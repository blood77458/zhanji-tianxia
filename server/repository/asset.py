#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""资产域：卡牌 / 技能 / 装备 / 道具 / 元神 / 宝物 / 碎片 / 阵容 / 阵法。

单点存储原则（见 SERVER_DATA_MODEL.md §1.2）：
「谁穿了什么」只有一份权威数据 —— player_equip.card_id /
player_spirit.card_id / player_treasure.card_id。
客户端要的 sharkCards[].equipIds / cardSpirits / treasureId 全部由
assembler 反查得出，这里**不存第二份**。
"""
import json
import time

import gamedata as G


class AssetRepo:
    def __init__(self, db):
        self.db = db

    # ============================================================ 卡牌
    def cards(self, player_id):
        return self.db.all("SELECT * FROM player_card WHERE player_id=? ORDER BY card_id",
                           (int(player_id),))

    def card(self, player_id, card_id):
        return self.db.one("SELECT * FROM player_card WHERE player_id=? AND card_id=?",
                           (int(player_id), int(card_id)))

    def card_by_meta(self, player_id, meta_id):
        return self.db.all("SELECT * FROM player_card WHERE player_id=? AND meta_id=?",
                           (int(player_id), int(meta_id)))

    def card_skills(self, card_id):
        return self.db.all("SELECT * FROM player_card_skill WHERE card_id=? ORDER BY slot",
                           (int(card_id),))

    def create_card(self, player_id, meta_id, level=1, exp=0):
        meta_id = int(meta_id)
        if not G.card_meta_exists(meta_id):
            raise ValueError("未知卡牌 metaId=%d" % meta_id)
        cid = self.db.next_id('card')
        now = int(time.time())
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO player_card(card_id, player_id, meta_id, level, exp,"
                " card_group_id, create_time) VALUES (?,?,?,?,?,?,?)",
                (cid, int(player_id), meta_id, int(level), int(exp),
                 G.card_group_id(meta_id), now))
            # ⚠️ 必须按配置预生成技能，空列表 + meta.skill~=0 → SIGKILL
            for i, sk in enumerate(G.build_card_skills(meta_id), 1):
                con.execute(
                    "INSERT INTO player_card_skill(card_id, slot, skill_id, skill_type,"
                    " curr_quality, country_group_id, country_group_num, card_group_ids)"
                    " VALUES (?,?,?,?,?,?,?,?)",
                    (cid, i, int(sk['skillId']), int(sk.get('skillType') or 0),
                     int(sk.get('currQuality') or 0), int(sk.get('countryGroupId') or 0),
                     int(sk.get('countryGroupNum') or 0),
                     ','.join(str(x) for x in (sk.get('cardGroupIds') or []))))
        return cid

    def update_card(self, player_id, card_id, **fields):
        self._update_owned('player_card', 'card_id', player_id, card_id, fields)

    def delete_card(self, player_id, card_id):
        with self.db.tx() as con:
            con.execute("DELETE FROM player_card WHERE player_id=? AND card_id=?",
                        (int(player_id), int(card_id)))
            # 卡牌没了，装备/元神/宝物要脱下来（外键不会级联到 card_id 字段）
            con.execute("UPDATE player_equip SET card_id=0 WHERE player_id=? AND card_id=?",
                        (int(player_id), int(card_id)))
            con.execute("UPDATE player_spirit SET card_id=0 WHERE player_id=? AND card_id=?",
                        (int(player_id), int(card_id)))
            con.execute("UPDATE player_treasure SET card_id=0 WHERE player_id=? AND card_id=?",
                        (int(player_id), int(card_id)))
            con.execute("DELETE FROM player_battle_slot WHERE player_id=? AND card_id=?",
                        (int(player_id), int(card_id)))

    def replace_card_skills(self, card_id, skills):
        with self.db.tx() as con:
            con.execute("DELETE FROM player_card_skill WHERE card_id=?", (int(card_id),))
            for i, sk in enumerate(skills, 1):
                con.execute(
                    "INSERT INTO player_card_skill(card_id, slot, skill_id, skill_type,"
                    " curr_quality, country_group_id, country_group_num, card_group_ids)"
                    " VALUES (?,?,?,?,?,?,?,?)",
                    (int(card_id), i, int(sk['skillId']), int(sk.get('skillType') or 0),
                     int(sk.get('currQuality') or 0), int(sk.get('countryGroupId') or 0),
                     int(sk.get('countryGroupNum') or 0),
                     ','.join(str(x) for x in (sk.get('cardGroupIds') or []))))

    def card_holder_ids(self, player_id):
        """所有「被穿在身上的东西」引用的卡牌 id 集合（卖卡/拆卡时的保护判断）。"""
        rows = self.db.all(
            "SELECT card_id FROM player_battle_slot WHERE player_id=? AND card_id>0"
            " UNION SELECT card_id FROM player_equip WHERE player_id=? AND card_id>0"
            " UNION SELECT card_id FROM player_spirit WHERE player_id=? AND card_id>0"
            " UNION SELECT card_id FROM player_treasure WHERE player_id=? AND card_id>0"
            " UNION SELECT card_id FROM player_matrix_grid WHERE player_id=? AND card_id>0",
            (int(player_id),) * 5)
        return {int(r['card_id']) for r in rows}

    # ============================================================ 装备
    def equips(self, player_id):
        return self.db.all("SELECT * FROM player_equip WHERE player_id=? ORDER BY equip_id",
                           (int(player_id),))

    def equip(self, player_id, equip_id):
        return self.db.one("SELECT * FROM player_equip WHERE player_id=? AND equip_id=?",
                           (int(player_id), int(equip_id)))

    def equips_of_card(self, player_id, card_id):
        """返回**完整行**（assembler 要用 meta_id/level 算装备加成，只给 id 不够）。"""
        return self.db.all("SELECT * FROM player_equip WHERE player_id=? AND card_id=?"
                           " ORDER BY equip_id", (int(player_id), int(card_id)))

    def create_equip(self, player_id, meta_id, level=1, exp=0, card_id=0):
        eid = self.db.next_id('equip')
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO player_equip(equip_id, player_id, meta_id, level, exp, card_id,"
                " create_time) VALUES (?,?,?,?,?,?,?)",
                (eid, int(player_id), int(meta_id), int(level), int(exp), int(card_id),
                 int(time.time())))
        return eid

    def update_equip(self, player_id, equip_id, **fields):
        self._update_owned('player_equip', 'equip_id', player_id, equip_id, fields)

    def delete_equip(self, player_id, equip_id):
        with self.db.tx() as con:
            con.execute("DELETE FROM player_equip WHERE player_id=? AND equip_id=?",
                        (int(player_id), int(equip_id)))

    def wear_equip(self, player_id, equip_id, card_id):
        """穿上/脱下（card_id=0 表示脱下）。"""
        self.update_equip(player_id, equip_id, card_id=int(card_id))

    # ============================================================ 道具
    def props(self, player_id):
        return self.db.all("SELECT * FROM player_prop WHERE player_id=? AND amount>0"
                           " ORDER BY meta_id", (int(player_id),))

    def prop(self, player_id, meta_id):
        return self.db.get_prop(int(player_id), int(meta_id))

    def add_prop(self, player_id, meta_id, delta):
        self.db.add_prop(int(player_id), int(meta_id), int(delta))
        return self.prop(player_id, meta_id)

    # ============================================================ 元神
    def spirits(self, player_id):
        return self.db.all("SELECT * FROM player_spirit WHERE player_id=? ORDER BY spirit_id",
                           (int(player_id),))

    def spirit(self, player_id, spirit_id):
        return self.db.one("SELECT * FROM player_spirit WHERE player_id=? AND spirit_id=?",
                           (int(player_id), int(spirit_id)))

    def spirit_attrs(self, spirit_id):
        return self.db.all("SELECT * FROM player_spirit_attr WHERE spirit_id=? ORDER BY slot",
                           (int(spirit_id),))

    def spirits_of_card(self, player_id, card_id):
        """返回完整行 + attributes（算元神加成要用）。"""
        out = []
        for s in self.db.all("SELECT * FROM player_spirit WHERE player_id=? AND card_id=?"
                             " ORDER BY spirit_id", (int(player_id), int(card_id))):
            d = dict(s)
            d['attributes'] = [dict(x) for x in self.db.all(
                "SELECT * FROM player_spirit_attr WHERE spirit_id=?", (int(s['spirit_id']),))]
            out.append(d)
        return out

    def create_spirit(self, player_id, meta_id, level=1, exp=0, card_id=0, attrs=None):
        sid = self.db.next_id('spirit')
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO player_spirit(spirit_id, player_id, meta_id, level, exp, card_id,"
                " create_time) VALUES (?,?,?,?,?,?,?)",
                (sid, int(player_id), int(meta_id), int(level), int(exp), int(card_id),
                 int(time.time())))
            self._write_spirit_attrs(con, sid, attrs or [])
        return sid

    def _write_spirit_attrs(self, con, spirit_id, attrs):
        con.execute("DELETE FROM player_spirit_attr WHERE spirit_id=?", (int(spirit_id),))
        for i, a in enumerate(attrs, 1):
            con.execute("INSERT INTO player_spirit_attr(spirit_id, slot, attribute_type,"
                        " attribute_growing) VALUES (?,?,?,?)",
                        (int(spirit_id), i, int(a.get('attributeType') or 0),
                         float(a.get('attributeGrowing') or 0)))

    def replace_spirit_attrs(self, spirit_id, attrs):
        with self.db.tx() as con:
            self._write_spirit_attrs(con, spirit_id, attrs)

    def update_spirit(self, player_id, spirit_id, **fields):
        self._update_owned('player_spirit', 'spirit_id', player_id, spirit_id, fields)

    def delete_spirit(self, player_id, spirit_id):
        with self.db.tx() as con:
            con.execute("DELETE FROM player_spirit WHERE player_id=? AND spirit_id=?",
                        (int(player_id), int(spirit_id)))

    # ---- 洗炼暂存 ----
    def unsaved_spirit(self, player_id):
        row = self.db.one("SELECT * FROM player_spirit_unsaved WHERE player_id=?",
                          (int(player_id),))
        if row is None:
            with self.db.tx() as con:
                con.execute("INSERT INTO player_spirit_unsaved(player_id) VALUES (?)",
                            (int(player_id),))
            row = self.db.one("SELECT * FROM player_spirit_unsaved WHERE player_id=?",
                              (int(player_id),))
        return row

    def set_unsaved_spirit(self, player_id, spirit_id, attrs):
        self.unsaved_spirit(player_id)
        with self.db.tx() as con:
            con.execute("UPDATE player_spirit_unsaved SET spirit_id=?, attributes_json=?,"
                        " updated_at=? WHERE player_id=?",
                        (int(spirit_id), json.dumps(attrs, ensure_ascii=False),
                         int(time.time()), int(player_id)))

    # ============================================================ 宝物
    def treasures(self, player_id):
        return self.db.all("SELECT * FROM player_treasure WHERE player_id=? ORDER BY treasure_id",
                           (int(player_id),))

    def treasure(self, player_id, treasure_id):
        return self.db.one("SELECT * FROM player_treasure WHERE player_id=? AND treasure_id=?",
                           (int(player_id), int(treasure_id)))

    def treasure_of_card(self, player_id, card_id):
        return self.db.one("SELECT * FROM player_treasure WHERE player_id=? AND card_id=?",
                           (int(player_id), int(card_id)))

    def create_treasure(self, player_id, meta_id, level=1, card_id=0):
        tid = self.db.next_id('treasure')
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO player_treasure(treasure_id, player_id, meta_id, level, card_id,"
                " create_time) VALUES (?,?,?,?,?,?)",
                (tid, int(player_id), int(meta_id), int(level), int(card_id), int(time.time())))
        return tid

    def update_treasure(self, player_id, treasure_id, **fields):
        self._update_owned('player_treasure', 'treasure_id', player_id, treasure_id, fields)

    def delete_treasure(self, player_id, treasure_id):
        with self.db.tx() as con:
            con.execute("DELETE FROM player_treasure WHERE player_id=? AND treasure_id=?",
                        (int(player_id), int(treasure_id)))

    # ============================================================ 碎片
    def fragments(self, player_id, kind):
        return self.db.all("SELECT * FROM player_fragment WHERE player_id=? AND kind=?"
                           " ORDER BY meta_id", (int(player_id), int(kind)))

    def add_fragment(self, player_id, kind, meta_id, delta):
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO player_fragment(player_id, kind, meta_id, amount) VALUES (?,?,?,?)"
                " ON CONFLICT(player_id, kind, meta_id)"
                " DO UPDATE SET amount = MAX(0, amount + excluded.amount)",
                (int(player_id), int(kind), int(meta_id), int(delta)))
            con.execute("DELETE FROM player_fragment WHERE player_id=? AND kind=? AND meta_id=?"
                        " AND amount<=0", (int(player_id), int(kind), int(meta_id)))
        row = self.db.one("SELECT amount FROM player_fragment WHERE player_id=? AND kind=?"
                          " AND meta_id=?", (int(player_id), int(kind), int(meta_id)))
        return int(row['amount']) if row else 0

    # ============================================================ 秘境货币
    def add_mysterious_coin(self, player_id, meta_id, delta):
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO player_mysterious_coin(player_id, meta_id, amount) VALUES (?,?,?)"
                " ON CONFLICT(player_id, meta_id)"
                " DO UPDATE SET amount = MAX(0, amount + excluded.amount)",
                (int(player_id), int(meta_id), int(delta)))
            con.execute("DELETE FROM player_mysterious_coin WHERE player_id=? AND meta_id=?"
                        " AND amount<=0", (int(player_id), int(meta_id)))

    # ============================================================ 阵容
    def battle_arrays(self, player_id):
        return self.db.all("SELECT * FROM player_battle_array WHERE player_id=?"
                           " ORDER BY array_id", (int(player_id),))

    def ensure_battle_arrays(self, player_id, count=1):
        rows = self.battle_arrays(player_id)
        if rows:
            return rows
        with self.db.tx() as con:
            for i in range(1, count + 1):
                con.execute("INSERT INTO player_battle_array(player_id, array_id, is_active)"
                            " VALUES (?,?,?)", (int(player_id), i, 1 if i == 1 else 0))
        return self.battle_arrays(player_id)

    def battle_slots(self, player_id, array_id=None):
        if array_id is None:
            return self.db.all("SELECT * FROM player_battle_slot WHERE player_id=?"
                               " ORDER BY array_id, slot", (int(player_id),))
        return self.db.all("SELECT * FROM player_battle_slot WHERE player_id=? AND array_id=?"
                           " ORDER BY slot", (int(player_id), int(array_id)))

    def set_battle_queue(self, player_id, array_id, card_ids):
        """整体替换某套阵容的槽位（1 号位 = 主将）。

        同时把 player.main_card_id / additional_card_ids 同步成当前生效阵容的快照
        —— 客户端 CommonManager.getQueueData() 读的是后者。
        """
        card_ids = [int(c) for c in card_ids if int(c or 0) > 0]
        with self.db.tx() as con:
            con.execute("DELETE FROM player_battle_slot WHERE player_id=? AND array_id=?",
                        (int(player_id), int(array_id)))
            for i, cid in enumerate(card_ids, 1):
                con.execute("INSERT INTO player_battle_slot(player_id, array_id, slot, card_id)"
                            " VALUES (?,?,?,?)", (int(player_id), int(array_id), i, cid))
            active = con.execute("SELECT array_id FROM player_battle_array WHERE player_id=?"
                                 " AND is_active=1", (int(player_id),)).fetchone()
            if active and int(active['array_id']) == int(array_id):
                main = card_ids[0] if card_ids else 0
                add = ','.join(str(c) for c in card_ids[1:])
                con.execute("UPDATE player SET main_card_id=?, additional_card_ids=?"
                            " WHERE player_id=?", (main, add, int(player_id)))

    def set_active_array(self, player_id, array_id):
        with self.db.tx() as con:
            con.execute("UPDATE player_battle_array SET is_active=0 WHERE player_id=?",
                        (int(player_id),))
            con.execute("UPDATE player_battle_array SET is_active=1 WHERE player_id=?"
                        " AND array_id=?", (int(player_id), int(array_id)))
            con.execute("UPDATE player_extend SET battle_array_id=? WHERE player_id=?",
                        (int(array_id), int(player_id)))
        self.sync_queue_snapshot(player_id, array_id)

    def sync_queue_snapshot(self, player_id, array_id=None):
        """把 player.main_card_id / additional_card_ids 刷成指定阵容的快照。"""
        if array_id is None:
            row = self.db.one("SELECT array_id FROM player_battle_array WHERE player_id=?"
                              " AND is_active=1", (int(player_id),))
            array_id = int(row['array_id']) if row else 1
        slots = self.battle_slots(player_id, array_id)
        cards = [int(s['card_id']) for s in slots if int(s['card_id']) > 0]
        with self.db.tx() as con:
            con.execute("UPDATE player SET main_card_id=?, additional_card_ids=?"
                        " WHERE player_id=?",
                        (cards[0] if cards else 0,
                         ','.join(str(c) for c in cards[1:]), int(player_id)))

    # ============================================================ 阵法
    def matrices(self, player_id):
        return self.db.all("SELECT * FROM player_matrix WHERE player_id=?", (int(player_id),))

    def matrix_grids(self, player_id, matrix_id=None):
        if matrix_id is None:
            return self.db.all("SELECT * FROM player_matrix_grid WHERE player_id=?"
                               " ORDER BY matrix_id, matrix_grid_id", (int(player_id),))
        return self.db.all("SELECT * FROM player_matrix_grid WHERE player_id=? AND matrix_id=?"
                           " ORDER BY matrix_grid_id", (int(player_id), int(matrix_id)))

    def set_matrix_grid(self, player_id, matrix_id, grid_id, card_id):
        with self.db.tx() as con:
            con.execute("INSERT INTO player_matrix(player_id, matrix_id) VALUES (?,?)"
                        " ON CONFLICT(player_id, matrix_id) DO NOTHING",
                        (int(player_id), int(matrix_id)))
            con.execute(
                "INSERT INTO player_matrix_grid(player_id, matrix_id, matrix_grid_id, card_id)"
                " VALUES (?,?,?,?) ON CONFLICT(player_id, matrix_id, matrix_grid_id)"
                " DO UPDATE SET card_id=excluded.card_id",
                (int(player_id), int(matrix_id), int(grid_id), int(card_id)))

    # ============================================================ 内部
    def _update_owned(self, table, key, player_id, obj_id, fields):
        if not fields:
            return
        cols = [c[1] for c in self.db.q("PRAGMA table_info(%s)" % table)]
        sets, args = [], []
        for k, v in fields.items():
            if k not in cols:
                raise KeyError("%s 表没有列 %r" % (table, k))
            sets.append("%s=?" % k)
            args.append(int(v) if isinstance(v, bool) else v)
        args += [int(player_id), int(obj_id)]
        with self.db.tx() as con:
            con.execute("UPDATE %s SET %s WHERE player_id=? AND %s=?"
                        % (table, ', '.join(sets), key), args)
