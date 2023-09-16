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



return {Stringify = Stringify, CharacterClients = CharacterClients}