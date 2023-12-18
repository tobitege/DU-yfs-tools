# DU-yfs-tools 1.7.4

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

Type "**/help**" in LUA chat to get a command list displayed (in LUA chat as well as the connected screen).

If a command cannot find needed parameters, it will say so in chat and most often provide a usage example.

## LUA parameters

- **onlyForRoute**

Enter here a route name (in double-quotes!) to only load waypoints of that route for the waypointer module. If no route is specified, this should only contain 2 double-quotes, like this: ""

- **onlySelectableWP**

By default this option is checked so that only route waypoints, that are marked as selectable in YFS, will be loaded and displayed by the waypointer module. This option is only applied for a linked YFS databank.

- **loadWaypoints**

By default this option is checked to enable the loading of any waypoints from linked databanks during startup.

- **outputFont**

The default font is "FiraMono" for the waypointer module (name must be in double-quotes). This will influence the display of names and distances of each AR marker on screen.

- **enableWaypointer**

By default this option is checked, so that the built-in waypointer module will use AR destination markers for all loaded waypoints (see above options).

- **wpRenderLimit**

Only waypoints which are within this value in kilometers range of the construct will be displayed. During flight the distances to waypoints obviously change, so some may come into range and be displayed anew and others move out of range and vanish from display.

The waypointer module can be active at the same time as other flight huds (YFS, ArchHud), but does have a little impact on performance (especially on older CPUs), more noticably with like more than 10 visible waypoints.

If need be, try using the other options "onlyForRoute" and "wpRenderLimit" to reduce the amount of concurrently processed waypoints.

Between updates the order of LUA parameters may change, but the order is of no importance.

## Commands

A variety of LUA chat commands allow to export data, create commands lists or change routes.

Most commands are specific to YFS, but there are a couple of general purpose and ArchHUD related commands as well.

It is highly recommended to NOT use commands whilst flying via any route in YFS!

Commands are entered into LUA chat and all start with a forward slash (/) character in order to not collide with YFS' own commands. Additional parameters are usually prefixed with a dash (-).

Any route or waypoint name should be enclosed in single quotes especially when they may contain blanks/spaces.

If a command is entered with missing parameters, the script will usually output an appropriate error message and provide an example.

The pipe symbol (|) in below command parameters is meant as " or ", i.e. a|b|c means a or b or c, exactly one of them.

If a parameter is enclosed in square brackets [] means it is optional or only used in special scenarios or combinations.

## ArchHud related

This script automatically detects stored locations in the connected databank, which could also be used by an ArchHUD script.

This would allow to e.g. export ArchHud saved locations as a list of ArchHud-typical commands to create sort of a backup or to be used on another ArchHud-piloted construct.

For ArchHud this script only *reads* its data upon start and does not change locations in an ArchHud databank.

### **/arch-save-named**

For each loaded waypoint a ArchHud chat command is being put out to save the waypoint as a named location. The source of the waypoint(s) could be an ArchHud or a YFS databank.

Example output:

`/addlocation test 1 ::pos{0, 2, 35.3683, 103.9990, 286.4556}`

## General purpose

### **/wp-export**

Outputs list of all loaded waypoints to LUA chat (with name) and to an optionally linked screen. Sources for these waypoints can be both ArchHud's saved locations as well as YFS's, depending on what kind of databank is linked.

### **/planetInfo** [id|'name']

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

### **/printAltitude**

Outputs to chat the construct's current altitude in meters.
Note: this can be "above" ground depending on the construct size and buildbox center!

### **/printPos**

Outputs to chat the current position as a local ::pos{} string, i.e. if close to or on a planet, it will include the planet's id in the ::pos string, like ::pos{0,2, ...} for Alioth.
Note: this can be "above" ground depending on the construct size and buildbox center!

### **/printWorldPos**

Outputs to chat the current position in world coordinates, i.e. the ::pos string will start with "0,0," instead of a planet's id and can have both positive and negative values across the x,y,z axis.
Note: this can be "above" ground depending on the construct size and buildbox center!

### **/DumpPoints**

A dev helper: outputs to chat all loaded waypoints in structured format.

### **/DumpRoutes**

A dev helper: outputs to chat all routes existing in the YFS databank.

### **/routes**

A dev helper: prints all available route names existing in the YFS databank.

## Special features

### **/findCenter** 'routename'

Calculates the approximate center between all points of the given route. The result is output to the LUA chat and also set as a waypoint.

For larger mining operations it can be of great help to set up a central "center" hub to use with maximum container link range and then go about your business of calibrations and/or collecting ore.

### **/warpCost** -from 'name'|::pos{}|planets -to 'name'|::pos{}|planets [-mass *tons*] [-cargo *tons*] [-moons]

Flexible warp cell calculator taking into account the current construct's mass and location.

At least one of *-from* and *-to* parameters must be specified, the other will then be determined from the construct (closest planet). Both accept either a planet's name, a ::pos{...} string or the keyword planets itself.

The latter actually generates a whole list of cell costs for all planets in the Atlas, not just the current one.

If the *-moons* parameter is present, it will also include all moons.

Mass is obviously a key factor in the calculation. By default it would use the current construct's total mass for it.
But with e.g. "**-mass 1234**" added, the script will use 1234 tons instead.

Example 1: `/warpCost -from Madis -to Alioth -mass 534`

Example 2: `/warpCost -from Alioth -to planets -moons`

Example 3: `/warpCost -from Madis -to planets -mass 534 -cargo 234`

Output in LUA chat will give a list of roundtrips: first trip with cargo and the return trip "empty" (no cargo).

```LUA
Executing /warpCost with: -from Madis -to planets -mass 534 -cargo 234
~~~ WARP CELL CALCULATOR ~~~
Current planet: Alioth
Mass: 534.0 tons  ~*~  Cargo: 234.0 tons
Alioth (141.37 SU) = 18 cells / 10 cells = 28 total
Thades (82.15 SU) = 10 cells / 5 cells = 15 total
Talemai (224.72 SU) = 28 cells / 16 cells = 44 total
Sicari (314.51 SU) = 40 cells / 22 cells = 62 total
Sinnen (313.3 SU) = 40 cells / 22 cells = 62 total
Teoma (354.06 SU) = 45 cells / 25 cells = 70 total
Jago (559.42 SU) -> too far!
```

Optional '*-from x*' with x being either 'here', a planet name, ::pos{} or 'planets' (multi-result).

Optional '-to x' like -from, but for end location.

Optional '-mass x' with x the total mass in tons. If not given, the current constructs' total mass is used.

Optional '-cargo x' with x the cargo mass in tons. If specified, a cell count for a return trip is calculated, too.

## YFS only

### **DISCLAIMER, DISCLAIMER, DISCLAIMER!**

**Do not run any command that adds/alters routes and/or waypoints whilst YFS is running to prevent any clashes between databank operations!**

**If it is done still and altered waypoints are part of any route(s), YFS should be restarted to read the updated values (as named waypoints are stored separately from routes)!**

### **/yfs-build-route-from-wp**

Powerful route-building command based on existing, named "landed" waypoints.

The idea for this command came from trying to quick-start a route for a new mining spot consisting of multiple mining sites (tiles/hexes) and the desire to use the least amount of commands/work to get a *Bug* (one of SVEA's available small VTOL ships with YFS) set up with a convenient route. There's still some work involved, but it's made easier!

#### Foreword about named waypoints

From experience, using *named waypoints* eases working with routes a lot, every time, hands down.

The names should be short, but unique, i.e. numbered, like "Chr 1", "Chr 2" etc. in the upcoming example below. Later on, within YFS' route editor they're then instantly recognisable. Since they're saved separately from routes, they're also usable across multiple routes. If you update a named waypoint, it becomes updated for any route it is part of.

The use in multiple routes can be helpful like having one route just for the mining locations ('*going in circles*') and a separate route just to go from the starting (or ending) route point to/from a central hub location (ore collection for pickups), that allows to visit all spots with maximum link container range.

The alternative would be to use YFS' user interface itself (go to Edit, select route, Edit) and then click the "**Add Current**" option at each location.
The same option exists for both the left-hand named waypoints list as well as the route editor itself on the right, but with stark differences.

The first one would auto-name the waypoint starting with "WP" and enumerate it, so it can be reused and is easier to recognise - as long as there's only 1 route 'cause then the numbering could become weird.
The option below the route points would *just* do that: add a location to the route at the end of the list with some specific distance as its name. Not very recognisable, tbh.

That way *works*, but any further editing of the route becomes laborious.

One cannot just replace/update a route point with any default command, but would need to add another waypoint, move it to the right index and then remove the old one. And did we mention that the name "312.2m" doesn't ring a bell? ;)

In comparison, any named waypoint can easily be replaced by a single command (see below YFS commands) by just using the same name again. Whenever YFS starts flying on a route, it will use that updated position of that waypoint.

And of course, should the construct be used across multiple mining spots with e.g. different ores or purposes, the user chosen name should be instantly recognisable instead of "WP012" or "WP003" and figuring out, where they "belong" to.

#### How do we get things started?

First, outside of this script, it is helpful to use the ingame Map, zoom in to the max on your mining area and click the checkbox to show all Constructs (can also first filter by name if that helps). Take a screenshot of the whole area so that all locations are included and then possibly add text marks to each, like an enumeration, from starting to ending location.

Basically, visualize your route upfront.

*Personal recommendation: try [**Greenshot**](https://getgreenshot.org/) (donation ware, no feature/runtime limitations), which allows easy screengrabs and has an editor to apply text marks as well as arrows etc.*

Now, go visit each location in order of how the route is imagined to be travelled along later on. Out of habit, going clockwise starting at the North-most location on the Map is one way to go.

At every spot, usually a dual- or tri-hex corner, pick a good, flat-ish landing location and use the following YFS command in LUA chat (adapt name accordingly)

**`/pos-save-current-as 'Chr 1'`**

to have it create a new, uniquely-named waypoint 'Chr 1'.

Alternatively, the below command could be used if an actual `::pos{}` was known:

**`/pos-save-as -name 'Chr 2' -pos '::pos{0,0,x,y,z}'`**

However, beware of the specified altitude in that ::pos{} may be bad luck if it was just taken from the ingame Map, which defaults to 0m (planet's sea level).

Using the first command makes sure to pick the altitude relative to the construct's build box and correctly measures a landing position.
Even an altitude taken manually via the "My location" on the Map might be lower than the construct's altitude value, thus causing YFS trying to move "into the ground" (down) more than physically possible - every centimeter counts (margins can help)! ;)

For demonstration purposes, our route here is specifically about Chromite ore, thus the short prefix "Chr ".

Once all the locations are saved as waypoints in YFS, the below example command can be used to create a named route with a selection of waypoints:

**`/yfs-build-route-from-wp -name 'Chromite' -altitude 450 -wpStartsWith 'Chr' -suffix 'F'`**

This command uses all existing waypoints, whose names start with "*Chr*", as landing locations and for each one adds an "at **F**light" waypoint directly above them at the specified altitude of 450 meters. We chose the "F" as a suffix in the name for "flight" as a personal preference. It can be different, but should be short due to limited YFS screen space in the route editor. As a result, for our waypoint "**Chr 1**" a new waypoint "**Chr 1F**" would be added and so on.

Since *there can be only one* altitude with this command, be careful to measure one that is safe to traverse between all waypoints: better to add a safety margin of 20m than being salty and dead inside the next hill along the way. ;)

The end result is a new route with all the above waypoints. If the route name is already taken, the script will show an error and not proceed!

#### How does it fly?

With our route, YFS starts at "Chr 1", landed on the ground.
It then ascends up above it to 450m to reach "Chr 1F", turns and flies toward "Chr 2F" still at 450 meters and there finally descends vertically down to "Chr 2" and is landed again.

This way of "*landed waypoint -> takeoff vertically to "F" -> fly over to next waypoint's F -> land again*" is then common between all waypoints.

Within the route all the "at flight" waypoints will be marked as "not selectable" and "not skippable", so only "Chr 1", "Chr 2" etc. are shown on the "Waypoints" list on screen (outside of the route editor) by YFS.

*Disclaimer:* due to the common altitude setting for all "at flight" waypoints, this works best *out of the box* for either flatlands or areas with little to no difference in maximum terrain elevation between all sites.

If in doubt about flight altitudes across waypoints, don't panic, help is here with the below altitude-related commands! :)

#### **/yfs-add-altitude-wp**

Adds waypoints for each existing WP at a specified altitude and name suffix.

This was the predecessor command to the above /yfs-build-route-from-wp command and a simple but not very luxurious way to add extra waypoints for flight altitudes. If not specified, the suffix will be defaulted to 'F'.

Use this with caution as it will iterate over all named waypoints!

Example: `/yfs-add-altitude-wp -altitude 450 -suffix 'F'`

#### **/wp-altitude-ceiling**

Determines the higher altitude of 2 *named* waypoints, then updates the lower-altitude waypoint with that value.

If 'Base 1F' is at 305m and 'Base 2F' at 354m altitude, the command will raise the altitude for 'Base 1F' to 354m as that is the ceiling of both.

Example: `/wp-altitude-ceiling 'Base 1F' 'Base 2F'`

#### **/yfs-options-reset**

Resets specific options for a range of waypoints of a given route.

This sets finalSpeed to 30km/h, maxSpeed to 0 (unlimited), margin to 0.01m.
Additionally it will remove the (currently) inaccessible option for alignment ('lockDir'), which would originate from the "Add + facing" option on the YFS route editor screen.

The options for selectable and skippable are unchanged.

If the -endIx parameter is left out, all waypoints starting from position -ix to the end will be processed. -ix and -endIx can have the same value to allow to change a single route point.

Example: `/yfs-options-reset -route 'name' -ix 2 -endIx 3`

#### **/yfs-replace-wp**

Replaces a named waypoint with the current position of the construct. If no name is specified or no waypoint with the provided name can be found, an error message will be displaye.

Example: `/yfs-replace-wp 'Chr 1'`

#### **/yfs-route-altitude** -route 'name' -ix 2 -endIx 3 -alt 330

Changes altitude for a range of waypoints (from ix to endIx) of a specific YFS route (identified by 'name') to a specified altitude "-alt" in meters.

#### **/yfs-route-nearest**

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

#### **/yfs-route-to-named**

Converts a route's *unnamed* waypoints to named waypoints for YFS.

Example: `/yfs-route-to-named 'Route 1'`

|Parameter|Comment|
|---------------------|----|
|*-onlySelectable*    | Only write waypoints marked as selectable in route|
|*-prefix 'Myprefix'* | if unspecified, 'WP' is the default|
|*-toScreen*          | output JSON of list to optional screen if linked|
|*-toDB*              | only if this is given, the changed list will be written to DB to avoid miscalls|

#### **/yfs-save-named**

Creates a list of YFS commands to recreate *all* named waypoints the script loaded.

If a screen is linked, the output will be display there as well to make it easier to copy the content to e.g. a text editor for safekeeping.

*Sample output (shortened to 3 entries):*

```lua
Executing /yfs-save-named
pos-save-as 'Peta 1' -pos ::pos{0, 8, 58.4133, 20.6821, 543.3269}
pos-save-as 'Peta 10' -pos ::pos{0, 8, 57.4760, 24.8180, 637.0505}
pos-save-as 'Peta 13' -pos ::pos{0, 8, 57.1549, 23.4400, 515.3481}
```

#### **/yfs-save-route**

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

#### **/yfs-wp-altitude**

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
