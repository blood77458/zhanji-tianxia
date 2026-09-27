
BattleSelfConfig = nil
BattleEnemyConfig = nil
BattleFightEventConfig = nil

function createFightEventConfigData(anim, frame, self_x, self_y, enemy_x, enemy_y)
	local data = {}
	data.anim = anim
	data.frame = frame
	data.self_x = self_x
	data.self_y = self_y
	data.enemy_x = enemy_x
	data.enemy_y = enemy_y
	return data
end

if BattleFightEventConfig == nil then
	BattleFightEventConfig = {}
	local self_x = 720/2-100;
	local self_y = 1280/2-100;
	local enemy_x = self_x + 200;
	local enemy_y = self_y + 200;
	
	for i = 1 , 20 do
		local key = "fight" .. i
		BattleFightEventConfig[key] = createFightEventConfigData(5+i, 10, self_x, self_y, enemy_x, enemy_y) 
	end
	BattleFightEventConfig["fightEnd"] = createFightEventConfigData(26, 10, self_x, self_y, enemy_x, enemy_y) 
end

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local kOffsetX = (visibleSize.width/9)
local kCardWidth = visibleSize.width / 5.2

local kSelfPosY = visibleSize.height / 12
local kSelfPosY2 = visibleSize.height / 5
local kSelfPosY3 = visibleSize.height * 0.3
local kEnemyPosY = visibleSize.height - kSelfPosY
local kEnemyPosY2 = visibleSize.height - kSelfPosY2 
local kEnemyPosY3 = visibleSize.height - kSelfPosY3

local function createConfigData( x, y, card, cardBg, cardBorder, cardBall, cardBallBg, light, shadow)
	local configData = {}
	configData.pos_x = x
	configData.pos_y = y
	configData.card = card
	configData.cardBg = cardBg
	configData.cardBorder = cardBorder
	configData.cardBall = cardBall
	configData.cardBallBg = cardBallBg
	configData.light = light
	configData.shadow = shadow
	return configData
end

if BattleSelfConfig == nil then
	BattleSelfConfig = {}
	BattleSelfConfig[0] = createConfigData(kOffsetX + kCardWidth*2, kSelfPosY3, "card1M", "cardBg1M", "cardBorder1M", "card1Mball", "card1Mballbg")
	BattleSelfConfig[1]=createConfigData(kOffsetX, kSelfPosY, "card15", "cardBg15", "cardBorder15", "card15ball", "card15ballbg", "yuan15", "shadow15")
	BattleSelfConfig[2]=createConfigData(kOffsetX + kCardWidth, kSelfPosY, "card14", "cardBg14", "cardBorder14", "card14ball", "card14ballbg", "yuan14", "shadow14")
	BattleSelfConfig[3]=createConfigData(kOffsetX + kCardWidth*2, kSelfPosY, "card13", "cardBg13", "cardBorder13", "card13ball", "card13ballbg", "yuan13", "shadow13")
	BattleSelfConfig[4]=createConfigData(kOffsetX + kCardWidth*3, kSelfPosY, "card12", "cardBg12", "cardBorder12", "card12ball", "card12ballbg", "yuan12", "shadow12")
	BattleSelfConfig[5]=createConfigData(kOffsetX + kCardWidth*4, kSelfPosY, "card11", "cardBg11", "cardBorder11", "card11ball", "card11ballbg", "yuan11", "shadow11")
	
	BattleSelfConfig[6]=createConfigData(kOffsetX, kSelfPosY2, "card19", "cardBg19", "cardBorder19", "card19ball", "card19ballbg", "yuan19", "shadow19")
	BattleSelfConfig[7]=createConfigData(kOffsetX + kCardWidth, kSelfPosY2, "card18", "cardBg18", "cardBorder18", "card18ball", "card18ballbg", "yuan18", "shadow18")
	BattleSelfConfig[8]=createConfigData(kOffsetX + kCardWidth*2, kSelfPosY2, "card1M", "cardBg1M", "cardBorder1M", "card1Mball", "card1Mballbg")
	BattleSelfConfig[9]=createConfigData(kOffsetX + kCardWidth*3, kSelfPosY2, "card17", "cardBg17", "cardBorder17", "card17ball", "card17ballbg", "yuan17", "shadow17")
	BattleSelfConfig[10]=createConfigData(kOffsetX + kCardWidth*4, kSelfPosY2, "card16", "cardBg16", "cardBorder16", "card16ball", "card16ballbg", "yuan16", "shadow16")
end

if BattleEnemyConfig == nil then
	BattleEnemyConfig = {}
	BattleEnemyConfig[0]=createConfigData(kOffsetX + kCardWidth*2, kEnemyPosY3, "card2M", "cardBg2M", "cardBorder2M", "card2Mball", "card2Mballbg")
	BattleEnemyConfig[1]=createConfigData(kOffsetX, kEnemyPosY, "card21", "cardBg21", "cardBorder21", "card21ball", "card21ballbg", "yuan21", "shadow21")
	BattleEnemyConfig[2]=createConfigData(kOffsetX + kCardWidth, kEnemyPosY, "card22", "cardBg22", "cardBorder22", "card22ball", "card22ballbg", "yuan22", "shadow22")
	BattleEnemyConfig[3]=createConfigData(kOffsetX + kCardWidth*2, kEnemyPosY, "card23", "cardBg23", "cardBorder23", "card23ball", "card23ballbg", "yuan23", "shadow23")
	BattleEnemyConfig[4]=createConfigData(kOffsetX + kCardWidth*3, kEnemyPosY, "card24", "cardBg24", "cardBorder24", "card24ball", "card24ballbg", "yuan24", "shadow24")
	BattleEnemyConfig[5]=createConfigData(kOffsetX + kCardWidth*4, kEnemyPosY, "card25", "cardBg25", "cardBorder25", "card25ball", "card25ballbg", "yuan25", "shadow25")
	
	BattleEnemyConfig[6]=createConfigData(kOffsetX, kEnemyPosY, "card26", "cardBg26", "cardBorder26", "card26ball", "card26ballbg", "yuan26", "shadow26")
	BattleEnemyConfig[7]=createConfigData(kOffsetX + kCardWidth, kEnemyPosY2, "card27", "cardBg27", "cardBorder27", "card27ball", "card27ballbg", "yuan27", "shadow27")
	BattleEnemyConfig[8]=createConfigData(kOffsetX + kCardWidth*2, kEnemyPosY2, "card2M", "cardBg2M", "cardBorder2M", "card2Mball", "card2Mballbg")
	BattleEnemyConfig[9]=createConfigData(kOffsetX + kCardWidth*3, kEnemyPosY2, "card28", "cardBg28", "cardBorder28", "card28ball", "card28ballbg", "yuan28", "shadow28")
	BattleEnemyConfig[10]=createConfigData(kOffsetX + kCardWidth*4, kEnemyPosY2, "card29", "cardBg29", "cardBorder29", "card29ball", "card29ballbg", "yuan29", "shadow29")
end

function getConfigDataIndex(posId, num)
	local index = nil
	if posId == 0 then
		index = 0
	elseif posId == 1 then
		index = (3 + 5)
	elseif posId == 2 then --1
		if num == 2 then
			index = (3 + 0)
		else
			index = (2 + 5)
		end
	elseif posId == 3 then --2 
		index = (4 + 5)
	elseif posId == 4 then --3
		if num == 4 then
			index = (3 + 0)
		else
			index = (2 + 0)
		end	
	elseif posId == 5 then
		index = (4 + 0)
	elseif posId == 6 then --5
		if num == 6 then
			index = (3 + 0)
		else
			index = (1 + 0)
		end	
	elseif posId == 7 then --6
		index = (5 + 0)
	elseif posId == 8 then --7
		if num == 8 then
			index = (3 + 0)
		else
			index = (1 + 5)
		end
	elseif posId == 9 then -- 8
		index = (5 + 5)
	elseif posId == 10 then
		index = (3 + 0)
	end
	return index
end


function getConfigData(posId, num)
      local data = nil
	if posId < 10000 then
		local index = getConfigDataIndex(posId, num)
		data = BattleSelfConfig[index]
	else
		posId = posId - 10000
		local index = getConfigDataIndex(posId, num)
		data = BattleEnemyConfig[index]
	end
	return data
end






















