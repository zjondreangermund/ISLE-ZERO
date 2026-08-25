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

local function horizontalDistance(a, b)
    return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

local function auditPathGrades(config, heightAt, report)
    local warningGrade = (config.Audit and config.Audit.WarnPathGrade) or 0.65
    local sampleSpacing = 18
    local worstGrade = 0
    local worstPath = "none"
    local worstSegment = 0

    for pathName, points in pairs(config.Paths) do
        for segmentIndex = 1, #points - 1 do
            local from = points[segmentIndex]
            local to = points[segmentIndex + 1]
            local horizontalLength = Vector2.new(to.X - from.X, to.Z - from.Z).Magnitude
            local samples = math.max(1, math.ceil(horizontalLength / sampleSpacing))
            local previous = nil

            for sampleIndex = 0, samples do
                local alpha = sampleIndex / samples
                local x = from.X + (to.X - from.X) * alpha
                local z = from.Z + (to.Z - from.Z) * alpha
                local point = Vector3.new(x, heightAt(config, x, z), z)

                if previous then
                    local run = horizontalDistance(previous, point)
                    if run > 0.01 then
                        local grade = math.abs(point.Y - previous.Y) / run
                        if grade > worstGrade then
                            worstGrade = grade
                            worstPath = pathName
                            worstSegment = segmentIndex
                        end
                    end
                end
                previous = point
            end
        end
    end

    report.metrics.WorstPathGrade = worstGrade
    report.metrics.WorstPathName = worstPath
    report.metrics.WorstPathSegment = worstSegment

    if worstGrade > warningGrade then
        record(
            report,
            "warnings",
            string.format(
                "Steep trail detected on %s segment %d: %.0f%% grade (warning threshold %.0f%%)",
                tostring(worstPath),
                worstSegment,
                worstGrade * 100,
                warningGrade * 100
            )
        )
    end
end

local function auditSpawnClearance(landmarks, spawn, report)
    if not spawn then
        return
    end

    local nearestName = nil
    local nearestDistance = math.huge
    for _, descendant in ipairs(landmarks:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant ~= spawn and descendant.CanCollide then
            local verticalDifference = math.abs(descendant.Position.Y - spawn.Position.Y)
            if verticalDifference < 10 then
                local distance = horizontalDistance(descendant.Position, spawn.Position)
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestName = descendant:GetFullName()
                end
            end
        end
    end

    report.metrics.SpawnNearestSolidDistance = nearestDistance == math.huge and -1 or nearestDistance
    if nearestDistance < 9 then
        record(report, "warnings", string.format("Crash spawn has solid geometry only %.1f studs away: %s", nearestDistance, tostring(nearestName)))
    end
end

function WorldAudit.Run(config, root, heightAt)
    local report = {
        errors = {},
        warnings = {},
        info = {},
        metrics = {},
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
        else
            auditSpawnClearance(landmarks, spawn, report)
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

    auditPathGrades(config, heightAt, report)

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
            local horizontal = horizontalDistance(a, b)
            if horizontal < 55 then
                record(report, "warnings", string.format("Landmarks %s and %s are only %.0f studs apart", aName, bName, horizontal))
            end
        end
    end

    local descendantCount = #root:GetDescendants()
    report.metrics.GeneratedDescendants = descendantCount

    local warnBudget = (config.Audit and config.Audit.WarnGeneratedDescendants) or 3500
    local maxBudget = (config.Audit and config.Audit.MaxGeneratedDescendants) or 5000
    if descendantCount > maxBudget then
        record(report, "warnings", string.format("Generated descendants %d exceed the preferred maximum budget of %d", descendantCount, maxBudget))
    elseif descendantCount > warnBudget then
        record(report, "warnings", string.format("Generated descendants %d are above the warning budget of %d", descendantCount, warnBudget))
    end

    record(report, "info", string.format("Generated descendants: %d", descendantCount))
    record(report, "info", string.format("Worst sampled path grade: %.0f%% (%s segment %d)", report.metrics.WorstPathGrade * 100, tostring(report.metrics.WorstPathName), report.metrics.WorstPathSegment))
    record(report, "info", string.format("World seed: %d", config.Seed))
    record(report, "info", string.format("World version: %d", config.WorldVersion))

    root:SetAttribute("AuditErrors", #report.errors)
    root:SetAttribute("AuditWarnings", #report.warnings)
    root:SetAttribute("GeneratedDescendants", descendantCount)
    root:SetAttribute("WorstPathGrade", report.metrics.WorstPathGrade)

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
