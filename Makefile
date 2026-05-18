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

# Regenerate a formula from PyPI + formulae.toml (resolves macOS + Linux).
#   make update-check FORMULA=terminux   # dry run: print a diff
#   make update       FORMULA=terminux   # write + style + audit
GEN_PY := $(shell brew --prefix python@3.13)/libexec/bin/python3
GEN    := $(GEN_PY) scripts/gen_formula.py

.PHONY: all check test style audit build tap clean update update-check

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

update-check:
	@test -n "$(FORMULA)" || { echo "usage: make update-check FORMULA=<name>"; exit 2; }
	$(GEN) "$(FORMULA)"

update:
	@test -n "$(FORMULA)" || { echo "usage: make update FORMULA=<name>"; exit 2; }
	$(GEN) "$(FORMULA)" --write
	brew style --fix $(TAP)/$(FORMULA)
	brew audit --strict --online $(TAP)/$(FORMULA)

clean:
	-brew uninstall $(FORMULAE)
	brew cleanup
