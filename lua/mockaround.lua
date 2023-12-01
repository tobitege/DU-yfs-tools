-- add some data for testing waypoints and routes
if not INGAME then
    local wplist = {}
    wplist["G 3"] = {pos="::pos{0,4,41.4442,-41.0777,735.1812}", opt={} }
    wplist["G 9"] = {pos="::pos{0,4,41.7842,-43.8314,489.0000}", opt={} }
    wplist["G 9F1"] = {pos="::pos{0,4,42.7643,-42.1550,560.0000}", opt={} }

    local routes = { }
    routes["Garni"] = { }
    routes["Garni"].points = {
        [1] = {pos="::pos{0,4,41.4442,-41.0777,735.1812}", waypointRef="G 3",   opt={ margin=2, finalSpeed=10 }},
        [2] = {pos="::pos{0,4,41.7842,-43.8314,489.0000}", waypointRef="G 9",   opt={ margin=2, finalSpeed=10 }},
        [3] = {pos="::pos{0,4,42.7643,-42.1550,560.0000}", waypointRef="G 9F1", opt={ margin=2, finalSpeed=10 }} }

    -- Default databank with YFS keys
    unit.databank.setStringValue(YFS_NAMED_POINTS, json.encode({ v = wplist, t="table" }))
    unit.databank.setStringValue(YFS_ROUTES, json.encode({ v = routes, t="table" }))
end
