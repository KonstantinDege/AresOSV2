local self = {}
self.version = 0.91
self.loadPrio = 1000

local counter = 0
local skip = 10
local data = {}


function self:register(env)
    _ENV = env


    register:addAction("onUpdate", "black_box", function()
        counter = counter + 1
        if counter % skip == 0 then
            return
        end
        print(os.clock(),  SensorAPI.getYaw())
        for k,v in pairs(SensorAPI) do
            print(k,v())
        end
    end)
end

return self
