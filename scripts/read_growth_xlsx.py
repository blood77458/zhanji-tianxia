# -*- coding: utf-8 -*-
"""把用户给的《五星武将成长表》xlsx 转成可读的文本摘要。

不装 openpyxl：xlsx 就是 zip + xml，直接用标准库解析。
输出：work/growth/dump.txt（完整）＋ 控制台摘要。
"""
import os
import re
import sys
import zipfile
import xml.etree.ElementTree as ET

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
XLSX = os.path.join(ROOT, 'work', 'growth', 'growth.xlsx')
OUT = os.path.join(ROOT, 'work', 'growth', 'dump.txt')
NS = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'


def col_index(ref):
    m = re.match(r'([A-Z]+)', ref or '')
    if not m:
        return 0
    n = 0
    for ch in m.group(1):
        n = n * 26 + (ord(ch) - 64)
    return n - 1


def shared_strings(z):
    if 'xl/sharedStrings.xml' not in z.namelist():
        return []
    root = ET.fromstring(z.read('xl/sharedStrings.xml'))
    out = []
    for si in root.findall(NS + 'si'):
        out.append(''.join(t.text or '' for t in si.iter(NS + 't')))
    return out


def sheet_names(z):
    wb = ET.fromstring(z.read('xl/workbook.xml'))
    rels = ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))
    rid2target = {}
    for r in rels:
        rid2target[r.get('Id')] = r.get('Target')
    out = []
    for sh in wb.find(NS + 'sheets'):
        rid = sh.get('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id')
        tgt = rid2target.get(rid, '')
        if not tgt.startswith('xl/'):
            tgt = 'xl/' + tgt.lstrip('/')
        out.append((sh.get('name'), tgt))
    return out


def read_sheet(z, path, sst):
    root = ET.fromstring(z.read(path))
    rows = []
    for row in root.iter(NS + 'row'):
        cells = {}
        for c in row.findall(NS + 'c'):
            ref = c.get('r')
            t = c.get('t')
            v = c.find(NS + 'v')
            isel = c.find(NS + 'is')
            if t == 's' and v is not None:
                val = sst[int(v.text)] if int(v.text) < len(sst) else ''
            elif t == 'inlineStr' and isel is not None:
                val = ''.join(x.text or '' for x in isel.iter(NS + 't'))
            elif v is not None:
                val = v.text
            else:
                val = ''
            cells[col_index(ref)] = (val or '').strip()
        if cells:
            width = max(cells) + 1
            rows.append([cells.get(i, '') for i in range(width)])
    return rows


def main():
    z = zipfile.ZipFile(XLSX)
    sst = shared_strings(z)
    names = sheet_names(z)
    lines = []
    print('工作表: %s' % [n for n, _ in names])
    for name, path in names:
        try:
            rows = read_sheet(z, path, sst)
        except KeyError:
            print('!! 解析失败', name, path)
            continue
        lines.append('=== sheet: %s  rows=%d ===' % (name, len(rows)))
        for r in rows:
            lines.append(' | '.join(r))
        lines.append('')
        # 控制台只打前 12 行
        print('\n--- %s (%d 行) ---' % (name, len(rows)))
        for r in rows[:12]:
            print('  ' + ' | '.join(r)[:200])
    open(OUT, 'w', encoding='utf-8').write('\n'.join(lines))
    print('\n完整内容 -> %s (%d 行)' % (OUT, len(lines)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
