--------------------------------------------------------------------------------
-- InviteSendPanel.lua - （我的申请）加好友请求发送界面:1. 发送列表；2. 添加好友；3. 取消申请
-- 相关接口: getInvitationFriends, getRecommendedFriends, cancelInvitation
-- author: xiaojie.bai
-- date: 2013-08-12 14:53
--------------------------------------------------------------------------------

require "canon.data.MetaManager"
require "canon.models.FriendManager"

require "canon.request.CancelInvitationRequest"

require "canon.customUI.CanonCard"
require "canon.customUI.SuspensionLabel"

require "canon.canonUtils"

require "canon.panel.UserDetailPanel"
require "canon.utils.ViewControlUtil"

InviteSentPanel = class(Layer)

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local lstInviteSent = {}

function InviteSentPanel:ctor()
  self.container = nil

  -- 表格操作，记录被操作项信息
  self.opUid = nil
  self.opIndex = nil
end

function InviteSentPanel:create(container, params)
  self.container = container
  lstInviteSent = params.lstInviteSent or lstInviteSent

  local panel = InviteSentPanel.new()
  panel:initLayer()
  return panel
end

----------------------------------------
-- 好友列表渲染
----------------------------------------
function InviteSentPanel:createInvitationTableView()
  local InvitationTableViewRenderer = class(TableViewRenderer)
  
  local strBtnCancel = Localization:getInstance():getText("friend_CancelBtn")
  
  local builder = LayoutBuilder:createWithContentsOfFile(FriendManager.DICT.RESOURCE_FILE)
  --------------------
  -- 初始化table数据
  --------------------
  function InvitationTableViewRenderer:ctor(width, height)
    self.list = lstInviteSent
  end
  
  local cellTag = -1001
  local buttonTag = {-12}
  --------------------
  -- table每个元素的模版构建
  --------------------
  function InvitationTableViewRenderer:buildCell(container)
    local aCell = builder:build("friend_apply_entry")
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
    
    local btnCancelInvite = aCell:getChildByName("friend_btn_friend_CancelBtn")
    btnCancelInvite:setTag(-12)
    local picBtnCancelInvite = btnCancelInvite:getChildByName("btn")
    picBtnCancelInvite:setTag(-10)
    
    local txtBtnCancelInvite = btnCancelInvite:getChildByName("txt_friend_CancelBtn")
    if type(txtBtnCancelInvite.setString) == "function" then
      txtBtnCancelInvite:setString(strBtnCancel)
    end

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
    if not lstInviteSent or #lstInviteSent == 0 then
      return nil
    end
    
    local aData = lstInviteSent[index + 1];
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
  local function cancelInviteCallback(data)
    SuspensionLabel:showContent(self.container, getTextByKey("friend_cancelRequestSuccess"))
    
    table.remove(lstInviteSent, self.opIndex)
    self:refreshTableStatus(true)
  end
  local function cancelInvite(friendUid, aIndex)
    self.opUid = friendUid
    self.opIndex = aIndex

    local params = {friendUid = friendUid}
    local cancelInvitationRequest = CancelInvitationRequest.new(params, rpc.SendingPriority.kHigh)
    cancelInvitationRequest:addEventListener(RequestNotifyEnum.CancelInvitationSucceed, cancelInviteCallback)
    cancelInvitationRequest:start()
  end

  --------------------
  -- table元素被点击事件响应
  --------------------
  local function onListItemTouch(evt)
    local aIndex = evt.data + 1
    local aCell = self.table:cellAtIndex(aIndex - 1)
    local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
    local aData = lstInviteSent[aIndex];
    
    local btnCancelInvite = aCell:getChildByTag(-1001):getChildByTag(-12)
    local picBtnCancelInvite = btnCancelInvite:getChildByTag(-10)
    local btnFriendDetail = aCell:getChildByTag(-1001):getChildByTag(-13)
    
    if ViewControlUtil.isInAreaPic(posInCell, btnCancelInvite, picBtnCancelInvite) then
      cancelInvite(aData.friendUid, aIndex)
    else -- detail
      local userDetailPanel = UserDetailPanel:create( self.container, {friendUid = aData.friendUid} )
      PopoutManager:sharedManager():popout(userDetailPanel, kPopoutDir.kScale, true, false, self.container)
    end
  end
    
  local renderer = InvitationTableViewRenderer.new(FriendManager.DICT.ITEM_WIDTH, FriendManager.DICT.ITEM_HEIGHT)
  local aTableView = TableView:create(renderer, 
      FriendManager.DICT.TABLE_WIDTH, 
      FriendManager.DICT.TABLE_HEIGHT_INVITE_SENT, 
      cellTag,
      buttonTag,
      CCScale9Sprite:create("pic/scroll.png"), 
      CCScale9Sprite:create("pic/scroll.png"),
      lstInviteSent
    )
  
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  aTableView:setPosition(ccp(FriendManager.DICT.TABLE_POSX, FriendManager.DICT.TABLE_POSY))
  
  return aTableView
end

function InviteSentPanel:refreshTableStatus(keepOffset)
  ViewControlUtil.refreshTableView(self.table, keepOffset)
  
  self:refreshInviteSentTagNum()
  
  if(lstInviteSent and #lstInviteSent > 0) then
    self.table:setVisible(true)
    self.hintTableEmpty:setVisible(false)
  else
    self.table:setVisible(false)
    self.hintTableEmpty:setVisible(true)
  end
end

--------------------
-- 增加已发送邀请
--------------------
function InviteSentPanel:addTableData(aData) 
  if(not aData) then
    return nil
  end
  
  local ownedUids = {}
  for _, aData in ipairs(lstInviteSent) do
    ownedUids[aData.friendUid] = aData.friendUid
  end
  
  if(not ownedUids[aData.friendUid]) then
    table.insert(lstInviteSent, aData)
    self:refreshTableStatus(true)
  end
end

--------------------
-- 增加已发送邀请
--------------------
function InviteSentPanel:addTableDatas(aDatas) 
  if(not aDatas or #aDatas == 0) then
    return nil
  end
  
  local ownedUids = {}
  for _, aData in ipairs(lstInviteSent) do
    ownedUids[aData.friendUid] = aData.friendUid
  end
  
  for i, aData in ipairs(aDatas) do
    if(not ownedUids[aData.friendUid]) then
      table.insert(lstInviteSent, aData)
    end
  end

  self:refreshTableStatus(true, #aDatas)
end

function InviteSentPanel:cancelInvite(friendUid)
  local opIdx = 0;
  for i, friend in ipairs(lstInviteSent) do
    if(friend.friendUid == friendUid) then
      opIdx = i;
      break;
    end
  end
  
  if(opIdx > 0) then
    table.remove(lstInviteSent, opIdx)
    self:refreshTableStatus(true)
  end
end

--------------------
-- 刷新我的申请页签数量
--------------------
function InviteSentPanel:refreshInviteSentTagNum()
  self.container:setSentTagNum(#lstInviteSent)
end

function InviteSentPanel:initLayer()
  InviteSentPanel.super.initLayer(self)
  
  local builder = LayoutBuilder:createWithContentsOfFile(FriendManager.DICT.RESOURCE_FILE)
  self.panelUI = builder:build("friend_page_3")
  
  local strInviteSentDesc = Localization:getInstance():getText("friend_RequestSentText")
  local strBtnFindMoreFriend = Localization:getInstance():getText("friend_FindMoreBtn")
  
  local txtInviteSentDesc = self.panelUI:getChildByName("friend_txt_friend_FriendListText"):getChildByName("txt_friend_FriendListText")
  txtInviteSentDesc:setDimensions(CCSizeMake(txtInviteSentDesc:getDimensions().width, 0))
  txtInviteSentDesc:setString(strInviteSentDesc)
  
  self:addChild(self.panelUI)
  
  -- 渲染 TableView
  self.table = self:createInvitationTableView()
  self:addChild(self.table)
  self.table:reloadData()
  
  self.hintTableEmpty = self.panelUI:getChildByName("friend_txt_friend_RequestSentText_empty")
  local txtHintTableEmpty = self.hintTableEmpty:getChildByName("txt")
  txtHintTableEmpty:setString(getTextByKey("friend_RequestSentText_empty"))
  if(self.table and self.table.tableViewRenderer:numberOfCells() > 0) then
    self.hintTableEmpty:setVisible(false)
  else
    self.table:setVisible(false)
  end
end

function InviteSentPanel:enterPanelAction()
  ViewControlUtil.showTableViewAction(self.table, visibleSize)
  ViewControlUtil.animateFadeIn(self.panelUI)
end

function InviteSentPanel:exitPanelAction(callback)
  ViewControlUtil.disappearTableViewAction(self.table, visibleSize, callback)
  ViewControlUtil.animateFadeOut(self.panelUI)
end