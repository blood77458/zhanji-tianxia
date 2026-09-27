--
-- ChatManager.lua
-- Author: zheng.che
-- Date: 2014-04-10 11:53:49\
-- 聊天管理
--
require "canon.constants.MethodDict"

ChatManager = {}

----------------------------------------------------------------------------------------------------------------------------------枚举

--聊天相关事件
ChatManager.NEW_CHAT_CONTENT = "newChatContent" --新消息事件 参数格式: data = {chatType = 2, chatContent = {uid = 100, nickName = "杰特" .. nameIndex, vipLevel = 1, message = "我操wocao"}}
ChatManager.CHAT_TAG_VIEWED = "CHAT_TAG_VIEWED" --切换聊天标签页后派发 无参数
ChatManager.CHAT_MESSAGE_SHOWED = "CHAT_MESSAGE_SHOWED" --聊天消息发送完毕消息 无参数
ChatManager.CONSUME_SPEAKER = "CONSUME_SPEAKER" --消耗喇叭
ChatManager.SEND_FAILED = "SEND_FAILED" --发送失败

--公告类型
ChatManager.REACH_TOWER_TOP   = 1--玩家在通天塔中爬到塔顶
ChatManager.ARENA_NO1         = 2--玩家在竞技场中夺取第一名
ChatManager.BOSS_LAST_HIT     = 3--玩家对Boss造成了最后一击
ChatManager.BABEL_NO1         = 4--通天塔结算时，玩家在通天塔排名中排到第一名
ChatManager.PK_NO1            = 5--比武结束后，玩家比武第一名
ChatManager.WORLD_BOSS_NO1    = 6--BOSS被击杀后，玩家在世界BOSS中得了第一名
ChatManager.CREATE_UNION      = 7--玩家创建了军团
ChatManager.CROSS_CHAMPION    = 8--跨服争霸夺冠
ChatManager.UNION_OCCUPY      = 9--军团城池占领
ChatManager.CROSS_XIAOYU_NO1  = 10--跨服gacha小玉嫁到活动结束，玩家排名第一


----------------------------------------------------------------------------------------------------------------------------------初始化

--控制器初始化
function ChatManager.startup()
	NotificationManager:addEventListener(MethodDict.METHOD_WORLDCHAT, ChatManager.onWorldChat)
	NotificationManager:addEventListener(MethodDict.METHOD_UNIONCHAT, ChatManager.onUnionChat)
	NotificationManager:addEventListener(MethodDict.METHOD_PRIVATECHAT, ChatManager.onPrivateChat)
end

----------------------------------------------------------------------------------------------------------------------------------协议接收

--收到世界频道消息
function ChatManager.onWorldChat(evt)
	--print("onWorldChat! evt = " .. table.tostring(evt))
	local bodyData = evt.data
	if (bodyData.retCode ~= 0) or (tonumber(bodyData.uid) ~= 1) then
		--普通世界聊天
		ChatManager.addWorldChatContent(bodyData)
    if (tonumber(bodyData.uid) == tonumber(DataManager.getCurrUser().uid)) and (bodyData.vipLevel < 1) then
      RewardManager:getReward({{itemType = ResourceEnum.PROP, metaId = 400127, amount = -1}})
      NotificationManager:dispatchEvent(Event.new(ChatManager.CONSUME_SPEAKER))
    end
    if tonumber(bodyData.uid) == tonumber(DataManager.getCurrUser().uid) then
      local currentWorldChatNum = DailyDataManager.getWorldMessageNum()
      DailyDataManager.setWorldMessageNum(currentWorldChatNum + 1)
    end
	else
		--公告
    for k, v in ipairs(bodyData.systemBroadcasts) do
      local castType = v.castType
      local message = ChatManager.getNewsStr(v.castType, v.content)

      local messageData = table.clone(bodyData, true)
      messageData.message = message
      ChatManager.addWorldChatContent(messageData)
    end
	end
end

--收到军团频道消息
function ChatManager.onUnionChat(evt)
	--print("onUnionChat! evt = " .. table.tostring(evt))
	local bodyData = evt.data
	ChatManager.addUnionChatContent(bodyData)
end

--收到私聊消息
function ChatManager.onPrivateChat(evt)
	--print("onPrivateChat! evt = " .. table.tostring(evt))
	local bodyData = evt.data
	ChatManager.addSpecialChatContent(bodyData)
end

--发送消息
function ChatManager.sendChat(params)
  --[[
  local chatTable = {}
  chatTable.method = params.method
  chatTable.message = params.message
  chatTable.userName = params.userName
  ]]
  if not TCPManager:sharedInstance():sendData(params) then
    NotificationManager:dispatchEvent(Event.new(ChatManager.SEND_FAILED))
  end
end

----------------------------------------------------------------------------------------------------------------------------------对外接口

--打开私聊窗口
function ChatManager.gotoPrivateChat(nick, uid)

end

----------------------------------------------------------------------------------------------------------------------------------处理函数

local chatList = {}
--[[
local nameIndex = 1
local function showTextFinish()
  
  NotificationManager:dispatchEvent(Event.new(ChatManager.NEW_CHAT_CONTENT, {chatType = 2, chatContent = {uid = 100, nickName = "杰特" .. nameIndex, vipLevel = 1, message = "我操wocao"}}))
  nameIndex = nameIndex + 1
end
local showTextFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( showTextFinish, 3, false )]]
function ChatManager.addWorldChatContent(aContent)
  if aContent.retCode == 0 then
    if not chatList["world"] then
      chatList["world"] = {}
    end
    table.insert(chatList["world"], aContent)
    local chatShowMax = DataManager.GameMetaData.chatSettingConfig.worldChatShowMax
    if #chatList["world"] > chatShowMax then
      for i = #chatList["world"] - chatShowMax, 1, -1 do
        table.remove(chatList["world"], i)
      end
    end
  end
  NotificationManager:dispatchEvent(Event.new(ChatManager.NEW_CHAT_CONTENT, {chatType = 1, chatContent = aContent}))
  NotificationManager:dispatchEvent(Event.new(ChatManager.CHAT_MESSAGE_SHOWED))
end

function ChatManager.getWorldChatList()
  -- chatList["world"] = {
  --   {uid = 100, nickName = "杰特", vipLevel = 1, message = "我操"},
  -- }
  return chatList["world"] or {}
end

function ChatManager.setWorldChatNewIndex(aIndex)
  chatList["worldNewIndex"] = aIndex
end

function ChatManager.resetWorldChatNewIndex()
  if chatList["world"] then
    chatList["worldNewIndex"] = #chatList["world"]
  else
    chatList["worldNewIndex"] = 0
  end
end

function ChatManager.getWorldChatNewIndex()
  return chatList["worldNewIndex"] or 0
end

function ChatManager.hasUnreadWorldChat()
  if chatList["world"] then
    return (#chatList["world"] > chatList["worldNewIndex"])
  end
  return false
end

function ChatManager.addSpecialChatContent(aContent)
  if aContent.retCode == 0 then
    if not chatList["special"] then
      chatList["special"] = {}
    end
    table.insert(chatList["special"], aContent)
    local chatShowMax = DataManager.GameMetaData.chatSettingConfig.privateChatShowMax
    if #chatList["special"] > chatShowMax then
      for i = #chatList["special"] - chatShowMax, 1, -1 do
        table.remove(chatList["special"], i)
        local oldIndex = ChatManager.getSpecialChatNewIndex()
        if oldIndex > 0 then
          ChatManager.setSpecialChatNewIndex(oldIndex - 1)
        end
      end
    end
  end
  NotificationManager:dispatchEvent(Event.new(ChatManager.NEW_CHAT_CONTENT, {chatType = 2, chatContent = aContent}))
  NotificationManager:dispatchEvent(Event.new(ChatManager.CHAT_MESSAGE_SHOWED))
end

function ChatManager.getSpecialChatList()
  return chatList["special"] or {}
end 

function ChatManager.setSpecialChatNewIndex(aIndex)
  chatList["specialNewIndex"] = aIndex
end

function ChatManager.resetSpecialChatNewIndex()
  if chatList["special"] then
    chatList["specialNewIndex"] = #chatList["special"]
  else
    chatList["specialNewIndex"] = 0
  end
end

function ChatManager.getSpecialChatNewIndex()
  return chatList["specialNewIndex"] or 0
end

function ChatManager.hasUnreadSpecialChat()
  if chatList["special"] then
    return (#chatList["special"] > chatList["specialNewIndex"])
  end
  return false
end

function ChatManager.addUnionChatContent(aContent)
  if aContent.retCode == 0 then
    if not chatList["union"] then
      chatList["union"] = {}
    end
    table.insert(chatList["union"], aContent)
    local chatShowMax = DataManager.GameMetaData.chatSettingConfig.unionChatShowMax
    if #chatList["union"] > chatShowMax then
      for i = #chatList["union"] - chatShowMax, 1, -1 do
        table.remove(chatList["union"], i)
        local oldIndex = ChatManager.getUnionChatNewIndex()
        if oldIndex > 0 then
          ChatManager.setUnionChatNewIndex(oldIndex - 1)
        end
      end
    end
  end
  NotificationManager:dispatchEvent(Event.new(ChatManager.NEW_CHAT_CONTENT, {chatType = 3, chatContent = aContent}))
  NotificationManager:dispatchEvent(Event.new(ChatManager.CHAT_MESSAGE_SHOWED))
end

function ChatManager.getUnionChatList()
  return chatList["union"] or {}
end 

function ChatManager.setUnionChatNewIndex(aIndex)
  chatList["unionNewIndex"] = aIndex
end

function ChatManager.resetUnionChatNewIndex()
  if chatList["union"] then
    chatList["unionNewIndex"] = #chatList["union"]
  else
    chatList["unionNewIndex"] = 0
  end
end

function ChatManager.getUnionChatNewIndex()
  return chatList["unionNewIndex"] or 0
end

function ChatManager.hasUnreadUnionChat()
  if chatList["union"] then
    return (#chatList["union"] > chatList["unionNewIndex"])
  end
  return false
end

function ChatManager.resetChatInfo()
  if chatList["world"] then
    for k, v in pairs(chatList["world"]) do
      chatList["world"][k] = nil
    end
  end
  if chatList["special"] then
    for k, v in pairs(chatList["special"]) do
      chatList["special"][k] = nil
    end
  end
  if chatList["union"] then
    for k, v in pairs(chatList["union"]) do
      chatList["union"][k] = nil
    end
  end
  chatList["specialNewIndex"] = 0
  chatList["unionNewIndex"] = 0
  chatList["worldNewIndex"] = 0
end

function ChatManager.hasUnreadChat()
  return ChatManager.hasUnreadWorldChat() or ChatManager.hasUnreadSpecialChat() or ChatManager.hasUnreadUnionChat()
end

------------------------------------------------------------------------------------------------------------------------------------系统消息相关

-------------------------------------------------
-- 获得系统消息文字内容
-- newsType 动态类型
-- detailData 后端返回的详细信息json
-------------------------------------------------
function ChatManager.getNewsStr(newsType, detailData)
  local _json = require("cjson")
  detailData = _json.decode(detailData)
  local result = ""

  if newsType == ChatManager.REACH_TOWER_TOP then
    --{nickname:xxx,}
    result =  Localization:getInstance():getText("union_chat_world_system_conten1", {name = detailData.nickname})--{name}成功通关通天塔
  elseif newsType == ChatManager.ARENA_NO1 then
    --{nickname:xxx, oldTopNickname:xxx}
    result = Localization:getInstance():getText("union_chat_world_system_conten2", {name1 = detailData.nickname, name2 = detailData.oldTopNickname})--{name1}力压群雄，从{name2}（原第一名玩家）手中夺走了天下第一的宝座。
  elseif newsType == ChatManager.BOSS_LAST_HIT then
    --{nickname:xxx, rewardCoin:xxx}
    result = Localization:getInstance():getText("union_chat_world_system_conten3", {name = detailData.nickname, num = detailData.rewardCoin})--{name}成功给予Boss最后一击，获得了{num}银币奖励。
  elseif newsType == ChatManager.BABEL_NO1 then
    --{nickname:xxx}
    result = Localization:getInstance():getText("union_chat_world_system_conten4", {name = detailData.nickname})--{name}在通天塔中夺得第一!
  elseif newsType == ChatManager.PK_NO1 then
    --{nickname:xxx, okRound:xxx}
    result = Localization:getInstance():getText("union_chat_world_system_conten5", {name = detailData.nickname})--{name}在武道大会中夺得第一
  elseif newsType == ChatManager.WORLD_BOSS_NO1 then
    --{nickname:xxx}
    result = Localization:getInstance():getText("union_chat_world_system_conten6", {name = detailData.nickname})--{name}在抢亲战中夺得第一！
  elseif newsType == ChatManager.CREATE_UNION then
    --{nickname:xxx, unionName:xxx}
    result = Localization:getInstance():getText("union_chat_world_system_conten7", {name1 = detailData.nickname, name2 = detailData.unionName})--【{name1}】创建了军团【{name2}】，准备一展宏图
  elseif newsType == ChatManager.CROSS_CHAMPION then
    --{nickname:xxx,}
    result =  Localization:getInstance():getText("cross_text_liaotian", {num1 = detailData.serverId, num2 = detailData.nickname, num3 = detailData.serverId})
  elseif newsType == ChatManager.UNION_OCCUPY then
    --{unionName:xxx, cityId:xxx}
    local cityName = UnionPkUtils.getCityNameById(tonumber(detailData.cityId))
    result = Localization:getInstance():getText("UnionWar_attend_text", {num1 = detailData.unionName, num2 = cityName})--恭喜【{num1}】军团本轮军团战成功占领城池【{num2}】
  elseif newsType == ChatManager.CROSS_XIAOYU_NO1 then
    result = Localization:getInstance():getText("activity_rankin1Anounce", {player = detailData.nickname, num = detailData.serverId})
  end
  return result
end

------------------------------------------------------------------------------------------------------------------------------------其他

--放在最后
ChatManager.startup()