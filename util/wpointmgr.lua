local tonum, strlen, strmatch = tonumber, string.len, string.match

---@if COMMENTS true
--- **************************************************************
--- ****************** Define WaypointMgr class ******************
--- **************************************************************
---@end
---@class WaypointMgr
WaypointMgr = { name = "", waypoints = {} }

--- comment Add a waypoint object to the list at position 'index'
--- @param self table
--- @param waypoint any
--- @param index any
--- @return nil
WaypointMgr.add = function(self, waypoint, index)
    if waypoint.__Waypoint and waypoint.__Waypoint() then
        -- If the waypoint has no name, skip duplicate check
        if waypoint.name and waypoint.name ~= "" then
            -- Check if a waypoint with the same name already exists
            for _,v in ipairs(self.waypoints) do
                if v.name == waypoint.name then
                    return nil
                end
            end
        end
        local wplus1 = 1 + #self.waypoints
        if index then
            -- Check if the specified index is within the valid range
            if index < 1 or index > wplus1 then
                print("[E] Invalid index. Must be in the range 1 to " .. wplus1)
                return nil
            end
            waypoint.parent = self
            table.insert(self.waypoints, index, waypoint)
        else
            waypoint.parent = self
            table.insert(self.waypoints, wplus1, waypoint)
        end
        return waypoint
    else
        print("[E] Invalid waypoint parameter!")
        return nil
    end
end

---@comment List of waypoints' data as table.
---@return table (systemId, planetId, latitude, longitude, altitude)
WaypointMgr.getWaypointsData = function(self)
    local res = {}
    for k,v in ipairs(self.waypoints) do
        table.insert(res, k, v:get())
    end
    return res
end

---@comment List of all waypoints as Waypoint objects.
---@return table Array of all Waypoint instances
WaypointMgr.getWaypointsInst = function(self)
    return self.waypoints
end

---@comment Returns the count of all waypoints
---@return integer Count of all waypoints
WaypointMgr.getCount = function(self)
    return #self.waypoints
end

---@comment Returns array of all waypoint instances sorted by their name
---@return table Array
WaypointMgr.getSorted = function(self)
    local sortedPoints = {}

    -- Copy waypoints to a new table for sorting
    for _,v in pairs(self.waypoints) do
        table.insert(sortedPoints, v)
    end

    -- Sort the copied table by waypoint names
    table.sort(sortedPoints, function(a, b)
        return a.name < b.name
    end)
    return sortedPoints
end

---@comment Moves waypoint at given index up by one, but 1 as minimum
WaypointMgr.moveUp = function(self, index)
    local waypointsCount = #self.waypoints

    if index and index > 1 and index <= waypointsCount then
        self.waypoints[index], self.waypoints[index - 1] = self.waypoints[index - 1], self.waypoints[index]
    end
end

---@comment Moves waypoint at given index down by one, but to end index as maximum
WaypointMgr.moveDown = function(self, index)
    local waypointsCount = #self.waypoints

    if index and index >= 1 and index < waypointsCount then
        self.waypoints[index], self.waypoints[index + 1] = self.waypoints[index + 1], self.waypoints[index]
    end
end

---@comment Removes only the first waypoint with the given name and returns that waypoint instance, otherwise nil
---@return any Either removed waypoint instance or nil if not found
WaypointMgr.removeByName = function(self, waypointName)
    for i, waypoint in ipairs(self.waypoints) do
        if waypoint.name == waypointName then
            local removedWaypoint = table.remove(self.waypoints, i)
            return removedWaypoint  -- Return the removed waypoint
        end
    end
    return nil  -- Return nil if not found
end

---@comment Returns true if at least one waypoint exist, else false
---@return boolean
WaypointMgr.hasPoints = function(self, param)
    return #self.waypoints > 0
end

---@comment Checks if a waypoint exists in 3 different ways: name, waypoint instance or same data
---@return any If not found, returns nil, otherwise the found waypoint instance
WaypointMgr.exists = function(self, param)
    for _, v in ipairs(self.waypoints) do
        if type(param) == "string" and v.name == param then
            return v
        elseif param and param.__Waypoint and Waypoint.__Waypoint() then
            if v == param then
                return v
            end
        elseif type(param) == "table" and #param == 5 then
            -- Check if a waypoint with the same nums exists
            if v.mapPos.systemId  == tonum(param[1]) and
               v.mapPos.id        == tonum(param[2]) and
               v.mapPos.latitude  == tonum(param[3]) and
               v.mapPos.longitude == tonum(param[4]) and
               v.mapPos.altitude  == tonum(param[5]) then
                return v
            end
        end
    end
    return nil
end

WaypointMgr.getName = function(self)
    return self.name
end

WaypointMgr.new = function(name)
    local obj = setmetatable(
        { waypoints = {}, name = name or "" },
        { __index = WaypointMgr }
    )
    return obj
end

return WaypointMgr
