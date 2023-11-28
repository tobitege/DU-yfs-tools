local timerFunc = {}

function timerFunc.Run(timerId)
    if timerId == 'update' then
        local projector = Projector()
        local svg = projector.getSVG()
        ---@diagnostic disable-next-line: param-type-mismatch
        system.setScreen(svg)
    end
end

return timerFunc