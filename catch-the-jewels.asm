[org 0x100]

jmp start
message1: db 'Computer Organization and Assembly Language (COAL)'
length1: dw 50
message2: db 'The Project - CATCH THE JEWELS'
length2: dw 30
message3: db 'Submitted to: Ms. Aleena Ahmad'
length3: dw 30
message4: db 'Submitted by: Waleed Imran (21L-5195) & Ahsan Javed (21L-1815)'
length4: dw 62
line: db '--------------------- CATCHING THE BOMB WILL END THE GAME ----------------------'
lineLenght: dw 80
message5: db 'Press ENTER to play!'
length5: dw 20
finalMessage: db 'GAME OVER!'
finalMessageLength: dw 10
finalScoreMessage: db 'Your SCORE = '
finalScoreMessageLength: dw 13
currentScoreMessage: db 'SCORE='
currentScoreMessageLength: dw 6
timeLeft: db 'Time='
timeLeftLength: dw 5
great: db 'GREAT!'
space: db '      '
itr5: dw -1
itr10: dw -5
itr15: dw -7
itrB: dw -2
horiz1: dw 16
horiz2: dw 32
horiz3: dw 48
horiz4: dw 64
horiz: dw 48, 64, 16, 32, 32, 48, 16, 64
selector: dw 0
credit: dw 0
vertBasket: dw 34
; display a tick count while the left shift key is down 
seconds: dw 0 
timerflag: dw 0 
oldkb: dd 0 
clockseconds:dw 0
clockminutes:dw 0
chkseconds:dw 18
chkminutes:dw 60
string1:db':'
lengthstring1:dw 1
string2:db' '
lengthstring2:dw 1
string3:db'00'
lengthstring3:dw 2
count5: dw 0
count10: dw 0
count15: dw 0


printstrtime:
    push bp 
    mov bp, sp 
    push es 
    push ax 
    push cx 
    push si 
    push di

    mov ax, 0xb800 
    mov es, ax ; point es to video base

    mov di,[bp+10]
    mov si, [bp+6] ; point si to string 
    mov cx, [bp+4] ; load length of string in cx 
    mov ah, [bp+8]
    cld ; auto increment mode 
    nextchar:
        lodsb ; load next char in al 
        stosw ; print char/attribute pair 
        loop nextchar ; repeat for the whole string

    pop di 
    pop si 
    pop cx 
    pop ax 
    pop es 
    pop bp 
    ret 8

printnum:
    push bp 
    mov bp, sp 
    push es 
    push ax 
    push bx 
    push cx 
    push dx 
    push di 

    mov ax, 0xb800 
    mov es, ax ; point es to video base 

    mov ax, [bp+6] ; load number in ax
    mov bx, 10 ; use base 10 for division 
    mov cx, 0 ; initialize count of digits 
    nextdigit:
        mov dx, 0 ; zero upper half of dividend 
        div bx ; divide by 10 
        add dl, 0x30 ; convert digit into ascii value 
        push dx ; save ascii value on stack 
        inc cx ; increment count of values 
        cmp ax, 0 ; is the quotient zero 
        jnz nextdigit ; if no divide it again 
    mov di, [bp+8] ; point di to 70th column 
    nextpos:
        pop dx ; remove a digit from the stack 
        mov dh, 0x07 ; use normal attribute 
        mov [es:di], dx ; print char on screen 
        add di, 2 ; move to next screen location 
        loop nextpos ; repeat for all digits on stack

    pop di 
    pop dx 
    pop cx 
    pop bx 
    pop ax
    pop es 
    pop bp 
    ret 2

; keyboard interrupt service routine 
kbisr:
    push ax 
    in al, 0x60     ; read a character from keyboard port
    cmp al, 0x4b    ; scan code for left arrow key
    jne checkOther
    cmp word[vertBasket], 1
    jz checkOther
    ; removing the bsket at previuos location
    mov ax, 22   ; rows
    push ax
    mov ax, word[vertBasket]   ; columns
    push ax
    call removeBasket
    dec word[vertBasket]    ; moving the basket right
    mov ax, 22   ; rows
    push ax
    mov ax, word[vertBasket]   ; columns
    push ax
    call basket
    checkOther:
    cmp al, 0x4d    ; scan code for right arrow key
    jne moveForward
    cmp word[vertBasket], 70
    jz moveForward
    ; removing the bsket at previuos location
    mov ax, 22   ; rows
    push ax
    mov ax, word[vertBasket]   ; columns
    push ax
    call removeBasket
    inc word[vertBasket]    ; moving the basket left
    mov ax, 22   ; rows
    push ax
    mov ax, word[vertBasket]   ; columns
    push ax
    call basket
    moveForward:
    cmp word [cs:timerflag], 1; is the flag already set 
    je exit ; yes, leave the ISR 
    mov word [cs:timerflag], 1; set flag to start printing 
    jmp exit ; leave the ISR 
    exit: mov al, 0x20
    out 0x20, al ; send EOI to PIC 
    pop ax
    iret ; return from interrupt

; timer interrupt service routine
timer:
    push ax
    mov di,4000
    push di
    cmp word [cs:timerflag], 1 ; is the printing flag set 
    jne skipall ; no, leave the ISR 
    inc word [cs:seconds] ; increment tick count 
    push word [cs:seconds]
    mov dx,[cs:seconds]
    push dx
    cmp dx,[cs:chkseconds]
    jne chk
    call incseconds
    chk:
        call printnum
        pop dx
    skipall:
        mov al, 0x20 
        out 0x20, al ; send EOI to PIC 
    pop di
    pop ax
    iret ; return from interrupt
 
incseconds:
    push cx
    mov cx,18
    increment:
        inc word[cs:chkseconds]
        loop increment
    push ax
    mov di,18
    push di
    inc word[cs:clockseconds]
    push word[cs:clockseconds]
    mov dx,[cs:clockseconds]
    push dx
    cmp dx,60
    jne chk2
    call incsminutes
    chk2:
        call printnum
    pop dx
    pop di
    pop ax
    pop cx
    ret

incsminutes:
    push ax
    sub word[cs:clockseconds],60
    push cx
    push ax
    mov di,14
    push di
    inc word[cs:clockminutes]
    push word[cs:clockminutes]
    mov dx,[cs:clockminutes]
    push dx
    cmp dx,2
    jne chkend
    call end
    jmp far[endcheck]
    chkend:
        call printnum
    pop dx
    pop di
    pop ax
    pop cx
    pop ax
    ret

clrscr:
    push es
    push di
    push ax

    mov ax, 0xb800
    mov es, ax
    mov di, 0
    nextChar:
        mov word[es:di], 0x0720
        add di ,2
        cmp di, 4000
        jnz nextChar
    
    pop ax
    pop di
    pop es
    ret

five:
    push bp
    mov bp, sp
    push es
    push di
    push ax
    push cx

    mov ax, 0xb800
    mov es, ax

    mov ax, 80
    mul word[bp+6]      ; rows
    add ax, [bp+4]      ; columns
    shl ax, 1
    mov di, ax
    mov ah, 0x02  ; attribute
    mov al, '-'
    mov cx, 5
    cld
    rep stosw
    add di, 150
    mov al, '|'
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, '5'
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, '|'
    mov [es:di], ax
    add di, 152
    mov al, '-'
    mov cx, 5
    rep stosw

    pop cx
    pop ax
    pop di
    pop es
    pop bp
    ret 4

removeFive:
    push bp
    mov bp, sp
    push es
    push di
    push ax
    push cx

    mov ax, 0xb800
    mov es, ax

    mov ax, 80
    mul word[bp+6]      ; rows
    add ax, [bp+4]      ; columns
    shl ax, 1
    mov di, ax
    mov ah, 0x02  ; attribute
    mov al, ' '
    mov cx, 5
    cld
    rep stosw
    add di, 150
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 152
    mov al, ' '
    mov cx, 5
    rep stosw

    pop cx
    pop ax
    pop di
    pop es
    pop bp
    ret 4

ten:
    push bp
    mov bp, sp
    push es
    push di
    push ax
    push cx

    mov ax, 0xb800
    mov es, ax

    mov ax, 80
    mul word[bp+6]      ; rows
    add ax, [bp+4]      ; columns
    shl ax, 1
    mov di, ax
    mov ah, 0x03  ; attribute
    mov al, '-'
    mov cx, 6
    cld
    rep stosw
    add di, 148
    mov al, '|'
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, '1'
    mov [es:di], ax
    add di, 2
    mov al, '0'
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, '|'
    mov [es:di], ax
    add di, 150
    mov al, '-'
    mov cx, 6
    rep stosw

    pop cx
    pop ax
    pop di
    pop es
    pop bp
    ret 4

removeTen:
    push bp
    mov bp, sp
    push es
    push di
    push ax
    push cx

    mov ax, 0xb800
    mov es, ax

    mov ax, 80
    mul word[bp+6]      ; rows
    add ax, [bp+4]      ; columns
    shl ax, 1
    mov di, ax
    mov ah, 0x03  ; attribute
    mov al, ' '
    mov cx, 6
    cld
    rep stosw
    add di, 148
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 150
    mov al, ' '
    mov cx, 6
    rep stosw

    pop cx
    pop ax
    pop di
    pop es
    pop bp
    ret 4

fifteen:
    push bp
    mov bp, sp
    push es
    push di
    push ax
    push cx

    mov ax, 0xb800
    mov es, ax

    mov ax, 80
    mul word[bp+6]      ; rows
    add ax, [bp+4]      ; columns
    shl ax, 1
    mov di, ax
    mov ah, 0x06  ; attribute
    mov al, '-'
    mov cx, 6
    cld
    rep stosw
    add di, 148
    mov al, '|'
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, '1'
    mov [es:di], ax
    add di, 2
    mov al, '5'
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, '|'
    mov [es:di], ax
    add di, 150
    mov al, '-'
    mov cx, 6
    rep stosw

    pop cx
    pop ax
    pop di
    pop es
    pop bp
    ret 4

removeFifteen:
    push bp
    mov bp, sp
    push es
    push di
    push ax
    push cx

    mov ax, 0xb800
    mov es, ax

    mov ax, 80
    mul word[bp+6]      ; rows
    add ax, [bp+4]      ; columns
    shl ax, 1
    mov di, ax
    mov ah, 0x06  ; attribute
    mov al, ' '
    mov cx, 6
    cld
    rep stosw
    add di, 148
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 150
    mov al, ' '
    mov cx, 6
    rep stosw

    pop cx
    pop ax
    pop di
    pop es
    pop bp
    ret 4

bomb:
    push bp
    mov bp, sp
    push es
    push di
    push ax
    push cx

    mov ax, 0xb800
    mov es, ax

    mov ax, 80
    mul word[bp+6]      ; rows
    add ax, [bp+4]      ; columns
    shl ax, 1
    mov di, ax
    mov ah, 0000000000000100b  ; attribute
    mov al, '*'
    mov cx, 3
    cld
    rep stosw
    add di, 154
    mov al, ')'
    mov [es:di], ax
    add di, 2
    mov al, '*'
    mov [es:di], ax
    add di, 2
    mov al, '('
    mov [es:di], ax
    add di, 156
    mov al, '*'
    mov cx, 3
    rep stosw

    pop cx
    pop ax
    pop di
    pop es
    pop bp
    ret 4

removeBomb:
    push bp
    mov bp, sp
    push es
    push di
    push ax
    push cx

    mov ax, 0xb800
    mov es, ax

    mov ax, 80
    mul word[bp+6]      ; rows
    add ax, [bp+4]      ; columns
    shl ax, 1
    mov di, ax
    mov ah, 0000000000000100b  ; attribute
    mov al, ' '
    mov cx, 3
    cld
    rep stosw
    add di, 154
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov [es:di], ax
    add di, 156
    mov al, ' '
    mov cx, 3
    rep stosw

    pop cx
    pop ax
    pop di
    pop es
    pop bp
    ret 4

basket:
    push bp
    mov bp, sp
    push es
    push di
    push ax
    push cx

    mov ax, 0xb800
    mov es, ax

    mov ax, 80
    mul word[bp+6]      ; rows
    add ax, [bp+4]      ; columns
    shl ax, 1
    mov di, ax
    mov ah, 0000000000001101b  ; attribute
    mov al, '|'
    mov [es:di], ax
    add di, 16
    mov [es:di], ax
    add di, 144
    mov al, '\'
    mov [es:di], ax
    add di, 2
    mov al, '_'
    mov cx, 7
    rep stosw
    mov al, '/'
    mov [es:di], ax

    pop cx
    pop ax
    pop di
    pop es
    pop bp
    ret 4

removeBasket:
    push bp
    mov bp, sp
    push es
    push di
    push ax
    push cx

    mov ax, 0xb800
    mov es, ax

    mov ax, 80
    mul word[bp+6]      ; rows
    add ax, [bp+4]      ; columns
    shl ax, 1
    mov di, ax
    mov ah, 0000000000001101b  ; attribute
    mov al, ' '
    mov [es:di], ax
    add di, 16
    mov [es:di], ax
    add di, 144
    mov al, ' '
    mov [es:di], ax
    add di, 2
    mov al, ' '
    mov cx, 7
    rep stosw
    mov al, ' '
    mov [es:di], ax

    pop cx
    pop ax
    pop di
    pop es
    pop bp
    ret 4

printString:
    push bp
    mov bp, sp
    push es
    push di
    push si
    push ax
    push bx
    push cx
    push dx

    mov ax, 0xb800
    mov es, ax

    mov si, [bp+12]   ; message
    mov cx, [bp+10]    ; length
    mov ax, [bp+8]    ; loading row
    mov dl, 80
    mul dl            ; multuply ax by 80
    add ax, [bp+6]    ; adding column
    shl ax, 1         ; multiply by 2
    mov di, ax
    mov bh, [bp+4]    ; loading attribute
    next:
        mov bl, [si]
        mov [es:di], bx
        add di, 2
        inc si
        loop next

    pop dx
    pop cx
    pop bx
    pop ax
    pop si
    pop di
    pop es
    pop bp
    ret 10

delay:
    push cx
    push dx
        mov cx, 15
        mov dx, 15
        l2:
            l1:
                dec dx
                jnz l1
            dec cx
            jnz l2
    pop dx
    pop cx
    ret

notificationDelay:
    push cx
    push dx
        mov cx, 10
        mov dx, 10
        l2n:
            l1n:
                dec dx
                jnz l1n
            dec cx
            jnz l2n
    pop dx
    pop cx
    ret

end:
    mov word[cs:timerflag], 0
    call clrscr
    mov ax, finalMessage
    push ax
    push word[finalMessageLength]
    mov ax, 4
    push ax ; row
    mov ax, 34
    push ax ; column
    push word 0000000010001101b ; attribute
    call printString

    mov ax, 7   ; rows
    push ax
    mov ax, 33   ; columns
    push ax
    call five
    push word[count5]
    mov ax, 1368
    push ax
    call printScore

    mov ax, 11   ; rows
    push ax
    mov ax, 33   ; columns
    push ax
    call ten
    push word[count10]
    mov ax, 2008
    push ax
    call printScore

    mov ax, 15   ; rows
    push ax
    mov ax, 33   ; columns
    push ax
    call fifteen
    push word[count15]
    mov ax, 2648
    push ax
    call printScore

    mov ax, finalScoreMessage
    push ax
    push word[finalScoreMessageLength]
    mov ax, 20
    push ax ; row
    mov ax, 30
    push ax ; column
    push word 0x07 ; attribute
    call printString

    push word[credit]
    mov ax, 3292
    push ax
    call printScore
    ret

startscreen:
    mov ax, message1
    push ax
    push word[length1]
    mov ax, 2
    push ax ; row
    mov ax, 14
    push ax ; column
    push word 0x07 ; attribute
    call printString

    mov ax, message2
    push ax
    push word[length2]
    mov ax, 4
    push ax ; row
    mov ax, 24
    push ax ; column
    push word 0000000000001101b ; attribute
    call printString

    mov ax, message3
    push ax
    push word[length3]
    mov ax, 6
    push ax ; row
    mov ax, 24
    push ax ; column
    push word 0x07 ; attribute
    call printString

    mov ax, message4
    push ax
    push word[length4]
    mov ax, 8
    push ax ; row
    mov ax, 9
    push ax ; column
    push word 0x07 ; attribute
    call printString

    mov ax, line
    push ax
    push word[lineLenght]
    mov ax, 10
    push ax ; row
    mov ax, 0
    push ax ; column
    push word 0x07 ; attribute
    call printString

    mov ax, 14   ; rows
    push ax
    mov ax, 11  ; columns
    push ax
    call five

    mov ax, 14   ; rows
    push ax
    mov ax, 24  ; columns
    push ax
    call ten

    mov ax, 14   ; rows
    push ax
    mov ax, 38  ; columns
    push ax
    call fifteen

    mov ax, 14   ; rows
    push ax
    mov ax, 51  ; columns
    push ax
    call basket

    mov ax, 14   ; rows
    push ax
    mov ax, 67  ; columns
    push ax
    call bomb

    mov ax, line
    push ax
    push word[lineLenght]
    mov ax, 20
    push ax ; row
    mov ax, 0
    push ax ; column
    push word 0x07 ; attribute
    call printString

    mov ax, message5
    push ax
    push word[length5]
    mov ax, 22
    push ax ; row
    mov ax, 29
    push ax ; column
    push word 0000000010001101b ; attribute
    call printString
    ret

checkenter:
    push ax
    loop1:
        mov ah,0
        int 0x16
        cmp al,13
        jnz loop1
    pop ax
    ret

printScore:
    push bp
    mov bp, sp
    push es
    push di
    push ax
    push bx
    push cx
    push dx

    mov ax, 0xb800
    mov es, ax

    mov ax, [bp+6]
    mov bx, 10
    mov cx, 0
    nextDigit:
        mov dx, 0
        div bx  ; remainder in dx
        add dx, 0x30
        push dx
        inc cx
        cmp ax, 0
        jnz nextDigit
    mov di, [bp+4]
    nextPos:
        pop dx
        mov dh, 0x07
        mov [es:di], dx
        add di, 2
        loop nextPos

    pop dx
    pop cx
    pop bx
    pop ax
    pop di
    pop es
    pop bp
    ret 4

removeNotification:
    push ax
    push bx
    push cx
    push dx
    call notificationDelay
    mov ax, space
    push ax
    mov ax, 6
    push ax
    mov ax, 12
    push ax ; row
    mov ax, 37
    push ax ; column
    push word 0x07 ; attribute
    call printString
    pop dx
    pop cx
    pop bx
    pop ax
    ret

scored:
    push ax
    push bx
    push cx
    push dx
    mov ax, great
    push ax
    mov ax, 6
    push ax
    mov ax, 12
    push ax ; row
    mov ax, 37
    push ax ; column
    push word 0000000000001010b ; attribute
    call printString
    call removeNotification
    pop dx
    pop cx
    pop bx
    pop ax
    ret


start:
    call clrscr
    call startscreen
    call checkenter
    call clrscr

    ; Game screen......................................................................................
    mov ax, currentScoreMessage
    push ax
    push word[currentScoreMessageLength]
    mov ax, 0
    push ax
    mov ax, 70
    push ax
    push word 0x07 ; attribute
    call printString

    mov ax, timeLeft
    push ax
    push word[timeLeftLength]
    mov ax, 0
    push ax
    mov ax, 0
    push ax
    push word 0x07 ; attribute
    call printString

    mov ax,16
    push ax
    mov ax,0x07
    push ax
    mov ax,string1
    push ax
    push word[lengthstring1]
    call printstrtime

    mov ax,12
    push ax
    mov ax,0x07
    push ax
    mov ax,string3
    push ax
    push word[lengthstring3]
    call printstrtime

    xor ax, ax 
    mov es, ax ; point es to IVT base 
    mov ax, [es:9*4] 
    mov [oldkb], ax ; save offset of old routine 
    mov ax, [es:9*4+2] 
    mov [oldkb+2], ax ; save segment of old routine 
    cli ; disable interrupts 
    mov word [es:9*4], kbisr ; store offset at n*4 
    mov [es:9*4+2], cs ; store segment at n*4+2 
    mov word [es:8*4], timer ; store offset at n*4 
    mov [es:8*4+2], cs ; store segment at n*4+ 
    sti ; enable interrupts 
    mov dx, start ; end of resident portion
    add dx, 15 ; round up to next para
    mov cl, 4
    shr dx, cl ; number of paras
    mov ax,0x3100

    infinity:
        mov ecx, 2

        ; checking CATCH
        cmp word[itr5], 21
        jnz noCredit1
        mov dx, word[vertBasket]
        add dx, 1
        cmp dx, word[horiz3]
        jz got5
        add dx, 1
        cmp dx, word[horiz3]
        jz got5
        add dx, 1
        cmp dx, word[horiz3]
        jz got5
        add dx, 1
        cmp dx, word[horiz3]
        jz got5
        add dx, 1
        cmp dx, word[horiz3]
        jz got5
        jnz noCredit1
        got5:
        add word[credit], 5
        push word[credit]
        mov ax, 154
        push ax
        call printScore
        call scored
        inc word[count5]
        mov word[itr5], -1
        mov bx, word[selector]
        mov dx, word[horiz+bx]
        add word[selector], 2
        cmp word[selector], 16
        mov word[horiz3], dx
        jnz noCredit1
        mov word[selector], 0       ; reseting the selector

        noCredit1:
        cmp word[itr10], 21
        jnz noCredit2
        mov dx, word[vertBasket]
        add dx, 1
        cmp dx, word[horiz4]
        jz got10
        add dx, 1
        cmp dx, word[horiz4]
        jz got10
        add dx, 1
        cmp dx, word[horiz4]
        jz got10
        add dx, 1
        cmp dx, word[horiz4]
        jz got10
        add dx, 1
        cmp dx, word[horiz4]
        jnz noCredit2
        got10:
        add word[credit], 10
        push word[credit]
        mov ax, 154
        push ax
        call printScore
        call scored
        inc word[count10]
        mov word[itr10], -5
        mov bx, word[selector]
        mov dx, word[horiz+bx]
        add word[selector], 2
        cmp word[selector], 16
        mov word[horiz4], dx
        jnz noCredit2
        mov word[selector], 0       ; reseting the selector

        noCredit2:
        cmp word[itr15], 21
        jnz noCredit3
        mov dx, word[vertBasket]
        add dx, 1
        cmp dx, word[horiz1]
        jz got15
        add dx, 1
        cmp dx, word[horiz1]
        jz got15
        add dx, 1
        cmp dx, word[horiz1]
        jz got15
        add dx, 1
        cmp dx, word[horiz1]
        jz got15
        add dx, 1
        cmp dx, word[horiz1]
        jnz noCredit3
        got15:
        add word[credit], 15
        push word[credit]
        mov ax, 154
        push ax
        call printScore
        call scored
        inc word[count15]
        mov word[itr15], -7
        mov bx, word[selector]
        mov dx, word[horiz+bx]
        add word[selector], 2
        cmp word[selector], 16
        mov word[horiz1], dx
        jnz noCredit3
        mov word[selector], 0       ; reseting the selector

        noCredit3:
        cmp word[itrB], 21
        jnz noCredit4
        mov dx, word[vertBasket]
        add dx, 1
        cmp dx, word[horiz2]
        jz gotB
        add dx, 1
        cmp dx, word[horiz2]
        jz gotB
        add dx, 1
        cmp dx, word[horiz2]
        jz gotB
        add dx, 1
        cmp dx, word[horiz2]
        jz gotB
        add dx, 1
        cmp dx, word[horiz2]
        jnz noCredit4
        gotB:
        call end
        call endcheck

        noCredit4:
        mov ax, 22   ; rows
        push ax
        mov ax, word[vertBasket]   ; columns
        push ax
        call basket

        mov ax, word[itr5]   ; rows
        push ax
        mov ax, word[horiz3]   ; columns
        push ax
        call five

        mov ax, word[itr10]   ; rows
        push ax
        mov ax, word[horiz4]   ; columns
        push ax
        call ten

        mov ax, word[itr15]   ; rows
        push ax
        mov ax, word[horiz1]   ; columns
        push ax
        call fifteen

        mov ax, word[itrB]   ; rows
        push ax
        mov ax, word[horiz2]   ; columns
        push ax
        call bomb

        call delay

        mov ax, word[itr5]   ; rows
        push ax
        mov ax, word[horiz3]   ; columns
        push ax
        call removeFive

        mov ax, word[itr10]   ; rows
        push ax
        mov ax, word[horiz4]   ; columns
        push ax
        call removeTen

        mov ax, word[itr15]   ; rows
        push ax
        mov ax, word[horiz1]   ; columns
        push ax
        call removeFifteen

        mov ax, word[itrB]   ; rows
        push ax
        mov ax, word[horiz2]   ; columns
        push ax
        call removeBomb

        inc word[itr5]
        inc word[itr10]
        inc word[itr15]
        inc word[itrB]

        cmp word[itr5], 24
        jnz skip1
        mov word[itr5], -1
        mov bx, word[selector]
        mov dx, word[horiz+bx]
        add word[selector], 2
        cmp word[selector], 16
        mov word[horiz3], dx
        jnz skip1
        mov word[selector], 0       ; reseting the selector
    
        skip1:
        cmp word[itr10], 24
        jnz skip2
        mov word[itr10], -5
        mov bx, word[selector]
        mov dx, word[horiz+bx]
        add word[selector], 2
        cmp word[selector], 16
        mov word[horiz4], dx
        jnz skip2
        mov word[selector], 0       ; reseting the selector
        
        skip2:
        cmp word[itr15], 24
        jnz skip3
        mov word[itr15], -7
        mov bx, word[selector]
        mov dx, word[horiz+bx]
        add word[selector], 2
        cmp word[selector], 16
        mov word[horiz1], dx
        jnz skip3
        mov word[selector], 0       ; reseting the selector

        skip3:
        cmp word[itrB], 24
        jnz skip4
        mov word[itrB], -2
        mov bx, word[selector]
        mov dx, word[horiz+bx]
        add word[selector], 2
        cmp word[selector], 16
        mov word[horiz2], dx
        jnz skip4
        mov word[selector], 0       ; reseting the selector

        skip4:
        dec ecx
        jnz infinity

    endcheck:
        mov ax,0x3100
mov ax,0x4c00
int 0x21