-- ErrorCodeManager.lua
-- 2014-11-14
-- zheng.che
-- 错误码管理器 所有错误码集结于此

ErrorCodeManager = {}

local _codes

-------------------------------------------------
-- 操作
-------------------------------------------------

function ErrorCodeManager.startup()
	if _codes == nil then
		_codes = {}

		------------------------------------------------------------------------------------------------------------------------------通用

		_codes[710512] = {startCallback=ErrorCodeManager.silverNotEnouth}--银币不足
		_codes[710513] = {startCallback=ErrorCodeManager.goldNotEnough}--金币不足
		_codes[710516] = {startCallback=ErrorCodeManager.packageIsFull}--格子不够

		------------------------------------------------------------------------------------------------------------------------------军团战

		_codes[716313] = {txtCode="UnionWar_error_txt12"}--主公，您没有在本军团内哦
		--_codes[716315] = {txtCode="xxx"}--玩家军团信息不存在--无提示
		_codes[716317] = {txtCode="WGVG_Error01"}--您已经失去相关权限。
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

		--2015-1-5 追加优化
		-- _codes[716640] = {txtCode="xxx"}--UnionWarLimitMeta is not configed 不提示
		-- _codes[716641] = {txtCode="xxx"}--Apply city union level not enough 在接口里单独提示
		-- _codes[716642] = {txtCode="xxx"}--Apply city union fight capacity not enough 在接口里单独提示

		--2015-1-31 追加 一定程度规避cityid为0的bug
		_codes[716601] = {txtCode="UnionWar_optimize_error2"}--城池信息出现错误，请您返回游戏首页并重新进入军团尝试。

		------------------------------------------------------------------------------------------------------------------------------卡牌以旧换新

		_codes[714700] = {txtCode="activity_contend_close"}--cardExchange activity closed 活动我未开启
		-- _codes[714701] = {txtCode="xxx"}--cardExchange last times not enough
		-- _codes[714702] = {txtCode="xxx"}--cardExchange insufficient quantity of material cards
		-- _codes[714703] = {txtCode="xxx"}--Material card can not reincarnate
		-- _codes[714704] = {txtCode="xxx"}--card rare is not enough
		-- _codes[716484] = {txtCode="xxx"}--星灵数不够
		-- _codes[711001] = {txtCode="xxx"}--Card is not configed in card-meta.xml
		-- _codes[710070] = {txtCode="xxx"}--User is not exist
		-- _codes[711051] = {txtCode="xxx"}--User does not own card
		-- _codes[711081] = {txtCode="xxx"}--Card is locked
		-- _codes[711059] = {txtCode="xxx"}--card is in battle queue
		-- _codes[711062] = {txtCode="xxx"}--Card is in matrix
		_codes[714717] = {txtCode="EC_COMMON_TXT"}

		------------------------------------------------------------------------------------------------------------------------------装备附灵
		-- _codes[711605] = {txtCode="xxx"}--Spirit value not enough
		-- _codes[711606] = {txtCode="xxx"}--Equip enchant level is max

		------------------------------------------------------------------------------------------------------------------------------许愿池
		_codes[714750] = {txtCode="activity_contend_close"}--activityWishing is closed 活动我未开启

		------------------------------------------------------------------------------------------------------------------------------多重好礼
		_codes[714770] = {txtCode="activity_contend_close"}--activityConsumeReward is closed 活动我未开启
		-- _codes[714771] = {txtCode="xxx"}--consumeRewardInfo is not exist
		-- _codes[714772] = {txtCode="xxx"}--activityConsumeReward is already gain
		-- _codes[714773] = {txtCode="xxx"}--activityConsumeReward.xml not config
		-- _codes[714774] = {txtCode="xxx"}--activityConsumeReward the recharge not enough
		------------------------------------------------------------------------------------------------------------------------------跨服PVP
		_codes[716991] = {txtCode="crossArena_tips1"}--列表过期

		------------------------------------------------------------------------------------------------------------------------------跨服GVG
		-- _codes[717000] = {txtCode="xxx"}--crossgvg inspire not open:{0:uid}
		-- _codes[717001] = {txtCode="xxx"}--crossgvg inspire not same union:{0:uid},{1:union},{2:appliedUnion}
		_codes[717002] = {txtCode="WGVG_Error11"}--军团金币鼓舞已经达到上限。(同时改当前值为上限)
		-- _codes[717003] = {txtCode="xxx"}--crossgvg coin inspire num reach limit:{0:uid},{1:coinInspireNum}
		-- _codes[717004] = {txtCode="xxx"}--crossgvg strive inspire num reach limit:{0:uid},{1:striveInspireNum}
		-- _codes[717005] = {txtCode="xxx"}--crossgvg buff id not support:{0:uid},{1:type}
		-- _codes[717006] = {txtCode="xxx"}--crossgvg can not apply:{0:uid},{1:type}
		-- _codes[717007] = {txtCode="xxx"}--crossgvg already apply:{0:uid}
		-- _codes[717008] = {txtCode="xxx"}--crossgvg not apply:{0:uid}
		-- _codes[717009] = {txtCode="xxx"}--crossgvg group match not open: {0:uid}, {1:currSeconds}
		-- _codes[717010] = {txtCode="xxx"}--crossgvg exchange formation already exchanged: {0:uid}, {1:formationVersion}
		-- _codes[717011] = {txtCode="xxx"}--crossgvg exchange formation exchange failed: {0:uid}, {1:formationVersion}
		-- _codes[717012] = {txtCode="xxx"}--crossgvg exchange formation not allowed: {0:uid}
		-- _codes[717013] = {txtCode="xxx"}--crossgvg apply level limit: {0:uid}, {1:unionLevel}, {2:unionLevelNeed}
		 _codes[717014] = {txtCode="WGVG_Error12"}--crossgvg not apply current union:{0:uid}, {1:version},{2:unionId},{3:currUnionId}
		-- _codes[717015] = {txtCode="xxx"}--crossgvg can not phase worship: {0:uid}
		-- _codes[717016] = {txtCode="xxx"}--crossgvg phase worship times full: {0:uid}, {1:crossGVGPhaseWorshipTimes}

		-- _codes[717017] = {txtCode="xxx"}--crossgvg role is null: {0:uid}
		-- _codes[717018] = {txtCode="xxx"}--crossgvg reward meta not exist: {0:uid}, {1:unionRank}
		-- _codes[717019] = {txtCode="xxx"}--crossgvg user not apply: {0:uid}
		-- _codes[717020] = {txtCode="xxx"}--crossgvg union is not in ranking: {0:uid}, {1:unionId}, {2:groupId}
		-- _codes[717021] = {txtCode="xxx"}--crossgvg group is null: {0:uid}, {1:groupId}, {2:version}
		-- _codes[717022] = {txtCode="xxx"}--crossgvg union is null: {0:uid}, {1:unionId}
		-- _codes[717023] = {txtCode="xxx"}--crossgvg battle union is busy: {0:uid}, {1:selfUnionId}, {2:enemyUnionId}
		-- _codes[717024] = {txtCode="xxx"}--crossgvg battle result is null: {0:uid}, {1:knockout}, {2:reportId}
		-- _codes[717025] = {txtCode="xxx"}--crossgvg group battle not open: {0:uid}, {1:currSeconds}
		-- _codes[717026] = {txtCode="xxx"}--crossgvg daily battle report is null: {0:uid}, {1:reportId}
		-- _codes[717027] = {txtCode="xxx"}--crossgvg knockout report is null: {0:uid}, {1:groupId}, {2:version}, {3:reportId}
		-- _codes[717028] = {txtCode="xxx"}--crossgvg server info is null: {0:uid}, {1:version}
		_codes[717029] = {txtCode="WGVG_Error09"}--没有可以匹配到的军团。
		_codes[717030] = {txtCode="WGVG_Error08"}--军团每日战斗次数已达上限。(同时改挑战次数为上限数值)
		-- _codes[717031] = {txtCode="xxx"}--crossgvg already gained knockout reward: {0:uid}

		-- _codes[717032] = {txtCode="xxx"}--crossgvg can not gain bless reward: {0:uid}, {1:winnerUnionId}, {2:managerId}
		-- _codes[717033] = {txtCode="xxx"}--crossgvg group id = 0: {0:uid}
		-- _codes[717034] = {txtCode="xxx"}--crossgvg user can not upload mirror: {0:uid}
		_codes[717035] = {txtCode="WGVG_Error10"}--该玩家已不处于本军团。
		-- _codes[717036] = {txtCode="xxx"}--crossgvg knockout has no winner: {0:uid}, {1:groupId}, {2:version}
		-- _codes[717037] = {txtCode="xxx"}--crossgvg version info is null: {0:uid}, {1:version}
		-- _codes[717037] = {txtCode="xxx"}--crossgvg can not get knockout status: {0:uid}
		-- _codes[717038] = {txtCode="xxx"}--crossgvg daily challenged num limit: {0:uid}, {1:unionId}, {2:challengeNum}
		------------------------------------------------------------------------------------------------------------------------------跨服GVG
		_codes[717025] = {txtCode="WGVG_Detail63"}--列表过期
		_codes[716430] = {txtCode="WGVG_Error01"}--User has no privilige to apply cross gvg union
		_codes[716431] = {txtCode="WGVG_Error01"}--User has no privilige to exchange formation cross gvg
		_codes[716432] = {txtCode="WGVG_Error01"}--User has no privilige to group battle cross gvg
	end
	
end

function ErrorCodeManager.clear()
end

-------------------------------------------------
-- 接口
-------------------------------------------------

function ErrorCodeManager.alert(errorCode, callbackWithCode)
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
function ErrorCodeManager.silverNotEnouth(errorCode)
	local scene = Director:mgr():run()
	local aPanel = MessageBoxPanel:create(scene, MessageBoxType.kCoinLimit)
	scene:addChild(aPanel)
	aPanel:scaleIn()
end

--弹出 金币不足 提示
function ErrorCodeManager.goldNotEnough(errorCode)
	local scene = Director:mgr():run()
	local aPanel = AssistantMessageBoxPanel:create(scene, AsMessageBoxType.addCoin, nil)
	scene:addChild(aPanel)
	aPanel:scaleIn()
end

--弹出 背包扩容 提示
function ErrorCodeManager.packageIsFull(errorCode)
	local scene = Director:mgr():run()
	scene.targetInfoPanel = NewPackageFullPanel:show()
end