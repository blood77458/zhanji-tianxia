--
-- LimitRewardPanel.lua
-- Author: meilam.xie
-- Date: 2015-01-27 15:32:32
-- 创建显示充值面板
--


local visibleSize = CCDirector:sharedDirector():getVisibleSize()


--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end
------------------------------------------------------------------------------------------------------

LimitRewardPanel = class(Layer)

function LimitRewardPanel:ctor()
	self.container = nil
	self.content = nil
end

function LimitRewardPanel:create(container)
	local s = LimitRewardPanel.new()
	self.container = container
	s:initLayer(container)
	return s
end

function LimitRewardPanel:initLayer(container)
	LimitRewardPanel.super.initLayer(self)
		--点击关闭
	local function onClose(evt)
		
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end

	local function ToLook(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		local  judgeVariable = Activity_rechargeLayer.JudgeDisplayAdvertising( )
		if judgeVariable > 0 then
			local para = evt.context
	        self.container:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_LimitReward"})
	    end
	end
	local builder = LayoutBuilder:createWithContentsOfFile("scene/limited_timeReward.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_limitedReward_1") 

	self:addChild(self.panelUI)
	
	self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("Limit-Reward001"))
	self.panelUI:getChildByName("activity_info_btn_close1"):getChildByName("txt"):setString(getTextByKey("shareFate_button2"))
	self.panelUI:getChildByName("activity_info_btn_close2"):getChildByName("txt"):setString(getTextByKey("Limit-Reward019"))

	local LimitRewardList = Activity_rechargeLayer.getLimitRewardList()
   --创建图标
	self:createIcon(LimitRewardList[1].reward,"normal_card_small_1")
	self:createIcon(LimitRewardList[2].reward,"normal_card_small_2")
	self:createIcon(LimitRewardList[3].reward,"normal_card_small_3")

    --关闭按钮
    local  CloseBtn = Button:create(self.panelUI:getChildByName("activity_info_btn_close1"))

    CloseBtn:addEventListener(Events.kStart, onClose, self)

    --去看看按钮 
    local  ToLookBtn = Button:create(self.panelUI:getChildByName("activity_info_btn_close2"))

    ToLookBtn:addEventListener(Events.kStart, ToLook, self)
    

end

--创建图标
function LimitRewardPanel:createIcon(reward,text)

  print("类型###########"..reward.itemType)

  local params = {}
  params.sourceDisplay = self.panelUI:getChildByName(text)
 
  params.container = self.panelUI
  
  params.showInCenter = true
  
  params.zindex = 10

  local newMeta = reward.metaId
  aCard = CanonGoodIcon.createGoodIcon(reward.itemType, newMeta, 0, params)
  
end

function LimitRewardPanel:dispose()
	LimitRewardPanel.super.dispose(self)
end

