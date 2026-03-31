SWIFT_FILES = Sources/FractalClockView.swift
SDK_PATH = $(shell xcrun --show-sdk-path --sdk macosx)
OUTPUT_BUNDLE = FractalClockAbsolute.saver
OUTPUT_MACOS = $(OUTPUT_BUNDLE)/Contents/MacOS
TARGET_NAME = FractalClockAbsolute

all: $(OUTPUT_BUNDLE)

$(OUTPUT_BUNDLE): $(SWIFT_FILES) Info.plist
	@mkdir -p $(OUTPUT_MACOS)
	swiftc $(SWIFT_FILES) \
		-sdk $(SDK_PATH) \
		-target arm64-apple-macos12.0 \
		-emit-library -Xlinker -bundle \
		-o $(TARGET_NAME)_arm64
	swiftc $(SWIFT_FILES) \
		-sdk $(SDK_PATH) \
		-target x86_64-apple-macos12.0 \
		-emit-library -Xlinker -bundle \
		-o $(TARGET_NAME)_x86_64
	lipo -create -output $(OUTPUT_MACOS)/$(TARGET_NAME) $(TARGET_NAME)_arm64 $(TARGET_NAME)_x86_64
	@cp Info.plist $(OUTPUT_BUNDLE)/Contents/Info.plist
	@rm $(TARGET_NAME)_arm64 $(TARGET_NAME)_x86_64
	@xattr -rc $(OUTPUT_BUNDLE) || true
	@codesign --force --deep --sign - $(OUTPUT_BUNDLE)
	@echo "Build successful! Created $(OUTPUT_BUNDLE)"

clean:
	rm -rf $(OUTPUT_BUNDLE) $(TARGET_NAME)_arm64 $(TARGET_NAME)_x86_64
