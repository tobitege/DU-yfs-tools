-- Feed waypoints to script based on "userclass.lua" by Wolf Labs (@wolfe_br)
-- tobitege: customisations to only run AR waypointing (outside of ArchHud)

local enableWaypointer = true --export: Enable waypoint AR display. Default: checked.
local wpRenderLimit = 5 --export: The number of kilometers above which distance waypoints are not rendered; 0 means display all

if not enableWaypointer then
    WP_WOLF_ENABLED = false
    return
end

if WM and WolfAR then
    WolfAR.setRenderLimit(wpRenderLimit)
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