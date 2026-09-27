require "hecore.utils"

ResCallbackEvent = table.const {
  onSuccess = "onSucess",
  onError = "onError",
  onProcess = "onProcess",
  onPrompt = "onPrompt"
}

ResourceLoader = { }

function ResourceLoader.init()
  return ResManager:getInstance():initStaticConfig();
end

function ResourceLoader.getCurVersion()
  return ResManager:getInstance():getCurVersion()
end

function ResourceLoader.getFileSize(virtualPath)
  return ResManager:getInstance():getFileSize(virtualPath)
end 

function ResourceLoader.loadRequiredRes(callback)
  local function onSuccess(data, needDownLoadData)
    callback(ResCallbackEvent.onSuccess, { items = data , needDownLoadData = needDownLoadData})
  end
  local function onError(errorCode, item)
    callback(ResCallbackEvent.onError, { errorCode = errorCode, item = item })
  end
  local function onProcess(process)
    callback(ResCallbackEvent.onProcess, process)
  end
  ResManager:getInstance():loadRequiredRes(onSuccess, onError, onProcess)
end

function ResourceLoader.loadRequiredResWithPrompt(callback)
  local function onSuccess(data, needDownLoadData)
    callback(ResCallbackEvent.onSuccess, { items = data , needDownLoadData = needDownLoadData})
  end
  local function onError(errorCode, item)
    callback(ResCallbackEvent.onError, { errorCode = errorCode, item = item })
  end
  local function onProcess(process)
    callback(ResCallbackEvent.onProcess, process)
  end
  local function onPrompt(data)
    callback(ResCallbackEvent.onPrompt, { status = data, resultHandler = function(r) 
            ResManager:getInstance():notifyPromptResult(r)
          end })
  end
  ResManager:getInstance():loadRequiredResWithPrompt(onSuccess, onError, onProcess, onPrompt)
end

function ResourceLoader.loadSpecifiedRes(virtualPaths, callback)
  local function onSuccess(data)
    callback(ResCallbackEvent.onSuccess, data)
  end
  local function onError(errorCode, item)
    callback(ResCallbackEvent.onError, { errorCode = errorCode, item = item })
  end
  local function onProcess(process)
    callback(ResCallbackEvent.onProcess, process)
  end
  ResManager:getInstance():loadSpecifiedRes(virtualPaths, onSuccess, onError, onProcess)
end

-- param 是callback的参数，多个参数时就用table
function ResourceLoader.loadThirdPartyRes(urls, callback, param)
  local function onSuccess(data)
    callback(ResCallbackEvent.onSuccess, data, param)
  end
  local function onError(errorCode, item)
    callback(ResCallbackEvent.onError, { errorCode = errorCode, item = item })
  end
  ResManager:getInstance():loadThirdPartyRes(urls, onSuccess, onError)
end

function ResourceLoader.downloadNewVersion()
  ResManager:getInstance():downloadNewVersion()
end
