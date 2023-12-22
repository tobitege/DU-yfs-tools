--TODO: refactor commands to use WM instead of databank data
local cmd = {}

-- requires libutils, globals PM, SU, YFSDB etc.
-- WaypointInfo only used for WarpCostCmd()

local strmatch, sformat, strlen = string.match, string.format, string.len
local tonum, uclamp, mabs, max, floor, ceil = tonumber, utils.clamp, math.abs, math.max, math.floor, math.ceil

-- Local functions

---@comment Adds for each existing waypoint listed in "wpnames" an extra "Flight" waypoint
--- at the given altitude with the given name suffix.
--- Already existing waypoints with the suffix'ed name will have their altitude changed!
--- Returns a list of "connected" waypoints, e.g.
--- 1 landed -> 1 flight -> 2 flight -> 2 landed -> 2 flight -> 3 flight -> 3 landed  etc.
--- as 2nd result; 1st result is the updated full waypoints list.
---@param wpdata table
---@param wpnames table
---@param altitude number
---@param suffix string
local function yfsAddAltitudeWaypoints(wpdata, wpnames, altitude, suffix)
    local cnt = 0
    local names = {}
    local wpCnt = #wpnames
    for _,k in ipairs(wpnames) do
        local wp = wpdata.v[k]
        if wp ~= nil then
            cnt = cnt + 1
            local wpN = k .. suffix
            if cnt > 1 then table.insert(names, wpN) end
            table.insert(names, k)
            if cnt < wpCnt then table.insert(names, wpN) end
            local newPos = PM.ReplaceAltitudeInPos(wp.pos, altitude)
            if wpdata.v[wpN] ~= nil then
                wpdata.v[wpN].pos = newPos
            else
                wpdata.v[wpN] = { pos = newPos }
                P(wpN .."  " .. newPos)
            end
        end
    end
    if cnt == 0 then
        P("[E] No waypoints processed!")
        return nil,nil
    end
    P("[I] "..cnt.." waypoints at "..altitude.."m added (or changed)!")
    return wpdata, names
end

local function storeYFSData(keyName, data)
    if not DetectedYFS or not keyName then return false end
    YFSDB:setData(keyName, data)
    return true
end

local function getYFSData(keyName)
    if not DetectedYFS or not keyName then return false end
    local data = YFSDB:getData(keyName)
    if data == nil or not IsTable(data.v) then
        return false
    end
    return data
end

local function storeYFSNamedWaypoints(data)
    storeYFSData(YFS_NAMED_POINTS, data)
end

local function storeYFSRoutes(data)
    storeYFSData(YFS_ROUTES, data)
end

-- Class functions

---@comment with WM: output name and position for all waypoints
function cmd.FindCenterCmd(text)
    if not WM or not WM:hasPoints() then
        return E("[E] No waypoints to export.")
    end
    local routes = cmd.GetYFSRoutes()
    if not routes then return end

    local parts = SU.SplitQuoted(text)
    if #parts < 1 then
        return E("[E] Parameter(s) missing: routename\nExample: /findCenter 'Cryo' -onlySelectable")
    end
    local onlySelectable = GetIndex(parts, "-onlySelectable") > 0
    local routename = parts[1]
    local route = routes.v[routename]
    if not route or not IsTable(route.points) or #route.points == 0 then
        return E("[E] Route '"..routename.."' not found or empty")
    end

    local wpdata = cmd.GetYFSNamedWaypoints()

    -- iterate route points and add to calculator
    local pointlist = {}
    local wpIdx = 1
    for _,v in ipairs(route.points) do
        local wppos = ""
        local wpName = "WP "..sformat("%03d", wpIdx)
        if v.waypointRef and wpdata then
            wpName = v.waypointRef
            wppos = wpdata.v[wpName].pos
        else
            wppos = v.pos
        end

        if wppos and ((not onlySelectable) or (v.opt["selectable"] ~= false)) then
            P("Using "..wpName)
            pointlist[wpIdx] = PM.MapPosToWorldVec3(wppos)
        end
        wpIdx = wpIdx + 1
    end
    local center = GetCentralPoint(pointlist)
    if center then
        local locPos = PM.WorldToMapPos(center)
        local output = "[I] Center coords: "..PM.MapPos2String(locPos)
        P(output)
    else
        P("[E] Could not calculate center, sorry!")
    end
end

function cmd.GetYFSNamedWaypoints(muteMsg)
    if not DetectedYFS then
        return E("[E] Linked YFS databank required!")
    end
    local namedWP = getYFSData(YFS_NAMED_POINTS)
    if not namedWP and not muteMsg then
        P("[I] No named waypoints")
    end
    return namedWP
end

function cmd.GetYFSRoutes()
    if not DetectedYFS then
        return E("[E] Linked YFS databank required!")
    end
    local data = getYFSData(YFS_ROUTES)
    if not data then
        return E('[I] No YFS routes found.')
    end
    return data
end

function cmd.PlanetInfoCmd(text)
    PM.PlanetInfo(text)
end

function cmd.PrintAltitudeCmd(text)
    P(Out.PrettyDistance(PM.Altitude()))
end

function cmd.PrintPosCmd(text)
    P(PM.GetCurrentPosString())
end

function cmd.PrintWorldPosCmd(text)
    P(PM.Vec3ToPosString(PM.WorldPosVec3()))
end

function cmd.WarpCostCmd(text)
    CalcWarpCost(text)
end

---@comment with WM: create commands to recreate waypoints in either YFS or ArchHud format
function cmd.WpSaveNamedCmd(text, isYfs)
    if not WM or not WM:hasPoints() then
        return E("[E] No waypoints to export.")
    end
    local output = ""
    for _,wp in ipairs(WM:getSorted()) do
        local pos = wp:AsString()
        if isYfs then
            pos = "pos-save-as '" .. wp:getName() .. "' -pos " .. pos
        else
            pos = "/addlocation " .. wp:getName() .. " " .. pos
        end
        output = output .. pos .. "\n"
        P(pos)
    end
    ScreenOutput(output)
end

function cmd.ArchSaveNamedCmd(text)
    cmd.WpSaveNamedCmd(text, false)
end

---@comment with WM: output name and position for all waypoints
function cmd.WpExportCmd(text)
    if not WM or not WM:hasPoints() then
        return E("[E] No waypoints to export.")
    end
    local output = ""
    local wplist = WM:getSorted()
    for _,wp in ipairs(wplist) do
        local s = wp:getName() .. "\n" .. wp:AsString() .. "\n"
        output = output .. s
    end
    P(output)
    ScreenOutput(output)
end

function cmd.WpAltitudeCeilingCmd(text)
    local wpnames = cmd.GetYFSNamedWaypoints()
    if not wpnames then return end

    -- 0 parse params to find a) name and b) new altitude value
    local parts = SU.SplitQuoted(text)
    if #parts ~= 2 then
        P("[E] Parameter(s) missing: 'name 1' 'name 2'")
        return E("Example: /wp-altitude-ceiling 'Base 1' 'Base 2'")
    end
    local wpName1 = parts[1]
    local wpName2 = parts[2]

    -- 1 find the 2 named waypoints per params
    local wp1found, wp2found = true, true
    if wpnames.v[wpName1] == nil or wpnames.v[wpName1] == "" then
        P("[E] Waypoint '".. wpName1 .."' not found.")
        wp1found = false
    end
    if wpnames.v[wpName2] == nil or wpnames.v[wpName2] == "" then
        P("[E] Waypoint '".. wpName2 .."' not found.")
        wp2found = false
    end
    if not wp1found or not wp2found then return end
    if wpnames.v[wpName1] == wpnames.v[wpName2] then
        return E("[E] Parameters invalid (same names).")
    end

    -- 3 get waypoint's altitudes and update the lower one
    local alt1 = PM.GetAltitudeFromPos(wpnames.v[wpName1].pos)
    local alt2 = PM.GetAltitudeFromPos(wpnames.v[wpName2].pos)
    if alt1 == alt2 then
        P("[I] Waypoints had same altitude, no changes applied.")
        return
    end
    local target, targetAlt = "", 0
    if alt1 > alt2 then
        target = wpName2
        targetAlt = alt1
    else
        target = wpName1
        targetAlt = alt2
    end
    local newPos = PM.ReplaceAltitudeInPos(wpnames.v[target].pos, targetAlt)
    wpnames.v[target].pos = newPos
    P("[I] Waypoint '"..target.."' changed to:")
    P(newPos)

    -- 4 json.encode data and write back to DB
    storeYFSNamedWaypoints(wpnames)
    return true
end

function cmd.GetStoredLocations(points) -- for ArchHud only
    if not points or not IsTable(points) then return end
    for _,p in ipairs(points) do
        if p.name and p.position and p.position.x and p.position.y and p.position.z then
            P("[I] Location '".. p.name .."' found.")
            local pos = '::pos{0,0,'.. p.position.x .. ',' .. p.position.y .. ',' .. p.position.z ..'}'
            PM.CreateWaypoint(pos, p.name)
        end
    end
end

function cmd.YfsAddAltitudeWpCmd(text)
    local wpdata = cmd.GetYFSNamedWaypoints()
    if not wpdata or not IsTable(wpdata.v) or TableLen(wpdata.v) == 0 then
        return E("[E] No waypoints.")
    end

    local example = "\nExample: /yfs-add-altitude-wp -altitude 450 -suffix 'F'"
    local args = SU.SplitQuoted(text)
    local pStart = GetParamValue(args, "-wpStartsWith", "s")
    if #args < 1 then
        return E("[E] Parameter missing: -altitude"..example)
    end
    local pAlt = GetParamValue(args, "-altitude", "n", true)
    local pSuf = GetParamValue(args, "-suffix", "s")
    if not pSuf or pSuf == "" then pSuf = "F" end
    if pAlt < -100 or pAlt > 20000 then
        return E("[E] -altitude value out of range (-100 .. 20000)"..example)
    end

    -- need a sorted list of names, can't use wpdata as that is being modified
    local wplist = {}
    for k in PairsByKeys(wpdata.v) do
        if not pStart or k:find(pStart) > 0 then
            table.insert(wplist, k)
        end
    end
    local newData, names = yfsAddAltitudeWaypoints(wpdata, wplist, pAlt, pSuf)
    if newData ~= nil and names ~= nil then
        storeYFSNamedWaypoints(newData)
    end
    return true
end

function cmd.YfsBuildRouteFromWpCmd(text)
    local wpdata = cmd.GetYFSNamedWaypoints()
    if not wpdata or not IsTable(wpdata.v) or TableLen(wpdata.v) == 0 then
        return E("[E] No waypoints.")
    end

    local rdata = cmd.GetYFSRoutes()
    if not rdata or not IsTable(rdata.v) or TableLen(rdata.v) == 0 then
        -- Initializing routes
        rdata = { v = {}, t = "table" }
    else
    end

    local example = "\nExample: /yfs-build-route-from-wp -name 'Route' -altitude 450 -wpStartsWith 'Chr' -suffix 'F'\n-suffix is optional, default F (Flight)"
    local args = SU.SplitQuoted(text)
    if #args < 1 then
        return E("[E] Parameters missing!"..example)
    end

    local pName  = GetParamValue(args, "-name", "s", true)
    if not pName then return end
    local pStart = GetParamValue(args, "-wpStartsWith", "s")
    local pAlt   = GetParamValue(args, "-altitude", "n", true)
    if not pAlt then return end
    local pSuf   = GetParamValue(args, "-prefix", "s")
    local pMarginL = GetParamValue(args, "-marginL", "n")
    local pMarginF = GetParamValue(args, "-marginF", "n")
    local pMaxSpeed = GetParamValue(args, "-maxSpeed", "n")
    local pFinalSpeedF = GetParamValue(args, "-finalSpeedF", "n")
    -- some sanity checks, review later
    pMarginL = uclamp(pMarginL or 0.1, 0.1, 100) -- landed position margin
    pMarginF = uclamp(pMarginF or 0.1, 0.1, 100) -- flight position margin
    pMaxSpeed = uclamp(pMaxSpeed or 0, 0, 1200) -- max speed at flight
    pFinalSpeedF = uclamp(pFinalSpeedF or 0, 0, 1200) -- speed reaching the wp
    if rdata.v[pName] ~= nil then
        return E("[E] Route "..pName.."already exists, aborting!")
    end
    if type(pSuf) ~= "string" or pSuf == "" then pSuf = "F" end
    if strlen(pSuf) > 3 then
        return E("[E] -suffix accepts max. 3 characters"..example)
    end
    if pAlt < -600 or pAlt > 20000 then
        return E("[E] -altitude value out of range (-100 .. 20000)"..example)
    end

    -- need a sorted list of names, can't use wpdata as that is being modified *live*
    -- names could be filtered by pStart
    local wplist = {}
    for k in PairsByKeys(wpdata.v) do
        if not pStart or k:find(pStart) > 0 then
            table.insert(wplist, k)
        end
    end

    -- lets add new "flight" waypoints and get updated tables back
    local wpdata, wplistNew = yfsAddAltitudeWaypoints(wpdata, wplist, pAlt, pSuf)
    if wpdata == nil or wplistNew == nil then
        return E("[I] No waypoints processed: no changes made.")
    end

    -- add new route
    rdata.v[pName] = { points = {} }

    -- assume that wplistNew now contains all required wp names in order
    -- so these can be added to the route
    local cnt = 0
    for _,k in ipairs(wplistNew) do
        local wp = wpdata.v[k]
        if wp ~= nil then
            -- add wp to route
            cnt = cnt + 1
            local rOpt = { margin = 0.1, maxSpeed = 0 }
            local rp = { opt = rOpt, pos = wp.pos, waypointRef = k }
            -- for "flight" waypoints:
            if GetIndex(wplist, k) < 1 then
                -- set final approaching speed for landing waypoints if specified
                if pFinalSpeedF and pFinalSpeedF > 0 and GetIndex(wplist, k) < 1 then
                    rp.opt.finalSpeed = pFinalSpeedF
                end
                -- set max speed for flight waypoints if specified
                if pMaxSpeed and pMaxSpeed > 0 then
                    rp.opt.maxSpeed = pMaxSpeed
                end
                -- set margin for flight waypoints if specified
                if pMarginF and pMarginF > 0.1 then
                    rp.opt.margin = pMarginF
                end
                rp.opt.selectable = false
                rp.opt.skippable = false
            else -- for Landed waypoints:
                -- set margin for landed waypoints if specified
                if pMarginL and pMarginL > 0.1 then
                    rp.opt.margin = pMarginL
                end
                rp.opt.selectable = true
                rp.opt.skippable = true
            end
            table.insert(rdata.v[pName].points, rp)
        end
    end
    P("[I] "..cnt.." positions added to route '"..pName.."'")
    storeYFSNamedWaypoints(wpdata)
    storeYFSRoutes(rdata)
end

function cmd.YfsSaveRouteCmd(text)
    local routes = cmd.GetYFSRoutes()
    if not routes then return end

    local parts = SU.SplitQuoted(text)
    if #parts < 1 then
        return E("[E] Parameter(s) missing: routename\nExample: /yfs-save-route 'Cryo' -onlySelectable -withOptions -prefix 'Cryo'")
    end
    local wpPrefix = GetParamValue(parts, "-prefix", "s")
    if not wpPrefix then wpPrefix = "WP" end
    local onlySelectable = GetIndex(parts, "-onlySelectable") > 0
    local withOptions = GetIndex(parts, "-withOptions") > 0
    local routename = parts[1]
    local route = routes.v[routename]
    if not route or not IsTable(route.points) or #route.points == 0 then
        return E("[E] Route '"..routename.."' not found or empty")
    end
    local output1, output2 = "create-route '"..routename.."'\r\n", ""

    local wpdata = cmd.GetYFSNamedWaypoints()

    -- iterate points, build one commands output for wp creation and one for
    -- adding each with options (optionally) to the route
    local wpIdx = 1
    local wpNames = {} -- to avoid duplicates
    for _,v in ipairs(route.points) do
        local wppos = ""
        local wpName = wpPrefix.." "..sformat("%03d", wpIdx)
        if v.waypointRef and wpdata then
            wpName = v.waypointRef
            wppos = wpdata.v[wpName].pos
        else
            wppos = v.pos or "<unknown>"
        end

        if GetIndex(wpNames, wpName) < 0 then
            wpNames[#wpNames + 1] = wpName
            local tmp = "pos-save-as '"..wpName.."' -pos "..wppos
            output1 = output1 .. tmp .. "\n"
        end
        if (not onlySelectable) or (v.opt["selectable"] ~= false) then
            local tmp = "route-add-named-pos '"..wpName.."'"
            if withOptions then
                -- named-waypoint level options
                -- Note: "lockdir" option is presently not transferrable!
                if v.opt["maxSpeed"] and v.opt["maxSpeed"] ~= 0 then
                    tmp = tmp.." -maxspeed "..v.opt["maxSpeed"]
                end
                if v.opt["margin"] and v.opt["margin"] ~= 0.1 then
                    tmp = tmp.." -margin "..v.opt["margin"]
                end
                -- route-level options require a 2nd command
                local routeLvlOptions = false
                local routeOptStr = ""
                if v.opt["skippable"] == true then
                    routeLvlOptions = true
                    routeOptStr = routeOptStr .. " -toggleSkippable"
                end
                if v.opt["selectable"] == false then
                    routeLvlOptions = true
                    routeOptStr = routeOptStr .. " -toggleSelectable"
                end
                if v.opt["finalSpeed"] and v.opt["finalSpeed"] ~= 0 then
                    routeLvlOptions = true
                    routeOptStr = routeOptStr.." -finalSpeed "..v.opt["finalSpeed"]
                end
                if routeLvlOptions then
                    tmp = tmp .. "\nroute-set-pos-option -ix "..wpIdx..routeOptStr
                end
            end
            output2 = output2 .. tmp .. "\n"
            wpIdx = wpIdx + 1
        end
    end
    output2 = output2.."route-save\r\n"
    P(output1..output2)
    ScreenOutput(output1..output2)
end

---@comment Replaces a given YFS waypoint (by -name) with current pos (default) or -pos ::pos{...}
function cmd.YfsReplaceWpCmd(text)
    local wpnames = cmd.GetYFSNamedWaypoints()
    if not wpnames then return end

    local ex = "\r\nExample: /yfs-replace-wp 'base 1'"
    local params = SU.SplitQuoted(text)
    if #params < 1 then
        return E("[E] Parameter(s) missing: -name 'point'"..ex)
    end

    local wpName = GetParamValue(params, "-name", "s", true)
    if not wpName then return end
    if not wpnames.v[wpName] or wpnames.v[wpName] == "" then
        return E("[E] Waypoint '".. wpName .."' not found."..ex)
    end

    local newPos = PM.GetCurrentPosString()
    local pPos = GetParamValue(params, "-pos", "s")
    if pPos then
        ---@diagnostic disable-next-line: cast-local-type
        local tmp = PM.SplitPos(pPos)
        if not tmp then
            return E("[E] Invalid ::pos{} specified!")
        end
        newPos = pPos
    end

    wpnames.v[wpName].pos = newPos
    P("[I] Waypoint '"..wpName.."' changed to:")
    P(newPos)

    storeYFSNamedWaypoints(wpnames)
    return true
end

---@comment Resets waypoint options for a range of waypoints in a specified route
function cmd.YfsOptionsResetCmd(text)
    local routes = cmd.GetYFSRoutes()
    if not routes then return end

    -- 1 check parameters
    local example = "\nExample:\n/yfs-options-reset -route 'name' -ix 2 -endIx 3\nWith -endIx being optional."
    local parts  = SU.SplitQuoted(text)
    local pName  = GetParamValue(parts, "-route", "s", true)
    if not pName then return E(example) end
    if not routes.v[pName] then
        return E("[E] Route '"..pName.."' not found."..example)
    end
    if not routes.v[pName].points or #routes.v[pName].points == 0 then
        return E("[E] Route '"..pName.."' empty.")
    end

    local pStart = GetParamValue(parts, "-ix", "i", true)
    local pEnd   = GetParamValue(parts, "-endIx", "i")
    if not pEnd then pEnd = #routes.v[pName].points end
    local isError = not pName or not pStart or (pStart < 1) or (pEnd and pEnd < pStart)
    if isError then
        return E("[E] Wrong number of parameters / invalid values!"..example)
    end
    if not pEnd or pEnd < pStart then pEnd = pStart end

    -- 2 process route waypoints and collect named waypoint names
    -- /yfs-options-reset -route 'Peta' -ix 2 -endIx 3
    P("[I] Processing route '"..pName.."'")
    local changed = 0
    local finalSpeed = 30 / 3.6 -- 30 km/h -> 8.333 m/s
    for i,v in ipairs(routes.v[pName].points) do
        if i >= pStart and i <= pEnd then
            local wpName = v.waypointRef
            if not wpName then
                wpName = i -- unnamed WP, use index
            end
            changed = changed + 1
            -- only reset specific attributes, so that selectable/skippable stays intact!
            routes.v[pName].points[i].opt.finalSpeed = finalSpeed
            routes.v[pName].points[i].opt.maxSpeed = 0
            routes.v[pName].points[i].opt.margin = 0.1
            routes.v[pName].points[i].opt.lockDir = nil
            P("[I] Options reset for route waypoint: "..wpName)
        end
    end
    if changed == 0 then
        return E("[I] No waypoints in route changed.\n[*] Make sure that start (and end-index) are valid.")
    end
    -- 3 store route back to db
    storeYFSRoutes(routes)
    P("[I] Routes saved.")
end

---@comment Replaces altitude for a range of waypoints in a specified route
function cmd.YfsRouteAltitudeCmd(text)
    local routes = cmd.GetYFSRoutes()
    if not routes then return end

    local namedWP = cmd.GetYFSNamedWaypoints()
    --if not namedWP then return end

    -- 1 check parameters
    local example = "\nExample:\n/yfs-route-altitude -route 'name' -ix 2 -endIx 3 -alt 330\nThe -endIx is optional."
    local parts  = SU.SplitQuoted(text)
    local pName  = GetParamValue(parts, "-route", "s", true)
    if not pName then return end
    if not routes.v[pName] then
        return E("[E] Route '"..pName.."' not found."..example)
    end
    if not routes.v[pName].points or #routes.v[pName].points == 0 then
        return E("[E] Route '"..pName.."' empty.")
    end

    local pStart = GetParamValue(parts, "-ix", "i", true)
    local pEnd   = GetParamValue(parts, "-endIx", "i")
    local pAlt   = GetParamValue(parts, "-alt", "n", true)
    if not pEnd then pEnd = #routes.v[pName].points end

    local isError = not pName or not pStart or not pAlt or (pStart < 1) or (pEnd and pEnd < pStart) or (pAlt < -100) or (pAlt > 10000)
    if isError then
        return E("[E] Wrong number of parameters / invalid values!"..example)
    end
    if not pEnd or pEnd < pStart then pEnd = pStart end

    -- 2 process route waypoints and collect named waypoint names
    -- /yfs-route-altitude -route 'Peta' -ix 2 -endIx 3 -alt 750
    P("[I] Processing route '"..pName.."'")
    local changed = 0
    local wpnames = {}
    for i,v in ipairs(routes.v[pName].points) do
        if i >= pStart and i <= pEnd then
            local newPos = ""
            local wpName = v.waypointRef
            if wpName and namedWP and namedWP.v and namedWP.v[wpName] then
                local wp = namedWP.v[wpName]
                if GetIndex(wpnames, wpName) < 1 then
                    table.insert(wpnames, wpName)
                end
                newPos = PM.ReplaceAltitudeInPos(wp.pos, pAlt)
            else -- unnamed WP
                wpName = i
                newPos = PM.ReplaceAltitudeInPos(v.pos, pAlt)
            end
            changed = changed + 1
            routes.v[pName].points[i].pos = newPos
            P("[I] Route Waypoint '"..wpName.."' changed to:\n"..newPos)
        end
    end
    if changed == 0 then
        return E("[I] No waypoints in route changed.\n[*] Make sure that start (and end-index) are valid.")
    end
    -- 3 store routes back to db
    storeYFSRoutes(routes)
    P("[I] Routes saved.")

    -- 4 process named waypoints list
    changed = 0
    for _,entry in ipairs(wpnames) do
        if namedWP and namedWP.v[entry] then
            changed = changed + 1
            local newPos = PM.ReplaceAltitudeInPos(namedWP.v[entry].pos, pAlt)
            namedWP.v[entry].pos = newPos
            P("[I] Named Waypoint '"..entry.."' changed to:")
            P(newPos)
        else
            P("[E] '"..entry.."' not found!")
        end
    end
    -- 5 write back to DB
    if changed > 0 then
        storeYFSNamedWaypoints(namedWP)
        P("[I] Named waypoints saved.")
    end
end

function cmd.YfsWpAltitudeCmd(text)
    -- 1 read named waypoints from DB
    local wpnames = cmd.GetYFSNamedWaypoints()
    if not wpnames then return E("[E] No named waypoints.") end

    -- 2 parse params to find a) name and b) new altitude value
    local parts = SU.SplitQuoted(text)
    if #parts ~= 2 then
        return E("[E] Wrong number of parameters!\nExample: /yfs-wp-altitude 'Base 1' 324.12")
    end
    local pName = parts[1] or ""

    -- 3 find named waypoint
    if not pName or not parts[2] or not wpnames.v[pName] or wpnames.v[pName] == "" then
         return E("[E] Waypoint '".. pName .."' not found")
    end

    -- 4 alter waypoint's altitude
    local pAlt = tonum(parts[2] or 0)
    local newPos = PM.ReplaceAltitudeInPos(wpnames.v[pName].pos, pAlt)
    wpnames.v[pName].pos = newPos
    P("[I] Waypoint '"..pName.."' changed to:")
    P(newPos)
    P("[I] Note: routes' waypoints are updated on route activation, i.e. exporting route data before activation may still show old value!")

    -- 4 write back to DB
    storeYFSNamedWaypoints(wpnames)
    return true
end

function cmd.YfsRouteNearestCmd(text)
    local routes = cmd.GetYFSRoutes()
    if not routes then return end
    -- 1 process params
    local params = SU.SplitQuoted(text)
    if #params == 0 or #params > 2 then
        P("[E] Wrong parameter count\n[I] Example: /yfs-route-nearest 'Route 1'")
        P("\nOptional parameter:\n")
        P("-onlySelectable -> only show closest, selectable waypoints in route")
        return false
    end
    -- 2 find the route
    local routeName = params[1]
    local route = routes.v[routeName]
    if not route or not IsTable(route.points) then
        return E("[E] Route '" .. routeName .."' not found or empty")
    end
    P("[I] Route '"..routeName.."' found.")
    -- 3 check optional parameters
    local onlySelectable = GetIndex(params, "-onlySelectable") > 0

    -- 4 process route waypoints
    local wplist = cmd.GetYFSNamedWaypoints(true)
    local idx = 0
    local closestDist = 999999999
    local sDist, sNearest = "", ""
    local res =  {}
    for k,v in ipairs(route.points) do
        idx = idx + 1
        if (not onlySelectable) or (v.opt and v.opt.selectable ~= false) then
            local wpname = SU.Trim(sformat("%02d", idx) .. ": '"..(v.waypointRef or "").."'")
            local pos = v.pos
            if v.waypointRef and wplist then
                pos = wplist.v[v.waypointRef].pos
            end
            local dist = PM.GetDistance(pos)
            if dist > 0.1 then
                route.points[k].distance = dist
                sDist = wpname .. " = " .. sformat("%.4f", dist)
                if dist < closestDist then
                    sNearest = sDist
                    closestDist = dist
                end
                local tmpDist = tostring(math.modf(dist * 10000))
                local key = ('0'):rep(12-#tmpDist)..tmpDist
                res[key] = idx
            end
        end
    end
    if not idx then return E("[I] No selectable waypoints found.") end
    local output = "Route-Idx / Name / Distance (m)\n"
    for _,key in pairs(GetSortedAssocKeys(res)) do
        local routeIdx = res[key]
        local wpName = route.points[routeIdx].waypointRef or routeIdx
        local wpDist = route.points[routeIdx].distance
        output = output .. sformat("%02d", routeIdx).." / '"..wpName.."' / "
        output = output .. Out.PrettyDistance(wpDist).."\n"
    end
    output = output .. "\n[I] Nearest waypoint: "..sNearest

    Out.PrintLines(output)
    ScreenOutput(output)
end

function cmd.YfsRouteToNamedCmd(text)
    local routes = cmd.GetYFSRoutes()
    if not routes then return end
    -- 1 process params
    local params = SU.SplitQuoted(text)
    if #params == 0 or #params > 6 then
        P("[E] Wrong parameter count\n[I] Example: /yfs-route-to-named 'Route 1'\nOptional parameters:\n")
        P("-onlySelectable -> only write waypoints marked as selectable in route")
        P("-prefix Myprefix -> if unspecified, 'WP' is default")
        P("-toScreen -> output JSON of list to optional screen if linked")
        P("-toDB -> only if this is given, the changed list will be written to DB to avoid miscalls")
        P("Important: command aborts if ANY waypoint's name starts with given prefix to avoid errors!")
        return false
    end
    -- 2 find the route
    local routeName = params[1]
    local route = routes.v[routeName]
    if not route or not IsTable(route.points) then
        return E("[E] Route '" .. routeName .."' not found or empty")
    end
    P("[I] Route '"..routeName.."' found.")
    -- 3 check optional parameters
    local toDB = GetIndex(params, "-toDB") > 0
    local toScreen = GetIndex(params, "-toScreen") > 0
    local onlySelectable = GetIndex(params, "-onlySelectable") > 0
    local wpPrefix = GetParamValue(params, "-prefix", "s")
    if not wpPrefix then wpPrefix = "WP" end

    -- 4 process route waypoints
    local wplist = cmd.GetYFSNamedWaypoints(true)
    if not wplist or not wplist.v then
        wplist = { v = { } }
    else
        -- if any WP with same prefix already exists, abort!
        for k,_ in pairs(wplist.v) do
            if string.find(k, wpPrefix) == 1 then
                return E("[!] Waypoints with same prefix already exist!\n[!] Command aborted.")
            end
        end
    end
    local idx = 0
    for _,v in ipairs(route.points) do
        if (not onlySelectable) or (v.opt and v.opt.selectable ~= false) then
            idx = idx + 1
            local wpname = wpPrefix .. " " .. sformat("%02d", idx)
            local wp = { pos = v.pos, opt = v.opt}
            --if margin then wp.opt.margin = margin end
            wplist.v[wpname] = wp
            P(wpname .."  " .. v.pos)
        end
    end
    if not idx then return E("[I] No changes to waypoints done") end

    -- 5 write waypoints back to DB, if at least 1 point was added
    if toDB then
        storeYFSNamedWaypoints(wplist)
        P("[I] Waypoint changes saved to databank!")
    else
        P("[I] -toDB not present, no changes saved to databank!")
    end
    if toScreen then
        ScreenOutput(json.encode(wplist.v))
    end
end

function cmd.YFSLoadNamedWaypoints()
    local wpnames = cmd.GetYFSNamedWaypoints()
    if not wpnames then return end
    for k,v in pairs(wpnames.v) do
        PM.CreateWaypoint(v.pos, k)
    end
end

function cmd.YFSLoadRoutepoints(onlySelectableWP, onlyWpForRoute)
    local routes = cmd.GetYFSRoutes()
    if not routes then return false end
    P('[I] Processing routes...')
    for k,v in pairs(routes.v) do
        if (onlyWpForRoute == "" or onlyWpForRoute == k) and IsTable(v) then
            for k2,v2 in ipairs(v.points) do
                if (not onlySelectableWP) or (v2.opt["selectable"] ~= false) then
                    local wpName = k .. " " .. k2
                    if v2.waypointRef then
                        wpName = v2.waypointRef
                    end
                    PM.CreateWaypoint(v2["pos"], wpName)
                end
            end
            P("[I] Route '"..k.."' read.")
        end
    end
    return true
end

function cmd.YfsSaveNamedCmd(text)
    cmd.WpSaveNamedCmd(text, true)
end

function cmd.PosDataCmd()
    --P("GetCameraCmd() called")
    P("getCameraHorizontalFov: "..system.getCameraHorizontalFov())
    P("getCameraVerticalFov: "..system.getCameraVerticalFov())

    P("getCameraPos: "..PM.Vec3String(system.getCameraPos()))
    P("getCameraForward: "..PM.Vec3String(system.getCameraForward()))
    P("getCameraRight: "..PM.Vec3String(system.getCameraRight()))
    P("getCameraUp: "..PM.Vec3String(system.getCameraUp()))

    P("getCameraWorldPos: "..PM.Vec3String(system.getCameraWorldPos()))
    P("getCameraWorldForward: "..PM.Vec3String(system.getCameraWorldForward()))
    P("getCameraWorldRight: "..PM.Vec3String(system.getCameraWorldRight()))
    P("getCameraWorldUp: "..PM.Vec3String(system.getCameraWorldUp()))

    P("construct.getWorldPosition: "..PM.Vec3String(construct.getWorldPosition(CNID)))
    P("construct.getOrientationForward: "..PM.Vec3String(construct.getOrientationForward()))
    P("construct.getOrientationRight: "..PM.Vec3String(construct.getOrientationRight()))
    P("construct.getOrientationUp: "..PM.Vec3String(construct.getOrientationUp()))
end

function cmd.DumpPointsCmd()
    if true then
        P("~=~=~=~=~=~=~= DUMP START ~=~=~=~=~=~=")
        local tmp = Out.DumpVar(WM:getWaypointsInst())
        P(tmp)
        return ScreenOutput((tmp or "[I] No waypoints."),"\n~=~=~=~=~=~=~= DUMP END ~=~=~=~=~=~=~=")
    end
---@if DEBUG true
    if DetectedYFS then
        P("~=~=~=~=~=~=~= POINTS DUMP START ~=~=~=~=~=~=")
        local tmp = YFSDB:getString(YFS_NAMED_POINTS)
        P(tmp)
        return ScreenOutput((tmp or "[I] No points."),"\n~=~=~=~=~=~=~= POINTS DUMP END ~=~=~=~=~=~=~=")
    end
    ---@diagnostic disable-next-line: undefined-field
    if DetectedArch > 0 and Config.databanks[DetectedArch] and Config.databanks[DetectedArch].getStringValue then
        P("~=~=~=~=~=~=~= LOCATIONS DUMP START ~=~=~=~=~=~=")
        ---@diagnostic disable-next-line: undefined-field
        local tmp = Config.databanks[DetectedArch].getStringValue(ARCH_SAVED_LOCATIONS)
        P(tmp)
        return ScreenOutput((tmp or "[I] No locations."),"\n~=~=~=~=~=~=~= LOCATIONS DUMP END ~=~=~=~=~=~=~=")
    end
    E("[E] No compatible databank found.")
---@end
end

function cmd.DumpRoutesCmd()
    if not DetectedYFS then return E("[I] No YFS databank.") end
    P("~=~=~=~=~=~=~= ROUTES DUMP START ~=~=~=~=~=~=")
    local tmp = YFSDB:getString(YFS_ROUTES)
    P(tmp)
    ScreenOutput((tmp or "[I] No routes."),"\n~=~=~=~=~=~=~= ROUTES DUMP END ~=~=~=~=~=~=~=")
end

function cmd.RoutesCmd()
    local routes = cmd.GetYFSRoutes()
    if not routes then return end
    P("[I] Available routes:")
    for k,_ in pairs(routes.v) do
        P(k)
    end
end

-- *** Dev/Testing functions ***

function cmd.YfsTestDataCmd(param)
    if not (param == "TESTING") then return end
    P("[*] Creating YFS test data...")

    YFSDB:remove(YFS_NAMED_POINTS)
    local data = { }
    data["Chr 01"] = { pos = "::pos{0,7,-20.7784,-153.7402,360.5184}", opt = {} }
    data["Chr 02"] = { pos = "::pos{0,7,-21.3610,-152.3447,345.8787}", opt = {} }
    data["Chr 03"] = { pos = "::pos{0,7,-23.0540,-152.8934,360.6677}", opt = {} }
    data["Chr 04"] = { pos = "::pos{0,7,-22.4445,-154.3119,320.1029}", opt = {} }
    data["Chr 05"] = { pos = "::pos{0,7,-20.5370,-154.7507,308.0151}", opt = {} }
    data["Chr 06"] = { pos = "::pos{0,7,-21.6295,-155.1465,292.7660}", opt = {} }
    data["Chr Hub"] = { pos = "::pos{0,7,-21.9903,-153.1008,391.4632}", opt = {} }
    local tmp = { v = data, t = type(data) }
    storeYFSNamedWaypoints(tmp)

    YFSDB:remove(YFS_ROUTES)
    local r = { }
    -- r["Test"] = { points = { } }
    -- r["Test"].points[1] = { pos = "::pos{0,7,-20.8094,-153.7308,366.1022}", waypointRef = "Chr 01" }
    storeYFSRoutes({ v = r, t = type(r) })

    P("[*] YFS test data saved!")
    cmd.DumpPointsCmd()
    cmd.DumpRoutesCmd()
end

function cmd.ConversionTestCmd(param)
    PM.ConversionTest()
end

function cmd.XCmd()
    -- local s = "-name C -altitude 440 -marginL 0.5 -marginF 1 -finalSpeedF 10 -suffix 'F'"
    -- P("X params: "..s)
    -- cmd.YfsBuildRouteFromWpCmd(s)
end

return cmd