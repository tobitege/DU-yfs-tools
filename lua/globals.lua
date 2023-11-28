-- Initialize globals and constants
Config = { core = nil, databanks = {}, screens = {} }
DetectedArch = 0
DetectedYFS = false
YFSDB = nil
YFS_NAMED_POINTS = "NamedPoints"
YFS_ROUTES = "NamedRoutes"
ARCH_SAVED_LOCATIONS = "SavedLocations"
DEBUG = false
Clicked = false -- for waypointer
WAYPOINTER_ENABLED = false

INGAME = system ~= nil

if not INGAME then
---@if DEBUG true
    require("mocks")
---@end
else
    print = system.print
end

WaypointInfo = require('atlas')