PATH_PREFIX_LEVELS, returnChannel = ...
local json = require("libs.json")
local lf = require("love.filesystem")
local folders = lf.getDirectoryItems("levels")
local levels = {}
for i = #folders, 1, -1 do
	if lf.isFile(folders[i]) then
		-- skip
	else
		if lf.isFile(PATH_PREFIX_LEVELS..folders[i]..'/main.json') then
			levels[#levels+1] = json.decode(lf.read(PATH_PREFIX_LEVELS..folders[i]..'/main.json'))
			if levels[#levels]['cover'] then
				levels[#levels]['cover'] = PATH_PREFIX_LEVELS..folders[i]..'/'..levels[#levels]['cover']
			end
		end
	end
end
returnChannel:push(levels)
