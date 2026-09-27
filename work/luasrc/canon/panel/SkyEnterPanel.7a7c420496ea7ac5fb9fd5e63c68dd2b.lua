--------------------------------------------------------------------------------
-- SkyEnterPanel.lua
-- author: haoyang.zhuang
-- date: 2013-12-19
--------------------------------------------------------------------------------
require "canon.scene.SkyTowerMainScene"
require "canon.request.GetBabelInfoRequest"
require "canon.data.DataManager"
require "canon.data.MetaManager"
require "canon.customUI.SuspensionLabel"
require "canon.models.EliteManager"
require "canon.customUI.SuspensionLabel"
require "canon.utils.TimeUtil"

SkyEnterPanel = class(Layer)

function SkyEnterPanel:ctor()
end

function SkyEnterPanel:create(container)
  self.container = container

  local panel = SkyEnterPanel.new()
  panel:initLayer()
  return panel
end

function SkyEnterPanel.enable()
  return true
end

----------------------------------------
-- 场景初始化
----------------------------------------
function SkyEnterPanel:initLayer()
  SkyEnterPanel.super.initLayer(self)
  
  local bgSpirte = Sprite:create( "pic/icon_babel_Bg.png" )
  bgSpirte:setAnchorPoint(ccp(0, 0))
  --bgSpirte:setScale(2.0)
  bgSpirte:setPosition(ccp( 0, 119 ))
  self:addChild(bgSpirte)
  
  local builder = LayoutBuilder:createWithContentsOfFile( "scene/sky_tongtianta.json" )
  
  local btnEnterRun = builder:build( "btn/btn_big_enter_run" )
  local txtEnterElite = getTextByKey( "babel_title" )
  btnEnterRun:getChildByName( "font" ):setString( txtEnterElite )
  btnEnterRun:setAnchorPoint(ccp( 0, 1 ))
  btnEnterRun:setPosition(ccp( 166.3, 282.15 ))
  
  local userData = DataManager.getCurrUser()
  
  local function onClickTower(e)
    local function Success(event)
      if event ~= nil then
        DataManager.GetBabelInfoData = event.data
        DataManager.GetBabelInfoData._DownloadDataTime = TimeUtil.getServerTimeSeconds()
      end
      local newScene = SkyTowerMainScene:create()
      newScene:setBackScene( "ChallengeEntersScene" )
      Director:sharedDirector():replaceScene( newScene )
    end
    local function Failed(event)
      if event.data == 713103 then
        SuspensionLabel:showContent(self, Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel}))
      end
    end
    
    if (userData.level >= MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel) then
      local params = {}
      local getBabelInfoRequest = GetBabelInfoRequest.new(params, rpc.SendingPriority.kHigh)
      getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoSucceed, Success)
      getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoFailed, Failed)
      getBabelInfoRequest:start()
    else
      SuspensionLabel:showContent(self, Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel}))
    end
  end
  
  local btn = Button:create( btnEnterRun )
  btn:addEventListener(Events.kStart, onClickTower, self)
  
  self:addChild( btnEnterRun )
end