# SPDX-FileCopyrightText: 2024 Collabora, Ltd.
# SPDX-License-Identifier: BSL-1.0

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
- **Monado Integration**: Meant at leveraging [Monado](https://gitlab.freedesktop.org/monado/monado) for AR support on phone-based platforms.

## Supported Platforms
1. **XR Headsets**:
   - Meta Quest 2/3
   - Other OpenXR-compatible devices
2. **Phone AR**:
   - Pixel phones with Monado-powered Google Cardboard driver
   - Other android phones

## Getting Started
To explore the SOMAR experience, follow the steps below to set up the application on your device.

### Install and run application on your device
If you just want to install and run the application on your XR device or Android Phone AR, this section is for you.

#### Install Prerequisites
 - OpenXR-compatible XR Headset
   1. Make sure your XR headset is in Developer Mode and can install APKs from unknown sources
   1. Download the right SOMAR-application-XYZ APK for your device from the [prebuilts](https://gitlab.collabora.com/somar-project/somar/-/tree/main/prebuilts) folder.
   1. Sideload the APK onto your device (depending on your device, sideloading method will change) :
     - [Quest devices](https://arborxr.com/blog/sideload-apps-on-meta-quest-3/)
     - [Pico devices](https://knowledge.vr-expert.com/kb/how-to-sideload-and-install-an-apk-file-on-the-pico-neo-3-pro/)
   1. Run the newly application from your XR device's UI and enjoy !
 - Recent Android phone
   1. Make sure you own a physical [Google Cardboard](https://arvr.google.com/cardboard/)-Compatible Phone holder with a QR code on the side.
   1. Make sure your Android phone is in Developer Mode and can install APKs from [unknown sources](https://www.applivery.com/docs/mobile-app-distribution/troubleshooting/mobile-app-distribution-all/android-unknown-sources/)
   1. Install the MONADO APK with cardboard support from the [prebuilts folder](https://gitlab.collabora.com/somar-project/somar/-/blob/main/prebuilts) on your phone.
   1. Install the "OpenXR Runtime Broker" from the Google Play Store on your phone.
   1. Run the OpenXR Runtime Broker and check the "Monado" box.
   1. Run the Monado android application on your phone and click the "QR code" logo in top-right corner.
   1. Point your phone camaera on the Cardboard QR code and wait until Monado has scanned the code.
   1. Install the SOMAR-application-XYZ APK from the [prebuilts folder](https://gitlab.collabora.com/somar-project/somar/-/blob/main/prebuilts) from your phone.
   1. Insert your phone into the Cardboard phone holder, plug-in your favorite earphones, launch the Somar application and enjoy !

### Edit and build the application in the Godot engine
If you are a developer and want to edit the godot project and rebuild, follow the below steps.


### Install Prerequisites
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
