local Types = require(script.Parent.Types)
local module = {}

local function newFolderWithNameAndParent(name: string, parent: Instance): Folder
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function findFirstFolder(parent: Instance, name: string): Folder?
    local folder = parent:FindFirstChild(name)
    if not folder then
        return nil
    end

    assert(folder:IsA("Folder"), "Instance is not a folder")

    return folder
end

function module.fromModuleScript(mapScript: ModuleScript): Types.Map
    local definition = (require)(mapScript)

    local playerSpawns = assert(findFirstFolder(mapScript, "PlayerSpawns"), "PlayerSpawns folder not found")
    local staticMap = assert(findFirstFolder(mapScript, "StaticMap"), "StaticMap folder not found")

    local bounds = findFirstFolder(mapScript, "Bounds") or newFolderWithNameAndParent("Bounds", mapScript)

    local dynamicMap = findFirstFolder(mapScript, "DynamicMap") or newFolderWithNameAndParent("DynamicMap", mapScript)
    local props = findFirstFolder(mapScript, "Props") or newFolderWithNameAndParent("Props", mapScript)
    local windows = findFirstFolder(mapScript, "Windows") or newFolderWithNameAndParent("Windows", mapScript)
    local itemSpawns = findFirstFolder(mapScript, "ItemSpawns") or newFolderWithNameAndParent("ItemSpawns", mapScript)
    local ammoSpawns = findFirstFolder(mapScript, "AmmoSpawns") or newFolderWithNameAndParent("AmmoSpawns", mapScript)

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

        MaterialVariants = findFirstFolder(mapScript, "MaterialVariants"),
    }
end

return module