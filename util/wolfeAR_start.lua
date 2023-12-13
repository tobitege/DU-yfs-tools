-- Feed waypoints to script based on "userclass.lua" by Wolf Labs (@wolfe_br)
-- tobitege: customisations to only run AR waypointing (outside of ArchHud)

local uclamp = utils.clamp

local enableWaypointer = true --export: Enable waypoint AR display. Default: checked.
--local wpRenderLimit = 3 --export: The number of kilometers above which distance waypoints are not rendered; 0 means display all
--wpRenderLimit = uclamp(wpRenderLimit, 0, 1000000) -- max 500 SU

if not enableWaypointer then
    WP_WOLF_ENABLED = false
    return
end

if WM and WolfAR then
    for _,p in ipairs(WM:getSorted()) do
        local s = PM.MapPos2String(p.mapPos)
        local wPos = PM.MapPosToWorldVec3(s);
        if s and wPos then
            WolfAR.AddWaypoint(p.name, wPos)
            P("[WPointer] Added "..p.name.."\r\n"..s)
        else
            P("[E] "..p.name.."\r\n"..(s or "(none)"))
        end
    end
end