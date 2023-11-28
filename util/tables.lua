--[[
Ordered table iterator, allow to iterate on the natural order of the keys of a
table.

Example:
]]

--// CHILL CODE ™ //--
-- table.ordered( [sorted reverse], [type] )  v 2

-- Lua 5.x add-on for the table library
-- Table using sorted index, with binary table for fast lookup.
-- http://lua-users.org/wiki/OrderedTable by PhilippeFremy 

-- table.ordered( [sorted reverse], [type] )
-- Gives you back a ordered table, can only take entered type
-- as index returned by type(index), by default "string"
-- sorted reverse, sorts the table in reverse order, else normal
-- stype is the default index type returned by type( index ),
-- by default "string", it is only possible to set one type as index
-- will effectively create a binary table, and will always lookup
-- through binary when an index is called
function table.ordered(ireverse, stype)
    local newmetatable = {}

    -- set sort function
    if ireverse then
      newmetatable._ireverse = 1
      function newmetatable.fcomp(a, b) return b[1] < a[1] end
    else
      function newmetatable.fcomp(a, b) return a[1] < b[1] end
    end

    -- set type by default "string"
    newmetatable.stype = stype or "string"

    -- fcomparevariable
    function newmetatable.fcompvar(value)
      return value[1]
    end

    -- sorted subtable
    newmetatable._tsorted = {}

    -- behaviour on new index
    function newmetatable.__newindex(t, key, value)
      if type(key) == getmetatable(t).stype then
        local fcomp = getmetatable(t).fcomp
        local fcompvar = getmetatable(t).fcompvar
        local tsorted = getmetatable(t)._tsorted
        local ireverse = getmetatable(t)._ireverse
        -- value is given so either update or insert newly
        if value then
          local pos, _ = table.bfind(tsorted, key, fcompvar, ireverse)
          -- if pos then update the index
          if pos then
            tsorted[pos] = {key, value}
          -- else insert new value
          else
            table.binsert(tsorted, {key, value}, fcomp)
          end
        -- value is nil so remove key
        else
          local pos, _ = table.bfind(tsorted, key, fcompvar, ireverse)
          if pos then
            table.remove(tsorted, pos)
          end
        end
      end
    end

    -- behavior on index
    function newmetatable.__index(t, key)
      if type(key) == getmetatable(t).stype then
        local fcomp = getmetatable(t).fcomp
        local fcompvar = getmetatable(t).fcompvar
        local tsorted = getmetatable(t)._tsorted
        local ireverse = getmetatable(t)._ireverse
        -- value if key exists
        local pos, value = table.bfind(tsorted, key, fcompvar, ireverse)
        if pos then
          return value[2]
        end
      end
    end

    -- set metatable
    return setmetatable({}, newmetatable)
end

function table.len(source) -- tobitege
    if type(source) ~= "table" then return 0 end
    local cnt = 0
    for _ in pairs(source) do
      cnt = cnt + 1
    end
    return cnt
end

  --// table.binsert( table, value [, comp] )

  -- Lua 5.x add-on for the table library
  -- Binary inserts given value into the table sorted by [,fcomp]
  -- fcomp is a comparison function that behaves just like
  -- fcomp in table.sort( table [, comp] ).
  -- This method is faster than doing a regular
  -- table.insert(table, value) followed by a table.sort(table [, comp]).
  function table.binsert(t, value, fcomp)
    -- Initialize compare function
    local fcomp = fcomp or function(a, b) return a < b end

    -- Initialize numbers
    local iStart, iEnd, iMid, iState =  1, table.len( t ), 1, 0

    -- Get insert position
    while iStart <= iEnd do
      -- calculate middle
      iMid = math.floor((iStart + iEnd) / 2)

      -- compare
      if fcomp(value , t[iMid]) then
        iEnd = iMid - 1
        iState = 0
      else
        iStart = iMid + 1
        iState = 1
      end
    end

    local pos = iMid+iState
    table.insert(t, pos, value)
    return pos
  end

  --// table.bfind(table, value [, compvalue] [, reverse])

  -- Lua 5.x add-on for the table library.
  -- Binary searches the table for value.
  -- If the value is found it returns the index and the value of
  -- the table where it was found.
  -- fcompval, if given, is a function that takes one value and
  -- returns a second value2 to be compared with the input value,
  -- e.g. compvalue = function(value) return value[1] end
  -- If reverse is given then the search assumes that the table
  -- is sorted with the biggest value on position 1.

  function table.bfind(t, value, fcompval, reverse)
    -- Initialize functions
    fcompval = fcompval or function(val) return val end
    local fcomp = function(a, b) return a < b end
    if reverse then
      fcomp = function(a, b) return a > b end
    end

    -- Initialize Numbers
    local iStart, iEnd, iMid = 1, table.len(t), 1

    -- Binary Search
    while (iStart <= iEnd) do
      -- calculate middle
      iMid = math.floor((iStart + iEnd) / 2)

      -- get compare value
      local value2 = fcompval(t[iMid])

      if value == value2 then
        return iMid, t[iMid]
      end

      if fcomp(value , value2) then
        iEnd = iMid - 1
      else
        iStart = iMid + 1
      end
    end
  end

  -- Iterate in ordered form
  -- returns 3 values i , index, value
  -- ( i = numerical index, index = tableindex, value = t[index] )
  function OrderedPairs(t)
    return OrderedNext, t
  end
  function OrderedNext(t, i)
    i = i or 0
    i = i + 1
    local indexvalue = getmetatable(t)._tsorted[i]
    if indexvalue then
      return i, indexvalue[1], indexvalue[2]
    end
  end