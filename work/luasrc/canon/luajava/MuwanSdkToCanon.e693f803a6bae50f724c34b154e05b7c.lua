require "hecore.luaJavaConvert"

local muwanSdk = nil
     
local isLoginMuwan = false
local isChangingAccount = false
local isCheckingMuwanId = false
local LogTag = "Muwan"

if isMuwanAndroid()  then
    muwanSdk = luajava.bindClass("com.happyelements.canon.muwan.MuwanGameSdk")
end

function isMuwanLogin()
    return isLoginMuwan
end

function getMuwanSid()
    if muwanSdk then
        return muwanSdk:getMuwanToken()
    end
end

function getMuwanUid()
   
        return muwan_uid
 
end

function loginMuwan(afterLoginFunc)
    if muwanSdk ~= nil and  not isLoginMuwan then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        isCheckingMuwanId = false
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:start login++++++++++++++++++++++++++++++++")
        local login_callback = luajava.createProxy("com.happyelements.canon.muwan.MuwanCanonCallback",
            {
                onSucc = function( statusCode)
                    DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login success++++++++++++++++++++++++++++++++")
                    isLoginMuwan = true
                    isChangingAccount = false
                    local muwan_sid = getMuwanSid()
                    --local muwan_uid --= getMuwanUid()
                    --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login Success(sid = "..muwan_sid..")++++++++++++++++++++++++++++++++")
                    --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login Success(uid = " .. muwan_uid .. ")++++++++++++++++++++++++++++++++")
                        
                    local function checkId()
                        if isCheckingMuwanId then
                            return
                        end
                        isCheckingMuwanId = true
                        DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:start check id++++++++++++++++++++++++++++++++")
                        local url = DataManager.SystemConfig.CheckMuzhiwanIdUrl
                            
                        --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:check id url:"..url.."++++++++++++++++++++++++++++++++")
                        url = url .."sessionId="..muwan_sid
                            
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
                                            isCheckingMuwanId = false
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
                            muwan_uid = rTable.uid
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
       
        
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:run login account++++++++++++++++++++++++++++++++")
        if isChangingAccount then
            muwanSdk:logoutMuwan()
        else
            muwanSdk:loginMuwan(login_callback)
        end
        
    end 
end

function logoutMuwan(afterLogoutFunc)
    if muwanSdk ~= nil and isLoginMuwan then
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:logout++++++++++++++++++++++++++++++++")
        isLoginMuwan = false
        isChangingAccount = false--
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end
        --            
        local logout_callback = luajava.createProxy("com.happyelements.canon.muwan.MuwanCanonCallback",
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
        muwanSdk:logoutMuwan(logout_callback)    
        --
    end
end
