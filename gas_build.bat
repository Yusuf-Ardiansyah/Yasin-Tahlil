@echo off
title Gas Build Sultan - Obfuscated Edition (Auto-Date)

:: Mengambil tanggal dan waktu pakai PowerShell biar formatnya rapi
FOR /F "tokens=*" %%g IN ('powershell -Command "Get-Date -format 'yyyyMMdd_HHmmss'"') do (SET DATETIME=%%g)

echo [1/5] Membersihkan Proyek...
call flutter clean

echo [2/5] Mengambil Package Terbaru...
call flutter pub get

echo [3/5] Memulai Build APK (Sultan Version)...
call flutter build apk --release --obfuscate --split-debug-info=./debug_info --split-per-abi

echo [4/5] Memulai Backup JKS Aman...
if not exist "D:\AndroidStudioProjects\Backup_JKS" mkdir "D:\AndroidStudioProjects\Backup_JKS"
copy "android\app\ILOVEYOU.jks" "D:\AndroidStudioProjects\Backup_JKS\ILOVEYOU_backup_%DATETIME%.jks" /Y

echo [5/5] Membuka Folder Hasil Build...
start "" "build\app\outputs\flutter-apk\"

echo.
echo ======================================================
echo BERHASIL! APK SULTAN TELAH TERENKRIPSI.
echo File Backup JKS: ILOVEYOU_backup_%DATETIME%.jks
echo Lokasi: D:\AndroidStudioProjects\yasin_tahlil
echo ======================================================
pause