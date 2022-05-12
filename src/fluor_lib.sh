#!/system/bin/sh
#
# FluorineEngine Core Library (c) 2022
# Author: xprjkt°
#

####################
# Variables
####################

modpath="/data/adb/modules/Fluorine/"
xlog_path="/data/media/0/fluorine.log"
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
cpu_gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)

xlog() { echo -e "[$(date +%T)]: [*]  $@" >>"$klog"; }

xmsg()
{
	case $* in
                "-n") echo "[*] $@" ;;
                "-w"|"--warn") echo "[!] $@" ;;
        esac
}

write()
{
	# Bail out if file does not exist
	[[ ! -f "$1" ]] && {
		xlog "$1 doesn't exist, skipping..."
		return 1
	}

	# Make file writable in case it is not already
	chmod +rw "$1" 2>/dev/null

	# Fetch the current key value
	curval=$(cat "$1" 2>/dev/null)

	# Bail out if value is already set
	[[ "$curval" == "$2" ]] && {
		xlog "$1 is already set to $2, skipping..."
		return 0
	}

	# Write the new value and bail if there's an error
	! echo -n "$2" >"$1" 2>/dev/null && {
		xlog "failed: $1 -> $2"
		return 1
	}

	# Log the success
	xlog "$1 $curval -> $2"
}

print_info()
{
	xlog "------- Fluorine° General info"
	xlog ""
	xlog "** Date of execution: $(date)"
	xlog "** Kernel: $kern_ver_name, $kern_bd_dt"
	xlog "** SOC: $soc_mf, $soc"
	xlog "** SDK: $sdk"
	xlog "** Android version: $avs"
	xlog "** Android ID: $(settings get secure android_id)"
	xlog "** CPU governor: $cpu_gov"
	xlog "** Number of CPUs: $nr_cores"
	xlog "** CPU freq: $cpu_min_clk_mhz-${cpu_max_clk_mhz}MHz"
	xlog "** CPU scheduling type: $cpu_sched"
	xlog "** Arch: $arch"
	xlog "** GPU freq: $gpu_min_clk_mhz-${gpu_max_clk_mhz}MHz"
	xlog "** GPU model: $gpu_mdl"
	xlog "** GPU governor: $gpu_gov"
	xlog "** Device: $dvc_brnd, $dvc_cdn"
	xlog "** ROM: $rom_info"
	xlog "** Screen resolution: $(wm size | awk '{print $}' | tail -n 1)"
	xlog "** Screen density: $(wm density | awk '{print $}' | tail -n 1) PPI"
	xlog "** Supported refresh rate: ${rr}HZ"
	xlog "** lib version: $lib_ver"
	xlog "** Battery charge level: $batt_pctg%"
	xlog "** Battery total capacity: ${batt_cpct}mAh"
	xlog "** Battery health: $batt_hth"
	xlog "** Battery status: $batt_sts"
	xlog "** Battery temperature: $batt_tmp°C"
	xlog "** Root: $root"
	xlog "** Current PID: $$"
	xlog ""
	xlog "-------"
}

# Current battery capacity available
[[ -e "/sys/class/power_supply/battery/capacity" ]] && batt_pctg=$(cat /sys/class/power_supply/battery/capacity) || batt_pctg=$(dumpsys battery 2>/dev/null | awk '/level/{print $2}')

# Battery temperature
batt_tmp=$(dumpsys battery 2>/dev/null | awk '/temperature/{print $2}')
[[ "$batt_tmp" == "" ]] && [[ -e "/sys/class/power_supply/battery/temp" ]] && batt_tmp=$(cat /sys/class/power_supply/battery/temp) || [[ "$batt_tmp" == "" ]] && [[ -e "/sys/class/power_supply/battery/batt_temp" ]] && batt_tmp=$(cat /sys/class/power_supply/battery/batt_temp)

# Transform this since we will use two algarisms only
batt_tmp=$((batt_tmp / 10)

# Max refresh rate
rr=$(dumpsys display 2>/dev/null | awk '/PhysicalDisplayInfo/{print $4}' | cut -c1-3 | tr -d .)
[[ -z "$rr" ]] && rr=$(dumpsys display 2>/dev/null | grep refreshRate | awk -F '=' '{print $6}' | cut -c1-3 | tail -n 1 | tr -d .) || rr=$(dumpsys display 2>/dev/null | grep FrameRate | awk -F '=' '{print $6}' | cut -c1-3 | tail -n 1 | tr -d .)

# Battery health
batt_hth=$(dumpsys battery 2>/dev/null | awk '/health/{print $2}')
[[ -e "/sys/class/power_supply/battery/health" ]] && batt_hth=$(cat /sys/class/power_supply/battery/health)
case "$batt_hth" in
	1) batt_hth="Unknown" ;;
	2) batt_hth="Good" ;;
	3) batt_hth="Overheat" ;;
	4) batt_hth="Dead" ;;
	5) batt_hth="OV" ;;
	6) batt_hth="UF" ;;
	7) batt_hth="Cold" ;;
	*) batt_hth="$batt_hth" ;;
esac

# Battery status
batt_sts=$(dumpsys battery 2>/dev/null | awk '/status/{print $2}')
[[ -e "/sys/class/power_supply/battery/status" ]] && batt_sts=$(cat /sys/class/power_supply/battery/status)
case "$batt_sts" in
	1) batt_sts="Unknown" ;;
	2) batt_sts="Charging" ;;
	3) batt_sts="Discharging" ;;
	4) batt_sts="Not charging" ;;
	5) batt_sts="Full" ;;
	*) batt_sts="$batt_sts" ;;
esac

# Battery total capacity
batt_cpct=$(cat /sys/class/power_supply/battery/charge_full_design)
[[ "$batt_cpct" == "" ]] && batt_cpct=$(dumpsys batterystats 2>/dev/null | awk '/Capacity:/{print $2}' | cut -d "," -f 1)

# MA -> MAh
[[ "$batt_cpct" -ge "1000000" ]] && batt_cpct=$((batt_cpct / 1000))

enable_devfreq_boost()
{
	for dir in /sys/class/devfreq/*/; do
		max_devfreq=$(cat "${dir}available_frequencies" | awk -F ' ' '{print $NF}')
		max_devfreq2=$(cat "${dir}available_frequencies" | awk -F ' ' '{print $1}')
		[[ "$max_devfreq2" -gt "$max_devfreq" ]] && max_devfreq="$max_devfreq2"
		write "${dir}min_freq" "$max_devfreq"
		write "${dir}bw_hwmon/hyst_length" "0"
		write "${dir}bw_hwmon/hist_memory" "0"
		write "${dir}bw_hwmon/hyst_trigger_count" "0"
		for i in /sys/class/devfreq/*-bw/; do
			write "${i}bw_hwmon/io_percent" "80"
			write "${i}bw_hwmon/sample_ms" "10"
		done
		write "/dev/cpu_dma_latency" "61"
	done
	xlog "enabled devfreq boost"
}

disable_devfreq_boost()
{
	for dir in /sys/class/devfreq/*/; do
		min_devfreq=$(cat "${dir}available_frequencies" | awk -F ' ' '{print $1}')
		min_devfreq2=$(cat "${dir}available_frequencies" | awk -F ' ' '{print $NF}')
		[[ "$min_devfreq2" -lt "$min_devfreq" ]] && min_devfreq="$min_devfreq2"
		write "${dir}min_freq" "$min_devfreq"
		write "${dir}bw_hwmon/hyst_length" "10"
		write "${dir}bw_hwmon/hist_memory" "20"
		write "${dir}bw_hwmon/hyst_trigger_count" "3"
		for i in /sys/class/devfreq/*-bw/; do
			write "${i}bw_hwmon/io_percent" "80"
			write "${i}bw_hwmon/sample_ms" "4"
		done
		write "/dev/cpu_dma_latency" "100"
	done
	xlog "disabled devfreq boost"
}
