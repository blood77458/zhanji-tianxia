require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"
require "canon.request.DiceRollRequest"
require "canon.panel.ActivitySilverDiceLayer_POP"
require "canon.panel.SilverDiceInfoPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- Activity_SilverDiceLayer
-- 银币骰子layer
-- create by czh @ 2014-1-10
--

Activity_SilverDiceLayer = class(Layer)




function Activity_SilverDiceLayer:ctor()
    self.container = nil
    self.extraArgs = nil

    self.todayRollTimes = 0
    --今日已转运总次数
    self.todayChangeLuckTimes = 0
    --奖励银币数量
    self.gainCoinNum = 0
    self.starCount = 0
    self.currentChangeLuckTimes = 0
    --当前投掷结果
    self.currentResult = {0,0,0,0,0,0}
    self.oldPositions = {};

    --弹出状态
    self.popState = false

    self.diceTypes = {"dice_horse", "dice_cloud", "dice_sun", "dice_moon", "dice_rune", "dice_star"}
    --骰子滚动共7帧
    self.diceRollTypes = {"dice_01", "dice_02", "dice_03", "dice_04", "dice_05", "dice_06", "dice_07"}
    self.offsets = {{x=0,y=90}, {x=-134,y=104}, {x=-37,y=-89}, {x=0,y=-86}, {x=89,y=-100}, {x=132,y=103}}
end

function Activity_SilverDiceLayer:create( container, extraArgs )
  local s = Activity_SilverDiceLayer.new()
  self.container = container
  
  local curDate = TimeUtil.getYmd()
  if(curDate ~= DataManager.getDataTimestamp()) then
    DataManager.resetSharkDiceDataForSwitchDay()
  end
  
  self.extraArgs = DataManager.getSharkDiceData()

  s:initLayer()

  return s
end

function Activity_SilverDiceLayer:initLayer()
  Activity_SilverDiceLayer.super.initLayer(self)

  --刷新显示
  local function refreshSelf()
    if self:canRoll() then 

      --可以投掷
      self.mainUI:getChildByName("btn_throw"):setVisible(true)
      self.mainUI:getChildByName("txt_info7"):setVisible(true)
      self.mainUI:getChildByName("txt_info8"):setVisible(false)
      
      --摇一摇始终不可见 节后改回 2014-1-26
      -- self.mainUI:getChildByName("icon_arrow_l"):setVisible(false)
      -- self.mainUI:getChildByName("icon_arrow_r"):setVisible(false)
      -- self.mainUI:getChildByName("txt_y"):setVisible(false)
      self.mainUI:getChildByName("icon_arrow_l"):setVisible(false)
      self.mainUI:getChildByName("icon_arrow_r"):setVisible(false)
      self.mainUI:getChildByName("txt_y"):setVisible(false)

      --今日剩余次数
      self.mainUI:getChildByName("txt_info7"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_number") .. self:rollTimesRemain())
    else
      --不可投掷
      self.mainUI:getChildByName("btn_throw"):setVisible(false)
      self.mainUI:getChildByName("txt_info7"):setVisible(false)
      self.mainUI:getChildByName("txt_info8"):setVisible(true)

      self.mainUI:getChildByName("icon_arrow_l"):setVisible(false)
      self.mainUI:getChildByName("icon_arrow_r"):setVisible(false)
      self.mainUI:getChildByName("txt_y"):setVisible(false)
    end
  end
  self.refreshSelf = refreshSelf

  --触摸投掷骰子
  local function rollButtonSelected(evt)
    --判断是否能投掷
    -- if not self.shakeState then
    --   return
    -- end



    self:startRoll()
  end

  --摇一摇触发
  local function accelerometerCallback(x, y, z, timestamp)
    if not self.shakeState then
      return
    end

    if not self:canRoll() then
      return
    end

    local acc = math.sqrt(x*x + y*y + z*z)
    if acc >= 3 then
      self:startRoll()
    end
  end
  self.accelerometerCallback = accelerometerCallback

  --定期更新时间
  local function timeTick(ee)

    local curDate = TimeUtil.getYmd()
    if(curDate ~= self.currentTime) then
      DataManager.resetSharkDiceDataForSwitchDay()
      local sharkDice = DataManager.getSharkDiceData()
      
      --今日已投掷骰子次数
      self.todayRollTimes = sharkDice.throwDiceCount
      --今日已转运次数
      self.todayChangeLuckTimes = sharkDice.changeDiceLuckCount
      --今日当前投掷改运次数
      self.currentChangeLuckTimes = sharkDice.changeLuckCountPerThrow

      --重新记录当前时间
      self.currentTime = DataManager.getDataTimestamp()

      self:refreshSelf()
      self.container:resetTipInfoForActivity("Activity_throwDice")

      --刷新子面板
      if self.aInfoPanel then
        self.aInfoPanel:refreshSelf()
      end
    end
  end
  
  self.builder = LayoutBuilder:createWithContentsOfFile("scene/sixhorse.json")
  self.builder.useArtLabelTTF = true
  self.mainUI = self.builder:build("sixhorse")
  self:addChild(self.mainUI)

  local titleLabel_ActivitytimeInfo1 = self.mainUI:getChildByName("txt_info1")--活动持续时间
  local titleLabel_ActivitytimeInfo2 = self.mainUI:getChildByName("txt_info2")--100%
  local titleLabel_ActivitytimeInfo3 = self.mainUI:getChildByName("txt_info3")--获得银币
  local titleLabel_ActivitytimeInfo4 = self.mainUI:getChildByName("txt_info4")--试试运气
  local titleLabel_empty = self.mainUI:getChildByName("txt_info8")--投掷次数用尽提示
  local titleLabel_remain = self.mainUI:getChildByName("txt_info7")--今日剩余次数:x
  local rollButtonDisplay = self.mainUI:getChildByName("btn_throw")--投掷骰子
  local rollButton = Button:create(rollButtonDisplay)

  local timeTable = MaintenanceManager:getStartAndEndTime("activityThrowDice");
  titleLabel_ActivitytimeInfo1:getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_top_title1"))
  titleLabel_ActivitytimeInfo2:getChildByName("txt"):setString("100%")
  titleLabel_ActivitytimeInfo3:getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_top_title3"))
  titleLabel_ActivitytimeInfo4:getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_top_title4", {num1 = timeTable[1].month, num2 = timeTable[1].day, num3 = timeTable[2].month, num4 = timeTable[2].day}))
  titleLabel_empty:getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_number_end"))
  titleLabel_remain:getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_top_title"))
  rollButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_move"))
  self.mainUI:getChildByName("txt_y"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_shake"))--摇一摇
  self.mainUI:getChildByName("txt_info10"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_coin1"))--银币

  rollButton:addEventListener(Events.kStart,rollButtonSelected, self)

  --初始化数据
  --print("配置文件 = " .. table.tostring(DataManager.GameMetaData.activityDiceConfig))
  self.todayRollTimes = self.extraArgs.throwDiceCount or 0
  self.todayChangeLuckTimes = self.extraArgs.changeDiceLuckCount or 0
  self.currentResult = self.extraArgs.diceStates or {0,0,0,0,0,0}
  if self.extraArgs.diceStates then
    local count = 0
    for i,v in ipairs(self.extraArgs.diceStates) do
      if v == 0 then
        count = count + 1
      end
    end
    self.starCount = count
  else
    self.starCount = 0
  end
  self.gainCoinNum = self.extraArgs.coins or 0
  self.currentChangeLuckTimes = self.extraArgs.changeLuckCountPerThrow or 0
  if not self.extraArgs.gainedReward then
    --上次未领取
    --显示上次结果
    for i = 1, 6 do
      local dice = self.mainUI:getChildByName(string.format("dice_00%d", i))
      local diceIndex = self.currentResult[i]
      dice:setDisplayFrame(createSpriteFrame(UI_RES_PATH.."/sixhorse/"..self.diceTypes[diceIndex+1]..".png"))
    end

    --直接打开二级
    self:playComplete()
  else
    --可以摇一摇
    --self:addAccelerometer()
  end

  self.oldPositions = {}
  for i = 1, 6 do
    local dice = self.mainUI:getChildByName(string.format("dice_00%d", i))
    table.insert(self.oldPositions, {x = dice:getPositionX(), y = dice:getPositionY()})
  end

  --用于定期刷新
  self.currentTime = DataManager.getDataTimestamp()
  self.onUpdateFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(timeTick,15,false);

  --摇一摇侦听
  self:setAccelerometerEnabled(true)
  self:registerScriptAccelerateHandler(self.accelerometerCallback)
  --可以摇一摇
  --self:addAccelerometer()

  local function infoButtonSelected(evt)
      self.container:setTableViewsEnabled(false)
      local aInfoPanel = SilverDiceInfoPanel:create(self.container)
      self.container:addChild(aInfoPanel)
      aInfoPanel:scaleIn()
  end
  local infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
  infoButton:addEventListener(Events.kStart, infoButtonSelected, self)
  
  self:refreshSelf()
end

function Activity_SilverDiceLayer:enable()
  if not DataManager.GameMetaData.activityDiceConfig then
    return false
  end
  local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityDiceConfig.featureName)
  return isEnable
end 

function Activity_SilverDiceLayer:dispose()
  self:removeAccelerometer()
  if (self.onUpdateFunc) then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onUpdateFunc)
  end

  self:setAccelerometerEnabled(false)
  self:unregisterScriptAccelerateHandler()

  Activity_SilverDiceLayer.super.dispose(self)
end

-----------------------------------------------
-- 查询接口
-----------------------------------------------

--允许投掷
function Activity_SilverDiceLayer:canRoll()
  return (self:rollTimesRemain() > 0);
end

--剩余次数
function Activity_SilverDiceLayer:rollTimesRemain()
  local maxTimes = DataManager.GameMetaData.activityDiceConfig.maxThrowDiceCount
  --local maxTimes = 6
  local remain = maxTimes - self.todayRollTimes;
  return remain
end

--是否全马
function Activity_SilverDiceLayer:isAllHorse()
  for i = 1, 6 do
    local diceIndex = self.currentResult[i]
    --print("diceIndex = " .. diceIndex);
    if diceIndex ~= 0 then
      return false
    end
  end
  return true
end

--马的个数
function Activity_SilverDiceLayer:horseNum()
  local result = 0
  for i = 1, 6 do
    local diceIndex = self.currentResult[i]
    if diceIndex == 0 then
      result = result + 1
    end
  end
  return result
end

function Activity_SilverDiceLayer:silverRewardNum()
  local currentHorseNum = self:horseNum()
  --基数
  local baseCoinThrowDice = DataManager.GameMetaData.activityDiceConfig.baseCoinThrowDice
  --倍率
  local diceMultiple = self:getDiceMultipleByHorseNum(currentHorseNum)
  --user-level.coinRewardCoefficient
  local level = DataManager.getCurrUser().level
  local coinRewardCoefficient = MetaManager.user_level[level].coinRewardCoefficient

  --print("奖励银币 = " .. (baseCoinThrowDice + math.floor(diceMultiple * coinRewardCoefficient)))
  return baseCoinThrowDice + math.floor(diceMultiple * coinRewardCoefficient)
  --return 100
end

function Activity_SilverDiceLayer:getDiceMultipleByHorseNum(num)
  local diceCoinMultipleItems = DataManager.GameMetaData.activityDiceConfig.diceCoinMultipleItems

  --print("diceCoinMultipleItems = " .. table.tostring(diceCoinMultipleItems))
  for _, diceCoinMultipleItem in pairs(diceCoinMultipleItems) do
    if diceCoinMultipleItem.horseNum == num then
      --print("num = " .. num)
      --print("diceCoinMultipleItem.horseNum = " .. diceCoinMultipleItem.horseNum)
      return diceCoinMultipleItem.diceMultiple
    end
  end
  return 0
end

function Activity_SilverDiceLayer:needGold()
  local diceGoldConsumeItems = DataManager.GameMetaData.activityDiceConfig.diceGoldConsumeItems
  --local diceGoldConsumeItems = {{diceStart = 1, diceOver = 10, diceGold = 1}, {diceStart = 11, diceOver = 20, diceGold = 2}}
  local freeMaxTimes = DataManager.GameMetaData.activityDiceConfig.freeChangeLuckCount
  --local freeMaxTimes = 6

  local currentTimes = self.currentChangeLuckTimes + 1

  for _, diceGoldConsumeItem in pairs(diceGoldConsumeItems) do
    if ((currentTimes >= diceGoldConsumeItem.diceStart ) and (currentTimes <= diceGoldConsumeItem.diceOver) ) then
      return diceGoldConsumeItem.diceGold
    end
  end
  return 0
end

-----------------------------------------------
-- 私有处理
-----------------------------------------------


function Activity_SilverDiceLayer:startRoll()

  --成功
  local function onSucceed(event)
    --print("投掷骰子操作结果 = " .. table.tostring(event))

    --重新记录当前时间
    DataManager.resetDataTimestamp()
    self.currentTime = DataManager.getDataTimestamp()
    local sharkDice = DataManager.getSharkDiceData()
    sharkDice.diceStates = event.data.diceStates or {0,0,0,0,0,0}
    sharkDice.coins = event.data.coins or 0
    sharkDice.throwDiceCount = event.data.throwDiceCount or 0
    sharkDice.changeDiceLuckCount = event.data.changeDiceLuckCount or 0
    sharkDice.changeLuckCountPerThrow = event.data.changeLuckCountPerThrow or 0
    sharkDice.gainedReward = false
    DataManager.setSharkDiceData(sharkDice)

    local count = 0
    for i,v in ipairs(sharkDice.diceStates) do
      if v == 0 then
        count = count + 1
      end
    end
    self.starCount = count
    self.currentResult = sharkDice.diceStates
    self.gainCoinNum = sharkDice.coins
    self.todayRollTimes = sharkDice.throwDiceCount
    self.todayChangeLuckTimes = sharkDice.changeDiceLuckCount
    self.currentChangeLuckTimes = sharkDice.changeLuckCountPerThrow

    self.refreshSelf()
    self.container:resetTipInfoForActivity("Activity_throwDice")
    self:playRollDice()
  end 
  --失败
  local function onFailed(event)
    --print("投掷返回失败信息 = " .. table.tostring(event))
    if event.data.retCode == 716200 then  --activity closed
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("activity_goldGod_end_remind")
      self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    elseif event.data.retCode == 716202 then  --FortuneNum over max
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("activity_dice_number_end")
      self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    else
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
      self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end

  self:removeAccelerometer()

  --发送指令
  --print("发送指令")
  local params = {}
  local request = DiceRollRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.ThrowDiceSucceed, onSucceed)
  request:addEventListener(RequestNotifyEnum.ThrowDiceFailed, onFailed)
  request:start()

  --test
  --onSucceed({data = {diceStates = {0, 0, 2, 3, 4, 5, 6}}})
end

--播放动画
function Activity_SilverDiceLayer:playRollDice()
  --遮罩
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self.container:addChild(self.tempLayer)
  self.container.targetInfoPanel = self.tempLayer
  self.container:setTableViewsEnabled(false)

  for i = 1, 6 do
    local dice = self.mainUI:getChildByName(string.format("dice_00%d", i))

    --先回到初始位置
    dice:setPositionX(self.oldPositions[i].x)
    dice:setPositionY(self.oldPositions[i].y)

    --开始动画
    local arr = CCArray:create()
    local randomTime = math.random(3, 7) / 10
    arr:addObject(CCMoveBy:create(randomTime, ccp(self.offsets[i].x, self.offsets[i].y)))
    arr:addObject(CCMoveBy:create(randomTime, ccp(-self.offsets[i].x, -self.offsets[i].y)))
    local action1 = CCSequence:create(arr)
    local action3 = CCRepeatForever:create(action1)
    dice:runAction(CCRepeatForever:create(action3))

    local diceAnimaFrames = {}
    for i = 1, 7 do
      table.insert(diceAnimaFrames, createSpriteFrame(UI_RES_PATH.."/sixhorse/"..self.diceRollTypes[i]..".png"))
    end
    dice:runAction(CCRepeatForever:create(SpriteUtil:buildAnimate(diceAnimaFrames, 0.1)))
  end

  --结束动画
  local function actionFinished()
    --取消遮罩
    self.tempLayer:removeFromParentAndCleanup(true)
    self.container.targetInfoPanel = nil
    self.container:setTableViewsEnabled(true)

    for i = 1, 6 do
      local dice = self.mainUI:getChildByName(string.format("dice_00%d", i))
      dice:stopAllActions()

      local diceIndex = self.currentResult[i]
      dice:setDisplayFrame(createSpriteFrame(UI_RES_PATH.."/sixhorse/"..self.diceTypes[diceIndex+1]..".png"))
    end
    self:playComplete()
  end

  local arr2 = CCArray:create()
  arr2:addObject(CCDelayTime:create(1.5))
  arr2:addObject(CCCallFunc:create(actionFinished))
  self:runAction(CCSequence:create(arr2))
end

--播放完毕
function Activity_SilverDiceLayer:playComplete()
  self.popState = true

  self.aInfoPanel = ActivitySilverDiceLayer_POP:create(self.container, self)
  self.container:addChild(self.aInfoPanel)
  self.aInfoPanel:scaleIn()

  self:popShow()
end

function Activity_SilverDiceLayer:addAccelerometer()
  if self.popState then
    return
  end

  --摇一摇始终不可见 节后改回 2014-1-26
  -- self.shakeState = true
  self.shakeState = false
end

function Activity_SilverDiceLayer:removeAccelerometer()
  self.shakeState = false
end

function Activity_SilverDiceLayer:popShow()
  self.container.targetInfoPanel = self.aInfoPanel
  self.container:setTableViewsEnabled(false)
  self:removeAccelerometer()
end

function Activity_SilverDiceLayer:popClose()
    self.container.targetInfoPanel = nil
    self.container:setTableViewsEnabled(true)

    self.popState = false
    self:refreshSelf()
    self.container:resetTipInfoForActivity("Activity_throwDice")
    self:addAccelerometer()

    self.aInfoPanel = nil
end

function Activity_SilverDiceLayer:panelExit()
  --print("Activity_SilverDiceLayer:panelExit")
  self:removeAccelerometer()
end

function Activity_SilverDiceLayer:panelEnter()
  --print("Activity_SilverDiceLayer:panelEnter")
  self:addAccelerometer()
end

function Activity_SilverDiceLayer.getTipNum()
  if not Activity_SilverDiceLayer.enable() then
    return 0
  end
  
  local result = 0
  local maxTimes = DataManager.GameMetaData.activityDiceConfig.maxThrowDiceCount
  
  local curDate = TimeUtil.getYmd()
  if(curDate ~= DataManager.getDataTimestamp()) then
    DataManager.resetSharkDiceDataForSwitchDay()
  end
  
  local sharkDice = DataManager.getSharkDiceData()
  local todayThrow = sharkDice.throwDiceCount
  if maxTimes > todayThrow then
    result = maxTimes - todayThrow
  end
  return result
end