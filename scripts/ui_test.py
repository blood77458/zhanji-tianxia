#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""《战姬天下》客户端 UI 自动化回归测试。

目标：把游戏主要功能全部点一遍，任何一步导致**进程死亡 / Lua 报错**都记录下来
（截图 + logcat），跑完输出报告。可重复运行以验证修复。

关键设计（踩过的坑）：
  * 顶部**滚动公告栏**每帧都在变，直接 hash 整屏会导致「界面已变化」永远为真。
    因此指纹只取**内容区** (y 120..1150)，避开公告栏与底部导航。
  * 每次点击后必须真正**导航回主界面**再点下一项；只判断「进程活着」是不够的。
    主界面用参照图相似度校验（--save-ref 采集）。

用法：
    python scripts/ui_test.py --save-ref          # 当前界面存为主界面参照
    python scripts/ui_test.py                     # 跑全部流程
    python scripts/ui_test.py --only main_menu_nav
    python scripts/ui_test.py --list
    python scripts/ui_test.py --probe 300 1213
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, 'work', 'uitest')
REF = os.path.join(OUT, '_ref_main.png')
LOGIN_REF = os.path.join(OUT, '_ref_login.png')
ADB = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk',
                   'platform-tools', 'adb.exe')
if not os.path.exists(ADB):
    ADB = 'adb'
DEV = os.environ.get('CANON_DEV', '127.0.0.1:16384')
PKG = os.environ.get('CANON_PKG', 'com.happyelements.canon.baiduDK')
ACT = PKG + '/com.happyelements.arda.MainActivity'

SCREEN_W, SCREEN_H = 720, 1280
SCALE = SCREEN_W / 720.0

# 内容区（排除顶部滚动公告栏 y<120 和底部导航 y>1150）
BOX = (0, 120, 720, 1150)
# 主界面校验用的**稳定条带**：不吃动画/横幅/跑马灯的影响。
# 逐条都要 >= 0.92 才算「在主界面」（实测每条静止时都是 1.0000）。
MAIN_BANDS = (
    (0, 130, 720, 215),        # 顶部菜单：任务/活动/奖励/求将/求宝/商城
    (0, 215, 720, 660),        # 中间立绘 + 竞技/演武（弹窗一定盖住这里）
    (0, 1095, 720, 1165),      # 图标行：装备/好友/邮箱/元神/宝物/炼魂
    (0, 1165, 720, 1280),      # 底部导航：首页/队伍/闯关/背包/神兽/军团
)
# 主界面校验区域：底部导航条（首页/队伍/闯关/背包/神兽/军团）
NAV_BOX = (0, 1150, 720, 1280)

COORD = {
    'login_guest':      (574, 1128),
    'cc_dice':          (554, 774),
    'cc_create':        (360, 960),
    'menu_task':        (60, 168),
    'menu_activity':    (180, 168),
    'menu_reward':      (300, 168),
    'menu_general':     (420, 168),
    'menu_treasure':    (540, 168),
    'menu_shop':        (660, 168),
    'home_arena':       (108, 314),
    'home_drill':       (126, 732),
    # 图标行：装备/好友/邮箱/元神/宝物/炼魂（实测中心 y≈1086，不是 1145）
    'icon_equip':       (60, 1086),
    'icon_friend':      (180, 1086),
    'icon_mail':        (300, 1086),
    'icon_soul':        (420, 1086),
    'icon_treasure':    (540, 1086),
    'icon_smelt':       (660, 1086),
    'nav_home':         (60, 1218),
    'nav_team':         (180, 1218),
    'nav_stage':        (300, 1218),
    'nav_bag':          (420, 1218),
    'nav_beast':        (540, 1218),
    'nav_guild':        (660, 1218),
    # 闯关（章节地图）实测坐标（720x1280）
    'stage_challenge':  (574, 946),   # 「挑战」按钮（第 2 回那一行）
    'stage_sweep':      (574, 818),   # 「扫荡」按钮（第 1 回那一行）
    'stage_reward':     (574, 690),   # 「领取」本章奖励
    'stage_enter':      (360, 630),   # 「乱入新世界」章节大按钮
    # 点「挑战」后会先弹「挑战次数 1/99 — 扫荡3轮 / 闯关」选择框，
    # 要点右边那个「闯关」按钮才真的进地图（实测 2026-10-17 截图换算）。
    'stage_enter_map':  (476, 684),
    'stage_forward':    (360, 1066),  # 战斗地图上的「前进」（点了才真的开战）
    'stage_getcity':    (560, 218),
    'back':             (40, 188),
    # 场景左上角的「返回」箭头。**不同场景高度不一样**，两个位置都要试：
    #   活动/队伍/装备/商城/闯关：(34,190)（顶栏下方那一行）
    #   军团：(34,112)（军团界面顶栏更矮，箭头贴着屏幕最上沿）
    'scene_back':       (34, 190),
    'scene_back_top':   (34, 112),
    # 详情类弹窗右上角的 X（装备详情/道具详情/武将详情…通用位置）
    'popup_close':      (676, 252),
    'dialog_ok':        (360, 800),
    # 战斗结算/奖励弹窗上的「确定」——位置不固定，两处都点一下
    'battle_ok':        (360, 1152),   # 战斗结算面板「确定」（实测中心 y≈1152）
    # 「大胜/惜败」结算面板底部两个按钮（实测 y≈1080）
    'result_select':    (180, 1080),   # 选择关卡
    'result_continue':  (516, 1080),   # 继续前进
    # 退出确认弹窗（按返回键会出现）—— 实测 720x1280 下按钮中心在 y≈688，
    # 之前记的 858 是错的，导致 goto_main() 取消了退出框、一直回不到主界面。
    'dialog_cancel':    (223, 688),
    'dialog_confirm':   (551, 688),
    # 空白处：popPanel（如每日签到）带全屏关闭层，点这里可关闭；
    # 同时这个点落在主界面右侧立绘上，不会误触任何按钮。
    # ⚠️ 不要用 (12,640)——那是「演武」按钮。
    'neutral':          (700, 640),
}


def sh(*args, timeout=90):
    try:
        p = subprocess.run([ADB, '-s', DEV] + list(args), capture_output=True, timeout=timeout)
        return p.returncode, (p.stdout or b'').decode('utf-8', 'replace') + \
                             (p.stderr or b'').decode('utf-8', 'replace')
    except subprocess.TimeoutExpired:
        return 124, 'TIMEOUT'


def shell(cmd, timeout=90):
    return sh('shell', cmd, timeout=timeout)


def tap(name, y=None):
    if y is None:
        if isinstance(name, str):
            if name not in COORD:
                raise KeyError('未知坐标: %s' % name)
            x, y = COORD[name]
        else:
            x, y = name
    else:
        x = name
    x = int(round(x * SCALE)); y = int(round(y * SCALE))
    shell('input tap %d %d' % (x, y))
    return x, y


def key_back():
    shell('input keyevent 4')


def pid():
    rc, out = shell('pidof %s' % PKG)
    parts = out.strip().split()
    return int(parts[0]) if parts and parts[0].isdigit() else 0


def alive():
    # adb 偶尔抽风会让 `pidof` 返回空，误判成进程已死（曾因此把好好的录像截断）。
    # 所以连续两次都探不到才算死。
    for _ in range(2):
        if pid() > 0:
            return True
        time.sleep(0.8)
    return pid() > 0


def _grab(remote, local):
    os.makedirs(OUT, exist_ok=True)
    shell('screencap -p %s' % remote)
    sh('pull', remote, local)
    return local


def screenshot(tag):
    return _grab('/sdcard/_ui_%s.png' % tag, os.path.join(OUT, '%s.png' % tag))


def content_hash():
    """内容区指纹（排除滚动公告栏）。"""
    from PIL import Image
    p = _grab('/sdcard/_ui_c.png', os.path.join(OUT, '_c.png'))
    try:
        im = Image.open(p).convert('L').crop(BOX)
        return hashlib.md5(im.tobytes()).hexdigest()[:12]
    except Exception:
        return '?'


def nav_similarity(ref_path=REF):
    """当前底部导航条与主界面参照的相似度 (0..1, 1=完全一致)。"""
    from PIL import Image, ImageChops
    if not os.path.exists(ref_path):
        return None
    p = _grab('/sdcard/_ui_n.png', os.path.join(OUT, '_n.png'))
    try:
        a = Image.open(ref_path).convert('L').crop(NAV_BOX)
        b = Image.open(p).convert('L').crop(NAV_BOX)
        diff = ImageChops.difference(a, b)
        h = diff.histogram()
        total = sum(h)
        same = h[0]                       # 差值为 0 的像素数
        return same / float(total) if total else 0.0
    except Exception:
        return None


def is_main(threshold=0.90):
    """是否在主界面。

    实测（2026-10-17，720x1280 实机）：

        整内容区(120-1150)        0.8722   ← 太严，会被「动态」内容拉低
        顶部菜单(130-215)         1.0000
        立绘区(215-660)           1.0000
        图标行(1095-1165)         1.0000
        底部导航(1165-1280)       1.0000

    差异全来自会变的东西 —— 吃桃横幅（时间段刷新）、顶部跑马灯、战报文案。
    所以这里只比**稳定条带**（`MAIN_BANDS`），并且要求**每一条**都够像。

    为什么不能只比底部导航：popPanel（签到/连登/公告）是盖在中间区域的，
    底部导航仍然可见，只比导航条会把「弹窗打开」误判成「在主界面」。
    加上立绘区就挡住了这种情况 —— 弹窗一定盖住它。
    """
    from PIL import Image, ImageChops
    if not os.path.exists(REF):
        # ⚠️ 绝不能 fail-open：参照图缺失时若返回 True，整套用例会在登录页上
        # 「全部通过」（踩过的坑）。缺参照一律判「不在主界面」。
        return False
    p = _grab('/sdcard/_ui_m.png', os.path.join(OUT, '_m.png'))
    try:
        a = Image.open(REF).convert('L')
        b = Image.open(p).convert('L')
        for box in MAIN_BANDS:
            ha = ImageChops.difference(a.crop(box), b.crop(box)).histogram()
            total = sum(ha) or 1
            # 差值 <= 12 视为「同一像素」（容忍轻微抗锯齿/压缩差异）
            if (sum(ha[:13]) / float(total)) < threshold:
                return False
        return True
    except Exception:
        return False


def screen_sim(ref_path, box=None, tol=13):
    """当前整屏与 ref 的相似度（box=None 用全屏）。"""
    from PIL import Image, ImageChops
    if not os.path.exists(ref_path):
        return None
    p = _grab('/sdcard/_ui_s.png', os.path.join(OUT, '_s.png'))
    try:
        a = Image.open(ref_path).convert('L')
        b = Image.open(p).convert('L')
        if box:
            a = a.crop(box); b = b.crop(box)
        if a.size != b.size:
            b = b.resize(a.size)
        h = ImageChops.difference(a, b).histogram()
        total = sum(h) or 1
        return sum(h[:tol]) / float(total)
    except Exception:
        return None


def on_login():
    """是否退回到了登录/启动页 —— 说明客户端「报错弹出后自己重启了」。
    只看屏幕下半部（LOGO 区），避免和主界面底部导航混淆。"""
    s = screen_sim(LOGIN_REF)
    return s is not None and s >= 0.90


def clear_log():
    shell('logcat -c')


ERR_PAT = re.compile(
    r'handler_lua_error|Fatal signal|attempt to (call|index|concatenate|perform)|'
    r'bad argument|SIGSEGV', re.I)


def read_errors():
    rc, out = shell('logcat -d -v brief', timeout=60)
    seen, res = set(), []
    for ln in out.splitlines():
        if ERR_PAT.search(ln):
            s = ln.strip()
            if s not in seen:
                seen.add(s); res.append(s)
    return res[-12:]


ERRDIR = '/data/data/%s/errorlogs' % PKG


def crash_files():
    """引擎在未捕获 Lua 错误时会写 .crash 文件（随后 sendSignal 9）。
    即使客户端之后自己重启回登录页，这个文件仍然留下 —— 是**最可靠**的
    「这一步真的出错了」证据，不会被「界面已变化」的假阳性掩盖。"""
    rc, out = shell('ls %s 2>/dev/null' % ERRDIR, timeout=30)
    return set(x.strip() for x in out.split() if x.strip().endswith('.crash'))


def read_crash(fname):
    rc, out = shell('cat %s/%s 2>/dev/null' % (ERRDIR, fname), timeout=30)
    txt = out.strip()
    m = re.search(r'(canon/[\w/]+\.lua:\d+:[^\n]*)', txt)
    if m:
        return m.group(1)[:300]
    return txt[-300:].replace('\n', ' ') if txt else '(空)'


def crash_detail():
    rc, out = shell('logcat -d', timeout=60)
    m = re.findall(r'handler_lua_error\|ERROR\]:\s*(.+)', out)
    if m:
        return m[-1].strip()[:300]
    m = re.findall(r'Fatal signal \d+ \([A-Z]+\)[^\n]*', out)
    if m:
        return m[-1].strip()[:300]
    m = re.findall(r'(canon/[\w/]+\.lua:\d+: [^\n]+)', out)
    if m:
        return m[-1].strip()[:300]
    return ''


def launch():
    shell('am force-stop %s' % PKG)
    time.sleep(2)
    shell('am start -n %s' % ACT)
    t0 = time.time()
    while time.time() - t0 < 60:
        if alive():
            break
        time.sleep(1)
    else:
        return False
    # 启动后若是「非主界面」，此刻八成就是登录/启动页 —— 存下来当参照，
    # 用于识别「点某个功能后客户端报错自己重启回登录页」这种假阳性。
    time.sleep(6)
    try:
        if not os.path.exists(REF) or not is_main():
            _grab('/sdcard/_ui_l.png', LOGIN_REF)
    except Exception:
        pass
    return True


def wait_stable_settle(rounds=3, gap=1.0):
    """等内容区连续 rounds 次不变。"""
    last = None; same = 0
    for _ in range(40):
        h = content_hash()
        same = same + 1 if h == last else 0
        if same >= rounds:
            return h
        last = h
        time.sleep(gap)
    return last


# ------------------------------------------------------------------ 流程
# step: ('tap',名) ('wait',秒) ('probe',名,标签) ('ensure_main',) ('back',) ('key',次数)
FLOWS = {
    'boot_to_main': {
        'desc': '启动 -> 登录 -> 创角 -> 新手引导 -> 主界面',
        'steps': [('reset',), ('auto_login',)],
    },
    'main_menu_top': {
        'desc': '顶部菜单: 任务/活动/奖励/求将/求宝/商城',
        'steps': [('ensure_main',)] + [
            ('probe', c, n) for c, n in [
                ('menu_task', '任务'), ('menu_activity', '活动'), ('menu_reward', '奖励'),
                ('menu_general', '求将'), ('menu_treasure', '求宝'), ('menu_shop', '商城')]],
    },
    'main_menu_nav': {
        'desc': '底部导航: 首页/队伍/闯关/背包/神兽/军团',
        'steps': [('ensure_main',)] + [
            ('probe', c, n) for c, n in [
                ('nav_home', '首页'), ('nav_team', '队伍'), ('nav_stage', '闯关'),
                ('nav_bag', '背包'), ('nav_beast', '神兽'), ('nav_guild', '军团')]],
    },
    'main_menu_icons': {
        'desc': '次级图标: 装备/好友/邮箱/元神/宝物/炼魂',
        'steps': [('ensure_main',)] + [
            ('probe', c, n) for c, n in [
                ('icon_equip', '装备'), ('icon_friend', '好友'), ('icon_mail', '邮箱'),
                ('icon_soul', '元神'), ('icon_treasure', '宝物'), ('icon_smelt', '炼魂')]],
    },
    'home_arena': {
        'desc': '主界面 竞技 / 演武',
        'steps': [('ensure_main',), ('probe', 'home_arena', '竞技'),
                  ('ensure_main',), ('probe', 'home_drill', '演武')],
    },
    'stage_flow': {
        'desc': '闯关 -> 挑战 -> 前进打一场 -> 结算 -> 回主界面',
        'steps': [('ensure_main',), ('probe', 'nav_stage', '闯关'),
                  ('probe', 'stage_challenge', '挑战(进战斗地图)'),
                  # 地图上点「前进」才真正开战（实测会走 triggerCoinEvent，
                  # 结算后关卡进度上涨、金币增加、体力扣减）
                  ('tap', 'stage_forward'), ('wait', 12),
                  ('tap_ok',), ('wait', 2), ('tap_ok',),
                  ('ensure_main',)],
    },
    'stage_reward': {
        'desc': '闯关 -> 领取本章奖励 -> 回主界面',
        'steps': [('ensure_main',), ('probe', 'nav_stage', '闯关'),
                  ('probe', 'stage_reward', '领取章节奖励'),
                  ('tap_ok',), ('ensure_main',)],
    },
}


class Runner:
    def __init__(self, args):
        self.args = args
        self.results = []
        self.t0 = time.time()

    def record(self, flow, step, status, detail='', shot=''):
        self.results.append({'flow': flow, 'step': step, 'status': status,
                             'detail': detail, 'shot': shot,
                             'time': round(time.time() - self.t0, 1)})
        mark = {'ok': ' OK ', 'fail': 'FAIL', 'warn': 'WARN', 'skip': 'SKIP'}[status]
        print('   [%s] %-16s %s' % (mark, step, detail[:110]), flush=True)

    def goto_main(self, tries=6):
        """从任意界面回到主界面（用参照图校验）。

        实测有效的关闭顺序（720x1280 实机，2026-10-17），**按可靠性排序**：

          1. 点底部导航「首页」`(60,1218)` —— 绝大多数场景都带这条底栏，
             点它直接回主界面，是最稳的一条路（实测活动/队伍/装备/商城/军团都行）；
          2. 点弹窗右上角 X `(676,252)` —— 装备/道具/武将详情这类浮层；
          3. 点场景左上角返回箭头 `(34,190)` —— 有的场景带、有的不带；
          4. 按 Android 返回键 → 弹「您确定要退出游戏吗？」→ 点取消 `(223,688)`；
          5. 点空白处 —— 关 popPanel（签到/连登带全屏关闭层）。

        之前只做 4、5 两步，所以进了「活动」这类场景就再也回不来。
        ⚠️ 不要盲目点场景左上角：军团界面的左上角是**搜索输入框**，
           点中会弹软键盘并顶掉顶部一整排按钮，反而更回不去。
        """
        if not alive():
            return False
        # 战斗结算面板会盖住底栏，先点掉它（否则后面所有点击都打在面板上）
        for _ in range(tries):
            if is_main():
                return True
            for name in ('battle_ok', 'result_continue', 'result_select',
                         'dialog_ok'):
                try:
                    tap(name)
                except KeyError:
                    pass
                time.sleep(0.7)
            if is_main():
                return True
            tap('nav_home'); time.sleep(1.2)
            if is_main():
                return True
            tap('popup_close'); time.sleep(0.9)
            if is_main():
                return True
            tap('scene_back'); time.sleep(1.2)
            if is_main():
                return True
            key_back(); time.sleep(1.2)
            tap('dialog_cancel'); time.sleep(0.8)    # 取消退出确认
            if is_main():
                return True
            tap('neutral'); time.sleep(0.9)          # 关 popPanel
            if is_main():
                return True
        return is_main()

    def auto_login(self, flow='boot'):
        """从启动态自动走到主界面。

        两种账号都要能处理：
          * **已有角色**（现在我们测的这个 60 级号）：点完「游客登录」直接进主界面，
            不能再点创角骰子/创建按钮，更不能盲点 40 下 —— 那会把界面点乱，
            后续所有 flow 都会因为「回不到主界面」连锁失败。
          * **新号**：才需要创角 + 新手引导连点。
        """
        for attempt in range(3):
            # 登录页
            tap('login_guest')
            time.sleep(9)
            if not alive():
                self.record(flow, 'login', 'fail', crash_detail() or '登录后进程死亡')
                return False
            wait_stable_settle()
            if is_main():
                self.record(flow, 'login', 'ok', '已有角色，直接进入主界面')
                return True
            # 下面这条路径只给「新号」用
            tap('cc_dice'); time.sleep(2)
            tap('cc_create'); time.sleep(5)
            if not alive():
                self.record(flow, 'create_char', 'fail', crash_detail() or '创角后进程死亡')
                return False
            if is_main():
                self.record(flow, 'login', 'ok', '已进入主界面')
                return True
            # 新手引导：连续点击推进
            for _ in range(40):
                shell('input tap 360 800')
                time.sleep(0.6)
                if not alive():
                    self.record(flow, 'tutorial', 'fail', crash_detail() or '引导中进程死亡')
                    return False
            time.sleep(4)
            wait_stable_settle()
            if is_main():
                self.record(flow, 'enter_main', 'ok', '已进入主界面')
                return True
            self.record(flow, 'enter_main_%d' % attempt, 'warn', '未识别为主界面，重试')
        return False

    def ensure_main(self):
        """确保在主界面。**返回 False 表示没做到**（调用方必须据此判失败，
        否则崩溃后重启回登录页会被误判成 OK —— 这是踩过的假阳性坑）。"""
        if not alive():
            err = crash_detail()
            print('   (进程死亡 -> 重启) %s' % (err[:110] if err else ''))
            if not launch():
                self.record('*', 'relaunch', 'fail', '无法启动')
                return False
            time.sleep(25)
            ok = self.auto_login('recover')
            if not ok:
                self.record('*', 'recover', 'fail',
                            '崩溃后未能恢复主界面: ' + (err or '?'))
            return ok
        if self.goto_main():
            return True
        return False

    def do_step(self, flow, step):
        k = step[0]
        if k == 'reset':
            clear_log()
            ok = launch()
            return self.record(flow, 'launch', 'ok' if ok else 'fail')
        if k == 'auto_login':
            return self.auto_login(flow)
        if k == 'ensure_main':
            return self.ensure_main()
        if k == 'wait':
            time.sleep(step[1]); return None
        if k == 'tap':
            try:
                tap(step[1]); time.sleep(1.2)
            except KeyError as e:
                self.record(flow, step[1], 'skip', str(e))
            return None
        if k == 'tap_ok':
            # 战斗结算 / 奖励弹窗的「确定」位置不固定，两个候选点各点一下，
            # 点空也无副作用（主界面上这两个位置不会触发任何按钮）。
            for name in ('battle_ok', 'dialog_ok'):
                tap(name)
                time.sleep(0.8)
            return None
        if k == 'back':
            key_back(); time.sleep(1.5); return None
        if k == 'probe':
            name, label = step[1], step[2]
            if not self.ensure_main():
                self.record(flow, label, 'fail', '无法回到主界面(上一步可能已崩溃)')
                return None
            before = content_hash()
            cf_before = crash_files()
            clear_log()
            try:
                tap(name)
            except KeyError as e:
                self.record(flow, label, 'skip', str(e)); return None
            time.sleep(self.args.wait)
            after = content_hash()
            errs = read_errors()
            dead = not alive()
            new_crashes = crash_files() - cf_before
            back_to_login = on_login()
            changed = before != after
            shot = ''
            if self.args.shots or dead or errs or new_crashes or back_to_login or not changed:
                shot = screenshot('%s_%s' % (flow, re.sub(r'\W+', '_', label)))
            # 1) 有新 crash 文件 = 引擎真的抛了未捕获 Lua 错误（最硬的证据）
            if new_crashes:
                f = sorted(new_crashes)[-1]
                self.record(flow, label, 'fail',
                            'Lua崩溃(%s): %s' % (f.replace('ANDROID_LUA_', '')[:10],
                                                 read_crash(f)), shot)
                return 'recover'
            if dead:
                self.record(flow, label, 'fail', '崩溃: ' + (crash_detail() or '进程死亡'), shot)
                return 'recover'
            if errs:
                self.record(flow, label, 'fail', 'Lua错误: ' + (crash_detail() or errs[-1]), shot)
                tap('dialog_ok'); time.sleep(1)
                return 'recover'
            # 2) 进程还活着但退回了登录页 = 报错弹窗后客户端自己重启了
            if back_to_login:
                self.record(flow, label, 'fail', '报错后客户端重启回登录页', shot)
                return 'recover'
            if not changed:
                self.record(flow, label, 'warn', '内容区无变化(可能未点中/本页)', shot)
                return None
            self.record(flow, label, 'ok', '界面已变化', shot)
            return 'opened'
        return None

    def recover(self, flow='recover'):
        """某一步把它点崩了：重启客户端并重新登录，好让后续步骤还能跑。"""
        print('   (恢复: 重启客户端并重新登录)', flush=True)
        if not launch():
            self.record(flow, 'recover', 'fail', '重启失败')
            return False
        time.sleep(20)
        return self.auto_login(flow)

    def run(self, name):
        fl = FLOWS[name]
        print('\n=== [%s] %s ===' % (name, fl['desc']), flush=True)
        for step in fl['steps']:
            if self.do_step(name, step) == 'recover':
                self.recover(name)


# 模块级便捷入口：脚本（rec_battle.py / test_battle.py）直接调 U.goto_main()
class _Args:
    wait = 3.0


def goto_main(tries=6):
    return Runner(_Args()).goto_main(tries)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--only')
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--wait', type=float, default=5.0)
    ap.add_argument('--shots', action='store_true', default=True)
    ap.add_argument('--save-ref', action='store_true')
    ap.add_argument('--probe', nargs=2, metavar=('X', 'Y'))
    a = ap.parse_args()

    os.makedirs(OUT, exist_ok=True)

    if a.list:
        for k, v in FLOWS.items():
            print('%-18s %s' % (k, v['desc']))
        return 0

    if a.save_ref:
        os.makedirs(OUT, exist_ok=True)
        p = _grab('/sdcard/_ui_ref.png', REF)
        print('参照图已保存:', p)
        print('底部导航相似度(自比):', nav_similarity())
        return 0

    if a.probe:
        x, y = int(a.probe[0]), int(a.probe[1])
        b = content_hash()
        print('main?=%.3f' % (nav_similarity() or -1))
        tap(x, y); time.sleep(a.wait)
        print('before=%s after=%s changed=%s pid=%d' % (b, content_hash(), b != content_hash(), pid()))
        for e in read_errors():
            print('  ERR', e[:170])
        return 0

    if not alive() and not launch():
        print('!! 无法启动客户端'); return 1
    time.sleep(3)

    r = Runner(a)
    for n in ([a.only] if a.only else list(FLOWS)):
        if n not in FLOWS:
            print('未知流程:', n); continue
        r.run(n)

    stamp = datetime.now().strftime('%m%d_%H%M%S')
    rep = os.path.join(OUT, 'report_%s.json' % stamp)
    json.dump(r.results, open(rep, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

    c = {s: sum(1 for x in r.results if x['status'] == s) for s in ('ok', 'warn', 'fail', 'skip')}
    print('\n================ 汇总 ================')
    print('OK=%d  WARN=%d  FAIL=%d  SKIP=%d' % (c['ok'], c['warn'], c['fail'], c['skip']))
    if c['fail']:
        print('\n--- 失败 ---')
        for x in r.results:
            if x['status'] == 'fail':
                print('  %-16s %-12s %s' % (x['flow'], x['step'], x['detail'][:120]))
                if x['shot']:
                    print('       %s' % x['shot'])
    if c['warn']:
        print('\n--- 警告 ---')
        for x in r.results:
            if x['status'] == 'warn':
                print('  %-16s %-12s %s' % (x['flow'], x['step'], x['detail'][:100]))
    print('\n报告: %s' % rep)
    return 0


if __name__ == '__main__':
    sys.exit(main())
