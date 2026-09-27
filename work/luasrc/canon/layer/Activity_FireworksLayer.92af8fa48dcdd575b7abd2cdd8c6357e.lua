require "canon.request.FireworksFireRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

-------------------------------------------------------------------------------------
-- Activity_FireworksLayer
-- 恭贺新禧layer
-- create by czh @ 2014-1-16
-------------------------------------------------------------------------------------

Activity_FireworksLayer = class(Layer)

--所需的四个道具
local ITEM1 = 400105
local ITEM2 = 400106
local ITEM3 = 400107
local ITEM4 = 400108

-------------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------------
function Activity_FireworksLayer:ctor()
    self.container = nil
    self.extraArgs = nil
end

-------------------------------------------------------------------------------------
-- 创建
-------------------------------------------------------------------------------------
function Activity_FireworksLayer:create( container, extraArgs )
  local s = Activity_FireworksLayer.new()
  self.container = container
  self.extraArgs = extraArgs

  s:initLayer()

  return s
end

-------------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------------
function Activity_FireworksLayer:initLayer()
  Activity_FireworksLayer.super.initLayer(self)

  local boomButton
  --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  --定义几个函数
  --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  --放烟火按钮点击
  local function boomButtonSelected(evt)
    --print("boomButtonSelected")
    if not self:canFire(true) then
      return
    end
    self:fire()
  end

  --刷新显示
  local function refreshSelf()
    --print("refreshSelf")
    --剩余次数数值
    local remain = self:timesRemain()
    --剩余次数:xx
    self.mainUI:getChildByName("txt_firecracker_event10"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_fireworks_remain") .. remain)

    if remain <= 0 then
      --次数为0
      --按钮置灰
      self.mainUI:getChildByName("btn_firework"):getChildByName("lbl_firework"):setVisible(false)
      --self.mainUI:getChildByName("btn_firework"):getChildByName("firecracker"):setVisible(false)
      self.mainUI:getChildByName("btn_firework"):getChildByName("btn"):setVisible(false)
      self.mainUI:getChildByName("btn_firework"):getChildByName("lbl_firework_inactive"):setVisible(true)
      --self.mainUI:getChildByName("btn_firework"):getChildByName("firecracker_inactiv"):setVisible(true)
      self.mainUI:getChildByName("btn_firework"):getChildByName("btn_inactive"):setVisible(true)
      
      boomButton:setEnable(false)
    else
      --还有次数
      --按钮还原
      self.mainUI:getChildByName("btn_firework"):getChildByName("lbl_firework"):setVisible(true)
      --self.mainUI:getChildByName("btn_firework"):getChildByName("firecracker"):setVisible(true)
      self.mainUI:getChildByName("btn_firework"):getChildByName("btn"):setVisible(true)
      self.mainUI:getChildByName("btn_firework"):getChildByName("lbl_firework_inactive"):setVisible(false)
      --self.mainUI:getChildByName("btn_firework"):getChildByName("firecracker_inactiv"):setVisible(false)
      self.mainUI:getChildByName("btn_firework"):getChildByName("btn_inactive"):setVisible(false)

      boomButton:setEnable(true)
    end
  end
  self.refreshSelf = refreshSelf

  --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  --end
  --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  
  --初始化界面显示
  self.builder = LayoutBuilder:createWithContentsOfFile("scene/firecracker_event.json")
  self.builder.useArtLabelTTF = true
  self.mainUI = self.builder:build("firecracker_event")
  self:addChild(self.mainUI)

  --初始化静态文本 和 不变参数的文本
  --获得活动时间
  local timeTable = MaintenanceManager:getStartAndEndTime("activityFireworks");
  --集齐
  self.mainUI:getChildByName("txt_firecracker_event1"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_fireworks_title1"))
  --4个物品的名称
  local item1 = Localization:getInstance():getText(MetaManager.prop_meta[ITEM1].name)
  local item2 = Localization:getInstance():getText(MetaManager.prop_meta[ITEM2].name)
  local item3 = Localization:getInstance():getText(MetaManager.prop_meta[ITEM3].name)
  local item4 = Localization:getInstance():getText(MetaManager.prop_meta[ITEM4].name)
  --print(item1)
  --print(Localization:getInstance():getText("activity_fireworks_title2"))
  --print(self.mainUI:getChildByName("txt_firecracker_event2"):getChildByName("txt"))
  self.mainUI:getChildByName("txt_firecracker_event2"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_fireworks_title2", {num1 = item1, num2 = item2, num3 = item3, num4 = item4}))
  --一套
  self.mainUI:getChildByName("txt_firecracker_event3"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_fireworks_title3"))
  --可以燃放烟花，快来试试吧。
  self.mainUI:getChildByName("txt_firecracker_event4"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_fireworks_title4"))
  --截止日期
  self.mainUI:getChildByName("txt_firecracker_event5"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_fireworks_time"))
  --月份数值
  self.mainUI:getChildByName("txt_firecracker_event6"):getChildByName("txt"):setString(timeTable[2].month)
  --月
  self.mainUI:getChildByName("txt_firecracker_event7"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_fireworks_time1"))
  --日数值
  self.mainUI:getChildByName("txt_firecracker_event8"):getChildByName("txt"):setString(timeTable[2].day)
  --日
  self.mainUI:getChildByName("txt_firecracker_event9"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_fireworks_time2"))

  --初始化按钮
  --放烟花
  boomButton = Button:create(self.mainUI:getChildByName("btn_firework"))
  boomButton:addEventListener(Events.kStart,boomButtonSelected, self)

  --先刷新一下状态
  self:refreshSelf()
end

function Activity_FireworksLayer:enable()
  local isEnable = MaintenanceManager.isActivityOpen("activityFireworks")
  return isEnable
end 

function Activity_FireworksLayer:dispose()
  Activity_FireworksLayer.super.dispose(self)
end

------------------------------------------------------------------------------------------------------------------------------------
--                                                           查询接口
------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
-- 返回能否放烟花
-------------------------------------------------------------------------------------
function Activity_FireworksLayer:canFire(withAlert)
  if self:timesRemain() <= 0 then
    --print("不能fire! 因为: 次数用光了")
    return false
  end

  if BagCalcManager.isFull() then
    if withAlert then
      --原来的提示条会卡
      -- local aContent = Localization:getInstance():getText("bagFull_move")
      -- SuspensionLabel:showContent(self.container, aContent)
      local text = Localization:getInstance():getText("shop_inventoryFull")
      self.targetInfoPanel = NewPackageFullPanel:show()
    end
    --print("不能fire! 因为: 背包已满")
    return false
  end

  return true
end

-------------------------------------------------------------------------------------
-- 剩余的数量
-------------------------------------------------------------------------------------
function Activity_FireworksLayer:timesRemain()
  --print("timesRemain")
  local result = 0

  --取最小值
  -- print("BagCalcManager.getNumById(ITEM1) = " .. BagCalcManager.getNumById(ITEM1))
  -- print("BagCalcManager.getNumById(ITEM2) = " .. BagCalcManager.getNumById(ITEM2))
  -- print("BagCalcManager.getNumById(ITEM3) = " .. BagCalcManager.getNumById(ITEM3))
  -- print("BagCalcManager.getNumById(ITEM4) = " .. BagCalcManager.getNumById(ITEM4))
  result = BagCalcManager.getNumById(ITEM1)--灯笼
  result = math.min(result, BagCalcManager.getNumById(ITEM2))--红包
  result = math.min(result, BagCalcManager.getNumById(ITEM3))--年糕
  result = math.min(result, BagCalcManager.getNumById(ITEM4))--剪纸

  return result
end

------------------------------------------------------------------------------------------------------------------------------------
--                                                         私有处理接口
------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
-- 向后台请求放烟火
-------------------------------------------------------------------------------------
function Activity_FireworksLayer:fire()
  --print("fire")

  --成功
  local function onSucceed(event)
    --奖励物品
    --print("放烟火返回成功信息 = " .. table.tostring(event))
    self.rewardList = event.data.rewards
    self:playAnime()
  end 
  --失败
  local function onFailed(event)
    --print("放烟火返回失败信息 = " .. table.tostring(event))
    if event.data == 716230 then  --fireworks activity is closed: {0:uid}
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("activity_goldGod_end_remind")
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
  local request = FireworksFireRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.FireworksFireSucceed, onSucceed)
  request:addEventListener(RequestNotifyEnum.FireworksFireFailed, onFailed)
  request:start()

  --test
  --onSucceed({data = {diceStates = {0, 0, 2, 3, 4, 5, 6}}})
end

--播放动画
function Activity_FireworksLayer:playAnime()
  --print("播放动画")


  --遮罩
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self.container:addChild(self.tempLayer)
  self.container.targetInfoPanel = self.tempLayer
  self.container:setTableViewsEnabled(false)

  --隐藏背后的关闭宝箱
  self.mainUI:getChildByName("icon_dragon_box"):setVisible(false)

  local fspt = FlashSprite:create("EVO2/dragon_box")
  fspt:changeAnimation(0)
  fspt:setLoop(false)
  local fspt_co = CocosObject.new(fspt)
  local function bossbreakAnimationEnd(anim)
    fspt:unregisterEndAnimationScriptHandler()
    self.container:removeChild(fspt_co)

    --取消遮罩
    self.tempLayer:removeFromParentAndCleanup(true)
    self.container.targetInfoPanel = nil
    self.container:setTableViewsEnabled(true)

    --隐藏背后的关闭宝箱
    self.mainUI:getChildByName("icon_dragon_box"):setVisible(true)
    
    self:doPlayComplete()
  end
  fspt:registerEndAnimationScriptHandler(bossbreakAnimationEnd)
  self.container:addChild(fspt_co)
  -- fspt:setPositionX(fspt:getPositionX() + 150)
  -- fspt:setPositionY(fspt:getPositionY() + 600)
end

--播放完毕后的操作
function Activity_FireworksLayer:doPlayComplete()
  --print("播放动画完毕")
  --print(self.rewardList)

  --已获得物品
  local function onGet()
    --加奖励
    RewardManager:getReward(self.rewardList)

    --扣道具
    local delItems = {}
    table.insert(delItems, {itemType = ResourceEnum.PROP, metaId = ITEM1, amount = -1})
    table.insert(delItems, {itemType = ResourceEnum.PROP, metaId = ITEM2, amount = -1})
    table.insert(delItems, {itemType = ResourceEnum.PROP, metaId = ITEM3, amount = -1})
    table.insert(delItems, {itemType = ResourceEnum.PROP, metaId = ITEM4, amount = -1})
    RewardManager:getReward(delItems)

    --刷新显示
    self.refreshSelf()
    self.container:resetTipInfoForActivity("Activity_Fireworks")
  end

  local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = self.rewardList, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), callback = onGet} )
  self.container:addChild(aRewardPanel)
  aRewardPanel:scaleIn()

end

function Activity_FireworksLayer.getTipNum()
  if not Activity_FireworksLayer.enable() then
    return 0
  end
  local result1 = 0	--灯笼
  local result2 = 0	--红包
  local result3 = 0	--年糕
  local result4 = 0	--剪纸
  local propDataList = DataManager.getPropsData()
  for _, v in pairs(propDataList) do
    if tonumber(v.metaId, 10) == 400105 then
      result1 = result1 + 1
    elseif tonumber(v.metaId, 10) == 400106 then
      result2 = result2 + 1
    elseif tonumber(v.metaId, 10) == 400107 then
      result3 = result3 + 1
    elseif tonumber(v.metaId, 10) == 400108 then
      result4 = result4 + 1
    end
  end
  local result = 0
  result = math.min(result1, result2, result3, result4)
  --[[
  result = BagCalcManager.getNumById(400105)--灯笼
  result = math.min(result, BagCalcManager.getNumById(400106))--红包
  result = math.min(result, BagCalcManager.getNumById(400107))--年糕
  result = math.min(result, BagCalcManager.getNumById(400108))--剪纸
  --]]
  return result
end
