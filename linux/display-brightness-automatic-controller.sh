#!/bin/bash

app_name="display-brightness-automatic-controller"
version="0.0.1"

enabled=1
temp_path="/tmp"
capture_source=/dev/video0
screen=/sys/class/backlight/acpi_video0
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

# run
max_dev_brightness=$(cat $screen_max_brightness)
streamer -q -b 16 -o $tmp_file_path
mean_pixel_grey=$(convert $tmp_file_path -quiet -grayscale Rec709Luma -format "%[fx:r]" info:-)
min_brightness=$(echo "$min_fact_brightness*$max_dev_brightness" | bc )
max_brightness=$(echo "$max_fact_brightness*$max_dev_brightness" | bc )
calc_brightness=$(echo "$min_brightness+$mean_pixel_grey*($max_brightness-$min_brightness)" | bc | cut -d '.' -f 1 )
echo $calc_brightness > $screen_brightness
rm $tmp_file_path
echo "Set $calc_brightness/$max_dev_brightness brightness level. Have a nice day!"

