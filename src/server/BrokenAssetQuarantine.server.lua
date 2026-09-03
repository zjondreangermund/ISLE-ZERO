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

-- Return the individual authored asset that owns this mesh, never the category
-- folder itself (Creatures / Nature / Props / Structures).
local function sourceAssetFor(instance)
    local current = instance

    if current.Parent == assets then
        return current
    end

    while current.Parent and current.Parent ~= assets do
        local parent = current.Parent
        if parent.Parent == assets then
            -- parent is a category folder, so current is the actual authored asset.
            return current
        end
        current = parent
    end

    return current ~= assets and current or nil
end

local removals = {}
for _, descendant in ipairs(assets:GetDescendants()) do
    local assetId = brokenAssetId(descendant)
    if assetId then
        table.insert(removals, {
            Instance = descendant,
            AssetId = assetId,
            Source = sourceAssetFor(descendant),
        })
    end
end

local counts = {}
for _, entry in ipairs(removals) do
    local descendant = entry.Instance
    local source = entry.Source

    if source then
        counts[source] = (counts[source] or 0) + 1
    end

    if descendant.Parent then
        -- Remove only the broken mesh object. Never destroy the entire source model
        -- and never destroy a category folder because one asset contains a bad mesh.
        descendant:Destroy()
    end
end

for source, count in pairs(counts) do
    if source.Parent then
        source:SetAttribute("ISLEZeroQuarantinedMeshCount", count)
        warn(string.format(
            "[ISLE//ZERO][ASSET QUARANTINE] Removed %d broken mesh object(s) from %s; source asset preserved",
            count,
            source.Name
        ))
    end
end
