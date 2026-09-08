@echo off
chcp 65001 >nul
cd /d "%~dp0"

rem 用法：sync.cmd "本次改了什么"
rem 不带参数时自动使用「更新方案内容」作为说明

where git >nul 2>nul
if errorlevel 1 (
  echo   未检测到 Git，请先安装：https://git-scm.com/
  pause
  exit /b 1
)

set "MSG=%~1"
if not defined MSG set "MSG=更新方案内容"

echo.
echo   ============================================
echo    同步到 GitHub
echo   ============================================
echo.
echo   [1/4] 拉取远程最新版本...
git pull --rebase
if errorlevel 1 (
  echo.
  echo   拉取失败，可能本地有未提交的改动。
  echo   请先处理冲突，或手动执行 git status 查看。
  pause
  exit /b 1
)

echo.
echo   [2/4] 暂存本地改动...
git add -A

echo.
echo   [3/4] 提交：%MSG%
git diff --cached --quiet
if not errorlevel 1 (
  echo   没有检测到任何改动，无需提交。
  echo.
  pause
  exit /b 0
)
git commit -m "%MSG%"
if errorlevel 1 (
  echo   提交失败。
  pause
  exit /b 1
)

echo.
echo   [4/4] 推送到 GitHub...
git push
if errorlevel 1 (
  echo   推送失败，请检查网络或 GitHub 登录状态。
  pause
  exit /b 1
)

echo.
echo   完成！约 1 分钟后在线预览自动更新：
echo   https://dreamgitdeep.github.io/sysu-bio-comprehensive-experiment/
echo.
pause
