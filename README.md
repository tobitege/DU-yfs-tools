# DU-yfs-tools 1.7.2

## Introduction

Unofficial commands for the [YFS flight script](https://github.com/PerMalmberg/du-yfs-wiki) by Yoarii (see DU's SVEA org) for Dual Universe (DU).
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

This script offers several commands for the LUA chat window in DU to assist with the handling of waypoints and routes. Several commands create a list of YFS commands to recreate waypoints and/or routes
(screen as output) which can then be copied to a local file as backup or re-used on a different construct.

It also comes with a flexible warp cell calculator command taking into account the current construct's mass and optionally a cargo mass and can output the cells to a specific location or all planets in range.

The script *can* be run at the same time as YFS, but it is highly recommended to not use commands, that alter or add waypoints or routes whilst YFS is running!

Upon start of the programming board it will auto-detect links and echo whether the core, databank and screen were found.

It will then read all routes and named waypoints from the databank and await commands via the LUA chat. All commands start with a "/" as to not interfere with YFS commands.

Type "/help" in LUA chat to get a command list displayed (in LUA chat as well as the connected screen).

If a command cannot find needed parameters, it will say so in chat and most often provide a usage example.

# Commands

A variety of LUA chat commands allow to export data, create commands lists or change routes.
Most commands are specific to YFS, but there are a couple of general purpose and ArchHUD related commands as well.

It is highly recommended to NOT use commands whilst flying via any route in YFS!

Commands are entered into LUA chat and all start with a forward slash (/) character in order to not collide with YFS' own commands.
Additional parameters are usually prefixed with a dash (-).

Any route or waypoint names should be enclosed in single quotes especially when they contain blanks in their names.

If a command is entered with missing parameters, the script will usually output an appropriate error message and provide an example.

The pipe symbol (|) in below command parameters is meant as " or ", i.e. a|b|c means a or b or c, exactly one of them.

If a parameter is enclosed in square brackets [] means it is optional or only used in special scenarios.

## ArchHud related

This script automatically detects stored locations in the connected databank, which could be one used by an ArchHUD script. This allows to e.g. export ArchHud locations to a list of commands to add these to a route in YFS or vice versa. For ArchHud this script only *reads* its data upon start and does not change locations in an ArchHud databank.

- **/arch-save-named**

Builds a list of chat commands for ArchHud to add locations for all named waypoints.

## General purpose

- **/wp-export**

Outputs list of all loaded waypoints to LUA chat (with name) and to an optionally linked screen. Sources for these waypoints can be both ArchHud's saved locations as well as YFS's, depending on what kind of databank is linked.

- **/planetInfo** [id|'name']

Displays some basic info mainly from the Atlas about the current planet (no parameters), a given planet id (e.g. 2 for Alioth) or by name like Jago.
The following examples will output the same result:
Example 1: `/planetInfo Madis`
Example 2: `/planetInfo 11`

```lua
Executing /planetInfo with: 11
~~~~~~~~ PLANET INFO ~~~~~~~~
Name: Madis Moon 2 (Id: 11)
Center: 17194626.0 / 22243633.88 / -214962.81
Radius: 12000.0m
Gravity: 0.942 (0.1 g)
Surface Min Alt.: -4018.44m
Surface Max Alt.: 651.737m
Max Static Alt.: 2500.0m
Has atmosphere: false
Is in Safe Zone: true
~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

- **/printAltitude**

Outputs to chat the construct's current altitude in meters.
Note: this can be "above" ground depending on the construct size and buildbox center!

- **/printPos**

Outputs to chat the current position as a local ::pos{} string, i.e. if close to or on a planet, it will include the planet's id in the ::pos string, like ::pos{0,2, ...} for Alioth.
Note: this can be "above" ground depending on the construct size and buildbox center!

- **/printWorldPos**

Outputs to chat the current position in world coordinates, i.e. the ::pos string will start with "0,0," instead of a planet's id and can have both positive and negative values across the x,y,z axis.
Note: this can be "above" ground depending on the construct size and buildbox center!

- **/DumpPoints**

A dev helper: outputs to chat all loaded waypoints in structured format.

- **/DumpRoutes**

A dev helper: outputs to chat all routes existing in the YFS databank.

## Special features

- **/findCenter** 'routename'

Calculates the approximate center between all points of the given route. The result is output to the LUA chat and also set as a waypoint.
For larger mining operations it can be of great help to set up a central "center" hub to use with maximum container link range and then go about your business of calibrations and/or collecting ore.

- **/warpCost** -from 'name'|::pos{}|planets -to 'name'|::pos{}|planets [-mass *tons*] [-cargo *tons*] [-moons]

Flexible warp cell calculator taking into account the current construct's mass and location.
At least one of *-from* and *-to* parameters must be specified, the other will then be determined from the construct (closest planet). Both accept either a planet's name, a ::pos{...} string or the keyword planets itself.

The latter actually generates a whole list of cell costs for all planets in the Atlas, not just the current one.

If the *-moons* parameter is present, it will also include all moons.

Mass is obviously a key factor in the calculation. By default it would use the current construct's total mass for it.
But with e.g. "**-mass 1234**" added, the script will use 1234 tons instead.

Example 1: `/warpCost -from Madis -to Alioth -mass 534`

Example 2: `/warpCost -from Alioth -to planets -moons`

Example 3: `/warpCost -from Madis -to planets -mass 534 -cargo 234`

Output in LUA chat will give a list of roundtrips: first trip with cargo and the return trip "empty" (no cargo):

```LUA
Executing /warpCost with: -from Madis -to planets -mass 534 -cargo 234
~~~ WARP CELL CALCULATOR ~~~
Current planet: Alioth
Mass: 534.0 tons  ~*~  Cargo: 234.0 tons
From: Madis
To (Distance) / Cells / Return w/o cargo
Madis (142.19 SU) = 18 cells / 10 cells = 28 total
Alioth (141.37 SU) = 18 cells / 10 cells = 28 total
Thades (142.14 SU) = 18 cells / 10 cells = 28 total
Talemai (142.05 SU) = 18 cells / 10 cells = 28 total
Sicari (142.12 SU) = 18 cells / 10 cells = 28 total
Sinnen (142.08 SU) = 18 cells / 10 cells = 28 total
Teoma (142.01 SU) = 18 cells / 10 cells = 28 total
Jago (142.01 SU) = 18 cells / 10 cells = 28 total
Point at screen, CTRL+L, then copy text!
```

Optional '*-from x*' with x being either 'here', a planet name, ::pos{} or 'planets' (multi-result).

Optional '-to x' like -from, but for end location.

Optional '-mass x' with x the total mass in tons. If not given, the current constructs' total mass is used.

Optional '-cargo x' with x the cargo mass in tons. If specified, a cell count for a return trip is calculated, too.

## YFS only

- **/yfs-build-route-from-wp**
Powerful route-building command based on existing, named "landed" waypoints.

The idea for this command came from trying to quick-start a route for a new mining spot consisting of multiple mining sites (tiles) and the desire to use the least amount of commands/work to get a Bug set up with a convenient route.

First we flew to each location, usually a tri-hex/tile corner, picked a good, flat landing location (if possible) and used YFS' commands like "**pos-save-current-as**" or "**pos-save-as**" to create a named waypoint for each, using a common "prefix" for all, like "Chr 1", "Chr 2" etc.

Once we had these locations as waypoints in YFS, the below example was used:

`/yfs-build-route-from-wp -name 'Chromite' -altitude 450 -wpStartsWith 'Chr' -suffix 'F'`

This command uses all existing waypoints, whose names start with "*Chr*", as landing locations and for each one adds an "at **F**light" waypoint above them at the specified altitude of 450 meters, thus the "F" as a suffix in the name (can be different, but should be short due to limited YFS screen space).

Be careful to select an altitude that is safe to traverse between all waypoints, better to add a safety margin of 20m than being too low and crash into some hill along the way. ;)
For waypoint "**Chr 1**" a new waypoint "**Chr 1F**" would be added and so on.

The route starts landed at "Chr 1", then moves up above it to 450m ("Chr 1F"), turns and flies to "Chr 2F" at 450 meters and finally lands at "Chr 2".

This way of "*landed -> takeoff vertically to "F" -> fly over to next waypoint's F -> land*" is then common between all waypoints. The "at flight" waypoints will be marked as "not selectable" and "not skippable" in the route itself, so only "Chr 1", "Chr 2" etc. are shown inside the route list by YFS.

*Pre-requisites:* there are multiple named waypoints in YFS that are either intended for one route *OR* can be identified by their name starting with a given string (like "*Chr*" in above example).

*Disclaimer:* due to the common altitude setting for all "at flight" waypoints, this works best for kind of flatlands with little to no difference in maximum terrain elevation between all sites.

- **/yfs-add-altitude-wp** -altitude 450 [-suffix 'F']

Adds waypoints for each existing WP at a specified altitude and name suffix. This is similar to the above command in goal and usage.

- **/wp-altitude-ceiling** 'Base 1' 'Base 2'

Determines the higher altitude of the 2 *named* waypoints, then updates the lower-altitude waypoint with that value.

- **/yfs-replace-wp** 'name'

Replaces a named waypoint with the current location. If this waypoint is part of any route, YFS should be restarted to read the updated value.

- **/yfs-route-altitude** -route 'name' -ix 2 -endIx 3 -alt 330

Changes altitude for a range of waypoints (from ix to endIx) of a specific YFS route (identified by 'name') to a specified altitude "-alt" in meters.

- **/yfs-route-nearest**

Shows a list of route waypoints by distance from the current location.
Example: `/yfs-route-nearest 'Peta'`
Sample output (shortened output; route only has unnamed waypoints, thus their index is the first value):

```lua
Executing /yfs-route-nearest with: 'Peta'
[I] Route 'Peta' found.
Route-Idx / Name / Distance (m)
13 / '13' / 0.13 m
14 / '14' / 26.48 m
12 / '12' / 169.77 m
10 / '10' / 893.43 m
11 / '11' / 901.91 m
09 / '9' / 932.43 m
15 / '15' / 1034.96 m
16 / '16' / 1038.88 m
[I] Nearest waypoint: 13: '' = 0.1341
```

- **/yfs-route-to-named**
Converts a route's *unnamed* waypoints to named waypoints for YFS.
Example: `/yfs-route-to-named 'Route 1'`

|Parameter|Comment|
|---------------------|----|
|*-onlySelectable*    | Only write waypoints marked as selectable in route|
|*-prefix 'Myprefix'* | if unspecified, 'WP' is the default|
|*-toScreen*          | output JSON of list to optional screen if linked|
|*-toDB*              | only if this is given, the changed list will be written to DB to avoid miscalls|

- **/yfs-save-named**
Creates a list of YFS commands to recreate *all* named waypoints the script loaded.
If a screen is linked, the output will be display there as well to make it easier to copy the content to e.g. a text editor for safekeeping.
*Sample output (shortened to 3 entries):*

```lua
Executing /yfs-save-named
pos-save-as 'Peta 1' -pos ::pos{0, 8, 58.4133, 20.6821, 543.3269}
pos-save-as 'Peta 10' -pos ::pos{0, 8, 57.4760, 24.8180, 637.0505}
pos-save-as 'Peta 13' -pos ::pos{0, 8, 57.1549, 23.4400, 515.3481}
```

- **/yfs-save-route**
Builds a list of YFS commands to recreate a full route setup incl. named waypoints and their options, like set margins (m) and finalSpeed values (m/s).
The result is output to LUA chat as well as an optionally linked screen.
This could then be copied off the screen buffer to an outside text editor to save it for safekeeping and can be used on other YFS-enabled constructs.
Example: `/yfs-save-route 'Peta' -onlySelectable -withOptions -prefix 'P'`
*Sample output (shortened to 3 entries):*

```lua
create-route 'Peta'
pos-save-as 'P 001' -pos ::pos{0,8,58.4133,20.6821,543.3269}
pos-save-as 'P 002' -pos ::pos{0,8,58.4129,20.6825,750.0000}
pos-save-as 'P 003' -pos ::pos{0,8,58.0159,21.0598,750.0000}
route-add-named-pos 'P 001' -margin 1
route-set-pos-option -ix 1 -toggleSkippable -finalSpeed 11.111111111111
route-add-named-pos 'P 002' -margin 1
route-set-pos-option -ix 2 -toggleSkippable -finalSpeed 11.111111111111
route-add-named-pos 'P 003' -margin 1
route-set-pos-option -ix 3 -toggleSkippable -finalSpeed 11.111111111111
route-save
```

- **/yfs-wp-altitude**
Changes altitude of a named waypoint to the specified altitude (in meters).
Example: `/yfs-wp-altitude 'Base 1' 324.12`

## Credits

Big thanks to Matt (Wolfram ingame) for [DU-LuaC](https://github.com/wolfe-labs/DU-LuaC), the waypointer script (customized version of his "userclass.lua"), the commissioned "findCenter" code and hours of chats to iron out issues and his dedication to superb solutions.

Biiig thanks to Yoarii (of DU's SVEA org) for his YFS flight script and his *plentiful* help and assistance over the past weeks! For YFS itself, consult the [YFS Wiki](https://github.com/PerMalmberg/du-yfs-wiki) and/or contact Yoarii in game or discord.

Credits to **Archaegeo** for the [ArchHud](https://github.com/Archaegeo/Archaegeo-Orbital-Hud/) project, which sparked my interest in the ingame LUA.

Credits to **1337joe** for the [du-mocks](https://github.com/1337joe/du-mocks) project.
This is invaluable for debugging lua scripts outside of the game in VSCode.
Note: the included version in the util/dumocks folder is customized in several places to improve debugging experience: do not replace with another version!

Credits to **EasternGamer** for the [AR-Library](https://github.com/EasternGamer/AR-Library/) project, which is partially included in this repo in the util\wpointer folder for special builds (not by default).
