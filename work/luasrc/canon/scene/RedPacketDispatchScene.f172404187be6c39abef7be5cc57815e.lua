require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.scene.BaseUIScene"
require "canon.manager.BagCalcManager"

require "canon.request.DistributeBonusRequest"
require "canon.panel.RedPacketAccpterListPanel"

RedPacketDispatchScene = class(BaseUIScene)
local visibleSize = CCSizeMake(720, 1280)
local enter_animation_duration = 0.3

local listData = {}--出战&上阵卡牌

function RedPacketDispatchScene:sortData()
	local function sortFriend(a , b)
		if a.lastestOfflineSeconds == b.lastestOfflineSeconds then
			return a.uid > b.uid
		else
			return a.lastestOfflineSeconds > b.lastestOfflineSeconds
		end
	end

	local function sortUnion(a , b)
		if a.lastestConstructDays == b.lastestConstructDays then
			if a.hisContribute == b.hisContribute then
				return a.uid > b.uid
			else
				return a.hisContribute > b.hisContribute
			end
		else
			return a.lastestConstructDays > b.lastestConstructDays
		end
	end

	local tempFriend = {}
	local finishTempFriend = {}
	for k,v in pairs(listData.friendList) do
		if v.itemDescKey == v.acceptNum then
			table.insert(finishTempFriend , v)
		else
			table.insert(tempFriend , v)
		end
	end
	table.sort(finishTempFriend , sortFriend)
	table.sort(tempFriend , sortFriend)
	for i=#listData.friendList,1,-1 do
		table.remove(listData.friendList , i)
	end
	for k,v in pairs(tempFriend) do
		table.insert(listData.friendList , v)
	end
	for k,v in pairs(finishTempFriend) do
		table.insert(listData.friendList , v)
	end

	local tempUnion = {}
	local finishTempUnion = {}
	for k,v in pairs(listData.unionList) do
		if v.itemDescKey == v.acceptNum then
			table.insert(finishTempUnion , v)
		else
			table.insert(tempUnion , v)
		end
	end
	table.sort(finishTempUnion , sortUnion)
	table.sort(tempUnion , sortUnion)
	for i=#listData.unionList,1,-1 do
		table.remove(listData.unionList , i)
	end
	for k,v in pairs(tempUnion) do
		table.insert(listData.unionList , v)
	end
	for k,v in pairs(finishTempUnion) do
		table.insert(listData.unionList , v)
	end
end

function RedPacketDispatchScene:refreshExtraDataToListData()
	for k,v in pairs(listData.unionList) do
		v.dispatchedNum = 0
		v.itemDescKey = self.itemDescKey
	end
	for k,v in pairs(listData.friendList) do
		v.dispatchedNum = 0
		v.itemDescKey = self.itemDescKey
	end
	self:sortData()

	self:refreshRedPacketNum()
end

function RedPacketDispatchScene:ctor()
  self.title = getTextByKey("redBag013")
  
end

function RedPacketDispatchScene:create( argv )
	-- body
	if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end

    listData = self.argv.params.listData
    
	local scene = RedPacketDispatchScene.new()
	scene.bonusId = self.argv.params.bonusId
    scene:initScene()
    
    return scene
end

function RedPacketDispatchScene:refreshTableView(selectID)
	self.selectID = selectID
	self:refreshExtraDataToListData()
	if self.tableView then
		self.tableView:removeFromParentAndCleanup(true)
		self.tableView = self:createTableView(selectID)
		self.tableView:reloadData()
		self.mainUI:addChild(self.tableView)
	end
end

function RedPacketDispatchScene:changeTableView( selectID )
	if self.selectID == selectID then
		return 
	end
	self.selectID = selectID
	if self.selectID == 1 then
		self.friendBtn.display:getChildByName("normal"):setVisible(true)
		self.unionBtn.display:getChildByName("normal"):setVisible(false)
	elseif self.selectID == 2 then
		self.friendBtn.display:getChildByName("normal"):setVisible(false)
		self.unionBtn.display:getChildByName("normal"):setVisible(true)
	end
	self:refreshExtraDataToListData()
	if self.tableView then
		local function onDisappearFinish()
			self.tableView:removeFromParentAndCleanup(true)
			self.tableView = self:createTableView(selectID)
			self.tableView:reloadData()
			self.mainUI:addChild(self.tableView)
			ViewControlUtil.showTableViewAction(self.tableView, visibleSize)
		end
		ViewControlUtil.disappearTableViewAction(self.tableView, visibleSize,onDisappearFinish)
		return
		-- self.tableView:removeFromParentAndCleanup(true)
	end
	self.tableView = self:createTableView(selectID)
	self.tableView:reloadData()
	self.mainUI:addChild(self.tableView)
end

function RedPacketDispatchScene:checkContinueSend( num )
	local propNum = 0
	local propId = self.bonusId
	local propsData = DataManager.getPropsData()
	for aKey, prop in pairs(propsData) do
	    if (prop.metaId == propId) then
			propNum = prop.amount
	    end
	end
	local dispatchedNum = self:getUsedPropNum()

	if dispatchedNum + num > propNum then
		return false
	end
	return true
end

function RedPacketDispatchScene:getUsedPropNum()
	local dispatchedNum = 0
	for k,v in pairs(listData.friendList) do
		if v.dispatchedNum then
			dispatchedNum = v.dispatchedNum + dispatchedNum
		end
	end

	for k,v in pairs(listData.unionList) do
		if v.dispatchedNum then
			dispatchedNum = v.dispatchedNum + dispatchedNum
		end
	end
	return dispatchedNum
end

function RedPacketDispatchScene:refreshRedPacketNum()
	local propNum = 0
	local propId = self.bonusId
	local propsData = DataManager.getPropsData()
	for aKey, prop in pairs(propsData) do
	    if (prop.metaId == propId) then
			propNum = prop.amount
	    end
	end

	local dispatchedNum = self:getUsedPropNum()

	self.mainUI:getChildByName("txt_2"):getChildByName("txt"):setString(dispatchedNum..'/'..propNum)
end

function RedPacketDispatchScene:refreshUI(onlyRefresh)
	if (#listData.unionList + #listData.friendList) == 0 then
		self:back()
	end
	if onlyRefresh then
		if self.selectID == 1 and #listData.friendList ~= 0 then
			self:refreshTableView(self.selectID)
		elseif self.selectID == 2 and #listData.unionList ~= 0 then
			self:refreshTableView(self.selectID)
		else
			if #listData.friendList == 0 then
				self:refreshTableView(2)
			else
				self:refreshTableView(1)
			end
		end
	else
		if #listData.friendList == 0 then
			self:changeTableView(2)
		else
			self:changeTableView(1)
		end

	end
	
	-- if #listData.friendList == 0 then
	-- 	self.friendBtn:setEnable(false)
	-- 	-- self.friendBtn.display:getChildByName("normal"):setVisible(false)
	-- elseif #listData.unionList == 0 then
	-- 	self.unionBtn:setEnable(false)
	-- 	-- self.unionBtn.display:getChildByName("normal"):setVisible(false)
	-- end

	self:refreshRedPacketNum()
end


function RedPacketDispatchScene:onInit()
	-- body
	BaseUIScene.initBackGround(self)
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity_02.json")
	self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("launch_activity_share_gift")
	self:addChild(self.mainUI)
	BaseUIScene.onInit(self)

	self.itemDescKey = 0
    for k,v in pairs(DataManager.GameMetaData.redBagConfig.redBagList) do
  		if v.redBagId == self.bonusId then
  			self.itemDescKey = v.itemDescKey
  			break
  		end
  	end
  	self:refreshExtraDataToListData()

	self.mainUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("redBag004"))
	self.mainUI:getChildByName("share_gift_title"):getChildByName("btn_across_fight_event_game"):getChildByName("txt"):setString(getTextByKey("home_friendBtn"))
	self.mainUI:getChildByName("share_gift_title"):getChildByName("btn_across_fight_event_game"):getChildByName("friend_tips_friend_RequestSentTag"):setVisible(false)
	self.mainUI:getChildByName("share_gift_title"):getChildByName("btn_across_fight_formt_game"):getChildByName("friend_tips_friend_RequestSentTag"):setVisible(false)
	self.mainUI:getChildByName("share_gift_title"):getChildByName("btn_across_fight_formt_game"):getChildByName("txt"):setString(getTextByKey("union_members_label_name"))
	self.mainUI:getChildByName("btn_distribution_confirm"):getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("redBag012"))

	local function onClickFriendBtn( evt )
		if #listData.friendList == 0 then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("redBag016"))
			return
		end
		self:changeTableView(1)
	end

	self.friendBtn = Button:create(self.mainUI:getChildByName("share_gift_title"):getChildByName("btn_across_fight_event_game"))
    self.friendBtn:addEventListener(Events.kStart, onClickFriendBtn )

    local function onClickUnionBtn( evt )
    	if #listData.unionList == 0 then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("redBag017"))
			return
		end
    	self:changeTableView(2)
    end

    self.unionBtn = Button:create(self.mainUI:getChildByName("share_gift_title"):getChildByName("btn_across_fight_formt_game"))
    self.unionBtn:addEventListener(Events.kStart, onClickUnionBtn )

    local function onSend(evt)
    	local params = {}
    	params.accepterType = self.selectID - 1
    	params.bonusId = self.bonusId
    	params.accepterList = {}
    	local accepterList = {}
    	if self.selectID == 1 then
    		accepterList = listData.friendList
		elseif self.selectID == 2 then
			accepterList = listData.unionList
    	end
    	for k,v in pairs(accepterList) do
    		if v.dispatchedNum and v.dispatchedNum ~= 0 then
    			local temp = {
    			uid = v.uid,
    			amount = v.dispatchedNum
    		}
    			table.insert(params.accepterList , temp)
    		end
    	end

    	if #params.accepterList == 0 then
    		SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("redBag018"))
    		return
    	end

    	print(table.tostring(params))

    	local function succeedCallback( e )
    		local accepterList = e.data.accepterList
    		local amount = e.data.usedNum
    		RewardManager:getReward({{itemType = ResourceEnum.PROP, metaId = self.bonusId, amount = -amount}})
    		if #accepterList ~= 0 then
    			local targetInfoPanel = RedPacketAccpterListPanel:create(self , {accepterList = accepterList})
	    		PopoutManager:sharedManager():popout(targetInfoPanel, kPopoutDir.kScale, true, false, self)
	    	else
	    		SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("redBag019"))
    		-- else
    		-- 	local num = 0
    		-- 	for k,v in pairs(accepterList) do
    		-- 		if v.acceptErrorcode == 5 then
    		-- 			accepterList[k].extendData = string.split(v.extend , "|")
    		-- 			num = num + accepterList[k].extendData[1] - accepterList[k].extendData[2]
    		-- 		end
    		-- 	end
    		-- 	RewardManager:getReward({{itemType = ResourceEnum.PROP, metaId = self.bonusId, amount = -amount - num}})
    		end
    		print(table.tostring(e.data))

	    	local function succeedCallback(e)
	    		listData = e.data
	    		-- self:refreshExtraDataToListData()
	    		self:refreshUI(true)
				-- local s = RedPacketDispatchScene:create(params)
				-- Director:mgr():run():replaceScene(RedPacketDispatchScene, {enterScene="BackpackSceneItem",returnScene="BackpackSceneItem", params = params})
			end
			local function failedCallback(e)
				
			end
			GetBonusAccepterListRequest.sendRequest({bonusId = self.bonusId} , succeedCallback, failedCallback)
    	end

    	local function failedCallback( e )
    		local errorCode = tonumber(e.data)
            if errorCode == 710618 then
                self:back()
            end
    	end

    	DistributeBonusRequest.sendRequest(params , succeedCallback, failedCallback)
    end
    local onSendBtn = Button:create(self.mainUI:getChildByName("btn_distribution_confirm"))
    onSendBtn:addEventListener(Events.kStart, onSend )

    self:refreshUI()

end


local TABLEVIEW_CELL_TAG = -1001
local TAG_ICON_ITEM = 1002
local TAG_TXT_MEMNAME = 1003
local TAG_TXT_LV = 1004
local TAG_TXT_CONTINUE_LOGIN = 1005
local TAG_TXT_CONTINUE_LOGIN_TIME = 1006
local TAG_TXT_UNION_NAME = 1007
local TAG_TXT_CONTRIBUTION = 1008
local TAG_TXT_CONTRIBUTION_NUM = 1009
local TAG_TXT_DISPATCHNUM = 1010
local TAG_TXT_STRENGTH = 1011
local TAG_ICON_FRIEND = 1012
local TAG_ICON_1ST = 1014
local TAG_ICON_2RD = 1015
local TAG_ICON_ELITE = 1016
local TAG_ICON_MEM = 1017
local TAG_ICON_GOODICON = 1018
local TAG_TXT_CONTINUE_LOGIN2 = 1019


function RedPacketDispatchScene:createTableView(enterType)
	local RedPacketDispatchSceneRenderer = class(TableViewRenderer)
	function RedPacketDispatchSceneRenderer:ctor(width, height)
	    -- body

		if enterType == 1 then
			self.list = listData.friendList
		elseif enterType == 2 then
			self.list = listData.unionList
		end
	    -- self.list = listData
	    local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity_02.json")
	    builder.useArtLabelTTF = true
	    self.builder = builder
	end
	function RedPacketDispatchSceneRenderer:buildCell(container)
	    local cell = self.builder:build("list/activity_hongbao_list")
	    cell:setPosition(ccp(0, 0))   
	    cell:setTag(TABLEVIEW_CELL_TAG)
	    container:addChild(cell)

	    cell:getChildByName("txt_guild_member_name"):setTag(TAG_TXT_MEMNAME)
	    cell:getChildByName("txt_guild_member_name"):getChildByName("txt"):setTag(TAG_TXT_MEMNAME)
	    cell:getChildByName("txt_guild_14"):setTag(TAG_TXT_LV)
	    cell:getChildByName("txt_guild_14"):getChildByName("txt"):setTag(TAG_TXT_LV)
	    cell:getChildByName("txt_2"):setTag(TAG_TXT_CONTINUE_LOGIN)
	    cell:getChildByName("txt_2"):getChildByName("txt"):setTag(TAG_TXT_CONTINUE_LOGIN)
	    cell:getChildByName("txt_6"):setTag(TAG_TXT_CONTINUE_LOGIN2)
	    cell:getChildByName("txt_6"):getChildByName("txt"):setTag(TAG_TXT_CONTINUE_LOGIN2)
	    cell:getChildByName("txt_4"):setTag(TAG_TXT_CONTINUE_LOGIN_TIME)
	    cell:getChildByName("txt_4"):getChildByName("txt"):setTag(TAG_TXT_CONTINUE_LOGIN_TIME)
	    cell:getChildByName("txt_5"):setTag(TAG_TXT_UNION_NAME)
	    cell:getChildByName("txt_5"):getChildByName("txt"):setTag(TAG_TXT_UNION_NAME)
	    cell:getChildByName("txt_guild_70"):setTag(TAG_TXT_CONTRIBUTION)
	    cell:getChildByName("txt_guild_70"):getChildByName("txt"):setTag(TAG_TXT_CONTRIBUTION)
	    cell:getChildByName("txt_guild_16_2"):setTag(TAG_TXT_CONTRIBUTION_NUM)
	    cell:getChildByName("txt_guild_16_2"):getChildByName("txt"):setTag(TAG_TXT_CONTRIBUTION_NUM)
	    cell:getChildByName("txt_other_upgrade3"):setTag(TAG_TXT_DISPATCHNUM)
	    cell:getChildByName("txt_other_upgrade3"):getChildByName("txt"):setTag(TAG_TXT_DISPATCHNUM)
	    cell:getChildByName("txt_1"):setTag(TAG_TXT_STRENGTH)
	    cell:getChildByName("txt_1"):getChildByName("txt"):setTag(TAG_TXT_STRENGTH)

	    cell:getChildByName("normal_card_small"):setTag(TAG_ICON_GOODICON)
	    cell:getChildByName("normal_card_small"):setVisible(false)

	    cell:getChildByName("lbl_rend_envelope_01"):setTag(TAG_ICON_FRIEND)
	    cell:getChildByName("lbl_mem"):setTag(TAG_ICON_MEM)
	    cell:getChildByName("lbl_1st"):setTag(TAG_ICON_1ST)
	    cell:getChildByName("lbl_2rd"):setTag(TAG_ICON_2RD)
	    cell:getChildByName("lbl_elite"):setTag(TAG_ICON_ELITE)

	    for i=1,4 do
	    	cell:getChildByName("btn_other_upgrade"..i):setTag(2000 + i)
	    	cell:getChildByName("btn_other_upgrade"..i):getChildByName("txt"):setTag(2000 + i)
	    	cell:getChildByName("btn_other_upgrade"..i):getChildByName("normal"):setTag(2010 + i)
	    	cell:getChildByName("btn_other_upgrade"..i):getChildByName("disabled"):setTag(2020 + i)
	    end

	    if enterType == 1 then
	    	cell:getChildByName("lbl_rend_envelope_01"):setVisible(true)
		    cell:getChildByName("lbl_mem"):setVisible(false)
		    cell:getChildByName("lbl_1st"):setVisible(false)
		    cell:getChildByName("lbl_2rd"):setVisible(false)
		    cell:getChildByName("lbl_elite"):setVisible(false)
    	elseif enterType == 2 then
			cell:getChildByName("lbl_rend_envelope_01"):setVisible(false)
		    cell:getChildByName("lbl_mem"):setVisible(true)
		    cell:getChildByName("lbl_1st"):setVisible(true)
		    cell:getChildByName("lbl_2rd"):setVisible(true)
		    cell:getChildByName("lbl_elite"):setVisible(true)
    	end
	    
    end
    local function setTextByTag( cell, tag, str)
	    local txt = cell:getChildByTag(tag):getChildByTag(tag)
	    setNodeText(txt, str);
	end

	local function setNodeVisibleByTag(cell, tag, visible)
	    cell:getChildByTag(tag):setVisible(visible)
	end

	local parent = self

	function RedPacketDispatchSceneRenderer:setData(rawCocosObj,index)
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)
		local itemData = self.list[index + 1]

		local tempTable = {"-1" , "-10" , "+1" , "+10"}
		for i=1,4 do
			setTextByTag(cell , 2000+i , tempTable[i])
		end

		for i=1,2 do
			if itemData.dispatchedNum == 0 or itemData.dispatchedNum + tonumber(tempTable[i]) < 0 then
				cell:getChildByTag(2000+i):getChildByTag(2010 + i):setVisible(false)
				cell:getChildByTag(2000+i):getChildByTag(2020 + i):setVisible(true)
				cell:getChildByTag(2000+i).ignoreTouch = true
			else
				cell:getChildByTag(2000+i):getChildByTag(2010 + i):setVisible(true)
				cell:getChildByTag(2000+i):getChildByTag(2020 + i):setVisible(false)
				cell:getChildByTag(2000+i).ignoreTouch = false
			end
		end

		for i=3,4 do
			if itemData.dispatchedNum + tonumber(tempTable[i]) > itemData.itemDescKey - itemData.acceptNum or not parent:checkContinueSend(tonumber(tempTable[i])) then
				cell:getChildByTag(2000+i):getChildByTag(2010 + i):setVisible(false)
				cell:getChildByTag(2000+i):getChildByTag(2020 + i):setVisible(true)
				cell:getChildByTag(2000+i).ignoreTouch = true
			else
				cell:getChildByTag(2000+i):getChildByTag(2010 + i):setVisible(true)
				cell:getChildByTag(2000+i):getChildByTag(2020 + i):setVisible(false)
				cell:getChildByTag(2000+i).ignoreTouch = false
			end
		end

		setTextByTag(cell , TAG_TXT_MEMNAME , itemData.nickName)
		setTextByTag(cell , TAG_TXT_LV , itemData.level)
		setTextByTag(cell , TAG_TXT_STRENGTH , itemData.fightCapacity)

		local aCardDisplay = cell:getChildByTag(TAG_ICON_GOODICON)
		local zOrder = cell:getChildByTag(TAG_ICON_GOODICON):getZOrder()

		local oldIcon = cell:getChildByTag(TAG_ICON_ITEM)
		if oldIcon then
			oldIcon:removeFromParentAndCleanup(true)
		end
		local params = {}
		params.sourceDisplay = aCardDisplay
		params.showInCenter = true
		local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, itemData.mainCardMetaId, 1, params)
		cell:addChild(icon.refCocosObj, zOrder)
		if icon then
			icon:setTag(TAG_ICON_ITEM)
			icon:dispose()
		end

		setTextByTag(cell , TAG_TXT_DISPATCHNUM , itemData.dispatchedNum .. '/' .. itemData.itemDescKey - itemData.acceptNum)

		if enterType == 1 then
			if itemData.unionName then
				setNodeVisibleByTag(cell , TAG_TXT_UNION_NAME , true)
				setTextByTag(cell , TAG_TXT_UNION_NAME , itemData.unionName)
			else
				setNodeVisibleByTag(cell , TAG_TXT_UNION_NAME , false)
			end
			

			--显示离线时间
		    local txtFriendLeave = cell:getChildByTag(TAG_TXT_CONTINUE_LOGIN2)
		    local txtFriendLeaveValue = txtFriendLeave:getChildByTag(TAG_TXT_CONTINUE_LOGIN2)
		    local offLineSec = 0
		    if not itemData.online then
		      --当前不在线才有偏差时间
		      offLineSec = TimeUtil.getServerTimeSeconds() - itemData.lastestOfflineSeconds
		    end
		    local hours = TimeUtil.getHoursBySec(offLineSec)
		    if hours <= 0 then
		      --不到1小时
		      txtFriendLeave:setVisible(false)
		    else
		      --超过1小时
		      txtFriendLeave:setVisible(true)
		      local days = TimeUtil.getPasseddDaysToNow(itemData.lastestOfflineSeconds)
		      if days <= 0 then
		        --不到1天
		        setNodeText(txtFriendLeaveValue, Localization:getInstance():getText("union_player_login_remind3", {num = hours}))--{num}小时未登陆
		      else
		        --超过1天
		        if days <= 7 then
		          --不到7天
		          setNodeText(txtFriendLeaveValue, Localization:getInstance():getText("union_player_login_remind2", {num = days}))--{num}天未登陆
		        else
		          --超过7天
		          setNodeText(txtFriendLeaveValue, Localization:getInstance():getText("union_player_login_remind1"))--7天以上未登陆
		        end
		      end
		    end

		else
			for i=1,4 do
				if i == itemData.title then
					setNodeVisibleByTag(cell , 1013 + i , true)
				else
					setNodeVisibleByTag(cell , 1013 + i , false)
				end
			end
			setTextByTag(cell , TAG_TXT_CONTINUE_LOGIN , getTextByKey("redBag005"))
			setTextByTag(cell , TAG_TXT_CONTINUE_LOGIN_TIME , itemData.lastestConstructDays .. getTextByKey("activity_consume_text2"))
			setTextByTag(cell , TAG_TXT_UNION_NAME , getTextByKey("union_player_contribute_all_text"))
			setTextByTag(cell , TAG_TXT_CONTRIBUTION_NUM , itemData.hisContribute)

		end


	end

	local function inArea(posX, posY, rect)
    	if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
    		return true
    	end
    	return false
	end
	local function onTouch( data , num )
		if data.dispatchedNum + num < 0 then
			return
		end
		if data.dispatchedNum + num > data.itemDescKey - data.acceptNum or not self:checkContinueSend(num) then
			return
		end

		data.dispatchedNum = data.dispatchedNum + num
		self:refreshRedPacketNum()
		local offset = self.tableView:getContentOffset()
		self.tableView:reloadData()
		self.tableView:setContentOffset(offset)
	end
	local function onListItemTouch( evt ) 
	    local aIndex = evt.data + 1
		local newCell = self.tableView:cellAtIndex(aIndex - 1)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData
		if enterType == 1 then
			aData = listData.friendList[aIndex]
		elseif enterType == 2 then
			aData = listData.unionList[aIndex]
		end
		-- local aData = listData[aIndex]

		local buttonDisplay
		local exchangeDisplay

		buttonDisplay = newCell:getChildByTag(TABLEVIEW_CELL_TAG):getChildByTag(2001)
		exchangeDisplay = buttonDisplay:getChildByTag(2011)
		if posInCell.x > buttonDisplay:getPositionX() and
		posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < buttonDisplay:getPositionY() then
			--点击按钮
			--print("-1")
			--判断能否增加
			onTouch(aData , -1)
		end

		buttonDisplay = newCell:getChildByTag(TABLEVIEW_CELL_TAG):getChildByTag(2002)
		exchangeDisplay = buttonDisplay:getChildByTag(2012)
		if posInCell.x > buttonDisplay:getPositionX() and
		posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < buttonDisplay:getPositionY() then
			--点击按钮
			--print("-10")
			--判断能否增加
			onTouch(aData , -10)
		end

		buttonDisplay = newCell:getChildByTag(TABLEVIEW_CELL_TAG):getChildByTag(2003)
		exchangeDisplay = buttonDisplay:getChildByTag(2013)
		if posInCell.x > buttonDisplay:getPositionX() and
		posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < buttonDisplay:getPositionY() then
			--点击按钮
			--print("+1")
			--判断能否减少
			onTouch(aData , 1)
		end

		buttonDisplay = newCell:getChildByTag(TABLEVIEW_CELL_TAG):getChildByTag(2004)
		exchangeDisplay = buttonDisplay:getChildByTag(2014)
		if posInCell.x > buttonDisplay:getPositionX() and
		posInCell.x < (buttonDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (buttonDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < buttonDisplay:getPositionY() then
			--点击按钮
			--print("+10")
			--判断能否减少
			onTouch(aData , 10)
		end
	end

	local cell_height = 200
	local list_height = 585.85
	local list_posY = 784

	self.mainUI:getChildByName("table_hongbao_list"):setVisible(false)
	local tableViewSizes = getTableViewSizes(self.mainUI:getChildByName("table_hongbao_list"))

	print(table.tostring(tableViewSizes))

	local renderer = RedPacketDispatchSceneRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)
	local tableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, TABLEVIEW_CELL_TAG, {2001,2002,2003,2004}, CCScale9Sprite:create(CCRectMake(0,0,0,0), "pic/scroll.png"), CCScale9Sprite:create(CCRectMake(0,0,0,0), "pic/scroll.png"))

	tableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
	tableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
	return tableView

end

function RedPacketDispatchScene:setTableViewsEnabledInner(v)
  if self.tableView then
    self.tableView:setTouchEnabled(v)
  end
end

function RedPacketDispatchScene:dispose()
	BaseUIScene.dispose(self)
end

function RedPacketDispatchScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function RedPacketDispatchScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function RedPacketDispatchScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    print("enterActionFinished 1! os.clock() = " .. os.clock())
    self:nodeAnimationFinished()
  end

  	self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.mainUI:runAction(CCSequence:create(arr))

	ViewControlUtil.showTableViewAction(self.tableView, visibleSize)
end

function RedPacketDispatchScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function RedPacketDispatchScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function RedPacketDispatchScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function RedPacketDispatchScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
      self:nodeAnimationFinished()
  end

  local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.mainUI:runAction(CCSequence:create(arr))
  
  if self.tableView then
    ViewControlUtil.disappearTableViewAction(self.tableView, visibleSize)
  end
  
	
end

function RedPacketDispatchScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function RedPacketDispatchScene:back()
	self.ignoreAction = false
	self:replaceScene(BackpackScene, {params = {tabIndex = BAGCATEGORY.item}})
end
