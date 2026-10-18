"""把 work/lua_cmp 里 solo_/ours_ 成对文件做统一 diff，给出「实质差异」报告。

判断口径：
  * 只差空白/注释        -> 视为「无功能差异」
  * 有实质差异           -> 统计增删行，并把关键片段摘出来
"""
import difflib
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
OUT = r'E:\deepseek_projects\app_server\work\lua_cmp'
REPORT = r'E:\deepseek_projects\app_server\work\lua_cmp\DIFF_REPORT.txt'


def read(p):
    return open(p, 'rb').read().decode('utf-8', 'replace').splitlines()


def norm(line):
    """去掉注释和行尾空白后的内容行，用于判断「实质差异」。"""
    s = line.strip()
    if s.startswith('--'):
        return ''
    s = re.sub(r'\s*--.*$', '', s)
    return s


def main():
    pairs = sorted({f[5:] for f in os.listdir(OUT) if f.startswith('solo_')})
    out = []
    subst = []
    tw = 0
    for name in pairs:
        a = read(os.path.join(OUT, 'solo_' + name))
        b = read(os.path.join(OUT, 'ours_' + name))
        na = [norm(x) for x in a]
        nb = [norm(x) for x in b]
        if na == nb:
            out.append('%-58s 只差注释/空白 (%d/%d 行)' % (name, len(a), len(b)))
            continue
        d = list(difflib.unified_diff(na, nb, 'solo', 'ours', lineterm='', n=1))
        add = sum(1 for x in d if x.startswith('+') and not x.startswith('+++'))
        rem = sum(1 for x in d if x.startswith('-') and not x.startswith('---'))
        tw += 1
        subst.append((add + rem, name, add, rem, d))
        out.append('%-58s 差异行 +%d/-%d (solo %d 行 / ours %d 行)'
                   % (name, add, rem, len(a), len(b)))

    subst.sort(reverse=True)
    lines = ['=' * 78, '一、总览', '=' * 78]
    lines += out
    lines += ['', '实质差异文件数: %d / %d' % (tw, len(pairs)), '']

    lines += ['=' * 78, '二、按差异量排序的明细（前 25 个）', '=' * 78]
    for weight, name, add, rem, d in subst[:25]:
        lines.append('')
        lines.append('#' * 70)
        lines.append('# %s   +%d/-%d' % (name, add, rem))
        lines.append('#' * 70)
        lines += d[:80]

    txt = '\n'.join(lines)
    open(REPORT, 'w', encoding='utf-8').write(txt)
    print(txt[:12000])
    print('\n...(完整报告: %s)' % REPORT)


if __name__ == '__main__':
    main()
