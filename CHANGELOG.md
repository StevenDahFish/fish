# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.5] - 2024-08-10

### Changed

- Moved "self" type definition to root (init.lua) in order to be importable by service modules

## [1.0.2 - 1.0.4] - 2024-08-10

### Changed

- Updating wally.toml to get the package functionality working correctly
- Update require paths to be relative

## [1.0.1] - 2024-08-09

### Added

- This CHANGELOG file.
- Comments to describe the type definitions
- Runtime typechecking example in tests

### Changed

- .luaurc now ignores type error "LocalShadow" due to impeding imports of services in controllers

### Removed

- Unused Roblox service references in tests
- Irrelevant TODO comments

## [1.0.0] - 2024-08-09

### Added

- The base functionality of the entire framework!

[unreleased]: https://github.com/StevenDahFish/fish/compare/v1.0.5...HEAD
[1.0.5]: https://github.com/StevenDahFish/fish/compare/v1.0.4...v1.0.5
[1.0.2 - 1.0.4]: https://github.com/StevenDahFish/fish/compare/v1.0.1...v1.0.4
[1.0.1]: https://github.com/StevenDahFish/fish/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/StevenDahFish/fish/releases/tag/v1.0.0