require "hecore.luaJavaConvert"

local oppoSdk = nil
     
local isLoginOppo = false
local isCheckingOppoId = false

local oppoTokenKey = ""
local oppoTokenSecret = ""
local oppoUid = ""
local oppoUserInfo = nil
local oppoUserToken = nil


if isOppoAndroid == nil then
	require "canon.data.ThirdPlatformLogin"
end

if isOppoAndroid()  then
    oppoSdk = luajava.bindClass("com.happyelements.canon.oppo.OppoGameSdk")
end

function getOppoSid()
    return oppoTokenKey
end

function getOppoUid()
    return oppoUid
end

function getIsLoginOppo()
    return isLoginOppo
end 

function loginOppo(afterLoginFunc)
    if oppoSdk ~= nil and  not isLoginOppo then
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        he_log_info("+++++++++++++++++++++++++++Oppo Log:start login++++++++++++++++++++++++++++++++")
        local getOppoUserInfo_callback = luajava.createProxy("com.happyelements.canon.oppo.OppoCanonCallback",
            {
                onSuccess = function(statusCode,info)
                        DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                        he_log_info("+++++++++++++++++++++++++++Oppo Log:get userinfo success++++++++++++++++++++++++++++++++")
                        local userInfo = info
                        local userToken = oppoSdk:getOppoAccessToken()
                        
                        -- he_log_info("+++++++++++++++++++++++++++Oppo Log:login Success(userInfo = "..userInfo..")++++++++++++++++++++++++++++++++")
                        -- he_log_info("+++++++++++++++++++++++++++Oppo Log:login Success(userToken = "..userToken..")++++++++++++++++++++++++++++++++")
                        
                        oppoUserInfo = table.deserialize(userInfo)
                        if oppoUserInfo then
                            oppoUid = oppoUserInfo.BriefUser.id
                        end

                        oppoUserToken = table.deserialize(userToken)
                        if oppoUserToken then
                            oppoTokenKey = oppoUserToken.oauth_token
                            oppoTokenSecret = oppoUserToken.oauth_token_secret
                        end
                        
                        -- oppoTokenKey = userToken:split("&")[1]:split("=")[2]
                        -- oppoTokenSecret = userToken:split("&")[2]:split("=")[2]

                        -- he_log_info("+++++++++++++++++++++++++++Oppo Log:login Success(oppoTokenKey = "..oppoTokenKey..")++++++++++++++++++++++++++++++++")
                        -- he_log_info("+++++++++++++++++++++++++++Oppo Log:login Success(oppoTokenSecret = "..oppoTokenSecret..")++++++++++++++++++++++++++++++++")
                        -- he_log_info("+++++++++++++++++++++++++++Oppo Log:login Success(oppoUid = " .. oppoUid .. ")++++++++++++++++++++++++++++++++")
                        
                        local function checkOppoId()
                            if isCheckingOppoId then
                                return
                            end
                            isCheckingOppoId = true
                            DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                            he_log_info("+++++++++++++++++++++++++++Oppo Log:start check oppo id++++++++++++++++++++++++++++++++")
                            local url = DataManager.SystemConfig.CheckOppoIdUrl
                            
                            --he_log_info("+++++++++++++++++++++++++++Oppo Log:check oppo id url:"..url.."++++++++++++++++++++++++++++++++")
                            local request = HttpRequest:createPost(url)
                            
                            local timeout = 10
                            
                            request:setConnectionTimeoutMs(timeout * 1000)
                            
                            request:setTimeoutMs(timeout * 1000)
                            
                            request:addHeader("Content-Type:application/x-www-form-urlencoded")
                            
                            local dataString ="access_token="..oppoTokenKey
                            
                            dataString = dataString .. "&access_secret="..oppoTokenSecret
							
							dataString = dataString .. "&gspId=7800106710"
                            
                            local dataStringLen = dataString:len()
                            
                            request:setPostData(dataString, dataStringLen)
                            
                            local function onCheckOppoIdFinish(response)
                                he_log_info("+++++++++++++++++++++++++++Oppo Log:Check oppo id finish ++++++++++++++++++++++++++++++++")
                                isCheckingOppoId = false		
                                --local tstr = table.serialize(response)
                                --he_log_info("+++++++++++++++++++++++++++Oppo Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
								local function checkNetWorkErr()
									 CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("popup_networkError"),
                                        nil,
                                        {
                                            text = getTextByKey("retry"),
                                            callbackFunc = function()
                                                checkOppoId()
                                            end
                                        }
                                    )
								end
								
								if response.httpCode ~= 200 then
									checkNetWorkErr()
									return
								end
								
                                local rTable = table.deserialize(response.body)		
                                if rTable.code ~= 200 then
                                    --he_log_error("+++++++++++++++++++++++++++Oppo Log:check oppo id error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
                                    checkNetWorkErr()
                                    return
                                end
                                DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                                if afterLoginFunc and type(afterLoginFunc) == "function" then
                                    he_log_info("+++++++++++++++++++++++++++Oppo Log:run afterLoginFunc++++++++++++++++++++++++++++++++")
                                    afterLoginFunc()
                                end
                            end
                            DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                            HttpClient:getInstance():sendRequest(onCheckOppoIdFinish, request)
                            
                        end
                        checkOppoId()                      
                end,
                onFail = function(statusCode,info) 
                    he_log_error("+++++++++++++++++++++++++++Oppo Log:getUserInfo failed statusCode = "..statusCode..",info = " .. info .. "++++++++++++++++++++++++++++++++")
                end
            }
        )
        local loginOppo_callback = luajava.createProxy("com.happyelements.canon.oppo.OppoCanonCallback",
            {
                onSuccess = function(statusCode,info)
                    if statusCode  then
                        he_log_info("+++++++++++++++++++++++++++Oppo Log:login success++++++++++++++++++++++++++++++++")
                        isLoginOppo = true         
                        
                        --oppoSdk:getOppoUserInfo()
                        
                    end
                end,
                onFail = function(statusCode,info) 
                    he_log_error("+++++++++++++++++++++++++++Oppo Log:login failed statusCode = "..statusCode..",info = " .. info .. "++++++++++++++++++++++++++++++++")
                end
            }
        )
        
        oppoSdk:setGetUserInfoResultCallBackFunc(getOppoUserInfo_callback)
        oppoSdk:setLoginResultCallBackFunc(loginOppo_callback)
        oppoSdk:loginOppo()
    end 
end

function logoutOppo(afterLogoutFunc)
    if oppoSdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++Oppo Log:logout++++++++++++++++++++++++++++++++")
        
        isLoginOppo = false
        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
            he_log_info("+++++++++++++++++++++++++++Oppo Log:begin run logout after func++++++++++++++++++++++++++++++++")
            afterLogoutFunc()
        end      
    end
end

function showOppoFloatSprite(isShow)
    if oppoSdk ~= nil then
        oppoSdk:showOppoGameSprite(isShow)
    end
end

function submitExtendDataToOppo() 
	if oppoSdk ~= nil then
		he_log_info("+++++++++++++++++++++++++++Oppo Log:submitExtendData++++++++++++++++++++++++++++++++")
		local userInfo = DataManager.getCurrUser()
		local extendData = {
								roleId = userInfo.uid,
								roleName = userInfo.nickName,
								roleLevel = userInfo.level,
								zoneId = DataManager.getServerid(),
								zoneName = DataManager.getCurGameServerName(),
			                }
							--he_log_info("+++++++++++++++++++++++++++Oppo Log:"..DataManager.getCurGameServerName()..":"..userInfo.uid..":"..userInfo.level)
		oppoSdk:submitExtendInfoToOppo(tostring(DataManager.getCurGameServerName()), tostring(userInfo.uid), tostring(userInfo.level)) 
	end
end