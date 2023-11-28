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