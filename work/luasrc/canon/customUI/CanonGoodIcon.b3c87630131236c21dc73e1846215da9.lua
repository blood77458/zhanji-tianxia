--
-- CanonGoodIcon.lua
-- Author: zheng.che
-- Date: 2014-03-04 15:17:14
-- 用于显示各种不同类型物品的icon
--

CanonGoodIcon = class()

--无卡牌的默认图像
CanonGoodIcon.CARD_NONE = "CARD_NONE"
--添加卡牌图标
CanonGoodIcon.CARD_ADD = "CARD_ADD"
--军团图标
CanonGoodIcon.UNION = "UNION"
--卡牌半身像
CanonGoodIcon.CARD_HALF = "CARD_HALF"

------------------------------------------------------------------------------------------------
-- 通过礼包id 获得其中第一个id物品icon

-- packageRewardId 礼包id int
-- params 见下文

-- return icon元件
------------------------------------------------------------------------------------------------
function CanonGoodIcon.createFirstGoodIconByPackageReward(packageRewardId, params)
	local packageRewardInfo = CanonGoodIcon.getRewardInfo(packageRewardId)
	return CanonGoodIcon.createGoodIconByPackageRewardInfo(packageRewardInfo, params)
end

------------------------------------------------------------------------------------------------
-- 通过礼包单元 获得将要显示的物品icon

-- packageRewardInfo 礼包奖励单元 table
-- params 见下文

-- return icon元件
------------------------------------------------------------------------------------------------
function CanonGoodIcon.createGoodIconByPackageRewardInfo(packageRewardInfo, params)
	return CanonGoodIcon.createGoodIcon(packageRewardInfo.itemType, packageRewardInfo.metaId, packageRewardInfo.amount, params)
end

------------------------------------------------------------------------------------------------
-- 通过物品类型 物品metaId 和额外参数 获得将要显示的物品icon

-- goodType 物品类型 int
-- metaId 物品metaId int
-- amount 物品数量 int
-- params 可选参数 table 可以传nil, 具体见↓

-- params.isCalendar 道具和装备用 作用不清楚 boolean
-- params.isShowStar 是否显示装备的稀有度 boolean
-- params.sourceDisplay 用于替换的美术资源 提供位置 宽高等信息 displayObject(可以是cc版本)
-- params.positions icon的位置 如果有sourceDisplay了就不用传 {x, y}
-- params.sourceSizes icon的宽高 如果有sourceDisplay了就不用传 {width, heigth}
-- params.scales icon的横竖比例 如果有sourceDisplay了就不用传 {width, heigth}
-- params.container icon需要存入的容器 displayObject(可以是cc版本)
-- params.zindex icon存入容器后的层级 int
-- params.showInCenter 是否居中显示 需要有sourceDisplay才有效 boolean
-- params.showAmount 是否显示物品数量
-- params.AmountPosX 物品数量x坐标
-- params.AmountPosY 物品数量y坐标
-- params.notShowCardStar 不显示卡牌星级 

-- return icon元件
------------------------------------------------------------------------------------------------
function CanonGoodIcon.createGoodIcon(goodType, metaId, amount, params) 
	--goodType = 2 --test
	-- print("createGoodIcon(goodType, metaId, amount) : " .. tostringRich({goodType, metaId, amount}))
	if not params then
		params = {}
	end

	local icon
	local border


	if goodType == ResourceEnum.COIN then
		icon = CanonItem:create()
		image = Sprite:create("common/CoinIcon_Mission.png")
		border = Sprite:create("Item/border/equipBorder1.png")
		border:setScale(144/155)
		icon:addChild(image)
		icon:addChild(border)
	elseif goodType == ResourceEnum.GEMS then
		icon = CanonItem:create()
		image = Sprite:create("common/GemIcon_Mission.png")
		border = Sprite:create("Item/border/equipBorder1.png")
		border:setScale(144/155)
		icon:addChild(image)
		icon:addChild(border)
	-- elseif goodType == ResourceEnum.ENERGY then
	-- elseif goodType == ResourceEnum.EXP then
	elseif goodType == ResourceEnum.CARD then
		if params.notShowCardStar then --是否显示星星
			icon = getHeadIconNoStarCanonCardByMetaId(metaId)
		else
			icon = getHeadIconCanonCardByMetaId(metaId)
		end
		--icon = getHeadIconCanonCardByMetaId(metaId)
	elseif goodType == ResourceEnum.EQUIP then
		icon = CanonItem:create()
		icon:loadByMetaId(metaId, params.isCalendar, params.isShowStar)
	elseif goodType == ResourceEnum.PROP then
		icon = CanonItem:create()
		icon:loadByMetaId(metaId, params.isCalendar, false)
	elseif goodType == ResourceEnum.SPIRIT then
		icon = CanonItem:create()
		icon:loadByMetaId(metaId, params.isCalendar, false)
    icon:setScale(0.83)
	-- elseif goodType == ResourceEnum.FRIENDPOINT then
	-- elseif goodType == ResourceEnum.GRID then
	-- elseif goodType == ResourceEnum.SKILLPOINTS then
	-- elseif goodType == ResourceEnum.EVENTPOINT then
	-- elseif goodType == ResourceEnum.ARENASCORE then
	-- elseif goodType == ResourceEnum.BEAST then
	elseif goodType == ResourceEnum.TREASURE then
		icon = CanonItem:create()
		icon:loadByMetaId(metaId, params.isCalendar, params.isShowStar)
	elseif goodType == ResourceEnum.BEAST_FRAGMENT then
		icon = CanonItem:create()
		local fragmentSprite = Sprite:create("#" .. MetaManager.beast_fragment[metaId].icon .. ".png")
		--fragmentSprite:setScale(130 / fragmentSprite:getContentSize().width)
		icon:addChild(fragmentSprite)
	-- elseif goodType == ResourceEnum.GACHA_POINT then
	elseif goodType == ResourceEnum.CARD_FRAGMENT then
		local cardMetaId = MetaManager.card_fragment_meta[metaId].cardId
		icon = getHeadIconNoStarCanonCardByMetaId(cardMetaId)
		local aSmallIcon = Sprite:create("Item/Picture/Prop_soul.png")
		aSmallIcon:setPosition( ccp(37, 47) )
		icon:addChild(aSmallIcon)
	elseif goodType == ResourceEnum.EQUIP_FRAGMENT then
		local equipMetaId = MetaManager.equip_fragment_meta[metaId].equipId
		icon = CanonItem:create()
		icon:loadByMetaId(equipMetaId)
		local aSmallIcon = Sprite:create("Item/Picture/Prop_soul_item.png")
		aSmallIcon:setPosition( ccp(37, 47) )
		icon:addChild(aSmallIcon)
	elseif goodType == ResourceEnum.RP_VALUE then
		icon = CanonItem:create()
		image = Sprite:create("common/icon_luck.png")
		border = Sprite:create("Item/border/equipBorder7.png")
		border:setScale(144/155)
		icon:addChild(image)
		icon:addChild(border)
	elseif goodType == ResourceEnum.ASTRALESSENCE then -- 星灵
		icon = CanonItem:create()
		image = Sprite:create("Item/Picture/Prop_xingling0.png")
		border = Sprite:create("Item/border/equipBorder1.png")
		border:setScale(144/155)
		icon:addChild(image)
		icon:addChild(border)
	elseif goodType == ResourceEnum.GENERALEXP then -- 武将经验
		icon = CanonItem:create()
		image = Sprite:create("common/icon_cardExp.png")
		border = Sprite:create("Item/border/equipBorder1.png")
		border:setScale(144/155)
		icon:addChild(image)
		icon:addChild(border)
  	elseif goodType == ResourceEnum.VIP_EXP then
		icon = CanonItem:create()
		image = Sprite:create("common/vip.png")
		border = Sprite:create("Item/border/equipBorder1.png")
		border:setScale(144/155)
		icon:addChild(image)
		icon:addChild(border)
	elseif goodType == ResourceEnum.UNION_CONTRIBUTION then
		icon = CanonItem:create()
		image = Sprite:create("common/JunTuanGongXian_Mission.png")
		border = Sprite:create("Item/border/equipBorder1.png")
		border:setScale(144/155)
		icon:addChild(image)
		icon:addChild(border)
	elseif goodType == CanonGoodIcon.CARD_NONE then
		--特殊情况 没有卡牌的默认图像
		icon = CanonItem:create()
		image = Sprite:create("ui_res/guild_pk/icon_illu.png")
		icon:addChild(image)
	elseif goodType == CanonGoodIcon.CARD_ADD then
		--特殊情况 添加卡牌加号icon
		icon = CanonItem:create()
		image = Sprite:create("common/icon_add_card.png")
		icon:addChild(image)
	elseif goodType == ResourceEnum.ENCHANT_POINT then
		--特殊情况 添加装备灵值icon
		icon = CanonItem:create()
		image = Sprite:create("Item/Picture/Porp_lingzhi0.png")
		icon:addChild(image)
	elseif goodType == CanonGoodIcon.UNION then
		--特殊情况 军团icon
		icon = CanonItem:create()
		image = Sprite:create("common/icon_union.png")
		icon:addChild(image)
	elseif goodType == CanonGoodIcon.CARD_HALF then
		icon = CanonItem:create()
		local image = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(metaId))
		image:setAnchorPoint(ccp(0.5, 0))
		icon:addChild(image)
	elseif goodType == ResourceEnum.TREASURE_FRAGMENT then--宝物碎片
		icon = CanonItem:create()
		image = Sprite:create("Item/Picture/Prop_TreasureCrystal0.png")
		border = Sprite:create("Item/border/equipBorder1.png")
		border:setScale(144/155)
		icon:addChild(image)
		icon:addChild(border)
	elseif (goodType >= ResourceEnum.CHARGE_FEEDBACK_BOX_1) and (goodType <= ResourceEnum.CHARGE_FEEDBACK_BOX_5) then
		icon = CanonItem:create()
		image = Sprite:create("common/box" .. (params.borderType) .. ".png")
		border = Sprite:create("Item/border/equipBorder" .. (params.borderType) .. ".png")
		border:setScale(144/155)
	    icon:addChild(image)
		icon:addChild(border)
	elseif (goodType == ResourceEnum.MEDAL) then
		icon = CanonItem:create()
		image = Sprite:create("common/icon_medal.png")
		border = Sprite:create("Item/border/equipBorder5.png")
		border:setScale(144/155)
	    icon:addChild(image)
		icon:addChild(border)
	elseif (goodType == ResourceEnum.MysteriousCoins) then
		icon = CanonItem:create()
		local temp = {
		"Prop_longlinshi0",
		"Prop_huchishi0",
		"Prop_xueyushi0",
		"Prop_xuanjiashi0",
		"Prop_mijingzhiyanshi0",
	}
		image = Sprite:create("Item/Picture/"..temp[metaId]..".png")
		border = Sprite:create("Item/border/equipBorder5.png")
		-- border:setScale(144/155)
	    icon:addChild(image)
		icon:addChild(border)
	end

	if icon then

		if params.sourceDisplay then
			params.positions = {params.sourceDisplay:getPositionX(), params.sourceDisplay:getPositionY()}
		end
		if params.positions then
			icon:setPosition(ccp(params.positions[1], params.positions[2]))
		end

		if params.sourceDisplay then
			params.sourceSizes = {}
			if params.sourceDisplay.getGroupBounds then
				table.insert(params.sourceSizes, params.sourceDisplay:getGroupBounds(params.sourceDisplay:getParent()).size.width )
				table.insert(params.sourceSizes, params.sourceDisplay:getGroupBounds(params.sourceDisplay:getParent()).size.height )
			else
				table.insert(params.sourceSizes, HeDisplayUtil:getNodeGroupBounds(params.sourceDisplay, params.sourceDisplay:getParent(), kHitAreaObjectTag).size.width )
				table.insert(params.sourceSizes, HeDisplayUtil:getNodeGroupBounds(params.sourceDisplay, params.sourceDisplay:getParent(), kHitAreaObjectTag).size.height )
			end
		end
		if params.sourceSizes and not params.scales then
			params.scales = {}
			table.insert(params.scales, params.sourceSizes[1] / icon:getGroupBounds().size.width)
			table.insert(params.scales, params.sourceSizes[2] / icon:getGroupBounds().size.height)
		end
		if params.scales then
			icon:setScaleX(params.scales[1])
			icon:setScaleY(params.scales[2])
		end

		if params.sourceDisplay and params.showInCenter then
			icon:setPositionX(params.sourceDisplay:getPositionX() + params.sourceSizes[1]/2)
			icon:setPositionY(params.sourceDisplay:getPositionY() - params.sourceSizes[2]/2)
		end

		if params.container then
			if params.zindex then
				if params.container.refCocosObj then
					params.container:addChildAt(icon, params.zindex)
				else
					params.container:addChild(icon.refCocosObj, params.zindex)
				end
			else
				if params.container.refCocosObj then
					params.container:addChild(icon)
				else
					params.container:addChild(icon.refCocosObj)
				end
			end
		end
	end
	
	if params.showAmount and amount and amount > 0 then
		local amountLabel = CCLabelTTF:create("x" .. amount,"Arial", 30)
		local amountPosX = 85
		local amountPosY = -53
		
		if params.AmountPosX then
			amountPosX = params.AmountPosX
		end
		
		if params.AmountPosY then
			amountPosY = params.AmountPosY
		end
		amountLabel:setPosition(ccp(amountPosX,amountPosY))
		icon:addChild(CocosObject.new(amountLabel))
	end

	return icon
end

--------------------------------------------------------------------------------------------------------------------------------------------------物品名称

------------------------------------------------------------------------------------------------
-- 通过礼包id 获得所有物品的名称

-- rewardPackageId 礼包id int
-- params 见下文

-- return 物品名称x数量[,物品名称x数量][,物品名称x数量]...
------------------------------------------------------------------------------------------------
function CanonGoodIcon.getGoodNamesByPackageReward(rewardPackageId, params)
	local packageRewardList = MetaManager.getRewardInfoByID(rewardPackageId) or {}
	--print("packageRewardList = " .. table.tostring(packageRewardList))
	local result = ""
	for k, v in ipairs(packageRewardList) do
		local packageRewardInfo = v
		local nameStr = CanonGoodIcon.getGoodNameByPackageRewardInfo(packageRewardInfo, params)

		if k ~= 1 then
			result = result .. Localization:getInstance():getText("union_dynamic_content_Symbol1")--，
		end
		result = result .. nameStr
	end
	--print("result = " .. result)
	return result
end

------------------------------------------------------------------------------------------------
-- 通过礼包id 获得其中第一个id物品的名称

-- packageRewardId 礼包id int
-- params 见下文

-- return 物品名称x数量
------------------------------------------------------------------------------------------------
function CanonGoodIcon.getFirstGoodNameByPackageReward(packageRewardId, params)
	local packageRewardInfo = CanonGoodIcon.getRewardInfo(packageRewardId)
	return CanonGoodIcon.getGoodNameByPackageRewardInfo(packageRewardInfo, params)
end

------------------------------------------------------------------------------------------------
-- 通过礼包单元 获得将要显示的物品icon

-- packageRewardInfo 礼包奖励单元 table
-- params 见下文

-- return 物品名称x数量
------------------------------------------------------------------------------------------------
function CanonGoodIcon.getGoodNameByPackageRewardInfo(packageRewardInfo, params)
	return CanonGoodIcon.getGoodName(packageRewardInfo.itemType, packageRewardInfo.metaId, packageRewardInfo.amount, params)
end

------------------------------------------------------------------------------------------------
-- 通过物品数据得到物品的显示名称

-- goodType 物品类型 int
-- metaId 物品metaId int
-- amount 物品数量 int
-- params 可选参数 table 可以传nil, 具体见↓

-- params.withoutAmount 是否!不!需要显示数量 boolean
-- params.mutiMark 显示数量时间隔的乘号自定义文本 不填默认为小写x string
-- params.limitShowAmount 是否只显示数值型资源的数量 boolean

-- return 物品名称x数量
------------------------------------------------------------------------------------------------
function CanonGoodIcon.getGoodName(goodType, metaId, amount, params)
	local result = ""
	if not params then
		params = {}
	end

	--params.limitShowAmount 为true情况下 是否显示数量
	local useNum = false

	if goodType == ResourceEnum.COIN then
		result = Localization:getInstance():getText("resource_silverCoin")
		useNum = true--数值型
	elseif goodType == ResourceEnum.GEMS then
		result = Localization:getInstance():getText("resource_goldCoin")
		useNum = true--数值型
	-- elseif goodType == ResourceEnum.ENERGY then
	-- elseif goodType == ResourceEnum.EXP then
	elseif goodType == ResourceEnum.CARD then
		local meta = MetaManager.card_meta[metaId]
		if SystemManager.debug then
			DebugManager.assert(meta ~= nil, "CanonGoodIcon 无此卡牌配置! metaId = " .. tostringRich(metaId))
		end
		result = Localization:getInstance():getText(meta.name) 
	elseif goodType == ResourceEnum.EQUIP then
		local meta = MetaManager.equip_meta[metaId]
		if SystemManager.debug then
			DebugManager.assert(meta ~= nil, "CanonGoodIcon 无此装备配置! metaId = " .. tostringRich(metaId))
		end
		result = Localization:getInstance():getText(meta.name)
	elseif goodType == ResourceEnum.PROP then
		local meta = MetaManager.prop_meta[metaId]
		if SystemManager.debug then
			DebugManager.assert(meta ~= nil, "CanonGoodIcon 无此道具配置! metaId = " .. tostringRich(metaId))
		end
		result = Localization:getInstance():getText(meta.name)
	elseif goodType == ResourceEnum.TREASURE then
		local meta = MetaManager.treasure_meta[metaId]
		if SystemManager.debug then
			DebugManager.assert(meta ~= nil, "CanonGoodIcon 无此道具配置! metaId = " .. tostringRich(metaId))
		end
		result = Localization:getInstance():getText(meta.name)
	-- elseif goodType == ResourceEnum.FRIENDPOINT then
	-- elseif goodType == ResourceEnum.GRID then
	-- elseif goodType == ResourceEnum.SKILLPOINTS then
	-- elseif goodType == ResourceEnum.EVENTPOINT then
	-- elseif goodType == ResourceEnum.ARENASCORE then
	-- elseif goodType == ResourceEnum.BEAST then
	elseif goodType == ResourceEnum.BEAST_FRAGMENT then
		local beastId = math.fmod(math.modf(metaId / 100, 10), 1000)
	    local aFragmentMetaConfig = MetaManager.beast_meta[beastId]
	    local fragmentList = aFragmentMetaConfig.attrs.beastFragmentId:split("|")
	    local fragmentIndex
        for k, v in ipairs(fragmentList) do
            local fragmentFormat = tostring(metaId)
            if v == fragmentFormat then
                fragmentIndex = k
                break
            end
        end
        result = Localization:getInstance():getText(aFragmentMetaConfig.attrs.beastNameKey) .. Localization:getInstance():getText(string.format("beastFragment_%d", fragmentIndex))
	-- elseif goodType == ResourceEnum.GACHA_POINT then
	elseif goodType == ResourceEnum.CARD_FRAGMENT then
		local cardMetaId = MetaManager.card_fragment_meta[metaId].cardId
		result = Localization:getInstance():getText(MetaManager.card_meta[cardMetaId].name) .. Localization:getInstance():getText("fragment_cardTab")
	elseif goodType == ResourceEnum.EQUIP_FRAGMENT then
		local equipMetaId = MetaManager.equip_fragment_meta[metaId].equipId
		result = Localization:getInstance():getText(MetaManager.equip_meta[equipMetaId].name) .. Localization:getInstance():getText("fragment_equipTab")
	elseif goodType == ResourceEnum.RP_VALUE then
		result = Localization:getInstance():getText("gacha_rpNum")
	elseif goodType == ResourceEnum.ASTRALESSENCE then -- 星灵
		result = Localization:getInstance():getText("item_astralEssence")
		useNum = true--数值型
	elseif goodType == ResourceEnum.GENERALEXP then -- 武将经验
		result = Localization:getInstance():getText("item_cardExp")
		useNum = true--数值型
	elseif goodType == ResourceEnum.SPIRIT then -- 武将经验
		result = Localization:getInstance():getText(MetaManager.spirit_meta[metaId].nameKey)
		useNum = true--数值型
	elseif goodType == ResourceEnum.UNION_CONTRIBUTION then -- 军团贡献
		result = Localization:getInstance():getText("UnionWar_attend_prop")
		useNum = true--数值型
	elseif goodType == ResourceEnum.ENCHANT_POINT then
		result = Localization:getInstance():getText("sacrifice_text3")
		useNum = true--数值型
	elseif goodType == ResourceEnum.MEDAL then
		result = Localization:getInstance():getText("activity_daily_shopicon1")
		useNum = true
	elseif (goodType == ResourceEnum.MysteriousCoins) then
		result = Localization:getInstance():getText("Mysterious_text"..metaId)
		useNum = false
	end

	if params.limitShowAmount then
		if useNum then
			if params.mutiMark then
				result = result..params.mutiMark..amount
			else
				result = result.."x"..amount
			end
		end
	elseif not params.withoutAmount then
		if params.mutiMark then
			result = result..params.mutiMark..amount
		else
			result = result.."x"..amount
		end
	end

	return result
end

------------------------------------------------------------------------------------------------
-- 通过物品数据得到物品的显示名称 不显示数量

-- goodType 物品类型 int
-- metaId 物品metaId int

-- return 物品名称
------------------------------------------------------------------------------------------------
function CanonGoodIcon.getGoodNameWithoutNum(goodType, metaId)
	return CanonGoodIcon.getGoodName(goodType, metaId, 1, {withoutAmount = true})
end

------------------------------------------------------------------------------------------------
-- 通过物品数据得到物品的显示名称 不显示数量

-- rewards 奖励列表 table 至少包含{itemType = xxx, metaId = xxx, amount = xxx}
-- sepStr 名字之间的间隔符 string 默认半角空格
-- params 显示物品名称所用的参数 table 默认显示数量

-- return 物品名称<间隔符>物品名称...
------------------------------------------------------------------------------------------------
function CanonGoodIcon.getGoodNamesStrByRewards(rewards, sepStr, params)
	if not params then
		params = {}
	end
	if not sepStr then
		sepStr = " "
	end

	local nameList = {}
	for i, reward in ipairs(rewards) do
		local name = CanonGoodIcon.getGoodName(reward.itemType, reward.metaId, reward.amount, params)
		table.insert(nameList, name)
	end

	return table.join(nameList, sepStr)
end

--------------------------------------------------------------------------------------------------------------------------------------------------查询数量

------------------------------------------------------------------------------------------------
--查询资源类物品的当前数值
------------------------------------------------------------------------------------------------
function CanonGoodIcon.getResourceNum(goodType)
	local GameData = DataManager.getGameInitData()

	local result = 0
	if goodType == ResourceEnum.COIN then
		result = tonumber(GameData.sharkUser.coins)
	elseif goodType == ResourceEnum.GEMS then
		result = CalculationManager.calcComplex_getGemsNow()
	elseif goodType == ResourceEnum.ENERGY then
	elseif goodType == ResourceEnum.EXP then
	-- elseif goodType == ResourceEnum.CARD then
	-- elseif goodType == ResourceEnum.EQUIP then
	-- elseif goodType == ResourceEnum.PROP then
	elseif goodType == ResourceEnum.FRIENDPOINT then
	elseif goodType == ResourceEnum.GRID then
	elseif goodType == ResourceEnum.SKILLPOINTS then
	elseif goodType == ResourceEnum.EVENTPOINT then
	elseif goodType == ResourceEnum.ARENASCORE then
	elseif goodType == ResourceEnum.BEAST then
	elseif goodType == ResourceEnum.BEAST_FRAGMENT then
	elseif goodType == ResourceEnum.GACHA_POINT then
	-- elseif goodType == ResourceEnum.CARD_FRAGMENT then
	-- elseif goodType == ResourceEnum.EQUIP_FRAGMENT then
	elseif goodType == ResourceEnum.RP_VALUE then
	elseif goodType == ResourceEnum.GENERALEXP then
		result = GameData.sharkUserExtend.generalExp
	elseif goodType == ResourceEnum.ASTRALESSENCE then
		return GameData.sharkUserExtend.astralEssence
	end

	return result
end

------------------------------------------------------------------------------------------------------------------------------------------------其他接口函数

--查询物品稀有度配置数值
function CanonGoodIcon.getGoodRare(goodType, metaId)
	-- print("goodType = " .. tostringRich(goodType))
	-- print("metaId = " .. tostringRich(metaId))
	local result = 0
	-- if goodType == ResourceEnum.COIN then
	-- elseif goodType == ResourceEnum.GEMS then
	-- elseif goodType == ResourceEnum.ENERGY then
	-- elseif goodType == ResourceEnum.EXP then
	if goodType == ResourceEnum.CARD then
		local meta = MetaManager.card_meta[metaId]
		result = meta.rare
	elseif goodType == ResourceEnum.EQUIP then
		local meta = MetaManager.equip_meta[metaId]
		result = meta.quality
	elseif goodType == ResourceEnum.PROP then
		local meta = MetaManager.prop_meta[metaId]
		result = meta.quality
	-- elseif goodType == ResourceEnum.FRIENDPOINT then
	-- elseif goodType == ResourceEnum.GRID then
	-- elseif goodType == ResourceEnum.SKILLPOINTS then
	-- elseif goodType == ResourceEnum.EVENTPOINT then
	-- elseif goodType == ResourceEnum.ARENASCORE then
	-- elseif goodType == ResourceEnum.BEAST then
	-- elseif goodType == ResourceEnum.BEAST_FRAGMENT then
	-- elseif goodType == ResourceEnum.GACHA_POINT then
	elseif goodType == ResourceEnum.CARD_FRAGMENT then
		local cardMetaId = MetaManager.card_fragment_meta[metaId].cardId
		result = CanonGoodIcon.getGoodRare(ResourceEnum.CARD, cardMetaId)
	elseif goodType == ResourceEnum.EQUIP_FRAGMENT then
		local equipMetaId = MetaManager.equip_fragment_meta[metaId].equipId
		result = CanonGoodIcon.getGoodRare(ResourceEnum.EQUIP, equipMetaId)
	-- elseif goodType == ResourceEnum.RP_VALUE then
	end

	return result
end

--查询物品卖出价格
function CanonGoodIcon.getGoodSellPrice(goodType, goodData)
	-- print("goodType = " .. tostringRich(goodType))
	-- print("goodData = " .. tostringRich(goodData))
	local result = 0
	-- if goodType == ResourceEnum.COIN then
	-- elseif goodType == ResourceEnum.GEMS then
	-- elseif goodType == ResourceEnum.ENERGY then
	-- elseif goodType == ResourceEnum.EXP then
	-- if goodType == ResourceEnum.CARD then
	if goodType == ResourceEnum.EQUIP then
		result = MetaManager.equip_meta[goodData.metaId].sellPriceCoe * MetaManager.equip_level[goodData.level].sellPriceBase
	-- elseif goodType == ResourceEnum.PROP then
	-- elseif goodType == ResourceEnum.FRIENDPOINT then
	-- elseif goodType == ResourceEnum.GRID then
	-- elseif goodType == ResourceEnum.SKILLPOINTS then
	-- elseif goodType == ResourceEnum.EVENTPOINT then
	-- elseif goodType == ResourceEnum.ARENASCORE then
	-- elseif goodType == ResourceEnum.BEAST then
	-- elseif goodType == ResourceEnum.BEAST_FRAGMENT then
	-- elseif goodType == ResourceEnum.GACHA_POINT then
	-- elseif goodType == ResourceEnum.CARD_FRAGMENT then
	-- elseif goodType == ResourceEnum.EQUIP_FRAGMENT then
	-- elseif goodType == ResourceEnum.RP_VALUE then
	end

	return result
end

--查询物品的metaID
function CanonGoodIcon.getGoodMetaIdByData(goodType, goodData)
	local result = 0
	-- if goodType == ResourceEnum.COIN then
	-- elseif goodType == ResourceEnum.GEMS then
	-- elseif goodType == ResourceEnum.ENERGY then
	-- elseif goodType == ResourceEnum.EXP then
	-- if goodType == ResourceEnum.CARD then
	if goodType == ResourceEnum.EQUIP then
		result = goodData.metaId
	-- elseif goodType == ResourceEnum.PROP then
	-- elseif goodType == ResourceEnum.FRIENDPOINT then
	-- elseif goodType == ResourceEnum.GRID then
	-- elseif goodType == ResourceEnum.SKILLPOINTS then
	-- elseif goodType == ResourceEnum.EVENTPOINT then
	-- elseif goodType == ResourceEnum.ARENASCORE then
	-- elseif goodType == ResourceEnum.BEAST then
	-- elseif goodType == ResourceEnum.BEAST_FRAGMENT then
	-- elseif goodType == ResourceEnum.GACHA_POINT then
	-- elseif goodType == ResourceEnum.CARD_FRAGMENT then
	-- elseif goodType == ResourceEnum.EQUIP_FRAGMENT then
	-- elseif goodType == ResourceEnum.RP_VALUE then
	end

	return result
end

--查询物品的物品id
function CanonGoodIcon.getGoodIdByData(goodType, goodData)
	local result = 0
	-- if goodType == ResourceEnum.COIN then
	-- elseif goodType == ResourceEnum.GEMS then
	-- elseif goodType == ResourceEnum.ENERGY then
	-- elseif goodType == ResourceEnum.EXP then
	-- if goodType == ResourceEnum.CARD then
	if goodType == ResourceEnum.EQUIP then
		result = goodData.equipId
	-- elseif goodType == ResourceEnum.PROP then
	-- elseif goodType == ResourceEnum.FRIENDPOINT then
	-- elseif goodType == ResourceEnum.GRID then
	-- elseif goodType == ResourceEnum.SKILLPOINTS then
	-- elseif goodType == ResourceEnum.EVENTPOINT then
	-- elseif goodType == ResourceEnum.ARENASCORE then
	-- elseif goodType == ResourceEnum.BEAST then
	-- elseif goodType == ResourceEnum.BEAST_FRAGMENT then
	-- elseif goodType == ResourceEnum.GACHA_POINT then
	-- elseif goodType == ResourceEnum.CARD_FRAGMENT then
	-- elseif goodType == ResourceEnum.EQUIP_FRAGMENT then
	-- elseif goodType == ResourceEnum.RP_VALUE then
	end

	return result
end

--查询物品是否正在使用中
function CanonGoodIcon.getGoodIsInUseByData(goodType, goodData)
	local result = false
	-- if goodType == ResourceEnum.COIN then
	-- elseif goodType == ResourceEnum.GEMS then
	-- elseif goodType == ResourceEnum.ENERGY then
	-- elseif goodType == ResourceEnum.EXP then
	-- if goodType == ResourceEnum.CARD then
	if goodType == ResourceEnum.EQUIP then
		result = goodData.cardId > 0
	-- elseif goodType == ResourceEnum.PROP then
	-- elseif goodType == ResourceEnum.FRIENDPOINT then
	-- elseif goodType == ResourceEnum.GRID then
	-- elseif goodType == ResourceEnum.SKILLPOINTS then
	-- elseif goodType == ResourceEnum.EVENTPOINT then
	-- elseif goodType == ResourceEnum.ARENASCORE then
	-- elseif goodType == ResourceEnum.BEAST then
	-- elseif goodType == ResourceEnum.BEAST_FRAGMENT then
	-- elseif goodType == ResourceEnum.GACHA_POINT then
	-- elseif goodType == ResourceEnum.CARD_FRAGMENT then
	-- elseif goodType == ResourceEnum.EQUIP_FRAGMENT then
	-- elseif goodType == ResourceEnum.RP_VALUE then
	end

	return result
end

------------------------------------------------------------------------------------------------
--查询某物品是否是资源类型(否则是道具类)
------------------------------------------------------------------------------------------------
function CanonGoodIcon.isResource(goodType)
	if goodType == ResourceEnum.COIN then
	-- elseif goodType == ResourceEnum.GEMS then
	-- elseif goodType == ResourceEnum.ENERGY then
	-- elseif goodType == ResourceEnum.EXP then
	elseif goodType == ResourceEnum.CARD then
		return false
	elseif goodType == ResourceEnum.EQUIP then
		return false
	elseif goodType == ResourceEnum.PROP then
		return false
	-- elseif goodType == ResourceEnum.FRIENDPOINT then
	-- elseif goodType == ResourceEnum.GRID then
	-- elseif goodType == ResourceEnum.SKILLPOINTS then
	-- elseif goodType == ResourceEnum.EVENTPOINT then
	-- elseif goodType == ResourceEnum.ARENASCORE then
	-- elseif goodType == ResourceEnum.BEAST then
	-- elseif goodType == ResourceEnum.BEAST_FRAGMENT then
	-- elseif goodType == ResourceEnum.GACHA_POINT then
	-- elseif goodType == ResourceEnum.CARD_FRAGMENT then
	-- elseif goodType == ResourceEnum.EQUIP_FRAGMENT then
	-- elseif goodType == ResourceEnum.RP_VALUE then
	-- elseif goodType == ResourceEnum.GENERALEXP then
	-- elseif goodType == ResourceEnum.ASTRALESSENCE then
	end

	return true
end

------------------------------------------------------------------------------------------------------------------------------------------------显示其他内容

-- 显示星数
-- containerDisplay 要显示星星的容器 根据数量不同自动居中 (注意: 如果里面有内容 会被自动销毁)
-- starNum 显示星星的数量
-- w 星星宽
-- h 星星高
-- gapW 横向间距
function CanonGoodIcon.setStarIcon(containerDisplay, starNum, w, h, gapW)
	if not containerDisplay then
		return 
	end
	if not starNum then
		starNum = 0
	end
	if not w then
		w = 34
	end
	if not h then
		h = 33
	end
	if not gapW then
		gapW = 0
	end

	for i = #containerDisplay.list, 1, -1 do
		--清空容器
		local v = containerDisplay.list[i]
		v:removeFromParentAndCleanup(true)
	end

	local totalWidth = (starNum-1)*gapW + starNum*w

	for i = 1, starNum, 1 do
		local spt = CCSprite:createWithSpriteFrameName("card_xing.png")
		spt:setAnchorPoint(ccp(0, 1))
		spt:setPosition(ccp((i-1)*(w+gapW) - totalWidth/2, h/2))

		local starDisplay = CocosObject.new(spt)
		local scaleX = w / starDisplay:getGroupBounds().size.width
		local scaleY = h / starDisplay:getGroupBounds().size.height
		starDisplay:setScaleX(scaleX)
		starDisplay:setScaleY(scaleY)

		containerDisplay:addChild(starDisplay)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------其他接口

--弹出物品详情二级
function CanonGoodIcon.popoutGoodPanel(goodType, metaId)
	local scene = Director:mgr():run()

	local result = 0
	-- if goodType == ResourceEnum.COIN then
	-- elseif goodType == ResourceEnum.GEMS then
	-- elseif goodType == ResourceEnum.ENERGY then
	-- elseif goodType == ResourceEnum.EXP then
	if goodType == ResourceEnum.CARD then
		--第一个参数应该是nil而不是0 表示无cardId 否则函数内部会试图寻找id为0的卡牌数据 找不到就报错 modified by zheng.che @ 2014-11-20
		local aCard = generateCard(nil, metaId, 1, tonumber(0))
		scene.targetInfoPanel = GachaCardInfoPanel:create(scene, aCard)
		PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, false, false, scene)
	elseif goodType == ResourceEnum.EQUIP then
		local aEquip = generateEquip(0, metaId, 1, tonumber(0))
		scene._data = aEquip
		scene.targetInfoPanel = EquipInfoPanelNoBtn:create( scene , "BackpackScene")
		PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false, scene)
	elseif goodType == ResourceEnum.PROP then
		local aProp = {
			metaId = metaId,
			amount = tonumber(-1),--默认不显示数量
		}
		scene._data = aProp
		scene.targetInfoPanel = PropInfoPanel:create( scene , true)
		PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false ,scene)
	-- elseif goodType == ResourceEnum.FRIENDPOINT then
	-- elseif goodType == ResourceEnum.GRID then
	-- elseif goodType == ResourceEnum.SKILLPOINTS then
	-- elseif goodType == ResourceEnum.EVENTPOINT then
	-- elseif goodType == ResourceEnum.ARENASCORE then
	-- elseif goodType == ResourceEnum.BEAST then
	-- elseif goodType == ResourceEnum.BEAST_FRAGMENT then
	-- elseif goodType == ResourceEnum.GACHA_POINT then
	elseif goodType == ResourceEnum.CARD_FRAGMENT then
		--第一个参数应该是nil而不是0 表示无cardId 否则函数内部会试图寻找id为0的卡牌数据 找不到就报错 modified by zheng.che @ 2014-11-20
		local aCard = generateCard(nil, MetaManager.card_fragment_meta[metaId].cardId, 1, tonumber(0))
		local cardPanel = GachaCardInfoPanel:create(scene, aCard)
		PopoutManager:sharedManager():popout(cardPanel, kPopoutDir.kScale, false, false, scene)
	elseif goodType == ResourceEnum.EQUIP_FRAGMENT then
		local aEquip = generateEquip(0, MetaManager.equip_fragment_meta[metaId].equipId, 1, tonumber(0))
		scene._data = aEquip
		scene.targetInfoPanel = EquipInfoPanelNoBtn:create( scene , "BackpackScene")
		PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false, scene)
	elseif goodType == ResourceEnum.SPIRIT then
		local aProp = {
			metaId = metaId,
		}
		scene._data = aProp
	    scene.targetInfoPanel = SpiritInfoPanelNoBtn:create( scene )
	    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false ,scene)
	-- elseif goodType == ResourceEnum.RP_VALUE then
	end
end

--格式化资源数值 超出5位显示w
function CanonGoodIcon.formatResourceNumStr(num)
	if num >= 100000 then
		return Localization:getInstance():getText("activity_seckill_money", {num1 = math.floor(num / 10000)})--{num1}w
	end
	return num
end

--格式化不能超过最大值的数字
function CanonGoodIcon.formatNumByMax(num, maxNum)
	if num >= maxNum then
		return maxNum
	end
	return num
end

------------------------------------------------------------------------------------------------------------------------------------------------自用函数

--通过礼包id获得奖励物品的信息
function CanonGoodIcon.getRewardInfo(rewardPackageId)
  local packageRewardList = MetaManager.getRewardInfoByID(rewardPackageId)
  if SystemManager.debug then
  	DebugManager.assert(packageRewardList[1] ~= nil, "这个奖励内容为空! rewardPackageId = " .. tostringRich(rewardPackageId))
  end
  return packageRewardList[1]
end

function CanonGoodIcon.getCardNameWithoutEvolutionLevel( cardMetaId )
	local aCardMeta = MetaManager.card_meta[cardMetaId]
    local cardGroup = aCardMeta.cardGroupId
    local nameKey 
    for _, card in pairs(MetaManager.card_meta) do
      if (card.evolutionLevel == 1) and (card.cardGroupId == cardGroup) then
        nameKey = MetaManager.card_meta[card.id].name
        break
      end
    end
    return getTextByKey(nameKey)
end

-- 获取物品描述
function CanonGoodIcon.getGoodDescribe(goodType,metaId)
	local result = ""
	if goodType == ResourceEnum.COIN then
		result = Localization:getInstance():getText("resource_silverCoin")
	elseif goodType == ResourceEnum.GEMS then
		result = Localization:getInstance():getText("resource_goldCoin")
	elseif goodType == ResourceEnum.CARD then
		result = Localization:getInstance():getText(MetaManager.card_meta[metaId].desc) 
	elseif goodType == ResourceEnum.EQUIP then
		result = Localization:getInstance():getText(MetaManager.equip_meta[metaId].desc)
	elseif goodType == ResourceEnum.PROP then
		result = Localization:getInstance():getText(MetaManager.prop_meta[metaId].desc)
	elseif goodType == ResourceEnum.RP_VALUE then
		result = Localization:getInstance():getText("gacha_rpNum")
	elseif goodType == ResourceEnum.ASTRALESSENCE then -- 星灵
		result = Localization:getInstance():getText("item_astralEssence")
	elseif goodType == ResourceEnum.GENERALEXP then -- 武将经验
		result = Localization:getInstance():getText("item_cardExp")
	elseif goodType == ResourceEnum.SPIRIT then -- 武将经验
		result = Localization:getInstance():getText(MetaManager.spirit_meta[metaId].nameKey)
	end
	return result
end