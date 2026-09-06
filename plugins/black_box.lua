local self = {}
self.version = 0.91
self.loadPrio = 1000

local data = {}


function self:register(env)
    _ENV = env


    register:addAction("onUpdate", "black_box", function()
        print(clock(),  SensorAPI.getYaw())
    end)
end

return self
