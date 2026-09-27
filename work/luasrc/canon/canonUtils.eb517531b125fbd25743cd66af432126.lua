
require "canon.data.MetaManager"

require "canon.customUI.CanonCard"
require "canon.customUI.CanonItem"
require "canon.request.RecordTutorialStepRequest"
require "canon.script_and_guide.NewUserGuide"
require "canon.manager.MaintenanceManager"
require "canon.customUI.RequestLoadingBox"

NumberColorEnum = table.const {
	blue = 0,
	green = 1,
	red = 2,
	write = 3,
	yellow = 4,
	critical = 5,
}

ServerStatusEnum = table.const{
	new = 0,
	normal = 1,
	crowd = 2,
	full = 3,
}

----------------------------------------
-- 记录当前服务器时间
----------------------------------------
g_curServerTimeStamp = 0
----------------------------------------
-- 判断用户当天是否领取月历签到奖励
-- user_CurPlayTime用户当前游戏的服务器时间，请求GetServerTimeStampRequest返回
----------------------------------------
function isUserSigninToday(user_CurPlayTime)
	local userLastSigninTime = DataManager.getUserLastSigninTime()
	local userCurPlayTime = user_CurPlayTime
	if userLastSigninTime == 0 then
		return false
	else
		userLastSigninTime = os.date("*t",userLastSigninTime)
		userCurPlayTime = os.date("*t",userCurPlayTime)
		if userCurPlayTime.year > userLastSigninTime.year then
		    return false
		end 
		if userCurPlayTime.month > userLastSigninTime.month then
		    return false
		end 
		if userCurPlayTime.day > userLastSigninTime.day then
		    return false
		end 
		return true
	end 
end  
----------------------------------------
-- 判断用户当天是否可以观星
-- user_CurPlayTime用户当前游戏的服务器时间，请求GetServerTimeStampRequest返回
----------------------------------------
function shouldSeeStarToday(user_CurPlayTime)
	local isShouldSeeStarToday = true 
	isShouldSeeStarToday = MaintenanceManager.isActivityOpen("consecutiveLogin") 
	local GameData = DataManager.getGameInitData()
	if GameData.sharkUserExtend and 
	   GameData.sharkUserExtend.continuousLoginInfo and 
	   GameData.sharkUserExtend.continuousLoginInfo.firstGetRewardTime 
	then
	    local firstSeeStarTime = GameData.sharkUserExtend.continuousLoginInfo.firstGetRewardTime
	    local timeDiff = user_CurPlayTime - firstSeeStarTime
	    if timeDiff / 86400 < 7 then
	        local lastSeeStarDay = GameData.sharkUserExtend.continuousLoginInfo.latestGetRewardTime
	        lastSeeStarDay = os.date("*t",lastSeeStarDay)
	        local curTime = os.date("*t",user_CurPlayTime)
	        if curTime.year == lastSeeStarDay.year and curTime.month == lastSeeStarDay.month and curTime.day == lastSeeStarDay.day then
	            isShouldSeeStarToday= false
	        end 
	    else
	        isShouldSeeStarToday = false
	    end 
	end
	return isShouldSeeStarToday   
end 

--new continue login 7 days judgement
function shouldPopContinueLoginPanelToday(user_CurPlayTime,paraOffsetDay)
	local isEnable = true 
	local remainDays = 6
	user_CurPlayTime = user_CurPlayTime + 28800 --加8时区，北京时间计算天数
	local todayFrom1970 = math.floor(user_CurPlayTime / (3600 * 24 ) )
	local GameData = DataManager.getGameInitData()
	if GameData.sharkUserExtendMore and 
	   GameData.sharkUserExtendMore.continuousLoginRewardInfoV2 and 
	   GameData.sharkUserExtendMore.continuousLoginRewardInfoV2.gainRewardDays 
	then
		local gainDays = GameData.sharkUserExtendMore.continuousLoginRewardInfoV2.gainRewardDays
		
		if table.getn(GameData.sharkUserExtendMore.continuousLoginRewardInfoV2.gainedContinuousLoginRewards) < 7 then
			remainDays = 6 - table.getn(GameData.sharkUserExtendMore.continuousLoginRewardInfoV2.gainedContinuousLoginRewards)
						
			if todayFrom1970 == gainDays then
				-- today has gained
				isEnable = false
			end
	    else
			if paraOffsetDay and todayFrom1970 <= gainDays + paraOffsetDay then
				--活动面板比正常的七日奖励多paraOffsetDay天显示
				
			else
				isEnable = false
			end
	    end 
	end
	return isEnable, remainDays, todayFrom1970    
end
----------------------------------------
-- 显示不同颜色的数字
-- num - 要显示的数字，pos_x/pos_y - 数字所在的位置，color - 数字的颜色，sign - 是否带符号，maxSize - 放大时最大大小
----------------------------------------
function createNumberEffect(num, pos_x, pos_y, color, sign, maxSize, noFadeout, returnSize, moveByPos, hidePlus)
	local pathAndName = "battle/pic/number_blue.png"
	if color == NumberColorEnum.blue then
		pathAndName = "battle/pic/number_blue.png"
	elseif color == NumberColorEnum.green then
	      pathAndName = "battle/pic/number_green.png"
	elseif color == NumberColorEnum.red then
	      pathAndName = "battle/pic/number_red.png"
	elseif color == NumberColorEnum.write then
	      pathAndName = "battle/pic/number_write.png"
	elseif color == NumberColorEnum.yellow then
	      pathAndName = "battle/pic/number_yellow.png"
	elseif color == NumberColorEnum.critical then
	      pathAndName = "battle/pic/number_Critcal.png"
	end
	
	local numStr = tostring(num)
	if sign ~= nil then
	      if num < 0 then
		      numStr = "/" .. math.abs(numStr)
		elseif num > 0 then
			if not hidePlus then
		      numStr = "." .. numStr
			end
	      end
	end
	if maxSize == nil then
		maxSize = 1.5
	end
	
	if not returnSize then
		returnSize = 1
	end
	
	local numberLabel = CCLabelAtlas:create(numStr, pathAndName, 25, 41, 46)
	numberLabel:setPosition( ccp(pos_x, pos_y) )
	numberLabel:setAnchorPoint( ccp(0.5, 0.5) )
	numberLabel:setOpacity(0)
	local animArray = CCArray:create()
	animArray:addObject(CCScaleTo:create(0.2, maxSize))
	animArray:addObject(CCScaleTo:create(0.1, returnSize))
	animArray:addObject(CCDelayTime:create(0.2))
	if (not noFadeout) then
		animArray:addObject(CCFadeOut:create(0.5))
	end
	local anim = CCSequence:create(animArray)
	numberLabel:runAction(anim)
	
	if moveByPos then
		numberLabel:runAction(CCMoveBy:create(0.2, moveByPos))
	end
	numberLabel:runAction(CCFadeIn:create(0.2))
	local numberLabel_co = CocosObject.new(numberLabel)
	return numberLabel_co
end

function createSpriteFrame(name)
	local texCache = CCTextureCache:sharedTextureCache()
	local tex = texCache:addImage(name)
	if not tex then
		return nil;
	end
	local size = tex:getContentSizeInPixels()
	local w = size.width
	local h = size.height
	local rect = CCRect(0, 0, w, h)
	local spriteFrame = CCSpriteFrame:createWithTexture( tex, rect )
	return spriteFrame
end

function getSpriteFrameByName(name)
	local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(name);
	return frame
end

function getDefaultCardBgSpriteFrame()
	local frame = getSpriteFrameByName("CardbattleXX3_card_bg.png")
	return frame
end


function getCanonItemByMetaId(metaId)
	 local item = CanonItem:create()
	 item:loadByMetaId(metaId)
	 return item
end

function getCanonCardByMeta(meta, sizeInfoType, locked , perfectType)
	local canonCard = CanonCard:create()

	if isInAppleReview() then
		canonCard:loadCard("card/card/" .. meta.harmoniousFigureID, "full", meta, sizeInfoType, locked , perfectType)
	else
		canonCard:loadCard("card/card/" .. meta.figureId, "full", meta, sizeInfoType, locked , perfectType)
	end

	return canonCard
end

----------------------------------------
-- 获取带有详细信息的大卡牌(name,level,exp,hp,atk,def,evolveLevel)
-- 需通过CanonCard的setLevel,setHp,setAtk,setDef设置属性值
----------------------------------------
function getBigCanonCardWithInfoByMetaId(metaId)
	local meta = MetaManager.card_meta[metaId]
	if meta then
		return getCanonCardByMeta(meta, SizeInfoTypes.BigWithInfo ,nil)
	end
	
	return getBigCanonCardWithInfoByMetaId(101022)
end

----------------------------------------
-- 获取不带详细信息的大卡牌
----------------------------------------
function getBigCanonCardNoInfoByMetaId(metaId)
	local meta = MetaManager.card_meta[metaId]
	if meta then
		return getCanonCardByMeta(meta, SizeInfoTypes.BigNoInfo,nil)
	end
	return getBigCanonCardNoInfoByMetaId(101022)
end

----------------------------------------
-- 军团战场用到的卡牌
----------------------------------------
function getBigCanonCardForUnionBattle(metaId)
	local meta = MetaManager.card_meta[metaId]
	if meta then
		return getCanonCardByMeta(meta, SizeInfoTypes.OnlyForUnionBattle)
	end
	return getBigCanonCardNoInfoByMetaId(101022)
end

----------------------------------------
-- 获取带等级、稀有度信息的小卡牌
-- 需通过CanonCard的setLevel设置属性值
----------------------------------------
function getSmallCanonCardWithLevelByMetaId(metaId)
	local meta = MetaManager.card_meta[metaId]
	if meta then
		return getCanonCardByMeta(meta, SizeInfoTypes.SmallWithLevel,nil)
	end
	return getSmallCanonCardWithLevelByMetaId(101022)
end

----------------------------------------
-- 获取带攻防血信息的小卡牌
-- 需通过CanonCard的setHp,setAtk,setDef设置属性值
----------------------------------------
function getSmallCanonCardWithPropByMetaId(metaId)
	local meta = MetaManager.card_meta[metaId]
	if meta then
		return getCanonCardByMeta(meta, SizeInfoTypes.SmallWithProp,nil)
	end
	return getSmallCanonCardWithPropByMetaId(101022)
end

----------------------------------------
-- 获取不带信息的小卡牌
----------------------------------------
function getSmallCanonCardNoInfoByMetaId(metaId)
	local meta = MetaManager.card_meta[metaId]
	if meta then
		return getCanonCardByMeta(meta, SizeInfoTypes.SmallNoInfo,nil)
	end
	return getSmallCanonCardNoInfoByMetaId(101022)
end

----------------------------------------
-- 获取带边框的和背景的卡牌人物头像Icon
----------------------------------------
function getHeadIconCanonCardByMetaId(metaId, locked,perfectType)
	local meta = MetaManager.card_meta[metaId]
	if meta then
		return getCanonCardByMeta(meta, SizeInfoTypes.IconHead, locked,perfectType)
	end
	return getSmallCanonCardNoInfoByMetaId(101022)
end

----------------------------------------
-- 获取带边框的和背景的卡牌人物头像Icon 但不显示头像上的星星
----------------------------------------
function getHeadIconNoStarCanonCardByMetaId(metaId)
	local meta = MetaManager.card_meta[metaId]
	if meta then
		return getCanonCardByMeta(meta, SizeInfoTypes.IconHeadNoStar , nil)
	end
	return getSmallCanonCardNoInfoByMetaId(101022)
end

function getBackpackHeadIconCanonCardByMetaId(metaId, locked ,perfectType)
	local meta = MetaManager.card_meta[metaId]
	if meta then
		return getCanonCardByMeta(meta, SizeInfoTypes.IconHeadBackpack, locked,perfectType)
	end
	return getBackpackHeadIconCanonCardByMetaId(101022)
end

function getCardSpriteFrameForName(metaId, name)
	local meta = MetaManager.card_meta[metaId]
	if meta then
		if isInAppleReview() then
			local cardSprite = CardSprite:create("card/card/" .. meta.harmoniousFigureID, "full")
			return cardSprite:getSpriteFrameByName(name)
		else
			local cardSprite = CardSprite:create("card/card/" .. meta.figureId, "full")
			return cardSprite:getSpriteFrameByName(name)
		end
	end
	return getCardSpriteFrame(101022, name)
end

----------------------------------------
-- 获取标准大小的卡牌SpriteFrame
----------------------------------------
function getCardSpriteFrame(metaId)
	--local canonCard = getBigCanonCardNoInfoByMetaId(metaId)
	--local cardSprite = canonCard:getSprite()
	--return cardSprite:getSpriteFrameByName("sdandard.png")
	return getCardSpriteFrameForName(metaId, "sdandard.png")
end

----------------------------------------
-- 获取头部大小的卡牌SpriteFrame
----------------------------------------
function getHeadCardSpriteFrame(metaId)
	--local canonCard = getBigCanonCardNoInfoByMetaId(metaId)
	--local cardSprite = canonCard:getSprite()
	--return cardSprite:getSpriteFrameByName("head.png")
	return getCardSpriteFrameForName(metaId, "head.png")
end

----------------------------------------
-- 获取全尺寸大小的卡牌SpriteFrame
----------------------------------------
function getFullCardSpriteFrame(metaId)
	--local canonCard = getBigCanonCardNoInfoByMetaId(metaId)
	--local cardSprite = canonCard:getSprite()
	--return cardSprite:getSpriteFrameByName("full.png")
	return getCardSpriteFrameForName(metaId, "full.png")
end

----------------------------------------
-- 获取宽屏尺寸大小的卡牌SpriteFrame
----------------------------------------
function getHalfWideCardSpriteFrame(metaId)
	--local canonCard = getBigCanonCardNoInfoByMetaId(metaId)
	--local cardSprite = canonCard:getSprite()
	--return cardSprite:getSpriteFrameByName("half.png")
	return getCardSpriteFrameForName(metaId, "half.png")
end

----------------------------------------
-- 获取卡牌的Icon SpriteFrame
----------------------------------------
--function getIconCardSpriteFrame(metaId)
	--local canonCard = getBigCanonCardNoInfoByMetaId(metaId)
	--local cardSprite = canonCard:getSprite()
	--canonCard:dispose()
	--return cardSprite:getSpriteFrameByName("icon.png")
--	return getCardSpriteFrameForName(metaId, "icon.png")
--end

function getCardBackGroundSpriteFrameByMeta(meta)
	if meta then
		local fileCardBg = "card/background/" .. meta.backgroundName
		local tex = CCTextureCache:sharedTextureCache():addImage(fileCardBg)
		local rt = CCRectMake(0, 0, tex:getContentSize().width, tex:getContentSize().height)
		local sp = CCSpriteFrame:createWithTexture(tex, rt)
		return sp
	end
	return nil
end

----------------------------------------
-- 获取卡牌背景的 SpriteFrame
----------------------------------------
function getCardBackGroundSpriteFrame(metaId)
	local meta = MetaManager.card_meta[metaId]
	if meta then
		return getCardBackGroundSpriteFrameByMeta(meta)
	end
	return nil
end


----------------------------------------
-- 获取卡牌边框的 SpriteFrame
----------------------------------------
function getCardBorderSpriteFrame(metaId)
	local meta = MetaManager.card_meta[metaId]
	if meta then
		local name = BigBorderDict[meta.rare]
		return CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(name)
	end
	return nil
end

function setNodeText(node, text)
	local className = toluahelper.getClass(node)
	if className == "CCLabelTTF" then
		tolua.cast(node, "CCLabelTTF")
		node:setString(text)
	elseif PlistResMgr:getInstance():getCCNodeClassName(node) == "ArtLabelTTF" then
		tolua.cast(node, "ArtLabelTTF")
		node:setText(text)
		node:construct()
	end
end

function setNodeColor(node, color)
	local className = toluahelper.getClass(node)
	if className == "CCLabelTTF" then
		tolua.cast(node, "CCLabelTTF")
		node:setColor(color)
	elseif PlistResMgr:getInstance():getCCNodeClassName(node) == "ArtLabelTTF" then
		tolua.cast(node, "ArtLabelTTF")
		--node:setCenter(color)
		node:setCenterColor(color)--原先的接口有误 modified by zheng.che @ 2014-12-21
		node:construct();
	end
end

function changeLabelToBMFont(label, str, fntFile)
	local bitmapLabel = BitmapText:create(str, "common/stage_name.fnt", label:getDimensions().width, label:getHorizontalAlignment())
	bitmapLabel:setPosition(ccp(label:getPosition().x, label:getPosition().y))
	bitmapLabel:setDimensions(label:getDimensions())
	bitmapLabel:setAnchorPoint(ccp(0, 1))
	bitmapLabel:setRotationX(label:getRotationX())
	bitmapLabel:setRotationY(label:getRotationY())
	bitmapLabel.name = label.name
	local parent = label:getParent()
	label:removeFromParentAndCleanup(true)
	parent:addChild(bitmapLabel)
end

local systemBackKeyTable = {}

function onSystemBackKeyClick()
	--print("clickSystemBackKey")
	
	if tonumber(Get_ShareData( "New_User_Guide_Running")) == 1 or tonumber(g_isRetryShowing) == 1 then
		return
	end
	
	if RequestLoadingBox.isExist() then
		do return end
	end
	
	if g_curSceneEnum == SceneEnum.MainMenuScene then
		
		if isLenovoAndroid() then
			
			showLenovoExitPic()
	    elseif isAnzhiAndroid() then
			
			showAnzhiExitPic()
		else
		    PlistResMgr:getInstance():tryToCloseActivity(getTextByKey("popup_exitGameText"), getTextByKey("yes"), getTextByKey("cancel"))
		end
		do return end
	end
	
	local scene = Director:mgr():run()
	if (not scene) or (scene.curSceneEnum ~= SceneEnum.UnionPkScene) then
		--军团战避免出现被动点击事件 否则会点到不该点的地方
		if #systemBackKeyTable > 0 then
			local position = systemBackKeyTable[#systemBackKeyTable].pos
			if onTouchRootLayer(CCTOUCHBEGAN, position.x, position.y,TouchType.systemBackTouch) then
				onTouchRootLayer(CCTOUCHENDED, position.x, position.y)
			end
		end
	end

	NotificationManager:dispatchEvent(Event.new("SYSTEM_BACK_KEY_CLICK"))
end

function registerBackKey(name, button)
	unregisterBackKey(name)
	local infoTable = {}
	infoTable.name = name
	button = button.display
	local anchorPoint = ccpSub(ccp(0.5, 0.5), button:getAnchorPoint())
	local contentSize = button:getContentSize()
	local anchorPointPos = ccp(contentSize.width * anchorPoint.x, contentSize.height * anchorPoint.y)
	infoTable.pos = ccp(contentSize.width * anchorPoint.x, contentSize.height * anchorPoint.y)
	while button:getParent()
	do
		--local anchorPoint = button:getAnchorPoint()
		--local pos = button:getPosition()
		--local contentSize = button:getContentSize()
		--local anchorPointPos = ccp(contentSize.width * anchorPoint.x, contentSize.height * anchorPoint.y)
		--local pixielPos = ccpSub(pos, anchorPointPos)
		infoTable.pos = ccpAdd(infoTable.pos,  button:getPosition())--pixielPos)
		button = button:getParent()
	end
	table.insert(systemBackKeyTable, infoTable)
end

function unregisterBackKey(name)
	for k,v in ipairs(systemBackKeyTable)
	do
		if v.name == name then
			table.remove(systemBackKeyTable, k)
			break;
		end
	end
end

g_waittingForUploadGuideFlag = false
g_curGuide = nil

function IsCurrentNewUserGuideRunning()
	if tonumber(Get_ShareData( "New_User_Guide_Running")) ~= 1 then
		return false
	end
	
	if g_waittingForUploadGuideFlag then
		return false
	end
	return true
end

--如果断网，会出现前后端新手引导不统一的状况，在这里处理
function IsGuideAlreadyExecutedNotSynsWithServer( guide )
	-- body
	local ret = false
	--处理武将强化的新手引导
	if(guide  == GuideConfig.kCardUpgrade) then
		local mainCardId = DataManager.getGameInitData().sharkUser.mainCardId
		local cardData = nil
		for k,v in pairs(DataManager.getCardsData()) do
			--print(k,table.serialize(v))
			if(v.cardId == mainCardId) then
				if(v.level > 20) then
			          --jump guide
			          local data = DataManager.getGameInitData()
			          local stepTutorial = {funcName = guide , step = 1}
			          table.insert(data.sharkUserExtend.tutorialSteps , stepTutorial)

			          local params = {funcName = guide, step = 1}
			          local request = RecordTutorialStepRequest.new( params, rpc.SendingPriority.kHigh )
			          request:start()
			          ret = true
			    end
			end

		end
	end

	--处理武将进阶的新手引导
	if GuideConfig.kCardEvol == guide then
		local mainCardId = DataManager.getGameInitData().sharkUser.mainCardId
		local cardData = nil
		for k,v in pairs(DataManager.getCardsData()) do
			-- print(k,v)
			if(v.cardId == mainCardId) then
				if(v.metaId == 102112) then
					local data = DataManager.getGameInitData()
			        local stepTutorial = {funcName = guide , step = 1}
			        table.insert(data.sharkUserExtend.tutorialSteps , stepTutorial)

			        local params = {funcName = guide, step = 1}
			        local request = RecordTutorialStepRequest.new( params, rpc.SendingPriority.kHigh )
			        request:start()
			        ret = true
				end
			end
		end
	end

	--处理附灵的新手引导
	if GuideConfig.kSacrifice == guide then
		if DataManager.getGameInitData().sharkUserExtend.enchantStepReward then
			ret = true
		end
	end

	return ret
end

function IsGuideExecuted( guide )
	local guideExe = false
	local data = DataManager.getGameInitData()
	for k,v in pairs(data.sharkUserExtend.tutorialSteps) do
	  if v.funcName == guide then
			guideExe = true
	  end
	end
	if IsGuideAlreadyExecutedNotSynsWithServer(guide) then
		guideExe = true
	end
	return guideExe
end

function ExeNewGuide( guide )
	--print("********************* runing new guide" .. guide)
	--if guide ~= kEnterGame then
	--	local uid = DataManager.getCurrUser().uid
	--	local key = "Forbid_New_User_Guide_" .. uid
	--	local flag = CCUserDefault:sharedUserDefault()->getIntegerForKey(key)
	--	if flag == 1 then
	--		he_log_info(****************NOT RUN NEW USER GUIDE ********************)
	--		he_log_info(key)
	--		do return end
	--	end
	--end

	
	if not IsGuideExecuted(guide) then
    
    if g_curGuide ~= nil then --判断，如果上一个状态还没保存，就在这里保存，以免漏掉
      Set_ShareData( "Guide_Save_State", 0 )
      GlobalScene_globalUpdate()
    end
    
		RunScript_MultiThread( "/canon/script_and_guide/" .. guide .. ".lua", 0 )
		g_curGuide = guide
		Set_ShareData( "Guide_Save_State", 1);
		g_waittingForUploadGuideFlag = true
	end
end

function isNewUser()
	if CCUserDefault:sharedUserDefault():getIntegerForKey("isNewUser") == 0 then
		CCUserDefault:sharedUserDefault():setIntegerForKey("isNewUser", 1)
		return true
	else
		return false
	end
end

local current_music_name = nil
----------------------------------------
-- 播放背景音乐
----
-- music 音乐文件名称
-- loop 是否循环
-- restart 是否从头开始/继续播放
----------------------------------------
function CanonPlayBackgroundMusic( music, loop, restart )
	local musicFlag = CCUserDefault:sharedUserDefault():getIntegerForKey("music_option")
	if musicFlag == 0 or musicFlag == 1 then
    if (current_music_name ~= music or restart) then
      SimpleAudioEngine:sharedEngine():playBackgroundMusic(music, loop)
      current_music_name = music
    end
	end
end

function recordBattleInfo(data)
	local destinationFile = io.open("BattleInfo.log", "w")
	if destinationFile ~= nil then
		local inBattleInfoStr = table.serialize(data)
		if inBattleInfoStr ~= nil then
			destinationFile:write(inBattleInfoStr)
		end
		destinationFile:close();
	end
end

function readBattleInfo()
	local battleInfoString = CCString:createWithContentsOfFile("BattleInfo.log");
	local _json = require("cjson")
	local battleInfo = _json.decode(battleInfoString:getCString())
	return battleInfo;
end

function isCurVersionForTest()
	return false
end

function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str	
end

function recordAchievement(num, percentage, isBanner)
if __IOS then
	PlatformMgr:getInstance():recordAchievement(num, percentage, isBanner)
end
end

function recordScore(score)
if __IOS then
	PlatformMgr:getInstance():recordScore(score)
end
end

local requireSwitch = true
function conditionalRequire(filePath)
  if requireSwitch then
    require(filePath)
  end
end

function getFloatNumber(number)
	number = math.floor((number + 1e-5) / 1e-4) * 1e-4
	return number
end

function doHttpRequest(url, params, callback, needEncode, needShowLoading)
	local function onResponseGet( response )
		if needShowLoading then
			RequestLoadingBox:removeLoadingBox()
		end
		callback(response)
	end
	local url = url
    local request = HttpRequest:createPost(url)
    local timeout = 10 
    request:setConnectionTimeoutMs(timeout * 1000) 
    request:setTimeoutMs(timeout * 1000)  
    request:addHeader("Content-Type:application/x-www-form-urlencoded")
    local dataString = ""
    for k,v in pairs(params) do
    	dataString = dataString..k.."="..v.."&"
    end
    dataString = dataString:sub(1, -2) --remove the last "&"
    print("dataString is "..dataString)
    if needEncode then
    	dataString = PlatformMgr:getInstance():encodeData(dataString)
    end
    if needShowLoading then
	    RequestLoadingBox:createLoadingBox(false)
		RequestLoadingBox:showLoadingBox()
	end
	local dataStringLen = dataString:len()
	request:setPostData(dataString, dataStringLen)
	HttpClient:getInstance():sendRequest(onResponseGet, request)
end

---------------------------------------------------
-- 全类型tostring 仅用作调试
---------------------------------------------------
function tostringRich(obj, depth)
	indent = nil
	limit = nil
	jstack = nil
	
	if obj == nil then
		return "nil"
	end
	if type(obj) == "string" then
		return "\"" .. obj .. "\""
	end
	if type(obj) == "boolean" then
		return tostring(obj)
	end
	if type(obj) == "number" then
		return tostring(obj)
	end
	if type(obj) == "table" then
		return table.tostring(obj, indent, limit, depth, jstack)
	end
	if type(obj) == "userdata" then
		return table.tostring(obj, indent, limit, depth, jstack)
	end
	return "[未知类型type = " .. type(obj) .. "]"
end

---判断是否在审核中
local _isInAppleReviewWar = false
function isInAppleReview()
	return _isInAppleReviewWar
end
function setInAppleReview(bIsInWar)
	_isInAppleReviewWar = bIsInWar
end
---------------------------------------------------
-- 获得滚动区域相关属性
---------------------------------------------------
function getTableViewSizes(tableViewDisplay)
	local result = {}
	if not tableViewDisplay then
		return result
	end
	local tableViewSize = tableViewDisplay:getGroupBounds(tableViewDisplay:getParent()).size
	local itemBeginDisplay = tableViewDisplay:getChildByName("list_begin")--列表第一项元件 一定存在
	local item2Display = tableViewDisplay:getChildByName("list_2")--列表第二项元件 没有表示无间隔
	local itemBGDisplay = itemBeginDisplay:getChildByName("list_bg")--列表内部的自定义边界元件 没有表示用元件整体大小
	local itemSize = itemBeginDisplay:getGroupBounds(itemBeginDisplay:getParent()).size
	if itemBGDisplay then
		--存在美术自定义item边界
		itemSize = itemBGDisplay:getGroupBounds(itemBGDisplay:getParent()).size
	end

	result.table_width = tableViewSize.width
	result.table_height = tableViewSize.height
	result.table_posX = tableViewDisplay:getPositionX()
	result.table_posY = tableViewDisplay:getPositionY()
	result.item_width = itemSize.width
	result.item_height = itemSize.height

	if item2Display then
		--存在第二元件(带间距) 高度重置
		result.item_height = itemBeginDisplay:getPositionY() - item2Display:getPositionY()
	end

	if SystemManager.debug then
		print("result = " .. tostringRich(result))
	end

	return result
end


--对数字进行四舍五入的函数
local math = require('math')

function roundOff(num, n)
    if n > 0 then
        local scale = math.pow(10, n-1)
        return math.floor(num / scale + 0.5) * scale
    elseif n < 0 then
        local scale = math.pow(10, n)
        return math.floor(num / scale + 0.5) * scale
    elseif n == 0 then
        return num
    end
end

function getServerIdFromUid(uid)
	local serverId = string.sub(uid,string.len(uid)-3)
	while(string.sub(serverId, 1, 1) == "0")
	do
		serverId = string.sub(serverId, 2, string.len(serverId)) 
	end
	return serverId
end

-- 查询某位置是否在元件区域内
-- positionCCP 判定位置
-- display 被检测的元件
function isHittedDisplay(positionCCP, display)
	local displayPosition
	local displaySize
	if display.refCocosObj then
		--一般元件
		displayPosition = display:getPosition()
		displaySize = display:getGroupBounds(display:getParent()).size
	else
		--Cocos2dx元件
		displayPosition = HeDisplayUtil:getNodePosition(display)
		displaySize = HeDisplayUtil:getNodeGroupBounds(display, display:getParent(), kHitAreaObjectTag).size
	end

	-- print("positionCCP.x = " .. tostringRich(positionCCP.x))
	-- print("positionCCP.y = " .. tostringRich(positionCCP.y))
	-- print("displaySize.width = " .. tostringRich(displaySize.width))
	-- print("displaySize.width = " .. tostringRich(displaySize.width))
	-- print("displayPosition.x = " .. tostringRich(displayPosition.x))
	-- print("displayPosition.y = " .. tostringRich(displayPosition.y))
	if (positionCCP.x >= displayPosition.x) 
	and (positionCCP.x <= displayPosition.x + displaySize.width) 
	and (positionCCP.y <= displayPosition.y) 
	and (positionCCP.y >= displayPosition.y - displaySize.height) then
		return true
	end
	return false
end