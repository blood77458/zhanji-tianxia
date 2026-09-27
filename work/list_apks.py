import zipfile, re, os, time

W = r"E:\deepseek_projects\app_server\work"
for fn in sorted(os.listdir(W)):
    if not fn.endswith(".apk"):
        continue
    p = os.path.join(W, fn)
    try:
        z = zipfile.ZipFile(p)
        mans = [n for n in z.namelist()
                if re.fullmatch(r"assets/static_config\.[0-9a-f]{32}\.xml", n)]
        man = mans[0].split(".")[1] if mans else "NONE"
        n_entries = len(z.namelist())
        injected = sum(1 for n in z.namelist() if "d08ea88ca145c6e57514d263ce8983da" in n)
    except Exception as e:
        man, n_entries, injected = "ERR:%s" % e, 0, 0
    print("%-30s %8.1fMB  mtime=%s  manifest=%-34s entries=%-5d injected=%d"
          % (fn, os.path.getsize(p) / 1048576,
             time.strftime("%H:%M:%S", time.localtime(os.path.getmtime(p))),
             man, n_entries, injected))
