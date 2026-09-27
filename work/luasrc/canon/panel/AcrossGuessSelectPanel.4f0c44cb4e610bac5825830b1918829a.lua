require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

--
--AcrossGuessSelectPanel
--

AcrossGuessSelectPanel = class(Layer)

function AcrossGuessSelectPanel:ctor()
	self.container = nil
  self.owner = nil
end

function AcrossGuessSelectPanel:create(container,owner)
	local s = AcrossGuessSelectPanel.new()
	s:initLayer(container,owner)
	return s
end

function AcrossGuessSelectPanel:initLayer(container,owner)
	AcrossGuessSelectPanel.super.initLayer(self)
	self.container = container
  self.owner = owner

	local builder = LayoutBuilder:createWithContentsOfFile("scene/across_fight.json")
  builder.useArtLabelTTF = true
  self.uiView = builder:build("popup_quiz_1")
  self:addChild(self.uiView)
  
  self.uiView:getChildByName("txt_arossfight_popup_1"):getChildByName("txt"):setString(getTextByKey("cross_guess_gamer"))
  self.uiView:getChildByName("txt_arossfight_popup_2"):getChildByName("txt"):setString(getTextByKey("cross_guess_fight"))
  
  local function closeBtnSelected(evt)
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
  end
  local closeBtn = Button:create(self.uiView:getChildByName("login_btn_close"))
  closeBtn:addEventListener(Events.kStart, closeBtnSelected, self)
  
  local confirmDisplay = self.uiView:getChildByName("common_btn_long_yellow")
  confirmDisplay:getChildByName("txt"):setString(getTextByKey("cross_guess_confim"))
  local function confirmBtnSelected(evt)
    self.owner:guessUidSelected(self.selectUid)
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
  end
  local confirmBtn = Button:create(confirmDisplay)
  confirmBtn:addEventListener(Events.kStart, confirmBtnSelected, self)
  confirmDisplay:getChildByName("bg_btn"):setVisible(false)
  confirmDisplay:getChildByName("btn_common_inactive"):setVisible(true)
  confirmBtn:setEnable(false)
  self.confirmBtn = confirmBtn
  
  self.selectUid = nil
  local table_temp_view = self.uiView:getChildByName("table_quiz_list")
  table_temp_view:setVisible(false)
  self.table_meta_info = getTableViewSizes(table_temp_view)
  self.tableData = AcrossFightManager.getCapacityList()
  self.tableView = self:createTableView()
  self:addChildAt(self.tableView, 8)
  self.tableView:reloadData()
end

function AcrossGuessSelectPanel:createTableView()
	local cellTag = 1024
	local buttonTag = {-13}
	local aPanel = self
	local tableViewRenderer = class(TableViewRenderer)
	function tableViewRenderer:ctor(width, height)
		self.list = aPanel.tableData or {}
	end
	function tableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/across_fight.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list_quiz")
		container:addChild(aCell)
		aCell:setTag(cellTag)
    
    local aServerLabel = aCell:getChildByName("txt_across_fight_1")
    aServerLabel:setTag(-10)
		aServerLabel = aServerLabel:getChildByName("txt")
		aServerLabel:setTag(-10)
    
    local aNameLabel = aCell:getChildByName("txt_across_fight_13")
    aNameLabel:setTag(-11)
		aNameLabel = aNameLabel:getChildByName("txt")
		aNameLabel:setTag(-10)
    
    local aCapacityLabel = aCell:getChildByName("txt_arossfight_popup_3")
    aCapacityLabel:setTag(-12)
		aCapacityLabel = aCapacityLabel:getChildByName("txt")
		aCapacityLabel:setTag(-10)
    
    local aSelectBtnDisplay = aCell:getChildByName("btn_the_choose")
		aSelectBtnDisplay:setTag(-13)
		aSelectBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("cross_guess_choose"))
		aSelectBtnDisplay:getChildByName("btn"):setTag(-10)
    aSelectBtnDisplay:getChildByName("btn_disable"):setTag(-11)
	end

	function tableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
    
    local aServerLabel = aCell:getChildByTag(-10)
    local serverNumber = tonumber(string.sub(tostring(aData.uid), -4, -1))
    if __IOS then
      setNodeText(aServerLabel:getChildByTag(-10), Localization:getInstance():getText("cross_list_text", {num1 = serverNumber}))
    else
      setNodeText(aServerLabel:getChildByTag(-10), Localization:getInstance():getText("cross_list_android", {num1 = serverNumber}))
    end
    local aNameLabel = aCell:getChildByTag(-11)
    setNodeText(aNameLabel:getChildByTag(-10), AcrossFightManager.getGuessUsername(aData.uid))
    
    local aCapacityLabel = aCell:getChildByTag(-12)
    setNodeText(aCapacityLabel:getChildByTag(-10), tostring(aData.capacity))
    
    local aSelectBtnDisplay = aCell:getChildByTag(-13)
    local normalDisplay = aSelectBtnDisplay:getChildByTag(-10)
    local disabledDisplay = aSelectBtnDisplay:getChildByTag(-11)
    if tostring(aData.uid) == tostring(aPanel.selectUid) then
      normalDisplay:setVisible(false)
      disabledDisplay:setVisible(true)
      aSelectBtnDisplay.ignoreTouch = true
    else
      normalDisplay:setVisible(true)
      disabledDisplay:setVisible(false)
      aSelectBtnDisplay.ignoreTouch = false
    end
    
	end


	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.tableView:cellAtIndex(aIndex - 1)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData = self.tableData[aIndex]

		local aSelectBtnDisplay = newCell:getChildByTag(cellTag):getChildByTag(-13)
		local normalDisplay = aSelectBtnDisplay:getChildByTag(-10)
    if posInCell.x > aSelectBtnDisplay:getPositionX() and
      posInCell.x < (aSelectBtnDisplay:getPositionX() + normalDisplay:getContentSize().width) and
      posInCell.y > (aSelectBtnDisplay:getPositionY() - normalDisplay:getContentSize().height) and
      posInCell.y < aSelectBtnDisplay:getPositionY() then
      if tostring(aData.uid) ~= tostring(self.selectUid) then
        self.selectUid = aData.uid
        local offsetY = self.tableView:getContentOffset().y
        self.tableView:reloadData()
        self.tableView:setContentOffset(ccp(0, offsetY), false)
        
        self.confirmBtn.display:getChildByName("bg_btn"):setVisible(true)
        self.confirmBtn.display:getChildByName("btn_common_inactive"):setVisible(false)
        self.confirmBtn:setEnable(true)
      end
    end
	end

	local renderer = tableViewRenderer.new(self.table_meta_info.item_width, self.table_meta_info.item_height)
	local aTableView = TableView:create(renderer, self.table_meta_info.table_width, self.table_meta_info.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
	aTableView:setPosition(ccp(self.table_meta_info.table_posX, self.table_meta_info.table_posY))
  
	return aTableView
end
