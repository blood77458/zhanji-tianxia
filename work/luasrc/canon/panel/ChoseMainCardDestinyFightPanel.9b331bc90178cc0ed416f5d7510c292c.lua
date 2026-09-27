ChoseMainCardDestinyFightPanel = class(Layer)

local destinyFightCardId = 0
function setDestinyFightCardId(choseId)
	--choseId = 0 表示全体出战
	--else 表示选择某一张卡牌出战
	destinyFightCardId = choseId
end

function getDestinyFightCardId()
	return destinyFightCardId
end


local COLS_NUM = 3
local TAG_CARD_PIC = 100
local TAG_CARD_NAME = 101
local TAG_NORMAL_CARD_SMALL = 102
local offsetX = -20
local offsetY = 15
function ChoseMainCardDestinyFightPanel:ctor()
    self.container = nil
	self.rewardInfo = {}
end

function ChoseMainCardDestinyFightPanel:create( container ,destinyData,callBackFunc)
    self.container = container
    self.callBackFunc = callBackFunc
	self.destinyData = destinyData
	self.cardParticle = nil
    local s = ChoseMainCardDestinyFightPanel.new()
    s:initLayer()
    return s
end

function ChoseMainCardDestinyFightPanel:createTableView(data,argv)
	local CardCellRenderer = class(TableViewRenderer)
	
	local function addParticle(cardCell)
		if self.cardParticle ~= nil then
			self.cardParticle:removeFromParentAndCleanup(true)
		end
		self.cardParticle = CCParticleSystemQuad:create(ParticlePathConstants.FxStarline)
		self.cardParticle:setPositionType(kCCPositionTypeRelative)
		self.cardParticle:setPosition(ccp(-20,20))
		cardCell:addChild(self.cardParticle, 1000)
		local particleMoveArray = CCArray:create()
		local particleMoveTime = 0.4
		particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(125, 0)))
		particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, -125)))
		particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(-125, 0)))
		particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, 125)))
		self.cardParticle:runAction(CCRepeatForever:create(CCSequence:create(particleMoveArray)))
    end
	
	function CardCellRenderer:ctor(width,height)
		local rows = #data%COLS_NUM
        if rows == 0 then
            rows = #data/COLS_NUM
        else
            rows = #data/COLS_NUM + 1
        end
        for i=1, rows do
            self.list[i] = i
        end
	end
	
	function CardCellRenderer:buildCell(container)
        for cols = 1,COLS_NUM do 
            local builder = LayoutBuilder:createWithContentsOfFile("scene/destiny_fight.json")
            local layer = builder:build("sb/common_reward_item") 
            layer:getChildByName("common_normal_card_small_sb"):setTag(TAG_NORMAL_CARD_SMALL)
			layer:getChildByName("common_txt_item_name"):setTag(TAG_CARD_NAME)
			layer:getChildByName("common_txt_item_name"):getChildByName("txt_item_name"):setTag(TAG_CARD_NAME)
            
            local layer_x = cols*(self.width/COLS_NUM)-(self.width/(COLS_NUM*2))
            layer:setPosition(ccp(layer_x,self.height*0.8)) 
            layer:setVisible(false)
            
            container:addChild(layer)
            layer:setTag(1000+cols)
        end
	end 
	
	function CardCellRenderer:setData(rawCocosObj,index)
	     
	    for x = 1,COLS_NUM do 
		    local cellLayer = self:getChildByTag(rawCocosObj, 1000+x)
		    local cardData = data[index*COLS_NUM + x]
			
			if x == 1 and index == 0 then
				addParticle(cellLayer)
			end
			
		    cellLayer:setVisible(false)
			
			local function setTextByTag(tag, str )
			    local txt = cellLayer:getChildByTag(tag):getChildByTag(tag)
			    if type(txt.setString) == "function" then
				    txt:setString(str)
			    end
		    end
	
		    local function setNodeVisibleByTag(tag, visible)
			    cellLayer:getChildByTag(tag):setVisible(visible)
		    end
			local pic_position_x,pic_position_y = cellLayer:getChildByTag(TAG_NORMAL_CARD_SMALL):getPosition()
		    local picZOrder = cellLayer:getChildByTag(TAG_NORMAL_CARD_SMALL):getZOrder()

            cellLayer:removeChildByTag(TAG_CARD_PIC,true)
		    
			if cardData then
				cellLayer:setVisible(true)
				--card
				cellLayer:getChildByTag(TAG_NORMAL_CARD_SMALL):setVisible(false)
				--print(table.tostring(cardData))
				local newMetaId = CommonManager:getSelfAvatarMetaByCardId( cardData.cardId )
				if newMetaId == 0 then
					newMetaId = cardData.metaId
				end
				local headCard = getBackpackHeadIconCanonCardByMetaId(newMetaId)--getHeadIconCanonCardByMetaId(cardData.metaId)
				local cardMeta = MetaManager.card_meta[cardData.metaId]
				headCard:setPosition(ccp(pic_position_x+offsetX,pic_position_y+offsetY))
				headCard:setTag(TAG_CARD_PIC)
				cellLayer:addChild(headCard.refCocosObj,picZOrder)
				headCard:dispose()
				
				setTextByTag( TAG_CARD_NAME, getTextByKey(cardMeta.name))
			end
		end
	end 
		
	local function inArea(posX, posY, rect)
		if posX >= rect.x and posX <= rect.x + rect.width and posY <= rect.y and posY >= rect.y + rect.height then
			return true
		end
		return false
	end
	
	local function onListItemTouch(evt)
		if self.targetInfoPanel then
			return
		end
		local selectedCardCell = self.tableUI:cellAtIndex(evt.data)
		local posInCell = selectedCardCell:convertToNodeSpace(evt.globalPosition)
		for cols =1 , COLS_NUM do
			
			local itemPosX, itemPosY = selectedCardCell:getChildByTag(1000+cols):getPosition()
			local itemRect = {}
			itemRect.x = itemPosX + offsetX
			itemRect.y = itemPosY + offsetY + 5
			itemRect.width = 120
			itemRect.height = -130
			print("itemPosX = " .. itemPosX .. ",itemPosY = " .. itemPosY .. ",posInCell.x = " .. posInCell.x .. ",posInCell.y = " .. posInCell.y)
			if inArea(posInCell.x, posInCell.y, itemRect) and self.queueData[evt.data*COLS_NUM + cols] then
				setDestinyFightCardId(self.queueData[evt.data*COLS_NUM + cols].cardId)
				addParticle(selectedCardCell:getChildByTag(1000+cols))
				break
			end
		end
	end
  
	local cell_height = 200
	local cell_width = 560
	local list_height = 180
	local list_posY = 1200
    local renderer = CardCellRenderer.new(cell_width, cell_height)
    local list = TableView:create(renderer, BAGCONFIG.WIDTH, list_height,nil,nil,
                                  CCScale9Sprite:create("pic/scroll.png"), 
                                  CCScale9Sprite:create("pic/scroll.png"),nil,-85)
	list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
    list:setPosition(ccp(40, (list_posY-list_height)/2))
	--
    return list
end

function ChoseMainCardDestinyFightPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	
    ChoseMainCardDestinyFightPanel.super.initLayer(self)
	
	local cardData = DataManager.getCardsData()
	local tQueueData = CommonManager.getQueueData()
	self.queueData = {}
	for k,v in pairs(tQueueData) do
		if k < 100 then
			for i,data in pairs(cardData) do 
				if data.cardId == v then
					table.insert(self.queueData,{cardId = v,metaId = data.metaId})
					break
				end
			end
		end
	end
	local builder = LayoutBuilder:createWithContentsOfFile("scene/destiny_fight.json")
    self.panelUI = builder:build("popup_selectmain")
    
	self.panelUI:getChildByName("txt_selectmain_title"):getChildByName("txt"):setString(getTextByKey("destinyBattle_cardSelect"))
    self.panelUI:getChildByName("txt_selectmain_info"):getChildByName("txt"):setString(getTextByKey("destinyBattle_duelConfirm"))
	self.panelUI:getChildByName("btn_cha"):getChildByName("txt"):setString(getTextByKey("destinyBattle_challengeBtn"))
	
	self.panelUI:getChildByName("common_reward_item"):setVisible(false)
	
    local function onClosePanel(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
        self.container:setTableViewsEnabled(true)
        self.container.targetInfoPanel = nil
        if self.callBackFunc and type(self.callBackFunc) == "function" then
            self:callBackFunc()
        end 
    end 
	
	local function onChallenge(evt)
		challengeDestinyFight(self.destinyData)
    end 
	
	local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
	closeButton:addEventListener( Events.kStart, onClosePanel, self ) 
	
	local challengeButton = Button:create(self.panelUI:getChildByName("btn_cha"))
	challengeButton:addEventListener( Events.kStart, onChallenge, self )
	
	self:addChild(self.panelUI) 
	self.tableUI = self:createTableView(self.queueData) 
	self:addChildAt(self.tableUI, 6)
end