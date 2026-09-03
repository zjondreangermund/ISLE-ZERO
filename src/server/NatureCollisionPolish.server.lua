local CollectionService = game:GetService("CollectionService")

local NATURE_KEYS = {
    JungleTree = true,
    EmergentTree = true,
    Palm = true,
    Mangrove = true,
}

local PROXY_SETTINGS = {
    JungleTree = {Width = 2.6, Height = 12},
    EmergentTree = {Width = 3.3, Height = 15},
    Palm = {Width = 1.9, Height = 11},
    Mangrove = {Width = 2.2, Height = 9},
}

local processed = setmetatable({}, {__mode = "k"})

local function disableHiddenPlaceholderCollision(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name ~= "ISLEZeroTreeCollision" then
            if descendant.Transparency >= 0.95 or model:GetAttribute("VisualAssetApplied") == true then
                descendant.CanCollide = false
                descendant.CanTouch = false
                descendant.CanQuery = false
            end
        end
    end
end

local function groundPointFor(model)
    local trunk = model:FindFirstChild("Trunk", true)
    local samplePosition = trunk and trunk.Position or model:GetPivot().Position

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {model}
    params.IgnoreWater = false

    local origin = samplePosition + Vector3.new(0, 80, 0)
    local result = workspace:Raycast(origin, Vector3.new(0, -220, 0), params)
    if result then
        return result.Position
    end

    local boxCFrame, boxSize = model:GetBoundingBox()
    return Vector3.new(samplePosition.X, boxCFrame.Position.Y - boxSize.Y / 2, samplePosition.Z)
end

local function createCollisionProxy(model, key)
    local existing = model:FindFirstChild("ISLEZeroTreeCollision")
    if existing and existing:IsA("BasePart") then
        return existing
    end

    local settings = PROXY_SETTINGS[key]
    if not settings then
        return nil
    end

    local ground = groundPointFor(model)
    local proxy = Instance.new("Part")
    proxy.Name = "ISLEZeroTreeCollision"
    proxy.Size = Vector3.new(settings.Width, settings.Height, settings.Width)
    proxy.CFrame = CFrame.new(ground + Vector3.new(0, settings.Height / 2, 0))
    proxy.Transparency = 1
    proxy.Anchored = true
    proxy.CanCollide = true
    proxy.CanTouch = false
    proxy.CanQuery = true
    proxy.CastShadow = false
    proxy.TopSurface = Enum.SurfaceType.Smooth
    proxy.BottomSurface = Enum.SurfaceType.Smooth
    proxy:SetAttribute("CollisionProxy", true)
    proxy.Parent = model
    return proxy
end

local function polishNatureModel(model)
    if not model:IsA("Model") or processed[model] then
        return
    end

    local key = tostring(model:GetAttribute("VisualAssetKey") or model.Name)
    if not NATURE_KEYS[key] then
        return
    end

    if model:GetAttribute("VisualAssetApplied") ~= true then
        return
    end

    disableHiddenPlaceholderCollision(model)
    createCollisionProxy(model, key)
    processed[model] = true
    model:SetAttribute("CollisionPolished", true)
end

local function scanRoot(root)
    if not root then
        return
    end

    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("Model") then
            polishNatureModel(descendant)
        end
    end
end

local function schedulePolish(model)
    if not model:IsA("Model") then
        return
    end

    task.delay(0.2, function()
        if model.Parent then
            polishNatureModel(model)
        end
    end)
end

CollectionService:GetInstanceAddedSignal("WorldVegetation"):Connect(function(instance)
    if instance:IsA("Model") then
        schedulePolish(instance)
    end
end)

workspace.DescendantAdded:Connect(function(instance)
    if instance:IsA("Model") then
        schedulePolish(instance)
    end
end)

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.5, function()
            scanRoot(workspace:FindFirstChild("ISLE_ZERO_WORLD"))
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        scanRoot(workspace:FindFirstChild("ISLE_ZERO_WORLD"))
    end
end)
