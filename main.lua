function print_err(msg,err)
    if err then
        err = tostring(err):gsub('"%-%- |STDERROR%-EVENTHANDLER[^"]*"', 'chunk'):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    else
        err = "???"
    end
    print(msg .. " ".. err)
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
        package.preload[pp..name] = nil
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


local function download_plugin(name,noError,noPrefix)
    local pp = packagePrefix
    if noPrefix then pp = "/" end

    if http == nil then
        if noError == nil or not noError then printError("hasPlugin '"..name.."': http API not available") end
        return nil
    end

    local url = pluginRepoBase .. name .. ".lua"
    local hres = http.get(url)
    if not hres then
        if noError == nil or not noError then printError("hasPlugin '"..name.."': download failed from "..url) end
        return nil
    end

    local content = hres.readAll()
    hres.close()

    local base = tostring(name):match("([^/\\]+)$") or name

    local saveDir = ""
    if pp and pp ~= "/" and pp ~= "" then
        saveDir = string.gsub(pp, "^/", "")
        saveDir = string.gsub(saveDir, "%.", "/")
        if saveDir:sub(-1) ~= "/" then saveDir = saveDir .. "/" end
    else
        saveDir = "" -- root
    end

    if saveDir ~= "" and not fs.exists(saveDir) then fs.makeDir(saveDir) end

    local savePath = (saveDir ~= "" and (saveDir .. base .. ".lua")) or (base .. ".lua")

    if fs.exists(savePath) then fs.delete(savePath) end

    local f = fs.open(savePath, "w")
    if not f then
        if noError == nil or not noError then printError("hasPlugin '"..name.."': failed to save downloaded plugin") end
        return nil
    end

    f.write(content)
    f.close()

    if package.loaded ~= nil and package.loaded[pp..name] ~= nil then
        package.loaded[pp..name] = nil
        package.preload[pp..name] = nil
        pp = "/"..pp
    end

    local ok2, res2 = pcall(realRequire, "/"..pp..name)
    if ok2 then
        pluginCache[name] = res2
        return res2
    else
        if noError == nil or not noError then printError("hasPlugin '"..name.."': require failed after download",res2) end
        return nil
    end
end

local function get_plugin(name,noError,noPrefix)
    local pp = packagePrefix
    if noPrefix then pp = "" end

    if pluginAlwaysDownload and pluginDownloadEnabled then
        local resD = download_plugin(name,noError,noPrefix)
        if resD ~= nil then return resD end

        if package.preload[pp..name] == nil then pp = "/"..pp end
        local okLocal, resLocal = pcall(realRequire, pp..name)
        if okLocal then
            pluginCache[name] = resLocal
            return resLocal
        else
            if noError == nil or not noError then printError("hasPlugin '"..name.."': require failed",resLocal) end
            return nil
        end
    end

    if package.preload[pp..name] == nil then pp = "/"..pp end
    
    local okLocal, resLocal = pcall(realRequire, pp..name)
    if okLocal then
        pluginCache[name] = resLocal
        return resLocal
    end

    if pluginDownloadEnabled then
        local resD = download_plugin(name,noError,noPrefix)
        if resD ~= nil then return resD end
    else
        if noError == nil or not noError then printError("hasPlugin '"..name.."': plugin not found and download disabled") end
    end
    
    if not okLocal then
        if noError == nil or not noError then printError("hasPlugin '"..name.."': require failed",resLocal) end
    end

    return nil
end

function plugins:hasPlugin(name,noError,noPrefix)
    assert(type(name) == "string", "hasPlugin: parameter name has to be string, was " .. type(name))
    if noError == nil then noError = false end
    name = plugins:fixName(name)

    if pluginCache[name] == nil then
		pluginCache[name] = false

        pluginCache[name] = get_plugin(name,noError,noPrefix)

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
    local id = os.startTimer(time)
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
    local id = os.startTimer(time)
    Timer[id] = func
end

register:addAction("timer", "Timer", onTimer)

-- Load all registrations from all packages. Will be late init

for name,_ in sortedPairs(package.preload) do
	getPlugin(name,true)
end

sleep(0.1)

register:callAction("StartUp")

getPlugin("optional", true, "", true)

getPlugin("plugin_list", true)

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