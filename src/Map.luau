local Types = require(script.Parent.Types)
local module = {}

local function validateMapIcons(mapIcons: any): ()
    assert(typeof(mapIcons) == "table", "MapIcons must be a table")
    assert(mapIcons["16:9"] == nil or typeof(mapIcons["16:9"]) == "string", 'MapIcons["16:9"] must be a string')
    assert(mapIcons["4:3"] == nil or typeof(mapIcons["4:3"]) == "string", 'MapIcons["4:3"] must be a string')
    assert(mapIcons["1:1"] == nil or typeof(mapIcons["1:1"]) == "string", 'MapIcons["1:1"] must be a string')
end

local function validateClouds(clouds: any): ()
    if clouds == nil then
        return
    end
    assert(typeof(clouds) == "table", "CloudsSettings must be nil or a table")
    assert(typeof(clouds.Cover) == "number", "CloudsSettings.Cover must be a number")
    assert(typeof(clouds.Density) == "number", "CloudsSettings.Density must be a number")
    assert(typeof(clouds.Color) == "Color3", "CloudsSettings.Color must be a Color3")
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

    validateClouds(definition.CloudsSettings)

    return definition
end

function module.ValidateMapScript(mapScript: Instance): Types.MapScript
    assert(mapScript:IsA("ModuleScript"), "MapScript must be a ModuleScript")

    module.ValidateDefinition((require)(mapScript))

    local static = mapScript:FindFirstChild("Static")
    assert(static and static:IsA("Folder"), "MapScript must have a Static Folder")

    local dynamic = mapScript:FindFirstChild("Dynamic")
    assert(dynamic and dynamic:IsA("Folder"), "MapScript must have a Dynamic Folder")

    local playerSpawns = mapScript:FindFirstChild("PlayerSpawns")
    assert(playerSpawns and playerSpawns:IsA("Folder"), "MapScript must have a PlayerSpawns Folder")

    local terrain = mapScript:FindFirstChild("Terrain")
    assert(not terrain or terrain:IsA("TerrainRegion"), "Terrain must be a TerrainRegion")

    local lighting = mapScript:FindFirstChild("Lighting")
    assert(not lighting or lighting:IsA("Folder"), "Lighting must be a Folder")

    local materialVariants = mapScript:FindFirstChild("MaterialVariants")
    assert(not materialVariants or materialVariants:IsA("Folder"), "MaterialVariants must be a Folder")

    return mapScript :: Types.MapScript
end

function module.fromMapScript(mapScript: Types.MapScript): Types.Map
    local maybeDefinition: unknown = (require)(mapScript)
    local definition = module.ValidateDefinition(maybeDefinition)

    return {
        Definition = definition,
        Map = definition.Map,

        PlayerSpawns = definition.Map.PlayerSpawns,

        Static = definition.Map.Static,
        Dynamic = definition.Map.Dynamic,
    }
end

return module