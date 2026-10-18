"""从真实抓包里解析出完整的一场战斗 eventFlow，摸清事件结构。

输出：
  work/ref_battle_sample.json   一场真实战斗的完整 eventFlow（缩进、可读）
  控制台打印事件序列摘要
"""
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = r'E:\deepseek_projects\app_server'
SRC = os.path.join(ROOT, 'work', 'reference_capture', 'reference_decoded_2.json')
OUT = os.path.join(ROOT, 'work', 'ref_battle_sample.json')


def walk(node, path=''):
    """在任意深度找 eventFlow 数组。"""
    if isinstance(node, dict):
        for k, v in node.items():
            if k == 'eventFlow' and isinstance(v, (list, dict)):
                yield path, v
            else:
                yield from walk(v, path + '/' + str(k))
    elif isinstance(node, list):
        for i, v in enumerate(node):
            yield from walk(v, path + '[%d]' % i)


def as_list(v):
    if isinstance(v, list):
        return v
    if isinstance(v, dict):
        if not v:
            return []
        if all(str(k).isdigit() for k in v):
            return [v[k] for k in sorted(v, key=lambda x: int(x))]
    return []


def main():
    raw = open(SRC, encoding='utf-8', errors='replace').read()
    # 抓包不是合法 JSON（有重复键/截断），用 json 试一次，失败就正则兜底
    try:
        data = json.loads(raw)
    except Exception:
        data = None
    flows = []
    if data is not None:
        flows = list(walk(data))
    print('解析出 %d 处 eventFlow' % len(flows))
    if not flows:
        print('!! 没有可用 JSON 结构，需要其他方式'); return 1

    # 取最长的那一场
    flows.sort(key=lambda kv: -len(as_list(kv[1])))
    path, flow = flows[0]
    evs = as_list(flow)
    print('最长一场: %s，共 %d 条事件' % (path, len(evs)))

    json.dump(evs, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('已写出 %s' % OUT)

    from collections import Counter
    c = Counter()
    for e in evs:
        acts = as_list(e.get('battleCardActs'))
        effs = tuple(sorted({int(a.get('effectId') or 0) for a in acts}))
        c[(int(e.get('eventType') or 0), int(e.get('actionType') or 0), effs)] += 1
    print('\n(eventType, actionType, effectId集合) -> 条数')
    for k, v in c.most_common(12):
        print('   %-22s %d' % (str(k), v))

    print('\n前 3 条完整事件:')
    for e in evs[:3]:
        print(json.dumps(e, ensure_ascii=False)[:400])
    return 0


if __name__ == '__main__':
    sys.exit(main())
