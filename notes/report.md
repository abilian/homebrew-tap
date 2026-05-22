# Homebrew Tap — Setup & Maintenance Notes

How this tap is built and kept up to date. The concrete formulae (`prezo`, `hop3-cli`, `terminux`) are used below as *archetypes* — most new Python apps will resemble one of them.

## What this tap is

A Homebrew tap is a plain git repository named `homebrew-<name>`. For `brew tap abilian/tap` to work, it must be published at `github.com/abilian/homebrew-tap`. Formula files live in `Formula/`; the filename is the formula name and the Ruby class is its CamelCase form (`hop3-cli.rb` → `class Hop3Cli`).

For Python applications the idiomatic pattern is `Language::Python::Virtualenv`: the app is installed into its own isolated virtualenv under `libexec`, so it never touches the system or user Python. Every transitive dependency is pinned as a `resource` block (normalized name + sdist URL + sha256), making installs reproducible.

## Cross-platform structure

CI builds on macOS (Intel + Apple Silicon) and Linux, so a formula must resolve on all three. The key rule: a `resource` is fetched and built on whatever OS it is *registered* for. Dependencies that exist on every platform go at the top level; platform-specific ones go inside `on_macos` / `on_linux` blocks (which can also carry `depends_on`). `virtualenv_install_with_resources` then installs only what belongs on the running OS. Homebrew's component order requires the `on_<os>` blocks to appear *before* the loose top-level resources; `brew style --fix` enforces this.

## Repository layout

```
homebrew-tap/
├── README.md                     # user-facing usage + maintenance docs
├── formulae.toml                 # declarative source of truth (one table per formula)
├── scripts/gen_formula.py        # regenerates Formula/<name>.rb from formulae.toml
├── Makefile                      # tap / style / audit / build + update targets
├── .github/workflows/tests.yml   # brew test-bot CI (macOS + Linux), verbatim template
├── .github/workflows/publish.yml # brew pr-pull bottle publishing, verbatim template
├── .build.yml                    # sourcehut CI (Linuxbrew, runs `make check`)
└── Formula/*.rb                  # one formula per app
```

## Formula archetypes

- **Pure / native-library app (`prezo`)** — Python deps plus C libraries that wheels build against. Needs system `depends_on` for the native stack (here: `cairo` for `cairosvg`, `libyaml` for `pyyaml`, and the Pillow image stack — `freetype`, `jpeg-turbo`, `libtiff`, `little-cms2`, `openjpeg`, `webp`). Same set on macOS and Linux.
- **Compiled-extension app (`hop3-cli`)** — dependencies whose wheels are built from source, needing toolchains: `pkgconf` + `rust` as `:build`, `libsodium` at runtime (for `bcrypt`/`cryptography`/`pynacl`).
- **Cross-platform GUI app (`terminux`)** — the backend differs by OS. macOS pulls the `pyobjc-*` stack (gated in `on_macos`); Linux needs a GTK/WebKit2 backend that the package does *not* declare itself, so `pywebview[gtk]` is resolved as a Linux-only extra, adding `pycairo` + `pygobject` resources and `cairo`/`glib`/`gobject-introspection`/`gtk+3`/`webkitgtk` system deps in `on_linux`.

## Automation

The tap is described declaratively in `formulae.toml` (per formula: PyPI name, version, metadata, test stanza, per-OS `depends_on`, `linux_extra`/`macos_extra` for backends a package doesn't self-declare, `ignore`, `*_note`). `scripts/gen_formula.py` renders `Formula/<name>.rb` from it.

It improves on `brew update-python-resources`, which only resolves for the host OS: the generator resolves the macOS tree on the host **and** the Linux tree in a Docker container, classifies each dependency as shared / macOS-only / Linux-only, fetches the sdist (or pure-python wheel) URL + sha256, and renders in the tap's house style. Stdlib only; needs Docker for the Linux leg and the brewed `python@3.13`.

Makefile targets: `make update-check FORMULA=<name>` (dry run, prints a diff) and `make update FORMULA=<name>` (write + `brew style --fix` + strict audit). The generator is idempotent — re-running with no upstream change reports "up to date".

## Lessons learned (generic)

- **`brew style` (rubocop) is stricter than `brew audit`, and real source builds surface more.** Style/audit passing does not prove the formula builds; only `brew install --build-from-source` plus `brew test`, on *each* platform, does. Native-dependency gaps (e.g. Pillow's `RequiredDependencyException: jpeg`) only appear at build time.
- **Platform-specific C extensions must be gated.** A macOS-only dep like `pyobjc-core` listed unconditionally breaks the Linux build (and vice versa). When in doubt, resolve the dependency tree separately per OS rather than assuming it's shared.
- **Don't pip-build meson-based bindings under Homebrew.** Homebrew installs resources with `--no-binary :all:`, so a sdist whose build backend is `meson-python` (e.g. `pycairo`, `PyGObject`) drags in `meson-python`/`ninja`/`patchelf` and fails. Prefer Homebrew's prebuilt equivalents (`py3cairo`, `pygobject3`) as `depends_on`; the virtualenv is created `--system-site-packages`, so they import without a pip build. This applies to any GTK/GObject-binding backend.
- **Build-backend chains can transitively require Rust.** `--no-binary :all:` also applies to PEP 517 build backends, so a package whose `pyproject.toml` declares `uv_build` or `maturin` will source-build them and need `rustc`. Add `depends_on "rust" => :build` (plus usually `pkgconf` => :build) when you see a PEP 517 backend whose own wheel pip is forbidden to use. This can lurk: an older release of the same package may have used a simpler backend, so the requirement only shows up after the `--uploaded-prior-to` window moves.
- **A green `brew test` proves assembly, not GUI runtime.** A `<cmd> --help` smoke test confirms the venv builds and entry points resolve, but does not exercise a display server or windowing backend. GUI runtime on a given OS is best-effort beyond what CI asserts.
- **The test stanza must be config-independent and survive `brew test`'s sandboxed `$HOME`.** A `--help` that errors without configuration (as `hop3 --help` does) is not a valid smoke test; prefer a config-free invariant such as `--version`. Never record a formula as "verified" when its test block was empty or commented out — verify the assertion actually runs.
- **`homepage` falls back to the PyPI project page** when the package declares no repository URL. Replace with the canonical repo URL when one exists.
- **Local development needs the repo registered as a tap** (`brew update-python-resources` and `make update` require it). Symlink the checkout:

  ```sh
  ln -s "$PWD" "$(brew --repository)/Library/Taps/abilian/homebrew-tap"
  ```

## Maintenance workflow

When a package or any of its dependencies changes on PyPI:

1. Bump `version` (or set `"latest"`) for that formula in `formulae.toml`; adjust `*_extra` / `depends_on` only if the package's own dependencies changed.
2. `make update-check FORMULA=<name>` — preview the regenerated formula.
3. `make update FORMULA=<name>` — apply, auto-style, strict audit.
4. Verify on both platforms: `brew install --build-from-source` + `brew test` locally, and the same inside `ghcr.io/homebrew/brew:main` for the Linux leg.

## Tutorial compliance

Reconciled with <https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap>. The tap was built manually rather than via `brew tap-new` / `brew create`, but the result is equivalent: correct repo name, `Formula/` layout, declared `depends_on`, README, and the official GitHub Actions workflows copied verbatim so bottle build/publish works as intended. Per-package resource pinning (here automated) is the correct approach for Python virtualenv apps. Sourcehut CI is kept alongside the GitHub workflows at the user's request.
