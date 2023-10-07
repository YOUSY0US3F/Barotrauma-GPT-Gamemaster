# Local Setup

## Dependencies:
- have a copy of Barotrauma
- install this mod from the workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2559634234

# Running
- place GAMEMASTER folder in steamapps/common/Barotrauma/LocalMods
- make a copy of resources/secretTemplate.lua in the Lua folder
  - name it secret.lua
  - input your OpenAI API token
- Open Barotrauma
- Host a Server
   - When making the game there will be a dropdown for "Server executable" set this to "Lua for Barotrauma"
- press F3 and feast your eyes upon the errors :)

# Refrences
- [Lua for barotrauma docs](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/getting-started/)
- [Lua for Barotrauma Repo](https://github.com/evilfactory/LuaCsForBarotrauma/tree/6b149e0498b9b634847c867ec6a211532f609c7b)

# Contributing
- If for some reason you want to contribute to this repo make a fork and put in a PR
## Basic Overview
- listener.lua uses Hooks to log whats happening in the game, and then, at a random interval will send these logs to GPT
- actions.lua is where all the different abilities the Gamemaster has are defined
- helpers.lua has a bunch of assorted utility functions
- GPT.lua handles generating the prompts for GPT and making and processing API calls to OpenAI
- json.lua is a handy little json parser that someone else made
- You can edit the prompts sent to GPT by editing the prompt files in resources
  - I did not implement a sophisticated prompt selection solution out of laziness
  - Maybe you can make that


