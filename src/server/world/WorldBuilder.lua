local ReplicatedStorage = game:GetService("ReplicatedStorage")

local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))
local AtmosphereBuilder = require(script.Parent.AtmosphereBuilder)
local TerrainBuilder = require(script.Parent.TerrainBuilder)
local CoastBuilder = require(script.Parent.CoastBuilder)
local PathBuilder = require(script.Parent.PathBuilder)
local LandmarkBuilder = require(script.Parent.LandmarkBuilder)
local VegetationBuilder = require(script.Parent.VegetationBuilder)
local WorldAudit = require(script.Parent.WorldAudit)

local WorldBuilder = {}

local WORLD_NAME = "ISLE_ZERO_WORLD"

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
    return root
end

function WorldBuilder.Build()
    local started = os.clock()
    removeTemplateObjects()
    local root = createRoot()

    AtmosphereBuilder.Build(config)
    local terrainState = TerrainBuilder.Build(config)
    CoastBuilder.Build(config, root, TerrainBuilder.HeightAt)

    -- Paths are laid before vegetation so tree placement can reserve walkable
    -- corridors and we do not end up with trunks in the middle of the trail.
    PathBuilder.Build(config, root, TerrainBuilder.HeightAt)
    LandmarkBuilder.Build(config, root, terrainState, TerrainBuilder.HeightAt)
    VegetationBuilder.Build(
        config,
        root,
        TerrainBuilder.HeightAt,
        PathBuilder.DistanceToAnyPath
    )

    local audit = WorldAudit.Run(config, root, TerrainBuilder.HeightAt)

    workspace:SetAttribute("ISLEZeroWorldVersion", config.WorldVersion)
    workspace:SetAttribute("ISLEZeroWorldSeed", config.Seed)
    workspace:SetAttribute("ISLEZeroGenerated", true)
    workspace:SetAttribute("ISLEZeroGenerationSeconds", math.floor((os.clock() - started) * 100) / 100)
    workspace:SetAttribute("ISLEZeroAuditErrors", #audit.errors)
    workspace:SetAttribute("ISLEZeroAuditWarnings", #audit.warnings)

    return root
end

function WorldBuilder.NeedsBuild()
    local root = workspace:FindFirstChild(WORLD_NAME)
    if not root then
        return true
    end
    return root:GetAttribute("WorldVersion") ~= config.WorldVersion
end

return WorldBuilder
