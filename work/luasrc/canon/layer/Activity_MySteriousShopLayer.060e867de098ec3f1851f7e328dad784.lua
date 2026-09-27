
require "canon.request.ExchangeMysteriousItemRequest"
require "hecore.display.Layer"
require "canon.panel.ActivityInfoPanel"
require "canon.models.RewardManager"


local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_MySteriousShopLayer = class(Layer)
local function onPassDay(evt)
  local self = evt.context
 
  local ExchangeMetas =  Activity_MySteriousShopLayer.getExchangeMetas()
  local TimesList = {}
  for _,config in ipairs(ExchangeMetas) do
    TimesList[config.id] = {nodeId = config.id , times = 0 }
  end

  DailyDataManager.setMysteriousExchangeTimes(TimesList)
  self.refresh()
  local offsetY = self.tableView:getContentOffset().y
  self.tableView:reloadData()
  self.tableView:setContentOffset(ccp(0, offsetY), false)
end
function Activity_MySteriousShopLayer:ctor()
  self.container = nil
  self.GeneralConfig = {}
  self.EquipConfig = {}
  self.refresh = nil
end

function Activity_MySteriousShopLayer:create( container , extraArgs)
  self.container = container
  local s = Activity_MySteriousShopLayer.new()
  s:initLayer()
  return s
end

function Activity_MySteriousShopLayer:enable(curTimeStamp)

  local FeatureName = Activity_MySteriousShopLayer.getFeatureName()
  local isEnable = false
  if not FeatureName then
    isEnable = false
  else
    isEnable = MaintenanceManager.isActivityOpen(FeatureName)
    
    if SystemManager.debug then
      print("Activity_MySteriousShopLayer isEnable = " .. tostringRich(isEnable))
    end
  end
  return isEnable
    
end 

function Activity_MySteriousShopLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_MySteriousShopLayer:dispose()
  NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
  Activity_MySteriousShopLayer.super.dispose(self)
end

function Activity_MySteriousShopLayer:initLayer()
    Activity_MySteriousShopLayer.super.initLayer(self)
    -- print("消耗金币"..MetaManager.getGameSettingConfig().secretShopConfig.refreshGoldCost)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity_02.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("launch_activity_mysteriouStore")
	local table_temp_view = self.mainUI:getChildByName("table_activity_shangcheng_list")
	table_temp_view:setVisible(false)
	self.table_meta_info = getTableViewSizes(table_temp_view)

	self.GeneralConfig =  Activity_MySteriousShopLayer.getGeneralConfig()
  self.EquipConfig =  Activity_MySteriousShopLayer.getEquipConfig()
  local function changeTimeslist()
      local ExchangeTimes  = DailyDataManager.getMysteriousExchangeTimes()
      local TimesList = {}
      local ExchangeMetas =  Activity_MySteriousShopLayer.getExchangeMetas()
      for _,Times in ipairs(ExchangeTimes) do
        local nodeId = tonumber(Times.nodeId)
        TimesList[nodeId] = Times
      end
      for _,config in ipairs(ExchangeMetas) do
        if TimesList[config.id] == nil then
          TimesList[config.id] = {nodeId = config.id , times = 0 }
        end
      end
      DailyDataManager.setMysteriousExchangeTimes(TimesList)
  end
  self.changeTimeslist = changeTimeslist
  local SharkMysteriousCoinsConfig = DataManager.getSharkMysteriousCoinsData()
   local NewMysteriousCoinsConfig = {}
  for _,config in ipairs(SharkMysteriousCoinsConfig) do
    NewMysteriousCoinsConfig[config.metaId] = config
  end
  
  for i=1,5 do
    if NewMysteriousCoinsConfig[i] == nil then
      NewMysteriousCoinsConfig[i] = {metaId = i,amount = "0"}
    end
  end
  DataManager.setSharkMysteriousCoinsData(NewMysteriousCoinsConfig)
  local function SetIconandTxtVisible(visible)
  	for i=1,4 do
  		self.mainUI:getChildByName("icon_Currency"..i):setVisible(visible)
  		if i ~= 1 then
	  		self.mainUI:getChildByName("txt_"..i):setVisible(visible)
	  	end
  	end
  end
  
  
  local function SetMoneyTxt(num)
    local SharkMysteriousCoinsData = DataManager.getSharkMysteriousCoinsData()
    if num then
	  	self.mainUI:getChildByName("txt_1"):getChildByName("txt"):setString(SharkMysteriousCoinsData[num].amount)
	  else
  		for i=1,4 do
          -- print("~~~~~~~~~~~~~~~~~~SharkMysteriousCoinsData = "..tostringRich(SharkMysteriousCoinsData))
          -- print("~~~~~~~~~~~~~~~~~~123 = "..tostringRich(SharkMysteriousCoinsData[i]))
  	  		self.mainUI:getChildByName("txt_"..i):getChildByName("txt"):setString(SharkMysteriousCoinsData[i].amount)
  		end
        
	  end
  end

  local function LeftBtnStaus(adjude)
    if not adjude then
      self.LeftBtn:setEnable(false)
      self.RightBtn:setEnable(true)
    end
    self.LeftUI:getChildByName("friend_btn_tab_inactive"):setVisible(not adjude)
  end
  local function RightBtnStaus(adjude)
    if not adjude then
      self.LeftBtn:setEnable(true)
      self.RightBtn:setEnable(false)
    end
    self.RightUI:getChildByName("friend_btn_tab_inactive"):setVisible(not adjude)
  end
  local function CreateNewTable(NewDateList)
  	if self.tableView then
	    self.tableView:removeFromParentAndCleanup(true)
	    self.tableView = nil
	end
    self.dataList = NewDateList
    self.tableView = self:createTableView(self.dataList)
    self.mainUI:addChild(self.tableView)
  end
  local function onLeftBtnFun(evt)
    self.dataList = self.GeneralConfig--{1,2,3,4,5,6,7,8,9}
    SetIconandTxtVisible(true)
    CreateNewTable(self.dataList)
    LeftBtnStaus(false)
    RightBtnStaus(true)
    self.mainUI:getChildByName("icon_Currency5"):setVisible(false)
    SetMoneyTxt()
  end

  local function onRightBtnFun(evt)
    self.dataList = self.EquipConfig--{1,2,3,4}
    SetIconandTxtVisible(false)
    CreateNewTable(self.dataList)
    LeftBtnStaus(true)
    RightBtnStaus(false)
    self.mainUI:getChildByName("icon_Currency5"):setVisible(true)
    SetMoneyTxt(5)

  end
   --问号按钮
  local  function helpBtnAction(evt)
    local para = evt.context
    self.container:setTableViewsEnabled(false)

    
    local aInfoPanel = ActivityInfoPanel:create(self.container, getTextByKey("Mysterious_titel7"))
    self.container:addChild(aInfoPanel)
    aInfoPanel:scaleIn()

  end
  local function refresh()
    if self.RightUI:getChildByName("friend_btn_tab_inactive"):isVisible() then
      SetMoneyTxt(5)
    else
      SetMoneyTxt()
    end
  end
  self.refresh = refresh
    --关闭按钮
    -- --login_btn_close
    local  HelpBtn = Button:create(self.mainUI:getChildByName("sky_btn_qa"))

    HelpBtn:addEventListener(Events.kStart, helpBtnAction, self)
    self.mainUI:getChildByName("across_wj_game"):getChildByName("txt"):setString(getTextByKey("Mysterious_titel3"))
    self.mainUI:getChildByName("across_zb_game"):getChildByName("txt"):setString(getTextByKey("Mysterious_titel4"))
    self.LeftUI = self.mainUI:getChildByName("across_wj_game")
    self.LeftBtn = Button:create(self.LeftUI)

    self.LeftBtn:addEventListener(Events.kStart, onLeftBtnFun, self)
 
    self.RightUI = self.mainUI:getChildByName("across_zb_game")
    self.RightBtn = Button:create(self.RightUI)

    self.RightBtn:addEventListener(Events.kStart, onRightBtnFun, self)

    self.RightUI:getChildByName("friend_btn_tab_inactive"):setVisible(false)
    self.mainUI:getChildByName("icon_Currency5"):setVisible(false)
    self.LeftBtn:setEnable(false)
    self.RightBtn:setEnable(true)
    self.refresh()
    self.changeTimeslist()
    self.dataList = self.GeneralConfig--{1,2,3,4,5,6,7,8,9} 
    
    self.tableView = self:createTableView(self.dataList)
    
    self.mainUI:addChild(self.tableView)
    self:addChild(self.mainUI)
	  NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)

end

function Activity_MySteriousShopLayer:createTableView(data)
  local cellTag = 1024
  local buttonTag = {}

  local Activity_MySteriousShopLayerRenderer = class(TableViewRenderer)
  
    function Activity_MySteriousShopLayerRenderer:ctor(width, height, creater)
    self.list = data or {}
    self.creater = creater
  end

  function Activity_MySteriousShopLayerRenderer:buildCell(container)
      local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity_02.json")
      local aCombineCell = builder:build("activity_shangcheng_list_1")
      container:addChild(aCombineCell)
      aCombineCell:setTag(cellTag)
      for i=1,3 do
      	--activity_wj_list2
      	local aCell = aCombineCell:getChildByName("activity_wj_list"..i)
      	aCell:setTag(-10-i)
      	local Icon = aCombineCell:getChildByName("normal_card_small"..i)
      	Icon:setTag(-20-i)
        -- txt_n_1
      	local MoneyTxt = aCell:getChildByName("txt_n_1")
      	MoneyTxt:setTag(-30-i)
        MoneyTxt:getChildByName("txt"):setTag(-30-i)

        local ExchangeBtn = aCombineCell:getChildByName("btn_blue_short"..i)
      	ExchangeBtn:setTag(-40-i)
        
        -- ExchangeBtn:getChildByName("txt"):setTag(-40-i)
        ExchangeBtn:getChildByName("txt"):setString(getTextByKey("Mysterious_titel5"))
        ExchangeBtn:getChildByName("btn_blue_short"):setTag(-40-i)

        for i=1,5 do
            local MoneyIcon = aCell:getChildByName("icon_Money"..i)
            MoneyIcon:setTag(-50-i)
        end
        

      end
  
  end

   local function setNodeVisibleByTag(cell, tag, visible)
    cell:getChildByTag(tag):setVisible(visible)
  end

  local function setTextByTag(cell, tag, str)
    local txt = cell:getChildByTag(tag):getChildByTag(tag)
    setNodeText(txt, str)
  end

  local function setColorByTag(cell, tag,color)
    local txt = cell:getChildByTag(tag):getChildByTag(tag)
    if type(txt.setColor) == "function" then
      txt:setColor(color)
    end
  end

  local function setIconVisibleByTag(cell, num)

    for i=1,5 do
        if i == num then
    		cell:getChildByTag(-50-i):setVisible(true)	
    	else
	    	cell:getChildByTag(-50-i):setVisible(false)	
    	end
    end
  end



  function Activity_MySteriousShopLayerRenderer:setData(rawCocosObj, index)
    
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local data = self.list[index + 1]
    local SharkMysteriousCoinsData = DataManager.getSharkMysteriousCoinsData()
    for i=1,3 do
    	if not aCell:getChildByTag(-40-i):isVisible() then
  			setNodeVisibleByTag(aCell, -40-i, true)
    	end
    	local oldIcon = aCell:getChildByTag(-100-i)
        if oldIcon then
          oldIcon:removeFromParentAndCleanup(true)
        end
        local cell = aCell:getChildByTag(-10 - i)
        if data[i] then
        	local aCardDisplay = aCell:getChildByTag(-20-i)
        	local params = {}
	        params.sourceDisplay = aCardDisplay
	        params.showInCenter = true
          local ExchangeTimes  = DailyDataManager.getMysteriousExchangeTimes()
        	local config = data[i]
        	local icon = CanonGoodIcon.createGoodIcon(config.goodsType, config.goodsId, config.goodsNum, params)
          local item_bg = Sprite:create(UI_RES_PATH.."/launch_activity_02/bg_small_number.png")
          item_bg:setPosition(ccp(15, -50))
          item_bg:setScaleY(1.2)
         local NowTime = TextField:create("/" .. config.mysteriousShopNum,"Arial", 25)
          NowTime:setPosition(ccp(81, 10))
          item_bg:addChild(NowTime)
          local subTimes = tonumber(config.mysteriousShopNum) - tonumber(ExchangeTimes[config.id].times) 
          local TimesAll = TextField:create(subTimes,"Arial", 25)
          TimesAll:setPosition(ccp(63, 10))
          if subTimes > 0 then
              TimesAll:setColor(ccc3(89,188,62))

          else
              TimesAll:setColor(ccc3(234,85,4))
          end
          item_bg:addChild(TimesAll)
          icon:addChild(item_bg)
          aCell:addChild(icon.refCocosObj,2001)
          
	        if icon then
	          icon:setTag(-100-i)
	          icon:dispose()
	        end
            setTextByTag(cell, -30-i,config.coinNum )
            setIconVisibleByTag(cell, config.coinId)
           
            if tonumber(config.coinNum) > tonumber(SharkMysteriousCoinsData[config.coinId].amount) or tonumber(ExchangeTimes[config.id].times) >= tonumber(config.mysteriousShopNum) then
              aCell:getChildByTag(-40-i):getChildByTag(-40-i):setVisible(false)
            else
              aCell:getChildByTag(-40-i):getChildByTag(-40-i):setVisible(true)
           end
            
            
           
            -- print("~~~~~~~~~~~~~~~~~~~~SharkMysteriousCoinsData[config.coinId].amount = "..SharkMysteriousCoinsData[config.coinId].amount)
            -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~config.coinNum = "..tostringRich(config.coinNum))
            -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ExchangeTimes[config.id] = "..tostringRich(ExchangeTimes[config.id]))
            -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~config.mysteriousShopNum = "..tostringRich(config.mysteriousShopNum))
            if tonumber(config.coinNum) > tonumber(SharkMysteriousCoinsData[config.coinId].amount) then
              setColorByTag(cell, -30-i,ccc3(234,85,4))
            else
              setColorByTag(cell, -30-i,ccc3(0,0,0))
            end
        else
          cell:setVisible(false)
          setNodeVisibleByTag(aCell, -20-i, false)
          setNodeVisibleByTag(aCell, -40-i, false)
        end
    end
       
  end
    local function onListItemTouch( evt )
      local aIndex = evt.data + 1
      local aCell = self.tableView:cellAtIndex(aIndex-1)
      local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
      local childs = aCell:getChildByTag(cellTag)
      local iconSize = {
      height = 110,
      width = 110,
      }
        
      local ChangeSize ={
        height = 46,
        width = 118,
      }  
      
      function getTouchedItemIndex()
     
        local aCombineData = self.dataList[aIndex]--self.dataList

        for i=1, 3 do
          local Config = aCombineData[i]
          if Config  and Config.goodsType ~= ResourceEnum.PROP then
            local aBtnArea = childs:getChildByTag(-20-i)
            
            if ((posInCell.x > aBtnArea:getPositionX()-iconSize.width*0) and
              (posInCell.x < aBtnArea:getPositionX()+iconSize.width) and
              (posInCell.y > aBtnArea:getPositionY()-iconSize.height*0.9) and
              (posInCell.y < aBtnArea:getPositionY()+iconSize.height/20)) then
              return i
            end
          end
        end

        for i=1,3 do
          local Config = aCombineData[i]
          if Config and childs:getChildByTag(-40-i):getChildByTag(-40-i):isVisible()  then
            local aBtnArea = childs:getChildByTag(-40-i)
            
            if ((posInCell.x > aBtnArea:getPositionX()-ChangeSize.width/25) and
              (posInCell.x < aBtnArea:getPositionX()+ChangeSize.width*0.9) and
              (posInCell.y > aBtnArea:getPositionY()-ChangeSize.height*0.9) and
              (posInCell.y < aBtnArea:getPositionY()+ChangeSize.height*0)) then
              return i+3
            end
          end
        end
        return -1
      end
      local itemIndex = getTouchedItemIndex()
    -- print("~~~~~~~~~~~~~~itemIndex = "..tostring(itemIndex))
      local aCombineData = self.dataList[aIndex]
      if  (itemIndex<4 and itemIndex>0) then
        local Config = aCombineData[itemIndex]
        if Config and Config.goodsType ~= ResourceEnum.PROP then
          CanonGoodIcon.popoutGoodPanel(Config.goodsType, Config.goodsId)
        end
      elseif (itemIndex<7 and itemIndex>3) then
        local Config = aCombineData[itemIndex-3]
        if Config and childs:getChildByTag(-40-itemIndex+3):getChildByTag(-40-itemIndex+3):isVisible() then
          if BagCalcManager.isFull() then
              NewPackageFullPanel:show()
              return
          end
          local function succeedCallback(event)

            RewardManager:getReward({{itemType = ResourceEnum.MysteriousCoins, metaId = Config.coinId, amount = -Config.coinNum},{itemType = Config.goodsType, metaId = Config.goodsId,amount = Config.goodsNum}})
            local ExchangeTimes  = DailyDataManager.getMysteriousExchangeTimes()
            ExchangeTimes[Config.id].times = ExchangeTimes[Config.id].times + 1
            DailyDataManager.setMysteriousExchangeTimes(ExchangeTimes)
            self.refresh()
            local offsetY = self.tableView:getContentOffset().y
            self.tableView:reloadData()
            self.tableView:setContentOffset(ccp(0, offsetY), false)
            
            local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = {{itemType = Config.goodsType, metaId = Config.goodsId,amount = Config.goodsNum}}, rewardTitle = Localization:getInstance():getText("Mysterious_titel8")} )
            self.container:addChild(aRewardPanel)
            aRewardPanel:scaleIn()
          end
          ExchangeMysteriousItemRequest.sendRequestDefalut( {ID = Config.id},succeedCallback)
         
        end
      end
    end
  
  
 
  local renderer = Activity_MySteriousShopLayerRenderer.new(self.table_meta_info.item_width, self.table_meta_info.item_height)
  local aTableView = TableView:create(renderer, self.table_meta_info.table_width, self.table_meta_info.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
 
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)

  aTableView:setPosition(ccp(self.table_meta_info.table_posX, self.table_meta_info.table_posY))
  return aTableView
end




function Activity_MySteriousShopLayer:setTouchEnabled(v)
  self.tableView:setTouchEnabled(v)
end

--获得配置
function Activity_MySteriousShopLayer.getMetas()
  return DataManager.GameMetaData.activityMysteriousExchangeConfig
end

--获得活动开关名称
function Activity_MySteriousShopLayer.getFeatureName()
  local metas = Activity_MySteriousShopLayer.getMetas()
  if not metas then
    --防崩
    return nil
  end
  return metas.featureName
end

function Activity_MySteriousShopLayer.getExchangeMetas()
   local metas = Activity_MySteriousShopLayer.getMetas()
  if not metas then
    --防崩
    return nil
  end
  if not metas.exchangeMetas then
    --防崩
    return nil
  end

  return metas.exchangeMetas
end

function Activity_MySteriousShopLayer.getGeneralConfig()
  local metas = Activity_MySteriousShopLayer.getMetas()
  if not metas then
    --防崩
    return nil
  end
  if not metas.exchangeMetas then
    --防崩
    return nil
  end
  local GeneralConfig = {}
  local NewGeneralConfig = {}
  local index = 0
  local num = 1
  for _,Config in ipairs(metas.exchangeMetas) do
  	if Config.listId == 1 then
  		table.insert(GeneralConfig,Config)
  	end
  end

  for i,config in ipairs(GeneralConfig) do
  	 if type(NewGeneralConfig[num]) ~= "table" then
	  	  NewGeneralConfig[num] = {}
  	 end
  	  table.insert(NewGeneralConfig[num],config)
  	  index = index + 1
  	  if index == 3 then
  	  	index = 0 
  	  	num = num + 1
  	  end
  end
 
 
  return NewGeneralConfig
end


function Activity_MySteriousShopLayer.getEquipConfig()
  local metas = Activity_MySteriousShopLayer.getMetas()
  if not metas then
    --防崩
    return nil
  end
  if not metas.exchangeMetas then
    --防崩
    return nil
  end
  local EquipConfig = {}
  local NewGeneralConfig = {}
  local index = 0
  local num = 1
  for _,config in ipairs(metas.exchangeMetas) do
  	if config.listId == 2 then
  		table.insert(EquipConfig,config)
  	end
  end

    for i,config in ipairs(EquipConfig) do
	  	 if type(NewGeneralConfig[num]) ~= "table" then
		  	  NewGeneralConfig[num] = {}
	  	 end
	  	  table.insert(NewGeneralConfig[num],config)
	  	  index = index + 1
	  	  if index == 3 then
	  	  	index = 0 
	  	  	num = num + 1
	  	  end
    end
  return NewGeneralConfig
end


function Activity_MySteriousShopLayer.getTipNum()
  if not Activity_MySteriousShopLayer.enable() then
    return 0
  end
  return 0
  -- return HeMemDataHolder:getInteger("Activity_SecretShopTips")
end