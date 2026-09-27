-- CrossUnionPKLoginScene.lua
-- meilan.xie
-- 2015-4-15
-- GvG登陆场景
require "canon.features.crossUnionPk.panel.CrossUnionRewardPreviewPanel"
require "canon.features.crossUnionPk.request.CrossUnionPkGetCrossGvgInfoBaseRequest"
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local enter_animation_duration = 0.3

--<property code="out" type="int" desc="当前状态-1.军团没有报名，2.所在服参赛军团不够四个（失去比赛资格），3.军团排名不是前四强，4.被淘汰，5.成功晋级" />
local  KnockoutType = {
                        NoApple = 1, --军团没有报名
                        ApplyNotEnoughFour = 2,--所在服参赛军团不够四个
                        ArmyRankFour = 3,--军团排名不是前四强
                        Knock = 4,--被淘汰了
                        promoted = 5 -- 晋级了

   
                      }

local BtnStatusName = nil --这个是按钮的状态
CrossUnionPKLoginScene = class(BaseUIScene)

--焦点变化事件
local function onFocusChanged(evt)
  local self = evt.context
  
end
--时间段更新事件
local function onTimelevelUpdate(evt)
  local self = evt.context
  if CrossUnionPkTimeLevel.TimeLevel == CrossUnionPkConsts.TIME_WORSHIP then
    CrossUnionPk.gotoCrossLoginUnionPkScene()
  else
    local function onAfterSucceed(evt)
      self.argv.data.groupId = evt.data.groupId
      self.argv.data.out = evt.data.out
      UnionManager.setGainCrossUnionWarInunionApplyCrossGvg(evt.data.unionApplyCrossGvg)
      UnionManager.setGainCrossUnionWarInselfApplyCrossGvg(evt.data.selfApplyCrossGvg)
      UnionManager.setGainCrossUnionWarIncrossGvgVersion(evt.data.crossGvgVersion)
      if CrossUnionPkTimeLevel.TimeLevel ~= CrossUnionPkConsts.TIME_ARMY2_GROUP  then
        self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_21"):setVisible(false)
        self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_22"):setVisible(false)
      end
      self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_08"):setVisible(false)
      self.ui:getChildByName("txt_Gvg_09_3"):setVisible(false)
      
      if CrossUnionPkTimeLevel.TimeLevel then
        self:RefreshButAndTextByTime(CrossUnionPkTimeLevel.TimeLevel)
      end
    end
    CrossUnionPkGetCrossGvgInfoBaseRequest.sendRequestDefalut(onAfterSucceed)
  end 
end

function CrossUnionPKLoginScene:ctor()
end

function CrossUnionPKLoginScene.clear()
  BtnStatusName = nil
end
function CrossUnionPKLoginScene:create(argv)
	local s = CrossUnionPKLoginScene.new()
	if argv then 
		s.argv = argv 
	else
		s.argv = {enterScene=nil,returnScene=nil,params={}}
	end
	s.curSceneEnum = SceneEnum.CrossUnionPKLoginScene

	--当前显示中的列表内容(注意: 子panel可能读取)
	s.selectedDataList = {}
	s:initScene()
	return s
end
--点击返回
local function onBackBtnClick(evt)
  local self = evt.context
  self:back()
end


--点击问号
local function onQaBtnClick(evt)
  local self = evt.context
  -- self:setTableViewsEnabled(false)
  --ReNameCoolingPanel
  local aInfoPanel = ActivityInfoPanel:create(self, getTextByKey("WGVG_Detail44"))
  self:addChild(aInfoPanel)
  aInfoPanel:scaleIn()
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~打开问号按钮")
end

function CrossUnionPKLoginScene:BtnUnVisableStatus(adjude)
    self.ui:getChildByName("btn_bles_big"):getChildByName("normal"):setVisible(adjude)
end 

function CrossUnionPKLoginScene:AlterText(txt,Times)
    --txt_Gvg_09_3
    self.ui:getChildByName("txt_Gvg_09_3"):setVisible(true)
    if Times then
      self.ui:getChildByName("txt_Gvg_09_3"):getChildByName("txt"):setString(getTextByKey(txt,{time = Times}))
    else
      self.ui:getChildByName("txt_Gvg_09_3"):getChildByName("txt"):setString(getTextByKey(txt))
    end
end

function CrossUnionPKLoginScene:UnionBtnStatus(adjude1,adjude2,text) -- 按钮置灰判断   按钮可点击判断  
  self:BtnUnVisableStatus(adjude1)
  self.ApplyButton:setEnable(adjude2)
  self.ui:getChildByName("btn_bles_big"):getChildByName("txt"):setString(getTextByKey(text))--设置按钮上面的文字
end


--点击报名
local function onApplyBtnClick(evt)
  local self = evt.context
  local nameId = UnionManager.getMyTitle()
  -- self:ApplyDemand(nameId)
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~点击报名 = "..nameId)
  --
  local function StopCountDown()
    if self.cdLabelComponent then
      self.cdLabelComponent:dispose()
      self.cdLabelComponent = nil
      self.ui:getChildByName("txt_Gvg_09_3"):setVisible(false)
    end
  end
  local function SucceedResponse(evt)
    -- print("~~~~~~~~~~~~~~~~~evt = "..tostringRich(evt))
    if evt.params.type == 1 then
      UnionManager.setGainCrossUnionWarInselfApplyCrossGvg(false)
    elseif evt.params.type == 0 then
      UnionManager.setGainCrossUnionWarInunionApplyCrossGvg(false)
    end
    StopCountDown()
    self:UnionBtnStatus(false,false,"已报名")
  end
  if BtnStatusName then
    if BtnStatusName == "MANAGERPanel" then --军团不到十级的弹框
      CanonMessageBox.showTextBox(getTextByKey("WGVG_Detail06"), nil)
    elseif BtnStatusName == "MEMBERRequest" then --团员报名请求
      CrossUnionPkGetApplyRequest.sendRequestDefalut({type = 1} ,SucceedResponse)
    elseif BtnStatusName == "MANAGERRequest" then  --军团报名请求
      CrossUnionPkGetApplyRequest.sendRequestDefalut({type = 0} ,SucceedResponse)
    elseif BtnStatusName == "ReplacePrepareScene" then --跳转进入战场
      StopCountDown()
      CrossUnionPk.gotoTeamAdjustScene()
    elseif BtnStatusName == "ReplaceWatchScene" then  --跳转观战 
      --CrossUnionPk.popGroupReport()
      CrossUnionPk.gotoKnockoutScene()
      StopCountDown()
    end
  end

end


--点击奖励
local function onRewardBtnClick(evt)
  local self = evt.context
   -- self:setTableViewsEnabled(false)
  --ReNameCoolingPanel
  
  local aInfoPanel = CrossUnionRewardPreviewPanel:create(self)
  self:addChild(aInfoPanel)
  aInfoPanel:scaleIn()
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~点击奖励")
end

--[[
local function OnApplyTime()
  -- if   then--是否在活动期间  报名期间

  --   return false
  -- else 
  --   return true
  -- end
end


--对军团成员按钮和时间的显示
local function MEMBERBtnAndTimeVisible()
  -- if then --报名了
  --   return false
  -- elseif then --所处军团是否报名
  --   --设置军团成员的剩余时间
  --   return true 
  -- end
end

local function MANAGERBtnAndTimeVisible()
  if  then --军团报名了
    return  false
  end
  return true
   
end
]]

 


function CrossUnionPKLoginScene:onInit()
	BaseUIScene.initBackGround(self)
  local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("GvG_prepare")
	self:addChild(ui)
	self.ui = ui

  local titleUI = builder:build("Gvg_colosseuml_title")
	self.titleUI = titleUI
	self.titleUI:setPositionY(visibleSize.height-35)
	self:addChild(titleUI)
  self.titleUI:getChildByName("icon_gold"):setVisible(false)
  self.titleUI:getChildByName("icon_silverCoin"):setVisible(false)
  -- self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_08"):setVisible(false)
  self.titleUI:getChildByName("icon_Gvg_ranking"):setVisible(false)

  --按钮
  local backButton = Button:create(self.titleUI:getChildByName("r_click"))
  backButton:addEventListener(Events.kStart, onBackBtnClick, self)
  
  local qaButton = Button:create(self.titleUI:getChildByName("sky_btn_qa"))
  qaButton:addEventListener(Events.kStart, onQaBtnClick, self)

  self.ApplyButton = Button:create(self.ui:getChildByName("btn_bles_big"))
  self.ApplyButton:addEventListener(Events.kStart, onApplyBtnClick, self)

  local RewardButton = Button:create(self.ui:getChildByName("icon_reward_tab"))
  RewardButton:addEventListener(Events.kStart, onRewardBtnClick, self)
  
  
  local TimeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
  -- print("~~~~~~~~~~~~~~~~~~~~~~TimeLevel = "..TimeLevel)
  
  self.cdLabelComponent = CdLabelComponent:create()

  self.IDentity = UnionManager.getMyTitle() --这个是判断职务

  UnionManager.eventDispatcher:addEventListener(CrossUnionPkConsts.UNIONPK_TIMELEVEL_PASSED, onTimelevelUpdate, self)
  --事件侦听
  UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
  CrossUnionPkTimeLevel.startup(TimeLevel)
  self:RefreshButAndTextByTime(TimeLevel) --显示对应的Ui内容
  -- self:RefreshButAndTextByTime(5)
   -- self:CountDown()
  BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)
end


--倒计时
function CrossUnionPKLoginScene:CountDown(timeLevel,text)
  -- print("timeLevel = " .. tostringRich(timeLevel))
  -- print("text = " .. tostringRich(text))
  --添加倒计时
  local function onTimeComplete()
    
    if self.cdLabelComponent then
      self.cdLabelComponent:dispose()
      self.cdLabelComponent = nil
    end
  end
  

  local currTime = TimeUtil.getServerTimeSeconds()
  local function onTimeTick(remainedSec)
    local formatedTimeStr = TimeUtil.formatTime(remainedSec)
    -- print(remainedSec)
    -- LevelTimeMeta.uwarContinueTime = remainedSec /60
    -- print("~~~~~~~~~~~~~~~~~~~~~LevelTimeMeta.uwarContinueTime = "..LevelTimeMeta.uwarContinueTime)
    if timeLevel == CrossUnionPkConsts.TIME_ARMY2_GROUP then 
      local adjude = self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_21"):isVisible()
      -- print("~~~~~~~~~~~~~~~~~~~~adjude = "..tostringRich(adjude))
      if not adjude  then
       -- print("~~~~~~~~~~~~~~~~~~~~~~~~~设置显示状态")
       self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_21"):setVisible(true)
       self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_22"):setVisible(true)
      end
        self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_21"):getChildByName("txt"):setString(getTextByKey(text))
        self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_22"):getChildByName("txt"):setString(" "..formatedTimeStr)
    else
      self:AlterText(text,formatedTimeStr)
    end
  end
  
  
  self.cdLabelComponent:setCallback(onTimeTick, onTimeComplete)
  local startTime, endTime = CrossUnionPkUtils.findTImeLevelStartAndEndTime(timeLevel) --这个接口不支持跨界
  self.cdLabelComponent:setTargetTime(endTime)
  self.cdLabelComponent:start()
end


function CrossUnionPKLoginScene:RefreshButAndTextByTime(timeLevel)
 
  local  time = nil
  -- print("~~~~~~~~~~~~~~~UnionManager.getGainCrossUnionWarInunionApplyCrossGvg() = "..tostringRich(UnionManager.getGainCrossUnionWarInunionApplyCrossGvg()))
  -- print("~~~~~~~~~~~~~~~~UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() = "..tostringRich(UnionManager.getGainCrossUnionWarInselfApplyCrossGvg()))
  if timeLevel == CrossUnionPkConsts.TIME_ARMY_APPLY then
    self:ResetTitleText("WGVG_Detail41")
    -- self:ResetTime("WGVG_Detail03","")
    self:AdjudeTimeFun(CrossUnionPkConsts.TIME_ARMY_APPLY,"WGVG_Detail03",false)
    self:AdjudeTimeFun(CrossUnionPkConsts.TIME_MEMBER_APPLY,"WGVG_Detail58",true)
    if UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() then --已报名

      self:UnionBtnStatus(false,false,"WGVG_Name30")
    elseif UnionManager.getGainCrossUnionWarInselfQuitCrossGvg() then
      self:UnionBtnStatus(false,false,"WGVG_Detail37") 
    else 
      if self.IDentity == UnionManager.TITLE_ELITE_MEMBER  or  self.IDentity == UnionManager.TITLE_MEMBER  then --团员
        
        if UnionManager.getGainCrossUnionWarInunionApplyCrossGvg() then --如果军团已报名
           self:ResetTitleText("WGVG_Detail67")
          --团员请求报名
          self:UnionBtnStatus(true,true,"WGVG_Detail66")
          self:AdjudeTimeFun(CrossUnionPkConsts.TIME_MEMBER_APPLY,"WGVG_Detail58",false)
          self:AdjudeTimeFun(CrossUnionPkConsts.TIME_ARMY1_PREPARE,"WGVG_Detail05",true)
          BtnStatusName = "MEMBERRequest"
          self:AlterText("WGVG_Detail23")
          -- self:CountDown(CrossUnionPkConsts.TIME_MEMBER_APPLY ,"WGVG_Detail23")
          -- AlterText("WGVG_Detail22",time) --倒计时
        else  --军团没有报名
          
          -- time = "" --军团的剩余时间
          self:UnionBtnStatus(false,false,"UnionWar_sign_title2")
          self:CountDown(CrossUnionPkConsts.TIME_ARMY_APPLY,"WGVG_Detail22")
          -- AlterText("WGVG_Detail22",time) --按钮置灰   按钮下方给出文字解释  倒计时
        end

      elseif self.IDentity == UnionManager.TITLE_MANAGER or  self.IDentity == UnionManager.TITLE_VICE_MANAGER then
        --倒计时

        
        if UnionManager.getGainCrossUnionWarInunionApplyCrossGvg() then --军团已经报名
          self:UnionBtnStatus(true,true,"WGVG_Detail66")
          self:ResetTitleText("WGVG_Detail67")
          self:AdjudeTimeFun(CrossUnionPkConsts.TIME_MEMBER_APPLY,"WGVG_Detail58",false)
          self:AdjudeTimeFun(CrossUnionPkConsts.TIME_ARMY1_PREPARE,"WGVG_Detail05",true)
          BtnStatusName = "MEMBERRequest"
          -- self:CountDown(CrossUnionPkConsts.TIME_MEMBER_APPLY ,"WGVG_Detail23")
          self:AlterText("WGVG_Detail23")
        else
          self:UnionBtnStatus(true,true,"UnionWar_sign_title2")
          if UnionManager.getUnionLevel() >= 10 then -- CrossUnionPkCheck.canManagerApply(timeLevel) then

             --团长请求报名
             BtnStatusName = "MANAGERRequest"
          else
            --团长弹框军团不到十级
            BtnStatusName = "MANAGERPanel" --MANAGERPanel
            
          end
          self:CountDown(CrossUnionPkConsts.TIME_ARMY_APPLY,"WGVG_Detail22")
        end 
      end
     
    end
  elseif timeLevel == CrossUnionPkConsts.TIME_MEMBER_APPLY then
    self:ResetTitleText("WGVG_Detail67") 
    -- self:ResetTime("WGVG_Detail03","")
    self:AdjudeTimeFun(CrossUnionPkConsts.TIME_MEMBER_APPLY,"WGVG_Detail58",false)
    self:AdjudeTimeFun(CrossUnionPkConsts.TIME_ARMY1_PREPARE,"WGVG_Detail05",true)
    if UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() then --已报名
      self:UnionBtnStatus(false,false,"WGVG_Name30")
    elseif UnionManager.getGainCrossUnionWarInselfQuitCrossGvg() then
      self:UnionBtnStatus(false,false,"WGVG_Detail37") 
    else 
      --军团长
      -- if self.IDentity == UnionManager.TITLE_MANAGER or  self.IDentity == UnionManager.TITLE_VICE_MANAGER then
        if UnionManager.getGainCrossUnionWarInunionApplyCrossGvg() then
          --团员倒计时
          -- self:CountDown(CrossUnionPkConsts.TIME_MEMBER_APPLY ,"WGVG_Detail23")
          self:AlterText("WGVG_Detail23")
          self:UnionBtnStatus(true,true,"WGVG_Detail66")
          BtnStatusName = "MEMBERRequest"
        else
          self:UnionBtnStatus(false,false,"WGVG_Detail37")
          -- self:AlterText("WGVG_Detail22")--错过报名多语言
        end
    end
  
  elseif timeLevel == CrossUnionPkConsts.TIME_ARMY1_PREPARE or timeLevel == CrossUnionPkConsts.TIME_ARMY1_FIGHTING   then
      --小组赛 
      self:ResetTime("WGVG_Detail05","")
      if timeLevel == CrossUnionPkConsts.TIME_ARMY1_PREPARE then 
        self:AdjudeTimeFun(CrossUnionPkConsts.TIME_ARMY1_PREPARE,"WGVG_Detail05",false)
        self:AdjudeTimeFun(CrossUnionPkConsts.TIME_ARMY1_FIGHTING,"WGVG_Detail70",true)
      else
        self:AdjudeTimeFun(CrossUnionPkConsts.TIME_ARMY1_FIGHTING,"WGVG_Detail70",false)
        self:AdjudeTimeFun(CrossUnionPkConsts.TIME_ARMY2_PREPARE,"WGVG_Detail35",true)
      end
      self:ResetTitleText("WGVG_title04")
      if UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() and UnionManager.getGainCrossUnionWarInunionApplyCrossGvg() and (not UnionManager.getGainCrossUnionWarInselfQuitCrossGvg())  then--已报名
        self:UnionBtnStatus(true,true,"UnionWar_supple_ready") --请求战场  跳转场景
        BtnStatusName = "ReplacePrepareScene"
      else
        self:UnionBtnStatus(false,false,"WGVG_Detail37") --错过报名
      end
     
    ----淘汰赛分组阶段
  elseif timeLevel == CrossUnionPkConsts.TIME_ARMY2_GROUP or timeLevel == CrossUnionPkConsts.TIME_GROUP_REWARD  then 
    self:ResetTextVisible()
    if UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() and (not UnionManager.getGainCrossUnionWarInselfQuitCrossGvg()) then --是否报名
      self:UnionBtnStatus(false,false,"UnionWar_supple_ready") 
    else
      self:UnionBtnStatus(false,false,"WGVG_Name29")
    end
    
    self:CountDown(CrossUnionPkConsts.TIME_ARMY2_GROUP,"WGVG_Detail27")
    -- 倒计时

    
  elseif  timeLevel == CrossUnionPkConsts.TIME_ARMY2_PREPARE  then --淘汰赛准备阶段
    -- self:ResetTime("WGVG_Detail35","")
    self:AdjudeTimeFun(CrossUnionPkConsts.TIME_ARMY2_PREPARE,"WGVG_Detail35",false)
    self:AdjudeTimeFun(CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16,"WGVG_Detail36",true)
    self:ResetTitleText("WGVG_Detail40")
    --[[
    if UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() then --是否报名

      if not self.argv.data.out then --有没有被淘汰
        self:UnionBtnStatus(true,true,"UnionWar_supple_ready") --跳转场景
        BtnStatusName = "ReplacePrepareScene"
      else --被淘汰了
        local text = nil
        if self.argv.data.groupId ~= 0 then --分组Id
          text = "WGVG_Detail33"
        else
          text = "WGVG_Detail34" 
        end
        self:UnionBtnStatus(false,false,"WGVG_Name29")--观战
        self:AlterText(text)--已经被淘汰了
      end
    else
      self:UnionBtnStatus(false,false,"WGVG_Name29")--观战
      self:AlterText("WGVG_Detail24")--没有报名
    end

    local  KnockoutType = {
                        NoApple = 1, --军团没有报名
                        ApplyNotEnoughFour = 2,--所在服参赛军团不够四个
                        ArmyRankFour = 3,--军团排名不是前四强
                        Knock = 4,--被淘汰了
                        promoted = 5 -- 晋级了

   
                      }
    

    ]]
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~self.argv.data.out = "..tostringRich(self.argv.data.out))
    
       
      if self.argv.data.out == KnockoutType.NoApple then 
        -- print("~~~~~~~~~~~~没报名")
        self:UnionBtnStatus(false,false,"WGVG_Name29")--观战
        self:AlterText("WGVG_Detail24")--没有报名
      elseif self.argv.data.out == KnockoutType.ApplyNotEnoughFour then
        self:UnionBtnStatus(false,false,"WGVG_Name29")--观战
        self:AlterText("WGVG_Detail34")--没有报名
        -- print("~~~~~~~~~~~~没报名")
      elseif self.argv.data.out == KnockoutType.ArmyRankFour then
        self:UnionBtnStatus(false,false,"WGVG_Name29")--观战
        self:AlterText("WGVG_Detail33")--没有报名
      elseif self.argv.data.out == KnockoutType.Knock then
        self:UnionBtnStatus(false,false,"WGVG_Name29")--观战
        self:AlterText("WGVG_Detail33")--没有报名
      elseif self.argv.data.out == KnockoutType.promoted then
        if UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() then --是否报名
          self:UnionBtnStatus(true,true,"UnionWar_supple_ready") --跳转场景
          BtnStatusName = "ReplacePrepareScene"
        else
          self:UnionBtnStatus(false,false,"WGVG_Name29")--观战
        end
      end
    
  
  else --淘汰赛战斗阶段  也是观战阶段
    self:ResetTitleText("WGVG_Detail40")
    -- self:ResetTime("WGVG_Detail36","")
    local  BtnName = "WGVG_Name29"
    if self.argv.data.out == KnockoutType.promoted then
        if UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() then --是否报名
          BtnName = "UnionWar_supple_ready"
        end
    end
    self:AdjudeTimeFun(CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16,"WGVG_Detail36",false)
    self:AdjudeTimeFun(CrossUnionPkConsts.TIME_WORSHIP,"WGVG_Detail71",true)
    if self.argv.data.out == KnockoutType.ApplyNotEnoughFour then
      self:UnionBtnStatus(false,false,BtnName)
    else
      self:UnionBtnStatus(true,true,BtnName) --观战 跳转场景
      BtnStatusName = "ReplaceWatchScene"
    end
  end 
end

function CrossUnionPKLoginScene:ResetTextVisible()
  self.ui:getChildByName("txt_Gvg_05"):setVisible(false)
  self.ui:getChildByName("txt_Gvg_09_2"):setVisible(false)
  self.ui:getChildByName("txt_Gvg_05_2"):setVisible(false)
  self.ui:getChildByName("txt_Gvg_09"):setVisible(false)
end
--设置时间的多语言
function CrossUnionPKLoginScene:ResetTime(txt1,time1,adjude)

  if adjude then
    self.ui:getChildByName("txt_Gvg_05"):setVisible(true)
    self.ui:getChildByName("txt_Gvg_09_2"):setVisible(true)
    self.ui:getChildByName("txt_Gvg_05"):getChildByName("txt"):setString(getTextByKey(txt1))
    -- 时间
    self.ui:getChildByName("txt_Gvg_09_2"):getChildByName("txt"):setString(time1)
  else
    --txt_Gvg_05_2
    self.ui:getChildByName("txt_Gvg_05_2"):setVisible(true)
    self.ui:getChildByName("txt_Gvg_09"):setVisible(true)
    self.ui:getChildByName("txt_Gvg_05_2"):getChildByName("txt"):setString(getTextByKey(txt1))
    --时间
    self.ui:getChildByName("txt_Gvg_09"):getChildByName("txt"):setString(time1)
  end
  --
  
  
end

--设置时间的多语言
function CrossUnionPKLoginScene:ResetTitleText(txt2)
 self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_08"):setVisible(true)
 self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_08"):getChildByName("txt"):setString(getTextByKey(txt2))
 -- self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_09"):getChildByName("txt"):setString(getTextByKey(txt1))
 
end

function CrossUnionPKLoginScene:ResetTitleTextandTime(txt,time)
 self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_21"):getChildByName("txt"):setString(getTextByKey(txt))
 self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_22"):getChildByName("txt"):setString(getTextByKey(time))
end

function getStartTimeandEndTimeFun(timeLevel1,timeLevel2)
  if timeLevel1 and timeLevel2 then
    local startTime,endTime = CrossUnionPkUtils.findTImeLevelStartAndEndTime(timeLevel1)
    local startTime1,endTime1 = CrossUnionPkUtils.findTImeLevelStartAndEndTime(timeLevel2)
    return startTime,endTime1
  elseif timeLevel1 then
    local startTime,endTime = CrossUnionPkUtils.findTImeLevelStartAndEndTime(timeLevel1)
    return startTime,endTime
  end
  return nil
end
function CrossUnionPKLoginScene:AdjudeTimeFun(timeLevel,text,adjudeNext)
  local FinalTimeText = nil
  local timeStart = nil
  local timeEnd = nil
  --[[
  if timeLevel == CrossUnionPkConsts.TIME_ARMY_APPLY then
    timeStart, timeEnd = getStartTimeandEndTimeFun(CrossUnionPkConsts.TIME_ARMY_APPLY,CrossUnionPkConsts.TIME_MEMBER_APPLY)
  else
    ]]
  -- if timeLevel == CrossUnionPkConsts.TIME_ARMY1_PREPARE then
  --   timeStart, timeEnd = getStartTimeandEndTimeFun(CrossUnionPkConsts.TIME_ARMY1_PREPARE,CrossUnionPkConsts.TIME_ARMY1_FIGHTING)
  -- else
  if timeLevel == CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16 then
    timeStart, timeEnd = getStartTimeandEndTimeFun(CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16,CrossUnionPkConsts.TIME_ARMY2_FIGHTING_CHAMPION)
  else
    timeStart, timeEnd = getStartTimeandEndTimeFun(timeLevel)
  end
  timeStart = UnionPkUtils.formatDate(timeStart)
  timeEnd = UnionPkUtils.formatDate(timeEnd)
  FinalTimeText = timeStart.."-"..timeEnd
  
  self:ResetTime(text,FinalTimeText,adjudeNext)
  
  
  
end

function CrossUnionPKLoginScene:dispose()
  if self.cdLabelComponent then
    self.cdLabelComponent:dispose()
    self.cdLabelComponent = nil
  end
  UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
  UnionManager.eventDispatcher:removeEventListener(CrossUnionPkConsts.UNIONPK_TIMELEVEL_PASSED, onTimelevelUpdate)
  CrossUnionPKLoginScene.clear()
  CrossUnionPkTimeLevel.clear()
  
  CrossUnionPKLoginScene.super.dispose(self)
end

function CrossUnionPKLoginScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function CrossUnionPKLoginScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  
end

function CrossUnionPKLoginScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.ui:setPositionX(self.ui:getPositionX() - visibleSize.width)
  self.ui:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  
  
  local aHeight = self.titleUI:getGroupBounds().size.height

  self.titleUI:setPositionY(self.titleUI:getPositionY() + aHeight)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(0, -aHeight)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.titleUI:runAction(CCSequence:create(arr))
  
end

function CrossUnionPKLoginScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
end

function CrossUnionPKLoginScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function CrossUnionPKLoginScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  
end

function CrossUnionPKLoginScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.ui:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  
  local aHeight = self.titleUI:getGroupBounds().size.height
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(0, aHeight)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.titleUI:runAction(CCSequence:create(arr))
  
end

function CrossUnionPKLoginScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function CrossUnionPKLoginScene:back()
  if self.argv.enterScene == "UnionScene" then
  
    UnionManager.gotoUnionScene()
  end
end
