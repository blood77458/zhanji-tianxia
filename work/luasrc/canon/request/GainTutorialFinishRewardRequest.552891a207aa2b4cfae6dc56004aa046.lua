
require "canon.request.BaseRequest"

GainTutorialFinishRewardRequest = class(BaseRequest)

function GainTutorialFinishRewardRequest:ctor()
    self.endpoint = "gainTutorialFinishReward"
end

function GainTutorialFinishRewardRequest:onSuccess( data )
    --print("GachaCard Success: " .. table.serialize(data))
    HeMemDataHolder:setString("GainTutorialFinishReward", table.serialize(data));
    if data.limitTime then
    	Activity_rechargeLayer.getRechargeData()
    	local gameInitData = DataManager.getGameInitData()
    	gameInitData.sharkActivity.flashRecharge.times = data.limitTime
    	DataManager.setGameInitData(gameInitData)
        Activity_rechargeLayer.showGuidePanel = true
        Activity_ExchangeDailyLayer.showGuidePanel = true
    end
    self:dispatchEvent(Event.new(RequestNotifyEnum.GainTutorialFinishRewardSucceed,data))    
end

function GainTutorialFinishRewardRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.GainTutorialFinishRewardFailed,error))    
--    BaseRequest.onError(self, error)
end


