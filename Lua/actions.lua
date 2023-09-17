Helpers = require "helpers"



function PlaceItem(identifier, character)
    local prefab = ItemPrefab.GetItemPrefab(identifier)
    Entity.Spawner.AddItemToSpawnQueue(prefab, character.WorldPosition, nil, nil, function(item)
        print(item.Name .. " Has been spawned near " .. character.Name)
    end)
end

function GiveAffliction(identifier, character, potency)
    local aff = AfflictionPrefab.Prefabs[identifier]
    local limb = character.AnimController.Limbs[1]

    char.CharacterHealth.ApplyAffliction(limb, aff.Instantiate(potency))
end

function SendDM(message, character)
    client = Util.FindClientCharacter(character)
    local chatMessage = ChatMessage.Create("The Director", message, ChatMessageType.Default, nil, nil)
    chatMessage.Color = Color(255, 0, 0, 0)
    Game.SendDirectChatMessage(chatMessage, client)
end

function Announce(message)
    for _, client in pairs(Client.ClientList) do
        local chatMessage = ChatMessage.Create("The Director", message, ChatMessageType.Default, nil, nil)
        chatMessage.Color = Color(255, 255, 0, 0)
        Game.SendDirectChatMessage(chatMessage, client)
    end
end

function SpawnMonster(character)
    pos = Vector2(character.WorldPosition.X - 2, character.WorldPosition.Y)
    Enitity.Spawner.AddCharacterToSpawnQueue("mudraptor", pos, function(ent)
        print(ent.Name .. " Has been spawned on: " .. character.Name)
    end)
end

function Query(character)

    local info = {}
    info["Alive"] = not character.IsDead
    info["Hull"] = character.CurrentHull and character.CurrentHull.RoomName or "Ocean"
    local buffer = {}
    for item in character.HeldItems do
        table.insert(buffer, item.Name)
    end
    info["HeldItems"] = buffer
    buffer = {}
    info["NearBy"] = Helpers.GetNeighbors(character)
    buffer = {}
    local out = {}
    --making this I'm starting to wonder why I did all that stuff above with info
    table.insert( out, string.format("%s is %s", character.Name, info["Alive"] and "Alive" or "Dead") )
    table.insert(out, string.format("%s is currently %s in water", character.Name, character.AnimController.InWater and "" or "not"))
    table.insert(out, string.format("%s is currently in the %s %s", character.Name, string.gsub(info["Hull"], "(%a+).", "", 1), next(info["NearBy"]) and "with: " .. table.concat(info["NearBy"], ", ") or ""))
    table.insert(out, string.format("%s is holding these item(s): %s", character.Name, next(info["HeldItems"]) and table.concat(info["HeldItems"], ",") or "nothing"))
    return out
end

return{PlaceItem = PlaceItem, 
    GiveAffliction = GiveAffliction,
    SendDM = SendDM,
    Announce = Announce,
    SpawnMonster = SpawnMonster,
    Query = Query
}
