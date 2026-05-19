# abilian/homebrew-tap

Homebrew formulae for Abilian projects.

## Usage

```sh
brew tap abilian/tap
brew install prezo      # TUI presentation tool
brew install hop3-cli   # Hop3 server CLI (provides the `hop3` command)
brew install terminux   # Desktop terminal with workspaces and tabs
```

Or without tapping first:

```sh
brew install abilian/tap/prezo
```

## Formulae

| Formula    | Command | Description                                            |
|------------|---------|--------------------------------------------------------|
| `prezo`    | `prezo` | TUI-based presentation tool (Markdown / MARP / Deckset) |
| `hop3-cli` | `hop3`  | CLI for Hop3 servers (Heroku-like deploys over JSON-RPC) |
| `terminux` | `terminux` | Cross-platform desktop terminal with workspaces and tabs |

All three are Python applications installed into their own isolated
virtualenv under `libexec`, so they never touch the system or user Python
environment.

## Maintaining

Each formula pins its full transitive dependency tree as `resource` blocks.
The tap is described declaratively in [`formulae.toml`](formulae.toml); the
generator in [`scripts/gen_formula.py`](scripts/gen_formula.py) re-renders a
`Formula/<name>.rb` from it.

Unlike `brew update-python-resources` (which only resolves for the host OS),
the generator resolves the macOS tree on the host **and** the Linux tree in a
Docker container, then classifies each dependency: shared resources go at the
top level, platform-specific ones into `on_macos` / `on_linux` blocks.

`formulae.toml` is the lockfile: each formula's `version` is the exact
release the tap ships. Two verbs, each with a `-check` dry run and an `-all`
whole-tap sweep:

- **`update`** — bump the pin to the newest PyPI release, then regenerate.
  Rewrites `version` in `formulae.toml` *and* the `.rb`. This is what you
  want when upstream publishes a new release.
- **`regen`** — regenerate the `.rb` at the *current* pin, no version
  change. Use after editing `depends_on` / metadata, or to confirm the
  generator is idempotent.

```sh
make update-check FORMULA=prezo   # show "prezo: 2026.4.2 -> X" + the .rb diff
make update       FORMULA=prezo   # apply it, then brew style --fix + audit
make update-all                   # bump every formula to its latest release
make regen FORMULA=terminux       # rebuild terminux.rb at its pinned version
```

`*-check` writes nothing and exits non-zero if anything would change;
`*-all` sweeps every formula in `formulae.toml` (the `-check` variants keep
going and aggregate, the apply variants stop at the first failure).

4. Verify the build on both platforms:

   ```sh
   brew install --build-from-source abilian/tap/prezo
   brew test abilian/tap/prezo
   # Linux leg (same image as CI):
   docker run --rm --platform linux/amd64 \
     -v "$PWD":/tap:ro ghcr.io/homebrew/brew:main bash -c \
     'ln -s /tap "$(brew --repository)/Library/Taps/abilian/homebrew-tap" && \
      brew install --build-from-source abilian/tap/prezo && \
      brew test abilian/tap/prezo'
   ```

Requirements: Docker (for the Linux resolution leg) and the brewed
`python@3.13` (the `Makefile` invokes it for the generator — stdlib only,
no pip installs).

> `brew update-python-resources` and `make update` require the formula to
> live in a tapped repository. For local development, symlink this repo into
> Homebrew's tap directory:
>
> ```sh
> ln -s "$PWD" "$(brew --repository)/Library/Taps/abilian/homebrew-tap"
> ```
