###################################################################################
#
#		TVerRec自動アップデート処理スクリプト
#
###################################################################################
Add-Type -AssemblyName System.IO.Compression.FileSystem

#----------------------------------------------------------------------
#Zipファイルを解凍
#----------------------------------------------------------------------
function Expand-Zip {
	[CmdletBinding()]
	[OutputType([void])]
	Param(
		[Parameter(Mandatory = $true)][string]$path,
		[Parameter(Mandatory = $true)][string]$destination
	)

	if (Test-Path -Path $path) {
		Write-Verbose ('{0}を{1}に展開します' -f $path, $destination)
		[System.IO.Compression.ZipFile]::ExtractToDirectory($path, $destination, $true)
		Write-Verbose ('{0}を展開しました' -f $path)
	} else {
		Write-Error ('{0}が見つかりません' -f $path)
	}
}

#----------------------------------------------------------------------
#ディレクトリの上書き
#----------------------------------------------------------------------
function Move-Files() {
	[CmdletBinding()]
	[OutputType([System.Void])]
	Param(
		[Parameter(Mandatory = $true)][String]$source,
		[Parameter(Mandatory = $true)][String]$destination
	)

	if ((Test-Path $destination) -and (Test-Path -PathType Container $source)) {
		#ディレクトリ上書き(移動先に存在 かつ ディレクトリ)は再帰的に Move-Files 呼び出し
		$items = (Get-ChildItem $source).Where({ $_.Name -inotlike '*update_tverrec.*' })
		foreach ($item in $items) { Move-Files -Source $item.FullName -Destination (Join-Path $destination $item.Name) }
		#移動し終わったディレクトリを削除
		Remove-Item -LiteralPath $source -Recurse -Force
	} else {
		#移動先に対象なし または ファイルの Move-Item に -Forece つけて実行
		Write-Output ('{0} → {1}' -f $source, $destination)
		Move-Item -LiteralPath $source -Destination $destination -Force
	}
}

#----------------------------------------------------------------------
#存在したら削除
#----------------------------------------------------------------------
Function Remove-IfExist {
	param (
		[Parameter(Mandatory = $true)][string]$path
	)
	if (Test-Path $path) { Remove-Item -LiteralPath $path -Force -Recurse }
}

#----------------------------------------------------------------------
#存在したらリネーム
#----------------------------------------------------------------------
Function Rename-IfExist {
	param (
		[Parameter(Mandatory = $true)][string]$path,
		[Parameter(Mandatory = $true)][string]$newname
	)
	if (Test-Path $path -PathType Leaf) { Rename-Item -LiteralPath $path -NewName $newname -Force }
}

#----------------------------------------------------------------------
#存在したら移動
#----------------------------------------------------------------------
Function Move-IfExist {
	param (
		[Parameter(Mandatory = $true)][string]$path,
		[Parameter(Mandatory = $true)][string]$destination
	)
	if (Test-Path $path -PathType Leaf) { Move-Item -LiteralPath $path -Destination $destination -Force }

}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#環境設定
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Set-StrictMode -Version Latest
try {
	if ($myInvocation.MyCommand.CommandType -eq 'ExternalScript') {
		$scriptRoot = Split-Path -Parent -Path (Split-Path -Parent -Path $myInvocation.MyCommand.Definition)
	} else { $scriptRoot = Convert-Path .. }
	Set-Location $scriptRoot
} catch { Write-Error ('❗ ディレクトリ設定に失敗しました') ; exit 1 }
if ($script:scriptRoot.Contains(' ')) { Write-Error ('❗ TVerRecはスペースを含むディレクトリに配置できません') ; exit 1 }
try {
	$script:confDir = Convert-Path (Join-Path $script:scriptRoot '../conf')
	. (Convert-Path (Join-Path $script:scriptRoot '../conf/system_setting.ps1'))
	if ( Test-Path (Join-Path $script:scriptRoot '../conf/user_setting.ps1') ) { . (Convert-Path (Join-Path $script:scriptRoot '../conf/user_setting.ps1')) }
} catch { Write-Warning ('❗ 設定ファイルの読み込みをせずに実行します') }

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#メイン処理
Write-Output ('')
Write-Output ('===========================================================================')
Write-Output ('---------------------------------------------------------------------------')
Write-Output ('                          TVerRecアップデート処理                          ')
Write-Output ('---------------------------------------------------------------------------')
Write-Output ('===========================================================================')

$repo = 'dongaba/TVerRec'
$releases = ('https://api.github.com/repos/{0}/releases/latest' -f $repo)

#念のため過去のバージョンがあれば削除し、作業ディレクトリを作成
Write-Output ('')
Write-Output ('-----------------------------------------------------------------')
Write-Output ('作業ディレクトリを作成します')
$updateTemp = Join-Path $scriptRoot '../tverrec-update-temp'
if (Test-Path $updateTemp ) { Remove-Item -LiteralPath $updateTemp -Force -Recurse -ErrorAction SilentlyContinue }
try { $null = New-Item -ItemType Directory -Path $updateTemp }
catch { Write-Error ('❗ 作業ディレクトリの作成に失敗しました') ; exit 1 }

#TVerRecの最新バージョン取得
Write-Output ('')
Write-Output ('-----------------------------------------------------------------')
Write-Output ('TVerRecの最新版をダウンロードします')
try {
	if ((Get-Variable -Name 'updatedFromHead' -ErrorAction SilentlyContinue) -and ($script:updatedFromHead)) {
		$zipURL = 'https://github.com/dongaba/TVerRec/archive/refs/heads/master.zip'
	} else { $zipURL = (Invoke-RestMethod -Uri $releases -Method 'GET').zipball_url }
	Invoke-WebRequest -UseBasicParsing -Uri $zipURL -OutFile (Join-Path $updateTemp 'TVerRecLatest.zip')
} catch { Write-Error ('❗ ダウンロードに失敗しました');	exit 1 }

#最新バージョンがダウンロードできていたら展開
Write-Output ('')
Write-Output ('-----------------------------------------------------------------')
Write-Output ('ダウンロードしたTVerRecを解凍します')
try {
	if (Test-Path (Join-Path $updateTemp 'TVerRecLatest.zip') -PathType Leaf) {
		#配下に作成されるディレクトリ名は不定「dongaba-TVerRec-xxxxxxxx」
		Expand-Zip -Path (Join-Path $updateTemp 'TVerRecLatest.zip') -Destination $updateTemp
	} else { Write-Error ('❗ ダウンロードしたファイルが見つかりません') ; exit 1 }
} catch { Write-Error ('❗ ダウンロードしたファイルの解凍に失敗しました') ; exit 1 }

#ディレクトリは上書きできないので独自関数で以下のディレクトリをループ
Write-Output ('')
Write-Output ('-----------------------------------------------------------------')
Write-Output ('ダウンロードしたTVerRecを配置します')
try {
	$newTVerRecDir = (Get-ChildItem -LiteralPath $updateTemp -Directory ).fullname
	Get-ChildItem -LiteralPath $newTVerRecDir -Force | ForEach-Object {
		#Move-Item を行う function として Move-Files 作成して呼び出す
		Move-Files -Source $_.FullName -Destination ('{0}{1}' -f (Join-Path $scriptRoot '../'), $_.Name )
	}
} catch { Write-Error ('❗ ダウンロードしたTVerRecの配置に失敗しました') ; exit 1 }

#作業ディレクトリを削除
Write-Output ('')
Write-Output ('-----------------------------------------------------------------')
Write-Output ('アップデートの作業ディレクトリを削除します')
try { if (Test-Path $updateTemp ) { Remove-Item -LiteralPath $updateTemp -Force -Recurse } }
catch { Write-Error ('❗ 作業ディレクトリの削除に失敗しました') ; exit 1 }

#過去のバージョンで使用していたファイルを削除、または移行
Write-Output ('')
Write-Output ('-----------------------------------------------------------------')
Write-Output ('過去のバージョンで使用していたファイルを削除、または移行します')
#tver.lockをhistory.lockに移行(v2.6.5→v2.6.6)
Remove-IfExist -Path (Join-Path $script:scriptRoot '../db/tver.lock')

#tver.sample.csvをhistory.sample.csvに移行(v2.6.5→v2.6.6)
Remove-IfExist -Path (Join-Path $script:scriptRoot '../db/tver.sample.csv')

#tver.csvをhistory.csvに移行(v2.6.5→v2.6.6)
Rename-IfExist -Path (Join-Path $script:scriptRoot '../db/tver.csv') -NewName 'history.csv'

#*.batを*.cmdに移行(v2.6.9→v2.7.0)
Remove-IfExist -Path (Join-Path $script:scriptRoot '../win/*.bat')

#TVerRec-Logo-Low.pngを削除(v2.7.5→v2.7.6)
Remove-IfExist -Path (Join-Path $script:scriptRoot '../img/TVerRec-Logo-Low.png')

#ダウンロード用のps1をリネーム(v2.7.5→v2.7.6)
Remove-IfExist -Path (Join-Path $script:scriptRoot 'tverrec_bulk.ps1')
Remove-IfExist -Path (Join-Path $script:scriptRoot 'tverrec_list.ps1')
Remove-IfExist -Path (Join-Path $script:scriptRoot 'tverrec_single.ps1')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../win/a.download_video.cmd')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../win/y.tverrec_list.cmd')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../win/z.download_single_video.cmd')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../unix/a.download_video.sh')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../unix/y.tverrec_list.sh')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../unix/z.download_single_video.sh')

#ダウンロード用のps1をリネーム(v2.7.6→v2.7.7)
Remove-IfExist -Path (Join-Path $script:scriptRoot '../.wsb/setup/TVerRec')

#dev containerの廃止(v2.8.0→v2.8.1)
Remove-IfExist -Path (Join-Path $script:scriptRoot '../.devcontainer')

#youtube-dlの旧更新スクリプトの削除(v2.8.1→v2.8.2)
Remove-IfExist -Path (Join-Path $script:scriptRoot 'functions/update_yt-dlp.ps1')
Remove-IfExist -Path (Join-Path $script:scriptRoot 'functions/update_ytdl-patched.ps1')

#ディレクトリ体系変更(v2.9.7→v2.9.8)
Move-IfExist -Path (Join-Path $script:scriptRoot '../list/list.csv') -Destination (Join-Path $script:scriptRoot '../db/list.csv')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../.wsb')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../colab')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../docker')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../list')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../img')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../lib')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../conf/ignore.sample.conf')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../conf/keyword.sample.conf')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../db/history.sample.csv')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../db/history.lock')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../db/ignore.lock')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../db/list.lock')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../resources/Icon.b64')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../resources/Logo.b64')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../resources/TVerRecMain.xaml')
Remove-IfExist -Path (Join-Path $script:scriptRoot '../resources/TVerRecSetting.xaml')

#リストファイルのレイアウト変更(v2.9.9→v3.0.0)
if (Test-Path (Join-Path $script:scriptRoot '../db/list.csv')) {
	$currentListFile = [pscustomobject](Import-Csv (Join-Path $script:scriptRoot '../db/list.csv'))
	$currentListFile | Add-Member -MemberType NoteProperty -Name 'episodePageURL' -Value ''
	$currentListFile | Add-Member -MemberType NoteProperty -Name 'seriesPageURL' -Value ''
	$currentListFile | Add-Member -MemberType NoteProperty -Name 'descriptionText' -Value ''
	Set-Content -LiteralPath (Join-Path $script:scriptRoot '../db/list.csv') -Value 'episodeID,episodePageURL,episodeNo,episodeName,seriesID,seriesPageURL,seriesName,seasonID,seasonName,media,provider,broadcastDate,endTime,keyword,ignoreWord,descriptionText'
	$currentListFile | Export-Csv -LiteralPath (Join-Path $script:scriptRoot '../db/list.csv') -Encoding UTF8 -Append
}

#リストファイルのレイアウト変更(v2.9.9→v3.0.0)
Remove-IfExist -Path (Join-Path $script:scriptRoot '../.vscode/thunder-tests')


#実行権限の付与
if (!$IsWindows) {
	Write-Output ('')
	Write-Output ('-----------------------------------------------------------------')
	Write-Output ('実行権限の付与します')
	(& chmod a+x (Join-Path $script:scriptRoot '../unix/*.sh'))
}

#アップデータ自体の更新のためのファイル作成
$null = New-Item (Join-Path $script:scriptRoot '../log/updater_update.txt') -Type file -Force
$null = 'このファイルはアップデータ自身のアプデートを完了させるために必要です。' | Out-File -FilePath (Join-Path $script:scriptRoot '../log/updater_update.txt')

Write-Output ('')
Write-Output ('===========================================================================')
Write-Output ('')
Write-Output ('💡 TVerRecのアップデートを終了しました。')
Write-Output ('')
Write-Output ('💡 TVerRecを再起動してください。')
Write-Output ('')
Write-Output ('===========================================================================')

exit 0
