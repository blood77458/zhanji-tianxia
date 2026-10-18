"""判断每个 endpoint 的客户端回调**是否需要读回包字段**。

空壳响应（只有 retCode）本身不一定有害：动作类接口（已读/删除/装备）客户端
通常自己刷新本地状态；但查询类和发奖类必须带字段，否则 nil index 直接崩。

做法：
  1. 找 endpoint 所属请求类，取 Success 事件名；
  2. 全库搜该事件的 addEventListener 注册点；
  3. 从注册点往后取 window 行，抓 `var.field`（var 是数据型形参）；
  4. 有字段访问 => NEEDS_PAYLOAD，否则 => 空壳可接受。

用法: python scripts/needs_payload.py <endpoint> [...]
"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = r'E:\deepseek_projects\app_server\work\luasrc'
EP = re.compile(r'endpoint\s*=\s*"(\w+)"')
SUCC = re.compile(r'RequestNotifyEnum\.(\w+)')
DATAVARS = ('data', 'e', 'evt', 'event', 'responseData', 'result', 'msg', 'res', 'packet')
WINDOW = 70


def load_all():
    out = []
    for dp, _, fs in os.walk(ROOT):
        for f in fs:
            if f.endswith('.lua'):
                p = os.path.join(dp, f)
                try:
                    out.append((p, open(p, 'rb').read().decode('utf-8', 'replace')))
                except Exception:
                    pass
    return out


def analyse(ep, files):
    """返回 (事件名, [(文件, 回调名, 字段列表)])"""
    ev = None
    for p, t in files:
        m = EP.search(t)
        if not m or m.group(1) != ep:
            continue
        for s in SUCC.findall(t):
            if 'Succeed' in s or 'Success' in s:
                ev = s
                break
        if ev:
            break
    if not ev:
        return None, []

    hits = []
    pat = re.compile(r'RequestNotifyEnum\.%s\s*,\s*([\w\.]+)' % re.escape(ev))
    for p, t in files:
        if ev not in t:
            continue
        for m in pat.finditer(t):
            cb = m.group(1).split('.')[-1]
            lines = t[m.end():].split('\n')[:WINDOW]
            body = '\n'.join(lines)
            flds = set()
            for v in DATAVARS:
                flds |= set(re.findall(r'\b%s\.([A-Za-z_]\w*)' % v, body))
            # retCode/extraMsg 是每个响应都有的状态字段；'data' 来自 e.data 这种
            # 事件解包写法，也不是业务字段。都不算「需要载荷」。
            flds -= {'retCode', 'extraMsg', 'errorCode', 'errCode', 'data',
                     'method', 'success'}
            hits.append((os.path.basename(p), cb, sorted(flds)))
    return ev, hits


def main():
    eps = sys.argv[1:]
    if not eps:
        print('usage: needs_payload.py <endpoint> [...]')
        return 1
    files = load_all()
    need, no = [], []
    for ep in eps:
        ev, hits = analyse(ep, files)
        if ev is None:
            print('%-30s ?  无请求类/事件名' % ep)
            continue
        allf = sorted({f for _, _, fs in hits for f in fs})
        if allf:
            need.append(ep)
            print('%-30s 需要回包  %s' % (ep, ', '.join(allf[:12])))
        else:
            no.append(ep)
            print('%-30s 空壳可接受' % ep)
    print('\n需要回包 %d 个 / 空壳可接受 %d 个' % (len(need), len(no)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
