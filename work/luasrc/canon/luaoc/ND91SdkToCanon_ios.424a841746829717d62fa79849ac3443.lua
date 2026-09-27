local nd91sdk = nil
     
local isSdkInit = false
local isLogin91 = false
local isChecking91id = false

local nd91_sid = -999
local nd91_loginUin = -999
local nd91_userName = ""

function getIos91Sid()
    return nd91_sid
end
    
function getIos91Uid()
    return nd91_loginUin
end
    
function login91_ios(afterLogin91Func)
    if not isLogin91 then
        he_log_info("+++++++++++++++++++++++++++91ios Log:start login++++++++++++++++++++++++++++++++")
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        local function login91_callback(isSuccess,info)
            if isSuccess then
                DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                isLogin91 = true 
                nd91_sid = ND91GameSdk:get91SessionId()
                nd91_loginUin = ND91GameSdk:get91LoginUin()
                --he_log_info("+++++++++++++++++++++++++++91ios Log:login Success(sid = "..nd91_sid..")++++++++++++++++++++++++++++++++")
                --he_log_info("+++++++++++++++++++++++++++91ios Log:login Success(uin = " .. nd91_loginUin .. ")++++++++++++++++++++++++++++++++")
                
                local function check91id()
                    if isChecking91id then
                        return
                    end
                    
                    isChecking91id = true
                    
                    DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++91ios Log:start check 91 id++++++++++++++++++++++++++++++++")
                    local url = DataManager.SystemConfig.CheckIos91idUrl
                    url = url .."sessionId="..nd91_sid.."&uin="..nd91_loginUin
                    --he_log_info("+++++++++++++++++++++++++++91ios Log:check 91 id url:"..url.."++++++++++++++++++++++++++++++++")
                    local request = HttpRequest:createPost(url)
                            
                    local function onCheck91idFinish(response)
                        he_log_info("+++++++++++++++++++++++++++91ios Log:Check 91 id finish ++++++++++++++++++++++++++++++++")
                        
                        isChecking91id = false	
                        	
                        --local tstr = table.serialize(response)
                        --he_log_info("+++++++++++++++++++++++++++91ios Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
						local function checkErr()
							CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("popup_networkError"),
                                        nil,
                                        {
                                            text = getTextByKey("retry"),
                                            callbackFunc = function()
                                                check91id()
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
                            --he_log_error("+++++++++++++++++++++++++++91ios Log:check 91 id error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
                            checkErr()
                            return
                        end
                                
                        nd91_loginUin = rTable.Uin
                            
                        DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                        if afterLogin91Func and type(afterLogin91Func) == "function" then
                            he_log_info("+++++++++++++++++++++++++++91ios Log:run afterLogin91Func++++++++++++++++++++++++++++++++")
                            afterLogin91Func()
                        end
                    end
                    DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                    HttpClient:getInstance():sendRequest(onCheck91idFinish, request)
                end
                check91id()
            else
                he_log_error("+++++++++++++++++++++++++++91ios Log:login failed info = "..info.."++++++++++++++++++++++++++++++++")   
                if isLogin91 then
                    --logout from usercenter
                    isLogin91 = false
                    Director:sharedDirector():replaceScene(LoginScene:create())
                else
                    --cancel login91 do nothing
                end 
            end 
        end 
        
        PlatformMgr:getInstance():registerLoginHandler(login91_callback)
        ND91GameSdk:login91()
    end
end

function logout91_ios(afterLogoutFunc)
    he_log_info("+++++++++++++++++++++++++++91ios Log:logout++++++++++++++++++++++++++++++++")
    ND91GameSdk:logout91()
    os.execute("sleep"..1)
    isLogin91 = false
    if afterLogoutFunc and type(afterLogoutFunc) == "function" then
        he_log_info("+++++++++++++++++++++++++++91ios Log:begin run logout after func++++++++++++++++++++++++++++++++")
        afterLogoutFunc()
    end  
end

function show91FloatButton_ios(isShow)
    if isShow then
        he_log_info("+++++++++++++++++++++++++++91ios Log:show FloatButton++++++++++++++++++++++++++++++++")
    else
        he_log_info("+++++++++++++++++++++++++++91ios Log:hide FloatButton++++++++++++++++++++++++++++++++")
    end
         
    ND91GameSdk:show91ToolBar(isShow)
end


