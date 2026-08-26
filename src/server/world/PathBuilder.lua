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

local function distanceToRiver(config, point)
    local waterways = config.Waterways
    if not waterways or not waterways.MainRiver then
        return math.huge
    end

    local best = math.huge
    local river = waterways.MainRiver
    for i = 1, #river - 1 do
        best = math.min(best, horizontalDistanceToSegment(point, river[i], river[i + 1]))
    end
    return best
end

local function createTrailPiece(parent, a, b, width, material, color)
    local horizontalDelta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
    local length = horizontalDelta.Magnitude
    if length < 0.75 then
        return
    end

    local midpoint = Vector3.new((a.X + b.X) / 2, (a.Y + b.Y) / 2, (a.Z + b.Z) / 2)
    local target = midpoint + horizontalDelta

    local piece = Instance.new("Part")
    piece.Name = "Trail"
    piece.Anchored = true
    piece.CanCollide = false
    piece.CanTouch = false
    piece.CanQuery = false
    piece.CastShadow = false
    piece.Material = material
    piece.Color = color
    piece.Transparency = 0.08
    piece.Size = Vector3.new(width, 0.24, length + 1.4)
    piece.CFrame = CFrame.lookAt(midpoint, target)
    piece.Parent = parent
    piece:SetAttribute("GeneratedPlaceholder", true)
    CollectionService:AddTag(piece, "WorldPath")
end

local function buildPath(config, parent, points, width, heightAt, color)
    local sampleSpacing = 9
    local riverClearance = (((config.Waterways or {}).RiverWidth) or 24) * 0.72

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
            local y = heightAt(config, x, z) + 0.28
            local current = Vector3.new(x, y, z)

            if previous then
                local midpoint = (previous + current) / 2
                if distanceToRiver(config, midpoint) > riverClearance then
                    createTrailPiece(parent, previous, current, width, Enum.Material.Ground, color)
                end
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
    buildPath(config, main, config.Paths.Main, 10, heightAt, Color3.fromRGB(91, 78, 57))

    local east = Instance.new("Folder")
    east.Name = "EastCliffLoop"
    east.Parent = folder
    buildPath(config, east, config.Paths.EastLoop, 7.5, heightAt, Color3.fromRGB(85, 75, 58))

    local west = Instance.new("Folder")
    west.Name = "MangroveLoop"
    west.Parent = folder
    buildPath(config, west, config.Paths.WestLoop, 7, heightAt, Color3.fromRGB(78, 70, 54))

    return folder
end

return PathBuilder
