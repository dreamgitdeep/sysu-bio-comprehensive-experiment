@echo off
chcp 65001 >nul
cd /d "%~dp0"
set PORT=8000

echo.
echo   ============================================
echo    本地预览服务
echo   ============================================
echo.

rem 优先使用 py 启动器，其次 python
set "PYCMD="
where py >nul 2>nul && set "PYCMD=py"
if not defined PYCMD (
  where python >nul 2>nul && set "PYCMD=python"
)

if not defined PYCMD (
  echo   未检测到 Python，改用浏览器直接打开文件。
  echo   （若页面图片未显示，请安装 Python 后重试）
  echo.
  start "" "index.html"
  exit /b 0
)

echo   预览地址: http://localhost:%PORT%/index.html
echo   主方案页: http://localhost:%PORT%/吴-项目方案交流文件.html
echo.
echo   停止预览: 在本窗口按 Ctrl+C，或直接关闭本窗口
echo.

start "" http://localhost:%PORT%/index.html
%PYCMD% -m http.server %PORT%
