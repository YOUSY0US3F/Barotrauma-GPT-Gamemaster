Helpers = require "helpers"
Actions = require "actions"
GPT = require "GPT"
JSON = require "json"
Ready = false
ElapsedTicks = 0
Delay = math.random(10,60) * 60
-- LastInteracted = {}
LastUsed = {}
-- WasUnconsious = {}
-- ConfirmedDead = {}
KnockedDown = {}
LastToolUse = {}
RepairingWall = {}
Equipped = {}
Wearing = {}
CurrentRoom = {}
RoomWater = {}
NameToCharacter = Actions.NameToCharacter

Hook.Add("roundStart", "start", function ()
    LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CharacterInventory"], "character")
    LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.DelayedEffect"], "setValue")
    LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.StatusEffect"], "setValue")
    local wait = 10 * 60
    for prefab in ItemPrefab.Prefabs do
        if Contains(prefab.Tags, "explosive") then
            print("added detector for:", tostring(prefab.Identifier))
            Hook.Add(string.format("statusEffect.apply.%s", tostring(prefab.Identifier)), string.format("%s explodes",tostring(prefab.Identifier)), function (effect, deltaTime, 
                item, targets, worldPosition)
                if effect.type == ActionType.Always or effect.type == ActionType.OnFire then
                    return
                end
                local msg = string.format("%s exploded!",item.Name)
                Actions.Log(msg)

                print(msg)
            end)
        end
    end
    Hook.Add("think","game start", function ()
        if wait <= 0 then
            Ready = true
            print("Game started")
            Actions.DeleteLogs()
            if GPT == true then
                print("GPT failed to load!!!")
                return
            end
            Hook.Add("think", "send Logs", function ()
                if ElapsedTicks >= Delay then
                    Actions.DumpLogs(GPT.Upload)
                    print("Upload started, delay: ", Delay/60)
                    Delay = math.random(10,60) * 60
                    ElapsedTicks = 0
                    return
                end
                ElapsedTicks = ElapsedTicks + 1
            end)
            Hook.Remove("think", "game start")
        else
            wait = wait - 1
        end
    end)
end)

Hook.Add("tryChangeClientName", "moderate player names", function (client, newName, newJob, newTeam)
    local oldname = client.Name
    GPT.Moderate(newName, function(response)
        local info = JSON.decode(response)
        if info.results[1].flagged then
            local chatMessage = ChatMessage.Create("Game", string.format("Invalid Name!!!\nYou tried to change your name to %s", GPT.CleanMessage(response,newName)), 
            ChatMessageType.MessageBox, nil, nil)
            chatMessage.Color = Color(255,0,0)
            Game.SendDirectChatMessage(chatMessage, client)
            client.Name = oldname
            Networking.LastClientListUpdateID = Networking.LastClientListUpdateID + 1
            Game.SendMessage(string.format("%s\'s name change request has been rejected.", oldname),ChatMessageType.Server, nil, nil )
        end
    end)
end)

-- Hook.Add("loaded", "game fully loaded", function ()
--     print("Loaded!")
-- end)



-- Hook.Add("characterDeath", "player death", function(character)
--     local msg = character.Name .. " has died of" .. character.CauseOfDeath
--     print(msg)
--     Actions.Log(msg)

--  end)

--  Hook.Add("item.drop", "player drops item", function(item, character)
--     if character.IsPlayer then
--         local msg = character.Name .. " has dropped a " .. tostring(item.Prefab.Identifier)
--         print(msg)
--     end
--  end)

-- Hook.Add("item.interact", "player picks up/places and item", function(item, characterPicker, ignoreRequireditemsBool, forceSelectKeyBool, forceActionKeyBool)
--     if characterPicker.IsPlayer or characterPicker.IsHuman then
--         if LastInteracted[characterPicker.Name] == tostring(item.Name) then
--             return
--         end
--         if not item then
--             return
--         end
--         if item.hasTag("smallitem") then
--             if characterPicker.Inventory.Contains(item) then
--                 msg = characterPicker.Name .. " picked up a " .. tostring(item.Name)
--             end
--             print(msg)
--             Actions.Log(msg)

--             LastInteracted[characterPicker.Name] = tostring(item.Name)
--         end
--     end
-- end)

-- Hook.Add("item.interact", "player fixes item", function(item, characterPicker, ignoreRequireditemsBool, forceSelectKeyBool, forceActionKeyBool)
--     if characterPicker.IsPlayer or characterPicker.IsHuman then
--         if LastInteracted[characterPicker.Name] == tostring(item.Name) then
--             return
--         end
--         if not item then
--             return
--         end
--         local helditemID = characterPicker.Inventory.GetItemAt(5)
--         if (item.Prefab.Category == 4 or item.Prefab.Subcategory == "Machine") and helditemID and (helditemID.Prefab.Subcategory == "electricalrepairtool" or helditemID.Prefab.Subcategory == "mechanicalrepairtool") then
--             local msg = string.format("%s is repairing a %s", characterPicker.Name, item.Name)
--             print(msg)
--             Actions.Log(msg)

--             LastInteracted[characterPicker.Name] = tostring(item.Name)
--         end
--     end
-- end)
 


Hook.Add("item.use", "player uses an item", function(item, itemUser, targetLimb)
    if itemUser == nil or item.Name == "Periscope" then
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
        Actions.Log(msg)

        LastUsed[itemUser] = item.Name
    end
 end)

 Hook.Add("item.applyTreatment", "player applies item on another player", function(item, usingCharacter, targetCharacter, limb)
    if usingCharacter.IsPlayer or usingCharacter.IsHuman then
        local msg = usingCharacter.Name .. " used " .. tostring(item.Name) .. " on " .. targetCharacter.Name .. "'s " .. limb.Name
        print(msg)
        Actions.Log(msg)

    end
 end)

 Hook.Add("chatMessage", "player message", function(message, sender)
    GPT.Moderate(message, function(response)
        local msg = string.format("%s radioed: %s", sender.Character.Name, GPT.CleanMessage(response,message))
        print(msg)
        Actions.Log(msg)

    end)
 end)

--  Hook.Add("chatMessage", "debug commands", function(message, sender)
--     if message == "query" then
--         print(table.concat(Actions.Query(sender.Character),"\n"))
--     end
--     if message == "sabotage" then
--         Actions.SabotageTool({character = sender.Character.Name})
--     end
--     if message == "sabotageS" then
--         Actions.SabotageSuit({character = sender.Character.Name})
--     end
--     if message == "godmode" then
--         Actions.MakeInvincible({character = sender.Character.Name, time = 10})
--     end
--     if message == "revive" then
--         Actions.Revive({character = sender.Character.Name})
--     end
--     if message == "item" then
--         Actions.PlaceItem({item = "Potassium", character = sender.Character.Name})
--     end

--     if message == "monster" then
--         Actions.SpawnMonster({character = sender.Character.Name})
--     end

--     if message == "swap" then
--         Actions.ReplaceEquippedItem({character = sender.Character.Name, item = "smg"})
--     end
--  end)

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
        Actions.Log(msg)

    end
 end)

--  Hook.Add("character.ApplyAffliction", "player gets affliction", function (character, limbHealth, newAffliction, allowStacking)
--         if character.GetAffliction(newAffliction.Prefab.Identifier) then
--             return
--         end
--         local msg = string.format( "%s now has %s %s", character.Character.Name, newAffliction.Name, newAffliction.Source and "caused by: " .. newAffliction.Source.Name or "")
--         print(msg)
--         Actions.Log(msg)
   
--  end)

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
            local verb = "picked up"
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
                    Actions.Log(msg)

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
                    Actions.Log(msg)

                    return
                end
            end
            if Wearing[inventory.character] and Helpers.Contains(Wearing[inventory.character], item.Name) and (index > 4 or index < 1) then
                verb = "took off their"
                table.remove( Wearing[inventory.character], IndexOf(Wearing[inventory.character], item.Name))
            end
            local msg = string.format("%s %s %s", inventory.character.Name,verb, item.Name)
            print(msg)
            Actions.Log(msg)
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
        Actions.Log(msg)

    end
 end)

 Hook.Add("statusEffect.apply.flamer", "flamer event", function(effect, deltaTime, item, targets, worldPosition)

    if effect.type == ActionType.OnUse and effect.HasTargetType(StatusEffect.TargetType.Contained) and effect.setValue then
        local msg = string.format("the %s in %s's %s exploded!", targets[1].Name, item.ParentInventory.Owner.Name, item.Name)
        print(msg)
        Actions.Log(msg)

    end
 end)

 Hook.Add("statusEffect.apply.weldingtool", "welding item/limb", function (effect, deltaTime, item, targets, worldPosition)
    if effect.type == ActionType.OnSuccess and next(targets) then
        local msg
        if targets[1].ToString() == "Barotrauma.Limb" then
            -- msg = string.format("%s is using a welding tool on %s's %s", 
            -- item.ParentInventory.Owner.Name, targets[1].character.Name, targets[1].Name)
            return
        else
            msg = string.format("%s is welding a door shut", item.ParentInventory.Owner.Name)
        end
        if msg == LastToolUse[item.ParentInventory.Owner.Name] then
            return
        end
        LastToolUse[item.ParentInventory.Owner.Name] = msg
        print(msg)
        Actions.Log(msg)

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
        Actions.Log(msg)

    end
    if effect.type == ActionType.OnUse and effect.HasTargetType(StatusEffect.TargetType.Contained) and effect.setValue then
        local msg = string.format("the %s in %s's %s exploded!", targets[1].Name, item.ParentInventory.Owner.Name, item.Name)
        print(msg)
        Actions.Log(msg)

    end
end)

 Hook.Add("statusEffect.apply.plasmacutter", "cutting item/limb", function (effect, deltaTime, item, targets, worldPosition)
    if effect.type == ActionType.OnSuccess and next(targets) then
        local msg
        if targets[1].ToString() == "Barotrauma.Limb" and targets[1].character.Name ~= item.ParentInventory.Owner.Name then
            msg = string.format("%s is cutting through %s's %s with a plasma cutter", 
            item.ParentInventory.Owner.Name, targets[1].character.Name, targets[1].Name)
        else
            msg = string.format("%s is cutting through a wall", item.ParentInventory.Owner.Name)
        end
        if msg == LastToolUse[item.ParentInventory.Owner.Name] then
            return
        end
        LastToolUse[item.ParentInventory.Owner.Name] = msg
        print(msg)
        Actions.Log(msg)

    end
    if effect.type == ActionType.OnUse and effect.HasTargetType(StatusEffect.TargetType.Contained) and effect.setValue then
        local msg = string.format("the %s in %s's %s exploded!", targets[1].Name, item.ParentInventory.Owner.Name, item.Name)
        print(msg)
        Actions.Log(msg)

    end
 end)

 Hook.Add("serverLog", "Log", function(line, messageType)
    local msg
    if messageType == 5 then
        msg = Helpers.ParseLog(line)
        print(msg)
        Actions.Log(msg)

    end
    if messageType == 2 and string.find(line,"‖%a+:.+:%d+:%d+‖") then
        msg = Helpers.ParseLog(line)
       local _, playerCount = string.gsub(line, "‖end‖", "")
       if playerCount == 2 or string.find(line, "Human") then
            msg = msg .. "\'s inventory"
       end
        print(msg)
        Actions.Log(msg)

    end
    if messageType == 1 and string.find(line,"‖%a+:.+:%d+:%d+‖") and not string.find(line,"equip") then
        msg = Helpers.ParseLog(line)
        print(msg)
        Actions.Log(msg)

    end 
end)

-- old debug hook
-- Hook.Add("think", "send Logs", function ()
--     if Ready then
--         if ElapsedTicks >= 300 then
--             if #LogBuffer < 7 then
--                 ElapsedTicks = 0
--                 return
--             end
--             local out = io.open("./resources/log.txt", "a")
--             if out == nil then
--                 return
--             end
--             table.insert(LogBuffer, "==============================================================\n")
--             out:write(table.concat(LogBuffer, "\n"))
--             out:close()
--             ElapsedTicks = 0
--             LogBuffer = {}
--             return
--         end
--         ElapsedTicks = ElapsedTicks + 1
--     end
-- end)

-- garbo
-- Hook.Add("think", "Player unconscious/wakes up/dead", function ()
--     for name,character in pairs(NameToCharacter) do
--         if character.IsDead and not ConfirmedDead[character] then
--             local msg = string.format( "%s is dead!",name)
--             print(msg)
--             Actions.Log(msg)

--             ConfirmedDead[character] = true
--             return
--         elseif not WasUnconsious[character] and character.CharacterHealth.IsUnconscious then
--             local msg = string.format( "%s is unconscious!",name)
--             print(msg)
--             Actions.Log(msg)

--             WasUnconsious[character] = true
--         elseif WasUnconsious[character] and not character.CharacterHealth.IsUnconscious then
--             local msg = string.format( "%s is no longer unconscious!",name)
--             if ConfirmedDead[character] then
--                 msg = string.format( "%s is back from the dead!",name)
--                 ConfirmedDead[character] = false
--             end
--             print(msg)
--             Actions.Log(msg)

--             WasUnconsious[character] = false
--         end 
--     end
-- end)

Hook.Add("think", "Player Knocked Down", function ()
    for name, character in pairs(Actions.NameToCharacter) do
        if character.IsKnockedDown and  not KnockedDown[name] then
            local msg = string.format("%s was Knocked down!", name)
            print(msg)
            Actions.Log(msg)
            KnockedDown[name] = true
        elseif KnockedDown[name] and not character.IsKnockedDown then
            KnockedDown[name] = false
        end
    end
end)

Hook.Add("think", "Player enters new room", function ()
    for name, character in pairs(Actions.NameToCharacter) do
        local room
        if not character.CurrentHull then
            room = "Ocean (exited the submarine)"
        else
            room = tostring(character.CurrentHull.DisplayName)
        end
        if not CurrentRoom[character] or CurrentRoom[character] ~= room then
            local neighbors = Helpers.GetNeighbors(character)
            CurrentRoom[character] = room
            local msg = string.format("%s has entered the %s %s", 
                name, room,
                next(neighbors) and "; " .. Helpers.CharacterConcat(neighbors) .. string.format(" %s there.", #neighbors == 1 and "is" or "are") or "")
            
            Actions.Log(msg)
            print(msg)
        end
    end
end)

Hook.Add("think", "Hull water percentage", function ()
    if not Ready then
        return
    end
    if not next(RoomWater) then
        local hulls = Client.ClientList[1].Character.Submarine.GetHulls(false)
        for hull in hulls do
            if not hull.IsWetRoom then
                print(hull.DisplayName)
                RoomWater[hull] = {water = hull.WaterPercentage, trend = 1}
            end
        end
        return
    end
    for hull, info in pairs(RoomWater) do
        if math.abs( info.water - hull.WaterPercentage) >= 40 then
            local msg     
            if (info.water - hull.WaterPercentage) * info.trend < 0 then
                msg = string.format( "The water level in the %s is %s!",tostring(hull.DisplayName),(info.water - hull.WaterPercentage)<0 and "increasing" or "decreasing")
                print(msg, " trend = ",info.trend)
                Actions.Log(msg)


                if hull.WaterPercentage >= 100 then
                    msg = string.format("The %s is full of water", tostring(hull.DisplayName))
                    print(msg)
                    Actions.Log(msg)

                end
               
            end
            RoomWater[hull].trend = (info.water - hull.WaterPercentage)/math.abs( info.water - hull.WaterPercentage )
            RoomWater[hull].water = hull.WaterPercentage
        end
    end 
end)


--string.gsub(room,"(%a+).", "", 1)