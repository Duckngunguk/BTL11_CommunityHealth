@echo off
chcp 65001 > nul
echo =======================================================================
echo 🚀 KHOỞI ĐỘNG 3 PHÂN QUYỀN (ROLES) CHẠY ĐỒNG THỜI - COMMUNITY HEALTH
echo =======================================================================
echo.
echo [1/3] Khởi động Role 1: Cán bộ Y tế (Ứng dụng Windows Desktop)
start "Can Bo Ye Te (Windows)" cmd /k "D:\flutter\bin\flutter.bat run -d windows"

echo [2/3] Khởi động Role 2: Phụ huynh (Chạy trên trình duyệt Chrome)
start "Phu Huynh (Chrome)" cmd /k "D:\flutter\bin\flutter.bat run -d chrome"

echo [3/3] Khởi động Role 3: Cổng Web Quản trị Admin (Chạy trên trình duyệt Edge)
start "Admin Web (Edge)" cmd /k "D:\flutter\bin\flutter.bat run -t lib/main_admin.dart -d edge"

echo.
echo =======================================================================
echo ✅ Đã kích hoạt 3 phiên làm việc trong các cửa sổ CMD riêng biệt!
echo Bạn có thể nhấn 'r' ở từng cửa sổ CMD để Hot Reload độc lập.
echo =======================================================================
pause
