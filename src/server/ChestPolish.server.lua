local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local bound = setmetatable({}, {__mode = "k"})

local function chestColors(tier)
    if tier == "Relic" then
        return Color3.fromRGB(66, 42, 91), Color3.fromRGB(104, 66, 145), Color3.fromRGB(181, 158, 201), Color3.fromRGB(164, 94, 255)
    elseif tier == "Deep" then
        return Color3.fromRGB(28, 39, 51), Color3.fromRGB(37, 62, 82), Color3.fromRGB(196, 157, 73), Color3.fromRGB(92, 166, 225)
    end
    return Color3.fromRGB(91, 63, 37), Color3.fromRGB(112, 77, 43), Color3.fromRGB(75, 77, 73), Color3.fromRGB(225, 164, 88)
end

local function restoreChest(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and (descendant.Name == "ChestBody" or descendant.Name == "ChestLid" or descendant.Name == "MetalBand") then
            descendant.Transparency = 0
        end
    end
end

local function animateOpen(model, lid)
    if model:GetAttribute("PolishOpenAnimated") then
        return
    end
    model:SetAttribute("PolishOpenAnimated", true)

    local closed = lid:GetAttribute("PolishClosedCFrame")
    if typeof(closed) ~= "CFrame" then
        closed = lid.CFrame
    end

    lid.CFrame = closed
    local goal = closed * CFrame.new(0, 1.15, -1.15) * CFrame.Angles(math.rad(-58), 0, 0)
    local tween = TweenService:Create(
        lid,
        TweenInfo.new(0.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {CFrame = goal}
    )
    tween:Play()
end

local function bindChest(base)
    if bound[base] or not base:IsA("BasePart") or not base.Parent or not base.Parent:IsA("Model") then
        return
    end
    bound[base] = true

    local model = base.Parent
    restoreChest(model)

    local tier = base:GetAttribute("LootTier") or "Supplies"
    local bodyColor, lidColor, bandColor, glowColor = chestColors(tier)
    base.Color = bodyColor
    base.Material = Enum.Material.WoodPlanks

    local lid = model:FindFirstChild("ChestLid")
    if lid and lid:IsA("BasePart") then
        lid.Color = lidColor
        lid.Material = Enum.Material.WoodPlanks
        lid.Transparency = 0
        lid:SetAttribute("PolishClosedCFrame", lid.CFrame)

        local oldGlow = lid:FindFirstChild("ChestGlow")
        if oldGlow then
            oldGlow:Destroy()
        end

        if tier == "Relic" or tier == "Deep" then
            local glow = Instance.new("PointLight")
            glow.Name = "ChestGlow"
            glow.Color = glowColor
            glow.Brightness = 0.75
            glow.Range = 10
            glow.Shadows = false
            glow.Parent = lid
        end
    end

    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") and child.Name == "MetalBand" then
            child.Color = bandColor
            child.Material = Enum.Material.Metal
            child.Transparency = 0
        end
    end

    local prompt = base:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.Name = "OpenChestPrompt"
        prompt.Parent = base
    end

    prompt.Enabled = true
    prompt.ActionText = "Open"
    if tier == "Relic" then
        prompt.ObjectText = "Purple relic cache"
    elseif tier == "Deep" then
        prompt.ObjectText = "Deep treasure cache"
    else
        prompt.ObjectText = "Supply cache"
    end
    prompt.HoldDuration = 0.35
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false

    prompt.Triggered:Connect(function()
        task.delay(0.06, function()
            if model.Parent and lid and lid.Parent and model:GetAttribute("OpenedVisual") == true then
                animateOpen(model, lid)
            end
        end)
    end)
end

local function scan()
    for _, chest in ipairs(CollectionService:GetTagged("LootChest")) do
        if chest:IsA("BasePart") and chest:IsDescendantOf(workspace) then
            bindChest(chest)
        end
    end
end

CollectionService:GetInstanceAddedSignal("LootChest"):Connect(function(chest)
    if chest:IsA("BasePart") then
        task.delay(0.3, bindChest, chest)
    end
end)

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.5, scan)
        task.delay(1.8, scan)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(0.5, scan)
end
