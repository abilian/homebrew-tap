#!/usr/bin/env python3
"""Generate a Homebrew Python-virtualenv formula from PyPI + a TOML config.

Automates the maintenance loop documented in the README:

  1. resolve the macOS dependency tree (host pip),
  2. resolve the Linux dependency tree (in a Docker container),
  3. classify every dependency as shared / macOS-only / Linux-only,
  4. fetch the sdist (or pure-python wheel) URL + sha256 for each,
  5. render Formula/<name>.rb.

Shared resources go at the top level; platform-specific ones land in
`on_macos` / `on_linux` blocks, so `virtualenv_install_with_resources`
only ever installs what belongs on the running OS.

Stdlib only. Needs Python >= 3.11 (tomllib) and, for the Linux leg,
Docker. Run it via the brewed interpreter, e.g.:

    "$(brew --prefix python@3.13)/libexec/bin/python3" \\
        scripts/gen_formula.py terminux --check
"""

from __future__ import annotations

import argparse
import difflib
import json
import re
import shlex
import subprocess
import sys
import tempfile
import tomllib
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / "formulae.toml"
FORMULA_DIR = ROOT / "Formula"
LINUX_IMAGE = "python:3.13-slim"


# --------------------------------------------------------------------------- #
# helpers
# --------------------------------------------------------------------------- #
def normalize(name: str) -> str:
    """PEP 503 normalized project name (Homebrew's resource-name convention)."""
    return re.sub(r"[-_.]+", "-", name).lower()


def camel(name: str) -> str:
    return "".join(p.capitalize() for p in re.split(r"[-_]+", name))


def http_json(url: str) -> dict:
    with urllib.request.urlopen(url, timeout=30) as r:
        return json.load(r)


def pypi_artifact(name: str, version: str) -> tuple[str, str, bool]:
    """Return (url, sha256, is_wheel) preferring an sdist for `name==version`."""
    data = http_json(f"https://pypi.org/pypi/{name}/{version}/json")
    urls = data["urls"]
    sdist = next((u for u in urls if u["packagetype"] == "sdist"), None)
    if sdist:
        return sdist["url"], sdist["digests"]["sha256"], False
    wheel = next(
        (
            u
            for u in urls
            if u["packagetype"] == "bdist_wheel"
            and re.search(r"-(py3|py2\.py3)-none-any\.whl$", u["filename"])
        ),
        urls[0] if urls else None,
    )
    if wheel is None:
        raise SystemExit(f"no distributable artifact for {name}=={version}")
    return wheel["url"], wheel["digests"]["sha256"], True


def _report_to_map(report: dict, drop: set[str]) -> dict[str, tuple[str, str]]:
    """{normalized_name: (pypi_name, version)} from a pip --report, minus `drop`."""
    out: dict[str, tuple[str, str]] = {}
    for item in report["install"]:
        meta = item["metadata"]
        norm = normalize(meta["name"])
        if norm in drop:
            continue
        out[norm] = (meta["name"], meta["version"])
    return out


def resolve_host(reqs: list[str], python_formula: str) -> dict:
    prefix = subprocess.run(
        ["brew", "--prefix", python_formula],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    py = f"{prefix}/libexec/bin/python3"
    with tempfile.NamedTemporaryFile("r", suffix=".json") as tmp:
        subprocess.run(
            [
                py,
                "-m",
                "pip",
                "install",
                "--disable-pip-version-check",
                "--dry-run",
                "--ignore-installed",
                "--report",
                tmp.name,
                *reqs,
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        return json.load(open(tmp.name))


def resolve_linux(reqs: list[str], apt: list[str]) -> dict:
    apt_line = (
        "apt-get update -qq >/dev/null && "
        f"apt-get install -y -qq {' '.join(map(shlex.quote, apt))} >/dev/null && "
        if apt
        else ""
    )
    script = (
        "set -e\n"
        f"{apt_line}"
        "pip install -q --disable-pip-version-check --root-user-action=ignore "
        "--dry-run --ignore-installed --report=/tmp/r.json "
        f"{' '.join(map(shlex.quote, reqs))} >/dev/null\n"
        'python -c "import json,sys;'
        "sys.stdout.write('@@JSON@@'+json.dumps(json.load(open('/tmp/r.json'))))\""
    )
    proc = subprocess.run(
        [
            "docker",
            "run",
            "--rm",
            "--platform",
            "linux/amd64",
            LINUX_IMAGE,
            "bash",
            "-c",
            script,
        ],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stdout + proc.stderr)
        raise SystemExit("Linux dependency resolution failed (see above)")
    marker = proc.stdout.split("@@JSON@@", 1)
    if len(marker) != 2:
        sys.stderr.write(proc.stdout + proc.stderr)
        raise SystemExit("could not parse Linux pip report")
    return json.loads(marker[1])


# --------------------------------------------------------------------------- #
# rendering
# --------------------------------------------------------------------------- #
@dataclass
class Res:
    name: str
    version: str
    pypi: str


@dataclass
class Plan:
    cls: str
    desc: str
    homepage: str
    license: str
    python: str
    main_url: str
    main_sha: str
    test: str
    macos_note: str = ""
    linux_note: str = ""
    common_dep: dict = field(default_factory=dict)  # {"build":[], "runtime":[]}
    macos_dep: dict = field(default_factory=dict)
    linux_dep: dict = field(default_factory=dict)
    common_res: list[Res] = field(default_factory=list)
    macos_res: list[Res] = field(default_factory=list)
    linux_res: list[Res] = field(default_factory=list)


def _dep_lines(dep: dict, indent: str) -> list[str]:
    lines = []
    for d in sorted(dep.get("build", [])):
        lines.append(f'{indent}depends_on "{d}" => :build')
    for d in sorted(dep.get("runtime", [])):
        lines.append(f'{indent}depends_on "{d}"')
    return lines


def _res_block(resources: list[Res], indent: str) -> list[str]:
    lines = []
    for r in sorted(resources, key=lambda x: x.name.lower()):
        url, sha, _ = pypi_artifact(r.pypi, r.version)
        lines += [
            f'{indent}resource "{r.name}" do',
            f'{indent}  url "{url}"',
            f'{indent}  sha256 "{sha}"',
            f"{indent}end",
            "",
        ]
    if lines:
        lines.pop()  # trailing blank
    return lines


def render(p: Plan) -> str:
    L: list[str] = [
        f"class {p.cls} < Formula",
        "  include Language::Python::Virtualenv",
        "",
        f'  desc "{p.desc}"',
        f'  homepage "{p.homepage}"',
        f'  url "{p.main_url}"',
        f'  sha256 "{p.main_sha}"',
    ]
    if p.license:
        L.append(f'  license "{p.license}"')
    # Homebrew canonical order: :build deps first, then runtime deps —
    # python@3.13 is just another runtime dep, sorted in place.
    top_dep = {
        "build": p.common_dep.get("build", []),
        "runtime": [*p.common_dep.get("runtime", []), p.python],
    }
    L += [""]
    L += _dep_lines(top_dep, "  ")

    def note_lines(text: str) -> list[str]:
        return [f"    # {ln}" for ln in text.splitlines()] if text else []

    def os_body(note: str, dep: dict, res: list[Res]) -> list[str]:
        head = note_lines(note) + _dep_lines(dep, "    ")
        tail = _res_block(res, "    ")
        if head and tail:
            return [*head, "", *tail]
        return head + tail

    macos_body = os_body(p.macos_note, p.macos_dep, p.macos_res)
    linux_body = os_body(p.linux_note, p.linux_dep, p.linux_res)
    if macos_body:
        L += ["", "  on_macos do", *macos_body, "  end"]
    if linux_body:
        L += ["", "  on_linux do", *linux_body, "  end"]

    common = _res_block(p.common_res, "  ")
    if common:
        L.append("")
        L += common

    L += [
        "",
        "  def install",
        "    virtualenv_install_with_resources",
        "  end",
        "",
        "  test do",
        f"    {p.test}",
        "  end",
        "end",
        "",
    ]
    return "\n".join(L)


# --------------------------------------------------------------------------- #
# planning
# --------------------------------------------------------------------------- #
def latest_version(pypi: str) -> str:
    """Newest release PyPI itself considers current (matches `pip install`)."""
    return http_json(f"https://pypi.org/pypi/{pypi}/json")["info"]["version"]


def bump_toml_version(formula: str, new: str) -> str:
    """Rewrite `version = "..."` under the [formula] table; return the old value."""
    lines = CONFIG.read_text().splitlines()
    header = re.compile(r"^\[([^\]]+)\]\s*$")
    in_table = False
    old: str | None = None
    for i, ln in enumerate(lines):
        m = header.match(ln)
        if m:
            in_table = m.group(1) == formula
            continue
        if in_table:
            vm = re.match(r'^(version\s*=\s*)"(.*?)"(.*)$', ln)
            if vm:
                old = vm.group(2)
                lines[i] = f'{vm.group(1)}"{new}"{vm.group(3)}'
                break
    if old is None:
        raise SystemExit(f"no version key under [{formula}] in {CONFIG.name}")
    CONFIG.write_text("\n".join(lines) + "\n")
    return old


def build_plan(name: str, cfg: dict, version_override: str | None = None) -> Plan:
    pypi = cfg.get("pypi", name)
    version = version_override or cfg.get("version", "latest")
    ignore = {normalize(x) for x in cfg.get("ignore", [])}
    main_norm = normalize(pypi)
    drop = ignore | {main_norm}

    base = pypi if version == "latest" else f"{pypi}=={version}"
    host_reqs = [base, *cfg.get("macos_extra", [])]
    host = resolve_host(host_reqs, cfg.get("python", "python@3.13"))

    # pin the real version (handles version = "latest")
    main_ver = next(
        i["metadata"]["version"]
        for i in host["install"]
        if normalize(i["metadata"]["name"]) == main_norm
    )

    linux_reqs = [f"{pypi}=={main_ver}", *cfg.get("linux_extra", [])]
    linux = resolve_linux(linux_reqs, cfg.get("resolve_apt", []))

    H = _report_to_map(host, drop)
    Lx = _report_to_map(linux, drop)

    common_res, macos_res, linux_res = [], [], []
    for n in sorted(set(H) | set(Lx)):
        in_h, in_l = n in H, n in Lx
        if in_h and in_l:
            (pn_h, v_h), (_, v_l) = H[n], Lx[n]
            if v_h == v_l:
                common_res.append(Res(n, v_h, pn_h))
            else:  # version skew -> pin per platform
                sys.stderr.write(
                    f"  ! {n}: macOS {v_h} vs Linux {v_l} -> pinned per-OS\n"
                )
                macos_res.append(Res(n, v_h, pn_h))
                linux_res.append(Res(n, v_l, Lx[n][0]))
        elif in_h:
            macos_res.append(Res(n, H[n][1], H[n][0]))
        else:
            linux_res.append(Res(n, Lx[n][1], Lx[n][0]))

    info = http_json(f"https://pypi.org/pypi/{pypi}/{main_ver}/json")["info"]
    main_url, main_sha, _ = pypi_artifact(pypi, main_ver)

    mac_cfg = cfg.get("depends_on", {}).get("macos", {})
    lin_cfg = cfg.get("depends_on", {}).get("linux", {})

    def split(kind: str):
        m, l = set(mac_cfg.get(kind, [])), set(lin_cfg.get(kind, []))
        return sorted(m & l), sorted(m - l), sorted(l - m)

    cb, mb, lb = split("build")
    cr, mr, lr = split("runtime")

    return Plan(
        cls=cfg.get("class_name", camel(name)),
        desc=cfg.get("desc") or info.get("summary", "").rstrip("."),
        homepage=cfg.get("homepage") or f"https://pypi.org/project/{pypi}/",
        license=cfg.get("license", ""),
        python=cfg.get("python", "python@3.13"),
        main_url=main_url,
        main_sha=main_sha,
        test=cfg["test"],
        macos_note=cfg.get("macos_note", ""),
        linux_note=cfg.get("linux_note", ""),
        common_dep={"build": cb, "runtime": cr},
        macos_dep={"build": mb, "runtime": mr},
        linux_dep={"build": lb, "runtime": lr},
        common_res=common_res,
        macos_res=macos_res,
        linux_res=linux_res,
    )


# --------------------------------------------------------------------------- #
# cli
# --------------------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("formula", help="key in formulae.toml / Formula/<name>.rb")
    ap.add_argument(
        "--write",
        action="store_true",
        help="write the file (default: print a diff and exit)",
    )
    ap.add_argument(
        "--update",
        action="store_true",
        help="bump the pin to the newest PyPI release before rendering "
        "(with --write, also rewrites the pin in formulae.toml)",
    )
    args = ap.parse_args()

    config = tomllib.loads(CONFIG.read_text())
    if args.formula not in config:
        raise SystemExit(
            f"'{args.formula}' not in {CONFIG.name}; known: {', '.join(sorted(config))}"
        )

    cfg = config[args.formula]
    old_pin = cfg.get("version", "latest")
    override = None
    if args.update:
        latest = latest_version(cfg.get("pypi", args.formula))
        override = latest
        if latest == old_pin:
            sys.stderr.write(f"==> {args.formula}: already latest ({latest})\n")
        else:
            sys.stderr.write(f"==> {args.formula}: {old_pin} -> {latest}\n")

    sys.stderr.write(f"==> resolving {args.formula} (macOS host + Linux docker)\n")
    plan = build_plan(args.formula, cfg, override)
    rendered = render(plan)

    target = FORMULA_DIR / f"{args.formula}.rb"
    current = target.read_text() if target.exists() else ""

    if args.write:
        if args.update and override and override != old_pin:
            bump_toml_version(args.formula, override)
            print(f"bumped {CONFIG.name}: {args.formula} {old_pin} -> {override}")
        target.write_text(rendered)
        print(f"wrote {target.relative_to(ROOT)}")
        print(
            "next: brew style --fix && brew audit --strict --online "
            f"abilian/tap/{args.formula}"
        )
        return 0

    diff = list(
        difflib.unified_diff(
            current.splitlines(),
            rendered.splitlines(),
            fromfile=f"a/{target.name}",
            tofile=f"b/{target.name}",
            lineterm="",
        )
    )
    if not diff:
        print(f"{target.name}: up to date")
        return 0
    print("\n".join(diff))
    print("\n(dry run — re-run with --write to apply)")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
