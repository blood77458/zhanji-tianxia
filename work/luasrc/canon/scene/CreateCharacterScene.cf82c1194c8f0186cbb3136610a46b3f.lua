require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.scene.MainMenuScene"
require "canon.scene.DialogOnceScene"
require "canon.data.MetaManager"
require "canon.request.CommErrorCodes"
require "canon.luajava.CanonEnvInjector"
require "canon.manager.MaintenanceManager"
require "canon.request.GeneNicknameRequest"
require "canon.request.GetAchievementsRequest"
require "canon.manager.TCPManager"

CreateCharacterScene = class(Scene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function CreateCharacterScene:ctor()
	self.ui = nil
    self.character_name = nil
    --self.invite_code = nil
    self.loading = nil
    self.title = "createCharacter"
end

function CreateCharacterScene:create()
  local s = CreateCharacterScene.new()
  s:initScene()
  return s
end

function CreateCharacterScene:back()
    self:replaceScene(LoginScene)
end

function CreateCharacterScene:setTableViewsEnabled(v)
	self.ui:setTouchEnabled(v)
	self.character_name.refCocosObj:setTouchEnabled(v)
	--self.invite_code.refCocosObj:setTouchEnabled(v)
end

function CreateCharacterScene:onInit()
  local card = Sprite:create("card/card/yuji_5/full.png")
  card:setScale(1.5)
  card:setPosition(ccp(400, 750))

  if not isInAppleReview() then
    self:addChild(card)
  end

	local builder = LayoutBuilder:createWithContentsOfFile("scene/login_new.json")
	self.ui = builder:build("login_newCharacter_new")
   self.ui:getChildByName("login_new_bubbles"):setRotation(-15)
    --输入角色名
    local input_character_size = self.ui:getChildByName("q_solid_gray9_panel_up"):getBounds().size   
    local input_character_pos = self.ui:getChildByName("q_solid_gray9_panel_up"):getPosition()
    local input_sprite = Scale9Sprite:create("common/button.png")
    self.character_name = TextInput:create(CCSizeMake(input_character_size.width,input_character_size.height), input_sprite)
    self.character_name:setPosition(ccp(input_character_pos.x,input_character_pos.y))
    self.character_name:setReturnType(kKeyboardReturnTypeDone)
    self.sbTxtNickName = self.ui:getChildByName("txt_getname")
    self.txtNickName = self.sbTxtNickName:getChildByName("txt")
    self.txtNickName:setString("")
    
    --输入邀请码
    --[[
    local input_character_size = self.ui:getChildByName("q_solid_gray9_panel_down"):getBounds().size   
    local input_character_pos = self.ui:getChildByName("q_solid_gray9_panel_down"):getPosition()
    local input_sprite = Scale9Sprite:create("common/button.png")
    self.invite_code = TextInput:create(CCSizeMake(input_character_size.width,input_character_size.height), input_sprite)
    self.invite_code:setPosition(ccp(input_character_pos.x,input_character_pos.y))
  --]]
    self.ui:getChildByName("q_solid_gray9_panel_up"):setVisible(false)
    --self.ui:getChildByName("q_solid_gray9_panel_down"):setVisible(false)
    
    local bt_rand = Button:create(self.ui:getChildByName("icon_griddle"))
    local bt_create = Button:create(self.ui:getChildByName("btn_newCharacter"))
	
    self.ui:getChildByName("txt_up"):getChildByName("txt"):setString(getTextByKey("login_characterName"))
    --self.ui:getChildByName("txt_down"):getChildByName("txt"):setString(getTextByKey("login_invitationCode"))
    --self.ui:getChildByName("txt_down"):setVisible(false)
    --self.ui:getChildByName("txt_nocode_info"):getChildByName("txt"):setString(getTextByKey("login_invitationCode_tips"))
    --self.ui:getChildByName("txt_nocode_info"):setVisible(false)
    self.ui:getChildByName("btn_newCharacter"):getChildByName("txt"):setString(getTextByKey("login_createCharacterBtn"))
    
    local function onInputBegan( evt )
      if __IOS then
        self.character_name:setText(self.txtNickName:getString())
        self.txtNickName:setVisible(false)
      end
    end

    local function onInputEnded( evt )
      if __IOS then
        self.character_name:setText("")
        self.txtNickName:setVisible(true)
      end
    end

    local function onInputCharacter( evt )
      local nickName = self.character_name:getText()
      self.txtNickName:setString(nickName)
    end
    local function onInputInviteCode( evt )
      --print(evt, evt.name, self.invite_code:getText())
    end
    local function onClickRandName(e)
      local function onGeneNicknameSucceed(data)
        print(table.tostring(data.data))
        local nickName = data.data.nickname
        
        self.txtNickName:setString(nickName)
        self.character_name:setText(nickName)
        if __IOS then
          self.character_name:setText("")
        end
      end
      local function onGeneNicknameFailed(error)
        local errorCode = tonumber(error.data)
        CanonMessageBox:showCommUnHandleErrorBox(errorCode)
      end
      
      local params = {}
      local geneNicknameRequest = GeneNicknameRequest.new(params, rpc.SendingPriority.kHigh)
      geneNicknameRequest:addEventListener(RequestNotifyEnum.GeneNicknameSucceed, onGeneNicknameSucceed)
      geneNicknameRequest:addEventListener(RequestNotifyEnum.GeneNicknameFailed, onGeneNicknameFailed)
      geneNicknameRequest:start()
    end
    local function onClickCreate(evt)      
      --输入校验
      local strNickName = self.txtNickName:getString()
      if strNickName == "" then
        CanonMessageBox.showText( ShowButtonType.ID_OK, getTextByKey("login_popup_nicknameIsNull") )
        return
      end
      local chinum,engnum = StringUtil.calcChineseEnglishNum(strNickName)
      if (chinum*2+engnum)>12 then
        local text = getTextByKey("login_popup_nicknameIsTooLong")
        CanonMessageBox.showText(
          ShowButtonType.ID_OK,
          text
        )
        return
      end    
        --创建用户并保存数据
        local function afterCreateUser(event)
          local uid = event.data.sharkUser.uid
          local serverId = event.data.sharkUser.serverId

          ------------he广告推广包 打6号点   by  zhiyong.cao
            he_log_info("===================================" .. uid .. "=++++++++++++++++++++++++++++++")
           if isPlatformAndroid() and localStorage.getSixPointIsExist() == "" then
            HeDCLog:getInstance():setUserID(tostring(uid))
          --    he_log_info("CanonEnvInjector:getHeChannelID()  " .. CanonEnvInjector:getHeChannelID())
          --    he_log_info("sendPromoteInfo uid :  " .. tostring(uid))
              DcManager.sendOfficialPromoteInfo(tostring(uid),CanonEnvInjector:getHeChannelID() , "he")
              localStorage.saveSixPoint()
            end

	if __IOS then
		PlatformMgr:getInstance():setUserId(uid)
		HeGameDefault:setUserId(tostring(uid))
	end

          DcManager.setUserId(uid)
          DcManager.initDCServerInfo(serverId)
          --localStorage:saveUserInfo(uid, event.data) 
          --设置消息推送的用户id
          if __ANDROID then
            CanonEnvInjector:setGspGameUserId(uid)
          end
          
          
            local function gameInitResponse( e )
              local request_times = 0
              local totalRequest = 0
              local function changeScene()
                local scene = DialogOnceScene:create( 1 )
                Director:sharedDirector():replaceScene( scene )
                TCPManager:sharedInstance():connectToServer()
              end
      				local function GetActivityOnOffConfigCallBack(e) --活动信息
      					MaintenanceManager.ActivityOnOffConfigData = e.data.maintenanceItem
      					request_times = request_times + 1
                          if request_times == totalRequest then
                              changeScene()
                          end 
      				end 
              --成就信息
              local function GetAchievementsCallBack(e)
                DataManager.setSharkAchievements(e.data.sharkAchievement)
                request_times = request_times + 1
                if request_times == totalRequest then
                    changeScene()
                end 
              end
              --禁言状态
              local function GetSpeakLimitStutasCallBack(e)
                local user = DataManager.getCurrUser()
                user.noChatEndSeconds = e.data.noChatEndSeconds
                DataManager.setCurrUser(user)
                request_times = request_times + 1
                if request_times == totalRequest then
                    changeScene()
                end 
              end 
      				--获取活动配置
      				local params = {}
      				local getActivityOnOffConfigRequest = GetActivityOnOffConfigRequest.new( nil, rpc.SendingPriority.kNormal )
      				getActivityOnOffConfigRequest:addEventListener( RequestNotifyEnum.GetActivityOnOffConfigSucceed, GetActivityOnOffConfigCallBack )
      				getActivityOnOffConfigRequest:start()
              totalRequest = totalRequest + 1
              --获取成就信息
              local getAchievementsRequest = GetAchievementsRequest.new( nil, rpc.SendingPriority.kNormal )
              getAchievementsRequest:addEventListener( RequestNotifyEnum.GetAchievementsSucceed, GetAchievementsCallBack )
              getAchievementsRequest:start()
              totalRequest = totalRequest + 1
              --获取是否禁言的状态
              SpeakLimitStutasRequest.sendRequest(nil , GetSpeakLimitStutasCallBack , nil)
              totalRequest = totalRequest + 1
            end
            local params = {}
            local request = GameInitRequest.new( params ,rpc.SendingPriority.kHigh )
            request:addEventListener( RequestNotifyEnum.GameInitSucceed, gameInitResponse )
            request:start()

          --[[
          local totalRequestTimes = 0
          local request_times = 0
          local function refreshLoading()
            request_times = request_times + 1
            print(request_times, totalRequestTimes)
            if request_times == totalRequestTimes then
              local scene = DialogOnceScene:create( 1 )
              print("redirect DialogOnceScene")
              Director:sharedDirector():replaceScene( scene )
            end
          end
          
          local function gameInitResponse( e )
            print(request_times, totalRequestTimes)
            refreshLoading()
          end
          local function GetEquipsCallBack(e) --装备信息
            print(request_times, totalRequestTimes)
            refreshLoading()
          end
          local function GetPropsCallBack(e) --道具信息
            print(request_times, totalRequestTimes)
            refreshLoading()                
          end    
          local function GetActivityOnOffConfigCallBack(e) --活动信息
            print(request_times, totalRequestTimes)
            MaintenanceManager.ActivityOnOffConfigData = e.data.maintenanceItem
            refreshLoading()
          end
          
          --gameInit
          local params = {serverId = DataManager.getServerid()}
          local gameInitRequest = GameInitRequest.new( params ,rpc.SendingPriority.kNormal )
          gameInitRequest:addEventListener( RequestNotifyEnum.GameInitSucceed, gameInitResponse )
          gameInitRequest:start()
          totalRequestTimes = totalRequestTimes + 1
          print(request_times, totalRequestTimes)
          
          --获取装备
          local getEquipsRequest = GetEquipsRequest.new( params, rpc.SendingPriority.kNormal )
          getEquipsRequest:addEventListener( RequestNotifyEnum.GetEquipsSucceed, GetEquipsCallBack )
          getEquipsRequest:start()
          totalRequestTimes = totalRequestTimes + 1
          print(request_times, totalRequestTimes)
          
          --获取道具
          local getPropsRequest = GetPropsRequest.new( params, rpc.SendingPriority.kNormal )
          getPropsRequest:addEventListener( RequestNotifyEnum.GetPropsSucceed, GetPropsCallBack )
          getPropsRequest:start()
          totalRequestTimes = totalRequestTimes + 1
          print(request_times, totalRequestTimes)
          
          --获取活动配置
          local getActivityOnOffConfigRequest = GetActivityOnOffConfigRequest.new( nil, rpc.SendingPriority.kHigh )
          getActivityOnOffConfigRequest:addEventListener( RequestNotifyEnum.GetActivityOnOffConfigSucceed, GetActivityOnOffConfigCallBack )
          getActivityOnOffConfigRequest:start()
          totalRequestTimes = totalRequestTimes + 1
          print(request_times, totalRequestTimes)
          
          --]]
        end
		
        local function onCreateError( err )
          --self.loading:removeFromParentAndCleanup(true)
          local errorCode = err.data
          if (errorCode == CommErrorCodes.NICKNAME_IS_NULL.code) then
            CanonMessageBox:showCommErrorBox(CommErrorCodes.NICKNAME_IS_NULL)
          elseif (errorCode == CommErrorCodes.NICKNAME_IS_INVALID.code) then
            CanonMessageBox:showCommErrorBox(CommErrorCodes.NICKNAME_IS_INVALID)
          elseif (errorCode == CommErrorCodes.NICKNAME_IS_TOOSHORT.code) then
            CanonMessageBox:showCommErrorBox(CommErrorCodes.NICKNAME_IS_TOOSHORT)
          elseif (errorCode == CommErrorCodes.NICKNAME_IS_TOOLONG.code) then
            CanonMessageBox:showCommErrorBox(CommErrorCodes.NICKNAME_IS_TOOLONG)
          elseif (errorCode == CommErrorCodes.NICKNAME_IS_EXIST.code) then
            CanonMessageBox:showCommErrorBox(CommErrorCodes.NICKNAME_IS_EXIST)
          elseif (errorCode == CommErrorCodes.INVITECODE_NOT_EXIST.code) then
            CanonMessageBox:showCommErrorBox(CommErrorCodes.INVITECODE_NOT_EXIST)
          elseif (errorCode == CommErrorCodes.NICKNAME_CONTAIN_SENSTIVEWORD.code) then
            CanonMessageBox:showCommErrorBox(CommErrorCodes.NICKNAME_CONTAIN_SENSTIVEWORD)
          elseif (errorCode == CommErrorCodes.CREATE_USER_ERROR.code) then
            CanonMessageBox:showCommErrorBox(CommErrorCodes.CREATE_USER_ERROR)
          else
            CanonMessageBox:showCommUnHandleErrorBox(errorCode)
          end
        end
        
        local params = {avatarId=1,nickName=strNickName,inviteCode=""}
        local request = CreateUserRequest.new(params, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.CreateUserSucceed, afterCreateUser)
        request:addEventListener(RequestNotifyEnum.CreateUserFailed, onCreateError)
        request:start()         
    end    

    self.character_name:addEventListener(kTextInputEvents.kChanged, onInputCharacter)
    self.character_name:addEventListener(kTextInputEvents.kBegan, onInputBegan)
    self.character_name:addEventListener(kTextInputEvents.kEnded, onInputEnded)
    self.character_name.refCocosObj:setInputFlag( -100 )
    self.sbTxtNickName:setZOrder(1001)
    
    --self.invite_code:addEventListener(kTextInputEvents.kChanged, onInputInviteCode)    
    bt_rand:addEventListener(Events.kStart,onClickRandName)
    bt_create:addEventListener(Events.kStart,onClickCreate)
	
    self.ui:addChild(self.character_name)
    --self.ui:addChild(self.invite_code)
    self:addChild(self.ui)
	--BaseUIScene.onInit(self)
end

function CreateCharacterScene:dispose()
  CreateCharacterScene.super.dispose(self)
end
