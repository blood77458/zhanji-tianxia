-- UnionTitleManager.lua
-- 2014-8-21
-- zheng.che
-- 军团职位权限管理 (没地方放了先放这里)
-- *此类中的查询接口只关心职位条件 不考虑其他条件

UnionTitleManager = {}

--权限编号:
--1.  解散军团
--2.  任命副团长
--3.  转让军团长
--4.  踢出副团长
--5.  罢免副团长
--6.  修改宣言
--7.  修改公告
--8.  任职精英成员
--9.  罢免精英成员
--10. 升级军团建筑
--11. 进团审核
--12. 踢出精英成员,普通成员
--13. 捐献
--14. 军团商城购买
--15. 领取工资
--16. 召唤军团怪兽
--17. 分配军团怪兽战利品
--18. 军团长城池报名
--19. 军团战调整阵型
local _totalPermissionCount = 19

--权限表 <职位编号, <权限编号, bool>>
local _permissionsHash = nil

---------------------------------------------------------------------------------------------------------

--
function UnionTitleManager.startup()
	if _permissionsHash == nil then
		_permissionsHash = {}

		for i=UnionManager.TITLE_MANAGER, UnionManager.TITLE_MEMBER do
			local titlePermissionHash = {}
			_permissionsHash[i] = titlePermissionHash
			local permissionArr = string.split(MetaManager.union_career[i].priviliges, ",")
			for k,v in ipairs(permissionArr) do
				titlePermissionHash[tostring(v)] = true
			end
		end
	end
	-- print("MetaManager.union_career = " .. tostringRich(MetaManager.union_career))
	-- print("_permissionsHash = " .. tostringRich(_permissionsHash))
end

function UnionTitleManager.clear()
end

---------------------------------------------------------------------------------------------------------

--查询能否报名竞标
-- title 职位编号
function UnionTitleManager.canCitySign(title)
	if title == nil then
		--不传title参数情况 认为查询玩家自身的职位
		title = UnionManager.getMyTitle()
	end

	return UnionTitleManager.canDoThis(title, 18)
end

--查询能否调整阵型
-- title 职位编号
function UnionTitleManager.canChangeForm(title)
	if title == nil then
		--不传title参数情况 认为查询玩家自身的职位
		title = UnionManager.getMyTitle()
	end

	return UnionTitleManager.canDoThis(title, 19)
end

---------------------------------------------------------------------------------------------------------

--调取配置文件进行查询操作
-- title 职位编号
-- pCode 权限编号
function UnionTitleManager.canDoThis(title, pCode)
	if title == nil then
		--不传title参数情况 认为查询玩家自身的职位
		title = UnionManager.getMyTitle()
	end

	local titlePermissionHash = _permissionsHash[title]
	if SystemManager.debug then
		DebugManager.assert(titlePermissionHash ~= nil, "调取军团职权配置失败 无效的职位编号! title = " .. tostringRich(title))
	end
	local result = titlePermissionHash[tostring(pCode)]
	return result
end