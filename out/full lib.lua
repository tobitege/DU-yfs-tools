package.preload['YFS-Tools:globals.lua']=(function()
-- Initialize globals and constants
Config = { core = nil, databanks = {}, screens = {} }
DetectedArch = 0
DetectedYFS = false
YFSDB = nil
YFS_NAMED_POINTS = "NamedPoints"
YFS_ROUTES = "NamedRoutes"
ARCH_SAVED_LOCATIONS = "SavedLocations"
DEBUG = true
Clicked = false -- for waypointer
WAYPOINTER_ENABLED = true

INGAME = system ~= nil

if not INGAME then

else
    print = system.print
end

WaypointInfo = require('atlas')
end)
package.preload['YFS-Tools:../util/SU.lua']=(function()
local SU = {}

local strmatch, strlen, tonum = string.match, string.len, tonumber

---@comment Returns s being trimmed of any whitespace from both start and end.
---@param s string
---@return string
function SU.Trim(s)
    if strlen(s) == 0 then return "" end
    return SU.Ltrim(SU.Rtrim(s))
end

---@comment Returns s being trimmed of any whitespace from the start.
---@param s string
---@return string
function SU.Ltrim(s)
    local res, _ = string.gsub(s, "^%s+", "")
    return res
end

---@comment Returns s being trimmed of any whitespace from the end.
---@param s string
---@return string
function SU.Rtrim(s)
    local res, _ = string.gsub(s, "%s+$", "")
    return res
end

function SU.Pad(s, padChar, length)
    if not s or not length or not padChar or tonum(length) < 1 then return s end
    return string.rep(padChar, length - s:len()) .. s
end

---@param s string
---@param prefix string
---@return boolean
function SU.StartsWith(s, prefix)
    if not s or not prefix then return false end
    return string.sub(s, 1, #prefix) == prefix
end

---@param s string
---@param suffix string
---@return boolean
function SU.EndsWith(s, suffix)
    if not s or not suffix then return false end
    return string.sub(s, -#suffix) == suffix
end

---@param s string
---@param suffix string
---@return string
function SU.RtrimChar(s,char)
    if not s or not char then return s end
    while #s > 0 and SU.EndsWith(s, char) do
        s = string.sub(s,1,#s - #char)
    end
    return s
end

---Splits the string into parts, honoring " and ' as quote chars to make multi-word arguments
-- SplitQuoted() credits to Yoarii (SVEA)
---@param s string
---@return string[]
function SU.SplitQuoted(s)
    local function isQuote(c) return c == '"' or c == "'" end
    local function isSpace(c) return c == " " end

    local function add(target, v)
        v = SU.Trim(v)
        if v:len() > 0 then
            table.insert(target, #target + 1, v)
        end
    end

    local inQuote = false
    local parts = {} ---@type string[]
    if type(s) ~= "string" or s == "" then
        return parts
    end

    local current = ""
    for c in string.gmatch(s, ".") do
        if isSpace(c) and not inQuote then
            -- End of non-quoted part
            add(parts, current)
            current = ""
        elseif isQuote(c) then
            if inQuote then -- End of quote
                add(parts, current)
                current = ""
                inQuote = false
            else -- End current, start quoted
                add(parts, current)
                current = ""
                inQuote = true
            end
        else
            current = current .. c
        end
    end

    -- Add whatever is at the end of the string.
    add(parts, current)

    return parts
end

---@comment Returns trueValue if cond is true, otherwise falseValue. nil's will be checked and returned as empty strings.
---@param cond boolean cond should evaluate to true or false
---@param trueValue any
---@param falseValue any
---@return string
function SU.If(cond, trueValue, falseValue)
    if cond then
        return tostring(trueValue or "")
    end
    return tostring(falseValue or "")
end

---@comment Returns true if char is a printable character
---@param char string single character
---@return boolean
function SU.isPrintable(char)
    return strmatch(char, "[%g%s]") ~= nil
end

---@comment Returns true if char is a printable character
---@return any Returns the ready string. In case of invalid separator, the original string is returned.
function SU.SplitAndCapitalize(inputString, delimiter)
    if not inputString or not SU.isPrintable(delimiter) then
        return inputString
    end
    local parts = {}
    for part in inputString:gmatch("[^" .. delimiter .. "]+") do
        table.insert(parts, part)
    end
    for i = 1, #parts do
        parts[i] = parts[i]:sub(1, 1):upper() .. parts[i]:sub(2)
    end
    return table.concat(parts)
end

return SU
end)
package.preload['YFS-Tools:../util/out.lua']=(function()
--- functions with chat output
local o = {}

function o.PrettyDistance(dist)
    if dist < 10000 then
        return Round(dist,2).." m"
    end
    if dist < 200000 then
        return Round(dist/1000,2).." km"
    end
    return Round(dist/200000,2).." SU"
end

---@param mass number mass in kg
---@return string prettyfied mass for display
function o.PrettyMass(mass)
    if mass > 1000000 then
        return Round(mass / 1000000,2).." KT"
    end
    if mass > 1000 then
        return Round(mass / 1000,2).." tons"
    end
    return Round(mass,2).." kg"
end

---@param s string|any
function o.PrintLines(s)
    if not s then return end
    if type(s) ~= "string" then s = tostring(s) end
    for str in s:gmatch("([^\n]+)") do
         print(str)
    end
end

function o.Error(err)
    o.PrintLines(err)
    return false
end

function o.DeepPrint(e, maxItems)
    if IsTable(e) then
        local cnt = 0
        maxItems = maxItems or 0
        for k,v in pairs(e) do
            if IsTable(v) then
                P("-> "..k)
                o.DeepPrint(v, maxItems)
            elseif type(v) == "boolean" then
                P(k..": "..BoolStr(v))
            elseif type(v) == "function" then
                P(k.."()")
            elseif v == nil then
                P(k.." ("..type(v)..")")
            else
                P(k..": "..tostring(v))
            end
            cnt = cnt + 1
            if maxItems > 0 and cnt >= maxItems then
               P("^:^:^:^: cutoff reached :^:^:^:^")
                return
            end
        end
    elseif type(e) == "boolean" then
       P(BoolStr(e))
    else
       P(e)
    end
end

function o.DumpVar(data)
    -- cache of tables already printed, to avoid infinite recursive loops
    local tablecache = {}
    local buffer = ""
    local padder = "    "
    local function _dumpvar(d, depth)
        local t = type(d)
        local str = tostring(d)
        if (t == "table") then
            if (tablecache[str]) then
                -- table already dumped before, so we dont
                -- dump it again, just mention it
                buffer = buffer.."<"..str..">\n"
            else
                tablecache[str] = (tablecache[str] or 0) + 1
                buffer = buffer.."("..str..") {\n"
                for k, v in pairs(d) do
                    buffer = buffer..string.rep(padder, depth+1).."["..k.."] => "
                    _dumpvar(v, depth+1)
                end
                buffer = buffer..string.rep(padder, depth).."}\n"
            end
        elseif (t == "boolean") then
            buffer = buffer.."("..BoolStr(t)..")\n"
        elseif (t == "number") then
            buffer = buffer.."("..t..") "..str.."\n"
        else
            buffer = buffer.."("..t..") \""..str.."\"\n"
        end
    end
    _dumpvar(data, 0)
    return buffer
end

return o
end)
package.preload['YFS-Tools:../util/Dtbk.lua']=(function()
-- Dtbk by Jeronimo
Dtbk = {}
Dtbk.__index = Dtbk;
function Dtbk.new(bank)
    local self = setmetatable({}, Dtbk)
    self.DB = bank
    self.concat = table.concat
    return self
end
function Dtbk.hasKey(self,tag)
    return self.DB.hasKey(tag)
end
function Dtbk.getString(self,tag)
    return self.DB.getStringValue(tag)
end
function Dtbk.setString(self,tag,value)
    self.DB.setStringValue(tag,value)
end
function Dtbk.setData(self,tag,value)
    local str = json.encode(value)
    self.DB.setStringValue(tag,str)
end
function Dtbk.getData(self,tag)
    local tmp = self.DB.getStringValue(tag)
    if tmp == nil then return nil end
    local str = json.decode(tmp)
    return str
end
function Dtbk.remove(self,key)
    self.DB.clearValue(key)
end
function Dtbk.ResetAll(self)
    self.DB.clear()
end

end)
package.preload['YFS-Tools:libutils.lua']=(function()
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
end)
package.preload['YFS-Tools:commands.lua']=(function()
--TODO: refactor commands to use WM instead of databank data
local cmd = {}

-- requires libutils, globals PM, SU, YFSDB etc.
-- WaypointInfo only used for WarpCostCmd()

local strmatch, sformat, strlen = string.match, string.format, string.len
local tonum, uclamp, mabs, max, floor, ceil = tonumber, utils.clamp, math.abs, math.max, math.floor, math.ceil

-- Local functions

---@comment Adds for each existing waypoint listed in "wpnames" an extra "Flight" waypoint
--- at the given altitude with the given name suffix.
--- Already existing waypoints with the suffix'ed name will have their altitude changed!
--- Returns a list of "connected" waypoints, e.g.
--- 1 landed -> 1 flight -> 2 flight -> 2 landed -> 2 flight -> 3 flight -> 3 landed  etc.
--- as 2nd result; 1st result is the updated full waypoints list.
---@param wpdata table
---@param wpnames table
---@param altitude number
---@param suffix string
local function yfsAddAltitudeWaypoints(wpdata, wpnames, altitude, suffix)
    local cnt = 0
    local names = {}
    local wpCnt = #wpnames
    for _,k in ipairs(wpnames) do
        local wp = wpdata.v[k]
        if wp ~= nil then
            cnt = cnt + 1
            local wpN = k .. suffix
            if cnt > 1 then table.insert(names, wpN) end
            table.insert(names, k)
            if cnt < wpCnt then table.insert(names, wpN) end
            local newPos = PM.ReplaceAltitudeInPos(wp.pos, altitude)
            if wpdata.v[wpN] ~= nil then
                wpdata.v[wpN].pos = newPos
            else
                wpdata.v[wpN] = { pos = newPos }
                P(wpN .."  " .. newPos)
            end
        end
    end
    if cnt == 0 then
        P("[E] No waypoints processed!")
        return nil,nil
    end
    P("[I] "..cnt.." waypoints at "..altitude.."m added (or changed)!")
    return wpdata, names
end

local function storeYFSData(keyName, data)
    if not DetectedYFS or not keyName then return false end
    YFSDB:setData(keyName, data)
    return true
end

local function getYFSData(keyName)
    if not DetectedYFS or not keyName then return false end
    local data = YFSDB:getData(keyName)
    if data == nil or not IsTable(data.v) then
        return false
    end
    return data
end

local function storeYFSNamedWaypoints(data)
    storeYFSData(YFS_NAMED_POINTS, data)
end

local function storeYFSRoutes(data)
    storeYFSData(YFS_ROUTES, data)
end

-- Class functions

function cmd.GetYFSNamedWaypoints(muteMsg)
    if not DetectedYFS then
        return E("[E] Linked YFS databank required!")
    end
    local namedWP = getYFSData(YFS_NAMED_POINTS)
    if not namedWP and not muteMsg then
        P("[I] No named waypoints")
    end
    return namedWP
end

function cmd.GetYFSRoutes()
    if not DetectedYFS then
        return E("[E] Linked YFS databank required!")
    end
    local data = getYFSData(YFS_ROUTES)
    if not data then
        return E('[I] No YFS routes found.')
    end
    return data
end

function cmd.PlanetInfoCmd(text)
    PM.PlanetInfo(text)
end

function cmd.PrintAltitudeCmd(text)
    P(Out.PrettyDistance(PM.Altitude()))
end

function cmd.PrintPosCmd(text)
    P(PM.GetCurrentPosString())
end

function cmd.PrintWorldPosCmd(text)
    P(PM.Vec3ToPosString(PM.WorldPosVec3()))
end

function cmd.WarpCostCmd(text)
    CalcWarpCost(text)
end

---@comment with WM: create commands to recreate waypoints in either YFS or ArchHud format
function cmd.WpSaveNamedCmd(text, isYfs)
    if not WM or not WM:hasPoints() then
        return E("[E] No waypoints to export.")
    end
    local output = ""
    for _,wp in ipairs(WM:getSorted()) do
        local pos = wp:AsString()
        if isYfs then
            pos = "pos-save-as '" .. wp:getName() .. "' -pos " .. pos
        else
            pos = "/addlocation " .. wp:getName() .. " " .. pos
        end
        output = output .. pos .. "\n"
        P(pos)
    end
    ScreenOutput(output)
end

function cmd.ArchSaveNamedCmd(text)
    cmd.WpSaveNamedCmd(text, false)
end

---@comment with WM: output name and position for all waypoints
function cmd.WpExportCmd(text)
    if not WM or not WM:hasPoints() then
        return E("[E] No waypoints to export.")
    end
    local output = ""
    local wplist = WM:getSorted()
    for _,wp in ipairs(wplist) do
        local s = wp:getName() .. "\n" .. wp:AsString() .. "\n"
        output = output .. s
    end
    P(output)
    ScreenOutput(output)
end

function cmd.WpAltitudeCeilingCmd(text)
    local wpnames = cmd.GetYFSNamedWaypoints()
    if not wpnames then return end

    -- 0 parse params to find a) name and b) new altitude value
    local parts = SU.SplitQuoted(text)
    if #parts ~= 2 then
        P("[E] Parameter(s) missing: 'name 1' 'name 2'")
        return E("Example: /wp-altitude-ceiling 'Base 1' 'Base 2'")
    end
    local wpName1 = parts[1]
    local wpName2 = parts[2]

    -- 2 find named waypoint as per params
    local wp1found, wp2found = true, true
    if wpnames.v[wpName1] == nil or wpnames.v[wpName1] == "" then
        P("[E] Waypoint '".. wpName1 .."' not found.")
        wp1found = false
    end
    if wpnames.v[wpName2] == nil or wpnames.v[wpName2] == "" then
        P("[E] Waypoint '".. wpName2 .."' not found.")
        wp2found = false
    end
    if not wp1found or not wp2found then return end
    if wpnames.v[wpName1] == wpnames.v[wpName2] then
        return E("[E] Parameters invalid (same names).")
    end

    -- 3 get waypoint's altitudes and update the lower one
    local alt1 = PM.GetAltitudeFromPos(wpnames.v[wpName1].pos)
    local alt2 = PM.GetAltitudeFromPos(wpnames.v[wpName2].pos)
    if alt1 == alt2 then
        P("[I] Waypoints had same altitude, no changes applied.")
        return
    end
    local target, targetAlt = "", 0
    if alt1 > alt2 then
        target = wpName2
        targetAlt = alt1
    else
        target = wpName1
        targetAlt = alt2
    end
    local newPos = PM.ReplaceAltitudeInPos(wpnames.v[target].pos, targetAlt)
    wpnames.v[target].pos = newPos
    P("[I] Waypoint '"..target.."' changed to:")
    P(newPos)

    -- 4 json.encode data and write back to DB
    storeYFSNamedWaypoints(wpnames)
    return true
end

function cmd.GetStoredLocations(points) -- for ArchHud only
    if not points or not IsTable(points) then return end
    for _,p in ipairs(points) do
        if p.name and p.position and p.position.x and p.position.y and p.position.z then
            P("[I] Location '".. p.name .."' found.")
            local pos = '::pos{0,0,'.. p.position.x .. ',' .. p.position.y .. ',' .. p.position.z ..'}'
            PM.CreateWaypoint(pos, p.name)
        end
    end
end

function cmd.YfsAddAltitudeWpCmd(text)
    local wpdata = cmd.GetYFSNamedWaypoints()
    if not wpdata or not IsTable(wpdata.v) or TableLen(wpdata.v) == 0 then
        return E("[E] No waypoints.")
    end

    local example = "\nExample: /yfs-add-altitude-wp -altitude 450 -suffix 'F'"
    local args = SU.SplitQuoted(text)
    local pStart = GetParamValue(args, "-wpStartsWith", "s")
    if #args < 1 then
        return E("[E] Parameter missing: -altitude"..example)
    end
    local pAlt = GetParamValue(args, "-altitude", "n", true)
    local pSuf = GetParamValue(args, "-suffix", "s")
    if not pSuf or pSuf == "" then pSuf = "F" end
    if pAlt < -100 or pAlt > 20000 then
        return E("[E] -altitude value out of range (-100 .. 20000)"..example)
    end

    -- need a sorted list of names, can't use wpdata as that is being modified
    local wplist = {}
    for k in PairsByKeys(wpdata.v) do
        if not pStart or k:find(pStart) > 0 then
            table.insert(wplist, k)
        end
    end
    local newData, names = yfsAddAltitudeWaypoints(wpdata, wplist, pAlt, pSuf)
    if newData ~= nil and names ~= nil then
        storeYFSNamedWaypoints(newData)
    end
    return true
end

function cmd.YfsBuildRouteFromWpCmd(text)
    local wpdata = cmd.GetYFSNamedWaypoints()
    if not wpdata or not IsTable(wpdata.v) or TableLen(wpdata.v) == 0 then
        return E("[E] No waypoints.")
    end

    local rdata = cmd.GetYFSRoutes()
    if not rdata or not IsTable(rdata.v) or TableLen(rdata.v) == 0 then
        -- Initializing routes
        rdata = { v = {}, t = "table" }
    else
    end

    local example = "\nExample: /yfs-build-route-from-wp -name 'Route' -altitude 450 -wpStartsWith 'Chr' -suffix 'F'\n-suffix is optional, default F (Flight)"
    local args = SU.SplitQuoted(text)
    if #args < 1 then
        return E("[E] Parameters missing!"..example)
    end

    local pName  = GetParamValue(args, "-name", "s", true)
    if not pName then return end
    local pStart = GetParamValue(args, "-wpStartsWith", "s")
    local pAlt   = GetParamValue(args, "-altitude", "n", true)
    if not pAlt then return end
    local pSuf   = GetParamValue(args, "-prefix", "s")
    local pMarginL = GetParamValue(args, "-marginL", "n")
    local pMarginF = GetParamValue(args, "-marginF", "n")
    local pMaxSpeed = GetParamValue(args, "-maxSpeed", "n")
    local pFinalSpeedF = GetParamValue(args, "-finalSpeedF", "n")
    -- some sanity checks, review later
    pMarginL = uclamp(pMarginL or 0.1, 0.1, 100) -- landed position margin
    pMarginF = uclamp(pMarginF or 0.1, 0.1, 100) -- flight position margin
    pMaxSpeed = uclamp(pMaxSpeed or 0, 0, 1200) -- max speed at flight
    pFinalSpeedF = uclamp(pFinalSpeedF or 0, 0, 1200) -- speed reaching the wp
    if rdata.v[pName] ~= nil then
        return E("[E] Route "..pName.."already exists, aborting!")
    end
    if not type(pSuf) == "string" or pSuf == "" then pSuf = "F" end
    if strlen(pSuf) > 3 then
        return E("[E] -suffix accepts max. 3 characters"..example)
    end
    if pAlt < -100 or pAlt > 20000 then
        return E("[E] -altitude value out of range (-100 .. 20000)"..example)
    end

    -- need a sorted list of names, can't use wpdata as that is being modified *live*
    -- names could be filtered by pStart
    local wplist = {}
    for k in PairsByKeys(wpdata.v) do
        if not pStart or k:find(pStart) > 0 then
            table.insert(wplist, k)
        end
    end

    -- lets add new "flight" waypoints and get updated tables back
    local wpdata, wplistNew = yfsAddAltitudeWaypoints(wpdata, wplist, pAlt, pSuf)
    if wpdata == nil or wplistNew == nil then
        return E("[I] No waypoints processed: no changes made.")
    end

    -- add new route
    rdata.v[pName] = { points = {} }

    -- assume that wplistNew now contains all required wp names in order
    -- so these can be added to the route
    local cnt = 0
    for _,k in ipairs(wplistNew) do
        local wp = wpdata.v[k]
        if wp ~= nil then
            -- add wp to route
            cnt = cnt + 1
            local rOpt = { margin = 0.1, maxSpeed = 0 }
            local rp = { opt = rOpt, pos = wp.pos, waypointRef = k }
            -- for "flight" waypoints:
            if GetIndex(wplist, k) < 1 then
                -- set final approaching speed for landing waypoints if specified
                if pFinalSpeedF and pFinalSpeedF > 0 and GetIndex(wplist, k) < 1 then
                    rp.opt.finalSpeed = pFinalSpeedF
                end
                -- set max speed for flight waypoints if specified
                if pMaxSpeed and pMaxSpeed > 0 then
                    rp.opt.maxSpeed = pMaxSpeed
                end
                -- set margin for flight waypoints if specified
                if pMarginF and pMarginF > 0.1 then
                    rp.opt.margin = pMarginF
                end
                rp.opt.selectable = false
                rp.opt.skippable = false
            else -- for Landed waypoints:
                -- set margin for landed waypoints if specified
                if pMarginL and pMarginL > 0.1 then
                    rp.opt.margin = pMarginL
                end
                rp.opt.selectable = true
                rp.opt.skippable = true
            end
            table.insert(rdata.v[pName].points, rp)
        end
    end
    P("[I] "..cnt.." positions added to route '"..pName.."'")
    storeYFSNamedWaypoints(wpdata)
    storeYFSRoutes(rdata)
end

function cmd.YfsSaveRouteCmd(text)
    local routes = cmd.GetYFSRoutes()
    if not routes then return end

    local parts = SU.SplitQuoted(text)
    if #parts < 1 then
        return E("[E] Parameter(s) missing: routename\nExample: /yfs-save-route 'Cryo' -onlySelectable -withOptions -prefix 'Cryo'")
    end
    local wpPrefix = GetParamValue(parts, "-prefix", "s")
    if not wpPrefix then wpPrefix = "WP" end
    local onlySelectable = GetIndex(parts, "-onlySelectable") > 0
    local withOptions = GetIndex(parts, "-withOptions") > 0
    local routename = parts[1]
    local route = routes.v[routename]
    if not route or not IsTable(route.points) or #route.points == 0 then
        return E("[E] Route '"..routename.."' not found or empty")
    end
    local output1, output2 = "create-route '"..routename.."'\r\n", ""

    local wpdata = cmd.GetYFSNamedWaypoints()

    -- iterate points, build one commands output for wp creation and one for
    -- adding each with options (optionally) to the route
    local wpIdx = 1
    local wpNames = {} -- to avoid duplicates
    for _,v in ipairs(route.points) do
        local wppos = ""
        local wpName = wpPrefix.." "..sformat("%03d", wpIdx)
        if v.waypointRef and wpdata then
            wpName = v.waypointRef
            wppos = wpdata.v[wpName].pos
        else
            wppos = v.pos or "<unknown>"
        end

        if GetIndex(wpNames, wpName) < 0 then
            wpNames[#wpNames + 1] = wpName
            local tmp = "pos-save-as '"..wpName.."' -pos "..wppos
            output1 = output1 .. tmp .. "\n"
        end
        if (not onlySelectable) or (v.opt["selectable"] ~= false) then
            local tmp = "route-add-named-pos '"..wpName.."'"
            if withOptions then
                -- named-waypoint level options
                -- Note: "lockdir" option is presently not transferrable!
                if v.opt["maxSpeed"] and v.opt["maxSpeed"] ~= 0 then
                    tmp = tmp.." -maxspeed "..v.opt["maxSpeed"]
                end
                if v.opt["margin"] and v.opt["margin"] ~= 0.1 then
                    tmp = tmp.." -margin "..v.opt["margin"]
                end
                -- route-level options require a 2nd command
                local routeLvlOptions = false
                local routeOptStr = ""
                if v.opt["skippable"] == true then
                    routeLvlOptions = true
                    routeOptStr = routeOptStr .. " -toggleSkippable"
                end
                if v.opt["selectable"] == false then
                    routeLvlOptions = true
                    routeOptStr = routeOptStr .. " -toggleSelectable"
                end
                if v.opt["finalSpeed"] and v.opt["finalSpeed"] ~= 0 then
                    routeLvlOptions = true
                    routeOptStr = routeOptStr.." -finalSpeed "..v.opt["finalSpeed"]
                end
                if routeLvlOptions then
                    tmp = tmp .. "\nroute-set-pos-option -ix "..wpIdx..routeOptStr
                end
            end
            output2 = output2 .. tmp .. "\n"
            wpIdx = wpIdx + 1
        end
    end
    output2 = output2.."route-save\r\n"
    P(output1..output2)
    ScreenOutput(output1..output2)
end

---@comment Replaces a given YFS waypoint (by -name) with current pos (default) or -pos ::pos{...}
function cmd.YfsReplaceWpCmd(text)
    local wpnames = cmd.GetYFSNamedWaypoints()
    if not wpnames then return end

    local ex = "\r\nExample: /yfs-replace-wp 'base 1'"
    local params = SU.SplitQuoted(text)
    if #params < 1 then
        return E("[E] Parameter(s) missing: -name 'point'"..ex)
    end

    local wpName = GetParamValue(params, "-name", "s", true)
    if not wpName then return end
    if not wpnames.v[wpName] or wpnames.v[wpName] == "" then
        return E("[E] Waypoint '".. wpName .."' not found."..ex)
    end

    local newPos = PM.GetCurrentPosString()
    local pPos = GetParamValue(params, "-pos", "s")
    if pPos then
        ---@diagnostic disable-next-line: cast-local-type
        local tmp = PM.SplitPos(pPos)
        if not tmp then
            return E("[E] Invalid ::pos{} specified!")
        end
        newPos = pPos
    end

    wpnames.v[wpName].pos = newPos
    P("[I] Waypoint '"..wpName.."' changed to:")
    P(newPos)

    storeYFSNamedWaypoints(wpnames)
    return true
end

function cmd.YfsRouteAltitudeCmd(text)
    local routes = cmd.GetYFSRoutes()
    if not routes then return end

    local namedWP = cmd.GetYFSNamedWaypoints()
    if not namedWP then return end

    -- 1 check parameters
    local example = "\nExample:\n/yfs-route-altitude -route 'name' -ix 2 -endIx 3 -alt 330\nThe -endIx is optional."
    local parts  = SU.SplitQuoted(text)
    local pName  = GetParamValue(parts, "-route", "s", true)
    if not pName then return end
    if not routes.v[pName] then
        return E("[E] Route '"..pName.."' not found."..example)
    end
    if not routes.v[pName].points or #routes.v[pName].points == 0 then
        return E("[E] Route '"..pName.."' empty.")
    end

    local pStart = GetParamValue(parts, "-ix", "i", true)
    local pEnd   = GetParamValue(parts, "-endIx", "i")
    local pAlt   = GetParamValue(parts, "-alt", "n", true)
    local isError = not pName or not pStart or not pAlt or (pStart < 1) or (pEnd and pEnd < pStart) or (pAlt < -100) or (pAlt > 10000)
    if isError then
        return E("[E] Wrong number of parameters / invalid values!"..example)
    end
    if not pEnd or pEnd < pStart then pEnd = pStart end

    -- 2 process route waypoints and collect named waypoint names
    -- /yfs-route-altitude -route 'Cryo' -ix 2 -endIx 3 -alt 330.1243
    P("[I] Processing route '"..pName.."'")
    local changed = 0
    local wpnames = {}
    for i,v in ipairs(routes.v[pName].points) do
        if i >= pStart and i <= pEnd then
            local wpName = v.waypointRef
            local wp = namedWP.v[wpName]
            if wp ~= nil then
                if GetIndex(wpnames, wpName) < 1 then
                    table.insert(wpnames, wpName)
                end
                local newPos = PM.ReplaceAltitudeInPos(wp.pos, pAlt)
                routes.v[pName].points[i].pos = newPos
                P("[I] Route Waypoint '"..wpName.."' changed to:\n"..newPos)
            end
        end
    end
    if #wpnames == 0 then
        return E("[I] No waypoints in route changed.\n[*] Make sure that start (and end-index) are valid.")
    end
    -- 3 store routes back to db
    storeYFSRoutes(routes)
    P("[I] Routes saved.")

    -- 4 process named waypoints list
    changed = 0
    for _,entry in ipairs(wpnames) do
        if namedWP.v[entry] then
            changed = changed + 1
            local newPos = PM.ReplaceAltitudeInPos(namedWP.v[entry].pos, altitude)
            namedWP.v[entry].pos = newPos
            P("[I] Named Waypoint '"..entry.."' changed to:")
            P(newPos)
        else
            P("[E] '"..entry.."' not found!")
        end
    end
    -- 5 write back to DB
    if changed > 0 then
        storeYFSNamedWaypoints(namedWP)
        P("[I] Named waypoints saved.")
    end
end

function cmd.YfsWpAltitudeCmd(text)
    -- 1 read named waypoints from DB
    local wpnames = cmd.GetYFSNamedWaypoints()
    if not wpnames then return E("[E] No named waypoints.") end

    -- 2 parse params to find a) name and b) new altitude value
    local parts = SU.SplitQuoted(text)
    if #parts ~= 2 then
        return E("[E] Wrong number of parameters!\nExample: /yfs-wp-altitude 'Base 1' 324.12")
    end
    local pName = parts[1] or ""

    -- 3 find named waypoint
    if not pName or not parts[2] or not wpnames.v[pName] or wpnames.v[pName] == "" then
         return E("[E] Waypoint '".. pName .."' not found")
    end

    -- 4 alter waypoint's altitude
    local pAlt = tonum(parts[2] or 0)
    local newPos = PM.ReplaceAltitudeInPos(wpnames.v[pName].pos, pAlt)
    wpnames.v[pName].pos = newPos
    P("[I] Waypoint '"..pName.."' changed to:")
    P(newPos)
    P("[I] Note: routes' waypoints are updated on route activation, i.e. exporting route data before activation may still show old value!")

    -- 4 write back to DB
    storeYFSNamedWaypoints(wpnames)
    return true
end

function cmd.YfsRouteNearestCmd(text)
    local routes = cmd.GetYFSRoutes()
    if not routes then return end
    -- 1 process params
    local params = SU.SplitQuoted(text)
    if #params == 0 or #params > 2 then
        P("[E] Wrong parameter count\n[I] Example: /yfs-route-nearest 'Route 1'")
        P("\nOptional parameter:\n")
        P("-onlySelectable -> only show closest, selectable waypoints in route")
        return false
    end
    -- 2 find the route
    local routeName = params[1]
    local route = routes.v[routeName]
    if not route or not IsTable(route.points) then
        return E("[E] Route '" .. routeName .."' not found or empty")
    end
    P("[I] Route '"..routeName.."' found.")
    -- 3 check optional parameters
    local onlySelectable = GetIndex(params, "-onlySelectable") > 0

    -- 4 process route waypoints
    local wplist = cmd.GetYFSNamedWaypoints(true)
    local idx = 0
    local closestDist = 999999999
    local sDist, sNearest = "", ""
    local res =  {}
    for k,v in ipairs(route.points) do
        idx = idx + 1
        if (not onlySelectable) or (v.opt and v.opt.selectable ~= false) then
            local wpname = SU.Trim(sformat("%02d", idx) .. ": '"..(v.waypointRef or "").."'")
            local pos = v.pos
            if v.waypointRef and wplist then
                pos = wplist.v[v.waypointRef].pos
            end
            local dist = PM.GetDistance(pos)
            if dist > 0.1 then
                route.points[k].distance = dist
                sDist = wpname .. " = " .. sformat("%.4f", dist)
                if dist < closestDist then
                    sNearest = sDist
                    closestDist = dist
                end
                local tmpDist = tostring(math.modf(dist * 10000))
                local key = ('0'):rep(12-#tmpDist)..tmpDist
                res[key] = idx
            end
        end
    end
    if not idx then return E("[I] No selectable waypoints found.") end
    local output = "Route-Idx / Name / Distance (m)\n"
    for _,key in pairs(GetSortedAssocKeys(res)) do
        local routeIdx = res[key]
        local wpName = route.points[routeIdx].waypointRef
        local wpDist = route.points[routeIdx].distance
        output = output .. sformat("%02d", routeIdx).." / '"..wpName.."' / "
        output = output .. Out.PrettyDistance(wpDist).."\n"
    end
    output = output .. "\n[I] Nearest waypoint: "..sNearest

    Out.PrintLines(output)
    ScreenOutput(output)
end

function cmd.YfsRouteToNamedCmd(text)
    local routes = cmd.GetYFSRoutes()
    if not routes then return end
    -- 1 process params
    local params = SU.SplitQuoted(text)
    if #params == 0 or #params > 6 then
        P("[E] Wrong parameter count\n[I] Example: /yfs-route-to-named 'Route 1'\nOptional parameters:\n")
        P("-onlySelectable -> only write waypoints marked as selectable in route")
        P("-prefix Myprefix -> if unspecified, 'WP' is default")
        P("-toScreen -> output JSON of list to optional screen if linked")
        P("-toDB -> only if this is given, the changed list will be written to DB to avoid miscalls")
        P("Important: command aborts if ANY waypoint's name starts with given prefix to avoid errors!")
        return false
    end
    -- 2 find the route
    local routeName = params[1]
    local route = routes.v[routeName]
    if not route or not IsTable(route.points) then
        return E("[E] Route '" .. routeName .."' not found or empty")
    end
    P("[I] Route '"..routeName.."' found.")
    -- 3 check optional parameters
    local toDB = GetIndex(params, "-toDB") > 0
    local toScreen = GetIndex(params, "-toScreen") > 0
    local onlySelectable = GetIndex(params, "-onlySelectable") > 0
    local wpPrefix = GetParamValue(params, "-prefix", "s")
    if not wpPrefix then wpPrefix = "WP" end
    -- local margin = nil
    -- local pMargin = GetParamValue(params, "-margin", "number")
    -- if pMargin and pMargin ~= 0.1 then margin = pMargin end

    -- 4 process route waypoints
    local wplist = cmd.GetYFSNamedWaypoints(true)
    if not wplist or not wplist.v then
        wplist = { v = { } }
    else
        -- if any WP with same prefix already exists, abort!
        for k,_ in pairs(wplist.v) do
            if string.find(k, wpPrefix) == 1 then
                return E("[!] Waypoints with same prefix already exist!\n[!] Command aborted.")
            end
        end
    end
    local idx = 0
    for _,v in ipairs(route.points) do
        if (not onlySelectable) or (v.opt and v.opt.selectable ~= false) then
            idx = idx + 1
            local wpname = wpPrefix .. " " .. sformat("%02d", idx)
            local wp = { pos = v.pos, opt = v.opt}
            --if margin then wp.opt.margin = margin end
            wplist.v[wpname] = wp
            P(wpname .."  " .. v.pos)
        end
    end
    if not idx then return E("[I] No changes to waypoints done") end

    -- 5 write waypoints back to DB, if at least 1 point was added
    if toDB then
        storeYFSNamedWaypoints(wplist)
        P("[I] Waypoint changes saved to databank!")
    else
        P("[I] -toDB not present, no changes saved to databank!")
    end
    if toScreen then
        ScreenOutput(json.encode(wplist.v))
    end
end

function cmd.YFSLoadNamedWaypoints()
    local wpnames = cmd.GetYFSNamedWaypoints()
    if not wpnames then return end
    for k,v in pairs(wpnames.v) do
        PM.CreateWaypoint(v.pos, k)
    end
end

function cmd.YFSLoadRoutepoints(onlySelectableWP, onlyWpForRoute)
    local routes = cmd.GetYFSRoutes()
    if not routes then return false end
    P('[I] Processing routes...')
    for k,v in pairs(routes.v) do
        if (onlyWpForRoute == "" or onlyWpForRoute == k) and IsTable(v) then
            for k2,v2 in ipairs(v.points) do
                if (not onlySelectableWP) or (v2.opt["selectable"] ~= false) then
                    local wpName = k .. " " .. k2
                    if v2.waypointRef then
                        wpName = v2.waypointRef
                    end
                    PM.CreateWaypoint(v2["pos"], wpName)
                end
            end
            P("[I] Route '"..k.."' read.")
        end
    end
    return true
end

function cmd.YfsSaveNamedCmd(text)
    cmd.WpSaveNamedCmd(text, true)
end

function cmd.PosDataCmd()
    --P("GetCameraCmd() called")
    P("getCameraHorizontalFov: "..system.getCameraHorizontalFov())
    P("getCameraVerticalFov: "..system.getCameraVerticalFov())

    P("getCameraPos: "..PM.Vec3String(system.getCameraPos()))
    P("getCameraForward: "..PM.Vec3String(system.getCameraForward()))
    P("getCameraRight: "..PM.Vec3String(system.getCameraRight()))
    P("getCameraUp: "..PM.Vec3String(system.getCameraUp()))

    P("getCameraWorldPos: "..PM.Vec3String(system.getCameraWorldPos()))
    P("getCameraWorldForward: "..PM.Vec3String(system.getCameraWorldForward()))
    P("getCameraWorldRight: "..PM.Vec3String(system.getCameraWorldRight()))
    P("getCameraWorldUp: "..PM.Vec3String(system.getCameraWorldUp()))

    P("construct.getWorldPosition: "..PM.Vec3String(construct.getWorldPosition(construct.getId())))
    P("construct.getOrientationForward: "..PM.Vec3String(construct.getOrientationForward()))
    P("construct.getOrientationRight: "..PM.Vec3String(construct.getOrientationRight()))
    P("construct.getOrientationUp: "..PM.Vec3String(construct.getOrientationUp()))
end

function cmd.DumpPointsCmd()
    if true then
        P("~=~=~=~=~=~=~= DUMP START ~=~=~=~=~=~=")
        local tmp = Out.DumpVar(WM:getWaypointsInst())
        P(tmp)
        return ScreenOutput((tmp or "[I] No waypoints."),"\n~=~=~=~=~=~=~= DUMP END ~=~=~=~=~=~=~=")
    end

end

function cmd.DumpRoutesCmd()
    if not DetectedYFS then return E("[I] No YFS databank.") end
    P("~=~=~=~=~=~=~= ROUTES DUMP START ~=~=~=~=~=~=")
    local tmp = YFSDB:getString(YFS_ROUTES)
    P(tmp)
    ScreenOutput((tmp or "[I] No routes."),"\n~=~=~=~=~=~=~= ROUTES DUMP END ~=~=~=~=~=~=~=")
end

function cmd.RoutesCmd()
    local routes = cmd.GetYFSRoutes()
    if not routes then return end
    P("[I] Available routes:")
    for k,_ in pairs(routes.v) do
        P(k)
    end
end

-- *** Dev/Testing functions ***

function cmd.YfsTestDataCmd(param)
    if not (param == "TESTING") then return end
    P("[*] Creating YFS test data...")

    YFSDB:remove(YFS_NAMED_POINTS)
    local data = { }
    data["Chr 01"] = { pos = "::pos{0,7,-20.7784,-153.7402,360.5184}", opt = {} }
    data["Chr 02"] = { pos = "::pos{0,7,-21.3610,-152.3447,345.8787}", opt = {} }
    data["Chr 03"] = { pos = "::pos{0,7,-23.0540,-152.8934,360.6677}", opt = {} }
    data["Chr 04"] = { pos = "::pos{0,7,-22.4445,-154.3119,320.1029}", opt = {} }
    data["Chr 05"] = { pos = "::pos{0,7,-20.5370,-154.7507,308.0151}", opt = {} }
    data["Chr 06"] = { pos = "::pos{0,7,-21.6295,-155.1465,292.7660}", opt = {} }
    data["Chr Hub"] = { pos = "::pos{0,7,-21.9903,-153.1008,391.4632}", opt = {} }
    local tmp = { v = data, t = type(data) }
    storeYFSNamedWaypoints(tmp)

    YFSDB:remove(YFS_ROUTES)
    local r = { }
    -- r["Test"] = { points = { } }
    -- r["Test"].points[1] = { pos = "::pos{0,7,-20.8094,-153.7308,366.1022}", waypointRef = "Chr 01" }
    storeYFSRoutes({ v = r, t = type(r) })

    P("[*] YFS test data saved!")
    cmd.DumpPointsCmd()
    cmd.DumpRoutesCmd()
end

function cmd.ConversionTestCmd(param)
    PM.ConversionTest()
end

function cmd.XCmd()
    -- local s = "-name C -altitude 440 -marginL 0.5 -marginF 1 -finalSpeedF 10 -suffix 'F'"
    -- P("X params: "..params)
    -- cmd.YfsBuildRouteFromWpCmd(s)
end

return cmd
end)
package.preload['YFS-Tools:help.lua']=(function()
local help = {}

function help.PrintHelpCmd()
    local hlp = "~~~~~~~~~~~~~~~~~~~~\nYFS-Tools Commands:\n~~~~~~~~~~~~~~~~~~~~\n"..
    "/arch-save-named\n-> Builds list of chat commands for ArchHud to add locations for all named waypoints.\n"..
    "/planetInfo (id or name)\n-> Info about current planet or for passed planet id or name, e.g. 2 for Alioth).\n"..
    "/printAltitude /printPos /printWorldPos\n-> Prints info data.\n"..
    "/warpCost -from name/::pos{}/planets -to name/::pos{}/planets -mass tons -moons\n-> Flexible warp cell calculator.\n"..
    "/wp-altitude-ceiling\n-> Changes a waypoint to have the higher altitude of both.\n"..
    "/wp-export\n-> Outputs list of plain waypoints to chat and an optional screen. Source can include ArchHud locations, too, if databank linked.\n"..
    "/yfs-add-altitude-wp\n-> Adds waypoints for each existing WP at a specified altitude and name suffix.\n"..
    "/yfs-build-route-from-wp\n-> Powerful route-building command based on existing named waypoints.\n"..
    "/yfs-route-altitude\n-> Changes altitude for a range of waypoints of a specific YFS route.\n"..
    "/yfs-route-nearest\n-> Show list of route waypoints by distance from current location.\n"..
    "/yfs-route-to-named\n-> Converts a route's *unnamed* waypoints to named waypoints for YFS.\n"..
    "/yfs-save-named\n-> Builds list of YFS commands to recreate all named waypoints.\n"..
    "/yfs-save-route\n-> Builds list of YFS commands to recreate full route incl. named waypoints and their options.\n"..
    "/yfs-wp-altitude\n-> Changes altitude of a named waypoint to specified altitude.\n"..
    "----------------------------------\n"..
    "Important: Enclose names (as parameters) in single quotes if they contain blanks!\n"..
    "*** DO NOT USE COMMANDS THAT CHANGE POINTS ***\n*** OR ROUTES WHILE YFS IS RUNNING! ***\n"
    ScreenOutput(hlp)
    P(hlp)
end

return help
end)
package.preload['YFS-Tools:warpcost.lua']=(function()
-- requires SU, PM
local strmatch, sformat, strlen = string.match, string.format, string.len
local tonum, uclamp, mabs, max, floor, ceil = tonumber, utils.clamp, math.abs, math.max, math.floor, math.ceil


---@comment Calculates # of warp cells for distance and mass
---@param text string List of space-separated params
function CalcWarpCost(text)
    local example = "\nExample 1:\n/warpCost -from Madis -to Alioth -mass 534"..
        "\nExample 2:\n/warpCost -from Alioth -to planets -moons"..
        "\nOptional '-from x' with x being either 'here', a planet name, ::pos{} or 'planets' (multi-result)."..
        "\nOptional '-to x' like -from, but for end location."..
        "\nOptional '-mass x' with x the total mass in tons. If not given, the current constructs' total mass is used."..
        "\nOptional '-cargo x' with x the cargo mass in tons. If specified, a cell count for a return trip is calculated, too."..
        "\nOptional '-moons' only together with 'planets' to also include moons in the list."..
        "\n- One of -from or -to can be left out, then the current construct's location (or planet) is used."..
        "\n- If construct is landed on a planet or moon, the Atlas specified warp altitude is the starting point."..
        "\n- Enclose names in single-quotes if they contain spaces!"
    local getCMass = construct.getMass
    local pOn, onPlanet = {}, false
    local s, s2 = "~~~ WARP CELL CALCULATOR ~~~", ""

    local function checkParam(args, pName, isFrom)
        local v, allPlanets, offs = {}, false, 0
        local par = GetParamValue(args, pName, "s")
        if not par or (par == "") or (par == "here") then
            v = PM.WorldPosVec3() -- current position
            if onPlanet and pOn then
                offs = 2 * pOn.radius
                par = pOn.name[1]
                v = vec3(pOn.center)
            else
                offs = 12 -- min. 12 km warp distance
                par = PM.Vec3ToPosString(v)
            end
        elseif par == "planets" then
            allPlanets = true
        elseif par > "" then
            if SU.StartsWith(par, "::pos{") then
                offs = 12 -- min. 12 km warp distance
                v = PM.MapPosToWorldPos(par)
            else
                local p = PM.PlanetByName(par)
                if p then
                    offs = 2 * p.radius
                    v = vec3(p.center)
                end
            end
        end
        return { parm = par, v = v, isP = allPlanets, offset = offs }
    end

    local args = SU.SplitQuoted(text)
    if #args < 1 then return E("[E] Parameter(s) missing!"..example) end
    local pMoons = GetIndex(args, "-moons") > 0

    -- for current location, check if we are "on" a planet (within atmo-radius),
    -- and set an offset of 2*radius from center as "warp barrier"
    local offset = 0
    pOn = PM.GetClosestPlanet(PM.WorldPosVec3())
    if pOn then
        offset = 2 * pOn.radius -- warp exclusion distance from center
        onPlanet = PM.Altitude() < offset
        if onPlanet then
            s2 = "Current"
        else
            s2 = "Nearest"
        end
        s = s.."\n"..s2.." planet: "..pOn.name[1]
    else
        s = s.."\n[I] No planet nearby!"
    end

    ---@diagnostic disable-next-line: missing-parameter
    local maxMass = 50000
    ---@diagnostic disable-next-line: missing-parameter
    local tons = getCMass(construct.getId()) / 1000

    -- check -cargo param and value
    local pCargo, bCargo = 0, false
    if GetIndex(args, "-cargo") > 0 then
        local tmpCargo = GetParamValue(args, "-cargo", "n")
        tmpCargo = tmpCargo or 0
        if tmpCargo > 0 then
            pCargo = uclamp(tmpCargo, 0, maxMass)
            bCargo = pCargo > 0
        else
            return E(s.."\n[E] Invalid -cargo value, must be in range of 1-50000 tons!")
        end
    end

    local pMass = GetParamValue(args, "-mass", "n")
    s2 = "Mass: "
    if pMass then
        tons = tonum(pMass)
    else
        s2 = "Construct "..s2
    end
    s = s.."\n"..s2..Out.PrettyMass(tons*1000)
    if bCargo then
        s = s.."  ~*~  Cargo: "..Out.PrettyMass(pCargo*1000)
    end
    if tons < 100 then -- warp drive alone is 75 tons!
        return E(s.."\n[E] Impossibly low mass for a warp ship! ;)")
    elseif tons > maxMass then
        return E(s.."\n[E] I don't accept you're warping that heavy! ;)")
    end

    local locFrom = checkParam(args, "-from", true)
    if not locFrom.isP and not locFrom.v then
        return E(s.."\n[E] Invalid starting location!")
    end
    local locTo = checkParam(args, "-to", false)
    if not locTo.isP and not locTo.v then
        return E(s.."\n[E] Invalid end location!")
    end

    if locFrom.isP and locTo.isP then
        return E(s.."\n[E] Only one 'planets' option supported!")
    end
    if (locFrom.parm == locTo.parm) or (locFrom.v == locTo.v) then
        return E(s.."\n[E] Start and end locations must be different!")
    end

    local function process(from, to, distance, massT, cargo)
        local out = ""
        if from > "" then out = out .. from end
        if from > "" and to > "" then out = out .. " to " end
        if to > "" then out = out .. to end
        out = out.. " ("..Out.PrettyDistance(distance)..")"

        -- min 1 SU, max 500 SU (1 SU = 200000 m)
        if distance < 200000 then
            return out.." -> too short!"
        elseif distance > 100000000 then
            return out.." -> too far!"
        end
        local cnt = PM.ComputeCells(distance, massT)
        out = out.." = "..cnt.." cell" .. SU.If(cnt > 1, "s")
        if bCargo then
            local cnt2 = PM.ComputeCells(distance, massT - cargo)
            out = out.." / "..cnt2.." cell" .. SU.If(cnt > 1, "s").." = "..(cnt+cnt2).." total"
        end
        return out
    end

    -- Single source and destination
    if not locFrom.isP and not locTo.isP then
        local distance = mabs(vec3(locFrom.v - locTo.v):len()) - locFrom.offset - locTo.offset
        local res = process(locFrom.parm, locTo.parm, distance, tons, pCargo)
        if type(res) == "string" then
            s = s .. "\n" .. res
            P(s)
            ScreenOutput(s)
        else
            E("[E] Sorry, something went wrong :(")
        end
        return
    end

    -- Planets processing
    local v1, v2 = nil, nil
    s2 = " (Distance) / Cells"..SU.If(bCargo, " / Return w/o cargo")
    if locFrom.isP then
        s = s.."\nTo: "..locTo.parm.."\nFrom"..s2
    else
        s = s.."\nFrom: "..locFrom.parm.."\nTo"..s2
    end
    for _,v in pairs(WaypointInfo[0]) do
        if not v.isAsteroid and (pMoons or not v.isMoon) then
            offset = 2 * v.radius
            if locFrom.isP then
                locFrom.parm = v.name[1]
                locFrom.v = vec3(v.center)
                offset = offset + locTo.offset
            else
                locTo.parm = v.name[1]
                locTo.v = vec3(v.center)
                offset = offset + locFrom.offset
            end
            local distance = mabs(vec3(locFrom.v - locTo.v):len()) - offset
            if distance > 100000 then
                s = s .. "\n" ..
                    process(SU.If(locFrom.isP, locFrom.parm),
                            SU.If(locTo.isP, locTo.parm),
                            distance, tons, pCargo)
            end
        end
    end
    P(s)
    ScreenOutput(s)
end

end)
package.preload['YFS-Tools:../util/wpoint.lua']=(function()
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
end)
package.preload['YFS-Tools:../util/wpointmgr.lua']=(function()
local tonum, strlen, strmatch = tonumber, string.len, string.match


---@class WaypointMgr
WaypointMgr = { name = "", waypoints = {} }

--- comment Add a waypoint object to the list at position 'index'
--- @param self table
--- @param waypoint any
--- @param index any
--- @return nil
WaypointMgr.add = function(self, waypoint, index)
    if waypoint.__Waypoint and waypoint.__Waypoint() then
        -- If the waypoint has no name, skip duplicate check
        if waypoint.name and waypoint.name ~= "" then
            -- Check if a waypoint with the same name already exists
            for _,v in ipairs(self.waypoints) do
                if v.name == waypoint.name then
                    return nil
                end
            end
        end
        local wplus1 = 1 + #self.waypoints
        if index then
            -- Check if the specified index is within the valid range
            if index < 1 or index > wplus1 then
                print("[E] Invalid index. Must be in the range 1 to " .. wplus1)
                return nil
            end
            waypoint.parent = self
            table.insert(self.waypoints, index, waypoint)
        else
            waypoint.parent = self
            table.insert(self.waypoints, wplus1, waypoint)
        end
        return waypoint
    else
        print("[E] Invalid waypoint parameter!")
        return nil
    end
end

---@comment List of waypoints' data as table.
---@return table (systemId, planetId, latitude, longitude, altitude)
WaypointMgr.getWaypointsData = function(self)
    local res = {}
    for k,v in ipairs(self.waypoints) do
        table.insert(res, k, v:get())
    end
    return res
end

---@comment List of all waypoints as Waypoint objects.
---@return table Array of all Waypoint instances
WaypointMgr.getWaypointsInst = function(self)
    return self.waypoints
end

---@comment Returns the count of all waypoints
---@return integer Count of all waypoints
WaypointMgr.getCount = function(self)
    return #self.waypoints
end

---@comment Returns array of all waypoint instances sorted by their name
---@return table Array
WaypointMgr.getSorted = function(self)
    local sortedPoints = {}

    -- Copy waypoints to a new table for sorting
    for _,v in pairs(self.waypoints) do
        table.insert(sortedPoints, v)
    end

    -- Sort the copied table by waypoint names
    table.sort(sortedPoints, function(a, b)
        return a.name < b.name
    end)
    return sortedPoints
end

---@comment Moves waypoint at given index up by one, but 1 as minimum
WaypointMgr.moveUp = function(self, index)
    local waypointsCount = #self.waypoints

    if index and index > 1 and index <= waypointsCount then
        self.waypoints[index], self.waypoints[index - 1] = self.waypoints[index - 1], self.waypoints[index]
    end
end

---@comment Moves waypoint at given index down by one, but to end index as maximum
WaypointMgr.moveDown = function(self, index)
    local waypointsCount = #self.waypoints

    if index and index >= 1 and index < waypointsCount then
        self.waypoints[index], self.waypoints[index + 1] = self.waypoints[index + 1], self.waypoints[index]
    end
end

---@comment Removes only the first waypoint with the given name and returns that waypoint instance, otherwise nil
---@return any Either removed waypoint instance or nil if not found
WaypointMgr.removeByName = function(self, waypointName)
    for i, waypoint in ipairs(self.waypoints) do
        if waypoint.name == waypointName then
            local removedWaypoint = table.remove(self.waypoints, i)
            return removedWaypoint  -- Return the removed waypoint
        end
    end
    return nil  -- Return nil if not found
end

---@comment Returns true if at least one waypoint exist, else false
---@return boolean
WaypointMgr.hasPoints = function(self, param)
    return #self.waypoints > 0
end

---@comment Checks if a waypoint exists in 3 different ways: name, waypoint instance or same data
---@return any If not found, returns nil, otherwise the found waypoint instance
WaypointMgr.exists = function(self, param)
    for _, v in ipairs(self.waypoints) do
        if type(param) == "string" and v.name == param then
            return v
        elseif param and param.__Waypoint and Waypoint.__Waypoint() then
            if v == param then
                return v
            end
        elseif type(param) == "table" and #param == 5 then
            -- Check if a waypoint with the same nums exists
            if v.mapPos.systemId  == tonum(param[1]) and
               v.mapPos.planetId  == tonum(param[2]) and
               v.mapPos.latitude  == tonum(param[3]) and
               v.mapPos.longitude == tonum(param[4]) and
               v.mapPos.altitude  == tonum(param[5]) then
                return v
            end
        end
    end
    return nil
end

WaypointMgr.getName = function(self)
    return self.name
end

WaypointMgr.new = function(name)
    local obj = setmetatable(
        { waypoints = {}, name = name or "" },
        { __index = WaypointMgr }
    )
    return obj
end

return WaypointMgr

end)
package.preload['YFS-Tools:libmain.lua']=(function()
-- require used classes and instantiate important ones
SU = require('YFS-Tools:../util/SU.lua') -- string utils
Out = require('YFS-Tools:../util/out.lua') -- output utils
P = Out.PrintLines
E = Out.Error

require('YFS-Tools:../util/Dtbk.lua') -- databank

require('YFS-Tools:libutils.lua') -- helper functions
Cmd = require('YFS-Tools:commands.lua') -- all YFS Tools commands
Help = require('YFS-Tools:help.lua') -- help utils

require('YFS-Tools:warpcost.lua') -- warp calculator function

require('YFS-Tools:../util/wpoint.lua') -- waypoint class
WM = require('YFS-Tools:../util/wpointmgr.lua').new("MAIN") -- instantiate MAIN waypoint manager

--require('waypointer_lib')
end)
package.preload['YFS-Tools:../util/pos.lua']=(function()
--- Class related to positions/coordinates like local/world conversion etc.
--- requires global WaypointInfo table (= atlas), vec3 library; classes SU, Out
local max, cos, macos, mdeg, msin, mabs, atan, ceil, floor, mpi = math.max, math.cos, math.acos, math.deg, math.sin, math.abs, math.atan, math.ceil, math.floor, math.pi
local tonum, strlen, strmatch, sformat = tonumber, string.len, string.match, string.format
local uclamp, vec3 = utils.clamp, vec3

local o = {}
o.__index = o
function o.New(pCore, pConstruct, pWM)
    -- Private attribute
    local s = {
        core = pCore,
        construct = pConstruct,
        Alioth1G = 9.891,
        waypointNames = {},
        waypointCount = 0,
        planetNames = {},
        p = {}, -- Planet object
        pIdx = 0, -- Atlas planet index
        wm = pWM -- Waypoint Manager instance
    }

    local function float_eq(a, b) -- float equation
        if a == 0 then
            return mabs(b) < 1e-09
        elseif b == 0 then
            return mabs(a) < 1e-09
        else
            return mabs(a - b) < math.max(mabs(a), mabs(b)) * epsilon
        end
    end

    ---@return boolean
    local function constructPresent()
        return s.construct ~= nil
    end

    ---@return boolean
    local function corePresent()
        return s.core ~= nil
    end

    -- Public functions

    ---@return number amount of warp cells
    function o.ComputeCells(distance, tons)
        return ceil(max(floor(tons*floor(((distance/1000)/200))*0.00024), 1))
    end

    ---@return string
    function o.GetPosPattern()
        local num = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
        return '::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' .. num ..  ',' .. num .. '}'
    end

    ---@return number # of entries in WaypointInfo/Atlas
    function o.GetWaypointCount()
        return s.wm:getCount()
    end

    ---@param posStr string ::pos{} string
    ---@return table|nil returns a MapPos table of the coords or nil if invalid string
    function o.SplitPos(posStr)
        -- min. length is 16: "::pos{0,1,2,3,4}"
        if type(posStr) ~= "string" or strlen(posStr) < 16 or not strmatch(posStr, "^::pos{") then
            P("[E] Invalid position: "..posStr)
            return nil
        end
        local sysId, pId, lat, lng, alt = strmatch(posStr, o.GetPosPattern())
        return { systemId  = tonum(sysId),
                 id        = tonum(pId),
                 latitude  = tonum(lat),
                 longitude = tonum(lng),
                 altitude  = tonum(alt) }
    end

    ---@param posString string The ::pos{} string in local coords!
    ---@return number Altitude in meters (if a local pos -> relative to sea level)
    function o.GetAltitudeFromPos(posString)
        local p = o.SplitPos(posStr)
        if p and p.altitude then return p.altitude end
        return 0
    end

    ---@param posStr string The ::pos{} string
    ---@return integer Id of planet in Atlas, e.g. 2 for Alioth; 0 for Space!
    function o.GetPlanetFromPos(posStr)
        local p = o.SplitPos(posStr)
        if p and p.id and p.id > 0 then return p.id end
        return 0
    end

    function o.GetAtlasPlanet(pid)
        if not pid or not WaypointInfo[0] or not WaypointInfo[0][tonum(pid)] then
            return nil
        end
        return WaypointInfo[0][tonum(pid)]
    end

    function o.GetClosestPlanetId(worldPosVec)
        local pIdx, dist = 0, 0
        local planetDistance = math.huge
        for i,v in pairs(WaypointInfo[0]) do
            dist = (worldPosVec - vec3(v.center)):len()
            if dist < planetDistance then
                planetDistance = dist
                pIdx = i
            end
        end
        return pIdx
    end

    function o.GetClosestPlanet(worldPosVec)
        local pid = o.GetClosestPlanetId(worldPosVec)
        return o.GetAtlasPlanet(pid)
    end

    function o.GetCurrentPosString()
        local v = o.WorldPosVec3()
        return o.MapPos2String(o.WorldToMapPos(v))
    end

    ---@comment Formats a MapPos table to a ::pos{} string
    ---@return string
    function o.MapPos2String(mapPos)
        if type(mapPos) ~= "table" then return "" end
        return '::pos{' .. (mapPos.systemId or 0).. ',' .. (mapPos.id or 0) .. ',' ..
               sformat("%.4f", (mapPos.latitude or 0)) .. ',' .. 
               sformat("%.4f", (mapPos.longitude or 0)) ..  ',' ..
               sformat("%.4f", (mapPos.altitude or 0)) .. '}'
    end

    ---@comment Formats a vec3 world-pos table to a ::pos{} string (planet id 0!)
    ---@return string
    function o.Vec3ToPosString(v3)
        if type(v3) ~= "table" then return "" end
        return '::pos{0,0,' ..
               sformat("%.4f", (v3.x or 0)) .. ',' ..
               sformat("%.4f", (v3.y or 0)) ..  ',' ..
               sformat("%.4f", (v3.z or 0)) .. '}'
    end

    ---@comment Formats a vec3 world-pos table to a ::pos{} string (planet id 0!)
    ---@return string
    function o.Vec3String(v3)
        if type(v3) ~= "table" then return "" end
        v3 = vec3(v3)
        return sformat("%.4f", (v3.x or 0)) .. ', ' ..
               sformat("%.4f", (v3.y or 0)) .. ', ' ..
               sformat("%.4f", (v3.z or 0))
    end

    ---@param posStr string ::pos{} string for change
    ---@param newAltitude number? new altitude value
    ---@return string
    function o.ReplaceAltitudeInPos(posStr, newAltitude)
        --TODO: move this to Waypoint class; allow class as param
        local p = o.SplitPos(posStr)
        if not p or not p.altitude or not newAltitude then
            return posStr
        end
        p.altitude = tonum(newAltitude)
        return o.MapPos2String(p)
    end

    ---@comment Returns current planet id if in game, otherwise 2
    ---@return number
    function o.PlanetId()
        if not corePresent() then return 0 end
        if not INGAME then
            return 2 -- Alioth
        end
        return s.core.getCurrentPlanetId()
    end

    ---@comment If code is run outside of game, a fixed vec3 will be returned for testing!
    ---@return any Vec3 position of construct (or nil)
    function o.WorldPosVec3()
        if not INGAME then
            return { x = -25140.37011013, y = 100812.26194182, z = -52412.710373821}
        end
        if constructPresent() then
            ---@diagnostic disable-next-line: missing-parameter
            return vec3(construct.getWorldPosition())
        end
        if corePresent() then
            ---@diagnostic disable-next-line: missing-parameter
            return vec3(core.getWorldPosition())
        end
        return nil
    end

    ---@comment If close to planet, returns the current altitude
    ---@return number Altitude in meters; 0 if not close to a planet!
    function o.Altitude()
        local p = o.GetAtlasPlanet(o.PlanetId())
        if not p or not p.center then return 0 end
        return (o.WorldPosVec3() - vec3(p.center)):len() - (p.radius or 0)
    end

    ---@comment Returns distance between
    --- a) current construct position and the one passed in
    ---   posStr (distTo not specified) in ::pos{0,x,...} format!
    --- OR
    --- b) both params specified, each separate coords.
    ---@param posStr string ::pos() string to measure FROM
    ---@param distTo nil optional ::pos() to measure TO; if empty -> current position
    ---@return number
    function o.GetDistance(posStr, distToStr)
        local curPos = o.WorldPosVec3()
        if type(distToStr) == "string" then
            curPos = o.MapPosToWorldPos(distToStr)
        elseif type(distToStr) == "table" then
            curPos = vec3(distToStr)
        end
        local wPos = o.MapPosToWorldPos(posStr)
        local dist = vec3(wPos - curPos):len()
        return dist
    end

    ---@comment experimental/unused; credit to Jeronimo
    ---@return number,number,number with x,y,z
    function o.World2local(x,y,z)
        --if not o.construct then return 0,0,0 end
        local cWOUP = s.construct.getWorldOrientationUp()
        local cWOF = s.construct.getWorldOrientationForward()
        local cWOR = s.construct.getWorldOrientationRight()
        local cWOUPx, cWOUPy, cWOUPz = cWOUP[1], cWOUP[2], cWOUP[3]
        local cWOFx, cWOFy, cWOFz = cWOF[1], cWOF[2], cWOF[3]
        local cWORx, cWORy, cWORz = cWOR[1], cWOR[2], cWOR[3]

        local v = library.systemResolution3(
            {cWORx,  cWORy, cWORz},
            {cWOFx,  cWOFy, cWOFz},
            {cWOUPx, cWOUPy, cWOUPz},
            {x, y, z})
        return v[1],v[2],v[3]
    end

    ---@param v table the vec3() position to convert
    ---@return any MapPos table or nil
    function o.WorldToMapPos(v)
        local body = o.GetClosestPlanet(v)
        if not body or not body.center or not body.radius then
            return { systemId = 0, id = 0, latitude = v.x, longitude = v.y, altitude = v.z }
        end
        local coords = v - vec3(body.center)
        local dist = coords:len()
        local alt = dist - body.radius
        local latitude = 0
        local longitude = 0
        if not float_eq(dist, 0) then
            local phi = atan(coords.y, coords.x)
            --phi >= 0 ???
            longitude = phi or (2 * mpi + phi)
            latitude = mpi / 2 - macos(coords.z / dist)
        end
        return {
            latitude  = mdeg(latitude),
            longitude = mdeg(longitude),
            altitude  = alt,
            id        = body.systemId,
            systemId  = body.id }
    end

    function o.PlanetByName(name)
        if type(name) ~= "string" or name == "" then return nil end
        name = name:lower()
        if s.planetNames[name] then
            local pid = tonum(s.planetNames[name])
            return WaypointInfo[0][pid]
        end
        return nil
    end

    ---comment Converts ::pos{} string into vec3
    ---@param posStr string ::pos{} string
    ---@return any vec3() or nil
    function o.MapPosToWorldPos(posStr)
        local p = o.SplitPos(posStr)
        if not p or not p.systemId then return nil end
        if (p.systemId == 0 and p.id == 0) then -- already WorldPos
            return vec3(p.latitude, p.longitude, p.altitude)
        end
        if not WaypointInfo[p.systemId] then return nil end
        local planet = WaypointInfo[p.systemId][p.id]
        --credits to Saga for lat/lon calc
        local lat = constants.deg2rad * uclamp(p.latitude, -90, 90)
        local lon = constants.deg2rad * (p.longitude % 360)
        local xproj = cos(lat)
        local planetxyz = vec3(xproj*cos(lon), xproj*msin(lon), msin(lat))
        return vec3(planet.center) + (planet.radius + p.altitude) * planetxyz
    end

    function o.PlanetInfo(id)
        local pid = nil
        if type(id) == "string" and id:len() == 0 then
            id = o.GetClosestPlanetId(o.WorldPosVec3())
        end
        if type(id) == "string" and s.planetNames[id:lower()] then -- id as planet name
            pid = tonum(s.planetNames[id:lower()])
        elseif type(id) == "number" and tonum(id) > 0 then -- id as planet id
            pid = tonum(id)
        end
        if pid == nil then
            return E("[E] No valid planet name or id specified!")
        end
        local p = o.GetAtlasPlanet(pid)
        if not p or type(p.name) ~= "table" then
            return E("[E] No planet found!")
        end
        P"~~~~~~~~ PLANET INFO ~~~~~~~~"
        if id == '' then
          P("Hint: '/planetInfo 2' for Alioth")
        end
        P("Name: "..p.name[1].." (Id: ".. p.id ..")")
        P("Center: "..p.center[1].." / "..p.center[2].." / "..p.center[3])
        P("Radius: "..(p.radius or 0).."m")
        local tmp = ""
        if p.gravity and p.gravity > 0 then
            tmp = " ("..sformat("%.1f", (p.gravity / s.Alioth1G)) .." g)"
        end
        P("Gravity: "..(p.gravity or 0)..tmp)
        if p.satellites and #p.satellites > 0 then
          P("Has Moons: "..#p.satellites)
        end
        P("Surface Min Alt.: "..(p.surfaceMinAltitude or 0).."m")
        P("Surface Max Alt.: "..(p.surfaceMaxAltitude or 0).."m")
        P("Max Static Alt.: "..(p.maxStaticAltitude or "").."m")
        P("Has atmosphere: "..BoolStr(p.hasAtmosphere))
        if p.hasAtmosphere then
          P("Atmo Thickness: "..(p.atmosphereThickness or 0).."m")
          P("Atmo altitude: "..(p.atmoAltitude or 0).."m")
          P("Atmo 10%: "..(p.atmo10 or 0).."m")
        end
        P("Is in Safe Zone: "..BoolStr(p.isInSafeZone))
        P"~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    end

    ---@comment Adds a named waypoint to the internal list.
    --- Source position string can be local or world position.
    --- World position will be converted to local and ::pos{}
    --- changed accordingly - IF a closest body was in range.
    ---@param posString string Local or world ::pos{} string
    ---@param wpName string Name of the newly named waypoint
    ---@return boolean true if added else false
    function o.CreateWaypoint(posString, wpName)
        if not s.wm or not wpName or wpName == '' or s.waypointNames[wpName] then
            return false
        end

        -- convert between local and world pos if needed
        local p = o.SplitPos(posString)
        if not p or not p.systemId then return false end

        local pcenter = { p.latitude, p.longitude, p.altitude }
        -- if world pos, try to determine planet
        if p.id == 0 then
            local w = o.WorldToMapPos(vec3(pcenter))
            if w and w.id and w.id > 0 then
                -- update pos with converted values
                p.latitude  = w.latitude
                p.longitude = w.longitude
                p.altitude  = w.altitude
                p.id        = w.id
                p.systemId  = w.systemId
                posString = o.MapPos2String(p)
            end
        else
            local v = o.MapPosToWorldPos(posString)
            pcenter = { v.x, v.y, v.z }
        end

        -- add waypoint to waypoint manager
        local wp = Waypoint:new(s.wm):setName(wpName):set(posString)
        if not wp or wp == {} then return false end
        if s.wm:exists(wp) then return false end
        return s.wm:add(wp)
    end

    ---@comment Simple test for coord conversion
    function o.ConversionTest()
        local p1 = "::pos{0,2,35.5118,104.0375,285.3076}"
        local w1 = o.MapPosToWorldPos(p1)
        P("HQ local to world:\n"..p1.." =")
        P(o.Vec3ToPosString(w1))
        local w2 = o.WorldToMapPos(w1)
        Out.DeepPrint(w2)
        P("World to local (should show same as above):")
        P(o.MapPos2String(w2))

        local wp = "::pos{0,0,-24955.2183,99771.5731,-52908.1353}"
        if o.CreateWaypoint(wp, "WorldPos") then
          P("Added 'WorldPos' waypoint")
        else
          P("Failed to add test waypoint!")
        end
    end

    local function init()
        s.pIdx = 0
        s.p = o.GetAtlasPlanet(o.PlanetId())
        if s.p then s.pIdx = s.p.id end
        if not WaypointInfo[0] then return end
        s.planetNames = {}
        for i, v in pairs(WaypointInfo[0]) do
            s.planetNames[v.name[1]:lower()] = i
            -- remove junk
            WaypointInfo[0][i].biosphere = nil
            WaypointInfo[0][i].classification = nil
            WaypointInfo[0][i].description = nil
            WaypointInfo[0][i].habitability = nil
            WaypointInfo[0][i].ores = nil
            -- new props
            if v.hasAtmosphere then
                local res = v.atmosphereRadius - v.radius
                WaypointInfo[0][i].atmoAltitude = res
                WaypointInfo[0][i].atmo10 = res * 0.9
            end
            WaypointInfo[0][i].isAsteroid = WaypointInfo[0][i].type[1] == "Asteroid"
            WaypointInfo[0][i].isMoon = WaypointInfo[0][i].type[1] == "Moon"
            WaypointInfo[0][i].isPlanet = WaypointInfo[0][i].type[1] == "Planet"
        end

        --s.wm = WaypointMgr.new("MAIN")
        if s.wm then
            P("[I] WaypointMgr assigned: "..s.wm:getName())
        else
            P("[E] NO WaypointMgr assigned!")
        end
    end

    init()
    return setmetatable(s, o)
end -- .New

return o
end)
package.preload['YFS-Tools:startup.lua']=(function()
---@diagnostic disable: undefined-field
local onlyForRoute=""--export: Load waypoints only for this route (enclosed in double quotes!)
local onlySelectableWP=false--export: Check to only display custom route waypoints that are marked as selectable
local loadWaypoints=true--export: Enable to load custom waypoints from databank
local outputFont="FiraMono"--export: Name of font used for screen output. Default: "FiraMono"

onlyForRoute = onlyForRoute or ""
OutputFont = outputFont or "FiraMono"

P("=========================================")
P("YFS-Tools 1.5 (unofficial)")
P("created by tobitege (c) 2023")
P("Thanks to Yoarii (SVEA) for YFS and LUA help!")
P("YFS 1.4+ databank link required (Routes).")
P("=========================================")
P("* WARNING: do not run commands that change")
P("* waypoints/routes while YFS runs!")
P("=========================================")
P("LUA parameter(s):")
P("Load waypoints from databank: " .. BoolStr(loadWaypoints))
P("Only waypoints for route: " .. onlyForRoute)
P("Only selectable waypoints: " .. BoolStr(onlySelectableWP))
P("Screen output font name: " .. OutputFont)
P("=========================================")

local status, err = false, nil
if INGAME then
    status, err, _ = xpcall(function()
        Config.core = library.getCoreUnit()
        Config.databanks = library.getLinksByClass('DataBank', true) -- true is important!
        Config.screens = library.getLinksByClass('Screen', true)
    end, Traceback)
    if not status then
        P("Error in Link Detection:\n" .. err)
        unit.exit()
        return
    end
else
    -- this requires du-mocks
    Config.core = unit.core
    Config.databanks =  { unit.databank }
    Config.screens =  { unit.screen }
end

if Config.core == nil then
    P("[E] No Core connected! Ending script.")
    unit.exit()
    return
end

PM = require('YFS-Tools:../util/pos.lua').New(Config.core, construct, WM) -- Positions and waypoint management

if #Config.databanks > 0 then
    local plural = ""
    if #Config.databanks > 1 then plural = "s" else plural = " '"..Config.databanks[1].getName().."'" end
    P(#Config.databanks .. " databank" .. plural .. " connected.")
else
    P("[E] DataBank not found.")
end

if #Config.screens > 0 then
    local plural = ""
    if #Config.screens > 1 then plural = "s" end
    P(#Config.screens .. " screen" .. plural .. " connected.")
end

-- load waypoints from databank(s) (ArchHUD or YFS)?
if loadWaypoints ~= true then
    P("[I] Waypoints loading is off.")
elseif #Config.databanks > 0 then
    local prevCount = 0
    for ix=1, #Config.databanks, 1 do
        ---@diagnostic disable-next-line: assign-type-mismatch
        local db = Config.databanks[ix] ---@type table DataBank
        P("===== Checking db '"..db.getName().."' =====")
        if db.hasKey(ARCH_SAVED_LOCATIONS) then
            P('ArchHud databank detected.')
            DetectedArch = ix
            local names = db.getStringValue(ARCH_SAVED_LOCATIONS)
            if names ~= "" then
                P('Searching stored locations...')
                local locations = json.decode(names)
                if IsTable(locations) then
                    Cmd.GetStoredLocations(locations)
                end
            end
        end
        if db.hasKey(YFS_ROUTES) or db.hasKey(YFS_NAMED_POINTS) then
            P('YFS databank detected.')
            YFSDB = Dtbk.new(db)
            DetectedYFS = true
            if not onlySelectableWP then
                Cmd.YFSLoadNamedWaypoints()
            end
            Cmd.YFSLoadRoutepoints(onlySelectableWP, onlyForRoute)
        end
        local count = PM.GetWaypointCount()
        if count == prevCount then
            P("[I] No waypoints loaded from db "..ix)
        else
            P("[I] "..(count - prevCount).." waypoints loaded from db "..ix)
        end
        prevCount = PM.GetWaypointCount()
    end
    P("=======================")
    if PM.GetWaypointCount() > 0 then
        P("[I] Total "..PM.GetWaypointCount().." waypoints loaded.")
    else
        P("[I] No waypoints loaded.")
    end
    P("=======================")
end
end)
package.preload['YFS-Tools:sys_onInputText.lua']=(function()
-- requires utils, global instances Cmd, SU

local inputTextFunc = {}

function inputTextFunc.Run(t)
    if not SU.StartsWith(t, "/") then return end
    if not Cmd then
        return E("[FATAL ERROR] Commands processor not assigned!")
    end
    local cmdList = {}
    cmdList['arch-save-named'] = 1
    cmdList['conversionTest'] = 1
    cmdList['posData'] = 1
    cmdList['help'] = 'Help'
    cmdList['planetInfo'] = 1
    cmdList['printAltitude'] = 1
    cmdList['printPos'] = 1
    cmdList['printWorldPos'] = 1
    cmdList['warpCost'] = 1
    cmdList['wp-altitude-ceiling'] = 1
    cmdList['wp-export'] = 1
    cmdList['yfs-add-altitude-wp'] = 1
    cmdList['yfs-build-route-from-wp'] = 1
    cmdList['yfs-save-named'] = 1
    cmdList['yfs-save-route'] = 1
    cmdList['yfs-replace-wp'] = 1
    cmdList['yfs-route-altitude'] = 1
    cmdList['yfs-route-nearest'] = 1
    cmdList['yfs-route-to-named'] = 1
    cmdList['yfs-wp-altitude'] = 1
    cmdList['DumpRoutes'] = 1
    cmdList['DumpPoints'] = 1
    cmdList['routes'] = 1
    if DEBUG then
        cmdList['YfsTestData'] = 1
        cmdList['x'] = 1
    end

    for k, func in pairs(cmdList) do
        if SU.StartsWith(t, "/"..k) then
            local params = t:sub(k:len()+2) or ""
            params = SU.Trim(params)
            if k == 'help' then -- special case
                k = "PrintHelp"
            end
            -- map command to function name, which must end with "Cmd"!
            local fn = SU.SplitAndCapitalize(k,'-').."Cmd"
            -- default use global Cmd class, unless a value is specified other than 1
            local cmdName = SU.If(type(func) == "string", func, "Cmd")
            P("Executing /"..k..SU.If(params ~= "", " with: "..params))
            if not _G[cmdName] then
                return E("[FATAL ERROR] "..cmdName.." not found!")
            end
            if _G[cmdName][fn] then
                return _G[cmdName][fn](params)
            end
        end
    end
    P("~~~~~~~~~~~~~~~~~~~~~")
    P("[E] Unknown command: "..t)
    P("[I] Supported commands:")
    for _,fn in ipairs(GetSortedAssocKeys(cmdList)) do
       P("/"..fn)
    end
end

return inputTextFunc
end)
package.preload['YFS-Tools:../util/wpointer/wpointer0.lua']=(function()
function LinkedList(name, prefix)
    local functions = {}
    local internalDataTable = {}
    local internalTableSize = 0
    local removeKey,addKey,indexKey,refKey = prefix .. 'Remove',prefix .. 'Add',prefix..'index',prefix..'ref'

    functions[removeKey] = function (node)
        local tblSize,internalDataTable = internalTableSize,internalDataTable
        if tblSize > 1 then
            if node[indexKey] == -1 then return end
            local lastElement,replaceNodeIndex = internalDataTable[tblSize],node[indexKey]
            internalDataTable[replaceNodeIndex] = lastElement
            internalDataTable[tblSize] = nil
            lastElement[indexKey] = replaceNodeIndex
            internalTableSize = tblSize - 1
            node[indexKey] = -1
            node[refKey] = nil
        elseif tblSize == 1 then
            internalDataTable[1] = nil
            internalTableSize = 0
            node[indexKey] = -1
            node[refKey] = nil
        end
    end

    functions[addKey] = function (node, override)
        local indexKey,refKey = indexKey,refKey
        if node[indexKey] and node[indexKey] ~= -1 then
            if not node[refKey] == functions or override then
                node[refKey][removeKey](node)
            else
                return
            end
        end
        local tblSize = internalTableSize + 1
        internalDataTable[tblSize] = node
        node[indexKey] = tblSize
        node[refKey] = functions
        internalTableSize = tblSize
    end

    functions[prefix .. 'GetData'] = function ()
        return internalDataTable, internalTableSize
    end

    return functions
end

local math = math
local sin, cos, rad, type = math.sin,math.cos,math.rad, type

function RotMatrixToQuat(m1,m2,m3)
    local m11,m22,m33 = m1[1],m2[2],m3[3]
    local t=m11+m22+m33
    if t>0 then
        local s=0.5/(t+1)^(0.5)
        return (m2[3]-m3[2])*s,(m3[1]-m1[3])*s,(m1[2]-m2[1])*s,0.25/s
    elseif m11>m22 and m11>m33 then
        local s = 1/(2*(1+m11-m22-m33)^(0.5))
        return 0.25/s,(m2[1]+m1[2])*s,(m3[1]+m1[3])*s,(m2[3]-m3[2])*s
    elseif m22>m33 then
        local s=1/(2*(1+m22-m11-m33)^(0.5))
        return (m2[1]+m1[2])*s,0.25/s,(m3[2]+m2[3])*s,(m3[1]-m1[3])*s
    else
        local s=1/(2*(1+m33-m11-m22)^(0.5))
        return (m3[1]+m1[3])*s,(m3[2]+m2[3])*s,0.25/s,(m1[2]-m2[1])*s
    end
end

function GetQuaternion(x,y,z,w)
    if type(x) == 'number' then
        if w == nil then
            if x == x and y == y and z == z then
                local rad,sin,cos = rad,sin,cos
                x,y,z = -rad(x * 0.5),rad(y * 0.5),-rad(z * 0.5)
                local sP,sH,sR=sin(x),sin(y),sin(z)
                local cP,cH,cR=cos(x),cos(y),cos(z)
                return (sP*cH*cR-cP*sH*sR),(cP*sH*cR+sP*cH*sR),(cP*cH*sR-sP*sH*cR),(cP*cH*cR+sP*sH*sR)
            else
                return 0,0,0,1
            end
        else
            return x,y,z,w
        end
    elseif type(x) == 'table' then
        if #x == 3 then
            local x,y,z,w = RotMatrixToQuat(x, y, z)
            return x,y,z,-w
        elseif #x == 4 then
            return x[1],x[2],x[3],x[4]
        else
            print('Unsupported Rotation!')
        end
    end
end
function QuaternionMultiply(ax,ay,az,aw,bx,by,bz,bw)
    return ax*bw+aw*bx+ay*bz-az*by,
    ay*bw+aw*by+az*bx-ax*bz,
    az*bw+aw*bz+ax*by-ay*bx,
    aw*bw-ax*bx-ay*by-az*bz
end

function RotatePoint(ax,ay,az,aw,oX,oY,oZ,wX,wY,wZ)
    local t1,t2,t3 = 2*(ax*oY - ay*oX),2*(ax*oZ - az*oX),2*(ay*oZ - az*oY)
    return 
    oX + ay*t1 + az*t2 + aw*t3 + wX,
    oY - ax*t1 - aw*t2 + az*t3 + wY,
    oZ + aw*t1 - ax*t2 - ay*t3 + wZ
end

function GetRotationManager(out_rotation, wXYZ, name)
    --====================--
    --Local Math Functions--
    --====================--
    local print,type,unpack,multiply,rotatePoint,getQuaternion = DUSystem.print,type,table.unpack,QuaternionMultiply,RotatePoint,GetQuaternion

    local superManager,needsUpdate,notForwarded,needNormal = nil,false,true,false
    local outBubble = nil
    --=================--
    --Positional Values--
    --=================--
    local pX,pY,pZ = wXYZ[1],wXYZ[2],wXYZ[3] -- These are original values, for relative to super rotation
    local positionIsRelative = false
    local doRotateOri,doRotatePos = true,true
    local posY = math.random()*0.00001

    --==================--
    --Orientation Values--
    --==================--
    local tix,tiy,tiz,tiw = 0,0,0,1 -- temp intermediate rotation values

    local ix,iy,iz,iw = 0,0,0,1 -- intermediate rotation values
    local nx,ny,nz = 0,1,0

    local subRotQueue = {}
    local subRotations = LinkedList(name, 'sub')

    --==============--
    --Function Array--
    --==============--
    local out = {}

    --=======--
    --=Cache=--
    --=======--
    local cache = {0,0,0,1,0,0,0,0,0,0}

    --============================--
    --Primary Processing Functions--
    --============================--
    local function process(wx,wy,wz,ww,lX,lY,lZ,lTX,lTY,lTZ)
        if not wx then
            wx,wy,wz,ww,lX,lY,lZ,lTX,lTY,lTZ = unpack(cache)
        else
            cache = {wx,wy,wz,ww,lX,lY,lZ,lTX,lTY,lTZ}
        end
        local dx,dy,dz = pX,pY,pZ
        if not positionIsRelative then
            dx,dy,dz = dx - lX, dy - lY, dz - lZ
        end
        if doRotatePos then
            wXYZ[1],wXYZ[2],wXYZ[3] = rotatePoint(wx,wy,wz,-ww,dx,dy,dz,lTX,lTY,lTZ)
        else
            wXYZ[1],wXYZ[2],wXYZ[3] = dx+lTX,dy+lTY,dz+lTZ
        end

        ix = ix or 1
        iy = iy or 1
        iz = iz or 1
        iw = iw or 1
        if doRotateOri then
            wx,wy,wz,ww = multiply(ix or 1,iy or 1,iz or 1,iw,wx,wy,wz,ww)
        else
            wx,wy,wz,ww = ix,iy,iz,iw
        end

        out_rotation[1],out_rotation[2],out_rotation[3],out_rotation[4] = wx,wy,wz,ww
        if needNormal then
            nx,ny,nz = 2*(wx*wy+wz*ww),1-2*(wx*wx+wz*wz),2*(wy*wz-wx*ww)
        end
        local subRots,subRotsSize = subRotations.subGetData()

        for i=1, subRotsSize do
            subRots[i].update(wx,wy,wz,ww,pX,pY,pZ,wXYZ[1],wXYZ[2],wXYZ[3])
        end
        needsUpdate = false
        notForwarded = true
    end
    out.update = process
    local function validate()
        if not superManager then
            process()
        else
            superManager.bubble()
        end
    end
    local function rotate()
        local tx,ty,tz,tw = getQuaternion(tix,tiy,tiz,tiw)
        if tx ~= ix or ty~= iy or tz ~= iz or tw ~= iw then
            ix, iy, iz, iw = tx, ty, tz, tw
            validate()
            out.bubble()
            return true
        end
        return false
    end
    function out.enableNormal()
        needNormal = true
    end
    function out.disableNormal()
        needNormal = false
    end
    function out.setSuperManager(rotManager)
        superManager = rotManager
        if not rotManager then
            cache = {0,0,0,1,0,0,0,0,0,0}
            needsUpdate = true
        end
    end
    function out.addToQueue(func)
        if not needsUpdate then
            subRotQueue[#subRotQueue+1] = func
        end
    end

    function out.addSubRotation(rotManager)
        rotManager.setSuperManager(out)
        subRotations.subAdd(rotManager, true)
        out.bubble()
    end
    function out.remove()
        if superManager then
            superManager.removeSubRotation(out)
            out.setSuperManager(false)
            out.bubble()
        end
    end
    function out.removeSubRotation(sub)
        sub.setSuperManager(false)
        subRotations.subRemove(sub)
    end
    function out.bubble()
        if superManager and not needsUpdate then
            subRotQueue = {}
            needsUpdate = true
            notForwarded = false
            superManager.addToQueue(process)
        else
            needsUpdate = true
        end
    end

    function out.checkUpdate()
        local neededUpdate = needsUpdate
        if neededUpdate and notForwarded then
            process()
            subRotQueue = {}
        elseif notForwarded then
            for i=1, #subRotQueue do
                subRotQueue[i]()
            end
            subRotQueue = {}
        elseif superManager then
            superManager.checkUpdate()
        end
        return neededUpdate
    end
    local outBubble = out.bubble
    local function assignFunctions(inFuncArr,specialCall)
        inFuncArr.update = process
        function inFuncArr.getPosition() return pX,pY,pZ end
        function inFuncArr.getRotationManger() return out end
        function inFuncArr.getSubRotationData() return subRotations.subGetData() end
        inFuncArr.checkUpdate = out.checkUpdate
        function inFuncArr.setPosition(tx,ty,tz)
            if type(tx) == 'table' then
                tx,ty,tz = tx[1],tx[2],tx[3]
            end
            if not (tx ~= tx or ty ~= ty or tz ~= tz)  then
                local tmpY = (ty or 0)+posY
                if pX ~= tx or pY ~= tmpY or pZ ~= tz then
                    pX,pY,pZ = tx,tmpY,tz
                    outBubble()
                    return true
                end
            end
            return false
        end
        function inFuncArr.getNormal()
            return nx,ny,nz
        end
        function inFuncArr.rotateXYZ(rotX,rotY,rotZ,rotW)
            if rotX and rotY and rotZ then
                tix,tiy,tiz,tiw = rotX,rotY,rotZ,rotW
                rotate()
                if specialCall then specialCall() end
            else
                if type(rotX) == 'table' then
                    if #rotX == 3 then
                        ---@diagnostic disable-next-line: cast-local-type
                        tix,tiy,tiz,tiw = rotX[1],rotX[2],rotX[3],nil
                        local result = rotate()
                        if specialCall then specialCall() end
                        goto valid
                    end
                end
                ---@diagnostic disable-next-line: param-type-mismatch
                system.print('Invalid format. Must be three angles, or right, forward and up vectors, or a quaternion. Use radians if angles.')
                ::valid::
                return false
            end
        end

        ---@diagnostic disable-next-line: cast-local-type
        function inFuncArr.rotateX(rotX) tix = rotX; tiw = nil; rotate(); if specialCall then specialCall() end end
        ---@diagnostic disable-next-line: cast-local-type
        function inFuncArr.rotateY(rotY) tiy = rotY; tiw = nil; rotate(); if specialCall then specialCall() end end
        ---@diagnostic disable-next-line: cast-local-type
        function inFuncArr.rotateZ(rotZ) tiz = rotZ; tiw = nil; rotate(); if specialCall then specialCall() end end

        function inFuncArr.setDoRotateOri(rot) doRotateOri = rot; outBubble() end
        function inFuncArr.setDoRotatePos(rot) doRotatePos = rot; outBubble() end

        function inFuncArr.setPositionIsRelative(isRelative) positionIsRelative = isRelative; outBubble() end
        function inFuncArr.getRotation() return ix, iy, iz, iw end
    end
    out.assignFunctions = assignFunctions

    return out
end
end)
package.preload['YFS-Tools:../util/wpointer/wpointer1.lua']=(function()
function WPointer(x,y,z, radius, name, type, localeType, subId)
    local sqrt,floor,max,round=math.sqrt,math.floor,math.max,Round
    local getCWorldPos,getCMass = construct.getWorldPosition,construct.getMass

    local keyframe = 0
    local self = {
        radius = radius,
        x = x,
        y = y,
        z = z,
        name = name,
        type = type,
        localeType = localeType,
        subId = subId,
        keyframe = keyframe
    }

    function self.getWaypointInfo()
        ---@diagnostic disable-next-line: missing-parameter
        local cid = construct.getId()
        local cPos = getCWorldPos(cid)
        ---@diagnostic disable-next-line: need-check-nil
        local px,py,pz = self.x-cPos[1], self.y-cPos[2], self.z-cPos[3]
        local distance = sqrt(px*px + py*py + pz*pz)
        local warpCost = 0
        -- min 2 SU, max 500 SU (1 SU = 200000 m)
        if distance > 400000 and distance <= 100000000 then
            local tons = getCMass(cid) / 1000
            warpCost = max(floor(tons*floor(((distance/1000)/200))*0.00024), 1)
        end
        local disR = round(distance, 4)
        if DEBUG then P("getWaypointInfo") end
        return self.name, round((distance/1000)/200, 4), warpCost, round((distance/1000), 4), disR
    end

    return self
end
end)
package.preload['YFS-Tools:../util/wpointer/wpointer2.lua']=(function()
PositionTypes = {
    globalP=false,
    localP=true
}
OrientationTypes = {
    globalO=false,
    localO=true 
}
local print = DUSystem.print
function ObjectGroup(objects, transX, transY)
    objects = objects or {}
    local self={style='',gStyle='',class='default', objects=objects,transX=transX,transY=transY,enabled=true,glow=false,gRad=10,scale = false,isZSorting=true}
    function self.addObject(object, id)
        id=id or #objects+1
        objects[id]=object
        return id
    end
    function self.removeObject(id) objects[id] = {} end

    function self.hide() self.enabled = false end
    function self.show() self.enabled = true end
    function self.isEnabled() return self.enabled end
    function self.setZSort(isZSorting) self.isZSorting = isZSorting end

    function self.setClass(class) self.class = class end
    function self.setStyle(style) self.style = style end
    function self.setGlowStyle(gStyle) self.gStyle = gStyle end
    function self.setGlow(enable,radius,scale) self.glow = enable; self.gRad = radius or self.gRad; self.scale = scale or false end 
    return self
end
ConstructReferential = GetRotationManager({0,0,0,1},{0,0,0}, 'Construct')
ConstructReferential.assignFunctions(ConstructReferential)
ConstructOriReferential = GetRotationManager({0,0,0,1},{0,0,0}, 'ConstructOri')
ConstructOriReferential.assignFunctions(ConstructOriReferential)
function Object(posType, oriType)

    local multiGroup,singleGroup,uiGroups={},{},{}
    local positionType=positionType
    local orientationType=orientationType
    local ori = {0,0,0,1}
    local position = {0,0,0}
    local objRotationHandler = GetRotationManager(ori,position, 'Object Rotation Handler')

    local self = {
        true, -- 1
        multiGroup, -- 2
        singleGroup, -- 3
        uiGroups, -- 4
        ori, -- 5
        position, -- 6
        oriType, -- 7
        posType -- 8
    }
    objRotationHandler.assignFunctions(self)
    self.setPositionIsRelative(true)
    self.setPositionIsRelative = nil
    function self.hide() self[1] = false end
    function self.show() self[1] = true end

    local loadUIModule = LoadUIModule
    if loadUIModule == nil then
        --print('No UI Module installed.')
        loadUIModule = function() end
    end
    local loadPureModule = LoadPureModule
    if loadPureModule == nil then
        --print('No Pure Module installed.')
        loadPureModule = function() end
    end

    loadPureModule(self, multiGroup, singleGroup)
    loadUIModule(self, uiGroups, objRotationHandler)
    local function choose()
        objRotationHandler.remove()
        local oriType,posType = self[7],self[8]
        if oriType and posType then
            ConstructReferential.addSubRotation(objRotationHandler)
        elseif oriType then
            ConstructOriReferential.addSubRotation(objRotationHandler)
        end
        self.setDoRotateOri(oriType)
        self.setDoRotatePos(posType)
    end
    choose()
    function self.setOrientationType(orientationType)
        self[7] = orientationType
        choose()
    end
    function self.setPositionType(positionType)
        self[8] = positionType
        choose()
    end
    function self.GetRotationManager()
        return objRotationHandler
    end
    function self.addSubObject(object)
        return objRotationHandler.addSubRotation(object.GetRotationManager())
    end
    function self.removeSubObject(id)
        objRotationHandler.removeSubRotation(id)
    end

    return self
end

function ObjectBuilderLinear()
    local self = {}
    function self.setPositionType(positionType)
        local self = {}
        local positionType = positionType
        function self.setOrientationType(orientationType)
            local self = {}
            local orientationType = orientationType
            function self.build()
                return Object(positionType, orientationType)
            end
            return self
        end
        return self
    end
    return self
end
end)
package.preload['YFS-Tools:../util/wpointer/wpointer3.lua']=(function()
function LoadPureModule(self, singleGroup, multiGroup)
    function self.getMultiPointBuilder(groupId)
        local builder = {}
        local multiplePoints = LinkedList('','')
        multiGroup[#multiGroup+1] = multiplePoints
        function builder.addMultiPointSVG()
            local shown = false
            local pointSetX,pointSetY,pointSetZ={},{},{}
            local mp = {pointSetX,pointSetY,pointSetZ,false,false}
            local self={}
            local pC=1
            function self.show()
                if not shown then
                    shown = true
                    multiplePoints.Add(mp)
                end
            end
            function self.hide()
                if shown then
                    shown = false
                    multiplePoints.Remove(mp)
                end
            end
            function self.addPoint(point)
                pointSetX[pC]=point[1]
                pointSetY[pC]=point[2]
                pointSetZ[pC]=point[3]
                pC=pC+1
                return self
            end
            function self.setPoints(bulk)
                for i=1,#bulk do
                    local point = bulk[i]
                    pointSetX[i]=point[1]
                    pointSetY[i]=point[2]
                    pointSetZ[i]=point[3]
                end
                pC=#bulk+1
                return self
            end
            function self.setDrawFunction(draw)
                mp[4] = draw
                --system.print("getMultiPointBuilder.Draw() set")
                return self
            end
            function self.setData(dat)
                mp[5] = dat
                return self
            end
            function self.build()
                if pC > 1 then
                    multiplePoints.Add(mp)
                    shown = true
                else print("WARNING! Malformed multi-point build operation, no points specified. Ignoring.")
                end
            end
            return self
        end
        return builder
    end

    function self.getSinglePointBuilder(groupId)
        local builder = {}
        local points = LinkedList('','')
        singleGroup[#singleGroup+1] = points
        function builder.addSinglePointSVG()
            local shown = false
            local outArr = {false,false,false,false,false}

            function self.setPosition(px,py,pz)
                if type(px) == 'table' then
                    outArr[1],outArr[2],outArr[3]=px[1],px[2],px[3]
                else
                    outArr[1],outArr[2],outArr[3]=px,py,pz
                end
                return self
            end

            function self.setDrawFunction(draw)
                outArr[4] = draw
                --system.print("getSinglePointBuilder.Draw() set")
                return self
            end

            function self.setData(dat)
                outArr[5] = dat
                return self
            end

            function self.show()
                if not shown then
                    shown = true
                end
            end
            function self.hide()
                if shown then
                    points.Remove(outArr)
                    shown = false
                end
            end
            function self.build()
                points.Add(outArr)
                shown = true
                return self
            end
            return self
        end
        return builder
    end
end

function ProcessPureModule(zBC, singleGroup, multiGroup, zBuffer, zSorter,
        mXX, mXY, mXZ,
        mYX, mYY, mYZ,
        mZX, mZY, mZZ,
        mXW, mYW, mZW)
    for cG = 1, #singleGroup do
        local group = singleGroup[cG]
        local singleGroups,singleSize = group.GetData()
        for sGC = 1, singleSize do
            local singleGroup = singleGroups[sGC]
            local x,y,z = singleGroup[1], singleGroup[2], singleGroup[3]
            local pz = mYX*x + mYY*y + mYZ*z + mYW
            if pz < 0 then goto disabled end
            zBC = zBC + 1
            zSorter[zBC] = -pz
            zBuffer[-pz] = singleGroup[4]((mXX*x + mXY*y + mXZ*z + mXW)/pz,(mZX*x + mZY*y + mZZ*z + mZW)/pz,pz,singleGroup[5])
            ::disabled::
        end
    end
    for cG = 1, #multiGroup do
        local group = multiGroup[cG]
        local multiGroups,groupSize = group.GetData()
        for mGC = 1, groupSize do
            local multiGroup = multiGroups[mGC]

            local tPointsX,tPointsY,tPointsZ = {},{},{}
            local pointsX,pointsY,pointsZ = multiGroup[1],multiGroup[2],multiGroup[3]
            local size = #pointsX
            local mGAvg = 0
            for pC=1,size do
                local x,y,z = pointsX[pC],pointsY[pC],pointsZ[pC]
                local pz = mYX*x + mYY*y + mYZ*z + mYW
                if pz < 0 then
                    goto disabled
                end

                tPointsX[pC],tPointsY[pC] = (mXX*x + mXY*y + mXZ*z + mXW)/pz,(mZX*x + mZY*y + mZZ*z + mZW)/pz
                mGAvg = mGAvg + pz
            end
            local depth = -mGAvg/size
            zBC = zBC + 1
            zSorter[zBC] = depth
            zBuffer[depth] = multiGroup[4](tPointsX,tPointsY,depth,multiGroup[5])
            ::disabled::
        end
    end
    return zBC
end
end)
package.preload['YFS-Tools:../util/wpointer/wpointer4.lua']=(function()
---@diagnostic disable: missing-parameter
function Projector()
    -- Localize frequently accessed data
    local construct, player, system, math = DUConstruct, DUPlayer, DUSystem, math

    -- Internal Parameters
    local frameBuffer,frameRender,isSmooth,lowLatency = {'',''},true,true,true

    -- Localize frequently accessed functions
    --- System-based function calls
    local getWidth, getHeight, getTime, setScreen =
    system.getScreenWidth,
    system.getScreenHeight,
    system.getArkTime,
    system.setScreen

    --- Camera-based function calls
    local getCamWorldRight, getCamWorldFwd, getCamWorldUp, getCamWorldPos =
    system.getCameraWorldRight,
    system.getCameraWorldForward,
    system.getCameraWorldUp,
    system.getCameraWorldPos

    local getConWorldRight, getConWorldFwd, getConWorldUp, getConWorldPos = 
    construct.getWorldRight,
    construct.getWorldForward,
    construct.getWorldUp,
    construct.getWorldPosition

    --- Manager-based function calls
    ---- Quaternion operations
    local rotMatrixToQuat,quatMulti = RotMatrixToQuat,QuaternionMultiply

    -- Localize Math functions
    local tan, atan, rad = math.tan, math.atan, math.rad

    --- FOV Paramters
    local horizontalFov = system.getCameraHorizontalFov
    local fnearDivAspect = 0

    local objectGroups = LinkedList('Group', '')

    local self = {}

    function self.getSize(size, zDepth, max, min)
        local pSize = atan(size, zDepth) * fnearDivAspect
        if max then
            if pSize >= max then
                return max
            else
                if min then
                    if pSize < min then
                        return min
                    end
                end
                return pSize
            end
        end
        return pSize
    end

    function self.refresh() frameRender = not frameRender; end

    function self.setLowLatency(low) lowLatency = low; end

    function self.setSmooth(iss) isSmooth = iss; end

    function self.addObjectGroup(objectGroup) objectGroups.Add(objectGroup) end

    function self.removeObjectGroup(objectGroup) objectGroups.Remove(objectGroup) end

    function self.getSVG()
        local getTime, atan, sort, unpack, format, concat, quatMulti = getTime, atan, table.sort, table.unpack, string.format, table.concat, quatMulti
        local startTime = getTime(self)
        frameRender = not frameRender
        local isClicked = false
        if Clicked then
            Clicked = false
            isClicked = true
        end
        local isHolding = holding

        local buffer = {}

        local width,height = getWidth(), getHeight()
        local aspect = width/height
        local tanFov = tan(rad(horizontalFov() * 0.5))

        --- Matrix Subprocessing
        local nearDivAspect = (width*0.5) / tanFov
        fnearDivAspect = nearDivAspect

        -- Localize projection matrix values
        local px1 = 1 / tanFov
        local pz3 = px1 * aspect

        local pxw,pzw = px1 * width * 0.5, -pz3 * height * 0.5
        -- Localize screen info
        local objectGroupsArray,objectGroupSize = objectGroups.GetData()
        local svgBuffer,svgZBuffer,svgBufferCounter = {},{},0

        local processPure = ProcessPureModule
        local processUI = ProcessUIModule
        local processRots = ProcessOrientations
        local processEvents = ProcessActionEvents
        if processPure == nil then
            processPure = function(zBC) return zBC end
        end
        if processUI == nil then
            processUI = function(zBC) return zBC end
            processRots = function() end
            processEvents = function() end
        end
        local predefinedRotations = {}
        local camR,camF,camU,camP = getCamWorldRight(),getCamWorldFwd(),getCamWorldUp(),getCamWorldPos()
        camR = camR or {1,1,1}
        camF = camF or {1,1,1}
        camU = camU or {1,1,1}
        camP = camP or {1,1,1}
        do
            local cwr,cwf,cwu = getConWorldRight(),getConWorldFwd(),getConWorldUp()
            ConstructReferential.rotateXYZ(cwr,cwf,cwu)
            ConstructOriReferential.rotateXYZ(cwr,cwf,cwu)
            ConstructReferential.setPosition(getConWorldPos())
            ConstructReferential.checkUpdate()
            ConstructOriReferential.checkUpdate()
        end
        local vx,vy,vz,vw = rotMatrixToQuat(camR,camF,camU)

        local vxx,vxy,vxz,vyx,vyy,vyz,vzx,vzy,vzz = camR[1]*pxw,camR[2]*pxw,camR[3]*pxw,camF[1],camF[2],camF[3],camU[1]*pzw,camU[2]*pzw,camU[3]*pzw
        local ex,ey,ez = camP[1],camP[2],camP[3]
        local deltaPreProcessing = getTime() - startTime
        local deltaDrawProcessing, deltaEvent, deltaZSort, deltaZBufferCopy, deltaPostProcessing = 0,0,0,0,0
        P("getSvg "..objectGroupSize)
        for i = 1, objectGroupSize do
            local objectGroup = objectGroupsArray[i]
            if objectGroup.enabled == false then
                goto not_enabled
            end
            local objects = objectGroup.objects

            local avgZ, avgZC = 0, 0
            local zBuffer, zSorter, zBC = {},{}, 0

            local notIntersected = true
            for m = 1, #objects do
                local obj = objects[m]
                if not obj[1] then
                    goto is_nil
                end

                obj.checkUpdate()
                local objOri, objPos, oriType, posType  = obj[5], obj[6], obj[7], obj[8]
                local objX,objY,objZ = objPos[1]-ex,objPos[2]-ey,objPos[3]-ez
                local mx,my,mz,mw = objOri[1], objOri[2], objOri[3], objOri[4]
                local a,b,c,d = quatMulti(mx,my,mz,mw,vx,vy,vz,vw)
                local aa, ab, ac, ad, bb, bc, bd, cc, cd = 2*a*a, 2*a*b, 2*a*c, 2*a*d, 2*b*b, 2*b*c, 2*b*d, 2*c*c, 2*c*d
                local mXX, mXY, mXZ,
                      mYX, mYY, mYZ,
                      mZX, mZY, mZZ = 
                (1 - bb - cc)*pxw,    (ab + cd)*pxw,    (ac - bd)*pxw,
                (ab - cd),           (1 - aa - cc),     (bc + ad),
                (ac + bd)*pzw,        (bc - ad)*pzw,    (1 - aa - bb)*pzw

                local mWX,mWY,mWZ = ((vxx*objX+vxy*objY+vxz*objZ)),(vyx*objX+vyy*objY+vyz*objZ),((vzx*objX+vzy*objY+vzz*objZ))

                local processRotations = processRots(predefinedRotations,vx,vy,vz,vw,pxw,pzw)
                predefinedRotations[mx .. ',' .. my .. ',' .. mz .. ',' .. mw] = {mXX,mXZ,mYX,mYZ,mZX,mZZ}

                avgZ = avgZ + mWY
                local uiGroups = obj[4]

                -- Process Actionables
                local eventStartTime = getTime()
                obj.previousUI = processEvents(uiGroups, obj.previousUI, isClicked, isHolding, vyx, vyy, vyz, processRotations, ex,ey,ez, sort)
                local drawProcessingStartTime = getTime()
                deltaEvent = deltaEvent + drawProcessingStartTime - eventStartTime
                -- Progress Pure

                zBC = processPure(zBC, obj[2], obj[3], zBuffer, zSorter,
                    mXX, mXY, mXZ,
                    mYX, mYY, mYZ,
                    mZX, mZY, mZZ,
                    mWX, mWY, mWZ
                )
                -- Process UI
                zBC = processUI(zBC, uiGroups, zBuffer, zSorter,
                            vxx, vxy, vxz,
                            vyx, vyy, vyz,
                            vzx, vzy, vzz,
                            ex,ey,ez,
                        processRotations,nearDivAspect)
                deltaDrawProcessing = deltaDrawProcessing + getTime() - drawProcessingStartTime
                ::is_nil::
            end
            local zSortingStartTime = getTime()
            if objectGroup.isZSorting then
                sort(zSorter)
            end
            local zBufferCopyStartTime = getTime()
            deltaZSort = deltaZSort + zBufferCopyStartTime - zSortingStartTime
            local drawStringData = {}
            for zC = 1, zBC do
                drawStringData[zC] = zBuffer[zSorter[zC]]
            end
            local postProcessingStartTime = getTime()
            deltaZBufferCopy = deltaZBufferCopy + postProcessingStartTime - zBufferCopyStartTime
            if zBC > 0 then
                local dpth = avgZ / avgZC
                local actualSVGCode = concat(drawStringData)
                local beginning, ending = '', ''
                if isSmooth then
                    ending = '</div>'
                    if frameRender then
                        beginning = '<div class="second" style="visibility: hidden">'
                    else
                        beginning = '<style>.first{animation: f1 0.008s infinite linear;} .second{animation: f2 0.008s infinite linear;} @keyframes f1 {from {visibility: hidden;} to {visibility: hidden;}} @keyframes f2 {from {visibility: visible;} to { visibility: visible;}}</style><div class="first">'
                    end
                end
                local styleHeader = ('<style>svg{background:none;width:%gpx;height:%gpx;position:absolute;top:0px;left:0px;}'):format(width,height)
                local svgHeader = ('<svg viewbox="-%g -%g %g %g"'):format(width*0.5,height*0.5,width,height)

                svgBufferCounter = svgBufferCounter + 1
                svgZBuffer[svgBufferCounter] = dpth

                if objectGroup.glow then
                    local size
                    if objectGroup.scale then
                        size = atan(objectGroup.gRad, dpth) * nearDivAspect
                    else
                        size = objectGroup.gRad
                    end
                    svgBuffer[dpth] = concat({
                                beginning,
                                '<div class="', objectGroup.class ,'">',
                                styleHeader,
                                objectGroup.style,
                                '.blur { filter: blur(',size,'px) brightness(60%) saturate(3);',
                                objectGroup.gStyle, '}</style>',
                                svgHeader,
                                ' class="blur">',
                                actualSVGCode,'</svg>',
                                svgHeader, '>',
                                actualSVGCode,
                                '</svg></div>',
                                ending
                            })
                else
                    svgBuffer[dpth] = concat({
                                beginning,
                                '<div class="', objectGroup.class ,'">',
                                styleHeader,
                                objectGroup.style, '}</style>',
                                svgHeader, '>',
                                actualSVGCode,
                                '</svg></div>',
                                ending
                            })
                end
            end
            deltaPostProcessing = deltaPostProcessing + getTime() - postProcessingStartTime
            ::not_enabled::
        end
        --P("getSvg "..Out.DumpVar(svgZBuffer))

        sort(svgZBuffer)

        for i = 1, svgBufferCounter do
            buffer[i] = svgBuffer[svgZBuffer[i]]
        end

        if frameRender then
            frameBuffer[2] = concat(buffer)
            return concat(frameBuffer), deltaPreProcessing, deltaDrawProcessing, deltaEvent, deltaZSort, deltaZBufferCopy, deltaPostProcessing
        end
        if isSmooth then
            frameBuffer[1] = concat(buffer)
            if lowLatency then
---@diagnostic disable-next-line: param-type-mismatch
                setScreen('<div>Refresh Required</div>') -- magical things happen when doing this for some reason, some really, really weird reason.
            end
        else
            frameBuffer[1] = ''
        end
        return nil
    end

    return self
end
end)
package.preload['YFS-Tools:waypointer_lib.lua']=(function()
require('YFS-Tools:../util/wpointer/wpointer0.lua')
require('YFS-Tools:../util/wpointer/wpointer1.lua')
require('YFS-Tools:../util/wpointer/wpointer2.lua')
require('YFS-Tools:../util/wpointer/wpointer3.lua')
require('YFS-Tools:../util/wpointer/wpointer4.lua')
end)
package.preload['YFS-Tools:sys_onActionStartWp.lua']=(function()
local actionStartFunc = {}

function actionStartFunc.Run(action)
    if action == 'option1' then
        WaypointOpt = true
        return
    end
    if action == 'option2' then
        local projector = Projector()
        projector.refresh()
        return
    end
end

return actionStartFunc


end)
package.preload['YFS-Tools:unit_onTimer(update).lua']=(function()
local timerFunc = {}

function timerFunc.Run(timerId)
    if timerId == 'update' then
        local projector = Projector()
        local svg = projector.getSVG()
        ---@diagnostic disable-next-line: param-type-mismatch
        if svg then
            system.setScreen(svg)
        else
            P("[W] svg empty")
        end
    end
end

return timerFunc
end)
package.preload['YFS-Tools:waypointer_start.lua']=(function()
-- Original waypointer script (c) EasternGamer
-- tobitege: customisation to read YFS route waypoints
-- as well as ArchHud locations and add these for display

local lowLatencyMode=false--export: Enables low latency for screen render, which can sometimes bug out if a frame gets skipped. A restart is required then.
local smooth=false--export: Enables full FPS rendering, which increases the perceived performance for an actual performance impact
local highPerformanceMode=false--export: Disables glow effect which can in some cases improve FPS significantly
local glowRadius=3--export: Sets the pixel size of the glow effect
local displayWarpCells=false--export: Enable display of warp cells amount
local displaySolarWP=false--export: Enable display of solar objects (planets, moons)
local displayCustomWP=true--export: Enable display of custom waypoints (routes)
local archHudWaypointSize=0.5--export: The size in meters of a custom waypoint (0.1 - 10)
local archHudWPRender=3--export: The number of kilometers above which distance custom waypoints are not rendered
local maxWaypointSize=200--export: The max size of a waypoint in pixels
local minWaypointSize=20--export: The min size of a waypoint in pixels (max 300)
local infoHighlight=300--export: The number of pixels within info is displayed
local fontsize=30--export: Font size (default: 20)
local colorWarp="#ADD8E6"--export: RGB color of warpable waypoints. Default: "#ADD8E6"
local nonWarp="#FFA500"--export: RGB color of non-warpable waypoints. Default: "#FFA500"
local colorWaypoint="#32CD32"--export: RGB color of custom waypoints. Default: "#32CD32"

local format, sqrt, len, max, print, uclamp = string.format, math.sqrt, string.len, math.max, system.print, utils.clamp

local position = {0,0,0}
local offsetPos = {0,0,0}
local orientation = {0,0,0}
---@diagnostic disable-next-line: missing-parameter
local width = system.getScreenWidth() / 2
---@diagnostic disable-next-line: missing-parameter
local height = system.getScreenHeight() / 2
local objectBuilder = ObjectBuilderLinear()
fontsize = uclamp(fontsize, 10,40)
minWaypointSize = uclamp(minWaypointSize, 5, 200)
maxWaypointSize = uclamp(maxWaypointSize, minWaypointSize+1, 400)
archHudWaypointSize = uclamp((archHudWaypointSize or 0.5), 0.1, 10)

WaypointOpt = false

local localeIndex = {
    ['en-US'] = 1,
    ['fr-FR'] = 2,
    ['de-De'] = 3
}

local projector = Projector()
projector.setSmooth(smooth)

local waypointObjectGroup = ObjectGroup()
projector.addObjectGroup(waypointObjectGroup)

local css = [[
svg {
    stroke-width: 3;
    vertical-align:middle;
    text-anchor:start;
    fill: white;
    font-family: Refrigerator;
    font-size: ]] .. fontsize .. [[;
}]]
waypointObjectGroup.setStyle(css)

if not highPerformanceMode then
    waypointObjectGroup.setGlow(true, glowRadius)
end
if not lowLatencyMode then
    projector.setLowLatency(lowLatencyMode)
end
local function drawText(content,x, y, text, opacity,uD,c,c2,stroke)
    uD[c],uD[c+1],uD[c+2],uD[c+3],uD[c+4],uD[c+5] = x,y,opacity,opacity,stroke,text
    content[c2] = '<text x="%g" y="%g" fill-opacity="%g" stroke-opacity="%g" stroke="%s">%s</text>'
    return c+6,c2+1
end
local function drawHorizontalLine(content,x, y, length, thickness,dU,c,c2,stroke)
    dU[c],dU[c+1],dU[c+2],dU[c+3],dU[c+4]=thickness,stroke,x,y,length
    content[c2] = '<path fill="none" stroke-width="%g" stroke="%s" d="M%g %gh%g"/>'
    return c+5,c2+1
end
local maxD = sqrt(width*width + height*height)
local function drawInfo(content,tx, ty, data,dU,c,c1,stroke,distanceToMouse)
    local font = fontsize
    -- "distance" here is in SU!!!
    local name,distance,warpCost,disKM,disM = data.getWaypointInfo()
    local keyframe = data.keyframe
    c,c1 = drawHorizontalLine(content, tx, ty + 3, len(name)*(font*0.6), 2,dU,c,c1,stroke)
    c,c1 = drawText(content, tx, ty, name, 1,dU,c,c1,stroke)
    if distanceToMouse <= infoHighlight then
        if keyframe < 6 then
            data.keyframe = keyframe + 1
        end
    else
        if keyframe ~= 0 then
            data.keyframe = keyframe - 1
        end
    end
    local opacity = keyframe/6
    if distanceToMouse < 15 and WaypointOpt then
        system.setWaypoint('::pos{0,0,' .. data.x ..',' .. data.y .. ',' .. data.z ..'}')
        WaypointOpt = false
    end
    if keyframe > 0 then
        disM = disM or 0
        disKM = disKM or 0
        local disText = ''
        if disM <= 1000 then
            disText = disM .. ' m'
        elseif disKM <= 200 then
            disText = disKM .. ' km'
        else
            disText = distance .. ' SU'
        end
        local f5 = font + 5
        local kf = keyframe * 10
        local tx2 = tx + 80
        c,c1 = drawText(content, tx2 - kf, ty+f5, disText, opacity,dU,c,c1,stroke)
        if displayWarpCells and distance > 2 then
            c,c1 = drawText(content, tx2 - kf, ty+f5*2, data.localeType, opacity,dU,c,c1,stroke)
            c,c1 = drawText(content, tx2 - kf, ty+f5*3, warpCost .. ' Warp Cells', opacity,dU,c,c1,stroke)
        elseif data.localeType == 'WP' then
            c,c1 = drawText(content, tx2 - kf, ty+f5*2, 'Alt: '..(data.subId or 0), opacity,dU,c,c1,stroke)
        else
            c,c1 = drawText(content, tx2 - kf, ty+f5*2, data.localeType, opacity,dU,c,c1,stroke)
        end
    end
    return c
end
local concat,unpack = table.concat,table.unpack
local function draw(tx,ty,tz,data)
    local dU, c = {},1
    local content,c1 = {},1
    local distanceToMouse = sqrt(tx*tx + ty*ty)
    local r = data.radius
    local off = (((tz/1000)/200))/100
    local size = Round(max(projector.getSize(r, tz, 100000000, minWaypointSize) - off, 5),1)
    P("draw")

    --if size < 1 then return '' end
    local _,distance,_,_,disM = data.getWaypointInfo()
    if data.type == 'Planet' then -- or data.type == 'WP' then
        if (disM < 2) or (tz < 30) or (size >= maxWaypointSize) or (distanceToMouse > maxD) or
           (r==archHudWaypointSize*1.25 and tz>archHudWPRender*1000) then -- Don't display
          P("* "..size)
            return ''
        end
    elseif data.type == 'Moon' then
        if distance > 20 then return '' end
    else
        if distance > 10 then return '' end
    end

    local stroke = colorWarp
    if data.type == 'WP' then
        stroke = colorWaypoint
    elseif distance > 500 then
        stroke = nonWarp
    end
    content[c1] = '<circle cx="%g" cy="%g" r="%g" fill="%s" stroke="%s"/>'
    dU[c],dU[c+1] = tx,ty
    c=c+2
    if r==archHudWaypointSize*1.25 then
        size = size /2
        dU[c+1] = colorWarp
    else
        dU[c+1] = 'none'
    end
    dU[c] = size
    dU[c+2] = stroke
    c=c+3
    c=drawInfo(content, tx + size + 5, ty - size + 5, data,dU,c,c1+1,stroke,distanceToMouse)
    return concat(content):format(unpack(dU))
end

local solarWaypoints = objectBuilder
		.setPositionType(PositionTypes.globalP)
		.setOrientationType(OrientationTypes.globalO)
		.build()
waypointObjectGroup.addObject(solarWaypoints)
local builder = solarWaypoints.getSinglePointBuilder()
if displaySolarWP then
    ---@diagnostic disable-next-line: missing-parameter
    local localizationIndex = localeIndex[system.getLocale()]
    for k,stellar in pairs(WaypointInfo[0]) do
        local wCenter = stellar.center
        local wName = stellar.name[localizationIndex]
        local wRadius = stellar.radius
        local wType = stellar.type[1]
        local wlType = stellar.type[localizationIndex]
        local waypointObject = WPointer(wCenter[1],wCenter[2],wCenter[3],
                wRadius * 1.25, wName, wType, wlType, nil)
        local customSVG = builder.addSinglePointSVG()
        customSVG.setPosition({wCenter[1], wCenter[2], wCenter[3]})
          .setData(waypointObject)
    	  .setDrawFunction(draw)
    	  .build()
    end
end

-- tobitege: draw custom waypoints if enabled
if displayCustomWP and WM then
    for k,p in ipairs(WM:getSorted()) do
        local subId = format("%.2f", p.mapPos.altitude)
        local waypointObject = WPointer(
                p.mapPos.latitude, p.mapPos.longitude, p.mapPos.altitude,
                archHudWaypointSize * 1.25, p.name, 'WP', 'WP', subId)
        local customSVG = builder.addSinglePointSVG()
        customSVG.setPosition({p.mapPos.latitude, p.mapPos.longitude, p.mapPos.altitude})
            .setData(waypointObject)
            .setDrawFunction(draw)
            .build()
        if DEBUG then
            P("[WPointer] Added "..p.name)
        end
    end
end
end)