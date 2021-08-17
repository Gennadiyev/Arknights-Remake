--[[
    javascript:document.documentElement.webkitRequestFullscreen();
]]

local eps = 0.02

local function behavior(target)
    target.programPointer = 0
    target.attackMode = false
    target.attackPhase = 0
    target.attackPhaseDuration = 0
    target.waitTime = 0
    target.blockedOperator = nil

    function target:attack(game, operator)
        warn("Attacking operator "..operator.name)
    end
    function target:getTauntFactor(game)
        if target.data.taunt == 1 then
            return target.pathLength
        end
    end
    function target:killed(game)
        for i = 1, #game.enemies do
            if game.enemies[i] == self then
                table.remove(game.enemies, i)
                return true
            end
        end
        return false
    end
    function target:update(game, dt)
        -- Check what's my next task
        if self.data.health < 0 then
            self:killed(game)
        end
        local task = {
            type = "suicide"
        }
        if self.programPointer < #self.program then
            task = self.program[self.programPointer + 1]
        end
        if task.type == "suicide" then
            self:killed(game)
        end
        -- If waiting then return
        if self.waitTime > 0 then
            self.waitTime = self.waitTime - dt
            if self.waitTime <= 0 then
                self.programPointer = self.programPointer + 1
            end
            return
        end
        if task.type == "move" then
            -- Did I arrive?
            local mx, my = task.destination[1] - self.position[1], self.destination[2] - self.position[2]
            local absLen = math.sqrt(mx * mx + my * my)
            if absLen < eps then
                -- arrived
                self.position[1], self.position[2] = task.destination[1], task.destination[2]
                -- warn("Moved to "..task.destination[1]..", "..task.destination[2])
                self.programPointer = self.programPointer + 1
            else
                -- move
                local dx, dy = mx / absLen * self.data.speed * dt, my / absLen * self.data.speed * dt
                local movedDistance = math.sqrt(dx^2 + dy^2)
                local ax, ay = self.position[1] + dx, self.position[2] + dy
                self.pathLength = self.pathLength - movedDistance
                local function isBlocked(game, x, y)
                    for i = 1, #game.operators do
                        if game.operators[i]:canBlock() then
                            
                        end
                    end
                end
                local blockedBy = isBlocked(game, ax, ay)
                if blockedBy then
                    self.blocked = blockedBy
                end
                self.position[1] = ax
                self.position[2] = ay
            end
        elseif task.type == "wait" then
            self.waitTime = task.duration
        elseif task.type == "invade" then
            game.life = game.life - self.data.invasion
            warn("Life left: "..game.life)
            self.programPointer = self.programPointer + 1
        end
        if not(self.isBlocked) then
            if self.attackMode then
                self.attackMode = false
                self.attackPhase = 0
                self.attackPhaseDuration = 0
            end
        else
            self.attackMode = true
            self.attackPhaseDuration = self.attackPhaseDuration + dt
            if self.attackPhase == 0 then
                -- preparation
                if self.attackPhaseDuration > self.data['attack_prepare'] then
                    -- preparation finished
                    self.attackPhase = 1
                    self.attackPhaseDuration = 0
                end
            else
                -- Iteration
                if self.attackPhaseDuration > self.data['attack_period'][self.attackPhase] then
                    self.attackPhase = self.attackPhase + 1
                    self.attackPhaseDuration = 0
                    if self.attackPhaseDuration > #self.data['attack_period'] then
                        self.attackPhase = 1
                    end
                    self:attack(game, self.blockedOperator)
                end
            end
        end
    end
end

return behavior
