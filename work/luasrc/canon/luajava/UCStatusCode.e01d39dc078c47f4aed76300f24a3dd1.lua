--调用成功
    g_UCSdk_SUCCESS = 0;

--调用失败
	g_UCSdk_FAIL = -2;

--没有初始化
	g_UCSdk_NO_INIT = -10;

--没有登录
	g_UCSdk_NO_LOGIN = -11;

--网咯错误
	g_UCSdk_NO_NETWORK = -12;

-- 初始化失败
	g_UCSdk_INIT_FAIL = -100;

--游戏帐户密码错误导致登录失败
	g_UCSdk_LOGIN_GAME_USER_AUTH_FAIL = -201;
	
--网络原因导致游戏帐户登录失败
	g_UCSdk_LOGIN_GAME_USER_NETWORK_FAIL = -202;
	
--其他原因导致的游戏帐户登录失败
	g_UCSdk_LOGIN_GAME_USER_OTHER_FAIL = -203;

-- 获取好友关系失败
	g_UCSdk_GETFRINDS_FAIL = -300;

-- 获取用户是否会员时失败
	g_UCSdk_VIP_FAIL = -400;
	
-- 获取用户会员特权信息时失败
	g_UCSdk_VIPINFO_FAIL = -401;

--用户退出充值界面
	g_UCSdk_PAY_USER_EXIT = -500;

--用户退出登录界面
	g_UCSdk_LOGIN_EXIT = -600;

--SDK界面将要显示
	g_UCSdk_SDK_OPEN = -700;

--SDK界面将要关闭，返回到游戏画面
	g_UCSdk_SDK_CLOSE = -701;

--游客状态
	g_UCSdk_GUEST = -800;

--uc账户登录状态
	g_UCSdk_UC_ACCOUNT = -801;

--退出游客试玩激活绑定页面回调状态码 
	g_UCSdk_BIND_EXIT = -900;