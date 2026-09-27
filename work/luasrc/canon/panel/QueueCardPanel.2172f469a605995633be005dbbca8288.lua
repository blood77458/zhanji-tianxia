--------------------------------------------------------------------------------
-- QueueCardPanel.lua - 卡牌队列滑动表
-- author: fanzhou.long
-- date: 2013-09-03
--------------------------------------------------------------------------------

--[[
Tags:
Basic -100
-1~-5 技能装备窗格
]]

local Table_width = 720--700
local Table_height = 664.75
local Table_posX = -6
local Table_posY = -16
local Item_width = 720
local Item_height = 0

local card_scale = 704/640
local item_scale = 108/144

local SKILL_TYPE_NORMAL = 1
local SKILL_TYPE_MAIN = 2


QueueCardPanel = class(Layer)

QueueCardPanel.ListTags = {
	CELL = -1001,
	CARD_FRAME = -100, --中心卡牌标签
	ICON_BASE = -100, --技能装备的基础标签值 范围-100 -1~-5
	NAMES_BASE = -100, --技能装备显示名的基础标签值 范围-100 +1~+5
	NAMES_TITLE = -100, --技能装备显示名框标签
	NAMES_TITLE_TEXT = -100, ----技能装备显示名框中文字的标签
	NAMES_BG = -101, --技能装备显示名背景标签
	SKILL_DOT_BASE = -1100, --下方组合技能紫色点标签
	SKILL_NAME_BASE = -1200, --下方组合技能技能名框标签
	SKILL_NAME_TEXT = -1200, --下方组合技能技能名中文字的标签
	SKILLAREA = -1300, --整个组合技能框的标签
	SKILLTIP = -100-20, --下方技能提示信息框标签
	SKILLTIP_TEXT = -20, --下方技能信息框里文字的标签

	TAG_TXT_LV = 101,
	TAG_TXT_ATKNUM = 102,
	TAG_TXT_DEFNUM = 103,
	TAG_TXT_HPNUM = 104,
	TAG_BUTTON_SPRITE = 105,
	TAG_TXT_CARDNAME = 106,
	TAG_ICON_LV = 107,
	TAG_ICON_ATK = 108,
	TAG_ICON_DEF = 109,
	TAG_ICON_HP = 110,
	TAG_ICON_KING = 111,

	TREASURE_ICON = 112,
	TREASURE_LOCK = 113,
	TAG_ICON_UPGRADE = 114, --全部强化
}

local empty_png = {
	"Item/Picture/Equip_empty.png",
	"Item/Picture/Equip_empty2.png",
	"Item/Picture/Equip_empty3.png",
	"Item/Picture/Skill_empty.png",
	"Item/Picture/Equip_empty4.png"
}

local empty_hint_text = {
	getTextByKey("formation_addWeapon"),
	getTextByKey("formation_addArmor"),
	getTextByKey("formation_addMount"),
	getTextByKey("Treasure_text_40")
}

local function itemFigureBuilder( source, targetId, noText )
	local aFigure = nil
	if (targetId > 0) then
		aFigure = CanonItem:create()
		aFigure:loadByMetaId(targetId)
	else
		aFigure = Sprite:create(UI_RES_PATH.."/formation_new/formation_normal_card_small_sb.png")
		if (targetId == 0) then
			local aBgSpt = Sprite:create(empty_png[4])
			aBgSpt:setAnchorPoint(ccp(0,0))
			aBgSpt:setScale(108/134)
			aFigure:addChild(aBgSpt)
		elseif (targetId == -100) then--宝物空箱子
			local aBgSpt = Sprite:create(empty_png[5])
			aBgSpt:setAnchorPoint(ccp(0,0))
			aBgSpt:setScale(108/134)
			local position = aBgSpt:getPosition()
			aBgSpt:setPosition(ccp(position.x - 3,position.y - 3))
			aFigure:addChild(aBgSpt)
			if (not noText) then
				local aText = ViewControlUtil.buildArtLabel( nil, empty_hint_text[4] )
				aText:setPosition(ccp(54,54))
				aFigure:addChild(aText)
			end
		else
			local aBgSpt = Sprite:create(empty_png[targetId*-1])
			aBgSpt:setAnchorPoint(ccp(0,0))
			aBgSpt:setScale(108/134)
			aFigure:addChild(aBgSpt)
			if (not noText) then
				local aText = ViewControlUtil.buildArtLabel( nil, empty_hint_text[targetId*-1] )
				aText:setPosition(ccp(54,54))
				aFigure:addChild(aText)
			end
		end
		aFigure:setZOrder(101)
	end
	local position = CocosObject.new(source):getPosition()
	aFigure:setPosition(ccp(position.x,position.y))
	return aFigure
end

local function createTreasure( source , targetId)
	local aFigure = nil
	aFigure = CanonItem:create()
	aFigure:loadByMetaId(targetId , false)

	local position = CocosObject.new(source):getPosition()
	aFigure:setPosition(ccp(position.x,position.y))
	return aFigure
end

function QueueCardPanel:ctor()
	self.container = nil
end

function QueueCardPanel:create(container, params)
	self.container = container
	local panel = QueueCardPanel.new()
	panel:initLayer()
	return panel
end

function QueueCardPanel:initLayer()
	QueueCardPanel.super.initLayer(self)
	-- 渲染 TableView
	self.tableUI = self:createCardQueueTableView()
	self:addChild(self.tableUI)
	--self.tableUI:reloadData()
end

local SKILL_ICON_PICNAME = {
	"Skill_weapon.png",
	"Skill_armor.png",
	"Skill_horse.png",
	"Skill_atk.png",
	"Skill_def.png",
	"Skill_hp.png",
}

----------------------------------------
----------------------------------------
function QueueCardPanel:createCardQueueTableView()
	local CardQueueListTableViewRenderer = class(TableViewRenderer)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/formation_new.json")
	builder.useArtLabelTTF = true
	local container = self.container
	
	function CardQueueListTableViewRenderer:ctor(width, height)
		for i=1,container.cardNums do
			self.list[i] = i
		end
	end
	
	function CardQueueListTableViewRenderer:buildCell(container)
		local aCell = builder:build("formation_mainframe_entry")
		-- aCell:setPosition(ccp(aCell:getPositionX() , aCell:getPositionY() - Table_height))
		container:addChild(aCell)
		
		aCell:setTag(QueueCardPanel.ListTags.CELL)
		aCell:getChildByName("full"):setTag(QueueCardPanel.ListTags.CARD_FRAME)

		aCell:getChildByName("icon_lock_big"):setTag(QueueCardPanel.ListTags.TREASURE_LOCK)
		aCell:getChildByName("icon_lock_big"):setZOrder(1003)
		
		for i=1, 6 do
			aCell:getChildByName("equip_test_"..i):setTag(QueueCardPanel.ListTags.ICON_BASE-i)
		end

		--标记Item名称
		for i=1, 6 do
			aCell:getChildByName("item_name"..i):setTag(QueueCardPanel.ListTags.NAMES_BASE+i)
			aCell:getChildByName("item_name"..i):getChildByName("txt_item_name"):setTag(QueueCardPanel.ListTags.NAMES_TITLE)
			aCell:getChildByName("item_name"..i):getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(QueueCardPanel.ListTags.NAMES_TITLE_TEXT)
			aCell:getChildByName("item_name"..i):getChildByName("bg_item_name"):setTag(QueueCardPanel.ListTags.NAMES_BG)
		end
		
		for i=1,9 do
			aCell:getChildByName("little_grey_dot"..i):setTag(QueueCardPanel.ListTags.SKILL_DOT_BASE-i)
			aCell:getChildByName("txt_skillcombine_name"..i):setTag(QueueCardPanel.ListTags.SKILL_NAME_BASE-i)
			aCell:getChildByName("txt_skillcombine_name"..i):getChildByName("txt"):setTag(QueueCardPanel.ListTags.SKILL_NAME_TEXT)
		end

		aCell:getChildByName("Transparent_green_light9_pic"):setTag(QueueCardPanel.ListTags.SKILLAREA)
		
		aCell:getChildByName("txt_formation_skill_tips"):setTag(QueueCardPanel.ListTags.SKILLTIP)
		aCell:getChildByName("txt_formation_skill_tips"):getChildByName("txt_formation_skill_tips"):setTag(QueueCardPanel.ListTags.SKILLTIP_TEXT)
		

		-- aCell:getChildByName("icon_lock"):setTag(QueueCardPanel.ListTags.TREASURE_ICON)
		--左下方锁定的位置
		-- local icon_lock = Sprite:create(UI_RES_PATH.."/formation_new/Equip_empty4.png")
		-- local originalIcon = aCell:getChildByName("icon_lock")
		-- icon_lock:setPosition(ccp(originalIcon:getPositionX(),originalIcon:getPositionY()))
		-- icon_lock:setScale(originalIcon:getScaleY())
		-- originalIcon:removeFromParentAndCleanup(true)
		-- aCell:addChild(icon_lock)

		-- aCell:getChildByName("txt_evo"):setZOrder(1002)
		aCell:getChildByName("formation_icon_lv_sb"):setZOrder(1002)
		aCell:getChildByName("txt_lv"):setZOrder(1002)
		aCell:getChildByName("icon_atk"):setZOrder(1002)
		aCell:getChildByName("icon_def"):setZOrder(1002)
		aCell:getChildByName("icon_hp"):setZOrder(1002)
		aCell:getChildByName("txt_hp_num"):setZOrder(1002)
		aCell:getChildByName("txt_atk_num"):setZOrder(1002)
		aCell:getChildByName("txt_def_num"):setZOrder(1002)

		aCell:getChildByName("txt_lv"):setTag(QueueCardPanel.ListTags.TAG_TXT_LV)
		aCell:getChildByName("txt_lv"):getChildByName("txt"):setTag(QueueCardPanel.ListTags.TAG_TXT_LV)
		aCell:getChildByName("txt_atk_num"):setTag(QueueCardPanel.ListTags.TAG_TXT_ATKNUM)
		aCell:getChildByName("txt_atk_num"):getChildByName("font"):setTag(QueueCardPanel.ListTags.TAG_TXT_ATKNUM)
		aCell:getChildByName("txt_def_num"):setTag(QueueCardPanel.ListTags.TAG_TXT_DEFNUM)
		aCell:getChildByName("txt_def_num"):getChildByName("font"):setTag(QueueCardPanel.ListTags.TAG_TXT_DEFNUM)
		aCell:getChildByName("txt_hp_num"):setTag(QueueCardPanel.ListTags.TAG_TXT_HPNUM)
		aCell:getChildByName("txt_hp_num"):getChildByName("font"):setTag(QueueCardPanel.ListTags.TAG_TXT_HPNUM)

		aCell:getChildByName("icon_elesoul"):setTag(QueueCardPanel.ListTags.TAG_BUTTON_SPRITE)
		aCell:getChildByName("formation_btn_to_unload"):setTag(QueueCardPanel.ListTags.TAG_ICON_UPGRADE) --全部强化
        -- aCell:getChildByName("formation_btn_to_unload"):getChildByName("")

		aCell:getChildByName("formation_icon_lv_sb"):setTag(QueueCardPanel.ListTags.TAG_ICON_LV)
		aCell:getChildByName("icon_atk"):setTag(QueueCardPanel.ListTags.TAG_ICON_ATK)
		aCell:getChildByName("icon_def"):setTag(QueueCardPanel.ListTags.TAG_ICON_DEF)
		aCell:getChildByName("icon_hp"):setTag(QueueCardPanel.ListTags.TAG_ICON_HP)
		aCell:getChildByName("formation_btn_to_unload"):getChildByName("txt"):setString(getTextByKey("strengthenAll_titel"))
        
	end
	
	function CardQueueListTableViewRenderer:setData( rawCocosObj, index )
		local aCardNo = index + 1
		
		local aCell = self:getChildByTag(rawCocosObj, QueueCardPanel.ListTags.CELL)

				
	  
		local childs = {}

		aCell:getChildByTag(QueueCardPanel.ListTags.TREASURE_LOCK):setVisible(false)
		
		childs[0] = aCell:getChildByTag(QueueCardPanel.ListTags.CARD_FRAME)
		childs[0]:setVisible(false)
			
		for i=1,6,1 do
			childs[i] = aCell:getChildByTag(QueueCardPanel.ListTags.ICON_BASE-i)
			childs[i]:setVisible(false)
		end
		
		for i=1,9 do
			aCell:getChildByTag(QueueCardPanel.ListTags.SKILL_DOT_BASE-i):setVisible(false)
			aCell:getChildByTag(QueueCardPanel.ListTags.SKILL_NAME_BASE-i):setVisible(false)
		end

		local treasureIcon = aCell:getChildByTag(QueueCardPanel.ListTags.TREASURE_ICON)
		
		local card_frame = CocosObject.new(childs[0])
		local frame_position = card_frame:getPosition()
		card_frame:removeFromParentAndCleanup(true)
		local cardDisplay = nil
		
		local aCard = container.queue[aCardNo]
        if aCard and ( not container.playerTeamData) then 
		
	        aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_UPGRADE):setVisible(true)
	    else
	    	aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_UPGRADE):setVisible(false)
	    end
		if aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_CARDNAME) then
			aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_CARDNAME):removeFromParentAndCleanup(true)
		end

		if aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_KING) then
			aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_KING):removeFromParentAndCleanup(true)
		end
		
		aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_LV):setVisible(false)
		aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_ATK):setVisible(false)
		aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_DEF):setVisible(false)
		aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_HP):setVisible(false)

		aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_LV):setVisible(false)
		aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_ATKNUM):setVisible(false)
		aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_DEFNUM):setVisible(false)
		aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_HPNUM):setVisible(false)
		if (aCard) then
			aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_LV):setVisible(true)
			aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_ATK):setVisible(true)
			aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_DEF):setVisible(true)
			aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_HP):setVisible(true)

			aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_LV):setVisible(true)
			aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_ATKNUM):setVisible(true)
			aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_DEFNUM):setVisible(true)
			aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_HPNUM):setVisible(true)

			local bigCardSpriteFrame = getFullCardSpriteFrame(CommonManager:changeAvatarByCardInfo( container.queue[aCardNo] ))
			local cardSprite = CCSprite:createWithSpriteFrame(bigCardSpriteFrame)
			cardDisplay = CocosObject.new(cardSprite)
			-- cardDisplay = getBigCanonCardNoInfoByMetaId(container.queue[aCardNo].metaId)
			local cardStatus = nil
			if (not container.playerTeamData) then
				cardStatus = CommonManager:getCardPropertiesWithSharkCardCache(aCard)
			else
				cardStatus = CommonManager:getCardPropertiesWithSharkCard(
					aCard,
					CommonManager.getQueueData(container.playerTeamData.mainCardId , container.playerTeamData.additionalCardIds),
					nil,
					container.playerTeamData.sharkCards,
					container.playerTeamData.sharkEquips,
					 CommonManager:getMatrixCardData({container.playerTeamData.sharkMatrices.sharkMatrices}),
					container.playerTeamData.sharkMatrices.sharkMatrices,
					container.playerTeamData.sharkBeasts,
					container.playerTeamData.sharkSpirits,
					container.playerTeamData.sharkTreasures
					)
			end


			
			local bmpName = BitmapText:create(getTextByKey(getTextByKey(MetaManager.card_meta[container.queue[aCardNo].metaId].name)), "common/card_name.fnt", 0, kCCTextAlignmentLeft)
	        bmpName:setScale(1)
	        local positionY = aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_LV):getPositionY()
	        bmpName:setPosition(ccp( 662.7 / 2, positionY ))
	        bmpName:setZOrder(1002)
	        bmpName:setTag(QueueCardPanel.ListTags.TAG_TXT_CARDNAME)
	        aCell:addChild(bmpName.refCocosObj)

			if CommonManager:checkIsCardPerfect(container.queue[aCardNo]) then
				local perfectSprite = nil
		        local perfectType = 0
				local cardMeta = MetaManager.card_meta[container.queue[aCardNo].metaId]
				if cardMeta.evolutionLevel == cardMeta.maxEvolvedLevel then
					perfectSprite = Sprite:create("common/icon_crown_gold.png")
				else
					perfectSprite = Sprite:create("common/icon_crown_silver.png")
				end
				local tempWidth = bmpName:getContentSize().width
				perfectSprite:setPosition(ccp( 662.7 / 2 - tempWidth / 2 - 25, positionY + 10 ))
				perfectSprite:setRotation(-45)
				perfectSprite:setZOrder(1002)
				perfectSprite:setTag(QueueCardPanel.ListTags.TAG_ICON_KING)
				aCell:addChild(perfectSprite.refCocosObj)
			end
			
			
	        setNodeText(aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_ATKNUM):getChildByTag(QueueCardPanel.ListTags.TAG_TXT_ATKNUM) , tostring(cardStatus.att))
	        setNodeText(aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_DEFNUM):getChildByTag(QueueCardPanel.ListTags.TAG_TXT_DEFNUM) , tostring(cardStatus.def))
	        setNodeText(aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_HPNUM):getChildByTag(QueueCardPanel.ListTags.TAG_TXT_HPNUM) , tostring(cardStatus.hp))
	        setNodeText(aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_LV):getChildByTag(QueueCardPanel.ListTags.TAG_TXT_LV) , tostring(cardStatus.level))
	        -- aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_ATKNUM):setString(tostring(cardStatus.att))
	        -- aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_DEFNUM):setString(tostring(cardStatus.def))
	        -- aCell:getChildByTag(QueueCardPanel.ListTags.TAG_TXT_HPNUM):setString(tostring(cardStatus.hp))
			-- cardDisplay:setAtk(math.floor(cardStatus.att))
			-- cardDisplay:setDef(math.floor(cardStatus.def))
			-- cardDisplay:setHp(math.floor(cardStatus.hp))
			-- cardDisplay:setLevel(aCard.level)
			local aCardMeta = MetaManager.card_meta[aCard.metaId]
			if (aCardMeta["skill"] ~= 0) then
		        local aSkillId = nil
		        for key, value in pairs(aCard.cardSkills) do
		          if(value.skillType == SKILL_TYPE_NORMAL) then
		            aSkillId = tonumber(value.skillId)
		          end
		        end  
       
				local leaderSkillFigure = itemFigureBuilder(childs[1], aCardMeta["skill"])
				--print("aSkillId = " .. tostringRich(aSkillId))
				local aSkill = MetaManager.skill_meta[aSkillId]
				local item_lv_bg = Sprite:createWithSpriteFrameName("item_lv_bg.png")
		        item_lv_bg:setPosition(ccp(23, 49))
						--print("aSkill = " .. tostringRich(aSkill))
		        card_lv = TextField:create("lv" .. aSkill.level,"Arial", 20)
		        card_lv:setPosition(ccp(42, 10))
		        item_lv_bg:addChild(card_lv)
		        leaderSkillFigure:addChild(item_lv_bg)
				
				aCell:addChild(leaderSkillFigure.refCocosObj)
				childs[1]:removeFromParentAndCleanup(true)
				childs[1] = leaderSkillFigure.refCocosObj
				leaderSkillFigure:dispose()
				local skillNameLabel = aCell:getChildByTag(QueueCardPanel.ListTags.NAMES_BASE+1):getChildByTag(QueueCardPanel.ListTags.NAMES_TITLE):getChildByTag(QueueCardPanel.ListTags.NAMES_TITLE_TEXT)
				--skillNameLabel = tolua.cast(skillNameLabel, "CCLabelTTF")
				setNodeText(skillNameLabel,getTextByKey(MetaManager.skill_meta[aCardMeta["skill"]]["name"]))
				aCell:getChildByTag(QueueCardPanel.ListTags.NAMES_BASE+1):setZOrder(2001)
			end
			if (aCardMeta["mainSkill"] ~= 0) then
		        local aSkillId = nil
		        for key, value in pairs(aCard.cardSkills) do
		          if(value.skillType == SKILL_TYPE_MAIN) then
		            aSkillId = tonumber(value.skillId)
		          end
		        end  
        
				local mainSkillFigure = itemFigureBuilder(childs[2], aCardMeta["mainSkill"])
				local aSkill = MetaManager.skill_meta[aSkillId]
		        local item_lv_bg = Sprite:createWithSpriteFrameName("item_lv_bg.png")
		        item_lv_bg:setPosition(ccp(23, 49))
		        card_lv = TextField:create("lv" .. aSkill.level,"Arial", 20)
		        card_lv:setPosition(ccp(42, 10))
		        item_lv_bg:addChild(card_lv)
		        mainSkillFigure:addChild(item_lv_bg)
				aCell:addChild(mainSkillFigure.refCocosObj)
				childs[2]:removeFromParentAndCleanup(true)
				childs[2] = mainSkillFigure.refCocosObj
				mainSkillFigure:dispose()
				local skillNameLabel = aCell:getChildByTag(QueueCardPanel.ListTags.NAMES_BASE+2):getChildByTag(QueueCardPanel.ListTags.NAMES_TITLE):getChildByTag(QueueCardPanel.ListTags.NAMES_TITLE_TEXT)
				--skillNameLabel = tolua.cast(skillNameLabel, "CCLabelTTF")
				setNodeText(skillNameLabel,getTextByKey(MetaManager.skill_meta[aCardMeta["mainSkill"]]["name"]))
				aCell:getChildByTag(QueueCardPanel.ListTags.NAMES_BASE+2):setZOrder(2001)
			end

			--宝物
			if aCard.treasure then
				if aCard.treasure.lock then
					aCell:getChildByTag(QueueCardPanel.ListTags.TREASURE_LOCK):setVisible(true)
				end
				local aSkillId = nil
		        for key, value in pairs(aCard.cardSkills) do
		          if(value.skillType == SKILL_TYPE_MAIN) then
		            aSkillId = tonumber(value.skillId)
		          end
		        end  
				local treasureFigure = itemFigureBuilder(childs[6], aCard.treasure.metaId)
		        local item_lv_bg = Sprite:createWithSpriteFrameName("item_lv_bg.png")
		        item_lv_bg:setPosition(ccp(23, 49))
		        card_lv = TextField:create("lv" .. aCard.treasure.level,"Arial", 20)
		        card_lv:setPosition(ccp(42, 10))
		        item_lv_bg:addChild(card_lv)
		        treasureFigure:addChild(item_lv_bg)
		        local kuang = Sprite.new(CCSprite:create("Item/Picture/Equip_empty4_1.png"))
		        treasureFigure:addChild(kuang)
				aCell:addChild(treasureFigure.refCocosObj)

				--添加闪烁动画
				local effect = FlashSprite:create("EVO2/TreasureFlash")
				effect:changeAnimation(0)
				effect:setLoop(true)
				effect = CocosObject.new(effect)
				treasureFigure:addChild(effect)

				childs[6]:removeFromParentAndCleanup(true)
				childs[6] = treasureFigure.refCocosObj
				treasureFigure:dispose()
				local skillNameLabel = aCell:getChildByTag(QueueCardPanel.ListTags.NAMES_BASE+6):getChildByTag(QueueCardPanel.ListTags.NAMES_TITLE):getChildByTag(QueueCardPanel.ListTags.NAMES_TITLE_TEXT)
				-- skillNameLabel = tolua.cast(skillNameLabel, "CCLabelTTF")
				setNodeText(skillNameLabel,getTextByKey(MetaManager.treasure_meta[aCard.treasure.metaId]["name"]))
				aCell:getChildByTag(QueueCardPanel.ListTags.NAMES_BASE+6):setZOrder(2001)



			end

			for key, aEquip in pairs(aCard.equips) do
				local equipFigure = itemFigureBuilder(childs[2+key], aEquip["metaId"])
				childs[2+key]:removeFromParentAndCleanup(true)
				childs[2+key] = equipFigure.refCocosObj
				
				--添加技能图标显示
				 local item_lv_bg = Sprite:createWithSpriteFrameName("item_lv_bg.png")
				  item_lv_bg:setPosition(ccp(23, 49))
				  card_lv = TextField:create("lv" .. aEquip.level,"Arial", 20)
				  card_lv:setPosition(ccp(42, 10))
				  item_lv_bg:addChild(card_lv)
				  equipFigure:addChild(item_lv_bg)
				
				aCell:addChild(equipFigure.refCocosObj)
				equipFigure:dispose()
				childs[-key] = nil
				local equipNameLabel = aCell:getChildByTag(QueueCardPanel.ListTags.NAMES_BASE+2+key):getChildByTag(QueueCardPanel.ListTags.NAMES_TITLE):getChildByTag(QueueCardPanel.ListTags.NAMES_TITLE_TEXT)
				--equipNameLabel = tolua.cast(equipNameLabel, "CCLabelTTF")
				setNodeText(equipNameLabel,getTextByKey(MetaManager.equip_meta[aEquip["metaId"]]["name"]))
				
				aCell:getChildByTag(QueueCardPanel.ListTags.NAMES_BASE+2+key):setZOrder(2001)
			end
			
			-- local gameInitData = DataManager.getGameInitData()

			local no = 1
			for i=1,#aCard.cardSkills do
				local aSkill = aCard.cardSkills[i]
				if (aSkill and aSkill.skillType==3 or aSkill.skillType==4) then
					aCell:getChildByTag(QueueCardPanel.ListTags.SKILL_DOT_BASE-no):setVisible(true)
					aCell:getChildByTag(QueueCardPanel.ListTags.SKILL_NAME_BASE-no):setVisible(true)
					local aTextNode = aCell:getChildByTag(QueueCardPanel.ListTags.SKILL_NAME_BASE-no):getChildByTag(QueueCardPanel.ListTags.SKILL_NAME_TEXT)
					setNodeText(
						aTextNode,
						getTextByKey( MetaManager.skill_meta[aSkill.skillId].name )
					)
					if (aCard.skillStatus[aSkill.skillId]) then
						local color
						if g_previousPlayerFateStatus then
							color = ccc3(43,186,233)
						else
							color = ccc3(0,153,51)
						end
						setNodeColor(
							aTextNode,
							color
						)
					else
						--必须重新设置颜色
						setNodeColor(
							aTextNode,
							ccc3(255,255,255)
						)
					end
					no = no + 1
				elseif (aSkill and aSkill.skillType==0) then
					aCell:getChildByTag(QueueCardPanel.ListTags.SKILL_DOT_BASE-no):setVisible(true)
					aCell:getChildByTag(QueueCardPanel.ListTags.SKILL_NAME_BASE-no):setVisible(true)
					local aEquipMeta = CommonManager.getSubTableByKey(
						MetaManager.equip_meta,
						{name = "prefixId", value=aSkill.equipPrefixId }
					)
					local aEquipName = MetaManager.equip_meta[aEquipMeta.id - aEquipMeta.evolveLevel + 1]["name"]
					local aTextNode = aCell:getChildByTag(QueueCardPanel.ListTags.SKILL_NAME_BASE-no):getChildByTag(QueueCardPanel.ListTags.SKILL_NAME_TEXT)
					setNodeText(
						aTextNode,
						getTextByKey( aEquipName )
					)
					if (aSkill.enabled) then
						setNodeColor(
							aTextNode,
							ccc3(0,153,51)
						)
					else
						--必须重新设置颜色
						setNodeColor(
							aTextNode,
							ccc3(255,255,255)
						)
					end
					no = no + 1
				elseif (aSkill and aSkill.skillType==5) then
					aCell:getChildByTag(QueueCardPanel.ListTags.SKILL_DOT_BASE-no):setVisible(true)
					aCell:getChildByTag(QueueCardPanel.ListTags.SKILL_NAME_BASE-no):setVisible(true)
					local aTreasureMeta = CommonManager.getSubTableByKey(
						MetaManager.treasure_meta,
						{name = "prefixID", value=aSkill.treasurePrefixId }
					)
					local aTreasureName = MetaManager.treasure_meta[aTreasureMeta.treasureID - aTreasureMeta.rare + 1]["name"]
					local aTextNode = aCell:getChildByTag(QueueCardPanel.ListTags.SKILL_NAME_BASE-no):getChildByTag(QueueCardPanel.ListTags.SKILL_NAME_TEXT)
					setNodeText(
						aTextNode,
						getTextByKey( MetaManager.skill_meta[aSkill.skillId].name )
					)
					if (aSkill.enabled) then
						setNodeColor(
							aTextNode,
							ccc3(0,153,51)
						)
					else
						--必须重新设置颜色
						setNodeColor(
							aTextNode,
							ccc3(255,255,255)
						)
					end
					no = no + 1
				end
			end
			cardDisplay:setZOrder(-1001)
		else
			cardDisplay = builder:build("layer/formation_card_add_big")
			cardDisplay:setZOrder(1001)
			cardDisplay:getChildByName("txt"):setString(getTextByKey("formation_addCard"))
			if (container.playerTeamData) then  --好友队列，屏蔽事件
				cardDisplay:getChildByName("txt"):setVisible(false)
				cardDisplay:getChildByName("btn_add_big"):setVisible(false)
				cardDisplay:setZOrder(-1001)
			end
		end
		
		cardDisplay:setPosition(ccp(frame_position.x,frame_position.y))
		cardDisplay:setTag(QueueCardPanel.ListTags.CARD_FRAME)
		cardDisplay:setScale(card_scale)
		-- cardDisplay:setZOrder(-1001)
		aCell:addChild(cardDisplay.refCocosObj)
		childs[0]:removeFromParentAndCleanup(true)
		card_frame:dispose()
		cardDisplay:dispose()
		
		for i=1,2,1 do
			if (not childs[i]:isVisible()) then
				local itemFigure = itemFigureBuilder(childs[i], 0)
				childs[i]:removeFromParentAndCleanup(true)
				childs[i] = itemFigure.refCocosObj
				aCell:addChild(itemFigure.refCocosObj)
				itemFigure:dispose()
				aCell:getChildByTag(QueueCardPanel.ListTags.NAMES_BASE+i):setZOrder(0)
			else
				childs[i]:setScale(item_scale)
			end
			childs[i]:setTag(QueueCardPanel.ListTags.ICON_BASE-i)
		end

		do
			local i = 6
			if (not childs[i]:isVisible()) then
				local itemFigure = itemFigureBuilder(childs[i], -100)
				childs[i]:removeFromParentAndCleanup(true)
				childs[i] = itemFigure.refCocosObj
				aCell:addChild(itemFigure.refCocosObj)
				itemFigure:dispose()
				aCell:getChildByTag(QueueCardPanel.ListTags.NAMES_BASE+i):setZOrder(0)
			else
				childs[i]:setScale(item_scale)
			end
			childs[i]:setTag(QueueCardPanel.ListTags.ICON_BASE-i)
		end
		
		for i=3,5,1 do
			if (not childs[i]:isVisible()) then
				local itemFigure = itemFigureBuilder(childs[i], i*-1+2, container.playerTeamData ~= nil)
				childs[i]:removeFromParentAndCleanup(true)
				childs[i] = itemFigure.refCocosObj
				aCell:addChild(itemFigure.refCocosObj)
				itemFigure:dispose()
				aCell:getChildByTag(QueueCardPanel.ListTags.NAMES_BASE+i):setZOrder(0)
			else
				childs[i]:setScale(item_scale)
			end
			childs[i]:setTag(QueueCardPanel.ListTags.ICON_BASE-i)
		end
		
		for i=1,6,1 do
			childs[i]:setZOrder(1001)
		end
		
		local skillTipLabel = aCell:getChildByTag(QueueCardPanel.ListTags.SKILLTIP):getChildByTag(QueueCardPanel.ListTags.SKILLTIP_TEXT)
		skillTipLabel = tolua.cast(skillTipLabel, "CCLabelTTF")
		setNodeText(skillTipLabel,"")
		if (aCard) then
			if (aCard.skillTip) then
				setNodeText(skillTipLabel,aCard.skillTip)
			end
		end
	end
	
	--------------------
	-- 设置table每个元素的监听器
	--------------------
	local function onListItemTouch( evt )
		local aIndex = evt.data
		local aCell = self.table:cellAtIndex(aIndex)
		
		local childs = aCell:getChildByTag(QueueCardPanel.ListTags.CELL)
		local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
		
		local cardFrame = childs:getChildByTag(QueueCardPanel.ListTags.CARD_FRAME)
		local skillArea = childs:getChildByTag(QueueCardPanel.ListTags.SKILLAREA)
		---[[
		local frameSize = {}
		local aCard = container.queue[aIndex + 1]
		if aCard then
			frameSize.height = 380
			frameSize.width = 270
		else
			frameSize.height = 447 * card_scale
			frameSize.width = 270
		-- 	local frameSize = {
		-- 	height = 380,
		-- 	width = 270,
		-- }
		end
		local iconSize = {
			height = 110,
			width = 110,
		}--]]
		local spriteSize ={
		height = 83,
		width = 87,
	}

		local upgradeSize ={
		height = 50,
		width = 133,
	}
		
		function getTouchedItemIndex()
			---[[
			if(	(posInCell.x > cardFrame:getPositionX()-frameSize.width/2) and
				(posInCell.x < cardFrame:getPositionX()+frameSize.width/2) and
				(posInCell.y > cardFrame:getPositionY()-frameSize.height/2) and
				(posInCell.y < cardFrame:getPositionY()+frameSize.height/2)) then
				return 0
			end--]]
			--[[
			if ( ViewControlUtil.isInArea(posInCell, cardFrame) ) then
				return 0
			end--]]
			
			for i=1, 6 do
				local aBtnArea = childs:getChildByTag(QueueCardPanel.ListTags.ICON_BASE-i)
				---[[
				if ((posInCell.x > aBtnArea:getPositionX()-iconSize.width/2) and
					(posInCell.x < aBtnArea:getPositionX()+iconSize.width/2) and
					(posInCell.y > aBtnArea:getPositionY()-iconSize.height/2) and
					(posInCell.y < aBtnArea:getPositionY()+iconSize.height/2)) then
					return i
				end--]]
				--[[
				if ( ViewControlUtil.isInArea(posInCell, aBtnArea) ) then
					return i
				end--]]
			end

			local aBtnSprite = childs:getChildByTag(QueueCardPanel.ListTags.TAG_BUTTON_SPRITE)
			if ((posInCell.x > aBtnSprite:getPositionX()) and
				(posInCell.x < aBtnSprite:getPositionX()+spriteSize.width) and
				(posInCell.y > aBtnSprite:getPositionY()-spriteSize.height) and
				(posInCell.y < aBtnSprite:getPositionY())) then
				return 8
			end 

			local aBtnUpgrade = childs:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_UPGRADE)
			if ((posInCell.x > aBtnUpgrade:getPositionX()) and
				(posInCell.x < aBtnUpgrade:getPositionX()+upgradeSize.width) and
				(posInCell.y > aBtnUpgrade:getPositionY()-upgradeSize.height) and
				(posInCell.y < aBtnUpgrade:getPositionY())) then
				return 9
			end 
			
			if ( ViewControlUtil.isInArea(posInCell, skillArea) ) then
				return 0
			end
			return -1
		end

		local itemIndex = getTouchedItemIndex()
		if (itemIndex==0) then
			container:cardFrameTouched(aIndex+1)
		elseif (itemIndex<3 and itemIndex>0) then
			container:skillBtnTouched(aIndex+1, itemIndex)
		elseif (itemIndex<6 and itemIndex>2) then
			container:equipBtnTouched(aIndex+1, itemIndex-2)
		elseif (itemIndex == 6) then
			if not TreasureManager.isUserLevelEnough() then
				local aContent = Localization:getInstance():getText("Treasure_text_37" , {num = TreasureManager.getTreasureUserLevel()})
     			SuspensionLabel:showContent(self, aContent)
     			return
			end
			container:treasureBtnTouched(aIndex+1)
		elseif (itemIndex == 8) then
			container:toSpritePanelTouched()
		elseif (itemIndex == 9) then
			if aCard then
				print("~~~~~~~~~~~~~~~~~~全部强化")
				local serverId = DataManager.getServerid()
				local uid = DataManager.getGameInitData().sharkUser.uid
				local level = DataManager.getGameInitData().sharkUser.level
				local time  = TimeUtil.getServerTimeSeconds()
				DcManager.sendDCActionInfo(serverId,uid,level,time,"equip","strengthenAll")
				-- childs:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_UPGRADE):setVisible(true)
				container:upgradeBtnTouched(aIndex+1)
			
			end
		--else
			--print("Hint: Unknown area touched")
		end
	end
	
	local function onSelectItem( evt )
    if container.selectedCardNo and container.selectedCardNo == evt.globalPosition + 1 then
      return
    end
    
		if (container.tableUI:cellAtIndex(container.selectedCardNo-1)) then
			container.tableUI:cellAtIndex(container.selectedCardNo-1):getChildByTag(CardQueueScene.ListTags.LAYER):getChildByTag(CardQueueScene.ListTags.CELL):getChildByTag(CardQueueScene.ListTags.ICON_SHADOW):setVisible(false) 
		end
		if (container.tableUI:cellAtIndex(evt.globalPosition)) then
			container.tableUI:cellAtIndex(evt.globalPosition):getChildByTag(CardQueueScene.ListTags.LAYER):getChildByTag(CardQueueScene.ListTags.CELL):getChildByTag(CardQueueScene.ListTags.ICON_SHADOW):setVisible(true)
		end
    
		container.selectedCardNo = evt.globalPosition + 1
    
    local scrollTo = evt.globalPosition
    scrollTo = ((container.cardNums - 4)<scrollTo) and ((container.cardNums - 4)) or scrollTo
    scrollTo = (scrollTo<0) and 0 or scrollTo
    container.tableOffsetUpperTarget = -scrollTo*(container.cellWidth)
    container.rolling = true
    container.cardPanelSpirit.tableUI:setContentOffset(ccp(-scrollTo*(Item_width), 0))

	end
	
	local renderer = CardQueueListTableViewRenderer.new(Item_width, Item_height)

	local aTableView = TableView:create(renderer, Table_width, Table_height, nil, {}, nil, nil, nil, nil, {noScrollBar = true})


	self.table = aTableView
	aTableView:setDirection(kCCScrollViewDirectionHorizontal)
	aTableView:setPageEnabled(true)
	if (not container.playerTeamData) then  --好友队列，屏蔽事件

		aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
    aTableView:addEventListener(DisplayEvents.kSelectItem, onSelectItem , self)
  else
  	local function onListItemTouch2( evt )
  		local aIndex = evt.data
		local aCell = self.table:cellAtIndex(aIndex)
		
		local childs = aCell:getChildByTag(QueueCardPanel.ListTags.CELL)
		local posInCell = aCell:convertToNodeSpace(evt.globalPosition)

		local spriteSize ={
		height = 83,
		width = 87,
	}
		local aBtnSprite = childs:getChildByTag(QueueCardPanel.ListTags.TAG_BUTTON_SPRITE)
		if ((posInCell.x > aBtnSprite:getPositionX()) and
			(posInCell.x < aBtnSprite:getPositionX()+spriteSize.width) and
			(posInCell.y > aBtnSprite:getPositionY()-spriteSize.height) and
			(posInCell.y < aBtnSprite:getPositionY())) then
			container:toSpritePanelTouched()
		end 

  	end
    print("setTouchEnabled")
    aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch2)
    aTableView:setDragEnabled(false)
    aTableView:setTouchEnabled(true)
	end
	aTableView:setPosition(ccp( Table_posX, Table_posY))
	return aTableView
end
