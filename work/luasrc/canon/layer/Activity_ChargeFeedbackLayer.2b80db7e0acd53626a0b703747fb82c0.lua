require "hecore.display.CocosObject"
require "hecore.display.Director"
require "canon.customUI.CanonGoodIcon"
require "canon.models.PackageModel"
require "canon.customUI.CdLabelComponent"
require "canon.request.GetChargeFeedbackRewardRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_ChargeFeedbackLayer = class(Layer)

function Activity_ChargeFeedbackLayer:ctor()
  self.container = nil
end

function Activity_ChargeFeedbackLayer:create( container , extraArgs)
  self.container = container
  self.extraArgs = extraArgs
  local s = Activity_ChargeFeedbackLayer.new()
  s:initLayer()
  return s
end

function Activity_ChargeFeedbackLayer:enable()

    local isEnable = MaintenanceManager.isActivityOpen("activityChargeFeedback")
    return isEnable
    -- return true
end 

function Activity_ChargeFeedbackLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_ChargeFeedbackLayer:dispose()
	Activity_ChargeFeedbackLayer.super.dispose(self)
end

local function isCurVipMaxLevel(level)--判断VIPLEVEL是否为最大
	local maxLevel = 0
	for k,v in pairs(MetaManager.vip_setting) do
		if maxLevel < v.level then
			maxLevel = v.level
		end
	end
	return level >= maxLevel
end

local function getCurVipInfo()--获取当前VIP等级相关信息
	local info = {}
	info.level = tonumber(DataManager.getCurrUser().vipLevel)
	info.levelupCurGold = tonumber(DataManager.getCurrUser().rechargeGems + DataManager.getCurrUser().vipExp)
	if isCurVipMaxLevel(info.level) then
		info.levelupTotalGold = MetaManager.vip_setting[info.level].requireGold
	else
		info.levelupTotalGold = MetaManager.vip_setting[info.level + 1].requireGold
	end
	return info
end


local box_border_type_arr = {1, 2, 2, 3, 3, 4, 4, 5}
function Activity_ChargeFeedbackLayer:initLayer()
    Activity_ChargeFeedbackLayer.super.initLayer(self)
    -- print("消耗金币"..MetaManager.getGameSettingConfig().secretShopConfig.refreshGoldCost)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("launch_activity11")
	self:addChild(self.mainUI)

	local curRechargeGems = tonumber(DataManager.getCurrUser().rechargeGems)

	self.chargeMeta = DataManager.GameMetaData.activityChargeFeedbackConfig.chargeFeedbackList
	
	for i=1,8 do
		if not self.chargeMeta[i].enable then
			self.mainUI:getChildByName("LA11_item"..i):setVisible(false)
		end
		self.mainUI:getChildByName("LA11_item"..i):getChildByName("btn_getit"):getChildByName("txt"):setString(getTextByKey("activity_claimRewardBtn"))
		self.mainUI:getChildByName("LA11_item"..i):getChildByName("txt_LA11_09"):getChildByName("txt"):setString(self.chargeMeta[i].gold..getTextByKey("activity_chargeReward_rewardTips2"))
		local params = {borderType = box_border_type_arr[i]}
		local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CHARGE_FEEDBACK_BOX_1 - 1 + box_border_type_arr[i], 0, 0, params)
		local picPosX = self.mainUI:getChildByName("LA11_item"..i):getChildByName("normal_card_small"):getPositionX()
		local picPosY = self.mainUI:getChildByName("LA11_item"..i):getChildByName("normal_card_small"):getPositionY()
		local zOrder = self.mainUI:getChildByName("LA11_item"..i):getChildByName("normal_card_small"):getZOrder()
		self.mainUI:getChildByName("LA11_item"..i):getChildByName("normal_card_small"):setVisible(false)
		icon:setPositionXY(picPosX, picPosY)
		icon:setZOrder(zOrder)
		icon:setScale(0.9)
		self.mainUI:getChildByName("LA11_item"..i):addChild(icon)
		local itemName = CanonGoodIcon.getGoodName(self.chargeMeta[i].rewardType1, self.chargeMeta[i].rewardId1, self.chargeMeta[i].rewardNum1, params)
		self.mainUI:getChildByName("LA11_item"..i):getChildByName("txt_LA11_08"):getChildByName("txt"):setString(itemName)

		local function showPackageInfo( evt )
			local selectId = evt.context
			local rewardList = {}
			for i=1,5 do
				if self.chargeMeta[selectId]["rewardType"..i] ~= 0 then
					rewardList[i] = {
					itemType = self.chargeMeta[selectId]["rewardType"..i],
					metaId = self.chargeMeta[selectId]["rewardId"..i],
					amount = self.chargeMeta[selectId]["rewardNum"..i],
					level = 1,
					exp = 0,
				}
				end
			end
			
			local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = rewardList, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle")} )
	        self.container:addChild(aRewardPanel)
	        aRewardPanel:scaleIn()
		end

		local rewardBtn = Button:create(icon)
		rewardBtn:addEventListener(Events.kStart, showPackageInfo , i)
	end

	self.btnsTable = {}

	local function onReward( evt )
		local selectId = evt.context

		if BagCalcManager.isFull() then
	        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
	        NewPackageFullPanel:show()
	        return
	    end

		local function doPlayAfterRewardSucceed( e )
	        -- body
	        local function onGet(  )
	          -- body
	        	RewardManager:getReward(e)
	        end
	        
	        local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = e, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), callback = onGet} )
	        self.container:addChild(aRewardPanel)
	        aRewardPanel:scaleIn()
	    end


		local function chargeFeedbackRewardSucceedResponse( e )
        	doPlayAfterRewardSucceed(e.data.rewards)

        	local gameInit  = DataManager.getGameInitData()
        	table.insert(gameInit.rewardStatus , selectId)
        	DataManager.setGameInitData(gameInit)
        	self:refreshSelf()
        	self.container:resetTipInfoForActivity("Activity_ChargeFeedback")
      	end

      	local function chargeFeedbackRewardFailedResponse( e )
	        if ( e.data == 710516) then
	          	NewPackageFullPanel:show()
	        elseif  e.data == 716915 then  --activity closed
	          local function closeCanonMessageBox()
	          	self.container:replaceScene(MainMenuScene)
	          end
	          local text = Localization:getInstance():getText("activity_error_expired")
	          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	        end
	    end	

		local params = {rewardId = selectId}
 		GetChargeFeedbackRewardRequest.sendRequest(params ,chargeFeedbackRewardSucceedResponse , chargeFeedbackRewardFailedResponse)

	end

	for i=1,8 do
		self.btnsTable[i] = Button:create(self.mainUI:getChildByName("LA11_item"..i):getChildByName("btn_getit") , true)
		self.btnsTable[i]:addEventListener(Events.kStart, onReward , i)
		self.mainUI:getChildByName("LA11_item"..i):getChildByName("lbl_yilingqu"):setVisible(false)
	end

	local limitVip = 1
	for k,v in pairs(self.chargeMeta) do
		if curRechargeGems >= v.gold then
			limitVip = k + 1
		end
	end

	for i=limitVip,#self.chargeMeta do
		self.btnsTable[i]:setEnable(false)
	end

	self:refreshSelf()

	local function isCurVipEndLevel( gold )
		if gold >= self.chargeMeta[#self.chargeMeta].gold then
			return true
		end
		return false
	end

	self.mainUI:getChildByName("txt_LA11_07"):getChildByName("txt"):setColor(ccc3(255,27,27))
	self.mainUI:getChildByName("txt_LA11_07"):getChildByName("txt"):setAroundColor(ccc3(255, 255, 255))
	self.mainUI:getChildByName("txt_LA11_02"):getChildByName("txt"):setColor(ccc3(255,27,27))
	self.mainUI:getChildByName("txt_LA11_02"):getChildByName("txt"):setAroundColor(ccc3(255, 255, 255))
	self.mainUI:getChildByName("txt_LA11_05"):getChildByName("txt"):setColor(ccc3(1,139,7))
	self.mainUI:getChildByName("txt_LA11_05"):getChildByName("txt"):setAroundColor(ccc3(255, 255, 255))

	self.mainUI:getChildByName("btn_top_up_go"):getChildByName("txt"):setAroundColor(ccc3(128, 49, 6))

	local vipInfo = getCurVipInfo()
	if isCurVipEndLevel(curRechargeGems) then
		self.mainUI:getChildByName("txt_LA11_11"):getChildByName("txt"):setString(getTextByKey("activity_repay_max"))
		self.mainUI:getChildByName("txt_LA11_05"):getChildByName("txt"):setVisible(false)
		self.mainUI:getChildByName("txt_LA11_02"):getChildByName("txt"):setVisible(false)
		self.mainUI:getChildByName("txt_LA11_03"):getChildByName("txt"):setVisible(false)
		self.mainUI:getChildByName("txt_LA11_01"):getChildByName("txt"):setVisible(false)
		self.mainUI:getChildByName("txt_LA11_04"):getChildByName("txt"):setVisible(false)
	else
		self.mainUI:getChildByName("txt_LA11_05"):getChildByName("txt"):setString(self.chargeMeta[limitVip].gold - curRechargeGems)
		self.mainUI:getChildByName("txt_LA11_02"):getChildByName("txt"):setString(self.chargeMeta[limitVip].gold)
		self.mainUI:getChildByName("txt_LA11_03"):getChildByName("txt"):setString(getTextByKey("activity_repay_txt2"))
		self.mainUI:getChildByName("txt_LA11_01"):getChildByName("txt"):setString(getTextByKey("activity_repay_txt1"))
		self.mainUI:getChildByName("txt_LA11_04"):getChildByName("txt"):setString(getTextByKey("activity_repay_txt3"))
		self.mainUI:getChildByName("txt_LA11_11"):getChildByName("txt"):setVisible(false)
	end

	local startAndEndTime = MaintenanceManager:getStartAndEndTime("activityChargeFeedback")
	local monthEnd = startAndEndTime[2].month
	local dayEnd = startAndEndTime[2].day
	local monthStart = startAndEndTime[1].month
	local dayStart = startAndEndTime[1].day

	local endTimeStr = Localization:getInstance():getText("activity_repay_time2" , {month1 = monthStart , day1 = dayStart,month2 = monthEnd , day2 = dayEnd})

	self.mainUI:getChildByName("txt_LA11_06"):getChildByName("txt"):setString(getTextByKey("activity_repay_time1"))
	self.mainUI:getChildByName("txt_LA11_07"):getChildByName("txt"):setString(endTimeStr)
	
	local function gotoShopScene( )
		self.container:replaceScene(ShopScene , {enterScene="ActivityPanelScene",returnScene="ActivityPanelScene",selectPanelName="Activity_ChargeFeedback", params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
	end

	local btnGo = Button:create(self.mainUI:getChildByName("btn_top_up_go"))
	btnGo:addEventListener(Events.kStart, gotoShopScene)
	self.mainUI:getChildByName("btn_top_up_go"):getChildByName("txt"):setString(getTextByKey("activity_repay_recharge"))

end

function Activity_ChargeFeedbackLayer:refreshSelf()
	local rewardedList = DataManager.getGameInitData().rewardStatus
	-- local rewardedList = {}
	for k,v in pairs(rewardedList) do
		self.mainUI:getChildByName("LA11_item"..v):getChildByName("btn_getit"):getChildByName("txt"):setString(getTextByKey("achieve_task_got"))
		self.btnsTable[v]:setEnable(false)
		self.btnsTable[v]:setVisible(false)
		self.mainUI:getChildByName("LA11_item"..v):getChildByName("lbl_yilingqu"):setVisible(true)
	end
end

function Activity_ChargeFeedbackLayer.getTipNum()
  if not Activity_ChargeFeedbackLayer.enable() then
    return 0
  end
  local rewardedList = DataManager.getGameInitData().rewardStatus
  -- local rewardedList = {}
  local chargeMeta = DataManager.GameMetaData.activityChargeFeedbackConfig.chargeFeedbackList
  local curRechargeGems = tonumber(DataManager.getCurrUser().rechargeGems)
  local rewardEnableNum = 0
  for k,v in pairs(chargeMeta) do
  	if curRechargeGems >= v.gold then
  		rewardEnableNum = rewardEnableNum + 1
  	end
  end
  if rewardEnableNum - #rewardedList > 0 then
  	return 1
  else
  	return 0
  end
end