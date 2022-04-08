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
logpath="/sdcard/.fluorine/atom.log"
workpath="/sdcard/.fluorine"

#####################
# START
#####################

[ ! -f $workpath ] || mkdir $workpath

#####################
# Kernel Variables
#####################

kernel="/proc/sys/kernel"
vm="/proc/sys/vm"
sched_features="/sys/kernel/debug/sched_features"
raid="/proc/sys/dev/raid"
pty="/proc/sys/kernel/pty"
keys="/proc/sys/kernel/keys"
fs="/proc/sys/fs"
lmk="/sys/module/lowmemorykiller/parameters"
lpm="/sys/module/lpm_levels"
mmc="/sys/module/mmc_core/parameters"
blkio="/dev/blkio/"
net="/proc/sys/net/"
kgsl="/sys/class/kgsl/kgsl-3d0"
stune="/dev/stune"

#####################
# Modes
#####################

energy()
{
	write "${kernel}perf_cpu_time_max_percent" "0"
	write "${kernel}sched_energy_aware" "1"
	write "${kernel}sched_schedstats" "1"
	write "${kernel}sched_boost" "0"
	write "${kernel}hung_task_timeout_secs" "0"
	write "${kernel}printk_devkmsg" "off"
	write "${kernel}sched_walt_cpu_high_irqload" "20000000"
	write "${kernel}sched_walt_init_task_load_pct" "10"
	write "${kernel}sched_tunable_scaling" "0"
	# VM Tweaks
	write "${vm}swap_ratio" "40"
	write "${vm}drop_caches" "3"
	write "${vm}swappiness" "100"
	write "${vm}stat_interval" "10"
	write "${vm}page-cluster" "0"
	write "${vm}reap_mem_on_sigkill" "1"
	write "${vm}block_dump" "0"
	# GPU Tweaks
	write "${kgsl}force_no_nap" "1"
	write "${kgsl}bus_split" "0"
	write "${kgsl}throttling" "0"
	write "${kgsl}force_rail_on" "1"
	write "${kgsl}force_bus_on" "1"
	write "${kgsl}force_clk_on" "1"
}

gaming()
{
	# Kernel
	write "${kernel}/sched_child_runs_first" "0"
	write "${kernel}/sched_energy_aware" "0"
	write "${kernel}/timer_migration" "0"
	write "${kernel}/perf_cpu_time_max_percent" "15"
	write "${kernel}/sched_min_granularity_ns" "3000000"
	write "${kernel}/sched_migration_cost_ns" "1000000"
	write "${kernel}/sched_nr_migrate" "128"
	write "${kernel}/sched_autogroup_enabled" "0"
	# Fs Tweaks
	write "${fs}/lease-break-time" "5"
	# VM Tweaks
	write "${vm}/stat_interval" "1"
	write "${vm}/vfs_cache_pressure" "75"
	write "${vm}/swappiness" "100"
	# Sched Tune
	write "${stune}/top-app/schedtune.boost" "6"
	write "${stune}/foreground/schedtune.boost" "1"
	write "${stune}/top-app/schedtune.prefer_idle" "1"
	write "${kgsl}/devfreq/adrenoboost" "3"
	write "/sys/module/cpu_input_boost/parameters/input_boost_duration" 128 	# Extras
	write "/sys/module/mmc_core/parameters/use_spi_crc" "0" 					# Extras
}

#####################
# Main Functions
#####################

__print_help()
{
cat <<EOF
FluorineEngine (c) 2022
Usage:
		-h, --help		-		print help menu and exit
EOF
}

printmsg()
{
	case $1 in
		"-n") echo "[*] $2" ;;
		"-w"|"--warn") echo "[!] $2" ;;
		"--custom-msg"|"-cm") echo "[$2] $3" ;;
		"--log"|"-l") echo "[$(date +"%X")]: $2" >> $logpath ;;
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
	else
		case $1 in
			"-h"|"-help") __print_help
			*) printmsg -w "Unknown Argument: [ $1 ]"; __print_help ;;
		esac
fi