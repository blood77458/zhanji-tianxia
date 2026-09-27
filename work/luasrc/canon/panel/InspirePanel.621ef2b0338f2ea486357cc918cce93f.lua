--------------------------------------------------------------------------------
-- InspirePanel.lua - 鼓舞信息面板
--------------------------------------------------------------------------------

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.data.MetaManager"
require "canon.models.CommonManager"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

InspirePanel = class(Layer)

function InspirePanel:ctor()
    self.container = nil
    self.propInspireCount = 0
    self.goldInspireCount = 0
end

function InspirePanel:create( container )
    self.container = container
    local s = InspirePanel.new()
    s:initLayer()
    return s
end

function InspirePanel:initLayer()
	InspirePanel.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/boss.json")
    self.panelUI = builder:build("boss_inspire")
	self:addChild(self.panelUI)

	local worldBossInfo = WorldBossScene.worldBossInfo
	local worldBossUserStatus = WorldBossScene.worldBossInfo.worldBossUserStatus
	self.worldBossConfig = DataManager.GameMetaData.activityWorldBossConfig
	local gameInitData = DataManager.getGameInitData()

	self.panelUI:getChildByName("txt_inspireon"):getChildByName("txt"):setString(getTextByKey("worldBoss_inspireBtn"))  --标题鼓舞士气
	self.panelUI:getChildByName("txt_boss_inspire1"):getChildByName("txt"):setString(getTextByKey("worldBoss_inspire_boost"))  --当前伤害加成
	local maxInspire = math.floor( self.worldBossConfig.inspireLimit * 100 )
	self.panelUI:getChildByName("txt_boss_inspire5"):getChildByName("txt"):setString(getTextByKey("worldBoss_inspireLimit")  .. maxInspire .. "%")  --当前伤害加成
	self.panelUI:getChildByName("txt_boss_inspire2"):getChildByName("txt"):setString(getTextByKey("worldBoss_propInspireTips"))  --消耗每个军令加成

	local normalInspire = math.floor((self.worldBossConfig.normalInspireBuff+0.001) * 100) 
	self.panelUI:getChildByName("txt_boss_rankfont"):getChildByName("txt"):setString("" .. normalInspire .. "%")  --普通加成数据
	self.panelUI:getChildByName("txt_boss_inspire3"):getChildByName("txt"):setString(getTextByKey("worldBoss_goldInspireTips", {num = self.worldBossConfig.goldInspireCost}))  --每次消耗20个金币加成

	local goldInspire = math.floor( self.worldBossConfig.goldInspireBuff * 100 )
	self.panelUI:getChildByName("txt_boss_rankfont2"):getChildByName("txt"):setString("" .. goldInspire .. "%")  --金币加成数据


	local function getCurInspirePropAmount()
		for k, v in pairs(gameInitData.sharkProps.sharkProps) do
			if v.metaId == self.worldBossConfig.inspirePropId then
				return v.amount
			end
		end
		return 0
	end
	
	local function getExpectInspireValue()
	      local addInspire = self.propInspireCount * self.worldBossConfig.normalInspireBuff
		addInspire = addInspire + self.goldInspireCount * self.worldBossConfig.goldInspireBuff
		addInspire = addInspire + WorldBossScene.worldBossInfo.worldBossUserStatus.inspireAddition
		addInspire = addInspire + 0.0001
		if addInspire > DataManager.GameMetaData.activityWorldBossConfig.inspireLimit then
			addInspire = DataManager.GameMetaData.activityWorldBossConfig.inspireLimit
		end
		return addInspire
	end

	local function updateCurrentInspireValue()
		self.expectInspire = getExpectInspireValue()
		local stringInspire = math.floor( self.expectInspire * 100 )
		self.panelUI:getChildByName("txt_bossrank_font"):getChildByName("txt"):setString("" .. stringInspire .. "%")  --当前伤害加成

		local curprop = getCurInspirePropAmount() - self.propInspireCount
		self.panelUI:getChildByName("txt_boss_inspire4"):getChildByName("txt"):setString(getTextByKey("worldBoss_propNum") .. " " .. curprop)  --当前拥有的军令

		local curGams = CalculationManager.calcComplex_getGemsNow() - self.goldInspireCount*self.worldBossConfig.goldInspireCost
		self.panelUI:getChildByName("txt_boss_inspire6"):getChildByName("txt"):setString("" .. curGams)  --当前的金币值
	end

	updateCurrentInspireValue()


	local function onInspire( evt )
		print("onInspire in InspirePanel")
		--判断当前是否有足够的鼓舞道具
		local function isEnoughProp()
			local curAmount = getCurInspirePropAmount()
			if curAmount > self.propInspireCount then
				return true
			end
			return false
		end
            local addInspire = getExpectInspireValue()
		if addInspire >= self.worldBossConfig.inspireLimit then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("worldBoss_boostLimit"))
		elseif not isEnoughProp() then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("worldBoss_propInsufficient"))
		else
			self.propInspireCount = self.propInspireCount + 1
			updateCurrentInspireValue()
		end
	end

	local inspireBtn = Button:create(self.panelUI:getChildByName("icon_token_inspire"))
	inspireBtn:addEventListener(Events.kStart, onInspire)

    local function onGoldInspire(evt)
    	local nowGems = CalculationManager.calcComplex_getGemsNow()
    	local addInspire = getExpectInspireValue()

    	local vipLevel = DataManager.getGameInitData().sharkUser.vipLevel
    	if not VipManager.isOwnPriv(vipLevel, 17) then
				local requireVipLevel = VipManager.getStartUpVipLevel(17)
				self.container.targetInfoPanel = VipWarningPanel:create( self.container, requireVipLevel)
		        PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false , self.container)
		elseif addInspire >= self.worldBossConfig.inspireLimit then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("worldBoss_boostLimit"))
		elseif nowGems <  (self.goldInspireCount+1)*self.worldBossConfig.goldInspireCost then
			--SuspensionLabel:showContent(self, Localization:getInstance():getText("没有足够的金币了"))
			local function onReplaceScene()
                self.container:setTableViewsEnabled(true)
                self.container.targetInfoPanel = nil
                PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			end
			local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
			self.container:addChild(aPanel)
			aPanel:scaleIn()
		else
			self.goldInspireCount = self.goldInspireCount + 1
			updateCurrentInspireValue()
		end
    end

    local goldInspireBtn = Button:create(self.panelUI:getChildByName("icon_gold_inspire"))
	goldInspireBtn:addEventListener(Events.kStart, onGoldInspire)


	local function onConfirmPanel(evt)
		if self.propInspireCount <= 0 and self.goldInspireCount <= 0 then
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			self.container.targetInspirePanel = nil
			do return end
		end	


		local function onInspireInWorldBossSuccess(response)
			local gameInitData = DataManager.getGameInitData()
			print( "onInspireInWorldBossSuccess" )
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			WorldBossScene.worldBossInfo.worldBossUserStatus.inspireAddition = self.expectInspire
			for k, v in pairs(gameInitData.sharkProps.sharkProps) do
				if v.metaId == self.worldBossConfig.inspirePropId then
					if v.amount >= self.propInspireCount then
						v.amount = v.amount - self.propInspireCount
						break
					end
				end
			end
			DataManager.setGameInitData(gameInitData)
			
			local gemsCost = self.goldInspireCount * self.worldBossConfig.goldInspireCost
			RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -gemsCost})

			self.container:updateShowBattleState()
			self.container.targetInspirePanel = nil
		end
		
		local function onInspireInWorldBossFailed(response)
			print( "onInspireInWorldBossFailed" )
		end
		local worldBossInspireList = {}
		local inspire = {
		      type = 1,
		      amount = self.propInspireCount
	    }
	    table.insert(worldBossInspireList, inspire)
	    local goldInspire = {
		      type = 2,
		      amount = self.goldInspireCount
	    }
		table.insert(worldBossInspireList, goldInspire)
		local params = {worldBossInspireInfos = worldBossInspireList} 
		local request = InspireInWorldBossRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener( RequestNotifyEnum.inspireInWorldBossSuccessd, onInspireInWorldBossSuccess )
	    request:addEventListener( RequestNotifyEnum.inspireInWorldBossFailed, onInspireInWorldBossFailed )
		request:start()
		

	end

	self.panelUI:getChildByName("btn_boss_sure"):getChildByName("txt"):setString(getTextByKey("yes"))
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_boss_sure"))
    bt_panel_close:addEventListener(Events.kStart, onConfirmPanel)   
	
   
    local function onCancelPanel(evt)
        PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		self.container.targetInspirePanel = nil
    end 
	self.panelUI:getChildByName("btn_boss_cancel"):getChildByName("txt"):setString(getTextByKey("cancel"))
    local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_boss_cancel"))
    bt_panel_close:addEventListener(Events.kStart, onCancelPanel)   
   
	
end