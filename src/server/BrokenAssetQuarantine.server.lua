local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BROKEN_MESH_IDS = {
    ["4701218333"] = true,
    ["4694750324"] = true,
}

local assets = ReplicatedStorage:FindFirstChild("ISLEZeroAssets")
if not assets then
    return
end

local function brokenAssetId(instance)
    if not (instance:IsA("MeshPart") or instance:IsA("SpecialMesh")) then
        return nil
    end

    local meshId = instance.MeshId
    for assetId in pairs(BROKEN_MESH_IDS) do
        if meshId ~= "" and string.find(meshId, assetId, 1, true) then
            return assetId
        end
    end
    return nil
end

local function sourceAssetFor(instance)
    local current = instance
    while current.Parent and current.Parent ~= assets do
        current = current.Parent
    end
    return current
end

local quarantined = {}
for _, descendant in ipairs(assets:GetDescendants()) do
    local assetId = brokenAssetId(descendant)
    if assetId then
        local source = sourceAssetFor(descendant)
        if source and not quarantined[source] then
            quarantined[source] = true
            warn(string.format("[ISLE//ZERO][ASSET QUARANTINE] Removed %s because Roblox cannot fetch mesh %s", source.Name, assetId))
            source:Destroy()
        end
    end
end
