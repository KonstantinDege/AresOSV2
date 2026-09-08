local self = {}
self.version = 0.91
self.loadPrio = 1000

function self:register(env)
    _ENV = env
    print("Plugin list registered.")
    slots = getPlugin("flightdatarecorder", true)
end

return self
