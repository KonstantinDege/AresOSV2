local self = {}
self.version = 0.91
self.loadPrio = 1000

local counter = 0
local skip = 40
local data = {}
local slots = nil

function self:register(env)
    _ENV = env
    slots = getPlugin("slots")

    register:addAction("onUpdate", "black_box", function()
        counter = counter + 1
        if counter % skip == 0 then
            print(os.clock(),  SensorAPI.getYaw(), slots.getToggleState("w_s"))
        end
    end)
    register:addAction("wStart", "test", function()
        print("W pressed")
    end)
    getPlugin("optional", false, "", true)
end

return self
