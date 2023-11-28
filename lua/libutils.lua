--P("library_s01.lua start")

local tonum, strmatch = tonumber, string.match

function IsTable(obj)
    return obj ~= nil and type(obj) == "table"
end

function GetSortedAssocKeys(source)
    local L = {}
    if not IsTable(source) then E("[E] Invalid object for GetSortedKeys()!") return L end
    for k,_ in pairs(source) do
        table.insert(L, k)
    end
    table.sort(L)
    return L
end

function Round(num, decimals)
    local mult = 10^(decimals or 0)
    return ((num*mult) + (2^52 + 2^51) - (2^52 + 2^51))/mult
end

function TableLen(source)
    if not IsTable(source) then return 0 end
    local cnt = 0
    for _ in pairs(source) do
      cnt = cnt + 1
    end
    return cnt
end

function GetIndex(source, value)
    if not IsTable(source) then return -1 end
    for k, v in pairs(source) do
      if value == v then return k end
    end
    return -1
end

---@param srcTable any
---@param paramName string
---@param reqType string|nil
---@param reqMsg boolean|nil
---@return any
function GetParamValue(srcTable, paramName, reqType, reqMsg)
    local err = "[E] Parameter value missing for "..paramName
    if srcTable == nil or not IsTable(srcTable) then
        if reqMsg == true then P(err) end
        return nil
    end
    for k, v in ipairs(srcTable) do
        if v == paramName then
            local idx = k + 1
            if #srcTable < idx then
                if reqMsg == true then P(err) end
                return nil
            end
            local val = srcTable[idx]
            if not reqType or reqType == "string" or reqType == "s" then
                if val == '""' or val == "''" then return nil end
                return val
            elseif ((reqType == "int" or reqType == "i") and not strmatch(val, "%D")) then
                return tonum(val)
            elseif reqType == "number" or reqType == "n" then
                return tonum(val)
            elseif reqType == "bool" or reqType == "b" then
                if val then return true else return false end
            end
            return nil
        end
    end
    if reqMsg == true then E(err) end
    return nil
end

function PairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0 -- iterator variable
    local iter = function () -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function BoolState(bool)
    if bool then
        return "enabled"
    else
        return "disabled"
    end
end

function BoolStr(b)
    if b == true then
        return "true"
    else
        return "false"
    end
end

function ScreenOutput(output, chatFooter)
    local chat = "Point at screen, CTRL+L, then copy text!"
    if #Config.screens >  0 then
        -- local pre = "local rslib = require('rslib')\n"..
        -- "local text = [["..output.."]]\n"..
        -- "local config = { fontSize = 20 }\n"..
        -- "rslib.drawQuickText(text, config)\n"
        local font = OutputFont or "FiraMono"
        local pre = "local text = [[\n"..output.."\n]]\n"..
[[
local rslib = require('rslib')
local layer = createLayer()
local rx, ry = getResolution()
local fontSize = 15
local font = loadFont("]]..font..[[", fontSize)
local line = 1
for str in text:gmatch("([^\n]+)") do
    addText(layer, font, str, 20, line*(fontSize+4))
    line = line + 1
end ]]
--setNextFillColor(layer, 1, 0, 0, 1)
--addBox(layer, rx/4, ry/4, rx/2, ry/2)
--addText(layer, font, text, rx/1, ry/1)
        --Config.screens[1].setHTML(pre)
        Config.screens[1].setRenderScript(pre)
        if chatFooter and chatFooter:len() then
            chat = chatFooter.."\n"..chat
        end
    else
        chat = "Hint: link a screen to PB to easily copy text from it!"
    end
    P(chat)
    return true
end

--P("library_s01.lua end")