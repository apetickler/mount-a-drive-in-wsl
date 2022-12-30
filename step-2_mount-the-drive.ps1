# Here we determine how the system will identify the particular drive
# we want to mount. You should be able to make this script work for
# you just by identifying the correct value for $target.
$target = "**MODEL**"
$target_device_id = GET-CimInstance -query "SELECT * from Win32_DiskDrive" | Where-Object {$_.Model -eq "$target"} | Select-Object -Expand DeviceID

# ======

# This is purely cosmetic and can be whatever you please.
$big_text = "**TITLE**"

# ======

function Write-Output-Centered {
    # I stole this function from
    # https://stackoverflow.com/questions/48621267/is-there-a-way-to-center-text-in-powershell
    param($message)
    Write-Output (
        "{0}{1}" -f (
            ' ' * (
                (
                    [Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($message.Length / 2)
                    )
                )
            ),
            $message
        )
}

function Banner {
    param($message)
    $border = ("=" * $message.Length)
    foreach ($line in $border, $message, $border) {
        Write-Output-Centered $line
    }
}

# ======

# ACT I: First we declare our intentions.
Write-Output "`n"
Banner "$big_text" | wsl.exe lolcat
Write-Output "`n"
Write-Output-Centered "Making the device $target available to the Linux subsystem..." | wsl.exe lolcat
Write-Output "`n"

# ACT II: Then we do the thing.
[array] $mount_command_output = (wsl.exe --mount "$target_device_id" --bare)

if ($LASTEXITCODE -ne 0) {
    # Looks like something went wrong.
    # We’d better be loud about it.
    $problem = "yup"
    $error_preamble = "UH OH!"
    while ($error_preamble.Length -lt $Host.UI.RawUI.BufferSize.Width) {
        $error_preamble = $error_preamble + " // " + $error_preamble
    }
    $error_preamble = $error_preamble.Substring(0, $Host.UI.RawUI.BufferSize.Width)
    Write-Host $error_preamble -ForegroundColor White -BackgroundColor DarkRed
    Write-Output "`n"
    Write-Output-Centered "wsl.exe --mount returned the following error:" | wsl.exe lolcat
}
else {
    # Looks like the operation was a success.
    $problem = "nope"
}

# ACT III: Here’s the output from the mount command.
foreach ($line in $mount_command_output) {
    # The replace argument here compensates for an
    # annoying encoding mismatch between WSL and PowerShell.
    Write-Output-Centered ($line -replace "`0","") | wsl.exe lolcat
}
# If the mount seems to have worked, we exit automatically.
if ($problem -eq "nope") {
    Write-Output-Centered "This message will self-destruct." | wsl.exe lolcat
    Start-Sleep -Seconds 5
}
# If not, we want to know about it.
if ($problem -eq "yup") {
    Read-Host -Prompt (Write-Output-Centered "Press any key and despair")
}