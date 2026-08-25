local WorldBuilder = require(script.Parent.world.WorldBuilder)

local ok, result = pcall(function()
    if WorldBuilder.NeedsBuild() then
        return WorldBuilder.Build()
    end
    return workspace:FindFirstChild("ISLE_ZERO_WORLD")
end)

if not ok then
    warn("[ISLE//ZERO] World generation failed:", result)
else
    print("[ISLE//ZERO] World ready:", result and result:GetFullName() or "unknown")
end
