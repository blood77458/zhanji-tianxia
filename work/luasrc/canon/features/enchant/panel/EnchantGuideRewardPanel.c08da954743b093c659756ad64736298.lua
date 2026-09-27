--
-- EnchantGuideRewardPanel
--

EnchantGuideRewardPanel = class(Layer)

function EnchantGuideRewardPanel:ctor()
    self.container = nil
end

function EnchantGuideRewardPanel:create( container )
    local s = EnchantGuideRewardPanel.new()
    s.container = container
    s:initLayer()
    return s
end

function EnchantGuideRewardPanel:initLayer()
    EnchantGuideRewardPanel.super.initLayer(self)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
    self.panelUI = builder:build("common_popup_guide_full")
    
    self.panelUI:getChildByName("common_txt_moreplay"):getChildByName("txt"):setString(getTextByKey("guide_enchant010"))

    local aRewardContainerUI = self.panelUI:getChildByName("guildPK_bank_item_fdrmation_2")
    local aIcon = aRewardContainerUI:getChildByName("normal_card_small")
    aIcon:setVisible(false)
    local equipMetaId = DataManager.GameMetaData.enchantTotalConfig.equipMetaId
    aRewardContainerUI:getChildByName("txt"):getChildByName("txt"):setString(CanonGoodIcon.getGoodName(ResourceEnum.EQUIP, equipMetaId, 1))
    local params = {}
    params.sourceDisplay = aIcon
    params.container = aRewardContainerUI
    params.showInCenter = true
    params.zindex = 10
    CanonGoodIcon.createGoodIcon(ResourceEnum.EQUIP, equipMetaId, 0, params)
    
    local function onClosePanel(evt)
    	local function afterSucceedCallback(event)
    		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
    		if self.container.curSceneEnum ~= SceneEnum.MainMenuScene then
				self.container:replaceScene(MainMenuScene)
			end
		end
		GetEnchantStepRewardRequest.sendRequestDefalut(nil, afterSucceedCallback)
    end
    self.panelUI:getChildByName("common_btn_close3"):getChildByName("txt"):setString(getTextByKey("achieve_task_get"))
    local sure_Btn = Button:create(self.panelUI:getChildByName("common_btn_close3"))
	sure_Btn:addEventListener(Events.kStart ,onClosePanel )
    

     local Close_Btn = Button:create(self.panelUI:getChildByName("btn_close"))
    Close_Btn:addEventListener(Events.kStart ,onClosePanel )

	self:addChild(self.panelUI) 
end