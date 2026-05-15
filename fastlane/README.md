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

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Sync iOS metadata only (no IPA upload)

### ios submit

```sh
[bundle exec] fastlane ios submit
```

Submit existing App Store build for review (no IPA upload)

----


## Mac

### mac beta

```sh
[bundle exec] fastlane mac beta
```

Upload to TestFlight (macOS)

### mac release

```sh
[bundle exec] fastlane mac release
```

Upload to Mac App Store

### mac metadata

```sh
[bundle exec] fastlane mac metadata
```

Sync macOS metadata only (no PKG upload)

### mac submit

```sh
[bundle exec] fastlane mac submit
```

Submit existing Mac App Store build for review (no PKG upload)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
