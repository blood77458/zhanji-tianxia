require "hecore.luaJavaConvert"

local jinliSdk = nil
     
local isLoginJinli = false
local isCheckingJinliId = false
local LogTag = "Jinli"

if isJinliAndroid()  then
    jinliSdk = luajava.bindClass("com.happyelements.canon.JinliGameSdk")
end

function isJinliLogin()
    return isLoginJinli
end

function getJinliSid()
    if jinliSdk then
        return jinliSdk:getJinliToken()
    end
end

function getJinliUid()
    if jinliSdk then
        return jinliSdk:getJinliPid()
    end
end

function loginJinli(afterLoginFunc)
    if jinliSdk ~= nil and  not isLoginJinli then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        isCheckingJinliId = false
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:start login++++++++++++++++++++++++++++++++")
        local login_callback = luajava.createProxy("com.happyelements.canon.JinliCanonCallback",
            {
                onSucc = function( statusCode)
                    
                    DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login success++++++++++++++++++++++++++++++++")
                    isLoginJinli = true         
                    local jinli_sid = getJinliSid()
                    local jinli_uid = getJinliUid()
                    --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login Success(sid = "..jinli_sid..")++++++++++++++++++++++++++++++++")
                    --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login Success(uid = " .. jinli_uid .. ")++++++++++++++++++++++++++++++++")
                        
                    local function checkId()
                        if isCheckingJinliId then
                            return
                        end
                        isCheckingJinliId = true
                        DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:start check id++++++++++++++++++++++++++++++++")
                        local url = DataManager.SystemConfig.CheckPlatformIdUrl
                            
                        --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:check id url:"..url.."++++++++++++++++++++++++++++++++")
                        url = url .."token="..jinli_sid.."&uid="..jinli_uid
                            
                        local request = HttpRequest:createPost(url)
                            
                            
                        local function onCheckIdFinish(response)
                            he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:Check jinli id finish ++++++++++++++++++++++++++++++++")
                                
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
                                            isCheckingJinliId = false
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
                            
                            if rTable.code ~= 1 then
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
        local logout_callback = luajava.createProxy("com.happyelements.canon.JinliCanonCallback",
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

                end,
                onFail = function(statusCode,info) 
                end
            }
        )
        jinliSdk:setJinliLogoutCallback(logout_callback)
        
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:run login account++++++++++++++++++++++++++++++++")
        jinliSdk:jinliLogin(login_callback)
        
    end 
end

function logoutJinli(afterLogoutFunc)
    if jinliSdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:logout++++++++++++++++++++++++++++++++")
        isLoginJinli = false
        
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end 
            
    end
end
