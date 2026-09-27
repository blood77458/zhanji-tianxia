----------------------------
--阵魂相关
--by dangchao
--2015/4/9
----------------------------

MagicCircleManager = {}

MagicCircleManager.magic_circle = require "canon.configs.magic_circle"

MagicCircleType = {
	--阵魂灯的加成类型
	Atk = 1,	--攻击
	Def = 2,	--防御
	Hp = 3,		--血量
	Crt = 4,	--暴击
	Eva = 5,	--闪避
	Par = 6,	--格挡
	Tou = 7,	--韧性
	Hit = 8,	--命中
	Prc = 9,	--破击
}
MagicCircleManager.magicCircleInfoTable = {}

function MagicCircleManager.GetMagicCircleInfoTable()
	return MagicCircleManager.magicCircleInfoTable
end

--初始化magicCircleInfoTable
function MagicCircleManager.InitMagicCircleInfoByMatrixId(matrixId)
	if matrixId == nil then
		--没有阵法信息
		return
	end
	local magicTotelNum = 0
	local magicCircleInfo = {}
	for k,v in pairs(MagicCircleManager.magic_circle) do 
		if v.magicCircleID == matrixId then
			magicTotelNum = magicTotelNum + 1
			table.insert(magicCircleInfo ,{
							magicCircleId = v.ID,
							magicCircleType = v.magicCircleType,
							magicCircleNum = v.magicCircleNum,
							isOpen = false --初始默认为未点亮
							})
		end
	end
	MagicCircleManager.magicCircleInfoTable[matrixId] = {magicTotelNum = magicTotelNum, magicCircleInfo = magicCircleInfo}
end

--返回该阵存在的总灯数，及满足点亮的阵魂灯
function MagicCircleManager.GetMagicCircleInfoByMatrixId(matrixId)
	if matrixId == nil then
		--没有阵法信息
		return
	end
	if MagicCircleManager.magicCircleInfoTable[matrixId] then
		--之前已经处理过，可以直接获取
		return MagicCircleManager.magicCircleInfoTable[matrixId]
	end
	
	MagicCircleManager.InitMagicCircleInfoByMatrixId(matrixId)
	MagicCircleManager.RefreshMagicCircleInfoByMatrixId(matrixId)
	return MagicCircleManager.magicCircleInfoTable[matrixId]
end

function MagicCircleManager.SetMagicCircleInfoByMatrixId(magicCircleInfo,matrixId)
	MagicCircleManager.magicCircleInfoTable[matrixId] = magicCircleInfo
end 

--刷新MatrixId代表的阵法中，满足点亮条件的阵魂灯
function MagicCircleManager.RefreshMagicCircleInfoByMatrixId(matrixId)
	if matrixId == nil then
		--没有阵法信息
		return
	end
	if MagicCircleManager.magicCircleInfoTable[matrixId] then
	else
		MagicCircleManager.InitMagicCircleInfoByMatrixId(matrixId)
	end
	local magicCircleInfo =  MagicCircleManager.magicCircleInfoTable[matrixId]
	--每个阵法的阵魂灯点亮的条件不一样，需要单独判断，没配置，自己按文档写
	if matrixId == 10 then
		--八门金锁阵：
			--阵魂灯有两个，点亮条件如下：
			--出战和上阵的同名武将少于或等于2名 全队配置（增加20%防御力）
			--出战和上阵的武将中没有同名武将 全队配置（增加20%防御力）
		local cardGroup = MetaManager.getCardGroupInfoInCurBattleArray(matrixId)
		local open1 = true
		local open2 = true
		for k,v in pairs(cardGroup) do 
			if v >= 2 then
				open2 = false
			end	
			if v >= 3 then
				open1 = false
			end
		end
		if magicCircleInfo.magicCircleInfo[1] then
			if open1 then
				magicCircleInfo.magicCircleInfo[1].isOpen = true
			else
				magicCircleInfo.magicCircleInfo[1].isOpen = false
			end
		end
		if magicCircleInfo.magicCircleInfo[2] then
			if open2 then
				magicCircleInfo.magicCircleInfo[2].isOpen = true
			else
				magicCircleInfo.magicCircleInfo[2].isOpen = false
			end
		end
	else
		--后续其他阵法扩展
	end
	MagicCircleManager.SetMagicCircleInfoByMatrixId(magicCircleInfo,matrixId)
	return magicCircleInfo
end

MagicCircleStatus = {
	--阵魂灯显示状态
	Lock = -1,	--未解锁阵魂灯
	White = 0,	--未达成任何阵魂灯条件
	Green = 1,	--达成一个阵魂灯条件
	Blue = 2,	--达成两个阵魂灯条件
}

--获取当前阵魂点亮的状态
function MagicCircleManager.GetCurMagicCircleStatus()
	local queueData = CommonManager.getQueueData( )
	local magicCircleStatus = MagicCircleStatus.Lock
	
	--阵魂解锁条件，按上阵武将个数解锁
	local magicCircleOpen = MetaManager.game_meta.gameSettingConfig.magicCircleOpen or 7
	if table.getn(queueData) >= magicCircleOpen then
		local curMatrixId = MetaManager.getCurInBattleMatrixId()
		local magicCircleInfo = MagicCircleManager.GetMagicCircleInfoByMatrixId(curMatrixId)
		local openNum = 0
		for mck,mcv in pairs(magicCircleInfo.magicCircleInfo) do 
			if mcv.isOpen then
				openNum = openNum + 1
			end
		end
		if openNum == 0 then
			magicCircleStatus = MagicCircleStatus.White
		elseif openNum == 1 then
			magicCircleStatus = MagicCircleStatus.Green
		elseif openNum == 2 then
			magicCircleStatus = MagicCircleStatus.Blue
		else
			--可扩展
		end
	end
	return magicCircleStatus
end

--判断当前阵魂是否解锁
function MagicCircleManager.IsCurMagicCircleOpen()
	local queueData = CommonManager.getQueueData( )
	local magicCircleStatus = MagicCircleStatus.Lock
	--阵魂解锁条件，按上阵武将个数解锁
	local magicCircleOpen = MetaManager.game_meta.gameSettingConfig.magicCircleOpen or 7
	if table.getn(queueData) >= magicCircleOpen then
		return true
	else
		return false
	end
end
