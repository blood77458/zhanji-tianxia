--------------------------------------------------------------------------------
-- EliteEnterPanel.lua - 玩家信息界面:队列、留言、切磋、删除好友
-- author: xiaojie.bai
-- date: 2013-09-30 11:50
--------------------------------------------------------------------------------

require "canon.models.EliteManager"
require "canon.scene.EliteMissionScene"

require "canon.customUI.SuspensionLabel"

EliteEnterPanel = class(Layer)

function EliteEnterPanel:ctor()
end

function EliteEnterPanel:create(container)
  self.container = container

  local panel = EliteEnterPanel.new()
  panel:initLayer()
  return panel
end

function EliteEnterPanel.enable()
  return true
end

----------------------------------------
-- 场景初始化
----------------------------------------
function EliteEnterPanel:initLayer()
  EliteEnterPanel.super.initLayer(self)
  
  local bgSpirte = Sprite:create(EliteManager.DICT.PIC_ATTACKON)
  bgSpirte:setAnchorPoint(ccp(0, 0))
  bgSpirte:setPosition(ccp( EliteManager.DICT.PIC_ATTACKON_POSX, EliteManager.DICT.PIC_ATTACKON_POSY ))
  self:addChild(bgSpirte)
  
  local builder = LayoutBuilder:createWithContentsOfFile(EliteManager.DICT.RESOURCE_FILE)
  self.panelUI = builder:build("elite_attackon")
  
  local btnEnterElite = self.panelUI:getChildByName("elite_btn_attacking_on")
  local txtEnterElite = getTextByKey("elite_title")
  btnEnterElite:getChildByName("font"):setString(txtEnterElite)
  
  local btn = Button:create(btnEnterElite)
  local function onEnterElite()
    if(EliteManager.isUnlockElite()) then
      self.container:replaceScene(EliteMissionScene)
    else
      local stageName = EliteManager.getFuncUnlockStageName()
      local aContent = getTextByKey("elite_unlockTips", {stageName = stageName})
      SuspensionLabel:showContent(self.container, aContent)
    end
  end
  btn:addEventListener(Events.kStart, onEnterElite, self)
  
  self:addChild(self.panelUI)
end