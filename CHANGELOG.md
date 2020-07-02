# CHANGELOG for FreeoiL Format based on https://keepachangelog.com/
## [Unreleased] - 
### Added
### Changed
### Fixed
### Removed

## [0.4.0] - In Development
### Added
### Changed
### Fixed
### Removed

## [0.3.0] - 2020-06-30
### Added
- Added icons and improved the menu to make the different status more obvious to the user.
- Added more game configuration options, different gun types, more game mode options.
- Added sounds that now trigger off network events.
- Added score tracking and score board.
- Added in game voice guidance.
### Changed
- Changed the settings to an improved module that utilizes signals and can sync across the network.
- Improved the lobby a lot!
- Changed the menu and gun connection icons.
- Dramatically improved menus and reduced the loading time and time between setting up options.
- Expanded testing to include some unit testing and lots of integration testing to include multiplayer game testing.
### Fixed
- Fixed entering the game without a gun conencted causing a crash and or crashing mid game if a gun disconnects.
- Fixed networking so that full drop in and out support during a game now works.
- Fixed existing game options to actually all work without conflicts.
- Fixed SR-12 battery level reporting.
### Removed

## [0.2.0-rc1] - 2018-11-30
### Added
- Added 2 Player Integration testing.
- Improved setters and getters for all shared settings.
- Added GitLab Continuous Integration (CI)
- Added Documentation in Markdown via ReadTheDocs.io
- Added history tracking and event exchange code to networking.
- Added scenes for Lobbies for Networking.
- Finished Battery Meter.
- Added networking support code for a Lobby.
- Ammo up to 253 rounds customizable.
- Maxed players out at 63 using ids 1-63. Teams is 1-62
- Finished end of game support.
- Finished Indoor or Outdoor mode support and cone.
### Changed
- Changed SettingsConf to SetConf and consolidated shared settings.
- Increased the size of widgets to make them easier to touch on small screens.
- Changed "Connect Weapon" button into gun image created by Prestonnovation.
### Fixed
- Fixed vibrate on android causing crash.
- Improved Android Bluetooth LE GATT implementation for more devices.
### Removed
- Unnecessary Java code. 

## [0.1.0] - 2018-10-23
### Added 
- All scenes needed to make the game playable and to support options.
- No Network Multiplayer Teams.
- No Network Multiplayer Free-For-All.
- Support for LazerCoiL module to Godot
- Support for telemetry data. 
- Support for reloading.
- Set gun ID.
- Connect to gun.
- Support for Bluetooth enabling, scanning, connecting, service discovery, and GATT.
- Support for Fine Access Permission.
- Permissions passing to Godot and support to LazerCoiL module.
- Toast support.
- Logging via godot.
