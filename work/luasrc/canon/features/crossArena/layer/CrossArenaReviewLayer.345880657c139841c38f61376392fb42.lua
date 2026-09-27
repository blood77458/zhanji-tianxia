require "hecore.display.CocosObject"
require "hecore.display.Director"
require "canon.customUI.CanonGoodIcon"
require "canon.features.crossArena.manager.CrossArenaManager"

require "canon.features.crossArena.request.ChallengeCrossUserRequest"
require "canon.features.crossArena.request.RefreshMatchRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

CrossArenaReviewLayer = class(Layer)

--焦点变化事件
local function onFocusChanged(evt)
  evt.context:setTableViewTouched(evt.data == nil)
end


function CrossArenaReviewLayer:ctor()
  self.container = nil
end

function CrossArenaReviewLayer:create( container , extraArgs)
  local s = CrossArenaReviewLayer.new()
  s.container = container
  s:initLayer()
  return s
end

function CrossArenaReviewLayer:dispose()
  UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	CrossArenaReviewLayer.super.dispose(self)
end

function CrossArenaReviewLayer:panelDismiss()
  self.container.targetInfoPanel = nil
end

function CrossArenaReviewLayer:initLayer()
    CrossArenaReviewLayer.super.initLayer(self)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/cross_Arena.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("table_crossArena_zb")
    self:addChild(self.mainUI)
	self.mainUI:getChildByName("Palm_red9_pic"):setVisible(false)
    self.mainUI:getChildByName("txt_jj_28"):getChildByName("txt"):setString(getTextByKey("crossArena_battleRank3")..CrossArenaManager.getMyRank())
    self.mainUI:getChildByName("txt_jj_29"):getChildByName("txt"):setString(getTextByKey("crossArena_battleScore")..CrossArenaManager.getMyBattleScore())

    local dataList = CrossArenaManager.getReportList()
    self.tableView = self:createTableView(self.mainUI:getChildByName("table_zb_list") , dataList.reports)
    self.mainUI:addChild(self.tableView)

    --事件侦听
    UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

    self.mainUI:getChildByName("txt_jj_12"):getChildByName("txt"):setString(getTextByKey("crossArena_tips2"))

    if #dataList.reports == 0 then
      self.mainUI:getChildByName("txt_jj_12"):setVisible(true)
    else
      self.mainUI:getChildByName("txt_jj_12"):setVisible(false)
    end
end

function CrossArenaReviewLayer:createTableView(display , dataList)
    local cellTag = 1024

    local CrossPVPReviewRenderer = class(TableViewRenderer)

    function CrossPVPReviewRenderer:ctor(width , height )
        self.width = width
        self.height = height
        self.list = dataList or {}
    end

    function CrossPVPReviewRenderer:buildCell(container)
        local builder = LayoutBuilder:createWithContentsOfFile("scene/cross_Arena.json")
        local aCell = builder:build("list/list_zb_1")
        container:addChild(aCell)
        aCell:setTag(cellTag)

        --扫描cell并自动添加tag
        self:addTags(aCell)
    end

    function CrossPVPReviewRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local aData = self.list[index + 1]

        --显示头像,胜利头像
        local aCardDisplay = self:getChildByNames(aCell, "icon_head1/card_normal_card_small_sb_upR")
        local oldIcon = aCell:getChildByTag(-100)
        if oldIcon then
          oldIcon:removeFromParentAndCleanup(true)
        end
        local params = {}
        params.sourceDisplay = aCardDisplay
        params.showInCenter = true
        local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, CommonManager.getSelfAvatarMeta(), 0, params)
        local iconContainer1 = self:getChildByNames(aCell, "icon_head1")
        iconContainer1:addChild(icon.refCocosObj, aCardDisplay:getZOrder())
        if icon then
          icon:setTag(-100)
          icon:dispose()
        end
        aCardDisplay:setVisible(false)

        --显示头像,失败头像
        local aCardDisplay2 = self:getChildByNames(aCell, "icon_head2/card_normal_card_small_sb_upR")
        local oldIcon = aCell:getChildByTag(-100)
        if oldIcon then
          oldIcon:removeFromParentAndCleanup(true)
        end
        local params = {}
        params.sourceDisplay = aCardDisplay2
        params.showInCenter = true
        local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, aData.metaId, 0, params)
        local iconContainer2 = self:getChildByNames(aCell, "icon_head2")
        iconContainer2:addChild(icon.refCocosObj, aCardDisplay2:getZOrder())
        if icon then
          icon:setTag(-100)
          icon:dispose()
        end
        aCardDisplay2:setVisible(false)

        if aData.win then
          self:getChildByNames(aCell, "icon_head1/icon_jj_sb"):setVisible(false)
          self:getChildByNames(aCell, "icon_head1/other_gray9_panel"):setVisible(false)
          self:getChildByNames(aCell, "icon_head1/icon_jj_sl"):setVisible(true)

          self:getChildByNames(aCell, "icon_head2/icon_jj_sb"):setVisible(true)
          self:getChildByNames(aCell, "icon_head2/other_gray9_panel"):setVisible(true)
          self:getChildByNames(aCell, "icon_head2/icon_jj_sl"):setVisible(false)

        else
          self:getChildByNames(aCell, "icon_head2/icon_jj_sb"):setVisible(false)
          self:getChildByNames(aCell, "icon_head2/other_gray9_panel"):setVisible(false)
          self:getChildByNames(aCell, "icon_head2/icon_jj_sl"):setVisible(true)

          self:getChildByNames(aCell, "icon_head1/icon_jj_sb"):setVisible(true)
          self:getChildByNames(aCell, "icon_head1/other_gray9_panel"):setVisible(true)
          self:getChildByNames(aCell, "icon_head1/icon_jj_sl"):setVisible(false)
        end

        self:setTxtByNames(aCell, "txt_jj_21/txt", aData.nickName)--天梯积分：[]
        self:setTxtByNames(aCell, "txt_jj_22/txt", CrossArenaUtils.getLocationStrById(aData.server))--{num}区
        self:setTxtByNames(aCell, "txt_jj_23/txt", CrossArenaUtils.getUnionNameStrById(aData.unionName))--[军团名]

        -- --不显示按钮
        -- self:getChildByNames(aCell, "btn"):setVisible(false)
    end

    local function onListItemTouch( evt )
      local aIndex = evt.data + 1
      local newCell = self.tableView:cellAtIndex(aIndex - 1)
      local aCell = newCell:getChildByTag(cellTag)
      local posInCell = newCell:convertToNodeSpace(evt.globalPosition)

      local btnDisplay = self.renderer:getChildByNames(aCell, "icon_jj_ck")
      -- local btnBgDisplay = self.renderer:getChildByNames(aCell, "btn/normal")
      if posInCell.x > btnDisplay:getPositionX() and
        posInCell.x < (btnDisplay:getPositionX() + btnDisplay:getContentSize().width) and
        posInCell.y > (btnDisplay:getPositionY() - btnDisplay:getContentSize().height) and
        posInCell.y < btnDisplay:getPositionY() then
        --点击按钮
        local function successCallback( evt )
          Director:sharedDirector():replaceScene(BattleScene:create(evt.data, BattleBackType.kCrossPVPReview, BattleEnterEnum.kCrossPVPReview))
        end
        local function failCallback( evt )
          local errorCode = tonumber(evt.data.retCode)
          if errorCode == 716991 then
            local function onErrorConfirm(errorCode)
              local function onAfterSucceedTest(e)
                self:refreshSelf()
              end
              GetCrossPvpReportRequest.sendRequestDefalut(onAfterSucceedTest)
            end
            local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
          end
        end
        local params = {reportId = dataList[aIndex].uuid}
        GetCrossPvpVideoRequest.sendRequest(params , successCallback , failCallback)
      end
    end

    local builder = LayoutBuilder:createWithContentsOfFile("scene/cross_Arena.json")
    local aCell = builder:build("list/list_zb_1")

    local tableViewSizes = getTableViewSizes(display)
    display:setVisible(false)

    self.renderer = CrossPVPReviewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)
    self.renderer:scanTags(aCell)
    local btnTag = self.renderer:getTagByLayerName("icon_jj_ck")
    local aTableView = TableView:create(self.renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, {btnTag}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
    aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
    -- self.mainUI:addChild(aTableView)
    return aTableView
end

function CrossArenaReviewLayer:refreshSelf()
  if self.tableView then
    self.tableView:removeFromParentAndCleanup(true)
  end
  local dataList = CrossArenaManager.getReportList()
  self.tableView = self:createTableView(self.mainUI:getChildByName("table_zb_list") , dataList.reports)
  self.mainUI:addChild(self.tableView)

  if #dataList == 0 then
    self.mainUI:getChildByName("txt_jj_12"):setVisible(true)
  else
    self.mainUI:getChildByName("txt_jj_12"):setVisible(false)
  end
end

----------------------------------------------------------------------
-- 切页动作
----------------------------------------------------------------------

-- 进入页面
function CrossArenaReviewLayer:panelEnter(callback)
  if self.tableView then
    ViewControlUtil.showTableViewAction(self.tableView, visibleSize,callback)
  else
    if callback then
        callback()
    end
  end
end

-- 退出页面
function CrossArenaReviewLayer:panelExit(callback)
  if self.tableView then
    ViewControlUtil.disappearTableViewAction(self.tableView, visibleSize, callback)
  else
    if callback then
        callback()
    end
  end
end

--设置触摸是否开启
function CrossArenaReviewLayer:setTableViewTouched(enabled)
  if self.tableView then
    self.tableView:setTouchEnabled(enabled)
  end
end