local function post(data)
    http.post("http://skeleti.asuscomm.com:8000/recorder", data)
end

local function getlocals(l)
  local i = 0
  local direction = 1
  return function ()
    i = i + direction
    local k,v = debug.getlocal(l,i)
    if (direction == 1 and (k == nil or k.sub(k,1,1) == '(')) then 
      i = -1 
      direction = -1 
      k,v = debug.getlocal(l,i) 
    end
    return k,v
  end
end


local function dumpsig(f)
  assert(type(f) == 'function', 
    "bad argument #1 to 'dumpsig' (function expected)")
  local p = {}
  pcall (function() 
    local oldhook
    local hook = function(event, line)
      for k,v in getlocals(3) do 
        if k == "(*vararg)" then 
          table.insert(p,"...") 
          break
        end 
        table.insert(p,k) end
      debug.sethook(oldhook)
      error('aborting the call')
    end
    oldhook = debug.sethook(hook, "c")
    -- To test for vararg must pass a least one vararg parameter
    f(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20)
  end)
  return "function("..table.concat(p,",")..")"  
end


local function print_table(data, sub)
    if type(data) == "table" then
        for k, v in pairs(data) do 
            if k ~= "_G" then
                post(sub.."."..k..": "..tostring(v))
                print_table(v, sub.."."..k)
            end
        end
        return
    end
    if type(data) == "function" then
        post(
            sub.." "..dumpsig(data)
        )

        if sub ~= nil and #sub >= 12 and string.sub(sub, -12) == "pullEventRaw" then
          return
        end

        if string.sub(sub, -4) == "exit" then return end
        if string.sub(sub, -8) == "shutdown" then return end
        if string.sub(sub, -9) == "pullEvent" then return end
        if string.sub(sub, -6) == "reboot" then return end
        if string.sub(sub, -11) == "getregistry" then return end
        if string.sub(sub, -7) == "getfenv" then return end
        if string.sub(sub, -5) == "yield" then return end
        if string.sub(sub, -7) == "receive" then return end

        res, v = pcall(data)
        if res then
            if v ~= nil and type(v) ~= "table" then
                post(sub.."() =>", v)
            end
            print_table(v, sub.."()")
        end
        
        return
    end 
end

print_table(_G, "_G")