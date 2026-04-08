# Version from pubspec.yaml (without build number)
VERSION := $(shell grep '^version:' pubspec.yaml | sed 's/version: *//;s/+.*//')

# Get staged Dart files
STAGED_DART_FILES := $(shell git diff --cached --name-only --diff-filter=ACM | grep '\.dart$$' 2>/dev/null)

# Check for staged files in subprojects
STAGED_FUNCTIONS_FILES := $(shell git diff --cached --name-only --diff-filter=ACM | grep '^functions/' 2>/dev/null)
STAGED_WEBSITE_FILES := $(shell git diff --cached --name-only --diff-filter=ACM | grep '^website/' 2>/dev/null)

# Default target
.PHONY: help
help:
	@echo "Flutter project commands:"
	@echo ""
	@echo "  Setup:"
	@echo "    get                 Install dependencies"
	@echo "    clean               Clean build artifacts"
	@echo "    install-precommit   Install git pre-commit hook"
	@echo "    sync-env            Sync .env to iOS Secrets.xcconfig"
	@echo "    pods                Update CocoaPods repo and install pods"
	@echo "    rules-deploy        Deploy Firestore and Storage security rules"
	@echo ""
	@echo "  Website:"
	@echo "    website-install     Install website dependencies"
	@echo "    website-run         Run website dev server"
	@echo "    website-build       Build website"
	@echo ""
	@echo "  Functions:"
	@echo "    functions-install   Install functions dependencies"
	@echo "    functions-build     Build functions"
	@echo "    functions-serve     Run functions with emulators"
	@echo "    functions-deploy    Deploy functions to Firebase"
	@echo "    functions-logs      View functions logs"
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
	@echo "    webapp-deploy       Build and deploy Flutter web app"
	@echo "    hosting-deploy      Build and deploy marketing website"
	@echo "    website-deploy      Deploy website + functions"
	@echo "    deploy-all          Deploy all platforms (SKIP_WEBAPP=1 SKIP_IOS=1 SKIP_ANDROID=1 SKIP_WEBSITE=1 to skip)"

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
	@if [ -n "$(STAGED_FUNCTIONS_FILES)" ]; then \
		echo "Running lint-staged for functions..."; \
		cd functions && pnpm lint-staged; \
	fi
	@if [ -n "$(STAGED_WEBSITE_FILES)" ]; then \
		echo "Running lint-staged for website..."; \
		cd website && pnpm lint-staged; \
	fi

# Full project commands
.PHONY: format-all
format-all:
	dart format .
	cd functions && pnpm prettier --write .
	cd website && pnpm prettier --write .

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
	cp build/app/outputs/flutter-apk/app-release.apk build/release/retroachieved-$(VERSION).apk
	@echo "-> build/release/retroachieved-$(VERSION).apk"

.PHONY: android-release-aab
android-release-aab: android-build-aab
	mkdir -p build/release
	cp build/app/outputs/bundle/release/app-release.aab build/release/retroachieved-$(VERSION).aab
	@echo "-> build/release/retroachieved-$(VERSION).aab"

.PHONY: ios-release
ios-release: ios-build
	mkdir -p build/release
	cp build/ios/ipa/*.ipa build/release/retroachieved-$(VERSION).ipa
	@echo "-> build/release/retroachieved-$(VERSION).ipa"

.PHONY: android-upload
android-upload:
	@echo "$(or $(TRACK),internal)" | grep -qE '^(internal|alpha|beta|production)$$' || (echo "Error: Invalid TRACK '$(TRACK)'. Must be: internal, alpha, beta, production"; exit 1)
	@echo "$(or $(STATUS),draft)" | grep -qE '^(draft|completed|halted|inProgress)$$' || (echo "Error: Invalid STATUS '$(STATUS)'. Must be: draft, completed, halted, inProgress"; exit 1)
	@echo "Track: $(or $(TRACK),internal) | Status: $(or $(STATUS),draft)"
	cd android && bundle exec fastlane deploy track:$(or $(TRACK),internal) status:$(or $(STATUS),draft)

.PHONY: android-deploy
android-deploy: android-build-aab android-upload

.PHONY: android-promote
android-promote:
	@echo "$(or $(FROM),internal)" | grep -qE '^(internal|alpha|beta|production)$$' || (echo "Error: Invalid FROM '$(FROM)'. Must be: internal, alpha, beta, production"; exit 1)
	@echo "$(or $(TO),production)" | grep -qE '^(internal|alpha|beta|production)$$' || (echo "Error: Invalid TO '$(TO)'. Must be: internal, alpha, beta, production"; exit 1)
	@echo "$(or $(STATUS),draft)" | grep -qE '^(draft|completed|halted|inProgress)$$' || (echo "Error: Invalid STATUS '$(STATUS)'. Must be: draft, completed, halted, inProgress"; exit 1)
	@echo "Promote: $(or $(FROM),internal) -> $(or $(TO),production) | Status: $(or $(STATUS),draft)"
	cd android && bundle exec fastlane promote from:$(or $(FROM),internal) to:$(or $(TO),production) status:$(or $(STATUS),draft)

.PHONY: ios-upload
ios-upload:
	@echo "$(or $(DEST),testflight)" | grep -qE '^(testflight|appstore)$$' || (echo "Error: Invalid DEST '$(DEST)'. Must be: testflight, appstore"; exit 1)
	@echo "Destination: $(or $(DEST),testflight)"
	@if [ "$(or $(DEST),testflight)" = "appstore" ]; then \
		cd ios && bundle exec fastlane release; \
	else \
		cd ios && bundle exec fastlane beta; \
	fi

.PHONY: ios-deploy
ios-deploy: ios-build ios-upload

.PHONY: web-release
web-release: web-build
	mkdir -p build/release
	cd build/web && zip -r ../release/retroachieved-$(VERSION)-web.zip .
	@echo "-> build/release/retroachieved-$(VERSION)-web.zip"

.PHONY: release-all
release-all: build-clean android-release-apk android-release-aab web-release

# Environment sync
.PHONY: sync-env
sync-env:
	@echo "Syncing .env to iOS Secrets.xcconfig..."
	@if [ -f .env ]; then \
		echo "// Auto-generated from .env - DO NOT EDIT" > ios/Flutter/Secrets.xcconfig; \
		grep -E "^[A-Za-z_][A-Za-z0-9_]*=" .env >> ios/Flutter/Secrets.xcconfig; \
		echo "Secrets.xcconfig updated."; \
	else \
		echo "Error: .env file not found"; \
		exit 1; \
	fi

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

# Firebase
.PHONY: rules-deploy
rules-deploy:
	firebase deploy --only firestore:rules,storage

# Functions
.PHONY: functions-install
functions-install:
	cd functions && pnpm install

.PHONY: functions-build
functions-build:
	cd functions && pnpm build

.PHONY: functions-serve
functions-serve:
	cd functions && pnpm serve

.PHONY: functions-deploy
functions-deploy:
ifdef FN
	firebase deploy --only functions:$(FN)
else
	firebase deploy --only functions
endif

.PHONY: functions-logs
functions-logs:
	firebase functions:log

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
	dart run flutter_launcher_icons

.PHONY: splash
splash:
	dart run flutter_native_splash:create

# Website
.PHONY: website-install
website-install:
	cd website && pnpm install

.PHONY: website-run
website-run:
	cd website && pnpm dev

.PHONY: website-build
website-build:
	cd website && pnpm build

# Hosting
.PHONY: hosting-deploy
hosting-deploy: website-build
	firebase deploy --only hosting:website

.PHONY: webapp-deploy
webapp-deploy: web-build
	firebase deploy --only hosting:webapp

.PHONY: website-deploy
website-deploy:
	firebase deploy --only hosting:website,functions

.PHONY: deploy-all
deploy-all:
ifndef SKIP_WEBAPP
	$(MAKE) webapp-deploy
endif
ifndef SKIP_IOS
	$(MAKE) ios-deploy
endif
ifndef SKIP_ANDROID
	$(MAKE) android-deploy STATUS=completed
endif
ifndef SKIP_WEBSITE
	$(MAKE) website-deploy
endif
