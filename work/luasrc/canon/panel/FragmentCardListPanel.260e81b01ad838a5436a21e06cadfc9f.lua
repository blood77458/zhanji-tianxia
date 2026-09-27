--
-- FragmentCardListPanel.lua
-- Author: czh
-- Date: 2014-02-13 16:48:03
--

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.FragmentSynthetizeCardRequest"
require "canon.panel.FragmentCardRewardPopPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 706
local table_height = 818
local table_posX = 12
local table_posY = 125
local item_width = 692
local item_height = 183

FragmentCardListPanel = class(Layer)

--焦点变化事件
local function onFocusChanged(evt)
  evt.context:setTableViewTouched(evt.data == nil)
end

--------------------------------------------------------------------------------------------------------

function FragmentCardListPanel:ctor()
    self.container = nil
    self.dataList = nil
end

function FragmentCardListPanel:create( container )
    local s = FragmentCardListPanel.new()
    s:initLayer(container)
    return s
end

--用于补全其他将魂不够情况下 可以合成的情况
local xiaoyuSoul = {}

function FragmentCardListPanel:initLayer(container)
  container.uiGroup2:getChildByName("btn_tab_active"):setVisible(false)
  container.uiGroup1:getChildByName("btn_tab_active"):setVisible(true)
  local function refreshSelf()
    for i = #self.dataList, 1, -1 do
      table.remove(self.dataList, i)
    end

    local tempList = {}
    if DataManager:getGameInitData().sharkCardFragments then
      tempList = DataManager:getGameInitData().sharkCardFragments.sharkCardFragments
    end
    
    for _, v in ipairs(tempList) do
      if v.amount > 0 then
        --要有值才能显示
        table.insert(self.dataList, v)
      end
    end

    --排序
    local function sortFunc(a, b)
      local cardMetaIdA = MetaManager.card_fragment_meta[a.metaId].cardId
      local cardMetaIdB = MetaManager.card_fragment_meta[b.metaId].cardId
	  
	  --小玉魂最优先
	  if a.xyId ~= b.xyId then
		return (a.xyId > b.xyId)
	  end
	  
      --能够合成排上方
      local needNumA = MetaManager.card_fragment_meta[a.metaId].amount
      local canGainA = a.amount >= needNumA
      local needNumB = MetaManager.card_fragment_meta[b.metaId].amount
      local canGainB = b.amount >= needNumB
	  if canGainA ~= canGainB then
        return canGainA
      end

      --稀有度由高至低
      local starNumA = MetaManager.card_meta[cardMetaIdA].rare
      local starNumB = MetaManager.card_meta[cardMetaIdB].rare
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
    
	xiaoyuSoul = {}
	for k,v in pairs (self.dataList) do 
		local starNum 
		if v.metaId == 800601 then
			v.xyId = v.metaId
			starNum = 4
			xiaoyuSoul[starNum] = {metaId = v.metaId,starNum = 4,amount = v.amount,name = CanonGoodIcon.getGoodName(ResourceEnum.CARD_FRAGMENT, v.metaId, 1, {withoutAmount = true})}
		elseif v.metaId == 800602 then
			v.xyId = v.metaId
			starNum = 5
			xiaoyuSoul[starNum] = {metaId = v.metaId,starNum = 5,amount = v.amount,name = CanonGoodIcon.getGoodName(ResourceEnum.CARD_FRAGMENT, v.metaId, 1, {withoutAmount = true})}
		elseif v.metaId == 800603 then
			v.xyId = v.metaId
			starNum = 6
			xiaoyuSoul[starNum] = {metaId = v.metaId,starNum = 6,amount = v.amount,name = CanonGoodIcon.getGoodName(ResourceEnum.CARD_FRAGMENT, v.metaId, 1, {withoutAmount = true})}
		else
			v.xyId = 1
		end
	end
	
	table.sort(self.dataList, sortFunc)
	
    self.listTableView:reloadData()

    if #self.dataList <= 0 then
      --列表为空 显示字符串
      self.container.noneText:getChildByName("txt"):setString(Localization:getInstance():getText("fragment_card_empty"))
      self.container.noneText:setVisible(true)
    else
      --列表不空 不显示字符串
      self.container.noneText:setVisible(false)
    end
  end
  self.refreshSelf = refreshSelf

  FragmentCardListPanel.super.initLayer(self)
  self.container = container
  self.dataList = {}
  
  self.listTableView = self:createListTableView()
  self:addChild(self.listTableView)

  UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

  self.refreshSelf()
end

function FragmentCardListPanel:createListTableView()
  local cellTag = 1024
  local buttonTag = {-31}
  local aListPanel = self
  local CardFragmentListTableViewRenderer = class(TableViewRenderer)
  function CardFragmentListTableViewRenderer:ctor(width, height)
    self.list = aListPanel.dataList or {}
  end
  function CardFragmentListTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/soulcombine.json")
    builder.useArtLabelTTF = true
    local aCell = builder:build("list_soul")
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    aCell:getChildByName("frame_card"):setVisible(false)
    aCell:getChildByName("bg_card"):setVisible(false)
    
    --武魂数量: 
    aCell:getChildByName("txt_soulcombine_1"):getChildByName("txt"):setString(Localization:getInstance():getText("fragment_card_num"))

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

  function CardFragmentListTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local aData = self.list[index + 1]
    local cardMetaId = MetaManager.card_fragment_meta[aData.metaId].cardId
    local needNum = MetaManager.card_fragment_meta[aData.metaId].amount
	
	if aData.metaId == 800601 or aData.metaId == 800602 or aData.metaId == 800603 then
		
	end
    local originalCard3_co = aCell:getChildByTag(-20)
    if originalCard3_co then
      originalCard3_co:removeFromParentAndCleanup(true)
    end
    
    local originalCard4_co = aCell:getChildByTag(-21)
    if originalCard4_co then
      originalCard4_co:removeFromParentAndCleanup(true)
    end
    
    local aCardDisplay =  aCell:getChildByTag(-10)
    local card3_co = getHeadIconNoStarCanonCardByMetaId(cardMetaId)
    card3_co:setPosition(ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()))
    card3_co:setScale(0.9)
    aCell:addChild(card3_co.refCocosObj, 10)
    card3_co:setTag(-20)
    card3_co:dispose()
    
    local aCurrentNumLabel = aCell:getChildByTag(-11)
    setNodeText(aCurrentNumLabel:getChildByTag(-10), aData.amount)
    
    local aNameLabel = aCell:getChildByTag(-12)
    setNodeText(aNameLabel:getChildByTag(-10), CanonGoodIcon.getGoodName(ResourceEnum.CARD_FRAGMENT, aData.metaId, 1, {withoutAmount = true}))
    
    local aLastNumLabel = aCell:getChildByTag(-13)
    local aCollectInfo1 = aCell:getChildByTag(-14)
    local aCollectInfo2 = aCell:getChildByTag(-15)
    local aCanCombineInfo = aCell:getChildByTag(-16)
    local aBtnDisplay = aCell:getChildByTag(-31)
    
    local starNum = MetaManager.card_meta[cardMetaId].rare
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
	
	if aData.amount < needNum then
		-- 不够
		aLastNumLabel:setVisible(true)
		aCollectInfo1:setVisible(true)
		aCollectInfo2:setVisible(true)
		aCanCombineInfo:setVisible(false)
		aBtnDisplay:setVisible(false)
		setNodeText(aLastNumLabel:getChildByTag(-10), string.format("%d", needNum - aData.amount))
		if xiaoyuSoul[starNum] and aData.metaId ~= xiaoyuSoul[starNum].metaId and xiaoyuSoul[starNum].amount >= (needNum - aData.amount) then
			--不够 用 小玉 魂补
			aBtnDisplay:setVisible(true)	
		end
    else
      --足够
      aLastNumLabel:setVisible(false)
      aCollectInfo1:setVisible(false)
      aCollectInfo2:setVisible(false)
      aCanCombineInfo:setVisible(true)
      aBtnDisplay:setVisible(true)
    end

    --处理角标
    local aSmallIcon = aCell:getChildByTag(-22)
    if aSmallIcon then
      aSmallIcon:removeFromParentAndCleanup(true)
      aSmallIcon = nil
    end
    aSmallIcon = Sprite:create("Item/Picture/Prop_soul.png")
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
	  local canGainCardUseSoul,extraXiaoyuSoul,xiaoyuSoulName,xiaoyuSoulMetaId= self:canGain(self.dataList[aIndex])
	  local function gotoGainCardUseSoul()
		self:gain(self.dataList[aIndex],xiaoyuSoulMetaId,extraXiaoyuSoul)
	  end
	  if extraXiaoyuSoul then
		CanonMessageBox:Show(getTextByKey("cardSplit_tips13",{num = extraXiaoyuSoul,name = xiaoyuSoulName}), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 35, gotoGainCardUseSoul)
	  else
		if canGainCardUseSoul then
			gotoGainCardUseSoul()
		end
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

  local renderer = CardFragmentListTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(table_posX, table_posY))

  aTableView.hitTestPoint = function (self, worldPosition, useGroupTest)
    return false -- 修复遮挡下方按钮的bug
  end
  return aTableView
end

function FragmentCardListPanel:dispose()
  UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)

  FragmentCardListPanel.super.dispose(self)
end

function FragmentCardListPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.listTableView, visibleSize,callback)
end

function FragmentCardListPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.listTableView, visibleSize, callback)
end

--设置触摸是否开启
function FragmentCardListPanel:setTableViewTouched(enabled)
  self.listTableView:setTouchEnabled(enabled)
end

--查询能否领取卡牌
function FragmentCardListPanel:canGain(aData)
  local needNum = MetaManager.card_fragment_meta[aData.metaId].amount
  local cardMetaId = MetaManager.card_fragment_meta[aData.metaId].cardId
  local starNum = MetaManager.card_meta[cardMetaId].rare
  if aData.amount < needNum then
    --不够
	if xiaoyuSoul[starNum] and aData.metaId ~= xiaoyuSoul[starNum].metaId and xiaoyuSoul[starNum].amount >= (needNum - aData.amount) then
		--小玉魂 补充
		return false,needNum - aData.amount,xiaoyuSoul[starNum].name,xiaoyuSoul[starNum].metaId
	end
    return false
  end
  return true
end

function FragmentCardListPanel:gain(aData,xiaoyuSoulMetaId,extraXiaoyuSoul)

  --成功
  local function onSucceed(event)
    --奖励物品
    --print("gain返回成功信息 = " .. table.tostring(event))
    --记录获得的奖励
    self.rewardList = event.data.rewards

    --扣碎片
    local delItems = {}
    table.insert(delItems, {itemType = ResourceEnum.CARD_FRAGMENT, metaId = aData.metaId, amount = -MetaManager.card_fragment_meta[aData.metaId].amount})
	if xiaoyuSoulMetaId then
		table.insert(delItems, {itemType = ResourceEnum.CARD_FRAGMENT, metaId = xiaoyuSoulMetaId, amount = -extraXiaoyuSoul})
	end
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
    elseif event.data == 713600 then  --碎片不够
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("fragment_cardCombine_notEnough")
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
  local request = FragmentSynthetizeCardRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.FragmentSynthetizeCardSucceed, onSucceed)
  request:addEventListener(RequestNotifyEnum.FragmentSynthetizeCardFailed, onFailed)
  request:start()
end

--播放动画
function FragmentCardListPanel:playAnime(aData)
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
  local cardMetaId = MetaManager.card_fragment_meta[aData.metaId].cardId
  local meta = MetaManager.card_meta[cardMetaId]
  fspt:addChangeInstance("iconFrame", getSpriteFrameByName( IconHeadBorderDict[meta.rare] ))
  fspt:addChangeInstance("iconHead", createSpriteFrame( "card/head/" .. meta.figureId .. "_head.png" ))
  fspt:addChangeInstance("iconBG", createSpriteFrame("pic/empty.png" ))

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
function FragmentCardListPanel:doPlayComplete()
  --print("播放动画完毕! self.rewardList = " .. table.tostring(self.rewardList))

  local function onClose()
    --启用列表滚动
    self:setTableViewTouched(true)
    self.container.targetInfoPanel = nil--不加这句不让返回主scene
  end

  --获得卡牌
  RewardManager:getReward(self.rewardList)
  --刷新显示
  self.refreshSelf()

  --弹出奖励
  self.aInfoPanel = FragmentCardRewardPopPanel:create(self.container, self, self.rewardList[1], onClose)
  self.container:addChild(self.aInfoPanel, 100)
  self.aInfoPanel:scaleIn()
end

--弹出卡牌信息
function FragmentCardListPanel:openCard(aData)
  --改为通用弹出物品详情二级 modified by zheng.che @ 2014-11-20
  CanonGoodIcon.popoutGoodPanel(ResourceEnum.CARD_FRAGMENT, aData.metaId)
end
