---@diagnostic disable: undefined-field
local onlyForRoute = "" --export: Load waypoints only for this route (enclosed in double quotes!)
local onlySelectableWP = true --export: Check to only display custom route waypoints that are marked as selectable
local loadWaypoints = true --export: Enable to load custom waypoints from databank
local outputFont = "FiraMono" --export: Name of font used for screen output. Default: "FiraMono"

onlyForRoute = onlyForRoute or ""
OutputFont = outputFont or "FiraMono"

P("=========================================")
P("YFS-Tools 1.5.1 (unofficial)")
P("created by tobitege (c) 2023")
P("Thanks to Yoarii (SVEA) for YFS and LUA help!")
P("YFS 1.4+ databank link required (Routes).")
P("=========================================")
P("* WARNING: do not run commands that change")
P("* waypoints/routes while YFS runs!")
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
    -- this requires du-mocks
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

-- for local debugging, see mockaround file for demo data!
if not INGAME then
    onlyForRoute = "Hema"
end

-- load waypoints from databank(s) (ArchHUD or YFS)?
if loadWaypoints ~= true then
    P("[I] Waypoints loading is off.")
elseif #Config.databanks > 0 then
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
end