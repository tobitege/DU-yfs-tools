local timerFunc = {}

function timerFunc.Run(timerId)
    if timerId == 'update' then
        local svg, index = projector.getSVG()
        ---@diagnostic disable-next-line: param-type-mismatch
        system.setScreen(svg)
        --if DEBUG and not svg then P(string.format("%.2f",system.getArkTime() - ScriptStartTime) .." [W] svg empty!") end
    end
end

return timerFunc