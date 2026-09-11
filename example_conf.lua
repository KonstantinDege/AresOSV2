local self = {}
self.version = 0.91
self.loadPrio = 1000

self.vel = {
    vel_right = "$5",
    vel_down  = "$6",
    vel_for   = "$7",
}
self.redstone = {
    left   = "$9@left",
    right = "$9@right",
    forward = "$8@left",
    backward = "$8@right",
    up = "$3@front",
}

return self
