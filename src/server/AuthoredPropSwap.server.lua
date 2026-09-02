local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assets = ReplicatedStorage:WaitForChild("ISLEZeroAssets")
local propsFolder = assets:WaitForChild("Props")
local furnitureFolder = assets:WaitForChild("Furniture")

local PROP_KEYS = {
    SupplyCrate = "Props",
    OldBarrel = "Props",
    ExpeditionPack = "Props",
    FieldJournal = "Props",
    OldSurveyScope = "Props",
    FireRingStone = "Props",
    TidePoolRock = "Props",
    Bedroll = "Furniture",
    Campfire = "Props",
}

local applied = setmetatable({}, {__mode = "k"})

local function normalize(value)
    return string.lower((string.gsub(tostring(value), "[%s_%-]", "")))
end

local function sourceFor(key, folderName)
    local folder = folderName == "Furniture" and furnitureFolder or propsFolder
    for _, child in ipairs(folder:GetChildren()) do
        if (child:IsA("Model") or child:IsA("BasePart")) and normalize(child.Name) == normalize(key) then
            return child
        end
    end
    for _, descendant in ipairs(folder:GetDescendants()) do
        if (descendant:IsA("Model") or descendant:IsA("BasePart")) and normalize(descendant.Name) == normalize(key) then
            return descendant
        end
    end
    return nil
end

local function stripExecutableContent(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") or descendant:IsA("Humanoid") then
            descendant:Destroy()
        end
    end
end

local function prepare(instance)
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

local function place(instance, target)
    local offsetY = instance:GetAttribute("ISLEZeroYOffset") or 0
    local yaw = math.rad(instance:GetAttribute("ISLEZeroYaw") or 0)
    local pitch = math.rad(instance:GetAttribute("ISLEZeroPitch") or 0)
    local roll = math.rad(instance:GetAttribute("ISLEZeroRoll") or 0)
    local targetCFrame = target.CFrame * CFrame.new(0, offsetY, 0) * CFrame.Angles(pitch, yaw, roll)

    if instance:IsA("Model") then
        local scale = instance:GetAttribute("ISLEZeroScale")
        if typeof(scale) == "number" and scale > 0 then
            pcall(function()
                instance:ScaleTo(scale)
            end)
        end
        instance:PivotTo(targetCFrame)
    else
        instance.CFrame = targetCFrame
    end
end

local function apply(part)
    if applied[part] or not part:IsA("BasePart") or not part:IsDescendantOf(workspace) then
        return
    end
    local folderName = PROP_KEYS[part.Name]
    if not folderName then
        return
    end
    if part:GetAttribute("GeneratedPlaceholder") ~= true then
        return
    end

    local source = sourceFor(part.Name, folderName)
    if not source then
        return
    end

    local visual = source:Clone()
    visual.Name = "AUTHORED_PROP_" .. part.Name
    stripExecutableContent(visual)
    visual.Parent = part.Parent
    place(visual, part)
    prepare(visual)
    part.Transparency = 1

    applied[part] = true
    part:SetAttribute("VisualAssetApplied", true)
    part:SetAttribute("VisualAssetSource", source.Name)
end

local function scan()
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    if not root then
        return
    end
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") and PROP_KEYS[descendant.Name] then
            apply(descendant)
        end
    end
end

workspace.DescendantAdded:Connect(function(instance)
    if instance:IsA("BasePart") and PROP_KEYS[instance.Name] then
        task.delay(0.1, apply, instance)
    end
end)

propsFolder.DescendantAdded:Connect(function()
    task.delay(0.2, scan)
end)
furnitureFolder.DescendantAdded:Connect(function()
    task.delay(0.2, scan)
end)

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.35, scan)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(0.35, scan)
end
