#!/bin/bash

# Manual screenshot extraction script
# Extracts screenshots from the most recent test results and renames them properly

set -e

OUTPUT_DIR="./Screenshots"

echo "📱 Manual Screenshot Extraction Tool"
echo "======================================="

# Find the most recent test results
LATEST_RESULTS=$(find ~/Library/Developer/Xcode/DerivedData -name "*.xcresult" -type d | grep -i simple | head -1)

if [ -z "$LATEST_RESULTS" ]; then
    echo "❌ No test results found. Please run UI tests first."
    exit 1
fi

echo "Found test results: $LATEST_RESULTS"

# Create output directory
mkdir -p "$OUTPUT_DIR/Manual"

# Extract screenshots
echo "Extracting screenshots..."
xcrun xcresulttool export attachments --path "$LATEST_RESULTS" --output-path "$OUTPUT_DIR/Manual"

# Read manifest and rename files based on suggested names
if [ -f "$OUTPUT_DIR/Manual/manifest.json" ]; then
    echo "Renaming screenshots based on manifest..."
    
    # Use Python to parse JSON and rename files
    python3 << 'EOF'
import json
import os
import shutil

manifest_path = "./Screenshots/Manual/manifest.json"
if os.path.exists(manifest_path):
    with open(manifest_path, 'r') as f:
        data = json.load(f)
    
    for test_data in data:
        for attachment in test_data.get('attachments', []):
            exported_name = attachment.get('exportedFileName')
            suggested_name = attachment.get('suggestedHumanReadableName')
            device_name = attachment.get('deviceName', 'Unknown')
            
            if exported_name and suggested_name:
                old_path = f"./Screenshots/Manual/{exported_name}"
                new_path = f"./Screenshots/Manual/{suggested_name}"
                
                if os.path.exists(old_path):
                    shutil.move(old_path, new_path)
                    print(f"Renamed: {exported_name} -> {suggested_name}")
EOF
    
    echo "✅ Screenshots extracted and renamed!"
    echo "📁 Location: $OUTPUT_DIR/Manual/"
    echo ""
    echo "📱 Generated screenshots:"
    find "$OUTPUT_DIR/Manual" -name "*.png" -type f | sort | while read -r screenshot; do
        echo "  - $(basename "$screenshot")"
    done
else
    echo "⚠️  No manifest found, screenshots extracted with original names"
    find "$OUTPUT_DIR/Manual" -name "*.png" -type f | while read -r screenshot; do
        echo "  - $(basename "$screenshot")"
    done
fi

echo ""
echo "🎉 Screenshot extraction complete!"
echo "Upload these files to App Store Connect for your app submission."