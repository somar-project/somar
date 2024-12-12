# SOMAR

SOMAR is an open-source XR application developed in collaboration with Portugal Marine Researchers SOMAR (https://somarbio.pt/somar/). The project aims to raise awareness about the negative impacts of underwater noise pollution, particularly on dolphins and whales. By leveraging immersive technology, SOMAR educates users on the detrimental effects of noise pollution caused by recreational boats and whale-watching activities.

## Table of Contents
- [Introduction](#introduction)
- [Technical Details](#technical-details)
- [Supported Platforms](#supported-platforms)
- [Getting Started](#getting-started)
- [Prerequisites](#prerequisites)
- [Installation](#running-and-installation)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Introduction
Underwater noise pollution is a growing concern that disrupts marine ecosystems and threatens the well-being of marine life, particularly cetaceans like dolphins and whales. SOMAR aims to educate users about this issue through an engaging, interactive experience in virtual and augmented reality.

The application immerses users in marine environments, demonstrating the impacts of noise pollution on marine animals and encouraging sustainable practices in marine tourism.

## Technical Details
- **Engine**: Developed using the [Godot Engine](https://godotengine.org/).
- **XR Compatibility**: Built with [OpenXR](https://www.khronos.org/openxr/) for maximum compatibility.
- **Monado Integration**: Meant at leveraging Monado for AR support on phone-based platforms.

## Supported Platforms
1. **XR Headsets**:
   - Meta Quest 2/3
   - Other OpenXR-compatible devices
2. **Phone AR**:
   - Pixel phones with Monado-powered Google Cardboard driver
   - Other android phones

## Getting Started
To explore the SOMAR experience, follow the steps below to set up the application on your device.

### Prerequisites
- Godot engine installation properly setup for [XR development](https://www.youtube.com/watch?v=shbHGhkh4NM)
- XR Headset or AR-compatible phone
- Installed runtime for OpenXR

### Build and Run/debug on device
- Launch Godot 4.X and open the project
- Connect your device via USB (or wireless via the right Godot menu)
- Click the "Remote Debug" button in the top menu bar to build and run your app on the connected device.
- Click [Project]-[Export...] from the main menu to export the .apk for your desired platform.

## License
SOMAR is licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute this software under the terms of the license.

## Acknowledgments
This project is a collaboration between Collabora and SOMAR. Special thanks to the teams involved in developing this application and raising awareness about marine conservation issues.
