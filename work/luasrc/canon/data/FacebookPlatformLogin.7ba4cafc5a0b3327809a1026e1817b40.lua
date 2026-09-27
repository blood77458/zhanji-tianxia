local _facebookManager = nil
local _uid = nil
local _sid = nil

local function showCommonErrorBox(callback)
    CanonMessageBox.showText(
        ShowButtonType.ID_OK,
        getTextByKey("popup_networkError"),
        nil,
        {
            text = getTextByKey("retry"),
            callbackFunc = function()
                if callback and type(callback) == "function" then
                	callback()
                end
            end
        }
    )
end

function getFacebookSid( )
	return _sid
end

function getFacebookUid( )
	return _uid
end

--you need to check both facebook and offical account before call this method
function bindFacebookAccountWithUsername( account, onBindAccountFinished )
	local function onBindFinish(response )
        if response.httpCode ~= 200 then
            showCommonErrorBox(function()
                bindFacebookAccountWithUsername(account, onBindAccountFinished)
            end)
            return     
        end
        if response.body == nil or response.body == "" then
            showCommonErrorBox(function()
                bindFacebookAccountWithUsername(account, onBindAccountFinished)
            end)
            return
        end

        local rTable = table.deserialize(response.body)        
        if rTable.code == 0 or rTable.code == 1 then
            onBindAccountFinished()
        elseif rTable.code == -4 then
            CanonMessageBox.showText(
                ShowButtonType.ID_OK,
                getTextByKey("login_facebook_wrong"),
                nil,
                {
                    text = getTextByKey("yes"),
                }
            )
        end

	end

	local url = DataManager.SystemConfig.BindFacebookAccountUrl
	local facebookPlatformId = ThirdPlatformDict.facebook
	local facebookUid = getFacebookUid()
	local facebookSid = getFacebookSid()
	local curPlatformId = getPlatFormIdMain()
	local officalUid = account
	local officalSid = getAccountSid()
    local params = {
    				facebookId = facebookPlatformId,
    				facebookUid = facebookUid,
    				facebookSid = facebookSid,
    				platformId = curPlatformId,
    				platformUid = officalUid,
    				platformSid = officalSid
    				} 

    doHttpRequest(url, params, onBindFinish, false, true)
end

function facebookGetBoundMapping( )
	DcManager.sendLoadingActivity(65, ((os.time() - g_startTime )*1000) )

    local url = DataManager.SystemConfig.GetBoundMappingUrl

    local platformId = ThirdPlatformDict.facebook
    local params = {
    	platformId = platformId,
    	platformUid = url_encode(_uid),
    	sid = url_encode(_sid)
	}

	local function onGetBoundMappingFinish( response )
		if response.httpCode ~= 200 then
            showCommonErrorBox(facebookGetBoundMapping)
            return		
    	end
        local rTable = table.deserialize(response.body)
        if rTable.code ~= 1 then
            showCommonErrorBox(facebookGetBoundMapping)
            return
        end
        
        DcManager.sendLoadingActivity(67, ((os.time() - g_startTime )*1000) )

        local accountId = rTable.accountId
        local getToken = rTable.token
        if tonumber(accountId) == -1 then
            setIsNewUser(true)
        else
            setIsNewUser(false)
        end 

        Communication:getInstance():init()
        Communication:getInstance():initSession(accountId,getToken)
	end

	DcManager.sendLoadingActivity(66, ((os.time() - g_startTime )*1000) )

	doHttpRequest(url, params, onGetBoundMappingFinish, false, true)
end

function checkFacebookSession(facebookId, onFacebookCheckFinished)
	local url = DataManager.SystemConfig.CheckFacebookIdUrl

	local seconds = TimeUtil.getServerTimeSeconds()
	local sk = HeMathUtils:md5(_md5Uid..seconds.."654321")
	local params = {
		udid = _md5Uid,
        unencrypted_uid = facebookId,
		seconds = seconds,
		sk = sk
	}

	local function onCheckFacebookFinish( response )
        print(table.tostring(response))
        local function checkErr()
            showCommonErrorBox()
        end
        		
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
            checkErr()
            return
        end

        _sid = sk
        _uid = facebookId
        onFacebookCheckFinished(rTable.officalAccount)
	end


	doHttpRequest(url, params, onCheckFacebookFinish, false, true)
end

function initFacebookSession(callback)
    if __IOS then
      _facebookManager = require "hecore.sns.facebook.FacebookIOS"
    elseif __ANDROID then
      _facebookManager = require "hecore.sns.facebook.FacebookAndroid"
    end
    local function onSessionInited()
        callback()
    end
	he_log_info("++++++++++++facebook init")
    _facebookManager:init(onSessionInited)
end

function doFacebookLogin( afterFacebookLogin )
	setPlatFormId(ThirdPlatformDict.facebook)
    RequestLoadingBox:createLoadingBox(false)
    RequestLoadingBox:showLoadingBox()
    _facebookManager:login(function(status, data)
		if status == SnsCallbackEvent.onSuccess then
			local getUserInfo = nil
			getUserInfo = function()
				_facebookManager:userInfo(function( result, userInfo )
                    RequestLoadingBox:removeLoadingBox()
					if result == SnsCallbackEvent.onError then
                        print(table.tostring(userInfo))
						showCommonErrorBox(getUserInfo)
					elseif result == SnsCallbackEvent.onSuccess then
                        _uid = userInfo.id;
						--he_log_info("++++++++++++facebook sendRequest result = " .. table.serialize(userInfo))
						--he_log_info("++++++++++++facebook login uid = " .. _uid)
						_md5Uid = HeMathUtils:md5(_uid.."facebook0000")
						afterFacebookLogin(_uid, userInfo.name)
					end
				end)
			end
			getUserInfo()
		elseif status == SnsCallbackEvent.onError then
            RequestLoadingBox:removeLoadingBox()
            CanonMessageBox.showText(
                ShowButtonType.ID_OK,
                getTextByKey("login_facebook_text8")
            )
		end
    end)
end

function isFacebookLogin()
    if _facebookManager then
        return _facebookManager:isLogin()
    end
    return false
end

function isFacebookSessionLoaded()
    if _facebookManager then
        return _facebookManager:isSessionStateLoaded()
    end
    return false
end

function logoutFacebook()
	if _facebookManager then
		return _facebookManager:logout()
	end
    return false
end

function feedFacebook(callback,captionPara,namePara,descPara)
	local function doFacebookFeed()
		local params = {
					caption = captionPara,
					name = namePara, 
					description = descPara,
					link = "http://www.senki.tw/", --台湾粉丝页官网
					picture = "http://statictw.canon.he-games.com/web/ad/facebookNeedIcon.png" --cdn图片
		}
		--he_log_info("++++++++++++goto facebook feed")
		 _facebookManager:presendFeed(function(status, data)
			if status == SnsCallbackEvent.onSuccess then
				--he_log_info("++++++++++++feed status == SnsCallbackEvent.onSuccess")
				callback()
			elseif status == SnsCallbackEvent.onError then
				CanonMessageBox.showText(
								ShowButtonType.ID_OK,
								getTextByKey("Fbactivity_error_txt2"),
								nil,
								{
									text = "ok",
									callbackFunc = function()
									end
								}
							)    
			end
		end,params)
	end
	if isBindFacebook() then
	--if true then
		--是否是绑定过facebook的账号
		--是则继续
		--否则先绑定
		if isFacebookLogin() then
			doFacebookFeed()
		else
			logoutFacebook() 
			--he_log_info("++++++++++++login first then to feed")
			doFacebookLogin(doFacebookFeed)            
		end
	else
		CanonMessageBox.showText(
								ShowButtonType.ID_OK,
								getTextByKey("Fbactivity_error_txt1"),
								nil,
								{
									text = "ok",
									callbackFunc = function()
									end
								}
							)     
	end
	
end

function sendRequestToFacebook(callback,captionPara,namePara,descPara)
	local function sendRequest()
		local params = {
					title = captionPara,
					message = descPara
		}
		he_log_info("++++++++++++goto facebook sendRequest")
		 _facebookManager:sendRequest(function(status, data)
			if status == SnsCallbackEvent.onSuccess then
				--he_log_info("++++++++++++facebook sendRequest result = " .. table.serialize(data))
				callback(data)
			elseif status == SnsCallbackEvent.onError then
				CanonMessageBox.showText(
								ShowButtonType.ID_OK,
								getTextByKey("Fbactivity_error_txt3"),
								nil,
								{
									text = "ok",
									callbackFunc = function()
									end
								}
							)    
			end
		end,params)
	end
	if isBindFacebook() then
	--if true then
		--是否是绑定过facebook的账号
		--是则继续
		--否则先绑定
		if isFacebookLogin() then
			sendRequest()
		else
			logoutFacebook() 
			--he_log_info("++++++++++++login first then to sendRequest")
			doFacebookLogin(sendRequest)            
		end
	else
		CanonMessageBox.showText(
								ShowButtonType.ID_OK,
								getTextByKey("Fbactivity_error_txt1"),
								nil,
								{
									text = "ok",
									callbackFunc = function()
									end
								}
							)     
	end
end