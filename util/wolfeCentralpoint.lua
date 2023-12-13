-- Requires vec3
-- Author: Matt / Wolfe Labs (@wolf_br), commissioned by tobitege (@tobitege)

local msqrt = math.sqrt

---@comment Gets the central point for an ARRAY(!) of waypoints; nil if invalid params or empty array.
---@param waypoints table with array of waypoints
---@param useCentroid boolean|nil optional; default: nil (or false)
---@return vec3|nil The vec3 of the center location (or nil)
function GetCentralPoint(waypoints, useCentroid)
    if type(waypoints) ~= "table" or #waypoints == 0 then return nil end
    if #waypoints == 1 then
      -- If we only have a single point, return it
        return waypoints[1]
    elseif #waypoints == 2 then
        -- For two points, we only need an average, no problem either
        return (vec3(waypoints[1]) + vec3(waypoints[2])) / 2
    end

    -- Base weight for averaging
    local base_weight = 1 / #waypoints

    -- Calculates the centroid position
    local centroid = vec3(0, 0, 0)
    for _, waypoint in pairs(waypoints) do
        centroid = centroid + vec3(waypoint) * base_weight
    end

    -- Use the centroid as the center, unless the option says otherwise
    local center = centroid

    -- Note to self: in the lines below math.sqrt(2) has been used to improve the center location.
    -- This number seems to have worked best as an exponent for the distances, but I'm not sure why.
    -- This is probably worth investigating at some point.

    -- If we aren't using the centroid, we'll use it along with the distance of all other points to estimate a new center
    if not useCentroid then
        -- Calculates the average distances for the centroid
        local avg_distance = 0
        for _, waypoint in pairs(waypoints) do
            avg_distance = avg_distance + base_weight * (vec3(waypoint) - center):len() ^ msqrt(2)
        end

        -- Now we try to get closer to center
        local center_accumulator = vec3(0, 0, 0)
        for _, waypoint in pairs(waypoints) do
            local point = vec3(waypoint)
            local distance = (point - center):len() ^ msqrt(2)
            local weight = distance / avg_distance
            center_accumulator = center_accumulator + point * base_weight * weight
        end

        -- Sets new value for the center
        center = center_accumulator
    end

    return center
end