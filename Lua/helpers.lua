
-- useless
-- function Stringify(prefabs, filter)
--     local out = ""
--     for prefab in prefabs do
--         if filter(prefab) then
--             out = out .. tostring(prefab.Identifier) .. " "
--         end
--     end
--     return out
-- end

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
        if otherchar ~= character and otherchar.CurrentHull then
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

function Contains(list, object)
    for item in list do
        if object == item then
            return true
        end
    end
    return false
end

function IndexOf(list, object)
    for i,v in ipairs(list) do
        if v == object then
            return i
        end
    end
    return 1
end

function ParseLog(log)
    return string.gsub(log, "‖%a+:.+:%d+:%d+‖",""):gsub("‖end‖","")
end

local function permute(tab, n)
    n = n or #tab
    for i = 1, n do
      local j = math.random(i, n)
      tab[i], tab[j] = tab[j], tab[i]
    end
    return tab
end

function GetRandomItems()
    local tab = {}
    for prefab in ItemPrefab.Prefabs do
        if ((prefab.Category == 8 or prefab.Category == 16 or prefab.Category == 64 or prefab.Category == 1024) or Helpers.Contains(prefab.Tags, "instrument")) and tostring(prefab.Description) ~= "" then
            table.insert(tab,prefab)
        end
    end
    return permute(tab,#tab)
end

function TokenLength(promptLength, messageBuffer)
    local length = 0
    for message in messageBuffer do
        length = length + string.len(message.content)
    end
    return (length + promptLength)/4
end

function CleanLog(log)
    local buf = {}
    local i = 1
    while i <= #log do
        if not next(buf) or buf[#buf] ~= log[i] then
            table.insert(buf,log[i])
        end
        i = i +1
    end
    return table.concat(buf,"\n")
end

function CharacterStatus(character)
    local affs = {}
    for affliction in character.CharacterHealth.GetAllAfflictions() do
        if affliction.Strength >= 0.5 and not Contains(affs,string.match(affliction.Name, "%b()") )then
            table.insert(affs,string.match(affliction.Name, "%b()"))
        end
    end
    return string.format("[%s: role: %s, Status: (%s) %s %s Afflictions: %s]", character.Name,tostring(character.Info.Job.Name),
    character.IsDead and "Dead" or "Alive", character.IsUnconscious and "(Unconscious)" or "", character.GodMode and "(Invincible)" or "",   next(affs) and table.concat(affs, ", ") or "None")
end


return {
    CharacterClients = CharacterClients, 
    GetHeldItems = GetHeldItems, 
    IsEquipped = IsEquipped,
    GetNeighbors = GetNeighbors,
    CharacterConcat = CharacterConcat,
    Contains = Contains,
    IndexOf = IndexOf,
    GetRandomItems = GetRandomItems,
    TokenLength = TokenLength,
    CleanLog = CleanLog,
    CharacterStatus = CharacterStatus,
    ParseLog = ParseLog
}