local isLogin_kuaiyong = false
local isChecking_kuaiyong_id = false

local kuaiyong_token = -999
local kuaiyong_loginUid = -999

function getIos_kuaiyongSid()
    return kuaiyong_token
end
    
function getIos_kuaiyongUid()
    return kuaiyong_loginUid
end
    
function loginKuaiyong_ios(afterLoginFunc)
    if not isLogin_kuaiyong then
        he_log_info("+++++++++++++++++++++++++++kuaiyongios Log:start login++++++++++++++++++++++++++++++++")
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        local function login_kuaiyong_callback(isSuccess,info)
            if isSuccess then
                DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                isLogin_kuaiyong = true
                kuaiyong_token = KYGameSdk:getKYLoginToken()
                
                local function check_kuaiyong_id()
                    RequestLoadingBox:createLoadingBox(false)
                    RequestLoadingBox:showLoadingBox()
                    if isChecking_kuaiyong_id then
                        return
                    end
                    
                    isChecking_kuaiyong_id = true
                    
                    DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++kuaiyongios Log:start check kuaiyong id++++++++++++++++++++++++++++++++")
                    local url = DataManager.SystemConfig.CheckIosKuaiYongUrl
                    url = url .."sid="..kuaiyong_token
                    --he_log_info("+++++++++++++++++++++++++++kuaiyongios Log:check kuaiyong id url:"..url.."++++++++++++++++++++++++++++++++")

                    local request = HttpRequest:createPost(url)
                            
                    local function onCheckKuaiyongidFinish(response)
                        RequestLoadingBox:removeLoadingBox()
                        he_log_info("+++++++++++++++++++++++++++kuaiyongios Log:Check kuaiyong id finish ++++++++++++++++++++++++++++++++")
                        
                        isChecking_kuaiyong_id = false	
                        
                        --local tstr = table.serialize(response)
                        --he_log_info("+++++++++++++++++++++++++++kuaiyongios Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
						local function checkErr()
							CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("popup_networkError"),
                                        nil,
                                        {
                                            text = getTextByKey("retry"),
                                            callbackFunc = function()
                                                check_kuaiyong_id()
                                            end
                                        }
                                    )
						end
						
						if response.httpCode ~= 200 then
							checkErr()
							return
						end
						
                        local rTable = table.deserialize(response.body)
                        kuaiyong_loginUid = rTable.user_id

                        if rTable.code ~= 0 then
                            --he_log_error("+++++++++++++++++++++++++++kuaiyongios Log:check kuaiyong id error:"..rTable.code.."++++++++++++++++++++++++++++++++")
                            checkErr()
                            return
                        end
                            
                        DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                        if afterLoginFunc and type(afterLoginFunc) == "function" then
                            he_log_info("+++++++++++++++++++++++++++kuaiyongios Log:run afterLoginFunc++++++++++++++++++++++++++++++++")
                            afterLoginFunc()
                        end
                    end
                    DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                    HttpClient:getInstance():sendRequest(onCheckKuaiyongidFinish, request)
                end
                check_kuaiyong_id()
            else
                he_log_error("+++++++++++++++++++++++++++kuaiyongios Log:login failed info = "..info.."++++++++++++++++++++++++++++++++")   
                if isLogin_kuaiyong then
                    --logout from usercenter
                    isLogin_kuaiyong = false
                    Director:sharedDirector():replaceScene(LoginScene:create())
                else
                    --cancel loginKuaiyong do nothing
                end 
            end 
        end 
        
        PlatformMgr:getInstance():registerLoginHandler(login_kuaiyong_callback)
        KYGameSdk:loginKuaiYong()
    end
end

function logoutKuaiyong_ios(afterLogoutFunc)
    if isLogin_kuaiyong then
        he_log_info("+++++++++++++++++++++++++++kuaiyongios Log:logout++++++++++++++++++++++++++++++++")
    
        --KYGameSdk:logoutKuaiyong()
        os.execute("sleep"..1)
        isLogin_kuaiyong = false
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++kuaiyongios Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end  
    end
end

function showKuaiyongGameCenter_ios()
    KYGameSdk:showGameCenterKuaiyong()
end


