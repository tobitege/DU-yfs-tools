# Changelog

## v1.7.7

- Fix in /yfs-save-route to correctly use "route-create", not "create-route" in command generation

## v1.7.6

- Fix for interim bug in */yfs-build-route-from-wp* if no -suffix was specified
- Updated ingame /help commands list (added /yfs-options-reset)

## v1.7.5

- Added command */yfs-options-reset* to reset certain route-options for a range of waypoints in a given route
- Fix: command */yfs-route-altitude* finally treats -endIx parameter as optional
- Updated README again. Even more elaborate on /yfs-build-route-from-wp

## v1.7.4

- Fix for /yfs-route-altitude not changing altitude in named waypoints due to typo
- Updated README with LUA parameters

## v1.7.3

- Fix for interim bug in Atlas data loading (pos.lua) causing the warp cell calculation to be wrong
- Fixed example for /warpCost command with correct values

## v1.7.2

- Fixed */yfs-route-altitude* and */yfs-route-nearest* commands to also work with unnamed waypoints in a route
- Fixed */planetInfo* command to accept a number again (as the Atlas id)
- LUA chat input is being trimmed first so accidental whitespace does not prevent "/" commands being recognized
- Updated README.md to finally include an extensive overview of all commands with examples

## v1.7.1

- AR Waypoint label font name+size changed for better readability
- AR Waypoint symbol in orange if > 2.25km away (max container link range)
- AR Waypoint distances: decimals staggered, normally 2, but between 10 and 1000 only 1 decimal
- Added LUA parameter wpRenderLimit to specify the km within which range waypoints are displayed (default: 5)
- If within 10m of a waypoint, its name will be displayed at center-left screen border for info
- Improved AR performance and removed unneeded code
- Hint: AR waypointer display can be turned off via LUA parameters
- To compile: update DU-LuaC to v1.3.2 at least

## v1.7.0

- Added command "/findCenter 'routename' -selectableOnly" to calculate the center point for a specified route's waypoints (only YFS support right now).
Useful to find a location to place a central hub reachable from all mining sites around it
Credits to Matt (Wolfe Labs) for this commissioned, custom LUA code!
More about this feature to come in the near future! ;)
- Improved AR waypoints' shadows for readability
- Switched AR waypoints' color to lime
- Renamed some files

## v1.6.2

- Added 2nd AR waypointer solution based on Wolfe Labs' "userclass" for ArchHud
- WP version now states which (if any) waypoints are loaded during startup
- Local debugging: enter q and **ENTER** to close the emulated chat in console (ends debugging session)
- Local debugging: emulated chat in console also runs onTimer on each **ENTER** for testing
- Local debugging: each prompt starts with emulated ArkTime() (only works for the mocks included in this repo!)
- DU-Mocks: added getInstructionCount() and getInstructionCount() to system
- Added "buildall.cmd" to run all DU-LuaC targets
- Changed the cmd files to include as first line a LUA_PATH configuration
- Changed project.json to explicitly set DEBUG variable with either true or false for all targets for clarity
- Added EasternGamer's "HUD" debug info to unit_onTimer(update).lua for the wp development version (DEBUG is on)
- Out subfolders now also have compiled Release builds
- Fixed startup display for lua param "Only waypoints for route:"
- Smaller cosmetics (removed some trailing spaces)

## v1.5.0

- Fixed: I had broken the waypointer version :( (build with w.cmd in console)
- Code cleanup, some files renamed, filled some mocks with life
