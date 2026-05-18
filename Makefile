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

.PHONY: all check test style audit build tap clean

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

clean:
	-brew uninstall $(FORMULAE)
	brew cleanup
