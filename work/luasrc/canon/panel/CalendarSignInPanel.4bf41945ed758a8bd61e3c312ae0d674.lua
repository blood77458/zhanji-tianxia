--------------------------------------------------------------------------------
-- CalendarSignInPanel.lua --月历签到
-- author: dang chao
-- updated: 2013-09-25
--------------------------------------------------------------------------------
require "canon.customUI.SuspensionLabel"
require "canon.manager.MaintenanceManager"

local visibleSize = CCDirector:sharedDirector():getVisibleSize();

CalendarSignInPanel = class(Layer)
CalendarSignInType = {popPanel = 1,activityLayer = 2}
function CalendarSignInPanel:ctor()
    self.container = nil
	self.signInActionFinish = false
	self.clickClosePanel = false
	self.type = CalendarSignInType.activityLayer
	self.calendarInfo = {}
end

function CalendarSignInPanel:create( container ,calendarInfo,type,closeCallBackFunc) 
    local s = CalendarSignInPanel.new()
    self.container = container
    s.calendarInfo = calendarInfo
	self.daysInThisMonth = 31
	self.hasSigninDays = 0
	self.scrollPicInThisMonth = 3
	self.colseCallBackFunc = closeCallBackFunc
    s:initLayer(type)
	
    return s
end

function CalendarSignInPanel:enable(curTimeStamp)
    local isEnable = MaintenanceManager.isActivityOpen("calendarLogin")
    return isEnable
end 


local TAG_DAYNUM_ON_DAYLAYER = 1001
local TAG_REWARDPIC_ON_DAYLAYER = 1002
local TAG_REWARDNUM_ON_DAYLAYER = 1003
local TAG_VIPNUM_ON_DAYLAYER = 1004

function CalendarSignInPanel:initLayer(ctype)
    CalendarSignInPanel.super.initLayer(self)
    if ctype then
        self.type = ctype
    end
	if self.type == CalendarSignInType.popPanel then
		--self.container:setTableViewsEnabled(false)
	end 
	 
	local builder = LayoutBuilder:createWithContentsOfFile("scene/calendar_new.json")
    self.panelUI = builder:build("calendar")
    
    local GameData = DataManager.getGameInitData()
    local function onClosePanel(evt)
        if self.type == CalendarSignInType.popPanel and self.signInActionFinish then
			self.clickClosePanel = true
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			--self.container:setTableViewsEnabled(true)
			self.container.targetInfoPanel = nil
			if self.colseCallBackFunc and type(self.colseCallBackFunc) == "function" then
		        self.colseCallBackFunc()
		    end
		end
    end 
    --init UI	
    self.panelUI:getChildByName("calendar_icon_upper"):setVisible(false)
	self.panelUI:getChildByName("calendar_normal_card_small_sb"):setVisible(false)
    --self.panelUI:getChildByName("calendar_bg_calendar_blue"):setVisible(false)
    self.panelUI:getChildByName("calendar_calendar"):setVisible(false)
    self.panelUI:getChildByName("calendar_txt_event_single"):setVisible(false)
    self.panelUI:getChildByName("calendar_txt_event_double"):setVisible(false)
	if self.type ~= CalendarSignInType.popPanel then
		self.panelUI:getChildByName("calendar_title_bar"):setVisible(false)
		self.panelUI:getChildByName("pattern_friend_mid_L"):setVisible(false)
		self.panelUI:getChildByName("pattern_friend_mid_R"):setVisible(false)
	end 
    
    if self.type == CalendarSignInType.popPanel then
	    self:addChild(self.panelUI)
	else
	    self:addChildAt(self.panelUI,-1)
	end
	
--close
    if self.type == CalendarSignInType.popPanel then
        local closeTouchLayer = Layer:create()
        local winSize = CCDirector:sharedDirector():getWinSize()
        closeTouchLayer:setContentSize(CCSizeMake(winSize.width, winSize.height))
        self:addChild(closeTouchLayer)
        local btn_close_Btn = Button:create(closeTouchLayer)
        btn_close_Btn:addEventListener(Events.kStart ,onClosePanel) 
    end 
    local day_table = {}
    
	local ITEMS_PER_ROW = 6
    local function getCurMonthRewardListFinish(data)
        if data.data.monthlyLoginRewardItems == nil then
            self.signInActionFinish = true
            return
        end 
        -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~data.data = "..tostringRich(data.data))
        self.daysInThisMonth = #data.data.monthlyLoginRewardItems 
        self.hasSigninDays = DataManager.getCurMonthUserSigninDays()
        self.calendarInfo  = data.data.monthlyLoginRewardItems
        self.scrollPicInThisMonth = data.data.adNum
        --init scroll pic
	    local scrollLayer = CCLayer:create()--LayerColor:create()
	    local scrollLayer_InArea = CCClippingRegionNode:create( scrollLayer, 0, 120, visibleSize.width, 300 )
	    scrollLayer:setPosition(ccp(0,self.panelUI:getChildByName("calendar_normal_card_small_sb"):getPosition().y/2))
        self.panelUI:addChild(CocosObject.new(scrollLayer_InArea))

        --scrollLayer:setColor(ccc3(0,255,0))
        local scrollPicGroup = {}
        local scrollPicInfoOriginal = MetaManager.getAdPicturesByType(1)
        local scrollPicInfo = {}
        for i = 1,self.scrollPicInThisMonth do 
            table.insert(scrollPicInfo,scrollPicInfoOriginal[i])
        end 
        for i = 1,#scrollPicInfo  do
            local function loadThirdPartyResCallback(eventName, data)
                if eventName == ResCallbackEvent.onError then
                    he_log_info("load third party res error, errorCode: " .. data.errorCode .. ", item: " .. data.item)
                elseif eventName == ResCallbackEvent.onSuccess then
                    he_log_info("load third party res success")
                    --data.readPath is the file's path after download

                    --校验当前UI是否存在 若不存在说明已经被析构 不处理就好 add by zheng.che @ 2014-9-16 10:37:09
					if self.parent == nil then
						return
					end
					
					if self.clickClosePanel then
						return
					end
					
                    local scrollPic = CCSprite:create(data.realPath)
                    if scrollPic ~= nil then
                        scrollLayer:addChild(scrollPic)
                        scrollPic:setPosition(ccp((i-1)*scrollPic:getContentSize().width,scrollPic:getContentSize().height/2))
                        scrollPic:setAnchorPoint(ccp(0,0.5))
                        table.insert(scrollPicGroup,{pic = scrollPic,movePos = i})
                        scrollLayer:setContentSize(CCSizeMake(scrollPic:getContentSize().width, scrollPic:getContentSize().height))
                    end
                    if i == #scrollPicInfo then
                        local picWaitTime = 6
                        local picMoveTime = 0.5
                        if #scrollPicGroup >= 2 then
                            for j = 1 ,#scrollPicInfo  do 
                                local function moveToBeginPos()
                                    if scrollPicGroup[j].movePos == 1 then
                                        local reInitProPos = j-1
                                        if reInitProPos == 0 then
                                            reInitProPos = self.scrollPicInThisMonth
                                        end 
                                        scrollPicGroup[j].pic:setPosition(ccp(scrollPicGroup[reInitProPos].pic:getPositionX()+scrollPicGroup[reInitProPos].pic:getContentSize().width,scrollPicGroup[j].pic:getContentSize().height/2))
                                    end 
                                    scrollPicGroup[j].movePos = scrollPicGroup[j].movePos - 1
                                    if scrollPicGroup[j].movePos == 0 then
                                        scrollPicGroup[j].movePos = self.scrollPicInThisMonth
                                    end
                                end
                                local array = CCArray:create()
                                array:addObject(CCDelayTime:create(picWaitTime))
                                array:addObject(CCMoveBy:create(picMoveTime, ccp(-scrollPicGroup[j].pic:getContentSize().width, 0)))
                                array:addObject(CCDelayTime:create(picMoveTime))
                                array:addObject(CCCallFunc:create(moveToBeginPos))
                                scrollPicGroup[j].pic:runAction(CCRepeatForever:create(CCSequence:create(array)))
                            end	
                        end
                    end 
                    --
                end
            end
            local picUrl = {}
            table.insert(picUrl,scrollPicInfo[i].url)
            ResourceLoader.loadThirdPartyRes(picUrl, loadThirdPartyResCallback)
        end 
        
        --init calendar
	    local firstDayPosition = self.panelUI:getChildByName("calendar_calendar"):getPosition()
		firstDayPosition.x = firstDayPosition.x + 4
		firstDayPosition.y = firstDayPosition.y - 8
	    for i = 1,self.daysInThisMonth do 
			if i > 30 then
				break;
			end
		    local dayLayer = Sprite:create(UI_RES_PATH.."/calendar_new/calendar_bg_calendar_sb.png")
			dayLayer:setScaleX(7/6)
		    local daySize = dayLayer:getBounds().size
		    dayLayer:setAnchorPoint(ccp(0,1))
		    local row = math.modf((i-1) / ITEMS_PER_ROW)
		    local line = (i-1) % ITEMS_PER_ROW
		    table.insert(day_table,dayLayer)
		    self.panelUI:addChild(dayLayer)
		    dayLayer:setPosition(ccp(firstDayPosition.x + line * daySize.width,firstDayPosition.y - row * daySize.height))
		    --add reward pic
		    local rewardPic = nil
		    
		    -- print("______________________self.calendarInfo[i]"..tostringRich(self.calendarInfo[i]))
		    if self.calendarInfo[i].rewardType == 1 then
		        rewardPic = CocosObject.new(CCSprite:create("common/CoinIcon.png"))
				rewardPic:setScale(0.7)
		    elseif self.calendarInfo[i].rewardType == 2 then
		        rewardPic = CocosObject.new(CCSprite:create("common/GemIcon.png"))
				rewardPic:setScale(0.7)
		    elseif self.calendarInfo[i].rewardType == 5 then
				--if not g_loadPlistBefore then
				--	PlistResMgr:getInstance():loadPlist("card/icon_plist.plist")
				--	g_loadPlistBefore = true;
				--end
		        rewardPic = CocosObject.new(CCSprite:create("card/head/" .. MetaManager.card_meta[self.calendarInfo[i].rewardId].figureId .. "_head.png"))
		        rewardPic:setScale(0.7)
		    elseif self.calendarInfo[i].rewardType == 6 then
		        rewardPic = CanonItem:create()
                rewardPic:loadByMetaId(self.calendarInfo[i].rewardId, true)
                rewardPic:setScale(0.7)
		    elseif self.calendarInfo[i].rewardType == 7 then
                rewardPic= CanonItem:create()
                rewardPic:loadByMetaId(self.calendarInfo[i].rewardId, true)
                rewardPic:setScale(0.7)
		    elseif self.calendarInfo[i].rewardType == 8 then
		        rewardPic = CocosObject.new(CCSprite:create("common/FriendpointIcon.png"))
				rewardPic:setScale(0.7)
			elseif self.calendarInfo[i].rewardType == 17 then
			    local CardId = MetaManager.card_fragment_meta[self.calendarInfo[i].rewardId].cardId
		        rewardPic = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD,CardId)
		        local  PropSp = CocosObject.new(CCSprite:create("Item/Picture/Prop_soul.png"))
		        PropSp:setScale(1.4)
		        PropSp:setPosition(ccp(60,60))
		        rewardPic:addChild(PropSp)
				rewardPic:setScale(0.4)
		    end 
		    if rewardPic ~= nil then
		        rewardPic:setTag(TAG_REWARDPIC_ON_DAYLAYER)
		        rewardPic:setZOrder(2)
		        rewardPic:setPosition(ccp( daySize.width*(0.5 - 1/12), daySize.height*0.5))
				rewardPic:setScaleX(rewardPic:getScaleX() * 6 / 7)
                dayLayer:addChild(rewardPic)
		    end 

		    -- print("~~~~~~~~~~~~~~~~~~~~~~~~self.calendarInfo[i].levelMin = "..tostringRich(self.calendarInfo[i].levelMin))
		    
		    if self.calendarInfo[i].levelMin  ~= 0 then
	            local MultipleNum = ""
	            --判断几倍显示中文字幕
	            if self.calendarInfo[i].rewardMultiple  == 1 then
		            MultipleNum = "一倍"
	            elseif self.calendarInfo[i].rewardMultiple  == 2 then
		            MultipleNum = "二倍"
	            elseif self.calendarInfo[i].rewardMultiple  == 3 then
		            MultipleNum = "三倍"
	            elseif self.calendarInfo[i].rewardMultiple  == 4 then
			        MultipleNum = "四倍"
	            elseif self.calendarInfo[i].rewardMultiple  == 5 then
		            MultipleNum = "五倍"
	            elseif self.calendarInfo[i].rewardMultiple  == 6 then
		            MultipleNum = "六倍"
		        
		        end
	            --add Vip
	            -- local VipNum = CCLabelTTF:create("V"..self.calendarInfo[i].levelMin.." "..MultipleNum,"Verdana-Bold",20)--BitmapText:create(i,"fonts/heiti.fnt")
			    local VipNum = TextField:create("V"..self.calendarInfo[i].levelMin.." "..MultipleNum)
			    VipNum:setColor(ccc3(255,255,255))
			    VipNum:setFontSize(20)
			    VipNum:setAnchorPoint(ccp(0,0.5))
	            VipNum:setPosition(ccp( daySize.width*0.12, daySize.height*0.38))
	            VipNum:setTag(TAG_VIPNUM_ON_DAYLAYER)
	            -- VipNum:setZOrder(5)
	            
				VipNum:setScaleX(VipNum:getScaleX() * 6 / 9)
				VipNum:setRotation(-45)
				-- dayLayer:addChild(VipNum)  enableStroke 
	            -- VipNum:enableStroke(ccc3(255,0,0),2) --coocs2dx 描边
	            
				local sp = Sprite:create("ui_res/calendar_new/bg_calendar_v.png")
				sp:setPosition(ccp( daySize.width*0.35, daySize.height*0.585)) 
				sp:setZOrder(-10) 
				sp:addChild(VipNum)
			    dayLayer:addChild(sp)
            end
		    --add signIn icon
		    if i <= self.hasSigninDays then
		        local signInIcon = CCSprite:create("pic/activityIcons/signInIcon.png")
                signInIcon:setPosition(ccp( daySize.width*(0.5 - 1/12), daySize.height*0.55))
                signInIcon:setZOrder(10)
				signInIcon:setScaleX(signInIcon:getScaleX()  / dayLayer:getScaleX())
                dayLayer:addChild(CocosObject.new(signInIcon))
            end
            --add day num
		    
		    local dayNum = TextField:create(i.."天")--BitmapText:create(i,"fonts/heiti.fnt")
		    dayNum:setColor(ccc3(80,80,80))
		    dayNum:setFontSize(20)
		    dayNum:setAnchorPoint(ccp(0,0.5))
            dayNum:setPosition(ccp( daySize.width*0.05, daySize.height*0.1))
            dayNum:setTag(TAG_DAYNUM_ON_DAYLAYER)
            dayNum:setZOrder(3)
			dayNum:setScaleX(dayNum:getScaleX() * 6 / 8)
            dayLayer:addChild(dayNum)
            
           
            --TAG_REWARDNUM_ON_DAYLAYER
            --add reward num
            local RewardPostionX = nil
            local num = 0
            rewardAmount = self.calendarInfo[i].rewardAmount
            -- rewardAmount = 100000
            while( rewardAmount >= 1)
			do
			   rewardAmount = rewardAmount /10
               num = num + 1
			   
			end

              -- print("~~~~~~~~~~~~~~~~~~~~~~~RewardPostionX = "..num)
              --num = 0 一位数 2 两位数 3 三位数 4 四位数  奖励数量不一致 要向右对齐
            if num == 1 then
				RewardPostionX = daySize.width*0.66
	        elseif num == 2 then
	        	RewardPostionX = daySize.width*0.58
	        elseif num == 3 then
	        	RewardPostionX = daySize.width*0.52
	        elseif num == 4 then
	        	RewardPostionX = daySize.width*0.45
	        elseif num == 5 then
	        	RewardPostionX = daySize.width*0.38
	        elseif num == 6 then
	        	RewardPostionX = daySize.width*0.32
            elseif num == 7 then
	        	RewardPostionX = daySize.width*0.26
	        end
            local RewardNum = TextField:create("x"..self.calendarInfo[i].rewardAmount)--BitmapText:create(i,"fonts/heiti.fnt")
		    RewardNum:setColor(ccc3(80,80,80))
		    RewardNum:setFontSize(22)
		    RewardNum:setAnchorPoint(ccp(0,0.5))
            RewardNum:setPosition(ccp( RewardPostionX, daySize.height*0.1))
            RewardNum:setTag(TAG_REWARDNUM_ON_DAYLAYER)
            RewardNum:setZOrder(3)
			RewardNum:setScaleX(RewardNum:getScaleX() * 6 / 8)
			RewardNum:setScaleY(RewardNum:getScaleX() * 6 / 7)
            dayLayer:addChild(RewardNum) 
	    end 
		
		local function signinActionFinish(SignInBefore) 
			local function showText()
				if self.type == CalendarSignInType.popPanel then
					local text =  TextField:create(getTextByKey("consecutiveLogin_continue"), nil, 30)
					text:setPositionX(360)
					text:setPositionY(scrollLayer:getPositionY() - 20)
					self.panelUI:addChild(text)
				end
			end
	           self.signInActionFinish = true
			   if SignInBefore then
				showText()
			   else
				SuspensionLabel:showContent(self, getTextByKey("login_claimReward"), showText)
			   end			
	    end 
--run sign in action 	    
	    local function runSigninAction()
			
	        if next(day_table) == nil or day_table[self.hasSigninDays+1] == nil or self.hasSigninDays+1 > 30 then
                signinActionFinish(false)
                return 
            end 
	        local signInIcon = CCSprite:create("pic/activityIcons/signInIcon.png")
	        signInIcon:setScale(100)
	        signInIcon:setVisible(false)
	        local dayLayer = day_table[self.hasSigninDays+1]
		    dayLayer:setZOrder(1000)
	        local daySize = dayLayer:getBounds().size
            signInIcon:setPosition(ccp( daySize.width*(0.5 - 1/12), daySize.height*0.55))
            signInIcon:setZOrder(40)
			
            dayLayer:addChild(CocosObject.new(signInIcon))
            local function signinIconShow()
                signInIcon:setVisible(true)
            end 
         
		    local function calendarLayerShakeAction()
		        CanonPlayEffect("music/sfx_day_login.wav")
		        signInIcon:setScaleX(1 / dayLayer:getScaleX() )
			    local array = CCArray:create()
			    local repeatTimes = 4
			    local screenShakeTime = 0.4
			    for i = 1,repeatTimes do 
				    array:addObject(CCMoveBy:create(screenShakeTime/repeatTimes/2, ccp(0,3)))
				    array:addObject(CCMoveBy:create(screenShakeTime/repeatTimes/2, ccp(0,-3)))
			    end
			    array:addObject(CCCallFunc:create(signinActionFinish))
			    self:runAction(CCSequence:create(array))
		    end 
            local array = CCArray:create()
            array:addObject(CCDelayTime:create(1))
            array:addObject(CCCallFunc:create(signinIconShow))
	        array:addObject(CCScaleTo:create(0.5,1))
	        array:addObject(CCDelayTime:create(0.5))
		    array:addObject(CCCallFunc:create(calendarLayerShakeAction))
            signInIcon:runAction(CCSequence:create(array))
	    end 
--request get today login reward
        local function getTodayLoginReward()
        	
            local function getLoginRewardSucceed(response)
                runSigninAction()
				--Synchronous front-end data
				if GameData.sharkUserExtend and GameData.sharkUserExtend.signInInfo then
					GameData.sharkUserExtend.signInInfo.getRewardTimeStamp = g_curServerTimeStamp
					if GameData.sharkUserExtend.signInInfo.loginDaysMonth < self.daysInThisMonth then
						GameData.sharkUserExtend.signInInfo.loginDaysMonth = DataManager.getCurMonthUserSigninDays() + 1
					else
						GameData.sharkUserExtend.signInInfo.loginDaysMonth = 1
					end 
				else
					--first sign in
					if GameData.sharkUserExtend then
					    GameData.sharkUserExtend["signInInfo"] = { getRewardTimeStamp = g_curServerTimeStamp,
                                                                                   loginDaysMonth = 1}
					else
					    GameData["sharkUserExtend"] = {}
                        GameData.sharkUserExtend["signInInfo"] = { getRewardTimeStamp = g_curServerTimeStamp,
                                                                                   loginDaysMonth = 1}
					end 
				end
				DataManager.setGameInitData(GameData)
        if type(self.container.resetTipInfoForActivity) == "function" then
          self.container:resetTipInfoForActivity("Activity_SignIn")
        end
            end
			
			local function getLoginRewardFailed(err)
				signinActionFinish(true)
			end 
			
            local request = GetLoginRewardRequest.new( params, rpc.SendingPriority.kHigh )
            request:addEventListener( RequestNotifyEnum.GetLoginRewardSucceed, getLoginRewardSucceed )
            request:addEventListener( RequestNotifyEnum.GetLoginRewardFailed, getLoginRewardFailed )
            request:start()
        end
--request get today signin reward
        local function getTodaySigninReward()
            local function getSigninRewardSucceed(response)
                --runSigninAction()
                getTodayLoginReward()
            end
			
			local function getSigninRewardFailed(err)
				--self.signInActionFinish = true
				getTodayLoginReward()
			end 
			
            local request = GetSigninRewardRequest.new( params, rpc.SendingPriority.kHigh )
            request:addEventListener( RequestNotifyEnum.GetSigninRewardSucceed, getSigninRewardSucceed )
            request:addEventListener( RequestNotifyEnum.GetSigninRewardFailed, getSigninRewardFailed )
            request:start()
        end 
        
        if self.type == CalendarSignInType.popPanel then
	        getTodaySigninReward()
	    else
            if not isUserSigninToday(TimeUtil.getServerTimeSeconds()) then
              getTodaySigninReward()
            end 
	    end 
    end 
    
    local request = GetCurMonthRewardListRequest.new( params, rpc.SendingPriority.kHigh )
    request:addEventListener( RequestNotifyEnum.GetCurMonthRewardMetaSucceed, getCurMonthRewardListFinish )
    request:start()
    
end

function CalendarSignInPanel.getTipNum()
  if not CalendarSignInPanel.enable() then
    return 0
  end
  
  local gameInitData = DataManager.getGameInitData()
  if not gameInitData.sharkUserExtend.signInInfo then
    return 1
  end
  
  local oldDate = os.date("%Y%m%d", gameInitData.sharkUserExtend.signInInfo.getRewardTimeStamp)
  local currentDate = os.date("%Y%m%d", TimeUtil.getServerTimeSeconds())
  --if oldDate ~= currentDate then
  if TimeUtil.getPasseddDaysToNow(gameInitData.sharkUserExtend.signInInfo.getRewardTimeStamp) ~= 0 then --判断不为同一天
    return 1
  else
    return 0
  end
end