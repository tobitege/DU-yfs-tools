-- require used classes and instantiate important ones
SU = require('SU') -- string utils
Out = require('out') -- output utils
P = Out.PrintLines
E = Out.Error

require('Dtbk') -- databank

require('libutils') -- helper functions
Cmd = require('commands') -- all YFS Tools commands
Help = require('help') -- help utils

require('warpcost') -- warp calculator function

require('wpoint') -- waypoint class
WM = require('wpointmgr').new("MAIN") -- instantiate MAIN waypoint manager

WaypointInfo = require('atlas')

require('wolfeCentralpoint') -- determine central point among array of waypoints
-- if not INGAME then
--     WolfeCenterPointRS = library.embedFile("../util/wolfeCentralPointScreen.lua")
-- end

WolfAR = nil -- customized Wolf Labs' AR waypointing