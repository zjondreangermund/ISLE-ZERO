local CollectionService = game:GetService("CollectionService")

local CoastBuilder = {}

local function makePart(parent, name, size, cframe, material, color)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = true
    p.CanTouch = false
    p.Material = material
    p.Color = color
    p.Size = size
    p.CFrame = cframe
    p.Parent = parent
    p:SetAttribute("GeneratedPlaceholder", true)
    CollectionService:AddTag(p, "WorldSetDressing")
    return p
end

function CoastBuilder.Build(config, root, heightAt)
    local folder = Instance.new("Folder")
    folder.Name = "CoastAndIslets"
    folder.Parent = root

    local terrain = workspace.Terrain
    local islets = {
        {Vector3.new(1260, -15, 520), 62},
        {Vector3.new(1320, -18, -330), 48},
        {Vector3.new(980, -20, -1040), 54},
        {Vector3.new(-1260, -16, -410), 58},
        {Vector3.new(-1380, -20, 390), 43},
    }

    for index, entry in ipairs(islets) do
        local center, radius = entry[1], entry[2]
        terrain:FillBall(center, radius, Enum.Material.Rock)
        if index == 1 then
            terrain:FillBall(center + Vector3.new(0, radius * 0.45, 0), radius * 0.62, Enum.Material.Sand)
        end
    end

    local rng = Random.new(config.Seed + 3321)
    local crash = config.Locations.CrashBeach

    -- Driftwood and storm debris help the spawn beach feel authored before
    -- custom meshes are available.
    for _ = 1, 18 do
        local x = crash.X + rng:NextNumber(-320, 320)
        local z = crash.Z + rng:NextNumber(-110, 140)
        local y = heightAt(config, x, z)
        if y < 22 then
            local length = rng:NextNumber(8, 22)
            local log = makePart(
                folder,
                "Driftwood",
                Vector3.new(length, rng:NextNumber(1.1, 2.2), rng:NextNumber(1.1, 2.2)),
                CFrame.new(x, y + 0.9, z) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(0, math.pi), rng:NextNumber(-0.2, 0.2)),
                Enum.Material.Wood,
                Color3.fromRGB(91, 73, 54)
            )
            log.CanCollide = false
            log.CanQuery = false
        end
    end

    -- Extra sea stacks along the east coast break up the horizon and reinforce
    -- the rougher cliff-side identity of that coast.
    for _ = 1, 11 do
        local x = rng:NextNumber(1080, 1360)
        local z = rng:NextNumber(-780, 360)
        local size = Vector3.new(rng:NextNumber(14, 35), rng:NextNumber(20, 65), rng:NextNumber(14, 34))
        makePart(
            folder,
            "SeaStack",
            size,
            CFrame.new(x, -8 + size.Y / 2, z) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, math.pi), rng:NextNumber(-0.15, 0.15)),
            Enum.Material.Rock,
            Color3.fromRGB(76, 80, 78)
        )
    end

    return folder
end

return CoastBuilder
