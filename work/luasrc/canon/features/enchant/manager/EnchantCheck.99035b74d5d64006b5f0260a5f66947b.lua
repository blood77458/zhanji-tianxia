-- EnchantCheck.lua
-- 2014-12-10
-- zheng.che
-- 装备附灵 条件检测

EnchantCheck = {}

-----------------------------------------------------------------------------------------------------------------查询

-- 查询装备是否附灵满级
-- currentLevel 当前等级
function EnchantCheck.isFullSkillLevel(currentLevel)
	if currentLevel < EnchantConfig.getMaxEnchantLevel() then
		return false
	end
	return true
end

-- 查询某件装备是否存在附灵信息
-- equipMetaId 装备的配置编号
function EnchantCheck.hasEnchantInfo(equipMetaId)
	local enchantMeta = EnchantConfig.getEnchantMeta(equipMetaId)
	if not enchantMeta then
		return false
	end
	return true
end

-----------------------------------------------------------------------------------------------------------------校验

-- 能否附灵
-- equipMetaId 装备的配置编号
function EnchantCheck.canEnchant(equipData)
	-- if SystemManager.debug then
	-- 	print("equipData = " .. tostringRich(equipData))
	-- end
	if not EnchantCheck.hasEnchantInfo(equipData.metaId) then
		--无附灵数据
		-- if SystemManager.debug then
		-- 	print("无附灵数据")
		-- end
		return false
	end

	if EnchantCheck.isFullSkillLevel(equipData.enchantLevel) then
		--已满级
		-- if SystemManager.debug then
		-- 	print("已满级")
		-- end
		return false
	end

	local enchantInfo = Enchant.findEnchantInfo(equipData.metaId, equipData.enchantLevel)--获得最新的附灵配置信息
	if EnchantData.getEnchantPoint() < enchantInfo.cost  then
		--剩余灵值不足
		-- if SystemManager.debug then
		-- 	print("剩余灵值不足! enchantInfo = " .. tostringRich(enchantInfo))
		-- end
		return false
	end

	return true
end

-- 查询是否允许进入附灵入口
function EnchantCheck.canEnterEnchant(withAlert)
	local config = DataManager.GameMetaData.enchantTotalConfig
	if not config then
		if SystemManager.debug then
			DebugManager.addError("装备附灵功能无后端配置, 无法开启! ")
		end
		return false
	end
	
	local needLevel = EnchantConfig.getEnchantsLevel()
	if DataManager.getGameInitData().sharkUser.level < needLevel then
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("module_needLevel", {num = needLevel}))--主公等级达到{num}解锁，继续努力吧！
		end
		return false
	end
	return true
end