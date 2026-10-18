#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 canon_server.py 里 `if method == "getMeta":` 那一整段（自包含，无 self 引用）
抽成独立模块 server/meta_payload.py，供新服务端直接调用。

不重写的原因：那 200 行里有大量实测踩出来的字段（adPictureConfig 的每个 id 都被
客户端无守卫解引用、activityFortuneNowConfig.fortuneFreeTime 缺失会 SIGKILL 等），
重新推导一遍风险极高。
"""
import io
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.abspath(os.path.join(HERE, '..', '..', 'server', 'canon_server.py'))
DST = os.path.abspath(os.path.join(HERE, '..', '..', 'server', 'meta_payload.py'))

lines = open(SRC, encoding='utf-8').read().split('\n')
start = next(i for i, l in enumerate(lines) if l.strip() == 'if method == "getMeta":')
end = next(i for i, l in enumerate(lines) if i > start and l.strip() == '# Bag / team /'
           ' mail / friends / beasts / shop / sweep + soft stubs.')
body = lines[start + 1:end]
while body and not body[-1].strip():
    body.pop()

# 原缩进 12 空格（if 体内），函数体要留 4 空格 → 去掉 8 空格
dedented = []
for l in body:
    dedented.append(l[8:] if l.startswith(' ' * 8) else l.lstrip())

header = '''#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""getMeta 的响应构造（从 canon_server.py 自动抽取，请勿手改本文件的载荷部分）。

抽取自 canon_server.py 第 %d-%d 行。里面每个字段都有踩坑注释，
改动前请先读那些注释 —— 这个接口是「少一个字段就 SIGKILL」的重灾区。
"""
import canon_server as _cs

# 把 canon_server 的模块级名字（含下划线开头的配置构造器）引进本命名空间，
# 让下面抽出来的代码能直接引用 _payment_exchanges() 等。
globals().update({k: v for k, v in vars(_cs).items() if not k.startswith('__')})


def get_meta_payload():
    method = "getMeta"          # 原代码在 _endpoint_response 里读外层变量，这里补上
''' % (start + 1, end)

open(DST, 'w', encoding='utf-8').write(header + '\n'.join(dedented) + '\n')
print('抽出第 %d-%d 行 -> %s' % (start + 1, end, DST))
