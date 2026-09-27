--
-- UnionListScene.lua
-- Author: zheng.che
-- Date: 2014-03-14 17:49:18
-- 军团列表界面
--

require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.request.UnionGetUnionListRequest"
require "canon.request.UnionGetMyApplyListRequest"
require "canon.request.UnionSearchRequest"
require "canon.customUI.TabPanelChangeComponent"
require "canon.panel.UnionListPanel"
require "canon.panel.UnionCreatePopPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

UnionListTagEnum = {
  UNION_LIST = 1,
  APPLY_LIST = 2,
  SEARCH_LIST = 3,
}

local enter_animation_duration = 0.3
local selectedText = ""

-------------------------------------------------------------------------------
-- 内部可用函数
-------------------------------------------------------------------------------

--点击军团列表
local function unionListTabButtonSelected(evt)
	local container = evt.context
	local function onSucceed(startNum, amount, requestEvent)
		--默认处理
		UnionGetUnionListRequest.onSucceedDefault(startNum, amount, requestEvent)

		container:gotoTagAndShowList(UnionListTagEnum.UNION_LIST, requestEvent.data.sharkUnionWrappers or {})

		container.refreshSelf()
	end
	UnionGetUnionListRequest.sendRequest(1, 20, onSucceed, UnionGetUnionListRequest.onFailedDefault)
end

--点击申请列表
local function myApplyListTabButtonSelected(evt)
	local container = evt.context
	local function onSucceed(requestEvent)
		--默认处理
		UnionGetMyApplyListRequest.onSucceedDefault(requestEvent)

		container:gotoTagAndShowList(UnionListTagEnum.APPLY_LIST, requestEvent.data.sharkUnionWrappers or {})
	end
	UnionGetMyApplyListRequest.sendRequest(onSucceed, UnionGetMyApplyListRequest.onFailedDefault)
end

--点击返回
local function onBackBtnClick(evt)
	evt.context:back()
end

--点击创建军团
local function onCreateUnionBtnClick(evt)
	evt.context.unionCreatePopPanel = UnionCreatePopPanel:create(evt.context)
	evt.context.targetInfoPanel = evt.context.unionCreatePopPanel
	PopoutManager:sharedManager():popout(evt.context.unionCreatePopPanel, kPopoutDir.kScale, true, false , evt.context)
end

--点击搜索
local function onSearchBtnClick(evt)
	local container = evt.context

	if UnionManager.canSearchTo(selectedText, true) then
		local function onSucceed(targetUnionName, requestEvent)
			--默认处理
			UnionSearchRequest.onSucceedDefault(targetUnionName, requestEvent)

			if #requestEvent.data.sharkUnionWrappers > 0 then
				container:gotoTagAndShowList(UnionListTagEnum.SEARCH_LIST, requestEvent.data.sharkUnionWrappers or {})
			else
				--没找到
				SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_search_button_click_remin2"))--您输入的军团不存在
			end
		end
		UnionSearchRequest.sendRequest(selectedText, onSucceed, UnionSearchRequest.onFailedDefault)
	end
end

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == nil)
end

-------------------------------------------------------------------------------
-- 初始化处理
-------------------------------------------------------------------------------

UnionListScene = class(BaseUIScene)

function UnionListScene:ctor()
end

function UnionListScene:create(argv)
	local s = UnionListScene.new()
	if argv then 
		s.argv = argv 
	else
		s.argv = {enterScene=nil,returnScene=nil,params={}}
	end
	s.curSceneEnum = SceneEnum.UnionListScene

  --当前显示中的列表内容(注意: 子panel可能读取)
  s.selectedDataList = {}
  s:initScene()
  return s
end

function UnionListScene:onInit()
	BaseUIScene.initBackGround(self)

	--用于生成新panle
	local function onCreatePanel(aIndex)
		--这里的3个列表效果一样 只有内容不同
		if aIndex == UnionListTagEnum.UNION_LIST then
			return UnionListPanel:create(self, aIndex)
		elseif aIndex == UnionListTagEnum.APPLY_LIST then
			return UnionListPanel:create(self, aIndex)
		elseif aIndex == UnionListTagEnum.SEARCH_LIST then
			return UnionListPanel:create(self, aIndex)
		end
		print("无效的panle编号! aIndex = " .. aIndex)
	end

	function refreshSelf()
		if UnionManager.isInJoinCD() and (not UnionManager.isInUnion()) then
			--不在军团 且有cd
			self.ui:getChildByName("txt_guild_36"):setVisible(true)
			self.cdLabelComponent:setTargetTime(UnionManager.getMyReactiveSeconds())
			self.cdLabelComponent:start()
		else
			self.ui:getChildByName("txt_guild_36"):setVisible(false)
			self.cdLabelComponent:stop()
		end

		if (self.tabChangeComponent.currentSelectedIndex == UnionListTagEnum.UNION_LIST) and (self.selectedDataList) and (#self.selectedDataList <= 0) then
			--当前页是军团列表 且没有内容
			self.ui:getChildByName("txt_guild_42"):setVisible(true)
		else
			self.ui:getChildByName("txt_guild_42"):setVisible(false)
		end
	end
	self.refreshSelf = refreshSelf

	function onTimeTick(remainedSec)
		local formatedTimeStr = TimeUtil.formatTime(remainedSec)
		self.ui:getChildByName("txt_guild_36"):getChildByName("txt"):setString(Localization:getInstance():getText("union_apply_cold_time_key", {num = formatedTimeStr}))--{num1}:{num2}:{num3}后可加入军团
	end
	self.onTimeTick = onTimeTick

	function onTimeComplete()
		self.refreshSelf()
	end
	self.onTimeComplete = onTimeComplete

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("guild_list_title")
	self:addChild(ui)
	self.ui = ui

	--静态文本
	ui:getChildByName("txt_guild_42"):getChildByName("txt"):setString(Localization:getInstance():getText("union_list_emputy_remind"))--没有军团

	--tab
	self.tabChangeComponent = TabPanelChangeComponent.new(self, onCreatePanel, nil, nil, nil)

	--tab按钮
	self.uiGroup1 = ui:getChildByName("btn_guild_list")
	self.uiGroup1:getChildByName("txt"):setString(Localization:getInstance():getText("union_list_name"))--军团列表
	self.tabButton1 = Button:create(self.uiGroup1)
	self.tabButton1:addEventListener(Events.kStart, unionListTabButtonSelected, self)
	self.tabChangeComponent:addTab(self.tabButton1)

	self.uiGroup2 = ui:getChildByName("btn_guild_list2")
	self.uiGroup2:getChildByName("txt"):setString(Localization:getInstance():getText("union_apply_list_name"))--已申请军团
	self.tabButton2 = CanonButton:create(self.uiGroup2)
	self.tabButton2:addEventListener(Events.kStart, myApplyListTabButtonSelected, self)
	self.tabChangeComponent:addTab(self.tabButton2)

	--其他按钮
	self.uiGroup3 = ui:getChildByName("r_click")
	self.backBtn = Button:create(self.uiGroup3)
	self.backBtn:addEventListener(Events.kStart, onBackBtnClick, self)

	self.uiGroup4 = ui:getChildByName("btn_create_guild")
	self.createUnionBtn = Button:create(self.uiGroup4)
	self.createUnionBtn:addEventListener(Events.kStart, onCreateUnionBtnClick, self)

	self.uiGroup5 = ui:getChildByName("btn_search")
	self.uiGroup5:getChildByName("txt"):setString(Localization:getInstance():getText("union_search_button"))--搜索
	self.searchBtn = Button:create(self.uiGroup5)
	self.searchBtn:addEventListener(Events.kStart, onSearchBtnClick, self)

	--初始化数据
	selectedText = ""

	--输入文本
	local function onTextInputEvent( evt )
		selectedText = self.editInputLabel:getText() 
		if selectedText == "" then
			ui:getChildByName("txt_search_txt"):getChildByName("txt"):setString(Localization:getInstance():getText("union_search_default_word_key"))--输入军团名称进行搜索
		else
			ui:getChildByName("txt_search_txt"):getChildByName("txt"):setString(selectedText)
		end
	end
	local inputBackground = ui:getChildByName("bg_guild_name")
	--local inputSize = inputBackground:getGroupBounds().size
	local inputSize = {width = 465, height = 43}--写死了 有没有办法获得资源宽高呢?
	local inputPos = inputBackground:getPosition()
	local inputSprite = Scale9Sprite:create("common/button.png")
	inputSprite:setAnchorPoint(ccp(0, 1))
	inputSprite:setOpacity(0)--隐藏九宫格
	self.editInputLabel = TextInput:create(CCSizeMake(inputSize.width, inputSize.height), inputSprite)
	self.editInputLabel:setPosition(ccp(inputPos.x + inputSize.width / 2, inputPos.y - inputSize.height / 2))
	self.editInputLabel.refCocosObj:setInputFlag( -100 ) -- 隐藏
	self.editInputLabel:setReturnType(kKeyboardReturnTypeDone)
	self.editInputLabel:addEventListener(kTextInputEvents.kChanged, onTextInputEvent)
	if __IOS then
		self.editInputLabel:setPlaceHolder(getTextByKey("union_search_default_word_key"))
		ui:getChildByName("txt_search_txt"):getChildByName("txt"):setVisible(false)
	end
	ui:addChild(self.editInputLabel)
	ui:getChildByName("txt_search_txt"):setZOrder(1001)
	ui:getChildByName("txt_search_txt"):getChildByName("txt"):setString(Localization:getInstance():getText("union_search_default_word_key"))--输入军团名称进行搜索

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

	--倒计时组件
	self.cdLabelComponent = CdLabelComponent:create()
	self.cdLabelComponent:setCallback(onTimeTick, onTimeComplete)

	--设定初始显示的页面为第一页
	self:gotoTagAndShowList(UnionListTagEnum.UNION_LIST, self.argv.params.topList)

	if UnionManager.isInUnion() then
		--当前玩家在军团中
		BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)

		--不显示
		self.uiGroup4:setVisible(false)
		self.uiGroup2:setVisible(false)

		self.createUnionBtn:setEnable(false)
	else
		--当前玩家不在军团中
		BaseUIScene.onInit(self)
		--设置最上方的home区域不显示 且不接受该区域的默认触摸事件
		self.BaseUi:getChildByName("home_menu_title"):setVisible(false)
		self.BaseUi:removeChild(self.mainActorTouchLayer)

		self.uiGroup4:setVisible(true)
		self.uiGroup2:setVisible(true)

		self.createUnionBtn:setEnable(true)

		--添加安卓设备返回按钮相关侦听
		self.onSystemBackClick = function()
			--registerBackKey("uniontBaseUIBackBt", self.backBtn)
			-- print("self.onSystemBackClick! ")
			if UiStackManager.isFocus(nil) then
				--是焦点
				--print("是焦点! ")
				self:back()
			end
		end
		self.onActionFinished = function()
			--print("self.onActionFinished! ")
			NotificationManager:addEventListener("SYSTEM_BACK_KEY_CLICK", self.onSystemBackClick)
		end
		NotificationManager:addEventListener("enterActionFinished", self.onActionFinished)
	end

	self.refreshSelf()
end

-----------------------------------------------内部接口------------------------------------------------------------

--显示某一页面的特定数据
function UnionListScene:gotoTagAndShowList(tagIndex, dataList)
	--假数据 自己测试时用 顺便定义格式
	-- dataList = {}
	-- dataList[1] = {}
	-- dataList[1].unionId = 1
	-- dataList[1].name = "牛逼闪闪的公会名字"
	-- dataList[1].declaration = "牛逼闪闪的公会宣言"
	-- dataList[1].level = 10
	-- dataList[1].memberNum = 11
	-- dataList[1].managerName = "我是军团长"
	-- dataList[1].managerLevel = 12
	-- dataList[1].rank = 1


	self.selectedDataList = dataList
	self.tabChangeComponent:changeToPanelByIndex(tagIndex)
end

-----------------------------------------------外部接口------------------------------------------------------------

function UnionListScene:setTableViewsEnabled(enabled)
	if self.tabChangeComponent.currentSelectedPanel then
		self.tabChangeComponent.currentSelectedPanel:setTableViewTouched(enabled)
	end

	if self.editInputLabel then
		self.editInputLabel:setEnabled(enabled)
	end
end

-----------------------------------------------进出场景动画------------------------------------------------------------
function UnionListScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function UnionListScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/background.mp3", true)
end

function UnionListScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	self.ui:setPositionX(self.ui:getPositionX() - visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))
end

function UnionListScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function UnionListScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function UnionListScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)
end

function UnionListScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))

	--同时当前选择页也退出动画 并行进行
	self.tabChangeComponent:startPanelExit(nil)
end

function UnionListScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景动画------------------------------------------------------------

-- 退出到外层
function UnionListScene:back()
	if UnionManager.isInUnion() then
		UnionManager.gotoUnionScene()
	else
		self:replaceScene(MainMenuScene)
	end
end

function UnionListScene:dispose()
	NotificationManager:removeEventListener("SYSTEM_BACK_KEY_CLICK", self.onSystemBackClick)
	NotificationManager:removeEventListener("enterActionFinished", self.onActionFinished)
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)

	if self.tabChangeComponent then
		self.tabChangeComponent:dispose()
		self.tabChangeComponent = nil
	end

	if self.cdLabelComponent then
		self.cdLabelComponent:dispose()
		self.cdLabelComponent = nil
	end

	UnionListScene.super.dispose(self)
end

-----------------------------------------------静态函数------------------------------------------------------------