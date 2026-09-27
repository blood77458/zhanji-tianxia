--卡牌合成
-- modified by zheng.che @ 2014-8-15 16:42:45 增加万能转生卡处理

require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.customUI.CanonCard"
require "canon.data.DataManager"
require "canon.models.PackageModel"
require "canon.request.CardComposeRequest"
require "canon.request.UpgradeCardByGeneralExpRequest"
require "canon.customUI.CanonCard"
require "canon.models.CommonManager"
require "canon.scene.CardEvolveResultScene"
require "canon.canonUtils"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
CardComposeScene = class(BaseUIScene)
local angleValue = 0
local cardNum    = 5  --每个圆圈卡牌数
local scheduler = CCDirector:sharedDirector():getScheduler()

local SUGGESTION_RARE = 3

--打开方式
CardComposeScene.STETE_CARD = "STETE_CARD"	--使用卡牌强化
CardComposeScene.STATE_EXP = "STATE_EXP"	--使用经验强化

function CardComposeScene:ctor()
    self.title = getTextByKey("cardEnhance_Title")
    self.mainUI = nil   
    self.mainCardId = nil
    self.mainCard = nil
    self.mainCardMetaId = nil
    
    self.matterCard = {}
    self.bigCirclePos   = {}
    self.smallCirclePos = {}
    self.points = {}
	self.pointsTable = {}
    self.centerPoint = {}   --中心坐标
    self.radiusB     = 230--225  --大圈半径
    self.radiusS     = 200  --小圈半径
    self.matterCardNum = 0
    self.matterTable = {}
    self.flashFrame1 = nil
    self.flashFrame2 = nil
    self.flashFinish = nil
    self.gameInitData = nil
    self.need_coins = nil
	self.run_animation = nil;
	self.enableRotation = false
	self.maxCardLevel = 0

	self.currentTargetLevel = 0 --武将经验强化 当前选择的等级
end


function CardComposeScene:getCardInfoFromInitData(cardId)
    self.GameInitData = DataManager.getGameInitData()
    local aCard = {}    
    for _, temp in ipairs(self.GameInitData.sharkCards.sharkCards) do
        if cardId == temp.cardId then
          aCard = temp
          break
        end
    end
    return aCard
end
function CardComposeScene:getComposeExp(mainCardId,matterCard)
    local needUpgradeCoin = 0
    local ret = {newLevel=nil,upgradeCoin=nil}
    local aCard = self:getCardInfoFromInitData(mainCardId)
    local aCardLevelConfig = MetaManager.card_level[aCard.level]
    local mainCardExp = aCardLevelConfig.totalExp + aCard.exp --主卡经验 = 总经验+当前经验
	self.oldCardExp = aCard.exp
    --print(table.tostring(aCardLevelConfig))
    --print(table.tostring(aCard))
    local resultAllExp = mainCardExp 
    if type(matterCard) == "table" then 
        for key,card in pairs(matterCard) do 
            local mCard = self:getCardInfoFromInitData(card.cardId)
            local matterCardLevelConfig = MetaManager.card_level[mCard.level]
            local basicExp = MetaManager.card_meta[mCard.metaId].basicExp
            local matterCardExp = matterCardLevelConfig.totalExp + mCard.exp
            --获得经验=基本经验+总经验×系数
            local getTotalExp = basicExp + (matterCardExp*matterCardLevelConfig.expConvertCoefficient)
            resultAllExp = resultAllExp + getTotalExp
            needUpgradeCoin = needUpgradeCoin + getTotalExp * MetaManager.game_meta.gameSettingConfig.cardUpgradeCoinRevise
            --print(resultAllExp,getTotalExp)
        end
    end
	local cardMaxLevel = MetaManager.card_evolve[MetaManager.card_meta[aCard.metaId].evolutionLevel].maxCardLevel
    for index,v in ipairs(MetaManager.card_level) do
        if index==#MetaManager.card_level and resultAllExp>v.totalExp then 
			self.expOverFlow = true;
			ret.newLevel = v.level
            ret.upgradeCoin = math.floor(needUpgradeCoin)
            break
        end
        if resultAllExp>=v.totalExp and resultAllExp<MetaManager.card_level[index+1].totalExp then 
            ret.newLevel = v.level
            ret.upgradeCoin = math.floor(needUpgradeCoin)
            break        
        end
    end     
	if ret.newLevel > cardMaxLevel then
		ret.newLevel = cardMaxLevel
	end
    --print(table.tostring(ret))
    return ret 
end

function CardComposeScene:create(argv)
    if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={state = CardComposeScene.STETE_CARD}}
    end
    local s = CardComposeScene.new()
    s:initScene()
    return s
end

function CardComposeScene:getCirclePosition()
    for i = 1,cardNum do
        local angle = i*(360/cardNum) - 90
        local posX_B = self.centerPoint.x + self.radiusB * math.cos(math.rad(angle))
        local posY_B = self.centerPoint.y + self.radiusB * math.sin(math.rad(angle))
        local posX_S = self.centerPoint.x + self.radiusS * math.cos(math.rad(angle))
        local posY_S = self.centerPoint.y + self.radiusS * math.sin(math.rad(angle))        
        table.insert(self.bigCirclePos  ,{x=posX_B,y=posY_B})
        table.insert(self.smallCirclePos,{x=posX_S,y=posY_S})
    end

    --移位
    for j=1,4 do 
        self.points[j] = self.bigCirclePos[j]    
    end 
    for k=5,9 do 
        self.points[k] = self.smallCirclePos[k-4]
    end
    self.points[10] = self.bigCirclePos[5]
end

function CardComposeScene:getCirclePositionTable(matterAmount)
	self.pointsTable = {}
	local mattersOnSmallCircle = 0
	if matterAmount >= cardNum then
		mattersOnSmallCircle = matterAmount - cardNum-- + 1
	end
	if mattersOnSmallCircle > cardNum then
		mattersOnSmallCircle = cardNum
	end
	local mattersOnBigCircle = matterAmount - mattersOnSmallCircle
	if mattersOnBigCircle > cardNum then
		mattersOnBigCircle = cardNum
	end
	self.pointsTable[0] = {}
	self.pointsTable[0].isBigCircle = true
	self.pointsTable[0].angle = -90
	local leftMattersOnSmallCircle = mattersOnSmallCircle
	local leftMattersOnBigCircle = mattersOnBigCircle
	for i = 1, matterAmount
	do
		if leftMattersOnSmallCircle > 0 then
			self.pointsTable[i] = {}
			self.pointsTable[i].isBigCircle = false
			self.pointsTable[i].angle = 90 - (360 / mattersOnSmallCircle) * (mattersOnSmallCircle - leftMattersOnSmallCircle)
			leftMattersOnSmallCircle = leftMattersOnSmallCircle - 1;
		elseif leftMattersOnBigCircle > 0 then
			self.pointsTable[i] = {}
			self.pointsTable[i].isBigCircle = true
			local cardsAmount = mattersOnBigCircle + 1
			if cardsAmount > cardNum then
				cardsAmount = cardNum
			end
			self.pointsTable[i].angle = 270 - (360 / cardsAmount) * (mattersOnBigCircle - leftMattersOnBigCircle + 1)
			leftMattersOnBigCircle = leftMattersOnBigCircle - 1
		end
	end
end

function CardComposeScene:getPositionByPointsTableIndex(index)
	local posX,posY = 0, 0
	
	if self.pointsTable[index] then
		if self.pointsTable[index].isBigCircle then
			posX = self.centerPoint.x + self.radiusB * math.cos(math.rad(self.pointsTable[index].angle))
			posY = self.centerPoint.y + self.radiusB * math.sin(math.rad(self.pointsTable[index].angle))
		else
			posX = self.centerPoint.x + self.radiusS * math.cos(math.rad(self.pointsTable[index].angle))
			posY = self.centerPoint.y + self.radiusS * math.sin(math.rad(self.pointsTable[index].angle))   
		end
	end
	
	return posX,posY
end

function CardComposeScene:moveToTower()
  --[[
  local userData = DataManager.getCurrUser()
  local function Success(event)
    if event ~= nil then
      DataManager.GetBabelInfoData = event.data
      DataManager.GetBabelInfoData._DownloadDataTime = TimeUtil.getServerTimeSeconds()
    end
    local newScene = SkyTowerMainScene:create()
    newScene:setBackScene( "CardComposeScene" ) --设置返回的Scene
    Director:sharedDirector():replaceScene( newScene )
  end
  local function Failed(event)
    if event.data == 713103 then
      SuspensionLabel:showContent(self, Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel}))
    end
  end
    
  if (userData.level >= MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel) then
    local params = {}
    local getBabelInfoRequest = GetBabelInfoRequest.new(params, rpc.SendingPriority.kHigh)
    getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoSucceed, Success)
    getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoFailed, Failed)
    getBabelInfoRequest:start()
  else
    SuspensionLabel:showContent(self, Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel}))
  end]]
  ChallengeEntersScene.readyToNewBabelEnterPanel()
end

function CardComposeScene:resetMattersPosition()
	local function onClickRemoveMatterCard(e)
		if self.pointsTable[e.context].isBigCircle then
			table.remove(self.matterCard, e.context)
			self:resetMattersPosition();
			if #self.matterCard == 0 then
				self.btStartCompose:setEnable(false)
				self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("btn_cardEnhance_Btn"):getChildByName("btn"):setVisible(false)
			end
		end
	end

	if type(self.matterCard)~="table"  then
		self.matterCard = {}
	end
	self:getCirclePositionTable(#self.matterCard)
	
	self.matterCardNum = #self.matterCard
	
	if type(self.matterTable) == "table" then
		for k, v in ipairs(self.matterTable)
		do
			self.mainUI:removeChild(v)
		end
	end
	
	self.matterTable = {}
	
	local showMax = #self.matterCard
	if showMax > 10 then
		showMax = 10
	end
	for index = showMax,1,-1
	do
		local card = self.matterCard[index]
		local matter = getSmallCanonCardNoInfoByMetaId(tonumber(card.metaId))
        local aCard = MetaManager.card_meta[tonumber(card.metaId)]
       -- matter:load("card/card/"..tostring(aCard.figureId).."/", "full")
        matter:setPosition(ccp(self:getPositionByPointsTableIndex(index)))
        matter:setScale(0.6)
		--local buttonMatter = Button:create(matter)
		--buttonMatter:addEventListener(Events.kStart, onClickRemoveMatterCard, index)
        self.matterTable[index] = matter
        self.mainUI:addChildAt(matter, self.mainUI:getChildByName("card_add_M"):getZOrder() + 1) 
	end
	
	if self.matterCardNum > 0 then
		if self.matterCardNum >= cardNum * 2 then
			self.mainUI:getChildByName("card_add_M"):setVisible(false)
		else
			--self.mainUI:getChildByName("card_add_M"):setVisible(true)
			--self.mainUI:getChildByName("card_add_M"):setPosition(ccp(self:getPositionByPointsTableIndex(0)))
		end
		--UI显示
        local masterCardId = HeMemDataHolder:getInteger("CardCompose_MainCardId")
        local result = self:getComposeExp(masterCardId,self.matterCard)
        self.need_coins = tonumber(self.gameInitData.sharkUser.coins - result.upgradeCoin)
		self.useCoin = result.upgradeCoin
        self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_equip_CoinConsume_num"):getChildByName("font"):setString(tostring(result.upgradeCoin))
        if self.need_coins < 0 then
			self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_equip_CoinConsume_num"):getChildByName("font"):setColor(ccc3(217, 0, 0))
		else
			self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_equip_CoinConsume_num"):getChildByName("font"):setColor(ccc3(0, 0, 0))
		end
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_equip_CoinConsume"):setVisible(true)
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_icon_sliver_coin"):setVisible(true)
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_equip_CoinConsume_num"):setVisible(true)
		local cardInfo = self:getCardInfoFromInitData(masterCardId)
        cardInfo.level = result.newLevel 
        local newResult = CommonManager:getCardPropertiesWithSharkCard(cardInfo)
        self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_lv_num_R"):getChildByName("font"):setString(tostring(newResult.level))
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_equip_lv_num_white_r"):getChildByName("font"):setString("/" .. self.maxCardLevel)
        self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_atk_add_num"):getChildByName("font"):setString(tostring(math.floor(newResult.att)))
        self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_def_add_num"):getChildByName("font"):setString(tostring(math.floor(newResult.def)))
        self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_hp_add_num"):getChildByName("font"):setString(tostring(math.floor(newResult.hp)))
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line1"):setVisible(false)
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line2"):setVisible(false)
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):setVisible(true)
	else
		self.mainUI:getChildByName("card_cardEnhance_unselect"):setVisible(true)
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):setVisible(false)
	end
        
end

--卡牌合成
function onClickStartCompose(e)
	if  not (e.context.mainCardMetaId >0) or not (e.context.matterCardNum > 0) then
		return false
	end
		
    if e.context.need_coins < 0 then 
        e.context.targetInfoPanel = MessageBoxPanel:create(e.context, MessageBoxType.kCoinLimit, {setTargetInfoPanelNil = true})
		e.context:addChild(e.context.targetInfoPanel)
		e.context.targetInfoPanel:scaleIn()
        return false
    end
		
	--[[if not e.ignoreMatterCardRare then
		for k, v in pairs(e.context.matterCard)
		do
			if MetaManager.card_meta[v.metaId].rare >= SUGGESTION_RARE then
				e.context.targetInfoPanel = MessageBoxPanel:create(e.context, MessageBoxType.kCardComposeRareCardWarning, {setTargetInfoPanelNil = true})
				e.context:addChild(e.context.targetInfoPanel)
				e.context.targetInfoPanel:scaleIn()
				return false
			end
		end
	end--]]
	
	--[[if not e.ignoreExp then
		if e.context.expOverFlow then
			e.context.targetInfoPanel = MessageBoxPanel:create(e.context, MessageBoxType.kCardComposeExpWarning, {setTargetInfoPanelNil = true})
			e.context:addChild(e.context.targetInfoPanel)
			e.context.targetInfoPanel:scaleIn()
			return false
		end
	end--]]
		
    if e.context.mainCardMetaId > 0 and type(e.context.matterCard)=="table" and #e.context.matterCard>0 then
		local curContext = e.context
		
			    --动画完成
		local function onFlashAnimationEnd(event)
			if curContext.flashFinish then
				curContext.flashFinish:unregisterEndAnimationScriptHandler()
			end
			HeMemDataHolder:deleteByKey("matterCard")
			local argv = {enterScene="CardComposeScene",returnScene="CardComposeScene",params={preReturnScene = curContext.argv.returnScene, state = curContext.currentState}}
			curContext:replaceScene( CardEvolveResultScene , argv)
		end
		
		local function CardComposeFailed(params)
			curContext.waitResponse = false;
			curContext.targetInfoPanel = curContext.prePanel
			curContext:setTouchEnabled(true)
			if params.data == 710512 then
				curContext.targetInfoPanel = MessageBoxPanel:create(curContext, MessageBoxType.kCoinLimit, {setTargetInfoPanelNil = true})
				curContext:addChild(curContext.targetInfoPanel)
				curContext.targetInfoPanel:scaleIn()
			end
		end
		
        local function CardComposeCallback(params)
			g_previousBattleCount = CommonManager:getLocalPlayerStrength()
			local dirtyCardIds = {}
			table.insert(dirtyCardIds, HeMemDataHolder:getInteger("CardCompose_MainCardId"))
			local mainCardData = HeMemDataHolder:getString("matterCard")
			local matterCardTable = {}
			if type(mainCardData)=="string" and mainCardData~="" then
				matterCardTable = table.deserialize(mainCardData) --table
			end
			
			for k, v in pairs(matterCardTable)
			do
				table.insert(dirtyCardIds, v.cardId)
			end
			
			CommonManager:setCardNeedUpdate(dirtyCardIds)
			
			curContext.waitResponse = false;
            curContext.mainCard:setVisible(false)
            curContext:setTouchEnabled(false)
            for i,obj in ipairs(curContext.matterTable) do 
                if obj ~= nil then 
                obj:setVisible(false)
                end
            end    
            --动画
			CanonPlayEffect("music/sfx_card_compound.wav")
			curContext.flashFinish = FlashSprite:create("EVO2/FZZZ_EXX")   
			curContext.flashFinish:setLoop(false)
              --换牌
            local newMetaId = params.data.sharkCard.metaId                
            HeMemDataHolder:setInteger( "CardCompose_NewMetaId",newMetaId )
            local masterCardId = HeMemDataHolder:getInteger("CardCompose_MainCardId")
            local result = CommonManager:getCardPropertiesWithCardId(masterCardId)
			result.exp = curContext.oldCardExp
            HeMemDataHolder:setString( "CardCompose_oldSharkCard",table.serialize(result) )
            HeMemDataHolder:setString( "CardCompose_newSharkCard",table.serialize(params.data.sharkCard) )
            local card1_spf = getCardSpriteFrame(newMetaId)  
            curContext.flashFinish:addChangeInstance("card1", card1_spf)
			local tmeta = MetaManager.card_meta[tonumber(newMetaId)]
			local countrySpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryCircle_" .. tmeta.country .. ".png")
			curContext.flashFinish:addChangeInstance("countrycircle1", countrySpriteFrame)
			local boardSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(BigBorderDict[tmeta.rare])
			curContext.flashFinish:addChangeInstance("cardBorder1", boardSpriteFrame)
			local cardBgSpriteFrame = createSpriteFrame("card/background/" .. tmeta.backgroundName)
			curContext.flashFinish:addChangeInstance("cardBg1", cardBgSpriteFrame)
			
			curContext.flashFinish:changeAnimation(2)
			--curContext.flashFinish:setPosition(-10,40)
			curContext.flashFinish:registerEndAnimationScriptHandler(onFlashAnimationEnd)
			curContext:addChild(CocosObject.new(curContext.flashFinish))     
			
			local mainCardId = HeMemDataHolder:getInteger("CardCompose_MainCardId")
			local matterCard = curContext.matterCard
			
			local cardData = DataManager.getCardsData()
			local toremoveKeys = {}
			for k,card in ipairs(cardData)
			do
				if card.cardId == mainCardId then
					cardData[k] = params.data.sharkCard
					--如果是阵列中的卡牌，就清空g_previousBonusTable
					local queueData = {}
					local matrixCardData = CommonManager:getMatrixCardData()
					for k,v in ipairs(matrixCardData) do 
						if not queueData[v] then
							queueData[v] = k + 100
						end
					end
					if queueData[card.cardId] and queueData[card.cardId] > 100 then
						g_previousBonusTable = nil;
					end
				else
					for key, mCard in pairs(matterCard)
					do
						if card.cardId == mCard.cardId then
							table.insert(toremoveKeys, k)
							break;
						end
					end
				end
			end
			for i = #toremoveKeys, 1, -1
			do
				table.remove(cardData, toremoveKeys[i])
			end
			DataManager.setCardsData(cardData)
			local rewardTable = {}
			table.insert(rewardTable, {itemType = ResourceEnum.COIN, amount = -curContext.useCoin})
			RewardManager:getReward(rewardTable)
        end    
		local masterId = HeMemDataHolder:getInteger("CardCompose_MainCardId")
		local slaveIds = {}
		for _, value in pairs(curContext.matterCard) do
			table.insert(slaveIds, value.cardId)
		end
		
		if curContext.waitResponse then
			do return end
		end
		
        --发送请求      
		curContext.waitResponse = true
		curContext.prePanel = curContext.targetInfoPanel
		curContext.targetInfoPanel = true
        local params={masterId=masterId, slaveIds=slaveIds}
        local request = CardComposeRequest.new( params, rpc.SendingPriority.kHigh )
        request:addEventListener( RequestNotifyEnum.CardComposeSucceed, CardComposeCallback )
        request:addEventListener( RequestNotifyEnum.CardComposeFailed, CardComposeFailed )
        request:start()     
    else
        --CCMessageBox("Please choose your cards!","Canon")
    end
end

function CardComposeScene:onInit()
    --print(table.tostring(self.argv))
    self.gameInitData = DataManager.getGameInitData()
	BaseUIScene.initBackGround(self)
	
	local bg = Sprite:create("pic/nicebg.png")
	bg:setScale(2)
	local winSize = CCDirector:sharedDirector():getWinSize()
	bg:setPosition(ccp(winSize.width / 2 , winSize.height / 2 - 25))
	self:addChild(bg)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/card_new.json")
	builder.useArtLabelTTF = true
    self.mainUI = builder:build("card_cardEnhance")    
	
	--大卡牌背景的注册点翻转
	local function changeRotatedR(bgR, num)
		bgR.refCocosObj:setAnchorPoint(ccp(0.5, 0.5))
		local contentSize = bgR.refCocosObj:getContentSize()
		local curPosX,curPosY = bgR.refCocosObj:getPosition()
		if num == 2 then
			bgR:setPosition(ccp(curPosX - contentSize.width / 2 , curPosY - contentSize.height / 2))
		elseif num == 3 then
			bgR:setPosition(ccp(curPosX + contentSize.width / 2 , curPosY + contentSize.height / 2))
		elseif num == 4 then
			bgR:setPosition(ccp(curPosX - contentSize.width / 2 , curPosY + contentSize.height / 2))
		end
	end
	changeRotatedR(self.mainUI:getChildByName("card_add_B"):getChildByName("card_bg_evolve_add"):getChildByName("bg_evolve_add_2"), 2)
	changeRotatedR(self.mainUI:getChildByName("card_add_B"):getChildByName("card_bg_evolve_add"):getChildByName("bg_evolve_add_3"), 3)
	changeRotatedR(self.mainUI:getChildByName("card_add_B"):getChildByName("card_bg_evolve_add"):getChildByName("bg_evolve_add_4"), 4)
	changeRotatedR(self.mainUI:getChildByName("card_add_B"):getChildByName("card_frame_evolve_add"):getChildByName("frame_evolve_add_3"), 2)
	changeRotatedR(self.mainUI:getChildByName("card_add_B"):getChildByName("card_frame_evolve_add"):getChildByName("frame_evolve_add_2"), 3)
	changeRotatedR(self.mainUI:getChildByName("card_add_B"):getChildByName("card_frame_evolve_add"):getChildByName("frame_evolve_add_4"), 4)
	
	--设置无锯齿 以防拼接处出现裂缝
	self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_bg_cardEvolve_middle_R").refCocosObj:getTexture():setAliasTexParameters();
	
	self.levelL = self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_lv_num_L")
	self.levelR = self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_lv_num_R")
	self.levelL:getChildByName("font"):setDimensions(CCSizeMake(0, self.levelL:getChildByName("font"):getDimensions().height))
	self.levelR:getChildByName("font"):setDimensions(CCSizeMake(0, self.levelR:getChildByName("font"):getDimensions().height))
	self.levelMaxL = self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_equip_lv_num_white_l")
	self.levelMaxR = self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_equip_lv_num_white_r")
	
	-----------------------------
    local frameBig = self.mainUI:getChildByName("card_frameB"):getPosition()
    self.centerPoint = {x = frameBig.x , y=frameBig.y}
    self:getCirclePosition()
    --print(table.tostring(self.bigCirclePos))
    --从卡牌详情进入
    if self.argv.enterScene=="CardInfoPanel" then
        HeMemDataHolder:setInteger("CardCompose_MainCardId", self.argv.params.cardId)
        HeMemDataHolder:setInteger("CardCompose_MainCardMetaId", self.argv.params.metaId)
        self.mainUI:getChildByName("card_add_B"):setVisible(false)
    end
    --从背包进入
    if self.argv.enterScene=="BackpackScene" and self.argv.params.cardType=="mainCard" then
        HeMemDataHolder:setInteger("CardCompose_MainCardId", self.argv.params.cardId)
        HeMemDataHolder:setInteger("CardCompose_MainCardMetaId", self.argv.params.metaId)
        self.mainUI:getChildByName("card_add_B"):setVisible(false)
    end
    if self.argv.enterScene=="CardStrenthenSelectScene" and self.argv.params.cardType=="matterCard" then
        self.matterCard = {}
        
        for index,value in pairs(self.argv.params.matterCard) do 
			--[[if #self.matterCard >= 10 then
				break;
			end--]]
            table.insert(self.matterCard,{cardId=value.cardId,metaId=value.metaId})
        end
        HeMemDataHolder:setString("matterCard", table.serialize(self.matterCard))
    end    

    self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_btn_cardEnhance_Btn"):getChildByName("txt_cardEnhance_Btn"):setString(getTextByKey("cardEnhance_Btn"))
    self.mainUI:getChildByName("card_frameB"):setVisible(false)
    self.mainUI:getChildByName("card_frameM"):setVisible(false)
    --self.mainUI:getChildByName("card_add_M"):setPosition(ccp(self.points[10].x,self.points[10].y))
	self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line1"):getChildByName("txt_cardEnhance_unselect_line1"):setString(getTextByKey("cardEnhance_noCardText"))
	local unselectLine2 = self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line2"):getChildByName("txt_cardEnhance_unselect_line2")
	unselectLine2:setDimensions(CCSizeMake(unselectLine2:getDimensions().width,0))
	unselectLine2:setString(getTextByKey("cardEnhance_noSubCardText"));
	self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line2"):setVisible(false)
	self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_btn_cardChoose_Btn"):getChildByName("txt_cardEnhance_Btn"):setString(getTextByKey("cardEnhance_SelectSubCard"))
	self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_equip_CoinConsume"):getChildByName("txt_equip_CoinConsume"):setString(getTextByKey("cardEnhance_CoinConsume"))
	self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_equip_CoinConsume_num"):getChildByName("font"):setString(0)
	self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_equip_CoinConsume"):setVisible(false)
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_icon_sliver_coin"):setVisible(false)
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_equip_CoinConsume_num"):setVisible(false)
	
	self.flashFrame1 = FlashSprite:create("EVO2/FZZZ_EXX")   
    self.flashFrame1:changeAnimation(0)
    self.flashFrame1:setPosition(-10,40)
    self:addChild(CocosObject.new(self.flashFrame1))    
    self.flashFrame2 = FlashSprite:create("EVO2/FZZZ_EXX")   
    self.flashFrame2:changeAnimation(1)
    self.flashFrame2:setPosition(-10,40)
    self:addChild(CocosObject.new(self.flashFrame2)) 
    --显示主卡
    self.mainCardMetaId = HeMemDataHolder:getInteger("CardCompose_MainCardMetaId")
	local masterCardId = HeMemDataHolder:getInteger("CardCompose_MainCardId")
	local cardStillExist = false
	local cardData = DataManager.getCardsData()
	for _, temp in ipairs(cardData) do
		if masterCardId == temp.cardId then
			cardStillExist = true
			if self.mainCardMetaId ~= temp.metaId then
				self.mainCardMetaId = temp.metaId
				HeMemDataHolder:setInteger("CardCompose_MainCardMetaId", self.mainCardMetaId)
			end
			break
		end
	end
	if masterCardId <= 0 or not cardStillExist then
		print("only metaId no cardId")
		self.mainCardMetaId = 0
		HeMemDataHolder:deleteByKey("CardCompose_MainCardMetaId")
	end
    if self.mainCardMetaId >0 then 
    	--存在主卡?
        self.mainCard = getBigCanonCardNoInfoByMetaId(tonumber(self.mainCardMetaId))
        local aCard = MetaManager.card_meta[tonumber(self.mainCardMetaId)]
        --self.mainCard:load("card/card/"..tostring(aCard.figureId).."/", "full")
        self.mainCard:setPosition( ccp(self.mainUI:getChildByName("card_frameB"):getPositionX(),self.mainUI:getChildByName("card_frameB"):getPositionY()) )
        self.mainCard:setScale(0.6)
        self.mainUI:getChildByName("card_frameB"):setVisible(false)
        self.mainUI:getChildByName("card_add_B"):setVisible(false)
        --主卡属性
        local masterCardId = HeMemDataHolder:getInteger("CardCompose_MainCardId")
        local result = CommonManager:getCardPropertiesWithCardId(masterCardId) 
        self.maxCardLevel = MetaManager.card_evolve[aCard.evolutionLevel].maxCardLevel
        self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_lv_num_L"):getChildByName("font"):setString(tostring(result.level))
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_equip_lv_num_white_l"):getChildByName("font"):setString("/" .. self.maxCardLevel)
        self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_atk_num"):getChildByName("font"):setString(tostring(math.floor(result.att)))
        self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_def_num"):getChildByName("font"):setString(tostring(math.floor(result.def)))
        self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_cardEvolve_preview"):getChildByName("card_txt_icon_hp_num"):getChildByName("font"):setString(tostring(math.floor(result.hp)))                 
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line2"):setVisible(true)
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line1"):setVisible(false)
	else
        self.mainUI:getChildByName("card_add_M"):setVisible(false)
        self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line1"):setVisible(true)
    end
    --显示素材卡
    local mainCardData = HeMemDataHolder:getString("matterCard")
    if type(mainCardData)=="string" and mainCardData~="" then
        self.tmatterCard = table.deserialize(mainCardData) --table
    end
	
	self.matterCard = {}
	
	if type(self.tmatterCard) == "table" then
		for k,v in pairs(self.tmatterCard)
		do
			local cardStillExist = false
			local cardData = DataManager.getCardsData()
			for _, temp in ipairs(cardData) do
				if v.cardId == temp.cardId then
					cardStillExist = true
					break
				end
			end
			if v.cardId > 0 and cardStillExist then
				table.insert(self.matterCard, v)
			end
		end
		
	end
	
	
	self:resetMattersPosition()
	self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_stage_name"):getChildByName("txt"):setString(getTextByKey("cardEnhance_selectedNum") .. table.getn(self.matterCard))
    
	self.levelMaxL:setPosition(ccp(self.levelL:getPositionX() + self.levelL:getChildByName("font"):getContentSize().width + 3, self.levelMaxL:getPositionY()))
	self.levelMaxR:setPosition(ccp(self.levelR:getPositionX() + self.levelR:getChildByName("font"):getContentSize().width + 3, self.levelMaxR:getPositionY()))
	
    --选择主卡
    local function onClickAddMainCard(e)		
        local function filterMainCardFunc( cardList )
            local result = {}
			
			local masterCardId = HeMemDataHolder:getInteger("CardCompose_MainCardId")
			
            for k,card in pairs(cardList) do
                local evolutionLevel = MetaManager.card_meta[card.metaId].evolutionLevel
                local maxCardLevel = MetaManager.card_evolve[evolutionLevel].maxCardLevel
                if tonumber(card.level) < tonumber(maxCardLevel) and tonumber(card.cardId) ~= tonumber(masterCardId) then
					if ItemManager.checkCardTypeCanUpgrade(card.metaId) then
						--卡牌类型允许强化 add by czh @ 2014-8-15 16:46:09
						local existInMatterCard = false
						for key,value in pairs(self.matterCard)
						do
							if value.cardId == card.cardId then
								existInMatterCard = true;
								break;
							end
						end
						if not existInMatterCard then
							table.insert(result,card)
						end
					end
                end
            end
            return result
        end
        local argv = {enterScene="CardComposeScene",returnScene="CardComposeScene",params={
		cardType="mainCard",filter=BACKPACK_FILTER.CARD,filterFunc = filterMainCardFunc, sortOrder = SORT_ORDER.DESC,sortIndex = 2,
		preReturnScene = self.argv.returnScene,isCardTrain = false, state = self.currentState
		}}
        self:replaceScene( BackpackScene , argv)
    end
    --选择素材卡
    local function onClickMatterCard(e)
		if self.mainCardMetaId >0 then
			local function filterMatterCardFunc( cardList )
				local result = {}
				
				local queueData = CommonManager.getQueueData()
				for k, v in pairs(CommonManager:getMatrixCardData()) do
					table.insert(queueData, v)
				end
				local mainCardId = HeMemDataHolder:getInteger("CardCompose_MainCardId")
				local masterCardGroupId = MetaManager.card_meta[self.mainCardMetaId].cardGroupId
				for k,card in pairs(cardList) do
					local found = false
					local slaveCardGroupId  = MetaManager.card_meta[card.metaId].cardGroupId
					if masterCardGroupId == slaveCardGroupId then
						found = true
					elseif mainCardId == card.cardId then
						found = true;
					else
						for _,value in pairs(queueData)
						do
							if tonumber(value) == card.cardId then
								found = true;
							end
						end
					end

					if not ItemManager.checkCardTypeCanUseToUpgrade(card.metaId) then
						--卡牌类型不允许作为强化材料 add by czh @ 2014-8-15 16:46:09
						found = true
					end

					if not found then
						table.insert(result,card)
					end
				end
				return result
			end     
			self.notDeleteCardInfo = true
			local argv = {enterScene="CardComposeScene",returnScene="CardComposeScene",params={
			cardType="matterCard",filterFunc = filterMatterCardFunc, 
			preReturnScene = self.argv.returnScene, mainCardId = HeMemDataHolder:getInteger("CardCompose_MainCardId"), mainCardMetaId = self.mainCardMetaId
			}}
			self:replaceScene( CardStrenthenSelectScene , argv)
		end
    end
    
	self.mainUI:getChildByName("card_add_M"):setVisible(false)
   -- local btnAddMatterCard = Button:create(self.mainUI:getChildByName("card_add_M"))    
    local btStartCompose  = Button:create(self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_btn_cardEnhance_Btn"), true)  
    
    local btnAddMainCard = Button:create(self.mainUI:getChildByName("card_add_B"))
    btnAddMainCard:addEventListener(Events.kStart, onClickAddMainCard)
	if self.mainCard then
		local btnClickCard = Button:create(self.mainCard)
		btnClickCard:addEventListener(Events.kStart, onClickAddMainCard)
	end
    --btnAddMatterCard:addEventListener(Events.kStart, onClickMatterCard)
    btStartCompose:addEventListener(Events.kStart, onClickStartCompose, self)  
	
	if self.mainCardMetaId > 0 and self.matterCardNum > 0 then
		btStartCompose:setEnable(true)
	else
		btStartCompose:setEnable(false)
	end	
	self.btStartCompose = btStartCompose
	
	local unselectAddMatterCard = Button:create(self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_btn_cardChoose_Btn"))
	unselectAddMatterCard:addEventListener(Events.kStart, onClickMatterCard)
	
	if self.mainCardMetaId <=0 then
		unselectAddMatterCard:setEnable(false)
		self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_btn_cardChoose_Btn"):getChildByName("btn"):setVisible(false)
	end

	--经验强化相关的一些静态多语言
	local infosDisplay = self.mainUI:getChildByName("card_cardEnhance_unselect")
	infosDisplay:getChildByName("card_other_upgrade_in"):getChildByName("txt_other_upgrade7"):getChildByName("txt"):setString(getTextByKey("cardEnhance_levelUp"))--将此武将升至
	infosDisplay:getChildByName("card_other_upgrade_in"):getChildByName("btn_other_upgrade1"):getChildByName("txt"):setString("-10")
	infosDisplay:getChildByName("card_other_upgrade_in"):getChildByName("btn_other_upgrade2"):getChildByName("txt"):setString("-1")
	infosDisplay:getChildByName("card_other_upgrade_in"):getChildByName("btn_other_upgrade3"):getChildByName("txt"):setString("+1")
	infosDisplay:getChildByName("card_other_upgrade_in"):getChildByName("btn_other_upgrade4"):getChildByName("txt"):setString("+10")

	infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade4"):getChildByName("txt"):setString(getTextByKey("cardEnhance_levelPreview1"))--可升至{num}
	infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade6"):getChildByName("txt"):setString(getTextByKey("cardEnhance_levelPreview2"))--级
	infosDisplay:getChildByName("card_btn_cardEnhance_Btn2"):getChildByName("txt_cardEnhance_Btn"):setString(getTextByKey("cardEnhance_Btn"))--开始合成

	--经验强化相关按钮
	self.btnExpCompose = Button:create(infosDisplay:getChildByName("card_btn_cardEnhance_Btn2"), true)
	self.btnExpCompose:addEventListener(Events.kStart, CardComposeScene.onClickExpCompose, self)

	self.btnCutMore = Button:create(infosDisplay:getChildByName("card_other_upgrade_in"):getChildByName("btn_other_upgrade1"), true)
	self.btnCutMore:addEventListener(Events.kStart, CardComposeScene.onClickCutMore, self)
	self.btnCutLess = Button:create(infosDisplay:getChildByName("card_other_upgrade_in"):getChildByName("btn_other_upgrade2"), true)
	self.btnCutLess:addEventListener(Events.kStart, CardComposeScene.onClickCutLess, self)
	self.btnAddLess = Button:create(infosDisplay:getChildByName("card_other_upgrade_in"):getChildByName("btn_other_upgrade3"), true)
	self.btnAddLess:addEventListener(Events.kStart, CardComposeScene.onClickAddLess, self)
	self.btnAddMore = Button:create(infosDisplay:getChildByName("card_other_upgrade_in"):getChildByName("btn_other_upgrade4"), true)
	self.btnAddMore:addEventListener(Events.kStart, CardComposeScene.onClickAddMore, self)

	--切换按钮
	self.changeStateBtnDisplay = self.mainUI:getChildByName("btn_change_up")
	local btnChangeState = Button:create(self.changeStateBtnDisplay)
	btnChangeState:addEventListener(Events.kStart, CardComposeScene.onClickChangeState, self)

	--一些基本属性的初始化	
	--当前拥有经验
	self.currentExp = CanonGoodIcon.getResourceNum(ResourceEnum.GENERALEXP)
	local masterCardId = HeMemDataHolder:getInteger("CardCompose_MainCardId")
	--print("masterCardId = " .. masterCardId)
	local mCard = self:getCardInfoFromInitData(masterCardId)
	self.currentCardData = nil
	if masterCardId and (masterCardId ~= 0) and (mCard.metaId ~= nil) then
		--print("mCard = " .. table.tostring(mCard))
		self.currentCardData = mCard
		--print("MetaManager.card_meta[mCard.metaId].evolutionLevel = " .. MetaManager.card_meta[mCard.metaId].evolutionLevel)
		local cardMaxLevel = MetaManager.card_evolve[MetaManager.card_meta[mCard.metaId].evolutionLevel].maxCardLevel

		--卡牌当前等级
		self.currentLevel = mCard.level
		--可升级至的最高等级
		self.maxLevel = cardMaxLevel
		--print("self.maxLevel = " .. self.maxLevel)
		--更新最大等级
		local totalExp = self.currentExp + mCard.exp + MetaManager.card_level[self.currentLevel].totalExp --可以支配的总经验 = 已有经验 + 主卡经验(=卡牌总经验+当前经验)
		--print("totalExp = " .. totalExp)
	    for index,v in ipairs(MetaManager.card_level) do
	    	if v.level < self.maxLevel then
		        if index==#MetaManager.card_level and totalExp>v.totalExp then 
					self.maxLevel = v.level
					--print("v.level = " .. v.level)
		            break
		        end
		        if totalExp>=v.totalExp and totalExp<MetaManager.card_level[index+1].totalExp then 
		            self.maxLevel = v.level
					--print("v.level2 = " .. v.level)
		            break        
		        end
		    end
	    end
		--print("self.maxLevel = " .. self.maxLevel)
	else
		--卡牌当前等级
		self.currentLevel = 0
		--可升级至的最高等级
		self.maxLevel = 0
	end
	

	--默认情况
	if self.argv.params.state == nil then
		self.argv.params.state = CardComposeScene.STETE_CARD
	end
	--设置当前状态
	self:changeShowState(self.argv.params.state)
	
    self:addChild(self.mainUI)
	if self.mainCard then
		self:addChild(self.mainCard) 
	end

	BaseUIScene.onInit(self)
    local angle = 0
    local angleValue=0
    local function tick()
		if not self.enableRotation then
			return
		end
		local rotateBigCircle = false;
		if #self.matterCard >= 1 then--cardNum * 2 then
			rotateBigCircle = true;
		end
		
		for k, v in ipairs(self.pointsTable)
		do
			if v.isBigCircle and rotateBigCircle then
				v.angle = v.angle - 0.2
			elseif not v.isBigCircle then
				v.angle = v.angle + 0.2
			end
			local cardMatter = self.matterTable[k]
			cardMatter:setPosition(ccp(self:getPositionByPointsTableIndex(k)))
		end
    end
	self.run_animation = scheduler:scheduleScriptFunc(tick, 0 , false)   

	--切换按钮层级提高
	self.mainUI:removeChild(self.changeStateBtnDisplay, false)
	self:addChild(self.changeStateBtnDisplay)
end

function CardComposeScene:changeShowState(aState)
	self.currentState = aState
	local infosDisplay = self.mainUI:getChildByName("card_cardEnhance_unselect")
	if aState == CardComposeScene.STETE_CARD then
		--用卡牌强化状态
		infosDisplay:getChildByName("card_txt_stage_name"):setVisible(true)
		infosDisplay:getChildByName("card_stage_name_bg"):setVisible(true)
		infosDisplay:getChildByName("card_btn_cardChoose_Btn"):setVisible(true)
		infosDisplay:getChildByName("card_btn_cardEnhance_Btn"):setVisible(true)
		infosDisplay:getChildByName("card_txt_cardEnhance_unselect_line2"):setVisible(true)
		infosDisplay:getChildByName("card_cardEvolve_preview"):setVisible(true)
		infosDisplay:getChildByName("card_txt_cardEnhance_unselect_line1"):setVisible(true)
		
		infosDisplay:getChildByName("card_other_upgrade_in"):setVisible(false)
		infosDisplay:getChildByName("bg_current_data"):setVisible(false)
		infosDisplay:getChildByName("card_btn_cardEnhance_Btn2"):setVisible(false)

		self.changeStateBtnDisplay:getChildByName("txt"):setString(getTextByKey("cardEnhance_useExpBtn"))--使用经验

	    if self.mainCardMetaId >0 then 
	    	--存在主卡?
	        self.mainUI:getChildByName("card_frameB"):setVisible(false)
	        self.mainUI:getChildByName("card_add_B"):setVisible(false)
			self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line2"):setVisible(true)
			self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line1"):setVisible(false)
		else
	        self.mainUI:getChildByName("card_add_M"):setVisible(false)
			self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line2"):setVisible(false)
	        self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line1"):setVisible(true)
	    end
		self:resetMattersPosition()

		if self.matterCardNum > 0 then
			--选择了副卡
			infosDisplay:getChildByName("card_txt_equip_CoinConsume"):setVisible(true)
			infosDisplay:getChildByName("card_icon_sliver_coin"):setVisible(true)
			infosDisplay:getChildByName("card_txt_equip_CoinConsume_num"):setVisible(true)
		else
			--没有副卡
			infosDisplay:getChildByName("card_txt_equip_CoinConsume"):setVisible(false)
			infosDisplay:getChildByName("card_icon_sliver_coin"):setVisible(false)
			infosDisplay:getChildByName("card_txt_equip_CoinConsume_num"):setVisible(false)
		end

		for i,obj in ipairs(self.matterTable) do
			obj:setVisible(true)
		end
	else
		--用经验强化状态
		infosDisplay:getChildByName("card_txt_stage_name"):setVisible(false)
		infosDisplay:getChildByName("card_stage_name_bg"):setVisible(false)
		infosDisplay:getChildByName("card_btn_cardChoose_Btn"):setVisible(false)
		infosDisplay:getChildByName("card_btn_cardEnhance_Btn"):setVisible(false)
		infosDisplay:getChildByName("card_txt_cardEnhance_unselect_line2"):setVisible(false)
		infosDisplay:getChildByName("card_cardEvolve_preview"):setVisible(false)
		infosDisplay:getChildByName("card_txt_cardEnhance_unselect_line1"):setVisible(false)

		infosDisplay:getChildByName("card_btn_cardEnhance_Btn2"):setVisible(true)
		infosDisplay:getChildByName("bg_current_data"):setVisible(true)

		self.changeStateBtnDisplay:getChildByName("txt"):setString(getTextByKey("cardEnhance_useCardBtn"))--使用武将

		for i,obj in ipairs(self.matterTable) do
			obj:setVisible(false)
		end

	    if self.mainCardMetaId >0 then
	    	--存在主卡
			self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line1"):setVisible(false)
			infosDisplay:getChildByName("card_other_upgrade_in"):setVisible(true)
		else
	        self.mainUI:getChildByName("card_cardEnhance_unselect"):getChildByName("card_txt_cardEnhance_unselect_line1"):setVisible(true)
			infosDisplay:getChildByName("card_other_upgrade_in"):setVisible(false)
	    end

		--刷新数值和状态
		self:refreshExpShow()
	end
end

--刷新经验强化相关数值状态
function CardComposeScene:refreshExpShow()
	--当前拥有的经验
	local currentExp = CanonGoodIcon.getResourceNum(ResourceEnum.GENERALEXP)

	self:setTargetLevel(self.maxLevel)

	local infosDisplay = self.mainUI:getChildByName("card_cardEnhance_unselect")
	infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade2"):getChildByName("txt"):setString(getTextByKey("cardEnhance_expOwned") .. currentExp)--当前拥有武将经验：[当前经验]
	infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade5"):getChildByName("txt"):setString(self.maxLevel)--[最高等级]
end

function CardComposeScene:setTargetLevel(targetLevel)
	local infosDisplay = self.mainUI:getChildByName("card_cardEnhance_unselect")
	if self.currentCardData then
		if targetLevel > self.maxLevel then
			self.currentTargetLevel = self.maxLevel
		elseif targetLevel < self.currentLevel then
			self.currentTargetLevel = self.currentLevel
		else
			self.currentTargetLevel = targetLevel
		end

		if self:hasEnoughExp() and (targetLevel <= (self.currentLevel + 1)) then
			--足够升一级的情况下 不能选择当前等级 最低是当前等级+1
			self.currentTargetLevel = self.currentLevel + 1
		end

		infosDisplay:getChildByName("card_other_upgrade_in"):getChildByName("txt_other_upgrade3"):getChildByName("txt"):setString(getTextByKey("cardEnhance_levelUp2", {num = self.currentTargetLevel}))--{num}级

		if self.currentTargetLevel >= self.maxLevel then
			self.btnAddLess:setEnable(false)
			self.btnAddMore:setEnable(false)
		else
			self.btnAddLess:setEnable(true)
			self.btnAddMore:setEnable(true)
		end

		if self.currentTargetLevel <= (self.currentLevel + 1) then
			self.btnCutMore:setEnable(false)
			self.btnCutLess:setEnable(false)
		else
			self.btnCutMore:setEnable(true)
			self.btnCutLess:setEnable(true)
		end

		if self.currentTargetLevel <= self.currentLevel then
			--无法升级
			self.btnExpCompose:setEnable(false)

			infosDisplay:getChildByName("card_txt_equip_CoinConsume"):setVisible(false)
			infosDisplay:getChildByName("card_icon_sliver_coin"):setVisible(false)
			infosDisplay:getChildByName("card_txt_equip_CoinConsume_num"):setVisible(false)

			infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade4"):setVisible(false)
			infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade5"):setVisible(false)
			infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade6"):setVisible(false)

			infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade8"):setVisible(true)
			infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade8"):getChildByName("txt"):setString(getTextByKey("cardEnhance_expNeeded", {num = CardComposeScene.getLeftExpToNextLevel(self.currentCardData)}))--还需要{num}升级
		else
			--允许升级
			self.btnExpCompose:setEnable(true)

			infosDisplay:getChildByName("card_txt_equip_CoinConsume"):setVisible(true)
			infosDisplay:getChildByName("card_icon_sliver_coin"):setVisible(true)
			infosDisplay:getChildByName("card_txt_equip_CoinConsume_num"):setVisible(true)

			infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade4"):setVisible(true)
			infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade5"):setVisible(true)
			infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade6"):setVisible(true)

			infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade8"):setVisible(false)

			local needCoin = CardComposeScene.getNeedCoinByTargetLevel(self.currentCardData, self.currentTargetLevel)
			infosDisplay:getChildByName("card_txt_equip_CoinConsume_num"):getChildByName("font"):setString(tostring(needCoin))

			local currentCoin = CanonGoodIcon.getResourceNum(ResourceEnum.COIN)
			if currentCoin < needCoin then
				--钱不够 红色
				infosDisplay:getChildByName("card_txt_equip_CoinConsume_num"):getChildByName("font"):setColor(ccc3(217, 0, 0))
			else
				--够了 黑色
				infosDisplay:getChildByName("card_txt_equip_CoinConsume_num"):getChildByName("font"):setColor(ccc3(0, 0, 0))
			end
		end
	else
		--没有主卡
		infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade4"):setVisible(false)
		infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade5"):setVisible(false)
		infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade6"):setVisible(false)

		infosDisplay:getChildByName("bg_current_data"):getChildByName("txt_other_upgrade8"):setVisible(false)

		self.btnExpCompose:setEnable(false)
	end
end

--拥有的经验足够至少升一级
function CardComposeScene:hasEnoughExp()
	if self.currentLevel < self.maxLevel then
		return true
	end
	return false
end

--判断能否经验升级
function CardComposeScene:canExpUpgrade()
	local currentCoin = CanonGoodIcon.getResourceNum(ResourceEnum.COIN)
	local needCoin, needExp = CardComposeScene.getNeedCoinByTargetLevel(self.currentCardData, self.currentTargetLevel)
	if currentCoin < needCoin then
		--银币不足 提示
		local scene = Director:mgr():run()
		local aPanel = MessageBoxPanel:create(scene, MessageBoxType.kCoinLimit)
		scene:addChild(aPanel)
		aPanel:scaleIn()
		return false
	end

	-- if needExp < needCoin then
	-- 	--经验不足 理论走不到这步
	-- 	return false
	-- end

	return true
end

--经验升级
function CardComposeScene:expUpgrade()
	local curContext = self
	 --动画完成
	local function onFlashAnimationEnd(event)
		if curContext.flashFinish then
			curContext.flashFinish:unregisterEndAnimationScriptHandler()
		end
		local argv = {enterScene="CardComposeScene",returnScene="CardComposeScene",params={preReturnScene = curContext.argv.returnScene, state = self.currentState}}
		curContext:replaceScene( CardEvolveResultScene , argv)
	end
	
    local function CardComposeCallback(evt)
		local dirtyCardIds = {}
		table.insert(dirtyCardIds, HeMemDataHolder:getInteger("CardCompose_MainCardId"))
		CommonManager:setCardNeedUpdate(dirtyCardIds)
		
		curContext.waitResponse = false;
        curContext.mainCard:setVisible(false)
        curContext:setTouchEnabled(false)
        for i,obj in ipairs(curContext.matterTable) do 
            if obj ~= nil then 
            	obj:setVisible(false)
            end
        end    
        --动画
		CanonPlayEffect("music/sfx_card_compound.wav")
		curContext.flashFinish = FlashSprite:create("EVO2/FZZZ_EXX")   
		curContext.flashFinish:setLoop(false)
          --换牌
        local newMetaId = evt.data.sharkCard.metaId                
        HeMemDataHolder:setInteger( "CardCompose_NewMetaId",newMetaId )
        local masterCardId = HeMemDataHolder:getInteger("CardCompose_MainCardId")
        local result = CommonManager:getCardPropertiesWithCardId(masterCardId)
		result.exp = curContext.oldCardExp
        HeMemDataHolder:setString( "CardCompose_oldSharkCard",table.serialize(result) )
        HeMemDataHolder:setString( "CardCompose_newSharkCard",table.serialize(evt.data.sharkCard) )
        local card1_spf = getCardSpriteFrame(newMetaId)  
        curContext.flashFinish:addChangeInstance("card1", card1_spf)
		local tmeta = MetaManager.card_meta[tonumber(newMetaId)]
		local countrySpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("countryCircle_" .. tmeta.country .. ".png")
		curContext.flashFinish:addChangeInstance("countrycircle1", countrySpriteFrame)
		local boardSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(BigBorderDict[tmeta.rare])
		curContext.flashFinish:addChangeInstance("cardBorder1", boardSpriteFrame)
		local cardBgSpriteFrame = createSpriteFrame("card/background/" .. tmeta.backgroundName)
		curContext.flashFinish:addChangeInstance("cardBg1", cardBgSpriteFrame)
		
		curContext.flashFinish:changeAnimation(2)
		--curContext.flashFinish:setPosition(-10,40)
		curContext.flashFinish:registerEndAnimationScriptHandler(onFlashAnimationEnd)
		curContext:addChild(CocosObject.new(curContext.flashFinish))     
    end  

	local function onSucceed(evt)
		--先走动画
		CardComposeCallback(evt)

		--后重置数据
		UpgradeCardByGeneralExpRequest.onSucceedDefault(evt)
	end
	UpgradeCardByGeneralExpRequest.sendRequest(self.currentCardData, self.currentTargetLevel, onSucceed, UpgradeCardByGeneralExpRequest.onFailedDefault)
end

function CardComposeScene:dispose()
	if not self.notDeleteCardInfo then
		HeMemDataHolder:deleteByKey("matterCard")
	end
    scheduler:unscheduleScriptEntry(self.run_animation)
    CardComposeScene.super.dispose(self)
end

function CardComposeScene:doEnterAnimation()
    self:preEnterAnimation()
    self:startEnterAnimation()
end

function CardComposeScene:preEnterAnimation()
    BaseUIScene.preEnterAnimation(self)
end

function CardComposeScene:startEnterAnimation()
    BaseUIScene.startEnterAnimation(self)
    local function enterActionFinished()
		self.enableRotation = true
        self:nodeAnimationFinished()
    end
    self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    self.mainUI:runAction(CCSequence:create(arr))
    if self.card ~= nil then
        self.card:setPositionX(self.card:getPositionX() - visibleSize.width)
        self.card:runAction(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
    end
    if self.mainCard ~= nil then  
        self.mainCard:setPositionX(self.mainCard:getPositionX()-visibleSize.width)
        self.mainCard:runAction(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))    
    end    
    self.flashFrame1:setPositionX(self.flashFrame1:getPositionX()-visibleSize.width)
    self.flashFrame1:runAction(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
    self.flashFrame2:setPositionX(self.flashFrame2:getPositionX()-visibleSize.width)
    self.flashFrame2:runAction(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))    
    for i,obj in ipairs(self.matterTable) do 
        if obj ~= nil then 
            obj:setPositionX(obj:getPositionX()-visibleSize.width)
            obj:runAction(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))  
        end
    end
end

function CardComposeScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function CardComposeScene:doExitAnimation()
    self:preExitAnimation()
    self:startExitAnimation()
end

function CardComposeScene:preExitAnimation()
    BaseUIScene.preExitAnimation(self)
end

function CardComposeScene:startExitAnimation()
    BaseUIScene.startExitAnimation(self)
    local function enterActionFinished()
        self:nodeAnimationFinished()
    end
	self.enableRotation = false
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width - 10, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    self.mainUI:runAction(CCSequence:create(arr))
    if self.card ~= nil then
        self.card:runAction(CCMoveBy:create(0.3, ccp(-visibleSize.width - 10, 0)))
    end
    self.flashFrame1:runAction(CCMoveBy:create(0.3, ccp(-visibleSize.width - 10, 0)))
    self.flashFrame2:runAction(CCMoveBy:create(0.3, ccp(-visibleSize.width - 10, 0)))
    if self.mainCard ~= nil then  
        self.mainCard:runAction(CCMoveBy:create(0.3, ccp(-visibleSize.width - 10, 0)))    
    end
    for i,obj in ipairs(self.matterTable) do 
        if obj ~= nil then 
            obj:runAction(CCMoveBy:create(0.3, ccp(-visibleSize.width - 10, 0))) 
        end
    end    

    --退出场景动画前先隐藏切换按钮
    self.changeStateBtnDisplay:setVisible(false)
end

function CardComposeScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function CardComposeScene:back()
    if self.argv.returnScene == "BackpackScene" then 
        self:replaceScene(BackpackScene)
	elseif self.argv.returnScene == "CardQueueScene" then
		self:replaceScene(CardQueueScene, {enterScene="CardComposeScene"})
	elseif (self.argv.returnScene == "MatrixScene") then
		self:replaceScene(MatrixScene)
  else
    self:replaceScene(MainMenuScene)
  end 
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--右上角的切换按钮点击
function CardComposeScene.onClickChangeState(evt)
	local self = evt.context
	if self.currentState == CardComposeScene.STETE_CARD then
		self:changeShowState(CardComposeScene.STATE_EXP)
	else
		self:changeShowState(CardComposeScene.STETE_CARD)
	end
end

--点击使用经验合成按钮
function CardComposeScene.onClickExpCompose(evt)
	local self = evt.context
	if self:canExpUpgrade() then
		self:expUpgrade()
	end
end

--点击-10
function CardComposeScene.onClickCutMore(evt)
	local self = evt.context
	self:setTargetLevel(self.currentTargetLevel - 10)
end

--点击-1
function CardComposeScene.onClickCutLess(evt)
	local self = evt.context
	self:setTargetLevel(self.currentTargetLevel - 1)
end

--点击+1
function CardComposeScene.onClickAddLess(evt)
	local self = evt.context
	self:setTargetLevel(self.currentTargetLevel + 1)
end

--点击+10
function CardComposeScene.onClickAddMore(evt)
	local self = evt.context
	self:setTargetLevel(self.currentTargetLevel + 10)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--查询强化到某等级需要的银币数
function CardComposeScene.getNeedCoinByTargetLevel(cardData, targetLevel)
	local cardExp = MetaManager.card_level[cardData.level].totalExp + cardData.exp--主卡经验 = 总经验+当前经验
	local needExp = MetaManager.card_level[targetLevel].totalExp - cardExp
	local needUpgradeCoin = math.floor(needExp * MetaManager.game_meta.gameSettingConfig.cardUpgradeCoinRevise)
	return needUpgradeCoin, needExp
end

--查询强化到某等级需要的银币数
function CardComposeScene.getLeftExpToNextLevel(cardData)
	local cardExp = MetaManager.card_level[cardData.level].totalExp + cardData.exp--主卡经验 = 总经验+当前经验
	local leftExp = MetaManager.card_level[cardData.level + 1].totalExp - cardExp
	return leftExp
end

