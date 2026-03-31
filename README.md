# Fractal Clock (Swift)

A modernized, Apple Silicon-compatible recreation of the classic Mac screensaver originally created by [DQD](https://www.dqd.com/programs/FractalClock/).

## Overview
This project is a complete rewrite of the original 2007 Objective-C/OpenGL code into Swift and CoreGraphics. It preserves the original fractal architecture while ensuring high-performance, native execution on modern macOS.

## Features
- **Modern Swift:** Rebuilt from the ground up using Swift and `ScreenSaverView`.
- **CoreGraphics Rendering:** Replaces legacy OpenGL with CPU-optimized vector geometry.
- **Apple Silicon Native:** Fully compatible with ARM64 and Intel architectures.
- **Dependency Free:** Built using a simple `Makefile` and standard system tools.

## Installation
Build the screensaver via:
```bash
make
```
Double-click `FractalClockAbsolute.saver` to install it into macOS System Settings.

## Credits
Original implementation and concept by [DQD - Fractal Clock](https://www.dqd.com/programs/FractalClock/).
