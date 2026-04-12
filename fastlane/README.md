fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Upload AAB to Google Play

### android metadata

```sh
[bundle exec] fastlane android metadata
```

Sync metadata and screenshots only (no AAB upload)

### android promote

```sh
[bundle exec] fastlane android promote
```

Promote a release from one track to another

----


## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Upload to App Store

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
