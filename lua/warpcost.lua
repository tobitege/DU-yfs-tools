-- requires SU, PM
local strmatch, sformat, strlen = string.match, string.format, string.len
local tonum, uclamp, mabs, max, floor, ceil = tonumber, utils.clamp, math.abs, math.max, math.floor, math.ceil
---@if COMMENTS true
-- /warpCost -to Alioth -mass 1080
-- /warpCost -from Teoma -mass 1080
-- /warpCost -from Madis -to Alioth -mass 1080
-- /warpCost -from Teoma -to planets -mass 1080
-- /warpCost -to planets -mass 1080
-- /warpCost -from planets -mass 1080
-- /warpCost -from Talemai -to Jago -mass 1080
-- /warpCost -to Jago -mass 1080
-- /warpCost -to ::pos{0,0,-54513.3696,218221.5643,34390.2197} -mass 2480
-- /warpCost -to planets -mass 3080 -cargo 500
---@end

---@comment Calculates # of warp cells for distance and mass
---@param text string List of space-separated params
function CalcWarpCost(text)
    local example = "\nExample 1:\n/warpCost -from Madis -to Alioth -mass 534"..
        "\nExample 2:\n/warpCost -from Alioth -to planets -moons"..
        "\nOptional '-from x' with x being either 'here', a planet name, ::pos{} or 'planets' (multi-result)."..
        "\nOptional '-to x' like -from, but for end location."..
        "\nOptional '-mass x' with x the total mass in tons. If not given, the current constructs' total mass is used."..
        "\nOptional '-cargo x' with x the cargo mass in tons. If specified, a cell count for a return trip is calculated, too."..
        "\nOptional '-moons' only together with 'planets' to also include moons in the list."..
        "\n- One of -from or -to can be left out, then the current construct's location (or planet) is used."..
        "\n- If construct is landed on a planet or moon, the Atlas specified warp altitude is the starting point."..
        "\n- Enclose names in single-quotes if they contain spaces!"
    local getCMass = construct.getMass
    local pOn, onPlanet = {}, false
    local s, s2 = "~~~ WARP CELL CALCULATOR ~~~", ""

    local function checkParam(args, pName, isFrom)
        local v, allPlanets, offs = {}, false, 0
        local par = GetParamValue(args, pName, "s")
        if not par or (par == "") or (par == "here") then
            v = PM.WorldPosVec3() -- current position
            if onPlanet and pOn then
                offs = 2 * pOn.radius
                par = pOn.name[1]
                v = vec3(pOn.center)
            else
                offs = 12 -- min. 12 km warp distance
                par = PM.Vec3ToPosString(v)
            end
        elseif par == "planets" then
            allPlanets = true
        elseif par > "" then
            if SU.StartsWith(par, "::pos{") then
                offs = 12 -- min. 12 km warp distance
                v = PM.MapPosToWorldVec3(par)
            else
                local p = PM.PlanetByName(par)
                if p then
                    offs = 2 * p.radius
                    v = vec3(p.center)
                end
            end
        end
        return { parm = par, v = v, isP = allPlanets, offset = offs }
    end

    local args = SU.SplitQuoted(text)
    if #args < 1 then return E("[E] Parameter(s) missing!"..example) end
    local pMoons = GetIndex(args, "-moons") > 0

    -- for current location, check if we are "on" a planet (within atmo-radius),
    -- and set an offset of 2*radius from center as "warp barrier"
    local offset = 0
    pOn = PM.GetClosestPlanet(PM.WorldPosVec3())
    if pOn then
        offset = 2 * pOn.radius -- warp exclusion distance from center
        onPlanet = PM.Altitude() < offset
        if onPlanet then
            s2 = "Current"
        else
            s2 = "Nearest"
        end
        s = s.."\n"..s2.." planet: "..pOn.name[1]
    else
        s = s.."\n[I] No planet nearby!"
    end

    ---@diagnostic disable-next-line: missing-parameter
    local maxMass = 50000
    ---@diagnostic disable-next-line: missing-parameter
    local tons = getCMass(CNID) / 1000 --in globals.lua!

    -- check -cargo param and value
    local pCargo, bCargo = 0, false
    if GetIndex(args, "-cargo") > 0 then
        local tmpCargo = GetParamValue(args, "-cargo", "n")
        tmpCargo = tmpCargo or 0
        if tmpCargo > 0 then
            pCargo = uclamp(tmpCargo, 0, maxMass)
            bCargo = pCargo > 0
        else
            return E(s.."\n[E] Invalid -cargo value, must be in range of 1-50000 tons!")
        end
    end

    local pMass = GetParamValue(args, "-mass", "n")
    s2 = "Mass: "
    if pMass then
        tons = tonum(pMass)
    else
        s2 = "Construct "..s2
    end
    s = s.."\n"..s2..Out.PrettyMass(tons*1000)
    if bCargo then
        s = s.."  ~*~  Cargo: "..Out.PrettyMass(pCargo*1000)
    end
    if tons < 100 then -- warp drive alone is 75 tons!
        return E(s.."\n[E] Impossibly low mass for a warp ship! ;)")
    elseif tons > maxMass then
        return E(s.."\n[E] I don't accept you're warping that heavy! ;)")
    end

    local locFrom = checkParam(args, "-from", true)
    if not locFrom.isP and not locFrom.v then
        return E(s.."\n[E] Invalid starting location!")
    end
    local locTo = checkParam(args, "-to", false)
    if not locTo.isP and not locTo.v then
        return E(s.."\n[E] Invalid end location!")
    end

    if locFrom.isP and locTo.isP then
        return E(s.."\n[E] Only one 'planets' option supported!")
    end
    if (locFrom.parm == locTo.parm) or (locFrom.v == locTo.v) then
        return E(s.."\n[E] Start and end locations must be different!")
    end

    local function process(from, to, distance, massT, cargo)
        local out = ""
        if from > "" then out = out .. from end
        if from > "" and to > "" then out = out .. " to " end
        if to > "" then out = out .. to end
        out = out.. " ("..Out.PrettyDistance(distance)..")"

        -- min 1 SU, max 500 SU (1 SU = 200000 m)
        if distance < 200000 then
            return out.." -> too short!"
        elseif distance > 100000000 then
            return out.." -> too far!"
        end
        local cnt = PM.ComputeCells(distance, massT)
        out = out.." = "..cnt.." cell" .. SU.If(cnt > 1, "s")
        if bCargo then
            local cnt2 = PM.ComputeCells(distance, massT - cargo)
            out = out.." / "..cnt2.." cell" .. SU.If(cnt > 1, "s").." = "..(cnt+cnt2).." total"
        end
        return out
    end

    -- Single source and destination
    if not locFrom.isP and not locTo.isP then
        local distance = mabs(vec3(locFrom.v - locTo.v):len()) - locFrom.offset - locTo.offset
        local res = process(locFrom.parm, locTo.parm, distance, tons, pCargo)
        if type(res) == "string" then
            s = s .. "\n" .. res
            P(s)
            ScreenOutput(s)
        else
            E("[E] Sorry, something went wrong :(")
        end
        return
    end

    -- Planets processing
    local v1, v2 = nil, nil
    s2 = " (Distance) / Cells"..SU.If(bCargo, " / Return w/o cargo")
    if locFrom.isP then
        s = s.."\nTo: "..locTo.parm.."\nFrom"..s2
    else
        s = s.."\nFrom: "..locFrom.parm.."\nTo"..s2
    end
    for _,v in pairs(WaypointInfo[0]) do
        if not v.isAsteroid and (pMoons or not v.isMoon) then
            offset = 2 * v.radius
            if locFrom.isP then
                locFrom.parm = v.name[1]
                locFrom.v = vec3(v.center)
                offset = offset + locTo.offset
            else
                locTo.parm = v.name[1]
                locTo.v = vec3(v.center)
                offset = offset + locFrom.offset
            end
            local distance = mabs(vec3(locFrom.v - locTo.v):len()) - offset
            if distance > 100000 then
                s = s .. "\n" ..
                    process(SU.If(locFrom.isP, locFrom.parm),
                            SU.If(locTo.isP, locTo.parm),
                            distance, tons, pCargo)
            end
        end
    end
    P(s)
    ScreenOutput(s)
end
