require "canon.request.SwornRewardGainRequest"

local exchangeTable_width = 738
local exchangeTable_height = 625
local exchangeItem_width = 738
local exchangeItem_height = 231
local exchangeTable_posX = -13
local exchangeTable_posY = 115

--某性武将名称key列表
local cardNameKeys = {"activity-sworn-hero1", "activity-sworn-hero2", "activity-sworn-hero3", "activity-sworn-hero4", "activity-sworn-hero5"}
--某星装备名称key列表
local equipNameKeys = {"activity-sworn-equip1", "activity-sworn-equip2", "activity-sworn-equip3", "activity-sworn-equip4", "activity-sworn-equip5"}

--某星武将图片名称列表
local cardPicNames = {"un_1.png", "un_2.png", "un_3.png", "un_4.png", "un_5.png"}
--某星装备图片名称列表
local equipPicNames = {"wq_1.png", "wq_2.png", "wq_3.png", "wq_4.png", "wq_5.png"}

--某星武将边框图
local cardBorderPicNames = {"cardIconBorder_1.png", "cardIconBorder_1.png", "cardIconBorder_2.png", "cardIconBorder_2.png", "cardIconBorder_3.png"}
--某星装备边框图
local equipBorderPicNames = {"Item/border/equipBorder1.png", "Item/border/equipBorder2.png", "Item/border/equipBorder3.png", "Item/border/equipBorder4.png", "Item/border/equipBorder5.png"}

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

-------------------------------------------------------------------------------------
-- Activity_SwornLayer
-- 桃园结义layer
-- create by czh @ 2014-1-20
-------------------------------------------------------------------------------------

Activity_SwornLayer = class(Layer)

-------------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------------
function Activity_SwornLayer:ctor()
    self.container = nil
    self.extraArgs = nil

    self.showParticles = {}
end

-------------------------------------------------------------------------------------
-- 创建
-------------------------------------------------------------------------------------
function Activity_SwornLayer:create( container, extraArgs )
  local s = Activity_SwornLayer.new()
  self.container = container
  self.extraArgs = extraArgs

  s:initLayer()

  return s
end

-------------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------------
function Activity_SwornLayer:initLayer()
  Activity_SwornLayer.super.initLayer(self)

  local boomButton
  --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  --定义几个函数
  --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  --放烟火按钮点击
  local function boomButtonSelected(evt)
    --print("按钮点击")
    if not self:canFire(true) then
      return
    end
    self:fire()
  end

  --刷新显示
  local function refreshSelf()
    --print("刷新显示")

    --刷新table之前 先把粒子全部清除
    for _,v in ipairs(self.showParticles) do
      v:removeFromParentAndCleanup(true)
    end
    self.showParticles = {}

    --获得要显示的列表数据
    --self.myList = {}
    for i = #self.myList, 1, -1 do
      table.remove(self.myList, i)
    end
    --local myList = {DataManager.GameMetaData.activitySwornBrothersConfig.swornBrothersRewardItems[1], DataManager.GameMetaData.activitySwornBrothersConfig.swornBrothersRewardItems[2]}
    local myList = DataManager.GameMetaData.activitySwornBrothersConfig.swornBrothersRewardItems
    
    for _, configItem in ipairs(myList) do
      table.insert(self.myList, {configItem = configItem, info = self:getInfoByConfigItem(configItem)})
    end
    
    --print("n = " .. #self.myList)
    --对显示内容排序
    local function sortFunc(a, b)
      --print("a.id:" .. a.configItem.id)
      --print("b.id:" .. b.configItem.id)
      if b.info.orderNum == a.info.orderNum then
        return a.configItem.id < b.configItem.id
      end
      return b.info.orderNum < a.info.orderNum
    end
    table.sort(self.myList, sortFunc)

    --print("开始打印列表")
    --print(table.tostring(self.myList))
    --print("结束打印列表")

    --对table进行刷新
    --local originalOffset = self.exchangeTableView:getContentOffset()
    self.exchangeTableView:reloadData()
    --self.exchangeTableView:setContentOffset(originalOffset)--这个用起来有点问题 策划说可以每次刷新重排
  end
  self.refreshSelf = refreshSelf

  --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  --end
  --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  
  --初始化界面显示
  self.builder = LayoutBuilder:createWithContentsOfFile("scene/cardCombine.json")
  self.builder.useArtLabelTTF = true
  self.mainUI = self.builder:build("cardCombine")
  self:addChild(self.mainUI)

  --描边
  self.mainUI:getChildByName("txt_cardCombine_txt2"):getChildByName("txt"):setColor(ccc3(0, 255, 0))
  self.mainUI:getChildByName("txt_cardCombine_txt2"):getChildByName("txt"):setAroundColor(ccc3(91, 24, 14))

  --初始化静态文本 和 不变参数的文本
  --获得活动时间
  local timeTable = MaintenanceManager:getStartAndEndTime("activitySwornBrothers");
  --活动时间
  self.mainUI:getChildByName("txt_cardCombine_txt1"):getChildByName("txt"):setString(Localization:getInstance():getText("activity-sworn-title1"))
  --几月几日
  self.mainUI:getChildByName("txt_cardCombine_txt2"):getChildByName("txt"):setString(Localization:getInstance():getText("activity-sworn-title3", {num1 = timeTable[1].month, num2 = timeTable[1].day, num3 = timeTable[2].month, num4 = timeTable[2].day}))
  --收集指定物品即可领取奖励，小伙伴们快抓紧机会吧。
  self.mainUI:getChildByName("txt_cardCombine_txt3"):getChildByName("txt"):setString(Localization:getInstance():getText("activity-sworn-title2"))

  --更新文字的位置
  local pos = self.mainUI:getChildByName("txt_cardCombine_txt1"):getPosition()
  self.mainUI:getChildByName("txt_cardCombine_txt1"):setPosition(ccp (pos.x - 5, pos.y) )

  self.myList = {}

  --初始化列表
  self.exchangeTableView = self:createExchangeTableView()
  self:addChild(self.exchangeTableView)
  
  --local originalOffset = self.exchangeTableView:getContentOffset()
  --self.originalOffsetY = originalOffset.y

  --先刷新一下状态
  self.refreshSelf()

  --print("canGainAnyReward = " .. tostring(self:canGainAnyReward()))
end

--返回是否能够显示活动
function Activity_SwornLayer:enable()
  if not DataManager.GameMetaData.activitySwornBrothersConfig then
    return false
  end
  local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activitySwornBrothersConfig.featureName)
  if isEnable then
    local sharkActivity = DataManager.getSharkActivity()
    sharkActivity.gainedSwornRewardList = sharkActivity.gainedSwornRewardList or {}
    DataManager.setSharkActivity(sharkActivity)
  end
  return isEnable
end 

function Activity_SwornLayer:dispose()
  Activity_SwornLayer.super.dispose(self)
end

function Activity_SwornLayer:setTouchEnabled(v)
  self.exchangeTableView:setTouchEnabled(v)
end

------------------------------------------------------------------------------------------------------------------------------------
--                                                           查询接口
------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
-- 返回能否领取奖励
-------------------------------------------------------------------------------------
function Activity_SwornLayer:canGain(configItem, info)
  if not info.canGain then
    --print("不能领取奖励! ")
    return false
  end

  return true
end

-------------------------------------------------------------------------------------
-- 整体能否领取奖励
-------------------------------------------------------------------------------------
function Activity_SwornLayer:canGainAnyReward()
  --
  local configList = DataManager.GameMetaData.activitySwornBrothersConfig.swornBrothersRewardItems
  local stateList = {}
  for _, configItem in ipairs(configList) do
    info = self:getInfoByConfigItem(configItem)
    if info.canGain then
      --有能领取的奖励条目
      return true
    end
  end
  --全都不能领取
  return false
end

------------------------------------------------------------------------------------------------------------------------------------
--                                                         私有处理接口
------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
-- 向后台请求领取奖励
-------------------------------------------------------------------------------------
function Activity_SwornLayer:gain(configItem, info)
  --print("gain")

  if BagCalcManager.isFull() then
    --背包已满
    local rewardList = MetaManager.getRewardInfoByID(configItem.rewardPackageId)
    local reward = rewardList[1]
    if (not (reward.itemType == ResourceEnum.COIN)) and (not (reward.itemType == ResourceEnum.GEMS)) then
      --奖励内容不是银币也不是金币
      --虽然试图请求 但背包满的情况会打回
      local aContent = Localization:getInstance():getText("shop_inventoryFull")
      NewPackageFullPanel:show()
      -- SuspensionLabel:showContent(self.container, aContent)
      return
    end

  end

  --成功
  local function onSucceed(event)
    --奖励物品
    --print("gain返回成功信息 = " .. table.tostring(event))

    --玩家点击确定获取
    local function onGet()
      --体现获得的奖励
      RewardManager:getReward(event.data.rewards)
    end

    --显示获得的奖励
    local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = event.data.rewards, rewardTitle = Localization:getInstance():getText("activity-sworn-reward2"), callback = onGet} )
    self.container:addChild(aRewardPanel)
    aRewardPanel:scaleIn()


    --更新物品数据
    local gameInitData = DataManager:getGameInitData()
    table.insert(gameInitData.sharkActivity.gainedSwornRewardList, configItem.id)
    DataManager.setGameInitData(gameInitData)

    --进行刷新
    self.refreshSelf()
    self.container:resetTipInfoForActivity("Activity_SwornBrothers")
  end 
  --失败
  local function onFailed(event)
    --print("gain返回失败信息 = " .. table.tostring(event))
    if event.data == 716240 then  --fireworks activity is closed: {0:uid}
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("activity_goldGod_end_remind")
      self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    else
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data})
      self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end

  --发送指令
  local params = {swornRewardId = configItem.id}
  local request = SwornRewardGainRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.SwornRewardGainSucceed, onSucceed)
  request:addEventListener(RequestNotifyEnum.SwornRewardGainFailed, onFailed)
  request:start()

  --test
  --onSucceed({data = {diceStates = {0, 0, 2, 3, 4, 5, 6}}})
end

-------------------------------------------------------------------------------------
-- 生成列表
-------------------------------------------------------------------------------------
function Activity_SwornLayer:createExchangeTableView()
  local cellTag = 1024
  local buttonTag = {{-12, -41}}
  local aExchangeScene = self
  local ExchangeTableViewRenderer = class(TableViewRenderer)

  --文件初始化
  function ExchangeTableViewRenderer:ctor(width, height)
    self.list = aExchangeScene.myList
  end

  --创建单元
  function ExchangeTableViewRenderer:buildCell(container)
    --print("buildCell")


    local builder = LayoutBuilder:createWithContentsOfFile("scene/cardCombine.json")
    local aCell = builder:build("cardCombine_list")
    container:addChild(aCell)
    aCell:setTag(cellTag)

    local aAreaL = aCell:getChildByName("popup_cardCombine_l_1")
    aAreaL:setTag(-11)
    local aAreaR = aCell:getChildByName("popup_cardCombine_r")
    aAreaR:setTag(-12)
    
    --初始化静态文本 (-21 ~ -29)
    --收集
    local aTxt1 = aAreaL:getChildByName("txt_cardCombine_txt5")
    aTxt1:setTag(-21)
    aTxt1:getChildByName("txt"):setString(Localization:getInstance():getText("activity-sworn-collect"))
    --奖励内容
    local aTxt2 = aAreaR:getChildByName("txt_cardCombine_txt4")
    aTxt2:setTag(-22)
    aTxt2:getChildByName("txt"):setString(Localization:getInstance():getText("activity-sworn-reward"))

    --用于给物品显示区域加tag
    local function setItemShowTag(showItem, selfTag)
      showItem:setTag(selfTag)

      showItem:getChildByName("normal_card_small"):setTag(-101)
      showItem:getChildByName("txt_item_name"):setTag(-102)
      showItem:getChildByName("txt_item_quantity"):setTag(-103)

      showItem:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(-101)
      showItem:getChildByName("txt_item_quantity"):getChildByName("txt_item_quantity"):setTag(-101)
    end

    --初始化物品显示区域 -31 ~ -36
    --收集的5个位置 对应3种情况(收集1种 收集2种 收集3种)
    setItemShowTag(aAreaL:getChildByName("combine_item_1"), -31)--1/2
    setItemShowTag(aAreaL:getChildByName("combine_item_2"), -32)--2/2
    setItemShowTag(aAreaL:getChildByName("combine_item_3"), -33)--1/3
    setItemShowTag(aAreaL:getChildByName("combine_item_4"), -34)--2/3 or 1/1
    setItemShowTag(aAreaL:getChildByName("combine_item_5"), -35)--3/3
    --分别对应3种情况要显示的元件列表
    self.collectTypeSets = {{-34}, {-31, -32}, {-33, -34, -35}}
    --奖励物品的1个位置 (注意这个没有个数的显示)
    aAreaR:getChildByName("reward_item"):setTag(-36)
    aAreaR:getChildByName("reward_item"):getChildByName("normal_card_small"):setTag(-101)
    aAreaR:getChildByName("reward_item"):getChildByName("txt_item_name"):setTag(-102)
    aAreaR:getChildByName("reward_item"):getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(-101)

    --初始化按钮 -41
    aAreaR:getChildByName("btn_get_reward"):setTag(-41)
    aAreaR:getChildByName("btn_get_reward"):getChildByName("txt"):setTag(-23)
    aAreaR:getChildByName("btn_get_reward"):getChildByName("btn_long_blue"):setTag(-51)
    aAreaR:getChildByName("btn_get_reward"):getChildByName("btn_inactive"):setTag(-52)
    
  end

  --获得数据
  function ExchangeTableViewRenderer:setData( rawCocosObj, index )
    local lable
--[[
    print("n = " .. #self.list)
    print("index = " .. index)
    --if index == 2 then
      print(table.tostring(self.list))
    --end
]]
    --用于显示某一个需求物品的具体内容
    local function showConditionItem(showIndex, showItem, showParent, showConfigItem, showInfo)
      aCardDisplay = showItem:getChildByTag(-101)
      aCardDisplay:setVisible(false)

      --显示文字
      setNodeText(showItem:getChildByTag(-102):getChildByTag(-101), Localization:getInstance():getText(showInfo.conditionList[showIndex].nameKey))
      setNodeText(showItem:getChildByTag(-103):getChildByTag(-101), (showInfo.conditionList[showIndex].totalNum .. "/" .. showInfo.conditionList[showIndex].needNum))
      if showInfo.conditionList[showIndex].enough then
        --足够 绿色
        setNodeColor(showItem:getChildByTag(-103):getChildByTag(-101), ccc3(0,0xFF,0))
      else
        --不够 红色
        setNodeColor(showItem:getChildByTag(-103):getChildByTag(-101), ccc3(0xFF,0,0))
      end

      local icon = showItem:getChildByTag(-201)
      if icon then
        icon:removeFromParentAndCleanup(true)
      end
      local border = showItem:getChildByTag(-211)
      if border then
        border:removeFromParentAndCleanup(true)
        border = nil
      end

      --显示图片
      local needType = showInfo.conditionList[showIndex].needType
      if needType == 1 then
        --卡组中第一个卡片
        icon = getHeadIconCanonCardByMetaId(showInfo.conditionList[showIndex].metaId)
        icon:setScale(0.7)
      elseif needType == 2 then
        --卡星
        icon = Sprite:create("Item/Picture/" .. cardPicNames[showInfo.conditionList[showIndex].needValue])
        icon:setScale(0.7)
        border = Sprite:create("#" .. cardBorderPicNames[showInfo.conditionList[showIndex].needValue])
        border:setScale(0.7)
      elseif needType == 3 then
        --装备组中第一个装备
        icon = CanonItem:create()
        icon:loadByMetaId(showInfo.conditionList[showIndex].metaId)
        icon:setScale(0.6)
      elseif needType == 4 then
        --装备品质
        icon = Sprite:create("Item/Picture/" .. equipPicNames[showInfo.conditionList[showIndex].needValue])
        icon:setScale(0.7)
        border = Sprite:create(equipBorderPicNames[showInfo.conditionList[showIndex].needValue])
        border:setScale(0.7)
      elseif needType == 5 then
        --道具
        icon = CanonItem:create()
        icon:loadByMetaId(showInfo.conditionList[showIndex].needValue)
        icon:setScale(0.6)
      else
        --没有显示
      end

      if icon then
        icon:setPosition( ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()) )
        showItem:addChild(icon.refCocosObj, 1)
        icon:setTag(-201)
        icon:dispose()
      end

      if border then
        border:setPosition( ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()) )
        showItem:addChild(border.refCocosObj, 2)
        border:setTag(-211)
        border:dispose()
      end
    end

    --------------------------函数开始-------------------
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local aConfigItem = self.list[index+1].configItem
    local aInfo = self.list[index+1].info
    --print("index = " .. index)
    --print("#self.list = " .. #self.list)
    --print("self.list[" .. (index+1) .. "] : " .. table.tostring(self.list[index+1]))

    --数据
    --需要收集几种物品
    local aCollectTypeNum = #aInfo.conditionList
    --当前的游戏初始化信息
    local aCurrentGameInitData = DataManager:getGameInitData()

    --区域
    local aAreaL = aCell:getChildByTag(-11)
    local aAreaR = aCell:getChildByTag(-12)

    --先全都不可见
    aAreaL:getChildByTag(-31):setVisible(false)
    aAreaL:getChildByTag(-32):setVisible(false)
    aAreaL:getChildByTag(-33):setVisible(false)
    aAreaL:getChildByTag(-34):setVisible(false)
    aAreaL:getChildByTag(-35):setVisible(false)
    --再显示该显示的
    for i = 1, aCollectTypeNum do
      aAreaL:getChildByTag(self.collectTypeSets[aCollectTypeNum][i]):setVisible(true)
      showConditionItem(i,  aAreaL:getChildByTag(self.collectTypeSets[aCollectTypeNum][i]), aAreaL, aConfigItem, aInfo)
    end
    --最后显示奖励物品
    --print("aConfigItem.rewardPackageId = " .. aConfigItem.rewardPackageId)
    --print("Localization:getInstance():getText(MetaManager.reward_package[aConfigItem.rewardPackageId] = " .. table.tostring(Localization:getInstance():getText(MetaManager.reward_package[aConfigItem.rewardPackageId])))
    --print("Localization:getInstance():getText(MetaManager.reward_package[aConfigItem.rewardPackageId].name = " .. Localization:getInstance():getText(MetaManager.reward_package[aConfigItem.rewardPackageId].name))
    local rewardList = MetaManager.getRewardInfoByID(aConfigItem.rewardPackageId)
    --print("rewardList = " .. table.tostring(rewardList))
    --取第一个奖励
    local reward = rewardList[1]
    
    --这里显示奖励物品图标<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    aCardDisplay = aAreaR:getChildByTag(-36):getChildByTag(-101)
    aCardDisplay:setVisible(false)
    local icon = aAreaR:getChildByTag(-36):getChildByTag(-201)
    if icon then
      icon:removeFromParentAndCleanup(true)
    end
    local aBorder = aAreaR:getChildByTag(-36):getChildByTag(-202)
    if aBorder then
      aBorder:removeFromParentAndCleanup(true)
      aBorder = nil
    end

    if reward.itemType == ResourceEnum.COIN then
      --银币
      icon = Sprite:create("common/CoinIcon_Mission.png")
      icon:setScale(0.75)
      aBorder = Sprite:create("Item/border/equipBorder1.png")
      aBorder:setScale(0.7)
      aRewardNameString = Localization:getInstance():getText("resource_silverCoin") .. "x" .. reward.amount
    elseif reward.itemType == ResourceEnum.GEMS then
      --金币
      icon = Sprite:create("common/GemIcon_Mission.png")
      icon:setScale(0.75)
      aBorder = Sprite:create("Item/border/equipBorder1.png")
      aBorder:setScale(0.7)
      aRewardNameString = Localization:getInstance():getText("resource_goldCoin") .. "x" .. reward.amount
    elseif reward.itemType == ResourceEnum.CARD then
      --卡牌
      icon = getHeadIconCanonCardByMetaId(reward.metaId)
      icon:setScale(0.7)
      aRewardNameString = Localization:getInstance():getText(MetaManager.card_meta[reward.metaId].name)
      if not (reward.amount == 1) then
        aRewardNameString = aRewardNameString .. "x" .. reward.amount
      end
    elseif reward.itemType == ResourceEnum.PROP then
      --道具
      icon = CanonItem:create()
      icon:loadByMetaId(reward.metaId)
      icon:setScale(0.6)
      aRewardNameString = Localization:getInstance():getText(MetaManager.prop_meta[reward.metaId].name)
      if not (reward.amount == 1) then
        aRewardNameString = aRewardNameString .. "x" .. reward.amount
      end
    end

    if icon then
      icon:setPosition( ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()) )
      aAreaR:getChildByTag(-36):addChild(icon.refCocosObj, 1)
      icon:setTag(-201)
      icon:dispose()
    end

    if aBorder then
      aBorder:setPosition( ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()) )
      aAreaR:getChildByTag(-36):addChild(aBorder.refCocosObj, 2)
      aBorder:setTag(-202)
      aBorder:dispose()
    end

    --显示文本
    setNodeText(aAreaR:getChildByTag(-36):getChildByTag(-102):getChildByTag(-101), aRewardNameString)

    --删除粒子效果
    if aCell.rewardParticle then --删除粒子效果
      aCell.rewardParticle:removeFromParentAndCleanup(true)
    end

    if aInfo.gained then
      --print("已经领取")
      --已经领取 全置灰 按钮显示"已领取"
      setNodeText(aAreaR:getChildByTag(-41):getChildByTag(-23), Localization:getInstance():getText("activity-sworn-got"))
      aAreaR:getChildByTag(-41):getChildByTag(-51):setVisible(false)
      aAreaR:getChildByTag(-41):getChildByTag(-52):setVisible(true)
      aAreaR:getChildByTag(-41).ignoreTouch = true

    else
      --还没领取
      setNodeText(aAreaR:getChildByTag(-41):getChildByTag(-23), Localization:getInstance():getText("activity-sworn-get"))
      if aInfo.canGain then
        --print("还没领取 条件满足")
        --条件满足 全部点亮
        aAreaR:getChildByTag(-41):getChildByTag(-51):setVisible(true)
        aAreaR:getChildByTag(-41):getChildByTag(-52):setVisible(false)
        aAreaR:getChildByTag(-41).ignoreTouch = false

        --显示粒子效果
        aCell.rewardParticle = ParticleManager.geneParticle(ParticlePathConstants.FxStarline, ccp(aAreaR:getChildByTag(-41):getPositionX(), aAreaR:getChildByTag(-41):getPositionY()), 1, 1000, CocosObject.new(aAreaR))
        aCell.rewardParticle.refCocosObj:setPositionType(kCCPositionTypeRelative);
        local contentSize = aAreaR:getChildByTag(-41):getChildByTag(-52):getContentSize()
        local width = aAreaR:getChildByTag(-41):getChildByTag(-52):getScaleX() * contentSize.width
        local height = aAreaR:getChildByTag(-41):getChildByTag(-52):getScaleY() * contentSize.height
        ParticleManager.moveParticle(aCell.rewardParticle, 1, {ccp(width, 0), ccp(0, -height), ccp(-width, 0), ccp(0, height)})

        --将粒子记录下来 方便一起清理
        table.insert(aExchangeScene.showParticles, aCell.rewardParticle)
      else
        --print("还没领取 条件不足")
        --条件不足 部分置灰
        aAreaR:getChildByTag(-41):getChildByTag(-51):setVisible(false)
        aAreaR:getChildByTag(-41):getChildByTag(-52):setVisible(true)
        aAreaR:getChildByTag(-41).ignoreTouch = true
      end
    end

    --处理按钮
    --local boomButton<<<<<<<<<<<<<<<<<<
  end

  local function onListItemTouch( evt )
    local aIndex = evt.data + 1

    local aConfigItem = self.myList[aIndex].configItem
    local aInfo = self.myList[aIndex].info

    local newCell = self.exchangeTableView:cellAtIndex(aIndex - 1)
    local areaR = newCell:getChildByTag(cellTag):getChildByTag(-12)
    local buttonDisplay = areaR:getChildByTag(-41)
    local exchangeDisplay = buttonDisplay:getChildByTag(-51)
    --print(buttonDisplay:getPositionX(), buttonDisplay:getPositionY())
    local posInCell = areaR:convertToNodeSpace(evt.globalPosition)
    --print(posInCell.x, posInCell.y)
    if posInCell.x > buttonDisplay:getPositionX() and
    posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
    posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
    posInCell.y < buttonDisplay:getPositionY() then
      --点击按钮
      if aExchangeScene:canGain(aConfigItem, aInfo) then
        aExchangeScene:gain(aConfigItem, aInfo)
      end
    end
  end

  --开始
  local renderer = ExchangeTableViewRenderer.new(exchangeItem_width, exchangeItem_height)
  local aTableView = TableView:create(renderer, exchangeTable_width, exchangeTable_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , aTableView)
  aTableView:setPosition(ccp(exchangeTable_posX, exchangeTable_posY))
  return aTableView
end

  -------------------------------------------------------------------------------------
  -- 获得该项配置的的数据信息
  -------------------------------------------------------------------------------------
  function Activity_SwornLayer:getInfoByConfigItem(configItem)
    local result = {canGain = false, gained = false, conditionEnough = true, conditionList = {}, orderNum = 2}
    local aGainedList = DataManager:getGameInitData().sharkActivity.gainedSwornRewardList
    for _, gainedId in ipairs(aGainedList) do
      if gainedId == configItem.id then
        --不能领取 因为已经领过了!
        result.gained = true
        result.orderNum = 0
      end
    end

    
    if not (configItem.conditionType1 == 0) then
      table.insert(result.conditionList, self:getConditionInfo(configItem.conditionType1, configItem.conditionValue1, configItem.conditionNum1))
    end
    if not (configItem.conditionType2 == 0) then
      table.insert(result.conditionList, self:getConditionInfo(configItem.conditionType2, configItem.conditionValue2, configItem.conditionNum2))
    end
    if not (configItem.conditionType3 == 0) then
      table.insert(result.conditionList, self:getConditionInfo(configItem.conditionType3, configItem.conditionValue3, configItem.conditionNum3))
    end

    --判断3种条件
    for __, conditionImfo in ipairs(result.conditionList) do
      if conditionImfo.enough == false then
        result.conditionEnough = false
      end
    end

    if (result.gained == false) and (result.conditionEnough == true) then
      --没有领过 且条件全达成 则可以领取
      result.canGain = true
      result.orderNum = 3
    end

    return result
  end

  -------------------------------------------------------------------------------------
  -- 获得某一需求信息
  -------------------------------------------------------------------------------------
  function Activity_SwornLayer:getConditionInfo(_needType, _needValue, _needNum)
    local result = {enough = false, totalNum = 0, needNum = _needNum, nameKey = "", needValue = _needValue, needType = _needType, metaId = ""}

    if _needType == 0 then
      --没有要求
      result.totalNum = 0
      result.nameKey = ""
    elseif _needType == 1 then
      --指定卡组武将
      local myCardList = DataManager:getGameInitData().sharkCards.sharkCards
      for _, myCard in ipairs(myCardList) do
        if MetaManager.card_meta[myCard.metaId].cardGroupId == _needValue then
          result.totalNum = result.totalNum + 1
        end
      end
      for _, card in pairs(MetaManager.card_meta) do
        --print("card.evolutionLevel = " .. card.evolutionLevel .. ", card.cardGroupId = " .. card.cardGroupId)
        if (card.evolutionLevel == 1) and (card.cardGroupId == _needValue) then
          result.nameKey = MetaManager.card_meta[card.id].name
          result.metaId = card.id
          break
        end
      end
    elseif _needType == 2 then
      --指定品质武将
      local myCardList = DataManager:getGameInitData().sharkCards.sharkCards
      for _, myCard in ipairs(myCardList) do
        if MetaManager.card_meta[myCard.metaId].rare == _needValue then
          result.totalNum = result.totalNum + 1
        end
      end
      result.nameKey = cardNameKeys[_needValue]
    elseif _needType == 3 then
      --指定装备组
      local myEquipList = DataManager:getGameInitData().sharkEquips.sharkEquips
      for _, myEquip in ipairs(myEquipList) do
        if MetaManager.equip_meta[myEquip.metaId].prefixId == _needValue then
          result.totalNum = result.totalNum + 1
        end
      end
      for _, equip in pairs(MetaManager.equip_meta) do
        if (equip.evolveLevel == 1) and (equip.prefixId == _needValue) then
          result.nameKey = MetaManager.equip_meta[equip.id].name
          result.metaId = equip.id
          break
        end
      end
    elseif _needType == 4 then
      --指定品质装备
      local myEquipList = DataManager:getGameInitData().sharkEquips.sharkEquips
      for _, myEquip in ipairs(myEquipList) do
        if MetaManager.equip_meta[myEquip.metaId].quality == _needValue then
          result.totalNum = result.totalNum + 1
        end
      end
      result.nameKey = equipNameKeys[_needValue]
    elseif _needType == 5 then
      --指定道具
      result.totalNum = BagCalcManager.getNumById(_needValue)
      result.nameKey = MetaManager.prop_meta[_needValue].name
    end

    --判断是否足够
    if _needType == 0 then
      --不需要任何物品 没有条件 故通过
      result.enough = true
    else
      if result.totalNum < _needNum then
        --不足
        result.enough = false
      else
        --足够
        result.enough = true
      end
    end

    return result
  end
  
  function Activity_SwornLayer.getTipNum()
    if not Activity_SwornLayer.enable() then
      return 0
    end
    -- local beginTime = TimeUtil.getServerTimeSeconds()
    -- print("beginTime = " .. tostringRich(beginTime))

    -- 当前拥有特定卡牌组id个数字典
    -- key: 卡牌组id
    -- value: 拥有个数 nil=没有
    local myCardGroupNumHash = {}

    -- 当前拥有特定品质卡牌个数字典
    -- key: 品质
    -- value: 拥有个数 nil=没有
    local myCardRareNumHash = {}

    -- 当前拥有特定装备组id个数字典
    -- key: 装备组id
    -- value: 拥有个数 nil=没有
    local myEquipGroupIdNumHash = {}

    -- 当前拥有特定品质装备个数字典
    -- key: 品质
    -- value: 拥有个数 nil=没有
    local myEquipQuilityNumHash = {}

    --获得卡牌相关数量信息
    local myCardList = DataManager:getGameInitData().sharkCards.sharkCards
    for _, myCard in ipairs(myCardList) do
      local groupId = MetaManager.card_meta[myCard.metaId].cardGroupId
      myCardGroupNumHash[groupId] = (myCardGroupNumHash[groupId] or 0) + 1

      local rare = MetaManager.card_meta[myCard.metaId].rare
      myCardRareNumHash[rare] = (myCardRareNumHash[rare] or 0) + 1
    end

    --获得装备相关数量信息
    local myEquipList = DataManager:getGameInitData().sharkEquips.sharkEquips
    for _, myEquip in ipairs(myEquipList) do
      local prefixId = MetaManager.equip_meta[myEquip.metaId].prefixId
      myEquipGroupIdNumHash[prefixId] = (myEquipGroupIdNumHash[prefixId] or 0) + 1

      local quality = MetaManager.equip_meta[myEquip.metaId].quality
      myEquipQuilityNumHash[quality] = (myEquipQuilityNumHash[quality] or 0) + 1
    end
    
    local aTipNum = 0
    local myList = DataManager.GameMetaData.activitySwornBrothersConfig.swornBrothersRewardItems
    local temp = DataManager.getSharkActivity().gainedSwornRewardList  --added by jet
    local aGainedList = {}
    for _, gainedId in ipairs(temp) do
      aGainedList[gainedId] = true
    end
    for _, configItem in ipairs(myList) do
      local gained = aGainedList[configItem.id]
      --[[
      local aGainedList = DataManager.getSharkActivity().gainedSwornRewardList  --commented out by jet
      for _, gainedId in ipairs(aGainedList) do
        if gainedId == configItem.id then
          gained = true
          break
        end
      end
      ]]
      if not gained then
        local conditionList = {}
        if not (configItem.conditionType1 == 0) then
          table.insert(conditionList, {configItem.conditionType1, configItem.conditionValue1, configItem.conditionNum1})
        end
        if not (configItem.conditionType2 == 0) then
          table.insert(conditionList, {configItem.conditionType2, configItem.conditionValue2, configItem.conditionNum2})
        end
        if not (configItem.conditionType3 == 0) then
          table.insert(conditionList, {configItem.conditionType3, configItem.conditionValue3, configItem.conditionNum3})
        end
        local isEnough = true
        for _, aConditionItem in ipairs(conditionList) do
          local _needType = aConditionItem[1]
          local _needValue = aConditionItem[2]
          local _needNum = aConditionItem[3]
          local totalNum = 0
          if _needType == 0 then
            --没有要求
            totalNum = 0
          elseif _needType == 1 then
            --指定卡组武将
            totalNum = myCardGroupNumHash[_needValue] or 0
          elseif _needType == 2 then
            --指定品质武将
            totalNum = myCardRareNumHash[_needValue] or 0
          elseif _needType == 3 then
            --指定装备组
            totalNum = myEquipGroupIdNumHash[_needValue] or 0
          elseif _needType == 4 then
            --指定品质装备
            totalNum = myEquipQuilityNumHash[_needValue] or 0
          elseif _needType == 5 then
            --指定道具
            totalNum = BagCalcManager.getNumById(_needValue)
          end

          --判断是否足够
          if _needType == 0 then
            --不需要任何物品 没有条件 故通过
          else
            if totalNum < _needNum then
              --不足
              isEnough = false
              break
            end
          end
        end
        if isEnough then
          aTipNum = aTipNum + 1
        end
      end
    end

    -- local endTime = TimeUtil.getServerTimeSeconds()
    -- print("endTime = " .. tostringRich(endTime))
    -- print("gap = " .. tostringRich(endTime - beginTime))

    return aTipNum
  end