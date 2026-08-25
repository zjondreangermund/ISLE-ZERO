local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not RunService:IsStudio() then
    return
end

local WorldBuilder = require(script.Parent.world.WorldBuilder)
local WorldAudit = require(script.Parent.world.WorldAudit)
local TerrainBuilder = require(script.Parent.world.TerrainBuilder)
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local WORLD_NAME = "ISLE_ZERO_WORLD"

local function printStatus(player)
    local root = workspace:FindFirstChild(WORLD_NAME)
    print(string.format("[ISLE//ZERO][DEV] World status requested by %s", player.Name))

    if not root then
        print("[ISLE//ZERO][DEV] No generated world model exists")
        return
    end

    local keys = {
        "WorldVersion",
        "WorldSeed",
        "BuildComplete",
        "BuildState",
        "CurrentPhase",
        "SpawnReleased",
        "AuditErrors",
        "AuditWarnings",
        "GeneratedDescendants",
        "WorstPathGrade",
        "TerrainSampledCells",
        "TerrainFilledColumns",
    }

    for _, key in ipairs(keys) do
        print(string.format("[ISLE//ZERO][DEV] %s = %s", key, tostring(root:GetAttribute(key))))
    end

    local buildError = root:GetAttribute("BuildError")
    if buildError then
        warn("[ISLE//ZERO][DEV] Last build error: " .. tostring(buildError))
    end
end

local function runAudit(player)
    local root = workspace:FindFirstChild(WORLD_NAME)
    if not root then
        warn(string.format("[ISLE//ZERO][DEV] %s requested an audit but no generated world exists", player.Name))
        return
    end

    print(string.format("[ISLE//ZERO][DEV] Running manual world audit for %s", player.Name))
    local report = WorldAudit.Run(config, root, TerrainBuilder.HeightAt)
    print(string.format("[ISLE//ZERO][DEV] Manual audit complete: %d error(s), %d warning(s)", #report.errors, #report.warnings))
end

local function rebuild(player)
    if WorldBuilder.IsBuilding() then
        warn(string.format("[ISLE//ZERO][DEV] %s requested a rebuild while one is already running", player.Name))
        return
    end

    print(string.format("[ISLE//ZERO][DEV] Full world rebuild requested by %s", player.Name))
    task.spawn(function()
        local ok, result = pcall(WorldBuilder.Build)
        if ok then
            print("[ISLE//ZERO][DEV] Rebuild complete: " .. result:GetFullName())
        else
            warn("[ISLE//ZERO][DEV] Rebuild failed: " .. tostring(result))
        end
    end)
end

local function onCommand(player, message)
    local command = string.lower(string.gsub(message, "^%s*(.-)%s*$", "%1"))

    if command == "/worldstatus" then
        printStatus(player)
    elseif command == "/worldaudit" then
        runAudit(player)
    elseif command == "/worldrebuild" then
        rebuild(player)
    end
end

local function connectPlayer(player)
    player.Chatted:Connect(function(message)
        onCommand(player, message)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    connectPlayer(player)
end
Players.PlayerAdded:Connect(connectPlayer)

print("[ISLE//ZERO][DEV] Studio commands ready: /worldstatus, /worldaudit, /worldrebuild")
