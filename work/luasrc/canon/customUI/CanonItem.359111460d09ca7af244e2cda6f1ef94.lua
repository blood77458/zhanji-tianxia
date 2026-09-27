

require "hecore.display.Sprite"
require "hecore.display.CocosObject"
require "hecore.display.Layer"
require "canon.data.MetaManager"



CanonItem = class(Layer);
function CanonItem:ctor()
	self.name = "CanonItem"
	self.bg = nil
	self.border = nil
	self.icon = nil
end

--static create function
function CanonItem:create()
	local item = CanonItem.new()
	item:initLayer()
	return item
end

function CanonItem:loadByMetaId(metaId, isCalendar, isShowStar)

	local aMeta = nil 
	local quality
	if tonumber(metaId) > 200000 and tonumber(metaId) < 250000 then
		aMeta = MetaManager.equip_meta[metaId]    --equip	
		quality = aMeta["quality"]
	elseif metaId > 30000000 and metaId < 40000000 then 
		aMeta = MetaManager.skill_meta[metaId]    --skill  
		quality = aMeta["quality"]
    elseif metaId > 400000 and metaId < 500000 then                    
        aMeta = MetaManager.prop_meta[metaId]     --prop 
        quality = aMeta["quality"] 
    elseif metaId > 600000 and metaId < 700000 then
    	aMeta = MetaManager.spirit_meta[metaId]		--spirit
    	quality = aMeta["rarity"]
    elseif metaId > 900000 and metaId < 910000 then
    	aMeta = MetaManager.equip_meta[MetaManager.equip_fragment_meta[metaId].equipId]		--equip soul
    	quality = aMeta["quality"]
	elseif metaId > 250000 and metaId < 300000 then
		aMeta = MetaManager.treasure_meta[metaId]		--treasure
    	quality = aMeta["rare"]
	end
    
	if aMeta then
        if quality > 7 then quality = 1 end		
        local pathAndName = nil
        local name = nil
		if (metaId > 200000 and metaId <250000) or (metaId > 900000 and metaId < 910000) then --equip,equip soul     
			name = aMeta["icon"]
			if name == nil then
				name = aMeta["PNGPrefix"]
			end
            local len = string.len(tostring(quality))      
			name = string.sub(name,1,string.len(name)-len) 
    	elseif metaId > 30000000 and metaId < 40000000 then --skill 
			name = aMeta["icon"]			
            local len = string.len(tostring(aMeta["level"]))
            name = string.sub(name,1,string.len(name)-len) 
        elseif metaId > 400000 and metaId < 500000 then         --prop
			name = aMeta["iconName"]			
            local len = string.len(tostring(quality))
            name = string.sub(name,1,string.len(name)-len) 
        elseif metaId > 600000 and metaId < 700000 then		--spirit
        	name = aMeta["icon"]
        elseif metaId > 250000 and metaId < 300000 then    --treasure
        	name = aMeta["figureID"]

		end
		if isCalendar then
			pathAndName = "" .. name .. "0_calendar.png"
		else
			pathAndName = "" .. name .. "0.png"
		end
		
		if metaId > 600000 and metaId < 700000 then
			pathAndName = name .. ".png"
			self.effect = FlashSprite:create("EVO2/elesoul_effect_s")
			self.effect:changeAnimation(quality-1)
			self.effect:setLoop(true)
			self.effect = CocosObject.new(self.effect)
		end

		if metaId > 250000 and metaId < 300000 then
			pathAndName = "treasure/" .. aMeta["figureID"]..".png"
		end
		
        local fileUtils = CCFileUtils:sharedFileUtils()
        local spt = CCSprite:create("Item/Picture/"..pathAndName )
        if spt then
            self.icon = Sprite.new(spt)
        end
		
        self:setQuality(quality, true, isCalendar)        
	
        if self.icon == nil then
            self.icon = Sprite.new(CCSprite:createWithSpriteFrameName("Item_empty.png" ))
            self:setQuality(quality, false)
        end

		if isShowStar then
        	--ÏÔÊ¾ÐÇÐÇ
	        local evovlePosY = -38
			local evovleInc = 22
			local xin_w = (quality - 1)*evovleInc
			local evovlePosX = -(xin_w/2) - 11
		
			for i = 1, quality, 1 do
				local x = self:geneImageSpt("card_xing.png", evovlePosX + (i-1)*evovleInc, evovlePosY)
				--x:setScale(0.8)
				self:addChild(x)
			end
		end

		if metaId > 900000 and metaId < 910000 then
			local aSmallIcon = Sprite:create("Item/Picture/Prop_soul_item.png")
			aSmallIcon:setPosition( ccp(37, 47) )
			self:addChild(aSmallIcon)
		end
    end
end

function CanonItem:setQuality( quality, withBg , isCalendar)
	--Put background
	if (withBg) and not isCalendar then
		local spt = CCSprite:create("Item/border/equipBg" .. quality .. ".png")
		self.bg = Sprite.new(spt)

		self:addChild(self.bg)
	end
	
	--Put icon
	self:addChild(self.icon)
	if not isCalendar then
		--Put border
		spt = CCSprite:create("Item/border/equipBorder" .. quality .. ".png")
		spt:setScale(144/138) --130
		self.border = Sprite.new(spt)
		self:addChild(self.border)
	end
	
	--Put effect
	if self.effect then
		self:addChild(self.effect)
	end
end

----------------------------------------
-- ÔÚÖ¸¶¨Î»ÖÃÉú³ÉÌí¼ÓÍ¼Æ¬
-- ×¢: posX,posYÎªËØ²Ä×óÉÏ½ÇµÄ×ø±ê
----------------------------------------
function CanonItem:geneImageSpt(spriteFrameName, posX, posY, scaleX, scaleY)
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