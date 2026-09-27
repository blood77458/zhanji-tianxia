-- EnchantUtils.lua
-- 2014-11-28
-- zheng.che
-- 装备附灵工具

EnchantUtils = {}

-- 获得某件装备某等级的附灵信息
-- equipMetaId 装备的metaId 请保证传入的装备存在附灵信息(允许附灵)
-- enchantLevel 附灵等级
-- result 装备附灵信息
-- result.attrHash 附加属性查询表 key:属性编号 value:↓
-- result.attrHash[attrId].id 某个附加属性的属性编号
-- result.attrHash[attrId].num 某个附加属性的加成数值
-- result.skills 附加技能list
-- result.skills[n].openTimes 某技能触发次数
-- result.skills[n].id 某技能编号
-- result.skills[n].num 技能加成数值(属性则为增加数值 另外还可能是百分比数值)
-- result.skills[n].nextOpenLevel 下一次强化/觉醒所需等级 如果没有下一次 则为-1
-- result.cost 当前阶数升阶消耗
-- result.nextLevelSkillInfo 下一级触发的技能,没有则为nil 格式:{id=触发的技能编号, isNew=是否为技能觉醒}
-- 最后一次查询记录 缓存用 防止连续重复计算
local _tempLastEquipMetaId = nil
local _tempLastEnchantLevel = nil
local _tempLastResult = nil
function EnchantUtils.findEnchantInfo(equipMetaId, enchantLevel)
	if (_tempLastEquipMetaId==equipMetaId) and (_tempLastEnchantLevel==enchantLevel) and (_tempLastResult~=nil) then
		return _tempLastResult
	end

	--print("enchantLevel = " .. tostringRich(enchantLevel))
	local enchantMeta = EnchantConfig.getEnchantMeta(equipMetaId)
	--print("enchantMeta = " .. tostringRich(enchantMeta))
	if SystemManager.debug then
		DebugManager.assert(enchantMeta ~= nil, "EnchantUtils.findEnchantInfo 传入的装备并不支持附灵! equipMetaId = " .. tostringRich(equipMetaId))
	end
	local levelMeta = EnchantConfig.getLevelMeta(enchantLevel)
	local nextLevelMeta = EnchantConfig.getLevelMeta(enchantLevel + 1)
	--print("levelMeta = " .. tostringRich(levelMeta))
	local equipMeta = MetaManager.equip_meta[equipMetaId]
	--print("equipMeta = " .. tostringRich(equipMeta))
	local attrRatio = EnchantConfig.getAttrRatio(equipMeta.quality)/100--不同品质装备属性加成系数
	--print("attrRatio = " .. tostringRich(attrRatio))

	local result = {}
	result.attrHash = {}
	result.skills = {}
	result.cost = 0

	--增加一个属性的数值
	local function addAttrNum(attrId, num)
		local attrInfo = result.attrHash[attrId]
		if attrInfo == nil then
			attrInfo = {}
			attrInfo.id = attrId
			attrInfo.num = 0--最终的属性数值
			result.attrHash[attrId] = attrInfo
		end
		attrInfo.num = attrInfo.num + num
	end

	--计算一级属性加成
	local attrList = EnchantConfig.getAttrList(equipMetaId)
	local attrCount = #attrList
	--print("attrCount = " .. tostringRich(attrCount))
	local tempAttrPointHash = {}
	for i=1, enchantLevel, 1 do
		--print(i)
		local tempLevelMeta = EnchantConfig.getLevelMeta(i)
		
		--属性索引号 指第几个属性
		local attrIndex = math.mod(i - 1, attrCount) + 1
		local attrId = attrList[attrIndex]--属性类型编号
		local attrInfo = tempAttrPointHash[attrId]
		if attrInfo == nil then
			tempAttrPointHash[attrId] = 0
		end
		tempAttrPointHash[attrId] = tempAttrPointHash[attrId] + tempLevelMeta.EnchantNumber
	end
	for k, point in pairs(tempAttrPointHash) do
		--print("attrInfo = " .. tostringRich(attrInfo))
		local addPoint = point
		local addPointNum = EnchantConfig.getAttrAddPoint(k)--每等级增加的点数系数 比如攻击是1 血量是6
		--print("addPoint = " .. tostringRich(addPoint))
		local addNum = math.floor(addPoint * addPointNum * attrRatio)--每级附灵基础加成=品质系数*成长系数*属性类型成长系数
		addAttrNum(k, addNum)
	end

	--计算技能开启情况
	local allSkills = EnchantConfig.getSkills(equipMetaId, enchantMeta)
	local skillCount = #allSkills
	--print("allSkills = " .. tostringRich(allSkills))
	for i, skillId in ipairs(allSkills) do
		skillId = tonumber(skillId)
		local skillInfo = {}
		skillInfo.id = skillId--技能编号
		skillInfo.openTimes = 0--该技能触发的次数
		skillInfo.num = 0--技能加成点数
		skillInfo.nextOpenLevel = -1--下一次强化/觉醒所需等级 如果没有下一次 则为-1

		if levelMeta then
			--等级不是0
			skillInfo.openTimes = math.floor((levelMeta.skillTotalCount-i) / skillCount) + 1--开启等级/次数
		end

		if skillInfo.openTimes > 0 then
			--技能开启了
			local skillMeta = EnchantConfig.getSkillMeta(skillId)
			local levelPoint = skillMeta.levelPoints[skillInfo.openTimes]
			if SystemManager.debug then
				DebugManager.assert(levelPoint ~= nil, "隐藏技能缺少开启等级配置! skillId = " .. tostringRich(skillId) .. ", skillInfo.openTimes = " .. tostringRich(skillInfo.openTimes))
			end
			if ConstManager.isPercentAttr(skillMeta.EnchantSkillType) then
				--是百分比加成 不取整
				skillInfo.num = levelPoint * attrRatio--技能加成=技能加成系数*品质系数
			else
				skillInfo.num = math.floor(levelPoint * attrRatio)--技能加成=技能加成系数*品质系数
			end

			addAttrNum(skillMeta.EnchantSkillType, skillInfo.num)
		end

		--计算下一次强化/觉醒等级
		local nextTotalOpenTimes = skillInfo.openTimes * skillCount + i--下一次强化/觉醒的总开启技能数
		local needLevel = EnchantConfig.getMinLevelByTotleOpenTimes(nextTotalOpenTimes)--达到此技能数所需的最低等级
		if needLevel ~= nil then
			--有所需等级
			skillInfo.nextOpenLevel = needLevel
		else
			--没有下一级了
			skillInfo.nextOpenLevel = -1
		end

		table.insert(result.skills, skillInfo)
	end

	--计算百分比加成(最后算)
	for i, skillInfo in ipairs(result.skills) do
		if skillInfo.openTimes > 0 then
			local skillMeta = EnchantConfig.getSkillMeta(skillInfo.id)
			local addAttrId = ConstManager.getPercentAttr(skillMeta.EnchantSkillType)--百分比对应的属性编号
			if addAttrId ~= nil then
				local addAttrInfo = result.attrHash[addAttrId]
				if addAttrInfo then
					-- print("addAttrInfo = " .. tostringRich(addAttrInfo))
					-- print("skillInfo = " .. tostringRich(skillInfo))
					addAttrInfo.num = math.floor(addAttrInfo.num * (1+skillInfo.num/100))--得到加成结果
				end
			end
		end
	end

	if not EnchantCheck.isFullSkillLevel(enchantLevel) then
		--没满级

		--计算本次升级消耗
		local nextLevelMeta = EnchantConfig.getLevelMeta(enchantLevel + 1)
		local tempCost = nextLevelMeta.costHash[equipMeta.quality]
		if SystemManager.debug then
			DebugManager.assert(tempCost ~= nil, "未找到此装备的下一等级附灵消耗(请检查quality属性)! equipMeta = " .. tostringRich(equipMeta) .. ", enchantLevel = " .. tostringRich(enchantLevel))
		end
		result.cost = tempCost

		--计算下一级预告
		if nextLevelMeta.EnchantSkill == 2 then
			--有技能
			result.nextLevelSkillInfo = {}

			local nextSkillIndex = math.mod(nextLevelMeta.skillTotalCount - 1, skillCount) + 1
			local mextSkillId = allSkills[nextSkillIndex]
			result.nextLevelSkillInfo.id = mextSkillId--下一级对应的技能
			result.nextLevelSkillInfo.isNew = (nextSkillIndex == nextLevelMeta.skillTotalCount)--是否新触发技能
		end
	else
		--满级
		result.cost = 0
	end


	_tempLastEquipMetaId = equipMetaId
	_tempLastEnchantLevel = enchantLevel
	_tempLastResult = result

	if SystemManager.debug then
		--print("result == " .. tostringRich(result))
	end

	return result
end

-- 获得某一等级增加的一级属性信息
-- return 技能描述文字
function EnchantUtils.getLevelAddAttrInfo(equipMetaId, enchantLevel)
	local result = {}

	local equipMetaData = MetaManager.equip_meta[equipMetaId]

	local attrRatio = EnchantConfig.getAttrRatio(equipMetaData.quality)/100--不同品质装备属性加成系数
	local attrList = EnchantConfig.getAttrList(equipMetaId)--该装备的全部附灵属性列表
	local attrCount = #attrList--
	local attrIndex = math.mod(enchantLevel - 1, attrCount) + 1--属性所处的位置
	local attrId = attrList[attrIndex]--属性类型编号
	local levelMeta = EnchantConfig.getLevelMeta(enchantLevel)--附灵等级配置
	local addPoint = levelMeta.EnchantNumber--该等级属性增加的点数
	local addPointNum = EnchantConfig.getAttrAddPoint(attrId)--等级增加的点数系数 比如攻击是1 血量是6
	--print("addPoint = " .. tostringRich(addPoint))
	local addNum = addPoint * addPointNum * attrRatio--每级附灵基础加成=品质系数*成长系数*属性类型成长系数

	result.attrId = attrId--属性类型编号
	result.addNum = addNum--属性增加值
	return result
end

-- 获得装备某技能首次开启增加属性点数
function EnchantUtils.findSkillAddNum(equipMetaId, enchantSkillMetaId, openTimes)
	local equipMetaData = MetaManager.equip_meta[equipMetaId]
	local attrRatio = EnchantConfig.getAttrRatio(equipMetaData.quality)/100--不同品质装备属性加成系数

	local skillMeta = EnchantConfig.getSkillMeta(enchantSkillMetaId)
	local levelPoint = skillMeta.levelPoints[openTimes]
	if SystemManager.debug then
		DebugManager.assert(levelPoint ~= nil, "EnchantUtils.findSkillAddNum 隐藏技能缺少开启等级配置! equipMetaData = " .. tostringRich(equipMetaData) .. ", skillMeta = " .. tostringRich(skillMeta) .. ", openTimes = " .. tostringRich(openTimes))
	end

	if ConstManager.isPercentAttr(skillMeta.EnchantSkillType) then
		--是百分比类型 不取整
		return levelPoint * attrRatio
	end
	--点数类型 取整
	return math.floor(levelPoint * attrRatio)--技能加成=技能加成系数*品质系数
end

-- -- 获得装备某技能的开启等级 暂时不需要了
-- function EnchantUtils.findSkillFirstOpenLevel(equipMetaId, enchantSkillMetaId)
-- 	local allSkills = EnchantConfig.getSkills(equipMetaId)
-- 	local skillCount = #allSkills
-- 	for i, tempSkillId in ipairs(allSkills) do
-- 		tempSkillId = tonumber(tempSkillId)
-- 		if tempSkillId == enchantSkillMetaId then
-- 			--是想要的技能
-- 			for level = 1, EnchantConfig.getMaxEnchantLevel() do
-- 				local levelMeta = EnchantConfig.getLevelMeta(level)--附灵等级配置
-- 				if levelMeta.skillTotalCount >= i then
-- 					--技能出现总次数达到技能索引号 就是第一次出现技能的等级了
-- 					return level
-- 				end
-- 			end
-- 		end
-- 	end
-- 	return 0
-- end

-- -- 下一等级是否有技能觉醒 暂时不需要了
-- function EnchantUtils.nextLevelAddSkill(equipMetaId, enchantInfo, currentLevel)
-- 	for i, v in ipairs(enchantInfo.skills) do
-- 		if v.openTimes <= 0 then
-- 			local needLevel = EnchantUtils.findSkillFirstOpenLevel(equipMetaId, v.skillId)
-- 			if (currentLevel + 1) >= needLevel then
-- 				return true
-- 			end
-- 		end
-- 	end
-- 	return false
-- end

--------------------------------------------------------------------------------------------------------------------------------------文字相关

-- 获得隐藏技能名称
-- enchantSkillMetaId 技能编号
-- openTimes 显示+几 穿nil则只返回默认名称
-- return 技能名称文字
function EnchantUtils.getSkillName(enchantSkillMetaId, openTimes)
	local skillMeta = EnchantConfig.getSkillMeta(enchantSkillMetaId)
	local result = Localization:getInstance():getText(skillMeta.EnchantSkillName)
	if openTimes and (openTimes~=0) then
		result = result .. "+" .. openTimes
	end
	return result
end

-- 获得隐藏技能描述
-- return 技能描述文字
function EnchantUtils.getSkillDesc(enchantSkillMetaId, addNum)
	local skillMeta = EnchantConfig.getSkillMeta(enchantSkillMetaId)
	if ConstManager.isPercentAttr(skillMeta.EnchantSkillType) then
		--是百分比属性
		addNum = addNum .. "%"
	end
	return Localization:getInstance():getText(skillMeta.EnchantSkillDes, {n = addNum})
end

-- 获得附灵等级的显示内容
function EnchantUtils.getEnchantLevelStr(enchantLevel)
	local enchantLevelStr = "+" .. enchantLevel
	if EnchantCheck.isFullSkillLevel(enchantLevel) then
		enchantLevelStr = enchantLevelStr .. Localization:getInstance():getText("enchant_12")--MAX！
	end
	return enchantLevelStr
end

--------------------------------------------------------------------------------------------------------------------------------------ui相关

--显示附加属性内容
function EnchantUtils.setAttrShow(attrDisplay, attrType, attrNumStr, colorType)
	attrDisplay:getChildByName("icon_atk"):setVisible(false)
	attrDisplay:getChildByName("icon_hp"):setVisible(false)
	attrDisplay:getChildByName("icon_def"):setVisible(false)
	attrDisplay:getChildByName("txt_03"):setVisible(false)
	attrDisplay:getChildByName("txt_02"):setVisible(false)

	--显示属性图标
	if attrType == ConstManager.ATTR_ATK then
		attrDisplay:getChildByName("icon_atk"):setVisible(true)
	elseif attrType == ConstManager.ATTR_DEF then
		attrDisplay:getChildByName("icon_def"):setVisible(true)
	elseif attrType == ConstManager.ATTR_HP then
		attrDisplay:getChildByName("icon_hp"):setVisible(true)
	end

	--显示属性值
	attrDisplay:getChildByName("txt_02"):getChildByName("txt"):setString(attrNumStr)
	attrDisplay:getChildByName("txt_03"):getChildByName("txt"):setString(attrNumStr)
	if colorType == 1 then
		--显示包边字
		attrDisplay:getChildByName("txt_02"):setVisible(true)
		attrDisplay:getChildByName("txt_02"):getChildByName("txt"):setColor(ccc3(255, 255, 255))
		attrDisplay:getChildByName("txt_02"):getChildByName("txt"):setAroundColor(ccc3(90, 14, 14))
	else
		--显示非包边字
		attrDisplay:getChildByName("txt_03"):setVisible(true)
		--attrDisplay:getChildByName("txt_03"):getChildByName("txt"):setColor(ccc3(70, 40, 255))
	end
end

--显示附加属性内容 tag版
function EnchantUtils.setAttrShowAsTag(attrDisplay, attrType, attrNumStr, colorType)
	attrDisplay:getChildByTag(-11):setVisible(false)
	attrDisplay:getChildByTag(-12):setVisible(false)
	attrDisplay:getChildByTag(-13):setVisible(false)
	attrDisplay:getChildByTag(-14):setVisible(false)
	attrDisplay:getChildByTag(-15):setVisible(false)

	--显示属性图标
	if attrType == ConstManager.ATTR_ATK then
		attrDisplay:getChildByTag(-11):setVisible(true)
	elseif attrType == ConstManager.ATTR_DEF then
		attrDisplay:getChildByTag(-13):setVisible(true)
	elseif attrType == ConstManager.ATTR_HP then
		attrDisplay:getChildByTag(-12):setVisible(true)
	end

	--显示属性值
	setNodeText(attrDisplay:getChildByTag(-14):getChildByTag(-11), attrNumStr)
	setNodeText(attrDisplay:getChildByTag(-15):getChildByTag(-11), attrNumStr)
	if colorType == 1 then
		--显示包边字
		attrDisplay:getChildByTag(-15):setVisible(true)
		attrDisplay:getChildByTag(-15):getChildByTag(-11):setCenterColor(ccc3(255, 255, 255))
		attrDisplay:getChildByTag(-15):getChildByTag(-11):setAroundColor(ccc3(90, 14, 14))
	else
		--显示非包边字
		attrDisplay:getChildByTag(-14):setVisible(true)
	end
end