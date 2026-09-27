--------------------------------------------------------------------------------
-- InspirePanel.lua - 鼓舞信息面板
--------------------------------------------------------------------------------

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.data.MetaManager"
require "canon.models.CommonManager"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

WorldBossAutoFightPanel = class(Layer)

function WorldBossAutoFightPanel:ctor()
    self.container = nil
end

function WorldBossAutoFightPanel:create( container, activityWorldBossLayer )
    self.container = container
	self.activityWorldBossLayer = activityWorldBossLayer
    local s = WorldBossAutoFightPanel.new()
    s:initLayer()
    return s
end

function WorldBossAutoFightPanel:initLayer()
	WorldBossAutoFightPanel.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
    self.panelUI = builder:build("common_popup1_long")
	self:addChild(self.panelUI)

	self.panelUI:getChildByName("common_btn_center"):setVisible(false)
	self.panelUI:getChildByName("common_txt_popup1"):setVisible(false)
	self.panelUI:getChildByName("common_txt_popup_line4"):getChildByName("txt_sellItem_equip"):setString(getTextByKey("worldBoss_autoConfirm"))

	local function onConfirm( evt )
		local function onSetAutoWorldBoss(response)
			print( "SetAutoWorldBossRequest info" )
			WorldBossScene.worldBossInfo.worldBossUser.autoChallenge = true
			self.activityWorldBossLayer:confirmAutoFight()
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			self.container.targetInspirePanel = nil
		end
			
		local params = { autoChallenge = true }
		local request = SetAutoWorldBossRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener( RequestNotifyEnum.setAutoWorldBossSuccessd, onSetAutoWorldBoss )
		request:start()
	end

	self.panelUI:getChildByName("common_btn_continue"):getChildByName("txt_continue"):setString(getTextByKey("yes"))
	local confirmBtn = Button:create(self.panelUI:getChildByName("common_btn_continue"))
	confirmBtn:addEventListener(Events.kStart, onConfirm)

  
   
    local function onCancelPanel(evt)
		
        PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		self.container.targetInspirePanel = nil
    end 
	
    self.panelUI:getChildByName("common_btn_cancel"):getChildByName("txt_cancel"):setString(getTextByKey("cancel"))
    local bt_panel_close = Button:create(self.panelUI:getChildByName("common_btn_cancel"))
    bt_panel_close:addEventListener(Events.kStart, onCancelPanel)   
   
	
end