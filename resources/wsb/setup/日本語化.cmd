@echo off
powershell Set-WinUserLanguageList -Force ja-JP
powershell Set-WinSystemLocale -SystemLocale ja-JP
powershell Set-WinUILanguageOverride -Language ja-JP
powershell Set-WinHomeLocation 122
mshta vbscript:execute("MsgBox(""���{�ꉻ����������ɂ͍ċN�����K�v�ł��B"" & vbCRLF & ""OK�������Ǝ����I��Windows�T���h�{�b�N�X���ċN�����܂��B""):close")
powershell Restart-Computer
