local CollectionService = game:GetService("CollectionService")

local ExplorationClearing = {}

local function horizontalDistance(a, b)
    return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

local function positionOf(instance)
    if instance:IsA("BasePart") then
        return instance.Position
    end
    if instance:IsA("Model") then
        return instance:GetPivot().Position
    end
    return nil
end

local function buildZones(config)
    local zones = {}
    local exploration = config.Exploration or {}

    for _, cave in pairs(exploration.Caves or {}) do
        table.insert(zones, {
            Position = cave.Entrance,
            Radius = cave.ClearingRadius or 26,
        })
    end

    for _, site in pairs(exploration.Sites or {}) do
        table.insert(zones, {
            Position = site.Position,
            Radius = site.Radius or 30,
        })
    end

    for _, sign in ipairs(exploration.Signposts or {}) do
        table.insert(zones, {
            Position = sign.Position,
            Radius = 12,
        })
    end

    return zones
end

function ExplorationClearing.Apply(config, worldRoot)
    local vegetation = worldRoot:FindFirstChild("Vegetation")
    if not vegetation then
        return 0
    end

    local zones = buildZones(config)
    local removed = 0

    for _, instance in ipairs(CollectionService:GetTagged("WorldVegetation")) do
        if instance:IsDescendantOf(vegetation) then
            local position = positionOf(instance)
            if position then
                for _, zone in ipairs(zones) do
                    if horizontalDistance(position, zone.Position) < zone.Radius then
                        instance:Destroy()
                        removed += 1
                        break
                    end
                end
            end
        end
    end

    worldRoot:SetAttribute("ExplorationVegetationRemoved", removed)
    print(string.format("[ISLE//ZERO][EXPLORATION] Cleared %d vegetation objects from discovery sites", removed))
    return removed
end

return ExplorationClearing
