# Here we determine how the system will identify the particular drive
# we want to mount. You should be able to make this script work for
# you just by identifying the correct value for $target.
$target = "**MODEL**"
$target_device_id = GET-CimInstance -query "SELECT * from Win32_DiskDrive" | Where-Object {$_.Model -eq "$target"} | Select-Object -Expand DeviceID

# ======

# This is purely cosmetic and can be whatever you please.
$big_text = "LET’S MOUNT A DRIVE"

# ======

# And here’s the udev rule that mounts the drive once Linux sees it.
# Notice that it assumes we’re mounting only one partition. If you’ve
# got anything more complex going on, you might want to make the rule
# execute a script.
#
# ACTION=="add", SUBSYSTEM=="block", ATTRS{model}=="WDC WD60EZAZ-00S", RUN+="/bin/mount -t btrfs -o noexec,rw /dev/%k1 /mnt/butter"

# ======

function Write-CenteredOutput {
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

function Write-Banner {
    param($message)
    $border = ("=" * $message.Length)
    foreach ($line in $border, $message, $border) {
        Write-CenteredOutput $line
    }
}

function Write-ErrorBanner {
    $error_preamble = "UH OH!"
    while ($error_preamble.Length -lt $Host.UI.RawUI.BufferSize.Width) {
        $error_preamble = $error_preamble + " // " + $error_preamble
    }
    $error_preamble = $error_preamble.Substring(0, $Host.UI.RawUI.BufferSize.Width)
    Write-Host $error_preamble -ForegroundColor White -BackgroundColor DarkRed
    Write-Output "`n"
}

# ======

# ACT I: First we declare our intentions.

Write-Output "`n"
Write-Banner "$big_text" | wsl.exe lolcat
Write-Output "`n"
Write-CenteredOutput "Making the device $target available to the Linux subsystem..." | wsl.exe lolcat
Write-Output "`n"

# ACT II: Then we do the thing.

# If we failed to isolate a device ID, there’s nothing to mount.
if ($target_device_id.Length -eq 0) {
    Write-ErrorBanner
    Write-CenteredOutput "Failed to isolate a device ID." | wsl.exe lolcat

    foreach ($line in `
    "Double-check the value of the variable `"`$target`"", `
    "at the beginning of this script, or try massaging", `
    "the pipeline that defines `"`$target_device_id`".") {
        Write-CenteredOutput $line
    }

    Write-Output "`n"
    Read-Host -Prompt (Write-CenteredOutput "Press any key to exit")
    return
}

[array] $mount_command_output = (wsl.exe --mount "$target_device_id" --bare)

if ($LASTEXITCODE -ne 0) {
    # Looks like something went wrong.
    # We’d better be loud about it.
    $problem = "yup"
    Write-ErrorBanner
    Write-CenteredOutput "wsl.exe --mount returned the following error:"
}
else {
    # Looks like the operation was a success.
    $problem = "nope"
}

# ACT III: We assess the results.

# Here’s the output from the mount command.
foreach ($line in $mount_command_output) {
    # The replace argument here compensates for an
    # annoying encoding mismatch between WSL and PowerShell.
    Write-CenteredOutput ($line -replace "`0","") | wsl.exe lolcat
}
# If the mount seems to have worked, we exit automatically.
if ($problem -eq "nope") {
    Write-CenteredOutput "This message will self-destruct." | wsl.exe lolcat
    Start-Sleep -Seconds 5
}
# If not, we want to know about it.
if ($problem -eq "yup") {
    Read-Host -Prompt (Write-CenteredOutput "Press any key and despair")
}