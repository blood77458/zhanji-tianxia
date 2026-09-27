require "hecore.luaJavaConvert"
require "canon.luajava.UCStatusCode"

local ucgamesdk = nil

local isSdkInit = false
local isLoginUC = false
local maxInitSdkRetryTimes = 10
local UC_sid = -999
local UC_id = -999
local UC_nickName = nil

local isCreateUCFloatBtn = false

local isCheckingUCid = false

function getIsUCSdkInit()
    --return isSdkInit 
    isSdkInit = ucgamesdk:isInitSucc()
    return isSdkInit
end 

function getIsLoginUC()
    return isLoginUC
end 

function getUCSid()
    return UC_sid
end 

function getUCID()
    return UC_id
end 

function getUCNickName()
    return UC_nickName
end

if isUCAndroid() then
    ucgamesdk = luajava.bindClass("cn.uc.gamesdk.jni.UCGameSdk")
end

function loginUC(afterLoginUC)
    if ucgamesdk ~= nil and getIsUCSdkInit() and not isLoginUC then
        he_log_info("+++++++++++++++++++++++++++UC Log:start login++++++++++++++++++++++++++++++++")
        DcManager.sendLoadingActivity(60, ((os.time() - g_startTime )*1000) )
        local ucsdk_callbackListener = nil
        local loginUC_callback = luajava.createProxy("cn.uc.gamesdk.jni.UCCanonCallback",
            {
                onResponse = function(statusCode,responseStr)
                    if statusCode == g_UCSdk_SUCCESS then
                        DcManager.sendLoadingActivity(61, ((os.time() - g_startTime )*1000) )
                        isLoginUC = true
                        UC_sid = ucgamesdk:getSid()
                        --he_log_info("+++++++++++++++++++++++++++UC Log:login ok:sid is :"..UC_sid.."++++++++++++++++++++++++++++++++")                        
                        
                        local function checkUCid()
                            if isCheckingUCid then
                                return
                            end
                            isCheckingUCid = true
                            DcManager.sendLoadingActivity(62, ((os.time() - g_startTime )*1000) )
                            he_log_info("+++++++++++++++++++++++++++UC Log:start check uc id++++++++++++++++++++++++++++++++")
                            local url = DataManager.SystemConfig.CheckUCidUrl
                            --he_log_info("+++++++++++++++++++++++++++UC Log:check uc id url:"..url.."++++++++++++++++++++++++++++++++")
                            local request = HttpRequest:createPost(url)
                            
                            local timeout = 10
                            
                            request:setConnectionTimeoutMs(timeout * 1000)
                            
                            request:setTimeoutMs(timeout * 1000)
                            
                            request:addHeader("Content-Type:application/x-www-form-urlencoded")
                            
                            local dataString ="sid="..UC_sid
							
							dataString = dataString .. "&gspId=7800106701"
                            
                            local dataStringLen = dataString:len()
                            
                            request:setPostData(dataString, dataStringLen)
                            
                            local function onCheckUCidFinish(response)
                                he_log_info("+++++++++++++++++++++++++++UC Log:Check UC id finish++++++++++++++++++++++++++++++++")
                                local function checkErr()
                                    he_log_error("+++++++++++++++++++++++++++UC Log:check uc id error++++++++++++++++++++++++++++++++")
                                    CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("popup_networkError"),
                                        nil,
                                        {
                                            text = getTextByKey("retry"),
                                            callbackFunc = function()
                                                checkUCid()
                                            end
                                        }
                                    )
                                end
                                
                                isCheckingUCid = false
                                
								if response.httpCode ~= 200 then
									checkErr()
                                    return
								end
								
                                if response.body == nil or response.body == "" then
                                    checkErr()
                                    return
                                end
                                		
                                local rTable = table.deserialize(response.body)		
                                if rTable.code ~= 1 then
                                    if rTable.code == 111 then--UC停服
                                        CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("uc_warn"),
                                        nil,
                                        {
                                            text = getTextByKey("yes"),
                                            callbackFunc = function()
                                            PlistResMgr:getInstance():terminateProcess()
                                            end
                                        }
                                    )
                                    else
                                        checkErr()
                                    end
                                    return
                                end
                                --local fields = response.body:split(",")
                                --he_log_info("+++++++++++++++++++++++++++response.body="..response.body.."++++++++++++++++++++++++++++++++")
                                UC_id = rTable.ucid--fields[1]
                                UC_nickName = rTable.nickName--fields[2]
                                if UC_nickName == nil then
                                    UC_nickName = "nil_null"
                                end
                                --he_log_info("+++++++++++++++++++++++++++UC Log:check uc id success:(UC_id="..UC_id..",UC_nickName="..UC_nickName..")++++++++++++++++++++++++++++++++")
                                DcManager.sendLoadingActivity(64, ((os.time() - g_startTime )*1000) )
                                if afterLoginUC and type(afterLoginUC) == "function" then
                                    afterLoginUC()
                                end
                            end
                            DcManager.sendLoadingActivity(63, ((os.time() - g_startTime )*1000) )
                            HttpClient:getInstance():sendRequest(onCheckUCidFinish, request)
                            
                        end
                        checkUCid()
                        
                    elseif statusCode == g_UCSdk_SDK_EXIT then
                        --exit login UI,back to game UI
                        he_log_info("+++++++++++++++++++++++++++UC Log:exit login UI++++++++++++++++++++++++++++++++")
                    else
                        he_log_error("+++++++++++++++++++++++++++UC Log:login UI failed++++++++++++++++++++++++++++++++")
                    end
                end
            }
        )
        
        ucsdk_callbackListener = luajava.bindClass("cn.uc.gamesdk.jni.LoginResultListener"):getInstance()
        ucsdk_callbackListener:setCallBackFunc(loginUC_callback)
        
        
        ucgamesdk:login(false,"")
        
    end 
end 

function initUCSdk(afterInitSdkFunc)
    
    if ucgamesdk ~= nil then
        local initSdkTimes = 0
        local ucsdk_callbackListener = nil
        local initSdk_callback = luajava.createProxy("cn.uc.gamesdk.jni.UCCanonCallback",
            {
                onResponse = function(statusCode,responseStr)
                    if statusCode == g_UCSdk_SUCCESS then
                        isSdkInit = true                        
                        he_log_info("+++++++++++++++++++++++++++UC Log:initUCSdk Success++++++++++++++++++++++++++++++++")
                        --createUCFloatButton()
                        if afterInitSdkFunc and type(afterInitSdkFunc) == "function" then
                            he_log_info("+++++++++++++++++++++++++++UC Log:run afterInitSdkFunc++++++++++++++++++++++++++++++++")
                            afterInitSdkFunc()
                        end
                        
                    else
                        he_log_error("+++++++++++++++++++++++++++UC Log:initUCSdk failed++++++++++++++++++++++++++++++++")
                        initSdkTimes = initSdkTimes + 1
                        if initSdkTimes < maxInitSdkRetryTimes then
                            ucgamesdk:initSDK(isDebug,logLevel,cpId,gameId,serverId,serverName,enablePayHistory,enableLogout)
                            return
                        end
                    end
                end
            }
        )
        
        ucsdk_callbackListener = luajava.bindClass("cn.uc.gamesdk.jni.InitResultListener"):getInstance()
        ucsdk_callbackListener:setCallBackFunc(initSdk_callback)
        ucgamesdk:initSDK(isDebug,logLevel,cpId,gameId,serverId,serverName,enablePayHistory,enableLogout)
    end 
end 

function destroyUCFloatButton()
    if ucgamesdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++UC Log:destroyFloatButton++++++++++++++++++++++++++++++++")
        ucgamesdk:destroyFloatButton()
    end
end

function exitUCSdk()
    if ucgamesdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++UC Log:exitSDK()++++++++++++++++++++++++++++++++")
        ucgamesdk:exitSDK()
    end
end 

function createUCFloatButton() 
    if ucgamesdk ~= nil then
        if not isCreateUCFloatBtn then
            he_log_info("+++++++++++++++++++++++++++UC Log:createFloatButton++++++++++++++++++++++++++++++++")
            isCreateUCFloatBtn = true
            ucgamesdk:createFloatButton()
        end
    end
end

function showUCFloatButton(posx,posy,isShow)
    if ucgamesdk ~= nil then
        if isShow then
            he_log_info("+++++++++++++++++++++++++++UC Log:show FloatButton++++++++++++++++++++++++++++++++")
        else
            he_log_info("+++++++++++++++++++++++++++UC Log:hide FloatButton++++++++++++++++++++++++++++++++")
        end
         
        ucgamesdk:showFloatButton(posx,posy,isShow)
    end
end 

function logoutUC(afterLogoutFunc)
     if ucgamesdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++UC Log:logout++++++++++++++++++++++++++++++++")
        local ucsdk_callbackListener = nil
        local logout_callback = luajava.createProxy("cn.uc.gamesdk.jni.UCCanonCallback",
            {
                onResponse = function(statusCode,responseStr)
                    if statusCode == g_UCSdk_SUCCESS then
                        isLoginUC = false
                        
                        he_log_info("+++++++++++++++++++++++++++UC Log:logout Success++++++++++++++++++++++++++++++++")
                        if afterLogoutFunc and type(afterLogoutFunc) == "function" then
                             he_log_info("+++++++++++++++++++++++++++UC Log:begin run logout after func++++++++++++++++++++++++++++++++")
                            afterLogoutFunc()
                        end
                        
                    else
                        
                        he_log_error("+++++++++++++++++++++++++++UC Log:logout failed++++++++++++++++++++++++++++++++")
                    end
                end
            }
        )
        
        ucsdk_callbackListener = luajava.bindClass("cn.uc.gamesdk.jni.LogoutListener"):getInstance()
        ucsdk_callbackListener:setCallBackFunc(logout_callback)
        ucgamesdk:logout()
    end
end 

function submitExtendDataToUC(dataType)
	if ucgamesdk ~= nil then
        he_log_info("+++++++++++++++++++++++++++UC Log:submitExtendData++++++++++++++++++++++++++++++++")
		local userInfo = DataManager.getCurrUser()
		local extendData = {
								roleId = userInfo.uid,
								roleName = userInfo.nickName,
								roleLevel = userInfo.level,
								zoneId = DataManager.getServerid(),
								zoneName = DataManager.getCurGameServerName(),
			                }
		extendData = table.serialize(extendData)
		he_log_info("+++++++++++++++++++++++++++UC Log:dataType:"..dataType..",extendData:"..extendData)
		ucgamesdk:submitExtendData(dataType,extendData)
	end
end









