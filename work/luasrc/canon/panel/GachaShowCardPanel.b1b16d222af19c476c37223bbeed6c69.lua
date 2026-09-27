require "canon.canonUtils"
require "canon.data.DataManager"
require "canon.data.MetaManager"
require "hecore.display.CocosObject"
require "hecore.display.Director"

local visibleSize = CCDirector:sharedDirector():getVisibleSize();

GachaShowCardPanel = class(Layer)

function GachaShowCardPanel:ctor()
end

function GachaShowCardPanel:create(container, rewards, index, callback, gachaType)
	local cardPanel = GachaShowCardPanel.new()
	cardPanel.container = container
	cardPanel.rewards = rewards
	cardPanel.cardIndex = index
	cardPanel.callback = callback
	cardPanel.gachaType = gachaType

	cardPanel:initLayer()
	return cardPanel
end

function GachaShowCardPanel:initLayer()
	GachaShowCardPanel.super.initLayer(self)

	self.background = LayerColor:create()
	self.background:setColor(ccc3( 0, 0, 0 ))
	self.background:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
	self:addChild(self.background)

	local particle = CCParticleSystemQuad:create("effect/fx_flower.plist")
	particle:setPosition(ccp(360, 800))
	self:addChild(CocosObject.new(particle))

	local spt = CCSprite:create("pic/yinghuabeijing.png")--解决jpg报错问题
	spt:setScale(2)
	spt:setPosition(ccp(visibleSize.width /2, visibleSize.height/2 + 150))
	self:addChild(CocosObject.new(spt))

	local cardId = self.rewards[self.cardIndex].metaId
	self.gachaFlashSprite = FlashSprite:create("EVO2/gacha")
	self.gachaFlashSprite:addChangeInstance("cardFull1", getFullCardSpriteFrame(cardId))
	self.gachaFlashSprite:addChangeInstance("card1", getCardSpriteFrame(cardId))
	self.gachaFlashSprite:addChangeInstance("cardBorder1", getCardBorderSpriteFrame(cardId))
	self.gachaFlashSprite:addChangeInstance("cardBg1", getCardBackGroundSpriteFrame(cardId))
	local meta = MetaManager.card_meta[cardId]
	local countryCicrleName = {"countryCircle_1.png", "countryCircle_2.png", "countryCircle_3.png", "countryCircle_4.png"}
	local countrySprite = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(countryCicrleName[meta.country])
	self.gachaFlashSprite:addChangeInstance("countryCicrle1", countrySprite)
	local BianGuangName = {
		"pic/gacha_bian_guang_1.png",
		"pic/gacha_bian_guang_1.png",
		"pic/gacha_bian_guang_2.png",
		"pic/gacha_bian_guang_2.png",
		"pic/gacha_bian_guang_2.png",
		"pic/gacha_bian_guang_3.png",
		"pic/gacha_bian_guang_3.png",
	}
	self.gachaFlashSprite:addChangeInstance("baiguang1", createSpriteFrame(BianGuangName[meta.rare]))
	local GachaTypeBgName = {"pic/gacha_bg_1.png", "pic/gacha_bg_2.png", "pic/gacha_bg_3.png", "pic/gacha_bg_3.png", "pic/gacha_bg_3.png", "pic/gacha_bg_3.png"}
	self.gachaFlashSprite:addChangeInstance("taijie1", createSpriteFrame(GachaTypeBgName[self.gachaType]))

	self.gachaFlashSprite:changeAnimation(self.cardIndex == 1 and 0 or 1)
	self.gachaFlashSprite:setLoop(false)

	local function onFlashAnimationEnd(anim)
		if anim == 0 then
			self.gachaFlashSprite:changeAnimation(1)
		else
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
			if self.cardIndex < #self.rewards and not self.skip then
				local panel = GachaShowCardPanel:create(self.container, self.rewards, self.cardIndex+1, self.callback, self.gachaType)
				PopoutManager:sharedManager():popout(panel, nil, true, false, self.container)
			elseif self.callback then
				self.callback()
			end
			Set_ShareData("Gacha_One_Finished", 1)
		end
	end

    local function onGachaShowCard(anim)
        local bmpName = BitmapText:create(getTextByKey(meta.name), "common/card_name.fnt", 0, kCCTextAlignmentLeft)
        bmpName:setScale(1)
        bmpName:setPosition(ccp( visibleSize.width/2, 400 ))
		local arr = CCArray:create()
		arr:addObject(CCDelayTime:create(2))
		arr:addObject(CCFadeOut:create(2))
        bmpName:runAction(CCSequence:create(arr))
        self:addChild(bmpName)
		local starWidth = 30
		local starX = visibleSize.width/2 + 18 - meta.rare * starWidth / 2
		for i = 1, meta.rare do
			local star = Sprite:createWithSpriteFrameName("card_xing.png")
			star:setPosition(ccp(starX + starWidth*(i-1), 450))
			local arr = CCArray:create()
			arr:addObject(CCDelayTime:create(2))
			arr:addObject(CCFadeOut:create(2))
			star:runAction(CCSequence:create(arr))
			self:addChild(star)
		end
    end

	self.gachaFlashSprite:registerEndAnimationScriptHandler(onFlashAnimationEnd)
	self.gachaFlashSprite:registerFlashScriptHandler( onGachaShowCard )
	self.gachaFlashSprite:addFrameEvent("showName", 1, 30)
	self:addChild(CocosObject.new(self.gachaFlashSprite))

	local function onSkipButtonClick()
		self.gachaFlashSprite:setIsRun(false)
		self.skip = true
		onFlashAnimationEnd()
	end
	if Get_ShareData("New_User_Guide_Running") ~= 1 then
		local pic = Sprite:create("textbox_comm/UsingPics/skip_1.png")
		pic:setAnchorPoint(ccp( 1, 0 ))
		pic:setPosition(ccp( 720, 0 ))
		self:addChild(pic)
		self.skipButton = Button:create(pic)
		self.skipButton:addEventListener(Events.kStart, onSkipButtonClick, self)
    end
end

function GachaShowCardPanel:dispose()
	self.gachaFlashSprite:unregisterFlashScriptHandler()
	self.gachaFlashSprite:unregisterEndAnimationScriptHandler()
	GachaShowCardPanel.super.dispose(self)
end
