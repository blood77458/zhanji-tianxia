#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""校验分享包：文档结构完整性 + zip 内容一致。

用法:
    python work/api_analysis/make_share_package.py   # 先生成
    python work/api_analysis/verify_package.py       # 再校验

查的是「删内容时容易删坏」的东西：
  * markdown 表格列数是否还与表头一致（删了一列最容易漏改分隔行）
  * 代码围栏是否成对（删整节最容易留下半截 ```）
  * 一级标题编号是否连续（删了 §7 就要把后面全部前移）
  * §X 交叉引用是否还指得到
  * 是否还残留只描述本仓库实现的字样
  * zip 里的文件与 dist 目录逐字节一致
"""
import os
import re
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
DIST = os.path.join(ROOT, 'dist')
PKG = 'zjt_canon_server_pack'
OUT = os.path.join(DIST, PKG)

FAIL = []


def check(label, cond, detail=''):
    if cond:
        print('  [OK]   %s %s' % (label, detail))
    else:
        print('  [FAIL] %s %s' % (label, detail))
        FAIL.append(label)


def read(fn):
    return open(os.path.join(OUT, fn), encoding='utf-8').read()


def check_headings(name, text, top_max):
    hs = re.findall(r'^## (\d+)\.', text, re.M)
    nums = [int(x) for x in hs]
    check('%s 一级标题连续 0..%d' % (name, top_max),
          nums == list(range(top_max + 1)), '实际 %s' % nums)


def check_tables(name, text):
    """逐表核对：每行的竖线数必须与表头一致。"""
    lines = text.split('\n')
    bad = []
    i = 0
    n_tables = 0
    while i < len(lines):
        l = lines[i]
        if l.startswith('|') and i + 1 < len(lines) \
                and re.match(r'^\|[\s\-:|]+\|\s*$', lines[i + 1]):
            n_tables += 1
            width = l.count('|')
            j = i + 2
            while j < len(lines) and lines[j].startswith('|'):
                if lines[j].count('|') != width:
                    bad.append('第 %d 行 列数 %d != 表头 %d: %s'
                               % (j + 1, lines[j].count('|'), width,
                                  lines[j][:60]))
                j += 1
            i = j
        else:
            i += 1
    check('%s 全部 %d 个表格列数自洽' % (name, n_tables), not bad,
          '' if not bad else '\n         ' + '\n         '.join(bad[:8]))


def check_fences(name, text):
    n = len(re.findall(r'^```', text, re.M))
    check('%s 代码围栏成对' % name, n % 2 == 0, '共 %d 个' % n)


def check_refs(name, text, top_max):
    refs = set()
    for m in re.finditer(r'§(\d+)(?:\.(\d+))?', text):
        refs.add((int(m.group(1)), m.group(2)))
    bad = [r for r in refs if r[0] > top_max]
    check('%s §X 交叉引用都可解析' % name, not bad, '越界: %s' % bad)


def main():
    if not os.path.isdir(OUT):
        print('先跑 make_share_package.py')
        sys.exit(1)

    api = read('API.md')
    mdl = read('SERVER_DATA_MODEL.md')

    print('=' * 74)
    print('一、标题编号连续性')
    print('=' * 74)
    check_headings('API.md', api, 9)
    check_headings('SERVER_DATA_MODEL.md', mdl, 9)

    print()
    print('=' * 74)
    print('二、markdown 表格列数自洽（删列的回归检查）')
    print('=' * 74)
    check_tables('API.md', api)
    check_tables('SERVER_DATA_MODEL.md', mdl)

    print()
    print('=' * 74)
    print('三、代码围栏与交叉引用')
    print('=' * 74)
    check_fences('API.md', api)
    check_fences('SERVER_DATA_MODEL.md', mdl)
    check_refs('API.md', api, 9)
    check_refs('SERVER_DATA_MODEL.md', mdl, 9)

    print()
    print('=' * 74)
    print('四、不应残留的「本仓库实现」字样')
    print('=' * 74)
    banned = [
        ('canon_server', '具体服务端文件名'),
        ('features.py', '具体服务端文件名'),
        ('work/api_analysis', '分析工具路径'),
        ('work/luasrc', '本仓库路径'),
        ('user_state.json', '旧存档文件名'),
        ('rpc_payloads.jsonl', '旧落盘文件名'),
        ('ARCHITECTURE.md', '本仓库文档'),
        ('smoke_assemble', '本仓库测试'),
        ('服务端实现', '逐接口实现状态'),
        ('建议补齐', '补齐建议'),
        ('迁移', '迁移章节'),
        ('自建服务端', '实现指代'),
    ]
    for word, why in banned:
        n = api.count(word) + mdl.count(word)
        check('无残留「%s」' % word, n == 0, '(%s) 命中 %d' % (why, n))

    print()
    print('=' * 74)
    print('五、保留内容抽检（不能删过头）')
    print('=' * 74)
    keep_api = [
        ('363 个 RPC method', '接口总表'),
        ('headercvt', '编码管线'),
        ('subHeader.errCode', '响应信封'),
        ('0x71', '响应方向异或'),
        ('<protocol>', '内嵌协议 DSL'),
        ('SHARK_ERROCODE_ORIGH', '错误码基址'),
        ('SIGKILL', '踩坑清单'),
        ('免责', '免责声明'),
        ('baiduDK', '目标包信息'),
    ]
    for word, why in keep_api:
        check('API.md 保留「%s」' % word, word in api, '(%s)' % why)

    keep_mdl = [
        ('88 张表', '规模'),
        ('组装层', '核心设计'),
        ('多数据库方言', '方言章节'),
        ('schema_mysql.sql', 'MySQL DDL'),
        ('schema_pg.sql', 'PG DDL'),
        ('8.0.13+', 'MySQL 版本要求'),
        ('JSONB', 'PG 类型映射'),
        ('免责', '见 README'),
    ]
    for word, why in keep_mdl:
        if word == '免责':
            continue
        check('SERVER_DATA_MODEL.md 保留「%s」' % word, word in mdl, '(%s)' % why)

    print()
    print('=' * 74)
    print('六、zip 内容与 dist 目录一致')
    print('=' * 74)
    zip_path = os.path.join(DIST, PKG + '.zip')
    check('zip 存在', os.path.exists(zip_path))
    if os.path.exists(zip_path):
        with zipfile.ZipFile(zip_path) as z:
            names = sorted(i.filename for i in z.infolist())
            want = sorted(PKG + '/' + f for f in
                          ('README.md', 'API.md', 'SERVER_DATA_MODEL.md',
                           'schema.sql', 'schema_mysql.sql', 'schema_pg.sql'))
            check('zip 内文件齐全', names == want, '%s' % names)
            same = True
            for f in ('README.md', 'API.md', 'SERVER_DATA_MODEL.md',
                      'schema.sql', 'schema_mysql.sql', 'schema_pg.sql'):
                if z.read(PKG + '/' + f) != open(
                        os.path.join(OUT, f), 'rb').read():
                    same = False
                    FAIL.append('zip 内 %s 与 dist 不一致' % f)
            check('zip 内每个文件与 dist 逐字节一致', same)
            bad = z.testzip()
            check('zip 完整性（CRC）', bad is None, '' if bad is None else bad)

    print()
    print('=' * 74)
    if FAIL:
        print('结果: %d 项失败' % len(FAIL))
        for f in FAIL:
            print('  - %s' % f)
        sys.exit(1)
    print('结果: 全部通过')
    print('=' * 74)


if __name__ == '__main__':
    main()
