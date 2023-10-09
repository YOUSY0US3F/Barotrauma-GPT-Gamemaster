Helpers = require "helpers"
LogBuffer = {}
TokenBuffer = {}
DirectorNames = {"God?", "???!", "strange voice", "a voice", "he47fgv", "Game?", "Server?"}
NameToCharacter = {}
Hook.Add("roundStart", "collect characters", function ()
    for _,character in pairs(Character.CharacterList) do
        print(character.Name)
        NameToCharacter[character.Name] = character
    end
    Hook.Add("character.created", "character spawns in", function (createdCharacter)
        if createdCharacter.IsHuman and not NameToCharacter[createdCharacter.Name] then
            print(createdCharacter.Name)
            NameToCharacter[createdCharacter.Name] = createdCharacter
        end
    end)
end)
local function cacheTokens(message)
    if not next(TokenBuffer) then
        table.insert(TokenBuffer, #message/4)
        return
    end
    table.insert(TokenBuffer, TokenBuffer[#TokenBuffer]+(#message/4))
end

local function DumpTokens()
    local copy = {}
    for val in TokenBuffer do
        table.insert(copy, val)
    end
    TokenBuffer = {}
    return copy
end
function Log(message)
    if message ~= LogBuffer[#LogBuffer] then
        table.insert(LogBuffer, message)
        cacheTokens(message)
    end
end

function DumpLogs(func)
    if #LogBuffer < 1 then 
        print("nothing happened, aborting")
        return 
    end
    func(LogBuffer, DumpTokens())
    ElapsedTicks = 0
    LogBuffer = {}
end

function DeleteLogs()
    LogBuffer = {}
end

local function getDirectorName()
    return DirectorNames[math.random(#DirectorNames)]
end

function PlaceItem(arg)
    local identifier = arg.item
    local character = NameToCharacter[arg.character]
    local prefab = ItemPrefab.GetItemPrefab(identifier)
    Entity.Spawner.AddItemToSpawnQueue(prefab, character.WorldPosition, nil, nil, function(item)
        print(item.Name .. " Has been spawned near " .. character.Name)
        local client = Util.FindClientCharacter(character)
        local chatMessage = ChatMessage.Create("?", "Something appeared at your feet...", ChatMessageType.ServerMessageBoxInGame, nil, nil)
        chatMessage.Color = Color(255,182,193)
        Game.SendDirectChatMessage(chatMessage, client)
        Log(string.format("You Placed a %s near %s", item.Name, character.Name))
    end)
end

function MakeIll(arg)
    local character = NameToCharacter[arg.character]
    local aff = AfflictionPrefab.Prefabs["nausea"]
    local limb = character.AnimController.Limbs[1]

    char.CharacterHealth.ApplyAffliction(limb, aff.Instantiate(100))
    Log(string.format("You made %s Ill", character.Name))
end

function SendDM(arg)
    local message = arg.message
    local character = NameToCharacter[arg.character]
    if not character.IsPlayer then
        Log(string.format("Your Message to %s fell upon deaf ears", arg.character))
        return
    end
    local client = Util.FindClientCharacter(character)
    local chatMessage = ChatMessage.Create(getDirectorName(), message, ChatMessageType.Default, nil, nil)
    chatMessage.Color = Color(255,165,0)
    Game.SendDirectChatMessage(chatMessage, client)
    Log(string.format("You Messaged %s: %s", arg.character, message))
end

function Announce(arg)
    local message = arg.message
    local director = "???"
    for _, client in pairs(Client.ClientList) do
        local chatMessage = ChatMessage.Create(director, message, ChatMessageType.Default, nil, nil)
        chatMessage.Color = Color(255, 255, 255)
        Game.SendDirectChatMessage(chatMessage, client)
        Log(string.format("You Announced : %s", message))
    end
end

function SpawnMonster(arg)
    local character = NameToCharacter[arg.character]
    local pos = Vector2(character.WorldPosition.X - 20, character.WorldPosition.Y)
    Entity.Spawner.AddCharacterToSpawnQueue("mudraptor", pos, function(ent)
        print(ent.Name .. " Has been spawned on: " .. character.Name)
        Log(string.format("You Summoned a Beast near %s", character.Name))
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
    table.insert(out, string.format("%s is %s", character.Name, info["Alive"] and "Alive" or "Dead"))
    table.insert(out, string.format("%s is currently %s in water", character.Name, character.AnimController.InWater and "" or "not"))
    table.insert(out, string.format("%s is currently in the %s %s", character.Name, string.gsub(info["Hull"], "(%a+).", "", 1), next(info["NearBy"]) and "with: " .. table.concat(info["NearBy"], ", ") or ""))
    table.insert(out, string.format("%s is holding these item(s): %s", character.Name, next(info["HeldItems"]) and table.concat(info["HeldItems"], ",") or "nothing"))
    return out
end

local function Sabotage(item)
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

function SabotageTool(arg)
    local character = NameToCharacter[arg.character]
    local item = character.Inventory.GetItemAt(5)
    if item and item.HasTag("mountableweapon") then
        if item.OwnInventory and (item.OwnInventory.GetItemAt(0).HasTag("weldingtoolfuel") or item.OwnInventory.GetItemAt(0).HasTag("oxygensource")) then
            Sabotage(item)
            Log(string.format("You Sabotaged %s\'s %s", character.Name, item.Name))
            return
        end
    end
end

function SabotageSuit(arg)
    local character = NameToCharacter[arg.character]
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
    Log(string.format("You Sabotaged %s\'s %s", character.Name, item.Name))
end

function Revive(arg)
    local character = NameToCharacter[arg.character]
    character.Revive(true)
    Util.FindClientCharacter(character).SetClientCharacter(character)
    --print(character," is back from the dead!")
    Log(string.format("You Revived %s", character.Name))
end

function MakeInvincible(arg)
    local character = NameToCharacter[arg.character]
    local time = arg.time
    character.GodMode = true
    print(character.Name," has godmode")
    local client = Util.FindClientCharacter(character)
    local chatMessage = ChatMessage.Create("?", string.format("some strange power has granted you invincibility for %s seconds", time), ChatMessageType.ServerMessageBoxInGame, nil, nil)
    chatMessage.Color = Color(255,182,193)
    Game.SendDirectChatMessage(chatMessage, client)
    local tickTime = time * 60
    Log(string.format("You Granted %s Invinciblity for %d seconds", character.Name, time))
    Hook.Add("think", character.Name .. " GodModeTimer", function ()
        if tickTime <= 0 then
            print(character.Name, " is no longer invincible")
            Log(string.format("%s is no longer invincible", character.Name))
            local client = Util.FindClientCharacter(character)
            local chatMessage = ChatMessage.Create("?", "You are mortal once more.", ChatMessageType.ServerMessageBoxInGame, nil, nil)
            chatMessage.Color = Color(255,182,193)
            Game.SendDirectChatMessage(chatMessage, client)
            Hook.Remove("think", character.Name .. " GodModeTimer")
            return
        end
        tickTime = tickTime - 1
    end)
end

function TeleportCharacter(arg)
    local character = NameToCharacter[arg.character]
    local destination = NameToCharacter[arg.destination]
    character.TeleportTo(destination.WorldPosition)
    Log(string.format("You Teleported %s to %s", character.Name, destination.Name))
end

function CureCharacter(arg)
    local character = NameToCharacter[arg.character]
    character.CharacterHealth.RemoveAllAfflictions()
    Log(string.format("You Cured %s", character.Name))
end

function ReplaceEquippedItem(arg)
    local character = NameToCharacter[arg.character]
    local prefab = ItemPrefab.GetItemPrefab(arg.item)
    if not character.Inventory.CanBePutInSlot(prefab, InvSlotType.RightHand, nil, nil) then
        PlaceItem(arg)
        return
    end
    local equip = character.Inventory.getItemInLimbSlot(InvSlotType.RightHand) ~= nil and character.Inventory.getItemInLimbSlot(InvSlotType.RightHand) or character.Inventory.getItemInLimbSlot(InvSlotType.LeftHand)
    local equipName = equip and equip.Name or "Nothing"
    for i in character.HeldItems do
        character.Inventory.RemoveItem(i)
     end
    Entity.Spawner.AddItemToSpawnQueue(prefab, character.Inventory, nil, nil, function (thing)
        character.Inventory.ForceToSlot(thing, InvSlotType.RightHand)
        equip.Remove()
        equip.Visible = false
        local client = Util.FindClientCharacter(character)
        local chatMessage = ChatMessage.Create("?", string.format("It's a miracle! Your %s turned into a %s!", equipName, thing.Name), ChatMessageType.ServerMessageBoxInGame, nil, nil)
        chatMessage.Color = Color(255,182,193)
        Game.SendDirectChatMessage(chatMessage, client)
        Log(string.format("You turned %s\'s %s into %s", character.Name, equipName, thing.Name))
    end, true, false, InvSlotType.RightHand)
end

return{
    NameToCharacter = NameToCharacter,
    PlaceItem = PlaceItem, 
    SendDM = SendDM,
    Announce = Announce,
    SpawnMonster = SpawnMonster,
    Query = Query,
    SabotageTool = SabotageTool,
    SabotageSuit = SabotageSuit,
    Revive = Revive,
    MakeInvincible = MakeInvincible,
    TeleportCharacter = TeleportCharacter,
    CureCharacter = CureCharacter,
    Log = Log,
    DumpLogs = DumpLogs,
    DeleteLogs = DeleteLogs,
    MakeIll = MakeIll,
    ReplaceEquippedItem = ReplaceEquippedItem
}
