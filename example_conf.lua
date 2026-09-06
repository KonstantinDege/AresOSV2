local self = {}
self.version = 0.91
self.loadPrio = 1000

self.vel = {
    vel_right = "$2",
    vel_down  = "$2",
    vel_for   = "$2",
}
self.redstone = {
    pitch_up   = "$1@right",
    pitch_down = "$1@left",
}

return self
