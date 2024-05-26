%define WIDTH 320
%define HEIGHT 240
;=============================================================

section .text
global find_markers


find_markers:
    push ebp
    mov ebp, esp
    
    sub esp, 24

    push ebx
    push edi
    push esi
    push edx

    mov DWORD[ebp-4], 0 ;set marker counter to 0
    mov DWORD[ebp-8], 0 ;set marker thickness counter to 0
    mov DWORD[ebp-12], 0 ;x coordiante saver
    ;ebp-16 for corner x
    ;ebp-20 for corner y
    mov DWORD[ebp-24], 0 ;marker width
    mov edx, DWORD[ebp+8] ;load address of bitmap to edx
    
    xor eax, eax; eax - x coordinate
    xor ebx, ebx; ebx - y coordinate

.find_corner_in_row_loop:
    cmp ebx, HEIGHT
    jge .exit
    cmp eax, WIDTH
    jge .next_row
    mov DWORD[ebp-12], eax
    call get_pixel
    test eax, eax
    jz .possible_corner ;.possible_corner
    mov eax, DWORD[ebp-12]
    inc eax
    jmp .find_corner_in_row_loop


.next_row:
    xor eax, eax ;x=0
    inc ebx; y+=1
    cmp ebx, HEIGHT
    jge .exit
    jmp .find_corner_in_row_loop

.possible_corner:
    mov eax, DWORD[ebp-12]
    ;inc DWORD[ebp-4]
    jmp .arm_one

.arm_one:
    mov DWORD[ebp-16], eax ; save corner x for later
    mov DWORD[ebp-20], ebx ; save corner y for later

    ;check pixel_below_corner
    test ebx, ebx
    jz .arm_one_row_0 ;if arm one at x=0 don't check below pixels
    dec ebx ;y-=1
    call get_pixel ; get color of pixel below corner
    test eax, eax
    jz .not_a_marker_1
    mov eax, DWORD[ebp-12] ;restore x
    inc eax ;x+=1
    jmp .arm_one_loop

.arm_one_loop:
    cmp eax, WIDTH ;if x>= 320 end of arm_one
    jge .end_of_arm_one_file_border
    mov DWORD[ebp-12], eax ;save current x
    call get_pixel ;get color of pixel in row below corner
    test eax, eax
    jz .not_a_marker_1
    mov eax, DWORD[ebp-12] ;restore x
    inc ebx ;check pixel in corner row
    call get_pixel
    jnz .end_of_arm_one ;if pixel in corner row not black jump to end_of_arm_one
    mov eax, DWORD[ebp-12] ;restore x
    inc eax ; x+=1
    dec ebx ;y-=1 - move back to row below corner
    jmp .arm_one_loop


.arm_one_row_0:
    cmp eax, WIDTH ;if x>= 320 end of arm_one
    jge .end_of_arm_one_file_border
    mov DWORD[ebp-12], eax ;save current x
    call get_pixel
    test eax, eax
    jnz .end_of_arm_one ;if pixel in corner row not black jump to end_of_arm_one
    mov eax, DWORD[ebp-12] ;restore x
    inc eax ; x+=1
    jmp .arm_one_row_0

.not_a_marker_1:
    mov DWORD[ebp-8], 0 ;reset marker thickness
    mov ebx, DWORD[ebp-20] ; go back to row where incorrect corner was found
    mov eax, DWORD[ebp-12] ;restore x
    call get_pixel ; check pixel in corner row to determine whether to increase current_x by 1 or 2
    test eax, eax
    jz .increase_by_2
    mov eax, DWORD[ebp-12] ;restore x
    inc eax ;x+=1
    jmp .find_corner_in_row_loop

    .increase_by_2:
        mov eax, DWORD[ebp-12] ;restore x
        add eax, 2 ;x+=1
        jmp .find_corner_in_row_loop

.end_of_arm_one:
    mov eax, DWORD[ebp-12] ;restore x
    mov ecx, eax
    sub ecx, DWORD[ebp-16] ; width = current_x - corner_x
    mov DWORD[ebp-24], ecx ; store width
    test ecx, 1 ; check if width even
    jnz .not_a_marker_1
    dec eax ; go to the last black pixel in arm
    mov DWORD[ebp-12], eax ;save current x
    jmp .exit ;.find_arm_one_top_row

.end_of_arm_one_file_border:
    mov eax, DWORD[ebp-12] ;restore x
    mov ecx, eax
    sub ecx, DWORD[ebp-16] ; width = current_x - corner_x
    inc ecx ; width correction - width+=1
    mov DWORD[ebp-24], ecx ; store width
    test ecx, 1 ; check if width even
    jnz .not_a_marker_1
    dec eax ; go to the last black pixel in arm
    mov DWORD[ebp-12], eax ;save current x
    inc eax

    ; inc eax
    ; cmp eax, WIDTH
    ; jz .find_arm_one_top_skip_right_check
    ; dec eax
    ; jmp .find_arm_one_top_row
    jmp .exit

.find_arm_one_top_skip_right_check:

.find_arm_one_top_row:

.exit:
    mov eax, DWORD[ebp-24]

    pop edx
    pop esi
    pop edi
    pop ebx

    mov esp, ebp
    pop ebp
    ret

get_pixel:
; description:
;   returns color of specified pixel
; arguments:
;   eax - x coordinate
;   ebx - y coordinate
; return value:
;   eax - 0RGB - pixel color

    push ebp
    mov ebp, esp

    ;pixel address calculation
    xor ecx, ecx ; reset ecx
    imul ecx, ebx, WIDTH ; ecx = y*width
    add ecx, eax ; ecx += x
    imul ecx, 3 ; ecx*=3, cause 3 colors of pixel
    add ecx, edx ; ecx+=bitmap address

    ;get color
    xor eax, eax ;reset eax
    add al, BYTE[ecx+2] ; load R
    shl eax, 8 ;make space for G
    mov al, BYTE[ecx+1] ; load G
    shl eax, 8 ; make space for B
    mov al, BYTE[ecx] ; load B

    mov esp, ebp
    pop ebp
    ret
