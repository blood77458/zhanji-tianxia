-- ChallengeFriendListRequest.lua
-- 2015-4-1
-- l1ghtsaber
-- 一键切磋
require "canon.request.BaseRequest"

ChallengeFriendListRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
ChallengeFriendListRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function ChallengeFriendListRequest:ctor(params, priority)
	  self.endpoint = "challengeFriendList"--<<<<< 1. 修改指令名称 后端提供
  	self.succeedEventName = self.endpoint .. "Succeed"
  	self.failedEventName = self.endpoint .. "Failed"
end

function ChallengeFriendListRequest:onSuccess( data )
  	self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function ChallengeFriendListRequest:onError(error)
  	self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function ChallengeFriendListRequest.sendRequestDefalut(friendUids, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		ChallengeFriendListRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	ChallengeFriendListRequest.sendRequest(friendUids, onSucceed, ChallengeFriendListRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

function ChallengeFriendListRequest.sendRequest(friendUids, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {friendUids = friendUids}--<<<<< 3

	local function onSucceedHandle(event)
    event.params = params
		if succeedCallback then
			event.params = params
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			event.params = params
			failedCallback(event)
		end
	end

  if not ChallengeFriendListRequest.TEST then
    --非测试状态 正常流程
    local request = ChallengeFriendListRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(request.succeedEventName, onSucceedHandle)
    request:addEventListener(request.failedEventName, onFailedHandle)
    request:start()
  else
    --测试流程 假数据
    onSucceedHandle(ChallengeFriendListRequest.getDebugDatas())
  end
end

--成功的默认处理
function ChallengeFriendListRequest.onSucceedDefault(event)--<<<<< 3
  RewardManager:getReward(event.data.rewards)
  local points = 0
  for k,v in pairs(event.data.rewards) do
    points = points + v.amount
  end
  local str = getTextByKey("friend_allChallenged1",{num = points})

  CanonMessageBox.showText(
    ShowButtonType.ID_OK,
    str,
    nil,
    { text = getTextByKey("yes") },
    nil
  )
end

--失败默认处理
function ChallengeFriendListRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end

--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function ChallengeFriendListRequest.getDebugDatas()
  local testEvt = {data = {}}
  testEvt.data.rewards =  {}
  local rank
  
  rank = {}
  rank.itemType = 8
  rank.metaId = 0
  rank.id = 0
  rank.amount = 8
  rank.level = 0
  rank.exp = 0
  table.insert(testEvt.data.rewards, rank)

  return testEvt
end