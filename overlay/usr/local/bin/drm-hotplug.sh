#!/bin/sh -x

LIGHTDM_DIR=/var/run/lightdm/root/
if [ -d $LIGHTDM_DIR ]; then
	export DISPLAY=$(ls $LIGHTDM_DIR)
	export XAUTHORITY=$LIGHTDM_DIR/$DISPLAY
fi

export DISPLAY=${DISPLAY:-:0}

# Find an authorized user
unset USER
for user in root $(users);do
    sudo -u $user xdpyinfo 2>/dev/null >&2 && \
        { USER=$user; break; }
done
[ $USER ] || exit 0

# Find disconnected monitors
MONITORS_DISCONNECTED=$(sudo -u $user xrandr|grep -w disconnected|cut -d' ' -f1)
for monitor in $MONITORS_DISCONNECTED;do
    # handle disconnected
    sudo -u $user xrandr --output $monitor --off
done


# Find connected monitors
MONITORS_CONNECTED=$(sudo -u $user xrandr|grep -w connected|cut -d' ' -f1)

# Make sure every connected monitors been enabled with a valid mode.
for monitor in $MONITORS_CONNECTED;do
    # Unlike the drm driver, X11 modesetting drv uses HDMI for HDMI-A
    CRTC=$(echo $monitor|sed "s/HDMI\(-[^B]\)/HDMI-A\1/")

    SYS="/sys/class/drm/card*-$CRTC/"
    MODE=$(cat $SYS/mode)

    # Already got a valid mode
    grep -w $MODE $SYS/modes && continue

    # Ether disabled or wrongly configured
    sudo -u $user xrandr --output $monitor --auto
done

exit 0
