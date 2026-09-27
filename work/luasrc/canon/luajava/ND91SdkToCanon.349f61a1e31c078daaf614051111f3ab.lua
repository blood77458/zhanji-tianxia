require "hecore.luaJavaConvert"
require "canon.luajava.ND91StatusCode"

local nd91sdk = nil
     
local isSdkInit = false
local isLogin91 = false
local isChecking91id = false

local nd91_sid = -999
local nd91_loginUin = -999
local nd91_userName = ""

if is91Android()  then
    nd91sdk = luajava.bindClass("com.nd.complatform.ND91GameSdk")
end

function getIs91SdkInit()
    isSdkInit = nd91sdk:isInitSucc()
    return isSdkInit
end 

function show91FloatButton(isShow)
    if nd91sdk ~= nil then
        if isShow then
            he_log_info("+++++++++++++++++++++++++++91 Log:show FloatButton++++++++++++++++++++++++++++++++")
        else
            he_log_info("+++++++++++++++++++++++++++91 Log:hide FloatButton++++++++++++++++++++++++++++++++")
        end
         
        nd91sdk:show91ToolBar(isShow)
    end
end 

function get91Sid()
    return nd91_sid
end

function get91LoginUin()
    return nd91_loginUin
end

function get91UserName()
    return nd91_userName
end

function login91(afterLogin91Func)
    if nd91sdk ~= nil and getIs91SdkInit() and not isLogin91 then
        he_log_info("+++++++++++++++++++++++++++91C Log:start login++++++++++++++++++++++++++++++++")
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
		
		local function afterLogin91()
			DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
			isLogin91 = true         
			nd91_sid = nd91sdk:get91SessionID()
			nd91_loginUin = nd91sdk:get91LoginUin()
			--he_log_info("+++++++++++++++++++++++++++91 Log:login Success(sid = "..nd91_sid..")++++++++++++++++++++++++++++++++")
			--he_log_info("+++++++++++++++++++++++++++91 Log:login Success(uin = " .. nd91_loginUin .. ")++++++++++++++++++++++++++++++++")
			
			local function check91id()
				if isChecking91id then
					return
				end
				isChecking91id = true
				DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
				he_log_info("+++++++++++++++++++++++++++91 Log:start check 91 id++++++++++++++++++++++++++++++++")
				local url = DataManager.SystemConfig.Check91idUrl
				url = url .."sessionId="..nd91_sid.."&uin="..nd91_loginUin
				--he_log_info("+++++++++++++++++++++++++++91 Log:check 91 id url:"..url.."++++++++++++++++++++++++++++++++")
				local request = HttpRequest:createPost(url)
				
				local function onCheck91idFinish(response)
					he_log_info("+++++++++++++++++++++++++++91 Log:Check 91 id finish ++++++++++++++++++++++++++++++++")
					isChecking91id = false		
                                --local tstr = table.serialize(response)
                                --he_log_info("+++++++++++++++++++++++++++91 Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
					local function checkNetWorkErr()
						CanonMessageBox.showText(
							ShowButtonType.ID_OK,
							getTextByKey("popup_networkError"),
							nil,
							{
								text = getTextByKey("retry"),
								callbackFunc = function()
									check91id()
								end
							}
						)
					end
					
					if response.httpCode ~= 200 then
						checkNetWorkErr()
						return
					end 
					local rTable = table.deserialize(response.body)		
					if rTable.code ~= 1 then
						--he_log_error("+++++++++++++++++++++++++++91 Log:check 91 id error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
						checkNetWorkErr()
						return
					end
					--local fields = response.body:split(",")
					nd91_loginUin = rTable.Uin
					--nd91_userName = rTable.userName--新协议去掉该字段
					if nd91_userName == nil then
						nd91_userName = "nil_null"
					end
					--he_log_info("+++++++++++++++++++++++++++91 Log:check uc id success:(Uin="..nd91_loginUin..",userName="..nd91_userName..")++++++++++++++++++++++++++++++++")
					DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
					if afterLogin91Func and type(afterLogin91Func) == "function" then
						he_log_info("+++++++++++++++++++++++++++91 Log:run afterLogin91Func++++++++++++++++++++++++++++++++")
						afterLogin91Func()
					end
				end
				DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
				HttpClient:getInstance():sendRequest(onCheck91idFinish, request)
				
			end
			check91id()
		end
		
        local login91_callback = luajava.createProxy("com.nd.complatform.ND91CanonCallback",
            {
                onResponse = function(statusCode)
                    if statusCode == g_ND91Sdk_SUCCESS then
                        afterLogin91()
                        
                    else
                        he_log_error("+++++++++++++++++++++++++++91 Log:login failed statusCode = "..statusCode.."++++++++++++++++++++++++++++++++")
                        
                    end
                end
            }
        )
        
		local change91_callback = luajava.createProxy("com.nd.complatform.ND91CanonCallback",
            {
                onResponse = function(statusCode)
                    if statusCode == g_ND91Sdk_SUCCESS or statusCode == g_ND91Sdk_LOGIN_FAIL or g_ND91Sdk_SESSION_INVALID then
                        
                        isLogin91 = false        
                       
                        Director:sharedDirector():replaceScene(LoginScene:create())    
                        
                        
                   
                        
                    end
                end
            }
        )
        nd91sdk:setLoginResultCallBackFunc(login91_callback)
		nd91sdk:setChangeResultCallBackFunc(change91_callback)
		if nd91sdk:isLogined91() then
			afterLogin91()
			
		else
			nd91sdk:login91()
			
		end
    end 
end 

function logout91(afterLogoutFunc)
    if nd91sdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++91 Log:logout++++++++++++++++++++++++++++++++")
        nd91sdk:logout91()
        os.execute("sleep"..1)
        isLogin91 = false
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++91 Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end      
    end
end 
