local self = {}
self.version = 0.91
self.loadPrio = 1000
local slots = {}
local multipleSlots = {"redstone_relay", "velocity_sensor"}
local multipleSlotsCP = {"redstone_relay"}
local threeWayToggle = {{"w", "s"}, {"a", "d"}, {"q", "e"}}

local sensors = {}
local redstonelinks = {}
local redstoneAPI = {}
local sensorAPI = {}
local baseRedstone = redstone

local function mergeInvArrays(...)
    local result = {}
    -- Iterate through all tables passed as arguments
    for _, currentTable in ipairs({...}) do
        -- Insert each value into the result table
        for _, value in ipairs(currentTable) do
            result[value] = true
        end
    end
    return result
end
local function fixName(name, expand)
    if string.find(name, "$", 1, true) then
        return expand..name
    end
    return name
end
local function handlethreeway(key, currentKeys)
    for _, group in ipairs(threeWayToggle) do
        if table.contains(group, key) then
            local firstPressed = currentKeys[group[1]] ~= nil
            local secondPressed = currentKeys[group[2]] ~= nil
            local currentState = 0

            if firstPressed and not secondPressed then
                currentState = 1
            elseif secondPressed and not firstPressed then
                currentState = -1
            end

            keyStates[table.concat(group, "_")] = currentState
        end
    end 
end

local threewayToggleKeys = mergeInvArrays(table.unpack(threeWayToggle))
local keyStates = {}
local previouskeys = {}
function self:register(env)
    _ENV = env

    for _, name in ipairs(peripheral.getNames()) do
        if multipleSlots[name] == nil then
            slots[peripheral.getType(name)] = peripheral.wrap(name)
        else
            if slots[peripheral.getType(name)] == nil then
                slots[peripheral.getType(name)] = {}
            end
            table.insert(slots[peripheral.getType(name)], peripheral.wrap(name))
        end
    end
    if slots["control_panel"] ~= nil then
        for _, element in slots["control_panel"].getModules() do
            if multipleSlotsCP[element.getType()] == nil then
                slots[element.getType()] = element
            else
                if slots[element.getType()] == nil then
                    slots[element.getType()] = {}
                end
                table.insert(slots[element.getType()], element)
            end
        end
    end
    if slots["linked_typewriter"] ~= nil then
        register:addAction("onUpdate", "typewriter", function()
            local currentKeyCodes = slots["linked_typewriter"].getKeys()
            local currentKeys = {}
            for _, keycode in pairs(currentKeyCodes) do
                local key = keys.getName(keycode)
                currentKeys[key] = true
                if previouskeys[key] == nil then
                    previouskeys[key] = true
                    register:callAction(key.."Start", key)

                    if threewayToggleKeys[key] then
                        handlethreeway(key, currentKeys)
                    end
                    keyStates[key] = 1
                else
                    register:callAction(key.."Hold", key)
                end
            end
            for key, _ in pairs(previouskeys) do
                if currentKeys[key] == nil then
                    previouskeys[key] = nil
                    register:callAction(key.."Stop", key)
                    if threewayToggleKeys[key] then
                        handlethreeway(key, currentKeys)
                    
                    end
                    keyStates[key] = 0
                end
            end

        end)
    end 

    local linkconfig = getPlugin("conf", true, "", true)
    if slots["redstone_relay"] ~= nil then
        for name, target in pairs(linkconfig.redstone) do
            local block, side = mysplit(name, "@")
            block = fixName(block, "redstone_relay_")
            if block == "" or block == nil then
                redstonelinks[target] = {
                    wrap = baseRedstone,
                    side = side
                }
            elseif slots["redstone_relay"][block] ~= nil then
                redstonelinks[target] = {
                    wrap = slots["redstone_relay"][block],
                    side = side
                }
            else
                print("Redstone relay " .. block .. " not found for target " .. target)
            end
                
        end
    end
    if slots["velocity_sensor"] ~= nil then
        for block, target in pairs(linkconfig.vel) do
            local block = fixName(block, "velocity_sensor_")
            if slots["velocity_sensor"][block] ~= nil then
                sensors[target] = slots["velocity_sensor"][block]
            else
                print("Velocity sensor " .. block .. " not found for target " .. target)
            end
        end
    end

    _ENV["RedstoneAPI"] = redstoneAPI
    _ENV["SensorAPI"] = sensorAPI
end

function self:getToggleState(key)
    if keyStates[key] ~= nil then
        return keyStates[key]
    end
    return 0
end

function RedstoneAPI.setOutput(target, on)
    if redstonelinks[target] ~= nil then
        redstonelinks[target].wrap.setOutput(redstonelinks[target].side, on)
    else
        print("Redstone target " .. target .. " not found")
    end
end

function RedstoneAPI.getOutput(target)
    if redstonelinks[target] ~= nil then
        return redstonelinks[target].wrap.getOutput(redstonelinks[target].side)
    end
    print("Redstone target " .. target .. " not found")
    return nil
end

function RedstoneAPI.getInput(target)
    if redstonelinks[target] ~= nil then
        return redstonelinks[target].wrap.getInput(redstonelinks[target].side)
    end
    print("Redstone target " .. target .. " not found")
    return nil
end

function RedstoneAPI.setAnalogOutput(target, value)
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
function RedstoneAPI.setAnalogueOutput(target, value)
    return RedstoneAPI.setAnalogOutput(target, value)
end

function RedstoneAPI.getAnalogOutput(target)
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

function RedstoneAPI.getAnalogueOutput(target)
    return RedstoneAPI.getAnalogOutput(target)
end

function RedstoneAPI.getAnalogInput(target)
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

function RedstoneAPI.getAnalogueInput(target)
    return RedstoneAPI.getAnalogInput(target)
end

function RedstoneAPI.getTargets()
    local targets = {}
    for target, _ in pairs(redstonelinks) do
        table.insert(targets, target)
    end
    return targets
end

function SensorAPI.getAlt()
    if slots["altitude_sensor"] ~= nil then
        return slots["altitude_sensor"].getHeight()
    end
    print("Altitude sensor not found")
    return nil
end
function SensorAPI.getPressure()
    if slots["altitude_sensor"] ~= nil then
        return slots["altitude_sensor"].getAirPressure()
    end
    print("Altitude sensor not found")
    return nil
end
function SensorAPI.getVelDown()
    if sensors["vel_down"] ~= nil then
        return sensors["vel_down"].getVelocity()
    end
    print("VelocityDown sensor not found")
    return nil
end
function SensorAPI.getVelFor()
    if sensors["vel_for"] ~= nil then
        return sensors["vel_for"].getVelocity()
    end
    print("VelocityForward sensor not found")
    return nil
end
function SensorAPI.getVelRight()
    if sensors["vel_right"] ~= nil then
        return sensors["vel_right"].getVelocity()
    end
    print("VelocityRight sensor not found")
    return nil
end
function SensorAPI.getVel()
    return vector.new(SensorAPI.getVelRight() or 0, SensorAPI.getVelDown() or 0, SensorAPI.getVelFor() or 0)
end

function SensorAPI.getYaw()
    if slots["navball"] ~= nil then
        return slots["navball"].getYaw()
    end
    print("Navball not found")
    return nil
end
function SensorAPI.getPitch()
    if slots["navball"] ~= nil then
        return slots["navball"].getPitch()
    end
    print("Navball not found")
    return nil
end
function SensorAPI.getRoll()
    if slots["navball"] ~= nil then
        return slots["navball"].getRoll()
    end
    print("Navball not found")
    return nil
end
function SensorAPI.getAttitude()
    return vector.new(SensorAPI.getYaw() or 0, SensorAPI.getPitch() or 0, SensorAPI.getRoll() or 0)
end
return self