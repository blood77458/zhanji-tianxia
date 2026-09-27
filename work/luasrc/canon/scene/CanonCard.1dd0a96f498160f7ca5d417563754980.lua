--------------------------------------------------------------------------------
-- CanonCard.lua - 生成卡牌信息素材
-- author: silian.xiang & xiaojie.bai
-- date: 2013-08-26 15:00
--------------------------------------------------------------------------------

require "hecore.display.Sprite"
require "hecore.display.CocosObject"
require "hecore.display.Layer"

SizeInfoTypes = {
		BigWithInfo = 0,
		BigNoInfo = 1,
		SmallWithLevel = 2,  -- 只显示等级和稀有度
		SmallWithProp = 3, -- 只显示攻防血
		SmallNoInfo = 4,
		IconHead = 5,
		IconHeadBackpack = 6,
		IconHeadNoStar = 7,	-- 显示icon 边框 但不显示星星
	}
BigBorderDict = {
		[1] = "cardBorder_large_1.png",
		[2] = "cardBorder_large_2.png",
		[3] = "cardBorder_large_3.png",
		[4] = "cardBorder_large_4.png",
		[5] = "cardBorder_large_5.png",
		[6] = "cardBorder_large_6.png",
		[7] = "cardBorder_large_7.png"
	}
SmallBorderDict = {
		[1] = "cardBorder_large_1.png",
		[2] = "cardBorder_large_2.png",
		[3] = "cardBorder_large_3.png",
		[4] = "cardBorder_large_4.png",
		[5] = "cardBorder_large_5.png",
		[6] = "cardBorder_large_6.png",
		[7] = "cardBorder_large_7.png"
	}

IconHeadBgDict = {
		[1] = "card/background/CardIconHeadBg_1.png",
		[2] = "card/background/CardIconHeadBg_1.png",
		[3] = "card/background/CardIconHeadBg_2.png",
		[4] = "card/background/CardIconHeadBg_2.png",
		[5] = "card/background/CardIconHeadBg_3.png",
		[6] = "card/background/CardIconHeadBg_3.png",
		[7] = "card/background/CardIconHeadBg_3.png"
}	

IconHeadBorderDict = {
		[1] = "cardIconBorder_1.png",
		[2] = "cardIconBorder_1.png",
		[3] = "cardIconBorder_2.png",
		[4] = "cardIconBorder_2.png",
		[5] = "cardIconBorder_3.png",
		[6] = "cardIconBorder_3.png",
		[7] = "cardIconBorder_3.png"
}

CanonCard = class(Layer);
function CanonCard:ctor()
	self.name = "CanonCard"
	self.cardSprite = nil
	self.chestSpt = nil
	self.bgSpt = nil
	self.borderSpt = nil
end

--static create function
function CanonCard:create()
  local card = CanonCard.new()
  card:initLayer()
  return card
end

function CanonCard:getSprite()
	return self.cardSprite 
end

--[[
function CanonCard:load(path, name)
	self.cardSprite = CardSprite:create(path, name)
		
	if nil == self.bgSpt then
		local spt = CCSprite:create("card/card_bg.png")
		self.bgSpt = CocosObject.new(spt)
    
    self:addChild(self.bgSpt)
	end
  
  if nil == self.chestSpt then
		local sf = self.cardSprite:getSpriteFrameByName("sdandard.png")
		local spt = CCSprite:createWithSpriteFrame(sf) 
		self.chestSpt = CocosObject.new(spt)
    
    self:addChild(self.chestSpt)
	end
	
	if nil == self.borderSpt then
		local spt = CCSprite:create("card/card_border.png") 
		self.borderSpt = CocosObject.new(spt)
    
    self:addChild(self.borderSpt)
	end
end
--]]

----------------------------------------
-- 注: posX,posY为素材左上角的坐标
----------------------------------------
function CanonCard:geneImageSpt(spriteFrameName, posX, posY, scaleX, scaleY)
	if(not scaleY) then
		scaleY = 1.0
	end

	if(not scaleX) then
		scaleX = 1.0
	end

	local spt = CCSprite:createWithSpriteFrameName(spriteFrameName)
	spt:setAnchorPoint(ccp(0, 1))
	spt:setPosition(ccp(posX, posY))
	spt:setScaleX(scaleX)
	spt:setScaleY(scaleY)

	return CocosObject.new(spt)
end

----------------------------------------
-- 在指定位置生成特定字体大小的TextField
-- 注: posX,posY为素材左上角的坐标
----------------------------------------
function CanonCard:geneTextSpt(posX, posY, dimensions, fontSize, hAlign, vAlign)
	local textSpt = TextField:create()
	textSpt:setDimensions(dimensions)
	textSpt:setPosition(ccp(posX + dimensions.width / 2, posY - dimensions.height / 2))
	textSpt:setFontSize(fontSize)
	textSpt:setHorizontalAlignment(hAlign or kCCTextAlignmentRight)
	textSpt:setVerticalAlignment(vAlign or kCCVerticalTextAlignmentCenter)

	return textSpt
end

function CanonCard:loadCard(path, name, meta, sizeInfoType)
	--temp add 
		if meta.backgroundName == nil then
			meta.cardBG = "wei12_1234.jpg"
		end
	--end
	
	local evolutionLevel = meta.evolutionLevel -- 卡牌进化等级
	local country = meta.country
	local rare = meta.rare
	
	if sizeInfoType == SizeInfoTypes.IconHeadBackpack or sizeInfoType == SizeInfoTypes.IconHead or sizeInfoType == SizeInfoTypes.IconHeadNoStar then
		--if not g_loadPlistBefore then
		--	PlistResMgr:getInstance():loadPlist("card/icon_plist.plist")
		--	g_loadPlistBefore = true;
		--end
		local iconBg = Sprite:create( IconHeadBgDict[rare] )
		self:addChild(iconBg)
		--local sf = self.cardSprite:getSpriteFrameByName("icon.png")
		local icon = Sprite:create("card/head/"..meta.figureId .. "_head.png")--Sprite:createWithSpriteFrame(sf)
		self:addChild(icon)
		local iconBorder = Sprite:create( "Item/border/equipBorder"..rare..".png" )
		self:addChild(iconBorder)
		
		if sizeInfoType == SizeInfoTypes.IconHeadBackpack then
			do return end
		end
		
		local evovlePosY = -38
		local evovleInc = 16
		local xin_w = (rare - 1)*evovleInc
		local evovlePosX = -(xin_w/2) - 11
		
		if sizeInfoType ~= SizeInfoTypes.IconHeadNoStar then
			--可以显示星星
			for i = 1, rare, 1 do
				local x = self:geneImageSpt("card_xing.png", evovlePosX + (i-1)*evovleInc, evovlePosY)
				x:setScale(0.8)
				self:addChild(x)
			end
		end
		
		
		do return end
	end
	
	self.cardSprite = CardSprite:create(path, name)
	self.cardSprite:retain()
	
	--[[
	if sizeInfoType == SizeInfoTypes.IconHead then
		local iconBg = Sprite:create( IconHeadBgDict[rare] )
		self:addChild(bg)
		local sf = self.cardSprite:getSpriteFrameByName("icon.png")
		local icon = Sprite:createWithSpriteFrame(sf)
		self:addChild(icon)
		local iconBorder = Sprite:createWithSpriteFrameName( IconHeadBorderDict[rare] )
		self:addChild(iconBorder)
		do return end
	end
	--]]

	if nil == self.borderSpt then
		local fileCardBorder = nil
		local spt = nil
		if(sizeInfoType == SizeInfoTypes.BigWithInfo or sizeInfoType == SizeInfoTypes.BigNoInfo) then
			fileCardBorder = BigBorderDict[rare]
			spt = CCSprite:createWithSpriteFrameName(fileCardBorder)
			self.borderSize = {}
			self.borderSize.width = 320
			self.borderSize.height = 450
			spt:setScale(2)
		elseif(sizeInfoType == SizeInfoTypes.SmallWithProp or sizeInfoType == SizeInfoTypes.SmallWithLevel or sizeInfoType == SizeInfoTypes.SmallNoInfo) then
			fileCardBorder = SmallBorderDict[rare]
			spt = CCSprite:createWithSpriteFrameName(fileCardBorder)
			self.borderSize = {}
			self.borderSize.width = 143
			self.borderSize.height = 201
			spt:setScale(143 / 160)
			--spt:setScaleY(192 / 225)
		else 
			return nil
		end

		--local spt = CCSprite:createWithSpriteFrameName(fileCardBorder)
		self.borderSpt = CocosObject.new(spt)
	end

	if nil == self.bgSpt then
		local fileCardBg = "card/background/" .. meta.backgroundName

		local spt = CCSprite:create(fileCardBg)
		if spt == nil then
			spt = CCSprite:create("card/background/wei12_1234.jpg")
		end
		spt:setScaleX(self.borderSize.width / spt:getContentSize().width)
		spt:setScaleY(self.borderSize.height / spt:getContentSize().height)

		self.bgSpt = CocosObject.new(spt)
		self:addChild(self.bgSpt)
	end

	if nil == self.chestSpt then
		local sf = self.cardSprite:getSpriteFrameByName("sdandard.png")
		local spt = CCSprite:createWithSpriteFrame(sf) 

		spt:setScaleX(self.borderSize.width / spt:getContentSize().width)
		spt:setScaleY(self.borderSize.height / spt:getContentSize().height)

		self.chestSpt = CocosObject.new(spt)
		self:addChild(self.chestSpt)
	end
	self:addChild(self.borderSpt)

	if(sizeInfoType == SizeInfoTypes.SmallWithProp or sizeInfoType == SizeInfoTypes.SmallWithLevel or sizeInfoType == SizeInfoTypes.SmallNoInfo) then
		-- add country
		if nil == self.countrySpt then
			local fileCountry = "countryCircle_" .. country .. ".png"
			local scaleXfactor = 143 / 320
			local scaleYfactor = 192 / 225
			self.countrySpt = self:geneImageSpt(fileCountry, -67.5, 98.5 ,scaleXfactor , scaleXfactor)
			self:addChild(self.countrySpt)
		end
	end
	
	if(sizeInfoType == SizeInfoTypes.BigWithInfo or sizeInfoType == SizeInfoTypes.BigNoInfo) then
		-- add country
		if nil == self.countrySpt then
			local fileCountry = "countryCircle_" .. country .. ".png"
			self.countrySpt = self:geneImageSpt(fileCountry, -151, 223)
			self:addChild(self.countrySpt)
		end

		-- add country icon
		--if nil == self.countryIconSpt then
		--	local fileCountryIcon = "countryIcon_" .. country .. ".png"
		--	self.countryIconSpt = self:geneImageSpt(fileCountryIcon, -146.3, 210.1)
		--	self:addChild(self.countryIconSpt)
		--end
    
    -- add card name
		local cardName = getTextByKey(meta.name)
		--local bmpName = BitmapText:create(getTextByKey(meta.name), "common/card_name.fnt", 0, kCCTextAlignmentCenter)
		--bmpName:setPosition(ccp(0, 210))
		local cardName_sp = self:geneTextSpt(0, 210, CCSizeMake(0, 0), 24, kCCTextAlignmentCenter)
		cardName_sp:setString(cardName)
		self:addChild(cardName_sp)

		-- add level
		self.LVcao = self:geneImageSpt("LVcao.png", 66, 224)
		self.LVcao:setVisible(false)
		self.iconLvSpt = self:geneImageSpt("icon_lv.png", 86, 220)
		self.iconLvSpt:setVisible(false)
		self.textLv = self:geneTextSpt(135, 208, CCSizeMake(0, 0), 25, kCCTextAlignmentLeft)
		self.textLv:setColor(ccc3(255, 255, 0))
		self.textLv:setString("1")
		self.textLv:setVisible(false)
		self:addChild(self.LVcao)
		self:addChild(self.iconLvSpt)
		self:addChild(self.textLv)
    
    -- add evolveLevel / maxEvolveLevel
		
		--[[
		local maxEvolvedLevel = meta.maxEvolvedLevel
		self.evolveLevelSpts = {}
		for i = 1, evolveLevel, 1 do
			table.insert(self.evolveLevelSpts, self:geneImageSpt("icon_evolveLevel.png", evovlePosX + (i-1)*evovleInc, evovlePosY))
		end
		for i = evolveLevel + 1, maxEvolvedLevel, 1 do
			table.insert(self.evolveLevelSpts, self:geneImageSpt("icon_evolveLevel_disable.png", evovlePosX + (i-1)*evovleInc, evovlePosY))
		end
		if(self.evolveLevelSpts and #self.evolveLevelSpts > 0) then
			for i, evolveLevelSpt in ipairs(self.evolveLevelSpts) do
				self:addChild(evolveLevelSpt)
			end
		end
		--]]
		
		--for i = 1, evolveLevel, 1 do
		local evovlePosX = -88
		local evovlePosY = 195
		local evovleInc = 18
		local evolveLevel = meta.evolutionLevel
		local xin_bg = self:geneImageSpt("xin_bg.png", evovlePosX, evovlePosY-1)
		xin_bg:setAnchorPoint(ccp(0,1))
		xin_bg:setScaleX(rare)
		self:addChild(xin_bg)
		
		local xin_bg_ex = self:geneImageSpt("xin_bg_ex.png", evovlePosX + rare*evovleInc, evovlePosY-1)
		xin_bg_ex:setAnchorPoint(ccp(0,1))
		self:addChild(xin_bg_ex)
		
		for i = 1, rare, 1 do
			local xx = self:geneImageSpt("card_xing.png", evovlePosX + (i-1)*evovleInc, evovlePosY)
			xx:setScale(0.8)
			self:addChild(xx)
		end
	end

	if (sizeInfoType == SizeInfoTypes.BigWithInfo) then
		-- add exp
		--self.expBgSpt = self:geneImageSpt("bg_expGauge.png", 60.90, 207.85)
		--self:addChild(self.expBgSpt)

		-- add hp, atk, def
		self.atkBgSpt = self:geneImageSpt("bg_parameter.png", -148, -123.50)
		self.atkIconSpt = self:geneImageSpt("icon_atk.png", -148, -123.50)
		self.textAtk = self:geneTextSpt(-135, -131, CCSizeMake(68.7, 17.1), 16)

		self.defBgSpt = self:geneImageSpt("bg_parameter.png", -148, -154.20)
		self.defIconSpt = self:geneImageSpt("icon_def.png", -148, -154.20)
		self.textDef = self:geneTextSpt(-135, -162, CCSizeMake(68.7, 17.1), 16)

		self.hpBgSpt = self:geneImageSpt("bg_parameter.png", -148, -186.95)
		self.hpIconSpt = self:geneImageSpt("icon_hp.png", -148, -191.65)
		self.textHp = self:geneTextSpt(-135, -194, CCSizeMake(68.7, 17.1), 16)

		self:addChild(self.atkBgSpt)
		self:addChild(self.atkIconSpt)
		self:addChild(self.textAtk)

		self:addChild(self.defBgSpt)
		self:addChild(self.defIconSpt)
		self:addChild(self.textDef)

		self:addChild(self.hpBgSpt)
		self:addChild(self.hpIconSpt)
		self:addChild(self.textHp)
		
		self:setHp()
		self:setDef()
		self:setAtk()

		-- todo add rare
	elseif (sizeInfoType == SizeInfoTypes.SmallWithLevel) then
		-- add level rare
		self.iconLvSpt = self:geneImageSpt("icon_lv.png", -82.9, -98.9)
		self.textLv = self:geneTextSpt(-47.6, -95.5, CCSizeMake(45.7, 26.8), 22, kCCTextAlignmentLeft)
		self.textLv:setColor(ccc3(255, 255, 0))
		self:addChild(self.iconLvSpt)
		self:addChild(self.textLv)

		-- add rare
		self.rareStarSpt = self:geneImageSpt("icon_rarity.png", 42.7, -97)
		self.textRare = self:geneTextSpt(68.7, -93.5, CCSizeMake(17.35, 28.1), 22, kCCTextAlignmentLeft)
		self.textRare:setString(rare)
		self:addChild(self.rareStarSpt)
		self:addChild(self.textRare)

	elseif (sizeInfoType == SizeInfoTypes.SmallWithProp) then
		-- add hp, atk, def
		self.atkIconSpt = self:geneImageSpt("icon_atk_small.png", -32.1, -31.5)
		self.textAtk = self:geneTextSpt(-7.4, -30.4, CCSizeMake(91.75, 26.1), 22)

		self.defIconSpt = self:geneImageSpt("icon_def_small.png", -28.3, -59.4)
		self.textDef = self:geneTextSpt(-7.4, -62.2, CCSizeMake(91.75, 26.1), 22)

		self.hpIconSpt = self:geneImageSpt("icon_hp_small.png", -28.3, -91.1)
		self.textHp = self:geneTextSpt(-7.4, -92, CCSizeMake(91.75, 26.1), 22)

		self:addChild(self.atkIconSpt)
		self:addChild(self.textAtk)

		self:addChild(self.defIconSpt)
		self:addChild(self.textDef)

		self:addChild(self.hpIconSpt)
		self:addChild(self.textHp)
	end
end

function CanonCard:setLevel(level)
	if(self.textLv) then
		self.iconLvSpt:setVisible(true)
		self.textLv:setVisible(true)
		self.LVcao:setVisible(true)
		self.textLv:setString(not level and "0" or tostring(level))
	end
end

--[[
function CanonCard:setExp(exp, maxExp) -- 只有大图有信息才显示
	self:removeChild(self.expBar)
	local scaleX = exp > maxExp and 1 or exp / (maxExp * 1.0)
	self.expBar = self:geneImageSpt("bg_exp.png", 62.65, 206.85, scaleX)

	self:addChild(self.expBar)
end
--]]

function CanonCard:setHp(hp)
	if(self.textHp) then
		self.textHp:setString(not hp and "0" or tostring(hp))
	end
end

function CanonCard:setAtk(atk)
	if(self.textAtk) then
		self.textAtk:setString(not atk and "0" or tostring(atk))
	end
end

function CanonCard:setDef(def)
	if(self.textDef) then
		self.textDef:setString(not def and "0" or tostring(def))
	end
end

function CanonCard:dispose()
	if self.cardSprite then
      self.cardSprite:release()
	end
      Layer.dispose(self)
end

