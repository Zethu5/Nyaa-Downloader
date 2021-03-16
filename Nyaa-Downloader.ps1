# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# ~~~~~~~~~~~~~~~~~~~~~~~ Config ~~~~~~~~~~~~~~~~~~~~~~~ #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

Param
(
        # Anime series folder path
        [Parameter(Mandatory=$false, 
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]
        $series_path = "E:\Series",

        # Torrent defalt download path
        [Parameter(Mandatory=$false, 
                   Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]
        $torrent_default_download_path = "E:\",

        # Flag to pause script at the end (debug etc...)
        [Parameter(Mandatory=$false, 
                   Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [boolean]
        $pause_script_at_end = $false,

        # Filter Type
        [Parameter(Mandatory=$false, 
                   Position=3)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("No filter", "No remakes", "Trusted only")]
        [string]
        $filter_type = "Trusted only",

        # Episode quality
        [Parameter(Mandatory=$false, 
                   Position=3)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("1080p", "720p", "480p")]
        [string]
        $episode_quality = "1080p",

        # Uploaders
        [Parameter(Mandatory=$false, 
                   Position=4)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $uploaders = @("Erai-raws","SSA","SmallSizedAnimations")
)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# ~~~~~~~~~~~~~~~~~~~~~ Don't Touch ~~~~~~~~~~~~~~~~~~~~ #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

$ErrorActionPreference = "Stop"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Check if Microsoft Office is intalled

if(!(Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | `
   ? {$_.Publisher -eq "Microsoft Corporation" -and ($_.DisplayName -match "Microsoft Office" -or $_.DisplayName -match "Microsoft 365")}))
{

    Write-Host "[     " -NoNewline -ForegroundColor Red
    Write-Host "ERROR" -NoNewline -ForegroundColor Red -BackgroundColor Black
    Write-Host "     ] " -NoNewline -ForegroundColor Red
    Write-Host "Didn't find an installation of Microsoft Office" -ForegroundColor Red

    pause
    break
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get all shows that are being watched

$shows_folders = Get-ChildItem -LiteralPath $series_path -Directory -Depth 0

[string[]] $shows_being_watched = @()
[string] $regex_episode_indicator = "(\s+)?\-(\s+)?\d+$"

foreach($folder_name in $shows_folders)
{
    if($folder_name -match $regex_episode_indicator)
    {
        $shows_being_watched += $folder_name
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get the episode that's needed to be searched for each show

$shows_episode_to_search = @{}
[string[]] $shows_to_search = @()

Write-Host "[INFO] Getting shows folders that are actively being watched" -ForegroundColor Yellow -BackgroundColor DarkMagenta

foreach($show_being_watched in $shows_being_watched)
{
    [string] $show_name = $show_being_watched -replace $regex_episode_indicator,""

    $show_being_watched -match "\d+$" | Out-Null
    [string] $episode_to_search = $Matches[0]
    $Matches.Clear()

    $shows_episode_to_search.Add($show_name,$episode_to_search)
    $shows_to_search += $show_name

    Write-Host "[  " -NoNewline -ForegroundColor Cyan
    Write-Host "SEARCH #$episode_to_search" -NoNewline -ForegroundColor Yellow -BackgroundColor Black

    for([int] $k = 0;$k -lt (5 - $episode_to_search.Length);$k++)
    {
        Write-Host " " -NoNewline -ForegroundColor Cyan
    }

    Write-Host "] $show_name" -ForegroundColor Cyan
}

Write-Host

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get episodes that exist in each show folder that is being watched

$shows_episodes_in_folder = @{}

foreach($show_being_watched in $shows_being_watched)
{
    [string] $show_name = $show_being_watched -replace $regex_episode_indicator,""

    $show_being_watched -match $regex_episode_indicator | Out-Null
    $Matches[0] -match "\d+" | Out-Null
    [string] $show_episode_need_to_see = $Matches[0]

    [string[]] $episodes_in_folder = Get-ChildItem -LiteralPath "$series_path\$show_being_watched" `
                                                    -Recurse |`
                                     Select-Object -ExpandProperty Name | % {
                                        if($_ -match "(\s+)?\-(\s+)?\d+.+\.\w+$")
                                        {
                                            $_ -match $regex_episode_indicator | Out-Null
                                            $Matches[0] -match "\d+" | Out-Null
                                            $Matches[0] -replace "^0",""
                                        }
                                     }

    $shows_episodes_in_folder.Add($show_name,$episodes_in_folder) | Out-Null
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Get the magnet torrent for each show episode

[string] $nyaa_url = "https://nyaa.si/"
[string] $filter_value = @{"No filter"="0";"No remakes"="1";"Trusted only"="2"}.$filter_type
[string] $category_value = "1_2"
[int] $num_torrents_downloading = 0
$shows_episodes_found = @{}
$file_names_and_where_to_put_them = @{}


Write-Host "[INFO] Getting torrent magnet link for each show" -ForegroundColor Yellow -BackgroundColor DarkMagenta

# check if the site is up
try
{
    Invoke-WebRequest -Uri $nyaa_url | Out-Null
}
catch
{
    Write-Host "[     " -NoNewline -ForegroundColor Cyan
    Write-Host "ERROR" -NoNewline -ForegroundColor Red -BackgroundColor Black
    Write-Host "     ] " -NoNewline -ForegroundColor Cyan
    Write-Host "Couldn't reach $nyaa_url, site down?" -ForegroundColor Red -BackgroundColor Black
    break
}

:outer foreach($show_to_search in $shows_to_search)
{
    [bool] $found_some_episode_for_show = $false

    foreach($uploader in $uploaders)
    {
        [int]    $page_index = 1
        [bool]   $reached_end = $false
        [string] $query = "[$uploader] $show_to_search $episode_quality"

        while(!$reached_end)
        {
            [string] $full_url = "$nyaa_url`?f=$filter_value&c=$category_value&q=$query&p=$page_index"
            $page = Invoke-WebRequest -Uri $full_url

            if(($page.ParsedHtml.IHTMLDocument3_getElementsByTagName("tr") | ? {$_.className -eq "success"} | `
               Measure-Object | Select-Object -ExpandProperty Count) -eq 0)
            {
                $reached_end = $true
                continue
            }

            $page_episodes = $page.ParsedHtml.IHTMLDocument3_getElementsByTagName("tr") | ? {$_.className -eq "success"}

            foreach($page_episode in $page_episodes)
            {
                # Episode file name on site
                if($page_episode.children[1].children.length -eq 1)
                {
                    [string] $page_episode_name = $page_episode.children[1].innerText
                } else {
                    [string] $page_episode_name = $page_episode.children[1].children[1].innerText
                }

                $page_episode_name = $page_episode_name.Trim()

                $Matches.Clear()

                # Episode number
                $page_episode_name -match "\s+?\-\s+?\d+(v\d+)?\s+" | Out-Null
                $Matches[0] -match "\d+" | Out-Null
                [int] $page_episode_number = $Matches[0]

                $Matches.Clear()

                # Episode magnet link
                [string] $page_episode_magnet_link = ($page_episode.children[2].children[1] | ? {$_.href -match "^magnet"}).href

                $Matches.Clear()

                if($page_episode_number -ge $shows_episode_to_search[$show_to_search] -and `
                   $page_episode_number -notin $shows_episodes_in_folder[$show_to_search] -and `
                   $shows_episodes_found.$show_to_search -notcontains $page_episode_number)
                {
                    if(!$shows_episodes_found.$show_to_search)
                    {
                        $shows_episodes_found.Add($show_to_search,@($page_episode_number))
                    }
                    else
                    {
                        $shows_episodes_found.$show_to_search += $page_episode_number
                    }

                    $file_names_and_where_to_put_them.Add($page_episode_name,($shows_folders -match ($show_to_search -replace "\(","\(" -replace "\)","\)" -replace "\[","\[" -replace "\]","\]")).Name)
                    start $page_episode_magnet_link

                    Write-Host "[  " -NoNewline -ForegroundColor Cyan
                    Write-Host "DOWNLOADING" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
                    Write-Host "  ] " -NoNewline -ForegroundColor Cyan
                    Write-Host "[$uploader] $show_to_search - $page_episode_number [$episode_quality].mkv" -ForegroundColor Cyan

                    $num_torrents_downloading++
                    $found_some_episode_for_show = $true
                }
            }

            $page_index++
        }
    }

    if(!$found_some_episode_for_show)
    {
        Write-Host "[ " -NoNewline -ForegroundColor Cyan
        Write-Host "NOTHING FOUND" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
        Write-Host " ] " -NoNewline -ForegroundColor Cyan
        Write-Host "$show_to_search" -ForegroundColor DarkCyan
    }
}

Write-Host ""


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Listen to torrents and move episodes to their destinations

[int] $torrent_check_internval = 1

if($num_torrents_downloading -gt 0)
{
    Write-Host "[INFO] Listening to torrents" -ForegroundColor Yellow -BackgroundColor DarkMagenta

    [int] $num_torrents_finished = 0
    [int] $sleep_counter = 1

    while($num_torrents_finished -lt $num_torrents_downloading)
    {
        foreach($record in $file_names_and_where_to_put_them.GetEnumerator())
        {
            $Matches.Clear()
            $record.Key -match "$(("\s+?\-\s+?" -replace "\(","\(" -replace "\)","\)"))\d+" | Out-Null
            $Matches[0] -match "\d+$" | Out-Null
            
            [string] $file_episode_number = $Matches[0]
            [string] $file_prefix = "$($record.Value -replace "\s+?\-\s+?\d+$") - $file_episode_number.mkv"
            
            try
            {
                Move-Item -LiteralPath "$torrent_default_download_path$($record.Key)" -Destination "$series_path\$($record.Value)\$file_prefix"
                $num_torrents_finished++
                Write-Host "[    " -NoNewline -ForegroundColor Cyan
                Write-Host "MOVED" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
                Write-Host "      ] " -NoNewline -ForegroundColor Cyan
                Write-Host " $torrent_default_download_path$($record.Key)" -NoNewline -ForegroundColor Yellow -BackgroundColor Black
                Write-Host " " -NoNewline
                Write-Host "---->" -NoNewline -ForegroundColor Green
                Write-Host " " -NoNewline
                Write-Host "$series_path\$($record.Value) - $($shows_episode_to_search.$show_to_search)\$file_prefix" -ForegroundColor Yellow -BackgroundColor Black
            }
            catch{}
        }

        if($num_torrents_finished -ne $num_torrents_downloading)
        {
            Start-Sleep -Seconds (60 * $torrent_check_internval)
            Write-Host "[  " -NoNewline -ForegroundColor Cyan
            Write-Host "$($sleep_counter * $torrent_check_internval) minutes" -NoNewline -ForegroundColor Yellow -BackgroundColor Black

            for([int]$k = 0;$k -lt (5 - ($sleep_counter * $torrent_check_internval).ToString().Length);$k++)
            {
                Write-Host " " -NoNewline
            }

            Write-Host "] " -NoNewline -ForegroundColor Cyan
            Write-Host "Still downloading" -ForegroundColor Cyan
            $sleep_counter++
        }
    }    
}
else
{
    Write-Host "[INFO] Didn't find any episode to download, exiting" -ForegroundColor Yellow -BackgroundColor DarkMagenta
}

if($pause_script_at_end) { pause }