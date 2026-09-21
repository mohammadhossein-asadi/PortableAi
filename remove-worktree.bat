@echo off
setlocal EnableExtensions EnableDelayedExpansion

title PortableAI - Worktree Remover

REM ============================================================
REM PortableAI - Worktree Remover
REM ============================================================
REM
REM Safely removes a worktree sandbox created by
REM create-worktree.bat:
REM
REM   1. Checks for uncommitted changes (asks before discarding)
REM   2. Checks for commits not merged into master (asks first)
REM   3. Removes the worktree folder and its registration
REM   4. Offers to delete the worktree/<name> branch
REM
REM Usage:
REM   remove-worktree.bat <name>
REM   remove-worktree.bat            (interactive)
REM
REM List existing worktrees with:
REM   git worktree list
REM ============================================================


REM ============================================================
REM PATH CONFIGURATION
REM ============================================================

cd /d "%~dp0"

set "ROOT=%CD%"

set "WORKTREE_DIR=%ROOT%\worktrees"


REM ============================================================
REM BANNER
REM ============================================================

cls

echo.
echo ============================================================
echo            PortableAI - Worktree Remover
echo ============================================================
echo.


REM ============================================================
REM CHECK GIT
REM ============================================================

echo [1/6] Checking for git...

where git >nul 2>&1

if errorlevel 1 (

    echo.
    echo [ERROR] git was not found in PATH.
    echo.

    pause
    exit /b 1
)

echo [OK] git found.
echo.


REM ============================================================
REM WORKTREE NAME
REM ============================================================

set "WORKTREE_NAME=%~1"

if "%WORKTREE_NAME%"=="" (
    set /p "WORKTREE_NAME=Enter the name of the worktree to remove: "
)

if "%WORKTREE_NAME%"=="" (

    echo.
    echo [ERROR] No name given.
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
echo Worktree:
echo   %WT_PATH%
echo.
echo Branch:
echo   %BRANCH_NAME%
echo.


REM ============================================================
REM CHECK WORKTREE EXISTS
REM ============================================================

echo [2/6] Checking the worktree...

if not exist "%WT_PATH%\.git" (

    echo.
    echo [ERROR] No worktree found at:
    echo   %WT_PATH%
    echo.
    echo Existing worktrees:
    echo.

    git worktree list

    echo.
    pause
    exit /b 1
)

echo [OK] Worktree found.
echo.


REM ============================================================
REM UNCOMMITTED CHANGES CHECK
REM ============================================================

echo [3/6] Checking for uncommitted changes...

set "IS_DIRTY=0"

git -C "%WT_PATH%" diff --quiet >nul 2>&1

if errorlevel 1 set "IS_DIRTY=1"

git -C "%WT_PATH%" diff --cached --quiet >nul 2>&1

if errorlevel 1 set "IS_DIRTY=1"

if "%IS_DIRTY%"=="1" (

    echo.
    echo [WARNING] This worktree has UNCOMMITTED changes.
    echo.
    echo Removing it will DISCARD them permanently.
    echo.

    set /p "CONFIRM_DIRTY=Discard uncommitted changes and continue? [y/N]: "

    if /I not "!CONFIRM_DIRTY!"=="y" (
        echo.
        echo Cancelled - nothing was removed.
        echo.
        pause
        exit /b 1
    )

) else (

    echo [OK] No uncommitted changes.
)

echo.


REM ============================================================
REM UNMERGED COMMITS CHECK
REM ============================================================

echo [4/6] Checking for commits not in master...

set "AHEAD=0"

for /f "delims=" %%C in ('git -C "%WT_PATH%" rev-list --count "%BASE_BRANCH%..%BRANCH_NAME%" 2^>nul') do set "AHEAD=%%C"

if "%AHEAD%"=="0" (

    echo [OK] All commits are already in %BASE_BRANCH%.

) else (

    echo.
    echo [WARNING] This branch has %AHEAD% commit^(s^) NOT merged into %BASE_BRANCH%:
    echo.

    git -C "%WT_PATH%" log --oneline "%BASE_BRANCH%..%BRANCH_NAME%"

    echo.

    set /p "CONFIRM_AHEAD=Delete the branch and lose these commits? [y/N]: "

    if /I not "!CONFIRM_AHEAD!"=="y" (
        echo.
        echo Keeping the branch. The worktree folder is still removed.
        echo.
        echo Keep the work with:
        echo   git merge %BRANCH_NAME%
        echo   git branch -d %BRANCH_NAME%
        echo.
        goto REMOVE_WORKTREE
    )

    echo Proceeding - branch commits will be discarded.
)

echo.


REM ============================================================
REM REMOVE WORKTREE
REM ============================================================

:REMOVE_WORKTREE

echo [5/6] Removing the worktree...

git worktree remove --force "%WT_PATH%"

if errorlevel 1 (

    echo.
    echo [ERROR] git worktree remove failed.
    echo.
    echo Try manually:
    echo   git worktree remove --force "%WT_PATH%"
    echo   git worktree prune
    echo.

    pause
    exit /b 1
)

echo [OK] Worktree removed.
echo.


REM ============================================================
REM BRANCH CLEANUP
REM ============================================================

echo [6/6] Cleaning up the branch...

git show-ref --verify --quiet "refs/heads/%BRANCH_NAME%"

if errorlevel 1 (

    echo [SKIP] Branch no longer exists.

    goto BRANCH_DONE
)

if "%AHEAD%"=="0" (

    git branch -d "%BRANCH_NAME%" >nul 2>&1

    echo [OK] Branch deleted:
    echo   %BRANCH_NAME%

) else (

    echo [SKIP] Branch kept because it still has unmerged commits:
    echo   %BRANCH_NAME%
    echo.
    echo Merge it first, then delete it:
    echo   git merge %BRANCH_NAME%
    echo   git branch -d %BRANCH_NAME%
    echo   - or force-delete with: git branch -D %BRANCH_NAME%
)

:BRANCH_DONE

echo.


REM ============================================================
REM SUMMARY
REM ============================================================

echo ============================================================
echo                    REMOVAL COMPLETE
echo ============================================================
echo.
echo   Remaining worktrees:
echo.

git worktree list

echo.
echo ============================================================
echo.

pause

endlocal
