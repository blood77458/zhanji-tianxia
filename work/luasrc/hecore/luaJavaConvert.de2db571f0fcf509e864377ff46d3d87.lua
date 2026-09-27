if __ANDROID then
    
    luaJavaConvert = {}

    local _java_class = luajava.bindClass("java.lang.Class")
    local _collection_class = _java_class:forName("java.util.Collection")
    local _map_class = _java_class:forName("java.util.Map")
    local _arr_class = luajava.bindClass("java.lang.reflect.Array")
    local _helper_class = luajava.bindClass("com.happyelements.android.LuaHelper")

    local function _convertValue(v)
      if v ~= nil and type(v) == "userdata" then
        local v_class = v:getClass()
        if _collection_class:isAssignableFrom(v_class) then
          v = luaJavaConvert.list2Table(v)
        elseif _map_class:isAssignableFrom(v_class) then
          v = luaJavaConvert.map2Table(v)
        elseif v_class:isArray() then
          v = luaJavaConvert.array2Table(v)
        end
      end
      return v
    end

    -- java中的map转换为lua中的table
    function luaJavaConvert.map2Table(map)
      local result = {}
      local ite = map:entrySet():iterator()
      while ite:hasNext() do
        local kv = ite:next()
        local k = kv:getKey()
        local v = kv:getValue()
        result[k] = _convertValue(v)
      end
      return result
    end

    -- java中的list转换为lua中的table
    function luaJavaConvert.list2Table(list)
      local result = {}
      local ite = list:iterator()
      while ite:hasNext() do
        local v = ite:next()
        result[#result + 1] = _convertValue(v)
      end
      return result
    end
    
    -- java中的数组转换为lua中的table
    function luaJavaConvert.array2Table(arr)
      local result = {}
      local len = _arr_class:getLength(arr)
      for i = 1, len do
        local v = _arr_class:get(arr, i - 1)
        result[#result + 1] = _convertValue(v)
      end
      return result
    end

    -- lua中数组风格的table转换为java中的list
    function luaJavaConvert.table2List(t)
      local list = luajava.newInstance("java.util.ArrayList")
      for i,v in ipairs(t) do
        list:add(v)
      end
      return list
    end

    -- lua中的table转换为java中的map
    function luaJavaConvert.table2Map(t)
      local map = luajava.newInstance("java.util.HashMap")
      for k,v in pairs(t) do
        map:put(k, v)
      end
      return map
    end
    
    -- lua中的table转换为java中的int array
    function luaJavaConvert.table2IntArray(t)
      local size = table.maxn(t)
      local arr = _helper_class:createIntArray(size)
      for i = 1, size do
        _arr_class:setInt(arr, i - 1, t[i])
      end
      return arr
    end
    
    -- lua中的table转换为java中的double array
    function luaJavaConvert.table2DoubleArray(t)
      local size = table.maxn(t)
      local arr = _helper_class:createDoubleArray(size)
      for i = 1, size do
        _arr_class:setDouble(arr, i - 1, t[i])
      end
      return arr
    end
    
    -- lua中的table转换为java中的float array
    function luaJavaConvert.table2FloatArray(t)
      local size = table.maxn(t)
      local arr = _helper_class:createFloatArray(size)
      for i = 1, size do
        _arr_class:setFloat(arr, i - 1, t[i])
      end
      return arr
    end
    
    -- lua中的table转换为java中的String array
    function luaJavaConvert.table2StringArray(t)
      local size = table.maxn(t)
      local arr = _helper_class:createStringArray(size)
      for i = 1, size do
        _arr_class:set(arr, i - 1, t[i])
      end
      return arr
    end
    
end

