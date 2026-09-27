-- EnchantConfig.lua
-- 2014-11-28
-- zheng.che
-- 装备附灵配置管理

EnchantConfig = {}

-- 装备查询id分隔符 (品质#部位)
EnchantConfig.SEP_SEARCH_ID = "#"

-- 装备信息 -> 附灵信息 查询表
-- key 装备查询id (装备metaId 或者 品质#部位)
-- value 触发的隐藏技能列表
-- 原表参数格式 {EquipmentId=0,Quality=4,Parts=2,EnchantSkill="10005|10007|10009|10011"},
-- 附加参数格式 {skills={111,222,333,444}}
local _euqipToEnchantHash = nil

-- 附灵等级对应数据的哈希表
-- key 附灵等级
-- value 附灵消耗数值等
-- 原表参数格式 {EnchantLevel=1,EnchantCost3=100,EnchantCost4=200,EnchantCost5=400,EnchantCost6=800,EnchantCost7=1000,EnchantNumber=1,EnchantSkill=1},
-- 附加参数格式 {costHash={[3]=100,[4]=200,[5]=400,[6]=800,[7]=1000}, skillTotalCount=12}
local _enchantLevelHash = nil

-- 每次附灵增加一级属性类型的哈希表
-- key 装备部位
-- value 一级属性类型列表
-- 原表参数格式 {EquipmentType=1,EnchantType="2|3"},
-- 附加参数格式 {addAttrs={2,3}}
local _enchantAttrHash = nil

-- 附灵隐藏技能哈希表
-- key 技能id
-- value 技能名称 说明 加成类型
-- 原表参数格式 {EnchantSkillId=10009,EnchantSkillName="10009_n",EnchantSkillDes="10009_des",EnchantSkillType=9},
-- 附加参数格式 {levelPoints={1=4,2=5,3=6}}
local _enchantSkillHash = nil

-- 每加一点增加的属性值系数哈希表
-- key 属性类型
-- value 增加的属性值大小
local _attrAddPointHash = nil

-- 不同品质的装备增加系数百分比
-- key 装备品质
-- value 系数百分比
local _attrRatioHash = nil

-- 附灵最大等级
local _maxEnchantLevel = 0

-- 通过技能开启次数获得所需最低等级的哈希表
-- key 全部技能的加成次数总和
-- value 达成此加成次数所需的最低等级
local _openTimesHash = nil

----------------------------------------------------------------------------------------
-- 启动
----------------------------------------------------------------------------------------
function EnchantConfig.startup()
	if _euqipToEnchantHash == nil then
		_euqipToEnchantHash = {}
		local equipment_skill = require "canon.configs.equipment_skill"
		for i, v in ipairs(equipment_skill) do
			local searchId
			if v.EquipmentId ~= 0 then
				searchId = tostring(v.EquipmentId)
			else
				searchId = v.Quality .. EnchantConfig.SEP_SEARCH_ID .. v.Parts--品质#部位
			end

			if v.EnchantSkill == 0 then
				v.skills = {}
			else
				v.skills = string.split(v.EnchantSkill, "|")
				for k, w in ipairs(v.skills) do
					v.skills[k] = tonumber(w)
				end
			end

			--删除不用的信息
			v.EnchantSkill = nil

			_euqipToEnchantHash[searchId] = v
		end
		if SystemManager.debug then
			print("_euqipToEnchantHash = " .. tostringRich(_euqipToEnchantHash))
		end
	end

	if _enchantLevelHash == nil then
		_enchantLevelHash = {}
		_openTimesHash = {}

		local enchant_Setting = require "canon.configs.enchant_Setting"
		_maxEnchantLevel = #enchant_Setting
		local tempSkillCount = 0
		for i, v in ipairs(enchant_Setting) do
			v.costHash = {}
			v.costHash[3] = v.EnchantCost3
			v.costHash[4] = v.EnchantCost4
			v.costHash[5] = v.EnchantCost5
			v.costHash[6] = v.EnchantCost6
			v.costHash[7] = v.EnchantCost7

			--删除不用的信息
			v.EnchantCost3 = nil
			v.EnchantCost4 = nil
			v.EnchantCost5 = nil
			v.EnchantCost6 = nil
			v.EnchantCost7 = nil

			if v.EnchantSkill == 2 then
				--该等级会触发技能
				tempSkillCount = tempSkillCount + 1

				_openTimesHash[tempSkillCount] = i
			end
			v.skillTotalCount = tempSkillCount--技能出现总次数

			_enchantLevelHash[tonumber(v.EnchantLevel)] = v
		end
		if SystemManager.debug then
			print("_enchantLevelHash[1] = " .. tostringRich(_enchantLevelHash[1]))
			print("_maxEnchantLevel = " .. tostringRich(_maxEnchantLevel))
			print("_openTimesHash = " .. tostringRich(_openTimesHash))
		end
	end

	if _enchantAttrHash == nil then
		_enchantAttrHash = {}
		local enchant_type = require "canon.configs.enchant_type"
		for i, v in ipairs(enchant_type) do
			v.addAttrs = string.split(v.EnchantType, "|")
			for k, w in ipairs(v.addAttrs) do
				v.addAttrs[tonumber(k)] = tonumber(w)
			end

			--删除不用的信息
			v.EnchantType = nil

			_enchantAttrHash[tonumber(v.EquipmentType)] = v
		end
		if SystemManager.debug then
			print("_enchantAttrHash = " .. tostringRich(_enchantAttrHash))
		end
	end

	if _enchantSkillHash == nil then
		_enchantSkillHash = {}
		local enchant_skilldes = require "canon.configs.enchant_skilldes"
		for i, v in ipairs(enchant_skilldes) do
			_enchantSkillHash[tonumber(v.EnchantSkillId)] = v
			v.levelPoints = {}
		end

		--把加点组合进去
		local equipment_number = require "canon.configs.equipment_number"
		for i, v in ipairs(equipment_number) do
			local skillMeta = _enchantSkillHash[tonumber(v.EnchantSkillId)]
			skillMeta.levelPoints[tonumber(v.EnchantSkillLevel)] = tonumber(v.EnchantSkillNumber)
		end

		if SystemManager.debug then
			--print("_enchantSkillHash = " .. tostringRich(_enchantSkillHash))
			print("_enchantSkillHash[10001] = " .. tostringRich(_enchantSkillHash[10001]))
		end
	end
end

function EnchantConfig.clear()
	--后端配置需要清空
	_attrAddPointHash = nil
	_attrRatioHash = nil
end

----------------------------------------------------------------------------------------
-- 查询接口
----------------------------------------------------------------------------------------

--获得装备附灵根配置
function EnchantConfig.getEnchantMeta(equipMetaId)
	local enchantMeta = _euqipToEnchantHash[equipMetaId]
	if enchantMeta == nil then
		local equipMeta = MetaManager.equip_meta[equipMetaId]
		--print("equipMeta = " .. tostringRich(equipMeta))
		enchantMeta = _euqipToEnchantHash[equipMeta.quality .. EnchantConfig.SEP_SEARCH_ID .. equipMeta.position]
	end
	return enchantMeta
end

-- 获得某个装备所有可出的隐藏技能
function EnchantConfig.getSkills(equipMetaId, enchantMeta)
	if not enchantMeta then
		enchantMeta = EnchantConfig.getEnchantMeta(equipMetaId)
	end
	return enchantMeta.skills
end

function EnchantConfig.getAttrList(equipMetaId)
	local equipMeta = MetaManager.equip_meta[equipMetaId]
	local attrMeta = _enchantAttrHash[equipMeta.position]
	return attrMeta.addAttrs
end

-- 获得附灵等级信息
function EnchantConfig.getLevelMeta(enchantLevel)
	local levelMeta = _enchantLevelHash[enchantLevel]
	return levelMeta
end

-- 获得技能配置信息
function EnchantConfig.getSkillMeta(skillId)
	local skillMeta = _enchantSkillHash[skillId]
	return skillMeta
end

-- 获得最大附灵等级数
function EnchantConfig.getMaxEnchantLevel()
	return _maxEnchantLevel
end

-- 通过总开启技能次数 获得所需最低等级
-- totalOpenTimes 大于0 小于等于最大技能开启次数
function EnchantConfig.getMinLevelByTotleOpenTimes(totalOpenTimes)
	return _openTimesHash[totalOpenTimes]
end

----------------------------------------------------------------------------------------
-- 后端config查询接口
----------------------------------------------------------------------------------------

--获得属性系数配置
function EnchantConfig.getAttrAddPointHash()
	if not _attrAddPointHash then
		_attrAddPointHash = {}
		local config = DataManager.GameMetaData.enchantTotalConfig
		_attrAddPointHash[ConstManager.ATTR_ATK] = config.atk--攻击属性系数
		_attrAddPointHash[ConstManager.ATTR_DEF] = config.def--防御属性系数
		_attrAddPointHash[ConstManager.ATTR_HP] = config.hp--生命属性系数
		--print("_attrAddPointHash = " .. tostringRich(_attrAddPointHash))
	end
	return _attrAddPointHash
end

--获得品质系数百分比配置
function EnchantConfig.getAttrRatioHash()
	if not _attrRatioHash then
		_attrRatioHash = {}
		local config = DataManager.GameMetaData.enchantTotalConfig
		_attrRatioHash[3] = config.quality3--蓝色品质系数百分比
		_attrRatioHash[4] = config.quality4--紫色品质系数百分比
		_attrRatioHash[5] = config.quality5--橙色品质系数百分比
		_attrRatioHash[6] = config.quality6--红色品质系数百分比
		_attrRatioHash[7] = config.quality7--金色品质系数百分比
		--print("_attrRatioHash = " .. tostringRich(_attrRatioHash))
	end
	return _attrRatioHash
end

--获得装备附灵所需玩家等级
function EnchantConfig.getEnchantsLevel()
	return MetaManager.game_meta.gameSettingConfig.enchantsLevel
end

----------------------------------

--获得属性系数
function EnchantConfig.getAttrAddPoint(attrType)
	local hash = EnchantConfig.getAttrAddPointHash()
	local result = hash[attrType]
	if SystemManager.debug then
		DebugManager.assert(result ~= nil, "无法获得属性系数! attrType = " .. tostringRich(attrType) .. ", hash = " .. tostringRich(hash))
	end
	return result
end

--获得品质系数百分比
function EnchantConfig.getAttrRatio(quality)
	local hash = EnchantConfig.getAttrRatioHash()
	local result = hash[quality]
	if SystemManager.debug then
		DebugManager.assert(result ~= nil, "无法获得品质系数百分比! quality = " .. tostringRich(quality) .. ", hash = " .. tostringRich(hash))
	end
	return result
end