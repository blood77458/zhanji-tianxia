-- ConstManager.lua
-- 2014-12-2
-- zheng.che
-- 定义系统常量 可附带转换函数但不要太多

ConstManager = {}

--------------------------------------------------------------------------------------------------------------------
-- 公共事件定义
--------------------------------------------------------------------------------------------------------------------

-- 战斗力显示更新事件 参数: 无
ConstManager.FIGHT_CAPACITY_SHOW_UPDATE = "FIGHT_CAPACITY_SHOW_UPDATE"

--------------------------------------------------------------------------------------------------------------------
-- 一级属性/二级属性 定义和转换
--------------------------------------------------------------------------------------------------------------------

--攻击
ConstManager.ATTR_ATK = 1
--防御
ConstManager.ATTR_DEF = 2
--血量
ConstManager.ATTR_HP = 3

--暴击
ConstManager.ATTR_CRT = 6
--韧性
ConstManager.ATTR_TOU = 7
--命中
ConstManager.ATTR_HIT = 8
--闪避
ConstManager.ATTR_EVA = 9
--格挡
ConstManager.ATTR_PAR = 10
--破击
ConstManager.ATTR_PRC = 11

--攻击加成百分比
ConstManager.ATTR_PERCENT_ATK = 12
--防御加成百分比
ConstManager.ATTR_PERCENT_DEF = 13
--生命加成百分比
ConstManager.ATTR_PERCENT_HP = 14

--一级属性列表
ConstManager.HEAD_ATTRS = {ConstManager.ATTR_ATK, ConstManager.ATTR_DEF, ConstManager.ATTR_HP}
--一级属性数量
ConstManager.HEAD_ATTR_COUNT = #ConstManager.HEAD_ATTRS

--全部属性列表
ConstManager.ALL_ATTRS = {	ConstManager.ATTR_ATK, 
							ConstManager.ATTR_DEF,
							ConstManager.ATTR_HP,
							ConstManager.ATTR_CRT,
							ConstManager.ATTR_TOU,
							ConstManager.ATTR_HIT,
							ConstManager.ATTR_EVA,
							ConstManager.ATTR_PAR,
							ConstManager.ATTR_PRC,
							}
--全部属性数量
ConstManager.TOTAL_ATTR_COUNT = #ConstManager.ALL_ATTRS

--加成百分比类属性 对应的属性编号
local _percentToAttrHash = {}
_percentToAttrHash[ConstManager.ATTR_PERCENT_ATK] = ConstManager.ATTR_ATK
_percentToAttrHash[ConstManager.ATTR_PERCENT_DEF] = ConstManager.ATTR_DEF
_percentToAttrHash[ConstManager.ATTR_PERCENT_HP] = ConstManager.ATTR_HP

--属性编号 对应的加成百分比类属性
local _attrToPercentHash = {}
_attrToPercentHash[ConstManager.ATTR_ATK] = ConstManager.ATTR_PERCENT_ATK
_attrToPercentHash[ConstManager.ATTR_DEF] = ConstManager.ATTR_PERCENT_DEF
_attrToPercentHash[ConstManager.ATTR_HP] = ConstManager.ATTR_PERCENT_HP

--查询该属性是否为百分比性质属性
function ConstManager.isPercentAttr(percentAttrId)
	local attrId = _percentToAttrHash[percentAttrId]
	return (attrId ~= nil)
end

--查询该百分比属性对应的原始属性
-- percentAttrId 百分比属性编号
-- return 对应的原始属性编号
function ConstManager.getPercentAttr(percentAttrId)
	local attrId = _percentToAttrHash[percentAttrId]
	return attrId
end

--查询该属性对应的百分比属性
-- attrId 对应的原始属性编号
-- return 百分比属性编号
function ConstManager.getAttrPercent(attrId)
	local percentAttrId = _attrToPercentHash[attrId]
	return percentAttrId
end

--------------------------------------------------------------------------------------------------------------------
-- 地区编号定义 需和配置保持一致
--------------------------------------------------------------------------------------------------------------------

--大陆地区
ConstManager.LOCATION_CN = 1
--台灣地區
ConstManager.LOCATION_TW = 2