--[[ Wolfe Labs Smart Template Library (STL)
https://github.com/wolfe-labs/SmartTemplateLibrary
(C) 2022 - Wolfe Labs ]]

--- Helper function that generates a clean print statement of a certain string
---@param str string The string we need to show
---@return string
local function mkPrint(str)
return 'print(\'' .. str:gsub('\'', '\\\''):gsub('\n', '\\n') .. '\')'
end

--- Helper function that merges tables
---@vararg table
---@return table
local function tMerge(...)
local tables = {...}
local result = {}
for _, t in pairs(tables) do
    for k, v in pairs(t) do
    result[k] = v
    end
end
return result
end

--- Retrieves a certain line from a string
---@param str string The source string
---@param ln number The line number
---@return string|nil
local function getLine(str, ln)
local _ = 0
for s in str:gmatch("([^\n]*)\n?") do
    _ = _ + 1
    if _ == ln then
    return s
    end
end
return nil
end

--- Trims a string
---@param str string The string being trimmed
---@return string
local function trim(str)
return str:gsub("^%s*(.-)%s*$", "%1")
end

---@class Template
local Template = {
--- Globals available for every template by default
globals = {
    math = math,
    table = table,
    string = string,
    ipairs = ipairs,
    pairs = pairs,
}
}

-- Makes our template directly callable
function Template.__call(self, ...)
return Template.render(self, ({...})[1])
end

--- Renders our template
---@param vars table The variables to be used when rendering the template
---@return string
function Template:render(vars)
-- Safety check, vars MUST be a table or nil
if type(vars or {}) ~= 'table' then
    error('Template parameters must be a table, got ' .. type(vars))
end

--- This is our return buffer
local _ = {}

-- Creates our environment
local env = tMerge(Template.globals, self.globals or {}, vars or {}, {
    print = function (str) table.insert(_, tostring(str or '')) end,
})

-- Invokes our template
self.callable(env)

-- General trimming
local result = table.concat(_, ''):gsub('%s+', ' ')

-- Trims result
result = result:sub(result:find('[^%s]') or 1):gsub('%s*$', '')

-- Done
return result
end

--- Creates a new template
---@param source string The code for your template
---@param globals table|nil Global variables to be used on on the template
---@param buildErrorHandler function|nil A function to handle build errors, if none is found throws an error
---@return Template
function Template.new(source, globals, buildErrorHandler)
-- Creates our instance
local self = {
    source = source,
    globals = globals,
}

-- Yield function (mostly for games who limit executions per frame)
local yield = (coroutine and coroutine.isyieldable() and coroutine.yield) or function () end

-- Parses direct printing of variables, we'll convert a {{var}} into {% print(var) %}
source = source:gsub('{{(.-)}}', '{%% print(%1) %%}')

-- Ensures {% if %} ... {% else %} ... {% end %} stays on same line
source = source:gsub('\n%s*{%%', '{%%')
source = source:gsub('%%}\n', '%%}')

--- This variable stores all our Lua "pieces"
local tPieces = {}

-- Parses actual Lua inside {% lua %} tags
while #source > 0 do
    --- The start index of Lua tag
    local iLuaStart = source:find('{%%')

    --- The end index of Lua tag
    local iLuaEnd = source:find('%%}')

    -- Checks if we have a match
    if iLuaStart then
    -- Errors when not closing a tag
    if not iLuaEnd then
        error('Template error, missing Lua closing tag near: ' .. source:sub(0, 16))
    end

    --- The current text before Lua tag
    local currentText = source:sub(1, iLuaStart - 1)
    if #currentText then
        table.insert(tPieces, mkPrint(currentText))
    end

    --- Our Lua tag content
    local luaTagContent = source:sub(iLuaStart, iLuaEnd + 1):match('{%%(.-)%%}') or ''
    table.insert(tPieces, luaTagContent)

    -- Removes parsed content
    source = source:sub(iLuaEnd + 2)
    else
    -- Adds remaining Lua as a single print statement
    table.insert(tPieces, mkPrint(source))

    -- Marks content as parsed
    source = ''
    end

    -- Yields loading
    yield()
end

-- Builds the Lua function
self.code = table.concat(tPieces, '\n')

-- Builds our function and caches it, this is our template now
local lua = string.format('return function (_) _ENV = _; _ = _ENV[_]\n%s\nend', self.code)
local _, err = load(lua, nil, 't', {})
if _ and not err then
    _ = _()
end

-- Checks for any errors
if err then
    local _, ln, msg = err:match('^(.-):(%d+):(.+)')
    local nearSrc = getLine(self.source, ln - 1)
    local nearLua = getLine(self.code, ln - 1)

    local ex = {
    raw = err,
    line = ln - 1,
    near = trim(nearSrc or 'N/A'),
    nearLua = trim(nearLua or 'N/A'),
    message = trim(msg),
    }

    if buildErrorHandler then
    buildErrorHandler(self, ex)
    else
    error(('Failed compiling template!\nError: %s\nLine: %d\nNear: %s\nCode: %s'):format(ex.message, ex.line, ex.near, ex.nearLua))
    end

    -- Retuns an invalid instance
    return nil
else
    -- If everything passed, assigns our callable to our compiled function
    self.callable = _
end

-- Initializes our instance
return setmetatable(self, Template)
end

-- By default, returns the constructor of our class
return Template.new