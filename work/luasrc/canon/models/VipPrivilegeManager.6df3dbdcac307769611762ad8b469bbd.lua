require "hecore.class"

VipPrivilegeManager = class()

function VipPrivilegeManager.getVipPrivilegeTextTable(vipLevel)
	local privilegeTextTable = {}
	local vipSetting = MetaManager.vip_setting[vipLevel]
	local i = 1
	while vipSetting["vipPrivilegeText" .. i] do
		if tonumber(vipSetting["vipPrivilegeText" .. i]) ~= 0 then
			table.insert(privilegeTextTable, getTextByKey(vipSetting["vipPrivilegeText" .. i]))
		end
		i = i + 1
	end
	return privilegeTextTable
end
