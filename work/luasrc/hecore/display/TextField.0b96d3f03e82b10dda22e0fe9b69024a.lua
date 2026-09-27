-------------------------------------------------------------------------
--  Class include: TextField, BitmapText, TextInput
-------------------------------------------------------------------------

require "hecore.display.CocosObject"

-- TextField -> CCLabelTTF
-- BitmapText -> CCLabelBMFont

kVerticalTextAlignment = {kCCVerticalTextAlignmentTop, kCCVerticalTextAlignmentCenter, kCCVerticalTextAlignmentBottom}
kTextAlignment = {kCCTextAlignmentLeft, kCCTextAlignmentCenter, kCCTextAlignmentRight}



--
-- TextField ---------------------------------------------------------
--

TextField = class(CocosObject);

function TextField:toString()
	return string.format("TextField [%s]", self.name and self.name or "nil");
end

--
-- public props ---------------------------------------------------------
--
function TextField:getString() return self.refCocosObj:getString() end
function TextField:setString(v) self.refCocosObj:setString(v) end	

--ccColor3B
function TextField:getColor() return self.refCocosObj:getColor() end
function TextField:setColor(v) self.refCocosObj:setColor(v) end

function TextField:getHorizontalAlignment() return self.refCocosObj:getHorizontalAlignment() end
function TextField:setHorizontalAlignment(v) self.refCocosObj:setHorizontalAlignment(v) end

function TextField:getVerticalAlignment() return self.refCocosObj:getVerticalAlignment() end
function TextField:setVerticalAlignment(v) self.refCocosObj:setVerticalAlignment(v) end

function TextField:getDimensions() return self.refCocosObj:getDimensions() end
function TextField:setDimensions(v) self.refCocosObj:setDimensions(v) end

function TextField:getFontSize() return self.refCocosObj:getFontSize() end
function TextField:setFontSize(v) self.refCocosObj:setFontSize(v) end

function TextField:getFontName() return self.refCocosObj:getFontName() end
function TextField:setFontName(v) self.refCocosObj:setFontName(v) end

function TextField:getTexture() return self.refCocosObj:getTexture() end

function TextField:setCacheEnabled(v)
    self.refCocosObj:setCacheEnabled(v)
end

--static creation function
function TextField:create(str, fontName, fontSize, dimensions, hAlignment, vAlignment)
  str = str or ""
  fontName = fontName or "Helvetica"
  fontSize = fontSize or 12
  dimensions = dimensions or CCSizeMake(0,0)
  --dimensions = CCSizeMake(0,0)
  hAlignment = hAlignment or kCCTextAlignmentLeft
  vAlignment = vAlignment or kCCVerticalTextAlignmentTop
  local label = CCLabelTTF:create(str, fontName, fontSize, dimensions, hAlignment, vAlignment)
  return TextField.new(label)
end

--added interfaces by jet.zhao<<

 TextRollEvents = {
  kRollProcess = "RollProcess",
  kRollFinished = "RollFinished"
}

function TextField:beginRollText( fromNum, toNum, format )
  format = format or "%d"
  local currentNum
  local function updateText( dt )
    if currentNum >= toNum then
      self:endRollText()
      return
    end
    currentNum = currentNum + 1
    self:setString(string.format(format, currentNum))
    self:dispatchEvent(Event.new(TextRollEvents.kRollProcess, 1, self))
  end
  currentNum = fromNum
  self.updateTextEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(updateText, 0, false)
end

function TextField:endRollText(  )
  if self.updateTextEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.updateTextEntry)
    self.updateTextEntry = nil
    self:dispatchEvent(Event.new(TextRollEvents.kRollFinished, nil, self))
  end
end

--added interfaces by jet.zhao>>




--
-- BitmapText ---------------------------------------------------------
--



BitmapText = class(CocosObject);

function BitmapText:toString()
	return string.format("TextField [%s]", self.name and self.name or "nil");
end

--
-- public props ---------------------------------------------------------
--
function BitmapText:getString() return self.refCocosObj:getString() end
function BitmapText:setString(v) self.refCocosObj:setString(v) end	

function BitmapText:setAlignment(alignment) self.refCocosObj:setAlignment(alignment) end
function BitmapText:setLineBreakWithoutSpace(breakWithoutSpace) self.refCocosObj:setLineBreakWithoutSpace(breakWithoutSpace) end

function BitmapText:getFntFile() return self.refCocosObj:getColor() end --string
function BitmapText:setFntFile(v) self.refCocosObj:setColor(v) end

--ccColor3B
function BitmapText:getColor() return self.refCocosObj:getColor() end
function BitmapText:setColor(v) self.refCocosObj:setColor(v) end

function BitmapText:getOpacity() return self.refCocosObj:getOpacity() end
function BitmapText:setOpacity(v) self.refCocosObj:setOpacity(v) end

function BitmapText:isOpacityModifyRGB() return self.refCocosObj:isOpacityModifyRGB() end
function BitmapText:setOpacityModifyRGB(v) self.refCocosObj:setOpacityModifyRGB(v) end

function BitmapText:getDimensions() return self.refCocosObj:getDimensions() end
function BitmapText:setDimensions(dim) self.refCocosObj:setDimensions(dim) end

function BitmapText:updateLabel() self.refCocosObj:updateLabel() end

function BitmapText:create(str, fntFile, width, alignment, imageOffset)
  if not fntFile then 
    print("create bitmap font fail. nill of fnt file")
    return nil 
  end
  str = str or ""
  width = width or -1
  alignment = alignment or kCCTextAlignmentLeft
  imageOffset = imageOffset or CCPointMake(0,0)
  local label = CCLabelBMFont:create(str, fntFile, width, alignment, imageOffset)
  return BitmapText.new(label)
end




--
-- TextInput ---------------------------------------------------------
--



kEditBoxInputMode = {
    kEditBoxInputModeAny,
    kEditBoxInputModeEmailAddr,
    kEditBoxInputModeNumeric,
    kEditBoxInputModePhoneNumber,
    kEditBoxInputModeUrl,
    kEditBoxInputModeDecimal,
    kEditBoxInputModeSingleLine
}
kEditBoxInputFlag = {
    kEditBoxInputFlagPassword,
    kEditBoxInputFlagSensitive,
    kEditBoxInputFlagInitialCapsWord,
    kEditBoxInputFlagInitialCapsSentence,
    kEditBoxInputFlagInitialCapsAllCharacters
}
kKeyboardReturnType = {
    kKeyboardReturnTypeDefault,
    kKeyboardReturnTypeDone,
    kKeyboardReturnTypeSend,
    kKeyboardReturnTypeSearch,
    kKeyboardReturnTypeGo
}

kTextInputEvents = {
  kBegan = "began", kEnded = "ended", kChanged = "changed", kReturn = "return"
} 

TextInput = class(CocosObject);

function TextInput:toString()
  return string.format("TextInput [%s]", self.name and self.name or "nil");
end

--
-- public props ---------------------------------------------------------
--
function TextInput:getText() return self.refCocosObj:getText() end
function TextInput:setText(v) self.refCocosObj:setText(v) end

--ccColor3B
function TextInput:setFontColor(v) self.refCocosObj:setFontColor(v) end
function TextInput:setPlaceholderFontColor(v) self.refCocosObj:setPlaceholderFontColor(v) end

function TextInput:getPlaceHolder() return self.refCocosObj:getPlaceHolder() end
function TextInput:setPlaceHolder(v) return self.refCocosObj:setPlaceHolder(v) end


function TextInput:getMaxLength() return self.refCocosObj:getMaxLength() end
function TextInput:setMaxLength(v) self.refCocosObj:setMaxLength(v) end

--EditBoxInputMode
function TextInput:setInputMode(v) self.refCocosObj:setInputMode(v) end
--EditBoxInputFlag
function TextInput:setInputFlag(v) self.refCocosObj:setInputFlag(v) end
--KeyboardReturnType
function TextInput:setReturnType(v) self.refCocosObj:setReturnType(v) end

function TextInput:setEnabled(v)
  self.refCocosObj:setEnabled(v)
end

function TextInput:setAnchorPoint(v)
  --setAnchorPoint is not supported. by default, anchor point is set to the center.
end
--
--
-- static create function ---------------------------------------------------------
--
local function getRefCocosObject( wrapper, shouldDispose )
  local ret = nil
  if type(wrapper) == "userdata" then
    ret = wrapper
  elseif type(wrapper) == "table" and type(wrapper.is) == "function" then
    ret = wrapper.refCocosObj
    if shouldDispose and type(wrapper.dispose) == "function" then 
      if wrapper.parent then wrapper:removeFromParentAndCleanup(true)
      else wrapper:dispose() end
    end
  end
  return ret
end

function TextInput:create(size, pNormal9SpriteBg, pPressed9SpriteBg, pDisabled9SpriteBg, releaseScale9Sprite)
  local shouldDispose = true
  if releaseScale9Sprite ~= nil then shouldDispose = releaseScale9Sprite end

  local pressed9SpriteBg = getRefCocosObject(pPressed9SpriteBg, shouldDispose)
  local disabled9SpriteBg = getRefCocosObject(pDisabled9SpriteBg, shouldDispose)
  local normal9SpriteBg = getRefCocosObject(pNormal9SpriteBg, shouldDispose)

  if not size or not normal9SpriteBg then
    print("create text input fail. invalid params.")
  end

  local textInput = nil
  local function editBoxEventHandler( event )
    local evt = Event.new(event, nil, textInput)
    if textInput and textInput:hasEventListenerByName(event) then textInput:dispatchEvent(evt) end
  end

  local text = CCEditBox:create(size, normal9SpriteBg, pressed9SpriteBg, disabled9SpriteBg)
  text:registerScriptEditBoxHandler(editBoxEventHandler)

  textInput = TextInput.new(text)
  return textInput
end

--ArtTextField

ArtTextField = class(TextField);

function ArtTextField:toString()
  return string.format("ArtTextField [%s]", self.name and self.name or "nil");
end


function ArtTextField:getString() return self.refCocosObj:getText() end
function ArtTextField:setString(v, noreconstruct)
	self.refCocosObj:setText(v)
	if not noreconstruct then
		self.refCocosObj:construct()
	end
end

function ArtTextField:setColor(v, noreconstruct)
	self.refCocosObj:setCenterColor(v)
	if not noreconstruct then
		self.refCocosObj:construct()
	end
end
function ArtTextField:getColor() return self.refCocosObj:getCenterColor() end

function ArtTextField:setAroundColor(v, noreconstruct)
	self.refCocosObj:setAroundColor(v)
	if not noreconstruct then
		self.refCocosObj:construct()
	end
end
function ArtTextField:getAroundColor() return self.refCocosObj:getAroundColor() end

function ArtTextField:getHorizontalAlignment() return self.refCocosObj:getHorizontalAlignment() end
function ArtTextField:setHorizontalAlignment(v, noreconstruct) 
	self.refCocosObj:setHorizontalAlignment(v) 
	if not noreconstruct then
		self.refCocosObj:construct()
	end
end

function ArtTextField:getVerticalAlignment() return self.refCocosObj:getVerticalAlignment() end
function ArtTextField:setVerticalAlignment(v, noreconstruct) 
	self.refCocosObj:setVerticalAlignment(v) 
	if not noreconstruct then
		self.refCocosObj:construct()
	end
end

function ArtTextField:getDimensions() return self.refCocosObj:getDimensions() end
function ArtTextField:setDimensions(v, noreconstruct) 
	self.refCocosObj:setDimensions(v) 
	if not noreconstruct then
		self.refCocosObj:construct()
	end
end

function ArtTextField:getFontSize() return self.refCocosObj:getSize() end
function ArtTextField:setFontSize(v, noreconstruct) 
	self.refCocosObj:setSize(v) 
	if not noreconstruct then
		self.refCocosObj:construct()
	end
end

function ArtTextField:getFontName() return self.refCocosObj:getFont() end
function ArtTextField:setFontName(v, noreconstruct) 
	self.refCocosObj:setFont(v) 
	if not noreconstruct then
		self.refCocosObj:construct()
	end
end

function ArtTextField:setAnchorPoint(v) self.refCocosObj:setTextAnchorPoint(v) end
function ArtTextField:getTexture() return self.refCocosObj:getTexture() end
function ArtTextField:setOpacity(v) return self.refCocosObj:getTexture() end
function ArtTextField:getContentSize() return self.refCocosObj:getTextContentSize() end

function ArtTextField:create(str, fontName, fontSize, dimensions, hAlignment, vAlignment)
  str = str or ""
  fontName = fontName or "Arial"
  fontSize = fontSize or 12
  dimensions = dimensions
  --dimensions = CCSizeMake(0,0)
  hAlignment = hAlignment or kCCTextAlignmentLeft
  vAlignment = vAlignment or kCCVerticalTextAlignmentTop
  
  local artLabel = ArtLabelTTF:create(str, fontName, fontSize)
  local toconstruct = false;
  if dimensions then
	artLabel:setDimensions(dimensions)
	toconstruct = true;
  end
  if kCCTextAlignmentLeft ~= hAlignment then
	artLabel:setHorizontalAlignment(hAlignment)
  end
  if kCCVerticalTextAlignmentTop ~= vAlignment then
	artLabel:setVerticalAlignment(vAlignment)
  end
  
  if toconstruct then
	artLabel:construct()
  end
  
  return ArtTextField.new(artLabel)
end

function ArtTextField:setCacheEnabled(v)
    self.refCocosObj:setCacheEnabled(v)
end