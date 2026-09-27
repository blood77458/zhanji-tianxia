require "hecore.EventDispatcher"
require "hecore.rpc"
require "canon.data.DataManager"
require "canon.request.localStorage"
require "canon.utils.TimeUtil"

CommunicationInitEvent = table.const {
	kComplete = "complete",
	kInitSessionSuccess = "initSessionSuccess",
	kInitSessionError = "initSessionError",
	kLoginSuccess = "loginSuccess",
	kLoginError = "loginError",
}

local DefaultErrorHandler = class()

function DefaultErrorHandler:ctor(errors)
  self.errors = errors
end

function DefaultErrorHandler:handleError(endpoints, err , otherParams)
	he_log_error("default handleError, err: " .. err .. ", endpoints: " .. table.serialize(endpoints))
	if endpoints[1] == "login" then
		local warningStr = getTextByKey("popup_networkError")
		if err == 111 then--UC停服
			warningStr = getTextByKey("uc_warn")
		elseif err == 106 then
			warningStr = getTextByKey("newVersion_error")
		end
		if err == 111 or err == 106 then--UC停服
				CanonMessageBox.showText(
				ShowButtonType.ID_OK,
				warningStr,
				nil,
				{
					text = getTextByKey("yes"),
					callbackFunc = function()
					PlistResMgr:getInstance():terminateProcess()
					end
				}
			)
				return
			end
		RequestLoadingBox:removeLoadingBox()
		Communication:getInstance():dispatchEvent(Event.new(CommunicationInitEvent.kLoginError, err))

	elseif err < 200 then
		local warningStr = getTextByKey("popup_networkError")
		if err == 108 then
			warningStr = getTextByKey("login_wrong_account2")
		elseif err == 109 then
			local limitEndTime = TimeUtil.formatDate(otherParams.banEndSeconds)
			warningStr = getTextByKey("silenced_text1")..limitEndTime
		elseif err == 111 then
			warningStr = getTextByKey("uc_warn")
		elseif err == 106 then
			warningStr = getTextByKey("newVersion_error")
		end
			-- TODO: handle global error
			--silian temp add
		Dialog_SetScreenTouchEnabled( true ); --让屏幕可以点击
        Terminate_New_User_Guide(); --终止当前新手引导
		Terminate_All_ShowDialogBoxes()
		for i=1,#endpoints do
			RequestLoadingBox:removeLoadingBox()
		end
		
		if err == 111 or err == 106 then--UC停服
			CanonMessageBox.showText(
			ShowButtonType.ID_OK,
			warningStr,
			nil,
			{
				text = getTextByKey("yes"),
				callbackFunc = function()
				PlistResMgr:getInstance():terminateProcess()
				end
			}
		)
			return
		end

		CanonMessageBox.showText(
			ShowButtonType.ID_OK,
			warningStr,
			nil,
			{
				text = getTextByKey("yes"),
				callbackFunc = function()
          NotificationManager:dispatchEvent(Event.new("GLOBAL_ERROR"))
					local loadingScene = LoadingScene:create()
					Director:sharedDirector():replaceScene( loadingScene )
				end
			}
		)
	end
end

Communication = class(EventDispatcher)

local _instance = nil
function Communication:getInstance()
	if not _instance then
		_instance = Communication.new()
	end
	return _instance
end

function Communication:setUser( content )
    local fiels = content:split(",")
    self.uid = fiels[1]
    self.uuid = fiels[2]
    self.sessionKey = fiels[3]
end

function Communication:initSession(p_uid,p_uuid,callbackFunc)
	he_log_info("begin init session ...")
  
    local uid = -1
    if(self.uid and tonumber(self.uid) > 0) then
        uid = tonumber(self.uid)
    end
    
    if p_uid then
        uid = p_uid
    end
    
    if p_uuid then
        self.uuid = p_uuid
    end 
    local url = DataManager.SystemConfig.SessionKeyUrl
    
	local request = HttpRequest:createPost(url)
	local function onInitSessionFinish(response)
		if response.httpCode ~= 200 then
		    he_log_error("init session fail, response: " .. table.serialize(response))
		    self:dispatchEvent(Event.new(CommunicationInitEvent.kInitSessionError))
		    return
		end
		local fiels = response.body:split(",")
		he_log_info("init session finish " .. table.serialize(fiels))
		self.uid = fiels[1]
		self.uuid = fiels[2]
		self.sessionKey = fiels[3]
        setNewAccountId(self.uid)
		if self.uid ~= "-1" then 
            localStorage.setCurrentUser(response.body)
            AntiAddictionManager.initAddictionTimer(self.uid)
            he_log_info("+++++++++++++++++++++++++++ Login Log:initSession finish ++++++++++++++++++++++++++++++++")
            setNewAccountId(tonumber(self.uid))
            self:dispatchEvent(Event.new(CommunicationInitEvent.kInitSessionSuccess))
            he_log_info("+++++++++++++++++++++++++++ Login Log:dispatchEvent(CommunicationInitEvent.kInitSessionSuccess) ++++++++++++++++++++++++++++++++")
            
		else
			self:dispatchEvent(Event.new(CommunicationInitEvent.kInitSessionError))
		end
	end
	
	local timeout = 15
	request:setConnectionTimeoutMs(timeout * 1000)
    request:setTimeoutMs(timeout * 1000)
    --request:addHeader("Content-Type:application/octet-stream")
    request:addHeader("Content-Type:application/x-www-form-urlencoded")
	local dataString = "uid=" .. tostring(uid) .. "&uuid=" .. tostring(self.uuid)
	dataString = dataString .. "&udid=" .. MetaInfo:getInstance():getUdid()
	dataString = dataString .. "&sdCardRoot=" .. MetaInfo:getInstance():getSdCardRoot()
	dataString = dataString .. "&ip=" .. MetaInfo:getInstance():getIpAddress()
	dataString = dataString .. "&phoneNumber=" .. MetaInfo:getInstance():getPhoneNum()
	dataString = dataString .. "&imei=" .. MetaInfo:getInstance():getImei()
	dataString = dataString .. "&simCountry=" .. MetaInfo:getInstance():getSimCountry()
	dataString = dataString .. "&netOperatorName=" .. MetaInfo:getInstance():getNetOperatorName()
	dataString = dataString .. "&netOperatorNum=" .. MetaInfo:getInstance():getNetOperatorNum()
	dataString = dataString .. "&iccid=" .. MetaInfo:getInstance():getIccid()
	dataString = dataString .. "&imsi=" .. MetaInfo:getInstance():getImsi()
	dataString = dataString .. "&filesDir=" .. MetaInfo:getInstance():getFilesDir()
	dataString = dataString .. "&crashLogDir=" .. MetaInfo:getInstance():getCrashLogDir()
	dataString = dataString .. "&packageName=" .. MetaInfo:getInstance():getPackageName()
	dataString = dataString .. "&language=" .. MetaInfo:getInstance():getLanguage()
	dataString = dataString .. "&mac=" .. MetaInfo:getInstance():getMacAddress()
	dataString = dataString .. "&apkVersionCode=" .. MetaInfo:getInstance():getApkVersionCode()
	dataString = dataString .. "&gameVersion=" .. MetaInfo:getInstance():getApkVersion()
	dataString = dataString .. "&location=" .. MetaInfo:getInstance():getCountry()
	dataString = dataString .. "&timeZone=" .. MetaInfo:getInstance():getTimeZone()
	dataString = dataString .. "&clientVersion=" .. MetaInfo:getInstance():getOsVersion()
	dataString = dataString .. "&clientType=" .. MetaInfo:getInstance():getDeviceModel()
	dataString = dataString .. "&machineType=" .. MetaInfo:getInstance():getMachineType()
	dataString = dataString .. "&equipment=" .. (MetaInfo:getInstance():isJailbreak() and "crack" or "nocrack")
	dataString = dataString .. "&deviceModel=" .. MetaInfo:getInstance():getDeviceModel()
	dataString = dataString .. "&networkInfo=" .. tostring(MetaInfo:getInstance():getNetworkInfo())
	dataString = dataString .. "&densityIndependentPixel=" .. MetaInfo:getInstance():getDensityIndependentPixel()
	dataString = dataString .. "&dotsPerInch=" .. MetaInfo:getInstance():getDotsPerInch()
	dataString = dataString .. "&resolution=" .. MetaInfo:getInstance():getResolutionWidth() .. "*" .. MetaInfo:getInstance():getResolutionHeight()
	dataString = dataString .. "&resolutionHeight=" .. MetaInfo:getInstance():getResolutionHeight()
	dataString = dataString .. "&resolutionWidth=" .. MetaInfo:getInstance():getResolutionWidth()
	dataString = dataString .. "&deviceSerialNumber=" .. MetaInfo:getInstance():getDeviceSerialNumber()
	dataString = dataString .. "&sdk=" .. MetaInfo:getInstance():getSdk()
	dataString = dataString .. "&networkType=" .. tostring(MetaInfo:getInstance():getSimNetworkType())
	dataString = dataString .. "&carrier=" .. tostring(MetaInfo:getInstance():getSimPhoneType())
	dataString = dataString .. "&cpuAbi=" .. MetaInfo:getInstance():getCpuAbi()
	dataString = dataString .. "&isCpuArmv7a=" .. (MetaInfo:getInstance():isCpuArmv7a() and "true" or "false")
	dataString = dataString .. "&sessionUuid=" .. MetaInfo:getInstance():getSessionUuid()
	dataString = dataString .. "&installKey=" .. MetaInfo:getInstance():getInstallKey()
	dataString = dataString .. "&isCpuArmv7a=" .. (MetaInfo:getInstance():isCpuArmv7a() and "true" or "false")
	dataString = dataString .. "&isRoot=" .. (MetaInfo:getInstance():isRoot() and "true" or "false")
	dataString = dataString .. "&localIpAddress=" .. MetaInfo:getInstance():getLocalIpAddress()
	dataString = dataString .. "&releaseVersion=" .. StartupConfig:getInstance():getReleaseVersion()
	
    dataString = dataString .. "&store=" .. getPlatFormIgnoreDevice()
    dataString = dataString .. "&src="  .. getPlatFormIgnoreDevice()
        
    dataString = dataString .. "&install_key=" ..MetaInfo:getInstance():getInstallKey()
    dataString = dataString .. "&uniqid=" .. MetaInfo:getInstance():getUdid()
    dataString = dataString .. "&platform=" .. getPlatFormIgnoreDevice()
	dataString = dataString .. "&isLongyuan=true" 
	if __ANDROID then
		dataString = dataString .. "&simulator=" .. CanonEnvInjector:isAndroidEmulator() --大版本的时候打开
	end
    --该设备时间与格林威治的当前时间相差小时数(可以为负数)
    dataString = dataString .. "&timezoneDiff=" .. (TimeUtil.getTimeZoneTotalDiffSecWithServer()/3600 + 8)
    
	if getPlatFormChannelName and type(getPlatFormChannelName) == "function" then 
		dataString = dataString .. "&channelName=" .. getPlatFormChannelName()
	end

  if __IOS then
   	dataString = dataString .. "&idfa=" .. PlatformMgr:getInstance():getIDFA()
  	dataString = dataString .. "&ios_udid=" .. PlatformMgr:getInstance():getDeviceId()
	else
		dataString = dataString .. "&serial_number=" .. MetaInfo:getInstance():getSerialNumber();
  	dataString = dataString .. "&android_id=" .. MetaInfo:getInstance():getUdid()
  end
        
	local dataStringLen = dataString:len()
	request:setPostData(dataString, dataStringLen)
	
	HttpClient:getInstance():sendRequest(onInitSessionFinish, request)
end

function Communication:initTransponder()
	he_log_info("begin init transponder ...")
	
	local config = {
	    url = DataManager.SystemConfig.ProtocolUrl.."?uid=" .. tostring(self.uid),
	    queueSize = 10,
	    flushInterval = 10,
	    timeout = 15,
	    defaultPriority = rpc.SendingPriority.kNormal
	}

	local function sessionKeySource(callback)
		callback(self.sessionKey, TimeUtil.getServerTimeSeconds() + 3600 * 24) 
	end

	local function platformFinder()
        if isI4ios() then
            return "iosi4"
        else
            return getPlatFormIgnoreDevice() --"tencent_qzone"
        end
	end

	local transponder = rpc.RpcTransponder.new(config, sessionKeySource)
	transponder:registryConvertor (
		rpc.AssembleConvertor.new(true, "0.3.0", "12306", "canon", "zh_CN", platformFinder, 0)
			, { rpc.CompressConvertor.new(), rpc.HeaderConvertor.new() }
			, { rpc.PackageConvertor.new() }
	)

	transponder:registryHandler(DefaultErrorHandler.new (
		{ [rpc.InternalError.kDefaultError] = true })
	)
  
	transponder:invalidateSessionKey()
	transponder:changeUID(self.uid)
	if not transponder:isBlocked() then transponder:flush() end
	self.transponder = transponder
end

function Communication:registEventHandler(handlerName)
	local handler = require("canon.request." .. handlerName)
	local EventHandlerWrapper = class()
	function EventHandlerWrapper:ctor()
		self.endpoints = { [handler.endpoint] = true }
	end
	function EventHandlerWrapper:handleResponse(endpoint, data)
		handler:handle(data)
	end
	self.transponder:registryHandler(EventHandlerWrapper.new())
end

function Communication:login()
	he_log_info("begin comm login ...")
	local loginCallback = function(endpoint, data, err)
		if err then
			he_log_error("comm login fail, err: " .. err)
			self:dispatchEvent(Event.new(CommunicationInitEvent.kLoginError, err))
			return true
		end
		he_log_info("comm login success " .. table.serialize(data))
		self:dispatchEvent(Event.new(CommunicationInitEvent.kLoginSuccess), data)
	end
	self.transponder:call("login", nil, loginCallback, rpc.SendingPriority.kHigh, true, true)
end

local function onLoginCallback(event)
    Communication:getInstance():communicationLoginCallback(event)
end

local function onInitSessionCallback(event)
    Communication:getInstance():communicationInitSessionCallback(event)
end
    
function Communication:communicationInitSessionCallback(event)
    Communication:getInstance():removeEventListener(CommunicationInitEvent.kInitSessionSuccess, onInitSessionCallback)
	Communication:getInstance():removeEventListener(CommunicationInitEvent.kInitSessionError, onInitSessionCallback)
	
	if event.name == CommunicationInitEvent.kInitSessionSuccess then
        self:initTransponder()
        self:addEventListener(CommunicationInitEvent.kLoginSuccess, onLoginCallback)
        self:addEventListener(CommunicationInitEvent.kLoginError, onLoginCallback)
        self:login()
    end
end

function Communication:communicationLoginCallback(event)
    Communication:getInstance():removeEventListener(CommunicationInitEvent.kLoginSuccess, onLoginCallback)
    Communication:getInstance():removeEventListener(CommunicationInitEvent.kLoginError, onLoginCallback)
    if event.name == CommunicationInitEvent.kLoginSuccess then
        self:dispatchEvent(Event.new(CommunicationInitEvent.kComplete))
    end
end 

function Communication:init()
	
	Communication:getInstance():addEventListener(CommunicationInitEvent.kInitSessionSuccess, onInitSessionCallback)
	Communication:getInstance():addEventListener(CommunicationInitEvent.kInitSessionError, onInitSessionCallback)
    
    --[[
    if isUCAndroid() or is91Android() or isXiaomiAndroid() or is360Android() or isDKAndroid() or isWdjAndroid() 
        or isOppoAndroid() or isPlatformIos() or isYyhAndroid() or isPlatformAndroid() or isBukaAndroid() 
        or isIosTW() or isGooglePlayTW() or isTWHE() or isChuangMengAndroid() or isOfficialPlatformFunc() or isYYBAndroid() 
	or isLongyuanPlatformFunc() or isAnzhiAndroid() or isVivoAndroid() or isI4ios() or isHaimaIos() or isKuaiYongIos() then
    --]]
    if true then
        --he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:begin initSession step1++++++++++++++++++++++++++++++++")
    else
        Communication:getInstance():initSession()
    end
end

function Communication:putOthers(key, value)
	self.transponder.processor.convertorRegistry.assembleConvertor.others[key] = value
end

function Communication:request(endpoint, params, callback, priority, retry)
	if (not self.transponder) then
		RequestLoadingBox:removeLoadingBox()
		--silian temp add
		Dialog_SetScreenTouchEnabled( true ); --让屏幕可以点击
        Terminate_New_User_Guide(); --终止当前新手引导
		Terminate_All_ShowDialogBoxes()
    
		CanonMessageBox.showText(
			ShowButtonType.ID_OK,
			getTextByKey("popup_networkError"),
			nil,
			{
				text = getTextByKey("retry"),
				callbackFunc = function()
					local loadingScene = LoadingScene:create()
					Director:sharedDirector():replaceScene( loadingScene )
				end
			}
		)
	else
		if retry then
			self.transponder:setRetryTimes(1)
		else
			self.transponder:setRetryTimes(0)
		end
		self.transponder:call(endpoint, params, callback, priority)
	end
end
