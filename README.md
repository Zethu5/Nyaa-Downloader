# Nyaa-Downloader

Powershell automation script for downloading anime from Nyaa

![](https://camo.githubusercontent.com/3121ae1f416313cf2af987bb11d541d48d7a20ccfdb57b0b6101f9421587a762/68747470733a2f2f692e696d6775722e636f6d2f646f646d43305a2e706e67)

## Operation
The script operates via **folder name conventions**.

There is a general folder that contains all of the shows folders.

Each show folder has the name of the show that the uploader wrote as the file name and the episode number to be watched.

Meaning for example that if I'm watching `2.43 Seiin Koukou Danshi Volley Bu` and the uploader names his episodes:

![Show episode uploaded](https://i.imgur.com/Kz5rAC4.png)

Than the folder name will be as it is in the file name:

![Folder name](https://i.imgur.com/GWUPyBc.png)

### ⚠️ Pay Attention!

For episodes to be downloaded, the folder names should be in the convetion of `<show name> - <episode number that you didn't watch yet>`

Lets look at the former example, if I would like to download every episode of `2.43 Seiin Koukou Danshi Volley Bu` from `episode 1` onward `until the latest one`, I would name the folder as follows:

![Folder episode convention](https://imgur.com/gpdLdMB.png)

For reference, your folders should look a little something like this:

![Folders reference](https://imgur.com/jwPUQdw.png)

The script will search for each show episode multiplied by the number of uploaders you have,

meaning for example that if I didn't find an episode with 'Erai-raws' as the uploader it will try searching the same episode with 'SSA' as the uplodaer and etc...

## Pre Configuration

For the script to work `BitTorrent/UTorrent` should be used and configured as such:

* New downloads should be put in a static place:

   ![Torrent download location](https://imgur.com/cUJJLx3.png)

* Maximum number of active torrents and downloads should be equal and seeding should be disabled:

   ![Parallel torrents and seeding disabling](https://imgur.com/B5BdiZO.png)
   
   > The reason seeding is disabled is because seeding a torrent keeps open handles to it meaning the file is used and cannot be moved automatically.
   
* Powershell v5.1+

   If you're not updated (check by running `powershell $host` in your cmd window)
   
   You can install the latest version: [.NET Framework](https://dotnet.microsoft.com/download/dotnet-framework)
   
* Microsoft Office / Office 365

   This requirement was a doozy for me as well, there are some Powershell functions that will not work unless Microsoft Office / Office 365 are installed
   
## Script Configuration

### Variables

The script contains some variables for you to configure:

- `$series_path` :
   ```powershell
   # Anime series folder path
   [Parameter(Mandatory=$false, 
              Position=0)]
   [ValidateNotNull()]
   [ValidateNotNullOrEmpty()]
   [string]
   $series_path = "E:\Series",
   ```
   
   > The path of the general folder that contains all of the shows folders
   
   > Change `E:\Series` to your desired location
   
   ---
   
- `$torrent_default_download_path` :

   ```powershell
   # Torrent defalt download path
   [Parameter(Mandatory=$false, 
              Position=1)]
   [ValidateNotNull()]
   [ValidateNotNullOrEmpty()]
   [string]
   $torrent_default_download_path = "E:\",
   ```
   
   > The path of the folder where torrents are placed after downloading
   
   > Change `E:\` to match the path you assigned in your torrent client
   
   ---
   
- `$pause_script_at_end` :

   ```powershell
   # Flag to pause script at the end (debug etc...)
   [Parameter(Mandatory=$false, 
              Position=1)]
   [ValidateNotNull()]
   [ValidateNotNullOrEmpty()]
   [boolean]
   $pause_script_at_end = $false,
   ```
   
   > As the name suggests, it's for debug purposes
   
   > If you wish to change it so you could stop the script window after it ends change from `$pause_script_at_end = $false,` to `$pause_script_at_end = $true,`
   
---

- `$filter_type` :

   ```powershell
   # Filter Type
   [Parameter(Mandatory=$false, 
              Position=3)]
   [ValidateNotNull()]
   [ValidateNotNullOrEmpty()]
   [ValidateSet("No filter", "No remakes", "Trusted only")]
   [string]
   $filter_type = "Trusted only",
   ```
   
   > The filter in the Nyaa site:
   
   ![Nyaa filter types](https://imgur.com/4dpTWrD.png)
   
   > Types of filters to change to: `"No filter"` `"No remakes"` `"Trusted only"`
   
---
   
- `$episode_quality` :

   ```powershell
   # Episode quality
   [Parameter(Mandatory=$false, 
              Position=3)]
   [ValidateNotNull()]
   [ValidateNotNullOrEmpty()]
   [ValidateSet("1080p", "720p", "480p")]
   [string]
   $episode_quality = "1080p",
   ```
   
   > Quality of the episodes downloaded, possible values: `"1080p"` `"720p"` `"480p"`
   
---

- `$uploaders` :

   ```powershell
   # Uploaders
   [Parameter(Mandatory=$false, 
              Position=4)]
   [ValidateNotNull()]
   [ValidateNotNullOrEmpty()]
   [string[]]
   $uploaders = @("Erai-raws","SSA","SmallSizedAnimations")
   ```
   
   > The uploaders that will be taken into account when searching for episodes
   
   > You can add or remove them by changing the values in the `@( ... )` area, values in quotations and seperated by comma
   

# Running the script

Running the script is as easy as right click and clicking the `Run with Powershell` button:

![Running the script](https://imgur.com/mKlwTqE.png)
