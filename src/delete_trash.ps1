###################################################################################
#
#		不要ファイル削除処理スクリプト
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
	if ($myInvocation.MyCommand.CommandType -ne 'ExternalScript') { $script:scriptRoot = Convert-Path . }
	else { $script:scriptRoot = Split-Path -Parent -Path $myInvocation.MyCommand.Definition }
	Set-Location $script:scriptRoot
} catch { Write-Error ('❗ カレントディレクトリの設定に失敗しました') ; exit 1 }
if ($script:scriptRoot.Contains(' ')) { Write-Error ('❗ TVerRecはスペースを含むディレクトリに配置できません') ; exit 1 }
try {
	. (Convert-Path (Join-Path $script:scriptRoot '../src/functions/initialize.ps1'))
	if (!$?) { exit 1 }
} catch { Write-Error ('❗ 関数の読み込みに失敗しました') ; exit 1 }

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#メイン処理
Invoke-RequiredFileCheck

#======================================================================
#1/3 ダウンロードが中断した際にできたゴミファイルは削除
Write-Output ('')
Write-Output ('----------------------------------------------------------------------')
Write-Output ('処理が中断した際にできたゴミファイルを削除します')

$toastShowParams = @{
	Text1      = '不要ファイル削除中'
	Text2      = '　処理1/3 - ダウンロード中断時のゴミファイルを削除'
	WorkDetail = ''
	Tag        = $script:appName
	Silent     = $false
	Group      = 'Delete'
}
Show-ProgressToast @toastShowParams

#半日以上前のログファイル・ロックファイルを削除
$toastUpdateParams = @{
	Title     = $script:logDir
	Rate      = [Float]( 1 / 4 )
	LeftText  = ''
	RightText = ''
	Tag       = $script:appName
	Group     = 'Delete'
}
Update-ProgressToast @toastUpdateParams

Remove-Files `
	-BasePath $script:logDir `
	-Conditions 'ffmpeg_error_*.log' `
	-DelPeriod 1

#作業ディレクトリ
$toastUpdateParams.Title = $script:downloadWorkDir
$toastUpdateParams.Rate = [Float]( 2 / 4 )
Update-ProgressToast @toastUpdateParams

Remove-Files `
	-BasePath $script:downloadWorkDir `
	-Conditions '*.ytdl, *.jpg, *.webp, *.vtt, *.srt, *.part, *.m4a.part-Frag*, *.m4a, *.live_chat.json, *.mp4.part-Frag*, *.temp.mp4, *.mp4' `
	-DelPeriod 0

#ダウンロード先
$toastUpdateParams.Title = $script:downloadBaseDir
$toastUpdateParams.Rate = [Float]( 3 / 4 )
Update-ProgressToast @toastUpdateParams

Remove-Files `
	-BasePath $script:downloadBaseDir `
	-Conditions '*.ytdl, *.jpg, *.webp, *.vtt, *.srt, *.part, *.m4a.part-Frag*, *.m4a, *.live_chat.json, *.mp4.part-Frag*, *.temp.mp4' `
	-DelPeriod 0

#移動先
if ($script:saveBaseDir -ne '') {
	foreach ($saveDir in $script:saveBaseDirArray) {
		$toastUpdateParams.Title = $saveDir
		$toastUpdateParams.Rate = [Float]( 4 / 4 )
		Update-ProgressToast @toastUpdateParams

		Remove-Files `
			-BasePath $saveDir `
			-Conditions '*.ytdl, *.jpg, *.vtt, *.srt, *.temp.mp4, *.part, *.mp4.part-Frag*, *.m4a, *.m4a.part-Frag*, *.live_chat.json' `
			-DelPeriod 0
	}
}

#======================================================================
#2/3 ダウンロード対象外に入っている番組は削除
Write-Output ('')
Write-Output ('----------------------------------------------------------------------')
Write-Output ('ダウンロード対象外の番組を削除します')

$toastShowParams.Text2 = '　処理2/3 - ダウンロード対象外の番組を削除'
Show-ProgressToast @toastShowParams

#個別ダウンロードが強制モードの場合にはスキップ
if ($script:forceSingleDownload) {
	Write-Warning ('❗ - 強制ダウンロードフラグが設定されているためダウンロード対象外の番組の削除処理をスキップします')
} else {
	#ダウンロード先にディレクトリがない場合はスキップ
	$workDirEntities = @(Get-ChildItem -LiteralPath $script:downloadBaseDir)
	if ($workDirEntities.Count -eq 0) { return }

	#ダウンロード対象外番組が登録されていない場合はスキップ
	$ignoreTitles = @(Read-IgnoreList)
	$ignoreDirs = [System.Collections.Generic.List[object]]::new()
	if ($ignoreTitles.Count -eq 0) { return }

	#削除対象の特定
	$ignoreTitles | ForEach-Object {
		$ignoreTitle = $_.Normalize([Text.NormalizationForm]::FormC)
		$filteredDirs = $workDirEntities.Where({ $_.Name.Normalize([Text.NormalizationForm]::FormC) -like "*${ignoreTitle}*" })
		$filteredDirs | ForEach-Object {
			$ignoreDirs.Add($_)
			Update-IgnoreList $ignoreTitle
		}
	}

	#----------------------------------------------------------------------
	if ($ignoreDirs.Count -ne 0) {
		if ($script:enableMultithread) {
			Write-Debug ('Multithread Processing Enabled')
			#並列化が有効の場合は並列化
			$ignoreDirs | ForEach-Object -Parallel {
				$ignoreNum = ([Array]::IndexOf($using:ignoreDirs, $_)) + 1
				$ignoreTotal = $using:ignoreDirs.Count
				Write-Output ('　{0}/{1} - {2}' -f $ignoreNum, $ignoreTotal, $_.Name)
				try { Remove-Item -LiteralPath $_ -Recurse -Force }
				catch { Write-Warning ('❗ 削除できないファイルがありました') }
			} -ThrottleLimit $script:multithreadNum
		} else {
			#並列化が無効の場合は従来型処理
			#ダウンロード対象外内のエントリ合計数
			$ignoreNum = 0
			$ignoreTotal = $ignoreDirs.Count
			$totalStartTime = Get-Date
			foreach ($ignoreDir in $ignoreDirs) {
				$ignoreNum += 1
				#処理時間の推計
				$secElapsed = (Get-Date) - $totalStartTime
				$secRemaining = -1
				if ($ignoreNum -ne 1) {
					$secRemaining = [Int][Math]::Ceiling(($secElapsed.TotalSeconds / $ignoreNum) * ($ignoreTotal - $ignoreNum))
					$minRemaining = ('残り時間 {0}分' -f ([Int][Math]::Ceiling($secRemaining / 60)))
					$progressRate = [Float]($ignoreNum / $ignoreTotal)
				} else {
					$minRemaining = ''
					$progressRate = 0
				}

				$toastUpdateParams.Title = $ignoreDir.Name
				$toastUpdateParams.Rate = $progressRate
				$toastUpdateParams.LeftText = ('{0}/{1}' -f $ignoreNum, $ignoreTotal)
				$toastUpdateParams.RightText = $minRemaining
				Update-ProgressToast @toastUpdateParams

				Write-Output ('　{0}/{1} - {2}' -f $ignoreNum, $ignoreTotal, $ignoreDir.Name)
				try { Remove-Item -LiteralPath $ignoreDir -Recurse -Force }
				catch { Write-Warning ('❗ 削除できないファイルがありました') }
			}
		}
	}
}

#----------------------------------------------------------------------

#======================================================================
#3/3 空ディレクトリと隠しファイルしか入っていないディレクトリを一気に削除
Write-Output ('')
Write-Output ('----------------------------------------------------------------------')
Write-Output ('空ディレクトリを削除します')

$toastShowParams.Text2 = '　処理3/3 - 空ディレクトリを削除'
Show-ProgressToast @toastShowParams

$emptyDirs = @()
$emptyDirs = @((Get-ChildItem -LiteralPath $script:downloadBaseDir -Recurse).Where({ $_.PSIsContainer })).Where({ ($_.GetFiles().Count -eq 0) -and ($_.GetDirectories().Count -eq 0) })
if ($emptyDirs.Count -ne 0) { $emptyDirs = @($emptyDirs.Fullname) }

$emptyDirTotal = $emptyDirs.Count

#----------------------------------------------------------------------
if ($emptyDirTotal -ne 0) {
	if ($script:enableMultithread) {
		Write-Debug ('Multithread Processing Enabled')
		#並列化が有効の場合は並列化
		$emptyDirs | ForEach-Object -Parallel {
			$emptyDirNum = ([Array]::IndexOf($using:emptyDirs, $_)) + 1
			$emptyDirTotal = $using:emptyDirs.Count
			Write-Output ('　{0}/{1} - {2}' -f $emptyDirNum, $emptyDirTotal, $_)
			try { Remove-Item -LiteralPath $_ -Recurse -Force }
			catch { Write-Warning ('❗ - 空ディレクトリの削除に失敗しました: {0}' -f $_) }
		} -ThrottleLimit $script:multithreadNum
	} else {
		#並列化が無効の場合は従来型処理
		$emptyDirNum = 0
		$emptyDirTotal = $emptyDirs.Count
		$totalStartTime = Get-Date
		foreach ($subDir in $emptyDirs) {
			$emptyDirNum += 1
			#処理時間の推計
			$secElapsed = (Get-Date) - $totalStartTime
			$secRemaining = -1
			if ($emptyDirNum -ne 1) {
				$secRemaining = [Int][Math]::Ceiling(($secElapsed.TotalSeconds / $emptyDirNum) * ($emptyDirTotal - $emptyDirNum))
				$minRemaining = ('残り時間 {0}分' -f ([Int][Math]::Ceiling($secRemaining / 60)))
				$progressRate = [Float]($emptyDirNum / $emptyDirTotal)
			} else {
				$minRemaining = ''
				$progressRate = 0
			}

			$toastUpdateParams.Title = $subDir
			$toastUpdateParams.Rate = $progressRate
			$toastUpdateParams.LeftText = ('{0}/{1}' -f $emptyDirNum, $emptyDirTotal)
			$toastUpdateParams.RightText = $minRemaining
			Update-ProgressToast @toastUpdateParams

			Write-Output ('　{0}/{1} - {2}' -f $emptyDirNum, $emptyDirTotal, $subDir)
			try { Remove-Item -LiteralPath $subDir -Recurse -Force -ErrorAction SilentlyContinue
			} catch { Write-Warning ('❗ - 空ディレクトリの削除に失敗しました: {0}' -f $subDir) }
		}
	}
}
#----------------------------------------------------------------------

$toastUpdateParams.Title = '不要ファイル削除'
$toastUpdateParams.Rate = 1
$toastUpdateParams.LeftText = ''
$toastUpdateParams.RightText = '完了'
Update-ProgressToast @toastUpdateParams

Invoke-GarbageCollection

Write-Output ('')
Write-Output ('---------------------------------------------------------------------------')
Write-Output ('不要ファイル削除処理を終了しました。                                       ')
Write-Output ('---------------------------------------------------------------------------')
