-- dummy "unit" file

-- Prep 3 mock slots for below "unit"
-- Credits to https://github.com/1337joe/du-mocks
Databank = require "dumocks.DatabankUnit"
Screen = require "dumocks.ScreenUnit"

-- "core" slot mock
local slotMock = Slot:new(nil, 1, { elementClass = "CoreUnit", name = "core" })
local u_core = slotMock:mockGetClosure()
u_core.export =  {}

-- "databank" slot mock
slotMock = Databank:new(nil, 2, "databank")
slotMock.name = "databank"
local u_databank = slotMock:mockGetClosure()
u_databank.export =  {}

-- "screen" slot mock
slotMock = Screen:new(nil, 3, "screen xs")
slotMock.name = "screen"
local u_screen = slotMock:mockGetClosure()
u_screen.export =  {}

-- "unit" mock object
local u = { core = u_core, databank = u_databank, screen = u_screen }

function u.exit() end
function u.hideWidget() end
function u.onEvent(a, b) end
function u.setTimer(s, n) end

return u