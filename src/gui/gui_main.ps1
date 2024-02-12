###################################################################################
#
#		GUIメインスクリプト
#
###################################################################################
using namespace System.Windows.Threading

if (!$IsWindows) { Write-Error ('❗ Windows以外では動作しません') ; Start-Sleep 10 ; exit 1 }
Add-Type -AssemblyName PresentationFramework

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#region 環境設定

Set-StrictMode -Version Latest
#----------------------------------------------------------------------
#初期化
try {
	if ($myInvocation.MyCommand.CommandType -ne 'ExternalScript') { $script:scriptRoot = Convert-Path . }
	else { $script:scriptRoot = Split-Path -Parent -Path $myInvocation.MyCommand.Definition }
	$script:scriptRoot = Convert-Path (Join-Path $script:scriptRoot '../')
	Set-Location $script:scriptRoot
} catch { Write-Error ('❗ ディレクトリ設定に失敗しました') ; exit 1 }
if ($script:scriptRoot.Contains(' ')) { Write-Error ('❗ TVerRecはスペースを含むディレクトリに配置できません') ; exit 1 }
try {
	. (Convert-Path (Join-Path $script:scriptRoot '../src/functions/initialize.ps1'))
	if (!$?) { exit 1 }
} catch { Write-Error ('❗ 関数の読み込みに失敗しました') ; exit 1 }

#パラメータ設定
$msgTypes = @('Output', 'Error', 'Warning', 'Verbose', 'Debug', 'Information')
$jobTerminationStates = @('Completed', 'Failed', 'Stopped')
$msgTypesColorMap = @{
	Output      = 'DarkSlateGray'
	Error       = 'Crimson'
	Warning     = 'Coral'
	Verbose     = 'LightSlateGray'
	Debug       = 'CornflowerBlue'
	Information = 'DarkGray'
}

#endregion 環境設定

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#region 関数定義

#GUIイベントの処理
function Sync-WpfEvents {
	[DispatcherFrame] $frame = [DispatcherFrame]::new($true)
	$null = [Dispatcher]::CurrentDispatcher.BeginInvoke(
		'Background',
		[DispatcherOperationCallback] {
			Param([object] $f)
			($f -as [DispatcherFrame]).Continue = $false
			return $null
		},
		$frame)
	[Dispatcher]::PushFrame($frame)
}

#テキストボックスへのログ出力と再描画
function Out-ExecutionLog {
	Param (
		[parameter(Mandatory = $false)][String]$message = '',
		[parameter(Mandatory = $false)][String]$type = 'Output'
	)
	$rtfRange = New-Object System.Windows.Documents.TextRange($outText.Document.ContentEnd, $outText.Document.ContentEnd)
	$rtfRange.Text = ("{0}`n" -f $Message)
	$rtfRange.ApplyPropertyValue([System.Windows.Documents.TextElement]::ForegroundProperty, $msgTypesColorMap[$type] )
	$outText.ScrollToEnd()
}

#endregion 関数定義

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#メイン処理

#----------------------------------------------------------------------
#region WPFのWindow設定

try {
	[String]$mainXaml = Get-Content -LiteralPath (Join-Path $script:xamlDir 'TVerRecMain.xaml')
	$mainXaml = $mainXaml -ireplace 'mc:Ignorable="d"', '' -ireplace 'x:N', 'N' -ireplace 'x:Class=".*?"', ''
	[xml]$mainCleanXaml = $mainXaml
	$mainWindow = [System.Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $mainCleanXaml))
} catch { Write-Error ('❗ ウィンドウデザイン読み込めませんでした。TVerRecが破損しています。') ; exit 1 }

#PowerShellのウィンドウを非表示に
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]public static extern IntPtr GetConsoleWindow() ;
[DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow) ;
'
$console = [Console.Window]::GetConsoleWindow()
$null = [Console.Window]::ShowWindow($console, 0)

#タスクバーのアイコンにオーバーレイ表示
$mainWindow.TaskbarItemInfo.Overlay = ConvertFrom-Base64 $script:iconBase64
$mainWindow.TaskbarItemInfo.Description = $mainWindow.Title

#ウィンドウを読み込み時の処理
$mainWindow.Add_Loaded({ $mainWindow.Icon = $script:iconPath })

#ウィンドウを閉じる際の処理
$mainWindow.Add_Closing({ Get-Job | Receive-Job -Wait -AutoRemoveJob -Force })

#Name属性を持つ要素のオブジェクト作成
$mainCleanXaml.SelectNodes('//*[@Name]') | ForEach-Object { Set-Variable -Name ($_.Name) -Value $mainWindow.FindName($_.Name) -Scope Local }

#WPFにロゴをロード
$LogoImage.Source = ConvertFrom-Base64 $script:logoBase64

#バージョン表記
$lblVersion.Content = ('Version {0}' -f $script:appVersion)

#ログ出力するためのテキストボックス
$outText = $mainWindow.FindName('tbOutText')

#endregion WPFのWindow設定

#----------------------------------------------------------------------
#region バックグラウンドジョブ化する処理を持つボタン

$btns = @(
	$mainWindow.FindName('btnSingle'), #0
	$mainWindow.FindName('btnBulk'), #1
	$mainWindow.FindName('btnListGen'), #2
	$mainWindow.FindName('btnList'), #3
	$mainWindow.FindName('btnDelete'), #4
	$mainWindow.FindName('btnValidate'), #5
	$mainWindow.FindName('btnMove'), #6
	$mainWindow.FindName('btnLoop')
)

#バックグラウンドジョブ化するボタンの処理内容
$scriptBlocks = @{
	$btns[0] = { . './download_single.ps1' $true }
	$btns[1] = { . './download_bulk.ps1' $true }
	$btns[2] = { . './generate_list.ps1' $true }
	$btns[3] = { . './download_list.ps1' $true }
	$btns[4] = { . './delete_trash.ps1' $true }
	$btns[5] = { . './validate_video.ps1' $true }
	$btns[6] = { . './move_video.ps1' $true }
	$btns[7] = { . './loop.ps1' $true }
}

#バックグラウンドジョブ化する処理の名前
$threadNames = @{
	$btns[0] = { 個別ダウンロード処理を実行中 }
	$btns[1] = { 一括ダウンロード処理を実行中 }
	$btns[2] = { リスト作成処理を実行中 }
	$btns[3] = { リストダウンロード処理を実行中 }
	$btns[4] = { 不要ファイル削除処理を実行中 }
	$btns[5] = { 番組整合性検証処理を実行中 }
	$btns[6] = { 番組移動処理を実行中 }
	$btns[7] = { ループ処理を実行中 }
}

#バックグラウンドジョブ化するボタンのアクション
foreach ($btn in $btns) {
	$btn.Add_Click({
			#ジョブの稼働中はボタンを無効化
			foreach ($btn in $btns) { $btn.IsEnabled = $false }
			$btnExit.IsEnabled = $false
			$lblStatus.Content = ([String]$threadNames[$this]).Trim()

			#処理停止ボタンの有効化
			$btnKillAll.IsEnabled = $true

			#バックグラウンドジョブの起動
			$null = Start-ThreadJob -Name $this.Name -ScriptBlock $scriptBlocks[$this]
			#$null = Start-Job -Name $this.Name $scriptBlocks[$this]	#こっちにするとWrite-Debugがコンソールに出る
		})
}

#endregion バックグラウンドジョブ化する処理を持つボタン

#----------------------------------------------------------------------
#region ジョブ化しないボタンのアクション

$btnWorkOpen.Add_Click({ Invoke-Item $script:downloadWorkDir })
$btnDownloadOpen.Add_Click({ Invoke-Item $script:downloadBaseDir })
$btnsaveOpen.Add_Click({
		if ($script:saveBaseDir -ne '') { $script:saveBaseDir.Split(';').Trim() | ForEach-Object { Invoke-Item $_ } }
		else { [System.Windows.MessageBox]::Show('保存ディレクトリが設定されていません') }
	})
$btnKeywordOpen.Add_Click({ Invoke-Item $script:keywordFilePath })
$btnIgnoreOpen.Add_Click({ Invoke-Item $script:ignoreFilePath })
$btnListOpen.Add_Click({ Invoke-Item $script:listFilePath })
$btnClearLog.Add_Click({
		$outText.Document.Blocks.Clear()
		Invoke-GarbageCollection
	})
$btnKillAll.Add_Click({
		Get-Job | Remove-Job -Force
		foreach ($btn in $btns) { $btn.IsEnabled = $true }
		$btnExit.IsEnabled = $true
		$btnKillAll.IsEnabled = $false
		$lblStatus.Content = '処理を強制停止しました'
		Invoke-GarbageCollection
	})
$btnWiki.Add_Click({ Start-Process ‘https://github.com/dongaba/TVerRec/wiki’ })
$btnsetting.Add_Click({
		. 'gui/gui_setting.ps1'
		if ( Test-Path (Join-Path $script:confDir 'user_setting.ps1') ) {
			. (Convert-Path (Join-Path $script:confDir 'user_setting.ps1'))
		}
		Invoke-GarbageCollection
	})
$btnExit.Add_Click({ $mainWindow.close() })

#endregion ジョブ化しないボタンのアクション

#----------------------------------------------------------------------
#region ウィンドウ表示

#処理停止ボタンの初期値は無効
$btnKillAll.IsEnabled = $false

try {
	$null = $mainWindow.Show()
	$null = $mainWindow.Activate()
	$null = [Console.Window]::ShowWindow($console, 0)
} catch { Write-Error ('❗ ウィンドウを描画できませんでした。TVerRecが破損しています。') ; exit 1 }

#endregion ウィンドウ表示

#----------------------------------------------------------------------
#region ウィンドウ表示後のループ処理
while ($mainWindow.IsVisible) {

	if ($jobs = Get-Job) {
		#ジョブがある場合の処理
		foreach ($job in $jobs) {
			#各メッセージタイプごとに内容を取得(ただしReceive-Jobは次Stepで実行するので取りこぼす可能性あり)
			foreach ($msgType in $msgTypes) {
				$variableValue = if ($job.$msgType) { $job.$msgType } else { $null }
				Set-Variable -Name ('msg' + $msgType) -Value $variableValue
			}

			#Jobからメッセージを取得し事前に取得したメッセージタイプと照合し色付け
			$jobMsgs = (Receive-Job $job *>&1)
			foreach ($jobMsg in $jobMsgs) {
				switch ($true) {
					($msgError -contains $jobMsg) { if ($msgError) { Out-ExecutionLog -Message ($jobMsg -join "`n") -Type 'Error' }; continue }
					($msgWarning -contains $jobMsg) { if ($msgWarning) { Out-ExecutionLog -Message ($jobMsg -join "`n") -Type 'Warning' }; continue }
					($msgVerbose -contains $jobMsg) { if ($msgVerbose) { Out-ExecutionLog -Message ($jobMsg -join "`n") -Type 'Verbose' }; continue }
					($msgDebug -contains $jobMsg) { if ($msgDebug) { Out-ExecutionLog -Message ($jobMsg -join "`n") -Type 'Debug' }; continue }
					($msgInformation -contains $jobMsg) { if ($msgInformation) { Out-ExecutionLog -Message ($jobMsg -join "`n") -Type 'Information' }; continue }
					default { Out-ExecutionLog -Message ($jobMsg -join "`n") -Type 'Output' }
				}
			}

			#各メッセージタイプごとの内容を保存する変数を開放
			foreach ($msgType in $msgTypes) {
				Remove-Variable -Name ('msg' + $msgType)
			}

			#終了したジョブのボタンの再有効化
			if ($job.State -in $jobTerminationStates) {
				Remove-Job $job
				$btns.ForEach({ $_.IsEnabled = $true })
				$btnExit.IsEnabled = $true
				$btnKillAll.IsEnabled = $false
				$lblStatus.Content = '処理を終了しました'
				Invoke-GarbageCollection
			}
		}
	}

	#GUIイベント処理
	Sync-WpfEvents

	Start-Sleep -Milliseconds 10
}

#endregion ウィンドウ表示後のループ処理

#----------------------------------------------------------------------
#region 終了処理

#Windowが閉じられたら乗っているゴミジョブを削除して終了
Get-Job | Receive-Job -Wait -AutoRemoveJob -Force

#endregion 終了処理

