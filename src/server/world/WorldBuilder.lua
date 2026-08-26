local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local config = require(shared:WaitForChild("WorldConfig"))
local gameplayConfig = require(shared:WaitForChild("GameplayConfig"))
local AtmosphereBuilder = require(script.Parent.AtmosphereBuilder)
local TerrainBuilder = require(script.Parent.TerrainBuilder)
local CaveBuilder = require(script.Parent.CaveBuilder)
local CoastBuilder = require(script.Parent.CoastBuilder)
local NaturalFeatureBuilder = require(script.Parent.NaturalFeatureBuilder)
local PathBuilder = require(script.Parent.PathBuilder)
local LandmarkBuilder = require(script.Parent.LandmarkBuilder)
local RegionBuilder = require(script.Parent.RegionBuilder)
local ExplorationSiteBuilder = require(script.Parent.ExplorationSiteBuilder)
local SignpostBuilder = require(script.Parent.SignpostBuilder)
local VegetationBuilder = require(script.Parent.VegetationBuilder)
local ExplorationClearing = require(script.Parent.ExplorationClearing)
local ExplorationAudit = require(script.Parent.ExplorationAudit)
local WorldAudit = require(script.Parent.WorldAudit)
local WorldPreflight = require(script.Parent.WorldPreflight)
local SpawnFlow = require(script.Parent.SpawnFlow)

local WorldBuilder = {}

local WORLD_NAME = "ISLE_ZERO_WORLD"
local buildInProgress = false

local function removeTemplateObjects()
    for _, name in ipairs({"Baseplate", "SpawnLocation"}) do
        local object = workspace:FindFirstChild(name)
        if object and object:GetAttribute("PreserveForISLEZero") ~= true then
            if object:IsA("BasePart") or object:IsA("SpawnLocation") then
                object:Destroy()
            end
        end
    end
end

local function createRoot()
    local old = workspace:FindFirstChild(WORLD_NAME)
    if old then
        old:Destroy()
    end

    local root = Instance.new("Model")
    root.Name = WORLD_NAME
    root.Parent = workspace
    root:SetAttribute("WorldVersion", config.WorldVersion)
    root:SetAttribute("WorldSeed", config.Seed)
    root:SetAttribute("GeneratedAtRuntime", true)
    root:SetAttribute("BuildComplete", false)
    root:SetAttribute("BuildState", "Starting")
    root:SetAttribute("CurrentPhase", "Starting")
    return root
end

local function runPhase(root, phaseName, callback)
    root:SetAttribute("CurrentPhase", phaseName)
    root:SetAttribute("BuildState", "Building")
    workspace:SetAttribute("ISLEZeroCurrentPhase", phaseName)

    local started = os.clock()
    local ok, result = pcall(callback)
    local seconds = math.floor((os.clock() - started) * 1000) / 1000

    root:SetAttribute("Phase_" .. phaseName .. "_Seconds", seconds)

    if not ok then
        error(string.format("World phase '%s' failed: %s", phaseName, tostring(result)), 0)
    end

    print(string.format("[ISLE//ZERO][WORLD] %s complete in %.3fs", phaseName, seconds))
    return result
end

local function markBuildFailed(root, message)
    if root and root.Parent then
        root:SetAttribute("BuildComplete", false)
        root:SetAttribute("BuildState", "Failed")
        root:SetAttribute("BuildError", string.sub(tostring(message), 1, 900))
    end
    workspace:SetAttribute("ISLEZeroGenerated", false)
    workspace:SetAttribute("ISLEZeroBuildState", "Failed")
end

function WorldBuilder.Build()
    WorldPreflight.Assert(config)

    if buildInProgress then
        error("A world build is already in progress", 0)
    end
    buildInProgress = true

    local started = os.clock()
    local root = nil

    workspace:SetAttribute("ISLEZeroCurrentPhase", "Starting")

    local ok, result = pcall(function()
        removeTemplateObjects()
        SpawnFlow.Prepare(config)
        root = createRoot()

        workspace:SetAttribute("ISLEZeroGenerated", false)
        workspace:SetAttribute("ISLEZeroBuildState", "Building")

        runPhase(root, "Atmosphere", function()
            AtmosphereBuilder.Build(config)
        end)

        local terrainState = runPhase(root, "Terrain", function()
            return TerrainBuilder.Build(config)
        end)
        root:SetAttribute("TerrainSampledCells", terrainState.SampledCells or 0)
        root:SetAttribute("TerrainFilledColumns", terrainState.FilledColumns or 0)

        runPhase(root, "Caves", function()
            CaveBuilder.Build(config, root, TerrainBuilder.HeightAt)
        end)

        runPhase(root, "Coast", function()
            CoastBuilder.Build(config, root, TerrainBuilder.HeightAt)
        end)

        runPhase(root, "NaturalFeatures", function()
            NaturalFeatureBuilder.Build(config, root, TerrainBuilder.HeightAt)
        end)

        runPhase(root, "Paths", function()
            PathBuilder.Build(config, root, TerrainBuilder.HeightAt)
        end)

        runPhase(root, "Landmarks", function()
            LandmarkBuilder.Build(config, root, terrainState, TerrainBuilder.HeightAt)
        end)

        runPhase(root, "Regions", function()
            RegionBuilder.Build(config, root, TerrainBuilder.HeightAt, gameplayConfig)
        end)

        runPhase(root, "Vegetation", function()
            VegetationBuilder.Build(
                config,
                root,
                TerrainBuilder.HeightAt,
                PathBuilder.DistanceToAnyPath
            )
        end)

        runPhase(root, "ExplorationClearings", function()
            ExplorationClearing.Apply(config, root)
        end)

        runPhase(root, "ExplorationSites", function()
            ExplorationSiteBuilder.Build(config, root, TerrainBuilder.HeightAt)
        end)

        runPhase(root, "TrailSigns", function()
            SignpostBuilder.Build(config, root, TerrainBuilder.HeightAt)
        end)

        local explorationAudit = runPhase(root, "ExplorationAudit", function()
            return ExplorationAudit.Run(config, root, TerrainBuilder.HeightAt)
        end)
        if #explorationAudit.errors > 0 then
            error(string.format("Exploration audit found %d blocking error(s)", #explorationAudit.errors), 0)
        end

        local audit = runPhase(root, "Audit", function()
            return WorldAudit.Run(config, root, TerrainBuilder.HeightAt)
        end)

        if #audit.errors > 0 then
            error(string.format("World audit found %d blocking error(s)", #audit.errors), 0)
        end

        local spawnReleased = runPhase(root, "SpawnRelease", function()
            return SpawnFlow.Release(root)
        end)
        root:SetAttribute("SpawnReleased", spawnReleased)

        if not spawnReleased then
            error("CrashBeachSpawn could not be activated", 0)
        end

        root:SetAttribute("BuildComplete", true)
        root:SetAttribute("BuildState", "Ready")
        root:SetAttribute("CurrentPhase", "Ready")
        root:SetAttribute("BuildError", nil)

        workspace:SetAttribute("ISLEZeroWorldVersion", config.WorldVersion)
        workspace:SetAttribute("ISLEZeroWorldSeed", config.Seed)
        workspace:SetAttribute("ISLEZeroGenerated", true)
        workspace:SetAttribute("ISLEZeroBuildState", "Ready")
        workspace:SetAttribute("ISLEZeroCurrentPhase", "Ready")
        workspace:SetAttribute("ISLEZeroGenerationSeconds", math.floor((os.clock() - started) * 100) / 100)
        workspace:SetAttribute("ISLEZeroAuditErrors", #audit.errors + #explorationAudit.errors)
        workspace:SetAttribute("ISLEZeroAuditWarnings", #audit.warnings + #explorationAudit.warnings)

        return root
    end)

    buildInProgress = false

    if not ok then
        markBuildFailed(root, result)
        warn("[ISLE//ZERO][WORLD] Build stopped. Temporary generation spawn is being kept for player safety.")
        error(result, 0)
    end

    return result
end

function WorldBuilder.IsBuilding()
    return buildInProgress
end

function WorldBuilder.NeedsBuild()
    local root = workspace:FindFirstChild(WORLD_NAME)
    if not root then
        return true
    end
    if root:GetAttribute("WorldVersion") ~= config.WorldVersion then
        return true
    end
    if root:GetAttribute("BuildComplete") ~= true then
        return true
    end
    return root:GetAttribute("BuildState") ~= "Ready"
end

return WorldBuilder
