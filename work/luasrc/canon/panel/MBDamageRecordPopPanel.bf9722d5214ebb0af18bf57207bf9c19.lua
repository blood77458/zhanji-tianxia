require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 678
local table_height = 210
local table_posX = 14 + 120
local table_posY = 115 + 390
local item_width = 435
local item_height = 50

--
-- MBDamageRecordPopPanel
-- 伤害记录面板 by czh 
--

MBDamageRecordPopPanel = class(Layer)

function MBDamageRecordPopPanel:ctor()
    self.container = nil
    self.recordList = nil
end

function MBDamageRecordPopPanel:create( container, recordList )
    local s = MBDamageRecordPopPanel.new()
    s:initLayer(container, recordList)
    return s
end

function MBDamageRecordPopPanel:initLayer(container, recordList)
  --触摸关闭
  local function closeButtonSelected(evt)
    self:dismiss()
  end

  MBDamageRecordPopPanel.super.initLayer(self)
  self.container = container
  self.recordList = recordList
    
  if (self.container.setTableViewsEnabled) then --有些弹窗可能发生在未继承BaseUI的场景中
    self.container:setTableViewsEnabled(false)
  end

  --淡入淡出
  
  self.colorLayer = LayerColor:create()
  self.colorLayer:setOpacity(kDarkOpacity)
  self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.colorLayer)
  
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.tempLayer)
  self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))

  local builder = LayoutBuilder:createWithContentsOfFile("scene/monster_nian.json")
  builder.useArtLabelTTF = true
  self.panelUI = builder:build("popup_history") 
  self.tempLayer:addChild(self.panelUI)

  --淡入淡出
  self.tempLayer:setScale(0.1)
  
  if #self.recordList <= 0 then
    --不显示table 显示一行文字
    self.panelUI:getChildByName("txt_no_dmg"):setVisible(true)
    self.panelUI:getChildByName("txt_no_dmg"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_damageRecord_noDamage"))
  else
    self.panelUI:getChildByName("txt_no_dmg"):setVisible(false)
    --显示table
    self.recordListTableView = self:createDamageRecordListTableView()
    self.panelUI:addChildAt(self.recordListTableView, 4)--要在白底(层级3)的上面 按钮层级下面 都行
    self.recordListTableView:reloadData()
  end

  --玩家昵称
  self.panelUI:getChildByName("txt_history_name_tab"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_damageRecord_playerName"))
  --总伤害值
  self.panelUI:getChildByName("txt_history_dmg_tab"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_damageRecord_damage"))
  --伤害记录
  self.panelUI:getChildByName("txt_history_dmg_title"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rewardList_recordBtn"))


  --关闭按钮
  local cancelButtonDisplay = self.panelUI:getChildByName("btn_history_close")
  cancelButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("close"))
  local cancelButton = Button:create(cancelButtonDisplay)
  cancelButton:addEventListener(Events.kStart,closeButtonSelected, self)

  --叉子按钮
  local closeButtonDisplay = self.panelUI:getChildByName("btn_close")
  local closeButton = Button:create(closeButtonDisplay)
  closeButton:addEventListener(Events.kStart,closeButtonSelected, self)
end

--淡入淡出
function MBDamageRecordPopPanel:scaleIn()
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

--淡入淡出
function MBDamageRecordPopPanel:dismiss()
  self:removeFromParentAndCleanup(true)
  if (self.container.setTableViewsEnabled) then --有些弹窗可能发生在未继承BaseUI的场景中
    self.container:setTableViewsEnabled(true)
  end
end

function MBDamageRecordPopPanel:createDamageRecordListTableView()
  local cellTag = 1024
  local buttonTag = {}
  local aMBRecordListPanel = self
  local DamageRecordListTableViewRenderer = class(TableViewRenderer)
  function DamageRecordListTableViewRenderer:ctor(width, height)
    self.list = aMBRecordListPanel.recordList or {}
  end
  function DamageRecordListTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/monster_nian.json")
    local aCell = builder:build("history_txt_combine")
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    local aPlayerNameLabel = aCell:getChildByName("txt_history_name")
    aPlayerNameLabel:setTag(-11)
    aPlayerNameLabel = aPlayerNameLabel:getChildByName("txt")
    aPlayerNameLabel:setTag(-10)
    
    local aPlayerDamageLabel = aCell:getChildByName("txt_history_dmg")
    aPlayerDamageLabel:setTag(-12)
    aPlayerDamageLabel = aPlayerDamageLabel:getChildByName("txt")
    aPlayerDamageLabel:setTag(-10)
  end
  function DamageRecordListTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)

    local aPlayerNameLabel = aCell:getChildByTag(-11)
    setNodeText(aPlayerNameLabel:getChildByTag(-10), self.list[index + 1].nickName)
    
    local aPlayerDamageLabel = aCell:getChildByTag(-12)
    setNodeText(aPlayerDamageLabel:getChildByTag(-10), self.list[index + 1].totalDamage)
  end
  local function onListItemTouch( evt )
  end
  local renderer = DamageRecordListTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(table_posX, table_posY))
  return aTableView
end

function MBDamageRecordPopPanel:dispose()
  MBDamageRecordPopPanel.super.dispose(self)
end

function MBDamageRecordPopPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.recordListTableView, visibleSize,callback)
end

function MBDamageRecordPopPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.recordListTableView, visibleSize, callback)
end

function MBDamageRecordPopPanel:setTableViewTouched(enabled)
  self.recordListTableView:setTouchEnabled(enabled)
end

function MBDamageRecordPopPanel:rewardGained()
  for _, aRecord in ipairs(self.recordList) do
    aRecord.gainReward = true
  end
  self.recordListTableView:reloadData()
end

