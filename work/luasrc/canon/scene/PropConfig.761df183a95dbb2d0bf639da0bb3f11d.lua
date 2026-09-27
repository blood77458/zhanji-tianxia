Prop_Effect_Type = {
	EXP = 0,
	ENERGY = 1,
	EP = 2,
	TREASUREBOX = 3,
	BOX = 4,
	KEY = 5,
	PEACECARD = 6,
	VIPBOX = 7,
	TIMES_BOX = 9,--使用次数随机礼包
	RED_PACKET = 11,--商城买来的可分配的红包
	RED_PACKET_RECIVED = 12,--收到的红包
}

--???????????
function PropConfig_isCanUseProp(itemType)
	if tonumber(itemType) == Prop_Effect_Type.TREASUREBOX then
		return true
	end
	if tonumber(itemType) == Prop_Effect_Type.BOX then
		return true
	end
	if tonumber(itemType) == Prop_Effect_Type.KEY then
		return true
	end
	if tonumber(itemType) == Prop_Effect_Type.VIPBOX then
		return true
	end
	if tonumber(itemType) == Prop_Effect_Type.TIMES_BOX then
		return true
	end
	if tonumber(itemType) == Prop_Effect_Type.RED_PACKET_RECIVED then
		return true
	end
	return false
end