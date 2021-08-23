local colors = {}

function colors.parse(str)
	local color = {}
	if type(str) == "string" then
		if str:sub(1, 1) == "#" then
			str = str:sub(2, -1)
		end
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
	elseif type(str) == "table" then
		for i = 1, #str do
			color[#color + 1] = colors.parse(str[i])
		end
	end
	return color
end

function colors.transparent(color, transparency, retainOriginal)
	if color[4] and retainOriginal then
		return color
	else
		return {color[1], color[2], color[3], transparency}
	end
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
	elevated = parse("50A2A7"),
	base = parse("06AED5"),
	enemy_base = parse("DD1C1A"),
	ready = parse("E9B44C"),
	ready_without_cost = parse("9b2915"),
	revive = parse("DD1C1A"),
	operator_health_bar = parse("74ffa8"),
	operator_skill_bar = parse("66ccff")
}

return colors
