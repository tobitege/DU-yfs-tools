local timerFunc = {}

function timerFunc.Run(timerId)
    if timerId == 'update' then
        local svg = WolfAR.onRenderFrame()
        if svg then
            system.setScreen(svg)
            if not INGAME then P("onTimer(update): "..svg) end
        end
    end
end

return timerFunc