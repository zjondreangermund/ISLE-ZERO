local CollectionService = game:GetService("CollectionService")

local bound = setmetatable({}, {__mode = "k"})

local STATE_NAMES = {"Idle", "Walk", "Run", "Attack", "Death"}

local function normalize(value)
    return string.lower((string.gsub(tostring(value), "[%s_%-]", "")))
end

local function authoredVisual(model)
    for _, child in ipairs(model:GetChildren()) do
        if string.sub(child.Name, 1, 9) == "AUTHORED_" and (child:IsA("Model") or child:IsA("BasePart")) then
            return child
        end
    end
    return nil
end

local function animationFor(visual, state)
    local attribute = visual:GetAttribute(state .. "AnimationId")
    if typeof(attribute) == "string" and attribute ~= "" then
        local animation = Instance.new("Animation")
        animation.Name = "ISLEZero" .. state
        animation.AnimationId = string.find(attribute, "rbxassetid://", 1, true) and attribute or ("rbxassetid://" .. attribute)
        animation.Parent = visual
        return animation
    elseif typeof(attribute) == "number" and attribute > 0 then
        local animation = Instance.new("Animation")
        animation.Name = "ISLEZero" .. state
        animation.AnimationId = "rbxassetid://" .. tostring(math.floor(attribute))
        animation.Parent = visual
        return animation
    end

    local wanted = normalize(state)
    for _, descendant in ipairs(visual:GetDescendants()) do
        if descendant:IsA("Animation") then
            local name = normalize(descendant.Name)
            if name == wanted or string.find(name, wanted, 1, true) then
                return descendant
            end
        end
    end
    return nil
end

local function ensureAnimator(visual)
    local controller = visual:FindFirstChildWhichIsA("AnimationController", true)
    if not controller then
        controller = Instance.new("AnimationController")
        controller.Name = "ISLEZeroAnimationController"
        controller.Parent = visual
    end
    local animator = controller:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = controller
    end
    return animator
end

local function loadTracks(visual, animator)
    local tracks = {}
    for _, state in ipairs(STATE_NAMES) do
        local animation = animationFor(visual, state)
        if animation then
            local ok, track = pcall(function()
                return animator:LoadAnimation(animation)
            end)
            if ok and track then
                track.Looped = state == "Idle" or state == "Walk" or state == "Run"
                tracks[state] = track
            end
        end
    end
    return tracks
end

local function bind(model)
    if bound[model] or not model:IsA("Model") then
        return
    end
    if not model:GetAttribute("VisualAssetApplied") then
        task.delay(0.35, bind, model)
        return
    end

    local visual = authoredVisual(model)
    if not visual or model:GetAttribute("VisualRigged") ~= true then
        return
    end

    local animator = ensureAnimator(visual)
    local tracks = loadTracks(visual, animator)
    if next(tracks) == nil then
        return
    end

    bound[model] = true
    model:SetAttribute("AnimationControllerActive", true)
    local current = nil

    local function play(state, force)
        local track = tracks[state]
        if not track then
            return
        end
        if current == state and not force then
            return
        end
        for name, other in pairs(tracks) do
            if name ~= state and other.IsPlaying then
                other:Stop(0.18)
            end
        end
        if force and track.IsPlaying then
            track:Stop(0.05)
        end
        track:Play(0.15)
        current = state
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Running:Connect(function(speed)
            if model:GetAttribute("AnimationState") == "Attack" then
                return
            end
            if speed > 11 and tracks.Run then
                play("Run")
            elseif speed > 0.8 and tracks.Walk then
                play("Walk")
            elseif tracks.Idle then
                play("Idle")
            end
        end)
        humanoid.Died:Connect(function()
            play("Death", true)
        end)
    end

    model:GetAttributeChangedSignal("AnimationState"):Connect(function()
        local state = model:GetAttribute("AnimationState")
        if state == "Attack" then
            play("Attack", true)
            task.delay(0.75, function()
                if model.Parent and humanoid and humanoid.Health > 0 then
                    if humanoid.MoveDirection.Magnitude > 0.05 then
                        play(tracks.Run and "Run" or "Walk")
                    else
                        play("Idle")
                    end
                end
            end)
        elseif state == "Death" then
            play("Death", true)
        elseif state == "Run" or state == "Walk" or state == "Idle" then
            play(state)
        end
    end)

    model:GetAttributeChangedSignal("AnimationPulse"):Connect(function()
        if model:GetAttribute("AnimationState") == "Attack" then
            play("Attack", true)
        end
    end)

    if tracks.Idle then
        play("Idle")
    end
end

CollectionService:GetInstanceAddedSignal("CaveGuardian"):Connect(function(model)
    task.delay(0.45, bind, model)
end)

for _, model in ipairs(CollectionService:GetTagged("CaveGuardian")) do
    task.delay(0.45, bind, model)
end
