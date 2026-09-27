#!/usr/bin/env python3
"""Inspect static_config.xml: how virtual Lua paths map to hashed filenames."""
import re, os, sys

P = r"E:\deepseek_projects\app_server\work\extract\assets\static_config.0b608cebad1fc9c8ae2b5272bae229ff.xml"
t = open(P, "rb").read().decode("utf-8", "replace")
print("manifest size:", len(t))

cats = re.findall(r'<category value="([^"]*)"', t)
print("categories:", len(cats))
print("first 15:", cats[:15])
print()

# show the raw head so we can see the nesting
print("=== head (600 chars) ===")
print(t[:600])
print()

# find entries whose value contains a lua name
print("=== entries matching ThirdPlatformLogin / BaseRequest / LoginScene ===")
for m in re.finditer(r'<file\s+([^/>]*)/>', t):
    entry = m.group(1)
    if any(k in entry for k in ("ThirdPlatformLogin", "BaseRequest", "LoginScene")):
        s = max(0, m.start() - 260)
        e = min(len(t), m.end() + 120)
        print("--- entry ---")
        print(entry.strip()[:300])
        print("context:", t[s:e].replace("\n", " | ")[:420])
        print()

# how many .lua entries are there and what do they look like
lua_entries = [m.group(1) for m in re.finditer(r'<file\s+([^/>]*\.lua[^/>]*)/>', t)]
print("lua file entries:", len(lua_entries))
for e in lua_entries[:5]:
    print("   ", e.strip()[:200])
