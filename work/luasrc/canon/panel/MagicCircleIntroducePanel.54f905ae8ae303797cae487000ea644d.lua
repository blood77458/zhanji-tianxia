----------------------------
--阵魂介绍面板
--by dangchao
--2015/4/14
----------------------------

MagicCircleIntroducePanel = class(Layer)

function MagicCircleIntroducePanel:ctor()
	self.container = nil
end

function MagicCircleIntroducePanel:create( container )
	local s = MagicCircleIntroducePanel.new()
	s:initLayer(container)
	return s
end

function MagicCircleIntroducePanel:initLayer(container)
	MagicCircleIntroducePanel.super.initLayer(self)
    
	self.container = container
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	--builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_introduce_camp")
	self.panelUI:getChildByName("bg_blackblood_1"):setVisible(false)
	self.panelUI:getChildByName("bg_decoration_cloud_R"):setVisible(false)
	self.panelUI:getChildByName("bg_decoration_cloud_L"):setVisible(false)
	
	self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("magicCircle_titel"))
	local introduceLockLable = {
								[1] = self.panelUI:getChildByName("txt_5"):getChildByName("txt_sellItem_equip"),
								[2] = self.panelUI:getChildByName("txt_4"):getChildByName("txt_sellItem_equip")
								}
	local introduceOpenLabel = {
								[1] = self.panelUI:getChildByName("txt_3"):getChildByName("txt_sellItem_equip"),
								[2] = self.panelUI:getChildByName("txt_2"):getChildByName("txt_sellItem_equip")
								}
	self.panelUI:getChildByName("txt_3"):getChildByName("txt_sellItem_equip"):setColor(ccc3(89,188,62))
	--self.panelUI:getChildByName("txt_3"):getChildByName("txt_sellItem_equip"):setAroundColor(ccc3(255,255,255))
	self.panelUI:getChildByName("txt_2"):getChildByName("txt_sellItem_equip"):setColor(ccc3(33,168,225))					
	local curMatrixId = MetaManager.getCurInBattleMatrixId()
	local magicCircleInfo = MagicCircleManager.GetMagicCircleInfoByMatrixId(curMatrixId)
	for mck,mcv in pairs(magicCircleInfo.magicCircleInfo) do 
		if mcv.isOpen then
			if introduceOpenLabel[mck] then
				introduceOpenLabel[mck]:setString(getTextByKey("magicCircle"..curMatrixId.."_text"..mck,{num1 = mcv.magicCircleNum .. "%"}))
			end
		else
			if introduceLockLable[mck] then
				introduceLockLable[mck]:setString(getTextByKey("magicCircle"..curMatrixId.."_text"..mck,{num1 = mcv.magicCircleNum .. "%"}))
			end
		end
	end
	local function onClose(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end
	local  CloseBtn = Button:create(self.panelUI:getChildByName("common_btn_close"))
	CloseBtn:addEventListener(Events.kStart, onClose)

	self:addChild(self.panelUI)

end

