; =============================================================================
;  CISP 310 - Lab 1: First Contact (Data Representation)      (STUDENT STARTER)
;  File: Lab01_FirstContact.asm       Rover Telemetry Project, Part 1 of 10
;
;  MISSION BRIEF: The FLC-1 rover has landed, and its first telemetry packet
;  just arrived - eight raw bytes. Before we let the CPU decode packets
;  (that starts in Lab 2), YOU decode this one by hand, because a computer
;  architect who cannot read hex is a pilot who cannot read a compass.
;
;       offset:   0     1     2      3      4      5      6     7
;       field :   SYNC  ID    FLAGS  TEMlo  TEMhi  BATlo  BAThi CHK
;       bytes :   A5    01    13     F2     FF     5E     0F    E9
;
;   - TEMP is bytes 3..4, LITTLE-ENDIAN (low byte first!), a SIGNED 16-bit
;     two's complement number, in tenths of a degree Celsius.
;   - BATT is bytes 5..6, little-endian, UNSIGNED, in millivolts.
;
;  Author:            Chase McWhorter
;  Date:              9/13/26
;
;  HOW THIS LAB WORKS: Answer the six TODOs by EDITING DATA, not code. Build
;  and run (Ctrl+F5). The provided checker prints PASS/FAIL for each answer.
;  The starter builds and runs as-is - you start at 0/6 and climb to 6/6.
;
;  VS PROJECT CHECKLIST (Lab 1 uses the Week-1 template):
;   [1] Platform = x86      [2] Build Customizations: masm checked
;   [3] .asm Item Type = Microsoft Macro Assembler
;   [4] Linker > System > SubSystem = Console
;   [5] Linker > Advanced > Entry Point = main   (Lab 1 only; Lab 2 changes this)
; =============================================================================

.686
.model flat, stdcall
option casemap:none
.stack 4096

; Win32 API contracts (Lab 2's harness will use printf; tonight, raw Win32)
GetStdHandle PROTO :DWORD
WriteFile    PROTO :DWORD, :PTR BYTE, :DWORD, :PTR DWORD, :DWORD
ExitProcess  PROTO :DWORD
STD_OUTPUT_HANDLE EQU -11

.data
; =============================================================================
;  YOUR SIX ANSWERS - edit the values, keep the names and sizes.
; =============================================================================

; TODO 1: The SYNC byte is A5 hex. Write it in BINARY (a 1010...b literal).
;         Work it out a nibble at a time: A = 1010, 5 = 0101.
ansSyncBin   BYTE  10100101b             ; <- your binary literal here (ends in b)

; TODO 2: The FLAGS byte is 00010011 binary. Write it in HEX (ends in h,
;         and a leading 0 if it starts with a letter: 0xxh).
ansFlagsHex  BYTE  13h                   ; <- your hex literal here (ends in h,

; TODO 3: The ID byte is 01 hex. Write it in plain DECIMAL.
ansIdDec     BYTE  1                    ; <- your decimal number here

; TODO 4: TEMP arrives as byte 3 = F2, byte 4 = FF, LITTLE-ENDIAN.
;         Assemble the 16-bit WORD (hex, 4 digits): which byte is on top?
ansTempWord  WORD  0FFF2h               ; <- your 4-digit hex WORD here

; TODO 5: That WORD is SIGNED two's complement. Decode it to decimal by
;         hand (invert the bits, add 1, negate) and write the value here.
;         Sanity check: the rover is a little chilly, not on fire.
ansTempDec   SWORD -14                  ; <- your (negative?) decimal here

; TODO 6: BATT arrives as byte 5 = 5E, byte 6 = 0F, little-endian UNSIGNED.
;         Assemble the word and convert to decimal millivolts by hand:
;         (thousands) 16^3 digit x 4096 + ... or split it 0F * 256 + 5E.
ansBattDec   WORD  3934                 ; <- your decimal millivolts here

; TODO 7 (no checker): put your name in the greeting.
msgHello     BYTE  "FLC-1 ground station operator: <YOUR NAME HERE>", 13, 10
MSG_LEN      EQU   ($ - msgHello)

; =============================================================================
;  Provided checker data (do not edit below this line)
; =============================================================================
expSyncBin   BYTE  0A5h
expFlagsHex  BYTE  13h
expIdDec     BYTE  1
expTempWord  WORD  0FFF2h
expTempDec   SWORD -14
expBattDec   WORD  3934

name1        BYTE  "check 1  sync as binary ....... ", 0
name2        BYTE  "check 2  flags as hex ......... ", 0
name3        BYTE  "check 3  id as decimal ........ ", 0
name4        BYTE  "check 4  temp word (endian) ... ", 0
name5        BYTE  "check 5  temp decoded (signed)  ", 0
name6        BYTE  "check 6  battery decoded ...... ", 0
NAME_LEN     EQU   32
sPass        BYTE  "PASS", 13, 10
sFail        BYTE  "FAIL", 13, 10
RESULT_LEN   EQU   6
msgDone      BYTE  13, 10, "Fix any FAIL lines, rebuild, rerun. 6/6 = done.", 13, 10
DONE_LEN     EQU   ($ - msgDone)

hStdOut      DWORD ?
bytesWritten DWORD ?

.code
; ---------------------------------------------------------------------------
;  Provided checker (uses ideas from Chapters 5-6 - revisit it in Week 7
;  and it will read like plain English). EAX = your value, EBX = expected,
;  ESI = name string.
; ---------------------------------------------------------------------------
Chk PROC
    cmp  eax, ebx                   ; decide BEFORE calling WriteFile -
    mov  edi, OFFSET sPass          ; API calls are allowed to change EAX
    je   chk_have
    mov  edi, OFFSET sFail
chk_have:
    INVOKE WriteFile, hStdOut, esi, NAME_LEN, ADDR bytesWritten, 0
    INVOKE WriteFile, hStdOut, edi, RESULT_LEN, ADDR bytesWritten, 0
    ret
Chk ENDP

main PROC
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov  hStdOut, eax

    INVOKE WriteFile, hStdOut, ADDR msgHello, MSG_LEN, ADDR bytesWritten, 0

    movzx eax, ansSyncBin
    movzx ebx, expSyncBin
    mov  esi, OFFSET name1
    call Chk

    movzx eax, ansFlagsHex
    movzx ebx, expFlagsHex
    mov  esi, OFFSET name2
    call Chk

    movzx eax, ansIdDec
    movzx ebx, expIdDec
    mov  esi, OFFSET name3
    call Chk

    movzx eax, ansTempWord
    movzx ebx, expTempWord
    mov  esi, OFFSET name4
    call Chk

    movsx eax, ansTempDec
    movsx ebx, expTempDec
    mov  esi, OFFSET name5
    call Chk

    movzx eax, ansBattDec
    movzx ebx, expBattDec
    mov  esi, OFFSET name6
    call Chk

    INVOKE WriteFile, hStdOut, ADDR msgDone, DONE_LEN, ADDR bytesWritten, 0
    INVOKE ExitProcess, 0
main ENDP

END main
