---@diagnostic disable: lowercase-global
-- Initialize globals and constants
Config = { core = nil, databanks = {}, screens = {} }
DetectedArch = 0
DetectedYFS = false
YFSDB = nil
YFS_NAMED_POINTS = "NamedPoints"
YFS_ROUTES = "NamedRoutes"
ARCH_SAVED_LOCATIONS = "SavedLocations"
DEBUG = false
WAYPOINTER_ENABLED = true
ScriptStartTime = 0
INGAME = system ~= nil

if not INGAME then
---@if Willi "Wonka"
    require("mocks")
---@end
else
    ScriptStartTime = system.getArkTime()
    print = system.print
end

projector = nil
clicked = false -- for waypointer

WaypointInfo = require('atlas')

CNID = construct.getId()