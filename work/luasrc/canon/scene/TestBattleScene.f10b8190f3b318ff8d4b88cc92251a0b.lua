require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.scene.BaseUIScene"
require "canon.customUI/CanonCard"
require "canon.request.TriggerBattleRequest"
require "canon.request.localStorage"
require "canon.request.Communication"
require "canon.request.BaseRequest"
require "canon.data.MetaManager"
require "canon.canonUtils"
require "canon.scene.BaseUIScene"
require "canon.scene.BattleConfig"
require "canon.scene.BattleEffect"
require "canon.models.BattleManager"
require "canon.request.GainArenaScoreByRankRequest"
require "canon.customUI.SuspensionLabel"
--require "canon.scene.WorldBossScene"


TestBattleScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function TestBattleScene:create( argv )
    local s = TestBattleScene.new()
    s.argv = argv
    s:initScene()
    return s    
end





function TestBattleScene:onInit()
	BaseUIScene.initBackGround(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/boss.json")
      self.boss2PrepareFight = builder:build("boss2")
	self:addChild(self.boss2PrepareFight)
	
	local txt = TextField:create("战斗中。。。。", "Arial", 30)
	self.boss2PrepareFight:addChild(txt)
	
	local function onFinish()
		local function onGetWorldBossInfo(response)
			WorldBossScene.worldBossInfo = response.data
			WorldBossScene.worldBossInfo.worldBossMonster.totalHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.totalHp)
			WorldBossScene.worldBossInfo.worldBossMonster.leftHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.leftHp)
			Director:sharedDirector():replaceScene(WorldBossScene:create(nil))
		end
		
		local request = GetWorldBossInfoRequest.new(nil, rpc.SendingPriority.kHigh)
		request:addEventListener( RequestNotifyEnum.getWorldBossInfoSuccessd, onGetWorldBossInfo )
		request:start()
	end
	
	local reviveBtn = Button:create( self.boss2PrepareFight:getChildByName("boss_btn_inspire"))
	self.boss2PrepareFight:getChildByName("boss_btn_inspire"):getChildByName("txt"):setString("返回挑战场景")
	reviveBtn:addEventListener( Events.kStart,onFinish ,self)
		
end



