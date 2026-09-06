local self = {}
self.version = 0.91
self.loadPrio = 1000

local counter = 0
local skip = 20
local data = {}
local slots = nil

function self:register(env)
    _ENV = env
    slots = getPlugin("slots")

    register:addAction("onUpdate", "black_box", function()
        counter = counter + 1
        if counter % skip == 0 then
            return
        end

        print(os.clock(),  SensorAPI.getYaw(), slot.getToggleState("w_s"))

    end)
    register:addAction("wStart", "test", function()
        print("W pressed")
    end)
end

return self
