--------------------------------------------------------------------------------
-- AdjustTeamScene.lua -- 调整队列页面
-- author: Jiang Yize
-- date: 2013-11-19
--------------------------------------------------------------------------------

require "canon.data.DataManager"
require "canon.data.MetaManager"
require "canon.models.CommonManager"
require "canon.request.AdjustTeamRequest"
require "canon.scene.BaseUIScene"
require "canon.utils.ViewControlUtil"

AdjustTeamScene = class(BaseUIScene)

----------------------------------
-- UI常量
----------------------------------
local CELL_WIDTH = 720
local CELL_HEIGHT = 185
local CELL_POS_X = 0
local LIST_WIDTH = 720
local LIST_HEIGHT = 925
local LIST_POS_X = 0
local LIST_POS_Y = 120

----------------------------------
-- TAG常量
----------------------------------
local TAG_CELL = -1001
local TAG_PIC = 1001
local TAG_FRAME_CARD = 1002
local TAG_EARTH_PANEL = 1003
local TAG_TXT_CARD_NAME = 1101
local TAG_TXT_LV_NUM = 1102
local TAG_TXT_ATK_NUM = 1103
local TAG_TXT_DEF_NUM = 1104
local TAG_TXT_HP_NUM = 1105
local TAG_ICON_CAPTAIN = 1201
local TAG_ICON_WHITE = 1211
local TAG_ICON_GREEN = 1212
local TAG_ICON_BLUE = 1213
local TAG_ICON_PURPLE = 1214
local TAG_ICON_ORANGE = 1215
local TAG_ICON_RED = 1216
local TAG_ICON_GOLD = 1217
local TAG_BTN_CHANGE = 1301
local TAG_PIC_CHANGE = 1302
local TAG_FIRST_STAR = 1401
local TAG_TXT_PERFECT = 1402

----------------------------------
----------------------------------
local VISIBLE_SIZE = CCDirector:sharedDirector():getVisibleSize()
local MAX_RARE_NUM = 7
local ADJUST_STATUS = table.const {
  NOT_SELECTED = 1,   -- 未选中卡牌
  SELECTED = 2,       -- 选中卡牌
}

----------------------------------
-- 全局变量
----------------------------------
local UiStatus = ADJUST_STATUS.NOT_SELECTED
local SelectedCellIndex = nil
local QueueData = nil

----------------------------------------
-- 构造函数
----------------------------------------
function AdjustTeamScene:ctor()
  self.title = getTextByKey("queue_transpositionSet")
  UiStatus = ADJUST_STATUS.NOT_SELECTED
  SelectedCellIndex = nil
  QueueData = CommonManager.getQueueData()
end

----------------------------------------
-- 创建Scene
----------------------------------------
function AdjustTeamScene:create()
  local scene = AdjustTeamScene.new()
  scene:initScene()
  return scene
end

----------------------------------------
-- 返回按钮
----------------------------------------
function AdjustTeamScene:back()
  self:replaceScene(CardQueueScene)
end

----------------------------------------
-- 设置TableView是否可以点击
----------------------------------------
function AdjustTeamScene:setTableViewsEnabledInner(v)
  if self.tableView then
    self.tableView:setTouchEnabled(v)
  end
end

----------------------------------------
-- 生成TableView
----------------------------------------
function AdjustTeamScene:createTableView(argv)
  -- 卡牌Renderer
  local CardCellRenderer = class(TableViewRenderer)
  
  -- 构造函数中计算cell个数
  function CardCellRenderer:ctor(width, height)
    for i = 1, #QueueData do
      self.list[i] = i
    end
  end
  
  local firstStarPosX, firstStarPosY, starGapX
    
  -- 构建卡牌信息Cell  
  function CardCellRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/formation_new.json")
    builder.useArtLabelTTF = true
    local cell = builder:build("formation_card")
    cell:setPosition(ccp(CELL_POS_X, self.height))
    cell:setTag(TAG_CELL)
    container:addChild(cell)
    
    -- 背景高亮
    cell:getChildByName("earth_yellow9_panel"):setTag(TAG_EARTH_PANEL)
    -- 卡牌图片
    cell:getChildByName("normal_card_big"):setAnchorPoint(ccp(0.5, 0.5))
    cell:getChildByName("normal_card_big"):setTag(TAG_PIC)
    cell:getChildByName("normal_card_big"):setVisible(false)
    cell:getChildByName("icon_captain_mark"):setTag(TAG_ICON_CAPTAIN)
    cell:getChildByName("icon_captain_mark"):setVisible(false)
    cell:getChildByName("frame_card"):setTag(TAG_FRAME_CARD)
    cell:getChildByName("frame_card"):setVisible(false)
    -- 卡牌名称
    cell:getChildByName("txt_formation_card_name"):setTag(TAG_TXT_CARD_NAME)
    cell:getChildByName("txt_formation_card_name"):getChildByName("txt"):setTag(TAG_TXT_CARD_NAME)
    -- 卡牌等级
    cell:getChildByName("txt_lv_num"):setTag(TAG_TXT_LV_NUM)
    cell:getChildByName("txt_lv_num"):getChildByName("font"):setTag(TAG_TXT_LV_NUM)
    -- 卡牌ATK、DEF、HP
    cell:getChildByName("txt_atk_num"):setTag(TAG_TXT_ATK_NUM)
    cell:getChildByName("txt_atk_num"):getChildByName("font"):setTag(TAG_TXT_ATK_NUM)
    cell:getChildByName("txt_def_num"):setTag(TAG_TXT_DEF_NUM)
    cell:getChildByName("txt_def_num"):getChildByName("font"):setTag(TAG_TXT_DEF_NUM)
    cell:getChildByName("txt_hp_num"):setTag(TAG_TXT_HP_NUM)
    cell:getChildByName("txt_hp_num"):getChildByName("font"):setTag(TAG_TXT_HP_NUM)
    -- 换位按钮
    cell:getChildByName("btn_change_captain"):setTag(TAG_BTN_CHANGE)
    cell:getChildByName("btn_change_captain"):getChildByName("txt"):setTag(TAG_BTN_CHANGE)
    cell:getChildByName("btn_change_captain"):getChildByName("btn"):setTag(TAG_PIC_CHANGE)
    -- 横幅颜色
    cell:getChildByName("q_white9_panel"):setTag(TAG_ICON_WHITE)
    cell:getChildByName("q_green9_panel"):setTag(TAG_ICON_GREEN)
    cell:getChildByName("q_blue9_panel"):setTag(TAG_ICON_BLUE)
    cell:getChildByName("q_purple9_panel"):setTag(TAG_ICON_PURPLE)
    cell:getChildByName("q_orange9_panel"):setTag(TAG_ICON_ORANGE)
    cell:getChildByName("q_red9_panel"):setTag(TAG_ICON_RED)
    cell:getChildByName("q_yellow9_panel"):setTag(TAG_ICON_GOLD)

    local perfectTxt = cell:getChildByName("txt_perfect"):getChildByName("txt")
    perfectTxt:setColor(ccc3(255,0,0))
    perfectTxt:setAroundColor(ccc3(255, 255, 255))
    cell:getChildByName("txt_perfect"):setTag(TAG_TXT_PERFECT)
    cell:getChildByName("txt_perfect"):getChildByName("txt"):setTag(TAG_TXT_PERFECT)
    
    -- 卡牌星级
    cell:getChildByName("icon_star_1"):setVisible(false)
    cell:getChildByName("icon_star_2"):setVisible(false)
    if (not firstStarPosX) and (not firstStarPosY) then 
      firstStarPosX, firstStarPosY = cell:getChildByName("icon_star_1").refCocosObj:getPosition()
    end
    if not starGapX then
      local posX, posY = cell:getChildByName("icon_star_2").refCocosObj:getPosition()
      starGapX = firstStarPosX - posX
    end
    for i = 1, MAX_RARE_NUM do 
      local star = Sprite:create(UI_RES_PATH.."/formation_new/formation_icon_star_sb.png")
      star:setAnchorPoint(ccp(0, 1))
      star:setPosition(ccp(firstStarPosX - starGapX * (i - 1), firstStarPosY))
      star.refCocosObj:setTag(TAG_FIRST_STAR - 1 + i)
      cell:addChild(star)
    end
  end
  
  -- 玩家的卡牌数据
  local cardsData = DataManager.getCardsData() 
  
  -- 设置数据
  function CardCellRenderer:setData(rawCocosObj, index)
    local cell = self:getChildByTag(rawCocosObj, TAG_CELL)
    
    -- 根据Tag设置文本
    local function setTextByTag(tag, str)
      local txt = cell:getChildByTag(tag):getChildByTag(tag)
      ViewControlUtil.setLableText(txt, str)
    end
    
    -- 根据Tag设置是否可见
    local function setNodeVisibleByTag(tag, visible)
      cell:getChildByTag(tag):setVisible(visible)
    end
    
    -- 获取卡牌信息
    local cardInfo = CommonManager.getSubTableByKey(cardsData, {name = "cardId", value = QueueData[index + 1]})
    local cardStatus = CommonManager:getBackpackCardPropertiesWithSharkCard(cardInfo)
    local cardMeta = MetaManager.card_meta[cardInfo.metaId]
    
    -- 主将标示
    if index == 0 then
      setNodeVisibleByTag(TAG_ICON_CAPTAIN, true)
    else
      setNodeVisibleByTag(TAG_ICON_CAPTAIN, false)
    end
    
    -- 卡牌图片
    setNodeVisibleByTag( TAG_TXT_PERFECT , false)
    setTextByTag(TAG_TXT_PERFECT, "")

    local perfectType = 0
    if CommonManager:checkIsCardPerfect(cardInfo) then
      if cardMeta.evolutionLevel == cardMeta.maxEvolvedLevel then
        perfectType = CardPerfectEnum.goldRight
        setTextByTag(TAG_TXT_PERFECT, getTextByKey("option_perfect"))
        setNodeVisibleByTag( TAG_TXT_PERFECT , true)
      else
        perfectType = CardPerfectEnum.silverRight
        setNodeVisibleByTag( TAG_TXT_PERFECT , false)
        setTextByTag(TAG_TXT_PERFECT, "")
      end
    end
    local picPosX, picPosY = cell:getChildByTag(TAG_PIC):getPosition()
    local picZOrder = cell:getChildByTag(TAG_PIC):getZOrder()
    local headCard = getBackpackHeadIconCanonCardByMetaId(CommonManager:changeAvatarByCardInfo( cardInfo ) , nil , perfectType)
    headCard:setPosition(ccp(picPosX, picPosY))
    cell:addChild(headCard.refCocosObj, picZOrder)
    headCard:dispose()
    
    -- 卡牌星级、横幅颜色
    for i = 1, MAX_RARE_NUM do
      setNodeVisibleByTag(TAG_FIRST_STAR - 1 + i, i <= cardMeta.rare)
      setNodeVisibleByTag(TAG_ICON_WHITE - 1 + i, i == cardMeta.rare)
    end
    
    -- 卡牌文字和数值
    setTextByTag(TAG_TXT_CARD_NAME, getTextByKey(cardMeta.name))
    setTextByTag(TAG_TXT_LV_NUM, "" .. cardInfo.level .. "/" .. MetaManager.card_evolve[cardMeta.evolutionLevel].maxCardLevel)
    setTextByTag(TAG_TXT_ATK_NUM, "" .. math.floor(cardStatus.att))
    setTextByTag(TAG_TXT_DEF_NUM, "" .. math.floor(cardStatus.def))
    setTextByTag(TAG_TXT_HP_NUM, "" .. math.floor(cardStatus.hp))
    
    -- 换位按钮
    setTextByTag(TAG_BTN_CHANGE, getTextByKey("queue_transpositionBtn"))
    if UiStatus == ADJUST_STATUS.SELECTED and index ~= SelectedCellIndex then
      setNodeVisibleByTag(TAG_BTN_CHANGE, true)
    else
      setNodeVisibleByTag(TAG_BTN_CHANGE, false)
    end
    
    -- 高亮显示
    if UiStatus == ADJUST_STATUS.SELECTED and index == SelectedCellIndex then
      setNodeVisibleByTag(TAG_EARTH_PANEL, false)
    else
      setNodeVisibleByTag(TAG_EARTH_PANEL, true)
    end
  end
  
  -- 点击事件
  local function onListItemTouch(evt)
    local curCellIndex = evt.data
    
    -- 刷新到未选定状态
    local function refreshToNotSelected() 
      UiStatus = ADJUST_STATUS.NOT_SELECTED
      ViewControlUtil.refreshTableView(self.tableView, true)
      SelectedCellIndex = nil
    end
    
    if UiStatus == ADJUST_STATUS.NOT_SELECTED then -- 未选定状态
      UiStatus = ADJUST_STATUS.SELECTED
      SelectedCellIndex = curCellIndex
      ViewControlUtil.refreshTableView(self.tableView, true)
      
    elseif UiStatus == ADJUST_STATUS.SELECTED then -- 选定状态
      if curCellIndex == SelectedCellIndex then -- 撤销选定
        refreshToNotSelected()
      else
        local curCell = self.tableView:cellAtIndex(curCellIndex):getChildByTag(TAG_CELL)
        local curCellPos = curCell:convertToNodeSpace(evt.globalPosition)
        local btnChange = curCell:getChildByTag(TAG_BTN_CHANGE)
        local picChange = btnChange:getChildByTag(TAG_PIC_CHANGE)
        
        if ViewControlUtil.isInAreaPic(curCellPos, btnChange, picChange) then -- 点击换位按钮
          QueueData[curCellIndex + 1], QueueData[SelectedCellIndex + 1] = QueueData[SelectedCellIndex + 1], QueueData[curCellIndex + 1]
          
          -- 处理队列信息
          local mainCardId = QueueData[1]
          local additionalCardIds = {}
          local additionalCardIdStr = ""
          for idx, cardId in pairs(QueueData) do
            if idx ~= 1 then
              table.insert(additionalCardIds, cardId)
              if additionalCardIdStr == "" then
                additionalCardIdStr = "" .. cardId
              else
                additionalCardIdStr = additionalCardIdStr .. "," .. cardId
              end
            end
          end
          
          -- 队列调整成功
          local function onAdjustTeamSucc(data)
            -- 存储数据
            local gameData = DataManager.getGameInitData()
            gameData["sharkUser"]["mainCardId"] = mainCardId
            gameData["sharkUser"]["additionalCardIds"] = additionalCardIdStr

            --当前阵容（换位）
            local BattleArrayId = gameData.sharkUserExtendMore.battleArrayId
            if GameData.sharkUser.level >= (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) then 
              gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue[curCellIndex + 1], gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue[SelectedCellIndex + 1] = 
              gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue[SelectedCellIndex + 1], gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue[curCellIndex + 1]
            end
            --end by l1ghtsaber

            DataManager.setGameInitData(gameData)            

            -- 刷新TableView
            refreshToNotSelected()
            -- 黑色横条
            SuspensionLabel:showContent(self, getTextByKey("queue_transpositionTip"))
          end
          
          -- 队列调整失败
          local function onAdjustTeamFail(err)
            -- 重置队列信息
            QueueData[curCellIndex + 1], QueueData[SelectedCellIndex + 1] = QueueData[SelectedCellIndex + 1], QueueData[curCellIndex + 1]
            -- 刷新TableView
            refreshToNotSelected()
            if err.data == 710203 then
                local aContent = Localization:getInstance():getText("formation_leadershipInsufficient")
                SuspensionLabel:showContent(self, aContent)
            end
          end
          
          local params = {mainCardId = mainCardId, additionalCardIds = additionalCardIds}
          local request = AdjustTeamRequest.new(params, rpc.SendingPriority.kHigh)
          request:addEventListener(RequestNotifyEnum.AdjustTeamSucceed, onAdjustTeamSucc)
          request:addEventListener(RequestNotifyEnum.AdjustTeamFailed, onAdjustTeamFail)
          request:start()
        end
      end
    end
  end
  
  local renderer = CardCellRenderer.new(CELL_WIDTH, CELL_HEIGHT)
  local tableView = TableView:create(
    renderer, 
    LIST_WIDTH, 
    LIST_HEIGHT, 
    TAG_CELL,
    TAG_BTN_CHANGE,
    CCScale9Sprite:create("pic/scroll.png"), 
    CCScale9Sprite:create("pic/scroll.png")
  )
  tableView:setPosition(ccp(LIST_POS_X, LIST_POS_Y))
  tableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  return tableView
end

----------------------------------------
-- 场景初始化
----------------------------------------
function AdjustTeamScene:onInit()
  BaseUIScene.initBackGround(self)
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/formation_new.json")
  self.mainUI = builder:build("formation_change_list")
  self.mainUI:getChildByName("formation_card"):setVisible(false)
  self:addChild(self.mainUI)
  self.tableView = self:createTableView()
  self:addChild(self.tableView)
  
  BaseUIScene.onInit(self)
end

----------------------------------------
-- 进入场景动画,被父类onInit()方法调用
----------------------------------------
function AdjustTeamScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

----------------------------------------
----------------------------------------
function AdjustTeamScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

----------------------------------------
----------------------------------------
function AdjustTeamScene:startEnterAnimation()
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  BaseUIScene.startEnterAnimation(self)
  ViewControlUtil.showTableViewAction(self.tableView, VISIBLE_SIZE, enterActionFinished)
end

----------------------------------------
----------------------------------------
function AdjustTeamScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

----------------------------------------
-- 场景切换时，被父类的replaceScene调用
----------------------------------------
function AdjustTeamScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

----------------------------------------
----------------------------------------
function AdjustTeamScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

----------------------------------------
----------------------------------------
function AdjustTeamScene:startExitAnimation()
  local function exitActionFinished()
    self:nodeAnimationFinished()
  end
  BaseUIScene.startExitAnimation(self)
  self.mainUI:getChildByName("bg_formation_red"):setVisible(false)
  ViewControlUtil.disappearTableViewAction(self.tableView, VISIBLE_SIZE, exitActionFinished) 
end

----------------------------------------
----------------------------------------
function AdjustTeamScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

----------------------------------------
-- 析构函数
----------------------------------------
function AdjustTeamScene:dispose()
  AdjustTeamScene.super.dispose(self)
end
