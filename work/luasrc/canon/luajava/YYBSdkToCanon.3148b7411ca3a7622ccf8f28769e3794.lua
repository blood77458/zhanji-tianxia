--腾讯应用宝lua接口
require "hecore.luaJavaConvert"

local YYBSdk = nil
local QQopenid = nil
local QQtoken = nil
local isCheckQQid = false

if isYYBAndroid()  then
    YYBSdk = luajava.bindClass("com.happyelements.canon.YYBGameSdk")
end

function getQQopenid()
    return QQopenid
end

function getQQSid()
    return QQtoken
end

function isLoginQQ()
    return YYBSdk:isLoginQQ()
end

function loginQQ(afterLoginQQFunc)
    if YYBSdk ~= nil and not isLoginQQ() then
        he_log_info("+++++++++++++++++++++++++++YYB Log:start login++++++++++++++++++++++++++++++++")
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )

        local loginQQ_callback = luajava.createProxy("com.happyelements.canon.YYBCanonCallback",
            {
                onSucc = function(info)
                    DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                    
                    local loginInfoTable = info:split(",")
                    
                    QQtoken = loginInfoTable[2]:split(":")[2]
                    QQopenid = loginInfoTable[1]:split(":")[2]
                    --he_log_info("+++++++++++++++++++++++++++YYB Log: QQopenid = " .. QQopenid ..",QQtoken = " .. QQtoken)    
                    local function checkQQid()
                        if isCheckQQid then
                            return
                        end
                        isCheckQQid = true
                        DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                        he_log_info("+++++++++++++++++++++++++++YYB Log:start check qq id++++++++++++++++++++++++++++++++")
                        local url = DataManager.SystemConfig.CheckQQidUrl
                        url = url .."sid="..QQtoken.."&udid="..QQopenid
                        
                        local request = HttpRequest:createPost(url)
                            
                        local function onCheckQQidFinish(response)
                            he_log_info("+++++++++++++++++++++++++++YYB Log:Check qq id finish ++++++++++++++++++++++++++++++++")
                            isCheckQQid = false		
                            --local tstr = table.serialize(response)
                            --he_log_info("+++++++++++++++++++++++++++YYB Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
							local function checkNetWorkErr()
								 CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("popup_networkError"),
                                        nil,
                                        {
                                            text = getTextByKey("retry"),
                                            callbackFunc = function()
                                                checkQQid()
                                            end
                                        }
                                    )
							end
							
							if response.httpCode ~= 200 then
								checkNetWorkErr()
								return
							end
							
                            local rTable = table.deserialize(response.body)		
                            if  rTable.code > 1 then
                                --he_log_error("+++++++++++++++++++++++++++YYB Log:check qq id error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
                                checkNetWorkErr()   
                                return
                            end
                                
                            DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                            if afterLoginQQFunc and type(afterLoginQQFunc) == "function" then
                                he_log_info("+++++++++++++++++++++++++++YYB Log:run afterLoginQQFunc++++++++++++++++++++++++++++++++")
                                afterLoginQQFunc()
                            end
                        end
                        DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                        HttpClient:getInstance():sendRequest(onCheckQQidFinish, request)
                            
                     end
                     checkQQid()
                end,
                onError = function(info)
                    he_log_info("+++++++++++++++++++++++++++YYB Log:login err:".. info .."++++++++++++++++++++++++++++++++")
                end,
                onCancel = function()
                    he_log_info("+++++++++++++++++++++++++++YYB Log:cancel login++++++++++++++++++++++++++++++++")
                end
            }
        )
        
        
        YYBSdk:loginQQ(loginQQ_callback)
    end 
end 

function logoutQQ(afterLogoutFunc)
    if YYBSdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++YYB Log:logout++++++++++++++++++++++++++++++++")
        YYBSdk:logoutQQ()
        os.execute("sleep"..1)
        
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++YYB Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end      
    end
end 
