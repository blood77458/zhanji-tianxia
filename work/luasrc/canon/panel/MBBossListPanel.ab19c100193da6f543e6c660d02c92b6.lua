require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.GetMultiplayerBossLeftHpRequest"
require "canon.scene.MultiplayerBossChallengeScene"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 706
local table_height = 845
local table_posX = 14
local table_posY = 115
local item_width = 692
local item_height = 166

--
-- MBBossListPanel
--

MBBossListPanel = class(Layer)

function MBBossListPanel:ctor()
    self.container = nil
    self.bossList = nil
end

function MBBossListPanel:create( container, bossList )
    local s = MBBossListPanel.new()
    s:initLayer(container, bossList)
    return s
end

function MBBossListPanel:initLayer(container, bossList)
    MBBossListPanel.super.initLayer(self)
    self.container = container
    self.bossList = bossList
    
    self.bossListTableView = self:createBossListTableView()
    self:addChild(self.bossListTableView)
    self.bossListTableView:reloadData()
end

function MBBossListPanel:createBossListTableView()
  local cellTag = 1024
  local buttonTag = {-15}
  local aMBBossListPanel = self
  local BossListTableViewRenderer = class(TableViewRenderer)
  function BossListTableViewRenderer:ctor(width, height)
    self.list = aMBBossListPanel.bossList or {}
  end
  function BossListTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/monster_nian.json")
    local aCell = builder:build("list_nowboss")
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
    
    local aBloodLabel = aCell:getChildByName("txt_nian_19")
    aBloodLabel:setTag(-12)
    aBloodLabel = aBloodLabel:getChildByName("txt")
    aBloodLabel:setTag(-10)
    
    local aTimeLabel = aCell:getChildByName("txt_nian_20")
    aTimeLabel:setTag(-13)
    aTimeLabel = aTimeLabel:getChildByName("txt")
    aTimeLabel:setTag(-10)
    
    local aFinderLabel = aCell:getChildByName("txt_nian_21")
    aFinderLabel:setTag(-14)
    aFinderLabel = aFinderLabel:getChildByName("txt")
    aFinderLabel:setTag(-10)
    
    local aButtonDisplay = aCell:getChildByName("btn_challenge_lt")
    aButtonDisplay:setTag(-15)
    local challangeLabel = aButtonDisplay:getChildByName("txt")
    challangeLabel:setTag(-10)
    challangeLabel:setString(Localization:getInstance():getText("activityNian_nianList_battleBtn"))
    local challengeDisplay = aButtonDisplay:getChildByName("btn")
    challengeDisplay:setTag(-11)
  end
  function BossListTableViewRenderer:setData( rawCocosObj, index )
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
    local aMonsterNameLabel = aCell:getChildByTag(-11)
    local cardGroup = aCardMeta.cardGroupId
    local nameKey 
    for _, card in pairs(MetaManager.card_meta) do
      if (card.evolutionLevel == 1) and (card.cardGroupId == cardGroup) then
        nameKey = MetaManager.card_meta[card.id].name
        break
      end
    end
    setNodeText(aMonsterNameLabel:getChildByTag(-10), Localization:getInstance():getText("activityNian_nianList_name", {cardname = Localization:getInstance():getText(nameKey), num = self.list[index + 1].level}))
    
    local aBloodLabel = aCell:getChildByTag(-12)
    setNodeText(aBloodLabel:getChildByTag(-10), Localization:getInstance():getText("activityNian_nianList_hp", {num = string.format("%d/%d", self.list[index + 1].leftHp, aMonsterMeta.hp)}))
    
    local aTimeLabel = aCell:getChildByTag(-13)
    local aLeftTime = self.list[index + 1].leftTime
    local hour = math.modf(aLeftTime / 3600)
    local min = math.modf(math.mod(aLeftTime, 3600) / 60)
    local sec = math.mod(math.mod(aLeftTime, 3600), 60)
    setNodeText(aTimeLabel:getChildByTag(-10), Localization:getInstance():getText("activityNian_nianList_time", {num = string.format("%02d:%02d:%02d", hour, min, sec)}))
    
    local aFinderLabel = aCell:getChildByTag(-14)
    setNodeText(aFinderLabel:getChildByTag(-10), Localization:getInstance():getText("activityNian_nianList_discoverer", {playername = self.list[index + 1].nickName}))
  end
  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local newCell = self.bossListTableView:cellAtIndex(aIndex - 1)
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
    local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-15)
    local challengeDisplay = buttonDisplay:getChildByTag(-11)
    
    if posInCell.x > buttonDisplay:getPositionX() and
      posInCell.x < (buttonDisplay:getPositionX() + challengeDisplay:getContentSize().width) and
      posInCell.y > (buttonDisplay:getPositionY() - challengeDisplay:getContentSize().height) and
      posInCell.y < buttonDisplay:getPositionY() then
      local function getMultiplayerBossLeftHpSucceed(event)
        self.bossList[aIndex].leftHp = event.data.leftHp
        local argv = {enterScene="MultiplayerBossScene",returnScene="MultiplayerBossScene",params={data = self.bossList[aIndex]}}
        self.container:replaceScene(MultiplayerBossChallengeScene, argv)
      end 
      local function getMultiplayerBossLeftHpFailed(event)
        if event.data.retCode == 714520 then  --activity closed
          local function closeCanonMessageBox()
            self.container:replaceScene(MainMenuScene)
          end
          local text = Localization:getInstance():getText("activityNian_timeOver")
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        elseif event.data.retCode == 714518 then  --overdue
          local function closeCanonMessageBox()
            --refresh ui
            for i = aIndex, #self.bossList - 1 do
              self.bossList[i] = self.bossList[i + 1]
            end
            self.bossList[#self.bossList] = nil
            self.bossListTableView:reloadData()
            self.container:refreshBossPanelTitle()
          end
          local text = Localization:getInstance():getText("activityNian_nianList_escapedTips")
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        elseif event.data.retCode == 714515 then  --activity closed but can gain reward
          local function closeCanonMessageBox()
            --refresh ui
            for i = #self.bossList, 1, -1 do
              self.bossList[i] = nil
            end
            self.bossListTableView:reloadData()
            self.container:refreshBossPanelTitle()
          end
          local text = Localization:getInstance():getText("activityNian_nianList_timeOver")
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        else
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        end
      end
      local params = {triggerUid = self.bossList[aIndex].triggerUid, bossId = self.bossList[aIndex].id}
      local request = GetMultiplayerBossLeftHpRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener( RequestNotifyEnum.GetMultiplayerBossLeftHpSucceed, getMultiplayerBossLeftHpSucceed )
      request:addEventListener( RequestNotifyEnum.GetMultiplayerBossLeftHpFailed, getMultiplayerBossLeftHpFailed )
      request:start()
    end
  end
  local renderer = BossListTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(table_posX, table_posY))
  return aTableView
end

function MBBossListPanel:dispose()
  MBBossListPanel.super.dispose(self)
end

function MBBossListPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.bossListTableView, visibleSize,callback)
end

function MBBossListPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.bossListTableView, visibleSize, callback)
end

function MBBossListPanel:setTableViewTouched(enabled)
  self.bossListTableView:setTouchEnabled(enabled)
end