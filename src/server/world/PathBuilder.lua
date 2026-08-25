local CollectionService = game:GetService("CollectionService")

local PathBuilder = {}

local function horizontalDistanceToSegment(point, a, b)
    local px, pz = point.X, point.Z
    local ax, az = a.X, a.Z
    local bx, bz = b.X, b.Z
    local abx, abz = bx - ax, bz - az
    local lengthSquared = abx * abx + abz * abz
    if lengthSquared <= 0.001 then
        return math.sqrt((px - ax) ^ 2 + (pz - az) ^ 2)
    end
    local t = math.clamp(((px - ax) * abx + (pz - az) * abz) / lengthSquared, 0, 1)
    local cx = ax + abx * t
    local cz = az + abz * t
    return math.sqrt((px - cx) ^ 2 + (pz - cz) ^ 2)
end

function PathBuilder.DistanceToAnyPath(config, point)
    local best = math.huge
    for _, points in pairs(config.Paths) do
        for i = 1, #points - 1 do
            best = math.min(best, horizontalDistanceToSegment(point, points[i], points[i + 1]))
        end
    end
    return best
end

local function createTrailPiece(parent, a, b, width, material, color)
    local delta = b - a
    if delta.Magnitude < 1 then
        return
    end

    local piece = Instance.new("Part")
    piece.Name = "Trail"
    piece.Anchored = true
    piece.CanCollide = false
    piece.CanTouch = false
    piece.CanQuery = false
    piece.CastShadow = false
    piece.Material = material
    piece.Color = color
    piece.Size = Vector3.new(width, 0.45, delta.Magnitude + 1)
    piece.CFrame = CFrame.lookAt((a + b) / 2, b)
    piece.Parent = parent
    piece:SetAttribute("GeneratedPlaceholder", true)
    CollectionService:AddTag(piece, "WorldPath")
end

local function buildPath(config, parent, points, width, heightAt, color)
    local sampleSpacing = 18
    for i = 1, #points - 1 do
        local from = points[i]
        local to = points[i + 1]
        local horizontalLength = Vector2.new(to.X - from.X, to.Z - from.Z).Magnitude
        local samples = math.max(1, math.ceil(horizontalLength / sampleSpacing))

        local previous = nil
        for sample = 0, samples do
            local t = sample / samples
            local x = from.X + (to.X - from.X) * t
            local z = from.Z + (to.Z - from.Z) * t
            local y = heightAt(config, x, z) + 0.35
            local current = Vector3.new(x, y, z)
            if previous then
                createTrailPiece(parent, previous, current, width, Enum.Material.Ground, color)
            end
            previous = current
        end
    end
end

function PathBuilder.Build(config, root, heightAt)
    local folder = Instance.new("Folder")
    folder.Name = "Paths"
    folder.Parent = root

    local main = Instance.new("Folder")
    main.Name = "MainTrail"
    main.Parent = folder
    buildPath(config, main, config.Paths.Main, 12, heightAt, Color3.fromRGB(96, 82, 58))

    local east = Instance.new("Folder")
    east.Name = "EastCliffLoop"
    east.Parent = folder
    buildPath(config, east, config.Paths.EastLoop, 9, heightAt, Color3.fromRGB(89, 78, 60))

    local west = Instance.new("Folder")
    west.Name = "MangroveLoop"
    west.Parent = folder
    buildPath(config, west, config.Paths.WestLoop, 8, heightAt, Color3.fromRGB(82, 72, 54))

    return folder
end

return PathBuilder
