--
-- TreasureInfoPanel.lua
-- Author: meilam.xie
-- Date: 2015-08-10 15:08:32
-- 创建宝物详情面板
--
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local showTypeEnum = {
	hp = 1,
	att = 2,
	def = 3,
}

local function getTreasureInfoFromInitData(treasureId)
  local TreasuresData = DataManager.getTreasuresData()
  local aTreasure = {} 
  -- print("~~~~~~~~~~~~~~~~~~~~gameInitData.sharkTreasures = "..tostringRich(TreasuresData))   
  for _, temp in ipairs(TreasuresData) do
    if treasureId == temp.treasureId then
      aTreasure = temp
      break
      end
  end
  return aTreasure
end

--TreasureInfoPanel 简介


TreasureInfoPanel = class(Layer)

function TreasureInfoPanel:ctor()
    
   
end

function TreasureInfoPanel:create(container,id,sharkTreasures)
    local s = TreasureInfoPanel.new()
    self.container = container
    self.Treasure = getTreasureInfoFromInitData(id)
	-- self.Treasure = sharkTreasures
    s:initLayer()
    return s
end

function TreasureInfoPanel:initLayer()
	TreasureInfoPanel.super.initLayer(self)
   
	local builder = LayoutBuilder:createWithContentsOfFile("scene/treasure.json")
	self.builder = builder
	builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_treasure2")
    self:addChild(self.panelUI)
    

    local function onClose(evt)
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
    -- self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
	end
	local Closedisplay = self.panelUI:getChildByName("frame_treasure_dk"):getChildByName("btn_close_sb")
	
	local  CloseBtn = Button:create(Closedisplay)
	CloseBtn:addEventListener(Events.kStart, onClose, self)
	self:addChild(self.panelUI)
	local Closedisplay = self.panelUI:getChildByName("frame_treasure_dk"):getChildByName("btn_close_sb")
    --treasure_txt_bwxq
    self.panelUI:getChildByName("frame_treasure_dk"):getChildByName("treasure_txt_bwxq"):getChildByName("txt_bwxq"):setString(getTextByKey("Treasure_titel_10"))
     self.panelUI:getChildByName("frame_treasure_dk1"):getChildByName("treasure_txt_bwxq"):getChildByName("txt"):setString(getTextByKey("cardInfo_Desc"))
	--简介
	local aDescArea = self.panelUI:getChildByName("frame_treasure_dk1"):getChildByName("green_tanslucent_grid9_pic")
	local aPanel = CardDescPanel:create(
		self.Treasure.metaId,
		{height=350, width=572},
		ccc3(255,255,255),
		self.Treasure.cardId
	)
	aPanel:setViewPosition(aDescArea:getPosition().x,aDescArea:getPosition().y-420)
	self.panelUI:getChildByName("frame_treasure_dk1"):getChildByName("green_tanslucent_grid9_pic"):addChild(aPanel)


	 --[[ local aCardId = aTreasureData.cardId
	if (aCardId~=0) then
		local cardsData = DataManager.getCardsData()
		local aCardMeta = CommonManager.getSubTableByKey(
			cardsData,
			{name="cardId", value=aCardId}
		).metaId
		local aCardName = MetaManager.card_meta[aCardMeta].name
		self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01"):getChildByName("zhuangbeizhong"):setZOrder(2001)
    self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01"):getChildByName("common_txt_ cc_max"):getChildByName("txt"):setString(Localization:getInstance():getText("bag_EquippedText",{cardname = getTextByKey(aCardName)}))
	else
		self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01"):getChildByName("common_txt_ cc_max"):setVisible(false)
		self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01"):getChildByName("zhuangbeizhong"):setVisible(false)
	end
	]]
	self.panelUI:getChildByName("treasure_equipInfo_upper_02"):getChildByName("common_txt_ cc_max"):setVisible(false)
	self.panelUI:getChildByName("treasure_equipInfo_upper_02"):getChildByName("zhuangbeizhong"):setVisible(false)--lbl_you
	self.panelUI:getChildByName("treasure_equipInfo_upper_02"):getChildByName("lbl_you"):setVisible(false)
    local  Celldisplay = self.panelUI:getChildByName("treasure_equipInfo_upper_02")
    for i=1,3 do
	   	Celldisplay:getChildByName("attribute_0"..i):getChildByName("icon_atk"):setVisible(false)
	   	Celldisplay:getChildByName("attribute_0"..i):getChildByName("icon_hp"):setVisible(false)
	   	Celldisplay:getChildByName("attribute_0"..i):getChildByName("icon_def"):setVisible(false)
    end
  -- self.ColorPanleList = {}
  for i=0,6 do

    local txtName = TreasureSystemUtils.getUINameTreasureAttrType(i)
    -- print("~~~~~~~~~~~~~~~~txtName = "..tostringRich(txtName))
    -- self.ColorPanleList[i+1] = txtName
    Celldisplay:getChildByName(txtName):setVisible(false)

  end
  self:refreshTreasureIconandStar()--aTreasureData.metaId
  self:refreshTreasureAtt(self.Treasure.treasureId)
	
   
end

function TreasureInfoPanel:refreshTreasureIconandStar()


	local  Celldisplay = self.panelUI:getChildByName("treasure_equipInfo_upper_02")
	Celldisplay:getChildByName("normal_card_small_sb"):setVisible(false)
    self:refreshTreasureColorPanel(MetaManager.treasure_meta[self.Treasure.metaId].rare)  
	--设置装备
	if self.treasureObject then
		self.treasureObject:removeFromParentAndCleanup(true)
    end 
	self.treasureObject = CanonItem:create()
    self.treasureObject:loadByMetaId(self.Treasure.metaId)
	self.treasureObject:setScale(130/150)
	local position = Celldisplay:getChildByName("normal_card_small_sb"):getPosition()
	self.treasureObject:setPosition(ccp(position.x,position.y))
	Celldisplay:addChild(self.treasureObject)
    self.flashPos = Celldisplay:convertToWorldSpace(ccp(position.x, position.y))
    
    for i=1,6 do
    	Celldisplay:getChildByName("common_star_sb"..i):setVisible(false)
    end

	for quality = 1, 7 do
		
		if (quality == MetaManager.treasure_meta[self.Treasure.metaId].rare+1) then
			break
		end
		Celldisplay:getChildByName("common_star_sb"..quality):setVisible(true)
	end
    Celldisplay:getChildByName("common_txt_bw_name"):getChildByName("txt"):setString(Localization:getInstance():getText(MetaManager.treasure_meta[self.Treasure.metaId].name))
	
end



function TreasureInfoPanel:refreshTreasureColorPanel(star)
  local  Celldisplay = self.panelUI:getChildByName("treasure_equipInfo_upper_02")

    for i=0,6 do
   
      local txtName = TreasureSystemUtils.getUINameTreasureAttrType(i)
      if i == star-1 then
        Celldisplay:getChildByName(txtName):setVisible(true)
      else
        Celldisplay:getChildByName(txtName):setVisible(false)
      end
   
    end
   
  
  
end


function TreasureInfoPanel:refreshTreasureAtt(treasureId)
 local  Celldisplay = self.panelUI:getChildByName("treasure_equipInfo_upper_02")
 
 local sharkTreasure = getTreasureInfoFromInitData(treasureId)	
 Celldisplay:getChildByName("txt_equip_lv_num"):getChildByName("font"):setString(sharkTreasure.level)
 local hp,def,att   = TreasureSystemUtils.CountAttandDefandHp(sharkTreasure,sharkTreasure.level)
 for i=1,3 do

 	local display = Celldisplay:getChildByName("attribute_0"..i)
 	if i == showTypeEnum.hp then
 		display:getChildByName("icon_hp"):setVisible(true)
 		display:getChildByName("txt_03"):getChildByName("txt"):setString(hp)
 		display:getChildByName("txt_02"):getChildByName("txt"):setString(hp)
 	elseif i == showTypeEnum.att then
 		display:getChildByName("icon_atk"):setVisible(true)
 		display:getChildByName("txt_03"):getChildByName("txt"):setString(att)
 		display:getChildByName("txt_02"):getChildByName("txt"):setString(att)
 	elseif i == showTypeEnum.def then
 		display:getChildByName("icon_def"):setVisible(true)
 		display:getChildByName("txt_03"):getChildByName("txt"):setString(def)
 		display:getChildByName("txt_02"):getChildByName("txt"):setString(def)
 	end
 	
 end

end
