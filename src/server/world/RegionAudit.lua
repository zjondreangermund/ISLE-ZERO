local CollectionService = game:GetService("CollectionService")

local RegionAudit = {}

local function record(report, level, message)
    table.insert(report[level], message)
end

local function countConfigured(dictionary)
    local count = 0
    for _ in pairs(dictionary or {}) do
        count += 1
    end
    return count
end

local function countTaggedInside(root, tag)
    local count = 0
    for _, object in ipairs(CollectionService:GetTagged(tag)) do
        if object:IsDescendantOf(root) then
            count += 1
        end
    end
    return count
end

function RegionAudit.Run(config, gameplayConfig, root)
    local report = {
        errors = {},
        warnings = {},
        info = {},
    }

    local folder = root:FindFirstChild("RegionsAndProgression")
    if not folder then
        record(report, "errors", "Missing RegionsAndProgression folder")
        return report
    end

    local regionCount = countConfigured(config.Regions)
    if regionCount < 8 then
        record(report, "warnings", string.format("Only %d configured map regions", regionCount))
    end

    local gateCount = countTaggedInside(root, "ProgressionGate")
    if gateCount < 2 then
        record(report, "errors", string.format("Only %d progression gate markers generated; expected at least 2", gateCount))
    end

    local travelCount = countTaggedInside(root, "ProgressionTravel")
    if travelCount < 2 then
        record(report, "errors", string.format("Only %d progression travel objects generated; expected at least 2", travelCount))
    end

    local travelPointCount = countTaggedInside(root, "WorldTravelPoint")
    if travelPointCount < 1 then
        record(report, "errors", "Deserted Island arrival travel point is missing")
    end

    local expectedRewards = countConfigured(gameplayConfig.CaveRewards)
    local rewardCount = countTaggedInside(root, "GuardianRewardCache")
    if rewardCount < expectedRewards then
        record(report, "errors", string.format("Only %d guardian reward caches generated; expected %d", rewardCount, expectedRewards))
    end

    local coast = root:FindFirstChild("CoastAndIslets")
    if not coast or not coast:FindFirstChild("DesertedIsland") then
        record(report, "errors", "Deserted Island model did not generate")
    end

    local regions = config.Regions or {}
    local frost = regions.Frostpeak
    if not frost or frost.Requirement ~= "WinterGear" then
        record(report, "errors", "Frostpeak is not configured to require WinterGear")
    end
    local stonefall = regions.StonefallRuins
    if not stonefall or stonefall.Requirement ~= "ClimbingKit" then
        record(report, "errors", "Stonefall upper ridge is not configured to require ClimbingKit")
    end
    local deserted = regions.DesertedIsland
    if not deserted or deserted.Requirement ~= "BoatRepairKit" then
        record(report, "errors", "Deserted Island is not configured to require BoatRepairKit")
    end

    local caves = root:FindFirstChild("Caves")
    local frostCave = caves and caves:FindFirstChild("FrostpeakCave")
    if not frostCave or frostCave:GetAttribute("GuardianType") ~= "IceBear" then
        record(report, "errors", "Frostpeak Cave Ice Bear guardian is missing")
    end

    root:SetAttribute("RegionCount", regionCount)
    root:SetAttribute("ProgressionGateCount", gateCount)
    root:SetAttribute("ProgressionTravelCount", travelCount)
    root:SetAttribute("GuardianRewardCount", rewardCount)

    record(report, "info", string.format("Map regions: %d", regionCount))
    record(report, "info", string.format("Gear gates: %d", gateCount))
    record(report, "info", string.format("Travel objects: %d", travelCount))
    record(report, "info", string.format("Guardian reward caches: %d/%d", rewardCount, expectedRewards))

    for _, message in ipairs(report.errors) do
        warn("[ISLE//ZERO][REGION AUDIT][ERROR] " .. message)
    end
    for _, message in ipairs(report.warnings) do
        warn("[ISLE//ZERO][REGION AUDIT][WARN] " .. message)
    end
    for _, message in ipairs(report.info) do
        print("[ISLE//ZERO][REGION AUDIT] " .. message)
    end

    if #report.errors == 0 then
        print(string.format("[ISLE//ZERO][REGION AUDIT] PASS (%d warning%s)", #report.warnings, #report.warnings == 1 and "" or "s"))
    end

    return report
end

return RegionAudit
