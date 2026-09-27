require "canon.customUI.CanonGoodIcon"
require "canon.data.DataManager"
require "canon.data.MetaManager"
require "canon.scene.EmailScene"
require "canon.utils.StringUtil"
require "canon.utils.ViewControlUtil"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.PopoutManager"
require "hecore.ui.TableView"

--
--CrossBossRankInfoPanel
--

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

CrossBossRankInfoPanel = class(Layer)

function CrossBossRankInfoPanel:ctor()
end

function CrossBossRankInfoPanel:create(container, params)
	local panel = CrossBossRankInfoPanel.new()
	panel.container = container
	panel.uiBuilder = LayoutBuilder:createWithContentsOfFile("scene/Siren.json")
	panel.params = params
	panel:initLayer()
	return panel
end

function CrossBossRankInfoPanel:initLayer()
	CrossBossRankInfoPanel.super.initLayer(self)

	self.mainUI = self.uiBuilder:build("popup_Siren_06")
	self:addChild(self.mainUI)
	self.mainUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("crossBoss_scoreRankTitle"))
	self.mainUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("crossBoss_scoreRankExplain_1" , {num1 = CrossWorldBossManager.getCrossBossSettingConfig().rankingListNum}))
	self.mainUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("crossBoss_scoreRankExplain_2"))

	local picClose = self.mainUI:getChildByName("login_btn_close")
	local btnClose = Button:create(picClose)
	local function onCloseClick()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	end
	btnClose:addEventListener(Events.kStart, onCloseClick)
  
	local ranks = self.params.ranks or {}
  local aPanel = self

	PKRewardListRender = class(TableViewRenderer)
	function PKRewardListRender:ctor()
		self.list = ranks or {}
	end
	function PKRewardListRender:buildCell(container)
		local rewardItem = aPanel.uiBuilder:build("list/Siren_integral_list")
		-- rewardItem:getChildByName("normal_card_small"):setAnchorPoint(ccp(0.5, 0.5))
		rewardItem:getChildByName("normal_card_small"):setTag(100)
		rewardItem:getChildByName("txt_1"):setTag(101)
		rewardItem:getChildByName("txt_1"):getChildByName("txt"):setTag(101)
		rewardItem:getChildByName("txt_2"):setTag(102)
		rewardItem:getChildByName("txt_2"):getChildByName("txt"):setTag(102)
		rewardItem:getChildByName("txt_3"):setTag(103)
		rewardItem:getChildByName("txt_3"):getChildByName("txt"):setTag(103)
		rewardItem:getChildByName("txt_4"):setTag(104)
		rewardItem:getChildByName("txt_4"):getChildByName("txt"):setTag(104)
		rewardItem:getChildByName("txt_6"):setTag(105)
		rewardItem:getChildByName("txt_6"):getChildByName("txt"):setTag(105)
		rewardItem:getChildByName("txt_5"):getChildByName("txt"):setString(getTextByKey("crossBoss_score"))

		rewardItem:getChildByName("lbl_1st"):setTag(200)
		rewardItem:getChildByName("lbl_2nd"):setTag(201)
		rewardItem:getChildByName("lbl_3rd"):setTag(202)
		rewardItem:getChildByName("txt_Siren_45"):setTag(203)
		rewardItem:getChildByName("txt_Siren_45"):getChildByName("txt"):setTag(203)

		rewardItem:getChildByName("btn_toView"):setTag(106)
		rewardItem:getChildByName("btn_toView"):getChildByName("txt"):setTag(106)
		rewardItem:setTag(111)
		container:addChild(rewardItem)
	end

	local function setTextByTag( cell, tag, str)
	    local txt = cell:getChildByTag(tag):getChildByTag(tag)
	    setNodeText(txt, str);
	  end

	  local function setNodeVisibleByTag(cell, tag, visible)
	    cell:getChildByTag(tag):setVisible(visible)
	  end

	function PKRewardListRender:setData(rawCocosObj, index)
		local cell = self:getChildByTag(rawCocosObj, 111)
		index = index + 1
		local serverId = self.list[index].serverId
		local nickName = self.list[index].nickName
		local level = self.list[index].level
		local unionName = self.list[index].unionName or ""
		local score = self.list[index].score
		-- local metaId = self.list[index].metaId
		local uid = self.list[index].uid
		local metaId = CommonManager:getSelfAvatarMetaByUid( uid )
		if metaId == nil then
			metaId = self.list[index].metaId
		end

		if index == 1 then
			setNodeVisibleByTag(cell , 200,  true)
			setNodeVisibleByTag(cell , 201,  false)
			setNodeVisibleByTag(cell , 202,  false)
			setNodeVisibleByTag(cell , 203,  false)
		elseif index == 2 then
			setNodeVisibleByTag(cell , 200,  false)
			setNodeVisibleByTag(cell , 201,  true)
			setNodeVisibleByTag(cell , 202,  false)
			setNodeVisibleByTag(cell , 203,  false)
		elseif index == 3 then
			setNodeVisibleByTag(cell , 200,  false)
			setNodeVisibleByTag(cell , 201,  false)
			setNodeVisibleByTag(cell , 202,  true)
			setNodeVisibleByTag(cell , 203,  false)
		else	
			setNodeVisibleByTag(cell , 200,  false)
			setNodeVisibleByTag(cell , 201,  false)
			setNodeVisibleByTag(cell , 202,  false)
			setNodeVisibleByTag(cell , 203,  true)
			setTextByTag(cell , 203 , getTextByKey("activity_rankTxt" , {num = index}))
		end

		setTextByTag(cell , 101 , serverId..getTextByKey("crossBoss_serverSuffix"))
		setTextByTag(cell , 102 , nickName)
		setTextByTag(cell , 103 , level)
		if unionName == "" then
			setTextByTag(cell , 104 , "")
		else
			setTextByTag(cell , 104 , "["..unionName.."]")
		end
		
		setTextByTag(cell , 105 , score)
		setTextByTag(cell , 106 , getTextByKey("crossBoss_viewTeam"))
		setNodeVisibleByTag(cell , 100 , false)

		local myUid = DataManager.getCurrUser().uid 
		if myUid == uid then
			setNodeVisibleByTag(cell , 106 , false)
		else
			setNodeVisibleByTag(cell , 106 , true)
		end

		local itemNode = cell:getChildByTag(-100)
		if itemNode then
			itemNode:removeFromParentAndCleanup(true)
			itemNode = nil
		end

		local params = {}
		params.sourceDisplay = cell:getChildByTag(100)
		params.showInCenter = true
		local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, metaId, 1, params)
		cell:addChild(icon.refCocosObj , cell:getChildByTag(100):getZOrder())
		if icon then
			icon:setTag(-100)
			icon:dispose()
		end
		
	end
	local function inArea(posX, posY, rect)
	    if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
	      return true
	    end
	    return false
	  end 

	local function onListItemTouch( evt ) 
	    local selectedCell = self.listView:cellAtIndex(evt.data):getChildByTag(111)
	    local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
	    local itemPosX, itemPosY = selectedCell:getChildByTag(106):getPosition()
	    local itemRect = {}
	    itemRect.x = itemPosX
	    itemRect.y = itemPosY - 58
	    itemRect.width = 151
	    itemRect.height = 58
	    if inArea(posInCell.x, posInCell.y, itemRect) and selectedCell:getChildByTag(106):isVisible() then
	    	local function onFormation()
			    params = {
			      playerUid = ranks[evt.data + 1].uid,
			    }
			    local function onGetPlayerTeamInfoCallback( e )
			      local argv = {
			      enterScene = SceneEnum.ActivitySceneToCrossBoss,
			      returnScene = SceneEnum.ActivitySceneToCrossBoss,
			      params = {
			          playerUid = ranks[evt.data + 1].uid,
			          playerTeamData = e.data,
			        },
			      }
			      -- self:closePanel()
			      Director:sharedDirector():replaceScene(CardQueueScene:create(argv))
			      -- self.container:replaceScene( CardQueueScene, argv )
			    end
				
			    local getPlayerTeamInfoRequest = GetPlayerTeamInfoRequest.new(params, rpc.SendingPriority.kHigh)
			    getPlayerTeamInfoRequest:addEventListener(RequestNotifyEnum.GetPlayerTeamInfoSucceed, onGetPlayerTeamInfoCallback)
			    getPlayerTeamInfoRequest:start()
			end
			onFormation()
		end
	end
	self.mainUI:getChildByName("tableview"):setVisible(false)
	local tableViewSizes = getTableViewSizes(self.mainUI:getChildByName("tableview"))
	local render = PKRewardListRender.new(tableViewSizes.item_width, tableViewSizes.item_height)
	render.container = self
	self.listView = TableView:create(render, tableViewSizes.table_width, tableViewSizes.table_height, 111, 106, CCScale9Sprite:create(CCRectMake(0,0,0,0), "pic/scroll.png"), CCScale9Sprite:create(CCRectMake(0,0,0,0), "pic/scroll.png"))
	self.listView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
	self.mainUI:addChild(self.listView)
	self.listView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
	self.listView:reloadData()
end