--
-- QuestionActivityRewardPanel
--

QuestionActivityRewardPanel = class(Layer)

local COLS_NUM = 3
local TAG_PIC_REWARD = 100
local TAG_REWARD_NAME = 101
local TAG_REWARD_NUM = 102
local TAG_NORMAL_CARD_SMALL = 103
local TAG_PIC_REWARD_BG = 104	    
local TAG_FRAME_CARD = 105

function QuestionActivityRewardPanel:ctor()
    self.container = nil
end

-- winType : 1.日奖励  2.周奖励
function QuestionActivityRewardPanel:create(father,winType,rewards,textNum,callBackFunc)
    local s = QuestionActivityRewardPanel.new()
    s.father = father
    s.winType = winType
    s.rewards = rewards
    s.textNum = textNum
    s.callBackFunc = callBackFunc
    s:initLayer(father.container)
    return s
end

function QuestionActivityRewardPanel:initLayer(container)
    QuestionActivityRewardPanel.super.initLayer(self)
    local visibleSize = CCDirector:sharedDirector():getVisibleSize()

    self.container = container
    self.container:setTableViewsEnabled(false)
    self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/question_activity.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_question_activity_02")
    self.tempLayer:setScale(0.1)
    self.tempLayer:addChild(self.panelUI)
    
    local titleStr = nil
    local textStr = nil
    if self.winType == 1 then
    	titleStr = getTextByKey("activity_question_title")
    	textStr_1 = getTextByKey("activity_question_congratulateDay")

    elseif self.winType == 2 then
    	titleStr = getTextByKey("activity_question_weekReward")
    	textStr_1 = getTextByKey("activity_question_congratulateWeek")
    end
	self.panelUI:getChildByName("common_txt_playerInfo_title"):getChildByName("txt_playerInfo_title"):setString(titleStr)
	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(textStr_1)
	self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("activity_question_answerNum"))
	self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(self.textNum)
	self.panelUI:getChildByName("reward_item"):setVisible(false)

    local function closeAction(evt)
    	self.container:setTableViewsEnabled(true)
      	self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("login_btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)

    local sureButton = Button:create(self.panelUI:getChildByName("btn_getcdreward_inactive"))
    sureButton.display:getChildByName("txt"):setString(getTextByKey("yes"))
    sureButton:addEventListener(Events.kStart, closeAction, self)

end
function QuestionActivityRewardPanel:scaleIn()
    self.tempLayer.touchEnabled = false
    self.tempLayer.touchChildren = false
    local function scaleInFinished()
        self.tempLayer.touchEnabled = true
        self.tempLayer.touchChildren = true

        -- createTableView
		local mergeRewardInfo = {}
		for k,v in pairs(self.rewards) do 
		    local hasSameReward = false
		    for ck,cv in pairs(mergeRewardInfo) do 
		        if v.itemType == cv.itemType then
		            if cv.itemType == 1 or  cv.itemType == 2 or cv.itemType == 8 then
		                hasSameReward = true
		                cv.amount = cv.amount + v.amount
		                break
		            elseif cv.itemType == 5 or  cv.itemType == 6 or cv.itemType == 7 then
		                if v.metaId == cv.metaId then
		                    hasSameReward = true
		                    cv.amount = cv.amount + v.amount
		                    break
		                end
		            end
		        end 
		    end 
		    if not hasSameReward then
		        table.insert(mergeRewardInfo,v)
		    end 
		end
        self.tableUI = self:createTableView(mergeRewardInfo) 
		self:addChildAt(self.tableUI, 6)
    end
    local arr = CCArray:create()
    arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
    arr:addObject(CCCallFunc:create(scaleInFinished))
    self.tempLayer:runAction(CCSequence:create(arr))
end

function QuestionActivityRewardPanel:dismiss()
    self.container.targetInfoPanel = nil
    if self.callBackFunc and type(self.callBackFunc) == "function" then
        self:callBackFunc()
    end
    self.container:setTableViewsEnabled(true)
    self:removeFromParentAndCleanup(true)
end

function QuestionActivityRewardPanel:createTableView(data,argv)
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
            local builder = LayoutBuilder:createWithContentsOfFile("scene/question_activity.json")
            local layer = builder:build("reward_item") 
            layer:getChildByName("normal_card_small"):setTag(TAG_NORMAL_CARD_SMALL)
            layer:getChildByName("bg_card"):setTag(TAG_PIC_REWARD_BG)
            layer:getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
            layer:getChildByName("txt_item_quantity"):setTag(TAG_REWARD_NUM)
            layer:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
            layer:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setColor(ccc3(255,255,255))
            layer:getChildByName("txt_item_quantity"):getChildByName("txt_item_quantity"):setTag(TAG_REWARD_NUM)
            layer:getChildByName("txt_item_quantity"):getChildByName("txt_item_quantity"):setColor(ccc3(255,255,255))
            layer:getChildByName("frame_card"):setTag(TAG_FRAME_CARD)
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
                end	
			    setTextByTag(TAG_REWARD_NAME, rewardName )
			    setTextByTag(TAG_REWARD_NUM, rewardNum )     		
			end
		end
	end 
		
	local cell_height = 200
	local cell_width = 560
	local list_height = 320
	local list_posY = 1400
    local renderer = RewardCellRenderer.new(cell_width, cell_height)
    local list = TableView:create(renderer, BAGCONFIG.WIDTH, list_height,nil,nil,
                                  CCScale9Sprite:create("pic/scroll.png"), 
                                  CCScale9Sprite:create("pic/scroll.png"),nil,-25)
    list:setPosition(ccp(-20, 560))
	--
    return list
end