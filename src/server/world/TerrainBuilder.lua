local TerrainBuilder = {}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function gaussian(x, z, cx, cz, sx, sz)
    local dx = (x - cx) / sx
    local dz = (z - cz) / sz
    return math.exp(-(dx * dx + dz * dz))
end

local function horizontalDistanceToSegment(x, z, a, b)
    local abx = b.X - a.X
    local abz = b.Z - a.Z
    local lengthSquared = abx * abx + abz * abz
    if lengthSquared < 0.001 then
        local dx = x - a.X
        local dz = z - a.Z
        return math.sqrt(dx * dx + dz * dz)
    end

    local t = math.clamp(((x - a.X) * abx + (z - a.Z) * abz) / lengthSquared, 0, 1)
    local cx = a.X + abx * t
    local cz = a.Z + abz * t
    local dx = x - cx
    local dz = z - cz
    return math.sqrt(dx * dx + dz * dz)
end

local function distanceToRiver(config, x, z)
    local waterways = config.Waterways
    if not waterways or not waterways.MainRiver then
        return math.huge
    end

    local best = math.huge
    local points = waterways.MainRiver
    for i = 1, #points - 1 do
        best = math.min(best, horizontalDistanceToSegment(x, z, points[i], points[i + 1]))
    end
    return best
end

function TerrainBuilder.HeightAt(config, x, z)
    local island = config.Island
    local nx = x / island.HalfX
    local nz = z / island.HalfZ

    local coastNoise = math.noise(x / 310, z / 310, config.Seed * 0.0001) * 0.08
    local fineCoast = math.noise(x / 120, z / 120, config.Seed * 0.0003) * 0.025
    local radius = math.sqrt(nx * nx + nz * nz) - coastNoise - fineCoast
    local edge = 1 - radius

    if edge <= 0 then
        return config.SeaLevel - 12 - math.abs(edge) * 55
    end

    local height
    local beachBand = island.BeachBand or 0.30
    if edge < beachBand then
        local t = edge / beachBand
        height = 3 + (t ^ 1.18) * 18
    else
        local t = clamp((edge - beachBand) / (1 - beachBand), 0, 1)
        height = 21 + (t ^ 1.12) * 78
    end

    local broadNoise = math.noise(x / 280, z / 280, config.Seed * 0.001) * 12
    local detailNoise = math.noise(x / 105, z / 105, config.Seed * 0.002) * 4.2
    height += broadNoise + detailNoise

    -- Northern Frostpeak is deliberately a multi-peak massif rather than a
    -- single dome. Stonefall occupies the eastern shoulder below it.
    local frostCore = gaussian(x, z, -155, -690, 365, 305)
    local frostWest = gaussian(x, z, -355, -675, 230, 235)
    local frostEast = gaussian(x, z, 40, -735, 235, 220)
    height += frostCore * 174
    height += frostWest * 72
    height += frostEast * 58

    local stonefallShoulder = gaussian(x, z, 280, -500, 330, 245)
    height += stonefallShoulder * 70
    height += gaussian(x, z, 760, -180, 245, 420) * 58

    local mountainBlend = math.max(frostCore, frostWest, frostEast)
    height -= detailNoise * mountainBlend * 0.78

    local villageBlend = gaussian(x, z, 360, 120, 250, 210)
    height = height * (1 - villageBlend * 0.58) + (45 + detailNoise * 0.2) * (villageBlend * 0.58)

    local crashShelf = gaussian(x, z, 120, 790, 360, 170)
    height = height * (1 - crashShelf * 0.75) + 8 * (crashShelf * 0.75)

    local mangroveBlend = gaussian(x, z, -760, 190, 300, 270)
    height = height * (1 - mangroveBlend * 0.74) + 7 * (mangroveBlend * 0.74)

    local ruinsBlend = gaussian(x, z, 260, -515, 150, 115)
    height = height * (1 - ruinsBlend * 0.72) + (202 + broadNoise * 0.06) * (ruinsBlend * 0.72)

    local summitBlend = gaussian(x, z, -150, -690, 125, 105)
    height = height * (1 - summitBlend * 0.5) + (300 + broadNoise * 0.05) * (summitBlend * 0.5)

    -- Keep a readable central plains basin like the illustrated world map.
    local plainsBlend = gaussian(x, z, 80, 90, 340, 310)
    height = height * (1 - plainsBlend * 0.32) + (55 + broadNoise * 0.25) * (plainsBlend * 0.32)

    local waterways = config.Waterways
    if waterways then
        local bankBlend = waterways.RiverBankBlend or 62
        local riverDistance = distanceToRiver(config, x, z)
        if riverDistance < bankBlend then
            local t = 1 - riverDistance / bankBlend
            height -= (t * t) * 7
        end
    end

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

    local frostDistance = Vector2.new(x + 150, z + 690).Magnitude
    if z < -430 and frostDistance < 450 then
        local snowNoise = math.noise(x / 95, z / 95, config.Seed * 0.004)
        if height > 225 then
            return snowNoise > 0.28 and Enum.Material.Ice or Enum.Material.Snow
        end
        if height > 165 then
            if snowNoise > -0.28 then
                return Enum.Material.Snow
            end
            return Enum.Material.Rock
        end
        if height > 125 and snowNoise > 0.38 then
            return Enum.Material.Snow
        end
    end

    local rockNoise = math.noise(x / 115, z / 115, config.Seed * 0.00083)
    if height > 245 then
        return Enum.Material.Rock
    end
    if height > 178 and rockNoise > -0.08 then
        return Enum.Material.Rock
    end
    if height > 125 and rockNoise > 0.26 then
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

local function sampleSegment(a, b, spacing, callback)
    local horizontalLength = Vector2.new(b.X - a.X, b.Z - a.Z).Magnitude
    local samples = math.max(1, math.ceil(horizontalLength / spacing))
    for index = 0, samples do
        local alpha = index / samples
        callback(
            a.X + (b.X - a.X) * alpha,
            a.Z + (b.Z - a.Z) * alpha,
            index,
            samples
        )
    end
end

local function carveRiver(terrain, config, river)
    local radius = ((config.Waterways and config.Waterways.RiverWidth) or 24) * 0.72
    for i = 1, #river - 1 do
        sampleSegment(river[i], river[i + 1], 12, function(x, z)
            local surface = TerrainBuilder.HeightAt(config, x, z)
            terrain:FillBall(Vector3.new(x, surface + 3, z), radius, Enum.Material.Air)
        end)
    end
end

local function fillRiverWater(terrain, config, river)
    local waterways = config.Waterways or {}
    local width = waterways.RiverWidth or 24
    local depth = waterways.RiverDepth or 8

    for i = 1, #river - 1 do
        local a = river[i]
        local b = river[i + 1]
        local horizontalLength = Vector2.new(b.X - a.X, b.Z - a.Z).Magnitude
        local samples = math.max(1, math.ceil(horizontalLength / 12))

        for sample = 0, samples - 1 do
            local t0 = sample / samples
            local t1 = (sample + 1) / samples
            local ax = a.X + (b.X - a.X) * t0
            local az = a.Z + (b.Z - a.Z) * t0
            local bx = a.X + (b.X - a.X) * t1
            local bz = a.Z + (b.Z - a.Z) * t1
            local ay = TerrainBuilder.HeightAt(config, ax, az) - 7.5
            local by = TerrainBuilder.HeightAt(config, bx, bz) - 7.5
            local midpoint = Vector3.new((ax + bx) / 2, (ay + by) / 2 - depth / 2, (az + bz) / 2)
            local target = Vector3.new(bx, midpoint.Y, bz)
            local length = Vector2.new(bx - ax, bz - az).Magnitude + 4
            terrain:FillBlock(
                CFrame.lookAt(midpoint, target),
                Vector3.new(width, depth, length),
                Enum.Material.Water
            )
        end
    end
end

function TerrainBuilder.Build(config)
    local terrain = workspace.Terrain

    if config.Generation.ClearExisting then
        terrain:Clear()
    end

    terrain.WaterColor = Color3.fromRGB(39, 118, 142)
    terrain.WaterTransparency = 0.24
    terrain.WaterReflectance = 0.1
    terrain.WaterWaveSize = 0.13
    terrain.WaterWaveSpeed = 8

    local oceanWidth = config.WorldHalfSize * 2
    terrain:FillBlock(
        CFrame.new(0, config.SeaLevel - config.OceanDepth / 2, 0),
        Vector3.new(oceanWidth, config.OceanDepth, oceanWidth),
        Enum.Material.Water
    )

    local island = config.Island
    local grid = island.Grid
    local counter = 0
    local filledColumns = 0

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
                filledColumns += 1
            end

            counter += 1
            yieldMaybe(counter, config)
        end
    end

    local waterways = config.Waterways or {}
    local river = waterways.MainRiver or {
        Vector3.new(-80, 0, -465),
        Vector3.new(-260, 0, -130),
        Vector3.new(-620, 0, 230),
    }

    carveRiver(terrain, config, river)

    local poolCenter = waterways.PoolCenter or Vector3.new(-275, 0, -115)
    local poolRadius = waterways.PoolRadius or 50
    local poolDepth = waterways.PoolDepth or 10
    local poolSurface = math.max(
        config.SeaLevel + 7,
        TerrainBuilder.HeightAt(config, poolCenter.X, poolCenter.Z) - 14
    )

    terrain:FillBall(Vector3.new(poolCenter.X, poolSurface + 5, poolCenter.Z), poolRadius + 7, Enum.Material.Air)
    terrain:FillCylinder(
        CFrame.new(poolCenter.X, poolSurface - poolDepth / 2, poolCenter.Z),
        poolDepth,
        poolRadius,
        Enum.Material.Water
    )

    fillRiverWater(terrain, config, river)

    return {
        RiverPoints = river,
        PoolCenter = poolCenter,
        PoolSurface = poolSurface,
        PoolRadius = poolRadius,
        SampledCells = counter,
        FilledColumns = filledColumns,
    }
end

return TerrainBuilder
