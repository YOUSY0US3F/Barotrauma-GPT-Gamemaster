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
    ["Nothing"] = function (arg) print("did nothing") end

}
-- CurrentDir=io.popen"cd":read'*l'
-- local promptFile = io.open(string.format("%s/resources/prompt.txt", CurrentDir),"r")
-- local functionFile = io.open(string.format("%s/resources/functions.json", CurrentDir),"r")
-- if not promptFile or not functionFile then
--     print("no prompt found!!!!")
--     return
-- end
-- Prompt = promptFile:read("*a")
-- FunctionList = JSON.decode(functionFile:read("*a"))
-- io.close(promptFile)
-- io.close(functionFile)
Prompt = File.Read("LocalMods\\Gamemaster\\Lua\\resources\\prompt.txt")
FunctionList = JSON.decode(File.Read("LocalMods/Gamemaster/Lua/resources/functions.json"))

SixteenK = {
    name = "gpt-3.5-turbo-16k",
    MaxTokens = 16385
}
Turbo = {
    name = "gpt-3.5-turbo",
    MaxTokens = 4097
}
Model = Turbo
MessageBuffer = {}
FunctionLen = 2974

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

local function addToBuffer(prompt, message)
    local msg = {
        role = "user",
        content = message
    }
    table.insert( MessageBuffer , msg)
    if (string.len(prompt) + FunctionLen)/4 >= Model.MaxTokens/2 then
        if Model.name == Turbo.name then
            Model = SixteenK
        else
            print("fatal error: context too damn big")
        end
    elseif Model.name == SixteenK.name then
        Model = Turbo
    
    end
    while Helpers.TokenLength(string.len(prompt)+FunctionLen, MessageBuffer) > Model.MaxTokens do
        table.remove(MessageBuffer,1)
    end
    
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
        execute(resolve)
    end, data,"application/json",{["Authorization"] = string.format("Bearer %s", Secret.TOKEN)},nil)
end

function Upload(log)
    local message = Helpers.CleanLog(log)
    local prompt = {
        role = "system",
        content = GeneratePrompt()
    }
    addToBuffer(prompt.content, message)
    table.insert(MessageBuffer,1,prompt)
    local data = JSON.encode({
        model = Model.name,
        messages = MessageBuffer,
        functions = FunctionList
    })


    -- local out = io.open("E:\\Games\\Steam\\steamapps\\common\\Barotrauma\\LocalMods\\Gamemaster\\Lua\\resources\\UploadLog.json", "a")
    -- if not out then
    --     print("no output file found :(")
    --     return
    -- end
    -- out:write(data .. ",\n")
    -- out:close()
    sendToGPT(data)
    print(Helpers.TokenLength(string.len(prompt.content)+FunctionLen, MessageBuffer))
    table.remove(MessageBuffer,1)
end

return{
    Moderate = Moderate,
    CleanMessage = CleanMessage,
    Upload = Upload
}