--
-- CdLabelComponent.lua
-- Author: zheng.che
-- Date: 2014-03-11 10:23:13
-- 倒计时组件
--

CdLabelComponent = class()

----------------------------------------------
-- 初始化
----------------------------------------------
function CdLabelComponent:ctor()
end

----------------------------------------------
-- 创建
----------------------------------------------
function CdLabelComponent:create(extra)
	local s = CdLabelComponent.new()
	s.extra = extra
	return s
end

----------------------------------------------
-- 初始化信息
----------------------------------------------
function CdLabelComponent:setCallback(aTimeTickCallback, aCompleteCallback)
	self.timeTickCallback = aTimeTickCallback
	self.completeCallback = aCompleteCallback
	--self.labelDisplay = aLabelDisplay

	-- if not self.onDispose then
	-- 	function onDispose()
	-- 		print("onDispose!!!!!!!!!!!!")
	-- 		self:dispose()
	-- 		self.labelDisplay.dispose = self.labelDisplay.disposeInCdComponent
	-- 		self.labelDisplay:dispose()
	-- 	end
	-- 	self.onDispose = onDispose
	-- end

	-- if self.labelDisplay then
	-- 	if self.labelDisplay.dispose then
	-- 		print("self.labelDisplay.dispose have! ")
	-- 		self.labelDisplay.disposeInCdComponent = self.labelDisplay.dispose
	-- 		self.labelDisplay.dispose = self.onDispose
	-- 	end
	-- end
end

function CdLabelComponent:setTargetTime(aTargetTime)
	
	self.targetTime = aTargetTime
end

----------------------------------------------
-- 开始计时
----------------------------------------------
function CdLabelComponent:start()
	if not self.onTick then
		local function onTick()
			--print("onTick")
			local remainedSec = self.targetTime - TimeUtil.getServerTimeSeconds()
			
			if remainedSec < 0 then
				remainedSec = 0
			end

			if self.timeTickCallback then
				
				self.timeTickCallback(remainedSec , self.extra)
			end

			if remainedSec <= 0 then
				
				if self.completeCallback then
					self:stop()
					self.completeCallback(self.extra)
				end
			end
		end
		self.onTick = onTick
	end

	if (self.targetTime > TimeUtil.getServerTimeSeconds()) and (not self.tickEntry) then
		
		self.tickEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(self.onTick, 1, false)--间隔1s
		self.onTick()
	end
end

----------------------------------------------
-- 是否已经到达目标时间
----------------------------------------------
function CdLabelComponent:targetReached()
	local leftTime = self.targetTime - TimeUtil.getServerTimeSeconds()
	if leftTime <= 0 then
		return true
	end
	return false
end

----------------------------------------------
-- 停止计时
----------------------------------------------
function CdLabelComponent:stop()
	if self.tickEntry then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.tickEntry)
		self.tickEntry = nil
	end
end

----------------------------------------------
-- 销毁
----------------------------------------------

function CdLabelComponent:dispose()
	self:stop()

	self.onTick = nil
	self.timeTickCallback = nil
	self.completeCallback = nil
	self.targetTime = 0
end