local actionStartFunc = {}

function actionStartFunc.Run(action)
    if action == 'option1' then
        WaypointOpt = true
        return
    end
    if action == 'option2' then
        local projector = Projector()
        projector.refresh()
        return
    end
end

return actionStartFunc

