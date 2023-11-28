local tonum, strlen, strmatch = tonumber, string.len, string.match

---@comment Simple Waypoint class to store a name with a location.
--- No location conversions or changes are done in this class!
--- The set method is flexible, though, in what it accepts as source for a location.
--- @class Waypoint
Waypoint = { mapPos = {}, name = "", parent = nil }

-- Waypoint methods
Waypoint.new = function(parent)
    local obj = setmetatable(
        { parent = parent, name = "",
          mapPos = { systemId = 0, planetId = 0, latitude = 0.0, longitude = 0.0, altitude = 0.0 } },
        { __index = Waypoint }
    )
    return obj
end

---@comment Returns the waypoint as { systemId, planetId, latitude, longitude, altitude }
---@return table
Waypoint.get = function(self)
    return self.mapPos
end

Waypoint.getPosPattern = function()
    local num = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
    return '::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' .. num ..  ',' .. num .. '}'
end

---@comment Sets a waypoint to the given map position (::pos{}, vec3 or table with 3 or 5 pos data)
Waypoint.set = function(self, newMapPos)
    if type(newMapPos) == "string" and strlen(newMapPos) < 16 then
        print("[E] Invalid position: "..newMapPos)
        return {}
    end

    if type(newMapPos) == "string" then
        local s, p, x, y, z = strmatch(newMapPos, self.getPosPattern())
        if s then
            self.mapPos.systemId = tonum(s)
            self.mapPos.planetId = tonum(p)
            self.mapPos.latitude = tonum(x)
            self.mapPos.longitude = tonum(y)
            self.mapPos.altitude = tonum(z)
        else
            print(newMapPos.." - Invalid string format. Use '::pos{s, p, x, y, z}'.")
        end
    elseif type(newMapPos) == "table" and #newMapPos == 3 then
        self.mapPos.latitude = tonum(newMapPos[1])
        self.mapPos.longitude = tonum(newMapPos[2])
        self.mapPos.altitude = tonum(newMapPos[3])
    elseif type(newMapPos) == "table" and #newMapPos == 5 then
        self.mapPos.systemId = tonum(newMapPos[1])
        self.mapPos.planetId = tonum(newMapPos[2])
        self.mapPos.latitude = tonum(newMapPos[3])
        self.mapPos.longitude = tonum(newMapPos[4])
        self.mapPos.altitude = tonum(newMapPos[5])
    elseif type(newMapPos) == "table" and newMapPos.x and newMapPos.y and newMapPos.z then
        self.mapPos.systemId = 0
        self.mapPos.planetId = 0
        self.mapPos.latitude = tonum(newMapPos.x)
        self.mapPos.longitude = tonum(newMapPos.y)
        self.mapPos.altitude = tonum(newMapPos.z)
    else
        print("Invalid input. Provide a ::pos{} string, vec3() or {s,p,x,y,z} table.")
    end
    return self
end

---@comment Set the name for the waypoint. Can be empty.
---@param self table
Waypoint.setName = function(self, newName)
    if newName == nil then self.name = "" return end
    if type(newName) == "string" and newName:gmatch("^%a[%w_- ]*$") then
        self.name = newName
    else
        print(tostring(newName).."\n[E] WP: Invalid name format. Should only contain printable characters.")
    end
    return self
end

---@comment Returns the name for the waypoint. Can be empty.
Waypoint.getName = function(self)
    return self.name
end

---@comment Returns just the altitude value (number).
Waypoint.getAltitude = function(self)
    return self.mapPos.altitude
end

---@comments Returns ::pos{} string of the waypoint
---@return string
Waypoint.AsString = function(self)
    return string.format("::pos{%d, %d, %.4f, %.4f, %.4f}",
                         self.mapPos.systemId, self.mapPos.planetId,
                         self.mapPos.latitude, self.mapPos.longitude, self.mapPos.altitude)
end

Waypoint.__Waypoint = function(self) return true end