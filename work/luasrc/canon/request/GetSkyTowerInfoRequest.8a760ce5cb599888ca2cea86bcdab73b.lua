require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GetSkyTowerInfoRequest = class(BaseRequest)

function GetSkyTowerInfoRequest:ctor()
  self.endpoint = METHOD_GETSKYTOWERINFO
end

function GetSkyTowerInfoRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetSkyTowerInfoSucceed, data))
end

function GetSkyTowerInfoRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetSkyTowerInfoFailed, error))
end

function generalSendGetSkyTowerInfoRequest(successCallback, failedCallback, callbackFunc)
	local function onGeneralGetSkyTowerInfoSucceed(evt)
		DataManager.setSharkSkyTowerData(evt.data)
		if successCallback then
			successCallback(evt)
		end
	end
	
	local function onGeneralGetSkyTowerInfoFailed(evt)
		CanonMessageBox:showCommUnHandleErrorBox(evt.data, nil, callbackFunc)
		if failedCallback then
			failedCallback(evt)
		end
	end
	--------------test
	local test = {}
	test.data = {}
	test.data.pastStatus = {days = TimeUtil.calcPassedDays(TimeUtil.getServerTimeSeconds()), 
	climbTimes = 0,
	maxTotalStars = 100,
	currTotalStars = 0,
	currUsedStars = 0,
	maxFloor = 0,
	currFloor = 0,
	inTopRankDays = 0, 
	gainFloorBuff = {},
	selfAtkBuff = 0,
	selfDefBuff = 0,
	enemyAtkDebuff = 0,
	enemyDefDebuff = 0,
	gainYesterdayReward = false};
	test.data.currStatus = 
	{days = TimeUtil.calcPassedDays(TimeUtil.getServerTimeSeconds()), 
	climbTimes = 0,
	maxTotalStars = 0,
	currTotalStars = 100,
	currUsedStars = 0,
	maxFloor = 0,
	currFloor = 3,
	inTopRankDays = 0, 
	gainFloorBuff = {},
	selfAtkBuff = 0,
	selfDefBuff = 0,
	enemyAtkDebuff = 0,
	enemyDefDebuff = 0,
	gainYesterdayReward = false};
	test.data.pastRanks = {};
	for i = 1, 20 do
		local aa = {}
		aa.uid = 1003890001
		if i == 1 then
			aa.uid = 1014560001
		end
		aa.nickName = "testuser" .. i
		aa.level = 20
		aa.mainCardMetaId = 101011
		aa.maxFloor = 40 - i
		aa.maxTotalStars = 40 - i
		aa.inTopRankDays = 40 - i	
		table.insert(test.data.pastRanks, aa)
	end
	test.data.sharkSkyTower = {uid = 1014560001, maxBigWinFloor = 5};
	--onGeneralGetSkyTowerInfoSucceed(test)
	--do return end
	--------------test
	local request = GetSkyTowerInfoRequest.new( nil, rpc.SendingPriority.kHigh )
  request:addEventListener( RequestNotifyEnum.GetSkyTowerInfoSucceed, onGeneralGetSkyTowerInfoSucceed )
  request:addEventListener( RequestNotifyEnum.GetSkyTowerInfoFailed, onGeneralGetSkyTowerInfoFailed )
  request:start()
end