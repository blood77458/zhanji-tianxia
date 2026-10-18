"""找出客户端会读、但服务端 getMeta 没下发的配置 key。

客户端到处是 `DataManager.GameMetaData.xxxConfig` / `GameMetaData.xxx` 这种直接取字段，
没有 nil 守卫 —— 少一个 key 就是「进某个活动面板直接闪退」。

用法：
    python scripts/audit_meta_keys.py            # 只看缺失
    python scripts/audit_meta_keys.py --all      # 连已有的也列出来
"""
import os
import re
import sys

ROOT = r'E:\deepseek_projects\app_server'
sys.path.insert(0, os.path.join(ROOT, 'server'))
sys.stdout.reconfigure(encoding='utf-8')
os.chdir(os.path.join(ROOT, 'server'))

from meta_payload import get_meta_payload          # noqa: E402

LUASRC = os.path.join(ROOT, 'work', 'luasrc')
PAT = re.compile(r'GameMetaData\s*\.\s*([A-Za-z_]\w*)')
PAT2 = re.compile(r'GameMetaData\s*\.\s*([A-Za-z_]\w*)\s*\.\s*([A-Za-z_]\w*)')
# 这些不是配置 key，是方法/字段访问
SKIP = {'cardPictureConfig', 'toString'}


def main():
    meta = get_meta_payload()
    have = set(meta.keys())
    used = {}
    used2 = {}
    for dp, _, fs in os.walk(LUASRC):
        for f in fs:
            if not f.endswith('.lua'):
                continue
            p = os.path.join(dp, f)
            try:
                t = open(p, 'rb').read().decode('utf-8', 'replace')
            except Exception:
                continue
            for m in PAT.finditer(t):
                used.setdefault(m.group(1), set()).add(f.split('.')[0])
            for m in PAT2.finditer(t):
                used2.setdefault((m.group(1), m.group(2)), set()).add(f.split('.')[0])

    missing = {k: v for k, v in used.items() if k not in have and k not in SKIP}
    print('客户端引用的 meta key : %d' % len(used))
    print('服务端已下发         : %d' % len(have))
    print('** 顶层缺失         : %d **\n' % len(missing))

    for k in sorted(missing, key=lambda x: -len(missing[x])):
        files = sorted(missing[k])
        print('  %-38s %2d 处  例: %s' % (k, len(files), ', '.join(files[:3])))

    # 二层：父 key 存在、但子字段不存在 —— 这类最阴，因为「顶层看起来是全的」
    nested = {}
    for (k1, k2), v in used2.items():
        parent = meta.get(k1)
        if not isinstance(parent, dict):
            continue
        if k2 not in parent:
            nested.setdefault((k1, k2), set()).update(v)

    # 三层：客户端常写 `local cfg = DataManager.GameMetaData.xxxConfig` 再 `cfg.field`，
    # 正则抓不到第二层。这里先在每个文件里解析「局部变量 -> meta key」的别名，
    # 再收集 `别名.field` 的访问。
    LOC = re.compile(r'local\s+(\w+)\s*=\s*(?:DataManager\s*\.\s*)?GameMetaData\s*\.\s*([A-Za-z_]\w*)')
    for dp, _, fs in os.walk(LUASRC):
        for f in fs:
            if not f.endswith('.lua'):
                continue
            p = os.path.join(dp, f)
            try:
                t = open(p, 'rb').read().decode('utf-8', 'replace')
            except Exception:
                continue
            for m in LOC.finditer(t):
                var, key = m.group(1), m.group(2)
                parent = meta.get(key)
                if not isinstance(parent, dict):
                    continue
                for fm in re.finditer(r'\b%s\s*\.\s*([A-Za-z_]\w*)' % re.escape(var), t):
                    field = fm.group(1)
                    if field not in parent:
                        nested.setdefault((key, field), set()).add(f.split('.')[0])

    print('\n** 嵌套字段缺失: %d **' % len(nested))
    for (k1, k2), files in sorted(nested.items(), key=lambda kv: -len(kv[1])):
        fs = sorted(files)
        print('  %s.%s' % (k1, k2))
        print('       %2d 处  例: %s' % (len(fs), ', '.join(fs[:3])))

    # 当回归门禁用：有任何缺失就返回非 0
    return 0 if (not missing and not nested) else 1


if __name__ == '__main__':
    sys.exit(main())
