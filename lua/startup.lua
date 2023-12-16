local uclamp = utils.clamp

local onlyForRoute = "" --export: Load waypoints only for this route (enclosed in double quotes!); default "".
local onlySelectableWP = true --export: Check to only display custom route waypoints that are marked as selectable
local loadWaypoints = true --export: Enable to load custom waypoints from databank
local outputFont = "FiraMono" --export: Name of font used for screen output. Default: "FiraMono"
local centerMaxDistance = 5000 --export: The furthest a point should be displayed on-screen in meters (1000..10000; default: 5000)
local centerHelperCirclesEvery = 1000 --export: Show grid circles every X meters (100..2000; default: 1000)

onlyForRoute = onlyForRoute or ""
OutputFont = outputFont or "FiraMono" -- used in libutils.lua

-- for new centerpoint mod
CenterMaxDistance = centerMaxDistance or 5000
CenterMaxDistance = uclamp(centerMaxDistance, 1000, 10000)
CenterHelperCirclesEvery = centerHelperCirclesEvery or 1000
CenterHelperCirclesEvery = uclamp(centerHelperCirclesEvery, 100, 2000)

P("=========================================")
P("YFS-Tools 1.7.1 (unofficial)")
P("created by tobitege (c) 2023")
P("Thanks to Yoarii (SVEA) for YFS and LUA help!")
P("YFS 1.4+ databank link required (Routes).")
P("=========================================")
P("* WARNING: do not run commands that change")
P("* waypoints/routes while YFS is running!")
P("=========================================")
P("LUA parameter(s):")
P("Load waypoints from databank: " .. BoolStr(loadWaypoints))
P("Only waypoints for route: " .. onlyForRoute)
P("Only selectable waypoints: " .. BoolStr(onlySelectableWP))
P("Screen output font name: " .. OutputFont)
P("=========================================")

local status, err = false, nil
if INGAME then
    status, err, _ = xpcall(function()
        Config.core = library.getCoreUnit()
        Config.databanks = library.getLinksByClass('DataBank', true) -- true is important!
        Config.screens = library.getLinksByClass('Screen', true)
    end, Traceback)
    if not status then
        P("Error in Link Detection:\n" .. err)
        unit.exit()
        return
    end
else
    -- this requires du-mocks!
    Config.core = unit.core
    Config.databanks =  { unit.databank }
    Config.screens =  { unit.screen }
end

if Config.core == nil then
    P("[E] No Core connected! Ending script.")
    unit.exit()
    return
end

PM = require('pos').New(Config.core, construct, WM) -- Positions and waypoint management

if #Config.databanks > 0 then
    local plural = ""
    if #Config.databanks > 1 then plural = "s" else plural = " '"..Config.databanks[1].getName().."'" end
    P(#Config.databanks .. " databank" .. plural .. " connected.")
else
    P("[E] DataBank not found.")
end

if #Config.screens > 0 then
    local plural = ""
    if #Config.screens > 1 then plural = "s" end
    P(#Config.screens .. " screen" .. plural .. " connected.")
end

-- optionally load waypoints from databank (ArchHUD or YFS)
if loadWaypoints ~= true or #Config.databanks == 0 then
    P("[I] Waypoints loading is off.")
    return
end

-- for local debugging, see mockaround file for demo data!
if not INGAME then
    onlyForRoute = "Garni"
end

local prevCount = 0
for ix=1, #Config.databanks, 1 do
    ---@diagnostic disable-next-line: assign-type-mismatch
    local db = Config.databanks[ix] ---@type table DataBank
    P("===== Checking db '"..db.getName().."' =====")
    if db.hasKey(ARCH_SAVED_LOCATIONS) then
        P('ArchHud databank detected.')
        DetectedArch = ix
        local names = db.getStringValue(ARCH_SAVED_LOCATIONS)
        if names ~= "" then
            P('Searching stored locations...')
            local locations = json.decode(names)
            if IsTable(locations) then
                Cmd.GetStoredLocations(locations)
            end
        end
    end
    if db.hasKey(YFS_ROUTES) or db.hasKey(YFS_NAMED_POINTS) then
        P('YFS databank detected.')
        YFSDB = Dtbk.new(db)
        DetectedYFS = true
        if not onlySelectableWP then
            Cmd.YFSLoadNamedWaypoints()
        end
        Cmd.YFSLoadRoutepoints(onlySelectableWP, onlyForRoute)
    end
    local count = PM.GetWaypointCount()
    if count == prevCount then
        P("[I] No waypoints loaded from db "..ix)
    else
        P("[I] "..(count - prevCount).." waypoints loaded from db "..ix)
    end
    prevCount = PM.GetWaypointCount()
end
P("=======================")
if PM.GetWaypointCount() > 0 then
    P("[I] Total "..PM.GetWaypointCount().." waypoints loaded.")
else
    P("[I] No waypoints loaded.")
end
P("=======================")