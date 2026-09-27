require "canon.utils.TimeUtil"

localStorage = {}

function localStorage.getCurrentUser()
  local user_path = HeResPathUtils:getUserDataPath()
  local file = io.open(user_path.."/user.dat","r")
  if file == nil then
    return "-1"
  else
    local content = file:read()
    file:close()  
    return content
  end
end

function localStorage.setCurrentUser( content )
  local fields = content:split(",")
  local uid = tonumber(fields[1])
  if(uid <= 0) then
    he_log_warning("failed to setCurrentUser, content:" .. content)
    return false
  end
  
	local user_path = HeResPathUtils:getUserDataPath()
	--local full_path = user_path.."/user.dat"
	--lua_write_atom_file(full_path, content)
  
  local file = io.open(user_path.."/user.dat","w")
  file:write( content )
  file:close()
  
  return true
end

function localStorage.getUserInfo( user_id  ) 
  local user_path = HeResPathUtils:getUserDataPath()
  local file,err = io.open(user_path.."/"..user_id..".txt","r")
  local user_data = ""
  if file then
      user_data = table.deserialize(file:read()) --json to table
      file:close()  
  end  
  return user_data
end

function localStorage.saveUserInfo( user_id ,user_data )
  local user_path = HeResPathUtils:getUserDataPath()
	--local full_path = user_path.."/"..user_id..".txt"
	--lua_write_atom_file(full_path, table.serialize( user_data ))
  local file = io.open(user_path.."/"..user_id..".txt","w")
  file:write( table.serialize( user_data ) ) --table to json
  file:close()
end

--user chose server info
function localStorage.getLastChoseServerInfo(   ) 
  local user_path = HeResPathUtils:getUserDataPath()
  local file,err = io.open(user_path.."/lastChoseServer.txt","r")
  local user_data = ""
  if file then
      user_data = table.deserialize(file:read()) --json to table
      file:close()  
  end  
  return user_data
end

function localStorage.saveChoseServerInfo( server_data )
  local user_path = HeResPathUtils:getUserDataPath()
	--local full_path = user_path.."/lastChoseServer.txt"
	--lua_write_atom_file(full_path, table.serialize( server_data ))
  local file = io.open(user_path.."/lastChoseServer.txt","w")
  file:write( table.serialize( server_data ) ) --table to json
  file:close()
end

function localStorage.getSoulPrayerCardId()
  local user_path = HeResPathUtils:getUserDataPath()
  local file = io.open(user_path.."/soulPrayer.dat","r")
  if file == nil then
    return
  else
    local content = file:read()
    file:close()  
    return tonumber(content)
  end
end

function localStorage.setSoulPrayerCardId( content )
	local user_path = HeResPathUtils:getUserDataPath()
	--local full_path = user_path.."/user.dat"
	--lua_write_atom_file(full_path, content)
  
  local file = io.open(user_path.."/soulPrayer.dat","w")
  file:write( content )
  file:close()
  
  return true
end

--
--user facebook share info
function localStorage.getShouldFacebbookShareInfo(   ) 
  local user_path = HeResPathUtils:getUserDataPath()
  local file,err = io.open(user_path.."/facebookshare.txt","r")
  local user_data = ""
  if file then
      user_data = table.deserialize(file:read()) --json to table
      file:close()  
  end  
  return user_data
end

function localStorage.saveShouldFacebbookShareInfo( data )
  local user_path = HeResPathUtils:getUserDataPath()
  local file = io.open(user_path.."/facebookshare.txt","w")
  file:write( table.serialize( data ) ) --table to json
  file:close()
end