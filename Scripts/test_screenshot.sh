#!/bin/bash

# Simple screenshot test script for verification
set -e

PROJECT_NAME="CrossSumsSimple"
SCHEME_NAME="Simple Cross Sums"
OUTPUT_DIR="./Screenshots"
DERIVED_DATA_PATH="./TestDerivedData"

echo "🧪 Testing screenshot generation for iPhone 16 Pro"

# Create output directories
mkdir -p "$OUTPUT_DIR/iPhone"
mkdir -p "$DERIVED_DATA_PATH"

echo "📱 Building and testing..."

# Run screenshot test for iPhone 16 Pro
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -only-testing "Simple Cross Sums UI Tests/AppStoreScreenshotTests/testIPhoneScreenshots" \
    test

echo "✅ Screenshot test completed!"

# Extract screenshots from test results
echo "📊 Extracting screenshots..."
RESULTS_PATH=$(find "$DERIVED_DATA_PATH" -name "*.xcresult" -type d | head -1)

if [ -n "$RESULTS_PATH" ]; then
    echo "Found test results: $RESULTS_PATH"
    
    # Create device-specific directory
    DEVICE_DIR="$OUTPUT_DIR/iPhone/iPhone_16_Pro_Test"
    mkdir -p "$DEVICE_DIR"
    
    # Extract screenshots using modern xcresulttool
    echo "Extracting attachments..."
    xcrun xcresulttool export attachments --path "$RESULTS_PATH" --output-path "$DEVICE_DIR"
    
    # List what we extracted
    echo "📱 Screenshots extracted:"
    find "$DEVICE_DIR" -name "*.png" -type f | while read -r screenshot; do
        echo "  - $(basename "$screenshot")"
    done
    
    echo "✅ Screenshots saved to: $DEVICE_DIR"
else
    echo "❌ No test results found"
fi

echo "🎉 Test complete!"