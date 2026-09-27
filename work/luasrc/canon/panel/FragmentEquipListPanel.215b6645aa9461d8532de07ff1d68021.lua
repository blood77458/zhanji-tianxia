--
-- FragmentEquipListPanel.lua
-- Author: czh
-- Date: 2014-02-17 20:44:46
--

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.FragmentSynthetizeEquipRequest"
require "canon.panel.FragmentEquipRewardPopPanel"
require "canon.panel.EquipInfoPanelNoBtn"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 706
local table_height = 818
local table_posX = 12
local table_posY = 125
local item_width = 692
local item_height = 183

FragmentEquipListPanel = class(Layer)

--焦点变化事件
local function onFocusChanged(evt)
  evt.context:setTableViewTouched(evt.data == nil)
end
--------------------------------------------------------------------------------------------------------

function FragmentEquipListPanel:ctor()
    self.container = nil
    self.dataList = nil
end

function FragmentEquipListPanel:create( container )
    local s = FragmentEquipListPanel.new()
    s:initLayer(container)
    return s
end

function FragmentEquipListPanel:initLayer(container)
   container.uiGroup2:getChildByName("btn_tab_active"):setVisible(true)
   container.uiGroup1:getChildByName("btn_tab_active"):setVisible(false)
  local function refreshSelf()
    for i = #self.dataList, 1, -1 do
      table.remove(self.dataList, i)
    end

    local tempList = {}
    if DataManager:getGameInitData().sharkEquipFragments then
	    tempList = DataManager:getGameInitData().sharkEquipFragments.sharkEquipFragments
	end
    
    for _, v in ipairs(tempList) do
      if v.amount > 0 then
        --要有值才能显示
        table.insert(self.dataList, v)
      end
    end

    --排序
    local function sortFunc(a, b)
      local equipMetaIdA = MetaManager.equip_fragment_meta[a.metaId].equipId
      local equipMetaIdB = MetaManager.equip_fragment_meta[b.metaId].equipId

      --能够合成排上方
      local needNumA = MetaManager.equip_fragment_meta[a.metaId].amount
      local canGainA = a.amount >= needNumA
      local needNumB = MetaManager.equip_fragment_meta[b.metaId].amount
      local canGainB = b.amount >= needNumB
      if canGainA ~= canGainB then
        return canGainA
      end

      --稀有度由高至低
      local starNumA = MetaManager.equip_meta[equipMetaIdA].quality
      local starNumB = MetaManager.equip_meta[equipMetaIdB].quality
      if starNumA ~= starNumB then
        return (starNumA > starNumB)
      end

      --碎片数量由多至少
      if a.amount ~= b.amount then
        return (a.amount > b.amount)
      end

      --metaId升序
      return (a.metaId < b.metaId)
    end
    table.sort(self.dataList, sortFunc)

    self.listTableView:reloadData()

    if #self.dataList <= 0 then
      --列表为空 显示字符串
      self.container.noneText:getChildByName("txt"):setString(Localization:getInstance():getText("fragment_equip_empty"))
      self.container.noneText:setVisible(true)
    else
      --列表不空 不显示字符串
      self.container.noneText:setVisible(false)
    end
  end
  self.refreshSelf = refreshSelf

  FragmentEquipListPanel.super.initLayer(self)
  self.container = container
  self.dataList = {}
  
  self.listTableView = self:createListTableView()
  self:addChild(self.listTableView)

  UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

  self.refreshSelf()
end

function FragmentEquipListPanel:createListTableView()
  local cellTag = 1024
  local buttonTag = {-31}
  local aListPanel = self
  local EquipFragmentListTableViewRenderer = class(TableViewRenderer)
  function EquipFragmentListTableViewRenderer:ctor(width, height)
    self.list = aListPanel.dataList or {}
  end
  function EquipFragmentListTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/soulcombine.json")
    builder.useArtLabelTTF = true
    local aCell = builder:build("list_soul")
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    aCell:getChildByName("frame_card"):setVisible(false)
    aCell:getChildByName("bg_card"):setVisible(false)

    --器魂数量: 
    aCell:getChildByName("txt_soulcombine_1"):getChildByName("txt"):setString(Localization:getInstance():getText("fragment_equip_num"))

    local aCardDisplay = aCell:getChildByName("normal_card_big")
    aCardDisplay:setTag(-10)
    aCardDisplay:setVisible(false)
    
    local aCurrentNumLabel = aCell:getChildByName("txt_soulcombine_2")
    aCurrentNumLabel:setTag(-11)
    aCurrentNumLabel = aCurrentNumLabel:getChildByName("txt")
    aCurrentNumLabel:setTag(-10)
    
    local aNameLabel = aCell:getChildByName("txt_inventory_card_name")
    aNameLabel:setTag(-12)
    aNameLabel = aNameLabel:getChildByName("txt_inventory_card_name")
    aNameLabel:setTag(-10)
    
    local aLastNumLabel = aCell:getChildByName("txt_soulcombine_5")
    aLastNumLabel:setTag(-13)
    aLastNumLabel = aLastNumLabel:getChildByName("txt")
    aLastNumLabel:setTag(-10)
    
    --星数
    aCell:getChildByName("icon_star_1"):setTag(-101)
    aCell:getChildByName("icon_star_2"):setTag(-102)
    aCell:getChildByName("icon_star_3"):setTag(-103)
    aCell:getChildByName("icon_star_4"):setTag(-104)
    aCell:getChildByName("icon_star_5"):setTag(-105)
    aCell:getChildByName("icon_star_6"):setTag(-106)
    aCell:getChildByName("icon_star_7"):setTag(-107)

    --星级颜色条
    aCell:getChildByName("q_white9_panel"):setTag(-201)
    aCell:getChildByName("q_green9_panel"):setTag(-202)
    aCell:getChildByName("q_blue9_panel"):setTag(-203)
    aCell:getChildByName("q_purple9_panel"):setTag(-204)
    aCell:getChildByName("q_orange9_panel"):setTag(-205)
    aCell:getChildByName("q_red9_panel"):setTag(-206)
    aCell:getChildByName("q_yellow9_panel"):setTag(-207)

    --合成按钮
    local aCombineBtnDisplay = aCell:getChildByName("btn_train")
    aCombineBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("fragment_combineBtn"))
    aCombineBtnDisplay:setTag(-31)
    aCombineBtnDisplay:getChildByName("btn"):setTag(-51)

    --再收集...个可以合成 文本
    local aCollectInfo1 = aCell:getChildByName("txt_soulcombine_4")
    aCollectInfo1:getChildByName("txt"):setString(Localization:getInstance():getText("fragment_cannotCombine1"))
    aCollectInfo1:setTag(-14)
    local aCollectInfo2 = aCell:getChildByName("txt_soulcombine_6")
    aCollectInfo2:getChildByName("txt"):setString(Localization:getInstance():getText("fragment_cannotCombine2"))
    aCollectInfo2:setTag(-15)

    --可以合成
    local aCanCombineInfo = aCell:getChildByName("txt_soulcombine_3")
    aCanCombineInfo:getChildByName("txt"):setString(Localization:getInstance():getText("fragment_canCombine"))
    aCanCombineInfo:setTag(-16)
  end

  function EquipFragmentListTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local aData = self.list[index + 1]
    local equipMetaId = MetaManager.equip_fragment_meta[aData.metaId].equipId
    local needNum = MetaManager.equip_fragment_meta[aData.metaId].amount

    local originalIcon_co = aCell:getChildByTag(-20)
    if originalIcon_co then
      originalIcon_co:removeFromParentAndCleanup(true)
    end
    
    local originalCard4_co = aCell:getChildByTag(-21)
    if originalCard4_co then
      originalCard4_co:removeFromParentAndCleanup(true)
    end
    
    local aCardDisplay =  aCell:getChildByTag(-10)
    local icon = CanonItem:create()
    icon:loadByMetaId(equipMetaId)
    icon:setPosition(ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()))
    icon:setScale(0.8)
    aCell:addChild(icon.refCocosObj, 10)
    icon:setTag(-20)
    icon:dispose()

    
    local aCurrentNumLabel = aCell:getChildByTag(-11)
    setNodeText(aCurrentNumLabel:getChildByTag(-10), aData.amount)
    
    local aNameLabel = aCell:getChildByTag(-12)
    setNodeText(aNameLabel:getChildByTag(-10), CanonGoodIcon.getGoodName(ResourceEnum.EQUIP_FRAGMENT, aData.metaId, 1, {withoutAmount = true}))
    
    local aLastNumLabel = aCell:getChildByTag(-13)
    local aCollectInfo1 = aCell:getChildByTag(-14)
    local aCollectInfo2 = aCell:getChildByTag(-15)
    local aCanCombineInfo = aCell:getChildByTag(-16)
    local aBtnDisplay = aCell:getChildByTag(-31)
    if aData.amount < needNum then
      --不够
      aLastNumLabel:setVisible(true)
      aCollectInfo1:setVisible(true)
      aCollectInfo2:setVisible(true)
      aCanCombineInfo:setVisible(false)
      aBtnDisplay:setVisible(false)
      setNodeText(aLastNumLabel:getChildByTag(-10), string.format("%d", needNum - aData.amount))
    else
      --足够
      aLastNumLabel:setVisible(false)
      aCollectInfo1:setVisible(false)
      aCollectInfo2:setVisible(false)
      aCanCombineInfo:setVisible(true)
      aBtnDisplay:setVisible(true)
    end

    local starNum = MetaManager.equip_meta[equipMetaId].quality
    for i = 1, 7 do
      if i <= starNum then
        --显示星星
        aCell:getChildByTag(-100 - i):setVisible(true)
      else
        --不显示星星
        aCell:getChildByTag(-100 - i):setVisible(false)
      end

      if i == starNum then
        aCell:getChildByTag(-200 - i):setVisible(true)
      else
        aCell:getChildByTag(-200 - i):setVisible(false)
      end
    end

    --处理角标
    local aSmallIcon = aCell:getChildByTag(-22)
    if aSmallIcon then
      aSmallIcon:removeFromParentAndCleanup(true)
      aSmallIcon = nil
    end
    aSmallIcon = Sprite:create("Item/Picture/Prop_soul_item.png")
    aSmallIcon:setScale(0.9)
    aSmallIcon:setPosition( ccp(aCardDisplay:getPositionX() + 33, aCardDisplay:getPositionY() + 42) )
    aCell:addChild(aSmallIcon.refCocosObj, 20)
    aSmallIcon:setTag(-22)
    aSmallIcon:dispose()
  end


  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local newCell = self.listTableView:cellAtIndex(aIndex - 1)
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)

    local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-31)
    local exchangeDisplay = buttonDisplay:getChildByTag(-51)
    if posInCell.x > buttonDisplay:getPositionX() and
    posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
    posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
    posInCell.y < buttonDisplay:getPositionY() then
      --点击按钮
      --print("onListItemTouch btnClicked")
      if self:canGain(self.dataList[aIndex]) then
        self:gain(self.dataList[aIndex])
      end
  	end

    local cardDisplay = newCell:getChildByTag(cellTag):getChildByTag(-20)
    exchangeDisplay = cardDisplay
    -- print("posInCell.x = " .. posInCell.x)
    -- print("posInCell.y = " .. posInCell.y)
    -- print("cardDisplay:getPositionX() = " .. cardDisplay:getPositionX())
    -- print("cardDisplay:getPositionY() = " .. cardDisplay:getPositionY())
    if posInCell.x > (cardDisplay:getPositionX() - 59) and
    posInCell.x < (cardDisplay:getPositionX() + 59) and
    posInCell.y > (cardDisplay:getPositionY() - 59) and
    posInCell.y < (cardDisplay:getPositionY() + 59) then
      --点击按钮
      --print("onListItemTouch cardClicked")
      self:openCard(self.dataList[aIndex])
    end
  end

  local renderer = EquipFragmentListTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(table_posX, table_posY))

  aTableView.hitTestPoint = function (self, worldPosition, useGroupTest)
    return false -- 修复遮挡下方按钮的bug
  end
  return aTableView
end

function FragmentEquipListPanel:dispose()
  UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
  
  FragmentEquipListPanel.super.dispose(self)
end

function FragmentEquipListPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.listTableView, visibleSize,callback)
end

function FragmentEquipListPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.listTableView, visibleSize, callback)
end

--设置触摸是否开启
function FragmentEquipListPanel:setTableViewTouched(enabled)
  self.listTableView:setTouchEnabled(enabled)
end

--查询能否领取武器
function FragmentEquipListPanel:canGain(aData)
  local needNum = MetaManager.equip_fragment_meta[aData.metaId].amount
  if aData.amount < needNum then
    --不够
    return false
  end
  return true
end

function FragmentEquipListPanel:gain(aData)

  --成功
  local function onSucceed(event)
    --奖励物品
    --print("gain返回成功信息 = " .. table.tostring(event))
    --记录获得的奖励
    self.rewardList = event.data.rewards

    --扣碎片
    local delItems = {}
    table.insert(delItems, {itemType = ResourceEnum.EQUIP_FRAGMENT, metaId = aData.metaId, amount = -MetaManager.equip_fragment_meta[aData.metaId].amount})
    RewardManager:getReward(delItems)


    --播放动画
    self:playAnime(aData)
  end 
  --失败
  local function onFailed(event)
    --print("gain返回失败信息 = " .. table.tostring(event))
    if event.data == 710516 then  --背包已满
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("shop_inventoryFull")
      self.targetInfoPanel = NewPackageFullPanel:show()
    elseif event.data == 713601 then  --碎片不够
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("fragment_equipCombine_notEnough")
      self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    else
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data})
      self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end

  ----------------------------------------gain
  if BagCalcManager.isFull() then
    --背包已满
    local aContent = Localization:getInstance():getText("shop_inventoryFull")
    -- SuspensionLabel:showContent(self, aContent)
    NewPackageFullPanel:show()
    return
  end

  --发送指令
  local params = {metaId = aData.metaId}
  --print("请求合成碎片! params = " .. table.tostring(params))
  local request = FragmentSynthetizeEquipRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.FragmentSynthetizeEquipSucceed, onSucceed)
  request:addEventListener(RequestNotifyEnum.FragmentSynthetizeEquipFailed, onFailed)
  request:start()
end

--播放动画
function FragmentEquipListPanel:playAnime(aData)
  --print("播放动画")

  --灰色遮罩
  self.colorLayer = LayerColor:create()
  self.colorLayer:setOpacity(kDarkOpacity)
  self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self.container:addChild(self.colorLayer)--一定要加在scene上才有效
  --禁用点击
  self.container.targetInfoPanel = self.colorLayer

  --禁用列表滚动
  self:setTableViewTouched(false)

  local fspt = FlashSprite:create("EVO2/soulcombine_act")

  --替换动画中icon内容
  local equipMetaId = MetaManager.equip_fragment_meta[aData.metaId].equipId
  local meta = MetaManager.equip_meta[equipMetaId]
  name = meta.icon
  local len = string.len(tostring(meta.quality))      
  name = string.sub(name,1,string.len(name)-len) 
  --local node = Sprite.new(CCSprint:create("Item/border/equipBorder" .. meta.quality .. ".png"))
  
  fspt:addChangeInstance("iconFrame", createSpriteFrame("Item/border/equipBorder" .. meta.quality .. ".png"))
  fspt:addChangeInstance("iconHead", createSpriteFrame( "Item/Picture/" .. name .. "0.png" ))
  fspt:addChangeInstance("iconBG", createSpriteFrame( "Item/border/equipBg" .. meta.quality .. ".png" ))

  --local icon = CanonItem:create()
  --icon:loadByMetaId(equipMetaId)
  --icon:setPosition(ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()))
  --icon:setScale(0.8)
  --self:addChild(icon, 1)

  fspt:changeAnimation(0)
  fspt:setLoop(false)
  local fspt_co = CocosObject.new(fspt)
  local function bossbreakAnimationEnd(anim)
    fspt:unregisterEndAnimationScriptHandler()
    self.container:removeChild(fspt_co)

    --取消遮罩
    self.colorLayer:removeFromParentAndCleanup(true)
    --启用点击
    self.container.targetInfoPanel = nil
    
    self:doPlayComplete()
  end
  fspt:registerEndAnimationScriptHandler(bossbreakAnimationEnd)
  self.container:addChild(fspt_co)
  fspt:setPositionX(fspt:getPositionX())
  fspt:setPositionY(fspt:getPositionY())
end

--播放完毕后的操作
function FragmentEquipListPanel:doPlayComplete()
  --print("播放动画完毕! self.rewardList = " .. table.tostring(self.rewardList))

  local function onClose()
    --启用列表滚动
    self:setTableViewTouched(true)
    self.container.targetInfoPanel = nil--不加这句不让返回主scene
  end

  --获得武器
  RewardManager:getReward(self.rewardList)
  --刷新显示
  self.refreshSelf()

  --弹出奖励
  self.aInfoPanel = FragmentEquipRewardPopPanel:create(self.container, self, self.rewardList[1], onClose)
  self.container:addChild(self.aInfoPanel, 100)
  self.aInfoPanel:scaleIn()
end

--弹出卡牌信息
function FragmentEquipListPanel:openCard(aData)
  local aEquip = generateEquip(0, MetaManager.equip_fragment_meta[aData.metaId].equipId, 1, tonumber(0))

  self.container._data = aEquip
  self.container.targetInfoPanel = EquipInfoPanelNoBtn:create( self.container , "BackpackScene")
  PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false ,self.container)
end
