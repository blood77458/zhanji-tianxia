require "canon.panel.CanonMessageBox"
require "hecore.ui.PopoutManager"
require "canon.request.localStorage"

--return the type of image pixel format for current machine
--1 for best machines, all image rgba8888
--2 for 4s and ipad mini1, only sceneCombine 8888
--3 for iphone4 and ipad2, all 4444
function getDeviceImageType()
	local machineType = MetaInfo:getInstance():getDeviceModel()
	if string.find(machineType, "iPhone") then --- for iphones
		local version = tonumber(machineType:sub(7,7))
		if version <= 3 then
			return 3
		elseif version == 4 then
			return 2
		else
			return 1
		end
	elseif string.find(machineType, "iPad") then  -- for ipad
		local version = tonumber(machineType:sub(5,5))
		local smallVersion = tonumber(machineType:sub(7,7))
		if version <= 2 then
			if smallVersion <= 4 then
				return 3
			else
				return 2
			end
		else
			return 1
		end
	elseif string.find(machineType, "iPod") then   -- for ipod
		local version = tonumber(machineType:sub(5,5))
		if version <= 4 then
			return 3
		else
			return 2
		end
	else
		return 3
	end
end

DynamicUpdateScene = class(Scene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

local function createSpriteFrame(name)
	local texCache = CCTextureCache:sharedTextureCache()
	local tex = texCache:addImage(name)
	if not tex then
		return nil;
	end
	local size = tex:getContentSizeInPixels()
	local w = size.width
	local h = size.height
	local rect = CCRect(0, 0, w, h)
	local spriteFrame = CCSpriteFrame:createWithTexture( tex, rect )
	return spriteFrame
end

function DynamicUpdateScene:ctor()
	self.spt = nil
	self.fspt = nil
	self.sizeStr = nil
	self.updating = false
	-- self.tagFetched = false
end

function DynamicUpdateScene:create()
  local s = DynamicUpdateScene.new()
  s:initScene()
  return s
end

function DynamicUpdateScene:onInit()
	--[[
	local oldUserInfo = localStorage.getCurrentUser()
	oldUserInfo = oldUserInfo:split(",")
	local accountId = tonumber(oldUserInfo[1])
	if accountId <= 0 then
	  accountId = -1
	end
	local lastChoseServerInfo = localStorage.getLastChoseServerInfo( ) 
	local lastChoseServerId
	if lastChoseServerInfo ~= "" then
		lastChoseServerId = lastChoseServerInfo.serverInfo.serverId
	else
		lastChoseServerId = 0
	end
	local domainUrl = StartupConfig:getInstance():getGameDomain()
	local url = domainUrl .. "/checkDebugVersion?accountId=" .. accountId .."&serverId=" .. lastChoseServerId
	local callback
	local function startRequest()
		local request = HttpRequest:createPost(url)
		HttpClient:getInstance():sendRequest( callback, request ) 
	end
	callback = function( response )
		--print(table.tostring(response))
		if response.errorCode==0 and response.httpCode==200 then 
			local user_path = HeResPathUtils:getUserDataPath()
			local file = io.open(user_path.."/debug.txt","w")
			if response.body == "false" then
				print("非白名单")
				file:write("jet")
			else
				print("白名单")
				file:write("debug")
			end
			file:close()
			self.tagFetched = true
		else
			local function closeCanonMessageBox()
				startRequest()
			end
    		CanonMessageBox:Show(getTextByKey("popup_networkError"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		end
	end
	startRequest()
	]]
    if isAnzhiAndroid() then
		local s = Sprite:create("anzhi_logo.jpg")
        s:setPosition(ccp(visibleSize.width/2, visibleSize.height/2))
        self:addChild(s)
		return
    end
    
	local bg = Sprite:create("logoBg.png")
	bg:setScale(10)
    bg:setPosition(ccp(visibleSize.width/2, visibleSize.height/2))
	self:addChild( bg)
	
	if isUCAndroid() then
	--add uc logo
		local uclog = Sprite:create("uc_logo.png")
		uclog:setAnchorPoint(ccp(1,1))
		uclog:setPosition(ccp(visibleSize.width, visibleSize.height))
		self:addChild( uclog)
	end
	local s
	if isWdjAndroid() or isDKAndroid() or is91Android() then
		s = Sprite:create("logo_zhanji.png")
	else
		s = Sprite:create("logo.png")
	end
	
	s:setPosition(ccp(visibleSize.width/2-20, visibleSize.height/2+100))
	self:addChild(s)
end

local kGuangX = 0
local kGuangY = 170

function DynamicUpdateScene:onUpdate(dt)
	--[[
	if not self.tagFetched then
		return
	end
	]]
	if self.updating then
		return
	end

	self.updating = true
	-- self.fspt = FlashSprite:create("loading/zhudonghua");
	-- local dianwei = createSpriteFrame("loading/dianweibig.png")
	-- self.fspt:addChangeInstance("dianwei", dianwei)
	-- local lvbu = createSpriteFrame("loading/lvbubig.png")
	-- self.fspt:addChangeInstance("lvbu", lvbu)
	-- local zhangfei = createSpriteFrame("loading/zhangfeibig.png")
	-- self.fspt:addChangeInstance("zhangfei", zhangfei)
	-- local sunquan = createSpriteFrame("loading/sunquanbig.png")
	-- self.fspt:addChangeInstance("sunquan", sunquan)
	-- self.fspt:changeAnimation(1)
	-- self.fspt:setLoop(false)
	-- self:addChild(CocosObject.new(self.fspt))
	--if isWdjAndroid() or isDKAndroid() or is91Android() then
	--	self.loginBG = CCSprite:create("loading/loginBG_zhanji.png")
	--else
		self.loginBG = CCSprite:create("loading/loginBG.png")
	--end
	
	self.loginBG:setAnchorPoint( ccp(0.0, 0.0) )
	self.Co_loginBG = CocosObject.new(self.loginBG)
	if g_wideDevice then
		self.Co_loginBG:setPosition(ccp(0, -100))
	end
	self:addChild(self.Co_loginBG)

	self.sptBG = CCSprite:create("loading/dibian.png")
	self.sptBG:setPosition(ccp(visibleSize.width/2,kGuangY))
	--self.sptBG:setScaleX(720/40)
	self.Co_sptBG = CocosObject.new(self.sptBG)
	self:addChild(self.Co_sptBG)

	self.spt = CCProgressTimer:create(CCSprite:create("loading/jindutiao.png"))
	self.spt:setPosition(ccp(visibleSize.width/2,170))
	self.spt:setType(kCCProgressTimerTypeBar);
	self.spt:setMidpoint(ccp(0,0))
	self.spt:setBarChangeRate(ccp(1, 0))
	self.spt:setPercentage(0)
	self:addChild(CocosObject.new(self.spt))
	
	if not IsDiaosiDevice() then
		CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA4444);	
	end
	
	self.sizeStr = CCLabelTTF:create(getTextByKey("checkingUpdate"), "Arial", 30)
	self.sizeStr:setPosition(ccp(visibleSize.width/2, 200))
	self.sizeStr:setColor(ccc3(0,0,0))
	self:addChild(CocosObject.new(self.sizeStr))


	local doUpdate = nil

	local function dynamicUpdateCallback(eventName, data)
		if eventName == ResCallbackEvent.onError then
			if data.errorCode == 2014 then
				CanonMessageBox.showText(
					ShowButtonType.ID_OK,
					getTextByKey("newVersionUpdate"),
					nil,
					{
	                    text = getTextByKey("yes"),
	                    callbackFunc = function()
	                        ResourceLoader.downloadNewVersion()
	                        PlistResMgr:getInstance():terminateProcess()
	                    end
					}
				)
			else
				local currentMd5 = ResourceLoader.getCurVersion()
				he_log_info("++++++++++++dynamicUpdateNetError")
				local errData = {
						errorData = data.errorCode,
						msg = "dynamicUpdateNetError"
						}
				DcManager.sendLoadingActivity(7, ((os.time() - g_startTime )*1000) ,errData)
			    CanonMessageBox.showText(
	                ShowButtonType.ID_OK,
	                getTextByKey("popup_networkError"),
	                nil,
	                {
	                    text = getTextByKey("retry"),
	                    callbackFunc = function()
	                        self.sizeStr:setString(getTextByKey("checkingUpdate"))
	                        self.spt:setPercentage(0)
	                        doUpdate()
	                    end
	                }
	            )
	        end
		elseif eventName == ResCallbackEvent.onSuccess then
			CCFileUtils:sharedFileUtils():purgeCachedEntries()
			ResManager:getInstance():initStaticConfig()
			local function reloadLua(name, isRequire)
				name = string.gsub(name, "src/", "")
				name = string.gsub(name, ".lua", "")
				name = string.gsub(name, "/", ".")
				if isRequire then
					require(name) 
				elseif package.loaded[name] then
					package.loaded[name] = nil  
				end
			end
			
			local function isLuaLoaded(virtualPath)
				virtualPath = string.gsub(virtualPath, "src/", "")
				virtualPath = string.gsub(virtualPath, ".lua", "")
				virtualPath = string.gsub(virtualPath, "/", ".")
				return package.loaded[virtualPath]
			end
			
			if type(data) == "table" and type(data.needDownLoadData) == "table" then
				for virtualPath, needDownLoad in pairs(data.needDownLoadData) do
					if needDownLoad then
						if isLuaLoaded(virtualPath) then
							CanonMessageBox.showText(
								ShowButtonType.ID_OK,
								getTextByKey("update_pleaseReopenTips"),
								nil,
								{
									text = getTextByKey("yes"),
									callbackFunc = function()
									restartApp()
									end
								}
							)
			--scenecombine.png²»ÔÙÊ¹ÓÃ
						
						end
					end
				end
			end
			Localization:getInstance():reload()
			require "canon.data.ThirdPlatformLogin"
			require "canon.scene.LoadingScene"
			local loadingScene = LoadingScene:create()
			Director:sharedDirector():replaceScene( loadingScene )
		elseif eventName == ResCallbackEvent.onProcess then
			if data.totalSize > 300000 then
				self.spt:setPercentage(data.curSize/data.totalSize * 100)
				self.sizeStr:setString( getTextByKey("updateTip")..string.format("%.2fM/%.2fM",data.curSize/1000000 ,data.totalSize/1000000))
				self.sizeStr:setColor(ccc3(0,0,0))
			end
		elseif eventName == ResCallbackEvent.onPrompt then
			local currentMd5 = ResourceLoader.getCurVersion()
			local md5Table = {md5_before = currentMd5}
			if data.status.needDownloadSize > 300000 then
				require "canon.customUI.UpdateNotifyBox"
				UpdateNotifyBox.showBox(
					data.status.needDownloadSize,
					function()
						DcManager.sendLoadingActivity(8, ((os.time() - g_startTime )*1000),  md5Table)
						data.resultHandler(1)
					end, 
					function()
						DcManager.sendLoadingActivity(7, ((os.time() - g_startTime )*1000) ,md5Table)
						data.resultHandler(0)
					 	PlistResMgr:getInstance():terminateProcess()
					end)
				--[[
				CanonMessageBox.showText(
					ShowButtonType.ID_OK_CANCEL,
					Localization:getInstance():getText("updateDialog", {num = string.format("%.2f", data.status.needDownloadSize/1000000)}),
					{
						text = getTextByKey("yes"),
						callbackFunc = function()
							data.resultHandler(1)
						end
					},
					nil,
					{
						text = getTextByKey("cancel"),
						callbackFunc = function()
							PlistResMgr:getInstance():tryToCloseActivity(getTextByKey("popup_exitGameText"), getTextByKey("yes"), getTextByKey("cancel"))
							data.resultHandler(0)
						end
					}
				)
--]]
			else
				DcManager.sendLoadingActivity(6, ((os.time() - g_startTime )*1000), md5Table )
				data.resultHandler(1)
			end
		end
	end

	doUpdate = function()
		ResourceLoader.loadRequiredResWithPrompt(dynamicUpdateCallback)
	end

	doUpdate()
end

