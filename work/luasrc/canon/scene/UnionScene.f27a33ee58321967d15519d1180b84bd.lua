--
-- UnionScene.lua
-- Author: zheng.che
-- Date: 2014-03-19 14:23:55
-- 军团主界面
--
require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.request.UnionGetUnionListRequest"
require "canon.request.UnionGetMyApplyListRequest"
require "canon.request.UnionSearchRequest"
require "canon.customUI.TabPanelChangeComponent"
require "canon.panel.UnionListPanel"
require "canon.panel.UnionCreatePopPanel"
require "canon.customUI.CanonButton"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local TagEnum = {
  UNION_LIST = 1,
  APPLY_LIST = 2,
  SEARCH_LIST = 3,
}

local enter_animation_duration = 0.3
local selectedText = ""

-------------------------------------------------------------------------------
-- 按钮点击
-------------------------------------------------------------------------------

--点击其他军团
local function onUnionListBtnlick(evt)
	UnionManager.gotoUnionListScene()
end

--点击修改公告
local function onChangeNotifyBtnlick(evt)
	--print("onChangeNotifyBtnlick")
	self = evt.context
	self.targetInfoPanel = UnionChangeNoticePopPanel:create(self)
	PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false , self)
end
-------------------------------------------------------------------------------
-- 点击建筑按钮
-------------------------------------------------------------------------------

--点击军团大厅
local function onHallBtnClick(evt)
	--print("onHallBtnClick")
	UnionManager.gotoHallScene("UnionScene")
end

--点击军团钱庄
local function onBankBtnClick(evt)
  UnionManager.gotoBankScene("UnionScene")
end

--点击军团商城
local function onShopBtnClick(evt)
	UnionManager.gotoShopScene("UnionScene")
end

--点击军团斗兽场
local function onColosseumBtnClick(evt)
	UnionManager.gotoUnionColosseumScene()
end

--点击未开放的建筑
local function onOtherBuildingBtnClick(evt)
	--print("onOtherBuildingBtnClick")
  	--未开放提示
	self = evt.context
	SuspensionLabel:showContent(self, Localization:getInstance():getText("union_building_lock_remind"))--暂未开启
end

--点击军团战按钮
local function onUnionPkBtnClick(evt)
	--print("onUnionPkBtnClick")
	if UnionPK.pkStarted(true) then
		--已经开始
		UnionPK.gotoUnionPkScene()
	end
end

--点击跨服Gvg按钮
local function onCrossUnionPkBtnClick(evt)
	--print("onCrossUnionPkBtnClick")
	if CrossUnionPk.pkStarted(true) then --是否首届开启
		--已经开始
		--
		CrossUnionPk.gotoCrossLoginUnionPkScene()
	end
end

-------------------------------------------------------------------------------
-- 点击建筑升级按钮
-------------------------------------------------------------------------------

--点击军团大厅升级
local function onHallUpgradeBtnClick(evt)
	--print("onHallUpgradeBtnClick")
	self = evt.context
	self.targetInfoPanel = UnionBuildingUpgradePopPanel:create(evt.context, UnionManager.UNION_BUILDING_HALL)
	PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false , self)
end

--点击军团商城升级
local function onShopUpgradeBtnClick(evt)
	--print("onShopUpgradeBtnClick")
	self = evt.context
	self.targetInfoPanel = UnionBuildingUpgradePopPanel:create(evt.context, UnionManager.UNION_BUILDING_SHOP)
	PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false , self)
end

--点击军团钱庄升级
local function onBankUpgradeBtnClick(evt)
	--print("onBankUpgradeBtnClick")
	self = evt.context
	self.targetInfoPanel = UnionBuildingUpgradePopPanel:create(evt.context, UnionManager.UNION_BUILDING_BANK)
	PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false , self)
end

--点击军团斗兽场升级
local function onColosseumUpgradeBtnClick(evt)
	--print("onColosseumUpgradeBtnClick")
	self = evt.context
	self.targetInfoPanel = UnionBuildingUpgradePopPanel:create(evt.context, UnionManager.UNION_BUILDING_COLOSSEUM)
	PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false , self)
end

-------------------------------------------------------------------------------
-- 事件侦听
-------------------------------------------------------------------------------

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == nil)
end

--建筑升级触发
local function onBuildingLevelup(evt)
	--print("onBuildingLevelup")
	local self = evt.context
	local buildingId = evt.buildingId

	local buildingIcon = self:getBuildingIconById(buildingId)
	local buildingSize = buildingIcon:getGroupBounds().size

	--显示动画
	self:setTableViewsEnabled(false)
	local colorLayer = LayerColor:create()
	colorLayer:setOpacity(kDarkOpacity)
	colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(colorLayer, 100)
	local fspt = FlashSprite:create("EVO2/qidao")
	fspt:changeAnimation(0)
	fspt:setLoop(false)
	fspt:setScale(0.7)
	self.fspt_co = CocosObject.new(fspt)
	-- self.fspt_co:setPositionX((buildingSize.width) / 2.0)
	-- self.fspt_co:setPositionY((buildingSize.height) / 2.0)
	self.fspt_co:setPositionX(buildingIcon:getPositionX() + buildingSize.width / 2.0 - visibleSize.width/2 + 100)
	self.fspt_co:setPositionY(buildingIcon:getPositionY() + buildingSize.height / 2.0 - visibleSize.height/2 - 0)
	local function animationEnd(anim)
		fspt:unregisterEndAnimationScriptHandler()
		self:removeChild(self.fspt_co)
		self:setTableViewsEnabled(true)
		self:removeChild(colorLayer)
	end
	fspt:registerEndAnimationScriptHandler(animationEnd)
	self:addChild(self.fspt_co)
end

--时间段更新事件
local function onTimelevelUpdate(evt)
  local self = evt.context
  local timeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
  

  if timeLevel >= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16 and timeLevel <= CrossUnionPkConsts.TIME_WORSHIP  then
  	local  adjude = self.ui:getChildByName("btn_guildPK_Gvg_tp"):getChildByName("icon_guildPK_Gvg_disable"):isVisible()
  	local function onGetMyDataSucceed(getMyDataRequestEvent)
		UnionGetMyDataRequest.onSucceedDefault(getMyDataRequestEvent)
        if getMyDataRequestEvent.data.out == 2 then
        	self.CrossUnionBtn:setEnable(false)
        	self.CrossUnionBtnDisplay1:setVisible(false)
        	self.ui:getChildByName("btn_guildPK_Gvg_tp"):getChildByName("icon_guildPK_Gvg_disable"):setVisible(true)
        	self.refreshSelf()
        end
	end
	if not adjude then 
		UnionGetMyDataRequest.sendRequest(onGetMyDataSucceed, UnionGetMyDataRequest.onFailedDefault)
    end
  else
  	  local Identity = UnionManager.getMyTitle() 
	  local ResultName = CrossUnionPkCheck.AdjusetCountDown(timeLevel,Identity)
	  -- print("~~~~~~~~~~~~~~ResultName = "..ResultName)
	  if ResultName == "MEMBERAPPLY" or ResultName == "ARMYAPPLY" or ResultName =="GROUPING" then
	  	local function onGetMyDataSucceed(getMyDataRequestEvent)
	  	    UnionGetMyDataRequest.onSucceedDefault(getMyDataRequestEvent)
	  	    -- print("更新了")
		  	self.CrossUnionBtnDisplay1:getChildByName("txt_guild_76"):setVisible(true)
			self.CrossUnionBtnDisplay1:getChildByName("bg_guild_cityname"):setVisible(true)

			self:SetCountUIText(ResultName)
			self.refreshSelf()
        end
		UnionGetMyDataRequest.sendRequest(onGetMyDataSucceed, UnionGetMyDataRequest.onFailedDefault)
	  else
        self:SetCountUIText(ResultName)
	    self.refreshSelf()
	  end
	  
  end
end



-------------------------------------------------------------------------------
-- 初始化处理
-------------------------------------------------------------------------------

UnionScene = class(BaseUIScene)

function UnionScene:ctor()
end

function UnionScene:create(argv)
	local s = UnionScene.new()
	if argv then 
		s.argv = argv 
	else
		s.argv = {enterScene=nil,returnScene=nil,params={}}
	end
	s.curSceneEnum = SceneEnum.UnionScene

	--当前显示中的列表内容(注意: 子panel可能读取)
	s.selectedDataList = {}
	s:initScene()
	return s
end

function UnionScene:onInit()
	BaseUIScene.initBackGround(self)
	
	self.tempLayer = Layer:create()
	self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(self.tempLayer)
	self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("guild_main")
	self.tempLayer:addChild(ui)
	self.ui = ui

	--刷新自身
	function refreshSelf()
		ui:getChildByName("txt_guild3"):getChildByName("txt"):setString(Localization:getInstance():getText("union_player_num_text_key") .. UnionManager.getUnionMemberCount() .. "/" .. UnionManager.getUnionMemberCountMax())--成员 + $成员数 + / + 成员数上限
		ui:getChildByName("txt_guild2"):getChildByName("txt"):setString(UnionManager.getMyContribute())--$个人贡献
		ui:getChildByName("txt_guild5"):getChildByName("txt"):setString(UnionManager.getUnionWealth())--$军团财富

		ui:getChildByName("txt_guildname"):getChildByName("txt"):setString(UnionManager.getUnionName())--$军团名称
		ui:getChildByName("txt_guild_info"):getChildByName("txt"):setString(UnionManager.getUnionNotice())--$军团公告

		local txt = ui:getChildByName("txt_guild_info"):getChildByName("txt")
		--txt:setDimensions(CCSizeMake(txt:getDimensions().width, 0))

		if UnionManager.canUpgradeBuilding(UnionManager.UNION_BUILDING_HALL) then -- 测试升级动画 unionUpgradeTest
			self.hallUpgradeBtnDisplay:setVisible(true)
			self.hallUpgradeBtn:setEnable(true)
			self.hallUpgradeBtnDisplay.touchEnabled = true
		else
			self.hallUpgradeBtnDisplay:setVisible(false)
			self.hallUpgradeBtn:setEnable(false)
			self.hallUpgradeBtnDisplay.touchEnabled = false
		end

		if UnionManager.canUpgradeBuilding(UnionManager.UNION_BUILDING_SHOP) then -- 测试升级动画 unionUpgradeTest
			self.shopUpgradeBtnDisplay:setVisible(true)
			self.shopUpgradeBtn:setEnable(true)
			self.shopUpgradeBtnDisplay.touchEnabled = true
		else
			self.shopUpgradeBtnDisplay:setVisible(false)
			self.shopUpgradeBtn:setEnable(false)
			self.shopUpgradeBtnDisplay.touchEnabled = false
		end
		
		if UnionManager.canUpgradeBuilding(UnionManager.UNION_BUILDING_BANK) then -- 测试升级动画 unionUpgradeTest
			self.bankUpgradeBtnDisplay:setVisible(true)
			self.bankUpgradeBtn:setEnable(true)
			self.bankUpgradeBtnDisplay.touchEnabled = true
		else
			self.bankUpgradeBtnDisplay:setVisible(false)
			self.bankUpgradeBtn:setEnable(false)
			self.bankUpgradeBtnDisplay.touchEnabled = false
		end
		
		if UnionManager.canUpgradeBuilding(UnionManager.UNION_BUILDING_COLOSSEUM) then -- 测试升级动画 unionUpgradeTest
			self.colosseumUpgradeBtnDisplay:setVisible(true)
			self.colosseumUpgradeBtn:setEnable(true)
			self.colosseumUpgradeBtnDisplay.touchEnabled = true
		else
			self.colosseumUpgradeBtnDisplay:setVisible(false)
			self.colosseumUpgradeBtn:setEnable(false)
			self.colosseumUpgradeBtnDisplay.touchEnabled = false
		end

		--设置能否查看修改公告按钮
		if UnionManager.canChangeNotice() then
			--有修改权限
			self.changeNotifyBtnDisplay:setVisible(true)
			self.changeNotifyBtn:setEnable(true)
		else
			self.changeNotifyBtnDisplay:setVisible(false)
			self.changeNotifyBtn:setEnable(false)
		end

		if UnionPK.enabled() then
			--判定军团战按钮是否有呼吸灯
			if UnionPkData.getUnionWarLightOn() then
				self.unionPkBtn:setShined(true)
			else
				self.unionPkBtn:setShined(false)
			end
			--显示角标
			self.unionPkBtn:setNum(UnionPkData.getUnionWarHintNum())
		end

		
        
		--跨服GvG
		-- print("~~~~~~~~~~~~~~~CrossUnionPkData.getCrossUnionWarLightOn() = "..tostringRich(CrossUnionPkData.getCrossUnionWarLightOn()))
		if  CrossUnionPk.enabled() then
			--判段跨服军团战按钮是否有呼吸灯
            CrossUnionPk.ResetLight()
			if CrossUnionPkData.getCrossUnionWarLightOn() and (not UnionManager.getGainCrossUnionWarInselfQuitCrossGvg()) then
                -- print("有呼吸灯")
				self.CrossUnionBtn:setShined(true)
			else
				self.CrossUnionBtn:setShined(false)
			end
			--显示角标
			self.CrossUnionBtn:setNum(0)
		end

		self.hallBtnDisplay:getChildByName("txt_lv"):getChildByName("txt"):setString(UnionManager.getBuildingLevel(UnionManager.UNION_BUILDING_HALL))
		self.shopBtnDisplay:getChildByName("txt_lv"):getChildByName("txt"):setString(UnionManager.getBuildingLevel(UnionManager.UNION_BUILDING_SHOP))
		self.bankBtnDisplay:getChildByName("txt_lv"):getChildByName("txt"):setString(UnionManager.getBuildingLevel(UnionManager.UNION_BUILDING_BANK))
		self.colosseumBtnDisplay:getChildByName("txt_lv"):getChildByName("txt"):setString(UnionManager.getBuildingLevel(UnionManager.UNION_BUILDING_COLOSSEUM))

		--更新角标
		self.hallBtn:setNum(UnionHallScene.getBuildingTipNum())
		self.shopBtn:setNum(UnionShopScene.getBuildingTipNum())
		self.bankBtn:setNum(UnionBankScene.getBuildingTipNum())
		self.colosseumBtn:setNum(UnionColosseumScene.getBuildingTipNum())
	end
	self.refreshSelf = refreshSelf

	function onTimeTick(remainedSec)
		local formatedTimeStr = TimeUtil.formatTime(remainedSec)
		ui:getChildByName("txt_guild_76"):getChildByName("txt"):setString(formatedTimeStr)--$剩余时间
	end
	self.onTimeTick = onTimeTick

	function onTimeComplete()
		ui:getChildByName("txt_guild_76"):setVisible(false)
		ui:getChildByName("txt_guild_75"):setVisible(false)
		ui:getChildByName("lbl_already_summon"):setVisible(false)
		ui:getChildByName("bg_guild_cityname"):setVisible(false)
	end
	self.onTimeComplete = onTimeComplete

    --跨服GvG倒计时
    function onTimeTickCross(remainedSec)
		local formatedTimeStr = TimeUtil.formatTime(remainedSec)
		--bg_guild_cityname
		
		self.CrossUnionBtnDisplay1:getChildByName("txt_guild_76"):getChildByName("txt"):setString(formatedTimeStr)--$剩余时间
	end
	self.onTimeTickCross = onTimeTickCross

	function onTimeCompleteCross()
		self.CrossUnionBtn:setShined(false)
		self.CrossUnionBtnDisplay1:getChildByName("txt_guild_76"):setVisible(false)
		self.CrossUnionBtnDisplay1:getChildByName("bg_guild_cityname"):setVisible(false)
	end
	self.onTimeCompleteCross = onTimeCompleteCross
	--静态文本
	ui:getChildByName("txt_guild1"):getChildByName("txt"):setString(Localization:getInstance():getText("union_player_contribute_text"))--个人贡献
	ui:getChildByName("txt_guild4"):getChildByName("txt"):setString(Localization:getInstance():getText("union_wealth_own_text"))--军团财富
	ui:getChildByName("txt_guild_75"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_away"))--距离神兽逃跑还有

	--其他军团
	self.unionListBtnDisplay = ui:getChildByName("icon_othergroup")
	self.unionListBtn = Button:create(self.unionListBtnDisplay)
	self.unionListBtn:addEventListener(Events.kStart, onUnionListBtnlick, self)

	--修改公告
	self.changeNotifyBtnDisplay = ui:getChildByName("icon_changeinfo")
	self.changeNotifyBtn = Button:create(self.changeNotifyBtnDisplay)
	self.changeNotifyBtn:addEventListener(Events.kStart, onChangeNotifyBtnlick, self)

	--军团战
	if UnionPK.enabled() then
		self.unionPkBtnDisplay = ui:getChildByName("btn_guildPK_tp")
		self.unionPkBtn = CanonButton:create(self.unionPkBtnDisplay)
		self.unionPkBtn:addEventListener(Events.kStart, onUnionPkBtnClick, self)
	else
		--军团战不存在
		ui:getChildByName("btn_guildPK_tp"):setVisible(false)
	end
  
	--跨服Gvg
	
    if CrossUnionPk.enabled() then
    	self.CrossUnionBtnDisplay1 = ui:getChildByName("btn_guildPK_Gvg_tp")
		self.CrossUnionBtnDisplay = self.CrossUnionBtnDisplay1:getChildByName("btn_chat")
		ui:getChildByName("btn_guildPK_Gvg_tp"):getChildByName("icon_guildPK_Gvg_disable"):setVisible(false)
    	self.CrossUnionBtn = CanonButton:create(self.CrossUnionBtnDisplay1)
		self.CrossUnionBtn:addEventListener(Events.kStart,onCrossUnionPkBtnClick,self)
	else
		ui:getChildByName("btn_guildPK_Gvg_tp"):setVisible(false)
		
	end
	-- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~UnionManager.getGainCrossUnionWarInout() = "..tostringRich(UnionManager.getGainCrossUnionWarInout()))
     local timeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
     print("timeLevel"..timeLevel)
    if timeLevel >= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16 and timeLevel <= CrossUnionPkConsts.TIME_WORSHIP and CrossUnionPk.enabled() then
	   print("在淘汰赛阶段")
	    if  UnionManager.getGainCrossUnionWarInout() == 2 then --服务器没有进淘汰赛
	      self.CrossUnionBtn:setEnable(false)
	      ui:getChildByName("btn_guildPK_Gvg_tp"):getChildByName("icon_guildPK_Gvg_disable"):setVisible(true)
	      self.CrossUnionBtnDisplay:setVisible(false)
		end
	end
    -- self.CrossUnionBtnDisplay1:getChildByName("btn_light"):setVisible(false)
    -- self.CrossUnionBtnDisplay1:getChildByName("num"):setVisible(false)
	--军团大厅
	self.hallBtnDisplay = ui:getChildByName("guild_main")
	self.hallBtn = CanonButton:create(self.hallBtnDisplay)
	self.hallBtn:addEventListener(Events.kStart, onHallBtnClick, self)
	--军团商城
	self.shopBtnDisplay = ui:getChildByName("guild_coin")
	self.shopBtn = CanonButton:create(self.shopBtnDisplay)
	self.shopBtn:addEventListener(Events.kStart, onShopBtnClick, self)
	--军团钱庄
	self.bankBtnDisplay = ui:getChildByName("guild_bank")
	self.bankBtn = CanonButton:create(self.bankBtnDisplay)
	self.bankBtn:addEventListener(Events.kStart, onBankBtnClick, self)
	--军团斗兽场
	self.colosseumBtnDisplay = ui:getChildByName("guild_colosseum")
	self.colosseumBtn = CanonButton:create(self.colosseumBtnDisplay)
	self.colosseumBtn:addEventListener(Events.kStart, onColosseumBtnClick, self)

	--军团大厅升级
	self.hallUpgradeBtnDisplay = ui:getChildByName("icon_lvup3")
	self.hallUpgradeBtn = Button:create(self.hallUpgradeBtnDisplay)
	self.hallUpgradeBtn:addEventListener(Events.kStart, onHallUpgradeBtnClick, self)
	--军团钱庄升级
	self.bankUpgradeBtnDisplay = ui:getChildByName("icon_lvup2")
	self.bankUpgradeBtn = Button:create(self.bankUpgradeBtnDisplay)
	self.bankUpgradeBtn:addEventListener(Events.kStart, onBankUpgradeBtnClick, self)
	--军团商城升级
	self.shopUpgradeBtnDisplay = ui:getChildByName("icon_lvup1")
	self.shopUpgradeBtn = Button:create(self.shopUpgradeBtnDisplay)
	self.shopUpgradeBtn:addEventListener(Events.kStart, onShopUpgradeBtnClick, self)
	--军团斗兽场升级
	self.colosseumUpgradeBtnDisplay = ui:getChildByName("icon_lvup4")
	self.colosseumUpgradeBtn = Button:create(self.colosseumUpgradeBtnDisplay)
	self.colosseumUpgradeBtn:addEventListener(Events.kStart, onColosseumUpgradeBtnClick, self)

	--未开放
	self.space1BtnDisplay = ui:getChildByName("space1")
	self.space1Btn = Button:create(self.space1BtnDisplay)
	self.space1Btn:addEventListener(Events.kStart, onOtherBuildingBtnClick, self)

	self.space2BtnDisplay = ui:getChildByName("space2")
	self.space2Btn = Button:create(self.space2BtnDisplay)
	self.space2Btn:addEventListener(Events.kStart, onOtherBuildingBtnClick, self)

	self.space3BtnDisplay = ui:getChildByName("space3")
	self.space3Btn = Button:create(self.space3BtnDisplay)
	self.space3Btn:addEventListener(Events.kStart, onOtherBuildingBtnClick, self)

	self.space5BtnDisplay = ui:getChildByName("space5")
	self.space5Btn = Button:create(self.space5BtnDisplay)
	self.space5Btn:addEventListener(Events.kStart, onOtherBuildingBtnClick, self)

	self.space6BtnDisplay = ui:getChildByName("space6")
	self.space6Btn = Button:create(self.space6BtnDisplay)
	self.space6Btn:addEventListener(Events.kStart, onOtherBuildingBtnClick, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	--建筑信息更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.EVENT_BUILDING_DATA_UPDATE, self.refreshSelf, self)
	--军团基础信息更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.EVENT_BASE_DATA_UPDATE, self.refreshSelf, self)
	UnionManager.eventDispatcher:addEventListener(UnionManager.EVENT_USER_UNION_DATA_UPDATE, self.refreshSelf, self)
	--军团申请者列表更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.APPLIERS_UPDATE, self.refreshSelf, self)
	--军团斗兽场信息更新导致刷新
	UnionManager.eventDispatcher:addEventListener(UnionManager.COLOSSEUM_DATA_UPDATE, self.refreshSelf, self)
	--有建筑升级成功
	UnionManager.eventDispatcher:addEventListener(UnionManager.EVENT_BUILDING_LEVELUP, onBuildingLevelup, self)

	--倒计时组件
	self.cdLabelComponent = CdLabelComponent:create()
	self.cdLabelComponent:setCallback(onTimeTick, onTimeComplete)


	--倒计时组件
	self.cdLabelComponentCross = CdLabelComponent:create()
	self.cdLabelComponentCross:setCallback(onTimeTickCross, onTimeCompleteCross)

	if UnionManager.isInBossAttackState() then
		--boss可以打
		ui:getChildByName("txt_guild_76"):setVisible(true)
		ui:getChildByName("txt_guild_75"):setVisible(true)
		ui:getChildByName("lbl_already_summon"):setVisible(true)
		ui:getChildByName("bg_guild_cityname"):setVisible(true)

		self.cdLabelComponent:setTargetTime(UnionManager.getColosseumMonsterRunTime())
		self.cdLabelComponent:start()

		--描边
		ui:getChildByName("txt_guild_75"):getChildByName("txt"):setColor(ccc3(80, 0, 0))
		ui:getChildByName("txt_guild_75"):getChildByName("txt"):setAroundColor(ccc3(255, 255, 255))

		ui:getChildByName("txt_guild_76"):getChildByName("txt"):setColor(ccc3(255, 0, 0))
		ui:getChildByName("txt_guild_76"):getChildByName("txt"):setAroundColor(ccc3(255, 255, 255))
	else
		--不能打
		ui:getChildByName("txt_guild_76"):setVisible(false)
		ui:getChildByName("txt_guild_75"):setVisible(false)
		ui:getChildByName("lbl_already_summon"):setVisible(false)
		ui:getChildByName("bg_guild_cityname"):setVisible(false)


		self.cdLabelComponent:dispose()
	end

    UnionManager.eventDispatcher:addEventListener(CrossUnionPkConsts.UNIONPK_TIMELEVEL_PASSED, onTimelevelUpdate, self)
    if CrossUnionPk.enabled() then
	    local timeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
	    CrossUnionPkTimeLevel.startup(timeLevel)
	    local Identity = UnionManager.getMyTitle()
	    local ResultName = CrossUnionPkCheck.AdjusetCountDown(timeLevel,Identity)
	    -- print("~~~~~~~~~~~~~~ResultName = "..ResultName)
	    self:SetCountUIText(ResultName)
    end
	self.refreshSelf()

	BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)

	--其他初始化操作
end

-----------------------------------------------内部接口------------------------------------------------------------
function UnionScene:SetCountUIText(resultName)
	-- local function getEndTime(timeLevel)
	-- 	local startTime, endTime = CrossUnionPkUtils.findTImeLevelStartAndEndTime(timeLevel)
	-- 	return 	endTime
	-- end
	-- CrossUnionPk.getEndTime(timeLevel)

	-- print("~~~~~~~~~~~~~~~~~~~~~resultName = "..tostringRich(resultName))
	-- print("~~~~~~~~~~~~~~~~~~~~~现在时间 = "..tostringRich(TimeUtil.formatTime(TimeUtil.getServerTimeSeconds())))

	CrossUnionPk.ResetLight()

	-- print("CrossUnionPkData.getCrossUnionWarLightOn() = "..tostringRich(CrossUnionPkData.getCrossUnionWarLightOn()))
	local TimeNum = nil
	
	if resultName == "HaveSignUp" or resultName == "MISSAPPLY" or resultName == nil or UnionManager.getGainCrossUnionWarInselfQuitCrossGvg() then
		self.CrossUnionBtnDisplay1:getChildByName("txt_guild_76"):setVisible(false)
		self.CrossUnionBtnDisplay1:getChildByName("bg_guild_cityname"):setVisible(false)
		if self.cdLabelComponentCross then 
			self.cdLabelComponentCross:dispose()
	    end
	elseif CrossUnionPk.enabled() then

		if resultName == "MEMBERAPPLY" and CrossUnionPkData.getCrossUnionWarLightOn() then
			TimeNum = CrossUnionPk.getEndTime(CrossUnionPkConsts.TIME_MEMBER_APPLY)
		elseif resultName == "ARMYAPPLY" and CrossUnionPkData.getCrossUnionWarLightOn() then--GROUPING
		    TimeNum = CrossUnionPk.getEndTime(CrossUnionPkConsts.TIME_ARMY_APPLY)
		elseif resultName == "GROUPING" then
		    TimeNum = CrossUnionPk.getEndTime(CrossUnionPkConsts.TIME_ARMY2_GROUP)
        end
    end
	
    
    if TimeNum then
    	local onTimeTickCross = self.onTimeTickCross
		local onTimeCompleteCross = self.onTimeCompleteCross
		self.cdLabelComponentCross:setCallback(onTimeTickCross, onTimeCompleteCross)
    	self.CrossUnionBtnDisplay1:getChildByName("txt_guild_76"):setVisible(true)
		self.CrossUnionBtnDisplay1:getChildByName("bg_guild_cityname"):setVisible(true)

	    self.cdLabelComponentCross:setTargetTime(TimeNum)
	    self.cdLabelComponentCross:start()
	else
		self.cdLabelComponentCross:dispose()
		self.CrossUnionBtnDisplay1:getChildByName("txt_guild_76"):setVisible(false)
		self.CrossUnionBtnDisplay1:getChildByName("bg_guild_cityname"):setVisible(false)
	end
end
-----------------------------------------------外部接口------------------------------------------------------------

function UnionScene:setTableViewsEnabled(enabled)
end

-----------------------------------------------进出场景动画------------------------------------------------------------
function UnionScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function UnionScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/background.mp3", true)
end

function UnionScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function enterActionFinished()
		--如果军团报名了就会给团员提示
	
         
     --    print("~~~~~~~~~~~~~~~~~~~~~~是否弹框 = "..tostringRich(UnionManager.getGainCrossUnionWarInapplyCrossGvgRemind() ))
	   
        local function SucceedResponse(evt)
        	-- print("~~~~~~~~~~~~~~~~~~~~弹框了")
	    	local function ToLook(evt)
		       CrossUnionPk.gotoCrossLoginUnionPkScene()
		    end
			
			if evt.data.applyCrossGvgRemind then
				local endTime = CrossUnionPk.getEndTime(CrossUnionPkConsts.TIME_MEMBER_APPLY)
		        local formatedTimeStr = TimeUtil.formatTime(endTime)
		        CanonMessageBox.showTextToLookBox(getTextByKey("WGVG_Detail29"), ToLook)
		        UnionManager.setGainCrossUnionWarInapplyCrossGvgRemind(false)
	        end
		end
	CrossUnionPkcrossGvgCanMindApplyRequest.sendRequestDefalut(SucceedResponse)
	self:nodeAnimationFinished()
	end

	--云雾动画
	local fspt = FlashSprite:create("map/others/flashPack/Cloud")
	fspt:changeAnimation(0)
	fspt:setLoop(false)
	local fspt_co = CocosObject.new(fspt)
	local function onCloudFlashAnimationEnd(anim)
		fspt:unregisterEndAnimationScriptHandler()
		self:removeChild(fspt_co)
		--Set_ShareData( "Cloud_Finished", 1 )
		self.fspt = nil;
	end
	self.fspt = fspt
	fspt:registerEndAnimationScriptHandler(onCloudFlashAnimationEnd)
	self:addChild(fspt_co)

	--放大的动画 动画过程禁止操作
	self.tempLayer:setScale(0.5)
	self.tempLayer.touchEnabled = false
	self.tempLayer.touchChildren = false
	local function scaleInFinished()
		self.tempLayer.touchEnabled = true
		self.tempLayer.touchChildren = true
		enterActionFinished()
	end
	local arr = CCArray:create()
	arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
	arr:addObject(CCCallFunc:create(scaleInFinished))
	self.tempLayer:runAction(CCSequence:create(arr))
end

function UnionScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function UnionScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function UnionScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)
end

function UnionScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))
end

function UnionScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景动画------------------------------------------------------------

-- 退出到外层
function UnionScene:back()
	self:replaceScene(MainMenuScene)
end

function UnionScene:dispose()
	--print("UnionScene:dispose")
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.EVENT_BUILDING_DATA_UPDATE, self.refreshSelf)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.EVENT_BASE_DATA_UPDATE, self.refreshSelf)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.EVENT_BUILDING_LEVELUP, onBuildingLevelup)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.EVENT_USER_UNION_DATA_UPDATE, self.refreshSelf)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.APPLIERS_UPDATE, self.refreshSelf)
	UnionManager.eventDispatcher:removeEventListener(UnionManager.COLOSSEUM_DATA_UPDATE, self.refreshSelf)
	UnionManager.eventDispatcher:removeEventListener(CrossUnionPkConsts.UNIONPK_TIMELEVEL_PASSED, onTimelevelUpdate)

	if self.cdLabelComponent then
		self.cdLabelComponent:dispose()
		self.cdLabelComponent = nil
	end
	if self.cdLabelComponentCross then
		self.cdLabelComponentCross:dispose()
		self.cdLabelComponentCross = nil
	end
    CrossUnionPkTimeLevel.clear()
	UnionScene.super.dispose(self)
end

function UnionScene:scaleIn()
end

-----------------------------------------------其他私有函数------------------------------------------------------------

--获得某个建筑的图标资源
function UnionScene:getBuildingIconById(buildingId)
	if buildingId == UnionManager.UNION_BUILDING_HALL then
		return self.hallBtnDisplay
	elseif buildingId == UnionManager.UNION_BUILDING_SHOP then
		return self.shopBtnDisplay
	elseif buildingId == UnionManager.UNION_BUILDING_BANK then
		return self.bankBtnDisplay
	elseif buildingId == UnionManager.UNION_BUILDING_COLOSSEUM then
		return self.colosseumBtnDisplay
	end

	--默认
	return self.hallBtnDisplay
end