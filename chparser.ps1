param(
    [Parameter(Mandatory = $true)]
    [string]$out,
    [string]$usn = "",
    [string]$vol = "C",
    [string]$file = ""
)

if ($vol -notmatch ":$") {
    $vol = "${vol}:"
}
if ([string]::IsNullOrWhiteSpace($file)) {
    $file = (Get-PSReadLineOption).HistorySavePath
}
if (-not (Test-Path $file)) {
    throw "Console history file $file does not exist."
}

$targetFileName = Split-Path $file -Leaf
$commands = Get-Content $file

if ($usn -ne "") {
    if (-not (Test-Path $usn)) {
        throw "USN input file $usn does not exist."
    }
    $source = Get-Content $usn
}
else {
    $source = fsutil usn readjournal $vol 2>$null
    if (-not $source) {
        throw "fsutil returned no data."
    }
}

$block   = @{}
$results = @()

foreach ($line in $source) {
    if ($line -match "^Usn\s*:") {
        if ($block.Count -gt 0 -and $block.FileName -and ($block.FileName -ieq $targetFileName)) {
            $results += [pscustomobject]@{
                Timestamp = $block.Timestamp
                Filename  = $block.FileName
                USN       = [int64]$block.Usn
                Command   = ""
            }
        }
        $block = @{}
        $block.Usn = ($line -split ":\s*",2)[1].Trim()
        continue
    }
    if ($line -match "^File name\s*:") {
        $block.FileName = ($line -split ":\s*",2)[1].Trim()
        continue
    }
    if ($line -match "^Time stamp\s*:") {
        $block.Timestamp = ($line -split ":\s*",2)[1].Trim()
        continue
    }
    if ($line -match "^Record length") {
        if ($block.FileName -and ($block.FileName -ieq $targetFileName)) {
            $results += [pscustomobject]@{
                Timestamp = $block.Timestamp
                Filename  = $block.FileName
                USN       = [int64]$block.Usn
                Command   = ""
            }
        }
        $block = @{}
        continue
    }
}

if ($block.Count -gt 0 -and $block.FileName -and ($block.FileName -ieq $targetFileName)) {
    $results += [pscustomobject]@{
        Timestamp = $block.Timestamp
        Filename  = $block.FileName
        USN       = [int64]$block.Usn
        Command   = ""
    }
}

$results = $results | Sort-Object USN
$recCount = $results.Count
$cmdCount = $commands.Count
$minCount = [Math]::Min($recCount, $cmdCount)

for ($i = 0; $i -lt $minCount; $i++) {
    $results[$recCount - 1 - $i].Command = $commands[$cmdCount - 1 - $i]
}

$results |
        Select-Object Timestamp, Filename, USN, Command |
        Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
