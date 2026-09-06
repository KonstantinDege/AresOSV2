local self = {}
self.version = 0.91
self.loadPrio = 1000

self.vel = {
    "$2": "vel_right",
    "$2": "vel_down",
    "$2": "vel_for",
}
self.redstone = {
    "$1@right": "pitch_up",
    "$1@left": "pitch_down",
}

return self
