local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local GameplayConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameplayConfig"))
local remotes = ReplicatedStorage:WaitForChild("ISLEZeroSurvival")
local actionRemote = remotes:WaitForChild("Action")
local stateRemote = remotes:WaitForChild("State")
local toastRemote = remotes:WaitForChild("Toast")
local getStateRemote = remotes:WaitForChild("GetState")

local gui = Instance.new("ScreenGui")
gui.Name = "ISLEZeroSurvivalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "InventoryPanel"
panel.Size = UDim2.fromOffset(310, 270)
panel.Position = UDim2.fromOffset(18, 108)
panel.BackgroundColor3 = Color3.fromRGB(18, 23, 20)
panel.BackgroundTransparency = 0.16
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(91, 112, 89)
stroke.Transparency = 0.35
stroke.Thickness = 1
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 10)
title.Size = UDim2.new(1, -28, 0, 26)
title.Font = Enum.Font.GothamBold
title.Text = "ISLE//ZERO  •  EXPEDITION KIT"
title.TextColor3 = Color3.fromRGB(231, 229, 207)
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local inventoryLabel = Instance.new("TextLabel")
inventoryLabel.BackgroundTransparency = 1
inventoryLabel.Position = UDim2.fromOffset(14, 43)
inventoryLabel.Size = UDim2.new(1, -28, 0, 145)
inventoryLabel.Font = Enum.Font.Code
inventoryLabel.TextColor3 = Color3.fromRGB(209, 211, 192)
inventoryLabel.TextSize = 13
inventoryLabel.TextXAlignment = Enum.TextXAlignment.Left
inventoryLabel.TextYAlignment = Enum.TextYAlignment.Top
inventoryLabel.Text = "Loading supplies..."
inventoryLabel.Parent = panel

local statsLabel = Instance.new("TextLabel")
statsLabel.BackgroundTransparency = 1
statsLabel.Position = UDim2.fromOffset(14, 191)
statsLabel.Size = UDim2.new(1, -28, 0, 29)
statsLabel.Font = Enum.Font.GothamBold
statsLabel.TextColor3 = Color3.fromRGB(213, 182, 92)
statsLabel.TextSize = 13
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.Text = "TREASURE 0 • CAVES 0 • WILDLIFE 0"
statsLabel.Parent = panel

local campLabel = Instance.new("TextLabel")
campLabel.BackgroundTransparency = 1
campLabel.Position = UDim2.fromOffset(14, 220)
campLabel.Size = UDim2.new(1, -28, 0, 42)
campLabel.Font = Enum.Font.Gotham
campLabel.TextColor3 = Color3.fromRGB(169, 189, 164)
campLabel.TextSize = 12
campLabel.TextWrapped = true
campLabel.TextXAlignment = Enum.TextXAlignment.Left
campLabel.TextYAlignment = Enum.TextYAlignment.Top
campLabel.Text = "Tent: Wood 6 • Cloth 3 • Rope 2 • Stone 4"
campLabel.Parent = panel

local hint = Instance.new("TextLabel")
hint.Name = "ControlHint"
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -22)
hint.Size = UDim2.fromOffset(650, 42)
hint.BackgroundColor3 = Color3.fromRGB(17, 20, 18)
hint.BackgroundTransparency = 0.22
hint.BorderSizePixel = 0
hint.Font = Enum.Font.GothamBold
hint.TextColor3 = Color3.fromRGB(233, 230, 208)
hint.TextSize = 13
hint.Text = "E / TAP: interact  •  Equip weapon + CLICK/TAP: attack  •  Equip healing item + CLICK/TAP: heal  •  Compass: CLICK/TAP"
hint.Parent = gui
Instance.new("UICorner", hint).CornerRadius = UDim.new(0, 8)

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 85)
toast.Size = UDim2.fromOffset(540, 50)
toast.BackgroundColor3 = Color3.fromRGB(19, 23, 20)
toast.BackgroundTransparency = 1
toast.BorderSizePixel = 0
toast.Font = Enum.Font.GothamBold
toast.TextColor3 = Color3.fromRGB(240, 235, 208)
toast.TextSize = 16
toast.TextTransparency = 1
toast.TextWrapped = true
toast.Parent = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 9)

local latestToast = 0
local latestPacket = nil

local function showToast(message)
    latestToast += 1
    local token = latestToast
    toast.Text = tostring(message)
    TweenService:Create(toast, TweenInfo.new(0.16), {
        BackgroundTransparency = 0.16,
        TextTransparency = 0,
    }):Play()

    task.delay(3.2, function()
        if token ~= latestToast then
            return
        end
        TweenService:Create(toast, TweenInfo.new(0.35), {
            BackgroundTransparency = 1,
            TextTransparency = 1,
        }):Play()
    end)
end

local function amount(inventory, key)
    return inventory[key] or 0
end

local function renderStats()
    local packet = latestPacket or {}
    statsLabel.Text = string.format(
        "TREASURE %d  •  CAVES %d  •  WILDLIFE %d",
        packet.TreasureValue or 0,
        packet.CavesCleared or 0,
        player:GetAttribute("WorldEnemiesDefeated") or 0
    )
end

local function renderState(packet)
    if type(packet) ~= "table" then
        return
    end
    latestPacket = packet
    local inventory = packet.Inventory or {}
    inventoryLabel.Text = string.format(
        "WOOD   %02d   CLOTH  %02d   ROPE %02d\nSTONE  %02d   HERB   %02d   MAP  %02d\nCOINS  %02d   RUBY   %02d   GOLD %02d\nEMRLD  %02d   SAPPH  %02d   PEARL %02d\nSHARD  %02d",
        amount(inventory, "Wood"),
        amount(inventory, "Cloth"),
        amount(inventory, "Rope"),
        amount(inventory, "Stone"),
        amount(inventory, "Herb"),
        amount(inventory, "MapFragment"),
        amount(inventory, "AncientCoin"),
        amount(inventory, "Ruby"),
        amount(inventory, "GoldBar"),
        amount(inventory, "Emerald"),
        amount(inventory, "Sapphire"),
        amount(inventory, "Pearl"),
        amount(inventory, "RelicShard")
    )
    renderStats()
    if packet.SafeCamp then
        campLabel.Text = "SAFE CAMP: " .. tostring(packet.SafeCamp) .. "  •  respawn/checkpoint active"
    else
        campLabel.Text = "CAMP: Wood 6 • Cloth 3 • Rope 2 • Stone 4  •  Cave camps need guardian cleared"
    end
end

local boundTools = setmetatable({}, {__mode = "k"})
local function bindTool(tool)
    if not tool:IsA("Tool") or boundTools[tool] then
        return
    end
    boundTools[tool] = true
    tool.Activated:Connect(function()
        local itemId = tool:GetAttribute("ItemId")
        local definition = itemId and GameplayConfig.Items[itemId]
        if definition and definition.Damage then
            actionRemote:FireServer("Attack", itemId)
        elseif (definition and definition.Heal) or itemId == "AncientCompass" then
            actionRemote:FireServer("Use", itemId)
        end
    end)
end

local function bindContainer(container)
    for _, child in ipairs(container:GetChildren()) do
        bindTool(child)
    end
    container.ChildAdded:Connect(bindTool)
end

local backpack = player:WaitForChild("Backpack")
bindContainer(backpack)
player.CharacterAdded:Connect(function(character)
    bindContainer(character)
end)
if player.Character then
    bindContainer(player.Character)
end

player:GetAttributeChangedSignal("WorldEnemiesDefeated"):Connect(renderStats)
stateRemote.OnClientEvent:Connect(renderState)
toastRemote.OnClientEvent:Connect(showToast)

local ok, packet = pcall(function()
    return getStateRemote:InvokeServer()
end)
if ok then
    renderState(packet)
end
