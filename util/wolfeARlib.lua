-- wolflib.lua
-- Requires global WaypointInfo (Atlas data!)
local wolfie = {
    core = nil,
    destList = {},
    destCount = 0
}
-- 'Montserrat' is better with 0.8
-- 'Refrigerator' is better with 1.2
local fontSize = 1.2 -- em's, not pixels :P
local font = 'Refrigerator'
local colorBlue = { 130, 224, 255 } -- blue #66CCFF
local colorLime = { 50, 205, 50 }   -- lime #32CD32
local showEta = false

local SmartTemplateLibrary = (function ()
    --[[
      Wolfe Labs Smart Template Library (STL)
      A simple, Twig-like templating language for Lua
      Syntax:
        {{ variable }} prints the contents of "variable"
        {% some_lua_code %} executes the Lua code, useful for creating blocks like {% if %} and {% else %}, make sure you add {% end %} too :)
      (C) 2022 - Wolfe Labs
    ]]

    --- Helper function that generates a clean print statement of a certain string
    ---@param str string The string we need to show
    ---@return string
    local function mkPrint(str)
      return 'print(\'' .. str:gsub('\'', '\\\''):gsub('\n', '\\n') .. '\')'
    end

    --- Helper function that merges tables
    ---@vararg table
    ---@return table
    local function tMerge(...)
      local tables = {...}
      local result = {}
      for _, t in pairs(tables) do
        for k, v in pairs(t) do
          result[k] = v
        end
      end
      return result
    end

    ---@class Template
    local Template = {
      --- Globals available for every template by default
      globals = {
        math = math,
        table = table,
        string = string,
        ipairs = ipairs,
        pairs = pairs,
      }
    }

    -- Makes our template directly callable
    function Template.__call(self, ...)
      return Template.render(self, ({...})[1])
    end

    --- Renders our template
    ---@param vars table The variables to be used when rendering the template
    ---@return string
    function Template:render(vars)
      -- Safety check, vars MUST be a table or nil
      if type(vars or {}) ~= 'table' then
        error('Template parameters must be a table, got ' .. type(vars))
      end

      --- This is our return buffer
      local _ = {}

      -- Creates our environment
      local env = tMerge(Template.globals, self.globals or {}, vars or {}, {
        print = function (str) table.insert(_, tostring(str or '')) end,
      })

      -- Invokes our template
      self.callable(env)

      -- General trimming
      local result = table.concat(_, ''):gsub('%s+', ' ')

      -- Trims result
      result = result:sub(result:find('[^%s]') or 1):gsub('%s*$', '')

      -- Done
      return result
    end

    --- Creates a new template
    ---@param source string The code for your template
    ---@param globals table Global variables to be used on on the template
    ---@param buildErrorHandler function A function to handle build errors, if none is found throws an error
    ---@return Template|nil
    function Template.new(source, globals, buildErrorHandler)
      -- Creates our instance
      local self = {
        source = source,
        globals = globals,
      }

      -- Yield function (mostly for games who limit executions per frame)
      local yield = (coroutine and coroutine.isyieldable() and coroutine.yield) or function () end

      -- Parses direct printing of variables, we'll convert a {{var}} into {% print(var) %}
      source = source:gsub('{{(.-)}}', '{%% print(%1) %%}')

      -- Ensures {% if %} ... {% else %} ... {% end %} stays on same line
      source = source:gsub('\n%s*{%%', '{%%')
      source = source:gsub('%%}\n', '%%}')

      --- This variable stores all our Lua "pieces"
      local tPieces = {}

      -- Parses actual Lua inside {% lua %} tags
      while #source > 0 do
        --- The start index of Lua tag
        local iLuaStart = source:find('{%%')

        --- The end index of Lua tag
        local iLuaEnd = source:find('%%}')

        -- Checks if we have a match
        if iLuaStart then
          -- Errors when not closing a tag
          if not iLuaEnd then
            error('Template error, missing Lua closing tag near: ' .. source:sub(0, 16))
          end

          --- The current text before Lua tag
          local currentText = source:sub(1, iLuaStart - 1)
          if #currentText then
            table.insert(tPieces, mkPrint(currentText))
          end

          --- Our Lua tag content
          local luaTagContent = source:sub(iLuaStart, iLuaEnd + 1):match('{%%(.-)%%}') or ''
          table.insert(tPieces, luaTagContent)

          -- Removes parsed content
          source = source:sub(iLuaEnd + 2)
        else
          -- Adds remaining Lua as a single print statement
          table.insert(tPieces, mkPrint(source))

          -- Marks content as parsed
          source = ''
        end

        -- Yields loading
        yield()
      end

      -- Builds the Lua function
      self.code = table.concat(tPieces, '\n')

      -- Builds our function and caches it, this is our template now
      local _, err = load(string.format([[return function (_) _ENV = _; _ = _ENV[_]; %s; end]], self.code), nil, 't', {})
      if _ and not err then
        _ = _()
      end

      -- Checks for any errors
      if err then
        if buildErrorHandler then
          buildErrorHandler(self, err)
        else
          error('[E] Failed compiling template: ' .. err)
        end

        -- Retuns an invalid instance
        return nil
      else
        -- If everything passed, assigns our callable to our compiled function
        self.callable = _
      end

      -- Initializes our instance
      return setmetatable(self, Template)
    end

    -- By default, returns the constructor of our class
    return Template.new
end)()

local function SmartTemplate(code, globals)
return SmartTemplateLibrary(code, globals, function(template, err)
    DUSystem.print(' [ERROR] Failed compiling template: ' .. err)
    DUSystem.print('[SOURCE] ' .. code)
    error()
end)
end

--- Distance to "infinity", used when projecting AR directions, set to 100su
---@type number
local infinityDistance = 100 * 200000
---@type number
local referenceGravity1g = nil

--- Gets the appropriate HUD color
---@param forcePvPZone boolean
---@return table<number,number>
local function getHudColor()
    return colorLime
end

--- Gets the appropriate HUD color in RGB notation
---@param alpha number
---@param forcePvPZone boolean
---@return string
local function getHudColorRgb(alpha)
    local color = getHudColor()
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

--- Gets the current motion direction in world space
---@return vec3|nil
local function getCurrentMotion()
    local worldVelocity = vec3(construct.getWorldAbsoluteVelocity())
    if worldVelocity:len() < 1 then return nil end
    return worldVelocity:normalize_inplace() * infinityDistance + vec3(construct.getWorldPosition())
end

--- Converts a distance amount into meters, kilometers or su
---@param distance number
---@return string
local function getDistanceAsString(distance)
    if distance > 100000 then
        return ('%.1f su'):format(distance / 200000)
    elseif distance > 1000 then
        return ('%.1f km'):format(distance / 1000)
    end
    return ('%.1f m'):format(distance)
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

--- Converts a number of seconds into a string
---@param seconds number
---@return string
local function getTimeAsString(seconds, longFormat)
    local days = math.floor(seconds / 86400)
    seconds = seconds - days * 86400

    local hours = math.floor(seconds / 3600)
    seconds = seconds - hours * 3600

    local minutes = math.floor(seconds / 60)
    seconds = seconds - minutes * 60

    -- Long format (X hours, Y minutes, Z seconds)
    if longFormat then
        local result = {}
        if days > 0 then table.insert(result, days .. 'd') end
        if hours > 0 then table.insert(result, hours .. 'h') end
        if minutes > 0 then table.insert(result, minutes .. 'm') end
        if hours == 0 then
        table.insert(result, math.floor(seconds) .. 's')
        end
        return table.concat(result, ' ')
    end

    -- Short format (X:YY:ZZ)
    local result = {}
    if hours > 0 then
        table.insert(result, hours + 24 * days)
    end
    table.insert(result, ('%02d'):format(math.floor(minutes)))
    table.insert(result, ('%02d'):format(math.floor(seconds)))
    return table.concat(result, ':')
end

--- Rounds a value to desired precision
---@param value number
---@param precision number
---@return string
local function getRoundedValue(value, precision)
    return ('%.' .. (precision or 0) .. 'f'):format(value)
end

--- Converts a m/s value into a string (optionally converts to km/h too)
---@param value number
---@param convertToKmph boolean
---@param decimals number
---@return string
local function getMetersPerSecondAsString(value, convertToKmph, decimals)
    if convertToKmph then
        return ('%s km/h'):format(getRoundedValue(value * 3.6, decimals or 1))
    end
    return ('%s m/s'):format(getRoundedValue(value, decimals or 1))
end

local function getNewtonsAsString(value, decimals)
    local suffix = 'N'
    if value > 1000000 then
        value = value / 1000000
        suffix = 'MN'
    elseif value > 1000 then
        value = value / 1000
        suffix = 'kN'
    end
    return ('%s %s'):format(getRoundedValue(value, decimals or 1), suffix)
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

--- Gets the altitude where a celestial body has certain gravitational force (in Gs)
---@param intensity number
---@param celestialBody number
local function getAltitudeAtGravitationalForceInGs(intensity, celestialBody)
    return getAltitudeAtGravitationalForce(intensity * referenceGravity1g, celestialBody)
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

local render = (function()
    local UI = {}
    local Shapes = {}

    --- Draws the hexagon, showing the current destiantion point in space
    Shapes.Hexagon = SmartTemplate([[
    <svg style="width: {{ size or 1 }}em; height: {{ size or 1 }}em;" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M24.25 1.56699L24 1.42265L23.75 1.56699L4.69745 12.567L4.44745 12.7113V13V35V35.2887L4.69745 35.433L23.75 46.433L24 46.5774L24.25 46.433L43.3026 35.433L43.5526 35.2887V35V13V12.7113L43.3026 12.567L24.25 1.56699ZM9.44745 32.4019V15.5981L24 7.19615L38.5526 15.5981V32.4019L24 40.8038L9.44745 32.4019Z" fill="{{ color }}" stroke="{{ stroke }}"/>
    </svg>
    ]])

    --- Draws the crosshair, showing current forward direction
    Shapes.Crosshair = SmartTemplate([[
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
        Newtons = getNewtonsAsString,
        Percentage = function(value, precision) return getRoundedValue(100 * value, precision) .. '%' end,
        Round = getRoundedValue,
        Time = getTimeAsString,
        TimeToDistance = function(distance, speed) return ((speed > 0) and getTimeAsString(distance / speed, true)) or nil end,
        WorldCoordinate = getARPointFromCoordinate,
        UI = UI,
        Shapes = Shapes,
        ShowETA = showEta,
    }

    --- Draws text
    -- text-shadow: 0px 0px 0.125em {{ stroke or Colors.Shadow }}, 0px 0px 0.250em #000, 0px 0px 0.500em #000;">
    renderGlobals.Label = SmartTemplate([[
        <span style="font-size: {{ size or ']]..fontSize..[[' }}em; font-family: {{ font or ']]..font..
        [[' }}; font-weight: {{ weight or 'normal' }}; color: {{ color or GetHudColor() }}; text-shadow: 2px 2px 0.125em {{ stroke or Colors.Shadow }}, -2px -2px 0.250em #000, 2px -2px 0.500em #000;">
          {{ text }}
        </span>
    ]], renderGlobals)

    --- Creates an element that is always centered at a certain coordinate
    UI.PositionCenteredAt = SmartTemplate(
        'position: absolute; top: {{ Percentage(y, 6) }}; left: {{ Percentage(x, 6) }}; margin-top: -{{ (height or 1) / 2 }}em; margin-left: -{{ (width or 1) / 2 }}em;'
    , renderGlobals)

    --- Renders a full destination marker (hexagon + info)
    UI.DestinationMarker = SmartTemplate([[
      {%
        local screen = WorldCoordinate(position)
        local distance = DistanceTo(position)

        -- When on same celestial body, we need to take into account going around it
        -- We use math.max here so we can also take the vertical displacement into account
        if Exists(currentCelestialBody) and Exists(destinationCelestialBody) and currentCelestialBody.info.id == destinationCelestialBody.info.id then
          distance = math.max(distance, DistanceAroundCelestialBody(position, destinationCelestialBody.info))
        end

        -- Calculates the ETA at current speed
        local eta = nil
        if Exists(ShowETA) and ShowETA and speed and speed > 1 then
          eta = TimeToDistance(distance, speed)
        end
      %}
      {% if screen then %}
        <div style="{{ UI.PositionCenteredAt({ x = screen.x, y = screen.y, width = 2, height = 2 }) }}">
          <div style="postion: relative;">
            {{ Shapes.Hexagon({ color = GetHudColor(), stroke = Colors.Shadow, size = 2 }) }}
          {% if title or distance then %}
            <div style="font-size: 0.8em; position: absolute; top: 1em; left: 2.5em; white-space: nowrap; padding: 0px 0.5em;">
              <hr style="border: 0px none; height: 2px; background: {{ GetHudColor() }}; width: 5em; margin: 0px -0.5em 0.5em; padding: 0px;" />
            {% if title then %}
              <div>{{ Label({ text = title, size = 1.1, weight = 'bold' }) }}</div>
            {% end %}
            {% if distance then %}
              <div>{{ Label({ text = Metric(distance) }) }}</div>
            {% end %}
            {% if eta then %}
              <div style="font-size: 0.8em;">{{ Label({ text = 'ETA: ' .. eta }) }}</div>
            {% end %}
            </div>
          {% end %}
          </div>
        </div>
      {% end %}
      ]], renderGlobals)

      --- Renders a crosshair shape
    UI.Crosshair = SmartTemplate([[
    <div style="{{ UI.PositionCenteredAt({ x = x, y = y, width = 1.5, height = 1.5 }) }}">
        {{ Shapes.Crosshair({ color = GetHudColor(), stroke = Colors.Shadow, size = 1.5 }) }}
    </div>
    ]], renderGlobals)

    --- This function renders anything AR-related, it has support for smooth mode, so it renders both latest and previous frame data
    local renderAR = SmartTemplate([[
    <div class="wlhud-ar-elements">
        {%
        if currentPointingAt then
            currentPointingAtOnScreen = WorldCoordinate(currentPointingAt)
        end
        if currentMotion then
            currentMotionOnScreen = WorldCoordinate(currentMotion)
        end
        %}

        {% if Exists(currentDestination) then %}
        {{ UI.DestinationMarker({ title = currentDestination.name, position = currentDestination.position, speed = currentDestinationApproachSpeed }) }}
        {% end %}

        {% if Exists(currentPointingAtOnScreen) then %}
        {{ UI.Crosshair(currentPointingAtOnScreen) }}
        {% end %}
    </div>
    ]], renderGlobals)

    --- This is what actually renders to the screen
    return function(data)
        return renderAR(data or {})
    end
end)()

-- Pass a core unit
function wolfie.setCore(pCore)
    core = pCore
end

-- Pass a list of waypoints (vec3) with their names in (name/vec3 pairs)
function wolfie.AddWaypoint(destName, vector)
    if not destName or type(vector) ~= "table" then return end
    wolfie.destCount = wolfie.destCount + 1
    wolfie.destList[wolfie.destCount] = { name = destName, position = vec3(vector) }
end

-- Main render function returning the generated SVG
function wolfie.onRenderFrame()
    if wolfie.destCount == 0 then return "" end

    -- Pre-calculates some vectors
    local worldVelocity = vec3(construct.getWorldVelocity())

    -- This is our current celestial body and coordinates
    local currentPosition = vec3(construct.getWorldPosition())
    local currentCelestialBody, currentCelestialBodyCoordinates = getClosestCelestialBody(currentPosition,false), nil
    if currentCelestialBody then
        currentCelestialBodyCoordinates = getLatLonAltFromWorldPosition(currentPosition, currentCelestialBody)
    end

    -- This is our current direction forward
    local currentPointingAt = getCurrentPointedAt()

    -- This is our current motion vector
    local currentMotion = getCurrentMotion()

    local output = ""
    for _,currentDestination in pairs(wolfie.destList) do

        -- This is our current destination in lat/lon/alt space, along with what celestial body it is
        local currentDestinationCelestialBody, currentDestinationCelestialBodyCoordinates = nil, nil
        if currentDestination then
            currentDestinationCelestialBody = getClosestCelestialBody(currentDestination.position,false)
            if currentDestinationCelestialBody then
                currentDestinationCelestialBodyCoordinates = getLatLonAltFromWorldPosition(currentDestination.position, currentDestinationCelestialBody)
            end
        end

        -- Prepares data for our current and destination celestial body
        local currentCelestialBodyInfo, destinationCelestialBodyInfo = nil, nil
        if currentCelestialBody and currentCelestialBodyCoordinates then
            currentCelestialBodyInfo = {
                info = currentCelestialBody,
                coordinates = currentCelestialBodyCoordinates,
            }
        end
        if currentDestinationCelestialBody and currentDestinationCelestialBodyCoordinates then
            destinationCelestialBodyInfo = {
                info = currentDestinationCelestialBody,
                coordinates = currentDestinationCelestialBodyCoordinates,
            }
        end

        -- Is destination on same celestial body
        local isDestinationOnSameCelestialBody = false
        if currentCelestialBody and currentDestinationCelestialBody and currentCelestialBody.id == currentDestinationCelestialBody.id then
            isDestinationOnSameCelestialBody = true
        end

        -- Let's calculate whether we're getting closer to our destination or not
        local currentDestinationApproachSpeed = worldVelocity:len()
        if isDestinationOnSameCelestialBody then
            currentDestinationApproachSpeed = worldVelocity:len()
        elseif currentDestination then
            local destinationVector = (currentDestination.position - currentPosition):normalize()
            currentDestinationApproachSpeed = destinationVector:dot(worldVelocity)
        end

        -- This will print all data with our template
        output = output .. render({
            currentDestination = currentDestination,
            currentDestinationApproachSpeed = currentDestinationApproachSpeed,
            currentPointingAt = currentPointingAt,
            currentMotion = currentMotion,
            currentSpeed = worldVelocity:len(),
            -- Routing utilities
            currentCelestialBody = currentCelestialBodyInfo,
            destinationCelestialBody = destinationCelestialBodyInfo,
        })
    end

    return output
end

return wolfie