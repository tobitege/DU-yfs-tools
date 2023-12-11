# Changelog

## v1.6.0

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
