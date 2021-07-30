local eps = 1e-3

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
    function target:getTauntFactor()
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
        if target.data.health < 0 then
            target:killed()
        end
        local task = {
            type = "suicide"
        }
        if target.programPointer < #target.program then
            task = target.program[target.programPointer + 1]
        end
        if task.type == "suicide" then
            target:killed()
        end
        -- If waiting then return
        if target.waitTime > 0 then
            target.waitTime = target.waitTime - dt
            if target.waitTime <= 0 then
                target.programPointer = target.programPointer + 1
            end
            return
        end
        if task.type == "move" then
            -- Did I arrive?
            local mx, my = task.destination[1] - target.position[1], task.destination[2] - target.position[2]
            local absLen = math.sqrt(mx * mx + my * my)
            if absLen < eps then
                -- arrived
                target.position[1], target.position[2] = task.destination[1], task.destination[2]
                -- warn("Moved to "..task.destination[1]..", "..task.destination[2])
                target.programPointer = target.programPointer + 1
            else
                -- move
                movedLength = movedLength
                target.position[1] = target.position[1] + mx / absLen * target.data.speed * dt
                target.position[2] = target.position[2] + my / absLen * target.data.speed * dt
            end
        elseif task.type == "wait" then
            target.waitTime = task.duration
        elseif task.type == "invade" then
            game.life = game.life - target.data.invasion
            warn("Life left: "..game.life)
            target.programPointer = target.programPointer + 1
        end
        if not(target.blockedOperator) then
            if target.attackMode then
                target.attackMode = false
                target.attackPhase = 0
                target.attackPhaseDuration = 0
            end
        else
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
