-------------------------------------------------------------------------
--  Class include: kAnimationEvents, ArmatureNode, ArmatureFactory
-------------------------------------------------------------------------

require "hecore.display.Director"

kAnimationTweenType = {
    TWEEN_EASING_MIN,    
    Linear,    
    Sine_EaseIn, Sine_EaseInOut, Sine_EaseOut,
    Quad_EaseIn, Quad_EaseOut, Quad_EaseInOut,
    Cubic_EaseIn, Cubic_EaseOut, Cubic_EaseInOut,
    Quart_EaseIn, Quart_EaseOut, Quart_EaseInOut,
    Quint_EaseIn, Quint_EaseOut, Quint_EaseInOut,
    Expo_EaseIn, Expo_EaseOut, Expo_EaseInOut,
    Circ_EaseIn, Circ_EaseOut, Circ_EaseInOut,
    Elastic_EaseIn, Elastic_EaseOut, Elastic_EaseInOut,    
    Back_EaseIn, Back_EaseOut, Back_EaseInOut,
    Bounce_EaseIn, Bounce_EaseOut, Bounce_EaseInOut,
    TWEEN_EASING_MAX
}

kAnimationEvents = {kStart = "start", kComplete = "complete", kLoopComplete = "loopComplete"}

--
-- ArmatureNode ---------------------------------------------------------
--

ArmatureNode = class(CocosObject)

function ArmatureNode:create( name )
	local node = Armature:create(name)
	local animation = nil
	if node then animation = node:getAnimation() end

	local ret = nil
	local function onAnimationEvent( eventType )
		if ret:hn(eventType) then ret:dp(Event.new(eventType, nil, ret)) end
	end 
	if animation then animation:registerScriptHandler(onAnimationEvent) end
	ret = ArmatureNode.new(node)
	return ret
end

--
--  --------------------------------------------------------- Armature methods

--Animation
function ArmatureNode:getAnimation() return self.refCocosObj:getAnimation() end
function ArmatureNode:setAnimation(v) self.refCocosObj:setAnimation(v) end

--ArmatureData
function ArmatureNode:getArmatureData() return self.refCocosObj:getArmatureData() end
function ArmatureNode:setArmatureData(v) self.refCocosObj:setArmatureData(v) end

function ArmatureNode:getName() return self.refCocosObj:getName() end
function ArmatureNode:setName(v) self.refCocosObj:setName(v) end
--CCTextureAtlas
function ArmatureNode:getTextureAtlas() return self.refCocosObj:getTextureAtlas() end
function ArmatureNode:setTextureAtlas(v) self.refCocosObj:setTextureAtlas(v) end
--Bone
function ArmatureNode:getParentBone() return self.refCocosObj:getParentBone() end
function ArmatureNode:setParentBone(v) self.refCocosObj:setParentBone(v) end

function ArmatureNode:addBone(bone, parentName) self.refCocosObj:addBone(bone, parentName) end
function ArmatureNode:getBone(name) return self.refCocosObj:getBone(name) end
function ArmatureNode:changeBoneParent( bone, parentName )
	self.refCocosObj:changeBoneParent(bone, parentName)
end

function ArmatureNode:update( dt ) self.refCocosObj:update(dt) end

function ArmatureNode:removeBone( bone, recursion ) self.refCocosObj:removeBone(bone, recursion) end
function ArmatureNode:getBoneDict( ) return self.refCocosObj:getBoneDict() end
function ArmatureNode:boundingBox() return self.refCocosObj:boundingBox() end
function ArmatureNode:getBoneAtPoint( x, y ) return self.refCocosObj:getBoneAtPoint(x, y) end

--
--  --------------------------------------------------------- Animation methods

function ArmatureNode:play( animationName, durationTo, durationTween, loop, tweenEasing )
	local animation = self:getAnimation()
	if animation and animationName then
		durationTo = durationTo or -1
		durationTween = durationTween or -1
		loop = loop or -1
		tweenEasing = tweenEasing or TWEEN_EASING_MAX
		animation:play(animationName, durationTo, durationTween, loop, tweenEasing)
	end
end
function ArmatureNode:playByIndex( animationIndex, durationTo, durationTween, loop, tweenEasing )
	local animation = self:getAnimation()
	if animation then
		durationTo = durationTo or -1
		durationTween = durationTween or -1
		loop = loop or -1
		tweenEasing = tweenEasing or TWEEN_EASING_MAX
		animation:playByIndex(animationIndex, durationTo, durationTween, loop, tweenEasing)
	end
end
function ArmatureNode:getMovementCount()
	local animation = self:getAnimation()
	if animation then return animation:getMovementCount() end
	return 0
end
function ArmatureNode:setAnimationScale( animationScale )
	local animation = self:getAnimation()
	if animation then animation:setAnimationScale(animationScale) end
end

function ArmatureNode:pause()
	local animation = self:getAnimation()
	if animation then animation:pause() end
end
function ArmatureNode:resume()
	local animation = self:getAnimation()
	if animation then animation:resume() end
end
function ArmatureNode:stop()
	local animation = self:getAnimation()
	if animation then animation:stop() end
end
function ArmatureNode:getCurrentFrameIndex()
	local animation = self:getAnimation()
	if animation then return animation:getCurrentFrameIndex() end
	return -1
end

--NOTICE: this is just a reference. C++ object not retain.
function ArmatureNode:getChildArmature( name )
	local bone = self:getBone(name)
	local armature = nil
	if bone then armature = bone:getArmature() end -- or getChildArmature?
	if armature then
		local animation = armature:getAnimation()
		local ret = ArmatureNode.new(armature)
		
		local function onAnimationEvent( eventType )
			if ret:hn(eventType) then ret:dp(Event.new(eventType, nil, ret)) end
		end 
		if animation then animation:registerScriptHandler(onAnimationEvent) end
		--just return a reference.
		ret.refCocosObj:release()
		return ret
	end
	return nil
end

--
--  --------------------------------------------------------- Bone methods
function ArmatureNode:addChildDisplay(childBoneName, frameName, index)
	local bone = self:getBone(childBoneName)
	if bone then
		local data = SpriteDisplayData:create()
		data:setParam(frameName)
		bone:addDisplay(data, index)
	end
end
function ArmatureNode:changeChildDisplay( childBoneName, displayIndex )
	local bone = self:getBone(childBoneName)
	if bone then
		bone:changeDisplayByIndex(displayIndex, true)
	end
end

--
-- ArmatureFactory ---------------------------------------------------------
--

--all static function

ArmatureFactory = {}

function ArmatureFactory:add(imagePath, plistPath, configFilePath)
	ArmatureDataManager:sharedArmatureDataManager():addArmatureFileInfo(imagePath, plistPath, configFilePath)
end

function ArmatureFactory:clean()
	ArmatureDataManager:sharedArmatureDataManager():purgeArmatureSystem()
end

function ArmatureFactory:createParticleDisplayData( plist )
	local node = ParticleDisplayData:create()
	node:setParam(plist)
	return node
end

function ArmatureFactory:createSpriteDisplayData( displayName )
	local node = ParticleDisplayData:create()
	node:setParam(displayName)
	return node
end

function ArmatureFactory:createShaderDisplayData( vert, frag )
	local node = ParticleDisplayData:create()
	node:setParam(vert, frag)
	return node
end

function ArmatureFactory:createBone( boneName, displayData, ignoreMovementBoneData, zorder )
	local node = Bone:create(boneName)
	if displayData then
		node:addDisplay(displayData, 0)
		node:changeDisplayByIndex(0, true)
	end
	if ignoreMovementBoneData then node:setIgnoreMovementBoneData(true) end
	zorder = zorder or 0
	node:setZOrder(zorder)
	return node
end