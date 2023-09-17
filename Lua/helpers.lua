function Stringify(prefabs, filter)
    local out = ""
    for prefab in prefabs do
        if filter(prefab) then
            out = out .. tostring(prefab.Identifier) .. " "
        end
    end
    return out
end

-- maps character characters to their corresponding clients (useless)
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

function GetNeighbors(character)
    if not character.CurrentHull then
        return  {}
    end
    local buffer = {}
    for _,otherchar in pairs(Character.CharacterList) do
        if otherchar.IsHuman and otherchar ~= character and otherchar.CurrentHull then
            if otherchar.CurrentHull.RoomName == character.CurrentHull.RoomName then
                table.insert( buffer, otherchar.Name )
            end
        end
    end
    return buffer
end

function CharacterConcat(characters)
    if #characters == 1 then return characters[1] end
    local out = ""
    for i, character in ipairs(characters) do
        if i == (#characters - 1) then
            out = out .. character .. " and "
        elseif i == #characters then
            out = out .. character
        else
            out = out .. character .. ", "
        end
    end
    return out
end


return {Stringify = Stringify, 
CharacterClients = CharacterClients, 
GetHeldItems = GetHeldItems, 
IsEquipped = IsEquipped,
GetNeighbors = GetNeighbors,
CharacterConcat = CharacterConcat}