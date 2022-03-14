#!/system/bin/sh
# Copyright (C) 2022 The Fluorine Project
#
#                    The Linux Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#####################
# Engine Variables
#####################

fluorineversion="0.01"
#enginestatus=$($?)
logpath="/sdcard/.fluorine/atom.log"
workpath="/sdcard/.fluorine"

#####################
# START
#####################

[ ! -f $workpath ] || mkdir $workpath

#####################
# Kernel Variables
#####################

kernel="/proc/sys/kernel/"
vm="/proc/sys/vm/"
sched_features="/sys/kernel/debug/sched_features"
raid="/proc/sys/dev/raid/"
pty="/proc/sys/kernel/pty/"
keys="/proc/sys/kernel/keys/"
fs="/proc/sys/fs/"
lmk="/sys/module/lowmemorykiller/parameters/"
lpm="/sys/module/lpm_levels/"
mmc="/sys/module/mmc_core/parameters/"
blkio="/dev/blkio/"
net="/proc/sys/net/"

printmsg()
{
	case $1 in
		"-n") echo "[*] $2" ;;
		"-w") echo "[!] $2" ;;
		"--custom-msg") echo "[$2] $3" ;;
		"--log") echo "[ $(date +"%X") ]: $2" >> $logpath ;;
	esac
}

write(){
	writefunc()
	{
		[ ! -f "$2" ] && return 1         # Bail out if file does not exist

		chmod +w "$2" 2>/dev/null         # Make file write-able in case it is not already

        	if ! echo "$3" > "$2" 2>/dev/null # Write the new value and bail if there's an error
	        then
        	        echo "[!] Failed: $2 --> $3"
                	return 1
	        fi

        	# Log the success
        	echo "[*] Success: $2 --> $3"
	}
}

log_sys()
{
	while true; do
		if [ ! -d $logpath ]; then
			rm $logpath
			echo "--------------------------" >> $logpath
			echo " Fluorine Logging System  " >> $logpath
			echo "--------------------------" >> $logpath
			echo "" >> $logpath
			return 1
#		elif [ -d $logpath ]; then
			printmsg --log started
		fi
	done
}

if [ $# -eq "0" ] && tty -s
then
	__print_help
fi
