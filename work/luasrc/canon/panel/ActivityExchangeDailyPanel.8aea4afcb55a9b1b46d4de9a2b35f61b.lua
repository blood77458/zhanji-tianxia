--
-- ActivityExchangeDailyPanel.lua
-- Author: meilam.xie
-- Date: 2015-03-24 15:32:32
-- 创建易帅换将面板
--


local visibleSize = CCDirector:sharedDirector():getVisibleSize()


--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end
------------------------------------------------------------------------------------------------------

ActivityExchangeDailyPanel = class(Layer)

function ActivityExchangeDailyPanel:ctor()
	self.container = nil
	self.content = nil
end

function ActivityExchangeDailyPanel:create(container)
	local s = ActivityExchangeDailyPanel.new()
	self.container = container
	s:initLayer(container)
	return s
end

function ActivityExchangeDailyPanel:initLayer(container)
	ActivityExchangeDailyPanel.super.initLayer(self)
		--点击关闭
	local function onClose(evt)
		
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end

	local function ToLook(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		
		local para = evt.context
        self.container:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_ExchangeDaily"})
	    
	end
	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_guild_colosseum_model") 

	self:addChild(self.panelUI)
	
	self.panelUI:getChildByName("txt_modelchoose_guild_info"):getChildByName("txt"):setString(getTextByKey("exchangDaily_guide"))
	self.panelUI:getChildByName("btn_slivercreate"):getChildByName("txt"):setString(getTextByKey("activity_fireworks_sure"))
	self.panelUI:getChildByName("btn_goldcreate"):getChildByName("txt"):setString(getTextByKey("levelup_goBtn"))
    --icon_gold
	self.panelUI:getChildByName("icon_gold"):setVisible(false)
	self.panelUI:getChildByName("txt_guild_71"):setVisible(false)
	self.panelUI:getChildByName("txt_guild_72"):setVisible(false)

    --关闭按钮
    --login_btn_close
    local  CloseBtn = Button:create(self.panelUI:getChildByName("login_btn_close"))

    CloseBtn:addEventListener(Events.kStart, onClose, self)

    local  SureBtn = Button:create(self.panelUI:getChildByName("btn_slivercreate"))

    SureBtn:addEventListener(Events.kStart, onClose, self)

    --去看看按钮 
    local  ToLookBtn = Button:create(self.panelUI:getChildByName("btn_goldcreate"))

    ToLookBtn:addEventListener(Events.kStart, ToLook, self)
    

end

function ActivityExchangeDailyPanel:dispose()
	ActivityExchangeDailyPanel.super.dispose(self)
end