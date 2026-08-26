@echo off
REM ============================================================
REM  File List Generator - Launcher (standard Python only)
REM  Put this bat, filelist.py and filelist.exe into any folder,
REM  then double-click. It works with or without Python:
REM    - Python 3 found: run filelist.py
REM    - No Python:     auto-run filelist.exe
REM  NO WorkBuddy dependency.
REM ============================================================
setlocal
set "PY="

REM --- 1) Windows py launcher ---
where py >nul 2>&1 && for /f "usebackq delims=" %%i in (`py -3 -c "import sys; print(sys.executable)"`) do if not defined PY set "PY=%%i"

REM --- 2) python on PATH ---
if not defined PY (
    where python >nul 2>&1 && for /f "tokens=*" %%i in ('python --version 2^>^&1') do (
        echo %%i| findstr /r /i "Python [0-9]" >nul 2>&1 && set "PY=python"
    )
)

REM --- 3) common install directories ---
if not defined PY (
    for %%p in (
        "%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
        "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
        "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
        "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
        "C:\Python313\python.exe"
        "C:\Python312\python.exe"
        "C:\Python311\python.exe"
        "C:\Python310\python.exe"
    ) do if not defined PY if exist %%p set "PY=%%~p"
)

REM --- 4) No Python? Fall back to the standalone exe ---
if not defined PY (
    if exist "%~dp0filelist.exe" (
        echo [INFO] No Python found, running filelist.exe ...
        "%~dp0filelist.exe" %*
        goto :end
    )
    echo [ERROR] Python 3 not found and filelist.exe is missing.
    echo         Install Python from python.org and check "Add python.exe to PATH",
    echo         or put filelist.exe in this folder.
    goto :end
)

echo [INFO] Python: %PY%
echo [INFO] Script: %~dp0filelist.py
echo [INFO] Scan  : %~dp0
echo.

"%PY%" "%~dp0filelist.py" %*
echo.

:end
echo [DONE] Press any key to close this window...
pause >nul
endlocal
