#!/bin/bash

echo "=== 測試修復後的系統指令 ==="
echo

echo "1. CPU 溫度:"
cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "溫度檢測失敗"
echo

echo "2. CPU 頻率:"
FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq 2>/dev/null)
if [ -n "$FREQ" ]; then
    echo "原始值: $FREQ kHz"
    echo "轉換值: $(echo "scale=1; $FREQ/1000000" | bc -l) GHz"
else
    echo "頻率檢測失敗"
fi
echo

echo "3. CPU 使用率:"
top -bn1 | awk '/%Cpu\(s\)/{printf 100-$8}' 2>/dev/null || echo "CPU使用率檢測失敗"
echo
echo

echo "4. 內存資訊:"
echo "總內存: $(free -m | awk '/Mem:/{print $2}') MB"
echo "已用內存: $(free -m | awk '/Mem:/{print $3}') MB"
echo "內存使用率: $(free -m | awk '/Mem:/{printf ($3)/$2*100}')%"
echo

echo "5. 存儲資訊 (根分區):"
echo "總容量: $(df / | tail -1 | awk '{print $2}') KB"
echo "已用容量: $(df / | tail -1 | awk '{print $3}') KB"
echo "使用率: $(df / | tail -1 | awk '{printf ($3)/$2*100}')%"
echo

echo "6. 網路介面:"
echo "ETH0 IP: $(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 2>/dev/null || echo '未連接')"
echo "WLAN IP: $(ip addr show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 2>/dev/null || echo '未連接')"
echo

echo "7. 網路流量:"
echo "ETH0 RX: $(cat /sys/class/net/eth0/statistics/rx_bytes 2>/dev/null | awk '{printf ($1)/1000000000}' || echo '0') GB"
echo "ETH0 TX: $(cat /sys/class/net/eth0/statistics/tx_bytes 2>/dev/null | awk '{printf ($1)/1000000000}' || echo '0') GB"
echo "WLAN RX: $(cat /sys/class/net/wlan0/statistics/rx_bytes 2>/dev/null | awk '{printf ($1)/1000000000}' || echo '0') GB"
echo "WLAN TX: $(cat /sys/class/net/wlan0/statistics/tx_bytes 2>/dev/null | awk '{printf ($1)/1000000000}' || echo '0') GB"
echo

echo "=== 測試完成 ==="