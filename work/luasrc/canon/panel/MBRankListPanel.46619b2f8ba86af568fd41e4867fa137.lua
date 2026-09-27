require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 706
local table_height = 755
local table_posX = 14
local table_posY = 115
local item_width = 692
local item_height = 166

local drag_height = item_height
local lastShowPosition = 0
local lastDirType = 2 --1:靠上 2:靠下
local touched = false
local currRankMax = 1

--
-- MBRankListPanel
--

MBRankListPanel = class(Layer)

function MBRankListPanel:ctor()
    self.container = nil
    self.rankList = {}--改为空数组 对其的操作只是添加或删除 没有重新赋值了 by czh @ 2014-2-10
    self.isInRankList = false--自己是否在排行榜中
end

function MBRankListPanel:create( container, rankList, showMe )
    local s = MBRankListPanel.new()
    s:initLayer(container, rankList, showMe)
    return s
end

function MBRankListPanel:initLayer(container, rankList, showMe, rankMax)

  --接收到列表信息 用于刷新显示
  local function onRequestCompleted(aList, aShowMe, aRankMax)
    currRankMax = aRankMax
    --将内容重置 然后填入获得到的数据
    for i = #self.rankList, 1, -1 do
      table.remove(self.rankList, i)
    end
    for _, v in ipairs(aList) do
      table.insert(self.rankList, v)
    end

    --刷新显示
    self.rankListTableView:reloadData()

    if aShowMe then
      self:showAtMyPosition()
    end

    if lastShowPosition ~= 0 then
      self:showAtPosition(lastShowPosition)
      lastShowPosition = 0
    end
    
    self:setTableViewTouched(true)
  end
  self.onRequestCompleted = onRequestCompleted

  --定时确认列表整体位置是否超出拉伸条件
  local function checkTablePosition()
    if touched then
      local currentPosition = self.rankListTableView:getContentOffset().y
      --print("checkTablePosition! currentPosition = " .. currentPosition)
      if currentPosition > drag_height then
        if (item_height * #self.rankList) < table_height then
          if currentPosition > (table_height - (item_height * #self.rankList) + drag_height) then
            self:dragDown()
          end
        else
          self:dragDown()
        end
      else
        local currentOffect = currentPosition + item_height * #self.rankList - table_height
        if currentOffect < -drag_height then
          self:dragUp()
        end
      end
    end
  end
  self.checkTablePosition = checkTablePosition

  MBRankListPanel.super.initLayer(self)
  self.container = container
  self.rankList = rankList
  currRankMax = rankMax
  
  self.rankListTableView = self:createRankListTableView()
  self:addChild(self.rankListTableView)
  self.rankListTableView:reloadData()

  if showMe then
    self:showAtMyPosition()
    end

  if not self.checkTablePositionTimer then --计时器不存在时创建
    self.checkTablePositionTimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(self.checkTablePosition, 0, false)
  end

  for i, v in ipairs(self.rankList) do
    if v.uid == DataManager.getGameInitData().sharkUser.uid then
      if v.rank ~= -1 then
        self.isInRankList = true
      end
    end
  end
end

function MBRankListPanel:createRankListTableView()
  local cellTag = 1024
  local buttonTag = {}
  local aMBRankListPanel = self
  local RankListTableViewRenderer = class(TableViewRenderer)
  function RankListTableViewRenderer:ctor(width, height)
    self.list = aMBRankListPanel.rankList or {}
  end
  function RankListTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/monster_nian.json")
    local aCell = builder:build("list_ranking")
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    aCell:getChildByName("frame_card"):setVisible(false)
    aCell:getChildByName("bg_card"):setVisible(false)
    local aCardDisplay = aCell:getChildByName("normal_card_small")
    aCardDisplay:setTag(-10)
    aCardDisplay:setVisible(false)
    
    local aRankLabel = aCell:getChildByName("txt_nian_25")
    aRankLabel:setTag(-11)
    aRankLabel = aRankLabel:getChildByName("txt")
    aRankLabel:setTag(-10)
    
    local aNameLabel = aCell:getChildByName("txt_nian_26")
    aNameLabel:setTag(-12)
    aNameLabel = aNameLabel:getChildByName("txt")
    aNameLabel:setTag(-10)
    
    local aLevelLabel = aCell:getChildByName("txt_nian_27")
    aLevelLabel:setTag(-13)
    aLevelLabel = aLevelLabel:getChildByName("txt")
    aLevelLabel:setTag(-10)
    
    local aPropDisplay = aCell:getChildByName("normal_card_small2")
    aPropDisplay:setTag(-14)
    aPropDisplay:setVisible(false)
    
    local aNumLabel = aCell:getChildByName("txt_nian_28")
    aNumLabel:setTag(-15)
    aNumLabel = aNumLabel:getChildByName("txt")
    aNumLabel:setTag(-10)
  end
  function RankListTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local originalCard3_co = aCell:getChildByTag(-20)
    if originalCard3_co then
      originalCard3_co:removeFromParentAndCleanup(true)
    end
    
    local originalCard4_co = aCell:getChildByTag(-21)
    if originalCard4_co then
      originalCard4_co:removeFromParentAndCleanup(true)
    end
    
    local aCardDisplay =  aCell:getChildByTag(-10)
    local newMeta = CommonManager:getSelfAvatarMetaByUid( self.list[index + 1].uid )
    if not newMeta then
        newMeta = self.list[index + 1].mainCardMetaId
    end
    local card3_co = getHeadIconCanonCardByMetaId(newMeta)
    card3_co:setPosition(ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()))
    card3_co:setScale(0.9)
    aCell:addChild(card3_co.refCocosObj, 6)
    card3_co:setTag(-20)
    card3_co:dispose()
    
    --del by czh @ 2014-1-27
    -- local aPropDisplay =  aCell:getChildByTag(-14)
    -- local card4_co = CanonItem:create()
    -- card4_co:loadByMetaId(0)  --FUCK
    -- card4_co:setPosition( ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()) )
    -- card4_co:setScale(0.3)
    -- aCell:addChild(card4_co.refCocosObj, 6)
    -- card4_co:setTag(-21)
    -- card4_co:dispose()

    --add by czh @ 2014-1-27 道具图标并没有显示出来
    local aPropDisplay = aCell:getChildByTag(-14)
    local icon = aCell:getChildByTag(-101)
    if icon then
      icon:removeFromParentAndCleanup(true)
    end
    icon = Sprite:create("Item/Picture/prop_tail0.png")
    icon:setScale(0.4)
    icon:setPosition( ccp(aPropDisplay:getPositionX(), aPropDisplay:getPositionY()) )
    aCell:addChild(icon.refCocosObj, 100)
    icon:setTag(-101)
    icon:dispose()
    
    local aRankLabel = aCell:getChildByTag(-11)
    if self.list[index + 1].rank == -1 then
      --未上榜
      setNodeText(aRankLabel:getChildByTag(-10), Localization:getInstance():getText("activityNian_outOfRank"))
    else
      --在榜上 排名是
      setNodeText(aRankLabel:getChildByTag(-10), Localization:getInstance():getText("activityNian_rankingTab_rank", {num = self.list[index + 1].rank}))
    end
    
    local aNameLabel = aCell:getChildByTag(-12)
    setNodeText(aNameLabel:getChildByTag(-10), self.list[index + 1].nickName)
    
    local aLevelLabel = aCell:getChildByTag(-13)
    setNodeText(aLevelLabel:getChildByTag(-10), string.format("LV %d", self.list[index + 1].level))
    
    local aNumLabel = aCell:getChildByTag(-15)
    setNodeText(aNumLabel:getChildByTag(-10), string.format("%d", self.list[index + 1].point))
  end
  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    --print("cell touched! aIndex = " .. aIndex)
    if self.rankList[aIndex].uid ~= DataManager.getGameInitData().sharkUser.uid then
      --不是玩家自身 点击才有效果
      local userDetailPanel = UserDetailPanel:create( self.container, {friendUid = self.rankList[aIndex].uid} )
      PopoutManager:sharedManager():popout(userDetailPanel, kPopoutDir.kScale, true, false, self.container)
    end
  end
  local function onListITouchBegin( evt )
    print("onListITouchBegin")
    touched = true
  end
  local renderer = RankListTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:addEventListener("tableCellTouchBegin", onListITouchBegin , self)
  aTableView:setPosition(ccp(table_posX, table_posY))
  return aTableView
end

function MBRankListPanel:dispose()
  if self.checkTablePositionTimer then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkTablePositionTimer)
  end
  MBRankListPanel.super.dispose(self)
end

function MBRankListPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.rankListTableView, visibleSize,callback)
end

function MBRankListPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.rankListTableView, visibleSize, callback)
end

function MBRankListPanel:setTableViewTouched(enabled)
  self.rankListTableView:setTouchEnabled(enabled)
end



--查看首位
function MBRankListPanel:checkTopButtonSelected()
  self:requestRanksBetween(1, 21, self.onRequestCompleted, self.container.bossInfo.point)
end

--查看自己
function MBRankListPanel:checkSelfButtonSelected()
  self:requestRanksBetween(0, 0, self.onRequestCompleted, self.container.bossInfo.point)
end
--请求某两个位置之间的排名
--若参数为0, 0则表示查看自己
function MBRankListPanel:requestRanksBetween(beginIndex, endIndex, completedCallBack, bossInfoPoint)
  local function getMultiplayerBossRankSucceed(event)
    print("getMultiplayerBossRankSucceed: " .. table.tostring(event))

    local haveMe = false--是否在原生表里有自己的数据
    local showMe = false--是否是查看自己
    local resultList = {}

    for _, v in ipairs(event.data.multiPlayerBossRanks) do
      table.insert(resultList, v)
      if v.uid == DataManager.getGameInitData().sharkUser.uid then
        haveMe = true
      end
    end

    if (beginIndex == 0) and (endIndex == 0) then
      --说明是查看自己
      showMe = true
    end

    if (not haveMe) and (not self.isInRankList) then
      --没有自己的数据 且自己不在排行榜中
      if showMe or 
        #event.data.multiPlayerBossRanks <= 0 or 
        event.data.multiPlayerBossRanks[#event.data.multiPlayerBossRanks].rank >= event.data.currRankMax
      then
        --需要显示自己 或者 列表为空 或者 最后一个人是末尾
        --生成一个虚构的自己
        local myData = {}
        myData.level = DataManager.getGameInitData().sharkUser.level
        myData.mainCardMetaId = MBRankListPanel:getCardMetaIdById(DataManager.getGameInitData().sharkUser.mainCardId)
        myData.uid = DataManager.getGameInitData().sharkUser.uid
        myData.point = bossInfoPoint
        myData.nickName = DataManager.getGameInitData().sharkUser.nickName
        myData.rank = -1

        table.insert(resultList, myData)
      end
    end
    
    completedCallBack(resultList, showMe, event.data.currRankMax)
  end 
  local function getMultiplayerBossRankFailed(event)
    print("getMultiplayerBossRankFailed")
    if event.data.retCode == 714520 then  --Multiplayer boss activity is closed: {0:uid}, {1:featureName}
      local function closeCanonMessageBox()
        self:replaceScene(MainMenuScene)
      end
      local text = Localization:getInstance():getText("activityNian_timeOver")
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    else
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end
  local function sendGetMultiplayerRankRequest()
    local params = {beginPos = beginIndex, endPos = endIndex}
    local request = GetMultiplayerBossRankRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener( RequestNotifyEnum.GetMultiplayerBossRankSucceed, getMultiplayerBossRankSucceed )
    request:addEventListener( RequestNotifyEnum.GetMultiplayerBossRankFailed, getMultiplayerBossRankFailed )
    request:start()
    print("sendGetMultiplayerRankRequest: params = " .. table.tostring(params))
  end
  
  --函数开始
  sendGetMultiplayerRankRequest()
end

--获得卡片的metaID
function MBRankListPanel:getCardMetaIdById(cardId)
  local All_Cards = DataManager.getCardsData()
  local subTable = nil
  local keyNo = -1
  for aKey, aValue in pairs(All_Cards) do
    if (tostring(aValue.cardId)==tostring(cardId)) then
      return aValue.metaId
    end
  end
  return cardId
end

--定位玩家自身的信息条目位置
function MBRankListPanel:showAtMyPosition()
  --寻找自己
  local myIndex = 1
  for i, v in ipairs(self.rankList) do
    if v.uid == DataManager.getGameInitData().sharkUser.uid then
      myIndex = i
    end
  end

  --设置位置
  self:showAtIndex(myIndex, 2)--自己要显示在靠下位置
end

--定位某一个特定位置的信息条目
function MBRankListPanel:showAtPosition(position)
  --寻找自己
  local index = 1
  for i, v in ipairs(self.rankList) do
    if v.rank == position then
      index = i
    end
  end

  --设置位置
  self:showAtIndex(index, lastDirType)
end

--显示某一个条目的位置为最下
--dirType 1:靠上 2:靠下
function MBRankListPanel:showAtIndex(index, dirType)
  --计算位置
  local yPosition

  if dirType == 2 then
    if (item_height * #self.rankList) < table_height then
      --整个列表不足一屏 列表整体最上
      yPosition = item_height * #self.rankList - table_height
    elseif index * item_height < table_height then
      --所在位置离最上不足一屏 列表整体最上
      yPosition = item_height * #self.rankList - table_height
    else
      --足够一屏 可以放在最下
      yPosition = item_height * (#self.rankList - index)
    end
  elseif dirType == 1 then
    --靠上
    if (item_height * #self.rankList) < table_height then
      --整个列表不足一屏 列表整体最上
      yPosition = item_height * #self.rankList - table_height
    elseif (#self.rankList - index + 1) * item_height < table_height then
      --所在位置离最下不足一屏 最后一个显示到结尾处
      yPosition = 0
    else
      --足够一屏 可以放在最上
      yPosition = item_height * (#self.rankList - index + 1) - table_height
    end
  end

  --设置位置
  self.rankListTableView:setContentOffset(ccp(0, -yPosition), false)
end

--触发上拉
function MBRankListPanel:dragUp()
  print("dragUp")
  local newHead = self:currentHead() - 10
  if newHead < 1 then
    newHead = 1
  end
  lastShowPosition = self:currentHead()-- - 1
  -- if lastShowPosition < 0 then
  --   lastShowPosition = 0
  -- end
  lastDirType = 2
  touched = false
  self:setTableViewTouched(false)
  self:requestRanksBetween(newHead, newHead + 20, self.onRequestCompleted, self.container.bossInfo.point)
end

--触发下拉
function MBRankListPanel:dragDown()
  print("dragDown")
  local newHead = self:currentHead() + 10
  lastShowPosition = self:currentTail()-- + 1
  if lastShowPosition < newHead then
    lastShowPosition = newHead
  end
  print("lastShowPosition = " .. lastShowPosition)
  lastDirType = 1
  touched = false
  self:setTableViewTouched(false)
  self:requestRanksBetween(newHead, newHead + 20, self.onRequestCompleted, self.container.bossInfo.point)
end

function MBRankListPanel:currentHead()
  local n = #self.rankList
  if n <= 0 then
    return 1
  end
  return self.rankList[1].rank
end

function MBRankListPanel:currentTail()
  local n = #self.rankList
  if n <= 0 then
    return 1
  end
  local lastRank = self.rankList[n].rank
  if lastRank ~= -1 then
    return self.rankList[n].rank
  elseif n >= 2 then
    return self.rankList[n-1].rank
  end
  return 1
end