DEBUG_MODE = false

local colors = require("libs.colors")
local profiler
local fpsGraph
local memGraph
local dtGraph
if DEBUG_MODE then
	profiler = require("libs.profiler")
	fpsGraph = profiler:new('fps', 30, 10, 80, 50)
	memGraph = profiler:new('mem', 130, 10, 80, 50)
	dtGraph = profiler:new('custom', 230, 10, 80, 50)
end
local json = require("libs.json")
local md5 = require("libs.md5")
local easing = require("libs.easing")
local lg = require("love.graphics")
local lf = require("love.filesystem")
local lw = require("love.window")
local floor = math.floor
local min = math.min
local max = math.max
local pi = math.pi
local sin = math.sin
local cos = math.cos
local abs = math.abs
local random = math.random

PATH_PREFIX_CHARACTERS = "assets/characters/"
PATH_PREFIX_ENEMIES = "assets/enemies/"
PATH_PREFIX_DRAWABLES = "assets/drawables/"
PATH_PREFIX_LEVELS = "levels/"
PATH_PREFIX_BEHAVIORS = "assets/behaviors/"
PATH_PREFIX_FONTS = "assets/fonts/"

BEGIN_OFFSET = 2

local doctor = json.decode(lf.read("data.json"))

local enemies = json.decode(lf.read(PATH_PREFIX_ENEMIES.."index.json")).enemies

local drawables = json.decode(lf.read(PATH_PREFIX_DRAWABLES.."index.json"))
for k, v in pairs(drawables) do
	drawables[k] = lg.newImage(PATH_PREFIX_DRAWABLES..v)
end

local w, h = lg.getWidth(), lg.getHeight()
local fontTitle = lg.newFont(PATH_PREFIX_FONTS.."sf-pro-display-bold.ttf", h * 0.050)
local fontLevel = lg.newFont(PATH_PREFIX_FONTS.."sf-pro-display-bold.ttf", h * 0.110)
local fontMain = lg.newFont(PATH_PREFIX_FONTS.."blender-book.ttf", h * 0.025)
local fontBold = lg.newFont(PATH_PREFIX_FONTS.."novecento-wide-bold.ttf", h * 0.060)
local fontClean = lg.newFont(PATH_PREFIX_FONTS.."sf-pro-display.ttf", h * 0.025)
local fontBook = lg.newFont(PATH_PREFIX_FONTS.."blender-book.ttf", h * 0.027)
local fontButter = lg.newFont(PATH_PREFIX_FONTS.."butter-regular.ttf", h * 0.060)
local fontBarcode = lg.newFont(PATH_PREFIX_FONTS.."barcode.ttf", h * 0.110)

local kanbanMessage = ""
local kanban
local levels = {}
local loadingString = "Loading."
local levelLoaderChannel = love.thread.newChannel('level_loader')
local levelLoaderThread = love.thread.newThread('level_loader.lua')
levelLoaderThread:start(PATH_PREFIX_LEVELS, levelLoaderChannel)
local characterLoaderChannel = love.thread.newChannel('character_loader')
local characterLoaderThread = love.thread.newThread('character_loader.lua')
characterLoaderThread:start(PATH_PREFIX_CHARACTERS, characterLoaderChannel)
local loaded_characters
local levelSelectTime = -1
local levelSelected = -1
local levelPage = 1
local moveRegister = {}
local teamEditing = false
local imageRegister = {}
local game = false
local gameStartTime = -1
timedTasks = {}
local debugMessages = {}

function timedTasks:create(task, countdown)
	timedTasks[#timedTasks + 1] = {
		task = task,
		time = countdown
	}
end

function timedTasks:update(dt)
	for i = 1, #timedTasks do
		timedTasks[i]['time'] = timedTasks[i]['time'] - dt
		
	end
end

lg.setDefaultFilter("nearest", "nearest", 2)
lg.setBackgroundColor(colors.black)

local function round(n, deci)
  deci = 10^(deci or 0)
  return math.floor(n*deci+.5)/deci
end

local function explode(inputstr, sep)
	if not(sep) then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[#t + 1] = str
	end
	return t
end

local function getImage(path)
	if imageRegister[path] then
		return imageRegister[path], true
	else
		imageRegister[path] = lg.newImage(path)
		return imageRegister[path], false
	end
end

local function pause()
	game.pause = not(game.pause)
end

function lg.gradientrectangle(x, y, w, h, color1, color2, direction, segments, easefunc)
	local c = {lg.getColor()}
	if direction == nil then direction = "lr" end
	if easefunc == nil then easefunc = easing.linear end
	if segments == nil then segments = 10 end
	if direction == "lr" then
		dx = max(1, floor(w / segments))
		local Mx = 0
		for mx = 0, w-dx, dx do
			lg.setColor(
				easefunc(mx, color1[1], color2[1] - color1[1], w),
				easefunc(mx, color1[2], color2[2] - color1[2], w),
				easefunc(mx, color1[3], color2[3] - color1[3], w),
				easefunc(mx, color1[4], color2[4] - color1[4], w)
			)
			lg.rectangle("fill", x+mx, y, dx, h)
			Mx = mx
		end
		Mx = Mx + dx
		lg.setColor(
			easefunc(Mx, color1[1], color2[1] - color1[1], w),
			easefunc(Mx, color1[2], color2[2] - color1[2], w),
			easefunc(Mx, color1[3], color2[3] - color1[3], w),
			easefunc(Mx, color1[4], color2[4] - color1[4], w)
		)
		lg.rectangle("fill", x+Mx, y, w-Mx, h)
	elseif direction == "td" then
		dy = max(1, floor(h / segments))
		local My = 0
		for my = 0, h-dy, dy do
			lg.setColor(
				easefunc(my, color1[1], color2[1] - color1[1], h),
				easefunc(my, color1[2], color2[2] - color1[2], h),
				easefunc(my, color1[3], color2[3] - color1[3], h),
				easefunc(my, color1[4], color2[4] - color1[4], h)
			)
			lg.rectangle("fill", x, y+my, w, dy)
			My = my
		end
		My = My + dy
		lg.setColor(
			easefunc(My, color1[1], color2[1] - color1[1], h),
			easefunc(My, color1[2], color2[2] - color1[2], h),
			easefunc(My, color1[3], color2[3] - color1[3], h),
			easefunc(My, color1[4], color2[4] - color1[4], h)
		)
		lg.rectangle("fill", x, y+My, w, h-My)
	end
	lg.setColor(c)
end

function lg.drawroundedbutton(text, x, y, w, h, isFilled, faceColor, backColor)
	local r = h * 0.5
	if isFilled then
		if not(faceColor) then faceColor = colors.black end
		if not(backColor) then backColor = colors.white end
		lg.setColor(backColor)
		lg.arc("fill", "open", x+r, y+r, r, 0.5 * pi, 1.5 * pi, 30)
		lg.rectangle("fill", x+r, y, w-2*r, h)
		lg.arc("fill", "open", x+w-r, y+r, r, 1.5 * pi, 2.5 * pi, 30)
		lg.setColor(faceColor)
		lg.printf(text, x, y+r-lg.getFont():getHeight() * 0.5, w, "center")
	else
		if not(faceColor) then faceColor = colors.white end
		lg.setColor(faceColor)
		lg.arc("line", "open", x+r, y+r, r, 0.5 * pi, 1.5 * pi, 30)
		lg.line(x+r+1, y, x+w-r-1, y)
		lg.line(x+r+1, y+r*2, x+w-r-1, y+r*2)
		lg.arc("line", "open", x+w-r, y+r, r, 1.5 * pi, 2.5 * pi, 30)
		lg.printf(text, x, y+r-lg.getFont():getHeight() * 0.5, w, "center")
	end
end

local function levelSelect(id)
	id = floor(id + 0.5)
	if id > 0 and id <= #levels then
		levelSelected = id
		levelSelectTime = T
		return id, T
	else
		levelSelected = 0
		levelSelectTime = T
	end
end

local function teamEdit(team)
	teamEditing = team
end

local function levelSelectConfirm(id)
	local teamId = doctor.last_selected_team
	local team = {}
	if teamId <= #doctor.teams and teamId >= 0 then
		team = doctor.teams[teamId]
	end
	w, h = lg.getWidth(), lg.getHeight()
	teamEdit(team)
end

function love.load()
	T = 0
	RunTime = 0
	lw.setFullscreen(true)
end

local function cashTostring(cash)
	local cashStr = tostring(floor(cash + 0.5))
	for i = #cashStr - 3, 1, -3 do
		cashStr = cashStr:sub(1, i)..","..cashStr:sub(i+1,-1)
	end
	return cashStr
end

function warn(str)
	if DEBUG_MODE then
		debugMessages[#debugMessages + 1] = {
			start = T or 0,
			duration = 2,
			text = tostring(str),
			color = colors.white
		}
		return
	end
end

local function operatorPerform(operator, command)
	if not(operator.data) then
		return false
	end
	local function fail()
		warn(string.format("Cannot understand: Operator %s, command %s", operator.name, command))
	end
	-- parse command
	local c = explode(command)
	if c[1] == "atk" then
		if c[2] == "add" then
			operator.data.attack = operator.data.attack + tonumber(c[3])
		elseif c[2] == "multiply" then
			operator.data.attack = operator.data.attack * tonumber(c[3])
		else
			fail()
		end
	elseif c[1] == "cost" then
		if c[2] == "add" then
			operator.data.cost = operator.data.cost + tonumber(c[3])
		elseif c[2] == "multiply" then
			operator.data.cost = floor(operator.data.cost * tonumber(c[3]) + 0.5)
		else
			fail()
		end
	elseif c[1] == "revive_period" then
		if c[2] == "add" then
			operator.data.revive_period = operator.data.revive_period + tonumber(c[3])
		elseif c[2] == "multiply" then
			operator.data.revive_period = operator.revive_period * tonumber(c[3])
		else
			fail()
		end
	end
end

local function mapToGrid(x, y)
	if not(game) or not(game.param) then
		return 0, 0
	end
	local xr = x - game.param.xm
	local yr = y - game.param.ym
	local bs = game.param.blockSize
	return 1+floor(yr / bs), 1+floor(xr / bs)
end

local function mapFromGridCenter(y, x)
	if not(game) or not(game.param) then
		return 0, 0
	end
	local xm = game.param.xm
	local ym = game.param.ym
	local bs = game.param.blockSize
	return xm + bs * (x - 0.5), ym + bs * (y - 0.5)
end

local function getBehavior(behaviorName, entity)
	local wrapper = require(PATH_PREFIX_BEHAVIORS..behaviorName)
	wrapper(entity)
end

local function levelPerform(command)
	if not(game) then
		return
	end
	local c = explode(command)
	if c[1] == "wait" then
		if c[2] == "clear" then
			-- wait clear
			game.waitMode = "clear"
			game.waitDuration = -1
		else
			local d = tonumber(c[2])
			if not(d) then
				warn("Invalid use of 'wait' in command: "..command)
				return
			end
			game.waitMode = "time"
			game.waitDuration = d
		end
	elseif c[1] == "hint" then
		if c[2] == "path" then
			local path = {}
			for i = 3, #c, 2 do
				table.insert(path, {c[i], c[i+1]})
			end
			game.hints[#game.hints + 1] = {
				start = T,
				path = path
			}
		else
			warn("Invalid use of 'hint' in command: "..command)
			return
		end
	elseif c[1] == "summon" then
		local enemyType = c[2]
		local enemyLevel = tonumber(c[3])
		if not(enemyType) or not(enemyLevel) then
			warn("Invalid use of 'summon' in command: "..command)
			return
		end
		local e = enemies[enemyType]
		local d = e['data'][enemyLevel]
		if not(e) or not(d) then
			warn("Unknown enemy & level: "..enemyType.." Lv."..tostring(enemyLevel))
			return
		end
		d.weight = e.weight
		d.max_health = d.health
		local encountered = false
		for i = 1, #game.encounteredEnemies do
			if game.encounteredEnemies[i] == enemyType then
				encountered = true
				break
			end
		end
		if not(encountered) then
			warn("New enemy: "..e.name)
		end
		local sx, sy = false, false
		if c[4] == "from" then
			sx, sy = tonumber(c[5]), tonumber(c[6])
		end
		if not(sx) or not(sy) then
			warn("Unknown 'from' in 'summon' in command: "..command)
			return
		end
		local osx, osy = sx, sy
		-- behavior = getBehavior(e.behavior,)
		local p = {}
		local pathLength = 0
		for i = 7, #c do
			if c[i] == "to" then
				local tx, ty = tonumber(c[i+1]), tonumber(c[i+2])
				if not(tx) or not(ty) then
					warn("Destination x, y not numbers: "..command)
					return
				end
				local thisLength = math.sqrt((tx - sx) ^ 2 + (ty - sy) ^ 2)
				pathLength = pathLength + thisLength
				sx, sy = tx, ty
				p[#p + 1] = {
					type = "move",
					length = thisLength,
					destination = {tx, ty}
				}
				i = i + 2
			elseif c[i] == "wait" then
				local d = tonumber(c[i+1])
				if not(d) then
					warn("Wait duration not a number: "..command)
					return
				end
				p[#p + 1] = {
					type = "wait",
					duration = d
				}
				i = i + 1
			elseif c[i] == "invade" then
				p[#p + 1] = {
					type = "invade"
				}
			end
		end
		local enemy = {
			type = enemyType,
			color = colors.parse(e.color),
			radius = e.radius,
			name = e.name,
			level = enemyLevel,
			data = d,
			blocked = false,
			program = p,
			position = {osx, osy}
		}
		getBehavior(e.behavior, enemy)
		game.enemies[#game.enemies + 1] = enemy
	end
end

local function gameStart(level, team)
	team = team['team_members']
	for i = 1, #team do
		team[i]['color'] = loaded_characters[team[i]['name']]['color']
		for j = 1, #team[i]['color'] do
			team[i]['color'][j] = colors.parse(team[i]['color'][j])
		end
		team[i]['blocked'] = {}
		team[i]['skillCost'] = 0
		team[i]['skillActive'] = false
		team[i]['state'] = "ready"
		team[i]['position'] = {0, 0}
		team[i]['image_quad'] = getImage(loaded_characters:getCharacterSkinQuad(team[i]['name'], team[i]['skin']))
		team[i]['image_full'] = getImage(loaded_characters:getCharacterSkin(team[i]['name'], team[i]['skin']))
		team[i]['skill'] = loaded_characters[team[i]['name']]['skills'][team[i]['skill']]
		team[i]['data'] = loaded_characters[team[i]['name']]['basics']
		team[i]['range'] = loaded_characters[team[i]['name']]['range']
		team[i]['data']['max_health'] = team[i]['data']['health']
		for j = 1, #team[i]['unlocked_modifiers'] do
			local commands = loaded_characters[team[i]['name']]['modifiers'][team[i]['unlocked_modifiers'][j]]
			for k = 1, #commands do
				operatorPerform(team[i], commands[k])
			end
		end
		getBehavior(loaded_characters[team[i]['name']]['behavior'], team[i])
	end
	game = {
		timeScale = 1,
		level = level,
		team = team,
		encounteredEnemies = {},
		pause = false,
		programFinished = false,
		programPointer = 0,
		life = level.life,
		cost = level.cost_init,
		costRegenPeriod = 1 / level.cost_regen,
		costRegenTimer = 0,
		startTime = T + 3,
		waitMode = "",
		waitDuration = 0,
		hints = {},
		enemies = {},
		operators = {}
	}
	gameStartTime = T
	teamEditing = false
end

function love.draw()
	if game then
		if T < gameStartTime + 3 then
			-- Animation
			if T < gameStartTime + 1.5 then
				lg.setBackgroundColor(
					easing.outQuad(T - gameStartTime, colors.black[1], -colors.black[1], 1.5),
					easing.outQuad(T - gameStartTime, colors.black[2], -colors.black[2], 1.5),
					easing.outQuad(T - gameStartTime, colors.black[3], -colors.black[3], 1.5),
					1
				)
				lg.setColor(colors.white[1], colors.white[2], colors.white[3], easing.outQuad(T - gameStartTime, 0, 0.25, 1.5))
				lg.setFont(fontBarcode)
				lg.print(game.level.code, easing.outCubic(T - gameStartTime, w * 0.2, -0.1 * w, 1.5), h * 0.2)
				lg.setColor(colors.white[1], colors.white[2], colors.white[3], easing.outQuad(T - gameStartTime, 0, 1, 1.5))
				lg.setFont(fontLevel)
				lg.print(game.level.code, easing.outCubic(T - gameStartTime, w * 0.2, -0.1 * w, 1.5), h * 0.2)
				lg.setColor(colors.white[1], colors.white[2], colors.white[3], easing.outQuad(T - gameStartTime, 0, 0.8, 1.5))
				lg.setFont(fontTitle)
				lg.print(game.level.name:sub(1, floor(easing.outQuad(T - gameStartTime, 0, #game.level.name, 1.5))), easing.outCubic(T - gameStartTime, w * 0.2, -0.1 * w, 1.5), h * 0.33)				
			else
				lg.setBackgroundColor(
					easing.outQuad(T - gameStartTime - 1.5, 0, colors.level.background[1], 1.5),
					easing.outQuad(T - gameStartTime - 1.5, 0, colors.level.background[2], 1.5),
					easing.outQuad(T - gameStartTime - 1.5, 0, colors.level.background[3], 1.5),
					1
				)
				lg.setColor(colors.white[1], colors.white[2], colors.white[3], easing.inQuad(T - gameStartTime - 1.5, 0.25, -0.25, 1.5))
				lg.setFont(fontBarcode)
				lg.print(game.level.code, easing.outCubic(T - gameStartTime, w * 0.2, -0.1 * w, 1.5), h * 0.2)
				lg.setColor(colors.white[1], colors.white[2], colors.white[3], easing.inQuad(T - gameStartTime - 1.5, 1, -1, 1.5))
				lg.setFont(fontLevel)
				lg.print(game.level.code, easing.inCubic(T - gameStartTime - 1.5, w * 0.1, -0.1 * w, 1.5), h * 0.2)
				-- lg.setColor(colors.white[1], colors.white[2], colors.white[3], easing.outQuad(T - gameStartTime - 1.5, 0.8, -0.8, 1.5))
				if math.random(1, 100) <= (T - gameStartTime - 1.5) / 1.5 * 100 then
					lg.setColor(0, 0, 0, 0)
				else
					lg.setColor(colors.white[1], colors.white[2], colors.white[3], easing.inQuad(T - gameStartTime - 1.5, 0.8, -0.8, 1.5))
				end
				lg.setFont(fontTitle)
				lg.print(game.level.name:sub(floor(easing.inQuad(T - gameStartTime - 1.5, 0, #game.level.name, 1.5)), -1), easing.outCubic(T - gameStartTime, w * 0.2, -0.1 * w, 1.5), h * 0.33)
			end
		else
			-- If param not yet calculated, make a round of computation
			if not(game['param']) then
				local p = min(w * 0.9 / game.level.dimension[1], h * 0.9 / game.level.dimension[2])
				game.param = {
					blockSize = p,
					blockMargin = p * 0.1,
					xm = w * 0.5 - p * game.level.dimension[1] * 0.5,
					ym = h * 0.5 - p * game.level.dimension[2] * 0.5
				}
			end
			local map = game.level.map
			for y = 1, #map do
				for x = 1, #map[1] do
					if map[y][x] ~= 0 then
						if map[y][x] == 1 then -- ground path
							lg.setLineWidth(2)
							lg.setColor(colors.level.ground)
							lg.rectangle(
								"line",
								game.param.xm + (x-1) * game.param.blockSize + game.param.blockMargin * 0.5,
								game.param.ym + (y-1) * game.param.blockSize + game.param.blockMargin * 0.5,
								game.param.blockSize - game.param.blockMargin,
								game.param.blockSize - game.param.blockMargin
							)
						elseif map[y][x] == 2 then -- elevated solid
							lg.setLineWidth(2)
							lg.setColor(colors.level.elevated)
							lg.rectangle(
								"line",
								game.param.xm + (x-1) * game.param.blockSize + game.param.blockMargin * 0.5,
								game.param.ym + (y-1) * game.param.blockSize + game.param.blockMargin * 0.5,
								game.param.blockSize - game.param.blockMargin,
								game.param.blockSize - game.param.blockMargin
							)
						elseif map[y][x] == 10 then -- enemy base
							lg.setLineWidth(4)
							lg.setColor(colors.transparent(colors.level.enemy_base, 0.2))
							lg.rectangle(
								"fill",
								game.param.xm + (x-1) * game.param.blockSize + game.param.blockMargin * 0.5,
								game.param.ym + (y-1) * game.param.blockSize + game.param.blockMargin * 0.5,
								game.param.blockSize - game.param.blockMargin,
								game.param.blockSize - game.param.blockMargin
							)
							lg.setColor(colors.level.enemy_base)
							lg.rectangle(
								"line",
								game.param.xm + (x-1) * game.param.blockSize + game.param.blockMargin * 0.5,
								game.param.ym + (y-1) * game.param.blockSize + game.param.blockMargin * 0.5,
								game.param.blockSize - game.param.blockMargin,
								game.param.blockSize - game.param.blockMargin
							)
						elseif map[y][x] == 11 then -- base
							lg.setLineWidth(4)
							lg.setColor(colors.transparent(colors.level.base, 0.2))
							lg.rectangle(
								"fill",
								game.param.xm + (x-1) * game.param.blockSize + game.param.blockMargin * 0.5,
								game.param.ym + (y-1) * game.param.blockSize + game.param.blockMargin * 0.5,
								game.param.blockSize - game.param.blockMargin,
								game.param.blockSize - game.param.blockMargin
							)
							lg.setColor(colors.level.base)
							lg.rectangle(
								"line",
								game.param.xm + (x-1) * game.param.blockSize + game.param.blockMargin * 0.5,
								game.param.ym + (y-1) * game.param.blockSize + game.param.blockMargin * 0.5,
								game.param.blockSize - game.param.blockMargin,
								game.param.blockSize - game.param.blockMargin
							)
						end
					end
				end
			end
			local cardWidth = floor(w / 12)
			local cardHeight = cardWidth / 18 * 35
			if game.focusedOperator then
				if game.focusedOperatorOnPlayfield then
					lg.setColor(1, 1, 1, max(0.2, (0.1 + game.focusedOperatorOnPlayfieldTime - RunTime) * 10))
					local s = min(w * 0.5 / game.focusedOperator['image_full']:getWidth(), h / game.focusedOperator['image_full']:getHeight()) * 1.3
					lg.draw(game.focusedOperator['image_full'], -w * 0.3 + easing.outCubic(min(0.2, RunTime - game.focusedOperatorOnPlayfieldTime), 0, -w*0.05, 0.2) + easing.outCubic(min(0.14, RunTime - game.lastOperatorFocus), 0, w * 0.1, 0.14), h * 0.6, 0, s, s, 0, game.focusedOperator['image_full']:getHeight() * 0.5)
				else
					lg.gradientrectangle(0, 0, w * 0.3, h, colors.transparent(colors.white, 0.4), colors.transparent(colors.white, 0), 'lr', 150, easing.outQuad)
					lg.setColor(1, 1, 1, 1)
					local s = min(w * 0.5 / game.focusedOperator['image_full']:getWidth(), h / game.focusedOperator['image_full']:getHeight()) * 1.3
					lg.draw(game.focusedOperator['image_full'], -w * 0.3 + easing.outCubic(min(0.14, RunTime - game.lastOperatorFocus), 0, w * 0.1, 0.14), h * 0.6, 0, s, s, 0, game.focusedOperator['image_full']:getHeight() * 0.5)
				end
				if game.focusedOperatorPosition then
					local ox, oy = game.focusedOperatorPosition[1], game.focusedOperatorPosition[2]
					local lx, ly = mapFromGridCenter(ox, oy)
					local hbs = game.param.blockSize * 0.5
					local bm = game.param.blockMargin
					if game.waitForDirection then
						local r = hbs * 3 + 20 * sin(RunTime * 2)
						lg.setLineWidth(4)
						lg.setColor(colors.transparent(game.focusedOperator.color[1]), 1)
						lg.line(lx - r, ly, lx, ly - r)
						lg.line(lx, ly - r, lx + r, ly)
						lg.line(lx + r, ly, lx, ly + r)
						lg.line(lx, ly + r, lx - r, ly)
						local range = game.focusedOperator['range']
						local function light(bx, by)
							local cx, cy = mapFromGridCenter(bx, by)
							lg.setColor(colors.transparent(colors.white, 0.5))
							lg.rectangle("fill", cx - hbs, cy - hbs, hbs * 2, hbs * 2)
						end
						for i = 1, #range do
							if game.focusedOperatorDirection == "right" then
								light(range[i][1] + ox, range[i][2] + oy)
							elseif game.focusedOperatorDirection == "left" then
								light(range[i][1] + ox, -range[i][2] + oy)
							elseif game.focusedOperatorDirection == "up" then
								light(-range[i][2] + ox, range[i][1] + oy)
							elseif game.focusedOperatorDirection == "down" then
								light(range[i][2] + ox, range[i][1] + oy)
							end
						end
					else
						lg.setLineWidth(2)
						lg.setColor(colors.white)
						lg.line(lx, 0, lx, ly - hbs - bm)
						lg.line(lx, ly + hbs + bm, lx, h)
						lg.line(0, ly, lx - hbs - bm, ly)
						lg.line(lx + hbs + bm, ly, w, ly)
					end
					if game.focusedOperatorDirection then
						if game.focusedOperatorDirection == "left" then
							lg.gradientrectangle(lx - hbs * 0.8, ly - hbs * 0.8, hbs * 1.6, hbs * 1.6, colors.transparent(game.focusedOperator.color[1],1), colors.transparent(game.focusedOperator.color[2],1), 'lr', hbs * 1.6, easing.linear)
						elseif game.focusedOperatorDirection == "right" then
							lg.gradientrectangle(lx - hbs * 0.8, ly - hbs * 0.8, hbs * 1.6, hbs * 1.6, colors.transparent(game.focusedOperator.color[2],1), colors.transparent(game.focusedOperator.color[1],1), 'lr', hbs * 1.6, easing.linear)
						elseif game.focusedOperatorDirection == "up" then
							lg.gradientrectangle(lx - hbs * 0.8, ly - hbs * 0.8, hbs * 1.6, hbs * 1.6, colors.transparent(game.focusedOperator.color[1],1), colors.transparent(game.focusedOperator.color[2],1), 'td', hbs * 1.6, easing.linear)
						elseif game.focusedOperatorDirection == "down" then
							lg.gradientrectangle(lx - hbs * 0.8, ly - hbs * 0.8, hbs * 1.6, hbs * 1.6, colors.transparent(game.focusedOperator.color[2],1), colors.transparent(game.focusedOperator.color[1],1), 'td', hbs * 1.6, easing.linear)
						end
					end
				end
			end
			lg.gradientrectangle(0, h - cardHeight, w, cardHeight, colors.transparent(colors.black, 0), colors.transparent(colors.black, 1), 'td', cardHeight * 0.5, easing.inCubic)
			lg.setFont(fontBook)
			for i = 1, #game.team do
				if game.team[i]['state'] == "ready" then
					if game['cost'] >= game.team[i]['data']['cost'] then
						-- READY and CAN_BE_APPOINTED
						local d = game.team[i]['image_quad']
						lg.gradientrectangle(
							cardWidth * (i-1), h - cardHeight, cardWidth, cardHeight,
							{colors.level.ready[1], colors.level.ready[2], colors.level.ready[3], 0.0},
							{colors.level.ready[1], colors.level.ready[2], colors.level.ready[3], 1.0},
							"td",
							50
						)
						lg.setColor(1, 1, 1, 1)
						lg.print(tostring(game.team[i]['data']['cost']), cardWidth * (i-1) + cardHeight * 0.12, h - cardHeight)
						lg.draw(
							d,
							cardWidth * (i-1),
							h,
							0,
							cardWidth / d:getWidth(),
							nil,
							0,
							d:getHeight()
						)
						lg.draw(drawables.cost, cardWidth * (i-1), h - cardHeight, 0, cardHeight * 0.1 / drawables.cost:getWidth(), nil)
					else
						local d = game.team[i]['image_quad']
						local costRate = game.cost / game.team[i]['data']['cost']
						lg.gradientrectangle(
							cardWidth * (i-1), h - cardHeight, cardWidth, cardHeight,
							colors.transparent(colors.white, 0),
							colors.transparent(colors.white, costRate),
							"td",
							50,
							easing.inQuad
						)
						lg.setColor(0.5, 0.5, 0.5, 1)
						lg.print(tostring(game.team[i]['data']['cost']), cardWidth * (i-1) + cardHeight * 0.12, h - cardHeight)
						lg.draw(
							d,
							cardWidth * (i-1),
							h,
							0,
							cardWidth / d:getWidth(),
							nil,
							0,
							d:getHeight()
						)
						lg.draw(drawables.cost, cardWidth * (i-1), h - cardHeight, 0, cardHeight * 0.1 / drawables.cost:getWidth(), nil)
					end
				elseif game.team[i]['state'] == "revive" then
					local d = game.team[i]['image_quad']
					lg.gradientrectangle(
						cardWidth * (i-1), h - easing.linear(game.team[i]['reviveDuration'], 0, cardHeight, game.team[i].data.revive_period), cardWidth, cardHeight,
						{colors.level.revive[1], colors.level.revive[2], colors.level.revive[3], 0.0},
						{colors.level.revive[1], colors.level.revive[2], colors.level.revive[3], 1},
						"td",
						50
					)
					lg.setColor(0.4, 0.4, 0.4, 0.4)
					lg.print(tostring(game.team[i]['data']['cost']), cardWidth * (i-1) + cardHeight * 0.12, h - cardHeight)
					lg.draw(
						d,
						cardWidth * (i-1),
						h,
						0,
						cardWidth / d:getWidth(),
						nil,
						0,
						d:getHeight()
					)
					lg.draw(drawables.cost, cardWidth * (i-1), h - cardHeight, 0, cardHeight * 0.1 / drawables.cost:getWidth(), nil)
					lg.setColor(colors.white)
					lg.setFont(fontBook)
					lg.printf(string.format("%.1f", game.team[i]['reviveDuration']), cardWidth * (i-1), h - cardHeight * 0.5 - lg:getFont():getHeight() * 0.5, cardWidth, "center")
					lg.setLineWidth(4)
					lg.arc("line", "open", cardWidth * (i-0.5), h - cardHeight * 0.5, cardWidth * 0.3, -pi * 0.5, easing.linear(game.team[i]['reviveDuration'], -pi*0.5, pi*2, game.team[i]['data']['revive_period']))
					-- lg.setColor(colors.transparent(colors.level.revive, 0.5))
					-- lg.rectangle("fill", cardWidth * (i-1), easing.linear(game.team[i]['reviveDuration'], h - cardHeight, cardHeight, game.team[i]['data']['revive_period']), cardWidth, cardHeight)
				elseif game.team[i]['state'] == "battle" then
					local ox, oy = game.team[i]['position'][1], game.team[i]['position'][2]
					local lx, ly = mapFromGridCenter(ox, oy)
					local hbs = game.param.blockSize * 0.5
					local bm = game.param.blockMargin
					if game.team[i]['direction'] == "left" then
						lg.gradientrectangle(lx - hbs * 0.9 + 2, ly - hbs * 0.9 + 2, hbs * 1.8 - 4, hbs * 1.8 - 4, colors.transparent(game.team[i].color[1],1), colors.transparent(game.team[i].color[2],1), 'lr', hbs * 1.8 - 4, easing.linear)
					elseif game.team[i]['direction'] == "right" then
						lg.gradientrectangle(lx - hbs * 0.9 + 2, ly - hbs * 0.9 + 2, hbs * 1.8 - 4, hbs * 1.8 - 4, colors.transparent(game.team[i].color[2],1), colors.transparent(game.team[i].color[1],1), 'lr', hbs * 1.8 - 4, easing.linear)
					elseif game.team[i]['direction'] == "up" then
						lg.gradientrectangle(lx - hbs * 0.9 + 2, ly - hbs * 0.9 + 2, hbs * 1.8 - 4, hbs * 1.8 - 4, colors.transparent(game.team[i].color[1],1), colors.transparent(game.team[i].color[2],1), 'td', hbs * 1.8 - 4, easing.linear)
					elseif game.team[i]['direction'] == "down" then
						lg.gradientrectangle(lx - hbs * 0.9 + 2, ly - hbs * 0.9 + 2, hbs * 1.8 - 4, hbs * 1.8 - 4, colors.transparent(game.team[i].color[2],1), colors.transparent(game.team[i].color[1],1), 'td', hbs * 1.8 - 4, easing.linear)
					end
					lg.setColor(colors.level.operator_health_bar)
					lg.setLineWidth(3)
					lg.line(lx - hbs * 0.9 + 2, ly + hbs * 0.9 - 3, easing.linear(game.team[i]['data']['health'], lx - hbs * 0.9 + 2, hbs * 1.8 - 4, game.team[i]['data']['max_health']), ly + hbs * 0.9 - 3)
					if game.team[i].skillCost >= game.team[i].skill.cost then
						lg.setColor(colors.transparent(colors.level.operator_skill_bar, math.random()))
						lg.line(lx - hbs * 0.9 + 2, ly + hbs * 0.9 - 6, easing.linear(game.team[i]['skillCost'], lx - hbs * 0.9 + 2, hbs * 1.8 - 4, game.team[i]['skill']['cost']), ly + hbs * 0.9 - 6)
					elseif game.team[i].skillActive then
						lg.setColor(colors.level.operator_skill_bar)
						lg.line(lx - hbs * 0.9 + 2, ly + hbs * 0.9 - 6, easing.linear(game.team[i]['skillActive'], lx - hbs * 0.9 + 2, hbs * 1.8 - 4, game.team[i]['skill']['duration']), ly + hbs * 0.9 - 6)
					else
						lg.setColor(colors.level.operator_skill_bar)
						lg.line(lx - hbs * 0.9 + 2, ly + hbs * 0.9 - 6, easing.linear(game.team[i]['skillCost'], lx - hbs * 0.9 + 2, hbs * 1.8 - 4, game.team[i]['skill']['cost']), ly + hbs * 0.9 - 6)
					end
				end
			end
			for i = 1, #game.enemies do
				local e = game.enemies[i]
				local dx, dy = mapFromGridCenter(e.position[1], e.position[2])
				lg.setColor(colors.transparent(e.color[1], 0.7))
				lg.circle("fill", dx, dy, e.radius * game.param.blockSize)
				lg.setColor(colors.transparent(e.color[2], 1))
				lg.setLineWidth(3)
				lg.arc("line", "open", dx, dy, e.radius * game.param.blockSize, 0, easing.linear(e.data.health, 0, 2 * pi, e.data.max_health))
			end
			
			lg.setFont(fontBook)
			lg.gradientrectangle(0, 0, w, lg:getFont():getHeight() * 2, colors.transparent(colors.black, 1), colors.transparent(colors.black, 0), 'td', 40, easing.outCubic)
			
			lg.setColor(1, 1, 1, 1)
			--function lg.gradientrectangle(x, y, w, h, color1, color2, direction, segments, easefunc)
			lg.setFont(fontButter)
			local fh = lg:getFont():getHeight()
			lg.gradientrectangle(0, h - cardHeight - fh * 1.4, cardWidth * 2, fh * 1.4, colors.transparent(colors.black, 1), colors.transparent(colors.black, 0), "lr", 50, easing.inCubic)
			lg.setLineWidth(2)
			lg.line(0, h - cardHeight, easing.linear(game.costRegenTimer / game.costRegenPeriod, 0, cardWidth * 2, 1), h - cardHeight)
			lg.draw(drawables.cost, fh * 0.75, h - cardHeight - fh * 0.7, 0, fh / drawables.cost:getHeight() * 0.8, nil, drawables.cost:getWidth() * 0.5, drawables.cost:getHeight() * 0.5)
			lg.printf({colors.white, tostring(game.cost)}, floor(fh * 1.5), floor(h - cardHeight - fh * 1.2), cardWidth * 2, "left")
		end
	elseif teamEditing then
		lg.setFont(fontTitle)
		lg.setColor(1, 1, 1, 1)
		lg.printf({colors.white, "Preparation: ", colors.accent, teamEditing['team_name']}, w * 0.09, h * 0.14 - fontTitle:getHeight() * 0.5, w * 0.91, "left")
		local hereX, hereY = floor(w * 0.12), floor(h * 0.225)
		local cardWidth = floor(h * 0.15)
		local cardMargin = floor(w * 0.024)
		local cardHeight = floor(h * 0.32)
		local teamMembers = teamEditing['team_members']
		for i = 1, 12 do
			lg.setColor(colors.white)
			if i % 2 == 1 then
				lg.gradientrectangle(hereX, hereY, cardWidth, cardHeight,
					{colors.white[1], colors.white[2], colors.white[3], 0.0},
					{colors.white[1], colors.white[2], colors.white[3], 0.6},
					'td', 100, easing.outSine)
				if teamMembers[i] then
					lg.setColor(1, 1, 1, 1)
					local d = getImage(loaded_characters:getCharacterSkinQuad(
						teamMembers[i]['name'],
						teamMembers[i]['skin']
					))
					lg.draw(
						d,
						hereX,
						hereY + cardHeight,
						0,
						cardWidth / d:getWidth(),
						nil,
						0,
						d:getHeight()
					)
				end
				-- lg.setColor(colors.white)
				-- lg.rectangle("line", hereX, hereY, cardWidth, cardHeight)
				hereY = hereY + cardHeight + cardMargin
			else
				lg.gradientrectangle(hereX, hereY, cardWidth, cardHeight,
					{colors.white[1], colors.white[2], colors.white[3], 0.0},
					{colors.white[1], colors.white[2], colors.white[3], 0.6},
					'td', 100, easing.outSine)
				if teamMembers[i] then
					lg.setColor(1, 1, 1, 1)
					local d = getImage(loaded_characters:getCharacterSkinQuad(
						teamMembers[i]['name'],
						teamMembers[i]['skin']
					))
					lg.draw(
						d,
						hereX,
						hereY + cardHeight,
						0,
						cardWidth / d:getWidth(),
						nil,
						0,
						d:getHeight()
					)
				end
				-- lg.setColor(colors.white)
				-- lg.rectangle("line", hereX, hereY, cardWidth, cardHeight)
				hereX = hereX + cardWidth + cardMargin
				hereY = hereY - cardHeight - cardMargin
			end
		end
		lg.setColor({colors.accent[1], colors.accent[2], colors.accent[3], 1})
		lg.circle("fill", w * 1.3, h * 0.5, w * 0.4, 100)
		lg.setColor(colors.black)
		lg.draw(drawables.play, w * 0.95, h * 0.5, 0, w * 0.06 / drawables.play:getWidth(), nil, drawables.play:getWidth() * 0.5, drawables.play:getHeight() * 0.5)
		-- lg.setFont(fontClean)
		-- lg.drawroundedbutton("Edit Team", w * 0.09, h * 0.27 - fontMain:getHeight() * 0.5, w * 0.13, fontMain:getHeight() * 1.8, false, colors.white) 
	else
		lg.setFont(fontTitle)
		lg.setColor(1, 1, 1, 1)
		lg.printf({colors.white, "Welcome, ", colors.accent, "Dr. ", doctor.name}, w * 0.09, h * 0.14 - fontTitle:getHeight() * 0.5, w * 0.91, "left")
		lg.setFont(fontClean)
		lg.drawroundedbutton("Administrator", w * 0.09, h * 0.22 - fontMain:getHeight() * 0.5, w * 0.13, fontMain:getHeight() * 1.8, true, colors.black, colors.accent) 
		lg.setLineWidth(2)
		lg.drawroundedbutton("Cash: "..cashTostring(doctor.cash), w * 0.23, h * 0.22 - fontMain:getHeight() * 0.5, w * 0.15, fontMain:getHeight() * 1.8, false, colors.white)
		if loadingString then
			lg.printf({colors.white, loadingString}, w * 0.09, h * 0.35 - fontMain:getHeight() * 0.5, w * 0.91, "left")
		else
			-- Display Levels
			local hereX, hereY = w * 0.09, h * 0.4
			lg.setFont(fontBold)
			local cardHeight = h * 0.15
			-- lg.rectangle("line", hereX, hereY, w * 0.46, cardHeight)
			local levelLoadedDuration = min(0.5, T - levelLoadedTime)
			for i = 1, #levels do
				if levelSelected and i == levelSelected then
					local selectedDuration = T - levelSelectTime
					selectedDuration = min(0.5, selectedDuration)
					lg.setColor(colors.accent)
					lg.rectangle("fill", hereX, hereY + cardHeight * easing.outCubic(selectedDuration, 0.3, -0.2, 0.5), 3, cardHeight * easing.outCubic(selectedDuration, 0.4, 0.1, 0.5))
					lg.gradientrectangle(
						hereX + 3,
						hereY + cardHeight * easing.outCubic(selectedDuration, 0.3, -0.2, 0.5),
						easing.outCubic(selectedDuration, 0, w * 0.3, 0.5),
						cardHeight * easing.outCubic(selectedDuration, 0.4, 0.1, 0.5),
						{colors.white[1], colors.white[2], colors.white[3], easing.outCubic(selectedDuration, 0.2, 0.4, 0.5)},
						{colors.white[1], colors.white[2], colors.white[3], 0}, 'lr', 80
					)
					lg.setColor(1, 1, 1, easing.outCubic(selectedDuration, 0, 1, 0.5))
					lg.draw(drawables.play, hereX + w * 0.36, hereY + cardHeight * 0.5, 0, cardHeight * 0.6 / drawables.play:getHeight(), nil, easing.outCubic(selectedDuration, 1.5*drawables.play:getWidth(), -0.5*drawables.play:getWidth(), 0.5), drawables.play:getHeight() * 0.5)
					lg.setColor(1, 1, 1, 1)
					lg.printf({colors.dim, levels[i]['code']:sub(1, easing.outCubic(levelLoadedDuration, 1, #levels[i]['code'], 0.5))}, hereX + 21, hereY + cardHeight * easing.outCubic(selectedDuration, 0.5, -0.15, 0.5) - fontBold:getHeight() * 0.5 + 3, w * 0.46, "left")
					lg.printf({colors.white, levels[i]['code']:sub(1, easing.outCubic(levelLoadedDuration, 1, #levels[i]['code'], 0.5))}, hereX + 18, hereY + cardHeight * easing.outCubic(selectedDuration, 0.5, -0.15, 0.5) - fontBold:getHeight() * 0.5, w * 0.46, "left")
					lg.setFont(fontBook)
					lg.printf({colors.white, levels[i]['name']:sub(1, easing.outCubic(selectedDuration, 1, #levels[i]['name'], 0.5)), ' - ', colors.accent, levels[i]['author']:sub(1, easing.outCubic(selectedDuration, 1, #levels[i]['author'], 0.5))}, hereX + 18,  hereY + cardHeight * easing.outCubic(selectedDuration, 0.5, -0.15, 0.5) + fontBold:getHeight() * 0.7, w * 0.46, "left")
				else
					if random(0, 100) <= 175 * levelLoadedDuration then
						lg.setColor(colors.dim)
						lg.rectangle("fill", hereX + 3, hereY + cardHeight * 0.3 + 3, 3, cardHeight * 0.4)
						lg.setColor(colors.white)
						lg.rectangle("fill", hereX, hereY + cardHeight * 0.3, 3, cardHeight * 0.4)
					end
					lg.setColor(1, 1, 1, 1)
					lg.setFont(fontBold)
					lg.printf({colors.dim, levels[i]['code']:sub(1, easing.outCubic(levelLoadedDuration, 1, #levels[i]['code'], 0.5))}, hereX + 21, hereY + cardHeight * 0.5 - fontBold:getHeight() * 0.5 + 3, w * 0.46, "left")
					lg.printf({colors.white, levels[i]['code']:sub(1, easing.outCubic(levelLoadedDuration, 1, #levels[i]['code'], 0.5))}, hereX + 18, hereY + cardHeight * 0.5 - fontBold:getHeight() * 0.5, w * 0.46, "left")
				end
				hereY = hereY + cardHeight
			end
		end
		lg.setColor(colors.white)
		lg.circle("fill", w * 1.2, h * 0.5, w * 0.6, 100)
		lg.setColor(colors.black)
		lg.circle("fill", w * 1.2, h * 0.5, w * 0.3, 100)
		if kanban then
			lg.setColor(1, 1, 1, 1)
			lg.draw(kanban, w*0.8 + doctor['kanban']['offset_x'], h*0.5 + doctor['kanban']['offset_y'], 0, min(w*0.3/kanban:getWidth(), h/kanban:getHeight()) * 2, nil, kanban:getWidth() * 0.5, kanban:getHeight() * 0.5)
			if kanbanMessage then
				lg.setFont(fontMain)
				lg.gradientrectangle(w * 0.6, h * 0.7, w * 0.33, h * 0.2, {0, 0, 0, 0.8}, {0, 0, 0, 0.4}, 'lr', 100)
				lg.setLineWidth(2)
				lg.setColor(1, 1, 1, 0.4)
				lg.rectangle("line", w * 0.6, h * 0.7, w * 0.33, h * 0.2)
				lg.setColor(1, 1, 1, 1)
				lg.printf({colors.accent, doctor['kanban']['name'], ": ", {1, 1, 1, 1}, kanbanMessage}, w * 0.62, h * 0.72, w * 0.29, "left")
			end
		end
		-- lg.setFont(fontBold)
		-- lg.setColor(colors.dim)
		-- lg.printf(doctor['kanban']['name'], w, 0, h, "left", pi*0.5)
	end
	for i = 1, #debugMessages do
		lg.setFont(fontClean)
		lg.setColor(colors.transparent(debugMessages[i]['color'], easing.inQuad(T - debugMessages[i]['start'], 1, -1, debugMessages[i]['duration'])))
		lg.printf(debugMessages[i]['text'], 14, lg.getFont():getHeight() * 1.4 * (i-1) + 14, w-28, "left")
	end
	if DEBUG_MODE then
		fpsGraph:draw()
		memGraph:draw()
		dtGraph:draw()
	end
end

warn("Dev Preview")

function love.update(dt)
	if DEBUG_MODE then
		fpsGraph:update(dt)
		memGraph:update(dt)
		dtGraph:update(dt, math.floor(dt * 1000))
		dtGraph.label = 'dt: ' ..  round(dt, 4)
	end
	RunTime = RunTime + dt
	if game then
		dt = dt * game.timeScale
	end
	T = T + dt
	for i = #debugMessages, 1, -1 do
		if debugMessages[i]['start'] < T - debugMessages[i]['duration'] then
			table.remove(debugMessages, i)
		end
	end
	if game and T > game.startTime + BEGIN_OFFSET and not(game.pause) then
		game.time = T
		if game.life <= 0 then
			warn("You lost!")
		end
		-- Cost regen
		game.costRegenTimer = game.costRegenTimer + dt
		if game.costRegenTimer > game.costRegenPeriod then
			game.cost = game.cost + 1
			game.costRegenTimer = 0
		end
		-- Update to all enemies
		for i = #game.enemies, 1, -1 do
			game.enemies[i]:update(game, dt)
		end
		-- Update to all team members
		for i = 1, #game.team do
			game.team[i]:update(game, dt)
		end
		-- See if all program ended
		if not(game.programFinished) then
			if game.programPointer < #game.level.program then
				-- Not yet finished
				if game.waitMode == "" then
					-- not waiting
					-- run one line
					game.programPointer = game.programPointer + 1
					local command = game.level.program[game.programPointer]
					warn(string.format("Called line %d: %s", game.programPointer, command))
					levelPerform(command)
				elseif game.waitMode == "clear" then
					if not(game.enemies) or #game.enemies == 0 then
						-- wait time ended
						game.waitMode = ""
						game.waitDuration = 0
					end
				elseif game.waitMode == "time" then
					if game.waitDuration > 0 then
						-- continue wait
						game.waitDuration = game.waitDuration - dt
					else
						-- wait time ended
						game.waitDuration = 0
						game.waitMode = ""
					end

				end
			else
				game.programFinished = true
			end
		end
	end
	if loadingString and floor(T-dt) ~= floor(T) then
		loadingString = loadingString .. "."
		if #loadingString > 10 then
			loadingString = "Loading."
		end
	end
	local returnedLevels = levelLoaderChannel:peek()
	if returnedLevels then
		loadingString = nil
		levels = returnedLevels
		levelLoaderChannel:pop()
		levelLoadedTime = T
		for i = 1, #levels do
			levels[i]['cover_love_image'] = lg.newImage(levels[i]['cover'])
		end
	end
	local returnedCharacters = characterLoaderChannel:peek()
	if returnedCharacters then
		loaded_characters = returnedCharacters
		
		function loaded_characters:getCharacter(characterName)
			return self[characterName]
		end
		
		function loaded_characters:getCharacterList()
			local l = {}
			for k, v in pairs(self) do
			   l[#l+1] = k 
			end
		end
		
		function loaded_characters:getCharacterSkin(characterName, skinName)
			local c = self:getCharacter(characterName)
			for i = 1, #c['skins'] do
				if c['skins'][i]['name'] == skinName then
					return c['skins'][i]['file']
				end
			end
			return false
		end
		
		function loaded_characters:getCharacterSkinQuad(characterName, skinName)
			local c = self:getCharacter(characterName)
			for i = 1, #c['skins'] do
				if c['skins'][i]['name'] == skinName then
					return c['skins'][i]['quad']
				end
			end
			return false
		end
		
		function loaded_characters:getRandomMessage(characterName)
			local c = self:getCharacter(characterName)
			local i = c['messages']['interactions']
			return i[math.random(1, #i)]
		end
		
		function loaded_characters:getGreetingMessage(characterName)
			local c = self:getCharacter(characterName)
			return c['messages']['greeting']
		end
		--

		characterLoaderChannel:pop()
		-- Load kanban
		local skins = loaded_characters[doctor['kanban']['name']]['skins']
		for i = 1, #skins do
			if skins[i]['name'] == doctor['kanban']['skin'] then
				kanban = getImage(skins[i]['file'])
			end
		end
		if not(kanban) then
			kanban = getImage(skins[1]['file'])
		end
		kanbanMessage = loaded_characters:getGreetingMessage(doctor['kanban']['name'])
	end
end

function love.touchpressed(id, x, y, dx, dy)
	if game then
		local cardWidth = floor(w / 12)
		local cardHeight = cardWidth / 18 * 35
		if game.waitForDirection then
			local mfgx, mfgy = mapFromGridCenter(game.focusedOperatorPosition[1], game.focusedOperatorPosition[2])
			if abs(x - mfgx) + abs(y - mfgy) < game.param.blockSize * 2 then
				moveRegister[#moveRegister + 1] = {
					id = id,
					onMoved = function(id, x, y, dx, dy)
						if abs(x - mfgx) + abs(y - mfgy) > game.param.blockSize then
							if abs(x - mfgx) > abs(y - mfgy) then
								if x > mfgx then
									game.focusedOperatorDirection = "right"
								else
									game.focusedOperatorDirection = "left"
								end
							else
								if y > mfgy then
									game.focusedOperatorDirection = "down"
								else
									game.focusedOperatorDirection = "up"
								end
							end
						else
							game.focusedOperatorDirection = false
						end
					end,
					onReleased = function(id, x, y, dx, dy)
						if game.focusedOperatorDirection then
							game.focusedOperator['state'] = "battle"
							game.focusedOperator['direction'] = game.focusedOperatorDirection
							game.focusedOperator['position'] = game.focusedOperatorPosition
							game.cost = game.cost - game.focusedOperator['data']['cost']
							game.waitForDirection = false
							game.timeScale = game.timeScaleLast
							game.focusedOperator = false
							game.focusedOperatorOnPlayfieldTime = 0
							game.focusedOperatorOnPlayfield = false
							game.focusedOperatorPosition = false
							game.waitForDirection =false
						end
					end
				}
			else
				game.waitForDirection = false
				game.timeScale = game.timeScaleLast
				game.focusedOperator = false
				game.focusedOperatorOnPlayfieldTime = 0
				game.focusedOperatorOnPlayfield = false
				game.focusedOperatorPosition = false
				game.waitForDirection =false
			end
		elseif y > h - cardHeight and not(game.focusedOperator) then
			-- Selecting heros
			local heroSelected = floor(x / cardWidth) + 1
			if heroSelected <= #game.team then
				warn("Selecting hero "..game.team[heroSelected]['name'])
				game.waitForDirection = false
				game.focusedOperator = game.team[heroSelected]
				game.focusedOperatorOnPlayfield = false
				game.focusedOperatorOnPlayfieldTime = RunTime
				game.lastOperatorFocus = RunTime
				game.timeScaleLast = game.timeScale
				game.timeScale = 0.2
				moveRegister[#moveRegister + 1] = {
					id = id,
					onMoved = function(id, cx, cy, dx, dy)
						if abs(cx - x) + abs(cy - y) > cardWidth and cy < h - cardHeight * 0.5 and game.cost >= game.focusedOperator['data']['cost'] then
							if not(game.focusedOperatorOnPlayfield) then
								game.focusedOperatorOnPlayfield = true
								game.focusedOperatorOnPlayfieldTime = RunTime
							end
							local mtgx, mtgy = mapToGrid(cx, cy)
							game.focusedOperatorPosition = {mtgx, mtgy}
						else
							if game.focusedOperatorOnPlayfield then
								game.focusedOperatorOnPlayfield = false
								game.focusedOperatorOnPlayfieldTime = RunTime
							end
							game.focusedOperatorPosition = false
						end
					end,
					onReleased = function(id, x, y, dx, dy)
						if game.focusedOperatorOnPlayfield then
							game.waitForDirection = true
						else
							game.waitForDirection = false
							game.timeScale = game.timeScaleLast
							game.focusedOperator = false
							game.focusedOperatorOnPlayfieldTime = 0
							game.focusedOperatorOnPlayfield = false
							game.focusedOperatorPosition = false
						end
					end
				}
			end
		else
			if game.focusedOperator and #love.touch.getTouches() == 1 then
				game.focusedOperator = nil
			else
				local mtgx, mtgy = mapToGrid(x, y)
				local dx, dy = mapFromGridCenter(mtgx, mtgy)
				warn(string.format("Touch Grid (%.2f , %.2f)", mtgx, mtgy))
			end
		end
	elseif teamEditing then
		if x > 0.93 * w and abs(y - h * 0.5) < h * 0.4 then
			gameStart(levels[levelSelected], teamEditing)
		end
	else
		if x > 0.6 * w then
			if kanbanMessage then
				kanbanMessage = nil
			else
				-- local c = loaded_characters[doctor['kanban']['name']]['messages']['interactions']
				kanbanMessage = loaded_characters:getRandomMessage(doctor['kanban']['name'])
			end
		elseif x > w * 0.09 and y > h * 0.4 then
			local newSelectedLevel = math.ceil((y - h * 0.4) / (h * 0.15))
			if levelSelected and newSelectedLevel == levelSelected then
				levelSelectConfirm(newSelectedLevel)
			else
				levelSelect(newSelectedLevel)
			end
		else
			levelSelect(0)
		end
	end
end

function love.touchmoved(id, x, y, dx, dy)
	for i = 1, #moveRegister do
		if id == moveRegister[i]['id'] then
			moveRegister[i].onMoved(id, x, y, dx, dy)
		end
	end
end

function love.touchreleased(id, x, y, dx, dy)
	for i = #moveRegister, 1, -1 do
		if id == moveRegister[i]['id'] then
			moveRegister[i].onReleased(id, x, y, dx, dy)
			table.remove(moveRegister, i)
		end
	end
end

function love.keypressed(key)
	if game then
		if key == "escape" then
			pause()
		elseif key == "1" then
			game.timeScale = 1
		elseif key == "2" then
			game.timeScale = 2
		elseif key == "3" then
			game.timeScale = 4
		elseif key == "0" then
			game.timeScale = 13
		end
	elseif teamEditing then
		teamEditing = false
	end
end

function love.threaderror(str, str2)
	error(str2)
end
