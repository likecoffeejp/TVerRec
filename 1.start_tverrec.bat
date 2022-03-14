@echo off
rem ###################################################################################
rem #  TVerRec : TVerビデオダウンローダ
rem #
rem #		一括ダウンロード処理開始スクリプト
rem #
rem #	Copyright (c) 2021 dongaba
rem #
rem #	Licensed under the Apache License, Version 2.0 (the "License");
rem #	you may not use this file except in compliance with the License.
rem #	You may obtain a copy of the License at
rem #
rem #		http://www.apache.org/licenses/LICENSE-2.0
rem #
rem #	Unless required by applicable law or agreed to in writing, software
rem #	distributed under the License is distributed on an "AS IS" BASIS,
rem #	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem #	See the License for the specific language governing permissions and
rem #	limitations under the License.
rem #
rem ###################################################################################

rem 文字コードをUTF8に
chcp 65001

setlocal enabledelayedexpansion
cd %~dp0

title TVerRec

for /f %%i in ('hostname') do set HostName=%%i
set PIDFile=pid-%HostName%.txt
set retryTime=600
set sleepTime=3600

for /f "tokens=2" %%i in ('tasklist /FI "WINDOWTITLE eq TVerRec" /NH') do set myPID=%%i
echo %myPID% > %PIDFile%

:Loop

	if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
		pwsh -NoProfile -ExecutionPolicy Unrestricted .\src\tverrec_bulk.ps1
	) else (
		powershell -NoProfile -ExecutionPolicy Unrestricted .\src\tverrec_bulk.ps1
	)

:ProcessChecker
	rem yt-dlpプロセスチェック
	timeout /T %retryTime% /nobreak > nul
	tasklist | findstr /i "ffmpeg yt-dlp" > nul 2>&1
	if %ERRORLEVEL% == 0 (
		echo ダウンロードが進行中です...
		tasklist /v | findstr /i "ffmpeg yt-dlp" 
		echo %retryTime%秒待機します...
		timeout /T %retryTime% /nobreak > nul
		goto ProcessChecker
	)

	if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
		pwsh -NoProfile -ExecutionPolicy Unrestricted .\src\validate_video.ps1
		pwsh -NoProfile -ExecutionPolicy Unrestricted .\src\validate_video.ps1

		pwsh -NoProfile -ExecutionPolicy Unrestricted .\src\move_video.ps1

		pwsh -NoProfile -ExecutionPolicy Unrestricted .\src\delete_ignored.ps1
	) else (
		powershell -NoProfile -ExecutionPolicy Unrestricted .\src\validate_video.ps1
		powershell -NoProfile -ExecutionPolicy Unrestricted .\src\validate_video.ps1

		powershell -NoProfile -ExecutionPolicy Unrestricted .\src\move_video.ps1

		powershell -NoProfile -ExecutionPolicy Unrestricted .\src\delete_ignored.ps1
	)

	echo %sleepTime%秒待機します...
	timeout /T %sleepTime% /nobreak > nul

	goto Loop

:End
	del %PIDFile%
	pause
