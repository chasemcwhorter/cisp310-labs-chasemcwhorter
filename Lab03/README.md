# Lab 3 — Engineering Units

## Required Experiment

For TODO 1, I removed the `CDQ` instruction and ran the program.

Visual Studio stopped at the `IDIV` instruction and gave an unhandled exception:

`0xC0000095: Integer overflow.`

This happened because `CDQ` was not there to sign-extend EAX into EDX. Since `IDIV` uses the full EDX:EAX register pair as the dividend, EDX contained an incorrect value when the division happened.

After recording the result, I put the `CDQ` instruction back into the program.

## README Questions

### 1. What did the missing CDQ do, and why?

`CDQ` sign-extends the signed value in EAX into EDX so that EDX:EAX contains the correct signed dividend for `IDIV`.

When I removed `CDQ`, EDX was not set up correctly before `IDIV` ran. Because `IDIV` uses EDX:EAX as one combined dividend, the incorrect value in EDX caused the division to fail.

On my computer, Visual Studio stopped at the `IDIV` instruction and reported:

`0xC0000095: Integer overflow.`

### 2. Compute -14 / 5 * 9 + 320 in integer math in the wrong order.

Using integer math:

-14 / 5 = -2

-2 * 9 = -18

-18 + 320 = 302

The result is **302**, which represents **30.2 °F**.

The precision was lost during the first division. Mathematically, -14 / 5 is -2.8, but integer division truncates toward zero and keeps only -2. Once the .8 is removed, multiplying by 9 cannot recover it. This is why the correct program multiplies before dividing.

### 3. What are the low 32 bits of 6,000,000,000 in hex, and why doesn't the CPU stop the program?

The low 32 bits of 6,000,000,000 are:

`0x65A0BC00`

The multiplication result is too large to fit as a signed 32-bit integer. `IMUL` keeps the low 32 bits of the result and sets the overflow flag.

The CPU does not automatically stop the program because the overflow is reported through the processor's overflow flag. The program has to check that flag itself. In this lab, `SETO` copies the overflow flag into a register so the program can display it.
