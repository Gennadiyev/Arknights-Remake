local floor = math.floor

local function behavior(target)
    target.attackMode = false
    target.attackPhase = 0
    target.attackPhaseDuration = 0
    target.blocking = {}
    function target:killed(game)
        target.state = "revive"
        return true
    end
    function target:update(game, dt)
        -- If I haven't blocked enough enemies, check whether there is another enemy that can be blocked
        local noEnemyToBlock = false
        if #target.blocking < target.data.block and not(noEnemyToBlock) then
            local blockCount = target.data.block - #target.blocking
            -- By default, the enemies with the shortest path towards the base will be blocked first
            local l = {}
            for i = 1, #game.enemies do
                l[#l + 1] = {
                    e = game.enemies[i]['target'],
                    d = game.enemies[i]['target']:getPah
                }
            end
        end
        noEnemyToBlock = nil
        -- If I'm blocking an enemy, then I have to attack the first blocked enemy.
        if #target.blocking then
            target.attackMode = true
            target.attackPhaseDuration = target.attackPhaseDuration + dt
            if target.attackPhase == 0 then
                -- preparation
                if target.attackPhaseDuration > target.data['attack_prepare'] then
                    -- preparation finished
                    target.attackPhase = 1
                    target.attackPhaseDuration = 0
                end
            else
                -- Iteration
                if target.attackPhaseDuration > target.data['attack_period'][target.attackPhase] then
                    target.attackPhase = target.attackPhase + 1
                    target.attackPhaseDuration = 0
                    if target.attackPhaseDuration > #target.data['attack_period'] then
                        target.attackPhase = 1
                    end
                    target:attack(game, target.blockedOperator)
                end
            end
        end 
    end
end

return behavior