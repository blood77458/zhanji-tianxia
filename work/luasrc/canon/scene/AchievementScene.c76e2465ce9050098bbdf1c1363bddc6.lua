require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "hecore.ui.TableView"
require "canon.request.GainAchievementRewardRequest"

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15
local mainUI = nil
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local OriginalOffset = 0 --这个是TableView 初始的偏移量
local CellNumberList = {} --这个是装每一种类型的Cell数 例如：等级里面的任务个数
local judeadd = true
local judeadd1 = true
local judeadd2 = true
local TitleADCell = nil   
local TitleAD = nil
local ControlLevelCell = true
local ControlMissionCell = true
local ControlEliteCell = true
local ControlCollectCardCell = true
local ControlLevelCellJude = true
local ControlMissionCellJude = true
local ControlEliteCellJude = true
local ControlCollectCardCellJude = true
local ControlButton = true
local AchievementType = nil
local AchievementReward = {}
local CellImage = nil
local AchievementTypeNum = 0
statusList = {}
local maxFinishedEliteCityId = 0
local maxFinishedEliteId = 0
local AchievementTypeEnum = 
{
  level = 1,
  mission = 2,
  elite = 3,
  collectCard = 4,
}

--
-- AchievementScene
--

AchievementScene = class(BaseUIScene)
local function CreateMaxFinishedEliteCityId()
  maxFinishedEliteId = EliteManager.getMaxFinishedEliteId()
  -- maxFinishedEliteCityId = 0
  if maxFinishedEliteId ~= 0 then
    local aMissionInfo = EliteManager.getEliteMissionByMissionId(maxFinishedEliteId)
    local aNextMissionInfo = EliteManager.getEliteMissionByMissionId(aMissionInfo.nextEliteId)
    if (not aNextMissionInfo) or (aMissionInfo.cityId ~= aNextMissionInfo.cityId) then
      maxFinishedEliteCityId = aMissionInfo.cityId
    else
      local aPreviousMissionInfo = EliteManager.getEliteMissionByMissionId(aMissionInfo.previousEliteId)
      while(aPreviousMissionInfo and (aMissionInfo.cityId == aPreviousMissionInfo.cityId)) do
        aMissionInfo = aPreviousMissionInfo
        aPreviousMissionInfo = EliteManager.getEliteMissionByMissionId(aMissionInfo.previousEliteId)
      end
      if aPreviousMissionInfo and (aMissionInfo.cityId ~= aPreviousMissionInfo.cityId) then
        maxFinishedEliteCityId = aPreviousMissionInfo.cityId
      end
    end
  end
end

function AchievementScene:ctor()
  statusList = {}
end

--每次切换场景 都会重置

local function ResetFun()
 OriginalOffset = 0 --这个是TableView 初始的偏移量
 CellNumberList = {} --这个是装每一种类型的Cell数 例如：等级里面的任务个数
 judeadd = true
 judeadd1 = true
 judeadd2 = true
 TitleADCell = nil   
 TitleAD = nil
 ControlLevelCell = true
 ControlMissionCell = true
 ControlEliteCell = true
 ControlLevelCellJude = true
 ControlMissionCellJude = true
 ControlEliteCellJude = true
 ControlButton = true
 ControlCollectCardCell = true
 ControlCollectCardCellJude = true
 AchievementTypeNum = 0
 statusList = {}
 maxFinishedEliteCityId = 0
 maxFinishedEliteId = 0

end

function AchievementScene:create(argv)
  local s = AchievementScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  self.ignoreAction = self.argv.params.ignoreAction
  self.CellNum = self.argv.params.CellNum or nil
  s:initScene()
  return s
end
local  function RemoveTitleADCell()
  if TitleADCell then
    TitleADCell:removeFromParentAndCleanup(true)
    TitleADCell = nil
    CellImage = nil
  end
end

local  function RemoveTitleAD()
  if TitleAD then
    TitleAD:removeFromParentAndCleanup(true)
    TitleAD = nil
  end
end
--创建覆盖上面的广告图  有响应事件
function AchievementScene:AddADTitle(PicName,num)
  -- print("__________________________创建覆盖上面的广告图"..PicName)
  local function onCancelClicked()
    -- print("______________________________点击")
    
    if num == AchievementTypeEnum.level then
      if ControlLevelCellJude then
        self:JudeCellButton(AchievementTypeEnum.level,self.LevelTab,1,ControlLevelCellJude)
        ControlLevelCellJude = false
      else
        self:JudeCellButton(AchievementTypeEnum.level,self.LevelTab,#self.LevelTab,ControlLevelCellJude)
        ControlLevelCellJude = true
      end
    elseif num == AchievementTypeEnum.mission then
      if ControlMissionCellJude then
        self:JudeCellButton(AchievementTypeEnum.mission,self.MissionTab,1,ControlMissionCellJude)
        ControlMissionCellJude = false
      else
        self:JudeCellButton(AchievementTypeEnum.mission,self.MissionTab,#self.MissionTab,ControlMissionCellJude)
        ControlMissionCellJude = true
      end
    elseif num == AchievementTypeEnum.elite then
      if ControlEliteCellJude then
        self:JudeCellButton(AchievementTypeEnum.elite,self.EliteTab,1,ControlEliteCellJude)
        ControlEliteCellJude = false
      else
         self:JudeCellButton(AchievementTypeEnum.elite,self.EliteTab,#self.EliteTab,ControlEliteCellJude)
        ControlEliteCellJude = true
      end
    elseif  num == AchievementTypeEnum.collectCard then
      if ControlCollectCardCellJude then
        self:JudeCellButton(AchievementTypeEnum.collectCard,self.CollectCardTab,1,ControlCollectCardCellJude)
        ControlCollectCardCellJude = false
      else
        self:JudeCellButton(AchievementTypeEnum.collectCard,self.CollectCardTab,#self.CollectCardTab,ControlCollectCardCellJude)
        ControlCollectCardCellJude = true
      end
    end
  end
  
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~CellNumberList = "..tostringRich(CellNumberList[num]))
  if  CellNumberList[num] ~= 1 then
    local arr = CCArray:create()
    local cancelSprite = nil
    local cancelSelected = nil
   
    if  num == 4 then
      
      cancelSprite = CCSprite:create("ui_res/daily_activity/"..PicName..".png")
      cancelSelected = CCSprite:create("ui_res/daily_activity/"..PicName..".png")
    else

      cancelSprite = CCSprite:create("ui_res/daily_activity/bg_achievement_task_"..PicName..".png")
      cancelSelected = CCSprite:create("ui_res/daily_activity/bg_achievement_task_"..PicName..".png")
    end
    --[[
    local TitleADCell = Layer:create()
    -- TitleADCell:setPosition(ccp(358,880))
    TitleADCell:addChild(cancelSprite)
    TitleADCellBut = Button:create(contentLayer)
    TitleADCellBut:addEventListener(Events.kStart, onCancelClicked, self)
    TitleADCell:setPosition(ccp(358,880))
    mainUI:addChild(TitleADCell)
    ]]

    local cancelButton = CCMenuItemSprite:create(cancelSprite, cancelSelected)
    cancelButton:setPosition(ccp(358,880))
    cancelButton:registerScriptTapHandler(onCancelClicked)
    -- cancelButton:setTag(2)
    CellImage = cancelButton
    arr:addObject(cancelButton)

    local menu = PandoraMenuEx:createWithArray(arr, -128)
    -- cancelButton:setEnabled(false)
    menu = tolua.cast(menu, "CCNode")
    menu:setPosition(0,0)
    -- menu:setTag(1)
    local menuLayer = CCLayer:create()

    -- local function onTouch(event, x, y)
    --   if event == CCTOUCHBEGAN then
    --     return true
    --   else
    --     return
    --   end
    -- end
    -- menuLayer:registerScriptTouchHandler(onTouch, false, 1, true)
    -- menuLayer:setTouchEnabled(false)
   
    menuLayer:addChild(menu, 20)
    TitleADCell = CocosObject.new(menuLayer)
    mainUI:addChild(TitleADCell)
  end

end
function AchievementScene:AddADTitleCell(picName,num)
  local newcell=self.tableView:cellAtIndex(num - 1) 
  if newcell then
    if num ~= AchievementTypeNum then
      TitleAD = CCSprite:create("ui_res/daily_activity/bg_achievement_task_"..picName..".png")
      TitleAD:setPosition(ccp(348,70))
      newcell:addChild(TitleAD)
    end
  end
end

function AchievementScene:showTextFinish()
    --TitleADCell 这个变量是浮在上面的标题图
    --TitleAD 这个变量是添加到TabelView的 Cell的标题图变量
        -- local ControlLevelCell = true           等级广告条的开关
        -- local ControlMissionCell = true         闯关广告条的开关
        -- local ControlEliteCell = true           过关斩将广告条开关
    --通过偏移量来设置UI的显示 
    
      local Offset = self.tableView:getContentOffset()
    -- print("____________________偏移量 = "..Offset.y)
    -- print("++++++++++++++++++++++++++++++++++++++OriginalOffset = "..OriginalOffset.y)
    
    --这个是下拉的状态  这个偏移会比 初始的位置还要小（类似下拉刷新，但是没有刷新的功能，只是做了删除覆盖广告图）
    if Offset.y <= OriginalOffset.y then
      
      if TitleADCell then
        TitleADCell:removeFromParentAndCleanup(true)
        TitleADCell = nil
        CellImage = nil
        ControlLevelCell = true
      end
    end
    --这个是当 TableView滑到底，偏移量为0 或是大于零是也要删除广告图 但是前提条件是最后一个广告下面的Cell的个数
    --只有一个广告图
    if  CellNumberList[4] and  CellNumberList[4] == 1 then   ---如果图鉴添加
      if Offset.y == 0 then
        if TitleAD then
          TitleAD:removeFromParentAndCleanup(true)
          TitleAD = nil
          judeadd1 = true
        end
      end
      if Offset.y >= 0 then
        if ControlButton then
          RemoveTitleADCell()
          ControlEliteCell = true
          ControlLevelCell = true
          ControlMissionCell = true
          ControlCollectCardCell =true
          ControlButton = false
        end
      end
    end
    --当偏移量小于等级广告图总共Cell的个数的时候我们就要创建等级的覆盖广告图  前提条件 等级Cell的个数不能为1
    if  Offset.y <  (OriginalOffset.y + (CellNumberList[1]-1) * self.table_meta_info.item_height) then
      if CellNumberList[1] ~= 1 then
       RemoveTitleAD()

        if Offset.y > OriginalOffset.y then
          if ControlLevelCell then
            RemoveTitleADCell()
            self:AddADTitle("level2",1)
            ControlLevelCell = false
          end
        end
      end
      judeadd = true
      ControlMissionCell = true
      ControlCollectCardCell = true
      -- ControlButton = true
    --这个是偏移量小于等于等级广告图最后Cell的偏移位置的时候，就在这最后一个Cell上面添加等级广告图
    elseif   Offset.y <= OriginalOffset.y + (CellNumberList[1]) * self.table_meta_info.item_height then
      RemoveTitleADCell()
      if  CellNumberList[1] ~= 1 then
        if judeadd then
          RemoveTitleADCell()
          -- print("################################### 添加等级Cell")
          self:AddADTitleCell("level2",CellNumberList[1])
          judeadd = false 
        end
      end
       
      ControlLevelCell = true
      ControlEliteCell = true
      ControlMissionCell = true
      ControlCollectCardCell = true
      ControlButton = true
    --这个是偏移量小于闯关和等级Cell的总个数减一的偏移位置的时候，就要创建闯关的广告图
    elseif  Offset.y <  (OriginalOffset.y + (CellNumberList[2] + CellNumberList[1]-1) * self.table_meta_info.item_height )  then
     
      if CellNumberList[2] ~= 1 then
        RemoveTitleAD()
      
        if ControlMissionCell then
          RemoveTitleADCell()
         
          if CellNumberList[2] ~= 1 then 
            self:AddADTitle("toconfirm2",2)
            ControlMissionCell = false 
          end 
        end
      end
      judeadd1 = true
      ControlLevelCell = true
      ControlEliteCell = true
      ControlCollectCardCell = true
      -- ControlButton = true
      judeadd = true
    --这个是在闯关最后一个Cell上面创建闯关的广告图  
    elseif  Offset.y <  (OriginalOffset.y + (CellNumberList[2]+ CellNumberList[1]) * self.table_meta_info.item_height ) then
      RemoveTitleADCell()
      if  CellNumberList[2] ~= 1   then
        if judeadd1 then
          RemoveTitleADCell()
          -- print("################################### 添加闯关Cell")
          if CellNumberList[2] ~= 1 then 
            self:AddADTitleCell("toconfirm2",CellNumberList[2]+CellNumberList[1])
            judeadd1 = false
          end
          ControlMissionCell = true
          
          
          ControlButton = true
        end
      end
       ControlEliteCell = true
       ControlCollectCardCell = true
    --这个是在创建过关斩将的广告图  
    elseif Offset.y < (OriginalOffset.y +(CellNumberList[2]+ CellNumberList[1]+ CellNumberList[3]-1) * self.table_meta_info.item_height ) then
      RemoveTitleAD()
      if CellNumberList[3] ~= 1 then
        if ControlEliteCell then
          RemoveTitleADCell()
          self:AddADTitle("pass2",3)
          ControlEliteCell = false
        end
      end
      ControlMissionCell = true
      ControlCollectCardCell = true
      ControlLevelCell = true
      judeadd1 = true
      judeadd2 = true
      ControlCollectCardCell =true
    elseif  Offset.y <  (OriginalOffset.y + (CellNumberList[2]+ CellNumberList[1]+CellNumberList[3]) * self.table_meta_info.item_height ) then
       RemoveTitleADCell()
        
      if  CellNumberList[3] ~= 1   then
        if judeadd2 then
          RemoveTitleADCell()
          -- print("################################### 添加闯关Cell")
          if CellNumberList[3] ~= 1 then 
            self:AddADTitleCell("pass2",CellNumberList[2]+CellNumberList[1]+CellNumberList[3])
            judeadd2 = false
          end
          ControlEliteCell = true
          
          ControlButton = true
        end
      end
      ControlCollectCardCell = true
    elseif CellNumberList[4] and Offset.y < (OriginalOffset.y +(CellNumberList[2]+ CellNumberList[1]+ CellNumberList[3]+CellNumberList[4]) * self.table_meta_info.item_height ) then   --这个是判断图鉴成就的位置这里面也是要加个开关 
      --ControlCollectCardCell

      RemoveTitleAD()
      if CellNumberList[4] ~= 1 then
        -- print("################################### 图鉴Cell")
        if ControlCollectCardCell then
          RemoveTitleADCell()
          self:AddADTitle("bg_rewardx2_task_collectCard2",4)
          ControlCollectCardCell = false
        end
      end
      ControlEliteCell = true
      ControlMissionCell = true
      ControlLevelCell = true
      judeadd2 = true
  end
end


function AchievementScene:onInit()

  self.jugeCell = true
	BaseUIScene.initBackGround(self)
  
  --新UI加黑底
  local colorLayer = LayerColor:create()
  colorLayer:setOpacity(kDarkOpacity)
  colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(colorLayer)

  self.title = Localization:getInstance():getText("achieve_task_title")
  
  self.builder = LayoutBuilder:createWithContentsOfFile("scene/daily_activity.json")
  self.builder.useArtLabelTTF = true
  mainUI = self.builder:build("daily_achievement_task")
  self:addChild(mainUI)

  local table_temp_view = mainUI:getChildByName("table_summary_list")
  table_temp_view:setVisible(false)
  self.table_meta_info = getTableViewSizes(table_temp_view)
 	
  local function onClickDailyActiveTaskButton()
    local function getDailyActiveInfoSucceedResponse( evt )
      self.ignoreAction = true
      local argv = {enterScene=nil,returnScene=nil,params={data = evt.data, ignoreAction = true , secretaryTips = self.argv.params.secretaryTips}}
      -- ResetFun()
      -- self:DeleteScheduler()
      self:replaceScene(SecretaryScene,argv)
    end
    local function getDailyActiveInfoFailedResponse( evt )
      
    end
    local request = GetDailyActiveInfoRequest.new( {}, rpc.SendingPriority.kHigh )
    request:addEventListener( RequestNotifyEnum.GetDailyActiveInfoSucceed, getDailyActiveInfoSucceedResponse )
    request:addEventListener( RequestNotifyEnum.GetDailyActiveInfoFailed, getDailyActiveInfoFailedResponse )
    request:start()
  end
  
  local function onClickDailyActiveTargetButton()
    local function onAfterSucceed( evt )
      self.ignoreAction = true
      local argv = {enterScene=nil,returnScene=nil,params={data = evt.data, ignoreAction = true , secretaryTips = self.argv.params.secretaryTips}}
      -- ResetFun()
      -- self:DeleteScheduler()
      self:replaceScene(DailyTargetScene,argv)
    end
    GetDailyAchieveInfoRequest.sendRequestDefalut(onAfterSucceed)
  end
  
  local function onClickAchievementButton()
    
  end
  
  if(DataManager.getCurrUser().level < DataManager.GameMetaData.dailyActiveConfig.levelLimit) then
    --不够打开第一页的等级
    self.secretaryTabDisplay = nil
    self.achievementTabDisplay = mainUI:getChildByName("btn_tab_activity1")
    self.targetTabDisplay = mainUI:getChildByName("btn_tab_activity2")
    mainUI:getChildByName("btn_tab_activity3"):setVisible(false)
  else
    self.secretaryTabDisplay = mainUI:getChildByName("btn_tab_activity1")
    self.achievementTabDisplay = mainUI:getChildByName("btn_tab_activity2")
    self.targetTabDisplay = mainUI:getChildByName("btn_tab_activity3")

  end

  if self.secretaryTabDisplay then
    self.dailyActiveTaskButton = Button:create(self.secretaryTabDisplay)
    self.dailyActiveTaskButton:addEventListener(Events.kStart,onClickDailyActiveTaskButton)
    self.secretaryTabDisplay:getChildByName("txt"):setString(getTextByKey("activity_daily_title1"))
    self.secretaryTabDisplay:getChildByName("icn_tixing_kong"):setVisible(false)
    self.secretaryTabDisplay:getChildByName("txt2"):setVisible(false)
    self.secretaryTabDisplay:getChildByName("btn_arena_active"):setVisible(false)
    local secretaryTipNum = (g_homeInfo and g_homeInfo.enableGainDailyActiveRewardNum or 0)
    if secretaryTipNum > 0 then
      self.secretaryTabDisplay:getChildByName("icn_tixing_kong"):setVisible(true)
      self.secretaryTabDisplay:getChildByName("txt2"):setVisible(true)
      self.secretaryTabDisplay:getChildByName("txt2"):setString(tostring(secretaryTipNum))
    else
      self.secretaryTabDisplay:getChildByName("icn_tixing_kong"):setVisible(false)
      self.secretaryTabDisplay:getChildByName("txt2"):setVisible(false)
    end
  end

  --每日目标按钮
  self.dailyActiveTargetButton = Button:create(self.targetTabDisplay)
  self.dailyActiveTargetButton:addEventListener(Events.kStart,onClickDailyActiveTargetButton)
  self.targetTabDisplay:getChildByName("txt"):setString(getTextByKey("activity_dailytask_title"))--每日目标
  self.targetTabDisplay:getChildByName("icn_tixing_kong"):setVisible(false)
  self.targetTabDisplay:getChildByName("txt2"):setVisible(false)
  self.targetTabDisplay:getChildByName("btn_arena_active"):setVisible(false)

  if DailyTargetScene.getTipNum() > 0 then
    self.targetTabDisplay:getChildByName("icn_tixing_kong"):setVisible(true)
    self.targetTabDisplay:getChildByName("txt2"):setVisible(true)
    self.targetTabDisplay:getChildByName("txt2"):setString(tostring(DailyTargetScene.getTipNum()))
  else
    self.targetTabDisplay:getChildByName("icn_tixing_kong"):setVisible(false)
    self.targetTabDisplay:getChildByName("txt2"):setVisible(false)
  end
  
  
  self.achievementTabDisplay:getChildByName("txt"):setString(getTextByKey("achieve_task_title"))
  self.achievementTabDisplay:getChildByName("btn_arena_disable"):setVisible(false)
  
  for k,v in pairs(AchievementTypeEnum) do
    AchievementTypeNum = AchievementTypeNum + 1
  end
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~AchievementTypeNum = "..AchievementTypeNum)
  self.selectedType = AchievementTypeEnum.level
  self:resetTipUI()
 	
  BaseUIScene.onInit(self)

  --这个是从图鉴那个场景中跳转到任务里面图鉴成就的位置，要通过设置偏移量才能真正切换到图鉴成就的位置
  --CellNum 可以通过这个数字显示哪一块的标题的位置
  local TotalCellNum = {}
  if self.CellNum then
    -- print("______________________________self.CellNum = "..self.CellNum)
    self:changeToList() 
  for i=1,AchievementTypeNum -1 do
   
    if i ~= 1 then
      TotalCellNum[i] = TotalCellNum[i -1] +CellNumberList[i] 
    else
      TotalCellNum[i] = CellNumberList[i] 
    end
  end
    
    self.tableView:setContentOffset(ccp(0,OriginalOffset.y+TotalCellNum[self.CellNum]*self.table_meta_info.item_height))
  else
    self:changeToList(4)
  end
  
end



function AchievementScene:resetTipUI()
  local aTipNum = AchievementScene.getTipNum()
  if aTipNum > 0 then
    self.achievementTabDisplay:getChildByName("icn_tixing_kong"):setVisible(true)
    self.achievementTabDisplay:getChildByName("txt2"):setVisible(true)
    self.achievementTabDisplay:getChildByName("txt2"):setString(tostring(aTipNum))
  else
    self.achievementTabDisplay:getChildByName("icn_tixing_kong"):setVisible(false)
    self.achievementTabDisplay:getChildByName("txt2"):setVisible(false)
  end
end



--判断是不是已经领取
local function getStatusForAchievement(aAchievementConfig)
  --1:abled;2:unabled;3:haved
  local cacheStatus = statusList[aAchievementConfig.achieveId]
  if cacheStatus then
    return cacheStatus
  end
  local function statusFound()
    local achievements = DataManager.getSharkAchievements()
    for _, aAchievement in pairs(achievements) do
      if aAchievement.achievementConfigId == aAchievementConfig.achieveId then
        if aAchievement.status == 3 then
          return 3
        end
        break
      end
    end
    if aAchievementConfig.achieveType == 1 then
      if DataManager.getCurrUser().level >= aAchievementConfig.achieveCondition then
        return 1
      else
        return 2
      end
    elseif aAchievementConfig.achieveType == 2 then
      local maxFinishedMissionId = CountryManager:sharedManager():getMaxFinishedMissionID()
      local countryId1 = math.modf(maxFinishedMissionId/10000)
      if countryId1 > aAchievementConfig.achieveCondition then
        return 1
      elseif countryId1 < aAchievementConfig.achieveCondition then
        return 2
      else
        local newMissionId, noNewExisted = CountryManager:sharedManager():getNewMissionID()
        if noNewExisted then
          return 1
        end
        local countryId2 = math.modf(newMissionId/10000)
        if countryId2 > countryId1 then
          return 1
        else
          return 2
        end
      end
    elseif aAchievementConfig.achieveType == 3 then
      if maxFinishedEliteId == 0 then
        return 2
      end
      
      if maxFinishedEliteCityId >= aAchievementConfig.achieveCondition then
        return 1
      else
        return 2
      end
    elseif aAchievementConfig.achieveType == 4 then  --这里要写图鉴成就的按钮状态的逻辑   去找图鉴信息里面的卡牌  
      -- print("aAchievementConfig.achieveType == 4")
      --后端给不能领取的id 还有收集卡牌的进度
      --查看图鉴开关是都开启，这个里面会有
      local isEnable = AchievementScene.isEnable()
      if isEnable then
        local CardBookachievements = DataManager.getSharkCardBookAchievements()
        -- print("______________________________________ = "..#CardBookachievements)
        for _, aAchievement in pairs(CardBookachievements) do
          if aAchievementConfig.achieveId == aAchievement.achievementConfigId then
            -- print("收集卡牌的进度值 = "..aAchievement.progress)
            return 2
          end
        end
        return 1
      else
        return 2
      end
    end
  end
  local aStatus = statusFound()
  statusList[aAchievementConfig.achieveId] = aStatus
  return aStatus
  
end
--这个好像是对已经可领取的那个排到最上面 将已经领取的放到最下面
local function getTableData(aType)
  -- print("*************************************aType = "..tostringRich(aType))
  local result = {}
 
  if #result == 0 then
    table.insert(result, {status = 0,achieveType = aType,achieveId = 0}) --将标题Cell的类型传进去
  end
  for _, aConfig in pairs(MetaManager.achievement_task) do
    if aConfig.achieveType == aType then
      local temp = {}

        for k, v in pairs(aConfig) do

          temp[k] = v
        end
      table.insert(result, temp)
      temp.status = getStatusForAchievement(aConfig)  --设置按钮的状态 把每一Cell的配置表传到getStatusForAchievement 在在这个方法里面判断是否按钮的状态
    end
  end
  table.sort(result, function(a, b)
    if a and  b and a.status and b.status then
      local aStatus1 = a.status
      local aStatus2 = b.status
     
      -- print("________________________________astatus =  "..a.status.." ,"..a.achieveType)
      -- print("________________________________bstatus =  "..b.status.." ,"..b.achieveType)
     
      if aStatus1 ~= aStatus2 then  --这里面就是状态不相同 就比较状态来排序  状态相同通过id值来排序
        return aStatus1 < aStatus2
       
      else
        return a.achieveId < b.achieveId
      end
    end

  end
  )
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ "..tostringRich(result))
  
  return result
end

function AchievementScene:changeToList(aType)
  if self.tableView then
    self.tableView:removeFromParentAndCleanup(true)
    self.tableView = nil
  end
 
  self.NewDataTable = {}
  local function AddDataTab(tab)
    for i,v in ipairs(tab) do
      -- print("++++++++++++++++++++++++++++++++++++++ index "..i)
      table.insert(self.NewDataTable,v)
    end
  end
  
  
  
  self.LevelTab = getTableData(AchievementTypeEnum.level)
  self.MissionTab = getTableData(AchievementTypeEnum.mission) 
  self.EliteTab = getTableData(AchievementTypeEnum.elite) 
  self.CollectCardTab = getTableData(AchievementTypeEnum.collectCard) 
  --[[
  print("_________________________等级表的个数LevelTab = "..#self.LevelTab)
  print("_________________________等级表的个数MissionTab = "..#self.MissionTab)
  print("_________________________等级表的个数EliteTab = "..#self.EliteTab)
  print("_________________________等级表的个数CollectCardTab = "..#self.CollectCardTab)
  ]]
  --将每一种的类型的表排序再重新添加到新的表
  
  local function CreateNewAchievementList()
    table.insert(self.NewDataTable,self.LevelTab[1])
    table.insert(self.NewDataTable,self.MissionTab[1])
    table.insert(self.NewDataTable,self.EliteTab[1])
    ControlLevelCellJude = false
    ControlMissionCellJude = false
    ControlEliteCellJude = false
    table.insert(CellNumberList,1) 
    table.insert(CellNumberList,1)
    table.insert(CellNumberList,1)
  end
  -- print("############################新表的长度 "..#self.NewDataTable)
  local isEnable = AchievementScene.isEnable()

  
  if isEnable then
    if aType == 4 then
      CreateNewAchievementList()
      table.insert(self.NewDataTable,self.CollectCardTab[1])
      ControlCollectCardCellJude = false
      table.insert(CellNumberList,1)
    else
      CreateNewAchievementList()
      AddDataTab(self.CollectCardTab)
      table.insert(CellNumberList,#self.CollectCardTab)
    end
  else
    CreateNewAchievementList()
  end
  self.tableData = self.NewDataTable
  self.tableView = self:createTableView()
  mainUI:addChildAt(self.tableView, 2)
  self.tableView:reloadData()
  --获得初始的偏移量
  OriginalOffset = self.tableView:getContentOffset()
  --将每一个类型的任务数放入表中
  

  -- print("____________________________初始Y偏移量 = "..OriginalOffset.y)
end


function AchievementScene:createTableView()
  local cellTag = 1024
  local buttonTag = {{105, -14}}
  local aScene = self
  local AchievementTableViewRenderer = class(TableViewRenderer)
  function AchievementTableViewRenderer:ctor(width, height)
    self.list = aScene.tableData
  end
  function AchievementTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/daily_activity.json")
    builder.useArtLabelTTF = true
    local aCell = builder:build("list_activity_summary_task")
    --aCell:setAnchorPoint(ccp(0,1))
    container:addChild(aCell)
    aCell:setTag(cellTag)

    local ADLevelCell = aCell:getChildByName("bg_achievement_task_level")
    ADLevelCell:setTag(101)
    ADLevelCell:setVisible(false)
    local ADEliteCell = aCell:getChildByName("bg_achievement_task_elite")
    ADEliteCell:setTag(102)
    ADEliteCell:setVisible(false)
    local ADToconCell = aCell:getChildByName("bg_daily_achievement_task_tocon")
    ADToconCell:setTag(103)
    ADToconCell:setVisible(false)
    local ADCollectCardCell = aCell:getChildByName("bg_rewardx2_task_collectCard")
    ADCollectCardCell:setTag(104)
    ADCollectCardCell:setVisible(false)
    local AchievementTask = aCell:getChildByName("list_activity_achievement_task")
    AchievementTask:setTag(105)
    local aCardDisplay = aCell:getChildByName("list_activity_achievement_task"):getChildByName("normal_card_small")
    aCardDisplay:setTag(-10)
    aCardDisplay:setVisible(false)
    
    local aNumLabel = aCell:getChildByName("list_activity_achievement_task"):getChildByName("txt_task_reward1")
    aNumLabel:setTag(-11)
    aNumLabel = aNumLabel:getChildByName("txt")
    aNumLabel:setTag(-10)
    aNumLabel:setAroundColor(ccc3(102,0,0))
    
    local aDesLabel = aCell:getChildByName("list_activity_achievement_task"):getChildByName("txt_task_reward2")
    aDesLabel:setTag(-12)
    aDesLabel = aDesLabel:getChildByName("txt")
    aDesLabel:setTag(-10)
    --txt_ceiling      common_txt_item_quantity
    local CommonLabel = aCell:getChildByName("list_activity_achievement_task"):getChildByName("common_txt_item_quantity")
    CommonLabel:setTag(-17)
    CommonLabel = CommonLabel:getChildByName("txt_item_quantity")
    CommonLabel:setTag(-10)

    local CeilingLabel = aCell:getChildByName("list_activity_achievement_task"):getChildByName("txt_ceiling")
    CeilingLabel:setTag(-16)
    CeilingLabel = CeilingLabel:getChildByName("txt")
    CeilingLabel:setTag(-10)
    
    local aButtonDisplay = aCell:getChildByName("list_activity_achievement_task"):getChildByName("btn_getcdreward")
    aButtonDisplay:setTag(-14)
    local challangeLabel = aButtonDisplay:getChildByName("txt")
    challangeLabel:setTag(-10)
    local challangBg = aButtonDisplay:getChildByName("btn")
    challangBg:setTag(-11)
  end
  function AchievementTableViewRenderer:setData( rawCocosObj, index )
   
    -- print("____________________________________self.list[index + 1].achieveType = "..self.list[index + 1].achieveType)
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
     local aButtonDisplay = aCell:getChildByTag(105):getChildByTag(-14)
    if self.list[index + 1].achieveType and self.list[index + 1].achieveType == AchievementTypeEnum.level and self.list[index + 1].achieveId == 0  then
      -- print("_____________________indexlevel = "..index)
      aCell:getChildByTag(101):setVisible(true)
      aCell:getChildByTag(105):setVisible(false)
    
    elseif self.list[index + 1].achieveType and self.list[index + 1].achieveType == AchievementTypeEnum.mission  and self.list[index + 1].achieveId == 0 then
      -- print("_____________________indexmission = "..index)
      aCell:getChildByTag(103):setVisible(true)
      aCell:getChildByTag(105):setVisible(false)
    
    elseif self.list[index + 1].achieveType and self.list[index + 1].achieveType == AchievementTypeEnum.elite and self.list[index + 1].achieveId == 0  then
      -- print("_____________________indexelite = "..index)
      aCell:getChildByTag(102):setVisible(true)
      aCell:getChildByTag(105):setVisible(false)
     
    elseif self.list[index + 1].achieveType and self.list[index + 1].achieveType == AchievementTypeEnum.collectCard and self.list[index + 1].achieveId == 0  then
     
      -- print("_____________________显示图鉴成就的广告图indexelite = "..self.list[index + 1].achieveType)
      -- print("__________________________当前的index值 = "..index+1)
        aCell:getChildByTag(104):setVisible(true)
        aCell:getChildByTag(105):setVisible(false)
      
      
    end

    if  self.list[index + 1].achieveId ~= 0  then
      -- print("————————————————————————————————————————标题Cell")
      --如果不是广告标题就要将广告标题隐藏起来
      aCell:getChildByTag(101):setVisible(false)
      aCell:getChildByTag(103):setVisible(false)
      aCell:getChildByTag(102):setVisible(false)
      aCell:getChildByTag(104):setVisible(false)
      aCell:getChildByTag(105):setVisible(true) 
      local aTableData = self.list[index + 1]
      
   
      local icon = aCell:getChildByTag(105):getChildByTag(-20)
      if icon then
        icon:removeFromParentAndCleanup(true)
      end
      
      
      local aRewardPackageConfig = {}
      --通过遍历另一个配置表 去寻找奖
      if aTableData.achieveType == 4 then
        -- print("+++++++++++++++++++++++++++++++++++++++achieveId "..aTableData.achieveId)
        local RewardTable = MetaManager.atlas_Reward
          
        for _,aConfig in pairs(RewardTable) do
          if aConfig.id == aTableData.achieveCondition then
            aRewardPackageConfig.content1Type = aConfig.rewardType
            aRewardPackageConfig.content1Id = aConfig.rewardID
            aRewardPackageConfig.content1Amount = aConfig.rewardNum
            aRewardPackageConfig.countryType = aConfig.countryType
            aRewardPackageConfig.id = aConfig.id
            aRewardPackageConfig.cardNum = aConfig.cardNum
            
          end  
        end
      else
        aRewardPackageConfig = MetaManager.reward_package[aTableData.achieveReward]
      end
      AchievementType = aTableData.achieveType
      AchievementReward =aRewardPackageConfig
      
      local aCardDisplay = aCell:getChildByTag(105):getChildByTag(-10)
      local params = {}
  		params.sourceDisplay = aCardDisplay
  		params.container = aCell:getChildByTag(105)
      params.showInCenter = true
  		params.zindex = 10
      -- print("______________________________________content1Type=  "..aRewardPackageConfig.content1Type.." content1Id = "..aRewardPackageConfig.content1Id)
    	
      icon = CanonGoodIcon.createGoodIcon(aRewardPackageConfig.content1Type, aRewardPackageConfig.content1Id, 0, params)

      if icon then
  			icon:setTag(-20)
  			icon:dispose()
  		end
      local progress = nil
      
      local function CardBookProgress(aAchievementConfig)
        if aAchievementConfig.achieveType == 4 then
          local CardBookachievements = DataManager.getSharkCardBookAchievements()
          -- print("______________________________________ = "..#CardBookachievements)
          local aStatus = getStatusForAchievement(aTableData)
          --如果没有达到可领取的条件就要获取进度
          if aStatus == 2 then
            for _, aAchievement in pairs(CardBookachievements) do
              if aAchievementConfig.achieveId == aAchievement.achievementConfigId then
                -- print("收集卡牌的进度值 = "..aAchievement.progress)

                progress = aAchievement.progress
                
              end
            end 
          else
            --如果已经达到领取条件和已经领取的  把进度值定为条件值
            progress = aRewardPackageConfig.cardNum
          end
        end
      end
      
      if aRewardPackageConfig then
        local aName
        if aRewardPackageConfig.content1Type == ResourceEnum.COIN then
          aName = Localization:getInstance():getText("resource_silverCoin")
        elseif aRewardPackageConfig.content1Type == ResourceEnum.GEMS then
          aName = Localization:getInstance():getText("resource_goldCoin")
        elseif aRewardPackageConfig.content1Type == ResourceEnum.PROP then
          local aPropMetaConfig = MetaManager.prop_meta[aRewardPackageConfig.content1Id]
          aName = Localization:getInstance():getText(aPropMetaConfig.name)
        elseif aRewardPackageConfig.content1Type == ResourceEnum.CARD_FRAGMENT then
          local cardMetaId = MetaManager.card_fragment_meta[aRewardPackageConfig.content1Id].cardId
          aName = Localization:getInstance():getText(MetaManager.card_meta[cardMetaId].name)
        elseif aRewardPackageConfig.content1Type == ResourceEnum.EQUIP_FRAGMENT then
          local equipMetaId = MetaManager.equip_fragment_meta[aRewardPackageConfig.content1Id].equipId
          aName = Localization:getInstance():getText(MetaManager.equip_meta[equipMetaId].name)
        elseif aRewardPackageConfig.content1Type == ResourceEnum.VIP_EXP then
          aName = Localization:getInstance():getText("achieve_task_vip")
       end

        if  aTableData.achieveType == 4  then
          if aRewardPackageConfig then
            if aRewardPackageConfig.countryType == 1 then
              aName = Localization:getInstance():getText("CardCollectionWei_Title"..aRewardPackageConfig.id)
            elseif aRewardPackageConfig.countryType == 2  then
              aName = Localization:getInstance():getText("CardCollectionShu_Title"..aRewardPackageConfig.id)
            elseif aRewardPackageConfig.countryType == 3 then
              aName = Localization:getInstance():getText("CardCollectionWu_Title"..aRewardPackageConfig.id)
            elseif aRewardPackageConfig.countryType == 4  then
              aName = Localization:getInstance():getText("CardCollectionQun_Title"..aRewardPackageConfig.id)
            end
          end
           
        else
          aName = aName .. "x" .. aRewardPackageConfig.content1Amount
        end
        if aCell:getChildByTag(105):getChildByTag(-11):getChildByTag(-10) then
          local aNumLabel = aCell:getChildByTag(105):getChildByTag(-11):getChildByTag(-10)
          setNodeText(aNumLabel, aName)
        end
      end
      
      local aDes
      -- local aDesCeiling = nil
      local aDesLabel = aCell:getChildByTag(105):getChildByTag(-12):getChildByTag(-10)
      aCell:getChildByTag(105):getChildByTag(-16):setVisible(false)
      aCell:getChildByTag(105):getChildByTag(-17):setVisible(false)
      local RewardNumLabel = aCell:getChildByTag(105):getChildByTag(-17):getChildByTag(-10)
      if aTableData.achieveType == AchievementTypeEnum.mission then
        local aBattleCountryConfig = MetaManager.battle_country[aTableData.achieveCondition]
        aDes = Localization:getInstance():getText("achieve_task_pass", {num1 = Localization:getInstance():getText(aBattleCountryConfig.cityNameKey)})
      elseif aTableData.achieveType == AchievementTypeEnum.level then
        aDes = Localization:getInstance():getText("achieve_task_level", {num1 = aTableData.achieveCondition})
      elseif aTableData.achieveType == AchievementTypeEnum.elite then
        local aBattleCountryConfig = MetaManager.battle_country[aTableData.achieveCondition]
        aDes = Localization:getInstance():getText("achieve_task_pass", {num1 = Localization:getInstance():getText(aBattleCountryConfig.cityNameKey)})
      elseif aTableData.achieveType == AchievementTypeEnum.collectCard then
        CardBookProgress(aTableData) --获取收集卡牌进度
       
        if progress ~= nil then
          
          local aDesCeiling = Localization:getInstance():getText(progress.."/"..aRewardPackageConfig.cardNum)
          aCell:getChildByTag(105):getChildByTag(-16):setVisible(true)
          
          local aDesCeilingLabel = aCell:getChildByTag(105):getChildByTag(-16):getChildByTag(-10) --进度
          setNodeText(aDesCeilingLabel, aDesCeiling)
          local CountryKey = nil
          if aRewardPackageConfig.countryType == 1 then
            CountryKey = "CardCollectionWei_Text"
          elseif aRewardPackageConfig.countryType == 2  then
            CountryKey = "CardCollectionShu_Text"
          elseif aRewardPackageConfig.countryType == 3 then
            CountryKey = "CardCollectionWu_Text"
          elseif aRewardPackageConfig.countryType == 4  then
            CountryKey = "CardCollectionQun_Text"
          end
          
            if aRewardPackageConfig.content1Amount ~= 1 then
              
              aCell:getChildByTag(105):getChildByTag(-17):setZOrder(10)
              aCell:getChildByTag(105):getChildByTag(-17):setVisible(true)
              local RewardNumText = "X"..aRewardPackageConfig.content1Amount
              setNodeText(RewardNumLabel, RewardNumText)
            end
         
          if CountryKey then
            aDes = Localization:getInstance():getText(CountryKey..aRewardPackageConfig.id)
          end
        end
      end
      
      setNodeText(aDesLabel, aDes)
     
      local challangeLabel = aButtonDisplay:getChildByTag(-10)
      local challangBg = aButtonDisplay:getChildByTag(-11)
       
      local aStatus = getStatusForAchievement(aTableData)
      if (aStatus == 3) then
        aButtonDisplay.ignoreTouch = true
        setNodeText(challangeLabel, Localization:getInstance():getText("achieve_task_got"))
        challangBg:setVisible(false)
      elseif (aStatus == 1) then
        aButtonDisplay.ignoreTouch = false
        setNodeText(challangeLabel, Localization:getInstance():getText("achieve_task_get"))
        challangBg:setVisible(true)
      else
        aButtonDisplay.ignoreTouch = true
        setNodeText(challangeLabel, Localization:getInstance():getText("achieve_task_get"))
        challangBg:setVisible(false)
      end
    end
  end
  

  local function onListItemTouch( evt )
    -- print("______________PPPPPPPP")

    --创建图标
      -- local function IconBtnAction(evt)
      --   print("////////////////////////////////////123")
      --   local para = evt.context
      --   CanonGoodIcon.popoutGoodPanel(aRewardPackageConfig.content1Type, aRewardPackageConfig.content1Id)
      -- end
   --AchievementType
-- AchievementReward
    local aIndex = evt.data + 1
    if aIndex == 1 then
      if ControlLevelCellJude then
        self:JudeCellButton(AchievementTypeEnum.level,self.LevelTab,1,ControlLevelCellJude)
        ControlLevelCellJude = false
      else
        self:JudeCellButton(AchievementTypeEnum.level,self.LevelTab,#self.LevelTab,ControlLevelCellJude)
        ControlLevelCellJude = true
    end
  
    
    elseif aIndex == CellNumberList[1]+1 then
      
      if ControlMissionCellJude then
        self:JudeCellButton(AchievementTypeEnum.mission,self.MissionTab,1,ControlMissionCellJude)
        ControlMissionCellJude = false
      else
        self:JudeCellButton(AchievementTypeEnum.mission,self.MissionTab,#self.MissionTab,ControlMissionCellJude)
        ControlMissionCellJude = true
      end
    elseif aIndex == CellNumberList[1]+1+CellNumberList[2] then
    
      if ControlEliteCellJude then
        self:JudeCellButton(AchievementTypeEnum.elite,self.EliteTab,1,ControlEliteCellJude)
        ControlEliteCellJude = false
      else
         self:JudeCellButton(AchievementTypeEnum.elite,self.EliteTab,#self.EliteTab,ControlEliteCellJude)
        ControlEliteCellJude = true
      end
    elseif  aIndex == CellNumberList[1]+1+CellNumberList[2]+CellNumberList[3] then
      if ControlCollectCardCellJude then
        self:JudeCellButton(AchievementTypeEnum.collectCard,self.CollectCardTab,1,ControlCollectCardCellJude)
        ControlCollectCardCellJude = false
      else
        self:JudeCellButton(AchievementTypeEnum.collectCard,self.CollectCardTab,#self.CollectCardTab,ControlCollectCardCellJude)
        ControlCollectCardCellJude = true
      end
    end

   
    local newCell = self.tableView:cellAtIndex(aIndex - 1)
    if newCell then 
      local posInCell = newCell:convertToNodeSpace(evt.globalPosition)

      local btnDisplay = newCell:getChildByTag(cellTag):getChildByTag(105)
      local buttonDisplay = btnDisplay:getChildByTag(-14)
      local iconDisplay = btnDisplay:getChildByTag(-10)
      local challengeDisplay = buttonDisplay:getChildByTag(-11)
      exchangeDisplay = iconDisplay
      exchangeSize = HeDisplayUtil:getNodeGroupBounds(exchangeDisplay, nil, kHitAreaObjectTag).size
      if posInCell.x > buttonDisplay:getPositionX() and
        posInCell.x < (buttonDisplay:getPositionX() + challengeDisplay:getContentSize().width) and
        posInCell.y > (buttonDisplay:getPositionY() - challengeDisplay:getContentSize().height) and
        posInCell.y < buttonDisplay:getPositionY() then
        if challengeDisplay and btnDisplay:isVisible() and challengeDisplay:isVisible() then
          self:receiveAchievement(self.tableData[aIndex],aIndex)
        end
      elseif posInCell.x > (iconDisplay:getPositionX()) and
        posInCell.x < (iconDisplay:getPositionX() + exchangeSize.width) and
        posInCell.y > (iconDisplay:getPositionY() - exchangeSize.height) and
        posInCell.y < (iconDisplay:getPositionY()) then
        
        local AchievementConfig =  self.tableData[aIndex]
        local AchievementReward = {}
        if AchievementConfig.achieveType == 4 then
          local RewardTable = MetaManager.atlas_Reward
          
          for _,aConfig in pairs(RewardTable) do
            if aConfig.id == AchievementConfig.achieveCondition then
              AchievementReward.content1Type = aConfig.rewardType
              AchievementReward.content1Id = aConfig.rewardID
              AchievementReward.content1Amount = aConfig.rewardNum
            end  
          end

          if AchievementReward.content1Id and AchievementReward.content1Id ~= 0 then  
            CanonGoodIcon.popoutGoodPanel(AchievementReward.content1Type, AchievementReward.content1Id)
          end
        end 
      end
    end
  end
  local renderer = AchievementTableViewRenderer.new(self.table_meta_info.item_width, self.table_meta_info.item_height)
  local aTableView = TableView:create(renderer, self.table_meta_info.table_width, self.table_meta_info.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(self.table_meta_info.table_posX, self.table_meta_info.table_posY))
  
  local function SchedulerFun()
  
    self:showTextFinish()
  end
  if not self.showTextFunc then

    self.showTextFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( SchedulerFun, 1/60, false)
  end
  return aTableView
end

local function isCurVipMaxLevel(level)--判断VIPLEVEL是否为最大
	local maxLevel = 0
	for k,v in pairs(MetaManager.vip_setting) do
		if maxLevel < v.level then
			maxLevel = v.level
		end
	end
	return level >= maxLevel
end

local function getCurVipInfo()--获取当前VIP等级相关信息
	local info = {}
	info.level = tonumber(DataManager.getCurrUser().vipLevel)
	info.levelupCurGold = tonumber(DataManager.getCurrUser().rechargeGems + DataManager.getCurrUser().vipExp)
	if isCurVipMaxLevel(info.level) then
		info.levelupTotalGold = MetaManager.vip_setting[info.level].requireGold
	else
		info.levelupTotalGold = MetaManager.vip_setting[info.level + 1].requireGold
	end
	return info
end


function AchievementScene:JudeCellButton(ControlCellNum,ControlCellTab,ControlCellTabNum,ControlCellJude)
  self:DeleteScheduler()
  if self.tableView then
    self.tableView:removeFromParentAndCleanup(true)
    self.tableView = nil
    
  end
   
    CellNumberList[ControlCellNum] = ControlCellTabNum
    --创建新的cell
    self.tableData =self:CreateNewList(ControlCellNum,ControlCellJude,ControlCellTab)
    self.tableView = self:createTableView()
    mainUI:addChildAt(self.tableView, 2)
    
    OriginalOffset = self.tableView:getContentOffset()
     -- print("______________________________self.CellNum = "..self.CellNum)
     local TotalCellNum = {}
    TotalCellNum[1] = 0
    for i,v in ipairs(CellNumberList) do
      TotalCellNum[i+1] = v+TotalCellNum[i]
    end

    self.tableView:reloadData()

    if ControlCellNum ~= 1 then--[[
        if ControlCellNum == 2 and CellNumberList[1] == 1 then
          self.tableView:setContentOffsetInDuration(ccp(0,OriginalOffset.y+(TotalCellNum[ControlCellNum]-1)*self.table_meta_info.item_height),1/100)
        elseif ControlCellNum == 3 and CellNumberList[2] == 1 and  CellNumberList[1] == 1 then
          self.tableView:setContentOffsetInDuration(ccp(0,OriginalOffset.y+(TotalCellNum[ControlCellNum]-2)*self.table_meta_info.item_height),1/100)
        elseif ControlCellNum == 4 and CellNumberList[2] == 1 and  CellNumberList[1] == 1 and CellNumberList[3] == 1 then
          self.tableView:setContentOffsetInDuration(ccp(0,OriginalOffset.y+(TotalCellNum[ControlCellNum]-3)*self.table_meta_info.item_height),1/100)
        else
          self.tableView:setContentOffsetInDuration(ccp(0,OriginalOffset.y+(TotalCellNum[ControlCellNum])*self.table_meta_info.item_height),1/100)
        end]]
        
    if OriginalOffset.y >= 0 then
      
      self.tableView:setContentOffset(ccp(0,OriginalOffset.y--[[+(AchievementTypeNum*self.table_meta_info.item_height)]]))
    else
      self.tableView:setContentOffset(ccp(0,OriginalOffset.y+(TotalCellNum[ControlCellNum])*self.table_meta_info.item_height))
    end

  end
      
end

function AchievementScene:CreateNewList(num,judeControl,CellTab) --num 第几个广告Cell ，开关，Cell 表
  -- local TotalCellNum = {}
  -- TotalCellNum[1] = CellNumberList[1] 
  -- TotalCellNum[2] = CellNumberList[1] +CellNumberList[2] 
  -- TotalCellNum[3] = CellNumberList[1] +CellNumberList[2] + CellNumberList[3]
  
  local TotalCellNum = {}
  for i=1,AchievementTypeNum -1 do
   
    if i ~= 1 then
      TotalCellNum[i] = TotalCellNum[i -1] +CellNumberList[i] 
    else
      TotalCellNum[i] = CellNumberList[i] 
    end
  end
  local keynum = 0
  if num ~= AchievementTypeEnum.level then
    keynum = TotalCellNum[num-1]
  end
  if  not judeControl then
    for i,v in ipairs(CellTab) do
      if i ~=1 then
        table.insert(self.NewDataTable,keynum+i,v)
      end
    end
  else
    for i=#CellTab,2,-1 do
      table.remove(self.NewDataTable,keynum+i)
    end
  end

  -- print("________________________________新的表 = "..tostringRich(self.NewDataTable))
  return self.NewDataTable
end

function AchievementScene:receiveAchievement(aData,index)
  if BagCalcManager.isFull() then
    NewPackageFullPanel:show()
    return
  end
  
  local scene = Director:mgr():run()
	local function onSucceed(requestEvent)
		GainAchievementRewardRequest.onSucceedDefault(requestEvent)
    
    local oldVipExp = DataManager.getCurrUser().vipExp 
    local function checkVipExp()
      if oldVipExp < DataManager.getCurrUser().vipExp then
        local vipInfo = getCurVipInfo()
        vipInfo.isMaxLevel = isCurVipMaxLevel(vipInfo.level)
        local aPanel = VipPrivilegePanel:create(self, vipInfo, true)
        PopoutManager:sharedManager():popout(aPanel, kPopoutDir.kScale, true, false ,self)
      end
    end
    
    RewardManager:getReward(requestEvent.data.reward) --将奖励放到背包里面
    local achievements = DataManager.getSharkAchievements()
    local existed = false
    for _, aAchievement in pairs(achievements) do
      if aAchievement.achievementConfigId == aData.achieveId then
        aAchievement.status = 3
        statusList[aData.achieveId] = 3
        existed = true
        break
      end
    end
    if not existed then
      local temp = {}
      temp.achievementConfigId = aData.achieveId
      temp.status = 3
      statusList[aData.achieveId] = 3
      table.insert(achievements, temp)
    end
    DataManager.setSharkAchievements(achievements)
    
    local offsetY = self.tableView:getContentOffset().y
    -- self:changeToList()
    local TotalCellNum = {}
    for i=1,AchievementTypeNum do
      if i ~= 1 then
        TotalCellNum[i] = TotalCellNum[i -1] +CellNumberList[i] 
      else
        TotalCellNum[i] = CellNumberList[i] 
      end
    end

    self:NewTableList(index,aData.achieveType,TotalCellNum)
    self.tableView:reloadData()
    local function SchedulerFun()
  
      self:showTextFinish()
    end
    if not self.showTextFunc then

      self.showTextFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( SchedulerFun, 1/60, false)
    end
    local offset = 0
    if aData.achieveType == 1  then
      offsetY = OriginalOffset.y
    else
      offsetY = OriginalOffset.y+TotalCellNum[aData.achieveType -1]*self.table_meta_info.item_height
    end
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~offsetY = "..offsetY)
    self.tableView:setContentOffset(ccp(0, offsetY), false)
    self:resetTipUI()
    local aRewardPanel = RewardReviewPanel:create( self, {rewardList = requestEvent.data.reward, rewardTitle = Localization:getInstance():getText("achieve_task_package"), callback = checkVipExp} )
    self:addChild(aRewardPanel)
    aRewardPanel:scaleIn()
	end
  -- print("_________________________________aData.achieveType = "..aData.achieveType)
  -- print("_________________________________aData.achieveId = "..aData.achieveId)
	GainAchievementRewardRequest.sendRequest(onSucceed, GainAchievementRewardRequest.onFailedDefault, {achievementType = aData.achieveType, achievementId = aData.achieveId})
end
function AchievementScene:NewTableList(achieveId,achieveType,TotalCellNum)
  self:DeleteScheduler()

  if self.tableView then
    self.tableView:removeFromParentAndCleanup(true)
    self.tableView = nil
  end
  local CellMessage = self.NewDataTable[achieveId]
  table.remove(self.NewDataTable,achieveId)
  
  

  table.insert(self.NewDataTable,TotalCellNum[achieveType],CellMessage)
  self.tableData = self.NewDataTable
  self.tableView = self:createTableView()
  mainUI:addChildAt(self.tableView, 2)
  
  OriginalOffset = self.tableView:getContentOffset()
  --重新排序列表
  self.LevelTab = getTableData(AchievementTypeEnum.level)
  self.MissionTab = getTableData(AchievementTypeEnum.mission) 
  self.EliteTab = getTableData(AchievementTypeEnum.elite) 
  self.CollectCardTab = getTableData(AchievementTypeEnum.collectCard)
end

function AchievementScene:setTableViewsEnabledInner(isEnable)
  if self.tableView then
   
    if TitleADCell then
      -- print("+++++++++++++++++++++++++++isEnable = "..tostringRich(isEnable))
     
      CellImage:setEnabled(isEnable)
    end
   self.tableView:setTouchEnabled(isEnable)
  end
end

function AchievementScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function AchievementScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function AchievementScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  for _, aChild in pairs(mainUI.list) do
    if not (self.ignoreAction and (aChild.name == "btn_tab_activity1" or aChild.name == "btn_tab_activity2" or aChild.name == "btn_tab_activity3")) then
      aChild:setPositionX(aChild:getPositionX() - visibleSize.width)
      local arr = CCArray:create()
      arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
      arr:addObject(CCCallFunc:create(enterActionFinished))
      aChild:runAction(CCSequence:create(arr))
    end
  end
  if self.tableView then
    ViewControlUtil.showTableViewAction(self.tableView, visibleSize)
  end
end

function AchievementScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function AchievementScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function AchievementScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function AchievementScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  if mainUI.list then
    --print("#self.mainUI.list = " .. tostringRich(#self.mainUI.list))
    for _, aChild in pairs(mainUI.list) do
      if not (self.ignoreAction and (aChild.name == "btn_tab_activity1" or aChild.name == "btn_tab_activity2" or aChild.name == "btn_tab_activity3")) then
        local arr = CCArray:create()
        arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
        arr:addObject(CCCallFunc:create(enterActionFinished))
        aChild:runAction(CCSequence:create(arr))
      end
    end
    if self.tableView then
      ViewControlUtil.disappearTableViewAction(self.tableView, visibleSize)
    end
  end
end

function AchievementScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
--停止调度
function AchievementScene:DeleteScheduler()
  RemoveTitleADCell()
  RemoveTitleAD()
  if self.showTextFunc  then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.showTextFunc)
    self.showTextFunc = nil
  end
end

function AchievementScene:back()
  self.ignoreAction = false
	self:replaceScene(MainMenuScene)
	
end

function AchievementScene.isEnable()
  local FeatureName = DataManager.GameMetaData.cardBookFeatureName
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~FeatureName = "..tostringRich(FeatureName))
  local isEnable = false
  if not FeatureName then
    isEnable = false
  else
    isEnable = MaintenanceManager.isActivityOpen(FeatureName)
    
    if SystemManager.debug then
      print("Activity_ExchangeDailyLayer isEnable = " .. tostringRich(isEnable))
    end
  end
  return isEnable
  
end

function AchievementScene.getTipNum()
  CreateMaxFinishedEliteCityId()
  local result = 0
 
  for _, aConfig in pairs(MetaManager.achievement_task) do
    if getStatusForAchievement(aConfig) == 1 then
      result = result + 1
    end
  end
  return result
end
function AchievementScene:dispose()
  ResetFun()
  self:DeleteScheduler()
  AchievementScene.super.dispose(self)
end
