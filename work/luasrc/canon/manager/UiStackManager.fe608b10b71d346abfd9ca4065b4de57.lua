--
-- UiStackManager.lua
-- Author: zheng.che
-- Date: 2014-03-18 15:34:38
-- 用于管理UI二级的堆栈记录 以及当前聚焦二级的查询
--

UiStackManager = class()

--------------------------------------------------------------------------------------------------外部可用接口

--堆栈
local stack = {}
local focus = nil
UiStackManager_EventDispatcher = EventDispatcher.new()
UiStackManager_EVENT_UPDATE = "UPDATE_FOCUS"

--------------------------------------------------------------
-- 增加一个二级ui到堆栈中
-- child 二级ui本体
--------------------------------------------------------------
function UiStackManager.push(child)
	if UiStackManager.indexOf(stack, child) ~= -1 then
		return
	end

	table.insert(stack, child)
	--print("UiStackManager.push! #stack = " .. #stack)
	UiStackManager.refreshFocus()
end


--------------------------------------------------------------
-- 将一个二级从堆栈中移除
-- child 二级ui本体
--------------------------------------------------------------
function UiStackManager.remove(child)
	local idx = UiStackManager.indexOf(stack, child)
	if idx == -1 then
		return
	end

	table.remove(stack, idx)
	--print("UiStackManager.remove! #stack = " .. #stack)

	UiStackManager.refreshFocus()
end


--------------------------------------------------------------
-- 清空数据 一般在切换场景时调用 在这里统一清除堆栈和侦听
--------------------------------------------------------------
function UiStackManager.clear()
	stack = {}
	UiStackManager_EventDispatcher:removeAllEventListeners()

	UiStackManager.refreshFocus()
end


--------------------------------------------------------------
-- 获得当前聚焦的二级(堆栈最外层)
--------------------------------------------------------------
function UiStackManager.getCurrentFocus()
	return focus
end


--------------------------------------------------------------
-- 当前面板是否在聚焦中(注意: 如果要判断scene则传nil)
--------------------------------------------------------------
function UiStackManager.isFocus(panel)
	if (UiStackManager.getCurrentFocus() == panel) then
		return true
	end
	return false
end

--------------------------------------------------------------------------------------------------内部函数

--------------------------------------------------------------
-- 刷新状态
--------------------------------------------------------------
function UiStackManager.refreshFocus()
	if #stack > 0 then
		focus = stack[#stack]
	else
		focus = nil
	end

	--这一段可能影响以前的逻辑
	-- local scene = Director:mgr():run()
	-- scene.targetInfoPanel = focus
	-- if (scene.setTableViewsEnabled) then
	-- 	scene:setTableViewsEnabled(focus == nil)
	-- end

	--print("UPDATE_FOCUS! ")
	UiStackManager_EventDispatcher:dispatchEvent(Event.new(UiStackManager_EVENT_UPDATE, focus))
end

function UiStackManager.indexOf(table, target)
	for k, v in ipairs(table) do
		if v == target then
			return k
		end
	end
	return -1
end