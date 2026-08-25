local TerrainBuilder = {}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function gaussian(x, z, cx, cz, sx, sz)
    local dx = (x - cx) / sx
    local dz = (z - cz) / sz
    return math.exp(-(dx * dx + dz * dz))
end

function TerrainBuilder.HeightAt(config, x, z)
    local island = config.Island
    local nx = x / island.HalfX
    local nz = z / island.HalfZ

    -- Distort the coastline just enough to avoid an obvious ellipse.
    local coastNoise = math.noise(x / 310, z / 310, config.Seed * 0.0001) * 0.08
    local fineCoast = math.noise(x / 120, z / 120, config.Seed * 0.0003) * 0.025
    local radius = math.sqrt(nx * nx + nz * nz) - coastNoise - fineCoast
    local edge = 1 - radius

    if edge <= 0 then
        return config.SeaLevel - 12 - math.abs(edge) * 55
    end

    local height
    local beachBand = 0.28
    if edge < beachBand then
        height = 3 + (edge / beachBand) * 18
    else
        local t = clamp((edge - beachBand) / (1 - beachBand), 0, 1)
        height = 21 + (t ^ 1.15) * 78
    end

    local broadNoise = math.noise(x / 260, z / 260, config.Seed * 0.001) * 13
    local detailNoise = math.noise(x / 90, z / 90, config.Seed * 0.002) * 5
    height += broadNoise + detailNoise

    -- Signature northern massif and supporting ridges.
    height += gaussian(x, z, -90, -650, 360, 310) * 185
    height += gaussian(x, z, 260, -500, 330, 230) * 72
    height += gaussian(x, z, 760, -180, 230, 410) * 62

    -- Keep the old-village bowl usable without making it look machine-flat.
    local villageBlend = gaussian(x, z, 360, 120, 250, 210)
    height = height * (1 - villageBlend * 0.58) + (45 + detailNoise * 0.25) * (villageBlend * 0.58)

    -- Southern crash crescent: a generous readable beach shelf.
    local crashShelf = gaussian(x, z, 120, 790, 360, 170)
    height = height * (1 - crashShelf * 0.75) + 8 * (crashShelf * 0.75)

    -- West mangrove basin stays low and wet.
    local mangroveBlend = gaussian(x, z, -760, 190, 300, 270)
    height = height * (1 - mangroveBlend * 0.74) + 7 * (mangroveBlend * 0.74)

    return math.max(config.SeaLevel + 2, height)
end

function TerrainBuilder.MaterialAt(config, x, z, height)
    local island = config.Island
    local nx = x / island.HalfX
    local nz = z / island.HalfZ
    local radius = math.sqrt(nx * nx + nz * nz)

    if height <= 17 or radius > 0.82 then
        return Enum.Material.Sand
    end
    if height > 175 then
        return Enum.Material.Rock
    end
    if height > 110 and math.noise(x / 75, z / 75, 2.7) > 0.08 then
        return Enum.Material.Slate
    end
    if x < -560 and z > -80 and z < 430 and height < 28 then
        return Enum.Material.Mud
    end
    return Enum.Material.Grass
end

local function yieldMaybe(counter, config)
    if counter % config.Generation.YieldEvery == 0 then
        task.wait()
    end
end

local function carveLine(terrain, config, a, b, radius, samples)
    for index = 0, samples do
        local alpha = index / samples
        local x = a.X + (b.X - a.X) * alpha
        local z = a.Z + (b.Z - a.Z) * alpha
        local surface = TerrainBuilder.HeightAt(config, x, z)
        terrain:FillBall(Vector3.new(x, surface + 5, z), radius, Enum.Material.Air)
    end
end

function TerrainBuilder.Build(config)
    local terrain = workspace.Terrain

    if config.Generation.ClearExisting then
        terrain:Clear()
    end

    -- Terrain.Decoration is intentionally not assigned here because Roblox
    -- currently exposes it as a non-scriptable property. Enable terrain
    -- decoration/grass in Studio place settings for the final art pass.
    terrain.WaterColor = Color3.fromRGB(42, 113, 135)
    terrain.WaterTransparency = 0.3
    terrain.WaterReflectance = 0.08
    terrain.WaterWaveSize = 0.16
    terrain.WaterWaveSpeed = 9

    local oceanWidth = config.WorldHalfSize * 2
    terrain:FillBlock(
        CFrame.new(0, config.SeaLevel - config.OceanDepth / 2, 0),
        Vector3.new(oceanWidth, config.OceanDepth, oceanWidth),
        Enum.Material.Water
    )

    local island = config.Island
    local grid = island.Grid
    local counter = 0

    for x = -island.HalfX - grid, island.HalfX + grid, grid do
        for z = -island.HalfZ - grid, island.HalfZ + grid, grid do
            local height = TerrainBuilder.HeightAt(config, x, z)
            if height > config.SeaLevel then
                local columnHeight = height - island.BaseY
                local material = TerrainBuilder.MaterialAt(config, x, z, height)
                terrain:FillBlock(
                    CFrame.new(x, island.BaseY + columnHeight / 2, z),
                    Vector3.new(grid + 2, columnHeight, grid + 2),
                    material
                )
            end

            counter += 1
            yieldMaybe(counter, config)
        end
    end

    -- River valley. Water surfaces are added separately by the world builder so
    -- the river can step down naturally instead of becoming one giant flat lake.
    local river = {
        Vector3.new(-80, 0, -465),
        Vector3.new(-150, 0, -350),
        Vector3.new(-260, 0, -215),
        Vector3.new(-260, 0, -130),
        Vector3.new(-340, 0, -30),
        Vector3.new(-430, 0, 80),
        Vector3.new(-520, 0, 165),
        Vector3.new(-620, 0, 230),
    }
    for i = 1, #river - 1 do
        carveLine(terrain, config, river[i], river[i + 1], 22, 8)
    end

    -- Waterfall pool and cave mouth. These are intentionally broad placeholders
    -- for a later mesh/terrain art pass.
    local poolSurface = math.max(config.SeaLevel + 7, TerrainBuilder.HeightAt(config, -275, -115) - 16)
    terrain:FillBall(Vector3.new(-275, poolSurface + 8, -115), 58, Enum.Material.Air)

    -- Cave entrance behind the waterfall and a short safe tunnel. The tunnel does
    -- not yet connect to story areas; it simply reserves underground space.
    local caveStart = Vector3.new(-315, poolSurface + 22, -160)
    local caveEnd = Vector3.new(-405, poolSurface + 28, -235)
    for i = 0, 10 do
        local t = i / 10
        local point = caveStart:Lerp(caveEnd, t)
        terrain:FillBall(point, 18 + math.sin(t * math.pi) * 4, Enum.Material.Air)
    end

    return {
        RiverPoints = river,
        PoolSurface = poolSurface,
        CaveStart = caveStart,
        CaveEnd = caveEnd,
    }
end

return TerrainBuilder
