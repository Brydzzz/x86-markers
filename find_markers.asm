%define WIDTH 320
%define HEIGHT 240
;=============================================================

section .text
global find_markers


find_markers:
    push ebp
    mov ebp, esp
    
    sub esp, 28

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
    mov DWORD[ebp-28], 0 ;y coordinate saver
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
    mov DWORD[ebp-12], eax ;save current x
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
    test eax, eax
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
    ; inc eax

    ; inc eax
    ; cmp eax, WIDTH
    ; jz .find_arm_one_top_skip_right_check
    ; dec eax
    ; jmp .find_arm_one_top_row
    jmp .find_arm_one_top_skip_right_check

.find_arm_one_top_row:
    mov eax, DWORD[ebp-12] ;restore x
    inc ebx ; y+=1
    cmp ebx, HEIGHT
    jge .not_a_marker_2 ;.exit
    inc eax ;x+=1
    call get_pixel ;check if right pixel white
    test eax, eax
    jz .not_a_marker_2
    mov eax, DWORD[ebp-12] ;restore x
    call get_pixel
    test eax, eax
    jnz .go_to_arm_two ;when arm one top was found go to arm two
    jmp .find_arm_one_top_row

.find_arm_one_top_skip_right_check:
    mov eax, DWORD[ebp-12] ;restore x
    inc ebx ; y+=1
    cmp ebx, HEIGHT
    jge .not_a_marker_2 ;.exit
    call get_pixel
    test eax, eax
    jnz .go_to_arm_two ;when arm one top was found go to arm two
    jmp .find_arm_one_top_skip_right_check

.not_a_marker_2:
    mov DWORD[ebp-8], 0 ; reset marker thickness counter
    mov eax, DWORD[ebp-16] ; x = corner_x
    add eax, DWORD[ebp-24] ; x+=width
    inc eax
    mov ebx, DWORD[ebp-20] ; y = corner_y
    jmp .find_corner_in_row_loop

.go_to_arm_two:
    ; marker thickness calculations
    mov ecx, ebx ; ecx = current_y
    sub ecx, DWORD[ebp-20] ;arm one thickness = current_y - corner_y
    mov DWORD[ebp-8], ecx ; move thickness value to ebp-8

    mov eax, DWORD[ebp-12] ;restore x
    dec eax ; x-=1
    mov DWORD[ebp-12], eax ;save current x
    jmp .check_arm_one_column

.check_arm_one_column:
    cmp ebx, DWORD[ebp-20] ; compare current_y and corner_y
    je .check_above_pixel ;if current_y == corner_y jmp check_abouve_pixel
    dec ebx ;y-=1
    call get_pixel
    test eax, eax
    jnz .not_a_marker_2
    mov eax, DWORD[ebp-12] ;restore x
    jmp .check_arm_one_column

.check_above_pixel:
    mov eax, DWORD[ebp-12] ;restore x
    add ebx, DWORD[ebp-8] ;go to row above arm one y+=arm_one_thickness
    call get_pixel
    test eax, eax
    jz .find_arm_two_top
    mov eax, DWORD[ebp-12] ;restore x
    cmp eax, DWORD[ebp-16]; if current_x=corner_x its not a marker (cause there is no arm two - pixel above is not black)
    jne .not_a_marker_2
    jmp .go_to_arm_two

.find_arm_two_top:
    mov eax, DWORD[ebp-12] ;restore x
    inc ebx ; y+=1
    cmp ebx, HEIGHT
    jge .marker_at_top_border ;if y >=240
    inc eax ; x+=1
    call get_pixel
    test eax, eax
    jz .not_a_marker_2 ;if pixel to the right of the right arm two border is black, it's not a marker
    mov eax, DWORD[ebp-12] ;restore x
    call get_pixel
    test eax, eax
    jnz .arm_two_top_found ;now check arm two right border pixels
    mov eax, DWORD[ebp-12] ;restore x
    jmp .find_arm_two_top

.marker_at_top_border:
    ;calculate_height_and_ratio
    mov ecx, ebx ; ecx = current_y
    sub ecx, DWORD[ebp-20] ; height=current_y - corner_y
	imul ecx, 2 ; height * 2
   ; mov DWORD[ebp-28], ecx ;move height*2 to ebp -28
    cmp ecx, DWORD[ebp-24] ; ?height*2==width
    jne .not_a_marker_2
    dec ebx ; back to y=239
    dec DWORD[ebp-8] ;marker thickness -=1 start of check if arms thickness is the same
    jmp .marker_at_top_border_top_loop

.marker_at_top_border_top_loop:
    test eax, eax
    jz .arm_two_right
    cmp eax, DWORD[ebp-16] ;if top_most_right_x == corner_x jmp to check arm two right_side
    je .arm_two_right
    dec DWORD[ebp-8] ;marker thickness -=1
    dec eax
    mov DWORD[ebp-12], eax ;save current x
    mov DWORD[ebp-28], ebx ;save current y
    jmp .check_arm_two_column_matb

.restore_y:
    mov eax, DWORD[ebp-12] ;restore x
    mov ebx, DWORD[ebp-28] ;restore y
    jmp .marker_at_top_border_top_loop

.check_arm_two_column_matb:
    cmp ebx, DWORD[ebp-20] ;?y==corner_y
    mov eax, DWORD[ebp-12] ;restore x
    call get_pixel
    test eax, eax
    jnz .not_a_marker_2 ;if pixels in column are not black it's not a marker
    dec ebx ;y-=1
    jmp .check_arm_two_column_matb

.arm_two_top_found:
    ;calculate_height_and_ratio
    ;calculate_height_and_ratio
    mov ecx, ebx ; ecx = current_y
    sub ecx, DWORD[ebp-20] ; height=current_y - corner_y
	imul ecx, 2 ; height * 2
    cmp ecx, DWORD[ebp-24] ; ?height*2==width
    jne .not_a_marker_2
    dec ebx ;go back to top black arm two row
    dec DWORD[ebp-8] ;marker thickness -=1
    jmp .arm_top_loop

.arm_top_loop:
    mov eax, DWORD[ebp-12] ;restore x
    cmp eax, DWORD[ebp-16] ; ?x == corner_x
    je .arm_two_right
    test eax, eax ; ?x==0
    jz .arm_two_right
    dec eax
    dec DWORD[ebp-8] ;marker thickness -=1
    mov DWORD[ebp-12], eax ;save current x
    mov DWORD[ebp-28], ebx ;save current y
    jmp .check_arm_two_column

.arm_top_above_pixel:
    mov eax, DWORD[ebp-12] ;restore x
    mov ebx, DWORD[ebp-28] ;restore y
    inc ebx ; y+=1
    call get_pixel
    test eax, eax
    jz .not_a_marker_2 ; if pixel above top is black it's not a marker
    dec ebx
    jmp .arm_top_loop

.check_arm_two_column:
    cmp ebx, DWORD[ebp-20] ; ?y==corner_y
    je .arm_top_above_pixel
    mov eax, DWORD[ebp-12] ;restore x
    call get_pixel
    test eax, eax
    jnz .not_a_marker_2 ;if pixels in column are not black it's not a marker
    dec ebx
    jmp .check_arm_two_column

.arm_two_right:
    cmp DWORD[ebp-8], 0 ; if thickness after substraction not 0, not_a_marker_2
    je .not_a_marker_2
    mov DWORD[ebp-12], eax ;save current x
    jmp .arm_two_right_loop

.arm_two_right_loop:
    cmp ebx, DWORD[ebp-20] ; if we reach corner y, marker was found
    je .marker_found
    call get_pixel
    test eax, eax ;check if arm pixel is black
    jnz .not_a_marker_2
    mov eax, DWORD[ebp-12] ;restore x
    test eax, eax
    jz .skip_right_check ; if marker is next to file left border
    ;check pixel next to arm two pixel
    dec eax
    call get_pixel
    test eax, eax
    jz .not_a_marker_2
    mov eax, DWORD[ebp-12] ;restore x
    dec ebx
    jmp .arm_two_right_loop

.skip_right_check:
    dec ebx
    jmp .arm_two_right_loop

.marker_found:
    mov DWORD[ebp-4], 22
    jmp .exit

.exit:
    mov eax, DWORD[ebp-4]

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
