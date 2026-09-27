-- TreasureSystem.lua
-- meilan.xie
-- 2015-7-27
-- 宝物系统


--manager

require "canon.features.treasureSystem.manager.TreasureSystemCheck"
require "canon.features.treasureSystem.manager.TreasureSystemConfig"
require "canon.features.treasureSystem.manager.TreasureSystemConsts"
require "canon.features.treasureSystem.manager.TreasureSystemData"
require "canon.features.treasureSystem.manager.TreasureSystemTest"
require "canon.features.treasureSystem.manager.TreasureSystemUtils"

require "canon.features.treasureSystem.manager.TreasureManager"


--request
require "canon.features.treasureSystem.request.SplitTreasureRequest"
require "canon.features.treasureSystem.request.EvolveTreasureRequest"
require "canon.features.treasureSystem.request.LockTreasuresRequest"
require "canon.features.treasureSystem.request.PotentialTreasureRequest"
require "canon.features.treasureSystem.request.ResetTreasurePotentialRequest"
require "canon.features.treasureSystem.request.UpgradeTreasureRequest"

require "canon.features.treasureSystem.request.BuyTreasureGridRequest"
require "canon.features.treasureSystem.request.GachaTreasureRequest"
require "canon.features.treasureSystem.request.SellTreasureRequest"
require "canon.features.treasureSystem.request.SetupTreasureRequest"

--scene
require "canon.features.treasureSystem.scene.TreasureGachaScene"
require "canon.features.treasureSystem.scene.TreasureBackpackScene"

--panel
require "canon.features.treasureSystem.panel.TreasureNewInfoPanel"
require "canon.features.treasureSystem.panel.TreasureInfoPanel"

require "canon.features.treasureSystem.panel.TreasureGachaOnePanel"
require "canon.features.treasureSystem.panel.TreasureGachaTenPanel"
require "canon.features.treasureSystem.panel.TreasurePackageFullPanel"


TreasureSystem = {}

-------------------------------------------------
-- 启动
-------------------------------------------------
function TreasureSystem.startup()
	
end

-------------------------------------------------
-- 清除
-------------------------------------------------
function TreasureSystem.clear()
	
end

-------------------------------------------------
-- 对外接口
-------------------------------------------------

-- 宝物是否存在
function TreasureSystem.enabled()
	return true
end

-------------------------------------------------
-- 跳转
-------------------------------------------------

--弹出宝物详情面板
function TreasureSystem.PopTreasureInfoPanel(evt)
	local self = evt.context.container  
	local treasureIds =  evt.context.treasureId
    local selectnum =  evt.context.SelectNum
    local index = evt.context.NewIndex
    local enterAndReturnScene = evt.context.enterAndReturnScene
	local aInfoPanel = TreasureNewInfoPanel:create(self,treasureIds,selectnum,index,enterAndReturnScene)
    PopoutManager:sharedManager():popout(aInfoPanel, kPopoutDir.kScale, true, false ,self) 
end


--弹出Gacha宝物详情面板
function TreasureSystem.PopTreasureGachaInfoPanel(evt)
	local self = evt.context.container  
	local treasureIds =  evt.context.treasureId
    local aInfoPanel = TreasureInfoPanel:create(self,treasureIds)
    PopoutManager:sharedManager():popout(aInfoPanel, kPopoutDir.kScale, true, false ,self) 
end