# CHANGELOG for FreeoiL Format based on https://keepachangelog.com/

## [Unreleased] - 
### Added
- Added history tracking and event exchange code to networking.
- Added scenes for Lobbies for Networking.
- Finished Battery Meter.
- Added networking support code for a Lobby.
- Ammo up to 253 rounds customizable.
- Maxed players out at 63 using ids 1-63. Teams is 1-62
- Finished end of game support.
- Finished Indoor or Outdoor mode support and cone.
### Changed
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