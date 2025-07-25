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
# 檢查是否為更新編譯
if [ -f "/bin/ssd_oled" ]; then
    echo "檢測到現有的 ssd_oled 程式，這可能是更新編譯"
    UPDATE_MODE=true
else
    UPDATE_MODE=false
fi

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

echo "5. 處理配置檔案..."
if [ "$UPDATE_MODE" = true ] && [ -f "/etc/oled/config.json" ]; then
    echo "檢測到現有配置檔案，保留用戶設定"
    echo "如需使用新配置，請手動複製 config_example/ 中的檔案"
else
    echo "複製預設配置檔案..."
    cp config_example/config_basic.json /etc/oled/config.json
fi

echo "6. 配置自啟動..."

# 檢查是否存在舊的 sj_oled 程式
if command -v sj_oled >/dev/null 2>&1; then
    echo "⚠️  檢測到舊的 sj_oled 程式存在"
    echo "   理應您的 OLED 先前可以正常顯示，請自行停用 sj_oled避免衝突"
    echo "   您可以手動編輯 /etc/rc.local 來調整啟動設定"
fi

# 檢查 rc.local 是否存在
if [ ! -f "/etc/rc.local" ]; then
    echo "創建新的 rc.local..."
    cat > /etc/rc.local << 'EOF'
#!/bin/bash
# 
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.

# 啟動 OLED 程式
ssd_oled >/dev/null 1>&2 &

exit 0
EOF
    chmod +x /etc/rc.local
    echo "✅ 已創建 rc.local 並添加自啟動"
else
    # 檢查是否已經包含 ssd_oled
    if grep -q "ssd_oled" /etc/rc.local; then
        echo "✅ rc.local 中已包含 ssd_oled 啟動命令 (可能是更新編譯)"
    else
        # 備份原始檔案
        cp /etc/rc.local /etc/rc.local.backup
        echo "已備份原始 rc.local 到 /etc/rc.local.backup"
        
        # 在 exit 0 前添加啟動命令
        if grep -q "exit 0" /etc/rc.local; then
            # 在 exit 0 前插入啟動命令
            sed -i '/exit 0/i ssd_oled >/dev/null 1>&2 &' /etc/rc.local
            echo "✅ 已在 rc.local 中添加自啟動命令"
        else
            # 如果沒有 exit 0，直接添加到末尾
            echo "" >> /etc/rc.local
            echo "# 啟動 OLED 程式" >> /etc/rc.local
            echo "ssd_oled >/dev/null 1>&2 &" >> /etc/rc.local
            echo "" >> /etc/rc.local
            echo "exit 0" >> /etc/rc.local
            echo "✅ 已在 rc.local 末尾添加自啟動命令"
        fi
    fi
    chmod +x /etc/rc.local
fi

echo "7. 測試程式..."
echo "測試系統指令..."
./test_commands.sh

echo

echo
if [ "$UPDATE_MODE" = true ]; then
    echo "=== 更新完成 ==="
    echo
    echo "✅ 程式已更新到最新版本"
    echo "✅ 保留了現有配置檔案"
    echo "✅ 自啟動設定未變更"
else
    echo "=== 部署完成 ==="
    echo
    echo "✅ 程式已安裝到系統"
    echo "✅ 配置檔案已設置"
    echo "✅ 自啟動已配置"
fi
echo
echo "程式位置: /bin/ssd_oled"
echo "配置檔案: /etc/oled/config.json"
echo "自啟動: 已配置在 /etc/rc.local"
echo
echo "📋 手動控制指令:"
echo "  啟動: ssd_oled &"
echo "  停止: killall ssd_oled"
echo "  測試: ssd_oled -c /etc/oled/config.json"
echo "  清屏: ssd_oled -clean"
echo
echo "🎨 可用配置檔案:"
echo "  基本版: cp config_example/config_basic.json /etc/oled/config.json"
echo "  分類版: cp config_example/config_multipage_clean.json /etc/oled/config.json"
echo "  精美版: cp config_example/config_multipage_premium.json /etc/oled/config.json"
echo
echo "⚠️  注意事項:"
echo "  請重新啟動系統以應用自啟動設定"
if [ "$UPDATE_MODE" = true ]; then
    echo "  - 這是更新編譯，現有設定已保留"
    echo "  - 如需使用新功能，請參考 config_example/ 中的新配置"
else
    echo "  - 如果檢測到 sj_oled 程式，請確認是否需要停用"
fi
echo "  - 重啟後程式會自動啟動"
echo "  - 如需修改啟動設定，請編輯 /etc/rc.local"
echo