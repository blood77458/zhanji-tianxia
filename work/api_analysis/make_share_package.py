#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成对外分享包：清理后的两份文档 + 三套 SQL，打成一个 zip。

用法:
    python work/api_analysis/make_share_package.py

清理原则
--------
分享对象的工程结构与本仓库不同，所以凡是**只描述本仓库实现**的内容一律去掉：

  * 「服务端实现 ✅ canon_server.py / features.py」这类逐接口实现状态
  * §4.1 总表的「服务端」列
  * 「客户端接口 vs 服务端覆盖对照」整节、「建议补齐顺序」
  * 从 `user_state.json` 迁移的整节（迁移脚本、渐进迁移策略）
  * 分析工具路径、复现命令、冒烟测试产物、代码目录树

保留下来的全部是**从 APK 逆向出来的、与实现无关的客观事实**：
三通道协议、编码管线、363 个接口的参数与响应字段、内嵌 `<protocol>` DSL、
错误码表、踩坑清单、表结构设计。

每处改动都用 `repl()` 做**精确匹配 + 出现次数断言**，匹配不到就报错退出，
避免文档一改、清理脚本静默漏删。
"""
import os
import re
import shutil
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
DIST = os.path.join(ROOT, 'dist')
PKG = 'zjt_canon_server_pack'

ERRORS = []


def repl(text, old, new, count=1, label=''):
    """精确替换并断言出现次数。"""
    n = text.count(old)
    if n != count:
        ERRORS.append('%s: 期望 %d 处，实际 %d 处 -> %r'
                      % (label or 'repl', count, n, old[:70]))
        return text
    return text.replace(old, new, count)


def drop_block(text, start_marker, end_marker, label=''):
    """删掉 [start_marker, end_marker) 之间的内容（保留 end_marker）。"""
    i = text.find(start_marker)
    if i < 0:
        ERRORS.append('%s: 找不到起始标记 %r' % (label, start_marker[:60]))
        return text
    j = text.find(end_marker, i)
    if j < 0:
        ERRORS.append('%s: 找不到结束标记 %r' % (label, end_marker[:60]))
        return text
    return text[:i] + text[j:]


# ===========================================================================
#  API.md
# ===========================================================================
def clean_api(text):
    # --- 文件头：去掉本仓库工具路径 ---
    text = repl(
        text,
        '> **自动生成**：`work/api_analysis/` 下的静态分析脚本。'
        '机器可读版本见 `api_endpoints.json` / `api_endpoints.csv`',
        '> **生成方式**：对解密后的 Lua 源码做静态分析 —— 请求参数取自实际调用点，'
        '响应字段由 `event.data.X` 引用点反推',
        label='API 文件头')

    # --- §0 快捷表：删掉「服务端还差哪些接口」一行 ---
    text = repl(
        text,
        '| 知道服务端还差哪些接口 | §7 覆盖对照 |\n', '',
        label='§0 快捷表')

    # --- §0 平台说明：去掉「自建服务端」这个指代本仓库的说法 ---
    text = repl(
        text,
        '> 即可切到官方账号通道，全部落到自建服务端。',
        '> 即可切到官方账号通道 —— 本包默认那条百度 SDK 通道已经连不上了，'
        '不改的话客户端走不到自己的服务端。',
        label='§0 平台说明')

    # --- §0 目录：重排编号 ---
    text = repl(
        text,
        '| §7 | 客户端接口 vs 自建服务端覆盖对照 + 补齐优先级 |\n'
        '| §8 | 137 条业务错误码 |\n'
        '| §9 | 踩坑清单 |\n'
        '| §10 | 附录：死代码、工具链、复现命令 |',
        '| §7 | 137 条业务错误码 |\n'
        '| §8 | 踩坑清单 |\n'
        '| §9 | 附录：死代码与统计口径 |',
        label='§0 目录')

    # --- §2.7：删掉「现自建服务端未实现该路由」 ---
    text = repl(text, '> ⚠️ 现自建服务端**未实现该路由**（落到 404）。\n\n', '',
                label='§2.7 备注')

    # --- §4 引言：删掉「服务端」列说明 ---
    text = repl(text, '> 「服务端」列 = 现自建服务端 `server/*.py` 是否有对应分支。\n', '',
                label='§4 引言')

    # --- §4.1 表格：删掉最后一列「服务端」 ---
    i = text.find('### 4.1 按功能域总表')
    j = text.find('\n## 5. ', i)
    if i < 0 or j < 0:
        ERRORS.append('§4.1 区域定位失败')
    else:
        seg = text[i:j]
        seg = seg.replace('| 响应字段（客户端读取）| 服务端 |',
                          '| 响应字段（客户端读取）|')
        seg = seg.replace('|---|---|---|---|---|', '|---|---|---|---|')
        # 数据行去掉末尾的 ✅ / ❌ 单元
        seg, n = re.subn(r'\| (?:✅|❌) \|\s*$', '|', seg, flags=re.M)
        seg = re.sub(r'\| (?:✅|❌) \|(\s*)$', r'|\1', seg, flags=re.M)
        text = text[:i] + seg + text[j:]
        print('    §4.1 去掉 %d 个「服务端」单元' % n)

    # --- §5：删掉逐接口的「服务端实现」行 ---
    text, n = re.subn(r'^\| 服务端实现 \|.*\|\s*\n', '', text, flags=re.M)
    print('    §5 去掉 %d 行「服务端实现」' % n)

    # --- 删掉整个 §7 ---
    text = drop_block(text, '## 7. 客户端接口 vs 服务端实现 覆盖对照',
                      '## 8. 业务错误码表', label='§7 整节')

    # --- §9.3 排查手段：删掉 rpc_payloads.jsonl 那条 ---
    text = repl(
        text,
        '- 自建服务端会把未识别请求写进 `server/rpc_payloads.jsonl`，'
        '这是继续补端点的抓手。\n', '',
        label='§9.3 排查手段')

    # --- 删掉 §10.3 分析工具与产物 ---
    text = drop_block(text, '### 10.3 分析工具与产物', '### 10.4 统计口径',
                      label='§10.3')

    # --- §10.4 统计口径：去掉本仓库专属表述 ---
    text = repl(
        text,
        '| APK 内 Lua 文件 | 1088 | `assets/src/**`，与本仓库旧版 `work/luasrc` '
        '相比有 21 个文件被补丁改动 |',
        '| APK 内 Lua 文件 | 1088 | `assets/src/**` |',
        label='§10.4 统计口径')
    text = repl(
        text,
        '> `ARCHITECTURE.md` 里写的「386 个具名 RPC 端点」统计口径略宽'
        '（把 `METHOD_*` 常量表与部分别名也计入了）。\n'
        '> 以本文档的 363 个**实际会发出的 method** 为准来补服务端，不会有遗漏。',
        '> 统计口径取「**实际会发出的 method**」：只算有调用点的，'
        '不算只定义未使用的 endpoint（见 §9.2）。',
        label='§10.4 口径说明')

    # --- 章节重编号 8/9/10 -> 7/8/9 ---
    for old, new in (
            ('## 8. 业务错误码表', '## 7. 业务错误码表'),
            ('## 9. 踩坑清单', '## 8. 踩坑清单'),
            ('### 9.1 协议层', '### 8.1 协议层'),
            ('### 9.2 响应数据层', '### 8.2 响应数据层'),
            ('### 9.3 排查手段', '### 8.3 排查手段'),
            ('## 10. 附录', '## 9. 附录'),
            ('### 10.1 被引用但未定义为请求类的名字', '### 9.1 被引用但未定义为请求类的名字'),
            ('### 10.2 客户端定义了但从未被调用的 endpoint',
             '### 9.2 客户端定义了但从未被调用的 endpoint'),
            ('### 10.4 统计口径', '### 9.3 统计口径'),
            ('### 10.5 免责', '### 9.4 免责'),
            ('+ §9 踩坑清单', '+ §8 踩坑清单'),
            ('见 §10.2', '见 §9.2'),
            ('见 §10.1，死代码', '见 §9.1，死代码'),
    ):
        text = repl(text, old, new, label='重编号 %r' % old[:30])

    return text


# ===========================================================================
#  SERVER_DATA_MODEL.md
# ===========================================================================
def clean_model(text):
    # --- 文件头 ---
    text = drop_block(text, '> 输入：', '\n---\n\n## 0. 一句话总结', label='model 文件头')
    text = repl(
        text,
        '\n---\n\n## 0. 一句话总结',
        '\n> **依据**：`API.md` —— 从 `zjt_pack_enablefix_signed.apk` 逆向出的 '
        '363 个接口\n'
        '> （每个接口的请求参数 + 客户端实际读取的响应字段）。\n'
        '>\n'
        '> **配套 DDL**（三份表 / 列 / 索引 / 视图完全一致）：\n'
        '> - `schema.sql` —— SQLite 版（基准，本文件的表结构以它为准）\n'
        '> - `schema_mysql.sql` —— MySQL 8.0.13+ 版\n'
        '> - `schema_pg.sql` —— PostgreSQL 版\n'
        '\n---\n\n## 0. 一句话总结',
        label='model 文件头替换')

    # --- §0：去掉「从 user_state.json 迁移」的叙述 ---
    text = repl(
        text,
        '现在服务端把整个账号塞进一个 `user_state.json`，问题是：跨玩家操作'
        '（军团、好友、排行、红包）根本没有落脚点，而且每次保存要重写全量。'
        '这套设计把它拆成 **88 张表 / 637 列 / 32 个索引 / 3 个视图**，'
        '同时用一个**组装层（assembler）**保证客户端拿到的东西和现在一模一样'
        '——所以可以**一个接口一个接口地迁移**，不用一次性重写。\n'
        '\n'
        '设计已经跑通验证：`server/schema.sql` 能建库，`server/assembler.py` '
        '能无条件拼出客户端要的全部 `gameInit` 顶层 key，'
        '`work/api_analysis/smoke_assemble.py` 是那个证明。',
        '这套设计把整个账号拆成 **88 张表 / 638 列 / 32 个索引 / 3 个视图**，'
        '再用一个**组装层（assembler）**保证拼出来的 JSON 与客户端期望完全一致。\n'
        '\n'
        '拆分动机：跨玩家操作（军团、好友、排行、红包）需要真正的落脚点；'
        '整块读写账号存档在多线程下既慢又容易丢更新。',
        label='§0 总结')

    # --- 表清单引言 ---
    text = repl(text, '完整 DDL 见 `server/schema.sql`', '完整 DDL 见 `schema.sql`',
                label='表清单引言')

    # --- §4.11 去掉「现有服务端只实现了 1 个」 ---
    text = repl(
        text,
        '客户端在这块有 **69 个接口**（不是 52），而现有服务端只实现了 1 个'
        '（`getUserUnionInfo` → 只回 `{hasUnion:False}`）。这是整个协议里最大的空洞。',
        '客户端在这块有 **69 个接口**（不是 52），是整份协议里最大的一块。',
        label='§4.11 引言')

    # --- 删掉 struct_union.md 引用 ---
    text = re.sub(
        r'> 字段级细节见 `work/api_analysis/struct_union\.md`[^\n]*\n',
        '', text)

    # --- §4.14 去掉对本仓库落盘文件的引用 ---
    text = repl(
        text,
        '> `unknown_rpc` 是替代现在 `rpc_payloads.jsonl` 的正式版本 —— 继续补端点时的抓手。',
        '> `unknown_rpc` 用来落盘未识别的 method —— 补端点时按它排序即可知道缺哪些。',
        label='§4.14 unknown_rpc 说明')

    # --- §5 组装层：去掉 repo 内模块路径 ---
    text = repl(
        text,
        '这是整套设计的**关键接缝**。建议单独一个模块 `server/assembler.py`，职责是：',
        '这是整套设计的**关键接缝**。职责单一：把数据库行翻译成客户端契约 JSON。',
        label='§5 组装层引言')

    # --- §6 表映射：去掉本仓库产物路径 ---
    text = repl(
        text,
        '完整的 363 行映射见：\n'
        '\n'
        '- `work/api_analysis/table_map.csv` —— 可直接用 Excel/表格筛选\n'
        '- `work/api_analysis/table_map.json` —— 程序读取\n'
        '\n'
        '字段：`method / 操作(读|写) / 分类 / 涉及表 / 请求参数 / 响应字段 / 服务端已实现`\n',
        '下面按「接口涉及哪些表」给出热度分布。每个接口的请求参数与响应字段见 '
        '`API.md` §4 / §5。\n',
        label='§6 表映射引言')

    # --- 删掉 §7 迁移（整节）---
    text = drop_block(text, '## 7. 从 `user_state.json` 迁移', '## 8. 移植到 MySQL',
                      label='§7 迁移')

    # --- §8「移植到 MySQL」换成多方言说明 ---
    text = drop_block(text, '## 8. 移植到 MySQL', '## 9. 代码结构（含已落地的原型）',
                      label='§8 MySQL 移植')
    text = repl(
        text,
        '## 9. 代码结构（含已落地的原型）',
        '## 7. 多数据库方言\n'
        '\n'
        '`schema.sql` 是 SQLite 版，也是**基准版**；另两份由它自动转换而来，\n'
        '表 / 列 / 索引 / 视图一一对应，应用层代码换库后不需要改行为。\n'
        '\n'
        '| 方言 | 文件 | 最低版本 | 主要差异 |\n'
        '|---|---|---|---|\n'
        '| SQLite | `schema.sql` | 3.x（建议开 WAL）| 基准。`INTEGER PRIMARY KEY AUTOINCREMENT`、`TEXT`、`REAL` |\n'
        '| MySQL | `schema_mysql.sql` | **8.0.13+** | `BIGINT AUTO_INCREMENT`、文本列按语义裁成 `VARCHAR(n)`、`*_json` 用 `LONGTEXT`、InnoDB/utf8mb4 |\n'
        '| PostgreSQL | `schema_pg.sql` | 9.6+ | `BIGSERIAL`、`DOUBLE PRECISION`、`*_json` 用 `JSONB` |\n'
        '\n'
        '**为什么 MySQL 必须 8.0.13+**：`TEXT` / `LONGTEXT` / `JSON` 列要带默认值，\n'
        '而 MySQL 只允许把它们写成**表达式**形式 `DEFAULT (\'{}\')`，这个语法从\n'
        '8.0.13 起才支持。若必须跑 5.7，把所有 `DEFAULT (\'...\')` 去掉、改由应用层\n'
        '补值即可，其余不变。\n'
        '\n'
        '**为什么 MySQL 的文本列不是 `TEXT`**：MySQL 对 `TEXT` 建索引必须写前缀\n'
        '长度（`col(64)`），很容易漏；而且 `TEXT` 不能直接写 `DEFAULT \'\'`。\n'
        '所以参与索引 / 唯一键 / 主键的文本列一律用有界 `VARCHAR(n)`，\n'
        '只有正文类和 `*_json` 整块载荷才用 `TEXT` / `LONGTEXT`。\n'
        'PostgreSQL 的 `TEXT` 没有这两个限制，所以原样保留。\n'
        '\n'
        '**三点跨库都要守住的约定**（与具体数据库无关）：\n'
        '\n'
        '1. **时间一律 Unix 秒整数**。不要改成 `DATETIME` / `TIMESTAMP` ——\n'
        '   客户端全程拿秒做算术，中间多一层转换只会引入时区 bug。\n'
        '2. **布尔用整数 0/1**。客户端的 `sharkUser*` 里这类字段本来就按数字读。\n'
        '3. **热行要用原子自增**。`player`（货币）和 `player_daily_counter` 是并发\n'
        '   写入热点，用 `UPDATE ... SET value = value + ?` 而不是「先读再写」；\n'
        '   多进程部署下不要指望进程内锁。\n'
        '\n'
        '---\n'
        '\n'
        '## 8. 实现注意事项（参考）\n'
        '\n'
        '下面是一种跑通过的分层方式，**不是必须的** —— 表结构本身不依赖任何\n'
        '特定代码组织。列出来只是说明这套 DDL 的字段划分是按下面的职责切的。\n',
        label='§7 多方言')

    # --- §9 代码结构：删掉仓库目录树与实现状态 ---
    text = drop_block(text, '这次不只给了 DDL，还写了**可运行的组装层原型**来证明设计成立：',
                      '分层规则：', label='§9 目录树')

    text = repl(
        text,
        '分层规则：\n'
        '\n'
        '- `repository` 只认数据库，**不知道客户端字段名**\n'
        '- `assembler` 只认客户端契约，**不写 SQL**（只接收 repo 传进来的行）\n'
        '- `canon_server` 的 handler 负责「读 repo → 喂 assembler → 编码」\n'
        '\n'
        '这样补新接口时，改动只会落在 `repository`（加一个查询）和 `assembler`'
        '（加一个字段），不会波及协议层。\n',
        '分层规则：\n'
        '\n'
        '- **数据访问层**只认数据库，**不知道客户端字段名**\n'
        '- **组装层**只认客户端契约，**不写 SQL**（只接收数据访问层传进来的行）\n'
        '- **路由层**负责「读数据 → 喂组装层 → 编码」\n'
        '\n'
        '这样加新接口时，改动只会落在数据访问层（加一个查询）和组装层\n'
        '（加一个字段），不会波及协议层。\n'
        '\n'
        '几条来自实测的注意事项：\n'
        '\n'
        '| 事项 | 为什么需要 |\n'
        '|---|---|\n'
        '| WAL + `busy_timeout` | 多线程共用一个库时，没有 WAL 会频繁 `database is locked` |\n'
        '| 真事务 | 「扣道具 + 发卡」这类复合操作必须原子 |\n'
        '| 原子取号 | `id_alloc` 用 `UPDATE ... RETURNING`，不要在应用里维护散落的游标 |\n'
        '| 数量归零即删行 | 客户端 `sharkProps[]` 里的 0 或负数会让数量显示异常 |\n'
        '\n'
        '---\n',
        label='§8 分层规则')

    # --- 删掉 §9.1 冒烟测试（整节）---
    text = drop_block(text, '### 9.1 设计验证：冒烟测试', '## 10. 这份设计没解决的事',
                      label='§9.1 冒烟测试')

    # --- §10 收尾：只留与实现无关的设计边界 ---
    text = repl(
        text,
        '## 10. 这份设计没解决的事\n'
        '\n'
        '诚实说明边界：\n'
        '\n'
        '1. **数值平衡完全没碰。** 掉落表、抽卡概率、成长曲线 —— 现在服务端大量用 '
        '`random` 硬编码。表结构给了 `gacha_log` / `reward_log` 做审计，但配置数据'
        '本身要另做（原厂的配置在 `work/luasrc/canon/configs/` 里，是 Lua 表，'
        '可以直接加载）。\n'
        '2. **`assembler.py` 只覆盖了 `gameInit`。** 363 个接口里还有一大批响应需要'
        '各自的组装函数（邮件列表、好友列表、军团各种 wrapper、战报…）。这些的字段'
        '契约在 `struct_mail_social.md` / `struct_union.md` 里已经逐条列出，'
        '但代码还没写。\n'
        '3. **`repository/` 层还没写。** `db.py` 提供了地基，但按域的数据访问函数'
        '（`asset_repo` / `guild_repo` …）是空的。\n'
        '4. **`rank_board` 的刷新策略**没定义。排行榜是定时全量重算还是增量维护，'
        '取决于玩家人数 —— 私服场景（个位数在线）建议直接查询时现算，'
        '`rank_board` 先当缓存用。\n'
        '5. **没有分库分表**。单 server_id 的场景下 88 张表跑在 SQLite 一个文件里'
        '绰绰有余。\n'
        '6. **`data_json` 里的字段契约没有强制约束。** `player_activity` / '
        '`player_daily` 这些 JSON 列靠约定，写错了不会报错。建议配一份 '
        '`activity_keys.py` 常量表 + 每个活动一个 `build_xxx_activity()` 组装函数，'
        '把契约收口。',
        '## 9. 这份设计没解决的事\n'
        '\n'
        '诚实说明边界，免得按图施工时踩空：\n'
        '\n'
        '1. **数值平衡不在表结构范围内。** 掉落表、抽卡概率、成长曲线都是「数据」'
        '而不是「结构」。表里留了 `gacha_log` / `reward_log` 做审计，但配置本身要'
        '另行准备 —— 原厂的策划表是 Lua 表字面量，可以直接解析后灌库。\n'
        '2. **JSON 列里的字段契约没有数据库层面的强制约束。** `player_activity` / '
        '`player_daily` 这类列靠约定，写错了不会报错。建议在应用层用一张常量表 + '
        '每个活动一个组装函数把契约收口，不要散在各处手拼。\n'
        '3. **排行榜的刷新策略没有定。** 定时全量重算还是增量维护取决于在线人数；'
        '小规模场景直接查询时现算即可，`rank_board` 先当缓存用。\n'
        '4. **没有分库分表。** 单 `server_id` 的规模下，88 张表放在一个库里绰绰有余。\n'
        '5. **跨服 / 军团战的战报只存了结构。** 战报内容的生成规则（谁打谁、胜负'
        '判定、积分结算）属于玩法逻辑，不在表设计范围内。',
        label='§10 设计边界')

    # --- 收尾：去掉文件头多余空行 ---
    text = repl(text, '服务端数据模型设计\n\n\n>', '服务端数据模型设计\n\n>',
                label='标题空行')

    return text


# ===========================================================================
PACKAGE_README = """\
# 《战姬天下》(canon) 服务端资料包

从 `zjt_pack_enablefix_signed.apk`（包名 `com.happyelements.canon.baiduDK`，
版本 11.0.61）逆向整理出来的**客户端协议**与**服务端表结构**。
这份资料只描述客户端「要什么」，不绑定任何具体的服务端实现。

## 包里有什么

| 文件 | 内容 |
|---|---|
| `API.md` | 接口文档。三条通信通道（REST / `/protocol` RPC / TCP）、AMF3 编码管线、363 个 RPC 接口的参数与响应字段、客户端内嵌的 `<protocol>` DSL、137 条业务错误码、踩坑清单 |
| `SERVER_DATA_MODEL.md` | 表结构设计说明。88 张表按域分组，每张表解决什么问题、字段怎么切、组装层怎么把行拼回客户端 JSON |
| `schema.sql` | **SQLite 版 DDL**（基准版，可直接执行）|
| `schema_mysql.sql` | MySQL 版 DDL（需要 8.0.13+）|
| `schema_pg.sql` | PostgreSQL 版 DDL |

三份 DDL 的表 / 列 / 索引 / 视图**一一对应**，只是方言不同：
88 张表、638 列、32 个索引、3 个视图。换库不需要改应用层行为。

## 建议的阅读顺序

1. `API.md` §0.1 —— 30 秒看懂一次完整登录会依次打哪些接口
2. `API.md` §1 —— 通信架构与编码管线。**这一节不理解，后面全白搭**
3. `API.md` §1.6 + §8 —— 类型与空值陷阱。客户端的崩溃几乎都出在这里
4. `API.md` §4 / §5 —— 接口总表与逐个详情
5. `SERVER_DATA_MODEL.md` —— 表结构怎么设计
6. `schema.sql` —— 落地的 DDL

## 上库

```bash
# SQLite
sqlite3 canon.db < schema.sql

# MySQL（8.0.13+）
mysql -u root -p canon < schema_mysql.sql

# PostgreSQL
psql -d canon -f schema_pg.sql
```

## 几个容易踩的点

- **客户端对任何未捕获的 Lua 错误直接 SIGKILL**，表现为「闪退」。所以
  「某个接口一调就崩」=「响应里少了客户端要读的字段」，不是网络问题。
- **不要下发空表 `{}`。** Lua 里空表为真，会顶掉客户端本地的默认值，
  下一行做 nil 运算就崩。要么给全字段，要么整个 key 不下发。
- **数字型 ID 必须是字符串**（`uid` 等），传 number 会触发 luajava
  签名不匹配 → SIGKILL。反过来 `level` / `exp` / 时间戳必须是数字。
- **响应方向的异或是 `0x71`，请求方向是 `0xC3`**，两者是反的。写反了
  客户端报 `zlib checksum failed`。

## 免责

《战姬天下》著作权属乐元素（Happy Elements）。本资料仅为个人学习与软件
保存目的所做的协议分析，不含任何原厂代码或资源，不得用于公开运营或盈利。
"""


def main():
    dist = DIST
    outdir = os.path.join(dist, PKG)
    if os.path.exists(outdir):
        shutil.rmtree(outdir)
    os.makedirs(outdir)

    print('清理 API.md ...')
    api = open(os.path.join(ROOT, 'API.md'), encoding='utf-8').read()
    api2 = clean_api(api)
    print('  %d 行 -> %d 行' % (api.count('\n') + 1, api2.count('\n') + 1))

    print('清理 SERVER_DATA_MODEL.md ...')
    mdl = open(os.path.join(ROOT, 'SERVER_DATA_MODEL.md'), encoding='utf-8').read()
    mdl2 = clean_model(mdl)
    print('  %d 行 -> %d 行' % (mdl.count('\n') + 1, mdl2.count('\n') + 1))

    if ERRORS:
        print()
        print('!! 清理脚本有 %d 处未命中，已中止（不改动任何文件）:' % len(ERRORS))
        for e in ERRORS:
            print('   - %s' % e)
        shutil.rmtree(outdir)
        sys.exit(1)

    open(os.path.join(outdir, 'API.md'), 'w',
         encoding='utf-8', newline='\n').write(api2)
    open(os.path.join(outdir, 'SERVER_DATA_MODEL.md'), 'w',
         encoding='utf-8', newline='\n').write(mdl2)
    open(os.path.join(outdir, 'README.md'), 'w',
         encoding='utf-8', newline='\n').write(PACKAGE_README)

    for fn in ('schema.sql', 'schema_mysql.sql', 'schema_pg.sql'):
        src = os.path.join(ROOT, 'server', fn)
        if not os.path.exists(src):
            print('!! 缺少 %s' % src)
            sys.exit(1)
        shutil.copyfile(src, os.path.join(outdir, fn))
        print('  打包 %s (%d KB)' % (fn, os.path.getsize(src) // 1024))

    zip_path = os.path.join(dist, PKG + '.zip')
    if os.path.exists(zip_path):
        os.remove(zip_path)
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for fn in ('README.md', 'API.md', 'SERVER_DATA_MODEL.md',
                   'schema.sql', 'schema_mysql.sql', 'schema_pg.sql'):
            z.write(os.path.join(outdir, fn), PKG + '/' + fn)

    print()
    print('=' * 70)
    print('压缩包: %s  (%d KB)' % (zip_path, os.path.getsize(zip_path) // 1024))
    with zipfile.ZipFile(zip_path) as z:
        for i in z.infolist():
            print('   %-34s %8d B' % (i.filename, i.file_size))
    print('=' * 70)


if __name__ == '__main__':
    main()
