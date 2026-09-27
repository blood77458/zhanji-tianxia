require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GetSharkBeastFragments = class(BaseRequest)

function GetSharkBeastFragments:ctor()
  self.endpoint = METHOD_GETSHARKBEASTFRAGMENTS
end

function GetSharkBeastFragments:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetSharkBeastFragmentsSucceed, data))
end

function GetSharkBeastFragments:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetSharkBeastFragmentsFailed, error))
end