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

local function validatePositiveSetting(report, settings, key, maximum)
    local value = settings[key]
    if not isFiniteNumber(value) or value <= 0 then
        add(report, "errors", "Vegetation." .. key .. " must be greater than zero")
    elseif maximum and value > maximum then
        add(report, "warnings", string.format("Vegetation.%s is very high (%s > %s)", key, tostring(value), tostring(maximum)))
    end
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
        if not isFiniteNumber(island.BeachBand) or island.BeachBand <= 0 or island.BeachBand >= 0.8 then
            add(report, "errors", "Island.BeachBand must be greater than 0 and below 0.8")
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

    local vegetation = config.Vegetation
    if vegetation ~= nil then
        if type(vegetation) ~= "table" then
            add(report, "errors", "Vegetation settings must be a table")
        else
            validatePositiveSetting(report, vegetation, "JungleTreeTarget", 6000)
            validatePositiveSetting(report, vegetation, "PalmTarget", 1200)
            validatePositiveSetting(report, vegetation, "MangroveTarget", 900)
            validatePositiveSetting(report, vegetation, "UnderstoryTarget", 4000)
            validatePositiveSetting(report, vegetation, "RockTarget", 1000)
            validatePositiveSetting(report, vegetation, "MaxAttemptsMultiplier", 12)
            validatePositiveSetting(report, vegetation, "TreeSpacing", 30)
            validatePositiveSetting(report, vegetation, "PalmSpacing", 35)
            validatePositiveSetting(report, vegetation, "MangroveSpacing", 25)
            validatePositiveSetting(report, vegetation, "PathClearance", 30)
            validatePositiveSetting(report, vegetation, "ForestNoiseScale", 600)
            validatePositiveSetting(report, vegetation, "MaxTreeElevation", 600)

            if not isFiniteNumber(vegetation.ForestNoiseBias) or vegetation.ForestNoiseBias < -1 or vegetation.ForestNoiseBias > 1 then
                add(report, "errors", "Vegetation.ForestNoiseBias must be between -1 and 1")
            end

            local density = generation and generation.VegetationDensity or 1
            if isFiniteNumber(density) then
                local projectedTrees = math.floor((vegetation.JungleTreeTarget or 0) * density)
                    + math.floor((vegetation.PalmTarget or 0) * density)
                    + math.floor((vegetation.MangroveTarget or 0) * density)
                if projectedTrees > 8000 then
                    add(report, "warnings", string.format("Projected tree target is very high: %d", projectedTrees))
                end
            end
        end
    else
        add(report, "warnings", "No Vegetation settings table is configured")
    end

    local audit = config.Audit
    if audit ~= nil then
        if type(audit) ~= "table" then
            add(report, "errors", "Audit settings must be a table")
        else
            if not isFiniteNumber(audit.WarnPathGrade) or audit.WarnPathGrade <= 0 then
                add(report, "errors", "Audit.WarnPathGrade must be greater than zero")
            end
            if not isFiniteNumber(audit.WarnGeneratedDescendants) or audit.WarnGeneratedDescendants < 1 then
                add(report, "errors", "Audit.WarnGeneratedDescendants must be at least 1")
            end
            if not isFiniteNumber(audit.MaxGeneratedDescendants) or audit.MaxGeneratedDescendants < 1 then
                add(report, "errors", "Audit.MaxGeneratedDescendants must be at least 1")
            elseif isFiniteNumber(audit.WarnGeneratedDescendants) and audit.MaxGeneratedDescendants <= audit.WarnGeneratedDescendants then
                add(report, "errors", "Audit.MaxGeneratedDescendants must be above WarnGeneratedDescendants")
            end
            if audit.MinTreeCount ~= nil and (not isFiniteNumber(audit.MinTreeCount) or audit.MinTreeCount < 0) then
                add(report, "errors", "Audit.MinTreeCount must be zero or greater")
            end
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
