--------------------------------------------------------------------------------
-- MyFriendsPanel.lua - 我的好友界面
-- author: xiaojie.bai
-- date: 2013-08-08 17:53
--------------------------------------------------------------------------------

require "canon.data.MetaManager"
require "canon.models.FriendManager"
require "canon.models.RewardManager"

require "canon.request.CommErrorCodes"
require "canon.request.SendFreeGiftRequest"
require "canon.request.SendAllFreeGiftRequest"
require "canon.request.AcceptAllFreeGiftRequest"

require "canon.customUI.CanonCard"
require "canon.canonUtils"
require "canon.panel.CanonMessageBox"
require "canon.panel.UserDetailPanel"

require "canon.utils.ViewControlUtil"

MyFriendsPanel = class(Layer)

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local lstSharkFriend = {}
local receivedEnergy = nil

function MyFriendsPanel:ctor()
  self.container = nil
end

function MyFriendsPanel:create(container, params)
  self.container = container
  lstSharkFriend = params.lstFriend or lstSharkFriend
  receivedEnergy = params.receivedEnergy
  
  self.friendSystemConfig = params.friendSystemConfig
  self.maxFreeGiftPerDay = self.friendSystemConfig.maxFreeGiftPerDay
  
  local panel = MyFriendsPanel.new()
  panel:initLayer()
  
  return panel
end

function MyFriendsPanel:getFriendsNum()
  return #lstSharkFriend
end

function MyFriendsPanel:refreshRecivedEnergy() 
  local txtRemindNumSb = self.panelUI:getChildByName("txt_remind_num")
  local tipsFriendSb = self.panelUI:getChildByName("tips_friend")

  if(receivedEnergy and receivedEnergy > 0) then
    txtRemindNumSb:setVisible(true)
    tipsFriendSb:setVisible(true)
    txtRemindNumSb:getChildByName("font"):setString(receivedEnergy)
  else 
    local btnClaimAllSb = self.panelUI:getChildByName("btn_friend_ClaimAllBtn")
    btnClaimAllSb:getChildByName("btn"):setVisible(false)
    btnClaimAllSb:getChildByName("disable"):setVisible(true)
    self.btnClaimGifts:setEnable(false)

    txtRemindNumSb:setVisible(false)
    tipsFriendSb:setVisible(false)
  end
end

function MyFriendsPanel:refreshSendAllBtn()
  local canSend = false
  if(lstSharkFriend and #lstSharkFriend > 0) then
    for i, friendData in ipairs(lstSharkFriend) do
      if not friendData.giftSent then
        canSend = true
        break
      end
    end
  end
  
  local btnSendAllSb = self.panelUI:getChildByName("btn_friend_sendALL")
  if not canSend then
    btnSendAllSb:getChildByName("btn"):setVisible(false)
    btnSendAllSb:getChildByName("disable"):setVisible(true)

    self.btnSendGifts:setEnable(false)
  else 
    btnSendAllSb:getChildByName("btn"):setVisible(true)
    btnSendAllSb:getChildByName("disable"):setVisible(false)
    
    self.btnSendGifts:setEnable(true)
  end
end

function MyFriendsPanel:setReceivedEnergy(energy)
  self.container:setReceivedEnergy(energy)
  receivedEnergy = energy
end

----------------------------------------
-- 好友列表渲染
----------------------------------------
function MyFriendsPanel:createFriendsTableView()
  local FriendTableViewRenderer = class(TableViewRenderer)
  local builder = LayoutBuilder:createWithContentsOfFile(FriendManager.DICT.RESOURCE_FILE)
  local strAlreadyGifted = Localization:getInstance():getText("friend_AlreadyGifted");
  local strGift = Localization:getInstance():getText("friend_GiftBtn")
  
  local strChallenged = getTextByKey("friend_alreadyChallenged")
  
  local fightFriendUids = DailyDataManager.getFightFriendUids()
  --------------------
  -- 初始化table数据
  --------------------
  function FriendTableViewRenderer:ctor(width, height)
    self.list = lstSharkFriend
  end

  local cellTag = -1001
  local buttonTag = {-12}
  --------------------
  -- table每个元素的模版构建
  --------------------
  function FriendTableViewRenderer:buildCell(container)
    local aCell = builder:build("friend_list_entry")
    container:addChild(aCell)
    
    aCell:setTag(-1001)
    
    local txtFriendName = aCell:getChildByName("friend_txt_friend_playerName");
    txtFriendName:setTag(-10)
    local txtFriendNameValue = txtFriendName:getChildByName("font")
    txtFriendNameValue:setTag(-10)
    
    local txtLv = aCell:getChildByName("friend_txt_lv_num")
    txtLv:setTag(-11)
    local txtLvValue = txtLv:getChildByName("font")
    txtLvValue:setTag(-10)
    
    local btnGift = aCell:getChildByName("friend_btn_friend_GiftBtn")
    btnGift:setTag(-12)
    local picBtnGift = btnGift:getChildByName("btn")
    picBtnGift:setTag(-10)
    local txtBtnGift = btnGift:getChildByName("txt_friend_GiftBtn")
    txtBtnGift:setTag(-11)
    local picBtnGiftDisable = btnGift:getChildByName("disable")
    picBtnGiftDisable:setTag(-12)
    
    local cardFrameM = aCell:getChildByName("friend_frame_card")
    cardFrameM:setTag(-14)
    
    local txtChallengeStatus = aCell:getChildByName("txt_friend_vs_ed")
    txtChallengeStatus:setTag(-15)
    local txtChallengeStatusValue = txtChallengeStatus:getChildByName("txt")
    txtChallengeStatusValue:setTag(-10)
    
    local txtFriendunion = aCell:getChildByName("txt_guild_namae");
    txtFriendunion:setTag(-16)
    local txtFriendUnionValue = txtFriendunion:getChildByName("txt")
    txtFriendUnionValue:setTag(-10)
    
    local txtFriendLeave = aCell:getChildByName("txt_leave");
    txtFriendLeave:setTag(-17)
    local txtFriendLeaveValue = txtFriendLeave:getChildByName("txt")
    txtFriendLeaveValue:setTag(-10)
  end

  --------------------
  -- 设置table每个元素的数据
  --------------------
  function FriendTableViewRenderer:setData(rawCocosObj, index)
    fightFriendUids = DailyDataManager.getFightFriendUids() --一键切磋刷新时重新导入已切磋武将信息
    if not lstSharkFriend or #lstSharkFriend == 0 then
      return nil
    end
    
    local aData = lstSharkFriend[index + 1];
    local aCell = self:getChildByTag(rawCocosObj, -1001)
    
    --清除图片信息
    local smallCanonCard = aCell:getChildByTag(-30)
    if smallCanonCard then
      smallCanonCard:removeFromParentAndCleanup(true)
    end
    
    local txtFriendName = aCell:getChildByTag(-10)
    local txtFriendNameValue = txtFriendName:getChildByTag(-10)
    ViewControlUtil.setLableText(txtFriendNameValue, aData.nickName)
    
    local txtLv = aCell:getChildByTag(-11)
    local txtLvValue = txtLv:getChildByTag(-10)
    ViewControlUtil.setLableText(txtLvValue, aData.level)
    
    local txtGiftBtnValue = (aData.giftSent and strAlreadyGifted) or strGift
    local btnGift = aCell:getChildByTag(-12)
    local picBtnGiftBtn = btnGift:getChildByTag(-10)
    picBtnGiftBtn:setVisible(not aData.giftSent)
    btnGift.ignoreTouch = aData.giftSent
    if(btnGift.setTouchEnabled) then
      btnGift:setTouchEnabled(not aData.giftSent)
    end
    local picBtnGiftDisable = btnGift:getChildByTag(-12)
    picBtnGiftDisable:setVisible(aData.giftSent)
    local btnGiftValue = btnGift:getChildByTag(-11)
    ViewControlUtil.setLableText(btnGiftValue, txtGiftBtnValue)

    local cardFrameSb = CocosObject.new(aCell:getChildByTag(-14))
    local smallCanonCard = getHeadIconCanonCardByMetaId(aData.mainCardMetaId)
    ViewControlUtil.adjustItemByFrame(smallCanonCard, cardFrameSb)
    aCell:addChild(smallCanonCard.refCocosObj, 1001)
    smallCanonCard:setTag(-30)
    smallCanonCard:dispose()
    cardFrameSb:setVisible(false)
    
    local challenged = FriendManager.containUid(fightFriendUids, aData.friendUid)
    local txtChallengeStatus = aCell:getChildByTag(-15)
    local txtChallenge = txtChallengeStatus:getChildByTag(-10)
    if challenged then
      ViewControlUtil.setLableText(txtChallenge, strChallenged)
    else
      ViewControlUtil.setLableText(txtChallenge, "")
    end

    local txtFriendunion = aCell:getChildByTag(-16)
    local txtFriendUnionValue = txtFriendunion:getChildByTag(-10)
    if aData.unionName then
      txtFriendunion:setVisible(true)
      ViewControlUtil.setLableText(txtFriendUnionValue, Localization:getInstance():getText("union_name_txt", {name = aData.unionName}))--otherUnionName
    else
      txtFriendunion:setVisible(false)
    end


    --显示离线时间
    local txtFriendLeave = aCell:getChildByTag(-17)
    local txtFriendLeaveValue = txtFriendLeave:getChildByTag(-10)
    local offLineSec = 0
    if not aData.online then
      --当前不在线才有偏差时间
      offLineSec = TimeUtil.getServerTimeSeconds() - aData.lastestOfflineSeconds
    end
    local hours = TimeUtil.getHoursBySec(offLineSec)
    if hours <= 0 then
      --不到1小时
      txtFriendLeave:setVisible(false)
    else
      --超过1小时
      txtFriendLeave:setVisible(true)
      local days = TimeUtil.getPasseddDaysToNow(aData.lastestOfflineSeconds)
      if days <= 0 then
        --不到1天
        setNodeText(txtFriendLeaveValue, Localization:getInstance():getText("union_player_login_remind3", {num = hours}))--{num}小时未登陆
      else
        --超过1天
        if days <= 7 then
          --不到7天
          setNodeText(txtFriendLeaveValue, Localization:getInstance():getText("union_player_login_remind2", {num = days}))--{num}天未登陆
        else
          --超过7天
          setNodeText(txtFriendLeaveValue, Localization:getInstance():getText("union_player_login_remind1"))--7天以上未登陆
        end
      end
    end
  end
  
  --------------------
  -- table元素被点击事件响应
  --------------------
  local function onListItemTouch(evt)
    local aIndex = evt.data + 1
    local aCell = self.table:cellAtIndex(aIndex - 1)
    local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
    local aData = lstSharkFriend[aIndex];
    
    local btnGift = aCell:getChildByTag(-1001):getChildByTag(-12)
    local picBtnGiftBtn = btnGift:getChildByTag(-10)
    local btnFriendDetail = aCell:getChildByTag(-1001):getChildByTag(-13)
    
    if ViewControlUtil.isInAreaPic(posInCell, btnGift, picBtnGiftBtn) then
      if(aData.giftSent) then 
        return nil
      end
      
      --------------------
      -- 设置赠送礼物按钮为已发送
      --------------------
      local function setGiftBtnSent()
        aData.giftSent = true
        picBtnGiftBtn:setVisible(not aData.giftSent)
        local picBtnGiftDisable = btnGift:getChildByTag(-12)
        picBtnGiftDisable:setVisible(aData.giftSent)

        local btnGiftValue = btnGift:getChildByTag(-11)
        ViewControlUtil.setLableText(btnGiftValue, strAlreadyGifted)
        
        self:refreshSendAllBtn()
      end
      
      local function onSendFreeGiftSucc(data)
        local gainedEnergy = data.data.gainedEnergy
        RewardManager:getReward({{itemType = ResourceEnum.ENERGY, amount = gainedEnergy}})
        setGiftBtnSent()
        
        local strSendFGSucc = nil
        if(gainedEnergy > 0) then
          strSendFGSucc = getTextByKey("friend_giftSentText", {num = gainedEnergy})
        else 
          strSendFGSucc = getTextByKey("friend_giftSentNoRewardText")
        end
        CanonMessageBox:Show(strSendFGSucc, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil, nil)
      end
      
      local function onSendFreeGiftFail(err)
        local errorCode = tonumber(err.data)
        
        if(CommErrorCodes.FRIEND_RELATIONSHIP_NOT_EXIST.code == errorCode) then --已不是好友，删除
          local function onDeleteFriend()
            table.remove(lstSharkFriend, aIndex)
            self.table:removeCellAtIndex(aIndex)
            self:refreshTableAndBtn(true)
          end
          CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_RELATIONSHIP_NOT_EXIST, nil, nil, onDeleteFriend)
        elseif(CommErrorCodes.FRIEND_FREEGIFT_SEND.code == errorCode) then -- 已发送，更新按钮状态
          CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_FREEGIFT_SEND, nil, nil, nil)
          setGiftBtnSent()
        elseif(CommErrorCodes.FRIEND_FREEGIFT_SENDNUM_FULL.code == errorCode) then -- 发送数量已满
          CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_FREEGIFT_SENDNUM_FULL, nil, nil, nil)
        else
          CanonMessageBox:showCommUnHandleErrorBox(errorCode)
        end
      end
      
      local params = {friendUid = aData.friendUid}
      local sendFreeGiftRequest = SendFreeGiftRequest.new(params, rpc.SendingPriority.kHigh)
      sendFreeGiftRequest:addEventListener(RequestNotifyEnum.SendFreeGiftSucceed, onSendFreeGiftSucc)
      sendFreeGiftRequest:addEventListener(RequestNotifyEnum.SendFreeGiftFailed, onSendFreeGiftFail)
      
      sendFreeGiftRequest:start()
    else -- detail
      local TableViewContentHeight = self.aTableView:getContentOffset().y
      local userDetailPanel = UserDetailPanel:create( self.container, {friendUid = aData.friendUid , FriendTableViewContentHeight = TableViewContentHeight , lstSharkFriend = lstSharkFriend , table = self.table} ) 
      PopoutManager:sharedManager():popout(userDetailPanel, kPopoutDir.kScale, true, false, self.container)
    end
  end
  
  local renderer = FriendTableViewRenderer.new(FriendManager.DICT.ITEM_WIDTH, FriendManager.DICT.ITEM_HEIGHT)
  local aTableView = TableView:create(renderer, 
      FriendManager.DICT.TABLE_WIDTH, 
      FriendManager.DICT.TABLE_HEIGHT_FRIENDS, 
      cellTag,
      buttonTag,
      CCScale9Sprite:create("pic/scroll.png"), 
      CCScale9Sprite:create("pic/scroll.png"),
      lstSharkFriend
    )
  
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  aTableView:setPosition(ccp(FriendManager.DICT.TABLE_POSX, FriendManager.DICT.TABLE_POSY))
  self.aTableView = aTableView
  
  return aTableView
end

function MyFriendsPanel:refreshTableAndBtn(keepOffset)
  ViewControlUtil.refreshTableView(self.table, keepOffset)
  
  --
  local userInfo = DataManager.getCurrUser()  
  userInfo.friendNum = g_homeInfo and g_homeInfo.friendNum or 0
  userInfo.maxFriendNum = MetaManager.user_level[userInfo.level].friendMax
  --
  self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("friend_FriendAmount"))
  self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(userInfo.friendNum .. "/" .. userInfo.maxFriendNum)
  
  self:refreshSendAllBtn()
  
  if(lstSharkFriend and #lstSharkFriend > 0) then
    self.table:setVisible(true)
    self.hintTableEmpty:setVisible(false)
  else
    self.table:setVisible(false)
    self.hintTableEmpty:setVisible(true)
  end
end

--------------------
-- 增加新好友，等待审核界面调用
--------------------
function MyFriendsPanel:addTableData(aData)
  g_homeInfo.friendNum = g_homeInfo.friendNum + 1
  table.insert(lstSharkFriend, aData)
  self:refreshTableAndBtn(true)
end

function MyFriendsPanel:deleteFriend(friendUid)
  local idx = 0
  for i, friend in ipairs(lstSharkFriend) do
    if(friend.friendUid == friendUid) then
      idx = i
      break
    end
  end
  
  g_homeInfo.friendNum = g_homeInfo.friendNum - 1
  if g_homeInfo.friendNum < 0 then
	g_homeInfo.friendNum = 0
  end
  
  if(idx > 0) then
    table.remove(lstSharkFriend, idx)
    self:refreshTableAndBtn(true)
  end  
  
end

function MyFriendsPanel:initLayer()
  MyFriendsPanel.super.initLayer(self)
  
  local builder = LayoutBuilder:createWithContentsOfFile(FriendManager.DICT.RESOURCE_FILE)
  self.panelUI = builder:build("friend_page_1")
  --
  local userInfo = DataManager.getCurrUser()  
  userInfo.friendNum = g_homeInfo and g_homeInfo.friendNum or 0
  userInfo.maxFriendNum = MetaManager.user_level[userInfo.level].friendMax
  --
  self.panelUI:getChildByName("tips_big"):setVisible(false)
  self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("friend_FriendAmount"))
  self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(userInfo.friendNum .. "/" .. userInfo.maxFriendNum)
  
  local strGiftInfo = Localization:getInstance():getText("friend_FriendListText", 
    {num1 = self.friendSystemConfig.energyGift, num2 = self.friendSystemConfig.energyReward})
  
  local strBtnClaimGifts = Localization:getInstance():getText("friend_ClaimAllBtn")
  local strBtnSendGifts = Localization:getInstance():getText("friend_GiftAllBtn")
  local strBtnFindMoreFriend = Localization:getInstance():getText("friend_FindMoreBtn")
  
  local txtGiftIntro = self.panelUI:getChildByName("txt_friend_FriendListText"):getChildByName("txt_friend_FriendListText")
  txtGiftIntro:setDimensions(CCSizeMake(txtGiftIntro:getDimensions().width, 0))
  txtGiftIntro:setString(strGiftInfo)
  
  -- 全部领取体力
  local txtBtnClaimGifts = self.panelUI:getChildByName("btn_friend_ClaimAllBtn"):getChildByName("txt_friend_ClaimAllBtn")
  txtBtnClaimGifts:setString(strBtnClaimGifts)
  
  local function onClaimGifts()
    local function acceptAllFreeGiftCallback(data) 
      local gainedEnergy = data.data.gainedEnergy
      RewardManager:getReward({{itemType = ResourceEnum.ENERGY, amount = gainedEnergy}})
      
      local text = nil
      if(gainedEnergy > 0) then
        text = Localization:getInstance():getText("friend_claimStaminaText", {num = gainedEnergy})
      else
        text = Localization:getInstance():getText("friend_claimStaminaFullText")
      end
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil, nil)
      
      self:setReceivedEnergy(receivedEnergy - gainedEnergy)
      self:refreshRecivedEnergy()
    end
    local function acceptAllFreeGiftFail(error)
      local errorCode = tonumber(error.data)
    
      if (errorCode == CommErrorCodes.FRIEND_FREEGIFT_ENERGY_POOL_EMPTY.code) then
        CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_FREEGIFT_ENERGY_POOL_EMPTY, nil, nil, nil)
      elseif(errorCode == CommErrorCodes.FRIEND_FREEGIFT_ENERGY_FULL.code) then
        CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_FREEGIFT_ENERGY_FULL, nil, nil, nil)
      else
        CanonMessageBox:showCommUnHandleErrorBox(errorCode)
      end
    end
    
    local acceptAllFreeGiftRequest = AcceptAllFreeGiftRequest.new(nil, rpc.SendingPriority.kHigh)
    acceptAllFreeGiftRequest:addEventListener(RequestNotifyEnum.AcceptAllFreeGiftSucceed, acceptAllFreeGiftCallback)
    acceptAllFreeGiftRequest:addEventListener(RequestNotifyEnum.AcceptAllFreeGiftFailed, acceptAllFreeGiftFail)
    
    acceptAllFreeGiftRequest:start()
  end
  self.btnClaimGifts = Button:create(self.panelUI:getChildByName("btn_friend_ClaimAllBtn"));
  self.btnClaimGifts:addEventListener(Events.kStart, onClaimGifts, self)
  -- 显示接受到的礼物数
  self:refreshRecivedEnergy()

  -- 全部赠送体力
  local txtBtnSendGifts = self.panelUI:getChildByName("btn_friend_sendALL"):getChildByName("txt_friend_GiftAllBtn"):getChildByName("txt_friend_GiftAllBtn")
  txtBtnSendGifts:setString(strBtnSendGifts)
  
  local function onSendGifts()
    local sentNum = 0
    for i, friend in ipairs(lstSharkFriend) do
      if(friend.giftSent) then
        sentNum = sentNum + 1
      end
    end
    if(sentNum >= self.maxFreeGiftPerDay) then
      local strWarnSentUpper = Localization:getInstance():getText("friend_cannotSendGiftText")
      CanonMessageBox:Show(strWarnSentUpper, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil, nil)
      return nil
    end
    
    local function sendAllFreeGiftCallback(data)
      local succUids = data.data.friendUids
      local gainedEnergy = data.data.gainedEnergy
      RewardManager:getReward({{itemType = ResourceEnum.ENERGY, amount = gainedEnergy}})
      
      if(succUids and #succUids > 0) then
        for i, friendId in ipairs(succUids) do
          for j, user in ipairs(lstSharkFriend) do
            if(friendId == user.friendUid) then
              user.giftSent = true
            end
          end
        end
        self:refreshTableAndBtn()
        
        local strWarnSentUpper = nil
        if(gainedEnergy > 0) then
          strWarnSentUpper = Localization:getInstance():getText("friend_giftSentToAllText", {num1 = #succUids, num2 = gainedEnergy})
        else 
          strWarnSentUpper = Localization:getInstance():getText("friend_giftSentToAllNoRewardText", {num = #succUids})
        end
        CanonMessageBox:Show(strWarnSentUpper, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil, nil)
      end
    end
    local function sendAllFreeGiftFail(error)
      local errorCode = tonumber(error.data)
      if(CommErrorCodes.FRIEND_FREEGIFT_SENDNUM_FULL.code == errorCode) then
        CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_FREEGIFT_SENDNUM_FULL, nil, nil, nil)
      else 
        CanonMessageBox:showCommUnHandleErrorBox(errorCode)
      end
    end
    
    local notSentUids = {}
    for i, friend in ipairs(lstSharkFriend) do
      if(not friend.giftSent) then
        table.insert(notSentUids, friend.friendUid)
      end
    end

    if(notSentUids and #notSentUids > 0) then
      local params = {friendUids = notSentUids}
      local sendAllFreeGiftRequest = SendAllFreeGiftRequest.new(params, rpc.SendingPriority.kHigh)
      sendAllFreeGiftRequest:addEventListener(RequestNotifyEnum.SendAllFreeGiftSucceed, sendAllFreeGiftCallback)
      sendAllFreeGiftRequest:addEventListener(RequestNotifyEnum.SendAllFreeGiftFailed, sendAllFreeGiftFail)
      
      sendAllFreeGiftRequest:start()
    end
  end
  self.btnSendGifts = Button:create(self.panelUI:getChildByName("btn_friend_sendALL"))
  self.btnSendGifts:addEventListener(Events.kStart, onSendGifts, self)
  self:refreshSendAllBtn()

  self:addChild(self.panelUI)

  -- 渲染 TableView
  self.table = self:createFriendsTableView()
  self.table:reloadData()
  self:addChild(self.table)
  if (self.container.argv.params[1]) then
    local offset = self.table:getContentOffset()
    offset.y = self.container.argv.params[1]
    self.table:setContentOffset(offset)
  end
  
  self.hintTableEmpty = self.panelUI:getChildByName("txt_friend_FriendListText_empty")
  local txtHintTableEmpty = self.hintTableEmpty:getChildByName("txt")
  txtHintTableEmpty:setString(getTextByKey("friend_FriendListText_empty"))
  if(self.table and self.table.tableViewRenderer:numberOfCells() > 0) then
    self.hintTableEmpty:setVisible(false)
  else
    self.table:setVisible(false)
  end
end

function MyFriendsPanel:enterPanelAction()
  ViewControlUtil.showTableViewAction(self.table, visibleSize)
  ViewControlUtil.animateFadeIn(self.panelUI)
end

function MyFriendsPanel:exitPanelAction(callback)
  ViewControlUtil.disappearTableViewAction(self.table, visibleSize, callback)
  ViewControlUtil.animateFadeOut(self.panelUI)
end