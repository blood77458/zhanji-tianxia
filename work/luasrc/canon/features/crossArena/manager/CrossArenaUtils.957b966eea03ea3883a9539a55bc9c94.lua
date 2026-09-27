-- CrossArenaUtils.lua
-- 2015-3-10
-- zheng.che
-- 跨服pvp工具类 杂七杂八

CrossArenaUtils = {}

-- 得到显示区名 如: [11区]
-- serverId 区编号
function CrossArenaUtils.getLocationStrById(serverId)
	return "["  .. Localization:getInstance():getText("login_serverNo", {num = serverId}) .. "]"
end

-- 得到显示的军团名 如: [xx军团]
-- unionName 军团名称
function CrossArenaUtils.getUnionNameStrById(unionName)
	if not unionName then
		return ""
	end
	return "["  .. unionName .. "]"
end