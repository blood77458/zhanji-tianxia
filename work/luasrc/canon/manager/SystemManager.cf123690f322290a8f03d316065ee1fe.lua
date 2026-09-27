--
-- SystemManager.lua
-- Author: zheng.che
-- Date: 2014-05-09 15:14:43
-- 系统管理器
--
require "canon.manager.ErrorCodeManager"
require "canon.manager.ConstManager"
require "canon.features.enchant.Enchant"
require "canon.features.crossArena.CrossArena"
require "canon.features.crossUnionPk.CrossUnionPk"
require "canon.features.treasureSystem.TreasureSystem"

SystemManager = {}

--调试状态 默认只有在游戏设置里 音乐*5 + 上方*3 才开启 参见ConfigScene
SystemManager.debug = false --默认
--系统时间偏移量秒数
SystemManager.offsetTimeSec = 0 --默认0(负数表示时间回溯)

--跨天log标记
SystemManager.debugPassDay = false--默认 false
--是否已经登录
SystemManager.isLogin = false

-- 开始运行
function SystemManager.mainStartup()
	print("SystemManager.mainStartup! ")
	PassDayManager.startup()
	UnionPK.startup()
	ErrorCodeManager.startup()
	Enchant.startup()
	DataManager.startup()
	CrossArena.startup()
	CrossUnionPk.startup()
    
	SystemManager.isLogin = true
end

--开始debug模式
function SystemManager.startDebug()
	print("start debug!!")
	SystemManager.debug = true
	SystemManager.debugPassDay = true
end

--退出游戏时清除玩家数据
function SystemManager.clearData()
	print("SystemManager.clearData!!")
	SystemManager.isLogin = false

    UnionManager.clear()
    UnionPK.clear()
    Activity_CardOldToNewLayer.clear()
    ErrorCodeManager.clear()
    Enchant.clear()
    DataManager.clear()
    CrossArena.clear()
    CrossUnionPk.clear()
    
    Activity_FountainLayer.clear()
    Activity_SeckillLayer.allClear()
    Activity_DoubleRewardLayer.clear()
    Activity_ConsumeRewardsLayer.clear()
	--清除小玉嫁到是否进入过界面的状态
	Activity_GachaXiaoyuLayer.reseEnterGachaXiaoyu()
end

--获得当前地区编号 定义详见ConstManager 来源详见luncher.lua
function SystemManager.getCurrentLocationId()
	return g_locationId
end

-- 查询是否当前地区
-- targetSwitchId 配置的地区开关
-- 该地域开关为1时，台湾大陆均开启该武将的图鉴以及装备合体技的显示
-- 该地域开关为2时，大陆地区开启 台湾地区关闭
-- 该地域开关为3时，大陆地区关闭 台湾地区开启
-- 该地域开关为4时，台湾大陆均关闭显示
function SystemManager.isMyLocation(targetSwitchId)
	if g_locationId == ConstManager.LOCATION_CN then
		--大陆
		if targetSwitchId == 1 or targetSwitchId == 2 then
			return true
		end
	else
		--台湾
		if targetSwitchId == 1 or targetSwitchId == 3 then
			return true
		end
	end
	return false
end

--查询新手引导是否已经结束
function SystemManager.isNewbieFinished()
	if Get_ShareData( "NewUserGuide_Not_Finished" ) == 1 then
		--还没有结束
		return false
	end
	return true
end

--断言例句
-- if SystemManager.debug then
-- 	DebugManager.assert(bool, str)
-- end