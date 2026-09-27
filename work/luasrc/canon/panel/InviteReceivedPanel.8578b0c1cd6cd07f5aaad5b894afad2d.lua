--------------------------------------------------------------------------------
-- InviteReceivedPanel.lua - （等待审核）处理陌生人的好友请求: 1. 请求列表；2. 接受请求 3. 拒绝申请
-- 相关接口: getInvitationFriends, getRecommendedFriends, cancelInvitation
-- author: xiaojie.bai
-- date: 2013-08-12 16:30
--------------------------------------------------------------------------------

require "canon.data.MetaManager"
require "canon.data.DataManager"
require "canon.models.FriendManager"

require "canon.request.AcceptInvitationRequest"
require "canon.request.RefuseInvitationRequest"
require "canon.request.AcceptAllInvitationsRequest"
require "canon.request.RefuseAllInvitationsRequest"
require "canon.request.CommErrorCodes"

require "canon.customUI.CanonCard"
require "canon.customUI.SuspensionLabel"

require "canon.canonUtils"
require "canon.panel.CanonMessageBox"
require "canon.panel.UserDetailPanel"

require "canon.utils.ViewControlUtil"

InviteReceivedPanel = class(Layer)

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local lstSharkFriend = {}

function InviteReceivedPanel:ctor()
  self.container = nil

  -- 表格操作，记录被操作项信息
  self.opUid = nil
  self.opIndex = nil
end

function InviteReceivedPanel:create(container, params)
  self.container = container
  lstSharkFriend = params.lstInviteReceived or lstSharkFriend
  self.currUser = DataManager.getCurrUser()
  self.maxFriendNum = MetaManager.user_level[self.currUser.level].friendMax
  
  local panel = InviteReceivedPanel.new()
  panel:initLayer()
  return panel
end

--------------------
-- 刷新等待审核页签数量
--------------------
function InviteReceivedPanel:refreshInviteReceivedTagNum()
  self.container:setReceivedTagNum(#lstSharkFriend)
end

function InviteReceivedPanel:disableBtn(btnSb)
    btnSb:getChildByName("btn"):setVisible(false)
    btnSb:getChildByName("disable"):setVisible(true)
    btnSb:setTouchEnabled(false)
end

--------------------
-- 刷新表单内容
--------------------
function InviteReceivedPanel:refreshTableStatus(keepOffset)
  ViewControlUtil.refreshTableView(self.table, keepOffset)
  
  self:refreshInviteReceivedTagNum()

  if(not lstSharkFriend or #lstSharkFriend == 0) then
    self:disableBtn(self.btnAcceptAllSb)
    self:disableBtn(self.btnRefuseAllSb)
    
    self.table:setVisible(false)
    self.hintTableEmpty:setVisible(true)
  else
    self.table:setVisible(true)
    self.hintTableEmpty:setVisible(false)
  end
end

--------------------
-- 列表中移除指定玩家信息
--------------------
function InviteReceivedPanel:removeData(friendUid)
  local idx = 0
  for i, friend in ipairs(lstSharkFriend) do
    if(friendUid == friend.friendUid) then
      idx = i;
      break;
    end
  end
  
  if(idx == 0) then
    return nil
  end
  local aData = lstSharkFriend[idx];
  table.remove(lstSharkFriend, idx)
  self:refreshTableStatus(true)
  
  return aData
end

function InviteReceivedPanel:acceptInvite(friendUid)
  local aData = self:removeData(friendUid)
  if(aData) then
    self.container.friendPanel:addTableData(aData)
  end
end

function InviteReceivedPanel:refuseInvite(friendUid)
  self:removeData(friendUid)
end

----------------------------------------
-- 好友列表渲染
----------------------------------------
function InviteReceivedPanel:createInvitationTableView()
  local InvitationTableViewRenderer = class(TableViewRenderer)
  
  local strBtnAccept = Localization:getInstance():getText("friend_AcceptBtn")
  local strBtnRefuse = Localization:getInstance():getText("friend_RefuseBtn")
  
  local builder = LayoutBuilder:createWithContentsOfFile(FriendManager.DICT.RESOURCE_FILE)
  --------------------
  -- 初始化table数据
  --------------------
  function InvitationTableViewRenderer:ctor(width, height)
    self.list = lstSharkFriend
  end

  local cellTag = -1001
  local buttonTag = {-12, -13}
  --------------------
  -- table每个元素的模版构建
  --------------------
  function InvitationTableViewRenderer:buildCell(container)
    local aCell = builder:build("friend_verify_entry")
    container:addChild(aCell)
    
    aCell:setTag(cellTag)
    
    local txtFriendName = aCell:getChildByName("friend_txt_friend_playerName");
    txtFriendName:setTag(-10)
    local txtFriendNameValue = txtFriendName:getChildByName("font")
    txtFriendNameValue:setTag(-10)
    
    local txtLv = aCell:getChildByName("friend_txt_lv_num")
    txtLv:setTag(-11)
    local txtLvValue = txtLv:getChildByName("font")
    txtLvValue:setTag(-10)
    
    local btnAcceptInvitee = aCell:getChildByName("friend_btn_playerInfo_invitationReceived_accept")
    btnAcceptInvitee:setTag(-12)
    local picBtnAcceptInvitee = btnAcceptInvitee:getChildByName("btn")
    picBtnAcceptInvitee:setTag(-10)
    btnAcceptInvitee:getChildByName("font"):setString(strBtnAccept)
    
    local btnRefuseInvitee = aCell:getChildByName("friend_btn_playerInfo_invitationReceived_refuse")
    btnRefuseInvitee:setTag(-13)
    local picBtnRefuseInvitee = btnRefuseInvitee:getChildByName("btn")
    picBtnRefuseInvitee:setTag(-10)
    btnRefuseInvitee:getChildByName("font"):setString(strBtnRefuse)

    local cardFrameM = aCell:getChildByName("friend_frame_card")
    cardFrameM:setTag(-15)
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
    
    local txtLv = aCell:getChildByTag(-11)
    local txtLvValue = txtLv:getChildByTag(-10)
    ViewControlUtil.setLableText(txtLvValue, aData.level)

    local cardFrameSb = CocosObject.new(aCell:getChildByTag(-15))
    local smallCanonCard = getHeadIconCanonCardByMetaId(aData.mainCardMetaId)
    ViewControlUtil.adjustItemByFrame(smallCanonCard, cardFrameSb)
    aCell:addChild(smallCanonCard.refCocosObj, 1001)
    smallCanonCard:setTag(-30)
    smallCanonCard:dispose()
    cardFrameSb:setVisible(false)
  end
  
  local function removeOpData()
    table.remove(lstSharkFriend, self.opIndex)
    
    self:refreshTableStatus(true)
  end
  
  local function acceptInvitationCallback(data)
    SuspensionLabel:showContent(self.container, getTextByKey("friend_acceptRequestSuccess"))
    
    removeOpData()
    
    local aData = data.data.acceptedFriend
    self.container.friendPanel:addTableData(aData)
  end
  
  local function acceptInvitationFailed(error)
    local errorCode = tonumber(error.data)
    
    if(CommErrorCodes.FRIEND_LIST_FULL.code == errorCode) then --好友已满
      CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_LIST_FULL, nil, nil, nil)
    elseif(CommErrorCodes.FRIEND_RELATIONSHIP_EXIST.code == errorCode) then -- 已经是好友
      CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_RELATIONSHIP_EXIST, nil, nil, nil)
    elseif(CommErrorCodes.FRIEND_INVITATION_NOT_EXIST.code == errorCode) then -- 邀请已不存在
      CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_INVITATION_NOT_EXIST, nil, nil, removeOpData)
    elseif(CommErrorCodes.FRIEND_SELF_LIST_FULL.code == errorCode) then --自己好友列表已满
      CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_SELF_LIST_FULL, nil, nil, nil)
    elseif(CommErrorCodes.FRIEND_ENEMY_LIST_FULL.code == errorCode) then --对方好友列表已满
      CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_ENEMY_LIST_FULL, nil, nil, nil)
    else
      CanonMessageBox:showCommUnHandleErrorBox(errorCode)
    end
  end
  
  local function acceptInvitation(friendUid, aIndex)
    self.opUid = friendUid
    self.opIndex = aIndex

    local param = {friendUid = friendUid}
    local acceptInvitationRequest = AcceptInvitationRequest.new(param, rpc.SendingPriority.kHigh)
    acceptInvitationRequest:addEventListener(RequestNotifyEnum.AcceptInvitationSucceed, acceptInvitationCallback)
    acceptInvitationRequest:addEventListener(RequestNotifyEnum.AcceptInvitationFailed, acceptInvitationFailed)
    acceptInvitationRequest:start()
  end

  local function refuseInvitationCallback(data)
    SuspensionLabel:showContent(self.container, getTextByKey("friend_refuseRequest"))
    
    removeOpData()
  end
  
  local function refuseInvitation(friendUid, aIndex)
    self.opUid = friendUid
    self.opIndex = aIndex

    local param = {friendUid = friendUid}
    local refuseInvitationRequest = RefuseInvitationRequest.new(param, rpc.SendingPriority.kHigh)
    refuseInvitationRequest:addEventListener(RequestNotifyEnum.RefuseInvitationSucceed, refuseInvitationCallback)
    refuseInvitationRequest:start()
  end
  
  --------------------
  -- table元素被点击事件响应
  --------------------
  local function onListItemTouch(evt)
    local aIndex = evt.data + 1
    local aCell = self.table:cellAtIndex(aIndex - 1)
    local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
    local aData = lstSharkFriend[aIndex];
    
    local btnAcceptInvitee = aCell:getChildByTag(-1001):getChildByTag(-12)
    local picBtnAcceptInvitee = btnAcceptInvitee:getChildByTag(-10)
    
    local btnRefuseInvitee = aCell:getChildByTag(-1001):getChildByTag(-13)
    local picBtnRefuseInvitee = btnRefuseInvitee:getChildByTag(-10)
    
    local btnFriendDetail = aCell:getChildByTag(-1001):getChildByTag(-14)
    
    if ViewControlUtil.isInAreaPic(posInCell, btnAcceptInvitee, picBtnAcceptInvitee) then --accept
      acceptInvitation(aData.friendUid, aIndex)
    elseif ViewControlUtil.isInAreaPic(posInCell, btnRefuseInvitee, picBtnRefuseInvitee) then --refuse
      refuseInvitation(aData.friendUid, aIndex)
    else -- detail
      local userDetailPanel = UserDetailPanel:create( self.container, {friendUid = aData.friendUid} )
      PopoutManager:sharedManager():popout(userDetailPanel, kPopoutDir.kScale, true, false, self.container)
    end
  end
    
  local renderer = InvitationTableViewRenderer.new(FriendManager.DICT.ITEM_WIDTH, FriendManager.DICT.ITEM_HEIGHT)
  local aTableView = TableView:create(renderer, 
      FriendManager.DICT.TABLE_WIDTH, 
      FriendManager.DICT.TABLE_HEIGHT_INVITE_RECEIVED, 
      cellTag,
      buttonTag,
      CCScale9Sprite:create("pic/scroll.png"), 
      CCScale9Sprite:create("pic/scroll.png"),
      lstSharkFriend
    )

  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  aTableView:setPosition(ccp(FriendManager.DICT.TABLE_POSX, FriendManager.DICT.TABLE_POSY))
  
  return aTableView
end

function InviteReceivedPanel:initLayer()
  InviteReceivedPanel.super.initLayer(self)
  
  local builder = LayoutBuilder:createWithContentsOfFile(FriendManager.DICT.RESOURCE_FILE)
  self.panelUI = builder:build("friend_page_2")
  
  local strBtnAcceptAll = Localization:getInstance():getText("friend_AcceptAllBtn")
  local strBtnRefuseAll = Localization:getInstance():getText("friend_RefuseAllBtn")
  local strInviteReceivedDesc = Localization:getInstance():getText("friend_RequestReceivedText")
  
  local txtGiftIntro = self.panelUI:getChildByName("friend_txt_friend_FriendListText"):getChildByName("txt_friend_FriendListText")
  txtGiftIntro:setDimensions(CCSizeMake(txtGiftIntro:getDimensions().width, 0))
  txtGiftIntro:setString(strInviteReceivedDesc)
  
  -- 全部接收
  self.btnAcceptAllSb = self.panelUI:getChildByName("friend_btn_friend_AcceptAllBtn");
  local txtBtnAcceptAll = self.btnAcceptAllSb:getChildByName("txt_friend_AcceptAllBtn")
  txtBtnAcceptAll:setString(strBtnAcceptAll)
  
  local function acceptAllCallback(data)
    local acceptedFriends = data.data.acceptedFriends
    if(acceptedFriends and #acceptedFriends > 0) then
      for _, acceptedFriend in ipairs(acceptedFriends) do
        self.container.friendPanel:addTableData(acceptedFriend)
      end
    end
    
    for idx = #lstSharkFriend, 1, -1 do
      table.remove(lstSharkFriend, idx)
    end
    
    local resFriends = data.data.reviewingFriends
    if(resFriends) then
      for i, sharkFriend in ipairs(resFriends) do
        table.insert(lstSharkFriend, sharkFriend)
      end
    end
    
    self:refreshTableStatus()
  end
  local function onAcceptAll()
    if(not lstSharkFriend or #lstSharkFriend == 0) then
      return nil
    end
    
    if(self.container.friendPanel:getFriendsNum() >= self.maxFriendNum) then
      local strWarnFriendsNumMax = Localization:getInstance():getText("friend_acceptRequestFailed_friendFull")
      CanonMessageBox:Show(strWarnFriendsNumMax, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil, nil)
      return nil
    end
    
    local acceptAllInvitationsRequest = AcceptAllInvitationsRequest.new(nil, rpc.SendingPriority.kHigh)
    acceptAllInvitationsRequest:addEventListener(RequestNotifyEnum.AcceptAllInvitationsSucceed, acceptAllCallback)
    acceptAllInvitationsRequest:start()
  end

  -- 全部拒绝
  self.btnRefuseAllSb = self.panelUI:getChildByName("friend_btn_friend_RefuseAllBtn")
  local txtBtnRefuseAll = self.btnRefuseAllSb:getChildByName("txt_friend_RefuseAllBtn")
  txtBtnRefuseAll:setString(strBtnRefuseAll)
  
  local function refuseAllCallback(data)
    SuspensionLabel:showContent(self.container, getTextByKey("friend_refuseRequestAll"))
    
    for idx = #lstSharkFriend, 1, -1 do
      table.remove(lstSharkFriend, idx)
    end
    
    self:refreshTableStatus()
  end
  local function onRefuseAll()
    if(not lstSharkFriend or #lstSharkFriend == 0) then
      return nil
    end
    
    local refuseAllInvitationsRequest = RefuseAllInvitationsRequest.new(nil, rpc.SendingPriority.kHigh)
    refuseAllInvitationsRequest:addEventListener(RequestNotifyEnum.RefuseAllInvitationsSucceed, refuseAllCallback)
    refuseAllInvitationsRequest:start()
  end

  if(not lstSharkFriend or #lstSharkFriend == 0) then
    self:disableBtn(self.btnAcceptAllSb)
    self:disableBtn(self.btnRefuseAllSb)
  else 
    local btnAcceptAll = Button:create(self.btnAcceptAllSb)
    btnAcceptAll:addEventListener(Events.kStart, onAcceptAll, self)

    local btnRefuseAll = Button:create(self.btnRefuseAllSb);
    btnRefuseAll:addEventListener(Events.kStart, onRefuseAll, self)
  end
  
  self:addChild(self.panelUI)
  
  -- 渲染 TableView
  self.table = self:createInvitationTableView()
  self:addChild(self.table)
  self.table:reloadData()
  
  self.hintTableEmpty = self.panelUI:getChildByName("friend_txt_friend_RequestReceivedText_empty")
  local txtHintTableEmpty = self.hintTableEmpty:getChildByName("txt")
  txtHintTableEmpty:setString(getTextByKey("friend_RequestReceivedText_empty"))
  if(self.table and self.table.tableViewRenderer:numberOfCells() > 0) then
    self.hintTableEmpty:setVisible(false)
  else
    self.table:setVisible(false)
  end
end

function InviteReceivedPanel:enterPanelAction()
  ViewControlUtil.showTableViewAction(self.table, visibleSize)
  ViewControlUtil.animateFadeIn(self.panelUI)
end

function InviteReceivedPanel:exitPanelAction(callback)
  ViewControlUtil.disappearTableViewAction(self.table, visibleSize, callback)
  ViewControlUtil.animateFadeOut(self.panelUI)
end