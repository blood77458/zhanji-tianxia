require "canon.request.GetDestinyInfoRequest"
require "canon.scene.DestinyFightChallengeScene"
require "canon.scene.KingTempleScene"
DestinyFightEnterPanel = class(Layer)

function DestinyFightEnterPanel:ctor()
end

function DestinyFightEnterPanel:create(container)
  self.container = container

  local panel = DestinyFightEnterPanel.new()
  panel:initLayer()
  return panel
end

function DestinyFightEnterPanel.enable()
  return true
end

function DestinyFightEnterPanel:initLayer()
	DestinyFightEnterPanel.super.initLayer(self)
  
	local builder = LayoutBuilder:createWithContentsOfFile( "scene/destiny_fight.json" )
	builder.useArtLabelTTF = true
	self.destinyFightLayer = builder:build("destiny_fight")
	self:addChild(self.destinyFightLayer)
	
	self.destinyFightLayer:getChildByName("btn_gofight"):getChildByName("txt"):setString(getTextByKey("destinyBattle_title"))
	self.destinyFightLayer:getChildByName("btn_goup"):getChildByName("txt"):setString(getTextByKey("hallOfChampion_title"))
		
	local function onClickAttension(evt)
	--	self.container.targetInfoPanel = NewBabelAttensionPanel:create(self.container)
	--	PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false ,self.container)
	--	print("show destiny fight info")
		local infoText = getTextByKey("destinyBattle_infoTxt1") .. "\\n" 
						.. getTextByKey("destinyBattle_infoTxt2") .. "\\n"
						.. getTextByKey("destinyBattle_infoTxt3") .. "\\n"
						.. getTextByKey("destinyBattle_infoTxt4") .. "\\n"
		local aInfoPanel = ActivityInfoPanel:create(self.container, infoText)
		self.container:addChild(aInfoPanel)
		aInfoPanel:scaleIn()
	end
	
	local function onClickDestinyFight(evt)
		--print("go to destiny fight")
		if getDestinyFightUnlockLevel() > DataManager.getCurrUser().level then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("destinyBattle_levelInsufficient", {num = getDestinyFightUnlockLevel()}))
			do return end
		end
		
		self.container:replaceScene(DestinyFightChallengeScene)
				
	end
	
	local function onClickBossHall(evt)
		--print("go to boss hall")
		self.container:replaceScene(KingTempleScene)
	end
	
	local attensionButton = Button:create(self.destinyFightLayer:getChildByName("sky_btn_qa"))
	attensionButton:addEventListener( Events.kStart, onClickAttension, self ) 
	
	self.challengeButton = Button:create(self.destinyFightLayer:getChildByName("btn_gofight"))
	self.challengeButton:addEventListener( Events.kStart, onClickDestinyFight, self ) 
	
	local watchRankButton = Button:create(self.destinyFightLayer:getChildByName("btn_goup"))
	watchRankButton:addEventListener( Events.kStart, onClickBossHall, self )  
	
	local destinyInfo = DataManager.getGameInitData().sharkDestinyInfo
	if destinyInfo and destinyInfo.spiritConcentrateLevel > 0 then
		self.destinyFightLayer:getChildByName("txt_destiny_fight1"):getChildByName("txt"):setString(getTextByKey("hallOfChampion_level") .. destinyInfo.spiritConcentrateLevel)
		self.destinyFightLayer:getChildByName("btn_goup"):getChildByName("btn"):setVisible(true)
		watchRankButton:setEnable(true)
	else
		self.destinyFightLayer:getChildByName("txt_destiny_fight1"):getChildByName("txt"):setString(getTextByKey("hallOfChampion_locked"))
		self.destinyFightLayer:getChildByName("btn_goup"):getChildByName("btn"):setVisible(false)
		watchRankButton:setEnable(false)
	end
	
end







function DestinyFightEnterPanel:dispose()
	Layer:dispose(self)
end
