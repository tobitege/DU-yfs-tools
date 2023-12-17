# DU-yfs-tools

## Introduction

Unofficial commands for the [YFS flight script](https://github.com/PerMalmberg/du-yfs-wiki) by Yoarii (SVEA) for Dual Universe (DU).
Credits to parts of the open software code to Yoarii, Archaegeo and EasternGamer.

Big thanks to Wolfram for his awesome tool [DU-LuaC](https://github.com/wolfe-labs/DU-LuaC)
with which this project was built to create "ready-to-install" JSON files for DU.
**I love that tool! :)**

The "out" folder contains the latest builds in the "development"
and "release" sub-folders. The "development" version keeps the source
in a readable format whereas the "release" version is a much compressed
version to save space on the programming board (ingame).

## Setup

### Required elements

- 1 programming board
- 1 screen
The screen itself is mostly optional as most output is via LUA chat, but offers
the easiest way to get generated output of commands copied to the clipboard
(CTRL+L when pointing at screen)
- a flight construct with YFS installed -> link to the "Routes" databank

- Deploy the programming board and the screen on the construct
- Link the constructs' core to the board.
- If present, link a new screen to the board (never use the YFS screen!)
- Link the existing YFS databank named "Routes" to the board.
- Install onto the board the "yfs-tools.json" script from either the "out\development-wp" or "out\release-wp" folders (see installation section below).

The "development-wp" version is recommended for use now as the integrated waypointing for routes is working very well and just awesome to have. :)

### Script Installation

General installation steps in DU:

For *programming boards* open a .json file in the above mentioned out\development
(or out\release) folder, copy its full content to clipboard and in game right
click the programming board to get the "Advanced" menu. Then click the menu item
"Paste Lua configuration from clipboard" to have the script installed on it.

## Usage

This script offers several commands for the LUA chat window in DU to
assist with the handling of waypoints and routes. Several commands
create a list of YFS commands to recreate waypoints and/or routes
(screen as output) which can then be copied to a local file as backup
or re-used on a different construct.

It also comes with a flexible warp cell calculator command taking into
account the current construct's mass and optionally a cargo mass
and can output the cells to a specific location or all planets in range.

The script *can* be run at the same time as YFS, but it is highly
recommended to not use commands, that alter or add waypoints or
routes whilst YFS is running!

Upon start of the programming board it will auto-detect links and
echo whether the core, databank and screen were found.

It will then read all routes and named waypoints from the databank
and await commands via the LUA chat. All commands start with a "/"
as to not interfere with YFS commands.

Type "/help" in LUA chat to get a command list displayed (in LUA chat
as well as the connected screen).

If a command cannot find needed parameters, it will say so in chat
and most often provide a usage example.

# Commands

A variety of LUA chat commands allow to export data, create commands lists or change routes.
Most commands are specific to YFS, but there are a couple of general purpose and ArchHUD related commands as well.
It is highly recommended to NOT use commands whilst flying via any route in YFS!
Commands are entered into LUA chat and all start with a forward slash (/) character in order to not collide with YFS' own commands.
Additional parameters are usually prefixed with a dash (-).
Any route or waypoint names should be enclosed in single quotes especially when they contain blanks in their names.
If a command is entered with missing parameters, the script will usually output an appropriate error message and provide an example.

## ArchHud related

This script automatically detects stored locations in the connected databank, which could be one used by an ArchHUD script. This allows to e.g. export ArchHud locations to a list of commands to add these to a route in YFS or vice versa. For ArchHud this script only *reads* its data upon start and does not change locations in an ArchHud databank.

- /arch-save-named
Builds a list of chat commands for ArchHud to add locations for all named waypoints.

## General purpose

- /findCenter *routename*
Calculates center between all points of a route, like for a central hub.
- /planetInfo (id or name)
Info about current planet (no parameters), a given planet id (e.g. 2 for Alioth) or by name like Jago.
- /printAltitude
Outputs to chat the current altitude in meters.
- /printPos
Outputs to chat the current position as a local ::pos string, i.e. if close to/on a planet, it will include the planet's id in the ::pos string, like ::pos{0,2, ...} for Alioth.
- /printWorldPos
Outputs to chat the current position in absolute world coordinates, i.e. the ::pos string will start with "0,0," instead of a planet's id.
- /warpCost -from *name*/::pos{}/planets -to *name*/::pos{}/planets -mass *tons* -moons
Flexible warp cell calculator. At least one of -from and -to parameters must be specified, the other will be the current construct's planet. Both accept either a planet's name, a ::pos string or the keyword planets. The latter will generate a list of cell costs for all planets. If the -moons parameter is specified, it will also include moons.
Mass is very important for the calculation. By default it would use the current construct's total mass for it. But with e.g. "-mass 1234" added, the script will use 1234 tons instead.

## YFS only

- /wp-altitude-ceiling
Of 2 *named* waypoints, changes one waypoint to have the higher altitude of both.
- /wp-export
Outputs list of plain waypoints to chat and an optional screen. Source can include ArchHud locations, too, if databank linked.
- /yfs-add-altitude-wp
Adds waypoints for each existing WP at a specified altitude and name suffix.
- /yfs-build-route-from-wp
Powerful route-building command based on existing named waypoints.
- /yfs-replace-wp 'name'
Replaces a named waypoint with the current location. If a route uses this waypoint, YFS should be restarted to read the updated value.
- /yfs-route-altitude -route 'name' -ix 2 -endIx 3 -alt 330
Changes altitude for a range of waypoints (from ix to endIx) of a specific YFS route (identified by name) to a specified altitude "-alt" in meters.
- /yfs-route-nearest
Show list of route waypoints by distance from current location.
- /yfs-route-to-named
Converts a route's *unnamed* waypoints to named waypoints for YFS.
- /yfs-save-named
Builds list of YFS commands to recreate all named waypoints.
- /yfs-save-route
Builds list of YFS commands to recreate full route incl. named waypoints and their options.
- /yfs-wp-altitude
Changes altitude of a named waypoint to specified altitude.

## Credits

Big thanks to Matt for [DU-LuaC](https://github.com/wolfe-labs/DU-LuaC) and
Yoarii (of DU's SVEA org) for their work and plentiful help they provided!

For YFS itself, consult the [YFS Wiki](https://github.com/PerMalmberg/du-yfs-wiki)
and contact Yoarii in game or discord.

Credits to 1337joe for the [du-mocks](https://github.com/1337joe/du-mocks) project
(most of it is included in the util/dumocks folder), that is invaluable for
debugging the lua scripts outside of the game in VSCode.
