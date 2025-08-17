local Types = require(script.Parent.Types)
local module = {}

-- We always want to use WaitForChild, because if a client is using this script, not all children may be replicated immediately.

local function waitForClass<T>(parent: Instance, name: string, class: T & Instance): T
    local Instance = assert(parent:WaitForChild(name), "Instance not found")
    assert(Instance:IsA(class.ClassName), "Instance is not a " .. class.ClassName)
    return Instance :: Instance & T
end

local function waitForFolder(parent: Instance, name: string): Folder
    return waitForClass(parent, name, Instance.new("Folder")) :: Folder
end

local function validateMapIcons(mapIcons: any): ()
    assert(typeof(mapIcons) == "table", "MapIcons must be a table")
    assert(mapIcons["16:9"] == nil or typeof(mapIcons["16:9"]) == "string", 'MapIcons["16:9"] must be a string')
    assert(mapIcons["4:3"] == nil or typeof(mapIcons["4:3"]) == "string", 'MapIcons["4:3"] must be a string')
    assert(mapIcons["1:1"] == nil or typeof(mapIcons["1:1"]) == "string", 'MapIcons["1:1"] must be a string')
end

function module.ValidateDefinition(definition: any): Types.MapDefinition
    assert(typeof(definition) == "table", "MapDefinition must be a table")

    assert(typeof(definition.Name) == "string", "Name must be a string")
    assert(definition.DisplayName == nil or typeof(definition.DisplayName) == "string", "DisplayName must be a string")
    assert(typeof(definition.Description) == "string", "Description must be a string")
    assert(typeof(definition.Authors) == "string", "Authors must be a string")
    
    validateMapIcons(definition.MapIcons)

    assert(typeof(definition.AvailableItems) == "table", "AvailableItems must be a table")
    assert(typeof(definition.AvailableAmmo) == "table", "AvailableAmmo must be a table")

    return definition
end

function module.fromModuleScript(mapScript: ModuleScript): Types.Map
    mapScript = mapScript:Clone()
    local maybeDefinition: unknown = (require)(mapScript)
    local definition = module.ValidateDefinition(maybeDefinition)

    local playerSpawns = waitForFolder(mapScript, "PlayerSpawns")

    local staticFolder = waitForFolder(mapScript, "Static")
    local dynamicFolder = waitForFolder(mapScript, "Dynamic")

    local configuration = mapScript:WaitForChild("Configuration")
    local lightingSettings = configuration:WaitForChild("LightingSettings")
    local waterSettings = configuration:WaitForChild("WaterSettings")
    local terrainColours = configuration:WaitForChild("TerrainColours")
    local gravity = waitForClass(configuration, "Gravity", Instance.new("NumberValue"))

    local materialVariants = configuration:WaitForChild("MaterialVariants")

    local terrainRegion = waitForClass(mapScript, "TerrainRegion", Instance.new("TerrainRegion"))

    return {
        Name = definition.Name,
        DisplayName = definition.DisplayName,
        Description = definition.Description,
        Authors = definition.Authors,
        Extras = definition.Extras or {},

        Folder = mapScript,

        MapIcons = definition.MapIcons,

        AvailableAmmo = definition.AvailableAmmo,
        AvailableItems = definition.AvailableItems,

        Configuration = {
            LightingSettings = lightingSettings,
            WaterSettings = waterSettings,
            TerrainColours = terrainColours,
            Gravity = gravity.Value,
            MaterialVariants = materialVariants,
        },

        PlayerSpawns = playerSpawns,

        TerrainRegion = terrainRegion,

        Static = staticFolder,
        Dynamic = dynamicFolder,

        MaterialVariants = materialVariants,
    }
end

return module