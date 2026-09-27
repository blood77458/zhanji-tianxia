require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.customUI/CanonCard"
require "canon.models.PackageModel"
require "canon.scene.BaseUIScene"
require "canon.scene.PropConfig"
require "canon.models.VipPrivilegeManager"
require "canon.panel.VipTreasureBoxPanel"
require "canon.panel.VipChargeSuccessPanel"
require "canon.panel.VipPrivilegePanel"
require "canon.request.BuyGoodsRequest"
require "canon.panel.ChargeRewardWarningPanel"
require "canon.manager.ShortPayManager"
-- require "canon.layer.Activity_rechargeLayer"

TABLEVIEW_TAB_INDEX = table.const{
	GOLD_SHOP = 1,
	VIP_SHOP = 2,
	CHARGE = 3,
    SHORT_CHARGE = 4,
	TOTAL_TAB_AMOUNT = 5,
}
local function getStartTime(FeatureName)
	local startAndEndTime = MaintenanceManager:getStartAndEndTime(FeatureName)
	return startAndEndTime[1].activityBeginTimeStamp
end

local function isFirstCharge()
	return (tonumber(DataManager.getCurrUser().rechargeGems) <= 0)
end

local function SetChargeDoubleVersion()--设置value
  local gameSettingConfig = MetaManager.getGameSettingConfig()
   local doubleChargeTimeBeforeFeatureName = gameSettingConfig.doubleChargeTimeBeforeName
   local doubleChargeTimeCurrFeatureName = gameSettingConfig.doubleChargeTimeCurrName
   local DoubleChargeInfo  = DataManager.getDoubleChargeInfo()
   local NowTime = TimeUtil.getServerTimeSeconds() 
    if doubleChargeTimeBeforeFeatureName == nil then
	   return 
	end

	if doubleChargeTimeCurrFeatureName == nil then

	   return 
	end


	local doubleChargeTimeCurr = getStartTime(doubleChargeTimeCurrFeatureName)
	local doubleChargeTimeBefore = getStartTime(doubleChargeTimeBeforeFeatureName)
    
    local function setVersion(version)
    	DoubleChargeInfo.doubleCharge = true
	    DoubleChargeInfo.version = version
	    DataManager.setDoubleChargeInfo(DoubleChargeInfo)
    end
  
   
   if  NowTime < tonumber(doubleChargeTimeBefore)  then --在第一次开启首冲翻倍前走久逻辑
	     setVersion(0)
   else
   	    
   	    if tonumber(NowTime) >= tonumber(doubleChargeTimeCurr) then --当前的时间是否大于现在的配置时间
   			if tonumber(DoubleChargeInfo.version) ~= tonumber(doubleChargeTimeCurr) then 
   				setVersion(tonumber(doubleChargeTimeCurr))
   			
   			end 
   		elseif  tonumber(NowTime) >= tonumber(doubleChargeTimeBefore)  and  tonumber(NowTime) < tonumber(doubleChargeTimeCurr) then --在两个时间配置之间
   			
   			if tonumber(DoubleChargeInfo.version) ~= tonumber(doubleChargeTimeBefore) then 
   			
   				setVersion(tonumber(doubleChargeTimeBefore))
   		
   			end
   		end  
    end
 end

local function isChargeDouble()--判断是否首冲 

	
   local gameSettingConfig = MetaManager.getGameSettingConfig()
   local doubleChargeTimeBeforeFeatureName = gameSettingConfig.doubleChargeTimeBeforeName
   local doubleChargeTimeCurrFeatureName = gameSettingConfig.doubleChargeTimeCurrName
   local DoubleChargeInfo  = DataManager.getDoubleChargeInfo()
   local NowTime = TimeUtil.getServerTimeSeconds() 
    if doubleChargeTimeBeforeFeatureName == nil then
	   return (tonumber(DataManager.getCurrUser().rechargeGems) <= 0)
	end

	if doubleChargeTimeCurrFeatureName == nil then

	   return (tonumber(DataManager.getCurrUser().rechargeGems) <= 0)
	end

	local doubleChargeTimeCurr = getStartTime(doubleChargeTimeCurrFeatureName)
	local doubleChargeTimeBefore = getStartTime(doubleChargeTimeBeforeFeatureName)
   -- print("~~~~~~~~~~~~~~~~~~~~doubleChargeTimeCurr = "..tostringRich(doubleChargeTimeCurr))
   -- print("~~~~~~~~~~~~~~~~~~~~doubleChargeTimeBefore = "..tostringRich(doubleChargeTimeBefore))
   -- print("~~~~~~~~~~~~~~~~~~~~NowTime = "..tostringRich(NowTime))
  
   
   if  NowTime < tonumber(doubleChargeTimeBefore) then --在第一次开启首冲翻倍前走久逻辑

      return (tonumber(DataManager.getCurrUser().rechargeGems) <= 0)
   else
   	    
   	    if tonumber(NowTime) >= tonumber(doubleChargeTimeCurr) then --当前的时间是否大于现在的配置时间 --配置时间一样也会走这个逻辑
   			if tonumber(DoubleChargeInfo.version) == tonumber(doubleChargeTimeCurr) then 
   				
   				return false
   			else
   				
   				if DoubleChargeInfo.doubleCharge then
	   	  	 		DoubleChargeInfo.doubleCharge = false
					DataManager.setDoubleChargeInfo(DoubleChargeInfo)
	   	  	 	end 
	   	  	 	return true
   			end 
   		elseif  tonumber(NowTime) >= tonumber(doubleChargeTimeBefore)  and  tonumber(NowTime) < tonumber(doubleChargeTimeCurr) then --在两个时间配置之间 --配置时间不一样
   			
   			if tonumber(DoubleChargeInfo.version) == tonumber(doubleChargeTimeBefore) then 
   			
   				return false
   			else
   				
   				if DoubleChargeInfo.doubleCharge then
	   	  	 		DoubleChargeInfo.doubleCharge = false
					DataManager.setDoubleChargeInfo(DoubleChargeInfo)
	   	  	 	end 
	   	  	 	return true
   			end
   		    
        end
          
          
   end
  
	return (tonumber(DataManager.getCurrUser().rechargeGems) <= 0)
end

local function getChargeInfos()--获取充值列表并且进行一些转换
	local chargeInfos = {}
	for k,data in pairs(MetaManager.getPaymentExchangeConfig()) do
		if data.onSale then
			local chargeInfo = table.clone(data, true)
			chargeInfo.isHot = (data.tag == 1)
			chargeInfo.amount = data.goldNum
			chargeInfo.extraAmount = data.giftGoldNum
			chargeInfo.chargeAmount = chargeInfo.amount + chargeInfo.extraAmount
			chargeInfo.priceText = Localization:getInstance():getText(data.itemDescKey, {num = tostring(data.platformCoin)}) 
			chargeInfo.textKey = data.textKey
			if not isTWHE() and not isShortPayItem(chargeInfo.id) then
				table.insert(chargeInfos, chargeInfo)
			end
		end
	end
    
    if isGooglePlayTW() or isTWHE() then
        --gash pay
        if isGashPayOpen() then
            table.insert(chargeInfos, {id = "gash_pay",
                                        priceText = Localization:getInstance():getText("gash_Name") ,
                                        platformCoin = 0,
                                        amount = 100000 + 1})
            he_log_info("++++++++++++insert gash_pay")						   
        end
        --mycard pay
        if isMycardPayOpen() then
            table.insert(chargeInfos, {id = "mycard_pay",
                                        priceText = Localization:getInstance():getText("mycard_Name"),
                                        platformCoin = 0,
                                        amount = 100000 + 2})
            he_log_info("++++++++++++insert mycard_pay")
        end  
    end
	print(table.tostring(chargeInfos))
	return chargeInfos
end

local function getShortChargeInfos()--获取短代支付充值列表
    local chargeInfos = {}
	for k,data in pairs(MetaManager.getPaymentExchangeConfig()) do
		if data.onSale then
			local chargeInfo = table.clone(data, true)
			chargeInfo.isHot = (data.tag == 1)
			chargeInfo.amount = data.goldNum
			chargeInfo.extraAmount = data.giftGoldNum
			chargeInfo.chargeAmount = chargeInfo.amount + chargeInfo.extraAmount
			chargeInfo.priceText = Localization:getInstance():getText(data.itemDescKey, {num = tostring(data.platformCoin)}) 
			chargeInfo.textKey = data.textKey
			if isShortPayItem(chargeInfo.id) then
				table.insert(chargeInfos, chargeInfo)
			end
		end
	end
	print(table.tostring(chargeInfos))
	return chargeInfos
end

local itemServerInfoTable = {}
local lifeLimitDataTable = {}
local dailyLimitDataTable = {}
-- local undercarriageTable = {}--即将下架商品列表
-- local shelvesTable = {}--即将上架商品列表

local function getTimeLimitGoodBeginTime( id )
	local beginTime = string.split(MetaManager.shop_meta[id].loopLimitDateStart , '/')
	local beginTimeStamp = TimeUtil.getTargetTimestampBy(beginTime[1], beginTime[2], beginTime[3], 0, 0, 0)
	return beginTimeStamp
end

local function getTimeLimitGoodEndTime( id )
	local endTime = string.split(MetaManager.shop_meta[id].loopLimitDateEnd , '/')
	local endTimeStamp = TimeUtil.getTargetTimestampBy(endTime[1], endTime[2], endTime[3], 0, 0, 0)
	return endTimeStamp
end

-- local function sortTimeLimitGoods()
-- 	shelvesTable = {}
-- 	local currentTime = TimeUtil.getServerTimeSeconds()
-- 	for key,value in pairs(MetaManager.shop_meta) do
-- 		if value.requireVipLevel and value.requireVipLevel ~= "0" and value.loopLimitTime ~= -1 then
-- 			if currentTime < getTimeLimitGoodBeginTime(value.id) then
-- 				table.insert(shelvesTable , value)
-- 			end
-- 		end
-- 	end
-- end

local function getItemServerInfoById(shopId)--获取商品信息
	if not itemServerInfoTable[shopId] then
		local shopData = {}
		shopData.isNew = true;
		shopData.lifeBuyTimes = 0;
		for k , data in pairs(lifeLimitDataTable) do
			if data.goodMetaId == shopId then
				shopData.lifeBuyTimes = data.lifePurchaseTimes
				break;
			end
		end
		shopData.dailyBuyTimes = 0;
		for k , data in pairs(dailyLimitDataTable) do
			if data.goodMetaId == shopId then
				shopData.dailyBuyTimes = data.dailyPurchaseTimes
				break;
			end
		end
		
		itemServerInfoTable[shopId] = shopData
	end
	return itemServerInfoTable[shopId]
end

local function isGoldTooMuch(num)
	return false
end

local function isDataVipTreasureBox(data)--判断商品是否为VIP宝箱
	return MetaManager.prop_meta[data.metaId].effectType == Prop_Effect_Type.TREASUREBOX
end

local function isCurVipMaxLevel(level)--判断VIPLEVEL是否为最大
	local maxLevel = 0
	for k,v in pairs(MetaManager.vip_setting) do
		if maxLevel < v.level then
			maxLevel = v.level
		end
	end
	return level >= maxLevel
end

local function getCurVipInfo()--获取当前VIP等级相关信息
	local info = {}
	info.level = tonumber(DataManager.getCurrUser().vipLevel)
	info.levelupCurGold = tonumber(DataManager.getCurrUser().rechargeGems + DataManager.getCurrUser().vipExp)
	if isCurVipMaxLevel(info.level) then
		info.levelupTotalGold = MetaManager.vip_setting[info.level].requireGold
	else
		info.levelupTotalGold = MetaManager.vip_setting[info.level + 1].requireGold
	end
	return info
end

ShopScene = class(BaseUIScene)
local visibleSize = CCSizeMake(720, 1280)

function ShopScene.getVipTreasureBoxDatas(data)--获取VIP宝箱可以开出的道具信息列表
	local boxDatas = {}
	local rewardPackageData = MetaManager.reward_package[MetaManager.prop_meta[data.metaId].effectValue]
	if rewardPackageData then
		for i = 1, 10 do
			local contentType = rewardPackageData["content" .. i .. "Type"]
			local contentId = rewardPackageData["content" .. i .. "Id"]
			local contentAmount = rewardPackageData["content" .. i .. "Amount"]
			if contentAmount > 0 then
				local boxData = {}
				boxData.amount = contentAmount
				boxData.dataType = contentType
				boxData.metaId = contentId
				table.insert(boxDatas, boxData)
			end
		end
	end
	return boxDatas
end

function ShopScene:ctor()
	self.tableView = {}
	self.tableData = {}
	self.title = getTextByKey("shop_title")
	self.tabButtonUI = {}
	self.tabButton = {}
	itemServerInfoTable = {}
	lifeLimitDataTable = {}
	dailyLimitDataTable = {}
	self.curSceneEnum = SceneEnum.ShopScene
	for i = 1, TABLEVIEW_TAB_INDEX.TOTAL_TAB_AMOUNT - 1 do
		self.tableData[i] = {}
	end
	
end

function ShopScene:create( argv )
    if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end
    
    local scene = ShopScene.new()
    scene:initScene()
    return scene
end

function ShopScene:onInit()	
	lifeLimitDataTable = DataManager.getLifeLimitGoodsData()
	dailyLimitDataTable = DailyDataManager.getDailyLimitGoodsData()
	BaseUIScene.initBackGround(self)
	--新UI加黑底
    local colorLayer = LayerColor:create()
    colorLayer:setOpacity(kDarkOpacity)
    colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(colorLayer)

	self.builder = LayoutBuilder:createWithContentsOfFile("scene/shop_new.json")
	self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("shop_title")
	self:addChild(self.mainUI)
	BaseUIScene.onInit(self)

	self.cdComponents = {}
	
    
	self.tabButtonUI[TABLEVIEW_TAB_INDEX.GOLD_SHOP] = self.mainUI:getChildByName("btn_shoptitle_goldshop")
	self.tabButtonUI[TABLEVIEW_TAB_INDEX.VIP_SHOP] = self.mainUI:getChildByName("btn_shoptitle_vipshop")
	self.tabButtonUI[TABLEVIEW_TAB_INDEX.CHARGE] = self.mainUI:getChildByName("btn_shoptitle_recharge")
    self.tabButtonUI[TABLEVIEW_TAB_INDEX.SHORT_CHARGE] = self.mainUI:getChildByName("btn_shoptitle_more_credit")
	
	self.tabButtonUI[TABLEVIEW_TAB_INDEX.GOLD_SHOP]:getChildByName("txt"):setString(getTextByKey("shop_goldTab"))
	self.tabButtonUI[TABLEVIEW_TAB_INDEX.VIP_SHOP]:getChildByName("txt"):setString(getTextByKey("shop_vipTab"))
	self.tabButtonUI[TABLEVIEW_TAB_INDEX.CHARGE]:getChildByName("txt"):setString(getTextByKey("shop_chargeTab"))
    self.tabButtonUI[TABLEVIEW_TAB_INDEX.SHORT_CHARGE]:getChildByName("txt"):setString(getTextByKey("bill_recharge_title"))
    
    self.mainUI:getChildByName("txt"):getChildByName("txt"):setString(getTextByKey("bill_recharge_text"))
    
	local function onClickButton(evt)

		self:showTableView(evt.context)
	end
	
	for i = 1, TABLEVIEW_TAB_INDEX.TOTAL_TAB_AMOUNT - 1 do
        if i == TABLEVIEW_TAB_INDEX.SHORT_CHARGE and not isShortPayOpen() then
            self.tabButtonUI[TABLEVIEW_TAB_INDEX.SHORT_CHARGE]:setVisible(false)
        else
            self.tabButton[i] = Button:create(self.tabButtonUI[i])
            self.tabButton[i]:addEventListener(Events.kStart, onClickButton, i)
            self.tabButtonUI[i]:getChildByName("btn_shoptitle_active"):setVisible(false)
        end
	end
	
	local vipPos = self.mainUI:getChildByName("vipbar"):getChildByName("shop_icon_common_vip_ing"):getPosition()
	local vipContentSize = self.mainUI:getChildByName("vipbar"):getChildByName("shop_icon_common_vip_ing"):getContentSize()
	
	local numberLabel = CCLabelAtlas:create("0", "pic/number_vip.png", 22, 41, 48)
	numberLabel:setScale(1.25)
	numberLabel:setAnchorPoint(ccp(0, 0.5))
	numberLabel:setPosition(ccp(vipPos.x + vipContentSize.width, vipPos.y - vipContentSize.height /2))
	local numberLabel_co = CocosObject.new(numberLabel)
	self.mainUI:getChildByName("vipbar"):addChild(numberLabel_co)
	self.vipNumberLabel = numberLabel
	
	local vipPos = self.mainUI:getChildByName("vipbar"):getChildByName("shop_icon_common_vip"):getPosition()
	local vipContentSize = self.mainUI:getChildByName("vipbar"):getChildByName("shop_icon_common_vip"):getContentSize()
	
	local numberLabel = CCLabelAtlas:create("0", "pic/number_vip.png", 22, 41, 48)
	numberLabel:setScale(1.25)
	numberLabel:setAnchorPoint(ccp(0, 0.5))
	numberLabel:setPosition(ccp(vipPos.x + vipContentSize.width, vipPos.y - vipContentSize.height /2))
	local numberLabel_co = CocosObject.new(numberLabel)
	self.mainUI:getChildByName("vipbar"):addChild(numberLabel_co)
	self.nextvipNumberLabel = numberLabel
	
	self.vipProgressBar = ProgressBar:create(self.mainUI:getChildByName("vipbar"):getChildByName("vip_boost"):getChildByName("vip_boost_sb"))
	
	self:refreshChargePic()
	
	local vipInfo = getCurVipInfo()
	vipInfo.isMaxLevel = isCurVipMaxLevel(vipInfo.level)
	self.vipPrivilegePanel = VipPrivilegePanel:create(self, vipInfo, true)
	self.vipPrivilegePanel:retain()
	
	local function onClickVipPrivilegeButton()
		local vipInfo = getCurVipInfo()
		vipInfo.isMaxLevel = isCurVipMaxLevel(vipInfo.level)
		self.vipPrivilegePanel:refreshPanel(vipInfo, true)
		self.targetInfoPanel = self.vipPrivilegePanel
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
	end
	if isDKAndroid() then
		self.mainUI:getChildByName("vipbar"):getChildByName("txt_shop_1"):getChildByName("txt"):setString(getTextByKey("restart_text"))
	end
	self.mainUI:getChildByName("vipbar"):getChildByName("btn_vip_privilege"):getChildByName("txt"):setString(getTextByKey("shop_vipBtn"))
	local vipPrivilegeButton = Button:create(self.mainUI:getChildByName("vipbar"):getChildByName("btn_vip_privilege"))
	vipPrivilegeButton:addEventListener(Events.kStart, onClickVipPrivilegeButton)
	
	if self.argv.params.tabIndex then
		self:showTableView(self.argv.params.tabIndex)
	else
		self:showTableView(TABLEVIEW_TAB_INDEX.GOLD_SHOP)
	end
end 

function ShopScene:refreshChargePic()--刷新充值界面左侧的图片
	local getCurrentIsDouble = isFirstCharge()
	
	if self.rechargeAd then
		self.mainUI:setChildIndex(self.rechargeAd, 1000)
	end
	
	if getCurrentIsDouble == self.previousIsDouble then
		do return end
	end
	self.previousIsDouble = getCurrentIsDouble
	self.mainUI:getChildByName("shop_recharge_ad"):setVisible(false)
	if self.rechargeAd then
		self.rechargeAd:removeFromParentAndCleanup(true)
		self.rechargeAd = nil;
	end
	
	local function onClickRecharge()
		self:replaceScene(GachaScene, {returnScene = "ShopScene"})
	end
	
	local rechargePos = self.mainUI:getChildByName("shop_recharge_ad"):getPosition()
	if getCurrentIsDouble then
		self.rechargeAd = Sprite:create("pic/show_ad_simple.png")
		local textSprite1 = Sprite:create("pic/shouchongsong.png")
		textSprite1:setPositionXY(self.rechargeAd:getContentSize().width / 2, self.rechargeAd:getContentSize().height - 80)
		self.rechargeAd:addChild(textSprite1)
		local textSprite2 = Sprite:create("pic/shouchongsong2.png")
		textSprite2:setPositionXY(self.rechargeAd:getContentSize().width / 2, self.rechargeAd:getContentSize().height - 80)
		self.rechargeAd:addChild(textSprite2)
		textSprite2:setVisible(false)
		
		local function shining()
			textSprite1:setVisible(not textSprite1:isVisible())
			textSprite2:setVisible(not textSprite2:isVisible())
		end
		
		local actionArray = CCArray:create()
		actionArray:addObject(CCDelayTime:create(0.1))
		actionArray:addObject(CCCallFuncN:create(shining))
		self.rechargeAd:runAction(CCRepeatForever:create(CCSequence:create(actionArray)))
	else
		self.rechargeAd = Sprite:create("pic/show_ad_gacha.png")
		self.rechargeButton = Button:create(self.rechargeAd)
		self.rechargeButton:addEventListener(Events.kStart, onClickRecharge)
	end
	self.rechargeAd:setAnchorPoint(ccp(0, 1))
	self.rechargeAd:setPositionXY(rechargePos.x, rechargePos.y)
	self.mainUI:addChild(self.rechargeAd)
end

function ShopScene:getTableData(tabIndex)--根据INDEX获取对应的商品或者充值相关信息
	table.removeAll(self.tableData[tabIndex])
	if tabIndex == TABLEVIEW_TAB_INDEX.GOLD_SHOP then
		for key,value in pairs(MetaManager.shop_meta) do
			if value.requireVipLevel == "0" and value.enable then --判断是否可卖shop_meta "enanle"字段 l1ghtsaber 2015/7/14
				local itemInfo = table.clone(value, true)
				itemInfo.ownAmount = 0
				itemInfo.needVipLevel = 0
				for k,item in pairs(DataManager.getPropsData()) do
					if tonumber(item.metaId) == tonumber(value.metaId) then 
						itemInfo.ownAmount = tonumber(item.amount)
						break;
					end
				end
				table.insert(self.tableData[tabIndex], itemInfo)
			end
		end
		self:sortTableData(tabIndex)
	elseif tabIndex == TABLEVIEW_TAB_INDEX.VIP_SHOP then
		for key,value in pairs(MetaManager.shop_meta) do
			if value.requireVipLevel and value.requireVipLevel ~= "0" and value.enable then
				local levels = string.split(value.requireVipLevel, ',');
				local curVipLevel = tonumber(DataManager.getCurrUser().vipLevel)
				local vipLevelEnable = false
				local nextVipLevelEnable = false
				local isVIPBox = (value.lifePurchaseLimit == 1) or (value.loopLimitTime ~= -1)
				local needVipLevel = 99
				for k, level in ipairs(levels) do
					local curLevel = tonumber(level)
					if curVipLevel == curLevel then
						vipLevelEnable = true;
					elseif curVipLevel + 1 == curLevel then
						nextVipLevelEnable = true
					end
					if curLevel < needVipLevel then
						needVipLevel = curLevel
					end
				end

				local vipShouldShow = true
				local vipInfo = getCurVipInfo()
				if needVipLevel > 15 and (needVipLevel - vipInfo.level ) > 1 then
					vipShouldShow = false
				end

				local isOnSell = true
				local currentTime = TimeUtil.getServerTimeSeconds()
				if (value.loopLimitTime ~= -1) then
					if currentTime > getTimeLimitGoodEndTime(value.id) or currentTime < getTimeLimitGoodBeginTime(value.id) then
						isOnSell = false
					end
				end
				
				if (vipLevelEnable or nextVipLevelEnable or isVIPBox) and vipShouldShow and isOnSell then
					if value.loopLimitTime ~= -1 or value.lifePurchaseLimit == -1 or getItemServerInfoById(value.id).lifeBuyTimes < value.lifePurchaseLimit then
						local itemInfo = table.clone(value, true)
						itemInfo.vipLevelEnable = vipLevelEnable
						itemInfo.ownAmount = 0
						for k,item in pairs(DataManager.getPropsData()) do
							if tonumber(item.metaId) == tonumber(value.metaId) then 
								itemInfo.ownAmount = tonumber(item.amount)
								break;
							end
						end
						itemInfo.needVipLevel = needVipLevel
						table.insert(self.tableData[tabIndex], itemInfo)
					end
				end
			end
		end
		self:sortTableData(tabIndex)
	elseif tabIndex == TABLEVIEW_TAB_INDEX.CHARGE then
		for k,data in pairs(getChargeInfos()) do
			table.insert(self.tableData[tabIndex], data)
		end
		self:sortTableData(tabIndex)
    elseif  tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE then
		for k,data in pairs(getShortChargeInfos()) do
			table.insert(self.tableData[tabIndex], data)
		end
		self:sortTableData(tabIndex)
	end
end

function ShopScene:refreshComponents(tabIndex)
	local function onTimeTick(remainedSec , extra)
		local itemInfo = MetaManager.shop_meta[extra.id]
		local curTableViewIndex = self.curTableViewIndex or tabIndex
		local aTime = {hh = 0, mm = 0, ss = 0}
		  aTime.ss = math.mod(remainedSec,60) 
		  remainedSec = math.modf(remainedSec/60)
		  aTime.mm = math.mod(remainedSec,60)
		  remainedSec = math.modf(remainedSec/60)
		  aTime.hh = remainedSec
		local day = math.modf(aTime.hh / 24)

		local formatedTimeStr = ""
		if day ~= 0 then
			formatedTimeStr = getTextByKey("loopLimitTime01",{day = day , hour = aTime.hh - day * 24})
		else
			if (aTime.hh - day * 24) ~= 0 then
				formatedTimeStr = getTextByKey("loopLimitTime02",{hour = aTime.hh - day * 24 , min = aTime.mm})
			else
				formatedTimeStr = getTextByKey("loopLimitTime03",{min = aTime.mm, sec = aTime.ss})
			end
		end

		local pos = 10000
		for k,v in pairs(self.tableData[extra.index]) do
			if v.id == extra.id then
				pos = k - 1
			end
		end

		if self.tableView[curTableViewIndex] and self.tableView[curTableViewIndex]:cellAtIndex(pos) and extra.index == curTableViewIndex then
			local selectedCell = self.tableView[curTableViewIndex]:cellAtIndex(pos):getChildByTag(-1001)
			buyTimesText = getTextByKey("redBag015")..VipManager.getRedPacketBuyTimes(itemInfo.id) .. "/" .. itemInfo.loopLimit .. formatedTimeStr
			local txt = selectedCell:getChildByTag(1013):getChildByTag(1013)
			setNodeText(txt, buyTimesText);
		end
		
		-- local formatedTimeStr = getTextByKey("loopLimitTime",{day = day , hour = aTime.hh - day * 24 , min = aTime.mm , sec = aTime.ss})
		
		-- setTextByTag(cell, TAG_TXT_ITEM_LIMIT, buyTimesText)
	end
	local function onTimeComplete(extra)
		-- local index = TABLEVIEW_TAB_INDEX.VIP_SHOP
		-- if (MetaManager.shop_meta[extra.id].requireVipLevel) and (MetaManager.shop_meta[extra.id].requireVipLevel) == "0" then
		-- 	index = TABLEVIEW_TAB_INDEX.GOLD_SHOP
		-- else
		-- 	index = TABLEVIEW_TAB_INDEX.VIP_SHOP
		-- end
		--删除过期的商品
		local currentTime = TimeUtil.getServerTimeSeconds()
		for i=#self.tableData[tabIndex],1,-1 do
			if self.tableData[tabIndex][i].loopLimitDateEnd ~= -1 then
				if currentTime > getTimeLimitGoodEndTime(self.tableData[tabIndex][i].id) then
					local r = table.remove(self.tableData[tabIndex] , i)
					if self.cdComponents[r.id] then
						self.cdComponents[r.id]:stop()
					end
				end
			end
		end
		local offset = self.tableView[extra.index]:getContentOffset()
		self:sortTableData(extra.index)
		self.tableView[extra.index]:reloadData()
		self.tableView[extra.index]:setContentOffset(offset)

		self:refreshComponents(extra.index)
	end

	for k,v in pairs(self.tableData[tabIndex]) do
		if self.cdComponents[v.id] then
			self.cdComponents[v.id]:stop()
		end
		if v.loopLimitTime and v.loopLimitTime ~= -1 then

			local index = tabIndex
			-- if (MetaManager.shop_meta[v.id].requireVipLevel) and (MetaManager.shop_meta[v.id].requireVipLevel) == "0" then
			-- 	index = TABLEVIEW_TAB_INDEX.GOLD_SHOP
			-- else
			-- 	index = TABLEVIEW_TAB_INDEX.VIP_SHOP
			-- end
			self.cdComponents[v.id] = CdLabelComponent:create({index = index , id = v.id})
			self.cdComponents[v.id]:setCallback(onTimeTick, onTimeComplete)
			self.cdComponents[v.id]:setTargetTime(VipManager.getNextRefreshTime(v.id))--往后偏移3秒，防止前端刷新了，后端还没刷新
			self.cdComponents[v.id]:start()
		end
	end
end

local rechargeAdMovePos = 250
local rechargeAdMovingDuration = 0.05
function ShopScene:showTableView(tabIndex)--根据INDEX显示商品或者充值的列表
	if self.curTableViewIndex == tabIndex then
		do return end
	end
	
	if tabIndex == TABLEVIEW_TAB_INDEX.CHARGE or tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE then
		if self.tableView[tabIndex] then
			self.tableView[tabIndex]:reloadData()
		end
	end
	-- if self.cdComponents then
	-- 	for k,v in pairs(self.cdComponents) do
	-- 		v:stop()
	-- 	end
	-- end
	if not self.tableView[tabIndex] then
		self:getTableData(tabIndex)
		self.tableView[tabIndex] = self:createTableView(tabIndex, self.tableData[tabIndex])
		self.mainUI:addChild(self.tableView[tabIndex])
		self.tableView[tabIndex]:setVisible(false)

		self:refreshComponents(tabIndex)
	end
	
	local function onShowFinish()
		self:setTableViewsEnabled(true)
	end
	
	local function onDisappearFinish()
		ViewControlUtil.showTableViewAction(self.tableView[tabIndex], visibleSize, onShowFinish)
		self.mainUI:getChildByName("vipbar"):setVisible(tabIndex ~= TABLEVIEW_TAB_INDEX.GOLD_SHOP)
        self.mainUI:getChildByName("txt"):setVisible(tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE)
		self.rechargeAd:setVisible(tabIndex == TABLEVIEW_TAB_INDEX.CHARGE or tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE)
		if self.rechargeButton then
			self.rechargeButton:setEnable(tabIndex == TABLEVIEW_TAB_INDEX.CHARGE or tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE)
		end
		self.mainUI:getChildByName("vipbar"):runAction(CCMoveBy:create(0.15, ccp(visibleSize.width, 0)))
		self.rechargeAd:runAction(CCMoveBy:create(rechargeAdMovingDuration, ccp(rechargeAdMovePos, 0)))
	end
	
	self:setTableViewsEnabled(false)
	
	if self.curTableViewIndex then
		ViewControlUtil.disappearTableViewAction(self.tableView[self.curTableViewIndex], visibleSize, onDisappearFinish)
		self.mainUI:getChildByName("vipbar"):runAction(CCMoveBy:create(0.15, ccp(-visibleSize.width, 0)))
		local actionArray = CCArray:create()
		actionArray:addObject(CCDelayTime:create(0.3 - rechargeAdMovingDuration))
		actionArray:addObject(CCMoveBy:create(rechargeAdMovingDuration, ccp(-rechargeAdMovePos, 0)))
		self.rechargeAd:runAction(CCSequence:create(actionArray))
	else
		self.mainUI:getChildByName("vipbar"):setPositionX(self.mainUI:getChildByName("vipbar"):getPositionX() - visibleSize.width)
		self.rechargeAd:setPositionX(self.rechargeAd:getPositionX() - rechargeAdMovePos)
		onDisappearFinish()
	end
	self.curTableViewIndex = tabIndex
	
	
	
	for i = 1, TABLEVIEW_TAB_INDEX.TOTAL_TAB_AMOUNT - 1 do
		if self.tableView[i] then
			if tabIndex ~= i then
				--self.tableView[i]:setVisible(false)
				self.tabButtonUI[i]:getChildByName("btn_shoptitle_active"):setVisible(false)
				self.tabButtonUI[i]:getChildByName("btn_shoptitle_inactive"):setVisible(true)
			else
				--self.tableView[i]:setVisible(true)
				self.tabButtonUI[i]:getChildByName("btn_shoptitle_active"):setVisible(true)
				self.tabButtonUI[i]:getChildByName("btn_shoptitle_inactive"):setVisible(false)
			end
		end
	end
	
	--[[self.mainUI:getChildByName("vipbar"):setVisible(tabIndex ~= TABLEVIEW_TAB_INDEX.GOLD_SHOP)
	self.rechargeAd:setVisible(tabIndex == TABLEVIEW_TAB_INDEX.CHARGE)--]]
	
	if tabIndex ~= TABLEVIEW_TAB_INDEX.GOLD_SHOP then
		self:resetVipProgress(tabIndex)
	end
	
end

function ShopScene:sortTableData(tabIndex)--对商品或者充值的信息进行排序
	if tabIndex == TABLEVIEW_TAB_INDEX.GOLD_SHOP then
		local function goldSortFunc(a, b)
			return a.order < b.order
		end
		table.sort(self.tableData[tabIndex], goldSortFunc)
	elseif tabIndex == TABLEVIEW_TAB_INDEX.VIP_SHOP then
		local curVipLevel = tonumber(DataManager.getCurrUser().vipLevel)
		local function vipSortFunc(a, b)
			local isASpecial = (a.needVipLevel >= curVipLevel + 2)
			local isBSpecial = (b.needVipLevel >= curVipLevel + 2)
			if isASpecial ~= isBSpecial then
				return not isASpecial
			elseif isASpecial then
				return a.needVipLevel < b.needVipLevel
			elseif a.vipLevelEnable ~= b.vipLevelEnable then
					return not a.vipLevelEnable
			else
				return a.order < b.order
			end
		end

		local function limitVipSortFunc(a , b)
			local Atime = VipManager.getNextRefreshTime(a.id) - TimeUtil.getServerTimeSeconds()
			local Btime = VipManager.getNextRefreshTime(b.id) - TimeUtil.getServerTimeSeconds()
			if Atime == Btime then
				return a.order < b.order
			else
				return Atime < Btime
			end
		end

		local tempTable = {}
		local limitTempTable = {}

		for k,v in pairs(self.tableData[tabIndex]) do
			if v.loopLimitTime ~= -1 and VipManager.getRedPacketBuyTimes(v.id) >= v.loopLimit then
				table.insert(limitTempTable , v)
			else
				table.insert(tempTable , v)
			end
		end

		table.sort(tempTable , vipSortFunc)
		table.sort(limitTempTable , limitVipSortFunc)
		-- self.tableData[tabIndex] = {}
		for i=#self.tableData[tabIndex],1 , -1 do
			table.remove(self.tableData[tabIndex] , i)
		end

		for k,v in pairs(tempTable) do
			table.insert(self.tableData[tabIndex] , v)
		end
		for k,v in pairs(limitTempTable) do
			table.insert(self.tableData[tabIndex] , v)
		end

		-- table.sort(self.tableData[tabIndex], vipSortFunc)
	elseif tabIndex == TABLEVIEW_TAB_INDEX.CHARGE or tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE then
		local function chargeSortFunc(a, b)
			return a.amount < b.amount
		end
		table.sort(self.tableData[tabIndex], chargeSortFunc)
	end
end

function ShopScene:refreshTable(keepOffset, tabIndex)--刷新商品或者充值的列表
	if keepOffset then
		local tableOffset = self.tableView[tabIndex]:getContentOffset()
		self.tableView[tabIndex]:reloadData()
		local minOffset = self.tableView[tabIndex]:getViewSize().height - 185 * table.getn(self.tableData[tabIndex])
		if tableOffset.y > 0 then
			tableOffset.y = 0
		end
		if tableOffset.y < minOffset then
			tableOffset.y = minOffset
		end
		self.tableView[tabIndex]:setContentOffset(tableOffset, true)
	else
		self.tableView[tabIndex]:reloadData()
	end
end

function ShopScene:resetVipProgress(tabIndex)--刷新VIP进度条
	local vipInfo = getCurVipInfo()
	
	self.mainUI:getChildByName("vipbar"):getChildByName("txt_exp_font"):getChildByName("txt"):setString(tostring(vipInfo.levelupCurGold) .. "/" .. vipInfo.levelupTotalGold)
	local percentage = 0
	if vipInfo.levelupTotalGold > 0 then
		percentage = vipInfo.levelupCurGold / vipInfo.levelupTotalGold * 100
	end
	if percentage > 100 then
		percentage = 100
	end
	
	self.vipNumberLabel:setString(tostring(vipInfo.level))
	self.nextvipNumberLabel:setString(tostring(vipInfo.level + 1))
	self.vipProgressBar:setPercentage(percentage)
	if isCurVipMaxLevel(vipInfo.level) then
		self.mainUI:getChildByName("vipbar"):getChildByName("txt_rechargemore"):getChildByName("txt"):setString(getTextByKey("shop_vipPrivilege_levelMax"))
		self.nextvipNumberLabel:setVisible(false)
	elseif tabIndex == TABLEVIEW_TAB_INDEX.VIP_SHOP then
		self.mainUI:getChildByName("vipbar"):getChildByName("txt_rechargemore"):getChildByName("txt"):setString(Localization:getInstance():getText("shop_vipPrivilege_vipLevel", {num = vipInfo.levelupTotalGold - vipInfo.levelupCurGold, vipLevel = ""}))
		self.nextvipNumberLabel:setVisible(true)
	elseif tabIndex == TABLEVIEW_TAB_INDEX.CHARGE or tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE then
		self.mainUI:getChildByName("vipbar"):getChildByName("txt_rechargemore"):getChildByName("txt"):setString(Localization:getInstance():getText("shop_vipPrivilege_vipLevel", {num = vipInfo.levelupTotalGold - vipInfo.levelupCurGold, vipLevel = ""}))
		self.nextvipNumberLabel:setVisible(true)
		self:refreshChargePic()
	end
	
	
end

local TABLEVIEW_CELL_TAG = -1001
local CELL_WIDTH = BAGCONFIG.WIDTH
local CELL_HEIGHT = 185
local TABLEVIEW_WIDTH = BAGCONFIG.WIDTH
local TABLEVIEW_PIXIEL_Y = 50
local TABLEVIEW_HEIGHT = BAGCONFIG.HEIGHT - 105 + TABLEVIEW_PIXIEL_Y
local TABLEVIEW_POS_X = 0
local TABLEVIEW_POS_Y = (1280-BAGCONFIG.HEIGHT)/2-30 - TABLEVIEW_PIXIEL_Y
local CHARGE_OFFSETX = 200

local TAG_ITEM_PIC = 1001
local TAG_ICON_WHITE = 1002
local TAG_ICON_GREEN = 1003
local TAG_ICON_BLUE = 1004
local TAG_ICON_PURPLE = 1005
local TAG_ICON_ORANGE = 1006
local TAG_ICON_RED = 1007
local TAG_ICON_GOLD = 1008
local TAG_TXT_OWN_AMOUNT = 1009
local TAG_BUTTON_BUY = 1010
local TAG_TXT_SELLPRICE = 1011
local TAG_TXT_ITEM_NAME = 1012
local TAG_TXT_ITEM_LIMIT = 1013
local TAG_TXT_ITEM_DESC = 1014
local TAG_ICON_ITEM = 1015
local TAG_ICON_DELETELINE = 1016
local TAG_TXT_ITEM_NEWPRICE = 1017
local TAG_ICON_VIP = 1018
local TAG_ICON_VIP_NUM = 1019
local TAG_BUTTON_BUY_INACTIVE = 1020
local TAG_TXT_CHARGE_PRICE = 1021
local TAG_TXT_EXTRA_CHARGE_PRICE = 1022
local TAG_TXT_CHARGE_CHARGE_PRICE = 1023
local TAG_ICON_CHARGE = 1024
local TAG_ICON_CHARGE_BOX = 1025
local TAG_ICON_HOTSELL = 1026
local TAG_BUTTON_CHARGE = 1027
local TAG_ICON_DOUBLE = 1028
local TAG_TXT_NEW_CHARGE_PRICE = 1029
local TAG_TXT_RECGARGE_BONUS = 1030
local TAG_PAYCHANNEL_PIC = 1031

function ShopScene:createTableView(tabIndex, data)
	local ShopSceneRenderer = class(TableViewRenderer)
	function ShopSceneRenderer:ctor(width, height)
		self.list = data
		local builder = LayoutBuilder:createWithContentsOfFile("scene/shop_new.json")
		builder.useArtLabelTTF = true
		self.builder = builder
	end
	
	function ShopSceneRenderer:buildCell(container)
		if tabIndex == TABLEVIEW_TAB_INDEX.GOLD_SHOP then
			local cell = self.builder:build("shop_coinmarket")
			cell:setPosition(ccp(0, self.height))		
			cell:setTag(TABLEVIEW_CELL_TAG)
			container:addChild(cell)
			
			cell:getChildByName("normal_card_small"):setAnchorPoint(ccp(0.5, 0.5))
			cell:getChildByName("normal_card_small"):setVisible(false)
			cell:getChildByName("normal_card_small"):setTag(TAG_ITEM_PIC)
			cell:getChildByName("q_white9_panel"):setTag(TAG_ICON_WHITE)
			cell:getChildByName("q_green9_panel"):setTag(TAG_ICON_GREEN)
			cell:getChildByName("q_blue9_panel"):setTag(TAG_ICON_BLUE)
			cell:getChildByName("q_purple9_panel"):setTag(TAG_ICON_PURPLE)
			cell:getChildByName("q_orange9_panel"):setTag(TAG_ICON_ORANGE)
			cell:getChildByName("q_red9_panel"):setTag(TAG_ICON_RED)
			cell:getChildByName("q_yellow9_panel"):setTag(TAG_ICON_GOLD)
			cell:getChildByName("frame_card"):setVisible(false)
			cell:getChildByName("txt_quantity"):setTag(TAG_TXT_OWN_AMOUNT)
			cell:getChildByName("txt_quantity"):getChildByName("txt_inventory_equip_selled"):setTag(TAG_TXT_OWN_AMOUNT)
			cell:getChildByName("btn_buy"):setTag(TAG_BUTTON_BUY)
			cell:getChildByName("btn_buy"):getChildByName("txt"):setString(getTextByKey("shop_buyBtn"))
			cell:getChildByName("btn_buy_inactive"):setTag(TAG_BUTTON_BUY_INACTIVE)
			cell:getChildByName("btn_buy_inactive"):getChildByName("txt"):setString(getTextByKey("shop_buyBtn"))
			cell:getChildByName("txt_price"):setTag(TAG_TXT_SELLPRICE)
			cell:getChildByName("txt_price"):getChildByName("font"):setTag(TAG_TXT_SELLPRICE)
			cell:getChildByName("txt_inventory_card_name"):setTag(TAG_TXT_ITEM_NAME)
			cell:getChildByName("txt_inventory_card_name"):getChildByName("font"):setTag(TAG_TXT_ITEM_NAME)
			cell:getChildByName("txt_message2"):setTag(TAG_TXT_ITEM_LIMIT)
			cell:getChildByName("txt_message2"):getChildByName("font"):setTag(TAG_TXT_ITEM_LIMIT)
			cell:getChildByName("txt_message"):setTag(TAG_TXT_ITEM_DESC)
			cell:getChildByName("txt_message"):getChildByName("font"):setTag(TAG_TXT_ITEM_DESC)
			cell:getChildByName("shop_icon_priceoff"):setTag(TAG_ICON_DELETELINE)
			cell:getChildByName("shop_txt_newprice"):setTag(TAG_TXT_ITEM_NEWPRICE)
			cell:getChildByName("shop_txt_newprice"):getChildByName("txt"):setTag(TAG_TXT_ITEM_NEWPRICE)
		elseif tabIndex == TABLEVIEW_TAB_INDEX.VIP_SHOP then
			local cell = self.builder:build("shop_vipmarket")
			cell:setPosition(ccp(0, self.height))		
			cell:setTag(TABLEVIEW_CELL_TAG)
			container:addChild(cell)
			
			cell:getChildByName("shop_txt_newprice"):setTag(TAG_TXT_ITEM_NEWPRICE)
			cell:getChildByName("shop_txt_newprice"):getChildByName("txt"):setTag(TAG_TXT_ITEM_NEWPRICE)
			cell:getChildByName("shop_icon_prioff"):setTag(TAG_ICON_DELETELINE)
			cell:getChildByName("icon_common_vip"):setTag(TAG_ICON_VIP)
			cell:getChildByName("txt_quantity"):setTag(TAG_TXT_OWN_AMOUNT)
			cell:getChildByName("txt_quantity"):getChildByName("txt_inventory_equip_selled"):setTag(TAG_TXT_OWN_AMOUNT)
			cell:getChildByName("btn_buy"):setTag(TAG_BUTTON_BUY)
			cell:getChildByName("btn_buy"):getChildByName("txt"):setString(getTextByKey("shop_buyBtn"))
			cell:getChildByName("btn_buy_inactive"):setTag(TAG_BUTTON_BUY_INACTIVE)
			cell:getChildByName("btn_buy_inactive"):getChildByName("txt"):setString(getTextByKey("shop_buyBtn"))
			cell:getChildByName("frame_card"):setVisible(false)
			cell:getChildByName("txt_price"):setTag(TAG_TXT_SELLPRICE)
			cell:getChildByName("txt_price"):getChildByName("font"):setTag(TAG_TXT_SELLPRICE)
			cell:getChildByName("txt_inventory_card_name"):setTag(TAG_TXT_ITEM_NAME)
			cell:getChildByName("txt_inventory_card_name"):getChildByName("font"):setTag(TAG_TXT_ITEM_NAME)
			cell:getChildByName("txt_message2"):setTag(TAG_TXT_ITEM_LIMIT)
			cell:getChildByName("txt_message2"):getChildByName("font"):setTag(TAG_TXT_ITEM_LIMIT)
			cell:getChildByName("txt_message"):setTag(TAG_TXT_ITEM_DESC)
			cell:getChildByName("txt_message"):getChildByName("font"):setTag(TAG_TXT_ITEM_DESC)
			cell:getChildByName("normal_card_small"):setAnchorPoint(ccp(0.5, 0.5))
			cell:getChildByName("normal_card_small"):setVisible(false)
			cell:getChildByName("normal_card_small"):setTag(TAG_ITEM_PIC)
			cell:getChildByName("q_white9_panel"):setTag(TAG_ICON_WHITE)
			cell:getChildByName("q_green9_panel"):setTag(TAG_ICON_GREEN)
			cell:getChildByName("q_blue9_panel"):setTag(TAG_ICON_BLUE)
			cell:getChildByName("q_purple9_panel"):setTag(TAG_ICON_PURPLE)
			cell:getChildByName("q_orange9_panel"):setTag(TAG_ICON_ORANGE)
			cell:getChildByName("q_red9_panel"):setTag(TAG_ICON_RED)
			cell:getChildByName("q_yellow9_panel"):setTag(TAG_ICON_GOLD)
		elseif tabIndex == TABLEVIEW_TAB_INDEX.CHARGE or tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE then
			local cell = self.builder:build("shop_recharge_list")
			cell:setPosition(ccp(200 - CHARGE_OFFSETX, self.height))		
			cell:setTag(TABLEVIEW_CELL_TAG)
			container:addChild(cell)
			
			cell:getChildByName("shop_txt_recharge"):setTag(TAG_TXT_CHARGE_PRICE)
			cell:getChildByName("shop_txt_recharge"):getChildByName("txt"):setTag(TAG_TXT_CHARGE_PRICE)
			cell:getChildByName("shop_txt_recharge_bouns"):setTag(TAG_TXT_EXTRA_CHARGE_PRICE)
			cell:getChildByName("shop_txt_recharge_bouns"):getChildByName("txt"):setTag(TAG_TXT_EXTRA_CHARGE_PRICE)
			cell:getChildByName("shop_txt_recharge1"):setTag(TAG_TXT_NEW_CHARGE_PRICE)
			cell:getChildByName("shop_txt_recharge1"):getChildByName("txt"):setTag(TAG_TXT_NEW_CHARGE_PRICE)
			
			--cell:getChildByName("shop_txt_recharge_bouns2"):setTag(TAG_TXT_CHARGE_CHARGE_PRICE)
			--cell:getChildByName("shop_txt_recharge_bouns2"):getChildByName("txt"):setTag(TAG_TXT_CHARGE_CHARGE_PRICE)
			cell:getChildByName("shop_icon_manycoin"):setTag(TAG_ICON_CHARGE)
			cell:getChildByName("shop_icon_tresure2"):setTag(TAG_ICON_CHARGE_BOX)
			cell:getChildByName("shop_icon_hotsell"):setTag(TAG_ICON_HOTSELL)
			cell:getChildByName("shop_btn_recharge"):setTag(TAG_BUTTON_CHARGE)
			cell:getChildByName("shop_btn_recharge"):getChildByName("txt"):setTag(TAG_BUTTON_CHARGE)
			cell:getChildByName("shop_btn_recharge"):getChildByName("txt"):setColor(ccc3(255, 204, 0))
			cell:getChildByName("icon_double"):setTag(TAG_ICON_DOUBLE)
			
			cell:getChildByName("txt_recharge_bonus"):setTag(TAG_TXT_RECGARGE_BONUS)
			cell:getChildByName("txt_recharge_bonus"):getChildByName("txt"):setTag(TAG_TXT_RECGARGE_BONUS)			
		end
	end
	
	local function setTextByTag( cell, tag, str)
		local txt = cell:getChildByTag(tag):getChildByTag(tag)
		setNodeText(txt, str);
	end
	
	local function setNodeVisibleByTag(cell, tag, visible)
		cell:getChildByTag(tag):setVisible(visible)
	end
	
	local cdComponents = self.cdComponents
	local shopContainer = self
	function ShopSceneRenderer:setData( rawCocosObj, index )
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)
		
		local function setGeneralData(itemInfo, itemMeta)
			local itemPosX, itemPosY = cell:getChildByTag(TAG_ITEM_PIC):getPosition()
			local zOrder = cell:getChildByTag(TAG_ITEM_PIC):getZOrder()
			if cell:getChildByTag(TAG_ICON_ITEM) then
				cell:removeChildByTag(TAG_ICON_ITEM, true)
			end
			
			local canonItem = CanonItem:create()
			canonItem:loadByMetaId(itemInfo.metaId)
			canonItem:setPosition(ccp(itemPosX, itemPosY))
			canonItem:setTag(TAG_ICON_ITEM)
			cell:addChild(canonItem.refCocosObj, zOrder)
			canonItem:dispose();
			
			setTextByTag(cell, TAG_TXT_OWN_AMOUNT, getTextByKey("shop_quantity") .. itemInfo.ownAmount)
			setTextByTag(cell, TAG_TXT_ITEM_DESC, getTextByKey(itemMeta.desc))
			setTextByTag(cell, TAG_TXT_ITEM_NAME, getTextByKey(itemMeta.name) .. "x" .. itemInfo.amount)
			
			local itemServerInfo = getItemServerInfoById(itemInfo.id)
			setNodeVisibleByTag(cell, TAG_BUTTON_BUY, true)
			setNodeVisibleByTag(cell, TAG_BUTTON_BUY_INACTIVE, false)
			
			setNodeVisibleByTag(cell, TAG_TXT_ITEM_LIMIT, not (itemInfo.lifePurchaseLimit == -1 and itemInfo.dailyPurchaseLimit == -1 and itemInfo.loopLimitTime == -1))
			local buyTimesText
			if itemInfo.lifePurchaseLimit ~= -1 then
				buyTimesText = Localization:getInstance():getText("shop_vipPurchase", {viplevel = "VIP" .. itemInfo.needVipLevel}) 
				setTextByTag(cell, TAG_TXT_ITEM_LIMIT, buyTimesText)
				setNodeVisibleByTag(cell, TAG_BUTTON_BUY, itemServerInfo.lifeBuyTimes < itemInfo.lifePurchaseLimit)
				setNodeVisibleByTag(cell, TAG_BUTTON_BUY_INACTIVE, not (itemServerInfo.lifeBuyTimes < itemInfo.lifePurchaseLimit))
			elseif itemInfo.dailyPurchaseLimit ~= -1 then
				buyTimesText = getTextByKey("shop_dailyPurchase") .. itemServerInfo.dailyBuyTimes .. "/" .. itemInfo.dailyPurchaseLimit
				setTextByTag(cell, TAG_TXT_ITEM_LIMIT, buyTimesText)
				setNodeVisibleByTag(cell, TAG_BUTTON_BUY, itemServerInfo.dailyBuyTimes < itemInfo.dailyPurchaseLimit)
				setNodeVisibleByTag(cell, TAG_BUTTON_BUY_INACTIVE, not (itemServerInfo.dailyBuyTimes < itemInfo.dailyPurchaseLimit))
			elseif itemInfo.loopLimitTime ~= -1 then

				local remainedSec = VipManager.getNextRefreshTime(itemInfo.id) - TimeUtil.getServerTimeSeconds()
				local aTime = {hh = 0, mm = 0, ss = 0}
				  aTime.ss = math.mod(remainedSec,60) 
				  remainedSec = math.modf(remainedSec/60)
				  aTime.mm = math.mod(remainedSec,60)
				  remainedSec = math.modf(remainedSec/60)
				  aTime.hh = remainedSec
				local day = math.modf(aTime.hh / 24)

				local formatedTimeStr = ""
				if day ~= 0 then
					formatedTimeStr = getTextByKey("loopLimitTime01",{day = day , hour = aTime.hh - day * 24})
				else
					if (aTime.hh - day * 24) ~= 0 then
						formatedTimeStr = getTextByKey("loopLimitTime02",{hour = aTime.hh - day * 24 , min = aTime.mm})
					else
						formatedTimeStr = getTextByKey("loopLimitTime03",{min = aTime.mm, sec = aTime.ss})
					end
				end
				local buyTimes = VipManager.getRedPacketBuyTimes(itemInfo.id)
				buyTimesText = getTextByKey("redBag015")..buyTimes .. "/" .. itemInfo.loopLimit .. formatedTimeStr
				setTextByTag(cell, TAG_TXT_ITEM_LIMIT, buyTimesText)
				setNodeVisibleByTag(cell, TAG_BUTTON_BUY, buyTimes < itemInfo.loopLimit)
				setNodeVisibleByTag(cell, TAG_BUTTON_BUY_INACTIVE, not (buyTimes < itemInfo.loopLimit))
			end
			
			setNodeVisibleByTag(cell, TAG_ICON_DELETELINE, itemInfo.discountPrice ~= itemInfo.price)
			setNodeVisibleByTag(cell, TAG_TXT_ITEM_NEWPRICE, itemInfo.discountPrice ~= itemInfo.price)
			setTextByTag(cell, TAG_TXT_SELLPRICE, itemInfo.price)
			setTextByTag(cell, TAG_TXT_ITEM_NEWPRICE, itemInfo.discountPrice)
			
			for quality = 1, 7
			do
				setNodeVisibleByTag(cell, TAG_ICON_WHITE + quality - 1, quality == itemMeta.quality)
			end
		end
		
		if tabIndex == TABLEVIEW_TAB_INDEX.GOLD_SHOP then
			local itemInfo = data[index + 1]
			local itemMeta = MetaManager.prop_meta[itemInfo.metaId]
			
			setGeneralData(itemInfo, itemMeta)
			
		elseif tabIndex == TABLEVIEW_TAB_INDEX.VIP_SHOP then
			local itemInfo = data[index + 1]
			local itemMeta = MetaManager.prop_meta[itemInfo.metaId]
			
			setGeneralData(itemInfo, itemMeta)
			
			if not itemInfo.vipLevelEnable then
				setNodeVisibleByTag(cell, TAG_BUTTON_BUY, false)
				setNodeVisibleByTag(cell, TAG_BUTTON_BUY_INACTIVE, true)
			end
			
			if cell:getChildByTag(TAG_ICON_VIP_NUM) then
				cell:removeChildByTag(TAG_ICON_VIP_NUM, true)
			end
			
			local vipPosX, vipPosY = cell:getChildByTag(TAG_ICON_VIP):getPosition()
			local vipContentSize = cell:getChildByTag(TAG_ICON_VIP):getContentSize()
			
			local numberLabel = CCLabelAtlas:create(tostring(itemInfo.needVipLevel), "pic/number_vip.png", 22, 41, 48)
			numberLabel:setScale(1.25)
			numberLabel:setAnchorPoint(ccp(0, 0.5))
			numberLabel:setTag(TAG_ICON_VIP_NUM)
			numberLabel:setPosition(ccp(vipPosX + vipContentSize.width, vipPosY - vipContentSize.height /2))
			local zOrder = cell:getChildByTag(TAG_ICON_VIP):getZOrder()
			cell:addChild(numberLabel, zOrder)
			
		elseif tabIndex == TABLEVIEW_TAB_INDEX.CHARGE or tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE then
			local itemInfo = data[index + 1]
			
			cell:removeChildByTag(TAG_PAYCHANNEL_PIC,true)
			
			if itemInfo.id == "gash_pay" or itemInfo.id == "mycard_pay" then
				setNodeVisibleByTag(cell, TAG_ICON_CHARGE, false)
				setNodeVisibleByTag(cell, TAG_ICON_CHARGE_BOX, false)
				setNodeVisibleByTag(cell, TAG_ICON_HOTSELL, false)
				setNodeVisibleByTag(cell, TAG_TXT_EXTRA_CHARGE_PRICE, false)
				setNodeVisibleByTag(cell, TAG_TXT_CHARGE_PRICE, false)
				setNodeVisibleByTag(cell, TAG_TXT_NEW_CHARGE_PRICE, false)
				setNodeVisibleByTag(cell, TAG_ICON_DOUBLE, false)
				setTextByTag(cell, TAG_BUTTON_CHARGE, itemInfo.priceText)
				setNodeVisibleByTag(cell, TAG_TXT_RECGARGE_BONUS, false)
				
				local pic = nil
				if itemInfo.id == "gash_pay" then
					pic = CCSprite:create("pic/activityIcons/icon_Gash.png")
				elseif itemInfo.id == "mycard_pay" then
					pic = CCSprite:create("pic/activityIcons/icon_mycard.png")
				end
				if pic and cell:getChildByTag(TAG_PAYCHANNEL_PIC) == nil then
					pic:setAnchorPoint(ccp(0, 0))
					if itemInfo.id == "gash_pay" then
					    pic:setPosition(ccp(7,-121 ))
				    elseif itemInfo.id == "mycard_pay" then
					    pic:setPosition(ccp(5,-126 ))
				    end
					pic:setZOrder(3)
					pic:setTag(TAG_PAYCHANNEL_PIC)
					cell:addChild(pic)
					setTextByTag(cell, TAG_BUTTON_CHARGE, itemInfo.priceText)
				end
			else
				setNodeVisibleByTag(cell, TAG_ICON_CHARGE, not itemInfo.isHot)
				setNodeVisibleByTag(cell, TAG_ICON_CHARGE_BOX, itemInfo.isHot)
				setNodeVisibleByTag(cell, TAG_ICON_HOTSELL, (itemInfo.isHot and not isChargeDouble() ))
				setNodeVisibleByTag(cell, TAG_TXT_EXTRA_CHARGE_PRICE, itemInfo.extraAmount > 0)
				setNodeVisibleByTag(cell, TAG_TXT_CHARGE_PRICE, itemInfo.extraAmount > 0)
				setNodeVisibleByTag(cell, TAG_TXT_NEW_CHARGE_PRICE, itemInfo.extraAmount <= 0)
				--setNodeVisibleByTag(cell, TAG_TXT_CHARGE_CHARGE_PRICE, false)
				setNodeVisibleByTag(cell, TAG_ICON_DOUBLE, isChargeDouble())
				setTextByTag(cell, TAG_TXT_CHARGE_PRICE, tostring(itemInfo.amount))
				setTextByTag(cell, TAG_TXT_NEW_CHARGE_PRICE, tostring(itemInfo.amount))
				setTextByTag(cell, TAG_TXT_EXTRA_CHARGE_PRICE, "+" .. tostring(itemInfo.extraAmount))
				--setTextByTag(cell, TAG_TXT_CHARGE_CHARGE_PRICE, "+" .. tostring(itemInfo.chargeAmount))
				setTextByTag(cell, TAG_BUTTON_CHARGE, itemInfo.priceText)
				
				--[[if isChargeDouble() then
					setNodeVisibleByTag(cell, TAG_ICON_HOTSELL, false)
				end--]]
				
				
			end
			
			if isFirstCharge() then
				--没首充过
				setNodeVisibleByTag(cell, TAG_TXT_RECGARGE_BONUS, true)
				if itemInfo.textKey then
					setTextByTag(cell, TAG_TXT_RECGARGE_BONUS, getTextByKey(itemInfo.textKey))
				elseif index < 5 then
					setTextByTag(cell, TAG_TXT_RECGARGE_BONUS, getTextByKey("chargeMoney_bonus1"))
				else
					setTextByTag(cell, TAG_TXT_RECGARGE_BONUS, getTextByKey("chargeMoney_bonus2"))
				end
			else
				--首充过
				--add by zheng.che @ 2014-7-11 充值送话费 modify_phoneCharge
				--print("itemInfo = " .. tostringRich(itemInfo))
				if Activity_PhoneChargeLayer.isEnable() and (not Activity_PhoneChargeLayer.isTodayRecharged()) and (tonumber(itemInfo.platformCoin) >= Activity_PhoneChargeLayer.getMinPay()) then
					--此时送话费活动有效 并且今天并没有充值过 并且充值金额超过配置数值(10元 2014-7-16)
					setNodeVisibleByTag(cell, TAG_TXT_RECGARGE_BONUS, true)

					local money = tonumber(itemInfo.platformCoin)--充值金额
					local charge = Activity_PhoneChargeLayer.getChargeByMoney(money)--话费返还
					--print("charge = " .. tostringRich(charge))
					setTextByTag(cell, TAG_TXT_RECGARGE_BONUS, getTextByKey("shop_phoneCharge", {num = charge}))--返还{num}元话费
				else
					setNodeVisibleByTag(cell, TAG_TXT_RECGARGE_BONUS, false)
				end
			end

		end
	end
	
	local function inArea(posX, posY, rect)
		if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
			return true
		end
		return false
	end
	
	local function onListItemTouch( evt ) 
		local selectedCell = self.tableView[self.curTableViewIndex]:cellAtIndex(evt.data):getChildByTag(TABLEVIEW_CELL_TAG)
		local curTabIndex = evt.context
		self._data = data[evt.data + 1]
		
		local function buyGoodsSucceedResponse(evt)
			self.waitRequest = false;
			SuspensionLabel:showContent(self, getTextByKey("shop_buySuccess"))
			
			RewardManager:getReward(evt.data.reward)
			local costTable = {}
			costTable.amount = tostring(-self._data.discountPrice)
			costTable.metaId = 0
			costTable.itemType = 2
			costTable.id = 0
			RewardManager:getReward({costTable})
			
			local buyItemInfo = getItemServerInfoById(self._data.id)
			buyItemInfo.lifeBuyTimes = buyItemInfo.lifeBuyTimes + 1
			buyItemInfo.dailyBuyTimes = buyItemInfo.dailyBuyTimes + 1
			if self._data.lifePurchaseLimit ~= -1 and buyItemInfo.lifeBuyTimes >= self._data.lifePurchaseLimit then
				for k,data in pairs(self.tableData[self.curTableViewIndex]) do
					if data.id == self._data.id then
						table.remove(self.tableData[self.curTableViewIndex], k)
						break;
					end
				end
			end
			
			local exist = false;
			for k, data in pairs(lifeLimitDataTable) do
				if data.goodMetaId == self._data.id then
					data.lifePurchaseTimes = buyItemInfo.lifeBuyTimes
					exist = true
				end
			end
			
			if not exist then
				local limitDataTable = {}
				limitDataTable.goodMetaId = self._data.id
				limitDataTable.lifePurchaseTimes = buyItemInfo.lifeBuyTimes
				table.insert(lifeLimitDataTable, limitDataTable)
			end
			
			DataManager.setLifeLimitGoodsData(lifeLimitDataTable)
			
			local exist = false;
			for k, data in pairs(dailyLimitDataTable) do
				if data.goodMetaId == self._data.id then
					data.dailyPurchaseTimes = buyItemInfo.dailyBuyTimes
					exist = true
				end
			end
			
			if not exist then
				local limitDataTable = {}
				limitDataTable.goodMetaId = self._data.id
				limitDataTable.dailyPurchaseTimes = buyItemInfo.dailyBuyTimes
				table.insert(dailyLimitDataTable, limitDataTable)
			end
			
			DailyDataManager.setDailyLimitGoodsData(dailyLimitDataTable)

			if self._data.loopLimitTime ~= -1 then
				VipManager.addItemNum(self._data.id)
			end
			
			for k,data in pairs(self.tableData[self.curTableViewIndex]) do
				if data.metaId == self._data.metaId then
					data.ownAmount = data.ownAmount + self._data.amount
				end
			end
			self:sortTableData(TABLEVIEW_TAB_INDEX.VIP_SHOP)
			self:refreshTable(true, self.curTableViewIndex)
		end
		
		local function buyGoodsFailedResponse(evt)
			self.waitRequest = false
			if evt.data == 710513 then --gold not enough
				local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
				self:addChild(aPanel)
				aPanel:scaleIn()
			elseif evt.data == 713001 then --daily purchase limit
				local aContent = Localization:getInstance():getText("shop_limitReached")
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = CanonMessageBox:Show(aContent, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
			elseif evt.data == 713002 then --life purchase limit
				local aContent = Localization:getInstance():getText("shop_limitReached")
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = CanonMessageBox:Show(aContent, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
			elseif evt.data == 712906 then --vip level not enough
				local aContent = Localization:getInstance():getText("shop_vipLevelInsufficient")
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = CanonMessageBox:Show(aContent, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
			elseif evt.data == 710516 then --package full
				local aContent = Localization:getInstance():getText("shop_inventoryFull")
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = NewPackageFullPanel:show()
			else
				CanonMessageBox:showCommUnHandleErrorBox(evt.data)
			end
		end
		
		local function sendBuyGoodsReuqest()
			if CalculationManager.calcComplex_getGemsNow() < self._data.discountPrice then
				local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
				self:addChild(aPanel)
				aPanel:scaleIn()
				do return end
			end
							
			local usedGridNum = BagCalcManager.calcUsedGridNum()
			local totalGridNum = BagCalcManager.calcTotalGridNum()
			if (usedGridNum == totalGridNum and self._data.ownAmount > 0) or usedGridNum > totalGridNum then
				local aContent = Localization:getInstance():getText("shop_inventoryFull")
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = NewPackageFullPanel:show()
				do return end
			end
							
			if self.waitRequest then
				do return end
			end
							
			self.waitRequest = true;
			local request = BuyGoodsRequest.new( {goodsId = self._data.id}, rpc.SendingPriority.kHigh )
			request:addEventListener( RequestNotifyEnum.BuyGoodsSucceed, buyGoodsSucceedResponse )
			request:addEventListener( RequestNotifyEnum.BuyGoodsFailed, buyGoodsFailedResponse )
			request:start()
		end
		
		if tabIndex == TABLEVIEW_TAB_INDEX.GOLD_SHOP then
			local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
			local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_BUTTON_BUY):getPosition()
			local itemRect = {}
			itemRect.x = itemPosX
			itemRect.y = itemPosY - 66
			itemRect.width = 168
			itemRect.height = 66
			if inArea(posInCell.x, posInCell.y, itemRect) then
				if selectedCell:getChildByTag(TAG_BUTTON_BUY) then
					if selectedCell:getChildByTag(TAG_BUTTON_BUY):isVisible() then
						sendBuyGoodsReuqest()
					end
				end
				do return end
			else
				self.targetInfoPanel = PropInfoPanel:create( self , true)
				PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self) 
			end
		elseif tabIndex == TABLEVIEW_TAB_INDEX.VIP_SHOP then
			local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
			local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_BUTTON_BUY):getPosition()
			local itemRect = {}
			itemRect.x = itemPosX
			itemRect.y = itemPosY - 66
			itemRect.width = 168
			itemRect.height = 66
			if inArea(posInCell.x, posInCell.y, itemRect) then
				if selectedCell:getChildByTag(TAG_BUTTON_BUY) then
					if selectedCell:getChildByTag(TAG_BUTTON_BUY):isVisible() then
						sendBuyGoodsReuqest()
					end
				end
				do return end
			else
				if isDataVipTreasureBox(self._data) then
					local boxDatas = ShopScene.getVipTreasureBoxDatas(self._data)
					self.targetInfoPanel = VipTreasureBoxPanel:create(self, boxDatas)
					PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
				else
					self.targetInfoPanel = PropInfoPanel:create( self , true)
					PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self) 
				end
				
			end
		elseif tabIndex == TABLEVIEW_TAB_INDEX.CHARGE or tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE then
			local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
			
			if posInCell.x < 0 then
				do return end
			end
			
			local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_BUTTON_CHARGE):getPosition()
			local itemRect = {}
			itemRect.x = itemPosX
			itemRect.y = itemPosY - 66
			itemRect.width = 168
			itemRect.height = 66
			if inArea(posInCell.x, posInCell.y, itemRect) then
				local beforeChargeLevel = getCurVipInfo().level
				local function chargeSucceed(evt)
			   
					local paymentInfo 
                    if tabIndex == TABLEVIEW_TAB_INDEX.CHARGE then
                        paymentInfo = getChargeInfos()
                    elseif tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE then
                        paymentInfo = getShortChargeInfos()
                    end
					for k,v in pairs(paymentInfo) do
						if v.id == evt.data.productId then
							self._data = v;
							break;
						end
					end
					self.waitRequest = false;
					
					local chargeAmount = 0
					local getAmount = 0
					he_log_info("++++++++++++self._data.id = " .. self._data.id)
					if self._data.id == "gash_pay" or self._data.id == "mycard_pay" then
						if evt.data.freeGems then
							self._data.extraAmount = evt.data.freeGems
                            he_log_info("++++++++++++freeGems = " .. evt.data.freeGems)
						else
							self._data.extraAmount = 0
                            he_log_info("++++++++++++freeGems = nil")
						end
						
						if evt.data.rechargeGems then
							self._data.amount = evt.data.rechargeGems
                            he_log_info("++++++++++++rechargeGems = " .. evt.data.rechargeGems)
						else
							self._data.amount = 0
                            he_log_info("++++++++++++rechargeGems = nil")
						end
						
						self._data.extraAmount = 0
						self._data.chargeAmount = self._data.amount
						
					end
					
					chargeAmount = self._data.amount
					  if MaintenanceManager.isActivityOpen("activityNewyeatCalcPay") and (not MaintenanceManager.isActivityAlreadyClose("activityNewyeatCalcPay")) then
						local gameInitData = DataManager.getGameInitData()
						if type(gameInitData.sharkActivity) == "table" then
						  gameInitData.sharkActivity.nyChagrgedGems = gameInitData.sharkActivity.nyChagrgedGems + chargeAmount
						end
						DataManager.setGameInitData(gameInitData)
					  end
					  local aActivityNewYearConfig = DataManager.GameMetaData.activityNewYearConfig
					  if aActivityNewYearConfig then
						if MaintenanceManager.isActivityOpen(aActivityNewYearConfig.featureNameCalcPay) and (not MaintenanceManager.isActivityAlreadyClose(aActivityNewYearConfig.featureNameCalcPay)) then
						  local sharkActivity = DataManager.getSharkActivity()
						  sharkActivity.chargeInfo = sharkActivity.chargeInfo or {}
						  if (not sharkActivity.chargeInfo.currVersion) or (sharkActivity.chargeInfo.currVersion ~= aActivityNewYearConfig.version) then
							sharkActivity.chargeInfo.currVersion = aActivityNewYearConfig.version
							sharkActivity.chargeInfo.gems = 0
							sharkActivity.chargeInfo.gainedRewardIds = {}
						  end
						  sharkActivity.chargeInfo.gems = sharkActivity.chargeInfo.gems + chargeAmount
						  DataManager.setSharkActivity(sharkActivity)
						end
					  end
          
					getAmount = self._data.extraAmount
					if isChargeDouble() then
						if self._data.chargeAmount > 20000 then
							getAmount = getAmount + 20000
						else
							getAmount = getAmount + self._data.chargeAmount

						end
					end
					
					local curUserInfo = DataManager.getCurrUser()
					curUserInfo.rechargeGems = curUserInfo.rechargeGems + chargeAmount
					while not isCurVipMaxLevel(curUserInfo.vipLevel) and curUserInfo.rechargeGems + curUserInfo.vipExp >= MetaManager.vip_setting[curUserInfo.vipLevel + 1].requireGold do
						curUserInfo.vipLevel = curUserInfo.vipLevel + 1
					end
					DataManager.setCurrUser(curUserInfo)			

					local costTable = {}
					costTable.amount = tostring(getAmount)
					costTable.metaId = 0
					costTable.itemType = 2
					costTable.id = 0
					RewardManager:getReward({costTable})					
					
					self:resetVipProgress(self.curTableViewIndex)
					
					if self.tableView[TABLEVIEW_TAB_INDEX.VIP_SHOP] then
						self:getTableData(TABLEVIEW_TAB_INDEX.VIP_SHOP)
						self:refreshTable(false, TABLEVIEW_TAB_INDEX.VIP_SHOP)
					end

					-- if self.tableView[TABLEVIEW_TAB_INDEX.CHARGE] then
					--    self.tableView[TABLEVIEW_TAB_INDEX.CHARGE]:reloadData()
					-- elseif self.tableView[TABLEVIEW_TAB_INDEX.SHORT_CHARGE] then
					--    self.tableView[TABLEVIEW_TAB_INDEX.SHORT_CHARGE]:reloadData()
					-- end

					local vipInfo = getCurVipInfo()
					vipInfo.isMaxLevel = isCurVipMaxLevel(vipInfo.level)
					vipInfo.isLevelup = (beforeChargeLevel < vipInfo.level)
					vipInfo.chargeAmount = chargeAmount
					self.targetInfoPanel = VipChargeSuccessPanel:create(self, vipInfo)
					self.vipWarningPanel = self.targetInfoPanel

					if Activity_ChargeRewardLayer.getEnableChargeLevel() > Activity_ChargeRewardLayer.getCurrentChargeLevel() then
						self.targetInfoPanel = ChargeRewardWarningPanel:create(self)
						-- PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
					else
						-- local vipInfo = getCurVipInfo()
						-- vipInfo.isMaxLevel = isCurVipMaxLevel(vipInfo.level)
						-- vipInfo.isLevelup = (beforeChargeLevel < vipInfo.level)
						-- vipInfo.chargeAmount = chargeAmount
						-- self.targetInfoPanel = VipChargeSuccessPanel:create(self, vipInfo)
						-- PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
					end
					if isChargeDouble() then
						SetChargeDoubleVersion()
					end

					PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
					if tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE then
						self:refreshTable(true, TABLEVIEW_TAB_INDEX.SHORT_CHARGE)
					else
						self:refreshTable(true, TABLEVIEW_TAB_INDEX.CHARGE)
					end
					--add by zheng.che @ 2014-7-11 充值送话费 modify_phoneCharge
					if Activity_PhoneChargeLayer.isEnable() and (not Activity_PhoneChargeLayer.isTodayRecharged()) and (tonumber(self._data.platformCoin) >= Activity_PhoneChargeLayer.getMinPay()) then
						--充值成功时 送话费活动有效 并且今天并没有充值过 并且充值金额超过配置额度(10元 2014-7-16)

						--增加剩余话费金额
						local money = tonumber(self._data.platformCoin)--充值金额
						local charge = Activity_PhoneChargeLayer.getChargeByMoney(money)--话费返还
						Activity_PhoneChargeLayer.setPhoneMoneyLeft(Activity_PhoneChargeLayer.getPhoneMoneyLeft() + charge)

						--提示玩家领取话费
						Activity_PhoneChargeLayer.tellUserGainPhoneMoney()
			            --设置为今日已充值
			            Activity_PhoneChargeLayer.setTodayRechargedState(true)
				    end
					    --限时充值当前时间段冲的钱
					    Activity_rechargeLayer.ResetRechargeData(chargeAmount)
					    
						    
				end
				
				local function chargeFailed(evt)
					self.waitRequest = false
					if type(evt) == "table" then
	                    if evt.data == 716152 then
	                        CanonMessageBox:Show(getTextByKey("chargeWaitingForRespond"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, nil, nil)
	                    elseif type(evt.data) == "number" then
	                        CanonMessageBox:showCommUnHandleErrorBox(evt.data)
	                    end
	                elseif type(evt) == "number" then
	                	if evt == valid_locale_error_code then
	                		CanonMessageBox:Show(getTextByKey("coin_nonsupport"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, nil, nil)
	                	end
	                end
				end
				
				local function sendChargeRequest()
					if isGoldTooMuch() then
						local function closeCanonMessageBox()
						end
						self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("shop_charge_overLimit"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
						do return end
					end
					
					if self.waitRequest then
						do return end
					end
					
                    --
                    if (__ANDROID and not CanonEnvInjector:isNetworkAvailable()) or (__IOS and Reachability:reachabilityForInternetConnection():currentReachabilityStatus() == 0) then
                        CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("popup_networkError"),
                                        nil,
                                        {
                                            text = getTextByKey("yes"),
                                            callbackFunc = function()
                                                
                                            end
                                        }
                                    )

                        return
                    end
                    --
					self.waitRequest = true;
                    
                    local function payCallBackFunc(isSuccess,detailInfo)
                        if isSuccess then
                            chargeSucceed(detailInfo)
                        else
                            chargeFailed(detailInfo)
                        end
                    end
                    if __ANDROID then
                        if not isGetGoodsListSucc() and isGooglePlayTW() then
                            --用户不能通过googleplay支付，获取支付列表失败
                            CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("payGooglePlayAddRemind"),
                                        nil,
                                        {
                                            text = getTextByKey("yes"),
                                            callbackFunc = function()
                                                self.waitRequest = false
                                            end
                                        }
                                    )
                            return
                        end 
                        if tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE then
                            if isYidongPayOpen() then
                                he_log_info("++++++++++++yidong pay")
                                GspBridge.pay(self._data,payCallBackFunc,nil,"shortMessageMMPay")
                            elseif isLiantongPayOpen() then
                                he_log_info("++++++++++++liantong pay")
                            elseif isDianxinPayOpen() then
                                he_log_info("++++++++++++dianxin pay")
                            else
                                CanonMessageBox.showText(
                                    ShowButtonType.ID_OK,
                                    "don't support short message pay",
                                    nil,
                                    {
                                        text = "ok",
                                        callbackFunc = function()
                                        end
                                    }
                                )
                                self.waitRequest = false
                                return
                            end
                        else
                            GspBridge.pay(self._data,payCallBackFunc)
                        end
                    elseif isPlatformIos() or isI4ios() or isHaimaIos() or isKuaiYongIos() or isTongbuIos() then
                    	IosPlatformPay(self._data, payCallBackFunc)
                    else
                        CanonMessageBox.showText(
                            ShowButtonType.ID_OK,
                            "This channel has no real pay",
                            nil,
                            {
                                text = "ok",
                                callbackFunc = function()
                                end
                            }
                        )
                        self.waitRequest = false
                        return

                    end
                    
					
				end
				--self._data
				sendChargeRequest()
			end
		end
	end
	
  local buttonTag = {}
	local tableViewWidth = TABLEVIEW_WIDTH
	local tableViewHeight = TABLEVIEW_HEIGHT
	local cellWidth = CELL_WIDTH
	local cellHeight = CELL_HEIGHT
	local tableViewPosX = TABLEVIEW_POS_X
	if tabIndex == TABLEVIEW_TAB_INDEX.GOLD_SHOP then
		table.insert(buttonTag, TAG_BUTTON_BUY)
	elseif tabIndex == TABLEVIEW_TAB_INDEX.VIP_SHOP then
		table.insert(buttonTag, TAG_BUTTON_BUY)
		tableViewHeight = TABLEVIEW_HEIGHT - 110
	elseif tabIndex == TABLEVIEW_TAB_INDEX.CHARGE or tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE then
		tableViewHeight = TABLEVIEW_HEIGHT - 110
		cellHeight = 125
		tableViewPosX = tableViewPosX + CHARGE_OFFSETX
		cellWidth = cellWidth - CHARGE_OFFSETX
		tableViewWidth = tableViewWidth - CHARGE_OFFSETX
		--tableViewHeight = TABLEVIEW_HEIGHT - 125
		--cellHeight = 119
		table.insert(buttonTag, TAG_BUTTON_CHARGE)
	end
	
  local renderer = ShopSceneRenderer.new(cellWidth, cellHeight)
  local list = TableView:create(renderer, tableViewWidth, tableViewHeight, TABLEVIEW_CELL_TAG, buttonTag)

	if tabIndex == TABLEVIEW_TAB_INDEX.CHARGE or tabIndex == TABLEVIEW_TAB_INDEX.SHORT_CHARGE then
		list:setBounceable(false)
	end
	
  list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , tabIndex)
  list:setPosition(ccp(tableViewPosX, TABLEVIEW_POS_Y))
  return list
end

function ShopScene:dispose()
	self.vipPrivilegePanel.toRetain = false
	self.vipPrivilegePanel:dispose()
	BaseUIScene.dispose(self)

	if self.cdComponents then
		for k,v in pairs(self.cdComponents) do
			v:stop()
		end
	end
end

function ShopScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function ShopScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function ShopScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
	ViewControlUtil.showTableViewAction(self.tableView[self.curTableViewIndex], visibleSize)
end

function ShopScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function ShopScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function ShopScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function ShopScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
      self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
  
	ViewControlUtil.disappearTableViewAction(self.tableView[self.curTableViewIndex], visibleSize)
	
end

function ShopScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function ShopScene:back()
	if self.argv.returnScene == "ActivityPanelScene" then
		self:replaceScene(ActivityPanelScene, {selectPanelName = self.argv.selectPanelName or "Activity_ChargeReward"})
	elseif self.argv.returnScene == "BackpackSceneItem" then
		self:replaceScene(BackpackScene, {params = {tabIndex = BAGCATEGORY.item}})
	elseif self.argv.returnScene == "Activity_TreasureboxRankLayer" then
		self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_Treasurebox"})
	elseif self.argv.returnScene == "PKScene" then
		self:replaceScene(PKScene)
	elseif self.argv.returnScene == "Activity_PhoneCharge" then
		self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_PhoneCharge", enterScene = "ShopScene"})
	elseif self.argv.returnScene == "DailyTargetScene" then
		DailyTargetScene.gotoDailyTargetScene()
	else
		self:replaceScene(MainMenuScene)
	end
end

function ShopScene:setTableViewsEnabled( v )
	if (v) then
		self.touchDisableSetTimes = self.touchDisableSetTimes - 1
		if (self.touchDisableSetTimes <= 0) then
			if self.tableView[self.curTableViewIndex] then
				self.tableView[self.curTableViewIndex]:setTouchEnabled(v)
			end
			self.mainUI:setTouchEnabled(v)
		end
	else
		self.touchDisableSetTimes = self.touchDisableSetTimes + 1
		if self.tableView[self.curTableViewIndex] then
			self.tableView[self.curTableViewIndex]:setTouchEnabled(v)
		end
		self.mainUI:setTouchEnabled(v)
	end
end

function isGashPayOpen()
	if isTWHE() then
		return true 
	end
	local isOpen = false
	if MaintenanceManager.isActivityOpen("gashValue") then
		local gameInitData = DataManager.getGameInitData()
		if gameInitData.sharkUserExtend and gameInitData.sharkUserExtend.paidChannelNames then
			for k,v in pairs(gameInitData.sharkUserExtend.paidChannelNames) do
				if string.find(v,"gash") or string.find(v,"mycard") then
					isOpen = true
					break
				end
			end
		end
	end
	return isOpen
end

function isMycardPayOpen()
	do 
		return false
	end
	
	if isTWHE() then
		return true 
	end
	local isOpen = false
	if MaintenanceManager.isActivityOpen("mycardValue") then
		local gameInitData = DataManager.getGameInitData()
		if gameInitData.sharkUserExtend and gameInitData.sharkUserExtend.paidChannelNames then
			for k,v in pairs(gameInitData.sharkUserExtend.paidChannelNames) do
				if string.find(v,"gash") or string.find(v,"mycard") then
					isOpen = true
					break
				end
			end
		end
	end
	return isOpen
end

function isShortPayItem(itemId)
    return string.find(itemId,"YIDONG") or string.find(itemId,"LIANTONG") or string.find(itemId,"DIANXIN") 
end

function ShopScene.informPaymentUnavailable()
	CanonMessageBox:Show("亲爱的玩家，由于目前南非货币汇率极不稳定。为保护您的利益，我们暂不支持此货币支付，请改用其他货币支付方式。", ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, nil, nil)	
end