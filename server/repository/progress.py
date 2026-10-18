#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""进度域：关卡上下文 / 场景推进 / 通关记录 / 精英 / 通天塔 / 圣诞副本。"""
import time


class ProgressRepo:
    def __init__(self, db):
        self.db = db

    # ---- sharkMissionContext ----
    def mission_context(self, player_id):
        row = self.db.one("SELECT * FROM player_mission_context WHERE player_id=?",
                          (int(player_id),))
        if row is None:
            with self.db.tx() as con:
                con.execute("INSERT INTO player_mission_context(player_id) VALUES (?)",
                            (int(player_id),))
            row = self.db.one("SELECT * FROM player_mission_context WHERE player_id=?",
                              (int(player_id),))
        return row

    def update_mission_context(self, player_id, **fields):
        self._update('player_mission_context', 'player_id', player_id, player_id, fields)

    # ---- sharkSceneProcess ----
    def scene_process(self, player_id):
        row = self.db.one("SELECT * FROM player_scene_process WHERE player_id=?",
                          (int(player_id),))
        if row is None:
            with self.db.tx() as con:
                con.execute("INSERT INTO player_scene_process(player_id) VALUES (?)",
                            (int(player_id),))
            row = self.db.one("SELECT * FROM player_scene_process WHERE player_id=?",
                              (int(player_id),))
        return row

    def scene_countries(self, player_id):
        return self.db.all("SELECT * FROM player_scene_country WHERE player_id=?",
                           (int(player_id),))

    def add_scene_country(self, player_id, country_id, kind):
        with self.db.tx() as con:
            con.execute("INSERT OR IGNORE INTO player_scene_country(player_id, country_id, kind)"
                        " VALUES (?,?,?)", (int(player_id), int(country_id), int(kind)))

    def set_max_finished_mission(self, player_id, mission_id):
        with self.db.tx() as con:
            con.execute("UPDATE player_scene_process SET max_finished_mission_id=MAX("
                        "max_finished_mission_id, ?), last_clear_time=? WHERE player_id=?",
                        (int(mission_id), int(time.time()), int(player_id)))

    # ---- missionCompletes ----
    def mission_completes(self, player_id):
        return self.db.all("SELECT * FROM player_mission_complete WHERE player_id=?"
                           " ORDER BY mission_id", (int(player_id),))

    def add_mission_complete(self, player_id, mission_id, star=0):
        with self.db.tx() as con:
            con.execute(
                "INSERT INTO player_mission_complete(player_id, mission_id, star, finish_time)"
                " VALUES (?,?,?,?) ON CONFLICT(player_id, mission_id)"
                " DO UPDATE SET star=MAX(star, excluded.star), complete_count=complete_count+1",
                (int(player_id), int(mission_id), int(star), int(time.time())))

    # ---- 精英 / 通天塔 / 圣诞 ----
    def elite(self, player_id):
        row = self.db.one("SELECT * FROM player_elite WHERE player_id=?", (int(player_id),))
        if row is None:
            with self.db.tx() as con:
                con.execute("INSERT INTO player_elite(player_id) VALUES (?)", (int(player_id),))
            row = self.db.one("SELECT * FROM player_elite WHERE player_id=?", (int(player_id),))
        return row

    def set_max_finished_elite(self, player_id, elite_id):
        self.elite(player_id)
        with self.db.tx() as con:
            con.execute("UPDATE player_elite SET max_finished_elite_id=MAX("
                        "max_finished_elite_id, ?) WHERE player_id=?",
                        (int(elite_id), int(player_id)))

    def sky_tower(self, player_id):
        row = self.db.one("SELECT * FROM player_sky_tower WHERE player_id=?", (int(player_id),))
        if row is None:
            with self.db.tx() as con:
                con.execute("INSERT INTO player_sky_tower(player_id) VALUES (?)",
                            (int(player_id),))
            row = self.db.one("SELECT * FROM player_sky_tower WHERE player_id=?",
                              (int(player_id),))
        return row

    def set_sky_tower_floor(self, player_id, floor):
        self.sky_tower(player_id)
        with self.db.tx() as con:
            con.execute("UPDATE player_sky_tower SET max_floor=MAX(max_floor, ?)"
                        " WHERE player_id=?", (int(floor), int(player_id)))

    def christ(self, player_id):
        row = self.db.one("SELECT * FROM player_christ WHERE player_id=?", (int(player_id),))
        if row is None:
            with self.db.tx() as con:
                con.execute("INSERT INTO player_christ(player_id) VALUES (?)", (int(player_id),))
            row = self.db.one("SELECT * FROM player_christ WHERE player_id=?", (int(player_id),))
        return row

    def set_max_finished_christ(self, player_id, christ_id):
        self.christ(player_id)
        with self.db.tx() as con:
            con.execute("UPDATE player_christ SET max_finished_christ_id=MAX("
                        "max_finished_christ_id, ?) WHERE player_id=?",
                        (int(christ_id), int(player_id)))

    # ---- 内部 ----
    def _update(self, table, key, where_val, player_id, fields):
        if not fields:
            return
        cols = [c[1] for c in self.db.q("PRAGMA table_info(%s)" % table)]
        sets, args = [], []
        for k, v in fields.items():
            if k not in cols:
                raise KeyError("%s 表没有列 %r" % (table, k))
            sets.append("%s=?" % k)
            args.append(int(v) if isinstance(v, bool) else v)
        args.append(int(where_val))
        with self.db.tx() as con:
            con.execute("UPDATE %s SET %s WHERE %s=?" % (table, ', '.join(sets), key), args)
