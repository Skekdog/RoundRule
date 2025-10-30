local Types = require(script.Parent.Types)
local module = {}

local function validateClouds(clouds: any): ()
    if clouds == nil then
        return
    end
    assert(typeof(clouds) == "table", "CloudsSettings must be nil or a table")
    assert(typeof(clouds.Cover) == "number", "CloudsSettings.Cover must be a number")
    assert(typeof(clouds.Density) == "number", "CloudsSettings.Density must be a number")
    assert(typeof(clouds.Color) == "Color3", "CloudsSettings.Color must be a Color3")
end

function module.ValidateDefinition(mapScript: Instance, definition: any): Types.MapDefinition
    assert(typeof(definition) == "table", "MapDefinition must be a table")

    for i, v in definition.AvailableAmmo do
		assert(i == v.Name, "Ammo name in AvailableAmmo must match index")
	end

	for i, v in definition.AvailableItems do
		assert(i == v.Name, "Item name in AvailableItems must match index")
	end

    validateClouds(definition.CloudsSettings)

    return definition
end

function module.ValidateMapScript(mapScript: Instance): Types.MapScript
    assert(mapScript:IsA("ModuleScript"), "MapScript must be a ModuleScript")

    module.ValidateDefinition(mapScript, (require)(mapScript))

    local static = mapScript:FindFirstChild("Static")
    assert(static, "MapScript must have a Static Folder")

    local dynamic = mapScript:FindFirstChild("Dynamic")
    assert(dynamic, "MapScript must have a Dynamic Folder")

    local playerSpawns = mapScript:FindFirstChild("PlayerSpawns")
    assert(playerSpawns, "MapScript must have a PlayerSpawns Folder")

    local terrain = mapScript:FindFirstChild("Terrain")
    assert(not terrain or terrain:IsA("TerrainRegion"), "Terrain must be a TerrainRegion")

    return mapScript :: Types.MapScript
end

function module.fromMapScript(mapScript: Types.MapScript): Types.Map
    local maybeDefinition: unknown = (require)(mapScript)
    local definition = module.ValidateDefinition(mapScript, maybeDefinition)

    return {
        Definition = definition,
        Map = definition.Map,

        PlayerSpawns = definition.Map.PlayerSpawns,

        Static = definition.Map.Static,
        Dynamic = definition.Map.Dynamic,
    }
end

return module