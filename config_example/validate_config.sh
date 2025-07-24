#!/bin/bash

if [ $# -eq 0 ]; then
    echo "用法: $0 <config_file.json>"
    echo "範例: $0 config_mix_modern.json"
    exit 1
fi

config_file="$1"

if [ ! -f "$config_file" ]; then
    echo "❌ 錯誤: 配置文件 '$config_file' 不存在"
    exit 1
fi

echo "=== 配置文件驗證器 ==="
echo "檢查文件: $config_file"
echo

# 檢查 JSON 語法
echo "1. 檢查 JSON 語法..."
if command -v python3 >/dev/null 2>&1; then
    if python3 -m json.tool "$config_file" >/dev/null 2>&1; then
        echo "✓ JSON 語法正確"
    else
        echo "❌ JSON 語法錯誤"
        python3 -m json.tool "$config_file"
        exit 1
    fi
elif command -v jq >/dev/null 2>&1; then
    if jq empty "$config_file" >/dev/null 2>&1; then
        echo "✓ JSON 語法正確"
    else
        echo "❌ JSON 語法錯誤"
        jq empty "$config_file"
        exit 1
    fi
else
    echo "⚠️  無法檢查 JSON 語法 (需要 python3 或 jq)"
fi

# 檢查必要欄位
echo
echo "2. 檢查必要欄位..."

# 檢查全域設定
if grep -q '"seting"' "$config_file"; then
    echo "✓ 找到全域設定 (seting)"
    
    if grep -q '"pixel"' "$config_file"; then
        echo "✓ 找到像素設定 (pixel)"
    else
        echo "❌ 缺少像素設定 (pixel)"
    fi
    
    if grep -q '"dev"' "$config_file"; then
        echo "✓ 找到設備設定 (dev)"
    else
        echo "❌ 缺少設備設定 (dev)"
    fi
    
    if grep -q '"addr"' "$config_file"; then
        echo "✓ 找到地址設定 (addr)"
    else
        echo "❌ 缺少地址設定 (addr)"
    fi
else
    echo "❌ 缺少全域設定 (seting)"
fi

# 檢查頁面設定
echo
echo "3. 檢查頁面設定..."
page_count=$(grep -c '"page"' "$config_file")
echo "找到 $page_count 個頁面設定"

if [ $page_count -gt 0 ]; then
    echo "✓ 找到頁面設定"
else
    echo "❌ 沒有找到頁面設定"
fi

# 檢查顯示元素
echo
echo "4. 檢查顯示元素..."
display_count=$(grep -c '"display"' "$config_file")
echo "找到 $display_count 個顯示區塊"

if [ $display_count -gt 0 ]; then
    echo "✓ 找到顯示元素"
else
    echo "❌ 沒有找到顯示元素"
fi

# 檢查功能編號
echo
echo "5. 檢查功能編號..."
func_numbers=$(grep -o '"func":[0-9]*' "$config_file" | grep -o '[0-9]*' | sort -u)

if [ -n "$func_numbers" ]; then
    echo "使用的功能編號:"
    for func in $func_numbers; do
        case $func in
            0) echo "  $func - 日期" ;;
            1) echo "  $func - 時間" ;;
            2) echo "  $func - CPU溫度" ;;
            3) echo "  $func - CPU使用率" ;;
            4) echo "  $func - CPU頻率" ;;
            5) echo "  $func - IP地址" ;;
            6) echo "  $func - 總內存" ;;
            7) echo "  $func - 已用內存" ;;
            8) echo "  $func - 內存使用率" ;;
            9) echo "  $func - 總存儲" ;;
            10) echo "  $func - 已用存儲" ;;
            11) echo "  $func - 存儲使用率" ;;
            20) echo "  $func - RX eth0" ;;
            21) echo "  $func - TX eth0" ;;
            22) echo "  $func - RX wlan0" ;;
            23) echo "  $func - TX wlan0" ;;
            *) echo "  $func - ⚠️  未知功能編號" ;;
        esac
    done
else
    echo "沒有找到功能編號"
fi

# 檢查網路介面
echo
echo "6. 檢查網路介面..."
ports=$(grep -o '"port":"[^"]*"' "$config_file" | grep -o '[^"]*"$' | sed 's/"$//' | sort -u)

if [ -n "$ports" ]; then
    echo "使用的網路介面:"
    for port in $ports; do
        if [ -d "/sys/class/net/$port" ]; then
            echo "  $port - ✓ 存在"
        else
            echo "  $port - ❌ 不存在"
        fi
    done
else
    echo "沒有找到網路介面設定"
fi

# 檢查座標範圍
echo
echo "7. 檢查座標範圍..."
x_coords=$(grep -o '"x[0-9]*":[0-9]*' "$config_file" | grep -o '[0-9]*$' | sort -n)
y_coords=$(grep -o '"y[0-9]*":[0-9]*' "$config_file" | grep -o '[0-9]*$' | sort -n)

if [ -n "$x_coords" ]; then
    max_x=$(echo "$x_coords" | tail -1)
    if [ $max_x -gt 127 ]; then
        echo "❌ X座標超出範圍: $max_x (最大127)"
    else
        echo "✓ X座標範圍正常 (最大: $max_x)"
    fi
fi

if [ -n "$y_coords" ]; then
    max_y=$(echo "$y_coords" | tail -1)
    if [ $max_y -gt 63 ]; then
        echo "❌ Y座標超出範圍: $max_y (最大63)"
    else
        echo "✓ Y座標範圍正常 (最大: $max_y)"
    fi
fi

# 檢查 blank 頁面
echo
echo "8. 檢查 blank 頁面..."
if grep -q '"blank"' "$config_file"; then
    echo "✓ 找到 blank 頁面"
else
    echo "⚠️  建議添加 blank 頁面用於清屏"
fi

echo
echo "=== 驗證完成 ==="
echo
echo "建議測試指令:"
echo "  ./ssd_oled -c $config_file"
echo
echo "如果測試正常，可以部署:"
echo "  cp $config_file /etc/oled/config.json"
echo "  killall ssd_oled && ssd_oled &"