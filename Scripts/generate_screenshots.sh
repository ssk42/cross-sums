#!/bin/bash

# App Store Screenshot Generation Script
# This script automates the generation of screenshots for App Store submission

set -e

# Configuration
PROJECT_NAME="CrossSumsSimple"
SCHEME_NAME="Simple Cross Sums"
OUTPUT_DIR="./Screenshots"
DERIVED_DATA_PATH="./DerivedData"

# Device configurations for App Store
declare -a IPHONE_DEVICES=(
    # "iPhone 16 Pro Max"
    # "iPhone 16 Pro" 
    # "iPhone 16 Plus"
    # "iPhone 16"
    # "iPhone 15 Pro"
)

declare -a IPAD_DEVICES=(
    "iPad Pro 13-inch (M4)"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting App Store Screenshot Generation${NC}"
echo "Project: $PROJECT_NAME"
echo "Scheme: $SCHEME_NAME"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/iPhone"
mkdir -p "$OUTPUT_DIR/iPad"

# Clear previous screenshots
rm -rf "$OUTPUT_DIR/iPhone"/*
rm -rf "$OUTPUT_DIR/iPad"/*

# Function to generate screenshots for a device
generate_screenshots_for_device() {
    local device="$1"
    local device_type="$2"
    
    echo -e "${YELLOW}📱 Generating screenshots for: $device${NC}"
    
    # Build and test with screenshots
    xcodebuild \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=$device" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -only-testing "Simple Cross Sums UI Tests/AppStoreScreenshotTests/test${device_type}Screenshots" \
        test
    
    # Extract screenshots from test results
    extract_screenshots_from_results "$device" "$device_type"
}

# Function to extract screenshots from test results
extract_screenshots_from_results() {
    local device="$1"
    local device_type="$2"
    
    # Find the latest test results
    RESULTS_PATH=$(find "$DERIVED_DATA_PATH" -name "*.xcresult" -type d | head -1)
    
    if [ -n "$RESULTS_PATH" ]; then
        echo "  Extracting screenshots from: $RESULTS_PATH"
        
        # Create device-specific directory
        DEVICE_DIR="$OUTPUT_DIR/$device_type/$(echo "$device" | sed 's/ /_/g')"
        mkdir -p "$DEVICE_DIR"
        export DEVICE_DIR # Export DEVICE_DIR for the Python script
        
        # Remove existing manifest.json if it exists
        rm -f "$DEVICE_DIR/manifest.json"
        # Extract screenshots using modern xcresulttool
        xcrun xcresulttool export attachments --path "$RESULTS_PATH" --output-path "$DEVICE_DIR"

        # Read manifest and rename files based on suggested names
        if [ -f "$DEVICE_DIR/manifest.json" ]; then
            echo "  Renaming screenshots based on manifest..."
            
            # Use Python to parse JSON and rename files
            python3 -c "
import json
import os
import shutil
import sys

DEVICE_DIR = sys.argv[1]
manifest_path = os.path.join(DEVICE_DIR, "manifest.json")
if os.path.exists(manifest_path):
    with open(manifest_path, 'r') as f:
        data = json.load(f)
    
    for test_data in data:
        for attachment in test_data.get('attachments', []):
            exported_name = attachment.get('exportedFileName')
            suggested_name = attachment.get('suggestedHumanReadableName')
            
            if exported_name and suggested_name:
                old_path = os.path.join(DEVICE_DIR, exported_name)
                new_path = os.path.join(DEVICE_DIR, suggested_name)
                
                if os.path.exists(old_path):
                    shutil.move(old_path, new_path)
                    print(f"    Renamed: {exported_name} -> {suggested_name}")
" "$DEVICE_DIR"
            echo "  ✅ Screenshots renamed!"
        else
            echo "  ⚠️  No manifest found, screenshots extracted with original names"
        fi
        
        echo -e "  ${GREEN}✅ Screenshots extracted to: $DEVICE_DIR${NC}"
    else
        echo -e "  ${RED}❌ No test results found in: $DERIVED_DATA_PATH${NC}"
    fi
}

# Main execution
echo -e "${BLUE}Building project first...${NC}"
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build-for-testing

echo ""
echo -e "${BLUE}📱 Generating iPhone Screenshots${NC}"
for device in "${IPHONE_DEVICES[@]}"; do
    if xcrun simctl list devices | grep -q "$device"; then
        generate_screenshots_for_device "$device" "iPhone"
    else
        echo -e "${YELLOW}⚠️  Device not available: $device${NC}"
    fi
done

echo ""
echo -e "${BLUE}📱 Generating iPad Screenshots${NC}"
for device in "${IPAD_DEVICES[@]}"; do
    if xcrun simctl list devices | grep -q "$device"; then
        generate_screenshots_for_device "$device" "iPad"
    else
        echo -e "${YELLOW}⚠️  Device not available: $device${NC}"
    fi
done

# Generate summary
echo ""
echo -e "${GREEN}🎉 Screenshot generation complete!${NC}"
echo -e "${BLUE}📊 Summary:${NC}"
echo "Output directory: $OUTPUT_DIR"

# Count generated screenshots
IPHONE_COUNT=$(find "$OUTPUT_DIR/iPhone" -type f -name "*.png" 2>/dev/null | wc -l)
IPAD_COUNT=$(find "$OUTPUT_DIR/iPad" -type f -name "*.png" 2>/dev/null | wc -l)

echo "iPhone screenshots: $IPHONE_COUNT"
echo "iPad screenshots: $IPAD_COUNT"
echo "Total screenshots: $((IPHONE_COUNT + IPAD_COUNT))"

ls -R "$OUTPUT_DIR/iPad"

echo ""
echo -e "${BLUE}📱 Next steps:${NC}"
echo "1. Review screenshots in: $OUTPUT_DIR"
echo "2. Select the best ones for App Store submission"
echo "3. Upload to App Store Connect"

echo ""
echo -e "${GREEN}✨ Screenshots ready for App Store submission!${NC}"