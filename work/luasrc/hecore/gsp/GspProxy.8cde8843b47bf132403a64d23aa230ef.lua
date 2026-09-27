require "hecore.utils"
require "hecore.luaJavaConvert"

GspModuleName = table.const {
  CUSTOMERSUPPORT = "CUSTOMERSUPPORT",
  NOTIFICATION = "NOTIFICATION",
  AD = "AD",
  PAYMENT = "PAYMENT"
}

GspRetCode = table.const {
  SUCCESS = 0
}

GspPaymentChannel = table.const {
  GOOGLEIAB = "GOOGLEIAB",
  GASH = "GASH"
}

GspPaymentEvent = table.const {
  onSuccess = "onSuccess",
  onFailed = "onFailed",
  onAbort = "onAbort",
  onPending = "onPending"
}

GspGetValidSkuListEvent = table.const {
  onSuccess = "onSuccess",
  onError = "onError"
}

local GspProxyAndroid = {}

function GspProxyAndroid:init(callback)
  self.instance = luajava.bindClass("com.happyelements.android.gsp.GspProxy"):getInstance()
  self.instance:setGspAppId(StartupConfig:getInstance():getGspAppId())
  self.instance:setGspSecretKey(StartupConfig:getInstance():getGspSecretKey())
  local _gspModuleInitCallback = luajava.createProxy("com.happyelements.android.gsp.GspModuleInitCallback",
    { 
      onModuleComplete = function(_module, _code)
        local module_name = _module:toString()
        if GspModuleName[module_name] ~= nil then
          callback(module_name, _code:getValue())
        end
      end
    }
  )
  self.instance:init(_gspModuleInitCallback)
end

function GspProxyAndroid:showCustomerDiaLog()
  self.instance:showCustomerDiaLog()
end

function GspProxyAndroid:showOffersWall()
  self.instance:showOffersWall()
end

function GspProxyAndroid:showOffersWallDialog()
  self.instance:showOffersWallDialog()
end

local function createTransactionCallback(callback)
  local transactionCallback = luajava.createProxy("com.happyelements.gsp.android.payment.TransactionCallback",
    {
      onSuccess = function(orderId)
        callback(GspPaymentEvent.onSuccess, { orderId = orderId })
      end,
      onFailed = function(errorCode, message)
        callback(GspPaymentEvent.onFailed, { errorCode = errorCode:getValue(), message = message })
      end,
      onAbort = function(orderId)
        callback(GspPaymentEvent.onAbort, { orderId = orderId })
      end,
      onPending = function(orderId)
        callback(GspPaymentEvent.onPending, { orderId = orderId })
      end
    }
  )
  return transactionCallback
end

function GspProxyAndroid:buy(channelId, channelParams, goodsName, price, currency, extend, callback)
  self.instance:getPaymentProxy():buy(channelId, luaJavaConvert.table2Map(channelParams), goodsName, price, currency, extend, createTransactionCallback(callback))
end

function GspProxyAndroid:recharge(channelId, channelParams, coinAmount, extend, callback)
  self.instance:getPaymentProxy():recharge(channelId, luaJavaConvert.table2Map(channelParams), coinAmount, extend, createTransactionCallback(callback))
end

function GspProxyAndroid:getValidSkuList(channelId, channelParams, filterSkuIds, locale, callback)
  local m_callback = luajava.createProxy("com.happyelements.gsp.android.base.CallbackBase",
    {
      onSuccess = function(data)
        local t1 = luaJavaConvert.list2Table(data)
        local t2 = {}
        for i,v in ipairs(t1) do
          local t = {}
          t.currency = v:getCurrency()
          t.description = v:getDescription()
          t.orgData = v:getOrgData()
          t.price = v:getPrice()
          t.skuId = v:getSkuId()
          t.title = v:getTitle()
          t.type = v:getType()
          table.insert(t2, t)
        end
        callback(GspGetValidSkuListEvent.onSuccess, t2)
      end,
      onError = function(errorCode, message)
        callback(GspGetValidSkuListEvent.onError, { errorCode = errorCode:getValue(), message = message })
      end
    }
  )
  self.instance:getPaymentProxy():getValidSkuList(channelId, luaJavaConvert.table2Map(channelParams), luaJavaConvert.table2List(filterSkuIds), locale, m_callback)
end

local GspProxyIOS = {}

GspProxy = nil

if __ANDROID then
  GspProxy = GspProxyAndroid
elseif __IOS then
  GspProxy = GspProxyIOS
end

