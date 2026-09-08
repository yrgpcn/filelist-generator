@echo off
REM ============================================================
REM  File List Generator - Launcher (standard Python only)
REM  Put this bat, filelist.py and filelist exe into any folder,
REM  then double-click. It works with or without Python:
REM    - Python 3 found: run filelist.py
REM    - No Python:     auto-run the standalone exe
REM      (filelist.exe or filelist-vX.Y.Z.exe, newest first)
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

REM --- 4) Python found? run the script ---
if defined PY goto :run_py

REM --- 5) No Python. Fall back to the standalone exe ---
set "EXE="
if exist "%~dp0filelist.exe" set "EXE=%~dp0filelist.exe"
if not defined EXE for /f "delims=" %%f in ('dir /b /a-d /o-d "%~dp0filelist-v*.exe" 2^>nul') do if not defined EXE set "EXE=%~dp0%%f"
if not defined EXE goto :noexe
echo [INFO] No Python found, running standalone exe: %EXE%
"%EXE%" %*
goto :end

:noexe
echo [ERROR] Python 3 not found and no filelist exe in this folder.
echo         Install Python from python.org and check "Add python.exe to PATH",
echo         or put filelist.exe / filelist-vX.Y.Z.exe in this folder.
goto :end

:run_py
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
