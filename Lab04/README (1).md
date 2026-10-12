# Lab 4 — The Packet Loop (Branching & Looping)

**Name:** Chase McWhorter  
**Date:** 10/10/26

## Required Experiment

**In TODO 5, why does JLE instead of JBE still pass, and what battery value (in hex) would expose the bug?**

`JLE` compares signed numbers, while `JBE` compares unsigned numbers. The bug does not show up in tonight's data because every battery reading is loaded with `MOVZX` from a 16-bit field, so its 32-bit value is always between 0 and 65535. All these values are positive as signed 32-bit numbers, too. In this exact program, no possible 16-bit battery value can expose the bug. If battery readings were instead full 32-bit values, `80000000h` would expose it: signed comparison treats that value as negative, but unsigned comparison treats it as greater than 0.

## README Questions

### 1. Why does minTemp start at 7FFFFFFFh instead of 0? What goes wrong with 0 on tonight's data?

`7FFFFFFFh` is the largest signed 32-bit integer. Starting there makes sure the first valid temperature becomes the new minimum. Starting at 0 would be wrong if all the temperatures were positive, because the minimum would stay 0 even though no packet had that temperature. On tonight's data, though, there are negative temperatures, including -73, so the final minimum would still be -73 even if it started at 0.

### 2. TODO 2 sums into AL — no AND 0FFh anywhere. Where is the mod-256?

`AL` is an 8-bit register, so it only keeps the lowest eight bits of the sum. Any carry past 255 is discarded automatically. That means adding into `AL` already gives the result modulo 256.

### 3. The outer loop uses INC/CMP/JL while the inner uses LOOP. Why would using LOOP for both be dangerous?

`LOOP` uses `ECX` as its counter. The inner checksum loop sets `ECX` to 8 for each packet, which would overwrite the outer loop's counter if that loop also depended on `ECX`. Keeping the outer packet index in `EBX` and using `INC/CMP/JL` avoids that conflict.
