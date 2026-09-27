local isLogin_haima = false
local isChecking_haima_id = false

local haima_token = -999
local haima_loginUid = -999

function getIos_haimaSid()
    return haima_token
end
    
function getIos_haimaUid()
    return haima_loginUid
end
    
function loginHaima_ios(afterLoginFunc)
    if not isLogin_haima then
        he_log_info("+++++++++++++++++++++++++++haimaios Log:start login++++++++++++++++++++++++++++++++")
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        local function login_haima_callback(isSuccess,info)
            if isSuccess then
                DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                isLogin_haima = true
                haima_token = "haimaSDK"
                haima_loginUid = haimaGameSdk:getHaimaLoginUid()
                --he_log_info("+++++++++++++++++++++++++++haimaios Log:login Success(sid = "..haima_token..")++++++++++++++++++++++++++++++++")
                --he_log_info("+++++++++++++++++++++++++++haimaios Log:login Success(uin = " .. haima_loginUid .. ")++++++++++++++++++++++++++++++++")
                
                local function check_haima_id()
                    if isChecking_haima_id then
                        return
                    end
                    
                    isChecking_haima_id = true
                    
                    DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++haimaios Log:start check haima id++++++++++++++++++++++++++++++++")
                    local url = DataManager.SystemConfig.CheckIosHaimaidUrl
                    url = url .."sid="..haima_token.."&user_id="..haima_loginUid
                    --he_log_info("+++++++++++++++++++++++++++haimaios Log:check haima id url:"..url.."++++++++++++++++++++++++++++++++")
                    local request = HttpRequest:createPost(url)
                            
                    local function onCheckHaimaidFinish(response)
                        he_log_info("+++++++++++++++++++++++++++haimaios Log:Check haima id finish ++++++++++++++++++++++++++++++++")
                        
                        isChecking_haima_id = false	
                        	
                        --local tstr = table.serialize(response)
                        --he_log_info("+++++++++++++++++++++++++++haimaios Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
						local function checkErr()
							CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("popup_networkError"),
                                        nil,
                                        {
                                            text = getTextByKey("retry"),
                                            callbackFunc = function()
                                                check_haima_id()
                                            end
                                        }
                                    )
						end
						
						if response.httpCode ~= 200 then
							checkErr()
							return
						end
						
                        local rTable = table.deserialize(response.body)		
                        if rTable.code ~= 1 then
                            --he_log_error("+++++++++++++++++++++++++++haimaios Log:check haima id error:"..rTable.code.."++++++++++++++++++++++++++++++++")
                            checkErr()
                            return
                        end
                            
                        DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                        if afterLoginFunc and type(afterLoginFunc) == "function" then
                            he_log_info("+++++++++++++++++++++++++++haimaios Log:run afterLoginFunc++++++++++++++++++++++++++++++++")
                            afterLoginFunc()
                        end
                    end
                    DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                    HttpClient:getInstance():sendRequest(onCheckHaimaidFinish, request)
                end
                check_haima_id()
            else
                he_log_error("+++++++++++++++++++++++++++haimaios Log:login failed info = "..info.."++++++++++++++++++++++++++++++++")   
                if isLogin_haima then
                    --logout from usercenter
                    isLogin_haima = false
                    Director:sharedDirector():replaceScene(LoginScene:create())
                else
                    --cancel loginHaima do nothing
                end 
            end 
        end 
        
        PlatformMgr:getInstance():registerLoginHandler(login_haima_callback)
        haimaGameSdk:loginHaima()
    end
end

function logoutHaima_ios(afterLogoutFunc)
    if isLogin_haima then
        he_log_info("+++++++++++++++++++++++++++haimaios Log:logout++++++++++++++++++++++++++++++++")
    
        --haimaGameSdk:logoutHaima()
        os.execute("sleep"..1)
        isLogin_haima = false
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++haimaios Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end  
    end
end

function showHaimaGameCenter_ios()
    haimaGameSdk:showGameCenterHaima()
end


