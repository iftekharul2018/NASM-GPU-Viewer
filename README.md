<div align="center">

# 🖼️ Assembly GPU Image Viewer

*A lightning-fast, hardware-accelerated image viewer written entirely in 64-bit x86 Assembly.*

![Assembly](https://img.shields.io/badge/Language-x86__64_Assembly-blue)
![NASM](https://img.shields.io/badge/Assembler-NASM-orange)
![SDL2](https://img.shields.io/badge/Library-SDL2-2C2C30?logo=libsdl)
![Platforms](https://img.shields.io/badge/Platforms-Windows_%7C_Linux-lightgrey)

</div>

---

## 🚀 About The Project

This project proves that low-level Assembly can be used to build sleek, modern graphical applications. By leveraging **SDL2** and **SDL2_image**, this viewer bypasses standard OS window managers to create a custom borderless window rendered directly on the GPU.

It features a custom cross-platform calling convention macro system, allowing the exact same `MAIN.ASM` source code to compile and run natively on both **Windows (Win32)** and **Linux (System V AMD64 ABI)** without modifying a single line of code.

### ✨ Key Features
* **Hardware Accelerated:** Buttery smooth panning and zooming calculated directly for the GPU.
* **Modern Drag-and-Drop:** Drag any supported image from your desktop directly onto the app to load it instantly.
* **Broad Format Support:** Natively supports `.JPG`, `.PNG`, `.TIFF`, and `.WEBP`.
* **Borderless Custom UI:** Window controls (Move, Resize, Fullscreen, Close) are custom-drawn interactively over the frame buffer.
* **Write Once, Build Anywhere:** Universal Assembly codebase for Windows and Linux.

---

## 🛠️ Prerequisites

To compile and run this project, ensure you have the following installed and added to your system's PATH:

* **[NASM](https://www.nasm.us/)**: The Netwide Assembler (v2.15 or newer).
* **[GCC](https://gcc.gnu.org/)**: For linking object files (MinGW-w64 on Windows, standard GCC on Linux).
* **SDL2 & SDL2_image**: Core development libraries for windowing, rendering, and image decoding.

---

## 💻 Compilation and Execution

### 🪟 Windows
Open your terminal in the project directory and run:

```bash
# 1. Assemble for Windows 64-bit (triggers Windows calling conventions)
nasm -f win64 -D WINDOWS MAIN.ASM -o MAIN.obj

# 2. Link using MinGW and SDL2 libraries
gcc MAIN.obj -o MAIN.exe -lmingw32 -lSDL2main -lSDL2 -lSDL2_image

# 3. Run the application
.\MAIN.exe
```

### 🐧 Linux
Open your terminal in the project directory and run:

```bash
# 1. Assemble for Linux 64-bit (defaults to Linux calling conventions)
nasm -f elf64 MAIN.ASM -o MAIN.o

# 2. Link using GCC and SDL2 libraries
gcc MAIN.o -o main_viewer -lSDL2 -lSDL2_image

# 3. Run the application
./main_viewer
```

---

## 🎮 Interface & Controls

| Action | Control / UI Element |
| :--- | :--- |
| **Load Image** | Drag and drop an image file into the window |
| **Pan Image** | Click and drag anywhere on the image |
| **Zoom In / Out** | Mouse Scroll Wheel |
| **Move Window** | Click and drag the 🟩 **Green Square** (Top Left) |
| **Reset Camera** | Click the 🟨 **Yellow Square** (Bottom Left) |
| **Toggle Fullscreen**| Click the 🟦 **Blue Square** (Top Right) |
| **Close App** | Click the 🟥 **Red Square** (Top Right) or press `ESC` |
| **Resize Window** | Click and drag the ⬜ **Grey Square** (Bottom Right) |

---
*Created as an exploration of modern graphics programming in raw Assembly.*
