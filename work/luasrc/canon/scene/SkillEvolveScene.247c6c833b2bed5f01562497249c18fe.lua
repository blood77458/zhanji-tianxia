--------------------------------------------------------------------------------
-- SkillEvolveScene.lua - 技能升级界面
-- author: fangzhou.long
-- date: 2013-08-19
--------------------------------------------------------------------------------

require "hecore.display.CocosObject"
require "hecore.display.Director"

require "hecore.ui.Button"

require "canon.scene.BaseUIScene"
require "canon.panel.MessageBoxPanel"

require "canon.request.UpgradeSkillRequest"

require "canon.models.CommonManager"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
SkillEvolveScene = class(BaseUIScene)

----------------------------------------
-- 构造方法
----------------------------------------
function SkillEvolveScene:ctor()
  self.title  = getTextByKey("skillEnhance_Title")
  self.mainUI = nil
  self.skillInfo = nil --技能相关信息
  self.maxLv = nil --最高技能等级
end

function SkillEvolveScene:create( argv )
  if (argv ~= nil) then
      self.cardId = tonumber( argv.params.cardId )
      self.skillId = tonumber( argv.params.skillId )
  end
  
  self.propNotEnough = 0
  self.skillLevelMax = false
  local s = SkillEvolveScene.new()
  s:initScene()
  return s
end

----------------------------------------
-- 获取该技能的最大等级
----------------------------------------
function SkillEvolveScene.getMaxLv(skillGroupId)
  local maxLv = 0
  for _, value in pairs(MetaManager.skill_meta) do
    if (value.skillGroupId == skillGroupId) then
      if (tonumber(value.level) > maxLv) then
        maxLv = tonumber(value.level)
      end
    end
  end
  return maxLv
end

----------------------------------------
-- 初始化读取技能数据等
----------------------------------------
function SkillEvolveScene:refreshSkillData()
  local UserData = DataManager.getCurrUser()
  self.coinsNow = UserData.coins
  
  local aSkill = MetaManager.skill_meta[self.skillId]
  
  self.skillInfo = aSkill
  self.maxLv = self.getMaxLv(self.skillInfo.skillGroupId)
  
  local skillStatus = aSkill.statusIdList:split("|")
  local numTable = {}
  for i=1,#skillStatus do
    if (skillStatus[i]~="0") then
      local aSkillStatus = MetaManager.skill_status[tonumber(skillStatus[i])]
	  numTable["num"..i] = (aSkillStatus.valueType==2) and aSkillStatus.effectValue or (aSkillStatus.effectValue*100 .. "%")
	else
	   numTable["num"..i] = nil
	end
  end
  self.skillInfo.numTable = numTable
  
  self.skillLevelMax = (tonumber(self.skillInfo.level) >= self.maxLv)
  
  if (not self.skillLevelMax) then
    self.nextSkillInfo = MetaManager.skill_meta[self.skillId+1]
	skillStatus = self.nextSkillInfo.statusIdList:split("|")
	numTable = {}
	for i=1,#skillStatus do
		if (skillStatus[i]~="0") then
			local aSkillStatus = MetaManager.skill_status[tonumber(skillStatus[i])]
			numTable["num"..i] = (aSkillStatus.valueType==2) and aSkillStatus.effectValue or (aSkillStatus.effectValue*100 .. "%")
		else
			numTable["num"..i] = nil
		end
	end
	self.nextSkillInfo.numTable = numTable
  end
end

----------------------------------------
-- 初始化UI界面
----------------------------------------
function SkillEvolveScene:initUI()
  self:refreshSkillData()
  BaseUIScene.initBackGround(self)
  local builder = LayoutBuilder:createWithContentsOfFile("scene/skillEnhance_new.json")
  self.mainUI = builder:build("skillEnhance")
  
  --刷新三个UI区块
  self:initUiGroup(1)
  self:initUiGroup(2)
  self.uiGroup3 = self.mainUI:getChildByName("bg_skillEnhance")
  
  self:addChild(self.mainUI)
  BaseUIScene.onInit(self)
end

----------------------------------------
-- 初始化Scene
----------------------------------------
function SkillEvolveScene:onInit()
  --self.loading = Sprite:create("loading.png")
  --self.loading:setScale(2)
  --self.loading:setPosition(ccp(visibleSize.width/2,visibleSize.height/2))
  --self:addChild(self.loading)

  self:initUI()
  
  --self.loading:setVisible(false)
end

----------------------------------------
-- 底部按钮的响应器
----------------------------------------
local function onClickBtn(evt)
  local aScene = evt.context
  if (aScene.skillLevelMax) then
    aScene:back()
  else
    aScene:evolveSkill()
  end
  --[[构造请求
  local request = UpgradeSkillRequest.new( params, rpc.SendingPriority.kHigh )
  request:addEventListener( RequestNotifyEnum.UpgradeSkillSucceed, afterSaveTrain )
  --发送请求
  request:start()]]
end

----------------------------------------
-- 获取背包中相应道具的数量
----------------------------------------
function SkillEvolveScene:getPropAmount( propId )
  local propsData = DataManager.getPropsData()
  for aKey, prop in pairs(propsData) do
    if (prop.metaId == propId) then
      return prop.amount,aKey
    end
  end
  return 0,0
end

----------------------------------------
-- 刷新物品相关信息的方法
----------------------------------------
function SkillEvolveScene:refreshItems()
	local propInfo = {}
	self.propData = {}
  
	for i=1,5 do
		propInfo[i] = self.skillInfo["propId"..i]
		self.propData[i] = {}
		self.propData[i].now,self.propData[i].propKey = self:getPropAmount(tonumber(propInfo[i]))
		self.propData[i].need = tonumber(self.skillInfo["propAmount"..i])
	end
	
	for key, value in pairs(self.propData) do
		if ( propInfo[key] ~= 0) then
			local propObject = CanonItem:create()
			propObject:loadByMetaId(propInfo[key])
			local position = self.uiGroup2:getChildByName("normal_card_small_"..key):getPosition()
			propObject:setPosition(ccp(position.x,position.y))
			propObject:setScale(0.75)
			self.uiGroup2:addChild(propObject)
			self.uiGroup2:getChildByName("normal_card_small_"..key):setVisible(false)
		
			if (value.now < value.need) then
				self.uiGroup2:getChildByName("txt_equipEvolve_material_num_"..key):getChildByName("font"):setColor(ccc3(255,0,0))
				self.uiGroup2:getChildByName("txt_equipEvolve_material_num_"..key):getChildByName("font"):setString( value.now .. "/" .. value.need)
				self.uiGroup2:getChildByName("normal_card_small_"..key):setOpacity(80)
				self.propNotEnough = propInfo[key]
			else
				self.uiGroup2:getChildByName("txt_equipEvolve_material_num_"..key):getChildByName("font"):setColor(ccc3(110,200,34))
				self.uiGroup2:getChildByName("txt_equipEvolve_material_num_"..key):getChildByName("font"):setString( value.now .. "/" .. value.need)
			end
		else
			self.uiGroup2:getChildByName("normal_card_small_"..key):setVisible(false)
			self.uiGroup2:getChildByName("txt_equipEvolve_material_num_"..key):setVisible(false)
			self.uiGroup2:getChildByName("q_purple9_panel_"..key):setVisible(false)
			--self.uiGroup2:getChildByName("txt_skillEnhance_material_num"..key):setVisible(false)
			--self.uiGroup2:getChildByName("bg_equipEvolve_material"..key):setVisible(false)
		end
	end
end

----------------------------------------
-- 刷新进阶的说明
----------------------------------------
function SkillEvolveScene:refreshDesc()
  self.uiGroup2:getChildByName("txt_skill_lv_num_L"):getChildByName("font"):setString(self.skillInfo.level .. "/" .. self.maxLv)
  self.uiGroup2:getChildByName("txt_skill_OldEffect"):getChildByName("txt_skill_OldEffect"):setString(Localization:getInstance():getText(self.skillInfo.desc, self.skillInfo.numTable))
  
  if (not self.skillLevelMax) then
    self.uiGroup2:getChildByName("txt_skill_lv_num_R"):getChildByName("font"):setString(self.nextSkillInfo.level .. "/" .. self.maxLv)
    self.uiGroup2:getChildByName("txt_skill_lv_num_R"):getChildByName("font"):setColor(ccc3(110,200,34))
    self.uiGroup2:getChildByName("txt_skill_NewEffect"):getChildByName("txt_skill_OldEffect"):setString(Localization:getInstance():getText(self.nextSkillInfo.desc, self.nextSkillInfo.numTable))
    self.uiGroup2:getChildByName("txt_skill_NewEffect"):getChildByName("txt_skill_OldEffect"):setColor(ccc3(110,200,34))
  end
end

local colorBarNameList = {
	"r_white9_panel",
	"r_green9_panel",
	"r_blue9_panel",
	"r_purple9_panel",
	"r_orange9_panel",
	"r_red9_panel",
	"r_yellow9_panel",
}

----------------------------------------
-- 用于初始化各个UI区块的方法
----------------------------------------
function SkillEvolveScene:initUiGroup( number )
  if (number == 1) then
    self.uiGroup1 = self.mainUI:getChildByName("skillEnhance_upper")
   
    --self.uiGroup1:getChildByName("txt_skillEnhance_quality"):getChildByName("txt_skillEnhance_quality"):setString(Localization:getInstance():getText("skillInfo_Quality"))
    self.uiGroup1:getChildByName("txt_equip_Desc"):getChildByName("txt_equip_Desc"):setString(getTextByKey("skill_Effect"))
    
    self.uiGroup1:getChildByName("txt_skillEnhance_skillName"):getChildByName("txt_skillEnhance_skillName"):setString(getTextByKey(self.skillInfo.name))
	self.uiGroup1:getChildByName("txt_equipName"):getChildByName("txt_equipName"):setString(getTextByKey(self.skillInfo.name))
    self.uiGroup1:getChildByName("txt_lv_num"):getChildByName("font"):setString(self.skillInfo.level)
    self.uiGroup1:getChildByName("txt_skill_Desc"):getChildByName("txt_skill_Desc"):setString( Localization:getInstance():getText(self.skillInfo.desc,self.skillInfo.numTable) )
    
	for quality = 1, 7 do
		local aQualityPanel = self.uiGroup1:getChildByName(colorBarNameList[quality])
		aQualityPanel:setVisible(false)
	end
	self.uiGroup1:getChildByName(colorBarNameList[self.skillInfo.quality]):setVisible(true)
	--设置技能
	local skillObject = CanonItem:create()
    skillObject:loadByMetaId(self.skillId)
	local position = self.uiGroup1:getChildByName("normal_card_small_sb"):getPosition()
	skillObject:setPosition(ccp(position.x,position.y))
	self.uiGroup1:addChild(skillObject) 
	self.uiGroup1:getChildByName("normal_card_small_sb"):setVisible(false)
    
  elseif (number == 2) then
    if (self.skillLevelMax) then
      self.mainUI:getChildByName("skillEnhance_mid"):setVisible(false)
      self.uiGroup2 = self.mainUI:getChildByName("skillEnhance_mid_maxlv")
      self.uiGroup2:getChildByName("txt_skillEnhance_Tips"):getChildByName("txt_skillEnhance_Tips"):setString(getTextByKey("skillEnhance_Tips"))
      self.uiGroup2:getChildByName("btn_skill_EnhanceBtn"):getChildByName("btn"):setVisible(false)
	  self.uiGroup2:getChildByName("btn_skill_EnhanceBtn"):getChildByName("txt_skill_EnhanceBtn"):setString(Localization:getInstance():getText("skill_EnhanceBtn"))
	else
      self.mainUI:getChildByName("skillEnhance_mid_maxlv"):setVisible(false)
      self.uiGroup2 = self.mainUI:getChildByName("skillEnhance_mid")
      
      self:refreshItems()
      
      self.uiGroup2:getChildByName("txt_equip_CoinConsume"):getChildByName("txt_equip_CoinConsume"):setString(Localization:getInstance():getText("skill_CoinConsume"))
      --self.uiGroup2:getChildByName("txt_equip_CoinOwn"):getChildByName("txt_equip_CoinOwn"):setString(Localization:getInstance():getText("skill_CoinOwn"))
      self.uiGroup2:getChildByName("txt_equip_CoinConsume_num"):getChildByName("font"):setString(self.skillInfo.coin)
      if (tonumber(self.skillInfo.coin)>tonumber(self.coinsNow)) then
        self.uiGroup2:getChildByName("txt_equip_CoinConsume_num"):getChildByName("font"):setColor(ccc3(255,0,0))
      else
        self.uiGroup2:getChildByName("txt_equip_CoinConsume_num"):getChildByName("font"):setColor(ccc3(110,200,34))
      end
      --self.uiGroup2:getChildByName("txt_equip_CoinOwn_num"):getChildByName("font"):setString(self.coinsNow)
	  local aButtonDisplay = self.uiGroup2:getChildByName("btn_skill_EnhanceBtn");
	  aButtonDisplay:getChildByName("txt_skill_EnhanceBtn"):setString(Localization:getInstance():getText("skill_EnhanceBtn"))
      local aButton = Button:create(aButtonDisplay)
	  aButton:addEventListener(Events.kStart, onClickBtn, self) 
	end
    self:refreshDesc()
    self.uiGroup2:setVisible(true)
  end
end

----------------------------------------
-- 返回键的响应器
----------------------------------------
function SkillEvolveScene:back()
  --TODO
  self:replaceScene( CardQueueScene )
end

----------------------------------------
-- 返回键的响应器
----------------------------------------
function SkillEvolveScene:evolveSkill()
  --物品数量检查
  if (self.propNotEnough ~= 0) then
    print(table.tostring(self.propNotEnough))
    local eliteInfo = EliteManager.getMaterialSrc(self.propNotEnough) 
	if (eliteInfo.eliteMissionId == 0) then
		CanonMessageBox.showText(
			ShowButtonType.ID_OK,
			getTextByKey("skill_MaterialShortText_cannotBuy")
		)
	else
		local aPanel = MessageBoxPanel:create(self, MessageBoxType.kSkillEvolvePropLimit, {propId = self.propNotEnough})
		self:addChild(aPanel)
		aPanel:scaleIn()
	end
    return
  end
  
  --钱币的检查
  if (tonumber(self.skillInfo.coin) > tonumber(self.coinsNow)) then
    local aPanel = MessageBoxPanel:create(self, MessageBoxType.kCoinLimit)
    self:addChild(aPanel)
    aPanel:scaleIn()
    return;
  end
  
  --构造请求及回调函数
  --升级成功后的处理
  local function afterEvolveSkill(event)
    self.skillId = self.skillId + 1
	--修改道具和卡牌数据
	print(table.tostring(self.propData))
	local GameData = DataManager.getGameInitData()
	for _, aPropData in pairs(self.propData) do
		if (aPropData.need~=0) then
			GameData.sharkProps.sharkProps[aPropData.propKey]["amount"] = aPropData.now - aPropData.need
		end
	end
	local aCard, aCardKey = CommonManager.getSubTableByKey(
		GameData.sharkCards.sharkCards,
		{name = "cardId", value = self.cardId}
	)
	local aSkill, aSkillKey = CommonManager.getSubTableByKey(
		aCard["cardSkills"],
		{name = "skillId", value = self.skillId-1}
	)
	aCard["cardSkills"][aSkillKey]["skillId"] = self.skillId
	GameData.sharkCards.sharkCards[aCardKey] = aCard
	DataManager.setGameInitData(GameData)
	--修改金钱数据
	local negativeReward = {
		{	itemType = ResourceEnum.COIN,
			amount = -1*self.skillInfo.coin
		}
	}
	RewardManager:getReward(negativeReward)
	self:refreshSkillData()
	self:initUiGroup(1)
	self:initUiGroup(2)
  end
  
  --升级失败后的处理
  local function onEvolveSkillError(event)
	  CCMessageBox("Error Code:" .. event.data, "Error")
  end
  
  local request = UpgradeSkillRequest.new( { cardId = self.cardId, skillId = self.skillId}, rpc.SendingPriority.kHigh )
  request:addEventListener( RequestNotifyEnum.UpgradeSkillSucceed, afterEvolveSkill )
  request:addEventListener( RequestNotifyEnum.UpgradeSkillFailed, onEvolveSkillError )
  --发送请求
  request:start()
end

----------------------------------------
-- 用来播放进退场动画的方法
----------------------------------------
function SkillEvolveScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function SkillEvolveScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
end

function SkillEvolveScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.uiGroup1:setPositionX(self.uiGroup1:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  --arr:addObject(CCDelayTime:create(0.2 / 3))
  arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
  self.uiGroup1:runAction(CCSequence:create(arr))
  self.uiGroup2:setPositionX(self.uiGroup2:getPositionX() - visibleSize.width)
  arr = CCArray:create()
  --arr:addObject(CCDelayTime:create(0.2 * 2 / 3))
  arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
  --arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup2:runAction(CCSequence:create(arr))
  self.uiGroup3:setPositionX(self.uiGroup3:getPositionX() - visibleSize.width)
  arr = CCArray:create()
  --arr:addObject(CCDelayTime:create(0.2))
  arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup3:runAction(CCSequence:create(arr))

--[[  for _, v in ipairs(self.uiGroup5.list) do
    v:setAlpha(0)
    v:runAction(CCFadeIn:create(0.5))
	end	]]
end

function SkillEvolveScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
end

function SkillEvolveScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function SkillEvolveScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function SkillEvolveScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end

  local arr = CCArray:create()
  --arr:addObject(CCDelayTime:create(0.2 / 3))
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  self.uiGroup1:runAction(CCSequence:create(arr))
  arr = CCArray:create()
  --arr:addObject(CCDelayTime:create(0.2 * 2 / 3))
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup2:runAction(CCSequence:create(arr))
  arr = CCArray:create()
  --arr:addObject(CCDelayTime:create(0.2))
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup3:runAction(CCSequence:create(arr))

--[[  for _, v in ipairs(self.uiGroup5.list) do
    v:runAction(CCFadeOut:create(0.5))
  end]]
end

function SkillEvolveScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end