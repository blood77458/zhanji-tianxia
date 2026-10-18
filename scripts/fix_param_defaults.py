"""把 handlers*.py 里 `api.param(params, 'xxx')`（缺默认值）补上类型正确的默认值。

缺默认值时 api.param 返回 None，下游 `int(None)` 直接 500 —— 客户端万一没带
这个字段（或字段为 null）就会崩。补成 0 / '' / [] 后，业务层会正常走到
「找不到记录」的分支并返回业务错误码。
"""
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
API = r'E:\deepseek_projects\app_server\server\api'

NUM = {'masterId', 'cardId', 'targetLevel', 'metaId', 'equipId', 'propId',
       'goodsId', 'avatarId', 'amount', 'skillId', 'gridId', 'index',
       'cardGroupId', 'itemId', 'itemType', 'type', 'id', 'times',
       'pos', 'position', 'slot', 'count', 'num', 'page', 'level',
       'matchedUid', 'uid', 'targetUid', 'rewardId', 'dayRewardId',
       'questionMetaId', 'answer', 'battleType', 'floor', 'version',
       'swornRewardId', 'praiseId', 'treasureId', 'spiritId', 'boxId'}
STR = {'notice', 'declaration', 'keyword', 'content', 'title', 'nickName',
       'accountName', 'password', 'name', 'email', 'inviteCode', 'declarationText'}
BOOL = {'speedUp', 'revenge', 'useGold'}
INT2 = {'opponentUid', 'friendUid'}
LIST = {'additionalCardIds'}

PAT = re.compile(r"api\.param\(params,\s*'([A-Za-z0-9_]+)'\s*\)")


def main():
    total = 0
    for fn in sorted(os.listdir(API)):
        if not (fn.startswith('handlers') and fn.endswith('.py')):
            continue
        p = os.path.join(API, fn)
        src = open(p, encoding='utf-8').read()
        n = [0]

        def rep(m):
            key = m.group(1)
            if key in NUM or key in INT2:
                n[0] += 1
                return "api.param(params, '%s', 0)" % key
            if key in STR:
                n[0] += 1
                return "api.param(params, '%s', '')" % key
            if key in BOOL:
                n[0] += 1
                return "api.param(params, '%s', False)" % key
            if key in LIST:
                n[0] += 1
                return "api.int_list_param(params, '%s')" % key
            return m.group(0)

        out = PAT.sub(rep, src)
        if n[0]:
            open(p, 'w', encoding='utf-8').write(out)
            print('  %-34s 补默认值 %d 处' % (fn, n[0]))
            total += n[0]
    print('\n合计 %d 处' % total)

    left = []
    for fn in sorted(os.listdir(API)):
        if fn.startswith('handlers') and fn.endswith('.py'):
            src = open(os.path.join(API, fn), encoding='utf-8').read()
            for m in PAT.finditer(src):
                left.append((fn, m.group(1)))
    if left:
        print('\n仍未补（非数字/非字符串类型，需人工确认）:')
        for fn, k in left:
            print('   %-30s %s' % (fn, k))
    return 0


if __name__ == '__main__':
    sys.exit(main())
