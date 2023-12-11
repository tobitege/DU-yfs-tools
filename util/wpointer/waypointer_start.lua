-- Original waypointer script (c) EasternGamer
-- tobitege: customisation to read YFS route waypoints
-- as well as ArchHud locations and add these for display

local enableWaypointer = true --export: Enable waypoint AR display. Default: checked.
local lowLatencyMode = true --export: Enables low latency for screen render, which can sometimes bug out if a frame gets skipped. A restart is required then.
local highPerformanceMode = false --export: Disables glow effect which can in some cases improve FPS significantly
local smooth = false --export: Caution: display can fault! Enables full FPS rendering, which increases the perceived performance for an actual performance impact
local glowRadius = 3 --export: Sets the pixel size of the glow effect. Only in non-higPerformanceMode; 0=disabled.
local displayWarpCells = false --export: Enable display of warp cells amount
local displaySolarWP = false --export: Enable display of solar objects (planets, moons)
local displayCustomWP = true --export: Enable display of custom waypoints (routes)
local archHudWaypointSize = 1 --export: The size in meters of a custom waypoint (0.1 - 10)
local archHudWPRender = 3 --export: The number of kilometers above which distance custom waypoints are not rendered
local maxWaypointSize = 200 --export: The max size of a waypoint in pixels
local minWaypointSize = 20 --export: The min size of a waypoint in pixels (max 300)
local infoHighlight = 300 --export: The number of pixels within info is displayed
local fontsize = 30 --export: Font size (default: 20)
local colorWarp = "#ADD8E6" --export: RGB color of warpable waypoints. Default: "#ADD8E6"
local nonWarp = "#FFA500" --export: RGB color of non-warpable waypoints. Default: "#FFA500"
local colorWaypoint = "#32CD32" --export: RGB color of custom waypoints. Default: "#32CD32"

local format, sqrt, len, max, print, uclamp = string.format, math.sqrt, string.len, math.max, system.print, utils.clamp
local concat,unpack = table.concat,table.unpack

local position = {0,0,0}
local offsetPos = {0,0,0}
local orientation = {0,0,0}
---@diagnostic disable-next-line: missing-parameter
local width = system.getScreenWidth() / 2
---@diagnostic disable-next-line: missing-parameter
local height = system.getScreenHeight() / 2
local objectBuilder = ObjectBuilderLinear()
fontsize = uclamp(fontsize, 10, 40)
glowRadius = uclamp(glowRadius, 0, 10)
minWaypointSize = uclamp(minWaypointSize, 5, 200)
maxWaypointSize = uclamp(maxWaypointSize, minWaypointSize+1, 400)
archHudWaypointSize = uclamp((archHudWaypointSize or 0.5), 0.1, 10)

if not enableWaypointer then
    WP_EG_ENABLED = false
end
WaypointOpt = false

local localeIndex = {
    ['en-US'] = 1,
    ['fr-FR'] = 2,
    ['de-De'] = 3
}

---@diagnostic disable-next-line: lowercase-global
projector = Projector()
projector.setSmooth(smooth)

local waypointObjectGroup = ObjectGroup()
projector.addObjectGroup(waypointObjectGroup)

local css = [[
svg {
    stroke-width: 3;
    vertical-align:middle;
    text-anchor:start;
    fill: white;
    font-family: Refrigerator;
    font-size: ]] .. fontsize .. [[;
}]]
waypointObjectGroup.setStyle(css)

if not highPerformanceMode and glowRadius > 0 then
    waypointObjectGroup.setGlow(true, glowRadius, true)
end

projector.setLowLatency(lowLatencyMode == true)
local function drawText(content,x, y, text, opacity,uD,c,c2,stroke)
    uD[c],uD[c+1],uD[c+2],uD[c+3],uD[c+4],uD[c+5] = x,y,opacity,opacity,stroke,text
    --content[c2] = '<text x="%g" y="%g" fill-opacity="%g" stroke-opacity="%g" stroke="%s">%s</text>'
    content[c2] = '<text x="%.1f" y="%.1f" fill-opacity="%.1f" stroke-opacity="%.1f" stroke="%s">%s</text>'
    return c+6,c2+1
end

local function drawHorizontalLine(content,x, y, length, thickness,dU,c,c2,stroke)
    dU[c],dU[c+1],dU[c+2],dU[c+3],dU[c+4]=thickness,stroke,x,y,length
    content[c2] = '<path fill="none" stroke-width="%.1f" stroke="%s" d="M%.1f %.1fh%.1f"/>'
    return c+5,c2+1
end

local maxD = sqrt(width*width + height*height)
local function drawInfo(content,tx,ty,data,dU,c,c1,stroke,distanceToMouse,wpInfo)
    local font = fontsize
    local name,distance,warpCost,disKM,disM = unpack(wpInfo)
    local keyframe = data.keyframe
    c,c1 = drawHorizontalLine(content, tx, ty + 3, len(name)*(font*0.6), 2,dU,c,c1,stroke)
    c,c1 = drawText(content, tx, ty, name, 1,dU,c,c1,stroke)
    if distanceToMouse <= infoHighlight then
        if keyframe < 6 then
            data.keyframe = keyframe + 1
        end
    else
        if keyframe ~= 0 then
            data.keyframe = keyframe - 1
        end
    end
    local opacity = keyframe/6
    if WaypointOpt and distanceToMouse < 15 then
        system.setWaypoint('::pos{0,0,' .. data.x ..',' .. data.y .. ',' .. data.z ..'}')
        WaypointOpt = false
    end
    if keyframe > 0 then
        disM = disM or 0
        disKM = disKM or 0
        distance = distance or 0
        local disText = ''
        if disM <= 2000 then
            disText = disM .. ' m'
        elseif disKM <= 200 then
            disText = disKM .. ' km'
        else
            disText = distance .. ' SU'
        end
        local f5 = font + 5
        local kf = keyframe * 10
        local tx2 = tx + 80
        c,c1 = drawText(content, tx2 - kf, ty+f5, disText, opacity,dU,c,c1,stroke)
        if displayWarpCells and distance > 2 then
            c,c1 = drawText(content, tx2 - kf, ty+f5*2, data.localeType, opacity,dU,c,c1,stroke)
            c,c1 = drawText(content, tx2 - kf, ty+f5*3, warpCost .. ' Warp Cells', opacity,dU,c,c1,stroke)
        elseif data.type == 'WP' then
            c,c1 = drawText(content, tx2 - kf, ty+f5*2, 'Alt: '..data.subId, opacity,dU,c,c1,stroke)
        else
            c,c1 = drawText(content, tx2 - kf, ty+f5*2, data.localeType, opacity,dU,c,c1,stroke)
        end
    end
    return c
end

local function draw(tx,ty,tz,data)
    local dU, c = {},1
    local content,c1 = {},1
    local distanceToMouse = sqrt(tx*tx + ty*ty)
    local r = data.radius
    local off = (((tz/1000)/200))/100
    --local size = Round(max(projector.getSize(r, tz, 100000000, minWaypointSize) - off, 5), 1)
    local size = max(projector.getSize(r, tz, 100000000, minWaypointSize) - off, 5)
    local wpInfo = data.getWaypointInfo()
    local distance,disM = wpInfo[2],wpInfo[5]
    size = uclamp(size, minWaypointSize, maxWaypointSize)
    if data.type == 'Planet' or data.type == 'WP' then
        if (disM < 2) or (distanceToMouse > maxD) or --or (tz < 30) or (size >= maxWaypointSize)
           (data.type == 'WP' and tz>archHudWPRender*1000) then -- Don't display
          return ''
        end
    elseif data.type == 'Moon' then
        if distance > 20 then return '' end
    else
        if distance > 10 then return '' end
    end

    local stroke = colorWarp
    if data.type == 'WP' then
        stroke = colorWaypoint
    elseif distance > 500 then
        stroke = nonWarp
    end
    --content[c1] = '<circle cx="%g" cy="%g" r="%g" fill="%s" stroke="%s"/>'
    content[c1] = '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" stroke="%s"/>'
    dU[c],dU[c+1] = tx,ty
    c=c+2
    if r==archHudWaypointSize*1.25 then
        size = size /2
        dU[c+1] = colorWarp
    else
        dU[c+1] = 'none'
    end
    dU[c] = size
    dU[c+2] = stroke
    c=c+3
    c=drawInfo(content, tx + size + 5, ty - size + 5, data,dU,c,c1+1,stroke,distanceToMouse,wpInfo)
    return concat(content):format(unpack(dU))
end

local solarWaypoints = objectBuilder
		.setPositionType(positionTypes.globalP)
		.setOrientationType(orientationTypes.globalO)
		.build()

waypointObjectGroup.addObject(solarWaypoints)
local builder = solarWaypoints.getSinglePointBuilder()
if displaySolarWP then
    ---@diagnostic disable-next-line: missing-parameter
    local localizationIndex = localeIndex[system.getLocale()]
    for k,stellar in pairs(WaypointInfo[0]) do
        local wCenter = stellar.center
        local wName = stellar.name[localizationIndex]
        local wRadius = stellar.radius
        local wType = stellar.type[1]
        if wType ~= "Asteroid" then
            local wlType = stellar.type[localizationIndex]
            local waypointObject = WPointer(wCenter[1],wCenter[2],wCenter[3],
                    wRadius * 1.25, wName, wType, wlType, nil)
            local customSVG = builder.addSinglePointSVG()
            customSVG.setPosition(wCenter[1], wCenter[2], wCenter[3])
                .setData(waypointObject)
                .setDrawFunction(draw)
                .build()
            P("[WPointer] Added "..wName)
        end
    end
end

-- tobitege: draw custom waypoints if enabled
if displayCustomWP and WM then
    for _,p in ipairs(WM:getSorted()) do
        local subId = format("%.2f", p.mapPos.altitude)
        local s = PM.MapPos2String(p.mapPos)
        local wPos = PM.MapPosToWorldVec3(s);
        if wPos then
            local waypointObject = WPointer(wPos.x, wPos.y, wPos.z,
                    archHudWaypointSize * 1.25, p.name, 'WP', 'WP', subId)
            local customSVG = builder.addSinglePointSVG()
            customSVG.setPosition(wPos.x, wPos.y, wPos.z)
                .setData(waypointObject)
                .setDrawFunction(draw)
                .build()
            P("[WPointer] Added "..p.name.."\r\n"..s)
        else
            P("[E] "..p.name.."\r\n"..s)
        end
    end
end