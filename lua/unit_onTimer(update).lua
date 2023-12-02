local timerFunc = {}

function timerFunc.Run(timerId)
    if timerId == 'update' then
        if not INGAME then P("onTimer(update)") end
        if not DEBUG then
            local svg = projector.getSVG()
            ---@diagnostic disable-next-line: param-type-mismatch
            if svg then system.setScreen(svg) end
            return
        end

-- EasternGamer's Screen Update with debug info
local timeStart = system.getArkTime()
local svg, deltaPreProcessing, deltaDrawProcessing, deltaEvent, deltaZSort, deltaZBufferCopy, deltaPostProcessing = projector.getSVG()
local delta = system.getArkTime() - timeStart
local floor = math.floor
local function WriteDelta(name, dt, suffix)
    return '<div>'.. name .. ':'.. floor((dt*100000))/100 .. suffix .. '</div>'
end
collectgarbage('collect')
if svg then
    if not DEBUG then
        system.setScreen(svg)
    else
        system.setScreen(table.concat({
            svg,
            '<div>CPU Instructions: ', system.getInstructionCount() .. '/' .. system.getInstructionLimit() .. '</div>',
            WriteDelta('Memory',collectgarbage('count')/1000, 'kb'),
            WriteDelta('Total',delta, 'ms'),
            WriteDelta('Pre-Processing', deltaPreProcessing, 'ms'),
            WriteDelta('Draw Processing', deltaDrawProcessing, 'ms'),
            WriteDelta('Event', deltaEvent, 'ms'),
            WriteDelta('Z-Sorting', deltaZSort, 'ms'),
            WriteDelta('Z-Buffer Copy', deltaZBufferCopy, 'ms'),
            WriteDelta('Post Processing', deltaPostProcessing, 'ms')
        }))
    end
end
--==================================--
    end
end

return timerFunc