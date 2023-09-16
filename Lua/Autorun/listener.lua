Helpers = require "helpers"
Actions = require "actions"
LogBuffer = {}
ElapsedTicks = 0
LastInteracted = {}
LastAffliction = {}
LastUsed = nil
NameToCharacter = {}

Hook.Add("roundStart", "setup", function ()
    LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CharacterInventory"], "character")
    for _,character in pairs(Character.CharacterList) do
        NameToCharacter[character.Name] = character
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

 Hook.Add("item.interact", "player interacts with item", function(item, characterPicker, ignoreRequireditemsBool, forceSelectKeyBool, forceActionKeyBool)
    if characterPicker.IsPlayer or characterPicker.IsHuman then
        if LastInteracted[characterPicker.Name] == tostring(item.Name) then
            return
        end
        -- local interactionType = " used a "
        -- local msg = characterPicker.Name .. interactionType .. item.Name
        if item.hasTag("smallitem") then
            msg = characterPicker.Name .. " picked up a " .. tostring(item.Name)
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
        local msg = itemUser.Name .. " used " .. tostring(item.Name)
        if tostring(item.Prefab.Identifier) == "ethanol" or tostring(item.Prefab.Identifier) == "rum" then
            msg = itemUser.Name .. " drank " .. item.Name
            print(msg)
            table.insert(LogBuffer, msg)
        end
        
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
        local msg = string.format("%s was hit in the %s by %s", character.Character.Name, hitLimb.Name, attackResult.Afflictions[1].Source.Name)  
        print(msg," vitality decrease: ", tostring(attackResult.Afflictions[1].GetVitalityDecrease(character)))
        table.insert(LogBuffer, msg)
        if character.IsUnconscious then
            msg = string.format("%s is %s", character.Character.Name, character.IsDead and "dead!" or "unconscious!")
            print(msg)
            table.insert(LogBuffer, msg)
        end
    end
 end)

 Hook.Add("character.ApplyAffliction", "player gets affliction", function (character, limbHealth, newAffliction, allowStacking)
    if character.Character.IsPlayer or character.Character.IsHuman then
        if character.GetAffliction(newAffliction.Prefab.Identifier) then
            return
        end
        local msg = string.format( "%s now has %s %s", character.Character.Name, newAffliction.Name, newAffliction.Source and "caused by: " .. newAffliction.Source.Name or "")
        print(msg)
        table.insert(LogBuffer, msg)   
    end
 end)

 Hook.Add("inventoryPutItem", "player puts item in inventory", function(inventory, item, characterUser, index, swapWholeStackBool)
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

            msg = string.format("%s grabbed a %s", inventory.character.Name, item.Name)
            print(msg)
            table.insert(LogBuffer, msg)
        end
        
    end
 end)


Hook.Add("think", "send Logs", function ()
    if not Game.RoundStarted then
        return
    end
    if ElapsedTicks >= 1200 then
        
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

-- Hook.Patch("Barotrauma.Networking.GameServer", "Log", function(line, messageType)
--     print(line)
-- end, Hook.HookMethodType.Before)