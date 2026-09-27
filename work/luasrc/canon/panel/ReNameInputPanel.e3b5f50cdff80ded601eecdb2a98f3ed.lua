require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.ChangeNameRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

ReNameInputPanel = class(Layer)

function ReNameInputPanel:ctor()
	self.container = nil
end

function ReNameInputPanel:create( container )
	self.container = container
	local s = ReNameInputPanel.new()
	s:initLayer()
	return s
end

function ReNameInputPanel:initLayer()
	if type(self.container.setTableViewsEnabled) == "function" then
		self.container:setTableViewsEnabled(false)
	end
	ReNameInputPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("common_popup_changename")

	self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("rename_CD_tips1"))
	self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("rename_CD_tips2"))
	self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(MetaManager.game_meta.gameSettingConfig.renameCooldown / 3600 /24)
	self.panelUI:getChildByName("common_btn_cancel_changename"):getChildByName("txt_cancel"):setString(getTextByKey("rename_button_save"))
	self.panelUI:getChildByName("common_btn_cancel_ya"):getChildByName("txt_cancel"):setString(getTextByKey("rename_button_cancel"))
	self.panelUI:getChildByName("txt_5"):getChildByName("txt"):setString(getTextByKey("rename_inputTitle"))

	-- 关闭Panel事件
	local function onClosePanel(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		if type(self.container.setTableViewsEnabled) == "function" then
			self.container:setTableViewsEnabled(true)
		end
	end

	-- 关闭按钮
	local closeButtonDisplay = self.panelUI:getChildByName("common_btn_cancel_ya")
	local closeButton = Button:create(closeButtonDisplay)
	closeButton:addEventListener(Events.kStart, onClosePanel, self)
	
	local closeButton1 = Button:create(self.panelUI:getChildByName("btn_close"))
	closeButton1:addEventListener(Events.kStart, onClosePanel, self)

	--初始化数据
	selectedText = ""

	local function onSaveName( evt )
		local strNickName = selectedText
	    if strNickName == "" then
	    	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("login_popup_nicknameIsNull"))
	        -- CanonMessageBox.showText( ShowButtonType.ID_OK, getTextByKey("login_popup_nicknameIsNull") )
	        return
	    end
	    local chinum,engnum = StringUtil.calcChineseEnglishNum(strNickName)
	    if (chinum*2+engnum)>12 then
	        -- local text = getTextByKey("login_popup_nicknameIsTooLong")
	        self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("login_popup_nicknameIsTooLong"))
	        -- CanonMessageBox.showText(
	        --   ShowButtonType.ID_OK,
	        --   text
	        -- )
	        return
	    end
	    if (chinum*2+engnum)<2 then
	    	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("login_popup_nicknameIsTooShort"))
	    	return
	    end
	    if strNickName == DataManager.getCurrUser().nickName then
	    	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("rename_sameName"))
	        return
	    end
	    local function onSaveNameSucceedResponse( e )
			local userData = DataManager.getCurrUser()
			userData.nickName = strNickName
			DataManager.setCurrUser(userData)

			local costTable = {}
			costTable.amount = (-1)
			costTable.metaId = MetaManager.game_meta.gameSettingConfig.renamePropId
			costTable.itemType = ResourceEnum.PROP
			RewardManager:getReward({costTable})	

			local nowTime = TimeUtil.getServerTimeSeconds()
			local gameInit = DataManager.getGameInitData()
			gameInit.sharkUserExtend.lastRenameTimes = nowTime
			DataManager.setGameInitData(gameInit)

			if type(self.container.refreshName) == "function" then
				self.container:refreshName()
			end

			if self.container.curSceneEnum and self.container.curSceneEnum == SceneEnum.BackpackScene then
				for k, v in pairs(self.container.item_data)
				do
					if v.metaId == MetaManager.game_meta.gameSettingConfig.renamePropId then
						self.container.item_data[k].amount = self.container.item_data[k].amount - 1
						if self.container.item_data[k].amount <= 0 then
							table.remove(self.container.item_data, k)
						end
						self.container:refreshTable(false)
						break;
					end
				end
			end
			
			onClosePanel(nil)
		end

		local function onSaveNameFailedResponse( e )
			local errorCode = e.data
	        if (errorCode == CommErrorCodes.NICKNAME_IS_NULL.code) then
	        	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey(CommErrorCodes.NICKNAME_IS_NULL.textKey))
	            -- CanonMessageBox:showCommErrorBox(CommErrorCodes.NICKNAME_IS_NULL)
	        elseif (errorCode == CommErrorCodes.NICKNAME_IS_INVALID.code) then
	        	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey(CommErrorCodes.NICKNAME_IS_INVALID.textKey))
	            -- CanonMessageBox:showCommErrorBox(CommErrorCodes.NICKNAME_IS_INVALID)
	        elseif (errorCode == CommErrorCodes.NICKNAME_IS_TOOSHORT.code) then
	        	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey(CommErrorCodes.NICKNAME_IS_TOOSHORT.textKey))
	            -- CanonMessageBox:showCommErrorBox(CommErrorCodes.NICKNAME_IS_TOOSHORT)
	        elseif (errorCode == CommErrorCodes.NICKNAME_IS_TOOLONG.code) then
	        	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey(CommErrorCodes.NICKNAME_IS_TOOLONG.textKey))
	            -- CanonMessageBox:showCommErrorBox(CommErrorCodes.NICKNAME_IS_TOOLONG)
	        elseif (errorCode == CommErrorCodes.NICKNAME_IS_EXIST.code) then
	        	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey(CommErrorCodes.NICKNAME_IS_EXIST.textKey))
	            -- CanonMessageBox:showCommErrorBox(CommErrorCodes.NICKNAME_IS_EXIST)
	        elseif (errorCode == CommErrorCodes.NICKNAME_CONTAIN_SENSTIVEWORD.code) then
	        	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey(CommErrorCodes.NICKNAME_CONTAIN_SENSTIVEWORD.textKey))
	            -- CanonMessageBox:showCommErrorBox(CommErrorCodes.NICKNAME_CONTAIN_SENSTIVEWORD)
            elseif (errorCode == 716870) then
            	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("rename_CDing1"))
	        end
		end

		local param = {nickName = strNickName}
		ChangeNameRequest.sendRequest(param,onSaveNameSucceedResponse,onSaveNameFailedResponse)
	end

	local btn = Button:create(self.panelUI:getChildByName("common_btn_cancel_changename"))
	btn:addEventListener(Events.kStart, onSaveName )

	--输入文本
	local function onTextInputEvent( evt )
		selectedText = self.editInputLabel:getText() 
		--print("selectedText = " .. selectedText)
		if selectedText == "" then
			self.panelUI:getChildByName("txt_info_txt1"):getChildByName("txt"):setString("")--输入6位以内的名称
		else
			self.panelUI:getChildByName("txt_info_txt1"):getChildByName("txt"):setString(selectedText)
		end
		-- self.panelUI:getChildByName("txt_info_txt1"):getChildByName("txt"):setString(selectedText)
	end
	local inputBackground = self.panelUI:getChildByName("other2_gray9_panel2")
	--local inputSize = inputBackground:getGroupBounds().size
	local inputSize = {width = 346.25, height = 58}
	local inputPos = inputBackground:getPosition()
	self.inputSprite = Scale9Sprite:create("pic/empty.png")
	self.inputSprite:setAnchorPoint(ccp(0, 1))
	self.inputSprite:setOpacity(0)
	self.editInputLabel = TextInput:create(CCSizeMake(inputSize.width, inputSize.height), self.inputSprite)
	self.editInputLabel:setPosition(ccp(inputPos.x + inputSize.width / 2, inputPos.y - inputSize.height / 2))
	self.editInputLabel.refCocosObj:setInputFlag( -100 ) -- 隐藏
	self.editInputLabel:setReturnType(kKeyboardReturnTypeDone)
	self.editInputLabel:addEventListener(kTextInputEvents.kChanged, onTextInputEvent)
	
	if __IOS then
		self.editInputLabel:setPlaceHolder("")
		self.panelUI:getChildByName("txt_info_txt1"):setVisible(false)
	end
	self.panelUI:addChild(self.editInputLabel)
	self.panelUI:getChildByName("txt_info_txt1"):setZOrder(1001)
	self.panelUI:getChildByName("txt_info_txt1"):getChildByName("txt"):setString(selectedText)--输入6位以内的名称
	
	self:addChild(self.panelUI)
end
