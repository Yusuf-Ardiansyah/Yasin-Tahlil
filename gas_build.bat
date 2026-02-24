@echo off
echo [1/4] Membersihkan Proyek...
call flutter clean

echo [2/4] Memulai Build APK (Split per ABI)...
call flutter build apk --release --split-per-abi

echo [3/4] Memulai Backup JKS Aman...
if not exist "D:\Backup_JKS" mkdir "D:\Backup_JKS"
copy "android\app\ILOVEYOU.jks" "D:\Backup_JKS\ILOVEYOU_backup.jks" /Y

echo [4/4] Membuka Folder Hasil Build...
start "" "build\app\outputs\flutter-apk\"

echo.
echo ======================================================
echo BERHASIL! APK siap diinstal dan JKS aman di Drive D.
echo Silakan pilih file arm64-v8a untuk HP ASUS kamu.
echo ======================================================
pause