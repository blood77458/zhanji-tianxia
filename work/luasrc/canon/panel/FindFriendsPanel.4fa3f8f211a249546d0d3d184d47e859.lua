--------------------------------------------------------------------------------
-- FindFriendsPanel.lua - 更多好友界面
-- author: xiaojie.bai
-- date: 2013-09-18 17:53
--------------------------------------------------------------------------------

require "canon.data.MetaManager"
require "canon.data.DataManager"
require "canon.models.FriendManager"

require "canon.request.CommErrorCodes"
require "canon.request.GetRecommendedFriendsRequest"
require "canon.request.SendAllInvitationsRequest"
require "canon.request.SendInvitationRequest"
require "canon.request.SearchUserByNicknameRequest"

require "canon.customUI.CanonCard"
require "canon.customUI.SuspensionLabel"

require "canon.canonUtils"
require "canon.panel.CanonMessageBox"
require "canon.panel.UserDetailPanel"

require "canon.utils.StringUtil"
require "canon.utils.ViewControlUtil"

FindFriendsPanel = class(Layer)

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local lstSharkFriend = {}

function FindFriendsPanel:ctor()
  self.container = nil
  
  self.sentUids = {}
end

function FindFriendsPanel:create(container, params)
  self.container = container
  
  if(params) then
    self.params = params
  else 
    self.params = {}
  end
  
  self.lstInviteSent = self.params.lstInviteSent or {}
  self.lstFriend = self.params.lstFriend or {}
  
  self.friendSystemConfig = self.params.friendSystemConfig
  self.maxFreeGiftPerDay = self.friendSystemConfig.maxFreeGiftPerDay
  
  self.currUser = DataManager.getCurrUser()
  self.maxFriendNum = MetaManager.user_level[self.currUser.level].friendMax
  
  local panel = FindFriendsPanel.new()
  panel:initLayer()
  
  return panel
end

----------------------------------------
-- 判断是否有未发送邀请的玩家
----------------------------------------
function FindFriendsPanel:canSent()
  local canSent = false
  if(not lstSharkFriend or #lstSharkFriend == 0) then
    return canSent
  end
  for i, friend in ipairs(lstSharkFriend) do
    if(not friend.invitationSent) then
      canSent = true
      break
    end
  end
  return canSent
end

----------------------------------------
-- 设置按钮状态
----------------------------------------
function FindFriendsPanel:setSendAllBtnEnable(enable)
  local btnSendAllSb = self.panelUI:getChildByName("friend_btn_friend_SendAllBtn")
  btnSendAllSb:getChildByName("btn"):setVisible(enable)
  btnSendAllSb:getChildByName("disable"):setVisible(not enable)
  self.btnSendAll:setEnable(enable)
end

----------------------------------------
-- 刷新全部发送邀请按钮状态
----------------------------------------
function FindFriendsPanel:refreshSendAllBtnStatus()
  local canSent = self:canSent()
  self:setSendAllBtnEnable(canSent)
end

----------------------------------------
-- 刷新表格视图区
----------------------------------------
function FindFriendsPanel:refreshTableView()
  self:removeChild(self.table)
  self.table = self:createInvitationTableView(lstSharkFriend)
  self:addChild(self.table)
  self.table:reloadData()
end

----------------------------------------
-- 判断可否发送邀请并弹框
----------------------------------------
function FindFriendsPanel:canSendInvite()
  if(#self.lstFriend >= self.maxFriendNum) then 
    local strWarnFriendsNumMax = Localization:getInstance():getText("friend_sendRequestFailed_friendFull")
    CanonMessageBox:Show(strWarnFriendsNumMax, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil, nil)
    return false
  elseif(#self.lstInviteSent >= self.friendSystemConfig.maxFriendInvitationSent) then
    local strWarnRequestFull = Localization:getInstance():getText("friend_sendRequestFailed_requestFull")
    CanonMessageBox:Show(strWarnRequestFull, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil, nil)
    return false
  end
  
  return true
end
  
----------------------------------------
-- 好友列表渲染
----------------------------------------
function FindFriendsPanel:createInvitationTableView(lstSharkFriend)
  self.sentUids = {}
  local InvitationTableViewRenderer = class(TableViewRenderer)

  local strAlreadyFriend = Localization:getInstance():getText("friend_AlreadyFriend")
  local strAlreadySent = Localization:getInstance():getText("friend_AlreadySent")
  local strBtnSend = Localization:getInstance():getText("friend_SendBtn")
  
  --------------------
  -- 初始化table数据
  --------------------
  function InvitationTableViewRenderer:ctor(width, height)
    self.list = lstSharkFriend
  end
  
  local cellTag = -1001
  local buttonTag = {-12}
  --------------------
  -- table每个元素的模版构建
  --------------------
  function InvitationTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile(FriendManager.DICT.RESOURCE_FILE)
    local aCell = builder:build("friend_send_entry")
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
    
    local btnSendInvite = aCell:getChildByName("friend_btn_friend_sendInvite")
    btnSendInvite:setTag(-12)
    local picBtnSendInvite = btnSendInvite:getChildByName("btn")
    picBtnSendInvite:setTag(-10)
    local picBtnSendInviteDisable = btnSendInvite:getChildByName("disable")
    picBtnSendInviteDisable:setTag(-11)
    local txtBtnSendInvite = btnSendInvite:getChildByName("txt_friend_sendInvite")
    txtBtnSendInvite:setTag(-12)
    
    local cardFrameM = aCell:getChildByName("friend_frame_card")
    cardFrameM:setTag(-14)
    
    local txtFriendunion = aCell:getChildByName("txt_guild_namae");
    txtFriendunion:setTag(-15)
    local txtFriendUnionValue = txtFriendunion:getChildByName("txt")
    txtFriendUnionValue:setTag(-10)
  end
    
  --------------------
  -- 设置table每个元素的数据
  --------------------
  function InvitationTableViewRenderer:setData(rawCocosObj, index)
    if not self.list or #self.list == 0 then
      return nil
    end
    
    local aData = self.list[index + 1];
    local aCell = self:getChildByTag(rawCocosObj, -1001)
    
    --清除图片信息
    local smallCanonCard = aCell:getChildByTag(-30)
    if smallCanonCard then
      smallCanonCard:removeFromParentAndCleanup(true)
    end
    
    local txtFriendName = aCell:getChildByTag(-10)
    local txtFriendNameValue = txtFriendName:getChildByTag(-10)
    ViewControlUtil.setLableText(txtFriendNameValue, aData.nickName)

    local btnSendInvite = aCell:getChildByTag(-12)

    local picBtnSendInvite = btnSendInvite:getChildByTag(-10)
    local picBtnSendInviteDisable = btnSendInvite:getChildByTag(-11)
    local txtBtnSendInvite = btnSendInvite:getChildByTag(-12)
    
    local btnEnable = not aData.invitationSent and not aData.friend
    btnSendInvite.ignoreTouch = not btnEnable
    if(btnSendInvite.setTouchEnabled) then
      btnSendInvite:setTouchEnabled(btnEnable)
    end
    picBtnSendInvite:setVisible(btnEnable)
    picBtnSendInviteDisable:setVisible(not btnEnable)
    local strBtn = (aData.friend and strAlreadyFriend) or (aData.invitationSent and strAlreadySent or strBtnSend)
    ViewControlUtil.setLableText(txtBtnSendInvite, strBtn)
    
    local txtLv = aCell:getChildByTag(-11)
    local txtLvValue = txtLv:getChildByTag(-10)
    ViewControlUtil.setLableText(txtLvValue, aData.level)

    local cardFrameSb = CocosObject.new(aCell:getChildByTag(-14))
    local smallCanonCard = getHeadIconCanonCardByMetaId(aData.mainCardMetaId)
    ViewControlUtil.adjustItemByFrame(smallCanonCard, cardFrameSb)
    aCell:addChild(smallCanonCard.refCocosObj, 1001)
    smallCanonCard:setTag(-30)
    smallCanonCard:dispose()

    local txtFriendunion = aCell:getChildByTag(-15)
    local txtFriendUnionValue = txtFriendunion:getChildByTag(-10)
    if aData.unionName then
      txtFriendunion:setVisible(true)
      ViewControlUtil.setLableText(txtFriendUnionValue, Localization:getInstance():getText("union_name_txt", {name = aData.unionName}))--otherUnionName
    else
      txtFriendunion:setVisible(false)
    end
    
    cardFrameSb:setVisible(false)
  end
  
  --------------------
  -- table元素被点击事件响应
  --------------------
  function onListItemTouch(evt)
    local aIndex = evt.data + 1
    local aCell = self.table:cellAtIndex(aIndex - 1)
    local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
    local aData = lstSharkFriend[aIndex];

    local btnSendInvite = aCell:getChildByTag(-1001):getChildByTag(-12)
    local picBtnSendInvite = btnSendInvite:getChildByTag(-10)
    
    local btnFriendDetail = aCell:getChildByTag(-1001):getChildByTag(-13)
    
    if ViewControlUtil.isInAreaPic(posInCell, btnSendInvite, picBtnSendInvite) then
      local function sendInvitationCallback(data)
        SuspensionLabel:showContent(self.container, getTextByKey("friend_sendRequestSuccess"))
        
        aData.invitationSent = true
        
        table.insert(self.sentUids, aData.friendUid)
        self.container.inviteSentPanel:addTableData(aData)
        
        local picBtnSendInviteDisable = btnSendInvite:getChildByTag(-11)
        local txtBtnSendInvite = btnSendInvite:getChildByTag(-12)
        
        btnSendInvite.ignoreTouch = aData.invitationSent
        if(btnSendInvite.setTouchEnabled) then
          btnSendInvite:setTouchEnabled(not aData.invitationSent)
        end
        picBtnSendInvite:setVisible(not aData.invitationSent)
        picBtnSendInviteDisable:setVisible(aData.invitationSent)
        ViewControlUtil.setLableText(txtBtnSendInvite, strAlreadySent)

        self:refreshSendAllBtnStatus()
      end
      
      local function sendInvitationFail(error)
        local errorCode = tonumber(error.data)
        if(CommErrorCodes.FRIEND_LIST_FULL.code == errorCode) then --好友已满
          CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_LIST_FULL, nil, nil, nil)
        elseif(CommErrorCodes.FRIEND_RELATIONSHIP_EXIST.code == errorCode) then -- 已经是好友
          CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_RELATIONSHIP_EXIST, nil, nil, nil)
        elseif(CommErrorCodes.FRIEND_INVITATION_EXIST.code == errorCode) then -- 邀请已存在
          CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_INVITATION_EXIST, nil, nil, removeOpData)
        elseif(CommErrorCodes.FRIEND_SENDER_INVITATION_LIST_FULL.code == errorCode) then -- 玩家发送邀请达到上限
          CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_SENDER_INVITATION_LIST_FULL, nil, nil, nil)
        elseif(CommErrorCodes.FRIEND_RECEIVER_INVITATION_LIST_FULL.code == errorCode) then -- 玩家接收邀请达到上限
          CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_RECEIVER_INVITATION_LIST_FULL, nil, nil, nil)
        elseif(CommErrorCodes.FRIEND_SELF_LIST_FULL.code == errorCode) then -- 自己好友数达上限
          CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_SELF_LIST_FULL, nil, nil, nil)
        elseif(CommErrorCodes.FRIEND_ENEMY_LIST_FULL.code == errorCode) then -- 对方好友数达上限
          CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_ENEMY_LIST_FULL, nil, nil, nil)
        else
          CanonMessageBox:showCommUnHandleErrorBox(errorCode)
        end
      end
      
      if(aData.invitationSent or aData.friend) then
        return nil
      end
      
      if(not self:canSendInvite()) then 
        return nil
      end
      
      local params = {friendUid = aData.friendUid}
      local sendInvitationRequest = SendInvitationRequest.new(params, rpc.SendingPriority.kHigh)
      sendInvitationRequest:addEventListener(RequestNotifyEnum.SendInvitationSucceed, sendInvitationCallback)
      sendInvitationRequest:addEventListener(RequestNotifyEnum.SendInvitationFailed, sendInvitationFail)
      
      sendInvitationRequest:start()
    else -- detail
      local userDetailPanel = UserDetailPanel:create( self.container, {friendUid = aData.friendUid, src = "FindFriendsPanel"} )
			PopoutManager:sharedManager():popout(userDetailPanel, kPopoutDir.kScale, true, false, self.container)
    end
  end
    
  local renderer = InvitationTableViewRenderer.new(FriendManager.DICT.ITEM_WIDTH, FriendManager.DICT.ITEM_HEIGHT)
  local aTableView = TableView:create(renderer, 
      FriendManager.DICT.TABLE_WIDTH, 
      FriendManager.DICT.TABLE_HEIGHT_FIND, 
      cellTag,
      buttonTag,
      CCScale9Sprite:create("pic/scroll.png"), 
      CCScale9Sprite:create("pic/scroll.png"),
      lstSharkFriend
    )
  
  
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  aTableView:setPosition(ccp(FriendManager.DICT.TABLE_POSX, FriendManager.DICT.TABLE_FIND_POSY))
  aTableView.hitTestPoint = function (self, worldPosition, useGroupTest)
    return false -- 修复遮挡下方按钮的bug
  end
  
  return aTableView
end

----------------------------------------
-- 好友详情弹框调用，设置邀请已发送
----------------------------------------
function FindFriendsPanel:sentInvite(friendUid)
  local idx = 0
  for i, friend in ipairs(lstSharkFriend) do
    if(friendUid == friend.friendUid) then
      idx = i
      break;
    end
  end
  
  if(idx <= 0) then
    return nil
  end
  
  local aData = lstSharkFriend[idx];
  aData.invitationSent = true
  table.insert(self.sentUids, friendUid)
  self.container.inviteSentPanel:addTableData(aData)
  
  local aCell = self.table:cellAtIndex(idx - 1)
  local btnSendInvite = aCell:getChildByTag(-1001):getChildByTag(-12)
  local picBtnSendInvite = btnSendInvite:getChildByTag(-10)
  local picBtnSendInviteDisable = btnSendInvite:getChildByTag(-11)
  local txtBtnSendInvite = btnSendInvite:getChildByTag(-12)
  
  btnSendInvite.ignoreTouch = aData.invitationSent
  if(btnSendInvite.setTouchEnabled) then
    btnSendInvite:setTouchEnabled(not aData.invitationSent)
  end
  picBtnSendInvite:setVisible(not aData.invitationSent)
  picBtnSendInviteDisable:setVisible(aData.invitationSent)
  local strAlreadySent = Localization:getInstance():getText("friend_AlreadySent")
  ViewControlUtil.setLableText(txtBtnSendInvite, strAlreadySent)

  self:refreshSendAllBtnStatus()
end

function FindFriendsPanel:cancelInvite(friendUid)
  local idx = 0
  for i, friend in ipairs(lstSharkFriend) do
    if(friendUid == friend.friendUid) then
      idx = i
      break;
    end
  end
  
  if(idx <= 0) then
    return nil
  end
  
  local aData = lstSharkFriend[idx];
  aData.invitationSent = false
  for i, uid in ipairs(self.sentUids) do
    if(uid == friendUid) then
      table.remove(self.sentUids, i)
      break;
    end
  end
  
  local aCell = self.table:cellAtIndex(idx - 1)
  local btnSendInvite = aCell:getChildByTag(-1001):getChildByTag(-12)
  local picBtnSendInvite = btnSendInvite:getChildByTag(-10)
  local picBtnSendInviteDisable = btnSendInvite:getChildByTag(-11)
  local txtBtnSendInvite = btnSendInvite:getChildByTag(-12)
  
  btnSendInvite.ignoreTouch = aData.invitationSent
  if(btnSendInvite.setTouchEnabled) then
    btnSendInvite:setTouchEnabled(not aData.invitationSent)
  end
  picBtnSendInvite:setVisible(not aData.invitationSent)
  picBtnSendInviteDisable:setVisible(aData.invitationSent)
  local strBtnSend = Localization:getInstance():getText("friend_SendBtn")
  ViewControlUtil.setLableText(txtBtnSendInvite, strBtnSend)

  self:refreshSendAllBtnStatus()
end

----------------------------------------
-- 好友主界面切换tag调用，刷新数据
----------------------------------------
function FindFriendsPanel:refreshTable()
  local function getRecommendedFriendsCallback(data) 
    lstSharkFriend = data.data.sharkFriends or {}
    if(self.table) then
      self:removeChild(self.table)
    end
    
    self.table = self:createInvitationTableView(lstSharkFriend)
    self:addChild(self.table)
    self.table:reloadData()

    self:refreshSendAllBtnStatus()
  end

  local getRecommendedFriendsRequest = GetRecommendedFriendsRequest.new(nil, rpc.SendingPriority.kHigh)
  getRecommendedFriendsRequest:addEventListener(RequestNotifyEnum.GetRecommendedFriendsSucceed, getRecommendedFriendsCallback)
  getRecommendedFriendsRequest:start()
end

function FindFriendsPanel:initLayer()
  FindFriendsPanel.super.initLayer(self)
  
  local builder = LayoutBuilder:createWithContentsOfFile(FriendManager.DICT.RESOURCE_FILE)
  self.panelUI = builder:build("friend_sendInvitation")
  
  self.txtNoFriend = self.panelUI:getChildByName("friend_txt_nofriend")
  self.txtNoFriend:getChildByName("txt"):setString(getTextByKey("friend_noUser"))
  self.txtNoFriend:setVisible(false)
  
  local sbTxtSearchInput = self.panelUI:getChildByName("friend_txt_searchInput")
  self.txtSearchInput = sbTxtSearchInput:getChildByName("font")
  self.txtSearchInput:setString("")
  if __IOS then
    self.txtSearchInput:setVisible(false)
  end
  
  -- 全部发送邀请
  local btnSendAllSb = self.panelUI:getChildByName("friend_btn_friend_SendAllBtn")
  local txtBtnSendAll = btnSendAllSb:getChildByName("txt_friend_SendAllBtn")
  local strBtnSendAll = Localization:getInstance():getText("friend_SendAllBtn")
  txtBtnSendAll:setString(strBtnSendAll)

  local function onSendAll()
    if(not self:canSendInvite()) then 
      return nil
    end
    
    local sendingUids = {}
    for i, friend in ipairs(lstSharkFriend) do
      local sent = nil
      if(self.sentUids and #self.sentUids > 0) then
        for j, uid in ipairs(self.sentUids) do
          if(uid == friend.friendUid) then
            sent = true
            break
          end
        end
      end

      if(not sent) then
        table.insert(sendingUids, friend.friendUid)
      end
    end

    local function sendAllInvitationsCallback(data)
      local sentSuccUids = data.data.friendUids
      if(sentSuccUids and #sentSuccUids > 0) then
        local sentSuccFriends = {}
        for i, friend in ipairs(lstSharkFriend) do
          for j, uid in ipairs(sentSuccUids) do
            if(uid == friend.friendUid) then
              friend.invitationSent = true
              table.insert(self.sentUids, uid)
              table.insert(sentSuccFriends, friend)
              break
            end
          end
        end
        
        self.container.inviteSentPanel:addTableDatas(sentSuccFriends)
        
        self.table:reloadData()
        self:refreshSendAllBtnStatus()
      else
        CanonMessageBox.showText(ShowButtonType.ID_OK, getTextByKey("friend_sendAllFailed")) 
      end
    end

    if(not sendingUids or #sendingUids == 0) then
      return nil
    end
    local params = {friendUids = sendingUids}
    local sendAllInvitationsRequest = SendAllInvitationsRequest.new(params, rpc.SendingPriority.kHigh)
    sendAllInvitationsRequest:addEventListener(RequestNotifyEnum.SendAllInvitationsSucceed, sendAllInvitationsCallback)
    sendAllInvitationsRequest:start()
  end
  self.btnSendAll = Button:create(btnSendAllSb)
  self.btnSendAll:addEventListener(Events.kStart, onSendAll, self)
  
  --搜索好友
  local txtBtnSearch = self.panelUI:getChildByName("friend_btn_friend_SearchBtn"):getChildByName("txt_friend_SearchBtn")
  local strBtnSearch = Localization:getInstance():getText("friend_SearchBtn")
  txtBtnSearch:setString(strBtnSearch)
  
  local function onSearch()
    self.txtNoFriend:setVisible(false)
    local nickName = self.txtSearchInput:getString()
    local function searchUserByNicknameCallback(data) 
      local sharkFriendDetail = data.data.sharkFriendDetail
      if(sharkFriendDetail) then
        if(sharkFriendDetail.friendUid ~= self.currUser.uid) then
          table.insert(lstSharkFriend, sharkFriendDetail)
          self:refreshSendAllBtnStatus()
          self.table:reloadData()
        end
      else
        self.txtNoFriend:setVisible(true)
      end
    end
    ---TODO 长度及合法性校验
    lstSharkFriend = {}
    self:refreshSendAllBtnStatus()
    self:refreshTableView()
    
    nickName = StringUtil.trim(nickName)
    if(string.len(nickName) > 0) then
      if(nickName == self.currUser.nickName) then
        self.txtNoFriend:setVisible(true)
        return nil
      end
      local params = {nickName = nickName}
      local searchUserByNicknameRequest = SearchUserByNicknameRequest.new(params, rpc.SendingPriority.kHigh)
      searchUserByNicknameRequest:addEventListener(RequestNotifyEnum.SearchUserByNicknameSucceed, searchUserByNicknameCallback)
      searchUserByNicknameRequest:start()
    end
    
    self.sendInvitationInput:setText("")
    self.txtSearchInput:setString("")
  end
  local btnSearch = Button:create(self.panelUI:getChildByName("friend_btn_friend_SearchBtn"))
  btnSearch:addEventListener(Events.kStart, onSearch, self)
  
  --再换一批
  local txtBtnChange = self.panelUI:getChildByName("friend_btn_friend_ChangeBtn"):getChildByName("txt_btn_friend_ChangeBtn")
  local strBtnChange = Localization:getInstance():getText("friend_ChangeBtn")
  txtBtnChange:setString(strBtnChange)
  
  local function onChange()
    self.txtNoFriend:setVisible(false)
    local function getRecommendedFriendsCallback(data) 
      lstSharkFriend = data.data.sharkFriends or {}

      self:refreshTableView()
      self:refreshSendAllBtnStatus()
      
      if(#lstSharkFriend == 0) then
        self.txtNoFriend:setVisible(true)
      end
    end

    local getRecommendedFriendsRequest = GetRecommendedFriendsRequest.new(nil, rpc.SendingPriority.kHigh)
    getRecommendedFriendsRequest:addEventListener(RequestNotifyEnum.GetRecommendedFriendsSucceed, getRecommendedFriendsCallback)
    getRecommendedFriendsRequest:start()
  end
  local btnChange = Button:create(self.panelUI:getChildByName("friend_btn_friend_ChangeBtn"))
  btnChange:addEventListener(Events.kStart, onChange, self)
  
  local sendInvitationInputSb = self.panelUI:getChildByName("friend_bg_serverSelect_serverList")
  local sendInvitationInputSize = sendInvitationInputSb:getBounds().size
  local sendInvitationInputPos = sendInvitationInputSb:getPosition()
  local sendInvitationInputSprite = Scale9Sprite:create("common/button.png")
  sendInvitationInputSprite:setAnchorPoint(ccp(0, 1))

  local function searchInputChanged()
    local nickName = self.sendInvitationInput:getText()
    self.txtSearchInput:setString(nickName)
  end
  self.sendInvitationInput = TextInput:create(CCSizeMake(sendInvitationInputSize.width, sendInvitationInputSize.height), sendInvitationInputSprite)
  self.sendInvitationInput:setPosition(ccp(sendInvitationInputPos.x + sendInvitationInputSize.width / 2, sendInvitationInputPos.y - sendInvitationInputSize.height / 2))
  self.sendInvitationInput.refCocosObj:setInputFlag( -100 ) -- 隐藏
  self.sendInvitationInput:setReturnType(kKeyboardReturnTypeDone)
  self.sendInvitationInput:addEventListener(kTextInputEvents.kChanged, searchInputChanged)
  self.panelUI:addChild(self.sendInvitationInput)
  sbTxtSearchInput:setZOrder(1001)
  
  self:addChild(self.panelUI)
end

function FindFriendsPanel:enterPanelAction()
  ViewControlUtil.showTableViewAction(self.table, visibleSize)
  ViewControlUtil.animateFadeIn(self.panelUI)
end

function FindFriendsPanel:exitPanelAction(callback)
  ViewControlUtil.disappearTableViewAction(self.table, visibleSize, callback)
  ViewControlUtil.animateFadeOut(self.panelUI)
end