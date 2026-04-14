# ⚙️ Application Logic

This document outlines the core architecture of the Assembly GPU Image Viewer using standard computer science methodologies: an Algorithm, Pseudocode, and a Visual Flowchart.

---

## 1. Algorithm

An algorithm is a step-by-step description of how the program solves the problem of displaying and interacting with an image.

**Step 1: Initialization**
* Initialize the SDL2 Video subsystem and SDL2_Image subsystem.
* Create a borderless, resizable OS window centered on the screen.
* Create a hardware-accelerated GPU renderer with VSync enabled.
* Load the default image file into a GPU Texture.
* Calculate initial scaling to fit the image inside the window.

**Step 2: The Main Application Loop**
* Check if the `isRunning` flag is set to True. If False, jump to Step 6.

**Step 3: Event Polling**
* Fetch the newest event from the OS queue.
* If the queue is empty, jump to Step 5.
* Determine the event type (Mouse Click, Mouse Scroll, Key Press, File Drop).

**Step 4: State Management**
* **If Drag & Drop:** Destroy the old texture, load the new file into the GPU, and reset the camera.
* **If Mouse Down:** Check collision with UI buttons. Set appropriate flags (`isDragging`, `isResizing`, `isMovingWindow`).
* **If Mouse Motion:** Update `posX` and `posY` if panning, or update Window Size/Position if interacting with the window borders.
* **If Mouse Wheel:** Multiply `zoomLevel` by a zoom factor (1.1 in or 0.9 out) and adjust `posX`/`posY` to zoom toward the center.
* Return to Step 3 until all events are processed.

**Step 5: GPU Rendering**
* Clear the previous frame with a solid background color.
* Calculate the new image dimensions by multiplying the original width/height by the `zoomLevel`.
* Draw the scaled image texture at the current `posX` and `posY`.
* Draw the colored UI rectangles (Move, Reset, Fullscreen, Close, Resize) over the frame buffer.
* Present the new frame to the screen.
* Return to Step 2.

**Step 6: Cleanup**
* Destroy the GPU Texture, Renderer, and Window pointers.
* Quit SDL2 and exit the program.

---

## 2. Pseudocode

Pseudocode represents the Assembly instructions in a readable, language-agnostic format.

```text
FUNCTION Main():
    CALL SDL_Init(VIDEO)
    CALL IMG_Init(ALL_FORMATS)
    
    window = CALL SDL_CreateWindow(BORDERLESS | RESIZABLE)
    renderer = CALL SDL_CreateRenderer(ACCELERATED | VSYNC)
    texture = CALL IMG_LoadTexture("test_image.jpg")
    
    CALL ResetCamera()
    isRunning = TRUE
    
    WHILE isRunning == TRUE:
        // 1. Process Events
        WHILE SDL_PollEvent(event) != 0:
            SWITCH event.type:
                CASE QUIT or ESC_KEY:
                    isRunning = FALSE
                
                CASE FILE_DROP:
                    Destroy(texture)
                    texture = LoadTexture(event.filename)
                    CALL ResetCamera()
                
                CASE MOUSE_DOWN:
                    IF CheckCollision(UI_CLOSE): isRunning = FALSE
                    ELSE IF CheckCollision(UI_FULLSCREEN): ToggleFullscreen()
                    ELSE IF CheckCollision(UI_RESET): CALL ResetCamera()
                    ELSE IF CheckCollision(UI_MOVE): isMovingWindow = TRUE
                    ELSE IF CheckCollision(UI_RESIZE): isResizing = TRUE
                    ELSE: isDragging = TRUE
                
                CASE MOUSE_UP:
                    isDragging = FALSE
                    isResizing = FALSE
                    isMovingWindow = FALSE
                
                CASE MOUSE_MOTION:
                    IF isDragging: UpdateImagePosition()
                    IF isMovingWindow: UpdateOSWindowPosition()
                    IF isResizing: UpdateOSWindowSize()
                
                CASE MOUSE_WHEEL:
                    CalculateNewZoom()
                    CenterCameraOnZoom()
        
        // 2. Render Frame
        CALL SDL_RenderClear()
        
        dstRect.width = origWidth * zoomLevel
        dstRect.height = origHeight * zoomLevel
        dstRect.x = posX
        dstRect.y = posY
        
        CALL SDL_RenderCopy(texture, dstRect)
        CALL DrawUIButtons()
        
        CALL SDL_RenderPresent()
    
    // 3. Cleanup
    CALL DestroyAllResources()
    RETURN 0
```


## 3. Visual Flowchart



```mermaid
flowchart TD
    Start([Start Program]) --> Init[Initialize SDL2 & Create Window/Renderer]
    Init --> LoadImg[Load Default Image to GPU]
    LoadImg --> MainLoop{Is Running?}
    
    MainLoop -- Yes --> PollEvent{Any OS Events?}
    
    PollEvent -- Yes --> CheckEvent[Identify Event Type]
    
    CheckEvent -->|File Drop| DropFile[Load New Image & Reset Camera]
    CheckEvent -->|Mouse Wheel| ZoomMath[Calculate Zoom Matrix]
    CheckEvent -->|Mouse Down/Up| SetFlags[Update Drag/Resize Flags]
    CheckEvent -->|Mouse Motion| MoveMath[Update Coordinates]
    CheckEvent -->|ESC / Close| SetQuit[Set isRunning = False]
    
    DropFile --> PollEvent
    ZoomMath --> PollEvent
    SetFlags --> PollEvent
    MoveMath --> PollEvent
    SetQuit --> PollEvent
    
    PollEvent -- No --> RenderFrame[Clear Framebuffer]
    RenderFrame --> DrawTex[Calculate Rect & Draw Texture]
    DrawTex --> DrawUI[Draw Custom Window Controls]
    DrawUI --> Present[Render Present / VSync]
    Present --> MainLoop
    
    MainLoop -- No --> Cleanup[Destroy Pointers & Free Memory]
    Cleanup --> End([Exit Program])
