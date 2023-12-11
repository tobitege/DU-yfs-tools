print("*** MOCKING MODE ***")

FSUFFIX = "?.lua;"
DU_LUA_PATH = 'C:/DualUniverse/Game/data/lua/' -- <- adapt to your local path!!!
DU_CPML_PATH = 'cpml/'..FSUFFIX

package.path = "lua/"..FSUFFIX..";util/"..FSUFFIX .. package.path -- add src directory
package.path = package.path .. ";" .. DU_LUA_PATH .. FSUFFIX
package.path = package.path .. ";" .. DU_LUA_PATH .. DU_CPML_PATH
package.path = package.path .. ";./util/du-mocks/"..FSUFFIX
package.path = package.path .. ";./util/du-mocks/dumocks/"..FSUFFIX
package.path = package.path .. ";./util/du-mocks/game-data-lua" --..FSUFFIX

-- DuMocks (from https://github.com/1337joe/du-mocks)
system = require("System"):new():mockGetClosure()
core = require("CoreUnit"):new():mockGetClosure()
construct = require("Construct"):new():mockGetClosure()

constants = { deg2rad = 1 }
DUConstruct = construct
DUSystem = system

-- DU game files
json  = require("json")
utils = require("utils")
vec3  = require("vec3")

Slot = require("slot")

unit = require("unit")
unit.databank.setStringValue(YFS_NAMED_POINTS, json.encode({v = {}, t = "table"}))
unit.databank.setStringValue(YFS_ROUTES, json.encode({v = routes, t = "table"}))

local lib = require("Library"):new()

-- dummy data from DU-Mocks repo
local resultSequence = {}
resultSequence[1] = {1, 2}
resultSequence[2] = {2, 3}
table.insert(lib.systemResolution2Solutions, resultSequence[1])
table.insert(lib.systemResolution2Solutions, resultSequence[2])
resultSequence[1] = {1, 2, 3}
resultSequence[2] = {2, 3, 4}
table.insert(lib.systemResolution3Solutions, resultSequence[1])
table.insert(lib.systemResolution3Solutions, resultSequence[2])
resultSequence[1] = {0.5, 0.5, 0.5}
resultSequence[2] = {0.5, 0.5, 0.5}
table.insert(lib.getPointOnScreenSolutions, resultSequence[1])
table.insert(lib.getPointOnScreenSolutions, resultSequence[2])

library = lib:mockGetClosure()