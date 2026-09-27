require "hecore.display.Director"
require "hecore.display.TextField"

if Director:getOpenGLView():getDesignResolutionSize().height == 1280 then
  g_resolutionHeight = 1280
  g_wideDevice = false
else
  g_resolutionHeight = 1080
  g_wideDevice = true
end

UI_RES_PATH = "ui_res"
UI_JSON_PATH = "ui_json"
UI_JSON_HEADER_LENGTH = 9

local kDrawDebugRect = false
local configCached = {}
local simplejson = require("hecore.simplejson")
local builderCached = {}

kGroupLayoutType = {kImage = 0, kText = 1, kGroup = 2}

local globalFontMapping = {}

LayoutBuilder = class()
function LayoutBuilder:ctor(config)
  self.name = config.name
  self.sceneFolder = config.sceneFolder
  self.config = config
  self.fontMapping = {}
  self.fontBuilderFunc = {}
  if __ANDROID then
    self.enableLabelCache = (not IsDiaosiDevice())
  else
    self.enableLabelCache = (not IsDiaosiDevice())
  end
end

function LayoutBuilder:createWithContentsOfFile(filePath)
  filePath = UI_JSON_PATH..filePath:sub(6)
  local aBuilder = builderCached[filePath]
  if aBuilder then
    return aBuilder
  end
  local config = configCached[filePath]
  if not config then
    local t = CCString:createWithContentsOfFile(filePath):getCString()
    
    config = simplejson.decode(t)
    configCached[filePath] = config
  end
  local fileSeparater = "/"

  local separatedFilePath = filePath:split(fileSeparater)
  local prefix = separatedFilePath[1]..fileSeparater
  if #separatedFilePath == 1 then prefix = "" end
  local plist = prefix .. config.config
  local image = prefix .. config.image
  config.name = filePath
  config.sceneFolder = filePath:sub(UI_JSON_HEADER_LENGTH, -6)
  --SpriteUtil:addSpriteFramesWithFile(plist, image)
  aBuilder = LayoutBuilder.new(config)
  builderCached[filePath] = aBuilder
  return aBuilder
end

local function setBasicTransformation(image, symbol, parent)
  image.name = symbol.id
  
  image:setPosition(ccp(symbol.x, -symbol.y))

  local image_Size = nil
  if symbol.type == kGroupLayoutType.kImage then --对于图片，获取图片显示的尺寸
    image_Size = image:getTextureRect().size
  end

  if image_Size ~= nil then
    image:setScaleX( symbol.width/image_Size.width ) --图片显示的宽度要与flash设计的完全一致，从而解决了图像畸变bug
    image:setScaleY( symbol.height/image_Size.height ) --图片显示的高度要与flash设计的完全一致，从而解决了图像畸变bug
  else
    image:setScaleX( symbol.scaleX )
    image:setScaleY( symbol.scaleY )
  end

  if symbol.rotation ~= nil then
    if symbol.rotation ~= 0 then image:setRotation(symbol.rotation) end
  else
    image:setRotationX(symbol.skewX)
    image:setRotationY(symbol.skewY)
  end
  
  if symbol.alpha and symbol.alpha < 1 then
    image:setAlpha(symbol.alpha)
  end
  
  parent:addChild(image)
  if symbol.type == kGroupLayoutType.kImage and symbol.id == kHitAreaObjectName then
    image:setVisible(false)
  end
end

local function buildText(symbol, builder)

--[[
  if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID then
	symbol.size = symbol.size + 2
	symbol.width = symbol.width * 1.2
	symbol.height = symbol.height * 1.2
  end
--]]
  local useArtLabelTTF = builder.useArtLabelTTF
  local hAlignment = kCCTextAlignmentLeft
  if symbol.alignment == "center" then
    hAlignment = kCCTextAlignmentCenter 
  elseif symbol.alignment == "right" then
    hAlignment = kCCTextAlignmentRight
  end
    
  local text
  if symbol.textType == "static" then
  if useArtLabelTTF and symbol.fillColor:lower() == "#ffffff" then
    text = ArtTextField:create("",builder:getFontFace(symbol.face), symbol.size, CCSizeMake(symbol.width, symbol.height), hAlignment, kCCVerticalTextAlignmentTop)
    if (not IsDiaosiDevice) then
      text:setCacheEnabled(true)
    end
  else
    text = TextField:create("",builder:getFontFace(symbol.face), symbol.size, CCSizeMake(symbol.width, symbol.height), hAlignment, kCCVerticalTextAlignmentTop)
    text:setColor(builder:hex2ccc3(symbol.fillColor))
    text:setCacheEnabled(false)
  end

  if builder.enableLabelCache then
    text:setCacheEnabled(true)
  end
    
  else
    if symbol.dynamicName then
      text = BitmapText:create("bitmap", builder:getFontFace(symbol.face), symbol.width, hAlignment)
    end
  end
  if text then
    text.name = symbol.id
    text:setPosition(ccp(symbol.x, -symbol.y))
    text:setAnchorPoint(ccp(0,1))
    if symbol.rotation ~= nil then
      if symbol.rotation ~= 0 then text:setRotation(symbol.rotation) end
    else
      text:setRotationX(symbol.skewX)
      text:setRotationY(symbol.skewY)
    end
  end
  return text
end

local function sortBoneDepthList(a, b)
  return a.index < b.index;
end

local function addDebugBounds(layout, parentLayer)
  if not kDrawDebugRect then return end

  local bounds = layout:getGroupBounds()
  local boundsLayer = LayerColor:create()
  boundsLayer:setColor(ccc3(128,55,144))
  boundsLayer:setOpacity(80)
  boundsLayer:changeWidthAndHeight(bounds.size.width, bounds.size.height)
  boundsLayer:setAnchorPoint(ccp(0,0))
  boundsLayer:setPosition(ccp(bounds.origin.x, bounds.origin.y))
  parentLayer:addChild(boundsLayer)
end
function LayoutBuilder:build(groupName, imageSuffix, alpha)
  if not self.config then
    print("build ui fail. no config:"..groupName)
    return nil
  end
  local group = self.config.groups[groupName];
  if not group then
    print("build ui fail. no group:"..groupName)
    return nil
  end
  
  imageSuffix = imageSuffix or "0000"

  local groupLayer = alpha and LayerRGBA:create() or Layer:create()
  groupLayer.name = groupName

  table.sort(group, sortBoneDepthList);
  for k, symbol in ipairs(group) do
    if symbol.type == kGroupLayoutType.kImage then
      local image = nil
      if type(symbol.scalingGrid) == "boolean" and symbol.scalingGrid then
        --image = assert(Scale9Sprite:createWithSpriteFrameName(symbol.image..imageSuffix))
        image = assert(Scale9Sprite:create(UI_RES_PATH.."/"..self.sceneFolder.."/"..symbol.image..".png"))
        image.name = symbol.id
        image:setPosition(ccp(symbol.x, -symbol.y))

        --local contentSize = image:getContentSize()
        --image:setPreferredSize(CCSizeMake(contentSize.width*symbol.scaleX, contentSize.height*symbol.scaleY))
        image:setPreferredSize(CCSizeMake(symbol.width, symbol.height))

        --add by zheng.che @ 2014-6-6 解决使用getNodeGroupBounds接口而元件中包含九宫格时导致结果尺寸略有偏差问题
        if image.refCocosObj and image.refCocosObj:getChildren() and (image.refCocosObj:getChildrenCount()>0) then
          local scale9Image = tolua.cast(image.refCocosObj:getChildren():objectAtIndex(0), "CCNode")
          local children = scale9Image:getChildren()
          local childrenCount = scale9Image:getChildrenCount()--应该是9个
          for i=0,childrenCount-1 do
            tolua.cast(children:objectAtIndex(i), "CCSprite"):setAnchorPoint(ccp(0,1))
          end
        end

        if symbol.rotation ~= nil then
          if symbol.rotation ~= 0 then image:setRotation(symbol.rotation) end
        else
          image:setRotationX(symbol.skewX)
          image:setRotationY(symbol.skewY)
        end
        
        groupLayer:addChild(image)
      else
        if symbol.width == 0 or symbol.height == 0 then
          image = assert(Sprite:create())
        else
          image = assert(Sprite:create(UI_RES_PATH.."/"..self.sceneFolder.."/"..symbol.image..".png"))
        end
        setBasicTransformation(image, symbol, groupLayer)
      end
      
      image:setAnchorPoint(ccp(0,1))
      addDebugBounds(image, groupLayer)
    elseif symbol.type == kGroupLayoutType.kText then
      local builder = self.fontBuilderFunc[symbol.id]
      builder = builder or buildText
      local text = builder(symbol, self)
      if text then
        groupLayer:addChild(text)
        addDebugBounds(text, groupLayer)
      end
    elseif symbol.type == kGroupLayoutType.kGroup then
      local layout = self:build(symbol.image, imageSuffix, alpha or (symbol.alpha and symbol.alpha < 1))
      if layout then
        setBasicTransformation(layout, symbol, groupLayer)
        addDebugBounds(layout, groupLayer)
      end
    end
  end

  if kDrawDebugRect then
    local boundsLayer = LayerColor:create()
    boundsLayer:setColor(ccc3(128,155,144))
    boundsLayer:changeWidthAndHeight(4,4)
    boundsLayer:setAnchorPoint(ccp(0,0))
    groupLayer:addChild(boundsLayer)
  end
  
  return groupLayer, group
end

--
------------------------------------------------------------------------------------ resize

function LayoutBuilder:resize( ui, fixedHeight )
  local winSize = Director:sharedDirector():getWinSize()
  if winSize.width ~= kScreenWidthDefault or winSize.height ~= kScreenHeightDefault then
    local scaleX = winSize.width/kScreenWidthDefault
    local scaleY = winSize.height/kScreenHeightDefault

    local scale = scaleY
    if fixedHeight then scale = scaleX end
    --print(ui, winSize.width, kScreenWidthDefault, winSize.height, kScreenHeightDefault, scale)
    ui:setScale(scale)
    return scale
  end
  return 1
end

function LayoutBuilder:transform2Top( ui, resize, fixedHeight )
  local winSize = CCDirector:sharedDirector():getWinSize()
  local transformedX = 0
  if resize then
    local scale = LayoutBuilder:resize(ui, fixedHeight)
    transformedX = (winSize.width - kScreenWidthDefault*scale)/2
  end
  return ui:setPosition(ccp(transformedX, winSize.height))
end
--
------------------------------------------------------------------------------------ font mapping

--mapping font face designed in Flash Pro to the face that game used.
-- for example, the original font face designed in Flash Pro is "Arial", but in game, we want to use "Helvetica" instead, 
-- than we can use this mapping methods.
function LayoutBuilder:addGlobalFontFace(designedFont, mappingTo)
  globalFontMapping[designedFont] = designedFont
end
function LayoutBuilder:addFontFace(designedFont, mappingTo)
  self.fontMapping[designedFont] = designedFont
end

function LayoutBuilder:getFontFace(designedFont)
  local face = self.fontMapping[designedFont]
  if not face then
    face = globalFontMapping[designedFont]
  end
  return face
end

-- add a build text function for selected item id.
function LayoutBuilder:addFontBuilderFunc(symbolId, func)
  fontBuilderFunc[symbolId] = func
end

function LayoutBuilder:hex2ccc3(color)
  local textColor = tostring(color)
  if #textColor > 6 then
    textColor = string.sub(textColor, 2, 7)
  end
  local integer = tonumber(textColor, 16)
  return HeDisplayUtil:ccc3FromUInt(integer)
end