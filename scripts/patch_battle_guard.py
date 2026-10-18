# -*- coding: utf-8 -*-
"""客户端 BattleScene 补丁（走 Caches/src 热补丁覆盖，不用重打包 APK）。

一共三处改动：

1. **空队列 nil 保护**（修 `BattleScene.lua:1372 attempt to index local 'fightEvent'`）
   `playBattleFlash()` 在「事件流走空 + 有一方血量归零」时会无条件取
   `fightEventFlow[1]` → index nil。正常流程里致命一击走的是
   `playLastHitAnim -> FightDeath -> Win/Crash/Lose`，不会再回到这里，但我们
   自己造的事件流会踩到。补丁：取事件前判空，空则直接播终局演出。

2. **我方主角卡破碎立绘预载**（setup 里，紧随敌方 `card2crash` 那段）
   记到 `SELF.crushSpriteSelf`，战败时用来替换 `card2crash`。

3. **战败也播爆衣**（`onFlashAnimationEnd` 的 `FightDeath` 分支，非胜利那一半）
   原本固定 `changeAnimation(BattleAnimEnum.Lose)`（只有倒地，没有立绘）。
   有 `SELF.crushSpriteSelf` 时改成：把 `card2crash` 换成我方主角卡的破碎立绘，
   再播 `BattleAnimEnum.Crash` —— 和战胜时看敌方爆衣是同一段动画。

⚠️ `Crash` 动画只能在整个 `battle_flash` 里**确实存在 `card2crash` 实例**时播，
否则 GLThread 原生 SIGSEGV（实测 `Fatal signal 11, fault addr 0x58`，不留 .crash）。
所以敌方那段保持 `data.qte` 判断，我方这段用 `crushSpriteSelf` 判断。

用法:
    python scripts/patch_battle_guard.py            # 只产出文件
    python scripts/patch_battle_guard.py --deploy   # 同时推到模拟器 Caches/src
"""
import hashlib
import os
import subprocess
import sys
import zipfile
import zlib

sys.stdout.reconfigure(encoding='utf-8')
from Crypto.Cipher import AES                      # noqa: E402
from Crypto.Util.Padding import pad, unpad         # noqa: E402

KEY = bytes.fromhex('e9747d92cc322e7d112e7c3451d7b36a')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APK = os.path.join(ROOT, 'client', 'zjt_pack_enablefix_signed.apk')
OUT = os.path.join(ROOT, 'work', 'patch_out')
ADB = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk',
                   'platform-tools', 'adb.exe')
DEV = '127.0.0.1:16384'
PKG = 'com.happyelements.canon.baiduDK'
TARGET = 'assets/src/canon/scene/'

NL = '\r\n'   # APK 里的 lua 明文是 CRLF，锚点必须跟着走


# ---------------------------------------------------------------- 1. nil 保护
GUARD_OLD = ('\telse' + NL
             + '\t\tlocal fightEvent = SELF.fightEventFlow[1]' + NL
             + '\t\ttable.remove(SELF.fightEventFlow , 1)' + NL)

GUARD_NEW = ('\telse' + NL
             + '\t\tlocal fightEvent = SELF.fightEventFlow[1]' + NL
             + '\t\tif not fightEvent then' + NL
             + '\t\t\tprint("[PATCH1] flow empty win=" .. tostring(SELF.data.win) .. " selfHp=" .. tostring(SELF.selfHp) .. " enemyHp=" .. tostring(SELF.enemyHp) .. " selfCrush=" .. tostring(SELF.crushSpriteSelf ~= nil))' + NL
             + '\t\t\t-- [PATCH1] 事件队列已空、且有一方血量归零：' + NL
             + '\t\t\t-- 原版这里会 index nil 崩在 BattleScene:1372。' + NL
             + '\t\t\t-- 直接播终局演出（和 onFlashAnimationEnd 的 FightDeath 分支一致）。' + NL
             + '\t\t\t-- ⚠️ Crash 会用到 card2crash 实例，实例不存在时硬播会 SIGSEGV。' + NL
             + '\t\t\tSELF.battle_flash_co:setVisible(true)' + NL
             + '\t\t\tif SELF.data.win then' + NL
             + '\t\t\t\tif SELF.data.qte then' + NL
             + '\t\t\t\t\tSELF.battle_flash:changeAnimation(BattleAnimEnum.Crash)' + NL
             + '\t\t\t\telse' + NL
             + '\t\t\t\t\tSELF.battle_flash:changeAnimation(BattleAnimEnum.Win)' + NL
             + '\t\t\t\tend' + NL
             + '\t\t\telse' + NL
             + '\t\t\tif SELF.crushSpriteSelf and SELF.card2crashSource == "self" then' + NL
             + '\t\t\t\tSELF:setChildIndex(SELF.battle_flash_co, 9999)' + NL
             + '\t\t\t\tSELF:refreshIndex()' + NL
             + '\t\t\t\tSELF.battle_flash:changeAnimation(BattleAnimEnum.Crash)' + NL
             + '\t\t\telse' + NL
             + '\t\t\t\tSELF.battle_flash:changeAnimation(BattleAnimEnum.Lose)' + NL
             + '\t\t\tend' + NL
             + '\t\t\tend' + NL
             + '\t\t\treturn' + NL
             + '\t\tend' + NL
             + '\t\ttable.remove(SELF.fightEventFlow , 1)' + NL)


# ------------------------------------------------- 2. 预载我方破碎立绘（setup）
SETUP_OLD = ('\t\telse' + NL
             + '\t\t\tself.data.qte = false' + NL
             + '\t\tend' + NL
             + '\t\tCCFileUtils:sharedFileUtils():setPopupNotify(true)' + NL
             + '\t\t' + NL
             + '\tend' + NL)

SETUP_NEW = SETUP_OLD + (
    '\t-- [PATCH2] 我方主角卡的破碎立绘：战败时也播爆衣' + NL
    + '\tself.crushSpriteSelf = nil' + NL
    + '\tlocal selfFigId = MetaManager.card_meta[tonumber(selfMainData.metaId)].figureId' + NL
    + '\tif selfFigId and selfFigId ~= "" then' + NL
    + '\t\tlocal selfInfos = string.split(selfFigId, "_")' + NL
    + '\t\tlocal selfCrushId = ""' + NL
    + '\t\tfor selfK,selfV in pairs(selfInfos) do' + NL
    + '\t\t\tif selfK == #selfInfos then' + NL
    + '\t\t\t\tselfCrushId = selfCrushId .. "_0"' + NL
    + '\t\t\telseif selfK + 1 == #selfInfos then' + NL
    + '\t\t\t\tselfCrushId = selfCrushId .. selfV' + NL
    + '\t\t\telse' + NL
    + '\t\t\t\tselfCrushId = selfCrushId .. selfV .. "_"' + NL
    + '\t\t\tend' + NL
    + '\t\tend' + NL
    + '\t\tCCFileUtils:sharedFileUtils():setPopupNotify(false)' + NL
    + '\t\tlocal selfExist = CCString:createWithContentsOfFile(CCFileUtils:sharedFileUtils():fullPathForFilename("card/crush/" .. selfCrushId .. ".png"))' + NL
    + '\t\tCCFileUtils:sharedFileUtils():setPopupNotify(true)' + NL
    + '\t\tprint("[PATCH2] fig=" .. tostring(selfFigId) .. " id=" .. tostring(selfCrushId) .. " exist=" .. tostring(selfExist ~= nil))' + NL
    + '\t\tif selfExist then' + NL
    + '\t\t\tself.crushSpriteSelf = createSpriteFrame("card/crush/" .. selfCrushId .. ".png")' + NL
    + '\t\t\tprint("[PATCH2] created=" .. tostring(self.crushSpriteSelf ~= nil))' + NL
    + '\t\tend' + NL
    + '\tend' + NL
    + '\t-- ⚠️ card2crash 实例必须在场景初始化时就注册好：' + NL
    + '\t-- 战斗中（FightDeath 时）再 addChangeInstance 补，会让 GLThread 里 SIGSEGV，' + NL
    + '\t-- 实测 Fatal signal 11 fault addr 0xc。所以这里先算清楚这个实例归谁：' + NL
    + '\t-- 敌方有破碎立绘时归敌方（战胜时用），没有时留给我方（战败时用）。' + NL
    + '\tif self.data.qte then' + NL
    + '\t\tself.card2crashSource = "enemy"' + NL
    + '\telseif self.crushSpriteSelf then' + NL
    + '\t\tself.battle_flash:addChangeInstance("card2crash", self.crushSpriteSelf)' + NL
    + '\t\tself.card2crashSource = "self"' + NL
    + '\tend' + NL
    + '\tprint("[PATCH2] crashSource=" .. tostring(self.card2crashSource))' + NL)


# --------------------------------------------- 3. 战败分支：Lose -> 我方爆衣 Crash
LOSE_OLD = ('\t\telse' + NL
            + '\t\t\tSELF.battle_flash:changeAnimation(BattleAnimEnum.Lose)' + NL
            + '\t\tend' + NL)

LOSE_NEW = ('\t\telse' + NL
            + '\t\t\t-- [PATCH3] 战败也播爆衣：把 card2crash 换成我方主角卡的破碎立绘' + NL
            + '\t\t\t-- 再播 Crash（和战胜时看敌方爆衣同一段动画）；没有立绘退回 Lose。' + NL
            + '\t\t\tprint("[PATCH3] fightDeathLose win=" .. tostring(SELF.data.win) .. " src=" .. tostring(SELF.card2crashSource))' + NL
            + '\t\t\tif SELF.crushSpriteSelf and SELF.card2crashSource == "self" then' + NL
            + '\t\t\t\tSELF:setChildIndex(SELF.battle_flash_co, 9999)' + NL
            + '\t\t\t\tSELF:refreshIndex()' + NL
            + '\t\t\t\tSELF.battle_flash:changeAnimation(BattleAnimEnum.Crash)' + NL
            + '\t\t\telse' + NL
            + '\t\t\t\tSELF.battle_flash:changeAnimation(BattleAnimEnum.Lose)' + NL
            + '\t\t\tend' + NL
            + '\t\tend' + NL)


# ------------------------- 3b. 真正走的那条：onLastHitFlashEnd 的失败分支
# 致命一击播完回调的是 onLastHitFlashEnd（不是 onFlashAnimationEnd），
# 战胜时的敌方爆衣就在它的 qte 分支里；战败这里原来只有 Lose（光倒地、没立绘）。
LOSE2_OLD = ('\telse' + NL
             + '\t\tSELF.battle_flash:changeAnimation(BattleAnimEnum.Lose)' + NL
             + '\tend' + NL
             + 'end' + NL)

LOSE2_NEW = ('\telse' + NL
             + '\t\t-- [PATCH3b] 战败也播爆衣：把 card2crash 换成我方主角卡的破碎立绘' + NL
             + '\t\t-- 再播 Crash（与战胜时看敌方爆衣同一段动画）；没有立绘退回 Lose。' + NL
             + '\t\tprint("[PATCH3] lastHitLose selfHp=" .. tostring(SELF.selfHp) .. " enemyHp=" .. tostring(SELF.enemyHp) .. " qte=" .. tostring(SELF.data.qte) .. " src=" .. tostring(SELF.card2crashSource))' + NL
             + '\t\tif SELF.crushSpriteSelf and SELF.card2crashSource == "self" then' + NL
             + '\t\t\tSELF:setChildIndex(SELF.battle_flash_co, 9999)' + NL
             + '\t\t\tSELF:refreshIndex()' + NL
             + '\t\t\tSELF.battle_flash:changeAnimation(BattleAnimEnum.Crash)' + NL
             + '\t\telse' + NL
             + '\t\t\tSELF.battle_flash:changeAnimation(BattleAnimEnum.Lose)' + NL
             + '\t\tend' + NL
             + '\tend' + NL
             + 'end' + NL)


# ------------------------------------------- 4. 诊断：TimeOut / FightDeath 打点
TIMEOUT_OLD = ('\tif #SELF.fightEventFlow == 0 and SELF.selfHp > 0 and SELF.enemyHp > 0 then' + NL
               + '\t\tSELF.battle_flash_co:setVisible(true)' + NL)

TIMEOUT_NEW = ('\tif #SELF.fightEventFlow == 0 and SELF.selfHp > 0 and SELF.enemyHp > 0 then' + NL
               + '\t\tprint("[PATCH4] TimeOut selfHp=" .. tostring(SELF.selfHp) .. " enemyHp=" .. tostring(SELF.enemyHp) .. " selfCrush=" .. tostring(SELF.crushSpriteSelf ~= nil))' + NL
               + '\t\tSELF.battle_flash_co:setVisible(true)' + NL)

FIGHTDEATH_OLD = ('\telseif anim == BattleAnimEnum.FightDeath then' + NL
                  + '\t\tif SELF.data.win then' + NL)

FIGHTDEATH_NEW = ('\telseif anim == BattleAnimEnum.FightDeath then' + NL
                  + '\t\tprint("[PATCH4] FightDeath win=" .. tostring(SELF.data.win) .. " selfHp=" .. tostring(SELF.selfHp) .. " enemyHp=" .. tostring(SELF.enemyHp))' + NL
                  + '\t\tif SELF.data.win then' + NL)


def decrypt(blob):
    pt = unpad(AES.new(KEY, AES.MODE_CBC, blob[:16]).decrypt(blob[16:]), 16)
    zipped = False
    if pt[:1] == b'\x78':
        try:
            pt = zlib.decompress(pt)
            zipped = True
        except Exception:
            pass
    return pt, zipped


def encrypt(pt, zipped):
    if zipped:
        pt = zlib.compress(pt, 9)
    iv = os.urandom(16)
    return iv + AES.new(KEY, AES.MODE_CBC, iv).encrypt(pad(pt, 16))


def deploy(local, remote):
    subprocess.run([ADB, '-s', DEV, 'shell', 'mkdir -p %s' % os.path.dirname(remote)],
                   capture_output=True, timeout=60)
    r = subprocess.run([ADB, '-s', DEV, 'push', local, remote],
                       capture_output=True, timeout=120)
    print('push ->', remote, 'rc=%s' % r.returncode)


def apply_one(src, old, new, tag):
    if new in src:
        print('  %s: 已打过，跳过' % tag)
        return src
    if old not in src:
        print('  %s: !! 找不到锚点' % tag)
        key = old.strip().split(NL)[-1].strip()[:40]
        i = src.find(key)
        print('     锚点尾部 %r 定位 idx=%s' % (key, i))
        if i >= 0:
            print(repr(src[max(0, i - 120):i + 160]))
        raise SystemExit(1)
    print('  %s: 已替换' % tag)
    return src.replace(old, new, 1)


def main():
    do_deploy = '--deploy' in sys.argv
    os.makedirs(OUT, exist_ok=True)
    z = zipfile.ZipFile(APK)
    entry = [n for n in z.namelist()
             if n.startswith(TARGET) and n.split('/')[-1].startswith('BattleScene.')]
    if not entry:
        print('!! APK 里找不到 BattleScene')
        return 1
    entry = entry[0]
    pt, zipped = decrypt(z.read(entry))
    src = pt.decode('utf-8', 'replace')
    print('APK 条目: %s' % entry)
    print('解密: %d 字节, zlib=%s' % (len(pt), zipped))
    patched = apply_one(src, GUARD_OLD, GUARD_NEW, 'PATCH1 空队列保护')
    patched = apply_one(patched, SETUP_OLD, SETUP_NEW, 'PATCH2 预载我方破碎立绘')
    patched = apply_one(patched, LOSE_OLD, LOSE_NEW, 'PATCH3 战败播爆衣')
    patched = apply_one(patched, LOSE2_OLD, LOSE2_NEW, 'PATCH3b 致命一击失败分支')
    patched = apply_one(patched, TIMEOUT_OLD, TIMEOUT_NEW, 'PATCH4 TimeOut 打点')
    patched = apply_one(patched, FIGHTDEATH_OLD, FIGHTDEATH_NEW, 'PATCH4 FightDeath 打点')
    enc = encrypt(patched.encode('utf-8'), zipped)
    name = os.path.basename(entry)
    plain_out = os.path.join(OUT, 'BattleScene.plain.lua')
    enc_out = os.path.join(OUT, 'BattleScene.enc.lua')
    open(plain_out, 'wb').write(patched.encode('utf-8'))
    open(enc_out, 'wb').write(enc)
    print('明文 -> %s' % plain_out)
    print('密文 -> %s  (md5=%s, %d 字节)'
          % (enc_out, hashlib.md5(enc).hexdigest(), len(enc)))
    if do_deploy:
        remote = '/data/data/%s/Caches/src/canon/scene/%s' % (PKG, name)
        deploy(enc_out, remote)
        subprocess.run([ADB, '-s', DEV, 'shell',
                        'rm -f /data/data/%s/Caches/static_config.md5' % PKG],
                       capture_output=True, timeout=60)
        print('已清理 Caches/static_config.md5')
    return 0


if __name__ == '__main__':
    sys.exit(main())
