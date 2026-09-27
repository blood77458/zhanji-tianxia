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
--RankRewardReviewPanel
--

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

RankRewardReviewPanel = class(Layer)

function RankRewardReviewPanel:ctor()
end

function RankRewardReviewPanel:create(container, params)
	local panel = RankRewardReviewPanel.new()
	panel.container = container
	panel.uiBuilder = LayoutBuilder:createWithContentsOfFile("scene/pk.json")
	panel.params = params
	panel:initLayer()
	return panel
end

function RankRewardReviewPanel:initLayer()
	RankRewardReviewPanel.super.initLayer(self)

	self.mainUI = self.uiBuilder:build("popup_reward_tab")
	self:addChild(self.mainUI)
	self.mainUI:getChildByName("txt_activity_info1"):getChildByName("txt"):setString(self.params.title or getTextByKey("pk_reward_title"))
	self.mainUI:getChildByName("txt_pk16"):setVisible(false)
	self.mainUI:getChildByName("txt_pk17"):setVisible(false)
	local txt = self.mainUI:getChildByName("txt_pk18")
	txt:setPositionX(32)
	txt:getChildByName("txt"):setString(self.params.subTitle)
	txt:getChildByName("txt"):setDimensions(CCSizeMake(660,30))

	local picClose = self.mainUI:getChildByName("btn_close")
	local btnClose = Button:create(picClose)
	local function onCloseClick()
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
	end
	btnClose:addEventListener(Events.kStart, onCloseClick)
  
	local rewardList = self.params.rewardList or {}
  local aPanel = self

	PKRewardListRender = class(TableViewRenderer)
	function PKRewardListRender:ctor()
		self.list = rewardList or {}
	end
	function PKRewardListRender:buildCell(container)
		local rewardItem = aPanel.uiBuilder:build("list_reward_tab")
		rewardItem:getChildByName("reward_item"):getChildByName("normal_card_small"):setAnchorPoint(ccp(0.5, 0.5))
		local tagTree = {txt_reward_rank = {101, txt=201}, reward_item = {102, txt_item_name={201, txt_item_name=301}, normal_card_small = 202}}
		setCCNodeTagTree(rewardItem, tagTree)
		rewardItem:setTag(111)
		container:addChild(rewardItem)
	end
	function PKRewardListRender:setData(rawCocosObj, index)
		local rewardItem = self:getChildByTag(rawCocosObj, 111)
		index = index + 1
		local itemNode = rewardItem:getChildByTag(120)
		if itemNode then
			itemNode:removeFromParentAndCleanup(true)
			itemNode = nil
		end
		local firstItem = rewardItem:getChildByTag(102)
		firstItem:setPositionX(90)
		firstItem:setVisible(false)
    local rankTxt = rewardItem:getChildByTag(101):getChildByTag(201)
    setNodeText(rankTxt, self.list[index].rankText)
    local rewardList = MetaManager.getRewardInfoByID(self.list[index].rewardPackage) or {}
    firstItem:setVisible(#rewardList > 0)
    local itemX = firstItem:getPositionX()
    local itemY = firstItem:getPositionY()
    for i,v in ipairs(rewardList) do
      local iconFrame = nil
      local itemContainer = nil
      local itemName = CanonGoodIcon.getGoodNameByPackageRewardInfo(v)
      if i > 1 then
        if itemNode == nil then
          itemNode = CCNode:create()
          itemNode:setTag(120)
          rewardItem:addChild(itemNode, 8)
        end
        itemContainer = aPanel.uiBuilder:build("sb/reward_item")
        iconFrame = itemContainer:getChildByName("normal_card_small")
        iconFrame:setAnchorPoint(ccp(0.5, 0.5))
        itemContainer:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setString(itemName)
        itemContainer:setPositionX(itemX + (i - 1) * 155)
        itemContainer:setPositionY(itemY)
        itemNode:addChild(itemContainer.refCocosObj)
      else
        itemContainer = firstItem
        iconFrame = firstItem:getChildByTag(202)
        setNodeText(firstItem:getChildByTag(201):getChildByTag(301), itemName)
      end
      CanonGoodIcon.createGoodIconByPackageRewardInfo(v, {sourceDisplay=iconFrame, container = itemContainer})
      iconFrame:setVisible(false)
    end
	end
	local render = PKRewardListRender.new(636, 181)
	render.container = self
	self.listView = TableView:create(render, 656, 670, 111, nil, CCScale9Sprite:create(CCRectMake(0,0,0,0), "pic/scroll.png"), CCScale9Sprite:create(CCRectMake(0,0,0,0), "pic/scroll.png"))
	self.listView:setPosition(ccp(38, 213))
	self.mainUI:addChild(self.listView)
	self.listView:reloadData()
end