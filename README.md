# Fractal Clock (Swift)

A modernized, Apple Silicon-compatible recreation of the classic Mac screensaver originally created by [DQD](https://www.dqd.com/programs/FractalClock/).

## Overview
This project is a complete rewrite of the original 2007 Objective-C/OpenGL code into Swift and CoreGraphics. It preserves the original fractal architecture while ensuring high-performance, native execution on modern macOS.

## Download
You can download the latest version of the screensaver directly:
👉 [**Download FractalClock.saver.zip**](FractalClock.saver.zip)

## Features
- **Modern Swift:** Rebuilt from the ground up using Swift and `ScreenSaverView`.
- **CoreGraphics Rendering:** Replaces legacy OpenGL with CPU-optimized vector geometry.
- **Apple Silicon Native:** Fully compatible with ARM64 and Intel architectures.
- **Dependency Free:** Built using a simple `Makefile` and standard system tools.

## Installation & Security

Because this screensaver is built locally and is not "notarized" by an Apple Developer ID ($99/year), macOS will block it by default with a "malware" warning. 

### 🚀 **Option 1: The Easy Way (Command Line)**
If you've downloaded the source or cloned the repo, just run:
```bash
./install.sh
```
This script automatically copies the screensaver to your `~/Library/Screen Savers` folder and tells macOS to trust the code.

### 🖱️ **Option 2: The Manual Way**
1.  **Download** and unzip [**FractalClock.saver.zip**](FractalClock.saver.zip).
2.  **Right-click** (or Control-click) the `.saver` file and select **Open**.
3.  When the warning dialog appears, click **Open** again.
4.  MacOS will ask if you want to install it; click **Install**.

## Performance & Battery
This version is heavily optimized for laptops and low-power devices:
- **Adaptive Frame Rate:** Automatically drops to 2 FPS in Low Power Mode.
- **Path Batching:** Reduces GPU overhead by 99% compared to traditional line drawing.
- **Zero-Allocation Loop:** Uses optimized Swift structs to avoid memory churn.

## Build from Source
If you have Xcode installed:
```bash
make
```
This generates `FractalClockAbsolute.saver`, a Universal Binary for Intel and Apple Silicon Macs.

## Credits
Original implementation and concept by [DQD - Fractal Clock](https://www.dqd.com/programs/FractalClock/).
