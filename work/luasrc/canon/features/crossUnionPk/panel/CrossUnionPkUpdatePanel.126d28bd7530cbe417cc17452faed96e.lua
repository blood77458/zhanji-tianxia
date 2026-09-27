--
-- CrossUnionPkUpdatePanel.lua
-- geng.men
-- 2015-4-23
-- gvg 军团长或者副军团长上传镜像框
--

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

------------------------------------------------------------------------------------------------------

CrossUnionPkUpdatePanel = class(Layer)

function CrossUnionPkUpdatePanel:ctor()
end

function CrossUnionPkUpdatePanel:create()
	local s = CrossUnionPkUpdatePanel.new()
	s:initLayer()
	return s
end

function CrossUnionPkUpdatePanel:initLayer()
	CrossUnionPkUpdatePanel.super.initLayer(self)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_Gvg_03") 
	self:addChild(self.panelUI)

	local function onRefreshSelf( evt )
		self:close()
		CanonMessageBox.showText(
		        ShowButtonType.ID_OK_CANCEL,
		        getTextByKey("WGVG_Detail09"),
		        {
		            text = getTextByKey("yes"),
		            callbackFunc = function()
		                UploadCrossGvgTeamMirrorRequest.sendRequestDefalut()
		            end
		        }
		    )
	end

	local refreshSelfBtn = Button:create(self.panelUI:getChildByName("btn_2"))
	refreshSelfBtn:addEventListener( Events.kStart, onRefreshSelf, self )

	self.panelUI:getChildByName("btn_2"):getChildByName("btn_light_upyellow"):setVisible(false)
	self.panelUI:getChildByName("btn_1"):getChildByName("btn_light_upyellow"):setVisible(false)

	if CrossUnionPkData.getTeamMirrorRemind() then
		local shineObj = self.panelUI:getChildByName("btn_2"):getChildByName("btn_light_upyellow")
		refreshSelfBtn:setShined(true , shineObj)
	end

	local function onRefreshTeam( evt )
		self:close()
		local function onAfterSucceed(evt)
			UnionManager.eventDispatcher:dispatchEvent(Event.new(CrossUnionPkConsts.NEED_REFRESH_TEAM_ADJUST_SCENE))
		end
		local params = CrossUnionPkData.getUploadTeamParams(false)
		ExchangeGvgFormationRequest.sendRequestDefalut(params ,onAfterSucceed)
		
	end

	local refreshTeamBtn = Button:create(self.panelUI:getChildByName("btn_1"))
	refreshTeamBtn:addEventListener( Events.kStart, onRefreshTeam, self )

	if CrossUnionPkData.getTeamAdjustLightOn() then
		local shineObj = self.panelUI:getChildByName("btn_1"):getChildByName("btn_light_upyellow")
		refreshTeamBtn:setShined(true , shineObj)
	end

	self.panelUI:getChildByName("btn_2"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail07"))
	self.panelUI:getChildByName("btn_1"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail07-2"))

end


function CrossUnionPkUpdatePanel:dispose()
	CrossUnionPkUpdatePanel.super.dispose(self)
end

--关闭对话框
function CrossUnionPkUpdatePanel:close()
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

-------------------------------------------------------------------------------------------------------------
