fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios certificates

```sh
[bundle exec] fastlane ios certificates
```

Sync development and App Store certificates and provisioning profiles via Match

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Build and deploy to TestFlight
Usage: bundle exec fastlane deploy

### ios bump_version

```sh
[bundle exec] fastlane ios bump_version
```

Bump marketing version in Project.swift and commit
Usage: bundle exec fastlane bump_version version:1.2.7

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
