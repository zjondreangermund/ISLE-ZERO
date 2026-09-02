local NATURE_PREFIXES = {
    "AUTHORED_JungleTree_",
    "AUTHORED_EmergentTree_",
    "AUTHORED_Palm_",
    "AUTHORED_Mangrove_",
}

local processed = setmetatable({}, {__mode = "k"})

local function isAuthoredNature(instance)
    if not instance:IsA("Model") then
        return false
    end
    for _, prefix in ipairs(NATURE_PREFIXES) do
        if string.sub(instance.Name, 1, #prefix) == prefix then
            return true
        end
    end
    return false
end

local function polish(model)
    if processed[model] or not isAuthoredNature(model) or not model:IsDescendantOf(workspace) then
        return
    end
    processed[model] = true

    local boxCFrame, boxSize = model:GetBoundingBox()
    local bottomY = boxCFrame.Position.Y - boxSize.Y / 2
    local center = Vector2.new(boxCFrame.Position.X, boxCFrame.Position.Z)
    local removed = 0

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local size = descendant.Size
            local horizontal = math.max(size.X, size.Z)
            local distance = (Vector2.new(descendant.Position.X, descendant.Position.Z) - center).Magnitude
            local nearGround = descendant.Position.Y - size.Y / 2 <= bottomY + 3.2
            local flatAndLong = horizontal >= 6 and size.Y <= horizontal * 0.32
            local obviousOutlier = distance > math.max(24, math.max(boxSize.X, boxSize.Z) * 0.62)

            if (nearGround and flatAndLong and distance > 4.5) or obviousOutlier then
                descendant:Destroy()
                removed += 1
            end
        end
    end

    if removed > 0 then
        print(string.format("[ISLE//ZERO][NATURE POLISH] Removed %d loose/outlier parts from %s", removed, model.Name))
    end
end

workspace.DescendantAdded:Connect(function(instance)
    if isAuthoredNature(instance) then
        task.delay(0.18, polish, instance)
    end
end)

local function scan()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if isAuthoredNature(descendant) then
            polish(descendant)
        end
    end
end

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(1, scan)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(1, scan)
end
