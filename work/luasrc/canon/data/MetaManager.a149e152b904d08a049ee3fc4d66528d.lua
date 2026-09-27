
MetaManager = {}
MetaManager.game_meta = {} --由GetGameMetaRequest设置
MetaManager.getGameSettingConfig = function() return (MetaManager.game_meta and MetaManager.game_meta.gameSettingConfig) or {} end
MetaManager.getServerPartitionConfig = function() return (MetaManager.game_meta and MetaManager.game_meta.serverPartitionConfig) or {} end
MetaManager.getBattleSettingConfig = function() return (MetaManager.game_meta and MetaManager.game_meta.battleSettingConfig) or {} end
MetaManager.getCardTrainConfig = function() return (MetaManager.game_meta and MetaManager.game_meta.gameSettingConfig.cardTrainConfig) or {} end
MetaManager.getPaymentExchangeConfig = function() return (MetaManager.game_meta and MetaManager.game_meta.paymentExchangeConfig.paymentExchanges) or {} end
MetaManager.prop_meta = require "canon.configs.prop_meta"
MetaManager.battle_country = require "canon.configs.battle_country"
MetaManager.battle_chapter = require "canon.configs.battle_chapter"
MetaManager.battle_mission = require "canon.configs.battle_mission"
MetaManager.battle_chapter_event = require "canon.configs.battle_chapter_event"
MetaManager.battle_monster_group = require "canon.configs.battle_monster_group"
MetaManager.battle_monster = require "canon.configs.battle_monster"
MetaManager.battle_event_battle = require "canon.configs.battle_event_battle"
MetaManager.equip_meta = require "canon.configs.equip_meta"
MetaManager.equip_level = require "canon.configs.equip_level"
MetaManager.equip_evolve_level = require "canon.configs.equip_evolve_level"
MetaManager.equip_suit = require "canon.configs.equip_suit"
MetaManager.equip_evolve = require "canon.configs.equip_evolve"
MetaManager.card_meta = require "canon.configs.card_meta"
MetaManager.card_evolve = require "canon.configs.card_evolve"
MetaManager.card_level = require "canon.configs.card_level"
MetaManager.card_rare = require "canon.configs.card_rare"
MetaManager.skill_meta = require "canon.configs.skill_meta"
MetaManager.skill_status = require "canon.configs.skill_status"
MetaManager.arena_rank_score = require "canon.configs.arena_rank_score"
MetaManager.arena_rank_reward = require "canon.configs.arena_rank_reward"
MetaManager.arena_score_exchange = require "canon.configs.arena_score_exchange"
MetaManager.gacha_card = require "canon.configs.gacha_card"
MetaManager.rp_gacha = require "canon.configs.rp_gacha"
MetaManager.babel_reset_price = require "canon.configs.babel_reset_price"
MetaManager.babel_setting = require "canon.configs.babel_setting"
MetaManager.event_conversation = require "canon.configs.event_conversation"
MetaManager.event_conversation_christmas = require "canon.configs.event_conversation_christmas"
MetaManager.vip_setting = require "canon.configs.vip_setting"
MetaManager.user_level = require "canon.configs.user_level"
MetaManager.expand_inventory = require "canon.configs.expand_inventory"
MetaManager.consecutive_login_reward = require "canon.configs.consecutive_login_reward"
MetaManager.consecutive_login_reward_new = require "canon.configs.consecutive_login_reward_new"MetaManager.elite_setting = require "canon.configs.elite_setting"
MetaManager.cow_stage = require "canon.configs.cow_stage"
MetaManager.prop_relation = require "canon.configs.prop_relation"
MetaManager.reward_package = require "canon.configs.reward_package"
MetaManager.countdown_reward = require "canon.configs.countdown_reward"
MetaManager.system_help = require "canon.configs.system_help"
MetaManager.shop_meta = require "canon.configs.shop_meta"
MetaManager.beast_meta = require "canon.configs.beast_meta"
MetaManager.beast_fragment = require "canon.configs.beast_fragment"
MetaManager.card_monologue = require "canon.configs.card_monologue"
MetaManager.charge_money_reward = require "canon.configs.charge_money_reward"
MetaManager.world_boss_level = require "canon.configs.world_boss_level"
MetaManager.activity_panel = require "canon.configs.activity_panel"
MetaManager.mission_remind = require "canon.configs.mission_remind"
MetaManager.activity_question_bank = require "canon.configs.activity_question_bank"

MetaManager.matrix_level = require "canon.configs.matrix_level"
MetaManager.matrix_grid = require "canon.configs.matrix_grid"
MetaManager.matrix_meta = require "canon.configs.matrix_meta"
MetaManager.item_synthetize = require "canon.configs.item_synthetize"
MetaManager.multiplayer_boss_level = require "canon.configs.multiplayer_boss_level"

MetaManager.sky_tower_monster = require "canon.configs.sky_tower_monster"
MetaManager.sky_tower_reward = require "canon.configs.sky_tower_reward"
MetaManager.sky_tower_buff = require "canon.configs.sky_tower_buff"
MetaManager.sky_tower_level = require "canon.configs.sky_tower_level"
MetaManager.random_number = require "canon.configs.random_number"
MetaManager.random_number = require "canon.configs.random_number"
MetaManager.random_number_table = string.split(MetaManager.random_number[1], ',')

MetaManager.card_fragment_meta = require "canon.configs.card_fragment_meta"
MetaManager.equip_fragment_meta = require "canon.configs.equip_fragment_meta"

MetaManager.activity_pray = require "canon.configs.activity_pray"

MetaManager.union_building_hall = require "canon.configs.union_building_hall"
MetaManager.union_building_shop = require "canon.configs.union_building_shop"
MetaManager.union_shop_normal = require "canon.configs.union_shop_normal"
MetaManager.union_shop_special = require "canon.configs.union_shop_special"
MetaManager.union_building_bank = require "canon.configs.union_building_bank"
MetaManager.activity_contend_fragment = require "canon.configs.activity_contend_fragment"
MetaManager.achievement_task = require "canon.configs.achievement_task"
MetaManager.union_building_colosseum = require "canon.configs.union_building_colosseum"
MetaManager.union_boss_meta = require "canon.configs.union_boss_meta"
MetaManager.card_level = require "canon.configs.card_level"
MetaManager.card_rare = require "canon.configs.card_rare"
MetaManager.spirit_meta = require "canon.configs.spirit_meta"
MetaManager.spirit_level = require "canon.configs.spirit_level"

MetaManager.cross_server_reward = require "canon.configs.cross_server_reward"
MetaManager.union_career = require "canon.configs.union_career"

MetaManager.card_resolve = require "canon.configs.card_resolve"

MetaManager.equip_spirit_value = require "canon.configs.equip_spirit_value"
MetaManager.atlas_Reward = require "canon.configs.atlas_Reward"
MetaManager.card_resolve_setting = require "canon.configs.card_resolve_setting"

MetaManager.treasure_meta = require "canon.configs.treasure_meta"
MetaManager.treasure_suit = require "canon.configs.treasure_suit"
MetaManager.treasure_potential_setting = require "canon.configs.treasure_potential_setting"
MetaManager.treasure_star = require "canon.configs.treasure_star"
MetaManager.treasure_strengthen = require "canon.configs.treasure_strengthen"
MetaManager.treasure_potential_gold = require "canon.configs.treasure_potential_gold"
MetaManager.treasure_potential_ordinary = require "canon.configs.treasure_potential_ordinary"
MetaManager.treasure_potential_silver = require "canon.configs.treasure_potential_silver"

MetaManager.sorted_allCard_meta = {}
MetaManager.sorted_country_wei_card_meta = {}
MetaManager.sorted_country_shu_card_meta = {}
MetaManager.sorted_country_wu_card_meta = {}
MetaManager.sorted_country_qun_card_meta = {}

MetaManager.sorted_allEquip_meta = {}
MetaManager.sorted_weapon_equip_meta = {}
MetaManager.sorted_armor_equip_meta = {}
MetaManager.sorted_horse_equip_meta = {}

MetaManager.currentMetaVersion = 0
MetaManager.currentMaintenanceVersion = 0
MetaManager.currentServerVersion = 0

MetaManager.special_group = {isInit = false} --缘分组
MetaManager.special_group_skill = require "canon.configs.special_group_skill"

--许愿池
MetaManager.activity_fountainwish_fountainmax = require "canon.configs.activity_fountainwish_fountainmax"
MetaManager.activity_fountainwish_gold = require "canon.configs.activity_fountainwish_gold"

function MetaManager.getWorldBossLevelMeta( level )
	for k, v in pairs(MetaManager.world_boss_level) do
		if v.level == level then
		      return v
		end
	end
	return nil
end

-- 获取每次购买回复体力值
function MetaManager.getEnergyGainedByGem()
  local gameSettingConfig = MetaManager.getGameSettingConfig()
  if gameSettingConfig == nil or gameSettingConfig.energyGainedByGem == nil then
    return 0
  else
    return gameSettingConfig.energyGainedByGem
  end
end

-- 获取每次购买回复精力值
function MetaManager.getEventPointGainedByGem()
  local gameSettingConfig = MetaManager.getGameSettingConfig()
  if gameSettingConfig == nil or gameSettingConfig.eventPointGainedByGem == nil then
    return 0
  else
    return gameSettingConfig.eventPointGainedByGem
  end
end

-- 获取帮助信息
function MetaManager.getHelpInfo()
  if not MetaManager.system_help then
    return nil
  end
  
  helpData = {}
  for idx, content in pairs(MetaManager.system_help) do
    data = {}
    contentKeys = {}
    data["id"] = content.id
    data["titleKey"] = content.titleKey
    table.insert(contentKeys, content.contentKey)
    data["contentKeys"] = contentKeys
    table.insert(helpData, data)
  end
  return helpData
end

-- 根据奖励ID获取奖励信息
function MetaManager.getRewardInfoByID(packageId)
  --add by zheng.che @ 2015-1-20
  if SystemManager.debug then
    DebugManager.assert(MetaManager.reward_package[packageId] ~= nil, "没有这个奖励! packageId = " .. tostringRich(packageId))
  end

  if (not MetaManager.reward_package) or (not MetaManager.reward_package[packageId]) then
    return nil
  end
  
  rewardList = {}
  rewardMeta = MetaManager.reward_package[packageId]
  
  -- 生成奖励
  local function geneReward(itemType, metaId, amount)
    local reward = {}
    reward.itemType = itemType
    reward.metaId = metaId
    reward.amount = amount
    return reward
  end
  
  if rewardMeta.content1Type ~= 0 and rewardMeta.content1Amount ~=0 then
    local reward = geneReward(rewardMeta.content1Type, rewardMeta.content1Id, rewardMeta.content1Amount)
    table.insert(rewardList, reward)
  end
  if rewardMeta.content2Type ~= 0 and rewardMeta.content2Amount ~=0 then
    local reward = geneReward(rewardMeta.content2Type, rewardMeta.content2Id, rewardMeta.content2Amount)
    table.insert(rewardList, reward)
  end
  if rewardMeta.content3Type ~= 0 and rewardMeta.content3Amount ~=0 then
    local reward = geneReward(rewardMeta.content3Type, rewardMeta.content3Id, rewardMeta.content3Amount)
    table.insert(rewardList, reward)
  end  
  if rewardMeta.content4Type ~= 0 and rewardMeta.content4Amount ~=0 then
    local reward = geneReward(rewardMeta.content4Type, rewardMeta.content4Id, rewardMeta.content4Amount)
    table.insert(rewardList, reward)
  end
  if rewardMeta.content5Type ~= 0 and rewardMeta.content5Amount ~=0 then
    local reward = geneReward(rewardMeta.content5Type, rewardMeta.content5Id, rewardMeta.content5Amount)
    table.insert(rewardList, reward)
  end
  if rewardMeta.content6Type ~= 0 and rewardMeta.content6Amount ~=0 then
    local reward = geneReward(rewardMeta.content6Type, rewardMeta.content6Id, rewardMeta.content6Amount)
    table.insert(rewardList, reward)
  end
  if rewardMeta.content7Type ~= 0 and rewardMeta.content7Amount ~=0 then
    local reward = geneReward(rewardMeta.content7Type, rewardMeta.content7Id, rewardMeta.content7Amount)
    table.insert(rewardList, reward)
  end
  if rewardMeta.content8Type ~= 0 and rewardMeta.content8Amount ~=0 then
    local reward = geneReward(rewardMeta.content8Type, rewardMeta.content8Id, rewardMeta.content8Amount)
    table.insert(rewardList, reward)
  end  
  if rewardMeta.content9Type ~= 0 and rewardMeta.content9Amount ~=0 then
    local reward = geneReward(rewardMeta.content9Type, rewardMeta.content9Id, rewardMeta.content9Amount)
    table.insert(rewardList, reward)
  end
  if rewardMeta.content10Type ~= 0 and rewardMeta.content10Amount ~=0 then
    local reward = geneReward(rewardMeta.content10Type, rewardMeta.content10Id, rewardMeta.content10Amount)
    table.insert(rewardList, reward)
  end
  
  return rewardList
end

-- filter sorted card data
MetaManager.getSortedCardInfo = function()
    if next(MetaManager.sorted_allCard_meta) == nil then
        local oldCardInfoTable = MetaManager.card_meta
        --filter groupId
        local cardInfoTableGroupByGroupId = {}
    
        for k,v in pairs(oldCardInfoTable) do 
            if cardInfoTableGroupByGroupId[v.cardGroupId] == nil then
                cardInfoTableGroupByGroupId[v.cardGroupId] = {v}
            else
                local hasInsertCard = false
                for ck,cv in pairs(cardInfoTableGroupByGroupId[v.cardGroupId]) do
                    if v.evolutionLevel < cv.evolutionLevel then
                        table.insert(cardInfoTableGroupByGroupId[v.cardGroupId],ck,v)
                        hasInsertCard = true
                        break
                    end 
                end
                if not hasInsertCard then
                    table.insert(cardInfoTableGroupByGroupId[v.cardGroupId],v)
                end 
            end 
        end 
        local tempTable = {}
        for k,v in pairs(cardInfoTableGroupByGroupId) do 
            table.insert(tempTable,v)
        end 
        cardInfoTableGroupByGroupId = tempTable
        local function cardGroupSort(a,b)
            if a[1].rare < b[1].rare then
                return true
            elseif a[1].rare == b[1].rare then
                if a[1].id < b[1].id then
                    return true
                else
                    return false
                end 
            else
                return false
            end
        end
        table.sort(cardInfoTableGroupByGroupId,cardGroupSort)
        MetaManager.sorted_allCard_meta = cardInfoTableGroupByGroupId
    end 
    return MetaManager.sorted_allCard_meta
end 

local function filterSortedCountryCard()
    local allCardTable = MetaManager.getSortedCardInfo()
    for k,v in pairs(allCardTable) do 
        for ck,cv in pairs(v) do 
            if cv.country == 1 then
                --wei
                table.insert(MetaManager.sorted_country_wei_card_meta,cv)
            elseif cv.country == 2 then
                --shu
                table.insert(MetaManager.sorted_country_shu_card_meta,cv)
            elseif cv.country == 3 then
                --wu
                table.insert(MetaManager.sorted_country_wu_card_meta,cv)
            elseif cv.country == 4 then
                --qun
                table.insert(MetaManager.sorted_country_qun_card_meta,cv)
            end 
        end 
    end 
end 
MetaManager.getSortedCountryWeiCardInfo = function()
    if next(MetaManager.sorted_country_wei_card_meta) == nil then
        filterSortedCountryCard()
    end 
    return MetaManager.sorted_country_wei_card_meta
end 

MetaManager.getSortedCountryShuCardInfo = function()
    if next(MetaManager.sorted_country_shu_card_meta) == nil then
        filterSortedCountryCard()
    end 
    return MetaManager.sorted_country_shu_card_meta
end 

MetaManager.getSortedCountryWuCardInfo = function()
    if next(MetaManager.sorted_country_wu_card_meta) == nil then
        filterSortedCountryCard()
    end 
    return MetaManager.sorted_country_wu_card_meta
end 

MetaManager.getSortedCountryQunCardInfo = function()
    if next(MetaManager.sorted_country_qun_card_meta) == nil then
        filterSortedCountryCard()
    end 
    return MetaManager.sorted_country_qun_card_meta
end 

-- filter sorted equip data
MetaManager.getSortedEquipInfo = function()
    if next(MetaManager.sorted_allEquip_meta) == nil then
        local oldEquipInfoTable = MetaManager.equip_meta
        --filter groupId
        local equipInfoTableGroupByPrefixId = {}
    
        for k,v in pairs(oldEquipInfoTable) do 
            if equipInfoTableGroupByPrefixId[v.prefixId] == nil then
                equipInfoTableGroupByPrefixId[v.prefixId] = {v}
            else
                local hasInsertCard = false
                for ck,cv in pairs(equipInfoTableGroupByPrefixId[v.prefixId]) do
                    if v.id < cv.id then
                        table.insert(equipInfoTableGroupByPrefixId[v.prefixId],ck,v)
                        hasInsertCard = true
                        break
                    end 
                end
                if not hasInsertCard then
                    table.insert(equipInfoTableGroupByPrefixId[v.prefixId],v)
                end 
            end 
        end 
        local tempTable = {}
        for k,v in pairs(equipInfoTableGroupByPrefixId) do 
            table.insert(tempTable,v[1])
        end 
        equipInfoTableGroupByPrefixId = tempTable
        local function equipGroupSort(a,b)
            if a.quality < b.quality then
                return true
            elseif a.quality == b.quality then
                if a.id < b.id then
                    return true
                else
                    return false
                end 
            else
                return false
            end
        end
        table.sort(equipInfoTableGroupByPrefixId,equipGroupSort)
        MetaManager.sorted_allEquip_meta = equipInfoTableGroupByPrefixId
    end 
    return MetaManager.sorted_allEquip_meta
end 

local function filterSortedPositionEquip()
    local allEquipTable = MetaManager.getSortedEquipInfo()
    for k,v in pairs(allEquipTable) do 
        if v.country == 1 then
            --weapon
            table.insert(MetaManager.sorted_weapon_equip_meta,v)
        elseif v.country == 2 then
            --armor
            table.insert(MetaManager.sorted_armor_equip_meta,v)
        elseif v.country == 3 then
            --horse
            table.insert(MetaManager.sorted_horse_equip_meta,v)
        end 
    end 
end 
MetaManager.getSortedWeaponEquipInfo = function()
    if next(MetaManager.MetaManager.sorted_weapon_equip_meta) == nil then
        filterSortedPositionEquip()
    end 
    return MetaManager.MetaManager.sorted_weapon_equip_meta
end 

MetaManager.getSortedArmorEquipInfo = function()
    if next(MetaManager.MetaManager.sorted_armor_equip_meta) == nil then
        filterSortedPositionEquip()
    end 
    return MetaManager.MetaManager.sorted_armor_equip_meta
end 

MetaManager.getSortedHorseEquipInfo = function()
    if next(MetaManager.MetaManager.sorted_horse_equip_meta) == nil then
        filterSortedPositionEquip()
    end 
    return MetaManager.MetaManager.sorted_horse_equip_meta
end 

MetaManager.checkMetaInfo = function(metaVersion)
    if not metaVersion then
        return true
    end
    if MetaManager.currentServerVersion == 0 then
        MetaManager.currentServerVersion = metaVersion.server_version
    else
        if MetaManager.currentServerVersion ~= metaVersion.server_version then
            MetaManager.currentServerVersion = metaVersion.server_version
            RequestLoadingBox:removeLoadingBox()
            CanonMessageBox.showText(
                ShowButtonType.ID_OK,
                getTextByKey("loginAgain_txt"),
                nil,
                {
                    text = getTextByKey("yes"),
                    callbackFunc = function()
                        Director:sharedDirector():replaceScene(LoadingScene:create())
                    end
                }
            )
            return false
        end
    end
    for k,v in pairs(metaVersion.methods) do
        if v == "getMeta" then
            MetaManager.currentMetaVersion = metaVersion.meta_version
            MetaManager.currentMaintenanceVersion = metaVersion.maintenance_version
            return true
        end
    end
    if MetaManager.currentMetaVersion == 0 and MetaManager.currentMaintenanceVersion == 0 then
        MetaManager.currentMetaVersion = metaVersion.meta_version
        MetaManager.currentMaintenanceVersion = metaVersion.maintenance_version
    else
        local needRefreshMeta = false
        if MetaManager.currentMetaVersion ~= metaVersion.meta_version then
            needRefreshMeta = true
        end
        if MetaManager.currentMaintenanceVersion ~= metaVersion.maintenance_version and metaVersion.maintenance_version ~= "0.0.0" then
            needRefreshMeta = true
        end
        if needRefreshMeta then
            MetaManager.currentMetaVersion = metaVersion.meta_version
            MetaManager.currentMaintenanceVersion = metaVersion.maintenance_version
            local function GetGameMetaCallBack(e) --游戏信息
                DataManager.GameMetaData = e.data
                DataManager.GameMetaData.cardPictureConfig.cardPictures = HeMemDataHolder:setString("cardPictures", table.serialize(DataManager.GameMetaData.cardPictureConfig.cardPictures))
            end
            --获取游戏配置信息
            local request = GetGameMetaRequest.new( nil, rpc.SendingPriority.kHigh )
            request:addEventListener( RequestNotifyEnum.GetGameMetaSucceed, GetGameMetaCallBack )
            request:start()
        end
    end
    return true
end

----
--获取广告图片资源
----
function MetaManager.getAdPictureConfig()
 return (MetaManager.game_meta and MetaManager.game_meta.adPictureConfig) or {}
end
----
--获取指定广告图片
----
function MetaManager.getAdPictureById(picId)
  local adPictures = MetaManager.getAdPictureConfig().adPictures
  if(not adPictures) then
    return nil
  end
  
  local adPicture = nil
  for _, pic in pairs(adPictures) do
    if(pic.id == picId) then
      adPicture = pic
      break
    end
  end
  
  return adPicture 
end
----
--获取特定类型广告图片资源
----
function MetaManager.getAdPicturesByType(adType)
  local _adType = tostring(adType)
  local adPictures = MetaManager.getAdPictureConfig().adPictures
  if(not adPictures) then
    return {}
  end
  
  local adPics = {}
  for _, pic in pairs(adPictures) do
    if(pic.adType == _adType) then
      table.insert(adPics, pic)
    end
  end
  
  return adPics 
end

function MetaManager.getNewBabelSettings()
	return MetaManager.game_meta.skyTowerSettingConfig
end

function MetaManager.getSpiritSettings()
	return MetaManager.game_meta.spiritSettingConfig
end

local goldSpiritVipLimit = nil
function MetaManager.getGoldSpiritVipLimit()
	if goldSpiritVipLimit == nil then
		local vipSetting = MetaManager.vip_setting
		local vipLimit = 10000
		for k,v in ipairs(vipSetting) do
			if v.extraConcentratePerDay ~= 0 and v.level < vipLimit then
				vipLimit = v.level
			end
		end
		goldSpiritVipLimit = vipLimit
		return vipLimit
	else
		return goldSpiritVipLimit
	end
end

function MetaManager.getSpecialGroupMeta()
    if MetaManager.special_group.isInit == false then
        MetaManager.special_group.isInit = true
        local special_group = require "canon.configs.special_group"
        for k,v in pairs(special_group) do
            for i=1,#v.cardGroupId do
                local cardGroupIds = string.split(v.cardGroupId, '|')
                for m,n in pairs(cardGroupIds) do
                    local aGroupList = v.cardGroupId:split("|")
                    MetaManager.special_group[tonumber(n)] = aGroupList
                end
            end
        end
    end
    return MetaManager.special_group
end



----
--获取圣诞节活动配置表
----
function MetaManager.getMerryChristmasConfig()
 return (MetaManager.game_meta and MetaManager.game_meta.activityEventChristmasConfig) or {}
end


--获取卡牌卡组id by cardId
function MetaManager.getCardGroupIdByCardId(cardId)
	local cardMeta = DataManager.getCardsData()
	for k,v in pairs(cardMeta) do 
		if v.cardId == cardId then
			return MetaManager.getCardGroupIdByCardMetaId(v.metaId)
		end
	end
	--未找到该卡牌
	return -999
end

--获取卡牌卡组id by cardMetaId
function MetaManager.getCardGroupIdByCardMetaId(cardMetaId)
	if MetaManager.card_meta[cardMetaId] then
		return MetaManager.card_meta[cardMetaId].cardGroupId
	else
		--未找到该卡牌
		return -999
	end
end

--获得当前出战阵容的武将（队列）
function MetaManager.getQueueCardInCurBattleArray()
	return CommonManager.getQueueData( )
end

--获得当前出战阵容的武将（队列+阵法）,只输出cardid
function MetaManager.getAllCardInCurBattleArray(matrixId)
	local gameData = DataManager.getGameInitData()
	local curBattleId = gameData.sharkUserExtendMore.battleArrayId
	local queueData = CommonManager.getQueueData( )
	local matricesData = CommonManager:getMatrixCardData()
	
	local cardInCurBattleArray = {}
	--队列武将记录
	for k,v in pairs(queueData) do
		table.insert(cardInCurBattleArray,v)
	end
	--阵法武将记录
	for k,v in pairs(matricesData) do
		table.insert(cardInCurBattleArray,v)
	end
	
	return cardInCurBattleArray
end

--根据卡牌组分捡卡牌，key为卡组id，value为该卡组的卡牌数
function MetaManager.getCardGroupInfoInCurBattleArray(matrixId)
	local cardInCurBattleArray = MetaManager.getAllCardInCurBattleArray(matrixId)
	local cardGroup = {}
	for k,v in pairs(cardInCurBattleArray) do 
		local cardGroupId = MetaManager.getCardGroupIdByCardId(v)
		if cardGroup[cardGroupId] then
			cardGroup[cardGroupId] = cardGroup[cardGroupId] + 1
		else
			cardGroup[cardGroupId] = 1
		end
	end
	return cardGroup
end

--获得当前阵法id
function MetaManager.getCurInBattleMatrixId()
	--当前多阵法没开
	--默认阵法id为10
	return 10
end