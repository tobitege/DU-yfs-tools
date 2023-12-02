-- add some data for testing waypoints and routes
if not INGAME then
    local wplist = {}
    wplist["G 3"] = {pos="::pos{0,4,41.4442,-41.0777,735.1812}", opt={} }
    wplist["G 9"] = {pos="::pos{0,4,41.7842,-43.8314,489.0000}", opt={} }
    wplist["G 9F1"] = {pos="::pos{0,4,42.7643,-42.1550,560.0000}", opt={} }

    wplist["Hema A1"] = {pos="::pos{0, 2, -65.3804, 133.7598, -327.5948}", opt={} }
    wplist["Hema A1 F"] = {pos="::pos{0, 2, -65.3804, 133.7598, 10.0000}", opt={} }
    wplist["Hema A2"] = {pos="::pos{0, 2, -65.6189, 132.2583, -299.0190}", opt={} }
    wplist["Hema A3"] = {pos="::pos{0, 2, -64.7893, 132.9524, -282.4475}", opt={} }

    wplist["K AGG HQ"] = {pos="::pos{0, 2, 35.4236, 103.9912, 1428.4366}", opt={} }
    wplist["K AGG Off"] = {pos="::pos{0, 2, 35.4236, 103.9912, 1438.0000}", opt={} }
    wplist["K Base Land"] = {pos="::pos{0, 2, 35.3663, 103.9968, 286.5888}", opt={} }
    wplist["K Base Off"] = {pos="::pos{0, 2, 35.3663, 103.9968, 1438.0000}", opt={} }

    local routes = { }
    routes["Garni"] = { }
    routes["Garni"].points = {
        [1] = {pos="::pos{0,4,41.4442,-41.0777,735.1812}", waypointRef="G 3",   opt={ margin=2, finalSpeed=10 }},
        [2] = {pos="::pos{0,4,41.7842,-43.8314,489.0000}", waypointRef="G 9",   opt={ margin=2, finalSpeed=10 }},
        [3] = {pos="::pos{0,4,42.7643,-42.1550,560.0000}", waypointRef="G 9F1", opt={ margin=2, finalSpeed=10 }} }

    routes["Hema"] = { }
    routes["Hema"].points = {
        [1] = {pos=wplist["Hema A1"].pos, waypointRef="Hema A1", opt={ margin=2, finalSpeed=10 }},
        [2] = {pos=wplist["Hema A1 F"].pos, waypointRef="Hema A1 F", opt={ margin=2, finalSpeed=10 }},
        [3] = {pos=wplist["Hema A2"].pos, waypointRef="Hema A2",   opt={ margin=2, finalSpeed=10 }},
        [4] = {pos=wplist["Hema A3"].pos, waypointRef="Hema A3", opt={ margin=2, finalSpeed=10 }} }

    -- Default databank with YFS keys
    unit.databank.setStringValue(YFS_NAMED_POINTS, json.encode({ v = wplist, t="table" }))
    unit.databank.setStringValue(YFS_ROUTES, json.encode({ v = routes, t="table" }))
end
