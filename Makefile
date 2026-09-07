SHELL := bash

# .SHELLFLAGS arrived in GNU Make 3.82 and the system make on macOS is 3.81,
# where it is parsed and never read — so pipefail is carried by the recipe that
# needs it (`labeled` below) rather than by the shell flags. Without it a
# labeled step's exit status is perl's, which always succeeds, and a deploy
# aggregate runs every platform after a failing one and exits 0.
.SHELLFLAGS := -o pipefail -c

# Where a deploy aggregate's combined log lands. Truncated at the top of each
# run, gitignored, and written without the escape codes that make it readable
# on a terminal.
RELEASE_LOG := release.log
strip_ansi = perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g'

# Run a sub-make target with every stdout/stderr line prefixed by [<label>], so
# the back-to-back per-platform logs in deploy-* are easy to scan. The job runs
# under a pseudo-TTY (script) so fastlane/flutter keep their colors, and perl
# adds the prefix while stripping the pty's trailing CR and the "^D" EOF marker
# script prints on its first line.
# Usage: $(call labeled,<label>,<target>,<args>)
labeled = set -o pipefail; script -q /dev/null $(MAKE) $(2) $(3) </dev/null 2>&1 | perl -pe 'BEGIN{$$|=1} s/\r$$//; s/^\^D\x08*// if $$.==1; s/^/[$(1)] /' | tee >($(strip_ansi) >> $(RELEASE_LOG))

# Platforms a deploy aggregate may omit: `make deploy-production SKIP=macos,wear`.
# The tokens are the release workflow's `targets` vocabulary. A skipped platform
# still prints its line, so the log says what did not run.
comma := ,
empty :=
space := $(empty) $(empty)
SKIP_PLATFORMS := android wear ios macos
SKIP_LIST := $(subst $(comma),$(space),$(SKIP))

# Usage: $(call deploy_step,<platform>,<target>,<args>)
deploy_step = $(if $(filter $(1),$(SKIP_LIST)),@echo "[$(1)] skipped" | tee -a $(RELEASE_LOG),$(call labeled,$(1),$(2),$(3)))

# Version from pubspec.yaml (without build number)
VERSION := $(shell grep '^version:' pubspec.yaml | sed 's/version: *//;s/+.*//')

# Build number from pubspec.yaml (the integer after `+`)
BUILD_NUMBER := $(shell grep '^version:' pubspec.yaml | sed 's/.*+//')

# macOS uses an offset so its CFBundleVersion can never collide with iOS under
# the shared bundle ID in App Store Connect.
MACOS_BUILD_NUMBER := $(shell echo $$(($(BUILD_NUMBER) + 10000)))

# Pin rsync to system version to avoid Homebrew versions
RSYNC_SHIM := $(CURDIR)/build/.rsync-shim

.PHONY: rsync-shim
rsync-shim:
	@mkdir -p $(RSYNC_SHIM)
	@ln -sf /usr/bin/rsync $(RSYNC_SHIM)/rsync

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
	@echo "    run                 Run the app in debug mode (iOS/desktop)"
	@echo "    android-run         Run the phone app in debug mode"
	@echo "    wear-run            Run the Wear OS app in debug mode"
	@echo "    wear-emulator       Create (if needed) and boot the round Wear OS AVD"
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
	@echo "    android-install-dev Build a debug APK and install it on the connected device"
	@echo "    android-build-apk   Build Android APK"
	@echo "    android-build-apk-dev    Build a debug Android APK"
	@echo "    android-build-apk-split  Build Android split-per-ABI APKs"
	@echo "    android-build-apk-fdroid Build FLOSS (flutter_zxing) split APKs for F-Droid"
	@echo "    fdroid-lock         Regenerate the pinned F-Droid lockfile after dep changes"
	@echo "    fdroid-check        Verify the pinned F-Droid lockfile is in sync with pubspec.yaml"
	@echo "    android-build-aab   Build Android App Bundle"
	@echo "    wear-build-apk      Build Wear OS APK"
	@echo "    wear-build-aab      Build Wear OS App Bundle"
	@echo "    wear-build-apk-dev  Build a debug Wear OS APK"
	@echo "    wear-install        Build Wear OS APK and install on the connected watch"
	@echo "    wear-install-dev    Build a debug Wear OS APK and install it on the connected watch"
	@echo "    wear-variant-apk    Build a Wear OS APK with a platform switch flipped (WEAR_ARGS=)"
	@echo "    wear-coldstart      Time cold starts of the installed Wear OS build (COLDSTART_ARGS=)"
	@echo "    android-push        Build APK and push to device via adb"
	@echo "    ios-build           Build iOS (no codesign)"
	@echo "    macos-build         Build macOS app (.app bundle, no codesign)"
	@echo "    macos-build-pkg     Build signed macOS .pkg for App Store"
	@echo "    linux-build         Build Linux desktop bundle"
	@echo "    windows-build       Build Windows desktop bundle"
	@echo "    build-all           Build all platforms"
	@echo "                        Every *-install target accepts DEVICE=<id> — needed whenever a"
	@echo "                        phone and a watch are attached at once (flutter devices)"
	@echo ""
	@echo "  Release:"
	@echo "    android-release-apk Build APK and copy to build/release/"
	@echo "    android-release-apk-fdroid  Build FLOSS F-Droid APKs -> build/release/ (…-fdroid-<abi>.apk)"
	@echo "    android-release-aab Build AAB and copy to build/release/"
	@echo "    wear-release-apk    Build Wear OS APK and copy to build/release/"
	@echo "    wear-release-aab    Build Wear OS AAB and copy to build/release/"
	@echo "    ios-release         Build IPA and copy to build/release/"
	@echo "    macos-release       Build PKG and copy to build/release/"
	@echo "    linux-release       Build Linux tarball -> build/release/"
	@echo "    windows-release     Build Windows zip -> build/release/"
	@echo "    release-all         Build and release all platforms"
	@echo ""
	@echo "  Deploying:"
	@echo "    android-deploy      Build AAB and upload to Google Play (TRACK=internal|beta|production, STATUS=draft|completed)"
	@echo "    android-promote     Promote release between tracks (FROM=internal, TO=production, STATUS=draft|completed)"
	@echo "    wear-deploy         Build the Wear OS AAB and upload to Google Play's wear:<TRACK>"
	@echo "    ios-deploy          Build IPA and upload (DEST=testflight|appstore, default: testflight)"
	@echo "    ios-submit          Submit the existing App Store build for review (no upload)"
	@echo "    macos-deploy        Build PKG and upload (DEST=testflight|appstore, default: testflight)"
	@echo "    macos-submit        Submit the existing Mac App Store build for review (no upload)"
	@echo "    deploy-production   Build and deploy to production (Google Play + App Store)"
	@echo "    deploy-beta         Build and deploy to beta (Google Play beta + TestFlight)"
	@echo "                        Both accept SKIP=android,wear,ios,macos and log to release.log"

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
	cd packages/pantry_core && dart run build_runner build --delete-conflicting-outputs

.PHONY: i18n-watch
i18n-watch:
	cd packages/pantry_core && dart run build_runner watch --delete-conflicting-outputs

.PHONY: i18n-from-nextcloud
i18n-from-nextcloud:
ifndef NC_JSON
	$(error NC_JSON is required. Usage: make i18n-from-nextcloud NC_JSON=~/path/nextcloud-pantry/l10n/nn_NO.json TARGET=packages/pantry_core/lib/i18n/messages_nn.i18n.yaml)
endif
ifndef TARGET
	$(error TARGET is required. Usage: make i18n-from-nextcloud NC_JSON=~/path/nextcloud-pantry/l10n/nn_NO.json TARGET=packages/pantry_core/lib/i18n/messages_nn.i18n.yaml)
endif
	dart run tool/i18n_generate_from_nextcloud.dart $(NC_JSON) $(TARGET)

# Development
# `run` stays flavorless so it still works for iOS, macOS, Linux and Windows.
# Android now has a flavor dimension and cannot build without one — use
# `android-run` for a phone or emulator.
.PHONY: run
run:
	flutter run

.PHONY: android-run
android-run:
	flutter run --flavor phone
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
#
# Each package resolves its own dependencies, so `flutter test` from the root
# sees only the app's own suite; the workspace packages have to be entered.
PACKAGES := packages/pantry_core packages/pantry_wear

.PHONY: test
test:
ifdef FILES
	flutter test $(FILES)
else
	flutter test
	@for pkg in $(PACKAGES); do \
		echo "==> $$pkg"; \
		(cd $$pkg && flutter test) || exit 1; \
	done
endif

.PHONY: test-coverage
test-coverage:
	flutter test --coverage
	@for pkg in $(PACKAGES); do \
		echo "==> $$pkg"; \
		(cd $$pkg && flutter test --coverage) || exit 1; \
	done
	@echo "Coverage report generated at coverage/lcov.info"

# Building

# Which device an install lands on. Developing the watch means a phone and a
# watch are both plugged in, and `flutter install` refuses to choose between
# them — so name one:
#   make wear-install-dev DEVICE=192.168.68.110:43639
#   make android-install-dev DEVICE=53031FDAP000YN
# Left empty it is omitted entirely, which is right when only one device is
# attached and is how these targets have always behaved.
DEVICE :=
DEVICE_FLAG := $(if $(DEVICE),-d $(DEVICE),)

.PHONY: android-build-apk
android-build-apk:
	flutter build apk --release --flavor phone --obfuscate --split-debug-info=build/debug-info-apk
.PHONY: android-build-apk-split
android-build-apk-split:
	flutter build apk --release --flavor phone --split-per-abi --obfuscate --split-debug-info=build/debug-info-apk
.PHONY: android-install
android-install: android-build-apk
	flutter install --flavor phone $(DEVICE_FLAG)

# Debug builds, for putting the working tree on a device without waiting out an
# obfuscated release. The mode is named on both halves deliberately: `flutter
# install` builds release by default, so a debug build followed by a bare
# install reaches for an artifact this never wrote.
.PHONY: android-build-apk-dev
android-build-apk-dev:
	flutter build apk --debug --flavor phone

.PHONY: android-install-dev
android-install-dev: android-build-apk-dev
	flutter install --debug --flavor phone $(DEVICE_FLAG)

# Wear OS. A separate entrypoint (`lib/main_wear.dart`) drives the watch UI from
# packages/pantry_wear; the flavor gives it its own merged manifest, minSdk and
# versionCode. The +20000 versionCode offset that keeps the watch's code unique
# across form factors is applied by the wear flavor in
# android/app/build.gradle.kts, not here — it has to hold for any wear build,
# including one that never goes through make. The fastlane lane mirrors it to
# name the changelog file Play will look the upload up by.
WEAR_TARGET := lib/main_wear.dart
WEAR_FLAGS := --flavor wear --target $(WEAR_TARGET)

.PHONY: wear-run
wear-run:
	flutter run $(WEAR_FLAGS)

# Plain, where the bundle below is obfuscated: a sideloaded APK's only
# debugging channel is a stack trace a user pastes, and the split debug symbols
# that would decode an obfuscated one have nowhere to be published to.
.PHONY: wear-build-apk
wear-build-apk:
	flutter build apk --release $(WEAR_FLAGS)

.PHONY: wear-build-aab
wear-build-aab:
	flutter build appbundle --release $(WEAR_FLAGS) --obfuscate --split-debug-info=build/debug-info-wear

.PHONY: wear-install
wear-install: wear-build-apk
	flutter install --flavor wear $(DEVICE_FLAG)

.PHONY: wear-build-apk-dev
wear-build-apk-dev:
	flutter build apk --debug $(WEAR_FLAGS)

.PHONY: wear-install-dev
wear-install-dev: wear-build-apk-dev
	flutter install --debug --flavor wear $(DEVICE_FLAG)

# Build a wear APK with one of the platform switches flipped, for a size or
# cold-start comparison, as `key=value` pairs:
#   make wear-variant-apk WEAR_ARGS="wearImpeller=false"
#   make wear-variant-apk WEAR_ARGS="wearKeepNative=true"
#   make wear-variant-apk WEAR_ARGS="wearSwipeToDismiss=true"
WEAR_ARGS :=
COLDSTART_ARGS :=
WEAR_RELEASE_FLAGS := --release $(WEAR_FLAGS) --obfuscate --split-debug-info=build/debug-info-wear

.PHONY: wear-variant-apk
wear-variant-apk:
	flutter build apk $(WEAR_RELEASE_FLAGS) $(foreach a,$(WEAR_ARGS),--android-project-arg=$(a))

.PHONY: wear-variant-install
wear-variant-install: wear-variant-apk
	flutter install --flavor wear $(DEVICE_FLAG)

.PHONY: wear-coldstart
wear-coldstart:
	tool/wear_coldstart.sh $(COLDSTART_ARGS)

# The AVD the watch UI is developed against. Round is the shape that catches
# layout mistakes first — square is the forgiving case, and the layout is
# shape-agnostic, so nothing needs a second AVD to develop against.
# Override to check other geometry, e.g.
#   make wear-emulator WEAR_DEVICE=wear_square
#   make wear-emulator WEAR_DEVICE=wear_round_chin_320_290   # flat tire
# or the minSdk floor:
#   make wear-emulator WEAR_AVD=pantry_wear_api30 \
#     WEAR_SYSTEM_IMAGE="system-images;android-30;android-wear;arm64-v8a"
WEAR_AVD := pantry_wear_round
WEAR_DEVICE := wear_round
WEAR_SYSTEM_IMAGE := system-images;android-34;android-wear;arm64-v8a

.PHONY: wear-emulator
wear-emulator:
	@if ! avdmanager list avd -c 2>/dev/null | grep -qx "$(WEAR_AVD)"; then \
		echo "Creating AVD $(WEAR_AVD)…"; \
		yes | sdkmanager "$(WEAR_SYSTEM_IMAGE)"; \
		echo no | avdmanager create avd -n "$(WEAR_AVD)" \
			-k "$(WEAR_SYSTEM_IMAGE)" -d "$(WEAR_DEVICE)"; \
	fi
	@echo "Booting $(WEAR_AVD) — once it is up, run: make wear-run"
	emulator -avd "$(WEAR_AVD)" -no-snapshot-load

# F-Droid variant — swaps the barcode scanner from Google ML Kit
# (mobile_scanner) to the FLOSS flutter_zxing so the APK carries no proprietary
# code. `fdroid-apply` mutates pubspec.yaml + the scanner impl in place;
# `fdroid-revert` restores them. See fdroid/README.md.
.PHONY: fdroid-apply
fdroid-apply:
	tool/fdroid/apply.sh

.PHONY: fdroid-revert
fdroid-revert:
	git checkout -- pubspec.yaml pubspec.lock lib/views/checklists/barcode_scanner/barcode_camera_scanner.dart packages/pantry_core/pubspec.yaml packages/pantry_core/lib/widgets/avif_image.dart android/app/build.gradle.kts android/app/src/main/kotlin/dev/casraf/pantry/DataLayerChannel.kt
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
	git checkout -- pubspec.yaml pubspec.lock lib/views/checklists/barcode_scanner/barcode_camera_scanner.dart packages/pantry_core/pubspec.yaml packages/pantry_core/lib/widgets/avif_image.dart android/app/build.gradle.kts android/app/src/main/kotlin/dev/casraf/pantry/DataLayerChannel.kt; \
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
		flutter build apk --release --flavor phone --split-per-abi --target-platform="$$1"; \
		mv build/app/outputs/flutter-apk/app-"$$2"-phone-release.apk "$$OUT/app-$$2-release.apk"; \
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
	adb push build/app/outputs/flutter-apk/app-phone-release.apk /sdcard/Download/pantry-$(VERSION).apk
	@echo "-> /sdcard/Download/pantry-$(VERSION).apk"

.PHONY: android-build-aab
android-build-aab:
	flutter build appbundle --release --flavor phone --obfuscate --split-debug-info=build/debug-info-aab
.PHONY: ios-build
ios-build:
	flutter build ios --release --no-codesign --obfuscate --split-debug-info=build/debug-info-ios
.PHONY: ios-build-ipa
ios-build-ipa: rsync-shim
	PATH="$(RSYNC_SHIM):$$PATH" flutter build ipa --release --obfuscate --split-debug-info=build/debug-info-ios --dart-define-from-file=.env --export-options-plist=ios/ExportOptions.plist

.PHONY: macos-build
macos-build:
	flutter build macos --release --build-number=$(MACOS_BUILD_NUMBER) --obfuscate --split-debug-info=build/debug-info-macos

.PHONY: macos-build-pkg
macos-build-pkg: rsync-shim
	flutter build macos --config-only --build-number=$(MACOS_BUILD_NUMBER) --obfuscate --split-debug-info=build/debug-info-macos
	rm -rf build/macos/Runner.xcarchive build/macos/pkg
	xcodebuild -workspace macos/Runner.xcworkspace \
		-scheme Runner \
		-configuration Release \
		-archivePath build/macos/Runner.xcarchive \
		-allowProvisioningUpdates \
		archive
	PATH="$(RSYNC_SHIM):$$PATH" xcodebuild -exportArchive \
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
	cp build/app/outputs/flutter-apk/app-phone-release.apk build/release/pantry-$(VERSION).apk
	@echo "-> build/release/pantry-$(VERSION).apk"

.PHONY: android-release-aab
android-release-aab: android-build-aab
	mkdir -p build/release
	cp build/app/outputs/bundle/phoneRelease/app-phone-release.aab build/release/pantry-$(VERSION).aab
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

.PHONY: wear-release-apk
wear-release-apk: wear-build-apk
	mkdir -p build/release
	cp build/app/outputs/flutter-apk/app-wear-release.apk build/release/pantry-$(VERSION)-wear.apk
	@echo "-> build/release/pantry-$(VERSION)-wear.apk"

.PHONY: wear-release-aab
wear-release-aab: wear-build-aab
	mkdir -p build/release
	cp build/app/outputs/bundle/wearRelease/app-wear-release.aab build/release/pantry-$(VERSION)-wear.aab
	@echo "-> build/release/pantry-$(VERSION)-wear.aab"

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

# The watch has tracks of its own — the lane prefixes `wear:` — and releases
# independently of the mobile track, so TRACK here names the wear track.
.PHONY: wear-upload
wear-upload:
	@echo "$(or $(TRACK),beta)" | grep -qE '^(internal|alpha|beta|production)$$' || (echo "Error: Invalid TRACK '$(TRACK)'. Must be: internal, alpha, beta, production"; exit 1)
	@echo "$(or $(STATUS),draft)" | grep -qE '^(draft|completed|halted|inProgress)$$' || (echo "Error: Invalid STATUS '$(STATUS)'. Must be: draft, completed, halted, inProgress"; exit 1)
	@echo "Track: wear:$(or $(TRACK),internal) | Status: $(or $(STATUS),draft)"
	bundle exec fastlane deploy_wear track:$(or $(TRACK),internal) status:$(or $(STATUS),draft)

.PHONY: wear-deploy
wear-deploy: wear-build-aab wear-upload

.PHONY: release-all
release-all: android-release-apk android-release-aab

# A SKIP typo fails by silently *doing* the platform it was meant to omit,
# which is why it is validated the way TRACK, STATUS and DEST are.
.PHONY: check-skip
check-skip:
	@for t in $(SKIP_LIST); do \
		case " $(SKIP_PLATFORMS) " in \
			*" $$t "*) ;; \
			*) echo "Error: Invalid SKIP platform '$$t'. Must be one of: $(SKIP_PLATFORMS)"; exit 1;; \
		esac; \
	done

.PHONY: release-log-reset
release-log-reset:
	@: > $(RELEASE_LOG)

.PHONY: deploy-production
deploy-production: check-skip release-log-reset
	$(call deploy_step,android,android-deploy,TRACK=production STATUS=completed)
	$(call deploy_step,wear,wear-deploy,TRACK=production STATUS=completed)
	$(call deploy_step,ios,ios-deploy,DEST=appstore)
	$(call deploy_step,macos,macos-deploy,DEST=appstore)

.PHONY: deploy-beta
deploy-beta: check-skip release-log-reset
	$(call deploy_step,android,android-deploy,TRACK=beta STATUS=completed)
	$(call deploy_step,wear,wear-deploy,TRACK=beta STATUS=completed)
	$(call deploy_step,ios,ios-deploy,DEST=testflight)
	$(call deploy_step,macos,macos-deploy,DEST=testflight)

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
