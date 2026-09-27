LocalAccountManager = {}

function LocalAccountManager.getLocalAccountInfo()
	local user_path = HeResPathUtils:getUserDataPath()
	local file = io.open(user_path.."/data01", "r")
	if file == nil then
		return -1
	end
	local content = file:read()
	file:close()
	local decodeStr = PlatformMgr:getInstance():decodeData(content)
	if decodeStr ~= nil then    -----文件的解密结果会有n个\x02\x02，所以要去掉
		decodeStr = string.match(decodeStr, "{[^}]+}")
		local retTable = table.deserialize(decodeStr)
		return retTable
	else
		return -1
	end
end

function LocalAccountManager.saveLocalAccountInfo(infoTable)
	local user_path = HeResPathUtils:getUserDataPath()
	local file = io.open(user_path.."/data01", "w")
	if file == nil then
		return
	end
	local content = table.serialize(infoTable)
	local finalStr = PlatformMgr:getInstance():encodeData(content)
	file:write(finalStr)
	file:close()
end

string.split = function(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

function LocalAccountManager.getSameUsernameTable()
	local usernameStr = CCString:createWithContentsOfFile("twinlist.txt"):getCString()
	usernameTable = string.split(usernameStr, "\n")
	return usernameTable
end