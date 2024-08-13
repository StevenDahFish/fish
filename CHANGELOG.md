# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.7] - 2024-08-12

### Added

- ClientRemoteSignal and ClientRemoteProperty types to DependencyTypes.lua and exported them in root (init.lua) in order to be importable by service modules

## [1.0.6] - 2024-08-10

### Added

- Documentation to the entire project using [Moonwave](https://github.com/evaera/moonwave)

### Changed

- Moved server started object indicator into the package instead of ReplicatedFirst to prevent potential future interference with the client starting
- README was changed to include information about documentation

### Removed

- A `!nonstrict` comment that was put in Server.lua mistakenly during testing

### Fixed

- Invalid reference in ClientService.lua when ran in context

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

[unreleased]: https://github.com/StevenDahFish/fish/compare/v1.0.7...HEAD
[1.0.7]: https://github.com/StevenDahFish/fish/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/StevenDahFish/fish/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/StevenDahFish/fish/compare/v1.0.4...v1.0.5
[1.0.2 - 1.0.4]: https://github.com/StevenDahFish/fish/compare/v1.0.1...v1.0.4
[1.0.1]: https://github.com/StevenDahFish/fish/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/StevenDahFish/fish/releases/tag/v1.0.0