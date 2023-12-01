local actionStartFunc = {}

function actionStartFunc.Run(action)
    --P("ActionStart: "..action)
    if action == 'option1' then
        WaypointOpt = true
        return
    end
    if action == 'option2' then
        projector.refresh()
        return
    end
end

return actionStartFunc

