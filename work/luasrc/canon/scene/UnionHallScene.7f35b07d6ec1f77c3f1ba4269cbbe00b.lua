require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.panel.UnionBankPreviewPanel"
require "canon.request.ReceiveUnionWageRequest"
require "canon.request.UnionConstructUnionRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local enter_animation_duration = 0.3

--
-- UnionHallScene
--

UnionHallScene = class(BaseUIScene)

function UnionHallScene:ctor()
	
end

function UnionHallScene:create(argv)
  local s = UnionHallScene.new()
  if argv then 
      self.argv = argv 
	  self.hallData = argv.params.data
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  s.curSceneEnum = SceneEnum.UnionHallScene
  s:initScene()
  return s
end

function UnionHallScene:onInit()
	BaseUIScene.initBackGround(self)
  
  self.title = Localization:getInstance():getText("arena_title")
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
  
  local ui = builder:build("guild_hall")
  self:addChild(ui)
  self.ui = ui
  self:addChild(ui)
  
  local titleUI = builder:build("guild_hall_title")
  self:addChild(titleUI)
  self.titleUI = titleUI
  self:addChild(titleUI)
  
	local offset_y = 1075
	self.itemTable = {}
	for i=1,10 do
		local weathItem = builder:build("txt/txt_guild_hall_combine")
		weathItem:setPosition( ccp(365, offset_y - (i*36) ))
		self.ui:addChild(weathItem)
		self.itemTable[i] = weathItem
	end

	local leftLabel
	local rightLabel
	local aNewPosX
	
	--普通建设UI显示
	local border = self.ui:getChildByName("list_guild_hall"):getChildByName("normal_card_small")
	local posX = border:getPositionX() + border:getContentSize().width/2 + 10
	local posY = border:getPositionY() - border:getContentSize().height/2 - 10
	self.ui:getChildByName("list_guild_hall"):removeChild(border, false)
	local coinIcon = Sprite:create("common/CoinIcon_Mission.png")
	coinIcon:setPosition(ccp(posX, posY))
	coinIcon:setScale(1.1)
	self.ui:getChildByName("list_guild_hall"):addChild(coinIcon)
	self.ui:getChildByName("list_guild_hall"):addChild(border)
	
	self.ui:getChildByName("list_guild_hall"):getChildByName("txt_guild_37"):getChildByName("txt"):setString(getTextByKey("union_build_gem_text"))
	local costCoin = UnionManager.getBuildCostNum(UnionManager.BUILD_LEVEL1)
	local costCoinStr = getTextByKey("union_build_gem_cost_text", {num = costCoin})
	self.ui:getChildByName("list_guild_hall"):getChildByName("txt_guild_38"):getChildByName("txt"):setString(costCoinStr)
	
	leftLabel = self.ui:getChildByName("list_guild_hall"):getChildByName("txt_guild_29")
	rightLabel = self.ui:getChildByName("list_guild_hall"):getChildByName("txt_guild11")
	leftLabel:getChildByName("txt"):setDimensions(CCSizeMake(0, leftLabel:getChildByName("txt"):getContentSize().height))
	self.ui:getChildByName("list_guild_hall"):getChildByName("txt_guild_hall_sub2"):getChildByName("txt"):setString(getTextByKey("union_build_add_text"))
	self.ui:getChildByName("list_guild_hall"):getChildByName("txt_guild_29"):getChildByName("txt"):setString(""..UnionManager.getBuildWealthNum(UnionManager.BUILD_LEVEL1))
	self.ui:getChildByName("list_guild_hall"):getChildByName("txt_guild11"):getChildByName("txt"):setString(getTextByKey("union_add_wealth_own_text1"))
	--动态文本缩进
	aNewPosX = leftLabel:getPosition().x + leftLabel:getChildByName("txt"):getContentSize().width
	rightLabel:setPositionX(aNewPosX)
	
	leftLabel = self.ui:getChildByName("list_guild_hall"):getChildByName("txt_guild_29_1")
	rightLabel = self.ui:getChildByName("list_guild_hall"):getChildByName("txt_guild11_2")
	leftLabel:getChildByName("txt"):setDimensions(CCSizeMake(0, leftLabel:getChildByName("txt"):getContentSize().height))
	self.ui:getChildByName("list_guild_hall"):getChildByName("txt_guild_hall_sub3"):getChildByName("txt"):setString(getTextByKey("union_build_add_text"))
	self.ui:getChildByName("list_guild_hall"):getChildByName("txt_guild_29_1"):getChildByName("txt"):setString(""..UnionManager.getBuildContributeNum(UnionManager.BUILD_LEVEL1))
	self.ui:getChildByName("list_guild_hall"):getChildByName("txt_guild11_2"):getChildByName("txt"):setString(getTextByKey("union_add_player_contribute_text1"))
	--动态文本缩进
	aNewPosX = leftLabel:getPosition().x + leftLabel:getChildByName("txt"):getContentSize().width
	rightLabel:setPositionX(aNewPosX)
	
	self.ui:getChildByName("list_guild_hall"):getChildByName("btn_slivercreate"):getChildByName("txt"):setString(getTextByKey("union_build_gem_text"))
	
	
	
	--高级建设UI显示
	local border = self.ui:getChildByName("list_guild_hall_2"):getChildByName("normal_card_small")
	local posX = border:getPositionX() + border:getContentSize().width/2 + 10
	local posY = border:getPositionY() - border:getContentSize().height/2 - 10
	self.ui:getChildByName("list_guild_hall_2"):removeChild(border, false)
	local coinIcon = Sprite:create("common/GemIcon_Mission.png")
	coinIcon:setPosition(ccp(posX, posY))
	coinIcon:setScale(1.1)
	self.ui:getChildByName("list_guild_hall_2"):addChild(coinIcon)
	self.ui:getChildByName("list_guild_hall_2"):addChild(border)
	
	self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild_37_g"):getChildByName("txt"):setString(getTextByKey("union_build_gold1_text"))
	self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild_hall_sub4"):getChildByName("txt"):setString(getTextByKey("activityNian_battle_costTxt1"))
	local costCoin = UnionManager.getBuildCostNum(UnionManager.BUILD_LEVEL2)
	local costCoinStr = tostring(costCoin) .. getTextByKey("resource_goldCoin")
	self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild_gold"):getChildByName("txt"):setString(costCoinStr)
	
	leftLabel = self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild_29")
	rightLabel = self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild11")
	leftLabel:getChildByName("txt"):setDimensions(CCSizeMake(0, leftLabel:getChildByName("txt"):getContentSize().height))
	self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild_hall_sub2"):getChildByName("txt"):setString(getTextByKey("union_build_add_text"))
	self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild_29"):getChildByName("txt"):setString(""..UnionManager.getBuildWealthNum(UnionManager.BUILD_LEVEL2))
	self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild11"):getChildByName("txt"):setString(getTextByKey("union_add_wealth_own_text1"))
	--动态文本缩进
	aNewPosX = leftLabel:getPosition().x + leftLabel:getChildByName("txt"):getContentSize().width
	rightLabel:setPositionX(aNewPosX)
	
	leftLabel = self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild_29_1")
	rightLabel = self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild11_2")
	leftLabel:getChildByName("txt"):setDimensions(CCSizeMake(0, leftLabel:getChildByName("txt"):getContentSize().height))
	self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild_hall_sub3"):getChildByName("txt"):setString(getTextByKey("union_build_add_text"))
	self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild_29_1"):getChildByName("txt"):setString(""..UnionManager.getBuildContributeNum(UnionManager.BUILD_LEVEL2))
	self.ui:getChildByName("list_guild_hall_2"):getChildByName("txt_guild11_2"):getChildByName("txt"):setString(getTextByKey("union_add_player_contribute_text1"))
	--动态文本缩进
	-- print("leftLabel:getChildByName(txt):getContentSize().width = " .. leftLabel:getChildByName("txt"):getContentSize().width)
	aNewPosX = leftLabel:getPosition().x + leftLabel:getChildByName("txt"):getContentSize().width
	rightLabel:setPositionX(aNewPosX)
	
	self.ui:getChildByName("list_guild_hall_2"):getChildByName("btn_slivercreate"):getChildByName("txt"):setString(getTextByKey("union_build_gold1_text"))
	
	
	
	--至尊建设UI显示
	local border = self.ui:getChildByName("list_guild_hall_3"):getChildByName("normal_card_small")
	local posX = border:getPositionX() + border:getContentSize().width/2 + 10
	local posY = border:getPositionY() - border:getContentSize().height/2 - 10
	self.ui:getChildByName("list_guild_hall_3"):removeChild(border, false)
	local coinIcon = Sprite:create("common/icon_many_gold.png")
	coinIcon:setPosition(ccp(posX, posY))
	coinIcon:setScale(1.1)
	self.ui:getChildByName("list_guild_hall_3"):addChild(coinIcon)
	self.ui:getChildByName("list_guild_hall_3"):addChild(border)
	
	leftLabel = self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild_29")
	rightLabel = self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild11")
	leftLabel:getChildByName("txt"):setDimensions(CCSizeMake(0, leftLabel:getChildByName("txt"):getContentSize().height))
	self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild_37_g"):getChildByName("txt"):setString(getTextByKey("union_build_gold2_text"))--至尊建设
	self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild_hall_sub4"):getChildByName("txt"):setString(getTextByKey("activityNian_battle_costTxt1"))
	local costCoin = UnionManager.getBuildCostNum(UnionManager.BUILD_LEVEL3)
	local costCoinStr = tostring(costCoin) .. getTextByKey("resource_goldCoin")
	self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild_gold"):getChildByName("txt"):setString(costCoinStr)
	
	self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild_hall_sub2"):getChildByName("txt"):setString(getTextByKey("union_build_add_text"))
	self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild_29"):getChildByName("txt"):setString(""..UnionManager.getBuildWealthNum(UnionManager.BUILD_LEVEL3))
	self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild11"):getChildByName("txt"):setString(getTextByKey("union_add_wealth_own_text1"))
	--动态文本缩进
	aNewPosX = leftLabel:getPosition().x + leftLabel:getChildByName("txt"):getContentSize().width
	rightLabel:setPositionX(aNewPosX)

	-- self.ttfLabel = TextField:create("Example", aExampleFontName, aExampleFontSize, CCSizeMake(aExampleWidth, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
 --  local aBaseHeight = self.ttfLabel:getTexture():getContentSize().height

	
	leftLabel = self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild_29_1")
	rightLabel = self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild11_2")
	leftLabel:getChildByName("txt"):setDimensions(CCSizeMake(0, leftLabel:getChildByName("txt"):getContentSize().height))
	self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild_hall_sub3"):getChildByName("txt"):setString(getTextByKey("union_build_add_text"))
	self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild_29_1"):getChildByName("txt"):setString(""..UnionManager.getBuildContributeNum(UnionManager.BUILD_LEVEL3))
	self.ui:getChildByName("list_guild_hall_3"):getChildByName("txt_guild11_2"):getChildByName("txt"):setString(getTextByKey("union_add_player_contribute_text1"))
	--动态文本缩进
	-- print("leftLabel:getChildByName(txt):getContentSize().width = " .. leftLabel:getChildByName("txt"):getContentSize().width)
	aNewPosX = leftLabel:getPosition().x + leftLabel:getChildByName("txt"):getContentSize().width
	rightLabel:setPositionX(aNewPosX)
	
	self.ui:getChildByName("list_guild_hall_3"):getChildByName("btn_slivercreate"):getChildByName("txt"):setString(getTextByKey("union_build_gold2_text"))--至尊建设
	
	
  local function backButtonSelected(evt)
    self:back()
  end
  
	local backButton = Button:create(self.titleUI:getChildByName("r_click"))
	backButton:addEventListener(Events.kStart, backButtonSelected, self)
  
 	self.building = false
  
	local function onConstructBtn1(evt)
		print("onConstructBtn1")
		local coin = tonumber(DataManager.getCurrUser().coins)
		if coin < UnionManager.getBuildCostNum(UnionManager.BUILD_LEVEL1) then
			local aPanel = MessageBoxPanel:create(self, MessageBoxType.kCoinLimit)
			self:addChild(aPanel)
			aPanel:scaleIn()
		else
			self:constructUnion(UnionManager.BUILD_LEVEL1)
		end
		
	end
	
	local function onConstructBtn2(evt)
		print("onConstructBtn2")
		local curGams = CalculationManager.calcComplex_getGemsNow()
		if curGams < UnionManager.getBuildCostNum(UnionManager.BUILD_LEVEL2) then
			local function onReplaceScene()
                --PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			end
			local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
			self:addChild(aPanel)
			aPanel:scaleIn()
		else
			self:constructUnion(UnionManager.BUILD_LEVEL2)
		end
	end
	
	local function onConstructBtn3(evt)
		local curGams = CalculationManager.calcComplex_getGemsNow()
		if curGams < UnionManager.getBuildCostNum(UnionManager.BUILD_LEVEL3) then
			local function onReplaceScene()
                --PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			end
			local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
			self:addChild(aPanel)
			aPanel:scaleIn()
		else
			self:constructUnion(UnionManager.BUILD_LEVEL3)
		end
	end
  
	self.constructBtn1 = Button:create(self.ui:getChildByName("list_guild_hall"):getChildByName("btn_slivercreate"))
	self.constructBtn1:addEventListener(Events.kStart, onConstructBtn1, self)
	
	self.constructBtn2 = Button:create(self.ui:getChildByName("list_guild_hall_2"):getChildByName("btn_slivercreate"))
	self.constructBtn2:addEventListener(Events.kStart, onConstructBtn2, self)
	
	self.constructBtn3 = Button:create(self.ui:getChildByName("list_guild_hall_3"):getChildByName("btn_slivercreate"))
	self.constructBtn3:addEventListener(Events.kStart, onConstructBtn3, self)
	
	local showContributeBtn = true
	local gameInitData = DataManager.getGameInitData()
	local lastConTime = gameInitData.sharkUserUnion.lastestConstructSeconds
	if lastConTime > 0 then
	--[[
	print( "lastConTime:" .. lastConTime)
	local lastConTimeFormat = os.date("*t", lastConTime)
	local canContributeTime = os.time{year=lastConTimeFormat.year, month=lastConTimeFormat.month, day=(lastConTimeFormat.day), hour=0}
	print( "canContributeTime:" .. canContributeTime)
	
	local curTime = TimeUtil.getServerTimeSeconds()
	print( "curTime:" .. curTime)
	if  curTime < canContributeTime then
		showContributeBtn = false
		self:hideContributeBtn()
	end
	--]]
		local pressDayFromNow = TimeUtil.getPasseddDaysToNow(lastConTime)
		if pressDayFromNow <= 0 then --todo
			showContributeBtn = false
			self:hideContributeBtn()
		end
	end
  
	self:refreshHallInfo()
	
	BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)
end

function UnionHallScene:hideContributeBtn()
	self.ui:getChildByName("list_guild_hall"):getChildByName("btn_slivercreate"):getChildByName("btn"):setVisible(false)
	self.ui:getChildByName("list_guild_hall_2"):getChildByName("btn_slivercreate"):getChildByName("btn"):setVisible(false)
	self.ui:getChildByName("list_guild_hall_3"):getChildByName("btn_slivercreate"):getChildByName("btn"):setVisible(false)

	self.constructBtn1:setEnable(false)
	self.constructBtn2:setEnable(false)
	self.constructBtn3:setEnable(false)
end

function UnionHallScene:constructUnion(buildLevel)
	if self.building then
		return
	end

	--能否建设
	local nowTimes = UnionManager.getTodayBuildTotalTimes()
	local maxTimes = UnionManager.DonatMaxTimes()
	-- print("nowTimes = " .. nowTimes)
	-- print("maxTimes = " .. maxTimes)
	if nowTimes >= maxTimes then
		SuspensionLabel:showContent(self, Localization:getInstance():getText("union_build_today_max_remind", {num = maxTimes}))--军团每天最多只能建设{num}次
		return
	end

	local function onConstructSucceed(constructType, requestEvent)
		UnionConstructUnionRequest.onSucceedDefault(constructType, requestEvent)
		--print("union hall construct success:" .. buildLevel)
		self.building = false
		self:refreshHallInfoByRequest()
		self:hideContributeBtn()
		
		local addContribute = UnionManager.getBuildContributeNum(buildLevel)
		local addWeath = UnionManager.getBuildWealthNum(buildLevel)
		
		SuspensionLabel:showContent(self, Localization:getInstance():getText("union_build_finish_remind", {num1 = addContribute, num2 = addWeath}))
	end
	
	local function onConstructFailed(requestEvent)
		--print("union hall construct failed:" .. buildLevel)
		UnionConstructUnionRequest.onFailedDefault(requestEvent)
		self.building = false
	end

	self.building = true
	UnionConstructUnionRequest.sendRequest(buildLevel, onConstructSucceed, onConstructFailed)
end

function UnionHallScene:refreshHallInfoByRequest()
	local function onSucceed(requestEvent)
		GetUnionBuildingHallInfoRequest.onSucceedDefault(requestEvent)
		self.hallData = requestEvent.data
		self:refreshHallInfo()
	end
	GetUnionBuildingHallInfoRequest.sendRequest(onSucceed, GetUnionBuildingHallInfoRequest.onFailedDefault)
end

function UnionHallScene:refreshHallInfo()
	--set title info
	local gameInitData = DataManager.getGameInitData();
	self.titleUI:getChildByName("txt_guild_21"):getChildByName("txt"):setString(""..gameInitData.sharkUserUnion.hisContribute)
	
	local curGams = CalculationManager.calcComplex_getGemsNow()
	self.titleUI:getChildByName("txt_guild_21_2"):getChildByName("txt"):setString(tostring(curGams))
	
	local coinStr = tostring(DataManager.getCurrUser().coins)
	self.titleUI:getChildByName("txt_guild_22"):getChildByName("txt"):setString(coinStr)
	
	local titleStr = getTextByKey("union_building_name1")
	self.titleUI:getChildByName("txt_guild_19"):getChildByName("txt"):setString(titleStr)
	
	local hallLevel = tostring(self.hallData.unionHallLevel)
	self.titleUI:getChildByName("txt_guild_20"):getChildByName("txt"):setString(hallLevel)
	
	--军团财富
	-- local textWealth = getTextByKey("union_add_wealth_own_text1")
	-- self.ui:getChildByName("txt_guild_39"):getChildByName("txt"):setString(textWealth)
	local hallLevel = tostring(self.hallData.unionWealth)
	self.ui:getChildByName("txt_guild_40"):getChildByName("txt"):setString(hallLevel)
	
	--升级下一级军团所需
	-- local textUp = getTextByKey("union_building_upgrade_wealth_need")
	-- self.ui:getChildByName("txt_guild_39_2"):getChildByName("txt"):setString(textUp)
	local currentLevel = self.hallData.unionHallLevel--应该用当前等级计算升级消耗
	local nextWealthStr = nil
	if MetaManager.union_building_hall[currentLevel] then
		nextWealthStr = tostring(MetaManager.union_building_hall[currentLevel].wealth)
	else
		nextWealthStr = "error"
	end
	self.ui:getChildByName("txt_guild_40_2"):getChildByName("txt"):setString(nextWealthStr)
	
	for i=1,10 do
		local item = self.itemTable[i]
		local data = self.hallData.donateAnnouncement[i]
		if data then
			item:setVisible(true)
			item:getChildByName("txt_guild_hall_sub1"):getChildByName("txt"):setString(data.nickname)
			item:getChildByName("txt_guild_hall_sub2"):getChildByName("txt"):setString(getTextByKey("union_hall_note1"))
			item:getChildByName("txt_guild_hall_sub3"):getChildByName("txt"):setString(tostring(data.donateNum))
			item:getChildByName("txt_guild_hall_sub4"):getChildByName("txt"):setString(getTextByKey("union_hall_note2"))
		else
			item:setVisible(false)
		end
	end

	--等级是否已满状态
	if UnionManager.isBuildingMaxLevel(UnionManager.UNION_BUILDING_HALL) then
		--已满级
		self.ui:getChildByName("txt_guild_40_2"):setVisible(false)
		self.ui:getChildByName("lbl_guild2"):setVisible(false)

		self.ui:getChildByName("lbl_guild_build_max"):setVisible(true)
	else
		--不是满级
		self.ui:getChildByName("txt_guild_40_2"):setVisible(true)
		self.ui:getChildByName("lbl_guild2"):setVisible(true)
		
		self.ui:getChildByName("lbl_guild_build_max"):setVisible(false)
	end

end

function UnionHallScene:dispose()
  --if self.countDownEntry then
  --  CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.countDownEntry)
  --  self.countDownEntry = nil
  --end
  UnionHallScene.super.dispose(self)
end

function UnionHallScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function UnionHallScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function UnionHallScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.ui:setPositionX(self.ui:getPositionX() - visibleSize.width)
  self.ui:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  
  
  local aHeight = self.titleUI:getGroupBounds().size.height
  self.titleUI:setPositionY(self.titleUI:getPositionY() + aHeight)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(0, -aHeight)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.titleUI:runAction(CCSequence:create(arr))
  
end

function UnionHallScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
end

function UnionHallScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function UnionHallScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  
end

function UnionHallScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.ui:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  
  local aHeight = self.titleUI:getGroupBounds().size.height
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(0, aHeight)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.titleUI:runAction(CCSequence:create(arr))
  
end

function UnionHallScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function UnionHallScene:back()
  if self.argv.enterScene == "UnionScene" then
    UnionManager.gotoUnionScene()
  end
end

function UnionHallScene.getBuildingTipNum()
  local result = 0
  local gameInitData = DataManager.getGameInitData()
  local lastConTime = gameInitData.sharkUserUnion.lastestConstructSeconds
	if lastConTime > 0 then
		local pressDayFromNow = TimeUtil.getPasseddDaysToNow(lastConTime)
		if pressDayFromNow <= 0 then
			result = 0
    else
      result = 1
		end
  else
    result = 1
	end
  return result
end