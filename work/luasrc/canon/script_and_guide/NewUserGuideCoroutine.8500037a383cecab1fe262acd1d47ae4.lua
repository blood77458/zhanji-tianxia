--------------------------------------------------------------------------------
-- NewUserGuideCoroutine.lua - 新手引导Coroutine调度
-- author: litong.sun
-- date: 2014-04-09
--------------------------------------------------------------------------------

-- lua coroutine只能保存lua状态，不能保存c堆栈，因此跨越c部分的切换会报错。新手引导正常使用下不会碰到这个问题。
-- cocoutine中发生错误会直接终止coroutine, 不会输出到控制台, 调试时需要注意
-- coroutine是即时切换的没有延迟所以要注意调用的逻辑顺序

local waitingEventToCoroutine = {}
local waitingCoroutineToEvent = {}
local onFinishHandle = nil

local function resume(co)
	coroutine.resume(co)
	if onFinishHandle and coroutine.status(co) == "dead" then
		onFinishHandle()
	end
end

function RunGuideScript(path)
	path = string.gsub(path, "\\", ".")
	path = string.gsub(path, "/", ".")
	if string.sub(path, 1, 1) == "." then
		path = string.sub(path, 2)
	end
	if string.sub(path, -4) == ".lua" then
		path = string.sub(path, 1, -5)
	end
	local script = require(path) -- 手机上不能使用loadfile
	if type(script) == "function" then
		local co = coroutine.create(script)
		resume(co)
	end
end

function WaitEvent(keymap, timeout)
	local co = coroutine.running()
	if timeout and timeout > 0 then
		local handle = nil
		local function onTimeOut()
			RemoveWaitingCoroutine(co)
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(handle)
			resume(co)
		end
		handle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(onTimeOut, timeout, false)
	end
	if waitingCoroutineToEvent[co] == nil then
		waitingCoroutineToEvent[co] = {}
	end
	for k,v in pairs(keymap) do
		if waitingEventToCoroutine[k] == nil then
			waitingEventToCoroutine[k] = {}
		end
		waitingEventToCoroutine[k][v] = co
		waitingCoroutineToEvent[co][k] = v
	end
	coroutine.yield()
end

function FireEvent(key, value)
	if waitingEventToCoroutine[key] ~= nil and waitingEventToCoroutine[key][value] ~= nil then
		local co = waitingEventToCoroutine[key][value]
		waitingEventToCoroutine[key][value] = nil
		if next(waitingEventToCoroutine[key]) == nil then
			waitingEventToCoroutine[key] = nil
		end
		if waitingCoroutineToEvent[co] ~= nil then
			waitingCoroutineToEvent[co][key] = nil
		end
		if waitingCoroutineToEvent[co] == nil or next(waitingCoroutineToEvent[co]) == nil then
			waitingCoroutineToEvent[co] = nil
			resume(co)
		end
	end
end

function RemoveWaitingCoroutine(co)
	if waitingCoroutineToEvent[co] ~= nil then
		for k,v in pairs(waitingCoroutineToEvent[co]) do
			if waitingEventToCoroutine[k] ~= nil and waitingEventToCoroutine[k][v] ~= nil then
				waitingEventToCoroutine[k][v] = nil
				if next(waitingEventToCoroutine[k]) == nil then
					waitingEventToCoroutine[k] = nil
				end
			end
		end
		waitingCoroutineToEvent[co] = nil
	end
end

function ClearWaitingCoroutine()
	waitingEventToCoroutine = {}
	waitingCoroutineToEvent = {}
end

function RegisterOnGuideFinishCallback(func)
	onFinishHandle = func
end

function getGuideFinishCallback()
	return onFinishHandle
end
