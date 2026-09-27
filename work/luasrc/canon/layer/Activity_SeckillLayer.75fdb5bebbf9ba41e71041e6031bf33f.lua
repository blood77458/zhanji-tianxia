--
-- Activity_SeckillLayer.lua
-- Author: zheng.che
-- Date: 2014-04-23 16:52:38
-- 限时秒杀活动
--
require "canon.request.SeckillBuyRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local exchangeTable_width = visibleSize.width
local exchangeTable_height = 500
local exchangeItem_width = visibleSize.width
local exchangeItem_height = 500
local exchangeTable_posX = 0
local exchangeTable_posY = 195

-- local exchangeTable_width = visibleSize.width
-- local exchangeTable_height = 500
-- local exchangeItem_width = 100
-- local exchangeItem_height = 500
-- local exchangeTable_posX = 0
-- local exchangeTable_posY = 190

local enter_animation_duration = 0.3
local original_scroll_duration = enter_animation_duration

Activity_SeckillLayer = class(Layer)

--焦点变化事件
local function onFocusChanged(evt)
  evt.context:setTouchEnabled(evt.data == nil)
end

--跨天事件
local function onPassDay(evt)
  local self = evt.context
  if Activity_SeckillLayer.checkTodayHaveList() then
    --隔天有新数据的情况下 刷新至新数据
    Activity_SeckillLayer.clearSaleInfoHash()
    self.refreshSelf()
  end
end

--左按钮点击
local function onLeftBtnClick(evt)
  --print("onLeftBtnClick")
  local self = evt.context
  self:gotoIndex(self.currentSelectedIndex - 1, false)
end

--右按钮点击
local function onRightBtnClick(evt)
  --print("onLeftBtnClick")
  local self = evt.context
  self:gotoIndex(self.currentSelectedIndex + 1, false)
end

-------------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------------
function Activity_SeckillLayer:ctor()
  self.container = nil
  self.extraArgs = nil

  --当前选中的条目
  self.currentSelectedCombineData = nil

  self.showParticles = {}
end

-------------------------------------------------------------------------------------
-- 创建
-------------------------------------------------------------------------------------
function Activity_SeckillLayer:create( container, extraArgs )
  local s = Activity_SeckillLayer.new()
  s.container = container
  s.extraArgs = extraArgs

  s:initLayer()

  return s
end

-------------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------------
function Activity_SeckillLayer:initLayer()
  Activity_SeckillLayer.super.initLayer(self)

  if not self.todayMark then
    self.todayMark = PassDayManager.getTodayMark()
  end

  --先判断是否跨天
  if self.todayMark ~= PassDayManager.getTodayMark() then
    Activity_SeckillLayer.clearSaleInfoHash()
  end

  --刷新整个列表显示
  local function refreshSelf()
    for i = #self.dataList, 1, -1 do
      table.remove(self.dataList, i)
    end

    local tempList = Activity_SeckillLayer.getTodaySaleList()
    --print("tempList = " .. table.tostring(tempList))

    for _, v in ipairs(tempList) do
      table.insert(self.dataList, v)
    end

    self.listTableView:reloadData()

    --移动到初始位置
    self:gotoIndex(Activity_SeckillLayer.firstKillIndex(), true)
  end
  self.refreshSelf = refreshSelf

  --刷新其中某一条数据显示
  local function refreshItemData(aCombineData)
    local index = table.indexOf(self.dataList, aCombineData)
    if not index then
      return
    end
    local newCell = self.listTableView:cellAtIndex(index-1)
    if not newCell then
      return
    end
    self.listTableView.tableViewRenderer:setData(newCell, index-1)
  end
  self.refreshItemData = refreshItemData

  --每秒触发计时器 用于刷新倒计时时间和状态
  local function onTick()
    --刷新当前选中的条目显示到标题的状态
    if self.currentSelectedCombineData then
      --print("tick")
      local aData = self.currentSelectedCombineData[1]

      local beginTime = Activity_SeckillLayer.getItemBeginTimestame(aData)
      local endTime = beginTime + aData.timeContinue * 60
      local crrentTime = TimeUtil.getServerTimeSeconds()
      if crrentTime < beginTime then
        --未开始
        self.mainUI:getChildByName("txt_weekend_sale_time"):setVisible(true)
        self.mainUI:getChildByName("lbl_weekend_sale"):setVisible(true)

        self.mainUI:getChildByName("txt_weekend_sale_info"):setVisible(false)

        local formatedTimeStr = TimeUtil.formatTimeWithHM(aData.timeBegin*60)
        self.mainUI:getChildByName("txt_weekend_sale_time"):getChildByName("txt"):setString(formatedTimeStr)
      elseif crrentTime > endTime then
        --已结束
        self.mainUI:getChildByName("txt_weekend_sale_time"):setVisible(false)
        self.mainUI:getChildByName("lbl_weekend_sale"):setVisible(false)

        self.mainUI:getChildByName("txt_weekend_sale_info"):setVisible(true)

        self.mainUI:getChildByName("txt_weekend_sale_info"):getChildByName("txt"):setString(getTextByKey("activity_seckill_activityend"))--本轮秒杀已结束
      else
        --进行中
        self.mainUI:getChildByName("txt_weekend_sale_time"):setVisible(false)
        self.mainUI:getChildByName("lbl_weekend_sale"):setVisible(false)

        self.mainUI:getChildByName("txt_weekend_sale_info"):setVisible(true)

        self.mainUI:getChildByName("txt_weekend_sale_info"):getChildByName("txt"):setString(getTextByKey("activity_seckill_remainingtime") .. TimeUtil.formatTime(endTime - crrentTime))--剩余时间：
      end
    end

    --刷新每一条的状态
    for k, v in ipairs(self.dataList) do
      local newCell = self.listTableView:cellAtIndex(k-1)
      if not newCell then
        return
      end
      self.listTableView.tableViewRenderer:refreshTime(newCell, v)
    end
  end
  self.onTick = onTick

  --初始化界面显示
  self.builder = LayoutBuilder:createWithContentsOfFile("scene/weekend_sale.json")
  self.builder.useArtLabelTTF = true
  self.mainUI = self.builder:build("weekend_sale")
  self:addChild(self.mainUI)

  --初始化静态文本 和 不变参数的文本
  --活动说明
  self.mainUI:getChildByName("txt_weekend_sale6"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_seckill_advertisement"))

  --初始化各种组件
  self.leftBtn = Button:create(self.mainUI:getChildByName("icon_sliding_l"))
  self.leftBtn:addEventListener(Events.kStart, onLeftBtnClick, self)

  self.rightBtn = Button:create(self.mainUI:getChildByName("icon_sliding_r"))
  self.rightBtn:addEventListener(Events.kStart, onRightBtnClick, self)

  self.dataList = {}

  --初始化列表
  self.listTableView = self:createListTableView()
  self.mainUI:addChild(self.listTableView)

  --改按钮层级
  self.mainUI:removeChild(self.leftBtn.display, false)
  self.mainUI:addChild(self.leftBtn.display)
  self.mainUI:removeChild(self.rightBtn.display, false)
  self.mainUI:addChild(self.rightBtn.display)

  --初始化计时器
  self.tickEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(self.onTick, 1, false)--间隔1s

  --加侦听
  UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
  NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)

  --先刷新一下状态
  self.refreshSelf()
end

--返回是否能够显示活动
function Activity_SeckillLayer:enable()
  if not DataManager.GameMetaData.activitySeckillConfig then
    print("Activity_SeckillLayer:enable 没有配置! ")
    return false
  end
  local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activitySeckillConfig.featureName)
  --print("Activity_SeckillLayer:enable isEnable = ! " .. tostring(isEnable))
  return isEnable
end

--移动到某一位置
function Activity_SeckillLayer:gotoIndex(aIndex, forceMove)
  --延时结束
  local function actionFinished()
    self.moving = false
  end

  if not self.moving then
    --print("-exchangeTable_width * (aIndex - 1) = " .. (-exchangeTable_width * (aIndex - 1)))
    self:setCurrentSelectIndex(aIndex)
    if forceMove then
      --直接移动 没有缓动 没有延时处理
      self.listTableView:setContentOffset(ccp(-exchangeTable_width * (aIndex - 1), 0))
    else
      self.listTableView:setContentOffsetInDuration(ccp(-exchangeTable_width * (aIndex - 1), 0), original_scroll_duration)
      self.moving = true

      --延时处理
      local arr2 = CCArray:create()
      arr2:addObject(CCDelayTime:create(original_scroll_duration))
      arr2:addObject(CCCallFunc:create(actionFinished))
      self:runAction(CCSequence:create(arr2))
    end
  end
end

--设置当前选择的数据
function Activity_SeckillLayer:setCurrentSelectIndex(aIndex)
  local tempCombineData = self.dataList[aIndex]
  if tempCombineData then
    self.currentSelectedIndex = aIndex
    self.currentSelectedCombineData = tempCombineData
    --print("self.currentSelectedCombineData = " .. table.tostring(self.currentSelectedCombineData))

    if self.currentSelectedIndex <= 1 then
      self.leftBtn.display:setVisible(false)
      self.leftBtn:setEnable(false)
    else
      self.leftBtn.display:setVisible(true)
      self.leftBtn:setEnable(true)
    end

    if self.currentSelectedIndex >= #self.dataList then
      self.rightBtn.display:setVisible(false)
      self.rightBtn:setEnable(false)
    else
      self.rightBtn.display:setVisible(true)
      self.rightBtn:setEnable(true)
    end

    self.onTick()
  end
end

function Activity_SeckillLayer:dispose()
  UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
  NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)

  if self.tickEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.tickEntry)
    self.tickEntry = nil
  end
  Activity_SeckillLayer.super.dispose(self)
end

function Activity_SeckillLayer:setTouchEnabled(v)
  --print("v = " .. tostring(v))
  self.listTableView:setTouchEnabled(v)
end


-------------------------------------------------------------------------------------------------------------------------------------------------------tableview

-------------------------------------------------------------------------------------
-- 生成列表
-------------------------------------------------------------------------------------
function Activity_SeckillLayer:createListTableView()
  local cellTag = 1024
  local buttonTag = {{-11, -31}, {-12, -31}}
  local aExchangeScene = self
  local ExchangeTableViewRenderer = class(TableViewRenderer)

  --文件初始化
  function ExchangeTableViewRenderer:ctor(width, height)
    self.list = aExchangeScene.dataList
  end

  --创建单元
  function ExchangeTableViewRenderer:buildCell(container)
    --print("buildCell")
    local builder = LayoutBuilder:createWithContentsOfFile("scene/weekend_sale.json")
    local aCombineCell = builder:build("list_weekend_sale_combine")
    container:addChild(aCombineCell)
    aCombineCell:setTag(cellTag)

    for i = 1, 2 do
      local aCell = aCombineCell:getChildByName("newlist_weekend_sale" .. i)
      aCell:setTag(-10 - i)

      --物品图标
      local aGoodIcon = aCell:getChildByName("normal_card_small")
      aGoodIcon:setTag(-11)

      --物品名称
      local aNameTxt = aCell:getChildByName("txt_weekend_sale1")
      aNameTxt:setTag(-12)
      aNameTxt:getChildByName("txt"):setTag(-12)

      --物品描述 明阳:不要了
      -- local aDescriptionTxt = aCell:getChildByName("txt_weekend_sale1_2")
      -- aDescriptionTxt:setTag(-13)
      -- aDescriptionTxt:getChildByName("txt"):setTag(-13)

      --原价
      local aOldPriceTxt = aCell:getChildByName("txt_weekend_sale2")
      aOldPriceTxt:setTag(-14)
      aOldPriceTxt:getChildByName("txt"):setTag(-14)

      --现价
      local aNowPriceTxt = aCell:getChildByName("txt_weekend_sale3")
      aNowPriceTxt:setTag(-15)
      aNowPriceTxt:getChildByName("txt"):setTag(-15)

      --剩余数量
      local aLastNumTxt = aCell:getChildByName("txt_weekend_sale10")
      aLastNumTxt:setTag(-16)
      aLastNumTxt:getChildByName("txt"):setTag(-16)

      --购买次数
      local aUsedTimesTxt = aCell:getChildByName("txt_weekend_sale4")
      aUsedTimesTxt:setTag(-17)
      aUsedTimesTxt:getChildByName("txt"):setTag(-17)

      --完售说明
      local aDescriptionTxt = aCell:getChildByName("txt_weekend_sale7")
      aDescriptionTxt:setTag(-18)
      aDescriptionTxt:getChildByName("txt"):setTag(-18)

      --银币标志
      local aSilverIcon = aCell:getChildByName("icon_silverCoin")
      aSilverIcon:setTag(-19)

      --金币标志
      local aGoldIcon = aCell:getChildByName("icon_manycoin")
      aGoldIcon:setTag(-20)

      -- --剩余时间
      -- local aLeftTime = aCell:getChildByName("txt_weekend_sale8")
      -- aLeftTime:setTag(-21)
      -- aLeftTime:getChildByName("txt"):setTag(-21)

      --"还剩"
      local aLeftNumLeftTxt = aCell:getChildByName("txt_weekend_sale9")
      aLeftNumLeftTxt:getChildByName("txt"):setString(Localization:getInstance():getText("activity_seckill_surplusnum"))--还剩
      aLeftNumLeftTxt:setTag(-22)

      --"份"
      local aLeftNumRightTxt = aCell:getChildByName("txt_weekend_sale11")
      aLeftNumRightTxt:getChildByName("txt"):setString(Localization:getInstance():getText("activity_seckill_surplusnum1"))--份
      aLeftNumRightTxt:setTag(-23)

      --剩余数量文字的背景
      local aNumBg = aCell:getChildByName("other_gray9_panel5")
      aNumBg:setTag(-24)

      --购买按钮
      local aBtnBuy = aCell:getChildByName("btn_nowbuy")
      aBtnBuy:setTag(-31)
      aBtnBuy:getChildByName("txt"):setTag(-11)
      aBtnBuy:getChildByName("txt"):setString(Localization:getInstance():getText("activity_seckill_buyBtn"))--购买
      aBtnBuy:getChildByName("normal"):setTag(-12)
      aBtnBuy:getChildByName("disable"):setTag(-13)
    end
  end

  --获得数据
  function ExchangeTableViewRenderer:setData( rawCocosObj, index )
    local aCombineCell = self:getChildByTag(rawCocosObj, cellTag)
    local aCombineData = self.list[index+1]

    -- if aCombineData == 0 then
    --   aCombineCell:setVisible(false)
    --   return
    -- end

    for i = 1, 2 do
      local aCell = aCombineCell:getChildByTag(-10 - i)
      local aData = aCombineData[i]

      --print("index = " .. index)
      --print("#self.list = " .. #self.list)
      --print("self.list[" .. (index+1) .. "] : " .. table.tostring(self.list[index+1]))

      -- <bean desc="秒杀活动物品配置">
      -- <property code="id" type="int" desc="活动配置id" />
      -- <property code="itemType" type="int" desc="物品类型" />
      -- <property code="itemNum" type="int" desc="物品数量" />
      -- <property code="itemId" type="int" desc="物品配置id" />
      -- <property code="limitNum" type="int" desc="单人限购数量" />
      -- <property code="activeTime" type="int" desc="物品开放时间（单位天）" />
      -- <property code="timeBegin" type="int" desc="秒杀起始时间（单位分钟）" />
      -- <property code="timeContinue" type="int" desc="秒杀持续时间（单位分钟）" />
      -- <property code="coinType" type="int" desc="货币类型（1：银币，2：金币）" />
      -- <property code="realNum" type="int" desc="真实库存" />
      -- <property code="showNum" type="int" desc="显示库存" />
      -- <property code="costPrice" type="int" desc="原始价格" />
      -- <property code="presentPrice" type="int" desc="折后价格" />
      -- </bean>

      local icon = aCell:getChildByTag(-101)
      if icon then
        icon:removeFromParentAndCleanup(true)
      end
      local aGoodIcon = aCell:getChildByTag(-11)
      local params = {}
      params.sourceDisplay = aGoodIcon
      params.container = aCell
      params.showInCenter = true
      params.zindex = 10
      icon = CanonGoodIcon.createGoodIcon(aData.itemType, aData.itemId, aData.itemNum, params)
      if icon then
        icon:setTag(-101)
        icon:dispose()
      end

      local aNameTxt = aCell:getChildByTag(-12):getChildByTag(-12)
      local goodName = CanonGoodIcon.getGoodName(aData.itemType, aData.itemId, aData.itemNum, {})
      setNodeText(aNameTxt, goodName)

      -- local aDescriptionTxt = aCell:getChildByTag(-13):getChildByTag(-13)
      -- setNodeText(aDescriptionTxt, "xxx")

      local aOldPriceTxt = aCell:getChildByTag(-14):getChildByTag(-14)
      setNodeText(aOldPriceTxt, CanonGoodIcon.formatResourceNumStr(aData.costPrice))

      local aNowPriceTxt = aCell:getChildByTag(-15):getChildByTag(-15)
      setNodeText(aNowPriceTxt, CanonGoodIcon.formatResourceNumStr(aData.presentPrice))

      local aSilverIcon = aCell:getChildByTag(-19)
      local aGoldIcon = aCell:getChildByTag(-20)
      if aData.coinType == 1 then
        --银币
        aSilverIcon:setVisible(true)
        aGoldIcon:setVisible(false)
      else
        --金币
        aSilverIcon:setVisible(false)
        aGoldIcon:setVisible(true)
      end

      --购买次数
      local aUsedTimesTxt = aCell:getChildByTag(-17)
      setNodeText(aUsedTimesTxt:getChildByTag(-17), Localization:getInstance():getText("activity_seckill_purchasetimes", {num1 = Activity_SeckillLayer.getTodayMyBroughtTimes(aData.id), num2 = aData.limitNum}))--限购：{num1}/{num2}

    end


    --默认首先刷新一次时间状态
    self:refreshTime(rawCocosObj, aCombineData)
  end

  --更新时间状态
  function ExchangeTableViewRenderer:refreshTime(rawCocosObj, aCombineData)
    local aCombineCell = self:getChildByTag(rawCocosObj, cellTag)

    for i = 1, 2 do
      local aCell = aCombineCell:getChildByTag(-10 - i)
      local aData = aCombineData[i]

      --剩余数量(3部分)
      local aLastNumTxt = aCell:getChildByTag(-16)
      local aLeftNumLeftTxt = aCell:getChildByTag(-22)
      local aLeftNumRightTxt = aCell:getChildByTag(-23)
      --完售说明
      local aDescriptionTxt = aCell:getChildByTag(-18)
      --文字背景
      local aNumBg = aCell:getChildByTag(-24)

      --根据剩余时间控制状态
      local beginTime = Activity_SeckillLayer.getItemBeginTimestame(aData)
      local endTime = beginTime + aData.timeContinue * 60
      local crrentTime = TimeUtil.getServerTimeSeconds()
      if (crrentTime > endTime) then
        --已结束 不显示剩余数量和售罄提示
        aLastNumTxt:setVisible(false)
        aLeftNumLeftTxt:setVisible(false)
        aLeftNumRightTxt:setVisible(false)
        aDescriptionTxt:setVisible(false)
        aNumBg:setVisible(false)
      else
        --显示剩余数量或者完售
        aNumBg:setVisible(true)--显示背景

        local showLastNum = Activity_SeckillLayer.getShowLastNum(aData.id, aData)
        if showLastNum <= 0 then
          --卖光了
          aLastNumTxt:setVisible(false)
          aLeftNumLeftTxt:setVisible(false)
          aLeftNumRightTxt:setVisible(false)

          aDescriptionTxt:setVisible(true)

          setNodeText(aDescriptionTxt:getChildByTag(-18), Localization:getInstance():getText("activity_seckill_exhausted"))--库存告罄，下次请早
        else
          --还有库存
          aLastNumTxt:setVisible(true)
          aLeftNumLeftTxt:setVisible(true)
          aLeftNumRightTxt:setVisible(true)

          aDescriptionTxt:setVisible(false)

          setNodeText(aLastNumTxt:getChildByTag(-16), showLastNum)--[剩余数量]
        end
      end

      --购买按钮    
      local aBtnBuy = aCell:getChildByTag(-31)

      if Activity_SeckillLayer.checkCanClickBtn(aData) then
        --按钮启用
        aBtnBuy:getChildByTag(-12):setVisible(true)
        aBtnBuy.ignoreTouch = false
      else
        --按钮禁用
        aBtnBuy:getChildByTag(-12):setVisible(false)
        aBtnBuy.ignoreTouch = true
      end
    end
  end

  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local aCombineData = self.dataList[aIndex]

    local newCell = self.listTableView:cellAtIndex(aIndex - 1)
    local aCombineCell = newCell:getChildByTag(cellTag)

    for i = 1, 2 do
      local aCell = aCombineCell:getChildByTag(-10 - i)
      local aData = aCombineData[i]

      local buttonDisplay = aCell:getChildByTag(-31)
      local exchangeDisplay = buttonDisplay:getChildByTag(-12)
      local exchangeSize = exchangeDisplay:getContentSize()
      --print(buttonDisplay:getPositionX(), buttonDisplay:getPositionY())
      local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
      --print(posInCell.x, posInCell.y)
      if posInCell.x > buttonDisplay:getPositionX() and
      posInCell.x < (buttonDisplay:getPositionX() + exchangeSize.width) and
      posInCell.y > (buttonDisplay:getPositionY() - exchangeSize.height) and
      posInCell.y < buttonDisplay:getPositionY() then
        --点击按钮
        --print("点击按钮! aData = " .. table.tostring(aData))
        if Activity_SeckillLayer.checkCanGain(aData) then
          Activity_SeckillLayer.gain(aData, aCombineData, self)
        end
      end

      local cardDisplay = aCell:getChildByTag(-11)
      exchangeDisplay = cardDisplay
      exchangeSize = HeDisplayUtil:getNodeGroupBounds(exchangeDisplay, nil, kHitAreaObjectTag).size
      -- print("posInCell.x = " .. posInCell.x)
      -- print("posInCell.y = " .. posInCell.y)
      -- print("cardDisplay:getPositionX() = " .. cardDisplay:getPositionX())
      -- print("cardDisplay:getPositionY() = " .. cardDisplay:getPositionY())
      -- print("exchangeSize.width = " .. exchangeSize.width)
      -- print("exchangeSize.height = " .. exchangeSize.height)
      if posInCell.x > (cardDisplay:getPositionX()) and
      posInCell.x < (cardDisplay:getPositionX() + exchangeSize.width) and
      posInCell.y > (cardDisplay:getPositionY() - exchangeSize.height) and
      posInCell.y < (cardDisplay:getPositionY()) then
        --点击物品图标
        --print("点击物品图标! aData = " .. table.tostring(aData))
        CanonGoodIcon.popoutGoodPanel(aData.itemType, aData.itemId)
      end
    end
  end

  --选中某一组合
  local function onSelectItem( evt )
    local aIndex = evt.globalPosition + 1
    --print("self.listTableView:getContentOffset().x = " .. self.listTableView:getContentOffset().x)
    -- print("self:getTag() = " .. self:getTag())
    --print("self.dataList = " .. table.tostring(self.dataList or {"nil"}))
    self:setCurrentSelectIndex(aIndex)
  end

  --开始
  local renderer = ExchangeTableViewRenderer.new(exchangeItem_width, exchangeItem_height)
  local aTableView = TableView:create(renderer, exchangeTable_width, exchangeTable_height, cellTag, buttonTag)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , aTableView)
  --aTableView:addEventListener(DisplayEvents.kSelectItem, onSelectItem , self)
  aTableView:setPosition(ccp(exchangeTable_posX, exchangeTable_posY))
  aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  --aTableView:setPageEnabled(true)--自动对齐位置
  aTableView:setDragEnabled(false)--不能拖拽
  return aTableView
end

-------------------------------------------------------------------------------------------------------------------------------------------------------静态

--秒杀物品信息查询表 id -> data
local saleInfoHash = {}

-------------------------------------------------------------------------------------------------set

--设置自己当天已购买列表
function Activity_SeckillLayer.addTodayMyBroughtTimes(aId)
  local todayBroughtList = DailyDataManager.getDailyDataSeckillLimitGoods()
  if not todayBroughtList then
    todayBroughtList = {}
  end

  local hasId = false
  for k, v in ipairs(todayBroughtList) do
    if v.goodMetaId == aId then
      hasId = true
      v.dailyPurchaseTimes = v.dailyPurchaseTimes + 1
    end
  end

  if not hasId then
    table.insert(todayBroughtList, {goodMetaId = aId, dailyPurchaseTimes = 1})
  end
  DailyDataManager.setDailyDataSeckillLimitGoods(todayBroughtList)
end

--设置秒杀物品信息列表(实际上是和当前状态比较 取多的数值)
function Activity_SeckillLayer.setSaleInfoList(vHash)
  --print("vHash = " .. table.tostring(vHash))
  for k, v in pairs(vHash) do
    local currentNum = saleInfoHash[k] or 0
    --print("currentNum" .. currentNum)
    if currentNum < v.buyNum then
      saleInfoHash[k] = v.buyNum
    end
  end
end

--某物品真实已购买数量+1
function Activity_SeckillLayer.addRealBroughtNum(aId)
  local broughtNum = saleInfoHash[aId]
  if not broughtNum then
    saleInfoHash[aId] = 0
  end
  saleInfoHash[aId] = saleInfoHash[aId] + 1
end

--某物品真实已购买数量=max
function Activity_SeckillLayer.setSoldOut(aId)
  --print("setSoldOut")
  local saleList = Activity_SeckillLayer.getAllSaleList()
  for k, v in ipairs(saleList) do
    if v.id == aId then
      --print("v.realNum = " .. v.realNum)
      saleInfoHash[aId] = v.realNum
    end
  end
end

--清空服务器购买记录
function Activity_SeckillLayer.clearSaleInfoHash()
  --print("Activity_SeckillLayer.clearSaleInfoHash! ")
  saleInfoHash = {}
end

-------------------------------------------------------------------------------------------------get

--获得自己当天已购买次数
function Activity_SeckillLayer.getTodayMyBroughtTimes(aId)
  local todayBroughtList = DailyDataManager.getDailyDataSeckillLimitGoods()
  if not todayBroughtList then
    --print("not todayBroughtList!")
    return 0
  end
  -- print("aId = " .. aId)
  -- print("todayBroughtList = " .. table.tostring(todayBroughtList))

  local hasId = false
  for k, v in ipairs(todayBroughtList) do
    if v.goodMetaId == aId then
      return v.dailyPurchaseTimes
    end
  end
  return 0
end

--获取配置信息
function Activity_SeckillLayer.getConfigData()
  return DataManager.GameMetaData.activitySeckillConfig or {}
end

--获取配置的起始时间是星期几(0-6 = Sunday-Saturday)
function Activity_SeckillLayer.getConfigStartWeekday()
  local activityConfig = MaintenanceManager:findActivityConfig(Activity_SeckillLayer.getConfigData().featureName)
  if not activityConfig then
    --print("未找到此活动! meta.featureName = " .. meta.featureName)
    return {}
  end
  return math.mod(activityConfig.activityUnite, 7)--配置是(1-7 = Monday-Sunday)
end

--获取物品列表
function Activity_SeckillLayer.getAllSaleList()
  return Activity_SeckillLayer.getConfigData().seckillItemMetas or {}
end

--获取当天显示的物品列表
function Activity_SeckillLayer.getTodaySaleList()
  local tempTodayHash = {}
  local totalList = Activity_SeckillLayer.getAllSaleList()
  --print("#totalList = " .. #totalList)

  local todayWeekday = TimeUtil.getTodayWeekday()
  local startWeekday = MaintenanceManager:getActivityBeginWeekday(Activity_SeckillLayer.getConfigData().featureName)
  --print("todayWeekday = " .. todayWeekday)
  --print("startWeekday = " .. startWeekday)
  for k, v in ipairs(totalList) do
    --print("v.activeTime = " .. v.activeTime)
    if math.mod(v.activeTime + startWeekday, 7) == todayWeekday then
      local tempCombine = tempTodayHash[v.timeBegin]
      if not tempCombine then
        tempCombine = {}
        tempTodayHash[v.timeBegin] = tempCombine
      end
      table.insert(tempCombine, v)
    end
  end

  local result = {}
  for k, v in pairs(tempTodayHash) do
    table.insert(result, v)
  end

  --排序
  local function sortFunc(a, b)
    return (a[1].timeBegin < b[1].timeBegin)
  end
  table.sort(result, sortFunc)

  return result
end

--查询某物品真实已购买数量
function Activity_SeckillLayer.getRealBroughtNum(aId)
  local result = saleInfoHash[aId]
  if not result then
    return 0
  end
  return result
end

--查询某物品的真实剩余数量
function Activity_SeckillLayer.getRealLastNum(aId, aData)
  local saleList = Activity_SeckillLayer.getAllSaleList()
  for k, v in ipairs(saleList) do
    if v.id == aId then
      aData = v
    end
  end

  if not aData then
    return 0
  end

  local broughtNum = Activity_SeckillLayer.getRealBroughtNum(aData.id)
  local result =  aData.realNum - broughtNum
  if result < 0 then
    result = 0
  end
  return result
end

--查询某物品的显示剩余数量
function Activity_SeckillLayer.getShowLastNum(aId, aData)
  local saleList = Activity_SeckillLayer.getAllSaleList()
  for k, v in ipairs(saleList) do
    if v.id == aId then
      aData = v
    end
  end

  if not aData then
    return 0
  end

  local realLastNum = Activity_SeckillLayer.getRealLastNum(aId, aData)
  --print("realLastNum = " .. realLastNum)
  local result = math.floor(realLastNum * aData.showNum / aData.realNum)
  --print("result = " .. result)
  return result
end

--角标数
function Activity_SeckillLayer.getTipNum()
  local whetherEnable = Activity_SeckillLayer.enable()
  if not whetherEnable then
    return 0, false
  end

  if Activity_SeckillLayer.isInKillTime(whetherEnable) then
    return 1, true
  end
  return 0, true
end

--获得某一购买项的开始时间戳
function Activity_SeckillLayer.getItemBeginTimestame(aData)
  --print("aData = " .. table.tostring(aData))
  local todayWeekday = TimeUtil.getTodayWeekday()
  local startWeekday = MaintenanceManager:getActivityBeginWeekday(Activity_SeckillLayer.getConfigData().featureName)

  if aData.beginTimestamp == nil then
    local hour = math.floor(aData.timeBegin / 60)
    local min = math.mod(aData.timeBegin, 60)
    aData.beginTimestamp = TimeUtil.getTodayTimestampBy(hour, min)

    if math.mod(aData.activeTime + startWeekday, 7) ~= todayWeekday then
      --实际上不是今天的 就当是昨天的好了 -1天
      aData.beginTimestamp = aData.beginTimestamp - TimeUtil.DAY
    end
  end
  return aData.beginTimestamp
end

--查询是否在秒杀期间
function Activity_SeckillLayer.isInKillTime(whetherEnable)
  whetherEnable = whetherEnable or Activity_SeckillLayer:enable()
  if not whetherEnable then
    return false
  end

  local tempList = Activity_SeckillLayer.getTodaySaleList()
  for k, aCombineData in ipairs(tempList) do
    for l, aData in ipairs(aCombineData) do
      local beginTime = Activity_SeckillLayer.getItemBeginTimestame(aData)
      local endTime = beginTime + aData.timeContinue * 60
      local crrentTime = TimeUtil.getServerTimeSeconds()
      if (crrentTime >= beginTime) and (crrentTime <= endTime) then
        --时间符合
        return true
      end
    end
  end

  return false
end

--查询初始显示位置(正在秒杀时 或者即将开始秒杀的)
function Activity_SeckillLayer.firstKillIndex()
  if not Activity_SeckillLayer:enable() then
    return false
  end

  local tempList = Activity_SeckillLayer.getTodaySaleList()
  for k, aCombineData in ipairs(tempList) do
    for l, aData in ipairs(aCombineData) do
      local beginTime = Activity_SeckillLayer.getItemBeginTimestame(aData)
      local endTime = beginTime + aData.timeContinue * 60
      local crrentTime = TimeUtil.getServerTimeSeconds()
      if (crrentTime <= endTime) then
        --第一个没结束的
        return k
      end
    end
  end

  --都结束了 就显示最后一个
  return #tempList
end

-------------------------------------------------------------------------------------------------check

--查询能否点击按钮
function Activity_SeckillLayer.checkCanClickBtn(aData)
  --根据剩余时间控制状态
  local beginTime = Activity_SeckillLayer.getItemBeginTimestame(aData)
  local endTime = beginTime + aData.timeContinue * 60
  local crrentTime = TimeUtil.getServerTimeSeconds()
  if (crrentTime < beginTime) or (crrentTime > endTime) then
    --时间不符
    --print("时间不符")
    return false
  end

  if Activity_SeckillLayer.getTodayMyBroughtTimes(aData.id) >= aData.limitNum then
    --次数已满
    --print("次数已满")
    return false
  end

  local showLastNum = Activity_SeckillLayer.getShowLastNum(aData.id, aData)
  -- print("aData.id = " .. aData.id)
  -- print("showLastNum = " .. showLastNum)
  if showLastNum <= 0 then
    --库存空
    return false
  end

  return true
end

--查询能否获得物品
function Activity_SeckillLayer.checkCanGain(aData)
  if not Activity_SeckillLayer.checkCanClickBtn(aData) then
    return false
  end

  if BagCalcManager.isFull() then
    --背包满
    NewPackageFullPanel:show()
    -- CanonMessageBox:Show(Localization:getInstance():getText("shop_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, nil, nil)
    return false
  end

  --判断金币
  if aData.coinType == 1 then
    --银币
    local needNum = CanonGoodIcon.getResourceNum(ResourceEnum.COIN)
    if needNum < aData.presentPrice then
      --银币不足 给提示
      local scene = Director:mgr():run()
      local aPanel = MessageBoxPanel:create(scene, MessageBoxType.kCoinLimit)
      scene:addChild(aPanel)
      aPanel:scaleIn()
      return false
    end
  else
    --金币
    local needNum = CanonGoodIcon.getResourceNum(ResourceEnum.GEMS)
    if needNum < aData.presentPrice then
      --金币不足 给提示
      local scene = Director:mgr():run()
      local aPanel = AssistantMessageBoxPanel:create(scene, AsMessageBoxType.addCoin, nil)
      scene:addChild(aPanel)
      aPanel:scaleIn()
      return false
    end
  end

  return true
end

--查询今日是否有配置的数据
function Activity_SeckillLayer.checkTodayHaveList()
  local todayList = Activity_SeckillLayer.getTodaySaleList()
  if #todayList <= 0 then
    --今天的数据一条也没有
    return false
  end
  return true
end

-------------------------------------------------------------------------------------------------method

--购买
function Activity_SeckillLayer.gain(aData, aCombineData, self)
  --print("gain")
  local function onSucceed(aData, evt)
    SeckillBuyRequest.onSucceedDefault(aData, evt)
    self.refreshItemData(aCombineData)
  end
  local function onFailed(aData, evt)
    SeckillBuyRequest.onFailedDefault(aData, evt)
    self.refreshItemData(aCombineData)
  end
  SeckillBuyRequest.sendRequest(aData, onSucceed, onFailed)
end

--全部清空
function Activity_SeckillLayer.allClear()
  Activity_SeckillLayer.clearSaleInfoHash()
end