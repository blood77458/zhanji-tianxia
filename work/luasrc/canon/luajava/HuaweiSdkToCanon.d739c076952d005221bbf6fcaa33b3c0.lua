require "hecore.luaJavaConvert"

local huaweiSdk = nil
     
local isLoginHuawei = false
local isCheckingHuaweiId = false
local LogTag = "Huawei"

if isHuaweiAndroid()  then
    huaweiSdk = luajava.bindClass("com.happyelements.canon.HuaweiGameSdk")
end

function isHuaweiLogin()
    return isLoginHuawei
end

function getHuaweiSid()
    if huaweiSdk then
        return url_encode(huaweiSdk:getHuaweiToken())
    end
end

function getHuaweiUid()
    if huaweiSdk then
        return huaweiSdk:getHuaweiUid()
    end
end

function loginHuawei(afterLoginFunc)
    if huaweiSdk ~= nil and  not isLoginHuawei then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        isCheckingHuaweiId = false
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:start login++++++++++++++++++++++++++++++++")
        local login_callback = luajava.createProxy("com.happyelements.canon.HuaweiCanonCallback",
            {
                onSucc = function( statusCode)
                    if statusCode == 0 then
						--normal login
						DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
						he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login success++++++++++++++++++++++++++++++++")
						isLoginHuawei = true         
						local huawei_sid = getHuaweiSid()
						local huawei_uid = getHuaweiUid()
						--he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login Success(sid = "..huawei_sid..")++++++++++++++++++++++++++++++++")
						--he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:login Success(uid = " .. huawei_uid .. ")++++++++++++++++++++++++++++++++")
							
						local function checkId()
							if isCheckingHuaweiId then
								return
							end
							isCheckingHuaweiId = true
							DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
							he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:start check id++++++++++++++++++++++++++++++++")
							local url = DataManager.SystemConfig.CheckPlatformIdUrl
								
							--he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:check id url:"..url.."++++++++++++++++++++++++++++++++")
							url = url .."sid="..huawei_sid.."&user_id="..huawei_uid
								
							local request = HttpRequest:createPost(url)
								
								
							local function onCheckIdFinish(response)
								he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:Check id finish ++++++++++++++++++++++++++++++++")
									
								--local tstr = table.serialize(response)
								--he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
								local function checkNetWorkErr()
									 CanonMessageBox.showText(
										ShowButtonType.ID_OK,
										getTextByKey("popup_networkError"),
										nil,
										{
											text = getTextByKey("retry"),
											callbackFunc = function()
												isCheckingHuaweiId = false
												checkId()
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
									--he_log_error("+++++++++++++++++++++++++++".. LogTag .. " Log:check id error:response.httpCode ="..response.httpCode..",rTable.code="..rTable.code.."++++++++++++++++++++++++++++++++")
									checkNetWorkErr()
									return
								end
								DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
								if afterLoginFunc and type(afterLoginFunc) == "function" then
									he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:run afterLoginFunc++++++++++++++++++++++++++++++++")
									afterLoginFunc()
								end
							end
							DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
							HttpClient:getInstance():sendRequest(onCheckIdFinish, request)
								
						end
						checkId()
					else
						--change account
						DataManager.clearData()
						DcManager.closeUserOnlineActivity()
						TCPManager:sharedInstance():closeConnect()

						--add by Geng.Men 退出登陆的时候清除武将强化主卡数据，防止玩家申请小号的时候在武将强化教程的部分卡死
						HeMemDataHolder:deleteByKey("CardCompose_MainCardId")
						UnionChatContainerPanel.resetChatContentView()
						Director:sharedDirector():replaceScene(LoginScene:create())
					end
                    
                end,
                onFail = function(statusCode,info) 
                    he_log_error("+++++++++++++++++++++++++++".. LogTag .. " Log:Login failed statusCode = "..statusCode..",info = " .. info .. "++++++++++++++++++++++++++++++++")
                end
            }
        )
        
        --        
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:run login account++++++++++++++++++++++++++++++++")
        huaweiSdk:loginHuawei(login_callback)
        
    end 
end

function logoutHuawei(afterLogoutFunc)
    if huaweiSdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:logout++++++++++++++++++++++++++++++++")
        isLoginHuawei = false
        
        huaweiSdk:logoutHuawei()
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++".. LogTag .. " Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end 
            
    end
end
