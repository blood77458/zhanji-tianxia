--------------------------------------------------------------------------------
-- StoryReviewActivityPanel.lua
-- author: zhehua.ou
-- date: 2014-11-30
--------------------------------------------------------------------------------
require "canon.models.EliteManager"

-- featureName 对应的剧情对话文件
StoryFileName = {
  eventChristmas = "event_conversation_christmas",
  eventNewyear = "event_conversation_christmas",
  eventGirls = "event_conversation_christmas",
  eventWedding = "event_conversation_christmas",
}

StoryStartId = {
  eventChristmas = 90101,
  eventNewyear = 90201,
  eventGirls = 90301,
  eventWedding = 90401,
}

StoryEndId = {
  eventChristmas = 90200,
  eventNewyear = 90300,
  eventGirls = 90400,
  eventWedding = 90404,
}

StoryReviewActivityPanel = class(Layer)

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function StoryReviewActivityPanel:ctor()
  self.mainUI = nil
end

function StoryReviewActivityPanel:create(contianer)
	local layer = StoryReviewActivityPanel.new()
	layer.contianer = contianer

	layer:initLayer()
	return layer
end

function StoryReviewActivityPanel:initLayer()
	StoryReviewActivityPanel.super.initLayer(self)

	local builder = LayoutBuilder:createWithContentsOfFile(EliteManager.DICT.RESOURCE_FILE)
	self.mainUI = builder:build("elite_page_elite_list")
	self:addChild(self.mainUI)

  self.mainUI:getChildByName("table_activityStory_list"):setVisible(false)
  self.TableView = self:CreateStoryList(self.mainUI:getChildByName("table_activityStory_list"))
end

function StoryReviewActivityPanel:CreateStoryList(display)
  local cellTag = 1024

  local StoryReviewActivityRenderer = class(TableViewRenderer)
  function StoryReviewActivityRenderer:ctor(width , height , data , creater)
    self.width = width
    self.height = height
    self.list = data or {}
    self.creater = creater
  end

  function StoryReviewActivityRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile(EliteManager.DICT.RESOURCE_FILE)
    local aCell = builder:build("list/activityStory_list")
    container:addChild(aCell)
    aCell:setTag(cellTag)

    local tempLayer = Layer:create()
    tempLayer:setContentSize(CCSizeMake(685, 198))
    tempLayer:setTag(-11)
    aCell:addChild(tempLayer)

  end

  function StoryReviewActivityRenderer:setData(rawCocosObj, index)
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local data = self.list[index + 1]

    aCell:getChildByTag(-11):removeChildByTag(-30, true)
    local btnSprite = Sprite:create( "pic/activityStoryUI/ActivityStory_"..data.sceneFeatureName..".png" )
    btnSprite:setAnchorPoint(ccp(0, 0))
    
    btnSprite:setTag(-30)

    aCell:getChildByTag(-11):addChild(btnSprite.refCocosObj,10)
  end

  local tableViewSizes = getTableViewSizes(display)

  local gameInitData = DataManager.getGameInitData()
  local tableData = gameInitData.sharkSceneProcess.activitySceneChapterList

  local renderer = StoryReviewActivityRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height , tableData , self)
  local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height + 136, cellTag, {-11}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local newCell = evt.target:cellAtIndex(aIndex - 1)
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)

    local cardDisplay = newCell:getChildByTag(cellTag):getChildByTag(-11)

    if posInCell.x > (cardDisplay:getPositionX()) and
      posInCell.x < (cardDisplay:getPositionX() + 685) and
      posInCell.y > (cardDisplay:getPositionY()) and
      posInCell.y < (cardDisplay:getPositionY() + 198) then

      local data = evt.target.tableViewRenderer.list[aIndex]
      self:ShowStoryBy(data.sceneFeatureName)
    end

  end

  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  self.mainUI:addChild(aTableView)

  return aTableView
end

function StoryReviewActivityPanel:ShowStoryBy(sceneFeatureName)
  local luaFileName = StoryFileName[sceneFeatureName]
  local conversationFile = require ("canon.configs."..luaFileName)
  
  local storyList = {}
  local previousDialogId
  local previoudDialogOpportunity
  for _, aConfig in ipairs(conversationFile) do
    if (aConfig.dialogId >= StoryStartId[sceneFeatureName]) and (aConfig.dialogId < StoryEndId[sceneFeatureName]) then
      if (not previousDialogId) or (previousDialogId ~= aConfig.dialogId) or (not previoudDialogOpportunity) or (previoudDialogOpportunity ~= aConfig.activeOpportunity) then
        previousDialogId = aConfig.dialogId
        previoudDialogOpportunity = aConfig.activeOpportunity
        local temp = {}
        temp.dialogId = previousDialogId
        temp.dialogOpportunity = previoudDialogOpportunity
        table.insert(storyList, temp)
      end
    end
  end

  local function checkStoryList()
    if #storyList > 0 then
        local originalGuideCallback = getGuideFinishCallback()
        local function guideFinished()
          table.remove(storyList, 1)
          RegisterOnGuideFinishCallback(originalGuideCallback)
          checkStoryList()
        end
        RegisterOnGuideFinishCallback(guideFinished)
        Run_Script_Using_Dialog_Index(storyList[1].dialogId, storyList[1].dialogOpportunity, luaFileName)
    end
  end

  checkStoryList()
end

function StoryReviewActivityPanel:dispose()
  StoryReviewActivityPanel.super.dispose(self)
end

function StoryReviewActivityPanel:doEnterAnimation()
  local RunningScene = Director:sharedDirector():getRunningScene()
  RunningScene:setTouchEnabled(false)

  self:startEnterAnimation()
end

function StoryReviewActivityPanel:startEnterAnimation()
  local function enterActionFinished()
	local RunningScene = Director:sharedDirector():getRunningScene()
	RunningScene:setTouchEnabled(true)
  end
  
  local function getCCSequence()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    
    return CCSequence:create(arr)
  end
  
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  self.mainUI:runAction(getCCSequence())
end

function StoryReviewActivityPanel:doExitAnimation(callBackFunc)
  local RunningScene = Director:sharedDirector():getRunningScene()
  RunningScene:setTouchEnabled(false)

  self:startExitAnimation(callBackFunc)
end

function StoryReviewActivityPanel:startExitAnimation(callBackFunc)  
  local function exitActionFinished()
  	local RunningScene = Director:sharedDirector():getRunningScene()
	RunningScene:setTouchEnabled(true)

	if callBackFunc then
	   callBackFunc()
	end
  end
  
  local function getCCSequence()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(exitActionFinished))
    
    return CCSequence:create(arr)
  end

  self.mainUI:runAction(getCCSequence())
end
