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
    
    function T:callback(event) -- callback function is called on each time an external operation is performed

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

    function T:update(game, dt)
        -- If currently the health is below 0, then kill
        if self.data.health < 0 then
            self:kill(game)
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
        if task.type == "move" then
            -- Have I reached the destination?
            if math.abs(self.position[1] - task.destination[1]) + math.abs(self.position[2] - task.destination[2]) < self.data.speed * 0.0334 then
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