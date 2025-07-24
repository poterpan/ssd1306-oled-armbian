#!/bin/bash

echo "=== Building SSD1306 OLED Display Program (Modern Version) ==="
echo

echo "1. Cleaning previous build..."
make clean

echo "2. Building program..."
make

if [ -f "ssd_oled" ]; then
    echo "Build successful! Executable: ssd_oled"
    echo ""
    echo "Usage: ./ssd_oled [options]"
    echo "  -c [config_file]  Load configuration file"
    echo "  -h                Show help"
    echo ""
    echo "Next steps:"
    echo "  Test commands: ./test_commands.sh"
    echo "  Test program: ./ssd_oled -c config_updated.json"
    echo "  Auto deploy: sudo ./deploy.sh"
else
    echo "Build failed!"
    exit 1
fi