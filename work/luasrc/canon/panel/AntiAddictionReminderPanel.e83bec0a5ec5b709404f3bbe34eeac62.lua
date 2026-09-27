
AntiAddictionReminderPanel = class(Layer)

function AntiAddictionReminderPanel:ctor()
    self.container = nil
end

function AntiAddictionReminderPanel:create( container , addictionStatus)
    local s = AntiAddictionReminderPanel.new()
    self.container = container
    self.addictionStatus = addictionStatus
    s:initLayer()
    return s
end

function AntiAddictionReminderPanel:initLayer()
    AntiAddictionReminderPanel.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
    self.panelUI = builder:build("common_popup_anti_indulge")
    self:addChild(self.panelUI) 
    
    local function backToLoginScene()
        PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
        self.container.targetInfoPanel = nil
        
        DataManager.clearData()
        DcManager.closeUserOnlineActivity()
            
        self.container:replaceScene(LoginScene)
    end

    local function onClosePanel(evt)
		
        if self.addictionStatus == AddictionStateTable.slight then
            PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
            self.container.targetInfoPanel = nil
        elseif self.addictionStatus == AddictionStateTable.severe then
            if is360Android() then
                logout360(backToLoginScene)
            end
        end 
        
    end 
	
	local function onRegister(evt)
        local function afterRealNameRegister()
            local function recordAddictedTimeSucc(evt)
                he_log_info("+++++++++++++++++++++++++++addiction Log:recordAddictedTimeSucc++++++++++++++++++++++++++++++++")
                PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
                self.container.targetInfoPanel = nil
            end
                    
            local function recordAddictedTimeFail(evt)
                he_log_info("+++++++++++++++++++++++++++addiction Log:recordAddictedTimeFail++++++++++++++++++++++++++++++++")
                PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
                self.container.targetInfoPanel = nil
            end
            local params = { minutes = 0 }
            local request = RecordAddictedTimeRequest.new( params, rpc.SendingPriority.kHigh )
            request:addEventListener( RequestNotifyEnum.RecordAddictedTimeSucceed, recordAddictedTimeSucc )
            request:addEventListener( RequestNotifyEnum.RecordAddictedTimeFailed, recordAddictedTimeFail )
            request:start()
            he_log_info("+++++++++++++++++++++++++++addiction Log:send request++++++++++++++++++++++++++++++++")
        end
        doSdkRealNameRegister(afterRealNameRegister)
    end 
	self.panelUI:getChildByName("txt_anti_indulge_title"):getChildByName("txt"):setString(getTextByKey("preventFascinationTitle")) 
	self.panelUI:getChildByName("txt_anti_indulge_2"):setVisible(false)
	self.panelUI:getChildByName("common_btn_cancel_y"):getChildByName("txt_cancel"):setString(getTextByKey("cancel"))
	self.panelUI:getChildByName("common_btn_register"):getChildByName("txt"):setString(getTextByKey("preventFascinationRegisterBtn"))
    if self.addictionStatus == AddictionStateTable.slight then
        self.panelUI:getChildByName("txt_anti_indulge_1"):getChildByName("txt"):setString(getTextByKey("preventFascinationPopups_slightText")) 
    else
        self.panelUI:getChildByName("txt_anti_indulge_1"):getChildByName("txt"):setString(getTextByKey("preventFascinationPopups2_severeText")) 
    end 
    local cancel_Btn = Button:create(self.panelUI:getChildByName("common_btn_cancel_y"))
	cancel_Btn:addEventListener(Events.kStart ,onClosePanel ) 

    local register_Btn = Button:create(self.panelUI:getChildByName("common_btn_register"))
	register_Btn:addEventListener(Events.kStart ,onRegister ) 
end