local Types = require(script.Parent.Types)
local module = {}

-- We always want to use WaitForChild, because if a client is using this script, not all children may be replicated immediately.
local function waitForFolder(parent: Instance, name: string): Folder
    local folder = assert(parent:WaitForChild(name), "Instance not found")
    assert(folder:IsA("Folder"), "Instance is not a folder")
    return folder
end

local function GetDisplayName(map: Types.Map): string
    return map.DisplayName or map.Name
end

function module.fromModuleScript(mapScript: ModuleScript): Types.Map
    local definition = (require)(mapScript)

    local playerSpawns = waitForFolder(mapScript, "PlayerSpawns")
    local staticMap = waitForFolder(mapScript, "StaticMap")

    local bounds = waitForFolder(mapScript, "Bounds")

    local dynamicMap = waitForFolder(mapScript, "DynamicMap")
    local props = waitForFolder(mapScript, "Props")
    local windows = waitForFolder(mapScript, "Windows")
    local itemSpawns = waitForFolder(mapScript, "ItemSpawns")
    local ammoSpawns = waitForFolder(mapScript, "AmmoSpawns")

    local materialVariants = waitForFolder(mapScript, "MaterialVariants")

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

        TerrainColors = definition.TerrainColors,
        WaterSettings = definition.WaterSettings,

        PlayerSpawns = playerSpawns,

        StaticMap = staticMap,
        Bounds = bounds,

        DynamicMap = dynamicMap,
        Props = props,
        Windows = windows,
        ItemSpawns = itemSpawns,
        AmmoSpawns = ammoSpawns,

        MaterialVariants = materialVariants,

        GetDisplayName = GetDisplayName,
    }
end

return module