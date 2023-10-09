JSON = require "json"
Actions = require "actions"
Helpers = require "helpers"
Secret = require "secret"
CallToFunction = {
    ["PlaceItem"] = Actions.PlaceItem,
    ["SendPrivateMessage"] = Actions.SendDM,
    ["Announce"] = Actions.Announce,
    ["SummonBeast"] = Actions.SpawnMonster,
    ["SabotageTool"] = Actions.SabotageTool,
    ["SabotageSuit"] = Actions.SabotageSuit,
    ["Revive"] = Actions.Revive,
    ["GrantInvulnerability"] = Actions.MakeInvincible,
    ["TeleportTo"] = Actions.TeleportCharacter,
    ["CureCharacter"] = Actions.CureCharacter,
    ["MakeIll"] = Actions.MakeIll,
    ["ReplaceHeldItem"] = Actions.ReplaceEquippedItem

}
TokenBuffer = {}
MadPrompt = File.Read("LocalMods\\Gamemaster\\Lua\\resources\\madGodPrompt.txt")
NormalPrompt = File.Read("LocalMods\\Gamemaster\\Lua\\resources\\prompt.txt")
FunctionList = JSON.decode(File.Read("LocalMods/Gamemaster/Lua/resources/functions.json"))
Prompt = NormalPrompt
SixteenK = {
    name = "gpt-3.5-turbo-16k",
    MaxTokens = 16000
}
Turbo = {
    name = "gpt-3.5-turbo",
    MaxTokens = 4000
}
Model = Turbo
Temperature = 1
MessageBuffer = {}
FunctionLen = 3160

Hook.Add("chatMessage", "admin commands", function(message, client) 
    if client.HasPermission(ClientPermissions.ManageSettings) then
        if message == "godswap" then
            if Prompt == NormalPrompt then
                Prompt = MadPrompt
                Temperature = 1.3
                Actions.Announce({message = "You swear you heard the water laughing at you"})
            else
                Temperature = 1
                Prompt = NormalPrompt
                Actions.Announce({message = "Things start to make a little more sense now"})
            end
            return true
        end
        if message == "forcestart" then
            Hook.Call("roundstart", {})
            print("called roundstart")
            return true
        end
        if message == "stressTest" then
            print("stress test started")
            for i = 1, 2 * Model.MaxTokens do        
                Actions.Log(string.format("Stress Test Line Number %d", i))
            end
            return true
        end

    end
end)

local function appendTokens(tokens)
    if not next(TokenBuffer) then
        TokenBuffer = tokens
        return
    end
    local prev = TokenBuffer[#TokenBuffer]
    for token in tokens do
        table.insert(TokenBuffer, token+prev)
        prev = token
    end
end

function CleanMessage(response, message)
    local info = JSON.decode(response)
    if info.results[1].flagged then
        local flags = {}
        for key, val in pairs(info.results[1].categories) do
            if val then
                table.insert(flags,key)
            end
        end
        return string.format( "something flagged as: %s",table.concat(flags,", ") )
    end
    return message
end

-- local function addToBuffer(prompt, messages)
--     for message in messages do
--         local msg = {
--             role = "user",
--             content = message
--         }
--         table.insert( MessageBuffer , msg)
--     end
--     if (string.len(prompt) + FunctionLen)/4 >= Model.MaxTokens/2 then
--         if Model.name == Turbo.name then
--             Model = SixteenK
--         else
--             print("fatal error: context too damn big")
--         end
--     elseif Model.name == SixteenK.name and (string.len(prompt) + FunctionLen)/4 < Turbo.MaxTokens/2 then
--         Model = Turbo
--     end

--     while Helpers.TokenLength(MessageBuffer) >= Model.MaxTokens/2 do
--         table.remove(MessageBuffer,1)
--     end
    
-- end
local function propagate(value)
    for i = 1, #TokenBuffer do
        TokenBuffer[i] = TokenBuffer[i] - value
    end
end

local function addToBuffer(messages)
    for message in messages do
        table.insert(MessageBuffer, message)
    end
    if TokenBuffer[#TokenBuffer] + (#TokenBuffer-1) >= Model.MaxTokens/2 then
        while TokenBuffer[1] do
            local token = TokenBuffer[1]
            if ((TokenBuffer[#TokenBuffer] + (#TokenBuffer-1)) - token) < Model.MaxTokens/2 then
                table.remove(TokenBuffer,1)
                table.remove(MessageBuffer,1)
                propagate(token)
                break
            else
                table.remove(TokenBuffer, 1)
                table.remove(MessageBuffer,1)
            end
        end
    end
    return {
        role = "user",
        content = table.concat(MessageBuffer, ",")
    }
end



function Moderate(message, callback)
    local data = JSON.encode({input = message})
    Networking.HttpPost("https://api.openai.com/v1/moderations",callback, data,"application/json",{["Authorization"] = string.format("Bearer %s", Secret.TOKEN)},nil)
end

local function GeneratePrompt()

    local items = {
        name = {},
        description = {}
    }
    local characters = {
        name = {},
        info = {}
    }
    local prefabs = Helpers.GetRandomItems()
    for i = 1,10 do
        local prefab = prefabs[i]
        if not prefab then break end
        table.insert(items.name,tostring(prefab.Name))
        table.insert(items.description, string.format("%s: %s", tostring(prefab.Name),tostring(prefab.Description)))
    end
    for _,character in pairs(Character.CharacterList) do
        if character.IsPlayer then
            table.insert(characters.name, character.Name)
            table.insert(characters.info, Helpers.CharacterStatus(character))
        end
    end
    local itemString = string.format("Items (case sensitive): %s", table.concat( items.name, ", "))
    local itemDescriptions = string.format("Item Descriptions: %s", table.concat( items.description, ", "))
    local charString = string.format("Characters (case sensitive): %s\nCharacter Info: %s", Helpers.CharacterConcat(characters.name), table.concat( characters.info, ", "))
    return table.concat({Prompt, itemString,itemDescriptions, charString}, "\n")
end

-- function InitGPT()
--     local prompt = GeneratePrompt()
--     local functionFile = io.open("./resources/functions.json","r")
--     if not functionFile then
--         print("no functions found!!!!")
--         return
--     end
--     local functionList = JSON.decode(functionFile:read("*a"))
--     local data = JSON.encode({
--         model = "gpt-3.5-turbo",
--         messages = {
--             {
--                 role = "system",
--                 content = prompt
--             },
--             {
--                 role = "user",
--                 content = "You have awakened, Let the Characters know of your presence"
--             }
--         },
--         functions = functionList,
--         function_call = "auto"
--     })
--     print(data)
--     Networking.HttpPost("https://api.openai.com/v1/chat/completions",function (resolve)
--         print("GPT has awakened")
--         print(resolve)
--     end, data,"application/json",{["Authorization"] = string.format("Bearer %s", Secret.TOKEN)},nil)
-- end

local function execute(response)
    local calls = JSON.decode(response)
    for choice in calls.choices do
        if choice.finish_reason == "function_call" then
            local call = choice.message.function_call
            local args = JSON.decode(call.arguments)
            print("args: ",table.concat(args,", "))
            CallToFunction[call.name](args)
        end
    end
end

local function sendToGPT(data)
    Networking.HttpPost("https://api.openai.com/v1/chat/completions",function (resolve)
       local ok, result = pcall(execute, resolve)
       if not ok then
            print(resolve)
            Model = SixteenK
       end
    end, data,"application/json",{["Authorization"] = string.format("Bearer %s", Secret.TOKEN)},nil)
end

function Upload(log, tokens)
    appendTokens(tokens)
    local prompt = {
        role = "system",
        content = GeneratePrompt()
    }
    if (string.len(prompt.content) + FunctionLen)/4 >= Model.MaxTokens/2 then
        if Model.name == Turbo.name then
            Model = SixteenK
        else
            print("fatal error: context too damn big")
        end
    elseif Model.name == SixteenK.name and (string.len(prompt.content) + FunctionLen)/4 < Turbo.MaxTokens/2 then
        Model = Turbo
    end
    if tokens[#tokens] >= Turbo.MaxTokens/2 then
        Model = SixteenK
    end 
    local msg = addToBuffer(log)
    local data = JSON.encode({
        model = Model.name,
        messages = {
            prompt,
            msg
        },
        temperature = Temperature,
        functions = FunctionList
    })
    local out = io.open("E:\\Games\\Steam\\steamapps\\common\\Barotrauma\\LocalMods\\Gamemaster\\Lua\\resources\\UploadLog.json", "a")
    if not out then
        print("no output file found :(")
        return
    end
    out:write(data .. ",\n")
    out:close()
    -- sendToGPT(data)

    print("message sent, Tokens: ",TokenBuffer[#TokenBuffer])
    table.remove(MessageBuffer,1)
end

return{
    Moderate = Moderate,
    CleanMessage = CleanMessage,
    Upload = Upload
}