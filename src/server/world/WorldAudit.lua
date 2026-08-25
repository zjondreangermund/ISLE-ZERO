local WorldAudit = {}

local REQUIRED_LANDMARKS = {
    "CrashSite",
    "OldVillage",
    "EastCliffBunkerEntrance",
    "RidgeRuins",
    "EastLookout",
    "ZeroPeak",
    "RiverAndWaterfall",
}

local REQUIRED_NATURAL_FEATURES = {
    "AncientBanyan",
    "BlueHoleCenote",
    "MangroveLagoon",
    "WindArch",
}

local REQUIRED_FOLDERS = {
    "CoastAndIslets",
    "NaturalFeatures",
    "Paths",
    "Landmarks",
    "Vegetation",
}

local function record(report, level, message)
    table.insert(report[level], message)
end

function WorldAudit.Run(config, root, heightAt)
    local report = {
        errors = {},
        warnings = {},
        info = {},
    }

    for _, folderName in ipairs(REQUIRED_FOLDERS) do
        if not root:FindFirstChild(folderName) then
            record(report, "errors", "Missing generated folder: " .. folderName)
        end
    end

    local landmarks = root:FindFirstChild("Landmarks")
    if landmarks then
        for _, landmarkName in ipairs(REQUIRED_LANDMARKS) do
            if not landmarks:FindFirstChild(landmarkName) then
                record(report, "errors", "Missing landmark: " .. landmarkName)
            end
        end

        local spawn = landmarks:FindFirstChild("CrashBeachSpawn")
        if not spawn or not spawn:IsA("SpawnLocation") then
            record(report, "errors", "CrashBeachSpawn is missing or invalid")
        elseif spawn.Position.Y <= config.SeaLevel then
            record(report, "errors", "CrashBeachSpawn is at or below sea level")
        end
    end

    local natural = root:FindFirstChild("NaturalFeatures")
    if natural then
        for _, featureName in ipairs(REQUIRED_NATURAL_FEATURES) do
            if not natural:FindFirstChild(featureName) then
                record(report, "errors", "Missing natural feature: " .. featureName)
            end
        end
    end

    for pathName, points in pairs(config.Paths) do
        for index, point in ipairs(points) do
            local height = heightAt(config, point.X, point.Z)
            if height <= config.SeaLevel then
                record(report, "errors", string.format("%s path point %d is outside playable land", pathName, index))
            elseif height < config.SeaLevel + 4 then
                record(report, "warnings", string.format("%s path point %d is very close to sea level", pathName, index))
            end
        end
    end

    local landmarkPositions = {}
    for name, position in pairs(config.Locations) do
        local height = heightAt(config, position.X, position.Z)
        landmarkPositions[name] = Vector3.new(position.X, height, position.Z)
        if height <= config.SeaLevel then
            record(report, "errors", name .. " is configured outside playable land")
        end
    end

    for name, zone in pairs(config.ScenicZones or {}) do
        local position = zone.Position
        local height = heightAt(config, position.X, position.Z)
        if height <= config.SeaLevel then
            record(report, "errors", "Scenic zone " .. name .. " is configured outside playable land")
        end
    end

    local names = {}
    for name in pairs(landmarkPositions) do
        table.insert(names, name)
    end
    table.sort(names)
    for i = 1, #names do
        for j = i + 1, #names do
            local aName, bName = names[i], names[j]
            local a, b = landmarkPositions[aName], landmarkPositions[bName]
            local horizontal = Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
            if horizontal < 55 then
                record(report, "warnings", string.format("Landmarks %s and %s are only %.0f studs apart", aName, bName, horizontal))
            end
        end
    end

    local descendantCount = #root:GetDescendants()
    record(report, "info", string.format("Generated descendants: %d", descendantCount))
    record(report, "info", string.format("World seed: %d", config.Seed))
    record(report, "info", string.format("World version: %d", config.WorldVersion))

    root:SetAttribute("AuditErrors", #report.errors)
    root:SetAttribute("AuditWarnings", #report.warnings)
    root:SetAttribute("GeneratedDescendants", descendantCount)

    for _, message in ipairs(report.errors) do
        warn("[ISLE//ZERO][WORLD AUDIT][ERROR] " .. message)
    end
    for _, message in ipairs(report.warnings) do
        warn("[ISLE//ZERO][WORLD AUDIT][WARN] " .. message)
    end
    for _, message in ipairs(report.info) do
        print("[ISLE//ZERO][WORLD AUDIT] " .. message)
    end

    if #report.errors == 0 then
        print(string.format("[ISLE//ZERO][WORLD AUDIT] PASS (%d warning%s)", #report.warnings, #report.warnings == 1 and "" or "s"))
    end

    return report
end

return WorldAudit
