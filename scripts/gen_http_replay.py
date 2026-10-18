# -*- coding: utf-8 -*-
"""把抓到的直连 HTTP 响应字节生成成 Lua 回放表。

输入：work/http_capture/*.bin（server/gameserver.py 的 _capture 落盘的原始响应）
输出：offline/lua/canon/single/http_replay.lua

路径映射规则（与抓包时一致）：
    /systemInfo                -> systemInfo.bin
    /check/android             -> check_android.bin
    /loginAccount/hasVisitorAccount -> loginAccount_hasVisitorAccount.bin
    /sessionKey/init           -> sessionKey_init.bin
    /mappingAccount            -> mappingAccount.bin
即：'/' 换成 '_'，去掉首尾 '/'。
"""
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAP = os.path.join(ROOT, 'work', 'http_capture')
OUT = os.path.join(ROOT, 'offline', 'lua', 'canon', 'single', 'http_replay.lua')


def path_of(fname):
    key = fname[:-4]                      # 去 .bin
    parts = key.split('_')
    # 从文件名还原成 URL：至少两个已知段
    if key == 'systemInfo':
        return '/systemInfo'
    if key.startswith('check_'):
        return '/check/' + key[len('check_'):]
    if key.startswith('loginAccount_'):
        return '/loginAccount/' + key[len('loginAccount_'):]
    if key == 'sessionKey_init':
        return '/sessionKey/init'
    return '/' + '/'.join(parts)


def main():
    files = sorted(f for f in os.listdir(CAP) if f.endswith('.bin')) \
        if os.path.isdir(CAP) else []
    if not files:
        print('!! work/http_capture 里没有 .bin，先用在线模式跑一遍登录')
        return 1
    lines = [
        '-- 自动生成，勿手改：scripts/gen_http_replay.py',
        '-- 内容：登录链路上「直连 HTTP」端点的原始响应字节（AMF3+zlib+XOR 信封，',
        '-- 原样回放，不需要在 Lua 里重写编码器）。十六进制存储。',
        '--',
        '-- 重新抓取：把 plist 域名改回 android1.canon.happyelements.cn（走 hosts），',
        '-- 在线跑一遍游客登录，然后重跑本脚本。',
        'return {',
    ]
    total = 0
    for f in files:
        blob = open(os.path.join(CAP, f), 'rb').read()
        total += len(blob)
        lines.append("    ['%s'] = '%s'," % (path_of(f), blob.hex()))
        print('  %-36s %4d 字节' % (path_of(f), len(blob)))
    lines.append('}')
    open(OUT, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print('共 %d 条 / %d 字节 -> %s' % (len(files), total, OUT))
    return 0


if __name__ == '__main__':
    sys.exit(main())
