require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.DiceGainRewardRequest"
require "canon.request.DiceChangeLuckRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local scroll_width = 525
local scroll_height = 420
local scroll_posX = 95
local scroll_posY = 430
local scroll_startPosY = 410

--
-- ActivitySilverDiceLayer_POP
--

ActivitySilverDiceLayer_POP = class(Layer)

function ActivitySilverDiceLayer_POP:ctor()
    self.container = nil
    self.content = nil

    self.oldPositions = {};
end

function ActivitySilverDiceLayer_POP:create( container, content )
    local s = ActivitySilverDiceLayer_POP.new()
    s:initLayer(container, content)
    return s
end

function ActivitySilverDiceLayer_POP:initLayer(container, content)
  MissionUnlockContentPanel.super.initLayer(self)

  --刷新显示
  local function refreshSelf()
    --print("refreshSelf")
    if not self.content:isAllHorse() then
      --非全马
      self.panelUI:getChildByName("btn_get"):setVisible(true)
      self.panelUI:getChildByName("btn_get2"):setVisible(false)
      if self:changeLuckTimesRemain() <= 0 then 
        --转运次数为0
        self.panelUI:getChildByName("txt_info6"):setVisible(true)

        self.panelUI:getChildByName("btn_change_luck"):setVisible(false)
        self.panelUI:getChildByName("btn_superchange_luck"):setVisible(false)
        self.panelUI:getChildByName("txt_info7"):setVisible(false)
      else
        --有转运次数
        self.panelUI:getChildByName("txt_info6"):setVisible(false)

        if self:changeLuckFreeTimesRemain() <= 0 then
          --没有免费次数 显示逆天转运
          self.panelUI:getChildByName("btn_superchange_luck"):setVisible(true)

          self.panelUI:getChildByName("btn_change_luck"):setVisible(false)
          self.panelUI:getChildByName("txt_info7"):setVisible(false)

          --逆天改运所需金币显示
          self.panelUI:getChildByName("btn_superchange_luck"):getChildByName("txt2"):setString(self.content:needGold())
        else
          --有免费次数
          self.panelUI:getChildByName("btn_change_luck"):setVisible(true)
          self.panelUI:getChildByName("txt_info7"):setVisible(true)
          
          self.panelUI:getChildByName("btn_superchange_luck"):setVisible(false)

          --显示免费改运次数文本
          self.panelUI:getChildByName("txt_info7"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_luck_time") .. self:changeLuckFreeTimesRemain())
        end
      end
    else
      --全马
      self.panelUI:getChildByName("btn_get2"):setVisible(true)

      self.panelUI:getChildByName("txt_info6"):setVisible(false)
      self.panelUI:getChildByName("btn_get"):setVisible(false)
      self.panelUI:getChildByName("btn_change_luck"):setVisible(false)
      self.panelUI:getChildByName("btn_superchange_luck"):setVisible(false)
      self.panelUI:getChildByName("txt_info7"):setVisible(false)
    end
    self.panelUI:getChildByName("txt_getcoin"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_coin") .. self.content.gainCoinNum)
    --其他奖励
    if self.content.starCount > 0 then
      local data = DataManager.GameMetaData.activityDiceConfig.diceNewRewardItems[self.content.starCount]
      local rewardLabel = ""
      for i=1,3 do
        if data["content"..i.."Id"] ~= 0 then
            if i > 1 then
              rewardLabel = rewardLabel .. "   "
            end

            local strLabel = CanonGoodIcon.getGoodName(data["content"..i.."Type"], data["content"..i.."Id"], data["content"..i.."Amount"], {withoutAmount = false})
            rewardLabel = rewardLabel..strLabel
        end
      end
      self.panelUI:getChildByName("txt_info11"):getChildByName("txt"):setString(rewardLabel)
    else
      self.panelUI:getChildByName("txt_info11"):getChildByName("txt"):setString("")
    end
    
    --显示结果
    for i = 1, 6 do
      local dice = self.panelUI:getChildByName(string.format("dice_%d", i))
      dice:stopAllActions()
      local diceIndex = self.content.currentResult[i]
      dice:setDisplayFrame(createSpriteFrame(UI_RES_PATH.."/sixhorse/"..self.content.diceTypes[diceIndex+1]..".png"))

      --回到初始位置
      dice:setPositionX(self.oldPositions[i].x)
      dice:setPositionY(self.oldPositions[i].y)
    end
  end
  self.refreshSelf = refreshSelf

  --获取奖励
  local function onGain(evt)
    self:startGain()
  end
  --转运
  local function onChangeLuck(evt)
    self:startChangeLuck()
  end
  --逆天转运
  local function onSuperChangeLuck(evt)
    if CalculationManager.calcComplex_getGemsNow() < self.content:needGold() then
      --金币不足 给提示
      local function replaceSceneFunc()
        self:runAction(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
      end
      local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin, nil, {onReplaceSceneFunc = replaceSceneFunc} )
      self.container:addChild(aPanel)
      aPanel:scaleIn()
    else
      --金币足够 发指令
      self:startChangeLuck()
    end
  end
    
  self.container = container
  self.content = content
  
  self.container.targetInfoPanel = self
  
  self.colorLayer = LayerColor:create()
  self.colorLayer:setOpacity(kDarkOpacity)
  self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.colorLayer)
  
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.tempLayer)
  self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/sixhorse.json")
  builder.useArtLabelTTF = true
  self.panelUI = builder:build("popup_sixhorse") 
  self.tempLayer:addChild(self.panelUI)
  
  self.panelUI:getChildByName("txt_info5"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_txt"))
  --银币+xx
  self.panelUI:getChildByName("txt_getcoin"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_coin"))
  self.panelUI:getChildByName("txt_info6"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_luck_done"))
  self.panelUI:getChildByName("btn_get2"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_receive"))
  --左侧领取按钮
  self.panelUI:getChildByName("btn_get"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_receive"))
  --改运按钮
  self.panelUI:getChildByName("btn_change_luck"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_luck"))
  self.panelUI:getChildByName("btn_superchange_luck"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_luck_break"))
  self.panelUI:getChildByName("btn_superchange_luck"):getChildByName("txt2"):setString("12")
  --今日免费改运次数:xx
  self.panelUI:getChildByName("txt_info7"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dice_luck_time"))
  
  --左侧领取按钮
  local gainButton = Button:create(self.panelUI:getChildByName("btn_get"))
  local gain2Button = Button:create(self.panelUI:getChildByName("btn_get2"))
  --改运按钮
  local changeLuckButton = Button:create(self.panelUI:getChildByName("btn_change_luck"))
  --逆天改运按钮
  local superChangeLuckButton = Button:create(self.panelUI:getChildByName("btn_superchange_luck"))

  gainButton:addEventListener(Events.kStart,onGain, self)
  gain2Button:addEventListener(Events.kStart,onGain, self)
  changeLuckButton:addEventListener(Events.kStart,onChangeLuck, self)
  superChangeLuckButton:addEventListener(Events.kStart,onSuperChangeLuck, self)

  
  self.tempLayer:setScale(0.1)

  self.oldPositions = {}
  for i = 1, 6 do
    local dice = self.panelUI:getChildByName(string.format("dice_%d", i))
    table.insert(self.oldPositions, {x = dice:getPositionX(), y = dice:getPositionY()})
  end

  self:refreshSelf()
end

function ActivitySilverDiceLayer_POP:scaleIn()
  self.tempLayer.touchEnabled = false
  self.tempLayer.touchChildren = false
  local function scaleInFinished()
    self.tempLayer.touchEnabled = true
    self.tempLayer.touchChildren = true
  end
  local arr = CCArray:create()
  arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
  arr:addObject(CCCallFunc:create(scaleInFinished))
  self.tempLayer:runAction(CCSequence:create(arr))
end

function ActivitySilverDiceLayer_POP:dismiss()
  self:removeFromParentAndCleanup(true)
  self.content:popClose()
end


function ActivitySilverDiceLayer_POP:changeLuckTimesRemain()
  local maxTimes = DataManager.GameMetaData.activityDiceConfig.maxChangeLuckCount
  local remain = maxTimes - self.content.todayChangeLuckTimes
  return remain
end

function ActivitySilverDiceLayer_POP:changeLuckFreeTimesRemain()
  local freeMaxTimes = DataManager.GameMetaData.activityDiceConfig.freeChangeLuckCount
  local remain = freeMaxTimes - self.content.todayChangeLuckTimes
  return remain
end

function ActivitySilverDiceLayer_POP:startGain()
  --成功
  local function onSucceed(event)
    --给钱 关闭
    RewardManager:getReward({{itemType = ResourceEnum.COIN, amount = event.data.gainedCoin}})
    RewardManager:getReward(event.data.diceNewRewards)

    --重新记录当前时间
    DataManager.resetDataTimestamp()
    self.content.currentTime = DataManager.getDataTimestamp()
    
    local sharkDice = DataManager.getSharkDiceData()
    sharkDice.diceStates = {0,0,0,0,0,0}
    sharkDice.coins = 0
    sharkDice.throwDiceCount = event.data.throwDiceCount or 0
    sharkDice.changeDiceLuckCount = event.data.changeDiceLuckCount or 0
    sharkDice.changeLuckCountPerThrow = event.data.changeLuckCountPerThrow or 0
    sharkDice.gainedReward = true
    DataManager.setSharkDiceData(sharkDice)

    self.content.currentResult = sharkDice.diceStates
    self.content.gainCoinNum = sharkDice.coins
    local count = 0
    for i,v in ipairs(sharkDice.diceStates) do
      if v == 0 then
        count = count + 1
      end
    end
    self.content.starCount = count
    self.content.todayRollTimes = sharkDice.throwDiceCount
    self.content.todayChangeLuckTimes = sharkDice.changeDiceLuckCount
    self.content.currentChangeLuckTimes = sharkDice.changeLuckCountPerThrow
    
    --RewardManager:getReward({{itemType = ResourceEnum.COIN, amount = 100}})
    self:dismiss()
    
  end 
  --失败
  local function onFailed(event)
    if event.data.retCode == 716200 then  --activity closed
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("activity_goldGod_end_remind")
      self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      --关闭当前二级
      self:dismiss()
    elseif event.data.retCode == 710516 then  --背包已满
      self.targetInfoPanel = NewPackageFullPanel:show()
    else
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
      self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end

  --发送指令
  local params = {}
  local request = DiceGainRewardRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.GainThrowDiceSucceed, onSucceed)
  request:addEventListener(RequestNotifyEnum.GainThrowDiceFailed, onFailed)
  request:start()

  --test
  --onSucceed({})
end

--请求改运
function ActivitySilverDiceLayer_POP:startChangeLuck()
  --成功
  local function onSucceed(event)
    self:startAction()

    --重新记录当前时间
    DataManager.resetDataTimestamp()
    self.content.currentTime = DataManager.getDataTimestamp()

    --更新次数 扣金币 换结果
    RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = (-event.data.golds or 0)}})
    
    local sharkDice = DataManager.getSharkDiceData()
    sharkDice.diceStates = event.data.diceStates or {0,0,0,0,0,0}
    sharkDice.coins = event.data.coins or 0
    sharkDice.throwDiceCount = event.data.throwDiceCount or 0
    sharkDice.changeDiceLuckCount = event.data.changeDiceLuckCount or 0
    sharkDice.changeLuckCountPerThrow = event.data.changeLuckCountPerThrow or 0
    sharkDice.gainedReward = false
    DataManager.setSharkDiceData(sharkDice)

    self.content.currentResult = sharkDice.diceStates
    self.content.gainCoinNum = sharkDice.coins
    local count = 0
    for i,v in ipairs(sharkDice.diceStates) do
      if v == 0 then
        count = count + 1
      end
    end
    self.content.starCount = count
    self.content.todayRollTimes = sharkDice.throwDiceCount
    self.content.todayChangeLuckTimes = sharkDice.changeDiceLuckCount
    self.content.currentChangeLuckTimes = sharkDice.changeLuckCountPerThrow
    --print("改运结果 = " .. table.tostring(event))

    --更新下边的骰子
    for i = 1, 6 do
      local dice = self.content.mainUI:getChildByName(string.format("dice_00%d", i))
      local diceIndex = self.content.currentResult[i]
      dice:setDisplayFrame(createSpriteFrame(UI_RES_PATH.."/sixhorse/"..self.content.diceTypes[diceIndex+1]..".png"))
    end
  end 
  --失败
  local function onFailed(event)
    if event.data.retCode == 716200 then  --activity closed
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("activity_goldGod_end_remind")
      self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      --关闭当前二级
      self:dismiss()
    elseif event.data.retCode == 716204 then  --
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("activity_dice_luck_done")
      self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    else
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
      self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end

  --发送指令
  local params = {}
  local request = DiceChangeLuckRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.ChangeThrowDiceLuckSucceed, onSucceed)
  request:addEventListener(RequestNotifyEnum.ChangeThrowDiceLuckFailed, onFailed)
  request:start()

  --test
  --onSucceed({data = {diceStates = {0, 0, 2, 3, 4, 5, 6}}})
end

function ActivitySilverDiceLayer_POP:startAction()
  --结束动画
  local function actionFinished()
    --取消遮罩
    self.tempLayer:removeFromParentAndCleanup(true)
    self.container.targetInfoPanel = nil
    self.container:setTableViewsEnabled(true)

    self.refreshSelf()
    self.content.refreshSelf()
  end

  --begin
  --遮罩
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self.container:addChild(self.tempLayer)
  self.container.targetInfoPanel = self.tempLayer
  self.container:setTableViewsEnabled(false)

  --延时处理
  local arr2 = CCArray:create()
  arr2:addObject(CCDelayTime:create(1))
  arr2:addObject(CCCallFunc:create(actionFinished))
  self:runAction(CCSequence:create(arr2))

  --自转动画
  for i = 1, 6 do
    local dice = self.panelUI:getChildByName(string.format("dice_%d", i))
    local diceIndex = self.content.currentResult[i]

    if not (diceIndex == 0) then
      --不是马 自转
      local diceAnimaFrames = {}
      for i = 1, 7 do
        table.insert(diceAnimaFrames, createSpriteFrame(UI_RES_PATH.."/sixhorse/" .. self.content.diceRollTypes[i] .. ".png"))--改资源读取接口导致
      end
     --print("diceAnimaFrames = " .. table.tostring(diceAnimaFrames))
      dice:runAction(CCRepeatForever:create(SpriteUtil:buildAnimate(diceAnimaFrames, 0.1)))

      dice:setPositionX(self.oldPositions[i].x - 12)
      dice:setPositionY(self.oldPositions[i].y + 20)
    end
  end
end