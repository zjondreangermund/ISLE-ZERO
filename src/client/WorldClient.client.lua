local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

if camera then
    camera.FieldOfView = 76
end

-- World-only phase: keep the client intentionally light. Story UI, inventory,
-- combat HUD and discovery popups will be added after the island art pass.
if not workspace:GetAttribute("ISLEZeroGenerated") then
    workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Wait()
end

print(string.format("[ISLE//ZERO] %s entered world version %s", player.Name, tostring(workspace:GetAttribute("ISLEZeroWorldVersion"))))
