local _sid = -999
local _uid = -999
local _loginType = 1
--ios登录
--loginType 1为游客登录
--loginType 2为账号登录
local _accountMixed = false

function isOfficalAccountPlatform()
    return isPlatformAndroid() or isPlatformIos() or isBukaAndroid() or isGooglePlayTW() or isIosTW() or isTWHE() or isChuangMengAndroid() or isOfficialPlatformFunc() or isLongyuanPlatformFunc()
end

local function showCommonErrorBox(callback)
    CanonMessageBox.showText(
        ShowButtonType.ID_OK,
        getTextByKey("popup_networkError"),
        nil,
        {
            text = getTextByKey("retry"),
            callbackFunc = function()
                callback()
            end
        }
    )
end
---
function bindAccountWithDevice(account, onBindAccountFinished)
	local url = DataManager.SystemConfig.RebindAccountUrl

	local params = {}
	params.account = account;
	params.deviceId = getDeviceId()
	params.seconds = TimeUtil.getServerTimeSeconds()
	params.platformId = getPlatFormId()
	params.sk = HeMathUtils:md5(account..params.deviceId..params.seconds)

	local function onBindAccountFinish( response )
		if response.httpCode ~= 200 then
			showCommonErrorBox(function()
				bindAccountWithDevice(account, onBindAccountFinished)
			end)
			return
		end

		local rTable = table.deserialize(response.body)
		if rTable.code ~= 1 then
			if rTable.code == -3 then
				showLoginErrorBox(getTextByKey("login_wrong_register"))
			else
				showCommonErrorBox(function()
					bindAccountWithDevice(account, onBindAccountFinished)
				end)
			end
		else
			onBindAccountFinished()
		end
	end

	doHttpRequest(url, params, onBindAccountFinish, true, true)
end

function accountGetBoundMapping()
    DcManager.sendLoadingActivity(65, ((os.time() - g_startTime )*1000) )
    
    local url = DataManager.SystemConfig.GetBoundMappingUrl

    local platformId = getPlatFormId()
    local sid = url_encode(_sid)
    local platformUid
    if _loginType == 1 then
    	platformUid = url_encode(getDeviceId())
    else
    	platformUid = url_encode(_uid)
    end

    local params = {}
    params.platformId = platformId
    params.platformUid = platformUid
    params.sid = sid

    local function onGetBoundMappingFinish(response)
    	if response.httpCode ~= 200 then
            showCommonErrorBox(accountGetBoundMapping)
            return		
    	end
        local rTable = table.deserialize(response.body)
        if rTable.code ~= 1 then
            showCommonErrorBox(accountGetBoundMapping)
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

    print("current params are "..table.tostring(params))
	doHttpRequest(url, params, onGetBoundMappingFinish, false, true)
end

local hasLoginAccount = false
function loginAccount(token, loginType, afterLoginAccount)
    local checkAccountId = nil
	if hasLoginAccount then
		return
	end
	hasLoginAccount = true
	_loginType = loginType
	
    checkAccountId = function()
	    local url = getCheckDeviceUrl(getPlatFormId())
	    local params = {}
	    local sk
	    if isPlatformIos() then
		   	local udid = token
		    local seconds = TimeUtil.getServerTimeSeconds()
		    sk = PlatformMgr:getInstance():encodeData(udid..seconds)

		    params.udid = url_encode(udid)
		    params.seconds = url_encode(seconds)
		    params.sk = url_encode(sk)
		    params.loginType = _loginType
	    elseif isPlatformAndroid() or isGooglePlayTW() or isIosTW() or isBukaAndroid() or isTWHE() or isChuangMengAndroid() or isOfficialPlatformFunc() or isLongyuanPlatformFunc() then
	    	local udid = token
		    local seconds = TimeUtil.getServerTimeSeconds()
		    sk = HeMathUtils:md5(udid..seconds.."123456")
		    
		    params.udid = url_encode(udid)
		    params.seconds = url_encode(seconds)
		    params.sk = url_encode(sk)
		    params.loginType = _loginType
		else
			
	    end

	    local function onCheckAccountIdFinish(response)
	        local function checkErr()
	            showCommonErrorBox(checkAccountId)
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

	        print("rTable is "..table.tostring(rTable))

	        _sid = sk
	        if not rTable.loginAccountId then
	        	_uid = -1
	        else
	        	_uid = rTable.loginAccountId
	        end
	        
	        if afterLoginAccount and type(afterLoginAccount) == "function" then
	            afterLoginAccount()
	        end
	    end
	    doHttpRequest(url, params, onCheckAccountIdFinish, false, true)
	end
	
    checkAccountId()

end 

function checkAccount(account, password, callback)
	local function onAccoutCheckResponse( response )
		callback(response)
	end
	local url = DataManager.SystemConfig.LoginAccountUrl
	local params = {}
	params.account = account
	params.password = password
	params.deviceId = getDeviceId()
	params.seconds = TimeUtil.getServerTimeSeconds()
	params.sk = HeMathUtils:md5(account..password..params.seconds)

	doHttpRequest(url, params, onAccoutCheckResponse, true, true)
end

function checkDeviceGuestAccount( onSuccessCallback )
	local function onDeviceChecked( response )
		if response.httpCode ~= 200 then
			showCommonErrorBox(function()
				checkDeviceGuestAccount( onSuccessCallback )
			end)
			return
		end
		local rTable = table.deserialize(response.body)
		onSuccessCallback(rTable)
	end
	local url = DataManager.SystemConfig.CheckDeviceAccountUrl
	local params = {}
	params.platformId = getPlatFormId()
	params.deviceId = getDeviceId()

	doHttpRequest(url, params, onDeviceChecked, false, true)
end

function guestLoginAccount(afterLogin)
	loginAccount(getDeviceId(), 1, afterLogin)
end

function logoutAccount()
	hasLoginAccount = false
end 

----取得平台的uid，为check/接口返回的token
function getAccountUid()
	if not _uid or _uid == -1 then
		return getDeviceId()
	else
		return _uid
	end
end

----取得平台的sid
function getAccountSid()
	return _sid
end

function getDeviceId()
	if __IOS then
		return PlatformMgr:getInstance():getDeviceId()
	elseif __ANDROID then
		return MetaInfo:getInstance():getUdid()
	end
end

function getCheckDeviceUrl()
	if isPlatformIos() then
		return DataManager.SystemConfig.CheckIosIdUrl
	elseif isPlatformAndroid() then
		return DataManager.SystemConfig.CheckAndroidIdUrl
	elseif isGooglePlayTW() then
		return DataManager.SystemConfig.CheckGooglePlayTWIdUrl
	elseif isTWHE() then
		return DataManager.SystemConfig.CheckTWHEIdUrl
	elseif isIosTW() then
		return DataManager.SystemConfig.CheckTWIosIdUrl
	elseif isBukaAndroid() then
		return DataManager.SystemConfig.CheckBuKaIdUrl
	elseif isChuangMengAndroid() then
		return DataManager.SystemConfig.CheckChuangMengIdUrl
	elseif isPujiaAndroid() then
		return DataManager.SystemConfig.CheckPujiaIdUrl
	elseif isOfficialPlatformFunc() then
		return DataManager.SystemConfig.CheckOfficialIdUrl
	elseif isLongyuanPlatformFunc() then
		return DataManager.SystemConfig.CheckLongyuanIdUrl
	end
end

--是否和服开关开启
function setAccountMixed( mixed )
	_accountMixed = mixed
end

function checkAccountInTwinList(username)
	if __ANDROID then
		return false
	end
	local usernameTable = LocalAccountManager.getSameUsernameTable()
	for k, v in pairs(usernameTable) do
		if v == username then
			return true
		end
	end
	return false
end

--重置密码
function resetkPassword(account, email, callback)
	local function onAccoutCheckResponse( response )
		callback(response)
	end
	local url = DataManager.SystemConfig.ResetPasswordUrl
	local params = {}
	params.account = account
	params.email = email
	params.deviceId = getDeviceId()
	params.seconds = TimeUtil.getServerTimeSeconds()
	params.sk = HeMathUtils:md5(account..email..params.seconds)

	doHttpRequest(url, params, onAccoutCheckResponse, true, true)
end

local hasBindEmail = false
function getAccountHasBindEmail()
	return hasBindEmail
end

function setAccountHasBindEmail(hasBind)
	hasBindEmail = hasBind
end

function checkIsGuestAccountLogin()
	if _loginType == 1 then
		return true
	else
		return false
	end
end

CurAccountEmailStatus = {
	NoNeedEmail = 0,	--非官方账号平台
	NoBindEmail = 1,	--官方账号登陆未绑定邮箱
	BindedEmail = 2,	--官方账号已绑定邮箱
	NoHaveEmail = 3,	--游客账号登陆，没邮箱
}

function getCurAccountEmailStatus()
	if isOfficalAccountPlatform() then
		if _loginType == 1 then
			return CurAccountEmailStatus.NoHaveEmail
		else
			if hasBindEmail then
				 he_log_info("+++++++++++++++++++++++++++login account Log:return CurAccountEmailStatus.BindedEmail")
				return CurAccountEmailStatus.BindedEmail
			else
				return CurAccountEmailStatus.NoBindEmail
			end
		end
	else
		return CurAccountEmailStatus.NoNeedEmail
	end
end

local oldEmail = ""
local newEmail = ""
function getOldEmail()
	return oldEmail
end

function getNewEmail()
	return newEmail
end

function setOldEmail(email)
	oldEmail = email
end

function setNewEmail(email)
	newEmail = email
end
