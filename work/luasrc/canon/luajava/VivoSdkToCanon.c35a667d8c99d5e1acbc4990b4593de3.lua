require "hecore.luaJavaConvert"

local vivoSdk = nil
     
local isLoginVivo = false
local isCheckingVivoId = false
local isSwitchAccount = false

if isVivoAndroid()  then
    vivoSdk = luajava.bindClass("com.happyelements.canon.VivoGameSdk")
end

function isVivoLogin()
    return isLoginVivo
end

function getVivoSid()
    if vivoSdk then
        return vivoSdk:getVivoAuthToken()
    end
end

function getVivoUid()
    if vivoSdk then
        return vivoSdk:getVivoOpenid()
    end
end

function loginVivo(afterLoginFunc)
    if vivoSdk ~= nil and  not isLoginVivo then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        isCheckingVivoId = false
        he_log_info("+++++++++++++++++++++++++++Vivo Log:start login++++++++++++++++++++++++++++++++")
        local loginVivo_callback = luajava.createProxy("com.happyelements.canon.VivoCanonCallback",
            {
                onSucc = function( statusCode)
                    
                    DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++Vivo Log:login success++++++++++++++++++++++++++++++++")
                    isLoginVivo = true         
                    local vivo_sid = getVivoSid()
                    local vivo_uid = getVivoUid()
                    --he_log_info("+++++++++++++++++++++++++++Vivo Log:login Success(sid = "..vivo_sid..")++++++++++++++++++++++++++++++++")
                    --he_log_info("+++++++++++++++++++++++++++Vivo Log:login Success(uid = " .. vivo_uid .. ")++++++++++++++++++++++++++++++++")
                        
                    local function checkVivoId()
                        if isCheckingVivoId then
                            return
                        end
                        isCheckingVivoId = true
                        DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                        he_log_info("+++++++++++++++++++++++++++Vivo Log:start check anzhi id++++++++++++++++++++++++++++++++")
                        local url = DataManager.SystemConfig.CheckPlatformIdUrl
                            
                        --he_log_info("+++++++++++++++++++++++++++Vivo Log:check vivo id url:"..url.."++++++++++++++++++++++++++++++++")
                        url = url .."sid="..vivo_sid.."&user_id="..vivo_uid
                            
                        local request = HttpRequest:createPost(url)
                            
                            
                        local function onCheckIdFinish(response)
                            he_log_info("+++++++++++++++++++++++++++Vivo Log:Check anzhi id finish ++++++++++++++++++++++++++++++++")
                                
                            --local tstr = table.serialize(response)
                            --he_log_info("+++++++++++++++++++++++++++Vivo Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
							local function checkNetWorkErr()
								CanonMessageBox.showText(
                                    ShowButtonType.ID_OK,
                                    getTextByKey("popup_networkError"),
                                    nil,
                                    {
                                        text = getTextByKey("retry"),
                                        callbackFunc = function()
                                            isCheckingVivoId = false
                                            checkVivoId()
                                        end
                                    }
                                )
							end
							
							if response.httpCode ~= 200 then
								checkNetWorkErr()
								return
							end
							
                            local rTable = table.deserialize(response.body)		
                            
                            if rTable.code ~= 200 then
                                --he_log_error("+++++++++++++++++++++++++++Vivo Log:check vivo id error:response.httpCode ="..response.httpCode..",rTable.code="..rTable.code.."++++++++++++++++++++++++++++++++")
                                checkNetWorkErr()
                                return
                            end
                            DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                            if afterLoginFunc and type(afterLoginFunc) == "function" then
                                he_log_info("+++++++++++++++++++++++++++Vivo Log:run afterLoginFunc++++++++++++++++++++++++++++++++")
                                afterLoginFunc()
                            end
                        end
                        DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                        HttpClient:getInstance():sendRequest(onCheckIdFinish, request)
                            
                    end
                    checkVivoId()
                end,
                onFail = function(statusCode,info) 
                    he_log_error("+++++++++++++++++++++++++++Vivo Log:Login failed statusCode = "..statusCode..",info = " .. info .. "++++++++++++++++++++++++++++++++")
                end
            }
        )
        
        --
        if isSwitchAccount then
            he_log_info("+++++++++++++++++++++++++++Vivo Log:run switch account++++++++++++++++++++++++++++++++")
            vivoSdk:switchAccountVivo(loginVivo_callback)
            isSwitchAccount = false
        else
            he_log_info("+++++++++++++++++++++++++++Vivo Log:run login account++++++++++++++++++++++++++++++++")
            vivoSdk:loginVivo(loginVivo_callback)
        end
    end 
end

function logoutVivo(afterLogoutFunc,logoutAccount)
    if vivoSdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++Vivo Log:logout++++++++++++++++++++++++++++++++")
        isLoginVivo = false
        isSwitchAccount = logoutAccount
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++Vivo Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end 
            
    end
end
