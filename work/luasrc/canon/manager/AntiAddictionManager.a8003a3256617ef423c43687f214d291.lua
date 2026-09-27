require "canon.request.RecordAddictedTimeRequest"

AntiAddictionManager = class()

local curUserId = nil
local addictionCoutTimeSchedule = nil
local addictionIsOpen = false
local addictionState1 = 3 * 60 * 60 --3 hours
local addictionState2 = 5 * 60 * 60 --5 hours
local reminderInterval = 15 * 60 --15 mins
local recordInterval = 15 * 60 --15 mins
if is360Android() then
    addictionIsOpen = true
end 
local curUserPlayInfo = {                            
                            timeStamp = TimeUtil.getServerTimeSeconds(),
                            during = 0,
                            lastReminderTime = 0
                        }
                        
AddictionStateTable = {
                            normal = 0,
                            slight = 1,
                            severe = 2,
                      }
function AntiAddictionManager.judgeIsAddiction(afterJudgeFunc)
    if not addictionIsOpen then
        return AddictionStateTable.normal
    end 
    if curUserId then
        if is360Android() then
            local function antiAddictionFunc()
                he_log_info("+++++++++++++++++++++++++++addiction Log:run atti-addiction func++++++++++++++++++++++++++++++++")
                if curUserPlayInfo.during > addictionState1 then
                    if (curUserPlayInfo.during - curUserPlayInfo.lastReminderTime) > reminderInterval then
                        curUserPlayInfo.lastReminderTime = curUserPlayInfo.during
                        local function recordAddictedTimeSucc(evt)
                            he_log_info("+++++++++++++++++++++++++++addiction Log:recordAddictedTimeSucc++++++++++++++++++++++++++++++++")
                            if curUserPlayInfo.during < addictionState2  then
                                if afterJudgeFunc and type(afterJudgeFunc) == "function" then
                                    afterJudgeFunc(AddictionStateTable.slight)
                                end
                            else
                                if afterJudgeFunc and type(afterJudgeFunc) == "function" then
                                    afterJudgeFunc(AddictionStateTable.severe)
                                end
                            end
                        end
                    
                        local function recordAddictedTimeFail(evt)
                            he_log_info("+++++++++++++++++++++++++++addiction Log:recordAddictedTimeFail++++++++++++++++++++++++++++++++")
                            
                        end
                        local params = { minutes = math.modf(curUserPlayInfo.during / 60) }
                        local request = RecordAddictedTimeRequest.new( params, rpc.SendingPriority.kHigh )
                        request:addEventListener( RequestNotifyEnum.RecordAddictedTimeSucceed, recordAddictedTimeSucc )
                        request:addEventListener( RequestNotifyEnum.RecordAddictedTimeFailed, recordAddictedTimeFail )
                        request:start()
                        he_log_info("+++++++++++++++++++++++++++addiction Log:send request++++++++++++++++++++++++++++++++")
                    end
                end 
            end

            check360Addiction(antiAddictionFunc)
            
        end
        
    end
end

function AntiAddictionManager.getUserInfo( user_id  ) 
    local user_path = HeResPathUtils:getUserDataPath()
    local file,err = io.open(user_path.."/"..user_id.."Addiction"..".txt","r")
    local user_data = ""
    if file then
      user_data = table.deserialize(file:read()) --json to table
      file:close()  
    end  
    return user_data
end

local function clearPlayDuring()
    local curDate = os.date("*t",TimeUtil.getServerTimeSeconds())
    local recDate = os.date("*t",curUserPlayInfo.timeStamp)
    if curDate.year ~= recDate.year or curDate.month ~= recDate.month or curDate.day ~= recDate.day then
        curUserPlayInfo = {
                            timeStamp = TimeUtil.getServerTimeSeconds(),
                            during = 0,
                            lastReminderTime = 0
                          }
    end
end 

local function addictionCoutTimeFunc()
    --he_log_info("+++++++++addictionCoutTimeFunc"..curUserPlayInfo.during)
    curUserPlayInfo.during = curUserPlayInfo.during  + 1 
    --per 15min record once
    if curUserPlayInfo.during  % recordInterval == 0 then
        curUserPlayInfo.timeStamp = TimeUtil.getServerTimeSeconds()
        clearPlayDuring()
        AntiAddictionManager.saveUserInfo( curUserId , curUserPlayInfo )
    end 
end 

function AntiAddictionManager.saveUserInfo( user_id ,user_data )
    local user_path = HeResPathUtils:getUserDataPath()
    local file = io.open(user_path.."/"..user_id.."Addiction"..".txt","w")
    file:write( table.serialize( user_data ) ) --table to json
    file:close()
end

function AntiAddictionManager.initAddictionTimer( user_id  )
    if not addictionIsOpen then
        return 
    end 
    curUserId = user_id
    curUserPlayInfo = AntiAddictionManager.getUserInfo( user_id  ) 
    if curUserPlayInfo == "" then
        curUserPlayInfo = {
                            timeStamp = TimeUtil.getServerTimeSeconds(),
                            during = 0,
                            lastReminderTime = 0
                          }
    else
        clearPlayDuring()
    end 
    
    if addictionCoutTimeSchedule == nil then
        addictionCoutTimeSchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( addictionCoutTimeFunc, 1, false )
    end 
end