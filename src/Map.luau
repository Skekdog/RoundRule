local Types = require(script.Parent.Types)

local Map = {}

function Map.ValidateStructure(structure: Instance): Types.MapStructure
    local metadataModule = structure:FindFirstChild("Metadata")
    assert(metadataModule and metadataModule:IsA("ModuleScript"), "Map must have Metadata ModuleScript")

    local metadata: {[unknown]: unknown} = (require)(metadataModule)
    assert(typeof(metadata) == "table", "Metadata must return a table")

    local displayName = metadata.DisplayName
    assert(displayName == nil or typeof(displayName) == "string", "DisplayName must be a string or nil")

    local description = metadata.Description
    assert(typeof(description) == "string", "Description must be a string")

    local authors = metadata.Authors
    assert(typeof(authors) == "string", "Authors must be a string")

    local icon = metadata.Icon
    assert(typeof(icon) == "Content", "Icon must be a Content. Use `Content.none` for default icon.")

    local static = structure:FindFirstChild("Static")
    assert(static, "Map must have Static")

    local dynamic = structure:FindFirstChild("Dynamic")
    assert(dynamic, "Map must have Dynamic")

    local playerSpawns = structure:FindFirstChild("PlayerSpawns")
    assert(playerSpawns, "Map must have PlayerSpawns")

    local terrain = structure:FindFirstChild("Terrain")
    assert(not terrain or terrain:IsA("TerrainRegion"), "Terrain must be a TerrainRegion")

    local clouds = structure:FindFirstChild("Clouds")
    assert(not clouds or clouds:IsA("Clouds"), "Clouds must be a Clouds")

    local gravity = structure:GetAttribute("Gravity")
    assert(gravity == nil or typeof(gravity) == "number", "Gravity must be a number")

    return structure :: Types.MapStructure
end

function Map.new(structure: Types.MapStructure): Types.Map
    local interactables: {[string]: Types.InteractableDefinition} = {}
    local interactablesFolder = structure:FindFirstChild("InteractableDefinitions")
    if interactablesFolder then
        for _, module in interactablesFolder:GetChildren() do
            if module:IsA("ModuleScript") then
                local definition: Types.InteractableDefinition = (require :: any)(module).Definition
                interactables[definition.Name] = definition
            end
        end
    end

    local items: {[string]: Types.ItemComponents} = {}
    local itemsFolder = structure:FindFirstChild("ItemDefinitions")
    if itemsFolder then
        for _, module in itemsFolder:GetChildren() do
            if module:IsA("ModuleScript") then
                local definition: Types.ItemComponents = (require :: any)(module).Definition
                items[definition.Name] = definition
            end
        end
    end

    local ammo: {[string]: Types.AmmoDefinition} = {}
    local ammoFolder = structure:FindFirstChild("AmmoDefinitions")
    if ammoFolder then
        for _, module in ammoFolder:GetChildren() do
            if module:IsA("ModuleScript") then
                local definition: Types.AmmoDefinition = (require :: any)(module).Definition
                ammo[definition.Name] = definition
            end
        end
    end

    local bosses: {[string]: Types.BossDefinition} = {}
    local bossesFolder = structure:FindFirstChild("Bosses")
    if bossesFolder then
        for _, module in bossesFolder:GetChildren() do
            if module:IsA("ModuleScript") then
                local definition: Types.BossDefinition = (require :: any)(module).Definition
                bosses[definition.Name] = definition
            end
        end
    end

    local name = structure.Name
    local originalNameAttr = structure:GetAttribute("OriginalName")
    if typeof(originalNameAttr) == "string" then
        name = originalNameAttr
    end

    local metadata: Types.MapMetadata = (require)(structure.Metadata)

    return {
        Structure = structure,

        Name = name,
        DisplayName = metadata.DisplayName,
        Description = metadata.Description,
        Authors = metadata.Authors,
        Icon = metadata.Icon,

        Gravity = structure:GetAttribute("Gravity") :: number? or 50,

        InteractableDefinitions = interactables,
        ItemDefinitions = items,
        AmmoDefinitions = ammo,
        Bosses = bosses,
    }
end

return table.freeze(Map)