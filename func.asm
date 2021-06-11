%use fp
section .text

global generate_fern
;----------------------------------------------
; Function generates Barnsley Fern in buffer
;----------------------------------------------
generate_fern:
; arguments: rdi = counter, rsi = *image_header, rdx = f1_prob, rcx = f2_prob, r8 = f3_prob

    ;prolog
	push	rbp
	mov		rbp, rsp

	mov     rax, 0x32CD32   ; lime green

    mov     rbx, [rsi+18]   ; rbx = width of image

    ;calculate row size
    imul    rbx, 3          
    add     rbx, 3         
    and     ebx, 0xFFFFFFFC ; rbx = (width*3 + 3) & ~3 -- least multiple of four

    ;push arguments to stack
    push    rsi             ; [rbp-8] = *image_header
    push    rbx             ; [rbp-16] = row_size
    push    rax             ; [rbp-24] = color
    push    rdi             ; [rbp-32] = counter
    push    rdx             ; [rbp-40] = f1_prob
    push    rcx             ; [rbp-48] = f2_prob
    push    r8              ; [rbp-56] = f3_prob

    ;store start point to rdi and rsi
    mov     rdi, 1          
    mov     rsi, 1

;---------------------------------
;   Coloring pixel (x,y)
;---------------------------------
color:
; arguments: rdi: x, rsi = y

    ;move offset to middle of bitmap to generate image on center
    mov     rcx, [rbp-8]
    xor     rdx, rdx
    xor     rax, rax
    mov     eax, [rcx+18]
    shr     rax, 1

    mov     r14, rax        ;r14 = width/2
    
    xor     rdx, rdx
    xor     rax, rax
    mov     eax, [rcx+22]
    mov     r11, 10
    div     r11

    mov     rcx, rax        ;rcx = hight/10
    mov     rdx, r14        ;rdx = width/2

    add     rdx, rdi        ; rdx += x
    add     rcx, rsi        ; rcx += y

    mov     rbx, [rbp-16]   ; rbx = row_size
    mov     rax, [rbp-8]    ; rax = *image_header

    imul    rbx, rcx        ; rbx = row_size * y

    ;column calculation
    imul    rdx, 3     
    add     rbx, rdx       
    add     rbx, rax        
    add     rbx, 54         

    ;copy to memory
    mov     rdx, [rbp-24]   ; rdx = color
    mov     [rbx], dx       ; store GGBB
    shr     rdx, 16         ; in rdx now 0x000000RR
    mov     [rbx+2], dl     ; store red

;--------------------------------------------------------
;   Choosing function of calculating next x and y 
;--------------------------------------------------------
random_function:
; arguments: rdi: x, rsi: y

    cvtsi2sd    xmm0, rdi       ; xmm0 = float(x)
    cvtsi2sd    xmm1, rsi       ; xmm1 = float(y)

    ;generate random number from 0 to 99 to rdx
    xor     rdx, rdx
    rdrand  rax
	mov     rcx, 100
    div     rcx             

    cmp     rdx, [rbp-40]
    jl      func1
    cmp     rdx, [rbp-48]
    jl      func2
    cmp     rdx, [rbp-56]
    jl      func3

func4:
    mov     rax, float64(0.0)   ; rax = 0.0
    movq    xmm2, rax           ; xmm2 = 0.0
    mov     rax, float64(0.16)  ; rax = 0.16
    movq    xmm4, rax           ; xmm4 = 0.16
    movq    xmm3, xmm1          ; xmm3 = y
    mulsd   xmm3, xmm4          ; xmm3 = y * 0.16

    jmp     set_new_coords

func1:
    mov     rax, float64(0.85)  ; rax = 0.85
    movq    xmm2, rax           ; xmm2 = 0.85
    mulsd   xmm2, xmm0          ; xmm2 = x*0.85
    mov     rax, float64(0.04)  ; rax = 0.04
    movq    xmm4, rax           ; xmm4 = 0.04
    mulsd   xmm4, xmm1          ; xmm4 = y*0.04
    addsd   xmm2, xmm4          ; xmm2 = x*0.85 + y*0.04

    mov     rax, float64(-0.04) ; rax = -0.04
    movq    xmm3, rax           ; xmm3 = -0.04
    mulsd   xmm3, xmm0          ; xmm3 = x*-0.04
    mov     rax, float64(0.85)  ; rax = 0.85
    movq    xmm4, rax           ; xmm4 = 0.85
    mulsd   xmm4, xmm1          ; xmm4 = y*0.85
    addsd   xmm3, xmm4          ; xmm3 = x*-0.04 + y*0.85
    mov     rbx, [rbp-8]        ; rax = image_header
    xor     rax, rax            ; rax = 0
    mov     eax, [rbx+18]       ; eax = width
    mov     rcx, float64(12.0)  ; rcx = 12
    movq    xmm6, rcx           ; xmm6 = 12
    cvtsi2sd    xmm5, rax       ; xmm5 = width
    divsd   xmm5, xmm6          ; xmm5 = width/12
    mov     rdx, float64(1.6)   ; rdx = 1.6
    movq    xmm4, rdx           ; xmm4 = 1.6
    mulsd   xmm4, xmm5          ; xmm4 = 1.6 * width/12
    addsd   xmm3, xmm4          ; xmm3 = x*-0.04 + y*0.85 + 1.6 * width/12

    jmp     set_new_coords

func2:
    mov     rax, float64(-0.15) ; rax = -0.15
    movq    xmm2, rax           ; xmm2 = -0.15
    mulsd   xmm2, xmm0          ; xmm2 = x*-0.15
    mov     rax, float64(0.28)  ; rax = 0.28
    movq    xmm4, rax           ; xmm4 = 0.28
    mulsd   xmm4, xmm1          ; xmm4 = y*0.28
    addsd   xmm2, xmm4          ; xmm2 = x*-0.15 + y*0.28

    mov     rax, float64(0.26)  ; rax = 0.26
    movq    xmm3, rax           ; xmm3 = 0.26
    mulsd   xmm3, xmm0          ; xmm3 = x*0.26
    mov     rax, float64(0.24)  ; rax = 0.24
    movq    xmm4, rax           ; xmm4 = 0.24
    mulsd   xmm4, xmm1          ; xmm4 = y*0.24
    addsd   xmm3, xmm4          ; xmm3 = x*0.26 + y*0.24
    mov     rbx, [rbp-8]        ; rax = image_header
    xor     rax, rax            ; rax = 0
    mov     eax, [rbx+18]       ; eax = width
    mov     rcx, float64(12.0)  ; rcx = 12
    movq    xmm6, rcx           ; xmm6 = 12
    cvtsi2sd    xmm5, rax       ; xmm5 = width
    divsd   xmm5, xmm6          ; xmm5 = width/12
    mov     rdx, float64(0.44)  ; rdx = 0.44
    movq    xmm4, rdx           ; xmm4 = 0.44
    mulsd   xmm4, xmm5          ; xmm4 = 0.44 * width/12
    addsd   xmm3, xmm4          ; xmm3 = x*0.26 + y*0.24 + 0.44 * width/12

    jmp     set_new_coords

func3:
    mov     rax, float64(0.20)  ; rax = 0.20
    movq    xmm2, rax           ; xmm2 = 0.20
    mulsd   xmm2, xmm0          ; xmm2 = x*0.20
    mov     rax, float64(-0.26) ; rax = -0.26
    movq    xmm4, rax           ; xmm4 = -0.26
    mulsd   xmm4, xmm1          ; xmm4 = y*-0.26
    addsd   xmm2, xmm4          ; xmm2 = x*0.20 + y*-0.26

    mov     rax, float64(0.23)  ; rax = 0.23
    movq    xmm3, rax           ; xmm3 = 0.23
    mulsd   xmm3, xmm0          ; xmm3 = x*0.23
    mov     rax, float64(0.22)  ; rax = 0.22
    movq    xmm4, rax           ; xmm4 = 0.22
    mulsd   xmm4, xmm1          ; xmm4 = y*0.22
    addsd   xmm3, xmm4          ; xmm3 = x*0.23 + y*0.22
    mov     rbx, [rbp-8]        ; rax = image_header
    xor     rax, rax            ; rax = 0
    mov     eax, [rbx+18]       ; eax = width
    mov     rcx, float64(12.0)  ; rcx = 12
    movq    xmm6, rcx           ; xmm6 = 12
    cvtsi2sd    xmm5, rax       ; xmm5 = width
    divsd   xmm5, xmm6          ; xmm5 = width/12
    mov     rdx, float64(1.6)   ; rdx = 1.6
    movq    xmm4, rdx           ; xmm4 = 1.6
    mulsd   xmm4, xmm5          ; xmm4 = 1.6 * width/12
    addsd   xmm3, xmm4          ; xmm3 = x*0.23 + y*0.22 + 1.6 * width/12

set_new_coords:
; sets new coords in int to rdi and rsi
; arguments: xmm2: new_x, xmm3: new_y
    cvtsd2si    rdi, xmm2   ; rdi = new_x
    cvtsd2si    rsi, xmm3   ; rsi = new_y

check_if_end:
; decrement and check if counter == 0

    dec     qword [rbp-32]
    mov     rax, [rbp-32]
    cmp     rax, 0
    jnz     color

epilog:
; end of the function

	mov		rsp, rbp
	pop		rbp
	ret
