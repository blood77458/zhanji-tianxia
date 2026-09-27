--------------------------------------------------------------------------------
-- FriendManager.lua - 好友相关的常量及存储结构
-- author: xiaojie.bai
-- date: 2013-08-08 17:53
--------------------------------------------------------------------------------

--
-- 好友系统中表格的大小配置
--
FriendManager = {}

FriendManager.DICT = {
  RESOURCE_FILE = "scene/friend_new.json",
  TABLE_WIDTH = 705,
  TABLE_HEIGHT_FRIENDS = 642,
  TABLE_HEIGHT_INVITE_RECEIVED = 642,
  TABLE_HEIGHT_INVITE_SENT = 734,
  TABLE_HEIGHT_FIND = 557,
  
  ITEM_WIDTH = 705,
  ITEM_HEIGHT = 165,
  TABLE_POSX = 15,
  TABLE_POSY = 120,
  TABLE_FIND_POSY = 220,

  TAG_INDEX_FRIEND = 1,
  TAG_INDEX_INVITERECEIVED = 2,
  TAG_INDEX_INVITESENT = 3,
  TAG_INDEX_FIND = 4,
  
  quality2Color = {"white", "green", "blue", "purple", "orange", "red", "gold"} --品质与成色字典
}

function FriendManager.containUid(uids, uid)
  if(not uids or #uids == 0) then
    return false
  else
    for _, _uid in ipairs(uids) do
      if tonumber(_uid) == tonumber(uid) then
        return true
      end
    end
  end
  return false
end