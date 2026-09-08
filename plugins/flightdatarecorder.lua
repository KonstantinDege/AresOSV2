local self = {}
self.version = 0.91
self.loadPrio = 1000

local counter = 0
local skip = 40
local data = {}
local slots = nil

local function sendJson(target, json)
    local jsonStr = textutils.serialiseJSON(json)
    return http.post(target, jsonStr)
end

function self:register(env)
    _ENV = env
    slots = getPlugin("slots")

    print("Flight Data Recorder plugin registered. Recording every " .. skip .. " ticks.")

    register:addAction("onUpdate", "black_box", function()
        if counter % skip == 0 then
            local new = {
                alt = SensorAPI.getAlt(),
                pressure = SensorAPI.getPressure(),
                vel = SensorAPI.getVel(),
                attitude = SensorAPI.getAttitude(),
                keys = {},
                time = os.clock(),
            }
            for k,v in pairs(slots.getActiveKeys()) do
                new.keys[v] = slots.getToggleState(v)
            end

            local res, msg = sendJson("http://skeleti.asuscomm.com:8000/recorder", new)
            if res == nil then
                print(msg)
            end

            table.insert(data, new)
        end
        counter = counter + 1
    end)
end

return self
