local Players = game:GetService("Players")

local SpawnFlow = {}

local HOLD_NAME = "ISLE_ZERO_GENERATION_HOLD"

local function destroyExisting()
    local existing = workspace:FindFirstChild(HOLD_NAME)
    if existing then
        existing:Destroy()
    end
end

function SpawnFlow.Prepare(config)
    destroyExisting()

    local center = config.Locations.CrashBeach
    local holdY = 70

    local model = Instance.new("Model")
    model.Name = HOLD_NAME
    model.Parent = workspace

    local platform = Instance.new("Part")
    platform.Name = "TemporaryPlatform"
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 1
    platform.Size = Vector3.new(54, 2, 54)
    platform.CFrame = CFrame.new(center.X, holdY - 3, center.Z)
    platform.Parent = model

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "TemporarySpawn"
    spawn.Anchored = true
    spawn.CanCollide = false
    spawn.Transparency = 1
    spawn.Size = Vector3.new(18, 1, 18)
    spawn.CFrame = CFrame.new(center.X, holdY, center.Z)
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Parent = model

    return model
end

local function moveCharacter(character, target)
    if not character or not character.Parent then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        return
    end
    character:PivotTo(target)
end

function SpawnFlow.Release(root)
    local landmarks = root:FindFirstChild("Landmarks")
    local finalSpawn = landmarks and landmarks:FindFirstChild("CrashBeachSpawn")
    if not finalSpawn or not finalSpawn:IsA("SpawnLocation") then
        warn("[ISLE//ZERO] Cannot release generation spawn: final CrashBeachSpawn is missing")
        return false
    end

    local target = finalSpawn.CFrame * CFrame.new(0, 5, 0)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            moveCharacter(player.Character, target)
        end
    end

    destroyExisting()
    return true
end

return SpawnFlow
