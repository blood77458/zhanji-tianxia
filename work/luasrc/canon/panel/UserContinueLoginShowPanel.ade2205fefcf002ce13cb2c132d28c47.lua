--------------------------------------------------------------------------------
-- UserContinueLoginShowPanel.lua --观星
-- author: dang chao
-- updated: 2013-09-28
--------------------------------------------------------------------------------
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

UserContinueLoginShowPanel = class(Layer)
UserContinueLoginShowType = {popPanel = 1,activityLayer = 2}
local starName = {
                     ["qinglong"] =  "consecutiveLogin_azureDragon",
                     ["zhuque"] = "consecutiveLogin_vermilionBird",
                     ["baihu"] = "consecutiveLogin_whiteTiger",
                     ["xuanwu"] = "consecutiveLogin_blackTortoise",
                     ["ziwei"] = "consecutiveLogin_purpleForbidden",
                     ["taiwei"] = "consecutiveLogin_supremePalace",
                     ["tianshi"] = "consecutiveLogin_heavenlyMarket",
                  }
local starPosition = {  
                           ["qinglong"] = {x=80,y=570},   -- qing long 
	                       ["zhuque"] = {x=580,y=400},  -- zhu que
	                       ["baihu"] = {x=640,y=570},  -- bai hu
	                       ["xuanwu"] = {x=360,y=800},  -- xuan wu
	                       ["ziwei"] = {x=580,y=740},  -- zi wei
	                       ["taiwei"] = {x=140,y=740},  -- tai wei
	                       ["tianshi"] = {x=140,y=400},  -- tian shi 
                         }
                         
local TAG_STAR_MASK = 1001
local TAG_STAR_HASGOTTEN_REWARD = 1002
local TAG_STAR_MISS_REWARD = 1003

local seeStarActionIsRunning = false
local isNewSeeStar = true
                   
local function getStarByIndex(index)
	if isNewSeeStar then
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
	else
		if index == 1 then
			return "qinglong"
		elseif index == 2 then
			return "taiwei"--"zhuque"
		elseif index == 3 then
			return "xuanwu"--"baihu"
		elseif index == 4 then
			return "ziwei"--"xuanwu"
		elseif index == 5 then
			return "baihu"--"ziwei"
		elseif index == 6 then
			return "zhuque"--"taiwei"
		elseif index == 7 then
			return "tianshi"
		end 
	end
	
    
end 

function UserContinueLoginShowPanel:ctor()
    self.container = nil
	self.hasSawStarToday = false
	self.seeStarBtn = nil
	self.rewardInfo = {}
end

function UserContinueLoginShowPanel:enable()
    local isEnable = true 
	local GameData = DataManager.getGameInitData()
	if GameData.sharkUserExtend and 
	   GameData.sharkUserExtend.continuousLoginInfo and 
	   GameData.sharkUserExtend.continuousLoginInfo.firstGetRewardTime 
	then
	    local firstSeeStarTime = GameData.sharkUserExtend.continuousLoginInfo.firstGetRewardTime
	    local timeDiff = g_curServerTimeStamp - firstSeeStarTime
	    if timeDiff / 86400 < 7 then
	        
	    else
	        isEnable = false
	    end 
	end
	return isEnable  
end

function UserContinueLoginShowPanel:create( container ,type,closeCallBackFunc,rewardId)
    self.container = container
	self.clickContinueBg = nil
    if rewardId then
        self.choseStar = rewardId
    end
    self.initShowBigRewardActionFinish = false
    self.closeCallBackFunc = closeCallBackFunc
    self.getBigRewardState = false
	
	isNewSeeStar = true
	local GameData = DataManager.getGameInitData()
	if  GameData.sharkUserExtend and GameData.sharkUserExtend.continuousLoginInfo and GameData.sharkUserExtend.continuousLoginInfo.gainRewardInOrder ~= nil then
		isNewSeeStar = GameData.sharkUserExtend.continuousLoginInfo.gainRewardInOrder
	end
	
	if isNewSeeStar then
		he_log_info("+++++++++new see star get reward by order ")
		self.starRewardInfo = MetaManager.consecutive_login_reward_new
	else
		self.starRewardInfo = MetaManager.consecutive_login_reward
	end 
--star state: true-can chose false-can not chose,has gotton
     self.starState = {
                      ["qinglong"] = true,
                      ["zhuque"] = true,
                      ["baihu"] = true,
                      ["xuanwu"] = true,
                      ["ziwei"] = true,
                      ["taiwei"] = true,
                      ["tianshi"] = true
                    }
	local GameData = DataManager.getGameInitData()
    if GameData.sharkUserExtend and GameData.sharkUserExtend.continuousLoginInfo then
        local gainRewardsTable = GameData.sharkUserExtend.continuousLoginInfo.gainRewards
        for k,v in pairs(gainRewardsTable) do 
            self.starState[getStarByIndex(v)] = false
        end  
        if #gainRewardsTable == 7 and not GameData.sharkUserExtend.continuousLoginInfo.getBigReward then
            self.getBigRewardState = true
        end 
		if GameData.sharkUserExtend.continuousLoginInfo.getBigReward then
			self.hasSawStarToday = true
		end 
    end 
	
    local s = UserContinueLoginShowPanel.new()
    s:initLayer(type)
	 
    return s
end
--------------------------------
--close get reward panel
--------------------------------
function UserContinueLoginShowPanel:panelDismiss()
	if self.type == UserContinueLoginShowType.activityLayer then
		self.container.targetInfoPanel = nil
	end
	local GameData = DataManager.getGameInitData()
    local gainRewardsTable = GameData.sharkUserExtend.continuousLoginInfo.gainRewards
    if #gainRewardsTable >= 7 then
        if GameData.sharkUserExtend.continuousLoginInfo.getBigReward then
            self.hasSawStarToday = true
            self.seeStarBtnPic:setVisible(false)
			self.seeStarBtn:setVisible(false)
			self.seeStarBtn:setEnable(false)
			self.seeStarBtn.display:setPositionY(-math.abs(self.seeStarBtn.display:getPositionY()))
			if self.type == CalendarSignInType.popPanel then
				if self.clickContinueBg then
					self.clickContinueBg:setVisible(true)
					self.labelBottom:setVisible(false)
				end
			else
				self.hasSawStarLabel:setVisible(true)
			end
        else
            self.getBigRewardState = true
            
            self.bigRewardCard:setScale(0.001)
            self.bigRewardCard:setVisible(true)
            self.bigRewardCardBg:setVisible(true)
            local arr = CCArray:create() 
            arr:addObject(CCDelayTime:create(0.2))		    
            arr:addObject(CCScaleTo:create(1,1.5))
            arr:addObject(CCScaleTo:create(0.2,1))
            self.bigRewardCard:runAction(CCSequence:create(arr))
            
            seeStarActionIsRunning =false
            
            self.lableOnSeeStarBtn:setText(getTextByKey("consecutiveLogin_finalReward"))
            self.lableOnSeeStarBtn:setSize(26)
			self.lableOnSeeStarBtn:construct()
			self.seeStarBtnPic:setVisible(true)
	        self.seeStarBtn:setVisible(true)
			self.seeStarBtn:setEnable(true)
			self.seeStarBtn.display:setPositionY(math.abs(self.seeStarBtn.display:getPositionY()))
        end 
    else
        self.hasSawStarToday = true
		if self.type == CalendarSignInType.popPanel then
			if self.clickContinueBg then
				self.clickContinueBg:setVisible(true)
				self.labelBottom:setVisible(false)
			end
		else
			self.hasSawStarLabel:setVisible(true)
		end
        self.seeStarBtnPic:setVisible(false)
		self.seeStarBtn:setVisible(false)
		self.seeStarBtn:setEnable(false)
		self.seeStarBtn.display:setPositionY(-math.abs(self.seeStarBtn.display:getPositionY()))
    end 
    RewardManager:getReward( self.rewardInfo )
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

function UserContinueLoginShowPanel:initLayer(ctype)
    if ctype then
        self.type = ctype
    else
        self.type = UserContinueLoginShowType.activityLayer
    end 
	if self.type == CalendarSignInType.popPanel then
		--self.container:setTableViewsEnabled(false)
	end 
	
    UserContinueLoginShowPanel.super.initLayer(self)
    seeStarActionIsRunning = false
    local function onClosePanel(evt)
        if self.type == CalendarSignInType.popPanel and self.hasSawStarToday and self.initShowBigRewardActionFinish then
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			--self.container:setTableViewsEnabled(true)
			self.container.targetInfoPanel = nil
			if self.closeCallBackFunc and type(self.closeCallBackFunc) == "function" then
		        self.closeCallBackFunc()
		    end 
		end
    end 
    local starTable = {}
    local function setAllStarDark()
        for k,v in pairs(starTable) do 
            v.refCocosObj:getChildByTag(TAG_STAR_MASK):setVisible(true)
        end 
    end 
------------------------------
--judge if Miss x star
--new see star need this func
------------------------------
	local function isMissStar(index)
	
		local isMiss = false
		if isNewSeeStar and self.starState[getStarByIndex(index)]  then
			if self.choseStar then
				if index < self.choseStar then
					isMiss = true
				end
			else
				local GameData = DataManager.getGameInitData()
				if GameData.sharkUserExtend and 
				   GameData.sharkUserExtend.continuousLoginInfo and 
				   GameData.sharkUserExtend.continuousLoginInfo.firstGetRewardTime 
				then
					local firstSeeStarTime = GameData.sharkUserExtend.continuousLoginInfo.firstGetRewardTime
					local thisSeeStarDay = os.date("*t",firstSeeStarTime + (index - 1)* 3600*24)
					local curTime = os.date("*t",TimeUtil.getServerTimeSeconds())
					if curTime.day ~= thisSeeStarDay.day and firstSeeStarTime + (index - 1)* 3600*24 < TimeUtil.getServerTimeSeconds() then
						isMiss = true
					end 
				end
			end 
			
		end 
		return isMiss
	end 
------------------------------
--pop get reward panel
------------------------------
    local function popGetRewardPanel(rewardIndex)
            local getRewardPanel = MessageBoxPanel:create( self, MessageBoxType.kCommon )
            local panelBg = getRewardPanel.panelUI:getChildByName("common_bg_popup")
            local panelBtn = getRewardPanel.panelUI:getChildByName("common_btn_center")
            panelBg:setScaleY(1.5)
            panelBtn:setPositionY(panelBg:getPositionY()-panelBg:getContentSize().height+panelBtn:getContentSize().height/3)
            --txt
            local getRewardTextLabel = TextField:create( getTextByKey("consecutiveLogin_getReward" ))
	        getRewardTextLabel:setFontSize(30)
	        getRewardTextLabel:setPosition(ccp(panelBg:getPositionX()+panelBg:getContentSize().width/2,panelBg:getPositionY() - panelBg:getContentSize().height*0.2))
	        getRewardPanel.panelUI:addChild(getRewardTextLabel)
            --pic
            local rewardPic ,rewardName = getRewardByInfo(self.starRewardInfo[rewardIndex])
            if rewardPic then
                rewardPic:setScale(1)
                rewardPic:setPosition(ccp(panelBg:getPositionX()+panelBg:getContentSize().width/2 - panelBg:getContentSize().width*0.2,panelBg:getPositionY() - panelBg:getContentSize().height*0.65))
	            getRewardPanel.panelUI:addChild(rewardPic)
            end 
            --name and num
            if rewardName then
                local rewardNameAndNumLabel = ArtLabelTTF:create(rewardName.."x"..self.starRewardInfo[rewardIndex].rewardAmount,nil,30)
				--TextField:create( rewardName.."x"..self.starRewardInfo[rewardIndex].rewardAmount)
                --rewardNameAndNumLabel:setFontSize(30)
                rewardNameAndNumLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
				rewardNameAndNumLabel:construct()
                rewardNameAndNumLabel:setPosition(ccp(panelBg:getPositionX()+panelBg:getContentSize().width/2 + panelBg:getContentSize().width*0.1,panelBg:getPositionY() - panelBg:getContentSize().height*0.65))
	            getRewardPanel.panelUI:addChild(CocosObject.new(rewardNameAndNumLabel))
            end
            self:addChild(getRewardPanel) 
            getRewardPanel:scaleIn()
            self.container.targetInfoPanel = getRewardPanel
    end 
------------------------------    
--see star action finish
------------------------------
	local function showStarBlowupEffect()
		local particle = CCParticleSystemQuad:create("effect/fx_stars_blowup.plist")
		particle:setPosition(starTable[self.choseStar].refCocosObj:getContentSize().width/2,starTable[self.choseStar].refCocosObj:getContentSize().height/2)
		starTable[self.choseStar].refCocosObj:addChild(particle)
		particle:setAutoRemoveOnFinish(true)
		
		starTable[self.choseStar].refCocosObj:getChildByTag(TAG_STAR_HASGOTTEN_REWARD):setVisible(true)
        starTable[self.choseStar].refCocosObj:getChildByTag(TAG_STAR_MASK):setVisible(true)
        self.lightBorder:setVisible(false)
	end
    local function SeeStarActionFinish()
		if isNewSeeStar then
			for i=1,self.choseStar-1 do 
				if isMissStar(i)then
					starTable[i].refCocosObj:getChildByTag(TAG_STAR_MASK):setVisible(true)
					starTable[i].refCocosObj:getChildByTag(TAG_STAR_MISS_REWARD):setVisible(true)
				end 
			end 
		end 
			
		--
		popGetRewardPanel(self.choseStar)
        
    end 
-----------------------    
--see star action 
-----------------------
    local function runSeeStarAction()
	   self.seeStarBtnPic:setVisible(false)
	   self.seeStarBtn:setVisible(false)
	   self.seeStarBtn:setEnable(false)
	   self.seeStarBtn.display:setPositionY(-math.abs(self.seeStarBtn.display:getPositionY()))
	   
       local arr = CCArray:create()
       if isNewSeeStar then
	   else
		   local canChoseStarTable = {} 
		   for i = 1,7 do 
				if self.starState[getStarByIndex(i)] then
					table.insert(canChoseStarTable,i)
				end
		   end        
		   local repeatTime = 5
		   
		   if #canChoseStarTable == 1 then
				self.lightBorder:setPosition(ccp(starTable[self.choseStar]:getPositionX(),starTable[self.choseStar]:getPositionY()))
				for i = 1 ,repeatTime do
					arr:addObject(CCDelayTime:create(0.1 * i ))
					local function starLight()
						setAllStarDark()
						self.lightBorder:setVisible(true)
						starTable[self.choseStar].refCocosObj:getChildByTag(TAG_STAR_MASK):setVisible(false)
					end 
					local function starDark()
						self.lightBorder:setVisible(false)
						starTable[self.choseStar].refCocosObj:getChildByTag(TAG_STAR_MASK):setVisible(true)
					end 
					arr:addObject(CCCallFunc:create(starDark))
					arr:addObject(CCDelayTime:create(0.1*i))
					arr:addObject(CCCallFunc:create(starLight))
				end 
		   else
				for i = 1 ,repeatTime do
					for k,starIndex in pairs(canChoseStarTable) do 
						arr:addObject(CCDelayTime:create(0.05 * i ))
						arr:addObject(CCMoveTo:create(0.001  ,ccp(starTable[starIndex]:getPositionX(),starTable[starIndex]:getPositionY())))
						local function starLight()
							setAllStarDark()
							self.lightBorder:setVisible(true)
							starTable[starIndex].refCocosObj:getChildByTag(TAG_STAR_MASK):setVisible(false)
						end 
						arr:addObject(CCCallFunc:create(starLight))
					end 
				end 
				for starIndex = 1, self.choseStar do 
					if self.starState[getStarByIndex(starIndex)] then
						arr:addObject(CCDelayTime:create(0.2 * starIndex ))
						arr:addObject(CCMoveTo:create(0.001  ,ccp(starTable[starIndex]:getPositionX(),starTable[starIndex]:getPositionY())))
						local function starLight()
							setAllStarDark()
							starTable[starIndex].refCocosObj:getChildByTag(TAG_STAR_MASK):setVisible(false)
						end
						arr:addObject(CCCallFunc:create(starLight))
					end 
				end 
		   end
	   end
	   
	   arr:addObject(CCCallFunc:create(showStarBlowupEffect))
       arr:addObject(CCDelayTime:create(0.7))
       arr:addObject(CCCallFunc:create(SeeStarActionFinish))
       self.lightBorder:runAction(CCSequence:create(arr))
	   
    end 
---------------------------
--get big reward response
---------------------------    
    local function getBigRewardSucceed(reward)
        local GameData = DataManager.getGameInitData()
		if self.bigRewardInfo then
			self.rewardInfo = self.bigRewardInfo
		else
			self.rewardInfo = {reward.data.reward}
		end
        popGetRewardPanel(8)
		GameData.sharkUserExtend.continuousLoginInfo.getBigReward = true
        DataManager.setGameInitData(GameData)
    end
    
    local function getBigRewardFailed(err)
        print("getBigRewardFailed")
        self.hasSawStarToday = true
    end 
-------------------------------------
--click SeeStar Btn
-------------------------------------
    local function OnSeeStarBtnClick(evt)
        print("click see star btn")
        if not seeStarActionIsRunning and self.initShowBigRewardActionFinish then
            if not self.getBigRewardState  then
				local function getContineLoginRewardSucceed(reward)
					self.choseStar = reward.data.rewardId
					self.rewardInfo = {reward.data.reward}
					if reward.data.bigReward then
						self.bigRewardInfo = {reward.data.bigReward}
					end
					seeStarActionIsRunning = true
					runSeeStarAction()
					--Synchronous front-end data
					local GameData = DataManager.getGameInitData()
					if GameData.sharkUserExtend and GameData.sharkUserExtend.continuousLoginInfo then
					    table.insert(GameData.sharkUserExtend.continuousLoginInfo.gainRewards,reward.data.rewardId)
					    GameData.sharkUserExtend.continuousLoginInfo["latestGetRewardTime"] = g_curServerTimeStamp
					else
					    --first see star
					    if GameData.sharkUserExtend then
					        GameData.sharkUserExtend["continuousLoginInfo"] = { firstGetRewardTime = g_curServerTimeStamp,
					                                                            latestGetRewardTime = g_curServerTimeStamp,
                                                                                gainRewards = {reward.data.rewardId}, 
                                                                                getBigReward = false}
					    else
					        GameData["sharkUserExtend"] = {}
                            GameData.sharkUserExtend["continuousLoginInfo"] = { firstGetRewardTime = g_curServerTimeStamp,
                                                                                latestGetRewardTime = g_curServerTimeStamp,
                                                                                gainRewards = {reward.data.rewardId}, 
                                                                                getBigReward = false}
					    end 
					end
					DataManager.setGameInitData(GameData)
          if type(self.container.resetTipInfoForActivity) == "function" then
            self.container:resetTipInfoForActivity("Activity_ContinueLogin")
          end
				end
				local function getContineLoginRewardFailed(err)
					if err.data.retCode == 714144 then
	                --has gotten reward already
					end 
					self.hasSawStarToday = true
					self.seeStarBtnPic:setVisible(false)
					self.seeStarBtn:setVisible(false)
					self.seeStarBtn:setEnable(false)
					self.seeStarBtn.display:setPositionY(-math.abs(self.seeStarBtn.display:getPositionY()))
					if self.type == CalendarSignInType.popPanel then
						if self.clickContinueBg then
							self.clickContinueBg:setVisible(true)
							self.labelBottom:setVisible(false)
						end
					else
						self.hasSawStarLabel:setVisible(true)
					end
				end 
				local params = {getBigReward = false}
				local request = GetContinueLoginRewardRequest.new( params, rpc.SendingPriority.kHigh )
				request:addEventListener( RequestNotifyEnum.GetContinueLoginRewardSucceed, getContineLoginRewardSucceed )
				request:addEventListener( RequestNotifyEnum.GetContinueLoginRewardFailed, getContineLoginRewardFailed )
				request:start()
            else
                seeStarActionIsRunning = true
                local params = {getBigReward = true}
	            local request = GetContinueLoginRewardRequest.new( params, rpc.SendingPriority.kHigh )
                request:addEventListener( RequestNotifyEnum.GetContinueLoginRewardSucceed, getBigRewardSucceed )
                request:addEventListener( RequestNotifyEnum.GetContinueLoginRewardFailed, getBigRewardFailed )
                request:start()
            end 
        end 
    end 
    --init UI	
	local bg = CCSprite:createWithSpriteFrameName("Activity_ContinueLogin_Bg.png")
	bg:setScale(2)
	bg:setPosition(ccp(361,585))
	self:addChild(CocosObject.new(bg))
	
    if self.type == CalendarSignInType.popPanel then
		local titleBg = CCSprite:createWithSpriteFrameName("title_bg.png")
		local title = CCSprite:create("pic/font_watchstar.png")
		titleBg:addChild(title)
		title:setPosition(titleBg:getContentSize().width/2,titleBg:getContentSize().height/2)
		titleBg:setPosition(ccp(361,915))
		self:addChild(CocosObject.new(titleBg))
		local bottomBg = CCSprite:createWithSpriteFrameName("down_bg.png")
		bottomBg:setPosition(ccp(361,203))
		self:addChild(CocosObject.new(bottomBg))
		
		self.clickContinueBg = CCSprite:createWithSpriteFrameName("semitransparent_Bg.png")
		self.clickContinueBg:setPosition(bottomBg:getContentSize().width/2,bottomBg:getContentSize().height/2)
		bottomBg:addChild(self.clickContinueBg)
		local clickContinueLabel = ArtLabelTTF:create(getTextByKey("consecutiveLogin_continue"),nil,30)
		clickContinueLabel:setPosition(self.clickContinueBg:getContentSize().width/2,self.clickContinueBg:getContentSize().height/2)
		self.clickContinueBg:addChild(clickContinueLabel)
		self.clickContinueBg:setVisible(false)
	end 
    self.labelBottom = ArtLabelTTF:create(getTextByKey("consecutiveLogin_text" ),nil,33)--TextField:create( getTextByKey("consecutiveLogin_text" ))
	self.labelBottom:setSize(35)
    self.labelBottom:setDimensions(CCSizeMake(640,0))
    self.labelBottom:construct()
    --self.labelBottom:setDimensions(CCSizeMake(700,0))
	--self.labelBottom:setFontSize(33)
	self.labelBottom:setPosition(ccp(370,245))
	self:addChild(CocosObject.new(self.labelBottom))

    self.bigReward_Txt = ArtLabelTTF:create(getTextByKey( "consecutiveLogin_reminder" ))
    self.bigReward_Txt:setSize( 33 )
    self.bigReward_Txt:setPosition(ccp( 361, 345 ))
    self.bigReward_Txt:construct()
    self:addChild(CocosObject.new( self.bigReward_Txt ))
    self.bigReward_Txt:setVisible( false )
	

	local function getRewardStar(rewardInfo)
	    local star = CocosObject.new(CCSprite:createWithSpriteFrameName("Activity_ContinueLogin_StarBg.png"))
	    local rewardPic = nil 
	    local rewardName = nil

	    rewardPic,rewardName = getRewardByInfo(rewardInfo)
	
	    if rewardPic ~= nil then
	        star:addChild(rewardPic)
	        rewardPic:setPosition(ccp(star:getContentSize().width/2,star:getContentSize().height/2))
	    end 
	    if rewardName ~= nil then
	        local rewardNameLabel 
				
			if isNewSeeStar then
				rewardNameLabel = ArtLabelTTF:create(getTextByKey("consecutiveLogin_date", {num = rewardInfo.id} ) ..":".. rewardName.."x"..rewardInfo.rewardAmount,nil,12)
				rewardNameLabel:setSize(12)
			else
				rewardNameLabel = ArtLabelTTF:create(rewardName.."x"..rewardInfo.rewardAmount,nil,12)
				rewardNameLabel:setSize(16)
			end
			
			rewardNameLabel:construct()
			star:addChild(CocosObject.new(rewardNameLabel))
	        rewardNameLabel:setPosition(ccp(star:getContentSize().width/2,-star:getContentSize().height*0.25))
	    end 
	    
--[[  --²»ÔÚÀïÃæÏÔÊ¾ÎÄ×ÖÁË
	    local starNameLabel = ArtLabelTTF:create(getTextByKey(starName[getStarByIndex(rewardInfo.id)]),nil,12)
	    starNameLabel:setSize(16)
		starNameLabel:construct()
		star:addChild(CocosObject.new(starNameLabel))
	    starNameLabel:setPosition(ccp(star:getContentSize().width/2,star:getContentSize().height*0.2))
--]]

	    --[[local starBorderUp = CCSprite:createWithSpriteFrameName("Activity_ContinueLogin_StarBorder.png")
	    local starBorderDown = CCSprite:createWithSpriteFrameName("Activity_ContinueLogin_StarBorder.png")
	    starBorderDown:setFlipX(true)
	    starBorderDown:setFlipY(true)
	    starBorderUp:setPosition(ccp(star:getContentSize().width/2,star:getContentSize().height/2))
	    starBorderDown:setPosition(ccp(star:getContentSize().width/2,star:getContentSize().height/2))
	    star:addChild(CocosObject.new(starBorderUp))
	    star:addChild(CocosObject.new(starBorderDown))--]]
-- mask layer
        local maskLayer = CCLayerColor:create(ccc4(0,0,0,150), star:getContentSize().width, star:getContentSize().height)
        maskLayer:setTag(TAG_STAR_MASK)
        if self.starState[getStarByIndex(rewardInfo.id)] then
            maskLayer:setVisible(false)
        else
            maskLayer:setVisible(true)
        end 
	    star:addChild(CocosObject.new(maskLayer))
-- has get rewardIcon 
        local getRewardIcon = CCSprite:createWithSpriteFrameName("signInIcon.png") 
        getRewardIcon:setTag(TAG_STAR_HASGOTTEN_REWARD)
        getRewardIcon:setPosition(ccp(star:getContentSize().width/2,star:getContentSize().height/2))
        getRewardIcon:setScale(0.5)
        if self.starState[getStarByIndex(rewardInfo.id)] then
            getRewardIcon:setVisible(false)
        else
            getRewardIcon:setVisible(true)
        end 
	    star:addChild(CocosObject.new(getRewardIcon))
-- has missed sign
		if isNewSeeStar then
			local missLabel = ArtLabelTTF:create(getTextByKey("activity_day_miss"), nil, 12)
			missLabel:setScale(0.7)
			missLabel:setTag(TAG_STAR_MISS_REWARD)
			missLabel:setPosition(ccp(star:getContentSize().width/2,star:getContentSize().height/2))
			star:addChild(CocosObject.new(missLabel))
			missLabel:setVisible(false)
			if isMissStar(rewardInfo.id) then
				maskLayer:setVisible(true)
				missLabel:setVisible(true)
			end 
		end 
		
	    star:setScale(1.7)
	    return star
	end 
	

	
	for k,v in pairs(self.starRewardInfo) do 
	    if v.acquireMethod == 1 then
	        local star = getRewardStar(v)
	        star:setPosition(ccp(starPosition[getStarByIndex(v.id)].x,starPosition[getStarByIndex(v.id)].y))
	        self:addChild(star)
	        starTable[v.id] = star
	    end
	end 
	
--  chosen light border
    self.lightBorder = CCSprite:createWithSpriteFrameName("Activity_ContinueLogin_ChosedStarBorder.png")
    self:addChild(CocosObject.new(self.lightBorder))
    self.lightBorder:setVisible(false)
    
    self.bigRewardCard =  getBigCanonCardNoInfoByMetaId(self.starRewardInfo[8].rewardId)
    self.bigRewardCard:setPosition(ccp(361,585))
    self:addChild(self.bigRewardCard)
    self.bigRewardCard:setScale(0.01)
    
    self.bigRewardCardBg = CCSprite:createWithSpriteFrameName("Activity_ContinueLogin_FinalReward_Bg.png")
	self.bigRewardCardBg:setScale(2)
    self.bigRewardCardBg:setPosition(ccp(self.bigRewardCard:getContentSize().width/2,self.bigRewardCard:getContentSize().height/2))
    self.bigRewardCard:addChild(CocosObject.new(self.bigRewardCardBg))
    self.bigRewardCardBg:setVisible(false)
    self.bigRewardCardBg:setZOrder(-1)

--close
    if self.type == CalendarSignInType.popPanel then
        local closeTouchLayer = Layer:create()
        local winSize = CCDirector:sharedDirector():getWinSize()
        closeTouchLayer:setContentSize(CCSizeMake(winSize.width, winSize.height))
        self:addChild(closeTouchLayer)
        local btn_close_Btn = Button:create(closeTouchLayer)
        btn_close_Btn:addEventListener(Events.kStart ,onClosePanel) 
    end 
	
	self.hasSawStarLabel = ArtLabelTTF:create(getTextByKey("consecutiveLogin_completedTxt"),nil,33)--TextField:create(getTextByKey("consecutiveLogin_completedTxt"))
	--self.hasSawStarLabel:setFontSize(33)
	self.hasSawStarLabel:setPosition(ccp(361,170))
	self:addChild(CocosObject.new(self.hasSawStarLabel))
	
	self.seeStarBtnPic = Sprite:create("pic/btn_common.png")
	self.seeStarBtnPic:setPosition(ccp(361,165))
	self:addChild(self.seeStarBtnPic)
	
	if self.getBigRewardState then
		self.lableOnSeeStarBtn = ArtLabelTTF:create(getTextByKey("consecutiveLogin_finalReward"),nil,26)
	else 
		if isNewSeeStar then
			self.lableOnSeeStarBtn = ArtLabelTTF:create(getTextByKey("reward_claimBtn"),nil,33)
		else
			self.lableOnSeeStarBtn = ArtLabelTTF:create(getTextByKey("consecutiveLogin_btn"),nil,33)
		end
		
		self.lableOnSeeStarBtn:setSize(40)
		self.lableOnSeeStarBtn:construct()
	end 
	self.lableOnSeeStarBtn:setPosition(ccp(self.seeStarBtnPic:getBounds().size.width/2,self.seeStarBtnPic:getBounds().size.height/2))
	self.seeStarBtnPic:addChild(CocosObject.new(self.lableOnSeeStarBtn))
	
    self.seeStarBtn = Button:create(self.seeStarBtnPic)
	self.seeStarBtn:addEventListener(Events.kStart,OnSeeStarBtnClick)
	self.seeStarBtnPic:setVisible(false)
	self.seeStarBtn:setVisible(false)
	self.seeStarBtn:setEnable(false)
	self.seeStarBtn.display:setPositionY(-math.abs(self.seeStarBtn.display:getPositionY()))
		
	if self.hasSawStarToday then
	    self.seeStarBtnPic:setVisible(false)
		self.seeStarBtn:setVisible(false)
		self.seeStarBtn:setEnable(false)
		self.seeStarBtn.display:setPositionY(-math.abs(self.seeStarBtn.display:getPositionY()))
	else
	    self.hasSawStarLabel:setVisible(false)
	end  
--run show big reward action 
    local function initShowBigRewardFinish()
        self.initShowBigRewardActionFinish = true
        --self.bigRewardCard:setVisible(false)
        if self.type ~= UserContinueLoginShowType.popPanel then
            if shouldSeeStarToday(g_curServerTimeStamp) then
				self.seeStarBtnPic:setVisible(true)
				self.seeStarBtn:setVisible(true)
				self.seeStarBtn:setEnable(true)
				self.seeStarBtn.display:setPositionY(math.abs(self.seeStarBtn.display:getPositionY()))
			else
			    self.hasSawStarLabel:setVisible(true)
			end 
		else
			self.seeStarBtnPic:setVisible(true)
			self.seeStarBtn:setVisible(true)
			self.seeStarBtn:setEnable(true)
			self.seeStarBtn.display:setPositionY(math.abs(self.seeStarBtn.display:getPositionY()))
        end 
    end 
        
    for k,v in pairs(starTable) do 
        v:setVisible(false)
		v:setScale(0.1)
    end 
    local function starShowAction()
		for k,v in pairs(starTable) do 
			v:setVisible(true)
			v:runAction(CCScaleTo:create(0.2,1.7))
		end 
        self.bigReward_Txt:setVisible( true )
	end 
    local arr = CCArray:create() 
	if shouldSeeStarToday(g_curServerTimeStamp) then
		arr:addObject(CCDelayTime:create(0.2))		    
		arr:addObject(CCScaleTo:create(1,1.5))
		arr:addObject(CCScaleTo:create(0.2,1))
		arr:addObject(CCDelayTime:create(1))
	end
	arr:addObject(CCCallFunc:create(starShowAction))
	if shouldSeeStarToday(g_curServerTimeStamp) then
		arr:addObject(CCScaleTo:create(0.1,0.7))
        arr:addObject(CCMoveTo:create(0.1,ccp(361,535)))
        self.Show_SeeStartToday = true
    else
        arr:addObject(CCScaleTo:create(0.001,0.7))
        arr:addObject(CCMoveTo:create(0.001,ccp(361,535)))
    end
    arr:addObject(CCCallFunc:create(initShowBigRewardFinish))
    self.bigRewardCard:runAction(CCSequence:create(arr))
end

function UserContinueLoginShowPanel.getTipNum()
  if not UserContinueLoginShowPanel.enable() then
    return 0
  end
  
  local gameInitData = DataManager.getGameInitData()
  if not gameInitData.sharkUserExtend.continuousLoginInfo then
    return 1
  end
  
  local oldDate = os.date("%Y%m%d", gameInitData.sharkUserExtend.continuousLoginInfo.latestGetRewardTime)
  local currentDate = os.date("%Y%m%d", TimeUtil.getServerTimeSeconds())
  --if oldDate ~= currentDate then
  if TimeUtil.getPasseddDaysToNow(gameInitData.sharkUserExtend.continuousLoginInfo.latestGetRewardTime) ~= 0 then --判断不为同一天
    return 1
  else
    return 0
  end
end