#!/bin/bash

echo +20 > /sys/class/rtc/rtc0/wakealarm
pm-suspend
