local self = {}
self.version = 0.91
self.loadPrio = 1000
local slots = {}
local multipleSlots = {"redstone_relay", "velocity_sensor"}
local multipleSlotsCP = {"redstone_relay"}
local threeWayToggle = {{"w", "s"}, {"a", "d"}, {"q", "e"}}
local baseRedstone = redstone

local sensors = {}
local redstonelinks = {}

local keyStates = {}
local previouskeys = {}

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

local threewayToggleKeys = mergeInvArrays(table.unpack(threeWayToggle))
local function fixName(name, expand)
    if string.find(name, "$", 1, true) then
        return string.gsub(name, "%$", expand)
    end
    return name
end
local function handlethreeway(key, currentKeys)
    for _, group in ipairs(threeWayToggle) do
        if inTable(group, key) then
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
        for _, element in pairs(slots["control_panel"].getModules()) do
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
            local currentKeyCodes = slots["linked_typewriter"].getPressedKeyCodes()
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

    local linkconfig = getPlugin("conf", false, "", true)
    for target, name in pairs(linkconfig.redstone) do
        local name = mysplit(name, "@")
        local block = fixName(name[1], "redstone_relay_")
        if block == "" or block == nil then
            redstonelinks[target] = {
                wrap = baseRedstone,
                side = name[2]
            }
        elseif peripheral.isPresent(block) then
            redstonelinks[target] = {
                wrap = peripheral.wrap(block),
                side = name[2]
            }
        else
            print("Redstone relay " .. block .. " not found for target " .. target)
        end
            
    end

    for target, block in pairs(linkconfig.vel) do
        local block = fixName(block, "velocity_sensor_")
        if peripheral.isPresent(block) then
            sensors[target] = peripheral.wrap(block)
        else
            print("Velocity sensor " .. block .. " not found for target " .. target)
        end
    end
end

function self.getToggleState(key)
    if keyStates[key] ~= nil then
        return keyStates[key]
    end
    return 0
end

function self.getActiveKeys(key)
    ret = {}
    for key, _ in pairs(keyStates) do 
        table.insert(ret, key)
    end
    return ret
end

function self.getRedstoneLinks() 
    return redstonelinks
end

function self.getSensors() 
    return sensors
end

return self

