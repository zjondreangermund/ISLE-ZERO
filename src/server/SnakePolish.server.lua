local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local polished = setmetatable({}, {__mode = "k"})
local activeConnections = setmetatable({}, {__mode = "k"})

local SEGMENT_COUNT = 9
local BODY_LENGTH = 4.4
local BODY_WIDTH = 0.58
local ROOT_SIZE = Vector3.new(0.72, 0.34, 1.15)

local function isSnake(model)
    return model:IsA("Model")
        and model:GetAttribute("GuardianType") == "JungleSnake"
        and model:GetAttribute("WorldEnemy") == true
end

local function suppressCoiledAuthoredVisual(model)
    for _, child in ipairs(model:GetChildren()) do
        if string.sub(child.Name, 1, 20) == "AUTHORED_JungleSnake" then
            child:Destroy()
        end
    end
end

local function removeOldSnakeVisual(model, root)
    for _, child in ipairs(model:GetChildren()) do
        if child ~= root and (child.Name == "Body" or child.Name == "Head" or string.sub(child.Name, 1, 12) == "SnakeSegment") then
            child:Destroy()
        end
    end
end

local function createSegment(model, root, index)
    local taper = 1 - ((index - 1) / SEGMENT_COUNT) * 0.46
    local segment = Instance.new("Part")
    segment.Name = string.format("SnakeSegment%02d", index)
    segment.Shape = Enum.PartType.Ball
    segment.Size = Vector3.new(BODY_WIDTH * taper, BODY_WIDTH * 0.72 * taper, BODY_WIDTH * 1.35 * taper)
    segment.Material = Enum.Material.SmoothPlastic
    segment.Color = index <= 2 and Color3.fromRGB(92, 123, 55) or Color3.fromRGB(53, 83, 43)
    segment.Anchored = false
    segment.CanCollide = false
    segment.CanTouch = false
    segment.CanQuery = false
    segment.Massless = true
    segment.CastShadow = true
    segment.CFrame = root.CFrame
    segment.Parent = model

    local motor = Instance.new("Motor6D")
    motor.Name = "SnakeMotor" .. index
    motor.Part0 = root
    motor.Part1 = segment
    motor.C1 = CFrame.identity
    motor.Parent = root

    return segment, motor
end

local function createHead(model, root)
    local head = Instance.new("Part")
    head.Name = "SnakeHead"
    head.Size = Vector3.new(0.82, 0.42, 1.05)
    head.Material = Enum.Material.SmoothPlastic
    head.Color = Color3.fromRGB(102, 133, 59)
    head.Anchored = false
    head.CanCollide = false
    head.CanTouch = false
    head.CanQuery = false
    head.Massless = true
    head.CFrame = root.CFrame
    head.Parent = model

    local motor = Instance.new("Motor6D")
    motor.Name = "SnakeHeadMotor"
    motor.Part0 = root
    motor.Part1 = head
    motor.C1 = CFrame.identity
    motor.Parent = root

    local eyeOffsets = {-1, 1}
    for _, side in ipairs(eyeOffsets) do
        local eye = Instance.new("Part")
        eye.Name = "Eye"
        eye.Shape = Enum.PartType.Ball
        eye.Size = Vector3.new(0.09, 0.09, 0.09)
        eye.Color = Color3.fromRGB(225, 198, 60)
        eye.Material = Enum.Material.Neon
        eye.Anchored = false
        eye.CanCollide = false
        eye.CanTouch = false
        eye.CanQuery = false
        eye.Massless = true
        eye.CFrame = head.CFrame
        eye.Parent = model

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = head
        weld.Part1 = eye
        weld.Parent = head

        eye.CFrame = head.CFrame * CFrame.new(0.25 * side, 0.12, -0.46)
    end

    return head, motor
end

local function stateMotion(state)
    if state == "Run" then
        return 0.34, 9.4, 0.12
    elseif state == "Walk" then
        return 0.26, 6.8, 0.08
    elseif state == "Attack" then
        return 0.42, 11.5, 0.28
    elseif state == "Death" then
        return 0.08, 1.2, -0.12
    end
    return 0.10, 2.2, 0.05
end

local function polishSnake(model)
    if polished[model] or not isSnake(model) or not model:IsDescendantOf(workspace) then
        return
    end

    local root = model:FindFirstChild("HumanoidRootPart")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart") or not humanoid then
        return
    end

    polished[model] = true
    suppressCoiledAuthoredVisual(model)
    removeOldSnakeVisual(model, root)

    root.Size = ROOT_SIZE
    root.CanCollide = true
    root.CanTouch = false
    root.Transparency = 1
    humanoid.HipHeight = 0.04
    humanoid.WalkSpeed = math.min(humanoid.WalkSpeed, 9.5)

    local billboard = root:FindFirstChild("WildlifeHealth")
    if billboard and billboard:IsA("BillboardGui") then
        billboard.StudsOffset = Vector3.new(0, 1.35, 0)
        billboard.Size = UDim2.fromOffset(122, 27)
        billboard.MaxDistance = 42
    end

    local motors = {}
    local head, headMotor = createHead(model, root)
    table.insert(motors, headMotor)

    for index = 1, SEGMENT_COUNT do
        local _, motor = createSegment(model, root, index)
        table.insert(motors, motor)
    end

    model:SetAttribute("SnakeVisualMode", "ProceduralSlither")
    model:SetAttribute("SnakeAuthoredVisualSuppressed", true)

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not model.Parent or humanoid.Health <= 0 and model:GetAttribute("AnimationState") ~= "Death" then
            if connection then
                connection:Disconnect()
            end
            activeConnections[model] = nil
            return
        end

        suppressCoiledAuthoredVisual(model)

        local state = model:GetAttribute("AnimationState") or "Idle"
        local amplitude, speed, headLift = stateMotion(state)
        local now = os.clock() * speed

        headMotor.C0 = CFrame.new(
            math.sin(now) * amplitude * 0.35,
            0.12 + headLift,
            -BODY_LENGTH / 2 - 0.48
        ) * CFrame.Angles(0, math.sin(now) * 0.18, state == "Attack" and math.rad(-10) or 0)
        head.CFrame = root.CFrame * headMotor.C0

        for index = 1, SEGMENT_COUNT do
            local t = (index - 1) / math.max(1, SEGMENT_COUNT - 1)
            local z = -BODY_LENGTH / 2 + t * BODY_LENGTH
            local wave = math.sin(now - index * 0.72) * amplitude * (0.55 + t * 0.65)
            local yaw = math.cos(now - index * 0.72) * amplitude * 0.34
            local vertical = math.sin(now * 0.5 - index * 0.3) * 0.025
            local motor = motors[index + 1]
            motor.C0 = CFrame.new(wave, 0.06 + vertical, z) * CFrame.Angles(0, yaw, 0)
        end
    end)
    activeConnections[model] = connection

    model.DescendantAdded:Connect(function(descendant)
        if string.sub(descendant.Name, 1, 20) == "AUTHORED_JungleSnake" then
            task.defer(suppressCoiledAuthoredVisual, model)
        end
    end)

    print("[ISLE//ZERO][SNAKE POLISH] Compact slithering jungle snake activated")
end

local function scan()
    for _, enemy in ipairs(CollectionService:GetTagged("WorldEnemy")) do
        if isSnake(enemy) then
            polishSnake(enemy)
        end
    end
end

CollectionService:GetInstanceAddedSignal("WorldEnemy"):Connect(function(enemy)
    if enemy:IsA("Model") then
        task.delay(0.35, polishSnake, enemy)
    end
end)

workspace:GetAttributeChangedSignal("ISLEZeroGenerated"):Connect(function()
    if workspace:GetAttribute("ISLEZeroGenerated") == true then
        task.delay(0.6, scan)
    end
end)

if workspace:GetAttribute("ISLEZeroGenerated") == true then
    task.delay(0.6, scan)
end
