-- UnionPkErrorCode.lua
-- 2014-9-15
-- zheng.che
-- 军团战 错误码处理

UnionPkErrorCode = {}

local _codes

-------------------------------------------------
-- 操作
-------------------------------------------------

function UnionPkErrorCode.startup()
	if _codes == nil then
		_codes = {}

		_codes[710512] = {startCallback=UnionPkErrorCode.silverNotEnouth}--银币不足
		_codes[710513] = {startCallback=UnionPkErrorCode.goldNotEnough}--金币不足
		_codes[710516] = {startCallback=UnionPkErrorCode.packageIsFull}--格子不够
		_codes[716313] = {txtCode="UnionWar_error_txt12"}--主公，您没有在本军团内哦
		--_codes[716315] = {txtCode="xxx"}--玩家军团信息不存在--无提示
		--_codes[716601] = {txtCode="xxx"}--城池信息不存在--无提示
		_codes[716613] = {txtCode="UnionWar_error_txt22"}--阵型信息不存在 *加状态 	--您的军团没有人报名本城池团战
		_codes[716607] = {txtCode="UnionWar_error_txt"}--战报信息不存在
		_codes[716632] = {txtCode="UnionWar_error_txt1"}--不能解散 	--军团战期间无法进行踢人，退出军团，解散军团等操作--军团战期间无法进行踢人，退出军团，解散军团等操作
		_codes[716633] = {txtCode="UnionWar_error_txt1"}--不能解散 	--军团战期间无法进行踢人，退出军团，解散军团等操作

		-- applyUnionCity错误码 参与竞标
		_codes[716428] = {txtCode="UnionWar_error_txt15"}--权限不够不能报名,刷新数据 	--权限不足
		_codes[716602] = {txtCode="UnionWar_error_txt3"}--不在时间段内 	--军团报名时间已过
		_codes[716603] = {txtCode="UnionWar_error_txt4"}--军团处于解散状态(前端也校验) 	--该军团处于解散状态，不能进行报名操作
		_codes[716604] = {txtCode="UnionWar_error_txt5"}--重复报名,前端改城池状态 	--已经报名本城池
		_codes[716605] = {txtCode="UnionWar_error_txt7"}--玩家所处军团报名数量达到上限	--您的军团报名城池数量达到上限
		_codes[716606] = {txtCode="UnionWar_error_txt6"}--报名的军团数量达到上限	--该城池报名军团数已经到达上限
		--_codes[716634] = {txtCode="xxx"}--我军是城池守方--不提示

		-- userApplyUnionCity错误码 报名参战
		_codes[716608] = {txtCode="UnionWar_error_txt14"}--报名时间已过，您没有参与本城池报名
		_codes[716609] = {txtCode="UnionWar_ready_choose"}--已经报名过了	--每名团员只能选择一个城池参加团战
		--_codes[716610] = {txtCode="xxx"}--所处军团没有参与此城池
		_codes[716611] = {txtCode="UnionWar_error_txt8"}--报名玩家人数已达上限

		-- exchangeUnionFormation错误码 调整阵型
		_codes[716429] = {txtCode="UnionWar_error_txt15"}--权限不足，不能进行调整阵型	--权限不足
		_codes[716612] = {txtCode="UnionWar_error_txt9"}--阵型调整时间已过

		-- inspireUnionBattle错误码(鼓舞)
		_codes[716614] = {txtCode="UnionWar_error_txt10"}--buff鼓舞时间已过
		--_codes[716615] = {txtCode="xxx"}--当前玩家没有报名该城池
		_codes[716616] = {txtCode="UnionWar_battle_done"}--金币鼓舞次数达上限	--已达到鼓舞上限次数
		_codes[716617] = {txtCode="UnionWar_battle_done"}--银币	--已达到鼓舞上限次数
		_codes[716618] = {txtCode="UnionWar_battle_done"}--奋力一击 	--已达到鼓舞上限次数
		--_codes[716619] = {txtCode="xxx"}--buffid错误--不提示
		_codes[716620] = {txtCode="UnionWar_error_txt11"}--先锋不能奋力一击(前端提前校验)	--您在阵型先锋位置，不能进行奋力一击

		-- gainUnionBattleReward错误码 获得奖励
		_codes[716621] = {txtCode="UnionWar_error_txt16"}--不在领奖时间内
		_codes[716622] = {txtCode="UnionWar_error_txt17"}--每日奖励已获得
		_codes[716623] = {txtCode="UnionWar_error_txt18"}--玩家不在军团成员里 	--主公，您不在军团内
		_codes[716624] = {txtCode="UnionWar_error_txt13"}--所处军团没有占领的城池	--未能占领城池
		-- _codes[716625] = {txtCode="xxx"}--每日奖励无配置--不提示
		_codes[716626] = {txtCode="UnionWar_error_txt20"}--已经领取过参与奖励了
		_codes[716627] = {txtCode="UnionWar_error_txt21"}--您的军团没有参与军团战
		_codes[716628] = {txtCode="UnionWar_error_txt19"}--已经领取过占领奖励了
		-- _codes[716629] = {txtCode="xxx"}--占领信息不存在--不提示
		-- _codes[716630] = {txtCode="xxx"}--配置不存在--不提示
		-- _codes[716631] = {txtCode="xxx"}--传的奖励类型不支持--不提示
		_codes[716635] = {txtCode="UnionWar_error_txt25"}--本轮军团战没有人报名本城池，您所在的军团直接获得本轮军团战的胜利
		_codes[716638] = {txtCode="UnionWar_time_begin2"}--军团战暂未开启
		_codes[716636] = {txtCode="UnionWar_reward_error"}--已经领取团员参战奖励
		_codes[716639] = {txtCode="UnionWar_error_attend"}--团队总鼓舞次数达到上限的错误码
		--_codes[716637] = {txtCode="xxx"}--试图领取参战奖但并没有参战 --不提示

	end
	
end

function UnionPkErrorCode.clear()
end

-------------------------------------------------
-- 接口
-------------------------------------------------

function UnionPkErrorCode.alert(errorCode, callbackWithCode)
	local codeData = _codes[errorCode]
	if codeData ~= nil then
		if codeData.startCallback ~= nil then
			codeData.startCallback(errorCode)
		end

		if codeData.txtCode ~= nil then
			local function onConfirme()
				if callbackWithCode then
					callbackWithCode(errorCode)
				end
			end
			CanonMessageBox.showTextBox(getTextByKey(codeData.txtCode), onConfirme)
		end
	else
		--默认提示
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end

end

-------------------------------------------------
-- 内部接口
-------------------------------------------------

--弹出 银币不足 提示
function UnionPkErrorCode.silverNotEnouth(errorCode)
	local scene = Director:mgr():run()
	local aPanel = MessageBoxPanel:create(scene, MessageBoxType.kCoinLimit)
	scene:addChild(aPanel)
	aPanel:scaleIn()
end

--弹出 金币不足 提示
function UnionPkErrorCode.goldNotEnough(errorCode)
	local scene = Director:mgr():run()
	local aPanel = AssistantMessageBoxPanel:create(scene, AsMessageBoxType.addCoin, nil)
	scene:addChild(aPanel)
	aPanel:scaleIn()
end

--弹出 背包扩容 提示
function UnionPkErrorCode.packageIsFull(errorCode)
	self.targetInfoPanel = NewPackageFullPanel:show()
end

-------------------------------------------------
-- 备忘
-------------------------------------------------

-- common错误码
-- GRID_NOT_ENOUGH(516, "Grid is not enough: {0:uid}, {1:currGridNum}, {2:needGridNum}"),格子不够
-- USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}"),玩家没有在军团中
-- SHARK_UNION_NOT_EXIST(6315, "SharkUserUnion is not exist: {0:serverId}, {1:unionId}"),玩家军团信息不存在-无提示
-- SHARK_UNION_CITY_NOT_EXIST(6601, "SharkUnionCity is not exist: {0:serverId}, {1:cityId}"),--城池信息不存在--无提示
-- SHARK_UNION_WAR_FORMATION_NOT_EXIST(6613, "SharkUnionWarFormation is not exist: {0:uid}, {1:cityId}, {2:unionId}"),--阵型信息不存在--无提示
-- SHARK_UNION_REPORT_NOT_EXIST(6607, "Shark union war report is not exist: {0:uid}, {1:cityId}, {2:reportId}"),--战报信息不存在
-- SHARK_UNION_WAR_USER_EXIT_CLOSE(6632, "User exit close in union war: {0:uid}"),--玩家不能离开军团
-- SHARK_UNION_WAR_DISSLOVE_UNION_CLOSE(6633, "Disslove union close in union war: {0:uid}"),--军团战期间不能解散军团

-- 接口错误码
-- applyUnionCity错误码
-- HAS_NO_UNION_PRIVILIGE_APPLY_UNION_WAR_CITY(6428, "User has no privilige to apply union war city: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),--权限不够--刷新数据
-- SHARK_UNION_APPLY_UNION_CITY_NOT_OPEN(6602, "Apply union city not open: {0:uid}, {1:cityId}"),--不在时间段内
-- SHARK_UNION_IS_DISSLOVING(6603, "Shark union is dissloving: {0:uid}, {1:cityId}, {2:unionId}"),--军团处于解散状态(前端也校验)
-- SHARK_UNION_ALREADY_APPLY_UNION_CITY(6604, "Already apply union city: {0:uid}, {1:cityId}, {2:unionId}"),--重复报名--前端改城池状态
-- SHARK_UNION_APPLY_UNION_CITY_REACH_LIMIT(6605, "Apply union city reach limit: {0:uid}, {1:cityId}, {2:unionId}"),--玩家所处军团报名数量达到上限
-- SHARK_UNION_CITY_SIGN_REACH_LIMIT(6606, "City sign reach limit: {0:uid}, {1:cityId}, {2:unionId}"),--报名的军团数量达到上限
-- SHARK_UNION_ALREADY_OWN_UNION_CITY(6634, "Already own union city: {0:uid}, {1:cityId}, {2:unionId}"),--我军是城池守方

-- userApplyUnionCity错误码
-- SHARK_UNION_USER_APPLY_NOT_OPEN(6608, "User apply union war is not open: {0:uid}, {1:cityId}"),--不在时间段内
-- SHARK_UNION_USER_ALREADY_APPLY(6609, "User already apply union war: {0:uid}, {1:cityId}"),--已经报名过了
-- SHARK_UNION_NOT_IN_CITY_WAR(6610, "Union is not in city war: {0:uid}, {1:cityId}, {2:unionId}"),--所处军团没有参与此城池
-- SHARK_UNION_USER_APPLY_NUM_REACH_LIMIT(6611, "User apply num reach limit: {0:uid}, {1:cityId}, {2:unionId}"),--报名玩家人数已达上限

-- exchangeUnionFormation错误码
-- HAS_NO_UNION_PRIVILIGE_EXCHANGE_UNION_WAR_FORMATION(6429, "User has no privilige to exchange union war formation: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),--没有权限
-- SHARK_UNION_PERPARE_NOT_OPEN(6612, "Union war perpare is not open: {0:uid}, {1:cityId}"),--不在时间段内

-- inspireUnionBattle错误码(鼓舞)
-- SHARK_UNION_INSPIRE_NOT_OPEN(6614, "Inspire union war is not open: {0:uid}"),--不在时间段内
-- SHARK_UNION_INSPIRE_USER_NOT_APPLY(6615, "User not apply inspire city: {0:uid}, {1:cityId}"),--当前玩家没有报名该城池
-- SHARK_UNION_GEM_INSPIRE_NUM_REACH_LIMIT(6616, "User gem inspire num reach limit: {0:uid}, {1:cityId}, {2:inspireNum}"),--金币鼓舞次数达上限
-- SHARK_UNION_COIN_INSPIRE_NUM_REACH_LIMIT(6617, "User coin inspire num reach limit: {0:uid}, {1:cityId}, {2:inspireNum}"),--银币
-- SHARK_UNION_STRIVE_INSPIRE_NUM_REACH_LIMIT(6618, "User strive inspire num reach limit: {0:uid}, {1:cityId}, {2:inspireNum}"),--奋力一击
-- SHARK_UNION_BUFF_ID_NOT_SUPPORT(6619, "Inspire BuffId is not support: {0:uid}, {1:buffId}"),--buffid错误--不提示
-- SHARK_UNION_STRIVE_INSPIRE_USER_IS_FORWARD(6620, "Strive inspire user is forward: {0:uid}"),--先锋不能奋力一击(前端提前校验)

-- gainUnionBattleReward错误码
-- SHARK_UNION_WAR_GAIN_REWARD_NOT_OPEN(6621, "Union war gain reward is not open: {0:uid}"),--不在领奖时间段内
-- SHARK_UNION_USER_ALREADY_GAIN_DAILY_REWARD(6622, "User already gain daily reward: {0:uid}"),--每日奖励已获得
-- SHARK_UNION_USER_IS_NOT_IN_UNION_MEMBER(6623, "User is not in union member: {0:uid}, {1:unionId}"),--玩家不在军团成员里
-- SHARK_UNION_HAS_NO_OWN_CITY(6624, "Union has no own city: {0:uid}, {1:unionId}"),--所处军团没有占领的城池
-- SHARK_UNION_DAILY_REWAR_NOT_CONFIG(6625, "Daily reward is not config: {0:uid}, {1:cityType}, {2:title}"),--每日奖励无配置--不提示
-- SHARK_UNION_USER_ALREADY_GAIN_PLAY_REWARD(6626, "User already gain play reward: {0:uid}"),--已经领取参与奖
-- SHARK_UNION_NOT_ATTEND_UNION_WAR(6627, "User union not attend union war: {0:uid}, {1:unionId}"),--军团没有参与到军团战
-- SHARK_UNION_USER_ALREADY_GAIN_OCCUPY_REWARD(6628, "User already gain occupy reward: {0:uid}"),--已经领取占领奖励
-- SHARK_UNION_HAS_NO_OCCUPY_INFO(6629, "User union has no occupy info: {0:uid}, {1:unionId}"),--占领信息不存在--不提示
-- SHARK_UNION_OCCUPY_REWARD_NOT_CONFIG(6630, "Occupy reward is not config: {0:uid}, {1:cityType}"),--配置不存在--不提示
-- SHARK_UNION_REWARD_TYPE_NOT_SUPPORT(6631, "Reward type is not support: {0:uid}, {1:rewardType}"),--传的奖励类型不支持--不提示