; =============================================================================
;  CISP 310 - Lab 4: The Packet Loop (Branching & Looping)     (STUDENT STARTER)
;  File: Lab04_PacketLoop.asm         Rover Telemetry Project, Part 4 of 10
;
;  THE STORY SO FAR: Eight packets came down last night. Two are corrupted.
;  Tonight you write the loop that checks every packet, rejects the bad
;  ones, and keeps statistics on the good ones.
;
;  THE ONE IDEA TONIGHT: signed and unsigned data use DIFFERENT jumps.
;      temperature (signed)  ->  JL  JLE  JG  JGE
;      battery (unsigned)    ->  JB  JBE  JA  JAE
;  CMP sets the flags; the jump you pick decides how to read them.
;
;  The loop skeleton is written for you. ESI points at the current packet,
;  EBX counts packets. You fill in six short gaps.
;
;  Author:            Chase McWhorter
;  Date:              10/10/2026
; =============================================================================

.686
.model flat, stdcall
option casemap:none
.stack 4096

includelib kernel32.lib
includelib msvcrt.lib
includelib legacy_stdio_definitions.lib

printf PROTO C :PTR SBYTE, :VARARG

; =====================================================================
;  SELF-CHECK HARNESS  (instructor-provided -- DO NOT EDIT)
;  You will learn how MACROs work in Chapter 6. Until then all you
;  need to know: mCHECK compares one of your results with the expected
;  value and prints PASS or FAIL.  It destroys EAX, ECX, EDX.
; =====================================================================
CheckEq  PROTO C :PTR BYTE, :DWORD, :DWORD
Summary  PROTO C

mCHECK MACRO nameText:REQ, actualMem:REQ, expectedVal:REQ
    LOCAL nm
    .data
nm  BYTE nameText, 0
    .code
    INVOKE CheckEq, ADDR nm, actualMem, expectedVal
ENDM

; =============================================================================
.data
;                SYNC  ID   FLAGS TEMlo TEMhi BATlo BAThi CHK
packets     BYTE 0A5h, 01h, 13h, 0F2h, 0FFh, 5Eh, 0Fh, 0E9h   ; 0  temp -14
            BYTE 0A5h, 02h, 21h, 0D7h, 00h,  04h, 10h, 4Dh    ; 1  temp 215
            BYTE 0A5h, 03h, 01h, 7Eh,  01h,  88h, 0Eh, 42h    ; 2  temp 382
            BYTE 0A5h, 04h, 15h, 0B7h, 0FFh, 0EAh, 0Bh, 97h   ; 3  temp -73
            BYTE 0A5h, 05h, 35h, 78h,  00h,  0AEh, 0Bh, 0F0h  ; 4  temp 120
            BYTE 5Ah,  06h, 01h, 00h,  00h,  68h,  10h, 0DCh  ; 5  BAD SYNC
            BYTE 0A5h, 07h, 09h, 0FFh, 00h,  28h,  0Fh, 16h   ; 6  BAD CHECKSUM
            BYTE 0A5h, 08h, 03h, 0C7h, 00h,  10h,  0Eh, 6Bh   ; 7  temp 199
NUM_PACKETS  EQU 8
PACKET_SIZE  EQU 8
SYNC_BYTE    EQU 0A5h
FLAG_LOWBATT EQU 04h              ; bit 2 of the FLAGS byte

; ---- Your results ----------------------------------------------------------
validCount   DWORD  0            ; -> 6
minTemp      SDWORD 7FFFFFFFh    ; -> -73   (start at "largest possible")
maxTemp      SDWORD 80000000h    ; -> 382   (start at "smallest possible")
maxBatt      DWORD  0            ; -> 4100
lowBattCount DWORD  0            ; -> 2

fmtTitle  BYTE "=== Lab 4: The Packet Loop ===",10,10,0
fmtOK     BYTE "packet %u: ok   temp=%4d  batt=%u",10,0
fmtRej    BYTE "packet %u: REJECTED",10,0
fmtStats  BYTE 10,"valid=%u  minTemp=%d  maxTemp=%d  maxBatt=%u  lowBatt=%u",10,10,0

; =============================================================================
.code
main PROC C USES ebx esi edi
    INVOKE printf, ADDR fmtTitle

    mov  esi, OFFSET packets      ; ESI -> current packet
    xor  ebx, ebx                 ; EBX = packet index 0..7

next_packet:
    ; -------------------------------------------------------------------
    ;  TODO 1: sync check. If the first byte is not SYNC_BYTE, reject.
    ;      cmp  BYTE PTR [esi], SYNC_BYTE
    ;      jne  reject
    ; -------------------------------------------------------------------
    cmp  BYTE PTR [esi], SYNC_BYTE
    jne  reject

    ; -------------------------------------------------------------------
    ;  TODO 2: checksum. Add all 8 bytes into AL; a good packet gives 0.
    ;  The loop is set up for you (EDI walks the bytes, ECX counts 8).
    ;  Inside the loop, two lines:
    ;      add  al, BYTE PTR [edi]
    ;      inc  edi
    ;  After the loop:  test al, al  /  jnz reject   (given)
    ; -------------------------------------------------------------------
    xor  eax, eax
    mov  edi, esi
    mov  ecx, PACKET_SIZE
sum_loop:
    add  al, BYTE PTR [edi]
    inc  edi
    loop sum_loop
    test al, al
    jnz  reject

    ; ---- packet is valid (given) ----------------------------------------
    inc  validCount
    movsx eax, WORD PTR [esi+3]   ; EAX = temperature (signed)
    movzx edx, WORD PTR [esi+5]   ; EDX = battery (unsigned)
    INVOKE printf, ADDR fmtOK, ebx, eax, edx
    movsx eax, WORD PTR [esi+3]   ; reload - printf destroyed EAX/EDX
    movzx edx, WORD PTR [esi+5]

    ; -------------------------------------------------------------------
    ;  TODO 3: new minimum temperature? EAX is SIGNED, so use JGE:
    ;      cmp  eax, minTemp
    ;      jge  not_min            ; not smaller -> skip the store
    ;      mov  minTemp, eax
    ; -------------------------------------------------------------------
    cmp  eax, minTemp
    jge  not_min
    mov  minTemp, eax
not_min:

    ; -------------------------------------------------------------------
    ;  TODO 4: new maximum temperature? Same shape, signed, JLE this time.
    ; -------------------------------------------------------------------
    cmp  eax, maxTemp
    jle  not_max
    mov  maxTemp, eax
not_max:

    ; -------------------------------------------------------------------
    ;  TODO 5: new maximum battery? EDX is UNSIGNED, so use JBE:
    ;      cmp  edx, maxBatt
    ;      jbe  not_maxb
    ;      mov  maxBatt, edx
    ;  (Try JLE here on purpose later - it happens to work on tonight's
    ;   data. Write in your README why that is a dormant bug.)
    ; -------------------------------------------------------------------
    cmp  edx, maxBatt
    jbe  not_maxb
    mov  maxBatt, edx
not_maxb:

    ; -------------------------------------------------------------------
    ;  TODO 6: is the LOW_BATT flag set? TEST looks at a bit without
    ;  changing anything:
    ;      test BYTE PTR [esi+2], FLAG_LOWBATT
    ;      jz   advance            ; bit clear -> nothing to count
    ;      inc  lowBattCount
    ; -------------------------------------------------------------------
    test BYTE PTR [esi+2], FLAG_LOWBATT
    jz   advance
    inc  lowBattCount
    jmp  advance

reject:
    INVOKE printf, ADDR fmtRej, ebx

advance:                          ; (given) move to the next packet
    add  esi, PACKET_SIZE
    inc  ebx
    cmp  ebx, NUM_PACKETS
    jl   next_packet

    INVOKE printf, ADDR fmtStats, validCount, minTemp, maxTemp, maxBatt, lowBattCount

    ; =====================================================================
    ;  SELF-CHECK (do not edit)
    ; =====================================================================
    mCHECK <"validCount">,   validCount,   6
    mCHECK <"minTemp">,      minTemp,      -73
    mCHECK <"maxTemp">,      maxTemp,      382
    mCHECK <"maxBatt">,      maxBatt,      4100
    mCHECK <"lowBattCount">, lowBattCount, 2
    INVOKE Summary

    xor  eax, eax
    ret
main ENDP

; =====================================================================
;  Self-check implementation (DO NOT EDIT below this line)
; =====================================================================
.data
chkTotal  DWORD 0
chkFail   DWORD 0
fmtPass   BYTE "  PASS   %-22s  got %d (0x%08X)", 10, 0
fmtFail   BYTE "* FAIL   %-22s  got %d (0x%08X), expected %d (0x%08X)", 10, 0
fmtAllOk  BYTE 10, ">>> ALL %d CHECKS PASSED -- lab complete!", 10, 0
fmtBad    BYTE 10, ">>> %d of %d checks failing -- keep going.", 10, 0

.code
CheckEq PROC C pName:PTR BYTE, actualVal:DWORD, expectVal:DWORD
    inc  chkTotal
    mov  eax, actualVal
    cmp  eax, expectVal
    jne  ce_fail
    INVOKE printf, ADDR fmtPass, pName, eax, eax
    ret
ce_fail:
    inc  chkFail
    INVOKE printf, ADDR fmtFail, pName, eax, eax, expectVal, expectVal
    ret
CheckEq ENDP

Summary PROC C
    mov  eax, chkFail
    test eax, eax
    jnz  sm_bad
    INVOKE printf, ADDR fmtAllOk, chkTotal
    ret
sm_bad:
    INVOKE printf, ADDR fmtBad, chkFail, chkTotal
    ret
Summary ENDP

END
