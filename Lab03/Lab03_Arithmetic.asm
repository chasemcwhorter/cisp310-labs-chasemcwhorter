; =============================================================================
;  CISP 310 - Lab 3: Engineering Units (Integer Arithmetic)   (STUDENT STARTER)
;  File: Lab03_Arithmetic.asm         Rover Telemetry Project, Part 3 of 10
;
;  THE STORY SO FAR: Lab 2 pulled raw numbers out of the packet: temperature
;  -14 (tenths of a degree) and battery 3934 (millivolts). Mission control
;  wants "-1.4 C" and "3 V 934 mV". Tonight: multiply and divide.
;
;  THE ONE RITUAL TONIGHT - division needs a two-register setup:
;      signed:    cdq            then  idiv ebx    (CDQ sign-extends EAX into EDX)
;      unsigned:  xor edx, edx   then  div  ebx    (EDX must be zero)
;  After either one:  quotient in EAX, remainder in EDX.
;  The divisor must be in a register (you cannot write "idiv 10").
;
;  Author:            Chase McWhorter
;  Date:              9-27-2026
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
tempRaw   SDWORD -14             ; tenths of a degree C (from Lab 2)
battRaw   DWORD  3934            ; millivolts           (from Lab 2)

; ---- Your results ----------------------------------------------------------
tempWhole SDWORD 0CCCCCCCCh      ; TODO 1  -> -1   (the part before the point)
tempFrac  SDWORD 0CCCCCCCCh      ; TODO 1  -> -4   (the remainder, as IDIV gives it)
battV     DWORD  0CCCCCCCCh      ; TODO 2  -> 3    (whole volts)
battRem   DWORD  0CCCCCCCCh      ; TODO 2  -> 934  (leftover millivolts)
tempF10   SDWORD 0CCCCCCCCh      ; TODO 3  -> 295  (Fahrenheit, tenths)

fmtTitle  BYTE "=== Lab 3: Engineering Units ===",10,10,0
fmtTemp   BYTE "temperature : %d tenths  =  %d.%d C  (fraction sign fixed later)",10,0
fmtBatt   BYTE "battery     : %u mV      =  %u V %u mV",10,0
fmtF      BYTE "fahrenheit  : %d tenths  =  %d.%d F",10,0
fmtDemo   BYTE 10,"demo (given): 300000 * 20000 = %d ?!  overflow flag = %u",10,10,0

; =============================================================================
.code
main PROC C USES ebx esi edi
    INVOKE printf, ADDR fmtTitle

    ; -------------------------------------------------------------------
    ;  TODO 1: split -14 tenths into a whole part and a fraction digit.
    ;  Divide EAX by 10 the SIGNED way. The first and last lines are
    ;  given; you write the two-instruction ritual in between.
    ;      mov  eax, tempRaw       (given)
    ;      mov  ebx, 10            (given - divisor in a register)
    ;      cdq                     <- you
    ;      idiv ebx                <- you
    ;      mov  tempWhole, eax     (given)  quotient  = -1
    ;      mov  tempFrac,  edx     (given)  remainder = -4
    ;  Expected: -1 and -4. (Yes, -4: x86 truncates toward zero and the
    ;  remainder keeps the sign of the dividend. -1*10 + -4 = -14.)
    ; -------------------------------------------------------------------
    mov  eax, tempRaw
    mov  ebx, 10

    ; Sign-extend EAX into EDX because TEMP is a signed value.
    cdq
    idiv ebx

    mov  tempWhole, eax
    mov  tempFrac,  edx
    INVOKE printf, ADDR fmtTemp, tempRaw, tempWhole, tempFrac

    ; -------------------------------------------------------------------
    ;  TODO 2: split 3934 mV into volts and leftover millivolts. This is
    ;  UNSIGNED division by 1000: clear EDX, then DIV.
    ;      mov  eax, battRaw       (given)
    ;      mov  ebx, 1000          (given)
    ;      xor  edx, edx           <- you
    ;      div  ebx                <- you
    ;      mov  battV,   eax       (given)  -> 3
    ;      mov  battRem, edx       (given)  -> 934
    ; -------------------------------------------------------------------
    mov  eax, battRaw
    mov  ebx, 1000

    ; Battery is unsigned, so clear the high half of the dividend.
    xor  edx, edx
    div  ebx

    mov  battV,   eax
    mov  battRem, edx
    INVOKE printf, ADDR fmtBatt, battRaw, battV, battRem

    ; -------------------------------------------------------------------
    ;  TODO 3: Fahrenheit in tenths:  F10 = tempRaw * 9 / 5 + 320
    ;  MULTIPLY FIRST, then divide (dividing first throws away precision).
    ;      mov  eax, tempRaw       (given)
    ;      imul eax, 9             <- you   (-126)
    ;      mov  ebx, 5             <- you
    ;      cdq                     <- you
    ;      idiv ebx                <- you   (-25, remainder ignored)
    ;      add  eax, 320           <- you   (295 = 29.5 F)
    ;      mov  tempF10, eax       (given)
    ; -------------------------------------------------------------------
    mov  eax, tempRaw

    ; Multiply before dividing so integer division does not lose precision.
    imul eax, 9
    mov  ebx, 5
    cdq
    idiv ebx
    add  eax, 320

    mov  tempF10, eax

    mov  eax, tempF10
    mov  ebx, 10
    cdq
    idiv ebx                      ; given: split for display only
    INVOKE printf, ADDR fmtF, tempF10, eax, edx

    ; ---- DEMO (given): overflow is SILENT ------------------------------
    ;  300000 * 20000 = 6,000,000,000 - too big for 32 bits. IMUL keeps
    ;  the low 32 bits and just raises the Overflow Flag. SETO copies that
    ;  flag into a register so we can print it. Nobody stops you unless you
    ;  look. (Ariane 5, flight 501: an unchecked overflow destroyed the
    ;  rocket 37 seconds after launch.)
    mov  eax, 300000
    imul eax, 20000
    mov  ebx, 0
    seto bl
    INVOKE printf, ADDR fmtDemo, eax, ebx

    ; =====================================================================
    ;  SELF-CHECK (do not edit)
    ; =====================================================================
    mCHECK <"tempWhole">, tempWhole, -1
    mCHECK <"tempFrac">,  tempFrac,  -4
    mCHECK <"battV">,     battV,     3
    mCHECK <"battRem">,   battRem,   934
    mCHECK <"tempF10">,   tempF10,   295
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