#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""按 glob+行号打印源码上下文: python ctx.py <glob> <start> <end> [glob start end ...]"""
import sys, glob, io, os

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
args = sys.argv[1:]
i = 0
while i < len(args):
    pat, a, b = args[i], int(args[i + 1]), int(args[i + 2])
    i += 3
    for p in glob.glob(pat):
        L = open(p, encoding='utf-8', errors='replace').read().split('\n')
        print('---- %s:%d-%d' % (p, a, b))
        for k in range(max(0, a - 1), min(len(L), b)):
            print('%5d| %s' % (k + 1, L[k]))
        print()
