--跨服GvG  祝福请求 
require "canon.request.BaseRequest"
--
CrossUnionPkGetBlessInFoRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossUnionPkGetBlessInFoRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossUnionPkGetBlessInFoRequest:ctor()
  self.endpoint = "getCrossGVGBlessInfo"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CrossUnionPkGetBlessInFoRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossUnionPkGetBlessInFoRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function CrossUnionPkGetBlessInFoRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		CrossUnionPkGetBlessInFoRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossUnionPkGetBlessInFoRequest.sendRequest(onSucceed, CrossUnionPkGetBlessInFoRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function CrossUnionPkGetBlessInFoRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {}--<<<<< 2. 附加参数转换成后端提供的接口格式

	local function onSucceedHandle(event)
		event.params = params
		if succeedCallback then
			event.params = params
			event.Data = Data
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			event.params = params
			failedCallback(event)
		end
	end

	if not CrossUnionPkGetBlessInFoRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("CrossUnionPkGetBlessInFoRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = CrossUnionPkGetBlessInFoRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(CrossUnionPkGetBlessInFoRequest.getDebugDatas())
	end
end

--成功的默认处理
function CrossUnionPkGetBlessInFoRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("CrossUnionPkGetBlessInFoRequest->event = " .. tostringRich(event))
	end
end

--失败默认处理
function CrossUnionPkGetBlessInFoRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
		if errorCode == 716313 then
			--玩家没加入任何军团 返回主界面
			local scene = Director:mgr():run()
			scene:replaceScene(MainMenuScene)
		end
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end



--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除  报名不需要假数据
function CrossUnionPkGetBlessInFoRequest.getDebugDatas()
	local testEvt = {data = {}}
	--帝王配置
	--<property code="king" type="boolean" desc="是否是至尊帝王" />
	-- <property code="mainCardMetaId" type="int" desc="至尊帝王主将metaId" />
	-- 	<property code="unionName" type="String" desc="至尊帝王所在军团名" />
	-- <property code="serverId" type="int" desc="至尊帝王所在服务器" />
	-- 	<property code="nickname" type="String" desc="至尊帝王昵称" />
	-- 	<property code="blessNum" type="int" desc="当前已获得祝福次数" />
	-- <property code="canBlessTimes" type="int" desc="当前剩余祝福次数" />
	-- local Info = nil
	testEvt.data =  {}
	
	-- Info = {}
	testEvt.data.king = true
	testEvt.data.mainCardMetaId = 101033
	testEvt.data.unionName = "神军团"
	testEvt.data.nickname = "我是大帝王"
	testEvt.data.serverId = 32
	testEvt.data.blessNum = 123
	testEvt.data.canBlessTimes = 1
    testEvt.data.gainGvgKnockoutReward = false
	testEvt.data.kingUid = 1001680001 
	-- table.insert(testEvt.data, Info)  

	return testEvt
end