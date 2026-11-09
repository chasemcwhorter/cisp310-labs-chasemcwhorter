; =============================================================================
;  CISP 310 - Lab 7: Flags, Masks & Shifts (Bit Manipulation)  (STUDENT STARTER)
;  File: Lab07_Bits.asm               Rover Telemetry Project, Part 7 of 10
;
;  THE STORY SO FAR: The FLAGS byte has ridden along since Lab 1. Tonight you
;  take it apart. One byte, eight switches:
;
;       bit 7..4 : MODE       (0=IDLE 1=DRIVE 2=SCIENCE 3=SAFE)
;       bit 3    : COMM_ERR
;       bit 2    : LOW_BATT
;       bit 1    : HEATER_ON
;       bit 0    : SENSORS_OK
;
;  THE THREE VERBS:   AND clears bits   OR sets bits   XOR flips bits
;  plus  TEST (look at a bit, change nothing)  and  SHL/SHR (slide bits).
;  Rule: a variable shift count must be in CL.  shl eax, cl   (not ebx!)
;
;  Author:            Chase McWhorter
;  Date:              November 8, 2026
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
packets     BYTE 0A5h, 01h, 13h, 0F2h, 0FFh, 5Eh, 0Fh, 0E9h   ; 0
            BYTE 0A5h, 02h, 21h, 0D7h, 00h,  04h, 10h, 4Dh    ; 1
            BYTE 0A5h, 03h, 01h, 7Eh,  01h,  88h, 0Eh, 42h    ; 2
            BYTE 0A5h, 04h, 15h, 0B7h, 0FFh, 0EAh, 0Bh, 97h   ; 3  LOW_BATT
            BYTE 0A5h, 05h, 35h, 78h,  00h,  0AEh, 0Bh, 0F0h  ; 4  LOW_BATT
            BYTE 5Ah,  06h, 01h, 00h,  00h,  68h,  10h, 0DCh  ; 5  bad sync
            BYTE 0A5h, 07h, 09h, 0FFh, 00h,  28h,  0Fh, 16h   ; 6  bad checksum
            BYTE 0A5h, 08h, 03h, 0C7h, 00h,  10h,  0Eh, 6Bh   ; 7
NUM_PACKETS  EQU 8
PACKET_SIZE  EQU 8
SYNC_BYTE    EQU 0A5h

FLAG_HEATER  EQU 02h
FLAG_LOWBATT EQU 04h

flags4      DWORD 35h            ; FLAGS byte of packet 4:  0011 0101

; ---- Your results ----------------------------------------------------------
mode4       DWORD 0CCCCCCCCh     ; TODO 1: mode field of flags4        -> 3
isLowBatt   DWORD 0CCCCCCCCh     ; TODO 2: LOW_BATT set in flags4?     -> 1
newFlags    DWORD 0CCCCCCCCh     ; TODO 3: flags4 after the command    -> 03h
lowBattMask DWORD 0CCCCCCCCh     ; TODO 4: one bit per packet          -> 18h
popCount    DWORD 0CCCCCCCCh     ; TODO 5: how many bits set in 18h    -> 2

fmtTitle    BYTE "=== Lab 7: Flags, Masks & Shifts ===",10,10,0
fmtF4       BYTE "flags4=0x%02X  mode=%u  lowBatt=%u  after command: 0x%02X",10,0
fmtMask     BYTE "low-battery bitmap: 0x%02X  (%u packets)",10,0
fmtDemo     BYTE 10,"demo (given): 6*8 by SHL = %u    -14 SAR 1 = %d    -14 SHR 1 = %u",10,10,0

; =============================================================================
.code

; ---- IsValidQ (GIVEN: your Lab 6 Pkt_IsValid) ------------------------------
IsValidQ PROC USES ecx edx, pPkt:PTR BYTE
    mov  edx, pPkt
    cmp  BYTE PTR [edx], SYNC_BYTE
    jne  ivq_bad
    xor  eax, eax
    mov  ecx, PACKET_SIZE
ivq_sum:
    add  al, BYTE PTR [edx]
    inc  edx
    loop ivq_sum
    test al, al
    jnz  ivq_bad
    mov  eax, 1
    ret
ivq_bad:
    xor  eax, eax
    ret
IsValidQ ENDP

main PROC C USES ebx esi edi
    INVOKE printf, ADDR fmtTitle

    ; -------------------------------------------------------------------
    ;  TODO 1: the MODE lives in bits 7..4. Slide it down to bits 3..0:
    ;      mov  eax, flags4
    ;      shr  eax, 4
    ;      mov  mode4, eax          -> 3 (SAFE)
    ; -------------------------------------------------------------------
    mov  eax, flags4              ; load the flags before extracting the mode
    shr  eax, 4                   ; shift mode bits 7..4 down to bits 3..0
    mov  mode4, eax               ; save the extracted mode

    ; -------------------------------------------------------------------
    ;  TODO 2: is LOW_BATT set? TEST the bit, then capture the answer:
    ;      test flags4, FLAG_LOWBATT
    ;      mov  eax, 0              ; MOV does not touch the flags
    ;      setnz al                 ; AL = 1 if TEST found the bit
    ;      mov  isLowBatt, eax      -> 1
    ; -------------------------------------------------------------------
    test flags4, FLAG_LOWBATT     ; check bit 2 without modifying flags4
    mov  eax, 0                   ; MOV preserves ZF from TEST; also clears upper 24 bits
    setnz al                      ; AL = 1 when the low-battery bit was set
    mov  isLowBatt, eax           ; save the Boolean result

    ; -------------------------------------------------------------------
    ;  TODO 3: mission control sends a command for packet 4's flags.
    ;  Apply the three verbs, in order, starting with flags4 in EAX:
    ;      mov  eax, flags4
    ;      or   eax, FLAG_HEATER        ; turn the heater ON     (set)
    ;      and  eax, NOT FLAG_LOWBATT   ; clear the alarm        (clear)
    ;      xor  eax, 30h                ; SAFE(3) -> IDLE(0)     (flip)
    ;      mov  newFlags, eax           -> 03h
    ; -------------------------------------------------------------------
    mov  eax, flags4              ; begin with original FLAGS byte
    or   eax, FLAG_HEATER         ; force heater bit to 1
    and  eax, NOT FLAG_LOWBATT    ; inverted mask clears only the alarm bit
    xor  eax, 30h                 ; flip known mode 3 (SAFE) to 0 (IDLE)
    mov  newFlags, eax            ; save 03h without changing flags4
    INVOKE printf, ADDR fmtF4, flags4, mode4, isLowBatt, newFlags

    ; -------------------------------------------------------------------
    ;  TODO 4: a bitmap - bit i = 1 when packet i is valid AND has
    ;  LOW_BATT set. The loop is given; you write the "set bit i" part:
    ;      mov  eax, 1
    ;      mov  ecx, ebx            ; shift count must be in CL
    ;      shl  eax, cl             ; EAX = 1 << i
    ;      or   lowBattMask, eax
    ;  Expected 18h: packets 3 and 4 (bits 3 and 4).
    ; -------------------------------------------------------------------
    mov  lowBattMask, 0
    mov  esi, OFFSET packets
    xor  ebx, ebx                 ; EBX = packet index = bit number
mask_loop:
    INVOKE IsValidQ, esi
    test eax, eax
    jz   mask_next
    test BYTE PTR [esi+2], FLAG_LOWBATT
    jz   mask_next
    mov  eax, 1                   ; start with only bit 0 set
    mov  ecx, ebx                 ; variable shift counts must use CL
    shl  eax, cl                  ; move the 1 into packet index bit position
    or   lowBattMask, eax         ; keep existing alerts and add this packet
mask_next:
    add  esi, PACKET_SIZE
    inc  ebx
    cmp  ebx, NUM_PACKETS
    jl   mask_loop

    ; -------------------------------------------------------------------
    ;  TODO 5: population count - how many 1 bits in lowBattMask?
    ;  Each SHR drops one bit into the Carry Flag; ADC adds it to EBX.
    ;  The loop shell is given; you write the two-instruction body:
    ;      shr  eax, 1
    ;      adc  ebx, 0              ; EBX = EBX + 0 + carry
    ; -------------------------------------------------------------------
    mov  eax, lowBattMask
    xor  ebx, ebx
    mov  ecx, 32
pc_loop:
    shr  eax, 1                   ; move the next low bit into CF
    adc  ebx, 0                   ; count that bit by adding the carry
    loop pc_loop
    mov  popCount, ebx
    INVOKE printf, ADDR fmtMask, lowBattMask, popCount

    ; ---- DEMO (given): shifts are arithmetic --------------------------
    mov  eax, 6
    shl  eax, 3                   ; 6 * 8 = 48
    mov  ebx, -14
    sar  ebx, 1                   ; signed   /2 = -7
    mov  ecx, -14
    shr  ecx, 1                   ; UNSIGNED /2 = 2147483641 (sign bit lost!)
    INVOKE printf, ADDR fmtDemo, eax, ebx, ecx

    ; =====================================================================
    ;  SELF-CHECK (do not edit)
    ; =====================================================================
    mCHECK <"mode4">,       mode4,       3
    mCHECK <"isLowBatt">,   isLowBatt,   1
    mCHECK <"newFlags">,    newFlags,    03h
    mCHECK <"lowBattMask">, lowBattMask, 18h
    mCHECK <"popCount">,    popCount,    2
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
