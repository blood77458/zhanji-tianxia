require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.scene.BaseUIScene"
require "canon.manager.BagCalcManager"
require "canon.request.SetCardGroupInterworkingRequest"

FateScene = class(BaseUIScene)
local visibleSize = CCSizeMake(720, 1280)

function FateScene:ctor()
  self.title = getTextByKey("shareFate_title")
end

function FateScene:create( argv )
	-- body
	if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end

	local scene = FateScene.new()
  self.ignoreAction = self.argv.params.ignoreAction
    scene:initScene()
    return scene
end

function FateScene:onInit()
	-- body
	BaseUIScene.initBackGround(self)
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/sameName.json")
	self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("sameName_main")
	self:addChild(self.mainUI)
	BaseUIScene.onInit(self)

  local limitLV = MetaManager.game_meta.gameSettingConfig.specialGroupUnlockLevel
  self:refreshUI()

  local ruleStr = getTextByKey("shareFate_tip5")
  local ruleStrTable = ruleStr:split("\\n")
  local finalString = ""
  for i, aString in ipairs(ruleStrTable) do
      if i > 1 then
          finalString = finalString.."\n"
      end
      finalString = finalString..aString
  end

  self.mainUI:getChildByName("lbl_sameName_01"):getChildByName("txt"):setString(getTextByKey("shareFate_tip4"))
  self.mainUI:getChildByName("lbl_sameName_02"):getChildByName("txt"):setString(getTextByKey("shareFate_tip6"))
  self.mainUI:getChildByName("txt_04"):getChildByName("txt"):setString(finalString)
  self.mainUI:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("shareFate_tip7" , {num = limitLV}))

  local ruleStr2 = getTextByKey("shareFate_dialogue")
  local ruleStrTable2 = ruleStr2:split("\\n")
  local finalString2 = ""
  for i, aString in ipairs(ruleStrTable2) do
      if i > 1 then
          finalString2 = finalString2.."\n"
      end
      finalString2 = finalString2..aString
  end
  self.mainUI:getChildByName("txt_01"):getChildByName("txt"):setString(finalString2)

  self.mainUI:getChildByName("halfblack3_r"):setVisible(false)
  self.mainUI:getChildByName("halfblack3_l"):setVisible(false)

  local function onClickFateBtn( evt )
    if DataManager.getCurrUser().level < limitLV then
      local aContent = getTextByKey("shareFate_Prompt",{num = limitLV})
      SuspensionLabel:showContent(self, aContent)
      return 
    end
    local gameInitData = DataManager.getGameInitData()
    local function changeFateStatusSuccess(e)
      g_previousBattleCount = CommonManager:getLocalPlayerStrength()
      gameInitData.sharkUserExtend.cardGroupInterworking = not gameInitData.sharkUserExtend.cardGroupInterworking
      DataManager.setGameInitData(gameInitData)
      g_previousPlayerFateStatus = gameInitData.sharkUserExtend.cardGroupInterworking
      self:refreshUI()
          
      --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
      DataManager.fightCapacityMaybeUpdated()
      
      g_shouldCalc = true
      CommonManager:checkEnableSkill(self)
      local effectQueue = CommonManager:getEffectCardQueue()
      for k,v in pairs(effectQueue) do
        if g_cardInfoCache[v] then
          g_cardInfoCache[v].needUpdate = true
        end
      end
    end
    local function changeFateStatusFail(e)
    end
    local cardGroupInterworking = gameInitData.sharkUserExtend.cardGroupInterworking
    local params = {cardGroupInterworking = not gameInitData.sharkUserExtend.cardGroupInterworking}

    SetCardGroupInterworkingRequest.sendRequest(params , changeFateStatusSuccess ,changeFateStatusFail)
  end

  local fateBtn = Button:create(self.mainUI:getChildByName("btn_sameName_01"))
  fateBtn:addEventListener(Events.kStart,onClickFateBtn)
end

function FateScene:refreshUI()
  local gameInitData = DataManager.getGameInitData()
  if gameInitData.sharkUserExtend.cardGroupInterworking then
    self.mainUI:getChildByName("txt_05"):getChildByName("txt"):setString(getTextByKey("shareFate_tip3"))
    self.mainUI:getChildByName("btn_sameName_01"):getChildByName("txt"):setString(getTextByKey("shareFate_button2"))
  else
    self.mainUI:getChildByName("txt_05"):getChildByName("txt"):setString(getTextByKey("shareFate_tip2"))
    self.mainUI:getChildByName("btn_sameName_01"):getChildByName("txt"):setString(getTextByKey("shareFate_button1"))
  end
end


function FateScene:dispose()
	BaseUIScene.dispose(self)
end

function FateScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function FateScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function FateScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function FateScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function FateScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function FateScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function FateScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    --print("enterActionFinished 2! os.clock() = " .. os.clock())
      self:nodeAnimationFinished()
  end
  
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function FateScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function FateScene:back()
  self:replaceScene(CardQueueScene)
end
