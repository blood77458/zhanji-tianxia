#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""校验三套 DDL：SQLite 真建库，MySQL / PostgreSQL 用 sqlglot 逐语句解析。

用法:
    python work/api_analysis/verify_dialects.py

没有本地 MySQL/PG 服务端，所以这两个方言只能做**语法级**校验
（sqlglot 是完整的方言解析器，能揪出类型写错、默认值写错、缺逗号这类问题）。
校验通过不代表能跑，但能挡住 99% 的手写 DDL 低级错误。
"""
import os
import re
import sqlite3
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRV = os.path.join(ROOT, 'server')

FAIL = []


def ok(msg):
    print('  [OK]   %s' % msg)


def bad(msg):
    print('  [FAIL] %s' % msg)
    FAIL.append(msg)


def split_statements(sql):
    """按分号切语句，跳过注释与空语句。"""
    lines = []
    for l in sql.split('\n'):
        s = l.strip()
        if s.startswith('--'):
            continue
        lines.append(l)
    body = '\n'.join(lines)
    out = []
    for st in body.split(';'):
        st = st.strip()
        if st:
            out.append(st)
    return out


def counts(sql):
    return {
        'table': len(re.findall(r'\bCREATE TABLE\b', sql)),
        'view': len(re.findall(r'\bCREATE VIEW\b', sql)),
        'index': len(re.findall(r'\bCREATE INDEX\b', sql)),
        'unique_index': len(re.findall(r'\bCREATE UNIQUE INDEX\b', sql)),
    }


def main():
    print('=' * 74)
    print('一、SQLite 版：真建库 + 建表数核对')
    print('=' * 74)
    sq = os.path.join(SRV, 'schema.sql')
    sql = open(sq, encoding='utf-8').read()
    fd, tmp = tempfile.mkstemp(suffix='.db')
    os.close(fd)
    try:
        con = sqlite3.connect(tmp)
        con.executescript(sql)
        tables = [r[0] for r in con.execute(
            "SELECT name FROM sqlite_master WHERE type='table'"
            " AND name NOT LIKE 'sqlite_%' ORDER BY name")]
        views = [r[0] for r in con.execute(
            "SELECT name FROM sqlite_master WHERE type='view' ORDER BY name")]
        idx = [r[0] for r in con.execute(
            "SELECT name FROM sqlite_master WHERE type='index'"
            " AND name NOT LIKE 'sqlite_%'")]
        cols = 0
        for t in tables:
            cols += len(list(con.execute('PRAGMA table_info(%s)' % t)))
        alloc = con.execute('SELECT COUNT(*) FROM id_alloc').fetchone()[0]
        con.close()
        ok('建库成功：%d 表 / %d 视图 / %d 索引 / %d 列' %
           (len(tables), len(views), len(idx), cols))
        ok('id_alloc 种子数据 %d 行' % alloc)
    except Exception as e:                                   # noqa: BLE001
        bad('SQLite 建库失败: %s' % e)
        return

    print()
    print('=' * 74)
    print('二、三种方言的语句数量必须一致')
    print('=' * 74)
    base = counts(sql)
    for name, fn in (('schema_mysql.sql', 'schema_mysql.sql'),
                     ('schema_pg.sql', 'schema_pg.sql')):
        p = os.path.join(SRV, fn)
        if not os.path.exists(p):
            bad('%s 不存在' % fn)
            continue
        c = counts(open(p, encoding='utf-8').read())
        if c == base:
            ok('%s 表/视图/索引数与 SQLite 版一致 %s' % (name, c))
        else:
            bad('%s 数量不符: %s != %s' % (name, c, base))

    print()
    print('=' * 74)
    print('三、MySQL / PostgreSQL 方言语法解析（sqlglot）')
    print('=' * 74)
    try:
        import sqlglot
    except ImportError:
        bad('未安装 sqlglot，跳过方言校验（pip install sqlglot）')
        return

    for fn, dialect in (('schema_mysql.sql', 'mysql'),
                        ('schema_pg.sql', 'postgres')):
        p = os.path.join(SRV, fn)
        text = open(p, encoding='utf-8').read()
        stmts = split_statements(text)
        errs = []
        for i, st in enumerate(stmts, 1):
            try:
                sqlglot.parse_one(st, dialect=dialect)
            except Exception as e:                           # noqa: BLE001
                head = st.split('\n')[0][:70]
                errs.append('#%d %s -> %s' % (i, head, str(e).split('\n')[0]))
        if errs:
            bad('%s 解析失败 %d 条：' % (fn, len(errs)))
            for e in errs[:12]:
                print('         %s' % e)
        else:
            ok('%s 全部 %d 条语句解析通过' % (fn, len(stmts)))

    print()
    print('=' * 74)
    print('四、方言特有构造抽查')
    print('=' * 74)

    def code_only(text):
        """去掉 `--` 注释行 —— 文件头里也写着 AUTOINCREMENT 做对照说明，
        不过滤掉的话断言会误判。"""
        return '\n'.join(l for l in text.split('\n')
                         if not l.strip().startswith('--'))

    my = code_only(open(os.path.join(SRV, 'schema_mysql.sql'), encoding='utf-8').read())
    pg = code_only(open(os.path.join(SRV, 'schema_pg.sql'), encoding='utf-8').read())

    checks = [
        ('MySQL 无 AUTOINCREMENT', 'AUTOINCREMENT' not in my),
        ('MySQL 无 PRAGMA', not re.search(r'^\s*PRAGMA', my, re.M)),
        ('MySQL 有 21 个 AUTO_INCREMENT', my.count('AUTO_INCREMENT') == 21),
        ('MySQL 每张表都带 ENGINE=InnoDB（88）',
         my.count('ENGINE=InnoDB') == 88),
        ('MySQL 无裸 DEFAULT 的 TEXT/LONGTEXT（必须加括号）',
         not re.search(r'^\s+\w+\s+(?:TEXT|LONGTEXT)\b[^,]*DEFAULT\s+'
                       r"(?!\()'", my, re.M)),
        ('MySQL 的 rank 列已加反引号', '`rank`' in my),
        ('MySQL 无残留 REAL（应转 DOUBLE）',
         not re.search(r'^\s+\w+\s+REAL\b', my, re.M)),
        ('PG 无 AUTOINCREMENT', 'AUTOINCREMENT' not in pg),
        ('PG 无 PRAGMA', not re.search(r'^\s*PRAGMA', pg, re.M)),
        ('PG 有 21 个 BIGSERIAL', pg.count('BIGSERIAL') == 21),
        ('PG 的 JSON 列是 JSONB', 'JSONB' in pg),
        ('PG 的 JSONB 默认值带 ::jsonb', '::jsonb' in pg),
        ('PG 保留字未误加引号（value/rank 裸用）',
         '"value"' not in pg and '"rank"' not in pg),
        ('PG 无残留 REAL（应转 DOUBLE PRECISION）',
         not re.search(r'^\s+\w+\s+REAL\b', pg, re.M)),
    ]
    for label, cond in checks:
        (ok if cond else bad)(label)

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
