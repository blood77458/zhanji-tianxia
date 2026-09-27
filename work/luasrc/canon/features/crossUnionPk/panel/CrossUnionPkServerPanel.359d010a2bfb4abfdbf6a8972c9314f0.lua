--
-- CrossUnionPkServerPanel.lua
-- geng.men
-- 2015-4-23
-- gvg 军团长或者副军团长上传镜像框
--

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

------------------------------------------------------------------------------------------------------

CrossUnionPkServerPanel = class(Layer)

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

function CrossUnionPkServerPanel:ctor()
end

function CrossUnionPkServerPanel:create(serverIds)
	local s = CrossUnionPkServerPanel.new()
	s.serverIds = serverIds
	s:initLayer()
	return s
end

function CrossUnionPkServerPanel:initLayer()
	CrossUnionPkServerPanel.super.initLayer(self)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_Gvg_07") 
	self:addChild(self.panelUI)

	local function onClose( evt )
		self:close()
	end

	local closeBtn = Button:create(self.panelUI:getChildByName("common_btn_close"))
	closeBtn:addEventListener( Events.kStart, onClose, self )

	for i=1,6 do
		self.panelUI:getChildByName("txt_Gvg_30_"..i):setVisible(false)
		self.panelUI:getChildByName("patter_formation_combination"..i):setVisible(false)
	end

	local function sortFunc( a , b )
		return a < b
	end

	table.sort( self.serverIds.serverIds , sortFunc )

	for k,v in pairs(self.serverIds.serverIds) do
		self.panelUI:getChildByName("txt_Gvg_30_"..k):setVisible(true)
		self.panelUI:getChildByName("patter_formation_combination"..k):setVisible(true)
		local tempTxt = v .. getTextByKey("crossBoss_serverSuffix") .. " " .. g_serverIds[v]
		self.panelUI:getChildByName("txt_Gvg_30_"..k):getChildByName("txt"):setString(tempTxt)
	end

	self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail21"))

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
end


function CrossUnionPkServerPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	CrossUnionPkServerPanel.super.dispose(self)
end

--关闭对话框
function CrossUnionPkServerPanel:close()
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

--设置触摸是否开启
function CrossUnionPkServerPanel:setTableViewsEnabled(enabled)
  if self.tableView then
    self.tableView:setTouchEnabled(enabled)
  end
end

-------------------------------------------------------------------------------------------------------------
