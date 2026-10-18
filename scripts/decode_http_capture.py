# -*- coding: utf-8 -*-
"""解码抓到的直连 HTTP 响应，看内容是否与请求/时间相关。"""
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'server'))

from protocol import amf3_decode  # noqa: E402

CAP = os.path.join(ROOT, 'work', 'http_capture')

for name in sorted(os.listdir(CAP)):
    if not name.endswith('.bin'):
        continue
    raw = open(os.path.join(CAP, name), 'rb').read()
    print('=== %s (%d 字节) head=%s' % (name, len(raw), raw[:4].hex()))
    try:
        obj = amf3_decode(raw)
        print('   ' + json.dumps(obj, ensure_ascii=False)[:600])
    except Exception as e:
        print('   解码失败: %r' % (e,))
