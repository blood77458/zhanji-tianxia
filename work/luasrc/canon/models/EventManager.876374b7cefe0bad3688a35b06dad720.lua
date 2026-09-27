require "canon.models.ArenaManager"
require "canon.features.crossArena.manager.CrossArenaManager"
require "canon.features.treasureSystem.manager.TreasureManager"
--
-- EventManager
--

local broadcast_help_max_index = 10
local system_broadcast_cache_max = 20
local activity_broadcast_cache_max = 20
local gold_god_boradcast_num = 3

EventManager = class()
local eventManagerInstance = nil
function EventManager:sharedManager()
	if not eventManagerInstance then
		eventManagerInstance = EventManager.new()
	end
	return eventManagerInstance
end

function EventManager:ctor(  )
  self:initializeData()
end

function EventManager:initializeData()
  self.systemBoardcastList = {}
  self.gachaBroadcastList = {}
  self.currentBroadcastHelpIndex = 0
  self.activityBroadcastList = {}
  self.treasureGachaBroadcastList = {}
end

function EventManager:addEvent(aEvent)
  if SystemManager.debug then
    print("new event: " .. table.tostring(aEvent))
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~广播广播广播")
  end
  if aEvent.endpoint == "arenaBroadcastEvent" then
    ArenaManager:sharedManager():receiveNewReport(aEvent.data)
  elseif aEvent.endpoint == "levelUpEvent" then
    CanonLevelUpEventReady = true
    print("CanonLevelUpEventReady is ready")
    if(not CanonLevelUpEventTimes or CanonLevelUpEventTimes <= 0) then
      CanonLevelUpEventTimes = 1
    else 
      CanonLevelUpEventTimes = CanonLevelUpEventTimes + 1
    end
    print("CanonLevelUpEventReady is ready", CanonLevelUpEventTimes)
  elseif aEvent.endpoint == "systemBroadcastEvent" then
    table.insert(self.systemBoardcastList, aEvent.data)
    if #self.systemBoardcastList > system_broadcast_cache_max then
      table.remove(self.systemBoardcastList, 1)
    end
  elseif aEvent.endpoint == "gachaBroadcastEvent" then
    if aEvent.data.type == 34 then
      self:InsertTreasureGachaBroadcast( aEvent.data )
    else
      self:InsertOneGachaBroadcast( aEvent.data )
    end
  elseif aEvent.endpoint == "activityBroadcastEvent" then
    table.insert(self.activityBroadcastList, aEvent.data)
    if #self.activityBroadcastList > activity_broadcast_cache_max then
      table.remove(self.activityBroadcastList, 1)
    end
  elseif aEvent.endpoint == "fightCapacityChangeEvent" then
    --更新战斗力 仅仅是数值变更 此时不影响显示
    local newFightCapacity = math.floor(aEvent.data.fightCapacity)
    DataManager.setRealFightCapacity(newFightCapacity)
  elseif aEvent.endpoint == "crossPvpBroadcastEvent" then
    CrossArenaManager.receiveNewReport(aEvent.data)
  end
end

function EventManager:getGoldGodActivityBroadcast()
  --print(table.tostring(self.activityBroadcastList))
  local result = {}
  local flag = 0
  for i = #self.activityBroadcastList, 1, -1 do
    local aActivityBroadcast = self.activityBroadcastList[i]
    if aActivityBroadcast.type == 15 then
      flag = flag + 1
      table.insert(result, aActivityBroadcast)
      if flag >= gold_god_boradcast_num then
        break
      end
    end
  end
  return result
end

function EventManager:getThreeGachaBroadcast()
  if self.gachaBroadcastList == nil then
    self.gachaBroadcastList = {}
  end
  
  local ThreeBroadcast = {}
  local CurNum = #self.gachaBroadcastList
--  print( CurNum )
  
  if CurNum > 0 then
    ThreeBroadcast[1] = self.gachaBroadcastList[CurNum]
  else
    ThreeBroadcast[1] = ""
  end
  
  CurNum = CurNum - 1
  if CurNum > 0 then
    ThreeBroadcast[2] = self.gachaBroadcastList[CurNum]
  else
    ThreeBroadcast[2] = ""
  end
  
  CurNum = CurNum - 1
  if CurNum > 0 then
    ThreeBroadcast[3] = self.gachaBroadcastList[CurNum]
  else
    ThreeBroadcast[3] = ""
  end
  
  CurNum = #self.gachaBroadcastList
  if CurNum > 10 then
    local New_gachaBroadcastList = {}
    New_gachaBroadcastList[3] = self.gachaBroadcastList[CurNum]
    New_gachaBroadcastList[2] = self.gachaBroadcastList[CurNum-1]
    New_gachaBroadcastList[1] = self.gachaBroadcastList[CurNum-2]
    self.gachaBroadcastList = New_gachaBroadcastList
  end
  
  return ThreeBroadcast
end

function EventManager:InsertOneGachaBroadcast( Data1 )
  if self.gachaBroadcastList == nil then
    self.gachaBroadcastList = {}
  end
  
--  print( "Insert One GachaBroadcast:" .. Data1.content )
  
  local CurNum = #self.gachaBroadcastList
  local _json = require("cjson")
  local cardMetaId = _json.decode(Data1.content).cardMetaId
  local cardName = Localization:getInstance():getText(MetaManager.card_meta[cardMetaId].name)
  self.gachaBroadcastList[CurNum+1] = Localization:getInstance():getText("gacha_broadcast", {player = Data1.userName, cardname = cardName})
end

function EventManager:getTreasureGachaBroadcast()
  if self.treasureGachaBroadcastList == nil then
    self.treasureGachaBroadcastList = {}
  end
  
  local SevenBroadcast = {}
  local CurNum = #self.treasureGachaBroadcastList

  for i = 1,7 do
    if (CurNum - i + 1 > 0) then
      SevenBroadcast[i] = self.treasureGachaBroadcastList[CurNum - i + 1]
    else
      SevenBroadcast[i] = ""
    end
  end

  CurNum = #self.treasureGachaBroadcastList
  if CurNum > 14 then
    local New_gachaBroadcastList = {}
    for i = 1,7 do
      New_gachaBroadcastList[i] = self.treasureGachaBroadcastList[CurNum - 7 + i]
    end
    self.treasureGachaBroadcastList = New_gachaBroadcastList
  end
  
  return SevenBroadcast
end

function EventManager:InsertTreasureGachaBroadcast( Data1 ) --todo
  if self.treasureGachaBroadcastList == nil then
    self.treasureGachaBroadcastList = {}
  end
  
--  print( "Insert One GachaBroadcast:" .. Data1.content )
  
  local CurNum = #self.treasureGachaBroadcastList
  local name1 = Data1.userName
  local _json = require("cjson")
  local treasureMetaId = _json.decode(Data1.content).itemMetaId
  local name2 = TreasureManager.getTreasureNameByMeta(treasureMetaId)  
  self.treasureGachaBroadcastList[CurNum+1] = Localization:getInstance():getText("Treasure_Notice", {name1 = name1, name2 = name2})
end

function EventManager:getOneSystemBoardcast()
  local result
  -- print("~~~~~~~~~~~~~~~~~测试1 ")
  if #self.systemBoardcastList ~= 0 then
    local _json = require("cjson")
    local aReport = table.remove(self.systemBoardcastList, 1)
    -- print("~~~~~~~~~~~~~~~~~测试2 ")
    if aReport == nil then
      return
    end

    if aReport.type == 5 then
      local cardMetaId = _json.decode(aReport.content).cardMetaId
      local cardName = Localization:getInstance():getText(MetaManager.card_meta[cardMetaId].name)
      result = Localization:getInstance():getText("broadcast_gacha", {player = aReport.userName, cardname = cardName})
    elseif aReport.type == 6 then
      local aContentList = _json.decode(aReport.content)
      local giftMetaId = aContentList.giftMetaId
      local itemType = aContentList.itemType
      local itemMetaId = _json.decode(aReport.content).itemMetaId
      local giftName = Localization:getInstance():getText(MetaManager.prop_meta[giftMetaId].name)
      local itemName
      if itemType == ResourceEnum.EQUIP then
        itemName = Localization:getInstance():getText(MetaManager.equip_meta[itemMetaId].name)
      elseif itemType == ResourceEnum.PROP then
        itemName = Localization:getInstance():getText(MetaManager.prop_meta[itemMetaId].name)
      end
      result = Localization:getInstance():getText("broadcast_chest", {player = aReport.userName, chestname = giftName, itemname = itemName})
    elseif aReport.type == 7 then
      local cardMetaId = _json.decode(aReport.content).cardMetaId
      local cardName = Localization:getInstance():getText(MetaManager.card_meta[cardMetaId].name)
      local cardEvolvedMetaId = MetaManager.card_meta[cardMetaId].evolutionCardId
      local cardEvolvedName = Localization:getInstance():getText(MetaManager.card_meta[cardEvolvedMetaId].name)
      result = Localization:getInstance():getText("broadcast_cardEvolve", {player = aReport.userName, cardname1 = cardName, cardname2 = cardEvolvedName})
    elseif aReport.type == 8 then
      local equipMetaId = _json.decode(aReport.content).equipMetaId
      local equipName = Localization:getInstance():getText(MetaManager.equip_meta[equipMetaId].name)
      local equipEvolvedMetaId = MetaManager.equip_evolve[equipMetaId].evolvedEquipId
      local equipEvolvedName = Localization:getInstance():getText(MetaManager.equip_meta[equipEvolvedMetaId].name)
      result = Localization:getInstance():getText("broadcast_equipEvolve", {player = aReport.userName, equipname1 = equipName, equipname2 = equipEvolvedName})
    elseif aReport.type == 9 then
      local aContentList = _json.decode(aReport.content)
      local cardMetaId = aContentList.cardMetaId
      local skillMetaId = aContentList.skillMetaId
      local cardName = Localization:getInstance():getText(MetaManager.card_meta[cardMetaId].name)
      local skilltype = MetaManager.skill_meta[skillMetaId].skillType
      local skilltypeName
      if skilltype == 1 then
        skilltypeName = Localization:getInstance():getText("cardInfo_Skill")
      elseif skilltype == 2 then
        skilltypeName = Localization:getInstance():getText("cardInfo_MainSkill")
      end
      local skillname = Localization:getInstance():getText(MetaManager.skill_meta[skillMetaId].name)
      result = Localization:getInstance():getText("broadcast_skillMax", {player = aReport.userName, cardname = cardName, skilltype = skilltypeName, skillname = skillname})
    elseif aReport.type == 10 then
      result = Localization:getInstance():getText("broadcast_babelTop", {player = aReport.userName})
    elseif aReport.type == 12 then
      local aContentList = _json.decode(aReport.content)
      local rank1 = aContentList.topRank
      local rank2 = aContentList.nowRank
      result = Localization:getInstance():getText("broadcast_arenaRankTop", {player = aReport.userName, rank1 = rank1, rank2 = rank2})
    elseif aReport.type == 11 then
      local enemyUserName = _json.decode(aReport.content).enemyName
      result = Localization:getInstance():getText("broadcast_arenaChampion", {player1 = aReport.userName, player2 = enemyUserName})
    elseif aReport.type == 16 then
       --宿命对决
      local round = _json.decode(aReport.content).round
      result = Localization:getInstance():getText("broadcast_destinyBattle_clear", {player = aReport.userName, num = round})
    elseif aReport.type == 17 then
      --凝神
      local concentrateId = _json.decode(aReport.content).concentrateId
      local spiritMetaData = MetaManager.spirit_meta[concentrateId]
      local spiritName = getTextByKey(spiritMetaData.nameKey)
      result = Localization:getInstance():getText("broadcast_spiritConcentrate_rare", {player = aReport.userName, spirit = spiritName})
    elseif aReport.type == 18 then
      local aContentList = _json.decode(aReport.content)
      local serverId = aContentList.serverId
      result = Localization:getInstance():getText("cross_text_quanju", {num1 = serverId, num2 = aReport.userName, serverId = serverId, num3 = serverId})
    elseif aReport.type == 19 then
      result = Localization:getInstance():getText("activity_dailyCharge_announcement1", {name = aReport.userName})
    elseif aReport.type == 20 then
      local aContentList = _json.decode(aReport.content)
      local tampDays = aContentList.days
      result = Localization:getInstance():getText("activity_dailyCharge_announcement2", {name = aReport.userName, days = tampDays})
    elseif aReport.type == 21 then
      local aContentList = _json.decode(aReport.content)
      local cityId = aContentList.cityId
      local unionName = aContentList.unionName
      local cityName = UnionPkUtils.getCityNameById(tonumber(cityId))
      result = Localization:getInstance():getText("UnionWar_attend_text", {num1 = unionName, num2 = cityName})
    elseif aReport.type == 22 then
      result = Localization:getInstance():getText("balloon_broadcast1", {player = aReport.userName})
    elseif aReport.type == 23 then
      result = Localization:getInstance():getText("balloon_broadcast2", {player = aReport.userName})
    elseif aReport.type == 24 then--装备附灵达到一定条件
      local aContentList = _json.decode(aReport.content)
      local cityId = aContentList.cityId
      local equipMetaId = aContentList.equipMetaId
      local equipName = Localization:getInstance():getText(MetaManager.equip_meta[equipMetaId].name)
      local enchantLevel = aContentList.enchantLevel
      result = Localization:getInstance():getText("enchant_13", {name = aReport.userName, equipmentname = equipName, level = enchantLevel})--{name}借天地之灵气，日月之精华，成功将{equipmentname}附灵到了{level}！
    elseif aReport.type == 25 then
      local aContentList = _json.decode(aReport.content)
      local name1 = aReport.userName
      local name2 = ""
      if aContentList.bossType == 2 then
        name2 = getTextByKey("crossBoss_typeAwaken")
      elseif aContentList.bossType == 3 then
        name2 = getTextByKey("crossBoss_typeRampage")
      end
      
      result = Localization:getInstance():getText("crossBoss_broadcastInfo_1", {name1 = name1, name2 = name2})
    elseif aReport.type == 26 then
      local aContentList = _json.decode(aReport.content)
      local name1 = ""
      local name2 = aReport.userName
      if aContentList.bossType == 2 then
        name1 = getTextByKey("crossBoss_awakenBoss")
      elseif aContentList.bossType == 3 then
        name1 = getTextByKey("crossBoss_rampageBoss")
      end
       
      result = Localization:getInstance():getText("crossBoss_broadcastInfo_2", {name1 = name1, name2 = name2})
	  elseif aReport.type == 27 then
  	  local aContentList = _json.decode(aReport.content)
         
      result = Localization:getInstance():getText("activity_rankin1Anounce", {player = aReport.userName, num = aContentList.serverId})
    elseif aReport.type == 28 then
      local aContentList = _json.decode(aReport.content)
      local id1 = aContentList.winnerServerId
      local name1 = aReport.userName
      local id2 = aContentList.loserServerId
      local name2 = aContentList.loserName

      result = Localization:getInstance():getText("crossArena_talk1", {num1 = id1, num2 = name1, num3 = id2, num4 = name2})
    elseif aReport.type == 31 then
      local aContentList = _json.decode(aReport.content)
      -- print("~~~~~~~~~~~~~~~~~type31 = "..tostringRich(aContentList))
      -- print("~~~~~~~~~~~~~~~~~~~aContentList.unionName1 = "..tostringRich(aContentList.unionName1))
      local Name1 = aContentList.unionName1
      local Name2 = aContentList.unionName2
      local Name3 = aContentList.unionName3
      local Name4 = aContentList.unionName4

      result = Localization:getInstance():getText("WGVG_Call01", {name1 = Name1, name2 = Name2, name3 = Name3, name4 = Name4})
    elseif aReport.type == 32 then
      local aContentList = _json.decode(aReport.content)
      -- print("~~~~~~~~~~~~~~~~~type32 = "..tostringRich(aContentList))
      local TextName = nil
      
      if aContentList.rank == 1 then
        TextName = "WGVG_Call02"
      elseif aContentList.rank == 2 then
        TextName = "WGVG_Call03"
      elseif aContentList.rank == 3 then
        TextName = "WGVG_Call04"
      end
        
      result = Localization:getInstance():getText(TextName, {name = aContentList.unionName ,name1 = serverId })
    elseif aReport.type == 33 then
      
      local aContentList = _json.decode(aReport.content)
      -- print("~~~~~~~~~~~~~~~~~type33 = "..tostringRich(aContentList))
      local Winnername = aContentList.winnerName

      result = Localization:getInstance():getText("WGVG_Call05", {name = Winnername})
    elseif aReport.type == 35 then
      print("~~~~~~~~~~~~~~~~~type34 = "..tostringRich(aReport))
      local aContentList = _json.decode(aReport.content)
      local name1 = aReport.userName
      local name2 = TreasureManager.getTreasureNameByMeta( aContentList.treasureMetaId )
      if aContentList.treasureRare == 5 then
        result = Localization:getInstance():getText("Treasure_gacha_6", {name1 = name1 , name2 = name2})
      else
        result = Localization:getInstance():getText("Treasure_gacha_7", {name1 = name1 , name2 = name2})
      end
    end
  else
    -- print("~~~~~~~~~~~~~~~~~~测试3")
    self.currentBroadcastHelpIndex = self.currentBroadcastHelpIndex + 1
    if self.currentBroadcastHelpIndex > broadcast_help_max_index then
      self.currentBroadcastHelpIndex = 1
    end
    result = Localization:getInstance():getText(string.format("broadcast_help%d", self.currentBroadcastHelpIndex))
  end
  return result
end