"""从单机端的 hecore.offline_meta 里抽出「跨服相关配置」的真实值。

这些是 **getMeta 下发的数据**（不是单机端特有的玩法），我们服务端缺它们，
客户端面板在拿到任何回包前就会 `nil.unlockLevel` 崩掉。

输出：work/cross_meta.json，供 meta_payload.py 合并。
"""
import json
import os
import sys

ROOT = r'E:\deepseek_projects\app_server'
sys.path.insert(0, os.path.join(ROOT, 'server'))
sys.stdout.reconfigure(encoding='utf-8')
import luaconf                                        # noqa: E402

SRC = os.path.join(ROOT, 'work', 'lua_cmp', 'solo_hecore_rpc')
OUT = os.path.join(ROOT, 'work', 'cross_meta.json')

KEYS = ['crossBossSettingConfig', 'crossBossHeroConfig', 'crossBossGoldBattleConfig',
        'crossBossRewardConfig', 'crossArenaSettingConfig',
        'crossServerTimeConfig', 'crossServerSettingConfig']


def main():
    text = open(SRC, 'rb').read().decode('utf-8', 'replace')
    i = text.find('hecore.offline_meta')
    j = text.find('hecore.offline_activities')
    block = text[i:j if j > i else i + 40000]

    got = {}
    for key in KEYS:
        marker = '["%s"]=' % key
        k = block.find(marker)
        if k < 0:
            print('%-28s 无' % key)
            continue
        start = block.find('{', k + len(marker) - 1)
        if start < 0:
            print('%-28s 找不到表' % key)
            continue
        try:
            val, end = luaconf.parse_value(block, start)
        except Exception as e:
            print('%-28s 解析失败: %s' % (key, e))
            continue
        got[key] = val
        n = len(val) if hasattr(val, '__len__') else 1
        print('%-28s OK  顶层 %s 项, %d 字节' % (key, n, end - start))

    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(got, f, ensure_ascii=False, indent=1, default=str)
    print('\n已写出 %s（%d 个配置）' % (OUT, len(got)))
    for key in ('crossBossSettingConfig', 'crossArenaSettingConfig'):
        if key in got:
            print('\n%s = %s' % (key, json.dumps(got[key], ensure_ascii=False)[:700]))
    return 0


if __name__ == '__main__':
    sys.exit(main())
