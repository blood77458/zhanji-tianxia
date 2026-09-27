ServerSelectPanel = class(Layer)

local cellTag = -1002

local txt_new_Tag = 1001
local txt_normal_Tag = 1002
local txt_crowd_Tag = 1003
local txt_full_Tag = 1004

local txt_serverArea_Tag = 1005
local txt_serverName_Tag = 1006

local selected_effect_Tag = 1007
local selected_ever_Tag = 1008

local selectedList = {}

local ServerSelectPanelInstence = nil
function ServerSelectPanel:ctor()
    self.container = nil
end

function ServerSelectPanel:create( container ,serverListInfo,callBackFunc, params)
    self.container = container
    self.callBackFunc = callBackFunc
	self.params = params
	self.serverListInfo = serverListInfo
	self.choseServerEnable = true
	if not self.params then
		self.params = {}
	end
    local s = ServerSelectPanel.new()
    s:initLayer()
    return s
end

function ServerSelectPanel:createTableView(data,argv)
	local ServerCellRenderer = class(TableViewRenderer)
	local selectedCellPanel = {} 
	function ServerCellRenderer:ctor(width,height)
		local rows = #data
        for i=1, rows do
            self.list[i] = i
        end
		local builder = LayoutBuilder:createWithContentsOfFile("scene/login_new.json")
		self.builder = builder
	end
	
	function ServerCellRenderer:buildCell(container)
        local cell = self.builder:build("login_server_select_bar")
        cell:setPosition(ccp(0, self.height))
        
        cell:getChildByName("login_txt_new"):getChildByName("txt"):setString(getTextByKey("login_serverNew"))
        cell:getChildByName("login_txt_normal"):getChildByName("txt"):setString(getTextByKey("login_serverNomal"))
        cell:getChildByName("login_txt_crowd"):getChildByName("txt"):setString(getTextByKey("login_serverBusy"))
        cell:getChildByName("txt_full"):getChildByName("txt"):setString(getTextByKey("login_serverFull"))
        
        cell:getChildByName("login_txt_new"):getChildByName("txt"):setTag(txt_new_Tag)
        cell:getChildByName("login_txt_normal"):getChildByName("txt"):setTag(txt_normal_Tag)
        cell:getChildByName("login_txt_crowd"):getChildByName("txt"):setTag(txt_crowd_Tag)
        cell:getChildByName("txt_full"):getChildByName("txt"):setTag(txt_full_Tag)
        
        cell:getChildByName("login_txt_new"):setTag(txt_new_Tag)
        cell:getChildByName("login_txt_normal"):setTag(txt_normal_Tag)
        cell:getChildByName("login_txt_crowd"):setTag(txt_crowd_Tag)
        cell:getChildByName("txt_full"):setTag(txt_full_Tag)
        
        cell:getChildByName("txt_area"):getChildByName("txt"):setTag(txt_serverArea_Tag)
        cell:getChildByName("txt_server_name"):getChildByName("txt"):setTag(txt_serverName_Tag)
        
        cell:getChildByName("txt_area"):setTag(txt_serverArea_Tag)
        cell:getChildByName("txt_server_name"):setTag(txt_serverName_Tag)
        
        cell:getChildByName("yellow9_panel"):setTag(selected_effect_Tag)
        cell:getChildByName("lbl_loginnew_recently"):setTag(selected_ever_Tag)
        
        cell:setTag(cellTag)
		container:addChild(cell)
	end 
	
	function ServerCellRenderer:setData(rawCocosObj,index)
	    local cell = self:getChildByTag(rawCocosObj, cellTag)
	    if data[index + 1] then
           
            cell:getChildByTag(txt_new_Tag):setVisible(false)
            cell:getChildByTag(txt_normal_Tag):setVisible(false)
            cell:getChildByTag(txt_crowd_Tag):setVisible(false)
            cell:getChildByTag(txt_full_Tag):setVisible(false)
            
            local serverStatus = data[index + 1].serverStatus
            local serverInfo = data[index + 1].serverInfo
            if serverStatus == ServerStatusEnum.new then
                cell:getChildByTag(txt_new_Tag):setVisible(true)
            elseif serverStatus == ServerStatusEnum.normal then
                cell:getChildByTag(txt_normal_Tag):setVisible(true)
            elseif serverStatus == ServerStatusEnum.crowd then
                cell:getChildByTag(txt_crowd_Tag):setVisible(true)
            elseif serverStatus == ServerStatusEnum.full then
                cell:getChildByTag(txt_full_Tag):setVisible(true)
            end

            cell:getChildByTag(selected_ever_Tag):setVisible(selectedList[serverInfo.serverId] ~= nil)
            --这里不能用setString函数 modified by zheng.che @ 2014-6-23
            setNodeText(cell:getChildByTag(txt_serverArea_Tag):getChildByTag(txt_serverArea_Tag), getTextByKey("login_serverNo",{num=serverInfo.serverId}))
            setNodeText(cell:getChildByTag(txt_serverName_Tag):getChildByTag(txt_serverName_Tag), serverInfo.serverName)
	    end
	end 
	
	local function onListItemTouch( evt ) 
        --print("++++"..data[evt.data + 1].serverInfo.serverId)
        if not self.choseServerEnable then
            return
        end 
        self.choseServerEnable = false
        local closeScheduler = nil
        local function closeFunc()
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(closeScheduler)
		    ServerSelectPanel:onClosePanel(nil,data[evt.data + 1].serverInfo.serverId)
        end 
        local cell = self.tableUI:cellAtIndex(evt.data )
        cell:getChildByTag(cellTag):getChildByTag(selected_effect_Tag):setVisible(false)
        closeScheduler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(closeFunc,0.1,false)
        
        --ServerSelectPanel:onClosePanel(nil,data[evt.data + 1].serverInfo.serverId)
	end
		
    local cell_height = 115
    local cell_width = 550
	local list_height = 450
	local list_posY = 1050
    local renderer = ServerCellRenderer.new(cell_width, cell_height)
    local list = TableView:create(renderer, cell_width, list_height,cellTag,
                                  nil,
                                  CCScale9Sprite:create("pic/scroll.png"), 
                                  CCScale9Sprite:create("pic/scroll.png"))

    list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch ,list)
    list:setPosition(ccp(105, (list_posY-list_height)/2))	
    return list
end

function ServerSelectPanel:onClosePanel(evt,choseServerId)
    PopoutManager:sharedManager():pullin(ServerSelectPanelInstence, kPopoutDir.kScale )
    ServerSelectPanelInstence.container.targetInfoPanel = nil
    if ServerSelectPanelInstence.callBackFunc and type(ServerSelectPanelInstence.callBackFunc) == "function" then
        ServerSelectPanelInstence:callBackFunc(choseServerId)
    end 
end 
    
function ServerSelectPanel:initLayer()
    ServerSelectPanel.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/login_new.json")
    self.panelUI = builder:build("login_server_select")
    
    --init UI
    self.panelUI:getChildByName("txt_recent_server"):getChildByName("txt"):setString(getTextByKey("login_serverRecentLoginServer"))
    self.panelUI:getChildByName("txt_all_server"):getChildByName("txt"):setString(getTextByKey("login_serverAllServerTitle"))
    
    local lastChoseServerInfo = localStorage.getLastChoseServerInfo( ) 
	local lastChoseServerId = self.serverListInfo[1].serverInfo.serverId
	if lastChoseServerInfo == "" then
	    self.panelUI:getChildByName("server_select_bar"):setVisible(false)
	else
	    self.panelUI:getChildByName("server_select_bar"):setVisible(true)
        self.panelUI:getChildByName("server_select_bar"):getChildByName("lbl_loginnew_recently"):setVisible(false)
	    self.panelUI:getChildByName("server_select_bar"):getChildByName("login_txt_new"):setVisible(false)
	    self.panelUI:getChildByName("server_select_bar"):getChildByName("login_txt_normal"):setVisible(false)
	    self.panelUI:getChildByName("server_select_bar"):getChildByName("login_txt_crowd"):setVisible(false)
	    self.panelUI:getChildByName("server_select_bar"):getChildByName("txt_full"):setVisible(false)
	    
	    self.panelUI:getChildByName("server_select_bar"):getChildByName("login_txt_new"):getChildByName("txt"):setString(getTextByKey("login_serverNew"))
        self.panelUI:getChildByName("server_select_bar"):getChildByName("login_txt_normal"):getChildByName("txt"):setString(getTextByKey("login_serverNomal"))
        self.panelUI:getChildByName("server_select_bar"):getChildByName("login_txt_crowd"):getChildByName("txt"):setString(getTextByKey("login_serverBusy"))
        self.panelUI:getChildByName("server_select_bar"):getChildByName("txt_full"):getChildByName("txt"):setString(getTextByKey("login_serverFull"))
        
        self.panelUI:getChildByName("server_select_bar"):getChildByName("txt_area"):getChildByName("txt"):setString(getTextByKey("login_serverNo",{num=lastChoseServerInfo.serverInfo.serverId}))
        self.panelUI:getChildByName("server_select_bar"):getChildByName("txt_server_name"):getChildByName("txt"):setString(lastChoseServerInfo.serverInfo.serverName)
        
	    if lastChoseServerInfo.serverStatus == ServerStatusEnum.new then
            self.panelUI:getChildByName("server_select_bar"):getChildByName("login_txt_new"):setVisible(true)
        elseif lastChoseServerInfo.serverStatus == ServerStatusEnum.normal then
            self.panelUI:getChildByName("server_select_bar"):getChildByName("login_txt_normal"):setVisible(true)
        elseif lastChoseServerInfo.serverStatus == ServerStatusEnum.crowd then
            self.panelUI:getChildByName("server_select_bar"):getChildByName("login_txt_crowd"):setVisible(true)
        elseif lastChoseServerInfo.serverStatus == ServerStatusEnum.full then
            self.panelUI:getChildByName("server_select_bar"):getChildByName("txt_full"):setVisible(true)
        end
	end
	    
    ServerSelectPanelInstence = self
    local close_Btn = Button:create(self.panelUI:getChildByName("btn_close"))
    close_Btn:addEventListener(Events.kStart ,ServerSelectPanel.onClosePanel ) 
    
    self:addChild(self.panelUI)

    local userData = localStorage.getCurrentUser()
    if userData ~= "-1" and userData:split(",")[1] then 
        local function onGetLoginedServer( response )
            if response.body and response.body ~= "0" then
                local tab = response.body:split(",")
                for k,v in pairs(tab) do
                    selectedList[tonumber(v)] = true
                end
            end
            self.tableUI = self:createTableView(self.serverListInfo) 
            self:addChild(self.tableUI)
        end
    
        local url = DataManager.SystemConfig.GetLoginedServer .. "accountId=" .. userData:split(",")[1]
        local params = {}
        doHttpRequest(url, params, onGetLoginedServer, true, true)
    else
        self.tableUI = self:createTableView(self.serverListInfo) 
        self:addChild(self.tableUI)
    end 
    
end