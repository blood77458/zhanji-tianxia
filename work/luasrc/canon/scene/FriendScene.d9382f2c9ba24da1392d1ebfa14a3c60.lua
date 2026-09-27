--------------------------------------------------------------------------------
-- FriendScene.lua - 我的好友界面： 获取待审核及已发送邀请数据
-- author: xiaojie.bai & fangzhou.long
-- date: 2013-08-08 21:00
--------------------------------------------------------------------------------
require "canon.models.FriendManager"

require "canon.panel.MyFriendsPanel"
require "canon.panel.InviteSentPanel"
require "canon.panel.InviteReceivedPanel"
require "canon.panel.FindFriendsPanel"

require "canon.request.GetFriendsRequest"
require "canon.request.GetReviewFriendsRequest"
require "canon.request.GetInvitationFriendsRequest"

require "canon.data.MetaManager"

FriendScene = class(BaseUIScene)

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local lstFriend = nil
local lstInviteReceived = nil
local lstInviteSent = nil
local receivedEnergy = nil
local friendDatas = {
    lstFriend={},
    receivedEnergy = nil,
    lstInviteReceived={},
    lstInviteSent={}
  }

function FriendScene:ctor()
  self.title = Localization:getInstance():getText("friend_Title")
  self.curSceneEnum = SceneEnum.FriendScene
  self.argv = nil
  
  self.friendTag = nil
  self.inviteReceivedTag = nil
  self.inviteSentTag = nil
  
  self.panel = nil
  self.friendTitle = nil
  
  self.friendPanel = nil
  self.inviteReceivedPanel = nil
  self.inviteSentPanel = nil
  self.findFriendsPanel = nil
end

function FriendScene:create(argv)
  local scene = FriendScene.new()
  
  if(argv) then
    self.argv = argv
  else
    self.argv = {enterScene = nil, returnScene = nil, params = {}}
  end
  
  self.friendSystemConfig = MetaManager.getGameSettingConfig().friendSystem -- 好友系统配置
  
  scene:initScene()
  return scene
end

----------------------------------------
-- 返回按钮
----------------------------------------
function FriendScene:back()
  self:replaceScene(MainMenuScene)
end

function FriendScene:setTableViewsEnabledInner(v)
  if not self.friendTitle or not self.panel or not self.panel.table then
    return
  end
  self.friendTitle:setTouchEnabled(v)
  self.panel:setTouchEnabled(v)
  self.panel.table:setTouchEnabled(v)
end

function FriendScene:setReceivedEnergy(enery) 
  receivedEnergy = enery
end

----------------------------------------
-- 设置等待审核tag的条数
----------------------------------------
function FriendScene:setReceivedTagNum(num)
  local tipReceivedTag = self.friendTitle:getChildByName("friend_tips_friend_RequestReceivedTag")
  local tipReceivedTagNum = self.friendTitle:getChildByName("friend_tips_friend_RequestReceivedTag_num")
  if(num == 0) then 
    tipReceivedTagNum:setVisible(false)
    tipReceivedTag:setVisible(false)
  else
    tipReceivedTagNum:setVisible(true)
    tipReceivedTag:setVisible(true)
    tipReceivedTagNum:getChildByName("font"):setString(num)
  end
end

----------------------------------------
-- 设置我的申请tag的条数
----------------------------------------
function FriendScene:setSentTagNum(num)
  local tipSentTag = self.friendTitle:getChildByName("friend_tips_friend_RequestSentTag")
  local tipSentTagNum = self.friendTitle:getChildByName("friend_tips_friend_RequestSentTag_num")

  if(num == 0) then 
    tipSentTagNum:setVisible(false)
    tipSentTag:setVisible(false)
  else
    tipSentTagNum:setVisible(true)
    tipSentTag:setVisible(true)
    tipSentTagNum:getChildByName("font"):setString(num)
  end
end

----------------------------------------
-- 从服务器或
----------------------------------------
function FriendScene:initData()
  self.exit_animation_duration = 0.5

 -- self:setParamData({})
  local flag = 3
  local function updateFlag()
    flag = flag - 1
    if(flag == 0) then
      friendDatas = {
        lstFriend = lstFriend,
        receivedEnergy = receivedEnergy,
        lstInviteReceived = lstInviteReceived,
        lstInviteSent = lstInviteSent,
      }

      self:initUI()
    end
  end
  local function loadFriendsData(data)
    lstFriend = data.data.sharkFriends or {}
    receivedEnergy = data.data.receivedEnergy or 0
    updateFlag()
  end
  local function loadInviteReceivedData(data)
    lstInviteReceived = data.data.sharkFriends or {}
    updateFlag()
  end
  local function loadInviteSentData(data)
    lstInviteSent = data.data.sharkFriends or {}
    updateFlag()
  end

  -- 获取好友列表
  local getFriendsRequest = GetFriendsRequest.new(nil, rpc.SendingPriority.kNormal)
  getFriendsRequest:addEventListener(RequestNotifyEnum.GetFriendsSucceed, loadFriendsData)
  getFriendsRequest:start()
  -- 获取待审核列表
  local getReviewFriendsRequest = GetReviewFriendsRequest.new(nil, rpc.SendingPriority.kNormal)
  getReviewFriendsRequest:addEventListener(RequestNotifyEnum.GetReviewFriendsSucceed, loadInviteReceivedData)
  getReviewFriendsRequest:start()
  -- 获取已发送请求列表
  local getInvitationFriendsRequest = GetInvitationFriendsRequest.new(nil, rpc.SendingPriority.kHigh)
  getInvitationFriendsRequest:addEventListener(RequestNotifyEnum.GetInvitationFriendsSucceed, loadInviteSentData)
  getInvitationFriendsRequest:start()
end

function FriendScene:createMyFriendsPanel()
  local params = {
      lstFriend = lstFriend,
      receivedEnergy = receivedEnergy,
      friendSystemConfig = self.friendSystemConfig
    }
  self.friendPanel = MyFriendsPanel:create(self, params)
  self.contentLayer:addChild(self.friendPanel)
end

function FriendScene:createInvitationReceivedPanel()
  local params = {
      lstInviteReceived = lstInviteReceived
    }
  self.inviteReceivedPanel = InviteReceivedPanel:create(self, params)
  self.contentLayer:addChild(self.inviteReceivedPanel)
end

function FriendScene:createInvitationSentPanel()
  local params = {
      lstInviteSent = lstInviteSent
    }
  self.inviteSentPanel = InviteSentPanel:create(self, params)
  self.contentLayer:addChild(self.inviteSentPanel)
end

function FriendScene:createFindFriendsPanel() --没有初始化table数据，切换tag时refreshTable
  local params = {
      lstFriend = lstFriend,
      lstInviteSent = lstInviteSent,
      friendSystemConfig = self.friendSystemConfig
    }
  self.findFriendsPanel = FindFriendsPanel:create(self, params)
  self.contentLayer:addChild(self.findFriendsPanel)
end

function FriendScene:initUI()
  ----------------------------------------
  -- 面板隐藏: 面板和table的visible和touchEnable设置
  ----------------------------------------
  local function setPanelVisible(panel, visible)
    panel:setVisible(visible)
    panel:setTouchEnabled(visible)
    if(panel.table) then
      panel.table:setTouchEnabled(visible)
    end
  end
  
  ----------------------------------------
  -- Button选中效果切换
  ----------------------------------------
  local function setButtonSelected(buttonSb, selected)
    buttonSb:getChildByName("btn"):setVisible(selected)
    buttonSb:getChildByName("disable"):setVisible(not selected)
  end
  
  ----------------------------------------
  -- 切换菜单按钮响应
  ----------------------------------------
  local function switchMenuTag(index)
    if(self.tagIndex and self.tagIndex == index) then
      return nil
    end
     
    local prevIndex = self.tagIndex
    local prevPanel = self.panel
    
    self.tagIndex = index
    
    setButtonSelected(self.friendTag, false)
    setButtonSelected(self.inviteReceivedTag, false)
    setButtonSelected(self.inviteSentTag, false)
    setButtonSelected(self.findFriendsTag, false)
    
    if(self.friendPanel and (not index or index ~= 1) and (not prevIndex or prevIndex ~= 1)) then
      setPanelVisible(self.friendPanel, false)
    end
    if(self.inviteReceivedPanel and (not index or index ~= 2) and (not prevIndex or prevIndex ~= 2)) then
      setPanelVisible(self.inviteReceivedPanel, false)
    end
    if(self.inviteSentPanel and (not index or index ~= 3) and (not prevIndex or prevIndex ~= 3)) then
      setPanelVisible(self.inviteSentPanel, false)
    end
    if(self.findFriendsPanel and (not index or index ~= 4) and (not prevIndex or prevIndex ~= 4)) then
      setPanelVisible(self.findFriendsPanel, false)
    end
    
    local selectTag = nil
    if(index == 1) then
      if(not self.friendPanel) then
        self:createMyFriendsPanel()
      end
      selectTag = self.friendTag
      self.panel = self.friendPanel
    elseif(index == 2) then
      if(not self.inviteReceivedPanel) then
        self:createInvitationReceivedPanel()
      end
      selectTag = self.inviteReceivedTag
      self.panel = self.inviteReceivedPanel
    elseif(index == 3) then
      if(not self.inviteSentPanel) then
        self:createInvitationSentPanel()
      end
      selectTag = self.inviteSentTag
      self.panel = self.inviteSentPanel
    elseif(index == 4) then
      if(not self.findFriendsPanel) then
        self:createFindFriendsPanel()
      else
        self.findFriendsPanel:refreshTable()
      end
      selectTag = self.findFriendsTag
      self.panel = self.findFriendsPanel
    else 
      self.tagIndex = 1
      if(not self.friendPanel) then
        self:createMyFriendsPanel()
      end
      selectTag = self.friendTag
      self.panel = self.friendPanel
    end
    
    if(prevPanel) then
      local function exitPanelCallback()
        setPanelVisible(prevPanel, false)
        
        setPanelVisible(self.panel, true)
        setButtonSelected(selectTag, true)
        self.panel:enterPanelAction()
      end
      
      prevPanel:exitPanelAction(exitPanelCallback)
    else
      setPanelVisible(self.panel, true)
      setButtonSelected(selectTag, true)
      self.panel:enterPanelAction()
    end
  end
  
  -- Tab
  local function clickFriendListTag(evt)
    if(self.tagIndex ~= 1) then
      switchMenuTag(1)
    end
  end
  
  local function clickRequestReceivedTag(evt)
    if(self.tagIndex ~= 2) then
      switchMenuTag(2)
    end
  end
  
  local function clickRequestSentTag(evt)
    if(self.tagIndex ~= 3) then
      switchMenuTag(3)
    end
  end
  
  local function clickFindFriendsTag(evt)
    if(self.tagIndex ~= 4) then
      switchMenuTag(4)
    end
  end
  
  if(self.isDisposed) then --异步加载，场景已切换销毁
    return nil
  end
  
  local strBtnMyFriendTag = Localization:getInstance():getText("friend_FriendListTag")
  local strBtnRequestReceivedTag = Localization:getInstance():getText("friend_RequestReceivedTag")
  local strBtnRequestSentTag = Localization:getInstance():getText("friend_RequestSentTag")
  
  self.friendTag = self.friendTitle:getChildByName("friend_btn_friend_FriendListTag")
  local btnBtnFriendListTag = Button:create(self.friendTag)
  btnBtnFriendListTag:addEventListener(Events.kStart, clickFriendListTag, self)
  local txtFriendListTag = self.friendTag:getChildByName("txt_friend_FriendListTag")
  txtFriendListTag:setString(strBtnMyFriendTag);
  
  self.inviteReceivedTag = self.friendTitle:getChildByName("friend_btn_friend_RequestReceivedTag")
  local btnBtnRequestReceivedTag = Button:create(self.inviteReceivedTag)
  btnBtnRequestReceivedTag:addEventListener(Events.kStart, clickRequestReceivedTag, self)
  local txtRequestReceivedTag = self.inviteReceivedTag:getChildByName("txt_friend_RequestReceivedTag")
  txtRequestReceivedTag:setString(strBtnRequestReceivedTag);
  
  self.inviteSentTag = self.friendTitle:getChildByName("friend_btn_friend_RequestSentTag")
  local btnBtnRequestSentTag = Button:create(self.inviteSentTag)
  btnBtnRequestSentTag:addEventListener(Events.kStart, clickRequestSentTag, self)
  local txtRequestSentTag = self.inviteSentTag:getChildByName("txt_friend_RequestSentTag")
  txtRequestSentTag:setString(strBtnRequestSentTag);
  
  self.findFriendsTag = self.friendTitle:getChildByName("friend_btn_friend_FindFriendTag")
  local btnBtnFindFriendTag = Button:create(self.findFriendsTag)
  btnBtnFindFriendTag:addEventListener(Events.kStart, clickFindFriendsTag, self)
  local txtFindFriendTag = self.findFriendsTag:getChildByName("txt_friend_FindFriendTag")
  local strBtnRequestSentTag = getTextByKey("friend_FindMoreTab")
  txtFindFriendTag:setString(strBtnRequestSentTag);
  
  local friendRequestReceivedNum = (lstInviteReceived and #lstInviteReceived) or 0
  local friendRequestSentNum = (lstInviteSent and #lstInviteSent) or 0
  self:setReceivedTagNum(friendRequestReceivedNum)
  self:setSentTagNum(friendRequestSentNum)
  
  self.friendTitle:setVisible(true)
  
  -- 创建所有panel,通过tag切换
  self:createMyFriendsPanel()
  self:createInvitationReceivedPanel()
  self:createInvitationSentPanel()
  self:createFindFriendsPanel()
  
  switchMenuTag(self.tagIndex)
end

----------------------------------------
-- 场景初始化
----------------------------------------
function FriendScene:onInit()
  BaseUIScene.initBackGround(self)
  
  --新UI加黑底
  local colorLayer = LayerColor:create()
  colorLayer:setOpacity(kDarkOpacity)
  colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(colorLayer)

  -- init ui
  local builder = LayoutBuilder:createWithContentsOfFile(FriendManager.DICT.RESOURCE_FILE)
  builder.useArtLabelTTF = true
  self.friendTitle = builder:build("friend_title")
  
  self.friendTitle:setVisible(false)
  self:addChild(self.friendTitle)
  --tips_big2
  -- self.friendTitle:getChildByName("tips_big"):setVisible(false)
  -- self.friendTitle:getChildByName("tips_big2"):setVisible(false)
  -- content layer
  self.contentLayer = Layer:create()
  self.contentLayer:setContentSize(CCSizeMake(1, 1))
  self:addChild(self.contentLayer)
  
  BaseUIScene.onInit(self)
end

----------------------------------------
-- 进入场景动画,被父类onInit()方法调用
----------------------------------------
function FriendScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

----------------------------------------
-- 进入场景动画的预处理
----------------------------------------
function FriendScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

----------------------------------------
-- 进入场景动画
----------------------------------------
function FriendScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  local function getCCSequence()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    
    return CCSequence:create(arr)
  end
  local function getCCSequenceNoAction()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
    
    return CCSequence:create(arr)
  end
  self.contentLayer:setPositionX(self.contentLayer:getPositionX() - visibleSize.width)
  self.contentLayer:runAction(getCCSequence())
  
  self.friendTitle:setPositionX(self.friendTitle:getPositionX() - visibleSize.width)
  self.friendTitle:runAction(getCCSequenceNoAction())
end

----------------------------------------
-- 进入场景动画的后处理
----------------------------------------
function FriendScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  self:initData()
end

----------------------------------------
-- 场景切换时，被父类的replaceScene调用
----------------------------------------
function FriendScene:doExitAnimation()
   self:preExitAnimation()
   self:startExitAnimation()
end

----------------------------------------
-- 退出场景动画的预处理
----------------------------------------
function FriendScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

----------------------------------------
-- 退出场景的动画
----------------------------------------
function FriendScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  
  local function exitActionFinished()
    self:nodeAnimationFinished()
  end
  
  local function getCCSequence()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(exitActionFinished))
    
    return CCSequence:create(arr)
  end
  local function getCCSequenceNoAction()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(exitActionFinished))
    
    return CCSequence:create(arr)
  end
  self.contentLayer:runAction(getCCSequence())
  
  self.friendTitle:runAction(getCCSequenceNoAction())
  if(self.panel) then
    self.panel:exitPanelAction()
  end
end

----------------------------------------
-- 退出场景动画的后处理
----------------------------------------
function FriendScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function FriendScene:dispose()
  FriendScene.super.dispose(self)
end