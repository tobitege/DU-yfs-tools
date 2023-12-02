--- Class related to positions/coordinates like local/world conversion etc.
--- requires global WaypointInfo table (= atlas), vec3 library; classes SU, Out
local max, cos, macos, mdeg, msin, mabs, atan, ceil, floor, mpi = math.max, math.cos, math.acos, math.deg, math.sin, math.abs, math.atan, math.ceil, math.floor, math.pi
local tonum, strlen, strmatch, sformat = tonumber, string.len, string.match, string.format
local uclamp, vec3 = utils.clamp, vec3

local o = {}
o.__index = o
function o.New(pCore, pConstruct, pWM)
    -- Private attribute
    local s = {
        core = pCore,
        construct = pConstruct,
        Alioth1G = 9.891,
        waypointNames = {},
        waypointCount = 0,
        planetNames = {},
        p = {}, -- Planet object
        pIdx = 0, -- Atlas planet index
        wm = pWM -- Waypoint Manager instance
    }

    local function float_eq(a, b) -- float equation
        if a == 0 then
            return mabs(b) < 1e-09
        elseif b == 0 then
            return mabs(a) < 1e-09
        else
            return mabs(a - b) < math.max(mabs(a), mabs(b)) * epsilon
        end
    end

    ---@return boolean
    local function constructPresent()
        return s.construct ~= nil
    end

    ---@return boolean
    local function corePresent()
        return s.core ~= nil
    end

    -- Public functions

    ---@return number amount of warp cells
    function o.ComputeCells(distance, tons)
        return ceil(max(floor(tons*floor(((distance/1000)/200))*0.00024), 1))
    end

    ---@return string
    function o.GetPosPattern()
        local num = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
        return '::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' .. num ..  ',' .. num .. '}'
    end

    ---@return number # of entries in WaypointInfo/Atlas
    function o.GetWaypointCount()
        return s.wm:getCount()
    end

    ---@param posStr string ::pos{} string
    ---@return table|nil returns a MapPos table of the coords or nil if invalid string
    function o.SplitPos(posStr)
        -- min. length is 16: "::pos{0,1,2,3,4}"
        if type(posStr) ~= "string" then
            P("[E] Invalid position: "..type(posStr))
            return nil
        end
        if strlen(posStr) < 16 or not strmatch(posStr, "^::pos{") then
            P("[E] Invalid position: "..posStr)
            return nil
        end
        local sysId, pId, lat, lng, alt = strmatch(posStr, o.GetPosPattern())
        return { systemId  = tonum(sysId),
                 id        = tonum(pId),
                 latitude  = tonum(lat),
                 longitude = tonum(lng),
                 altitude  = tonum(alt) }
    end

    ---@param posString string The ::pos{} string in local coords!
    ---@return number Altitude in meters (if a local pos -> relative to sea level)
    function o.GetAltitudeFromPos(posString)
        local p = o.SplitPos(posStr)
        if p and p.altitude then return p.altitude end
        return 0
    end

    ---@param posStr string The ::pos{} string
    ---@return integer Id of planet in Atlas, e.g. 2 for Alioth; 0 for Space!
    function o.GetPlanetFromPos(posStr)
        local p = o.SplitPos(posStr)
        if p and p.id and p.id > 0 then return p.id end
        return 0
    end

    function o.GetAtlasPlanet(pid)
        if not pid or not WaypointInfo[0] or not WaypointInfo[0][tonum(pid)] then
            return nil
        end
        return WaypointInfo[0][tonum(pid)]
    end

    function o.GetClosestPlanetId(worldPosVec)
        local pIdx, dist = 0, 0
        local planetDistance = math.huge
        for i,v in pairs(WaypointInfo[0]) do
            dist = (worldPosVec - vec3(v.center)):len()
            if dist < planetDistance then
                planetDistance = dist
                pIdx = i
            end
        end
        return pIdx
    end

    function o.GetClosestPlanet(worldPosVec)
        local pid = o.GetClosestPlanetId(worldPosVec)
        return o.GetAtlasPlanet(pid)
    end

    function o.GetCurrentPosString()
        local v = o.WorldPosVec3()
        return o.MapPos2String(o.WorldToMapPos(v))
    end

    ---@comment Formats a MapPos table to a ::pos{} string
    ---@return string
    function o.MapPos2String(mapPos)
        if type(mapPos) ~= "table" then return "" end
        return '::pos{' .. (mapPos.systemId or 0).. ',' .. (mapPos.id or 0) .. ',' ..
               sformat("%.4f", (mapPos.latitude or 0)) .. ',' .. 
               sformat("%.4f", (mapPos.longitude or 0)) ..  ',' ..
               sformat("%.4f", (mapPos.altitude or 0)) .. '}'
    end

    ---@comment Formats a vec3 world-pos table to a ::pos{} string (planet id 0!)
    ---@return string
    function o.Vec3ToPosString(v3)
        if type(v3) ~= "table" then return "" end
        return '::pos{0,0,' ..
               sformat("%.4f", (v3.x or 0)) .. ',' ..
               sformat("%.4f", (v3.y or 0)) ..  ',' ..
               sformat("%.4f", (v3.z or 0)) .. '}'
    end

    ---@comment Formats a vec3 world-pos table to a ::pos{} string (planet id 0!)
    ---@return string
    function o.Vec3String(v3)
        if type(v3) ~= "table" then return "" end
        v3 = vec3(v3)
        return sformat("%.4f", (v3.x or 0)) .. ', ' ..
               sformat("%.4f", (v3.y or 0)) .. ', ' ..
               sformat("%.4f", (v3.z or 0))
    end

    ---@param posStr string ::pos{} string for change
    ---@param newAltitude number? new altitude value
    ---@return string
    function o.ReplaceAltitudeInPos(posStr, newAltitude)
        --TODO: move this to Waypoint class; allow class as param
        local p = o.SplitPos(posStr)
        if not p or not p.altitude or not newAltitude then
            return posStr
        end
        p.altitude = tonum(newAltitude)
        return o.MapPos2String(p)
    end

    ---@comment Returns current planet id if in game, otherwise 2
    ---@return number
    function o.PlanetId()
        if not corePresent() then return 0 end
        if not INGAME then
            return 2 -- Alioth
        end
        return s.core.getCurrentPlanetId()
    end

    ---@comment If code is run outside of game, a fixed vec3 will be returned for testing!
    ---@return any Vec3 position of construct (or nil)
    function o.WorldPosVec3()
        if not INGAME then
            return { x = -25140.37011013, y = 100812.26194182, z = -52412.710373821}
        end
        if constructPresent() then
            ---@diagnostic disable-next-line: missing-parameter
            return vec3(construct.getWorldPosition())
        end
        if corePresent() then
            ---@diagnostic disable-next-line: missing-parameter
            return vec3(core.getWorldPosition())
        end
        return nil
    end

    ---@comment If close to planet, returns the current altitude
    ---@return number Altitude in meters; 0 if not close to a planet!
    function o.Altitude()
        local p = o.GetAtlasPlanet(o.PlanetId())
        if not p or not p.center then return 0 end
        return (o.WorldPosVec3() - vec3(p.center)):len() - (p.radius or 0)
    end

    ---@comment Returns distance between
    --- a) current construct position and the one passed in
    ---   posStr (distTo not specified) in ::pos{0,x,...} format!
    --- OR
    --- b) both params specified, each separate coords.
    ---@param posStr string ::pos() string to measure FROM
    ---@param distTo nil optional ::pos() to measure TO; if empty -> current position
    ---@return number
    function o.GetDistance(posStr, distToStr)
        local curPos = o.WorldPosVec3()
        if type(distToStr) == "string" then
            curPos = o.MapPosToWorldVec3(distToStr)
        elseif type(distToStr) == "table" then
            curPos = vec3(distToStr)
        end
        local wPos = o.MapPosToWorldVec3(posStr)
        local dist = vec3(wPos - curPos):len()
        return dist
    end

    ---@comment experimental/unused; credit to Jeronimo
    ---@return number,number,number with x,y,z
    function o.World2local(x,y,z)
        --if not o.construct then return 0,0,0 end
        local cWOUP = s.construct.getWorldOrientationUp()
        local cWOF = s.construct.getWorldOrientationForward()
        local cWOR = s.construct.getWorldOrientationRight()
        local cWOUPx, cWOUPy, cWOUPz = cWOUP[1], cWOUP[2], cWOUP[3]
        local cWOFx, cWOFy, cWOFz = cWOF[1], cWOF[2], cWOF[3]
        local cWORx, cWORy, cWORz = cWOR[1], cWOR[2], cWOR[3]

        local v = library.systemResolution3(
            {cWORx,  cWORy, cWORz},
            {cWOFx,  cWOFy, cWOFz},
            {cWOUPx, cWOUPy, cWOUPz},
            {x, y, z})
        return v[1],v[2],v[3]
    end

    ---@param v table the vec3() position to convert
    ---@return any MapPos table or nil
    function o.WorldToMapPos(v)
        local body = o.GetClosestPlanet(v)
        if not body or not body.center or not body.radius then
            return { systemId = 0, id = 0, latitude = v.x, longitude = v.y, altitude = v.z }
        end
        local coords = v - vec3(body.center)
        local dist = coords:len()
        local alt = dist - body.radius
        local latitude = 0
        local longitude = 0
        if not float_eq(dist, 0) then
            local phi = atan(coords.y, coords.x)
            --phi >= 0 ???
            longitude = phi or (2 * mpi + phi)
            latitude = mpi / 2 - macos(coords.z / dist)
        end
        return {
            latitude  = mdeg(latitude),
            longitude = mdeg(longitude),
            altitude  = alt,
            id        = body.systemId,
            systemId  = body.id }
    end

    function o.PlanetByName(name)
        if type(name) ~= "string" or name == "" then return nil end
        name = name:lower()
        if s.planetNames[name] then
            local pid = tonum(s.planetNames[name])
            return WaypointInfo[0][pid]
        end
        return nil
    end

    ---comment Converts ::pos{} string into vec3
    ---@param posStr string ::pos{} string
    ---@return any vec3() or nil
    function o.MapPosToWorldVec3(posStr)
        local p = o.SplitPos(posStr)
        if not p or not p.systemId then return nil end
        if (p.systemId == 0 and p.id == 0) then -- already WorldPos
            return vec3(p.latitude, p.longitude, p.altitude)
        end
        if not WaypointInfo[p.systemId] then return nil end
        local planet = WaypointInfo[p.systemId][p.id]
        --credits to Saga for lat/lon calc
        local lat = constants.deg2rad * uclamp(p.latitude, -90, 90)
        local lon = constants.deg2rad * (p.longitude % 360)
        local xproj = cos(lat)
        local planetxyz = vec3(xproj*cos(lon), xproj*msin(lon), msin(lat))
        return vec3(planet.center) + (planet.radius + p.altitude) * planetxyz
    end

    function o.PlanetInfo(id)
        local pid = nil
        if type(id) == "string" and id:len() == 0 then
            id = o.GetClosestPlanetId(o.WorldPosVec3())
        end
        if type(id) == "string" and s.planetNames[id:lower()] then -- id as planet name
            pid = tonum(s.planetNames[id:lower()])
        elseif type(id) == "number" and tonum(id) > 0 then -- id as planet id
            pid = tonum(id)
        end
        if pid == nil then
            return E("[E] No valid planet name or id specified!")
        end
        local p = o.GetAtlasPlanet(pid)
        if not p or type(p.name) ~= "table" then
            return E("[E] No planet found!")
        end
        P"~~~~~~~~ PLANET INFO ~~~~~~~~"
        if id == '' then
          P("Hint: '/planetInfo 2' for Alioth")
        end
        P("Name: "..p.name[1].." (Id: ".. p.id ..")")
        P("Center: "..p.center[1].." / "..p.center[2].." / "..p.center[3])
        P("Radius: "..(p.radius or 0).."m")
        local tmp = ""
        if p.gravity and p.gravity > 0 then
            tmp = " ("..sformat("%.1f", (p.gravity / s.Alioth1G)) .." g)"
        end
        P("Gravity: "..(p.gravity or 0)..tmp)
        if p.satellites and #p.satellites > 0 then
          P("Has Moons: "..#p.satellites)
        end
        P("Surface Min Alt.: "..(p.surfaceMinAltitude or 0).."m")
        P("Surface Max Alt.: "..(p.surfaceMaxAltitude or 0).."m")
        P("Max Static Alt.: "..(p.maxStaticAltitude or "").."m")
        P("Has atmosphere: "..BoolStr(p.hasAtmosphere))
        if p.hasAtmosphere then
          P("Atmo Thickness: "..(p.atmosphereThickness or 0).."m")
          P("Atmo altitude: "..(p.atmoAltitude or 0).."m")
          P("Atmo 10%: "..(p.atmo10 or 0).."m")
        end
        P("Is in Safe Zone: "..BoolStr(p.isInSafeZone))
        P"~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    end

    ---@comment Adds a named waypoint to the internal list.
    --- Source position string can be local or world position.
    --- World position will be converted to local and ::pos{}
    --- changed accordingly - IF a closest body was in range.
    ---@param posString string Local or world ::pos{} string
    ---@param wpName string Name of the newly named waypoint
    ---@return boolean true if added else false
    function o.CreateWaypoint(posString, wpName)
        if not s.wm or not wpName or wpName == '' or s.waypointNames[wpName] then
            return false
        end

        -- convert between local and world pos if needed
        local p = o.SplitPos(posString)
        if not p or not p.systemId then return false end

        local pcenter = { p.latitude, p.longitude, p.altitude }
        -- if world pos, try to determine planet
        if p.id == 0 then
            local w = o.WorldToMapPos(vec3(pcenter))
            if w and w.id and w.id > 0 then
                -- update pos with converted values
                p.latitude  = w.latitude
                p.longitude = w.longitude
                p.altitude  = w.altitude
                p.id        = w.id
                p.systemId  = w.systemId
                posString = o.MapPos2String(p)
            end
        else
            local v = o.MapPosToWorldVec3(posString)
            pcenter = { v.x, v.y, v.z }
        end

        -- add waypoint to waypoint manager
        local wp = Waypoint:new(s.wm):setName(wpName):set(posString)
        if not wp or wp == {} then return false end
        if s.wm:exists(wp) then return false end
        return s.wm:add(wp)
    end

    ---@comment Simple test for coord conversion
    function o.ConversionTest()
        local p1 = "::pos{0,2,35.5118,104.0375,285.3076}"
        local w1 = o.MapPosToWorldVec3(p1)
        P("HQ local to world:\n"..p1.." =")
        P(o.Vec3ToPosString(w1))
        local w2 = o.WorldToMapPos(w1)
        Out.DeepPrint(w2)
        P("World to local (should show same as above):")
        P(o.MapPos2String(w2))

        local wp = "::pos{0,0,-24955.2183,99771.5731,-52908.1353}"
        if o.CreateWaypoint(wp, "WorldPos") then
          P("Added 'WorldPos' waypoint")
        else
          P("Failed to add test waypoint!")
        end
    end

    local function init()
        s.pIdx = 0
        s.p = o.GetAtlasPlanet(o.PlanetId())
        if s.p then s.pIdx = s.p.id end
        if not WaypointInfo[0] then return end
        s.planetNames = {}
        for i, v in pairs(WaypointInfo[0]) do
            s.planetNames[v.name[1]:lower()] = i
            -- remove junk
            WaypointInfo[0][i].biosphere = nil
            WaypointInfo[0][i].classification = nil
            WaypointInfo[0][i].description = nil
            WaypointInfo[0][i].habitability = nil
            WaypointInfo[0][i].ores = nil
            -- new props
            if v.hasAtmosphere then
                local res = v.atmosphereRadius - v.radius
                WaypointInfo[0][i].atmoAltitude = res
                WaypointInfo[0][i].atmo10 = res * 0.9
            end
            WaypointInfo[0][i].isAsteroid = WaypointInfo[0][i].type[1] == "Asteroid"
            WaypointInfo[0][i].isMoon = WaypointInfo[0][i].type[1] == "Moon"
            WaypointInfo[0][i].isPlanet = WaypointInfo[0][i].type[1] == "Planet"
        end

        --s.wm = WaypointMgr.new("MAIN")
        if s.wm then
            P("[I] WaypointMgr assigned: "..s.wm:getName())
        else
            P("[E] NO WaypointMgr assigned!")
        end
    end

    init()
    return setmetatable(s, o)
end -- .New

return o