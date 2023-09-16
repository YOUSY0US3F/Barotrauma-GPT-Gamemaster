function Stringify(prefabs, filter)
    local out = ""
    for prefab in prefabs do
        if filter(prefab) then
            out = out .. tostring(prefab.Identifier) .. " "
        end
    end
    return out
end

-- maps character names to their corresponding clients (useless)
function CharacterClients()
    local table = {}
    for _,client in pairs(Client.ClientList) do
        table[client.Character.Name] = client
    end
    return table
end

function GetHeldItems(character)
    local heldItems = {}
        for item in character.HeldItems do
            table.insert(heldItems, item.Name)
        end
        return heldItems
end

function IsEquipped(character, itemName)
    for item in character.HeldItems do
        if item.Name == itemName then
            return true
        end
    end
    return false
end


return {Stringify = Stringify, CharacterClients = CharacterClients, GetHeldItems = GetHeldItems, IsEquipped = IsEquipped}