# Use bash with pipefail so a failing command in a pipe (e.g. a labeled
# sub-make below) still fails the recipe instead of being masked by awk.
SHELL := bash
.SHELLFLAGS := -o pipefail -c

# Run a sub-make target with every stdout/stderr line prefixed by [<target>],
# so the back-to-back per-platform logs in deploy-* are easy to scan. The job
# runs under a pseudo-TTY (script) so fastlane/flutter keep their colors, and
# perl adds the prefix while stripping the pty's trailing CR and the "^D" EOF
# marker script prints on its first line. Usage: $(call labeled,<target>,<args>)
labeled = script -q /dev/null $(MAKE) $(1) $(2) </dev/null 2>&1 | perl -pe 'BEGIN{$$|=1} s/\r$$//; s/^\^D\x08*// if $$.==1; s/^/[$(1)] /'

# Version from pubspec.yaml (without build number)
VERSION := $(shell grep '^version:' pubspec.yaml | sed 's/version: *//;s/+.*//')

# Build number from pubspec.yaml (the integer after `+`)
BUILD_NUMBER := $(shell grep '^version:' pubspec.yaml | sed 's/.*+//')

# macOS uses an offset so its CFBundleVersion can never collide with iOS under
# the shared bundle ID in App Store Connect.
MACOS_BUILD_NUMBER := $(shell echo $$(($(BUILD_NUMBER) + 10000)))

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
	@echo "    i18n-from-nextcloud Populate a translation file from a Nextcloud l10n JSON (NC_JSON=, TARGET=)"
	@echo ""
	@echo "  Development:"
	@echo "    run                 Run the app in debug mode"
	@echo "    format              Format all Dart files"
	@echo "    analyze             Analyze all Dart files"
	@echo "    check               Check all files (format + analyze, no changes)"
	@echo ""
	@echo "  Testing:"
	@echo "    test                Run all tests"
	@echo "    test-coverage       Run tests with coverage report"
	@echo ""
	@echo "  API:"
	@echo "    fetch-openapi       Fetch openapi.json from chenasraf/nextcloud-pantry (optional: REF=<ref>)"
	@echo ""
	@echo "  Assets:"
	@echo "    icons               Generate launcher icons, favicon & web logo from SVG"
	@echo "    widget-icons        Generate Android widget icon drawables from Material Symbols"
	@echo "    splash              Generate splash screen from SVG"
	@echo ""
	@echo "  Building:"
	@echo "    android-install     Build APK and install on connected device"
	@echo "    android-build-apk   Build Android APK"
	@echo "    android-build-apk-split  Build Android split-per-ABI APKs"
	@echo "    android-build-apk-fdroid Build FLOSS (flutter_zxing) split APKs for F-Droid"
	@echo "    fdroid-lock         Regenerate the pinned F-Droid lockfile after dep changes"
	@echo "    fdroid-check        Verify the pinned F-Droid lockfile is in sync with pubspec.yaml"
	@echo "    android-build-aab   Build Android App Bundle"
	@echo "    android-push        Build APK and push to device via adb"
	@echo "    ios-build           Build iOS (no codesign)"
	@echo "    macos-build         Build macOS app (.app bundle, no codesign)"
	@echo "    macos-build-pkg     Build signed macOS .pkg for App Store"
	@echo "    linux-build         Build Linux desktop bundle"
	@echo "    windows-build       Build Windows desktop bundle"
	@echo "    build-all           Build all platforms"
	@echo ""
	@echo "  Release:"
	@echo "    android-release-apk Build APK and copy to build/release/"
	@echo "    android-release-apk-fdroid  Build FLOSS F-Droid APKs -> build/release/ (…-fdroid-<abi>.apk)"
	@echo "    android-release-aab Build AAB and copy to build/release/"
	@echo "    ios-release         Build IPA and copy to build/release/"
	@echo "    macos-release       Build PKG and copy to build/release/"
	@echo "    linux-release       Build Linux tarball -> build/release/"
	@echo "    windows-release     Build Windows zip -> build/release/"
	@echo "    release-all         Build and release all platforms"
	@echo ""
	@echo "  Deploying:"
	@echo "    android-deploy      Build AAB and upload to Google Play (TRACK=internal|beta|production, STATUS=draft|completed)"
	@echo "    android-promote     Promote release between tracks (FROM=internal, TO=production, STATUS=draft|completed)"
	@echo "    ios-deploy          Build IPA and upload (DEST=testflight|appstore, default: testflight)"
	@echo "    ios-submit          Submit the existing App Store build for review (no upload)"
	@echo "    macos-deploy        Build PKG and upload (DEST=testflight|appstore, default: testflight)"
	@echo "    macos-submit        Submit the existing Mac App Store build for review (no upload)"
	@echo "    deploy-production   Build and deploy to production (Google Play + App Store)"
	@echo "    deploy-beta         Build and deploy to beta (Google Play beta + TestFlight)"

# Setup
.PHONY: get
get:
	flutter pub get
	pnpm install

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

.PHONY: i18n-from-nextcloud
i18n-from-nextcloud:
ifndef NC_JSON
	$(error NC_JSON is required. Usage: make i18n-from-nextcloud NC_JSON=~/path/nextcloud-pantry/l10n/nn_NO.json TARGET=lib/i18n/messages_nn.i18n.yaml)
endif
ifndef TARGET
	$(error TARGET is required. Usage: make i18n-from-nextcloud NC_JSON=~/path/nextcloud-pantry/l10n/nn_NO.json TARGET=lib/i18n/messages_nn.i18n.yaml)
endif
	dart run tool/i18n_generate_from_nextcloud.dart $(NC_JSON) $(TARGET)

# Development
.PHONY: run
run:
	flutter run
.PHONY: format
format:
	dart format .
	pnpm exec prettier --write "**/*.{yml,yaml}"

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
	flutter test $(FILES)
else
	flutter test
endif

.PHONY: test-coverage
test-coverage:
	flutter test --coverage
	@echo "Coverage report generated at coverage/lcov.info"

# Building
.PHONY: android-build-apk
android-build-apk:
	flutter build apk --release --obfuscate --split-debug-info=build/debug-info-apk
.PHONY: android-build-apk-split
android-build-apk-split:
	flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info-apk
.PHONY: android-install
android-install: android-build-apk
	flutter install

# F-Droid variant — swaps the barcode scanner from Google ML Kit
# (mobile_scanner) to the FLOSS flutter_zxing so the APK carries no proprietary
# code. `fdroid-apply` mutates pubspec.yaml + the scanner impl in place;
# `fdroid-revert` restores them. See fdroid/README.md.
.PHONY: fdroid-apply
fdroid-apply:
	tool/fdroid/apply.sh

.PHONY: fdroid-revert
fdroid-revert:
	git checkout -- pubspec.yaml pubspec.lock lib/views/checklists/barcode_scanner/barcode_camera_scanner.dart lib/widgets/avif_image.dart
	flutter pub get

# Verify the pinned F-Droid lockfile still satisfies the FLOSS pubspec, catching
# a dependency change that wasn't followed by `make fdroid-lock`. Restores the
# working tree afterwards. Run by CI and the pubspec pre-commit hook.
.PHONY: fdroid-check
fdroid-check:
	tool/fdroid/check-lock.sh

# Regenerate the pinned F-Droid lockfile (tool/fdroid/pubspec.lock) after
# dependency changes. Applies the scanner swap, resolves fresh (unpinned),
# captures the lock, then restores the working tree. Commit the updated lock.
.PHONY: fdroid-lock
fdroid-lock:
	@set -e; \
	FDROID_REGEN_LOCK=1 tool/fdroid/apply.sh; \
	cp pubspec.lock tool/fdroid/pubspec.lock; \
	git checkout -- pubspec.yaml pubspec.lock lib/views/checklists/barcode_scanner/barcode_camera_scanner.dart lib/widgets/avif_image.dart; \
	flutter pub get; \
	echo "Regenerated tool/fdroid/pubspec.lock — commit it."

# Build the FLOSS split APKs one ABI at a time with --target-platform, matching
# F-Droid's per-versionCode recipe exactly so the output reproduces byte-for-byte
# (see fdroid/README.md). `flutter clean` isolates each ABI as F-Droid does;
# APKs are stashed outside build/ since clean wipes it.
.PHONY: android-build-apk-fdroid
android-build-apk-fdroid: fdroid-apply
	@set -e; \
	OUT=$$(mktemp -d); \
	build_one() { \
		flutter clean; \
		flutter pub get --enforce-lockfile; \
		flutter build apk --release --split-per-abi --target-platform="$$1"; \
		mv build/app/outputs/flutter-apk/app-"$$2"-release.apk "$$OUT/app-$$2-release.apk"; \
	}; \
	build_one android-arm armeabi-v7a; \
	build_one android-arm64 arm64-v8a; \
	build_one android-x64 x86_64; \
	mkdir -p build/app/outputs/flutter-apk; \
	mv "$$OUT"/*.apk build/app/outputs/flutter-apk/; \
	rmdir "$$OUT"
	@echo "F-Droid split APKs built. Run 'make fdroid-revert' to restore the ML Kit default."

.PHONY: android-push
android-push: android-build-apk
	adb push build/app/outputs/flutter-apk/app-release.apk /sdcard/Download/pantry-$(VERSION).apk
	@echo "-> /sdcard/Download/pantry-$(VERSION).apk"

.PHONY: android-build-aab
android-build-aab:
	flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info-aab
.PHONY: ios-build
ios-build:
	flutter build ios --release --no-codesign --obfuscate --split-debug-info=build/debug-info-ios
.PHONY: ios-build-ipa
ios-build-ipa:
	flutter build ipa --release --obfuscate --split-debug-info=build/debug-info-ios --dart-define-from-file=.env --export-options-plist=ios/ExportOptions.plist

.PHONY: macos-build
macos-build:
	flutter build macos --release --build-number=$(MACOS_BUILD_NUMBER) --obfuscate --split-debug-info=build/debug-info-macos

.PHONY: macos-build-pkg
macos-build-pkg:
	flutter build macos --config-only --build-number=$(MACOS_BUILD_NUMBER) --obfuscate --split-debug-info=build/debug-info-macos
	rm -rf build/macos/Runner.xcarchive build/macos/pkg
	xcodebuild -workspace macos/Runner.xcworkspace \
		-scheme Runner \
		-configuration Release \
		-archivePath build/macos/Runner.xcarchive \
		-allowProvisioningUpdates \
		archive
	xcodebuild -exportArchive \
		-archivePath build/macos/Runner.xcarchive \
		-exportPath build/macos/pkg \
		-exportOptionsPlist macos/ExportOptions.plist \
		-allowProvisioningUpdates

.PHONY: linux-build
linux-build:
	flutter build linux --release --obfuscate --split-debug-info=build/debug-info-linux

.PHONY: windows-build
windows-build:
	flutter build windows --release --obfuscate --split-debug-info=build/debug-info-windows

.PHONY: build-all
build-all: android-build-apk android-build-aab

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

.PHONY: android-release-apk-fdroid
android-release-apk-fdroid: android-build-apk-fdroid
	mkdir -p build/release
	@APK_DIR=build/app/outputs/flutter-apk; \
	for abi in armeabi-v7a arm64-v8a x86_64; do \
		cp $$APK_DIR/app-$$abi-release.apk build/release/pantry-$(VERSION)-fdroid-$$abi.apk; \
		echo "-> build/release/pantry-$(VERSION)-fdroid-$$abi.apk"; \
	done
	@echo "Run 'make fdroid-revert' to restore the ML Kit default."

.PHONY: ios-release
ios-release: ios-build-ipa
	mkdir -p build/release
	cp build/ios/ipa/*.ipa build/release/pantry-$(VERSION).ipa
	@echo "-> build/release/pantry-$(VERSION).ipa"

.PHONY: macos-release
macos-release: macos-build-pkg
	mkdir -p build/release
	cp build/macos/pkg/*.pkg build/release/pantry-$(VERSION).pkg
	@echo "-> build/release/pantry-$(VERSION).pkg"

.PHONY: linux-release
linux-release: linux-build
	mkdir -p build/release
	tar -czf build/release/pantry-$(VERSION)-linux-x64.tar.gz -C build/linux/x64/release/bundle .
	@echo "-> build/release/pantry-$(VERSION)-linux-x64.tar.gz"

.PHONY: windows-release
windows-release: windows-build
	mkdir -p build/release
	cd build/windows/x64/runner/Release && zip -r "$(CURDIR)/build/release/pantry-$(VERSION)-windows-x64.zip" .
	@echo "-> build/release/pantry-$(VERSION)-windows-x64.zip"

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

.PHONY: ios-submit
ios-submit:
	bundle exec fastlane ios submit

.PHONY: macos-upload
macos-upload:
	@echo "$(or $(DEST),testflight)" | grep -qE '^(testflight|appstore)$$' || (echo "Error: Invalid DEST '$(DEST)'. Must be: testflight, appstore"; exit 1)
	@echo "Destination: $(or $(DEST),testflight)"
	@if [ "$(or $(DEST),testflight)" = "appstore" ]; then \
		bundle exec fastlane mac release; \
	else \
		bundle exec fastlane mac beta; \
	fi

.PHONY: macos-deploy
macos-deploy: macos-build-pkg macos-upload

.PHONY: macos-submit
macos-submit:
	bundle exec fastlane mac submit

.PHONY: release-all
release-all: android-release-apk android-release-aab

.PHONY: deploy-production
deploy-production:
	$(call labeled,android-deploy,TRACK=production STATUS=completed)
	$(call labeled,ios-deploy,DEST=appstore)
	$(call labeled,macos-deploy,DEST=appstore)

.PHONY: deploy-beta
deploy-beta:
	$(call labeled,android-deploy,TRACK=beta STATUS=completed)
	$(call labeled,ios-deploy,DEST=testflight)
	$(call labeled,macos-deploy,DEST=testflight)

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
	gh api repos/chenasraf/nextcloud-pantry/contents/openapi.json$(if $(REF),?ref=$(REF)) --jq '.content' | base64 -d > openapi.json
	@echo "-> openapi.json updated$(if $(REF), (ref: $(REF)))"

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

.PHONY: widget-icons
widget-icons:
	dart run tool/generate_widget_icons.dart

.PHONY: icons
icons:
	mkdir -p assets/icon
	rsvg-convert -w 1024 -h 1024 assets/logo_icon_squircle.svg > assets/icon/icon.png
	rsvg-convert -w 1024 -h 1024 assets/logo_icon_square.svg > assets/icon/icon_ios.png
	rsvg-convert -w 1024 -h 1024 assets/logo_icon_foreground.svg > assets/icon/icon_foreground.png
	rsvg-convert -w 1024 -h 1024 assets/logo_icon_macos.svg > assets/icon/icon_macos.png
	dart run flutter_launcher_icons
	rsvg-convert -w 512 -h 512 assets/logo_icon_squircle.svg > fastlane/metadata/android/en-US/images/icon.png

.PHONY: splash
splash:
	mkdir -p assets/icon
	rsvg-convert -h 1152 --page-width 1920 --page-height 1920 --top 384 --left 384 assets/logo_icon.svg > assets/icon/splash.png
	dart run flutter_native_splash:create
