@echo off

echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo WinGet���C���X�g�[�����邽�߂ɕK�v�ȃ\�t�g�E�F�A���C���X�g�[�����܂�...
if "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (
	powershell Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile %TEMP%\Microsoft.VCLibs.x64.14.00.Desktop.appx
	powershell Add-AppxPackage %TEMP%\Microsoft.VCLibs.x64.14.00.Desktop.appx
	del /q %TEMP%\Microsoft.VCLibs.x64.14.00.Desktop.appx

	powershell Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx -OutFile %TEMP%\Microsoft.UI.Xaml.2.8.x64.appx
	powershell Add-AppxPackage %TEMP%\Microsoft.UI.Xaml.2.8.x64.appx
	del /q %TEMP%\Microsoft.UI.Xaml.2.8.x64.appx
)
if "%PROCESSOR_ARCHITECTURE%" EQU "IA64" (
	powershell Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile %TEMP%\Microsoft.VCLibs.x64.14.00.Desktop.appx
	powershell Add-AppxPackage %TEMP%\Microsoft.VCLibs.x64.14.00.Desktop.appx
	del /q %TEMP%\Microsoft.VCLibs.x64.14.00.Desktop.appx

	powershell Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx -OutFile %TEMP%\Microsoft.UI.Xaml.2.8.x64.appx
	powershell Add-AppxPackage %TEMP%\Microsoft.UI.Xaml.2.8.x64.appx
	del /q %TEMP%\Microsoft.UI.Xaml.2.8.x64.appx
)
if "%PROCESSOR_ARCHITECTURE%" EQU "ARM64" (
	powershell Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.arm64.14.00.Desktop.appx -OutFile %TEMP%\Microsoft.VCLibs.arm64.14.00.Desktop.appx
	powershell Add-AppxPackage %TEMP%\Microsoft.VCLibs.arm64.14.00.Desktop.appx
	del /q %TEMP%\Microsoft.VCLibs.arm64.14.00.Desktop.appx

	powershell Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.arm64.appx -OutFile %TEMP%\Microsoft.UI.Xaml.2.8.arm64.appx
	powershell Add-AppxPackage %TEMP%\Microsoft.UI.Xaml.2.8.arm64.appx
	del /q %TEMP%\Microsoft.UI.Xaml.2.8.arm64.appx
)

echo.
echo WinGet���C���X�g�[�����܂�...
powershell Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile %TEMP%\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
powershell Add-AppxPackage %TEMP%\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
del /q %TEMP%\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle


echo.
echo �Ō��PowerShell���C���X�g�[�����܂�...
winget install Microsoft.PowerShell --accept-source-agreements --accept-package-agreements

echo.
mshta vbscript:execute("MsgBox(""PowerShell�̃C���X�g�[�����������܂����B""):close")

explorer.exe "C:\Users\WDAGUtilityAccount\Desktop\TVerRec\win"
