# abilian/homebrew-tap

Homebrew formulae for Abilian projects, for macOS and Linux.

## Formulae

| Formula    | Command    | Description                                              |
|------------|------------|----------------------------------------------------------|
| `prezo`    | `prezo`    | TUI-based presentation tool (Markdown / MARP / Deckset)  |
| `hop3-cli` | `hop3`     | CLI for Hop3 servers (Heroku-like deploys over JSON-RPC) |
| `terminux` | `terminux` | Cross-platform desktop terminal with workspaces and tabs |
| `libera`   | `libera`   | Libera Suite office suite (docx / xlsx / pptx / ODF)     |

All four are Python applications installed into their own isolated virtualenv under `libexec`, so they never touch the system or user Python environment.

## Usage

The `brew` commands are the same on both platforms:

```sh
brew tap abilian/tap
brew install prezo      # TUI presentation tool
brew install hop3-cli   # Hop3 server CLI (provides the `hop3` command)
brew install terminux   # Desktop terminal with workspaces and tabs
brew install libera     # Desktop office suite
```

Or without tapping first:

```sh
brew install abilian/tap/prezo
```

Upgrade with `brew update && brew upgrade`, remove with `brew uninstall <formula>`.

### macOS

1. Install [Homebrew](https://brew.sh) if it is not there yet:

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. On Apple Silicon, put `brew` on your `PATH` by running the line for your shell, then open a new terminal (Intel Macs can skip this: `/usr/local/bin` is already on the `PATH`):

   ```sh
   # zsh (the macOS default)
   echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zprofile
   # bash
   echo 'eval "$(/opt/homebrew/bin/brew shellenv bash)"' >> ~/.bash_profile
   # fish
   echo '/opt/homebrew/bin/brew shellenv fish | source' >> ~/.config/fish/config.fish
   ```

3. Run the `brew` commands above.

4. For `libera`, fetch the editors once (about 170 MB, each file checked against the SHA-256 in the manifest shipped with the package):

   ```sh
   libera --payload-install
   libera report.docx
   ```

   Libera Suite needs Apple Silicon and macOS 14 or later.

### Linux

Homebrew runs on Linux too (x86_64 and arm64). It installs under `/home/linuxbrew/.linuxbrew` and does not interfere with the distribution's packages.

1. Install the build prerequisites and Homebrew:

   ```sh
   sudo apt-get install build-essential procps curl file git   # Debian/Ubuntu
   # sudo dnf group install development-tools && sudo dnf install procps-ng curl file git   # Fedora
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   The installer line works in bash, zsh and fish 3.4 or later. Ubuntu 22.04 ships fish 3.3, so there, type `bash` first.

2. Put `brew` on your `PATH` by running the line for your shell, then open a new terminal:

   ```sh
   # bash
   echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"' >> ~/.bashrc
   # zsh
   echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"' >> ~/.zshrc
   # fish
   echo '/home/linuxbrew/.linuxbrew/bin/brew shellenv fish | source' >> ~/.config/fish/config.fish
   ```

3. Run the `brew` commands above.

The GUI apps (`terminux`, `libera`) take GTK 3, WebKitGTK and PyGObject from Homebrew rather than from the system, so their first install downloads and builds a lot more than on macOS.

For `libera`, fetch the editors, then add a launcher entry (icon in the application menu, "Open With" for office files):

```sh
libera --payload-install
libera --launcher-install
```

> On Linux, the Libera Suite [Flatpak](https://docs.liberasuite.eu/) is the better install: it bundles its own GTK, WebKit and editors. Use this formula on a machine that already lives in Homebrew.

## Maintaining

Each formula pins its full transitive dependency tree as `resource` blocks. The tap is described declaratively in [`formulae.toml`](formulae.toml); the generator in [`scripts/gen_formula.py`](scripts/gen_formula.py) re-renders a `Formula/<name>.rb` from it.

Unlike `brew update-python-resources` (which only resolves for the host OS), the generator resolves the macOS tree on the host **and** the Linux tree in a Docker container, then classifies each dependency: shared resources go at the top level, platform-specific ones into `on_macos` / `on_linux` blocks.

`formulae.toml` is the lockfile: each formula's `version` is the exact release the tap ships. Two verbs, each with a `-check` dry run and an `-all` whole-tap sweep:

- **`update`** — bump the pin to the newest PyPI release, then regenerate. Rewrites `version` in `formulae.toml` *and* the `.rb`. This is what you want when upstream publishes a new release.
- **`regen`** — regenerate the `.rb` at the *current* pin, no version change. Use after editing `depends_on` / metadata, or to confirm the generator is idempotent.

```sh
make update-check FORMULA=prezo   # show "prezo: 2026.4.2 -> X" + the .rb diff
make update       FORMULA=prezo   # apply it, then brew style --fix + audit
make update-all                   # bump every formula to its latest release
make regen FORMULA=terminux       # rebuild terminux.rb at its pinned version
```

`*-check` writes nothing and exits non-zero if anything would change; `*-all` sweeps every formula in `formulae.toml` (the `-check` variants keep going and aggregate, the apply variants stop at the first failure).

Then verify the build on both platforms:

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

Requirements: Docker (for the Linux resolution leg) and the brewed `python@3.13` (the `Makefile` invokes it for the generator — stdlib only, no pip installs).

> `brew update-python-resources` and `make update` require the formula to live in a tapped repository. For local development, symlink this repo into Homebrew's tap directory:
>
> ```sh
> ln -s "$PWD" "$(brew --repository)/Library/Taps/abilian/homebrew-tap"
> ```
