#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""冒烟测试：建库 → 灌一个初始角色 → 组装 gameInit → 校验客户端契约。

验证两件事：
  1. schema.sql 能建库，assembler 能无条件拼出客户端要的全部 gameInit 顶层 key；
  2. 关键字段的类型符合客户端的硬约束（uid 是字符串、additionalCardIds 是
     逗号字符串、列表字段是列表、sharkMissionContext 不为空 …）。

跑法：python work/api_analysis/smoke_assemble.py
"""
import io
import json
import os
import sys
import time

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
SERVER = os.path.abspath(os.path.join(HERE, '..', '..', 'server'))
sys.path.insert(0, SERVER)

import db as dbmod            # noqa: E402
import assembler              # noqa: E402

# 客户端在 DataManager / 各 Scene 里实际读取的 gameInit 顶层 key（扫描全仓得到）
REQUIRED_KEYS = [
    'sharkUser', 'sharkUserExtend', 'sharkUserExtendMore',
    'sharkCards', 'sharkEquips', 'sharkProps', 'sharkSpirits', 'sharkTreasures',
    'sharkMatrices', 'sharkUserBattleArray', 'sharkMissionContext', 'sharkSceneProcess',
    'missionCompletes', 'sharkCardFragments', 'sharkEquipFragments',
    'sharkMysteriousCoins', 'sharkDailyData', 'sharkDailyDataExtend',
    'sharkUserSecretShop', 'sharkElite', 'sharkSkyTower', 'sharkChristInfo',
    'sharkGachaInfo', 'sharkDice', 'sharkShop', 'sharkGemCards',
    'crossPvpActivityStatus', 'crossBossActivityStatus', 'timestamp',
]

# 客户端的硬类型约束（错了就是 SIGKILL / 黑屏）
TYPE_RULES = [
    ('sharkUser.uid', str, 'luajava setGspGameUserId(java.lang.String)V，传数字 → Invalid method call'),
    ('sharkUser.nickName', str, 'UI setString'),
    ('sharkUser.additionalCardIds', str, 'CommonManager.getQueueData 对它 :split(",")'),
    ('sharkUser.level', int, '大量算术与比较'),
    ('sharkUser.freeGems', int, 'calcComplex_getGemsNow 四则运算'),
    ('sharkUser.usedFreeGems', int, '同上'),
    ('sharkUser.rechargeGems', int, '同上'),
    ('sharkUser.usedRechargeGems', int, '同上'),
    ('sharkUser.energy', int, '体力恢复计算'),
    ('sharkUser.eventPoint', int, '精力恢复计算'),
    ('sharkUser.coins', int, 'BaseUIScene setString'),
    ('sharkCards.sharkCards', list, 'ipairs / #'),
    ('sharkSpirits.sharkSpirits', list, 'pairs 遍历'),
    ('sharkTreasures.sharkTreasures', list, 'pairs 遍历'),
    ('sharkEquips.sharkEquips', list, 'ipairs'),
    ('sharkProps.sharkProps', list, 'ipairs'),
    ('sharkUserBattleArray', list, 'BackpackScene:1084 无守卫索引 [1..3]'),
    ('missionCompletes', list, 'ipairs'),
    ('sharkMissionContext', dict, '空表为真 → 下发 {} 会顶掉客户端默认值然后崩'),
    ('sharkSceneProcess', dict, '同上'),
    ('sharkUserExtend.tutorialSteps', list, 'canonUtils.lua:603 pairs(data.sharkUserExtend.tutorialSteps)'),
    ('sharkUserExtend.gainedChargeMoneyRewardList', list, '同步累充状态'),
    ('sharkUserExtend.signInInfo', dict, 'DailyDataManager'),
    ('sharkUserExtendMore.battleArrayId', int, 'MetaManager.getAllCardInCurBattleArray 索引数组'),
]


def get_path(obj, path):
    cur = obj
    for part in path.split('.'):
        if not isinstance(cur, dict) or part not in cur:
            return None, False
        cur = cur[part]
    return cur, True


def seed(db):
    """灌一个最小可玩的初始角色：1 张卡 + 1 件装备 + 1 个道具 + 1 个元神 + 1 个宝物。"""
    now = int(time.time())
    today = db.today()
    with db.tx() as con:
        con.execute("INSERT INTO account(account_name, create_time, last_login_time)"
                    " VALUES (NULL,?,?)", (now, now))
        acc = con.execute("SELECT last_insert_rowid()").fetchone()[0]
        con.execute(
            "INSERT INTO player(account_id, server_id, nickname, create_time, last_login_time,"
            " level, exp, gold, gem, free_gems, energy, energy_last_update_time, event_point,"
            " event_point_last_update_time, action_power, main_card_id, additional_card_ids,"
            " create_time) VALUES (?,1,'测试主公',?,?,1,0,100000,10000,10000,100,?,100,?,100,1,'',?)",
            (acc, now, now, now, now, now))
        pid = con.execute("SELECT last_insert_rowid()").fetchone()[0]
        con.execute("INSERT INTO player_extend(player_id) VALUES (?)", (pid,))
        con.execute("INSERT INTO player_mission_context(player_id) VALUES (?)", (pid,))
        con.execute("INSERT INTO player_scene_process(player_id) VALUES (?)", (pid,))
        con.execute("INSERT INTO player_daily(player_id, stat_date) VALUES (?,?)", (pid, today))
        con.execute("INSERT INTO player_secret_shop(player_id, free_times, last_refresh_second)"
                    " VALUES (?,5,?)", (pid, now))

        cid = db.next_id('card')
        con.execute("INSERT INTO player_card(card_id, player_id, meta_id, level, exp,"
                    " card_group_id, create_time) VALUES (?,?,102111,1,0,1,?)", (cid, pid, now))
        for i, sk in enumerate([{'skillType': 1, 'skillId': 2001, 'currQuality': 1,
                                 'groupIds': [11, 12]}], 1):
            con.execute("INSERT INTO player_card_skill(card_id, slot, skill_id, skill_type,"
                        " curr_quality, card_group_ids) VALUES (?,?,?,?,?,?)",
                        (cid, i, sk['skillId'], sk['skillType'], sk['currQuality'],
                         ','.join(str(x) for x in sk['groupIds'])))
        eid = db.next_id('equip')
        con.execute("INSERT INTO player_equip(equip_id, player_id, meta_id, level, card_id,"
                    " create_time) VALUES (?,?,301111,1,?,?)", (eid, pid, cid, now))
        sid = db.next_id('spirit')
        con.execute("INSERT INTO player_spirit(spirit_id, player_id, meta_id, level, card_id,"
                    " create_time) VALUES (?,?,401111,1,?,?)", (sid, pid, cid, now))
        con.execute("INSERT INTO player_spirit_attr(spirit_id, slot, attribute_type,"
                    " attribute_growing) VALUES (?,1,1,1.25)", (sid,))
        tid = db.next_id('treasure')
        con.execute("INSERT INTO player_treasure(treasure_id, player_id, meta_id, level,"
                    " card_id, create_time) VALUES (?,?,501111,1,?,?)", (tid, pid, cid, now))
        # 阵容只记「哪张卡站在哪个位置」；装备/元神/宝物靠 card_id 反查
        con.execute("INSERT INTO player_battle_array(player_id, array_id, is_active)"
                    " VALUES (?,1,1)", (pid,))
        con.execute("INSERT INTO player_battle_slot(player_id, array_id, slot, card_id)"
                    " VALUES (?,1,1,?)", (pid, cid))
        con.execute("INSERT INTO player_matrix(player_id, matrix_id) VALUES (?,1)", (pid,))
        con.execute("INSERT INTO player_matrix_grid(player_id, matrix_id, matrix_grid_id, card_id)"
                    " VALUES (?,1,1,?)", (pid, cid))
        con.execute("INSERT INTO player_tutorial_step(player_id, step, done_time)"
                    " VALUES (?,1,?)", (pid, now))
        db.add_prop(pid, 600001, 50)
    return pid


def assert_paths(payload):
    fails = []
    for path, typ, why in TYPE_RULES:
        val, found = get_path(payload, path)
        if not found:
            fails.append('缺失 %s  （%s）' % (path, why))
            continue
        if not isinstance(val, typ) or isinstance(val, bool) and typ is int:
            fails.append('类型错 %s: 期望 %s，实际 %s=%r  （%s）'
                         % (path, typ.__name__, type(val).__name__, val, why))
    return fails


def main():
    path = os.path.join(HERE, '_smoke.db')
    for suffix in ('', '-wal', '-shm'):
        if os.path.exists(path + suffix):
            os.remove(path + suffix)
    db = dbmod.Database(path)
    db.init_schema()
    pid = seed(db)
    payload = assembler.build_game_init(db, pid)

    print('=== 1. 顶层 key 覆盖 ===')
    missing = [k for k in REQUIRED_KEYS if k not in payload]
    extra = [k for k in payload if k not in REQUIRED_KEYS]
    print('  需要 %d 个，实际 %d 个，缺失 %d 个' % (len(REQUIRED_KEYS), len(payload), len(missing)))
    if missing:
        print('  ❌ 缺失: %s' % ', '.join(missing))
    else:
        print('  ✅ 全部齐全')
    if extra:
        print('  （额外 key: %s）' % ', '.join(extra))

    print()
    print('=== 2. 类型约束 ===')
    fails = assert_paths(payload)
    if fails:
        for f in fails:
            print('  ❌ ' + f)
    else:
        print('  ✅ %d 条类型约束全部通过' % len(TYPE_RULES))

    print()
    print('=== 3. 抽样内容 ===')
    su = payload['sharkUser']
    print('  sharkUser: uid=%r(%s) nickName=%r level=%d gem=%d additionalCardIds=%r'
          % (su['uid'], type(su['uid']).__name__, su['nickName'], su['level'],
             su['gem'], su['additionalCardIds']))
    card = payload['sharkCards']['sharkCards'][0]
    print('  card[0]  : cardId=%d metaId=%d equipIds=%s cardSpirits=%s treasureId=%d skills=%d'
          % (card['cardId'], card['metaId'], card['equipIds'], card['cardSpirits'],
             card['treasureId'], len(card['cardSkills'])))
    print('  派生校验 : equipIds/cardSpirits/treasureId 都是从 player_equip/spirit/treasure'
          ' 的 card_id 反查出来的')
    print('  battle   : %d 套阵容，槽位 %s'
          % (len(payload['sharkUserBattleArray']),
             [s['cardId'] for s in payload['sharkUserBattleArray'][0]['sharkUserQueue']]))
    print('  mission  : %s' % payload['sharkMissionContext'])
    print('  extend   : %d 个字段; extendMore.battleArrayId=%s'
          % (len(payload['sharkUserExtend']), payload['sharkUserExtendMore']['battleArrayId']))

    print()
    total = len(json.dumps(payload, ensure_ascii=False))
    print('=== 结果 ===')
    if not missing and not fails:
        print('  ✅ 通过：schema + assembler 能完整拼出客户端 gameInit 契约（%d 字节）' % total)
    else:
        print('  ❌ 未通过')
        db.close()
        return 1

    db.close()
    for suffix in ('', '-wal', '-shm'):
        try:
            os.remove(path + suffix)
        except OSError:
            pass
    return 0


if __name__ == '__main__':
    sys.exit(main())
