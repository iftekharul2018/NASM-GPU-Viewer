bits 64
default rel

; --- CROSS-PLATFORM CALLING CONVENTION MACROS ---
%ifdef WINDOWS
    %define arg1 rcx
    %define arg2 rdx
    %define arg3 r8
    %define arg4 r9
%else ; LINUX
    %define arg1 rdi
    %define arg2 rsi
    %define arg3 rdx
    %define arg4 rcx
%endif

segment .data
    windowTitle db "Assembly GPU Viewer", 0
    imgFile     db "test_image.jpg", 0   

    ; SDL & IMG Constants
    SDL_INIT_VIDEO equ 0x00000020
    
    ; 1=JPG, 2=PNG, 4=TIF, 8=WEBP (Total 15 for all)
    IMG_INIT_ALL   equ 0x0000000F 
    
    ; Window & Renderer Flags
    SDL_WINDOWPOS_CENTERED equ 0x2FFF0000
    SDL_WINDOW_BORDERLESS  equ 0x00000010
    SDL_WINDOW_RESIZABLE   equ 0x00000020
    SDL_WINDOW_FULLSCREEN_DESKTOP equ 0x00001001 
    SDL_RENDERER_ACCELERATED equ 0x00000002
    SDL_RENDERER_PRESENTVSYNC equ 0x00000004

    ; Float Constants for Math
    zoomFactorIn   dd 1.1
    zoomFactorOut  dd 0.90909
    floatTwo       dd 2.0

segment .bss
    align 16
    pWindow     resq 1
    pRenderer   resq 1
    pTexture    resq 1
    
    event       resb 64 
    dstRect     resd 4  
    uiRect      resd 4
    
    origWidth   resd 1
    origHeight  resd 1
    winW        resd 1
    winH        resd 1
    winX        resd 1  
    winY        resd 1  
    
    ; Camera & State Flags
    zoomLevel      resd 1
    posX           resd 1
    posY           resd 1
    
    isRunning      resb 1
    isDragging     resb 1  
    isResizing     resb 1  
    isMovingWindow resb 1  
    isFullScreen   resb 1

segment .text
    global main
    extern SDL_Init, SDL_Quit
    extern SDL_CreateWindow, SDL_DestroyWindow
    extern SDL_CreateRenderer, SDL_DestroyRenderer
    extern SDL_GetWindowSize, SDL_SetWindowSize, SDL_SetWindowFullscreen
    extern SDL_GetWindowPosition, SDL_SetWindowPosition
    extern SDL_PollEvent, SDL_free
    extern SDL_SetRenderDrawColor, SDL_RenderFillRect
    extern SDL_RenderClear, SDL_RenderCopy, SDL_RenderPresent
    extern SDL_QueryTexture, SDL_DestroyTexture
    extern IMG_Init, IMG_Quit, IMG_LoadTexture

main:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; 1. Initialize SDL2
    mov arg1, SDL_INIT_VIDEO
    call SDL_Init

    ; 2. Initialize SDL_image (JPG + PNG + TIF + WEBP)
    mov arg1, IMG_INIT_ALL
    call IMG_Init

    ; 3. Create Borderless Window
    lea arg1, [rel windowTitle]
    mov arg2, SDL_WINDOWPOS_CENTERED
    mov arg3, SDL_WINDOWPOS_CENTERED
    mov arg4, 800           
    mov qword [rsp+32], 600 
    
    mov rax, SDL_WINDOW_BORDERLESS
    or rax, SDL_WINDOW_RESIZABLE
    mov qword [rsp+40], rax 
    call SDL_CreateWindow
    mov [rel pWindow], rax

    ; 4. Create Renderer
    mov arg1, [rel pWindow]
    mov arg2, -1
    mov arg3, SDL_RENDERER_ACCELERATED
    or arg3, SDL_RENDERER_PRESENTVSYNC
    call SDL_CreateRenderer
    mov [rel pRenderer], rax

    ; 5. Load Initial Image
    mov arg1, [rel pRenderer]
    lea arg2, [rel imgFile]
    call IMG_LoadTexture
    mov [rel pTexture], rax

    ; 6. Get Initial Texture Size
    mov arg1, [rel pTexture]
    xor arg2, arg2       
    xor arg3, arg3       
    lea arg4, [rel origWidth]
    lea rax, [rel origHeight]
    mov [rsp+32], rax    
    call SDL_QueryTexture

    ; 7. Setup initial dimensions and compute camera
    mov dword [rel winW], 800
    mov dword [rel winH], 600
    call reset_camera

    mov byte [rel isRunning], 1
    mov byte [rel isDragging], 0
    mov byte [rel isResizing], 0
    mov byte [rel isMovingWindow], 0
    mov byte [rel isFullScreen], 0

.main_loop:
    cmp byte [rel isRunning], 0
    je .cleanup

    ; --- EVENT POLLING ---
.poll_events:
    lea arg1, [rel event]
    call SDL_PollEvent
    test rax, rax
    jz .render_frame

    mov eax, dword [rel event] 
    
    cmp eax, 0x100  ; SDL_QUIT
    je .quit_event
    cmp eax, 0x300  ; SDL_KEYDOWN 
    je .key_down
    cmp eax, 0x401  ; SDL_MOUSEBUTTONDOWN
    je .mouse_down
    cmp eax, 0x402  ; SDL_MOUSEBUTTONUP
    je .mouse_up
    cmp eax, 0x400  ; SDL_MOUSEMOTION
    je .mouse_motion
    cmp eax, 0x403  ; SDL_MOUSEWHEEL
    je .mouse_wheel
    cmp eax, 0x1000 ; SDL_DROPFILE
    je .drop_file
    
    jmp .poll_events

.key_down:
    cmp dword [rel event+20], 27 ; ESC
    je .quit_event
    jmp .poll_events

.quit_event:
    mov byte [rel isRunning], 0
    jmp .poll_events

    ; --- FILE DROP EVENT ---
.drop_file:
    mov arg1, [rel pTexture]
    call SDL_DestroyTexture

    mov arg1, [rel pRenderer]
    mov arg2, [rel event+8]
    call IMG_LoadTexture
    mov [rel pTexture], rax

    mov arg1, [rel event+8]
    call SDL_free

    mov arg1, [rel pTexture]
    xor arg2, arg2       
    xor arg3, arg3       
    lea arg4, [rel origWidth]
    lea rax, [rel origHeight]
    mov [rsp+32], rax    
    call SDL_QueryTexture

    call reset_camera
    jmp .poll_events

    ; --- MOUSE EVENTS ---
.mouse_down:
    cmp byte [rel event+16], 1   
    jne .poll_events

    mov arg1, [rel pWindow]
    lea arg2, [rel winW]
    lea arg3, [rel winH]
    call SDL_GetWindowSize

    mov eax, dword [rel event+20] 
    mov ebx, dword [rel event+24] 

    cmp eax, 40
    jg .check_close_btn
    cmp ebx, 40
    jg .check_close_btn
    mov byte [rel isMovingWindow], 1
    jmp .poll_events

.check_close_btn:
    cmp ebx, 40
    jg .check_reset_btn
    mov ecx, dword [rel winW]
    sub ecx, 40
    cmp eax, ecx
    jge .quit_event

.check_fullscreen_btn:
    mov ecx, dword [rel winW]
    sub ecx, 80
    cmp eax, ecx
    jge .toggle_fullscreen

.check_reset_btn:
    cmp eax, 40
    jg .check_resize_handle
    mov ecx, dword [rel winH]
    sub ecx, 40
    cmp ebx, ecx
    jl .check_resize_handle
    call reset_camera
    jmp .poll_events

.check_resize_handle:
    mov ecx, dword [rel winW]
    sub ecx, 20
    cmp eax, ecx
    jl .start_pan
    mov edx, dword [rel winH]
    sub edx, 20
    cmp ebx, edx
    jl .start_pan
    mov byte [rel isResizing], 1
    jmp .poll_events

.start_pan:
    mov byte [rel isDragging], 1
    jmp .poll_events

.toggle_fullscreen:
    xor byte [rel isFullScreen], 1
    cmp byte [rel isFullScreen], 1
    je .set_full
    mov arg1, [rel pWindow]
    xor arg2, arg2
    call SDL_SetWindowFullscreen
    call reset_camera
    jmp .poll_events
.set_full:
    mov arg1, [rel pWindow]
    mov arg2, SDL_WINDOW_FULLSCREEN_DESKTOP
    call SDL_SetWindowFullscreen
    jmp .poll_events

.mouse_up:
    cmp byte [rel event+16], 1   
    jne .poll_events
    mov byte [rel isDragging], 0
    mov byte [rel isResizing], 0
    mov byte [rel isMovingWindow], 0
    jmp .poll_events

.mouse_motion:
    cmp byte [rel isMovingWindow], 1
    je .handle_window_move
    cmp byte [rel isResizing], 1
    je .handle_window_resize
    cmp byte [rel isDragging], 1 
    je .handle_image_pan
    jmp .poll_events

.handle_window_move:
    movsxd r12, dword [rel event+28] 
    movsxd r13, dword [rel event+32] 
    mov arg1, [rel pWindow]
    lea arg2, [rel winX]
    lea arg3, [rel winY]
    call SDL_GetWindowPosition
    movsxd rax, dword [rel winX]
    add rax, r12
    movsxd rbx, dword [rel winY]
    add rbx, r13
    mov arg1, [rel pWindow]
    mov arg2, rax
    mov arg3, rbx
    call SDL_SetWindowPosition
    jmp .poll_events

.handle_window_resize:
    movsxd rax, dword [rel event+28] 
    movsxd rbx, dword [rel event+32] 
    movsxd r10, dword [rel winW]
    add r10, rax
    cmp r10, 200 
    jg .w_ok
    mov r10, 200
.w_ok:
    mov dword [rel winW], r10d
    movsxd r11, dword [rel winH]
    add r11, rbx
    cmp r11, 200 
    jg .h_ok
    mov r11, 200
.h_ok:
    mov dword [rel winH], r11d
    mov arg1, [rel pWindow]
    mov arg2, r10     
    mov arg3, r11     
    call SDL_SetWindowSize
    jmp .poll_events

.handle_image_pan:
    cvtsi2ss xmm0, dword [rel event+28] 
    addss xmm0, dword [rel posX]
    movss dword [rel posX], xmm0
    cvtsi2ss xmm1, dword [rel event+32] 
    addss xmm1, dword [rel posY]
    movss dword [rel posY], xmm1
    jmp .poll_events

.mouse_wheel:
    mov eax, dword [rel event+20] 
    test eax, eax
    jz .poll_events
    movss xmm0, dword [rel zoomLevel]
    movss xmm1, xmm0              
    js .zoom_out                  
    mulss xmm0, dword [rel zoomFactorIn]
    jmp .apply_zoom
.zoom_out:
    mulss xmm0, dword [rel zoomFactorOut]
.apply_zoom:
    movss dword [rel zoomLevel], xmm0
    subss xmm0, xmm1
    cvtsi2ss xmm2, dword [rel origWidth]
    mulss xmm2, xmm0
    divss xmm2, dword [rel floatTwo] 
    cvtsi2ss xmm3, dword [rel origHeight]
    mulss xmm3, xmm0
    divss xmm3, dword [rel floatTwo] 
    movss xmm4, dword [rel posX]
    subss xmm4, xmm2
    movss dword [rel posX], xmm4
    movss xmm5, dword [rel posY]
    subss xmm5, xmm3
    movss dword [rel posY], xmm5
    jmp .poll_events

    ; --- GPU RENDERING ---
.render_frame:
    mov arg1, [rel pRenderer]
    mov arg2, 0
    mov arg3, 0
    mov arg4, 0
    mov qword [rsp+32], 255
    call SDL_SetRenderDrawColor

    mov arg1, [rel pRenderer]
    call SDL_RenderClear

    ; Draw Image
    cvtsi2ss xmm0, dword [rel origWidth]
    mulss xmm0, dword [rel zoomLevel]
    cvttss2si eax, xmm0              
    mov dword [rel dstRect+8], eax   
    cvtsi2ss xmm0, dword [rel origHeight]
    mulss xmm0, dword [rel zoomLevel]
    cvttss2si eax, xmm0
    mov dword [rel dstRect+12], eax  
    cvttss2si eax, dword [rel posX]
    mov dword [rel dstRect+0], eax
    cvttss2si eax, dword [rel posY]
    mov dword [rel dstRect+4], eax

    mov arg1, [rel pRenderer]
    mov arg2, [rel pTexture]
    xor arg3, arg3           
    lea arg4, [rel dstRect]  
    call SDL_RenderCopy

    ; Get Window Size for UI Updates
    mov arg1, [rel pWindow]
    lea arg2, [rel winW]
    lea arg3, [rel winH]
    call SDL_GetWindowSize

    ; Draw MOVE Button (Green, Top Left)
    mov arg1, [rel pRenderer]
    mov arg2, 50
    mov arg3, 255
    mov arg4, 50
    mov qword [rsp+32], 255
    call SDL_SetRenderDrawColor
    mov dword [rel uiRect+0], 0   
    mov dword [rel uiRect+4], 0   
    mov dword [rel uiRect+8], 40  
    mov dword [rel uiRect+12], 40 
    mov arg1, [rel pRenderer]
    lea arg2, [rel uiRect]
    call SDL_RenderFillRect

    ; Draw RESET CAMERA Button (Yellow, Bottom Left)
    mov arg1, [rel pRenderer]
    mov arg2, 255
    mov arg3, 255
    mov arg4, 0
    mov qword [rsp+32], 255
    call SDL_SetRenderDrawColor
    mov dword [rel uiRect+0], 0 
    mov eax, dword [rel winH]
    sub eax, 40
    mov dword [rel uiRect+4], eax 
    mov dword [rel uiRect+8], 40  
    mov dword [rel uiRect+12], 40 
    mov arg1, [rel pRenderer]
    lea arg2, [rel uiRect]
    call SDL_RenderFillRect

    ; Draw Fullscreen Button (Blue, Top Right)
    mov arg1, [rel pRenderer]
    mov arg2, 0
    mov arg3, 120
    mov arg4, 255
    mov qword [rsp+32], 255
    call SDL_SetRenderDrawColor
    mov eax, dword [rel winW]
    sub eax, 80
    mov dword [rel uiRect+0], eax 
    mov dword [rel uiRect+4], 0   
    mov dword [rel uiRect+8], 40  
    mov dword [rel uiRect+12], 40 
    mov arg1, [rel pRenderer]
    lea arg2, [rel uiRect]
    call SDL_RenderFillRect

    ; Draw Close Button (Red, Top Right)
    mov arg1, [rel pRenderer]
    mov arg2, 255
    mov arg3, 50
    mov arg4, 50
    mov qword [rsp+32], 255
    call SDL_SetRenderDrawColor
    mov eax, dword [rel winW]
    sub eax, 40
    mov dword [rel uiRect+0], eax 
    mov arg1, [rel pRenderer]
    lea arg2, [rel uiRect]
    call SDL_RenderFillRect

    ; Draw Resize Handle (Grey, Bottom Right)
    mov arg1, [rel pRenderer]
    mov arg2, 100
    mov arg3, 100
    mov arg4, 100
    mov qword [rsp+32], 255
    call SDL_SetRenderDrawColor
    mov eax, dword [rel winW]
    sub eax, 20
    mov dword [rel uiRect+0], eax 
    mov ebx, dword [rel winH]
    sub ebx, 20
    mov dword [rel uiRect+4], ebx 
    mov dword [rel uiRect+8], 20  
    mov dword [rel uiRect+12], 20 
    mov arg1, [rel pRenderer]
    lea arg2, [rel uiRect]
    call SDL_RenderFillRect

    mov arg1, [rel pRenderer]
    call SDL_RenderPresent

    jmp .main_loop

.cleanup:
    mov arg1, [rel pTexture]
    call SDL_DestroyTexture
    mov arg1, [rel pRenderer]
    call SDL_DestroyRenderer
    mov arg1, [rel pWindow]
    call SDL_DestroyWindow
    call IMG_Quit
    call SDL_Quit

    leave
    ret

; --- SUBROUTINE: RE-CENTER CAMERA ---
; Placed OUTSIDE main so it doesn't break local label scope
reset_camera:
    cvtsi2ss xmm0, dword [rel origWidth]
    cvtsi2ss xmm1, dword [rel origHeight]
    cvtsi2ss xmm2, dword [rel winW]
    cvtsi2ss xmm3, dword [rel winH]
    divss xmm2, xmm0  
    divss xmm3, xmm1  
    minss xmm2, xmm3  
    movss dword [rel zoomLevel], xmm2
    mulss xmm0, xmm2  
    cvtsi2ss xmm4, dword [rel winW]
    subss xmm4, xmm0
    divss xmm4, dword [rel floatTwo]
    movss dword [rel posX], xmm4
    mulss xmm1, xmm2  
    cvtsi2ss xmm5, dword [rel winH]
    subss xmm5, xmm1
    divss xmm5, dword [rel floatTwo]
    movss dword [rel posY], xmm5
    ret