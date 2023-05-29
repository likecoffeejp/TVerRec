###################################################################################
#
#		不要ファイル削除処理スクリプト
#
#	Copyright (c) 2022 dongaba
#
#	Licensed under the MIT License;
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#
#	The above copyright notice and this permission notice shall be included in
#	all copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#	THE SOFTWARE.
#
###################################################################################

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#環境設定
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Set-StrictMode -Version Latest
#----------------------------------------------------------------------
#初期化
try {
	if ($script:myInvocation.MyCommand.CommandType -eq 'ExternalScript') {
		$script:scriptRoot = Split-Path -Parent -Path $script:myInvocation.MyCommand.Definition
	} else { $script:scriptRoot = Convert-Path . }
	Set-Location $script:scriptRoot
	$script:confDir = $(Convert-Path $(Join-Path $script:scriptRoot '../conf'))
	$script:devDir = $(Join-Path $script:scriptRoot '../dev')
} catch { Write-Error 'カレントディレクトリの設定に失敗しました' ; exit 1 }
try {
	. $(Convert-Path (Join-Path $script:scriptRoot '../src/functions/initialize.ps1'))
	if ($? -eq $false) { exit 1 }
} catch { Write-Error '関数の読み込みに失敗しました' ; exit 1 }

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#メイン処理

#設定で指定したファイル・ディレクトリの存在チェック
checkRequiredFile

#======================================================================
#1/3 ダウンロードが中断した際にできたゴミファイルは削除
Write-Output '----------------------------------------------------------------------'
Write-Output '処理が中断した際にできたゴミファイルを削除します'
Write-Output '----------------------------------------------------------------------'
#進捗表示
showProgressToast `
	-Text1 'ファイルの掃除中' `
	-Text2 '　処理1/3 - ダウンロード中断時のゴミファイルを削除' `
	-WorkDetail '' `
	-Tag $script:appName `
	-Group 'Delete' `
	-Duration 'long' `
	-Silent $false

updateProgressToast `
	-Title $script:downloadWorkDir `
	-Rate $( 1 / 4 ) `
	-LeftText '' `
	-RightText '' `
	-Tag $script:appName `
	-Group 'Delete'

#処理 - 半日以上前のログファイル・ロックファイルを削除
$script:ffmpegErrorLogDir = `
	Split-Path $script:ffpmegErrorLogPath `
| Convert-Path
deleteFiles `
	-Path $script:ffmpegErrorLogDir `
	-Conditions 'ffmpeg_error_*.log' `
	-DatePast -0.5
deleteFiles `
	-Path $scriptRoot `
	-Conditions 'brightcovenew_*.lock' `
	-DatePast -0.5

#処理 - 7日以上前の無視リストのバックアップを削除
deleteFiles `
	-Path $script:confDir `
	-Conditions 'ignore.conf.*' `
	-DatePast -7

#進捗表示
updateProgressToast `
	-Title $script:downloadWorkDir `
	-Rate $( 2 / 4 ) `
	-LeftText '' `
	-RightText '' `
	-Tag $script:appName `
	-Group 'Delete'

#処理 - 作業ディレクトリ
deleteFiles `
	-Path $script:downloadWorkDir `
	-Conditions '*.ytdl, *.jpg, *.vtt, *.temp.mp4, *.part, *.mp4.part-Frag*, *.mp4' `
	-DatePast 0

#進捗表示
updateProgressToast `
	-Title $script:downloadBaseDir `
	-Rate $( 3 / 4 ) `
	-LeftText '' `
	-RightText '' `
	-Tag $script:appName `
	-Group 'Delete'

#処理 - ダウンロード先
deleteFiles `
	-Path $script:downloadBaseDir `
	-Conditions '*.ytdl, *.jpg, *.vtt, *.temp.mp4, *.part, *.mp4.part-Frag*' `
	-DatePast 0

if ($script:saveBaseDir -ne '') {
	foreach ($local:saveDir in $script:saveBaseDirArray) {
		#進捗表示
		updateProgressToast `
			-Title $local:saveDir.Trim() `
			-Rate $( 4 / 4 ) `
			-LeftText '' `
			-RightText '' `
			-Tag $script:appName `
			-Group 'Delete'
		#処理 - 移動先
		deleteFiles `
			-Path $local:saveDir `
			-Conditions '*.ytdl, *.jpg, *.vtt, *.temp.mp4, *.part, *.mp4.part-Frag*' `
			-DatePast 0
	}
}

#======================================================================
#2/3 ダウンロード対象外に入っている番組は削除
Write-Output '----------------------------------------------------------------------'
Write-Output 'ダウンロード対象外の番組を削除します'
Write-Output '----------------------------------------------------------------------'
#進捗表示
showProgressToast `
	-Text1 'ファイルの掃除中' `
	-Text2 '　処理2/3 - ダウンロード対象外の番組を削除' `
	-WorkDetail '' `
	-Tag $script:appName `
	-Group 'Delete' `
	-Duration 'long' `
	-Silent $false

#ダウンロード対象外番組の読み込み
try {
	#ロックファイルをロック
	while ($(fileLock $script:ignoreLockFilePath).fileLocked -ne $true)
	{ Write-Warning 'ファイルのロック解除待ち中です'; Start-Sleep -Seconds 1 }
	#ファイル操作
	$local:ignoreTitles = [String[]](Get-Content `
			-Path $script:ignoreFilePath `
			-Encoding UTF8 `
		| Where-Object { !($_ -match '^\s*$') } `
		| Where-Object { !($_ -match '^;.*$') })
} catch { Write-Error 'ダウンロード対象外の読み込みに失敗しました' ; exit 1
} finally { $null = fileUnlock $script:ignoreLockFilePath }

#----------------------------------------------------------------------
if ($null -ne $local:ignoreTitles ) {
	$local:ignoreTitles | ForEach-Object -Parallel {
		$local:i = $([Array]::IndexOf($using:local:ignoreTitles, $_)) + 1
		$local:total = $using:local:ignoreTitles.Count
		#処理
		Write-Output "$($local:i)/$($local:total) - $($_)"
		try {
			$local:delTargets = Get-ChildItem `
				-LiteralPath $using:script:downloadBaseDir `
				-Name -Filter "*$($_)*"
		} catch { Write-Warning '削除対象を特定できませんでした' }
		try {
			if ($null -ne $delTargets) {
				foreach ($local:delTarget in $local:delTargets) {
					$local:delPath = Join-Path $using:script:downloadBaseDir $local:delTarget
					Write-Output "　$($local:i)/$($local:total) -「$($local:delPath)」を削除します"
					Remove-Item `
						-Path $local:delPath `
						-Recurse `
						-Force `
						-ErrorAction SilentlyContinue
				}
			}
		} catch { Write-Warning '　$($local:i)/$($local:total) - 削除できないファイルがありました' }
	} -ThrottleLimit $script:multithreadNum
}

#----------------------------------------------------------------------

#======================================================================
#3/3 空ディレクトリと隠しファイルしか入っていないディレクトリを一気に削除
Write-Output '----------------------------------------------------------------------'
Write-Output '空ディレクトリを削除します'
Write-Output '----------------------------------------------------------------------'
#進捗表示
showProgressToast `
	-Text1 'ファイルの掃除中' `
	-Text2 '　処理3/3 - 空ディレクトリを削除' `
	-WorkDetail '' `
	-Tag $script:appName `
	-Group 'Delete' `
	-Duration 'long' `
	-Silent $false

#処理
$local:allSubDirs = $null
try {
	$local:allSubDirs = @((Get-ChildItem -LiteralPath $script:downloadBaseDir -Recurse).`
			Where({ $_.PSIsContainer })).FullName `
	| Sort-Object -Descending
} catch { Write-Warning 'ディレクトリを見つけられませんでした' }

#サブディレクトリの合計数
if ($local:allSubDirs -is [Array]) { $local:subDirTotal = $local:allSubDirs.Length }
elseif ($null -ne $local:allSubDirs) { $local:subDirTotal = 1 }
else { $local:subDirTotal = 0 }

#----------------------------------------------------------------------
if ($local:subDirTotal -ne 0) {
	$local:allSubDirs | ForEach-Object -Parallel {
		$local:i = $([Array]::IndexOf($using:local:allSubDirs, $_)) + 1
		$local:total = $using:local:allSubDirs.Count
		#処理
		Write-Output "$($local:i)/$($local:total) - $($_)"
		if (@((Get-ChildItem -LiteralPath $_ -Recurse).`
					Where({ ! $_.PSIsContainer })).Count -eq 0) {
			Write-Output "　$($local:i)/$($local:total) - 「$($_)」を削除します"
			try {
				Remove-Item `
					-LiteralPath $_ `
					-Recurse `
					-Force
			} catch { Write-Output "　$($local:i)/$($local:total) - 空ディレクトリの削除に失敗しました: $_" }
		}
	} -ThrottleLimit $script:multithreadNum
}
#----------------------------------------------------------------------

#進捗表示
updateProgressToast `
	-Title '' `
	-Rate 1 `
	-LeftText '' `
	-RightText '完了' `
	-Tag $script:appName `
	-Group 'Delete'

Write-Output '---------------------------------------------------------------------------'
Write-Output '不要ファイル削除処理を終了しました。                                       '
Write-Output '---------------------------------------------------------------------------'
