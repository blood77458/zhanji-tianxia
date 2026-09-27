--------------------------------------------------------------------------------
-- LoginScene.lua - 游戏登陆界面:快速登陆、选服、增加EnterForeground事件监听
--------------------------------------------------------------------------------

require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.MainMenuScene"
require "canon.scene.CreateCharacterScene"
require "canon.scene.BaseUIScene"
require "canon.request.LoginServerRequest"
require "canon.request.Communication"
require "canon.request.BaseRequest"
require "canon.request.localStorage"
require "canon.request.CreateUserRequest"
require "canon.request.GameInitRequest"
require "canon.request.GetGameMetaRequest"
require "canon.request.GetGachaBroadcastRequest"
require "canon.scene.GachaScene"
require "canon.scene.CardEvolveResultScene"
require "canon.panel.CardDescPanel"
require "canon.request.GetActivityOnOffConfigRequest"
require "canon.panel.CanonMessageBox"
require "canon.constants.GlobalConstants"
require "canon.luajava.CanonEnvInjector"
require "canon.data.ThirdPlatformLogin"
require "canon.data.ThirdPlatformLoginBackup"
require "canon.data.ThirdPlatformExit"
require "canon.luajava.UCSdkToCanon"
require "canon.luajava.ND91SdkToCanon"
require "canon.luajava.XiaomiSdkToCanon"
require "canon.luajava.Qihoo360SdkToCanon"
require "canon.luajava.DKSdkToCanon"
require "canon.luajava.WdjSdkToCanon"
require "canon.luajava.OppoSdkToCanon"
require "canon.luajava.YyhSdkToCanon"
require "canon.luajava.AnzhiSdkToCanon"
require "canon.luajava.VivoSdkToCanon"
require "canon.luajava.iBukaToCanon"
require "canon.luajava.YYBSdkToCanon"
require "canon.luaoc.i4SdkToCanon_ios"
require "canon.luaoc.HaimaSdkToCanon_ios"
require "canon.luaoc.KuaiyongSdkToCanon_ios"
require "canon.luaoc.TBSdkToCanon_ios"
require "canon.luajava.JinliSdkToCanon"
require "canon.luajava.JinshanSdkToCanon"
require "canon.luajava.MuwanSdkToCanon"
require "canon.luajava.JoloplaySdkToCanon"
require "canon.luajava.LenovoSdkToCanon"
require "canon.luajava.HuaweiSdkToCanon"
require "canon.luajava.GooglePlayToCanon"
require "canon.luajava.GspBridge"
require "canon.manager.MaintenanceManager"
require "canon.manager.SimpleMaintenanceManager"
require "canon.constants.MusicPathConstants"
require "canon.manager.AntiAddictionManager"
require "canon.data.MetaManager"

require "canon.utils.SystemInfoCall"
require "canon.panel.ServerSelectPanel"
require "canon.manager.TCPManager"
require "canon.models.LocalAccountManager"
require "canon.utils.FormatCheckUtil"
require "canon.data.AccountPlatformLogin"
require "canon.manager.SystemManager"
require "canon.request.GetAchievementsRequest"
require "canon.request.SpeakLimitStutasRequest"

require "canon.data.ServerDataSelect"
g_serverIds = {}
--[[
local hasLocalAccount = false
--判断本地文件是否保存有账号
local oldUserInfo = localStorage.getCurrentUser()
oldUserInfo = oldUserInfo:split(",")
if tonumber(oldUserInfo[1]) > 0 then
  hasLocalAccount = true
end
]]
function isBindFacebook()
	return false
	--return bindFacebook
end

LoginScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local serverListInfo = {}
local _instanceOfLoginScene = nil
function LoginScene:getInstance()
	if not _instanceOfLoginScene then
		_instanceOfLoginScene = LoginScene.new()
	end
	return _instanceOfLoginScene
end

function LoginScene:releaseInstance() 
  _instanceOfLoginScene = nil
end

function LoginScene:ctor()
  self.title = "login"
  
  self.mainUI = nil
  self.uid = "1"
  self.isNewbie = false
  self.conn = { connState = nil }

  self.loading = nil
  self.background = nil
  
  --存储系统信息
  self.systemInfo = nil
  
  --开始的时候请求，决定是绑定账号还是注册新账号
  self.isDeviceBindWithAccount = true
  --保存label的引用
  self.registerStr = nil
  self.usernameStr = nil

  --登录所用的用户名和密码
  self.account = nil
  self.password = nil

  --按钮
  self.usernameBtn = nil
  self.registerBtn = nil
  self.guestBtn = nil
  self.loginBtn = nil

  --修改ios服务器id
  self.enableServerOffset = false
  self.iosServerOffset = 0

  self:initConn()
end

function LoginScene:create(argv)
  local scene = LoginScene.new()
  scene:initScene()
  
  if(argv) then
    scene.argv = argv
  else 
    scene.argv = {enterScene = nil, returnScene = nil, params = {}}
  end
  
  _instanceOfLoginScene = scene
  return scene
end

function LoginScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function LoginScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function LoginScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.5, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function LoginScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function LoginScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function LoginScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function LoginScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
    self.mainUI = nil 
    self.conn:removeEventListener(CommunicationInitEvent.kComplete, initCommunicatonSuccess) 
    _instanceOfLoginScene = nil
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
  
  _instanceOfLoginScene = nil
end

function LoginScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function LoginScene:setIsNewbie(isNew)
    self.isNewbie = isNew
end

function LoginScene:loginGame()
  he_log_info("+++++++++++++++++++++++++++Login Log:loginGame++++++++++++++++++++++++++++++++")
  local connState = false
  if self.conn then
      connState = self.conn.connState
  end
  if connState and self.isNewbie == true then
    local function AllDataInit()
        local function New_User()
          --CCMessageBox("new user","Canon")
          DcManager.sendLoadingActivity(90, ((os.time() - g_startTime )*1000) )
          local scene = CreateCharacterScene:create()
          Director:sharedDirector():replaceScene(scene )
          if is91Android() then
            show91FloatButton(true)
          end
        end
        local function GetGameMetaCallBack(e) --游戏信息
          DataManager.GameMetaData = e.data
          DataManager.GameMetaData.cardPictureConfig.cardPictures = HeMemDataHolder:setString("cardPictures", table.serialize(DataManager.GameMetaData.cardPictureConfig.cardPictures))
          he_log_info(table.tostring(e.data))
          New_User()
        end
        --获取游戏配置信息
        local request = GetGameMetaRequest.new( nil, rpc.SendingPriority.kHigh )
        request:addEventListener( RequestNotifyEnum.GetGameMetaSucceed, GetGameMetaCallBack )
        request:start()
    end
    AllDataInit()
  else
    --if self.mainUI == nil then
    --    Director:sharedDirector():replaceScene(LoginScene:create())
    --    return
    --end
    --self.mainUI:setTouchEnabled(false)
    --self.loading = Sprite:create("loading.png")
    --self.loading:setScale(2)
    --self.loading:setPosition(ccp(visibleSize.width/2,visibleSize.height/2))
    --self:addChild(self.loading)
    local function gameInitResponse( e )
      local request_times = 0
      local totalRequest = 0
      
      local function refreshLoading()
        request_times = request_times + 1
        if request_times == totalRequest then
            --self.loading:setVisible(false)
            DcManager.sendLoadingActivity(80, ((os.time() - g_startTime )*1000) )
            local scene = MainMenuScene.create()
            Director:sharedDirector():replaceScene( scene )
            TCPManager:sharedInstance():connectToServer()
            if isUCAndroid() then
              --uc need pass user extend info
              submitExtendDataToUC("loginGameRole")
            end
        end
      end
      local function GetGameMetaCallBack(e) --游戏信息
        DataManager.GameMetaData = e.data
        DataManager.GameMetaData.cardPictureConfig.cardPictures = HeMemDataHolder:setString("cardPictures", table.serialize(DataManager.GameMetaData.cardPictureConfig.cardPictures))
        refreshLoading()
      end
      local function GetActivityOnOffConfigCallBack(e) --活动开关配置信息
        MaintenanceManager.ActivityOnOffConfigData = e.data.maintenanceItem
        refreshLoading()
      end 
      local function GetAchievementsCallBack(e)
        DataManager.setSharkAchievements(e.data.sharkAchievement)
        refreshLoading()
      end
      local function GetSpeakLimitStutasCallBack(e)
        local user = DataManager.getCurrUser()
        user.noChatEndSeconds = e.data.noChatEndSeconds
        DataManager.setCurrUser(user)
        refreshLoading()
      end
      --获取游戏配置信息
      local getGameMetaRequest = GetGameMetaRequest.new( nil, rpc.SendingPriority.kNormal )
      getGameMetaRequest:addEventListener( RequestNotifyEnum.GetGameMetaSucceed, GetGameMetaCallBack )
      getGameMetaRequest:start()
      totalRequest = totalRequest + 1
      --获取活动开关配置
      local params = {serverId = DataManager.getServerid()}
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

      --由于进队伍卡，所以提前加载进队伍资源
      LayoutBuilder:createWithContentsOfFile("scene/formation_new.json")
      LayoutBuilder:createWithContentsOfFile("scene/details_card.json")
    end
    -- 调用gameInit接口
    local gameInitRequest = GameInitRequest.new( nil ,rpc.SendingPriority.kHigh )
    gameInitRequest:addEventListener( RequestNotifyEnum.GameInitSucceed, gameInitResponse )
    gameInitRequest:start()
  end
end 

local accountReturnRewards = nil
function resetAccountReturnRewards()
	accountReturnRewards = nil
end

function getAccountReturnRewards()
--[[test data
	accountReturnRewards = {
		[1] = { amount = "14",exp = "0", id = 0, level = 0, itemType = 7, metaId = 400008},
		[2] = { amount = "13",exp = "0", id = 0, level = 0, itemType = 7, metaId = 400009},
		[3] = { amount = "12",exp = "0", id = 0, level = 0, itemType = 7, metaId = 400008},
		[4] = { amount = "11",exp = "0", id = 0, level = 0, itemType = 7, metaId = 400008},
	}
-- end]]
	return accountReturnRewards
end
function LoginScene:startLoginServer()
  --[[
  if not hasLocalAccount then
    local function closeCanonMessageBox()
      --PlistResMgr:getInstance():terminateProcess()
      os.exit()
    end
    CanonMessageBox:Show(getTextByKey("EC_COMMON_TXT"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    return
  end
  ]]
  local serverId = DataManager.getServerid()
  function afterLoginServer(event)
    LoginScene:getInstance().conn.connState = true

    local uid = event.data.uid
	accountReturnRewards = event.data.accountReturnRewards
    if uid == "1" then
        LoginScene:getInstance().isNewbie = true
    else 
        LoginScene:getInstance().isNewbie = false
       
	if __IOS then 
        	PlatformMgr:getInstance():setUserId(uid)
			HeDCLog:getInstance():setUserID(tostring(uid))
	end

        DcManager.setUserId(uid)
        DcManager.initDCServerInfo(serverId)
        --设置消息推送的用户id
        if __ANDROID then
          CanonEnvInjector:setGspGameUserId(uid)
        end
    end
    he_log_info("+++++++++++++++++++++++++++ Login Log:afterLoginServer--uid="..event.data.uid.."++++++++++++++++++++++++++++++++")
    for k,v in pairs(serverListInfo) do 
        if v.serverInfo.serverId == serverId then
            v.alreadyMixed = true
            localStorage.saveChoseServerInfo( v )
            break
        end 
    end
    DcManager.sendLoadingActivity(70, ((os.time() - g_startTime )*1000) )
    LoginScene:getInstance():loginGame()

    --增加游戏入口统一管理接口 by zheng.che
    SystemManager.mainStartup()
  end
  
  function loginServerFailed(error)
	he_log_info("+++++++++++++++++++++++++++ Login Log:login server error,serverId = "..DataManager.getServerid().."++++++++++++++++++++++++++++++++")
	local function closeCanonMessageBox()
	    Director:sharedDirector():replaceScene(LoginScene:create())
	end
	if error.data == 710053 then
	    --server full
	    local aContent = getTextByKey("login_serverFullCantLogin")
		LoginScene:getInstance().targetInfoPanel = CanonMessageBox:Show(aContent, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif error.data == 710052 then
	    --server id error
	    local aContent = getTextByKey("login_serverInquireError")
		LoginScene:getInstance().targetInfoPanel = CanonMessageBox:Show(aContent, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(error.data,nil,closeCanonMessageBox )
	end
  end
  
  local params = {serverId = serverId, accountId = getAccountId()}
  local request = LoginServerRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.LoginServerSucceed, afterLoginServer)
  request:addEventListener(RequestNotifyEnum.LoginServerFailed, loginServerFailed)
  request:start()
end

function LoginScene:initServerInfo()
	EventManager:sharedManager():initializeData()
	serverListInfo = {}
	
	local needLoadPrepardServer = true
	local function isWhiteAccountId(serverInfo)
	    --white accountIds
        local oldUserInfo = localStorage.getCurrentUser()
        oldUserInfo = oldUserInfo:split(",")
        local whiteIds = serverInfo.whiteAccountIds
        whiteIds = whiteIds:split(",")
        for wi,wv in pairs(whiteIds) do 
            if wv == oldUserInfo[1] then
                return true
            end
        end
	    return false
	end 
	
	local function judgeServerStatus(serverInfo)
	    local serverCurStatus = ServerStatusEnum.normal
        for i,serverStatus in ipairs(self.systemInfo.serverStatuses) do 
            if serverInfo.serverId == serverStatus.serverId then
                local serverBusyAmount = serverInfo.serverBusy
                local serverNormalAmount = serverInfo.serverNormal
                local serverCurAmount = serverStatus.amount
                
                if serverCurAmount >= serverBusyAmount then
                    serverCurStatus = ServerStatusEnum.full
                else
                    needLoadPrepardServer = false
                    if serverCurAmount >= serverNormalAmount then
                        serverCurStatus = ServerStatusEnum.crowd
                    else
                        if serverInfo.newServer then
                            serverCurStatus = ServerStatusEnum.new
                        else
                            serverCurStatus = ServerStatusEnum.normal
                        end
                    end
                end
                
                break
            end 
        end 
        return serverCurStatus
	end
	
    local function addServerOffset( serverInfo )
		if serverInfo.serverId < self.iosServerOffset then
			serverInfo.serverId = serverInfo.serverId + self.iosServerOffset
		end
    end

	if self.systemInfo then
      g_serverIds = {}
	    for k,runningServerInfo in ipairs(self.systemInfo.serverPartitionConfig.runningServers) do 
          g_serverIds[runningServerInfo.serverId] = runningServerInfo.serverName
	        local serverEnable = runningServerInfo.enable or isWhiteAccountId(runningServerInfo)
	        	        
	        local serverBegin = false
	        if runningServerInfo.beginTime == "0" or tonumber(runningServerInfo.beginTime) <= self.systemInfo.ts then
	            serverBegin = true
	        end 
	        if serverEnable and serverBegin then
	            local serverCurStatus = judgeServerStatus(runningServerInfo)
              if __IOS and self.enableServerOffset then 
                addServerOffset(runningServerInfo)
              end
	            local sInfo = {
	                            serverInfo = runningServerInfo,
	                            serverStatus = serverCurStatus,
                               }
				if isServerShow(runningServerInfo.serverId) then
					table.insert(serverListInfo,sInfo)
				end
	        end 
	    end 
	    
	    if needLoadPrepardServer then
	        for k,preparedServerInfo in ipairs(self.systemInfo.serverPartitionConfig.preparedServers) do 
	            local serverEnable = preparedServerInfo.enable or isWhiteAccountId(preparedServerInfo)
	            local serverCurStatus = judgeServerStatus(preparedServerInfo) 
	            if serverEnable and serverCurStatus ~= ServerStatusEnum.full then            
                  if __IOS and self.enableServerOffset then
                    addServerOffset(preparedServerInfo)
                  end
                    local sInfo = {
                                    serverInfo = preparedServerInfo,
                                    serverStatus = serverCurStatus,
                                   }
					if isServerShow(runningServerInfo.serverId) then
						table.insert(serverListInfo,sInfo)
					end
                    break -- only show one prepared server
	            end
	        end 
	    end 
	end
		
	--init last chose server info 
    local lastChoseServerId  = nil
	if serverListInfo[1] then
        lastChoseServerId = serverListInfo[1].serverInfo.serverId
	end
    
	local lastChoseServerInfo = localStorage.getLastChoseServerInfo() 
	if lastChoseServerInfo == "" then
	--[[
		if LoginScene.userDat ~= nil then
			local serInfo = serverListInfo[2]
			if serInfo then
				lastChoseServerId = serverListInfo[2].serverInfo.serverId
			end
		end
	--]]
	else
      if __IOS and not lastChoseServerInfo.alreadyMixed then
        addServerOffset(lastChoseServerInfo.serverInfo)
      end
      lastChoseServerInfo.alreadyMixed = true
      localStorage.saveChoseServerInfo( lastChoseServerInfo )
	    lastChoseServerId = lastChoseServerInfo.serverInfo.serverId
	end
	
	self:setChoseServerInfo(lastChoseServerId)
	
	DataManager.recordGameServerInfo(serverListInfo)
end

local newServerLabel = nil
local normalServerLabel = nil
local crowdServerLabel = nil
local fullServerLabel = nil

local serverAreaLabel = nil
local serverNameLabel = nil
local serverAreaLabelTxt = nil
local serverNameLabelTxt = nil
function LoginScene:initChoseServerUI()
    self.mainUI:getChildByName("login_txt_new"):getChildByName("txt"):setString(getTextByKey("login_serverNew"))
    self.mainUI:getChildByName("login_txt_normal"):getChildByName("txt"):setString(getTextByKey("login_serverNomal"))
    self.mainUI:getChildByName("login_txt_crowd"):getChildByName("txt"):setString(getTextByKey("login_serverBusy"))
    self.mainUI:getChildByName("txt_full"):getChildByName("txt"):setString(getTextByKey("login_serverFull"))
    
    newServerLabel = self.mainUI:getChildByName("login_txt_new")
    normalServerLabel = self.mainUI:getChildByName("login_txt_normal")
    crowdServerLabel = self.mainUI:getChildByName("login_txt_crowd")
    fullServerLabel = self.mainUI:getChildByName("txt_full")
    
    serverAreaLabel = self.mainUI:getChildByName("txt_server")
    serverNameLabel = self.mainUI:getChildByName("txt_server1")
    
    serverAreaLabelTxt = self.mainUI:getChildByName("txt_server"):getChildByName("txt")
    serverNameLabelTxt = self.mainUI:getChildByName("txt_server1"):getChildByName("txt")
    
    self:clearServerInfo()
end

function LoginScene:clearServerInfo()
    serverAreaLabel:setVisible(false)
    serverNameLabel:setVisible(false)
    newServerLabel:setVisible(false)
    normalServerLabel:setVisible(false)
    crowdServerLabel:setVisible(false)
    fullServerLabel:setVisible(false)
end 

function LoginScene:Terminate_RunningGuide()
  if _G.Global_Guide_Already then
    Terminate_New_User_Guide()
    Terminate_All_ShowDialogBoxes()
    _G.Global_Guide_Already = nil
  end
end

function LoginScene:setChoseServerInfo(serverId)
    if serverId then
        DataManager.setServerId(serverId)
        LoginScene:getInstance():clearServerInfo()
        for k,v in ipairs(serverListInfo) do 
             if v.serverInfo.serverId == serverId then
                if v.serverStatus == ServerStatusEnum.new then
                    newServerLabel:setVisible(true)
                elseif v.serverStatus == ServerStatusEnum.normal then
                    normalServerLabel:setVisible(true)
                elseif v.serverStatus == ServerStatusEnum.crowd then
                    crowdServerLabel:setVisible(true)
                elseif v.serverStatus == ServerStatusEnum.full then
                    fullServerLabel:setVisible(true)
                end
                serverAreaLabel:setVisible(true)
                serverNameLabel:setVisible(true)
                serverAreaLabelTxt:setString(getTextByKey("login_serverNo",{num=v.serverInfo.serverId}))
                serverNameLabelTxt:setString(v.serverInfo.serverName)
                break
            end
        end 
    end
end
function LoginScene:onInit()
  --触发清除数据流程 每次进入登陆界面时都调用 add by zheng.che @ 2015-1-26
  SystemManager.clearData()

  ClearWaitingCoroutine()
  Set_ShareData( "New_User_Guide_Running", 0)
  self:Terminate_RunningGuide() --如果正在运行新手引导，则要先将新手引导停止
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/login_new.json")
  builder.useArtLabelTTF = true
  self.mainUI = builder:build("login_fastlogin")
  ----
  -- 请求系统全局配置信息
  ----
  local function onSystemInfoCall(response)
    RequestLoadingBox:removeLoadingBox()
    if response.errorCode==0 and response.httpCode==200 then 
      self.systemInfo = amf3.decode(response.body)
      
      local ts = self.systemInfo.ts or os.time()
      _G.__g_utcDiffSeconds = os.difftime(ts, os.time())

      local serverMergeConfig = self.systemInfo.systemConf.serverMergeConfig
      if serverMergeConfig then
        if serverMergeConfig.enable and serverMergeConfig.gameDomain then
          DataManager.setGameDomain(self.systemInfo.systemConf.serverMergeConfig.gameDomain)
        end
        self.enableServerOffset = self.systemInfo.systemConf.serverMergeConfig.enable
        self.iosServerOffset = self.systemInfo.systemConf.serverMergeConfig.serverOffset
        setAccountMixed(serverMergeConfig.enable)
      end

  	  self:initServerInfo()
  	  self:setChoseServerInfo()

      if __IOS then
        --self.adBtn:setVisible(self.systemInfo.cleanVersion) --大陆不需要
        setInAppleReview(self.systemInfo.cleanVersion)
      elseif isDKAndroid()then
      	--setInAppleReview(true) --发提审版本时打开
      end

      if isOfficalAccountPlatform() then
        local function onGetDeviceAccount( result )
          self.isDeviceBindWithAccount = result
          if self.registerStr and result then
            self.registerStr:setString(getTextByKey("login_bound_title"))
          end
        end

        checkDeviceGuestAccount(onGetDeviceAccount)
      end
    else
      he_log_error("get gameSystemInfo meet error, response detail:")
      he_log_error(table.tostring(response))
      CanonMessageBox.showText(
        ShowButtonType.ID_OK,
        getTextByKey("popup_networkError"),
        nil,
        {
            text = getTextByKey("retry"),
            callbackFunc = function()
              RequestLoadingBox:createLoadingBox(false)
              RequestLoadingBox:showLoadingBox()
              SystemInfoCall.getData(onSystemInfoCall)
            end
        }
      )

    end
  end
  
  local scheduler = nil
  local function waitingGetServerInfoFunc()
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(scheduler)
    RequestLoadingBox:createLoadingBox(false)
    RequestLoadingBox:showLoadingBox()
    SystemInfoCall.getData(onSystemInfoCall)
  end 
  scheduler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(waitingGetServerInfoFunc,0.1,false)

                  

  
  local enableChoseServer = true
  local function loginServer()
	enableChoseServer = false
    CanonPlayEffect(MusicPathConstants.ButtonOK)
    if isUCAndroid() then
      loginUC(requestGetBoundMapping)
    elseif is91Android() then
      login91(requestGetBoundMapping)
    elseif isXiaomiAndroid() then
      loginXiaomi(requestGetBoundMapping)
    elseif is360Android() then
      login360(requestGetBoundMapping)
    elseif isDKAndroid() then
      loginDK(requestGetBoundMapping)
    elseif isWdjAndroid() then
      loginWdj(requestGetBoundMapping)  
    elseif isOppoAndroid() then
      loginOppo(requestGetBoundMapping)
    elseif isYyhAndroid() then
      loginYYH(requestGetBoundMapping)
    elseif isAnzhiAndroid() then
      loginAnzhi(requestGetBoundMapping)
    elseif isVivoAndroid() then
      loginVivo(requestGetBoundMapping)
    elseif isOfficalAccountPlatform() then
      guestLogin(accountGetBoundMapping)
    elseif isYYBAndroid() then
      loginQQ(requestGetBoundMapping)
    elseif isI4ios() then
      loginI4_ios(requestGetBoundMapping)  
    elseif isHaimaIos() then
      loginHaima_ios(requestGetBoundMapping)
    elseif isKuaiYongIos() then
      loginKuaiyong_ios(requestGetBoundMapping)
    elseif isTongbuIos() then
      loginTongbu_ios(requestGetBoundMapping)
    elseif isJinliAndroid() then
      loginJinli(requestGetBoundMapping)  
    elseif isJinshanAndroid() then
      loginJinshan(requestGetBoundMapping)
    elseif isJoloplayAndroid() then
      loginJoloplay(requestGetBoundMapping)
    elseif isHuaweiAndroid() then
      loginHuawei(requestGetBoundMapping)
    elseif isMuwanAndroid() then
      loginMuwan(requestGetBoundMapping)
	elseif isLenovoAndroid() then
	  loginLenovo(requestGetBoundMapping)
    else
      self:startLoginServer()
    end
  end
    
  local function onLoginClick( evt )
    if(not self.systemInfo) then
      he_log_warning("systemInfo not init")
      return
    end
	
    local featureName = "openBeta"
    if isUCAndroid() then
      featureName = featureName .. "_uc"
    elseif is91Android() then
      featureName = featureName .. "_91"
    elseif isXiaomiAndroid() then
      featureName = featureName .. "_mi"
    elseif is360Android() then
      featureName = featureName .. "_360"
    elseif isDKAndroid() then
      featureName = featureName .. "_duoku"
    elseif isWdjAndroid() then
      featureName = featureName .. "_wandoujia"
    elseif isOppoAndroid() then
      featureName = featureName .. "_oppo"
    elseif isYyhAndroid() then
      featureName = featureName .."_yingyonghui"
    elseif isPlatformAndroid() then
      featureName = featureName .."_he"
    elseif isBukaAndroid() then
      featureName = featureName .."_ibuka"
    elseif isGooglePlayTW() then
      featurnName = featureName .. "_googleplay"
	elseif isTWHE() then
      featurnName = featureName .. "_twhe"
    end
    
    local maintenanceFeatures = self.systemInfo.systemConf.maintenanceFeatures
    local feature = nil
    for _, _feature in ipairs(maintenanceFeatures) do
      if( featureName == _feature.name) then
        feature = _feature
        break;
      end
    end
    
    if(not feature) then
      he_log_warning(featureName .. " is not exist")
    end
    
    local isFeatureEnable = SimpleMaintenanceManager.isFeatureEnable(feature)
    if(isFeatureEnable) then
      local activityEndDateList = feature.endTime:split(" ")[1]:split("/")
      local activityEndTimeList = feature.endTime:split(" ")[2]:split(":")
      
      local month = activityEndDateList[2]
      local day = activityEndDateList[3]
      local hour = activityEndTimeList[1]
      local min = activityEndTimeList[2]
      
      local openRegistNotice = getTextByKey("popup_launchTip", {month=month, day=day, hour=hour, min=min})
      CanonMessageBox.showText(
        ShowButtonType.ID_OK,
        openRegistNotice
      )
    else 
      loginServer()
    end
  end

  local function updateLoginArea( account )
    self.registerBtn:setVisible(false)
    self.guestBtn:setVisible(false)

    self.usernameBtn:setVisible(true)
    self.loginBtn:setVisible(true)

    self.usernameStr:setString(account)
  end

  --账号已经验证成功
  local function saveLoginAccount(account, password)
    local accountTable = {}
    accountTable.username = account
    accountTable.password = password
    accountTable.deviceid = getDeviceId()
    LocalAccountManager.saveLocalAccountInfo(accountTable)
  end

  local function loginWithAccount(account, password)
    ---如果本地没有token，先去请求token
    if self.token == nil then
      local function showCheckError( errorId )
        if not errorId then
          CanonMessageBox.showText( ShowButtonType.ID_OK, getTextByKey("popup_networkError") )
        else
          CanonMessageBox.showText( ShowButtonType.ID_OK, getCheckAccountErrorStr(errorId) )
        end
      end
      local function onAccountChecked( response )
        if response.httpCode ~= 200 or response.errorCode ~= 0 then
          showCheckError()
          return
        end
        if not response.body or response.body == "" then
          showCheckError()
          return
        end
        local retCode = table.deserialize(response.body)
        if retCode.code == 1 then
		  setAccountHasBindEmail(retCode.email)
          loginAccount(retCode.token, 2, accountGetBoundMapping)
        else
          showCheckError(retCode.code)
        end
      end
      checkAccount(self.account, HeMathUtils:md5(self.password), onAccountChecked)
    else
    --本地已经有了token，试着登录
      loginAccount(self.token, 2, accountGetBoundMapping)
    end
  end

  --本地存有账号的时候，点击登录按钮回调(中间的)
  local function localAccountLogin(account, password)
    loginWithAccount(account, password)
  end

  --点击用户名的回调
  local function onLocalUsernameClick( evt )
    require "canon.panel.AccountLoginPanel"

    local function onLoginSucceed(token, account, password)
      saveLoginAccount(account, password)
      self.account = account
      self.password = password
      self.token = token

      updateLoginArea( account )
      loginWithAccount(account, password)
    end

    local loginPanel = AccountLoginPanel:create(self.account, self.password, onLoginSucceed)
    PopoutManager:sharedManager():popout(loginPanel , kPopoutDir.kScale, true, false ,self) 
  end

    --本地没有账号的时候，点击登录按钮(左边的)
  local function onAccountLoginClick( evt )
    ---本地有游客账号的时候，弹出绑定账号的弹窗
    if self.isDeviceBindWithAccount then    
      require "canon.panel.GuestBindAccountPanel"

      local function onCreateAccountSucceed(account, password)
        saveLoginAccount(account, password)
        self.account = account
        self.password = password
        self.token = nil

        updateLoginArea(account)
        loginWithAccount(account, password)
      end

      local bindPanel = GuestBindAccountPanel:create(onCreateAccountSucceed)
      PopoutManager:sharedManager():popout(bindPanel, kPopoutDir.kScale, true, false, self)
    else 
      --本地没有账号，弹出登录窗                                  
      require "canon.panel.AccountLoginPanel"

      local function onLoginSucceed(token, account, password)
        saveLoginAccount(account, password)
        self.account = account
        self.password = password
        self.token = token

        updateLoginArea(account)
        loginWithAccount(account, password)
      end

      local loginPanel = AccountLoginPanel:create(nil, nil, onLoginSucceed)
      PopoutManager:sharedManager():popout(loginPanel , kPopoutDir.kScale, true, false ,self)
    end
  end

  local function onGuestGameClick( evt )
    guestLoginAccount(accountGetBoundMapping)
  end

	-- if isWdjAndroid() or isDKAndroid() or is91Android() then
	-- 	self.loginBG = CCSprite:create("loading/loginBG_zhanji.png")
	-- else
		self.loginBG = CCSprite:create("loading/loginBG.png")
	-- end
  self.loginBG:setAnchorPoint( ccp(0.0, 0.0) )
  self.Co_loginBG = CocosObject.new(self.loginBG)
  self:addChild(self.Co_loginBG)
	
	local particle = CCParticleSystemQuad:create("effect/fx_flower.plist")
	particle:setPosition(ccp(360, 800))
	self:addChild(CocosObject.new(particle))
    
    if isUCAndroid() then
        if getIsUCSdkInit() then
            showUCFloatButton(50,50,false)
        end
    elseif is91Android() then
        if getIs91SdkInit() then
            show91FloatButton(false)
        end
    elseif isDKAndroid() then
          showDKFloatButton(false)
    elseif isOppoAndroid() then
        showOppoFloatSprite(false)
    elseif isYyhAndroid() then
        showYyhToolBar(false)
    elseif isAnzhiAndroid() then
        showAnzhiFloatBar(false)
    end

    if isOfficalAccountPlatform() then
      --上面的账户按钮
      local usernameBtnNode = self.mainUI:getChildByName("login_btu_FBid")
      self.usernameStr = usernameBtnNode:getChildByName("txt")
      self.usernameBtn = Button:create(usernameBtnNode)
      self.usernameBtn:addEventListener( Events.kStart, onLocalUsernameClick, self)

      --左边的登录按钮
      local registerBtnNode = self.mainUI:getChildByName("btn_fastlogin_l")
      self.registerStr = registerBtnNode:getChildByName("txt")
      self.registerStr:setString(getTextByKey("login_account_title"))
      self.registerBtn = Button:create(registerBtnNode)
      self.registerBtn:addEventListener( Events.kStart, onAccountLoginClick, self )

      --右边的游客登录按钮
      local guestBtnNode = self.mainUI:getChildByName("btn_fastlogin_r")
      guestBtnNode:getChildByName("txt"):setString(getTextByKey("login_tourist_title"))
      self.guestBtn = Button:create(guestBtnNode)
      self.guestBtn:addEventListener( Events.kStart, onGuestGameClick, self)

      --中间的登录按钮，当本地有账户或账户登录成功后出现
      local loginBtnNode = self.mainUI:getChildByName("btn_fastlogin")
      loginBtnNode:getChildByName("txt"):setString(getTextByKey("login_title1"))
      self.loginBtn = Button:create(loginBtnNode)
      self.loginBtn:addEventListener( Events.kStart, localAccountLogin, self)

      local accountInfo = LocalAccountManager.getLocalAccountInfo()
      if accountInfo ~= -1 and accountInfo.deviceid == getDeviceId() then
        self.account = accountInfo.username
        self.password = accountInfo.password

        self.usernameStr:setString(self.account)
        self.registerBtn:setVisible(false)
        self.guestBtn:setVisible(false)
      else
        self.loginBtn:setVisible(false)
        self.usernameBtn:setVisible(false)
      end
    else
      self.mainUI:getChildByName("login_btu_FBid"):setVisible(false)
      self.mainUI:getChildByName("btn_fastlogin_l"):setVisible(false)
      self.mainUI:getChildByName("btn_fastlogin_r"):setVisible(false)

      local loginBtnNode = self.mainUI:getChildByName("btn_fastlogin")
      loginBtnNode:getChildByName("txt"):setString(getTextByKey("login_title1"))
      self.loginBtn = Button:create(loginBtnNode)
      self.loginBtn:addEventListener( Events.kStart, onLoginClick, self)
    end

    self:addChild(self.mainUI)
	
	local function onChooseServerClick( evt )
        --CanonMessageBox.showText(ShowButtonType.ID_OK, "Only one server online now!")
		if next(serverListInfo) == nil then
			return
		end
		if enableChoseServer then
			self.targetInfoPanel = ServerSelectPanel:create( self ,serverListInfo, self.setChoseServerInfo)
			PopoutManager:sharedManager():popout(self.targetInfoPanel , kPopoutDir.kScale, true, false ,self)
		end
    end
    

	self.mainUI:getChildByName("txt_click"):getChildByName("txt"):setString(getTextByKey("login_selectServer"))
	--非facebook版本不需要显示facebook登陆按钮
	self.mainUI:getChildByName("login_btn_fastlogin_small_facebook"):setVisible(false)
	
	self:initChoseServerUI()
	--self.mainUI:getChildByName("txt_server"):getChildByName("txt"):setString(getTextByKey("login_serverNo",{num=1}) .."  " .. getTextByKey("login_serverNameDef") .. "  " .. getTextByKey("login_serverCondition_new"))
    
    local selectServerBtn = Button:create(self.mainUI:getChildByName("r_click"))
    selectServerBtn:addEventListener( Events.kStart, onChooseServerClick, self )
	
    if isPlatformIos() then
      --[[
      local gameCenter = Sprite:create("common/gamecenter.png")
      gameCenter:setPosition(ccp(80, 80))
      self:addChild(gameCenter , 20)
      local gameCenterBtn = Button:create(gameCenter)
      gameCenterBtn:addEventListener(Events.kStart, function()
          PlatformMgr:getInstance():showLeaderboards()
      end, self)

      local achieve = Sprite:create("common/achievement.png")
      achieve:setPosition(ccp(visibleSize.width - 80, 80))
      self:addChild(achieve, 20)
      local achieveBtn = Button:create(achieve)
      achieveBtn:addEventListener(Events.kStart, function()
          PlatformMgr:getInstance():showAchievements()
      end, self)
      ]]
    end
	--第三方登录
	--self.mainUI:getChildByName("normal_card_small1"):setVisible(false)
	--self.mainUI:getChildByName("normal_card_small2"):setVisible(false)
	--self.mainUI:getChildByName("normal_card_small3"):setVisible(false)
	--self.mainUI:getChildByName("txt_bottom"):setVisible(false)

    --切换帐号
	if (DataManager.SystemConfig.ChangeAccountVisible) then
		local text = TextField:create("帐号：")
		text:setFontSize(30)
		text:setPosition(ccp(visibleSize.width/2-200, 350))
		self:addChild(text)  
		local scale9 = Scale9Sprite:create("textbox_comm/TextBox_Comm_2.png")
		local editbox = TextInput:create(CCSizeMake(280,50), scale9)
    editbox:setReturnType(kKeyboardReturnTypeDone)
		self:addChild(editbox)
		editbox:setPosition(ccp(visibleSize.width/2, 350))

		local function onTextInputEvent( evt )
			local function callback( response )
				--print(table.tostring(response))
				if response.errorCode==0 and response.httpCode==200 then 
					local user_uuid = response.body
					localStorage.setCurrentUser(user_uuid)
					self:initConn()
				end
			end
			local accountId = editbox:getText()
			local url = DataManager.SystemConfig.ChangeAccountUrl .. accountId
			local request = HttpRequest:createPost(url)
			HttpClient:getInstance():sendRequest( callback, request )       
		end
		editbox:addEventListener(kTextInputEvents.kChanged, onTextInputEvent)
	end

	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("card/card_plist.plist");
	-- CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("pic/pic_plist.plist");
  
  -- add EnterForeground script by spark
  local function notificationHandler(name)
    if("APP_ENTER_FOREGROUND" == name) then -- 重新进入游戏
      --1. 同步时间,rpc.lua中纠正_G.__g_utcDiffSeconds
      local connState = Communication:getInstance().transponder
      if(connState) then
        local request = GetServerTimeStampRequest.new( nil, rpc.SendingPriority.kHigh )
        request:start()
      end
    else
      he_log_warning("unsupport system notifitcation name:" .. name)
    end
  end
  CCNotificationCenter:sharedNotificationCenter():registerScriptObserver(notificationHandler)
end

function LoginScene:initConn()
  self.conn = Communication:getInstance()
  
  local function initCommunicatonSuccess()
    self.conn:removeEventListener(CommunicationInitEvent.kComplete, initCommunicatonSuccess)  
    self.conn.connState = true
    he_log_info("+++++++++++++++++++++++++++Login Log:initCommunicatonSuccess++++++++++++++++++++++++++++++++")
    DcManager.sendLoadingActivity(68, ((os.time() - g_startTime )*1000) )
    --[[
    if isUCAndroid() or is91Android() or isXiaomiAndroid() or is360Android() or isPlatformIos() or isIosTW()
        or isDKAndroid() or isWdjAndroid() or isOppoAndroid() or isYyhAndroid() or isPlatformAndroid() or isBukaAndroid() or isGooglePlayTW() or isTWHE() 
    		or isChuangMengAndroid() or isOfficialPlatformFunc() or isYYBAndroid() or isLongyuanPlatformFunc() or isAnzhiAndroid() or isVivoAndroid()
        or isI4ios() or isHaimaIos() or isKuaiYongIos () then
    --]]
    if true then
        thirdPlatformBindAccount(self.startLoginServer)
    end
  end
  
  local content = localStorage.getCurrentUser()
  LoginScene.userDat = content
  self.conn:setUser( content )
  he_log_info("+++++++++++++++++++++++++++Login Log:addEventListener initCommunicatonSuccess++++++++++++++++++++++++++++++++")
  self.conn:addEventListener(CommunicationInitEvent.kComplete, initCommunicatonSuccess)
  
  if isUCAndroid()  then
    if getIsLoginUC() then
        logoutUC()
    end
  elseif isXiaomiAndroid() then
    if getIsLoginXiaomi() then
        logoutXiaomi()
    end
  elseif is360Android() then
    if getIsLogin360() then
        logout360()
    end
  elseif isDKAndroid() then
    if getIsLoginDK() then
        logoutDK()
    end
  elseif isWdjAndroid() then
    if getIsLoginWdj() then
        logoutWdj()
    end
  elseif isOppoAndroid() then
    if getIsLoginOppo() then
        logoutOppo()
    end
  elseif isYyhAndroid() then
    logoutYYH()
  elseif isYYBAndroid() then
    logoutQQ()
  elseif isAnzhiAndroid() then
    logoutAnzhi()
  elseif isVivoAndroid() then
    if isVivoLogin() then
        logoutVivo()
    end
  elseif isJinliAndroid() then
    logoutJinli()
  elseif isOfficalAccountPlatform() then
    logoutAccount()
  elseif isI4ios() then
    logoutI4_ios()
  elseif isHaimaIos() then
    logoutHaima_ios()
  elseif isKuaiYongIos() then
    logoutKuaiyong_ios()
  elseif isTongbuIos() then
    logoutTongbu_ios()
  elseif isHuaweiAndroid() then
    if isHuaweiLogin() then
        logoutHuawei()
    end
  elseif isJoloplayAndroid() then
    if isJoloplayLogin() then 
        logoutJoloplay()
    end
  elseif isJinshanAndroid() then
    logoutJinshan()
  elseif isMuwanAndroid() then
    logoutMuwan()
  elseif isLenovoAndroid() then
	logoutLenovo()
  else
    self.conn:init()
  end	
end

function LoginScene:dispose()
    he_log_info("+++++++++++++++++++++++++++Login Log:dispose()++++++++++++++++++++++++++++++++")
	LoginScene.super.dispose(self)
end
