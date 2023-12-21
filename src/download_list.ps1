###################################################################################
#
#		リストダウンロード処理スクリプト
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

$keyword = 'リスト指定'
Get-Token

#ダウンロードリストを読み込み
$listLinks = @(Get-LinkFromDownloadList)
if ($null -eq $listLinks) { Write-Warning ('💡 ダウンロードリストが0件です') ; exit 0 }

#URLがすでにダウンロード履歴に存在する場合は検索結果から除外
if ($listLinks.Count -ne 0) { $videoLinks, $processedCount = Invoke-HistoryMatchCheck $listLinks }
else { $videoLinks = @(); $processedCount = 0 }
$videoTotal = $videoLinks.Count
Write-Output ('')
if ($videoTotal -eq 0) { Write-Output ('　処理対象{0}本　処理済{1}本' -f $videoTotal, $processedCount) }
else { Write-Output ('　💡 処理対象{0}本　処理済{1}本' -f $videoTotal, $processedCount) }


#処理時間の推計
$totalStartTime = Get-Date
$secRemaining = -1

Show-ProgressToast `
	-Text1 'リストからの番組のダウンロード' `
	-Text2 'リストファイルから番組をダウンロード' `
	-WorkDetail '読み込み中...' `
	-Duration 'long' `
	-Silent $false `
	-Tag $script:appName `
	-Group 'List'

#----------------------------------------------------------------------
#個々の番組ダウンロードここから
$videoNum = 0
foreach ($videoLink in $videoLinks) {
	$videoNum += 1
	#ダウンロード先ディレクトリの存在確認先ディレクトリの存在確認(稼働中に共有ディレクトリが切断された場合に対応)
	if (Test-Path $script:downloadBaseDir -PathType Container) {}
	else { Write-Error ('❗ 番組ダウンロード先ディレクトリにアクセスできません。終了します') ; exit 1 }
	#進捗率の計算
	$progressRate = [Float]($videoNum / $videoTotal)
	$secElapsed = (Get-Date) - $totalStartTime
	$secRemaining = [Int][Math]::Ceiling(($secElapsed.TotalSeconds / $videoNum) * ($videoTotal - $videoNum))
	$minRemaining = ('{0}分' -f ([Int][Math]::Ceiling($secRemaining / 60)))
	#進捗更新
	Update-ProgressToast `
		-Title 'リストからの番組のダウンロード' `
		-Rate $progressRate `
		-LeftText $videoNum/$videoTotal `
		-RightText $minRemaining `
		-Tag $script:appName `
		-Group 'List'
	Write-Output ('--------------------------------------------------')
	Write-Output ('{0}/{1} - {2}' -f $videoNum, $videoTotal, $videoLink)
	#youtube-dlプロセスの確認と、youtube-dlのプロセス数が多い場合の待機
	Wait-YtdlProcess $script:parallelDownloadFileNum
	#TVer番組ダウンロードのメイン処理
	Invoke-VideoDownload `
		-Keyword $keyword `
		-EpisodePage $videoLink `
		-Force $false
}
#----------------------------------------------------------------------

Update-ProgressToast `
	-Title 'リストからの番組のダウンロード' `
	-Rate '1' `
	-LeftText '' `
	-RightText '完了' `
	-Tag $script:appName `
	-Group 'List'

#youtube-dlのプロセスが終わるまで待機
Write-Output ('')
Write-Output ('ダウンロードの終了を待機しています')
Wait-DownloadCompletion

Invoke-GarbageCollection

Write-Output ('')
Write-Output ('---------------------------------------------------------------------------')
Write-Output ('リストダウンロード処理を終了しました。                                     ')
Write-Output ('---------------------------------------------------------------------------')

