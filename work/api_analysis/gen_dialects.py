#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 SQLite 版 `server/schema.sql` 转成 MySQL / PostgreSQL 方言。

用法:
    python work/api_analysis/gen_dialects.py

产出:
    server/schema_mysql.sql
    server/schema_pg.sql

设计取舍见脚本末尾的 DIALECT_NOTES。核心原则是**语义等价**：
同一份应用代码换库后不需要改行为，尤其是下面三件容易转错的事：

1. `INTEGER PRIMARY KEY AUTOINCREMENT` 在 MySQL 必须是
   `BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY`（AUTO_INCREMENT 列必须带键），
   在 PG 是 `BIGSERIAL PRIMARY KEY`（本身已隐含 NOT NULL + DEFAULT）。
2. `TEXT` 在 MySQL 里**不能直接写 `DEFAULT '...'`**，必须写成表达式
   `DEFAULT ('...')`（MySQL 8.0.13+）。这是本脚本唯一要求版本的地方。
3. PG 的 JSON 列用 `JSONB`，默认值要写成 `'{}'::jsonb`。
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(ROOT, 'server', 'schema.sql')

# ---------------------------------------------------------------------------
# 列名 → MySQL 文本类型宽度。
# 规则：**参与索引 / UNIQUE / PRIMARY KEY 的文本列必须是有界 VARCHAR**
#      （MySQL 对 TEXT 建索引要写前缀长度，很丑且容易漏）。
#      其余普通短文本给 255；确实可能很长的给 TEXT。
# ---------------------------------------------------------------------------
MYSQL_LEN = {
    'name': 191, 'nickname': 191, 'account_name': 191, 'guild_name': 191,
    'platform_id': 64, 'platform_uid': 191, 'device_id': 191, 'invite_code': 64,
    'session_key': 128, 'uuid': 64, 'uk': 128, 'udid': 128,
    'client_ip': 64, 'last_login_ip': 64,
    'password_hash': 128, 'password_salt': 64, 'email': 191,
    'board_key': 128, 'method': 128, 'operator': 128, 'title_text': 255,
    'sid': 128, 'reason': 255,
}
# 确实可能超过 64KB / 需要 TEXT 的
MYSQL_LONG_TEXT = {'content', 'content_text', 'declaration', 'notice'}

# 看起来像 JSON 的列：名字以 _json 结尾，或默认值就是 '{}' / '[]'
RE_JSON_NAME = re.compile(r'_json$', re.I)
RE_JSON_DEFAULT = re.compile(r"DEFAULT\s+'(?:\{\}|\[\])'")
RE_JSONB_EXTRA = {'params', 'report', 'entry', 'record', 'reward', 'results'}

# MySQL / PG 的保留字里可能被当列名用的（用于决定是否加引号）
MYSQL_RESERVED = {
    'add', 'all', 'alter', 'and', 'as', 'asc', 'before', 'between', 'bigint',
    'binary', 'blob', 'both', 'by', 'call', 'cascade', 'case', 'change', 'char',
    'character', 'check', 'collate', 'column', 'condition', 'constraint',
    'continue', 'convert', 'create', 'cross', 'current_date', 'current_time',
    'current_timestamp', 'current_user', 'cursor', 'database', 'databases',
    'day_hour', 'day_microsecond', 'day_minute', 'day_second', 'dec', 'decimal',
    'declare', 'default', 'delayed', 'delete', 'desc', 'describe',
    'deterministic', 'distinct', 'distinctrow', 'div', 'double', 'drop', 'dual',
    'each', 'else', 'elseif', 'enclosed', 'escaped', 'exists', 'exit',
    'explain', 'false', 'fetch', 'float', 'for', 'force', 'foreign', 'from',
    'fulltext', 'grant', 'group', 'having', 'high_priority', 'hour_microsecond',
    'hour_minute', 'hour_second', 'if', 'ignore', 'in', 'index', 'infile',
    'inner', 'insert', 'int', 'integer', 'interval', 'into', 'is', 'iterate',
    'join', 'key', 'keys', 'kill', 'leading', 'leave', 'left', 'like', 'limit',
    'linear', 'lines', 'load', 'localtime', 'localtimestamp', 'lock', 'long',
    'longblob', 'longtext', 'loop', 'low_priority', 'match', 'mediumblob',
    'mediumint', 'mediumtext', 'middleint', 'minute_microsecond',
    'minute_second', 'mod', 'modifies', 'natural', 'not', 'no_write_to_binlog',
    'null', 'numeric', 'on', 'optimize', 'option', 'optionally', 'or', 'order',
    'out', 'outer', 'outfile', 'precision', 'primary', 'procedure', 'purge',
    'range', 'read', 'reads', 'real', 'references', 'regexp', 'release', 'rename',
    'repeat', 'replace', 'require', 'restrict', 'return', 'revoke', 'right',
    'rlike', 'schema', 'schemas', 'second_microsecond', 'select', 'sensitive',
    'separator', 'set', 'show', 'smallint', 'soname', 'spatial', 'specific',
    'sql', 'sqlexception', 'sqlstate', 'sqlwarning', 'sql_big_result',
    'sql_calc_found_rows', 'sql_small_result', 'ssl', 'starting', 'straight_join',
    'table', 'terminated', 'then', 'tinyblob', 'tinyint', 'tinytext', 'to',
    'trailing', 'trigger', 'true', 'undo', 'union', 'unique', 'unlock',
    'unsigned', 'update', 'usage', 'use', 'using', 'utc_date', 'utc_time',
    'utc_timestamp', 'values', 'varbinary', 'varchar', 'varcharacter', 'varying',
    'when', 'where', 'while', 'with', 'write', 'xor', 'year_month', 'zerofill',
    'rank', 'groups', 'system', 'of', 'over', 'window', 'recursive', 'cume_dist',
    'dense_rank', 'first_value', 'lag', 'last_value', 'lead', 'nth_value',
    'ntile', 'percent_rank', 'row_number', 'empty', 'json_table', 'lateral',
}
PG_RESERVED = {
    'all', 'analyse', 'analyze', 'and', 'any', 'array', 'as', 'asc',
    'asymmetric', 'both', 'case', 'cast', 'check', 'collate', 'column',
    'constraint', 'create', 'current_catalog', 'current_date', 'current_role',
    'current_time', 'current_timestamp', 'current_user', 'default',
    'deferrable', 'desc', 'distinct', 'do', 'else', 'end', 'except', 'false',
    'fetch', 'for', 'foreign', 'freeze', 'from', 'full', 'grant', 'group',
    'having', 'ilike', 'in', 'initially', 'inner', 'intersect', 'into',
    'isnull', 'lateral', 'leading', 'left', 'like', 'limit', 'localtime',
    'localtimestamp', 'natural', 'not', 'notnull', 'null', 'offset', 'on',
    'only', 'or', 'order', 'outer', 'overlaps', 'placing', 'primary',
    'references', 'returning', 'right', 'select', 'session_user', 'similar',
    'some', 'symmetric', 'table', 'then', 'to', 'trailing', 'true', 'union',
    'unique', 'user', 'using', 'variadic', 'verbose', 'when', 'where', 'window',
    'with', 'authorization', 'binary', 'collation', 'concurrently', 'cross',
    'current_schema', 'freeze', 'full', 'ilike', 'is', 'isnull', 'join', 'left',
    'natural', 'notnull', 'over', 'overlaps', 'right', 'similar', 'tablesample',
    'variadic', 'key', 'rows', 'range', 'groups', 'system',
}
# 说明：`value` 与 `rank` 在 PG 里都是 **non-reserved**，可以直接当列名，
# 所以故意不放进上面的集合 —— 放进去了反而会让全表查询都必须加双引号。
# 而 `rank` 在 MySQL 8.0 之后是 **reserved**，必须加反引号，故留在
# MYSQL_RESERVED 里。


def die(msg):
    print('ERROR: %s' % msg)
    sys.exit(1)


# ---------------------------------------------------------------------------
# 解析：把 schema.sql 拆成「语句块」，认出 CREATE TABLE 的列定义行
# ---------------------------------------------------------------------------
RE_COL = re.compile(
    r'^(?P<indent>\s+)(?P<name>[a-z_][a-z0-9_]*)'
    r'(?P<sp>\s+)(?P<type>INTEGER|TEXT|REAL|BOOLEAN)(?P<rest>\b.*)$')


def split_columns(sql):
    """返回所有 (表名, 列名, 原始类型) —— 用于统计与冲突检查。"""
    out = []
    table = None
    for raw in sql.split('\n'):
        m = re.match(r'\s*CREATE TABLE\s+(\w+)\s*\(', raw)
        if m:
            table = m.group(1)
            continue
        if re.match(r'\s*\)\s*;', raw):
            table = None
            continue
        if table:
            cm = RE_COL.match(raw)
            if cm:
                out.append((table, cm.group('name'), cm.group('type')))
    return out


def check_reserved(cols):
    m_hits = sorted({c for _t, c, _ty in cols if c.lower() in MYSQL_RESERVED})
    p_hits = sorted({c for _t, c, _ty in cols if c.lower() in PG_RESERVED})
    return m_hits, p_hits


# ---------------------------------------------------------------------------
# MySQL
# ---------------------------------------------------------------------------
def mysql_text_type(col):
    lc = col.lower()
    if RE_JSON_NAME.search(lc) or lc in RE_JSONB_EXTRA:
        return 'LONGTEXT'
    if lc in MYSQL_LONG_TEXT:
        return 'TEXT'
    if lc in MYSQL_LEN:
        return 'VARCHAR(%d)' % MYSQL_LEN[lc]
    return 'VARCHAR(255)'


def to_mysql(sql, reserved):
    out = []
    in_table = False
    for raw in sql.split('\n'):
        line = raw

        # 1) 行级注释 / 空行原样保留
        stripped = line.strip()
        if not stripped or stripped.startswith('--'):
            out.append(line)
            continue

        # 2) PRAGMA 删掉
        if stripped.upper().startswith('PRAGMA'):
            out.append('-- （MySQL 无需 PRAGMA：InnoDB 外键默认开启）')
            continue

        # 3) CREATE TABLE 开头 / 结尾
        if re.match(r'\s*CREATE TABLE\s+\w+\s*\(', line):
            in_table = True
            out.append(line)
            continue
        if in_table and re.match(r'\s*\)\s*;\s*$', line):
            in_table = False
            out.append(') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
                       ' COLLATE=utf8mb4_unicode_ci;')
            continue

        # 4) 列定义
        if in_table:
            cm = RE_COL.match(line)
            if cm:
                col, ty, rest = cm.group('name'), cm.group('type'), cm.group('rest')
                if ty == 'INTEGER' and re.search(r'PRIMARY KEY\s+AUTOINCREMENT', rest):
                    rest = re.sub(r'PRIMARY KEY\s+AUTOINCREMENT',
                                  'NOT NULL AUTO_INCREMENT PRIMARY KEY', rest)
                    ty = 'BIGINT'
                elif ty == 'INTEGER':
                    ty = 'BIGINT'
                elif ty == 'REAL':
                    ty = 'DOUBLE'
                elif ty == 'BOOLEAN':
                    ty = 'TINYINT(1)'
                elif ty == 'TEXT':
                    ty = mysql_text_type(col)
                # TEXT/LONGTEXT 的默认值必须写成表达式
                if ty in ('TEXT', 'LONGTEXT', 'JSON'):
                    rest = re.sub(r"DEFAULT\s+('(?:[^']|'')*')",
                                  r'DEFAULT (\1)', rest)
                name = col
                if col.lower() in reserved:
                    name = '`%s`' % col
                out.append('%s%s%s%s%s' % (cm.group('indent'), name,
                                           cm.group('sp'), ty, rest))
                continue

        out.append(line)
    return '\n'.join(out)


# ---------------------------------------------------------------------------
# PostgreSQL
# ---------------------------------------------------------------------------
def to_pg(sql, reserved):
    out = []
    in_table = False
    for raw in sql.split('\n'):
        line = raw
        stripped = line.strip()
        if not stripped or stripped.startswith('--'):
            out.append(line)
            continue

        if stripped.upper().startswith('PRAGMA'):
            out.append('-- （PG 无需 PRAGMA：外键默认强制）')
            continue

        if re.match(r'\s*CREATE TABLE\s+\w+\s*\(', line):
            in_table = True
            out.append(line)
            continue
        if in_table and re.match(r'\s*\)\s*;\s*$', line):
            in_table = False
            out.append(line)
            continue

        if in_table:
            cm = RE_COL.match(line)
            if cm:
                col, ty, rest = cm.group('name'), cm.group('type'), cm.group('rest')
                is_json = bool(RE_JSON_NAME.search(col.lower())
                               or RE_JSON_DEFAULT.search(rest))
                if ty == 'INTEGER' and re.search(r'PRIMARY KEY\s+AUTOINCREMENT', rest):
                    rest = re.sub(r'PRIMARY KEY\s+AUTOINCREMENT', 'PRIMARY KEY', rest)
                    ty = 'BIGSERIAL'
                elif ty == 'INTEGER':
                    ty = 'BIGINT'
                elif ty == 'REAL':
                    ty = 'DOUBLE PRECISION'
                elif ty == 'BOOLEAN':
                    ty = 'BOOLEAN'
                elif ty == 'TEXT':
                    ty = 'JSONB' if is_json else 'TEXT'
                if ty == 'JSONB':
                    rest = re.sub(r"DEFAULT\s+'(\{\}|\[\])'",
                                  r"DEFAULT '\1'::jsonb", rest)
                name = col
                if col.lower() in reserved:
                    name = '"%s"' % col
                out.append('%s%s%s%s%s' % (cm.group('indent'), name,
                                           cm.group('sp'), ty, rest))
                continue

        out.append(line)
    return '\n'.join(out)


# ---------------------------------------------------------------------------
HEADER_MYSQL = """\
-- ============================================================================
--  《战姬天下》(canon) 服务端数据库结构  v1 —— MySQL 版
-- ============================================================================
--  本文件由 `server/schema.sql`（SQLite 版）自动转换而来，**表/列/索引/视图
--  与 SQLite 版一一对应**，语义等价。改动请改 SQLite 版后重新生成。
--
--  引擎：InnoDB / utf8mb4
--  要求：**MySQL 8.0.13 及以上**
--        原因：TEXT / LONGTEXT / JSON 列要带默认值，MySQL 只允许写成表达式
--        形式 `DEFAULT ('{}')`，这个语法从 8.0.13 起才支持。若必须跑 5.7，
--        把所有 `DEFAULT ('...')` 改成不带默认值（或在应用层补值）即可。
--
--  与 SQLite 版的类型映射
--  ----------------------
--    INTEGER  -> BIGINT            （统一用 BIGINT：时间戳列不受 2038 限制）
--    INTEGER PRIMARY KEY AUTOINCREMENT
--             -> BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY
--    REAL     -> DOUBLE
--    BOOLEAN  -> TINYINT(1)        （SQLite 本来就用 INTEGER 0/1，没有语义变化）
--    TEXT     -> VARCHAR(n)        （**参与索引/唯一键的文本列必须是有界
--                                    VARCHAR**，MySQL 对 TEXT 建索引要写前缀
--                                    长度，容易漏；这里按列语义给了宽度）
--             -> TEXT / LONGTEXT   （正文类、以及 *_json 整块载荷）
--    PRAGMA   -> 删除              （InnoDB 外键默认开启）
--
--  注意：本文件的列顺序、默认值、外键级联行为都与 SQLite 版一致，
--        应用层代码换库后不需要调整。
-- ============================================================================

"""

HEADER_PG = """\
-- ============================================================================
--  《战姬天下》(canon) 服务端数据库结构  v1 —— PostgreSQL 版
-- ============================================================================
--  本文件由 `server/schema.sql`（SQLite 版）自动转换而来，**表/列/索引/视图
--  与 SQLite 版一一对应**，语义等价。改动请改 SQLite 版后重新生成。
--
--  要求：PostgreSQL 12 及以上（JSONB、BIGSERIAL 都是老特性，实际 9.4+ 即可）
--
--  与 SQLite 版的类型映射
--  ----------------------
--    INTEGER  -> BIGINT            （统一用 BIGINT：时间戳列不受 2038 限制）
--    INTEGER PRIMARY KEY AUTOINCREMENT
--             -> BIGSERIAL PRIMARY KEY
--    REAL     -> DOUBLE PRECISION
--    BOOLEAN  -> BOOLEAN           （SQLite 本来就用 INTEGER 0/1，没有语义变化）
--    TEXT     -> TEXT              （PG 的 TEXT 可以带默认值，也能直接建索引，
--                                    所以不需要像 MySQL 那样裁成 VARCHAR）
--    *_json / 默认值为 '{}' '[]' 的列
--             -> JSONB             （默认值写成 '{}'::jsonb；JSONB 会做合法性
--                                    校验，写入非法 JSON 会直接报错，是好事）
--    PRAGMA   -> 删除
--
--  注意：本文件的列顺序、默认值、外键级联行为都与 SQLite 版一致，
--        应用层代码换库后不需要调整。
-- ============================================================================

"""


def main():
    if not os.path.exists(SRC):
        die('找不到 %s' % SRC)
    sql = open(SRC, encoding='utf-8').read()

    cols = split_columns(sql)
    print('解析到 %d 个列定义' % len(cols))
    if '--list-columns' in sys.argv:
        names = sorted({c for _t, c, _ty in cols})
        print('%d 个不同列名：' % len(names))
        for i in range(0, len(names), 8):
            print('  ' + '  '.join(names[i:i + 8]))
        return
    m_hits, p_hits = check_reserved(cols)
    print('MySQL 保留字列名（需加反引号）: %s' % (m_hits or '无'))
    print('PG   保留字列名（需加双引号）: %s' % (p_hits or '无'))

    my = to_mysql(sql, set(m_hits))
    pg = to_pg(sql, set(p_hits))

    # 去掉 SQLite 版原来的文件头（到 PRAGMA 前一行），换成方言头
    def strip_old_header(text):
        lines = text.split('\n')
        for i, l in enumerate(lines):
            if l.strip().upper().startswith('PRAGMA') or 'MySQL 无需 PRAGMA' in l \
                    or 'PG 无需 PRAGMA' in l:
                return '\n'.join(lines[i:])
        return text

    my = HEADER_MYSQL + strip_old_header(my)
    pg = HEADER_PG + strip_old_header(pg)

    my_path = os.path.join(ROOT, 'server', 'schema_mysql.sql')
    pg_path = os.path.join(ROOT, 'server', 'schema_pg.sql')
    open(my_path, 'w', encoding='utf-8', newline='\n').write(my)
    open(pg_path, 'w', encoding='utf-8', newline='\n').write(pg)
    print('已写出 %s' % my_path)
    print('已写出 %s' % pg_path)


if __name__ == '__main__':
    main()
