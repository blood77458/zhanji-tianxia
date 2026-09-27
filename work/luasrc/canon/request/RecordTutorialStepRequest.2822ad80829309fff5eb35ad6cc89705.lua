
require "canon.request.BaseRequest"

RecordTutorialStepRequest = class(BaseRequest)

function RecordTutorialStepRequest:ctor(params)
    self.endpoint = "recordTutorialStep"
	self.data = nil
	self.showLoading = false
	self.params = params
end

function RecordTutorialStepRequest:onSuccess( data )
  print("RecordTutorialStepRequest success")
end

function RecordTutorialStepRequest:onError( error )
    BaseRequest.onError(self, error)
end