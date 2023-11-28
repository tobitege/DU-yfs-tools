-- dummy "slot" mock
-- based on DuMocks' classes

local Slot = { 
    elementClass = "",
    widgetType = "",
    export = {},
    slotname = ""
}

function Slot:new(o, localId, elementDefinition)
    o = o or {
        widgetShown = true,
        mass = 0, -- kg
        maxHitPoints = 100,
        hitPoints = 100
    }
    setmetatable(o, self)
    self.__index = self

    o.localId = localId or 0
    o.name = ""

    if elementDefinition then
        o.elementClass = elementDefinition.elementClass
        o.slotname = elementDefinition.name
        o.itemId = elementDefinition.itemId or 0
    end
    o.loaded = 1
    return o
end

--- Returns 1 if element is loaded and 0 otherwise. Elements may unload if the player gets too far away from them, at
-- which point calls to their api will stop responding as expected. This state can only be recovered from by restarting
-- the script.
-- @treturn 0/1 The element load state.
function Slot:load()
    return self.loaded
end

--- The class of the element.
-- @treturn string The class name of the element.
function Slot:getClass()
    return self.elementClass
end

--- Hide the element's widget in the in-game widget stack.
function Slot:hideWidget()
    self.widgetShown = false
end

--- Mock only, not in-game: Bundles the object into a closure so functions can be called with "." instead of ":".
-- @treturn table A table encompasing the api calls of object.
function Slot:mockGetClosure()
    local closure = {}
    closure.export = {}
    closure.hideWidget = function() return self:hideWidget() end
    closure.getClass = function() return self:getClass() end
    closure.load = function() return self:load() end
    return closure
end

return Slot