fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### release_all

```sh
[bundle exec] fastlane release_all
```

Complete release workflow for both iOS and Android

Assumes version and CHANGELOG.md have already been updated by Claude

This will:

  1. Build and upload iOS to App Store

  2. Build Android AAB and open folder for Google Play upload

----


## iOS

### ios release

```sh
[bundle exec] fastlane ios release
```

Build IPA and upload to App Store Connect with metadata

Options:

  bump_type: 'major', 'minor', 'patch' to bump version number (optional, defaults to 'minor')

Examples:

  fastlane release                    # Bump minor version (default: 1.9.0 -> 1.10.0)

  fastlane release bump_type:patch    # Bump patch version (1.9.0 -> 1.9.1)

  fastlane release bump_type:minor    # Bump minor version (1.9.0 -> 1.10.0)

  fastlane release bump_type:major    # Bump major version (1.9.0 -> 2.0.0)

----


## Android

### android release

```sh
[bundle exec] fastlane android release
```

Build Android App Bundle and open folder for Google Play upload

Options:

  bump_type: 'major', 'minor', 'patch' to bump version number (optional, defaults to 'minor')

Examples:

  fastlane android release                    # Bump minor version and build AAB

  fastlane android release bump_type:patch    # Bump patch version and build AAB

  fastlane android release bump_type:minor    # Bump minor version and build AAB

  fastlane android release bump_type:major    # Bump major version and build AAB

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
