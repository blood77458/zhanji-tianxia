require "hecore.luaJavaConvert"

local joloplaySdk = nil
     
local isLoginJoloplay = false
local isChangingAccount = false
local isCheckingJoloplayId = false
local LogTag = "Joloplay"

if isJoloplayAndroid()  then
    joloplaySdk = luajava.bindClass("com.happyelements.canon.joloplay.JoloplayGameSdk")
end

function isJoloplayLogin()
    return isLoginJoloplay
end

function getJoloplayAccountSign()
    if joloplaySdk then
        return joloplaySdk:getJoloplayUtk()
    end
end

function getJoloplayAccount()
    if joloplaySdk then
        return url_encode(joloplaySdk:getJoloplayAccount())
    end
end

function getJoloplayUid()
    if joloplaySdk then
        return joloplaySdk:getJoloplayUserid()
    end
end
function  getJoloplaySid()
    if joloplaySdk then
        return url_encode(joloplaySdk:getJoloplayAccountSign())
    end
end

function getJoloplayUsername()
    if joloplaySdk then
        return joloplaySdk:getJoloplayUsername()
    end
end

function loginJoloplay(afterLoginFunc)

    if joloplaySdk ~= nil and  not isLoginJoloplay then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        isCheckingJoloplayId = false
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:start login++++++++++++++++++++++++++++++++")
        local login_callback = luajava.createProxy("com.happyelements.canon.joloplay.JoloplayCanonCallback",
            {
                onSucc = function( statusCode)
                    
                    DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login success++++++++++++++++++++++++++++++++")
                    isLoginJoloplay = true
                    isChangingAccount = false
                    local joloplay_sid = getJoloplaySid()
                    local joloplay_uid = getJoloplayUid()
					local joloplay_Session = getJoloplayUsername()
                    local joloplay_Account = getJoloplayAccount()
					local joloplay_AccountSign = getJoloplayAccountSign()

                    --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login Success(sid = "..joloplay_sid..")++++++++++++++++++++++++++++++++")
                    --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login Success(uid = " .. joloplay_uid .. ")++++++++++++++++++++++++++++++++")
                        
                    local function checkId()
					he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:bggin checkId++++++++++++++++++++++++++++++++")
                        if isCheckingJoloplayId then
						he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:bggin isCheckingJoloplayId++++++++++++++++++++++++++++++++")
                            return
                        end
						he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:bggin isCheckingJoloplayId----end  ++++++++++++++++++++++++++++++++")
                        isCheckingJoloplayId = true
                        DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:start check id++++++++++++++++++++++++++++++++")
                        local url = DataManager.SystemConfig.CheckPlatformIdUrl
                            
                       
                        url = url .."sessionId="..joloplay_sid.."&account="..getJoloplayAccount().."&uid="..getJoloplayUid()
                            
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
                                            isCheckingJoloplayId = false
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
        
        
       
        
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:run login account++++++++++++++++++++++++++++++++")
        if isChangingAccount then
            joloplaySdk:logoutJoloplay()
        else
            joloplaySdk:loginJoloplay(login_callback)
        end
        
    end 
end

function logoutJoloplay(afterLogoutFunc)
    if joloplaySdk ~= nil and isLoginJoloplay then
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:logout++++++++++++++++++++++++++++++++")
        isLoginJoloplay = false
        isChangingAccount = false 
		isCheckingJoloplayId = false
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end
                 
        local logout_callback = luajava.createProxy("com.happyelements.canon.joloplay.JoloplayCanonCallback",
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
        joloplaySdk:logoutJoloplay(logout_callback)    
        
    end
end
