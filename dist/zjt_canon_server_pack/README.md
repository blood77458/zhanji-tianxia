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
