--------------------------------------------------------------------------------
-- FacebookShareTriggerPanel.lua --显示获得的奖励
-- author: dang chao
-- updated: 2013-10-20
--------------------------------------------------------------------------------


FacebookShareTriggerPanel = class(Layer)


function FacebookShareTriggerPanel:ctor()
    self.container = nil
	self.rewardInfo = {}
end

function FacebookShareTriggerPanel:create( container ,shareId,shareText,callBackFunc)
    self.container = container
    self.callBackFunc = callBackFunc
	self.shareId = shareId
	self.shareText = shareText
    local s = FacebookShareTriggerPanel.new()
    s:initLayer()
    return s
end

function FacebookShareTriggerPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	
    FacebookShareTriggerPanel.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
	builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_FB1")
	
	self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(self.shareText)
	self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("FBactivity_share_txt1"))
	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(self.shareText)
	self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("FBactivity_share_txt2"))
	
	local function requestFacebookTriggerShare(shareSuccess)
		local function ShareFacebookTriggerSucc(response)
			--本地更新记录sharkFbShareGameList
			local gameData = DataManager.getGameInitData()
			if gameData.sharkFbShare and gameData.sharkFbShare.sharkFbShareGameList then
				table.insert(gameData.sharkFbShare.sharkFbShareGameList,{
																			shareId = self.shareId,
																			shareSuccess = shareSuccess
																		})
			else
				--first write facebook share data
				if gameData.sharkFbShare then
					gameData.sharkFbShare["sharkFbShareGameList"] = { 
																		{
																			shareId = self.shareId,
																			shareSuccess = shareSuccess
																		}
																	}
				else
					gameData["sharkFbShare"] = {}
					gameData.sharkFbShare["sharkFbShareGameList"] = { 
																		{
																			shareId = self.shareId,
																			shareSuccess = shareSuccess
																		}
																	}
				end 
			end
			DataManager.setGameInitData(gameData)
			
			--删除本地记录的shareid
			local shareInfo = localStorage.getShouldFacebbookShareInfo(   ) 
			if shareInfo ~= "" then
				shareInfo.shareId = ""
				shareInfo.shareText = ""
				localStorage.saveShouldFacebbookShareInfo( shareInfo )
			end	 
		
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			self.container:setTableViewsEnabled(true)
			self.container.targetInfoPanel = nil
			if self.callBackFunc and type(self.callBackFunc) == "function" then
				self:callBackFunc()
			end 
		end
		local function ShareFacebbookTriggerFail(response)
			local errorCode = tonumber(response.data)
			CanonMessageBox:showCommUnHandleErrorBox(errorCode)
		end
		local params = {shareId = self.shareId,shareSuccess = shareSuccess}
		local request = FacebookRecordTriggerShareRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.ShareFacebookTriggerSucceed, ShareFacebookTriggerSucc)
		request:addEventListener(RequestNotifyEnum.ShareFacebookTriggerFailed, ShareFacebbookTriggerFail)
		request:start() 
	end
	
	local function requestFacebookTriggerShareTrue()
		requestFacebookTriggerShare(true)
	end
	
	local function requestFacebookTriggerShareFalse()
		requestFacebookTriggerShare(false)
	end
    local function onClosePanel(evt)
		CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, getTextByKey("FBactivity_reward_confirmCancel"), 
          {
            text = getTextByKey("yes"),
            callbackFunc = function()
				he_log_info("+++++++++++++++++++++++++++cancel facebook share ++++++++++++++++++++++++++++++++")
				--记录状态，之后不再弹分享请求弹窗
				local shareInfo = {
									shareId = self.shareId,
									shareText = self.shareText,
									shareOpen = FacebookShareOpenKey.CLOSE
								   }
				localStorage.saveShouldFacebbookShareInfo( shareInfo ) 
				requestFacebookTriggerShareFalse()
            end
          }, 
          nil,
          {
            text = getTextByKey("cancel"),
            callbackFunc = function()
				
            end
          }
        )
    end 
	
	local function onShareFB(evt)
		he_log_info("+++++++++++++++++++++++++++goto facebook share ++++++++++++++++++++++++++++++++")
		--判断是否bind
		if not isBindFacebook() then
			local function gotoBindFacebook()
				DataManager.clearData()
				--保存当前shareid 重新登录后重新弹分享面板
				local shareInfo = {
									shareId = self.shareId,
									shareText = self.shareText,
									shareOpen = FacebookShareOpenKey.OPEN
								   }
				localStorage.saveShouldFacebbookShareInfo(shareInfo)
				Director:sharedDirector():replaceScene(LoginScene:create())
				return
			end
			
			local function cancelBindFacebook()
				--do nothing
			end
			CanonMessageBox:Show(getTextByKey("Fbactivity_error_txt1"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoBindFacebook, cancelBindFacebook)
			return
		end

		-- 调用facebook share 接口
		local currUser = DataManager.getCurrUser()
		feedFacebook(requestFacebookTriggerShareTrue,getTextByKey("Fbactivity_share_txt6",{name1 = currUser.nickName}),getTextByKey("Fbactivity_share_txt4",{name1 = currUser.nickName, txt1 = self.shareText}),getTextByKey("Fbactivity_share_txt5"))
    end 
	
    --close
	local close_Btn = Button:create(self.panelUI:getChildByName("btn_close"))
    close_Btn:addEventListener(Events.kStart ,onClosePanel ) 
	--share
	local close_Btn = Button:create(self.panelUI:getChildByName("btn_FB_share"))
    close_Btn:addEventListener(Events.kStart ,onShareFB ) 
	
	--rewardIcon
	local rewardId = DataManager.GameMetaData.fbShareConfig.fbShareMetas[self.shareId].shareReward
	local rewardConfig = MetaManager.getRewardInfoByID(rewardId) or {}
	local rewardItem = self.panelUI:getChildByName("bg_FB_item")
	rewardItem:getChildByName("frame_card"):setVisible(false)
	rewardItem:getChildByName("normal_card_small"):setVisible(false)
	rewardItem:getChildByName("bg_card"):setVisible(false)
	if #rewardConfig > 0 then
		local itemName = CanonGoodIcon.getGoodNameByPackageRewardInfo(rewardConfig[1])
		rewardItem:getChildByName("txt"):getChildByName("txt"):setString(itemName)
		
		local params = {}
		params.sourceSizes = {135, 135}
		local itemIcon = CanonGoodIcon.createGoodIcon(rewardConfig[1].itemType, rewardConfig[1].metaId, 0, params)
		
		itemIcon:setPosition(ccp(rewardItem:getChildByName("normal_card_small"):getPositionX(), rewardItem:getChildByName("normal_card_small"):getPositionY()))
		rewardItem:addChild(itemIcon)	
	end
	
    self:addChild(self.panelUI) 
end