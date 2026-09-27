--
-- UnionGetMyDataRequest.lua
-- Author: zheng.che
-- Date: 2014-03-27 10:37:14
-- 获得当前玩家的军团信息
--
require "canon.request.BaseRequest"

UnionGetMyDataRequest = class(BaseRequest)

function UnionGetMyDataRequest:ctor()
  self.endpoint = "getUserUnionInfo"--<<<<< 1. 修改指令名称 后端提供
end

function UnionGetMyDataRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetMyDataSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionGetMyDataRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetMyDataFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionGetMyDataRequest.sendRequest(succeedCallback, failedCallback, isShowLoading)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	--检查是否显示loading画面
	if isShowLoading == nil then
		isShowLoading = true
	end

	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {}--<<<<< 3
	local request = UnionGetMyDataRequest.new(params, rpc.SendingPriority.kHigh, isShowLoading)
	request.showLoading = isShowLoading
	request:addEventListener(RequestNotifyEnum.UnionGetMyDataSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionGetMyDataFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionGetMyDataRequest.onSucceedDefault(event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))
	--更新玩家军团信息

	if event.data.sharkUserUnion then
		--有军团数据的情况 否则啥也不做
		UnionManager.setMyUnionData(event.data.sharkUserUnion)
		-- print("~~~~~~~~~~~~~~~~~~~~event.data.applyCrossGvgRemind = "..tostringRich(event.data))

		-- .setGainCrossUnionWarInapplyCrossGvgRemind(event.data.applyCrossGvgRemind)
		UnionManager.setGainCrossUnionWarInout(event.data.out)
		UnionManager.setGainCrossUnionWarInunionApplyCrossGvg(event.data.unionApplyCrossGvg)
		UnionManager.setGainCrossUnionWarInselfApplyCrossGvg(event.data.selfApplyCrossGvg)
		UnionManager.setGainCrossUnionWarIncrossGvgVersion(event.data.crossGvgVersion)
		UnionManager.setGainCrossUnionWarInpromotion(event.data.promotion)
		UnionManager.setGainCrossUnionWarInselfQuitCrossGvg(event.data.selfQuitCrossGvg)
	end

	--军团战角标数量
	UnionPkData.setUnionWarHintNum(event.data.unionWarHintNum or 0)
end

--失败默认处理
function UnionGetMyDataRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	--无错误码
	local errorCode = tonumber(event.data.retCode)
	CanonMessageBox:showCommUnHandleErrorBox(errorCode)
end