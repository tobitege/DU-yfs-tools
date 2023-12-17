-- wolfeARlib.lua
-- Requires stl.lua, global WaypointInfo (Atlas data!)

local uclamp = utils.clamp

local wolfie = {
    core = nil,
    destList = {},
    destCount = 0,
    renderLimitKm = 5
}
-- 'Montserrat' is better with 0.8
-- 'Refrigerator' is better with 1.2
local fontSize = 1.2 -- em's, not pixels :P
local font = 'Oxanium' -- 'Refrigerator'
local colorBlue = { 130, 224, 255 } -- blue #66CCFF
local colorLime = { 50, 205, 50 }   -- lime #32CD32
local colorOrange = { 256, 128, 0 } -- orange #ff8000

--- Distance to "infinity", used when projecting AR directions, set to 100su
---@type number
local infinityDistance = 100 * 200000
---@type number
local referenceGravity1g = nil

--- Gets the appropriate HUD color
---@param forcePvPZone boolean
---@return table<number,number>
local function getHudColor(distance)
    if distance and distance > 2250 then
        return colorOrange
    end
    return colorLime
end

--- Gets the appropriate HUD color in RGB notation
---@param alpha number
---@param forcePvPZone boolean
---@return string
local function getHudColorRgb(alpha, distance)
    local color = getHudColor(distance)
    color[4] = alpha or 1
    return ('rgba(%s, %s, %s, %s)'):format(color[1], color[2], color[3], color[4])
end

--- Converts a coordinate from local to world space
local function convertLocalToWorldCoordinates(coordinate)
    return vec3(construct.getWorldPosition())
        + coordinate.x * vec3(construct.getWorldOrientationRight())
        + coordinate.y * vec3(construct.getWorldOrientationForward())
        + coordinate.z * vec3(construct.getWorldOrientationUp())
end

--- Gets the current forward direction in world space
---@return vec3
local function getCurrentPointedAt()
    return convertLocalToWorldCoordinates(vec3(0, infinityDistance, 0))
end

--- Converts a distance amount into meters, kilometers or su
---@param distance number
---@return string
local function getDistanceAsString(distance)
    if distance > 100000 then
        return ('%.2f su'):format(distance / 200000)
    elseif distance > 1000 then
        return ('%.2f km'):format(distance / 1000)
    elseif distance > 10 then
        return ('%.1f m'):format(distance)
    end
    return ('%.2f m'):format(distance)
end

--- Gets the distance to a certain point in space
---@param point vec3
---@return number
local function getDistanceToPoint(point)
    return (vec3(construct.getWorldPosition()) - point):len()
end

local function getARPointFromCoordinate(coordinate)
    local result = vec3(library.getPointOnScreen({ coordinate:unpack() }))
    if result:len() == 0 then
        return nil
    end
    return result
end

--- Rounds a value to desired precision
---@param value number
---@param precision number
---@return string
local function getRoundedValue(value, precision)
    return ('%.' .. (precision or 0) .. 'f'):format(value)
end

--- Gets closest celestial body to world position (in m/s²)
---@param altitude number
---@param celestialBody table
local function getGravitationalForceAtAltitude(altitude, celestialBody)
    return celestialBody.GM / (celestialBody.radius + altitude) ^ 2
end

--- Gets closest celestial body to world position (in Gs)
---@param altitude number
---@param celestialBody table
local function getGravitationalForceAtAltitudeInGs(altitude, celestialBody)
    return getGravitationalForceAtAltitude(altitude, celestialBody) / referenceGravity1g
end

--- Gets the altitude where a celestial body has certain gravitational force (in m/s²)
---@param intensity number
---@param celestialBody table
local function getAltitudeAtGravitationalForce(intensity, celestialBody)
    return math.sqrt(celestialBody.GM / intensity) - celestialBody.radius
end

--- Gets closest celestial body to world position
---@param position vec3
---@param allowInfiniteRange boolean
local function getClosestCelestialBody(position, allowInfiniteRange)
    local closestBody = nil
    local closestBodyDistance = nil
    for _, celestialBody in pairs(WaypointInfo[0]) do
        local celestialBodyPosition = vec3(celestialBody.center)
        local celestialBodyDistance = (position - celestialBodyPosition):len()
        local celestialBodyAltitude = celestialBodyDistance - (celestialBody.radius or 0)
        if (not closestBodyDistance or closestBodyDistance > celestialBodyAltitude) and (allowInfiniteRange or celestialBodyDistance <= 400000) then
            closestBody = celestialBody
            closestBodyDistance = celestialBodyAltitude
        end
    end
    return closestBody, closestBodyDistance
end

--- Gets a celestial body relative position from a world position
---@param position vec3
---@param celestialBody table
---@return table
local function getCelestialBodyPosition(position, celestialBody)
    return position - vec3(celestialBody.center.x, celestialBody.center.y, celestialBody.center.z)
end

--- Gets a lat, lon, alt position from a world position
---@param position vec3
---@param celestialBody table
---@return table
local function getLatLonAltFromWorldPosition(position, celestialBody)
    -- We need to extract the "local" coordinate (offset from planet center) here and then normalize it to do math with it
    local offset = getCelestialBodyPosition(position, celestialBody)
    local offsetNormalized = offset:normalize()
    return {
        lat = 90 - (math.acos(offsetNormalized.z) * 180 / math.pi),
        lon = math.atan(offsetNormalized.y, offsetNormalized.x) / math.pi * 180,
        alt = offset:len() - celestialBody.radius,
    }
end

--- Gets the distance to a certain point in space
--- Code adapted from: https://community.esri.com/t5/coordinate-reference-systems-blog/distance-on-a-sphere-the-haversine-formula/ba-p/902128
---@param point vec3
---@param celestialBody table
---@return number
local function getDistanceAroundCelestialBody(point, celestialBody)
    local currentCoordinates = getLatLonAltFromWorldPosition(vec3(construct.getWorldPosition()), celestialBody)
    local targetCoordinates = getLatLonAltFromWorldPosition(point, celestialBody)
    local flyingAltitude = math.max(currentCoordinates.alt, celestialBody.maxStaticAltitude or 1000)

    -- Helper function to convert degrees to radians
    local function rad(deg)
        return deg * math.pi / 180
    end

    --local phi1, phi2 = rad(currentCoordinates.lat), rad(targetCoordinates.lat)
    local phi2 = rad(targetCoordinates.lat)
    local deltaPhi, deltaLambda = rad(currentCoordinates.lat - targetCoordinates.lat), rad(currentCoordinates.lon - targetCoordinates.lon)

    local a = math.sin(deltaPhi / 2) ^ 2 + math.cos(phi2) * math.cos(phi2) * math.sin(deltaLambda / 2) ^ 2
    local c = 2 * math.atan(math.sqrt(a), math.sqrt(1 - a))

    return (celestialBody.radius + flyingAltitude) * c
end

function wolfie.render(destList)
    local UI = {}
    local Shapes = {}

    --- Draws the hexagon, showing the current destiantion point in space
    Shapes.Hexagon = STL([[
    <svg style="width: {{ size or 1 }}em; height: {{ size or 1 }}em;" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M24.25 1.56699L24 1.42265L23.75 1.56699L4.69745 12.567L4.44745 12.7113V13V35V35.2887L4.69745 35.433L23.75 46.433L24 46.5774L24.25 46.433L43.3026 35.433L43.5526 35.2887V35V13V12.7113L43.3026 12.567L24.25 1.56699ZM9.44745 32.4019V15.5981L24 7.19615L38.5526 15.5981V32.4019L24 40.8038L9.44745 32.4019Z" fill="{{ color }}" stroke="{{ stroke }}"/>
    </svg>
    ]])

    --- Draws the crosshair, showing current forward direction
    Shapes.Crosshair = STL([[
    <svg style="width: {{ size or 1 }}em; height: {{ size or 1 }}em;" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M23.6465 37.8683L24.0001 38.2218L24.3536 37.8683L26.3536 35.8684L26.5 35.7219V35.5148V26.5H35.5148H35.7219L35.8684 26.3536L37.8684 24.3536L38.2219 24L37.8684 23.6465L35.8684 21.6465L35.7219 21.5H35.5148H26.5V12.4852V12.2781L26.3536 12.1317L24.3536 10.1317L24.0001 9.77818L23.6465 10.1317L21.6465 12.1318L21.5 12.2782V12.4854V21.5H12.4854H12.2782L12.1318 21.6465L10.1318 23.6465L9.77824 24L10.1318 24.3536L12.1318 26.3536L12.2782 26.5H12.4854H21.5V35.5147V35.7218L21.6465 35.8682L23.6465 37.8683Z" fill="{{ color }}" stroke="{{ stroke }}"/>
    </svg>
    ]])

    local renderGlobals = {
        Colors = {
            Shadow = 'rgba(0, 0, 0, 0.75)',
            ShadowLight = 'rgba(0, 0, 0, 0.375)',
        },
        DistanceAroundCelestialBody = getDistanceAroundCelestialBody,
        DistanceTo = getDistanceToPoint,
        Exists = function(value) return 'nil' ~= type(value) end,
        GetHudColor = getHudColorRgb,
        GravityAt = getGravitationalForceAtAltitude,
        GravityAtInGs = getGravitationalForceAtAltitudeInGs,
        Metric = getDistanceAsString,
        Percentage = function(value, precision) return getRoundedValue(100 * (value or 1), precision) .. '%' end,
        Round = getRoundedValue,
        WorldCoordinate = getARPointFromCoordinate,
        UI = UI,
        Shapes = Shapes,
        renderLimit = wolfie.renderLimitKm
    }

    --- Draws text
    -- text-shadow: 0px 0px 0.125em {{ stroke or Colors.Shadow }}, 0px 0px 0.250em #000, 0px 0px 0.500em #000;">
    renderGlobals.Label = STL([[<span style="font-size: {{ size or ']]..fontSize..[[' }}em; font-family: {{ font or ']]..font..[[' }};
        font-weight: {{ weight or 'normal' }}; color: {{ color or GetHudColor() }};
        text-shadow: 2px 2px 0.125em {{ stroke or Colors.Shadow }}, -2px -2px 0.50em #000, 2px -2px 0.50em #000;">
    {{ text }}
    </span>
    ]], renderGlobals)

    --- Creates an element that is always centered at a certain coordinate
    UI.PositionCenteredAt = STL('position: absolute; top: {{ Percentage(y, 5) }}; left: {{ Percentage(x, 5) }}; margin-top: -{{ (height or 1) / 2 }}em; margin-left: -{{ (width or 1) / 2 }}em;'
    , renderGlobals)

    --- Renders a full destination marker (hexagon + info)
    UI.DestinationMarker = STL([[
    {%
    local screen = WorldCoordinate(position)
    local distance = DistanceTo(position)

    -- When on same celestial body, we need to take into account going around it
    -- We use math.max here so we can also take the vertical displacement into account
    if Exists(currentCelestialBody) and Exists(destinationCelestialBody) and currentCelestialBody.info.id == destinationCelestialBody.info.id then
        distance = math.max(distance, DistanceAroundCelestialBody(position, destinationCelestialBody.info))
    end
    local distKm = distance / 1000
    local showWP = screen and ((renderLimit < 0.01) or (renderLimit > distKm))
    %}
    {% if showWP then %}
        {% if distance and title and distance < 10 then %}
        <div style="font-size: 1em; position: absolute; top: 50%; left: 0.25em; white-space: nowrap; padding: 0px 0.5em;">
            {{ Label({ text = title, size = 1.5 }) }}
        </div>
        {% end %}
        <div style="{{ UI.PositionCenteredAt({ x = screen.x, y = screen.y, width = 2, height = 2 }) }}">
        <div style="postion: relative;">
            {{ Shapes.Hexagon({ color = GetHudColor(1, distance), stroke = Colors.Shadow, size = 2 }) }}
            {% if title or distance then %}
            <div style="font-size: 0.8em; position: absolute; top: 1em; left: 2.5em; white-space: nowrap; padding: 0px 0.5em;">
            <hr style="border: 0px none; height: 2px; background: {{ GetHudColor(1, distance) }}; width: 5em; margin: 0px -0.5em 0.5em; padding: 0px;" />
            {% if title then %}
            <div>{{ Label({ text = title, size = 1, weight = 'bold' }) }}</div>
            {% end %}
            {% if distance then %}
            <div>{{ Label({ text = Metric(distance), size = 1 }) }}</div>
            {% end %}
            </div>
            {% end %}
            </div>
        </div>
    {% end %}
    ]], renderGlobals)

    --- Renders a crosshair shape
    UI.Crosshair = STL([[
    <div style="{{ UI.PositionCenteredAt({ x = x, y = y, width = 1.5, height = 1.5 }) }}">
        {{ Shapes.Crosshair({ color = GetHudColor(), stroke = Colors.Shadow, size = 1.5 }) }}
    </div>
    ]], renderGlobals)

    renderGlobals.currentPointingAt = getCurrentPointedAt() -- current direction forward

    --- rAR contains rendered, AR-related items
    local rAR = [[<div class="wlhud-ar-elements">
    {%
    if currentPointingAt then
        currentPointingAtOnScreen = WorldCoordinate(currentPointingAt)
    end
    %}
    {% if Exists(currentPointingAtOnScreen) then %}
        {{ UI.Crosshair(currentPointingAtOnScreen) }}
    {% end %}
    ]]

    local currentCelestialBodyInfo, currentCelestialBodyCoordinates = nil, nil
    local currentPosition = vec3(construct.getWorldPosition())
    local currentCelestialBody = getClosestCelestialBody(currentPosition,false)
    if currentCelestialBody then
        currentCelestialBodyCoordinates = getLatLonAltFromWorldPosition(currentPosition, currentCelestialBody)
        if currentCelestialBodyCoordinates then
            currentCelestialBodyInfo = { info = currentCelestialBody, coordinates = currentCelestialBodyCoordinates }
        end
    end
    if type(destList) == "table" then
        for _,dest in pairs(destList) do
            -- Is destination on same celestial body
            local isDestinationOnSameCelestialBody = false
            if currentCelestialBody and dest.bodyInfo and currentCelestialBody.id == dest.bodyInfo.info.id then
                isDestinationOnSameCelestialBody = true
            end

            local marker = STL([[ {{ UI.DestinationMarker({ title = currentDestination.name, position = currentDestination.position }) }} ]],
            {
                currentDestination = dest,
                currentCelestialBody = currentCelestialBodyInfo,
                destinationCelestialBody = dest.bodyInfo,
                destinationOnSameCelestialBody = isDestinationOnSameCelestialBody
            })
            if marker then
                rAR = rAR .. marker(renderGlobals)
            end
        end
    end
    rAR = rAR .. "</div>"
    local renderAR = STL(rAR, renderGlobals)
    if renderAR then
        return renderAR()
    end
    return ""
end

-- Pass a core unit
function wolfie.setCore(pCore)
    core = pCore
end

-- Limit in km to display waypoints (0 = unlimited; max. 1mil)
function wolfie.setRenderLimit(renderLimit)
    renderLimit = renderLimit or 0
    renderLimit = tonumber(renderLimit)
    wolfie.renderLimitKm = uclamp(renderLimit, 0, 1000000) -- 0 = unlimited; max 500 SU
end

-- Pass a list of waypoints (vec3) with their names in (name/vec3 pairs)
function wolfie.AddWaypoint(destName, vector)
    if not destName or type(vector) ~= "table" then return end
    wolfie.destCount = wolfie.destCount + 1
    local bodyCoordinates, bodyInfo = nil, nil
    local currentBody = getClosestCelestialBody(vector,false)
    if currentBody then
        bodyCoordinates = getLatLonAltFromWorldPosition(vector, currentBody)
        if bodyCoordinates then
            bodyInfo = {
                info = currentBody,
                coordinates = bodyCoordinates
            }
        end
    end
    local data = { name = destName, position = vec3(vector), bodyInfo = bodyInfo }
    wolfie.destList[wolfie.destCount] = data
end

-- Main render function returning the generated SVG
function wolfie.onRenderFrame()
    return wolfie.render(wolfie.destList)
end

return wolfie