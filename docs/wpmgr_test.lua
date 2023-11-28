--[[-----
require('wpmgr')

-- Example Usage:
-- Create an instance of WaypointMgr with a specific name
local WpMgr = WaypointMgr:new("CustomWaypointMgrName")

-- Add waypoints by name
local waypoint1 = WpMgr:add(Waypoint:new(WpMgr):setName("Waypoint1"))
local waypoint2 = WpMgr:add(Waypoint:new(WpMgr):setName("Waypoint2"))
local waypoint3 = WpMgr:add(Waypoint:new(WpMgr):setName("Waypoint3"))

-- Check if waypoints exist by name, object, and nums
local existingByName = WpMgr:exists("Waypoint2")
local existingByObject = WpMgr:exists(waypoint3)
local existingByNums = WpMgr:exists{1, 2, 0.5, 0.8, 100}

-- Print the existing waypoints
print("Existing Waypoints:")
print(existingByName)
print(existingByObject)
print(existingByNums)

-- Get and print sorted waypoints
local sortedWaypoints = WpMgr:getSorted()
print("Sorted Waypoints:")
for k, v in pairs(sortedWaypoints) do
    print(k, v.name)
end

-- Define WaypointChildMgr class
local WaypointChildMgr = {
    -- additional properties or methods specific to WaypointChildMgr
}

-- Set the metatable to delegate to WaypointMgr
local WaypointChildMgrMetatable = { __index = WaypointMgr }
setmetatable(WaypointChildMgr, WaypointChildMgrMetatable)

-- WaypointChildMgr constructor
WaypointChildMgr.New = function(name)
    local obj = setmetatable(
        { waypoints = {}, name = name or "DefaultWaypointChildMgrName" },
        WaypointChildMgrMetatable -- Use the metatable defined outside the New function
    )
    return obj
end

-- Additional methods or properties specific to WaypointChildMgr
WaypointChildMgr.additionalMethod = function(self)
    print("This is a method from WaypointChildMgr.")
end

-- Example Usage:
local childMgr = WaypointChildMgr:New("ChildWaypointMgr")
childMgr:add(Waypoint:new(childMgr):setName("ChildWaypoint1"))

-- Access methods from WaypointMgr and WaypointChildMgr
childMgr:add(Waypoint:new(childMgr):setName("ChildWaypoint2"))
childMgr:additionalMethod()
-----]]