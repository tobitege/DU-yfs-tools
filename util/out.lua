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