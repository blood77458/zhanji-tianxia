require "hecore.rpc"
require "hecore.class"
require "canon.request.Communication"
require "canon.customUI.RequestLoadingBox"
require "canon.panel.CanonMessageBox"

RequestNotifyEnum = table.const {
  LoginServerSucceed = "LoginServerSucceed",
  LoginServerFailed = "LoginServerFailed",
  CreateUserSucceed = "CreateUserSucceed",
  CreateUserFailed = "CreateUserFailed",
  GetFriendsSucceed = "GetFriendsSucceed", --获取好友列表信息
  UpgradeEquipSucceed = "UpgradeEquipSucceed",
  UpgradeEquipFailed = "UpgradeEquipFailed",
  QuickUpgradeEquipSucceed = "QuickUpgradeEquipSucceed",
  QuickUpgradeEquipFailed = "QuickUpgradeEquipFailed",
  EvolveEquipSucceed = "EvolveEquipSucceed",
  EvolveEquipFailed = "EvolveEquipFailed",
  TrainCardSucceed = "TrainCardSucceed",--卡片培养成功
  TrainCardFailed = "TrainCardFailed",--卡片培养失败
  SaveCardTrainSucceed = "SaveCardTrainSucceed",--保存卡片培养成功
  GiveUpCardTrainSucceed = "GiveUpCardTrainSucceed",
  TriggerBattleSucceed = "TriggerBattleSucceed",
  TriggerCoinSucceed = "TriggerCoinSucceed",
  TriggerExpSucceed = "TriggerExpSucceed",
  TriggerCardSucceed = "TriggerCardSucceed",
  TriggerEmptySucceed = "TriggerEmptySucceed",
  TriggerRandomSucceed = "TriggerRandomSucceed",
  MapEventFailed = "MapEventFailed",
  GameInitSucceed = "GameInitSucceed",
  GetGameMetaSucceed = "GetGameMetaSucceed",
  GetPropsSucceed = "GetPropsSucceed",    --道具
  GetEquipsSucceed = "GetEquipsSucceed",  --装备
  GetArenaMatchedPlayersSucceed = "GetArenaMatchedPlayersSucceed",
  GetArenaMatchedPlayersFailed = "GetArenaMatchedPlayersFailed",
  BuyChallengeNumSucceed = "BuyChallengeNumSucceed",
  BuyChallengeNumFailed = "BuyChallengeNumFailed",
  ChallengeArenaSucceed = "ChallengeArenaSucceed",
  ChallengeArenaFailed = "ChallengeArenaFailed",
  GainArenaScoreByRankSucceed = "GainArenaScoreByRankSucceed",
  GainArenaScoreByRankFailed = "GainArenaScoreByRankFailed",
  UpgradeSkillSucceed = "UpgradeSkillSucceed",--技能升级成功
  UpgradeSkillFailed = "UpgradeSkillFailed",--技能升级失败

  GetReviewFriendsSucceed = "GetReviewFriendsSucceed", --获取等待审核的好友请求列表
  GetInvitationFriendsSucceed = "GetInvitationFriendsSucceed", --获取已发出的邀请列表
  GetFriendDetailSucceed = "GetFriendDetailSucceed", --获取好友信息详情
  GetFriendDetailFailed = "GetFriendDetailFailed", --TODO 获取好友详情失败
  GetRecommendedFriendsSucceed = "GetRecommendedFriendsSucceed", --获取推荐好友
  SearchUserByNicknameSucceed = "SearchUserByNicknameSucceed", --据昵称查询用户
  DeleteFriendSucceed = "DeleteFriendSucceed", --删除好友关系

  AcceptInvitationSucceed = "AcceptInvitationSucceed", -- 接收好友邀请
  AcceptInvitationFailed = "AcceptInvitationFailed", -- 接收好友邀请失败
  RefuseInvitationSucceed = "RefuseInvitationSucceed", -- 拒绝好友邀请
  AcceptAllInvitationsSucceed = "AcceptAllInvitationsSucceed", --接收所有好友邀请
  RefuseAllInvitationsSucceed = "RefuseAllInvitationsSucceed", --拒绝所有好友邀请

  CancelInvitationSucceed = "CancelInvitationSucceed", --取消好友邀请
  SendInvitationSucceed = "SendInvitationSucceed", --发送好友邀请
  SendInvitationFailed = "SendInvitationFailed", --发送邀请失败
  SendAllInvitationsSucceed = "SendAllInvitationsSucceed", --全部好友发送邀请

  SendFreeGiftSucceed = "SendFreeGiftSucceed", -- 发送免费礼物
  SendFreeGiftFailed = "SendFreeGiftFailed", -- 发送礼物失败
  SendAllFreeGiftSucceed = "SendAllFreeGiftSucceed", -- 向所有好友发送免费礼物
  SendAllFreeGiftFailed = "SendAllFreeGiftFailed", --向所有好友发送礼物失败
  AcceptAllFreeGiftSucceed = "AcceptAllFreeGiftSucceed", -- 接受所有免费礼物
  AcceptAllFreeGiftFailed = "AcceptAllFreeGiftFailed", -- 接受所有免费礼物

  ExchangeTrainDanSucceed = "ExchangeTrainDanSucceed",
  ExchangeTrainDanFailed = "ExchangeTrainDanFailed",
  GainRankFirstRewardSucceed = "GainRankFirstRewardSucceed",
  GainRankFirstRewardFailed = "GainRankFirstRewardFailed",
  GachaCardSucceed = "GachaCardSucceed",
  GachaCardFailed = "GachaCardFailed",
  GachaCardFreeSucceed = "GachaCardFreeSucceed",
  GachaCardFreeFailed = "GachaCardFreeFailed",
  CardComposeSucceed = "CardComposeSucceed", --合成
  CardComposeFailed = "CardComposeFailed", --合成
  CardEvolutionSucceed = "CardEvolutionSucceed",  --进化
  CardEvolutionFailed = "CardEvolutionFailed",  --进化
  
  GainTutorialFinishRewardSucceed = "GainTutorialFinishRewardSucceed",
  GainTutorialFinishRewardFailed = "GainTutorialFinishRewardFailed",
  
  DeleteSysEmailSucceed = "DeleteSysEmailSucceed", 
  DeleteSysNoticeSucceed = "DeleteSysNoticeSucceed", 
  DeleteUserEmailSucceed = "DeleteUserEmailSucceed", 
  GetSysEmailMetaSucceed = "GetSysEmailMetaSucceed", --邮件
  GetUserEmailsSucceed = "GetUserEmailsSucceed", 
  ReadSysEmailSucceed = "ReadSysEmailSucceed", 
  ReadSysNoticeSucceed = "ReadSysNoticeSucceed", 
  ReadUserEmailSucceed = "ReadUserEmailSucceed", 
  SendUserEmailSucceed = "SendUserEmailSucceed", 
  GainSysEmailRewardSucceed = "GainSysEmailRewardSucceed",
  GainSysEmailRewardFailed = "GainSysEmailRewardFailed",
  
  ChallengeBabelSucceed = "ChallengeBabelSucceed", --通天塔
  ChallengeBabelFailed = "ChallengeBabelFailed", 
  GainAutoClimbRewardSucceed = "GainAutoClimbRewardSucceed", 
  GainAutoClimbRewardFailed = "GainAutoClimbRewardFailed", 
  GetBabelInfoSucceed = "GetBabelInfoSucceed", 
  GetBabelInfoFailed = "GetBabelInfoFailed", 
  ResetBabelSucceed = "ResetBabelSucceed", 
  ResetBabelFailed = "ResetBabelFailed", 
  StartAutoClimbBabelSucceed = "StartAutoClimbBabelSucceed", 
  StartAutoClimbBabelFailed = "StartAutoClimbBabelFailed", 
  
  --宿命对决
  GetDestinyInfoSucceed = "GetDestinyInfoSucceed",
  GetDestinyInfoFailed = "GetDestinyInfoFailed",
  DestinyBattleSucceed = "DestinyBattleSucceed",
  DestinyBattleFailed = "DestinyBattleFailed",
  --凝神
  SpiritConcentrateSucceed = "SpiritConcentrateSucceed",
  SpiritConcentrateFailed = "SpiritConcentrateFailed",
  
  SellCardsSucceed = "SellCardsSucceed",--卡牌卖出成功
  SellPropSucceed = "SellPropSucceed",--道具卖出成功
  SellEquipsSucceed = "SellEquipsSucceed",--装备卖出成功
  
  ReplaceCardSucceed = "ReplaceCardSucceed",--重整队列成功
  ReplaceCardFailed = "ReplaceCardFailed",--重整队列失败
  AdjustTeamSucceed = "AdjustTeamSucceed",--调整队列成功
  AdjustTeamFailed = "AdjustTeamFailed",--调整队列失败
  
  SetupEquipSucceed = "SetupEquipSucceed",--穿上装备成功
  SetupEquipFailed = "SetupEquipFailed",--穿上装备失败
  
  ChallengeFriendSucceed = "challengeFriendSucceed", --好友切磋成功
  ChallengeFriendFailed = "challengeFriendFailed", --好友切磋失败
  
  GetPlayerTeamInfoSucceed = "GetPlayerTeamInfoSucceed", --获取好友队列信息成功
  
  GetMissionCompleteInfoSucceed = "GetMissionCompleteInfoSucceed",
  BuyMissionCompleteCountSucceed = "BuyMissionCompleteCountSucceed",
  BuyMissionCompleteCountFailed = "BuyMissionCompleteCountFailed",
  GainChapterFinishRewardSucceed = "GainChapterFinishRewardSucceed",
  GainChapterFinishRewardFailed = "GainChapterFinishRewardFailed",
  
  GetCardBookSucceed = "GetCardBookSucceed", -- illustrated card info 获取图鉴信息成功

  
  GetRewardListSucceed = "GetRewardListSucceed", --获取奖励列表信息成功
  GetSingleRewardSucceed = "GetSingleRewardSucceed", --获取单个奖励成功
  GetAllRewardSucceed = "GetAllRewardSucceed", --获取全部奖励成功

  GetCurMonthRewardMetaSucceed = "GetCurMonthRewardMetaSucceed",
  
  GetServerTimeStampSucceed = "GetServerTimeStampSucceed",
  
  GetSigninRewardSucceed = "GetSigninRewardSucceed",
  GetSigninRewardFailed = "GetSigninRewardFailed",
  GetLoginRewardSucceed = "GetLoginRewardSucceed",
  GetLoginRewardFailed = "GetLoginRewardFailed",
  GetContinueLoginRewardSucceed = "GetContinueLoginRewardSucceed",
  GetContinueLoginRewardFailed = "GetContinueLoginRewardFailed",
  GainContinueLoginRewardV2Succeed = "GainContinueLoginRewardV2Succeed",
  GainContinueLoginRewardV2Failed = "GainContinueLoginRewardV2Failed",

  GetActivityOnOffConfigSucceed = "GetActivityOnOffConfigSucceed",
  
  GetEatPeachInfoSucceed = "GetEatPeachInfoSucceed",
  EatPeachSucceed = "EatPeachSucceed",
  EatPeachFailed = "EatPeachFailed",
  
  GainDayRewardSucceed = "GainDayRewardSucceed",
  GainDayRewardFailed = "GainDayRewardFailed",
  
  GetGemConsumeInfoSucceed = "GetGemConsumeInfoSucceed",
  GainGemConsumeRewardsSucceed = "GainGemConsumeRewardsSucceed",

  
  GetCowStageInfoSucceed = "GetCowStageInfoSucceed",
  ChallengeCowStageSucceed = "ChallengeCowStageSucceed",
  ChallengeCowStageFailed = "ChallengeCowStageFailed",
  
  BuyGridSucceed = "BuyGridSucceed",
  BuyGridFailed = "BuyGridFailed",
	
  BuyGoodsSucceed = "BuyGoodsSucceed",
  BuyGoodsFailed = "BuyGoodsFailed",
  
  ValidatePaymentOrderSucceed = "ValidatePaymentOrderSucceed",
  ValidatePaymentOrderFailed = "ValidatePaymentOrderFailed",
  
  UsePropSucceed = "UsePropSucceed",
  UsePropFailed = "UsePropFailed",
  
  GetGachaBroadcastSucceed = "GetGachaBroadcastSucceed",
  GetGachaBroadcastFailed = "GetGachaBroadcastFailed",
  
  GetEliteInfoSucceed = "GetEliteInfoSucceed", --获取精英关卡信息成功
  GetEliteInfoFailed = "GetEliteInfoFailed", --获取精英关卡信息失败
  ChallengeEliteSucceed = "ChallengeEliteSucceed", --精英关卡挑战成功
  ChallengeEliteFailed = "ChallengeEliteFailed", --精英关卡挑战失败
  ResetEliteSucceed = "ResetEliteSucceed", --重置关卡挑战次数成功
  ResetEliteFailed = "ResetEliteFailed", --重置关卡挑战次数失败
  
  BuyEnergySucceed = "BuyEnergySucceed", --购买体力成功
  BuyEnergyFailed = "BuyEnergyFailed", --购买体力失败
  BuyEventPointSucceed = "BuyEventPointSucceed", --购买精力成功
  BuyEventPointFailed = "BuyEventPointFailed", --购买精力失败
  
  UpgradeUserSucceed = "UpgradeUserSucceed", --用户升级成功
  UpgradeUserFailed = "UpgradeUserFailed", --用户升级失败
  
  GetAnnouncementInfoSucceed = "GetAnnouncementInfoSucceed", --获取系统公告信息成功
  GetHomeInfoSucceed = "GetHomeInfoSucceed", --获取主页信息成功
  GetHomeInfoFailed = "GetHomeInfoFailed", --获取主页信息失败
  GetCountdownRewardSucceed = "GetCountdownRewardSucceed", --获取新手礼包成功
  GetCountdownRewardFailed = "GetCountdownRewardFailed", --获取新手礼包失败
  ExchangeGiftBagSucceed = "ExchangeGiftBagSucceed", --兑换礼包成功
  ExchangeGiftBagFailed = "ExchangeGiftBagFailed", --兑换礼包失败
  
  BindAccountSucceed = "BindAccountSucceed"	,	--绑定账号成功
  BindAccountFailed = "BindAccountFailed", --绑定账号失败
  
  GeneNicknameSucceed = "GeneNicknameSucceed", -- 随机生成可用用户昵称成功
  GeneNicknameFailed = "GeneNicknameFailed", -- 随机生成可用用户昵称失败
  
  GetRobUserListSucceed = "GetRobUserListSucceed",
  GetRobUserListFailed = "GetRobUserListFailed",
  RobBeastFragmentSucceed = "RobBeastFragmentSucceed",
  RobBeastFragmentFailed = "RobBeastFragmentFailed",
	
	GetSharkBeastFragmentsSucceed = "GetSharkBeastFragmentsSucceed",
	GetSharkBeastFragmentsFailed = "GetSharkBeastFragmentsFailed",
	AvoidBattleSucceed = "AvoidBattleSucceed",
	AvoidBattleFailed = "AvoidBattleFailed",
	AdjustBeastSucceed = "AdjustBeastSucceed",
	AdjustBeastFailed = "AdjustBeastFailed",
	FinishBeastComposeSucceed = "FinishBeastComposeSucceed",
	FinishBeastComposeFailed = "FinishBeastComposeFailed",
	StartComposeBeastSucceed = "StartComposeBeastSucceed",
	StartComposeBeastFailed = "StartComposeBeastFailed",
	GetSharkBeastsSucceed = "GetSharkBeastsSucceed",
	GetSharkBeastsFailed = "GetSharkBeastsFailed",
  
  ClearMissionSucceed = "ClearMissionSucceed",
  ClearMissionFailed = "ClearMissionFailed",
  ResetClearTimeSucceed = "ResetClearTimeSucceed",
  ResetClearTimeFailed = "ResetClearTimeFailed",
  
  --anti addiction 
  RecordAddictedTimeSucceed = "RecordAddictedTimeSucceed",
  RecordAddictedTimeFailed = "RecordAddictedTimeFailed",
  
  --world boss
  getWorldBossInfoSuccessd = "getWorldBossInfoSuccessd",
  getWorldBossInfoFailed = "getWorldBossInfoFailed",
  challengeWorldBossSuccessd = "challengeWorldBossSuccessd",
  challengeWorldBossFailed = "challengeWorldBossFailed",
  gainWorldBossRewardsSuccessd = "gainWorldBossRewardsSuccessd",
  gainWorldBossRewardsFailed = "gainWorldBossRewardsFailed",
  inspireInWorldBossSuccessd = "inspireInWorldBossSuccessd",
  inspireInWorldBossFailed = "inspireInWorldBossFailed",
  setAutoWorldBossSuccessd = "setAutoWorldBossSuccessd",
  setAutoWorldBossFailed = "setAutoWorldBossFailed",
  
  
  
	
	GainChargeMoneyRewardSucceed = "GainChargeMoneyRewardSucceed",
	GainChargeMoneyRewardFailed = "GainChargeMoneyRewardFailed",
  
  --level race activity
  GetLevelRaceInfoSucceed = "GetLevelRaceInfoSucceed",
  GetLevelRaceInfoFailed = "GetLevelRaceInfoFailed",
  GainLevelRaceRewardsSucceed = "GainLevelRaceRewardsSucceed",
  GainLevelRaceRewardsFailed = "GainLevelRaceRewardsFailed",
  
  --gacha points activity
  GetGachaPointsInfoSucceed = "GetGachaPointsInfoSucceed",
  GetGachaPointsInfoFailed = "GetGachaPointsInfoFailed",
  GainGachaPointsRewardsSucceed = "GainGachaPointsRewardsSucceed",
  GainGachaPointsRewardsFailed = "GainGachaPointsRewardsFailed",
  
  --newyear recharge activity
  GainNewYearRewardsSucceed = "GainNewYearRewardsSucceed",
  GainNewYearRewardsFailed = "GainNewYearRewardsFailed",
  
  --month card activity
  GainMonthCardSucceed = "GainMonthCardSucceed",
  GainMonthCardFailed = "GainMonthCardFailed",
  GetBuyMonthCardResultSucceed = "GetBuyMonthCardResultSucceed",
  GetBuyMonthCardResultFailed = "GetBuyMonthCardResultFailed",
  
  --lottery fortune activity
  GainFortuneRewardsSucceed = "GainFortuneRewardsSucceed",
  GainFortuneRewardsFailed = "GainFortuneRewardsFailed",
  
  --gold god activity
  GainGoldGodRewardsSucceed = "GainGoldGodRewardsSucceed",
  GainGoldGodRewardsFailed = "GainGoldGodRewardsFailed",
  
  --银币活动
  GetSilverDiceInfoSucceed = "GetSilverDiceInfoSucceed",
  GetSilverDiceInfoFailed = "GetSilverDiceInfoFailed",
  ThrowDiceSucceed = "ThrowDiceSucceed",
  ThrowDiceFailed = "ThrowDiceFailed",
  GainThrowDiceSucceed = "GainThrowDiceSucceed",
  GainThrowDiceFailed = "GainThrowDiceFailed",
  ChangeThrowDiceLuckSucceed = "ChangeThrowDiceLuckSucceed",
  ChangeThrowDiceLuckFailed = "ChangeThrowDiceLuckFailed",
	ReplaceMatrixGridSucceed = "ReplaceMatrixGridSucceed",
	ReplaceMatrixGridFailed = "ReplaceMatrixGridFailed",
	UpgradeMatrixSucceed = "UpgradeMatrixSucceed",
	UpgradeMatrixFailed = "UpgradeMatrixFailed",

  --fireworks activity
  FireworksFireSucceed = "FireworksFireSucceed",
  FireworksFireFailed = "FireworksFireFailed",
	
	SynthetizeItemSucceed = "SynthetizeItemSucceed",
  SynthetizeItemFailed = "SynthetizeItemFailed",
  
  --multiplayer activity
  GetMultiplayserBossInfoSucceed = "GetMultiplayserBossInfoSucceed",
  GetMultiplayserBossInfoFailed = "GetMultiplayserBossInfoFailed",
  GainMultiplayerBossRankRewardSucceed = "GainMultiplayerBossRankRewardSucceed",
  GainMultiplayerBossRankRewardFailed = "GainMultiplayerBossRankRewardFailed",
  GetMultiplayerBossRankSucceed = "GetMultiplayerBossRankSucceed",
  GetMultiplayerBossRankFailed = "GetMultiplayerBossRankFailed",
  GetMultiplayerBossDamageSucceed = "GetMultiplayerBossDamageSucceed",
  GetMultiplayerBossDamageFailed = "GetMultiplayerBossDamageFailed",
  GainMultiplayerBossParticipationRewardSucceed = "GainMultiplayerBossParticipationRewardSucceed",
  GainMultiplayerBossParticipationRewardFailed = "GainMultiplayerBossParticipationRewardFailed",
  ChallengeMultiplayerBossSucceed = "ChallengeMultiplayerBossSucceed",
  ChallengeMultiplayerBossFailed = "ChallengeMultiplayerBossFailed",
  BuyActionPowerSucceed = "BuyActionPowerSucceed",
  BuyActionPowerFailed = "BuyActionPowerFailed",
  GetMultiplayerBossLeftHpSucceed = "GetMultiplayerBossLeftHpSucceed",
  GetMultiplayerBossLeftHpFailed = "GetMultiplayerBossLeftHpFailed",
  
  --sworn activity
  SwornRewardGainSucceed = "SwornRewardGainSucceed",
  SwornRewardGainFailed = "SwornRewardGainFailed",
	
	--new babel
	GetSkyTowerInfoSucceed = "GetSkyTowerInfoSucceed",
  GetSkyTowerInfoFailed = "GetSkyTowerInfoFailed",
	ChallengeSkyTowerSucceed = "ChallengeSkyTowerSucceed",
  ChallengeSkyTowerFailed = "ChallengeSkyTowerFailed",
	GainYesterdayAdditionSucceed = "GainYesterdayAdditionSucceed",
  GainYesterdayAdditionFailed = "GainYesterdayAdditionFailed",
	GainFloorAdditionSucceed = "GainFloorAdditionSucceed",
  GainFloorAdditionFailed = "GainFloorAdditionFailed",
	GainRankRewardsSucceed = "GainRankRewardsSucceed",
  GainRankRewardsFailed = "GainRankRewardsFailed",
  ResetClimbTowerSucceed = "ResetClimbTowerSucceed",
  ResetClimbTowerFailed = "ResetClimbTowerFailed",
  
  --fragment
  FragmentSynthetizeCardSucceed = "FragmentSynthetizeCardSucceed",
  FragmentSynthetizeCardFailed = "FragmentSynthetizeCardFailed",
  FragmentSynthetizeEquipSucceed = "FragmentSynthetizeEquipSucceed",
  FragmentSynthetizeEquipFailed = "FragmentSynthetizeEquipFailed",
  PrayCardFragmentSucceed = "PrayCardFragmentSucceed",
  PrayCardFragmentFailed = "PrayCardFragmentFailed",

  --treasurebox activity
  TreasureboxPointsInfoGetSucceed = "TreasureboxPointsInfoGetSucceed",
  TreasureboxPointsInfoGetFailed = "TreasureboxPointsInfoGetFailed",
  TreasureboxGainRankRewardSucceed = "TreasureboxGainRankRewardSucceed",
  TreasureboxGainRankRewardFailed = "TreasureboxGainRankRewardFailed",
  TreasureboxGainPointRewardSucceed = "TreasureboxGainPointRewardSucceed",
  TreasureboxGainPointRewardFailed = "TreasureboxGainPointRewardFailed",

  --小秘书
  GetDailyActiveInfoSucceed = "GetDailyActiveInfoSucceed",
  GetDailyActiveInfoFailed = "GetDailyActiveInfoFailed",
  ActiveRewardSucceed = "ActiveRewardSucceed",
  ActiveRewardFailed = "ActiveRewardFailed",
  
   --PK
  PKGetPkInfoSucceed = "GetPkInfoSucceed",
  PKGetPkInfoFailed = "GetPkInfoFailed",
  PKChallengePkUserSucceed = "PKChallengePkUserSucceed",
  PKChallengePkUserFailed = "PKChallengePkUserFailed",
  PKGainPkBuffSucceed = "PKGainPkBuffSucceed",
  PKGainPkBuffFailed = "PKGainPkBuffFailed",
  PKGetPkFoesSucceed = "PKGetPkFoesSucceed",
  PKGetPkFoesFailed = "PKGetPkFoesFailed",
  PKGetPkTopRankUsersSucceed = "PKGetPkTopRankUsersSucceed",
  PKGetPkTopRankUsersFailed = "PKGetPkTopRankUsersFailed",
  PKGainPkRewardsSucceed = "PKGainPkRewardsSucceed",
  PKGainPkRewardsFailed = "PKGainPkRewardsFailed",
  --monthcard
  GetAccumulateGemsSucceed = "GetAccumulateGemsSucceed",
  BuyMonthGemCardSucceed = "BuyMonthGemCardSucceed",
  BuyMonthGemCardFailed = "BuyMonthGemCardFailed",
  --点赞活动
  GetRecordPraiseIdSucceed = "GetRecordPraiseIdSucceed",
  GetRecordPraiseIdFailed = "GetRecordPraiseIdFailed",
  GainPraiseRewardSucceed = "GainPraiseRewardSucceed",
  GainPraiseRewardFailed = "GainPraiseRewardFailed",
  
  --IM
  GetSocketServerSucceed = "GetSocketServerSucceed",
  GetSocketServerFailed = "GetSocketServerFailed",

  --union 军团
  UnionCreateSucceed = "UnionCreateSucceed",
  UnionCreateFailed = "UnionCreateFailed",
  UnionGetUnionListSucceed = "UnionGetUnionListSucceed",
  UnionGetUnionListFailed = "UnionGetUnionListFailed",
  UnionGetMyApplyListSucceed = "UnionGetMyApplyListSucceed",
  UnionGetMyApplyListFailed = "UnionGetMyApplyListFailed",
  UnionApplySucceed = "UnionApplySucceed",
  UnionApplyFailed = "UnionApplyFailed",
  UnionSearchSucceed = "UnionSearchSucceed",
  UnionSearchFailed = "UnionSearchFailed",
  UnionCancelApplySucceed = "UnionCancelApplySucceed",
  UnionCancelApplyFailed = "UnionCancelApplyFailed",
  UnionGetUnionInfoSucceed = "UnionGetUnionInfoSucceed",
  UnionGetUnionInfoFailed = "UnionGetUnionInfoFailed",
  UnionDissolveSucceed = "UnionDissolveSucceed",
  UnionDissolveFailed = "UnionDissolveFailed",
  GetUnionBuildingShopInfoSucceed = "GetUnionBuildingShopInfoSucceed",
  GetUnionBuildingShopInfoFailed = "GetUnionBuildingShopInfoFailed",
  UnionAcceptSucceed = "UnionAcceptSucceed",
  UnionAcceptFailed = "UnionAcceptFailed",
  UnionRejectSucceed = "UnionRejectSucceed",
  UnionRejectFailed = "UnionRejectFailed",
  UnionGetApplierListSucceed = "UnionGetApplierListSucceed",
  UnionGetApplierListFailed = "UnionGetApplierListFailed",
  BuyUnionPropSucceed = "BuyUnionPropSucceed",
  BuyUnionPropFailed = "BuyUnionPropFailed",
  GetUnionBuildingBankInfoSucceed = "GetUnionBuildingBankInfoSucceed",
  GetUnionBuildingBankInfoFailed = "GetUnionBuildingBankInfoFailed",
  GetUnionBuildingHallInfoSucceed = "GetUnionBuildingHallInfoSucceed",
  GetUnionBuildingHallInfoFailed = "GetUnionBuildingHallInfoFailed",
  UnionCancelDissolveSucceed = "UnionCancelDissolveSucceed",
  UnionCancelDissolveFailed = "UnionCancelDissolveFailed",
  UnionGetMemberListSucceed = "UnionGetMemberListSucceed",
  UnionGetMemberListFailed = "UnionGetMemberListFailed",
  UnionRejectAllSucceed = "UnionRejectAllSucceed",
  UnionRejectAllFailed = "UnionRejectAllFailed",
  UnionTransferSucceed = "UnionTransferSucceed",
  UnionTransferFailed = "UnionTransferFailed",
  UnionCancelTransferSucceed = "UnionCancelTransferSucceed",
  UnionCancelTransferFailed = "UnionCancelTransferFailed",
  UnionImpeachSucceed = "UnionImpeachSucceed",
  UnionImpeachFailed = "UnionImpeachFailed",
  UnionAppointSucceed = "UnionAppointSucceed",
  UnionAppointFailed = "UnionAppointFailed",
  UnionKickSucceed = "UnionKickSucceed",
  UnionKickFailed = "UnionKickFailed",
  UnionQuitSucceed = "UnionQuitSucceed",
  UnionQuitFailed = "UnionQuitFailed",
  ReceiveUnionWageSucceed = "ReceiveUnionWageSucceed",
  ReceiveUnionWageFailed = "ReceiveUnionWageFailed",
  UnionGetMyDataSucceed = "UnionGetMyDataSucceed",
  UnionGetMyDataFailed = "UnionGetMyDataFailed",
  UnionBuildingUpgradeSucceed = "UnionBuildingUpgradeSucceed",
  UnionBuildingUpgradeFailed = "UnionBuildingUpgradeFailed",
  UnionConstructUnionSucceed = "UnionConstructUnionSucceed",
  UnionConstructUnionFailed = "UnionConstructUnionFailed",
  UnionChangeNoticeSucceed = "UnionChangeNoticeSucceed",
  UnionChangeNoticeFailed = "UnionChangeNoticeFailed",
  UnionChangeDeclarationSucceed = "UnionChangeDeclarationSucceed",
  UnionChangeDeclarationFailed = "UnionChangeDeclarationFailed",
  UnionGetNewsSucceed = "UnionGetNewsSucceed",
  UnionGetNewsFailed = "UnionGetNewsFailed",
  --军团斗兽场
  UnionColosseumSummonSucceed = "UnionColosseumSummonSucceed",
  UnionColosseumSummonFailed = "UnionColosseumSummonFailed",
  UnionColosseumChallengeSucceed = "UnionColosseumChallengeSucceed",
  UnionColosseumChallengeFailed = "UnionColosseumChallengeFailed",
  UnionColosseumGetRankSucceed = "UnionColosseumGetRankSucceed",
  UnionColosseumGetRankFailed = "UnionColosseumGetRankFailed",
  UnionColosseumStartAllocationSucceed = "UnionColosseumStartAllocationSucceed",
  UnionColosseumStartAllocationFailed = "UnionColosseumStartAllocationFailed",
  UnionColosseumGiveUpAllocationSucceed = "UnionColosseumGiveUpAllocationSucceed",
  UnionColosseumGiveUpAllocationFailed = "UnionColosseumGiveUpAllocationFailed",
  UnionColosseumBuildingInfoSucceed = "UnionColosseumBuildingInfoSucceed",
  UnionColosseumBuildingInfoFailed = "UnionColosseumBuildingInfoFailed",
  --邀请码活动
  GainInviteRewardSucceed = "GainInviteRewardSucceed",
  GainInviteRewardFailed = "GainInviteRewardFailed",
  GainInvitedRewardSucceed = "GainInvitedRewardSucceed",
  GainInvitedRewardFailed = "GainInvitedRewardFailed",
  GetInvitationInfoSucceed = "GetInvitationInfoSucceed",
  GetInvitationInfoFailed = "GetInvitationInfoFailed",
  --扭蛋池活动
  GachaCardByBoxSucceed = "GachaCardByBoxSucceed",
  GachaCardByBoxFailed = "GachaCardByBoxFailed",
  GetSharkGachaBoxInfoSucceed = "GetSharkGachaBoxInfoSucceed",
  GetSharkGachaBoxInfoFailed = "GetSharkGachaBoxInfoFailed",
  RefreshGachaBoxSucceed = "RefreshGachaBoxSucceed",
  RefreshGachaBoxFailed = "RefreshGachaBoxFailed",
  
  -- 重生祭炼
  ItemRebirthSucceed = "ItemRebirthSucceed",
  ItemRebirthFailed = "ItemRebirthFailed",
  ItemSacrificeSucceed = "ItemSacrificeSucceed",
  ItemSacrificeFailed = "ItemSacrificeFailed",
  --神秘商店
  GetSecretShopListSucceed = "GetSecretShopListSucceed",
  GetSecretShopListFailed = "GetSecretShopListFailed",
  ExchangeSecretShopSucceed = "ExchangeSecretShopSucceed",
  ExchangeSecretShopFailed = "ExchangeSecretShopFailed",
  RefreshSecretShopSucceed = "RefreshSecretShopSucceed",
  RefreshSecretShopFailed = "RefreshSecretShopFailed",

  --卡牌经验强化
  UpgradeCardByGeneralExpSucceed = "UpgradeCardByGeneralExpSucceed",
  UpgradeCardByGeneralExpFailed = "UpgradeCardByGeneralExpFailed",
  
  ChallengeContendSucceed = "ChallengeContendSucceed",
  ChallengeContendFailed = "ChallengeContendFailed",
  
  --seckill限时秒杀
  SeckillGetInfoSucceed = "SeckillGetInfoSucceed",
  SeckillGetInfoFailed = "SeckillGetInfoFailed",
  SeckillBuySucceed = "SeckillBuySucceed",
  SeckillBuyFailed = "SeckillBuyFailed",
  
  --achievement
  GetAchievementsSucceed = "GetAchievementsSucceed",
  GainAchievementRewardSucceed = "GainAchievementRewardSucceed",
  GainAchievementRewardFailed = "GainAchievementRewardFailed",

  --元神
  BuySpiritPoolSucceed = "BuySpiritPoolSucceed",
  BuySpiritPoolFailed = "BuySpiritPoolFailed",
  EquipSpiritSucceed = "EquipSpiritSucceed",
  EquipSpiritFailed = "EquipSpiritFailed",
  RefreshSubAttributeSucceed = "RefreshSubAttributeSucceed",
  RefreshSubAttributeFailed = "RefreshSubAttributeFailed",
  SellSpiritSucceed = "SellSpiritSucceed",
  SellSpiritFailed = "SellSpiritFailed",
  UnequipSpiritSucceed = "UnequipSpiritSucceed",
  UnequipSpiritFailed = "UnequipSpiritFailed",
  UnlockSubAttributeSucceed = "UnlockSubAttributeSucceed",
  UnlockSubAttributeFailed = "UnlockSubAttributeFailed",
  UpgradeSpiritSucceed = "UpgradeSpiritSucceed",
  UpgradeSpiritFailed = "UpgradeSpiritFailed",
  SelectSubAttributeSucceed = "SelectSubAttributeSucceed",
  SelectSubAttributeFailed = "SelectSubAttributeFailed",

  --new email
  EmailBatchDeleteRewardEmailSucceed = "EmailBatchDeleteRewardEmailSucceed",
  EmailBatchDeleteRewardEmailFailed = "EmailBatchDeleteRewardEmailFailed",
  EmailBatchDeleteSysEmailSucceed = "EmailBatchDeleteSysEmailSucceed",
  EmailBatchDeleteSysEmailFailed = "EmailBatchDeleteSysEmailFailed",
  EmailBatchDeleteSysNoticeSucceed = "EmailBatchDeleteSysNoticeSucceed",
  EmailBatchDeleteSysNoticeFailed = "EmailBatchDeleteSysNoticeFailed",
  EmailBatchDeleteUserEmailSucceed = "EmailBatchDeleteUserEmailSucceed",
  EmailBatchDeleteUserEmailFailed = "EmailBatchDeleteUserEmailFailed",
  EmailGainRewardEmailRewardSucceed = "EmailGainRewardEmailRewardSucceed",
  EmailGainRewardEmailRewardFailed = "EmailGainRewardEmailRewardFailed",
  EmailReadRewardEmailSucceed = "EmailReadRewardEmailSucceed",
  EmailReadRewardEmailFailed = "EmailReadRewardEmailFailed",
  
  --across fight
  GetCrossPkInfoSucceed = "GetCrossPkInfoSucceed",
  GetCrossPkInfoFailed = "GetCrossPkInfoFailed",
  GetCrossPkReportSucceed = "GetCrossPkReportSucceed",
  GetCrossPkReportFailed = "GetCrossPkReportFailed",
  GainCrossPkRankRewardSucceed = "GainCrossPkRankRewardSucceed",
  GainCrossPkRankRewardFailed = "GainCrossPkRankRewardFailed",
  GainCrossPkGuessRewardSucceed = "GainCrossPkGuessRewardSucceed",
  GainCrossPkGuessRewardFailed = "GainCrossPkGuessRewardFailed",
  GainCrossPkServerRewardSucceed = "GainCrossPkServerRewardSucceed",
  GainCrossPkServerRewardFailed = "GainCrossPkServerRewardFailed",
  GetCrossPkCapacitySucceed = "GetCrossPkCapacitySucceed",
  GetCrossPkCapacityFailed = "GetCrossPkCapacityFailed",
  GuessCrossPkRankSucceed = "GuessCrossPkRankSucceed",
  GuessCrossPkRankFailed = "GuessCrossPkRankFailed",
  
  --改名协议
  ChangeNameSucceed = "ChangeNameSucceed",
  ChangeNameFailed = "ChangeNameFailed",

  --话费充值
  PhoneChargeSetNumSucceed = "PhoneChargeSetNumSucceed",
  PhoneChargeSetNumFailed = "PhoneChargeSetNumFailed",
  PhoneChargeGainSucceed = "PhoneChargeGainSucceed",
  PhoneChargeGainFailed = "PhoneChargeGainFailed",
  PhoneChargeGetInfoSucceed = "PhoneChargeGetInfoSucceed",
  PhoneChargeGetInfoFailed = "PhoneChargeGetInfoFailed",

  -- --军团战 UI
  -- UnionPkGetCityListSucceed = "UnionPkGetCityListSucceed",
  -- UnionPkGetCityListFailed = "UnionPkGetCityListFailed",
  -- UnionPkGetCityInfoSucceed = "UnionPkGetCityInfoSucceed",
  -- UnionPkGetCityInfoFailed = "UnionPkGetCityInfoFailed",
  -- UnionPkSignAttackSucceed = "UnionPkSignAttackSucceed",
  -- UnionPkSignAttackFailed = "UnionPkSignAttackFailed",
  -- UnionPkMemberApplySucceed = "UnionPkMemberApplySucceed",
  -- UnionPkMemberApplyFailed = "UnionPkMemberApplyFailed",
  -- Succeed = "Succeed",
  -- Failed = "Failed",
  -- Succeed = "Succeed",
  -- Failed = "Failed",

  --请求是否禁言的状态
  SpeakLimitStutasSucceed = "SpeakLimitStutasSucceed",
  SpeakLimitStutasFailed = "SpeakLimitStutasFailed",

  --每日首充
  GetRechargeInfoSucceed = "GetRechargeInfoSucceed",
  GetRechargeInfoFailed = "GetRechargeInfoFailed",

  GainRechargeRewardSucceed = "GainRechargeRewardSucceed",
  GainRechargeRewardFailed = "GainRechargeRewardFailed",
  
    --lock card
  LockCardSucceed = "LockCardSucceed",
  LockCardFailed = "LockCardFailed",

  --通天塔 跳过
  SkyTowerSkipBattleSucceed = "SkyTowerSkipBattleSucceed",
  SkyTowerSkipBattleFailed = "SkyTowerSkipBattleFailed",

  SkyTowerSkipGainAddSucceed = "SkyTowerSkipGainAddSucceed",
  SkyTowerSkipGainAddFailed = "SkyTowerSkipGainAddFailed",

  SkyTowerSkipGainRewardsSucceed = "SkyTowerSkipGainRewardsSucceed",
  SkyTowerSkipGainRewardsFailed = "SkyTowerSkipGainRewardsFailed",

  --元神刷新复选框
  SetSpiritRefreshAutoSaveSucceed = "SetSpiritRefreshAutoSaveSucceed",
  SetSpiritRefreshAutoSaveFailed = "SetSpiritRefreshAutoSaveFailed",

  --更换卡牌头像
  AdjustCardAvatarSucceed = "AdjustCardAvatarSucceed",
  AdjustCardAvatarFailed = "AdjustCardAvatarFailed",
  --投放马 刷新
  WantedActivityRefreshTaskRequestSucceed = "WantedActivityRefreshTaskRequestSucceed",
  WantedActivityRefreshTaskRequestFailed = "WantedActivityRefreshTaskRequestFailed",

  --投放马 挑战
  WantedActivityChallengeRequestSucceed  = "WantedActivityChallengeRequestSucceed",
  WantedActivityChallengeRequestFailed = "WantedActivityChallengeRequestFailed",

  --投放马 兑换
  WantedActivityExchangeRequestSucceed = "WantedActivityExchangeRequestSucceed",
  WantedActivityExchangeRequestFailed = "WantedActivityExchangeRequestFailed",

  --投放马 请求活动数据
  WantedActivityGetWantedInfoRequestSucceed = "WantedActivityGetWantedInfoRequestSucceed",
  WantedActivityGetWantedInfoRequestFailed = "WantedActivityGetWantedInfoRequestFailed",

  --每日任务
  GetTaskInfoSucceed = "GetTaskInfoSucceed",
  GetTaskInfoFailed = "GetTaskInfoFailed",
  GainDailyTaskRewardSucceed = "GainDailyTaskRewardSucceed",
  GainDailyTaskRewardFailed = "GainDailyTaskRewardFailed",

  --充值反馈
  GetChargeFeedbackRewardSucceed = "GetChargeFeedbackRewardSucceed",
  GetChargeFeedbackRewardFailed = "GetChargeFeedbackRewardFailed",

  --猜题活动 回答问题
  QuestionActAnswerRequestSucceed = "QuestionActAnswerRequestSucceed",
  QuestionActAnswerRequestFailed = "QuestionActAnswerRequestFailed",

  --猜题活动 获取每日答题信息
  QuestionActGetStateRequestSucceed = "QuestionActGetStateRequestSucceed",
  QuestionActGetStateRequestFailed = "QuestionActGetStateRequestFailed",

  --猜题活动 获取每日奖励
  QuestionActDailyRewardRequestSucceed = "QuestionActDailyRewardRequestSucceed",
  QuestionActDailyRewardRequestFailed = "QuestionActDailyRewardRequestFailed",

  --猜题活动 获取周奖励
  QuestionActWeekRewardRequestSucceed = "QuestionActWeekRewardRequestSucceed",
  QuestionActWeekRewardRequestFailed = "QuestionActWeekRewardRequestFailed",

  --周一大礼包
  GainMondayRewardSucceed = "GainMondayRewardSucceed",
  GainMondayRewardFailed = "GainMondayRewardFailed",

  -- 吹气球
  BlowBalloonActBuyEnegyRequestSucceed = "BlowBalloonActBuyEnegyRequestSucceed",
  BlowBalloonActBuyEnegyRequestFailed = "BlowBalloonActBuyEnegyRequestFailed",

  BlowBalloonActGetEnegyRequestSucceed = "BlowBalloonActGetEnegyRequestSucceed",
  BlowBalloonActGetEnegyRequestFailed = "BlowBalloonActGetEnegyRequestFailed",

  BlowBalloonActGainMagicValueRequestSucceed = "BlowBalloonActGainMagicValueRequestSucceed",
  BlowBalloonActGainMagicValueRequestFailed = "BlowBalloonActGainMagicValueRequestFailed",

  BlowBalloonActGetMagicRewardRequestSucceed = "BlowBalloonActGetMagicRewardRequestSucceed",
  BlowBalloonActGetMagicRewardRequestFailed = "BlowBalloonActGetMagicRewardRequestFailed",

  BlowBalloonActGetRankRewardRequestSucceed = "BlowBalloonActGetRankRewardRequestSucceed",
  BlowBalloonActGetRankRewardRequestFailed = "BlowBalloonActGetRankRewardRequestFailed",

  BlowBalloonActInfoRequestSucceed = "BlowBalloonActInfoRequestSucceed",
  BlowBalloonActInfoRequestFailed = "BlowBalloonActInfoRequestFailed",

  --缘分互通
  SetCardGroupInterworkingSucceed = "SetCardGroupInterworkingSucceed",
  SetCardGroupInterworkingFailed = "SetCardGroupInterworkingFailed",
  
  --账号绑定邮箱更改
  EmailChangeSucceed = "EmailChangeSucceed",
  EmailChangeFailed = "EmailChangeFailed",
  
  --武将拆解
  SplitCardSucceed = "SplitCardSucceed",
  SplitCardFailed = "SplitCardFailed",
  
  --圣诞活动 请求挑战
  MerryChristmasChallengeRequestSucceed = "MerryChristmasChallengeRequestSucceed",
  MerryChristmasChallengeRequestFailed  = "MerryChristmasChallengeRequestFailed",

  MerryChristmasResetRequestSucceed = "MerryChristmasResetRequestSucceed",
  MerryChristmasResetRequestFailed = "MerryChristmasResetRequestFailed",

  --跨服世界boss
  GetCrossBossInfoSucceed = "GetCrossBossInfoSucceed",
  GetCrossBossInfoFailed = "GetCrossBossInfoFailed",
  RefreshCrossBossBattlePhaseSucceed = "RefreshCrossBossBattlePhaseSucceed",
  RefreshCrossBossBattlePhaseFailed = "RefreshCrossBossBattlePhaseFailed",
  ChallengeCrossBossSucceed = "ChallengeCrossBossSucceed",
  ChallengeCrossBossFailed = "ChallengeCrossBossFailed",
  InspireCrossBossTeamSucceed = "InspireCrossBossTeamSucceed",
  InspireCrossBossTeamFailed = "InspireCrossBossTeamFailed",
  GainCrossBossRewardSucceed = "GainCrossBossRewardSucceed",
  GainCrossBossRewardFailed = "GainCrossBossRewardFailed",
  GetCrossBossRankInfoSucceed = "GetCrossBossRankInfoSucceed",
  GetCrossBossRankInfoFailed = "GetCrossBossRankInfoFailed",
  
    --facebook share触发式
  ShareFacebookTriggerSucceed = "ShareFacebookTriggerSucceed",
  ShareFacebookTriggerFailed = "ShareFacebookTriggerFailed",
  --facebook share活动式
  ShareFacebookActivitySucceed = "ShareFacebookActivitySucceed",
  ShareFacebookActivityFailed = "ShareFacebookActivityFailed",
  --facebook invite friend
  FacebookInviteFriendSucceed = "FacebookInviteFriendSucceed",
  FacebookInviteFriendFailed = "FacebookInviteFriendFailed",
  --facebook gain activity reward 
  FacebookGainActivityRewardSucceed = "FacebookGainActivityRewardSucceed",
  FacebookGainActivityRewardFailed = "FacebookGainActivityRewardFailed",

  --分配红包
  DistributeBonusSucceed = "DistributeBonusSucceed",
  DistributeBonusFailed = "DistributeBonusFailed",
  GetBonusAccepterListSucceed = "GetBonusAccepterListSucceed",
  GetBonusAccepterListFailed = "GetBonusAccepterListFailed",
  
  --跨服Gacha 小玉嫁到
  GetCrossGachaInfoSucceed = "GetCrossGachaInfoSucceed",
  GetCrossGachaInfoFailed = "GetCrossGachaInfoFailed",
  CrossGachaGainPointRewardSucceed = "CrossGachaGainPointRewardSucceed",
  CrossGachaGainPointRewardFailed = "CrossGachaGainPointRewardFailed",
  CrossGachaGainRankRewardSucceed = "CrossGachaGainRankRewardSucceed",
  CrossGachaGainRankRewardFailed = "CrossGachaGainRankRewardFailed",
  --限时充值
  GetActiveEnterRechangeSucceed = "GetActiveEnterRechangeSucceed", 
  GetActiveEnterRechangeFailed = "GetActiveEnterRechangeFailed",
  --易帅换将日常版 刷新
  ActiverefreshCardSucceed = "ActiverefreshCardSucceed",
  ActiverefreshCardFailed = "ActiverefreshCardFailed",
  --跨服pvp
  ChallengeCrossUserSucceed = "ChallengeCrossUserSucceed",
  ChallengeCrossUserFailed = "ChallengeCrossUserFailed",
  RefreshMatchSucceed = "RefreshMatchSucceed",
  RefreshMatchFailed = "RefreshMatchFailed",

     --lock Treasures
  LockTreasuresSucceed = "LockTreasuresSucceed",
  LockTreasuresFailed = "LockTreasuresFailed",

}

BaseRequest = class(EventDispatcher)

function BaseRequest:ctor(params, priority)
	self.params = params
	self.priority = priority
  self.delayLoading = false
  self.communicating = false
  self.delayHandler = nil
  self.showLoading = true
  self.enableTouch = false
  self.needRetry = true
end

function BaseRequest:onSuccess(data)
	he_log_info(self.endpoint .. " request success")
end

function BaseRequest:onError(err)
	he_log_error(self.endpoint .. " request error " .. err)
	CCMessageBox(self.endpoint .. " request error", err)
end

local errorCodeSet = {
  710203,
  710204,
  710404,
  710403,
  710513,
  710549,
  710515,
  710204,
  710203,
  710071,
  710544,
  710548,
  710549,
  711051,
  711059,
  713608,
  714000,
  714103,
  714105,
  716373,
  710503,
  710206,
  710203,
}

function BaseRequest:start()
  self.communicating = true
  if self.showLoading then
    RequestLoadingBox:createLoadingBox(self.enableTouch)
    if self.delayLoading then
      local function showLoadingBox()
        if self.communicating then
          CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.delayHandler)
          RequestLoadingBox:showLoadingBox()
        end
      end
      self.delayHandler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(showLoadingBox, 1.0 ,false);
    else
      RequestLoadingBox:showLoadingBox()
    end
  end
	if self.params == nil then
		self.params = {}
	end
  
	self.params["serverId"] = DataManager.getServerid()
	Communication:getInstance():request(self.endpoint, self.params, 
		function(endpoint, data, err)
      self.communicating = false
      if self.showLoading then
        if self.delayHandler then
          CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.delayHandler)
          self.delayHandler = nil
        end
        RequestLoadingBox:removeLoadingBox()
      end
			if err then
        --这里如果直接弹窗，在某些场景可能会有问题，所以先把这个“错误码优化”的功能注销掉
        -- for k,v in pairs(errorCodeSet) do
        --   if not self.params.DoNotCaptureFailueMessage and v == err then
        --     CanonMessageBox:showSpecialErrorBox( ShowErrorCodeType.EC_COMMON )
        --     return true
        --   end
        -- end

        -- if not self.params.DoNotCaptureFailueMessage and err == 710516 then
        --   CanonMessageBox:showSpecialErrorBox( ShowErrorCodeType.EC_GRID_NOT_ENOUGH )
        --   return true
        -- elseif not self.params.DoNotCaptureFailueMessage and err == 710514 then
        --   CanonMessageBox:showSpecialErrorBox( ShowErrorCodeType.EC_REQUISITE_ENERGY_NOT_ENOUGH )
        --   return true
        -- elseif not self.params.DoNotCaptureFailueMessage and err == 716493 then
        --   CanonMessageBox:showSpecialErrorBox( ShowErrorCodeType.EC_ACHIEVEMENT_REWARD_NOT_EXIST )
        --   return true
        -- elseif not self.params.DoNotCaptureFailueMessage and err == 716371 then
        --   CanonMessageBox:showSpecialErrorBox( ShowErrorCodeType.EC_RECEIVE_WAGE_AT_WRONG_TIME )
        --   return true
        -- end
				self:onError(err)
				return true
			end
			self:onSuccess(data)
		end, self.priority, self.needRetry)
end
