[org 0x100]
jmp start

sanke: times 200 dw 0          
snk_size: dw 1
temp: dw 0
apple_pos dw 0
score: dw 0
last_direction db 'R'  

score_text db 'Score: ', '00', 0

game_over_msg db '** GAME OVER **', 0
score_msg     db 'Score: ', 0
rq_msg        db 'Restart or Quit R/Q', 0

making_board: ;Draw Borders and board
pushad
mov ax, 0xB800
mov es, ax
xor di, di
mov ax, 0x3320       ; Board color
mov cx, 2000
cld
rep stosw

;score row
mov ax, 0x3320
mov cx, 80
mov di, 0
clr_score:
mov [es:di], ax
add di, 2
loop clr_score

mov ah, 0x1F
mov al, '|'
mov cx, 23
mov si, 320      

left_right_border:
mov di, si
mov [es:di], ax         

add di, 158
mov [es:di], ax         

add si, 160
loop left_right_border

mov ah, 0x1F
mov al, '-'
mov cx, 79
mov di, 160   
top_border:
mov [es:di], ax
add di, 2
loop top_border


mov cx, 78
mov di, 3842
bottom_border:
mov [es:di], ax
add di, 2
loop bottom_border
popad
ret


print_score:  ; score printing
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, 0xB800
    mov es, ax
    mov di, 66   ;score kee positioning

    mov si, score_text
ps_loop:
    lodsb
    cmp al, 0
    je ps_done
    mov ah, 0x30
    mov [es:di], ax
    add di, 2
    jmp ps_loop
ps_done:

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

update_score:
push ax
push bx

mov ax, [score]
mov bx, 10
xor dx, dx
div bx
add dl, '0'
mov [score_text+8], dl
mov al, ah
add al, '0'
mov [score_text+7], al
call print_score

pop bx
pop ax
ret

move_snake: ; main loops snake movement and game loop
pushad
mov ax, 0xB800
mov es, ax
mov di, 1000

mov byte [last_direction], 'R'

game_loop:
mov ah, 01h
int 16h
jz no_key_press

mov ah, 00h
int 16h

cmp ah, 0x4B 
je set_left
cmp ah, 0x4D 
je set_right
cmp ah, 0x50 
je set_down
cmp ah, 0x48 
je set_up

jmp no_key_press

set_left:
mov byte [last_direction], 'L'
jmp no_key_press

set_right:
mov byte [last_direction], 'R'
jmp no_key_press

set_down:
mov byte [last_direction], 'D'
jmp no_key_press

set_up:
mov byte [last_direction], 'U'
jmp no_key_press

no_key_press:
mov al, [last_direction]
cmp al, 'R'
je mov_right
cmp al, 'L'
je mov_left
cmp al, 'U'
je mov_up
cmp al, 'D'
je mov_down
jmp game_loop

mov_right:
add di, 2
call check
call move_snake_direction
jmp delay_and_continue

mov_left:
sub di, 2
call check
call move_snake_direction
jmp delay_and_continue

mov_up:
sub di, 160
call check
call move_snake_direction
jmp delay_and_continue

mov_down:
add di, 160
call check
call move_snake_direction
jmp delay_and_continue

delay_and_continue:
call delay
jmp game_loop
popad
ret


delay: ; delay movement
push cx
push dx
mov cx, 0300h  
mov dx, 04h     

delay_outer:
push dx
delay_loop:
nop
loop delay_loop
pop dx
dec dx
jnz delay_outer
pop dx
pop cx
ret


move_snake_direction:  ; move snake and print (erase snake as it moves and shift)
push ax
push bx
push cx
push dx
push si
push di

mov bx, di

mov cx, [snk_size]
shl cx, 1
mov si, 0

.erase_loop:
mov di, [sanke + si]
mov ax, 0x3320
mov [es:di], ax
add si, 2
cmp si, cx
jl .erase_loop

mov cx, [snk_size]
dec cx
shl cx, 1
mov si, cx

.shift_loop:
cmp si, 0
je .done_shift
mov ax, [sanke + si - 2]
mov [sanke + si], ax
sub si, 2
jmp .shift_loop

.done_shift:
mov [sanke], bx

mov cx, [snk_size]
shl cx, 1
mov si, 0

.draw_snake_loop:
mov di, [sanke + si]
cmp si, 0
jne .not_head
mov ax, 0x4F3A
jmp .write_char

.not_head:
mov ax, 0x0000

.write_char:
mov [es:di], ax
add si, 2
cmp si, cx
jl .draw_snake_loop

pop di
pop si
pop dx
pop cx
pop bx
pop ax
ret


apple:  ; apple generate
pushad

try_again:
mov ah, 00h
int 1Ah
mov ax, dx
xor dx, dx
mov cx, 21
div cx
add dl, 3          
mov bl, dl

mov ah, 00h
int 1Ah
mov ax, dx
xor dx, dx
mov cx, 38
div cx
add dl, 1
mov bh, dl

movzx ax, bl
mov cx, 160
mul cx
mov si, ax        

movzx ax, bh
shl ax, 1         
add si, ax

mov [apple_pos], si

mov ax, 0xB800
mov es, ax
mov di, si
mov ax, 0xB04F
mov [es:di], ax
popad
ret



check:  ; game end checks (collisions)
push ax
push bx
push dx
push cx
push si
push di

mov ax, 0x0C2A
mov dx, ax
mov ax, 0x1F2D
mov bx, 0x1F7C

cmp [es:di], ax     ;left border
je end_game

cmp [es:di], bx    ; right border
je end_game

cmp word [es:di], 0x0000  ; self collision
je end_game

cmp di, [apple_pos]
je growt
jmp skip

end_game:
call game_over_screen


growt:    ; snake growth
mov cx, [snk_size]
inc cx
mov [snk_size], cx
inc word [score]
call update_score
dec cx
shl cx, 1
mov si, cx

.grow_shift_loop:
cmp si, 0
je .done_shift
mov ax, [sanke + si - 2]
mov [sanke + si], ax
sub si, 2
jmp .grow_shift_loop

.done_shift:
mov [sanke], di

mov cx, [snk_size]
shl cx, 1
mov si, 0

.grow_draw_loop:
mov di, [sanke + si]
cmp si, 0
jne .not_head
mov ax, 0x2C38
jmp .write_char

.not_head:
mov ax, 0x0A2A ; snake body

.write_char:
mov [es:di], ax
add si, 2
cmp si, cx
jl .grow_draw_loop

call apple

skip:
pop di
pop si
pop cx
pop dx
pop bx
pop ax
ret


start:   ; start basically main of the code
call making_board
call apple
call move_snake


print_string:   
    push ax
    push bx
.next_char:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x04
    mov [es:bx], ax
    add bx, 2
    jmp .next_char
.done:
    pop bx
    pop ax
    ret


print_number:    ; printinf for end screen score
    push ax
    push bx
    push cx
    push dx
    push si

    xor cx, cx         

.next_digit:
    xor dx, dx
    mov si, 10
    div si             
    push dx             
    inc cx
    test ax, ax
    jnz .next_digit

.print_loop:
    pop dx
    add dl, '0'
    mov dh, 0x07
    mov [es:bx], dx
    add bx, 2
    loop .print_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


game_over_screen:             ; game over screen
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov ax, 0x0720        
    mov cx, 2000
    rep stosw             


    mov si, game_over_msg
    mov bx, 160 * 10 + 30 * 2
    call print_string

    mov si, score_msg
    mov bx, 160 * 12 + 30 * 2
    call print_string

    mov ax, [score]        
    mov bx, 160 * 12 + 38 * 2
    call print_number

    mov si, rq_msg
    mov bx, 160 * 14 + 25 * 2
    call print_string

.wait_input:
    mov ah, 0
    int 16h
    cmp al, 'R'
    je restart_game
    cmp al, 'r'
    je restart_game
    cmp al, 'Q'
    je quit_game
    cmp al, 'q'
    je quit_game
    jmp .wait_input

game_over_text_loop:
    lodsb
    cmp al, '$'
    je game_over_done
    mov ah, 0x1F
    mov [es:di], ax
    add di, 2
    jmp game_over_text_loop
	
game_over_done:
    mov di, 180          
    call print_score

    mov si, 'Restart or Quit? (R/Q)$'
    mov di, 220          
restart_quit_prompt:
    lodsb
    cmp al, '$'
    je get_restart_quit_input
    mov ah, 0x1F
    mov [es:di], ax
    add di, 2
    jmp restart_quit_prompt

get_restart_quit_input:
    mov ah, 01h          
    int 16h
    jz get_restart_quit_input   

    mov ah, 00h
    int 16h              

    cmp al, 'R'          
    je restart_game
    cmp al, 'Q'           
    je quit_game
    jmp get_restart_quit_input    

restart_game:
    mov word [score], 0
    mov word [snk_size], 1
    mov byte [last_direction], 'R'

    mov cx, 200        
    mov si, sanke
	
clear_snake_loop:
    mov word [si], 0
    add si, 2
    loop clear_snake_loop

    call making_board
    call update_score
    call apple
    call move_snake

quit_game:
    mov ax, 0x4C00        
    int 0x21
