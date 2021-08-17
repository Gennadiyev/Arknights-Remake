local floor = math.floor

local function behavior(target)
    target.attackTarget = {}
    target.attackMode = false
    target.attackPhase = 0
    target.attackPhaseDuration = 0
    target.blocking = {}
    function target:killed(game)
        self.state = "revive"
        return true
    end
    function target:canBlock(game)
        return self.state == "battle" and #self.blocking < self.data.block
    end
    function target:update(game, dt)
        -- If I haven't blocked enough enemies, check whether there is another enemy that can be blocked
        -- local noEnemyToBlock = false
        -- if #target.blocking < target.data.block and not(noEnemyToBlock) then
        --     local blockCount = target.data.block - #target.blocking
        --     -- By default, the enemies with the shortest path towards the base will be blocked first
        --     local l = {}
        --     for i = 1, #game.enemies do
        --         l[#l + 1] = {
        --             e = game.enemies[i]['target'],
        --             d = game.enemies[i]['target']:getPah
        --         }
        --     end
        -- end
        -- noEnemyToBlock = nil
        -- If I'm blocking an enemy, then I have to attack the first blocked enemy.
        if #self.blocking then
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
                    self:attack(game, self.attackTarget)
                end
            end
        end 
    end
end

return behavior