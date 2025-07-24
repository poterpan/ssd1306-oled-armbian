#!/bin/bash

echo "=== OLED 配置文件生成器 ==="
echo

# 配置選項
echo "請選擇配置模式:"
echo "1) 混合模式 - 緊湊佈局，3頁顯示"
echo "2) 大字模式 - 大字體，14頁顯示"  
echo "3) 簡化模式 - 極簡設計，2頁顯示"
echo "4) 自定義模式 - 手動配置"
echo

read -p "請輸入選項 (1-4): " mode

case $mode in
    1)
        echo "選擇: 混合模式"
        template="config_mix_modern.json"
        ;;
    2)
        echo "選擇: 大字模式"
        template="config_big_modern.json"
        ;;
    3)
        echo "選擇: 簡化模式"
        template="config_simple_modern.json"
        ;;
    4)
        echo "選擇: 自定義模式"
        template=""
        ;;
    *)
        echo "無效選項，使用混合模式"
        template="config_mix_modern.json"
        ;;
esac

# 基本設定
echo
echo "=== 基本設定 ==="
read -p "I2C 設備路徑 [/dev/i2c-0]: " i2c_dev
i2c_dev=${i2c_dev:-/dev/i2c-0}

read -p "OLED I2C 地址 [60]: " i2c_addr
i2c_addr=${i2c_addr:-60}

read -p "系統名稱 [CumeBox]: " system_name
system_name=${system_name:-CumeBox}

read -p "輸出文件名 [my_config.json]: " output_file
output_file=${output_file:-my_config.json}

# 網路設定
echo
echo "=== 網路設定 ==="
echo "可用網路介面:"
ls /sys/class/net/ | grep -v lo

read -p "主要網路介面 [eth0]: " primary_interface
primary_interface=${primary_interface:-eth0}

read -p "次要網路介面 [wlan0]: " secondary_interface  
secondary_interface=${secondary_interface:-wlan0}

# 生成配置
echo
echo "=== 生成配置文件 ==="

if [ -n "$template" ] && [ -f "$template" ]; then
    # 使用範本
    cp "$template" "$output_file"
    
    # 替換設定值
    sed -i "s|/dev/i2c-0|$i2c_dev|g" "$output_file"
    sed -i "s|\"addr\":60|\"addr\":$i2c_addr|g" "$output_file"
    sed -i "s|CumeBox|$system_name|g" "$output_file"
    sed -i "s|\"port\":\"eth0\"|\"port\":\"$primary_interface\"|g" "$output_file"
    sed -i "s|\"port\":\"wlan0\"|\"port\":\"$secondary_interface\"|g" "$output_file"
    
    echo "✓ 配置文件已生成: $output_file"
    echo "✓ 基於範本: $template"
    
else
    # 自定義模式
    echo "生成自定義配置..."
    
    cat > "$output_file" << EOF
{
    "seting":{
        "pixel":12864,
        "dev":"$i2c_dev",
        "addr":$i2c_addr
    },
    "welcome":{
        "seting":{
            "cycle":5,"time":40,"page":1
        },
        "display":[
            {"type":"r_rect","x0":2,"y0":2,"w":124,"h":60,"r":25,"fill":0,"color":1,"en":1},
            {"type":"str","data":"$system_name","x0":25,"y0":20,"size":2,"color":1,"en":1},
            {"type":"str","data":"System","x0":25,"y0":40,"size":2,"color":1,"en":1}
        ]
    },
    "status":{
        "seting":{
            "cycle":10,"time":60,"page":2
        },
        "display":[
            {"type":"str","data":"Status","x0":35,"y0":2,"size":2,"color":1,"en":1},
            {"type":"line","x0":0,"y0":20,"x1":127,"y1":20,"color":1,"en":1},
            {"type":"str","data":"CPU:","x0":5,"y0":25,"size":1,"color":2,"en":1},
            {"type":"base","func":3,"x0":35,"y0":25,"base":4,"class":1,"size":1,"color":1,"en":1},
            {"type":"str","data":"%","x0":60,"y0":25,"size":1,"color":1,"en":1},
            {"type":"str","data":"Temp:","x0":70,"y0":25,"size":1,"color":2,"en":1},
            {"type":"base","func":2,"x0":100,"y0":25,"base":4,"class":0,"size":1,"color":1,"en":1},
            {"type":"str","data":"MEM:","x0":5,"y0":35,"size":1,"color":2,"en":1},
            {"type":"base","func":8,"x0":35,"y0":35,"base":4,"class":1,"size":1,"color":1,"en":1},
            {"type":"str","data":"%","x0":60,"y0":35,"size":1,"color":1,"en":1},
            {"type":"str","data":"DISK:","x0":70,"y0":35,"size":1,"color":2,"en":1},
            {"type":"base","func":11,"x0":100,"y0":35,"base":4,"class":1,"size":1,"color":1,"en":1},
            {"type":"str","data":"%","x0":120,"y0":35,"size":1,"color":1,"en":1},
            {"type":"str","data":"NET:","x0":5,"y0":45,"size":1,"color":2,"en":1},
            {"type":"base","func":5,"x0":30,"y0":45,"port":"$primary_interface","base":15,"size":1,"color":1,"en":1},
            {"type":"str","data":"Time:","x0":5,"y0":55,"size":1,"color":2,"en":1},
            {"type":"base","func":1,"x0":35,"y0":55,"base":8,"class":"%H:%M","size":1,"color":1,"en":1}
        ]
    },
    "blank":{
        "seting":{
            "cycle":5,"time":1,"page":14
        }
    }
}
EOF
    
    echo "✓ 自定義配置文件已生成: $output_file"
fi

echo
echo "=== 配置摘要 ==="
echo "文件: $output_file"
echo "I2C設備: $i2c_dev"
echo "I2C地址: $i2c_addr"
echo "系統名稱: $system_name"
echo "主要網路: $primary_interface"
echo "次要網路: $secondary_interface"

echo
echo "=== 使用方法 ==="
echo "1. 測試配置: ./ssd_oled -c $output_file"
echo "2. 部署配置: cp $output_file /etc/oled/config.json"
echo "3. 重啟程式: killall ssd_oled && ssd_oled &"
echo
echo "配置說明請參考: README.md"