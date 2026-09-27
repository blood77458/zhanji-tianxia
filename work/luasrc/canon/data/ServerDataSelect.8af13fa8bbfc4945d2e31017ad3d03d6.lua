

-------------------------------
-------platFormId define-------
-------------------------------
--0: undefined windows
--1: UC android
-------------------------------

local platformGroup_longyuan = {
                        [0] = false,	--default = 0,
                    [1] = true,		--uc = 1,
                    [2] = true,		--nd91 = 2,
                    [3] = true, 	--mi = 3,
                    [4] = true, 	--qihoo360 = 4,
                        [5] = false,	--ios = 5,
                    [6] = true,		--baiduDK = 6,
                    [7] = true,		--wdj = 7,
                        [8] = true,	--gamecenter = 8,
                        [9] = false,	--lenovo = 9,
                        [10] = true,	--yingyonghui = 10,
                        [11] = false,	--he = 11,
						[14] = false,	--googleplay = 14,
                        [16] = false,	--ibuka = 16,
			            [17] = false,	--iosTW = 17,	
						[19] = false,	--twhe = 19,
						[20] = false,	--chuangmeng = 21,
						[22] = false,	--facebook = 22,
						[23] = false,	--qqyingyongbao = 23,
						[24] = false,	--twIbuka = 24,
						[25] = false,	--mobile01 = 25,
						[26] = true,    --longyuanofficial = 26,
						--墨迹、极游、三星、迪信通、N多、优亿、利趣、遇见、核桃、动游、艺果。
						[27] = true,    --longyuanMoji = 27,
						[28] = true,	--longyuanJiyou = 28,
						[29] = true,	--longyuanSanxing = 29,
						[30] = true,	--longyuanDixintong = 30,
						[31] = true,	--longyuanNduo = 31,
						[32] = true,	--longyuanYouyi = 32,
						[33] = true,	--longyuanLiqu = 33,
						[34] = true,	--longyuanYujian = 34,
						[35] = true,	--longyuanHetao = 35,
						[36] = true, 	--longyuanDongyou = 36,
						[37] = true,	--longyuanYiguo = 37,
						[38] = false,	--HYKJ = 38,--华悦科技
                        [39] = true, 	--anzhi = 39,
			[40] = true,    --vivo = 40,
                    }
local function isLongyuanFunc(platformId)
	return true--platformGroup_longyuan[platformId]--从龙渊分支打出来的包都是龙渊渠道
end

local serverShowList = 
{
	maxServerId = 900,
	group_longyuan = {
						{min = 1, max = 56},
						{min = 400, max =900},
						{min = 9990,max = 9999},
					 },
	group_own = {
					{ min = 1, max = 399},
				},
}

function isServerShow(serverid)
	local isShow = false
	if serverid == 9001 then
		--版署和谐服
		return isShow
	else
		return true -- 不再区分自营和龙渊，所有玩家混服2014/9/2
		--[[
		local platformId = getCurPlatFormId()
		local isLongyuan = isLongyuanFunc(platformId)
		
		if isLongyuan then
			--龙渊运营渠道
			for k,v in pairs(serverShowList.group_longyuan) do 
				if serverid >= v.min and serverid <= v.max then
					isShow = true
					break
				end
			end
		else
			--默认自营渠道
			if serverid > serverShowList.maxServerId then
				isShow = true
			else
				for k,v in pairs(serverShowList.group_own) do
					if serverid >= v.min and serverid <= v.max then
						isShow = true
						break
					end
				end
			end
		end
		return isShow
		--]]
	end
end


