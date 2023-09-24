Helpers = require "helpers"

DirectorNames = {"God?", "???!", "strange voice", "a voice", "he47fgv", "Game?", "it"}

local function getDirectorName()
    return DirectorNames[math.random(#DirectorNames)]
end

function PlaceItem(identifier, character)
    local prefab = ItemPrefab.GetItemPrefab(identifier)
    Entity.Spawner.AddItemToSpawnQueue(prefab, character.WorldPosition, nil, nil, function(item)
        print(item.Name .. " Has been spawned near " .. character.Name)
        local client = Util.FindClientCharacter(character)
        local chatMessage = ChatMessage.Create("?", "Something appeared at your feet...", ChatMessageType.ServerMessageBoxInGame, nil, nil)
        chatMessage.Color = Color(255,182,193)
        Game.SendDirectChatMessage(chatMessage, client)
    end)
end

-- function GiveAffliction(identifier, character, potency)
--     local aff = AfflictionPrefab.Prefabs[identifier]
--     local limb = character.AnimController.Limbs[1]

--     char.CharacterHealth.ApplyAffliction(limb, aff.Instantiate(potency))
-- end

function SendDM(message, character)
    local client = Util.FindClientCharacter(character)
    local chatMessage = ChatMessage.Create(getDirectorName(), message, ChatMessageType.Default, nil, nil)
    chatMessage.Color = Color(255,182,193)
    Game.SendDirectChatMessage(chatMessage, client)
end

function Announce(message)
    for _, client in pairs(Client.ClientList) do
        local chatMessage = ChatMessage.Create(getDirectorName(), message, ChatMessageType.Default, nil, nil)
        chatMessage.Color = Color(255, 255, 255)
        Game.SendDirectChatMessage(chatMessage, client)
    end
end

function SpawnMonster(character)
    pos = Vector2(character.WorldPosition.X - 20, character.WorldPosition.Y)
    Entity.Spawner.AddCharacterToSpawnQueue("mudraptor", pos, function(ent)
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

function Sabotage(item)
    local tank = item.OwnInventory.GetItemAt(0)
    local repl
    if tank.HasTag("weldingtoolfuel") then
        repl = ItemPrefab.GetItemPrefab("oxygentank")
    else
        repl = ItemPrefab.GetItemPrefab("weldingfueltank")
    end
    item.OwnInventory.RemoveItem(tank)
    Entity.Spawner.AddItemToSpawnQueue(repl, item.OwnInventory, nil, nil, function(thing)
        print(thing.Name .. ", where it doesn't belong...")
    end)
end

function SabotageTool(character)
    local item = character.Inventory.GetItemAt(5)
    if item and item.HasTag("mountableweapon") then
        if item.OwnInventory and (item.OwnInventory.GetItemAt(0).HasTag("weldingtoolfuel") or item.OwnInventory.GetItemAt(0).HasTag("oxygensource")) then
            Sabotage(item)
            return
        end
    end
end

function SabotageSuit(character)
    local suit = character.Inventory.GetItemAt(4)
    local mask = character.Inventory.GetItemAt(2)
    local item
    if (suit and suit.HasTag("diving")) then
        item = suit
    elseif (mask and mask.HasTag("diving")) then
        item = mask
    else
        return
    end
    Sabotage(item)
end

function Revive(character)
    character.Revive(true)
    Util.FindClientCharacter(character).SetClientCharacter(character)
end

function MakeInvincible(character, time)
    character.GodMode = true
    print(character.Name," has godmode")
    local client = Util.FindClientCharacter(character)
    local chatMessage = ChatMessage.Create("?", string.format("some strange power has granted you invincibility for %s seconds", time), ChatMessageType.ServerMessageBoxInGame, nil, nil)
    chatMessage.Color = Color(255,182,193)
    Game.SendDirectChatMessage(chatMessage, client)
    local tickTime = time * 60
    Hook.Add("think", character.Name .. " GodModeTimer", function ()
        if tickTime <= 0 then
            print(character.Name, "is no longer invincible")
            local client = Util.FindClientCharacter(character)
            local chatMessage = ChatMessage.Create("?", "You are mortal once more.", ChatMessageType.ServerMessageBoxInGame, nil, nil)
            chatMessage.Color = Color(255,182,193)
            Hook.Remove("think", character.Name .. " GodModeTimer")
            return
        end
        tickTime = tickTime - 1
    end)
end
return{PlaceItem = PlaceItem, 
    SendDM = SendDM,
    Announce = Announce,
    SpawnMonster = SpawnMonster,
    Query = Query,
    SabotageTool = SabotageTool,
    SabotageSuit = SabotageSuit,
    Revive = Revive,
    MakeInvincible = MakeInvincible
}
