# CHParser

## What is CHParser?

CHParser is a tool written in PowerShell that automatically correlates timestamps from the $UsnJrnl to the consolehost_history.txt file, and outputs this information into an easily read csv file.

## How is this useful?

The consolehost file on a Windows system contains the last 4096 commands that were ran on that local system in chronological order, which is a great resource during forensics and incident response. However, this file does not contain timestamps. In order to get accurate timestamps for each specific commands, another resource needs to be used; the $UsnJrnl. The $UsnJrnl contains timestamps for when files on an NTFS system are modified / updated. By matching the most recent timestamps from the $UsnJrnl to the order of commands within the consolehost file, you can derive accurate timestamps for each attempted command run.  

## Usage

```
# Arguments
-usn (optional) Path to a text file that already contains saved USN Journal output
-vol Path to the $UsnJrnl to correlate timestamps (if -f is not supplied, it will default to C:)
-file (optional) The path to the consolehost_history.txt file to retrieve commands, if no path is given then it will default to C:\Users\<user>\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
-out Path to csv output
```

Cmdline usage examples:
```
.\chparser.ps1 -f <path to $usnJrnl> -c <path to consolehost_history.txt> -o <output.csv>

# Example
.\chparser.ps1 -f D: -c evidence/consolehost_history.txt -o results/chresults.csv
```

