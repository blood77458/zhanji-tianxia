--
-- TabPanelChangeComponent
-- Author: czh
-- Date: 2014-02-13 11:53:28
--

-- 还差: 

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15

TabPanelChangeComponent = class(nil)

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

----------------------------------------------
-- 
----------------------------------------------
function TabPanelChangeComponent:ctor(aContainer, aCreatePanelCallback, aCallBackBeforeChange, aStartExitCallback, aStartEnterCallback)
	--所在容器 用于遮蔽用户操作
	self.container = aContainer
	--生成panel的回调函数 必须有
	self.createPanelCallback = aCreatePanelCallback

	--在change启动之前调用此函数 如果没有则跳过 参数(目标panel编号)
	self.callBackBeforeChange = aCallBackBeforeChange
	--在当前panel要退出时调用 如果没有则跳过 参数(即将退出panel编号)
	self.startExitCallback = aStartExitCallback
	--在目标panel要出现时调用 如果没有则跳过 参数(即将出现panel编号)
	self.startEnterCallback = aStartEnterCallback

	--当前选择位置 默认不存在
	self.currentSelectedIndex = -1
	--当前选择panel 默认空
	self.currentSelectedPanel = nil
	--目标位置 默认不存在
	self.targetSelectedIndex = -1

	--全部tab列表
	self.tabButons = {}
end

----------------------------------------------
-- 添加一个新的按钮和生成对应panel的callback
-- 其中panel需要具有以下函数: 
-- setTableViewTouched(bool)
-- panelEnter(callback)
-- panelExit(callback)
----------------------------------------------
function TabPanelChangeComponent:addTab(aTabButton)
	table.insert(self.tabButons, aTabButton)
end

-----------------------------------------------逻辑部分------------------------------------------------------------

----------------------------------------------
-- 查询是否可以切换到此页签
----------------------------------------------
function TabPanelChangeComponent:canChangeTo(aIndex)
	if self.currentSelectedIndex == aIndex then
		--已经在此标签上
		return false
	end
	if self.targetSelectedIndex == aIndex then
		--正在切换 且目标和当前一样
		return false
	end
	return true
end

----------------------------------------------
-- 
----------------------------------------------
function TabPanelChangeComponent:changeToPanelByIndex(aIndex)
	--校验
	if not self:canChangeTo(aIndex) then
		--不能切换
		return
	end

	self.targetSelectedIndex = aIndex

	local function onComplete()
		self:startChange(aIndex)
	end

	-- --校验 (已删除 因为可能有非实体按钮的翻页操作! by zheng.che @ 2014-3-18)
	-- if (aIndex <= 0) or (aIndex > #self.tabButons) then
	-- 	print("试图进入的页面编号超出范围! aIndex = " .. aIndex)
	-- 	return
	-- end

	--local targetPanel = self:getPanelByIndex(aIndex)
	--local currentPanel = self:getCurrentPanel()

	if self.callBackBeforeChange then
		self.callBackBeforeChange(aIndex, onComplete)
	else
		self:startChange(aIndex)
	end
end

----------------------------------------------
-- 开始转换
----------------------------------------------
function TabPanelChangeComponent:startChange(aIndex)

	--进入新panel完毕
	local function panelEnterFinished()
		self:enableUserInterface()
	end
	--退出旧panel完毕
	local function panelExitFinished()
		self:enableUserInterface()
		if self.currentSelectedPanel then
			--帮容器清除旧panel
			self.container:removeChild(self.currentSelectedPanel, true)
			self.currentSelectedPanel = nil
		else
			print("TabPanelChangeComponent:panelExitFinished self.currentSelectedPanel为空")
		end

		--改变选择目标
		self:updateState(aIndex)

		self:startPanelEnter(panelEnterFinished)
	end

	---------------------------
	if self.currentSelectedIndex == -1 then
		--之前没有显示过 直接播enter动画
		--改变选择目标
		self:updateState(aIndex)
		self:startPanelEnter(panelEnterFinished)
	else
		--当前有显示 先播exit动画
		self:startPanelExit(panelExitFinished)
	end
end

----------------------------------------------
-- 改变选择目标
----------------------------------------------
function TabPanelChangeComponent:updateState(aIndex)
	--改变选择目标
	self.currentSelectedIndex = aIndex
	self.targetSelectedIndex = -1

	if self.currentSelectedPanel and self.currentSelectedPanel.dispose then
		self.currentSelectedPanel:dispose()
	end
	self.currentSelectedPanel = self:getNewPanelByIndex(self.currentSelectedIndex)

	if self.currentSelectedPanel then
		--帮容器添加新panel
		self.container:addChild(self.currentSelectedPanel)
	else
		print("TabPanelChangeComponent:updateState self.currentSelectedPanel为空")
	end

	--按钮显示状态变化
	for i, v in ipairs(self.tabButons) do
		if i == aIndex then
			-- 亮 不可点
			if v.display:getChildByName("btn_tab_active") then
				v.display:getChildByName("btn_tab_active"):setVisible(true)
			end
			if v.display:getChildByName("btn_tab_inactive") then
				v.display:getChildByName("btn_tab_inactive"):setVisible(false)
			end
			v:setEnable(false)
		else
			-- 灭 可点
			if v.display:getChildByName("btn_tab_active") then
				v.display:getChildByName("btn_tab_active"):setVisible(false)
			end
			if v.display:getChildByName("btn_tab_inactive") then
				v.display:getChildByName("btn_tab_inactive"):setVisible(true)
			end
			v:setEnable(true)
		end
	end
end

----------------------------------------------
-- 禁止玩家的操作
----------------------------------------------
function TabPanelChangeComponent:disableUserInterface()
	if self.tempLayer then
		--防止重复遮挡
		self:enableUserInterface()
	end
	self.tempLayer = Layer:create()
	self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self.container:addChild(self.tempLayer)

	local scene = Director:mgr():run()
	scene.targetInfoPanel = self.tempLayer

	if self.currentSelectedPanel and self.currentSelectedPanel.setTableViewTouched then
		self.currentSelectedPanel:setTableViewTouched(false)
	end
end

----------------------------------------------
-- 启用玩家的操作
----------------------------------------------
function TabPanelChangeComponent:enableUserInterface()
	if self.tempLayer then
		self.tempLayer:removeFromParentAndCleanup(true)

		local scene = Director:mgr():run()
		scene.targetInfoPanel = nil

		if self.currentSelectedPanel and self.currentSelectedPanel.setTableViewTouched then
			self.currentSelectedPanel:setTableViewTouched(true)
		end
	end
end

----------------------------------------------
-- 开始进入新panel(动画)
----------------------------------------------
function TabPanelChangeComponent:startPanelEnter(aCompleteCallBack)
	self:disableUserInterface()
	if self.currentSelectedPanel and self.currentSelectedPanel.panelEnter then
	    self.currentSelectedPanel:panelEnter(aCompleteCallBack)
	else
		--此处为调用失败情况 跳过上述处理
		aCompleteCallBack()
	end

    if self.startEnterCallback then
    	--通知外界即将进入新场景
    	self.startEnterCallback(self.currentSelectedIndex)
    end
end

----------------------------------------------
-- 开始退出旧panel(动画)
----------------------------------------------
function TabPanelChangeComponent:startPanelExit(aCompleteCallBack)
	self:disableUserInterface()
	if self.currentSelectedPanel and self.currentSelectedPanel.panelExit then
	    self.currentSelectedPanel:panelExit(aCompleteCallBack)
	else
		--此处为调用失败情况 跳过上述处理
		if aCompleteCallBack then
			aCompleteCallBack()
		end
	end
	
    if self.startExitCallback then
    	--通知外界即将退出旧场景
    	self.startExitCallback(self.currentSelectedIndex)
    end
end

-----------------------------------------------资料存取------------------------------------------------------------

----------------------------------------------
-- 通过索引号获得对应panel
----------------------------------------------
function TabPanelChangeComponent:getNewPanelByIndex(aIndex)
	return self.createPanelCallback(aIndex)
end

-- ----------------------------------------------
-- -- 获得当前选择的panel
-- ----------------------------------------------
-- function TabPanelChangeComponent:getCurrentPanel()
-- 	print("getCurrentPanel! ")
-- 	if self.currentSelectedIndex == -1 then
-- 		return nil
-- 	end
-- 	return self:getPanelByIndex(self.currentSelectedIndex)
-- end

----------------------------------------------
-- 清除自身
----------------------------------------------
function TabPanelChangeComponent:dispose()
	self.container = nil
	self.callBackBeforeChange = nil
	self.startExitCallback = nil
	self.startEnterCallback = nil
	self.createPanelCallback = nil

	self.currentSelectedIndex = -1
	self.currentSelectedPanel = nil

	for i, v in ipairs(self.tabButons) do
		v:dispose()
	end

	self.tabButons = {}
end




