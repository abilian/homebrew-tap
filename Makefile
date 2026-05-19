# Homebrew tap test/build automation.
#
#   make            # alias for `make all`
#   make all        # full suite: style + audit + source build + brew test
#   make check      # fast suite: style + audit only (no native compiles)
#   make style      # rubocop + readall
#   make audit      # strict online audit
#   make build      # install --build-from-source + brew test, each formula
#   make tap        # (re)register this checkout as a local tap
#   make clean      # uninstall the formulae and run brew cleanup

TAP      := abilian/tap
TAP_DIR  := $(shell brew --repository)/Library/Taps/abilian/homebrew-tap
FORMULAE := $(patsubst Formula/%.rb,$(TAP)/%,$(wildcard Formula/*.rb))

# All resolve deps for macOS (host) + Linux (Docker) from formulae.toml.
#
#   update*  — bump the pin to the newest PyPI release, then regenerate.
#              Rewrites `version` in formulae.toml + the .rb.
#   regen*   — regenerate at the CURRENT pin (no version change). Use after
#              editing deps/config, or to check generator idempotency.
#   *-check  — dry run: print what would change, write nothing.
#   *-all    — every formula in formulae.toml (FORMULA unset).
#
#   make update-check FORMULA=prezo   # would prezo move? show bump + diff
#   make update       FORMULA=prezo   # bump prezo to latest + style + audit
#   make update-all                   # bump every formula to latest
#   make regen-all                    # rebuild every .rb at its pinned version
GEN_PY     := $(shell brew --prefix python@3.13)/libexec/bin/python3
GEN        := $(GEN_PY) scripts/gen_formula.py
# Top-level tables in formulae.toml == the formula names.
TOML_NAMES := $(GEN_PY) -c "import tomllib;print(' '.join(tomllib.load(open('formulae.toml','rb'))))"

.PHONY: all check test style audit build tap clean \
        update update-check update-all update-check-all \
        regen regen-check regen-all regen-check-all

all: tap style audit build

# Fast gate for CI: everything except the multi-minute source builds.
check: tap style audit

# Backwards-friendly alias.
test: all

tap:
	@mkdir -p "$(dir $(TAP_DIR))"
	@ln -sfn "$(CURDIR)" "$(TAP_DIR)"
	@echo "Tapped $(CURDIR) -> $(TAP_DIR)"

style:
	brew style $(TAP)
	brew readall $(TAP)

audit:
	brew audit --strict --online $(FORMULAE)

build:
	@for f in $(FORMULAE); do \
		echo "==> $$f"; \
		brew install --build-from-source "$$f" || exit 1; \
		brew test "$$f" || exit 1; \
	done

# --- regenerate at the current pin (no version change) --------------------- #
regen-check:
	@test -n "$(FORMULA)" || { echo "usage: make regen-check FORMULA=<name>"; exit 2; }
	$(GEN) "$(FORMULA)"

regen:
	@test -n "$(FORMULA)" || { echo "usage: make regen FORMULA=<name>"; exit 2; }
	$(GEN) "$(FORMULA)" --write
	brew style --fix $(TAP)/$(FORMULA)
	brew audit --strict --online $(TAP)/$(FORMULA)

# --- bump the pin to the newest PyPI release, then regenerate -------------- #
update-check:
	@test -n "$(FORMULA)" || { echo "usage: make update-check FORMULA=<name>"; exit 2; }
	$(GEN) "$(FORMULA)" --update

update:
	@test -n "$(FORMULA)" || { echo "usage: make update FORMULA=<name>"; exit 2; }
	$(GEN) "$(FORMULA)" --update --write
	brew style --fix $(TAP)/$(FORMULA)
	brew audit --strict --online $(TAP)/$(FORMULA)

# --- whole-tap sweeps (FORMULA unset) -------------------------------------- #
# *-check: keep going, exit non-zero if any formula would change.
# bare:    stop at the first failure (don't mass-rewrite blind).
regen-check-all:
	@rc=0; for f in $$($(TOML_NAMES)); do \
		echo "==> $$f"; \
		$(MAKE) --no-print-directory regen-check FORMULA=$$f || rc=1; \
	done; exit $$rc

regen-all:
	@for f in $$($(TOML_NAMES)); do \
		echo "==> $$f"; \
		$(MAKE) --no-print-directory regen FORMULA=$$f || exit 1; \
	done

update-check-all:
	@rc=0; for f in $$($(TOML_NAMES)); do \
		echo "==> $$f"; \
		$(MAKE) --no-print-directory update-check FORMULA=$$f || rc=1; \
	done; exit $$rc

update-all:
	@for f in $$($(TOML_NAMES)); do \
		echo "==> $$f"; \
		$(MAKE) --no-print-directory update FORMULA=$$f || exit 1; \
	done

clean:
	-brew uninstall $(FORMULAE)
	brew cleanup
