#!/bin/bash
RPI="gamecat@10.42.0.2"
case "${1:-status}" in
  on)  ssh $RPI "echo 'admin_pass!' | sudo -S sed -i 's/arm_freq=.*/arm_freq=1500/' /boot/firmware/config.txt && grep -q maxcpus=2 /boot/firmware/cmdline.txt || echo 'admin_pass!' | sudo -S sed -i '\$s/\$/ maxcpus=2/' /boot/firmware/cmdline.txt && echo 'admin_pass!' | sudo -S reboot" ;;
  off) ssh $RPI "echo 'admin_pass!' | sudo -S sed -i '/arm_freq=/d' /boot/firmware/config.txt && echo 'admin_pass!' | sudo -S sed -i 's/ maxcpus=2//' /boot/firmware/cmdline.txt && echo 'admin_pass!' | sudo -S reboot" ;;
  *)   ssh $RPI "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null; grep arm_freq /boot/firmware/config.txt 2>/dev/null; grep maxcpus /boot/firmware/cmdline.txt 2>/dev/null; uptime" ;;
esac
