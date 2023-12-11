local timerFunc = {}

function timerFunc.Run(timerId)
    if timerId == 'update' then
        if not INGAME then P("onTimer(update)") end
        if not DEBUG or not INGAME then
            local svg = WolfAR.onRenderFrame()
            if svg then
                system.setScreen(svg)
                if not INGAME then P(svg) end
            end
            return
        end
    end
end

return timerFunc