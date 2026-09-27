-------------------------------------------------------------------------
--  Class include: Sprite, SpriteUtil, Scale9Sprite
-------------------------------------------------------------------------

require "hecore.display.CocosObject"

local __kTexturePixelFormat__ = {}



--
-- Sprite ---------------------------------------------------------
--

Sprite = class(CocosObject);

function Sprite:toString()
	return string.format("Sprite [%s]", self.name and self.name or "nil");
end

--
-- public props ---------------------------------------------------------
--
--ccBlendFunc
function Sprite:getBlendFunc() return self.refCocosObj:getBlendFunc() end
function Sprite:setBlendFunc(v) self.refCocosObj:setBlendFunc(v) end	

--ccColor3B
function Sprite:getColor() return self.refCocosObj:getColor() end
function Sprite:setColor(v) self.refCocosObj:setColor(v) end

function Sprite:isOpacityModifyRGB() return self.refCocosObj:isOpacityModifyRGB() end
function Sprite:setOpacityModifyRGB(v) self.refCocosObj:setOpacityModifyRGB(v) end


--CCSpriteFrame
function Sprite:isFrameDisplayed(v) return self.refCocosObj:isFrameDisplayed(v) end
function Sprite:setDisplayFrame(v) self.refCocosObj:setDisplayFrame(v) end
function Sprite:displayFrame() return self.refCocosObj:displayFrame() end
function Sprite:setUserData(v) self.refCocosObj:setUserData(v) end

--CCRect
function Sprite:setTextureRect(v) self.refCocosObj:setTextureRect(v) end
function Sprite:getTextureRect() return self.refCocosObj:getTextureRect() end
--CCRect rect, bool rotated, CCSize size
function Sprite:setTextureRect2(rect, rotated, size) self.refCocosObj:setTextureRect(rect, rotated, size) end

function Sprite:play(animate, delay, repeatTimes, onRepeatFinishCallback, removeAfterRepeatFinished)
  local repeatAction = nil
  local context = self
  if type(repeatTimes) == "number" and repeatTimes > 0 then
    local function onRepeatFinished()
      if onRepeatFinishCallback then onRepeatFinishCallback() end
      if removeAfterRepeatFinished then context:removeFromParentAndCleanup(true) end
    end
    repeatAction = CCSequence:createWithTwoActions(CCRepeat:create(animate, repeatTimes), CCCallFunc:create(onRepeatFinished))
  else repeatAction = CCRepeatForever:create(animate) end
  
  if type(delay) == "number" and delay > 0 then
    self:setVisible(false)
    --repeatAction is a C++ object, we need to retain it's reference count.
    repeatAction:retain()
    local function onDelayTimeFinished()
      context:setVisible(true)
      context:stopAllActions()
      context:runAction(repeatAction)
      
      --after the delay time, release the reference count for GC
      repeatAction:release()
    end
    self:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(delay), CCCallFunc:create(onDelayTimeFinished)))
  else
    self:runAction(repeatAction)
  end
end

--
--
-- static create function ---------------------------------------------------------
--

-- create a sprite with **the** image filename or sprite frame name. sprite frame name have prefix '#'.
--Example:
--  create with an image
--  sprite = SpriteUtil:buildSprite("hello1.png")
--  or with a sprite frame
--  sprite = SpriteUtil:buildSprite("#frame0001")
function Sprite:create(fileName)
  if not fileName then 
    local sprite = CCSprite:create()
    return Sprite.new(sprite)
  end
  
  if string.byte(fileName) == 35 then 
    -- start with "#"
    if fileName:sub(-4) == "0000" then
      local sprite = CCSprite:create(UI_RES_PATH.."/"..string.sub(fileName, 2, -5)..".png")
      return Sprite.new(sprite)
    else
      local sprite = CCSprite:createWithSpriteFrameName(string.sub(fileName, 2))
      return Sprite.new(sprite)
    end
  else
    local sprite = nil
    if __kTexturePixelFormat__[fileName] then
      CCTexture2D:setDefaultAlphaPixelFormat(__kTexturePixelFormat__[fileName])
      sprite = CCSprite:create(fileName)
      CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)
    else
      sprite = CCSprite:create(fileName)
    end
    return Sprite.new(sprite)
  end
end

function Sprite:createWithSpriteFrameName(frameName)
  return Sprite.new(CCSprite:createWithSpriteFrameName(frameName));
end

function Sprite:createWithSpriteFrame(frame)
  return Sprite.new(CCSprite:createWithSpriteFrame(frame));
end

function Sprite:createWithTexture(texture)
  return Sprite.new(CCSprite:create(texture));
end




--
-- SpriteUtil ---------------------------------------------------------
--

SpriteUtil = {};

function SpriteUtil:buildAnimatedSprite(timePerFrame, pattern, begin, length, isReversed)
  local frames = SpriteUtil:buildFrames(pattern, begin, length, isReversed)
  local sprite = CCSprite:createWithSpriteFrame(frames[1])
  local animate = SpriteUtil:buildAnimate(frames, timePerFrame)
  return Sprite.new(sprite), animate
end

--Creates a sprite that it's texture repeated to fill the whole content area.
function SpriteUtil:buildRepeatedSprite(fileName, repeatRect)
  if not fileName then 
    print("build repeated sprite fail. no filename") 
    return
  end
  if not repeatRect then
    local winsize = CCDirector:sharedDirector():getWinSize()
    repeatRect = CCRectMake(0,0,winsize.width, winsize.height)
  end
  local p = ccTexParams()
  p.minFilter = GL_LINEAR -- GL_LINEAR, 0x2601
  p.magFilter = GL_LINEAR
  p.wrapS = GL_REPEAT -- GL_REPEAT, 0x2901
  p.wrapT = GL_LINEAR
  local sprite = CCSprite:create(fileName, repeatRect)
  sprite:getTexture():setTexParameters(p)
  return Sprite.new(sprite)
end

-- mapping texture's CCTexture2DPixelFormat with filename.
-- common use: kTexture2DPixelFormat_RGB565 kTexture2DPixelFormat_RGB888 kTexture2DPixelFormat_RGBA8888 
-- kTexture2DPixelFormat_RGBA4444 kTexture2DPixelFormat_RGB5A1
-- kCCTexture2DPixelFormat_PVRTC4 kCCTexture2DPixelFormat_PVRTC2
function SpriteUtil:setTexturePixelFormat(fileName, pixelFormat)
  __kTexturePixelFormat__[fileName] = pixelFormat
end

--Adds multiple Sprite Frames from a plist file. The texture will be associated with the created sprite frames.
-- if texture contains special pixel format, use setTexturePixelFormat first.
function SpriteUtil:addSpriteFramesWithFile(plistFilename, textureFileName)
  local sharedSpriteFrameCache = CCSpriteFrameCache:sharedSpriteFrameCache()
  if __kTexturePixelFormat__[textureFileName] then
    CCTexture2D:setDefaultAlphaPixelFormat(__kTexturePixelFormat__[textureFileName])
    sharedSpriteFrameCache:addSpriteFramesWithFile(plistFilename, textureFileName)
    CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)
  else
    --sharedSpriteFrameCache:addSpriteFramesWithFile(plistFilename, textureFileName)
	PlistResMgr:getInstance():loadPlist(plistFilename)
  end
end

function SpriteUtil:cacheTexture(textureFileName)
  if __kTexturePixelFormat__[textureFileName] then
    CCTexture2D:setDefaultAlphaPixelFormat(__kTexturePixelFormat__[textureFileName])
    CCTextureCache:sharedTextureCache():addImage(textureFileName)
    CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)
  else
    CCTextureCache:sharedTextureCache():addImage(textureFileName)
  end
end

--Creates multiple frames by pattern.
-- Example:
-- create array of CCSpriteFrame [walk0001.png -> walk0020.png]
-- local frames = SpriteUtil:buildFrames("walk%04d.png", 1, 20)
function SpriteUtil:buildFrames(pattern, begin, length, isReversed)
  if not pattern then 
    print("build frames fail. no pattern") 
    return
  end
  --https://github.com/dualface/quick-cocos2d-x/blob/master/framework/client/display.lua#newFrames
  local sharedSpriteFrameCache = CCSpriteFrameCache:sharedSpriteFrameCache()
  local frames = {}
  local step = 1
  local last = begin + length - 1
  if isReversed then
    last, begin = begin, last
    step = -1
  end

  for index = begin, last, step do
    local frameName = string.format(pattern, index)
    local frame = sharedSpriteFrameCache:spriteFrameByName(frameName) --CCSpriteFrame* spriteFrameByName(const char *pszName);
    if not frame then print("invalid frame, name %s", frameName) end
    frames[#frames + 1] = frame
  end
  return frames
end

-- Example:
--  local frames    = SpriteUtil:buildFrames("walk_%02d.png", 1, 20)
--  local animation = SpriteUtil:buildAnimate(frames, 0.5 / 20) -- in 0.5s play 20 frames
function SpriteUtil:buildAnimate(frames, time)
  --https://github.com/dualface/quick-cocos2d-x/blob/master/framework/client/display.lua#newAnimation
  local count = #frames
  local array = CCArray:create()
  for i = 1, count do
    array:addObject(frames[i])
  end
  time = time or 1.0 / count
  return CCAnimate:create(CCAnimation:createWithSpriteFrames(array, time))
end




--
-- Scale9Sprite ---------------------------------------------------------
--

local kZeroCapInsets = CCRectMake(0,0,0,0)

Scale9Sprite = class(CocosObject);

function Scale9Sprite:toString()
  return string.format("Scale9Sprite [%s]", self.name and self.name or "nil");
end

--
-- public props ---------------------------------------------------------
--
--CCSize
function Scale9Sprite:getOriginalSize() return self.refCocosObj:getOriginalSize() end
--CCSize
function Scale9Sprite:getPreferredSize() return self.refCocosObj:getPreferredSize() end
function Scale9Sprite:setPreferredSize(v) self.refCocosObj:setPreferredSize(v) end
--CCRect
function Scale9Sprite:getCapInsets() return self.refCocosObj:getCapInsets() end
function Scale9Sprite:setCapInsets(v) self.refCocosObj:setCapInsets(v) end

function Scale9Sprite:resizableSpriteWithCapInsets(v) return self.refCocosObj:resizableSpriteWithCapInsets(v) end
function Scale9Sprite:setSpriteFrame(v) self.refCocosObj:setSpriteFrame(v) end

--
--
-- static create function ---------------------------------------------------------
--

function Scale9Sprite:create(fileName, capInsets)
  capInsets = capInsets or kZeroCapInsets
  local sprite = CCScale9Sprite:create(capInsets, fileName)
    return Scale9Sprite.new(sprite)
end

function Scale9Sprite:createWithSpriteFrame(spriteFrame, capInsets)
  capInsets = capInsets or kZeroCapInsets
    local sprite = CCScale9Sprite:createWithSpriteFrame(spriteFrame, capInsets)
    return Scale9Sprite.new(sprite)
end

function Scale9Sprite:createWithSpriteFrameName(spriteFrameName, capInsets)
  capInsets = capInsets or kZeroCapInsets
    local sprite = CCScale9Sprite:createWithSpriteFrameName(spriteFrameName, capInsets)
    return Scale9Sprite.new(sprite)
end
