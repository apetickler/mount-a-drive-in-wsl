# Here’s the udev rule that mounts the drive once Linux sees it.
# Notice that it assumes we’re mounting only one partition. If you’ve
# got anything more complex going on, you might want to make the rule
# execute a script.

ACTION=="add", SUBSYSTEM=="block", ATTRS{model}=="**MODEL**", RUN+="/bin/mount -t **FILESYSTEM** -o **OPTIONS** /dev/%k1 /**MOUNT-POINT**"