require "hecore.luaJavaConvert"

local anzhiSdk = nil
     
local isLoginAnzhi = false
local isCheckingAnzhiId = false

if isAnzhiAndroid()  then
    anzhiSdk = luajava.bindClass("com.happyelements.canon.AnzhiGameSdk")
end

function getAnzhiSid()
    if anzhiSdk then
        return anzhiSdk:getAnzhiSid()
    end
end

function getAnzhiUid()
    if anzhiSdk then
        return anzhiSdk:getAnzhiUid()
    end
end


function showAnzhiExitPic()
    if anzhiSdk then
        anzhiSdk:onBackPressed()
    end
end

function loginAnzhi(afterLoginFunc)
    if anzhiSdk ~= nil and  not isLoginAnzhi then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        isCheckingAnzhiId = false
        he_log_info("+++++++++++++++++++++++++++Anzhi Log:start login++++++++++++++++++++++++++++++++")
        local loginAnzhi_callback = luajava.createProxy("com.happyelements.canon.AnzhiCanonCallback",
            {
                onSucc = function( statusCode)
                    
                    DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                    he_log_info("+++++++++++++++++++++++++++Anzhi Log:login success++++++++++++++++++++++++++++++++")
                    isLoginAnzhi = true         
                    local anzhi_sid = getAnzhiSid()
                    local anzhi_uid = getAnzhiUid()
                    --he_log_info("+++++++++++++++++++++++++++Anzhi Log:login Success(sid = "..anzhi_sid..")++++++++++++++++++++++++++++++++")
                    --he_log_info("+++++++++++++++++++++++++++Anzhi Log:login Success(uid = " .. anzhi_uid .. ")++++++++++++++++++++++++++++++++")
                        
                    local function checkAnzhiId()
                        if isCheckingAnzhiId then
                            return
                        end
                        isCheckingAnzhiId = true
                        DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                        he_log_info("+++++++++++++++++++++++++++Anzhi Log:start check anzhi id++++++++++++++++++++++++++++++++")
                        local url = DataManager.SystemConfig.CheckAnzhiIdUrl
                            
                        --he_log_info("+++++++++++++++++++++++++++Anzhi Log:check anzhi id url:"..url.."++++++++++++++++++++++++++++++++")
                        url = url .."sid="..anzhi_sid.."&user_id="..anzhi_uid
                            
                        local request = HttpRequest:createPost(url)
                            
                            
                        local function onCheckIdFinish(response)
                            he_log_info("+++++++++++++++++++++++++++Anzhi Log:Check anzhi id finish ++++++++++++++++++++++++++++++++")
                                
                            --local tstr = table.serialize(response)
                            --he_log_info("+++++++++++++++++++++++++++Anzhi Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
							local function checkNetWorkErr()
								he_log_error("+++++++++++++++++++++++++++Anzhi Log:check anzhi id error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
                                CanonMessageBox.showText(
                                    ShowButtonType.ID_OK,
                                    getTextByKey("popup_networkError"),
                                    nil,
                                    {
                                        text = getTextByKey("retry"),
                                        callbackFunc = function()
                                            isCheckingAnzhiId = false
                                            checkAnzhiId()
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
                                checkNetWorkErr()
                                return
                            end
                            DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                            if afterLoginFunc and type(afterLoginFunc) == "function" then
                                he_log_info("+++++++++++++++++++++++++++Anzhi Log:run afterLoginFunc++++++++++++++++++++++++++++++++")
                                afterLoginFunc()
                            end
                        end
                        DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                        HttpClient:getInstance():sendRequest(onCheckIdFinish, request)
                            
                    end
                    checkAnzhiId()
                end,
                onFail = function(statusCode,info) 
                    he_log_error("+++++++++++++++++++++++++++Anzhi Log:Login failed statusCode = "..statusCode..",info = " .. info .. "++++++++++++++++++++++++++++++++")
                end
            }
        )
        
        --
        local logoutAnzhi_callback = luajava.createProxy("com.happyelements.canon.AnzhiCanonCallback",
            {
                onSucc = function(statusCode,info)
                     he_log_error("+++++++++++++++++++++++++++AnzhiLog:logout success++++++++++++++++++++++++++++++++")
                     ---清除本地数据
                    DataManager.clearData()
                    DcManager.closeUserOnlineActivity()
                    TCPManager:sharedInstance():closeConnect()

                    --add by Geng.Men 退出登陆的时候清除武将强化主卡数据，防止玩家申请小号的时候在武将强化教程的部分卡死
                    HeMemDataHolder:deleteByKey("CardCompose_MainCardId")
                    UnionChatContainerPanel.resetChatContentView()
                    Director:sharedDirector():replaceScene(LoginScene:create())
                end,
                onFail = function(statusCode,info)
                    he_log_error("+++++++++++++++++++++++++++AnzhiLog:logout failed statusCode = "..statusCode.."++++++++++++++++++++++++++++++++")
                end
            }
        )
        anzhiSdk:setLogoutCallBack(logoutAnzhi_callback)
        anzhiSdk:anzhiLogin(loginAnzhi_callback)
    end 
end

function logoutAnzhi(afterLogoutFunc)
    if anzhiSdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++Anzhi Log:logout++++++++++++++++++++++++++++++++")
--[[
        local logoutAnzhi_callback = luajava.createProxy("com.happyelements.canon.AnzhiCanonCallback",
            {
                onSucc = function(statusCode)
                    isLoginAnzhi = false
                    if afterLogoutFunc and type(afterLogoutFunc) == "function" then
                        he_log_info("+++++++++++++++++++++++++++Anzhi Log:begin run logout after func++++++++++++++++++++++++++++++++")
                        afterLogoutFunc()
                    end 
                end,
                onFail = function(statusCode,info)
                    he_log_error("+++++++++++++++++++++++++++Anzhi Log:logout failed statusCode = "..statusCode.."++++++++++++++++++++++++++++++++")
                end
            }
        )
        anzhiSdk:anzhiLogout(logoutAnzhi_callback)   
--]]
		isLoginAnzhi = false
		if afterLogoutFunc and type(afterLogoutFunc) == "function" then
			he_log_info("+++++++++++++++++++++++++++Anzhi Log:begin run logout after func++++++++++++++++++++++++++++++++")
			afterLogoutFunc()
		end 
    end
end

function showAnzhiFloatBar(isShow)
     if anzhiSdk ~= nil then
        anzhiSdk:showAnzhiFloatBar(isShow)
     end
end
