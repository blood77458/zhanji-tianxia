--------------------------------------------------------------------------------
-- UserDetailPanel.lua - 玩家信息界面:队列、留言、切磋、删除好友
-- author: xiaojie.bai
-- date: 2013-08-15 13:50
--------------------------------------------------------------------------------
require "canon.models.FriendManager"

require "canon.request.CommErrorCodes"
require "canon.request.GetFriendDetailRequest"
require "canon.request.DeleteFriendRequest"
require "canon.request.AcceptInvitationRequest"
require "canon.request.RefuseInvitationRequest"
require "canon.request.CancelInvitationRequest"
require "canon.request.SendInvitationRequest"
require "canon.request.ChallengeFriendRequest"
require "canon.request.GetPlayerTeamInfoRequest"
require "canon.request.ChallengeFriendListRequest"

require "canon.panel.EmailWritePanel"
require "canon.panel.CanonMessageBox"

require "canon.customUI.CanonCard"
require "canon.canonUtils"
require "canon.data.DataManager"

require "canon.models.BattleManager"
require "canon.scene.BattleScene"

require "canon.customUI.SuspensionLabel"

UserDetailPanel = class(Layer)

UserDetailPanel.MESSAGE_TYPE_NORMAL = 1
UserDetailPanel.MESSAGE_TYPE_PRIVATE_MESSAGE = 2

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

----------------------------------------------------------------------------------------------------------------------------------------按钮侦听函数

local function onAddFriend(evt)
  local self = evt.context

  local function onSendInviteCallback(data)
    self:showOpResultTips(getTextByKey("friend_sendRequestSuccess"))
    if(self.container.findFriendsPanel) then
      self.container.findFriendsPanel:sentInvite(self.friendUid)
    end
    self:closePanel();
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
  local params = {friendUid = self.friendUid}
  local sendInvitationRequest = SendInvitationRequest.new(params, rpc.SendingPriority.kHigh)
  sendInvitationRequest:addEventListener(RequestNotifyEnum.SendInvitationSucceed, onSendInviteCallback)
  sendInvitationRequest:addEventListener(RequestNotifyEnum.SendInvitationFailed, sendInvitationFail)
  sendInvitationRequest:start()
end

----------------------------------------------------------------------------------------------------------------------------------------

function UserDetailPanel:ctor()
  self.friendUid = nil
  self.userDetail = nil
end

function UserDetailPanel:create(container, params)
  self.container = container
  
  local panel = UserDetailPanel.new()

  panel.friendUid = params.friendUid
  panel.src = params.src
  panel.messageType = params.messageType or UserDetailPanel.MESSAGE_TYPE_NORMAL--发送消息方式类型
  panel.onPrivateMessageCallback = params.onPrivateMessageCallback
  panel.currUser = DataManager.getCurrUser()
  panel.currUId = panel.currUser.uid
  panel.FriendTableViewContentHeight = params.FriendTableViewContentHeight
  panel.lstSharkFriend = params.lstSharkFriend --传入好友信息，一键切磋用
  panel.tableList = params.table

  panel:initLayer()
  return panel
end

----------------------------------------
-- 发送邮件
----------------------------------------
function UserDetailPanel:SendEmail()
	local panel = EmailWritePanel:create(self.container, nil, self.userDetail.nickName, self.userDetail.friendUid, false)
	PopoutManager:sharedManager():popout(panel, nil, true, false, self.container)
end

----------------------------------------
-- 初始化好友文字信息
----------------------------------------
function UserDetailPanel:initFriendInfo()
  local strFriendAmountSb = Localization:getInstance():getText("friend_FriendAmount")
  local strFriendAmount = self.userDetail.friendNum .. "/" .. self.userDetail.friendNumMax
  local strArenaRankSb = Localization:getInstance():getText("friend_ArenaRank")
  local strStrengthSb = Localization:getInstance():getText("friend_Strength")
  local strPanelTitle = Localization:getInstance():getText("userDetail_title");
    
  local friendInfoSb = self.panelUI:getChildByName("friend_sb_playerInfo")
  
  local cardFrameSb = friendInfoSb:getChildByName("friend_frame_card")
  cardFrameSb:setVisible(false)

  local canonCard = getHeadIconCanonCardByMetaId(self.userDetail.mainCardMetaId)
  ViewControlUtil.adjustItemByFrame(canonCard, cardFrameSb)
  canonCard:setZOrder(10001)
  friendInfoSb:addChild(canonCard)
  
  self.panelUI:getChildByName("friend_txt_friendInfo_title"):getChildByName("font"):setString(strPanelTitle);
  
  friendInfoSb:getChildByName("friend_txt_friend_lv_num"):getChildByName("font"):setString(self.userDetail.level);
  friendInfoSb:getChildByName("friend_txt_friend_playerName"):getChildByName("font"):setString(self.userDetail.nickName);
  friendInfoSb:getChildByName("friend_txt_friend_friendAmount"):getChildByName("font"):setString(strFriendAmountSb);
  friendInfoSb:getChildByName("friend_txt_friend_friendAmount_num"):getChildByName("font"):setString(strFriendAmount);
  
  if self.container.curSceneEnum == SceneEnum.PKScene or self.container.curSceneEnum == SceneEnum.NewBabelRankScene then
    friendInfoSb:getChildByName("friend_txt_friend_arenaRank"):getChildByName("font"):setString(strStrengthSb);
    friendInfoSb:getChildByName("friend_txt_friend_arenaRank_num"):getChildByName("font"):setString(self.userDetail.fightCapacity);
    friendInfoSb:getChildByName("friend_txt_friend_strength"):setVisible(false)
    friendInfoSb:getChildByName("friend_txt_friend_strength_num"):setVisible(false)
  else
    friendInfoSb:getChildByName("friend_txt_friend_arenaRank"):getChildByName("font"):setString(strArenaRankSb);
    local strArenaRankName = self.userDetail.arenaRank > 0 and self.userDetail.arenaRank or getTextByKey("friend_arenaRank_out")
    friendInfoSb:getChildByName("friend_txt_friend_arenaRank_num"):getChildByName("font"):setString(strArenaRankName);
    friendInfoSb:getChildByName("friend_txt_friend_strength"):getChildByName("font"):setString(strStrengthSb);
    friendInfoSb:getChildByName("friend_txt_friend_strength_num"):getChildByName("font"):setString(self.userDetail.fightCapacity);
  end
  
  if self.userDetail.unionName then
    friendInfoSb:getChildByName("txt_guild_namae"):setVisible(true)
    friendInfoSb:getChildByName("txt_guild_namae"):getChildByName("txt"):setString(Localization:getInstance():getText("union_name_txt", {name = self.userDetail.unionName}));--otherUnionName
  else
    friendInfoSb:getChildByName("txt_guild_namae"):setVisible(false)
  end
end

function UserDetailPanel:initDefaultOp()
  local opArea = self.panelUI:getChildByName("friend_btn_playerInfo_invitationReceived")
  opArea:setVisible(true)

  -- 加为好友
  local txtBtnAddFriend = opArea:getChildByName("friend_btn_playerInfo_invitationReceived_accept"):getChildByName("font")
  local strBtnAddFriend = Localization:getInstance():getText("friend_AddFriendBtn")
  txtBtnAddFriend:setString(strBtnAddFriend)
  
  local btnAddFriend = Button:create(opArea:getChildByName("friend_btn_playerInfo_invitationReceived_accept"))
  btnAddFriend:addEventListener(Events.kStart, onAddFriend, self)
  
  --查看队列
  local txtBtnFormation = opArea:getChildByName("friend_btn_playerInfo_invitationReceived_refuse"):getChildByName("font")
  local strBtnFormation = Localization:getInstance():getText("friend_FormationBtn")
  txtBtnFormation:setString(strBtnFormation)
  
  local function onFormation()
    params = {
      playerUid = self.friendUid,
    }
    local function onGetPlayerTeamInfoCallback( evt )
      local argv = {
      enterScene = self.container.curSceneEnum,
      returnScene = self.container.curSceneEnum,
      params = {
          playerUid = self.friendUid,
          playerTeamData = evt.data,
        },
      }
      self:closePanel()
      self.container:replaceScene( CardQueueScene, argv )
    end
	
    local getPlayerTeamInfoRequest = GetPlayerTeamInfoRequest.new(params, rpc.SendingPriority.kHigh)
    getPlayerTeamInfoRequest:addEventListener(RequestNotifyEnum.GetPlayerTeamInfoSucceed, onGetPlayerTeamInfoCallback)
    getPlayerTeamInfoRequest:start()
  end
  local btnFormation = Button:create(opArea:getChildByName("friend_btn_playerInfo_invitationReceived_refuse"))
  btnFormation:addEventListener(Events.kStart, onFormation, self)
  
  -- 留言
  local txtBtnSendMessage = opArea:getChildByName("friend_btn_friend_SendMessageBtn"):getChildByName("txt_friend_SendMessageBtn")
  local strBtnSendMessage = Localization:getInstance():getText("friend_SendMessageBtn")
  txtBtnSendMessage:setString(strBtnSendMessage)
  
  local function onSendMessage()
    self:SendEmail()
  end
  local btnSendMessage = Button:create(opArea:getChildByName("friend_btn_friend_SendMessageBtn"))
  btnSendMessage:addEventListener(Events.kStart, onSendMessage, self)
end

-----------------------------------
-- 显示私聊好友界面
-----------------------------------
function UserDetailPanel:initPrivateMessageOp()
  local opArea = self.panelUI:getChildByName("friend_btn_playerInfo_default")
  opArea:setVisible(true)

  -- 加为好友
  local txtBtnAddFriend = opArea:getChildByName("friend_btn_friend_AddFriendBtn"):getChildByName("txt_friend_AddFriendBtn")
  if self.userDetail.friend then
    txtBtnAddFriend:setString(Localization:getInstance():getText("union_player_button_aready_friend"))--已是好友
  elseif self.userDetail.invitationSent then
    txtBtnAddFriend:setString(Localization:getInstance():getText("friend_AlreadySent"))--已发申请
  else
    txtBtnAddFriend:setString(Localization:getInstance():getText("friend_AddFriendBtn"))
  end
  
  local btnAddFriend = Button:create(opArea:getChildByName("friend_btn_friend_AddFriendBtn"))
  btnAddFriend:addEventListener(Events.kStart, onAddFriend, self)
  if self.userDetail.friend or self.userDetail.invitationSent then
    --不可点击
    btnAddFriend:setEnable(false)
    btnAddFriend.touchEnabled = false
    opArea:getChildByName("friend_btn_friend_AddFriendBtn"):getChildByName("btn"):setVisible(false)
  end
  
  -- 私聊
  local txtBtnSendMessage = opArea:getChildByName("friend_btn_friend_SendMessageBtn"):getChildByName("txt_friend_SendMessageBtn")
  local strBtnSendMessage = Localization:getInstance():getText("union_chat_private_text")
  txtBtnSendMessage:setString(strBtnSendMessage)
  
  local function onSendMessage()
    print("onSendMessage")
    --ChatManager.gotoPrivateChat(self.userDetail.nickName, self.userDetail.friendUid)
    if self.onPrivateMessageCallback then
      self:closePanel()
      self.onPrivateMessageCallback(self.userDetail.nickName, self.userDetail.friendUid)
    end
  end
  local btnSendMessage = Button:create(opArea:getChildByName("friend_btn_friend_SendMessageBtn"))
  btnSendMessage:addEventListener(Events.kStart, onSendMessage, self)
end

function UserDetailPanel:showOpResultTips(aContent)
  SuspensionLabel:showContent(self.container, aContent)
end

function UserDetailPanel:initFriendOp()
  local opArea = self.panelUI:getChildByName("friend_btn_playerInfo_friend")
  opArea:setVisible(true)

  -- 队列
  local txtBtnFormation = opArea:getChildByName("friend_btn_friend_FormationBtn"):getChildByName("txt_friend_FormationBtn")
  local strBtnFormation = Localization:getInstance():getText("friend_FormationBtn")
  txtBtnFormation:setString(strBtnFormation)
  
  local function onFormation()
    params = {
      playerUid = self.friendUid,
    }
    local function onGetPlayerTeamInfoCallback( evt )
      local argv = {
      enterScene = self.container.curSceneEnum,
      returnScene = self.container.curSceneEnum,
      params = {
          playerUid = self.friendUid,
          playerTeamData = evt.data,
        },
      }
      self:closePanel()
      self.container:replaceScene( CardQueueScene, argv )
    end
	
    local getPlayerTeamInfoRequest = GetPlayerTeamInfoRequest.new(params, rpc.SendingPriority.kHigh)
    getPlayerTeamInfoRequest:addEventListener(RequestNotifyEnum.GetPlayerTeamInfoSucceed, onGetPlayerTeamInfoCallback)
    getPlayerTeamInfoRequest:start()
  end
  local btnFormation = Button:create(opArea:getChildByName("friend_btn_friend_FormationBtn"))
  btnFormation:addEventListener(Events.kStart, onFormation, self)
  
  -- 留言
  local txtBtnSendMessage = opArea:getChildByName("friend_btn_friend_SendMessageBtn"):getChildByName("txt_friend_SendMessageBtn")
  local strSendMessage = Localization:getInstance():getText("friend_SendMessageBtn")
  txtBtnSendMessage:setString(strSendMessage)
  
  local function onSendMessage()
    self:SendEmail()
  end
  local btnSendMessage = Button:create(opArea:getChildByName("friend_btn_friend_SendMessageBtn"))
  btnSendMessage:addEventListener(Events.kStart, onSendMessage, self)
  
  -- 切磋
  local txtBtnChallenge = opArea:getChildByName("friend_btn_friend_ChallengeBtn"):getChildByName("txt_friend_ChallengeBtn")
  local strBtnChallenge = Localization:getInstance():getText("friend_ChallengeBtn")
  txtBtnChallenge:setString(strBtnChallenge)
  
  local function onChallenge()
    local function onChallengeFriendSucc(data)
      local fightFriendUids = DailyDataManager.getFightFriendUids()
      local challenged = FriendManager.containUid(fightFriendUids, self.friendUid)
      if not challenged then
        table.insert(fightFriendUids, self.friendUid)
        DailyDataManager.setFightFriendUids(fightFriendUids)
      end
      data.data.tableContentHeight = self.FriendTableViewContentHeight
      
      Director:sharedDirector():replaceScene(BattleScene:create(data.data, BattleBackType.kUserDetailPanel, BattleEnterEnum.kUserDetailPanel, 1))
    end
    
    local function onChallengeFriendFail(error)
      local errorCode = tonumber(error.data)
      
      if(CommErrorCodes.FRIEND_NOT_EXIST.code == errorCode) then --好友不存在
        CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_NOT_EXIST, nil, nil, nil)
      else
        CanonMessageBox:showCommUnHandleErrorBox(errorCode)
      end
    end
    
    local params = {friendUid = self.friendUid}
    local challengeFriendRequest = ChallengeFriendRequest.new(params, rpc.SendingPriority.kHigh)
    challengeFriendRequest:addEventListener(RequestNotifyEnum.ChallengeFriendSucceed, onChallengeFriendSucc)
    challengeFriendRequest:addEventListener(RequestNotifyEnum.ChallengeFriendFailed, onChallengeFriendFail)
    challengeFriendRequest:start()
  end
  local btnChallenge = Button:create(opArea:getChildByName("friend_btn_friend_ChallengeBtn"))
  btnChallenge:addEventListener(Events.kStart, onChallenge, self)

  --一键切磋
  local function loadFriendsData(data)
    self.lstSharkFriend = data.data.sharkFriends or {}
  end

  if not self.lstSharkFriend then 
    -- 获取好友列表
    local getFriendsRequest = GetFriendsRequest.new(nil, rpc.SendingPriority.kNormal)
    getFriendsRequest:addEventListener(RequestNotifyEnum.GetFriendsSucceed, loadFriendsData)
    getFriendsRequest:start()
  end

  local function onChallengeList()
    local function afterChallengeFriendListRequest()
      local fightFriendUids = {}
      for k,v in pairs (self.lstSharkFriend) do
        table.insert(fightFriendUids,v.friendUid)
      end
      DailyDataManager.setFightFriendUids(fightFriendUids)
      if self.tableList then 
        local currentOffset = self.tableList:getContentOffset().y
        self.tableList:reloadData()
        self.tableList:setContentOffset(ccp(0, currentOffset), false)
      end
    end
    local fightFriendUids = DailyDataManager.getFightFriendUids()
    local friendUids = {}
    for k,v in pairs(self.lstSharkFriend) do
      local challenged = false 
      for _,value in pairs(fightFriendUids) do 
        if v.friendUid == value then 
          challenged = true
          break
        end
      end
      if not challenged then 
        table.insert(friendUids,v.friendUid) 
      end
    end 
    ChallengeFriendListRequest.sendRequestDefalut(friendUids,afterChallengeFriendListRequest) 
  end
  local challengeListDisplay = self.panelUI:getChildByName("btn_friend_Akay")
  challengeListDisplay:getChildByName("txt"):getChildByName("txt"):setString(getTextByKey("friend_allChallenged"))
  local btChallengeList = Button:create(challengeListDisplay)
  btChallengeList:addEventListener(Events.kStart, onChallengeList, self)

  
  -- 删除好友
  local txtBtnDeleteFriend = opArea:getChildByName("friend_btn_friend_DeleteFriendBtn"):getChildByName("txt_friend_DeleteFriendBtn")
  local strBtnDeleteFriend = Localization:getInstance():getText("friend_DeleteFriendBtn")
  txtBtnDeleteFriend:setString(strBtnDeleteFriend)
  
  local function onDeleteFriend()
    local function deleteFriend()
      local function onDeleteFriendCallback(data)
        self:showOpResultTips(getTextByKey("friend_deleteFriendSuccess"))
        if(self.container.friendPanel) then
          self.container.friendPanel:deleteFriend(self.friendUid)
        end
        self:closePanel();
      end
      local params = {friendUid = self.friendUid}
      local deleteFriendRequest = DeleteFriendRequest.new(params, rpc.SendingPriority.kHigh)
      deleteFriendRequest:addEventListener(RequestNotifyEnum.DeleteFriendSucceed, onDeleteFriendCallback)
      deleteFriendRequest:start()
    end
    
    local strConfirmDelFriend = Localization:getInstance():getText("friend_confirmDeleteText")
    CanonMessageBox:Show(strConfirmDelFriend, ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, deleteFriend, nil)
  end
  local btnDeleteFriend = Button:create(opArea:getChildByName("friend_btn_friend_DeleteFriendBtn"))
  btnDeleteFriend:addEventListener(Events.kStart, onDeleteFriend, self)
end

function UserDetailPanel:initInviteReceivedOp()
  local opArea = self.panelUI:getChildByName("friend_btn_playerInfo_friend")
  opArea:setVisible(true)

  --非好友 不可见 一键切磋按钮
  self.panelUI:getChildByName("btn_friend_Akay"):setVisible(false)
  -- 接受
  local txtBtnAcceptInvite = opArea:getChildByName("friend_btn_friend_FormationBtn"):getChildByName("txt_friend_FormationBtn")
  local strBtnAccept = Localization:getInstance():getText("friend_AcceptBtn")
  txtBtnAcceptInvite:setString(strBtnAccept)
  
  local function onAcceptInvite()
    local function onAcceptInviteCallback(data)
      self:showOpResultTips(getTextByKey("friend_acceptRequestSuccess"))
      if(self.container.inviteReceivedPanel) then
        self.container.inviteReceivedPanel:acceptInvite(self.friendUid)
      end
      self:closePanel();
    end
    
    local function acceptInvitationFailed(error)
      local errorCode = tonumber(error.data)
      
      if(CommErrorCodes.FRIEND_LIST_FULL.code == errorCode) then --好友已满
        CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_LIST_FULL, nil, nil, nil)
      elseif(CommErrorCodes.FRIEND_RELATIONSHIP_EXIST.code == errorCode) then -- 已经是好友
        CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_RELATIONSHIP_EXIST, nil, nil, nil)
      elseif(CommErrorCodes.FRIEND_INVITATION_NOT_EXIST.code == errorCode) then -- 邀请已不存在
        CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_INVITATION_NOT_EXIST, nil, nil, nil)
      elseif(CommErrorCodes.FRIEND_SELF_LIST_FULL.code == errorCode) then -- 自己好友数达上限
        CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_SELF_LIST_FULL, nil, nil, nil)
      elseif(CommErrorCodes.FRIEND_ENEMY_LIST_FULL.code == errorCode) then -- 对方好友数达上限
        CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_ENEMY_LIST_FULL, nil, nil, nil)
      else
        CanonMessageBox:showCommUnHandleErrorBox(errorCode)
      end
    end
    
    local params = {friendUid = self.friendUid}
    local acceptInvitationRequest = AcceptInvitationRequest.new(params, rpc.SendingPriority.kHigh)
    acceptInvitationRequest:addEventListener(RequestNotifyEnum.AcceptInvitationSucceed, onAcceptInviteCallback)
    acceptInvitationRequest:addEventListener(RequestNotifyEnum.AcceptInvitationFailed, acceptInvitationFailed)
    acceptInvitationRequest:start()
  end
  local btnAcceptInvite = Button:create(opArea:getChildByName("friend_btn_friend_FormationBtn"))
  btnAcceptInvite:addEventListener(Events.kStart, onAcceptInvite, self)
  
  -- 拒绝
  local txtBtnRefuseInvite = opArea:getChildByName("friend_btn_friend_SendMessageBtn"):getChildByName("txt_friend_SendMessageBtn")
  local strBtnRefuse = Localization:getInstance():getText("friend_RefuseBtn")
  txtBtnRefuseInvite:setString(strBtnRefuse)
  
  local function onRefuseInvite()
    local function onRefuseInviteCallback(data)
      self:showOpResultTips(getTextByKey("friend_refuseRequest"))
      
      if(self.container.inviteReceivedPanel) then
        self.container.inviteReceivedPanel:refuseInvite(self.friendUid)
      end
      self:closePanel();
    end
    local params = {friendUid = self.friendUid}
    local refuseInvitationRequest = RefuseInvitationRequest.new(params, rpc.SendingPriority.kHigh)
    refuseInvitationRequest:addEventListener(RequestNotifyEnum.RefuseInvitationSucceed, onRefuseInviteCallback)
    refuseInvitationRequest:start()
  end
  local btnRefuseInvite = Button:create(opArea:getChildByName("friend_btn_friend_SendMessageBtn"))
  btnRefuseInvite:addEventListener(Events.kStart, onRefuseInvite, self)
  
  --查看队列
  local txtBtnFormation = opArea:getChildByName("friend_btn_friend_ChallengeBtn"):getChildByName("txt_friend_ChallengeBtn")
  local strBtnFormation = Localization:getInstance():getText("friend_FormationBtn")
  txtBtnFormation:setString(strBtnFormation)
  
  local function onFormation()
    params = {
      playerUid = self.friendUid,
    }
    local function onGetPlayerTeamInfoCallback( evt )
      local argv = {
      enterScene = self.container.curSceneEnum,
      returnScene = self.container.curSceneEnum,
      params = {
          playerUid = self.friendUid,
          playerTeamData = evt.data,
        },
      }
      self:closePanel()
      self.container:replaceScene( CardQueueScene, argv )
    end
	
    local getPlayerTeamInfoRequest = GetPlayerTeamInfoRequest.new(params, rpc.SendingPriority.kHigh)
    getPlayerTeamInfoRequest:addEventListener(RequestNotifyEnum.GetPlayerTeamInfoSucceed, onGetPlayerTeamInfoCallback)
    getPlayerTeamInfoRequest:start()
  end
  local btnFormation = Button:create(opArea:getChildByName("friend_btn_friend_ChallengeBtn"))
  btnFormation:addEventListener(Events.kStart, onFormation, self)
  
  -- 留言
  local txtBtnSendMessage = opArea:getChildByName("friend_btn_friend_DeleteFriendBtn"):getChildByName("txt_friend_DeleteFriendBtn")
  local strBtnSendMessage = Localization:getInstance():getText("friend_SendMessageBtn")
  txtBtnSendMessage:setString(strBtnSendMessage)
  
  local function onSendMessage()
    self:SendEmail()
  end
  local btnSendMessage = Button:create(opArea:getChildByName("friend_btn_friend_DeleteFriendBtn"))
  btnSendMessage:addEventListener(Events.kStart, onSendMessage, self)
end

function UserDetailPanel:initInviteSentOp()
  local opArea = self.panelUI:getChildByName("friend_btn_playerInfo_invitationReceived")
  opArea:setVisible(true)

  -- 取消申请
  local txtBtnCancelApply = opArea:getChildByName("friend_btn_playerInfo_invitationReceived_accept"):getChildByName("font")
  local strBtnCancel = Localization:getInstance():getText("friend_CancelBtn")
  txtBtnCancelApply:setString(strBtnCancel)
   
  local function onCancelInvite()
    local function onCancelInviteCallback(data)
      self:showOpResultTips(getTextByKey("friend_cancelRequestSuccess"))
      if(self.src and self.src == "FindFriendsPanel") then
        if(self.container.findFriendsPanel) then
          self.container.findFriendsPanel:cancelInvite(self.friendUid)
        end
      end
      
      if(self.container.inviteSentPanel) then
        self.container.inviteSentPanel:cancelInvite(self.friendUid)
      end
      self:closePanel();
    end
    local params = {friendUid = self.friendUid}
    local cancelInvitationRequest = CancelInvitationRequest.new(params, rpc.SendingPriority.kHigh)
    cancelInvitationRequest:addEventListener(RequestNotifyEnum.CancelInvitationSucceed, onCancelInviteCallback)
    cancelInvitationRequest:start()
  end
  local btnCancelApply = Button:create(opArea:getChildByName("friend_btn_playerInfo_invitationReceived_accept"))
  btnCancelApply:addEventListener(Events.kStart, onCancelInvite, self)
  
  --查看队列
  local txtBtnFormation = opArea:getChildByName("friend_btn_playerInfo_invitationReceived_refuse"):getChildByName("font")
  local strBtnFormation = Localization:getInstance():getText("friend_FormationBtn")
  txtBtnFormation:setString(strBtnFormation)
  
  local function onFormation()
    params = {
      playerUid = self.friendUid,
    }
    local function onGetPlayerTeamInfoCallback( evt )
      local argv = {
      enterScene = self.container.curSceneEnum,
      returnScene = self.container.curSceneEnum,
      params = {
          playerUid = self.friendUid,
          playerTeamData = evt.data,
        },
      }
      self:closePanel()
      self.container:replaceScene( CardQueueScene, argv )
    end
	
    local getPlayerTeamInfoRequest = GetPlayerTeamInfoRequest.new(params, rpc.SendingPriority.kHigh)
    getPlayerTeamInfoRequest:addEventListener(RequestNotifyEnum.GetPlayerTeamInfoSucceed, onGetPlayerTeamInfoCallback)
    getPlayerTeamInfoRequest:start()
  end
  local btnFormation = Button:create(opArea:getChildByName("friend_btn_playerInfo_invitationReceived_refuse"))
  btnFormation:addEventListener(Events.kStart, onFormation, self)
  
  -- 留言
  local txtBtnSendMessage = opArea:getChildByName("friend_btn_friend_SendMessageBtn"):getChildByName("txt_friend_SendMessageBtn")
  local strBtnSendMessage = Localization:getInstance():getText("friend_SendMessageBtn")
  txtBtnSendMessage:setString(strBtnSendMessage)
  
  local function onSendMessage()
    self:SendEmail()
  end
  local btnSendMessage = Button:create(opArea:getChildByName("friend_btn_friend_SendMessageBtn"))
  btnSendMessage:addEventListener(Events.kStart, onSendMessage, self)
end

function UserDetailPanel:initOpArea()
  if self.messageType==UserDetailPanel.MESSAGE_TYPE_PRIVATE_MESSAGE then
    self:initPrivateMessageOp()
  elseif(self.userDetail.friend) then
    self:initFriendOp()
  elseif(self.userDetail.invitationReceived) then
    self:initInviteReceivedOp()
  elseif(self.userDetail.invitationSent) then
    self:initInviteSentOp()
  else
    self:initDefaultOp()
  end
end

function UserDetailPanel:closePanel(evt)
  if self.Close_CallBack ~= nil then
    self.Close_CallBack() --用于解决QA提的BUG
  end
  PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
end
  
function UserDetailPanel:initCloseBtn()
  local function closePanel(evt)
    
    if self.Close_CallBack ~= nil then
      self.Close_CallBack() --用于解决QA提的BUG
    end
    
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
  end

  local btnPanelClose = Button:create(self.panelUI:getChildByName("common_btn_close"))
  btnPanelClose:addEventListener(Events.kStart, closePanel)
end

function UserDetailPanel:initChatBtn()
  if(self.userDetail.friend and (self.messageType~=UserDetailPanel.MESSAGE_TYPE_PRIVATE_MESSAGE)) then
    local function btnChatSelected(evt)
      if self.Close_CallBack ~= nil then
        self.Close_CallBack() --用于解决QA提的BUG
      end
      PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)

      local scene = Director:mgr():run()
      local chatPanel = UnionChatContainerPanel:create(scene, {tabType = TabEnum.chatToSpecial, specialName = self.userDetail.nickName})
      PopoutManager:sharedManager():popout(chatPanel, kPopoutDir.kScale, true, false , scene)
    end
    local btnPanelChat = Button:create(self.panelUI:getChildByName("btn_chat_friendInfo1"))
    btnPanelChat:addEventListener(Events.kStart, btnChatSelected)
  elseif (self.messageType~=UserDetailPanel.MESSAGE_TYPE_PRIVATE_MESSAGE and not self.userDetail.friend and self.userDetail.invitationReceived) then
    self.panelUI:getChildByName("btn_chat_friendInfo1"):setVisible(false)
  end
end

----------------------------------------
-- 请求玩家详情，并初始化界面数据
----------------------------------------
function UserDetailPanel:initData()
  local function onGetFriendDetailSucc(data)
    self.userDetail = data.data.sharkFriendDetail
    
    local builder = LayoutBuilder:createWithContentsOfFile(FriendManager.DICT.RESOURCE_FILE)
    local strSymbolName = ""
    if(self.userDetail.friend and (self.messageType~=UserDetailPanel.MESSAGE_TYPE_PRIVATE_MESSAGE)) or (self.messageType~=UserDetailPanel.MESSAGE_TYPE_PRIVATE_MESSAGE and not self.userDetail.friend and self.userDetail.invitationReceived) then
      strSymbolName = "friend_popup_friendInfo1"
    else
      strSymbolName = "friend_popup_friendInfo2"
    end
    self.panelUI = builder:build(strSymbolName)
    
    if(self.userDetail.friend and (self.messageType~=UserDetailPanel.MESSAGE_TYPE_PRIVATE_MESSAGE)) or (self.messageType~=UserDetailPanel.MESSAGE_TYPE_PRIVATE_MESSAGE and not self.userDetail.friend and self.userDetail.invitationReceived) then
      self.panelUI:getChildByName("friend_btn_playerInfo_friend"):setVisible(false)
    else
      self.panelUI:getChildByName("friend_btn_playerInfo_default"):setVisible(false)
      self.panelUI:getChildByName("friend_btn_playerInfo_invitationReceived"):setVisible(false)
      self.panelUI:getChildByName("friend_btn_playerInfo_invitationSent"):setVisible(false)
    end
    
    self:initFriendInfo()
    self:initOpArea()
    self:initCloseBtn()
    self:initChatBtn()
    
    self:addChild(self.panelUI)
  end
  
  local function onGetFriendDetailFail(err)
    local errorCode = tonumber(err.data)
    
    if (errorCode == CommErrorCodes.USER_NOT_EXIST.code) then
      local argv = {
        enterScene = UserDetailPanel,
        returnScene = MainMenuScene,
        params = {
          tagIndex = self.tagIndex,
          tableOffset = self.tableOffset,
          deletedUid = self.friendUid
        }
      }
      self.container:replaceScene(argv.returnScene, argv)
    else
      CanonMessageBox:showCommUnHandleErrorBox(errorCode)
    end
  end

  local params = {friendUid = self.friendUid}
  local getFriendDetailRequest = GetFriendDetailRequest.new(params, rpc.SendingPriority.kHigh)
  getFriendDetailRequest:addEventListener(RequestNotifyEnum.GetFriendDetailSucceed, onGetFriendDetailSucc)
  getFriendDetailRequest:addEventListener(RequestNotifyEnum.GetFriendDetailFailed, onGetFriendDetailFail)
  getFriendDetailRequest:start()
end

----------------------------------------
-- 场景初始化
----------------------------------------
function UserDetailPanel:initLayer()  
  UserDetailPanel.super.initLayer(self)
  self:initData()
end