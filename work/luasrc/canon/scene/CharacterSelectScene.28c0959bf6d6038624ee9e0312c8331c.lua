require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.manager.DcManager"

CharacterSelectScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

local instanceOfCharacterSelectScene = nil

function CharacterSelectScene:getInstance()
  if not instanceOfCharacterSelectScene then
		instanceOfCharacterSelectScene = CharacterSelectScene.new()
	end
	return instanceOfCharacterSelectScene
end

function CharacterSelectScene:ctor()
	self.title = getTextByKey("option_userManagement")
end

function CharacterSelectScene:create()
  local s = CharacterSelectScene.new()
  s:initScene()
  instanceOfCharacterSelectScene = s
  return s
end

function CharacterSelectScene:back()
  self:replaceScene( ConfigScene )
end

function CharacterSelectScene:onInit()
	BaseUIScene.initBackGround(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/CharacterSelect_new.json")
    self.mainUI = builder:build("CharacterSelect")
	self.mainUI:getChildByName("list_CreateCharacter"):setVisible(false)
	local area = self.mainUI:getChildByName("list_ChangeCharacter")
	
	local currUser = DataManager.getCurrUser()
  
  local uid = currUser.uid
	area:getChildByName("txt_Character_name"):getChildByName("txt"):setString(currUser.nickName)
	area:getChildByName("txt_level"):getChildByName("txt"):setString(getTextByKey("option_characterLv") .. currUser.level)
	--TODO 服务器ID
	area:getChildByName("txt_servernum"):getChildByName("txt"):setString(getTextByKey("option_characterServer") .. uid % 10000)
	--TODO 暂不开放更换角色
	area:getChildByName("btn_change"):setVisible(false)
  
  --退出
  local function onClickExitBtn()
    local function backToLoginScene()
      if isUCAndroid() then
        LoginScene:releaseInstance()
      end
      
      --local loginScene = LoginScene:create({enterScene = CharacterSelectScene})
      ---清除本地数据
      DataManager.clearData()
      DcManager.closeUserOnlineActivity()
      TCPManager:sharedInstance():closeConnect()

      --add by Geng.Men 退出登陆的时候清除武将强化主卡数据，防止玩家申请小号的时候在武将强化教程的部分卡死
      HeMemDataHolder:deleteByKey("CardCompose_MainCardId")
      UnionChatContainerPanel.resetChatContentView()
      CharacterSelectScene:getInstance():replaceScene(LoginScene)

      g_previousPlayerStrength = nil--清空前面账号的战斗力缓存
    end
        
    if isUCAndroid() then
      logoutUC(backToLoginScene)
    elseif is91Android() then 
      logout91(backToLoginScene)
    elseif isXiaomiAndroid() then
      logoutXiaomi(backToLoginScene)
    elseif is360Android() then
      logout360(backToLoginScene)
    elseif isDKAndroid() then
      logoutDK(backToLoginScene)
    elseif isWdjAndroid() then
      logoutWdj(backToLoginScene)
    elseif isOppoAndroid() then
      logoutOppo(backToLoginScene)
    elseif isYyhAndroid() then
      logoutYYH(backToLoginScene)
    elseif isYYBAndroid() then
      logoutQQ(backToLoginScene)
    elseif isAnzhiAndroid() then
      logoutAnzhi(backToLoginScene)
    elseif isVivoAndroid() then
      logoutVivo(backToLoginScene,true)
    elseif isJinliAndroid() then
      logoutJinli(backToLoginScene)
    else
      backToLoginScene()
    end
  end

  -- local function toUserCenter()
  --   if isKuaiYongIos() then
  --     KYGameSdk:showUserCenter()
  --   --elseif 其他平台 then
  --   end
  -- end

  --以后设计用户中心的代码都在这里加
  -- if isKuaiYongIos() then
  --   area:getChildByName("btn_exit"):getChildByName("txt"):setString(getTextByKey("option_person"))
  --   local exitBtn = Button:create(area:getChildByName("btn_exit"))
  --   exitBtn:addEventListener( Events.kStart, toUserCenter, self )
  -- else
    area:getChildByName("btn_exit"):getChildByName("txt"):setString(getTextByKey("option_exitBtn"))
    local exitBtn = Button:create(area:getChildByName("btn_exit"))
    exitBtn:addEventListener( Events.kStart, onClickExitBtn, self )
  -- end
  
  self:addChild(self.mainUI)
	BaseUIScene.onInit(self)
end

function CharacterSelectScene:dispose()
  CharacterSelectScene.super.dispose(self)
end

function CharacterSelectScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function CharacterSelectScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function CharacterSelectScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() + visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function CharacterSelectScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function CharacterSelectScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function CharacterSelectScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function CharacterSelectScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    BaseUIScene.nodeAnimationFinished(self)
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.5, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function CharacterSelectScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

