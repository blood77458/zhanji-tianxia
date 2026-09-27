require "hecore.luaJavaConvert"

local wdjSdk = nil
     
local isLoginWdj = false
local isCheckingWdjId = false

local Wdj_StatusCode = {
    NORMAL_LOGIN = 3,
    NEW_REGISTER = 4,
}

if isWdjAndroid == nil then
	require "canon.data.ThirdPlatformLogin"
end

if isWdjAndroid()  then
    wdjSdk = luajava.bindClass("com.happyelements.canon.wdj.WdjGameSdk")
end

function getWdjSid()
    if wdjSdk then
        return url_encode(wdjSdk:getWdjUToken())
    end
end

function getWdjUid()
    if wdjSdk then
        return url_encode(wdjSdk:getWdjUid())
    end
end

function getWdjUName()
    if wdjSdk then
        return wdjSdk:getWdjUName()
    end
end 

function getIsLoginWdj()
    return isLoginWdj
end

local preventContinueLogin = false
function loginWdj(afterLoginFunc)
    if wdjSdk ~= nil and not isLoginWdj and not preventContinueLogin then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        isCheckingWdjId = false
		preventContinueLogin = true
        he_log_info("+++++++++++++++++++++++++++Wdj Log:start login++++++++++++++++++++++++++++++++")
        local loginWdj_callback = luajava.createProxy("com.happyelements.canon.wdj.WdjCanonCallback",
            {
                onSuccess = function(statusCode)
					preventContinueLogin = false
                    if statusCode ~= nil then
                        DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                        he_log_info("+++++++++++++++++++++++++++Wdj Log:login Success(statusCode = ".. statusCode ..")++++++++++++++++++++++++++++++++")
                        isLoginWdj = true
                        local wdj_token = getWdjSid()
                        local wdj_uid = getWdjUid()
                        local wdj_uname = getWdjUName()
                        --he_log_info("+++++++++++++++++++++++++++Wdj Log:login Success(sid = ".. wdj_token ..")++++++++++++++++++++++++++++++++")
                        --he_log_info("+++++++++++++++++++++++++++Wdj Log:login Success(uid = " .. wdj_uid .. ")++++++++++++++++++++++++++++++++")
                        --he_log_info("+++++++++++++++++++++++++++Wdj Log:login Success(uname = " .. wdj_uname .. ")++++++++++++++++++++++++++++++++")
                        
                        local function checkWdjId()
                            if isCheckingWdjId then
                                return
                            end
                            isCheckingWdjId = true
                            DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                            he_log_info("+++++++++++++++++++++++++++Wdj Log:start check wandoujia id++++++++++++++++++++++++++++++++")
                            local url = DataManager.SystemConfig.CheckWdjIdUrl
                            
                            --he_log_info("+++++++++++++++++++++++++++Wdj Log:check wandoujia id url:"..url.."++++++++++++++++++++++++++++++++")
                            local request = HttpRequest:createPost(url)
                            
                            local timeout = 10
                            
                            request:setConnectionTimeoutMs(timeout * 1000)
                            
                            request:setTimeoutMs(timeout * 1000)
                            
                            request:addHeader("Content-Type:application/x-www-form-urlencoded")
                            
                            local dataString ="sessionId="..wdj_token
                            
                            dataString = dataString .. "&uid="..wdj_uid
							
							dataString = dataString .. "&gspId=7806507808"
                            
                            local dataStringLen = dataString:len()
                            
                            request:setPostData(dataString, dataStringLen)

                            
                            local function onCheckWdjIdFinish(response)
                                --he_log_info("+++++++++++++++++++++++++++Wdj Log:Check Wdj id finish(response.body = "..response.body..",response.httpCode = "..response.httpCode.."++++++++++++++++++++++++++++++++")
								local function checkNetWorkErr()
									--he_log_error("+++++++++++++++++++++++++++Wdj Log:check Wdj id error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
                                    CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("popup_networkError"),
                                        nil,
                                        {
                                            text = getTextByKey("retry"),
                                            callbackFunc = function()
                                                isCheckingWdjId = false
                                                checkWdjId()
                                            end
                                        }
                                    )
								end
								
								if response.httpCode ~= 200 then
									checkNetWorkErr()
									return
								end
								
                                if response.body == nil or response.body == "" then
                                    checkNetWorkErr()
                                    return
                                end
                                         
                                local rTable = table.deserialize(response.body)		
                                if rTable.code ~= 0 then
                                    checkNetWorkErr()
                                    return
                                end
                                
                                DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                                he_log_info("+++++++++++++++++++++++++++Wdj Log:check wandoujia id success:++++++++++++++++++++++++++++++++")
                                if afterLoginFunc and type(afterLoginFunc) == "function" then
                                    he_log_info("+++++++++++++++++++++++++++Wdj Log:run afterLoginFunc++++++++++++++++++++++++++++++++")
                                    afterLoginFunc()
                                end
                            end
                            DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                            HttpClient:getInstance():sendRequest(onCheckWdjIdFinish, request)
                            
                        end
                        checkWdjId()           
                        
                    end
                end,
                onFail = function(returnCode,info)
					preventContinueLogin = false
                    he_log_error("+++++++++++++++++++++++++++Wdj Log:login failed statusCode = "..returnCode..",info = "..info.."++++++++++++++++++++++++++++++++")
                end
            }
        )

        

        local  logoutCallback=luajava.createProxy("com.happyelements.canon.wdj.WdjCanonCallback",
            {
                onSuccess = function(statusCode)
                    isLoginWdj = false
                    wdjSdk:logoutWdj()
                    he_log_error("+++++++++++++++++++++++++++Wdj :logout success++++++++++++++++++++++++++++++++")
                     ---清除本地数据
                    DataManager.clearData()
                    DcManager.closeUserOnlineActivity()
                    TCPManager:sharedInstance():closeConnect()

                    --add by Geng.Men 退出登陆的时候清除武将强化主卡数据，防止玩家申请小号的时候在武将强化教程的部分卡死
                    HeMemDataHolder:deleteByKey("CardCompose_MainCardId")
                    UnionChatContainerPanel.resetChatContentView()
                    Director:sharedDirector():replaceScene(LoginScene:create())
                    isCheckingWdjId = false  

                    end,
                 onFail = function(returnCode,info)
                    
                    he_log_error("+++++++++++++++++++++++++++Wdj Log:login failed statusCode = "..returnCode..",info = "..info.."++++++++++++++++++++++++++++++++")
                end

              }
            )   
        

        wdjSdk:setLogoutResultCallBackFunc(logoutCallback)
        wdjSdk:setLoginResultCallBackFunc(loginWdj_callback)
        wdjSdk:loginWdj()
    end 
end 

function logoutWdj(afterLogoutFunc)
     if wdjSdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++Wdj Log:logout++++++++++++++++++++++++++++++++")
        wdjSdk:logoutWdj()
        os.execute("sleep"..1)
        isLoginWdj = false
        -- if afterLogoutFunc and type(afterLogoutFunc) == "function" then
        --     he_log_info("+++++++++++++++++++++++++++Wdj Log:begin run logout after func++++++++++++++++++++++++++++++++")
        --     afterLogoutFunc()
        -- end      
    end
end 


