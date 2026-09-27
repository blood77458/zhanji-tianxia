-- Enchant.lua
-- 2014-11-28
-- zheng.che
-- 装备附灵
-- 提供外部功能操作此功能的各种入口函数 尽量不关心内部结构
-- 特殊情况允许破例 使用内部的接口或者常量 但须在调用处注释说明
-- ENCHANT_MODIFY 装备附灵相关修改 搜索用关键字

require "canon.features.enchant.manager.EnchantConfig"
require "canon.features.enchant.manager.EnchantUtils"
require "canon.features.enchant.manager.EnchantTest"
require "canon.features.enchant.manager.EnchantData"
require "canon.features.enchant.manager.EnchantCheck"

require "canon.features.enchant.scene.EnchantScene"
require "canon.features.enchant.panel.EnchantGuideRewardPanel"

require "canon.features.enchant.request.EnchantUpgradeRequest"
require "canon.features.enchant.request.GetEnchantStepRewardRequest"

Enchant = {}

--------------------------------------------------------------------------------------------------
-- 启动/清除
--------------------------------------------------------------------------------------------------
function Enchant.startup()
	EnchantConfig.startup()
	EnchantData.startup()
end

function Enchant.clear()
	EnchantConfig.clear()
	EnchantData.clear()
end

--------------------------------------------------------------------------------------------------
-- 对外接口
--------------------------------------------------------------------------------------------------

--功能是否已启用
function Enchant.enabled()
	local config = DataManager.GameMetaData.enchantTotalConfig
	if not config then
		if SystemManager.debug then
			DebugManager.addError("装备附灵功能无后端配置, 无法开启! ")
		end
		return false
	end
	return true
end

--能否进入附灵入口
function Enchant.canEnterEnchant(withAlert)
	return EnchantCheck.canEnterEnchant(withAlert)
end

-- 获得某件装备某等级的附灵信息
-- equipMetaId 装备的metaId
-- enchantLevel 附灵等级
-- result 装备附灵信息
-- result.attrHash 附加属性查询表 key:属性编号 value:↓
-- result.attrHash[attrId].id 某个附加属性的属性编号
-- result.attrHash[attrId].num 某个附加属性的加成数值
-- result.skills 附加技能list
-- result.skills[n].openLevel 某技能触发次数
-- result.skills[n].id 某技能编号
-- result.skills[n].num 技能加成数值(属性则为增加数值 另外还可能是百分比数值)
function Enchant.findEnchantInfo(equipMetaId, enchantLevel)
	if not Enchant.enabled() then
		return nil
	end
	return EnchantUtils.findEnchantInfo(equipMetaId, enchantLevel)
end

--查询某件装备是否存在附灵信息
function Enchant.hasEnchantInfo(equipMetaId)
	if not Enchant.enabled() then
		return false
	end
	return EnchantCheck.hasEnchantInfo(equipMetaId)
end

-- 查询某件装备是否支持附灵
-- equipMetaId 装备的配置编号
function Enchant.isSupportToEnchant(equipMetaId)
	return EnchantCheck.hasEnchantInfo(equipMetaId)
end

--------------------------------------------------------------------------------------------------
-- 跳转
--------------------------------------------------------------------------------------------------

-- 进入附灵场景
-- equipData 要附灵的装备数据引用
function Enchant.gotoEnchantScene(equipData, enterScene, returnScene,argvs)
	local scene = Director:mgr():run()
    if argvs then
    	scene:replaceScene(EnchantScene, argvs)
    else
		local argv = {}
		argv.enterScene = enterScene
		argv.returnScene = returnScene
		
		argv.params = {}
		argv.params.equipData = equipData

		scene:replaceScene(EnchantScene, argv)
	end
end