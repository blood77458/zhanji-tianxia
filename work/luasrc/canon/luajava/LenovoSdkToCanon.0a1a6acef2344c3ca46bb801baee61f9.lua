require "hecore.luaJavaConvert"

local muwanSdk = nil
     
local isLoginMuwan = false
local isChangingAccount = false
local isCheckingMuwanId = false
local LogTag = "Lenovo"

if isLenovoAndroid()  then
    lenovoSdk = luajava.bindClass("com.happyelements.canon.lenovo.LenovoGameSdk")
end

function isLenovoLogin()
    return isLoginLenovo
end

function getLenovoSid()
    if lenovoSdk then
        return lenovoSdk:getLenovoToken()
    end
end

function getLenovoUid()
   
        return lenovo_uid
 
end

function showLenovoExitPic()
    if lenovoSdk then
        lenovoSdk:onBackPressed()
    end
end

function loginLenovo(afterLoginFunc)
    if lenovoSdk ~= nil and  not isLoginLenovo then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        isCheckingLenovoId = false
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:start login++++++++++++++++++++++++++++++++")
        local login_callback = luajava.createProxy("com.happyelements.canon.lenovo.LenovoCanonCallback",
            {
                onSucc = function( statusCode)
                    DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login success++++++++++++++++++++++++++++++++")
                    isLoginLenovo = true
                    isChangingAccount = false
                    local lenovo_sid = getLenovoSid()
                    --local muwan_uid --= getMuwanUid()
                    --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login Success(sid = "..lenovo_sid..")++++++++++++++++++++++++++++++++")
                    --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login Success(uid = " .. lenovo_uid .. ")++++++++++++++++++++++++++++++++")
                        
                    local function checkId()
                        if isCheckingLenovoId then
                            return
                        end
                        isCheckingLenovoId = true
                        DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:start check id++++++++++++++++++++++++++++++++")
                        local url = DataManager.SystemConfig.CheckLenovoIdUrl
                            
                        --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:check id url:"..url.."++++++++++++++++++++++++++++++++")
                        url = url .."sessionId=" .. lenovo_sid
                            
                        local request = HttpRequest:createPost(url)
                            
                            
                        local function onCheckIdFinish(response)
                            he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:Check id finish ++++++++++++++++++++++++++++++++")
                         						
                            --local tstr = table.serialize(response)
                            --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
							local function checkNetWorkErr()
								CanonMessageBox.showText(
                                    ShowButtonType.ID_OK,
                                    getTextByKey("popup_networkError"),
                                    nil,
                                    {
                                        text = getTextByKey("retry"),
                                        callbackFunc = function()
                                            isCheckingLenovoId = false
                                            checkId()
                                        end
                                    }
                                )
							end
							
							if response.httpCode ~= 200 then
								checkNetWorkErr()
								return
							end
							
                            local rTable = table.deserialize(response.body)		
                            lenovo_uid = rTable.uid
                            if rTable.code ~= "1" then
                                --he_log_error("+++++++++++++++++++++++++++".. LogTag .. " Log:check id error:response.httpCode ="..response.httpCode..",rTable.code="..rTable.code.."++++++++++++++++++++++++++++++++")
                                checkNetWorkErr()
                                return
                            end
                            DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                            if afterLoginFunc and type(afterLoginFunc) == "function" then
                                he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:run afterLoginFunc++++++++++++++++++++++++++++++++")
                                afterLoginFunc()
                            end
                        end
                        DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                        HttpClient:getInstance():sendRequest(onCheckIdFinish, request)
                            
                    end
                    checkId()
                end,
                onFail = function(statusCode,info) 
                    he_log_error("+++++++++++++++++++++++++++".. LogTag .. " Log:Login failed statusCode = "..statusCode..",info = " .. info .. "++++++++++++++++++++++++++++++++")
                end
            }
        )
        
        --
       
        
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:run login account++++++++++++++++++++++++++++++++")
        if isChangingAccount then
            lenovoSdk:logoutLenovo()
        else
            lenovoSdk:getTokenByQuickLogin(login_callback)
        end
        
    end 
end

function logoutLenovo(afterLogoutFunc)
    if lenovoSdk ~= nil and isLoginLenovo then
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:logout++++++++++++++++++++++++++++++++")
        isLoginLenovo = false
        isChangingAccount = false--
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end
        --[[            
        local logout_callback = luajava.createProxy("com.happyelements.canon.lenovo.LenovoCanonCallback",
        {
                onSucc = function( statusCode)
                    ---清除本地数据
                    DataManager.clearData()
                    DcManager.closeUserOnlineActivity()
                    TCPManager:sharedInstance():closeConnect()

                    --add by Geng.Men 退出登陆的时候清除武将强化主卡数据，防止玩家申请小号的时候在武将强化教程的部分卡死
                    HeMemDataHolder:deleteByKey("CardCompose_MainCardId")
                    UnionChatContainerPanel.resetChatContentView()
                    Director:sharedDirector():replaceScene(LoginScene:create())

                    g_previousPlayerStrength = nil--清空前面账号的战斗力缓存
                    
                    if afterLogoutFunc and type(afterLogoutFunc) == "function" then
                        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:begin run logout after func++++++++++++++++++++++++++++++++")
                        afterLogoutFunc()
                    end 

                end,
                onFail = function(statusCode,info) 
                end
            }
        )
        lenovoSdk:logoutLenovo(logout_callback)    
        --]]
    end

    
end


