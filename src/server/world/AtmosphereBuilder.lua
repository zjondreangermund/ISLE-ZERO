local Lighting = game:GetService("Lighting")

local AtmosphereBuilder = {}

local function replace(className, name, parent)
    local existing = parent:FindFirstChild(name)
    if existing then
        existing:Destroy()
    end
    local object = Instance.new(className)
    object.Name = name
    object.Parent = parent
    return object
end

function AtmosphereBuilder.Build()
    Lighting.ClockTime = 15.35
    Lighting.Brightness = 2.25
    Lighting.GlobalShadows = true
    Lighting.ShadowSoftness = 0.22
    Lighting.EnvironmentDiffuseScale = 0.38
    Lighting.EnvironmentSpecularScale = 0.55
    Lighting.ExposureCompensation = -0.05
    Lighting.GeographicLatitude = 8
    Lighting.Ambient = Color3.fromRGB(88, 95, 91)
    Lighting.OutdoorAmbient = Color3.fromRGB(133, 144, 138)

    local atmosphere = replace("Atmosphere", "ISLEZeroAtmosphere", Lighting)
    atmosphere.Color = Color3.fromRGB(199, 222, 222)
    atmosphere.Decay = Color3.fromRGB(89, 109, 113)
    atmosphere.Density = 0.29
    atmosphere.Glare = 0.12
    atmosphere.Haze = 1.75
    atmosphere.Offset = 0.05

    local color = replace("ColorCorrectionEffect", "ISLEZeroColor", Lighting)
    color.Brightness = -0.015
    color.Contrast = 0.08
    color.Saturation = -0.04
    color.TintColor = Color3.fromRGB(244, 250, 244)

    local sunRays = replace("SunRaysEffect", "ISLEZeroSunRays", Lighting)
    sunRays.Intensity = 0.045
    sunRays.Spread = 0.78

    local bloom = replace("BloomEffect", "ISLEZeroBloom", Lighting)
    bloom.Intensity = 0.18
    bloom.Size = 20
    bloom.Threshold = 1.25

    local clouds = workspace.Terrain:FindFirstChild("ISLEZeroClouds")
    if clouds then
        clouds:Destroy()
    end
    clouds = Instance.new("Clouds")
    clouds.Name = "ISLEZeroClouds"
    clouds.Cover = 0.3
    clouds.Density = 0.56
    clouds.Color = Color3.fromRGB(238, 241, 237)
    clouds.Parent = workspace.Terrain

    -- FallenPartsDestroyHeight is intentionally left to Studio place settings;
    -- Roblox restricts changing it from ordinary runtime scripts.
end

return AtmosphereBuilder
