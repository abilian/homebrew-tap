# abilian/homebrew-tap

Homebrew formulae for Abilian projects.

## Usage

```sh
brew tap abilian/tap
brew install prezo      # TUI presentation tool
brew install hop3-cli   # Hop3 server CLI (provides the `hop3` command)
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

Both are Python applications installed into their own isolated virtualenv
under `libexec`, so they never touch the system or user Python environment.

## Maintaining

Each formula pins its full transitive dependency tree as `resource` blocks.
When a package or one of its dependencies is updated on PyPI:

1. Bump `url` + `sha256` in the formula to the new sdist (see the PyPI JSON
   API, e.g. `https://pypi.org/pypi/prezo/json`).
2. Regenerate the pinned resources:

   ```sh
   brew update-python-resources abilian/tap/prezo
   ```

3. Verify:

   ```sh
   brew audit --strict --online abilian/tap/prezo
   brew install --build-from-source abilian/tap/prezo
   brew test abilian/tap/prezo
   ```

> `brew update-python-resources` requires the formula to live in a tapped
> repository. For local development, symlink this repo into Homebrew's tap
> directory:
>
> ```sh
> ln -s "$PWD" "$(brew --repository)/Library/Taps/abilian/homebrew-tap"
> ```
