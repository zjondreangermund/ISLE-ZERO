local CollectionService = game:GetService("CollectionService")

local SignpostBuilder = {}

local function part(parent, name, size, cframe, material, color)
    local object = Instance.new("Part")
    object.Name = name
    object.Anchored = true
    object.CanTouch = false
    object.Size = size
    object.CFrame = cframe
    object.Material = material
    object.Color = color
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = parent
    object:SetAttribute("GeneratedPlaceholder", true)
    return object
end

local function addBoardText(board, text)
    local surface = Instance.new("SurfaceGui")
    surface.Name = "DirectionText"
    surface.Face = Enum.NormalId.Front
    surface.AlwaysOnTop = false
    surface.LightInfluence = 0.7
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 32
    surface.Parent = board

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(227, 215, 177)
    label.TextStrokeColor3 = Color3.fromRGB(48, 36, 24)
    label.TextStrokeTransparency = 0.35
    label.Parent = surface

    local back = Instance.new("SurfaceGui")
    back.Name = "DirectionTextBack"
    back.Face = Enum.NormalId.Back
    back.AlwaysOnTop = false
    back.LightInfluence = 0.7
    back.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    back.PixelsPerStud = 32
    back.Parent = board

    local backLabel = label:Clone()
    backLabel.Parent = back
end

local function buildOne(config, folder, sign, heightAt)
    local y = heightAt(config, sign.Position.X, sign.Position.Z)
    local yaw = math.rad(sign.Yaw or 0)
    local base = CFrame.new(sign.Position.X, y, sign.Position.Z) * CFrame.Angles(0, yaw, 0)

    local model = Instance.new("Model")
    model.Name = sign.Name or "TrailSign"
    model.Parent = folder
    model:SetAttribute("GeneratedPlaceholder", true)
    model:SetAttribute("Signpost", true)
    CollectionService:AddTag(model, "TrailSign")

    local post = part(
        model,
        "Post",
        Vector3.new(1.7, 13, 1.7),
        base * CFrame.new(0, 6.5, 0),
        Enum.Material.Wood,
        Color3.fromRGB(82, 57, 35)
    )
    post.CanCollide = true

    local lines = sign.Lines or {}
    for index, text in ipairs(lines) do
        local width = math.max(13, math.min(24, 9 + string.len(text) * 0.55))
        local boardYaw = math.rad((index - 1) * 4 - (#lines - 1) * 2)
        local board = part(
            model,
            "DirectionBoard",
            Vector3.new(width, 3.5, 0.75),
            base * CFrame.new(0, 11.2 - (index - 1) * 3.35, -0.6) * CFrame.Angles(0, boardYaw, math.rad((index % 2 == 0) and -1.2 or 1.2)),
            Enum.Material.WoodPlanks,
            Color3.fromRGB(99, 71, 43)
        )
        board.CanCollide = false
        board.CanQuery = false
        addBoardText(board, text)
    end

    local cap = part(
        model,
        "PostCap",
        Vector3.new(2.4, 0.7, 2.4),
        base * CFrame.new(0, 13.1, 0),
        Enum.Material.Wood,
        Color3.fromRGB(70, 49, 31)
    )
    cap.CanCollide = false

    return model
end

function SignpostBuilder.Build(config, worldRoot, heightAt)
    local folder = Instance.new("Folder")
    folder.Name = "TrailSigns"
    folder.Parent = worldRoot

    local count = 0
    local signs = (config.Exploration and config.Exploration.Signposts) or {}
    for _, sign in ipairs(signs) do
        buildOne(config, folder, sign, heightAt)
        count += 1
    end

    folder:SetAttribute("SignpostCount", count)
    print(string.format("[ISLE//ZERO][SIGNS] Built %d wooden direction signposts", count))
    return folder
end

return SignpostBuilder
