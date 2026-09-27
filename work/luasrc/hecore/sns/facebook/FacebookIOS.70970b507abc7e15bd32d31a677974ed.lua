require "hecore.sns.SnsCallbackEvent"
FacebookIOS = {}
FacebookIOS.session = nil
--FBSession:setDefaultAppID("193774167446229") 
FBSession:setDefaultAppID("369628473180052") -- appid for canon

FBSessionState = table.const
{
	FBSessionStateCreated = 0,              --One of two initial states indicating that no valid cached token was found
	FBSessionStateCreatedTokenLoaded = 1,   --已登录 One of two initial session states indicating that a cached token was loaded; when a session is in this state, a call to open will result in an open session, without UX or app-switching
	FBSessionStateCreatedOpening = 2,       --One of three pre-open session states indicating that an attempt to open the session is underway
	FBSessionStateOpen =  513,              --登录完成 Open session state indicating user has logged in or a cached token is available
	FBSessionStateOpenTokenExtended = 514,  --Open session state indicating token has been extended
	FBSessionStateClosedLoginFailed = 257,  --需要清缓存Closed session state indicating that a login attempt failed
	FBSessionStateClosed = 258,             --需要清缓存Closed session state indicating that the session was closed, but the users token remains cached on the device for later use
}

FBWebDialogResultState = table.const{
	FBWebDialogResultDialogCompleted = 0, 
	FBWebDialogResultDialogNotCompleted = 1,
}

FBSessionLoginBehavior = table.const{
    FBSessionLoginBehaviorWithFallbackToWebView = 0, --Attempt Facebook Login, ask user for credentials if necessary
    FBSessionLoginBehaviorWithNoFallbackToWebView = 1, --Attempt Facebook Login, no direct request for credentials will be made
    FBSessionLoginBehaviorForcingWebView = 2, --Only attempt WebView Login; ask user for credentials
}

FBSessionDefaultAudience = table.const {
    FBSessionDefaultAudienceNone = 0,
    FBSessionDefaultAudienceOnlyMe = 10,
    FBSessionDefaultAudienceFriends = 20,
    FBSessionDefaultAudienceEveryone = 30,
}

function FacebookIOS:init(callback)    
	self.session = FBSession:init()
    callback(SnsCallbackEvent.onSuccess)
end

--登录授权(need read permissions)
function FacebookIOS:login( callback )	
    local permissions = {"email","public_profile", "user_friends"} -- "public_profile", "user_friends", "friend_list"

    --if FBSession:activeSession():state() == FBSessionState.FBSessionStateCreatedTokenLoaded then
    --    local data = {session=self.session, state=FBSessionState.FBSessionStateCreatedTokenLoaded,fb_error=nil}
    --    callback(SnsCallbackEvent.onSuccess,data)
    --else
            FBSession:openActiveSessionWithReadPermissions_allowLoginUI_completionHandler(
            permissions,
            true,
            toobjc(
            	--fb_session : FBSession
            	--fb_status : NSNumber
            	--fb_error : NSError	
                function(fb_session, fb_status , fb_error)
                	print("fb_status="..fb_status)
                	print(table.tostring(fb_session," "))
                    local data = {fb_session=fb_session, fb_status=fb_status,fb_error=fb_error}
                    if fb_error then
                        callback(SnsCallbackEvent.onError,data)
                    elseif fb_status == FBSessionState.FBSessionStateOpen or fb_status == FBSessionState.FBSessionStateOpenTokenExtended then
                        self.session = fb_session
                        callback(SnsCallbackEvent.onSuccess,data)
                    elseif fb_status == FBSessionState.FBSessionStateClosedLoginFailed or fb_status == FBSessionState.FBSessionStateClosed then
                        fb_session:closeAndClearTokenInformation()
                    end
                end):FBCallbackONO()
        )
    --end	
end 

function FacebookIOS:isSessionStateLoaded()
    return FBSession:activeSession():state() == FBSessionState.FBSessionStateCreatedTokenLoaded 
           or FBSession:activeSession():state() == FBSessionState.FBSessionStateOpen 
end

--退出登录
function FacebookIOS:logout()
    self.session:closeAndClearTokenInformation()
    return true
end

--判断是否登录
function FacebookIOS:isLogin()
    if self.session:isOpen() and self.session:accessTokenData() then
        return true
    else
        return false
    end
end

--返回当前用户Access Token
function FacebookIOS:getAccessToken()
	local accessToken = self.session:accessTokenData()
	if accessToken == nil or accessToken == false then
		accessToken = ""
	end
	return accessToken
end

--邀请好友
--好友列表,table类型，如params.friends={to="286400088"}
--多个特定好友: params.friends={suggestions="286400088,100002608739169"}
function FacebookIOS:invite(callback,params)
    FBWebDialogs:presentRequestsDialogModallyWithSession_message_title_parameters_handler_friendCache(
        nil,
        params.message,
        params.title,
        params.friends, --好友列表,table类型，如{to="100002608739169"}
        toobjc(
        	--result : FBWebDialogResultState,0=ok,1=failed
        	--result_url : NSURL
        	--result_error: NSError
        	function(result, result_url, result_error)
                local data = {result=result, result_url=result_url, result_error=result_error}
                if result_error then
                    callback(SnsCallbackEvent.onError,data)
                elseif result == FBWebDialogResultState.FBWebDialogResultDialogNotCompleted then
                    print("send invite not complete")
                    callback(SnsCallbackEvent.onCancel,data)
                else
                    print("send invite complete")
he_log_info("++++++++++++facebook sendRequest result_url = " .. result_url:parameterString())
                    callback(SnsCallbackEvent.onSuccess,data.result)
                end
            end
        ):FBCallbackNOO(),
		nil
    )
end

--用户信息
function FacebookIOS:userInfo( callback )      
    local request = FBRequest:initWithSession_graphPath(self.session,"me")
    request:startWithCompletionHandler(
        toobjc(
        	--fb_connection: FBRequestConnection
        	--fb_result: NSDictionary or id
        	--fb_error: NSError
            function(fb_connection,fb_result,fb_error)       
                local data = {fb_connection=fb_connection,fb_result=fb_result,fb_error=fb_error}
                if fb_error then       
                    callback(SnsCallbackEvent.onError,data)
                else
                    callback(SnsCallbackEvent.onSuccess,data.fb_result)
                end
            end
        ):FBCallback()
    )
end

--好友列表
function FacebookIOS:getAppFriends( callback )
    FBRequest:requestForMyFriends():startWithCompletionHandler(
        toobjc(
        	--fb_connection: FBRequestConnection
        	--fb_result: NSDictionary or id
        	--fb_error: NSError        
            function(fb_connection,fb_result,fb_error)
                print("AppFriends list:")
                print(table.tostring(fb_result," "))
                local data = {fb_connection=fb_connection,fb_result=fb_result,fb_error=fb_error}
                if fb_error then                 
                    callback(SnsCallbackEvent.onError,data)
                else
                    callback(SnsCallbackEvent.onSuccess,data)
                end
            end
        ):FBCallback()
    )
end

--返回用户权限 renturn true/false
function FacebookIOS:hasPermission( permissions )
    local local_permissions = FBSession:activeSession():permissions() --return NSArray*
    for p in pairs(local_permissions) do
        if p == permissions then
            return true
        end
    end
    return false
end

--获取权限
--permissions为table类型
function FacebookIOS:getPermission( callback, permissions )
    FBSession:activeSession():reauthorizeWithPermissions_behavior_completionHandler(
        permissions,
        FBSessionLoginBehavior.FBSessionLoginBehaviorWithFallbackToWebView,
        toobjc(
            function(fb_session , fb_error)
            	--fb_session : FBSession
            	--fb_error : NSError
                local data = {fb_session=fb_session , fb_error=fb_error}
                if fb_error then                 
                    callback(SnsCallbackEvent.onError,data)
                else
                    callback(SnsCallbackEvent.onSuccess,data)
                end
            end
        ):FBCallback()
    )
end

--Get the User's Current Location
--https://developers.facebook.com/docs/tutorials/ios-sdk-tutorial/show-nearby-places/
--[[
    params = {
        distanceFilter = 50,
    }
]]
function FacebookIOS:getUserLocation(callback,params)
    local locationmanager = CLLocationManager:init()
    locationmanager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    locationManager.distanceFilter = params.distanceFilter
    locationManager:startUpdatingLocation()
    --[[
    functon locationManager_didUpdateToLocation_fromLocation( manager,newLocation ,oldLocation ) 
        local data = {manager,newLocation ,oldLocation}
        if oldLocation !=false or (oldLocation.coordinate.latitude != newLocation.coordinate.latitude && oldLocation.coordinate.longitude != newLocation.coordinate.longitude)) then
            print("user location : "..newLocation.coordinate.latitude..","..newLocation.coordinate.longitude)
            callback(SnsCallbackEvent.onSuccess ,data )
        end
    end
    local locationManager_didFailWithError(manager,ns_error)
        local data = {manager,ns_error}
        print("Get user location error!")
        callback(SnsCallbackEvent.onError,data)
    end
    ]]
end

--发送basic requests[自定义message和title]
function FacebookIOS:sendRequest(callback,params)
    FBWebDialogs:presentRequestsDialogModallyWithSession_message_title_parameters_handler(
        nil,
        params.message,
        params.title,
        params.params,
        toobjc(
            function( result, result_url ,result_error)
                local data = {result=result, result_url=result_url, result_error=result_error}
                if result_error then
                    callback(SnsCallbackEvent.onError,data)
                elseif result == FBWebDialogResultState.FBWebDialogResultDialogNotCompleted then
                    callback(SnsCallbackEvent.onCancel,data)
                else
                    print("send request complete")
                    local str = result_url:absoluteString()--query()
                    he_log_info("++++++++++++facebook sendRequest result_url = " .. str)
                    if string.find(str,"request") then
                        print("send request success")
                        --example:result_url = fbconnect://success?request=899752963369894&to%5B0%5D=1476810659231915&to%5B1%5D=779070432135265
                        local resultUrlParse = string.split(str,"&to")
                        local requestResultData = {to = ""}
                        for k,v in pairs(resultUrlParse) do
                            local parse = string.split(v,"=")
                            if parse[2] then
                                if requestResultData.to ~= "" then
                                    requestResultData.to = requestResultData.to .. "," .. parse[2]
                                else
                                    requestResultData.to = parse[2]
                                end
                            end
                        end
                        callback(SnsCallbackEvent.onSuccess,requestResultData)
                    else
                        print("send request canceled")
                        --example:result_url = fbconnect://success?error_code=4201&error_message=User+canceled+the+Dialog+flow
                        callback(SnsCallbackEvent.onCancel,data)
                    end


                end
            end):FBCallbackNOO()
    )
end

--发feed
--[[
params = {
    link --链接地址
    name --feed名称
    caption --标题
    picture --图片地址
    description --摘要
}
]]
function FacebookIOS:presendFeed(callback,params)
    local shareParams = FBShareDialogParams:init()
    shareParams.link = params.link
    shareParams.name = params.name
    shareParams.caption = params.caption
    shareParams.picture= NSURL:URLWithString(params.pictureURL)
    shareParams.description = params.description    
    if FBDialogs:canPresentShareDialogWithParams(shareParams) then
        FBDialogs:presentShareDialogWithParams_clientState_handler(
            shareParams,
            nil, --clientState,default nil
            toobjc(
            function( result, result_url ,result_error)
                local data = { result=result, result_url=result_url ,result_error=result_error }
                if resurl_error then
                    callback(SnsCallbackEvent.onError,data)
                elseif result == FBWebDialogResultState.FBWebDialogResultDialogNotCompleted then 
                    callback(SnsCallbackEvent.onCancel,data)
                else
                    callback(SnsCallbackEvent.onSuccess,data)
                end
            end):FBCallbackNOO()
        )
    else
        --Prepare the web dialog parameters
        local web_dlg_params = {
            name = params.name,
            caption = params.caption,
            description = params.description,
            picture = params.pictureURL,
            link =  params.linkURL,
        }
        --Invoke the dialog
        FBWebDialogs:presentFeedDialogModallyWithSession_parameters_handler(
            nil,
            web_dlg_params,
            toobjc(function( result, result_url ,result_error)
                local data = { result=result, result_url=result_url ,result_error=result_error }
                if resurl_error then
                    callback(SnsCallbackEvent.onError,data)
                elseif result == FBWebDialogResultState.FBWebDialogResultDialogNotCompleted then 
                    callback(SnsCallbackEvent.onCancel,data)
                else
                    callback(SnsCallbackEvent.onSuccess,data)
                end
            end):FBCallbackNOO()
        )
    end
end

--Bragging and News Feed ，炫耀和feed
--https://developers.facebook.com/docs/tutorials/ios-sdk-games/feed/
--Bragging的实现：通过在params的摘要和标题字段自定义游戏分数score来实现炫耀。
function FacebookIOS:presendBrag(callback,params)
    self:presendFeed(callback,params)
end

--Publish Open Graph Story
--https://developers.facebook.com/docs/tutorials/ios-sdk-games/open-graph/
--need to request write permissions from Facebook
--[[
params = {
    type = 'score'       --类型
    data = {"score"=100} --分数   
}
params = {
    type  = "achievement" --类型
                          --成就url列表   
    data = {"achievement" = {"http://www.friendsmash.com/opengraph/achievement_50.html",
                             "http://www.friendsmash.com/opengraph/achievement_100.html",}
           }  
}
]]
function FacebookIOS:publishStory(callback,params)

	if self.session:isOpen() ~= true then
		FBSession:openActiveSessionWithAllowLoginUI(true)
	end
    local permissions = {"publish_actions"}
    local hasPermissions = nil
    if self.hasPermission("publish_actions") == false then
        self.session:requestNewPublishPermissions_defaultAudience_completionHandler(
            permissions,
            FBSessionDefaultAudience.FBSessionDefaultAudienceFriends,
            toobjc(function( fb_connection, fb_result ,fb_error)
                local data = {fb_connection=fb_connection,fb_result=fb_result,fb_error=fb_error}
                if fb_error then
                    hasPermissions = false
                    callback(SnsCallbackEvent.onError,data)
                    return false
                else
                    hasPermissions = true
                end
            end):FBCallback()
        )
    end

    if hasPermissions == true then
        local fbGraphPath = ""
        local myFacebookID = "me"
        if params.type == "score" then
            fbGraphPath = myFacebookID.."/scores"
        elseif params.type == "achievement" then
            fbGraphPath = myFacebookID.."/achievement"
        else
            return false
        end
        FBRequestConnection:startWithGraphPath_parameters_HTTPMethod_completionHandler(
            fbGraphPath,
            params.data,
            "POST",
            toobjc(
                function( fb_connection, fb_result ,fb_error)
                    local data = {fb_connection=fb_connection,fb_result=fb_result,fb_error=fb_error}
                    if fb_error then
                        callback(SnsCallbackEvent.onError,data)
                    else
                        callback(SnsCallbackEvent.onSuccess,data)
                    end
                end):FBCallback()
        )
    end         
end

function FacebookIOS:processIncomingURL(targetURL)
    if string.find(targetURL,"notif") or string.find(targetURL,"challenge_brag") then
        local i, j = string.find(targetURL, "?")
        return string.sub(targetURL,j+1)
    end
    return targetURL
end
--[[
function FacebookIOS:processIncomingRequest(targetURL)
end
function FacebookIOS:processIncomingFeed(targetURL)
end
]]
return FacebookIOS