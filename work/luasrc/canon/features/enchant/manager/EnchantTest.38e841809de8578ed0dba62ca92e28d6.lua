-- EnchantTest.lua
-- 2014-12-2
-- zheng.che
-- 装备附灵测试类 提供各种测试接口 方便管理

EnchantTest = {}

-- 总之是测试
function EnchantTest.test()
	local beginTime = TimeUtil.getServerTimeSeconds()
	local enchantInfo = EnchantUtils.findEnchantInfo(220031, 30)
	local endTime = TimeUtil.getServerTimeSeconds()
	print("enchantInfo = " .. tostringRich(enchantInfo))
	print("beginTime = " .. tostringRich(beginTime))
	print("endTime = " .. tostringRich(endTime))
	print("gapTime = " .. tostringRich(endTime - beginTime))
end