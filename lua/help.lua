local help = {}

function help.PrintHelpCmd()
    local hlp = "~~~~~~~~~~~~~~~~~~~~\nYFS-Tools Commands:\n~~~~~~~~~~~~~~~~~~~~\n"..
    "/arch-save-named\n-> Builds list of chat commands for ArchHud to add locations for all named waypoints.\n"..
    "/planetInfo (id or name)\n-> Info about current planet or for passed planet id or name, e.g. 2 for Alioth).\n"..
    "/printAltitude /printPos /printWorldPos\n-> Prints info data.\n"..
    "/warpCost -from name/::pos{}/planets -to name/::pos{}/planets -mass tons -moons\n-> Flexible warp cell calculator.\n"..
    "/wp-altitude-ceiling\n-> Changes a waypoint to have the higher altitude of both.\n"..
    "/wp-export\n-> Outputs list of plain waypoints to chat and an optional screen. Source can include ArchHud locations, too, if databank linked.\n"..
    "/yfs-add-altitude-wp\n-> Adds waypoints for each existing WP at a specified altitude and name suffix.\n"..
    "/yfs-build-route-from-wp\n-> Powerful route-building command based on existing named waypoints.\n"..
    "/yfs-route-altitude\n-> Changes altitude for a range of waypoints of a specific YFS route.\n"..
    "/yfs-route-nearest\n-> Show list of route waypoints by distance from current location.\n"..
    "/yfs-route-to-named\n-> Converts a route's *unnamed* waypoints to named waypoints for YFS.\n"..
    "/yfs-save-named\n-> Builds list of YFS commands to recreate all named waypoints.\n"..
    "/yfs-save-route\n-> Builds list of YFS commands to recreate full route incl. named waypoints and their options.\n"..
    "/yfs-wp-altitude\n-> Changes altitude of a named waypoint to specified altitude.\n"..
    "----------------------------------\n"..
    "Important: Enclose names (as parameters) in single quotes if they contain blanks!\n"..
    "*** DO NOT USE COMMANDS THAT CHANGE POINTS ***\n*** OR ROUTES WHILE YFS IS RUNNING! ***\n"
    ScreenOutput(hlp)
    P(hlp)
end

return help