local isLoginTongbu = false
local isCheckingTongbuid = false

local tb_sid = -999
local tb_uid = -999

function getIos_tongbuSid()
    return tb_sid
end
    
function getIos_tongbuUid()

    return tb_uid
end
    
function getIos_tongbuurl()
    if TBGameSdk then
        he_log_info("+++++++++++++++++++++++++++Tongbuios Log:urlencode++++++++++++++++++++++++++++++++")
        return url_encode(TBGameSdk:getTBSessionId())
    end
end
function loginTongbu_ios(afterLoginFunc)
    if not isLoginTongbu then
        he_log_info("+++++++++++++++++++++++++++Tongbuios Log:start login++++++++++++++++++++++++++++++++")
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        local function loginTongbu_callback(isSuccess,info)    
            if isSuccess then
                DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                isLoginTongbu = true 
               
                tb_sid=getIos_tongbuurl()
                --tb_sid = TBGameSdk:getTBSessionId()
                tb_uid = TBGameSdk:getTBUid()
                
                local function checkTongbuid()
                    if isCheckingTongbuid then
                        return
                    end
                    
                    isCheckingTongbuid = true
                    
                    DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                    --he_log_info("+++++++++++++++++++++++++++Tongbuios Log:start check tb id++++++++++++++++++++++++++++++++")
                    local url = DataManager.SystemConfig.CheckIosTongbuidUrl
                    url = url .."sessionId="..tb_sid.."&uid="..tb_uid
                    --he_log_info("+++++++++++++++++++++++++++Tongbuios Log:check tb id url:"..url.."++++++++++++++++++++++++++++++++")
                    local request = HttpRequest:createPost(url)
                            
                    local function onCheckTongbuidFinish(response)
                        --he_log_info("+++++++++++++++++++++++++++Tongbuios Log:Check tb id finish ++++++++++++++++++++++++++++++++")
                        
                        isCheckingTongbuid = false	
                        	
                        --local tstr = table.serialize(response)
                        --he_log_info("+++++++++++++++++++++++++++Tongbuios Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
						local function checkErr()
							CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("popup_networkError"),
                                        nil,
                                        {
                                            text = getTextByKey("retry"),
                                            callbackFunc = function()
                                                checkTongbuid()
                                            end
                                        }
                                    )
						end
						
						if response.httpCode ~= 200 then
							checkErr()
							return
						end
						
                        local rTable = table.deserialize(response.body)		
                        if rTable.code ~= "1" then
                            --he_log_error("+++++++++++++++++++++++++++Tongbuios Log:check tb id error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
                            checkErr()
                            return
                        end
                                
                        DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                        if afterLoginFunc and type(afterLoginFunc) == "function" then
                            he_log_info("+++++++++++++++++++++++++++Tongbuios Log:run afterLoginFunc++++++++++++++++++++++++++++++++")
                            afterLoginFunc()
                        end
                    end
                    DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                    HttpClient:getInstance():sendRequest(onCheckTongbuidFinish, request)
                end
                checkTongbuid()
            else
                he_log_error("+++++++++++++++++++++++++++Tongbuios Log:login failed info = "..info.."++++++++++++++++++++++++++++++++")   
                if isLoginTongbu then
                    --logout from usercenter
                    isLoginTongbu = false
                    Director:sharedDirector():replaceScene(LoginScene:create())
                else
                    --cancel loginTongbu do nothing
                end 
            end 
        end 
        
        PlatformMgr:getInstance():registerLoginHandler(loginTongbu_callback)
        TBGameSdk:loginTB()
    end
end

function logoutTongbu_ios(afterLogoutFunc)
    if isLoginTongbu then
        isLoginTongbu = false
        TBGameSdk:logoutTB()
        os.execute("sleep"..1)
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            afterLogoutFunc()
        end  
    end     
end

function showTongbuCenter_ios()         
    TBGameSdk:showTBCenter()
end

function showTongbuFloatButton_ios(isShow)
    if isShow then
        he_log_info("+++++++++++++++++++++++++++Tongbuios Log:show FloatButton++++++++++++++++++++++++++++++++")
    else
        he_log_info("+++++++++++++++++++++++++++Tongbuios Log:hide FloatButton++++++++++++++++++++++++++++++++")
    end
         
    TBGameSdk:showTBToolBar(isShow)
end


