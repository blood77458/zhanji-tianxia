-- UnionPkConsts.lua
-- 2014-8-5
-- zheng.che
-- 军团战相关数值

UnionPkConsts = {}

--大城池id起点(范围:1-5)
UnionPkConsts.bigCityStartNum = 1
--中城池id起点(范围:6-15)
UnionPkConsts.midCityStartNum = 6
--小城池id起点(范围:16-)
UnionPkConsts.smallCityStartNum = 16

--大城池数量(不超过5)
UnionPkConsts.bigCityNum = 1
--中等城池数量(不超过10)
UnionPkConsts.midCityNum = 4
--大城池和中等城池总数
UnionPkConsts.bigAndMidCityNum = UnionPkConsts.bigCityNum + UnionPkConsts.midCityNum--5

--ui里每组小城池个数
UnionPkConsts.smallCityUiGroupNum = 5

----------------------------------------------------------------------------------------------

--军团战时间表
UnionPkConsts.TIME_NONE 			= 0--非任何时间段
UnionPkConsts.TIME_SELECT 			= 1--选择目标城池阶段
UnionPkConsts.TIME_SELECTING 		= 2--等待竞标结果阶段
UnionPkConsts.TIME_MEMBER_APPLY 	= 3--成员报名阶段
UnionPkConsts.TIME_ROUND1_FORM 		= 4--第一轮调整阵型
UnionPkConsts.TIME_ROUND1_BUFF 		= 5--第一轮buff鼓舞
UnionPkConsts.TIME_ROUND1_FIGHT 	= 6--第一轮等待结果
UnionPkConsts.TIME_ROUND2_FORM 		= 7--第二轮调整阵型
UnionPkConsts.TIME_ROUND2_BUFF 		= 8--第二轮buff鼓舞
UnionPkConsts.TIME_ROUND2_FIGHT 	= 9--第二轮等待结果
UnionPkConsts.TIME_REWARD 			= 10--领奖阶段


UnionPkConsts.MAX_TIMES = 10--最大时间段编号