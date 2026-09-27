-- Activity_PhoneChargeLayer.lua
-- 2014-7-8
-- zheng.che
-- 话费活动

--modify_phoneCharge 其他功能关于话费返还活动的修改 搜索关键字

require "canon.panel.PhoneChargeBindPopPanel"
require "canon.panel.PhoneChargeChangePhoneNumberPopPanel"
require "canon.panel.PhoneChargeGainByNumPopPanel"
require "canon.panel.PhoneChargeGainPopPanel"

require "canon.request.PhoneChargeSetNumRequest"
require "canon.request.PhoneChargeGainRequest"
require "canon.request.PhoneChargeGetInfoRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local enter_animation_duration = 0.3
local original_scroll_duration = enter_animation_duration

Activity_PhoneChargeLayer = class(Layer)

-----------------------------------------------------------------------------------------------------------提前定义内容

-------------------------------------------------------------------------------------
-- 事件
-------------------------------------------------------------------------------------

--话费充值相关的数据有更新 无参数
Activity_PhoneChargeLayer.PHONE_CHARGE_DATA_UPDATE = "PHONE_CHARGE_DATA_UPDATE"

-------------------------------------------------------------------------------------
-- 按键事件
-------------------------------------------------------------------------------------

--焦点变化事件
local function onFocusChanged(evt)
  evt.context:setTouchEnabled(evt.data == nil)
end

--绑定手机号码 或者切换绑定信息
local function onBindBtnClick(evt)
  --print("onBindBtnClick")
  Activity_PhoneChargeLayer.tellUserBindPhoneNumber()
end

--去充值/获取话费按钮
local function onChargeBtnClick(evt)
  --print("onChargeBtnClick")
  local self = evt.context
  if Activity_PhoneChargeLayer.havePhoneMoneyLeft() then
    --仍有话费剩余未充值
    --提示获取话费
    Activity_PhoneChargeLayer.tellUserGainPhoneMoney()
  else
    --没有剩余
    --去充值吧

    self.container:replaceScene(ShopScene, {returnScene = "Activity_PhoneCharge", params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
  end
end

-------------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------------
function Activity_PhoneChargeLayer:ctor()
  self.container = nil
  self.extraArgs = nil

  --当前选中的条目
  self.currentSelectedCombineData = nil

  self.showParticles = {}
end

-------------------------------------------------------------------------------------
-- 创建
-------------------------------------------------------------------------------------
function Activity_PhoneChargeLayer:create( container, extraArgs )
  local s = Activity_PhoneChargeLayer.new()
  s.container = container
  s.extraArgs = extraArgs

  s:initLayer()

  return s
end

-------------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------------
function Activity_PhoneChargeLayer:initLayer()
  Activity_PhoneChargeLayer.super.initLayer(self)

  --刷新整个列表显示
  local function refreshSelf()
    --print("refreshSelf ")
    if Activity_PhoneChargeLayer.isBindPhoneNumber() then
      --已绑定
      self.mainUI:getChildByName("txt_chr"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_phoneNumber") .. Activity_PhoneChargeLayer.getBindPhoneNumber())--已绑定手机号码：[xxx]
      self.mainUI:getChildByName("btn_chr1"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_changeNumber"))--更改号码
    else
      --没有绑定号码
      self.mainUI:getChildByName("txt_chr"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_notBound"))--您还没有绑定手机号码
      self.mainUI:getChildByName("btn_chr1"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_bindNumber"))--绑定号码
    end

    if Activity_PhoneChargeLayer.havePhoneMoneyLeft() then
      --仍有话费剩余未充值
      self.mainUI:getChildByName("txt_chr2"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_notClaimed", {num = Activity_PhoneChargeLayer.getPhoneMoneyLeft()}))--您现在就能获得{num}元话费返还
      self.mainUI:getChildByName("btn_chr2"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_claimBtn"))--获取话费
    else
      --没有剩余
      self.mainUI:getChildByName("btn_chr2"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_chargeBtn"))--去充值

      if Activity_PhoneChargeLayer.isTodayRecharged() then
        --今日充值过 说明已经领取了
        self.mainUI:getChildByName("txt_chr2"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_alreadyClaimed"))--您今天已经获得了话费返还
      else
        --今日未充值 说明还有获取机会
        self.mainUI:getChildByName("txt_chr2"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_notCharged"))--您今天还能获得6元话费返还
      end
    end
  end
  self.refreshSelf = refreshSelf

  --初始化界面显示
  self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
  self.builder.useArtLabelTTF = true
  self.mainUI = self.builder:build("launch_activity8")
  self:addChild(self.mainUI)

  --初始化静态文本 和 不变参数的文本--
  --活动说明
  local activityDate = MaintenanceManager:getStartAndEndTime(Activity_PhoneChargeLayer.getFeatureName())
  --活动时间：{year1}年{month1}月{day1}日——{year2}年{month2}月{day2}日
  self.mainUI:getChildByName("txt_chr3"):getChildByName("txt"):setString(Localization:getInstance():getText("phoneCharge_time", {year1 = activityDate[1].year, month1 = activityDate[1].month, day1 = activityDate[1].day, year2 = activityDate[2].year, month2 = activityDate[2].month, day2 = activityDate[2].day}))

  --处理按钮--
  --绑定/更改手机号码按钮
  self.bindBtn = Button:create(self.mainUI:getChildByName("btn_chr1"))
  self.bindBtn:addEventListener(Events.kStart, onBindBtnClick, self)
  --去充值/获取话费按钮
  self.chargeBtn = Button:create(self.mainUI:getChildByName("btn_chr2"))
  self.chargeBtn:addEventListener(Events.kStart, onChargeBtnClick, self)
  

  --加侦听
  UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
  NotificationManager:addEventListener(Activity_PhoneChargeLayer.PHONE_CHARGE_DATA_UPDATE, self.refreshSelf, self)

  --先刷新一下状态
  self.refreshSelf()
end

--返回是否能够显示活动
function Activity_PhoneChargeLayer:enable()
  return Activity_PhoneChargeLayer.isEnable()
end

function Activity_PhoneChargeLayer:dispose()
  UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
  NotificationManager:removeEventListener(Activity_PhoneChargeLayer.PHONE_CHARGE_DATA_UPDATE, self.refreshSelf)

  if self.tickEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.tickEntry)
    self.tickEntry = nil
  end
  Activity_PhoneChargeLayer.super.dispose(self)
end

function Activity_PhoneChargeLayer:setTouchEnabled(v)
  --print("v = " .. tostring(v))
end


-------------------------------------------------------------------------------------------------------------------------------------------------------tableview



-------------------------------------------------------------------------------------------------------------------------------------------------------静态

-------------------------------------------------------------------------------------------------set

--设置绑定的电话号码
function Activity_PhoneChargeLayer.setBindPhoneNumber(value)
  --print("setBindPhoneNumber " .. value)
  local gameInitData = DataManager.getGameInitData()
  if not gameInitData.sharkActivity then
    gameInitData.sharkActivity = {}
  end
  gameInitData.sharkActivity.defaultPhoneNum = value
  DataManager.setGameInitData(gameInitData)
end

--设置剩余话费数量 单位:元
function Activity_PhoneChargeLayer.setPhoneMoneyLeft(value)
  local homeInfo = ActivityPanelScene.getStatusInfo()
  homeInfo.rechargeCallsBalance = value * 100
end

--设置今日是否充值过
function Activity_PhoneChargeLayer.setTodayRechargedState(value)
  local homeInfo = ActivityPanelScene.getStatusInfo()
  homeInfo.dailyRecharge = value
end

-------------------------------------------------------------------------------------------------get

--角标数
function Activity_PhoneChargeLayer.getTipNum()
  if not Activity_PhoneChargeLayer.isEnable() then
    --若未开启则不计入角标数
    return 0, false
  end

  if Activity_PhoneChargeLayer.havePhoneMoneyLeft() then
    --仍有未获取的话费
    return 1, false
  end
  if not Activity_PhoneChargeLayer.isTodayRecharged() then
    --当天并未充值
    return 1, false
  end
	return 0, false
end

--活动id名称
function Activity_PhoneChargeLayer.getFeatureName()
  return "activityPhoneCharge"
end

--获得剩余话费数量
function Activity_PhoneChargeLayer.getPhoneMoneyLeft()
	local homeInfo = ActivityPanelScene.getStatusInfo()
  local result = homeInfo.rechargeCallsBalance or 0
	return result / 100
end

--获得绑定的电话号码
function Activity_PhoneChargeLayer.getBindPhoneNumber()
  local gameInitData = DataManager.getGameInitData()
  if not gameInitData.sharkActivity then
    return nil
  end
  if not gameInitData.sharkActivity.defaultPhoneNum then
    return nil
  end
  --("getBindPhoneNumber " .. gameInitData.sharkActivity.defaultPhoneNum)
  return gameInitData.sharkActivity.defaultPhoneNum
end

--获取配置信息
function Activity_PhoneChargeLayer.getConfigData()
  --print("DataManager.GameMetaData.activitySettingConfig" .. tostringRich(DataManager.GameMetaData.activitySettingConfig))
  if not DataManager.GameMetaData.activitySettingConfig then
    return nil
  end
  return DataManager.GameMetaData.activitySettingConfig.phoneChargeConfig
end

--获得最低充值额度
function Activity_PhoneChargeLayer.getMinPay()
  local configData = Activity_PhoneChargeLayer.getConfigData()
  if not configData then
    return 0
  end
  return configData.minPayment
end

--今日是否充值过
function Activity_PhoneChargeLayer.isTodayRecharged()
  local homeInfo = ActivityPanelScene.getStatusInfo()
  local result = homeInfo.dailyRecharge or false
  return result
end

--获得每日充值话费金额列表(降序排列 如:{3000,1000}) 单位:分
function Activity_PhoneChargeLayer.getChargeAmounts()
  local configData = Activity_PhoneChargeLayer.getConfigData()
  --print("configData = " .. tostringRich(configData))
  if not configData then
    return 0
  end
  return configData.chargeAmounts
end

--通过充钱数量获得返还话费数量 返回单位:分
function Activity_PhoneChargeLayer.getChargeByMoney(money)
  local listData = Activity_PhoneChargeLayer.getChargeAmounts()
  --print("listData = " .. tostringRich(listData))
  for k,v in ipairs(listData) do
    if (money*100) >= v then
      return v / 100
    end
  end
  return 0
end

-------------------------------------------------------------------------------------------------check

--充值话费活动是否有效
function Activity_PhoneChargeLayer.isEnable()
  if not isYYBAndroid() then
    --不在应用宝平台
    if SystemManager.debug then
      print("Activity_PhoneChargeLayer.isEnable : false! 不在应用宝平台! ")
    end
    return false
  end

  local isEnable = MaintenanceManager.isActivityOpen(Activity_PhoneChargeLayer.getFeatureName())
  --print("Activity_PhoneChargeLayer.isEnable = ! " .. tostring(isEnable))
  return isEnable
end

--是否首充过
function Activity_PhoneChargeLayer.isRecharged()
	if tonumber(DataManager.getCurrUser().rechargeGems) <= 0 then
		return false
	end

	return true
end

--是否绑定了手机号码
function Activity_PhoneChargeLayer.isBindPhoneNumber()
  if not Activity_PhoneChargeLayer.getBindPhoneNumber() then
    return false
  end
  return true
end

--是否仍有未领取话费
function Activity_PhoneChargeLayer.havePhoneMoneyLeft()
  local leftMoney = Activity_PhoneChargeLayer.getPhoneMoneyLeft()
  if leftMoney <= 0 then
    return false
  end
  return true
end

-------------------------------------------------------------------------------------------------check alert

--是否符合手机号码校验
function Activity_PhoneChargeLayer.isPhoneNumber(selectedText, withAlert)
  if selectedText == "" then
    --print("不能绑定手机号 因为字符串为空! ")
    if withAlert then
      SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("phoneCharge_wrongNumber"))--输入的手机号码不正确，请仔细检查
    end
    return false
  end

  local firstNum = string.byte(selectedText,-#selectedText);
  if firstNum ~= 49 then
    --print("不能绑定手机号 首位不是1! ")
    if withAlert then
      SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("phoneCharge_wrongNumber"))--输入的手机号码不正确，请仔细检查
    end
    return false
  end

  local numberNum = StringUtil.calcNumberNum(selectedText)
  if numberNum ~= #selectedText then
    --print("不能绑定手机号 不全是数字! ")
    if withAlert then
      SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("phoneCharge_wrongNumber"))--输入的手机号码不正确，请仔细检查
    end
    return false
  end
  if numberNum ~= 11 then
    --print("不能绑定手机号 不是11个字! ")
    if withAlert then
      SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("phoneCharge_wrongNumber"))--输入的手机号码不正确，请仔细检查
    end
    return false
  end

  return true
end

-------------------------------------------------------------------------------------------------option

--提示用户绑定手机号
function Activity_PhoneChargeLayer.tellUserBindPhoneNumber()
  --print("tellUserBindPhoneNumber!")
  local scene = Director:mgr():run()

  if Activity_PhoneChargeLayer.isBindPhoneNumber() then
    --已绑定手机号
    scene.targetInfoPanel = PhoneChargeChangePhoneNumberPopPanel:create(scene)
    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
  else
    --未绑定
    scene.targetInfoPanel = PhoneChargeBindPopPanel:create(scene)
    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
  end
end

--提示用户获得话费
function Activity_PhoneChargeLayer.tellUserGainPhoneMoney()
  --print("tellUserGainPhoneMoney!")
  local scene = Director:mgr():run()

  if Activity_PhoneChargeLayer.isBindPhoneNumber() then
    --已绑定手机号
    scene.targetInfoPanel = PhoneChargeGainPopPanel:create(scene)
    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
  else
    --未绑定
    scene.targetInfoPanel = PhoneChargeGainByNumPopPanel:create(scene)
    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
  end
end
