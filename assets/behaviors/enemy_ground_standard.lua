local pathFinder = require("libs.lua-star")
local function round(i)
    return math.floor(i + 0.5)
end

local function wrapper(T)
    
    T.behavior = "enemy_ground_standard" -- behavior name
    T.attackState = {
        target = false, -- attacking target
        attackPhase = 0, -- attack phase
        attackPhaseDuration = 0, -- duration elapsed in current state
    }
    T.distance = false -- distance to invasion
    T.programPointer = 0 -- program pointer
    T.waitTime = 0 -- wait time if the program demands wait
    T.blocked = false
    
    function T:callback(game, event) -- callback function is called on each time an external operation is performed
        if event == "summon" then

        end
    end
    
    function T:kill(game) -- kill this instance
        for i = 1, #game.enemies do
            if game.enemies[i] == self then
                table.remove(game.enemies, i)
                return true
            end
        end
        return false
    end

    function T:attack(game, target)
        target.data.health = target.data.health - math.max(self.data.attack - target.data.defence, 0.05*self.data.attack)
    end

    function T:update(game, dt)
        -- If currently the health is below 0, then kill
        if self.data.health < 0 then
            self:kill(game)
        end
        -- If the blocking target is not on battle, remove blocking status
        if self.blocked and self.blocked.state ~= "battle" then
            self.blocked = falsse
        end
        -- If waiting right now, then update waitTime and quit
        if self.waitTime > 0 then
            self.waitTime = self.waitTime - dt
            if self.waitTime < 0 then
                self.waitTime = 0
                self.programPointer = self.programPointer + 1
            else
                return
            end
        end
        -- Fetch the current task
        local task
        if self.programPointer < #self.program then -- program unfinished
            task = self.program[self.programPointer + 1]
        else -- program finished but still undead
            self:kill(game)
            return
        end
        -- If blocked by other operator, attack phase propagate
        if self.blocked then
            if self.attackState.target == self.blocked then
                self.attackState.attackPhaseDuration = self.attackState.attackPhaseDuration + dt
                --
                if self.attackState.attackPhase == 0 then
                    -- preparation
                    if self.attackState.attackPhaseDuration >= self.data['attack_prepare'] then
                        -- preparation finished
                        self.attackState.attackPhase = 1
                        self.attackState.attackPhaseDuration = 0
                    end
                else
                    if self.attackState.attackPhaseDuration >= self.data['attack_period'][self.attackState.attackPhase] then
                        self.attackState.attackPhase = self.attackState.attackPhase + 1
                        self.attackState.attackPhaseDuration = 0
                        if self.attackState.attackPhase > #self.data['attack_period'] then
                            self.attackState.attackPhase = 1
                        end
                        self:attack(game, self.blocked)
                    end
                end
                --
            else
                self.attackState.target = self.blocked
                self.attackState.attackPhase = 0
                self.attackState.attackPhaseDuration = 0
            end
        else
            self.attackState.attackPhase = 0
            self.attackState.attackPhaseDuration = 0
        end
        if task.type == "move" then
            -- Have I reached the destination?
            if math.abs(self.position[1] - task.destination[1]) + math.abs(self.position[2] - task.destination[2]) < self.data.speed * 0.0167 * game.timeScale then
                self.programPointer = self.programPointer + 1
                self.position[1], self.position[2] = task.destination[1], task.destination[2]
                return
            end
            -- Use a* to find the path
            -- Generate Path map with only true and false
            local gameMap = game.level.map
            local pathMap = {}
            for y = 1, #gameMap do
                local row = {}
				for x = 1, #gameMap[1] do
					if gameMap[y][x] == 1 or gameMap[y][x] == 3 or gameMap[y][x] == 5 or gameMap[y][x] == 7 or gameMap[y][x] == 10 or gameMap[y][x] == 11 then
                        row[x] = true
                    else
                        row[x] = false
                    end
                end
                pathMap[y] = row
            end
            -- Feed to A* pathFinder
            local pathMapFunction = function(y, x)
                return pathMap[y][x]
            end
            local path = pathFinder:find(#pathMap, #pathMap[1], {x=round(self.position[1]), y=round(self.position[2])}, {x=task.destination[1], y=task.destination[2]}, pathMapFunction, true, true)
            -- If path does not exist, then warn and suicide
            if not(path) then warn("Cannot find path for "..tostring(self)) self:kill(game) return end
            -- Find the next path
            local tx, ty = 0, 0
            if path[2] then
                tx, ty = path[2].x, path[2].y
            else
                tx, ty = task.destination[1], task.destination[2]
            end
            -- Move towards tx, ty
            local mx, my = tx - self.position[1], ty - self.position[2]
            -- Move according to speed
            local absLen = math.sqrt(mx * mx + my * my)
            local dx, dy = mx / absLen * self.data.speed * dt, my / absLen * self.data.speed * dt
            -- Attempted target position is ax, ay
            local ax, ay = self.position[1] + dx, self.position[2] + dy
            -- Check if ax, ay is blocked by operators
            local t = game.team
            local floor = math.floor
            for i = 1, #t do
                if t[i]['state'] == "battle" then
                    if floor(t[i]['position'][1]) == round(ax) and floor(t[i]['position'][2]) == round(ay) then
                        -- Do not move
                        for j = 1, #t[i].blocked do
                            if t[i].blocked[j] == self then
                                return
                            end
                        end
                        t[i].blocked[#t[i].blocked + 1] = self
                        self.blocked = t[i]
                        return
                    end
                end
            end
            -- Update distance to destination
            local d = 0
            for i = self.programPointer + 2, #self.program do
                if self.program[i]['type'] == "move" then
                    d = d + self.program[i]['length']
                end
            end
            if path and #path > 1 then
                d = d + #path - 2 + absLen
            else
                d = d + absLen
            end
            self.distance = d
            -- Update the position
            self.position[1], self.position[2] = ax, ay
        elseif task.type == "wait" then
            self.waitTime = task.duration
        elseif task.type == "invade" then
            game.life = game.life - self.data.invasion
            warn("Life left: "..game.life)
            self.programPointer = self.programPointer + 1
        end
    end
end

return wrapper