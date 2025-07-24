# SSD1306 OLED 顯示器 - Armbian 現代化版本

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Armbian-orange.svg)](https://www.armbian.com/)
[![Hardware](https://img.shields.io/badge/Hardware-SSD1306-blue.svg)](https://www.adafruit.com/product/326)

適用於 Armbian 系統的現代化 SSD1306 OLED 顯示器系統監控程式。基於 JSON 配置系統，提供即時系統資訊顯示。

## 🙏 致謝與專案源起

本專案基於以下優秀專案的基礎進行重構和現代化：

- **[yishunzhikong/SSD1306_OLED_json](https://github.com/yishunzhikong/SSD1306_OLED_json)** - 原始 JSON 配置 OLED 顯示專案 (針對 OpenWrt)
- **[bearcatl/SSD1306_OLED_json](https://github.com/bearcatl/SSD1306_OLED_json)** - 擴展功能分支

感謝兩位原作者的卓越工作，為嵌入式 Linux 系統的 OLED 顯示提供了優秀的 JSON 配置化解決方案。本重構版本專門針對 Armbian 系統進行了現代化和相容性改進。

## 🎯 功能特色

- **現代兼容性**: 支援最新 Armbian 發行版
- **系統監控**: CPU、記憶體、存儲、網路、溫度監控
- **靈活配置**: 基於 JSON 的配置系統，多種範本可選
- **一鍵安裝**: 自動化部署腳本
- **硬體支援**: I2C SSD1306 OLED 顯示器 (128x64, 128x32)
- **網路無關**: 支援有線和無線網路介面

## 🚀 快速開始

### 一鍵部署
```bash
# 1. 給腳本執行權限
chmod +x *.sh

# 2. 測試系統指令
./test_commands.sh

# 3. 自動部署 (需要 root 權限)
sudo ./deploy.sh
```

### 手動編譯
```bash
# 編譯程式
./build.sh

# 或者手動編譯
make clean
make
```

### 系統需求
```bash
# 安裝必要套件
sudo apt update
sudo apt install i2c-tools build-essential

# 啟用 I2C
sudo armbian-config  # 選擇 "System" -> "Hardware" -> 啟用 I2C
```

## 🔧 修復的問題

本專案解決了原版本在現代 Armbian 系統上的關鍵兼容性問題：

### 1. 網路指令現代化
**問題**: 原程式使用 `ifconfig` 指令，現代 Armbian 系統預設不包含此指令  
**修復**: 
- IP 地址獲取: 改用 `ip addr show` 指令
- 網路流量統計: 改用 `/sys/class/net/*/statistics/*` 檔案

```c
// 舊版 (使用 ifconfig)
"ifconfig eth0 | awk '/RX p/{printf ($5)/1000000000}'"

// 新版 (使用 /sys/class/net)
"cat /sys/class/net/eth0/statistics/rx_bytes 2>/dev/null | awk '{printf ($1)/1000000000}'"
```

### 2. EMMC 容量檢測修復
**問題**: 原程式使用 `df | awk '/mmcblk/'` 無法正確檢測到 mmcblk2 設備  
**修復**: 改用 `df / | tail -1` 直接檢測根分區

### 3. CPU 功能優化
**問題**: 
- CPU 頻率路徑錯誤 (`cpu[04]` 應為 `cpu0`)
- top 指令輸出格式變更
- 頻率單位轉換錯誤

**修復**:
- CPU 頻率: 使用正確路徑 `/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq`
- CPU 使用率: 更新 awk 語法適配新的 top 輸出格式
- 頻率轉換: 修正 kHz → GHz 轉換

## 📋 功能對應表

| 功能編號 | 功能描述 | 修復狀態 | 說明 |
|---------|---------|---------|------|
| 0 | 獲取日期 | ✅ 正常 | |
| 1 | 獲取時間 | ✅ 正常 | |
| 2 | CPU溫度 | ✅ 正常 | |
| 3 | CPU使用率 | ✅ 已修復 | 更新 top 指令格式 |
| 4 | CPU頻率 | ✅ 已修復 | 修復路徑和單位轉換 |
| 5 | 獲取IP | ✅ 已修復 | 改用 ip 指令 |
| 6-8 | 記憶體資訊 | ✅ 正常 | 總記憶體、使用記憶體、使用率 |
| 9-11 | EMMC資訊 | ✅ 已修復 | 總容量、使用容量、使用率 |
| 20-23 | 網路流量 | ✅ 已修復 | RX/TX eth0/wlan0 |

## 🔌 硬體連接

| OLED 針腳 | 開發板針腳 | 說明 |
|----------|-----------|------|
| VCC | 3.3V | 電源供應 |
| GND | GND | 接地 |
| SDA | GPIO2 (SDA) | I2C 資料線 |
| SCL | GPIO3 (SCL) | I2C 時鐘線 |

### 驗證硬體連接
```bash
# 檢查 I2C 連接
i2cdetect -y 0

# 應該在地址 0x3C (60) 顯示設備
```

## 📊 配置說明

### 快速配置
使用 `config_updated.json` 作為參考，包含：
- 系統資訊顯示頁面
- 網路資訊顯示頁面  
- 內存和存儲資訊頁面
- 正確的參數配置

### 基本配置結構
```json
{
    "seting": {
        "pixel": 12864,        // OLED分辨率 (128x64 或 128x32)
        "dev": "/dev/i2c-0",   // I2C設備路徑
        "addr": 60             // OLED I2C地址 (0x3C)
    },
    "page1": {
        "seting": {
            "cycle": 5,        // 刷新周期 (5 * 100ms = 500ms)
            "time": 50,        // 顯示時長 (50 * 100ms = 5秒)
            "page": 1          // 頁面順序
        },
        "display": [
            // 顯示元素配置
        ]
    }
}
```

### 📖 詳細配置文檔

如需完整的JSON配置語法說明、所有顯示元素類型和參數詳解，請參考：

**[📋 原作者詳細配置文檔 (README_yishunzhikong.md)](README_yishunzhikong.md)**

該文檔包含：
- 完整的JSON語法說明
- 所有顯示元素類型詳解（點、線、圓、矩形、三角形、字符串、數字等）
- 內置基礎元素的詳細配置
- Shell命令返回值的使用方法
- 各種屬性參數的取值範圍和說明

### 常用配置範例

#### 顯示系統時間
```json
{"type": "base", "func": 0, "class": "%H:%M:%S", "x0": 0, "y0": 0, "size": 1, "color": 1, "en": 1}
```

#### 顯示CPU溫度
```json
{"type": "base", "func": 1, "x0": 0, "y0": 16, "size": 1, "color": 1, "en": 1}
```

#### 顯示自定義文字
```json
{"type": "str", "data": "System Info", "x0": 0, "y0": 0, "size": 1, "color": 1, "en": 1}
```

#### 執行系統指令並顯示結果
```json
{"type": "cmd", "data": "hostname", "x0": 0, "y0": 16, "base": 12, "size": 1, "color": 1, "en": 1}
```

## 🛠️ 使用方法

### 基本指令
```bash
# 啟動顯示
ssd_oled &

# 使用指定配置
ssd_oled -c /etc/oled/config.json

# 清除螢幕
ssd_oled -clean

# 停止程式
killall ssd_oled
```

### 程式控制
```bash
# 檢查運行狀態
ps aux | grep ssd_oled

# 檢查 I2C 連接
i2cdetect -y 0
```

## 🧪 測試與部署

### 測試系統指令
```bash
./test_commands.sh
```

### 測試程式
```bash
# 測試配置
./ssd_oled -c config_updated.json

# 清除螢幕
./ssd_oled -clean
```

### 自動安裝
```bash
sudo ./deploy.sh
```

手動安裝步驟：
1. 編譯程式：`make clean && make`
2. 複製程式：`cp ssd_oled /bin/`
3. 設定權限：`chmod +x /bin/ssd_oled`
4. 創建目錄：`mkdir -p /etc/oled`
5. 複製配置：`cp config_updated.json /etc/oled/config.json`
6. 設定自啟動：編輯 `/etc/rc.local`，添加 `ssd_oled >/dev/null 1>&2 &`

## 🐛 故障排除

### 1. 程式無法啟動
```bash
# 檢查 I2C 設備
i2cdetect -y 0

# 檢查權限
ls -l /bin/ssd_oled

# 確保 i2c-tools 已安裝
apt install i2c-tools
```

### 2. 顯示內容錯誤
```bash
# 測試系統指令
./test_commands.sh

# 查看錯誤訊息 (移除重定向)
ssd_oled -c /etc/oled/config.json
```

### 3. EMMC 顯示 0%
```bash
# 檢查根分區
df /

# 測試指令
df / | tail -1 | awk '{printf ($3)/$2*100}'
```

### 4. 網路資訊無法顯示
```bash
# 檢查網路介面
ls /sys/class/net/

# 測試 IP 獲取
ip addr show eth0 | grep 'inet '
```

## 📁 重要檔案

| 檔案 | 說明 |
|------|------|
| `ssd_oled` | 編譯後的執行檔 |
| `config_updated.json` | 現代化配置範例 |
| `test_commands.sh` | 系統指令測試腳本 |
| `deploy.sh` | 自動部署腳本 |
| `build.sh` | 編譯腳本 |
| `/etc/oled/config.json` | 系統配置檔案 |
| `/bin/ssd_oled` | 系統程式位置 |

## 🆚 與原專案的差異

### 目標平台
- **原專案**: 主要針對 OpenWrt 路由器系統
- **本專案**: 專門針對 Armbian 單板電腦系統

### 系統兼容性
- **原專案**: 使用較舊的系統指令，在現代 Linux 上可能失效
- **本專案**: 完全現代化，支援最新 Armbian 發行版

### 功能增強
- **原專案**: 基礎顯示功能
- **本專案**: 增加配置工具、驗證器、自動安裝等

## 🆕 更新內容

✅ 修復 ifconfig 相容性問題  
✅ 修復 EMMC 容量檢測 (0% 問題)  
✅ 修復 CPU 頻率顯示  
✅ 更新網路流量統計  
✅ 程式重命名為 ssd_oled  
✅ 提供完整的測試和部署腳本  
✅ 現代化所有系統指令

## 🤝 貢獻

歡迎貢獻！請：

1. Fork 本專案
2. 創建功能分支
3. 進行更改
4. 如適用，添加測試
5. 提交 Pull Request

## 📜 授權

本專案採用 MIT 授權條款 - 詳見 [LICENSE](LICENSE) 檔案。

## 🔗 相關專案

- [Armbian](https://www.armbian.com/) - ARM 開發板的 Linux 系統
- [SSD1306 Library](https://github.com/adafruit/Adafruit_SSD1306) - Arduino SSD1306 顯示器庫
- [cJSON](https://github.com/DaveGamble/cJSON) - JSON 解析庫
- [SSD1306 驅動庫](https://github.com/deeplyembeddedWP/SSD1306-OLED-display-driver-for-BeagleBone) - BeagleBone SSD1306 驅動

## 📞 支援

如果遇到問題：
1. 先執行 `./test_commands.sh` 檢查系統指令
2. 檢查 I2C 連接：`i2cdetect -y 0`
3. 查看程式運行狀態：`ps aux | grep ssd_oled`
4. 移除 `>/dev/null` 重定向查看詳細錯誤訊息

---

**原始專案鏈接**: 
- https://github.com/yishunzhikong/SSD1306_OLED_json
- https://github.com/bearcatl/SSD1306_OLED_json