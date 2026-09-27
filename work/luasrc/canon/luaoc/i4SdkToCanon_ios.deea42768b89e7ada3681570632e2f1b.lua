local isLogin_i4 = false
local isChecking_i4_id = false

local i4_token = -999
local i4_loginUid = -999

function getIos_i4Sid()
    return i4_token
end
    
function getIos_i4Uid()
    return i4_loginUid
end
    
function loginI4_ios(afterLoginFunc)
    if not isLogin_i4 then
        he_log_info("+++++++++++++++++++++++++++i4ios Log:start login++++++++++++++++++++++++++++++++")
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        local function login_i4_callback(isSuccess,info)
            if isSuccess then
                DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                isLogin_i4 = true
                i4_token = i4GameSdk:getI4SessionId()
                i4_loginUid = i4GameSdk:getI4LoginUid()
                --he_log_info("+++++++++++++++++++++++++++i4ios Log:login Success(sid = "..i4_token..")++++++++++++++++++++++++++++++++")
                --he_log_info("+++++++++++++++++++++++++++i4ios Log:login Success(uin = " .. i4_loginUid .. ")++++++++++++++++++++++++++++++++")
                
                local function check_i4_id()
                    if isChecking_i4_id then
                        return
                    end
                    
                    isChecking_i4_id = true
                    
                    DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++i4ios Log:start check i4 id++++++++++++++++++++++++++++++++")
                    local url = DataManager.SystemConfig.CheckIosI4idUrl
                    url = url .."sid="..i4_token.."&user_id="..i4_loginUid
                    --he_log_info("+++++++++++++++++++++++++++i4ios Log:check i4 id url:"..url.."++++++++++++++++++++++++++++++++")
                    local request = HttpRequest:createPost(url)
                            
                    local function onCheckI4idFinish(response)
                        he_log_info("+++++++++++++++++++++++++++i4ios Log:Check i4 id finish ++++++++++++++++++++++++++++++++")
                        
                        isChecking_i4_id = false	
                        	
                        --local tstr = table.serialize(response)
                        --he_log_info("+++++++++++++++++++++++++++i4ios Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
						local function checkErr()
							CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("popup_networkError"),
                                        nil,
                                        {
                                            text = getTextByKey("retry"),
                                            callbackFunc = function()
                                                check_i4_id()
                                            end
                                        }
                                    )
						end
						
						if response.httpCode ~= 200 then
							checkErr()
							return
						end
                        local rTable = table.deserialize(response.body)		
                        if rTable.code ~= 0 then
                            --he_log_error("+++++++++++++++++++++++++++i4ios Log:check i4 id error:"..rTable.code.."++++++++++++++++++++++++++++++++")
                            checkErr()
                            return
                        end
                            
                        DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                        if afterLoginFunc and type(afterLoginFunc) == "function" then
                            he_log_info("+++++++++++++++++++++++++++i4ios Log:run afterLoginFunc++++++++++++++++++++++++++++++++")
                            afterLoginFunc()
                        end
                    end
                    DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                    HttpClient:getInstance():sendRequest(onCheckI4idFinish, request)
                end
                check_i4_id()
            else
                he_log_error("+++++++++++++++++++++++++++i4ios Log:login failed info = "..info.."++++++++++++++++++++++++++++++++")   
                if isLogin_i4 then
                    --logout from usercenter
                    isLogin_i4 = false
                    Director:sharedDirector():replaceScene(LoginScene:create())
                else
                    --cancel loginI4 do nothing
                end 
            end 
        end 
        
        PlatformMgr:getInstance():registerLoginHandler(login_i4_callback)
        i4GameSdk:loginI4()
    end
end

function logoutI4_ios(afterLogoutFunc)
    if isLogin_i4 then
        he_log_info("+++++++++++++++++++++++++++i4ios Log:logout++++++++++++++++++++++++++++++++")
    
        i4GameSdk:logoutI4()
        os.execute("sleep"..1)
        isLogin_i4 = false
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++i4ios Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end  
    end
end

function showI4GameCenter_ios()
    i4GameSdk:showGameCenterI4()
end


