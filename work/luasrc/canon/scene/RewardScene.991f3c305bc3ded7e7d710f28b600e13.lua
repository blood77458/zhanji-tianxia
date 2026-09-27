require "canon.request.RewardRequest"
require "canon.panel.GetRewardInfoPanel"
require "canon.manager.BagCalcManager"

RewardScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function RewardScene:ctor()
	self.title = getTextByKey("reward_title")
	self.tableUI = nil
	self.mainUI = nil
	self.targetInfoPanel = nil
	
	self.rewardListData = {}
	self.getNoCardReward = false
	self.getNoEquipReward = false
	
	self.rewardTipsLabel = nil
end
local reward_position = {}
local curPropsInfo = {}
local user_select = { tab=nil,row=nil,col=nil }

function RewardScene:create(argv)
    if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end
    local scene = RewardScene.new()
    scene:initScene()
    return scene
end

function RewardScene:back()
    if self.argv.returnScene ~= nil then  
    else
        self:replaceScene(MainMenuScene)
    end
end

function RewardScene:setTableViewsEnabled( v )
   if not self.touchDisableSetTimes then
		self.touchDisableSetTimes = 0
	end
	if (v) then
		self.touchDisableSetTimes = self.touchDisableSetTimes - 1
		if (self.touchDisableSetTimes <= 0) then
			self.touchDisableSetTimes = 0
			if self.tableUI then
				self.tableUI:setTouchEnabled(v)
			end
		end
	else
		self.touchDisableSetTimes = self.touchDisableSetTimes + 1
		if self.tableUI then
			self.tableUI:setTouchEnabled(v)
		end
	end 
end 

local TAG_TXT_REWARDREASON_L = 1001
local TAG_TXT_REWARDREASON_M = 1002
local TAG_TXT_REWARDREASON_R = 1003
local TAG_TXT_REWARD_NAME = 1004
local TAG_TXT_REWARD_NUM = 1005
local TAG_BTN_GETREWARD = 1006
local TAG_TXT_BAGFULL = 1007
local TAG_PIC_REWARD_BG = 1008
local TAG_PIC_REWARD = 1009
local TAG_NORMAL_CARD_SMALL = 1010
local TAG_FRAME_CARD = 1011

local cellTag = -1002

local isCard_bag_full = false
local isEquip_bag_full = false
local isItem_bag_full = false

local isItem_bag_Overflow = false

local hasRewardItemInBag = false

function RewardScene:createTableView(data,argv)
	local RewardRenderer = class(TableViewRenderer)
	function RewardRenderer:ctor(width,height)
		local rows = #data
        for i=1, rows do
            self.list[i] = i
        end
		local builder = LayoutBuilder:createWithContentsOfFile("scene/reward_new.json")
		self.builder = builder
	end
	
	function RewardRenderer:buildCell(container)
		local cell = self.builder:build("sb/reward_list") 
		cell:setPosition(ccp(0, self.height))
		cell:getChildByName("frame_card"):setTag(TAG_FRAME_CARD)
		cell:getChildByName("txt_l"):setVisible(false)
		cell:getChildByName("txt_center"):setVisible(false)
		--cell:getChildByName("txt_r"):setVisible(false)
		cell:getChildByName("txt_itemname"):setVisible(false)
		cell:getChildByName("txt_itemquantity"):setVisible(false)
		cell:getChildByName("btn_blue_short"):setVisible(false)
		
		local getRewardLabelFlash = cell:getChildByName("btn_blue_short"):getChildByName("font")
	    getRewardLabelFlash:setVisible(false)
	    local zOrder = getRewardLabelFlash.refCocosObj:getZOrder() + 1
	    local posX, posY = getRewardLabelFlash.refCocosObj:getPosition()
	    local getRewardLabel = ArtLabelTTF:create(getTextByKey("reward_claimBtn"))
	    getRewardLabel:setSize(getRewardLabelFlash:getFontSize())
	    getRewardLabel:setPosition(posX+10,posY)
	    getRewardLabel:setTextAnchorPoint(ccp(0,1))
	    getRewardLabel:setAroundColor(ccc3(32,69,94))
	    getRewardLabel:construct()
	    cell:getChildByName("btn_blue_short"):addChild(CocosObject.new(getRewardLabel), zOrder)
	
		cell:getChildByName("font_bagfull"):setVisible(false)
		cell:getChildByName("font_bagfull"):getChildByName("font_bagfull"):setString(getTextByKey("reward_inventoryFullTxt"))
		cell:getChildByName("normal_card_small"):setVisible(false)
		
		cell:getChildByName("txt_l"):setTag(TAG_TXT_REWARDREASON_L)
		cell:getChildByName("txt_center"):setTag(TAG_TXT_REWARDREASON_M)
		--cell:getChildByName("txt_r"):setTag(TAG_TXT_REWARDREASON_R)
		cell:getChildByName("txt_l"):getChildByName("txt_l"):setTag(TAG_TXT_REWARDREASON_L)
		cell:getChildByName("txt_center"):getChildByName("txt_center"):setTag(TAG_TXT_REWARDREASON_M)
		--cell:getChildByName("txt_r"):getChildByName("txt_r"):setTag(TAG_TXT_REWARDREASON_R)
		cell:getChildByName("txt_itemname"):getChildByName("txt_itemname"):setVisible(false)
		cell:getChildByName("txt_itemquantity"):getChildByName("txt_itemquantity"):setVisible(false)
		local rewardNameLabel = CCLabelTTF:create("","Arial",cell:getChildByName("txt_itemname"):getChildByName("txt_itemname"):getFontSize())
		rewardNameLabel:setColor(cell:getChildByName("txt_itemname"):getChildByName("txt_itemname"):getColor())
		rewardNameLabel:setAnchorPoint(ccp(0,1))
		cell:getChildByName("txt_itemname"):addChild(CocosObject.new(rewardNameLabel))
		local rewardNumLabel = CCLabelTTF:create("","Arial",cell:getChildByName("txt_itemquantity"):getChildByName("txt_itemquantity"):getFontSize())
		rewardNumLabel:setAnchorPoint(ccp(0,1))
		rewardNumLabel:setColor(cell:getChildByName("txt_itemquantity"):getChildByName("txt_itemquantity"):getColor())
		cell:getChildByName("txt_itemquantity"):addChild(CocosObject.new(rewardNumLabel))
        rewardNameLabel:setTag(TAG_TXT_REWARD_NAME)
        rewardNumLabel:setTag(TAG_TXT_REWARD_NUM)
		cell:getChildByName("txt_itemname"):setTag(TAG_TXT_REWARD_NAME)
		cell:getChildByName("txt_itemquantity"):setTag(TAG_TXT_REWARD_NUM)
		cell:getChildByName("btn_blue_short"):setTag(TAG_BTN_GETREWARD)
		cell:getChildByName("font_bagfull"):setTag(TAG_TXT_BAGFULL)
		cell:getChildByName("bg_card"):setTag(TAG_PIC_REWARD_BG)
		cell:getChildByName("normal_card_small"):setTag(TAG_NORMAL_CARD_SMALL)
				
		cell:setTag(-1002)
		container:addChild(cell)
	end 
		
	function RewardRenderer:setData(rawCocosObj,index)
		local cell = self:getChildByTag(rawCocosObj, -1002)
		local function setTextByTag(tag, str )
			local txt = cell:getChildByTag(tag):getChildByTag(tag)
			if type(txt.setString) == "function" then
				txt:setString(str)
			end
		end
	
		local function setNodeVisibleByTag(tag, visible)
			cell:getChildByTag(tag):setVisible(visible)
		end
		local pic_position_x,pic_position_y = cell:getChildByTag(TAG_NORMAL_CARD_SMALL):getPosition()
		local picZOrder = cell:getChildByTag(TAG_PIC_REWARD_BG):getZOrder()
		local rewardName = "null"
		local rewardNum = "1"
		cell:removeChildByTag(TAG_PIC_REWARD, true)
		setNodeVisibleByTag( TAG_BTN_GETREWARD, false)
		setNodeVisibleByTag( TAG_TXT_BAGFULL, false)
		setNodeVisibleByTag( TAG_TXT_REWARD_NAME, false)
		setNodeVisibleByTag( TAG_TXT_REWARD_NUM, false)
		setNodeVisibleByTag( TAG_FRAME_CARD, false)
		if data[index + 1] then
			local rewardInfo = data[index + 1]
			rewardNum = "x"..rewardInfo.reward.amount
			if rewardInfo.reward.itemType == 1 then
			    --coin
			    local coinIcon = CCSprite:create("common/CoinIcon.png")
			    coinIcon:setTag(TAG_PIC_REWARD)
			    coinIcon:setPosition(ccp(80,-80))
			    cell:addChild(coinIcon,picZOrder)
			    rewardName = getTextByKey("resource_silverCoin")
			    setNodeVisibleByTag( TAG_FRAME_CARD, true)
            elseif rewardInfo.reward.itemType == 2 then	
                --gem
                local gemIcon = CCSprite:create("common/GemIcon.png")
			    gemIcon:setTag(TAG_PIC_REWARD)
			    gemIcon:setPosition(ccp(80,-80))
			    cell:addChild(gemIcon,picZOrder)
			    rewardName = getTextByKey("resource_goldCoin")
			    setNodeVisibleByTag( TAG_FRAME_CARD, true)
            elseif rewardInfo.reward.itemType == 3 then
                --energy
            elseif rewardInfo.reward.itemType == 4 then
                --exp
            elseif rewardInfo.reward.itemType == 5 then
                --card
                local cardMeta = MetaManager.card_meta[rewardInfo.reward.metaId]
			    local headCard = getHeadIconCanonCardByMetaId(rewardInfo.reward.metaId)
			    --headCard:setScale(0.9)
			    headCard:setPosition(ccp(pic_position_x,pic_position_y))
				--headCard:setAnchorPoint(ccp(0,1))
			    if cardMeta == nil then
			        rewardName = "Card"..rewardInfo.reward.metaId
			    else
			        --cardMeta = MetaManager.card_meta[101022]
			        rewardName = getTextByKey(cardMeta.name)
			    end 
				headCard:setTag(TAG_PIC_REWARD)
			    cell:addChild(headCard.refCocosObj,picZOrder)
				headCard:dispose()
            elseif rewardInfo.reward.itemType == 6 then
                --equip
				local canonItem = CanonItem:create()
				local itemMeta = MetaManager.equip_meta[rewardInfo.reward.metaId]
                canonItem:loadByMetaId(rewardInfo.reward.metaId)
                canonItem:setScale(0.9)
				canonItem:setPosition(ccp(80,-80))
				canonItem:setTag(TAG_PIC_REWARD)
				cell:addChild(canonItem.refCocosObj, picZOrder)
				canonItem:dispose()
				if itemMeta == nil then
			        rewardName = "Equip"..rewardInfo.reward.metaId
			    else
			        rewardName = getTextByKey(itemMeta.name)
			    end 
            elseif rewardInfo.reward.itemType == 7 then
                --prop
                local canonItem = CanonItem:create()
				local itemMeta = MetaManager.prop_meta[rewardInfo.reward.metaId]
                canonItem:loadByMetaId(rewardInfo.reward.metaId)
                canonItem:setScale(0.9)
				canonItem:setPosition(ccp(80,-80))
				canonItem:setTag(TAG_PIC_REWARD)
				cell:addChild(canonItem.refCocosObj, picZOrder)
				canonItem:dispose()
				if itemMeta == nil then
			        rewardName = "Prop"..rewardInfo.reward.metaId
			    else
			        rewardName = getTextByKey(itemMeta.name)
			    end 
            elseif rewardInfo.reward.itemType == 8 then
                --friendpoint
                local friendpointIcon = CCSprite:create("common/FriendpointIcon.png")
			    friendpointIcon:setTag(TAG_PIC_REWARD)
			    friendpointIcon:setPosition(ccp(80,-80))
			    cell:addChild(friendpointIcon,picZOrder)
			    rewardName = getTextByKey("resource_friendshipPoint")
			    setNodeVisibleByTag( TAG_FRAME_CARD, true)
            elseif rewardInfo.reward.itemType == 9 then
                --grid
            elseif rewardInfo.reward.itemType == 10 then
                --skillpoint
            elseif rewardInfo.reward.itemType == 11 then
                --eventpoint
            elseif rewardInfo.reward.itemType == 12 then
                --arenascore
            elseif rewardInfo.reward.itemType == ResourceEnum.UNION_CONTRIBUTION then
            	--军团贡献
            	local unionIcon = CCSprite:create("common/JunTuanGongXian.png")
			    unionIcon:setTag(TAG_PIC_REWARD)
			    unionIcon:setPosition(ccp(80,-80))
			    cell:addChild(unionIcon,picZOrder)
			    rewardName = getTextByKey("UnionWar_attend_prop")
			    setNodeVisibleByTag( TAG_FRAME_CARD, true)
			elseif rewardInfo.reward.itemType == 22 then
				--星灵
				local starIcon = CCSprite:create("Item/Picture/Prop_xingling0.png")
			    starIcon:setTag(TAG_PIC_REWARD)
			    starIcon:setPosition(ccp(80,-80))
			    cell:addChild(starIcon,picZOrder)
			    rewardName = getTextByKey("item_astralEssence")
			    setNodeVisibleByTag( TAG_FRAME_CARD, true)
			elseif rewardInfo.reward.itemType == 17 then
				--卡牌魂魄
				local CardId = MetaManager.card_fragment_meta[rewardInfo.reward.metaId].cardId
		        local rewardPic = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD,CardId)
		        local  PropSp = CocosObject.new(CCSprite:create("Item/Picture/Prop_soul.png"))
		        PropSp:setScale(0.7)
		        PropSp:setPosition(ccp(45,48))
		        rewardPic:addChild(PropSp)
			    rewardPic:setTag(TAG_PIC_REWARD)
			    rewardPic:setPosition(ccp(80,-80))
			    cell:addChild(rewardPic.refCocosObj,picZOrder)
			    if rewardPic then
			    	rewardPic:dispose()
			    end
			    local aName = Localization:getInstance():getText(MetaManager.card_meta[CardId].name)
			    rewardName = aName
			    setNodeVisibleByTag( TAG_FRAME_CARD, true)
			end	
		    --setTextByTag( TAG_TXT_REWARD_NAME, rewardName)
		    --setTextByTag( TAG_TXT_REWARD_NUM, rewardNum)
			ViewControlUtil.setLableText(cell:getChildByTag(TAG_TXT_REWARD_NAME):getChildByTag(TAG_TXT_REWARD_NAME), rewardName)
			ViewControlUtil.setLableText(cell:getChildByTag(TAG_TXT_REWARD_NUM):getChildByTag(TAG_TXT_REWARD_NUM), rewardNum)
		    if rewardInfo.rewardReason == 1 then
		        setTextByTag( TAG_TXT_REWARDREASON_L, getTextByKey("reward_login"))
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    elseif rewardInfo.rewardReason == 2 then
				local str = getTextByKey("reward_consecutiveLogin")
				str = string.gsub(str,"{num}",rewardInfo.rewardReasonDetail)
		        setTextByTag( TAG_TXT_REWARDREASON_L, str)
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    elseif rewardInfo.rewardReason == 3 then
		        local str = getTextByKey("reward_levelUpReward")
				str = string.gsub(str,"{num}",rewardInfo.rewardReasonDetail)
		        setTextByTag( TAG_TXT_REWARDREASON_L, str)
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    elseif rewardInfo.rewardReason == 4 then
		        --world boss
		        local str = getTextByKey("worldBoss_rewardPoolTitle")
		        local dateList = os.date("%x",rewardInfo.rewardReasonDetail)
		        dateList = dateList:split("/")
				str = string.gsub(str,"{month}",dateList[1])
				str = string.gsub(str,"{date}",dateList[2])
		        setTextByTag( TAG_TXT_REWARDREASON_L, str)
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    elseif rewardInfo.rewardReason == 5 then
		        --uc user came back 
		        setTextByTag( TAG_TXT_REWARDREASON_L, getTextByKey("reward_playerComeback"))
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    elseif rewardInfo.rewardReason == 6 then
		        --system compensation
		        setTextByTag( TAG_TXT_REWARDREASON_L, getTextByKey("reward_compensationReward"))
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    elseif rewardInfo.rewardReason == 7 then
		        --multi player boss
		        setTextByTag( TAG_TXT_REWARDREASON_L, getTextByKey("reward_multiplayerBossPoints"))
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    elseif rewardInfo.rewardReason == 8 then
		        --multi player boss after kill special boss
		        --print(table.tostring(rewardInfo))
		        local rewardTxt = Localization:getInstance():getText("reward_multiplayerBossLevel" , {num = rewardInfo.rewardReasonDetail})
		        setTextByTag( TAG_TXT_REWARDREASON_L, rewardTxt)
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    elseif rewardInfo.rewardReason == 9 then
		    	--军团斗兽场道具奖励 团长分配所得 unionColosseumTag
		        print(table.tostring(rewardInfo))
		        --{title:xxx, nickname:xxx  ,  bossId:xxxx}

				local _json = require("cjson")
				local detal = _json.decode(rewardInfo.rewardReasonDetail)
				print("detal = " .. tostringRich(detal))

				local titleName = UnionManager.getTitleName(tonumber(detal.title))
				local bossName = UnionManager.getBossName(detal.bossId)

				local showParams = {}
				showParams.careet = titleName
				showParams.name = detal.nickname
				showParams.bossName = bossName
		        local rewardTxt = Localization:getInstance():getText("union_monster_reward_distribution_output" , showParams)--【{careet}】{name}给你分配了杀死【{bossName}】战利品
		        setTextByTag( TAG_TXT_REWARDREASON_L, rewardTxt)
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
			elseif rewardInfo.rewardReason == 10 then
				--facebook share奖励
				setTextByTag( TAG_TXT_REWARDREASON_L, getTextByKey("FBactivity_reward_txt2"))
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
			elseif rewardInfo.rewardReason == 11 then
				--facebook 被邀请奖励
				setTextByTag( TAG_TXT_REWARDREASON_L, getTextByKey("FBactivity_reward_txt1"))
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    elseif rewardInfo.rewardReason == 12 then
		    	local rewardTxt = Localization:getInstance():getText("UnionWar_attend_back")
		        setTextByTag( TAG_TXT_REWARDREASON_L, rewardTxt)
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    elseif rewardInfo.rewardReason == 13 then
		    	local rewardTxt = Localization:getInstance():getText("balloon_reward2_desc")
		        setTextByTag( TAG_TXT_REWARDREASON_L, rewardTxt)
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    elseif rewardInfo.rewardReason == 14 then
				--7天登陆奖励
				local rewardTxt = Localization:getInstance():getText("consecutiveLogin_rewards",{num = rewardInfo.rewardReasonDetail})
		        setTextByTag( TAG_TXT_REWARDREASON_L, rewardTxt)
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    elseif rewardInfo.rewardReason == 15 then
				--老玩家回归奖励
				local rewardTxt = Localization:getInstance():getText("regressionGirl_text")
		        setTextByTag( TAG_TXT_REWARDREASON_L, rewardTxt)
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
	        elseif rewardInfo.rewardReason == 16 then

	        	local _json = require("cjson")
				local detal = _json.decode(rewardInfo.rewardReasonDetail)
				print("detal = " .. tostringRich(detal))

		    	local rewardTxt = Localization:getInstance():getText("redBag002" , {name = detal.nickname})
		        setTextByTag( TAG_TXT_REWARDREASON_L, rewardTxt)
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
	        elseif rewardInfo.rewardReason == 17 then
	        	--GVG小组赛礼包
				local rewardTxt = Localization:getInstance():getText("WGVG_Name17")
		        setTextByTag( TAG_TXT_REWARDREASON_L, rewardTxt)
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, true)
		    else
		        setNodeVisibleByTag( TAG_TXT_REWARDREASON_L, false)
		    end 
		    local nameSize = cell:getChildByTag(TAG_TXT_REWARD_NAME):getChildByTag(TAG_TXT_REWARD_NAME):getContentSize()
		    cell:getChildByTag(TAG_TXT_REWARD_NUM):setPosition(ccp(cell:getChildByTag(TAG_TXT_REWARD_NAME):getPositionX()+nameSize.width,cell:getChildByTag(TAG_TXT_REWARD_NAME):getPositionY()))
		    
		    if rewardInfo.reward.itemType == 5 then
		        setNodeVisibleByTag( TAG_BTN_GETREWARD, not(isCard_bag_full))
		        setNodeVisibleByTag( TAG_TXT_BAGFULL, isCard_bag_full)
		    elseif rewardInfo.reward.itemType == 6 then
		        setNodeVisibleByTag( TAG_BTN_GETREWARD, not(isEquip_bag_full))
		        setNodeVisibleByTag( TAG_TXT_BAGFULL, isEquip_bag_full)
		    elseif rewardInfo.reward.itemType == 7 then
		        local hasThisItem = false
		        for ci,cv in pairs(curPropsInfo) do 
		            if cv.metaId == rewardInfo.reward.metaId and cv.amount ~= 0 then
		                hasThisItem = true
		                hasRewardItemInBag = true
		                break
		            end 
		        end 
		        setNodeVisibleByTag( TAG_BTN_GETREWARD, (not(isItem_bag_full) or hasThisItem and not isItem_bag_Overflow))
		        setNodeVisibleByTag( TAG_TXT_BAGFULL, (isItem_bag_full and not(hasThisItem) or isItem_bag_Overflow)) 
		    else
		        setNodeVisibleByTag( TAG_BTN_GETREWARD, true)
		        setNodeVisibleByTag( TAG_TXT_BAGFULL, false)
		    end 
			setNodeVisibleByTag( TAG_TXT_REWARD_NAME, true)
			setNodeVisibleByTag( TAG_TXT_REWARD_NUM, true)
		end
	end 
	
	local function inArea(posX, posY, rect)
		if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
			return true
		end
		return false
	end	
	local function onListItemTouch( evt ) 
		local  function isInArea_Center(position, rect) 
			return position.x > rect.x and
					position.x < (rect.x + rect.width) and 
					position.y > rect.y and 
					position.y < ( rect.y + rect.height )
		end
		local selectedCell = self.tableUI:cellAtIndex(evt.data)
		local selectedIndex = evt.data + 1
		local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
		
		local getRewardBtn = selectedCell:getChildByTag(-1002):getChildByTag(TAG_BTN_GETREWARD)
		self._data = data[evt.data + 1]
		user_select.tab = evt.context
		local function getSingleReward(selectedIndex)	
			print(selectedIndex..data[selectedIndex].reward.amount)
			local params = {rewardId = data[selectedIndex].rewardId}
			
			local function getSingleRewardFinish(evt)
			    local rewardInfo = evt.data.reward
			    RewardManager:getReward( rewardInfo )
			    self:refreshRewardList("showGetRewardInfoPanel",rewardInfo)
			end 
			--send request
			local request = GetSingleRewardRequest.new( params, rpc.SendingPriority.kHigh )
			request:addEventListener( RequestNotifyEnum.GetSingleRewardSucceed, getSingleRewardFinish )
			request:start()	
		end
		local rect = {x = getRewardBtn:getPositionX(), y = 35,width = 168,height = 66}
		if isInArea_Center(posInCell, rect) and getRewardBtn:isVisible() then
			getSingleReward(selectedIndex)	
		end
		local posX,posY = getRewardBtn:getPosition()
		--print(posInCell.x.." "..posInCell.y.." "..posX.." "..posY)
	end
	
	local cell_height = 165
	local list_height = 700
	local list_posY = 1000
    local renderer = RewardRenderer.new(BAGCONFIG.WIDTH, cell_height)
    local list = TableView:create(renderer, BAGCONFIG.WIDTH, list_height,cellTag,
      TAG_BTN_GETREWARD,
      CCScale9Sprite:create("pic/scroll.png"), 
      CCScale9Sprite:create("pic/scroll.png"))

    list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch )
    list:setPosition(ccp(12, (list_posY-list_height)/2))
	--
    return list
end 


function RewardScene:refreshRewardList(argv1,argv2)

	if not self.rewardTipsLabel then --Scene has been disposed
		return
	end
	
	local function getRewardListResponse(evt)
	
		
        if (type(self) == "table") and self.rewardSceneExit then
          return
        end
    
    	if not self.rewardTipsLabel then --Scene has been disposed
			return
		end
		
		--clear chose btn state
		self.getNoCardReward = false
		self.mainUI:getChildByName("reward_title"):getChildByName("icon_checkbox_l"):setVisible(false)
		
		self.getNoEquipReward = false
		self.mainUI:getChildByName("reward_title"):getChildByName("icon_checkbox_r"):setVisible(false)
		
		if evt.data.sharkRewardList ~= nil then
		    if self.tableUI ~= nil then
		        self:removeChild(self.tableUI,true)
		        self.tableUI = nil
		    end 
			curPropsInfo = DataManager.getPropsData() 
			
			local usedGridNum = BagCalcManager.calcUsedGridNum()
            local totalGridNum = BagCalcManager.calcTotalGridNum()
  
			if BagCalcManager.isFull() then
				isCard_bag_full = true
				isEquip_bag_full = true
				isItem_bag_full = true
			else
				isCard_bag_full = false
				isEquip_bag_full = false
				isItem_bag_full = false
			end 
			
			if usedGridNum > totalGridNum then
			    isItem_bag_Overflow = true
			else
			    isItem_bag_Overflow = false
			end 
			
			hasRewardItemInBag = false
			
		    self.rewardListData = evt.data.sharkRewardList
		    if next(self.rewardListData) ~= nil then
		        self.rewardTipsLabel:setVisible(false)
		        self.getAllRewardBtnPic:getChildByName("btn_yellow_short_inactive"):setVisible(false)
		        self.getAllRewardBtnPic:getChildByName("btn_yellow_short"):setVisible(true)
		        self.getAllRewardBtn:setEnable(true)
		    else
		        self.rewardTipsLabel:setVisible(true)
		        self.getAllRewardBtnPic:getChildByName("btn_yellow_short_inactive"):setVisible(true)
		        self.getAllRewardBtnPic:getChildByName("btn_yellow_short"):setVisible(false)
		        self.getAllRewardBtn:setEnable(false)
		    end
		    self.tableUI = self:createTableView( self.rewardListData , self.argv) 
            --local zOrder = self.BaseUi:getZOrder()
	        self:addChildAt(self.tableUI,2)
	        if argv1 == "showGetRewardInfoPanel" and type(argv2) == "table" then
	            if next(argv2) == nil then
--pop new messagebos txt:rewardPopup_noReward
					CanonMessageBox:Show(getTextByKey("rewardPopup_noReward"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, nil, nil)
	            else
	                self.targetInfoPanel = GetRewardInfoPanel:create( self, argv2)--data[selectedIndex].reward)
			        PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
			    end 
			elseif argv1 == "notShowAnimation" then
				--nothing
			else
				local aDuration
				if #self.rewardListData == 1 then
					aDuration = 0.3 - 0.1
				else
					aDuration = (0.3 - 0.1) / (#self.rewardListData - 1)
				end
				for i = 1,#self.rewardListData do 
				    local aCell = self.tableUI:cellAtIndex(i - 1)
				    if aCell ~= nil then
					    aCell:setPositionX(aCell:getPositionX() - visibleSize.width-12)
					    local arr = CCArray:create()
					    arr:addObject(CCDelayTime:create(0.1+aDuration * (i - 1)))
					    arr:addObject(CCMoveBy:create(0.2, ccp(visibleSize.width+12, 0)))
					    aCell:runAction(CCSequence:create(arr))
					end 
				end 
			    --self.tableUI:setPositionX(-visibleSize.width)
                --self.tableUI:runAction(CCMoveBy:create(0.5, ccp(12+visibleSize.width, 0)))
	        end 
	        
		end 
	end 
	
	--
	
	local request = GetRewardListRequest.new( nil, rpc.SendingPriority.kHigh )
	request:addEventListener( RequestNotifyEnum.GetRewardListSucceed, getRewardListResponse )
	request:start()
end 

function RewardScene:setEnableUserTouch(isEnable)
    self:setTableViewsEnabled( isEnable )
    self.mainUI:setTouchEnabled(isEnable)
end 

function RewardScene:panelDismiss()
    self:setEnableUserTouch(true)
    self.targetInfoPanel = nil
end

function RewardScene:onInit()
	BaseUIScene.initBackGround(self)
    
    self.exit_animation_duration = 0.3
	
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/reward_new.json")
	self.mainUI = self.builder:build("reward")
	
    self:addChild(self.mainUI)
	--init UI
	--self.mainUI:getChildByName("reward_upbox"):setVisible(false)
	self.mainUI:getChildByName("reward_title"):getChildByName("txt_nocard"):getChildByName("txt_nocard"):setString(getTextByKey("reward_excludeCard"))
	self.mainUI:getChildByName("reward_title"):getChildByName("txt_noitem"):getChildByName("txt_noitem"):setString(getTextByKey("reward_excludeEquip"))
	local getAllRewardLabelFlash = self.mainUI:getChildByName("reward_title"):getChildByName("btn_yellow_short"):getChildByName("font")
	self.getAllRewardBtnPic = self.mainUI:getChildByName("reward_title"):getChildByName("btn_yellow_short")
	getAllRewardLabelFlash:setVisible(false)
	local zOrder = getAllRewardLabelFlash.refCocosObj:getZOrder() + 1
	local posX, posY = getAllRewardLabelFlash.refCocosObj:getPosition()
	local getAllRewardLabel = ArtLabelTTF:create(getTextByKey("reward_claimAllBtn"))
	getAllRewardLabel:setSize(getAllRewardLabelFlash:getFontSize())
	getAllRewardLabel:setPosition(posX,posY)
	getAllRewardLabel:setTextAnchorPoint(ccp(-0.1, 1))
	getAllRewardLabel:setAroundColor(ccc3(102,51,0))
	getAllRewardLabel:construct()
	self.mainUI:getChildByName("reward_title"):getChildByName("btn_yellow_short"):addChild(CocosObject.new(getAllRewardLabel), zOrder)
	
	self.mainUI:getChildByName("txt_prompt"):getChildByName("txt"):setString(getTextByKey("reward_noReward"))
	self.rewardTipsLabel = self.mainUI:getChildByName("txt_prompt")
	self.rewardTipsLabel:setVisible(false)
	
	local onNoGetEquipBtnClick = nil;
	
	local function onNoGetCardBtnClick()
		if self.getNoCardReward then
			self.getNoCardReward = false
			self.mainUI:getChildByName("reward_title"):getChildByName("icon_checkbox_l"):setVisible(false)
		else
			self.getNoCardReward = true
			self.mainUI:getChildByName("reward_title"):getChildByName("icon_checkbox_l"):setVisible(true)
			if self.getNoEquipReward then
				onNoGetEquipBtnClick()
			end
		end
	end 
	
	onNoGetEquipBtnClick =  function()
		if self.getNoEquipReward then
			self.getNoEquipReward = false
			self.mainUI:getChildByName("reward_title"):getChildByName("icon_checkbox_r"):setVisible(false)
		else
			self.getNoEquipReward = true
			self.mainUI:getChildByName("reward_title"):getChildByName("icon_checkbox_r"):setVisible(true)
			if self.getNoCardReward then
				onNoGetCardBtnClick()
			end
		end
	end 
	
	local function onGetAllRewardBtnClick()
	    print("click GetAllRewardBtn")
		local function getAllRewardFinish(evt)
		    self:setEnableUserTouch(true)
			local rewardInfo = {}
			if next(evt.data) == nil then
			    CanonMessageBox:Show(getTextByKey("rewardPopup_noReward"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, nil, nil)
		        return
			else
			    for k,v in pairs(evt.data.rewards) do 
			        table.insert(rewardInfo,v)
			    end 
			    RewardManager:getReward( rewardInfo )
			    self:refreshRewardList("showGetRewardInfoPanel",rewardInfo)
			end
		end
		if next(self.rewardListData) == nil then
--pop new messagebos txt:rewardPopup_noReward
			CanonMessageBox:Show(getTextByKey("rewardPopup_noReward"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, nil, nil)
		    return
		end 
		local hasRewardOccupyBackpack = false
		local hasRewardNotOccupyBackPack = false
		local onlyHasCardReward = true
		local onlyHasEquipReward = true
		for k,v in pairs(self.rewardListData) do 
		    if v.reward.itemType == 5 then
		        hasRewardOccupyBackpack = true
		        onlyHasEquipReward =false
            elseif v.reward.itemType == 6 then
                hasRewardOccupyBackpack = true
                onlyHasCardReward = false
            elseif v.reward.itemType == 7 then
		        hasRewardOccupyBackpack = true
		        onlyHasCardReward = false
		        onlyHasEquipReward = false
		    else
		        hasRewardNotOccupyBackPack = true
		        onlyHasCardReward = false
		        onlyHasEquipReward = false
		    end 
		end
 
		if (onlyHasCardReward and self.getNoCardReward) or (onlyHasEquipReward and self.getNoEquipReward) then
--pop new messagebos txt:rewardPopup_noReward
			CanonMessageBox:Show(getTextByKey("rewardPopup_noReward"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, nil, nil)
		    return
		end 
		
		if (isCard_bag_full or isEquip_bag_full or isItem_bag_full) --bag full
            and hasRewardOccupyBackpack                             
            and not hasRewardNotOccupyBackPack                      --only have reward occupy bag(hasRewardOccupyBackpack:true hasRewardNotOccupyBackPack:false)
            and (not self.getNoCardReward or not self.getNoEquipReward) --chose get reward that occupy bag
            and (not(hasRewardItemInBag) or isItem_bag_Overflow)
        then
                self:setEnableUserTouch(false)
                NewPackageFullPanel:show()
                -- local aPanel = MessageBoxPanel:create(self, MessageBoxType.kBagFullCanNotGetReward)
                -- self:addChild(aPanel) 
                -- aPanel:scaleIn()
			    return
		end 
		local params = {pickUpCard = not(self.getNoCardReward),pickUpEquip = not(self.getNoEquipReward)}
		local request = GetAllRewardRequest.new( params, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.GetAllRewardSucceed, getAllRewardFinish )
		request:start()
		self:setEnableUserTouch(false)
	end 
	
	local noGetCardBtn = Button:create(self.mainUI:getChildByName("reward_title"):getChildByName("icon_checkbox_l"))
    noGetCardBtn:addEventListener(Events.kStart, onNoGetCardBtnClick)  
	local noGetEquipBtn = Button:create(self.mainUI:getChildByName("reward_title"):getChildByName("icon_checkbox_r"))
    noGetEquipBtn:addEventListener(Events.kStart, onNoGetEquipBtnClick)  
	self.getAllRewardBtn = Button:create(self.mainUI:getChildByName("reward_title"):getChildByName("btn_yellow_short"))
	self.getAllRewardBtn:addEventListener(Events.kStart, onGetAllRewardBtnClick)
	
	local noGetCardTxtBtn = Button:create(self.mainUI:getChildByName("reward_title"):getChildByName("txt_nocard"))
    noGetCardTxtBtn:addEventListener(Events.kStart, onNoGetCardBtnClick)  
	local noGetEquipTxtBtn = Button:create(	self.mainUI:getChildByName("reward_title"):getChildByName("txt_noitem"))
    noGetEquipTxtBtn:addEventListener(Events.kStart, onNoGetEquipBtnClick)  

	self.mainUI:getChildByName("reward_title"):getChildByName("icon_checkbox_l"):setVisible(false)
	self.mainUI:getChildByName("reward_title"):getChildByName("icon_checkbox_r"):setVisible(false)
	self.mainUI:getChildByName("reward_list"):setVisible(false)
	
	self:refreshRewardList()
	BaseUIScene.onInit(self)
end

function RewardScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function RewardScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function RewardScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterMov()
        self:nodeAnimationFinished()
        self:setEnableUserTouch(true)
        self.targetInfoPanel = nil
    end 
    local array = CCArray:create()
    self.mainUI:setPositionX(-visibleSize.width)

	array:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
	array:addObject(CCDelayTime:create(0.3))
	array:addObject(CCCallFunc:create(enterMov))
	self:setEnableUserTouch(false)
	self.mainUI:runAction(CCSequence:create(array)) 
end

function RewardScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function RewardScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function RewardScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  self.rewardSceneExit = true
end

function RewardScene:startExitAnimation()
    BaseUIScene.startExitAnimation(self)
    self:setEnableUserTouch(false)
    local function exitActionFinished()
        self:nodeAnimationFinished()
    end
    local array = CCArray:create()
	if #self.rewardListData > 0 then
		array:addObject(CCDelayTime:create(0.3))
	end
	array:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width-50, 0)))
	array:addObject(CCCallFunc:create(exitActionFinished))
	self.mainUI:runAction(CCSequence:create(array))
	--self.tableUI:runAction(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0)))
	local aDuration
	if #self.rewardListData == 1 then
	    aDuration = 0.3 
	else
	    aDuration = 0.3  / (#self.rewardListData - 1)
	end
    for i = 1, #self.rewardListData do
        local aCell = self.tableUI:cellAtIndex(i - 1)
        if aCell ~= nil then
            local arr = CCArray:create()
            arr:addObject(CCDelayTime:create(aDuration * (i - 1)))
            arr:addObject(CCMoveBy:create(0.2, ccp(-visibleSize.width-50, 0)))
            aCell:runAction(CCSequence:create(arr))
        end 
    end
end

function RewardScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function RewardScene:dispose()
	self.rewardTipsLabel = nil
	RewardScene.super.dispose(self)
end