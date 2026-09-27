-------------------------------
-------platFormId define-------
-------------------------------
--0: undefined windows
--1: UC android
-------------------------------
local ThirdPlatformDict = {
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
                        anzhi =39,
                        vivo = 40,
                        iosi4 = 41,
                        am = 42, --金立android
                        haima =43,
                        huawei = 44,
                        jinshan = 45,
                        kuaiyong = 46,
						muwan = 48, --拇指玩
						joloplay = 49, -- HTC
						coolpad = 50,-- 酷派
						offerme = 51, -- 台湾offerme版本
						tongbu = 52,
						funfun = 53, -- 台湾趣玩
						pubgame = 54, --台湾游戏酒吧
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

setPlatFormId(platFormId)

function isOfficialPlatformFunc()
	return isOfficialPlatform
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

function isTWHE()
    if platFormId == ThirdPlatformDict.twhe then
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

function isI4ios()
    if platFormId == ThirdPlatformDict.iosi4 then
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
