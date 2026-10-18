import os
import sys

ROOT = r'E:\deepseek_projects\app_server'
sys.path.insert(0, os.path.join(ROOT, 'server'))
os.chdir(os.path.join(ROOT, 'server'))
sys.stdout.reconfigure(encoding='utf-8')
from db import Database            # noqa: E402

db = Database('canon.db')
db.connect()
with db.tx() as con:
    con.execute("DELETE FROM player_activity WHERE activity_key='mission_event_cache'")
print('战斗事件缓存已清空')
db.close()
