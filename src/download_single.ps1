###################################################################################
#
#		個別ダウンロード処理スクリプト
#
###################################################################################
Set-StrictMode -Version Latest
$script:guiMode = if ($args) { [String]$args[0] } else { '' }

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#環境設定
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
try {
	if ($myInvocation.MyCommand.CommandType -ne 'ExternalScript') { $script:scriptRoot = Convert-Path .// }
	else { $script:scriptRoot = Split-Path -Parent -Path $myInvocation.MyCommand.Definition }
	Set-Location $script:scriptRoot
} catch { Throw ('❌️ カレントディレクトリの設定に失敗しました') }
if ($script:scriptRoot.Contains(' ')) { Throw ('❌️ TVerRecはスペースを含むディレクトリに配置できません') }
try {
	. (Convert-Path (Join-Path $script:scriptRoot '../src/functions/initialize.ps1'))
	if (!$?) { Throw ('❌️ TVerRecの初期化処理に失敗しました') }
} catch { Throw ('❌️ 関数の読み込みに失敗しました') }

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#メイン処理
Invoke-RequiredFileCheck
Get-Token
$keyword = '個別指定'

#GUI起動を判定
if (!$script:guiMode) { $script:guiMode = $false }

#----------------------------------------------------------------------
#無限ループ
while ($true) {
	#いろいろ初期化
	$videoPageURL = ''
	#移動先ディレクトリの存在確認(稼働中に共有ディレクトリが切断された場合に対応)
	if (!(Test-Path $script:downloadBaseDir -PathType Container)) { Throw ('❌️ 番組ダウンロード先ディレクトリにアクセスできません。終了します') }
	#youtube-dlプロセスの確認と、youtube-dlのプロセス数が多い場合の待機
	Wait-YtdlProcess $script:parallelDownloadFileNum
	if (!$script:guiMode) {
		$videoPageURL = (Read-Host '番組URLを入力してください。何も入力しないで Enter を押すと終了します。').Trim()
	} else {
		#アセンブリの読み込み
		$null = [System.Reflection.Assembly]::Load('Microsoft.VisualBasic, Version=8.0.0.0, Culture=Neutral, PublicKeyToken=b03f5f7f11d50a3a')
		#インプットボックスの表示
		$videoPageURL = [String][Microsoft.VisualBasic.Interaction]::InputBox("番組URLを入力してください。`n何も入力しないで OK を押すと終了します。", 'TVerRec個別ダウンロード').Trim()
	}

	#正しいURLが入力されるまでループ
	if ($videoPageURL -ne '') {
		if ($videoPageURL -notmatch '^https://tver.jp/(/?.*)') {
			#TVer以外のサイトへの対応
			Write-Output ('{0}{1}' -f 'ダウンロード：', $videoPageURL)
			try { Invoke-NonTverYtdl $videoPageURL }
			catch { Throw ('　❌️ youtube-dlの起動に失敗しました') }
			#5秒待機
			Start-Sleep -Seconds 5
		} else {
			Write-Output ('{0}' -f $videoPageURL)
			#TVer番組ダウンロードのメイン処理
			Invoke-VideoDownload `
				-Keyword $keyword `
				-EpisodePage $videoPageURL `
				-Force $script:forceSingleDownload
			Invoke-GarbageCollection
		}
	} else { break }
}

Remove-Variable -Name args, keyword, videoPageURL -ErrorAction SilentlyContinue

Invoke-GarbageCollection

Write-Output ('')
Write-Output ('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
Write-Output ('ダウンロード処理を終了しました。')
Write-Output ('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
