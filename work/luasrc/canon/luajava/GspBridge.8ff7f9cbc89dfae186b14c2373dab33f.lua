--------------------------------------------------------------------------------
-- GspBridge.lua -调用GSP支付接口
-- author: xiaojie.bai
-- date: 2013-12-11 18:00
--------------------------------------------------------------------------------
require "canon.request.ValidatePaymentOrderRequest"

local GspBridgeAndroid = {}

local instance = nil
function GspBridgeAndroid.init()
  instance = luajava.bindClass("com.happyelements.canon.GspBridge"):getInstance()
end

local getGoodsListSucc = false

function isGetGoodsListSucc()
    return getGoodsListSucc
end

function GspBridgeAndroid.getGooglePlayGoodsList(productIds)
  if(not instance) then
    GspBridge.init()
  end
  
  if getGoodsListSucc then
    return
  end

  local getGoodsList_callback = luajava.createProxy("com.happyelements.canon.GetGoodsListCallBack",
    {
        onSuccess = function(data)
            he_log_info("+++++++++getGooglePlayGoodsList success: ")
            local goodsTable = luaJavaConvert.list2Table(data)
            for k,v in ipairs(goodsTable) do
                local goodsId = v:getSkuId()
                local goodsPrice = v:getPrice()
                local orgData = v:getOrgData()
                he_log_info("+++++++++goodsId = " .. goodsId .. ",goodsPrice = " .. goodsPrice .. ",orgData = [" .. orgData .. "]")
                orgData = table.deserialize(orgData)
                
                --修改商品信息
                for ck,cv in pairs(MetaManager.getPaymentExchangeConfig()) do
                    if cv.onSale and cv.id == goodsId then
                        cv.itemDescKey = orgData.price
                        cv.platformCoin = goodsPrice
                        he_log_info("+++++++++cv.itemDescKey = " .. cv.itemDescKey .. ",cv.platformCoin = " .. cv.platformCoin)
                    end
                end
                --
            end
            getGoodsListSucc = true
        end,
        onFailed = function(msg)
            he_log_info("+++++++++getGooglePlayGoodsList error: " .. msg)
            --MetaManager.game_meta.paymentExchangeConfig.paymentExchanges = nil
        end
    }
    )
  productIds = luaJavaConvert.table2List( productIds )
  instance:callGoodsList(productIds,getGoodsList_callback)
end

function GspBridgeAndroid.pay(productInfo,payCallBackFunc,funcName,payMethord)
  if(not instance) then
    GspBridge.init()
  end
  
  local oldPrice = productInfo.platformCoin
  local oldAmount = productInfo.amount
  local oldProductInfo = productInfo
  local productId = productInfo.id
  local ownOrderId 
  
  local pay_callback = luajava.createProxy("com.happyelements.canon.PayCallBack",
    {
      onSuccess = function(recieveOrderId)
        he_log_info("+++++++++onSuccess orderId: " .. productId)
	if  payMethord == "shortMessageMMPay" then
		recieveOrderId = ownOrderId
	end
	
        if isYYBAndroid() and payMethord ~= "shortMessageMMPay" then
            local evt = {data = {productId = productId}}
            payCallBackFunc(true,evt)
            return
        end
        local hasRetryCheck = false
        local retryWaitDuring = 15 -- retry send check order request during 15 seconds if check fail
        local sendCheckOrderRequest = nil
        local retrySchedule = nil
        
        local function ValidatePaymentOrderSucceedResponse(evt)
            
            if retrySchedule then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(retrySchedule)
                retrySchedule = nil
				RequestLoadingBox:removeLoadingBox()
            end
            
            if payCallBackFunc and type(payCallBackFunc) == "function" then
                payCallBackFunc(evt.data.succ,evt)
            end
        end
        
        local function ValidatePaymentOrderFailedResponse(evt)
            
            if evt.data == 716152 then
                if not hasRetryCheck then
                    RequestLoadingBox:createLoadingBox(false)
                    RequestLoadingBox:showLoadingBox()
                    hasRetryCheck = true
                    retrySchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(sendCheckOrderRequest,retryWaitDuring,false)
                    he_log_info("+++++++++check order err ")
                    return
                end
            end
            
            if retrySchedule then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(retrySchedule)
                retrySchedule = nil
				RequestLoadingBox:removeLoadingBox()
            end
                    
            if payCallBackFunc and type(payCallBackFunc) == "function" then
                payCallBackFunc(false,evt)
            end
        end
        
        
        sendCheckOrderRequest = function ()
            local request = ValidatePaymentOrderRequest.new( {orderId = recieveOrderId}, rpc.SendingPriority.kHigh )
            request:addEventListener( RequestNotifyEnum.ValidatePaymentOrderSucceed, ValidatePaymentOrderSucceedResponse )
            request:addEventListener( RequestNotifyEnum.ValidatePaymentOrderFailed, ValidatePaymentOrderFailedResponse )
            request:start()
        end
        
        sendCheckOrderRequest()

      end,
      onFailed = function(msg, detail)
        --he_log_info("+++++++++++msg: " .. msg .. ",detail: " .. detail)--有时候detail会是空，注释掉，防止crash
        if detail and detail == "getSkuDetails() failed: 6:Error" then
            --用户不能通过googleplay支付，获取支付列表失败
            CanonMessageBox:Show( getTextByKey("payGooglePlayAddRemind"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
        end
        if payCallBackFunc and type(payCallBackFunc) == "function" then
            payCallBackFunc(false)
        end
      end
    }
  )
  
  local m_platform = getPlatFormIgnoreDevice()
  local userInfo = DataManager.getCurrUser()
  productInfo.itemDescKey = getTextByKey(productInfo.itemDescKey,{num = tostring(productInfo.platformCoin)})
  productInfo.itemNameKey = getTextByKey(productInfo.itemNameKey)
  
  if funcName == nil then
    funcName = "exchange"
  end
  
  if payMethord == nil then
    payMethord = "normal"
  end
  
  productInfo.payMethord = payMethord
  
  local tencentAmount = productInfo.amount
  if  funcName == "shop" and isYYBAndroid() then
    tencentAmount = 1
  end
  
  if is91Android() then
    productInfo.amount = 1
  end 
  
  if is91Android() then
    --91 need parameter_priceStr is single product's price
    productInfo.platformCoin = productInfo.platformCoin / productInfo.amount
  end
    
  productInfo.uid = userInfo.uid
  productInfo.zone_id = DataManager.getZoneId()
  productInfo.server_id = DataManager.getServerid()
  productInfo.roleId = string.sub(userInfo.uid,1,string.len(userInfo.uid)-4)
	
  if isYYBAndroid() then
    --tencent 价格人民币转换为Q点
    productInfo.platformCoin = productInfo.platformCoin * 10
    productInfo.platformCoin = productInfo.platformCoin / tencentAmount
    productInfo.uid = userInfo.uid
    productInfo.snszoneid = 1
    productInfo.zone_id = DataManager.getZoneId()
    productInfo.server_id = DataManager.getServerid()
    --he_log_info("+++++++++++uid: " .. userInfo.uid)
  end
  
  local itemPrice = productInfo.platformCoin
  
  local function getWaresid()
    local waresid = "-999"
    --if isYyhAndroid() then
        if  funcName == "shop" then
            waresid = "8"
        else
			waresid = productInfo.id:split("_")[2]
			if string.sub(waresid,1,1) == "0" then
				waresid = string.sub(waresid,string.len(waresid))
			end
            --waresid = string.sub(productInfo.id,string.len(productInfo.id))
        end
    --end
    return waresid
  end 
  
  local waresid = getWaresid()
  
  
  
  local extendString = {
                            platform = m_platform,
                            zone_id = DataManager.getZoneId(),
                            server_id = DataManager.getServerid(),
                            func_name = funcName,
                            waresid = waresid,
                            role_id = userInfo.uid,
                            _user_id = string.sub(userInfo.uid,1,string.len(userInfo.uid)-4),
                            itemId = tostring(productId), 
                            itemAmount = tostring(tencentAmount), 
                            itemPrice = tostring(itemPrice), 
                            realAmount = tostring(tencentAmount),
                        }
  extendString = table.serialize( extendString )
  --he_log_info("+++++++++++extendString: " .. extendString)
  
  local getOrderIdUrl 
  local somePara =   "product_id="..productInfo.id
                     .."&price="..productInfo.platformCoin
                     .."&language="..MetaInfo:getInstance():getLanguage()
                     .."&platform="..m_platform
                     .."&appName=".."战姬天下"
                     .."&extend="..extendString
                     .."&server_id="..DataManager.getServerid()
                     .."&zone_id="..DataManager.getZoneId()
                     .."&locale="..MetaInfo:getInstance():getTimeZone()
                     .."&level="..DataManager.getCurrUser().level
                     .."&clientType="..MetaInfo:getInstance():getDeviceModel()
                     .."&client="..""
                     .."&client_version="..MetaInfo:getInstance():getOsVersion()
                     .."&client_detail="..""
  
  productInfo =  table.serialize( productInfo )
  --he_log_info("+++++++++++productInfo: " .. productInfo)
  
  --短代支付单独先请求游戏后端，获取orderid begin                          
  local function onGetOrderIdFinish(response)
		RequestLoadingBox:removeLoadingBox()
        he_log_info("+++++++++++++++++++++++++++shortPay Log:get orderId finish ++++++++++++++++++++++++++++++++")	
        local tstr = table.serialize(response)
        he_log_info("+++++++++++++++++++++++++++shortPay Log:tstr = ".. tstr .." ++++++++++++++++++++++++++++++++")
		if response.body == "" then
			he_log_error("+++++++++++++++++++++++++++shortPay Log:get orderId error body is empty+++++++++++++++++++++++++++")
			CanonMessageBox.showText(
                                        ShowButtonType.ID_OK,
                                        getTextByKey("skyTower_error_dataDesync"),
                                        nil,
                                        {
                                            text = getTextByKey("yes"),
                                            callbackFunc = function()
                                            end
                                        }
                                    )
            payCallBackFunc(false)                        
            return
		end
        local rTable = table.deserialize(response.body)		
        if response.httpCode ~= 200 or rTable.result ~= "success" then
            he_log_error("+++++++++++++++++++++++++++shortPay Log:get orderId error:"..response.httpCode.."++++++++++++++++++++++++++++++++")
            payCallBackFunc(false)                        
            return
        end
		ownOrderId = rTable.order_id
		he_log_error("+++++++++++++++++++++++++++shortPay Log:get orderId = "..ownOrderId.."++++++++++++++++++++++++++++++++")
		local extendData = {
							orderId = ownOrderId
                        }
		extendData = table.serialize( extendData )
        instance:pay(m_platform,pay_callback,productInfo,extendData)
  end             
  --短代支付请求获取orderid end
        
  if payMethord == "shortMessageMMPay" then
    --移动mm
    local appid -- gspid
	if isYYBAndroid() then
		appid = "7600106707"; 
	end 
    getOrderIdUrl = StartupConfig:getInstance():getGameDomain().."/paymentcenter/1/1/init/" .. appid .. "/" .. userInfo.uid
    local dataLen = somePara:len()
    local request = HttpRequest:createPost(getOrderIdUrl)
	local timeout = 10
    request:setConnectionTimeoutMs(timeout * 1000)
    request:setTimeoutMs(timeout * 1000)
    request:addHeader("Content-Type:application/x-www-form-urlencoded")
	request:setPostData(somePara, dataLen)
	he_log_error("+++++++++++++++++++++++++++shortPay Log:get orderId setPostData+++++++++++++++++++++++++++++")
    HttpClient:getInstance():sendRequest(onGetOrderIdFinish, request)
	RequestLoadingBox:createLoadingBox(false)
    RequestLoadingBox:showLoadingBox()
  else
    instance:pay(m_platform,pay_callback,productInfo,extendString)
  end
  
  oldProductInfo.platformCoin = oldPrice
  oldProductInfo.amount = oldAmount
end

GspBridge = nil

if __ANDROID then
  GspBridge = GspBridgeAndroid  
elseif __IOS then
  GspBridge = {}
else
  GspBridge = {}
end