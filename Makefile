# Version from pubspec.yaml (without build number)
VERSION := $(shell grep '^version:' pubspec.yaml | sed 's/version: *//;s/+.*//')

# Get staged Dart files
STAGED_DART_FILES := $(shell git diff --cached --name-only --diff-filter=ACM | grep '\.dart$$' 2>/dev/null)

# Default target
.PHONY: help
help:
	@echo "Flutter project commands:"
	@echo ""
	@echo "  Setup:"
	@echo "    get                 Install dependencies"
	@echo "    clean               Clean build artifacts"
	@echo "    install-precommit   Install git pre-commit hook"
	@echo "    pods                Update CocoaPods repo and install pods"
	@echo ""
	@echo "  i18n:"
	@echo "    i18n                Build i18n generated Dart code"
	@echo "    i18n-watch          Watch and rebuild i18n on changes"
	@echo ""
	@echo "  Development:"
	@echo "    run                 Run the app in debug mode"
	@echo "    webapp-run          Run the web app in default browser"
	@echo "    format              Format staged Dart files"
	@echo "    analyze             Analyze staged Dart files"
	@echo "    check               Check staged files (format + analyze, no changes)"
	@echo "    precommit           Run pre-commit checks on staged files"
	@echo "    format-all          Format all Dart files"
	@echo "    analyze-all         Analyze all Dart files"
	@echo "    check-all           Check all files (format + analyze, no changes)"
	@echo ""
	@echo "  Testing:"
	@echo "    test                Run all tests"
	@echo "    test-coverage       Run tests with coverage report"
	@echo ""
	@echo "  API:"
	@echo "    fetch-openapi       Fetch openapi.json from chenasraf/nextcloud-pantry"
	@echo ""
	@echo "  Assets:"
	@echo "    icons               Generate launcher icons, favicon & web logo from SVG"
	@echo "    splash              Generate splash screen from SVG"
	@echo ""
	@echo "  Building:"
	@echo "    android-install     Build APK and install on connected device"
	@echo "    android-build-apk   Build Android APK"
	@echo "    android-build-aab   Build Android App Bundle"
	@echo "    android-push        Build APK and push to device via adb"
	@echo "    ios-build           Build iOS (no codesign)"
	@echo "    web-build           Build web app"
	@echo "    build-all           Build all platforms"
	@echo ""
	@echo "  Release:"
	@echo "    android-release-apk Build APK and copy to build/release/"
	@echo "    android-release-aab Build AAB and copy to build/release/"
	@echo "    ios-release         Build iOS and create unsigned IPA in build/release/"
	@echo "    web-release         Build web and create zip in build/release/"
	@echo "    release-all         Build and release all platforms"
	@echo ""
	@echo "  Deploying:"
	@echo "    android-deploy      Build AAB and upload to Google Play (TRACK=internal|beta|production, STATUS=draft|completed)"
	@echo "    android-promote     Promote release between tracks (FROM=internal, TO=production, STATUS=draft|completed)"
	@echo "    ios-deploy          Build IPA and upload (DEST=testflight|appstore, default: testflight)"

# Setup
.PHONY: get
get:
	flutter pub get

.PHONY: clean
clean:
	flutter clean
	rm -rf coverage/

.PHONY: build-clean
build-clean:
	rm -rf build/release/*

# i18n
.PHONY: i18n
i18n:
	dart run build_runner build --delete-conflicting-outputs

.PHONY: i18n-watch
i18n-watch:
	dart run build_runner watch --delete-conflicting-outputs

# Development
.PHONY: run
run:
	flutter run --dart-define-from-file=.env

.PHONY: webapp-run
webapp-run:
	open http://localhost:5111 & flutter run -d web-server --web-port=5111 --dart-define-from-file=.env

.PHONY: format
format:
	@if [ -n "$(STAGED_DART_FILES)" ]; then \
		echo "Formatting staged files..."; \
		dart format $(STAGED_DART_FILES); \
	else \
		echo "No staged Dart files to format."; \
	fi

.PHONY: analyze
analyze:
	@if [ -n "$(STAGED_DART_FILES)" ]; then \
		echo "Analyzing staged files..."; \
		dart analyze $(STAGED_DART_FILES); \
	else \
		echo "No staged Dart files to analyze."; \
	fi

.PHONY: check
check:
	@if [ -n "$(STAGED_DART_FILES)" ]; then \
		echo "Checking staged files..."; \
		dart format --output=none --set-exit-if-changed $(STAGED_DART_FILES); \
		dart analyze $(STAGED_DART_FILES); \
	else \
		echo "No staged Dart files to check."; \
	fi

.PHONY: precommit
precommit: format analyze
	@if [ -n "$(STAGED_DART_FILES)" ]; then \
		echo "Re-staging formatted files..."; \
		git add $(STAGED_DART_FILES); \
	fi

# Full project commands
.PHONY: format-all
format-all:
	dart format .

.PHONY: analyze-all
analyze-all:
	flutter analyze --no-fatal-infos

.PHONY: check-all
check-all:
	dart format --output=none --set-exit-if-changed .
	flutter analyze --no-fatal-infos

# Testing
.PHONY: test
test:
ifdef FILES
	flutter test $(FILES) --dart-define-from-file=.env
else
	flutter test --dart-define-from-file=.env
endif

.PHONY: test-coverage
test-coverage:
	flutter test --coverage --dart-define-from-file=.env
	@echo "Coverage report generated at coverage/lcov.info"

# Building
.PHONY: android-build-apk
android-build-apk:
	flutter build apk --release --obfuscate --split-debug-info=build/debug-info-apk --dart-define-from-file=.env

.PHONY: android-install
android-install: android-build-apk
	flutter install

.PHONY: android-push
android-push: android-build-apk
	adb push build/app/outputs/flutter-apk/app-release.apk /sdcard/Download/pantry-$(VERSION).apk
	@echo "-> /sdcard/Download/pantry-$(VERSION).apk"

.PHONY: android-build-aab
android-build-aab:
	flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info-aab --dart-define-from-file=.env

.PHONY: ios-build
ios-build:
	flutter build ipa --release --obfuscate --split-debug-info=build/debug-info-ios --dart-define-from-file=.env --export-options-plist=ios/ExportOptions.plist

.PHONY: web-build
web-build:
	flutter build web --release --dart-define-from-file=.env

.PHONY: build-all
build-all: android-build-apk android-build-aab web-build

# Release (build + copy renamed artifacts to build/release/)
.PHONY: android-release-apk
android-release-apk: android-build-apk
	mkdir -p build/release
	cp build/app/outputs/flutter-apk/app-release.apk build/release/pantry-$(VERSION).apk
	@echo "-> build/release/pantry-$(VERSION).apk"

.PHONY: android-release-aab
android-release-aab: android-build-aab
	mkdir -p build/release
	cp build/app/outputs/bundle/release/app-release.aab build/release/pantry-$(VERSION).aab
	@echo "-> build/release/pantry-$(VERSION).aab"

.PHONY: ios-release
ios-release: ios-build
	mkdir -p build/release
	cp build/ios/ipa/*.ipa build/release/pantry-$(VERSION).ipa
	@echo "-> build/release/pantry-$(VERSION).ipa"

.PHONY: android-upload
android-upload:
	@echo "$(or $(TRACK),beta)" | grep -qE '^(internal|alpha|beta|production)$$' || (echo "Error: Invalid TRACK '$(TRACK)'. Must be: internal, alpha, beta, production"; exit 1)
	@echo "$(or $(STATUS),draft)" | grep -qE '^(draft|completed|halted|inProgress)$$' || (echo "Error: Invalid STATUS '$(STATUS)'. Must be: draft, completed, halted, inProgress"; exit 1)
	@echo "Track: $(or $(TRACK),internal) | Status: $(or $(STATUS),draft)"
	bundle exec fastlane deploy track:$(or $(TRACK),internal) status:$(or $(STATUS),draft)

.PHONY: android-deploy
android-deploy: android-build-aab android-upload

.PHONY: android-promote
android-promote:
	@echo "$(or $(FROM),internal)" | grep -qE '^(internal|alpha|beta|production)$$' || (echo "Error: Invalid FROM '$(FROM)'. Must be: internal, alpha, beta, production"; exit 1)
	@echo "$(or $(TO),production)" | grep -qE '^(internal|alpha|beta|production)$$' || (echo "Error: Invalid TO '$(TO)'. Must be: internal, alpha, beta, production"; exit 1)
	@echo "$(or $(STATUS),draft)" | grep -qE '^(draft|completed|halted|inProgress)$$' || (echo "Error: Invalid STATUS '$(STATUS)'. Must be: draft, completed, halted, inProgress"; exit 1)
	@echo "Promote: $(or $(FROM),internal) -> $(or $(TO),production) | Status: $(or $(STATUS),draft)"
	bundle exec fastlane promote from:$(or $(FROM),internal) to:$(or $(TO),production) status:$(or $(STATUS),draft)

.PHONY: ios-upload
ios-upload:
	@echo "$(or $(DEST),testflight)" | grep -qE '^(testflight|appstore)$$' || (echo "Error: Invalid DEST '$(DEST)'. Must be: testflight, appstore"; exit 1)
	@echo "Destination: $(or $(DEST),testflight)"
	@if [ "$(or $(DEST),testflight)" = "appstore" ]; then \
		bundle exec fastlane ios release; \
	else \
		bundle exec fastlane ios beta; \
	fi

.PHONY: ios-deploy
ios-deploy: ios-build ios-upload

.PHONY: web-release
web-release: web-build
	mkdir -p build/release
	cd build/web && zip -r ../release/pantry-$(VERSION)-web.zip .
	@echo "-> build/release/pantry-$(VERSION)-web.zip"

.PHONY: release-all
release-all: build-clean android-release-apk android-release-aab web-release

# CocoaPods
.PHONY: pods
pods:
	cd ios && pod install --repo-update
	cd macos && pod install --repo-update

# Git hooks
.PHONY: install-precommit
install-precommit:
	@if [ ! -f .git/hooks/pre-commit ]; then \
		echo "Installing pre-commit hook..."; \
		echo '#!/bin/sh' > .git/hooks/pre-commit; \
		echo 'make precommit' >> .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "Pre-commit hook installed."; \
	else \
		echo "Pre-commit hook already exists, skipping."; \
	fi

# API
.PHONY: fetch-openapi
fetch-openapi:
	gh api repos/chenasraf/nextcloud-pantry/contents/openapi.json --jq '.content' | base64 -d > openapi.json
	@echo "-> openapi.json updated"

# Assets
.PHONY: copy-graphics
copy-graphics:
ifndef GRAPHICS_DIR
	$(error GRAPHICS_DIR is required. Usage: make copy-graphics GRAPHICS_DIR=~/path/to/graphics)
endif
	@for pattern in icon logo; do \
		for ext in svg png; do \
			for f in $(GRAPHICS_DIR)/$$pattern*.$$ext; do \
				[ -e "$$f" ] && cp "$$f" assets/icon/ && echo "Copied $$f" || true; \
			done; \
		done; \
	done

.PHONY: icons
icons:
	mkdir -p assets/icon
	rsvg-convert -h 1024 assets/logo_icon.svg > assets/icon/icon.png
	dart run flutter_launcher_icons

.PHONY: splash
splash:
	mkdir -p assets/icon
	rsvg-convert -h 512 --page-width 1024 --page-height 1024 --top 256 --left 256 assets/logo_icon.svg > assets/icon/splash.png
	dart run flutter_native_splash:create
