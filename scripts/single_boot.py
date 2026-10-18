# -*- coding: utf-8 -*-
"""单机版启动迭代器：重启客户端 → 点过弹窗 → 游客登录 → 收集 unhandled 清单。

用法:
    python scripts/single_boot.py             # 只跑一次并报告
    python scripts/single_boot.py --wait 40   # 登录后等更久（首次进主界面比较慢）

输出：
    * `[SINGLE] unhandled <method>` 清单（下一批要加进快照的方法）
    * 截图 `work/uitest/boot_<时间>.png`
    * 关键日志尾部
"""
import os
import re
import subprocess
import sys
import time

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADB = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk',
                   'platform-tools', 'adb.exe')
DEV = '127.0.0.1:16384'
PKG = 'com.happyelements.canon.baiduDK'

# 覆盖层对话框/按钮的真实坐标（720x1280）
TAP_COMPAT_OK = (580, 803)      # 「这个应用是为旧版 Android 开发」的 確定
TAP_GUEST = (548, 1181)         # 游客登录


def shell(cmd, timeout=60):
    r = subprocess.run([ADB, '-s', DEV, 'shell', cmd], capture_output=True,
                       timeout=timeout)
    return (r.stdout or b'').decode('utf-8', 'replace')


def tap(pt):
    shell('input tap %d %d' % pt)
    time.sleep(1.5)


def main():
    wait = 30
    if '--wait' in sys.argv:
        wait = int(sys.argv[sys.argv.index('--wait') + 1])

    shell('am force-stop %s' % PKG)
    shell('logcat -c')
    time.sleep(2)
    shell('monkey -p %s -c android.intent.category.LAUNCHER 1' % PKG)
    print('启动中…', flush=True)
    time.sleep(22)
    # 全新安装会先弹 MuMu 的权限页（存储/联系人/电话/短信/位置/相机 + 繼續）
    for y in (306, 466, 625, 785, 944, 1104):
        shell('input tap 632 %d' % y)
        time.sleep(0.4)
    shell('input tap 654 1216')      # 繼續
    time.sleep(4)

    tap(TAP_COMPAT_OK)          # 兼容性提示（有就点掉，没有也无害）
    time.sleep(2.5)
    # 实测：兼容提示关掉后的第一次点击会被吞掉，所以连点两次
    tap(TAP_GUEST)
    time.sleep(2.0)
    tap(TAP_GUEST)
    print('已点游客登录，等 %ds…' % wait, flush=True)
    time.sleep(wait)

    log = shell('logcat -d | grep -E "SINGLE|LUA-print"')
    unhandled = sorted(set(re.findall(r'unhandled ([A-Za-z_0-9]+)', log)))
    misses = sorted(set(re.findall(r'MISS (\S+)', log)))

    print('\n=== unhandled（下一批要加进快照）===')
    print(' '.join(unhandled) if unhandled else '（无）')
    print('\n=== 本地 HTTP 未命中 ===')
    print(' '.join(misses) if misses else '（无）')

    tail = [l for l in log.split('\n') if 'SINGLE' in l][-14:]
    print('\n=== 日志尾部 ===')
    for l in tail:
        print('  ' + l.split('SINGLE', 1)[-1].strip()[:120])

    png = os.path.join(ROOT, 'work', 'uitest', 'boot_%d.png' % int(time.time()))
    shell('screencap -p /sdcard/_boot.png')
    subprocess.run([ADB, '-s', DEV, 'pull', '/sdcard/_boot.png', png],
                   capture_output=True)
    print('\n截图 -> %s' % png)

    errs = shell('ls -t /data/data/%s/errorlogs/ 2>/dev/null | head -2' % PKG).strip()
    if errs:
        print('错误日志: %s' % ' '.join(errs.split()))
        for name in errs.split()[:1]:
            print(shell('head -c 400 /data/data/%s/errorlogs/%s' % (PKG, name)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
