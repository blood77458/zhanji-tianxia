
--[[
Tags:
Basic -100
-1~-5 技能装备窗格
]]

local Table_width = 720 --700
local Table_height = 664.75
local Table_posX = -6
local Table_posY = -16
local Item_width = 720
local Item_height = 0

local card_scale = 704/640
local item_scale = 108/144

local SKILL_TYPE_NORMAL = 1
local SKILL_TYPE_MAIN = 2


QueueSpiritPanel = class(Layer)

QueueSpiritPanel.ListTags = {
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
}

local empty_png = {
	UI_RES_PATH.."/formation_new/icon_elesoul_empty.png",
	"Item/Picture/formation_lock.png",
}

local empty_hint_text = {
	getTextByKey("formation_addSpirit"),
	getTextByKey("spirit_locked"),
	getTextByKey("formation_addMount")
}

local function itemFigureBuilder( source, targetId, noText )
	local aFigure = nil
	if (targetId > 0) then
		aFigure = CanonItem:create()
		aFigure:loadByMetaId(targetId)
	else
		aFigure = Sprite:create(UI_RES_PATH.."/formation_new/formation_normal_card_small_sb.png")
		if (targetId == 0) then
			local aBgSpt = Sprite:create(empty_png[2])
			aBgSpt:setAnchorPoint(ccp(0,0))
			aBgSpt:setScale(108/134)
			aFigure:addChild(aBgSpt)
			local aText = ViewControlUtil.buildArtLabel( nil, empty_hint_text[2] )
			aText:setPosition(ccp(54,54))
			aFigure:addChild(aText)
		else
			local aBgSpt = Sprite:create(empty_png[1])
			aBgSpt:setAnchorPoint(ccp(0,0))
			aBgSpt:setScale(108/134)
			aFigure:addChild(aBgSpt)
			if (not noText) then
				local aText = ViewControlUtil.buildArtLabel( nil, empty_hint_text[1] )
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

function QueueSpiritPanel:ctor()
	self.container = nil
end

function QueueSpiritPanel:create(container, params)
	self.container = container
	local panel = QueueSpiritPanel.new()
	panel:initLayer()
	return panel
end

function QueueSpiritPanel:initLayer()
	QueueSpiritPanel.super.initLayer(self)
	
	-- 渲染 TableView
	self.tableUI = self:createCardQueueTableView()
	self:addChild(self.tableUI)
	-- self.tableUI:reloadData()
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
function QueueSpiritPanel:createCardQueueTableView()
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
		local aCell = builder:build("formation_mainframe_entry2")
		-- aCell:setPosition(ccp(aCell:getPositionX() , aCell:getPositionY() - Table_height))
		container:addChild(aCell)
		
		aCell:setTag(QueueSpiritPanel.ListTags.CELL)
		aCell:getChildByName("full"):setTag(QueueSpiritPanel.ListTags.CARD_FRAME)
		
		for i=1, 6 do
			aCell:getChildByName("equip_test_"..i):setTag(QueueSpiritPanel.ListTags.ICON_BASE-i)
		end

		--标记Item名称
		for i=1, 6 do
			aCell:getChildByName("item_name"..i):setTag(QueueSpiritPanel.ListTags.NAMES_BASE+i)
			aCell:getChildByName("item_name"..i):getChildByName("txt_item_name"):setTag(QueueSpiritPanel.ListTags.NAMES_TITLE)
			aCell:getChildByName("item_name"..i):getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(QueueSpiritPanel.ListTags.NAMES_TITLE_TEXT)
			aCell:getChildByName("item_name"..i):getChildByName("bg_item_name"):setTag(QueueSpiritPanel.ListTags.NAMES_BG)
		end
		
		for i=1,9 do
			aCell:getChildByName("little_grey_dot"..i):setTag(QueueSpiritPanel.ListTags.SKILL_DOT_BASE-i)
			aCell:getChildByName("txt_skillcombine_name"..i):setTag(QueueSpiritPanel.ListTags.SKILL_NAME_BASE-i)
			aCell:getChildByName("txt_skillcombine_name"..i):getChildByName("txt"):setTag(QueueSpiritPanel.ListTags.SKILL_NAME_TEXT)
		end

		aCell:getChildByName("gray9_panel"):setTag(QueueSpiritPanel.ListTags.SKILLAREA)
		
		aCell:getChildByName("txt_formation_skill_tips"):setTag(QueueSpiritPanel.ListTags.SKILLTIP)
		aCell:getChildByName("txt_formation_skill_tips"):getChildByName("txt_formation_skill_tips"):setTag(QueueSpiritPanel.ListTags.SKILLTIP_TEXT)
		
		--左下方锁定的位置
		-- local icon_lock = Sprite:create(UI_RES_PATH.."/formation_new/formation_icon_lock_sb.png")
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

		aCell:getChildByName("txt_lv"):setTag(QueueSpiritPanel.ListTags.TAG_TXT_LV)
		aCell:getChildByName("txt_lv"):getChildByName("txt"):setTag(QueueSpiritPanel.ListTags.TAG_TXT_LV)
		aCell:getChildByName("txt_atk_num"):setTag(QueueSpiritPanel.ListTags.TAG_TXT_ATKNUM)
		aCell:getChildByName("txt_atk_num"):getChildByName("font"):setTag(QueueSpiritPanel.ListTags.TAG_TXT_ATKNUM)
		aCell:getChildByName("txt_def_num"):setTag(QueueSpiritPanel.ListTags.TAG_TXT_DEFNUM)
		aCell:getChildByName("txt_def_num"):getChildByName("font"):setTag(QueueSpiritPanel.ListTags.TAG_TXT_DEFNUM)
		aCell:getChildByName("txt_hp_num"):setTag(QueueSpiritPanel.ListTags.TAG_TXT_HPNUM)
		aCell:getChildByName("txt_hp_num"):getChildByName("font"):setTag(QueueSpiritPanel.ListTags.TAG_TXT_HPNUM)
		aCell:getChildByName("icon_elesoul"):setTag(QueueSpiritPanel.ListTags.TAG_BUTTON_SPRITE)

		aCell:getChildByName("formation_icon_lv_sb"):setTag(QueueSpiritPanel.ListTags.TAG_ICON_LV)
		aCell:getChildByName("icon_atk"):setTag(QueueSpiritPanel.ListTags.TAG_ICON_ATK)
		aCell:getChildByName("icon_def"):setTag(QueueSpiritPanel.ListTags.TAG_ICON_DEF)
		aCell:getChildByName("icon_hp"):setTag(QueueSpiritPanel.ListTags.TAG_ICON_HP)

	end
	
	function CardQueueListTableViewRenderer:setData( rawCocosObj, index )
		local aCardNo = index + 1
		
		local aCell = self:getChildByTag(rawCocosObj, QueueSpiritPanel.ListTags.CELL)
		local childs = {}
		
		childs[0] = aCell:getChildByTag(QueueSpiritPanel.ListTags.CARD_FRAME)
		childs[0]:setVisible(false)
			
		for i=1,6,1 do
			childs[i] = aCell:getChildByTag(QueueSpiritPanel.ListTags.ICON_BASE-i)
			childs[i]:setVisible(false)
		end
		
		for i=1,9 do
			aCell:getChildByTag(QueueSpiritPanel.ListTags.SKILL_DOT_BASE-i):setVisible(false)
			aCell:getChildByTag(QueueSpiritPanel.ListTags.SKILL_NAME_BASE-i):setVisible(false)
		end
		
		local card_frame = CocosObject.new(childs[0])
		local frame_position = card_frame:getPosition()
		card_frame:removeFromParentAndCleanup(true)
		local cardDisplay = nil
		
		local aCard = container.queue[aCardNo]

		if aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_CARDNAME) then
			aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_CARDNAME):removeFromParentAndCleanup(true)
		end
		if aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_KING) then
			aCell:getChildByTag(QueueCardPanel.ListTags.TAG_ICON_KING):removeFromParentAndCleanup(true)
		end

		aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_ICON_LV):setVisible(false)
		aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_ICON_ATK):setVisible(false)
		aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_ICON_DEF):setVisible(false)
		aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_ICON_HP):setVisible(false)

		aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_LV):setVisible(false)
		aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_ATKNUM):setVisible(false)
		aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_DEFNUM):setVisible(false)
		aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_HPNUM):setVisible(false)
		
		if (aCard) then
			aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_ICON_LV):setVisible(true)
			aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_ICON_ATK):setVisible(true)
			aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_ICON_DEF):setVisible(true)
			aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_ICON_HP):setVisible(true)

			aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_LV):setVisible(true)
			aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_ATKNUM):setVisible(true)
			aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_DEFNUM):setVisible(true)
			aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_HPNUM):setVisible(true)
			
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

			local rare = MetaManager.card_meta[container.queue[aCardNo].metaId].rare
			local spriteNum = MetaManager.card_rare[rare].spiritNum + MetaManager.card_level[cardStatus.level].spiritNum
			for k,v in pairs(aCard.spirits) do
				local spiritFigure = itemFigureBuilder(childs[k], v.metaId)
		        local item_lv_bg = Sprite:createWithSpriteFrameName("item_lv_bg.png")
		        item_lv_bg:setPosition(ccp(23, 49))
		        card_lv = TextField:create("lv" .. v.level,"Arial", 20)
		        card_lv:setPosition(ccp(42, 10))
		        item_lv_bg:addChild(card_lv)
		        spiritFigure:addChild(item_lv_bg)
		        if k > spriteNum then
		        	local lock_bg = Sprite:create(UI_RES_PATH.."/formation_new/icon_ele_lock.png")
		        	lock_bg:setScale(148/134)
		        	spiritFigure:addChild(lock_bg)
		        end
				aCell:addChild(spiritFigure.refCocosObj)
				childs[k]:removeFromParentAndCleanup(true)
				childs[k] = spiritFigure.refCocosObj
				childs[k]:setScale(item_scale)
				spiritFigure:dispose()
				local skillNameLabel = aCell:getChildByTag(QueueSpiritPanel.ListTags.NAMES_BASE + k):getChildByTag(QueueSpiritPanel.ListTags.NAMES_TITLE):getChildByTag(QueueSpiritPanel.ListTags.NAMES_TITLE_TEXT)
				--skillNameLabel = tolua.cast(skillNameLabel, "CCLabelTTF")
				setNodeText(skillNameLabel,getTextByKey(MetaManager.spirit_meta[v.metaId]["nameKey"]))
				aCell:getChildByTag(QueueSpiritPanel.ListTags.NAMES_BASE+k):setZOrder(2001)
			end

			for i=1,spriteNum do
				if (not childs[i]:isVisible()) then
					local itemFigure = itemFigureBuilder(childs[i], -1)
					childs[i]:removeFromParentAndCleanup(true)
					childs[i] = itemFigure.refCocosObj
					aCell:addChild(itemFigure.refCocosObj)
					itemFigure:dispose()
					aCell:getChildByTag(QueueSpiritPanel.ListTags.NAMES_BASE+i):setZOrder(0)
				-- else
				-- 	childs[i]:setScale(item_scale)
				end
				childs[i]:setTag(QueueSpiritPanel.ListTags.ICON_BASE-i)
			end

			
			local bmpName = BitmapText:create(getTextByKey(getTextByKey(MetaManager.card_meta[container.queue[aCardNo].metaId].name)), "common/card_name.fnt", 0, kCCTextAlignmentLeft)
	        bmpName:setScale(1)
	        local positionY = aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_ICON_LV):getPositionY()
	        bmpName:setPosition(ccp( 662.7 / 2, positionY ))
	        bmpName:setZOrder(1002)
	        bmpName:setTag(QueueSpiritPanel.ListTags.TAG_TXT_CARDNAME)
	        aCell:addChild(bmpName.refCocosObj)
	        setNodeText(aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_ATKNUM):getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_ATKNUM) , tostring(cardStatus.att))
	        setNodeText(aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_DEFNUM):getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_DEFNUM) , tostring(cardStatus.def))
	        setNodeText(aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_HPNUM):getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_HPNUM) , tostring(cardStatus.hp))
	        setNodeText(aCell:getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_LV):getChildByTag(QueueSpiritPanel.ListTags.TAG_TXT_LV) , tostring(cardStatus.level))

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

	        -- local gameInitData = DataManager.getGameInitData()
			local no = 1
			for i=1,#aCard.cardSkills do
				local aSkill = aCard.cardSkills[i]
				if (aSkill and aSkill.skillType==3 or aSkill.skillType==4) then
					aCell:getChildByTag(QueueSpiritPanel.ListTags.SKILL_DOT_BASE-no):setVisible(true)
					aCell:getChildByTag(QueueSpiritPanel.ListTags.SKILL_NAME_BASE-no):setVisible(true)
					local aTextNode = aCell:getChildByTag(QueueSpiritPanel.ListTags.SKILL_NAME_BASE-no):getChildByTag(QueueSpiritPanel.ListTags.SKILL_NAME_TEXT)
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
					aCell:getChildByTag(QueueSpiritPanel.ListTags.SKILL_DOT_BASE-no):setVisible(true)
					aCell:getChildByTag(QueueSpiritPanel.ListTags.SKILL_NAME_BASE-no):setVisible(true)
					local aEquipMeta = CommonManager.getSubTableByKey(
						MetaManager.equip_meta,
						{name = "prefixId", value=aSkill.equipPrefixId }
					)
					local aEquipName = MetaManager.equip_meta[aEquipMeta.id - aEquipMeta.evolveLevel + 1]["name"]
					local aTextNode = aCell:getChildByTag(QueueSpiritPanel.ListTags.SKILL_NAME_BASE-no):getChildByTag(QueueSpiritPanel.ListTags.SKILL_NAME_TEXT)
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
		cardDisplay:setTag(QueueSpiritPanel.ListTags.CARD_FRAME)
		cardDisplay:setScale(card_scale)
		-- cardDisplay:setZOrder(-1001)
		aCell:addChild(cardDisplay.refCocosObj)
		childs[0]:removeFromParentAndCleanup(true)
		card_frame:dispose()
		cardDisplay:dispose()

		for i=1,6 do
			if (not childs[i]:isVisible()) then
				local itemFigure = itemFigureBuilder(childs[i], 0, container.playerTeamData ~= nil)
				childs[i]:removeFromParentAndCleanup(true)
				childs[i] = itemFigure.refCocosObj
				aCell:addChild(itemFigure.refCocosObj)
				itemFigure:dispose()
				aCell:getChildByTag(QueueSpiritPanel.ListTags.NAMES_BASE+i):setZOrder(0)
			-- else
			-- 	childs[i]:setScale(item_scale)
			end
			childs[i]:setTag(QueueSpiritPanel.ListTags.ICON_BASE-i)
		end

		for i=1,6,1 do
			childs[i]:setZOrder(1001)
		end
		
		local skillTipLabel = aCell:getChildByTag(QueueSpiritPanel.ListTags.SKILLTIP):getChildByTag(QueueSpiritPanel.ListTags.SKILLTIP_TEXT)
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
		
		local childs = aCell:getChildByTag(QueueSpiritPanel.ListTags.CELL)
		local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
		
		local cardFrame = childs:getChildByTag(QueueSpiritPanel.ListTags.CARD_FRAME)
		local skillArea = childs:getChildByTag(QueueSpiritPanel.ListTags.SKILLAREA)
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
				local aBtnArea = childs:getChildByTag(QueueSpiritPanel.ListTags.ICON_BASE-i)
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

			local aBtnSprite = childs:getChildByTag(QueueSpiritPanel.ListTags.TAG_BUTTON_SPRITE)
			if ((posInCell.x > aBtnSprite:getPositionX()) and
				(posInCell.x < aBtnSprite:getPositionX()+spriteSize.width) and
				(posInCell.y > aBtnSprite:getPositionY()-spriteSize.height) and
				(posInCell.y < aBtnSprite:getPositionY())) then
				return 8
			end 
			
			if ( ViewControlUtil.isInArea(posInCell, skillArea) ) then
				return 0
			end
			return -1
		end

		local itemIndex = getTouchedItemIndex()
		if (itemIndex==0) then
			container:cardFrameTouched(aIndex+1)
		elseif(itemIndex == 8 ) then
			container:toCardPanelTouched()
		elseif(itemIndex ~= -1) then
			container:spriteBtnTouched(aIndex+1 , itemIndex)
		else
			print("Hint: Unknown area touched")
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
    container.cardPanel.tableUI:setContentOffset(ccp(-scrollTo*(Item_width), 0))

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
		
		local childs = aCell:getChildByTag(QueueSpiritPanel.ListTags.CELL)
		local posInCell = aCell:convertToNodeSpace(evt.globalPosition)

		local spriteSize ={
		height = 83,
		width = 87,
	}
		local aBtnSprite = childs:getChildByTag(QueueSpiritPanel.ListTags.TAG_BUTTON_SPRITE)
		if ((posInCell.x > aBtnSprite:getPositionX()) and
			(posInCell.x < aBtnSprite:getPositionX()+spriteSize.width) and
			(posInCell.y > aBtnSprite:getPositionY()-spriteSize.height) and
			(posInCell.y < aBtnSprite:getPositionY())) then
			container:toCardPanelTouched()
		end 

  	end
    aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch2)
    aTableView:setDragEnabled(false)
    aTableView:setTouchEnabled(true)
	end
	aTableView:setPosition(ccp( Table_posX, Table_posY))
	return aTableView
end
