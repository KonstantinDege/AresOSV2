local self = {}
self.version = 0.91
self.loadPrio = 1000

local slots = nil
local rs = nil

local m = 0
local M = 11

local function binary_switch(input, r1, r2)
    if input > 0 then
        rs.setOutput(r1, true)
        rs.setOutput(r2, false)
    elseif input < 0 then
        rs.setOutput(r1, false)
        rs.setOutput(r2, true)
    else
        rs.setOutput(r1, false)
        rs.setOutput(r2, false)
    end
end

function self:register(env)
    _ENV = env
    slots = getPlugin("slots")

    rs = getPlugin("redstone")
    local ticker = 0

    print("Flight Loaded")
    register:addAction("onUpdate", "flight", function()
        local forward = slots.getToggleState("w_s")
        local side = slots.getToggleState("a_d")
        local up = slots.getToggleState("space")
        binary_switch(forward, "forward", "backward")
        binary_switch(side, "left", "right")
        rs.setAnalogOutput("up", ticker)
    end)

    register:addAction("spaceHold", "up", function() 
        if ticker <= 15 then
            ticker = ticker+1
        end
    end)
    register:addAction("leftShiftHold", "down", function() 
        if ticker >= 0 then
            ticker = ticker-1
        end
    end)
end

return self
