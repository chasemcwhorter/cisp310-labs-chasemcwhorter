
# CISP 310 — Lab 7: Flags, Masks & Shifts

**Name:** Chase McWhorter  
**Date:** November 8, 2026

## Question 1 — Why TODO 1 Does Not Need an AND

**a. Low 8 bits of EAX:**

- Before `shr eax, 4`: `0011 0101` (`35h`)
- After `shr eax, 4`:  `0000 0011` (`03h`)

**b.** The original mode bits `0011`, which were in bits 7–4, move into bits 3–0 after shifting right four places. The original lower four bits fall off the right side. Because `SHR` shifts in zeros on the left, bits 31–4 are all zero afterward. An `AND 0F0h` before the shift is unnecessary.

## Question 2 — Forcing the Mode to SCIENCE (2)

**a.** A single `XOR` instruction cannot force the mode to 2 for every starting mode because XOR only toggles selected bits. Different starting modes would produce different results.

**b. Instructions:**

```asm
and eax, 0Fh     ; Clear all four mode bits while preserving bits 3..0
or  eax, 20h     ; Set mode to 0010 (SCIENCE) in bits 7..4
```

The desired upper nibble is `0010` (`20h`). These instructions keep the lower nibble unchanged, regardless of the starting mode.

For example, starting with `35h` (`0011 0101`):

```text
Original:     0011 0101  (35h)
After AND:    0000 0101  (05h)
After OR:     0010 0101  (25h)
```

## Question 3 — Why SHR Gives a Large Positive Number

The 32-bit two's-complement representation of `-14` is `1111 1111 1111 1111 1111 1111 1111 0010`. `SHR` shifts every bit right and inserts a zero on the left, so the result becomes `0111 1111 1111 1111 1111 1111 1111 1001`, or `2147483641`. The `SAR` instruction is used for signed arithmetic shifts because it copies the sign bit instead of inserting zero, so `sar` of `-14` by one produces `-7`.

## Required Experiment — ADC vs. ADD (from the original lab handout)

**Predicted result when replacing `adc ebx, 0` with `add ebx, 0`:** `popCount = 0`, instead of `2`.

`SHR` moves each bit that falls off into the Carry Flag (CF). `ADC` includes that carry in the count, so it adds 1 for each set bit. `ADD ebx, 0` ignores the Carry Flag and therefore leaves the count at zero. The final submitted assembly code should use `adc ebx, 0` so the check passes.

*Experiment note: This is the expected result from the code. Verify it by running the temporary ADD version, then restore ADC.*
