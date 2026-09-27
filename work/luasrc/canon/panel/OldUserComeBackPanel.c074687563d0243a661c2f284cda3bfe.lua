--------------------------------------------------------------------------------
-- OldUserComeBackPanel.lua --显示获得的奖励
-- author: dang chao
-- updated: 2015-01-12
--------------------------------------------------------------------------------


OldUserComeBackPanel = class(Layer)

local COLS_NUM = 3
local TAG_PIC_REWARD = 100
local TAG_REWARD_NAME = 101
local TAG_REWARD_NUM = 102
local TAG_NORMAL_CARD_SMALL = 103
local TAG_PIC_REWARD_BG = 104	    
local TAG_FRAME_CARD = 105
local TAG_TXT_LEVEL = 106
local TAG_LEVEL_BG = 107
function OldUserComeBackPanel:ctor()
    self.container = nil
	self.rewardInfo = {}
end

function OldUserComeBackPanel:shouldPop()
	return  getAccountReturnRewards() 
end

function OldUserComeBackPanel:create( container ,callBackFunc, params)
    self.container = container
    self.callBackFunc = callBackFunc
	self.params = params
	if not self.params then
		self.params = {}
	end

    local s = OldUserComeBackPanel.new()
    s:initLayer()
    return s
end

function OldUserComeBackPanel:createTableView(data)
local aRewardInfoPanel = self
	local RewardCellRenderer = class(TableViewRenderer)
	function RewardCellRenderer:ctor(width,height)
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
	
	function RewardCellRenderer:buildCell(container)
        for cols = 1,COLS_NUM do 
            local builder = LayoutBuilder:createWithContentsOfFile("scene/reward_new.json")
            local layer = builder:build("reward_item") 
            layer:getChildByName("normal_card_small"):setTag(TAG_NORMAL_CARD_SMALL)
            layer:getChildByName("bg_card"):setTag(TAG_PIC_REWARD_BG)
            layer:getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
            layer:getChildByName("txt_item_quantity"):setTag(TAG_REWARD_NUM)
            layer:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
            layer:getChildByName("txt_item_quantity"):getChildByName("txt_item_quantity"):setTag(TAG_REWARD_NUM)
            layer:getChildByName("frame_card"):setTag(TAG_FRAME_CARD)
            layer:getChildByName("txt_level"):setTag(TAG_TXT_LEVEL)
            layer:getChildByName("txt_level"):getChildByName("txt"):setTag(100)
            layer:getChildByName("bg_small_number"):setTag(TAG_LEVEL_BG)
            local layer_x = cols*(self.width/COLS_NUM)-(self.width/(COLS_NUM*2))
            layer:setPosition(ccp(layer_x,self.height*0.9)) 
            layer:setVisible(false)
            layer:getChildByName("normal_card_small"):setVisible(false)
            container:addChild(layer)
            layer:setTag(1000+cols)
        end
	end 
	
	function RewardCellRenderer:setData(rawCocosObj,index)
	    
	    for x = 1,COLS_NUM do 
		    local cellLayer = self:getChildByTag(rawCocosObj, 1000+x)
		    
		    cellLayer:setVisible(false)
			local reward_id = index*COLS_NUM + x
			if reward_id <= #data then
			    --
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
		        local picZOrder = cellLayer:getChildByTag(TAG_PIC_REWARD_BG):getZOrder()
			    cellLayer:setVisible(true)
                cellLayer:removeChildByTag(TAG_PIC_REWARD,true)
		        
			    local rewardInfo = data[reward_id]
			    local rewardNum = "x"..rewardInfo.amount
			    local rewardName = rewardInfo.itemType..":"..rewardInfo.metaId
			    if rewardInfo.itemType == 1 then
			    --coin
			        cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(true)
			        local coinIcon = CCSprite:create("common/CoinIcon.png")
			        coinIcon:setTag(TAG_PIC_REWARD)
			        coinIcon:setPosition(ccp(pic_position_x,pic_position_y))
			        cellLayer:addChild(coinIcon,picZOrder)
			        rewardName = getTextByKey("resource_silverCoin")
                elseif rewardInfo.itemType == 2 then	
                --gem
                    cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(true)
                    local gemIcon = CCSprite:create("common/GemIcon.png")
			        gemIcon:setTag(TAG_PIC_REWARD)
			        gemIcon:setPosition(ccp(pic_position_x,pic_position_y))
			        cellLayer:addChild(gemIcon,picZOrder)
                    rewardName = getTextByKey("resource_goldCoin")
                elseif rewardInfo.itemType == 3 then
                --energy
                elseif rewardInfo.itemType == 4 then
                --exp
                elseif rewardInfo.itemType == 5 then
                --card
                    cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(false)
			        local headCard = getHeadIconCanonCardByMetaId(rewardInfo.metaId)
			        headCard:setPosition(ccp(pic_position_x,pic_position_y))
				    headCard:setTag(TAG_PIC_REWARD)
			        cellLayer:addChild(headCard.refCocosObj,picZOrder)
				    headCard:dispose()
				
                    local cardMeta = MetaManager.card_meta[rewardInfo.metaId]
			    
			        if cardMeta == nil then
			            rewardName = "Card"..rewardInfo.metaId
			        else
			            rewardName = getTextByKey(cardMeta.name)
			        end 
				
                elseif rewardInfo.itemType == 6 then
                --equip
                    cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(false)
                    local canonItem = CanonItem:create()
				    local itemMeta = MetaManager.equip_meta[rewardInfo.metaId]
                    canonItem:loadByMetaId(rewardInfo.metaId)
                    canonItem:setScale(0.9)
				    canonItem:setPosition(ccp(pic_position_x,pic_position_y))
				    canonItem:setTag(TAG_PIC_REWARD)
				    cellLayer:addChild(canonItem.refCocosObj, picZOrder)
				    canonItem:dispose()
				    
				    if itemMeta == nil then
			            rewardName = "Equip"..rewardInfo.metaId
			        else
			            rewardName = getTextByKey(itemMeta.name)
			        end 
                elseif rewardInfo.itemType == 7 then
                --prop
                    cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(false)
                    local canonItem = CanonItem:create()
				    local itemMeta = MetaManager.prop_meta[rewardInfo.metaId]
                    canonItem:loadByMetaId(rewardInfo.metaId)
                    canonItem:setScale(0.9)
				    canonItem:setPosition(ccp(pic_position_x,pic_position_y))
				    canonItem:setTag(TAG_PIC_REWARD)
				    cellLayer:addChild(canonItem.refCocosObj, picZOrder)
				    canonItem:dispose()
				    
				    if itemMeta == nil then
			            rewardName = "Prop"..rewardInfo.metaId
			        else
			            rewardName = getTextByKey(itemMeta.name)
			        end 
                elseif rewardInfo.itemType == 8 then
                --friendpoint
                    cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(true)
                    local friendpointIcon = CCSprite:create("common/FriendpointIcon.png")
			        friendpointIcon:setTag(TAG_PIC_REWARD)
			        friendpointIcon:setPosition(ccp(pic_position_x,pic_position_y))
			        cellLayer:addChild(friendpointIcon,picZOrder)
                    rewardName = getTextByKey("resource_friendshipPoint")
                elseif rewardInfo.itemType == 9 then
                --grid
                elseif rewardInfo.itemType == 10 then
                --skillpoint
                elseif rewardInfo.itemType == 11 then
                --eventpoint
                elseif rewardInfo.itemType == 12 then
                --arenascore
                elseif rewardInfo.itemType == 14 then
                --monster fragment 
                    cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(false)
                    local canonItem = CanonItem:create()
                    local fragmentSprite = Sprite:create("#" .. MetaManager.beast_fragment[rewardInfo.metaId].icon .. ".png")
                    fragmentSprite:setScale(130 / fragmentSprite:getContentSize().width)
                    canonItem:addChild(fragmentSprite)
                    canonItem:setScale(0.9)		
                    canonItem:setPosition(ccp(pic_position_x,pic_position_y))
				    canonItem:setTag(TAG_PIC_REWARD)
				    cellLayer:addChild(canonItem.refCocosObj, picZOrder)
				    canonItem:dispose()
				    rewardName = BeastScene.getBeastFragmentNameByData(rewardInfo)
				elseif rewardInfo.itemType == ResourceEnum.GACHA_POINT then
					cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(true)
			        local gachaPointsIcon = CCSprite:createWithSpriteFrameName("Prop_chaojijingyanqiu0.png")
			        gachaPointsIcon:setTag(TAG_PIC_REWARD)
			        gachaPointsIcon:setPosition(ccp(pic_position_x,pic_position_y))
			        cellLayer:addChild(gachaPointsIcon,picZOrder)
			        rewardName = getTextByKey("resource_gachaPoints")
			    else
			    	cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(false)
			    	local icon = CanonGoodIcon.createGoodIcon(rewardInfo.itemType , rewardInfo.metaId , 0 , {sourceSizes = {134, 134}})
			    	icon:setTag(TAG_PIC_REWARD)
			    	icon:setPosition(ccp(pic_position_x,pic_position_y))
			    	cellLayer:addChild(icon.refCocosObj,picZOrder)
			    	local params = {withoutAmount = true}
			    	rewardName = CanonGoodIcon.getGoodName(rewardInfo.itemType , rewardInfo.metaId , rewardInfo.amount , params)
		  --       elseif goodType == ResourceEnum.EQUIP_FRAGMENT then
				-- 	local equipMetaId = MetaManager.equip_fragment_meta[metaId].equipId
				-- 	icon = CanonItem:create()
				-- 	icon:loadByMetaId(equipMetaId)
				-- 	local aSmallIcon = Sprite:createWithSpriteFrameName("Prop_soul_item.png")
				-- 	aSmallIcon:setPosition( ccp(45, 42) )
				-- 	icon:addChild(aSmallIcon)
				-- elseif goodType == ResourceEnum.RP_VALUE then
				-- 	icon = CanonItem:create()
				-- 	image = Sprite:create("common/icon_luck.png")
				-- 	border = Sprite:create("Item/border/equipBorder7.png")
				-- 	icon:addChild(image)
				-- 	icon:addChild(border)
                end	
			    setTextByTag(TAG_REWARD_NAME, rewardName )
			    setTextByTag(TAG_REWARD_NUM, rewardNum )   
			    if (rewardInfo.itemType == 5) and aRewardInfoPanel.params.showCardLevel then
			    	cellLayer:getChildByTag(TAG_TXT_LEVEL):setVisible(true)
			    	cellLayer:getChildByTag(TAG_LEVEL_BG):setVisible(true)
			    	setNodeText(cellLayer:getChildByTag(TAG_TXT_LEVEL):getChildByTag(100), "Lv." .. rewardInfo.level)
			    else
			    	cellLayer:getChildByTag(TAG_TXT_LEVEL):setVisible(false)
			    	cellLayer:getChildByTag(TAG_LEVEL_BG):setVisible(false)
			    end
			end--
		end
	end 
		
	local cell_height = 190
	local cell_width = 540
	local list_height = 250
	local list_posY = 400
    local renderer = RewardCellRenderer.new(cell_width, cell_height)
    local list = TableView:create(renderer, BAGCONFIG.WIDTH, list_height,nil,nil,
                                  CCScale9Sprite:create("pic/scroll.png"), 
                                  CCScale9Sprite:create("pic/scroll.png"),nil,-70)
    list:setPosition(ccp(10, list_posY))
	--
    return list
end

function OldUserComeBackPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	
    OldUserComeBackPanel.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
    self.panelUI = builder:build("common_popup_comeBackMaster")
    self:addChild(self.panelUI) 
    
    local function GainRewardBtnClick(evt)
		resetAccountReturnRewards()
		
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
        self.container:setTableViewsEnabled(true)
        self.container.targetInfoPanel = nil
        		
		if self.callBackFunc and type(self.callBackFunc) == "function" then
			self:callBackFunc()
		end
    end 
	
	self.panelUI:getChildByName("common_btn_goarena"):getChildByName("txt"):setString(getTextByKey("regressionGirl_UI"))
    local gainRewardBtn = Button:create(self.panelUI:getChildByName("common_btn_goarena"))
    gainRewardBtn:addEventListener(Events.kStart, GainRewardBtnClick)
				
    --init UI
	
	local bgCardPic = self.panelUI:getChildByName("full")
	bgCardPic:setVisible(false)
	self.bgCard = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(103004))--103004 -- 小乔3
	self.bgCard:setPosition(ccp(bgCardPic:getPositionX() + bgCardPic:getContentSize().width / 2.0 +70, bgCardPic:getPositionY() - bgCardPic:getContentSize().height / 2.0 -50 ))
	self.panelUI:addChildAt(self.bgCard,-1)
		
	self.tableUI = self:createTableView(getAccountReturnRewards()) 
	self:addChildAt(self.tableUI, 6)
end