local colors = {}

function colors.parse(str)
	if str:sub(1, 1) == "#" then
		str = str:sub(2, -1)
	end
	local color = {}
	if #str == 8 then
		-- str should be formatted as '80dd00ff'
		color[1] = tonumber("0x"..string.sub(str,3,4)) / 255
		color[2] = tonumber("0x"..string.sub(str,5,6)) / 255
		color[3] = tonumber("0x"..string.sub(str,7,8)) / 255
		color[4] = tonumber("0x"..string.sub(str,1,2)) / 255
	else
		-- str should be formatted as 'ff00ff'
		color[1] = tonumber("0x"..string.sub(str,1,2)) / 255
		color[2] = tonumber("0x"..string.sub(str,3,4)) / 255
		color[3] = tonumber("0x"..string.sub(str,5,6)) / 255
		-- color[4] = 1
	end
	return color
end

function colors.transparent(color, transparency)
	return {color[1], color[2], color[3], transparency}
end

local parse = colors.parse

colors.white = parse("e1e8eb")
colors.black = parse("343a40")
colors.accent = parse("ffc107")
colors.dim = parse("7952b3")

-- https://coolors.co/1c110a-e4d6a7-e9b44c-9b2915-50a2a7
colors.level = {
	background = parse("1C110A"),
	ground = parse("E4D6A7"),
	air = parse("50A2A7"),
	base = parse("06AED5"),
	enemy_base = parse("DD1C1A"),
	ready = parse("E9B44C"),
	ready_without_cost = parse("9b2915"),
	revive = parse("DD1C1A"),
	
}

return colors
