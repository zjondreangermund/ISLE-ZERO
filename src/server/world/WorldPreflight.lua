local WorldPreflight = {}

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function isVector3(value)
    return typeof(value) == "Vector3"
end

local function add(report, level, message)
    table.insert(report[level], message)
end

function WorldPreflight.Run(config)
    local report = {
        errors = {},
        warnings = {},
        info = {},
    }

    if type(config) ~= "table" then
        add(report, "errors", "WorldConfig did not return a table")
        return report
    end

    if not isFiniteNumber(config.WorldVersion) or config.WorldVersion < 1 then
        add(report, "errors", "WorldVersion must be a positive number")
    end
    if not isFiniteNumber(config.Seed) then
        add(report, "errors", "Seed must be a finite number")
    end
    if not isFiniteNumber(config.SeaLevel) then
        add(report, "errors", "SeaLevel must be a finite number")
    end
    if not isFiniteNumber(config.OceanDepth) or config.OceanDepth <= 0 then
        add(report, "errors", "OceanDepth must be greater than zero")
    end
    if not isFiniteNumber(config.WorldHalfSize) or config.WorldHalfSize <= 0 then
        add(report, "errors", "WorldHalfSize must be greater than zero")
    end

    local island = config.Island
    if type(island) ~= "table" then
        add(report, "errors", "Island settings are missing")
    else
        if not isFiniteNumber(island.HalfX) or island.HalfX <= 0 then
            add(report, "errors", "Island.HalfX must be greater than zero")
        end
        if not isFiniteNumber(island.HalfZ) or island.HalfZ <= 0 then
            add(report, "errors", "Island.HalfZ must be greater than zero")
        end
        if not isFiniteNumber(island.Grid) or island.Grid < 8 then
            add(report, "errors", "Island.Grid must be at least 8 studs")
        elseif island.Grid > 64 then
            add(report, "warnings", "Island.Grid above 64 may make the terrain visibly blocky")
        end
        if not isFiniteNumber(island.BaseY) then
            add(report, "errors", "Island.BaseY must be finite")
        elseif isFiniteNumber(config.SeaLevel) and island.BaseY >= config.SeaLevel then
            add(report, "errors", "Island.BaseY must be below SeaLevel")
        end

        if isFiniteNumber(config.WorldHalfSize) and isFiniteNumber(island.HalfX) and island.HalfX >= config.WorldHalfSize then
            add(report, "errors", "Island.HalfX must fit inside WorldHalfSize")
        end
        if isFiniteNumber(config.WorldHalfSize) and isFiniteNumber(island.HalfZ) and island.HalfZ >= config.WorldHalfSize then
            add(report, "errors", "Island.HalfZ must fit inside WorldHalfSize")
        end
    end

    local generation = config.Generation
    if type(generation) ~= "table" then
        add(report, "errors", "Generation settings are missing")
    else
        if not isFiniteNumber(generation.YieldEvery) or generation.YieldEvery < 1 then
            add(report, "errors", "Generation.YieldEvery must be at least 1")
        end
        if not isFiniteNumber(generation.VegetationDensity) or generation.VegetationDensity < 0 then
            add(report, "errors", "Generation.VegetationDensity must be zero or greater")
        elseif generation.VegetationDensity > 2 then
            add(report, "warnings", "VegetationDensity above 2 may create excessive placeholder instances")
        end
    end

    if type(config.Locations) ~= "table" then
        add(report, "errors", "Locations table is missing")
    else
        for name, position in pairs(config.Locations) do
            if not isVector3(position) then
                add(report, "errors", "Location " .. tostring(name) .. " must be a Vector3")
            elseif isFiniteNumber(config.WorldHalfSize) and (math.abs(position.X) > config.WorldHalfSize or math.abs(position.Z) > config.WorldHalfSize) then
                add(report, "errors", "Location " .. tostring(name) .. " is outside WorldHalfSize")
            end
        end
    end

    if type(config.ScenicZones) ~= "table" then
        add(report, "warnings", "No ScenicZones table is configured")
    else
        for name, zone in pairs(config.ScenicZones) do
            if type(zone) ~= "table" or not isVector3(zone.Position) then
                add(report, "errors", "Scenic zone " .. tostring(name) .. " needs a Vector3 Position")
            end
            if type(zone) ~= "table" or not isFiniteNumber(zone.Radius) or zone.Radius <= 0 then
                add(report, "errors", "Scenic zone " .. tostring(name) .. " needs a positive Radius")
            end
        end
    end

    if type(config.Paths) ~= "table" then
        add(report, "errors", "Paths table is missing")
    else
        for pathName, points in pairs(config.Paths) do
            if type(points) ~= "table" or #points < 2 then
                add(report, "errors", "Path " .. tostring(pathName) .. " needs at least two points")
            else
                for index, point in ipairs(points) do
                    if not isVector3(point) then
                        add(report, "errors", string.format("Path %s point %d is not a Vector3", tostring(pathName), index))
                    elseif isFiniteNumber(config.WorldHalfSize) and (math.abs(point.X) > config.WorldHalfSize or math.abs(point.Z) > config.WorldHalfSize) then
                        add(report, "errors", string.format("Path %s point %d is outside WorldHalfSize", tostring(pathName), index))
                    end
                end
            end
        end
    end

    if not config.Locations or not isVector3(config.Locations.CrashBeach) then
        add(report, "errors", "CrashBeach location is required for safe spawning")
    end

    add(report, "info", string.format("Preflight checked world version %s", tostring(config.WorldVersion)))
    return report
end

function WorldPreflight.Assert(config)
    local report = WorldPreflight.Run(config)

    for _, message in ipairs(report.warnings) do
        warn("[ISLE//ZERO][PREFLIGHT][WARN] " .. message)
    end
    for _, message in ipairs(report.info) do
        print("[ISLE//ZERO][PREFLIGHT] " .. message)
    end

    if #report.errors > 0 then
        for _, message in ipairs(report.errors) do
            warn("[ISLE//ZERO][PREFLIGHT][ERROR] " .. message)
        end
        error(string.format("World preflight failed with %d error(s)", #report.errors), 0)
    end

    print(string.format("[ISLE//ZERO][PREFLIGHT] PASS (%d warning%s)", #report.warnings, #report.warnings == 1 and "" or "s"))
    return report
end

return WorldPreflight
