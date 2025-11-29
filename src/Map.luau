local Types = require(script.Parent.Types)

local Map = {}

function Map.ValidateStructure(structure: Instance): Types.MapStructure
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

    local displayName = structure:GetAttribute("DisplayName")
    assert(displayName == nil or typeof(displayName) == "string", "DisplayName must be a string")

    local description = structure:GetAttribute("Description")
    assert(typeof(description) == "string", "Description must be a string")

    local authors = structure:GetAttribute("Authors")
    assert(typeof(authors) == "string", "Authors must be a string")

    local icon = structure:GetAttribute("Icon")
    assert(icon == nil or typeof(icon) == "string", "Icon must be a string")

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

    local items: {[string]: Types.ItemDefinition} = {}
    local itemsFolder = structure:FindFirstChild("ItemDefinitions")
    if itemsFolder then
        for _, module in itemsFolder:GetChildren() do
            if module:IsA("ModuleScript") then
                local definition: Types.ItemDefinition = (require :: any)(module).Definition
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

    local name = structure.Name
    local originalNameAttr = structure:GetAttribute("OriginalName")
    if typeof(originalNameAttr) == "string" then
        name = originalNameAttr
    end

    return {
        Structure = structure,

        Name = name,
        DisplayName = structure:GetAttribute("DisplayName") :: string?,
        Description = structure:GetAttribute("Description") :: string,
        Authors = structure:GetAttribute("Authors") :: string,
        Icon = structure:GetAttribute("Icon") :: string,

        Gravity = structure:GetAttribute("Gravity") :: number? or 50,

        InteractableDefinitions = interactables,
        ItemDefinitions = items,
        AmmoDefinitions = ammo,
    }
end

return Map