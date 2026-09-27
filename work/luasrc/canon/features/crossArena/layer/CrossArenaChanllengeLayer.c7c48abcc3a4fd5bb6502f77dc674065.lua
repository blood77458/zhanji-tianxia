require "hecore.display.CocosObject"
require "hecore.display.Director"
require "canon.customUI.CanonGoodIcon"
require "canon.features.crossArena.manager.CrossArenaManager"

require "canon.features.crossArena.request.ChallengeCrossUserRequest"
require "canon.features.crossArena.request.RefreshMatchRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local function onPassDay(evt)
  local self = evt.context
  if self.mainUI.list == nil then--如果跨天并且进入领奖阶段，这个layer释放了，就return
    return
  end
  self:refreshWhenCrossDay()
  self.freeRefreshTimestamp = 0
  self:refreshRefreshButton()
end

CrossArenaChanllengeLayer = class(Layer)

function CrossArenaChanllengeLayer:ctor()
  self.container = nil
end

function CrossArenaChanllengeLayer:create( container , sceneId, currentTabIndex)
  local s = CrossArenaChanllengeLayer.new()
  s.container = container
  s.extraArgs = extraArgsr
  s.sceneId = sceneId
  s.currentTabIndex = currentTabIndex
  s:initLayer()
  return s
end

function CrossArenaChanllengeLayer:dispose()
  NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
	CrossArenaChanllengeLayer.super.dispose(self)
  if self.cdLabelComponent then
    self.cdLabelComponent:stop()
    self.cdLabelComponent = nil
  end
end

function CrossArenaChanllengeLayer:panelDismiss()
  self.container.targetInfoPanel = nil
end

function CrossArenaChanllengeLayer:refreshChanllgeList()
  local battleList = self.mainUI:getChildByName("list_jj")
  if self.matchList == nil then
    battleList:setVisible(false)
    return
  end
  for k,v in pairs(self.matchList) do
    --每个挑战者的信息

    --点击头像
    local function onHeadClick(evt)
      --进入玩家队列
      --print("v = " .. tostringRich(v))
      CrossArena.gotoUserFormationScene(v.uid, self.sceneId, self.currentTabIndex)
    end

    local item = battleList:getChildByName("list_jj_"..k)

    if item.heroIcon then
      --删除原头像和点击事件
      item.headBtn:dispose()
      item.heroIcon:removeFromParentAndCleanup(true)
    end

    local sourceDisplay = item:getChildByName("card_normal_card_small_sb_upR")
    sourceDisplay:setVisible(false)
    sourceDisplay.touchEnabled = false
    sourceDisplay.touchChildren = false

    item.heroIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, v.metaId, 1, {sourceDisplay = sourceDisplay , showInCenter = true})
    item:addChildAt(item.heroIcon, sourceDisplay:getZOrder())

    item.headBtn = Button:create(item.heroIcon)
    item.headBtn:addEventListener(Events.kStart, onHeadClick)

    item:getChildByName("txt_jj_35"):getChildByName("txt"):setString(getTextByKey("crossArena_battleRank2")..v.rank)
    item:getChildByName("txt_jj_36"):getChildByName("txt"):setString(v.nickName)
    item:getChildByName("txt_jj_37"):getChildByName("txt"):setString("["..v.server.."]"..getTextByKey("crossBoss_serverSuffix"))
    item:getChildByName("txt_jj_40"):getChildByName("txt"):setString(getTextByKey("crossArena_battleScore"))
    item:getChildByName("txt_jj_41"):getChildByName("txt"):setString(v.battleScore)
    item:getChildByName("txt_jj_26"):getChildByName("txt"):setString(v.combat)
    item:getChildByName("lbl_ztl_jj"):getChildByName("txt"):setString(getTextByKey("crossArena_battleCapacity"))
  end
end

function CrossArenaChanllengeLayer:initLayer()
    CrossArenaChanllengeLayer.super.initLayer(self)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/cross_Arena.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("table_crossArena_jjsx")
    self:addChild(self.mainUI)

    self.matchList = CrossArenaManager.getMatchList()
    self.freeRefreshTimestamp = CrossArenaManager.getFreeRefreshTimestamp()

    local function addCDComponent()
      --刷新刷新按钮
      self:refreshRefreshButton()
      --删除已经存在的倒计时
      if self.cdLabelComponent then
        self.cdLabelComponent:stop()
        self.cdLabelComponent = nil
      end
      --添加倒计时
      local function onTimeComplete()
        self:refreshRefreshButton()
        if self.cdLabelComponent then
          self.cdLabelComponent:stop()
          self.cdLabelComponent = nil
        end
      end

      local function onTimeTick(remainedSec)
        local formatedTimeStr = TimeUtil.formatTime(remainedSec)
        -- print(formatedTimeStr)
        self.mainUI:getChildByName("txt_jj_42"):getChildByName("txt"):setString(formatedTimeStr)
      end
      
      self.cdLabelComponent = CdLabelComponent:create()
      self.cdLabelComponent:setCallback(onTimeTick, onTimeComplete)
      local crossArenaSetting = CrossArenaManager.getCrossArenaSetting()
      local endTime = self.freeRefreshTimestamp + 10 * 60
      self.cdLabelComponent:setTargetTime(endTime)
      self.cdLabelComponent:start()
    end

    NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)

    self.chanllengeBtnTable = {}
    local battleList = self.mainUI:getChildByName("list_jj")
    for i=1,4 do
      local function onTouchBtn( evt )
        local function successCallback( e )
          --进入battleScene
          local pvpDailyInfo = DailyDataManager.getCrossPvpDailyData()
          pvpDailyInfo.crossPvpTimes = pvpDailyInfo.crossPvpTimes + 1
          DailyDataManager.setCrossPvpDailyData(pvpDailyInfo)
          
          Director:sharedDirector():replaceScene(BattleScene:create(e.data, BattleBackType.kCrossPVP, BattleEnterEnum.kCrossPVP))
        end

        local function failCallback( e )
          
        end
        local param = {index = evt.context-1}
        ChallengeCrossUserRequest.sendRequest(param , successCallback , failCallback)
      end
      local item = battleList:getChildByName("list_jj_"..i)
      self.chanllengeBtnTable[i] = Button:create(item:getChildByName("btn"))
      self.chanllengeBtnTable[i]:addEventListener(Events.kStart,onTouchBtn ,i)
    end
    self:refreshChanllgeList()

    self.mainUI:getChildByName("txt_jj_28"):getChildByName("txt"):setString(getTextByKey("crossArena_battleRank"))
    self.mainUI:getChildByName("txt_jj_43"):getChildByName("txt"):setString(CrossArenaManager.getMyRank())
    self.mainUI:getChildByName("txt_jj_29"):getChildByName("txt"):setString(getTextByKey("crossArena_battleScore")..CrossArenaManager.getMyBattleScore())
    self.mainUI:getChildByName("txt_jj_32"):getChildByName("txt"):setString(getTextByKey("crossArena_activeScore")..CrossArenaManager.getMyActiveScore())
    
    local function onTouchRewardReview( evt )
      --奖励预览
      local aInfoPanel = CrossArenaRewardReviewPanel:create(self.container)
      self.container:addChild(aInfoPanel)
      aInfoPanel:scaleIn()
    end

    local rewardReviewBtn = Button:create(self.mainUI:getChildByName("icon_reward_tab_jj"))
    rewardReviewBtn:addEventListener(Events.kStart,onTouchRewardReview)

    local function onBuyTimes( evt )
      --买次数
      local function successCallback( e )
        RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -self.buyCost}})
        local pvpDailyInfo = DailyDataManager.getCrossPvpDailyData()
        pvpDailyInfo.crossPvpBuyTimes = pvpDailyInfo.crossPvpBuyTimes + 1
        DailyDataManager.setCrossPvpDailyData(pvpDailyInfo)
        self:refreshWhenCrossDay()
      end
      BuyCrossPvpChallengeTimeRequest.sendRequestDefalut(successCallback)
    end

    self.buyTimesBtn = Button:create(self.mainUI:getChildByName("btn_blue_buy"))
    self.buyTimesBtn:addEventListener(Events.kStart,onBuyTimes)

    local function onRefresh( evt )
      --刷新对手
      local function successCallback( e )
        if self.refreshType == 1 then
          --扣除金币
          RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -self.refreshCost}})
          local pvpDailyInfo = DailyDataManager.getCrossPvpDailyData()
          pvpDailyInfo.crossPvpRefreshTimes = pvpDailyInfo.crossPvpRefreshTimes + 1
          DailyDataManager.setCrossPvpDailyData(pvpDailyInfo)
        end

        --免费刷新之后重置时间
        local currentTime = TimeUtil.getServerTimeSeconds()
        if self.refreshType == 0 then
          self.freeRefreshTimestamp = TimeUtil.getServerTimeSeconds()
        end
        
        --添加计时器
        addCDComponent()
        --刷新对手
        self.matchList = e.data.matchList
        self:refreshChanllgeList()
      end

      local function failCallback( e )
        
      end
      local params = {type = self.refreshType}
      RefreshMatchRequest.sendRequest(params , successCallback , failCallback)
    end

    self.refreshBtn = Button:create(self.mainUI:getChildByName("btn_blue_long_1"))
    self.refreshBtn:addEventListener(Events.kStart,onRefresh)

    self.mainUI:getChildByName("txt_jj_33"):getChildByName("txt"):setString(getTextByKey("crossArena_remainBattleTimes"))
    -- self.mainUI:getChildByName("txt_jj_34"):getChildByName("txt"):setString("剩余次数")
    self.mainUI:getChildByName("txt_jj_1"):getChildByName("txt"):setString(getTextByKey("crossArena_challengePlayer2"))
    
    self:refreshWhenCrossDay()

    --添加计时器
    addCDComponent()

    --主将形象
    local tempCard = self.mainUI:getChildByName("bg_jj_2")
    tempCard:setVisible(false)
    -- local cardsInfo = table.clone(DataManager.getCardsData(), true)
    -- local queue = table.clone(CommonManager.getQueueData(), true)

    -- for key,value in pairs(queue) do
    --   queue[key] = CommonManager.getSubTableByKey(
    --     cardsInfo,
    --     {name = "cardId", value=value}
    --   )
    -- end

    local params = {}
    params.sourceDisplay = tempCard
    params.scales = { 0.64, 0.64}
    params.showInCenter = true

    local mainCard = CanonGoodIcon.createGoodIcon(CanonGoodIcon.CARD_HALF, CommonManager.getSelfAvatarMeta(), 0, params)
    mainCard.touchEnabled = false
    mainCard.touchChildren = false
    -- mainCard:setAnchorPoint( ccp(0.0, 0.0) )
    self.mainUI:addChildAt(mainCard , tempCard:getZOrder())
    mainCard:setPositionY(653)
    -- mainCard:setPositionX(0)

    self.mainUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("crossArena_tips3"))
    self.mainUI:getChildByName("txt_jj_12"):getChildByName("txt"):setString(getTextByKey("crossArena_tips4"))
end

function CrossArenaChanllengeLayer:refreshRefreshButton()
  if self.matchList == nil then
    self.refreshBtn:setEnable(false)
    self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("normal"):setVisible(false)
    self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("disabled"):setVisible(true)
    self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("icon_jj_qian"):setVisible(false)
    self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("crossArena_challengePlayer"))
    self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("txt_2"):getChildByName("txt"):setString("")
    self.mainUI:getChildByName("txt_jj_1"):setVisible(false)
    self.mainUI:getChildByName("txt_jj_42"):setVisible(false)

    return
  end

  self.mainUI:getChildByName("txt_jj_12"):setVisible(false)
  self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("normal"):setVisible(true)
  self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("disabled"):setVisible(false)

  local pvpDailyInfo = DailyDataManager.getCrossPvpDailyData()
  local crossArenaSetting = CrossArenaManager.getCrossArenaSetting()

  local currentTime = TimeUtil.getServerTimeSeconds()
  if currentTime - self.freeRefreshTimestamp >= 10 * 60 then
    --免费刷新
    self.refreshType = 0--免费
    self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("icon_jj_qian"):setVisible(false)
    self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("crossArena_challengePlayer"))
    self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("txt_2"):getChildByName("txt"):setString("")
    -- self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("txt_jj_42"):setVisible(false)
    -- self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("txt_jj_1"):setVisible(false)
    self.mainUI:getChildByName("txt_jj_1"):setVisible(false)
    self.mainUI:getChildByName("txt_jj_42"):setVisible(false)
  else
    self.refreshType = 1--金币
    local buyTimes = pvpDailyInfo.crossPvpRefreshTimes + 1
    if buyTimes >= #crossArenaSetting.refreshCosts then
      buyTimes = #crossArenaSetting.refreshCosts
    end
    self.refreshCost = crossArenaSetting.refreshCosts[buyTimes].cost
    self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("icon_jj_qian"):setVisible(true)
    self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("txt_2"):getChildByName("txt"):setString(self.refreshCost..getTextByKey("crossArena_challengePlayer"))
    self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("txt_1"):getChildByName("txt"):setString("")
    -- self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("txt_jj_42"):setVisible(true)
    -- self.mainUI:getChildByName("btn_blue_long_1"):getChildByName("txt_jj_1"):setVisible(true)
    self.mainUI:getChildByName("txt_jj_1"):setVisible(true)
    self.mainUI:getChildByName("txt_jj_42"):setVisible(true)
  end
end

function CrossArenaChanllengeLayer:refreshWhenCrossDay()
  local pvpDailyInfo = DailyDataManager.getCrossPvpDailyData()
  local crossArenaSetting = CrossArenaManager.getCrossArenaSetting()

  self.mainUI:getChildByName("txt_2"):setVisible(false)
  --购买btn的状态
  local lastChallengeTimes = CrossArenaManager.getLastChangllengeNum()
  if lastChallengeTimes == crossArenaSetting.freeBattleNum then
    self.buyTimesBtn:setEnable(false)
    self.buyTimesBtn:setVisible(true)
    self.mainUI:getChildByName("btn_blue_buy"):getChildByName("icon_jj_qian"):setVisible(false)
    self.mainUI:getChildByName("btn_blue_buy"):getChildByName("normal"):setVisible(false)
    self.mainUI:getChildByName("btn_blue_buy"):getChildByName("disabled"):setVisible(true)
    self.mainUI:getChildByName("btn_blue_buy"):getChildByName("txt"):setString("")
    self.mainUI:getChildByName("btn_blue_buy"):getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("crossArena_buyBattleTimes"))

  elseif pvpDailyInfo.crossPvpBuyTimes == #crossArenaSetting.goldBattleCosts then
    self.buyTimesBtn:setEnable(false)
    self.buyTimesBtn:setVisible(false)
    self.mainUI:getChildByName("txt_2"):setVisible(true)
  else
    self.buyTimesBtn:setEnable(true)
    self.buyTimesBtn:setVisible(true)
    self.mainUI:getChildByName("btn_blue_buy"):getChildByName("icon_jj_qian"):setVisible(true)
    self.mainUI:getChildByName("btn_blue_buy"):getChildByName("normal"):setVisible(true)
    self.mainUI:getChildByName("btn_blue_buy"):getChildByName("disabled"):setVisible(false)
    local cost = crossArenaSetting.goldBattleCosts[pvpDailyInfo.crossPvpBuyTimes + 1]
    self.mainUI:getChildByName("btn_blue_buy"):getChildByName("txt"):setString(cost.cost..getTextByKey("crossArena_buyBattleTimes"))
    self.mainUI:getChildByName("btn_blue_buy"):getChildByName("txt_1"):getChildByName("txt"):setString("")
    self.buyCost = cost.cost
  end

  local battleList = self.mainUI:getChildByName("list_jj")
  if lastChallengeTimes == 0 then
    for i=1,4 do
      self.chanllengeBtnTable[i]:setEnable(false)
      battleList:getChildByName("list_jj_"..i):getChildByName("btn"):getChildByName("icon_challenge"):setVisible(false)
      battleList:getChildByName("list_jj_"..i):getChildByName("btn"):getChildByName("icon_challenge_gray"):setVisible(true)
    end
  else
    for i=1,4 do
      self.chanllengeBtnTable[i]:setEnable(true)
      battleList:getChildByName("list_jj_"..i):getChildByName("btn"):getChildByName("icon_challenge"):setVisible(true)
      battleList:getChildByName("list_jj_"..i):getChildByName("btn"):getChildByName("icon_challenge_gray"):setVisible(false)
    end
  end

  --次数string
  self.mainUI:getChildByName("txt_jj_34"):getChildByName("txt"):setString(lastChallengeTimes.."/"..crossArenaSetting.freeBattleNum)
  if lastChallengeTimes == 0 then--改变颜色
    self.mainUI:getChildByName("txt_jj_34"):getChildByName("txt"):setColor(ccc3(255, 0, 0))
  else
    self.mainUI:getChildByName("txt_jj_34"):getChildByName("txt"):setColor(ccc3(79, 255, 79))
  end

  self:refreshRefreshButton()
end

----------------------------------------------------------------------
-- 切页动作
----------------------------------------------------------------------

-- 进入页面
function CrossArenaChanllengeLayer:panelEnter(callback)
  --ViewControlUtil.showTableViewAction(self.listTableView, visibleSize,callback)
  if callback then
    callback()
  end
end

-- 退出页面
function CrossArenaChanllengeLayer:panelExit(callback)
  if callback then
    callback()
  end
  --ViewControlUtil.disappearTableViewAction(self.listTableView, visibleSize, callback)
end

--设置触摸是否开启
function CrossArenaChanllengeLayer:setTableViewTouched(enabled)
  --self.listTableView:setTouchEnabled(enabled)
end