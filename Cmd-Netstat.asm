;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                           SymbOS network daemon                            @
;@                               N E T S T A T                                @
;@                                                                            @
;@               (c) 2015 by Prodatron / SymbiosiS (Jörn Mika)                @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


;### PRGPRZ -> Programm-Prozess
prgprz  call SyShell_PARALL     ;get commandline parameters
        call SyShell_PARSHL     ;fetch shell-specific parameters
        jp c,prgend
        call SyNet_NETINI               ;***** INIT NETWORK API (SEARCH FOR THE DAEMON)
        ld hl,nettxtdmn
        jr c,prgend0            ;no daemon found -> error
        call netstt
        jr prgend

;### PRGEND -> Programm beenden
prgend0 ld e,0
        call SyShell_STROUT
prgend  ld e,0
        call SyShell_EXIT       ;tell Shell, that process will quit
        ld hl,(App_BegCode+prgpstnum)
        call SySystem_PRGEND
prgend1 rst #30
        jr prgend1

;### NETSTT -> show netstats
netstt  ld hl,nettxttit
        call SyShell_STROUT0
        ;...                            ;***** GET TOTAL NUMBER OF SOCKETS
        xor a
        ld c,4
        ld hl,netsckdat
        call SyNet_CFGSCK               ;***** GET SOCKET DATA
        ld b,4
        ld ix,netsckdat
netstt1 ld a,(ix+0)
        cp 1
        ld hl,nettxtpr0
        jr z,netstt2
        cp 2
        ld hl,nettxtpr1
        jp nz,netstt9
netstt2 push bc
        push ix
        ld de,nettxtlin+2       ;protocol
        ld bc,3
        ldir
        ld hl,nettxtlin+19
        ld de,nettxtlin+20
        ld c,46
        ld (hl)," "
        ldir
        ld l,(ix+4)             ;local port
        ld h,(ix+5)
        ld iy,nettxtlin+19
        push ix
        call clcn16
        pop ix
        ld a,(ix+0)
        cp 1
        ld a,(ix+2)
        jr nz,netstt8
        or a
        jr z,netstt6            ;tcp listen -> skip remote
        jr netstt7
netstt8 bit 4,a
        jr z,netstt6            ;udp open -> skip remote
netstt7 ld hl,nettxtlin+32      ;remote ip
        ld e,"."
        ld a,(ix+7):call clcn08:ld (hl),e:inc hl
        ld a,(ix+6):call clcn08:ld (hl),e:inc hl
        ld a,(ix+9):call clcn08:ld (hl),e:inc hl
        ld a,(ix+8):call clcn08:ld (hl),":":inc hl
        push hl:pop iy
        ld l,(ix+10)            ;remote port
        ld h,(ix+11)
        push ix
        call clcn16
        pop ix
netstt6 ld a,(ix+0)
        cp 1
        ld a,(ix+2)
        jr nz,netstt4
        res 7,a                 ;tcp status
        add a
        ld c,a
        ld b,0
        ld hl,nettxtstt
        add hl,bc
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
netstt3 ld de,nettxtlin+55
        ld bc,12
        ldir
        jr netstt5
netstt4 bit 4,a                 ;udp status
        ld hl,nettxtsta
        jr z,netstt3
        ld hl,nettxtstb
        jr netstt3
netstt5 ld hl,nettxtlin         ;print line
        call SyShell_STROUT0
        pop ix
        pop bc
netstt9 ld de,16
        add ix,de
        dec b
        jp nz,netstt1
        ld hl,nettxtlfd
        call SyShell_STROUT0
        ret


netsckdat   ds 16*4

nettxtdmn   db "Network daemon not running!",13,10,0

nettxttit   db 13,10,"Active Connections",13,10,13,10
            db "  Proto  Local Address          Foreign Address        State",13,10,0
nettxtlin   db "  XXX    localhost:XXXXX        XXX.XXX.XXX.XXX:XXXXX  XXXXXXXXXXX ",13,10,0

nettxtpr0   db "TCP"
nettxtpr1   db "UDP"

nettxtstt   dw nettxtst0,nettxtst1,nettxtst2,nettxtst3,nettxtst4
nettxtst0   db "LISTEN      "
nettxtst1   db "SYN_SEND    "
nettxtst2   db "ESTABLISHED "
nettxtst3   db "CLOSE_WAIT  "
nettxtst4   db "CLOSED      "

nettxtsta   db "OPEN        "
nettxtstb   db "SENDING     "

nettxtlfd   db 13,10,0


;==============================================================================
;### SUB ROUTINES #############################################################
;==============================================================================

;### CLCN08 -> Converst 8bit value into ASCII string (not terminated)
;### Input      A=Value, HL=Destination
;### Output     HL=points behind last digit
;### Destroyed  AF,BC
clcn08  cp 10
        jr c,clcn082
        cp 100
        jr c,clcn081
        ld c,100
        call clcn083
clcn081 ld c,10
        call clcn083
clcn082 add "0"
        ld (hl),a
        inc hl
        ret
clcn083 ld b,"0"-1
clcn084 sub c
        inc b
        jr nc,clcn084
        add c
        ld (hl),b
        inc hl
        ret

;### CLCN16 ->  Converst 16bit value into ASCII string (not terminated)
;### Input      HL=Value, IY=Destination
;### Output     (IY)=points on last digit
;### Veraendert AF,BC,DE,HL,IX
clcn16t dw -10,-100,-1000,-10000
clcn16  ld b,4          ;1
        ld ix,clcn16t+6 ;4
        xor a           ;1
clcn161 ld e,(ix+0)     ;5
        ld d,(ix+1)     ;5
        dec ix          ;3
        dec ix          ;3
        ld c,"0"        ;2
clcn162 add hl,de       ;3
        jr nc,clcn165   ;3/2
        inc c           ;1
        inc a           ;1
        jr clcn162      ;3
clcn165 sbc hl,de       ;4
        or a            ;1
        jr z,clcn163    ;3/2
        ld (iy+0),c     ;5
        inc iy          ;3
clcn163 djnz clcn161    ;4/3
clcn164 ld a,"0"        ;2
        add l           ;1
        ld (iy+0),a     ;5
        ret



;==============================================================================
;### DATA AREA ################################################################
;==============================================================================

App_BegData

;### nothing (more) here
db 0

;==============================================================================
;### TRANSFER AREA ############################################################
;==============================================================================

App_BegTrns
;### PRGPRZS -> Stack for app process
            ds 64
prgstk      ds 6*2
            dw prgprz
App_PrcID   db 0
App_MsgBuf  ds 14
