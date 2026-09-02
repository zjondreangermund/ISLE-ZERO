local CollectionService = game:GetService("CollectionService")

local AdventureBuilder = {}

local rarityColors = {
    Common = Color3.fromRGB(113, 105, 88),
    Uncommon = Color3.fromRGB(80, 145, 82),
    Rare = Color3.fromRGB(66, 112, 181),
    Epic = Color3.fromRGB(132, 76, 174),
    Legendary = Color3.fromRGB(219, 168, 55),
}

local function makePart(parent, name, size, cframe, material, color, transparency)
    local object = Instance.new("Part")
    object.Name = name
    object.Anchored = true
    object.CanTouch = false
    object.Size = size
    object.CFrame = cframe
    object.Material = material
    object.Color = color
    object.Transparency = transparency or 0
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = parent
    object:SetAttribute("GeneratedPlaceholder", true)
    return object
end

local function groundY(config, heightAt, entry)
    if entry.FixedY then
        return entry.FixedY
    end
    return heightAt(config, entry.Position.X, entry.Position.Z)
end

local function ensureAccessCave(caves, id, discoveryName)
    local cave = caves:FindFirstChild(id)
    if not cave then
        cave = Instance.new("Model")
        cave.Name = id
        cave.Parent = caves
    end
    cave:SetAttribute("GuardianDefeated", true)
    cave:SetAttribute("CampBuilt", false)
    cave:SetAttribute("DiscoveryName", discoveryName or id)
    cave:SetAttribute("AdventureCompatibilityNode", true)
    return cave
end

local function chestModel(folder, entry, position, accessCaveId)
    local rarity = entry.Rarity or "Common"
    local accent = rarityColors[rarity] or rarityColors.Common

    local model = Instance.new("Model")
    model.Name = "WorldChest_" .. entry.Id
    model.Parent = folder
    model:SetAttribute("GeneratedPlaceholder", true)

    local yaw = math.rad((#entry.Id * 29) % 180)
    local body = makePart(
        model,
        "ChestBody",
        Vector3.new(7.2, 4, 5),
        CFrame.new(position) * CFrame.Angles(0, yaw, 0),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(84, 58, 35)
    )
    body:SetAttribute("ChestId", "WORLD_" .. entry.Id)
    body:SetAttribute("CaveId", accessCaveId)
    body:SetAttribute("LootTier", entry.Tier or "Supplies")
    body:SetAttribute("Rarity", rarity)
    body:SetAttribute("WorldChest", true)
    CollectionService:AddTag(body, "LootChest")
    CollectionService:AddTag(body, "WorldLootChest")

    local lid = makePart(
        model,
        "ChestLid",
        Vector3.new(7.4, 1.35, 5.2),
        CFrame.new(position + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, yaw, 0),
        Enum.Material.WoodPlanks,
        Color3.fromRGB(101, 70, 39)
    )
    lid.CanCollide = false

    for _, x in ipairs({-2.4, 2.4}) do
        local band = makePart(
            model,
            "ChestBand",
            Vector3.new(0.48, 5.1, 5.3),
            CFrame.new(position + Vector3.new(x, 1.2, 0)) * CFrame.Angles(0, yaw, 0),
            Enum.Material.Metal,
            accent
        )
        band.CanCollide = false
    end

    if rarity ~= "Common" then
        local glow = makePart(
            model,
            "LootGlow",
            Vector3.new(4.2, 0.22, 2.6),
            CFrame.new(position + Vector3.new(0, 3.55, 0)),
            Enum.Material.Neon,
            accent,
            0.2
        )
        glow.CanCollide = false
        glow.CanQuery = false
        local light = Instance.new("PointLight")
        light.Brightness = rarity == "Epic" and 1.6 or 1.0
        light.Range = rarity == "Epic" and 15 or 11
        light.Color = accent
        light.Parent = glow
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "OpenChestPrompt"
    prompt.ActionText = "Search chest"
    prompt.ObjectText = rarity .. " island cache"
    prompt.HoldDuration = 0.45
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Enabled = true
    prompt.Parent = body

    return model
end

local function specialCache(folder, caves, config, heightAt, entry)
    ensureAccessCave(caves, entry.CaveId, entry.DisplayName)
    local y = groundY(config, heightAt, entry)
    local position = Vector3.new(entry.Position.X, y + 2.4, entry.Position.Z)
    local rarity = entry.Rarity or "Rare"
    local accent = rarityColors[rarity] or rarityColors.Rare

    local model = Instance.new("Model")
    model.Name = entry.Id
    model.Parent = folder

    local base = makePart(model, "RewardChest", Vector3.new(8.2, 4.6, 6.1), CFrame.new(position), Enum.Material.WoodPlanks, Color3.fromRGB(72, 50, 32))
    base:SetAttribute("CaveId", entry.CaveId)
    base:SetAttribute("RewardItem", entry.ItemId)
    base:SetAttribute("RewardName", entry.DisplayName)
    base:SetAttribute("Rarity", rarity)
    base:SetAttribute("AdventureSpecialCache", true)
    CollectionService:AddTag(base, "GuardianRewardCache")
    CollectionService:AddTag(base, "SpecialWorldCache")

    local lid = makePart(model, "RewardLid", Vector3.new(8.4, 1.5, 6.3), CFrame.new(position + Vector3.new(0, 3, 0)), Enum.Material.Metal, accent)
    lid.CanCollide = false

    local glow = makePart(model, "RewardGlow", Vector3.new(5.3, 0.3, 3.3), CFrame.new(position + Vector3.new(0, 4.1, 0)), Enum.Material.Neon, accent, 0.12)
    glow.CanCollide = false
    glow.CanQuery = false
    local light = Instance.new("PointLight")
    light.Brightness = rarity == "Legendary" and 2.8 or 1.8
    light.Range = rarity == "Legendary" and 24 or 18
    light.Color = accent
    light.Parent = glow

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "GuardianRewardPrompt"
    prompt.ActionText = "Claim " .. rarity .. " cache"
    prompt.ObjectText = entry.DisplayName
    prompt.HoldDuration = 0.65
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Enabled = true
    prompt.Parent = base
end

local function fieldCamp(folder, caves, config, heightAt, entry)
    local caveId = "FieldCamp_" .. entry.Id
    ensureAccessCave(caves, caveId, entry.Id)
    local y = groundY(config, heightAt, entry)
    local position = Vector3.new(entry.Position.X, y + 0.7, entry.Position.Z)

    local model = Instance.new("Model")
    model.Name = entry.Id
    model.Parent = folder

    local ring = makePart(model, "CampClearing", Vector3.new(24, 0.7, 20), CFrame.new(position - Vector3.new(0, 0.35, 0)), Enum.Material.Ground, Color3.fromRGB(91, 90, 66), 0.1)
    ring.CanCollide = true

    local pad = makePart(model, "CampBuildSpot", Vector3.new(13, 0.8, 11), CFrame.new(position), Enum.Material.Ground, Color3.fromRGB(72, 78, 69), 0.18)
    pad.CanCollide = true
    pad:SetAttribute("CaveId", caveId)
    pad:SetAttribute("FieldCamp", true)
    CollectionService:AddTag(pad, "CampBuildSpot")
    CollectionService:AddTag(pad, "FieldCampBuildSpot")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CampPrompt"
    prompt.ActionText = "Build field camp"
    prompt.ObjectText = "Safe outdoor checkpoint"
    prompt.HoldDuration = 0.75
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Enabled = true
    prompt.Parent = pad

    local sign = makePart(model, "CampSign", Vector3.new(7, 3, 0.5), CFrame.new(position + Vector3.new(8, 4, -3)), Enum.Material.WoodPlanks, Color3.fromRGB(82, 58, 36))
    sign.CanCollide = false
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.Parent = sign
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = "CAMP SITE"
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(226, 215, 183)
    label.Parent = gui
end

local function encounterMarker(folder, config, heightAt, entry)
    local y = groundY(config, heightAt, entry)
    local marker = makePart(
        folder,
        "Encounter_" .. entry.Id,
        Vector3.new(3, 1, 3),
        CFrame.new(entry.Position.X, y + 3, entry.Position.Z),
        Enum.Material.SmoothPlastic,
        Color3.new(1, 1, 1),
        1
    )
    marker.CanCollide = false
    marker.CanQuery = false
    marker:SetAttribute("EncounterId", entry.Id)
    marker:SetAttribute("GuardianType", entry.Type)
    CollectionService:AddTag(marker, "WorldEnemySpawn")
end

function AdventureBuilder.Build(config, root, heightAt, gameplayConfig)
    local folder = Instance.new("Folder")
    folder.Name = "AdventureContent"
    folder.Parent = root

    local caves = root:FindFirstChild("Caves")
    if not caves then
        error("AdventureBuilder requires the generated Caves folder")
    end

    ensureAccessCave(caves, "WorldLootAccess", "Island caches")

    local chestFolder = Instance.new("Folder")
    chestFolder.Name = "WorldChests"
    chestFolder.Parent = folder
    local chestCount = 0
    for _, entry in ipairs(gameplayConfig.WorldChests or {}) do
        local y = groundY(config, heightAt, entry)
        chestModel(chestFolder, entry, Vector3.new(entry.Position.X, y + 2.2, entry.Position.Z), "WorldLootAccess")
        chestCount += 1
    end

    local specialFolder = Instance.new("Folder")
    specialFolder.Name = "SpecialCaches"
    specialFolder.Parent = folder
    local specialCount = 0
    for _, entry in ipairs(gameplayConfig.SpecialCaches or {}) do
        specialCache(specialFolder, caves, config, heightAt, entry)
        specialCount += 1
    end

    local campFolder = Instance.new("Folder")
    campFolder.Name = "FieldCamps"
    campFolder.Parent = folder
    local campCount = 0
    for _, entry in ipairs(gameplayConfig.FieldCamps or {}) do
        fieldCamp(campFolder, caves, config, heightAt, entry)
        campCount += 1
    end

    local encounterFolder = Instance.new("Folder")
    encounterFolder.Name = "WorldEnemySpawns"
    encounterFolder.Parent = folder
    local encounterCount = 0
    for _, entry in ipairs(gameplayConfig.WorldEncounters or {}) do
        encounterMarker(encounterFolder, config, heightAt, entry)
        encounterCount += 1
    end

    folder:SetAttribute("WorldChestCount", chestCount)
    folder:SetAttribute("SpecialCacheCount", specialCount)
    folder:SetAttribute("FieldCampCount", campCount)
    folder:SetAttribute("WorldEncounterCount", encounterCount)

    print(string.format(
        "[ISLE//ZERO][ADVENTURE] %d world chests, %d special caches, %d field camps, %d enemy encounters",
        chestCount,
        specialCount,
        campCount,
        encounterCount
    ))
    return folder
end

return AdventureBuilder
