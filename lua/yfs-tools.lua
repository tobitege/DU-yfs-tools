-- Important for local debugging:
package.path = "lua/?.lua;util/wpointer/?.lua;"..package.path
require('globals')

-- DU-LuaC checks for true are last, so that local debugging sees true!
---@if with_waypointer_eg false
WP_EG_ENABLED = false
---@else
--WP_EG_ENABLED = true
---@end

---@if with_waypointer_wl false
WP_WOLF_ENABLED = false
---@else
WP_WOLF_ENABLED = true
---@end

---@if debug false
DEBUG = false
---@else
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
    P("[E] Error in startup!")
    if err then P(err) end
    unit.exit()
    return
end

local inp = require('sys_onInputText')
if inp ~= nil then
    system:onEvent('onInputText', function (self, text) inp.Run(text) end)
end

---@if with_waypointer_eg true
-- EasternGamer's waypointer mod
-- *****************************************
if WP_WOLF_ENABLED then WP_EG_ENABLED = false end -- only enable one
---@diagnostic disable-next-line: lowercase-global
rot = 0 -- for waypointer
local onT

if WP_EG_ENABLED then
    require('waypointer_lib')
    if WP_EG_ENABLED then -- so check again if it is enabled
        local asWP = require('sys_onActionStartWp')
        if asWP ~= nil then
            system:onEvent('onActionStart', function (self, option) asWP.Run(option) end)
        end

        onT = require('unit_onTimer(update)_eg')
        if onT ~= nil then
            unit:onEvent('onTimer', function (unit, id) onT.Run("update") end)
        end
    end
end
---@end

---@if with_waypointer_wl true
-- Wolfe Labs' waypointer mod (customized)
-- *****************************************
if WP_WOLF_ENABLED and Config.core then
    WolfAR = require('wolfeARlib')
    require('wolfeAR_start')
    if WP_WOLF_ENABLED then
        WolfAR.setCore(Config.core)
        onT = require('unit_onTimer(update)_wolfeAR')
        if onT ~= nil then
            unit:onEvent('onTimer', function (unit, id) onT.Run("update") end)
        end
    end
end
-- *****************************************
---@end

if not WP_EG_ENABLED and not WP_WOLF_ENABLED then
    P('[I] Waypointer module disabled.')
else
    P('[I] Waypointer module enabled.')

    unit.setTimer("update", 1/120) -- The timer to update the screen
    system.showScreen(1)
end

if INGAME then
    if DEBUGx then
        status, err, _ = xpcall(function() PM.ConversionTest() end, Traceback)
        if not status then
            if err then P("[E] Error in test call:\n" .. err) end
            unit.exit()
            return
        end
    else
        unit.hideWidget()
    end
    P("Type /help for available commands.")
---@if debug
else
    -- outside of DU, e.g. in VSCode debugging, emulate a simple LUA chat prompt
    -- and send all user input to our OnInputText event
    repeat
        if onT then onT.Run("update") end -- call timer
        io.write("["..system.getArkTime()..'] > ')
        local chat = io.read()
        P("[IN] "..chat)
        if inp and inp.Run then inp.Run(chat) end
    until not inp or (chat and chat == "q")
---@end
end