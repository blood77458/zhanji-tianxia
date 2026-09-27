@echo off
setlocal
rem Portable launcher — works from any checkout path.
cd /d "%~dp0"

rem Manifest MD5 must match the client APK's assets/static_config.<md5>.xml
if not defined CANON_MANIFEST_MD5 set CANON_MANIFEST_MD5=81c8ede8d76998cd852173d537c04aac

rem Prefer `py` launcher, then python on PATH, then common Conda install.
where py >nul 2>&1 && (
  py -3 -u canon_server.py
  goto :eof
)
where python >nul 2>&1 && (
  python -u canon_server.py
  goto :eof
)
if exist "D:\conda\python.exe" (
  "D:\conda\python.exe" -u canon_server.py
  goto :eof
)

echo [ERROR] Python 3 not found. Install Python 3.10+ and re-run.
exit /b 1
