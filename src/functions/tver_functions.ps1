###################################################################################
#
#		TVer固有関数スクリプト
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
Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

$script:requestHeader = @{
	'x-tver-platform-type' = 'web'
	'Origin'               = 'https://tver.jp'
	'Referer'              = 'https://tver.jp'
}

#----------------------------------------------------------------------
#TVerのAPI Tokenを取得
#----------------------------------------------------------------------
function Get-Token () {
	[OutputType([System.Void])]
	Param ()

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

	$tverTokenURL = 'https://platform-api.tver.jp/v2/api/platform_users/browser/create'
	$requestHeader = @{
		'Content-Type' = 'application/x-www-form-urlencoded'
	}
	$requestBody = 'device_type=pc'
	try {
		$tokenResponse = Invoke-RestMethod `
			-Uri $tverTokenURL `
			-Method 'POST' `
			-Headers $requestHeader `
			-Body $requestBody `
			-TimeoutSec $script:timeoutSec
		$script:platformUID = $tokenResponse.Result.platform_uid
		$script:platformToken = $tokenResponse.Result.platform_token
	} catch { Write-Warning ('❗ トークン取得エラー、終了します') ; exit 1 }
}

#----------------------------------------------------------------------
#キーワードから番組のリンクへの変換
#----------------------------------------------------------------------
function Get-VideoLinksFromKeyword {
	[OutputType([System.Object[]])]
	Param ([String]$keyword)

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

	$script:episodeLinks = @()
	$script:seriesLinks = [System.Collections.Generic.List[String]]::new()

<<<<<<< HEAD
	switch ($true) {
		($keyword.IndexOf('series/') -eq 0) {
			#番組IDによる番組検索から番組ページのLinkを取得
			$seriesID = Remove-Comment($keyword).Replace('series/', '').Trim()
			Invoke-StatisticsCheck -Operation 'search' -TVerType 'series' -TVerID $seriesID
			try { $script:episodeLinks = Get-LinkFromSeriesID ($seriesID) }
			catch { Write-Warning ('❗ 情報取得エラー。スキップします Err:02') ; continue }
			break
		}
		($keyword.IndexOf('talents/') -eq 0) {
			#タレントIDによるタレント検索から番組ページのLinkを取得
			$talentID = Remove-Comment($keyword).Replace('talents/', '').Trim()
			Invoke-StatisticsCheck -Operation 'search' -TVerType 'talent' -TVerID $talentID
			try { $script:episodeLinks = Get-LinkFromTalentID ($talentID) }
			catch { Write-Warning ('❗ 情報取得エラー。スキップします Err:03') ; continue }
			break
		}
		($keyword.IndexOf('tag/') -eq 0) {
			#ジャンルなどのTag情報から番組ページのLinkを取得
			$tagID = Remove-Comment($keyword).Replace('tag/', '').Trim()
			Invoke-StatisticsCheck -Operation 'search' -TVerType 'tag' -TVerID $tagID
			try { $script:episodeLinks = Get-LinkFromTag ($tagID) }
			catch { Write-Warning ('❗ 情報取得エラー。スキップします Err:04') ; continue }
			break
		}
		($keyword.IndexOf('new/') -eq 0) {
			#新着番組から番組ページのLinkを取得
			$genre = Remove-Comment($keyword).Replace('new/', '').Trim()
			Invoke-StatisticsCheck -Operation 'search' -TVerType 'new' -TVerID $genre
			try { $script:episodeLinks = Get-LinkFromNew ($genre) }
			catch { Write-Warning ('❗ 情報取得エラー。スキップします Err:05') ; continue }
			break
		}
		($keyword.IndexOf('ranking/') -eq 0) {
			#ランキングによる番組ページのLinkを取得
			$genre = Remove-Comment($keyword).Replace('ranking/', '').Trim()
			Invoke-StatisticsCheck -Operation 'search' -TVerType 'ranking' -TVerID $genre
			try { $script:episodeLinks = Get-LinkFromRanking ($genre) }
			catch { Write-Warning ('❗ 情報取得エラー。スキップします Err:06') ; continue }
			break
		}
		($keyword.IndexOf('toppage') -eq 0) {
			#トップページから番組ページのLinkを取得
			Invoke-StatisticsCheck -Operation 'search' -TVerType 'toppage'
			try { $script:episodeLinks = Get-LinkFromTopPage }
			catch { Write-Warning ('❗ 情報取得エラー。スキップします Err:07') ; continue }
			break
		}
		($keyword.IndexOf('title/') -eq 0) {
			#番組名による新着検索から番組ページのLinkを取得
			$titleName = Remove-Comment($keyword).Replace('title/', '').Trim()
			Invoke-StatisticsCheck -Operation 'search' -TVerType 'title' -TVerID $titleName
			Write-Warning ('❗ 番組名検索は廃止されました。スキップします Err:08') ; continue
			break
		}
		($keyword.IndexOf('sitemap') -eq 0) {
			#サイトマップから番組ページのLinkを取得
			Invoke-StatisticsCheck -Operation 'search' -TVerType 'sitemap'
			try { $script:episodeLinks = Get-LinkFromSiteMap }
			catch { Write-Warning ('❗ 情報取得エラー。スキップします Err:09') ; continue }
			break
		}
		default {
			#タレント名や番組名などURL形式でない場合APIで検索結果から番組ページのLinkを取得
			Invoke-StatisticsCheck -Operation 'search' -TVerType 'free' -TVerID $keyword
			try { $script:episodeLinks = Get-LinkFromFreeKeyword ($keyword) }
			catch { Write-Warning ('❗ 情報取得エラー。スキップします Err:10') ; continue }
			break
=======
	$key = $keyword.split(' ')[0].split("`t")[0].Split('/')[0]
	$tverID = Remove-Comment(($keyword.Replace("$key/", '')).Trim())
	Invoke-StatisticsCheck -Operation 'search' -TVerType $key -TVerID $tverID
	try {
		switch ($key) {
			'series' { $script:episodeLinks = @(Get-LinkFromSeriesID $tverID) ; continue }
			'talents' { $script:episodeLinks = @(Get-LinkFromTalentID $tverID) ; continue }
			'tag' { $script:episodeLinks = @(Get-LinkFromTag $tverID) ; continue }
			'new' { $script:episodeLinks = @(Get-LinkFromNew $tverID) ; continue }
			'ranking' { $script:episodeLinks = @(Get-LinkFromRanking $tverID) ; continue }
			'toppage' { $script:episodeLinks = @(Get-LinkFromTopPage) ; continue }
			'sitemap' { $script:episodeLinks = @(Get-LinkFromSiteMap) ; continue }
			default { $script:episodeLinks = @(Get-LinkFromFreeKeyword $keyword) }
		}
	} catch { Write-Warning ("❗ 情報取得エラー。スキップします Type:$key") ; continue }

	return $script:episodeLinks | Sort-Object -Unique
}

#----------------------------------------------------------------------
#各種IDによる番組検索から番組ページのLinkを取得
#----------------------------------------------------------------------
function ProcessSearchResults {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)][String]$baseURL,
		[Parameter(Mandatory = $false)][String]$type,
		[Parameter(Mandatory = $false)][String]$keyword
	)

	#URLの整形
	if ($type -eq 'keyword') { $callSearchURL = ('{0}?platform_uid={1}&platform_token={2}&keyword={3}' -f $baseURL, $script:platformUID, $script:platformToken, $keyword) }
	else { $callSearchURL = ('{0}?platform_uid={1}&platform_token={2}' -f $baseURL, $script:platformUID, $script:platformToken) }

	#取得した値をタイプごとに調整
	$searchResultsRaw = Invoke-RestMethod -Uri $callSearchURL -Method 'GET' -Headers $script:requestHeader -TimeoutSec $script:timeoutSec
	if ($type -in @('new', 'ranking')) { $searchResults = $searchResultsRaw.Result.Contents.Contents }
	elseif ($type -eq 'specialmain') { $searchResults = $searchResultsRaw.Result.specialContents }
	elseif ($type -eq 'specialdetail') { $searchResults = $searchResultsRaw.Result.Contents.Content.Contents }
	else { $searchResults = $searchResultsRaw.Result.Contents }

	#タイプ別に再帰呼び出し
	foreach ($searchResult in $searchResults) {
		switch ($searchResult.Type) {
			'live' { continue }
			'episode' {
				$script:episodeLinks += ('https://tver.jp/episodes/{0}' -f $searchResult.Content.Id)
				continue
			}
			'series' {
				Write-Verbose ('　Series {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeriesID $searchResult.Content.Id
				continue
			}
			'season' {
				Write-Verbose ('　Season {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeasonID $searchResult.Content.Id
				continue
			}
			'special' {
				Write-Verbose ('　Special Detail {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSpecialDetailID $searchResult.Content.Id
				continue
			}
			default { $script:episodeLinks += ('https://tver.jp/{0}/{1}' -f $searchResult.Type, $searchResult.Content.Id) }
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
		}
	}

	return $script:episodeLinks | Sort-Object | Get-Unique
}

#----------------------------------------------------------------------
#SeriesIDによる番組検索から番組ページのLinkを取得
#----------------------------------------------------------------------
function Get-LinkFromSeriesID {
	[OutputType([System.Object[]])]
<<<<<<< HEAD
	Param ([String]$seriesID)

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

	$seasonLinks = [System.Collections.Generic.List[String]]::new()
	$callSearchBaseURL = 'https://platform-api.tver.jp/service/api/v1/callSeriesSeasons/'

	#まずはSeries→Seasonに変換
	$callSearchURL = ('{0}{1}?platform_uid={2}&platform_token={3}' -f $callSearchBaseURL, $seriesID.Replace('series/', '').Replace('https://tver.jp/', ''), $script:platformUID, $script:platformToken)
	$searchResultsRaw = Invoke-RestMethod -Uri $callSearchURL -Method 'GET' -Headers $script:requestHeader -TimeoutSec $script:timeoutSec
	$searchResults = $searchResultsRaw.Result.Contents
	foreach ($searchResult in $searchResults) { $seasonLinks.Add($searchResult.Content.Id) }

	#次にSeason→Episodeに変換
	foreach ( $seasonLink in $seasonLinks) { Get-LinkFromSeasonID ($seasonLink) }

	return $script:episodeLinks | Sort-Object | Get-Unique
=======
	Param ([Parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$seriesID)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	$script:episodeLinks += @(ProcessSearchResults -baseURL ('https://platform-api.tver.jp/service/api/v1/callSeriesSeasons/{0}' -f $seriesID))
	return $script:episodeLinks | Sort-Object -Unique
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
}

#----------------------------------------------------------------------
#SeasonIDによる番組検索から番組ページのLinkを取得
#----------------------------------------------------------------------
function Get-LinkFromSeasonID {
	[OutputType([System.Object[]])]
<<<<<<< HEAD
	Param ([String]$SeasonID)

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

	$callSearchBaseURL = 'https://platform-api.tver.jp/service/api/v1/callSeasonEpisodes/'
	$callSearchURL = ('{0}{1}?platform_uid={2}&platform_token={3}' -f $callSearchBaseURL, $SeasonID.Replace('season/', '').Replace('https://tver.jp/', ''), $script:platformUID, $script:platformToken)
	$searchResultsRaw = Invoke-RestMethod -Uri $callSearchURL -Method 'GET' -Headers $script:requestHeader -TimeoutSec $script:timeoutSec
	$searchResults = $searchResultsRaw.Result.Contents
	foreach ($searchResult in $searchResults) {
		switch ($searchResult.Type) {
			'live' { break }
			'episode' {
				$script:episodeLinks.Add('https://tver.jp/episodes/{0}' -f $searchResult.Content.Id)
				break
			}
			'season' {
				Write-Output ('　Season {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeasonID $searchResult.Content.Id
				break
			}
			'series' {
				Write-Output ('　Series {0} からEpisodeを抽出中...' -f $searchResults[$i].Content.Id)
				Get-LinkFromSeriesID $searchResult.Content.Id
				break
			}
			default {
				#他にはないと思われるが念のため
				$script:episodeLinks.Add('https://tver.jp/{0}/{1}' -f $searchResult.Type, $searchResult.Content.Id)
				break
			}
		}
	}

	return $script:episodeLinks | Sort-Object | Get-Unique
=======
	Param ([Parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$seasonID)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	$script:episodeLinks += @(ProcessSearchResults -baseURL ('https://platform-api.tver.jp/service/api/v1/callSeasonEpisodes/{0}' -f $seasonID))
	return $script:episodeLinks | Sort-Object -Unique
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
}

#----------------------------------------------------------------------
#TalentIDによるタレント検索から番組ページのLinkを取得
#----------------------------------------------------------------------
function Get-LinkFromTalentID {
	[OutputType([System.Object[]])]
	Param ([String]$talentID)

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
<<<<<<< HEAD

	$callSearchBaseURL = 'https://platform-api.tver.jp/service/api/v1/callTalentEpisode/'
	$callSearchURL = ('{0}{1}?platform_uid={2}&platform_token={3}' -f $callSearchBaseURL, $talentID.Replace('talents/', '').Replace('https://tver.jp/', ''), $script:platformUID, $script:platformToken)
	$searchResultsRaw = Invoke-RestMethod -Uri $callSearchURL -Method 'GET' -Headers $script:requestHeader -TimeoutSec $script:timeoutSec
	$searchResults = $searchResultsRaw.Result.Contents
	foreach ($searchResult in $searchResults) {
		switch ($searchResult.Type) {
			'live' { break }
			'episode' {
				$script:episodeLinks.Add('https://tver.jp/episodes/{0}' -f $searchResult.Content.Id)
				break
			}
			'season' {
				Write-Output ('　Season {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeasonID $searchResult.Content.Id
				break
			}
			'series' {
				Write-Output ('　Series {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeriesID $searchResult.Content.Id
				break
			}
			default {
				#他にはないと思われるが念のため
				$script:episodeLinks.Add('https://tver.jp/{0}/{1}' -f $searchResult.Type, $searchResult.Content.Id)
				break
			}
		}
	}

	return $script:episodeLinks | Sort-Object | Get-Unique
=======
	$script:episodeLinks += @(ProcessSearchResults -baseURL ('https://platform-api.tver.jp/service/api/v1/callTalentEpisode/{0}' -f $talentID))
	return $script:episodeLinks | Sort-Object -Unique
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
}

#----------------------------------------------------------------------
#SpecialIDによる特集ページのLinkを取得
#----------------------------------------------------------------------
function Get-LinkFromSpecialMainID {
	[OutputType([System.Object[]])]
	Param ([String]$specialMainID)

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
<<<<<<< HEAD

	$callSearchBaseURL = 'https://platform-api.tver.jp/service/api/v1/callSpecialContents/'
	$callSearchURL = ('{0}{1}?platform_uid={2}&platform_token={3}' -f $callSearchBaseURL, $specialMainID, $script:platformUID, $script:platformToken)
	$searchResultsRaw = Invoke-RestMethod -Uri $callSearchURL -Method 'GET' -Headers $script:requestHeader -TimeoutSec $script:timeoutSec
	$searchResults = $searchResultsRaw.Result.specialContents
	foreach ($searchResult in $searchResults) {
		switch ($searchResult.Type) {
			'live' { break }
			'episode' {
				$script:episodeLinks.Add('https://tver.jp/episodes/{0}' -f $searchResult.Content.Id)
				break
			}
			'season' {
				Write-Output ('　Season {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeasonID ($searchResult.Content.Id)
				break
			}
			'series' {
				#Seriesは重複が多いので高速化のためにバッファにためて最後に処理
				Write-Output ('　Series {0} をバッファに保存中...' -f $searchResult.Content.Id)
				$script:seriesLinks.Add($searchResult.Content.Id)
				break
			}
			'special' {
				Write-Output ('　Special Detail {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSpecialDetailID ($searchResult.Content.Id)
				break
			}
			default {
				#他にはないと思われるが念のため
				$script:episodeLinks.Add('https://tver.jp/{0}/{1}' -f $searchResult.Type, $searchResult.Content.Id)
				break
			}
		}
	}

	return $script:episodeLinks | Sort-Object | Get-Unique
=======
	$script:episodeLinks += @(ProcessSearchResults -baseURL ('https://platform-api.tver.jp/service/api/v1/callSpecialContents/{0}' -f $specialMainID) -Type 'specialmain')
	return $script:episodeLinks | Sort-Object -Unique
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
}

#----------------------------------------------------------------------
#SpecialDetailIDによる特集ページのLinkを取得
#----------------------------------------------------------------------
function Get-LinkFromSpecialDetailID {
	[OutputType([System.Object[]])]
<<<<<<< HEAD
	Param ([String]$specialDetailID)

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

	$callSearchBaseURL = 'https://platform-api.tver.jp/service/api/v1/callSpecialContentsDetail/'
	$callSearchURL = ('{0}{1}?platform_uid={2}&platform_token={3}' -f $callSearchBaseURL, $specialDetailID, $script:platformUID, $script:platformToken)
	$searchResultsRaw = Invoke-RestMethod -Uri $callSearchURL -Method 'GET' -Headers $script:requestHeader -TimeoutSec $script:timeoutSec
	$searchResults = $searchResultsRaw.Result.Contents.Content.Contents
	foreach ($searchResult in $searchResults) {
		switch ($searchResult.Type) {
			'live' { break }
			'episode' {
				$script:episodeLinks.Add('https://tver.jp/episodes/{0}' -f $searchResult.Content.Id)
				break
			}
			'season' {
				Write-Output ('　Season {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeasonID ($searchResult.Content.Id)
				break
			}
			'series' {
				#Seriesは重複が多いので高速化のためにバッファにためて最後に処理
				Write-Output ('　Series {0} をバッファに保存中...' -f $searchResult.Content.Id)
				$script:seriesLinks.Add($searchResult.Content.Id)
				break
			}
			'special' {
				#再度Specialが出てきた際は再帰呼び出し
				Write-Output ('　Special Detail {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSpecialDetailID ($searchResult.Content.Id)
				break
			}
			default {
				#他にはないと思われるが念のため
				$script:episodeLinks.Add('https://tver.jp/{0}/{1}' -f $searchResult.Type, $searchResult.Content.Id)
				break
			}
		}
	}

	return $script:episodeLinks | Sort-Object | Get-Unique
=======
	Param ([Parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$specialDetailID)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	$script:episodeLinks += @(ProcessSearchResults -baseURL ('https://platform-api.tver.jp/service/api/v1/callSpecialContentsDetail/{0}' -f $specialDetailID) -Type 'specialdetail')
	return $script:episodeLinks | Sort-Object -Unique
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
}

#----------------------------------------------------------------------
#タグから番組ページのLinkを取得
#----------------------------------------------------------------------
function Get-LinkFromTag {
	[OutputType([System.Object[]])]
<<<<<<< HEAD
	Param ([String]$tagID)

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

	$callSearchBaseURL = 'https://platform-api.tver.jp/service/api/v1/callTagSearch'
	$callSearchURL = ('{0}/{1}?platform_uid={2}&platform_token={3}' -f $callSearchBaseURL, $tagID.Replace('tag/', ''), $script:platformUID, $script:platformToken)
	$searchResultsRaw = Invoke-RestMethod -Uri $callSearchURL -Method 'GET' -Headers $script:requestHeader -TimeoutSec $script:timeoutSec
	$searchResults = $searchResultsRaw.Result.Contents
	foreach ($searchResult in $searchResults) {
		switch ($searchResult.Type) {
			'live' { break }
			'episode' {
				$script:episodeLinks.Add('https://tver.jp/episodes/{0}' -f $searchResult.Content.Id)
				break
			}
			'season' {
				Write-Output ('　Season {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeasonID ($searchResult.Content.Id)
				break
			}
			'series' {
				Write-Output ('　Series {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeriesID ($searchResult.Content.Id)
				break
			}
			default {
				#他にはないと思われるが念のため
				$script:episodeLinks.Add('https://tver.jp/{0}/{1}' -f $searchResult.Type, $searchResult.Content.Id)
				break
			}
		}
	}

	return $script:episodeLinks | Sort-Object | Get-Unique
=======
	Param ([Parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$tagID)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	$script:episodeLinks += @(ProcessSearchResults -baseURL ('https://platform-api.tver.jp/service/api/v1/callTagSearch/{0}' -f $tagID))
	return $script:episodeLinks | Sort-Object -Unique
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
}

#----------------------------------------------------------------------
#新着から番組ページのLinkを取得
#----------------------------------------------------------------------
function Get-LinkFromNew {
	[OutputType([System.Object[]])]
<<<<<<< HEAD
	Param ([String]$genre)

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

	$callSearchBaseURL = 'https://service-api.tver.jp/api/v1/callNewerDetail'
	$callSearchURL = ('{0}/{1}?platform_uid={2}&platform_token={3}' -f $callSearchBaseURL, $genre.Replace('new/', ''), $script:platformUID, $script:platformToken)
	$searchResultsRaw = Invoke-RestMethod -Uri $callSearchURL -Method 'GET' -Headers $script:requestHeader -TimeoutSec $script:timeoutSec
	$searchResults = $searchResultsRaw.Result.Contents.Contents
	foreach ($searchResult in $searchResults) {
		switch ($searchResult.Type) {
			'live' { break }
			'episode' {
				$script:episodeLinks.Add('https://tver.jp/episodes/{0}' -f $searchResult.Content.Id)
				break
			}
			'season' {
				Write-Output ('　Season {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeasonID ($searchResult.Content.Id)
				break
			}
			'series' {
				Write-Output ('　Series {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeriesID ($searchResult.Content.Id)
				break
			}
			default {
				#他にはないと思われるが念のため
				$script:episodeLinks.Add('https://tver.jp/{0}/{1}' -f $searchResult.Type, $searchResult.Content.Id)
				break
			}
		}
	}

	return $script:episodeLinks | Sort-Object | Get-Unique
=======
	Param ([Parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$genre)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	$script:episodeLinks += @(ProcessSearchResults -baseURL ('https://platform-api.tver.jp/service/api/v1/callNewerDetail/{0}' -f $genre) -Type 'new')
	return $script:episodeLinks | Sort-Object -Unique
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
}

#----------------------------------------------------------------------
#ランキングから番組ページのLinkを取得
#----------------------------------------------------------------------
function Get-LinkFromRanking {
	[OutputType([System.Object[]])]
<<<<<<< HEAD
	Param ([String]$genre)

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

	$callSearchBaseURL = 'https://service-api.tver.jp/api/v1/callEpisodeRanking'
	if ($genre -eq 'all') {
		$callSearchURL = ('{0}?platform_uid={1}&platform_token={2}' -f $callSearchBaseURL, $script:platformUID, $script:platformToken)
	} else {
		$callSearchURL = ('{0}Detail/{1}?platform_uid={2}&platform_token={3}' -f $callSearchBaseURL, $genre.Replace('ranking/', '').Trim(), $script:platformUID, $script:platformToken )
	}
	$searchResultsRaw = Invoke-RestMethod -Uri $callSearchURL -Method 'GET' -Headers $script:requestHeader -TimeoutSec $script:timeoutSec
	$searchResults = $searchResultsRaw.Result.Contents.Contents
	foreach ($searchResult in $searchResults) {
		switch ($searchResult.Type) {
			'live' { break }
			'episode' {
				$script:episodeLinks.Add('https://tver.jp/episodes/{0}' -f $searchResult.Content.Id)
				break
			}
			'season' {
				Write-Output ('　Season {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeasonID ($searchResult.Content.Id)
				break
			}
			'series' {
				Write-Output ('　Series {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeriesID ($searchResult.Content.Id)
				break
			}
			default {
				#他にはないと思われるが念のため
				$script:episodeLinks.Add('https://tver.jp/{0}/{1}' -f $searchResult.Type, $searchResult.Content.Id)
				break
			}
		}
	}

	return $script:episodeLinks | Sort-Object | Get-Unique
=======
	Param ([Parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$genre)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	if ($genre -eq 'all') { $script:episodeLinks += @(ProcessSearchResults -baseURL 'https://platform-api.tver.jp/service/api/v1/callEpisodeRanking' -Type 'ranking') }
	else { $script:episodeLinks += @(ProcessSearchResults -baseURL ('https://platform-api.tver.jp/service/api/v1/callEpisodeRankingDetail/{0}' -f $genre) -Type 'ranking') }
	return $script:episodeLinks | Sort-Object -Unique
}

#----------------------------------------------------------------------
#TVerのAPIを叩いてフリーワード検索
#----------------------------------------------------------------------
function Get-LinkFromFreeKeyword {
	[OutputType([System.Object[]])]
	Param ([Parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$keyword)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	$script:episodeLinks += @(ProcessSearchResults -baseURL 'https://platform-api.tver.jp/service/api/v1/callKeywordSearch' -Type 'keyword' -Keyword $keyword)
	return $script:episodeLinks | Sort-Object -Unique
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
}

#----------------------------------------------------------------------
#トップページから番組ページのLinkを取得
#----------------------------------------------------------------------
function Get-LinkFromTopPage {
	[OutputType([System.Object[]])]
	Param ()

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

	$callSearchBaseURL = 'https://platform-api.tver.jp/service/api/v1/callHome'
	$callSearchURL = ('{0}?platform_uid={1}&platform_token={2}' -f $callSearchBaseURL, $script:platformUID, $script:platformToken)
	$searchResultsRaw = Invoke-RestMethod -Uri $callSearchURL -Method 'GET' -Headers $script:requestHeader -TimeoutSec $script:timeoutSec
	$searchResults = $searchResultsRaw.Result.Components
	foreach ($searchResult in $searchResults) {
<<<<<<< HEAD
		if ($searchResult.Type -eq 'horizontal' `
				-or $searchResult.Type -eq 'ranking' `
				-or $searchResult.Type -eq 'talents' `
				-or $searchResult.Type -eq 'billboard' `
				-or $searchResult.Type -eq 'episodeRanking' `
				-or $searchResult.Type -eq 'newer' `
				-or $searchResult.Type -eq 'ender' `
				-or $searchResult.Type -eq 'talent' `
				-or $searchResult.Type -eq 'special') {
=======
		if ($searchResult.Type -in @('horizontal', 'ranking', 'talents', 'billboard', 'episodeRanking', 'newer', 'ender', 'talent', 'special', 'specialContent') ) {
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
			#横スクロール型 or 総合ランキング or 注目タレント or 特集
			foreach ($searchResultContent in $searchResult.Contents) {
				switch ($searchResultContent.Type) {
					'live' { break }
					'episode' {
<<<<<<< HEAD
						$script:episodeLinks.Add('https://tver.jp/episodes/{0}' -f $searchResultContent.Content.Id)
						break
					}
					'season' {
						Write-Output ('　Season {0} からEpisodeを抽出中...' -f $searchResultContent.Content.Id)
						Get-LinkFromSeasonID ($searchResultContent.Content.Id)
						break
=======
						$script:episodeLinks += ('https://tver.jp/episodes/{0}' -f $searchResultContent.Content.Id)
						continue
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
					}
					'series' {
						#Seriesは重複が多いので高速化のためにバッファにためて最後に処理
						Write-Verbose ('　Series {0} をバッファに保存中...' -f $searchResultContent.Content.Id)
						$script:seriesLinks.Add($searchResultContent.Content.Id)
						break
					}
					'season' {
						Write-Verbose ('　Season {0} からEpisodeを抽出中...' -f $searchResultContent.Content.Id)
						Get-LinkFromSeasonID ($searchResultContent.Content.Id)
						continue
					}
					'talent' {
						Write-Verbose ('　Talent {0} からEpisodeを抽出中...' -f $searchResultContent.Content.Id)
						Get-LinkFromTalentID ($searchResultContent.Content.Id)
						break
					}
					'specialMain' {
						Write-Verbose ('　Special Main {0} からEpisodeを抽出中...' -f $searchResultContent.Content.Id)
						Get-LinkFromSpecialMainID ($searchResultContent.Content.Id)
						break
					}
					'special' {
						Write-Verbose ('　Special Detail {0} からEpisodeを抽出中...' -f $searchResultContent.Content.Id)
						Get-LinkFromSpecialDetailID ($searchResultContent.Content.Id)
						break
					}
					default {
						#他にはないと思われるが念のため
						$script:episodeLinks.Add('https://tver.jp/{0}/{1}' -f $searchResultContent.Type, $searchResultContent.Content.Id)
						break
					}
<<<<<<< HEAD
=======
					default { $script:episodeLinks += ('https://tver.jp/{0}/{1}' -f $searchResultContent.Type, $searchResultContent.Content.Id) }
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
				}
			}
		} elseif ($searchResult.Type -eq 'topics') {
			foreach ($searchResultContent in $searchResult.Contents) {
				switch ($searchResultContent.Content.Content.Type) {
					'live' { break }
					'episode' {
<<<<<<< HEAD
						$script:episodeLinks.Add('https://tver.jp/episodes/{0}' -f $searchResultContent.Content.Content.Content.Id)
						break
					}
					'season' {
						Write-Output ('　Season {0} からEpisodeを抽出中...' -f $searchResultContent.Content.Content.Content.Id)
						Get-LinkFromSeasonID ($searchResultContent.Content.Content.Content.Id)
						break
=======
						$script:episodeLinks += ('https://tver.jp/episodes/{0}' -f $searchResultContent.Content.Content.Content.Id)
						continue
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
					}
					'series' {
						#Seriesは重複が多いので高速化のためにバッファにためて最後に処理
						Write-Verbose ('　Series {0} をバッファに保存中...' -f $searchResultContent.Content.Content.Content.Id)
						$script:seriesLinks.Add(($searchResultContent.Content.Content.Content.Id))
						break
					}
					'season' {
						Write-Verbose ('　Season {0} からEpisodeを抽出中...' -f $searchResultContent.Content.Content.Content.Id)
						Get-LinkFromSeasonID ($searchResultContent.Content.Content.Content.Id)
						continue
					}
					'talent' {
						Write-Verbose ('　Talent {0} からEpisodeを抽出中...' -f $searchResultContent.Content.Content.Content.Id)
						Get-LinkFromTalentID ($searchResultContent.Content.Content.Content.Id)
						break
					}
					default {
						#他にはないと思われるが念のため
						$script:episodeLinks.Add('https://tver.jp/{0}/{1}' -f $searchResultContent.Content.Content.Type, $searchResultContent.Content.Content.Content.Id)
						break
					}
<<<<<<< HEAD
=======
					default { $script:episodeLinks += ('https://tver.jp/{0}/{1}' -f $searchResultContent.Content.Content.Type, $searchResultContent.Content.Content.Content.Id) }
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
				}
			}
		} elseif ($searchResult.Type -eq 'banner') { #広告	URLは $searchResult.Contents.Content.targetURL
		} elseif ($searchResult.Type -eq 'resume') { #続きを見る	ブラウザのCookieを処理しないといけないと思われるため対応予定なし
		} elseif ($searchResult.Type -eq 'favorite') { #お気に入り	ブラウザのCookieを処理しないといけないと思われるため対応予定なし
		} else { Write-Warning ('❗ 未知のパターンです。 - {0}' -f $searchResult.Type) }

	}

	#バッファしておいたSeriesの重複を削除しEpisodeを抽出
	$script:seriesLinks = $script:seriesLinks | Sort-Object | Get-Unique
	foreach ($seriesID in $script:seriesLinks) {
		Write-Verbose ('　Series {0} からEpisodeを抽出中...' -f $seriesID)
		Get-LinkFromSeriesID ($seriesID)
	}

	return $script:episodeLinks | Sort-Object | Get-Unique
}

#----------------------------------------------------------------------
#サイトマップから番組ページのLinkを取得
#----------------------------------------------------------------------
function Get-LinkFromSiteMap {
	[OutputType([System.Object[]])]
	Param ()

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

	$callSearchURL = 'https://tver.jp/sitemap.xml'
	$searchResultsRaw = Invoke-RestMethod -Uri $callSearchURL -Method 'GET' -Headers $script:requestHeader -TimeoutSec $script:timeoutSec
	$searchResults = $searchResultsRaw.urlset.url.loc | Sort-Object | Get-Unique

	foreach ($searchResult in $searchResults) {
		if ($searchResult -cmatch '\/episodes\/') { $script:episodeLinks += ($searchResult) }
		elseif ($script:sitemapParseEpisodeOnly) { Write-Debug ('Episodeではないためスキップします') }
		else {
			switch ($true) {
<<<<<<< HEAD
				($searchResult -cmatch '\/seasons\/') {
					Write-Output ('　{0} からEpisodeを抽出中...' -f $searchResult)
					try { Get-LinkFromSeasonID ($searchResult) }
					catch { Write-Warning ('❗ 情報取得エラー。スキップします Err:11') ; continue }
					break
				}
				($searchResult -cmatch '\/series\/') {
					Write-Output ('　{0} からEpisodeを抽出中...' -f $searchResult)
					try { Get-LinkFromSeriesID ($searchResult) }
					catch { Write-Warning ('❗ 情報取得エラー。スキップします Err:12') ; continue }
					break
=======
				($searchResult -cmatch '\/series\/') {
					Write-Verbose ('　{0} からEpisodeを抽出中...' -f $searchResult)
					try { Get-LinkFromSeriesID $searchResult.Replace('https://tver.jp/series/', '') }
					catch { Write-Warning ('❗ 情報取得エラー。スキップします Err:12') }
					continue
>>>>>>> 3831af5f2df229386e4e052e791239d30163297a
				}
				($searchResult -eq 'https://tver.jp/') { break }	#トップページ	別のキーワードがあるためため対応予定なし
				($searchResult -cmatch '\/info\/') { break }	#お知らせ	番組ページではないため対応予定なし
				($searchResult -cmatch '\/live\/') { break }	#追っかけ再生	対応していない
				($searchResult -cmatch '\/mypage\/') { break }	#マイページ	ブラウザのCookieを処理しないといけないと思われるため対応予定なし
				($searchResult -cmatch '\/program') { break }	#番組表	番組ページではないため対応予定なし
				($searchResult -cmatch '\/ranking') { break }	#ランキング	他でカバーできるため対応予定なし
				($searchResult -cmatch '\/specials') { break }	#特集	他でカバーできるため対応予定なし
				($searchResult -cmatch '\/topics') { break }	#トピック	番組ページではないため対応予定なし
				default { Write-Warning ('❗ 未知のパターンです。 - {0}' -f $searchResult) ; break }
			}
		}
	}

	return $script:episodeLinks | Sort-Object | Get-Unique
}

#----------------------------------------------------------------------
#TVerのAPIを叩いてフリーワード検索
#----------------------------------------------------------------------
function Get-LinkFromFreeKeyword {
	[OutputType([System.Object[]])]
	Param ([String]$keyword)

	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

	$tverSearchBaseURL = 'https://platform-api.tver.jp/service/api/v1/callKeywordSearch'
	$tverSearchURL = ('{0}?platform_uid={1}&platform_token={2}&keyword={3}' -f $tverSearchBaseURL, $script:platformUID, $script:platformToken, $keyword )
	$searchResultsRaw = Invoke-RestMethod -Uri $tverSearchURL -Method 'GET' -Headers $script:requestHeader -TimeoutSec $script:timeoutSec
	$searchResults = $searchResultsRaw.Result.Contents

	foreach ($searchResult in $searchResults) {
		switch ($searchResult.Type) {
			'live' { break }
			'episode' {
				$script:episodeLinks.Add('https://tver.jp/episodes/{0}' -f $searchResult.Content.Id)
				break
			}
			'season' {
				Write-Output ('　Season {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeasonID ($searchResult.Content.Id)
				break
			}
			'series' {
				Write-Output ('　Series {0} からEpisodeを抽出中...' -f $searchResult.Content.Id)
				Get-LinkFromSeriesID ($searchResult.Content.Id)
				break
			}
			default {
				#他にはないと思われるが念のため
				$script:episodeLinks.Add('https://tver.jp/{0}/{1}' -f $searchResult.Type, $searchResult.Content.Id )
				break
			}
		}
	}

	return $script:episodeLinks | Sort-Object | Get-Unique
}

