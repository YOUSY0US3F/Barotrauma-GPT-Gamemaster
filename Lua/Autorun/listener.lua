Helpers = require "helpers"
Actions = require "actions"
LogBuffer = {}
ElapsedTicks = 0
LastInteracted = {}
LastUsed = {}
WasUnconsious = {}
ConfirmedDead = {}
LastToolUse = {}
RepairingWall = {}
Equipped = {}
Wearing = {}
CurrentRoom = {}

NameToCharacter = {}

Hook.Add("roundStart", "setup", function ()
    LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CharacterInventory"], "character")
    for _,character in pairs(Character.CharacterList) do
        NameToCharacter[character.Name] = character
        print(character.Name)
        CurrentRoom[character] = character.CurrentHull.RoomName
    end
end)

Hook.Add("loaded", "game fully loaded", function ()
    print("Loaded!")
end)

Hook.Add("character.created", "character spawns in", function (createdCharacter)
    if createdCharacter.IsHuman and not NameToCharacter[createdCharacter.Name] then
        NameToCharacter[createdCharacter.Name] = createdCharacter
        print(createdCharacter.Name," was created")
    end
end)

-- Hook.Add("characterDeath", "player death", function(character)
--     local msg = character.Name .. " has died of" .. character.CauseOfDeath
--     print(msg)
--     table.insert(LogBuffer, msg)
--  end)

--  Hook.Add("item.drop", "player drops item", function(item, character)
--     if character.IsPlayer then
--         local msg = character.Name .. " has dropped a " .. tostring(item.Prefab.Identifier)
--         print(msg)
--     end
--  end)

Hook.Add("item.interact", "player picks up/places and item", function(item, characterPicker, ignoreRequireditemsBool, forceSelectKeyBool, forceActionKeyBool)
    if characterPicker.IsPlayer or characterPicker.IsHuman then
        if LastInteracted[characterPicker.Name] == tostring(item.Name) then
            return
        end
        if not item then
            return
        end
        if item.hasTag("smallitem") then
            if characterPicker.Inventory.Contains(item) then
                msg = characterPicker.Name .. " picked up a " .. tostring(item.Name)
            end
            print(msg)
            table.insert(LogBuffer, msg)
            LastInteracted[characterPicker.Name] = tostring(item.Name)
        end
    end
end)

Hook.Add("item.interact", "player fixes item", function(item, characterPicker, ignoreRequireditemsBool, forceSelectKeyBool, forceActionKeyBool)
    if characterPicker.IsPlayer or characterPicker.IsHuman then
        if LastInteracted[characterPicker.Name] == tostring(item.Name) then
            return
        end
        if not item then
            return
        end
        if item.Prefab.Category == 4 or item.Prefab.Subcategory == "Machine" then
            local msg = string.format("%s is repairing a %s", characterPicker.Name, item.Name)
            print(msg)
            table.insert(LogBuffer, msg)
            LastInteracted[characterPicker.Name] = tostring(item.Name)
        end
    end
end)
 


Hook.Add("item.use", "player uses an item", function(item, itemUser, targetLimb)
    if itemUser == nil then
        return
    end
    if itemUser.IsPlayer or itemUser.IsHuman then
        local msg = itemUser.Name .. " is using a " .. tostring(item.Name)
        if tostring(item.Prefab.Identifier) == "ethanol" or tostring(item.Prefab.Identifier) == "rum" then
            msg = itemUser.Name .. " drank " .. item.Name
        end
        if LastUsed[itemUser] and LastUsed[itemUser] == item.Name then
            return
        elseif item.Prefab.Category == 4 or item.Prefab.Subcategory == "Machine" then
            msg = string.format("%s is working on %s %s", itemUser.Name, (item.hasTag("reactor") or item.hasTag("engine")) and "the" or "a", item.Name)
        end
        print(msg)
        table.insert(LogBuffer, msg)
        LastUsed[itemUser] = item.Name
    end

 end)

 Hook.Add("item.applyTreatment", "player applies item on another player", function(item, usingCharacter, targetCharacter, limb)
    if usingCharacter.IsPlayer or usingCharacter.IsHuman then
        local msg = usingCharacter.Name .. " used " .. tostring(item.Name) .. " on " .. targetCharacter.Name .. "'s " .. limb.Name
        print(msg)
        table.insert(LogBuffer, msg)
    end
 end)

 Hook.Add("chatMessage", "player message", function(message, sender)
    local msg = sender.Character.Name .. " said: " .. message 
    print(msg)
    table.insert(LogBuffer, msg)
 end)

 Hook.Add("chatMessage", "debug commands", function(message, sender)
    if message == "query" then
        print(table.concat(Actions.Query(sender.Character),"\n"))
    end
 end)

 Hook.Add("character.applyDamage", "player damage", function(character, attackResult, hitLimb, allowStacking)
    if character.Character.IsPlayer or character.Character.IsHuman then
        if not attackResult.Afflictions then
            return
        end
        if attackResult.Afflictions[1].GetVitalityDecrease(character) <= 1 then
            return
        end
        local heldItems = Helpers.GetHeldItems(attackResult.Afflictions[1].Source)
        local msg = string.format("%s was hit in the %s by %s %s", character.Character.Name, 
            hitLimb.Name, attackResult.Afflictions[1].Source.Name, 
            next(heldItems) and "with a: ".. heldItems[1] or "")  
        print(msg)
        table.insert(LogBuffer, msg)
    end
 end)

 Hook.Add("character.ApplyAffliction", "player gets affliction", function (character, limbHealth, newAffliction, allowStacking)
        if character.GetAffliction(newAffliction.Prefab.Identifier) then
            return
        end
        local msg = string.format( "%s now has %s %s", character.Character.Name, newAffliction.Name, newAffliction.Source and "caused by: " .. newAffliction.Source.Name or "")
        print(msg)
        table.insert(LogBuffer, msg)   
 end)

 Hook.Add("inventoryPutItem", "player acquires new item or equips/unequips item", function(inventory, item, characterUser, index, swapWholeStackBool)
    if not characterUser then
        return
    end
    if not item then
        print("item is nil")
    end
    if not inventory then
        print("inventory is nil")
    end
    if characterUser.IsPlayer or characterUser.IsHuman then
        if inventory.ToString() == "Barotrauma.CharacterInventory" then
            local verb = "acquired a"
            if index <= 4 and index >= 1 then
                verb = "wore a"
                if not Wearing[inventory.character] then
                    Wearing[inventory.character] = {}
                end
                table.insert(Wearing[inventory.character], item.Name)
            end
            if index == 5 or index == 6 then
                verb = "equipped a" 
                if not Equipped[inventory.character] then
                    Equipped[inventory.character] = {}
                end
                if index == 6 then
                    Equipped[inventory.character][1] = item.Name
                else
                    Equipped[inventory.character][2] = item.Name
                end
                if item.Name == "Handcuffs" then
                    local msg = string.format("%s was Handcuffed", inventory.character.Name)
                    print(msg)
                    table.insert(LogBuffer, msg)
                    return
                end
            end
            -- cool awesome spaghetti code to manually define unequipping
            -- later discorverd this was reported in server logs already, but I'm keeping this here
            -- as a monument to my hubris
            if Equipped[inventory.character] and (Equipped[inventory.character][1] == item.Name or Equipped[inventory.character][2] == item.Name) and index ~=5 and index ~=6 then
                if Equipped[inventory.character][1] == item.Name then
                    Equipped[inventory.character][1] = ""
                else
                    Equipped[inventory.character][2] = ""
                end
                verb = "put away their"
                if item.Name == "Handcuffs" then
                    local msg = string.format("%s is no longer Handcuffed", inventory.character.Name)
                    print(msg)
                    table.insert(LogBuffer, msg)
                    return
                end
            end
            if Wearing[inventory.character] and Helpers.Contains(Wearing[inventory.character], item.Name) and (index > 4 or index < 1) then
                verb = "took off their"
                table.remove( Wearing[inventory.character], IndexOf(Wearing[inventory.character], item.Name))
            end
            local msg = string.format("%s %s %s", inventory.character.Name,verb, item.Name)
            if msg ~= LogBuffer[#LogBuffer] then
                print(msg)
                table.insert(LogBuffer, msg)
            end
        end
        
    end
 end)

 Hook.Add("inventoryPutItem", "Player Takes item out of another Player's Inventory", function(inventory, item, characterUser, index, swapWholeStackBool)
    if inventory.ToString() == "Barotrauma.CharacterInventory" and item.PreviousParentInventory.ToString() == "Barotrauma.CharacterInventory" and 
    item.PreviousParentInventory.character.Name~= characterUser.Name then
        local prevInv = item.PreviousParentInventory
        local msg = string.format("%s took %s's %s", characterUser.Name, prevInv.character.Name, item.Name)
        if Wearing[prevInv.character] and Helpers.Contains(Wearing[prevInv.character], item.Name) then
            msg = string.format("%s stripped off %s's %s", characterUser.Name, prevInv.character.Name, item.Name)
        end
        print(msg)
        table.insert(LogBuffer, msg)
    end
 end)

 Hook.Add("statusEffect.apply.weldingtool", "welding item/limb", function (effect, deltaTime, item, targets, worldPosition)
    if effect.type == ActionType.OnSuccess and next(targets) then
        local msg
        if targets[1].ToString() == "Barotrauma.Limb" then
            msg = string.format("%s is using a welding tool on %s's %s", 
            item.ParentInventory.Owner.Name, targets[1].character.Name, targets[1].Name)
        else
            msg = string.format("%s is welding a door shut", item.ParentInventory.Owner.Name)
        end
        if msg == LastToolUse[item.ParentInventory.Owner.Name] then
            return
        end
        LastToolUse[item.ParentInventory.Owner.Name] = msg
        print(msg)
        table.insert(LogBuffer, msg)
    end
 end)

 Hook.Add("statusEffect.apply.weldingtool", "repairing", function (effect, deltaTime, item, targets, worldPosition)
    if effect.type == ActionType.OnSuccess and not next(targets) then
        local msg = string.format("%s is repairing a wall", item.ParentInventory.Owner.Name)
        if RepairingWall[item.ParentInventory.Owner.Name] then
            return
        end
        RepairingWall[item.ParentInventory.Owner.Name] = true
        print(msg)
        table.insert(LogBuffer, msg)
    end
 end)

 Hook.Add("statusEffect.apply.plasmacutter", "cutting item/limb", function (effect, deltaTime, item, targets, worldPosition)
    if effect.type == ActionType.OnSuccess and next(targets) then
        local msg
        if targets[1].ToString() == "Barotrauma.Limb" then
            msg = string.format("%s is cutting through %s's %s with a plasma cutter", 
            item.ParentInventory.Owner.Name, targets[1].character.Name, targets[1].Name)
        else
            msg = string.format("%s is cutting open a door", item.ParentInventory.Owner.Name)
        end
        if msg == LastToolUse[item.ParentInventory.Owner.Name] then
            return
        end
        LastToolUse[item.ParentInventory.Owner.Name] = msg
        print(msg)
        table.insert(LogBuffer, msg)
    end
 end)

 Hook.Add("statusEffect.apply.reactor", "reactor exploded", function (effect, deltaTime, item, targets, worldPosition)
    if effect.type == ActionType.OnBroken then
        local msg = "The Reacter has detonated!!!"
        print(msg)
        table.insert(LogBuffer, msg)
    end
 end)

 Hook.Add("serverLog", "Log", function(line, messageType)
    local msg
    if messageType == 5 then
        msg = Helpers.CleanLog(line)
        print(msg)
    end
    if messageType == 2 and string.find(line,"‖%a+:.+:%d+:%d+‖") and not string.find(line,"picked") then
        msg = Helpers.CleanLog(line)
        print(msg)
    end
    if messageType == 1 and string.find(line,"‖%a+:.+:%d+:%d+‖") and not string.find(line,"equip") then
        msg = Helpers.CleanLog(line)
        print(msg)
    end
    table.insert(LogBuffer, msg)
end)

Hook.Add("think", "send Logs", function ()
    if not Game.RoundStarted then
        return
    end
    if ElapsedTicks >= 300 then
        if #LogBuffer < 7 then
            ElapsedTicks = 0
            return
        end
        local out = io.open("E:/Games/Steam/steamapps/common/Barotrauma/LocalMods/Gamemaster/Lua/log.txt", "a")
        if out == nil then
            return
        end
        table.insert(LogBuffer, "==============================================================\n")
        out:write(table.concat(LogBuffer, "\n"))
        out:close()
        ElapsedTicks = 0
        LogBuffer = {}
        return
    end
    ElapsedTicks = ElapsedTicks + 1
end)

Hook.Add("think", "Player unconscious/wakes up/dead", function ()
    for name,character in pairs(NameToCharacter) do
        if character.IsDead and not ConfirmedDead[character] then
            local msg = string.format( "%s is dead!",name)
            print(msg)
            table.insert(LogBuffer, msg)
            ConfirmedDead[character] = true
        elseif not WasUnconsious[character] and character.CharacterHealth.IsUnconscious then
            local msg = string.format( "%s is unconscious!",name)
            print(msg)
            table.insert(LogBuffer, msg)
            WasUnconsious[character] = true
        elseif WasUnconsious[character] and not character.CharacterHealth.IsUnconscious then
            local msg = string.format( "%s is no longer unconscious!",name)
            print(msg)
            table.insert(LogBuffer, msg)
            WasUnconsious[character] = false
        end 
    end
end)

Hook.Add("think", "Player enters new room", function ()
    for name, character in pairs(NameToCharacter) do
        local room
        if not character.CurrentHull then
            --out of pure laziness I decide to just make this the same format as the rooms
            room = "roomname.Ocean"
        else
            room = character.CurrentHull.RoomName
        end
        if not CurrentRoom[character] or CurrentRoom[character] ~= room then
            local neighbors = Helpers.GetNeighbors(character)
            CurrentRoom[character] = room
            local msg = string.format("%s has entered the %s %s", 
                name, string.gsub(room,"(%a+).", "", 1), 
                next(neighbors) and "; " .. Helpers.CharacterConcat(neighbors) .. string.format(" %s there.", #neighbors == 1 and "is" or "are") or "")
            
            table.insert(LogBuffer,msg)
            print(msg)
        end
    end
end)

