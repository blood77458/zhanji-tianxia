local Ios_sid = -999
local hasLoginIos = false
function loginIos(afterLoginIos)
    local checkIosId = nil
	if hasLoginIos then
		return
	end
	hasLoginIos = true
	
    checkIosId = function()
	    he_log_info("+++++++++++++++++++++++++++Ios Log:start check ios id++++++++++++++++++++++++++++++++")
	    local url = DataManager.SystemConfig.CheckIosIdUrl

	    local request = HttpRequest:createPost(url)
	    
	    local timeout = 10
	    
	    request:setConnectionTimeoutMs(timeout * 1000)
	    
	    request:setTimeoutMs(timeout * 1000)
	    
	    request:addHeader("Content-Type:application/x-www-form-urlencoded")

	    local udid = PlatformMgr:getInstance():getDeviceId()
	    local time = TimeUtil.getServerTimeSeconds()
	    local sk = PlatformMgr:getInstance():encodeData(udid..time)
	    local dataString ="udid="..url_encode(udid)
	    dataString = dataString.."&seconds="..url_encode(time)
	    dataString = dataString.."&sk="..url_encode(sk)
	    he_log_info("dataString is:"..dataString)
	    
	    local dataStringLen = dataString:len()
	    
	    request:setPostData(dataString, dataStringLen)
	    
	    local function onCheckIosIdFinish(response)
	        he_log_info("+++++++++++++++++++++++++++IOS Log:Check ios id finish++++++++++++++++++++++++++++++++")
	        local function checkErr()
	            he_log_error("+++++++++++++++++++++++++++IOS Log:check ios id error++++++++++++++++++++++++++++++++")
				RequestLoadingBox:removeLoadingBox()
	            CanonMessageBox.showText(
	                ShowButtonType.ID_OK,
	                getTextByKey("popup_networkError"),
	                nil,
	                {
	                    text = getTextByKey("retry"),
	                    callbackFunc = function()
	                        checkIosId()
	                    end
	                }
	            )
	        end
	        
	        if response.body == nil or response.body == "" then
	            checkErr()
	            return
	        end
	        		
	        local rTable = table.deserialize(response.body)		
	        if response.httpCode ~= 200 or rTable.code ~= 1 then
	        	he_log_error("error code is: "..rTable.code)
	            checkErr()
	            return
	        end

	        Ios_sid = sk
	        
	        if afterLoginIos and type(afterLoginIos) == "function" then
	            afterLoginIos()
	        end
	    end
	    RequestLoadingBox:createLoadingBox(false)
		RequestLoadingBox:showLoadingBox()
	    HttpClient:getInstance():sendRequest(onCheckIosIdFinish, request)
	end
	
    checkIosId()

end 

function logoutIos()
	hasLoginIos = false
end 
function getIosUdid()
	return PlatformMgr:getInstance():getDeviceId()
end

function getIosSid()
	return Ios_sid
end

function IosPlatformPay(productInfo, callbackFunc, funcName)
	local function payCallBackFunc( result, info)
		if result then		        
	        local hasRetryCheck = false
	        local retryWaitDuring = 15 -- retry send check order request during 15 seconds if check fail
	        local sendCheckOrderRequest = nil
	        local retrySchedule = nil
	        
	        local function ValidatePaymentOrderSucceedResponse(evt)
	            if retrySchedule then
	                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(retrySchedule)
	                RequestLoadingBox:removeLoadingBox()
	                retrySchedule = nil
	            end
	            
	            if callbackFunc and type(callbackFunc) == "function" then
	                callbackFunc(evt.data.succ,evt)
	            end
	        end
	        
	        local function ValidatePaymentOrderFailedResponse(evt)

	            if evt.data == 716152 then
	                if not hasRetryCheck then
	                    RequestLoadingBox:createLoadingBox(false)
	                    RequestLoadingBox:showLoadingBox()
	                    hasRetryCheck = true
	                    retrySchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(sendCheckOrderRequest,retryWaitDuring,false)
	                    he_log_info("+++++++++check order err ")
	                    return
	                end
	            end
	            
	            if retrySchedule then
	                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(retrySchedule)
	                RequestLoadingBox:removeLoadingBox()
	                retrySchedule = nil
	            end
	                    
	            if callbackFunc and type(callbackFunc) == "function" then
	                callbackFunc(false,evt)
	            end
	        end
	        
	        sendCheckOrderRequest = function ()
	            local request = ValidatePaymentOrderRequest.new( {orderId = info}, rpc.SendingPriority.kHigh )
	            request:addEventListener( RequestNotifyEnum.ValidatePaymentOrderSucceed, ValidatePaymentOrderSucceedResponse )
	            request:addEventListener( RequestNotifyEnum.ValidatePaymentOrderFailed, ValidatePaymentOrderFailedResponse )
	            request:start()
	        end
	        
	        sendCheckOrderRequest()

		else
	        if callbackFunc and type(callbackFunc) == "function" then
	            callbackFunc(false)
	        end
		end
	end

	if funcName == nil then
		funcName = "exchange"
	end
	local userInfo = DataManager.getCurrUser()
    local platform = getPlatFormIgnoreDevice()
    if isI4ios() then
        platform = "iosi4"
    end

    if isHaimaIos() then
    	local function getWaresid()
    		local waresid = "-999"
        	if  funcName == "shop" then
            	waresid = "9"
	        else
				waresid = productInfo.id:split("_")[2]
				if string.sub(waresid,1,1) == "0" then
					waresid = string.sub(waresid,string.len(waresid))
				end
	        end
	    	return waresid
	 	end 
  
    	local waresid = getWaresid()
    	productInfo.waresid = waresid
    end

	local extendString = {
		platform = platform,
		zone_id = DataManager.getZoneId(),
		server_id = DataManager.getServerid(),
		func_name = funcName,
		waresid = 0,
        role_id = userInfo.uid,
        _user_id = string.sub(userInfo.uid,1,string.len(userInfo.uid)-4)
	}
	extendString = table.serialize(extendString)
    productInfo.itemDescKey = getTextByKey(productInfo.itemDescKey)
    productInfo.itemNameKey = getTextByKey(productInfo.itemNameKey)
    
    productInfo =  table.serialize( productInfo )
    he_log_info("+++++++++++productInfo: " .. productInfo)
    
    if isI4ios() or isHaimaIos() or isKuaiYongIos() or isTongbuIos() then
        PlatformMgr:getInstance():pay(productInfo, extendString, payCallBackFunc)
    else
        IosPaymentLua:getInstance():pay(productInfo.id, extendString, payCallBackFunc)
        --PlatformMgr:getInstance():pay(productInfo.id, extendString, payCallBackFunc)
    end
end
