--
-- UnionNewsScene.lua
-- Author: zheng.che
-- Date: 2014-04-03 11:40:09
-- 军团消息场景
--
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

UnionInfoTagEnum = {
  INFO_LIST = 1,
}

local enter_animation_duration = 0.3
local selectedText = ""

-------------------------------------------------------------------------------
-- 内部可用函数
-------------------------------------------------------------------------------

--点击返回
local function onBackBtnClick(evt)
	evt.context:back()
end

--焦点变化事件
local function onFocusChanged(evt)
	--print("onFocusChanged! evt.data == nil = " .. tostring(evt.data == nil))
	evt.context:setTableViewsEnabled(evt.data == nil)
end

-------------------------------------------------------------------------------
-- 初始化处理
-------------------------------------------------------------------------------

UnionNewsScene = class(BaseUIScene)

function UnionNewsScene:ctor()
end

function UnionNewsScene:create(argv)
	local s = UnionNewsScene.new()
	if argv then 
		s.argv = argv 
	else
		s.argv = {enterScene=nil,returnScene=nil,params={}}
	end
	s.curSceneEnum = SceneEnum.UnionNewsScene

  s:initScene()
  return s
end

function UnionNewsScene:onInit()
	BaseUIScene.initBackGround(self)

	--用于生成新panle
	local function onCreatePanel(aIndex)
		--这里的3个列表效果一样 只有内容不同
		if aIndex == UnionInfoTagEnum.INFO_LIST then
			return UnionNewsListPanel:create(self, aIndex)
		end
		print("无效的panle编号! aIndex = " .. aIndex)
	end

	function refreshSelf()
	end
	self.refreshSelf = refreshSelf

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("guild_general_title")
	self:addChild(ui)
	self.ui = ui

	--静态文本
	self.ui:getChildByName("txt_guild_19"):getChildByName("txt"):setString(getTextByKey("union_dynamic_title"))--军团动态

	--其他按钮
	self.uiGroup3 = ui:getChildByName("r_click")
	self.backBtn = Button:create(self.uiGroup3)
	self.backBtn:addEventListener(Events.kStart, onBackBtnClick, self)

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

	--设定初始显示的页面为第一页
	self.tabChangeComponent = TabPanelChangeComponent.new(self, onCreatePanel, nil, nil, nil)
	self.tabChangeComponent:changeToPanelByIndex(UnionInfoTagEnum.INFO_LIST)

	self.refreshSelf()

	BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)
end

-----------------------------------------------内部接口------------------------------------------------------------

-----------------------------------------------外部接口------------------------------------------------------------

function UnionNewsScene:setTableViewsEnabled(enabled)
	if self.tabChangeComponent and self.tabChangeComponent.currentSelectedPanel then
		self.tabChangeComponent.currentSelectedPanel:setTableViewTouched(enabled)
	end
end

-----------------------------------------------进出场景动画------------------------------------------------------------
function UnionNewsScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function UnionNewsScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/background.mp3", true)
end

function UnionNewsScene:startEnterAnimation()
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

function UnionNewsScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function UnionNewsScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function UnionNewsScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)
end

function UnionNewsScene:startExitAnimation()
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

function UnionNewsScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景动画------------------------------------------------------------

-- 退出到外层
function UnionNewsScene:back()
	if UnionManager.isInUnion() then
		UnionManager.gotoUnionScene()
	else
		self:replaceScene(MainMenuScene)
	end
end

function UnionNewsScene:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)

	if self.tabChangeComponent then
		self.tabChangeComponent:dispose()
		self.tabChangeComponent = nil
	end

	UnionNewsScene.super.dispose(self)
end

-----------------------------------------------静态函数------------------------------------------------------------