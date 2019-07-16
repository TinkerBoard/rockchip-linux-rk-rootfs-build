#!/bin/bash

echo +30 > /sys/class/rtc/rtc0/wakealarm
pm-suspend
