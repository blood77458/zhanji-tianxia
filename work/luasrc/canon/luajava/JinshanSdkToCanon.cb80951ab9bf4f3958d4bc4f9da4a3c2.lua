require "hecore.luaJavaConvert"

local jinshanSdk = nil
     
local isLoginJinshan = false
local isChangingAccount = false
local isCheckingJinshanId = false
local LogTag = "Jinshan"

if isJinshanAndroid()  then
    jinshanSdk = luajava.bindClass("com.happyelements.canon.JinshanGameSdk")
end

function isJinshanLogin()
    return isLoginJinshan
end

function getJinshanSid()
    if jinshanSdk then
        return jinshanSdk:getJinshanUtk()
    end
end

function getJinshanUid()
    if jinshanSdk then
        return jinshanSdk:getJinshanUserid()
    end
end

function loginJinshan(afterLoginFunc)
    if jinshanSdk ~= nil and  not isLoginJinshan then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        isCheckingJinshanId = false
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:start login++++++++++++++++++++++++++++++++")
        local login_callback = luajava.createProxy("com.happyelements.canon.JinshanCanonCallback",
            {
                onSucc = function( statusCode)
                    
                    DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login success++++++++++++++++++++++++++++++++")
                    isLoginJinshan = true
                    isChangingAccount = false
                    local jinshan_sid = getJinshanSid()
                    local jinshan_uid = getJinshanUid()
                    --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login Success(sid = "..jinshan_sid..")++++++++++++++++++++++++++++++++")
                    --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login Success(uid = " .. jinshan_uid .. ")++++++++++++++++++++++++++++++++")
                        
                    local function checkId()
                        if isCheckingJinshanId then
                            return
                        end
                        isCheckingJinshanId = true
                        DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:start check id++++++++++++++++++++++++++++++++")
                        local url = DataManager.SystemConfig.CheckPlatformIdUrl
                            
                        --he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:check id url:"..url.."++++++++++++++++++++++++++++++++")
                        url = url .."token="..jinshan_sid.."&ip="..MetaInfo:getInstance():getIpAddress().."&uid="..getJinshanUid()
                            
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
                                            isCheckingJinshanId = false
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
       
        
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:run login account++++++++++++++++++++++++++++++++")
        if isChangingAccount then
            jinshanSdk:logoutJinshan()
        else
            jinshanSdk:loginJinshan(login_callback)
        end
        
    end 
end

function logoutJinshan(afterLogoutFunc)
    if jinshanSdk ~= nil and isLoginJinshan then
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:logout++++++++++++++++++++++++++++++++")
        isLoginJinshan = false
        isChangingAccount = true
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end
        --[[            
        local logout_callback = luajava.createProxy("com.happyelements.canon.JinshanCanonCallback",
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
        jinshanSdk:logoutJinshan(logout_callback)    
        --]]
    end
end
