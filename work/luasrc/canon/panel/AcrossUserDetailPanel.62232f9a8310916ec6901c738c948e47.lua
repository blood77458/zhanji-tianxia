require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
--AcrossUserDetailPanel
--

AcrossUserDetailPanel = class(Layer)

function AcrossUserDetailPanel:ctor()
  self.container = nil
  self.params = nil
end

function AcrossUserDetailPanel:create(container, params)
  local panel = AcrossUserDetailPanel.new()
  panel.container = container
  panel.params = params
  panel:initLayer()
  return panel
end

function AcrossUserDetailPanel:initLayer()  
  AcrossUserDetailPanel.super.initLayer(self)
  
  local function onGetFriendDetailSucc(event)
    print(table.tostring(event.data))
    local builder = LayoutBuilder:createWithContentsOfFile("scene/across_fight.json")
    builder.useArtLabelTTF = true
    self.uiView = builder:build("popup_quiz_2")
    self:addChild(self.uiView)
    
    local function closeBtnSelected(evt)
      if self.params.closeCallback ~= nil then
        self.params.closeCallback()
      end
      PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
    end
    local closeBtnDisplay = self.uiView:getChildByName("login_btn_close")
    local closeBtn = Button:create(closeBtnDisplay)
    closeBtn:addEventListener(Events.kStart, closeBtnSelected, self)
    
    self.uiView:getChildByName("txt_across_fight_16"):getChildByName("txt"):setString(getTextByKey("cross_guess_gamer"))
    self.uiView:getChildByName("txt_across_fight_15"):getChildByName("txt"):setString(event.data.sharkFriendDetail.nickName)
    local levelLabel = self.uiView:getChildByName("txt_across_fight_20"):getChildByName("txt")
    levelLabel:setString(tostring(event.data.sharkFriendDetail.level))
    levelLabel:setColor(ccc3(255,255,0))
    levelLabel:setAroundColor(ccc3(103,37,37))
    self.uiView:getChildByName("txt_across_fight_17"):getChildByName("txt"):setString(getTextByKey("cross_guess_fight"))
    self.uiView:getChildByName("txt_across_fight_21"):getChildByName("txt"):setString(tostring(event.data.sharkFriendDetail.fightCapacity))
    self.uiView:getChildByName("txt_across_fight_18"):getChildByName("txt"):setString(getTextByKey("cross_look_area"))
    self.uiView:getChildByName("txt_across_fight_17"):getChildByName("txt"):setString(getTextByKey("crossArena_battleCapacity"))
    local serverNumber = tonumber(string.sub(tostring(event.data.sharkFriendDetail.friendUid), -4, -1))
    if __IOS then
      self.uiView:getChildByName("txt_across_fight_1"):getChildByName("txt"):setString(Localization:getInstance():getText("cross_list_text", {num1 = serverNumber}))
    else
      self.uiView:getChildByName("txt_across_fight_1"):getChildByName("txt"):setString(Localization:getInstance():getText("cross_list_android", {num1 = serverNumber}))
    end
    
    local cardFrameSb = self.uiView:getChildByName("acrossfight_frame_card")
    cardFrameSb:setVisible(false)
    local canonCard = getHeadIconCanonCardByMetaId(event.data.sharkFriendDetail.mainCardMetaId)
    ViewControlUtil.adjustItemByFrame(canonCard, cardFrameSb)
    canonCard:setScale(1)
    canonCard:setZOrder(10001)
    self.uiView:addChild(canonCard)
    
    local function viewBtnSelected(event)
      local params = {
        playerUid = self.params.uid,
      }
      local function onGetPlayerTeamInfoCallback( evt )
        local argv = {
        enterScene = self.container.curSceneEnum,
        returnScene = self.container.curSceneEnum,
        params = {
            playerUid = self.params.uid,
            playerTeamData = evt.data,
          },
        }
        closeBtnSelected()
        self.container:replaceScene( CardQueueScene, argv )
      end
      local getPlayerTeamInfoRequest = GetPlayerTeamInfoRequest.new(params, rpc.SendingPriority.kHigh)
      getPlayerTeamInfoRequest:addEventListener(RequestNotifyEnum.GetPlayerTeamInfoSucceed, onGetPlayerTeamInfoCallback)
      getPlayerTeamInfoRequest:start()
    end
    local viewBtnDisplay = self.uiView:getChildByName("btn_queue_view")
    viewBtnDisplay:getChildByName("txt"):getChildByName("txt"):setString(getTextByKey("cross_look_team"))
    local viewBtn = Button:create(viewBtnDisplay)
    viewBtn:addEventListener(Events.kStart, viewBtnSelected, self)
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

  local params = {friendUid = self.params.uid}
  local getFriendDetailRequest = GetFriendDetailRequest.new(params, rpc.SendingPriority.kHigh)
  getFriendDetailRequest:addEventListener(RequestNotifyEnum.GetFriendDetailSucceed, onGetFriendDetailSucc)
  getFriendDetailRequest:addEventListener(RequestNotifyEnum.GetFriendDetailFailed, onGetFriendDetailFail)
  getFriendDetailRequest:start()
end
