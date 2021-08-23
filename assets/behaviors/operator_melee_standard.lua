local function wrapper(T)
    
    T.behavior = "enemy_ground_standard" -- behavior name
    T.attackState = {
        target = false, -- attacking target
        attackPhase = 0, -- attack phase
        attackPhaseDuration = 0, -- duration elapsed in current state
    }

    function T:callback(game, event)
        if event == "spawned" then
            self.spawnTime = game.time
        end
    end

    function T:kill()
        self.state = "revive"
        self.position = false
        self.reviveDuration = self.data.revive_period
        self.attackState = {
            target = false, -- attacking target
            attackPhase = 0, -- attack phase
            attackPhaseDuration = 0, -- duration elapsed in current state
        }
        self.skillActive = false
        self.skillCost = 0
        self.data.health = self.data.max_health
    end

    function T:update(game, dt)
        if self.state == "battle" then
            -- If health drops below 0, kill youself
            if self.data.health <= 0 then
                self:kill()
            end
            -- If the skill is auto cost regen, regen some cost
            if self.skill.cost_regeneration == "auto" then
                -- If skill is active, no cost will be regen-ed
                if self.skillActive then
                    self.skillActive = self.skillActive - dt
                    if self.skillActive <= 0 then
                        self.skillActive = false
                    end
                else
                    -- Regen
                    self.skillCost = math.min(self.skillCost + dt, self.skill.cost)
                    if self.skillCost >= self.skill.cost and self.skill.trigger == "auto" then
                        self.skillActive = self.skill.duration
                        self.skillCost = 0
                        warn("Skill Triggered: "..self.name)
                    end
                end
            end
        elseif self.state == "revive" then
            if self.reviveDuration then
                self.reviveDuration = self.reviveDuration - dt
                if self.reviveDuration < 0 then
                    self.reviveDuration = false
                    self.state = "ready"
                end
            end
        end
    end
    
end

return wrapper