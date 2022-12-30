# Scripts to help you mount physical Linux drives in WSL

There are all sorts of reasons you might want to have persistent, reliable access to a btrfs/ext4/etc. drive in WSL or Windows. Are are some scripts that will help!

Here are the broad strokes of what we’re dealing with:

* WSL doesn't automatically know about drives that Windows doesn't mount for itself; they have to be passed through using the "wsl.exe --mount" command.
* "wsl.exe --mount" requires admin privileges, but obviously we want it to happen non-interactively every time WSL boots up.
* Once that happens, Linux can mount the drive as you would expect.

Here’s our strategy:

###step-1_call-windows-scheduled-task.sh###
This script does just one thing: It invokes a Windows scheduled task, which you’ll have to create. It should be called each time WSL starts. I call it from the startup script specified in my wsl.conf file.

Change “`**TASK NAME**`” to whatever you think is appropriate.

###Step 1.5: The scheduled task###
The scheduled task shouldn’t actually run on a schedule; mine is scheduled to run just once, at a time in the distant past. The reason it’s a scheduled task is because that’s a technique for executing commands that require admin privileges while bypassing the UAC prompt. Does that look like a healthy operating system security model? That’s not for me to say.

The scheduled task needs to run with “highest privileges”, and it needs to simply call the Powershell script step-2_mount-the-drive.ps1. The name of the task needs to match what you entered in step 1 for “`**TASK NAME**`”.

###step-2_mount-the-drive.ps1###
This one needs to be customized to specify your hard drive’s model (set the variable `$target` near the top of the file), which you can find in the output of “`GET-CimInstance -query "SELECT * from Win32_DiskDrive"`”. It runs the “`wsl.exe --mount`” command, which allows your hard drive to appear in WSL, probably under `/dev`.

The script opens in a conhost window (ew!), so I’ve put some effort into making the output presentable with that in mind. The window will close itself after five seconds if the mount was successful; otherwise it will hang around so you can review the error.

**NOTE:** This file makes several calls to lolcat, which it expects to find installed under WSL. This is purely cosmetic. If you don’t have lolcat installed or if you find it to be in poor taste, you can simply remove all instances of “` | wsl.exe lolcat`”.

Once you’ve gotten this far, you should be able to see your drive listed in the output of `lsblk` under WSL.

###step-3_xx-mount-drive.rules###
You want WSL to mount your drive automatically, as soon as it sees it. If it’s connected via USB, then I’m guessing your Linux installation is configured to do this without requiring any action on your part.

Otherwise, you have a few options: You might write a systemd service, or an fstab entry with the `noauto` flag might work.

Don't get cocky and think you can simply add a "`wsl.exe mount`" command right after the "`wsl.exe --mount`" in your Powershell script. "`wsl.exe --mount`" runs asynchronously, so the hard drive won’t be available yet when your "`wsl.exe mount`" command runs.

I mean, I guess you could just slap a timer in between, like some sort of animal.

My strategy is to create a udev rule. Hopefully you can make this one work for you by filling it in with your own configuration info and popping it into `/etc/rdev/rules.d/`. Enter your own values for `**MODEL**`, `**FILESYSTEM**`, `**OPTIONS**`, and `**MOUNTPOINT**`. As a matter of convention, rename the file to begin with a two-digit number like all your other udev rules.

You should be able to find the correct value for `**MODEL**` by playing around with udevadm. If your configuration or use case differs substantially from mine, you might also need to adjust the device path or the value for `SUBSYSTEM`.

When you’re reasonably confident everything is in place, reboot WSL, and if all has gone well, you can see your drive’s contents at its mount point and you’re now off to the races. I hope I’ve saved you some trouble!
