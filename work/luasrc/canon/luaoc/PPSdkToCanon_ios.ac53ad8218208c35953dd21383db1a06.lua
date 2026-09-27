local isLoginPP = false
local isCheckingPPid = false

local pp_sid = -999
local pp_uid = -999

function getIosPPSid()
    return pp_sid
end
    
function getIosPPUid()
    return pp_uid
end
    
function loginPP_ios(afterLoginFunc)
    if not isLoginPP then
        he_log_info("+++++++++++++++++++++++++++PPios Log:start login++++++++++++++++++++++++++++++++")
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        local function loginPP_callback(isSuccess,info)
            if isSuccess then
                DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                isLoginPP = true 
                pp_sid = PPGameSdk:getPPSessionId()
                pp_uid = PPGameSdk:getPPUid()
                he_log_info("+++++++++++++++++++++++++++PPios Log:login Success(sid = "..pp_sid..")++++++++++++++++++++++++++++++++")
                he_log_info("+++++++++++++++++++++++++++PPios Log:login Success(uid = " .. pp_uid .. ")++++++++++++++++++++++++++++++++")
                
                local function checkPPid()
                    if isCheckingPPid then
                        return
                    end
                    
                    isCheckingPPid = true
                    
                    DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++PPios Log:start check pp id++++++++++++++++++++++++++++++++")
                    local url = DataManager.SystemConfig.CheckIosPPidUrl
                    url = url .."token="..pp_sid.."&uid="..pp_uid
                    he_log_info("+++++++++++++++++++++++++++PPios Log:check pp id url:"..url.."++++++++++++++++++++++++++++++++")
                    local request = HttpRequest:createPost(url)
                            
                    local function onCheckPPidFinish(response)
                        he_log_info("+++++++++++++++++++++++++++PPios Log:Check pp id finish ++++++++++++++++++++++++++++++++")
                        
                        isCheckingPPid = false	
                        	
                        --local tstr = table.serialize(response)
                        --he_log_info("+++++++++++++++++++++++++++PPios Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
						local function checkErr()
							CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("popup_networkError"),
                                        nil,
                                        {
                                            text = getTextByKey("retry"),
                                            callbackFunc = function()
                                                checkPPid()
                                            end
                                        }
                                    )
						end
						
						if response.httpCode ~= 200 then
							checkErr()
							return
						end
                        local rTable = table.deserialize(response.body)		
                        if  rTable.code > 1 then
                            --he_log_error("+++++++++++++++++++++++++++PPios Log:check pp id error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
                            checkErr()
                            return
                        end
                                
                        DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                        if afterLoginFunc and type(afterLoginFunc) == "function" then
                            he_log_info("+++++++++++++++++++++++++++PPios Log:run afterLoginFunc++++++++++++++++++++++++++++++++")
                            afterLoginFunc()
                        end
                    end
                    DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                    HttpClient:getInstance():sendRequest(onCheckPPidFinish, request)
                end
                checkPPid()
            else
                he_log_error("+++++++++++++++++++++++++++PPios Log:login failed info = "..info.."++++++++++++++++++++++++++++++++")   
                if isLoginPP then
                    --logout from usercenter
                    isLoginPP = false
                    Director:sharedDirector():replaceScene(LoginScene:create())
                else
                    --cancel loginPP do nothing
                end 
            end 
        end 
        
        PlatformMgr:getInstance():registerLoginHandler(loginPP_callback)
        PPGameSdk:loginPP()
    end
end

function logoutPP_ios(afterLogoutFunc)
    if isLoginPP then
        he_log_info("+++++++++++++++++++++++++++PPios Log:logout++++++++++++++++++++++++++++++++")
        isLoginPP = false
        PPGameSdk:logoutPP()
        os.execute("sleep"..1)
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++PPios Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end  
    end     
end

function showPPCenter_ios()         
    PPGameSdk:showPPCenter()
end


