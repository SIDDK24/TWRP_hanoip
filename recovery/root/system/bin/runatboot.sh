#!/system/bin/sh
#!/system/bin/sh

fstab_fixup()
{
	sed -i "s|fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized,keydirectory=/metadata/vold/metadata_encryption,quota,reservedsize=512M,sysfs_path=/sys/devices/platform/soc/1d84000.ufshc,checkpoint=fs|fileencryption=ice,quota,reservedsize=128M,checkpoint=fs|" /system/etc/recovery.fstab
	sed -i "/by-name\/metadata/d" /system/etc/recovery.fstab
}

avb_version()
{
	avb_version=""
	avb_version=$(getprop ro.boot.vbmeta.avb_version)
	    echo "avb version is: [$avb_version]"
	    case $avb_version in
	        1.0)
		        echo "Android 11 Stock Rom Detected"
			    fstab_fixup
			    setprop fbe.metadata.wrappedkey ""
			    setprop ro.product.first_api_level ""
	            ;;
	        *)
	            echo "Android 11+ ROM Detected"
		        setprop fbe.metadata.wrappedkey true
		        setprop ro.product.first_api_level 30
		        setprop ro.adb.secure=0
		        setprop ro.crypto.volume.filenames_mode=aes-256-cts
		        setprop ro.vendor.qti.va_aosp.support=1
	            ;;
	        esac
}

avb_version

exit 0

module_path=/vendor/lib/modules

touch_class_path=/sys/class/touchscreen
touch_path=
firmware_path=/vendor/firmware
firmware_file=

wait_for_poweron()
{
	local wait_nomore
	local readiness
	local count
	wait_nomore=60
	count=0
	while true; do
		readiness=$(cat $touch_path/poweron)
		if [ "$readiness" == "1" ]; then
			break;
		fi
		count=$((count+1))
		[ $count -eq $wait_nomore ] && break
		sleep 1
	done
	if [ $count -eq $wait_nomore ]; then
		return 1
	fi
	return 0
}

# Load TouchScreen Modules
insmod $module_path/exfat.ko
insmod $module_path/ilitek_v3_mmi.ko
insmod $module_path/mmi_info.ko
insmod $module_path/moto_f_usbnet.ko
insmod $module_path/qpnp_adaptive_charge.ko
insmod $module_path/sx933x_sar.ko
insmod $module_path/fpc1020_mmi.ko
insmod $module_path/mmi_annotate.ko
insmod $module_path/mmi_sys_temp.ko
insmod $module_path/mpq-adapter.ko
insmod $module_path/sensors_class.ko
insmod $module_path/utags.ko


cd $firmware_path
touch_product_string=$(ls $touch_class_path)
echo "ilitek"
firmware_file="FW_ILITEK_TDDI_TM.bin"
touch_path=/sys$(cat $touch_class_path/$touch_product_string/path | awk '{print $1}')
wait_for_poweron
echo $firmware_file > $touch_path/doreflash
echo 1 > $touch_path/forcereflash
sleep 5
echo 1 > $touch_path/reset

exit 0