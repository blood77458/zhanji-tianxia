require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.GetMultiplayerBossDamageRequest"
require "canon.panel.MBDamageRecordPopPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 706
local table_height = 755
local table_posX = 14
local table_posY = 115
local item_width = 692
local item_height = 166

--
-- MBRecordListPanel
--

MBRecordListPanel = class(Layer)

function MBRecordListPanel:ctor()
    self.container = nil
    self.recordList = nil
end

function MBRecordListPanel:create( container, recordList )
    local s = MBRecordListPanel.new()
    s:initLayer(container, recordList)
    return s
end

function MBRecordListPanel:initLayer(container, recordList)
    MBRecordListPanel.super.initLayer(self)
    self.container = container
    self.recordList = recordList
    
    table.sort(self.recordList, function(a, b)
      return a.triggerSecond > b.triggerSecond
    end
    )
    
    self.recordListTableView = self:createRecordListTableView()
    self:addChild(self.recordListTableView)
    self.recordListTableView:reloadData()
end

--add by czh
--因为可能弹出pop 所以需要禁用滚动
function MBRecordListPanel:setTableViewsEnabled(v)
  self.recordListTableView:setTouchEnabled(v)
end

function MBRecordListPanel:createRecordListTableView()
  local cellTag = 1024
  local buttonTag = {-14}
  local aMBRecordListPanel = self
  local RecordListTableViewRenderer = class(TableViewRenderer)
  function RecordListTableViewRenderer:ctor(width, height)
    self.list = aMBRecordListPanel.recordList or {}
  end
  function RecordListTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/monster_nian.json")
    local aCell = builder:build("list_challenge_record")
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    aCell:getChildByName("frame_card"):setVisible(false)
    aCell:getChildByName("bg_card"):setVisible(false)
    local aCardDisplay = aCell:getChildByName("normal_card_small")
    aCardDisplay:setTag(-10)
    aCardDisplay:setVisible(false)
    
    local aMonsterNameLabel = aCell:getChildByName("txt_nian_18")
    aMonsterNameLabel:setTag(-11)
    aMonsterNameLabel = aMonsterNameLabel:getChildByName("txt")
    aMonsterNameLabel:setTag(-10)
    
    local aFinderLabel = aCell:getChildByName("txt_nian_21")
    aFinderLabel:setTag(-12)
    aFinderLabel = aFinderLabel:getChildByName("txt")
    aFinderLabel:setTag(-10)
    
    local aBeatTimeLabel = aCell:getChildByName("txt_nian_22")
    aBeatTimeLabel:setTag(-13)
    aBeatTimeLabel = aBeatTimeLabel:getChildByName("txt")
    aBeatTimeLabel:setTag(-10)
    
    local aButtonDisplay = aCell:getChildByName("btn_battle_record_big")
    aButtonDisplay:setTag(-14)
    local challangeLabel = aButtonDisplay:getChildByName("txt")
    challangeLabel:setTag(-10)
    challangeLabel:setString(Localization:getInstance():getText("activityNian_rewardList_recordBtn"))
    local challengeDisplay = aButtonDisplay:getChildByName("btn")
    challengeDisplay:setTag(-11)
    
    local aNotGainedLabel = aCell:getChildByName("txt_nian_23")
    aNotGainedLabel:setTag(-15)
    aNotGainedLabel:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rewardList_claimed"))
    
    local aGainedLabel = aCell:getChildByName("txt_nian_24")
    aGainedLabel:setTag(-16)
    aGainedLabel:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rewardList_notClaimed"))
    
    local aWinLabel = aCell:getChildByName("txt_nian_25")
    aWinLabel:setTag(-17)
    aWinLabel = aWinLabel:getChildByName("txt")
    aWinLabel:setTag(-10)
  end
  function RecordListTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local originalCard3_co = aCell:getChildByTag(-20)
    if originalCard3_co then
      originalCard3_co:removeFromParentAndCleanup(true)
    end
    
    local aCardDisplay =  aCell:getChildByTag(-10)
    local aMonsterMeta = MetaManager.multiplayer_boss_level[self.list[index + 1].level]
    local aCardMetaId = aMonsterMeta.cardId
    local card3_co = getHeadIconCanonCardByMetaId(aCardMetaId)
    card3_co:setPosition(ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()))
    card3_co:setScale(0.9)
    aCell:addChild(card3_co.refCocosObj, 6)
    card3_co:setTag(-20)
    card3_co:dispose()
    
    local aCardMeta = MetaManager.card_meta[aCardMetaId]
    local cardGroup = aCardMeta.cardGroupId
    local nameKey 
    for _, card in pairs(MetaManager.card_meta) do
      if (card.evolutionLevel == 1) and (card.cardGroupId == cardGroup) then
        nameKey = MetaManager.card_meta[card.id].name
        break
      end
    end
    local aMonsterNameLabel = aCell:getChildByTag(-11)
    setNodeText(aMonsterNameLabel:getChildByTag(-10), Localization:getInstance():getText("activityNian_nianList_name", {cardname = Localization:getInstance():getText(nameKey), num = self.list[index + 1].level}))
    
    local aFinderLabel = aCell:getChildByTag(-12)
    setNodeText(aFinderLabel:getChildByTag(-10), Localization:getInstance():getText("activityNian_nianList_discoverer", {playername = self.list[index + 1].nickName}))
    
    local foundDateTable = os.date("*t", self.list[index + 1].triggerSecond)
    local foundMonth = foundDateTable.month
    local foundDay = foundDateTable.day
    local foundhour = foundDateTable.hour
    local foundMin = foundDateTable.min
    local aBeatTimeLabel = aCell:getChildByTag(-13)
    setNodeText(aBeatTimeLabel:getChildByTag(-10), Localization:getInstance():getText("activityNian_rewardList_time", {num = string.format("%02d/%02d  %02d:%02d", foundMonth, foundDay, foundhour, foundMin)}))
    
    if self.list[index + 1].gainReward then
      aCell:getChildByTag(-15):setVisible(false)
      aCell:getChildByTag(-16):setVisible(true)
    elseif self.list[index + 1].leftHp <= 0 then
      aCell:getChildByTag(-15):setVisible(true)
      aCell:getChildByTag(-16):setVisible(false)
    else
      aCell:getChildByTag(-15):setVisible(false)
      aCell:getChildByTag(-16):setVisible(false)
    end
    
    if self.list[index + 1].leftHp <= 0 then
      setNodeText(aCell:getChildByTag(-17):getChildByTag(-10), Localization:getInstance():getText("activityNian_rewardList_win"))
    else
      setNodeText(aCell:getChildByTag(-17):getChildByTag(-10), Localization:getInstance():getText("activityNian_rewardList_lose"))
    end
  end
  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local newCell = self.recordListTableView:cellAtIndex(aIndex - 1)
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
    local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-14)
    local challengeDisplay = buttonDisplay:getChildByTag(-11)
    
    if posInCell.x > buttonDisplay:getPositionX() and
      posInCell.x < (buttonDisplay:getPositionX() + challengeDisplay:getContentSize().width) and
      posInCell.y > (buttonDisplay:getPositionY() - challengeDisplay:getContentSize().height) and
      posInCell.y < buttonDisplay:getPositionY() then
      local function getMultiplayerBossDamageSucceed(event)
        --测试列表内容很多的情况
        -- table.insert(event.data.damages, event.data.damages[1])
        -- table.insert(event.data.damages, event.data.damages[1])
        -- table.insert(event.data.damages, event.data.damages[1])
        -- table.insert(event.data.damages, event.data.damages[1])
        -- table.insert(event.data.damages, event.data.damages[1])
        -- table.insert(event.data.damages, event.data.damages[1])
        -- table.insert(event.data.damages, event.data.damages[1])
        -- table.insert(event.data.damages, event.data.damages[1])
        -- table.insert(event.data.damages, event.data.damages[1])
        -- table.insert(event.data.damages, event.data.damages[1])
        -- table.insert(event.data.damages, event.data.damages[1])
        print("getMultiplayerBossDamageSucceed: " .. table.tostring(event))
        --弹出伤害面板
        self.aInfoPanel = MBDamageRecordPopPanel:create(self.container, event.data.damages)
        self.container:addChild(self.aInfoPanel)
        self.aInfoPanel:scaleIn()
      end 
      local function getMultiplayerBossDamageFailed(event)
        print("getMultiplayerBossDamageFailed")
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
      local params = {triggerUid = tonumber(self.recordList[aIndex].triggerUid), bossId = self.recordList[aIndex].id}
      local request = GetMultiplayerBossDamageRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener( RequestNotifyEnum.GetMultiplayerBossDamageSucceed, getMultiplayerBossDamageSucceed )
      request:addEventListener( RequestNotifyEnum.GetMultiplayerBossDamageFailed, getMultiplayerBossDamageFailed )
      request:start()
    end
  end
  local renderer = RecordListTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(table_posX, table_posY))
  return aTableView
end

function MBRecordListPanel:dispose()
  MBRecordListPanel.super.dispose(self)
end

function MBRecordListPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.recordListTableView, visibleSize,callback)
end

function MBRecordListPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.recordListTableView, visibleSize, callback)
end

function MBRecordListPanel:setTableViewTouched(enabled)
  self.recordListTableView:setTouchEnabled(enabled)
end

function MBRecordListPanel:rewardGained()
  local gainedNum = 0
  for _, aRecord in ipairs(self.recordList) do
    if not aRecord.gainReward and (aRecord.leftHp <= 0) then
      gainedNum = gainedNum + 1
    end
    aRecord.gainReward = true
  end
  self.recordListTableView:reloadData()
  local homeInfo = ActivityPanelScene.getStatusInfo()
  if homeInfo.ungainedRewardNum then
    homeInfo.ungainedRewardNum = math.max(homeInfo.ungainedRewardNum - gainedNum, 0)
  end
end