local Types = require(script.Parent.Types)
local module = {}

-- We always want to use WaitForChild, because if a client is using this script, not all children may be replicated immediately.

local function waitForClass(parent: Instance, name: string, class: string): Instance
    local Instance = assert(parent:WaitForChild(name), "Instance not found")
    assert(Instance:IsA(class), "Instance is not a " .. class)
    return Instance
end

local function waitForFolder(parent: Instance, name: string): Folder
    return waitForClass(parent, name, "Folder") :: Folder
end

function module.fromModuleScript(mapScript: ModuleScript): Types.Map
    local definition = (require)(mapScript)

    local playerSpawns = waitForFolder(mapScript, "PlayerSpawns")
    local staticMap = waitForFolder(mapScript, "StaticMap")

    local lightingModifiers = waitForFolder(mapScript, "LightingModifiers")
    local futureLightingModifiers = waitForFolder(mapScript, "FutureLightingModifiers")

    local bounds = waitForFolder(mapScript, "Bounds")

    local dynamicMap = waitForFolder(mapScript, "DynamicMap")
    local props = waitForFolder(mapScript, "Props")
    local windows = waitForFolder(mapScript, "Windows")
    local itemSpawns = waitForFolder(mapScript, "ItemSpawns")
    local ammoSpawns = waitForFolder(mapScript, "AmmoSpawns")
    local interactables = waitForFolder(mapScript, "Interactables")

    local materialVariants = waitForFolder(mapScript, "MaterialVariants")

    local terrainRegion = waitForClass(mapScript, "TerrainRegion", "TerrainRegion") :: TerrainRegion

    return {
        Name = definition.Name,
        DisplayName = definition.DisplayName,
        Description = definition.Description,
        Authors = definition.Authors,

        MapIcons = definition.MapIcons,

        AvailableAmmo = definition.AvailableAmmo,
        AvailableItems = definition.AvailableItems,

        Gravity = definition.Gravity,

        LightingSettings = definition.LightingSettings,
        FutureLightingSettings = definition.FutureLightingSettings,

        LightingModifiers = lightingModifiers,
        FutureLightingModifiers = futureLightingModifiers,

        TerrainColors = definition.TerrainColors,
        WaterSettings = definition.WaterSettings,

        PlayerSpawns = playerSpawns,

        TerrainRegion = terrainRegion,
        StaticMap = staticMap,
        Bounds = bounds,

        DynamicMap = dynamicMap,
        Props = props,
        Windows = windows,
        ItemSpawns = itemSpawns,
        AmmoSpawns = ammoSpawns,
        Interactables = interactables,

        MaterialVariants = materialVariants,
    }
end

return module