local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assets = ReplicatedStorage:WaitForChild("ISLEZeroAssets")
local applied = setmetatable({}, {__mode = "k"})

local STATIC_KEY_OVERRIDES = {
    SafeTent = "SafeTent",
    JungleTree = "JungleTree",
    EmergentTree = "EmergentTree",
    Palm = "Palm",
    Mangrove = "Mangrove",
}

local function stripExecutableContent(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        local remove = descendant:IsA("Script")
            or descendant:IsA("LocalScript")
            or descendant:IsA("ModuleScript")
            or descendant:IsA("Humanoid")
            or descendant:IsA("Animator")
            or descendant:IsA("AnimationController")
        if remove then
            descendant:Destroy()
        end
    end
end

local function findAsset(key, preferredFolder)
    if preferredFolder then
        local folder = assets:FindFirstChild(preferredFolder)
        local preferred = folder and folder:FindFirstChild(key, true)
        if preferred and (preferred:IsA("Model") or preferred:IsA("BasePart")) then
            return preferred
        end
    end

    local found = assets:FindFirstChild(key, true)
    if found and (found:IsA("Model") or found:IsA("BasePart")) then
        return found
    end
    return nil
end

local function prepareStaticVisual(instance)
    if instance:IsA("BasePart") then
        instance.Anchored = true
        instance.CanCollide = false
        instance.CanTouch = false
        instance.CanQuery = false
        return
    end

    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
        end
    end
end

local function prepareCreatureVisual(instance, root)
    local parts = {}
    if instance:IsA("BasePart") then
        table.insert(parts, instance)
    else
        for _, descendant in ipairs(instance:GetDescendants()) do
            if descendant:IsA("BasePart") then
                table.insert(parts, descendant)
            end
        end
    end

    for _, part in ipairs(parts) do
        part.Anchored = false
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Massless = true

        local weld = Instance.new("WeldConstraint")
        weld.Name = "ISLEZeroVisualWeld"
        weld.Part0 = root
        weld.Part1 = part
        weld.Parent = root
    end
end

local function pivotInstance(instance, cframe)
    local offsetY = instance:GetAttribute("ISLEZeroYOffset") or 0
    local yaw = math.rad(instance:GetAttribute("ISLEZeroYaw") or 0)
    local target = cframe * CFrame.new(0, offsetY, 0) * CFrame.Angles(0, yaw, 0)

    if instance:IsA("Model") then
        instance:PivotTo(target)
    elseif instance:IsA("BasePart") then
        instance.CFrame = target
    end
end

local function hideGeneratedVisuals(model, exceptRoot)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant ~= exceptRoot then
            descendant.Transparency = 1
            for _, child in ipairs(descendant:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") then
                    child.Transparency = 1
                end
            end
        end
    end
end

local function staticAssetKey(model)
    local explicit = model:GetAttribute("AssetKey")
    if explicit then
        return tostring(explicit)
    end

    if string.sub(model.Name, 1, 11) == "WorldChest_" then
        return "WorldChest"
    end
    if string.sub(model.Name, 1, 6) == "Chest_" then
        return "CaveChest"
    end

    return STATIC_KEY_OVERRIDES[model.Name] or model.Name
end

local function preferredStaticFolder(model, key)
    if key == "JungleTree" or key == "EmergentTree" or key == "Palm" or key == "Mangrove" then
        return "Nature"
    end
    if key == "WorldChest" or key == "CaveChest" then
        return "Props"
    end
    if model.Name == "SafeTent" then
        return "Structures"
    end
    return "Structures"
end

local function tryCreature(model)
    if applied[model] or not model:IsA("Model") then
        return false
    end

    local guardianType = model:GetAttribute("GuardianType")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not guardianType or not root or not root:IsA("BasePart") then
        return false
    end
    if not CollectionService:HasTag(model, "CaveGuardian") and model:GetAttribute("WorldEnemy") ~= true then
        return false
    end

    local source = findAsset(tostring(guardianType), "Creatures")
    if not source then
        return false
    end

    hideGeneratedVisuals(model, root)

    local visual = source:Clone()
    visual.Name = "AUTHORED_" .. tostring(guardianType)
    stripExecutableContent(visual)
    visual.Parent = model
    pivotInstance(visual, root.CFrame)
    prepareCreatureVisual(visual, root)

    applied[model] = true
    model:SetAttribute("VisualAssetApplied", true)
    model:SetAttribute("VisualAssetKey", tostring(guardianType))
    return true
end

local function tryStatic(model)
    if applied[model] or not model:IsA("Model") then
        return false
    end
    if model:GetAttribute("WorldEnemy") == true or model:GetAttribute("GuardianType") then
        return false
    end

    local isCandidate = model:GetAttribute("GeneratedPlaceholder") == true
        or model.Name == "SafeTent"
        or string.sub(model.Name, 1, 11) == "WorldChest_"
        or string.sub(model.Name, 1, 6) == "Chest_"

    if not isCandidate then
        return false
    end

    local key = staticAssetKey(model)
    local source = findAsset(key, preferredStaticFolder(model, key))
    if not source then
        return false
    end

    local visual = source:Clone()
    visual.Name = "AUTHORED_" .. key
    stripExecutableContent(visual)
    visual.Parent = model.Parent
    pivotInstance(visual, model:GetPivot())
    prepareStaticVisual(visual)
    hideGeneratedVisuals(model, nil)

    applied[model] = true
    model:SetAttribute("VisualAssetApplied", true)
    model:SetAttribute("VisualAssetKey", key)
    return true
end

local function tryApply(instance)
    if not instance:IsA("Model") then
        return
    end
    if tryCreature(instance) then
        return
    end
    tryStatic(instance)
end

local function scanWorld()
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    if root then
        tryApply(root)
        for _, descendant in ipairs(root:GetDescendants()) do
            if descendant:IsA("Model") then
                tryApply(descendant)
            end
        end
    end

    for _, guardian in ipairs(CollectionService:GetTagged("CaveGuardian")) do
        if guardian:IsA("Model") then
            tryCreature(guardian)
        end
    end
end

CollectionService:GetInstanceAddedSignal("CaveGuardian"):Connect(function(model)
    task.delay(0.15, tryCreature, model)
end)

workspace.DescendantAdded:Connect(function(instance)
    if instance:IsA("Model") and (instance.Name == "SafeTent" or instance:GetAttribute("GeneratedPlaceholder") == true) then
        task.delay(0.15, tryApply, instance)
    end
end)

assets.DescendantAdded:Connect(function()
    task.delay(0.25, scanWorld)
end)

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.35, scanWorld)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(0.35, scanWorld)
end
