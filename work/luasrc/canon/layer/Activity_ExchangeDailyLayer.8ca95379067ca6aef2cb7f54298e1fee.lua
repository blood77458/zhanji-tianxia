--限时奖励
require "hecore.display.CocosObject"
require "hecore.display.Director"
require "canon.data.DataManager"
require "canon.panel.ActivityInfoPanel"
require "canon.utils.TimeUtil"
require "canon.customUI.CdLabelComponent"
require "canon.request.ActivereFreshCardExchangeDaillyCardRequest"



local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_ExchangeDailyLayer = class(Layer)
local _cardExchangeMetaHash = nil
local _ExchangeMetaByCardId = nil
local _hasEnterd = false
--跨天事件  零点的自动更新
local function onPassDay(evt)
  local self = evt.context

  local FreeRefreshText = "Free"
  --重新设置兑换次数
  self.refreshSelf(FreeRefreshText)
  
end
function Activity_ExchangeDailyLayer:ShowClosePanel()
  local function closeCanonMessageBox()
    self.container:replaceScene(MainMenuScene)
  end
  local text = Localization:getInstance():getText("activity-treasurebox-over")
  self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
end
function Activity_ExchangeDailyLayer:ctor()
  self.container = nil
end

function Activity_ExchangeDailyLayer:create( container , extraArgs)
  self.container = container
  self.extraArgs = extraArgs
  local s = Activity_ExchangeDailyLayer.new()
  s:initLayer()
  return s
end

function Activity_ExchangeDailyLayer:initLayer()
 
	Activity_ExchangeDailyLayer.super.initLayer(self)
  --导入falsh
  self.builder = LayoutBuilder:createWithContentsOfFile("scene/exchangeDaily.json")
  self.builder.useArtLabelTTF = true
  self.mainUI = self.builder:build("exchangeDaily")
  self:addChild(self.mainUI)
  self.ChooseList = {}
  self.IconName = {}
  self.newMetaIdList = {}
  self.newIdList = {} 
  self.ExchangeBtnList = {}--对按钮点亮，到零点自动刷新按钮要点亮
  
  local function CreateIconFun(newMetaId,i)
    self.MetaId = newMetaId
    local NowId = Activity_ExchangeDailyLayer.getCardExchangeMetaByCardId(newMetaId)
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~NowId = "..NowId)
    table.insert(self.newIdList,NowId)
    table.insert(self.newMetaIdList,newMetaId)
    local function IconBtnAction(evt)
      -- print("_____________________________________显示详情")
      local para = evt.context
      Activity_ExchangeDailyLayer.openCard(self.newMetaIdList[para.MetaId])
    end
    local params = {}
    params.sourceDisplay = self.mainUI:getChildByName("card_normal"..i)
    params.container = self.mainUI
    params.showInCenter = true
    params.zindex = 10
    params.metaid = newMetaId
 
    local CardName = Localization:getInstance():getText(MetaManager.card_meta[newMetaId].name)
    -- print("~~~~~~~~~~~~~~~~~~~~CardName = "..CardName)
    self.mainUI:getChildByName("txt_card"..i):getChildByName("txt"):setString(CardName)
    
    self.mainUI:getChildByName("txt_card"..i):getChildByName("txt"):setColor(ccc3(255, 255, 0))
    self.mainUI:getChildByName("txt_card"..i):getChildByName("txt"):setAroundColor(ccc3(91, 24, 14))
    local aCard = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, newMetaId, 1, params)
    table.insert(self.IconName,aCard)
    local IconBtn = Button:create(params.sourceDisplay)
    IconBtn:addEventListener(Events.kStart,IconBtnAction,{MetaId = i})
  end

  
  local function refreshSelf(txt)

    local NowMoney = CalculationManager.calcComplex_getGemsNow()

    local function SucceedResponse(evt)
      -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~当前兑换次数evt.data.cardExchangeDailyInfo.cardMetaIds = "..evt.data.cardExchangeDailyInfo.exchangeTimes)
        -- if event.data.retCode == 714401 then  --activity closed
       
      --重新设置兑换次数
      Activity_ExchangeDailyLayer.setCurrentExchangeNum(evt.data.cardExchangeDailyInfo.exchangeTimes)
      if txt ~= "Free" and NowMoney >= 300  then
        RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = (-300 or 0)}})
      elseif txt == "Free" then
        
        local JudeButs = Activity_ExchangeDailyLayer.canEnterScene()
        if JudeButs then
          for i,v in ipairs(self.ExchangeBtnList) do
            local ExchangeBtn = v
            if ExchangeBtn then
              ExchangeBtn:setEnable(true)
              self.mainUI:getChildByName("btn_"..i):getChildByName("normal"):setVisible(true)
            end
          end
          if self.RefreshBtn then
            self.RefreshBtn:setEnable(true)
            self.mainUI:getChildByName("btn_yellow_long_exchageDaily"):getChildByName("normal"):setVisible(true)
          end
            --刷新可兑换次数  在免费刷新的时候
          local CurrentNum = Activity_ExchangeDailyLayer.getCurrentExchangeNum()
          local TotalNum = Activity_ExchangeDailyLayer.getCardNum()
          local SurplusNum = TotalNum - CurrentNum
          self.mainUI:getChildByName("txt_03"):getChildByName("txt"):setString(getTextByKey("exchangeDaily_card",{num1 = SurplusNum,num2 = TotalNum}))--刷新
          self.container:resetTipInfoForActivity("Activity_ExchangeDaily")
        end
      end
      self.newMetaIdList = {}
      self.newIdList = {}
       --删除旧的iCON图
      for i,v in ipairs(self.IconName) do
        local Icon = v
        if Icon then
          Icon:removeFromParentAndCleanup(true)
        end
      end
      self.IconName = {}
      -- 
      local cardMetaIdsList = evt.data.cardExchangeDailyInfo.cardMetaIds
      Activity_ExchangeDailyLayer.setCardExchangeList(cardMetaIdsList)
      for k,v in pairs(cardMetaIdsList) do
        
        CreateIconFun(v,k)
      end
     
      -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~123cardExchangeDailyInfo "..tostringRich(cardMetaIdsList))
    end

    if txt == "Free"  then  --传入的txt是Free 就说明是免费刷新， 只有在后端返回的数为Null 和零点刷新的时候才会走
      ActivereFreshCardExchangeDaillyCardRequest.sendRequestDefalut({useGold=false} ,SucceedResponse)
    elseif NowMoney >= 300 then 
      
      ActivereFreshCardExchangeDaillyCardRequest.sendRequestDefalut({useGold=true} ,SucceedResponse)
    else
      local function onReplaceScene()
        self.container:setTableViewsEnabled(true)
        self.targetInfoPanel = nil
      end
      local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
      self:addChild(aPanel)
      aPanel:scaleIn()
      return
    end
  end 
  self.refreshSelf = refreshSelf
  local currentAstralessenceNum = CanonGoodIcon.getResourceNum(ResourceEnum.ASTRALESSENCE)--当前星灵数
  self.mainUI:getChildByName("txt_shopmyster8"):getChildByName("txt"):setString(currentAstralessenceNum)
  --兑换
  local  function ExchangeBtnAction(evt)
    local para = evt.context
    local Enable = Activity_ExchangeDailyLayer.enable()
    if not Enable then
      self:ShowClosePanel()
    else
      local exchangeId = self.newIdList[para.index]
      Activity_ExchangeDailyLayer.gotoScene(exchangeId)
    end
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~跳转到CardOldToNewExchangeScene"..para.index.."  self.ChooseList = "..self.ChooseList[para.index].id)
    
  end
  local JudeBut = Activity_ExchangeDailyLayer.canEnterScene()
  for i=1,4 do
    --card_normal1
    self.mainUI:getChildByName("card_normal"..i):setVisible(false)
    local ExchangeUI = self.mainUI:getChildByName("btn_"..i)
    ExchangeUI:getChildByName("txt"):setString(getTextByKey("cardExchange_exchange"))--兑换
    local ExchangeBtn = Button:create(ExchangeUI)
    ExchangeBtn:addEventListener(Events.kStart,ExchangeBtnAction,{index = i}) --传入兑换id
    
    table.insert(self.ExchangeBtnList,ExchangeBtn)
    --如果达到兑换上限 按钮置灰
    if not JudeBut then
      ExchangeBtn:setEnable(false)
      ExchangeUI:getChildByName("normal"):setVisible(false)
    end
  end

  local timeTable = MaintenanceManager:getActivityBeginAndEndTimeButThisActivityIsOpenEveryWeek(Activity_ExchangeDailyLayer.getFeatureName())
  self.mainUI:getChildByName("btn_yellow_long_exchageDaily"):getChildByName("txt2"):setString(getTextByKey("exchangDaily_buy",{num = 300}))--刷新
  local CurrentNum = Activity_ExchangeDailyLayer.getCurrentExchangeNum()
  local TotalNum = Activity_ExchangeDailyLayer.getCardNum()
  local SurplusNum = TotalNum - CurrentNum
  self.mainUI:getChildByName("txt_03"):getChildByName("txt"):setString(getTextByKey("exchangeDaily_card",{num1 = SurplusNum,num2 = TotalNum}))--刷新
  --
  self.mainUI:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("exchangeDaily_time1"))
  self.mainUI:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("exchangeDaily_time2",{month1 = timeTable[1].month , day1 = timeTable[1].day , month2 = timeTable[2].month, day2 = timeTable[2].day}))
  self.mainUI:getChildByName("btn_yellow_long_exchageDaily"):getChildByName("txt"):setVisible(false) --兑换
  
  --问号按钮
  local  function helpBtnAction(evt)
    local para = evt.context
    self.container:setTableViewsEnabled(false)
 --本期活动时间：{month1}月{day1}日—{month2}月{day2}日。\n活动期间可以使用两张没有转生过的五星卡牌加一定的星灵进行新卡牌的兑换。\n如果使用与所需兑换卡牌名
    local str = getTextByKey("exchangeDaily_help", {month1 = timeTable[1].month , day1 = timeTable[1].day , month2 = timeTable[2].month, day2 = timeTable[2].day})
    local aInfoPanel = ActivityInfoPanel:create(self.container, str)
    self.container:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
  end
  local helpBtn = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
  helpBtn:addEventListener(Events.kStart,helpBtnAction,self)
  --刷新按钮
  local  function RefreshBtnAction(evt)
    local para = evt.context
    local Enable = Activity_ExchangeDailyLayer.enable()
    if not Enable then
      self:ShowClosePanel()
    else
      self.refreshSelf()
    end
    
    -- print("~~~~~~~~~~~~~~~~~~刷新")
  end
  self.RefreshBtn = Button:create(self.mainUI:getChildByName("btn_yellow_long_exchageDaily"))
  self.RefreshBtn:addEventListener(Events.kStart,RefreshBtnAction,self)
  --normal
  if not JudeBut then
    self.RefreshBtn:setEnable(false)
    self.mainUI:getChildByName("btn_yellow_long_exchageDaily"):getChildByName("normal"):setVisible(false)
  end
  --至尊求将按钮
  local  function GachaBtnAction(evt)
    local para = evt.context
    local Enable = Activity_ExchangeDailyLayer.enable()
    if not Enable then
      self:ShowClosePanel()
    else
      self.container:replaceScene(GachaScene, {returnScene = "Activity_ExchangeDailyLayer"})
    end
  end
  local GachaBtn = Button:create(self.mainUI:getChildByName("icon_gachaRupreme"))
  GachaBtn:addEventListener(Events.kStart,GachaBtnAction,self)

  --祭炼按钮
  local  function CardRebirthBtnAction(evt)
    local para = evt.context
    local Enable = Activity_ExchangeDailyLayer.enable()
    if not Enable then
      self:ShowClosePanel()
    else
      if (DataManager.getCurrUser().level < MetaManager.getGameSettingConfig().sacrificeUnlockLevel) then
        SuspensionLabel:showContent(self, Localization:getInstance():getText("module_needLevel", {num = MetaManager.getGameSettingConfig().sacrificeUnlockLevel}))
      else
        self.container:replaceScene(CardRebirthScene, {returnScene = "Activity_ExchangeDailyLayer"})
      end
    end
    
  end
  local CardRebirthBtn = Button:create(self.mainUI:getChildByName("icon_therefined"))
  CardRebirthBtn:addEventListener(Events.kStart,CardRebirthBtnAction,self)
  
  --加侦听
  NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)
  local CardExchangeMetaList = Activity_ExchangeDailyLayer.getCardExchangeList()

  --当后端传来的配置返回的CardExchangeMetaList 是空的就会免费刷新一次
  if CardExchangeMetaList == nil or #CardExchangeMetaList == 0 then
    local FreeRefreshText = "Free"
    self.refreshSelf(FreeRefreshText)
  else
    for i,v in ipairs(CardExchangeMetaList) do

      CreateIconFun(v,i)
    end
  end
  --如果活动结束 弹出一个切回主界面的弹框
  local Enable = Activity_ExchangeDailyLayer.enable()
  if not Enable then
    self:ShowClosePanel()
  end
end

--获得配置
function Activity_ExchangeDailyLayer.getMetas()
  return DataManager.GameMetaData.exchangeDailyConfig
end

--获得活动开关名称
function Activity_ExchangeDailyLayer.getFeatureName()
  local metas = Activity_ExchangeDailyLayer.getMetas()
  if not metas then
    --防崩
    return nil
  end
  return metas.featureName
end



--同系列材料卡牌星灵系数
function Activity_ExchangeDailyLayer.getOldCardRatio()
  local metas = Activity_ExchangeDailyLayer.getMetas()
  if not metas then
    return 1
  end
  return metas.oldCardRatio
end
--兑换上限
function Activity_ExchangeDailyLayer.getCardNum()
  local metas = Activity_ExchangeDailyLayer.getMetas()
  if not metas then
    return 1
  end
  return metas.cardNum
end


--兑换卡牌所需星灵系数
function Activity_ExchangeDailyLayer.getNewCardRatio()
  local metas = Activity_ExchangeDailyLayer.getMetas()

  if not metas then
    return 1
  end
  return metas.newCardRatio
end

--六星卡牌消耗星灵
function Activity_ExchangeDailyLayer.getSixCost()
  local metas = Activity_ExchangeDailyLayer.getMetas()
  if not metas then
    return 1
  end
  return metas.sixCost
end
--总共可兑换卡牌配置 list
function Activity_ExchangeDailyLayer.getCardExchangeMetaList()
  local metas = Activity_ExchangeDailyLayer.getMetas()
  if not metas then
    return {}
  end

  return metas.cardExchangeMeta
end


--可兑换卡牌配置 list
function Activity_ExchangeDailyLayer.getCardExchangeList()
  local list = Activity_ExchangeDailyLayer.getCardExchangeDailyInfo()
  if not list then
    return {}
  end

  return list.cardMetaIds
end

--重新设置一下list
function Activity_ExchangeDailyLayer.setCardExchangeList(list)
   local gameInitData = DataManager.getGameInitData()

  
  if gameInitData.sharkDailyDataExtend then
    gameInitData.sharkDailyDataExtend.cardExchangeDailyInfo.cardMetaIds = list
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~gameInitData.sharkDailyDataExtend.cardExchangeDailyInfo.cardMetaIds = "..tostringRich(gameInitData.sharkDailyDataExtend.cardExchangeDailyInfo.cardMetaIds))
    DataManager.setGameInitData(gameInitData)
  end
end
--重新设置一下已兑换次数
function Activity_ExchangeDailyLayer.setCardExchangeexchangeTimes(num)
  local gameInitData = DataManager.getGameInitData()
  if gameInitData.sharkDailyDataExtend then
    gameInitData.sharkDailyDataExtend.cardExchangeDailyInfo.exchangeTimes = num
    -- print("~~~~~~~~~~~~~~~~~~~~~~gameInitData.sharkDailyDataExtend.cardExchangeDailyInfo.exchangeTimes = "..gameInitData.sharkDailyDataExtend.cardExchangeDailyInfo.exchangeTimes)
    DataManager.setGameInitData(gameInitData)
  end
  
end
--通过CardId 获得配置
function Activity_ExchangeDailyLayer.getCardExchangeMetaByCardId(CardId)
  local cardExchangeMetaList = Activity_ExchangeDailyLayer.getCardExchangeMetaList()
  if not cardExchangeMetaList then
    return {}
  end

  if not _ExchangeMetaByCardId then
    --array转hash 只转一次
    _ExchangeMetaByCardId = {}
    for i, v in ipairs(cardExchangeMetaList) do
      local meta = cardExchangeMetaList[i]
      -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~meta.cardId = "..meta.cardId.." meta.id =  "..meta.id)

      _ExchangeMetaByCardId[meta.cardId] = meta.id
    end
  end
  local result = _ExchangeMetaByCardId[CardId]
  if SystemManager.debug then
    DebugManager.assert(result ~= nil, "Activity_CardOldToNewLayer 没有这个兑换Id! exchangeId = " .. tostringRich(CardId))
  end
  return result

end


--查找获得卡牌具体配置
-- <bean desc="兑换信息配置">
--  <property code="id" type="int" desc="配置序列" />
--  <property code="cardId" type="int" desc="兑换卡牌metaId" />
--  <property code="secretNum" type="int" desc="需要星灵数量" />
--  <property code="exchangeNum" type="int" desc="卡牌兑换上限" />
-- </bean>
function Activity_ExchangeDailyLayer.getCardExchangeMetaById(exchangeId)
  local cardExchangeMetaList = Activity_ExchangeDailyLayer.getCardExchangeMetaList()
  if not cardExchangeMetaList then
    return {}
  end

  if not _cardExchangeMetaHash then
    --array转hash 只转一次
    _cardExchangeMetaHash = {}
    for i, v in ipairs(cardExchangeMetaList) do
      local meta = cardExchangeMetaList[i]
      meta.exchangeNum = Activity_ExchangeDailyLayer.getCardNum()
      _cardExchangeMetaHash[meta.id] = meta

    end
  end

  local result = _cardExchangeMetaHash[exchangeId]
  if SystemManager.debug then
    DebugManager.assert(result ~= nil, "Activity_CardOldToNewLayer 没有这个兑换卡牌! exchangeId = " .. tostringRich(exchangeId))
  end
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~result ="..tostringRich(result))
  return result
end

------------------------------------------

--获得当前的兑换信息 hash
-- <bean desc="易帅换将信息（日常）">
--   <list code="cardMetaIds" type="int" desc="当前可兑换的卡牌metaId" />
--   <property code="exchangeTimes" type="int" desc="当前兑换次数" />
-- </bean>
function Activity_ExchangeDailyLayer.getCardExchangeDailyInfo()

  local gameInitData = DataManager.getGameInitData()
  if not gameInitData.sharkDailyDataExtend then
     gameInitData.sharkDailyDataExtend = {}
  end

  if  gameInitData.sharkDailyDataExtend.cardExchangeDailyInfo == nil then
    gameInitData.sharkDailyDataExtend.cardExchangeDailyInfo = {}
    --这时候还没有数据
    gameInitData.getCardExchangeDailyInfo = {cardMetaIds = {}, exchangeTimes = 0}
  end 
  DataManager.setGameInitData(gameInitData)
  return gameInitData.sharkDailyDataExtend.cardExchangeDailyInfo
end


--增加已经兑换的数量
function Activity_ExchangeDailyLayer.addCurrentExchangeNum()
  local exchangeTimes = Activity_ExchangeDailyLayer.getCurrentExchangeNum()
  if exchangeTimes == nil then
    exchangeTimes = 0
  end
  exchangeTimes = exchangeTimes + 1
  Activity_ExchangeDailyLayer.setCardExchangeexchangeTimes(exchangeTimes)

end

--设置已兑换次数
function Activity_ExchangeDailyLayer.setCurrentExchangeNum(num)
  local exchangeTimes = Activity_ExchangeDailyLayer.getCurrentExchangeNum()
  if exchangeTimes == nil then
    exchangeTimes = 0
  end
  exchangeTimes = num
  Activity_ExchangeDailyLayer.setCardExchangeexchangeTimes(exchangeTimes)

end



--获得已经兑换的数量
function Activity_ExchangeDailyLayer.getCurrentExchangeNum()
  local CardExchengeInfo = Activity_ExchangeDailyLayer.getCardExchangeDailyInfo()
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~CardExchengeInfo.exchangeTimes = "..tostringRich(CardExchengeInfo))
  if CardExchengeInfo.exchangeTimes == nil then
    return 0
  end
  return CardExchengeInfo.exchangeTimes
end

------------------------------------------

--弹出卡牌信息
function Activity_ExchangeDailyLayer.openCard(cardMetaId)
  --print("cardMetaId = " .. tostringRich(cardMetaId))
  CanonGoodIcon.popoutGoodPanel(ResourceEnum.CARD, cardMetaId)
end

--进入兑换场景
--exchangeId 兑换编号
function Activity_ExchangeDailyLayer.gotoScene(exchangeId)
  local argv = {}
  argv.params = {}
  argv.params.exchangeId = exchangeId
  argv.params.returnScene = "Activity_ExchangeDailyLayer"
  argv.params.layer = Activity_ExchangeDailyLayer
  Director:sharedDirector():replaceScene(CardOldToNewExchangeScene:create(argv))
end

------------------------------------------

-- 查询是否能进入场景
-- aData 配置数据
function Activity_ExchangeDailyLayer.canEnterScene()
  local currentExchangeNum = Activity_ExchangeDailyLayer.getCurrentExchangeNum()--当前兑换数量\
  local exchangeNum = Activity_ExchangeDailyLayer.getCardNum() --兑换上限
  if currentExchangeNum >= exchangeNum then
    return false
  end
  return true
end


function Activity_ExchangeDailyLayer.enable()
  local FeatureName = Activity_ExchangeDailyLayer.getFeatureName()
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~FeatureName = "..tostringRich(FeatureName))
  local isEnable = false
  if not FeatureName then
    isEnable = false
  else
    isEnable = MaintenanceManager.isActivityOpen(FeatureName)
    -- Time = MaintenanceManager:getActivityBeginWeekday(activityName)
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Time = "..tostringRich(Time))
    if SystemManager.debug then
      print("Activity_ExchangeDailyLayer isEnable = " .. tostringRich(isEnable))
    end
  end
  return isEnable
end


function Activity_ExchangeDailyLayer.getTipNum()
  if not Activity_ExchangeDailyLayer.enable() then
    --活动未开启
    return 0
  end
  local TotalNum = 0
  local CardExchangeMetaList = Activity_ExchangeDailyLayer.getCardExchangeList()
  --如果CardExchangeMetaList 这个是空 就说明活动刚开 有五次机会
  if CardExchangeMetaList == nil or #CardExchangeMetaList == 0 then
    TotalNum = Activity_ExchangeDailyLayer.getCardNum()  
  else
    local CurrentExchangeTimes = Activity_ExchangeDailyLayer.getCurrentExchangeNum()
    local ExchangeNum = Activity_ExchangeDailyLayer.getCardNum()
    TotalNum = ExchangeNum - CurrentExchangeTimes
  end
  
  return TotalNum
end

function Activity_ExchangeDailyLayer.clear()
  _cardExchangeMetaHash = nil
  _ExchangeMetaByCardId = nil
  _hasEnterd = false
end



function Activity_ExchangeDailyLayer:dispose()
  NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
  Activity_ExchangeDailyLayer.super.dispose(self)
end