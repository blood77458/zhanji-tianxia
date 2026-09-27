if not __IOS then
  return
end

waxClass{"IosPaymentLua", NSObject, protocols = {"GspPaymentDelegate", "SKProductsRequestDelegate"}}

local _instance = nil
local _canPurchase = true
local _paymentObject;
local _finishCallback;

local _isPaymentAction = false

local _iapConfig = nil

valid_locale_error_code = 9999

function getInstance(self)
	if (_instance == nil) then
		_instance = self:init()
	end
	return _instance
end

function init(self)
	self.super:init()
	_canPurchase = true
	return self
end

function isSouthAfriceLocale(product)
	if product:priceLocale():localeIdentifier() == "en_ZA@currency=ZAR" then
		return true
	else
		return false
	end
end

function isInvalidLocale(product)
	print("_________________________________")
	print(product:priceLocale():localeIdentifier())
	if product:priceLocale():localeIdentifier() == "en_ZA@currency=ZAR" then	--南非兰特
		return true
	elseif product:priceLocale():localeIdentifier() == "ja_JP@currency=JPY" then				--日币
		return true
	else
		return false
	end
end

function getValidSkuList(self, productIds)
	if _iapConfig and #_iapConfig > 0 then
		return
	end
	if (_paymentObject == nil) then
		_paymentObject = GspEnvironment:getGspPaymentAgent():startTransaction_channelParams(0, nil)
	end
	local payStatus = _paymentObject:getPaymentStatus()
	if _canPurchase == true and payStatus then
		_paymentObject:setDelegate(self)

		_paymentObject:setValue_forKey(NSNumber:numberWithBool(false), "isGetLocal")
		_paymentObject:setValue_forKey(NSNumber:numberWithBool(false), "isPaymentAction")

		_isPaymentAction = false
		_paymentObject:setValue_forKey(productIds, "iap_server_config")

		local productIdentifiers = NSMutableSet:initWithCapacity(#productIds)
		for _,v in pairs(productIds) do
			productIdentifiers:addObject(v)
		end
		if SKPaymentQueue:canMakePayments() then
			local productRequest = SKProductsRequest:initWithProductIdentifiers(productIdentifiers)
	    	productRequest:setDelegate(self)
	    	productRequest:start()
	    end
	end
end

function pay(self, productId, extendString, finishCallback)
	if (_paymentObject == nil) then
		_paymentObject = GspEnvironment:getGspPaymentAgent():startTransaction_channelParams(0, nil)
	end
	local payStatus = _paymentObject:getPaymentStatus()
	if _canPurchase == true and payStatus then
		_finishCallback = finishCallback

		_paymentObject:setDelegate(self)
		_paymentObject:setExtendString(extendString)

		if productId == "" or productId == nil then
			_finishCallback(false)
		end

		local productIds = NSMutableSet:setWithObject(productId)
		_paymentObject:setValue_forKey(NSNumber:numberWithBool(false), "isGetLocal")
		_paymentObject:setValue_forKey(NSNumber:numberWithBool(true), "isPaymentAction")
		_paymentObject:setUserID(GspMetaHive:getInstance():gameUserId())

		_isPaymentAction = true

		local ret = handleValidPayment()
		if ret == true then
			return
		end

		GspMBProgressHUD:showHUDAddedTo_animated(UIApplication:sharedApplication():windows()[1], true)
		if GspMetaInfo:getInstance():getCurrntNet("http://www.apple.com") then
			if _iapConfig ~= nil and #_iapConfig > 0 then
				for k,v in pairs(_iapConfig) do
					if v:productIdentifier() == productId then
						if isInvalidLocale(v) then
							GspMBProgressHUD:hideHUDForView_animated(UIApplication:sharedApplication():windows()[1], true)
							ShopScene.informPaymentUnavailable()
							_finishCallback(false, valid_locale_error_code)
							return
						else
							_paymentObject:setProPaymentProduct(v)
							_paymentObject:purchaseProPaymentStart()
							return
						end
					end
				end
			end

			local productRequest = SKProductsRequest:initWithProductIdentifiers(productIds)
        	productRequest:setDelegate(self)
        	productRequest:start()
        else
        	_finishCallback(false)
        end
	end
end

function handleValidPayment(self)
	local transactions = SKPaymentQueue:defaultQueue():transactions()
	if #transactions > 0 then
		for k,v in pairs(transactions) do
			local strKey = "apple_iap_"..v:payment():productIdentifier()
			local params = NSUserDefaults:standardUserDefaults():objectForKey(strKey)
			if params == nil then
				SKPaymentQueue:defaultQueue():finishTransaction(v)
				GspMBProgressHUD:hideHUDForView_animated(UIApplication:sharedApplication():windows()[1], true)
			else
				if params["order_id"] == nil or params["product_id"] == nil or params["price"] == nil or params["currency"] == nil then
					_paymentObject:failedTransaction(v)
				else
					_paymentObject:setOrderId(params["order_id"])
					if type(_paymentObject.setPayProductId) == "function" then
						he_log_info("+++++++++++++++++++++++++++ iosPay Log:has defined payProductId++++++++++++++++++++++++++++++++")
						_paymentObject:setPayProductId(params["product_id"])
						_paymentObject:setPayProductPrice(params["price"])
						_paymentObject:setPayCurrency(params["currency"])
					else
						he_log_info("+++++++++++++++++++++++++++ iosPay Log:no define payProductId++++++++++++++++++++++++++++++++")
						_paymentObject:failedTransaction(v)
						return false
					end

					if (v:transactionState() == 1) then
						_paymentObject:confirmTransaction(v)
						return true
					elseif v:transactionState() == 2 then
						_paymentObject:failedTransaction(v)
					end
				end
			end
 		end
 		return false
	else
		return false
	end
end

function productsRequest_didReceiveResponse(self, request, response)
	if response:products() then
		if #response:products() == 1 and _isPaymentAction then
			if isInvalidLocale(response:products()[1]) then
				GspMBProgressHUD:hideHUDForView_animated(UIApplication:sharedApplication():windows()[1], true)
				ShopScene.informPaymentUnavailable()
				_finishCallback(false, valid_locale_error_code)
				return
			else
				_paymentObject:setProPaymentProduct(response:products()[1])
				_paymentObject:purchaseProPaymentStart()
			end
		elseif #response:products() > 1 then
			if not _iapConfig or #_iapConfig == 0 then
				_iapConfig = {}
				for k,v in pairs(response:products()) do
					table.insert(_iapConfig, v)
				end
			end
		else
			if _isPaymentAction then
				GspMBProgressHUD:hideHUDForView_animated(UIApplication:sharedApplication():windows()[1], true)
				_finishCallback(false)
			end
		end
	else
		if _isPaymentAction then
			_finishCallback(false)
		end
	end
end

function paymentGetIapConfig(self, iapInfo)
	_iapConfig = {}
	for k,v in pairs(iapInfo) do
		table.insert(_iapConfig, v)
	end
end

function paymentComplete_errorInfo_userInfo(self, orderId, error, info)
	_finishCallback(true, orderId)
end

function paymentError(self, error)
	_finishCallback(false)
end
