# Version from pubspec.yaml (without build number)
VERSION := $(shell grep '^version:' pubspec.yaml | sed 's/version: *//;s/+.*//')

# Default target
.PHONY: help
help:
	@echo "Flutter project commands:"
	@echo ""
	@echo "  Setup:"
	@echo "    get                 Install dependencies"
	@echo "    clean               Clean build artifacts"
	@echo "    install-hooks       Install git hooks via lefthook"
	@echo "    pods                Update CocoaPods repo and install pods"
	@echo ""
	@echo "  i18n:"
	@echo "    i18n                Build i18n generated Dart code"
	@echo "    i18n-watch          Watch and rebuild i18n on changes"
	@echo ""
	@echo "  Development:"
	@echo "    run                 Run the app in debug mode"
	@echo "    webapp-run          Run the web app in default browser"
	@echo "    format              Format all Dart files"
	@echo "    analyze             Analyze all Dart files"
	@echo "    check               Check all files (format + analyze, no changes)"
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
	dart run tool/fix_i18n_escapes.dart
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
	dart format .

.PHONY: analyze
analyze:
	flutter analyze --no-fatal-infos

.PHONY: check
check:
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
	flutter build ios --release --no-codesign --obfuscate --split-debug-info=build/debug-info-ios --dart-define-from-file=.env

.PHONY: ios-build-ipa
ios-build-ipa:
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
ios-deploy: ios-build-ipa ios-upload

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
.PHONY: install-hooks
install-hooks:
	lefthook install

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
	rsvg-convert -w 1024 -h 1024 assets/logo_icon_square.svg > assets/icon/icon_ios.png
	rsvg-convert -w 1024 -h 1024 assets/logo_icon_foreground.svg > assets/icon/icon_foreground.png
	dart run flutter_launcher_icons
	rsvg-convert -w 512 -h 512 assets/logo_icon_square.svg > fastlane/metadata/android/en-US/images/icon.png

.PHONY: splash
splash:
	mkdir -p assets/icon
	rsvg-convert -h 1152 --page-width 1920 --page-height 1920 --top 384 --left 384 assets/logo_icon.svg > assets/icon/splash.png
	dart run flutter_native_splash:create
