require "hecore.luaJavaConvert"

local yyhSdk = nil
     
local isLoginYYH = false
local isCheckingYYHid = false

if isYyhAndroid()  then
    yyhSdk = luajava.bindClass("com.happyelements.canon.yyh.YyhGameSdk")
end

function getYYHSid()
    if yyhSdk then
        return yyhSdk:getYyhTicket()
    end
end

function getYYHUid()
    if yyhSdk then
        return yyhSdk:getYyhUid()
    end
end

function loginYYH(afterLoginFunc)
    if yyhSdk ~= nil and  not isLoginYYH then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        isCheckingYYHid = false
        he_log_info("+++++++++++++++++++++++++++YYH Log:start login++++++++++++++++++++++++++++++++")
        local loginYYH_callback = luajava.createProxy("com.happyelements.canon.yyh.YyhCanonCallback",
            {
                onSuccess = function( statusCode, info)
                    
                    DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++YYH Log:login success++++++++++++++++++++++++++++++++")
                    isLoginYYH = true         
                    local yyh_sid = getYYHSid()
                    local yyh_uid = getYYHUid()
                    --he_log_info("+++++++++++++++++++++++++++YYH Log:login Success(sid = "..yyh_sid..")++++++++++++++++++++++++++++++++")
                    --he_log_info("+++++++++++++++++++++++++++YYH Log:login Success(uid = " .. yyh_uid .. ")++++++++++++++++++++++++++++++++")
                        
                    local function checkYYHid()
                        if isCheckingYYHid then
                            return
                        end
                        isCheckingYYHid = true
                        DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                        he_log_info("+++++++++++++++++++++++++++YYH Log:start check yyh id++++++++++++++++++++++++++++++++")
                        local url = DataManager.SystemConfig.CheckYYHIdUrl
                            
                        --he_log_info("+++++++++++++++++++++++++++YYH Log:check yyh id url:"..url.."++++++++++++++++++++++++++++++++")
                        url = url .."ticket="..yyh_sid.."&userId="..yyh_uid.."&gspId=7806507860"
                            
                        local request = HttpRequest:createPost(url)
                            
                            
                        local function onCheckYYHidFinish(response)
                            he_log_info("+++++++++++++++++++++++++++YYH Log:Check yyh id finish ++++++++++++++++++++++++++++++++")
                                
                            --local tstr = table.serialize(response)
                            --he_log_info("+++++++++++++++++++++++++++YYH Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
							local function checkNetWorkErr()
								CanonMessageBox.showText(
                                    ShowButtonType.ID_OK,
                                    getTextByKey("popup_networkError"),
                                    nil,
                                    {
                                        text = getTextByKey("retry"),
                                        callbackFunc = function()
                                            isCheckingYYHid = false
                                            checkYYHid()
                                        end
                                    }
                                )
							end
							
							if response.httpCode ~= 200 then
								checkNetWorkErr()
								return
							end
							
                            local rTable = table.deserialize(response.body)		
                            
                            if rTable.code ~= 0 then
                                --he_log_error("+++++++++++++++++++++++++++YYH Log:check yyh id error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
                                checkNetWorkErr()
                                return
                            end
                            DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                            if afterLoginFunc and type(afterLoginFunc) == "function" then
                                he_log_info("+++++++++++++++++++++++++++YYH Log:run afterLoginYYHFunc++++++++++++++++++++++++++++++++")
                                afterLoginFunc()
                            end
                        end
                        DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                        HttpClient:getInstance():sendRequest(onCheckYYHidFinish, request)
                            
                    end
                    checkYYHid()
                end,
                onFail = function(statusCode,info) 
                    he_log_error("+++++++++++++++++++++++++++YYH Log:Login failed statusCode = "..statusCode..",info = " .. info .. "++++++++++++++++++++++++++++++++")
                end
            }
        )
        
        --
        local logoutYYH_callback = luajava.createProxy("com.happyelements.canon.yyh.YyhCanonCallback",
            {
                onSuccess = function(statusCode,info)
                    Director:sharedDirector():replaceScene(LoginScene:create())
                end,
                onFail = function(statusCode,info)
                    he_log_error("+++++++++++++++++++++++++++YYH Log:logout failed statusCode = "..statusCode.."++++++++++++++++++++++++++++++++")
                end
            }
        )
        yyhSdk:setLoginResultCallBackFunc(loginYYH_callback)
        yyhSdk:setLogoutResultCallBackFunc(logoutYYH_callback)
        yyhSdk:loginYyh()
    end 
end

function logoutYYH(afterLogoutFunc)
    if yyhSdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++YYH Log:logout++++++++++++++++++++++++++++++++")
        
        isLoginYYH = false
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++YYH Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end      
    end
end

function showYyhToolBar(isShow)
    if yyhSdk ~= nil then
        yyhSdk:showYYHBar(isShow)
    end
end