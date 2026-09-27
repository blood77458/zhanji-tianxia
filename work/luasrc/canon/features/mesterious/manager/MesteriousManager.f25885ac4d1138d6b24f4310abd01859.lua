require "hecore.display.CocosObject"
MesteriousManager = {}

local _defaultDiffculty = 2;
local _chanllengeCountry = 1;

local const_FeatrueName = {
	"activityMysterious_1",
	"activityMysterious_2",
	"activityMysterious_3",
	"activityMysterious_4",
	"activityMysterious_5",
	"activityMysterious_all",
}

function MesteriousManager.getMesteriousData()
	local ret = {false,false,false,false,false}

	if MaintenanceManager.isActivityOpen(const_FeatrueName[#const_FeatrueName]) then
		for k,v in pairs(ret) do
			ret[k] = true
		end
	else
		for i=1,#ret do
			if MaintenanceManager.isActivityOpen(const_FeatrueName[i]) then
				ret[i] = true
			end
		end
	end

	return ret
end

function MesteriousManager.setChanllengeCountry( v )
	_chanllengeCountry = v
end

function MesteriousManager.getChanllengeCountry( )
	return _chanllengeCountry
end

function MesteriousManager.setDefaultDiffculty( v )
	_defaultDiffculty = v
end

function MesteriousManager.getDefaultDiffculty( )
	return _defaultDiffculty
end

function MesteriousManager.changeMysteriousChallengeTimes()
	local mysteriousChallengeTimes = DailyDataManager.getMysteriousChallengeTimes()
	local findPos = -1
	for k,v in pairs(mysteriousChallengeTimes) do
		if tonumber(v.nodeId) == _chanllengeCountry then
			findPos = k
		end
	end
	if findPos == -1 then
		local node = {
		nodeId = _chanllengeCountry,
		times = 1
	}
		table.insert(mysteriousChallengeTimes , node)
	else
		mysteriousChallengeTimes[findPos].times = mysteriousChallengeTimes[findPos].times + 1
	end

	DailyDataManager.setMysteriousChallengeTimes(mysteriousChallengeTimes)
end

function MesteriousManager.getMysteriousChallengeTimesById( id )
	local mysteriousChallengeTimes = DailyDataManager.getMysteriousChallengeTimes()
	for k,v in pairs(mysteriousChallengeTimes) do
		if tonumber(v.nodeId) == id then
			return MesteriousManager.getMysteriousConfig().eventLimit - v.times
		end
	end
	print("~~~~~~~~~~~~~~~~~~~~~~"..tostringRich(MesteriousManager.getMysteriousConfig()))
	return MesteriousManager.getMysteriousConfig().eventLimit
end

function MesteriousManager.getMysteriousConfig()
	return DataManager.GameMetaData.eventMysteriousConfig
end