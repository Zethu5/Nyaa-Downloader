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
        $uploaders = @('Erai-raws','SSA','SmallSizedAnimations')
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