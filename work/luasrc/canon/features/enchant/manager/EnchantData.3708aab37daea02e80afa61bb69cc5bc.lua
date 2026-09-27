-- EnchantData.lua
-- 2014-12-4
-- zheng.che
-- 装备附灵的数据管理

EnchantData = {}
EnchantData.guideEnchantNum = 200

--装备灵值
local _enchantPoint = nil--默认为空 退出时记得清空

----------------------------------------------------------------------------------------
-- 启动/清除
----------------------------------------------------------------------------------------
function EnchantData.startup()
end

function EnchantData.clear()
	_enchantPoint = nil
end

--------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
-- 装备灵值
----------------------------------------------------------------------------------------

--获取
function EnchantData.getEnchantPoint()
	if _enchantPoint == nil then
		_enchantPoint = DataManager.getGameInitData().sharkUser.spiritValue
	end
	return _enchantPoint
end

--设置
function EnchantData.setEnchantPoint(v)
	_enchantPoint = v
end