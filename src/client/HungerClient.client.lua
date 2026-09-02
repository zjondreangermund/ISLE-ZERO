local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ISLEZeroSurvival")
local actionRemote = remotes:WaitForChild("Action")

local gui = Instance.new("ScreenGui")
gui.Name = "ISLEZeroHungerHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "HungerPanel"
panel.Position = UDim2.fromOffset(18, 386)
panel.Size = UDim2.fromOffset(310, 44)
panel.BackgroundColor3 = Color3.fromRGB(18, 23, 20)
panel.BackgroundTransparency = 0.16
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 9)

local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Position = UDim2.fromOffset(12, 5)
label.Size = UDim2.new(1, -24, 0, 17)
label.Font = Enum.Font.GothamBold
label.TextSize = 12
label.TextColor3 = Color3.fromRGB(226, 222, 197)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = panel

local barBack = Instance.new("Frame")
barBack.Position = UDim2.fromOffset(12, 27)
barBack.Size = UDim2.new(1, -24, 0, 8)
barBack.BackgroundColor3 = Color3.fromRGB(47, 51, 45)
barBack.BorderSizePixel = 0
barBack.Parent = panel
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(1, 1)
bar.BackgroundColor3 = Color3.fromRGB(184, 157, 79)
bar.BorderSizePixel = 0
bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local function renderHunger()
    local hunger = math.clamp(player:GetAttribute("Hunger") or 100, 0, 100)
    local rawMeat = player:GetAttribute("RawMeat") or 0
    label.Text = string.format("FOOD  %d%%    •    RAW MEAT %d    •    safe camps pause hunger", hunger, rawMeat)
    bar.Size = UDim2.fromScale(hunger / 100, 1)
end

player:GetAttributeChangedSignal("Hunger"):Connect(renderHunger)
player:GetAttributeChangedSignal("RawMeat"):Connect(renderHunger)
renderHunger()

local boundTools = setmetatable({}, {__mode = "k"})
local function bindTool(tool)
    if not tool:IsA("Tool") or boundTools[tool] or tool:GetAttribute("FoodItem") ~= true then
        return
    end
    boundTools[tool] = true
    tool.Activated:Connect(function()
        if tool.Parent ~= player.Character then
            return
        end
        actionRemote:FireServer("EatFood", tool:GetAttribute("ItemId"))
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
player.CharacterAdded:Connect(bindContainer)
if player.Character then
    bindContainer(player.Character)
end
