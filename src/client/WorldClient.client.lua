local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

if camera then
    camera.FieldOfView = 76
end

local phaseInfo = {
    Starting = {0.04, "Preparing island"},
    Atmosphere = {0.09, "Setting sky and atmosphere"},
    Terrain = {0.42, "Raising the island"},
    Coast = {0.56, "Shaping coast and islets"},
    NaturalFeatures = {0.66, "Placing natural landmarks"},
    Paths = {0.74, "Cutting exploration trails"},
    Landmarks = {0.82, "Building island landmarks"},
    Vegetation = {0.90, "Growing jungle and mangroves"},
    Audit = {0.96, "Checking the world"},
    SpawnRelease = {0.99, "Opening Crash Beach"},
    Ready = {1.0, "Island ready"},
}

local gui = Instance.new("ScreenGui")
gui.Name = "ISLEZeroWorldLoading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.BackgroundColor3 = Color3.fromRGB(8, 12, 13)
backdrop.BorderSizePixel = 0
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.44)
title.Size = UDim2.fromOffset(520, 70)
title.Font = Enum.Font.GothamBold
title.Text = "ISLE//ZERO"
title.TextColor3 = Color3.fromRGB(235, 241, 239)
title.TextScaled = true
title.Parent = backdrop

local status = Instance.new("TextLabel")
status.Name = "Status"
status.BackgroundTransparency = 1
status.AnchorPoint = Vector2.new(0.5, 0.5)
status.Position = UDim2.fromScale(0.5, 0.515)
status.Size = UDim2.fromOffset(440, 30)
status.Font = Enum.Font.Gotham
status.Text = "Preparing island"
status.TextColor3 = Color3.fromRGB(156, 171, 168)
status.TextSize = 18
status.Parent = backdrop

local barBack = Instance.new("Frame")
barBack.Name = "ProgressBack"
barBack.AnchorPoint = Vector2.new(0.5, 0.5)
barBack.Position = UDim2.fromScale(0.5, 0.56)
barBack.Size = UDim2.fromOffset(360, 4)
barBack.BackgroundColor3 = Color3.fromRGB(38, 47, 47)
barBack.BorderSizePixel = 0
barBack.Parent = backdrop

local bar = Instance.new("Frame")
bar.Name = "Progress"
bar.Size = UDim2.fromScale(0.02, 1)
bar.BackgroundColor3 = Color3.fromRGB(191, 211, 201)
bar.BorderSizePixel = 0
bar.Parent = barBack

local function setPhase(phase)
    local info = phaseInfo[phase] or {0.03, phase or "Preparing island"}
    status.Text = info[2]
    TweenService:Create(
        bar,
        TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromScale(info[1], 1)}
    ):Play()
end

setPhase(workspace:GetAttribute("ISLEZeroCurrentPhase") or "Starting")

local phaseConnection = workspace:GetAttributeChangedSignal("ISLEZeroCurrentPhase"):Connect(function()
    setPhase(workspace:GetAttribute("ISLEZeroCurrentPhase") or "Starting")
end)

-- Do not wait for just one attribute change: the first change can be nil -> false
-- when the server starts generating. Stay here until generation is truly ready.
while workspace:GetAttribute("ISLEZeroGenerated") ~= true do
    if workspace:GetAttribute("ISLEZeroBuildState") == "Failed" then
        status.Text = "World generation failed - check Studio Output"
        status.TextColor3 = Color3.fromRGB(228, 145, 133)
        warn("[ISLE//ZERO] Client detected a failed world build")
        return
    end
    task.wait(0.1)
end

setPhase("Ready")
task.wait(0.15)

phaseConnection:Disconnect()

local fade = TweenService:Create(
    backdrop,
    TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {BackgroundTransparency = 1}
)
fade:Play()

for _, object in ipairs(backdrop:GetDescendants()) do
    if object:IsA("TextLabel") then
        TweenService:Create(object, TweenInfo.new(0.35), {TextTransparency = 1}):Play()
    elseif object:IsA("Frame") then
        TweenService:Create(object, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
    end
end

fade.Completed:Wait()
gui:Destroy()

print(string.format("[ISLE//ZERO] %s entered world version %s", player.Name, tostring(workspace:GetAttribute("ISLEZeroWorldVersion"))))
