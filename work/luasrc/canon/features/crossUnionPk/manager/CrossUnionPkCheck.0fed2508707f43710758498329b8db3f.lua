-- CrossUnionPkCheck.lua
-- geng.men
-- 2015-4-14
-- 跨服GVG 校验接口

CrossUnionPkCheck = {}

--是否在团员报名时间段内
function CrossUnionPkCheck.isInMemberApplyTimeLevel(timeLevel)
	
	if timeLevel == CrossUnionPkConsts.TIME_MEMBER_APPLY   then
		--团员参与阶段\
		return true
    end

	
	return false
end

--能否进行团员报名
function CrossUnionPkCheck.canMemberApply(timeLevel)
	if not CrossUnionPkCheck.isInMemberApplyTimeLevel(timeLevel) then
		--不在时间段内
		return false
	end

	if  UnionManager.getGainCrossUnionWarInunionApplyCrossGvg()  then --军团是否报名
	  if UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() then --自己已报名了
	  	return false
	  end
      return true
    end
    return false

end

--是否在团长报名时间段内
function CrossUnionPkCheck.isInManagerApplyTimeLevel(timeLevel)
	
	if timeLevel == CrossUnionPkConsts.TIME_ARMY_APPLY  then
		--团长参与阶段
		return true
	end
	return false
end

--能否进行团长报名
function CrossUnionPkCheck.canManagerApply(timeLevel)
	
	-- print("CrossUnionPkCheck.isInManagerApplyTimeLevel(timeLevel) = "..tostringRich(CrossUnionPkCheck.isInManagerApplyTimeLevel(timeLevel)))
	if not CrossUnionPkCheck.isInManagerApplyTimeLevel(timeLevel) then
		--不在时间段内
		return false
	end

	if UnionManager.getGainCrossUnionWarInunionApplyCrossGvg() then --军团是否报名
	  return false
	elseif UnionManager.getUnionLevel() >= 10  then-- 检测军团是否达到10 级
      return true
    end
    return false
end

function CrossUnionPkCheck.canManagerLight(	Ide,timeLevel)
	-- print("UnionManager.getUnionLevel() = "..tostringRich(UnionManager.getUnionLevel()))
	-- print("UnionManager.getGainCrossUnionWarInunionApplyCrossGvg() = "..tostringRich(UnionManager.getGainCrossUnionWarInunionApplyCrossGvg()))
	-- print("UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() = "..tostringRich(UnionManager.getGainCrossUnionWarInselfApplyCrossGvg()))
	local  Adjude = false
	
	if CrossUnionPkCheck.isInManagerApplyTimeLevel(timeLevel) then
		if UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() then --个人已经报名了
		Adjude = false
		else
			
            Adjude = true
	    end       
	elseif CrossUnionPkCheck.isInMemberApplyTimeLevel(timeLevel) then
		if UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() then --个人已经报名了
		Adjude = false
		else
		
			if UnionManager.getGainCrossUnionWarInunionApplyCrossGvg() then
				Adjude = true
			else
                Adjude = false
			end
			
		end

	end


	

	CrossUnionPkData.setCrossUnionWarLightOn(Adjude)
end











-- 检查是否正在进行特定的淘汰赛
-- timeLevel 要检查的时间区间
-- knockoutType 对应的淘汰赛类型
function CrossUnionPkCheck.isKnockoutMatching(timeLevel, knockoutType)
	if timeLevel == CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16 and knockoutType == CrossUnionPkConsts.KNOCKOUT_TYPE_16 then
		--正在十六强阶段
		return true
	elseif timeLevel == CrossUnionPkConsts.TIME_ARMY2_FIGHTING_8 and knockoutType == CrossUnionPkConsts.KNOCKOUT_TYPE_8 then
		--正在八强阶段
		return true
	elseif timeLevel == CrossUnionPkConsts.TIME_ARMY2_FIGHTING_4 and knockoutType == CrossUnionPkConsts.KNOCKOUT_TYPE_4 then
		--正在四强阶段
		return true
	elseif (timeLevel == CrossUnionPkConsts.TIME_ARMY2_FIGHTING_THIRD or timeLevel == CrossUnionPkConsts.TIME_ARMY2_FIGHTING_CHAMPION) 
			and (knockoutType == CrossUnionPkConsts.KNOCKOUT_TYPE_THIRD or knockoutType == CrossUnionPkConsts.KNOCKOUT_TYPE_CHAMPION) then
		--正在冠军赛/季军赛阶段
		return true
	end
	return false
end


function CrossUnionPkCheck.AdjusetCountDown(timeLevel,IDentity)
	local ResultTextName = nil
	if timeLevel == CrossUnionPkConsts.TIME_ARMY_APPLY then
    if UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() then --已报名
       ResultTextName = "HaveSignUp"

    else 
      if IDentity == UnionManager.TITLE_ELITE_MEMBER  or  IDentity == UnionManager.TITLE_MEMBER  then --团员
        
        if UnionManager.getGainCrossUnionWarInunionApplyCrossGvg() then --如果军团已报名

          --团员请求报名
          ResultTextName = "MEMBERAPPLY"
          
        else  --军团没有报名
          
          ResultTextName = "ARMYAPPLY"
        end

      elseif IDentity == UnionManager.TITLE_MANAGER or  IDentity == UnionManager.TITLE_VICE_MANAGER then
        ResultTextName = "ARMYAPPLY"
      end
    end
  elseif timeLevel == CrossUnionPkConsts.TIME_MEMBER_APPLY then 
    if UnionManager.getGainCrossUnionWarInselfApplyCrossGvg() then --已报名
	    ResultTextName = "HaveSignUp"
    else 
      --军团长
        if UnionManager.getGainCrossUnionWarInunionApplyCrossGvg() then
          ResultTextName = "MEMBERAPPLY"
        else
	      ResultTextName = "MISSAPPLY" --错过报名
        end
    end 
  elseif timeLevel == CrossUnionPkConsts.TIME_ARMY2_GROUP or timeLevel == CrossUnionPkConsts.TIME_GROUP_REWARD  then 
  	ResultTextName = "GROUPING" --分组阶段
  end 
  return ResultTextName
end

--能否进入淘汰赛主场景
--timeLevel 对应时间段 默认为当前时间段
function CrossUnionPkCheck.canEnterKouckoutScene(timeLevel)
	if timeLevel == nil then
		timeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
	end
	
	if timeLevel >= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16 and timeLevel <= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_CHAMPION  then
		--淘汰赛阶段
		return true
	end
	return false
end

--能否进入小组赛场景
--timeLevel 对应时间段 默认为当前时间段
function CrossUnionPkCheck.canEnterTeamAdjustScene(timeLevel)
	if timeLevel == nil then
		timeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
	end
	
	if timeLevel >= CrossUnionPkConsts.TIME_ARMY1_PREPARE and timeLevel <= CrossUnionPkConsts.TIME_ARMY1_FIGHTING  then
		--小组赛阶段
		return true
	end
	return false
end

--查看这个这个服务器id是否有跨服军团战
-- 是否在正确的军团战服务器
function CrossUnionPkCheck.isInCorrectServer()
	local serverId = DataManager.getServerid()
	
	return CrossUnionPkConfig.isCorrectServer(serverId)
end