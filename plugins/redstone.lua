local self = {}
self.version = 0.91
self.loadPrio = 1000

local redstonelinks = nil

function self:register(env)
    _ENV = env
    local slots = getPlugin("slots")

    redstonelinks = slots.getRedstoneLinks()

end

function self.setOutput(target, on)
    if redstonelinks[target] ~= nil then
        redstonelinks[target].wrap.setOutput(redstonelinks[target].side, on)
    else
        print("Redstone target " .. target .. " not found")
    end
end

function self.getOutput(target)
    if redstonelinks[target] ~= nil then
        return redstonelinks[target].wrap.getOutput(redstonelinks[target].side)
    end
    print("Redstone target " .. target .. " not found")
    return nil
end

function self.getInput(target)
    if redstonelinks[target] ~= nil then
        return redstonelinks[target].wrap.getInput(redstonelinks[target].side)
    end
    print("Redstone target " .. target .. " not found")
    return nil
end

function self.setAnalogOutput(target, value)
    if redstonelinks[target] ~= nil then
        if redstonelinks[target].wrap.setAnalogOutput then
            return redstonelinks[target].wrap.setAnalogOutput(redstonelinks[target].side, value)
        elseif redstonelinks[target].wrap.setAnalogueOutput then
            return redstonelinks[target].wrap.setAnalogueOutput(redstonelinks[target].side, value)
        end
    end
    print("Redstone target " .. target .. " not found or method unavailable")
    return nil
end

-- alias British spelling
function self.setAnalogueOutput(target, value)
    return self.setAnalogOutput(target, value)
end

function self.getAnalogOutput(target)
    if redstonelinks[target] ~= nil then
        if redstonelinks[target].wrap.getAnalogOutput then
            return redstonelinks[target].wrap.getAnalogOutput(redstonelinks[target].side)
        elseif redstonelinks[target].wrap.getAnalogueOutput then
            return redstonelinks[target].wrap.getAnalogueOutput(redstonelinks[target].side)
        end
    end
    print("Redstone target " .. target .. " not found or method unavailable")
    return nil
end

function self.getAnalogueOutput(target)
    return self.getAnalogOutput(target)
end

function self.getAnalogInput(target)
    if redstonelinks[target] ~= nil then
        if redstonelinks[target].wrap.getAnalogInput then
            return redstonelinks[target].wrap.getAnalogInput(redstonelinks[target].side)
        elseif redstonelinks[target].wrap.getAnalogueInput then
            return redstonelinks[target].wrap.getAnalogueInput(redstonelinks[target].side)
        end
    end
    print("Redstone target " .. target .. " not found or method unavailable")
    return nil
end

function self.getAnalogueInput(target)
    return self.getAnalogInput(target)
end

function self.getTargets()
    local targets = {}
    for target, _ in pairs(redstonelinks) do
        table.insert(targets, target)
    end
    return targets
end

return self
