#!/bin/bash

echo "=== OLED 程式部署腳本 ==="
echo

# 檢查是否為 root 用戶
if [ "$EUID" -ne 0 ]; then
    echo "請使用 root 權限執行此腳本"
    echo "使用方法: sudo ./deploy.sh"
    exit 1
fi

echo "1. 停止現有的 OLED 程式..."
killall ssd_oled 2>/dev/null || echo "沒有運行中的 ssd_oled 程式"
killall ssd 2>/dev/null || echo "沒有運行中的 ssd 程式"
killall sj_oled 2>/dev/null || echo "沒有運行中的 sj_oled 程式"

echo "2. 編譯程式..."
make clean
make

if [ ! -f "ssd_oled" ]; then
    echo "編譯失敗！請檢查錯誤訊息"
    exit 1
fi

echo "3. 複製程式到系統目錄..."
cp ssd_oled /bin/
chmod +x /bin/ssd_oled

echo "4. 創建配置目錄..."
mkdir -p /etc/oled

echo "5. 複製配置檔案..."
cp config_updated.json /etc/oled/config.json

echo "6. 備份並更新 rc.local..."
if [ -f "/etc/rc.local" ]; then
    cp /etc/rc.local /etc/rc.local.backup
    echo "已備份原始 rc.local 到 /etc/rc.local.backup"
fi

# 創建新的 rc.local
cat > /etc/rc.local << 'EOF'
#!/bin/bash
# 
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

# 停止舊的 OLED 程式
#sj_oled >/dev/null 1>&2 &

# 啟動新的 OLED 程式
ssd_oled >/dev/null 1>&2 &

exit 0
EOF

chmod +x /etc/rc.local

echo "7. 測試程式..."
echo "測試系統指令..."
./test_commands.sh

echo
echo "8. 啟動 OLED 程式..."
/bin/ssd_oled >/dev/null 1>&2 &

if pgrep ssd_oled > /dev/null; then
    echo "✅ OLED 程式啟動成功！"
else
    echo "❌ OLED 程式啟動失敗，請檢查硬體連接"
fi

echo
echo "=== 部署完成 ==="
echo
echo "程式位置: /bin/ssd_oled"
echo "配置檔案: /etc/oled/config.json"
echo "自啟動: 已配置在 /etc/rc.local"
echo
echo "手動控制指令:"
echo "  啟動: ssd_oled &"
echo "  停止: killall ssd_oled"
echo "  測試: ssd_oled -c /etc/oled/config.json"
echo "  清屏: ssd_oled -clean"
echo