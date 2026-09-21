@echo off
setlocal EnableExtensions EnableDelayedExpansion

title PortableAI - Worktree Sandbox Creator

REM ============================================================
REM PortableAI - Worktree Sandbox Creator
REM ============================================================
REM
REM Creates an isolated git worktree so the AI agent (or you)
REM can work on a separate branch without ever touching the
REM main checkout.
REM
REM What it does:
REM
REM   1. Creates branch  worktree/<name>  from the current HEAD
REM   2. Creates folder  worktrees\<name>  with the repo files
REM   3. Links  llama\  and  models\  from the main checkout
REM      with directory junctions (zero extra disk space, the
REM      sandbox can run models immediately)
REM   4. Copies  mcp\mcp.json  into the sandbox (untracked file)
REM   5. Adds per-worktree git exclusions so linked/copied files
REM      never show up in git status
REM
REM Usage:
REM   create-worktree.bat <name>
REM   create-worktree.bat            (interactive)
REM
REM Remove a worktree with:
REM   remove-worktree.bat <name>
REM ============================================================


REM ============================================================
REM PATH CONFIGURATION
REM ============================================================

cd /d "%~dp0"

set "ROOT=%CD%"

set "WORKTREE_DIR=%ROOT%\worktrees"

set "LLAMA_DIR=%ROOT%\llama"
set "MODELS_DIR=%ROOT%\models"
set "MCP_DIR=%ROOT%\mcp"

if not exist "%WORKTREE_DIR%" mkdir "%WORKTREE_DIR%" >nul 2>&1


REM ============================================================
REM BANNER
REM ============================================================

cls

echo.
echo ============================================================
echo           PortableAI - Worktree Sandbox Creator
echo ============================================================
echo.


REM ============================================================
REM CHECK GIT
REM ============================================================

echo [1/8] Checking for git...

where git >nul 2>&1

if errorlevel 1 (

    echo.
    echo [ERROR] git was not found in PATH.
    echo.
    echo Install git from https://git-scm.com and try again.
    echo.

    pause
    exit /b 1
)

echo [OK] git found.
echo.


REM ============================================================
REM CHECK REPOSITORY
REM ============================================================

echo [2/8] Checking git repository...

git rev-parse --is-inside-work-tree >nul 2>&1

if errorlevel 1 (

    echo.
    echo [ERROR] This is not a git repository.
    echo.
    echo Expected to run inside:
    echo %ROOT%
    echo.

    pause
    exit /b 1
)

echo [OK] Repository found.
echo.


REM ============================================================
REM WORKTREE NAME
REM ============================================================

set "WORKTREE_NAME=%~1"

if "%WORKTREE_NAME%"=="" (
    set /p "WORKTREE_NAME=Enter a name for the worktree: "
)

if "%WORKTREE_NAME%"=="" (

    echo.
    echo [ERROR] No name given.
    echo.

    pause
    exit /b 1
)

REM Trim trailing spaces and dots (invalid at the end of folder names)

:STRIP_LOOP

if "%WORKTREE_NAME%"=="" goto STRIP_DONE

if not "%WORKTREE_NAME:~-1%"==" " if not "%WORKTREE_NAME:~-1%"=="." goto STRIP_DONE

set "WORKTREE_NAME=%WORKTREE_NAME:~0,-1%"

goto STRIP_LOOP

:STRIP_DONE

if "%WORKTREE_NAME%"=="" (

    echo.
    echo [ERROR] Name is empty after cleanup.
    echo.

    pause
    exit /b 1
)

REM Reject spaces, quotes and ampersands (they break batch expansion
REM and shell commands). Uses the substitution-compare trick so the
REM check cannot misfire on ordinary letters.

if not "%WORKTREE_NAME%"=="%WORKTREE_NAME: =%" (

    echo.
    echo [ERROR] The name must not contain spaces.
    echo.

    pause
    exit /b 1
)

if not "%WORKTREE_NAME%"=="%WORKTREE_NAME:&=%" (

    echo.
    echo [ERROR] The name must not contain the "&" character.
    echo.

    pause
    exit /b 1
)

if not "%WORKTREE_NAME%"=="%WORKTREE_NAME:"=%" (

    echo.
    echo [ERROR] The name must not contain quotes.
    echo.

    pause
    exit /b 1
)

set "BRANCH_NAME=worktree/%WORKTREE_NAME%"
set "WT_PATH=%WORKTREE_DIR%\%WORKTREE_NAME%"

REM Base branch = whatever the main checkout currently has checked out

set "BASE_BRANCH=master"

for /f "delims=" %%B in ('git -C "%ROOT%" rev-parse --abbrev-ref HEAD 2^>nul') do set "BASE_BRANCH=%%B"

echo.
echo Worktree name:
echo   %WORKTREE_NAME%
echo.
echo Branch:
echo   %BRANCH_NAME%
echo.
echo Folder:
echo   %WT_PATH%
echo.


REM ============================================================
REM CONFLICT CHECKS
REM ============================================================

echo [3/8] Checking for conflicts...

if exist "%WT_PATH%" (

    if not exist "%WT_PATH%\.git" (

        REM Stale leftover folder (e.g. a crashed run or manual
        REM deletion) - it is not a registered worktree anymore.

        echo [WARN] Stale leftover folder found:
        echo   %WT_PATH%
        echo.
        echo It is not a registered worktree.
        echo.

        set /p "CONFIRM_STALE=Delete the leftover folder and continue? [y/N]: "

        if /I not "!CONFIRM_STALE:~0,1!"=="y" (

            echo.
            echo Cancelled. Remove it manually:
            echo   rmdir /s /q "%WT_PATH%"
            echo.

            pause
            exit /b 1
        )

        REM Clear junctions first - a plain rmdir on a junction
        REM deletes only the link, never the linked target folder.

        if exist "%WT_PATH%\llama" rmdir "%WT_PATH%\llama" >nul 2>&1
        if exist "%WT_PATH%\models" rmdir "%WT_PATH%\models" >nul 2>&1

        rmdir /s /q "%WT_PATH%" >nul 2>&1

        if exist "%WT_PATH%" (

            echo.
            echo [ERROR] Could not delete the leftover folder.
            echo A file may be locked - close programs using it and retry.
            echo.

            pause
            exit /b 1
        )

        echo [OK] Leftover folder removed.
        echo.

    ) else (

        echo.
        echo [ERROR] Folder already exists and is a registered worktree:
        echo   %WT_PATH%
        echo.
        echo Remove it first:
        echo   remove-worktree.bat %WORKTREE_NAME%
        echo.

        pause
        exit /b 1
    )
)

git show-ref --verify --quiet "refs/heads/%BRANCH_NAME%"

if not errorlevel 1 (

    echo.
    echo [ERROR] Branch already exists:
    echo   %BRANCH_NAME%
    echo.
    echo Either reuse it:
    echo   git worktree add "%WT_PATH%" "%BRANCH_NAME%"
    echo.
    echo Or delete it first:
    echo   git branch -D "%BRANCH_NAME%"
    echo.

    pause
    exit /b 1
)

echo [OK] No conflicts.
echo.


REM ============================================================
REM UNCOMMITTED CHANGES WARNING
REM ============================================================

echo [4/8] Checking for uncommitted changes...

set "IS_DIRTY=0"

git diff --quiet >nul 2>&1

if errorlevel 1 set "IS_DIRTY=1"

git diff --cached --quiet >nul 2>&1

if errorlevel 1 set "IS_DIRTY=1"

if "%IS_DIRTY%"=="1" (

    echo.
    echo [WARNING] You have uncommitted changes.
    echo.
    echo The new worktree branches from the last COMMIT.
    echo Uncommitted changes will NOT appear in it.
    echo.
    set /p "CONFIRM_DIRTY=Continue anyway? [y/N]: "

    if /I not "!CONFIRM_DIRTY:~0,1!"=="y" (
        echo.
        echo Cancelled.
        echo.
        pause
        exit /b 1
    )

) else (

    echo [OK] Working tree clean.
)

echo.


REM ============================================================
REM CREATE WORKTREE
REM ============================================================

echo [5/8] Creating worktree and branch...

git worktree add "%WT_PATH%" -b "%BRANCH_NAME%"

if errorlevel 1 (

    echo.
    echo [ERROR] git worktree add failed.
    echo.
    echo Check the error above. Common causes:
    echo   - invalid characters in the name
    echo   - stale worktree records (fix: git worktree prune^)
    echo.

    pause
    exit /b 1
)

echo.
echo [OK] Worktree created:
echo   %WT_PATH%
echo.


REM ============================================================
REM LINK LLAMA AND MODELS
REM ============================================================

echo [6/8] Linking llama\ and models\ from the main checkout...
echo.

REM llama\ contains huge binaries which are NOT tracked by git.
REM A fresh worktree would not have them, so they are linked
REM with a directory junction - no admin rights, no extra
REM disk space, fully functional.

if exist "%LLAMA_DIR%\llama-server.exe" (

    REM A leftover empty/partial folder (e.g. from a tracked file)
    REM would block the junction, so clear it first. Any deleted
    REM tracked files are recoverable from git.

    if exist "%WT_PATH%\llama" rmdir /s /q "%WT_PATH%\llama" >nul 2>&1

    mklink /J "%WT_PATH%\llama" "%LLAMA_DIR%" >nul 2>&1

    if errorlevel 1 (
        echo [WARN] Could not link llama\. Copy it manually if needed.
    ) else (
        echo [OK] llama\ linked from the main checkout - no extra disk space used.
    )

) else (

    echo [SKIP] llama\llama-server.exe not found in the main checkout.
    echo        Finish Step 2 of the README, then copy or re-link it manually.
)

echo.

if exist "%MODELS_DIR%\*.gguf" (

    if exist "%WT_PATH%\models" rmdir /s /q "%WT_PATH%\models" >nul 2>&1

    mklink /J "%WT_PATH%\models" "%MODELS_DIR%" >nul 2>&1

    if errorlevel 1 (
        echo [WARN] Could not link models\. Copy them manually if needed.
    ) else (
        echo [OK] models\ linked from the main checkout - no extra disk space used.
    )

) else (

    echo [SKIP] No GGUF models in:
    echo        %MODELS_DIR%
    echo        Nothing to link.
)

echo.


REM ============================================================
REM COPY MCP CONFIG
REM ============================================================

echo [7/8] Copying MCP config...

if exist "%MCP_DIR%\mcp.json" (

    if not exist "%WT_PATH%\mcp" mkdir "%WT_PATH%\mcp" >nul 2>&1

    copy /Y "%MCP_DIR%\mcp.json" "%WT_PATH%\mcp\mcp.json" >nul 2>&1

    echo [OK] mcp\mcp.json copied into the worktree.

) else (

    echo [SKIP] No mcp\mcp.json found in the main checkout.
    echo        See mcp\mcp.json.example to create one.
)

echo.


REM ============================================================
REM PER-WORKTREE GIT EXCLUSIONS
REM ============================================================

echo [8/8] Adding per-worktree git exclusions...

set "WT_GITDIR="

for /f "delims=" %%G in ('git -C "%WT_PATH%" rev-parse --git-dir 2^>nul') do set "WT_GITDIR=%%G"

if not defined WT_GITDIR (

    echo [WARN] Could not locate the worktree git dir - skipping.
    echo        Linked files may show as untracked in git status.
    echo.
    goto EXCLUSIONS_DONE
)

set "WT_GITDIR=%WT_GITDIR:/=\%"

if not exist "%WT_GITDIR%\info" mkdir "%WT_GITDIR%\info" >nul 2>&1

(
    echo # PortableAI worktree sandbox - local exclusions ^(per-worktree, not tracked^)
    echo /llama/
    echo /models/
    echo /mcp/mcp.json
) > "%WT_GITDIR%\info\exclude"

echo [OK] Exclusions written to:
echo   %WT_GITDIR%\info\exclude

:EXCLUSIONS_DONE

echo.


REM ============================================================
REM SUMMARY
REM ============================================================

echo ============================================================
echo                    WORKTREE READY
echo ============================================================
echo.
echo   Folder:
echo     %WT_PATH%
echo.
echo   Branch:
echo     %BRANCH_NAME%
echo.
echo   Run the agent inside the sandbox:
echo     cd worktrees\%WORKTREE_NAME%
echo     run-llama.bat
echo.
echo   The main checkout stays clean:
echo     git -C "%ROOT%" status
echo.
echo   Compare / merge the results later:
echo     git diff %BASE_BRANCH% %BRANCH_NAME%
echo     git merge %BRANCH_NAME%
echo.
echo   Remove this worktree when done:
echo     remove-worktree.bat %WORKTREE_NAME%
echo.
echo ============================================================
echo.

pause

endlocal
