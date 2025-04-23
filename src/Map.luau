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

local function validateMapIcons(mapIcons: any): ()
    assert(typeof(mapIcons) == "table", "MapIcons must be a table")
    assert(mapIcons["16:9"] == nil or typeof(mapIcons["16:9"]) == "string", 'MapIcons["16:9"] must be a string')
    assert(mapIcons["4:3"] == nil or typeof(mapIcons["4:3"]) == "string", 'MapIcons["4:3"] must be a string')
    assert(mapIcons["1:1"] == nil or typeof(mapIcons["1:1"]) == "string", 'MapIcons["1:1"] must be a string')
end

local function validateDefinition(definition: any): Types.MapDefinition
    assert(typeof(definition) == "table", "MapDefinition must be a table")

    assert(typeof(definition.Name) == "string", "Name must be a string")
    assert(definition.DisplayName == nil or typeof(definition.DisplayName) == "string", "DisplayName must be a string")
    assert(typeof(definition.Description) == "string", "Description must be a string")
    assert(typeof(definition.Authors) == "string", "Authors must be a string")
    
    validateMapIcons(definition.MapIcons)

    assert(typeof(definition.AvailableItems) == "table", "AvailableItems must be a table")
    assert(typeof(definition.AvailableAmmo) == "table", "AvailableAmmo must be a table")

    assert(typeof(definition.Gravity) == "number", "Gravity must be a number")

    assert(typeof(definition.WaterSettings) == "table", "WaterSettings must be a table")
    assert(typeof(definition.TerrainColors) == "table", "TerrainColors must be a table")

    assert(typeof(definition.LightingSettings) == "table", "LightingSettings must be a table")
    assert(typeof(definition.FutureLightingSettings) == "table", "FutureLightingSettings must be a table")

    return definition
end

function module.fromModuleScript(mapScript: ModuleScript): Types.Map
    local maybeDefinition: unknown = (require)(mapScript)
    local definition = validateDefinition(maybeDefinition)

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