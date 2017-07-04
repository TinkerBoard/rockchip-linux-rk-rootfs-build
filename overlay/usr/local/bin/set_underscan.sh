if [[ $1 -eq 0 ]] ; then
    echo 'you need set percentage (<= 100) '
    exit 1
fi
#Before using modetest, need stop modetest fire otherwise the device can't be found.
service lightdm stop
#find the active crtc id
crtc_id=`modetest -M rockchip | grep TMDS | awk '{print $2}'`
modetest -M rockchip -w $crtc_id:bottom\ margin:$1
modetest -M rockchip -w $crtc_id:top\ margin:$1
modetest -M rockchip -w $crtc_id:right\ margin:$1
modetest -M rockchip -w $crtc_id:left\ margin:$1
service lightdm start
