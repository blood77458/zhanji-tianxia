--------------------------------------------------------------------------------
-- SearchUserByNicknameRequest.lua - 据昵称查找用户
-- author: xiaojie.bai
-- date: 2013-08-21 15:32
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

SearchUserByNicknameRequest = class(BaseRequest)

function SearchUserByNicknameRequest:ctor()
  self.endpoint = METHOD_SEARCHUSERBYNICKNAME
end

function SearchUserByNicknameRequest:onSuccess( data )
  he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.SearchUserByNicknameSucceed, data))
end

function SearchUserByNicknameRequest:onError( error )
  BaseRequest.onError(self, error)
end