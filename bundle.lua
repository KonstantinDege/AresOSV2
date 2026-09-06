packagePrefix = ""
real_time = true
package = package or {}
package.preload = package.preload or {}
package.preload["black_box"] = function(...)
    local self = {}
    self.version = 0.91
    self.loadPrio = 1000
    local data = {}
    function self:register(env)
        _ENV = env
        register:addAction("onUpdate", "black_box", function()
            print(os.clock(),  SensorAPI.getYaw())
        end)
    end
    return self
end
package.preload["register"] = function(...)
    -- Register is handling all event registrations
    local self = {}
    self.functionRegister = {}
    self.taskRegister = { }
    self.taskOrder = {}
    local function compareTasks(a, b)
        if a ~= nil and b ~= nil then
            return self.taskRegister[a].order < self.taskRegister[b].order
        end
        return nil
    end
    --[[Adds a task that will be done one step (yield) every frame,
        if there is not a task with lower or same priority number before that.
        Tasks with a lot of yield and unset "rating" that run for a very long time may block important tasks.
        "rating" is the amount of power, in relation the total cpu cycles, a task takes.
        At the time of adding this rating, you could execute about 3500 commands before cpu overload.]]--
    local taskMaxRating = 2500
    function self:addTask(name, func, priority, rating)
        assert(type(name) == "string", "addTask: name isn't a string, type was " .. type(name))
        assert(type(func) == "function", name .. ": func isn't a function, type was " .. type(func))
        if priority == nil then
            priority = 10
        else
            assert(type(priority) == "number" ,  name .. ": priority has to be number, type was " .. type(priority))
        end
        if rating == nil then
            rating = taskMaxRating
        else
            assert(type(rating) == "number" ,  name .. ": rating has to be number, type was " .. type(rating))
            assert(rating <= taskMaxRating ,  name .. ": rating has to be smaller then the allowed max rating of " .. taskMaxRating)
        end
        if not self:hasAction("onUpdate","registerTasker") then
            self:addAction("onUpdate","registerTasker",function() self:runTasks() end)
        end
        if self.taskRegister[name] ~= nil then self:removeTask(name) end
        table.insert(self.taskOrder, name)
        self.taskRegister[name] = {order=priority,task=coroutine.create(func),rating=rating}
        if #self.taskOrder > 1 then table.sort(self.taskOrder,compareTasks) end
    end
    function self:hasTask(name)
        return self.taskRegister[name] ~= nil
    end
    function self:removeTask(name)
        assert(type(name) == "string", "removeTask: Name isn't a string, type was " .. type(name))
        self.taskRegister[name] = nil
        for k,v in pairs(self.taskOrder) do
            if v == name then
                table.remove(self.taskOrder,k)
                return
            end
        end
    end
    function self:runTasks()
        local currTasksRating = 0
        for _, name in ipairs(self.taskOrder) do
            local regTask = self.taskRegister[name]
            if (currTasksRating + regTask.rating) <=  taskMaxRating then
                if regTask.task == nil or coroutine.status(regTask.task) == "dead" then
                    self:removeTask(name)
                else
                    currTasksRating = currTasksRating + regTask.rating
                    local ok, errorMsg = coroutine.resume(regTask.task)
                    if not ok then
                        printError(name .." in runTasks:",errorMsg)
                        self:removeTask(name)
                    end
                end
            end
        end
    end
    function self:hasAction(action,name)
        return self.functionRegister[action] ~= nil and self.functionRegister[action][name] ~= nil
    end
    function self:addAction(action, name, func)
        assert(type(action) == "string", "action isn't a string, type was " .. type(action))
        assert(type(name) == "string", action .. ": name isn't a string, type was " .. type(name))
        assert(type(func) == "function", action .. ":" .. name .. ": func isn't a function, type was " .. type(func))
        if self.functionRegister[action] == nil then
            self.functionRegister[action] = {}
        end
        self.functionRegister[action][name] = func
    end
    function self:removeAction(action, name)
        if self.functionRegister[action] == nil or self.functionRegister[action][name] == nil then
            return false
        end
        self.functionRegister[action][name] = nil
        return true
    end
    function self:callAction(action, ...)
        local results = {}
        if self.functionRegister[action] ~= nil then
            if devMode then
                print("callAction: " .. action)
            end
            for name, func in pairs(self.functionRegister[action]) do
                if func ~= nil then
                    local status, res = pcall(func, ...)
                    if status then
                        results[name] = res
                    else
                        printError(name .." in callAction:",res)
                    end
                end
            end
        end
        return results
    end
    function self:callActionSpecific(action, name, ...)
    	assert(self.functionRegister[action] == "table", action .. ":" .. " not registered")
    	assert(self.functionRegister[action][name] == "function", action .. ":" .. name .. ": called specified function isn't a function, type was " .. type(self.functionRegister[action][name]))
    	local status, res = pcall(self.functionRegister[action][name], ...)
    	if status then
    		return res
    	else
    		printError(name .." in callActionSpecific:",res)
    	end
    end
    return self
end
package.preload["slots"] = function(...)
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
        local linkconfig = getPlugin("conf", false, "", true)
        if slots["redstone_relay"] ~= nil then
            for target, name in pairs(linkconfig.redstone) do
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
            for target, block in pairs(linkconfig.vel) do
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
    function redstoneAPI.setOutput(target, on)
        if redstonelinks[target] ~= nil then
            redstonelinks[target].wrap.setOutput(redstonelinks[target].side, on)
        else
            print("Redstone target " .. target .. " not found")
        end
    end
    function redstoneAPI.getOutput(target)
        if redstonelinks[target] ~= nil then
            return redstonelinks[target].wrap.getOutput(redstonelinks[target].side)
        end
        print("Redstone target " .. target .. " not found")
        return nil
    end
    function redstoneAPI.getInput(target)
        if redstonelinks[target] ~= nil then
            return redstonelinks[target].wrap.getInput(redstonelinks[target].side)
        end
        print("Redstone target " .. target .. " not found")
        return nil
    end
    function redstoneAPI.setAnalogOutput(target, value)
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
    function redstoneAPI.setAnalogueOutput(target, value)
        return redstoneAPI.setAnalogOutput(target, value)
    end
    function redstoneAPI.getAnalogOutput(target)
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
    function redstoneAPI.getAnalogueOutput(target)
        return redstoneAPI.getAnalogOutput(target)
    end
    function redstoneAPI.getAnalogInput(target)
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
    function redstoneAPI.getAnalogueInput(target)
        return redstoneAPI.getAnalogInput(target)
    end
    function redstoneAPI.getTargets()
        local targets = {}
        for target, _ in pairs(redstonelinks) do
            table.insert(targets, target)
        end
        return targets
    end
    function sensorAPI.getAlt()
        if slots["altitude_sensor"] ~= nil then
            return slots["altitude_sensor"].getHeight()
        end
        print("Altitude sensor not found")
        return nil
    end
    function sensorAPI.getPressure()
        if slots["altitude_sensor"] ~= nil then
            return slots["altitude_sensor"].getAirPressure()
        end
        print("Altitude sensor not found")
        return nil
    end
    function sensorAPI.getVelDown()
        if sensors["vel_down"] ~= nil then
            return sensors["vel_down"].getVelocity()
        end
        print("VelocityDown sensor not found")
        return nil
    end
    function sensorAPI.getVelFor()
        if sensors["vel_for"] ~= nil then
            return sensors["vel_for"].getVelocity()
        end
        print("VelocityForward sensor not found")
        return nil
    end
    function sensorAPI.getVelRight()
        if sensors["vel_right"] ~= nil then
            return sensors["vel_right"].getVelocity()
        end
        print("VelocityRight sensor not found")
        return nil
    end
    function sensorAPI.getVel()
        return vector.new(sensorAPI.getVelRight() or 0, sensorAPI.getVelDown() or 0, sensorAPI.getVelFor() or 0)
    end
    function sensorAPI.getYaw()
        if slots["navball"] ~= nil then
            return slots["navball"].getYaw()
        end
        print("Navball not found")
        return nil
    end
    function sensorAPI.getPitch()
        if slots["navball"] ~= nil then
            return slots["navball"].getPitch()
        end
        print("Navball not found")
        return nil
    end
    function sensorAPI.getRoll()
        if slots["navball"] ~= nil then
            return slots["navball"].getRoll()
        end
        print("Navball not found")
        return nil
    end
    function sensorAPI.getAttitude()
        return vector.new(sensorAPI.getYaw() or 0, sensorAPI.getPitch() or 0, sensorAPI.getRoll() or 0)
    end
    return self
end

rawPrint = print
function print_err(msg,err)
    if err then
        err = tostring(err):gsub('"%-%- |STDERROR%-EVENTHANDLER[^"]*"', 'chunk'):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    else
        err = "???"
    end
    rawPrint(msg .. " ".. err)
end
function print(str)
    rawPrint(tostring(str))
end

-- plugin handler
local realRequire = require
require = function(name) return print("require '" .. name.. "': deprecated, use getPlugin()") end 
local plugins = {}
local pluginCache = {}
function plugins:fixName(name)
    local pp = packagePrefix
    if string.find(name, pp) then
        name = string.gsub(name, pp, "")
    end
	return name
end

function plugins:unloadPlugin(name,noPrefix,key)
	assert(type(name) == "string", "getPlugin: parameter name has to be string, was " .. type(name))
	name = plugins:fixName(name)
    local pp = packagePrefix
    if type(pluginCache[name]) == "table" and pluginCache[name].valid ~= nil then
        if pluginCache[name]:valid(key) ~= true then
            return nil
        end
    end
	if noPrefix then pp = "" end
	if package.loaded ~= nil and package.loaded[pp..name] ~= nil then
		package.loaded[pp..name] = nil
	end
	if pluginCache[name] ~= nil then
		if type(pluginCache[name]) == "table" and type(pluginCache[name].unregister) == "function" then
			pluginCache[name].unregister()
		end
		pluginCache[name] = nil
	end
end
-- optional key, will checked on function "valid" before returning plugin if it exist, otherwise defaults to return plugin
function plugins:getPlugin(name,noError,key,noPrefix)
    assert(type(name) == "string", "getPlugin: parameter name has to be string, was " .. type(name))
    if noError == nil then noError = false end
	name = plugins:fixName(name)
	
    if not plugins:hasPlugin(name,noError,noPrefix) then return nil end

    if type(pluginCache[name]) == "table" and pluginCache[name].valid ~= nil then
        if pluginCache[name]:valid(key) ~= true then
            if not noError then printError("getPlugin '"..name.."':".." Not valid or compatible") end
            return nil
        end
    end

    return pluginCache[name]
end
function plugins:hasPlugin(name,noError,noPrefix)
    assert(type(name) == "string", "hasPlugin: parameter name has to be string, was " .. type(name))
    if noError == nil then noError = false end
    name = plugins:fixName(name)
    local pp = packagePrefix
	if noPrefix then pp = "" end
	
    if pluginCache[name] == nil then
		pluginCache[name] = false

        local ok, res = pcall(realRequire, pp..name)
        if not ok then
            if noError == nil or not noError then
                printError("hasPlugin '"..name.."': require failed",res)
            end
        else
            pluginCache[name] = res
        end


        if type(pluginCache[name]) == "table" then
            if pluginCache[name].register ~= nil then
                -- injecting globals to make sure they are available
                if _ENV["register"] == nil then _ENV["register"] = register end

                local ok2, res2 = pcall(pluginCache[name].register,pluginCache[name],_ENV)
                if not ok2 and not noError then
                    printError("hasPlugin '"..name.."': register failed",res2)
                end
            end
        else
            if pluginCache[name] ~= nil and pluginCache[name] ~= false then
				if type(pluginCache[name]) == "string" then 
					printError("hasPlugin '"..name.."':"..pluginCache[name])
				else
					printError("hasPlugin '"..name.."': not table value")
				end
                
            end
        end
    end
    return type(pluginCache[name]) == "table"
end
function unloadPlugin(name,noPrefix) return plugins:unloadPlugin(name,noPrefix) end
function hasPlugin(name,noError,noPrefix) return plugins:hasPlugin(name,noError,noPrefix) end
function getPlugin(name,noError,key,noPrefix) return plugins:getPlugin(name,noError,key,noPrefix) end
local errorStack = {}

-- NEEDS to be the FIRST initialized module! Register is the only implicit dependency

-- Globals


-- END globals

-- helpers
function collect_keys(t, sort)
    local _k = {}
    for k in pairs(t) do
        _k[#_k+1] = k
    end
    table.sort(_k, sort)
    return _k
end
function sortedPairs(t, sort)
    local keys = collect_keys(t, sort)
    local i = 0
    return function()
        i = i+1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end
function tableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end


function timeit(title, f)
    collectgarbage()
    local startTime = clock()
    local result = f()
    local endTime = clock()
    print( title .. ": " .. (endTime - startTime) )
    return result
end
function getRelativePitch(velocity)
    return math.deg(math.atan(velocity[2], velocity[3])) - 90
end
function getRelativeYaw(velocity)
    return math.deg(math.atan(velocity[2], velocity[1])) - 90
end
function mysplit(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end
function inTable(tab, val)
    if type(tab) ~= "table" then return false end
    for k,v in pairs(tab) do
        if v == val then return true,k end
    end
    return false
end
function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    if numDecimalPlaces ~= nil then
        return math.floor(num * mult + 0.5) / mult
    else
        return math.floor((num * mult + 0.5) / mult)
    end
end

-- END helpers
register = getPlugin("register")
slots = getPlugin("slots")

--easier time with timers
local Timer = {}
local TimerTimes = {}

function addTimer(time, callback)
    if time == nil then time = 0 end
    id = os.startTimer(time)
    Timer[id] = callback
    TimerTimes[id] = time
end

function onTimer(timerId)
    if Timer[timerId] ~= nil then
        local ok, err = pcall(Timer[timerId])
        if not ok then printError("Timer:" .. err .. "  " .. timerId) end

        if TimerTimes[timerId] ~= nil then
            addTimer(TimerTimes[timerId], Timer[timerId])
        end
        Timer[timerId] = nil
        TimerTimes[timerId] = nil
    end
end

function stopTimer(id)
    if id == nil then
        for k,_ in pairs(Timer) do
            Timer[k] = nil
            TimerTimes[k] = nil
            os.cancelTimer(k)
        end
        return
    end

    Timer[id] = nil
    TimerTimes[id] = nil
    os.cancelTimer(id)
end

function delay(func, time)
    if time == nil then time = 0 end
    id = os.startTimer(time)
    Timer[id] = callback
end

register:addAction("timer", "Timer", onTimer)

-- Load all registrations from all packages. Will be late init

for name,_ in sortedPairs(package.preload) do
	getPlugin(name,true)
end

sleep(0.1)

register:callAction("StartUp")


sleep()

local function tickProgram()
    while true do
        register:callAction("onUpdate")
        register:runTasks()
        sleep(0) -- Yields for 1 tick
    end
end

local function listenerProgram()
    while true do
        local event= os.pullEvent()
        register:callAction(table.unpack(event))
    end
end

if real_time then
    parallel.waitForAll(tickProgram, listenerProgram)
end