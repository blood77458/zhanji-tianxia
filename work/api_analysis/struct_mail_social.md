# 邮件系统 / 好友社交系统 —— 客户端实际读取的数据结构

> 只读分析，来源：`work/apk_luasrc/`（已解密客户端 Lua）。
> 判定原则：以客户端**怎么用**为准。
> - `ipairs` / `#` / `table.insert` / `table.sort` / `table.union` → **数组**
> - `pairs` 遍历或 `xxx.field` 取字段 → **字典 / 对象**
> - `tonumber` / 算术 / `<` `>` 比较 → **数字**
> - `string.gsub` / `string.sub` / `..` 拼接 / `:split(",")` → **字符串**
>
> 结论里的 `文件:行号` 一律是**客户端源码行**。带哈希的文件名太长，故在上方别名表中给出完整路径，正文用 `[别名]:行号` 引用。

---

## 0. 别名表（正文引用的全部文件）

| 别名 | 完整路径（相对 `work/apk_luasrc/`） |
|---|---|
| `[ES]` | `canon/scene/EmailScene.58cd4eda836fed4be0df417f93268b18.lua` |
| `[EVP]` | `canon/panel/EmailViewPanel.f64f248e49ef9f397566ec1a76ca3fff.lua` |
| `[EWP]` | `canon/panel/EmailWritePanel.76d107e2e263a9ebc3349837d1d0bce4.lua` |
| `[EBP]` | `canon/panel/EmailBlankPanel.ccf91c5a661c32394e65001476b71c25.lua` |
| `[GETMAIL]` | `canon/request/GetUserEmailsRequest.64a20b0bf0291baf37be3fedd4671cc1.lua` |
| `[SYSMETA]` | `canon/request/GetSysEmailMetaRequest.f07274ac7f058b39c24e207ed6ea7299.lua` |
| `[BDEL-SYS]` | `canon/request/EmailBatchDeleteSysEmailRequest.6b71d5f5d890abf40c4003981cc25caf.lua` |
| `[BDEL-REW]` | `canon/request/EmailBatchDeleteRewardEmailRequest.229b21af2621c5c6b8209fc52127ba77.lua` |
| `[BDEL-NOTICE]` | `canon/request/EmailBatchDeleteSysNoticeRequest.c682843eacde88db7d78d1a1c01b8c69.lua` |
| `[BDEL-USER]` | `canon/request/EmailBatchDeleteUserEmailRequest.b6821f4d16813ea12e5525965d051deb.lua` |
| `[GAIN-REW]` | `canon/request/EmailGainRewardEmailRewardRequest.8932a63d616d1bbaf20b989115c51b66.lua` |
| `[READ-REW]` | `canon/request/EmailReadRewardEmailRequest.3e8751ec864433b3c82e55737bf2edb1.lua` |
| `[GAIN-SYS]` | `canon/request/GainSysEmailRewardRequest.fa76c2d15e5761d1d3f9b0f5d40642bd.lua` |
| `[DEL-SYS]` | `canon/request/DeleteSysEmailRequest.cfefd2e19b667e06efc8536f39ed507b.lua` |
| `[DEL-NOTICE]` | `canon/request/DeleteSysNoticeRequest.c72e544041ba3df94e415d9a0c6805f8.lua` |
| `[DEL-USER]` | `canon/request/DeleteUserEmailRequest.d7d3343ea2d533bb40df64fc4a494dde.lua` |
| `[READ-SYS]` | `canon/request/ReadSysEmailRequest.1813d0375f3a3bfefe4a58e9a458a30d.lua` |
| `[READ-NOTICE]` | `canon/request/ReadSysNoticeRequest.bb40eff7560470387b253d00b30bf351.lua` |
| `[READ-USER]` | `canon/request/ReadUserEmailRequest.c29f595f70598bdcdb8a8c97e8ed1d2a.lua` |
| `[SEND-USER]` | `canon/request/SendUserEmailRequest.ca14272652dd872e54af3eceb7f85ffb.lua` |
| `[EMLCHG]` | `canon/request/EmailChangeRequest.cd5e5bcb1682f35271b1af8795811a53.lua` |
| `[METH]` | `canon/request/CommMethodConstants.83adcc191aae8f68e0e071d608d23829.lua` |
| `[FS]` | `canon/scene/FriendScene.d9382f2c9ba24da1392d1ebfa14a3c60.lua` |
| `[MFP]` | `canon/panel/MyFriendsPanel.da9e823d0cf8f53743c633e44f183dd7.lua` |
| `[FFP]` | `canon/panel/FindFriendsPanel.4fa3f8f211a249546d0d3d184d47e859.lua` |
| `[IRP]` | `canon/panel/InviteReceivedPanel.8578b0c1cd6cd07f5aaad5b894afad2d.lua` |
| `[ISP]` | `canon/panel/InviteSentPanel.66a3b721fbb3baa4fe01832a5ac23cc5.lua` |
| `[UDP]` | `canon/panel/UserDetailPanel.7356d71edec07969bdb4e96038aa3b73.lua` |
| `[AUDP]` | `canon/panel/AcrossUserDetailPanel.62232f9a8310916ec6901c738c948e47.lua` |
| `[UMLP]` | `canon/panel/UnionMemberListPanel.10242232c2c3b559c33fc3cada107c0f.lua` |
| `[FM]` | `canon/models/FriendManager.49a05ef6f3772be022539531e617d540.lua` |
| `[CHFL]` | `canon/request/ChallengeFriendListRequest.19d3b17f8a9747d208da25639bbe9a4b.lua` |
| `[PRAISE]` | `canon/layer/Activity_PraiseLayer.ec347692341630f2ec03b9931dfba8b4.lua` |
| `[INVCODE]` | `canon/layer/Activity_InvitationCodeLayer.3a5f0e8fce4d2a41078f06939168dd1b.lua` |
| `[REDPKT]` | `canon/scene/RedPacketDispatchScene.f172404187be6c39abef7be5cc57815e.lua` |
| `[REDPANEL]` | `canon/panel/RedPacketAccpterListPanel.a4473cfe5cbae0ab4c0d5f34897cd1f6.lua` |
| `[APS]` | `canon/scene/ActivityPanelScene.71655c90fed48aa85faa1fdac3b266de.lua` |
| `[BSCENE]` | `canon/scene/BattleScene.0700806167ed9176ab8f0cb94fae9b2f.lua` |
| `[GRIP]` | `canon/panel/GetRewardInfoPanel.3aa703435bd5656193b5bac264647faf.lua` |
| `[RWD]` | `canon/models/RewardManager.1f0c5b53068af9d80b738fb0a097aba4.lua` |
| `[UTILS]` | `hecore/utils.b490359ad65a71f75f0cbd6f15ca3094.lua` |
| `[CUTILS]` | `canon/canonUtils.f9d1d84bf834a74bd572aa49174eb583.lua` |
| `[TIME]` | `canon/utils/TimeUtil.a4a63f3046f0b46e7618ca1ca243424b.lua` |
| `[VCU]` | `canon/utils/ViewControlUtil.8a77779026c0f7ac3945afdacf464cc6.lua` |

**唯一消费者说明**：整份 `getUserEmails` 的响应被原样存进 `DataManager.GetUserEmailsData`（`[ES]:486`），之后**只有 `[ES]` 与 `[EVP]` 两个文件**读它（全仓库 `DataManager.GetUserEmailsData` 共 47 处命中，全部落在这两个文件）。所以这两个文件里的字段访问就是客户端期望的**全部**字段路径。

---

# 一、邮件系统

## 1.1 `getUserEmails` 顶层响应

- 接口名：`getUserEmails`（`[GETMAIL]:10`）
- 请求参数：**空表** `{}`（`[ES]:545` 传 `{}`；`[GETMAIL]:9` 的 `params` 被完全忽略）
- 调用点：全客户端**只有一处** —— `[ES]:545`
- 顶层结构：**字典（对象）**，5 个键

| 字段名 | 类型 | 客户端用途 | 证据 |
|---|---|---|---|
| `sysEmails` | **数组** | 系统邮件 + 奖励邮件（客户端把两者合并后回写此键） | `[ES]:126` `ipairs(...sysEmails)`；`[ES]:182`；`[ES]:489` `or {}`；`[ES]:510` 回写；`[ES]:616`/`830` |
| `rewardEmails` | **数组** | 奖励邮件原始列表，用于并入 `sysEmails` | `[ES]:495` `or {}` → `[ES]:496` `ipairs(rewardEmails)`；`[ES]:500` `table.union(sysEmails, rewardEmails)` |
| `sysNotices` | **数组** | 系统通知（tab2） | `[ES]:151`、`[ES]:205`、`[ES]:455`、`[ES]:534`、`[ES]:662`、`[ES]:832` |
| `userEmails` | **数组** | 玩家邮件（tab3） | `[ES]:157`、`[ES]:213`、`[ES]:455`、`[ES]:536`、`[ES]:731`、`[ES]:834` |
| `sysEmailMeta` | **数组** | 系统邮件元数据表（按 `id` 关联 `sysEmail.sysEmailMetaId`） | `[ES]:132` `ipairs(...sysEmailMeta)`；`[ES]:515`；`[ES]:626`；`[EVP]:73`；`[EVP]:206` |

### 关键语义：`sysEmails` 是客户端自己合并出来的

```
[ES]:489  local sysEmails  = DataManager.GetUserEmailsData.sysEmails or {}
[ES]:491  for k, mailData in ipairs(sysEmails)  do mailData.mailType = 2 end  -- MAIL_TYPE_SYSEMAIL
[ES]:495  local rewardEmails = DataManager.GetUserEmailsData.rewardEmails or {}
[ES]:496  for k, mailData in ipairs(rewardEmails) do mailData.mailType = 4 end -- MAIL_TYPE_REWARD
[ES]:500  local tab1List = table.union(sysEmails, rewardEmails)
[ES]:507  table.sort(tab1List, sortFunc)
[ES]:510  DataManager.GetUserEmailsData.sysEmails = tab1List   -- 覆盖回写
```

`table.union` 是纯数组拼接（`[UTILS]:92-97`，用 `ipairs` + `table.insert`）。
**因此服务端必须返回「两个独立数组」，不要把奖励邮件预先塞进 `sysEmails`** —— 否则会被重复合并一次。

- `mailType` 是**客户端自己打的时间标记**（`[ES]:492`/`[ES]:497`），服务端**不需要也不应该**返回。
- 值：`MAIL_TYPE_USER=1`、`MAIL_TYPE_SYSEMAIL=2`、`MAIL_TYPE_SYSNOTICE=3`、`MAIL_TYPE_REWARD=4`（`[ES]:55-58`）。

### 缺失会怎样崩

| 情况 | 后果 | 证据链 |
|---|---|---|
| 顶层键缺失（如无 `sysNotices`） | **不崩**，全部访问点都有 `or {}` 兜底（`[ES]:455/489/495/534/536`） | — |
| 这些键不是**数组**而是 AMF 字典（字符串键） | **不崩，但永远显示空列表**：`ipairs` 遍历 0 次，`#list == 0`；后续 `list[mailIndex]`（数字下标）取到 `nil`，而取值处都有 `if mailData == nil then return` 保护（`[ES]:618/664`） | `[ES]:126`、`[ES]:616-620` |
| `sysEmails` / `rewardEmails` 元素缺 **`receiveSeconds`** | **崩**：`table.sort` 的比较函数做 `a.receiveSeconds < b.receiveSeconds`（`[ES]:504`）→ `attempt to compare nil` | `[ES]:502-507` |
| `sysEmails` 元素既无 `sysEmailMetaId` 又无 `rewardEmailId` | **不崩**，但批量删除时 `table.insert(sysList, nil)` 不写入，列表项难以删除 | `[ES]:186`、`[ES]:189` |

---

## 1.2 `sysEmails` 数组元素（`mailType == MAIL_TYPE_SYSEMAIL` 时）

服务端返回的 `sysEmails` 元素 = 普通系统邮件。

| 字段名 | 类型 | 客户端用途 | 证据 |
|---|---|---|---|
| `sysEmailMetaId` | 数字/不透明 ID | 与 `sysEmailMeta[].id` 做 `==` 匹配；作为删除/已读/领奖的 ID | `[ES]:129`、`[ES]:133` `meta.id == v.sysEmailMetaId`、`[ES]:186`、`[ES]:516`、`[ES]:627`、`[EVP]:68`、`[EVP]:74`、`[EVP]:207` |
| `read` | 布尔 | 未读红点；`not v.read` 计数 | `[ES]:461`、`[ES]:648`、`[ES]:720`、`[ES]:775` |
| `gainedReward` | 布尔 | 是否已领奖，决定「领奖」按钮是否显示 | `[ES]:131/144`、`[EVP]:72/82/134/225` |
| `receiveSeconds` | **数字（必填）** | 排序键 + 列表时间显示 | `[ES]:504`（`<` 比较）、`[ES]:645` `TimeUtil.formatDate(mailData.receiveSeconds)` |
| `mailType` | 数字 | **客户端写入**，非服务端字段 | `[ES]:492` |

`title` / `content` **不从这里取** —— 普通系统邮件的标题与正文来自 `sysEmailMeta`（见 1.5）。

### 缺失会怎样崩

- `receiveSeconds` 缺失 → **崩**（`[ES]:504` 比较 nil；`[ES]:645` → `TimeUtil.formatDate(nil)` → `[TIME]:268` `timeNum + TimeZone*3600` 对 nil 做算术 → 崩）。
- `read` / `gainedReward` 缺失 → **不崩**（`not nil` 为真），只是邮件永远显示为未读 / 未领奖。
- `sysEmailMetaId` 缺失 → **不崩**，但该邮件在列表里被 `return` 跳过（`[ES]:632-634`），表现为**列表项空白/少一条**。

---

## 1.3 `sysEmails` 数组元素（`mailType == MAIL_TYPE_REWARD` 时，即来自 `rewardEmails`）

| 字段名 | 类型 | 客户端用途 | 证据 |
|---|---|---|---|
| `rewardEmailId` | 数字/不透明 ID | 删除 / 已读 / 领奖的 ID；也作 `rewardEmailIds` 数组元素 | `[ES]:189`、`[ES]:782`、`[EVP]:85`、`[EVP]:96`、`[EVP]:174` |
| `title` | **字符串** | 列表标题 | `[ES]:639`、`[EVP]:220` |
| `content` | **字符串（必填）** | 列表摘要 + 详情正文 | `[ES]:526` `string.gsub(aSysEmail.content, ...)`、`[ES]:640`、`[EVP]:221` |
| `read` | 布尔 | 未读红点 | `[ES]:461`、`[ES]:648` |
| `gainedReward` | 布尔 | 领奖按钮 | `[ES]:144`、`[EVP]:82/134/225` |
| `receiveSeconds` | **数字（必填）** | 排序 + 时间显示 | `[ES]:504`、`[ES]:645` |
| `mailType` | 数字 | **客户端写入** | `[ES]:497` |

### 缺失会怎样崩

- **`content` 缺失 → 必崩**：`[ES]:526` `aSysEmail.content = string.gsub(aSysEmail.content, "^%s*(.-)%s*$", "%1")` → `bad argument #1 to 'gsub' (string expected, got nil)`。
- `receiveSeconds` 缺失 → 崩（同上）。
- `title` 缺失 → **不崩**（`setNodeText(node, nil)` 走 C++ `setString(nil)`，行为不确定，但多数机型只是空文本）。
- `rewardEmailId` 缺失 → **不崩**，但删除时会把 `nil` 塞进 `rewardEmailIds`，批量删除请求数组里出现空洞。

---

## 1.4 `sysNotices` 数组元素（系统通知）

| 字段名 | 类型 | 客户端用途 | 证据 |
|---|---|---|---|
| `sysNoticeId` | 数字/不透明 ID | 删除 / 已读 ID；也作 `sysNoticeIds` 元素 | `[ES]:152`、`[ES]:207`、`[ES]:663`、`[ES]:787-788`、`[EVP]:108/112` |
| `read` | 布尔 | 未读红点 | `[ES]:461`、`[ES]:720`、`[ES]:787` |
| `receiveTime` | **数字（必填）** | 列表时间显示 | `[ES]:719` `EmailScene.getEmailTimeText(mailData.receiveTime)` |
| `detail` | **字符串（JSON 文本，必填）** | `table.deserialize` 解成字典再取字段 | `[ES]:668`、`[EVP]:252` |
| `type` | **数字** | 决定文案分支（1..12） | `[ES]:671` 起 `if mailData.type == 1 ... elseif ... == 12`；`[EVP]:254` 起同样分支 |

`type` 取值与 `detail` 内层字段（客户端**只在对应 `type` 分支里**读这些字段）：

| `type` | `detail` 内层字段 | 证据 |
|---|---|---|
| 1 | `nickName` | `[ES]:673`、`[EVP]:256` |
| 2 | `nickName`, `fragmentId` | `[ES]:675-679`、`[EVP]:258-262` |
| 3 | `nickName` | `[ES]:683-684` |
| 4 | `title`, `content` | `[ES]:686-687`、`[EVP]:269-270` |
| 5 | `nickName`, `loseScore`（`tonumber` 后 `> 0` 比较） | `[ES]:689-693`、`[EVP]:272-276` |
| 6 | `title`（`tonumber`）, `nickname`, `unionName` | `[ES]:698-699` |
| 7 | `nickName` | `[ES]:702` |
| 8 | `oldNickName`, `year`, `month`, `day`, `newNickName` | `[ES]:705`、`[EVP]:288` |
| 9 | 同 8 | `[ES]:708` |
| 11 | `points`, `propId` | `[ES]:711-713` |
| 12 | `name` | `[ES]:716` |

注意 `type==5` 用 `loseScore`，`type==6` 用 `nickname`（全小写）而 1/2/3/5/7/8 用 `nickName`（驼峰）—— **大小写不统一，是客户端历史遗留，必须逐字照抄**。

### 缺失会怎样崩

- **`detail` 缺失或不是合法 JSON → 必崩**：`table.deserialize` = `cjson.decode(str)`（`[UTILS]:322-325`），传 `nil` / 坏字符串直接抛错（`[ES]:668`、`[EVP]:252`）。
- **`receiveTime` 缺失 → 必崩**：`getEmailTimeText` 做 `TimeUtil.getServerTimeSeconds() - time`（`[ES]:841`）→ 算术遇 nil。
- **`type` 缺失 → 不崩但正文为空**：所有 `elseif` 都不命中，`mailTitle`/`mailText` 保持 `""`。
- `sysNoticeId` 缺失 → 不崩，该条不可删/不可标记已读（`[ES]:206`、`[ES]:787` 有 nil 保护）。
- `read` 缺失 → 不崩，永远显示未读。

---

## 1.5 `userEmails` 数组元素（玩家邮件）

| 字段名 | 类型 | 客户端用途 | 证据 |
|---|---|---|---|
| `userEmailId` | 数字/不透明 ID | 删除 / 已读 ID；也作 `userEmailIds` 元素 | `[ES]:158`、`[ES]:215`、`[ES]:732`、`[ES]:795-796`、`[EVP]:120/124` |
| `senderName` | **字符串** | 列表左侧标题 + 详情标题 | `[ES]:734` `setNodeText(textTitle, mailData.senderName)`、`[EVP]:316` |
| `senderUid` | 数字/不透明 UID | 「回复」时的收件人 | `[EVP]:182` `EmailWritePanel:create(..., mailData.senderName, mailData.senderUid, true, ...)` → 最终作为 `sendUserEmail` 的 `receiveUid`（`[EWP]:69`） |
| `content` | **字符串** | 列表摘要 + 详情正文 | `[ES]:735`、`[EVP]:317` |
| `sendTime` | **数字（必填）** | 列表/详情时间 | `[ES]:737`、`[EVP]:318` `getEmailTimeText(mailData.sendTime)` |
| `read` | 布尔 | 未读红点 | `[ES]:461`、`[ES]:738`、`[ES]:795` |

### 缺失会怎样崩

- **`sendTime` 缺失 → 必崩**（`getEmailTimeText` 算术 nil，`[ES]:841`）。
- **`senderName` 缺失 → 高风险崩**：`[ES]:736` 紧接 `textTitle:getTextureRect()`，且 `setNodeText` → `node:setString(nil)` / `node:setText(nil)`（`[CUTILS]:426-436`）把 nil 传进 C++ 绑定，多数环境直接报错。
- `content` 缺失 → 高风险（`[ES]:735` → `setNodeText` → `setString(nil)`）。
- `userEmailId` / `read` 缺失 → 不崩。
- **整条 `userEmails[index]` 为 nil → 崩**：`[ES]:732-734` 取值后**没有** nil 检查就直接 `mailData.senderName`。（对比 `[ES]:618/664` 的 tab1/tab2 有 `if mailData == nil then return`。）因此 `userEmails` 数组**不能有空洞**。

---

## 1.6 `sysEmailMeta` 数组元素

**它是什么**：不是客户端配置表（不在 `MetaManager` / `canon/configs/` 里），而是**由 `getUserEmails` 响应一并下发的「系统邮件模板表」**，键是 `id == sysEmails[].sysEmailMetaId`。作用是给系统邮件提供标题正文和「是否含奖励」标记。

**谁在读**：只有 `[ES]` 与 `[EVP]`。全仓库 `GetSysEmailMetaRequest` / `getSysEmailMeta` **零调用点**（`[SYSMETA]:1-24` 是死代码；`RequestNotifyEnum.GetSysEmailMetaSucceed` 定义于 `canon/request/BaseRequest.1e6ab6fe54c3c6917e66a2c39c4fc43a.lua:90`，无人监听）。**所以 `sysEmailMeta` 必须搭 `getUserEmails` 一起返回。**

| 字段名 | 类型 | 客户端用途 | 证据 |
|---|---|---|---|
| `id` | 数字/不透明 ID | 与 `sysEmails[].sysEmailMetaId` 做 `==` 匹配 | `[ES]:133`、`[ES]:516`、`[ES]:627`、`[EVP]:74`、`[EVP]:207` |
| `containReward` | 布尔 | 决定删除时是否弹「删了就领不到奖励」二次确认 | `[ES]:134`、`[EVP]:75`、`[EVP]:217` → `[EVP]:225` |
| `titleText` | **字符串** | 系统邮件标题 | `[ES]:635`、`[EVP]:215` |
| `contentText` | **字符串（必填）** | 系统邮件正文 | `[ES]:522` `string.gsub(mailMeta.contentText, ...)`、`[ES]:636`、`[EVP]:216` |

### 缺失会怎样崩

- **`contentText` 缺失 → 必崩**（前提是该 `id` 被某条 `sysEmail` 命中）：`[ES]:522` 的 `string.gsub(nil, ...)`。
- `id` 与 `sysEmailMetaId` 对不上 → **不崩**：`mailMeta == nil` → `[ES]:632-634` `return`，该邮件变成**列表里的空白行**；详情面板则 `[EVP]:212-214` 直接 `return`，弹出**空白面板**。
- `sysEmailMeta` 不是数组（例如 AMF 空对象/字典） → **不崩**：`ipairs` 0 次，效果等于上一条（所有系统邮件都找不到 meta）。
  > 注意：当前服务端实现把 `sysEmailMeta` 填成 `{}`（`server/features.py:943`），配合空 `sysEmails` 是安全的；**一旦开始下发 `sysEmails`，`sysEmailMeta` 必须同步下发**，否则全是空白行。

---

## 1.7 邮件操作接口：请求参数与返回字段

所有请求都走 `BaseRequest`，`params` 就是 AMF 字典。**"返回字段"只列客户端真的读了的字段**；其余字段客户端丢弃。

| 接口 (endpoint) | 请求参数 | 客户端读取的返回字段 | 证据 |
|---|---|---|---|
| `readSysEmail` | `{sysEmailMetaId = <id>}` | **无**（响应体不读） | `[ES]:776`、`[READ-SYS]:10/15` |
| `readSysNotice` | `{sysNoticeId = <id>}` | **无** | `[ES]:788`、`[READ-NOTICE]:10` |
| `readUserEmail` | `{userEmailId = <id>}` | **无** | `[ES]:796`、`[READ-USER]:10` |
| `readRewardEmail` | `{rewardEmailId = <id>}`（`sendRequest` 直接传标量，内部包成该键） | **无** | `[ES]:782`、`[READ-REW]:30/42` |
| `deleteSysEmail` | `{sysEmailMetaId = <id>}` | **无** | `[EVP]:91`、`[DEL-SYS]:10` |
| `deleteSysNotice` | `{sysNoticeId = <id>}` | **无** | `[EVP]:112`、`[DEL-NOTICE]:10` |
| `deleteUserEmail` | `{userEmailId = <id>}` | **无** | `[EVP]:124`、`[DEL-USER]:10` |
| `gainSysEmailReward` | `{sysEmailId = <id>}` ⚠️ **键名是 `sysEmailId`，但值是 `sysEmailMetaId`** | `rewards`（数组） | 请求：`[EVP]:168`；返回：`[EVP]:146` `GetRewardInfoPanel:create(..., e.data.rewards, ...)`、`[EVP]:148` `RewardManager:getReward(e.data.rewards)` |
| `gainRewardEmailReward` | `{rewardEmailId = <id>}` | `rewards`（数组） | `[EVP]:174`、`[GAIN-REW]:42`；回调 `[EVP]:137-149` |
| `batchDeleteSysEmail` | `{sysEmailIds = <数组>}` | **无** | `[ES]:196/199`、`[BDEL-SYS]:42` |
| `batchDeleteRewardEmail` | `{rewardEmailIds = <数组>}` | **无** | `[ES]:197/201`、`[EVP]:96`、`[BDEL-REW]:42` |
| `batchDeleteSysNotice` | `{sysNoticeIds = <数组>}` | **无** | `[ES]:210`、`[BDEL-NOTICE]:42` |
| `batchDeleteUserEmail` | `{userEmailIds = <数组>}` | **无** | `[ES]:218`、`[BDEL-USER]:42` |
| `sendUserEmail` | `{content = <字符串>, receiveUid = <uid>}` | `rewards`（**可选**，数组） | 请求：`[EWP]:69`；返回：`[EWP]:50` `if e.data.rewards then` → `[EWP]:51-58` |
| `modifyEmail` | `{newEmail = <字符串>}` | **无** | `canon/scene/ConfigScene.a838f4ae7ba059f0ca29a55967c0aea6.lua:308`、`[EMLCHG]:10` |

### ⚠️ 两个必须注意的坑

1. **`gainSysEmailReward` 的键名与值不一致**：客户端发 `sysEmailId`，塞进去的却是 `mailData.sysEmailMetaId`（`[EVP]:168`）。服务端要么把该键当「系统邮件模板 id」处理，要么兼容两种语义。
2. **`rewards` 是硬需求**（`gainSysEmailReward` / `gainRewardEmailReward` / `sendUserEmail` 有则读、`challengeFriendList` 无脑读）：
   - 成功回调里无条件构造 `GetRewardInfoPanel:create(container, e.data.rewards, cb)`（`[EVP]:146`）；
   - `GetRewardInfoPanel:create` 把 `rewardInfo` 存下来（`[GRIP]:33`），`initLayer` 里做 `for k,v in pairs(self.rewardInfo)`（`[GRIP]:380`）与 `#data`（`[GRIP]:42`）；
   - **`rewards` 缺失/为 nil → `pairs(nil)` / `#nil` 直接抛错 → 崩**。
   - 奖励元素形状（`[GRIP]:383-399`、`[CHFL]:97-104`）：`itemType`(数字)、`amount`(数字)、`metaId`(数字，type 5/6/7 需要)、`level`(数字，type 5 需要)、`id`、`exp`。
   - 对比：`sendUserEmail` 的 `rewards` 有 `if e.data.rewards then` 保护（`[EWP]:50`），缺失只是不弹奖励提示，**不崩**。

### 邮件错误码（客户端会特判的成功/失败语义）

`[EVP]:151-158` 对这 4 个错误码逐条弹不同文案，服务端做失败返回时应当复用：

| retCode | 客户端提示 | 证据 |
|---|---|---|
| `712605` | 此邮件不包含奖励 | `[EVP]:151` |
| `712606` | 奖励已被领取 | `[EVP]:153` |
| `712607` | 邮件已过期 | `[EVP]:155` |
| `712608` | 邮件已被删除 | `[EVP]:157` |
| `710516` | 背包已满（弹扩容面板） | `[EVP]:159-161`、`[GAIN-REW]:60` |

另外 `[BDEL-*]:61` 注释里留下 `SHARK_EMAILS_IS_NULL(2601, "SharkEmails is null: {0:uid}")`，说明服务端在「邮件容器为空」时用 2601。

---

# 二、好友 / 社交系统

## 2.1 `sharkFriend` —— 好友条目通用结构（数组元素）

`getFriends` / `getReviewFriends` / `getInvitationFriends` / `getRecommendedFriends` **四个接口的元素结构是同一个**（都叫 `sharkFriends`，都被各自的 `TableViewRenderer:setData` 当作同构条目渲染）。

| 字段名 | 类型 | 客户端用途 | 证据 |
|---|---|---|---|
| `friendUid` | 数字/不透明 UID | 列表主键；按钮操作参数；一键赠礼/一键邀请的 uid 数组元素；已切磋判定 | `[MFP]:216`(经 `[FM]:34-45` `tonumber`)、`[MFP]:334`、`[MFP]:538`、`[FFP]:262`、`[FFP]:308`、`[FFP]:483`、`[IRP]:283`、`[ISP]:172`、`[UDP]:358` |
| `nickName` | 字符串 | 列表名称 | `[MFP]:189`、`[FFP]:201`、`[IRP]:190`、`[ISP]:118` |
| `level` | 数字（也可字符串） | 列表等级 | `[MFP]:193`、`[FFP]:221`、`[IRP]:194`、`[ISP]:122` |
| `mainCardMetaId` | 数字 | 头像卡 | `[MFP]:209`、`[FFP]:224`、`[IRP]:197`、`[ISP]:125` |
| `unionName` | 字符串 / nil | 军团名（有则显示） | `[MFP]:227`、`[FFP]:232`、`[ISP]:133` |
| `online` | 布尔 | 是否在线 | `[MFP]:239` |
| `lastestOfflineSeconds` | **数字** | 离线时长 | `[MFP]:241`、`[MFP]:250` |
| `giftSent` | 布尔 | 是否已送免费礼物 | `[MFP]:75`、`[MFP]:195`、`[MFP]:281`、`[MFP]:492`、`[MFP]:537` |
| `invitationSent` | 布尔 | 是否已发邀请（推荐好友列表用） | `[FFP]:71`、`[FFP]:209`、`[FFP]:216`、`[FFP]:260` |
| `friend` | 布尔 | 是否已是好友（推荐好友列表用） | `[FFP]:209`、`[FFP]:216` |

字段的**按场景子集需求**（服务端可以按列表类型精简）：

| 列表 | 渲染器 | 必需字段 |
|---|---|---|
| `getFriends` → `sharkFriends` | `[MFP]:172-265` | `friendUid`,`nickName`,`level`,`mainCardMetaId`,`giftSent`,`online`,`lastestOfflineSeconds`（`unionName` 可选） |
| `getReviewFriends` / `getInvitationFriends` → `sharkFriends` | `[IRP]:174-203` / `[ISP]:102-141` | `friendUid`,`nickName`,`level`,`mainCardMetaId`（`unionName` 可选） |
| `getRecommendedFriends` / `searchUserByNickname` → `sharkFriends` / `sharkFriendDetail` | `[FFP]:185-240` | `friendUid`,`nickName`,`level`,`mainCardMetaId`,`invitationSent`,`friend`（`unionName` 可选） |

### 缺失会怎样崩

- **`lastestOfflineSeconds` 缺失且 `online` 为假 → 必崩**：`[MFP]:239` `if not aData.online then offLineSec = TimeUtil.getServerTimeSeconds() - aData.lastestOfflineSeconds`（`[MFP]:241`）→ 算术遇 nil。
  → **只要 `online` 不是 `true`，`lastestOfflineSeconds` 就必须是数字。**
- `nickName` / `content` 之类传 `setLableText(..., nil)`（`[VCU]:169-179` → `setString(nil)`）：高风险，多数机型报错。
- `mainCardMetaId` 缺失 → **不崩**：`getHeadIconCanonCardByMetaId(nil)` → `MetaManager.card_meta[nil]` 为 nil → 返回默认卡 101022（`[CUTILS]:290-296`）。**降级为默认头像。**
- `level` 是数字还是字符串都行（走 `setString`，tolua 会自动转字符串）。
- **`friendUid` 类型不一致 → 不崩但功能静默失效**：`[MFP]:510` `if(friendId == user.friendUid)` 是**严格相等**，`friendId` 来自 `sendAllFreeGift` 返回的 `friendUids` 数组（`[MFP]:503`、`[MFP]:508`），`user.friendUid` 来自 `sharkFriends`。两者必须**同为数字或同为字符串**，否则「已赠送」状态刷不出来。
  （对比 `FriendManager.containUid` 用了 `tonumber` 双转（`[FM]:39`），容错更好。）

---

## 2.2 好友列表类接口

| 接口 | 请求参数 | 返回结构 | 类型 | 证据 |
|---|---|---|---|---|
| `getFriends` | 无（`new(nil, ...)`） | `sharkFriends`, `receivedEnergy` | 数组 + 数字 | `[FS]:156-158`；`sharkFriends`：`[FS]:142`、`[FS]:367-368`；`receivedEnergy`：`[FS]:143` `or 0`、`[MFP]:56` `> 0` |
| `getReviewFriends` | 无 | `sharkFriends`（待审核 = 别人发给我的邀请） | 数组 | `[FS]:160-162`、`[FS]:147` |
| `getInvitationFriends` | 无 | `sharkFriends`（我已发出、待对方审核） | 数组 | `[FS]:164-166`、`[FS]:151` |
| `getRecommendedFriends` | 无 | `sharkFriends`（推荐好友） | 数组 | `[FFP]:437-439`、`[FFP]:425`、`[FFP]:573`；「换一批」再调一次 `[FFP]:583` |

`receivedEnergy`：`getFriends` 的 `receivedEnergy` 是**可领取的友情点总数**（`FriendScene:setReceivedEnergy` → `MyFriendsPanel:refreshRecivedEnergy`，`[MFP]:56`），`acceptAllFreeGift` 之后客户端会做 `receivedEnergy - gainedEnergy`（`[MFP]:459`）。

### 缺失会怎样崩

- `sharkFriends` 缺失 → **不崩**（全部有 `or {}`：`[FS]:142/147/151`、`[FFP]:425/573`、`[UDP]:344`）。
- `receivedEnergy` 缺失 → **不崩**（`[FS]:143` `or 0`；`[MFP]:56` 是 `if(receivedEnergy and receivedEnergy > 0)`）。
- 但 `sharkFriends` 元素缺 `lastestOfflineSeconds`（且 `online` 非真）→ **崩**（见 2.1）。

---

## 2.3 `sharkFriendDetail` —— 玩家详情结构（字典）

来源：`getFriendDetail` 与 `searchUserByNickname`。**两个接口共用同一个字段名，就是同一套结构**（`searchUserByNickname` 的返回值会被直接 `table.insert` 进好友列表当好友条目用，`[FFP]:534`）。

| 字段名 | 类型 | 客户端用途 | 证据 |
|---|---|---|---|
| `friendUid` | 数字/UID | 标题、发送邮件收件人、私聊目标、跨服服号后 4 位 | `[UDP]:109`、`[UDP]:250`、`[AUDP]:59`、`[FFP]:533` |
| `nickName` | 字符串 | 昵称 | `[UDP]:136`、`[AUDP]:50` |
| `level` | 数字 | 等级 | `[UDP]:135`、`[AUDP]:52` |
| `mainCardMetaId` | 数字 | 头像卡 | `[UDP]:128`、`[AUDP]:68` |
| `fightCapacity` | 数字 | 战力 | `[UDP]:142`、`[UDP]:150`、`[AUDP]:56` |
| `friendNum` | **数字（必填）** | 「好友 n/m」的分子 | `[UDP]:118` `self.userDetail.friendNum .. "/" .. self.userDetail.friendNumMax` |
| `friendNumMax` | **数字（必填）** | 分母 | `[UDP]:118` |
| `arenaRank` | **数字（必填）** | 竞技场排名，`> 0` 判定 | `[UDP]:147` |
| `unionName` | 字符串 / nil | 军团名 | `[UDP]:153-155` |
| `friend` | 布尔 | 分支：已是好友 → 显示切磋/删除 | `[UDP]:223`、`[UDP]:233`、`[UDP]:601`、`[UDP]:634`、`[UDP]:661`、`[FFP]:209`、`[UMLP]:460` |
| `invitationSent` | 布尔 | 分支：已发申请（按钮置灰） | `[UDP]:225`、`[UDP]:233`、`[UDP]:605`、`[FFP]:216`、`[UMLP]:461` |
| `invitationReceived` | 布尔 | 分支：对方邀请了我 → 显示接受/拒绝 | `[UDP]:603`、`[UDP]:647`、`[UDP]:661`、`[UDP]:668` |

### 缺失会怎样崩

- **`friendNum` 或 `friendNumMax` 缺失 → 必崩**：`[UDP]:118` 的 `..` 拼接会把 nil 拼进去 → `attempt to concatenate a nil value`。
- **`arenaRank` 缺失 → 必崩**：`[UDP]:147` `self.userDetail.arenaRank > 0` → `attempt to compare nil with number`。
- `nickName` / `level` / `fightCapacity` / `mainCardMetaId` 缺失 → 见 2.1（`mainCardMetaId` 降级、文本类高风险）。
- `friendUid` 缺失 → **不崩**（`[AUDP]:59` 走 `tostring(nil)`）；但 `[UDP]:250` 会传 nil 给私聊回调。
- `friend` / `invitationSent` / `invitationReceived` 全缺失 → **不崩**：落到 `[UDP]:607-608` 的 `initDefaultOp()` 分支。
- **`getFriendDetail` 整体返回 nil 的 `sharkFriendDetail` → 崩**：`[UDP]:657` `self.userDetail = data.data.sharkFriendDetail` 之后**无 nil 检查**，`[UDP]:661` 立刻 `self.userDetail.friend`。
  - 对比 `searchUserByNickname`：`[FFP]:531-540` 有 `if(sharkFriendDetail) then ... else 显示「无此玩家」`，`[UMLP]:459-466` 同样有保护 → **这两处 nil 是安全的，`getFriendDetail` 不是**。

---

## 2.4 邀请 / 免费礼物 / 切磋 操作接口

| 接口 (endpoint) | 请求参数 | 客户端读取的返回字段 | 证据 |
|---|---|---|---|
| `sendInvitation` | `{friendUid = <uid>}` | **无**（成功即把本地 `invitationSent` 置 true） | 请求：`[FFP]:308`、`[UDP]:72`；成功：`[FFP]:257-277` |
| `sendAllInvitations` | `{friendUids = <数组>}` | `friendUids`（数组，**实际成功的 uid 列表**） | 请求：`[FFP]:514`；返回：`[FFP]:488-499` `local sentSuccUids = data.data.friendUids` + `#sentSuccUids` + `ipairs` |
| `cancelInvitation` | `{friendUid = <uid>}` | **无** | `[ISP]:152`、`[UDP]:549`；成功 `[ISP]:142-146` |
| `acceptInvitation` | `{friendUid = <uid>}` | `acceptedFriend`（**单个好友条目**） | 请求：`[IRP]:242`、`[UDP]:454`；返回：`[IRP]:216-217` `local aData = data.data.acceptedFriend` → `friendPanel:addTableData(aData)` |
| `acceptAllInvitations` | 无 | `acceptedFriends`（好友条目数组）、`reviewingFriends`（剩余待审核条目数组） | `[IRP]:329-345`：`data.data.acceptedFriends` + `#` + `ipairs`；`data.data.reviewingFriends` + `ipairs` |
| `refuseInvitation` | `{friendUid = <uid>}` | **无** | `[IRP]:259`、`[UDP]:477` |
| `refuseAllInvitations` | 无 | **无**（客户端直接清空本地列表） | `[IRP]:384-386`、`[IRP]:370-378` |
| `deleteFriend` | `{friendUid = <uid>}` | **无** | `[UDP]:403`；成功 `[UDP]:396-402` |
| `sendFreeGift` | `{friendUid = <uid>}` | `gainedEnergy`（数字） | 请求：`[MFP]:334`；返回：`[MFP]:301` `data.data.gainedEnergy`、`[MFP]:306` `> 0` |
| `sendAllFreeGift` | `{friendUids = <数组>}` | `friendUids`（数组）、`gainedEnergy`（数字） | 请求：`[MFP]:543`；返回：`[MFP]:503-504` `data.data.friendUids` / `data.data.gainedEnergy`，`#succUids`（`[MFP]:507`）、`ipairs`（`[MFP]:508`） |
| `acceptAllFreeGift` | 无 | `gainedEnergy`（数字） | `[MFP]:474`；返回：`[MFP]:448` `data.data.gainedEnergy`、`[MFP]:452` `> 0`、`[MFP]:459` 算术 |
| `challengeFriend` | `{friendUid = <uid>}` | **整个 `data.data` 被当作战斗负载交给 `BattleScene`** | 请求：`[UDP]:333`；使用：`[UDP]:318-320` |
| `challengeFriendList`（一键切磋） | `{friendUids = <数组>}` | `rewards`（数组） | 请求：`[UDP]:381`、`[CHFL]:37`；返回：`[CHFL]:67` `RewardManager:getReward(event.data.rewards)`、`[CHFL]:69` `pairs(event.data.rewards)`、`[CHFL]:70` `v.amount` |

### `challengeFriend` 返回字段（跨模块）

`[UDP]:318-320`：

```lua
data.data.tableContentHeight = self.FriendTableViewContentHeight   -- 客户端自己塞的
Director:sharedDirector():replaceScene(BattleScene:create(data.data, BattleBackType.kUserDetailPanel,
                                                          BattleEnterEnum.kUserDetailPanel, 1))
```

→ `data.data` 就是**战斗场景负载**，字段由 `BattleScene` 消费（`[BSCENE]:132` `scene.data = data`）。已知读取点（属战斗模块，非本文件范围）：

| 字段 | 证据 |
|---|---|
| `cardInitDatas`（数组，**必需**） | `[BSCENE]:1749` `pairs(self.data.cardInitDatas)`、`[BSCENE]:2180`、`[BSCENE]:2213` |
| `eventFlow`（数组） | `[BSCENE]:2316` `pairs(self.data.eventFlow)` |
| `win`（布尔） | `[BSCENE]:872`、`[BSCENE]:1704` |
| `qte` | `[BSCENE]:1931`、`[BSCENE]:1954` |
| `singleBattleAttName` / `singleBattleDefName`（字符串） | `[BSCENE]:1830-1831` |
| `forbidSkip` | `[BSCENE]:2467` |
| `tableContentHeight` | **客户端写入**（`[UDP]:318`），返回时由 `[BSCENE]:229-230` 读回用于恢复好友列表滚动位置 |

> ⚠️ `pairs(nil)` 会崩，所以 `challengeFriend` 至少要返回带 `cardInitDatas` 的完整战斗负载。**建议本阶段先按「返回一场真实战斗负载」或「明确失败」二选一，不要返回空 payload。**

### 缺失会怎样崩

- `sendAllInvitations.friendUids` 缺失 → **不崩**：`[FFP]:489` `if(sentSuccUids and #sentSuccUids > 0)`，只是弹「全部发送失败」（`[FFP]:507`）。
- `sendAllFreeGift.friendUids` 缺失 → **不崩**（`[MFP]:507` 同样有 nil 保护），但 `gainedEnergy` 会被当 0。
- `acceptAllInvitations.acceptedFriends` / `reviewingFriends` 缺失 → **不崩**（`[IRP]:330`、`[IRP]:341` 都有保护）。
  ⚠️ **但元素必须满足「好友条目」完整形状**：`acceptedFriend` / `acceptedFriends[]` 会被 `addTableData` 塞进 `MyFriendsPanel` 的列表（`[MFP]:390-394`），随后走**好友列表渲染器**（`[MFP]:172-265`），因此同样需要 `online` + `lastestOfflineSeconds`，否则按 2.1 的规则崩。
- `gainedEnergy` 缺失 → **不崩**（`[MFP]:306`/`[MFP]:452` 是 `> 0` 比较，但 `[MFP]:449` `RewardManager:getReward({{itemType=..., amount = gainedEnergy}})`，`[RWD]:321` 才做 `tonumber(value.amount)`；`tonumber(nil)` 返回 nil，再做 `+` 才崩）→ **属于高风险，建议始终返回数字**。
- **`challengeFriendList.rewards` 缺失 → 必崩**：`[CHFL]:69` `for k,v in pairs(event.data.rewards)` → `pairs(nil)`。（该文件 `[CHFL]:92-106` 的 `getDebugDatas()` 给出了客户端期望的元素形状：`{itemType, metaId, id, amount, level, exp}`。）
- `challengeFriend` payload 缺 `cardInitDatas` → **必崩**（`[BSCENE]:1749`）。

---

## 2.5 红包

### `distributeBonus`

- 请求参数（`[REDPKT]:292-310, 360`）：

| 参数 | 类型 | 说明 | 证据 |
|---|---|---|---|
| `accepterType` | 数字 | `self.selectID - 1`（好友=0 / 军团=1） | `[REDPKT]:293` |
| `bonusId` | 数字 | 红包道具 id | `[REDPKT]:294` |
| `accepterList` | **数组** | 每项 `{uid = <uid>, amount = <数字>}` | `[REDPKT]:295`、`[REDPKT]:304-308` |

- 返回字段：

| 字段 | 类型 | 用途 | 证据 |
|---|---|---|---|
| `usedNum` | **数字** | 扣道具数量，做 `-amount` 运算 | `[REDPKT]:321-322` |
| `accepterList` | **数组** | 传给 `RedPacketAccpterListPanel`（`#` + 遍历） | `[REDPKT]:320`、`[REDPKT]:323-324`、`[REDPANEL]:43` |

- `accepterList` 元素（`[REDPANEL]:43-58`）：

| 字段 | 类型 | 用途 | 证据 |
|---|---|---|---|
| `acceptErrorcode` | **数字 1..6** | 结果分支 | `[REDPANEL]:45/47/49/51/53/56` |
| `acceptName` | 字符串 | 玩家名，与文案拼接 | `[REDPANEL]:46/48/50/52/55/57` |
| `extend` | **字符串**，格式 `"a|b"` | 仅 `acceptErrorcode == 5` 时读，`string.split(v.extend, "|")` 后取 `num[1]`/`num[2]` 做减法 | `[REDPANEL]:54-55` |

**缺失后果**：`usedNum` 缺失 → `[REDPKT]:322` `amount = -amount` 对 nil 取负 → **崩**。`accepterList` 缺失 → `[REDPKT]:323` `#accepterList` → **崩**。

### `getBonusAccepterList`

- 请求参数：`{bonusId = <数字>}`（`[REDPKT]:350`）
- 返回字段：

| 字段 | 类型 | 用途 | 证据 |
|---|---|---|---|
| `friendList` | **数组** | 好友候选（可直接选为收红包人） | `[REDPKT]:41` `pairs(listData.friendList)`、`[REDPKT]:270` `#listData.friendList`、`[REDPKT]:396/614` |
| `unionList` | **数组** | 军团成员候选 | `[REDPKT]:62`、`[REDPKT]:281`、`[REDPKT]:398/616` |

整个 `e.data` 被直接赋给 `listData`（`[REDPKT]:341`），即响应顶层**就是** `{friendList, unionList}`。

- `friendList` 元素（`[REDPKT]:19-25, 507-568`）：

| 字段 | 类型 | 用途 | 证据 |
|---|---|---|---|
| `uid` | **数字** | 排序比较 + 提交 `accepterList.uid` | `[REDPKT]:21`、`[REDPKT]:305` |
| `lastestOfflineSeconds` | **数字** | 排序比较 | `[REDPKT]:20/23`、`[REDPKT]:545/554` |
| `acceptNum` | **数字** | 已领取数（服务端权威值） | `[REDPKT]:42`、`[REDPKT]:496`、`[REDPKT]:528`、`[REDPKT]:598` |
| `nickName` | 字符串 | 列表名 | `[REDPKT]:507` |
| `level` | 数字 | 等级 | `[REDPKT]:508` |
| `fightCapacity` | 数字 | 战力 | `[REDPKT]:509` |
| `mainCardMetaId` | 数字 | 头像 | `[REDPKT]:521` |
| `unionName` | 字符串/nil | 军团名 | `[REDPKT]:531-535` |
| `online` | 布尔 | 在线判定 | `[REDPKT]:543` |
| `dispatchedNum` | 数字 | **客户端写入**（本次分配数量，`[REDPKT]:84/88/602`） | — |
| `itemDescKey` | 数字 | **客户端写入**，来自本地配置 `red_bag.lua` 的 `redBagList[].itemDescKey`（`[REDPKT]:253-259`、`red_bag.7b847c7fbe51bbb12b39e3a2bb2ef5ee.lua:2-5`），**不是服务端字段** | — |

- `unionList` 元素（`[REDPKT]:27-37, 570-582`）：在 friendList 字段基础上换 `lastestOfflineSeconds` → **`lastestConstructDays`**，并新增 **`hisContribute`**、**`title`**：

| 字段 | 类型 | 用途 | 证据 |
|---|---|---|---|
| `lastestConstructDays` | **数字** | 排序比较 | `[REDPKT]:28/35` |
| `hisContribute` | **数字** | 排序比较 + 显示 | `[REDPKT]:29/32`、`[REDPKT]:581` |
| `title` | **数字 1..4** | 职位图标 | `[REDPKT]:572` |
| `uid` / `acceptNum` / `nickName` / `level` / `fightCapacity` / `mainCardMetaId` | 同上 | | `[REDPKT]:581`、`[REDPKT]:507-528` 同渲染器 |

**缺失后果**：
- `friendList` / `unionList` 缺失 → **崩**（`[REDPKT]:41` `pairs(nil)`、`[REDPKT]:208` `#listData.unionList`）。
- 元素缺 `uid` / `lastestOfflineSeconds`（或军团版的 `lastestConstructDays` / `hisContribute`）→ **崩**（`[REDPKT]:19-37` 的比较函数对 nil 做 `>`）。
- 元素缺 `acceptNum` → **崩**（`[REDPKT]:496`/`598` 对 nil 做减法/比较）。
- 元素缺 `online` 且缺 `lastestOfflineSeconds` → **崩**（`[REDPKT]:543-545`）。

---

## 2.6 点赞

| 接口 | 请求参数 | 客户端读取的返回字段 | 证据 |
|---|---|---|---|
| `recordPraiseId` | `{praiseId = <数字>}` | **无 —— 响应体完全不读** | 请求：`[PRAISE]:133`、`GetRecordPraiseIdRequest.2f91ff8302ed1838ed3234c39ad43360.lua:31`；回调签名 `succeedCallback(Data, event)`（同文件 `:23`），消费方只用**第一个参数**（自己传进去的 `clickContext`）：`[PRAISE]:94` `function requestPraiseSucceed(data, response)` → `[PRAISE]:101` `table.insert(activity.recordPraiseIds, data)` |
| `gainPraiseReward` | `{praiseId = <数字>}` | `rewards`（数组） | 请求：`[PRAISE]:189`；返回：`[PRAISE]:171` `RewardManager:getReward(response.data.rewards)`、`[PRAISE]:174` `rewardList = response.data.rewards` |

> 这是个**反直觉但重要**的结论：`recordPraiseId` 的成功回调里那个 `data` 是**回声**（客户端自己传的 praiseId），不是服务端字段。返回 `{}` 即可。

**缺失后果**：`gainPraiseReward` 的 `rewards` 缺失 → `RewardReviewPanel:create(..., {rewardList = nil, ...})`（`[PRAISE]:174`），后续按 `[GRIP]:380` 的同一模式 `pairs(nil)` → **崩**。

---

## 2.7 邀请码

| 接口 | 请求参数 | 客户端读取的返回字段 | 证据 |
|---|---|---|---|
| `getInvitationInfo` | `{deviceId = <字符串>}` | `sharkAccountInvitation`（**字典**）、`deviceHasInvited`（**布尔**） | 请求：`[APS]:600-602`；返回：`[APS]:586` `event.data.sharkAccountInvitation`、`[APS]:589` 填入 `extraArgs[1]`、`[APS]:591` `event.data.deviceHasInvited` 填入 `extraArgs[2]` |
| `gainInviteReward` | **无**（`sendRequest(nil, ...)`） | `rewards`（数组） | 请求：`[INVCODE]:195`；返回：`[INVCODE]:162`、`[INVCODE]:166` `rewardList = response.data.rewards` |
| `gainInvitedReward` | `{invitationCode = <字符串>, deviceId = <字符串>}`（`deviceId` 来自 `getDeviceId()`） | `rewards`（数组） | 请求：`[INVCODE]:258-259`；返回：`[INVCODE]:209`、`[INVCODE]:211` |

### `sharkAccountInvitation` 结构（字典）

由 `getInvitationInfo` 返回，随后作为 `extraArgs[1]` 传进 `Activity_InvitationCodeLayer`：

| 字段 | 类型 | 用途 | 证据 |
|---|---|---|---|
| `invitePlayerNum` | **数字** | 已邀请人数（`> 30` 截断为 30；参与减法与比较） | `[INVCODE]:104-109`、`[INVCODE]:201`、`[INVCODE]:287-297` |
| `gainedInviteRewardNum` | **数字** | 已领奖人数 | `[INVCODE]:108`、`[INVCODE]:201`、`[INVCODE]:287` |
| `hasInvited` | **布尔** | 我是否已被别人邀请（决定提交框是否显示） | `[INVCODE]:266`、`[INVCODE]:288/300` |
| `deviceId` | 字符串 | 客户端在默认值里预留（`[APS]:585`），`[INVCODE]` 未直接读 | `[APS]:585` |

**缺失后果**：
- `sharkAccountInvitation` 缺失 → **不崩**：`[APS]:586-590` 会造一个默认字典 `{invitePlayerNum=0, gainedInviteRewardNum=0, hasInvited=false, deviceId=""}`。
- 但若 `sharkAccountInvitation` **存在却缺 `invitePlayerNum` / `gainedInviteRewardNum`** → **崩**：`[INVCODE]:108` `(invitePlayers - self.extraArgs[1].gainedInviteRewardNum)` 与 `[INVCODE]:201` 减法 → 算术 nil。
- `deviceHasInvited` 缺失 → **不崩**（`[INVCODE]:266` 是 `if ... or self.extraArgs[2]` 真值判断）。
- `gainInviteReward` / `gainInvitedReward` 的 `rewards` 缺失 → **崩**（同 2.6，`[INVCODE]:166`/`[INVCODE]:211` → `RewardReviewPanel` 内部按 `pairs`/`#` 消费）。

其他被客户端特判的邀请码错误码（服务端可复用）：`716810`（device 已被邀请）、`716811`（账号已被邀请）、`716813`（邀请码非法），见 `[INVCODE]:235-240`。

---

# 三、未能确认的部分

| 项 | 状态 | 说明 |
|---|---|---|
| `sysEmailMeta` 是否**独立**接口下发 | **否**（已确认） | `getSysEmailMeta` 端点存在（`[SYSMETA]:10`）但**零调用点**；实际只从 `getUserEmails` 响应里读（`[ES]:515`、`[EVP]:206`）。 |
| `sysEmails[]` / `userEmails[]` / `sysNotices[]` 的 **id 具体数值类型**（int vs long vs string） | **未能确认** | 客户端把它们当作不透明值：只做「相等比较/原样回传」。`sysEmailMetaId` 与 `sysEmailMeta[].id` **必须同类型**；`rewardEmailId` / `sysNoticeId` / `userEmailId` / `friendUid` 类型不限，但**同一字段在「列表」与「返回的 uid 数组」里必须一致**（见 `[MFP]:510`）。 |
| `challengeFriend` 返回的战斗负载**完整** schema | **未能确认（超出本次范围）** | 只列出 `BattleScene` 明确读取的字段（见 2.4）。完整定义属战斗模块，建议单独分析。 |
| `distributeBonus` 成功后 `e.data` 除 `accepterList` / `usedNum` 外的字段 | **未能确认** | `[REDPKT]:338` 只 `print(table.tostring(e.data))` 调试输出，无实际读取。 |
| `getInvitationInfo` 的 `sharkAccountInvitation.deviceId` 是否真被读 | **未能确认** | 只在客户端默认值里出现（`[APS]:585`），`[INVCODE]` 内无直接读取。 |
| `getFriends` 是否还返回别的字段（如 `friendNum`） | **否**（已确认） | `friendNum` / `maxFriendNum` 来自 `g_homeInfo`（`getHomeInfo`）与 `MetaManager.user_level`（`[MFP]:370-371`、`[MFP]:424-425`），**不走 `getFriends`**。 |
| `searchUserByNickname` 除 `sharkFriendDetail` 外的字段 | **未见读取** | `[FFP]:531`、`[UMLP]:459` 只读 `data.data.sharkFriendDetail`。 |

---

# 四、服务端建表建议

> 前提：客户端崩溃点几乎都是「JSON/AMF 里少一个数字字段」或「该数组的却是字典」。所以**下表「必须独立成列」的字段 = 缺了就崩的字段**。

## 4.1 值得单独建列的字段（缺失或类型错 → 客户端崩 / 功能静默失效）

### 邮件

| 表 | 列 | 类型 | 理由 |
|---|---|---|---|
| `user_email`（系统邮件实例） | `id` (PK), `uid`(收件人), **`sys_email_meta_id`**, **`receive_seconds`**, `read`, `gained_reward`, `deleted` | INT/BIGINT, BIGINT | `receive_seconds` 是排序键（`[ES]:504`）与时间显示（`[ES]:645`），**必须非空** |
| `user_email`（奖励邮件实例） | 同上 + **`reward_email_id`**, `title`, **`content`** | TEXT for content | `content` 走 `string.gsub`（`[ES]:526`），**必须非空** |
| `user_email`（系统通知实例） | `id`(PK), `uid`, **`sys_notice_id`**, **`receive_time`**, `read`, **`notice_type`**, **`detail_json`** | INT, TEXT | `detail_json` 必须能 `cjson.decode`（`[ES]:668`）；`receive_time` 必须数字 |
| `user_email`（玩家邮件实例） | `id`(PK), `uid`, **`user_email_id`**, `sender_uid`, **`sender_name`**, **`content`**, **`send_time`**, `read` | BIGINT, TEXT, INT | `send_time` 必须数字（`[ES]:737`）；`user_emails` **数组不能有空洞**（`[ES]:732-734` 无 nil 检查） |
| `sys_email_meta`（模板表） | **`id`** (PK), **`title_text`**, **`content_text`**, **`contain_reward`** | INT, TEXT, BOOL | 随 `getUserEmails` 一起下发；`content_text` 必须非空 |
| 备注 | 以上三类邮件若同表存放，用 `mail_kind` 区分即可 —— 客户端仅通过「键名是否存在」区分（`sysEmailMetaId` vs `rewardEmailId`），**不需要服务端下发 `mailType`** | | `[ES]:492/497` |

### 社交

| 表 | 列 | 类型 | 理由 |
|---|---|---|---|
| `friend_relation` | `uid`, `friend_uid`, `created_at`, **`gift_sent`(按天), `invitation_sent`, `invitation_received`** | BIGINT,BOOL | 三个布尔决定按钮分支 |
| `friend_relation`（列表渲染用的快照） | **`nick_name`, `level`, `main_card_meta_id`, `union_name`, `online`, `lastest_offline_seconds`** | TEXT,INT,INT,TEXT,BOOL,INT | `online=false` 时 **`lastest_offline_seconds` 必须非空**（`[MFP]:241`） |
| `friend_invitation` | `id`, `from_uid`, `to_uid`, `status`, `created_at` | | 三种列表都靠这条表过滤 |
| `red_bag_accepter`（红包已领数量） | **`bonus_id`, `uid`, `accept_num`** | INT | `accept_num` 参与 `itemDescKey - acceptNum` 减法（`[REDPKT]:496/528/598`） |
| 备注 | 红包候选人的 `itemDescKey` **不要建列**：它是客户端本地配置（`[REDPKT]:253-259`） | | |

## 4.2 可以整块当 JSON 存

| 字段 | 存放建议 | 理由 |
|---|---|---|
| `sysNotices[].detail` | **JSON 字符串列**（`detail` 本身就是字符串） | 客户端 `table.deserialize(mailData.detail)`（`[ES]:668`），11 种 `type` 的内层键完全不同（`nickName`/`fragmentId`/`loseScore`/`points`/`propId`/`oldNickName`…），拆列性价比极低。**只需保证能 `cjson.decode`。** |
| `sendUserEmail` / `gainSysEmailReward` / `gainRewardEmailReward` / `gainInviteReward` / `gainInvitedReward` / `gainPraiseReward` / `challengeFriendList` 的 `rewards` | **临时构造，不必落库** | 元素形状统一为 `{itemType, amount, metaId?, level?, id?, exp?}`（`[GRIP]:383-399`、`[CHFL]:97-104`），由发奖逻辑现算即可。**但绝不能为空/nil** —— 无脑 `pairs`/`#` 会崩。 |
| `getBonusAccepterList` 的 `friendList` / `unionList` | **不落库**，实时从 `friend_relation` + `user` join 出来 | 其中 `dispatchedNum` / `itemDescKey` 是**纯客户端字段**（`[REDPKT]:84-90`、`[REDPKT]:253-259`），服务端连传都不用传。 |
| `sharkAccountInvitation` | 建议拆列（`invite_player_num` / `gained_invite_reward_num` / `has_invited`） | 只有 3 个字段，且 `invitePlayerNum` / `gainedInviteRewardNum` **缺失会崩**（`[INVCODE]:108/201`），单独建列更安全。 |
| `sharkFriendDetail.invitation_received` | 独立列 | 决定「接受/拒绝」分支（`[UDP]:603`），但也可靠 `friend_invitation` 现算。 |

## 4.3 三条落地铁律

1. **数组键永远是数组**：`sysEmails` `rewardEmails` `sysNotices` `userEmails` `sysEmailMeta` `sharkFriends` `rewards` `friendUids` `acceptedFriends` `reviewingFriends` `friendList` `unionList` `accepterList`。AMF 编码器把空表编成「空对象」而不是「空数组」时，客户端虽然多数场景不崩（`ipairs` 0 次），但一旦有元素就会因为「字典带字符串键」而全部读不到 → 表现为**界面全空**。
2. **三个「一定崩」的字段**：`sysEmails/rewardEmails[].receiveSeconds`、`sysEmailMeta[].contentText`、`rewardEmails[].content`。这三个做 `NOT NULL` 约束。
3. **两个「返回 nil 一定崩」的对象**：`getFriendDetail` 的 `sharkFriendDetail`（`[UDP]:657` 无保护）、`gainSysEmailReward`/`gainRewardEmailReward` 的 `rewards`（`[EVP]:146` → `[GRIP]:380`）。要么给足字段，要么走失败码而**不要**返回成功空对象。
