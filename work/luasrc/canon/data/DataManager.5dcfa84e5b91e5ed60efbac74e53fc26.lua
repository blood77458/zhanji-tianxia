-- modified by zheng.che @ 2014-12-21 增加战斗力属性存储

local domainUrl = StartupConfig:getInstance():getGameDomain()
if(not domainUrl) then
  domainUrl = "http://android.canon.happyelements.cn"
end
local isLocal = string.find(domainUrl, "10.130.142.72") or string.find(domainUrl, "10.130.130.27") or false
if isDEV() then
	isLocal = true
else
	isLocal = false
end
local server_Id = 1
local zone_Id = 0

DataManager = {}

DataManager = {
  SystemConfig = {
    GameOfficialName = "Canon",
    GameVersion = "0.1",
    CheckQQidUrl = domainUrl .. "/check/tencentYYB?",
    SessionKeyUrl = domainUrl .. "/sessionKey/init",
    ProtocolUrl = domainUrl .. "/protocol",
    CheckUCidUrl = domainUrl .. "/check/ucid",
    Check91idUrl = domainUrl .. "/check/nd91?",
    CheckXiaomiIdUrl = domainUrl .. "/check/xiaomi?",
    Check360IdUrl = domainUrl .. "/check/360?",
    CheckIosIdUrl = domainUrl .. "/check/ios?",
    CheckDKIdUrl = domainUrl .. "/check/duoku?",
    CheckWdjIdUrl = domainUrl .. "/check/wandoujia",
    CheckOppoIdUrl = domainUrl .."/check/oppo",
    CheckYYHIdUrl = domainUrl .. "/check/yyh?",
    CheckAnzhiIdUrl = domainUrl .. "/check/anzhi?",
    CheckIosI4idUrl = domainUrl .. "/check/iosi4?",
    CheckIosHaimaidUrl = domainUrl .. "/check/haima?",
    CheckIosTongbuidUrl = domainUrl .. "/check/tongbu?",
    CheckIosKuaiYongUrl = domainUrl .. "/check/ky?",
    CheckPlatformIdUrl = domainUrl .. "/check/"..getPlatFormIgnoreDevice().."?",
	CheckMuzhiwanIdUrl =  domainUrl .. "/check/muwan?",
	CheckLenovoIdUrl =  domainUrl .. "/check/lenovo?",
    CheckAndroidIdUrl = domainUrl .. "/check/android?",
    CheckTWIosIdUrl = domainUrl .. "/check/iosTw?",
    CheckBuKaIdUrl = domainUrl .. "/check/ibuka?",
	CheckChuangMengIdUrl = domainUrl .. "/check/chuangmeng?",
	CheckPujiaIdUrl = domainUrl .. "/check/pujia?",
    CheckGooglePlayTWIdUrl = domainUrl .. "/check/googleplay?",
    CheckOfficialIdUrl = domainUrl .. "/check/"..getPlatFormIgnoreDevice().."?",
    CheckLongyuanIdUrl = domainUrl .. "/check/"..getPlatFormIgnoreDevice().."?",
	CheckTWHEIdUrl = domainUrl .. "/check/twhe?",
	CheckTWBuKaIdUrl = domainUrl .. "/check/twIbuka?",
	CheckMobile01IdUrl = domainUrl .. "/check/mobile01?",
    CheckFacebookIdUrl = domainUrl .. "/check/facebook",
    CheckOffermeTWIdUrl = domainUrl .. "/check/offerme?",
	CheckPlatformIdUrl = domainUrl .. "/check/"..getPlatFormIgnoreDevice().."?",
    ChangeAccountUrl = domainUrl .. "/account?accountId=",
    GetBoundMappingUrl = domainUrl .. "/mappingAccount",
    RegisterAccountUrl = domainUrl .. "/loginAccount/register",
    LoginAccountUrl = domainUrl .. "/loginAccount/login",
    RebindAccountUrl = domainUrl .. "/loginAccount/rebind",
    ModifyPasswordUrl = domainUrl .. "/loginAccount/modifyPassword",
    CheckDeviceAccountUrl = domainUrl .. "/loginAccount/hasVisitorAccount",
    BindFacebookAccountUrl = domainUrl .. "/loginAccount/bindFacebook",
    ResetPasswordUrl = domainUrl .. "/loginAccount/resetPassword",
    GetLoginedServer = domainUrl .. "/getLoginServer?",
    ChangeAccountVisible = isLocal,
  },
  GameInitData = {}, --存放gameInit请求的原始返回值 TODO dreprect，应统一使用DataManager.getGameInitData()函数
  GameMetaData = {}, --存放getMeta请求的原始返回值 TODO dreprect，应统一使用MetaManager.game_meta
 getGameInitData = function() return table.clone(DataManager.GameInitData, true) end, --table.deserialize(HeMemDataHolder:getString("GameInit")) end,
  setGameInitData = function( data ) DataManager.GameInitData = data end,-- HeMemDataHolder:setString("GameInit", table.serialize(data)) end,
  
  getCurrUser = function() local gameInitData = DataManager.getGameInitData(); return (gameInitData and gameInitData.sharkUser) or nil end,
  setCurrUser = function( data ) local gameInitData = DataManager.getGameInitData(); gameInitData.sharkUser = data; DataManager.setGameInitData(gameInitData) end,

  getExchangeGiftBagInfo = function()
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkUserExtend and gameInitData.sharkUserExtend.exchangeGiftBagInfo then
      return gameInitData.sharkUserExtend.exchangeGiftBagInfo
    else
      return nil
    end
  end,

  setExchangeGiftBagInfo = function(data)
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkUserExtend then
      gameInitData.sharkUserExtend.exchangeGiftBagInfo = data
      DataManager.setGameInitData(gameInitData)
    end
  end,
  
  getCountdownRewardInfo = function()
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkUserExtend and gameInitData.sharkUserExtend.countdownRewardInfo then
      return gameInitData.sharkUserExtend.countdownRewardInfo
    else
      return nil
    end
  end,
  
  setCountdownRewardInfo = function(data)
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkUserExtend then
      gameInitData.sharkUserExtend.countdownRewardInfo = data
      DataManager.setGameInitData(gameInitData)
    end
  end,

  --get user signin days
  getCurMonthUserSigninDays = function()
		local gameInitData = DataManager.getGameInitData()
		if gameInitData.sharkUserExtend ~= nil 
			and gameInitData.sharkUserExtend.signInInfo ~= nil 
			and gameInitData.sharkUserExtend.signInInfo.loginDaysMonth then
				--
				local lastSignTime = os.date("*t",gameInitData.sharkUserExtend.signInInfo.getRewardTimeStamp)
				local curTime = os.date("*t",g_curServerTimeStamp)
				if lastSignTime.year == curTime.year and  lastSignTime.month == curTime.month then
				    return gameInitData.sharkUserExtend.signInInfo.loginDaysMonth
				else
				    return 0
				end
		else
			return 0
		end 
  end,
  --get user last signin time
  getUserLastSigninTime = function()
		local gameInitData = DataManager.getGameInitData()
		if gameInitData.sharkUserExtend ~= nil 
			and gameInitData.sharkUserExtend.signInInfo ~= nil 
			and gameInitData.sharkUserExtend.signInInfo.getRewardTimeStamp then
				return gameInitData.sharkUserExtend.signInInfo.getRewardTimeStamp
		else
			return 0
		end 
  end,
  getEquipsData = function()
		local gameInitData = DataManager.getGameInitData()
		return gameInitData.sharkEquips and gameInitData.sharkEquips.sharkEquips or {}
	end,
  setEquipsData = function( data )
		local gameInitData = DataManager.getGameInitData()
		gameInitData.sharkEquips.sharkEquips = data
		DataManager.setGameInitData(gameInitData)
	end,

  getSpiritsData = function()
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkSpirits == nil then
      gameInitData.sharkSpirits = {sharkSpirits = {}}
      DataManager.setGameInitData(gameInitData)
    end
    return gameInitData.sharkSpirits and gameInitData.sharkSpirits.sharkSpirits or {}
  end,
  setSpiritsData = function( data )
    local gameInitData = DataManager.getGameInitData()
    gameInitData.sharkSpirits.sharkSpirits = data
    DataManager.setGameInitData(gameInitData)
  end,

  getTreasureFragmentNum = function()
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkUserExtendMore ~= nil 
      and gameInitData.sharkUserExtendMore.treasureInfo ~= nil 
      and gameInitData.sharkUserExtendMore.treasureInfo.treasureFragmentNum then
        return gameInitData.sharkUserExtendMore.treasureInfo.treasureFragmentNum
    else

      return 0
    end 
    
  end,
  setTreasureFragmentNum  = function( data )
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkUserExtendMore == nil then
       gameInitData.sharkUserExtendMore = {}
    end
    if gameInitData.sharkUserExtendMore.treasureInfo == nil then
       gameInitData.sharkUserExtendMore.treasureInfo = {treasureFragmentNum = 0}
    end
    gameInitData.sharkUserExtendMore.treasureInfo.treasureFragmentNum = data
    DataManager.setGameInitData(gameInitData)
  end,
  getDoubleChargeInfo = function()
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkUserExtendMore ~= nil 
      and gameInitData.sharkUserExtendMore.doubleChargeInfo ~= nil then
        return gameInitData.sharkUserExtendMore.doubleChargeInfo
    else

      return {doubleCharge = false,version = 0}
    end 
    
  end,
  setDoubleChargeInfo  = function( data )
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkUserExtendMore == nil then
       gameInitData.sharkUserExtendMore = {}
    end
    if gameInitData.sharkUserExtendMore.doubleChargeInfo == nil then
       gameInitData.sharkUserExtendMore.doubleChargeInfo = {doubleCharge = false,version = 0}
    end
    gameInitData.sharkUserExtendMore.doubleChargeInfo = data
    DataManager.setGameInitData(gameInitData)
  end,

  getMedalNum = function()
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkUserExtendMore ~= nil 
      and gameInitData.sharkUserExtendMore.medalNum ~= nil then
        return gameInitData.sharkUserExtendMore.medalNum
    else
      return 0
    end 
  end,

  setMedalNum = function( data )
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkUserExtendMore == nil then
       gameInitData.sharkUserExtendMore = {}
    end
    gameInitData.sharkUserExtendMore.medalNum = data
    DataManager.setGameInitData(gameInitData)
  end,


  getTreasuresData = function()
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkTreasures == nil then
      gameInitData.sharkTreasures = {sharkTreasures = {}}
      DataManager.setGameInitData(gameInitData)
    end
    return gameInitData.sharkTreasures and gameInitData.sharkTreasures.sharkTreasures or {}
  end,
  setTreasuresData = function( data )
    local gameInitData = DataManager.getGameInitData()
    gameInitData.sharkTreasures.sharkTreasures = data
    DataManager.setGameInitData(gameInitData)
  end,

  getSharkMysteriousCoinsData = function()
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkMysteriousCoins == nil then
      gameInitData.sharkMysteriousCoins = {sharkMysteriousCoins = {}}
      DataManager.setGameInitData(gameInitData)
    end
    return gameInitData.sharkMysteriousCoins and gameInitData.sharkMysteriousCoins.sharkMysteriousCoins or {}
  end,
  setSharkMysteriousCoinsData = function( data )
    local gameInitData = DataManager.getGameInitData()
    gameInitData.sharkMysteriousCoins.sharkMysteriousCoins = data
    DataManager.setGameInitData(gameInitData)
  end,
  
  --获取活动信息
  getSharkActivity = function()
    local gameInitData = DataManager.getGameInitData()
    return gameInitData.sharkActivity or {}
  end,
  
  setSharkActivity = function(data)
    local gameInitData = DataManager.getGameInitData()
    gameInitData.sharkActivity = data
    DataManager.setGameInitData(gameInitData)
  end,
  
  getPropsData = function()
		local gameInitData = DataManager.getGameInitData()
		return gameInitData.sharkProps and gameInitData.sharkProps.sharkProps or {}
	end,
  setPropsData = function( data )
		local gameInitData = DataManager.getGameInitData()
		gameInitData.sharkProps.sharkProps = data
		DataManager.setGameInitData(gameInitData)
	end,
  
  getCardsData = function()
		return DataManager.getGameInitData().sharkCards.sharkCards
	end,

  -- 通过卡牌id获得卡的数据
  getCardById = function(cardId)
    local cardData = DataManager.getCardsData()
    for _, temp in ipairs(cardData) do
      if cardId == temp.cardId then
          return temp
      end
    end
    return nil
  end,

  setCardsData = function( data )
		local gameInitData = DataManager.getGameInitData()
		gameInitData.sharkCards.sharkCards = data
		DataManager.setGameInitData(gameInitData)
	end,
  
  --获取与包装卡牌碎片信息
  getCardFragmentsData = function()
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkCardFragments and gameInitData.sharkCardFragments.sharkCardFragments then
      return gameInitData.sharkCardFragments.sharkCardFragments
    end
		return {}
	end,
  setCardFragmentsData = function( data )
		local gameInitData = DataManager.getGameInitData()
    if not gameInitData.sharkCardFragments then
      gameInitData.sharkCardFragments = {}
    end
		gameInitData.sharkCardFragments.sharkCardFragments = data
		DataManager.setGameInitData(gameInitData)
	end,
  
  --获取与包装装备碎片信息
  getEquipFragmentsData = function()
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkEquipFragments and gameInitData.sharkEquipFragments.sharkEquipFragments then
      return gameInitData.sharkEquipFragments.sharkEquipFragments
    end
		return {}
	end,
  setEquipFragmentsData = function( data )
		local gameInitData = DataManager.getGameInitData()
    if not gameInitData.sharkEquipFragments then
      gameInitData.sharkEquipFragments = {}
    end
		gameInitData.sharkEquipFragments.sharkEquipFragments = data
		DataManager.setGameInitData(gameInitData)
	end,
	
  getPlayerTeamInfo = function()
		return HeMemDataHolder:getString("playerTeamInfo")
	end,
  setPlayerTeamInfo = function( data )
		HeMemDataHolder:setString("playerTeamInfo", data)
	end,
  
  clearData = function() 
    --GameInit
    HeMemDataHolder:deleteByKey("GameInit")
    --playerTeamInfo
    HeMemDataHolder:deleteByKey("playerTeamInfo")
    
    -- battle map will update while gameInit recall
    
    g_cardInfoCache = {}
    g_cardCountryNumCache = {}
		g_previousSkillTable = nil;
		g_shouldCalc = true
		g_previousBonusTable = nil;

  end,
	
	--get lifeLimitGoods Data
	getLifeLimitGoodsData = function()
		local gameInitData = DataManager.getGameInitData()
		return gameInitData.sharkUserExtend and gameInitData.sharkUserExtend.lifeLimitGoods or {}
	end,
  setLifeLimitGoodsData = function( data )
		local gameInitData = DataManager.getGameInitData()
		gameInitData.sharkUserExtend.lifeLimitGoods = data
		DataManager.setGameInitData(gameInitData)
	end,
	
	--get sharkbeasts
	getSharkBeastsData = function()
		local gameInitData = DataManager.getGameInitData()
		return gameInitData.sharkBeasts or {}
	end,
  setSharkBeastsData = function( data )
		local gameInitData = DataManager.getGameInitData()
		gameInitData.sharkBeasts = data
		DataManager.setGameInitData(gameInitData)
	end,
  
	getGainedChargeMoneyRewardlist = function()
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkUserExtend and gameInitData.sharkUserExtend.gainedChargeMoneyRewardList then
      return gameInitData.sharkUserExtend.gainedChargeMoneyRewardList
    else
      return nil
    end
  end,

  setGainedChargeMoneyRewardlist = function(data)
    local gameInitData = DataManager.getGameInitData()
    if gameInitData.sharkUserExtend then
      gameInitData.sharkUserExtend.gainedChargeMoneyRewardList = data
      DataManager.setGameInitData(gameInitData)
    end
  end,
  
	getServerid = function ()
		return server_Id
	end,

	getZoneId = function ()
		return zone_Id
	end,

	setServerId = function (serverId)
		server_Id = serverId
	end,

	setZoneId = function (zoneId)
		zone_Id = zoneId
	end,
	
	--get sharkMatrices
	getSharkMatricesData = function()
		local gameInitData = DataManager.getGameInitData()
		return gameInitData.sharkMatrices and gameInitData.sharkMatrices.sharkMatrices or {}
	end,
  setSharkMatricesData = function( data )
		local gameInitData = DataManager.getGameInitData()
		if not gameInitData.sharkMatrices then
			gameInitData.sharkMatrices = {}
		end
		gameInitData.sharkMatrices.sharkMatrices = data
		DataManager.setGameInitData(gameInitData)
	end,
	
	getSharkSkyTowerData = function()
		local gameInitData = DataManager.getGameInitData()
		return gameInitData.sharkSkyTower or {}
	end,
  setSharkSkyTowerData = function( data )
		local gameInitData = DataManager.getGameInitData()
		gameInitData.sharkSkyTower = data
		DataManager.setGameInitData(gameInitData)
	end,
  
  -- 跳过状态下，返回下一个需要加强属性的窗口
  getSharkSkyTowerNeedAddFloor = function()
    local sharkSkyTowerData = DataManager.getSharkSkyTowerData()
    local BeginfloorNum = sharkSkyTowerData.currStatus.beginSkipFloor
    
    -- 检测起点
    if sharkSkyTowerData.currStatus then
      if type(sharkSkyTowerData.currStatus.gainFloorBuff) == "table" then
        for k, data in pairs(sharkSkyTowerData.currStatus.gainFloorBuff) do
          if data > BeginfloorNum then
            BeginfloorNum = data
          end
        end
      end
    end

    -- 最大可跳过层
    local TargetFloorNum = sharkSkyTowerData.sharkSkyTower.maxBigWinFloor
    local maxFloor = table.getn(MetaManager.sky_tower_level)
    if TargetFloorNum >= maxFloor then
        TargetFloorNum = maxFloor - 1
    end

    for i = BeginfloorNum , TargetFloorNum do
      if MetaManager.sky_tower_level[i + 1].haveBuff == 1 then
        return i
      end
    end

    return 0
  end,

  getSharkDiceData = function()
    local gameInitData = DataManager.getGameInitData()
		if not gameInitData.sharkDice then
      local temp = {}
      temp.throwDiceCount = 0
      temp.changeDiceLuckCount = 0
      temp.changeLuckCountPerThrow = 0
      temp.gainedReward = true
      temp.diceStates = {0,0,0,0,0,0}
      temp.coins = 0
      gameInitData.sharkDice = temp
      DataManager.setGameInitData(gameInitData)
    end
    return gameInitData.sharkDice
  end,
  resetSharkDiceDataForSwitchDay = function()
    local sharkDice = DataManager.getSharkDiceData()
    sharkDice.throwDiceCount = 0
    sharkDice.changeDiceLuckCount = 0
    sharkDice.changeLuckCountPerThrow = 0
    DataManager.setSharkDiceData(sharkDice)
    DataManager.resetDataTimestamp()
  end,
  setSharkDiceData = function(data)
    local gameInitData = DataManager.getGameInitData()
    gameInitData.sharkDice = data
    DataManager.setGameInitData(gameInitData)
  end,
  getDataTimestamp = function()
    local gameInitData = DataManager.getGameInitData()
		return gameInitData.timestamp
  end,
  resetDataTimestamp = function()
    local gameInitData = DataManager.getGameInitData()
    gameInitData.timestamp = TimeUtil.getYmd()
    DataManager.setGameInitData(gameInitData)
  end,
  
  achievements = {},
  setSharkAchievements = function(data)
    DataManager.achievements = data
  end,
  getSharkAchievements = function()
    return DataManager.achievements or {}
  end,
  CardBookachievements = {},
  setSharkCardBookAchievements = function(data)
    DataManager.CardBookachievements = data
  end,
  getSharkCardBookAchievements = function()
    return DataManager.CardBookachievements or {}
  end,
  
  getSharkCrossPkUser = function()
		local gameInitData = DataManager.getGameInitData()
    if not gameInitData.sharkCrossPkUser then
      gameInitData.sharkCrossPkUser = {}
      gameInitData.sharkCrossPkUser.crossVersion = 1
      gameInitData.sharkCrossPkUser.guessUid = 0
      gameInitData.sharkCrossPkUser.gainGuessReward = false
      gameInitData.sharkCrossPkUser.gainRankReward = false
      gameInitData.sharkCrossPkUser.gainServerReward = false
      DataManager.setGameInitData(gameInitData)
    end
		return gameInitData.sharkCrossPkUser or {}
	end,
  resetSharkCrossPkUser = function(aVersion)
    local gameInitData = DataManager.getGameInitData()
    if not gameInitData.sharkCrossPkUser then
      gameInitData.sharkCrossPkUser = {}
    end
    if gameInitData.sharkCrossPkUser.crossVersion ~= aVersion then
      gameInitData.sharkCrossPkUser.crossVersion = aVersion
      gameInitData.sharkCrossPkUser.guessUid = 0
      gameInitData.sharkCrossPkUser.gainGuessReward = false
      gameInitData.sharkCrossPkUser.gainRankReward = false
      gameInitData.sharkCrossPkUser.gainServerReward = false
      DataManager.setGameInitData(gameInitData)
    end
  end,
  setSharkCrossPkUser = function(data)
    local gameInitData = DataManager.getGameInitData()
		gameInitData.sharkCrossPkUser = data
		DataManager.setGameInitData(gameInitData)
  end,
  getSharkChristInfo = function()
    local gameInitData = DataManager.getGameInitData()
    if not gameInitData.sharkChristInfo then
      gameInitData.sharkChristInfo = {}
      gameInitData.sharkChristInfo.maxFinishedChristId = 0
      gameInitData.sharkChristInfo.listSharkChristInfo = {}
    end

    DataManager.setGameInitData(gameInitData)
    return gameInitData.sharkChristInfo or {}
  end,

  setSharkChristInfo = function(data)
    local gameInitData = DataManager.getGameInitData()
    gameInitData.sharkChristInfo = data
    DataManager.setGameInitData(gameInitData)
  end,
  
}

local function refreshSystemConfig()
  DataManager.SystemConfig = {
    GameOfficialName = "Canon",
    GameVersion = "0.1",
    SessionKeyUrl = domainUrl .. "/sessionKey/init",
    ProtocolUrl = domainUrl .. "/protocol",
    CheckUCidUrl = domainUrl .. "/check/ucid",
    Check91idUrl = domainUrl .. "/check/nd91?",
    CheckXiaomiIdUrl = domainUrl .. "/check/xiaomi?",
    Check360IdUrl = domainUrl .. "/check/360?",
    CheckIosIdUrl = domainUrl .. "/check/ios?",
    CheckDKIdUrl = domainUrl .. "/check/duoku?",
    CheckWdjIdUrl = domainUrl .. "/check/wandoujia",
    CheckOppoIdUrl = domainUrl .."/check/oppo",
    CheckYYHIdUrl = domainUrl .. "/check/yyh?",
    CheckAndroidIdUrl = domainUrl .. "/check/android?",
    CheckTWIosIdUrl = domainUrl .. "/check/iosTw?",
    CheckBuKaIdUrl = domainUrl .. "/check/ibuka?",
	CheckChuangMengIdUrl = domainUrl .. "/check/chuangmeng?",
	CheckPujiaIdUrl = domainUrl .. "/check/pujia?",
    CheckGooglePlayTWIdUrl = domainUrl .. "/check/googleplay?",
    CheckOfficialIdUrl = domainUrl .. "/check/"..getPlatFormIgnoreDevice().."?",
    CheckLongyuanIdUrl = domainUrl .. "/check/"..getPlatFormIgnoreDevice().."?",
	CheckPlatformIdUrl = domainUrl .. "/check/"..getPlatFormIgnoreDevice().."?",
    CheckTWHEIdUrl = domainUrl .. "/check/twhe?",
    ChangeAccountUrl = domainUrl .. "/account?accountId=",
    GetBoundMappingUrl = domainUrl .. "/mappingAccount",
    RegisterAccountUrl = domainUrl .. "/loginAccount/register",
    LoginAccountUrl = domainUrl .. "/loginAccount/login",
    RebindAccountUrl = domainUrl .. "/loginAccount/rebind",
    ModifyPasswordUrl = domainUrl .. "/loginAccount/modifyPassword",
    CheckDeviceAccountUrl = domainUrl .. "/loginAccount/hasVisitorAccount",
	ResetPasswordUrl = domainUrl .. "/loginAccount/resetPassword",
    ChangeAccountVisible = isLocal,
  }
end

--change game domain to the url in systemInfo
function DataManager.setGameDomain(url)
  domainUrl = url
  refreshSystemConfig()
end

local gameServerInfo = {}
function DataManager.recordGameServerInfo(serverInfo)
	gameServerInfo = serverInfo
end

function DataManager.getCurGameServerName()
	local serverId = DataManager.getServerid()
	local serverName = "serverError"
	for k,v in pairs(gameServerInfo) do 
		if v.serverInfo.serverId == serverId then
			serverName = v.serverInfo.serverName
			break
		end
	end
	return serverName
end

--当前真实玩家总战斗力 (用作缓存 前端通过接口控制何时切换到显示中)
local _realFightCapacity = nil
--当前显示的总战斗力
local _showFightCapacity = nil

function DataManager.startup()
  _realFightCapacity = nil
  _showFightCapacity = nil
end

function DataManager.clear()
  _realFightCapacity = nil
  _showFightCapacity = nil
end

--------------------------------------------
-- 战斗力相关接口
--------------------------------------------

function DataManager.getRealFightCapacity()
  if _realFightCapacity == nil then
    _realFightCapacity = 0
  end
  return _realFightCapacity
end

function DataManager.setRealFightCapacity(v)
  _realFightCapacity = v
end

function DataManager.getShowFightCapacity()
  if _showFightCapacity == nil then
    --print("DataManager.getGameInitData().sharkUserExtend = " .. tostringRich(DataManager.getGameInitData().sharkUserExtend))
    _showFightCapacity = DataManager.getGameInitData().sharkUserExtend.fightCapacity
    _realFightCapacity = _showFightCapacity
  end
  return _showFightCapacity
end

function DataManager.fightCapacityIsChanged()
  return (_realFightCapacity ~= _showFightCapacity)
end

--刷新战力显示 需要显示上有变更时都要调用此函数
local scheduler = nil
function DataManager.fightCapacityMaybeUpdated()
  --延迟调用
  local function delayDo()
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(scheduler)
    scheduler = nil

    if not DataManager.fightCapacityIsChanged() then
      return
    end

    scene = Director:mgr():run()

    --触发更新动画(先做)
    AttributeChangePanel:show(DataManager.getShowFightCapacity(), DataManager.getRealFightCapacity(), scene)
    --更新显示数值(后做)
    _showFightCapacity = _realFightCapacity
    --通知更新显示
    BaseUINotify:dispatchEvent(Event.new(ConstManager.FIGHT_CAPACITY_SHOW_UPDATE, _showFightCapacity))
  end

  --
  if not scheduler then--防止连续多次触发
    scheduler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(delayDo, 0.1, false)
  end
end
