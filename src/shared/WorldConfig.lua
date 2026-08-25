local WorldConfig = {
    WorldVersion = 1,
    Seed = 7102026,

    SeaLevel = 0,
    OceanDepth = 90,
    WorldHalfSize = 1600,

    Island = {
        HalfX = 1180,
        HalfZ = 980,
        Grid = 32,
        BaseY = -72,
        BeachBand = 0.18,
    },

    Generation = {
        YieldEvery = 180,
        ClearExisting = true,
        VegetationDensity = 1.0,
    },

    Locations = {
        CrashBeach = Vector3.new(120, 8, 790),
        JungleGate = Vector3.new(90, 36, 560),
        Village = Vector3.new(360, 52, 120),
        RiverBasin = Vector3.new(-180, 46, 120),
        Waterfall = Vector3.new(-260, 92, -130),
        BunkerApproach = Vector3.new(820, 88, -50),
        EastLookout = Vector3.new(930, 150, -250),
        RidgeRuins = Vector3.new(160, 205, -550),
        Summit = Vector3.new(-90, 286, -680),
        Mangroves = Vector3.new(-780, 18, 200),
    },

    ScenicZones = {
        AncientBanyan = {
            Position = Vector3.new(-40, 0, 330),
            Radius = 86,
        },
        BlueHole = {
            Position = Vector3.new(80, 0, -300),
            Radius = 72,
        },
        MangroveLagoon = {
            Position = Vector3.new(-790, 0, 205),
            Radius = 66,
        },
        WindArch = {
            Position = Vector3.new(900, 0, -575),
            Radius = 78,
        },
    },

    Paths = {
        Main = {
            Vector3.new(120, 0, 760),
            Vector3.new(80, 0, 610),
            Vector3.new(180, 0, 480),
            Vector3.new(310, 0, 320),
            Vector3.new(360, 0, 140),
            Vector3.new(270, 0, -20),
            Vector3.new(80, 0, -90),
            Vector3.new(-120, 0, -140),
            Vector3.new(-260, 0, -140),
            Vector3.new(-150, 0, -330),
            Vector3.new(40, 0, -480),
            Vector3.new(160, 0, -560),
            Vector3.new(40, 0, -650),
            Vector3.new(-90, 0, -700),
        },
        EastLoop = {
            Vector3.new(360, 0, 120),
            Vector3.new(540, 0, 160),
            Vector3.new(720, 0, 80),
            Vector3.new(820, 0, -40),
            Vector3.new(860, 0, -210),
            Vector3.new(700, 0, -360),
            Vector3.new(470, 0, -430),
            Vector3.new(200, 0, -520),
        },
        WestLoop = {
            Vector3.new(90, 0, 610),
            Vector3.new(-150, 0, 650),
            Vector3.new(-390, 0, 570),
            Vector3.new(-620, 0, 400),
            Vector3.new(-790, 0, 200),
            Vector3.new(-610, 0, 20),
            Vector3.new(-400, 0, -60),
            Vector3.new(-220, 0, -120),
        },
    },
}

return WorldConfig
