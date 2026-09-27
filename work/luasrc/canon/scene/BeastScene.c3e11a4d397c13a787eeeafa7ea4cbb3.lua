require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.customUI/CanonCard"
require "canon.scene.BaseUIScene"
require "canon.panel.BeastDetailInfoPanel"
require "canon.panel.BeastNoBattlePanel"

require "canon.request.AvoidBattle"
require "canon.request.AdjustBeast"
require "canon.request.FinishBeastCompose"
require "canon.request.GetRobUserListRequest"
require "canon.request.RobBeastFragmentRequest"
require "canon.request.StartComposeBeast"
require "canon.scene.RobFragmentScene"


BeastScene = class(BaseUIScene)
local visibleSize = CCSizeMake(720, 1280)

local curIndex
local isInFinishComposingFlash = false

local function getBeastSpriteByBeastInfo(beastInfo)
	return "" .. beastInfo.attrs.beastPic .. ".png"
end

local function getBeastBriefSpriteByBeastInfo(beastInfo)
	return "" .. beastInfo.attrs.beastIcon .. ".png"
end

local function getBeastFragmentSpriteByBeastInfo(beastInfo, fragmentNum)
	return "" .. beastInfo.fragmentsTable[fragmentNum].icon .. ".png"
end

local beastNoBattleTime = 0
local fragmentsInfo = {}
local function getNoBattleTime()
	return beastNoBattleTime
end

local function getBeastDatas(datas)
	local beastData = DataManager.getSharkBeastsData()
	
	local serverTime = TimeUtil.getServerTimeSeconds()
	
	for k,data in pairs(datas) do
		local curBeastData
			if type(beastData.sharkBeasts) == "table" then
			for kk, vv in pairs(beastData.sharkBeasts) do
				if vv.metaId == data.attrs.id then
					curBeastData = vv
					break;
				end
			end
		end
		
		data.level = 0
		data.exp = 0
		data.inCompose = false
		data.composeTime = 0
		data.lastTimeStamp = serverTime
		data.inuse = false
		
		if curBeastData then
			data.level = curBeastData.level
			data.exp = curBeastData.exp
			data.composeTime = curBeastData.composeBeginSecond + MetaManager.game_meta.gameSettingConfig.beastConfig.beastCombineTime - data.lastTimeStamp
			data.inCompose = curBeastData.composing
			if type(beastData.sharkBeasts) == "table" then
				for kk, vv in pairs(beastData.currBeastIds) do
					if vv == data.attrs.id then
						data.inuse = true
						break;
					end
				end
			end
		end
		data.leftComposeTime = data.composeTime
		
		local showLevel = data.level
		if showLevel < 1 then
			showLevel = 1
		end
		data.totalExp = data.items[showLevel].exp
	
		for key, fragmentData in pairs(data.fragmentsTable) do
			data.fragmentsTable[key].amount = 0
			if type(fragmentsInfo.sharkBeastFragments) == "table" then
				for kk, vv in pairs(fragmentsInfo.sharkBeastFragments) do
					if fragmentData.id == vv.metaId then
						data.fragmentsTable[key].amount = vv.amount
						break;
					end
				end
			end
		end
	end
	
	if fragmentsInfo.avoidBattleEndSecond and fragmentsInfo.avoidBattleEndSecond > 0 then
		beastNoBattleTime = fragmentsInfo.avoidBattleEndSecond - serverTime
	else
		beastNoBattleTime = 0
	end
	
	return datas
end

function BeastScene.doPreparationBeforeReplaceToBeastScene(successCallback, failureCallback)
	local oneRequestDone = false
	local fragmentsInfo
	local function checkGotoBeastScene()
		if oneRequestDone then
			if successCallback then
				successCallback(fragmentsInfo)
			end
		else
			oneRequestDone = true
		end
	end
				
	local function onGetSharkBeastFragmentsSucceed(evt)
		fragmentsInfo = evt.data.sharkBeastFragments
		checkGotoBeastScene()
	end
				
	local function onGetSharkBeastFragmentsFailed(evt)
		CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		if failureCallback then
			failureCallback()
		end
	end
	
	local function sendGetSharkBeastFragments()
		local request = GetSharkBeastFragments.new( nil, rpc.SendingPriority.kNormal )
		request:addEventListener( RequestNotifyEnum.GetSharkBeastFragmentsSucceed, onGetSharkBeastFragmentsSucceed )
		request:addEventListener( RequestNotifyEnum.GetSharkBeastFragmentsFailed, onGetSharkBeastFragmentsFailed )
		request:start()
	end
				
	local function onGetSharkBeastsSucceed(evt)
		DataManager.setSharkBeastsData(evt.data.sharkBeasts)
		checkGotoBeastScene()
	end
			
	local function onGetSharkBeastsFailed(evt)
		CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		failureCallback()
	end
				
	local function sendGetSharkBeastsRequest()
		local request = GetSharkBeastsRequest.new( nil, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.GetSharkBeastsSucceed, onGetSharkBeastsSucceed )
		request:addEventListener( RequestNotifyEnum.GetSharkBeastsFailed, onGetSharkBeastsFailed )
		request:start()
	end
				
	sendGetSharkBeastFragments()
				
	sendGetSharkBeastsRequest()
end

function BeastScene.getBeastFragmentNameByData(fragmentData)
	local nameText = ""
	for k,data in pairs(MetaManager.beast_meta) do
		local fragments = string.split(data.attrs.beastFragmentId, '|')
		for key , fragmentId in pairs(fragments) do
			if tonumber(fragmentId) == fragmentData.metaId then
				nameText = nameText .. getTextByKey(data.attrs.beastNameKey) .. getTextByKey("beastFragment_" .. key)
				break;
			end
		end
	end
	return nameText
end

function BeastScene:ctor()
	self.title = getTextByKey("beast_title")
	curIndex = nil;
	self.curSceneEnum = SceneEnum.BeastScene
	fragmentsInfo = {}
	isInFinishComposingFlash = false;
end

function BeastScene:create( argv )
    if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end
    
    local scene = BeastScene.new()
		
		if argv.params.fragmentsInfo then
			fragmentsInfo = argv.params.fragmentsInfo
		end
		
    scene:initScene()
    return scene
end

function BeastScene:onInit()	
	BaseUIScene.initBackGround(self)
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/rob.json")
	self.builder.useArtLabelTTF = true
	
	self.mainUI = self.builder:build("rob")
	self.mainUI:getChildByName("rob_btn_watch_detail"):getChildByName("txt"):setString(getTextByKey("beast_descBtn"))
	self.mainUI:getChildByName("btn_usetoken"):getChildByName("txt"):setString(getTextByKey("beast_peaceBtn"))
	self.mainUI:getChildByName("btn_battle_on"):getChildByName("txt"):setString(getTextByKey("beast_activeBtn"))
	self.mainUI:getChildByName("rob_btn_compose"):getChildByName("txt"):setString(getTextByKey("beast_summonBtn"))
	self.mainUI:getChildByName("txt_outbattle"):getChildByName("txt"):setString(getTextByKey("beast_peace"))
	self.mainUI:getChildByName("rob_txt_unopen"):getChildByName("txt"):setString(getTextByKey("beast_peaceInactive"))
	
	self.expBar = ProgressBar:create(self.mainUI:getChildByName("icon_robExp"))
	
	self.beastDatas = {}
	for k,data in ipairs(MetaManager.beast_meta) do
		local beastData = table.clone(data, true)
		local fragments = string.split(data.attrs.beastFragmentId, '|')
		beastData.fragmentsTable = {}
		for key, fragData in ipairs(fragments) do
			local fragmentTable = MetaManager.beast_fragment[tonumber(fragData)]
			if fragmentTable then
				table.insert(beastData.fragmentsTable, fragmentTable)
			end
		end
		table.insert(self.beastDatas, beastData)
	end
	getBeastDatas(self.beastDatas)
	curIndex = self.argv.params.beginIndex or 1
	
	self.beastDetailTableView = self:createBeastDetailTableView(self.beastDatas)
	self.mainUI:addChildAt(self.beastDetailTableView, self.mainUI:getChildByName("bg_general_activity"):getZOrder() + 1)
	-- self.mainUI:addChildAt(self.beastDetailTableView,10)
	self.beastBriefTableView = self:createBeastBriefTableView(self.beastDatas)
	self.mainUI:addChild(self.beastBriefTableView)
	self.detailButtonPosY = self.mainUI:getChildByName("rob_btn_watch_detail"):getPositionY()
	
	local function onClickDetail(evt)
		self.targetInfoPanel = BeastDetailInfoPanel:create(self, self.beastDatas[curIndex])
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
	end
	
	local detailButton = Button:create(self.mainUI:getChildByName("rob_btn_watch_detail"))
	detailButton:addEventListener(Events.kStart, onClickDetail)
	
	local function onClickUseToken(evt)
		self.targetInfoPanel = BeastNoBattlePanel:create(self)
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
	end
	
	local useTokenButton = Button:create(self.mainUI:getChildByName("btn_usetoken"))
	useTokenButton:addEventListener(Events.kStart, onClickUseToken)
	self.useTokenButton = useTokenButton
	
	local function onBattleOnSuccess(evt)
		self.waitRequest = false
		g_previousBattleCount = CommonManager:getLocalPlayerStrength()
		for k,data in ipairs(self.beastDatas) do
			if curIndex == k then
				data.inuse = true
			else
				data.inuse = false
			end
		end
		
		local beastData = DataManager.getSharkBeastsData()
		beastData.currBeastIds = {curIndex}
		DataManager.setSharkBeastsData(beastData)
		
		self:refreshBriefTable(true)
		self:refreshBeastDetailInfo()

		--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
		DataManager.fightCapacityMaybeUpdated()
	end
	
	local function onBattleOnFailed(evt)
		self.waitRequest = false
		if evt.data == 716000 then
			local function closeCanonMessageBox()
				self:sendGetSharkBeastsRequest()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("beastError_notAvailable"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 716015 then
			local function closeCanonMessageBox()
				self:sendGetSharkBeastsRequest()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("beastError_notAvailable"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		else
			CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		end
	end
	
	local function sendBattlOnRequest()
		if self.waitRequest then
			do return end
		end
		
		self.waitRequest = true;
		
		local request = AdjustBeast.new( {beastIds = {self.beastDatas[curIndex].attrs.id}}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.AdjustBeastSucceed, onBattleOnSuccess )
		request:addEventListener( RequestNotifyEnum.AdjustBeastFailed, onBattleOnFailed )
		request:start()
	end
	
	local function onClickBattleon(evt)
		if self.beastDatas[curIndex].inuse then
			SuspensionLabel:showContent(self, getTextByKey("beast_alreadyActive"))
		else
			sendBattlOnRequest()
		end
	end
	
	local battleonButton = Button:create(self.mainUI:getChildByName("btn_battle_on"))
	battleonButton:addEventListener(Events.kStart, onClickBattleon)
	self.battleonButton = battleonButton
	
	local function onComposeSuccess(evt)
		self.waitRequest = false
		local curBeastInfo = self.beastDatas[curIndex]
		local beastInfo = DataManager.getSharkBeastsData()
		local exist = false
		local tosetBeastTable = {}
		
		if not beastInfo.sharkBeasts then
			beastInfo.sharkBeasts = {}
		end
		
		for k,data in pairs(beastInfo.sharkBeasts) do
			if data.metaId == curBeastInfo.attrs.id then
				exist = true
				tosetBeastTable = data
				break;
			end
		end
		
		curBeastInfo.inCompose = true
		curBeastInfo.composeTime = MetaManager.game_meta.gameSettingConfig.beastConfig.beastCombineTime
		curBeastInfo.leftComposeTime = curBeastInfo.composeTime
		curBeastInfo.lastTimeStamp = TimeUtil.getServerTimeSeconds()
		
		tosetBeastTable.level = curBeastInfo.level
		tosetBeastTable.metaId = curBeastInfo.attrs.id
		tosetBeastTable.exp = curBeastInfo.exp
		tosetBeastTable.composeBeginSecond = curBeastInfo.lastTimeStamp
		tosetBeastTable.composing = curBeastInfo.inCompose
		
		if not exist then
			table.insert(beastInfo.sharkBeasts, tosetBeastTable)
		end
		
		DataManager.setSharkBeastsData(beastInfo)		
		self.beastDetailTableView:updateCellAtIndex(curIndex - 1)
		self:refreshComposeButton()
	end
	
	local function onComposeFailed(evt)
		self.waitRequest = false
		
		if evt.data == 716020 then
			local function closeCanonMessageBox()
				self:sendGetSharkBeastsRequest()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("beastError_inCombine"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 716010 then
			local function closeCanonMessageBox()
				self:regetFragmentInfo()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("beast_fragmentInsufficient"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		else
			CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		end
	end
	
	local function sendComposeRequest()
		if self.waitRequest then
			do return end
		end
		
		self.waitRequest = true;
		
		local request = StartComposeBeast.new( {beastId = self.beastDatas[curIndex].attrs.id}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.StartComposeBeastSucceed, onComposeSuccess )
		request:addEventListener( RequestNotifyEnum.StartComposeBeastFailed, onComposeFailed )
		request:start()
	end
	
	local function onEnsureComposeSuccess(evt)
		local getBeastInfo = evt.data.sharkBeast
		local curBeastInfo
		for k, data in pairs(self.beastDatas) do
			if getBeastInfo.metaId == data.attrs.id then
				curBeastInfo = data
				break;
			end
		end

		local shouldShowAttrChange = false;
		if curBeastInfo.inuse and curBeastInfo.level < getBeastInfo.level then
			g_previousBattleCount = CommonManager:getLocalPlayerStrength()
			shouldShowAttrChange = true
		end
		
		for k, data in ipairs(curBeastInfo.fragmentsTable) do
			data.amount = data.amount - 1
		end
		
		curBeastInfo.level = getBeastInfo.level
		curBeastInfo.exp = getBeastInfo.exp
		curBeastInfo.totalExp = curBeastInfo.items[curBeastInfo.level].exp
		curBeastInfo.inCompose = false
		local oldValue = CommonManager:getLocalPlayerStrength()
		local beastData = DataManager.getSharkBeastsData()
		if not beastData.sharkBeasts then
			beastData.sharkBeasts = {}
		end
		local exist = false
		for k,data in pairs(beastData.sharkBeasts) do
			if data.metaId == getBeastInfo.metaId then
				beastData.sharkBeasts[k] = getBeastInfo
				exist = true
				break;
			end
		end
		
		if not exist then
			table.insert(beastData.sharkBeasts, getBeastInfo)
		end
		DataManager.setSharkBeastsData(beastData)
		
		isInFinishComposingFlash = true;
		local finishComposeFlash = FlashSprite:create("EVO2/rob_combine")
		local finishComposeFlash_co = CocosObject.new(finishComposeFlash)
		self.beastDetailTableView:updateCellAtIndex(curIndex - 1)
		local function refreshUIInfo()
			if exist then
				--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
				DataManager.fightCapacityMaybeUpdated()
			end
      
			isInFinishComposingFlash = false;
			finishComposeFlash_co:removeFromParentAndCleanup(true)
			self:setTableViewsEnabled(true)
			self:refreshTable(true)
			self:refreshBeastDetailInfo()
			
			local noBeastInUse = true
			for k, data in pairs(self.beastDatas) do
				if data.inuse then
					noBeastInUse = false
					break;
				end
			end
			if noBeastInUse then
				sendBattlOnRequest()
			else
				if shouldShowAttrChange then
					--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
					DataManager.fightCapacityMaybeUpdated()
				end
			end

			--取消遮罩
		    self.tempLayer:removeFromParentAndCleanup(true)
		    self.targetInfoPanel = nil
			
			--facebook share beast level up info
			FacebookShareManager.facebookShareBeast(self.beastDatas[curIndex].level)
		end

		--遮罩
	  self.tempLayer = Layer:create()
	  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	  self:addChild(self.tempLayer)
	  self.targetInfoPanel = self.tempLayer
		
		finishComposeFlash:addChangeInstance("showBeast", CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(getBeastSpriteByBeastInfo(self.beastDatas[curIndex])))
		finishComposeFlash:changeAnimation(0)
		finishComposeFlash:registerEndAnimationScriptHandler(refreshUIInfo)		
		self:addChild(finishComposeFlash_co)
		self:setTableViewsEnabled(false)
		
	end
	
	local function onEnsureComposeFailed(evt)
		if evt.data == 716012 then
			local function closeCanonMessageBox()
				self:sendGetSharkBeastsRequest()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("beastError_notInCombine"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 716013 then
			local function closeCanonMessageBox()
				self:sendGetSharkBeastsRequest()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("beastError_timeIsNotOver"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 716010 then
			local function closeCanonMessageBox()
				self.beastDatas[curIndex].inCompose = false
				self:regetFragmentInfo()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("beast_fragmentInsufficient"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		else
			CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		end
	end
	
	local function sendEnsureSuccessRequest()
		local index = curIndex
		local request = FinishBeastCompose.new( {beastId = self.beastDatas[index].attrs.id}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.FinishBeastComposeSucceed, onEnsureComposeSuccess )
		request:addEventListener( RequestNotifyEnum.FinishBeastComposeFailed, onEnsureComposeFailed )
		request:start()
	end
	
	local function onClickCompose(evt)
		local curBeastInfo = self.beastDatas[curIndex]
		if curBeastInfo.inCompose then
			sendEnsureSuccessRequest()
		else
			if curBeastInfo.totalExp == 0 then
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("beast_levelMax"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
				do return end
			else
				local canCompose = true
				for k, fragment in pairs(curBeastInfo.fragmentsTable) do
					if fragment.amount <= 0 then
						canCompose = false
					end
				end
				if canCompose then
					sendComposeRequest()
				else
					local function closeCanonMessageBox()
					end
					self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("beast_fragmentInsufficient"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
					do return end
				end
			end
		end
	end
	
	local composeButton = Button:create(self.mainUI:getChildByName("rob_btn_compose"))
	composeButton:addEventListener(Events.kStart, onClickCompose)
	self.composeButton = composeButton
	
	self:refreshBeastDetailInfo()
	
	self:getNoBattleTimeInfo()
	
	self:addChild(self.mainUI)
	BaseUIScene.onInit(self)
	
	self:synchronizationBriefTable(0)
	self:synchronizationDetailTable(0)

end

function BeastScene:sendGetSharkBeastsRequest()
	local function onGetSharkBeastsSucceed(evt)
		DataManager.setSharkBeastsData(evt.data.sharkBeasts)
		getBeastDatas(self.beastDatas)
		self:refreshTable(true)
		self:refreshBeastDetailInfo()
	end
				
	local function onGetSharkBeastsFailed(evt)
		CanonMessageBox:showCommUnHandleErrorBox(evt.data)
	end
	
	local request = GetSharkBeastsRequest.new( nil, rpc.SendingPriority.kHigh )
	request:addEventListener( RequestNotifyEnum.GetSharkBeastsSucceed, onGetSharkBeastsSucceed )
	request:addEventListener( RequestNotifyEnum.GetSharkBeastsFailed, onGetSharkBeastsFailed )
	request:start()
end

function BeastScene:resetFragmentInfo()
	for k, data in pairs(self.beastDatas) do
		for key, fragmentData in pairs(data.fragmentsTable) do
			data.fragmentsTable[key].amount = 0
			if type(fragmentsInfo.sharkBeastFragments) == "table" then
				for kk, vv in pairs(fragmentsInfo.sharkBeastFragments) do
					if fragmentData.id == vv.metaId then
						data.fragmentsTable[key].amount = vv.amount
						break;
					end
				end
			end
		end
	end
	self:refreshTable(true)
end

function BeastScene:regetFragmentInfo()
	local function onGetSharkBeastFragmentsSucceed(evt)
		fragmentsInfo = evt.data.sharkBeastFragments
		self:resetFragmentInfo()		
		self:refreshBeastDetailInfo()
	end
				
	local function onGetSharkBeastFragmentsFailed(evt)
		CanonMessageBox:showCommUnHandleErrorBox(evt.data)
	end
				
	local function sendGetSharkBeastFragments()
		local request = GetSharkBeastFragments.new( nil, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.GetSharkBeastFragmentsSucceed, onGetSharkBeastFragmentsSucceed )
		request:addEventListener( RequestNotifyEnum.GetSharkBeastFragmentsFailed, onGetSharkBeastFragmentsFailed )
		request:start()
	end
	
	sendGetSharkBeastFragments()
end

function BeastScene:getNoBattleTimeInfo(nobattleTime)
	if not nobattleTime then
		nobattleTime = getNoBattleTime()
	end
	self.noBattleTime = nobattleTime
	self.lastTimeStamp = TimeUtil.getServerTimeSeconds()
	self.noBattleTimeLeft = self.noBattleTime
	
	local function refreshNoBattleStatus()
		self.noBattleTimeLeft = self.noBattleTime - (TimeUtil.getServerTimeSeconds() - self.lastTimeStamp)
		self.mainUI:getChildByName("rob_txt_unopen"):setVisible(self.noBattleTimeLeft <= 0)
		self.mainUI:getChildByName("rob_txt_time"):setVisible(self.noBattleTimeLeft > 0)
		if self.noBattleTimeLeft > 0 then
			self.mainUI:getChildByName("rob_txt_time"):getChildByName("txt"):setString( string.format( "%02d:%02d:%02d", math.floor(self.noBattleTimeLeft/3600), math.floor((self.noBattleTimeLeft % 3600)/60), math.floor(self.noBattleTimeLeft % 60)))	
			self.useTokenButton:setEnable(false)
			self.mainUI:getChildByName("btn_usetoken"):getChildByName("btn"):setVisible(false)
		else
			self.useTokenButton:setEnable(true)
			self.mainUI:getChildByName("btn_usetoken"):getChildByName("btn"):setVisible(true)
			if self.noBattleTimeSchedule then
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.noBattleTimeSchedule)
				self.noBattleTimeSchedule = nil
			end
		end
	end
	
	if self.noBattleTimeSchedule then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.noBattleTimeSchedule)
		self.noBattleTimeSchedule = nil
	end
	self.noBattleTimeSchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshNoBattleStatus,1,false)
	
	refreshNoBattleStatus()
end

function BeastScene:synchronizationBriefTable(duration)
	local locationDuration = duration
	if not locationDuration then
		locationDuration = 0.3
	end
	
	local minPosX = -(180 * #self.beastDatas - 720)
	local tosetPosX = -180 * (curIndex - 1)
	if tosetPosX < minPosX then
		tosetPosX = minPosX
	end
	
	if math.abs(tosetPosX - self.beastBriefTableView.refCocosObj:getContainer():getPositionX()) < 1 then
		do return end
	end
	
	self.beastBriefTableView:setContentOffsetInDuration(ccp(tosetPosX, 0), locationDuration)
	
	local function onLocationFinish()
		self:setTableViewsEnabled(true)
	end
	self:setTableViewsEnabled(false)
	local actionArray = CCArray:create()
	actionArray:addObject(CCDelayTime:create(locationDuration))
	actionArray:addObject(CCCallFuncN:create(onLocationFinish))
	self:runAction(CCSequence:create(actionArray))
end

function BeastScene:synchronizationDetailTable(duration)
	local locationDuration = duration
	if not locationDuration then
		locationDuration = 0
	end
	local tosetPosX = -720 * (curIndex - 1)
	if math.abs(tosetPosX - self.beastDetailTableView.refCocosObj:getContainer():getPositionX()) < 1 then
		do return end
	end
	self.beastDetailTableView:setContentOffsetInDuration(ccp(tosetPosX, 0), locationDuration)
	
	local function onLocationFinish()
		self:setTableViewsEnabled(true)
	end
	self:setTableViewsEnabled(false)
	local actionArray = CCArray:create()
	actionArray:addObject(CCDelayTime:create(locationDuration))
	actionArray:addObject(CCCallFuncN:create(onLocationFinish))
	self:runAction(CCSequence:create(actionArray))
end

function BeastScene:refreshTable(keepOffset)
	self:refreshBriefTable(keepOffset)
	self:refreshDetailTable(keepOffset)
end

function BeastScene:refreshBriefTable(keepOffse)
	if keepOffset then
		local tableOffset = self.beastBriefTableView:getContentOffset()
		self.beastBriefTableView:reloadData()
		self.beastBriefTableView:setContentOffset(tableOffset, true)
	else
		self.beastBriefTableView:reloadData()
	end
end

function BeastScene:refreshDetailTable(keepOffset)
	if keepOffset then
		local tableOffset = self.beastDetailTableView:getContentOffset()
		self.beastDetailTableView:reloadData()
		self.beastDetailTableView:setContentOffset(tableOffset, true)
	else
		self.beastDetailTableView:reloadData()
	end
end

function BeastScene:refreshBeastDetailInfo()
	local function setBeastInfoVisible(visible)
		self.mainUI:getChildByName("icon_lv"):setVisible(visible)
		self.mainUI:getChildByName("rob_txt_lv"):setVisible(visible)
		self.mainUI:getChildByName("txt_icon_robExp_num"):setVisible(visible)
		self.mainUI:getChildByName("icon_rob_exp_light"):setVisible(visible)
		self.mainUI:getChildByName("icon_robExp"):setVisible(visible)
		self.mainUI:getChildByName("bg_home_exp"):setVisible(visible)
		self.mainUI:getChildByName("txt_watch_detail"):setVisible(visible)
		self.mainUI:getChildByName("btn_battle_on"):getChildByName("btn"):setVisible(visible)
		self.battleonButton:setEnable(visible)
	end
	
	local curBeastInfo = self.beastDatas[curIndex]
	
	setBeastInfoVisible(curBeastInfo.level > 0)
	
	if curBeastInfo.level <= 0 then
		self.mainUI:getChildByName("rob_btn_watch_detail"):setPositionY(self.detailButtonPosY + 26)
	else
		self.mainUI:getChildByName("rob_btn_watch_detail"):setPositionY(self.detailButtonPosY)
		self.mainUI:getChildByName("txt_icon_robExp_num"):getChildByName("font"):setString(tostring(curBeastInfo.exp) .. "/" .. curBeastInfo.totalExp)
		self.mainUI:getChildByName("rob_txt_lv"):getChildByName("txt_calendar_icon_upper"):setString(curBeastInfo.level)
		self.mainUI:getChildByName("txt_watch_detail"):getChildByName("txt"):setString(getTextByKey(curBeastInfo.items[curBeastInfo.level].beastSkillDesc))
		local percentage = 100
		if curBeastInfo.totalExp > 0 then
			percentage = curBeastInfo.exp / curBeastInfo.totalExp * 100
		end
		if percentage > 100 then
			percentage = 100
		end
		self.expBar:setPercentage(percentage)
	end
	
	self:refreshComposeButton()
	
end

function BeastScene:refreshComposeButton()
	local curBeastInfo = self.beastDatas[curIndex]
	
	local composeBtnText = self.mainUI:getChildByName("rob_btn_compose"):getChildByName("txt")
	local composeBtnBtn = self.mainUI:getChildByName("rob_btn_compose"):getChildByName("btn")
	if curBeastInfo.leftComposeTime > 0 then
		composeBtnText:setString(string.format( "%02d:%02d:%02d", math.floor(curBeastInfo.leftComposeTime/3600), math.floor((curBeastInfo.leftComposeTime % 3600)/60), math.floor(curBeastInfo.leftComposeTime % 60)))
		self.composeButton:setEnable(false)
		composeBtnBtn:setVisible(false)
	elseif curBeastInfo.inCompose then
		composeBtnText:setString(getTextByKey("beast_completeBtn"))
		self.composeButton:setEnable(true)
		composeBtnBtn:setVisible(true)
	else
		if curBeastInfo.level <= 0 then
			composeBtnText:setString(getTextByKey("beast_summonBtn"))
		else
			composeBtnText:setString(getTextByKey("beast_enhanceBtn"))
		end
		
		local haveAllFragment = true
		
		for k,data in pairs(curBeastInfo.fragmentsTable) do
			if data.amount <= 0 then
				haveAllFragment = false
				break;
			end
		end
		
		self.composeButton:setEnable(haveAllFragment)
		composeBtnBtn:setVisible(haveAllFragment)
	end
	
	local function refreshComposeStatus()
		local hasCompose = false
		for k, data in ipairs(self.beastDatas) do
			if data.leftComposeTime > 0 then
				hasCompose = true
				data.leftComposeTime = data.composeTime - (TimeUtil.getServerTimeSeconds() - data.lastTimeStamp)
				if data.leftComposeTime <= 0 then
				end
				if k == curIndex then
					self:refreshComposeButton()
				end
			end
		end
		
		if not hasCompose then
			if self.inComposeSchedule then
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.inComposeSchedule)
				self.inComposeSchedule = nil
			end
		end
	end
	
	if not self.inComposeSchedule then
		self.inComposeSchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshComposeStatus,1,false)
		refreshComposeStatus()
	end
	
end

local TABLEVIEW_CELL_TAG = -1001
local TXT_BEAST_NAME_TAG = 1001
local ICON_FAKE_BEAST_TAG = 1002
local ICON_BEAST_TAG = 1003
local ICON_FIRST_FRAGMENT_TAG = 1004
local ICON_LAST_FRAGMENT_TAG = 1009
local TXT_FRAGMENT_NAME_TAG = 1010
local TXT_FRAGMENT_AMOUNT_TAG = 1011
local ICON_FAKE_FRAGMENT_TAG = 1012
local ICON_FRAGMENT_TAG = 1013
local TXT_BEAST_LEVEL_TAG = 1014
local ICON_INUSE_TAG = 1015
local FLASH_BG = 1016

local function inArea(posX, posY, rect)
	if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
		return true
	end
	return false
end

local function setTextByTag( cell, tag, str)
	local txt = cell:getChildByTag(tag):getChildByTag(tag)
	setNodeText(txt, str);
end
	
local function setNodeVisibleByTag(cell, tag, visible)
	cell:getChildByTag(tag):setVisible(visible)
end

local function getMiddlePosition(cell, tag)
	local posX, posY = cell:getChildByTag(tag):getPosition()
	local contentSize = cell:getChildByTag(tag):getContentSize()
	local scaleX,scaleY = cell:getChildByTag(tag):getScaleX(), cell:getChildByTag(tag):getScaleY()
	return ccp(posX + contentSize.width / 2 * scaleX, posY - contentSize.height /2 * scaleY)
end

local function addNodeReplaceWithTag(cell, tag, node, nodeTag)
	if cell:getChildByTag(nodeTag) then
		cell:removeChildByTag(nodeTag, true)
	end
	node:setTag(nodeTag)
	node:setPosition(getMiddlePosition(cell, tag))
	local zOrder = cell:getChildByTag(tag):getZOrder()
	cell:addChild(node, zOrder)
end

function BeastScene:createBeastDetailTableView(data)
	local BeastDetailRenderer = class(TableViewRenderer)
	local SELF = self
	function BeastDetailRenderer:ctor(width, height)
		self.list = data
		local builder = LayoutBuilder:createWithContentsOfFile("scene/rob.json")
		builder.useArtLabelTTF = true
		self.builder = builder
	end 

	function BeastDetailRenderer:buildCell(container)
		local cell = self.builder:build("rob_main")
		cell:setPosition(ccp(0, self.height))		
		cell:setTag(TABLEVIEW_CELL_TAG)
		container:addChild(cell)
		
		-- cell:getChildByName("rob_background"):getChildByName("fz_sb"):setOpacity(75)
		-- cell:getChildByName("rob_background"):getChildByName("fz_sb_m_1"):setOpacity(75)
		-- cell:getChildByName("rob_background"):getChildByName("fz_sb_m_2"):setOpacity(75)
		-- cell:getChildByName("rob_background"):getChildByName("fz_sb_m_3"):setOpacity(75)
		
		cell:getChildByName("txt_name"):setTag(TXT_BEAST_NAME_TAG)
		cell:getChildByName("txt_name"):getChildByName("txt"):setTag(TXT_BEAST_NAME_TAG)
		cell:getChildByName("rob_main"):setTag(ICON_FAKE_BEAST_TAG)
		cell:getChildByName("rob_main"):setVisible(false)
		for i = 1, 6 do
			local fragment = cell:getChildByName("rob_chip" .. i)
			fragment:setTag(ICON_FIRST_FRAGMENT_TAG + i - 1)
			fragment:getChildByName("rob_txt_circle_upper"):getChildByName("txt_calendar_icon_upper"):setString(getTextByKey("beastFragment_" .. i))
			fragment:getChildByName("rob_txt_circle_upper_figure"):setTag(TXT_FRAGMENT_AMOUNT_TAG)
			fragment:getChildByName("rob_txt_circle_upper_figure"):getChildByName("txt"):setTag(TXT_FRAGMENT_AMOUNT_TAG)
			fragment:getChildByName("rob_icon"):setTag(ICON_FAKE_FRAGMENT_TAG)
			fragment:getChildByName("rob_icon"):setVisible(false)
		end
		
		local bgEffectFlash = FlashSprite:create("EVO2/rob_combine")
		bgEffectFlash:addChangeInstance("showBeast", createSpriteFrame("pic/empty.png"))		
		bgEffectFlash:changeAnimation(1)
		bgEffectFlash:setPosition(-5, -self.height - 130)
		bgEffectFlash:setTag(FLASH_BG)
		bgEffectFlash:setVisible(false)
		cell:addChildAt(CocosObject.new(bgEffectFlash), cell:getChildByName("rob_background"):getZOrder() + 1)
	end

	function BeastDetailRenderer:setData( rawCocosObj, index )
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)
		local beastInfo = data[index + 1]
		
		setTextByTag(cell, TXT_BEAST_NAME_TAG, getTextByKey(beastInfo.attrs.beastNameKey))
		local beastSprite = CCSprite:createWithSpriteFrameName(getBeastSpriteByBeastInfo(beastInfo))
		addNodeReplaceWithTag(cell, ICON_FAKE_BEAST_TAG, beastSprite, ICON_BEAST_TAG)
		
		beastSprite:setVisible(not isInFinishComposingFlash)
		
		for i = 1, 6 do
			local fragment = cell:getChildByTag(ICON_FIRST_FRAGMENT_TAG + i - 1)
			if fragment then
				setTextByTag(fragment, TXT_FRAGMENT_AMOUNT_TAG, "x" .. beastInfo.fragmentsTable[i].amount)
				local fragmentSprite = CCSprite:createWithSpriteFrameName(getBeastFragmentSpriteByBeastInfo(beastInfo, i))
				if beastInfo.fragmentsTable[i].amount <= 0 then
					fragmentSprite:setColor(ccc3(80, 80, 80))
				end
				addNodeReplaceWithTag(fragment, ICON_FAKE_FRAGMENT_TAG, fragmentSprite, ICON_FRAGMENT_TAG)
			end
		end

		setNodeVisibleByTag(cell, FLASH_BG, (beastInfo.leftComposeTime > 0 or beastInfo.inCompose))
	end
	
	local renderer = BeastDetailRenderer.new(720, 750)
	local buttonTag = {}
	for i = ICON_FIRST_FRAGMENT_TAG, ICON_LAST_FRAGMENT_TAG do
		table.insert(buttonTag, i)
	end
	
  local list = TableView:create(renderer, 720, 750, TABLEVIEW_CELL_TAG, buttonTag, nil, nil, nil, nil, {noScrollBar = true})
	list:setDirection(kCCScrollViewDirectionHorizontal)
	list:setPageEnabled(true)
	list:reloadData()
	local function onListItemTouch( evt ) 
		local selectedCell = list:cellAtIndex(evt.data):getChildByTag(TABLEVIEW_CELL_TAG)
		local curTabIndex = evt.context
		self._data = data[evt.data + 1]
		
		local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
		
		for i = 1, 6 do
			local itemPosX, itemPosY = selectedCell:getChildByTag(ICON_FIRST_FRAGMENT_TAG + i - 1):getPosition()
			local itemRect = {}
			itemRect.width = 176.5
			itemRect.height = 160.75
			itemRect.x = itemPosX
			itemRect.y = itemPosY - itemRect.height
			
			local function gotoFight()
				if self.waitRequest then
					do return end
				end
        local id = self._data.fragmentsTable[i].id
        local function successCallback(data)
					self.waitRequest = false
          local robUserList = data.robUserList
          local robRobotList = data.robRobotList
          self:replaceScene(RobFragmentScene, {enterScene="BeastScene",returnScene="BeastScene",params={robPlayers = robUserList, beastFragmentId = id, beginIndex = self.selectIndex, leftTime = SELF.noBattleTimeLeft , robRobots = robRobotList}})
        end
        
        local function failureCallback(data)
					self.waitRequest = false
          if data.retCode == 716019 then
						SuspensionLabel:showContent(self, getTextByKey("beast_fragmentLimit"))
						self:regetFragmentInfo()
					else
						CanonMessageBox:showCommUnHandleErrorBox(data.retCode)
					end
        end
        self.waitRequest = true
				self.selectIndex = curIndex
        RobFragmentScene.doPreparationBeforeReplaceToFragmentScene(id, successCallback, failureCallback)
			end
			
			if inArea(posInCell.x, posInCell.y, itemRect) then
				if self._data.fragmentsTable[i].amount >= 999 then
					SuspensionLabel:showContent(self, getTextByKey("beast_fragmentLimit"))
				--[[elseif self.noBattleTimeLeft > 0 then
					local function closeCanonMessageBox()
					end
					self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("beastRob_peaceTips"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, gotoFight, closeCanonMessageBox)--]]
				else
					gotoFight()
				end
				break;
			end
		end
	end
	
	local function onSelectItem(evt)
		if curIndex ~= evt.globalPosition + 1 then
			curIndex = evt.globalPosition + 1
			SELF:refreshBriefTable(true)
			SELF:synchronizationBriefTable()
			SELF:refreshBeastDetailInfo()
		end
	end

  list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  list:addEventListener(DisplayEvents.kSelectItem, onSelectItem)
  list:setPosition(ccp(0, 120))
  return list
end

function BeastScene:createBeastBriefTableView(data)
	local BeastBriefRenderer = class(TableViewRenderer)
	local SELF = self
	function BeastBriefRenderer:ctor(width, height)
		self.list = data
		local builder = LayoutBuilder:createWithContentsOfFile("scene/rob.json")
		builder.useArtLabelTTF = true
		self.builder = builder
	end 

	function BeastBriefRenderer:buildCell(container)
		local cell = self.builder:build("rob_icon_upper")
		cell:setPosition(ccp(0, self.height - 12))		
		cell:setTag(TABLEVIEW_CELL_TAG)
		container:addChild(cell)
		
		cell:getChildByName("txt_icon_upper"):setTag(TXT_BEAST_NAME_TAG)
		cell:getChildByName("txt_icon_upper"):getChildByName("txt_calendar_icon_upper"):setTag(TXT_BEAST_NAME_TAG)
		cell:getChildByName("txt_icon_upper_lv"):setTag(TXT_BEAST_LEVEL_TAG)
		cell:getChildByName("txt_icon_upper_lv"):getChildByName("txt_calendar_icon_upper"):setTag(TXT_BEAST_LEVEL_TAG)
		cell:getChildByName("icon_stageList_challenge"):setTag(ICON_INUSE_TAG)
		cell:getChildByName("active_title"):setTag(ICON_FAKE_BEAST_TAG)
	end

	function BeastBriefRenderer:setData( rawCocosObj, index )
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)

		local beastInfo = data[index + 1]
		setTextByTag(cell, TXT_BEAST_NAME_TAG, getTextByKey(beastInfo.attrs.beastNameKey))
		setNodeVisibleByTag(cell, TXT_BEAST_LEVEL_TAG, beastInfo.level > 0)
		setTextByTag(cell, TXT_BEAST_LEVEL_TAG, "Lv." .. beastInfo.level)
		setNodeVisibleByTag(cell, ICON_INUSE_TAG, beastInfo.inuse == true)
		
		local beastSprite = CCSprite:createWithSpriteFrameName(getBeastBriefSpriteByBeastInfo(beastInfo))
		beastSprite:setScale( 140 / beastSprite:getContentSize().width)
		addNodeReplaceWithTag(cell, ICON_FAKE_BEAST_TAG, beastSprite, ICON_BEAST_TAG)
		
		setNodeVisibleByTag(cell, ICON_FAKE_BEAST_TAG, curIndex == index + 1)
	end
	
	local renderer = BeastBriefRenderer.new(180, 180)
  local list = TableView:create(renderer, 720, 180, TABLEVIEW_CELL_TAG, {}, nil, nil, nil, nil, {noScrollBar = true})
	list:setDirection(kCCScrollViewDirectionHorizontal)
	list:setPageEnabled(true)
	list:reloadData()
	local function onListItemTouch( evt ) 
		local selectedCell = list:cellAtIndex(evt.data):getChildByTag(TABLEVIEW_CELL_TAG)
		local curTabIndex = evt.context
		self._data = data[evt.data + 1]
		curIndex = evt.data + 1
		SELF:refreshBriefTable(true)
		SELF:synchronizationDetailTable()
		SELF:refreshBeastDetailInfo()
		
		local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
	end

  list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  list:setPosition(ccp(0, 870))
  return list
end

function BeastScene:dispose()
	if self.noBattleTimeSchedule then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.noBattleTimeSchedule)
		self.noBattleTimeSchedule = nil
	end
	
	if self.inComposeSchedule then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.inComposeSchedule)
		self.inComposeSchedule = nil
	end
	
	BaseUIScene.dispose(self)
end

function BeastScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function BeastScene:preEnterAnimation()
	CanonPlayBackgroundMusic("music/background.mp3", true)
  BaseUIScene.preEnterAnimation(self)
end

function BeastScene:startEnterAnimation()
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

function BeastScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
  if GuideConfig.kBeast == nil then
    GuideConfig.kBeast = "Guide_Beast"
  end
  ExeNewGuide( GuideConfig.kBeast )
end

function BeastScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function BeastScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function BeastScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
      self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))	
end

function BeastScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function BeastScene:back()
	if self.argv and self.argv.returnScene == "BackpackScene" then
		self:replaceScene(BackpackScene, {params = {tabIndex = BAGCATEGORY.item}})
	else
		self:replaceScene(MainMenuScene)
	end
end

function BeastScene:setTableViewsEnabled( v )
	if (v) then
		self.touchDisableSetTimes = self.touchDisableSetTimes - 1
		if (self.touchDisableSetTimes <= 0) then
			if self.beastDetailTableView then
				self.beastDetailTableView:setTouchEnabled(v)
			end
			if self.beastBriefTableView then
				self.beastBriefTableView:setTouchEnabled(v)
			end
			self.mainUI:setTouchEnabled(v)
		end
	else
		self.touchDisableSetTimes = self.touchDisableSetTimes + 1
		if self.beastDetailTableView then
			self.beastDetailTableView:setTouchEnabled(v)
		end
		if self.beastBriefTableView then
			self.beastBriefTableView:setTouchEnabled(v)
		end
		self.mainUI:setTouchEnabled(v)
	end
end