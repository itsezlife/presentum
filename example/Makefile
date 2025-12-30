SHELL :=/bin/bash -e -o pipefail
PWD   := $(shell pwd)

.DEFAULT_GOAL := all
.PHONY: all
all: ## build pipeline
all: setup codegen format analyze test build

.PHONY: precommit
precommit: ## validate the branch before commit
precommit: all

.PHONY: ci
ci: ## CI build pipeline
ci: analyze test

.PHONY: git-hooks
git-hooks: ## install git hooks
	@git config --local core.hooksPath .githooks/

.PHONY: help
help:
	@echo 'Usage: make <OPTIONS> ... <TARGETS>'
	@echo ''
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: setup
setup: ## setup environment
	$(call print-target)
	@fvm dart --disable-analytics
	@fvm flutter config --no-analytics --enable-android --enable-web
	@yes | fvm flutter doctor --android-licenses || true
	@fvm flutter precache --universal --android --web
	$(call get)

.PHONY: version
version: ## show current flutter version
	$(call print-target)
	@fvm flutter --version

.PHONY: get
get: ## get dependencies
	$(call print-target)
	@flutter pub get

.PHONY: upgrade
upgrade: get ## upgrade dependencies
	$(call print-target)
	@fvm flutter pub upgrade

.PHONY: outdated
outdated: ## check for outdated dependencies
	$(call print-target)
	@fvm flutter pub outdated

.PHONY: codegen
codegen: get ## run codegenerators
	$(call print-target)
	@fvm dart run build_runner build --delete-conflicting-outputs
	@fvm dart run pubspec_generator:generate --input pubspec.yaml --output lib/src/common/constant/pubspec.yaml.g.dart
	$(call fix)

.PHONY: gen
gen: codegen

.PHONY: fix
fix: get ## format and fix code
	$(call print-target)
	@fvm dart format -l 80 lib test .
	@fvm dart fix --apply lib/
	@fvm dart fix --apply test/
	@fvm dart fix --apply .

.PHONY: format
format: fix

.PHONY: fmt
fmt: fix

.PHONY: clean
clean: ## remove files created during build pipeline
	$(call print-target)
	@fvm flutter clean
	@rm -rf .dart_tool build coverage .flutter-plugins .flutter-plugins-dependencies
	$(call get)

.PHONY: analyze
analyze: get ## check source code for errors and warnings
	$(call print-target)
	@fvm dart format --set-exit-if-changed -l 80 -o none lib/ test/
	@fvm flutter analyze --fatal-infos --fatal-warnings lib/ test/

.PHONY: check
check: analyze

.PHONY: lint
lint: analyze

.PHONY: test
test: ## run tests
	$(call print-target)
	@fvm flutter test --color --coverage --concurrency=50 --platform=tester --reporter=compact --timeout=30s

.PHONY: coverage
coverage: test ## generate coverage report
	$(call print-target)
	@lcov --list coverage/lcov.info

.PHONY: build
build: gen ## build the application
	$(call print-target)
	@fvm flutter build web --release --source-maps --pwa-strategy none --base-href / --dart-define VERSION=0.0.0 --dart-define-from-file=config/production.json

.PHONY: build-apk
build-apk: get ## build the application
	$(call print-target)
	@FLAVOR=$${FLAVOR:-development}; \
	fvm flutter build apk --release --dart-define-from-file=config/$$FLAVOR.json -t lib/main.dart --obfuscate --target-platform android-arm64 --obfuscate --split-debug-info=build/debug-info
	@echo "Opening APK location..."
	@APK_DIR="build/app/outputs/flutter-apk"; \
	open "$$APK_DIR" || xdg-open "$$APK_DIR" || explorer "$${APK_DIR//\//\\}" || echo "Please manually navigate to $$APK_DIR"

.PHONY: release
release: ## create shorebird release for platform
	$(call print-target)
	@FLAVOR=$${FLAVOR:-development}; \
	PLATFORM=$${PLATFORM:-android}; \
	shorebird release $$PLATFORM --target ./lib/main.dart --dart-define-from-file=config/$$FLAVOR.json

.PHONY: release-android-apk
release-android-apk: ## create shorebird release for android (apk artifact)
	$(call print-target)
	@FLAVOR=$${FLAVOR:-development}; \
	shorebird release android --target ./lib/main.dart --dart-define-from-file=config/$$FLAVOR.json --artifact apk --target-platform android-arm64 --split-debug-info=build/debug-info

.PHONY: patch
patch: gen ## create shorebird patch for platform
	$(call print-target)
	FLAVOR=$${FLAVOR:-development}; \
	PLATFORM=$${PLATFORM:-android}; \
	shorebird patch $$PLATFORM --release-version latest --target ./lib/main.dart --dart-define-from-file=config/$$FLAVOR.json

.PHONY: patch-android
patch-android: gen ## create shorebird patch for android
	$(call print-target)
	FLAVOR=$${FLAVOR:-development}; \
	shorebird patch android --release-version latest --target ./lib/main.dart --dart-define-from-file=config/$$FLAVOR.json --split-debug-info=build/debug-info

.PHONY: preview-android
preview-android: ## preview shorebird patch for android
	$(call print-target)
	@shorebird preview --platform android

.PHONY: l10n
l10n: ## generate localization files
	$(call print-target)
	@fvm flutter gen-l10n

.PHONY: diff
diff: ## git diff
	$(call print-target)
	@git diff --exit-code
	@RES=$$(git status --porcelain) ; if [ -n "$$RES" ]; then echo $$RES && exit 1 ; fi

define print-target
    @printf "Executing target: \033[36m$@\033[0m\n"
endef
