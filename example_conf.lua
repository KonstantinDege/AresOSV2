local self = {}
self.version = 0.91
self.loadPrio = 1000

self.vel = {
    vel_right = "$5",
    vel_down  = "$6",
    vel_for   = "$7",
}
self.redstone = {
    pitch_up   = "$1@right",
    pitch_down = "$1@left",
}

return self
