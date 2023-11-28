package.path = "lua/?.lua;util/wpointer/?.lua;"..package.path
require('globals')

---@if with_waypointer
WAYPOINTER_ENABLED = true
---@end
---@if debug
DEBUG = true
---@end
require('libmain')

---@if STRICT true
-- local strictness = require("strictness")
-- local t = strictness.strict()
-- Out.DeepPrint(strictness)
-- Out.DeepPrint(t)
---@end

--local XPCall = {}
--XPCall.__index = XPCall
--XPCall.Call = function(entryName, f, ...)
--end
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

local inp = require('sys_OnInputText')
if inp ~= nil then
    system:onEvent('onInputText', function (self, text) inp.Run(text) end)
end

-- *****************************************
---@if with_waypointer true
-- Only for waypointer mod
if WAYPOINTER_ENABLED then
    require('waypointer_lib')
    local asWP = require('sys_onActionStartWp')
    if asWP ~= nil then
        system:onEvent('onActionStart', function (self, option) asWP.Run(option) end)
    end

    local onT = require('unit_onTimer(update)')
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
    if DEBUG then
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
else
    -- outside of DU, e.g. in VSCode debugging, emulate a simple LUA chat prompt
    -- and send all user input to our OnInputText event
    repeat
        io.write('>> ')
        local chat = io.read()
        P("[Input] "..chat)
        if inp and inp.Run then inp.Run(chat) end
    until not inp or not chat or chat:len() == 0
end