

require "hecore.display.Sprite"
require "hecore.display.CocosObject"
require "hecore.display.Layer"



BaseItem = class(Layer)
function BaseItem:ctor()
	self.name = "BaseItem"
	self.border = {}
end

function BaseItem:load(path, name)
	
	
end

function CanonCard:removeAllDisplayObject()
	self:removeChild(self.bodySpt, false)
	self:removeChild(self.headSpt, false)
	self:removeChild(self.chestSpt, false)
	self:removeChild(self.bgSpt, false)
	self:removeChild(self.borderSpt, false)
end

function CanonCard:changeType( cardType )
	if self.type ~= cardType then
		if cardType == kCanonCardType.kCT_Normal then
			self:removeAllDisplayObject()
			self:addChild(self.bgSpt)
			self:addChild(self.chestSpt)
			self:addChild(self.borderSpt)
		elseif cardType == kCanonCardType.kCT_Full then
		    
		elseif cardType == kCanonCardType.kCT_Head then
			  
		end
		
		
	end
end






