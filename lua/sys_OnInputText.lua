-- requires utils, global instances Cmd, SU

local inputTextFunc = {}

function inputTextFunc.Run(t)
    t = SU.Trim(t)
    if not SU.StartsWith(t, "/") then return end
    if not Cmd then
        return E("[FATAL ERROR] Commands processor not assigned!")
    end
    local cmdList = {}
    cmdList['arch-save-named'] = 1
    cmdList['conversionTest'] = 1
    cmdList['findCenter'] = 1
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
    cmdList['yfs-options-reset'] = 1
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