--------------------------------------------------------------------------------
-- SystemInfoCall.lua - 游戏系统配置及状态获取统一管理
-- author: xiaojie.bai
-- date: 2013-09-26 10:53
--------------------------------------------------------------------------------

SystemInfoCall = {}

local domainUrl = StartupConfig:getInstance():getGameDomain()
local systemInfoUrl = domainUrl .. "/systemInfo"

local function deftCallback(response)
  if response.errorCode==0 and response.httpCode==200 then 
    local data = amf3.decode(response.body)
    
    he_log_info("systemInfo: " .. table.tostring(data))
    
    local ts = data.ts or os.time()
    _G.__g_utcDiffSeconds = os.difftime(ts, os.time())
  else
    he_log_error("get gameSystemInfo meet error, response detail:")
    he_log_error(table.tostring(response))
  end
end

function SystemInfoCall.getData(callback)
  local _callback = callback
  if(not _callback) then
    _callback = deftCallback
  end
  
  local request = HttpRequest:createPost(systemInfoUrl)
  HttpClient:getInstance():sendRequest(_callback, request)
end