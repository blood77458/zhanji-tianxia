--http://lua-users.org/wiki/SplitJoin

function string:split(sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

function string:escape()
    return (self:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1'):gsub('%z','%%z'))
end

function string:strip(pattern)
  local s = self
  pattern = pattern or "%s+"
  local _s = s:gsub("^" .. pattern, "")
  while _s ~= s do
    s = _s;
    _s = s:gsub("^" .. pattern, "")
  end
  _s = s:gsub(pattern .. "$", "")
  while _s ~= s do
    s = _s;
    _s = s:gsub(pattern .. "$", "")
  end
  return s
end

function setTimeOut(func, time)
  local scheduleScriptFuncID
  time = time or 1
  local function onScheduleScriptFunc()
    if func then func() end
    if scheduleScriptFuncID ~= nil then CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(scheduleScriptFuncID) end
  end
  scheduleScriptFuncID = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(onScheduleScriptFunc,time,false)
end

function table.clone(t, nometa)
  local u = {}

  if not nometa then
    setmetatable(u, getmetatable(t))
  end

  for i, v in pairs(t) do
    if type(v) == "table" then
      u[i] = table.clone(v, nometa)
    else
      u[i] = v
    end
  end

  return u
end

function table.indexOf(t, v)
    for i, v_ in ipairs(t) do
        if v_ == v then return i end
    end
    return nil
end

function table.keyOf(t, v)
    for k, v_ in pairs(t) do
        if v_ == v then return k end
    end
    return nil
end


function table.includes(t, value)
  return table.indexOf(t, value)
end

function table.removeValue(t, value)
  local index = table.indexOf(t, value)
  if index then table.remove(t, index) end
  return t
end

function table.unique(t)
  local seen = {}
  for i, v in ipairs(t) do
    if not table.includes(seen, v) then table.insert(seen, v) end
  end

  return seen
end

function table.union(t0, t1)
    local t = {}
    for i, v in ipairs(t0) do table.insert(t, v) end
    for i, v in ipairs(t1) do table.insert(t, v) end
    return t
end

function table.merge(t0, t1)
    local t = {}
    for k, v in pairs(t0) do t[k] = v end
    for k, v in pairs(t1) do t[k] = v end
    return t
end

function table.removeAll(t)
    for i = 1, #t do t[i] = nil end
    for k, v in pairs(t) do t[k] = nil; end
end

function table.keys(t)
  local keys = {}
  for k, v in pairs(t) do table.insert(keys, k) end
  return keys
end

function table.values(t)
  local values = {}
  for k, v in pairs(t) do table.insert(values, v) end
  return values
end

function table.last(t)
  return t[#t]
end

function table.append(t, moreValues)
  for i, v in ipairs(moreValues) do
    table.insert(t, v)
  end

  return t
end

function table.each(t, func)
  for k, v in pairs(t) do
    func(v, k)
  end
end

function table.find(t, func)
  for k, v in pairs(t) do
    if func(v) then return v, k end
  end

  return nil
end

function table.filter(t, func)
  local matches = {}
  for k, v in pairs(t) do
    if func(v) then table.insert(matches, v) end
  end

  return matches
end

function table.groupBy(t, func)
  local grouped = {}
  for k, v in pairs(t) do
    local groupKey = func(v)
    if not grouped[groupKey] then grouped[groupKey] = {} end
    table.insert(grouped[groupKey], v)
  end

  return grouped
end

function table.tostring(tbl, indent, limit, depth, jstack)
  limit   = limit  or 1000
  depth   = depth  or 7
  jstack  = jstack or {name="top"}
  local i = 0

  local output = {}
  if type(tbl) == "table" then
    -- very important to avoid disgracing ourselves with circular referencs...
    if depth <= 0 then
      return "{...}\n"
    end
    for i,t in pairs(jstack) do
      if tbl == t then
        return "<" .. i .. ">,\n"
      end
    end
    jstack[jstack.name] = tbl

    table.insert(output, "{\n")

    local name = jstack.name
    for key, value in pairs(tbl) do
      local innerIndent = (indent or " ") .. (indent or " ")
      table.insert(output, innerIndent .. tostring(key) .. " = ")
      jstack.name = name .. "." .. tostring(key)
      table.insert(output,
        value == tbl and "<parent>," or table.tostring(value, innerIndent, limit, depth-1, jstack)
      )

      i = i + 1
      if i > limit then
        table.insert(output, (innerIndent or "") .. "...\n")
        break
      end
    end

    table.insert(output, indent and (indent or "") .. "},\n" or "}")
  else
    if type(tbl) == "string" then tbl = "\"" .. string.format("%q", tbl) .. "\"" end -- quote strings
    table.insert(output, tostring(tbl) .. ",\n")
  end

  return table.concat(output)
end

function table.insertIfNotExist(t, v)
    if t then
        if not table.indexOf(t, v) then table.insert(t, v) end
    else
        t = {v}
    end
    return t
end
function table.removeIfExist(t, v)
    if t then
        local i = table.indexOf(t, v)
        if i then return table.remove(t, i) end
        for k, v_ in pairs(t) do
            if v_ == v then t[k] = nil; return v_; end
        end
    end
    return nil
end

function table.size(t)
    local s = 0;
    for k,v in pairs(t) do
        if v ~= nil then s = s+1; end
    end
    return s;
end

function table.getNotKV(t,i)
    local index = 0;
    local key,value = nil,nil;
    for k,v in pairs(t) do
        if v ~= nil then
            index = index + 1; 
            if index == i then
                value = v;
                key = k;
                break; 
            end 
        end
    end
    return key, value;
end

function table.exist(t,v)
    for k,v_ in pairs(t) do
        if v_ == v then
            return true;
        end
    end
    return false;
end

--
-- Just For Test Phase ---------------------------------------------------------------------------------
--

local function printConstTable(t)
    print("---------------- Constants Table Error -----------------")
    for k, v in pairs(t) do print(k, v) end
end

function table.bean(c, b)
    if __RESTRICT_BEAN then
        local proxy = {}
        local metadata = {
            __o = b,
            __c = c,
            __index = function(t, k)
                if not c[k] then
                    printConstTable(t)
                    error("fail to retrieve undefined key '" .. k .. "' from a bean table.", 2)
                end
                return rawget(b, k)
            end,
            __newindex = function(t, k, v)
                local t_f = c[k]
                if t_f then
                    if nil == v and ("number" ~= t_f) or type(v) == t_f then      -- 匹配原始数据类型，仅number可以设置为nil
                        rawset(b, k, v)
                    else
                        local mt = getmetatable(v)
                        if mt and mt.__c == t_f then                              -- 匹配自定义数据类型
                            rawset(b, k, v)
                        else
                            local c_metadata = getmetatable(c)
                            if c_metadata and type(c_metadata.__o) == "table" then printConstTable(c_metadata.__o) end
                            error("fail to modify a bean table for key '" .. k .. "' with a value of '" .. type(v) .. "'", 2)
                        end
                    end
                else
                    printConstTable(t)
                    error("fail to modify a bean table with key of '" .. k .. "'", 2)
                end
            end
        }
        setmetatable(proxy, metadata)
        return proxy
    else
        return b
    end
end

function table.serialize(t)
  local _json = require("cjson")
  return _json.encode(t)
end

function table.deserialize(str)
  local _json = require("cjson")
  return _json.decode(str)
end

function table.const(t)
    if __RESTRICT_BEAN then
        local const = {}
        local metadata = {
            __o = t,
            __index = function(a, k)
                local v = t[k]
                if nil == v then
                    printConstTable(t)
                    error("fail to retrieve undefined key '" .. k .. "' from a constants table.", 2)
                end
                return v
            end,
            __newindex = function(a, k, b)
                printConstTable(t)
                error("fail to modify a constants table with key of '" .. k .. "'", 2)
            end
        }
        setmetatable(const, metadata)
        return const
    else
        return t
    end
end

table.class = table.const

function table.debug(t, tab)
    if __DEBUG_OUTPUT then
        local prev = ""
        if type(tab) == "number" then 
            for i = 1, tab do prev = prev .. "\t" end
        end
            
        if #t > 0 then
            for i, v in ipairs(t) do 
                print(prev, i, v) 
                if type(v) == "table" then
                    table.debug(v, type(tab) == "number" and (tab + 1) or 1)
                end
            end
        else
            local object = false
            for k, v in pairs(t) do
                object = true
                print(prev, k, v) 
                if type(v) == "table" then
                    table.debug(v, type(tab) == "number" and (tab + 1) or 1)
                end
            end
            if not object then print(prev, "... empty ...") end
        end
    end
end

Type = table.const {
    kNumber = "number",
    kString = "string",
    kBoolean = "boolean",
    kArray = "table",
    kTable = "table"
}

function getTextByKey( keyName, params )
  if(params) then
    return Localization:getInstance():getText( keyName, params )
  else
    return Localization:getInstance():getText( keyName )
  end
end

-- 将table中的string通过sep字符串连接到一起 成为一个新字符串
-- t 字符串table 不能为nil 不能含有字符串以外元素 不能是哈希
-- sep 间隔符 字符串 不能为nil 可以是空字符串
-- *此方法和string.split(str, sep)互逆
function table.join(t, sep)
  local result = ""
  local size = #t
  for i, v in ipairs(t) do
    result = result .. v
    if i < size then
      result = result .. sep
    end
  end
  return result
end


--
-- Tests ---------------------------------------------------------------------------------------------
--

--[[
local T_STRING = "string"
local Class = table.class{ 
            prop1 = T_STRING, prop2 = T_STRING, prop3 = T_STRING, 
            dynamic1 = T_STRING, dynamic2 = T_STRING, dynamic3 = T_STRING 
        }
local bean = table.bean(Class, {
            prop1 = "Prop1",
            prop2 = "Prop2",
            prop3 = "Prop3",
        })

print(bean.prop1, bean.prop2, bean.prop3, bean.dynamic1, bean.dynamic2, bean.dynamic3)
bean.prop1 = nil
bean.dynamic1 = "Dynamic1"
print(bean.prop1, bean.prop2, bean.prop3, bean.dynamic1, bean.dynamic2, bean.dynamic3)
bean.dynamic2 = true                -- raise error here
bean.notexsit = true                -- raise error here
print(bean.notexsit)                -- raise error here
--]]
