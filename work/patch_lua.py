#!/usr/bin/env python3
"""
Generalised multi-file Lua patcher for the canon client.

The engine SIGKILLs the process on ANY uncaught Lua error, so every residual
`attempt to call a nil value` shows up as "游戏直接弹出了".  This script applies
a registry of targeted source patches to the encrypted Lua assets inside an APK
and rebuilds it, handling the whole asset chain automatically:

    decrypt  = AES-128-CBC(blob[16:], key, blob[:16]) -> unpad -> zlib.inflate
    encrypt  = IV(16) || AES-128-CBC(zlib.compress(src,9) padded, key, IV)
    asset    = assets/src/<virt path>.<md5(encrypted)>.lua
    manifest = assets/static_config.<md5(manifest bytes)>.xml   (renamed!)

Output APK is UNSIGNED; sign it afterwards (zipalign + apksigner, canon.keystore).
"""
import os, re, sys, zlib, hashlib, zipfile
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad

KEY = bytes.fromhex("e9747d92cc322e7d112e7c3451d7b36a")
SRC_APK = r"E:\deepseek_projects\app_server\work\zjt_bypass.apk"
OUT_APK = r"E:\deepseek_projects\app_server\work\zjt_run.apk"


def P_local_pay(src: bytes):
    """
    canon/luajava/GspBridge.lua

    Native GSP/Google Play is unavailable on the local emu.  Short-circuit
    GspBridgeAndroid.pay to validatePaymentOrder on our server (grants gems /
    rechargeGems) then invoke the same success callback as a real receipt.
    """
    # Insert right after `local productId = productInfo.id`
    needle = b"local productId = productInfo.id\r\n"
    if src.count(needle) != 1:
        needle = b"local productId = productInfo.id\n"
    if src.count(needle) != 1:
        raise SystemExit(f"GspBridge productId line matched {src.count(needle)}")
    inject = (
        needle +
        b"  -- [patched] local offline pay: skip native GSP, credit via server\r\n"
        b"  do\r\n"
        b"    local function localPayOk(evt)\r\n"
        b"      if payCallBackFunc and type(payCallBackFunc) == \"function\" then\r\n"
        b"        local ok = true\r\n"
        b"        if evt and evt.data and evt.data.succ == false then ok = false end\r\n"
        b"        payCallBackFunc(ok, evt)\r\n"
        b"      end\r\n"
        b"    end\r\n"
        b"    local function localPayFail(evt)\r\n"
        b"      if payCallBackFunc and type(payCallBackFunc) == \"function\" then\r\n"
        b"        payCallBackFunc(false, evt)\r\n"
        b"      end\r\n"
        b"    end\r\n"
        b"    local gold = productInfo.amount or productInfo.goldNum or 60\r\n"
        b"    local request = ValidatePaymentOrderRequest.new({\r\n"
        b"      orderId = \"local-\" .. tostring(os.time()) .. \"-\" .. tostring(productId),\r\n"
        b"      productId = productId,\r\n"
        b"      goldNum = gold,\r\n"
        b"    }, rpc.SendingPriority.kHigh)\r\n"
        b"    request:addEventListener(RequestNotifyEnum.ValidatePaymentOrderSucceed, localPayOk)\r\n"
        b"    request:addEventListener(RequestNotifyEnum.ValidatePaymentOrderFailed, localPayFail)\r\n"
        b"    request:start()\r\n"
        b"    return\r\n"
        b"  end\r\n"
    )
    return src.replace(needle, inject, 1)


def P_mainmenu_tip_pcall(src: bytes):
    """
    canon/scene/MainMenuScene.lua

    After closing 每日签到, tip refresh walks every Activity_*.getTipNum().
    Incomplete getMeta fields (cardExchangeMeta, dayRewards, fortuneFreeTime,
    ...) make individual getTipNum throw; the engine SIGKILLs the process.
    Wrap each call in pcall so one bad tip never pops the game.
    """
    old = (
        b"    local panelNameDict = ActivityPanelScene.getPanelNameDict()\r\n"
        b"    for k, v in pairs(panelNameDict) do\r\n"
        b"      local aTipNum, aParticleStatus = v.getTipNum()\r\n"
        b"      if aTipNum > 0 then\r\n"
        b"        self.activityCount = self.activityCount + 1\r\n"
        b"        self.activityEnableTips[k] = aTipNum\r\n"
        b"      end\r\n"
        b"      self.activityParticleInfos[k] = aParticleStatus\r\n"
        b"    end\r\n"
    )
    new = (
        b"    local panelNameDict = ActivityPanelScene.getPanelNameDict()\r\n"
        b"    for k, v in pairs(panelNameDict) do\r\n"
        b"      -- [patched] pcall: incomplete activity meta must not SIGKILL\r\n"
        b"      local ok, aTipNum, aParticleStatus = pcall(function()\r\n"
        b"        return v.getTipNum()\r\n"
        b"      end)\r\n"
        b"      if not ok then\r\n"
        b"        aTipNum, aParticleStatus = 0, nil\r\n"
        b"      end\r\n"
        b"      aTipNum = aTipNum or 0\r\n"
        b"      if aTipNum > 0 then\r\n"
        b"        self.activityCount = self.activityCount + 1\r\n"
        b"        self.activityEnableTips[k] = aTipNum\r\n"
        b"      end\r\n"
        b"      self.activityParticleInfos[k] = aParticleStatus\r\n"
        b"    end\r\n"
    )
    if src.count(old) != 1:
        old = old.replace(b"\r\n", b"\n")
        new = new.replace(b"\r\n", b"\n")
    if src.count(old) != 1:
        raise SystemExit(f"MainMenu tip loop matched {src.count(old)}")
    return src.replace(old, new, 1)


def P_calendar_signin_close(src: bytes):
    """
    canon/panel/CalendarSignInPanel.lua

    Empty-area close for the startup popPanel is gated on signInActionFinish,
    which stays false until getMonthlyLoginRewardMeta + claim animation finish.
    Players tapping blank space during that window get no close (or race into
    tip-refresh crashes).  Always allow popPanel close on empty-area tap.
    """
    old = (
        b"    local function onClosePanel(evt)\r\n"
        b"        if self.type == CalendarSignInType.popPanel and self.signInActionFinish then\r\n"
        b"\t\t\tself.clickClosePanel = true\r\n"
        b"\t\t\tPopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )\r\n"
        b"\t\t\t--self.container:setTableViewsEnabled(true)\r\n"
        b"\t\t\tself.container.targetInfoPanel = nil\r\n"
        b"\t\t\tif self.colseCallBackFunc and type(self.colseCallBackFunc) == \"function\" then\r\n"
        b"\t\t        self.colseCallBackFunc()\r\n"
        b"\t\t    end\r\n"
        b"\t\tend\r\n"
        b"    end \r\n"
    )
    new = (
        b"    local function onClosePanel(evt)\r\n"
        b"        -- [patched] always allow empty-area close for startup popPanel\r\n"
        b"        if self.type == CalendarSignInType.popPanel then\r\n"
        b"\t\t\tself.clickClosePanel = true\r\n"
        b"\t\t\tself.signInActionFinish = true\r\n"
        b"\t\t\tPopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )\r\n"
        b"\t\t\t--self.container:setTableViewsEnabled(true)\r\n"
        b"\t\t\tself.container.targetInfoPanel = nil\r\n"
        b"\t\t\tif self.colseCallBackFunc and type(self.colseCallBackFunc) == \"function\" then\r\n"
        b"\t\t        self.colseCallBackFunc()\r\n"
        b"\t\t    end\r\n"
        b"\t\tend\r\n"
        b"    end \r\n"
    )
    if src.count(old) != 1:
        old = old.replace(b"\r\n", b"\n")
        new = new.replace(b"\r\n", b"\n")
    if src.count(old) != 1:
        raise SystemExit(f"CalendarSignIn onClosePanel matched {src.count(old)}")
    return src.replace(old, new, 1)


def P_fortune_tip_guard(src: bytes):
    """
    canon/layer/Activity_LotteryFortuneLayer.lua

    getTipNum / shouldShowParticle subtract fortuneFreeTime with no nil guard.
    Incomplete getMeta activityFortuneNowConfig => SIGKILL on MainMenu tip
    refresh (e.g. right after closing 每日签到).
    """
    old_tip = (
        b"function Activity_LotteryFortuneLayer.getTipNum()\r\n"
        b"  if not Activity_LotteryFortuneLayer.enable() then\r\n"
        b"    return 0\r\n"
        b"  end\r\n"
        b"  \r\n"
        b"  local result = DataManager.GameMetaData.activityFortuneNowConfig.fortuneFreeTime - DailyDataManager.getDailyDataFortuneNum()\r\n"
    )
    new_tip = (
        b"function Activity_LotteryFortuneLayer.getTipNum()\r\n"
        b"  if not Activity_LotteryFortuneLayer.enable() then\r\n"
        b"    return 0\r\n"
        b"  end\r\n"
        b"  -- [patched] nil-safe fortuneFreeTime\r\n"
        b"  local cfg = DataManager.GameMetaData.activityFortuneNowConfig\r\n"
        b"  if not cfg or not cfg.fortuneFreeTime then\r\n"
        b"    return 0\r\n"
        b"  end\r\n"
        b"  local result = cfg.fortuneFreeTime - DailyDataManager.getDailyDataFortuneNum()\r\n"
    )
    old_part = (
        b"function Activity_LotteryFortuneLayer.shouldShowParticle()\r\n"
        b"  if (DataManager.GameMetaData.activityFortuneNowConfig.fortuneFreeTime > DailyDataManager.getDailyDataFortuneNum()) then\r\n"
        b"    return true\r\n"
        b"  else\r\n"
        b"    return false\r\n"
        b"  end\r\n"
        b"end\r\n"
    )
    new_part = (
        b"function Activity_LotteryFortuneLayer.shouldShowParticle()\r\n"
        b"  -- [patched] nil-safe fortuneFreeTime\r\n"
        b"  local cfg = DataManager.GameMetaData.activityFortuneNowConfig\r\n"
        b"  if not cfg or not cfg.fortuneFreeTime then\r\n"
        b"    return false\r\n"
        b"  end\r\n"
        b"  if (cfg.fortuneFreeTime > DailyDataManager.getDailyDataFortuneNum()) then\r\n"
        b"    return true\r\n"
        b"  else\r\n"
        b"    return false\r\n"
        b"  end\r\n"
        b"end\r\n"
    )
    out = src
    for old, new, label in (
        (old_tip, new_tip, "getTipNum"),
        (old_part, new_part, "shouldShowParticle"),
    ):
        o, n = old, new
        if out.count(o) != 1:
            o = o.replace(b"\r\n", b"\n")
            n = n.replace(b"\r\n", b"\n")
        if out.count(o) != 1:
            raise SystemExit(f"LotteryFortune {label} matched {out.count(o)}")
        out = out.replace(o, n, 1)
    return out


def P_shop_charge_double(src: bytes):
    """
    canon/scene/ShopScene.lua

    getStartTime indexes MaintenanceManager:getStartAndEndTime()[1] without a
    nil guard.  Empty maintenanceItem (local server) => charge-tab render
    via isChargeDouble SIGKILLs: attempt to index a nil value.
    """
    old = (
        b"local function getStartTime(FeatureName)\r\n"
        b"\tlocal startAndEndTime = MaintenanceManager:getStartAndEndTime(FeatureName)\r\n"
        b"\treturn startAndEndTime[1].activityBeginTimeStamp\r\n"
        b"end"
    )
    if src.count(old) != 1:
        old = old.replace(b"\r\n", b"\n")
    if src.count(old) != 1:
        raise SystemExit(f"ShopScene getStartTime matched {src.count(old)}")
    new = (
        b"local function getStartTime(FeatureName)\r\n"
        b"\tlocal startAndEndTime = MaintenanceManager:getStartAndEndTime(FeatureName)\r\n"
        b"\t-- [patched] empty maintenanceItem => no double-charge window\r\n"
        b"\tif startAndEndTime and startAndEndTime[1] "
        b"and startAndEndTime[1].activityBeginTimeStamp then\r\n"
        b"\t\treturn startAndEndTime[1].activityBeginTimeStamp\r\n"
        b"\tend\r\n"
        b"\treturn 0\r\n"
        b"end"
    )
    if b"\r\n" not in old:
        new = new.replace(b"\r\n", b"\n")
    return src.replace(old, new, 1)


def P_activity_tip_pcall(src: bytes):
    """
    canon/scene/ActivityPanelScene.lua

    Same tip-refresh crash surface as MainMenu: resetAllTipInfoData / 
    resetTipInfoForActivity call getTipNum without guards.
    """
    old_all = (
        b"function ActivityPanelScene:resetAllTipInfoData()\r\n"
        b"  for k, v in pairs(PANEL_NAME_DICT) do\r\n"
        b"    local aTipNum, aParticleStatus = v.getTipNum()\r\n"
        b"    if aTipNum >= 0 then\r\n"
        b"      PANEL_TIP_DICT[k] = aTipNum\r\n"
        b"    end\r\n"
        b"    PANEL_PARTICLE_DICT[k] = aParticleStatus\r\n"
        b"  end\r\n"
        b"end\r\n"
    )
    new_all = (
        b"function ActivityPanelScene:resetAllTipInfoData()\r\n"
        b"  for k, v in pairs(PANEL_NAME_DICT) do\r\n"
        b"    -- [patched] pcall getTipNum\r\n"
        b"    local ok, aTipNum, aParticleStatus = pcall(function()\r\n"
        b"      return v.getTipNum()\r\n"
        b"    end)\r\n"
        b"    if not ok then aTipNum, aParticleStatus = 0, nil end\r\n"
        b"    aTipNum = aTipNum or 0\r\n"
        b"    if aTipNum >= 0 then\r\n"
        b"      PANEL_TIP_DICT[k] = aTipNum\r\n"
        b"    end\r\n"
        b"    PANEL_PARTICLE_DICT[k] = aParticleStatus\r\n"
        b"  end\r\n"
        b"end\r\n"
    )
    old_one = (
        b"function ActivityPanelScene:resetTipInfoForActivity(activityName)\r\n"
        b"  local aTipNum, aParticleStatus = PANEL_NAME_DICT[activityName].getTipNum()\r\n"
    )
    new_one = (
        b"function ActivityPanelScene:resetTipInfoForActivity(activityName)\r\n"
        b"  -- [patched] pcall getTipNum\r\n"
        b"  local ok, aTipNum, aParticleStatus = pcall(function()\r\n"
        b"    return PANEL_NAME_DICT[activityName].getTipNum()\r\n"
        b"  end)\r\n"
        b"  if not ok then aTipNum, aParticleStatus = 0, nil end\r\n"
        b"  aTipNum = aTipNum or 0\r\n"
    )
    out = src
    for old, new, label in (
        (old_all, new_all, "resetAllTipInfoData"),
        (old_one, new_one, "resetTipInfoForActivity"),
    ):
        o, n = old, new
        if out.count(o) != 1:
            o = o.replace(b"\r\n", b"\n")
            n = n.replace(b"\r\n", b"\n")
        if out.count(o) != 1:
            raise SystemExit(f"ActivityPanel {label} matched {out.count(o)}")
        out = out.replace(o, n, 1)
    return out


def P_activity_enable_pcall(src: bytes):
    """
    canon/scene/ActivityPanelScene.lua

    initEnabledPanels calls value.panel.enable() bare. Incomplete getMeta
    (e.g. WealthGod goldGodMaxTimes nil) throws → SIGKILL when opening 活动
    after recharge. pcall each enable so one bad tab cannot pop the game.
    """
    old = (
        b"function ActivityPanelScene:initEnabledPanels()\r\n"
        b"  for _, value in ipairs(DICT_PANEL) do\r\n"
        b"    if value.panel then\r\n"
        b"      local enable = value.panel.enable()\r\n"
    )
    new = (
        b"function ActivityPanelScene:initEnabledPanels()\r\n"
        b"  for _, value in ipairs(DICT_PANEL) do\r\n"
        b"    if value.panel then\r\n"
        b"      -- [patched] pcall enable so nil-config tabs don't SIGKILL\r\n"
        b"      local ok, enable = pcall(function() return value.panel.enable() end)\r\n"
        b"      if not ok then enable = false end\r\n"
    )
    if src.count(old) != 1:
        old = old.replace(b"\r\n", b"\n")
        new = new.replace(b"\r\n", b"\n")
    if src.count(old) != 1:
        raise SystemExit(
            f"ActivityPanelScene initEnabledPanels matched {src.count(old)}")
    return src.replace(old, new, 1)


def P_activity_secret_shop_interval(src: bytes):
    """
    canon/scene/ActivityPanelScene.lua

    checkMysteryShopReflesh does
        currentToatalTimestamp + newRefreshInterval[i + 1]
    when the pipe-split refresh list is exhausted [i+1] is nil → arithmetic
    crash after 累充领取 returns to ActivityPanelScene.
    Also create sharkUserSecretShop if missing before writing lastRefreshSecond.
    """
    old = (
        b"        currentToatalTimestamp = currentToatalTimestamp + "
        b"newRefreshInterval[i + 1]\r\n"
    )
    if src.count(old) != 1:
        old = old.replace(b"\r\n", b"\n")
    if src.count(old) != 1:
        raise SystemExit(
            f"ActivityPanelScene refresh interval matched {src.count(old)}")
    new = (
        b"        local nxt = newRefreshInterval[i + 1]\r\n"
        b"        -- [patched] exhausted refresh slots => stay on last window\r\n"
        b"        if not nxt then break end\r\n"
        b"        currentToatalTimestamp = currentToatalTimestamp + nxt\r\n"
    )
    if b"\r\n" not in old:
        new = new.replace(b"\r\n", b"\n")
    out = src.replace(old, new, 1)

    old2 = (
        b"    if(not gameInitData.sharkUserSecretShop) then\r\n"
        b"      self.lastRefleshTime = -1\r\n"
        b"    else\r\n"
        b"      self.lastRefleshTime = "
        b"gameInitData.sharkUserSecretShop.lastRefreshSecond\r\n"
        b"    end\r\n"
    )
    if out.count(old2) != 1:
        old2 = old2.replace(b"\r\n", b"\n")
    if out.count(old2) != 1:
        raise SystemExit(
            f"ActivityPanelScene secretShop init matched {out.count(old2)}")
    new2 = (
        b"    if(not gameInitData.sharkUserSecretShop) then\r\n"
        b"      -- [patched] create stub so later writes don't nil-index\r\n"
        b"      gameInitData.sharkUserSecretShop = {"
        b"lastRefreshSecond = 0, freeTimes = 5, ifListFresh = false}\r\n"
        b"      DataManager.setGameInitData(gameInitData)\r\n"
        b"      self.lastRefleshTime = -1\r\n"
        b"    else\r\n"
        b"      self.lastRefleshTime = "
        b"gameInitData.sharkUserSecretShop.lastRefreshSecond or 0\r\n"
        b"    end\r\n"
    )
    if b"\r\n" not in old2:
        new2 = new2.replace(b"\r\n", b"\n")
    return out.replace(old2, new2, 1)


def P_mystery_shop_secret(src: bytes):
    """
    canon/layer/Activity_MysteryShopLayer.lua

    initLayer writes gameInitData.sharkUserSecretShop.freeTimes with no nil
    guard on the parent — SIGKILL when gameInit omitted the table.
    """
    old = (
        b"\tlocal gameInitData = DataManager.getGameInitData()\r\n"
        b"\tgameInitData.sharkUserSecretShop.freeTimes = "
        b"self.extraArgs.freeTimes\r\n"
        b"\tDataManager.setGameInitData(gameInitData)\r\n"
    )
    if src.count(old) != 1:
        old = old.replace(b"\r\n", b"\n")
    if src.count(old) != 1:
        raise SystemExit(
            f"MysteryShop freeTimes write matched {src.count(old)}")
    new = (
        b"\tlocal gameInitData = DataManager.getGameInitData()\r\n"
        b"\t-- [patched] ensure sharkUserSecretShop exists\r\n"
        b"\tgameInitData.sharkUserSecretShop = "
        b"gameInitData.sharkUserSecretShop or {}\r\n"
        b"\tgameInitData.sharkUserSecretShop.freeTimes = "
        b"(self.extraArgs and self.extraArgs.freeTimes) or 0\r\n"
        b"\tDataManager.setGameInitData(gameInitData)\r\n"
    )
    if b"\r\n" not in old:
        new = new.replace(b"\r\n", b"\n")
    return src.replace(old, new, 1)


def P_queuecard_skill_nil(src: bytes):
    """
    canon/panel/QueueCardPanel.lua

    When cardSkills lacks a SKILL_TYPE_NORMAL/MAIN entry, aSkillId stays nil and
    MetaManager.skill_meta[nil] is nil -> `aSkill.level` SIGKILLs right after login
    (MainMenu builds QueueCardPanel for the home formation strip).
    """
    # Two near-identical blocks (normal + main). Patch both.
    pat = re.compile(
        rb"(local aSkill = MetaManager\.skill_meta\[aSkillId\]\r?\n"
        rb"\s+local item_lv_bg = Sprite:createWithSpriteFrameName\(\"item_lv_bg\.png\"\)\r?\n"
        rb"\s+item_lv_bg:setPosition\(ccp\(23, 49\)\)\r?\n"
        rb"(?:\s+--[^\r\n]*\r?\n)?"
        rb"\s+card_lv = TextField:create\(\"lv\" \.\. aSkill\.level,\"Arial\", 20\))")
    repl = (
        b"local aSkill = aSkillId and MetaManager.skill_meta[aSkillId]\r\n"
        b"\t\t        local item_lv_bg = Sprite:createWithSpriteFrameName(\"item_lv_bg.png\")\r\n"
        b"\t\t        item_lv_bg:setPosition(ccp(23, 49))\r\n"
        b"\t\t        -- [patched] nil aSkillId/aSkill -> default lv1 (empty cardSkills)\r\n"
        b"\t\t        card_lv = TextField:create(\"lv\" .. ((aSkill and aSkill.level) or 1),\"Arial\", 20)")
    out2, n = pat.subn(repl, src)
    if n != 2:
        raise SystemExit(f"QueueCardPanel aSkill.level matched {n} times (expected 2)")
    # also guard pairs(aCard.cardSkills) — nil cardSkills
    out3, n2 = re.subn(
        rb"for key, value in pairs\(aCard\.cardSkills\) do",
        b"for key, value in pairs(aCard.cardSkills or {}) do",
        out2)
    if n2 < 2:
        raise SystemExit(f"cardSkills pairs guard matched {n2} times (expected >=2)")
    return out3


# --------------------------------------------------------------------------
# source patches:  (virtual lua path, human note, bytes -> bytes callable)
# --------------------------------------------------------------------------
def _single_sub(pat, repl):
    """Wrap one regex substitution as a bytes -> bytes patch."""
    def _apply(plain: bytes) -> bytes:
        out, n = pat.subn(repl, plain)
        if n != 1:
            raise SystemExit(f"pattern matched {n} times (expected exactly 1)")
        return out
    return _apply


def P_cardqueue_skills(src: bytes):
    """
    canon/scene/CardQueueScene.lua

    loadQueueData assumes every sharkCard already has `cardSkills` (as built by
    RewardManager.generateCard).  gameInit cards from our local server may omit
    it, and table.insert(nil, ...) kills the process on opening 编队/队伍.

    Also guard the equip-suit tip path where getSubTableByKey can return nil.
    """
    pat1 = re.compile(
        rb"(aCard\.skillStatus = \{\} --[^\r\n]*\r?\n"
        rb"\t\taCard\.skillTip = nil\r?\n)")
    repl1 = (b"aCard.skillStatus = {} -- card skill status\r\n"
             b"\t\taCard.skillTip = nil\r\n"
             b"\t\taCard.cardSkills = aCard.cardSkills or {}  "
             b"-- [patched] nil -> SIGKILL on table.insert\r\n")
    out, n1 = pat1.subn(repl1, src)
    if n1 != 1:
        raise SystemExit(f"cardSkills init matched {n1} times (expected 1)")

    # Wrap aEquipName dereference in `if aEquipMeta then ... end`
    old = (
        b'\t\t\t\t\t\tlocal aEquipName = MetaManager.equip_meta'
        b'[aEquipMeta.id - aEquipMeta.evolveLevel + 1]["name"]\r\n'
        b'\t\t\t\t\t\tif (not skillTipFlag) then\r\n'
        b'\t\t\t\t\t\t\taCard.skillTip = Localization:getInstance():getText(\r\n'
        b'\t\t\t\t\t\t\t\t"formation_equipSkillTips",\r\n'
        b'\t\t\t\t\t\t\t\t{itemname = getTextByKey(aEquipName)}\r\n'
        b'\t\t\t\t\t\t\t)\r\n'
        b'\t\t\t\t\t\t\tskillTipFlag = true\r\n'
        b'\t\t\t\t\t\tend\r\n'
    )
    new = (
        b'\t\t\t\t\t\tif aEquipMeta and MetaManager.equip_meta'
        b'[aEquipMeta.id - aEquipMeta.evolveLevel + 1] then\r\n'
        b'\t\t\t\t\t\t\tlocal aEquipName = MetaManager.equip_meta'
        b'[aEquipMeta.id - aEquipMeta.evolveLevel + 1]["name"]\r\n'
        b'\t\t\t\t\t\t\tif (not skillTipFlag) then\r\n'
        b'\t\t\t\t\t\t\t\taCard.skillTip = Localization:getInstance():getText(\r\n'
        b'\t\t\t\t\t\t\t\t\t"formation_equipSkillTips",\r\n'
        b'\t\t\t\t\t\t\t\t\t{itemname = getTextByKey(aEquipName)}\r\n'
        b'\t\t\t\t\t\t\t\t)\r\n'
        b'\t\t\t\t\t\t\t\tskillTipFlag = true\r\n'
        b'\t\t\t\t\t\t\tend\r\n'
        b'\t\t\t\t\t\tend  -- [patched] nil aEquipMeta guard\r\n'
    )
    if out.count(old) != 1:
        raise SystemExit(f"aEquipMeta block matched {out.count(old)} times (expected 1)")
    return out.replace(old, new, 1)

def P_six_point(src: bytes):
    """
    canon/scene/CreateCharacterScene.lua

    After a successful createUser the client runs a Happy Elements *ad-campaign*
    tracking block ("he广告推广包 打6号点").  It calls two helpers that DO NOT
    EXIST anywhere in this build:

        localStorage.getSixPointIsExist()   -- nil
        localStorage.saveSixPoint()         -- nil

    ...and it POSTs the new uid to Happy Elements' promotion server via
    DcManager.sendOfficialPromoteInfo().  In the shipped channel build this
    branch was dead code (isPlatformAndroid() was false for the .baiduDK
    package); our SDK-bypass patch turned it true and thereby exposed the bug.

    The block is pure marketing telemetry, irrelevant to gameplay, and phoning
    a third-party tracker is undesirable -- so drop it entirely.  The removed
    text is `if ... end` (balanced), the replacement is a comment (balanced).
    """
    pat = re.compile(
        rb"if\s+isPlatformAndroid\(\)\s+and\s+localStorage\.getSixPointIsExist\(\)"
        rb".*?localStorage\.saveSixPoint\(\)\s*\r?\n\s*end",
        re.S)
    repl = (b"-- [patched] 6-point ad-tracking block removed: "
            b"localStorage.getSixPointIsExist/saveSixPoint are not defined in "
            b"this build (would be a nil-call, and the engine SIGKILLs on Lua errors)")
    return _single_sub(pat, repl)(src)


def P_null_sprites(src: bytes):
    """
    hecore/display/Sprite.lua

    `CCSprite:create(<missing file>)` / `CCSprite:createWithSpriteFrameName(
    <missing frame>)` return a NULL C++ pointer, which tolua surfaces as nil.
    The wrapper then holds refCocosObj == nil; adding it to a node makes the
    engine hand NULL to C++ and the GLThread dies with

        Fatal signal 11 (SIGSEGV), fault addr 0x0 ... in GLThread

    with NO Lua error and NO crash file (so all the usual diagnostics are
    silent).  This can happen on a channel build that ships a subset of the
    original assets.

    Fix: log the offending asset name AND substitute an empty CCSprite so the
    scene graph stays non-NULL and the game keeps running.
    """
    # NOTE: the decrypted Lua uses CRLF, so every pattern uses \r?\n.
    # Sprite:create  -> insert the guard just before `return Sprite.new(sprite)`
    pat1 = re.compile(
        rb"(local sprite = nil\r?\n"
        rb".*?\r?\n"
        rb"    return )Sprite\.new\(sprite\)",
        re.S)
    repl1 = (rb"\1Sprite.new(sprite or _safeSprite(fileName))")

    # Sprite:createWithSpriteFrameName
    pat2 = re.compile(
        rb"function Sprite:createWithSpriteFrameName\(frameName\)\r?\n"
        rb"\s*return Sprite\.new\(CCSprite:createWithSpriteFrameName\(frameName\)\);")
    repl2 = (b"function Sprite:createWithSpriteFrameName(frameName)\r\n"
             b"  local s = CCSprite:createWithSpriteFrameName(frameName)\r\n"
             b"  if not s then\r\n"
             b"    print(\"!!!NULL_SPRITE_FRAME: \" .. tostring(frameName))\r\n"
             b"    s = CCSprite:create()\r\n"
             b"  end\r\n"
             b"  return Sprite.new(s);")

    # combined: apply both, verifying each matched exactly once
    def _sub(plain: bytes):
        out, c1 = pat1.subn(repl1, plain)
        if c1 != 1:
            raise SystemExit(f"Sprite:create guard matched {c1} times")
        out, c2 = pat2.subn(repl2, out)
        if c2 != 1:
            raise SystemExit(f"createWithSpriteFrameName guard matched {c2} times")
        # Sprite:createWithSpriteFrame(nil-or-dead-frame)
        pat3 = re.compile(
            rb"function Sprite:createWithSpriteFrame\(frame\)\r?\n"
            rb"\s*return Sprite\.new\(CCSprite:createWithSpriteFrame\(frame\)\);")
        repl3 = (b"function Sprite:createWithSpriteFrame(frame)\r\n"
                 b"  local s = nil\r\n"
                 b"  if frame then s = CCSprite:createWithSpriteFrame(frame) end\r\n"
                 b"  if not s then\r\n"
                 b"    print(\"!!!NULL_SPRITE_FRAME_OBJ\")\r\n"
                 b"    s = CCSprite:create()\r\n"
                 b"  end\r\n"
                 b"  return Sprite.new(s);")
        out, c3 = pat3.subn(repl3, out)
        if c3 != 1:
            raise SystemExit(f"createWithSpriteFrame guard matched {c3} times")
        # inject the helper right after `Sprite = class(CocosObject);`
        helper = (b"\r\nlocal function _safeSprite(fileName)\r\n"
                  b"  print(\"!!!NULL_SPRITE: \" .. tostring(fileName))\r\n"
                  b"  return CCSprite:create()\r\n"
                  b"end\r\n")
        out, c4 = re.subn(rb"(\r?\n)Sprite = class\(CocosObject\);\r?\n",
                          rb"\1Sprite = class(CocosObject);" + helper, out)
        if c4 != 1:
            raise SystemExit(f"_safeSprite injection matched {c4} times")
        return out

    return _sub(src)


def P_null_cocosobject(src: bytes):
    """
    hecore/display/CocosObject.lua -- diagnostic.

    A NULL C++ pointer stored as refCocosObj is what produces the otherwise
    invisible GLThread SIGSEGV (fault addr 0x0).  Log it together with a Lua
    traceback so the exact construction site (and asset) is named.
    """
    pat = re.compile(
        rb"(function CocosObject:ctor\(refCocosObj\)\r?\n"
        rb".*?\r?\n"
        rb"    self:setRefCocosObj\(refCocosObj\)\r?\n)",
        re.S)
    repl = (b"\\1"                       # backslash-1 == regex group 1
            b"    if not self.refCocosObj then\r\n"
            b'      print("!!!NULL_COCOS_OBJECT name=" .. tostring(self.name))\r\n'
            b"      print(debug.traceback())\r\n"
            b"    end\r\n")
    return _single_sub(pat, repl)(src)


def P_card_frame_fallback(src: bytes):
    """
    canon/canonUtils.lua :: getCardSpriteFrameForName

        local cardSprite = CardSprite:create("card/card/" .. meta.figureId, "full")
        return cardSprite:getSpriteFrameByName(name)

    `getCardSpriteFrame(metaId)` asks for "sdandard.png" (sic).  This APK only
    ships `full.png` for the card atlases -- of 879 card art directories exactly
    ONE (youguanyu_1) also contains a standard-size frame; the rest were streamed
    from the CDN at runtime.

    A missing frame yields a NULL CCSpriteFrame -> CCSprite:createWithSpriteFrame
    returns NULL -> the node ends up with a null texture, and the GLThread dies
    with `Fatal signal 11 (SIGSEGV) fault addr 0x0` while drawing the home
    screen's main card, with no Lua error and no crash file.

    Fall back to the always-present "full.png" frame.
    """
    pat = re.compile(
        rb"(function getCardSpriteFrameForName\(metaId, name\)\r?\n"
        rb"\tlocal meta = MetaManager\.card_meta\[metaId\]\r?\n"
        rb"\tif meta then\r?\n)"
        rb"(\t\tif isInAppleReview\(\) then\r?\n"
        rb"\t\t\tlocal cardSprite = CardSprite:create\(\"card/card/\" \.\. meta\.harmoniousFigureID, \"full\"\)\r?\n"
        rb"\t\t\treturn cardSprite:getSpriteFrameByName\(name\)\r?\n"
        rb"\t\telse\r?\n"
        rb"\t\t\tlocal cardSprite = CardSprite:create\(\"card/card/\" \.\. meta\.figureId, \"full\"\)\r?\n"
        rb"\t\t\treturn cardSprite:getSpriteFrameByName\(name\)\r?\n"
        rb"\t\tend\r?\n)",
        re.S)
    repl = (b"\\1"                        # backslash-1 == regex group 1
            b"\t\tlocal cardSprite\r\n"
            b"\t\tif isInAppleReview() then\r\n"
            b'\t\t\tcardSprite = CardSprite:create("card/card/" .. meta.harmoniousFigureID, "full")\r\n'
            b"\t\telse\r\n"
            b'\t\t\tcardSprite = CardSprite:create("card/card/" .. meta.figureId, "full")\r\n'
            b"\t\tend\r\n"
            b"\t\tlocal frame = cardSprite and cardSprite:getSpriteFrameByName(name)\r\n"
            b"\t\tif not frame and cardSprite then\r\n"
            b"\t\t\t-- [patched] standard-size frame not shipped in this build; the\r\n"
            b"\t\t\t-- 'full' frame always is.  Prevents a NULL sprite -> GL SIGSEGV.\r\n"
            b'\t\t\tframe = cardSprite:getSpriteFrameByName("full.png")\r\n'
            b"\t\tend\r\n"
            b"\t\tif not frame then\r\n"
            b'\t\t\tprint("!!!NO_CARD_FRAME figure=" .. tostring(meta.figureId) .. " wanted=" .. tostring(name))\r\n'
            b"\t\tend\r\n"
            b"\t\treturn frame\r\n")
    return _single_sub(pat, repl)(src)


def P_textureless_sprites(src: bytes):
    """
    hecore/display/Sprite.lua + Scale9Sprite.

    `Sprite:create()` with NO filename, and `Sprite:create(<missing file>)`, both
    end up wrapping `CCSprite:create()` -- a sprite with a NULL texture.  Such a
    node is perfectly happy in Lua, but on the next GL frame
    `CCSprite::draw()` dereferences the null texture and the process dies with

        Fatal signal 11 (SIGSEGV), fault addr 0x0 ... in GLThread

    no Lua error, no crash file.  LayoutBuilder.build uses exactly this form
    (line 221: `image = assert(Sprite:create())` when width/height == 0).

    Fix: substitute a sprite built from a texture that is definitely present
    (`pic/base_ui_bg.png`, already used by BaseUIScene:initBackGround on the
    screens that render fine), and log it so the caller is identifiable.
    """
    # 1) the no-filename branch of Sprite:create
    pat1 = re.compile(
        rb"function Sprite:create\(fileName\)\r?\n"
        rb"  if not fileName then \r?\n"
        rb"    local sprite = CCSprite:create\(\)\r?\n"
        rb"    return Sprite\.new\(sprite\)\r?\n"
        rb"  end\r?\n")
    repl1 = (b"function Sprite:create(fileName)\r\n"
             b"  if not fileName then\r\n"
             b"    -- [patched] textureless CCSprite segfaults in draw()\r\n"
             b"    print(\"!!!TEXTURELESS_SPRITE\")\r\n"
             b"    print(debug.traceback())\r\n"
             b"    return Sprite.new(CCSprite:create(\"pic/base_ui_bg.png\"))\r\n"
             b"  end\r\n")

    # 2) Scale9Sprite:create with a missing file
    pat2 = re.compile(
        rb"function Scale9Sprite:create\(fileName, capInsets\)\r?\n"
        rb"  capInsets = capInsets or kZeroCapInsets\r?\n"
        rb"  local sprite = CCScale9Sprite:create\(capInsets, fileName\)\r?\n"
        rb"    return Scale9Sprite\.new\(sprite\)\r?\n"
        rb"end\r?\n")
    repl2 = (b"function Scale9Sprite:create(fileName, capInsets)\r\n"
             b"  capInsets = capInsets or kZeroCapInsets\r\n"
             b"  local sprite = CCScale9Sprite:create(capInsets, fileName)\r\n"
             b"  if not sprite then\r\n"
             b"    -- [patched] missing nine-slice art -> null texture -> GL SIGSEGV\r\n"
             b"    print(\"!!!NULL_9SLICE: \" .. tostring(fileName))\r\n"
             b"    sprite = CCScale9Sprite:create(capInsets, \"pic/base_ui_bg.png\")\r\n"
             b"  end\r\n"
             b"    return Scale9Sprite.new(sprite)\r\n"
             b"end\r\n")

    out, c1 = pat1.subn(repl1, src)
    if c1 != 1:
        raise SystemExit(f"textureless-sprite patch matched {c1}")
    out, c2 = pat2.subn(repl2, out)
    if c2 != 1:
        raise SystemExit(f"nine-slice patch matched {c2}")
    return out


def P_image_probe(src: bytes):
    """
    hecore/ui/LayoutBuilder.lua -- DEFINITIVE diagnostic.

    Answers two questions at once:
      1) which virtual image paths does the client actually request?
         (path = UI_RES_PATH .. "/" .. sceneFolder .. "/" .. symbol.image .. ".png")
      2) when a file is absent, does Cocos return Lua `nil` or a NON-NIL userdata
         whose internal pointer is NULL?  `if not sprite` only catches the
         former, which is why the existing !!!NULL_SPRITE guard never fired.

    tostring() on a tolua userdata yields the pointer (e.g. "CCSprite: 0x0"),
    so it distinguishes the two cases without dereferencing anything.
    """
    CRLF = b"\r\n"

    def probe(pathvar, tag):
        return (b"          local " + pathvar + b" = UI_RES_PATH..\"/\"..self.sceneFolder..\"/\"..symbol.image..\".png\"" + CRLF +
                b"          print(\"!!!IMG_REQ " + tag + b" \".." + pathvar + b")" + CRLF)

    # ---- 1) log each group + sceneFolder once -------------------------------
    pat_a = re.compile(rb"(\r\n  groupLayer\.name = groupName\r?\n)")
    repl_a = (b"\r\n  groupLayer.name = groupName" + CRLF +
              b"  print(\"!!!BUILD_GROUP \"..tostring(groupName)..\" folder=\"..tostring(self.sceneFolder))" + CRLF)

    # ---- 2) nine-slice branch (Scale9Sprite) --------------------------------
    pat_b = re.compile(
        rb"        image = assert\(Scale9Sprite:create\(UI_RES_PATH\.\.\"/\"\.\.self\.sceneFolder\.\.\"/\"\.\.symbol\.image\.\.\"\.png\"\)\)\r?\n")
    repl_b = (b"        local __p9 = UI_RES_PATH..\"/\"..self.sceneFolder..\"/\"..symbol.image..\".png\"" + CRLF +
              b"        print(\"!!!IMG_REQ 9SLICE \"..__p9)" + CRLF +
              b"        image = Scale9Sprite:create(__p9)" + CRLF +
              b"        local __n9 = (image and image.refCocosObj) and 1 or 0" + CRLF +
              b"        local __s9 = \"nil\"" + CRLF +
              b"        if __n9 == 1 then __s9 = tostring(image.refCocosObj) end" + CRLF +
              b"        print(\"!!!IMG_OBJ 9SLICE n=\"..__n9..\" raw=\"..__s9)" + CRLF +
              b"        if __n9 == 1 and string.find(__s9, \"0x0\", 1, true) then print(\"!!!IMG_NULLPTR_9SLICE \"..__p9) end" + CRLF)

    # ---- 3) normal branch (Sprite) -----------------------------------------
    pat_c = re.compile(
        rb"        if symbol\.width == 0 or symbol\.height == 0 then\r?\n"
        rb"          image = assert\(Sprite:create\(\)\)\r?\n"
        rb"        else\r?\n"
        rb"          image = assert\(Sprite:create\(UI_RES_PATH\.\.\"/\"\.\.self\.sceneFolder\.\.\"/\"\.\.symbol\.image\.\.\"\.png\"\)\)\r?\n"
        rb"        end\r?\n")
    repl_c = (b"        if symbol.width == 0 or symbol.height == 0 then" + CRLF +
              b"          image = Sprite:create()" + CRLF +
              b"        else" + CRLF +
              probe(b"__p", b"SPRITE") +
              b"          image = Sprite:create(__p)" + CRLF +
              b"          local __n = (image and image.refCocosObj) and 1 or 0" + CRLF +
              b"          local __s = \"nil\"" + CRLF +
              b"          if __n == 1 then __s = tostring(image.refCocosObj) end" + CRLF +
              b"          print(\"!!!IMG_OBJ SPRITE n=\"..__n..\" raw=\"..__s)" + CRLF +
              b"          if __n == 1 and string.find(__s, \"0x0\", 1, true) then print(\"!!!IMG_NULLPTR \"..__p) end" + CRLF +
              b"        end" + CRLF)

    out, ca = pat_a.subn(repl_a, src)
    if ca != 1:
        raise SystemExit(f"group-log pattern matched {ca}")
    out, cb = pat_b.subn(repl_b, out)
    if cb != 1:
        raise SystemExit(f"nine-slice probe matched {cb}")
    out, cc = pat_c.subn(repl_c, out)
    if cc != 1:
        raise SystemExit(f"sprite probe matched {cc}")
    return out


def P_textfield_art_stubs(src: bytes):
    """
    hecore/display/TextField.lua

    With useArtLabelTTF=false, LayoutBuilder builds plain TextField labels.
    Call sites throughout the game still invoke ArtTextField-only APIs
    (setAroundColor / getAroundColor).  Stub them as no-ops on TextField so
    BaseUIScene:onInit and friends keep running.
    """
    pat = re.compile(
        rb"(function TextField:setColor\(v\) self\.refCocosObj:setColor\(v\) end\r?\n)")
    repl = (rb"\1"
            rb"function TextField:setAroundColor(v, noreconstruct) end  "
            rb"-- [patched] ArtTextField API stub for TTF fallback\r\n"
            rb"function TextField:getAroundColor() return ccc3(0,0,0) end\r\n")
    return _single_sub(pat, repl)(src)


def P_guide_coro_errors(src: bytes):
    """
    canon/script_and_guide/NewUserGuideCoroutine.lua

    coroutine.resume errors are silently discarded; a dead coroutine then
    still fires onFinishHandle.  Surface the error so MainMenuScene failures
    after the tutorial are visible in logcat.
    """
    pat = re.compile(
        rb"local function resume\(co\)\r?\n"
        rb"\tcoroutine\.resume\(co\)\r?\n"
        rb"\tif onFinishHandle and coroutine\.status\(co\) == \"dead\" then\r?\n"
        rb"\t\tonFinishHandle\(\)\r?\n"
        rb"\tend\r?\n"
        rb"end")
    repl = (b"local function resume(co)\r\n"
            b"\tlocal ok, err = coroutine.resume(co)\r\n"
            b"\tif not ok then\r\n"
            b"\t\tprint(\"!!!GUIDE_COROUTINE_ERROR: \" .. tostring(err))\r\n"
            b"\t\tprint(debug.traceback())\r\n"
            b"\tend\r\n"
            b"\tif onFinishHandle and coroutine.status(co) == \"dead\" then\r\n"
            # MainMenuScene:create() runs here; errors are OUTSIDE coroutine.resume
            # and were previously invisible (black screen, process alive).
            b"\t\tlocal ok2, err2 = pcall(onFinishHandle)\r\n"
            b"\t\tif not ok2 then\r\n"
            b"\t\t\tprint(\"!!!GUIDE_FINISH_ERROR: \" .. tostring(err2))\r\n"
            b"\t\t\tprint(debug.traceback())\r\n"
            b"\t\tend\r\n"
            b"\tend\r\n"
            b"end")
    return _single_sub(pat, repl)(src)


def P_baseui_progress(src: bytes):
    """
    canon/scene/BaseUIScene.lua -- progress prints + guard setAroundColor so a
    missing ArtTextField API cannot abort MainMenuScene:onInit.
    """
    pat = re.compile(
        rb'(\tlocal orgText = self\.BaseUi:getChildByName\("home_menu_title"\):'
        rb'getChildByName\("txt_icon_playerExp_num"\):getChildByName\("font"\)\r?\n'
        rb'\t)orgText:setAroundColor\(aroundColor or ccc3\(0,0,0\)\)\r?\n')
    repl = (rb'\1print("!!!BASEUI_after_build vip/exp wiring")\r\n'
            rb'\tif orgText and orgText.setAroundColor then '
            rb'orgText:setAroundColor(aroundColor or ccc3(0,0,0)) end\r\n')
    out = _single_sub(pat, repl)(src)

    pat2 = re.compile(
        rb'(self\.BaseUi = self\.builder:build\("shouye_home_menu"\)\r?\n)')
    repl2 = rb'\1\tprint("!!!BASEUI_build_done")\r\n'
    out, n = pat2.subn(repl2, out)
    if n != 1:
        raise SystemExit(f"BASEUI_build_done probe matched {n}")

    # Mark successful completion of BaseUIScene:onInit (after addChild).
    pat3 = re.compile(rb'(self:addChild\(self\.BaseUi\)\r?\n)')
    repl3 = (rb'\1\tprint("!!!BASEUI_addChild_done")\r\n')
    out, n3 = pat3.subn(repl3, out)
    if n3 != 1:
        raise SystemExit(f"BASEUI_addChild_done probe matched {n3}")

    # Refresh silver coins alongside exp/level in sufEnterAnimation.  Coin
    # rewards update GameData in RewardManager but BaseUISceneDataChanged is
    # often skipped (g_isInBattleScene / missing .list); exp already refreshes
    # here which is why users saw exp work and coins not.
    # Anchor on sufEnterAnimation only (the early onInit setPercentage is
    # followed by sprite:setZOrder, not resetLevelAndExpUI).
    pat4 = re.compile(
        rb"(g_BaseUISceneExpBar\[0\]:setPercentage\(userData\.exp \* 100 / "
        rb"MetaManager\.user_level\[userData\.level\]\.exp\)\r?\n"
        rb"\tend\r?\n"
        rb"\tresetLevelAndExpUI\(\))")
    # IMPORTANT: use real " in the bytes (not \") — a bare \" opens a bogus
    # string for lua_balance / the Lua parser and nukes keyword counting.
    repl4 = (
        b"g_BaseUISceneExpBar[0]:setPercentage(userData.exp * 100 / "
        b"MetaManager.user_level[userData.level].exp)\r\n"
        b'\t\tg_BaseUISceneObject:getChildByName("home_menu_title"):'
        b'getChildByName("txt_icon_silverCoin_test_num"):getChildByName("font"):'
        b"setString(tostring(userData.coins))\r\n"
        b"\tend\r\n"
        b"\tresetLevelAndExpUI()")
    out, n4 = pat4.subn(repl4, out)
    if n4 != 1:
        print(f"    [warn] coin refresh in sufEnterAnimation matched {n4}")
    return out


def P_disable_artfont(src: bytes):
    """
    canon/scene/BaseUIScene.lua

        self.builder = LayoutBuilder:createWithContentsOfFile("scene/shouye_new.json")
        self.builder.useArtLabelTTF = true          <- line 258
        self.BaseUi = self.builder:build("shouye_home_menu")

    With useArtLabelTTF set, LayoutBuilder.buildText renders every white static
    label through the NATIVE ArtTextField (an art/bitmap-font renderer) instead
    of the ordinary TextField.  ArtTextField is not a Lua class, so none of the
    Sprite/CocosObject guards can see a failure inside it, and the observed
    crash is a GLThread SIGSEGV at fault addr 0x0 occurring immediately after
    the last txt/* group is built -- i.e. while the art-font labels are drawn.

    Disabling it falls back to TextField (plain TTF), the same path the login
    and character-creation screens use, which render correctly.
    """
    pat = re.compile(rb"(\tself\.builder = LayoutBuilder:createWithContentsOfFile\(\"scene/shouye_new\.json\"\)\r?\n"
                     rb"\t)self\.builder\.useArtLabelTTF = true(\r?\n)")
    repl = rb"\1self.builder.useArtLabelTTF = false\2"
    return _single_sub(pat, repl)(src)


def P_preload_messagebox(src: bytes):
    """
    canon/scene/LoadingScene.lua

    CanonMessageBox is also required by DynamicUpdateScene / LoginScene, but
    MainMenuScene uses it without its own require (relying on side-effects).
    NewUserGuideCoroutine notes that require() across a C boundary inside a
    coroutine can fail.  Preload here (main thread, before any guide coroutine)
    so package.loaded already holds CanonMessageBox + its deps.
    """
    pat = re.compile(rb'(require "canon\.script_and_guide\.NewUserGuide"\r?\n)')
    repl = (rb'\1'
            rb'require "canon.panel.CanonMessageBox"  '
            rb'-- [patched] preload before NewUserGuide coroutine\r\n')
    return _single_sub(pat, repl)(src)


def P_spirit_level_guard(src: bytes):
    """
    canon/manager/SpiritManager.lua

    isUserLevelEnough does `user.level >= spiritSettingConfig.unlockLevel`
    with no nil guard. Empty/partial getMeta => SIGKILL on MainMenu scroll.
    Mirror TreasureManager's defensive fallback.
    """
    pat = re.compile(
        rb"function SpiritManager\.isUserLevelEnough\(\)\r?\n"
        rb"\treturn DataManager\.getCurrUser\(\)\.level >= "
        rb"DataManager\.GameMetaData\.spiritSettingConfig\.unlockLevel\r?\n"
        rb"end")
    repl = (
        b"function SpiritManager.isUserLevelEnough()\r\n"
        b"\tlocal cfg = DataManager.GameMetaData.spiritSettingConfig\r\n"
        b"\tlocal need = (cfg and cfg.unlockLevel) or 60\r\n"
        b"\tlocal u = DataManager.getCurrUser()\r\n"
        b"\treturn (u and u.level or 0) >= need\r\n"
        b"end")
    return _single_sub(pat, repl)(src)


def P_battle_weapon_guard(src: bytes):
    """
    canon/scene/BattleScene.lua

    Chapter battles resolve enemy weapon via battle_monster[monsterId].cardId
    with no nil checks. Missing group/monster for some mission tiles =>
    SIGKILL mid-stage. Keep weapon lookup optional.
    """
    pat = re.compile(
        rb"\t\t\t\tlocal cardId = MetaManager\.battle_monster\[tonumber\(monsterId\)\]\.cardId\r?\n"
        rb"\t\t\t\t\r?\n"
        rb"\t\t\t\tlocal cardMeta = MetaManager\.card_meta\[tonumber\(cardId\)\]\r?\n"
        rb"\t\t\t\t\r?\n"
        rb"\t\t\t\tself\.enemyWeaponInfo\.weaponType = cardMeta\.weaponType\r?\n"
        rb"\t\t\t\tself\.enemyWeaponInfo\.evolveLevel = cardMeta\.rare\r?\n")
    repl = (
        b"\t\t\t\tlocal mon = monsterId and MetaManager.battle_monster[tonumber(monsterId)]\r\n"
        b"\t\t\t\tlocal cardMeta = mon and MetaManager.card_meta[tonumber(mon.cardId)]\r\n"
        b"\t\t\t\tif cardMeta then\r\n"
        b"\t\t\t\t\tself.enemyWeaponInfo.weaponType = cardMeta.weaponType\r\n"
        b"\t\t\t\t\tself.enemyWeaponInfo.evolveLevel = cardMeta.rare\r\n"
        b"\t\t\t\tend\r\n")
    return _single_sub(pat, repl)(src)


PATCHES = [
    # (virtual path, note, builder)
    ("canon/scene/CreateCharacterScene.lua",
     "drop 6-point ad-tracking block (nil-call crash)",
     P_six_point),
    # NOTE: one builder per FILE -- both Sprite.lua fixes must be chained here,
    # because main() re-reads the pristine asset for each registry entry.
    ("hecore/display/Sprite.lua",
     "guard NULL / textureless sprites and missing nine-slices",
     lambda s: P_textureless_sprites(P_null_sprites(s))),
    ("hecore/display/CocosObject.lua",
     "traceback on NULL native object (diagnostic)",
     P_null_cocosobject),
    ("canon/canonUtils.lua",
     "fall back to full.png when a card frame is missing (NULL texture -> SIGSEGV)",
     P_card_frame_fallback),
    ("hecore/ui/LayoutBuilder.lua",
     "PROBE: log every requested image path + detect NULL pointer returns",
     P_image_probe),
    ("canon/scene/BaseUIScene.lua",
     "disable ArtTextField + progress probes + guard setAroundColor",
     lambda s: P_baseui_progress(P_disable_artfont(s))),
    ("canon/scene/LoadingScene.lua",
     "preload CanonMessageBox before NewUserGuide coroutine",
     P_preload_messagebox),
    ("hecore/display/TextField.lua",
     "stub setAroundColor/getAroundColor on TextField (TTF fallback)",
     P_textfield_art_stubs),
    ("canon/script_and_guide/NewUserGuideCoroutine.lua",
     "print swallowed guide-coroutine errors",
     P_guide_coro_errors),
    ("canon/manager/SpiritManager.lua",
     "nil-safe isUserLevelEnough (MainMenu SpiritBackPack scroll)",
     P_spirit_level_guard),
    ("canon/scene/BattleScene.lua",
     "nil-safe enemy weapon lookup on chapter tiles",
     P_battle_weapon_guard),
    ("canon/scene/CardQueueScene.lua",
     "nil-safe cardSkills + equipMeta on 编队/队伍",
     P_cardqueue_skills),
    ("canon/panel/QueueCardPanel.lua",
     "nil-safe skill level when cardSkills missing NORMAL/MAIN",
     P_queuecard_skill_nil),
    ("canon/luajava/GspBridge.lua",
     "local offline pay via validatePaymentOrder (skip native GSP)",
     P_local_pay),
    ("canon/scene/ShopScene.lua",
     "nil-safe getStartTime for empty double-charge maintenance",
     P_shop_charge_double),
    ("canon/scene/ActivityPanelScene.lua",
     "nil-safe secretShop + pcall tip/enable",
     lambda s: P_activity_enable_pcall(
         P_activity_tip_pcall(P_activity_secret_shop_interval(s)))),
    ("canon/layer/Activity_MysteryShopLayer.lua",
     "nil-safe sharkUserSecretShop.freeTimes write",
     P_mystery_shop_secret),
    ("canon/panel/CalendarSignInPanel.lua",
     "always allow empty-area close on startup 每日签到 popPanel",
     P_calendar_signin_close),
    ("canon/layer/Activity_LotteryFortuneLayer.lua",
     "nil-safe fortuneFreeTime in getTipNum/shouldShowParticle",
     P_fortune_tip_guard),
    ("canon/scene/MainMenuScene.lua",
     "pcall Activity getTipNum so tip refresh never SIGKILLs",
     P_mainmenu_tip_pcall),
]


# --------------------------------------------------------------------------
def decrypt(blob):
    return zlib.decompress(unpad(AES.new(KEY, AES.MODE_CBC, blob[:16]).decrypt(blob[16:]), 16))


def encrypt(src):
    iv = os.urandom(16)
    return iv + AES.new(KEY, AES.MODE_CBC, iv).encrypt(pad(zlib.compress(src, 9), 16))


def lua_balance(src: bytes):
    """Cheap Lua block-keyword balance meter (skips strings/comments)."""
    i, n = 0, len(src)
    opens = ends = 0
    while i < n:
        if src.startswith(b"--[[", i):
            j = src.find(b"]]", i + 4); i = (j + 2) if j >= 0 else n; continue
        if src.startswith(b"--", i):
            j = src.find(b"\n", i); i = (j + 1) if j >= 0 else n; continue
        c = src[i]
        if c in (0x22, 0x27):
            q = c; i += 1
            while i < n and src[i] != q:
                if src[i] == 0x5C: i += 1
                i += 1
            i += 1; continue
        if src.startswith(b"[[", i):
            j = src.find(b"]]", i + 2); i = (j + 2) if j >= 0 else n; continue
        if (65 <= c <= 90) or (97 <= c <= 122) or c == 0x5F:
            j = i
            while j < n and ((65 <= src[j] <= 90) or (97 <= src[j] <= 122) or
                             (48 <= src[j] <= 57) or src[j] == 0x5F):
                j += 1
            w = src[i:j]
            if w in (b"function", b"if", b"for", b"while"):
                opens += 1
            elif w == b"do":
                k = src.rfind(b"\n", 0, i)
                if b"for" not in src[k + 1:i] and b"while" not in src[k + 1:i]:
                    opens += 1
            elif w == b"end":
                ends += 1
            elif w == b"repeat":
                opens += 1
            elif w == b"until":
                ends += 1
            i = j; continue
        i += 1
    return opens, ends


def find_manifest(z):
    m = [x for x in z.namelist()
         if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", x)]
    if len(m) != 1:
        raise SystemExit(f"expected exactly 1 manifest, got {m}")
    return m[0]


def main():
    zin = zipfile.ZipFile(SRC_APK)
    names = zin.namelist()
    manifest_old = find_manifest(zin)
    manifest_txt = zin.read(manifest_old)
    print(f"source APK : {SRC_APK}")
    print(f"manifest   : {manifest_old}")

    replacements = {}   # old_name -> (new_name, blob)
    new_manifest = manifest_txt

    for virt, note, builder in PATCHES:
        prefix = "assets/src/" + virt.rsplit(".", 1)[0] + "."
        hits = [x for x in names if x.startswith(prefix) and x.endswith(".lua")]
        if len(hits) != 1:
            raise SystemExit(f"{virt}: expected 1 asset, got {hits}")
        old_name = hits[0]
        old_blob = zin.read(old_name)
        old_md5 = hashlib.md5(old_blob).hexdigest()

        plain = decrypt(old_blob)
        new_plain = builder(plain)
        if new_plain == plain:
            raise SystemExit(f"{virt}: patch was a no-op")

        b0, b1 = lua_balance(plain), lua_balance(new_plain)
        if (b0[0] - b0[1]) != (b1[0] - b1[1]):
            raise SystemExit(f"{virt}: block balance delta changed "
                             f"{b0} -> {b1} (patch broke syntax)")

        new_blob = encrypt(new_plain)
        new_md5 = hashlib.md5(new_blob).hexdigest()
        new_name = old_name.replace(old_md5, new_md5)
        assert decrypt(new_blob) == new_plain, "round-trip failed"

        print(f"\n  [{virt}]  {note}")
        print(f"    asset  {old_name.split('/')[-1]}")
        print(f"        -> {new_name.split('/')[-1]}")
        print(f"    size   {len(old_blob)} -> {len(new_blob)}   balance {b0} -> {b1}")

        # manifest entry: value="<basename>" md5="<old>" size="<old>"
        base = re.escape(virt.rsplit("/", 1)[1]).encode()
        rx = re.compile(rb'(value="' + base + rb'"\s+md5=")' + old_md5.encode() +
                        rb'("\s+size=")\d+(")')
        new_manifest, c = rx.subn(rb'\g<1>' + new_md5.encode() + rb'\g<2>' +
                                  str(len(new_blob)).encode() + rb'\g<3>', new_manifest)
        if c != 1:
            raise SystemExit(f"{virt}: manifest entry not updated (matches={c})")
        replacements[old_name] = (new_name, new_blob)

    man_md5 = hashlib.md5(new_manifest).hexdigest()
    man_new = "assets/static_config.%s.xml" % man_md5
    print(f"\n  manifest md5 {manifest_old.split('.')[1]} -> {man_md5}")

    print("\nrebuilding APK ...")
    zout = zipfile.ZipFile(OUT_APK, "w", zipfile.ZIP_DEFLATED)
    for item in zin.infolist():
        fn = item.filename
        if fn in replacements:
            nn, blob = replacements[fn]
            zout.writestr(nn, blob)
        elif fn == manifest_old:
            zout.writestr(man_new, new_manifest)
        else:
            zout.writestr(item, zin.read(fn))
    zout.close()

    z = zipfile.ZipFile(OUT_APK)
    for nn, blob in replacements.values():
        assert hashlib.md5(z.read(nn)).hexdigest() in nn
    assert hashlib.md5(z.read(man_new)).hexdigest() == man_md5
    assert manifest_old not in z.namelist()
    print(f"DONE -> {OUT_APK}  ({os.path.getsize(OUT_APK)/1024/1024:.1f} MB, "
          f"{len(z.namelist())} entries)")
    print(f"  NEW MANIFEST: {man_new}")


if __name__ == "__main__":
    main()
