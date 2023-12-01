package.path = "lua/?.lua;util/wpointer/?.lua;"..package.path
require('globals')

-- trick to make it right in debugger ;)
---@if with_waypointer false
WAYPOINTER_ENABLED = false
---@else
WAYPOINTER_ENABLED = true
---@end
---@if debug
DEBUG = true
---@end
require('libmain')

if INGAME then
    local Traceback = traceback
else
    function Traceback(o)
        if o then P(tostring(o)) end
    end
    require 'mockaround'
end

local status, err, _ = xpcall(function() require('startup') end, Traceback)
if not status then
    P("Error in startup!")
    if err then P(err) end
    unit.exit()
    return
end

local inp = require('sys_onInputText')
if inp ~= nil then
    system:onEvent('onInputText', function (self, text) inp.Run(text) end)
end

-- *****************************************
---@if with_waypointer true
-- Only for waypointer mod
local onT
if WAYPOINTER_ENABLED then
    require('waypointer_lib')
    local asWP = require('sys_onActionStartWp')
    if asWP ~= nil then
        system:onEvent('onActionStart', function (self, option) asWP.Run(option) end)
    end

    onT = require('unit_onTimer(update)')
    if onT ~= nil then
        unit:onEvent('onTimer', function (unit, id) onT.Run("update") end)
    end

    P('[I] Waypointer module enabled.')
    require('waypointer_start')
    ---@diagnostic disable-next-line: lowercase-global
    rot = 0 -- for wpointer0

    unit.setTimer("update", 1/240) -- The timer to update the screen
    ---@diagnostic disable-next-line: param-type-mismatch
    system.showScreen(1)
end
---@end
-- *****************************************

if INGAME then
    if DEBUGx then
        status, err, _ = xpcall(function() PM.ConversionTest() end, Traceback)
        if not status then
            if err then P("Error in call:\n" .. err) end
            unit.exit()
            return
        end
    else
        unit.hideWidget()
    end
    P("Type /help for available commands.")
    if #Config.screens > 0 then
        P(Config.screens[1].getScreenWidth().."/"..Config.screens[1].getScreenHeight())
    end
---@if debug
else
    -- outside of DU, e.g. in VSCode debugging, emulate a simple LUA chat prompt
    -- and send all user input to our OnInputText event
    repeat
        if onT then onT.Run("update") end
        io.write("["..system.getArkTime()..'] > ')
        local chat = io.read()
        P("[IN] "..chat)
        if inp and inp.Run then inp.Run(chat) end
    until not inp or (chat and chat == "q")
---@end
end