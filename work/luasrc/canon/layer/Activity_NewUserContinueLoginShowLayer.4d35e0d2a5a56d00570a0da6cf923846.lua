--------------------------------------------------------------------------------
-- Activity_NewUserContinueLoginShowLayer.lua --七日连登
-- author: dang chao
-- updated: 2015-02-03
--------------------------------------------------------------------------------
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

Activity_NewUserContinueLoginShowLayer = class(Layer)

local offset_y = -60

local starPosition = {  
                           ["qinglong"] = {x=80,y=570+offset_y},   -- qing long 
	                       ["zhuque"] = {x=580,y=400+offset_y},  -- zhu que
	                       ["baihu"] = {x=640,y=570+offset_y},  -- bai hu
	                       ["xuanwu"] = {x=360,y=820+offset_y},  -- xuan wu
	                       ["ziwei"] = {x=580,y=740+offset_y},  -- zi wei
	                       ["taiwei"] = {x=140,y=740+offset_y},  -- tai wei
	                       ["tianshi"] = {x=140,y=400+offset_y},  -- tian shi 
                         }
                         

                   
local function getStarByIndex(index)
	if index == 2 then
		return "qinglong"
	elseif index == 3 then
		return "taiwei"--"zhuque"
	elseif index == 4 then
		return "xuanwu"--"baihu"
	elseif index == 5 then
		return "ziwei"--"xuanwu"
	elseif index == 6 then
		return "baihu"--"ziwei"
	elseif index == 7 then
		return "zhuque"--"taiwei"
	elseif index == 1 then
		return "tianshi"
	end 
	
end 

function Activity_NewUserContinueLoginShowLayer:ctor()
    self.container = nil
	self.rewardInfo = {}
end

function Activity_NewUserContinueLoginShowLayer:enable()
	--活动面板比正常的七日奖励多一天显示
    return shouldPopContinueLoginPanelToday(g_curServerTimeStamp,1) or New_UserContinueLoginShowPanel:enable()
end

function Activity_NewUserContinueLoginShowLayer:create( container ,closeCallBackFunc)
    self.container = container
    self.closeCallBackFunc = closeCallBackFunc
	--获取奖励信息
	self.starRewardInfo = MetaManager.consecutive_login_reward
	
    local s = Activity_NewUserContinueLoginShowLayer.new()
    s:initLayer()
	 
    return s
end
 
function getRewardByInfo(rewardInfo)
	local function getSpriteByResPath(resPath)
		local sprite = CanonItem:create()
		local quality = 1
		sprite:addChild(Sprite:create("Item/border/equipBg" .. quality .. ".png"))
		sprite:addChild(Sprite:create(resPath))
		local spt = Sprite:create("Item/border/equipBorder" .. quality .. ".png")
		spt:setScale(144/130)
		sprite:addChild(spt)
		return sprite
	end
    local rewardPic = nil
    local rewardName = nil
    if rewardInfo.rewardType == 1 then
		rewardPic = getSpriteByResPath("common/CoinIcon.png")
		rewardPic:setScale(0.46)
	    --rewardPic = Sprite:create("common/CoinIcon.png")
	    --rewardPic:setScale(0.5)
	    rewardName = getTextByKey("resource_silverCoin")
	elseif rewardInfo.rewardType == 2 then
	    rewardPic = getSpriteByResPath("common/GemIcon.png")
		rewardPic:setScale(0.46)
		--rewardPic = Sprite:create("common/GemIcon.png")
	    --rewardPic:setScale(0.5)
	    rewardName = getTextByKey("resource_goldCoin")
	elseif rewardInfo.rewardType == 5 then
	    rewardPic = getHeadIconCanonCardByMetaId(rewardInfo.rewardId)
	    rewardPic:setScale(0.5)
	    local cardMeta = MetaManager.card_meta[rewardInfo.rewardId]
	    if cardMeta == nil then
		    rewardName = "Card"..rewardInfo.rewardId
	    else
		    rewardName = getTextByKey(cardMeta.name)
	    end 
	elseif rewardInfo.rewardType == 6 then
	    rewardPic = CanonItem:create()
        rewardPic:loadByMetaId(rewardInfo.rewardId)
        rewardPic:setScale(0.46)
        local itemMeta = MetaManager.equip_meta[rewardInfo.rewardId]
        if itemMeta == nil then
		    rewardName = "Equip"..rewardInfo.rewardId
	    else
		    rewardName = getTextByKey(itemMeta.name)
	    end 
	elseif rewardInfo.rewardType == 7 then
	    rewardPic = CanonItem:create()
        rewardPic:loadByMetaId(rewardInfo.rewardId)
        rewardPic:setScale(0.46)
        local itemMeta = MetaManager.prop_meta[rewardInfo.rewardId]
        if itemMeta == nil then
		    rewardName = "Prop"..rewardInfo.rewardId
	    else
		    rewardName = getTextByKey(itemMeta.name)
	    end 
	elseif rewardInfo.rewardType == 8 then
		rewardPic = getSpriteByResPath("common/FriendpointIcon.png")
		rewardPic:setScale(0.46)
	    --rewardPic = Sprite:create("common/FriendpointIcon.png")
	    --rewardPic:setScale(0.5)
	    rewardName = getTextByKey("resource_friendshipPoint")
	end 
    return rewardPic,rewardName
end 

function Activity_NewUserContinueLoginShowLayer:initLayer()
    --init UI	
	
	Activity_NewUserContinueLoginShowLayer.super.initLayer(self)
	local bg = CCSprite:create("pic/activityIcons/Activity_ContinueLogin_Bg.png")
	bg:setScale(2.1)
	bg:setPosition(ccp(361,593+offset_y))
	self:addChild(CocosObject.new(bg))
	
    
    local titleBg = CCSprite:create("pic/activityIcons/title_bg.png")
	local title = CCSprite:create("pic/font_watchstar.png")
	titleBg:setScaleY(0.7)
	titleBg:addChild(title)
	title:setPosition(titleBg:getContentSize().width/2,titleBg:getContentSize().height/2)
	titleBg:setPosition(ccp(361,915+offset_y))
	self:addChild(CocosObject.new(titleBg))
	local bottomBg = CCSprite:create("pic/activityIcons/down_bg.png")
	bottomBg:setPosition(ccp(361,203+offset_y))
	self:addChild(CocosObject.new(bottomBg))
	
	local labelBottom = ArtLabelTTF:create(getTextByKey("consecutiveLogin_text" ),nil,33)--TextField:create( getTextByKey("consecutiveLogin_text" ))
	labelBottom:setSize(35)
    labelBottom:setDimensions(CCSizeMake(640,0))
    labelBottom:construct()
    --self.labelBottom:setDimensions(CCSizeMake(700,0))
	--self.labelBottom:setFontSize(33)
	labelBottom:setPosition(ccp(370,245+offset_y))
	self:addChild(CocosObject.new(labelBottom))

	--中间卡牌
	local bigRewardMetaId = 104061 -- 吕布
	local bigRewardCard = getBigCanonCardNoInfoByMetaId(bigRewardMetaId)
    bigRewardCard:setPosition(ccp(361,520+offset_y))
	bigRewardCard:setScale(0.9)
    self:addChild(bigRewardCard)
	
	local GameData = DataManager.getGameInitData()
	local gainedContinuousLoginRewards = {} 
	if GameData.sharkUserExtendMore and 
		   GameData.sharkUserExtendMore.continuousLoginRewardInfoV2 and 
		   GameData.sharkUserExtendMore.continuousLoginRewardInfoV2.gainedContinuousLoginRewards 
		then
		gainedContinuousLoginRewards = GameData.sharkUserExtendMore.continuousLoginRewardInfoV2.gainedContinuousLoginRewards 
	end
	--判断某日奖励是否领过
	local function judgeRewardHasGained(rewardId)
		if gainedContinuousLoginRewards[rewardId] then
			--已领取
			return true
		else
			--未领取
			return false
		end
	end
	
	local function getRewardStar(rewardInfo)
	    local star = CocosObject.new(CCSprite:create("pic/activityIcons/Activity_ContinueLogin_StarBg.png"))
	    local rewardPic = nil 
	    local rewardName = nil

	    rewardPic,rewardName = getRewardByInfo(rewardInfo)
	
	    if rewardPic ~= nil then
	        star:addChild(rewardPic)
	        rewardPic:setPosition(ccp(star:getContentSize().width/2,star:getContentSize().height/2))
	    end 
	    if rewardName ~= nil then
	        local rewardNameLabel 
				
			rewardNameLabel = ArtLabelTTF:create(getTextByKey("consecutiveLogin_date", {num = rewardInfo.id} ) ..":".. rewardName.."x"..rewardInfo.rewardAmount,nil,12)
			rewardNameLabel:setSize(12)
			
			rewardNameLabel:construct()
			star:addChild(CocosObject.new(rewardNameLabel))
	        rewardNameLabel:setPosition(ccp(star:getContentSize().width/2,-star:getContentSize().height*0.25))
	    end 
 
		
	    star:setScale(1.7)
	    return star
	end
	
	for k,v in pairs(self.starRewardInfo) do 
	    if v.acquireMethod == 1 then
	        local star = getRewardStar(v)
	        star:setPosition(ccp(starPosition[getStarByIndex(v.id)].x,starPosition[getStarByIndex(v.id)].y))
	        self:addChild(star)
			
			if judgeRewardHasGained(v.id) then
			--添加已领取图标
				local getRewardIcon = CCSprite:create("pic/activityIcons/signInIcon.png") 
				getRewardIcon:setPosition(ccp(star:getContentSize().width/2,star:getContentSize().height/2))
				getRewardIcon:setScale(0.5)
				star:addChild(CocosObject.new(getRewardIcon))
			end
	    end
	end 

    
end

function Activity_NewUserContinueLoginShowLayer.getTipNum()
  --没有角标需求
  return 0
end