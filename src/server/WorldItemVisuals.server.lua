local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assets = ReplicatedStorage:WaitForChild("ISLEZeroAssets")
local worldItems = assets:WaitForChild("WorldItems")
local applied = setmetatable({}, {__mode = "k"})

local ITEM_ALIASES = {
    RawMeat = {"rawmeat", "rawwildmeat", "meat"},
    CookedWildMeat = {"cookedwildmeat", "cookedmeat"},
    FoodRation = {"foodration", "ration", "expeditionration"},
    Berries = {"berries", "berry", "forestberries"},
    Coconut = {"coconut", "coconuts"},
    MapFragment = {"mapfragment", "map", "mappiece"},
    AncientCoin = {"ancientcoin", "coin", "coins"},
    GoldBar = {"goldbar", "gold"},
    RelicShard = {"relicshard", "relic"},
    Medkit = {"medkit", "firstaid", "firstaidkit"},
    Bandage = {"bandage", "bandages"},
    Machete = {"machete"},
    Torch = {"torch", "cavetorch"},
    Wood = {"wood", "log", "woodbundle"},
    Cloth = {"cloth", "fabric"},
    Rope = {"rope", "ropebundle"},
    Stone = {"stone", "rockpickup"},
    Herb = {"herb", "healingherb"},
}

local function normalizeName(value)
    return string.lower((string.gsub(tostring(value), "[%s_%-]", "")))
end

local function matches(name, key)
    local normalized = normalizeName(name)
    if normalized == normalizeName(key) then
        return true
    end
    for _, alias in ipairs(ITEM_ALIASES[key] or {}) do
        if normalized == alias or string.sub(normalized, 1, #alias) == alias then
            return true
        end
    end
    return false
end

local function visualCandidates(itemId)
    local result = {}
    local seen = {}
    for _, descendant in ipairs(worldItems:GetDescendants()) do
        if (descendant:IsA("Model") or descendant:IsA("BasePart")) and not seen[descendant] and matches(descendant.Name, itemId) then
            seen[descendant] = true
            table.insert(result, descendant)
        end
    end
    table.sort(result, function(a, b)
        return a.Name < b.Name
    end)
    return result
end

local function deterministicPick(object, candidates)
    if #candidates == 0 then
        return nil
    end
    if #candidates == 1 then
        return candidates[1]
    end
    local p = object.Position
    local value = math.floor(math.abs(p.X * 11.3 + p.Y * 3.7 + p.Z * 19.1))
    return candidates[(value % #candidates) + 1]
end

local function stripExecutableContent(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") or descendant:IsA("Humanoid") then
            descendant:Destroy()
        end
    end
end

local function prepareVisual(instance)
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

local function placeVisual(visual, object)
    local yaw = math.rad(visual:GetAttribute("ISLEZeroYaw") or 0)
    local pitch = math.rad(visual:GetAttribute("ISLEZeroPitch") or 0)
    local roll = math.rad(visual:GetAttribute("ISLEZeroRoll") or 0)
    local offsetY = visual:GetAttribute("ISLEZeroYOffset") or 0
    local target = object.CFrame * CFrame.Angles(pitch, yaw, roll)
    local desiredBottom = object.Position.Y - object.Size.Y / 2 + offsetY

    if visual:IsA("Model") then
        local scale = visual:GetAttribute("ISLEZeroScale")
        if typeof(scale) == "number" and scale > 0 then
            pcall(function()
                visual:ScaleTo(scale)
            end)
        end
        visual:PivotTo(target)
        local boxCFrame, boxSize = visual:GetBoundingBox()
        local bottom = boxCFrame.Position.Y - boxSize.Y / 2
        visual:PivotTo(visual:GetPivot() + Vector3.new(0, desiredBottom - bottom, 0))
    elseif visual:IsA("BasePart") then
        visual.CFrame = target + Vector3.new(0, desiredBottom + visual.Size.Y / 2 - target.Position.Y, 0)
    end
end

local function itemIdFor(object)
    return object:GetAttribute("ItemId") or object:GetAttribute("FoodId")
end

local function apply(object)
    if applied[object] or not object:IsA("BasePart") or not object:IsDescendantOf(workspace) then
        return
    end

    local itemId = itemIdFor(object)
    if not itemId then
        return
    end

    local candidates = visualCandidates(tostring(itemId))
    local source = deterministicPick(object, candidates)
    if not source then
        return
    end

    local visual = source:Clone()
    visual.Name = "AUTHORED_PICKUP_" .. tostring(itemId)
    stripExecutableContent(visual)
    visual.Parent = object.Parent
    placeVisual(visual, object)
    prepareVisual(visual)

    object.Transparency = 1
    for _, child in ipairs(object:GetChildren()) do
        if child:IsA("Decal") or child:IsA("Texture") then
            child.Transparency = 1
        end
    end

    applied[object] = true
    object:SetAttribute("VisualAssetApplied", true)
    object:SetAttribute("VisualAssetSource", source.Name)

    object.Destroying:Connect(function()
        if visual.Parent then
            visual:Destroy()
        end
    end)
end

local function scan()
    for _, tag in ipairs({"WorldPickup", "FoodPickup"}) do
        for _, object in ipairs(CollectionService:GetTagged(tag)) do
            if object:IsA("BasePart") then
                apply(object)
            end
        end
    end
end

for _, tag in ipairs({"WorldPickup", "FoodPickup"}) do
    CollectionService:GetInstanceAddedSignal(tag):Connect(function(object)
        task.delay(0.1, apply, object)
    end)
end

worldItems.DescendantAdded:Connect(function()
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
