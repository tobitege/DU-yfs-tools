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

WP_EG_ENABLED = false -- Waypointer by EasternGamer
WP_WOLF_ENABLED = false -- Waypointer AR by Wolfe Labs

CNID = construct.getId()