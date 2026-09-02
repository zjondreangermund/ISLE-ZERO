local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameplayConfig"))
local bound = setmetatable({}, {__mode = "k"})

local function nearestDistance(position)
    local nearest = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if root and humanoid and humanoid.Health > 0 then
            nearest = math.min(nearest, (root.Position - position).Magnitude)
        end
    end
    return nearest
end

local function bind(model)
    if bound[model] or not model:IsA("Model") or model:GetAttribute("WorldEnemy") == true then
        return
    end
    local guardianType = model:GetAttribute("GuardianType")
    local definition = guardianType and GameplayConfig.Guardians[guardianType]
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not definition or not humanoid or not root or not root:IsA("BasePart") then
        return
    end

    bound[model] = true
    model:SetAttribute("AnimationState", "Idle")

    humanoid.Running:Connect(function(speed)
        if humanoid.Health <= 0 then
            return
        end
        if speed > 10 then
            model:SetAttribute("AnimationState", "Run")
        elseif speed > 0.7 then
            model:SetAttribute("AnimationState", "Walk")
        elseif model:GetAttribute("AnimationState") ~= "Attack" then
            model:SetAttribute("AnimationState", "Idle")
        end
    end)

    humanoid.Died:Connect(function()
        model:SetAttribute("AnimationState", "Death")
        model:SetAttribute("AnimationPulse", (model:GetAttribute("AnimationPulse") or 0) + 1)
    end)

    task.spawn(function()
        local lastPulse = 0
        while model.Parent and humanoid.Health > 0 do
            task.wait(0.18)
            local distance = nearestDistance(root.Position)
            if distance <= (definition.AttackRange or 5) and os.clock() - lastPulse > 1.1 then
                lastPulse = os.clock()
                model:SetAttribute("AnimationState", "Attack")
                model:SetAttribute("AnimationPulse", (model:GetAttribute("AnimationPulse") or 0) + 1)
                task.delay(0.7, function()
                    if model.Parent and humanoid.Health > 0 and model:GetAttribute("AnimationState") == "Attack" then
                        model:SetAttribute("AnimationState", humanoid.MoveDirection.Magnitude > 0.05 and "Run" or "Idle")
                    end
                end)
            end
        end
    end)
end

CollectionService:GetInstanceAddedSignal("CaveGuardian"):Connect(function(model)
    task.delay(0.3, bind, model)
end)
for _, model in ipairs(CollectionService:GetTagged("CaveGuardian")) do
    task.delay(0.3, bind, model)
end
