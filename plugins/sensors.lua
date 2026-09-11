local self = {}
self.version = 0.91
self.loadPrio = 1000

local sensors = nil

function self:register(env)
    _ENV = env
    local slots = getPlugin("slots")

    sensors = slots.getSensors()
end

function self.getAlt()
    if slots["altitude_sensor"] ~= nil then
        return slots["altitude_sensor"].getHeight()
    end
    print("Altitude sensor not found")
    return nil
end
function self.getPressure()
    if slots["altitude_sensor"] ~= nil then
        return slots["altitude_sensor"].getAirPressure()
    end
    print("Altitude sensor not found")
    return nil
end
function self.getVelDown()
    if sensors["vel_down"] ~= nil then
        return sensors["vel_down"].getVelocity()
    end
    print("VelocityDown sensor not found")
    return nil
end
function self.getVelFor()
    if sensors["vel_for"] ~= nil then
        return sensors["vel_for"].getVelocity()
    end
    print("VelocityForward sensor not found")
    return nil
end
function self.getVelRight()
    if sensors["vel_right"] ~= nil then
        return sensors["vel_right"].getVelocity()
    end
    print("VelocityRight sensor not found")
    return nil
end
function self.getVel()
    return vector.new(self.getVelFor() or 0, self.getVelRight() or 0, self.getVelDown() or 0)
end

function self.getYaw()
    if slots["navball"] ~= nil then
        return slots["navball"].getYaw()
    end
    print("Navball not found")
    return nil
end
function self.getPitch()
    if slots["navball"] ~= nil then
        return slots["navball"].getPitch()
    end
    print("Navball not found")
    return nil
end
function self.getRoll()
    if slots["navball"] ~= nil then
        return slots["navball"].getRoll()
    end
    print("Navball not found")
    return nil
end
function self.getAttitude()
    return vector.new(self.getRoll() or 0, self.getPitch() or 0, self.getYaw() or 0)
end

return self
