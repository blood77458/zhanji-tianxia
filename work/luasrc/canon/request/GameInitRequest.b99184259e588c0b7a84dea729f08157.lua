
require "canon.request.BaseRequest"
require "canon.utils.TimeUtil"
require "canon.manager.DailyDataManager"

GameInitRequest = class(BaseRequest)

function GameInitRequest:ctor()
    self.endpoint = "gameInit"
end

function GameInitRequest:onSuccess( data )
    --print("GameInit Success: " .. table.serialize(data))
  local function isCurVipMaxLevel(level)--判断VIPLEVEL是否为最大
    local maxLevel = 0
    for k,v in pairs(MetaManager.vip_setting) do
      if maxLevel < v.level then
        maxLevel = v.level
      end
    end
    return level >= maxLevel
  end

  data.sharkEquips = data.sharkEquips or {sharkEquips = {}}
  data.sharkProps = data.sharkProps or {sharkProps = {}}

  while not isCurVipMaxLevel(data.sharkUser.vipLevel) and (data.sharkUser.rechargeGems + data.sharkUser.vipExp) >= MetaManager.vip_setting[data.sharkUser.vipLevel + 1].requireGold do
    data.sharkUser.vipLevel = data.sharkUser.vipLevel + 1
  end

	DataManager.setGameInitData( data )
  DataManager.resetDataTimestamp()
  CountryManager:sharedManager():initializeData()
  ArenaManager:sharedManager():initializeData()
  --EventManager:sharedManager():initializeData()
  ChatManager.resetChatInfo()
  DcManager.refreshVipLevel()

  local aOldTime = TimeUtil.getServerTimeSeconds()
  HeMemDataHolder:setInteger("oldTime", aOldTime)
  
  DailyDataManager.init()

  Activity_rechargeLayer.recharge_data_Ready = false
  Activity_rechargeLayer.showGuidePanel = false
  Activity_ExchangeDailyLayer.showGuidePanel = false
  sacrifice_already_showed = false
  statusList = {}
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GameInitSucceed,data))    
end

function GameInitRequest:onError( error )
    BaseRequest.onError(self, error)
end