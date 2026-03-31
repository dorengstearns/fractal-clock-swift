# Fractal Clock

A modernized recreation of the 2007 classic Mac Screensaver, brought up to speed for Apple Silicon.

## Overview
This project completely rewrites the legacy immediate-mode OpenGL mathematical renderer (`glBegin`, `glEnd`) from its roots in a 2007 Objective-C screensaver package. The completely modernized codebase translates the fractal architecture to Swift utilizing the CPU-optimized vector curves of Apple's `CoreGraphics` library (`CGContext`), effectively securing the beautiful fractal animation to run effortlessly on the newest generations of macOS and Apple Silicon Processors. 

## Features
- **Fractal Generation:** Deep vector geometry and recursive branch mathematics that scale in size seamlessly across 11 synchronized dimension layers based on real-world UNIX epoch time data. 
- **Modern Screensaver Core:** Constructed into a modern `.saver` plugin wrapper utilizing `@objc` bindings and Swift `ScreenSaverView` endpoints, fully respecting modern macOS Legacy Sandboxing parameters and system settings displays.
- **Dependency Free:** Fully decoupled from messy intermediate Xcode project configurations. Recompiled and code-signed perfectly via our lightweight standalone Command Line `Makefile` and standard Terminal `swiftc`. 

## Installation

Run the build configuration in your terminal via:
```bash
make
```

Double click the generated `FractalClockAbsolute.saver` output bundle from your file browser. `macOS System Settings` will automatically mount the plugin. 

## Special Notes
Older implementations attempted to dynamically benchmark System FPS processing speeds per-frame to dynamically truncate fractal lengths for weaker 16-bit processing architectures. We have completely deleted these legacy bottlenecks as the IPC wrapper latency found via System Settings sandboxing artificially depressed the theoretical load score. Our solution trusts modern CoreGraphics drawing and hardcodes a beautiful 11-layered geometric progression matrix.
