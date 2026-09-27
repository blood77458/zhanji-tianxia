require "canon.request.BaseRequest"

ChangeBattleArrayRequest = class(BaseRequest)

function ChangeBattleArrayRequest:ctor(params, priority)
	self.endpoint = "changeBattleArray"--<<<<< 1. 修改指令名称 后端提供
  	self.succeedEventName = self.endpoint .. "Succeed"
  	self.failedEventName = self.endpoint .. "Failed"
end

function ChangeBattleArrayRequest:onSuccess( data )
  	self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function ChangeBattleArrayRequest:onError(error)
  	self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function ChangeBattleArrayRequest.sendRequestDefalut(battleArrayId, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		ChangeBattleArrayRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	ChangeBattleArrayRequest.sendRequest(battleArrayId, onSucceed, ChangeBattleArrayRequest.onFailedDefault)
end

function ChangeBattleArrayRequest.sendRequest(battleArrayId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {battleArrayId = battleArrayId}--<<<<< 3

	local function onSucceedHandle(event)
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

	local request = ChangeBattleArrayRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)--<<<<< 2
	request:addEventListener(request.failedEventName, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function ChangeBattleArrayRequest.onSucceedDefault(event)--<<<<< 3
  local GameData = DataManager.getGameInitData()
	local BattleArrayId = GameData.sharkUserExtendMore.battleArrayId
	local nowId = event.params.battleArrayId

	GameData.sharkUserExtendMore.battleArrayId = nowId
	
  	local cardsInfo = GameData.sharkCards and GameData.sharkCards.sharkCards or {}
  	local equipsData = GameData.sharkEquips and GameData.sharkEquips.sharkEquips or {}
  	local spiritData = GameData.sharkSpirits and GameData.sharkSpirits.sharkSpirits or {}
    local treasureData = GameData.sharkTreasures and GameData.sharkTreasures.sharkTreasures or {}

  	local BattleQueue = GameData.sharkUserBattleArray[nowId]
  	local additionalCardIdStr = ""

  	--导入阵型信息
  	for k,v in pairs(BattleQueue.sharkUserQueue) do
  	  if k~=1 then 
  	  	additionalCardIdStr = additionalCardIdStr .. "," .. v.cardId
  	  else
  	  	GameData["sharkUser"]["mainCardId"] = v.cardId
  	  end
  	end
  	additionalCardIdStr = string.sub(additionalCardIdStr, 2, -1)
  	GameData["sharkUser"]["additionalCardIds"] = additionalCardIdStr
  	--print(additionalCardIdStr)

  	--导入阵法武将信息
  	local tmpMatrix = BattleQueue.sharkMatrices and BattleQueue.sharkMatrices.sharkMatrices or {}
    if not GameData["sharkMatrices"] then GameData["sharkMatrices"] = {} end
    if not GameData["sharkMatrices"]["sharkMatrices"] then GameData["sharkMatrices"]["sharkMatrices"] = {} end
  	for k,v in pairs(GameData["sharkMatrices"]["sharkMatrices"]) do
  	  v.sharkMatrixGrids = {}
  	  for _,value in pairs(tmpMatrix) do
  	  	if value.matrixId == v.matrixId then v.sharkMatrixGrids = value.sharkMatrixGrids end
  	  end
  	end

  	--导入卡牌，装备，圆神信息
  	  --定位并脱掉
  	local posCards = {}
  	for k,v in pairs(cardsInfo) do
  	  posCards[v.cardId] = k
  	  v.equipIds = {}
  	  v.cardSpirits = {}
      v.treasureId = 0
  	end
  	local posEquips = {}
  	for k,v in pairs(equipsData) do
  	  posEquips[v.equipId] = k
  	  if v.cardId then v.cardId = 0 end
  	end
  	local posSpirits = {}
  	for k,v in pairs(spiritData) do
  	  posSpirits[v.spiritId] = k
  	  if v.cardId then v.cardId = 0 end
  	end
    local posTreasure = {}
    for k,v in pairs(treasureData) do
      posTreasure[v.treasureId] = k
      if v.cardId then v.cardId = 0 end
    end


  	  --穿上装备和圆神
  	for k,v in pairs(BattleQueue.sharkUserQueue) do
    	if type(v.equips) == "table" then 
    	  for _,value in pairs(v.equips) do
    	    table.insert(cardsInfo[posCards[v.cardId]].equipIds,value)
    	    equipsData[posEquips[value]].cardId = v.cardId
    	  end 
    	end
    	if type(v.spirits) == "table" then 
    	  for _,value in pairs(v.spirits) do
    	    table.insert(cardsInfo[posCards[v.cardId]].cardSpirits,value)
    	    spiritData[posSpirits[value.spiritId]].cardId = v.cardId
    	  end 
    	end
      if v.treasureId ~= 0 then
        cardsInfo[posCards[v.cardId]].treasureId = v.treasureId
        treasureData[posTreasure[v.treasureId]].cardId = v.cardId
      end
  	end

  	DataManager.setGameInitData(GameData)
  	DataManager.setCardsData(cardsInfo)
  	DataManager.setEquipsData(equipsData)
  	DataManager.setSpiritsData(spiritData)
    DataManager.setTreasuresData(treasureData)
    g_cardInfoCache = {}  --卡牌信息缓存 保证背包显示的攻防血与阵容一致
    g_cardCountryNumCache = {} --国籍人数缓存
    g_previousSkillTable = nil --连携技能缓存
    g_shouldCalc = true
    g_previousBonusTable = nil; --阵法加成缓存
    --CommonManager.cacheCardInfo()
end

--失败默认处理
function ChangeBattleArrayRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end