--限时奖励
require "hecore.display.CocosObject"
require "hecore.display.Director"
require "canon.scene.ShopScene"
require "canon.data.DataManager"
require "canon.panel.ActivityInfoPanel"
require "canon.utils.TimeUtil"
require "canon.customUI.CdLabelComponent"
require "canon.request.ActiveRechangeRequest"


--天数转秒
local function DaytoSecond(Daytime)
    return Daytime*60*60
end

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_rechargeLayer = class(Layer)



function Activity_rechargeLayer:ctor()
  self.container = nil
  --记录你领取了几个物品
  self.rewardCount=0

end

function Activity_rechargeLayer:create( container , extraArgs)
  self.container = container
  self.extraArgs = extraArgs
  self.MustAchieveMoneyList = {}
  self.RewardIdList = {}  --领奖Id
  self.BtnTableList = {}  --三个按钮的表
  self.RewardProgressList = {}  --已领取奖励表
  self.TotalMoneyList = {} 
  self.StageTimeList = {}
  --造的假数据
  --造的假数据
  -- self.TotalMoneyList = {60,0,0}
  -- self.RewardProgressList = {1,2,3}
  -- self.TotalMoneyList = self.extraArgs.recharge
  self.TotalMoneyList = Activity_rechargeLayer.getRechargeData().recharge
  -- self.RewardProgressList = self.extraArgs.rewards
  self.RewardProgressList = Activity_rechargeLayer.getRechargeData().rewards
  local s = Activity_rechargeLayer.new()
  s:initLayer()
  return s
end

function Activity_rechargeLayer:initLayer()
 
	Activity_rechargeLayer.super.initLayer(self)

    --导入falsh
  self.builder = LayoutBuilder:createWithContentsOfFile("scene/limited_timeReward.json")
  self.builder.useArtLabelTTF = true
  self.mainUI = self.builder:build("limited_timeReward")
  self:addChild(self.mainUI)


      
  local bgPosX,bgPosY = self.mainUI:getChildByName("bigCard"):getPositionX(),self.mainUI:getChildByName("bigCard"):getPositionY()
  -- print(bgPosX,bgPosY)
  self.mainUI:getChildByName("bigCard"):setVisible(false)
  --这里要添加一个精灵
  local card3_spf = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(101111))
  card3_spf:setPosition(ccp(bgPosX-250,bgPosY-350))
  card3_spf.refCocosObj:setFlipX(true)
  card3_spf:setScale(1.5)
  self.mainUI:addChildAt(card3_spf, 3)
   
   --去充值文字
   self.mainUI:getChildByName("btn_topUp_go"):getChildByName("txt"):setString(getTextByKey("chargeMoney_go"))
   
   --领奖  文字
   self.mainUI:getChildByName("list_limited_timeReward1"):getChildByName("btn_nowbuy"):getChildByName("txt"):setString(getTextByKey("Limit-Reward002"))
   self.mainUI:getChildByName("list_limited_timeReward2"):getChildByName("btn_nowbuy"):getChildByName("txt"):setString(getTextByKey("Limit-Reward002"))
   self.mainUI:getChildByName("list_limited_timeReward3"):getChildByName("btn_nowbuy"):getChildByName("txt"):setString(getTextByKey("Limit-Reward002"))
   

   --配置领取的物品说明
   self.mainUI:getChildByName("list_limited_timeReward1"):getChildByName("txt_LTR_04"):getChildByName("txt"):setString(getTextByKey("Limit-Reward003"))
   self.mainUI:getChildByName("list_limited_timeReward2"):getChildByName("txt_LTR_04"):getChildByName("txt"):setString(getTextByKey("Limit-Reward004"))
   self.mainUI:getChildByName("list_limited_timeReward3"):getChildByName("txt_LTR_04"):getChildByName("txt"):setString(getTextByKey("Limit-Reward005"))



   self.mainUI:getChildByName("list_limited_timeReward1"):getChildByName("txt_LTR_05"):getChildByName("txt"):setString(getTextByKey("Limit-Reward014"))
   self.mainUI:getChildByName("list_limited_timeReward2"):getChildByName("txt_LTR_05"):getChildByName("txt"):setString(getTextByKey("Limit-Reward015"))
   self.mainUI:getChildByName("list_limited_timeReward3"):getChildByName("txt_LTR_05"):getChildByName("txt"):setString(getTextByKey("Limit-Reward016"))

   self.mainUI:getChildByName("list_limited_timeReward1"):getChildByName("txt_LTR_06"):getChildByName("txt"):setString(getTextByKey("skyTower_remainingStars"))
   self.mainUI:getChildByName("list_limited_timeReward2"):getChildByName("txt_LTR_06"):getChildByName("txt"):setString(getTextByKey("skyTower_remainingStars"))
   self.mainUI:getChildByName("list_limited_timeReward3"):getChildByName("txt_LTR_06"):getChildByName("txt"):setString(getTextByKey("skyTower_remainingStars"))


   self.mainUI:getChildByName("list_limited_timeReward1"):getChildByName("txt_LTR_08"):getChildByName("txt"):setString(getTextByKey("Limit-Reward006"))
   self.mainUI:getChildByName("list_limited_timeReward2"):getChildByName("txt_LTR_08"):getChildByName("txt"):setString(getTextByKey("Limit-Reward006"))
   self.mainUI:getChildByName("list_limited_timeReward3"):getChildByName("txt_LTR_08"):getChildByName("txt"):setString(getTextByKey("Limit-Reward006"))
  
  --章的显示
   self.mainUI:getChildByName("list_limited_timeReward1"):getChildByName("lbl_yicuoguo"):setVisible(false)
   self.mainUI:getChildByName("list_limited_timeReward2"):getChildByName("lbl_yicuoguo"):setVisible(false)
   self.mainUI:getChildByName("list_limited_timeReward3"):getChildByName("lbl_yicuoguo"):setVisible(false)

   self.mainUI:getChildByName("list_limited_timeReward1"):getChildByName("lbl_yilingqu"):setVisible(false)
   self.mainUI:getChildByName("list_limited_timeReward2"):getChildByName("lbl_yilingqu"):setVisible(false)
   self.mainUI:getChildByName("list_limited_timeReward3"):getChildByName("lbl_yilingqu"):setVisible(false)

   --打开宝箱变灰
   self.mainUI:getChildByName("icon_baoxiang_3"):setVisible(true)
   --打开宝箱
   self.mainUI:getChildByName("icon_baoxiang_1"):setVisible(false)
   self.mainUI:getChildByName("icon_baoxiang_2"):setVisible(false)

   --进度条的显示
   
   self.mainUI:getChildByName("progress_bar_2"):setVisible(false)
   self.mainUI:getChildByName("progress_bar_3"):setVisible(false)
   self.mainUI:getChildByName("progress_bar_4"):setVisible(false)


   --进度文字
   self.mainUI:getChildByName("txt_LTR_02"):getChildByName("txt"):setString(getTextByKey("Limit-Reward011"))
   


  self.mainUI:getChildByName("txt_LTR_03"):getChildByName("txt"):setString(getTextByKey("Limit-Reward007"))
  self.mainUI:getChildByName("txt_LTR_01"):getChildByName("txt"):setString(getTextByKey("Limit-Reward018"))
   --限时进度条

  local function shopBtnAction(evt)

    local para = evt.context
    self.container:replaceScene(ShopScene, {enterScene = "ActivityPanelScene",returnScene = "ActivityPanelScene",selectPanelName = "Activity_LimitReward", params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
  end
  local shopBtn = Button:create(self.mainUI:getChildByName("btn_topUp_go"))
  shopBtn:addEventListener(Events.kStart, shopBtnAction, self)
  -- self:createButtonEvent()
  self.mainUI:getChildByName("list_limited_timeReward1"):getChildByName("btn_nowbuy"):getChildByName("normal"):setVisible(false)
  self.mainUI:getChildByName("list_limited_timeReward2"):getChildByName("btn_nowbuy"):getChildByName("normal"):setVisible(false)
  self.mainUI:getChildByName("list_limited_timeReward3"):getChildByName("btn_nowbuy"):getChildByName("normal"):setVisible(false)

 

 --问号按钮
  local  function helpBtnAction(evt)
    local para = evt.context
    self.container:setTableViewsEnabled(false)

    local begainTime , endTime = getEatPeachTime("questionDaily")
    local aInfoPanel = ActivityInfoPanel:create(self.container, getTextByKey("Limit-Reward009",{time1 = begainTime..":00" , time2 = endTime..":00"}))
    self.container:addChild(aInfoPanel)
    aInfoPanel:scaleIn()

  end
  local helpBtn = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
  helpBtn:addEventListener(Events.kStart,helpBtnAction,self)
  --这个就是获取金币数
  -- print("~~~~~~~~~~~~~~~~~~"..DataManager.getCurrUser().rechargeGems)



  

   --得到后端的配置数据
  local LimitRewardList = Activity_rechargeLayer.getLimitRewardList()
  --local  reward = LimitRewardList[1].reward
  -- print("Id=####~~~~~~~~~"..tostringRich(x[1].reward))

 
  self:createIcon(LimitRewardList[1].reward,"list_limited_timeReward1",1)
  self:createIcon(LimitRewardList[2].reward,"list_limited_timeReward2",2)
  self:createIcon(LimitRewardList[3].reward,"list_limited_timeReward3",3)

   

   -- print("Id=####~~~~~~~~~"..tostringRich(final))

 
   
 --将每个领取奖品的充值的钱数添加到表里面
  table.insert(self.MustAchieveMoneyList,LimitRewardList[1].rewardDetail)
  table.insert(self.MustAchieveMoneyList,LimitRewardList[2].rewardDetail)
  table.insert(self.MustAchieveMoneyList,LimitRewardList[3].rewardDetail)
  
  local FinalReward = self:getFinalRewardList()
  table.insert(self.RewardIdList,LimitRewardList[1].stepId)
  table.insert(self.RewardIdList,LimitRewardList[2].stepId)
  table.insert(self.RewardIdList,LimitRewardList[3].stepId)
  table.insert(self.RewardIdList,FinalReward.stepId)



  -- print("最后的奖励的ID "..FinalReward.stepId)

 
  -- print("转换成秒的时间###########   "..self.MustAchieveMoneyList[1])
  
  --self:createButtonEvent()
  local rechargeData = Activity_rechargeLayer.getRechargeData()
  local registrationTime = rechargeData.times
  for i = 1, 3 do
    table.insert(self.StageTimeList,DaytoSecond(LimitRewardList[i].limitTime))
  end
 
  self:createButtonAndSchedule(1,registrationTime)

  self:createButtonAndSchedule(2,registrationTime)
 
  self:createButtonAndSchedule(3,registrationTime)


 

    
end

function Activity_rechargeLayer:createButtonAndSchedule(aIndex,timenum)
  local Component = nil 
  -- print("_________________________________________timenum   "..timenum)
  local textNames = {"list_limited_timeReward1","list_limited_timeReward2","list_limited_timeReward3"}
  local limitRechargeData = Activity_rechargeLayer.getRechargeData()
    --设置按钮的状态

  local function HaveReceivedBtnHandle(textname)
    self.mainUI:getChildByName(textname):getChildByName("btn_nowbuy"):getChildByName("normal"):setVisible(false)
    self.rewardCount = self.rewardCount+1
    self:setprogress(self.rewardCount)
    self:DisappearTime(textname)
    local posX,posY=self.mainUI:getChildByName(textname):getChildByName("lbl_yilingqu"):getPositionX(),self.mainUI:getChildByName(textname):getChildByName("lbl_yilingqu"):getPositionY()
    self.mainUI:getChildByName(textname):getChildByName("lbl_yilingqu"):setRotation(-25)
    self.mainUI:getChildByName(textname):getChildByName("lbl_yilingqu"):setVisible(true)
    self.mainUI:getChildByName(textname):getChildByName("lbl_yilingqu"):setPositionXY(posX, posY-45) 
    
  end

  local function BuyBtnAction(evt)
     local para = evt.context
    if BagCalcManager.isFull() then
      NewPackageFullPanel:show()
      return
    end
     local function BtnCallBack()
      SuspensionLabel:showContent(self.container, Localization:getInstance():getText("Limit-Reward010"))
      para.Btn:setEnable(false)
      if  para.Componentname then
        para.Componentname:stop()
      end
      HaveReceivedBtnHandle(textNames[para.indexnum])
      Activity_rechargeLayer.setRewardsData(para.indexnum)
      self.container:resetTipInfoForActivity("Activity_LimitReward")
      local UnreceievedRewardsNum = Activity_rechargeLayer.getUnreceievedRewardsNum()
      if UnreceievedRewardsNum <= 0  and not (Activity_rechargeLayer.UnreachedRewardAndTimeRange(1)) and not (Activity_rechargeLayer.UnreachedRewardAndTimeRange(2)) and not (Activity_rechargeLayer.UnreachedRewardAndTimeRange(3))  then
        self.container:replaceScene(MainMenuScene)
      end
      --[[
      if para.indexnum == 3 then 
        self:OpenBaoxiangFun()
        self:CreateBaoxiangBtn()
      end]]
    end
    self:SendRequestFun(self.RewardIdList[para.indexnum],BtnCallBack)
    
     
       
  end

  local  function CreateBtnFun(textname,indexs)
    self.mainUI:getChildByName(textname):getChildByName("btn_nowbuy"):getChildByName("normal"):setVisible(true)
    self.BuyBtn = Button:create(self.mainUI:getChildByName(textname):getChildByName("btn_nowbuy"):getChildByName("normal"))

    self.BuyBtn:addEventListener(Events.kStart, BuyBtnAction, {Btn = self.BuyBtn,indexnum = indexs,Componentname=Component})
    -- self.BuyBtn:setEnable(false)
    
  end


   local  function AjudeFun(UnsatisfyConditions)
     
     local existed

     -- print("___________________________________ #Rewardprogress "..#self.RewardProgressList)
     -- if #self.Rewardprogress == 0 then 
     --   Component = CdLabelComponent:create()
     --   self:countdown(Component,textNames[aIndex],timenum,aIndex)
     -- end
   
    for i,v in ipairs(self.RewardProgressList) do

      -- print("————————————————————————————寻找已领取的奖励")
       if aIndex == v then
         HaveReceivedBtnHandle(textNames[aIndex],false)
         existed = true
         break
       end
    end
       
      if not existed then
		 local limitMoney
        local limitRewardConfigs = Activity_rechargeLayer.getLimitRewardList()
        -- print("_________________________limitRewardConfigs = "..tostringRich(limitRewardConfigs))
        for _, aLimitRewardConfig in ipairs(limitRewardConfigs) do
            -- print("aLimitRewardConfig = "..tostringRich(aLimitRewardConfig))
       
          if aLimitRewardConfig.stepId == aIndex then

            limitMoney = aLimitRewardConfig.rewardDetail
            -- print("_______________________limitMoney = "..tostring(limitMoney))
            -- print("___________________________________limitRechargeData.recharge[aIndex] = "..limitRechargeData.recharge[aIndex])
             --满足条件 这个是可以领取但是却没有领
            if self.TotalMoneyList[aIndex] >= limitMoney then
              -- print("——————————————————————————————可以创建按钮了 ")
                 CreateBtnFun(textNames[aIndex],aIndex)
                 self:DisappearTime(textNames[aIndex])
            else
              --不满足 我们就要创建倒计时 
              -- print ("__________________________________倒计时")
              UnsatisfyConditions()
               
            end
          end
        end
      end
   end

    --如果在活动时间内判断
   if (TimeUtil.getServerTimeSeconds()-timenum) <=  self.StageTimeList[aIndex] then
       local function CreateSchedule()
        self["com" .. aIndex] = CdLabelComponent:create()
        Component = self["com" .. aIndex]
        self:countdown(Component,textNames[aIndex],timenum+self.StageTimeList[aIndex],aIndex)
       end
       AjudeFun(CreateSchedule)


   else
       local function CreateMissTime()
        -- print("————————————————————————————————————aIndex "..aIndex)
         local posX,posY=self.mainUI:getChildByName(textNames[aIndex]):getChildByName("lbl_yicuoguo"):getPositionX(),self.mainUI:getChildByName(textNames[aIndex]):getChildByName("lbl_yicuoguo"):getPositionY()
         self.mainUI:getChildByName(textNames[aIndex]):getChildByName("lbl_yicuoguo"):setRotation(-25)
         self.mainUI:getChildByName(textNames[aIndex]):getChildByName("lbl_yicuoguo"):setPositionXY(posX, posY-45) 
         self.mainUI:getChildByName(textNames[aIndex]):getChildByName("lbl_yicuoguo"):setVisible(true)
         self:DisappearTime(textNames[aIndex])
       end
       AjudeFun(CreateMissTime) 

   end
    

   
end



--创建图标
function Activity_rechargeLayer:createIcon(reward,text,indexs)

  -- print("类型###########"..reward.itemType)

  local params = {}
  params.sourceDisplay = self.mainUI:getChildByName(text):getChildByName("normal_card_small")
 
  params.container = self.mainUI:getChildByName(text)
  
  params.showInCenter = true
  
  params.zindex = 10

  local newMeta = reward.metaId
  aCard = CanonGoodIcon.createGoodIcon(reward.itemType, newMeta, 0, params)
  
  local function IconBtnAction(evt)
   -- print("_____________________________________显示详情")
   local para = evt.context
     
     CanonGoodIcon.popoutGoodPanel(reward.itemType, reward.metaId)
   
    -- print("_____________________________________显示index = "..para.indexnum)

  end
  local IconBtn = Button:create(aCard)
  IconBtn:addEventListener(Events.kStart,IconBtnAction,{indexnum = indexs})

  local  function createstar(starnum,text)
    if starnum == 4 then
      self.mainUI:getChildByName(text):getChildByName("icon_star_5"):setVisible(false)
    end

  end

  if reward.itemType == ResourceEnum.CARD then
    createstar(MetaManager.card_meta[reward.metaId].rare,text)
    self.textName = getTextByKey(MetaManager.card_meta[reward.metaId].name)

  elseif reward.itemType == ResourceEnum.EQUIP then 
   
    createstar(MetaManager.equip_meta[reward.metaId].quality,text)
    self.textName = getTextByKey(MetaManager.equip_meta[reward.metaId].name)
 end
  self.mainUI:getChildByName(text):getChildByName("txt_LTR_03"):getChildByName("txt"):setString(self.textName)

end

function Activity_rechargeLayer:DisappearTime(textUI)
  self.mainUI:getChildByName(textUI):getChildByName("txt_LTR_06"):setVisible(false)
  self.mainUI:getChildByName(textUI):getChildByName("txt_LTR_07"):setVisible(false)
  self.mainUI:getChildByName(textUI):getChildByName("txt_LTR_08"):setVisible(false)
end



function Activity_rechargeLayer:countdown(cdLabelComponent,UIText,second,index) --传入的是一个flash的text 还有倒计时的时间
 
  local function onTimeTick1(remainedSec)
    local formatedTimeStr = TimeUtil.formatTime(remainedSec)
    -- print("设置的时间########"..formatedTimeStr)
    if  formatedTimeStr then
      self.mainUI:getChildByName(UIText):getChildByName("txt_LTR_07"):getChildByName("txt"):setString(formatedTimeStr)
    end
  end


  local  function onTimeComplete1()
    -- print("倒计时结束")
       
    if self.TotalMoneyList[index] < self.MustAchieveMoneyList[index] then

       local posX,posY=self.mainUI:getChildByName(UIText):getChildByName("lbl_yicuoguo"):getPositionX(),self.mainUI:getChildByName(UIText):getChildByName("lbl_yicuoguo"):getPositionY()
       self.mainUI:getChildByName(UIText):getChildByName("lbl_yicuoguo"):setRotation(-25)
       self.mainUI:getChildByName(UIText):getChildByName("lbl_yicuoguo"):setPositionXY(posX, posY-45) 
       self.mainUI:getChildByName(UIText):getChildByName("lbl_yicuoguo"):setVisible(true)
       cdLabelComponent:stop()
       self:DisappearTime(UIText)
    end
    local UnreceievedRewardsNum = Activity_rechargeLayer.getUnreceievedRewardsNum()
    if UnreceievedRewardsNum == 0 then
      local rechargeData = Activity_rechargeLayer.getRechargeData()
      local registrationTime = rechargeData.times
      local LimitRewardList = Activity_rechargeLayer.getLimitRewardList()
      if (TimeUtil.getServerTimeSeconds()-registrationTime) >=  DaytoSecond(LimitRewardList[3].limitTime) then
        
        self.container:replaceScene(MainMenuScene)
      end
    end

  end

    
  cdLabelComponent:setCallback(onTimeTick1, onTimeComplete1)
  -- print("当前的时间#########"..TimeUtil.getServerTimeSeconds())
  cdLabelComponent:setTargetTime(second)
  cdLabelComponent:start()
end


function Activity_rechargeLayer:CreateBaoxiangBtn()
  local function AccaptBtnAction(evt)
    local para = evt.context
    -- print("领取最终礼品")
    local function finalRewardCallBack()
      SuspensionLabel:showContent(self.container, Localization:getInstance():getText("Limit-Reward010"))
      para:setEnable(false)
      self.mainUI:getChildByName("icon_baoxiang_2"):setVisible(false)
      self.mainUI:getChildByName("icon_baoxiang_1"):setVisible(true)
      local final = self:getFinalRewardList()
      --设置领奖
      Activity_rechargeLayer.setRewardsData(4)
      -- print("最终奖励的Id "..self.RewardIdList[4])
      self.mainUI:getChildByName("txt_LTR_03"):getChildByName("txt"):setVisible(false)
      self.mainUI:getChildByName("txt_LTR_01"):getChildByName("txt"):setVisible(false)
      self.container:resetTipInfoForActivity("Activity_LimitReward")
      self.container:replaceScene(MainMenuScene)
    end
    
    self:SendRequestFun(self.RewardIdList[4],finalRewardCallBack)
    


  end
  local AccaptBtn = Button:create(self.mainUI:getChildByName("icon_baoxiang_2"))
  AccaptBtn:addEventListener(Events.kStart, AccaptBtnAction, AccaptBtn)
     
end




function Activity_rechargeLayer:OpenBaoxiangFun()
  self.mainUI:getChildByName("icon_baoxiang_2"):setVisible(true)
  self.mainUI:getChildByName("icon_baoxiang_3"):setVisible(false)
   
  
end




--[[
function Activity_rechargeLayer:JudgeReceive(Indexs)

  local LimitRewardList = Activity_rechargeLayer.getLimitRewardList()
  --时间戳
  local rechargeData = Activity_rechargeLayer.getRechargeData()
  local registrationTime = rechargeData.times
  if (TimeUtil.getServerTimeSeconds()-registrationTime) <=  DaytoSecond(LimitRewardList[Indexs].limitTime) then
    --如果在时间范围内 如果已经领取了就返回false 
      for i,v in ipairs(Activity_rechargeLayer.getRechargeData().rewards) do
         print("————————————————————————————寻找已领取的奖励")
         if aIndex == v then
          
          return false
         else
          return true
         end
      end
      
  end

  --判断是否已经领取
  for i,v in ipairs(Activity_rechargeLayer.getRechargeData().rewards) do

    print("————————————————————————————寻找已领取的奖励")
     if aIndex == v then
      
      return false
     end
  end

  --
  
  local limitMoney
  local limitRewardConfigs = Activity_rechargeLayer.getLimitRewardList()
    -- print("_________________________limitRewardConfigs = "..tostringRich(limitRewardConfigs))
  for _, aLimitRewardConfig in ipairs(limitRewardConfigs) do
    -- print("aLimitRewardConfig = "..tostringRich(aLimitRewardConfig))
   
    if aLimitRewardConfig.stepId == aIndex then

      limitMoney = aLimitRewardConfig.rewardDetail
      -- print("_______________________limitMoney = "..tostring(limitMoney))
      -- print("___________________________________limitRechargeData.recharge[aIndex] = "..limitRechargeData.recharge[aIndex])
       --满足条件 这个是可以领取但是却没有领
      if Activity_rechargeLayer.getRechargeData().recharge[aIndex] >= limitMoney then
        -- print("——————————————————————————————可以创建按钮了 ")
        return true
      end
        --不满足 我们就要创建倒计时 
        -- print ("__________________________________倒计时")
      return false
    end
  end
end
]]

--判断是否显示广告
function  Activity_rechargeLayer.JudgeDisplayAdvertising( )
  local LimitRewardList = Activity_rechargeLayer.getLimitRewardList()
  -- print("__________________________________LimitRewardList[3].limitTime = "..LimitRewardList[3].limitTime)
  --时间戳
  local rechargeData = Activity_rechargeLayer.getRechargeData()
  local registrationTime = rechargeData.times
  local showRechargeAdType = 0  --0表示不需要显示广告，1表示显示没有倒计时的静态图，2表示显示倒计时
  if Activity_rechargeLayer.enable() then
    if (TimeUtil.getServerTimeSeconds()-registrationTime) <=  DaytoSecond(LimitRewardList[3].limitTime) then  --判断是否在72小时之内
      if rechargeData.recharge[3] >= LimitRewardList[3].rewardDetail  then    --判断充值数是否大于等于最大档
        showRechargeAdType = 1
      else
        --显示动态图片
        showRechargeAdType = 2
      end
    else
      showRechargeAdType = 1
    end
  else
    showRechargeAdType = 0
  end

  return showRechargeAdType

  --[[
  if not SystemManager.isNewbieFinished() then
    return false
  end
  local  OverTimeOrReceivedCount = 0
   --判断是否过了新手引导
  for i = 1 ,3 do
   
    if  self:JudgeReceive(i) then
       return  true--显示广告 只要有一个true就显示广告
    end
    if  not self:JudgeReceive(i) then
      OverTimeOrReceivedCount = OverTimeOrReceivedCount+1
    end
  end
  if OverTimeOrReceivedCount == 3 and #Activity_rechargeLayer.getRechargeData().rewards == 3 then
    return true
  end
  return false
  ]]
end

function Activity_rechargeLayer:setprogress(num)
  if num == 1 then

    self.mainUI:getChildByName("progress_bar_2"):setVisible(true)

  elseif num == 2 then

    self.mainUI:getChildByName("progress_bar_3"):setVisible(true)

  elseif num == 3 then

    self.mainUI:getChildByName("progress_bar_4"):setVisible(true)
     self:OpenBaoxiangFun()
     self:CreateBaoxiangBtn()
  end
    
end


function Activity_rechargeLayer.UnreachedRewardAndTimeRange(Indexs)

  -- print("______________________________下标值 "..tostringRich(Indexs))
  local LimitRewardList = Activity_rechargeLayer.getLimitRewardList()
  --时间戳
  local rechargeData = Activity_rechargeLayer.getRechargeData()
  local registrationTime = rechargeData.times
  if (TimeUtil.getServerTimeSeconds()-registrationTime) >=  DaytoSecond(LimitRewardList[Indexs].limitTime) then
      return false
  end

  --判断是否已经领取
  for i,v in ipairs(Activity_rechargeLayer.getRechargeData().rewards) do

    -- print("————————————————————————————寻找已领取的奖励")
     if aIndex == v then
      
      return false
     end
  end

  --
  -- print("__________________________________________循环过后")
  local limitMoney
  local limitRewardConfigs = Activity_rechargeLayer.getLimitRewardList()
    -- print("_________________________limitRewardConfigs = "..tostringRich(limitRewardConfigs))
  for _, aLimitRewardConfig in ipairs(limitRewardConfigs) do
    -- print("aLimitRewardConfig = "..tostringRich(aLimitRewardConfig))
   
    if aLimitRewardConfig.stepId == Indexs then

      limitMoney = aLimitRewardConfig.rewardDetail
      -- print("_______________________limitMoney = "..tostring(limitMoney))
      -- print("___________________________________limitRechargeData.recharge[aIndex] = "..limitRechargeData.recharge[Indexs])
       --满足条件 这个是可以领取但是却没有领
      if Activity_rechargeLayer.getRechargeData().recharge[Indexs] >= limitMoney then
        -- print("——————————————————————————————可以创建按钮了 ")
        return false
      end
        --不满足 我们就要创建倒计时 
        -- print ("__________________________________倒计时")
      return true
    end
  end
end

--显示第几个倒计时 如果三个倒计时都没有了 显示第二种广告
function Activity_rechargeLayer.CurrentJudgeCountdown()
  -- print("_____________________________判断满足"..tostringRich(Activity_rechargeLayer.UnreachedRewardAndTimeRange(1)))
  if Activity_rechargeLayer.UnreachedRewardAndTimeRange(1) then
    return 1
  end
  if Activity_rechargeLayer.UnreachedRewardAndTimeRange(2) then
    return 2
  end
  if Activity_rechargeLayer.UnreachedRewardAndTimeRange(3) then
    return 3
  end
  return 4
end



--获得配置
function Activity_rechargeLayer:getMetas()
  --print("metas = " .. tostringRich(metas))
  return DataManager.GameMetaData.activityLimitRewardConfig
end

--获得活动开关名称
function Activity_rechargeLayer:getFeatureName()
  local metas = Activity_rechargeLayer.getMetas()
  -- print("_____________1")
  -- print(table.tostring(metas))
  if not metas then
    --防崩
    return nil
  end
  return metas.featureName
end

--获得多倍奖励配置 list
-- <?xml version="1.0" encoding="UTF-8"?>
-- <bean desc="限时首充奖励配置">
--   <property code="stepId" type="int" desc="奖励Id"/>
--   <property code="reward" ref="Reward" desc="奖励内容"/>
--   <property code="rewardDetail" type="string" desc="奖励条件"/>
-- </bean>
function Activity_rechargeLayer.getLimitRewardList()
  local metas = Activity_rechargeLayer.getMetas()
  -- print("metas = " .. tostringRich(metas))
  if not metas then
    --防崩
    return {}
  end
  return metas.limitRewards or {}
end

function Activity_rechargeLayer:getFinalRewardList()
  local metas = Activity_rechargeLayer.getMetas()
  -- print("metasfinalReward = " .. tostringRich(metas.finalReward))
  if not metas then
    --防崩
    return {}
  end
  return metas.finalReward or {}
end



function Activity_rechargeLayer:SendRequestFun(Id,BtnSuccessFun)
  local function successCallback(data)
    extraArgs = data.data or {}
    -- if Id == 4 then
    print("最终奖励的奖励 "..tostringRich(extraArgs.reward))

    -- end
    RewardManager:getReward(extraArgs.reward)
    
    if BtnSuccessFun then
      BtnSuccessFun()
    end

  end
  ActiveRechangeRequest.sendRequestDefalut( {stepId=Id} ,successCallback)
end



function Activity_rechargeLayer.getRewardsData()
  local gameInitData = DataManager.getGameInitData()
  return gameInitData.sharkActivity.flashRecharge.rewards
end

function Activity_rechargeLayer.setRewardsData(RewardIds)
   local gameInitData = DataManager.getGameInitData()
   
   table.insert(gameInitData.sharkActivity.flashRecharge.rewards,RewardIds)
   DataManager.setGameInitData(gameInitData)
end

function Activity_rechargeLayer.getRechargeData()
  local gameInitData = DataManager.getGameInitData()
  if not gameInitData.sharkActivity then
    --这时候还没有数据
    gameInitData.sharkActivity = {}
  end
  if not gameInitData.sharkActivity.flashRecharge then
    gameInitData.sharkActivity.flashRecharge = {times = 0, recharge = {}, rewards = {}}
  end
  for i = 1, 3 do
	  if not gameInitData.sharkActivity.flashRecharge.recharge[i] then
      gameInitData.sharkActivity.flashRecharge.recharge[i] = 0
    end
  end
  if not Activity_rechargeLayer.recharge_data_Ready then
    for i = 3, 2, -1 do
      for j = 1, i - 1 do
        gameInitData.sharkActivity.flashRecharge.recharge[i] = gameInitData.sharkActivity.flashRecharge.recharge[i] + 
        gameInitData.sharkActivity.flashRecharge.recharge[j]
      end
    end
    Activity_rechargeLayer.recharge_data_Ready = true
    DataManager.setGameInitData(gameInitData)
  end

  return gameInitData.sharkActivity.flashRecharge
end

--修改当前充的钱数
function Activity_rechargeLayer.ResetRechargeData(RechargeMoney)
  -- print("——————————————————————————————————冲的钱数 = "..RechargeMoney)
  -- local function DaytoSecond(Daytime)
  --   return Daytime*60*60
  -- end
  local rechargeData = Activity_rechargeLayer.getRechargeData()
  local registrationTime = rechargeData.times
  local LimitRewardList = Activity_rechargeLayer.getLimitRewardList()

 
  local gameInitData = DataManager.getGameInitData()

  if (TimeUtil.getServerTimeSeconds()-registrationTime) <=  DaytoSecond(LimitRewardList[1].limitTime )then
    for i = 1,3 do
      gameInitData.sharkActivity.flashRecharge.recharge[i] = RechargeMoney + gameInitData.sharkActivity.flashRecharge.recharge[i]
    end
  elseif (TimeUtil.getServerTimeSeconds()-registrationTime) <=  DaytoSecond(LimitRewardList[2].limitTime) then
    for i = 2,3 do
      gameInitData.sharkActivity.flashRecharge.recharge[i] = RechargeMoney + gameInitData.sharkActivity.flashRecharge.recharge[i]
    end
  elseif (TimeUtil.getServerTimeSeconds()-registrationTime) <=  DaytoSecond(LimitRewardList[3].limitTime) then
      gameInitData.sharkActivity.flashRecharge.recharge[3] = RechargeMoney + gameInitData.sharkActivity.flashRecharge.recharge[2]
  end
   DataManager.setGameInitData(gameInitData)
  
 

end

function Activity_rechargeLayer.getUnreceievedRewardsNum()
  local limitRechargeData = Activity_rechargeLayer.getRechargeData()
  local result = 0
  for i = 1, 4 do
    local existed
    for _, aValue in ipairs(limitRechargeData.rewards) do
      if i == aValue then
        existed = true
        break
      end
    end
    if not existed then
      if (i == 4) and (#limitRechargeData.rewards == 3) then
        result = result + 1
      end
      if i < 4 then
        local limitMoney
        local limitRewardConfigs = Activity_rechargeLayer.getLimitRewardList()
        for _, aLimitRewardConfig in ipairs(limitRewardConfigs) do
          if aLimitRewardConfig.stepId == i then
            limitMoney = aLimitRewardConfig.rewardDetail

            break
          end
        end
        if limitRechargeData.recharge[i] >= limitMoney then
          -- print("___________________________________充值的Money = "..limitRechargeData.recharge[i])
          result = result + 1
        end
      end
    end
  end
  return result
end

function Activity_rechargeLayer:enable(curTimeStamp)
  
	local isEnable = true
  --Activity_rechargeLayer.ResetRechargeData(660)
 
  local featureName = Activity_rechargeLayer:getFeatureName()
  --print("___________featureName:" .. featureName)
  if not featureName then
    
    return false
  end

  local limitRewardConfigs = Activity_rechargeLayer.getLimitRewardList()
  local limitRechargeData = Activity_rechargeLayer.getRechargeData()
  
  if not MaintenanceManager.isActivityOpen(featureName) then    --活动未开启
    
    if not MaintenanceManager.isActivityAlreadyClose(featureName) then    --时间点在活动开启前
      
      return false
    else                                                                  --时间点在活动结束后
      if limitRechargeData.times == 0 then                                --活动结束后才生成的数据结构
        
        return false
      else                                                                --虽然当前时间点是活动结束后，但是活动结束前数据结构已生成
        if #limitRechargeData.rewards >= 4 then                           --奖励已经全部领取完毕
         
          return false
        else                                                              --奖励未全部领取完
          if (TimeUtil.getServerTimeSeconds() - limitRechargeData.times) >=  DaytoSecond(limitRewardConfigs[3].limitTime) then  --玩家的活动时间已结束
            if Activity_rechargeLayer.getUnreceievedRewardsNum() > 0 then
              
              return true
            else
              
              return false
            end
          else 
            if Activity_rechargeLayer.getUnreceievedRewardsNum() > 0 then
              return true
            else
              
              return false
            end
           -- return true
          end
        end
      end
    end
  else  --活动已开启
    
    if #limitRechargeData.rewards >= 4 then   --奖励全部领取完毕
     
        return false
    else    --奖励未全部领取完
      if (TimeUtil.getServerTimeSeconds() - limitRechargeData.times) >=  DaytoSecond(limitRewardConfigs[3].limitTime) then  --玩家的活动时间已结束
        if Activity_rechargeLayer.getUnreceievedRewardsNum() > 0 then
          
          return true
        else
         
          return false
        end
      else

         if #limitRechargeData.rewards >= 4 then
          return false
         else
         
          return true
         end
      --  end
       
        -- return true
      end
    end
  end
  
  return isEnable
end

function Activity_rechargeLayer.getTipNum()
  local unReveivedNum = Activity_rechargeLayer.getUnreceievedRewardsNum()
  --print("__________unReceivedNum:" .. unReveivedNum)
  return unReveivedNum, 0
end

function Activity_rechargeLayer:dispose()
  if self.com1 then
    self.com1:stop()
  end
  if self.com2 then
    self.com2:stop()
  end
  if self.com3 then
    self.com3:stop()
  end
  Activity_rechargeLayer.super.dispose(self)
end