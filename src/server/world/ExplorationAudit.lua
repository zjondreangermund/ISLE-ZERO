local ExplorationAudit = {}

local function countKeys(dictionary)
    local count = 0
    for _ in pairs(dictionary or {}) do
        count += 1
    end
    return count
end

local function record(report, level, message)
    table.insert(report[level], message)
end

function ExplorationAudit.Run(config, root, heightAt)
    local report = {
        errors = {},
        warnings = {},
        info = {},
    }

    local exploration = config.Exploration or {}
    local cavesFolder = root:FindFirstChild("Caves")
    local sitesFolder = root:FindFirstChild("ExplorationSites")
    local signsFolder = root:FindFirstChild("TrailSigns")

    if not cavesFolder then
        record(report, "errors", "Missing Caves folder")
    end
    if not sitesFolder then
        record(report, "errors", "Missing ExplorationSites folder")
    end
    if not signsFolder then
        record(report, "errors", "Missing TrailSigns folder")
    end

    local configuredCaves = countKeys(exploration.Caves)
    local configuredSites = countKeys(exploration.Sites)
    local configuredSigns = #(exploration.Signposts or {})

    local caveCount = cavesFolder and (cavesFolder:GetAttribute("CaveCount") or #cavesFolder:GetChildren()) or 0
    local siteCount = sitesFolder and (sitesFolder:GetAttribute("SiteCount") or #sitesFolder:GetChildren()) or 0
    local signCount = signsFolder and (signsFolder:GetAttribute("SignpostCount") or #signsFolder:GetChildren()) or 0

    local minimumCaves = (config.Audit and config.Audit.MinCaveCount) or configuredCaves
    local minimumSites = (config.Audit and config.Audit.MinExplorationSiteCount) or configuredSites
    local minimumSigns = (config.Audit and config.Audit.MinSignpostCount) or configuredSigns

    if caveCount < minimumCaves then
        record(report, "errors", string.format("Only %d caves generated; expected at least %d", caveCount, minimumCaves))
    end
    if siteCount < minimumSites then
        record(report, "errors", string.format("Only %d exploration sites generated; expected at least %d", siteCount, minimumSites))
    end
    if signCount < minimumSigns then
        record(report, "errors", string.format("Only %d trail signs generated; expected at least %d", signCount, minimumSigns))
    end

    if cavesFolder then
        for caveId, cave in pairs(exploration.Caves or {}) do
            local model = cavesFolder:FindFirstChild(caveId)
            if not model then
                record(report, "errors", "Missing cave model: " .. caveId)
            elseif not model:FindFirstChild("DiscoveryMarker") then
                record(report, "warnings", "Cave has no discovery marker: " .. caveId)
            end

            local entrance = cave.Entrance
            if entrance then
                local height = heightAt(config, entrance.X, entrance.Z)
                if height <= config.SeaLevel then
                    record(report, "errors", "Cave entrance is outside playable land: " .. caveId)
                end
            end
        end
    end

    if sitesFolder then
        for siteId, site in pairs(exploration.Sites or {}) do
            local model = sitesFolder:FindFirstChild(siteId)
            if not model then
                record(report, "errors", "Missing exploration site model: " .. siteId)
            elseif not model:FindFirstChild("DiscoveryMarker") then
                record(report, "warnings", "Exploration site has no discovery marker: " .. siteId)
            end

            local position = site.Position
            if position then
                local height = heightAt(config, position.X, position.Z)
                if height <= config.SeaLevel then
                    record(report, "errors", "Exploration site is outside playable land: " .. siteId)
                end
            end
        end
    end

    root:SetAttribute("CaveCount", caveCount)
    root:SetAttribute("ExplorationSiteCount", siteCount)
    root:SetAttribute("TrailSignCount", signCount)

    record(report, "info", string.format("Caves: %d/%d", caveCount, configuredCaves))
    record(report, "info", string.format("Surface exploration sites: %d/%d", siteCount, configuredSites))
    record(report, "info", string.format("Wooden signposts: %d/%d", signCount, configuredSigns))

    for _, message in ipairs(report.errors) do
        warn("[ISLE//ZERO][EXPLORATION AUDIT][ERROR] " .. message)
    end
    for _, message in ipairs(report.warnings) do
        warn("[ISLE//ZERO][EXPLORATION AUDIT][WARN] " .. message)
    end
    for _, message in ipairs(report.info) do
        print("[ISLE//ZERO][EXPLORATION AUDIT] " .. message)
    end

    if #report.errors == 0 then
        print(string.format("[ISLE//ZERO][EXPLORATION AUDIT] PASS (%d warning%s)", #report.warnings, #report.warnings == 1 and "" or "s"))
    end

    return report
end

return ExplorationAudit
