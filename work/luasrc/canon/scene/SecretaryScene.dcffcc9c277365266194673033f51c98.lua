require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.scene.BaseUIScene"
require "canon.manager.BagCalcManager"

require "canon.scene.SkillEvolveScene"
require "canon.scene.CardComposeScene"
require "canon.scene.EquipUpgradeScene"
require "canon.scene.ArenaRankScene"
require "canon.scene.RobFragmentScene"
require "canon.scene.ChapterMapScene"
require "canon.scene.BackpackScene"
require "canon.scene.FriendScene"
require "canon.scene.GachaScene"
require "canon.panel.MainActorPanel"
require "canon.request.ActiveRewardRequest"
require "canon.customUI.CanonGoodIcon" 
require "canon.scene.ChallengeEntersScene"
require "canon.panel.DailyActivityRewardPanel"
require "canon.manager.UnionManager"
require "canon.scene.AchievementScene"
require "canon.scene.MedalShopScene"
require "canon.request.GetMedalShopListRequest"

--请到 SecretaryScene:initLimitLev() 添加任务id对应限制等级，这个表现在只是用来看的。 2015/9/7 l1ghtsaber
LEVEL_LIMIT_IDS = table.const{
  BEBEL_TOWER = 11,
  UNION = 19,
  SPIRIT = 23,
  RETREA = 24,
  TREASURE = 25
}
local limitLev = {}

local PARTICLE_TAG = 1234

SecretaryScene = class(BaseUIScene)
local visibleSize = CCSizeMake(720, 1280)

function SecretaryScene:ctor()
  self.__FLAG = "SecretaryScene"
  self.title = getTextByKey("activity_daily_title")
  self.isDailyTaskTableViewOnShow = nil
  self.isDailyRewardTableViewOnShow = nil
end

function SecretaryScene:create( argv )
	-- body
	if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end

	local scene = SecretaryScene.new()
  self.ignoreAction = self.argv.params.ignoreAction
    scene:initScene()
    return scene
end

function SecretaryScene:initLimitLev()
  limitLev[11] = MetaManager.getNewBabelSettings().unlockLevel
  limitLev[19] = UnionManager.unionMinLevel()
  limitLev[23] = DataManager.GameMetaData.spiritSettingConfig.unlockLevel
  limitLev[24] = DataManager.GameMetaData.treasureSettingConfig.unlockLevel
  limitLev[25] = DataManager.GameMetaData.treasureSettingConfig.unlockLevel
end

function SecretaryScene:sortTaskInfo()
  local activeConifgItems = DataManager.GameMetaData.dailyActiveConfig.activeConfigItems
  local taskNotFinishedTable = {}
  local taskLimitedTable = {}
  local taskFinishedTable = {}

  --将任务拆成3分，好排序
  for k,v in pairs(activeConifgItems) do
    --print(k,v)
    if (limitLev[v.id] and limitLev[v.id] > DataManager.getCurrUser().level) then
      table.insert(taskLimitedTable , v)
    else
      local isFinded = false;
      for m,n in pairs(self.activeTaskCounterList) do
        if(v.id == n.taskId) then
          isFinded = true;
          if(n.num >= v.conditionNum) then 
            table.insert(taskFinishedTable , v)
          else
            table.insert(taskNotFinishedTable , v)
          end
        end
      end
      if( not isFinded) then
        table.insert(taskNotFinishedTable , v)
      end
    end
  end
  local function taskSortFunc( a,b )
    return a.id < b.id
  end

  table.sort(taskNotFinishedTable , taskSortFunc)
  table.sort(taskLimitedTable , taskSortFunc)
  table.sort(taskFinishedTable , taskSortFunc)

  self.activeConifgItemsAfterSort = {}
  for k,v in pairs(taskNotFinishedTable) do
    table.insert(self.activeConifgItemsAfterSort , v)
  end
  for k,v in pairs(taskLimitedTable) do
    table.insert(self.activeConifgItemsAfterSort , v)
  end
  for k,v in pairs(taskFinishedTable) do
    table.insert(self.activeConifgItemsAfterSort , v)
  end
end

function SecretaryScene:onInit()
	-- body
	BaseUIScene.initBackGround(self)
  
  --新UI加黑底
  local colorLayer = LayerColor:create()
  colorLayer:setOpacity(kDarkOpacity)
  colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(colorLayer)

	self.builder = LayoutBuilder:createWithContentsOfFile("scene/daily_activity.json")
	self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("daily_activity")
	self:addChild(self.mainUI)
	BaseUIScene.onInit(self)

  self.secretaryTips = self.argv.params.secretaryTips or 0
  self.dailyTargetTipNum = self.argv.params.dailyTargetTipNum or 0
  self:resetTipUI()

  --print("########################################")
  --print(table.serialize(self.argv.params.data.dailyActiveInfo.taskCounters))
  --print("########################################")

  self.activeTaskCounterList = self.argv.params.data.dailyActiveInfo.taskCounters

  self.activeRewardItems = DataManager.GameMetaData.dailyActiveConfig.activeRewardItems
  self.gainedRewards = self.argv.params.data.dailyActiveInfo.gainedRewards
  self.totalActiveGet = self.argv.params.data.dailyActiveInfo.activeValue
  self.sunIconInitPositionX = self.mainUI:getChildByName("bg_daily_activity_progress"):getChildByName("icon_sun"):getPositionX()

  self:initLimitLev()
  self:sortTaskInfo()

  for k,v in pairs(self.activeTaskCounterList) do
    --print(k,v)
    if(17 == v.taskId) then
      HeMemDataHolder:setString("buyEnergyTimes", tostring(v.num))
    elseif(18 == v.taskId) then
      HeMemDataHolder:setString("buyEventPointTimes", tostring(v.num))
    end
  end

  local function onClickDailyActiveTaskButton(  )
    -- body
    if( self.isAcrossDay == true) then
      self:refreshWhenAcrossTheDay()
      do return end
    end
    self:ShowDailyTaskTableView(  ) 
  end

  local function onClickDailyActiveRewardButton(  )
    -- body
    if( self.isAcrossDay == true) then
      self:refreshWhenAcrossTheDay()
      do return end
    end
    self.targetInfoPanel = DailyActivityRewardPanel:create(self, self.activeRewardItems , self.gainedRewards , self.totalActiveGet)
    PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false, self)
    -- self:ShowDailyRewardTableView(  ) 
  end

  -- self.mainUI:getChildByName("btn_tab_activity1"):getChildByName("icn_tixing_kong"):setVisible(false)
  -- self.mainUI:getChildByName("btn_tab_activity1"):getChildByName("txt2"):setVisible(false)
  self.dailyActiveTaskButton = Button:create(self.mainUI:getChildByName("btn_tab_activity1"))
  self.dailyActiveTaskButton:addEventListener(Events.kStart,onClickDailyActiveTaskButton)
  self.mainUI:getChildByName("btn_tab_activity1"):getChildByName("txt"):setString(getTextByKey("activity_daily_title1"))
  
  local function onClickAchievementButton()
    self.ignoreAction = true
    self:replaceScene(AchievementScene, {enterScene="SecretaryScene",returnScene=nil,params={ignoreAction = true , secretaryTips = self.secretaryTips}})
  end
  
  local function onClickDailyActiveTargetButton()
    local function onAfterSucceed( evt )
      self.ignoreAction = true
      local argv = {enterScene=nil,returnScene=nil,params={data = evt.data, ignoreAction = true , secretaryTips = self.secretaryTips}}
      self:replaceScene(DailyTargetScene,argv)
    end
    GetDailyAchieveInfoRequest.sendRequestDefalut(onAfterSucceed)
  end
  
  local aTipNum = AchievementScene.getTipNum()
  if aTipNum > 0 then
    self.mainUI:getChildByName("btn_tab_activity2"):getChildByName("icn_tixing_kong"):setVisible(true)
    self.mainUI:getChildByName("btn_tab_activity2"):getChildByName("txt2"):setVisible(true)
    self.mainUI:getChildByName("btn_tab_activity2"):getChildByName("txt2"):setString(tostring(aTipNum))
  else
    self.mainUI:getChildByName("btn_tab_activity2"):getChildByName("icn_tixing_kong"):setVisible(false)
    self.mainUI:getChildByName("btn_tab_activity2"):getChildByName("txt2"):setVisible(false)
  end
  self.dailyActiveRewardButton = Button:create(self.mainUI:getChildByName("btn_tab_activity2"))
  self.dailyActiveRewardButton:addEventListener(Events.kStart,onClickAchievementButton)
  self.mainUI:getChildByName("btn_tab_activity2"):getChildByName("txt"):setString(getTextByKey("achieve_task_title"))

  --每日目标按钮
  self.dailyActiveTargetButton = Button:create(self.mainUI:getChildByName("btn_tab_activity3"))
  self.dailyActiveTargetButton:addEventListener(Events.kStart,onClickDailyActiveTargetButton)
  self.mainUI:getChildByName("btn_tab_activity3"):getChildByName("txt"):setString(getTextByKey("activity_dailytask_title"))--每日目标
  self.mainUI:getChildByName("btn_tab_activity3"):getChildByName("icn_tixing_kong"):setVisible(false)
  self.mainUI:getChildByName("btn_tab_activity3"):getChildByName("txt2"):setVisible(false)
  self.mainUI:getChildByName("btn_tab_activity3"):getChildByName("btn_arena_active"):setVisible(false)

  if DailyTargetScene.getTipNum() > 0 then
    self.mainUI:getChildByName("btn_tab_activity3"):getChildByName("icn_tixing_kong"):setVisible(true)
    self.mainUI:getChildByName("btn_tab_activity3"):getChildByName("txt2"):setVisible(true)
    self.mainUI:getChildByName("btn_tab_activity3"):getChildByName("txt2"):setString(tostring(DailyTargetScene.getTipNum()))
  else
    self.mainUI:getChildByName("btn_tab_activity3"):getChildByName("icn_tixing_kong"):setVisible(false)
    self.mainUI:getChildByName("btn_tab_activity3"):getChildByName("txt2"):setVisible(false)
  end

  self.dailyActiveRewardButton2 = Button:create(self.mainUI:getChildByName("btn_yellow_short"))
  self.dailyActiveRewardButton2:addEventListener(Events.kStart,onClickDailyActiveRewardButton)
  self.mainUI:getChildByName("btn_yellow_short"):getChildByName("txt"):setString(getTextByKey("activity_daily_active"))

  self.mainUI:getChildByName("txt_daily_activity3"):getChildByName("txt"):setString(getTextByKey("activity_daily_txt"))

  self.mainUI:getChildByName("bg_guide_win"):getChildByName("txt"):setString(getTextByKey("activity_daily_shoptext2")..DataManager.getMedalNum())
  self.mainUI:getChildByName("lottery_bg_red"):getChildByName("txt"):setString(getTextByKey("activity_daily_shopicon"))
  local function onClickMedalShop()
    local function getMedalShopList(evt)
      local argv = {
        enterScene = nil,
        returnScene = nil,
        params = {
          medalList = evt.data.itemIdList
        }
      }
      self:replaceScene(MedalShopScene, argv)
    end
    GetMedalShopListRequest.sendRequestDefalut(getMedalShopList)
  end
  local medalShopBtn = Button:create(self.mainUI:getChildByName("lottery_bg_red"))
  medalShopBtn:addEventListener(Events.kStart,onClickMedalShop)

  local function addParticle(parentBtn)
      local rewardParticle = CCParticleSystemQuad:create(ParticlePathConstants.FxStarline)
        rewardParticle:setPositionType(kCCPositionTypeRelative)
        rewardParticle:setPosition(ccp(0, 0))
        rewardParticle:setTag(PARTICLE_TAG)
        parentBtn:addChild(CocosObject.new(rewardParticle), 1000)
        local particleMoveArray = CCArray:create()
        local particleMoveTime = 0.4
        particleMoveArray:addObject(CCMoveBy:create(particleMoveTime*2, ccp(168.2, 0)))
        particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, -69.6)))
        particleMoveArray:addObject(CCMoveBy:create(particleMoveTime*2, ccp(-168.2, 0)))
        particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, 69.6)))
        rewardParticle:runAction(CCRepeatForever:create(CCSequence:create(particleMoveArray)))
        return rewardParticle
  end 

  --定期更新时间
  local function timeTick(ee)
    --print("定期更新时间: " .. self.currentTime)
     -- print("定期更新时间2: " .. TimeUtil.getServerTimeSeconds())
    -- print("标准时间:"..TimeUtil.formatTime(TimeUtil.getServerTimeSeconds()))
    local b = TimeUtil.whetherSwitchDay(self.currentTime)
    -- self.isAcrossDay = true
    --print(b)
    --print(type(b))
    if b then
      --跨天了
      --print("self.aInfoPanel: " .. table.tostring(self.aInfoPanel))--不能打印太大的內容

      --重新记录当前时间
      self.currentTime = TimeUtil.getServerTimeSeconds()

      self.isAcrossDay = true

    end
  end

  self.particle = addParticle(self.mainUI:getChildByName("btn_yellow_short"))
  self.particle:setVisible(false)

  --self:RefreshActiveUI()

  self:ShowDailyTaskTableView()

  self.currentTime = TimeUtil.getServerTimeSeconds()
  self.onCrossDayUpdateFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(timeTick,15,false);
end

function SecretaryScene:addParticle(  )
  -- body
  if(self.isDailyRewardTableViewOnShow == true) then
    self.particle:setVisible(false)
    do return end
  end
  local activeRewardItems = DataManager.GameMetaData.dailyActiveConfig.activeRewardItems
  local activeCanReward = {}
  for i=1,#activeRewardItems do
    if(self.totalActiveGet >= activeRewardItems[i].activeValue) then
      table.insert(activeCanReward , activeRewardItems[i].id)
    end
  end
  --print(table.tostring(self.gainedRewards))
  if(#activeCanReward > #self.gainedRewards) then
    self.particle:setVisible(true)
  else
    self.particle:setVisible(false)
  end
end

function SecretaryScene:RefreshActiveUI()
  local activeConifgItems = DataManager.GameMetaData.dailyActiveConfig.activeConfigItems
  local activeRewardItems = DataManager.GameMetaData.dailyActiveConfig.activeRewardItems
  local activeNeedToReward = 0
  for i=1,#activeRewardItems do
    if(self.totalActiveGet < activeRewardItems[i].activeValue) then
      activeNeedToReward = activeRewardItems[i].activeValue - self.totalActiveGet
      break
    end
  end

  self:addParticle()

  local txtDailyActiveToReward = Localization:getInstance():getText("activity_daily_reward" , {num1 = activeNeedToReward})

  self.mainUI:getChildByName("txt_daily_actixity1"):getChildByName("txt"):setString(txtDailyActiveToReward)

  

  local totalActive = 0
  for k,v in pairs(activeConifgItems) do
    totalActive = totalActive + v.activeValue
  end

  local txtDailyActivePercent = Localization:getInstance():getText("activity_daily_value2" , {num1 = self.totalActiveGet , num2 = totalActive})
  self.mainUI:getChildByName("txt_daily_activity2"):getChildByName("txt"):setString(txtDailyActivePercent)

  if (not self.activeProcessBar ) then
    self.activeProcessBar = ProgressBar:create(self.mainUI:getChildByName("bg_daily_activity_progress"):getChildByName("icon_playerExp"))
  end

  local percent = (self.totalActiveGet) * 100 / totalActive
  self.activeProcessBar:setPercentage(percent)

  self.SunIcon = self.mainUI:getChildByName("bg_daily_activity_progress"):getChildByName("icon_sun")
  local sunStartPosX = self.sunIconInitPositionX
  local sunEndPosLength = 236
  local sunNewPosX = (percent / 100) * sunEndPosLength + sunStartPosX
  self.SunIcon:setPositionX(sunNewPosX)

  end

function SecretaryScene:ShowDailyTaskTableView(  )
  if (self.isDailyTaskTableViewOnShow == true) then
    do return end
  end

  self.dailyActiveRewardButton2:setVisible(true)

  self.mainUI:getChildByName("btn_tab_activity1"):getChildByName("btn_arena_active"):setVisible(true)
  self.mainUI:getChildByName("btn_tab_activity1"):getChildByName("btn_arena_disable"):setVisible(false)
  self.mainUI:getChildByName("btn_tab_activity2"):getChildByName("btn_arena_active"):setVisible(false)
  self.mainUI:getChildByName("btn_tab_activity2"):getChildByName("btn_arena_disable"):setVisible(true)

  if not self.taskTableView then
    self.taskTableView = self:createDailyTaskTableView(self.activeConifgItemsAfterSort , self.activeTaskCounterList)
    self.mainUI:addChild(self.taskTableView)
    self.taskTableView:setVisible(false)
  end

  local function onShowFinish()
    self:setTableViewsEnabled(true)
  end
  
  local function onDisappearFinish()
    ViewControlUtil.showTableViewAction(self.taskTableView, visibleSize, onShowFinish)
  end

  self:setTableViewsEnabled(false)
  
  if( self.isDailyTaskTableViewOnShow == nil) then
    onDisappearFinish()
  else
    ViewControlUtil.disappearTableViewAction(self.rewardTableView, visibleSize, onDisappearFinish)
  end

  self.isDailyTaskTableViewOnShow = true
  self.isDailyRewardTableViewOnShow = false

  self:RefreshActiveUI()
end

function SecretaryScene:ShowDailyRewardTableView(  ) 
  if (self.isDailyRewardTableViewOnShow == true) then
    do return end
  end

  self.dailyActiveRewardButton2:setVisible(false)

  self.mainUI:getChildByName("btn_tab_activity1"):getChildByName("btn_arena_active"):setVisible(false)
  self.mainUI:getChildByName("btn_tab_activity1"):getChildByName("btn_arena_disable"):setVisible(true)
  self.mainUI:getChildByName("btn_tab_activity2"):getChildByName("btn_arena_active"):setVisible(true)
  self.mainUI:getChildByName("btn_tab_activity2"):getChildByName("btn_arena_disable"):setVisible(false)

  if not self.rewardTableView then
    self.rewardTableView = self:createDailyRewardTableView(self.activeRewardItems , self.gainedRewards , self.totalActiveGet)
    self.mainUI:addChild(self.rewardTableView)
    self.rewardTableView:setVisible(false)
  end

  local function onShowFinish()
    self:setTableViewsEnabled(true)
  end
  local function onDisappearFinish()
    ViewControlUtil.showTableViewAction(self.rewardTableView, visibleSize, onShowFinish)
  end

  self:setTableViewsEnabled(false)
  
  if( self.isDailyTaskTableViewOnShow == nil) then
    onDisappearFinish()
  else
    ViewControlUtil.disappearTableViewAction(self.taskTableView, visibleSize, onDisappearFinish)
  end

  self.isDailyTaskTableViewOnShow = false
  self.isDailyRewardTableViewOnShow = true

  self:RefreshActiveUI()
end

function SecretaryScene:afterRewardSuccessed( rewardID )
  -- if(self.isDailyRewardTableViewOnShow == true) then

  --   self.mainUI:removeChild(self.rewardTableView ,true)
    -- table.insert(self.gainedRewards , rewardID)
    --print("################"..table.serialize(self.gainedRewards))
    -- self.rewardTableView = self:createDailyRewardTableView(self.activeRewardItems , self.gainedRewards , self.totalActiveGet)
    -- self.mainUI:addChild(self.rewardTableView)
  -- end
end

function SecretaryScene:refreshWhenAcrossTheDay()
  local function getDailyActiveInfoSucceedResponse( evt )
  -- body
    SuspensionLabel:showContent(self, getTextByKey("activity_daily_txt1"))
    -- local argv = {enterScene=nil,returnScene=nil,params={data = evt.data}}
    -- self:replaceScene(SecretaryScene,argv);
    -- 这里应该是需要删掉这两个key值
    HeMemDataHolder:setString("buyEnergyTimes", tostring(0))
    HeMemDataHolder:setString("buyEventPointTimes", tostring(0))

    self.activeTaskCounterList = evt.data.dailyActiveInfo.taskCounters
    self.activeRewardItems = DataManager.GameMetaData.dailyActiveConfig.activeRewardItems
    self.gainedRewards = evt.data.dailyActiveInfo.gainedRewards
    self.totalActiveGet = evt.data.dailyActiveInfo.activeValue

    self:sortTaskInfo()
    self:RefreshActiveUI()

    local isVisible = self.taskTableView:isVisible()
    local touchEnable = self.taskTableView.refCocosObj:isTouchEnabled()
    self.mainUI:removeChild(self.taskTableView ,true)
    self.taskTableView = self:createDailyTaskTableView(self.activeConifgItemsAfterSort , self.activeTaskCounterList)
    self.taskTableView:setVisible(isVisible)
    self.taskTableView:setTouchEnabled(touchEnable)
    self.mainUI:addChild(self.taskTableView)

    if ( self.rewardTableView ) then
      isVisible = self.rewardTableView:isVisible()
      touchEnable = self.rewardTableView.refCocosObj:isTouchEnabled()
      self.mainUI:removeChild(self.rewardTableView ,true)
      self.rewardTableView = self:createDailyRewardTableView(self.activeRewardItems , self.gainedRewards , self.totalActiveGet)
      self.rewardTableView:setVisible(isVisible)
      self.rewardTableView:setTouchEnabled(touchEnable)
      self.mainUI:addChild(self.rewardTableView)
    end

    self.isAcrossDay = false
    
    end

  local function getDailyActiveInfoFailedResponse( evt )
    --print(table.serialize(evt.data))
    -- body
  end

    local request = GetDailyActiveInfoRequest.new( {}, rpc.SendingPriority.kHigh )
    request:addEventListener( RequestNotifyEnum.GetDailyActiveInfoSucceed, getDailyActiveInfoSucceedResponse )
    request:addEventListener( RequestNotifyEnum.GetDailyActiveInfoFailed, getDailyActiveInfoFailedResponse )
    request:start()
  end

function SecretaryScene:afterBuyEnerySuccessed(  )
  -- body
  local buyEnergyTimesNum = tonumber( HeMemDataHolder:getString("buyEnergyTimes") )
  if (not buyEnergyTimesNum) then
    buyEnergyTimesNum = 0
  end
  buyEnergyTimesNum = buyEnergyTimesNum  + 1
  HeMemDataHolder:setString("buyEnergyTimes", tostring(buyEnergyTimesNum))
  local isVisible = self.taskTableView:isVisible()
  local touchEnable = self.taskTableView.refCocosObj:isTouchEnabled()
  self.mainUI:removeChild(self.taskTableView ,true)

  local isFinded = false
  for k,v in pairs(self.activeTaskCounterList) do
    if(v.taskId == 17) then
      isFinded = true
      v.num = buyEnergyTimesNum
    end
  end
  if (not  isFinded ) then
    local v = {taskId = 17 , num = buyEnergyTimesNum}
    table.insert(self.activeTaskCounterList , v)
  end

  self:sortTaskInfo()

  self.taskTableView = self:createDailyTaskTableView(self.activeConifgItemsAfterSort , self.activeTaskCounterList)
  self.taskTableView:setVisible(isVisible)
  self.taskTableView:setTouchEnabled(touchEnable)
  self.mainUI:addChild(self.taskTableView)
  --self.taskTableView:reloadData()

  for k,v in pairs(self.activeConifgItemsAfterSort) do
    if(v.id == 17) then
      if(buyEnergyTimesNum - 1 < v.conditionNum and buyEnergyTimesNum >= v.conditionNum) then
        self.totalActiveGet = self.totalActiveGet + v.activeValue
        self:RefreshActiveUI()
      end
    end
  end
end

function SecretaryScene:afterBuyEventPointSuccessed(  )
  -- body
  local buyEventPointTimesNum = tonumber( HeMemDataHolder:getString("buyEventPointTimes") )
  if (not buyEventPointTimesNum) then
    buyEventPointTimesNum = 0
  end
  buyEventPointTimesNum = buyEventPointTimesNum  + 1
  HeMemDataHolder:setString("buyEventPointTimes", tostring(buyEventPointTimesNum))
  --self.taskTableView:reloadData()
  local isVisible = self.taskTableView:isVisible()
  local touchEnable = self.taskTableView.refCocosObj:isTouchEnabled()
  self.mainUI:removeChild(self.taskTableView ,true)

  local isFinded = false
  for k,v in pairs(self.activeTaskCounterList) do
    if(v.taskId == 18) then
      isFinded = true
      v.num = buyEventPointTimesNum
    end
  end
  if (not  isFinded ) then
    local v = {taskId = 18 , num = buyEventPointTimesNum}
    table.insert(self.activeTaskCounterList,v)
  end

  self:sortTaskInfo()

  self.taskTableView = self:createDailyTaskTableView(self.activeConifgItemsAfterSort , self.activeTaskCounterList)
  self.taskTableView:setVisible(isVisible)
  self.taskTableView:setTouchEnabled(touchEnable)
  self.mainUI:addChild(self.taskTableView)

  for k,v in pairs(self.activeConifgItemsAfterSort) do
    if(v.id == 18) then
      if(buyEventPointTimesNum - 1 < v.conditionNum and buyEventPointTimesNum >= v.conditionNum) then
        self.totalActiveGet = self.totalActiveGet + v.activeValue
        self:RefreshActiveUI()
      end
    end
  end
end

local TABLEVIEW_CELL_TAG = -1001

local TAG_BUTTON_MOVE_TO_SCENE = 1001
local TAG_TXT_DETAIL = 1002
local TAG_TXT_ACTIVE_GET = 1003
local TAG_ALREADY_FINISHED = 1004
local TAG_TXT_NOT_OPEN = 1005
local TAG_BUTTON_REWARD = 1006
local TAG_TXT_REWARDED = 1007
local TAG_BUTTON_ABLE = 1008
local TAG_BUTTON_DISABLE = 1009
local TAG_BG_YELLOW_PANEL = 1010
local TAG_BG_HUA_WEN = 1011
local TAG_BG_WHITE_PANEL = 1012
local TAG_REAWRD_ITEM = 1013
local TAG_ICON_SUN = 1014
local TAG_ICON_ITEM = 1015
local TAG_ICON_ITEM_BORDER = 1016
local TAG_BUTTON_REWARD_DISABLE = 1017

function SecretaryScene:createDailyTaskTableView( data , activeTaskCounterList)
  -- body
  local SecretarySceneRenderer = class(TableViewRenderer)
  local fatherContainer = self
  function SecretarySceneRenderer:ctor(width, height)
    -- body
    self.list = data
    local builder = LayoutBuilder:createWithContentsOfFile("scene/daily_activity.json")
    builder.useArtLabelTTF = true
    self.builder = builder
  end

  function SecretarySceneRenderer:buildCell(container)
    local cell = self.builder:build("list_daily_activity_quest")
    cell:setPosition(ccp(0, 0))   
    cell:setTag(TABLEVIEW_CELL_TAG)
    container:addChild(cell)

    cell:getChildByName("yellow9_panel"):setTag(TAG_BG_YELLOW_PANEL)
    cell:getChildByName("txt_saily_activity6"):setTag(TAG_TXT_DETAIL)
    cell:getChildByName("txt_saily_activity6"):getChildByName("txt"):setTag(TAG_TXT_DETAIL)
    cell:getChildByName("txt_saily_activity7"):setTag(TAG_TXT_ACTIVE_GET)
    cell:getChildByName("txt_saily_activity7"):getChildByName("txt"):setTag(TAG_TXT_ACTIVE_GET)
    cell:getChildByName("ibl_completed"):setTag(TAG_ALREADY_FINISHED)
    cell:getChildByName("ibl_completed"):setVisible(false)
    cell:getChildByName("txt_saily_activity4"):setTag(TAG_TXT_NOT_OPEN)
    cell:getChildByName("txt_saily_activity4"):getChildByName("txt"):setTag(TAG_TXT_NOT_OPEN)
    cell:getChildByName("txt_saily_activity4"):setVisible(false)
    cell:getChildByName("txt_saily_activity4"):getChildByName("txt"):setString(getTextByKey("activity_daily_level"))
    cell:getChildByName("txt_saily_activity5"):setVisible(false)
    cell:getChildByName("btn_go"):setTag(TAG_BUTTON_MOVE_TO_SCENE)
    cell:getChildByName("btn_go"):getChildByName("txt"):setTag(TAG_BUTTON_MOVE_TO_SCENE)
    cell:getChildByName("btn_go"):getChildByName("txt"):setString(getTextByKey("activity_daily_go"))
    cell:getChildByName("btn_go"):setVisible(true)
    cell:getChildByName("btn_go_disable"):setVisible(false)

  end

  local function setTextByTag( cell, tag, str)
    local txt = cell:getChildByTag(tag):getChildByTag(tag)
    setNodeText(txt, str);
  end

  local function setNodeVisibleByTag(cell, tag, visible)
    cell:getChildByTag(tag):setVisible(visible)
  end

  function SecretarySceneRenderer:setData(rawCocosObj,index)
    local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)

    local finishedTimes = 0
    for k,v in pairs(activeTaskCounterList) do
      if(data[index + 1].id == v.taskId) then
        local num 

        if (17 == v.taskId) then
          num = tonumber( HeMemDataHolder:getString("buyEnergyTimes") )
        elseif (18 == v.taskId) then
          num = tonumber( HeMemDataHolder:getString("buyEventPointTimes") )
        else
          num = v.num
        end

        finishedTimes = num
        if(finishedTimes > data[index + 1].conditionNum) then
          finishedTimes = data[index + 1].conditionNum
        end
      end
    end


    local taskDetails = Localization:getInstance():getText("activity_daily_type"..data[index + 1].id , {num1 = finishedTimes , num2 = data[index + 1].conditionNum})
    setTextByTag(cell , TAG_TXT_DETAIL , taskDetails);
    setTextByTag(cell , TAG_TXT_ACTIVE_GET , "+"..data[index + 1].activeValue)
    
    setNodeVisibleByTag(cell , TAG_ALREADY_FINISHED , false)
    setNodeVisibleByTag(cell , TAG_BUTTON_MOVE_TO_SCENE , true)
    setNodeVisibleByTag(cell , TAG_TXT_NOT_OPEN , false)

    --通天塔
    if (limitLev[data[index + 1].id] and limitLev[data[index + 1].id] > DataManager.getCurrUser().level) then
        setNodeVisibleByTag(cell , TAG_ALREADY_FINISHED , false)
        setNodeVisibleByTag(cell , TAG_BUTTON_MOVE_TO_SCENE , false)
        setNodeVisibleByTag(cell , TAG_TXT_NOT_OPEN , true)
    else
      for k,v in pairs(activeTaskCounterList) do
        if(data[index + 1].id == v.taskId) then
          local num 
          if (17 == v.taskId) then
            num = tonumber( HeMemDataHolder:getString("buyEnergyTimes") )
            --print("aaaaaaaaaaaaaaaaa"..num)
          elseif (18 == v.taskId) then
              num = tonumber( HeMemDataHolder:getString("buyEventPointTimes") )
          else
              num = v.num
          end
          if num < data[index + 1].conditionNum then
            setNodeVisibleByTag(cell , TAG_ALREADY_FINISHED , false)
            setNodeVisibleByTag(cell , TAG_BUTTON_MOVE_TO_SCENE , true)
          else
            setNodeVisibleByTag(cell , TAG_BG_YELLOW_PANEL , false)
            setNodeVisibleByTag(cell , TAG_ALREADY_FINISHED , true)
            setNodeVisibleByTag(cell , TAG_BUTTON_MOVE_TO_SCENE , false)
          end
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
    local selectedCell = self.taskTableView:cellAtIndex(evt.data):getChildByTag(TABLEVIEW_CELL_TAG)

    local sceneID = self.activeConifgItemsAfterSort[evt.data + 1].id
    
    local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
      local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_BUTTON_MOVE_TO_SCENE):getPosition()
      local itemRect = {}
      itemRect.x = itemPosX
      itemRect.y = itemPosY - 66
      itemRect.width = 168
      itemRect.height = 66
      if inArea(posInCell.x, posInCell.y, itemRect) then
        if selectedCell:getChildByTag(TAG_BUTTON_MOVE_TO_SCENE) then
          if selectedCell:getChildByTag(TAG_BUTTON_MOVE_TO_SCENE):isVisible() then
            if( fatherContainer.isAcrossDay == true) then
              fatherContainer:refreshWhenAcrossTheDay()
              do return end
            end
            if sceneID == 1 then
              self:replaceScene(CardQueueScene,{enterScene=nil,returnScene=nil,params={}})
            elseif sceneID == 2 then
              --self:replaceScene(CardComposeScene,{enterScene=nil,returnScene=nil,params={}})
              self:replaceScene(CardQueueScene)
            elseif sceneID == 3 then
              self:replaceScene(BackpackScene,{params = {isCardTrain = false, tabIndex = BAGCATEGORY.equip}})
            elseif sceneID == 4 then
              --self:replaceScene(BackpackScene,{params = {isCardTrain = true}})
              self:replaceScene(CardQueueScene)
            elseif sceneID == 5 or sceneID == 6 then
              self:replaceScene(FriendScene)
            elseif sceneID == 7 then
              self:replaceToArena()
            elseif sceneID == 8 then
              self:callFuncBeforeSceneChange(
                function()
                  local function doPrerationSucceed(fragmentsInfo)
                    local argv = {enterScene="MainMenuScene",returnScene="MainMenuScene",params={fragmentsInfo=fragmentsInfo}}
                    self:replaceScene(BeastScene, argv)
                  end
        
                  local function doPrerationFailed()
                    self.isChangeingScene = false
                  end
        
                  BeastScene.doPreparationBeforeReplaceToBeastScene(doPrerationSucceed, doPrerationFailed)
                end
                )
              --self:replaceScene(BeastScene)--bug
            elseif sceneID == 9 then
              self:replaceScene(ChapterMapScene)
            elseif sceneID == 10 then
              if(EliteManager.isUnlockElite()) then
                self:replaceScene(EliteMissionScene)
              else
                self:replaceScene(ChallengeEntersScene)
              end
            elseif sceneID == 11 then
              self:replaceScene(ChallengeEntersScene, {params = {showPanelName = "skytower"}})
            elseif sceneID == 12 then
              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_EatPeach"})
            elseif sceneID == 13 then
              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_WorldBoss"})
            elseif sceneID == 14 then
              self:replaceScene(BackpackScene,{params = {tabIndex = BAGCATEGORY.item}})
            elseif sceneID == 15 then
              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_SignIn"})
              --15是登录,跨天签到
            elseif sceneID == 16 then
              self:replaceScene(GachaScene)
            elseif sceneID == 17 or sceneID == 18 then
              self.targetInfoPanel = MainActorPanel:create( self )
              PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)  
              --self.taskTableView:setTouchEnabled(v)
            -- elseif sceneID == 19 then
            --   self:replaceScene(MainMenuScene)
            elseif sceneID == 19 then
              if UnionManager.ennabled(true) then
                UnionManager.gotoUnionScene()
              end
            elseif sceneID == 20 then
              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_Pray"})
            elseif sceneID == 21 then
              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_Wanted"})
            elseif sceneID == 22 then
              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_Question"})
            elseif sceneID == 23 then
              local destinyInfo = DataManager.getGameInitData().sharkDestinyInfo
              if destinyInfo and destinyInfo.spiritConcentrateLevel > 0 then
                self:replaceScene( KingTempleScene )
              else
                self:replaceScene( DestinyFightChallengeScene )
              end    
            elseif sceneID == 24 then
              self:replaceScene(CardRebirthScene)
            elseif sceneID == 25 then
              self:replaceScene(TreasureBackpackScene)
            end        
          end
        end
        do return end
      else
        
      end
  end

  local cell_height = 120
  local list_height = 523.5 + 36
  local list_posY = 222 - 27

  local renderer = SecretarySceneRenderer.new(BAGCONFIG.WIDTH, cell_height)
  local list = TableView:create(renderer, BAGCONFIG.WIDTH, list_height, TABLEVIEW_CELL_TAG,TAG_BUTTON_MOVE_TO_SCENE)

  list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  list:setPosition(ccp(12, list_posY))
  return list
end

function SecretaryScene:createDailyRewardTableView(data , gainedRewards , activeValueGet)
  local SecretarySceneRenderer = class(TableViewRenderer)
  local fatherContainer = self
  function SecretarySceneRenderer:ctor(width, height)
    -- body
    self.list = data
    local builder = LayoutBuilder:createWithContentsOfFile("scene/daily_activity.json")
    builder.useArtLabelTTF = true
    self.builder = builder
  end

  function SecretarySceneRenderer:buildCell(container)
    local cell = self.builder:build("list_daily_activity_quest")
    cell:setPosition(ccp(0, 0))   
    cell:setTag(TABLEVIEW_CELL_TAG)
    container:addChild(cell)

    cell:getChildByName("white9_panel"):setTag(TAG_BG_YELLOW_PANEL)
    cell:getChildByName("txt_saily_activity6"):setTag(TAG_TXT_DETAIL)
    cell:getChildByName("txt_saily_activity6"):getChildByName("txt"):setTag(TAG_TXT_DETAIL)
    cell:getChildByName("txt_saily_activity7"):setTag(TAG_TXT_ACTIVE_GET)
    cell:getChildByName("txt_saily_activity7"):getChildByName("txt"):setTag(TAG_TXT_ACTIVE_GET)
    cell:getChildByName("ibl_completed"):setTag(TAG_ALREADY_FINISHED)
    cell:getChildByName("ibl_completed"):setVisible(false)
    cell:getChildByName("txt_saily_activity5"):setTag(TAG_TXT_REWARDED)
    cell:getChildByName("txt_saily_activity5"):getChildByName("txt"):setTag(TAG_TXT_REWARDED)
    cell:getChildByName("txt_saily_activity5"):getChildByName("txt"):setString(getTextByKey("activity_daily_receive"))
    cell:getChildByName("txt_saily_activity5"):setVisible(false)
    cell:getChildByName("txt_saily_activity4"):setVisible(false)
    cell:getChildByName("btn_go"):setTag(TAG_BUTTON_REWARD)
    cell:getChildByName("btn_go"):getChildByName("txt"):setTag(TAG_BUTTON_REWARD)
    --cell:getChildByName("btn_go"):getChildByName("btn"):setTag(TAG_BUTTON_ABLE)
    --cell:getChildByName("btn_go"):getChildByName("btn_disable"):setTag(TAG_BUTTON_DISABLE)
    cell:getChildByName("btn_go"):getChildByName("txt"):setString(getTextByKey("activity_daily_get"))
    cell:getChildByName("btn_go"):setVisible(true)
    cell:getChildByName("huawen"):setTag(TAG_BG_HUA_WEN)
    cell:getChildByName("white9_panel"):setTag(TAG_BG_WHITE_PANEL)
    cell:getChildByName("icon_sun"):setTag(TAG_ICON_SUN)
    cell:getChildByName("icon_sun"):setVisible(false)
    cell:getChildByName("btn_go_disable"):setTag(TAG_BUTTON_REWARD_DISABLE)
    cell:getChildByName("btn_go_disable"):getChildByName("txt"):setTag(TAG_BUTTON_REWARD_DISABLE)
    cell:getChildByName("btn_go_disable"):getChildByName("txt"):setString(getTextByKey("activity_daily_get"))
    cell:getChildByName("btn_go_disable"):setVisible(false)

  end

  local function setTextByTag( cell, tag, str)
    local txt = cell:getChildByTag(tag):getChildByTag(tag)
    setNodeText(txt, str);
  end

  local function setNodeVisibleByTag(cell, tag, visible)
    cell:getChildByTag(tag):setVisible(visible)
  end

  local function getPackageReward( id )
    -- body
    local packageRewardList = MetaManager.getRewardInfoByID(id) or {}
    if(#packageRewardList == 0) then
      return nil
    end
    return packageRewardList[1]

  end

  local function replaceItemIcon( cell, index , posX , posY )

    local aRewardNameString
    local aBorder = cell:getChildByTag(TAG_ICON_ITEM_BORDER)
    if aBorder then
      aBorder:removeFromParentAndCleanup(true)
    end

    local icon = cell:getChildByTag(TAG_ICON_ITEM)
    if icon then
      icon:removeFromParentAndCleanup(true)
    end

    local packageList = getPackageReward(data[index].rewardPackageId)

    if(packageList == nil) then
      do return end
    end

    local itemType = packageList.itemType
    local id = packageList.metaId
    local amount = packageList.amount
    

    -- if ( itemType == 5) then
    --   icon = getHeadIconCanonCardByMetaId(id)
    --   icon:setScale(0.7)
    --   aRewardNameString = Localization:getInstance():getText(MetaManager.card_meta[id].name) .. "x" .. amount
    -- elseif (itemType == 6) or (itemType == 7) then
    --   icon = CanonItem:create()
    --   icon:loadByMetaId(id)
    --   icon:setScale(0.6)
    --   if itemType == 6 then
    --     aRewardNameString = Localization:getInstance():getText(MetaManager.equip_meta[id].name) .. "x" .. amount
    --   end
    --   if itemType == 7 then
    --     aRewardNameString = Localization:getInstance():getText(MetaManager.prop_meta[id].name) .. "x" .. amount
    --   end
    -- elseif ( itemType == 1) then
    --   icon = Sprite:create("common/CoinIcon_Mission.png")
    --   icon:setScale(0.7)
    --   aBorder = Sprite:create("Item/border/equipBorder1.png")
    --   aBorder:setScale(0.7)
    --   aRewardNameString = Localization:getInstance():getText("resource_silverCoin") .. "x" .. amount
    -- elseif itemType == 2 then
    --   icon = Sprite:create("common/GemIcon_Mission.png")
    --   icon:setScale(0.7)
    --   aBorder = Sprite:create("Item/border/equipBorder1.png")
    --   aBorder:setScale(0.7)
    --   aRewardNameString = Localization:getInstance():getText("resource_goldCoin") .. "x" .. amount
    -- end
    
    local params = {}
    params.positions = {posX , posY}
    params.sourceSizes = {80,80}
    params.isShowStar = false--显示稀有度星星
    params.container = cell
    params.zindex = 10

    local icon = CanonGoodIcon.createFirstGoodIconByPackageReward(data[index].rewardPackageId, params)
    local name = CanonGoodIcon.getFirstGoodNameByPackageReward(data[index].rewardPackageId, params)
    if icon then
      icon:setTag(TAG_ICON_ITEM)
      icon:dispose()
    end

    if(not icon) then
      do return end
    end

    -- icon:setPosition( ccp(posX , posY) )
    -- cell:addChild(icon.refCocosObj, 10)
    -- icon:setTag(TAG_ICON_ITEM)
    -- icon:dispose()

    -- if aBorder then
    --   aBorder:setPosition( ccp(posX , posY) )
    --   cell:addChild(aBorder.refCocosObj, 10)
    --   aBorder:setTag(TAG_ICON_ITEM_BORDER)
    --   aBorder:dispose()
    -- end

    setTextByTag(cell , TAG_TXT_ACTIVE_GET , name)

  end

  function SecretarySceneRenderer:setData(rawCocosObj,index)
    local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)
    setTextByTag(cell , TAG_TXT_DETAIL , getTextByKey("activity_daily_value") .. data[index + 1].activeValue)
    --setTextByTag(cell , TAG_TXT_ACTIVE_GET , "x"..1)

    local itemPosX, itemPosY = cell:getChildByTag(TAG_ICON_SUN):getPosition()
    local itemSize = cell:getChildByTag(TAG_ICON_SUN):getContentSize()
    local zOrder = cell:getChildByTag(TAG_ICON_SUN):getZOrder()
    if cell:getChildByTag(TAG_REAWRD_ITEM) then
      cell:removeChildByTag(TAG_REAWRD_ITEM, true)
    end

    replaceItemIcon(cell , index + 1 , itemPosX + itemSize.width / 2 - 20, itemPosY - itemSize.height / 2 + 5)
      
    local canonItem = CanonItem:create()
    canonItem:loadByMetaId(data[index + 1].rewardPackageId)
    canonItem:setPosition(ccp(itemPosX, itemPosY))
    canonItem:setTag(TAG_REAWRD_ITEM)
    cell:addChild(canonItem.refCocosObj, zOrder)
    canonItem:dispose();

    setNodeVisibleByTag(cell , TAG_TXT_REWARDED , false)
    setNodeVisibleByTag(cell , TAG_BUTTON_REWARD , true)
    --setNodeVisibleByTag(cell , TAG_TXT_NOT_OPEN , false)

    local isGained = false
    for k,v in pairs(gainedRewards) do
      if(data[index + 1].id == v) then
        --cell:setVisible(false)
        -- cell:getChildByTag(TAG_BG_HUA_WEN):setColor(ccc3(127, 127, 127))
        -- cell:getChildByTag(TAG_BG_WHITE_PANEL):setColor(ccc3(127, 127, 127))
        -- cell:getChildByTag(TAG_BG_YELLOW_PANEL):setColor(ccc3(127, 127, 127))

        setNodeVisibleByTag(cell , TAG_BG_YELLOW_PANEL , false)
        setNodeVisibleByTag(cell , TAG_TXT_REWARDED , true)
        setNodeVisibleByTag(cell , TAG_BUTTON_REWARD , false)
        cell:getChildByTag(TAG_BUTTON_REWARD_DISABLE):setVisible(false)
        isGained = true
      
      end
    end
    if(not isGained) then
      setNodeVisibleByTag(cell , TAG_BG_YELLOW_PANEL , true)
      if(activeValueGet < data[index + 1].activeValue) then
          setNodeVisibleByTag(cell , TAG_TXT_REWARDED , false)
          setNodeVisibleByTag(cell , TAG_BUTTON_REWARD , true)
          cell:getChildByTag(TAG_BUTTON_REWARD_DISABLE):setVisible(true)
          cell:getChildByTag(TAG_BUTTON_REWARD):setVisible(false)
      else
          setNodeVisibleByTag(cell , TAG_TXT_REWARDED , false)
          setNodeVisibleByTag(cell , TAG_BUTTON_REWARD , true)
          cell:getChildByTag(TAG_BUTTON_REWARD_DISABLE):setVisible(false)
          cell:getChildByTag(TAG_BUTTON_REWARD):setVisible(true)
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
    local selectedCell = self.rewardTableView:cellAtIndex(evt.data):getChildByTag(TABLEVIEW_CELL_TAG)

    if(selectedCell:getChildByTag(TAG_BUTTON_REWARD_DISABLE):isVisible()) then
      do return end
    end
    if(selectedCell:getChildByTag(TAG_BUTTON_REWARD):isVisible()) then
      local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
      local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_BUTTON_REWARD):getPosition()
      local itemRect = {}
      itemRect.x = itemPosX
      itemRect.y = itemPosY - 66
      itemRect.width = 168
      itemRect.height = 66

      self.touchItemIndex = evt.data + 1

      local function doPlayAfterRewardSucceed( evt )
        -- body
        local function onGet(  )
          -- body
          RewardManager:getReward(evt)
        end
        
        local aRewardPanel = RewardReviewPanel:create( fatherContainer, {rewardList = evt, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), callback = onGet} )
        fatherContainer:addChild(aRewardPanel)
        aRewardPanel:scaleIn()

      end

      local function activeRewardSucceedResponse( evt )
        -- body 获取奖励成功，更新数据
        --print(self.touchItemIndex.."activeRewardSucceedResponse:"..table.serialize(evt.data))
        fatherContainer:afterRewardSuccessed(self.touchItemIndex)
        doPlayAfterRewardSucceed(evt.data.rewards)
        
      end

      local function activeRewardFailedResponse( evt )
        --fatherContainer:afterRewardSuccessed(self.touchItemIndex)
        -- body
        --print("领取失败")
        if ( evt.data.retCode == 710516) then
          NewPackageFullPanel:show()
          -- CanonMessageBox:Show( getTextByKey("shop_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ) --"您的背包已满，请清理背包。"
        elseif (evt.data.retCode == 716254) then
          fatherContainer:refreshWhenAcrossTheDay()
          if (TimeUtil.whetherSwitchDay(self.currentTime)) then
            self.currentTime = TimeUtil.getServerTimeSeconds()
          end
        end
      end

      if inArea(posInCell.x, posInCell.y, itemRect) then
        if( fatherContainer.isAcrossDay == true) then
          fatherContainer:refreshWhenAcrossTheDay()
          do return end
        end
        --print("LALALALLALA:"..evt.data)
        local params = {activeRewardId = evt.data + 1}
        local request = ActiveRewardRequest.new( params, rpc.SendingPriority.kHigh )
        request:addEventListener( RequestNotifyEnum.ActiveRewardSucceed, activeRewardSucceedResponse )
        request:addEventListener( RequestNotifyEnum.ActiveRewardFailed, activeRewardFailedResponse )
        request:start()
      end
    end

  end

  local cell_height = 120
  local list_height = 529.5
  local list_posY = 980

  local renderer = SecretarySceneRenderer.new(BAGCONFIG.WIDTH, cell_height)
  local list = TableView:create(renderer, BAGCONFIG.WIDTH, list_height, TABLEVIEW_CELL_TAG,TAG_BUTTON_REWARD)

  list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  list:setPosition(ccp(12, 215))
  return list
end


function SecretaryScene:setTableViewsEnabledInner(v)
  if self.taskTableView then
    self.taskTableView:setTouchEnabled(v)
  end
end

function SecretaryScene:dispose()
  print("SecretaryScene:dispose!!!!!!")
  if (self.onCrossDayUpdateFunc) then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onCrossDayUpdateFunc)
  end
	BaseUIScene.dispose(self)
end

function SecretaryScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function SecretaryScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function SecretaryScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    print("enterActionFinished 1! os.clock() = " .. os.clock())
    self:nodeAnimationFinished()
  end
  --[[
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
  ]]
  
  for _, aChild in pairs(self.mainUI.list) do
    if not (self.ignoreAction and (aChild.name == "btn_tab_activity1" or aChild.name == "btn_tab_activity2" or aChild.name == "btn_tab_activity3")) then
      aChild:setPositionX(aChild:getPositionX() - visibleSize.width)
      local arr = CCArray:create()
      arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
      arr:addObject(CCCallFunc:create(enterActionFinished))
      aChild:runAction(CCSequence:create(arr))
    end
  end
  
	ViewControlUtil.showTableViewAction(self.taskTableView, visibleSize)
end

function SecretaryScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function SecretaryScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function SecretaryScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function SecretaryScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    --print("enterActionFinished 2! os.clock() = " .. os.clock())
      self:nodeAnimationFinished()
  end
  --[[
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
  ]]
  
  if self.mainUI.list then
    --print("#self.mainUI.list = " .. tostringRich(#self.mainUI.list))
    local funcAdded = false
    for _, aChild in pairs(self.mainUI.list) do
      if not (self.ignoreAction and (aChild.name == "btn_tab_activity1" or aChild.name == "btn_tab_activity2" or aChild.name == "btn_tab_activity3")) then
        local arr = CCArray:create()
        arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
        if not funcAdded then
          arr:addObject(CCCallFunc:create(enterActionFinished))
          funcAdded = true
        end
        aChild:runAction(CCSequence:create(arr))
      end
    end
    
    if(self.isDailyTaskTableViewOnShow) then
      ViewControlUtil.disappearTableViewAction(self.taskTableView, visibleSize)
    else
      ViewControlUtil.disappearTableViewAction(self.rewardTableView, visibleSize)
    end
  end
  
	
end

function SecretaryScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function SecretaryScene:back()
  self.ignoreAction = false
	self:replaceScene(MainMenuScene)
	
end

function SecretaryScene:setTableViewsEnabled( v )
  if (v) then
    self.touchDisableSetTimes = self.touchDisableSetTimes - 1
    if (self.touchDisableSetTimes <= 0) then
      if self.isDailyTaskTableViewOnShow  then
        if self.taskTableView then
          self.taskTableView:setTouchEnabled(v)
        end
      end
      if (self.isDailyRewardTableViewOnShow) then
        if self.rewardTableView then
          self.rewardTableView:setTouchEnabled(v)
        end
      end
      self.mainUI:setTouchEnabled(v)
    end
  else
    self.touchDisableSetTimes = self.touchDisableSetTimes + 1
    if self.isDailyTaskTableViewOnShow  then
        if self.taskTableView then
          self.taskTableView:setTouchEnabled(v)
        end
      end
      if (self.isDailyRewardTableViewOnShow) then
        if self.rewardTableView then
          self.rewardTableView:setTouchEnabled(v)
        end
      end
    self.mainUI:setTouchEnabled(v)
  end
end

function SecretaryScene:resetTipUI()
  local aTipNum = (g_homeInfo and g_homeInfo.enableGainDailyActiveRewardNum or 0)
  --print("YOYOQIEKENAO"..self.secretaryTips)
  if aTipNum > 0 then
    self.mainUI:getChildByName("btn_tab_activity1"):getChildByName("icn_tixing_kong"):setVisible(true)
    self.mainUI:getChildByName("btn_tab_activity1"):getChildByName("txt2"):setVisible(true)
    self.mainUI:getChildByName("btn_tab_activity1"):getChildByName("txt2"):setString(tostring(aTipNum))
  else
    self.mainUI:getChildByName("btn_tab_activity1"):getChildByName("icn_tixing_kong"):setVisible(false)
    self.mainUI:getChildByName("btn_tab_activity1"):getChildByName("txt2"):setVisible(false)
  end
end