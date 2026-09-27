require "canon.request.FacebookActivityRequest"
require "canon.panel.FacebookShareTriggerPanel"

FacebookShareManager = class()

FacebookShareOpenKey = {
	OPEN = 1,
	CLOSE = 2
}
function FacebookShareManager.isOpenFacebookShareFunc()
	if not DataManager.GameMetaData.fbShareConfig then
		return false
    end
    local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.fbShareConfig.featureNamePopup)
	
	if not isEnable then
		return false
	end
	
	return false
	--[[
	if isIosTW() or isGooglePlayTW() or isTWHE() or isTWibuka() or isMobile01() or isOffermeTW() then
		--用户选择不绑定facebook且取消过一下则不弹出分享窗
		--
		local shareInfo = localStorage.getShouldFacebbookShareInfo(   )
		local shareOpen = FacebookShareOpenKey.OPEN
		if shareInfo ~= "" then
			he_log_info("+++++++++++++++++++++++++++ facebook share open judge:".. table.serialize (shareInfo))
			shareOpen = shareInfo.shareOpen
		end 
		
		if shareInfo.shareId == nil or shareInfo.shareId == "" then
			he_log_info("+++++++++++++++++++++++++++ facebook share open judge: false 1")
			--return false
		end
		if not isBindFacebook() and shareOpen == FacebookShareOpenKey.CLOSE then
			he_log_info("+++++++++++++++++++++++++++ facebook share open judge: false 2")
			return false
		else
			he_log_info("+++++++++++++++++++++++++++ facebook share open judge: true")
			return true
		end
	else
		he_log_info("+++++++++++++++++++++++++++ facebook share open judge: false 3")
		return false
	end--]]
end

--check whether No.shareId info should share to facebook
function FacebookShareManager.judgeShouldShareFacebook(shareId)
	local shouldShare = true
	local gameData = DataManager.getGameInitData()
	if gameData.sharkFbShare and gameData.sharkFbShare.sharkFbShareGameList then
		local shareList = gameData.sharkFbShare.sharkFbShareGameList
		for k,v in pairs(shareList) do
			if v.shareId == shareId then
				shouldShare = false
				break
			end
		end
	end
	return shouldShare
end

local runningShareId = nil
local runningCallback = nil
local runningShareText = nil
function FacebookShareManager.setFacebookShareId(shareId)
	runningShareId = shareId
end
function FacebookShareManager.setFacebookShareCallback(callback)
	runningCallback = callback
end

function FacebookShareManager.popFacebookTriggerSharePanel(shareId,shareText,callback)
	local curScene = Director.sharedDirector():getRunningScene()
	local sharePanel = FacebookShareTriggerPanel:create( curScene,shareId,shareText,callback )
    PopoutManager:sharedManager():popout( sharePanel, kPopoutDir.kScale, true, false ,curScene )
end

--临时处理函数
--[[
local function requestFacebookTriggerShare(shareSuccess)
	local function ShareFacebookTriggerSucc(response)
		--本地更新记录sharkFbShareGameList
		local gameData = DataManager.getGameInitData()
		if gameData.sharkFbShare and gameData.sharkFbShare.sharkFbShareGameList then
			table.insert(gameData.sharkFbShare.sharkFbShareGameList,{
																		shareId = runningShareId,
																		shareSuccess = shareSuccess
																	})
		else
			--first write facebook share data
			if gameData.sharkFbShare then
				gameData.sharkFbShare["sharkFbShareGameList"] = { 
																	{
																		shareId = runningShareId,
																		shareSuccess = shareSuccess
																	}
																}
			else
				gameData["sharkFbShare"] = {}
				gameData.sharkFbShare["sharkFbShareGameList"] = { 
																	{
																		shareId = runningShareId,
																		shareSuccess = shareSuccess
																	}
																}
			end 
		end
		DataManager.setGameInitData(gameData)
		if runningCallback and type(runningCallback) == "function" then
			runningCallback()
		end
	end
	local function ShareFacebbookTriggerFail(response)
		local errorCode = tonumber(response.data)
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
	local params = {shareId = runningShareId,shareSuccess = shareSuccess}
	local request = FacebookRecordTriggerShareRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.ShareFacebookTriggerSucceed, ShareFacebookTriggerSucc)
	request:addEventListener(RequestNotifyEnum.ShareFacebookTriggerFailed, ShareFacebbookTriggerFail)
	request:start() 
end
 
--临时处理函数
function gotoShareFacebook()
	he_log_info("+++++++++++++++++++++++++++goto facebook share ++++++++++++++++++++++++++++++++")
	--判断是否bind
	if not isBindFacebook() then
		local function gotoBindFacebook()
			DataManager.clearData()
			--保存当前shareid 重新登录后重新弹分享面板
			local shareInfo = {
								shareId = runningShareId
							   }
			localStorage.saveShouldFacebbookShareInfo(shareInfo)
			Director:sharedDirector():replaceScene(LoginScene:create())
			return
		end
		
		local function cancelBindFacebook()
			--TO DO	记录状态，之后不再弹分享请求弹窗
		end
		CanonMessageBox:Show(getTextByKey("Fbactivity_error_txt1"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoBindFacebook, cancelBindFacebook)
		return
	end

	--todo 调用facebook share 接口
	requestFacebookTriggerShare(true)
end

--临时处理函数
function cancelShareFacebook()
	he_log_info("+++++++++++++++++++++++++++cancel facebook share ++++++++++++++++++++++++++++++++")
	--to do 记录状态，之后不再弹分享请求弹窗
	--删除本地记录待弹shareid
	local shareInfo = "" 
	localStorage.saveShouldFacebbookShareInfo( shareInfo ) 
	requestFacebookTriggerShare(false)
end
--]]

--user level up share
--user can level up several levels at once,so do not judge precise level
local levelShareList = {
	--[2] = {level = 2, shareId = 1},
	--[3] = {level = 3, shareId = 2},
	--[4] = {level = 4, shareId = 3},
	[5] = {level = 5, shareId = 4},
	[6] = {level = 6, shareId = 5},
	[7] = {level = 7, shareId = 6},
	--[8] = {level = 8, shareId = 7},
	[9] = {level = 9, shareId = 8},
	[10] = {level = 10, shareId = 9},
	[11] = {level = 11, shareId = 10},
	[12] = {level = 12, shareId = 11},
	[13] = {level = 13, shareId = 12},
	[14] = {level = 14, shareId = 13},
}
--when user level up, check should share info to facebook
function FacebookShareManager.facebookShareLevelUp(userLevel,callback)
	if not FacebookShareManager.isOpenFacebookShareFunc() then
		if callback and type(callback) == "function" then
			callback()
		end
		return
	end
	
	local level = math.floor(userLevel / 10)
	if levelShareList[level] == nil then
		--20 30 40 80 not pop because there are guides
		if callback and type(callback) == "function" then
			callback()
		end
		return
	end
	local shareId = levelShareList[level].shareId
	if FacebookShareManager.judgeShouldShareFacebook(shareId) then
		he_log_info("+++++++++++++++++++++++++++pop facebook share messagebox++++++++++++++++++++++++++++++++")
		local shareText = getTextByKey("FBactivity_share_title1",{num1 = level * 10})
		runningShareId = shareId
		runningCallback = callback
		runningShareText = shareText
		--临时弹框，分享facebook功能
		--CanonMessageBox:Show(getTextByKey("shareFacebook balabala"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoShareFacebook, cancelShareFacebook)
		
		FacebookShareManager.popFacebookTriggerSharePanel(shareId,shareText,callback)
		return
	else
		he_log_info("+++++++++++++++++++++++++++not goto facebook share ++++++++++++++++++++++++++++++++")
		if callback and type(callback) == "function" then
			callback()
			return
		end
	end		
end

--user clean one special charpter share
local charpterCleanShareList = {
	[13] = {charpterId = 13, charpterName = "xiaopei", shareId = 14},--小沛
	[14] = {charpterId = 14, charpterName = "julu", shareId = 15},--巨鹿
	[15] = {charpterId = 15, charpterName = "chibi", shareId = 16},--赤壁
	[16] = {charpterId = 16, charpterName = "guandu", shareId = 17},--官渡
	[17] = {charpterId = 17, charpterName = "jieting", shareId = 18},--街亭
	[18] = {charpterId = 18, charpterName = "shouchun", shareId = 19},--寿春
	[19] = {charpterId = 19, charpterName = "hanzhong", shareId = 20},--汉中
	[20] = {charpterId = 20, charpterName = "wancheng", shareId = 21},--宛城
	[21] = {charpterId = 21, charpterName = "changan", shareId = 22},--长安
	[22] = {charpterId = 22, charpterName = "xuchang", shareId = 23},--许昌
	[23] = {charpterId = 23, charpterName = "xiapi", shareId = 24},--下邳
	[24] = {charpterId = 24, charpterName = "yiling", shareId = 25},--夷陵
	[25] = {charpterId = 25, charpterName = "wuzhangyuan", shareId = 26},--五丈原
	[26] = {charpterId = 26, charpterName = "xinye", shareId = 27},--新野
	[27] = {charpterId = 27, charpterName = "jianye", shareId = 28},--建邺
	[28] = {charpterId = 28, charpterName = "nanzhong", shareId = 29},--南中
	[29] = {charpterId = 29, charpterName = "xiliang", shareId = 30},--西凉
	[30] = {charpterId = 30, charpterName = "chengdu", shareId = 31},--成都
}

--when user clean one special charpter, check should share info to facebook
function FacebookShareManager.facebookShareCharpterMapClean(callback)
	if not FacebookShareManager.isOpenFacebookShareFunc() then
		if callback and type(callback) == "function" then
			callback()
		end
		return
	end
	
	local cleanControyId = CountryManager:sharedManager().selectedCountryID
	local curChapterId = CountryManager:sharedManager().selectedChapterID
	if MetaManager.battle_chapter[curChapterId + 1] or charpterCleanShareList[cleanControyId] == nil then
		if callback and type(callback) == "function" then
			callback()
		end
		return
	end
	
	local shareId = charpterCleanShareList[cleanControyId].shareId
	if FacebookShareManager.judgeShouldShareFacebook(shareId) then
		he_log_info("+++++++++++++++++++++++++++pop facebook share messagebox++++++++++++++++++++++++++++++++")
		local shareText = getTextByKey("FBactivity_share_title2",{city = CountryManager:sharedManager():getCountryName(cleanControyId)})
		runningShareId = shareId
		runningCallback = callback
		runningShareText = shareText
		--临时弹框，分享facebook功能
		--CanonMessageBox:Show(getTextByKey("shareFacebook balabala"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoShareFacebook, cancelShareFacebook)
		FacebookShareManager.popFacebookTriggerSharePanel(shareId,shareText,callback)
		return
	else
		he_log_info("+++++++++++++++++++++++++++not goto facebook share ++++++++++++++++++++++++++++++++")
		if callback and type(callback) == "function" then
			callback()
		end
	end	
end

--user clean one special charpter share
local eliteMissionCleanShareList = {
	[129115] = {eliteMissionId = 129115, charpterId = 12, charpterName = "fancheng", shareId = 32},--樊城
	[139120] = {eliteMissionId = 139120, charpterId = 13, charpterName = "xiaopei", shareId = 33},--小沛
	[149120] = {eliteMissionId = 149120, charpterId = 14, charpterName = "julu", shareId = 34},--巨鹿
	[159125] = {eliteMissionId = 159125, charpterId = 15, charpterName = "chibi", shareId = 35},--赤壁
	[169125] = {eliteMissionId = 169125, charpterId = 16, charpterName = "guandu", shareId = 36},--官渡
	[179125] = {eliteMissionId = 179125, charpterId = 17, charpterName = "jieting", shareId = 37},--街亭
	[189125] = {eliteMissionId = 189125, charpterId = 18, charpterName = "shouchun", shareId = 38},--寿春
	[199125] = {eliteMissionId = 199125, charpterId = 19, charpterName = "hanzhong", shareId = 39},--汉中
	[209125] = {eliteMissionId = 209125, charpterId = 20, charpterName = "wancheng", shareId = 40},--宛城
	[219125] = {eliteMissionId = 219125, charpterId = 21, charpterName = "changan", shareId = 41},--长安
	[229125] = {eliteMissionId = 229125, charpterId = 22, charpterName = "xuchang", shareId = 42},--许昌
}
--when user clean one special EliteMission, check should share info to facebook
function FacebookShareManager.facebookShareEliteMission(callback)	
	if not FacebookShareManager.isOpenFacebookShareFunc() then
		if callback and type(callback) == "function" then
			callback()
		end
		return
	end
	
	local maxFinishedEliteId = EliteManager.getMaxFinishedEliteId()
	if eliteMissionCleanShareList[maxFinishedEliteId] == nil then
		if callback and type(callback) == "function" then
			callback()
		end
		return
	end
	local shareId = eliteMissionCleanShareList[maxFinishedEliteId].shareId
	local cleanControyId = eliteMissionCleanShareList[maxFinishedEliteId].charpterId
	if FacebookShareManager.judgeShouldShareFacebook(shareId) then
		he_log_info("+++++++++++++++++++++++++++pop facebook share messagebox++++++++++++++++++++++++++++++++")
		local shareText = getTextByKey("FBactivity_share_title2",{city = CountryManager:sharedManager():getCountryName(cleanControyId)})
		runningShareText = shareText
		runningShareId = shareId
		runningCallback = callback
		--临时弹框，分享facebook功能
		--CanonMessageBox:Show(getTextByKey("shareFacebook balabala"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoShareFacebook, cancelShareFacebook)
		FacebookShareManager.popFacebookTriggerSharePanel(shareId,shareText,callback)
		return
	else
		he_log_info("+++++++++++++++++++++++++++not goto facebook share ++++++++++++++++++++++++++++++++")
		if callback and type(callback) == "function" then
			callback()
		end
	end	
end

--when user first clean sky tower, check should share info to facebook
function FacebookShareManager.facebookShareSkyTowerClean(callback)	
	if not FacebookShareManager.isOpenFacebookShareFunc() then
		if callback and type(callback) == "function" then
			callback()
		end
		return
	end
	
	local shareId = 43
	if FacebookShareManager.judgeShouldShareFacebook(shareId) then
		he_log_info("+++++++++++++++++++++++++++pop facebook share messagebox++++++++++++++++++++++++++++++++")
		local shareText = getTextByKey("FBactivity_share_title15")
		runningShareText = shareText
		runningShareId = shareId
		runningCallback = callback
		--临时弹框，分享facebook功能
		--CanonMessageBox:Show(getTextByKey("shareFacebook balabala"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoShareFacebook, cancelShareFacebook)
		FacebookShareManager.popFacebookTriggerSharePanel(shareId,shareText,callback)
	else
		he_log_info("+++++++++++++++++++++++++++not goto facebook share ++++++++++++++++++++++++++++++++")
		if callback and type(callback) == "function" then
			callback()
		end
	end
end

--user first get 5/6 card/equip share
FacebookCardEquipShareID = {
	STAR5CARD = 44,		--首次获得5星卡牌
	STAR6CARD = 45,		--首次获得6星卡牌
	STAR5EQUIP = 46,	--首次获得5星装备
	STAR6EQUIP = 47,	--首次获得6星装备
}
local firstCardEquipShareList = {
	[FacebookCardEquipShareID.STAR5CARD] = {desc = "FBactivity_share_title3", shareId = 44},
	[FacebookCardEquipShareID.STAR6CARD] = {desc = "FBactivity_share_title4", shareId = 45},
	[FacebookCardEquipShareID.STAR5EQUIP] = {desc = "FBactivity_share_title5", shareId = 46},
	[FacebookCardEquipShareID.STAR6EQUIP] = {desc = "FBactivity_share_title6", shareId = 47},
}
--when user first get 5/6 card/equip, check should share info to facebook
function FacebookShareManager.facebookShareCardEquip(card_equip_id,callback)	
	--if not FacebookShareManager.isOpenFacebookShareFunc() then
	--	if callback and type(callback) == "function" then
	--		callback()
	--	end
	--	return true
	--end
	
	--if FacebookShareManager.judgeShouldShareFacebook(card_equip_id) then
		he_log_info("+++++++++++++++++++++++++++pop facebook share messagebox++++++++++++++++++++++++++++++++")
		local shareText = getTextByKey(firstCardEquipShareList[card_equip_id].desc)
		runningShareText = shareText
		runningShareId = card_equip_id
		runningCallback = callback
		--临时弹框，分享facebook功能
		--CanonMessageBox:Show(getTextByKey(firstCardEquipShareList[card_equip_id].desc), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoShareFacebook, cancelShareFacebook)
		FacebookShareManager.popFacebookTriggerSharePanel(card_equip_id,shareText,callback)
		return true
	--else
	--	he_log_info("+++++++++++++++++++++++++++not goto facebook share ++++++++++++++++++++++++++++++++")
	--	if callback and type(callback) == "function" then
	--		callback()
	--	end
	--	return false
	--end
end

--arena rank share list
FacebookArenaRankShareID = {
	FIRST_100 = {shareId = 48, rank = 100},
	FIRST_10 = {shareId = 49, rank = 10},
}
--when user first enter 10/100 arena rank, check should share info to facebook
function FacebookShareManager.facebookShareArenaRank(rankShareId,callback)	
	--if not FacebookShareManager.isOpenFacebookShareFunc() then
	--	if callback and type(callback) == "function" then
	--		callback()
	--	end
	--	return true
	--end
	
	if FacebookShareManager.judgeShouldShareFacebook(rankShareId.shareId) then
		he_log_info("+++++++++++++++++++++++++++pop facebook share messagebox++++++++++++++++++++++++++++++++")
		local shareText = getTextByKey("FBactivity_share_title7", {num1 = rankShareId.rank})
		runningShareText = shareText
		runningShareId = rankShareId.shareId
		runningCallback = callback
		--临时弹框，分享facebook功能
		--CanonMessageBox:Show(getTextByKey("ARENA RANK = " .. rankShareId.shareId), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoShareFacebook, cancelShareFacebook)
		FacebookShareManager.popFacebookTriggerSharePanel(rankShareId.shareId,shareText,callback)
		return true
	else
		he_log_info("+++++++++++++++++++++++++++not goto facebook share ++++++++++++++++++++++++++++++++")
		if callback and type(callback) == "function" then
			callback()
		end
		return false
	end
end 

----
--user first get purple/orange spirit share
FacebookSpiritShareID = {
	PURPLE = {shareId = 50, desc = "FBactivity_share_title16"},		--首次获得紫色元神
	ORANGE = {shareId = 51,	desc = "FBactivity_share_title17"},		--首次获得橙色元神
}
--when user first get purple/orange spirit, check should share info to facebook
function FacebookShareManager.facebookShareSpirit(spiritShareId,callback)	
	if not FacebookShareManager.isOpenFacebookShareFunc() then
		if callback and type(callback) == "function" then
			callback()
		end
		return true
	end
	
	if FacebookShareManager.judgeShouldShareFacebook(spiritShareId.shareId) then
		he_log_info("+++++++++++++++++++++++++++pop facebook share messagebox++++++++++++++++++++++++++++++++")
		local shareText = getTextByKey(spiritShareId.desc)
		runningShareText = shareText
		runningShareId = spiritShareId.shareId
		runningCallback = callback
		--临时弹框，分享facebook功能
		--CanonMessageBox:Show(getTextByKey("facebook spirit share" .. spiritShareId.shareId), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoShareFacebook, cancelShareFacebook)
		FacebookShareManager.popFacebookTriggerSharePanel(spiritShareId.shareId,shareText,callback)
		return true
	else
		he_log_info("+++++++++++++++++++++++++++not goto facebook share ++++++++++++++++++++++++++++++++")
		if callback and type(callback) == "function" then
			callback()
		end
		return false
	end
end

----
--user kingtemple level up share
local FacebookKingTempleShareID = {
	[2] = {TEMPLE_LEVEL_SHAREID = 52},	--王者殿堂2级
	[3] = {TEMPLE_LEVEL_SHAREID = 53},	--王者殿堂3级
	[4] = {TEMPLE_LEVEL_SHAREID = 54},	--王者殿堂4级
	[5] = {TEMPLE_LEVEL_SHAREID = 55},	--王者殿堂5级
	[6] = {TEMPLE_LEVEL_SHAREID = 56},	--王者殿堂6级
	[7] = {TEMPLE_LEVEL_SHAREID = 57},	--王者殿堂7级
}
--when user level up king temple, check should share info to facebook
function FacebookShareManager.facebookShareKingTemple(kingTempleLevel,callback)	
	if not FacebookShareManager.isOpenFacebookShareFunc() then
		if callback and type(callback) == "function" then
			callback()
		end
		return true
	end
	
	if FacebookKingTempleShareID[kingTempleLevel] == nil then
		if callback and type(callback) == "function" then
			callback()
		end
		return false
	end
	
	local shareId = FacebookKingTempleShareID[kingTempleLevel].TEMPLE_LEVEL_SHAREID
	if FacebookShareManager.judgeShouldShareFacebook(shareId) then
		he_log_info("+++++++++++++++++++++++++++pop facebook share messagebox++++++++++++++++++++++++++++++++")
		local shareText = getTextByKey("FBactivity_share_title8",{num1 = kingTempleLevel})
		runningShareText = shareText
		runningShareId = shareId
		runningCallback = callback
		--临时弹框，分享facebook功能
		--CanonMessageBox:Show(getTextByKey("facebook spirit share" .. shareId), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoShareFacebook, cancelShareFacebook)
		FacebookShareManager.popFacebookTriggerSharePanel(shareId,shareText,callback)
		return true
	else
		he_log_info("+++++++++++++++++++++++++++not goto facebook share ++++++++++++++++++++++++++++++++")
		if callback and type(callback) == "function" then
			callback()
		end
		return false
	end
end

----
--user card evolution share
FacebookCardEvolutionShareID = {
	STAR5CARD_FIRST_EVO_SHAREID = {shareId = 58, desc = "FBactivity_share_title9"},	--五星卡牌第一次进阶
	STAR5CARD_MAX_EVO_SHAREID = {shareId = 59, desc = "FBactivity_share_title10"},		--五星卡牌Max进阶
	STAR6CARD_FIRST_EVO_SHAREID = {shareId = 60, desc = "FBactivity_share_title11"},	--六星卡牌第一次进阶
	STAR6CARD_MAX_EVO_SHAREID = {shareId = 61, desc = "FBactivity_share_title12"},		--六星卡牌Max进阶
}
--when user level up king temple, check should share info to facebook
function FacebookShareManager.facebookShareCardEvolusion(card_evolution_shareId,callback)	
	--if not FacebookShareManager.isOpenFacebookShareFunc() then
	--	if callback and type(callback) == "function" then
	--		callback()
	--	end
	--	return true
	--end
	
	if FacebookShareManager.judgeShouldShareFacebook(card_evolution_shareId.shareId) then
		he_log_info("+++++++++++++++++++++++++++pop facebook share messagebox++++++++++++++++++++++++++++++++")
		local shareText = getTextByKey(card_evolution_shareId.desc)
		runningShareText = shareText
		runningShareId = card_evolution_shareId.shareId
		runningCallback = callback
		--临时弹框，分享facebook功能
		--CanonMessageBox:Show(getTextByKey("facebook card evolusion share" .. card_evolution_shareId.shareId), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoShareFacebook, cancelShareFacebook)
		FacebookShareManager.popFacebookTriggerSharePanel(card_evolution_shareId.shareId,shareText,callback)
		return true
	else
		he_log_info("+++++++++++++++++++++++++++not goto facebook share ++++++++++++++++++++++++++++++++")
		if callback and type(callback) == "function" then
			callback()
		end
		return false
	end
end

----
--user beast level up share
local FacebookBeastShareID = {
	[15] = {BEAST_LEVEL_SHAREID = 62},	--神兽15级
	[25] = {BEAST_LEVEL_SHAREID = 63},	--神兽25级
	[35] = {BEAST_LEVEL_SHAREID = 64},	--神兽35级
}
--when user level up beast, check should share info to facebook
function FacebookShareManager.facebookShareBeast(beast_level,callback)	
	if not FacebookShareManager.isOpenFacebookShareFunc() then
		if callback and type(callback) == "function" then
			callback()
		end
		return true
	end
	
	if FacebookBeastShareID[beast_level] == nil then
		return true
	end
	
	local shareId = FacebookBeastShareID[beast_level].BEAST_LEVEL_SHAREID
	if FacebookShareManager.judgeShouldShareFacebook(shareId) then
		he_log_info("+++++++++++++++++++++++++++pop facebook share messagebox++++++++++++++++++++++++++++++++")
		local shareText = getTextByKey("FBactivity_share_title13",{num1 = beast_level})
		runningShareText = shareText
		runningShareId = shareId
		runningCallback = callback
		--临时弹框，分享facebook功能
		--CanonMessageBox:Show(getTextByKey("facebook beast share" .. shareId), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoShareFacebook, cancelShareFacebook)
		FacebookShareManager.popFacebookTriggerSharePanel(shareId,shareText,callback)
		return true
	else
		he_log_info("+++++++++++++++++++++++++++not goto facebook share ++++++++++++++++++++++++++++++++")
		if callback and type(callback) == "function" then
			callback()
		end
		return false
	end
end

--when user get recharge reward, check should share info to facebook
function FacebookShareManager.facebookShareRecharge(callback)	
	if not FacebookShareManager.isOpenFacebookShareFunc() then
		if callback and type(callback) == "function" then
			callback()
		end
		return true
	end

	local shareId = 65
	if FacebookShareManager.judgeShouldShareFacebook(shareId) then
		he_log_info("+++++++++++++++++++++++++++pop facebook share messagebox++++++++++++++++++++++++++++++++")
		local shareText = getTextByKey("FBactivity_share_title14")
		runningShareText = shareText
		runningShareId = shareId
		runningCallback = callback
		--临时弹框，分享facebook功能
		--CanonMessageBox:Show(getTextByKey("facebook get rechare reward share" .. shareId), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoShareFacebook, cancelShareFacebook)
		FacebookShareManager.popFacebookTriggerSharePanel(shareId,shareText,callback)
		return true
	else
		he_log_info("+++++++++++++++++++++++++++not goto facebook share ++++++++++++++++++++++++++++++++")
		if callback and type(callback) == "function" then
			callback()
		end
		return false
	end
end