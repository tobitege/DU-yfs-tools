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

-- Loop
--https://github.com/renatomaia/loop
--https://renatomaia.github.io/loop/manual/basics.html
--package.path = package.path .. ";util/loop/"..FSUFFIX
--oo = require "loop.base"

-- DuMocks
system = require("System")
core = require("CoreUnit")
construct = require("Construct")
library = require("Library")
constants = { deg2rad = 1 }
DUConstruct = construct
DUSystem = system

-- DU game file
json  = require("json")
utils = require("utils")
vec3  = require("vec3")

Slot = require("slot")

unit = require("unit")
unit.databank.setStringValue(YFS_NAMED_POINTS, json.encode({v = {}, t = "table"}))
unit.databank.setStringValue(YFS_ROUTES, json.encode({v = routes, t = "table"}))
