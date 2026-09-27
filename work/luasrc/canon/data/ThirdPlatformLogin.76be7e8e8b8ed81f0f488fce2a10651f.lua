require "canon.luajava.CanonEnvInjector" 
require "canon.data.IosPlatformLogin"
require "canon.data.AndroidPlatformLogin"

local accountId = -999
local token = -999

-------------------------------
-------platFormId define-------
-------------------------------
--0: undefined windows
--1: UC android
-------------------------------
ThirdPlatformDict = {
                        default = 0,
                        uc = 1,
                        nd91 = 2,
                        mi = 3,
                        qihoo360 = 4,
                        ios = 5,
                        baiduDK = 6,
                        wdj = 7,
                        gamecenter = 8,
                        lenovo = 9,
                        yingyonghui = 10,
                        he = 11,
                        ios91 = 12,
                        iosPP = 13,
						googleplay = 14,
                        ibuka = 16,
			            iosTW = 17,
						twhe = 19,
						chuangmeng = 21,
						facebook = 22,
						tencentYYB = 23,
						twIbuka = 24,
						mobile01 = 25,
						longyuanofficial = 26,
						--墨迹、极游、三星、迪信通、N多、优亿、利趣、遇见、核桃、动游、艺果、万能钥匙。
						longyuanMoji = 27,
						longyuanJiyou = 28,
						longyuanSanxing = 29,
						longyuanDixintong = 30,
						longyuanNduo = 31,
						longyuanYouyi = 32,
						longyuanLiqu = 33,
						longyuanYujian = 34,
						longyuanHetao = 35,
						longyuanDongyou = 36,
						longyuanYiguo = 37,
						longyuanWannengyaoshi = 47,
						HYKJ = 38,--华悦科技
                        anzhi = 39,
                        vivo = 40,
                        iosi4 = 41,
                        am = 42, --金立android
                        haima = 43,
                        huawei = 44,
                        jinshan = 45,
                        kuaiyong = 46,
						muwan = 48, --拇指玩
						joloplay = 49, -- HTC
						coolpad = 50,-- 酷派
						offerme = 51, -- 台湾offerme版本
                        tongbu = 52,
						longyuankuaiya = 55,
						longyuan1 =56,
						longyuan2 =57,
						longyuan3 =58,
						longyuancpa1 = 59,
						longyuancpa2 = 60,
						longyuankcgz1 = 61,
						longyuankcgz2 = 62,
						pujia = 63, --扑家
                        longyuanzz = 64, --龙源zz
                    }
                    
CanonOfficialChannel = {
                            he = 11,
							pujia = 63,
                        --    ibuka = 16,
                    }

local platFormId = ThirdPlatformDict.default
local isLongyuanPlatform = false
local isOfficialPlatform = false
if __ANDROID then
    local packageName = CanonEnvInjector:getAndroidPackageName()
    local platformSign = packageName:split(".")
	
	if platformSign[table.getn(platformSign)-1] == "longyuan" and string.find(platformSign[table.getn(platformSign)],"longyuan") ~= nil then
		isLongyuanPlatform = true
	end
	
	if platformSign[table.getn(platformSign)] =="coolpad" then
		--酷派的登陆机制和官包一致
		isLongyuanPlatform = true
	end
	
	if platformSign[table.getn(platformSign)-1] == "official" then
		isOfficialPlatform = true
	end
	
    platformSign = platformSign[table.getn(platformSign)]
        
    he_log_info("+++++++++++++++++++++++++++ThirdPlatform Log:platformSign = "..platformSign.."++++++++++++++++++++++++++++++++")
    platFormId = platformSign--StartupConfig:getInstance():getPlatFormId()
    he_log_info("+++++++++++++++++++++++++++ThirdPlatform Log:platformSign = "..platFormId.."++++++++++++++++++++++++++++++++")
    if ThirdPlatformDict[platFormId] then
        platFormId = ThirdPlatformDict[platFormId]
    else
        platFormId = ThirdPlatformDict.default
    end

    he_log_info("+++++++++++++++++++++++++++ThirdPlatform Log:platformSign = "..platFormId.."++++++++++++++++++++++++++++++++")
elseif __IOS then
    local packageName = PlatformMgr:getInstance():getBundleName()
    local platformSign = packageName:split(".")
    platformSign = platformSign[table.getn(platformSign)]
    if platformSign == "nd91" then
        platFormId = ThirdPlatformDict.ios91
    elseif platformSign == "PP" then
        platFormId = ThirdPlatformDict.iosPP
    elseif platformSign == "i4" then
        platFormId = ThirdPlatformDict.iosi4
    elseif platformSign == "haima" then
        platFormId = ThirdPlatformDict.haima
    elseif platformSign == "kuaiyong" then
        platFormId = ThirdPlatformDict.kuaiyong
    elseif platformSign == "tongbu" then
        platFormId = ThirdPlatformDict.tongbu
    else
        platFormId = ThirdPlatformDict.ios
    end
    he_log_info("+++++++++++++++++++++++++++ThirdPlatform Log:platformSign = "..platFormId.."++++++++++++++++++++++++++++++++")	
end

function isLongyuanPlatformFunc()
	return isLongyuanPlatform
end

function isOfficialPlatformFunc()
	return isOfficialPlatform
end

function isDEV()
    if platFormId == ThirdPlatformDict.default then
        return true
    else
        return false
    end
end

function isUCAndroid()
    if platFormId == ThirdPlatformDict.uc then
        return true
    else
        return false
    end
end

function is91Android()
    if platFormId == ThirdPlatformDict.nd91 then
        return true
    else
        return false
    end
end

function isXiaomiAndroid()
    if platFormId == ThirdPlatformDict.mi then
        return true
    else
        return false
    end
end

function is360Android()
    if platFormId == ThirdPlatformDict.qihoo360 then
        return true
    else
        return false
    end
end

function isDKAndroid()
    if platFormId == ThirdPlatformDict.baiduDK then
        return true
    else
        return false
    end
end

function isWdjAndroid()
    if platFormId == ThirdPlatformDict.wdj then
        return true
    else
        return false
    end
end

function isOppoAndroid() 
    if platFormId == ThirdPlatformDict.gamecenter then
        return true
    else
        return false
    end
end

function isYyhAndroid()
    if platFormId == ThirdPlatformDict.yingyonghui then
        return true
    else
        return false
    end
end

function isYYBAndroid()
    if platFormId == ThirdPlatformDict.tencentYYB then
        return true
    else
        return false
    end
end

function isAnzhiAndroid()
    if platFormId == ThirdPlatformDict.anzhi then
        return true
    else
        return false
    end
end

function isVivoAndroid()
    if platFormId == ThirdPlatformDict.vivo then
        return true
    else
        return false
    end
end

function isI4ios()
    if platFormId == ThirdPlatformDict.iosi4 then
        return true
    else
        return false
    end
end

function isJinliAndroid()
    if platFormId == ThirdPlatformDict.am then
        return true
    else
        return false
    end
end

function isJinshanAndroid()
    if platFormId == ThirdPlatformDict.jinshan then
        return true
    else
        return false
    end
end

function isMuwanAndroid()
    if platFormId == ThirdPlatformDict.muwan then
        return true
    else
        return false
    end
end

function isJoloplayAndroid()
    if platFormId == ThirdPlatformDict.joloplay then
        return true
    else
        return false
    end
end

function isLenovoAndroid()
    if platFormId == ThirdPlatformDict.lenovo then
        return true
    else
        return false
    end
end

function isHuaweiAndroid()
    if platFormId == ThirdPlatformDict.huawei then
        return true
    else
        return false
    end
end

function isHaimaIos()
    if platFormId == ThirdPlatformDict.haima then
        return true
    else
        return false
    end
end

function isKuaiYongIos()
    if platFormId == ThirdPlatformDict.kuaiyong then
        return true
    else
        return false
    end
end

function isTongbuIos()
    if platFormId == ThirdPlatformDict.tongbu then
        return true
    else
        return false
    end
end

function isPlatformIos()
    if platFormId == ThirdPlatformDict.ios then
        return true
    else
        return false
    end
end

function isPlatformAndroid()
    if platFormId == ThirdPlatformDict.he then
        return true
    else
        return false
    end
end 

function isBukaAndroid()
    if platFormId == ThirdPlatformDict.ibuka then
        return true
    else
        return false
    end
end

function isChuangMengAndroid()
    if platFormId == ThirdPlatformDict.chuangmeng then
        return true
    else
        return false
    end
end

function isPujiaAndroid()
    if platFormId == ThirdPlatformDict.pujia then
        return true
    else
        return false
    end
end

function isGooglePlayTW()
    if platFormId == ThirdPlatformDict.googleplay then
        return true 
    else
        return false
    end
end

function isOffermeTW()
    if platFormId == ThirdPlatformDict.offerme then
        return true
    else
        return false
    end
end

function isFunFunTW()
    if platFormId == ThirdPlatformDict.funfun then
        return true
    else
        return false
    end
end

function isPubgameTW()
    if platFormId == ThirdPlatformDict.pubgame then
        return true
    else
        return false
    end
end

function isTWHE()
    if platFormId == ThirdPlatformDict.twhe then
        return true
    else
        return false
    end
end

function isIosTW()
    if platFormId == ThirdPlatformDict.iosTW then
        return true
    else
        return false
    end
end

function getPlatName()
    return StartupConfig:getInstance():getPlatFormId()
end 

function getPlatFormIgnoreDevice()
    local platform = "def"
    if __ANDROID then
        local packageName = CanonEnvInjector:getAndroidPackageName()
        local platformSign = packageName:split(".")
        local signStr = platformSign[table.getn(platformSign)]
		if signStr == "qihoo360" then
			platform = "360"
		elseif signStr == "nd91" then
			platform = "91"
        elseif signStr == "baiduDK" then
            platform = "duoku"
        elseif signStr == "wdj" then
            platform = "wandoujia"
        elseif signStr == "gamecenter" then
            platform = "oppo"
        elseif signStr == "am" then
            platform = "jinli"
	elseif signStr == "muwan" then
    	    platform = "muzhiwan"
        elseif CanonOfficialChannel[signStr] then
            he_log_info("+++++++++++++++++++++++++++ThirdPlatform Log:is offical channel++++++++++++++++++++++++++++++++")
            platform = "he"
		else
			platform = signStr
		end
    elseif __IOS or __MAC then
        local packageName = PlatformMgr:getInstance():getBundleName()
        local platformSign = packageName:split(".")
        local signStr = platformSign[table.getn(platformSign)]
        if signStr == "nd91" then
            platform = "91"
        elseif signStr == "PP" then
            platform = "pp"
        elseif signStr == "i4" then
            platform = "as"
        elseif signStr == "haima" then
            platform = "haima"
        elseif signStr == "kuaiyong" then
            platform = "ky"
		elseif signStr == "tongbu" then
			platform = "tongbu"
        else
            platform = "ios"
        end
    end
    return platform
end

function getPlatFormChannelName()
    local channelName = ""
    if __ANDROID then
        local packageName = CanonEnvInjector:getAndroidPackageName()
        local platformSign = packageName:split(".")
        local signStr = platformSign[table.getn(platformSign)]
		if signStr == "he" then
			channelName = "he"
		--elseif signStr == "ibuka" then
		--	channelName = "buka"
		end
    end
    he_log_info("+++++++++++++++++++++++++++ThirdPlatform Log:channelName = "..channelName.."++++++++++++++++++++++++++++++++")
    return channelName
end

function getPlatFormId()
    return platFormId
end 

function setPlatFormId(pid)
    platFormId = pid
end 

function getAccountId()
    return accountId
end 

function setNewAccountId(newId)
    accountId = newId
    --he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:set newAccountId = "..accountId.."++++++++++++++++++++++++++++++++")
end

function getToken()
    return getToken
end 

local isNewUser = false
function thirdPlatformBindAccount(afterBindAccountFunc)
    he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:begin bindAccount++++++++++++++++++++++++++++++++")
    local function bindAccountFinish(timedata)
        he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:bindAccount succeed++++++++++++++++++++++++++++++++")
        DcManager.sendLoadingActivity(69, ((os.time() - g_startTime )*1000) )
        if afterBindAccountFunc and type(afterBindAccountFunc) == "function" then
            afterBindAccountFunc()
        end
    end
    
    local function onBindAccountFailed(error)
      local errorCode = tonumber(error.data)
      he_log_error("+++++++++++++++++++++++++++ThirdPlatform Login Log:bindAccount  failed: " .. errorCode .. "++++++++++++++++++++++++++++++++")
      CanonMessageBox:showCommUnHandleErrorBox(errorCode)
      logoutAccount()
    end
    
    --he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:accountId = "..getAccountId().."++++++++++++++++++++++++++++++++")
    if isNewUser then
        he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:begin bindAccount new user++++++++++++++++++++++++++++++++")
        --LoginScene:getInstance():setIsNewbie(true)
        
        local params = {platformId = getPlatFormId(),platformUid = getPlatformUid(),sid = getPlatformSid()}
        local request = BindAccountRequest.new( params, rpc.SendingPriority.kHigh )
        request:addEventListener( RequestNotifyEnum.BindAccountSucceed, bindAccountFinish )
        request:addEventListener( RequestNotifyEnum.BindAccountFailed, onBindAccountFailed )
        request:start()
    else
        he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:old user++++++++++++++++++++++++++++++++")
        --LoginScene:getInstance():setIsNewbie(false)
        DcManager.sendLoadingActivity(69, ((os.time() - g_startTime )*1000) )
        if afterBindAccountFunc and type(afterBindAccountFunc) == "function" then
            afterBindAccountFunc()
        end
    end
end 

function setIsNewUser(newUser )
    isNewUser = newUser
end

function getPlatformUid()
    local platformUid = -999 
    if isUCAndroid() then
        platformUid = getUCID()
    elseif is91Android() then
        platformUid = get91LoginUin()
    elseif isXiaomiAndroid() then
        platformUid = getXiaomiLoginUid()
    elseif is360Android() then
        platformUid = get360LoginUid ()
    elseif isDKAndroid() then
        platformUid = getDKUid()
    elseif isWdjAndroid() then
        platformUid = getWdjUid()
    elseif isOppoAndroid() then
        platformUid = getOppoUid()
    elseif isYyhAndroid() then
        platformUid = getYYHUid()
    elseif isAnzhiAndroid() then
        platformUid = getAnzhiUid()
    elseif isVivoAndroid() then
        platformUid = getVivoUid()
    elseif isOfficalAccountPlatform() then
        platformUid = getAccountUid()
    elseif isYYBAndroid() then
        platformUid = getQQopenid()
    elseif isI4ios() then
        platformUid = getIos_i4Uid()
    elseif isJinliAndroid() then
        platformUid = getJinliUid()
    elseif isHaimaIos() then
        platformUid = getIos_haimaUid()
    elseif isKuaiYongIos() then
        platformUid = getIos_kuaiyongUid()
    elseif isTongbuIos() then
        platformUid = getIos_tongbuUid()
    elseif isHuaweiAndroid() then
        platformUid = getHuaweiUid()
    elseif isJinshanAndroid() then
        platformUid = getJinshanUid()
    elseif isMuwanAndroid() then
        platformUid = getMuwanUid()
    elseif isJoloplayAndroid() then
        platformUid = getJoloplayUid()
	elseif isLenovoAndroid() then
        platformUid = getLenovoUid()
    end
    return tostring(platformUid)
end

function getPlatformSid()
    local sid = -999
    if isUCAndroid() then
        sid = getUCSid()
    elseif is91Android() then
        sid = get91Sid()
    elseif isXiaomiAndroid() then
        sid = getXiaomiSid()
    elseif is360Android() then
        sid = get360Sid()
    elseif isDKAndroid() then
        sid = getDKSid()
    elseif isWdjAndroid() then
        sid = getWdjSid()
    elseif isOppoAndroid() then
        sid = getOppoSid()
    elseif isYyhAndroid() then
        sid = getYYHSid()
    elseif isAnzhiAndroid() then
        sid = getAnzhiSid()
    elseif isVivoAndroid() then
        sid = getVivoSid()
    elseif isOfficalAccountPlatform() then
        sid = getAccountSid()
    elseif isYYBAndroid() then
        sid = getQQSid()
    elseif isI4ios()then
        sid = getIos_i4Sid()
    elseif isJinliAndroid() then
        sid = getJinliSid()
    elseif isHaimaIos() then
        sid = getIos_haimaSid()
    elseif isKuaiYongIos() then
        sid = getIos_kuaiyongSid()
    elseif isTongbuIos() then
        sid = getIos_tongbuSid()
    elseif isHuaweiAndroid() then
        sid = getHuaweiSid()
    elseif isJinshanAndroid() then
        sid = getJinshanSid()
    elseif isMuwanAndroid() then
        sid = getMuwanSid()
    elseif isJoloplayAndroid() then
        sid = getJoloplaySid()
	elseif isLenovoAndroid() then
		sid = getLenovoSid()
    end
    return sid
end

function requestGetBoundMapping()
    he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:GetBoundMapping begin++++++++++++++++++++++++++++++++")
    DcManager.sendLoadingActivity(65, ((os.time() - g_startTime )*1000) )
    local platformId = getPlatFormId()
    
    local platformUid = -999
    local sid = -999
    sid = getPlatformSid()
    platformUid = getPlatformUid()
    
    local request = HttpRequest:createPost(DataManager.SystemConfig.GetBoundMappingUrl)
                         
    local timeout = 10
    
    if isPlatformIos() or isPlatformAndroid() or isBukaAndroid() or isGooglePlayTW() or isIosTW() or isTWHE() or isChuangMengAndroid() or isPujiaAndroid() or isLongyuanPlatformFunc() or isOfficialPlatformFunc() then
        platformUid = url_encode(platformUid)
        sid = url_encode(sid)
    end

    request:setConnectionTimeoutMs(timeout * 1000)
                            
    request:setTimeoutMs(timeout * 1000)
                            
    request:addHeader("Content-Type:application/x-www-form-urlencoded")
    
    --he_log_info("current sid is: "..sid.." uid is:"..platformUid)
    local dataString = "platformId=" .. platformId .. "&platformUid=" .. platformUid .."&sid=".. sid
    --he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:platformId=" .. platformId .. "&platformUid=" .. platformUid .."&sid=".. sid.."++++++++++++++++++++++++++++++++")
    local dataStringLen = dataString:len()
    request:setPostData(dataString, dataStringLen)
    
    local function onGetBoundMappingFinish(response)
        --he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:GetBoundMapping finish response.body = "..response.body.."++++++++++++++++++++++++++++++++")
        RequestLoadingBox:removeLoadingBox()
		--添加转换打点，监控后端传入数据
		--begin
		local responseData = {
						response = table.serialize(response)
						}
				DcManager.sendLoadingActivity(100, ((os.time() - g_startTime )*1000) ,responseData)
		--end
		local function netErr()
			CanonMessageBox.showText(
                ShowButtonType.ID_OK,
                getTextByKey("popup_networkError"),
                nil,
                {
                    text = getTextByKey("retry"),
                    callbackFunc = function()
                        requestGetBoundMapping()
                    end
                }
            )
		end
		if response.httpCode ~= 200 then
			netErr()
			return
		end
        local rTable = table.deserialize(response.body)
        if rTable.code ~= 1 then
            --he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:GetBoundMapping err:"..response.httpCode.."++++++++++++++++++++++++++++++++")
            --if rTable.code then
            --     he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:GetBoundMapping err:"..rTable.code.."++++++++++++++++++++++++++++++++")
            --end
			--RequestLoadingBox:removeLoadingBox()
            netErr()
            return
        end
        --local fields = response.body:split(",")
        accountId = rTable.accountId--tonumber(fields[1])
        getToken = rTable.token--fields[2]
        if tonumber(accountId) == -1 then
            isNewUser = true
        else
            isNewUser = false
        end 
        --he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:GetBoundMapping success:(accountId="..accountId..",getToken="..getToken..")++++++++++++++++++++++++++++++++")
        he_log_info("+++++++++++++++++++++++++++ThirdPlatform Login Log:begin initSession++++++++++++++++++++++++++++++++")
        DcManager.sendLoadingActivity(67, ((os.time() - g_startTime )*1000) )
        Communication:getInstance():init()
        
        Communication:getInstance():initSession(accountId,getToken)
        
        
    end 
    DcManager.sendLoadingActivity(66, ((os.time() - g_startTime )*1000) )
	RequestLoadingBox:createLoadingBox(false)
	RequestLoadingBox:showLoadingBox()
    HttpClient:getInstance():sendRequest(onGetBoundMappingFinish, request)
end

function getCurPlatFormId()
	return platFormId
end