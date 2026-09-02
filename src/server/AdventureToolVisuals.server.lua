local Players = game:GetService("Players")

local function weld(handle, object)
    local constraint = Instance.new("WeldConstraint")
    constraint.Part0 = handle
    constraint.Part1 = object
    constraint.Parent = handle
end

local function addPart(tool, handle, name, size, offset, material, color)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.CFrame = handle.CFrame * offset
    object.Material = material
    object.Color = color
    object.Anchored = false
    object.CanCollide = false
    object.CanTouch = false
    object.Massless = true
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = tool
    weld(handle, object)
    return object
end

local function styleTool(tool)
    if not tool:IsA("Tool") or tool:GetAttribute("AdventureStyled") then
        return
    end
    local itemId = tool:GetAttribute("ItemId")
    local handle = tool:FindFirstChild("Handle")
    if not itemId or not handle or not handle:IsA("BasePart") then
        return
    end

    if itemId == "HunterSpear" then
        tool:SetAttribute("AdventureStyled", true)
        handle.Size = Vector3.new(0.55, 6.5, 0.55)
        handle.Material = Enum.Material.Wood
        handle.Color = Color3.fromRGB(102, 73, 46)
        tool.Grip = CFrame.new(0, -1.4, 0) * CFrame.Angles(0, 0, math.rad(-8))
        addPart(tool, handle, "SpearHead", Vector3.new(0.35, 2.4, 1.15), CFrame.new(0, 4.1, 0), Enum.Material.Metal, Color3.fromRGB(161, 167, 164))
        addPart(tool, handle, "SpearBinding", Vector3.new(0.8, 0.9, 0.8), CFrame.new(0, 2.8, 0), Enum.Material.Fabric, Color3.fromRGB(120, 91, 56))
    elseif itemId == "SteelAxe" then
        tool:SetAttribute("AdventureStyled", true)
        handle.Size = Vector3.new(0.65, 5.2, 0.65)
        handle.Material = Enum.Material.Wood
        handle.Color = Color3.fromRGB(94, 65, 42)
        tool.Grip = CFrame.new(0, -1.1, 0) * CFrame.Angles(0, 0, math.rad(-5))
        addPart(tool, handle, "AxeHead", Vector3.new(3.2, 1.5, 0.55), CFrame.new(0.9, 2.7, 0), Enum.Material.Metal, Color3.fromRGB(135, 142, 143))
        addPart(tool, handle, "AxeEdge", Vector3.new(1.5, 2.1, 0.32), CFrame.new(2.1, 2.7, 0) * CFrame.Angles(0, 0, math.rad(16)), Enum.Material.Metal, Color3.fromRGB(190, 194, 191))
    elseif itemId == "IcePick" then
        tool:SetAttribute("AdventureStyled", true)
        handle.Size = Vector3.new(0.65, 4.8, 0.65)
        handle.Material = Enum.Material.Metal
        handle.Color = Color3.fromRGB(82, 94, 101)
        tool.Grip = CFrame.new(0, -0.9, 0) * CFrame.Angles(0, 0, math.rad(-6))
        addPart(tool, handle, "PickHead", Vector3.new(4.1, 0.55, 0.55), CFrame.new(0, 2.5, 0), Enum.Material.Metal, Color3.fromRGB(148, 190, 205))
        local glow = addPart(tool, handle, "IceGlow", Vector3.new(0.55, 1.2, 0.55), CFrame.new(1.7, 2.5, 0), Enum.Material.Neon, Color3.fromRGB(118, 210, 232))
        local light = Instance.new("PointLight")
        light.Brightness = 0.8
        light.Range = 8
        light.Color = glow.Color
        light.Parent = glow
    elseif itemId == "AncientCompass" then
        tool:SetAttribute("AdventureStyled", true)
        handle.Size = Vector3.new(2.4, 0.7, 2.4)
        handle.Shape = Enum.PartType.Cylinder
        handle.Material = Enum.Material.Metal
        handle.Color = Color3.fromRGB(176, 142, 68)
        tool.Grip = CFrame.new(0, -0.2, 0) * CFrame.Angles(0, 0, math.rad(90))
        addPart(tool, handle, "CompassNeedle", Vector3.new(0.2, 0.25, 1.6), CFrame.new(0, 0.48, 0), Enum.Material.Neon, Color3.fromRGB(178, 55, 48))
    elseif itemId == "ExplorerRelic" then
        tool:SetAttribute("AdventureStyled", true)
        handle.Size = Vector3.new(2.2, 2.2, 2.2)
        handle.Shape = Enum.PartType.Ball
        handle.Material = Enum.Material.Neon
        handle.Color = Color3.fromRGB(226, 185, 78)
        local light = Instance.new("PointLight")
        light.Brightness = 2.2
        light.Range = 15
        light.Color = handle.Color
        light.Parent = handle
    end
end

local function bindContainer(container)
    for _, child in ipairs(container:GetChildren()) do
        task.defer(styleTool, child)
    end
    container.ChildAdded:Connect(function(child)
        task.defer(styleTool, child)
    end)
end

local function bindPlayer(player)
    local backpack = player:WaitForChild("Backpack")
    bindContainer(backpack)
    player.CharacterAdded:Connect(bindContainer)
    if player.Character then
        bindContainer(player.Character)
    end
end

Players.PlayerAdded:Connect(bindPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    task.defer(bindPlayer, player)
end
