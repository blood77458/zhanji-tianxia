-- CrossUnionPKBlessingScene.lua
-- meilan.xie
-- 2015-5-4
-- Gvg 祝福天师
require "canon.features.crossUnionPk.panel.CrossUnionRewardPreviewPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local enter_animation_duration = 0.3

CrossUnionPKBlessingScene = class(BaseUIScene)

--跨天事件  零点的自动更新
local function onPassDay(evt)
  local self = evt.context
  local function SucceedResponse(evt)
      --获取祝福帝王的个人信息
      -- argv.data = evt.data
    if evt.data.canBlessTimes > 0 then
      self:BtnStatus(true)
    end
        
  end
  CrossUnionPkGetBlessInFoRequest.sendRequestDefalut(SucceedResponse)
  
end
--焦点变化事件
local function onFocusChanged(evt)
  -- evt.context:setTableViewTouched(evt.data == nil)
end
--时间段更新事件
local function onTimelevelUpdate(evt)
  local self = evt.context
  local TimeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
  if TimeLevel ~=  CrossUnionPkConsts.TIME_WORSHIP then
    CrossUnionPk.gotoCrossLoginUnionPkScene()
  end
end

function CrossUnionPKBlessingScene:ctor()
end

function CrossUnionPKBlessingScene.clear()
end
function CrossUnionPKBlessingScene:create(argv)
	local s = CrossUnionPKBlessingScene.new()
	if argv then 
		s.argv = argv 
	else
		s.argv = {enterScene=nil,returnScene=nil,params={}}
	end
	s.curSceneEnum = SceneEnum.CrossUnionPKBlessingScene

	--当前显示中的列表内容(注意: 子panel可能读取)
	s.selectedDataList = {}
	s:initScene()
	return s
end
--点击返回
local function onBackBtnClick(evt)
  local self = evt.context
  self:back()
end


--点击问号
local function onQaBtnClick(evt)
  local self = evt.context
  -- self:setTableViewsEnabled(false)
  --ReNameCoolingPanel
  local aInfoPanel = ActivityInfoPanel:create(self, getTextByKey("WGVG_Detail44"))
  self:addChild(aInfoPanel)
  aInfoPanel:scaleIn()
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~打开问号按钮")
end

function CrossUnionPKBlessingScene:BtnUnVisableStatus(adjude)
    self.ui:getChildByName("btn_bles_big"):getChildByName("normal"):setVisible(adjude)
end 

function CrossUnionPKBlessingScene:AlterText(txt,Times)
    --txt_Gvg_09_3
    self.ui:getChildByName("txt_Gvg_09_3"):getChildByName("txt"):setString(getTextByKey(txt,{time = Times}))
end

function CrossUnionPKBlessingScene:UnionBtnStatus(adjude1,adjude2,text) -- 按钮置灰判断   按钮可点击判断  
  self:BtnUnVisableStatus(adjude1)
  self.BlesButton:setEnable(adjude2)
  self.ui:getChildByName("btn_bles_big"):getChildByName("txt"):setString(getTextByKey(text))--设置按钮上面的文字
end

function CrossUnionPKBlessingScene:BtnStatus(adj)
  self.BlesButton:setEnable(adj)
  self.ui:getChildByName("btn_bles_big"):getChildByName("normal"):setVisible(adj)
end

--点击祝福
local function onBlesBtnClick(evt)
  local self = evt.context
  local nameId = UnionManager.getMyTitle()
  -- self:ApplyDemand(nameId)
  
  if BagCalcManager.isFull() then
    NewPackageFullPanel:show()
    return
  end
  local function SucceedResponse(evt)
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~点击祝福= "..tostringRich(evt.data))
    --要领取奖励 可能要弹奖励面板
    RewardManager:getReward(evt.data.rewards)
    local aRewardPanel = RewardReviewPanel:create( self, {rewardList = evt.data.rewards, rewardTitle = Localization:getInstance():getText("WGVG_Detail61")} )
    self:addChild(aRewardPanel)
    aRewardPanel:scaleIn()
    -- print("~~~~~~~~~~~~~~~~~Reward = "..tostringRich(evt.data.rewards))
    -- self.BlesButton:setEnable(false)
    -- self.ui:getChildByName("btn_bles_big"):getChildByName("normal"):setVisible(false)
    self:BtnStatus(false)

  end

  CrossUnionPkGetBlessRequest.sendRequestDefalut(SucceedResponse)
end


--点击奖励
local function onRewardBtnClick(evt)
  local self = evt.context
  if BagCalcManager.isFull() then
    NewPackageFullPanel:show()
    return
  end
  local function SucceedResponse(evt)
    --要领取奖励 可能要弹奖励面板
    local txtName = nil
    if evt.data.rank == 1 then
      txtName = "WGVG_Name18"
    elseif evt.data.rank == 2 then
      txtName = "WGVG_Name19"
    elseif evt.data.rank == 3 then
      txtName = "WGVG_Name20"
    elseif evt.data.rank == 4 then
      txtName = "WGVG_Name22"
    elseif evt.data.rank == 8 then
      txtName = "WGVG_Name23"
    elseif evt.data.rank == 16 then
      txtName = "WGVG_Name24"
    end
    RewardManager:getReward(evt.data.rewards)
    local aRewardPanel = RewardReviewPanel:create( self, {rewardList = evt.data.rewards, rewardTitle = Localization:getInstance():getText(txtName)} )
    self:addChild(aRewardPanel)
    aRewardPanel:scaleIn()
    -- print("~~~~~~~~~~~~~~~~~Reward = "..tostringRich(evt.data.rewards))
    -- self.BlesButton:setEnable(false)
    -- self.ui:getChildByName("btn_bles_big"):getChildByName("normal"):setVisible(false)
    self.RewardButton:setEnable(false)
    self.ui:getChildByName("icon_Gvg_reward"):setVisible(false)


  end
  CrossUnionPkGetKnockoutReward.sendRequestDefalut(SucceedResponse)
  --
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~点击奖励")
end

--点击激战回顾
local function onWarReviewBtnClick(evt)
  local self = evt.context
  CrossUnionPk.gotoKnockoutScene()
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~点击激战回顾")
end

--点击半身像
local function onKingBtnClick(evt)
  local self = evt.context
  
  CrossArena.gotoUserFormationScene(self.argv.data.kingUid, nil, nil,"CrossUnionPKBlessingScene")
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~点击任务半身像")
end

function CrossUnionPKBlessingScene:onInit()
	BaseUIScene.initBackGround(self)
  local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("GvG_bles")
	self:addChild(ui)
	self.ui = ui

  local titleUI = builder:build("Gvg_colosseuml_title")
	self.titleUI = titleUI
	self.titleUI:setPositionY(visibleSize.height-35)
	self:addChild(titleUI)
  

  self.titleUI:getChildByName("icon_gold"):setVisible(false)
  self.titleUI:getChildByName("icon_silverCoin"):setVisible(false)
  -- icon_Gvg_ranking
  self.titleUI:getChildByName("icon_Gvg_ranking"):setVisible(false)
  self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_22"):setVisible(false)
  self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_21"):setVisible(false)
  self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_08"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail71"))
  
  
  self.fullCard = CanonFullCard:create(self.ui:getChildByName("bigCard"))
  self.fullCard:setScale(2.25)
  -- self.fullCard:setScaleY(2)
  --显示卡牌大图
  self.fullCard:setCard(self.argv.data.mainCardMetaId)
  --卡牌大图点击事件

  local cardIcon2 = Button:create(self.fullCard)
  cardIcon2:addEventListener(Events.kStart,onKingBtnClick, self)
  --txt_Gvg_02
  --军团名
  self.ui:getChildByName("txt_Gvg_02"):getChildByName("txt"):setString("["..self.argv.data.unionName.."]")
  --几区
  self.ui:getChildByName("txt_Gvg_01"):getChildByName("txt"):setString(getTextByKey("login_serverNo", {num = self.argv.data.serverId})..":")
  --军团长union_major_text_key
  self.ui:getChildByName("txt_Gvg_03"):getChildByName("txt"):setString(getTextByKey("union_major_text_key"))
  self.ui:getChildByName("txt_Gvg_03"):getChildByName("txt"):setColor(ccc3(255, 246, 125))
  self.ui:getChildByName("txt_Gvg_03"):getChildByName("txt"):setAroundColor(ccc3(56, 51, 100))
  --团长名
  self.ui:getChildByName("txt_Gvg_04"):getChildByName("txt"):setString(" : "..self.argv.data.nickname)
  self.ui:getChildByName("txt_Gvg_04"):getChildByName("txt"):setColor(ccc3(255, 246, 125))
  self.ui:getChildByName("txt_Gvg_04"):getChildByName("txt"):setAroundColor(ccc3(56, 51, 100))
  
  --按钮
  --返回按钮
  local backButton = Button:create(self.titleUI:getChildByName("r_click"))
  backButton:addEventListener(Events.kStart, onBackBtnClick, self)
  --问号按钮
  local qaButton = Button:create(self.titleUI:getChildByName("sky_btn_qa"))
  qaButton:addEventListener(Events.kStart, onQaBtnClick, self)
  --祝福按钮
  --WGVG_Name12
  local TextName = nil
  if self.argv.data.king then
    TextName = "WGVG_Name15"
    -- WGVG_Detail32
    self.ui:getChildByName("txt_Gvg_05"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail32",{number = self.argv.data.blessNum}))
  else
    TextName = "WGVG_Name12"
  --祝福次数

  self.ui:getChildByName("txt_Gvg_06"):getChildByName("txt"):setString(self.argv.data.blessNum)
  --次祝福
  self.ui:getChildByName("txt_Gvg_07"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail42"))
  end
  local BlessUIName = self.ui:getChildByName("btn_bles_big")
  BlessUIName:getChildByName("txt"):setString(getTextByKey(TextName))
  self.BlesButton = Button:create(BlessUIName)
  self.BlesButton:addEventListener(Events.kStart, onBlesBtnClick, self)
  -- print("~~~~~~~~~~~~~~~~~剩余祝福次数 = "..tostringRich(self.argv.data.canBlessTimes))
  if self.argv.data.canBlessTimes <= 0 then
    self:BtnStatus(false)
  -- else
  --   BtnStatus(true)
  end
  --奖励按钮
  self.RewardButton = Button:create(self.ui:getChildByName("icon_Gvg_reward"))
  self.RewardButton:addEventListener(Events.kStart, onRewardBtnClick, self)
  if not UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() or not self.argv.data.promotion or self.argv.data.gainGvgKnockoutReward then --是否报名
    self.RewardButton:setEnable(false)
    self.ui:getChildByName("icon_Gvg_reward"):setVisible(false)
  end  
  --激战回顾按钮
  local WarReviewButton = Button:create(self.ui:getChildByName("icon_Gvg_review")) --激战回顾
  WarReviewButton:addEventListener(Events.kStart, onWarReviewBtnClick, self)
  UnionManager.eventDispatcher:addEventListener(CrossUnionPkConsts.UNIONPK_TIMELEVEL_PASSED, onTimelevelUpdate, self)
   --事件侦听
  UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
  NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)
  local TimeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
  CrossUnionPkTimeLevel.startup(TimeLevel)
 
  BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)
end




function CrossUnionPKBlessingScene:dispose()
  UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
  UnionManager.eventDispatcher:removeEventListener(CrossUnionPkConsts.UNIONPK_TIMELEVEL_PASSED, onTimelevelUpdate)
  NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
  CrossUnionPkTimeLevel.clear()
  CrossUnionPKBlessingScene.clear()
  CrossUnionPKBlessingScene.super.dispose(self)
end

function CrossUnionPKBlessingScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function CrossUnionPKBlessingScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  
end

function CrossUnionPKBlessingScene:startEnterAnimation()
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

function CrossUnionPKBlessingScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
end

function CrossUnionPKBlessingScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function CrossUnionPKBlessingScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  
end

function CrossUnionPKBlessingScene:startExitAnimation()
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

function CrossUnionPKBlessingScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function CrossUnionPKBlessingScene:back()
  if self.argv.enterScene == "UnionScene" then
  
    UnionManager.gotoUnionScene()
  end
end
