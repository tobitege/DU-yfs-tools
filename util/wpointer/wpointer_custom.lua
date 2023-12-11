function WPointer(x,y,z, radius, name, type, localeType, subId)
    local sqrt,floor,max,round=math.sqrt,math.floor,math.max,Round
    local getCWorldPos,getCMass = construct.getWorldPosition,construct.getMass

    local keyframe = 0
    local self = {
        radius = radius,
        x = x,
        y = y,
        z = z,
        name = name,
        type = type,
        localeType = localeType,
        subId = subId,
        keyframe = keyframe
    }

    function self.getWaypointInfo()
        ---@diagnostic disable-next-line: missing-parameter
        local cid = CNID --in globals.lua!
        local cPos = getCWorldPos(cid)
        ---@diagnostic disable-next-line: need-check-nil
        local px,py,pz = self.x-cPos[1], self.y-cPos[2], self.z-cPos[3]
        local distance = sqrt(px*px + py*py + pz*pz)
        local warpCost = 0
        -- min 2 SU, max 500 SU (1 SU = 200000 m)
        local disR = round(distance, 1)
        if disR > 400000 and disR <= 100000000 then
            local tons = getCMass(cid) / 1000
            warpCost = max(floor(tons*floor(((disR/1000)/200))*0.00024), 1)
        end
        return {self.name, round((disR/1000)/200, 1), warpCost, round((disR/1000), 1), disR}
    end

    return self
end