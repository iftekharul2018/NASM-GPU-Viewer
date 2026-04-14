\# Assembly GPU Image Viewer



A lightning-fast, highly optimized image viewer written entirely in 64-bit x86 Assembly (NASM). It leverages SDL2 for cross-platform window management and hardware-accelerated GPU rendering.



This project uses a custom calling convention macro system, allowing the exact same `MAIN.ASM` source file to compile and run natively on both Windows and Linux without any code modifications.



\## Features



\* \*\*Hardware Accelerated:\*\* Uses the GPU for buttery smooth panning and zooming.

\* \*\*Modern Drag-and-Drop:\*\* Drag any image from your OS directly onto the borderless window to load it instantly.

\* \*\*Broad Format Support:\*\* Natively supports JPG, PNG, TIFF, and WebP.

\* \*\*Borderless UI:\*\* Custom-built window controls (Move, Close, Resize, Fullscreen) drawn directly to the frame buffer.

\* \*\*Cross-Platform:\*\* Write once, build anywhere. Compatible with Windows (Win32 API calling convention) and Linux (System V AMD64 ABI).



\## Prerequisites



To compile and run this project, you will need the following installed and added to your system's PATH:



\* \*\*NASM:\*\* The Netwide Assembler (v2.15 or newer).

\* \*\*GCC:\*\* For linking the object files (MinGW-w64 on Windows, standard GCC on Linux).

\* \*\*SDL2 Development Libraries:\*\* Core windowing and rendering library.

\* \*\*SDL2\_image Development Libraries:\*\* For loading various image formats.



\## Compilation and Execution



###Windows

Open your terminal in the project directory and run:

```bash

nasm -f win64 -D WINDOWS MAIN.ASM -o MAIN.obj

gcc MAIN.obj -o MAIN.exe -lmingw32 -lSDL2main -lSDL2 -lSDL2\_image

.\\MAIN.exe



Linux

Open your terminal in the project directory and run:





Action	Control / UI Element		

Pan Image	Click and drag anywhere on the image		

Zoom In / Out	Mouse Scroll Wheel		

Move Window	Click and drag the Green Square (Top Left)		

Reset Camera	Click the Yellow Square (Bottom Left)		

Toggle Fullscreen	Click the Blue Square (Top Right)		

Close App	Click the Red Square (Top Right) or press ESC		

Resize Window	Click and drag the Grey Square (Bottom Right)		

Load Image	Drag and drop an image file into the window		



