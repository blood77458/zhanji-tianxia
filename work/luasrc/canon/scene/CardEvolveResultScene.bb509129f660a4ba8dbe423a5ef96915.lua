require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.customUI.CanonCard"
require "canon.canonUtils"
require "canon.panel.AttributeChangePanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
CardEvolveResultScene = class(BaseUIScene)

function CardEvolveResultScene:ctor()
    self.title = ""
    self.mainUI = nil
end

function CardEvolveResultScene:create(argv)
    if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end
    local s = CardEvolveResultScene.new()
    s:initScene()
    return s
end


function CardEvolveResultScene:onInit()
	if self.argv.enterScene=="CardComposeScene" then
		self.title = getTextByKey("cardEnhanceResult_success")
	else
		self.title = getTextByKey("cardEvolveResult_success")
	end
	
    BaseUIScene.initBackGround(self)
	
	local bg = Sprite:create("pic/nicebg.png")
	bg:setScale(2)
	local winSize = CCDirector:sharedDirector():getWinSize()
	bg:setPosition(ccp(winSize.width / 2 , winSize.height / 2 - 25))
	bg:setColor(ccc3(80, 80, 80))
	self:addChild(bg)
	
    local builder = LayoutBuilder:createWithContentsOfFile("scene/card_new.json")
	builder.useArtLabelTTF = true
    self.mainUI = builder:build("card_cardEvolveResult")
	
	if self.argv.enterScene=="CardComposeScene" then
		self.targetInfoPanel = true;
		local newMetaId = HeMemDataHolder:getInteger( "CardCompose_NewMetaId" )
		local oldSharkCard = table.deserialize( HeMemDataHolder:getString( "CardCompose_oldSharkCard" ) )
		local newSharkCard = table.deserialize( HeMemDataHolder:getString( "CardCompose_newSharkCard" ) )
		
		self.curCardLevel = oldSharkCard.level
		self.endCardLevel = newSharkCard.level
		self.animationEnd = false;
		
		if not oldSharkCard.exp then
			oldSharkCard.exp = 0
		end
		
		local cardPositionX, cardPositionY = self.mainUI:getChildByName("card_icon_evolve_result_card_sb").refCocosObj:getPosition()
		local cardScaleX, cardScaleY = self.mainUI:getChildByName("card_icon_evolve_result_card_sb").refCocosObj:getScaleX(), self.mainUI:getChildByName("card_icon_evolve_result_card_sb").refCocosObj:getScaleY()
		local cardSize = self.mainUI:getChildByName("card_icon_evolve_result_card_sb").refCocosObj:getContentSize()
		local zOrder = self.mainUI:getChildByName("card_icon_evolve_result_card_sb").refCocosObj:getZOrder()
		
		local bigCanonCardWithInfo = getBigCanonCardWithInfoByMetaId(newMetaId)
		local winSize = CCDirector:sharedDirector():getWinSize()
		bigCanonCardWithInfo:setPosition(ccp(cardPositionX + cardSize.width * cardScaleX / 2, cardPositionY - cardSize.height * cardScaleY / 2))
		local sharkCardStatus = CommonManager:getCardPropertiesWithSharkCard(newSharkCard)
		--设置卡牌属性
		self.sharkCardStatus = sharkCardStatus
		bigCanonCardWithInfo:setScaleX(cardSize.width * cardScaleX / bigCanonCardWithInfo.borderSpt:getContentSize().width)
		bigCanonCardWithInfo:setScaleX(cardSize.height * cardScaleY / bigCanonCardWithInfo.borderSpt:getContentSize().height)
		
		bigCanonCardWithInfo:setHp("")
		bigCanonCardWithInfo:setAtk("")
		bigCanonCardWithInfo:setDef("")
		bigCanonCardWithInfo:setLevel("")
		
		local cardMeta = MetaManager.card_meta[newMetaId]
		local cardMaxLevel = MetaManager.card_evolve[cardMeta.evolutionLevel].maxCardLevel
		
		if tonumber(newSharkCard.level) >= tonumber(cardMaxLevel) then
			self.mainUI:getChildByName("card_txt_evolveresult_attention"):setVisible(true)
			self.mainUI:getChildByName("card_btn_evolveresult_confirm"):getChildByName("txt_btn_evolveresult_confirm"):setString(getTextByKey("yes"))
			self.mainUI:getChildByName("card_txt_evolveresult_attention"):getChildByName("font"):setString(getTextByKey("cardEnhanceResult_maxLevel"))
			HeMemDataHolder:deleteByKey("CardCompose_MainCardId")
			HeMemDataHolder:deleteByKey("CardCompose_MainCardMetaId")
		elseif tonumber(newSharkCard.level) >= tonumber(MetaManager.card_evolve[cardMeta.evolutionLevel].evolveNeedLevel) then
			self.mainUI:getChildByName("card_txt_evolveresult_attention"):setVisible(true)
			self.mainUI:getChildByName("card_btn_evolveresult_confirm"):getChildByName("txt_btn_evolveresult_confirm"):setString(getTextByKey("cardEnhanceResult_continueBtn"))
			self.mainUI:getChildByName("card_txt_evolveresult_attention"):getChildByName("font"):setString(getTextByKey("cardEnhanceResult_canEvolve"))
		else
			self.mainUI:getChildByName("card_txt_evolveresult_attention"):setVisible(false)
			self.mainUI:getChildByName("card_btn_evolveresult_confirm"):getChildByName("txt_btn_evolveresult_confirm"):setString(getTextByKey("cardEnhanceResult_continueBtn"))
		end
		
		local percentage = newSharkCard.exp / MetaManager.card_level[newSharkCard.level].exp * 100
		if percentage > 100 then
			percentage = 100
		end
		self.endPercentage = percentage
		
		percentage = oldSharkCard.exp / MetaManager.card_level[oldSharkCard.level].exp * 100
		if percentage > 100 then
			percentage = 100
		end
		self.curPercentage = percentage
		
		--[[local hightlight_progress = ProgressBar:create(self.mainUI:getChildByName("card_enhance_progress_highlight_sb"))
		hightlight_progress:setPercentage(self.curPercentage)
		self.hightlight_progress = hightlight_progress--]]
		local progress = ProgressBar:create(self.mainUI:getChildByName("card_enhance_progress_sb"))
		progress:setPercentage(self.curPercentage)
		self.progress = progress
		
		self.mainUI:getChildByName("card_txt_lv_num_R"):getChildByName("font"):setString(tostring(sharkCardStatus.level))
		self.mainUI:getChildByName("card_txt_lv_num_L"):getChildByName("font"):setString(tostring(oldSharkCard.level))
		self.mainUI:getChildByName("card_txt_equip_lv_num_white_l"):getChildByName("font"):setString("/" .. cardMaxLevel)
		self.mainUI:getChildByName("card_txt_equip_lv_num_white_r"):getChildByName("font"):setString( "/" .. cardMaxLevel)
		self.mainUI:getChildByName("card_txt_card_enhance_hp_R"):getChildByName("font"):setString(tostring(sharkCardStatus.hp))
		self.mainUI:getChildByName("card_txt_card_enhance_hp_L"):getChildByName("font"):setString(tostring(oldSharkCard.hp))
		self.mainUI:getChildByName("card_txt_card_enhance_def_R"):getChildByName("font"):setString(tostring(sharkCardStatus.def))
		self.mainUI:getChildByName("card_txt_card_enhance_def_L"):getChildByName("font"):setString(tostring(oldSharkCard.def))
		self.mainUI:getChildByName("card_txt_evolveresult_atk_M"):getChildByName("font"):setString(tostring(sharkCardStatus.att))
		self.mainUI:getChildByName("card_txt_evolveresult_atk_L"):getChildByName("font"):setString(tostring(oldSharkCard.att))
		
		self.levelL = self.mainUI:getChildByName("card_txt_lv_num_L")
		self.levelR = self.mainUI:getChildByName("card_txt_lv_num_R")
		self.levelL:getChildByName("font"):setDimensions(CCSizeMake(0, self.levelL:getChildByName("font"):getDimensions().height))
		self.levelR:getChildByName("font"):setDimensions(CCSizeMake(0, self.levelR:getChildByName("font"):getDimensions().height))
		self.levelMaxL = self.mainUI:getChildByName("card_txt_equip_lv_num_white_l")
		self.levelMaxR = self.mainUI:getChildByName("card_txt_equip_lv_num_white_r")
		self.levelMaxL:setPosition(ccp(self.levelL:getPositionX() + self.levelL:getChildByName("font"):getContentSize().width + 3, self.levelMaxL:getPositionY()))
		self.levelMaxR:setPosition(ccp(self.levelR:getPositionX() + self.levelR:getChildByName("font"):getContentSize().width + 3, self.levelMaxR:getPositionY()))
		
		self.attentionVisible = self.mainUI:getChildByName("card_txt_evolveresult_attention"):isVisible()
		self.mainUI:setPositionY(self.mainUI:getPositionY() - 100)
		
		for k,v in pairs(self.mainUI.list)
		do
			v:setVisible(false)
		end
		
		self.mainUI:getChildByName("card_enhance_progress_bg_sb"):setVisible(true)
		self.mainUI:getChildByName("card_enhance_progress_sb"):setVisible(true)
		self.mainUI:getChildByName("card_enhance_progress_highlight_sb"):setVisible(true)
		
		function showEndResult()
			if not self.animationEnd then
				self.coverTouchLayer:unregisterScriptTouchHandler()
				--self.hightlight_progress:stopProgress()
				self.progress:stopProgress()
				if Get_ShareData("New_User_Guide_Running") ~=1 then
					self.mainUI:stopAllActions()
				end
				--self.hightlight_progress:setPercentage(self.endPercentage)
				self.progress:setPercentage(self.endPercentage)
				self.animationEnd = true;
				bigCanonCardWithInfo:setHp(self.sharkCardStatus.hp)
				bigCanonCardWithInfo:setAtk(self.sharkCardStatus.att)
				bigCanonCardWithInfo:setDef(self.sharkCardStatus.def)
				bigCanonCardWithInfo:setLevel(self.sharkCardStatus.level)
				self.mainUI:getChildByName("card_enhance_progress_bg_sb"):setVisible(false)
				self.mainUI:getChildByName("card_enhance_progress_sb"):setVisible(false)
				self.mainUI:getChildByName("card_enhance_progress_highlight_sb"):setVisible(false)
				
				local function onMoveFinish()
					for k,v in pairs(self.mainUI.list)
					do
						v:setVisible(true)
					end
					self.mainUI:getChildByName("card_txt_evolveresult_attention"):setVisible(self.attentionVisible)
					self.mainUI:getChildByName("card_icon_evolve_result_card_sb"):setVisible(false)
					self.mainUI:getChildByName("card_txt_evolveresult_name_R"):setVisible(false)
					self.mainUI:getChildByName("card_txt_evolveresult_name_M"):setVisible(false)
					self.mainUI:getChildByName("card_txt_evolveresult_name_L"):setVisible(false)
					self.mainUI:getChildByName("card_txt_evolveresult_atk_R"):setVisible(false)
					self.mainUI:getChildByName("card_txt_evolveresult_def_R"):setVisible(false)
					self.mainUI:getChildByName("card_txt_evolveresult_hp_R"):setVisible(false)
					self.mainUI:getChildByName("card_enhance_progress_bg_sb"):setVisible(false)
					self.mainUI:getChildByName("card_enhance_progress_sb"):setVisible(false)
					self.mainUI:getChildByName("card_enhance_progress_highlight_sb"):setVisible(false)
					self.mainUI:getChildByName("card_bg3_sb"):setVisible(false)
					self.enableClick = true;
					
					--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
					DataManager.fightCapacityMaybeUpdated()

					if Get_ShareData("New_User_Guide_Running") == 1 then
						Set_ShareData( "CardMergeFinished", 1 )
						Director:sharedDirector():getRunningScene():resetTouchFlag()
						CCDirector:sharedDirector():getTouchDispatcher():setDispatchEvents(true)
					end
					self.targetInfoPanel = nil;
				end
				
				
				--self.mainUI:setPositionY(self.mainUI:getPositionY() + 100)
				
				local enhanceCompleteFlash = FlashSprite:create("EVO2/enhance_complete")
				enhanceCompleteFlash:setLoop(false)
				
				local enhanceCompleteFlash_co = CocosObject.new(enhanceCompleteFlash)
				local function onEnhanceFlashEnd()
					if enhanceCompleteFlash then
						enhanceCompleteFlash:unregisterEndAnimationScriptHandler()
					end
					self:removeChild(enhanceCompleteFlash_co)
					onMoveFinish()
				end
				enhanceCompleteFlash:changeAnimation(0)
				enhanceCompleteFlash:registerEndAnimationScriptHandler(onEnhanceFlashEnd)
				self:addChild(enhanceCompleteFlash_co)
				
				if Get_ShareData("New_User_Guide_Running") ~=1 then
					local actionArray = CCArray:create()
					actionArray:addObject(CCMoveBy:create(1.5, ccp(0, 100)))
					--actionArray:addObject(CCCallFuncN:create(onMoveFinish))
					self.mainUI:runAction(CCSequence:create(actionArray))
				else
					self.mainUI:setPositionY(self.mainUI:getPositionY() + 100)
				end
			end
		end
		
		local function onClickConfirm(e)
			if self.animationEnd then
				if self.enableClick then
					local nextReturnScene = nil;
					local state = nil;
					if self.argv.params then
						nextReturnScene = self.argv.params.preReturnScene
						state = self.argv.params.state
					end
					local argv = {enterScene=nil,returnScene=nextReturnScene,params={state = state}}
					self:replaceScene(CardComposeScene, argv)
				end
			else
				showEndResult()
			end
		end
		
		local btn_confirm = Button:create(self.mainUI:getChildByName("card_btn_evolveresult_confirm"))
		btn_confirm:addEventListener(Events.kStart, onClickConfirm)
		
		
		self:addChild(self.mainUI)
		bigCanonCardWithInfo:setScale(1.1)
		self.mainUI:addChild( bigCanonCardWithInfo)
		
		local runExpProgressIncreaseAnimation=  nil
		
		local function showLevelupFlash()
			local levelupFlash = FlashSprite:create("EVO2/card_levelup")  
			--levelupFlash:setPosition(ccp(720 /  2, 1280 / 2))
			local levelupFlash_co = CocosObject.new(levelupFlash)
			local function onLevelupFlashEnd()
				if levelupFlash then
					levelupFlash:unregisterEndAnimationScriptHandler()
				end
				self:removeChild(levelupFlash_co)
				runExpProgressIncreaseAnimation()
			end
			levelupFlash:changeAnimation(0)
			levelupFlash:registerEndAnimationScriptHandler(onLevelupFlashEnd)
			levelupFlash_co:setPositionY( -200 - 100 - 8)
			self:addChild(levelupFlash_co)
			--self.hightlight_progress:stopProgress()
			self.progress:stopProgress()
			self.mainUI:stopAllActions()
			--self.hightlight_progress:setPercentage(self.curPercentage)
			self.progress:setPercentage(self.curPercentage)
			
			local particle = CCParticleSystemQuad:create("effect/fx_card_lvup.plist")
			particle:setPosition(ccp(360, 440-100))
			particle:setAutoRemoveOnFinish(true)
			self:addChild(CocosObject.new(particle))
			--local arr = CCArray:create()
			--arr:addObject(CCDelayTime:create(0.5))
			--arr:addObject(CCCallFunc:create(onLevelupFlashEnd))
			--levelupFlash:runAction(CCSequence:create(arr))
		end
		
		runExpProgressIncreaseAnimation = function()
			if self.animationEnd then
				do return end
			end
			--self.hightlight_progress:setPercentage(self.curPercentage)
			self.progress:setPercentage(self.curPercentage)
			if tonumber(self.curCardLevel) >= tonumber(self.endCardLevel) then
				local duration = 0.5 * (self.endPercentage - self.curPercentage) / 100
				local percentage = self.endPercentage
				local arr = CCArray:create()
				arr:addObject(CCDelayTime:create(duration))
				arr:addObject(CCCallFunc:create(showEndResult))
				--self.hightlight_progress:progressTo(percentage, duration)
				self.progress:progressTo(percentage, duration)
				self.mainUI:runAction(CCSequence:create(arr))
			else
				
				local duration = 0.5 * (100 - self.curPercentage) / 100
				local percentage = 100
				local arr = CCArray:create()
				arr:addObject(CCDelayTime:create(duration))
				arr:addObject(CCCallFunc:create(showLevelupFlash))
				--self.hightlight_progress:progressTo(percentage, duration)
				self.progress:progressTo(percentage, duration)
				self.mainUI:runAction(CCSequence:create(arr))
				
				self.curPercentage = 0
				self.curCardLevel = self.curCardLevel + 1
			end
		end
		runExpProgressIncreaseAnimation()
	else
		local oldMetaId = HeMemDataHolder:getInteger( "CardEvolve_OldMetaId" )
		local newMetaId = HeMemDataHolder:getInteger( "CardEvolve_NewMetaId" )
		local oldSharkCard = table.deserialize( HeMemDataHolder:getString( "CardEvolve_oldSharkCard" ) )
		local newSharkCard = table.deserialize( HeMemDataHolder:getString( "CardEvolve_newSharkCard" ) )
		local sharkCardStatus = CommonManager:getCardPropertiesWithSharkCard(newSharkCard)
		local oldMeta = MetaManager.card_meta[tonumber(oldMetaId)]
		local oldMaxCardLevel = MetaManager.card_evolve[oldMeta.evolutionLevel].maxCardLevel
		local newMeta = MetaManager.card_meta[tonumber(newMetaId)]
		local newMaxCardLevel = MetaManager.card_evolve[newMeta.evolutionLevel].maxCardLevel
		
		local cardPositionX, cardPositionY = self.mainUI:getChildByName("card_icon_evolve_result_card_sb").refCocosObj:getPosition()
		local cardScaleX, cardScaleY = self.mainUI:getChildByName("card_icon_evolve_result_card_sb").refCocosObj:getScaleX(), self.mainUI:getChildByName("card_icon_evolve_result_card_sb").refCocosObj:getScaleY()
		local cardSize = self.mainUI:getChildByName("card_icon_evolve_result_card_sb").refCocosObj:getContentSize()
		local zOrder = self.mainUI:getChildByName("card_icon_evolve_result_card_sb").refCocosObj:getZOrder()
		
		local bigCanonCardWithInfo = getBigCanonCardWithInfoByMetaId(newMetaId)
		local winSize = CCDirector:sharedDirector():getWinSize()
		bigCanonCardWithInfo:setPosition(ccp(cardPositionX + cardSize.width * cardScaleX / 2, cardPositionY - cardSize.height * cardScaleY / 2))
		local sharkCardStatus = CommonManager:getCardPropertiesWithSharkCard(newSharkCard)
		--设置卡牌属性
		bigCanonCardWithInfo:setHp(sharkCardStatus.hp)
		bigCanonCardWithInfo:setAtk(sharkCardStatus.att)
		bigCanonCardWithInfo:setDef(sharkCardStatus.def)
		bigCanonCardWithInfo:setLevel(sharkCardStatus.level)
		bigCanonCardWithInfo:setScaleX(cardSize.width * cardScaleX / bigCanonCardWithInfo.borderSpt:getContentSize().width)
		bigCanonCardWithInfo:setScaleX(cardSize.height * cardScaleY / bigCanonCardWithInfo.borderSpt:getContentSize().height)
		
		self.mainUI:getChildByName("card_txt_evolveresult_name_R"):getChildByName("font"):setString(getTextByKey("cardEvolveResult_bonus"))
		self.mainUI:getChildByName("card_txt_evolveresult_name_L"):getChildByName("font"):setString(getTextByKey(oldMeta.name))
		self.mainUI:getChildByName("card_txt_evolveresult_name_M"):getChildByName("font"):setString(getTextByKey(newMeta.name))
		self.mainUI:getChildByName("card_txt_lv_num_L"):getChildByName("font"):setString("" .. oldSharkCard.level)
		self.mainUI:getChildByName("card_txt_equip_lv_num_white_l"):getChildByName("font"):setString("/" .. oldMaxCardLevel)
		self.mainUI:getChildByName("card_txt_lv_num_R"):getChildByName("font"):setString("" .. sharkCardStatus.level )
		self.mainUI:getChildByName("card_txt_equip_lv_num_white_r"):getChildByName("font"):setString( "/" .. newMaxCardLevel)
		self.mainUI:getChildByName("card_txt_evolveresult_atk_R"):getChildByName("font"):setString("+" .. tostring(newSharkCard.attEvolveValue))
		self.mainUI:getChildByName("card_txt_evolveresult_atk_M"):getChildByName("font"):setString(tostring(sharkCardStatus.att - newSharkCard.attEvolveValue))
		self.mainUI:getChildByName("card_txt_evolveresult_atk_L"):getChildByName("font"):setString(tostring(oldSharkCard.att))
		self.mainUI:getChildByName("card_txt_evolveresult_def_R"):getChildByName("font"):setString("+" .. tostring(newSharkCard.defEvolveValue))
		self.mainUI:getChildByName("card_txt_card_enhance_def_R"):getChildByName("font"):setString(tostring(sharkCardStatus.def - newSharkCard.defEvolveValue))
		self.mainUI:getChildByName("card_txt_card_enhance_def_L"):getChildByName("font"):setString(tostring(oldSharkCard.def))
		self.mainUI:getChildByName("card_txt_evolveresult_hp_R"):getChildByName("font"):setString("+" .. tostring(newSharkCard.hpEvolveValue))
		self.mainUI:getChildByName("card_txt_card_enhance_hp_R"):getChildByName("font"):setString(tostring(sharkCardStatus.hp - newSharkCard.hpEvolveValue))
		self.mainUI:getChildByName("card_txt_card_enhance_hp_L"):getChildByName("font"):setString(tostring(oldSharkCard.hp))

		self.levelL = self.mainUI:getChildByName("card_txt_lv_num_L")
		self.levelR = self.mainUI:getChildByName("card_txt_lv_num_R")
		self.levelL:getChildByName("font"):setDimensions(CCSizeMake(0, self.levelL:getChildByName("font"):getDimensions().height))
		self.levelR:getChildByName("font"):setDimensions(CCSizeMake(0, self.levelR:getChildByName("font"):getDimensions().height))
		self.levelMaxL = self.mainUI:getChildByName("card_txt_equip_lv_num_white_l")
		self.mainUI:getChildByName("card_txt_equip_lv_num_white_r"):setVisible(false)
		self.levelMaxR = self.mainUI:getChildByName("card_txt_equip_lv_num_white_r")
		--self.levelMaxR:getChildByName("font"):setColor(ccc3(0, 102, 0))
		self.levelMaxL:setPosition(ccp(self.levelL:getPositionX() + self.levelL:getChildByName("font"):getContentSize().width + 3, self.levelMaxL:getPositionY()))
		self.levelMaxR:setPosition(ccp(self.levelR:getPositionX() + self.levelR:getChildByName("font"):getContentSize().width + 3, self.levelMaxR:getPositionY()))
		local maxR = TextField:create(self.levelMaxR:getChildByName("font"):getString(), self.levelMaxR:getChildByName("font"):getFontName(), 
		self.levelMaxR:getChildByName("font"):getFontSize(), self.levelMaxR:getChildByName("font"):getDimensions(), 
		tonumber(self.levelMaxR:getChildByName("font"):getHorizontalAlignment()), tonumber(self.levelMaxR:getChildByName("font"):getVerticalAlignment()))
		maxR:setPositionXY(self.levelMaxR:getPositionX(), self.levelMaxR:getPositionY())
		maxR:setAnchorPoint(ccp(0, 1))
		maxR:setColor(ccc3(34, 199, 103))
		self.mainUI:addChild(maxR)
		
		self.mainUI:getChildByName("card_txt_evolveresult_attention"):getChildByName("font"):setString(getTextByKey("cardEvolveResult_maxLevel"))
		self.mainUI:getChildByName("card_btn_evolveresult_confirm"):getChildByName("txt_btn_evolveresult_confirm"):setString(getTextByKey("yes"))
		self.mainUI:getChildByName("card_icon_evolve_result_card_sb"):setVisible(false)
		self.mainUI:getChildByName("card_enhance_progress_highlight_sb"):setVisible(false)
		self.mainUI:getChildByName("card_enhance_progress_sb"):setVisible(false)
		self.mainUI:getChildByName("card_enhance_progress_bg_sb"):setVisible(false)
		self.mainUI:getChildByName("card_txt_evolveresult_attention"):setVisible(newMeta.evolutionLevel >= newMeta.maxEvolvedLevel)
		
		local function onClickConfirm(e)
			local nextReturnScene = nil;
			if self.argv.params then
				nextReturnScene = self.argv.params.preReturnScene
			end
            local argv = {enterScene=nil,returnScene=nextReturnScene,params={}}
			self:replaceScene(CardEvolutionScene, argv)
		end
		
		local btn_confirm = Button:create(self.mainUI:getChildByName("card_btn_evolveresult_confirm"))
		btn_confirm:addEventListener(Events.kStart, onClickConfirm)
		
		self:addChild(self.mainUI)
		bigCanonCardWithInfo:setScale(1.1)
		self.mainUI:addChildAt( bigCanonCardWithInfo , zOrder)
		
		Set_ShareData( "CardJJFinished", 1 )
	end
	
	BaseUIScene.onInit(self)
	
	if self.argv.enterScene=="CardComposeScene" then
		local function onTouchCoverLayer(eventType, x, y)
			showEndResult()
			return true
		end
		
		--Set_ShareData( "CardEvolve_Can_Click", 1 )
		self.coverTouchLayer = Layer:create()
		self.coverTouchLayer:registerScriptTouchHandler( onTouchCoverLayer,false, -10, true )
		self.coverTouchLayer:setTouchEnabled(true)
		self:addChild(self.coverTouchLayer)
		if Get_ShareData("New_User_Guide_Running") ==1 then
			showEndResult();
		end
	else
		--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
		DataManager.fightCapacityMaybeUpdated()
	end
	
end

function CardEvolveResultScene:dispose()
    CardEvolveResultScene.super.dispose(self)
end

function CardEvolveResultScene:doEnterAnimation()
    self:preEnterAnimation()
    self:startEnterAnimation()
end

function CardEvolveResultScene:preEnterAnimation()
    BaseUIScene.preEnterAnimation(self)
end

function CardEvolveResultScene:startEnterAnimation()
    BaseUIScene.startEnterAnimation(self)
    local function enterActionFinished()
        self:nodeAnimationFinished()
    end
    --self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
    local arr = CCArray:create()
  --  arr:addObject(CCMoveBy:create(0.5, ccp(visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    self.mainUI:runAction(CCSequence:create(arr))
end

function CardEvolveResultScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
	if self.argv.enterScene=="CardComposeScene" and Get_ShareData("New_User_Guide_Running") ==1 then
		CCDirector:sharedDirector():getTouchDispatcher():setDispatchEvents(false)
	end
end

function CardEvolveResultScene:doExitAnimation()
    self:preExitAnimation()
    self:startExitAnimation()
end

function CardEvolveResultScene:preExitAnimation()
    BaseUIScene.preExitAnimation(self)
end

function CardEvolveResultScene:startExitAnimation()
    BaseUIScene.startExitAnimation(self)
    local function enterActionFinished()
        self:nodeAnimationFinished()
    end
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    self.mainUI:runAction(CCSequence:create(arr))
end

function CardEvolveResultScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function CardEvolveResultScene:back()
    if self.argv.returnScene == "CardEvolutionScene" then 
		local nextReturnScene = nil;
		if self.argv.params then
			nextReturnScene = self.argv.params.preReturnScene
		end
        local argv = {enterScene=nil,returnScene=nextReturnScene,params={}}
		self:replaceScene(CardEvolutionScene, argv)
    elseif self.argv.returnScene == "CardComposeScene" then
		local nextReturnScene = nil;
		local state = nil;
		if self.argv.params then
			nextReturnScene = self.argv.params.preReturnScene
			state = self.argv.params.state
		end
        local argv = {enterScene=nil,returnScene=nextReturnScene,params={state = state}}
		self:replaceScene(CardComposeScene, argv)
    else
        self:replaceScene(MainMenuScene)
    end 
end