#!/bin/bash

app_name="display-brightness-automatic-controller"
version="0.0.2"

enabled=1
temp_path="/tmp"
capture_source=/dev/video0
screen=/sys/class/backlight/intel_backlight
min_fact_brightness=0.03
max_fact_brightness=1.0

while getopts e:t:s:n:x: option
do
case "${option}"
in
e) enabled=${OPTARG};;
t) temp_path=${OPTARG};;
s) screen=${OPTARG};;
n) min_fact_brightness=${OPTARG};;
x) max_fact_brightness=${OPTARG};;
esac
done

tmp_file_path="$temp_path/$appName.jpeg"
screen_max_brightness="$screen/max_brightness"
screen_brightness="$screen/brightness"

if [ -z "`whereis streamer | grep /`" ];	then 
    echo "$app_name: streamer [Not installed]"
    exit 1
fi
if [ -z "`whereis convert | grep /`" ];	then 
    echo "$app_name: convert [Not installed]"
    exit 1
fi
if [ ! $enabled -eq 1 ] ; then
    echo "Not enabled. Exiting."
    exit 0
fi
if [ ! -d "$temp_path" ]; then
    echo "Temp directory not found!"
    exit 3
fi
if [ ! -f "$screen_max_brightness" ]; then
    echo "Screen max_brightness not found!"
    exit 5
fi
if [ ! -f "$screen_brightness" ]; then
    echo "Screen brightness not found!"
    exit 6
fi
camera_in_use=$(lsof | grep $capture_source)
if [[ ! -z $camera_in_use ]]; then
    echo "Camera in use. Exiting..."
    exit 0
fi

# run
max_dev_brightness=$(cat $screen_max_brightness)
streamer -w 2 -q -b 16 -o $tmp_file_path
mean_pixel_grey=$(convert $tmp_file_path -quiet -grayscale Rec709Luma -format "%[fx:r]" info:-)
echo "Captured $mean_pixel_grey as mean pixel grey"
rm $tmp_file_path
min_brightness=$(echo "$min_fact_brightness*$max_dev_brightness" | bc )
max_brightness=$(echo "$max_fact_brightness*$max_dev_brightness" | bc )
calc_brightness=$(echo "$min_brightness+$mean_pixel_grey*($max_brightness-$min_brightness)" | bc | cut -d '.' -f 1 )
# needs sudo
echo $calc_brightness > $screen_brightness
echo "Set $calc_brightness/$max_dev_brightness brightness level. Have a nice day!"

