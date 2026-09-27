--------------------------------------------------------------------------------
-- MaintenanceManager.lua -- 活动开关管理
-- author: xiaojie.bai
-- date: 2013-10-29
--------------------------------------------------------------------------------

SimpleMaintenanceManager = {}

-- 判断活动是否开启
-- activityName：活动名称
-- timeStamp：时间戳
function SimpleMaintenanceManager.isFeatureEnable(feature)
  local isEnable = false;
  if(not feature or not feature.enable) then
    return isEnable
  end

  local curServerTimeStamp = TimeUtil.getServerTimeSeconds()
  
  local activityBeginDateList = feature.beginTime:split(" ")[1]:split("/")
  local activityEndDateList = feature.endTime:split(" ")[1]:split("/")
  local activityBeginTimeList = feature.beginTime:split(" ")[2]:split(":")
  local activityEndTimeList = feature.endTime:split(" ")[2]:split(":")
            
  local activityBeginTimeStamp = os.time({day=activityBeginDateList[3], month=activityBeginDateList[2],year=activityBeginDateList[1], hour=activityBeginTimeList[1], min=activityBeginTimeList[2], sec=0}) 
  local activityEndTimeStamp = os.time({day=activityEndDateList[3], month=activityEndDateList[2],year=activityEndDateList[1], hour=activityEndTimeList[1], min=activityEndTimeList[2], sec=0}) 
  
  isEnable = curServerTimeStamp >= activityBeginTimeStamp and curServerTimeStamp <= activityEndTimeStamp
  
  return isEnable
end