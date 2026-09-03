local BROKEN_MESH_IDS = {
    ["4701218333"] = true,
    ["4694750324"] = true,
}

local NATURE_PREFIXES = {
    "AUTHORED_JungleTree_",
    "AUTHORED_EmergentTree_",
    "AUTHORED_Palm_",
    "AUTHORED_Mangrove_",
}

local REJECTED_PREFIXES = {
    "AUTHORED_TreeHouse_",
    "AUTHORED_CaveChest_",
    "AUTHORED_WorldChest_",
    "AUTHORED_BlackJaguar",
    "AUTHORED_JungleStalker",
}

local function startsWith(value, prefix)
    return string.sub(value, 1, #prefix) == prefix
end

local function isNatureVisual(instance)
    for _, prefix in ipairs(NATURE_PREFIXES) do
        if startsWith(instance.Name, prefix) then
            return true
        end
    end
    return false
end

local function shouldRejectByName(instance)
    for _, prefix in ipairs(REJECTED_PREFIXES) do
        if startsWith(instance.Name, prefix) then
            return true
        end
    end
    return false
end

local function containsBrokenMesh(instance)
    local objects = instance:IsA("Model") and instance:GetDescendants() or {instance}
    for _, descendant in ipairs(objects) do
        if descendant:IsA("MeshPart") or descendant:IsA("SpecialMesh") then
            local meshId = descendant.MeshId
            for assetId in pairs(BROKEN_MESH_IDS) do
                if meshId ~= "" and string.find(meshId, assetId, 1, true) then
                    return true, assetId
                end
            end
        end
    end
    return false, nil
end

local function restoreCreature(model)
    if not model or not model:IsA("Model") then
        return
    end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if descendant.Name == "Body" or descendant.Name == "Head" or descendant.Name == "Leg" or descendant.Name == "Tail" then
                descendant.Transparency = 0
            elseif descendant.Name == "HumanoidRootPart" then
                descendant.Transparency = 1
            end
        end
    end
    model:SetAttribute("UsingGeneratedFallback", true)
end

local function restoreTreeHouse()
    local root = workspace:FindFirstChild("ISLE_ZERO_WORLD")
    local treeHouse = root and root:FindFirstChild("JungleTreeHouse", true)
    if not treeHouse or not treeHouse:IsA("Model") then
        return
    end

    for _, descendant in ipairs(treeHouse:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local marker = descendant.Name == "TreeHouseClimbPoint"
                or descendant.Name == "TreeHouseDescendPoint"
                or descendant.Name == "TreeHouseRestPoint"
                or descendant.Name == "TreeHouseSafeZone"
            descendant.Transparency = marker and 1 or 0
        end
    end
    treeHouse:SetAttribute("UsingGeneratedFallback", true)
end

local function restoreChest(model)
    if not model or not model:IsA("Model") then
        return
    end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and (descendant.Name == "ChestBody" or descendant.Name == "ChestLid" or descendant.Name == "MetalBand") then
            descendant.Transparency = 0
        end
    end
    model:SetAttribute("UsingGeneratedFallback", true)
end

local function nearestSiblingModel(authored, predicate)
    local parent = authored.Parent
    if not parent then
        return nil
    end

    local position = authored:GetPivot().Position
    local nearest = nil
    local best = math.huge
    for _, sibling in ipairs(parent:GetChildren()) do
        if sibling:IsA("Model") and predicate(sibling) then
            local distance = (sibling:GetPivot().Position - position).Magnitude
            if distance < best then
                best = distance
                nearest = sibling
            end
        end
    end
    return nearest
end

local function restoreForAuthored(authored)
    if startsWith(authored.Name, "AUTHORED_TreeHouse_") then
        restoreTreeHouse()
        return
    end

    if startsWith(authored.Name, "AUTHORED_BlackJaguar") or startsWith(authored.Name, "AUTHORED_JungleStalker") then
        restoreCreature(authored.Parent)
        return
    end

    if startsWith(authored.Name, "AUTHORED_CaveChest_") then
        restoreChest(nearestSiblingModel(authored, function(model)
            return startsWith(model.Name, "Chest_")
        end))
        return
    end

    if startsWith(authored.Name, "AUTHORED_WorldChest_") then
        restoreChest(nearestSiblingModel(authored, function(model)
            return startsWith(model.Name, "WorldChest_")
        end))
        return
    end

    if isNatureVisual(authored) then
        local nature = nearestSiblingModel(authored, function(model)
            return model.Name == "JungleTree" or model.Name == "EmergentTree" or model.Name == "Palm" or model.Name == "Mangrove"
        end)
        if nature then
            for _, descendant in ipairs(nature:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Transparency = 0
                end
            end
        end
    end
end

local function terrainGround(position)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {workspace.Terrain}
    params.IgnoreWater = true

    local result = workspace:Raycast(
        Vector3.new(position.X, 700, position.Z),
        Vector3.new(0, -1400, 0),
        params
    )
    return result and result.Position or nil
end

local function groundNature(instance)
    if not instance.Parent or not isNatureVisual(instance) then
        return
    end

    local ground = terrainGround(instance:GetPivot().Position)
    if not ground then
        return
    end

    if instance:IsA("Model") then
        local ok, boxCFrame, boxSize = pcall(function()
            local cf, size = instance:GetBoundingBox()
            return cf, size
        end)
        if ok then
            local bottom = boxCFrame.Position.Y - boxSize.Y / 2
            instance:PivotTo(instance:GetPivot() + Vector3.new(0, ground.Y - bottom, 0))
        end
    elseif instance:IsA("BasePart") then
        local bottom = instance.Position.Y - instance.Size.Y / 2
        instance.CFrame += Vector3.new(0, ground.Y - bottom, 0)
    end

    instance:SetAttribute("TerrainGrounded", true)
end

local function processAuthored(instance)
    if not (instance:IsA("Model") or instance:IsA("BasePart")) or not startsWith(instance.Name, "AUTHORED_") then
        return
    end

    if shouldRejectByName(instance) then
        restoreForAuthored(instance)
        warn("[ISLE//ZERO][POLISH] Rejected unreliable authored visual: " .. instance.Name)
        instance:Destroy()
        return
    end

    local broken, assetId = containsBrokenMesh(instance)
    if broken then
        restoreForAuthored(instance)
        warn(string.format("[ISLE//ZERO][POLISH] Rejected failed mesh %s in %s", tostring(assetId), instance.Name))
        instance:Destroy()
        return
    end

    if isNatureVisual(instance) then
        groundNature(instance)
    end
end

local function scan()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if (descendant:IsA("Model") or descendant:IsA("BasePart")) and startsWith(descendant.Name, "AUTHORED_") then
            processAuthored(descendant)
        end
    end
    restoreTreeHouse()
end

workspace.DescendantAdded:Connect(function(instance)
    if (instance:IsA("Model") or instance:IsA("BasePart")) and startsWith(instance.Name, "AUTHORED_") then
        task.delay(0.08, processAuthored, instance)
    end
end)

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.35, scan)
        task.delay(1.8, scan)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(0.35, scan)
end
