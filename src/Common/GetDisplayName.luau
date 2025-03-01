local function GetDisplayName(object: {Name: string, DisplayName: string?}): string
    return object.DisplayName or object.Name
end

return GetDisplayName