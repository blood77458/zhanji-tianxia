-- EquipUtils.lua
-- zheng.che
-- 2014-12-11
-- 装备相关接口

EquipUtils = {}

-- 获得装备某等级强化后的的属性信息
-- equipMetaId 装备配置编号
-- level 强化等级
-- result = {id=属性类型编号, num=属性增加数值}
function EquipUtils.findAttrAddInfo(equipMetaId, level)
	local equipMeta = MetaManager.equip_meta[equipMetaId]
	local levelConfig = MetaManager.equip_level[level]

	local result = {}
	if tonumber(equipMeta.basicAtk, 10) > 0 then
        result.id = ConstManager.ATTR_ATK
        result.num = math.floor(equipMeta.basicAtk + equipMeta.atkSCoe * levelConfig.atk)
    elseif tonumber(equipMeta.basicDefence, 10) > 0 then
		result.id = ConstManager.ATTR_DEF
        result.num = math.floor(equipMeta.basicDefence + equipMeta.defSCoe * levelConfig.def)
    elseif tonumber(equipMeta.basicHp, 10) > 0 then
		result.id = ConstManager.ATTR_HP
        result.num = math.floor(equipMeta.basicHp + equipMeta.hpSCoe * levelConfig.hp)
    end

    return result
end

-- 获得装备某等级增加的一级属性列表
-- equipMetaId 装备配置编号
-- level 强化等级
-- enchantLevel 附灵等级
-- result = {属性列表}
function EquipUtils.findFirstAttrs(equipMetaId, level, enchantLevel)
    local result = {}
    local normalAttr = EquipUtils.findAttrAddInfo(equipMetaId, level)
    table.insert(result, normalAttr)

    if Enchant.isSupportToEnchant(equipMetaId) then
        --此装备允许附灵
        local enchantInfo = EnchantUtils.findEnchantInfo(equipMetaId, enchantLevel)
        for k, v in pairs(enchantInfo.attrHash) do
            if table.indexOf(ConstManager.HEAD_ATTRS, k) ~= nil then
                --是一级属性
                table.insert(result, v)
            end
        end

        --对装备原始属性做加成操作
        local normalPercentAttrId = ConstManager.getAttrPercent(normalAttr.id)
        local normalPercentAttrInfo = enchantInfo.attrHash[normalPercentAttrId]
        if normalPercentAttrInfo then
            normalAttr.num = math.floor(normalAttr.num * (1+normalPercentAttrInfo.num/100))--得到加成结果
        end
    end

    return result
end