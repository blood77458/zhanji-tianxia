--
-- CrossUnionRewardPreviewPanel.lua
-- Author: meilam.xie
-- Date: 2015-04-21 15:45:32
-- 创建GvG奖励预览
--


local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local RewardType = {
                      RankingReward = 2, --排名奖励
                      IntegralReward = 1 --积分奖励
                    }
local RankingRewardList = {}
local IntegralRewardList = {}

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end
------------------------------------------------------------------------------------------------------

CrossUnionRewardPreviewPanel = class(Layer)

function CrossUnionRewardPreviewPanel.clear()
  RankingRewardList = {}
  IntegralRewardList = {}
end
function CrossUnionRewardPreviewPanel:ctor()
	self.container = nil
	self.content = nil
end

function CrossUnionRewardPreviewPanel:create(container)
	local s = CrossUnionRewardPreviewPanel.new()
	self.container = container
	s:initLayer(container)
	return s
end

local function FilterReward(num)
  local RewardList = {}
  local TotalRewardList = CrossUnionPkConfig.getGVGRewardMetas()
  for i,v in ipairs(TotalRewardList) do
    if v.rewardCondition == num then
      table.insert(RewardList,v)
    end
  end
  return RewardList
end
function CrossUnionRewardPreviewPanel:setTableViewsEnabled(v)
  self.tableView:setTouchEnabled(v)
end

function CrossUnionRewardPreviewPanel:initLayer(container)
	CrossUnionRewardPreviewPanel.super.initLayer(self)
		--点击关闭
	local function onClose(evt)
		self:dismiss()
	end
    -- self.container:setTableViewsEnabled(false)
	self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)

	self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))

	local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_Gvg_01") 
  local table_temp_view = self.panelUI:getChildByName("table_Gvg_list2")
  table_temp_view:setVisible(false)
  self.table_meta_info = getTableViewSizes(table_temp_view)

	self.tempLayer:addChild(self.panelUI)
  --cross_list_reward
  self.panelUI:getChildByName("common_txt_playerInfo_title"):getChildByName("txt_playerInfo_title"):setString(getTextByKey("cross_list_reward"))
  local newList1 = FilterReward(RewardType.IntegralReward)
  for i=#newList1,1,-1 do
    table.insert(IntegralRewardList,newList1[i])
  end

  local newList2 = FilterReward(RewardType.RankingReward)
  for i=#newList2,1,-1 do
    table.insert(RankingRewardList,newList2[i])
  end
  -- IntegralRewardList = FilterReward(RewardType.IntegralReward)
  -- print("~~~~~~~~~~~~~~~~~~~~IntegralRewardList = "..tostringRich(IntegralRewardList))
  -- RankingRewardList = FilterReward(RewardType.RankingReward)
  -- IntegralRewardList = FilterReward(RewardType.IntegralReward)



  local function LeftBtnStaus(adjude)
    self.LeftUI:getChildByName("lbl_Gvg_04"):setVisible(adjude)
  end
  local function RightBtnStaus(adjude)
    self.RightUI:getChildByName("lbl_Gvg_03"):setVisible(adjude)
  end
  local function CreateNewTable(NewDateList)
    self.tableView:removeFromParentAndCleanup(true)
    self.tableView = nil
    self.dataList = NewDateList
    self.tableView = self:createTableView(self.dataList)
    self.panelUI:addChild(self.tableView)
  end
  local function onLeftBtnFun(evt)
    -- print("~~~~~~~~~~~~~~~~~~~~~跨服淘汰赛的按钮")
    self.dataList = RankingRewardList
    CreateNewTable(self.dataList)
    if not self.RightUI:getChildByName("btn_Gvg_inactive"):isVisible() then
      self.LeftUI:getChildByName("btn_Gvg_inactive"):setVisible(false)
      self.RightUI:getChildByName("btn_Gvg_inactive"):setVisible(true)
    end
    -- self.LeftBtn:setEnable(false)
    -- LeftBtnStaus(true)
    self:ResetText("WGVG-RewardTime1")
    -- if not self.rightAdjude then
    --   self.rightAdjude = true
    --   self.leftAdjude = false
    --   self.RightBtn:setEnable(true)
    --   RightBtnStaus(false)
    -- end
  end

  local function onRightBtnFun(evt)
    -- print("~~~~~~~~~~~~~~~~~~~~~本服小组赛的按钮")
    self.dataList = IntegralRewardList
    CreateNewTable(self.dataList)
    -- self.RightBtn:setEnable(false)
    -- RightBtnStaus(true)
    self:ResetText("WGVG-RewardTime2")
    if not self.LeftUI:getChildByName("btn_Gvg_inactive"):isVisible() then
      self.LeftUI:getChildByName("btn_Gvg_inactive"):setVisible(true)
      self.RightUI:getChildByName("btn_Gvg_inactive"):setVisible(false)
    end
    -- if not self.leftAdjude then
    --   self.leftAdjude = true
    --   self.rightAdjude = false
    --   self.LeftBtn:setEnable(true) 
    --   LeftBtnStaus(false)
    -- end
  end
  
    --关闭按钮
    -- --login_btn_close
    local  CloseBtn = Button:create(self.panelUI:getChildByName("login_btn_close"))

    CloseBtn:addEventListener(Events.kStart, onClose, self)
    
    self.LeftUI = self.panelUI:getChildByName("btn_Gvg_in_04")
    self.LeftBtn = Button:create(self.LeftUI)

    self.LeftBtn:addEventListener(Events.kStart, onLeftBtnFun, self)
    -- self.LeftBtn:setEnable(false)
    -- self.leftAdjude = false
    
    self.RightUI = self.panelUI:getChildByName("btn_Gvg_in_03")
    self.RightBtn = Button:create(self.RightUI)

    self.RightBtn:addEventListener(Events.kStart, onRightBtnFun, self)
    -- self.rightAdjude = true
    -- self.RightUI:getChildByName("lbl_Gvg_03"):setVisible(false)
   
    
    self.dataList = RankingRewardList--{1,2,3,4,5,6,7,8,9,10,11,12,13}
    
    self.LeftUI:getChildByName("btn_Gvg_inactive"):setVisible(false)
    self:ResetText("WGVG-RewardTime1")
    self.tableView = self:createTableView(self.dataList)
    UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
    self.panelUI:addChild(self.tableView)
    self.tempLayer:setScale(0.1)
    
end


function CrossUnionRewardPreviewPanel:createTableView(data)
  local cellTag = 1024

  local UnionBattleReportRenderer = class(TableViewRenderer)

    function UnionBattleReportRenderer:ctor(width, height, creater)
    self.list = data or {}
    self.creater = creater
  end

  function UnionBattleReportRenderer:buildCell(container)
      local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
      local aCell = builder:build("list/list_activity_question")
      container:addChild(aCell)
      aCell:setTag(cellTag)
      aCell:getChildByName("txt_reward_rank"):setTag(-10)
      aCell:getChildByName("txt_reward_rank"):getChildByName("txt"):setTag(-10)

      for i=1,4 do
        aCell:getChildByName("normal_card_small"..i):setTag(-20-i)

        aCell:getChildByName("normal_card_small"..i):getChildByName("txt"):setTag(-10)
        aCell:getChildByName("normal_card_small"..i):getChildByName("txt"):getChildByName("txt"):setTag(-10)

        aCell:getChildByName("normal_card_small"..i):getChildByName("normal_card_small"):setTag(-20)
        aCell:getChildByName("normal_card_small"..i):getChildByName("normal_card_small"):setVisible(false)
      end
  end

  function UnionBattleReportRenderer:setData(rawCocosObj, index)
    
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local data = self.list[index + 1]
        local TxtName = nil
        if data.detail1 == data.detail2 then

          if data.detail1 == 1 then
            TxtName = "WGVG_Name18"
          elseif data.detail1 == 2 then 
            TxtName = "WGVG_Name19"
          elseif data.detail1 == 3 then
            TxtName = "WGVG_Name20"
          elseif data.detail1 == 4 then
            TxtName = "WGVG_Name22"
          end 
            setNodeText(aCell:getChildByTag(-10):getChildByTag(-10), getTextByKey(TxtName))
        else
          if data.detail1 == 5 then
            TxtName = "WGVG_Name23"
          elseif data.detail1 == 9 then 
            TxtName = "WGVG_Name24"
          elseif data.detail1 == 0 then
            TxtName = "WGVG_Name28"
          elseif data.detail1 == 1200 then
            TxtName = "WGVG_Name27"
          elseif data.detail1 == 2000 then
            TxtName = "WGVG_Name26"
          elseif data.detail1 == 2400 then
            TxtName = "WGVG_Name25"
          end
            setNodeText(aCell:getChildByTag(-10):getChildByTag(-10), getTextByKey(TxtName))
        end
        
        -- print("~~~~~~~~~~~~~~~~~~~reward = "..tostringRich(data))
        -- for i=1,4 do
          
          -- local reward = MetaManager.getRewardInfoByID(propConfigs.id)
            aCell:getChildByTag(-20-1):removeChildByTag(-30, true)
            aCell:getChildByTag(-20-1):getChildByTag(-10):getChildByTag(-10):setVisible(false)
            -- print("~~~~~~~~~~~~~~~~~~~reward = "..tostringRich(reward))
            
            -- if reward then
              
                local itemIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.PROP, data.rewardPropId, 1,{sourceDisplay = aCell:getChildByTag(-20-1):getChildByTag(-20) , showInCenter = true})
                itemIcon:setTag(-30)
                aCell:getChildByTag(-20-1):addChild(itemIcon.refCocosObj,10)

                setNodeText(aCell:getChildByTag(-20-1):getChildByTag(-10):getChildByTag(-10),CanonGoodIcon.getGoodName(ResourceEnum.PROP, data.rewardPropId,1,{withoutAmount = false}))
                -- print("~~~~~~~~~~~CanonGoodIcon.getGoodName = "..tostringRich(CanonGoodIcon.getGoodName(ResourceEnum.PROP, data.rewardPropId,1,{withoutAmount = false})))
                -- print("~~~~~~~~~~~~~~~~~~~~~data.detail1 = "..tostringRich(data.detail1))
                -- print("~~~~~~~~~~~~~~~~~~~data.rewardPropId = "..tostringRich(data.rewardPropId))
                aCell:getChildByTag(-20-1):getChildByTag(-10):getChildByTag(-10):setVisible(true)

            -- end
            
        -- end
  end
    local function onListItemTouch( evt )
      local aIndex = evt.data + 1
      local newCell = self.tableView:cellAtIndex(aIndex - 1)
     
      if newCell then 
        local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
        local data = self.dataList[aIndex]
        -- print("~~~~~~~~~~~~~~data.rewardPackId = "..tostringRich(data.rewardPackId))
        local  propConfigs = MetaManager.prop_meta[data.rewardPropId]
        
        -- for i=1,4 do
          
          local btnDisplay = newCell:getChildByTag(cellTag)--:getChildByTag(-20-i)
          local iconDisplay = btnDisplay:getChildByTag(-20-1)
          -- local challengeDisplay = iconDisplay:getChildByTag(-20)
          exchangeDisplay = iconDisplay
          exchangeSize = HeDisplayUtil:getNodeGroupBounds(exchangeDisplay, nil, kHitAreaObjectTag).size
         if posInCell.x > (iconDisplay:getPositionX()- exchangeSize.width/3) and
            posInCell.x < (iconDisplay:getPositionX() + 55) and
            posInCell.y > (iconDisplay:getPositionY() - 71) and
            posInCell.y < (iconDisplay:getPositionY()+exchangeSize.width/5) then
            self:PopPanel(propConfigs)
          end
        -- end
      end    
      
    end
  
  
  
  -- aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  local renderer = UnionBattleReportRenderer.new(self.table_meta_info.item_width, self.table_meta_info.item_height)
  local aTableView = TableView:create(renderer, self.table_meta_info.table_width, self.table_meta_info.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(self.table_meta_info.table_posX, self.table_meta_info.table_posY))
  return aTableView
end

function CrossUnionRewardPreviewPanel:ResetText(txt)
  -- txt_Gvg_17
  self.panelUI:getChildByName("txt_Gvg_17"):getChildByName("txt"):setString(getTextByKey(txt))

end

function CrossUnionRewardPreviewPanel:PopPanel(propConfigs)
 local rewardList = MetaManager.getRewardInfoByID(propConfigs.effectValue) or {}
 -- print("~~~~~~~~~~~~~~rewardList = "..tostringRich(rewardList))
 local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = rewardList, rewardTitle = getTextByKey("pk_reward_title")} )
 self.panelUI:addChild(aRewardPanel)
 aRewardPanel:scaleIn()

end

function CrossUnionRewardPreviewPanel:scaleIn()
  
  self.tempLayer.touchEnabled = false
  self.tempLayer.touchChildren = false
  local function scaleInFinished()
    self.tempLayer.touchEnabled = true
    self.tempLayer.touchChildren = true
  end
  local arr = CCArray:create()
  arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
  arr:addObject(CCCallFunc:create(scaleInFinished))
  self.tempLayer:runAction(CCSequence:create(arr))

  --添加到二级堆栈
  UiStackManager.push(self)
end

function CrossUnionRewardPreviewPanel:dismiss()
  UiStackManager.remove(self)
  self.container.targetInfoPanel = nil
  self:removeFromParentAndCleanup(true)
  -- self.container:setTableViewsEnabled(true)
end

function CrossUnionRewardPreviewPanel:dispose()
  UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
  CrossUnionRewardPreviewPanel.clear()
	CrossUnionRewardPreviewPanel.super.dispose(self)
end