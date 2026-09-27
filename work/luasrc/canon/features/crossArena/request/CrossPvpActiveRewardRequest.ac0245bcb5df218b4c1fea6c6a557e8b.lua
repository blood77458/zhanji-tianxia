require "canon.request.BaseRequest"

CrossPvpActiveRewardRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossPvpActiveRewardRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossPvpActiveRewardRequest:ctor(params, priority)
	self.endpoint = "gainCrossPvpActiveReward"--<<<<< 1. 修改指令名称 后端提供
  	self.succeedEventName = self.endpoint .. "Succeed"
  	self.failedEventName = self.endpoint .. "Failed"
end

function CrossPvpActiveRewardRequest:onSuccess( data )
  	self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossPvpActiveRewardRequest:onError(error)
  	self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function CrossPvpActiveRewardRequest.sendRequestDefalut(activeId, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		CrossPvpActiveRewardRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossPvpActiveRewardRequest.sendRequest(activeId, onSucceed, CrossPvpActiveRewardRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

function CrossPvpActiveRewardRequest.sendRequest(activeId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {activeId = activeId}--<<<<< 3

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

  if not CrossPvpActiveRewardRequest.TEST then
    --非测试状态 正常流程
    local request = CrossPvpActiveRewardRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(request.succeedEventName, onSucceedHandle)
    request:addEventListener(request.failedEventName, onFailedHandle)
    request:start()
  else
    --测试流程 假数据
    onSucceedHandle(CrossPvpActiveRewardRequest.getDebugDatas())
  end
end

--成功的默认处理
function CrossPvpActiveRewardRequest.onSucceedDefault(event)--<<<<< 3
	local activeId = event.params.activeId
  local rewardsInfo = CrossArenaManager.getMyActiveRewards()
  local isfinished = false
  for k,v in pairs(rewardsInfo) do
    if v == activeId then 
      isfinished = true
    end
  end
  if not isfinished then table.insert(rewardsInfo,activeId) end
  CrossArenaManager.setMyActiveRewards(rewardsInfo)

  RewardManager:getReward(event.data.rewards)

  --显示获得的奖励
  local scene = Director:mgr():run()
  local aRewardPanel = RewardReviewPanel:create( scene, {rewardList = event.data.rewards, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle")} )
  scene:addChild(aRewardPanel)
  aRewardPanel:scaleIn()
end

--失败默认处理
function CrossPvpActiveRewardRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end

--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function CrossPvpActiveRewardRequest.getDebugDatas()
  local testEvt = {data = {}}
  testEvt.data.rewards =  {}
  local rank
  
  rank = {}
  rank.itemType = 5
  rank.metaId = 101011
  rank.id = 123
  rank.amount = 1
  rank.level = 1
  rank.exp = 56
  table.insert(testEvt.data.rewards, rank)

  return testEvt
end