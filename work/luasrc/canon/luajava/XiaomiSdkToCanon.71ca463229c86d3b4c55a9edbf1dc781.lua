require "hecore.luaJavaConvert"
require "canon.luajava.XiaomiStatusCode"

local xiaomiSdk = nil
     
local isLoginXiaomi = false
local isCheckingXiaomiId = false

local xiaomi_sid = -999
local xiaomi_loginUid = -999

if isXiaomiAndroid()  then
    xiaomiSdk = luajava.bindClass("com.xiaomi.complatform.XiaomiGameSdk")
end

function getXiaomiSid()
    return xiaomi_sid
end

function getXiaomiLoginUid()
    return xiaomi_loginUid
end

function getIsLoginXiaomi()
    return isLoginXiaomi
end

function loginXiaomi(afterLoginXiaomiFunc)
    if xiaomiSdk ~= nil and not isLoginXiaomi then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        isCheckingXiaomiId = false
        he_log_info("+++++++++++++++++++++++++++Xiaomi Log:start login++++++++++++++++++++++++++++++++")
        local loginXiaomi_callback = luajava.createProxy("com.xiaomi.complatform.XiaomiCanonCallback",
            {
                onResponse = function(statusCode)
                    if statusCode == g_XiaomiSdk_LOGIN_SUCCESS then
                        DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                        isLoginXiaomi = true
                        xiaomi_sid = xiaomiSdk:getXiaomiSessionId()
                        xiaomi_loginUid = xiaomiSdk:getXiaomiUid()
                        --he_log_info("+++++++++++++++++++++++++++Xiaomi Log:login Success(sid = ".. xiaomi_sid ..")++++++++++++++++++++++++++++++++")
                        --he_log_info("+++++++++++++++++++++++++++Xiaomi Log:login Success(uid = " .. xiaomi_loginUid .. ")++++++++++++++++++++++++++++++++")
                        
                        local function checkXiaomiId()
                            if isCheckingXiaomiId then
                                return
                            end
                            isCheckingXiaomiId = true
                            DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                            he_log_info("+++++++++++++++++++++++++++Xiaomi Log:start check xiaomi id++++++++++++++++++++++++++++++++")
                            local url = DataManager.SystemConfig.CheckXiaomiIdUrl
                            url = url .."uid="..xiaomi_loginUid.."&sessionId="..xiaomi_sid.."&gspId=7800106702"
                            --he_log_info("+++++++++++++++++++++++++++Xiaomi Log:check xiaomi id url:"..url.."++++++++++++++++++++++++++++++++")
                            local request = HttpRequest:createPost(url)
                            
                            local function onCheckXiaomiIdFinish(response)
                                --he_log_info("+++++++++++++++++++++++++++Xiaomi Log:Check Xiaomi id finish(response.body = "..response.body..",response.httpCode = "..response.httpCode.."++++++++++++++++++++++++++++++++")
                                --isCheckingXiaomiId = false     
								local function checkNetWorkErr()
									--he_log_error("+++++++++++++++++++++++++++Xiaomi Log:check Xiaomi id error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
                                    CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("popup_networkError"),
                                        nil,
                                        {
                                            text = getTextByKey("retry"),
                                            callbackFunc = function()
                                                isCheckingXiaomiId = false
                                                checkXiaomiId()
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
                                    checkNetWorkErr()
                                    return
                                end
                                
                                DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                                he_log_info("+++++++++++++++++++++++++++Xiaomi Log:check Xiaomi id success:++++++++++++++++++++++++++++++++")
                                if afterLoginXiaomiFunc and type(afterLoginXiaomiFunc) == "function" then
                                    he_log_info("+++++++++++++++++++++++++++Xiaomi Log:run afterLoginXiaomiFunc++++++++++++++++++++++++++++++++")
                                    afterLoginXiaomiFunc()
                                end
                            end
                            DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                            HttpClient:getInstance():sendRequest(onCheckXiaomiIdFinish, request)
                            
                        end
                        checkXiaomiId()
                        
                    else
                        he_log_error("+++++++++++++++++++++++++++Xiaomi Log:login failed statusCode = "..statusCode.."++++++++++++++++++++++++++++++++")
                        
                    end
                end
            }
        )
        
        xiaomiSdk:setLoginResultCallBackFunc(loginXiaomi_callback)
        xiaomiSdk:loginXiaomi()
    end 
end 

function logoutXiaomi(afterLogoutFunc)
     if xiaomiSdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++Xiaomi Log:logout++++++++++++++++++++++++++++++++")
        local logoutXiaomi_callback = luajava.createProxy("com.xiaomi.complatform.XiaomiCanonCallback",
            {
                onResponse = function(statusCode)
                    if statusCode == g_XiaomiSdk_LOGOUT_SUCCESS then
                        isLoginXiaomi = false
                        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
                            he_log_info("+++++++++++++++++++++++++++Xiaomi Log:begin run logout after func++++++++++++++++++++++++++++++++")
                            afterLogoutFunc()
                        end 
                    else
                        he_log_error("+++++++++++++++++++++++++++Xiaomi Log:logout failed statusCode = "..statusCode.."++++++++++++++++++++++++++++++++")
                        
                    end
                end
            }
        )
        
        xiaomiSdk:setLogoutResultCallBackFunc(logoutXiaomi_callback)
        xiaomiSdk:logoutXiaomi()
    end
end 

function openXiaomiMainEnter()
    if xiaomiSdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++Xiaomi Log:ready to show xiaomi main enter++++++++++++++++++++++++++++++++")
        xiaomiSdk:openXiaomiMainEnter()
    end 
end
