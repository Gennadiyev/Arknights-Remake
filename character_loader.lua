PATH_PREFIX_CHARACTERS, returnChannel = ...
local json = require("libs.json")
local lf = require("love.filesystem")

-- Load all character info
local characters = json.decode(lf.read(PATH_PREFIX_CHARACTERS.."index.json")).characters
local loaded_characters = {}
for i = 1, #characters do
	loaded_characters[characters[i]['name']] = json.decode(
        lf.read(PATH_PREFIX_CHARACTERS..characters[i]['folder'].."/main.json")
    )
    loaded_characters[characters[i]['name']]['folder'] = 
        PATH_PREFIX_CHARACTERS..characters[i]['folder']..'/'
    -- Skins path extend
    for j = 1, #loaded_characters[characters[i]['name']]['skins'] do
        loaded_characters[characters[i]['name']]['skins'][j]['file'] = 
            PATH_PREFIX_CHARACTERS..characters[i]['folder'].."/"..loaded_characters[characters[i]['name']]['skins'][j]['file']
        loaded_characters[characters[i]['name']]['skins'][j]['quad'] = 
            PATH_PREFIX_CHARACTERS..characters[i]['folder'].."/"..loaded_characters[characters[i]['name']]['skins'][j]['quad']
    end
end

returnChannel:push(loaded_characters)
