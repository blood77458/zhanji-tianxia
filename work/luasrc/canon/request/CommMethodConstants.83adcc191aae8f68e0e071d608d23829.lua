--------------------------------------------------------------------------------
-- CommMethodConstants.lua - 通信协议请求方法
-- author: xiaojie.bai
-- date: 2013-07-30 11:00
--------------------------------------------------------------------------------

METHOD_GETFRIENDS = "getFriends" --获取好友列表信息
METHOD_GETREVIEWFRIENDS = "getReviewFriends" --获取等待审核的好友请求列表
METHOD_GETINVITATIONFRIENDS = "getInvitationFriends" --获取已发出的好友邀请列表
METHOD_GETFRIENDDETAIL = "getFriendDetail" --获取好友详情
METHOD_GETRECOMMENDEDFRIENDS = "getRecommendedFriends" --获取推荐好友
METHOD_SEARCHUSERBYNICKNAME = "searchUserByNickname" --据昵称查询玩家
METHOD_DELETEFRIEND = "deleteFriend" --删除好友关系

METHOD_ACCEPTINVITATION = "acceptInvitation" --接收添加好友邀请
METHOD_REFUSEINVITATION = "refuseInvitation" --拒绝添加好友邀请
METHOD_ACCEPTALLINVITATIONS = "acceptAllInvitations" --接收所有好友邀请
METHOD_REFUSEALLINVITATIONS = "refuseAllInvitations" --拒绝所有好友邀请

METHOD_SENDINVITATION = "sendInvitation" --发送邀请
METHOD_SENDALLINVITATIONS = "sendAllInvitations" --全部发送邀请

METHOD_CANCELINVITATION = "cancelInvitation" --取消好友请求

METHOD_SENDFREEGIFT = "sendFreeGift" --发送免费礼物
METHOD_SENDALLFREEGIFT = "sendAllFreeGift" --向所有好友发送免费礼物
METHOD_ACCEPTALLFREEGIFT = "acceptAllFreeGift" --接受所有免费礼物

METHOD_CHALLENGEFRIEND = "challengeFriend" --好友切磋请求

METHOD_BUYGRID = "buyGrid"
METHOD_BUYGOODS = "buyGoods"
METHOD_USEPROP = "useProp"
METHOD_GETGACHABROADCAST = "getGachaBroadcast"

METHOD_GETELITEINFO = "getEliteInfo" --获取精英关卡信息
METHOD_CHALLENGEELITE = "challengeElite" --挑战精英关卡
METHOD_RESETELITE = "resetElite" --重置关卡挑战次数

METHOD_GENENICKNAME = "geneNickname" --随机生成可用用户昵称

METHOD_GETSHARKBEASTFRAGMENTS = "getSharkBeastFragments"
METHOD_ADJUSTBEAST = "adjustBeast"
METHOD_AVOIDBATTLE = "avoidBattle"
METHOD_FINISHBEASTCOMPOSE = "finishBeastCompose"
METHOD_GETROBUSERLIST = "getRobUserList"
METHOD_ROBBEASTFRAGMENT = "robBeastFragment"
METHOD_STARTCOMPOSEBEAST = "startComposeBeast"
METHOD_GETSHARKBEASTS = "getSharkBeasts"
METHOD_GAINCHARGEMONEYREWARD = "gainChargeMoneyReward"

METHOD_UPGRADEMATRIX = "upgradeMatrix"
METHOD_REPLACEMATRIXGRID = "replaceMatrixGrid"

METHOD_SYNTHETIZEITEM = "synthetizeItem"

METHOD_GETSKYTOWERINFO = "getSkyTowerInfo"
METHOD_CHALLENGESKYTOWER = "challengeSkyTower"
METHOD_GAINYESTERDAYADDITION = "gainYesterdayAddition"
METHOD_GAINFLOORADDITION = "gainFloorAddition"
METHOD_GAINRANKREWARDS = "gainRankRewards"
METHOD_RESETCLIMBTOWERDATA = "resetClimbData"