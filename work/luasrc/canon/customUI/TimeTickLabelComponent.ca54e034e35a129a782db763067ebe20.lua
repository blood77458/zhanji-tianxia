--
-- TimeTickLabelComponent.lua
-- Author: zheng.che
-- Date: 2014-03-11 10:23:13
-- 倒计时组件
--

TimeTickLabelComponent = class()

----------------------------------------------
-- 初始化
----------------------------------------------
function TimeTickLabelComponent:ctor()
end

----------------------------------------------
-- 开始计时
----------------------------------------------
function TimeTickLabelComponent:startWith(aLabelDisplay, aTargetTime)
	self.labelDisplay = aLabelDisplay
	self.targetTime = aTargetTime

	if self:
end

----------------------------------------------
-- 是否已经到达目标时间
----------------------------------------------
function TimeTickLabelComponent:targetReached()
	local leftTime = self.targetTime - TimeUtil.getServerTimeSeconds()
	if leftTime <= 0 then
		return true
	end
	return false
end