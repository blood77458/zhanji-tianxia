--------------------------------------------------------------------------------
-- SkillUpgradeScene.lua - 技能升级
-- author: haoyang.zhuang
--------------------------------------------------------------------------------

require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.request.UpgradeSkillRequest"
require "hecore.ui.LayoutBuilder"
require "canon.panel.SkillShowAnimationPanel"
require "canon.panel.MessageBoxPanel"
require "hecore.ui.TableView"
require "canon.customUI.SuspensionLabel"
require "canon.models.CommonManager"
require "canon.models.RewardManager"
require "canon.data.DataManager"
require "canon.data.MetaManager"
require "canon.utils.TimeUtil"

SkillUpgradeScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function SkillUpgradeScene:ctor()
  self.title = getTextByKey("skillEnhance_Title")
end

function SkillUpgradeScene:create( cardId, skillId, skillName, curLevel, nextLevel, maxLevel, returnScene, inInfoPanel )
  local s = SkillUpgradeScene.new()
  
  self.cardId = cardId
  self.skillId = skillId
  self.skillName = skillName or ""
  self.curLevel = curLevel
  self.nextLevel = nextLevel
  self.maxLevel = maxLevel
  self.returnScene = returnScene
  self.inInfoPanel = inInfoPanel

  s:initScene()
  return s
end

function SkillUpgradeScene:onInit()
  BaseUIScene.initBackGround(self)
  self:addChild(self.mainUI)
  BaseUIScene.onInit(self)
  
  self:Init_All_Books_Info() --产生需要的所有技能书数据
  self:Init_All_Skill_Level_Info() --产生所有技能级别的数据
  
  self.builder = LayoutBuilder:createWithContentsOfFile("scene/skillup.json")
  
  self:Add_BooksList_TableView()
  self:AddControlPanel()

end

function SkillUpgradeScene:Init_All_Books_Info()
  self.BooksTypeTotalNumber = 0 --技能书的数量
  
  self.booksMetaIdList = {} --每种技能书，MetaId号
  self.booksScore = {} --每种技能书，包含的分数（用于计算概率）
  self.booksName = {} --每种技能书，名称
  self.booksEachLevelType = {} --每种技能书，对应的级别
  self.booksHavingNumber = {} --每种技能书，拥有多少个
  self.booksSelectedNum = {} --每种技能书，用户选择的数量
  self.booksSelectedItem = {} --每种技能书，用户选择的元素
  
  local i
  local j
  local k
  local v
  for i,v in pairs( MetaManager.prop_meta ) do
    if tonumber(v.effectType) == 8 then
      self.BooksTypeTotalNumber = self.BooksTypeTotalNumber + 1
      self.booksMetaIdList[self.BooksTypeTotalNumber] = i --技能书MetaId
      self.booksScore[self.BooksTypeTotalNumber] = v.effectValue --技能书在计算概率时的分数
      self.booksName[self.BooksTypeTotalNumber] = getTextByKey(v.name)--技能书的名称
      self.booksEachLevelType[self.BooksTypeTotalNumber] = 0 --技能书级别
      self.booksHavingNumber[self.BooksTypeTotalNumber] = 0 --拥有数量
      self.booksSelectedNum[self.BooksTypeTotalNumber] = 0 --用户选择数量
      self.booksSelectedItem[self.BooksTypeTotalNumber] = {} --用户选择的元素
    end
  end
  
  if self.BooksTypeTotalNumber < 1 then
    return
  end
  
  for j = 1, self.BooksTypeTotalNumber do --排序（按effectValue升序排列）
    for i = self.BooksTypeTotalNumber, j, -1 do
      if i > j then 
        if self.booksMetaIdList[i-1] > self.booksMetaIdList[i] then
          local tmp1 = self.booksMetaIdList[i] --交换1
          self.booksMetaIdList[i] = self.booksMetaIdList[i-1]
          self.booksMetaIdList[i-1] = tmp1
          local tmp2 = self.booksScore[i] --交换2
          self.booksScore[i] = self.booksScore[i-1]
          self.booksScore[i-1] = tmp2
          local tmp3 = self.booksName[i] --交换3
          self.booksName[i] = self.booksName[i-1]
          self.booksName[i-1] = tmp3
        end
      end
    end
  end
  
  for j = 1, self.BooksTypeTotalNumber do --设置技能书级别
    self.booksEachLevelType[j] = j
  end
  
  local InitData = DataManager.getGameInitData()
  for j = 1, self.BooksTypeTotalNumber do --每种技能书的拥有数量
    local Id1 = self.booksMetaIdList[j]
    for i, v in pairs( InitData.sharkProps.sharkProps ) do
      if tonumber(v.metaId) == tonumber(Id1) then
        self.booksHavingNumber[j] = tonumber(v.amount) --存诸数量
        if v.amount >= 1 then
          for k = 1, v.amount do --存储选择状态
            self.booksSelectedItem[j][k] = false
          end
        end
      end
    end
  end
  
--  self:Test_Books_Info() --测试数据正确性
  
end

function SkillUpgradeScene:Test_Books_Info()
  print( "BooksTypeTotalNumber: " .. self.BooksTypeTotalNumber )
  local i
  for i = 1, self.BooksTypeTotalNumber do
    print(string.format( "MetaId: " .. self.booksMetaIdList[i] .. ", Score: " .. self.booksScore[i] .. ", Level: " .. self.booksEachLevelType[i] .. ", Number: " .. self.booksHavingNumber[i] ))
  end
end

function SkillUpgradeScene:Init_All_Skill_Level_Info()
  self.SkillLevelTotalNumber = 10 --技能共有多少个级别
  self.needScore = MetaManager.skill_meta[self.skillId].upgradeValue --在每个级别，升级需要的分数
  self.coinCostAtEachLevel = MetaManager.skill_meta[self.skillId].coin --在每个级别，升级需要的银币数
  self.iconShowInEachLevel = "Item/Picture/" .. MetaManager.skill_meta[self.skillId].icon .. ".png" --在每个级别，显示的图标名
  
--  self:Test_Skill_Level_Info() --测试数据正确性

end

function SkillUpgradeScene:Test_Skill_Level_Info()
  print( "SkillLevelTotalNumber: " .. self.SkillLevelTotalNumber )
  print(string.format( "NeedScore: " .. self.needScore .. ", Coin: " .. self.coinCostAtEachLevel .. ", Icon: " .. self.iconShowInEachLevel ))
end

function SkillUpgradeScene:AddControlPanel()
  self.controlPanel = self.builder:build( "skillup_package_bottom" )
  
  self.controlPanel:getChildByName( "skillup_txt_equip_CoinConsume" ):getChildByName( "txt_equip_CoinConsume" ):setString( getTextByKey("skill_CoinConsume") )
  self.controlPanel:getChildByName( "skillup_txt_need_selection" ):getChildByName( "txt" ):setString( getTextByKey("skill_selectTip") )
  self.controlPanel:getChildByName( "btn_yellow_sure" ):getChildByName( "txt" ):setString( getTextByKey("skill_EnhanceBtn") )
  self.controlPanel:getChildByName( "skillup_txt1" ):getChildByName( "txt" ):setString( getTextByKey("skill_nextLevel") )
  self.controlPanel:getChildByName( "skillup_txt_success_rate" ):getChildByName( "txt" ):setString( getTextByKey("skill_successProbability") )
  
  self.controlPanel:getChildByName( "skillup_txt_skillname_in" ):getChildByName( "txt" ):setString( self.skillName )
  self.controlPanel:getChildByName( "skillup_txt_skill_lv" ):getChildByName( "txt" ):setString( "" .. self.nextLevel )
  
  self.controlPanel:setAnchorPoint(ccp( 0, 0 ))
  self.controlPanel:setPosition(ccp( 0, 0 ))
  self:addChild( self.controlPanel )
  
  local function On_RunUpgrade_Click()
--    print( "On_RunUpgrade_Click" )
    self:Run_Upgrade()
  end
  
  self.UpgradeButton = Button:create( self.controlPanel:getChildByName( "btn_yellow_sure" ) )
  self.UpgradeButton:addEventListener( Events.kStart, On_RunUpgrade_Click, self )
  
  self:RefreshControlState()
end

function SkillUpgradeScene:Calc_Success_Probability()
  local i
  local totalScore = 0
  local totalUseBooksNum = 0
  for i = 1, self.BooksTypeTotalNumber do
    totalScore = totalScore + self.booksSelectedNum[i] * self.booksScore[i]
    totalUseBooksNum = totalUseBooksNum + self.booksSelectedNum[i]
  end
  
  local totalProbability
  if self.needScore > 0 then
    totalProbability = totalScore / self.needScore
    if totalProbability > 1.0 then
      totalProbability = 1.0
    end
    if totalProbability < 0 then
      totalProbability = 0
    end
  else
    totalProbability = 1.0
  end
  
  return totalProbability
end

function SkillUpgradeScene:RefreshControlState()
  local totalProbability = self:Calc_Success_Probability()
  self.controlPanel:getChildByName( "skillup_txt_success_rate_font" ):getChildByName( "txt" ):setString( math.ceil(totalProbability*100) .. "%" )
  
  local totalMoneyCost = self.coinCostAtEachLevel
  self.controlPanel:getChildByName( "skillup_txt_equip_CoinConsume_num" ):getChildByName( "font" ):setString( totalMoneyCost )
  
  local InitData = DataManager.getGameInitData()
  local havingCoins = 0+InitData["sharkUser"].coins
  if havingCoins < totalMoneyCost then
    self.controlPanel:getChildByName( "skillup_txt_equip_CoinConsume_num" ):getChildByName( "font" ):setColor(ccc3( 255, 0, 0 ))
  else
    self.controlPanel:getChildByName( "skillup_txt_equip_CoinConsume_num" ):getChildByName( "font" ):setColor(ccc3( 255, 255, 255 ))
  end
  
  self:RefreshCoinsShow()
end

function SkillUpgradeScene:RefreshCoinsShow()
  local i
  local totalSelectedNum = 0
  for i = 1, self.BooksTypeTotalNumber do
    totalSelectedNum = totalSelectedNum + self.booksSelectedNum[i]
  end
  if totalSelectedNum > 0 then --如果选择了技能书
    self.controlPanel:getChildByName( "skillup_txt_need_selection" ):setVisible( false )
    
    self.controlPanel:getChildByName( "skillup_txt_equip_CoinConsume" ):setVisible( true )
    self.controlPanel:getChildByName( "icon_silverCoin" ):setVisible( true )
    self.controlPanel:getChildByName( "skillup_txt_equip_CoinConsume_num" ):setVisible( true )
    self.controlPanel:getChildByName( "btn_yellow_sure" ):getChildByName( "btn_bg" ):setVisible( true )
    self.UpgradeButton:setEnable( true )
  else --如果没有选择任何技能书
    self.controlPanel:getChildByName( "skillup_txt_need_selection" ):setVisible( true )
    
    self.controlPanel:getChildByName( "skillup_txt_equip_CoinConsume" ):setVisible( false )
    self.controlPanel:getChildByName( "icon_silverCoin" ):setVisible( false )
    self.controlPanel:getChildByName( "skillup_txt_equip_CoinConsume_num" ):setVisible( false )
    self.controlPanel:getChildByName( "btn_yellow_sure" ):getChildByName( "btn_bg" ):setVisible( false )
    self.UpgradeButton:setEnable( false )
  end
end

function SkillUpgradeScene:Add_BooksList_TableView()
  
  SkillUpgrade_Instance = self --全局
  self.TouchEnable = true
  
  local SimpleTableViewRenderer = class(TableViewRenderer)
  function SimpleTableViewRenderer:ctor(width, height)
    self.ShowingTypeNumber = 0
    self.LevelNumber = {}
    self.Total_Page_Number_In_Cell = {}
    self.Current_Page_In_Cell = {}
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/skillup.json")
    if SkillUpgrade_Instance.BooksTypeTotalNumber < 1 then
      return
    end
    local j
    for j = 1, SkillUpgrade_Instance.BooksTypeTotalNumber do
      if SkillUpgrade_Instance.booksHavingNumber[j] > 0 then
        self.ShowingTypeNumber = self.ShowingTypeNumber + 1
        self.list[self.ShowingTypeNumber] = self.ShowingTypeNumber
        self.LevelNumber[self.ShowingTypeNumber] = j
        self.Total_Page_Number_In_Cell[self.ShowingTypeNumber] = math.floor(SkillUpgrade_Instance.booksHavingNumber[j]/8) + 1
        self.Current_Page_In_Cell[self.ShowingTypeNumber] = 1
      end
    end
  end
  function SimpleTableViewRenderer:buildCell(container)
    local OneItem_1 = self.builder:build("skillup_package_list")
    OneItem_1:setTag( -6001 ) --整体
    OneItem_1:getChildByName("skillup_item"):setVisible( false )
    
    OneItem_1:getChildByName("txt_lv_skillbook"):setTag( -11 ) --技能书名称
    OneItem_1:getChildByName("txt_lv_skillbook"):getChildByName("txt"):setTag( -1101 ) --技能书名称txt
    
    OneItem_1:getChildByName("txt_list_page"):setTag( -12 ) --页码
    OneItem_1:getChildByName("txt_list_page"):getChildByName("txt"):setTag( -1012 ) --页码txt
    
    OneItem_1:getChildByName("btn_pgup"):setTag( -13 ) --上一页按钮
    OneItem_1:getChildByName("btn_pgup"):getChildByName("btn_d_many"):setTag( -2013 ) --上一页按钮的颜色图层
    OneItem_1:getChildByName("btn_pgup"):getChildByName("txt"):setTag( -1013 ) --上一页txt
    
    OneItem_1:getChildByName("btn_pgdown"):setTag( -14 ) --下一页按钮
    OneItem_1:getChildByName("btn_pgdown"):getChildByName("btn_d_many"):setTag( -2014 ) --下一页按钮的颜色图层
    OneItem_1:getChildByName("btn_pgdown"):getChildByName("txt"):setTag( -1014 ) --下一页txt
    
    local i
    for i = 1, 8 do
      local x
      local y
      if i <= 4 then
        x = 17 + ( i - 1 ) * 172.2
        y = 404
      else
        x = 17 + ( i - 1 - 4 ) * 172.2
        y = 233
      end
      local newItem = self.builder:build( "skillup_item" )
      
      local newFrame = self.builder:build( "layer/skillup_newFrame" )
      local newFrame_X = x + newItem:getChildByName( "frame_card" ):getPositionX()
      local newFrame_Y = y - newItem:getChildByName( "frame_card" ):getPositionY()
      newFrame:setAnchorPoint(ccp( 0, 0 ))
      newFrame:setPosition(ccp( newFrame_X, newFrame_Y ))
      OneItem_1:addChild( newFrame )
      newFrame:setTag( -3300 - i )
      
      newItem:getChildByName( "normal_card_small" ):setVisible( false )
      newItem:getChildByName( "bg_card" ):setVisible( false )
      newItem:getChildByName( "icon_selected" ):setVisible( false )
      newItem:getChildByName( "frame_card" ):setVisible( false )
      newItem:setAnchorPoint(ccp( 0, 0 ))
      newItem:setPosition(ccp( x, y ))
      OneItem_1:addChild( newItem )
      newItem:setTag( -3000 - i ) --Tag从-3001到-3008
      newItem:getChildByName( "txt_item_name" ):setTag( -61 )
      newItem:getChildByName( "txt_item_name" ):getChildByName( "txt_item_name" ):setTag( -161 )
      newItem:getChildByName( "bg_card" ):setTag( -62 )
      newItem:getChildByName( "icon_selected" ):setTag( -63 )
      newItem:getChildByName( "frame_card" ):setTag( -64 )
      
    end
    
    container:addChild( OneItem_1 )
  end
  function SimpleTableViewRenderer:setData( rawCocosObj, index )
    local OneItem_1 = self:getChildByTag( rawCocosObj, -6001 )
    self:Set_Showing_Data( index+1, OneItem_1 )
  end
  function SimpleTableViewRenderer:Set_Showing_Data( Item_Id, OneItem_1 )
    local booksName = OneItem_1:getChildByTag( -11 ):getChildByTag( -1101 )
    local pageNum = OneItem_1:getChildByTag( -12 ):getChildByTag( -1012 )
    local previousTxt = OneItem_1:getChildByTag( -13 ):getChildByTag( -1013 )
    local nextTxt = OneItem_1:getChildByTag( -14 ):getChildByTag( -1014 )
    
    tolua.cast( booksName, "CCLabelTTF" )
    tolua.cast( pageNum, "CCLabelTTF" )
    tolua.cast( previousTxt, "CCLabelTTF" )
    tolua.cast( nextTxt, "CCLabelTTF" )
    
    local showBooksIndex = self.LevelNumber[Item_Id]
    if showBooksIndex == 1 then
      booksName:setString( getTextByKey("skill_skillBookType1") )
    elseif showBooksIndex == 2 then
      booksName:setString( getTextByKey("skill_skillBookType2") )
    elseif showBooksIndex == 3 then
      booksName:setString( getTextByKey("skill_skillBookType3") )
    elseif showBooksIndex == 4 then
      booksName:setString( getTextByKey("skill_skillBookType4") )
    elseif showBooksIndex == 5 then
      booksName:setString( getTextByKey("skill_skillBookType5") )
    elseif showBooksIndex == 6 then
      booksName:setString( getTextByKey("skill_skillBookType6") )
    elseif showBooksIndex == 7 then
      booksName:setString( getTextByKey("skill_skillBookType7") )
    elseif showBooksIndex == 8 then
      booksName:setString( getTextByKey("skill_skillBookType8") )
    elseif showBooksIndex == 9 then
      booksName:setString( getTextByKey("skill_skillBookType9") )
    elseif showBooksIndex == 10 then
      booksName:setString( getTextByKey("skill_skillBookType10") )
    elseif showBooksIndex == 11 then
      booksName:setString( "十一级技能书" )
    elseif showBooksIndex == 12 then
      booksName:setString( "十二级技能书" )
    elseif showBooksIndex == 13 then
      booksName:setString( "十三级技能书" )
    elseif showBooksIndex == 14 then
      booksName:setString( "十四级技能书" )
    elseif showBooksIndex == 15 then
      booksName:setString( "十五级技能书" )
    elseif showBooksIndex == 16 then
      booksName:setString( "十六级技能书" )
    elseif showBooksIndex == 17 then
      booksName:setString( "十七级技能书" )
    elseif showBooksIndex == 18 then
      booksName:setString( "十八级技能书" )
    elseif showBooksIndex == 19 then
      booksName:setString( "十九级技能书" )
    elseif showBooksIndex == 20 then
      booksName:setString( "二十级技能书" )
    end
    
    local totalPageNumber = self.Total_Page_Number_In_Cell[Item_Id]
    local currentPage = self.Current_Page_In_Cell[Item_Id]
    pageNum:setString( getTextByKey("skill_pageNum") .. currentPage .. "/" .. totalPageNumber )
    
    previousTxt:setString( getTextByKey("skill_pageUpBtn")  )
    
    nextTxt:setString( getTextByKey("skill_pageDownBtn") )
    
    self:Set_Button_State( OneItem_1, Item_Id )
    
    self:Show_Icons( OneItem_1, Item_Id )
    
    self:Refresh_Selected_State( OneItem_1, Item_Id )
    
  end
  function SimpleTableViewRenderer:Set_Button_State( OneItem_1, Item_Id )
    local Using_TotalPageNumber = self.Total_Page_Number_In_Cell[Item_Id]
    local Using_CurrentPage = self.Current_Page_In_Cell[Item_Id]
    
    local previousButton = OneItem_1:getChildByTag( -13 )
    local nextButton = OneItem_1:getChildByTag( -14 )
    
    local previousButtonColor = OneItem_1:getChildByTag( -13 ):getChildByTag( -2013 )
    local nextButtonColor = OneItem_1:getChildByTag( -14 ):getChildByTag( -2014 )
      
    if Using_CurrentPage <= 1 then
      previousButtonColor:setVisible( false )
      
      previousButton.ignoreTouch = true
    else
      previousButtonColor:setVisible( true )
      
      previousButton.ignoreTouch = false
    end
    if Using_CurrentPage >= Using_TotalPageNumber then
      nextButtonColor:setVisible( false )
      
      nextButton.ignoreTouch = true
    else
      nextButtonColor:setVisible( true )
      
      nextButton.ignoreTouch = false
    end
  end
  function SimpleTableViewRenderer:Show_Icons( OneItem_1, Item_Id )
    local This_MetaId = SkillUpgrade_Instance.booksMetaIdList[self.LevelNumber[Item_Id]]
    local This_Showing_Icon = SkillUpgrade_Instance.iconShowInEachLevel[self.LevelNumber[Item_Id]]
    local This_booksHavingNumber = SkillUpgrade_Instance.booksHavingNumber[self.LevelNumber[Item_Id]]
    local This_booksName = SkillUpgrade_Instance.booksName[self.LevelNumber[Item_Id]]
    local Using_TotalPageNumber = self.Total_Page_Number_In_Cell[Item_Id]
    local Using_CurrentPage = self.Current_Page_In_Cell[Item_Id]
    
    local Number_In_This_Page
    if Using_CurrentPage < Using_TotalPageNumber then
      Number_In_This_Page = 8
    else
      Number_In_This_Page = This_booksHavingNumber - ( Using_CurrentPage - 1 ) * 8
    end
      
    local i
    for i = 1, 8 do
      local oneIcon = OneItem_1:getChildByTag( -3000 - i )
      local oneIconTxt = oneIcon:getChildByTag( -61 ):getChildByTag( -161 )
      local oneIconBg = oneIcon:getChildByTag( -62 )
      local oneIconFrame = oneIcon:getChildByTag( -64 )
      tolua.cast( oneIconTxt, "CCLabelTTF" )
      
      local newFrame = OneItem_1:getChildByTag( -3300 - i )
      
      if i <= Number_In_This_Page then
        oneIconTxt:setString( This_booksName )
        oneIcon:setVisible( true )
        newFrame:setVisible( true )
          
        local showingPicture = CanonItem:create() --Sprite.new(CCSprite:create( This_Showing_Icon ))
          showingPicture:loadByMetaId( This_MetaId )
        local wantFrameWidth = 130
        local wantFrameHeight = 130
        showingPicture:setScaleX( 0.9 )
        showingPicture:setScaleY( 0.9 )
        local wantLocationX = wantFrameWidth/2
        local wantLocationY = -wantFrameHeight/2
        showingPicture:setAnchorPoint(ccp( 0.5, 0.5 ))
        showingPicture:setPosition(ccp( wantLocationX, wantLocationY ))
        newFrame:addChild( showingPicture.refCocosObj, 1001 )
      else
        oneIcon:setVisible( false )
        newFrame:setVisible( false )
      end
      
    end
  end
  function SimpleTableViewRenderer:Refresh_Selected_State( OneItem_1, Item_Id )
    local This_booksHavingNumber = SkillUpgrade_Instance.booksHavingNumber[self.LevelNumber[Item_Id]]
    local Using_TotalPageNumber = self.Total_Page_Number_In_Cell[Item_Id]
    local Using_CurrentPage = self.Current_Page_In_Cell[Item_Id]
    
    local booksStartIndex = 1 + ( Using_CurrentPage - 1 ) * 8
    local booksEndIndex = 8 + ( Using_CurrentPage - 1 ) * 8
    if booksEndIndex > This_booksHavingNumber then
      booksEndIndex = This_booksHavingNumber
    end
    
    local This_booksSelectedItem = SkillUpgrade_Instance.booksSelectedItem[self.LevelNumber[Item_Id]]
    
    local j
    for j = booksStartIndex, booksEndIndex do
      local PicId = -3000 - ( j - booksStartIndex + 1 )
      local PicItem = OneItem_1:getChildByTag( PicId )
      local Tick = PicItem:getChildByTag( -63 )
      
      if This_booksSelectedItem[j] then
        Tick:setVisible( true )
      else
        Tick:setVisible( false )
      end
    end
    
  end
  
  function onListItemTouch( evt )
    if self.TouchEnable == false then
      return
    end
--    print("list item touched: [type, index]", evt.name, evt.data)
    
    local function isInArea_LeftTop( position, button ) 
      return position.x > button:getPositionX() and
        position.x < ( button:getPositionX() + button:getContentSize().width ) and 
        position.y > ( button:getPositionY() - button:getContentSize().height ) and 
        position.y < button:getPositionY()
    end
    
    local This_Table_View = self.renderer
    
    local TotalNum = self.renderer.TotalNum
    local aIndex = evt.data + 1
    
    local aCell = self.ListView:cellAtIndex( evt.data )
    local posInCell = aCell:convertToNodeSpace( evt.globalPosition )
--    print(posInCell.x, posInCell.y)
    
    local This_MessageBox = aCell:getChildByTag( -6001 )
    local previousButton = This_MessageBox:getChildByTag( -13 )
    local previousButtonColor = previousButton:getChildByTag( -2013 )
    local nextButton = This_MessageBox:getChildByTag( -14 )
    local nextButtonColor = nextButton:getChildByTag( -2014 )
    local showingPictures = {}
      showingPictures[1] = This_MessageBox:getChildByTag( -3001 )
      showingPictures[2] = This_MessageBox:getChildByTag( -3002 )
      showingPictures[3] = This_MessageBox:getChildByTag( -3003 )
      showingPictures[4] = This_MessageBox:getChildByTag( -3004 )
      showingPictures[5] = This_MessageBox:getChildByTag( -3005 )
      showingPictures[6] = This_MessageBox:getChildByTag( -3006 )
      showingPictures[7] = This_MessageBox:getChildByTag( -3007 )
      showingPictures[8] = This_MessageBox:getChildByTag( -3008 )
    local newFrame = {}
      newFrame[1] = This_MessageBox:getChildByTag( -3301 )
      newFrame[2] = This_MessageBox:getChildByTag( -3302 )
      newFrame[3] = This_MessageBox:getChildByTag( -3303 )
      newFrame[4] = This_MessageBox:getChildByTag( -3304 )
      newFrame[5] = This_MessageBox:getChildByTag( -3305 )
      newFrame[6] = This_MessageBox:getChildByTag( -3306 )
      newFrame[7] = This_MessageBox:getChildByTag( -3307 )
      newFrame[8] = This_MessageBox:getChildByTag( -3308 )
      
    previousButton:setContentSize(CCSize( 103, 38.95 ))
    nextButton:setContentSize(CCSize( 97.7, 38.95 ))
    showingPictures[1]:setContentSize(CCSize( 176, 167.05 ))
    showingPictures[2]:setContentSize(CCSize( 176, 167.05 ))
    showingPictures[3]:setContentSize(CCSize( 176, 167.05 ))
    showingPictures[4]:setContentSize(CCSize( 176, 167.05 ))
    showingPictures[5]:setContentSize(CCSize( 176, 167.05 ))
    showingPictures[6]:setContentSize(CCSize( 176, 167.05 ))
    showingPictures[7]:setContentSize(CCSize( 176, 167.05 ))
    showingPictures[8]:setContentSize(CCSize( 176, 167.05 ))
    newFrame[1]:setContentSize(CCSize( 130, 130 ))
    newFrame[2]:setContentSize(CCSize( 130, 130 ))
    newFrame[3]:setContentSize(CCSize( 130, 130 ))
    newFrame[4]:setContentSize(CCSize( 130, 130 ))
    newFrame[5]:setContentSize(CCSize( 130, 130 ))
    newFrame[6]:setContentSize(CCSize( 130, 130 ))
    newFrame[7]:setContentSize(CCSize( 130, 130 ))
    newFrame[8]:setContentSize(CCSize( 130, 130 ))
    
    local function Is_Previous_Btn_Enabled()
      return previousButtonColor:isVisible()
    end
    local function Is_Next_Btn_Enabled()
      return nextButtonColor:isVisible()
    end
    
    local function On_Previous_Btn_Clicked( OneItem_1, Item_Id )
--      print( "On_Previous_Btn_Clicked" )
      if ( not Is_Previous_Btn_Enabled() ) then
        return
      end
      
      local totalPageNumber = This_Table_View.Total_Page_Number_In_Cell[Item_Id]
      local currentPage = This_Table_View.Current_Page_In_Cell[Item_Id]
      
      if currentPage <= 1 then
        return
      end
      
      This_Table_View.Current_Page_In_Cell[Item_Id] = This_Table_View.Current_Page_In_Cell[Item_Id] - 1
      currentPage = This_Table_View.Current_Page_In_Cell[Item_Id] --重新计算页号
--      print( "New Page Number: " .. currentPage )
      
      This_Table_View:Set_Showing_Data( Item_Id, OneItem_1 )
    end
    
    local function On_Next_Btn_Clicked( OneItem_1, Item_Id )
--      print( "On_Next_Btn_Clicked" )
      if ( not Is_Next_Btn_Enabled() ) then
        return
      end
      
      local totalPageNumber = This_Table_View.Total_Page_Number_In_Cell[Item_Id]
      local currentPage = This_Table_View.Current_Page_In_Cell[Item_Id]
      if currentPage >= totalPageNumber then
        return
      end
      This_Table_View.Current_Page_In_Cell[Item_Id] = This_Table_View.Current_Page_In_Cell[Item_Id] + 1
      currentPage = This_Table_View.Current_Page_In_Cell[Item_Id] --重新计算页号
--      print( "New Page Number: " .. currentPage )
      
      This_Table_View:Set_Showing_Data( Item_Id, OneItem_1 )
    end
    
    local function On_ShowingPicture_Clicked( Pic_Index_In_Cell, Item_Id )
--      print( "On_ShowingPicture_Clicked", Pic_Index_In_Cell )
      
      local This_booksSelectedItem = SkillUpgrade_Instance.booksSelectedItem[This_Table_View.LevelNumber[Item_Id]]
      local totalPageNumber = This_Table_View.Total_Page_Number_In_Cell[Item_Id]
      local currentPage = This_Table_View.Current_Page_In_Cell[Item_Id]
      local Pic_Index_In_Total = Pic_Index_In_Cell + ( currentPage - 1 ) * 8
      
      if This_booksSelectedItem[Pic_Index_In_Total] == true then
        This_booksSelectedItem[Pic_Index_In_Total] = false
        showingPictures[Pic_Index_In_Cell]:getChildByTag( -63 ):setVisible( false )
        SkillUpgrade_Instance.booksSelectedNum[This_Table_View.LevelNumber[Item_Id]] = SkillUpgrade_Instance.booksSelectedNum[This_Table_View.LevelNumber[Item_Id]] - 1
--        print( "Visible: false" )
      else
        local i
        local totalSelectedNum = 0
        for i = 1, SkillUpgrade_Instance.BooksTypeTotalNumber do
          totalSelectedNum = totalSelectedNum + SkillUpgrade_Instance.booksSelectedNum[i]
        end
        if totalSelectedNum < 5 then --最多选择5本
          This_booksSelectedItem[Pic_Index_In_Total] = true
          showingPictures[Pic_Index_In_Cell]:getChildByTag( -63 ):setVisible( true )
          SkillUpgrade_Instance.booksSelectedNum[This_Table_View.LevelNumber[Item_Id]] = SkillUpgrade_Instance.booksSelectedNum[This_Table_View.LevelNumber[Item_Id]] + 1
--          print( "Visible: true" )
        else
          SuspensionLabel:showContent(self, Localization:getInstance():getText( "skill_skillBooksMaxCount" )) --"最多可选5本技能书"
        end
      end
      
      self:RefreshControlState()
      
    end

    if isInArea_LeftTop( posInCell, previousButton ) then
      if Is_Previous_Btn_Enabled() then
        On_Previous_Btn_Clicked( This_MessageBox, aIndex )
      end
    end
    if isInArea_LeftTop( posInCell, nextButton ) then
      if Is_Next_Btn_Enabled() then
        On_Next_Btn_Clicked( This_MessageBox, aIndex )
      end
    end
    if isInArea_LeftTop( posInCell, newFrame[1] ) and newFrame[1]:isVisible() then
      On_ShowingPicture_Clicked( 1, aIndex )
    end
    if isInArea_LeftTop( posInCell, newFrame[2] ) and newFrame[2]:isVisible() then
      On_ShowingPicture_Clicked( 2, aIndex )
    end
    if isInArea_LeftTop( posInCell, newFrame[3] ) and newFrame[3]:isVisible() then
      On_ShowingPicture_Clicked( 3, aIndex )
    end
    if isInArea_LeftTop( posInCell, newFrame[4] ) and newFrame[4]:isVisible() then
      On_ShowingPicture_Clicked( 4, aIndex )
    end
    if isInArea_LeftTop( posInCell, newFrame[5] ) and newFrame[5]:isVisible() then
      On_ShowingPicture_Clicked( 5, aIndex )
    end
    if isInArea_LeftTop( posInCell, newFrame[6] ) and newFrame[6]:isVisible() then
      On_ShowingPicture_Clicked( 6, aIndex )
    end
    if isInArea_LeftTop( posInCell, newFrame[7] ) and newFrame[7]:isVisible() then
      On_ShowingPicture_Clicked( 7, aIndex )
    end
    if isInArea_LeftTop( posInCell, newFrame[8] ) and newFrame[8]:isVisible() then
      On_ShowingPicture_Clicked( 8, aIndex )
    end

  end

  self.renderer = SimpleTableViewRenderer.new( 720, 460 )
  self.cellTag = -6001
  self.buttonTag = { -13, -14, -3301, -3302, -3303, -3304, -3305, -3306, -3307, -3308 }
  self.ListView = TableView:create( self.renderer, 720, 822, self.cellTag, self.buttonTag, CCScale9Sprite:create( CCRectMake(0,0,0,0), "pic/scroll.png"), CCScale9Sprite:create( CCRectMake(0,0,0,0), "pic/scroll.png") )
  self.ListView:setPosition(ccp( 0, 220 ))
  self.ListView.name = "list"
  self.ListView:addEventListener( DisplayEvents.kTouchItem, onListItemTouch , self )
  self:addChild( self.ListView )

  self.ListView.hitTestPoint = function (self, worldPosition, useGroupTest)
    return false -- 修复遮挡下方按钮的bug
  end
  
  if self.renderer.ShowingTypeNumber > 0 then
    if self.showingEmptyTxt ~= nil then
      self.showingEmptyTxt:setVisible( false )
    end
  else
    if self.showingEmptyTxt == nil then
      Max_Hanzi_Num_In_One_Line = 17  --一行中最多有多少个汉字
      
      self.showingEmptyTxt = TextField:create( getTextByKey("skill_skillBagEmpty") )
      self.showingEmptyTxt:setFontSize( 35 )
      self.showingEmptyTxt:setColor(ccc3( 255, 0, 0 ))
      self.showingEmptyTxt:setAnchorPoint(ccp( 0.5, 0.5 ))
      self.showingEmptyTxt:setHorizontalAlignment( kCCTextAlignmentCenter )
      self.showingEmptyTxt:setDimensions(CCSizeMake( 35*Max_Hanzi_Num_In_One_Line, 0 ))
      self.showingEmptyTxt:setPosition(ccp( visibleSize.width/2, 680 ))
      self:addChild( self.showingEmptyTxt )
    end
  end

end

function SkillUpgradeScene:Show_CoinNotEnough_Panel()
  if self.ListView ~= nil then
    self.ListView:setTouchEnabled( false )
  end 
  local aPanel = MessageBoxPanel:create( self, MessageBoxType.kCoinLimit )
  self:addChild( aPanel )
  aPanel:scaleIn()
end
function SkillUpgradeScene:panelDismiss()
  if self.ListView ~= nil and self.ListView.refCocosObj ~= nil then
    self.ListView:setTouchEnabled( true )
  end
end

function SkillUpgradeScene:Run_Upgrade()
  local i
  local totalSelectedNum = 0
  for i = 1, self.BooksTypeTotalNumber do
    totalSelectedNum = totalSelectedNum + self.booksSelectedNum[i]
  end
  if totalSelectedNum <= 0 then --首先保证已经选择技能书
    return
  end
  
  local function Upgrade_Finished( e )
--    print( "Old SkillId: " .. self.skillId .. ", New SkillId: " .. e.data.cardSkill.skillId )
    
--步骤1：修改银币数量
    local needCoins = self.coinCostAtEachLevel
    local negativeReward = {
      { itemType = ResourceEnum.COIN,
        amount = -1 * needCoins
      }
    }
    RewardManager:getReward( negativeReward )
--步骤2：修改技能书数量
    if self.BooksTypeTotalNumber >= 1 then
      local i
      local negativeReward = {}
      local usedNumber = 0
      for i = 1, self.BooksTypeTotalNumber do
        if self.booksSelectedNum[i] > 0 then
          usedNumber = usedNumber + 1
          negativeReward[usedNumber] = {
              itemType = ResourceEnum.PROP,
              metaId = self.booksMetaIdList[i],
              amount = -1 * self.booksSelectedNum[i]
            }
        end
      end
      if usedNumber > 0 then
        RewardManager:getReward( negativeReward )
      end
    end
--步骤3：修改技能
    if e.data.cardSkill.skillId ~= self.skillId then
      local GameData = DataManager.getGameInitData()
      local aCard, aCardKey = CommonManager.getSubTableByKey(
        GameData.sharkCards.sharkCards,
        {name = "cardId", value = self.cardId}
      )
      local aSkill, aSkillKey = CommonManager.getSubTableByKey(
        aCard["cardSkills"],
        {name = "skillId", value = self.skillId}
      )
      aCard["cardSkills"][aSkillKey]["skillId"] = e.data.cardSkill.skillId
      GameData.sharkCards.sharkCards[aCardKey] = aCard
      DataManager.setGameInitData(GameData)
    end
    
--显示结果：
    local function On_SuccessOK_Click()
      if self.nextLevel+1 <= self.maxLevel then
        local newScene = SkillUpgradeScene:create( self.cardId, e.data.cardSkill.skillId, self.skillName, self.curLevel+1, self.nextLevel+1, self.maxLevel, self.returnScene, self.inInfoPanel )
        Director:sharedDirector():replaceScene( newScene )
      else
        self:back()
      end
    end
    local function On_FailedOK_Click()
      local newScene = SkillUpgradeScene:create( self.cardId, self.skillId, self.skillName, self.curLevel, self.nextLevel, self.maxLevel, self.returnScene, self.inInfoPanel )
      Director:sharedDirector():replaceScene( newScene )
    end
    if e.data.cardSkill.skillId ~= self.skillId then
      SkillShowAnimationPanel:Show( self.skillId, true, self.curLevel, self.nextLevel, On_SuccessOK_Click )
--      CanonMessageBox:Show( "升级成功！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, On_SuccessOK_Click )
    else
      SkillShowAnimationPanel:Show( self.skillId, false, self.curLevel, self.nextLevel, On_FailedOK_Click )
--      CanonMessageBox:Show( "升级失败！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, On_FailedOK_Click )
    end
  end
  
  local function Upgrade_Error( e )
    if e.data == 712014 then --"Param skillBookIds's size is more than five: {0:skillBookIdsNum}"
      CanonMessageBox:Show( getTextByKey("skill_skillBooksMaxCount"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ) --"选择的技能书数量不能超过5本"
    elseif e.data == 712005 then --"CardSkill has reached max level: {0:uid}, {1:cardId}, {2:skillId}"
      CanonMessageBox:Show( getTextByKey("skillEnhance_Tips"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ) --"此技能已达到最大等级"
    elseif e.data == 712013 then --"Prop is not skill book: {0:propMetaId}, {1:propType}"
      CanonMessageBox:Show( getTextByKey("skill_mustChooseSkillBook"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ) --"选择的必须是技能书"
    elseif e.data == 710512 then --"Coin is not enough: {0:uid}, {1:currCoin}, {2:needCoin}"
      self:Show_CoinNotEnough_Panel()
    elseif e.data == 712301 then --"Prop is not enough: {0:uid}, {1:propId}, {2:ownNum}, {3:needNum}"
      CanonMessageBox:Show( getTextByKey("skill_skillBookNotEnough"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ) --"技能书不足"
    elseif e.data == 712015 then
      CanonMessageBox:Show( getTextByKey("skill_skillUpgradeLevelLimit") .. (self.curLevel*10), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
    else
      CanonMessageBox:showCommUnHandleErrorBox( e.data )
    end
  end

  local InitData = DataManager.getGameInitData()
  local havingCoins = 0+InitData["sharkUser"].coins
  local needCoins = self.coinCostAtEachLevel
  if havingCoins < needCoins then
--    print( "needCoins: " .. needCoins .. ", havingCoins: " .. havingCoins )
    self:Show_CoinNotEnough_Panel()
    return
  end
  
  local skillBooks1 = {}
    local num = 0
    local i
    local j
    for j = 1, self.BooksTypeTotalNumber do
      if self.booksSelectedNum[j] > 0 then
        for i = 1, self.booksSelectedNum[j] do
          num = num + 1
          skillBooks1[num] = self.booksMetaIdList[j]
        end
      end
    end
  local skillUpgradeParams = { cardId = self.cardId, skillId = self.skillId, skillBooks = skillBooks1 }
        
  local upgradeSkill = UpgradeSkillRequest.new( skillUpgradeParams, rpc.SendingPriority.kHigh )
  upgradeSkill:addEventListener( RequestNotifyEnum.UpgradeSkillSucceed, Upgrade_Finished )
  upgradeSkill:addEventListener( RequestNotifyEnum.UpgradeSkillFailed, Upgrade_Error )
  upgradeSkill:start()
end

function SkillUpgradeScene:moveToTower()
  --[[
  local function Success(event)
    if event ~= nil then
      DataManager.GetBabelInfoData = event.data
      DataManager.GetBabelInfoData._DownloadDataTime = TimeUtil.getServerTimeSeconds()
    end
    self:replaceScene( SkyTowerMainScene )
  end
  local function Failed(event)
    if event.data == 713103 then
      SuspensionLabel:showContent(self, Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel}))
    end
  end
    
  local userData = DataManager.getCurrUser()
  if ( userData.level >= MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel ) then
    local params = {}
    local getBabelInfoRequest = GetBabelInfoRequest.new( params, rpc.SendingPriority.kHigh )
    getBabelInfoRequest:addEventListener( RequestNotifyEnum.GetBabelInfoSucceed, Success )
    getBabelInfoRequest:addEventListener( RequestNotifyEnum.GetBabelInfoFailed, Failed )
    getBabelInfoRequest:start()
  else
    SuspensionLabel:showContent(self, Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel}))
  end]]
  ChallengeEntersScene.readyToNewBabelEnterPanel()
end

function SkillUpgradeScene:setTableViewsEnabled(v)
  if self.ListView ~= nil then
    self.ListView:setTouchEnabled(v)
  end
end

function SkillUpgradeScene:back()
  if not self.returnScene then
    self:replaceScene( CardQueueScene )
  elseif self.inInfoPanel then
    if self.returnScene == SceneEnum.MatrixScene then
      self:replaceScene(MatrixScene, {enterScene=nil,returnScene=nil,params={cardId = self.cardId, infoPanelTabType = tabTypeEnum.skill}})
    elseif self.returnScene == SceneEnum.CardQueueScene then
      self:replaceScene(CardQueueScene, {enterScene="EquipUpgradeScene",returnScene=nil,params={cardId = self.cardId, infoPanelTabType = tabTypeEnum.skill}})
    elseif self.returnScene == SceneEnum.BackpackScene then
      self:replaceScene(BackpackScene, {params = {isCardTrain = false, cardId = self.cardId, infoPanelTabType = tabTypeEnum.skill}})
    end
  else
    self:replaceScene( CardQueueScene )
  end
end

function SkillUpgradeScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function SkillUpgradeScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function SkillUpgradeScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  
  self:nodeAnimationFinished()
end

function SkillUpgradeScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function SkillUpgradeScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation() 
end

function SkillUpgradeScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function SkillUpgradeScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  
  self:nodeAnimationFinished()
end

function SkillUpgradeScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end






