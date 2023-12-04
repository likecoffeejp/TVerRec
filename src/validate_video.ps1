###################################################################################
#
#		番組整合性チェック処理スクリプト
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

try { $script:guiMode = [String]$args[0] } catch { $script:guiMode = '' }

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#環境設定
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Set-StrictMode -Version Latest
#----------------------------------------------------------------------
#初期化
try {
	if ($script:myInvocation.MyCommand.CommandType -ne 'ExternalScript') { $script:scriptRoot = Convert-Path . }
	else { $script:scriptRoot = Split-Path -Parent -Path $script:myInvocation.MyCommand.Definition }
	Set-Location $script:scriptRoot
} catch { Write-Error ('❗ カレントディレクトリの設定に失敗しました') ; exit 1 }
if ($script:scriptRoot.Contains(' ')) { Write-Error ('❗ TVerRecはスペースを含むディレクトリに配置できません') ; exit 1 }
try {
	. (Convert-Path (Join-Path $script:scriptRoot '../src/functions/initialize.ps1'))
	if (!$?) { exit 1 }
} catch { Write-Error ('❗ 関数の読み込みに失敗しました') ; exit 1 }

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#メイン処理

#設定で指定したファイル・ディレクトリの存在チェック
Invoke-RequiredFileCheck

#======================================================================
#ダウンロード履歴ファイルのクリーンアップ
Write-Output ('')
Write-Output ('----------------------------------------------------------------------')
Write-Output ('ダウンロード履歴の不整合レコードを削除します')
Show-ProgressToast `
	-Text1 'ダウンロードファイルの整合性検証中' `
	-Text2 '　処理1/5 - 破損レコードを削除' `
	-WorkDetail '' `
	-Tag $script:appName `
	-Group 'Validate' `
	-Duration 'long' `
	-Silent $false

#ダウンロード履歴の破損レコード削除
Optimize-HistoryFile

Write-Output ('')
Write-Output ('----------------------------------------------------------------------')
Write-Output ('古いダウンロード履歴を削除します')
Show-ProgressToast `
	-Text1 'ダウンロードファイルの整合性検証中' `
	-Text2 ('　処理2/5 - {0}日以上前のダウンロード履歴を削除' -f $script:histRetentionPeriod) `
	-WorkDetail '' `
	-Tag $script:appName `
	-Group 'Validate' `
	-Duration 'long' `
	-Silent $false

#指定日以上前に処理したものはダウンロード履歴から削除
Limit-HistoryFile -RetentionPeriod $script:histRetentionPeriod

Write-Output ('')
Write-Output ('----------------------------------------------------------------------')
Write-Output ('ダウンロード履歴の重複レコードを削除します')
Show-ProgressToast `
	-Text1 'ダウンロードファイルの整合性検証中' `
	-Text2 '　処理3/5 - ダウンロード履歴の重複レコードを削除' `
	-WorkDetail '' `
	-Tag $script:appName `
	-Group 'Validate' `
	-Duration 'long' `
	-Silent $false

#ダウンロード履歴の重複削除
Repair-HistoryFile

if ($script:disableValidation) {
	Write-Warning ('💡 ダウンロードファイルの整合性検証が無効化されているので、検証せずに終了します')
	exit
}

#======================================================================
#未検証のファイルが0になるまでループ
$script:validationFailed = $false
$videoNotValidatedNum = 0
$videoNotValidatedNum = @((Import-Csv -LiteralPath $script:histFilePath -Encoding UTF8).Where({ $_.videoPath -ne '-- IGNORED --' }).Where({ $_.videoValidated -eq '0' })).Count

while ($videoNotValidatedNum -ne 0) {
	#======================================================================
	#ダウンロード履歴から番組チェックが終わっていないものを読み込み
	Write-Output ('')
	Write-Output ('----------------------------------------------------------------------')
	Write-Output ('整合性検証が終わっていない番組を検証します')

	try {
		while ((Lock-File $script:histLockFilePath).fileLocked -ne $true) { Write-Warning ('ファイルのロック解除待ち中です') ; Start-Sleep -Seconds 1 }
		$videoHists = @((Import-Csv -LiteralPath $script:histFilePath -Encoding UTF8).Where({ $_.videoPath -ne '-- IGNORED --' }).Where({ $_.videoValidated -eq '0' }) | Select-Object 'videoPage', 'videoPath', 'videoValidated')
	} catch { Write-Warning ('❗ ダウンロード履歴の読み込みに失敗しました') }
	finally { $null = Unlock-File $script:histLockFilePath }

	if (($null -eq $videoHists) -or ($videoHists.Count -eq 0)) {
		#チェックする番組なし
		Write-Output ('　すべての番組を検証済です')
		Write-Output ('')
	} else {
		#ダウンロードファイルをチェック
		$validateTotal = 0
		$validateTotal = $videoHists.Count
		#ffmpegのデコードオプションの設定
		if ($script:forceSoftwareDecodeFlag) { $decodeOption = '' }
		else {
			if ($script:ffmpegDecodeOption -ne '') {
				Write-Output ('---------------------------------------------------------------------------')
				Write-Output ('💡 ffmpegのデコードオプションが設定されてます')
				Write-Output ('　　　{0}' -f $ffmpegDecodeOption)
				Write-Output ('💡 もし整合性検証がうまく進まない場合は、以下のどちらかをお試しください')
				Write-Output ('　・user_setting.ps1 でデコードオプションを変更する')
				Write-Output ('　・user_setting.ps1 で $script:forceSoftwareDecodeFlag = $true と設定する')
				Write-Output ('---------------------------------------------------------------------------')
			}
			$decodeOption = $script:ffmpegDecodeOption
		}
		Show-ProgressToast `
			-Text1 'ダウンロードファイルの整合性検証中' `
			-Text2 '　処理4/5 - ファイルを検証' `
			-WorkDetail '残り時間計算中' `
			-Tag $script:appName `
			-Group 'Validate' `
			-Duration 'long' `
			-Silent $false
		#----------------------------------------------------------------------
		$totalStartTime = Get-Date
		$validateNum = 0
		foreach ($videoHist in $videoHists.videoPath) {
			$videoFileRelPath = $videoHist
			#処理時間の推計
			$secElapsed = (Get-Date) - $totalStartTime
			$secRemaining = -1
			if ($validateNum -ne 0) {
				$secRemaining = [Int][Math]::Ceiling(($secElapsed.TotalSeconds / $validateNum) * ($validateTotal - $validateNum))
				$minRemaining = ('{0}分' -f ([Int][Math]::Ceiling($secRemaining / 60)))
				$progressRate = [Float]($validateNum / $validateTotal)
			} else {
				$minRemaining = ''
				$progressRate = 0
			}
			$validateNum += 1
			Update-ProgressToast `
				-Title $videoFileRelPath `
				-Rate $progressRate `
				-LeftText $validateNum/$validateTotal `
				-RightText ('残り時間 {0}' -f $minRemaining) `
				-Tag $script:appName `
				-Group 'Validate'
			if (Test-Path $script:downloadBaseDir -PathType Container) {}
			else { Write-Error ('❗ 番組ダウンロード先ディレクトリにアクセスできません。終了します。') ; exit 1 }
			#番組の整合性チェック
			Write-Output ('{0}/{1} - {2}' -f $validateNum, $validateTotal, $videoFileRelPath)
			Invoke-ValidityCheck `
				-DecodeOption $decodeOption `
				-Path $videoFileRelPath
			Start-Sleep -Seconds 1
		}
		#----------------------------------------------------------------------
	}

	#======================================================================
	#ダウンロード履歴から整合性検証が終わっていないもののステータスを初期化
	Write-Output ('')
	Write-Output ('----------------------------------------------------------------------')
	Write-Output ('ダウンロード履歴から検証が終わっていない番組のステータスを変更します')
	Show-ProgressToast `
		-Text1 'ダウンロードファイルの整合性検証中' `
		-Text2 '　処理5/5 - 未検証のファイルのステータスを変更' `
		-WorkDetail '' `
		-Tag $script:appName `
		-Group 'Validate' `
		-Duration 'long' `
		-Silent $false
	try {
		while ((Lock-File $script:histLockFilePath).fileLocked -ne $true) { Write-Warning ('ファイルのロック解除待ち中です') ; Start-Sleep -Seconds 1 }
		$videoHists = @(Import-Csv -Path $script:histFilePath -Encoding UTF8)
		foreach ($uncheckedVido in ($videoHists).Where({ $_.videoValidated -eq 2 })) {
			$uncheckedVido.videoValidated = '0'
		}
		$videoHists | Export-Csv -LiteralPath $script:histFilePath -Encoding UTF8
	} catch { Write-Warning ('❗ ダウンロード履歴の更新に失敗しました') }
	finally { $null = Unlock-File $script:histLockFilePath }
	$videoNotValidatedNum = @((Import-Csv -LiteralPath $script:histFilePath -Encoding UTF8).Where({ $_.videoPath -ne '-- IGNORED --' }).Where({ $_.videoValidated -eq '0' })).Count
}

#======================================================================
#完了処理
Update-ProgressToast `
	-Title 'ダウンロードファイルの整合性検証' `
	-Rate '1' `
	-LeftText '' `
	-RightText '完了' `
	-Tag $script:appName `
	-Group 'Validate'

Invoke-GarbageCollection

Write-Output ('')
Write-Output ('---------------------------------------------------------------------------')
Write-Output ('番組整合性チェック処理を終了しました。                                           ')
Write-Output ('---------------------------------------------------------------------------')
