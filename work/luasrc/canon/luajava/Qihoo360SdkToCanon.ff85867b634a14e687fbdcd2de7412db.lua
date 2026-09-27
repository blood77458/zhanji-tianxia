require "hecore.luaJavaConvert"

local qihoo360Sdk = nil
     
local isLogin360 = false
local isChecking360Id = false

local qihoo360_sid = -999
local qihoo360_loginUid = -999

if is360Android()  then
    qihoo360Sdk = luajava.bindClass("com.qihoo360.complatform.qihoo360GameSdk")
end

function getIsLogin360()
    return isLogin360
end

function get360LoginUid ()
    return qihoo360_loginUid
end

function get360Sid()
    return qihoo360_sid
end

function getIsLogin360()
    return isLogin360
end

function login360(afterLoginFunc)

    if qihoo360Sdk ~= nil and not isLogin360 then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        he_log_info("+++++++++++++++++++++++++++360 Log:start login++++++++++++++++++++++++++++++++")
        local login360_callback = luajava.createProxy("com.qihoo360.complatform.qihoo360CanonCallback",
            {
                onResponse = function(code)
                    if code and code ~= "is null"  then
                        --he_log_info("+++++++++++++++++++++++++++360 Log:login code = " .. code .." ++++++++++++++++++++++++++++++++")
                            DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                            he_log_info("+++++++++++++++++++++++++++360 Log:login Success++++++++++++++++++++++++++++++++")
                            isLogin360 = true
                            local token = code
                            --he_log_info("+++++++++++++++++++++++++++360 Log:token = "..token .."++++++++++++++++++++++++++++++++")
                            
                            qihoo360_sid = token
                            
                            local function check360Id()
                                if isChecking360Id then
                                    return
                                end
                                isChecking360Id = true
                                DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                                he_log_info("+++++++++++++++++++++++++++360 Log:start check 360 id++++++++++++++++++++++++++++++++")
                                local url = DataManager.SystemConfig.Check360IdUrl
                                
                                
                                url = url .."accessToken="..token.."&gspId=7800106705"
                                
                                local request = HttpRequest:createPost(url)
                            
                                local function onCheck360IdFinish(response)
                                    -- he_log_info("+++++++++++++++++++++++++++360 Log:Check 360 id finish(response.body = "..response.body..",response.httpCode = "..response.httpCode.."++++++++++++++++++++++++++++++++")
                                    local function checkErr()
                                        he_log_error("+++++++++++++++++++++++++++360 Log:check 360 id error++++++++++++++++++++++++++++++++")
                                        CanonMessageBox.showText(
                                            ShowButtonType.ID_OK,
                                            getTextByKey("popup_networkError"),
                                            nil,
                                            {
                                                text = getTextByKey("retry"),
                                                callbackFunc = function()
                                                    check360Id()
                                                end
                                            }
                                        )
                                    end

                                    isChecking360Id = false		
                                    
									if response.httpCode ~= 200 then
										checkErr()
                                        return
									end
									
                                    if response.body == nil or response.body == "" then
                                        checkErr()
                                        return
                                    end
                                
                                    local rTable = table.deserialize(response.body)		
                                    if rTable.code ~= 200 then
                                        --he_log_error("+++++++++++++++++++++++++++360 Log:check 360 id error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
                                        checkErr()
                                        return
                                    end
                                
                                    he_log_info("+++++++++++++++++++++++++++360 Log:check 360 success:++++++++++++++++++++++++++++++++")
                                    -- qihoo360Sdk:NameandId(response.body)
                                    qihoo360_loginUid = rTable.uid
                                    DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                                    if afterLoginFunc and type(afterLoginFunc) == "function" then
                                        he_log_info("+++++++++++++++++++++++++++360 Log:run afterLogin360Func++++++++++++++++++++++++++++++++")
                                        afterLoginFunc()
                                    end
                                end
                                DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                                HttpClient:getInstance():sendRequest(onCheck360IdFinish, request)
                            
                            end
                            
                            check360Id()
                            
                        
                    else
                        he_log_error("+++++++++++++++++++++++++++360 Log:login failed ++++++++++++++++++++++++++++++++")
                        
                    end
                end
            }
        )
        
        qihoo360Sdk:setLoginResultCallBackFunc(login360_callback)
        qihoo360Sdk:login360(false)
    end 
end 

function logout360(afterLogoutFunc)
     if qihoo360Sdk ~= nil and isLogin360 then
        he_log_info("+++++++++++++++++++++++++++360 Log:logout++++++++++++++++++++++++++++++++")
        
        local maskLayer = CCLayerColor:create(ccc4(0,0,0,200))
        local maskLayer_zOrder = 10001
        CCDirector:sharedDirector():getRunningScene():addChild(maskLayer, maskLayer_zOrder)
        he_log_info("+++++++++++++++++++++++++++360 Log:logout add mask layer++++++++++++++++++++++++++++++++")
        local logout_callback = luajava.createProxy("com.qihoo360.complatform.qihoo360CanonCallback",
            {
                onResponse = function(code)
                he_log_error("+++++++++++++++++++++++++++360 Log:logout code = "..code.."++++++++++++++++++++++++++++++++")
                    CCDirector:sharedDirector():getRunningScene():removeChild(maskLayer,true)
                    local logoutResult = table.deserialize(code)	
                    if logoutResult.which == 2 then
                        isLogin360 = false
                        
                        he_log_info("+++++++++++++++++++++++++++360 Log:logout Success++++++++++++++++++++++++++++++++")
                        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
                             he_log_info("+++++++++++++++++++++++++++360 Log:begin run logout after func++++++++++++++++++++++++++++++++")
                            afterLogoutFunc()
                        end
                        
                    else
                        
                        he_log_error("+++++++++++++++++++++++++++360 Log:logout failed++++++++++++++++++++++++++++++++")
                    end
                end
            }
        )
        
        qihoo360Sdk:setLogoutResultCallBackFunc(logout_callback)
        qihoo360Sdk:logout360()
    end
end 

function doSdkRealNameRegister(afterRegisterFunc)
    if qihoo360Sdk ~= nil and isLogin360 then
        he_log_info("+++++++++++++++++++++++++++360 Log:doSdkRealNameRegister++++++++++++++++++++++++++++++++")
        local realNameRegister_callback = luajava.createProxy("com.qihoo360.complatform.qihoo360CanonCallback",
            {
                onResponse = function(code)
                    if afterRegisterFunc and type(afterRegisterFunc) == "function" then
                        afterRegisterFunc()
                    end
                end
            }
        )
        
        qihoo360Sdk:setRealNameRegisterResultCallbackFunc(realNameRegister_callback)
        qihoo360Sdk:doSdkRealNameRegister(false,false,qihoo360_loginUid)
    end
end

function check360Addiction(afterCheckFunc)
    if qihoo360Sdk ~= nil and isLogin360 then
        he_log_info("+++++++++++++++++++++++++++360 Log:check addiction state++++++++++++++++++++++++++++++++")
        local check_callback = luajava.createProxy("com.qihoo360.complatform.qihoo360CanonCallback",
            {
                onResponse = function(code)
                    he_log_info("+++++++++++++++++++++++++++360 Log:check code = "..code.."++++++++++++++++++++++++++++++++")
                    local checkResult = table.deserialize(code)	
                    if checkResult.error_code == "0" then
                        if checkResult.content.ret[1].status == "0" or checkResult.content.ret[1].status == "1" then
                            he_log_info("+++++++++++++++++++++++++++360 Log:should run atti-addiction func++++++++++++++++++++++++++++++++")
                            if afterCheckFunc and type(afterCheckFunc) == "function" then
                                afterCheckFunc()
                            end
                        else
                        end
                    else
                        he_log_error("+++++++++++++++++++++++++++360 Log:check addiction failed++++++++++++++++++++++++++++++++")
                    end
                end
            }
        )
        
        qihoo360Sdk:setCheckAddictionResultCallBackFunc(check_callback)
        qihoo360Sdk:check360Addiction(qihoo360_loginUid)
    else
        return false
    end
end
