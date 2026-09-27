require "hecore.luaJavaConvert"
require "canon.luajava.ND91StatusCode"

local dkSdk = nil
     
local isSdkInit = false
local isLoginDK = false
local isCheckingDKid = false

local dk_sid = -999
local dk_loginUin = -999
local dk_userName = ""

if isDKAndroid()  then
    dkSdk = luajava.bindClass("com.nd.complatform.ND91GameSdk")
end

function getDKSid()
	return dk_sid
end

function getDKUid()
	return dk_loginUin
end

function getDKUserName()
	return dk_userName
end

function getIsLoginDK()
    return isLoginDK
end 

function loginDK(afterLoginDKFunc)
    if dkSdk ~= nil and not isLoginDK then
        he_log_info("+++++++++++++++++++++++++++douku Log:start login++++++++++++++++++++++++++++++++")
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
		
		local function afterLoginDKFunc1()
			DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
			isLoginDK = true         
			dk_sid = dkSdk:get91SessionID()
			dk_loginUin = dkSdk:get91LoginUin()
			if dk_loginUin == nil then
				isLoginDK = false        
                Director:sharedDirector():replaceScene(LoginScene:create()) 
				return
			end
			--he_log_info("+++++++++++++++++++++++++++dk Log:login Success(sid = "..dk_sid..")++++++++++++++++++++++++++++++++")
			--he_log_info("+++++++++++++++++++++++++++dk Log:login Success(uin = " .. dk_loginUin .. ")++++++++++++++++++++++++++++++++")
			
			local function checkDKid()
				if isCheckingDKid then
					return
				end
				isCheckingDKid = true
				DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
				he_log_info("+++++++++++++++++++++++++++dk Log:start check dk id++++++++++++++++++++++++++++++++")
				local url = DataManager.SystemConfig.CheckDKIdUrl
				url = url .."sessionId="..dk_sid.."&uin="..dk_loginUin
				--he_log_info("+++++++++++++++++++++++++++dk Log:check dk id url:"..url.."++++++++++++++++++++++++++++++++")
				local request = HttpRequest:createPost(url)
				
				local function onCheckDKidFinish(response)
					he_log_info("+++++++++++++++++++++++++++dk Log:Check dk id finish ++++++++++++++++++++++++++++++++")
					isCheckingDKid = false		
                                --local tstr = table.serialize(response)
                                --he_log_info("+++++++++++++++++++++++++++dk Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
					local function checkNetWorkErr()
						CanonMessageBox.showText(
							ShowButtonType.ID_OK,
							getTextByKey("popup_networkError"),
							nil,
							{
								text = getTextByKey("retry"),
								callbackFunc = function()
									checkDKid()
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
						--he_log_error("+++++++++++++++++++++++++++dk Log:check dk id error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
						checkNetWorkErr()
						return
					end
					--local fields = response.body:split(",")
					dk_loginUin = rTable.Uin
					--dk_userName = rTable.userName--新协议去掉该字段
					if dk_userName == nil then
						dk_userName = "nil_null"
					end
					--he_log_info("+++++++++++++++++++++++++++dk Log:check uc id success:(Uin="..dk_loginUin..",userName="..dk_userName..")++++++++++++++++++++++++++++++++")
					DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
					if afterLoginDKFunc and type(afterLoginDKFunc) == "function" then
						he_log_info("+++++++++++++++++++++++++++dk Log:run afterLoginDKFunc++++++++++++++++++++++++++++++++")
						afterLoginDKFunc()
					end
				end
				DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
				HttpClient:getInstance():sendRequest(onCheckDKidFinish, request)
				
			end
			checkDKid()
		end
		
        local loginDK_callback = luajava.createProxy("com.nd.complatform.ND91CanonCallback",
            {
                onResponse = function(statusCode)
                    if statusCode == g_ND91Sdk_SUCCESS then
                        afterLoginDKFunc1()
                        
                    else
                        he_log_error("+++++++++++++++++++++++++++dk Log:login failed statusCode = "..statusCode.."++++++++++++++++++++++++++++++++")
                        
                    end
                end
            }
        )
        
		local changeDK_callback = luajava.createProxy("com.nd.complatform.ND91CanonCallback",
            {
                onResponse = function(statusCode)
                    if statusCode == g_ND91Sdk_SUCCESS or statusCode == g_ND91Sdk_LOGIN_FAIL or g_ND91Sdk_SESSION_INVALID then
                        
                        isLoginDK = false        
                       
                        Director:sharedDirector():replaceScene(LoginScene:create())    
                        
                        
                   
                        
                    end
                end
            }
        )
        dkSdk:setLoginResultCallBackFunc(loginDK_callback)
		dkSdk:setChangeResultCallBackFunc(changeDK_callback)
		if dkSdk:isLogined91() then
			afterLoginDKFunc1()
		else
			dkSdk:login91()
		end
    end 
end

function logoutDK(afterLogoutFunc)
    if dkSdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++DK Log:logout++++++++++++++++++++++++++++++++")
        
        dkSdk:logout91()
        os.execute("sleep"..1)
		isLoginDK = false
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++DK Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end      
    end
end

function showDKFloatButton(isShow)
    if dkSdk ~= nil then
        if isShow then
            he_log_info("+++++++++++++++++++++++++++DK Log:show FloatButton++++++++++++++++++++++++++++++++")
        else
            he_log_info("+++++++++++++++++++++++++++DK Log:hide FloatButton++++++++++++++++++++++++++++++++")
        end
         
        dkSdk:show91ToolBar(isShow)
    end
end 
