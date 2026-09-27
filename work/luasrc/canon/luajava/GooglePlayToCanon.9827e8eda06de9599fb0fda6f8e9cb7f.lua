local Android_sid = -999
local hasLoginAndroid = false
function loginGooglePlayTW(afterLoginAndroid)
    local checkAndroidId = nil
	if hasLoginAndroid then
		return
	end
	hasLoginAndroid = true
	
    checkAndroidId = function()
	    he_log_info("+++++++++++++++++++++++++++Android Log:start check Android id++++++++++++++++++++++++++++++++")
	    local url = DataManager.SystemConfig.CheckGooglePlayTWIdUrl

	    local request = HttpRequest:createPost(url)
	    
	    local timeout = 10
	    
	    request:setConnectionTimeoutMs(timeout * 1000)
	    
	    request:setTimeoutMs(timeout * 1000)
	    
	    request:addHeader("Content-Type:application/x-www-form-urlencoded")

	    local udid = MetaInfo:getInstance():getUdid()
	    local time = TimeUtil.getServerTimeSeconds()
	    local sk = CanonEnvInjector:getStrMd5(udid..time.."123456")
	    local dataString ="udid="..url_encode(udid)
	    dataString = dataString.."&seconds="..url_encode(time)
	    dataString = dataString.."&sk="..url_encode(sk)
	    he_log_info("dataString is:"..dataString)
	    
	    local dataStringLen = dataString:len()
	    
	    request:setPostData(dataString, dataStringLen)
        he_log_error("+++++++++++++++++++++++++++Android Log:dataString = ".. dataString .."++++++++++++++++++++++++++++++++")
	    local function onCheckAndroidIdFinish(response)
	        he_log_info("+++++++++++++++++++++++++++Android Log:Check Android id finish++++++++++++++++++++++++++++++++")
	        local function checkErr()
	            he_log_error("+++++++++++++++++++++++++++Android Log:check Android id error++++++++++++++++++++++++++++++++")
				RequestLoadingBox:removeLoadingBox()
	            CanonMessageBox.showText(
	                ShowButtonType.ID_OK,
	                getTextByKey("popup_networkError"),
	                nil,
	                {
	                    text = getTextByKey("retry"),
	                    callbackFunc = function()
	                        checkAndroidId()
	                    end
	                }
	            )
	        end
	        
			if response.httpCode ~= 200 then
				checkErr()
	            return
			end
			
	        if response.body == nil or response.body == "" then
	            checkErr()
	            return
	        end
	        
            --local tstr = table.serialize(response)
            --he_log_info("+++++++++++++++++++++++++++Android Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
                                    		
	        local rTable = table.deserialize(response.body)		
	        if rTable.code ~= 1 then
	        	he_log_error("error code is: "..rTable.code)
	            checkErr()
	            return
	        end

	        Android_sid = sk
	        
	        if afterLoginAndroid and type(afterLoginAndroid) == "function" then
	            afterLoginAndroid()
	        end
	    end
	    RequestLoadingBox:createLoadingBox(false)
		RequestLoadingBox:showLoadingBox()
	    HttpClient:getInstance():sendRequest(onCheckAndroidIdFinish, request)
	end
	
    checkAndroidId()

end 

function logoutGooglePlayTW()
	hasLoginAndroid = false
end 
function getGooglePlayTWUdid()
	return MetaInfo:getInstance():getUdid()
end

function getGooglePlayTWSid()
	return Android_sid
end