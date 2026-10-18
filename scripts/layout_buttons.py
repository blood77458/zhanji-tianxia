#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从 APK 内的 UI 布局 json 反推各元素的**绝对屏幕坐标**。

引擎渲染方式（hecore/ui/LayoutBuilder.lua）：
    image:setPosition(ccp(symbol.x, -symbol.y)) ; anchor(0,1)
    group 也一样，通过 setBasicTransformation 摆到父级里
    type: kImage=0, kText=1, kGroup=2   （kGroup 的 symbol.image 就是子 group 名）

所以：
    绝对x = Σ(各层 group 的 x) + item.x
    绝对y = Σ(各层 group 的 y) + item.y      （y 向下为正，与 adb input tap 一致）
    中心点 = 绝对坐标 + (w/2, h/2)

设计分辨率 720x1280，设备 720x1280 -> k = 1。
"""
import argparse
import json
import os
import re
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

LAYOUTS = {
    'shouye_new': '主界面(首页)',
    'login_new': '登录页',
    'CharacterSelect_new': '选角',
    'package_new': '背包',
    'formation_new': '队伍/阵容',
    'card_new': '武将',
    'gacha_new': '抽卡',
    'shop_new': '商店',
    'email_all_new': '邮箱',
    'friend_new': '好友',
    'guild': '军团',
    'arena_new': '竞技场',
    'chapterSelect_new': '章节/闯关',
    'elite_new': '精英',
    'task_activity': '任务/活动',
    'option_new': '设置',
    'mainmenu_scene_new': '主界面旧版',
}


def find_apk():
    for d in (os.path.join(ROOT, 'client'), os.path.join(ROOT, 'work')):
        if not os.path.isdir(d):
            continue
        c = [os.path.join(d, f) for f in os.listdir(d) if f.lower().endswith('.apk')]
        if not c:
            continue
        s = [x for x in c if 'enablefix' in os.path.basename(x).lower()]
        c = s or c
        c.sort(key=lambda p: os.path.getmtime(p), reverse=True)
        return c[0]
    raise SystemExit('no apk')


def load_layout(apk, logical):
    with zipfile.ZipFile(apk) as z:
        pat = re.compile(r'assets/resource/ui_json/%s\.[0-9a-f]{16,40}\.json$' % re.escape(logical))
        hit = [n for n in z.namelist() if pat.match(n)]
        if not hit:
            return None
        return json.loads(z.read(hit[0]).decode('utf-8'))


def build_hierarchy(cfg):
    """返回 (parent_of_group, offset_in_parent)。type==2 的条目 image 即子 group 名。"""
    groups = cfg.get('groups', {})
    parent = {}
    off = {}
    for gname, items in groups.items():
        for it in items:
            if it.get('type') == 2 and it.get('image'):
                child = it['image']
                if child in groups and child not in parent:
                    parent[child] = gname
                    off[child] = (it.get('x', 0), it.get('y', 0))
    return parent, off


def root_groups(cfg):
    groups = cfg.get('groups', {})
    parent, _ = build_hierarchy(cfg)
    return [g for g in groups if g not in parent]


def abs_offset(gname, parent, off, cache):
    if gname in cache:
        return cache[gname]
    if gname not in parent:
        cache[gname] = (0, 0)
        return cache[gname]
    px, py = abs_offset(parent[gname], parent, off, cache)
    ox, oy = off[gname]
    cache[gname] = (px + ox, py + oy)
    return cache[gname]


def walk(apk, logical, k=1.0):
    cfg = load_layout(apk, logical)
    if not cfg:
        return None, None
    parent, off = build_hierarchy(cfg)
    cache = {}
    out = []
    for gname, items in cfg.get('groups', {}).items():
        gx, gy = abs_offset(gname, parent, off, cache)
        for it in items:
            x = it.get('x', 0); y = it.get('y', 0)
            w = it.get('width', 0); h = it.get('height', 0)
            ax, ay = gx + x, gy + y
            out.append({
                'group': gname,
                'id': it.get('id') or '',
                'image': it.get('image') or '',
                'type': it.get('type'),
                'abs': (ax, ay),
                'wh': (w, h),
                'tap': (int(round((ax + w / 2.0) * k)), int(round((ay + h / 2.0) * k))),
            })
    return out, root_groups(cfg)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--layout', default='shouye_new')
    ap.add_argument('--filter', default=None)
    ap.add_argument('--all', action='store_true', help='列出所有 layout')
    ap.add_argument('--screen', default='720x1280')
    ap.add_argument('--only-clickable', action='store_true', default=True)
    a = ap.parse_args()

    sw, sh = (int(v) for v in a.screen.lower().split('x'))
    k = sh / 1280.0
    apk = find_apk()
    print('APK: %s   设备 %dx%d   k=%.4f' % (apk, sw, sh, k))
    print()

    targets = list(LAYOUTS) if a.all else [a.layout]
    for logical in targets:
        rows, roots = walk(apk, logical, k)
        if rows is None:
            print('== %-24s 未找到' % logical)
            continue
        print('== %s (%s)   root groups=%s' % (logical, LAYOUTS.get(logical, ''), roots))
        for r in rows:
            if a.filter and a.filter not in r['id'] and a.filter not in r['image'] and a.filter not in r['group']:
                continue
            if r['type'] != 0:      # 只看图片（可点区域基本都是 kImage）
                continue
            if not r['id'] and not r['image']:
                continue
            print('   %-36s grp=%-30s abs=(%5d,%5d) wh=(%4d,%4d) -> tap(%4d,%4d)'
                  % (r['id'] or r['image'], r['group'], r['abs'][0], r['abs'][1],
                     r['wh'][0], r['wh'][1], r['tap'][0], r['tap'][1]))
        print()


if __name__ == '__main__':
    main()
