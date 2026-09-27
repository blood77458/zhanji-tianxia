--------------------------------------------------------------------------------
-- CommErrorCodes.lua - 通讯错误码
-- author: xiaojie.bai
-- date: 2013-08-30 11:00
--------------------------------------------------------------------------------

SHARK_ERROCODE_ORIGH = 710000 -- shark游戏错误码起始值

CommErrorCodes = {}

CommErrorCodes.USER_NOT_EXIST = {code = SHARK_ERROCODE_ORIGH + 70, textKey = "EC_USER_NOT_EXIST_TXT"}

--用户注册相关
CommErrorCodes.NICKNAME_IS_NULL = {code = SHARK_ERROCODE_ORIGH + 73, textKey = "login_popup_nicknameIsNull"}
CommErrorCodes.NICKNAME_IS_INVALID = {code = SHARK_ERROCODE_ORIGH + 74, textKey = "login_popup_nicknameIsIllegal"}
CommErrorCodes.NICKNAME_IS_TOOSHORT = {code = SHARK_ERROCODE_ORIGH + 75, textKey = "login_popup_nicknameIsTooShort"}
CommErrorCodes.NICKNAME_IS_TOOLONG = {code = SHARK_ERROCODE_ORIGH + 76, textKey = "login_popup_nicknameIsTooLong"}
CommErrorCodes.NICKNAME_IS_EXIST = {code = SHARK_ERROCODE_ORIGH + 77, textKey = "login_popup_nicknameExist"}
CommErrorCodes.INVITECODE_NOT_EXIST = {code = SHARK_ERROCODE_ORIGH + 78, textKey = "login_popup_InvitationCodeDoesNotExist"}
CommErrorCodes.NICKNAME_CONTAIN_SENSTIVEWORD = {code = SHARK_ERROCODE_ORIGH + 79, textKey = "login_popup_nicknameExist"}

-- 购买体力精力
CommErrorCodes.USER_ENERGY_FULL = {code = SHARK_ERROCODE_ORIGH + 90, textKey = "playerInfo_energyFull"}
CommErrorCodes.USER_ENERGY_BOUGHT_NUM_FULL = {code = SHARK_ERROCODE_ORIGH + 91, textKey = "playerInfo_cannotRecoverStamina"}
CommErrorCodes.USER_EVENT_POINT_FULL = {code = SHARK_ERROCODE_ORIGH + 92, textKey = "playerInfo_eventPointFull"}
CommErrorCodes.USER_EVENT_POINT_BOUGHT_NUM_FULL = {code = SHARK_ERROCODE_ORIGH + 93, textKey = "playerInfo_cannotRecoverVigour"}

-- 好友系统相关 --
CommErrorCodes.FRIEND_NOT_EXIST = {code = SHARK_ERROCODE_ORIGH + 601, textKey = "EC_FRIEND_RELATIONSHIP_NOT_EXIST_TXT"} --玩家已不是好友
CommErrorCodes.FRIEND_LIST_FULL = {code = SHARK_ERROCODE_ORIGH + 604, textKey = "EC_FRIEND_LIST_FULL_TXT"} --好友数达到上限
CommErrorCodes.FRIEND_RELATIONSHIP_EXIST = {code = SHARK_ERROCODE_ORIGH + 605, textKey = "EC_FRIEND_RELATIONSHIP_EXIST_TXT"} --好友关系已经建立
CommErrorCodes.FRIEND_INVITATION_EXIST = {code = SHARK_ERROCODE_ORIGH + 606, textKey = "EC_FRIEND_INVITATION_EXIST_TXT"} --已被好友邀请
CommErrorCodes.FRIEND_INVITATION_NOT_EXIST = {code = SHARK_ERROCODE_ORIGH + 607, textKey = "EC_FRIEND_INVITATION_NOT_EXIST_TXT"} --不被好友邀请
CommErrorCodes.FRIEND_SENDER_INVITATION_LIST_FULL = {code = SHARK_ERROCODE_ORIGH + 608, textKey = "EC_FRIEND_SENDER_INVITATION_LIST_FULL_TXT"} --玩家发送邀请数达到上限
CommErrorCodes.FRIEND_RECEIVER_INVITATION_LIST_FULL = {code = SHARK_ERROCODE_ORIGH + 609, textKey = "EC_FRIEND_RECEIVER_INVITATION_LIST_FULL_TXT"} --玩家接收邀请数达到上限

CommErrorCodes.FRIEND_RELATIONSHIP_NOT_EXIST = {code = SHARK_ERROCODE_ORIGH + 610, textKey = "EC_FRIEND_RELATIONSHIP_NOT_EXIST_TXT"} -- 玩家已不是好友
CommErrorCodes.FRIEND_FREEGIFT_SEND = {code = SHARK_ERROCODE_ORIGH + 611, textKey = "EC_FRIEND_FREEGIFT_SEND_TXT"} --当日已向玩家发送过礼物
CommErrorCodes.FRIEND_FREEGIFT_SENDNUM_FULL = {code = SHARK_ERROCODE_ORIGH + 612, textKey = "EC_FRIEND_FREEGIFT_SENDNUM_FULL_TXT"} --可发送礼物达到上限

CommErrorCodes.FRIEND_FREEGIFT_ENERGY_POOL_EMPTY = {code = SHARK_ERROCODE_ORIGH + 614, textKey = "EC_FRIEND_FREEGIFT_ENERGY_POOL_EMPTY_TXT"} --没有体力可接收
CommErrorCodes.FRIEND_FREEGIFT_ENERGY_FULL = {code = SHARK_ERROCODE_ORIGH + 615, textKey = "EC_FRIEND_FREEGIFT_ENERGY_FULL_TXT"} --玩家体力满
CommErrorCodes.FRIEND_SELF_LIST_FULL = {code = SHARK_ERROCODE_ORIGH + 616, textKey = "friend_acceptRequestFailed_friendFull"} --自己好友数达上限
CommErrorCodes.FRIEND_ENEMY_LIST_FULL = {code = SHARK_ERROCODE_ORIGH + 617, textKey = "friend_acceptRequestFailed_opponentFriendFull"} --对方好友数达上限

--TODO
CommErrorCodes.ELITE_SETTING_NOTCONFIG = {code = SHARK_ERROCODE_ORIGH + 3201, textKey = ""} -- 关卡配置不存在
CommErrorCodes.ELITE_CHALLENGETIMES_REACH = {code = SHARK_ERROCODE_ORIGH + 3202, textKey = "EC_ELITE_CHALLENGETIMES_REACH_TXT"} -- 挑战次数达到上限
CommErrorCodes.ELITE_GRID_FULL = {code = SHARK_ERROCODE_ORIGH + 3203, textKey = "EC_ELITE_GRID_FULL_TXT"} -- 背包已满
CommErrorCodes.ELITE_PREMISSION_UNLOCK = {code = SHARK_ERROCODE_ORIGH + 3204, textKey = "EC_ELITE_PREMISSION_UNLOCK_TXT"} -- 上一精英关卡未解锁
CommErrorCodes.ELITE_REQUIREMISSION_UNLOCK = {code = SHARK_ERROCODE_ORIGH + 3205, textKey = "EC_ELITE_REQUIREMISSION_UNLOCK_TXT"} -- 依赖的普通关卡未解锁

CommErrorCodes.USER_LEVELUP_EVENT_NOT_EXIST = {code = SHARK_ERROCODE_ORIGH + 530, textKey = "popup_normalError"} -- 依赖的普通关卡未解锁

-- 没有新手礼包配置
CommErrorCodes.COUNTDOWN_REWARD_META_NOT_CONFIGED = {code = SHARK_ERROCODE_ORIGH + 4180, textKey = "countdownReward_cannotOpen"}
-- 未到领取时间
CommErrorCodes.COUNTDOWN_REWARD_NOT_REACH_TIME = {code = SHARK_ERROCODE_ORIGH + 4181, textKey = "countdownReward_cannotOpen"}

-- 兑换礼包错误码
CommErrorCodes.EXCHANGE_GIFT_BAG_INVALID_ACTIVATION_CODE = {code = SHARK_ERROCODE_ORIGH + 4200}
CommErrorCodes.EXCHANGE_GIFT_BAG_HAS_GET_REWARD = {code = SHARK_ERROCODE_ORIGH + 4201}
CommErrorCodes.ACTIVATION_CODE_META_NOT_CONFIGED = {code = SHARK_ERROCODE_ORIGH + 4202}
CommErrorCodes.EXCHANGE_GIFT_BAG_NOT_IN_ACTIVITY_TIME = {code = SHARK_ERROCODE_ORIGH + 4203}
CommErrorCodes.EXCHANGE_GIFT_BAG_ACTIVATION_CODE_NOT_EXIST = {code = SHARK_ERROCODE_ORIGH + 4204}
CommErrorCodes.EXCHANGE_GIFT_BAG_ACTIVATION_HAS_USED = {code = SHARK_ERROCODE_ORIGH + 4205}
CommErrorCodes.ACTIVATION_CODE_ITEM_NOT_CONFIGED = {code = SHARK_ERROCODE_ORIGH + 4207}

--周末秒杀活动
CommErrorCodes.ACTIVITY_SECKILL_CLOSE = {code = SHARK_ERROCODE_ORIGH + 4600, textKey = "activity_goldGod_end_remind"}--活动已结束
-- CommErrorCodes.ACTIVITY_SECKILL_ITEM_NOT_CONFIG = {code = SHARK_ERROCODE_ORIGH + 4601, textKey = "xxx"}--没有配置
-- CommErrorCodes.ACTIVITY_SECKILL_CURRENCY_TYPE_NOT_SUPPORT = {code = SHARK_ERROCODE_ORIGH + 4602, textKey = "xxx"}--无效类型
CommErrorCodes.ACTIVITY_SECKILL_USER_PURCHASE_LIMIT = {code = SHARK_ERROCODE_ORIGH + 4603, textKey = "activity_seckill_limit"}--购买次数到达上限
CommErrorCodes.ACTIVITY_SECKILL_ITEM_SOLD_OUT = {code = SHARK_ERROCODE_ORIGH + 4604, textKey = "activity_seckill_exhausted"}--库存告罄，下次请早
CommErrorCodes.ACTIVITY_SECKILL_ITEM_NOT_IN_TIME = {code = SHARK_ERROCODE_ORIGH + 4605, textKey = "activity_seckill_close"}--不在购买时限内

--军团系统相关
CommErrorCodes.USER_JOINED_UNION = {code = SHARK_ERROCODE_ORIGH + 6300, textKey = "union_creat_not_satisfied5"}--已经加入军团
CommErrorCodes.USER_IN_UNION_COLD = {code = SHARK_ERROCODE_ORIGH + 6301, textKey = "union_apply_not_satisfied3"}--加入军团冷却时间
CommErrorCodes.USER_LEVEL_NOT_FIT_UNION = {code = SHARK_ERROCODE_ORIGH + 6302, textKey = "union_apply_not_satisfied1"}--需要达到{num}级才能申请加入军团
CommErrorCodes.UNION_NAME_IS_NULL = {code = SHARK_ERROCODE_ORIGH + 6304, textKey = "union_creat_not_satisfied6"}--军团名称不能为空
CommErrorCodes.UNION_NAME_IS_INVALID = {code = SHARK_ERROCODE_ORIGH + 6305, textKey = "union_creat_not_satisfied8"}--军团名称包含非法字符(只能是中文 数字 字母)
CommErrorCodes.UNION_NAME_IS_TOOSHORT = {code = SHARK_ERROCODE_ORIGH + 6306, textKey = "union_creat_not_satisfied7"}--军团名称过短
CommErrorCodes.UNION_NAME_IS_TOOLONG = {code = SHARK_ERROCODE_ORIGH + 6307, textKey = "union_creat_not_satisfied2"}--军团名不能超过6个汉字或12位英文数字
CommErrorCodes.UNION_NAME_IS_EXIST = {code = SHARK_ERROCODE_ORIGH + 6308, textKey = "union_creat_not_satisfied3"}--该军团名已存在
CommErrorCodes.UNION_NAME_CONTIAN_SENSITIVE_WORD = {code = SHARK_ERROCODE_ORIGH + 6309, textKey = "union_creat_not_satisfied8"}--军团名称包含非法字符
CommErrorCodes.USER_APPLY_UNION_REACH_UPPER = {code = SHARK_ERROCODE_ORIGH + 6311, textKey = "union_apply_not_satisfied4"}--您提交的申请已经达到上限
CommErrorCodes.UNION_APPLIERS_REACH_UPPER = {code = SHARK_ERROCODE_ORIGH + 6312, textKey = "union_apply_not_satisfied5"}--该军团不能接受更多的申请了
CommErrorCodes.USER_NOT_JOIN_ANY_UNION = {code = SHARK_ERROCODE_ORIGH + 6313, textKey = "union_data_refresh_remind"}--数据已过期，请重新进入界面
CommErrorCodes.UNION_APPLY_NOT_EXIST = {code = SHARK_ERROCODE_ORIGH + 6314, textKey = "union_data_refresh_remind"}--数据已过期，请重新进入界面
CommErrorCodes.UNION_CANONT_DISSOLVE_FOR_LEVEL = {code = SHARK_ERROCODE_ORIGH + 6316, textKey = "union_dissolve_not_satisfied2"}--军团等级达到{num}级后不能解散
CommErrorCodes.USER_NOT_UNION_MANAGER = {code = SHARK_ERROCODE_ORIGH + 6317, textKey = "union_dissolve_not_satisfied1"}--只有军团长才能解散军团
CommErrorCodes.USER_IS_UNION_MANAGER = {code = SHARK_ERROCODE_ORIGH + 6318, textKey = "union_data_refresh_remind"}--数据已过期，请重新进入界面
CommErrorCodes.USERS_NOT_IN_SAME_UNION = {code = SHARK_ERROCODE_ORIGH + 6319, textKey = "union_data_refresh_remind"}--数据已过期，请重新进入界面
CommErrorCodes.UNION_MEMBERS_REACH_UPPER = {code = SHARK_ERROCODE_ORIGH + 6320, textKey = "union_examine_accept_remind1"}--军团人数已满
CommErrorCodes.UNION_CANNOT_DISSOLVE_FOR_MULTIPLE_MEMBERS = {code = SHARK_ERROCODE_ORIGH + 6322, textKey = "union_dissolve_not_satisfied3"}--军团人数为1时才能解散军团
CommErrorCodes.UNSUPPORT_UNION_APPOINT_TYPE = {code = SHARK_ERROCODE_ORIGH + 6323, textKey = "union_data_refresh_remind"}--数据已过期，请重新进入界面
CommErrorCodes.UNION_MEMBERS_SUBTYPE_REACH_UPPER = {code = SHARK_ERROCODE_ORIGH + 6324, textKey = "union_player_button_appointment_remind"}--该职位人数已满
CommErrorCodes.UNION_MANAGER_LEAVE_TIME_NOT_ENOUGH = {code = SHARK_ERROCODE_ORIGH + 6325, textKey = "union_player_button_impeach_remind"}--军团长离开超过7天后才能弹劾
CommErrorCodes.NO_MEMBERS_IN_UNION = {code = SHARK_ERROCODE_ORIGH + 6326, textKey = "union_data_refresh_remind"}--除了军团长没有其他成员
CommErrorCodes.USER_IS_NOT_UNION_MANAGER = {code = SHARK_ERROCODE_ORIGH + 6327, textKey = "union_data_refresh_remind"}--数据已过期，请重新进入界面
CommErrorCodes.UNION_NOT_IN_TRANSFER_STATUS = {code = SHARK_ERROCODE_ORIGH + 6328, textKey = "union_data_refresh_remind"}--数据已过期，请重新进入界面
CommErrorCodes.UNION_NOT_IN_DISSOLVE_STATUS = {code = SHARK_ERROCODE_ORIGH + 6329, textKey = "union_data_refresh_remind"}--数据已过期，请重新进入界面
CommErrorCodes.UNION_ALREADY_DISSOLVED = {code = SHARK_ERROCODE_ORIGH + 6330, textKey = "union_data_refresh_remind"}--数据已过期，请重新进入界面
CommErrorCodes.UNION_IN_DISSOLVE_STATUS = {code = SHARK_ERROCODE_ORIGH + 6331, textKey = "union_building_upgrade_not_satisfied3"}--解散中不能执行该操作
CommErrorCodes.UNION_DECLARATION_TOO_LONG = {code = SHARK_ERROCODE_ORIGH + 6332, textKey = "union_announcement_not_satisfied1"}--文本过长
CommErrorCodes.UNION_DECLARATION_CONTAINS_SENSITIVE_WROD = {code = SHARK_ERROCODE_ORIGH + 6333, textKey = "union_announcement_not_satisfied3"}--您的公告中包含非法字符
CommErrorCodes.UNION_DECLARATION_IS_EMPTY = {code = SHARK_ERROCODE_ORIGH + 6334, textKey = "union_announcement_not_satisfied4"}--文本不能为空
CommErrorCodes.UNION_NOTICE_TOO_LONG = {code = SHARK_ERROCODE_ORIGH + 6335, textKey = "union_announcement_not_satisfied1"}--文本过长
CommErrorCodes.UNION_NOTICE_CONTAINS_SENSITIVE_WORD = {code = SHARK_ERROCODE_ORIGH + 6336, textKey = "union_announcement_not_satisfied3"}--您的公告中包含非法字符
CommErrorCodes.UNION_NOTICE_IS_EMPTY = {code = SHARK_ERROCODE_ORIGH + 6337, textKey = "union_announcement_not_satisfied4"}--文本不能为空
CommErrorCodes.UNION_WEALTH_NOT_ENOUGH = {code = SHARK_ERROCODE_ORIGH + 6338, textKey = "union_building_upgrade__not_satisfied3"}--财富不够，不能进行升级
CommErrorCodes.USER_IS_NOT_IN_UNION = {code = SHARK_ERROCODE_ORIGH + 6339, textKey = "union_monster_errorNum1"}--此人不在军团里，请重新分配
CommErrorCodes.STR_HAS_WROWN_WORD = {code = SHARK_ERROCODE_ORIGH + 6340, textKey = "union_text_explain"}--不支持特殊符号的显示，请重新输入

CommErrorCodes.UNION_BUILDING_REACH_MAX_LEVEL = {code = SHARK_ERROCODE_ORIGH + 6353, textKey = "union_building_upgrade__not_satisfied1"}--建筑已经达到满级
CommErrorCodes.UNION_BUILDING_LEVEL_BIGGER_THAN_UNION_LEVEL = {code = SHARK_ERROCODE_ORIGH + 6357, textKey = "union_building_upgrade__not_satisfied2"}--建筑等级不能超过军团大厅的等级
-- CommErrorCodes.UNION_BUILDING_TYPE_UNSUPPORT = {code = SHARK_ERROCODE_ORIGH + 6358, textKey = "111"}--不存在的建筑类型
CommErrorCodes.ALREADY_CONSTRUCT_TODAY = {code = SHARK_ERROCODE_ORIGH + 6359, textKey = "union_build_today_complete_remind"}--今日已建设
-- CommErrorCodes.SHARK_USER_UNION_IS_NULL = {code = SHARK_ERROCODE_ORIGH + 6360, textKey = "111"}--
-- CommErrorCodes.USER_NOT_IN_UNION = {code = SHARK_ERROCODE_ORIGH + 6361, textKey = "111"}--用户不在这个军团中
-- CommErrorCodes.UNION_CONSTRUCT_TYPE_UNSUPPORT = {code = SHARK_ERROCODE_ORIGH + 6362, textKey = "111"}--捐献类型不存在
-- CommErrorCodes.UNION_SHOP_NORMAL_META_NOT_CONFIGED = {code = SHARK_ERROCODE_ORIGH + 6363, textKey = "111"}--
-- CommErrorCodes.UNION_SHOP_SPECIAL_META_NOT_CONFIGED = {code = SHARK_ERROCODE_ORIGH + 6364, textKey = "111"}--
-- CommErrorCodes.UNION_NORMAL_PROP_DAILY_PURCHASE_TIMES_LIMIT = {code = SHARK_ERROCODE_ORIGH + 6365, textKey = "111"}--道具到达上限
-- CommErrorCodes.UNION_SPECIAL_PROP_DAILY_PURCHASE_TIMES_LIMIT = {code = SHARK_ERROCODE_ORIGH + 6366, textKey = "111"}--特殊道具达到上限
-- CommErrorCodes.SPECIAL_PROP_IS_NOT_ON_SALE = {code = SHARK_ERROCODE_ORIGH + 6367, textKey = "111"}--现在不出售
-- CommErrorCodes.UNION_SHOP_PROP_TYPE_UNSUPPORT = {code = SHARK_ERROCODE_ORIGH + 6368, textKey = "111"}--不支持的商城道具类型
-- CommErrorCodes.UNION_SHOP_LEVEL_NOT_ENOUGH = {code = SHARK_ERROCODE_ORIGH + 6369, textKey = "111"}--商城等级不足
-- CommErrorCodes.USER_UNION_CONTRIBUTE_NOT_ENOUGH = {code = SHARK_ERROCODE_ORIGH + 6370, textKey = "111"}--贡献值不足
-- CommErrorCodes.RECEIVE_WAGE_AT_WRONG_TIME = {code = SHARK_ERROCODE_ORIGH + 6371, textKey = "111"}--领工资时间不对
-- CommErrorCodes.ALREADY_RECEIVED_WAGE_TODAY = {code = SHARK_ERROCODE_ORIGH + 6372, textKey = "111"}--今日已领过工资

CommErrorCodes.UNION_MONSTER_IS_ALIVE = {code = SHARK_ERROCODE_ORIGH + 6377, textKey = "union_monster_errorNum2"}--怪物尚未死亡，不能进行分配
CommErrorCodes.UNOIN_MONSTER_CANNOT_SUMMON_MONSTER_THIS_TIME = {code = SHARK_ERROCODE_ORIGH + 6378, textKey = "union_monster_errorNum3"}--主公，现在不在召唤时间哦
CommErrorCodes.UNION_MONSTER_HAS_REWARD_NOT_DISTRIBUTE = {code = SHARK_ERROCODE_ORIGH + 6379, textKey = "union_monster_errorNum4"}--奖励尚未分配

CommErrorCodes.UNION_MONSTER_ESCAPE = {code = SHARK_ERROCODE_ORIGH + 6382, textKey = "union_monster_errorNum5"}--怪物已逃跑
CommErrorCodes.UNION_MONSTER_IS_DEAD = {code = SHARK_ERROCODE_ORIGH + 6383, textKey = "union_monster_errorNum6"}--怪物已被击杀
CommErrorCodes.UNION_MONSTER_COLOSSEUM_LEVEL_LIMIT = {code = SHARK_ERROCODE_ORIGH + 6384, textKey = "union_monster_errorNum7"}--怪物未解锁，请升级斗兽场
CommErrorCodes.UNION_MONSTER_DAILY_ATT_TIMES_LIMIT = {code = SHARK_ERROCODE_ORIGH + 6385, textKey = "union_monster_errorNum8"}--攻击次数不足
CommErrorCodes.UNION_MONSTER_REWARD_ALREADY_DISTRIBUTED = {code = SHARK_ERROCODE_ORIGH + 6386, textKey = "union_monster_errorNum9"}--奖励已分配
CommErrorCodes.UNION_MONSTER_REWARD_DISTRIBUTE_NUM_NOT_MATCH = {code = SHARK_ERROCODE_ORIGH + 6387, textKey = "union_data_refresh_remind"}--分配总数不符--数据已过期，请重新进入界面
CommErrorCodes.UNION_MONSTER_SUMMON_TIMES_LIMIT = {code = SHARK_ERROCODE_ORIGH + 6388, textKey = "union_monster_errorNum10"}--召唤次数到达上限
CommErrorCodes.UNION_MONSTER_SOMEONE_DISTRIBUTING_REWARD = {code = SHARK_ERROCODE_ORIGH + 6389, textKey = "union_monster_reward_distribution_not_satisfied1"}--有其他玩家正在分配战利品
CommErrorCodes.UNION_MONSTER_SOMEONE_SUMMONING_MONSTER = {code = SHARK_ERROCODE_ORIGH + 6390, textKey = "union_monster_summon_not_satisfied1"}--同一时间只能召唤一只怪兽

-- CommErrorCodes.UNION_CAREER_META_NOT_CONFIGED = {code = SHARK_ERROCODE_ORIGH + 6410, textKey = "111"}--
-- CommErrorCodes.HAS_NO_UNION_PRIVILIGE_DISSOLVE_UNION = {code = SHARK_ERROCODE_ORIGH + 6411, textKey = "union_announcement_not_satisfied2"}--没有权限解散
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_APPOINT_VICE_MANAGER = {code = SHARK_ERROCODE_ORIGH + 6412, textKey = "union_announcement_not_satisfied2"}--没有权限任命副团长
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_TRANSFER_UNION = {code = SHARK_ERROCODE_ORIGH + 6413, textKey = "union_announcement_not_satisfied2"}--没有权限移交
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_KICK_OUT_VICE_MANAGER = {code = SHARK_ERROCODE_ORIGH + 6414, textKey = "union_announcement_not_satisfied2"}--没有权限踢副团长
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_RECALL_VICE_MANAGER = {code = SHARK_ERROCODE_ORIGH + 6415, textKey = "union_announcement_not_satisfied2"}--没有权限罢免副团长
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_MODIFY_DECLARATION = {code = SHARK_ERROCODE_ORIGH + 6416, textKey = "union_announcement_not_satisfied2"}--没有权限修改宣言
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_MODIFY_ANNOUNCEMENT = {code = SHARK_ERROCODE_ORIGH + 6417, textKey = "union_announcement_not_satisfied2"}--没有权限修改公告
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_APPOINT_ELITE_MEMBER = {code = SHARK_ERROCODE_ORIGH + 6418, textKey = "union_announcement_not_satisfied2"}--没有权限任命精英成员
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_RECALL_ELITE_MEMBER = {code = SHARK_ERROCODE_ORIGH + 6419, textKey = "union_announcement_not_satisfied2"}--没有权限罢免精英成员
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_UPGRAGE_UNION_BUILDING = {code = SHARK_ERROCODE_ORIGH + 6420, textKey = "union_announcement_not_satisfied2"}--没有权限升级建筑
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_APPLY_EXAMINE = {code = SHARK_ERROCODE_ORIGH + 6421, textKey = "union_announcement_not_satisfied2"}--您的职务不能执行此操作
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_KICK_OUT_MEMBER = {code = SHARK_ERROCODE_ORIGH + 6422, textKey = "union_announcement_not_satisfied2"}--没有权限踢人
-- CommErrorCodes.HAS_NO_UNION_PRIVILIGE_DONATE = {code = SHARK_ERROCODE_ORIGH + 6423, textKey = "111"}--没有权限捐献
-- CommErrorCodes.HAS_NO_UNION_PRIVILIGE_UNION_SHOP_BUY = {code = SHARK_ERROCODE_ORIGH + 6424, textKey = "111"}--没有权限购买
-- CommErrorCodes.HAS_NO_UNION_PRIVILIGE_RECEIVE_WAGE = {code = SHARK_ERROCODE_ORIGH + 6425, textKey = "111"}--没有权限领工资
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_SUMMON_MONSTER = {code = SHARK_ERROCODE_ORIGH + 6426, textKey = "union_monster_errorNum11"}--主公，您没有召唤权限哦
CommErrorCodes.HAS_NO_UNION_PRIVILIGE_DISTRIBUTE_MONSTER_REWARD = {code = SHARK_ERROCODE_ORIGH + 6427, textKey = "union_monster_errorNum12"}--主公，您没有分配权限哦




--卡牌经验强化
CommErrorCodes.CARD_TARGET_LEVEL_IS_INVALID = {code = SHARK_ERROCODE_ORIGH + 1063, textKey = "cardEnhance_levelInvalid"}--您选择的等级不正确
CommErrorCodes.GENERAL_EXP_NOT_ENOUGH = {code = SHARK_ERROCODE_ORIGH + 6471, textKey = "cardEnhance_expInsufficient"}--当前拥有的武将经验不足

CommErrorCodes.CREATE_USER_ERROR = {code = SHARK_ERROCODE_ORIGH + 71 , textKey = "EC_CREATE_USER"}
CommErrorCodes.OPEN_VIPBOX = {code = SHARK_ERROCODE_ORIGH + 2908 , textKey = "EC_USE_PROP"}
CommErrorCodes.CHALLENAGE_PK_ERROR = {code = SHARK_ERROCODE_ORIGH + 103 , textKey = "EC_CHALLENGE_PK_USER"}
CommErrorCodes.GAIN_PK_REWARD_ERROR = {code = SHARK_ERROCODE_ORIGH + 544 , textKey = "EC_GAIN_PK_REWARDS"}