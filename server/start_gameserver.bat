@echo off
setlocal
cd /d "%~dp0"

if not defined CANON_MANIFEST_MD5 set CANON_MANIFEST_MD5=81c8ede8d76998cd852173d537c04aac

set PY=
where py >nul 2>&1 && set PY=py -3
if not defined PY where python >nul 2>&1 && set PY=python
if not defined PY if exist "D:\conda\python.exe" set PY=D:\conda\python.exe
if not defined PY (
  echo [ERROR] Python 3 not found. Install Python 3.10+ and re-run.
  exit /b 1
)

if not exist "canon.db" (
  echo [init] canon.db missing — running init_db.py ...
  %PY% init_db.py
  if errorlevel 1 exit /b 1
)

%PY% -u gameserver.py %*
