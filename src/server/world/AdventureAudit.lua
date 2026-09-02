local CollectionService = game:GetService("CollectionService")

local AdventureAudit = {}

local function record(report, level, message)
    table.insert(report[level], message)
end

local function countTagged(root, tag)
    local count = 0
    for _, object in ipairs(CollectionService:GetTagged(tag)) do
        if object:IsDescendantOf(root) then
            count += 1
        end
    end
    return count
end

function AdventureAudit.Run(root, gameplayConfig)
    local report = {
        errors = {},
        warnings = {},
        info = {},
    }

    local folder = root:FindFirstChild("AdventureContent")
    if not folder then
        record(report, "errors", "AdventureContent folder is missing")
        return report
    end

    local expectedChests = #(gameplayConfig.WorldChests or {})
    local expectedSpecial = #(gameplayConfig.SpecialCaches or {})
    local expectedCamps = #(gameplayConfig.FieldCamps or {})
    local expectedEncounters = #(gameplayConfig.WorldEncounters or {})

    local chests = countTagged(root, "WorldLootChest")
    local special = countTagged(root, "SpecialWorldCache")
    local camps = countTagged(root, "FieldCampBuildSpot")
    local encounters = countTagged(root, "WorldEnemySpawn")

    if chests < expectedChests then
        record(report, "errors", string.format("Only %d/%d world loot chests generated", chests, expectedChests))
    end
    if special < expectedSpecial then
        record(report, "errors", string.format("Only %d/%d special caches generated", special, expectedSpecial))
    end
    if camps < expectedCamps then
        record(report, "errors", string.format("Only %d/%d field camps generated", camps, expectedCamps))
    end
    if encounters < expectedEncounters then
        record(report, "errors", string.format("Only %d/%d world enemy spawns generated", encounters, expectedEncounters))
    end

    local caves = root:FindFirstChild("Caves")
    local access = caves and caves:FindFirstChild("WorldLootAccess")
    if not access or access:GetAttribute("GuardianDefeated") ~= true then
        record(report, "errors", "WorldLootAccess compatibility node is missing or locked")
    end

    for _, cave in ipairs(caves and caves:GetChildren() or {}) do
        if cave:GetAttribute("AdventureCompatibilityNode") ~= true then
            local marker = cave:FindFirstChild("GuardianSpawn", true)
            if marker then
                local walkable = 0
                for _, object in ipairs(cave:GetDescendants()) do
                    if object:IsA("BasePart") and (object.Name == "CavePath" or object.Name == "ChamberFloor") then
                        walkable += 1
                    end
                end
                if walkable == 0 then
                    record(report, "errors", cave.Name .. " guardian has no walkable cave surfaces for floor snapping")
                end
            end
        end
    end

    root:SetAttribute("WorldLootChestCount", chests)
    root:SetAttribute("SpecialWorldCacheCount", special)
    root:SetAttribute("FieldCampCount", camps)
    root:SetAttribute("WorldEncounterCount", encounters)

    record(report, "info", string.format("World loot chests: %d/%d", chests, expectedChests))
    record(report, "info", string.format("Special weapon/relic caches: %d/%d", special, expectedSpecial))
    record(report, "info", string.format("Outdoor camps: %d/%d", camps, expectedCamps))
    record(report, "info", string.format("Roaming enemy encounters: %d/%d", encounters, expectedEncounters))

    for _, message in ipairs(report.errors) do
        warn("[ISLE//ZERO][ADVENTURE AUDIT][ERROR] " .. message)
    end
    for _, message in ipairs(report.warnings) do
        warn("[ISLE//ZERO][ADVENTURE AUDIT][WARN] " .. message)
    end
    for _, message in ipairs(report.info) do
        print("[ISLE//ZERO][ADVENTURE AUDIT] " .. message)
    end

    if #report.errors == 0 then
        print(string.format("[ISLE//ZERO][ADVENTURE AUDIT] PASS (%d warning%s)", #report.warnings, #report.warnings == 1 and "" or "s"))
    end

    return report
end

return AdventureAudit
