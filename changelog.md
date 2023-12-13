# Changelog

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
