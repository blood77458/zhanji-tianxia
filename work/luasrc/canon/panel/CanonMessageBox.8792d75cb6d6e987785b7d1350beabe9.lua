------------------------ 通用消息框 ------------------------
-- 使用方法：CanonMessageBox.showText(buttonType, text, leftBtnInfo, centerBtnInfo, rightBtnInfo)
-- 参数说明：第1、2个参数必须有，后3个参数可选
--  buttonType  --按钮类型
--  text  --文本文字
--  leftBtnInfo  --{text="left", callbackFunc=funcNameLeft}
--  centerBtnInfo  --{text="center", callbackFunc=funcNameCenter}
--  rightBtnInfo --{text="right", callbackFunc=funcNameRight}
-- 作者： 庄浩洋 & xiaojie.bai
------------------------------------------------------------

require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.constants.MusicPathConstants"
require "hecore.ui.Button"

ShowMessageType = {
  ShowText = 1,  --显示文字信息
  ShowPicture = 2,  --显示图片信息
}

ShowButtonType = {
  ID_OK = 1,  --确定按钮
  ID_CANCEL = 2,  --取消按钮
  ID_OK_CANCEL = 4,  --确定与取消按钮
  ID_RET_MONEY = 6,  --取消与充值按钮
  ID_RET_LOOK = 7,  --去看看
}

ShowErrorCodeType = {
  EC_GRID_NOT_ENOUGH = 1,
  EC_REQUISITE_ENERGY_NOT_ENOUGH = 2,
  EC_ACHIEVEMENT_REWARD_NOT_EXIST = 3,
  EC_RECEIVE_WAGE_AT_WRONG_TIME = 4,
  EC_COMMON = 5,
  EC_TRIGGER_BATTLE_EVENT = 6,

}

CanonMessageBox = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

CanonMessageBox.TextKey_OK = "yes" -- 确定
CanonMessageBox.TextKey_Cancel = "cancel" -- 取消
CanonMessageBox.TextKey_Pay = "payBtn" --充值
CanonMessageBox.TextKey_Look = "levelup_goBtn" --去看看

CanonMessageBox.DefaultFontSize = 30

function CanonMessageBox:ctor()
  self.container = nil
  self.params = nil
end

--[[
msgBoxParams格式:
{
  contentType, --文字/图片(option)
  content, --内容(require)
  fontSize, -- 内容字体大小(option)
  buttonType, --按钮组合类型(require)
  leftBtnInfo = {text, callbackFunc}, --左按钮(option)
  centerBtnInfo = {text, callbackFunc}, --中按钮(option)
  rightBtnInfo = {text, callbackFunc} --右按钮(option)
}
--]]
function CanonMessageBox.show(msgBoxParams)
    local panel = CanonMessageBox.new()
    panel.container = Director:sharedDirector():getRunningScene()
    panel.params = msgBoxParams
    
    panel:initLayer()
    
    return panel
end

------
--  buttonType  --按钮类型，参加CanonMessageBox.lua的 ShowButtonType
--  text  --文本文字
--  leftBtnInfo  --{text="left", callbackFunc=funcNameLeft}
--  centerBtnInfo  --{text="center", callbackFunc=funcNameCenter}
--  rightBtnInfo --{text="right", callbackFunc=funcNameRight}
------
function CanonMessageBox.showText(buttonType, text, leftBtnInfo, centerBtnInfo, rightBtnInfo)
  local msgBoxParams = {}
  
  msgBoxParams.contentType = ShowMessageType.ShowText
  msgBoxParams.content = text
  msgBoxParams.buttonType = buttonType
  msgBoxParams.leftBtnInfo = leftBtnInfo
  msgBoxParams.centerBtnInfo = centerBtnInfo
  msgBoxParams.rightBtnInfo = rightBtnInfo
  
  return CanonMessageBox.show(msgBoxParams)
end

function CanonMessageBox:initLayer()
	if not g_loadSceneCombine then
		g_loadSceneCombine = true
	end
  if(self.container) then
    if (self.container.setTableViewsEnabled) then --有些弹窗可能发生在未继承BaseUI的场景中
      self.container:setTableViewsEnabled(false)
    end
  
    --移动位置 因为可能没有container modified by zheng.che @ 2014-8-26 14:52:01
    self.pre_container_targetInfoPanel = self.container.targetInfoPanel
    self.container.targetInfoPanel = self
  end
  
  CanonMessageBox.super.initLayer(self)
  
  -- 背景层，用于缩放
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.tempLayer)
  self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
  self.panelUI = builder:build("common_popup1") 
  self.tempLayer:addChild(self.panelUI)
  
  -- 所有页面控件提取为变量
  local aMessageLabelOne = self.panelUI:getChildByName("common_txt_popup1"):getChildByName("txt_popup1")
  local aMessageLabelTwo = self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip")
  aMessageLabelTwo:setDimensions(CCSizeMake(aMessageLabelTwo:getDimensions().width, 0))
  local leftBtn = self.panelUI:getChildByName("common_btn_continue")
  local txtLeftBtn = leftBtn:getChildByName("txt_continue")
  leftBtn:setVisible(false)
  local rightBtn = self.panelUI:getChildByName("common_btn_cancel")
  local txtRightBtn = rightBtn:getChildByName("txt_cancel")
  rightBtn:setVisible(false)
  local centerBtn = self.panelUI:getChildByName("common_btn_center")
  local txtCenterBtn = centerBtn:getChildByName("txt_center")
  centerBtn:setVisible(false)
  
  -- 逻辑显示
  
  local params = self.params
  
  self.exampleBuild = builder:build("txt/common_txt_ sellItem_equip")
  local aExampleLabel = self.exampleBuild:getChildByName("txt_sellItem_equip")
  aExampleLabel:setDimensions(CCSizeMake(aExampleLabel:getDimensions().width, 0))
  aExampleLabel:setString("Example")
  
  if(params.fontSize) then
    aExampleLabel:setFontSize(params.fontSize)
    txtLeftBtn:setFontSize(params.fontSize)
    txtCenterBtn:setFontSize(params.fontSize)
    txtRightBtn:setFontSize(params.fontSize)
  end
  
  local aBaseHeight = aExampleLabel:getTexture():getContentSize().height
  
  local function geneBtn(btnSb, txtSb, btnInfo, defaultTextKey, musicPath)
    btnSb:setVisible(true)
    local btnText = btnInfo and btnInfo.text or getTextByKey(defaultTextKey)
    txtSb:setString(btnText)
    
    local function onClick()
      self.container.targetInfoPanel = self.pre_container_targetInfoPanel
      if (self.container.setTableViewsEnabled) and (not self.container.targetInfoPanel) then --有些弹窗可能发生在未继承BaseUI的场景中)
      self.container:setTableViewsEnabled(true)
      end
      
      PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )

      CanonPlayEffect(musicPath)
      if (btnInfo and btnInfo.callbackFunc ~= nil) then
        btnInfo.callbackFunc()
      end
    end
    
    local btn = Button:create(btnSb)
    btn:addEventListener( Events.kStart, onClick )
  end
  
  local buttonType = params.buttonType
  local leftBtnInfo = params.leftBtnInfo
  local centerBtnInfo = params.centerBtnInfo
  local rightBtnInfo = params.rightBtnInfo
  
  if(ShowButtonType.ID_OK == buttonType) then
    geneBtn(centerBtn, txtCenterBtn, centerBtnInfo, CanonMessageBox.TextKey_OK, MusicPathConstants.ButtonOK)
  elseif(ShowButtonType.ID_CANCEL == buttonType) then
    geneBtn(centerBtn, txtCenterBtn, centerBtnInfo, CanonMessageBox.TextKey_Cancel, MusicPathConstants.ButtonCancel)
  elseif(ShowButtonType.ID_OK_CANCEL == buttonType) then
    geneBtn(leftBtn, txtLeftBtn, leftBtnInfo, CanonMessageBox.TextKey_OK, MusicPathConstants.ButtonOK)
    geneBtn(rightBtn, txtRightBtn, rightBtnInfo, CanonMessageBox.TextKey_Cancel, MusicPathConstants.ButtonCancel)
  elseif(ShowButtonType.ID_RET_MONEY == buttonType) then
    geneBtn(leftBtn, txtLeftBtn, leftBtnInfo, CanonMessageBox.TextKey_Cancel, MusicPathConstants.ButtonCancel)
    geneBtn(rightBtn, txtRightBtn, rightBtnInfo, CanonMessageBox.TextKey_Pay, MusicPathConstants.ButtonOK)
  elseif(ShowButtonType.ID_RET_LOOK == buttonType) then --去看看
    geneBtn(leftBtn, txtLeftBtn, leftBtnInfo, CanonMessageBox.TextKey_OK, MusicPathConstants.ButtonCancel)
    geneBtn(rightBtn, txtRightBtn, rightBtnInfo, CanonMessageBox.TextKey_Look, MusicPathConstants.ButtonOK)
  else
    he_log_warning("unsupport type" .. buttonType)
  end
  
  -- 显示图片或文案
  local contentType = params.contentType and params.contentType or ShowMessageType.ShowText
  local content = params.content
  if(contentType == ShowMessageType.ShowText) then
    
    aExampleLabel:setString(content)
    
    local aMultiple = aExampleLabel:getTexture():getContentSize().height / aBaseHeight
    if aMultiple > (1.0 - 0.1) and aMultiple < (1.0 + 0.1) then
      aMessageLabelOne:setString(content)
      aMessageLabelTwo:setVisible(false)
    else
      aMessageLabelTwo:setString(content)
      aMessageLabelOne:setVisible(false)
    end
  elseif(contentType == ShowMessageType.ShowPicture) then
    local picSpirte = Sprite:create(content)
    local positionY = aMessageLabelOne.getPosition().y + aBaseHeight / 2
    picSpirte:setPosition(ccp( visibleSize.width/2, aMessageLabelOne.getPosition().y ))
    self:addChild(picSpirte)
  else
    he_log_warning("contentType is not support:" .. contentType)
  end

  PopoutManager:sharedManager():popout(self, kPopoutDir.kScale, true, false ,self.container)
end

function CanonMessageBox:scaleIn()
  self.tempLayer.touchEnabled = false
  self.tempLayer.touchChildren = false
  local function scaleInFinished()
    self.tempLayer.touchEnabled = true
    self.tempLayer.touchChildren = true
  end
  local arr = CCArray:create()
  arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
  arr:addObject(CCCallFunc:create(scaleInFinished))
  self.tempLayer:runAction(CCSequence:create(arr))
end

function CanonMessageBox:dispose()
  self.exampleBuild:dispose()
  CanonMessageBox.super.dispose(self)
end

----------------------------------------
-- 旧版面板接口
----------------------------------------
function CanonMessageBox:Show( Text_Or_FilePath, messageType, buttonType, textSize, CallBackFunc_OK, CallBackFunc_CancelRet )
  local msgBoxParams = {}
  
  msgBoxParams.contentType = messageType or ShowMessageType.ShowText
  msgBoxParams.content = Text_Or_FilePath
  msgBoxParams.fontSize = textSize or CanonMessageBox.DefaultFontSize
  msgBoxParams.buttonType = buttonType or ShowButtonType.ID_OK
  
  if(ShowButtonType.ID_OK == buttonType or ShowButtonType.ID_CANCEL == buttonType) then
    msgBoxParams.centerBtnInfo = {}
    msgBoxParams.centerBtnInfo.callbackFunc = CallBackFunc_OK
  elseif(ShowButtonType.ID_OK_CANCEL == buttonType) then
    msgBoxParams.leftBtnInfo = {}
    msgBoxParams.leftBtnInfo.callbackFunc = CallBackFunc_OK
    msgBoxParams.rightBtnInfo = {}
    msgBoxParams.rightBtnInfo.callbackFunc = CallBackFunc_CancelRet
  elseif(ShowButtonType.ID_CANCEL == buttonType) then
    msgBoxParams.leftBtnInfo = {}
    msgBoxParams.leftBtnInfo.callbackFunc = CallBackFunc_CancelRet
    msgBoxParams.rightBtnInfo = {}
    msgBoxParams.rightBtnInfo.callbackFunc = CallBackFunc_OK
  elseif(ShowButtonType.ID_RET_LOOK == buttonType) then --去看看
    --print("~~~~~~~~~~~~~~~~弹框")
    msgBoxParams.leftBtnInfo = {}
    msgBoxParams.leftBtnInfo.callbackFunc = CallBackFunc_CancelRet
    msgBoxParams.rightBtnInfo = {}
    msgBoxParams.rightBtnInfo.callbackFunc = CallBackFunc_OK
  else
    return nil
  end

  
  return CanonMessageBox.show(msgBoxParams)
end

----------------------------------------
-- 前后端通讯业务错误码提示框
-- commErrorCode 通信错误码结构体，参见CommErrorCodes.lua
-- textParams 错误信息文案替换字典
-- textSize 文字大小
-- callBackFunc 点击确定回调函数
----------------------------------------
function CanonMessageBox:showCommErrorBox(commErrorCode, textParams, textSize, callBackFunc)
  local text = nil
  if(commErrorCode.textKey and commErrorCode.textKey ~= "") then
    text = getTextByKey(commErrorCode.textKey, textParams)
  else 
    text = getTextByKey("defaultError_popupText", {errorCodeId = commErrorCode.code})
  end
  if(not text) then
    he_log_warning("getTextByKey return nil:", commErrorCode.textKey)
    text = "error: " .. commErrorCode.code
  end
  
  self:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, textSize, callBackFunc, nil)
end

----------------------------------------
-- 前后端通讯业务错误码提示框
-- commErrorCode 通信错误码结构体，参见CommErrorCodes.lua
-- textSize 文字大小
-- callBackFunc 点击确定回调函数
----------------------------------------
function CanonMessageBox:showCommUnHandleErrorBox(errorCode, textSize, callBackFunc)
  local text = getTextByKey("defaultError_popupText", {errorCodeId = errorCode})
  
  self:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, textSize, callBackFunc, nil)
end

function CanonMessageBox:showSpecialErrorBox( errorType , textSize, callBackFunc)
  local text
  if errorType == ShowErrorCodeType.EC_GRID_NOT_ENOUGH then
    text = getTextByKey("EC_GRID_NOT_ENOUGH_TXT")
  elseif errorType == ShowErrorCodeType.EC_REQUISITE_ENERGY_NOT_ENOUGH then
    text = getTextByKey("EC_REQUISITE_ENERGY_NOT_ENOUGH_TXT")
  elseif errorType == ShowErrorCodeType.EC_ACHIEVEMENT_REWARD_NOT_EXIST then
    text = getTextByKey("EC_ACHIEVEMENT_REWARD_NOT_EXIST_TXT")
  elseif errorType == ShowErrorCodeType.EC_RECEIVE_WAGE_AT_WRONG_TIME then
    text = getTextByKey("EC_RECEIVE_WAGE_AT_WRONG_TIME_TXT")
  elseif errorType == ShowErrorCodeType.EC_TRIGGER_BATTLE_EVENT then
    text = getTextByKey("EC_TRIGGER_BATTLE_EVENT")
  else
    text = getTextByKey("EC_COMMON_TXT")
  end
  self:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, textSize, callBackFunc, nil)
end

----------------------------------------
-- 以确认框形态弹出 *注意里面是点号而不是冒号
----------------------------------------
function CanonMessageBox.showAsConfirmBox(text, CallBackFunc_OK, CallBackFunc_CancelRet)
  CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, CallBackFunc_OK, CallBackFunc_CancelRet)
end

----------------------------------------
-- 弹出对应文字的提示框 *注意里面是点号而不是冒号
----------------------------------------
function CanonMessageBox.showTextBox(text, CallBackFunc_OK)
  CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, CallBackFunc_OK, nil)
end

function CanonMessageBox.showTextToLookBox(text, CallBackFunc_OK)
  CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_RET_LOOK, nil, CallBackFunc_OK, nil)
end