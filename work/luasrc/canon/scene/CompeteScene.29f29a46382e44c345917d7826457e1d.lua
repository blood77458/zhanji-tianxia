require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "hecore.ui.TableView"

require "canon.features.crossArena.manager.CrossArenaManager"
require "canon.features.crossArena.scene.CrossArenaChanllengeScene"
require "canon.features.crossArena.panel.CrossArenaRulePanel"

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local CompeteTypeEnum = 
{
  arena = 1,
  pk = 2,
  crossPk = 3,
  crossPVP = 4,
}

--
--CompeteScene
--

CompeteScene = class(BaseUIScene)

function CompeteScene:ctor()
end

function CompeteScene:create(argv)
  local s = CompeteScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  s:initScene()
  return s
end

function CompeteScene:onInit()
	BaseUIScene.initBackGround(self)
  --新UI加黑底
  local colorLayer = LayerColor:create()
  colorLayer:setOpacity(kDarkOpacity)
  colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(colorLayer)
  
  self.title = Localization:getInstance():getText("sports_sport_titile")
  
  self.builder = LayoutBuilder:createWithContentsOfFile("scene/compete_ollection.json")
  self.builder.useArtLabelTTF = true
  self.table_meta_info = getTableViewSizes(self.builder:build("table_combine_list"))
  self.table_meta_info.table_posX = 9
  self.table_meta_info.table_posY = 120
  if __IOS and isInAppleReview() then
    self.tableData = {CompeteTypeEnum.arena, CompeteTypeEnum.pk, CompeteTypeEnum.crossPk}
  else
    self.tableData = {CompeteTypeEnum.arena, CompeteTypeEnum.pk, CompeteTypeEnum.crossPk , CompeteTypeEnum.crossPVP}
  end
  
  self.tableView = self:createTableView()
  self:addChild(self.tableView)
  self.tableView:reloadData()
  
  BaseUIScene.onInit(self)
end

function CompeteScene:createTableView()
	local cellTag = 1024
	local buttonTag = {-20}
	local aScene = self
	local tableViewRenderer = class(TableViewRenderer)
	function tableViewRenderer:ctor(width, height)
		self.list = aScene.tableData or {}
	end
	function tableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/compete_ollection.json")
		local aCell = builder:build("btn_pk")
		container:addChild(aCell)
		aCell:setTag(cellTag)

    aCell:getChildByName("list_bg"):setVisible(false)
    
    local type1Group1 = aCell:getChildByName("txt_info")
    type1Group1:setTag(-10)
    type1Group1 = type1Group1:getChildByName("txt")
		type1Group1:setTag(-10)
    
    local type1Group2 = aCell:getChildByName("halfblack_new_l3")
    type1Group2:setTag(-11)
    
    local type1Group3 = aCell:getChildByName("halfblack_new_l4")
    type1Group3:setTag(-12)
    
    local type2Group1 = aCell:getChildByName("txt_getretime")
    type2Group1:setTag(-13)
    type2Group1 = type2Group1:getChildByName("txt")
		type2Group1:setTag(-10)
    
    local type2Group2 = aCell:getChildByName("txt_time")
    type2Group2:setTag(-14)
    type2Group2 = type2Group2:getChildByName("txt")
		type2Group2:setTag(-10)
    
    local type2Group3 = aCell:getChildByName("halfblack_new_l1")
    type2Group3:setTag(-15)
    
    local type2Group4 = aCell:getChildByName("halfblack_new_l2")
    type2Group4:setTag(-16)
    
    local bg1 = aCell:getChildByName("btn_arena_entrance")
    bg1:setTag(-17)
    
    local bg2 = aCell:getChildByName("pk_entrance_btn")
    bg2:setTag(-18)
    
    local bg3 = aCell:getChildByName("btn_acrossight_entrance")
    bg3:setTag(-19)

    local bg4 = aCell:getChildByName("sword_entrance_btn")
    bg4:setTag(-23)
    
    local infoBtnDisplay = aCell:getChildByName("sky_btn_qa")
    infoBtnDisplay:setTag(-20)
    
    local tipBg1 = aCell:getChildByName("bg_reward_rank")
    tipBg1:setTag(-21)
    
    local tipLabel1 = aCell:getChildByName("txt_compete_ollection_1")
    tipLabel1:setTag(-22)
    tipLabel1 = tipLabel1:getChildByName("txt")
    tipLabel1:setString(Localization:getInstance():getText("sports_crossserver_text1"))
		tipLabel1:setTag(-10)
	end

	function tableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
    
    local type1Group1 = aCell:getChildByTag(-10)
    local type1Group2 = aCell:getChildByTag(-11)
    local type1Group3 = aCell:getChildByTag(-12)
    local type2Group1 = aCell:getChildByTag(-13)
    local type2Group2 = aCell:getChildByTag(-14)
    local type2Group3 = aCell:getChildByTag(-15)
    local type2Group4 = aCell:getChildByTag(-16)
    local bg1 = aCell:getChildByTag(-17)
    local bg2 = aCell:getChildByTag(-18)
    local bg3 = aCell:getChildByTag(-19)
    local bg4 = aCell:getChildByTag(-23)
    local infoBtnDisplay = aCell:getChildByTag(-20)
    local tipBg1 = aCell:getChildByTag(-21)
    local tipLabel1 = aCell:getChildByTag(-22)
    type1Group1:setVisible(false)
    type1Group2:setVisible(false)
    type1Group3:setVisible(false)
    type2Group1:setVisible(false)
    type2Group2:setVisible(false)
    type2Group3:setVisible(false)
    type2Group4:setVisible(false)
    bg1:setVisible(false)
    bg2:setVisible(false)
    bg3:setVisible(false)
    bg4:setVisible(false)
    infoBtnDisplay:setVisible(false)
    tipBg1:setVisible(false)
    tipLabel1:setVisible(false)
    if aData == CompeteTypeEnum.arena then
      bg1:setVisible(true)
    elseif aData == CompeteTypeEnum.pk then
      if not AcrossFightManager.isPkOpen() then
        type1Group2:setVisible(true)
        type1Group3:setVisible(true)
        if DataManager.GameMetaData.pkSettingConfig then
          type1Group1:setVisible(true)
          local beginTime = MaintenanceManager:getStartAndEndTime(DataManager.GameMetaData.pkSettingConfig.featureNamePkSession)
          if beginTime and beginTime[1] then
            setNodeText(type1Group1:getChildByTag(-10), getTextByKey("pk_session_start") .. getTextByKey("pk_session_start1", {num1=beginTime[1].month, num2=beginTime[1].day, num3 = 0}))
          end
        end
      else
        type1Group1:setVisible(true)
        type1Group2:setVisible(true)
        type1Group3:setVisible(true)
        if AcrossFightManager.whetherInPkDoingTime() then
          setNodeText(type1Group1:getChildByTag(-10), getTextByKey("sports_pk_underway"))
          if AcrossFightManager.whetherCrossPkExistInServer() and not AcrossFightManager.isOpen() then
            local beginTime = TimeUtil.toServerTimestamp(AcrossFightManager.getNextCrossPkBeginTime())
            local currentTime = TimeUtil.getServerTimeSeconds()
            local timeStamp = beginTime - currentTime
            if timeStamp > 0  and timeStamp < 86400 * 7 then
              tipBg1:setVisible(true)
              tipLabel1:setVisible(true)
            end
          end
        else
          setNodeText(type1Group1:getChildByTag(-10), getTextByKey("sports_pk_reward"))
        end
      end
      bg2:setVisible(true)
    elseif aData == CompeteTypeEnum.crossPk then
      infoBtnDisplay:setVisible(true)
      if not AcrossFightManager.whetherCrossPkExistInServer() then
        type1Group1:setVisible(true)
        type1Group2:setVisible(true)
        type1Group3:setVisible(true)
        setNodeText(type1Group1:getChildByTag(-10), getTextByKey("sports_crossserver_close"))
      elseif not AcrossFightManager.isOpen() then
        type1Group2:setVisible(true)
        type1Group3:setVisible(true)
        if DataManager.GameMetaData.crossServerSettingConfig then
          type1Group1:setVisible(true)
          local beginTime = AcrossFightManager.getNextCrossPkBeginTime()
          setNodeText(type1Group1:getChildByTag(-10), getTextByKey("sports_pk_beginTime") .. getTextByKey("sports_pk_beginTime1", {num=beginTime.month, num2=beginTime.day, num3 = beginTime.hour}))
        end
      else
        type1Group1:setVisible(true)
        type1Group2:setVisible(true)
        type1Group3:setVisible(true)
        if AcrossFightManager.getCurrentTimeEnum() < AcrossFightTimeEnum.rewardTime then
          setNodeText(type1Group1:getChildByTag(-10), getTextByKey("sports_crossserver_underway"))
        else
          local rewardTime = AcrossFightManager.getCurrentCrossPkRewardTime()
          setNodeText(type1Group1:getChildByTag(-10), getTextByKey("sports_crossserver_reward", {num1 = rewardTime.num1, num2 = rewardTime.num2, num3 = rewardTime.num3, num4 = rewardTime.num4, num5 = rewardTime.num5, num6 = rewardTime.num6}))
        end
      end
      bg3:setVisible(true)
    elseif aData == CompeteTypeEnum.crossPVP then
        infoBtnDisplay:setVisible(true)
        bg1:setVisible(true)
        if not CrossArenaManager.checkPVPIsOpen() then
          type1Group1:setVisible(true)
          type1Group2:setVisible(true)
          type1Group3:setVisible(true)
          setNodeText(type1Group1:getChildByTag(-10), getTextByKey("crossArena_labelUnlockText2"))
        elseif DataManager.getCurrUser().level < CrossArenaManager.getCrossArenaSetting().unlockLevel then
          type1Group1:setVisible(true)
          type1Group2:setVisible(true)
          type1Group3:setVisible(true)
          setNodeText(type1Group1:getChildByTag(-10), getTextByKey("crossArena_labelUnlockText" , {num1 = CrossArenaManager.getCrossArenaSetting().unlockLevel}))
        elseif CrossArenaManager.getCurrentStage() == CrossPVP_Stage.Battle then
          type1Group1:setVisible(true)
          type1Group2:setVisible(true)
          type1Group3:setVisible(true)
          setNodeText(type1Group1:getChildByTag(-10), getTextByKey("crossArena_labelBattleText"))
        elseif CrossArenaManager.getCurrentStage() == CrossPVP_Stage.Reward then
          type1Group1:setVisible(true)
          type1Group2:setVisible(true)
          type1Group3:setVisible(true)
          setNodeText(type1Group1:getChildByTag(-10), getTextByKey("crossArena_labelRewardText"))
        end
        bg4:setVisible(true)
    end
    
	end


	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.tableView:cellAtIndex(aIndex - 1)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData = self.tableData[aIndex]
    local infoBtnDisplay = newCell:getChildByTag(cellTag):getChildByTag(-20)
    if infoBtnDisplay:isVisible() and
      posInCell.x > infoBtnDisplay:getPositionX() and
      posInCell.x < (infoBtnDisplay:getPositionX() + infoBtnDisplay:getContentSize().width) and
      posInCell.y > (infoBtnDisplay:getPositionY() - infoBtnDisplay:getContentSize().height) and
      posInCell.y < infoBtnDisplay:getPositionY() then
      if aIndex == CompeteTypeEnum.crossPk then 
        self:setTableViewsEnabled(false)
        local timeTable = AcrossFightManager.getCurrentOrNextCrossPkTimeTable()
        local aInfoPanel = ActivityInfoPanel:create(self, Localization:getInstance():getText("cross_explain_text", {num1 = timeTable[1].month, num2 = timeTable[1].day, num3 = timeTable[1].hour, num4 = timeTable[2].month, num5 = timeTable[2].day, num6 = timeTable[2].hour, num7 = timeTable[3].month, num8 = timeTable[3].day, num9 = timeTable[3].hour, num10 = timeTable[4].month, num11 = timeTable[4].day, num12 = timeTable[4].hour, num13 = timeTable[5].month, num14 = timeTable[5].day, num15 = timeTable[5].hour, num16 = timeTable[6].month, num17 = timeTable[6].day, num18 = timeTable[6].hour, num19 = timeTable[7].month, num20 = timeTable[7].day, num21 = timeTable[7].hour, num22 = timeTable[8].month, num23 = timeTable[8].day, num24 = timeTable[8].hour, num25 = timeTable[9].month, num26 = timeTable[9].day, num27 = timeTable[9].hour, num28 = timeTable[10].month, num29 = timeTable[10].day, num30 = timeTable[10].hour, num31 = timeTable[11].month, num32 = timeTable[11].day, num33 = timeTable[11].hour, num34 = timeTable[12].month, num35 = timeTable[12].day, num36 = timeTable[12].hour, num37 = timeTable[13].month, num38 = timeTable[13].day, num39 = timeTable[13].hour, num40 = timeTable[14].month, num41 = timeTable[14].day, num42 = timeTable[14].hour, num43 = timeTable[15].month, num44 = timeTable[15].day, num45 = timeTable[15].hour}))
        self:addChild(aInfoPanel)
        aInfoPanel:scaleIn()
      elseif aIndex == CompeteTypeEnum.crossPVP then  
        PopoutManager:sharedManager():popout(CrossArenaRulePanel:create(self, nil), kPopoutDir.kScale, true, false, self)
      end
    else
      self:buttonSelectedWithType(aData)
    end
	end

	local renderer = tableViewRenderer.new(self.table_meta_info.item_width, self.table_meta_info.item_height)
	local aTableView = TableView:create(renderer, self.table_meta_info.table_width, self.table_meta_info.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
	aTableView:setPosition(ccp(self.table_meta_info.table_posX, self.table_meta_info.table_posY))
  
	return aTableView
end

function CompeteScene:buttonSelectedWithType(aData)
  if aData == CompeteTypeEnum.arena then
    self:replaceToArena()
  elseif aData == CompeteTypeEnum.pk then
    if DataManager.GameMetaData.pkSettingConfig and DataManager.getCurrUser().level < DataManager.GameMetaData.pkSettingConfig.pkUnlockLevel then
      SuspensionLabel:showContent(self, getTextByKey("pk_level_limit"))
      return
    end
    self:replaceScene(PKScene)
  elseif aData == CompeteTypeEnum.crossPk then
    local crossServerSettingConfig = DataManager.GameMetaData.crossServerSettingConfig
    local whetherOpen, notInServer = AcrossFightManager.isOpen()
    if whetherOpen then
      if AcrossFightManager.getCurrentTimeEnum() ~= AcrossFightTimeEnum.notStart then
        local function successCallback()
          self:replaceScene(AcrossFightScene)
        end
        AcrossFightScene.enterScene(successCallback)
      end
    elseif notInServer then
      SuspensionLabel:showContent(self, getTextByKey("cross_pk_error"))
    end
  elseif aData == CompeteTypeEnum.crossPVP then
    if not CrossArenaManager.checkPVPIsOpen() then
      return
    elseif DataManager.getCurrUser().level < CrossArenaManager.getCrossArenaSetting().unlockLevel then
      return
    end
    --self:replaceScene(CrossArenaChanllengeScene) del by zheng.che 改成掉接口
    CrossArena.gotoCrossPvpScene(nil, nil)
  end
end

function CompeteScene:setTableViewsEnabledInner(isEnable)
  if self.tableView then
      self.tableView:setTouchEnabled(isEnable)
  end
end

function CompeteScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function CompeteScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function CompeteScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  ViewControlUtil.showTableViewAction(self.tableView, visibleSize, enterActionFinished)
end

function CompeteScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function CompeteScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function CompeteScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function CompeteScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
      self:nodeAnimationFinished()
  end
  
  ViewControlUtil.disappearTableViewAction(self.tableView, visibleSize, enterActionFinished)
end

function CompeteScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function CompeteScene:back()
	self:replaceScene(MainMenuScene)
	
end