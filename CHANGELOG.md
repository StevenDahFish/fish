# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Changed all references to "server" type in services to use "self" instead due to context being missed

## [1.1.7]

### Changed
- self.confirm() now returns the value passed to it, similar to assert()
- Clarified error message on client when obfuscation is enabled

### Fixed
- Type definition "{Start: never}" causing inability to reference service/controller using variable

## [1.1.6]

### Added
- Documentation for fish
- Client.Signal table in services as a different way to create a signal and listen to it
- self.confirm() in public service functions as a drop-in replacement for assert(), but silently fails instead of throwing an error
- Option to obfuscate service & controller names on the client during runtime
- If a service/controller takes more than 5 seconds to be required, a warning will be outputted assuming that it's waiting on something for too long
- Unreliable signals are able to be created now
- Acknowledgements to the documentation page & linked in README

### Changed
- Made all functions in services and controllers explicitly define self for better autocompletion
- Due to limitations of how self.confirm() was implemented, errors in services will no longer be sent to the client while playtesting in Studio

## [1.1.5] - 2025-03-15

### Added
- If a service/controller is attempted to be created even though its "@load" declares otherwise, a warning will be outputted
- Description about the "@load" module functionality for controllers in the documentation

### Changed
- When creating controllers, you now need to provide its own instance for "@load" warnings to work
- Controllers in the test folder now provide its own script instance as required in this version

### Fixed
- "@load" module being required when either .serviceDeep() or .controllerDeep() was being used

## [1.1.4] - 2025-03-06

### Fixed
- Multiple of the same directories being made when structuring for the client with .serviceDeep()

### Changed
- Services in the tests folder now provide its own script instance as required in v1.1.2

## [1.1.3] - 2025-02-24

### Added
- "@load" module functionality for controllers

## [1.1.2] - 2025-02-22

### Added
- Directory structuring when adding services with .serviceDeep()
- You can provide an "@load" module in the same directory as a service that returns a function that returns a boolean that determines whether a module should be loaded on start

### Changed
- When creating services, you now need to provide its own script instance for directory structuring to work

### Fixed
- Type definitions with extra whitespace

### Removed
- getServiceNames() from Client as it was redundant

## [1.1.1] - 2025-01-08

### Added
- Controllers can now specify a load order which affects which Start function runs first

### Removed
- Unused Wally dependency Cmdr
- Redundant Wally dependency TableUtil

## [1.1.0] - 2024-09-22

### Added
- Mutex integration into client functions of services

## [1.0.9] - 2024-09-13

### Changed
- ClientService reference is no longer public in the Client module

### Fixed
- The Start function on services will now run if the Client table is empty
- If the server takes longer to load, the client will now properly wait to initialize

## [1.0.8] - 2024-08-29

### Added

- Limitations section to README about cyclic dependencies
- Home page to documentation site
- Docs page to make home page button link work

### Changed

- Services that have nothing in the Client table (has nothing public) is hidden from the client entirely

### Fixed

- Added `@ignore` comment to ClientRemoteSignal and ClientRemoteProperty types to prevent being added to documentation site

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

[Unreleased]: https://github.com/StevenDahFish/fish/compare/v1.1.7...HEAD
[1.1.7]: https://github.com/StevenDahFish/fish/compare/v1.1.6...v1.1.7
[1.1.6]: https://github.com/StevenDahFish/fish/compare/v1.1.5...v1.1.6
[1.1.5]: https://github.com/StevenDahFish/fish/compare/v1.1.4...v1.1.5
[1.1.4]: https://github.com/StevenDahFish/fish/compare/v1.1.3...v1.1.4
[1.1.3]: https://github.com/StevenDahFish/fish/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/StevenDahFish/fish/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/StevenDahFish/fish/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/StevenDahFish/fish/compare/v1.0.9...v1.1.0
[1.0.9]: https://github.com/StevenDahFish/fish/compare/v1.0.8...v1.0.9
[1.0.8]: https://github.com/StevenDahFish/fish/compare/v1.0.7...v1.0.8
[1.0.7]: https://github.com/StevenDahFish/fish/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/StevenDahFish/fish/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/StevenDahFish/fish/compare/v1.0.4...v1.0.5
[1.0.2 - 1.0.4]: https://github.com/StevenDahFish/fish/compare/v1.0.1...v1.0.4
[1.0.1]: https://github.com/StevenDahFish/fish/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/StevenDahFish/fish/releases/tag/v1.0.0