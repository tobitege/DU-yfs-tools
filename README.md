# DU-yfs-tools

## Introduction

Unofficial commands for the [YFS flight script](https://github.com/PerMalmberg/du-yfs-wiki) by Yoarii (SVEA) for Dual Universe (DU).
Credits to parts of the open software code to Yoarii, Archaegeo and EasternGamer.

Big thanks for Wolfram for his awesome tool [DU-LuaC](https://github.com/wolfe-labs/DU-LuaC)
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
- Install onto the board the "yfs-tools.json" script from either
the "out\development" or "out\release" folders (see installation section below).

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

## Credits

Big thanks to Matt for [DU-LuaC](https://github.com/wolfe-labs/DU-LuaC) and
Yoarii (of DU's SVEA org) for their work and plentiful help they provided!

For YFS itself, consult the [YFS Wiki](https://github.com/PerMalmberg/du-yfs-wiki)
and contact Yoarii in game or discord.

Credits to 1337joe for the [du-mocks](https://github.com/1337joe/du-mocks) project
(most of it is included in the util/dumocks folder), that is invaluable for
debugging the lua scripts outside of the game in VSCode.
