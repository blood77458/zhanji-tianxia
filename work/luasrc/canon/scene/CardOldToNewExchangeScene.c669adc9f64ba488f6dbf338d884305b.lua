-- CardOldToNewExchangeScene.lua
-- 2014-11-7
-- zheng.che
-- 卡牌以旧换新 兑换场景
require "canon.request.ActivityexchangeCardDailyRequest"
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

FragmentTagEnum = {
  CARD = 1,
  EQUIP = 2,
}

local enter_animation_duration = 0.3

-------------------------------------------------------------------------------
-- 可用函数
-------------------------------------------------------------------------------

--点击问号
local function onHelpBtnClick(evt)
	local self = evt.context
    local TxtName = nil
	local timeTable
	if self.argv.params.returnScene == "Activity_ExchangeDailyLayer" then
		TxtName = "exchangeDaily_help"
        timeTable = MaintenanceManager:getActivityBeginAndEndTimeButThisActivityIsOpenEveryWeek(self.argv.params.layer.getFeatureName())
    else
    	TxtName = "cardExchange_help_txt1"
    	timeTable = MaintenanceManager:getStartAndEndTime(self.argv.params.layer.getFeatureName())
    end
	--本期活动时间：{month1}月{day1}日—{month2}月{day2}日。\n活动期间可以使用两张没有转生过的五星卡牌加一定的星灵进行新卡牌的兑换。\n如果使用与所需兑换卡牌名
	local str = getTextByKey(TxtName, {month1 = timeTable[1].month , day1 = timeTable[1].day , month2 = timeTable[2].month, day2 = timeTable[2].day})
    local aInfoPanel = ActivityInfoPanel:create(self, str)
    self:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
end

--点击兑换
local function onExchangeBtnClick(evt)
	local self = evt.context
	--

	local selectNum = #self.selectCardList
	if selectNum < self.needSelectCardNum then
		--选择数量不够
		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("cardExchange_error_txt1"))--兑换所需的材料武将不足！
		return
	end

	local needEssence = self:getNeedEssence()
	local currentAstralessenceNum = CanonGoodIcon.getResourceNum(ResourceEnum.ASTRALESSENCE)--当前星灵数
	if currentAstralessenceNum < needEssence then
		--星灵数不够
		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("cardExchange_error_txt2"))--兑换所需的星灵不足！
		return
	end

	local exchangeCardIds = {}
	for i = 1, self.needSelectCardNum, 1 do
		table.insert(exchangeCardIds, self.selectCardList[i].cardId)
	end

	local function onAfterSucceed(evt)
		--兑换成功
		local function onAnimeEnd()
			local function onRewardClose()
				--玩家关闭奖励窗口
				local exchangeMeta = self.argv.params.layer.getCardExchangeMetaById(self.argv.params.exchangeId)
				local currentExchangeNum = self.argv.params.layer.getCurrentExchangeNum(self.argv.params.exchangeId)--当前兑换数量
				if currentExchangeNum >= exchangeMeta.exchangeNum then
					--达到兑换数量上限 自动返回上一级
					self:back()
				else
					--清空选择 然后刷新
					self.selectCardList = {}
					self:refreshSelf()
				end
			end
			--显示获得的奖励
			local scene = Director:mgr():run()
			local aRewardPanel = RewardReviewPanel:create( scene, {rewardList = evt.data.reward, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), closeCB = onRewardClose} )
			scene:addChild(aRewardPanel)
			aRewardPanel:scaleIn()
		end
		self:playAnime(onAnimeEnd)
	end
	if self.argv.params.returnScene == "Activity_ExchangeDailyLayer" then
		local exchangeMeta = self.argv.params.layer.getCardExchangeMetaById(self.argv.params.exchangeId)
		-- print("~~~~~~~~~~~~~~~~~~Activity_ExchangeDailyLayer")
		ActivityexchangeCardDailyRequest.sendRequestDefalut(exchangeMeta.cardId, exchangeCardIds, needEssence, onAfterSucceed)
    else

    	-- print("~~~~~~~~~~~~~~~~~~CardOldToNewExchangeRequest")
		CardOldToNewExchangeRequest.sendRequestDefalut(self.argv.params.exchangeId, exchangeCardIds, needEssence, onAfterSucceed)
	end
end

--点击左边卡牌
local function onCardClick(evt)
	local self = evt.context
	self:openSelectPanel()
end

--点击卡牌大图
local function onFullCardClick(evt)
	local self = evt.context
	local exchangeMeta = self.argv.params.layer.getCardExchangeMetaById(self.argv.params.exchangeId)
	self.argv.params.layer.openCard(exchangeMeta.cardId)
end

-------------------------------------------------------------------------------
-- 初始化处理
-------------------------------------------------------------------------------

CardOldToNewExchangeScene = class(BaseUIScene)

function CardOldToNewExchangeScene:ctor()
	--已经选择的卡牌列表
	self.selectCardList = {}
	--可选择的卡牌数量
	self.needSelectCardNum = 1
end

local globalReturnScene

function CardOldToNewExchangeScene:create(argv)
	if SystemManager.debug then
		DebugManager.assert(argv.params ~= nil, "CardOldToNewExchangeScene: argv参数必须有 params 字段! ")
		DebugManager.assert(argv.params.exchangeId ~= nil, "CardOldToNewExchangeScene: argv参数必须有 params.exchangeId 字段! ")
	end
  local s = CardOldToNewExchangeScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  s:initScene()
  return s
end

function CardOldToNewExchangeScene:onInit()

	BaseUIScene.initBackGround(self)
	local TitleName = nil
    if self.argv.params.returnScene == "Activity_ExchangeDailyLayer" then
        TitleName = "exchangeDaily_title"
    else
    	TitleName = "activityCardExchange_title"
    end
	self.title = Localization:getInstance():getText(TitleName)--易帅换将

	local builder = LayoutBuilder:createWithContentsOfFile("scene/oldChangeNew.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("activity_oldChangeNew_main")
	self:addChild(ui)
	self.ui = ui

	--print("self.argv = " .. tostringRich(self.argv))
	local exchangeMeta = self.argv.params.layer.getCardExchangeMetaById(self.argv.params.exchangeId)
	local cardName = CanonGoodIcon.getGoodName(ResourceEnum.CARD, exchangeMeta.cardId, 0, {withoutAmount = true})
	local cardRare = CanonGoodIcon.getGoodRare(ResourceEnum.CARD, exchangeMeta.cardId)

	if cardRare == 6 then
		--六星卡牌 选一张
		self.needSelectCardNum = 1
	else
		--非6星卡牌 选两张
		self.needSelectCardNum = 2
	end

	local function refreshSelf()
		local currentAstralessenceNum = CanonGoodIcon.getResourceNum(ResourceEnum.ASTRALESSENCE)--当前星灵数
		local currentExchangeNum = self.argv.params.layer.getCurrentExchangeNum(self.argv.params.exchangeId)--当前兑换数量

		self.ui:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("cardExchange_secret") .. currentAstralessenceNum)--已有星灵数:[num]
		self.ui:getChildByName("txt_7"):getChildByName("txt"):setString(exchangeMeta.exchangeNum - currentExchangeNum)--[剩余兑换次数]
		self.ui:getChildByName("txt_9"):getChildByName("txt"):setString(cardName)--[目标卡牌名称]

		--显示n个卡牌图标
		self.ui:getChildByName("normal_card_position_name1"):setVisible(false)
		self.ui:getChildByName("normal_card_position_name2"):setVisible(false)
		self.ui:getChildByName("normal_card_position_name3"):setVisible(false)
		local selectCardIconNames = {}
		if self.needSelectCardNum == 1 then
			--选一张
			selectCardIconNames = {"normal_card_position_name3"}
		else
			--选两张
			selectCardIconNames = {"normal_card_position_name1", "normal_card_position_name2"}
		end
		for i = 1, self.needSelectCardNum, 1 do
			--显示卡牌图标
			local cardItemDisplay = self.ui:getChildByName(selectCardIconNames[i])
			cardItemDisplay:setVisible(true)

			if cardItemDisplay.cardIcon then
				cardItemDisplay.cardIcon:removeFromParentAndCleanup(true)
			end
			local aCardDisplay = cardItemDisplay:getChildByName("nomal_card_small")
			local params = {}
			params.sourceDisplay = aCardDisplay
			params.showInCenter = true

			cardItemDisplay.cardIcon = nil
			local cardName = nil
			if self.selectCardList[i] then
				--有选择的卡牌
				cardItemDisplay.cardIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, CommonManager:changeAvatarByCardInfo(self.selectCardList[i]), 0, params)
				cardName = CanonGoodIcon.getGoodName(ResourceEnum.CARD, self.selectCardList[i].metaId, 0, {withoutAmount = true})
			else
				--没选择的卡牌
				cardItemDisplay.cardIcon = CanonGoodIcon.createGoodIcon(CanonGoodIcon.CARD_ADD, 0, 0, params)
				cardName = ""
			end
			--显示卡牌头像
			cardItemDisplay:addChildAt(cardItemDisplay.cardIcon, aCardDisplay:getZOrder())
			--显示卡牌名称
			cardItemDisplay:getChildByName("txt"):getChildByName("txt"):setString(cardName)
		end

		--显示需要的星灵数
		local needEssence = self:getNeedEssence()
		self.ui:getChildByName("txt_4"):getChildByName("txt"):setString(needEssence)--[消耗星灵数]
	end
	self.refreshSelf = refreshSelf

	--获得活动时间
	local timeTable
	if self.argv.params.returnScene == "Activity_ExchangeDailyLayer" then
        timeTable = MaintenanceManager:getActivityBeginAndEndTimeButThisActivityIsOpenEveryWeek(self.argv.params.layer.getFeatureName())
    else
    	timeTable = MaintenanceManager:getStartAndEndTime(self.argv.params.layer.getFeatureName())
    end

	--隐藏卡牌默认边框
	self.ui:getChildByName("normal_card_position_name1"):getChildByName("nomal_card_small"):setVisible(false)
	self.ui:getChildByName("normal_card_position_name2"):getChildByName("nomal_card_small"):setVisible(false)
	self.ui:getChildByName("normal_card_position_name3"):getChildByName("nomal_card_small"):setVisible(false)

	--静态文本
	self.ui:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("cardExchange_duration") .. getTextByKey("cardExchange_time", {month1 = timeTable[1].month , day1 = timeTable[1].day , month2 = timeTable[2].month, day2 = timeTable[2].day}))--本期活动时间: + {month1}月{day1}日—{month2}月{day2}日
	self.ui:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("cardExchange_useSecret"))--消耗星灵:
	self.ui:getChildByName("txt_5"):getChildByName("txt"):setString(getTextByKey("cardExchange_notice1"))--材料须为与目标武将同星级未转生武将
	self.ui:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("cardExchange_notice2"))--使用与目标武将同名的材料武将,会减少星灵的消耗！
	self.ui:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("cardExchange_txt2"))--可兑换: 
	self.ui:getChildByName("txt_8"):getChildByName("txt"):setString(getTextByKey("cardExchange_txt3"))--次
	self.ui:getChildByName("btn"):getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("cardExchange_exchange"))--兑换

	if self.argv.params.specialExchange then
		self.ui:getChildByName("txt_5"):getChildByName("txt"):setString(getTextByKey("cardExchange_notice3"))--材料须为与目标武将同星级未转生武将
		self.ui:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey(" "))--使用与目标武将同名的材料武将,会减少星灵的消耗！
	end

	--按钮
	local helpBtn = Button:create(self.ui:getChildByName("sky_btn_qa"))
	helpBtn:addEventListener(Events.kStart, onHelpBtnClick, self)

	local exchangeBtn = Button:create(self.ui:getChildByName("btn"))
	exchangeBtn:addEventListener(Events.kStart, onExchangeBtnClick, self)

	local cardIcon1 = Button:create(self.ui:getChildByName("normal_card_position_name1"))
	cardIcon1:addEventListener(Events.kStart,onCardClick, self)

	local cardIcon2 = Button:create(self.ui:getChildByName("normal_card_position_name2"))
	cardIcon2:addEventListener(Events.kStart,onCardClick, self)

	local cardIcon3 = Button:create(self.ui:getChildByName("normal_card_position_name3"))
	cardIcon3:addEventListener(Events.kStart,onCardClick, self)

	--设置目标卡牌的星数
	CanonGoodIcon.setStarIcon(self.ui:getChildByName("icon_xinBig"), cardRare, 34, 33, 0)
	--卡牌大图
	self.fullCard = CanonFullCard:create(self.ui:getChildByName("full"))
	--显示卡牌大图
	self.fullCard:setCard(exchangeMeta.cardId)
	--卡牌大图点击事件
	local cardIcon2 = Button:create(self.fullCard)
	cardIcon2:addEventListener(Events.kStart,onFullCardClick, self)
  
	self.refreshSelf()

	BaseUIScene.onInit(self)
end

--打开选择界面
function CardOldToNewExchangeScene:openSelectPanel()
	--
	local function onSelected(selectDataList)
		--获得选择的卡牌列表
		self.selectCardList = selectDataList
		--刷新显示
		self.refreshSelf()
	end

	local exchangeMeta = self.argv.params.layer.getCardExchangeMetaById(self.argv.params.exchangeId)
	local dataList = ItemManager.getOldToNewMatterCards(exchangeMeta.cardId , exchangeMeta.specialExchange)
	-- print("~~~~~~~~~~~~~~~~~~~~~~dataList = "..tostringRich(dataList))
	local scene = Director:mgr():run()
	scene.targetInfoPanel = BatchSelectItemPanel:create(dataList, BatchSelectItemPanel.SELECT_TYPE_CARD_EXCHANGE, self.needSelectCardNum, onSelected)
	PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
end

--本次兑换需要多少星灵
function CardOldToNewExchangeScene:getNeedEssence()
	local needEssence = 0
	local exchangeMeta = self.argv.params.layer.getCardExchangeMetaById(self.argv.params.exchangeId)
	local cardRare = CanonGoodIcon.getGoodRare(ResourceEnum.CARD, exchangeMeta.cardId)
	if cardRare == 6 then
		--6星卡牌 固定消耗
		if #self.selectCardList <= 0 then
			--没有选择
			needEssence = 0
		else
			needEssence = self.argv.params.layer.getSixCost()
		end
	else
		--非6星卡牌 走公式
		local targetEssence = exchangeMeta.secretNum
		if #self.selectCardList <= 0 then
			--没有选择
			needEssence = 0
		else
			local totalExchangeEssence = 0
			for i, v in ipairs(self.selectCardList) do
				local thisCardExchangeEssence = MetaManager.card_meta[v.metaId].astralEssence
				if CommonManager:checkTwoCardsInOneGroup(v.metaId, exchangeMeta.cardId) then
					--属于同名卡牌(缘分卡) 有加成
					thisCardExchangeEssence = thisCardExchangeEssence * self.argv.params.layer.getOldCardRatio()
				end
				totalExchangeEssence = totalExchangeEssence + thisCardExchangeEssence
			end
			needEssence = targetEssence - totalExchangeEssence
			if needEssence < 0 then
				needEssence = 0
			end
		end
	end
	return needEssence
end

function CardOldToNewExchangeScene:playAnime(completeCB)
	local exchangeMeta = self.argv.params.layer.getCardExchangeMetaById(self.argv.params.exchangeId)
	local cardId = exchangeMeta.cardId

	--灰色遮罩
	self.colorLayer = LayerColor:create()
	self.colorLayer:setOpacity(kDarkOpacity)
	self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(self.colorLayer)--一定要加在scene上才有效
	--禁用点击
	self.targetInfoPanel = self.colorLayer

	self.gachaFlashSprite = FlashSprite:create("EVO2/card_old_to_new")
	
	self.gachaFlashSprite:addChangeInstance("cardFull1", getFullCardSpriteFrame(cardId))
	self.gachaFlashSprite:addChangeInstance("card1", getCardSpriteFrame(cardId))
	self.gachaFlashSprite:addChangeInstance("cardBorder1", getCardBorderSpriteFrame(cardId))
	self.gachaFlashSprite:addChangeInstance("cardBg1", getCardBackGroundSpriteFrame(cardId))

	local meta = MetaManager.card_meta[cardId]
	local countryCicrleName = {"countryCircle_1.png", "countryCircle_2.png", "countryCircle_3.png", "countryCircle_4.png"}
	local countrySprite = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(countryCicrleName[meta.country])
	self.gachaFlashSprite:addChangeInstance("countryCicrle1", countrySprite)
	local BianGuangName = {
		"pic/gacha_bian_guang_1.png",
		"pic/gacha_bian_guang_1.png",
		"pic/gacha_bian_guang_2.png",
		"pic/gacha_bian_guang_2.png",
		"pic/gacha_bian_guang_2.png",
		"pic/gacha_bian_guang_3.png",
		"pic/gacha_bian_guang_3.png",
	}
	self.gachaFlashSprite:addChangeInstance("baiguang1", createSpriteFrame(BianGuangName[meta.rare]))

	self.gachaFlashSprite:changeAnimation(0)
	self.gachaFlashSprite:setLoop(false)

	local function onFlashAnimationEnd(anim)
	    self.gachaFlashSprite:unregisterEndAnimationScriptHandler()
	    self:removeChild(self.gachaFlashSprite_co)

	    --取消遮罩
	    self.colorLayer:removeFromParentAndCleanup(true)
	    --启用点击
	    self.targetInfoPanel = nil

		if completeCB then
			completeCB()
		end
	end

	self.gachaFlashSprite:registerEndAnimationScriptHandler(onFlashAnimationEnd)
	self.gachaFlashSprite:addFrameEvent("showName", 1, 30)
	self.gachaFlashSprite_co = CocosObject.new(self.gachaFlashSprite)
	self:addChild(self.gachaFlashSprite_co)
end
-----------------------------------------------外部接口------------------------------------------------------------

-----------------------------------------------进出场景动画------------------------------------------------------------
function CardOldToNewExchangeScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function CardOldToNewExchangeScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/background.mp3", true)
end

function CardOldToNewExchangeScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	self.ui:setPositionX(self.ui:getPositionX() - visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))
end

function CardOldToNewExchangeScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
	--
end

function CardOldToNewExchangeScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function CardOldToNewExchangeScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)
end

function CardOldToNewExchangeScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))
end

function CardOldToNewExchangeScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景动画------------------------------------------------------------

-- 退出到外层
function CardOldToNewExchangeScene:back()
	if self.argv.params.returnScene == "Activity_ExchangeDailyLayer" then
        self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_ExchangeDaily"})
	else
		self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_CardExchange"})
    end
end

function CardOldToNewExchangeScene:dispose()
	CardOldToNewExchangeScene.super.dispose(self)
end

-----------------------------------------------静态函数------------------------------------------------------------