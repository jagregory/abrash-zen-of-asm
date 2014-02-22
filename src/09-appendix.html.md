# APPENDIX A: 8086/8088 Instruction Set Reference

*Adapted from "Assembly Language from Square One," by Jeff Duntemann (Scott, Foresman and Company, 1989), by permission of the author.*

The following is a summary of the 8088's instruction set, with valid instruction forms, execution times, sizes, and examples given for each instruction. A short summary of each instruction is provided as well. This is not a complete reference on the 8088's instruction set; rather, it is a quick reference summary that is particularly useful for calculating Execution Unit execution time and/or code size. This reference is also handy in that it lists all forms of each instruction, including the special, shorter forms that many instructions have.

References that provide more comprehensive information about the 8088's instruction set are listed below.

## Notes on the Instruction Set Reference

### Instruction Operands

When an instruction takes two operands, the destination operand is the operand on the *left*, and the source operand is the operand on the *right*. In general, when a result is produced by an instruction, the result replaces the destination operand. For example, in the instruction `add bx,si`, the BX register (the destination operand) is added to the SI register (the source operand), and the sum is then placed back in the BX register, overwriting whatever was in BX before the addition.

### Flag Results

Each instruction contains a flag summary that looks like this (the asterisks will vary from instruction to instruction):

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
| `*` |     |     |     | `*` | `*` | `*` | `*` | `*` | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |

The nine flags are all represented here. An asterisk indicates that the instruction on that page affects that flag. If a flag is affected at all (that is, if it has an asterisk beneath it) it will generally be affected according to these rules:

`OF:` Set if the result is too large to fit in the destination operand.

`DF:` Set by the `std` instruction; cleared by `cld`.

`IF:` Set by the `sti` and `int` instructions; cleared by `cli`.

`TF:` For debuggers; not used in normal programming and may be ignored.

`SF:` Set when the sign of the result is negative.

`ZF:` Set if the result of an operation is zero. If the result is non zero, ZF is cleared.

`AF:` "Auxiliary carry" used for 4bit BCD math. Set when an operation causes a carry out of a 4bit BCD quantity.

`PF:` Set if the number of 1 bits in the low byte of the result is even; cleared if the number of 1 bits in the low byte of the result is odd. Used in data communications applications but little else.

`CF:` Set if the result of an add or shift operation "carries out" a bit beyond the destination operand; otherwise cleared. May be manually set by `stc` and manually cleared by `clc` when CF must be in a known state before an operation begins.

In addition, all flags may be either set or cleared by `popf` and `iret`, and CF, PF, AF, ZF, and SF may be either set or cleared by `sahf`.

Some instructions force certain flags to become undefined. When this is the case for a given instruction, it will be so stated under "Notes.""Undefined" means *don't count on it being in any particular state*.

### Accounting for the Time Consumed by Memory Accesses

Each bytesized access to memory takes 4 cycles. That time is normally built into execution times; however, many instructions may work with either byte or wordsized memory operands. In such cases, *each* additional bytesized access to memory incurred by the use of wordsized operands adds four cycles to the instruction's official execution time. For example, `add ax,[si]` takes 4 cycles longer to execute than `add al,[si]`.

Some instructions access memory more than once. In such cases, 4 cycles are required for *each* extra access. So, for example, `add [si],ax`, takes not 4 but 8 cycles longer than `add [si],al`, because the wordsized memory operand pointed to by SI must be both read and written to. 8 and 16bit forms of various instructions are shown separately in this appendix, with the cycle times adjusted appropriately in the case of 16bit instructions, so you do not need to add any additional execution time for wordsized memory operands.

### These Are Only Execution Unit Execution Times

The execution times given below describe how many cycles each instruction takes to execute *once it has reached the Execution Unit*. This does not account for the time required to *reach* the Execution Unitthat is, the time required to fetch the instruction byte. Instruction fetch time for a given instruction can vary from no time at all to more than 4 cycles per byte, depending on how quickly the Execution Unit executes the preceding instructions, how often those instructions access memory, and how effectively the Bus Interface Unit can prefetch that instruction's bytes into the prefetch queue.

Overall execution time is a complex topic, to which Chapters 3, 4, and 5 are largely dedicated. Refer to those chapters for a detailed discussion of the topic. For the purposes of this appendix, simply understand that the execution times given here are Execution Unit execution times only, and so are only part of the overall execution picture.

### Effective Address Calculations

As described in Chapter 7, instructions that use *mod-reg-rm* memory operands require extra cycles, known as effective address calculation time, in order to calculate the address of the memory location being addressed. Effective address calculation time varies with the *mod-reg-rm* memory addressing mode selected, but does not depend on the instruction selected. In this appendix, effective address calculation time will be denoted as "+EA"; this will mean that the instruction takes the specified number of cycles *plus* the number of cycles required for effective address calculation by the selected addressing mode, as follows:

| Memory addressing mode      | Additional cycles required for EA calculation |
|-----------------------------|-----------------------------------------------|
| **Base**                    |                                               |
| \ \ `[bp]`{.nasm}           | 5 cycles                                      |
| \ \ `[bx]`{.nasm}           | 5 cycles                                      |
| **Index**                   |                                               |
| \ \ `[si]`{.nasm}           | 5 cycles                                      |
| \ \ `[di]`{.nasm}           | 5 cycles                                      |
| **Direct**                  |                                               |
| \ \ `[MemVar]`{.nasm}       | 6 cycles                                      |
| **Base+Index**              |                                               |
| \ \ `[bp+di]`{.nasm}        | 7 cycles                                      |
| \ \ `[bx+si]`{.nasm}        | 7 cycles                                      |
| **Base+Index**              |                                               |
| \ \ `[bx+di]`{.nasm}        | 8 cycles                                      |
| \ \ `[bp+si]`{.nasm}        | 8 cycles                                      |
| **Base+Displacement**       |                                               |
| \ \ `[bx+disp]`{.nasm}      | 9 cycles                                      |
| \ \ `[bp+disp]`{.nasm}      | 9 cycles                                      |
| **Index+Displacement**      |                                               |
| \ \ `[si+disp]`{.nasm}      | 9 cycles                                      |
| \ \ `[di+disp]`{.nasm}      | 9 cycles                                      |
| **Base+Index+Displacement** |                                               |
| \ \ `[bp+di+disp]`{.nasm}   | 11 cycles                                     |
| \ \ `[bx+si+disp]`{.nasm}   | 11 cycles                                     |
| **Base+Index+Displacement** |                                               |
| \ \ `[bx+di+disp]`{.nasm}   | 12 cycles                                     |
| \ \ `[bp+si+disp]`{.nasm}   | 12 cycles                                     |

For example, `mov bl,[si]` takes 13 cycles: 8 cycles for the execution of the basic instruction, and 5 cycles for effective address calculation.

Two additional cycles are required if a segment override prefix, as in `mov al,es:[di]`, is used.

If you want to know whether a given form of any instruction uses *mod-reg-rm* memory addressing, the rule is: if "+EA" appears in the "Cycles" field for that instruction form, *mod-reg-rm* memory addressing is used; if "+EA" does not appear, *mod-reg-rm* memory addressing is not used. There is no way to tell whether or not *mod-reg-rm* register addressing is used; the references listed below provide that information if you need it.

Note that segment override prefixes can be used on all *mod-reg-rm* memory accesses. Note also that all *mod-reg-rm* memory accesses default to accessing the segment pointed to by DS, except when BP is used to point to memory, in which case *mod-reg-rm* memory accesses default to accessing the segment pointed to by SS. Segment defaults used by non *mod-reg-rm* instructions are noted on a casebycase basis in this appendix, as are the cases in which segment override prefixes can and cannot be used.

### Instruction Forms Shown

This appendix shows the various forms of each instruction. This does *not* mean that all forms accepted by the assembler are shown. Rather, forms that assemble to different opcodes, with different size and/or performance characteristics, are shown.

For example, `xlat`, `xlat [mem8]`, and `xlatb` are all forms of `xlat` that the assembler accepts. However, since all three forms assemble to exactly the same instruction byte, I will only show one of the forms, `xlat`. On the other hand, `or [WordVar],1000h` and `or [ByteVar],10h`, which appear to be two instances of the same instruction, actually assemble to two different instruction opcodes, with different sizes and performance characteristics, so I will show those forms of `or` separately, as `or [mem16],immed16` and `or [mem8],immed8`, respectively.

Note that some wordsized immediate operands to some instructions can be stored as bytes and signextended to a word at execution time. This can be done with immediate operands in the range 128 to +127 (0FFh to 07Fh). This is a distinct instruction form and is shown separately. To continue the example above, `or [WordVar],10h` would be another form of `or`, denoted as `or [mem16],sextimmed`.

Finally, I haven't shown general forms of instructions that are always replaced by special shorter forms. For example, there's a *mod-reg-rm* form of `mov reg16,immed16` that's 4 bytes long. There's also a special form of the same instruction that's only 3 bytes long. The special form is superior, so MASM always assembles that form; there's no good reason to want the other form. The only way to get the long form is to hand assemble the desired instruction and then use `db` to create the instruction. Since it's almost certain that you'll never want to use long forms of instructions that have special short forms, to avoid confusion I've omitted the long forms. The references listed below can be used to look up the long forms if you so desire.

### Cycle Times

There is no definitive source for the execution times of 8088 instructions that I am aware of. Intel's documentation has a number of mistakes, and so do all other sources I know of. I have done my best to provide correct cycle times in this appendix. I have crossreferenced the cycle times from three sources: Intel's *iAPX 86,88 User's Manual* (Santa Clara, CA, 1981, available directly from Intel or in technical bookstores), the *Microsoft Macro Assembler 5.0 Reference* that comes with MASM 5.0, and *The 8088 Book* (by Rector and Alexy, Osborne/McGrawHill, Berkeley, CA 1980). I have corrected all documented cycle times that I know to be wrong, and I have checked dubious times with the Zen timer to the greatest possible extent.

Nonetheless, there is no certainty that all times listed here are correct; I have no magic insight into the innards of the 8088, and the Zen timer has its limitations in determining Execution Unit execution times. In any case, rarely is any reference totally free of errors. That's merely one more reason to follow the practice recommended throughout *The Zen of Assembler*: time your code. Even if all the cycle times in this chapter are correct, cycle times are only one part of overall execution time (instruction fetching, wait states, and the like also influence overall execution time)so you *must* time your code if you want to know how fast it really is.

By the way, 8086/80186/80286/80386/8087/80287/80387 cycle times are not given in this appendix. The abovementioned *Microsoft Macro Assembler 5.0 Reference* is an excellent cycletime reference for those processors.

### Instruction Sizes

Instruction sizes in bytes are given in this appendix. However, the size of a given form of a given instruction that uses *mod-reg-rm* memory addressing may vary, depending on whether 0, 1, or 2 displacement bytes are present. In such cases, instruction sizes are given as a maximum/minimum range; for example, `adc [mem16],immed16` may be anywhere from 4 to 6 bytes in size, depending on the displacement used. Both the *Microsoft Macro Assembler 5.0 Reference* and *The 8086 Book* are good references on exact instruction formats and sizes.

AAA ASCII adjust after addition
-------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `aaa` | 4      | 1     | `aaa` |


**Notes:**

Given the binary result of the addition of two decimal digits (that is, two values bits 30 of which are in the range 0 to 9; the value of bits 74 are ignored, facilitating addition of ASCII digits but allowing addition of unpacked BCD values as well) in AL, with the flags still set from the addition, `aaa` corrects that binary result to one decimal digit (unpacked BCD) in AL, and increments AH if the result of the previous addition was greater than 9.

OF, SF, ZF, and PF are left undefined by `aaa`. AF and CF are set to 1 if the result of the previous addition was greater than 9.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg`= CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


AAD ASCII adjust before division
--------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `aad` | 60     | 2     | `aad` |

**Notes:**

`aad` converts a twodigit unpacked BCD number stored in AX (with the most significant digit in AH) into a binary number in AX, by multiplying AH by 10 and adding it to 10, then zeroing AH. The name derives from the use of this instruction to convert a twodigit unpacked BCD value to a binary value in preparation for using that number as a dividend.

OF, AF, and CF are left undefined by `aad`. AH is always set to 0; the Sign flag is set on the basis of bit 7 of AL.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


AAM ASCII adjust after multiplication
-------------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `aam` | 83     | 2     | `aam` |

**Notes:**

`aam` converts a binary value in the range 0 to 99 stored in AL into a two digit unpacked BCD number in AX, with the most significant digit in AH, by dividing AL by 10 and storing the quotient in AH and the remainder in AL. The name derives from the use of this instruction to convert the binary result of the multiplication of two unpacked BCD values (two values in the range 0 to 9) to an unpacked BCD result.

OF, AF, and CF are left undefined by `aam`. ZF is set according to the contents of AL, not AX. SF is also set according to the contents of AL; practically speaking, however, SF is always set to 0, since the sign bit of AL is always 0 after `aam`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[``mem8``]` = 8bit memory data

`[``mem16``]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

AAS ASCII adjust after subtraction
----------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `aas` | 4      | 2     | `aas` |

**Notes:**

Given the binary result of the subtraction of two decimal digits (that is, two values bits 30 of which are in the range 0 to 9; the value of bits 74 are ignored, facilitating subtraction of ASCII digits but allowing addition of unpacked BCD values as well) in AL, with the flags still set from the subtraction, `aas` corrects that binary result to a decimal digit (unpacked BCD) in AL. Note that if the result of the subtraction was less than 0 (borrow occurred), AH is decremented by `aas`, and AF and CF are set to 1.

OF, SF, ZF, and PF are left undefined by `aas`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

ADC Arithmetic add with carry
-----------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                             | Cycles | Bytes  |                        |
|-----------------------------|--------|--------|------------------------|
| `adc` *reg8*,*reg8*         | 3      | 2      | `adc` al,bl            |
| `adc` [*mem8*],*reg8*       | 16+EA  | 2 to 4 | `adc` [bx],ch          |
| `adc` *reg8*,[*mem8*]       | 9+EA   | 2 to 4 | `adc` dl,[bx+si]       |
| `adc` *reg16*,*reg16*       | 3      | 2      | `adc` bx,di            |
| `adc` [*mem16*],*reg16*     | 24+EA  | 2 to 4 | `adc` [WordVar+2],cx   |
| `adc` *reg16*,[*mem16*]     | 13+EA  | 2 to 4 | `adc` si,[di]          |
| `adc` *reg8*,*immed8*       | 4      | 3      | `adc` ah,1             |
| `adc` [*mem8*],*immed8*     | 17+EA  | 3 to 5 | `adc` [ByteVar],10h    |
| `adc` *reg16*,*sextimmed*   | 4      | 3      | `adc` bx,7fh           |
| `adc` *reg16*,*immed16*     | 4      | 4      | `adc` dx,1000h         |
| `adc` [*mem16*],*sextimmed* | 25+EA  | 3 to 5 | `adc` [WordVar],0ffffh |
| `adc` [*mem16*],*immed16*   | 25+EA  | 4 to 6 | `adc` [WordVar],000ffh |
| `adc` al,*immed8*           | 4      | 2      | `adc` al,40h           |
| `adc` ax,*immed16*          | 4      | 3      | `adc` ax,8000h         |

**Notes:**

`adc` adds the source operand and the Carry flag to the destination operand; after the operation, the result replaces the destination operand. The add is an arithmetic add, and the carry allows multiple precision additions across several registers or memory locations. (To add without taking the Carry flag into account, use the `add` instruction.) All affected flags are set according to the operation. Most importantly, if the result does not fit into the destination operand, the Carry flag is set to 1.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

ADD Arithmetic add (ignore carry)
---------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                             | Cycles | Bytes  |                           |
|-----------------------------|--------|--------|---------------------------|
| `add` *reg8*,*reg8*         | 3      | 2      | `add` ah,al               |
| `add` [*mem8*],*reg8*       | 16EA   | 2 to 4 | `add` [bx1],dh            |
| `add` *reg8*,[*mem8*]       | 9EA    | 2 to 4 | `add` ch,[bx]             |
| `add` *reg16*,*reg16*       | 3      | 2      | `add` dx,ax               |
| `add` [*mem16*],*reg16*     | 24EA   | 2 to 4 | `add` [bp5],ax            |
| `add` *reg16*,[*mem16*]     | 13EA   | 2 to 4 | `add` ax,[Basedi]         |
| `add` *reg8*,*immed8*       | 4      | 3      | `add` dl,16               |
| `add` [*mem8*],*immed8*     | 17EA   | 3 to 5 | `add` byte ptr [si6],0c3h |
| `add` *reg16*,*sextimmed*   | 4      | 3      | `add` si,0ff80h           |
| `add` *reg16*,*immed16*     | 4      | 4      | `add` si,8000h            |
| `add` [*mem16*],*sextimmed* | 25EA   | 3 to 5 | `add` [WordVar],3         |
| `add` [*mem16*],*immed16*   | 25EA   | 4 to 6 | `add` [WordVar],300h      |
| `add` al,*immed8*           | 4      | 2      | `add` al,1                |
| `add` ax,*immed16*          | 4      | 3      | `add` ax,2                |

**Notes:**

`add` adds the source operand to the destination operand; after the operation the result replaces the destination operand. The add is an arithmetic add, and does *not* take the Carry flag into account. (To add using the Carry flag, use the `adc`add with carryinstruction.) All affected flags are set according to the operation. Most importantly, if the result does not fit into the destination operand, the Carry flag is set to 1.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16`= 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


AND Logical and
---------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                             | Cycles | Bytes  |                            |
|-----------------------------|--------|--------|----------------------------|
| `and` *reg8*,*reg8*         | 3      | 2      | `and` dl,dl                |
| `and` [*mem8*],*reg8*       | 16EA   | 2 to 4 | `and` [si1],dl             |
| `and` *reg8*,[*mem8*]       | 9EA    | 2 to 4 | `and` ah,[sibx]            |
| `and` *reg16*,*reg16*       | 3      | 2      | `and` si,bp                |
| `and` [*mem16*],*reg16*     | 24EA   | 2 to 4 | `and` [WordVar],dx         |
| `and` *reg16*,[*mem16*]     | 13EA   | 2 to 4 | `and` si,[WordVar2]        |
| `and` *reg8*,*immed8*       | 4      | 3      | `and` ah,07fh              |
| `and` [*mem8*],*immed8*     | 17EA   | 3 to 5 | `and` byte ptr [di],5      |
| `and` *reg16*,*sextimmed*   | 4      | 3      | `and` dx,1                 |
| `and` *reg16*,*immed16*     | 4      | 4      | `and` cx,0aaaah            |
| `and` [*mem16*],*sextimmed* | 25EA   | 3 to 5 | `and` word ptr [bx],80h    |
| `and` [*mem16*],*immed16*   | 25EA   | 4 to 6 | `and` word ptr [di],05555h |
| `and` al,*immed8*           | 4      | 2      | `and` al,0f0h              |
| `and` ax,*immed16*          | 4      | 3      | `and` ax,0ff00h            |

**Notes:**

`and` performs the logical operation "and" on its two operands. Once the operation is complete, the result replaces the destination operand. `and` is performed on a bitby bit basis, such that bit 0 of the source is anded with bit 0 of the destination, bit 1 of the source is anded with bit 1 of the destination, and so on. The "and" operation yields a 1 if *both* of the operands are 1, and a 0 if *either* operand is 0. Note that `and` makes the Auxiliary Carry flag undefined. CF and OF are cleared to 0, and the other affected flags are set according to the operation's results.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

CALL Call subroutine
--------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                         | Cycles | Bytes  |                            |
|-------------------------|--------|--------|----------------------------|
| `call` *disp16*         | 23     | 3      | `call` near ptr NearTarget |
| `call` *reg16*          | 20     | 2      | `call` bx                  |
| `call` [*mem16*]        | 29EA   | 2 to 4 | `call` word ptr [Vecssi]   |
| `call` *segment:offset* | 36     | 5      | `call` far ptr FarTarget   |
| `call` [*mem32*]        | 53EA   | 2 to 4 | `call` dword ptr [FarVec]  |

**Notes:**

`call` branches to the destination specified by the single operand; that is, `call` sets IP (and CS, for far jumps) so that the next instruction executed is at the specified location. If the call is a far call, `call` then pushes CS onto the stack; then, whether the call is far or near, `call` pushes the offset of the start of the next instruction onto the stack. The pushed address can later be used by `ret` to return from the called subroutine to the instruction after `call`.

In addition to branching directly to either near or far labels, `call` can branch anywhere in the segment pointed to by CS by setting IP equal to an offset stored in any generalpurpose register. `call` can also branch to an address (either near or far) stored in memory and accessed through any *mod-reg-rm* addressing mode; this is ideal for calling addresses stored in jump tables.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


CBW Convert signed byte in AL to signed word in AX
--------------------------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `cbw` | 2      | 1     | `cbw` |

**Notes:**

`cbw` signextends a signed byte in AL to a signed word in AX. In other words, bit 7 of AL is copied to all bits of AH.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


CLC Clear Carry flag
--------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `clc` | 2      | 1     | `clc` |

**Notes:**

`clc` clears the Carry flag (CF) to 0. Use `clc` in situations where the Carry flag *must* be in a known cleared state before work begins, as when you are rotating a series of words or bytes using `rcl` or `rcr`, or before performing multiword addition in a loop with `adc`. `clc` can also be useful for returning a status in the Carry flag from a subroutine, or for presetting the Carry flag before a conditional jump that tests the Carry flag, such as `jc`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


CLD Clear Direction flag
------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |  *  |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `cld` | 2      | 1     | `cld` |

**Notes:**

`cld` clears the Direction flag (DF) to 0. This affects the pointer register adjustments performed after each memory access by the string instructions `lods`, `stos`, `scas`, `movs`, and `cmps`. When DF=0, pointer registers (SI and/or DI) are incremented by 1 or 2; when DF=1, pointer registers are decremented by 1 or 2. DF is set to 1 by `std`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


CLI Clear Interrupt flag
------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |  *  |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `cli` | 2      | 1     | `cli` |

**Notes:**

`cli` clears the Interrupt flag (IF) to 0, disabling maskable hardware interrupts (IRQ0 through IRQ7) until IF is set to 1. (Software interrupts via `int` are not affected by the state of IF.) `sti` sets the Interrupt flag to 1, enabling maskable hardware interrupts.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


CMC Complement Carry flag
-------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `cmc` | 2      | 1     | `cmc` |

**Notes:**

`cmc` flips the state of the Carry flag (CF). If the Carry flag is 0, `cmc` sets it to 1; if the Carry flag is 1, `cmc` sets it to 0.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


CMP Compare by subtracting without saving result
------------------------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                             | Cycles | Bytes  |                       |
|-----------------------------|--------|--------|-----------------------|
| `cmp` *reg8*,*reg8*         | 3      | 2      | `cmp` ah,al           |
| `cmp` [*mem8*],*reg8*       | 9EA    | 2 to 4 | `cmp` [si],cl         |
| `cmp` *reg8*,[*mem8*]       | 9EA    | 2 to 4 | `cmp` ah,[bx]         |
| `cmp` *reg16*,*reg16*       | 3      | 2      | `cmp` dx,ax           |
| `cmp` [*mem16*],*reg16*     | 13EA   | 2 to 4 | `cmp` [bxdiRecPtr],bx |
| `cmp` *reg16*,[*mem16*]     | 13EA   | 2 to 4 | `cmp` bp,[bx1]        |
| `cmp` *reg8*,*immed8*       | 4      | 3      | `cmp` ah,9            |
| `cmp` [*mem8*],*immed8*     | 10EA   | 3 to 5 | `cmp` [ByteVar],39h   |
| `cmp` *reg16*,*sextimmed*   | 4      | 3      | `cmp` dx,8            |
| `cmp` *reg16*,*immed16*     | 4      | 4      | `cmp` sp,999h         |
| `cmp` [*mem16*],*sextimmed* | 14EA   | 3 to 5 | `cmp` [WordVar],12    |
| `cmp` [*mem16*],*immed16*   | 14EA   | 4 to 6 | `cmp` [WordVar],92h   |
| `cmp` al,*immed8*           | 4      | 2      | `cmp` al,22           |
| `cmp` ax,*immed16*          | 4      | 3      | `cmp` ax,722          |

**Notes:**

`cmp` compares two operands and sets the flags to indicate the results of the comparison. *Neither operand is affected*. The operation itself is identical to subtraction of the source from the destination without borrow (the operation of the `sub` instruction) save that the result is only used to set the flags, and does not replace the destination. Typically, `cmp` is followed by one of the conditional jump instructions; for example, `jz` to jump if the operands were equal, `jnz` if they were unequal, and so on.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


CMPS Compare string
-------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|               | Cycles    | Bytes |                       |
|---------------|-----------|-------|-----------------------|
| `cmpsb`       | 22        | 1     | `cmpsb`               |
| `repz cmpsb`  | 9(22\*CX) | 2     | `repz cmpsb`          |
| `repnz cmpsb` | 9(22\*CX) | 2     | `repnz cmpsb`         |
| `cmpsw`       | 30        | 1     | `cmpsw`               |
| `repz cmpsw`  | 9(30\*CX) | 2     | `repz cmpsw`          |
| `repnz cmpsw` | 9(30\*CX) | 2     | `repnz cmpsw`         |

**Notes:**

`cmps` compares either the byte (`cmpsb`) or word (`cmpsw`) pointed to by DS:SI to the byte or word pointed to by ES:DI, adjusting both SI and DI after the operation, as described below. The use of DS as the source segment can be overridden, but ES must be the segment of the destination and cannot be overridden. SI must always be the source offset, and DI must always be the destination offset. The comparison is performed via a trial subtraction of the location pointed to by ES:DI from the location pointed to by DS:SI; just as with `cmp`, this trial subtraction alters only the flags, not any memory locations.

By placing an instruction repeat count in CX and preceding `cmpsb` or `cmpsw` with the `repz` or `repnz` prefix, it is possible to execute a single `cmps` up to 65,535 (0FFFFh) times, just as if that many `cmps` instructions had been executed, but without the need for any additional instruction fetching. Repeated `cmps` instructions end either when CX counts down to 0 or when the state of the Zero flag specified by `repz`/`repnz` ceases to be true. The Zero flag should be tested to determine whether a match/nonmatch was found after `repz cmps` or `repnz cmps` ends.

Note that if CX is 0 when repeated `cmps` is started, zero repetitions of `cmps`not 65,536 repetitionsare performed. After each `cmps`, SI and DI are adjusted (as described in the next paragraph) by either 1 (for `cmpsb`) or 2 (for `cmpsw`), and, if the `repz` or `repnz` prefix is being used, CX is decremented by 1. Note that the accumulator is not affected by `cmps`.

"Adjusting" SI and DI means incrementing them if the Direction flag is cleared (0) or decrementing them if the Direction flag is set (1).

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


CWD Convert signed word in AX to signed doubleword in DX:AX
-----------------------------------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `cwd` | 5      | 1     | `cwd` |

**Notes:**

`cwd` signextends a signed word in AX to a signed doubleword in DX:AX. In other words, bit 15 of AX is copied to all bits of DX.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


DAA Decimal adjust after addition
---------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `daa` | 4      | 1     | `daa` |

**Notes:**

Given the binary result of the addition of two packed BCD values in AL, with the flags still set from the addition, `daa` corrects that binary result to two packed BCD digits in AL.

The Overflow flag is left in an undefined state by `daa`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


DAS Decimal adjust after subtraction
------------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `das` | 4      | 1     | `das` |

**Notes:**

Given the binary result of the subtraction of two packed BCD values in AL, with the flags still set from the subtraction, `das` corrects that binary result to two packed BCD digits in AL.

The Overflow flag is left in an undefined state by `das`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


DEC Decrement operand
---------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                 | Cycles | Bytes  |                     |
|-----------------|--------|--------|---------------------|
| `dec` *reg8*    | 3      | 2      | `dec` ah            |
| `dec` [*mem8*]  | 15EA   | 2 to 4 | `dec` byte ptr [bx] |
| `dec` *reg16*   | 2      | 1      | `dec` si            |
| `dec` [*mem16*] | 23EA   | 2 to 4 | `dec` [WordVar]     |

**Notes:**

`dec` decrements (subtracts 1 from) the operand. Decrementing an operand with `dec` is similar to subtracting 1 from the operand with `sub`; however, `dec` is more compact, since no immediate operand is required, and, unlike `sub`, the Carry flag is not affected by `dec`. Note the special, shorter 16bitregister form of `dec`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


DIV Unsigned divide
-------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                 | Cycles         | Bytes  |                      |
|-----------------|----------------|--------|----------------------|
| `div` *reg8*    | 80 to 90       | 2      | `div` bh             |
| `div` [*mem8*]  | 86EA to 96EA   | 2 to 4 | `div` byte ptr [si3] |
| `div` *reg16*   | 144 to 162     | 2      | `div` cx             |
| `div` [*mem16*] | 154EA to 172EA | 2 to 4 | `div` [WordVar]      |

**Notes:**

`div` performs a 16x8 unsigned division of AX by a byte operand, storing the quotient in AL and the remainder in AH, or a 32x16 unsigned multiplication of DX:AX by a word operand, storing the quotient in AX and the remainder in DX. Note that in order to use a byte value in AL as a dividend, you must zeroextend it to a word in AX (`sub ah,ah` can be used for this purpose). Similarly, in order to divide a word value in AX by another word value, you must zeroextend it to a doubleword in DX:AX, generally with `sub dx,dx`. Also note that for 16x8 division, the quotient must be no larger than 8 bits, and for 32x16 division, the quotient must be no larger than 16 bits. If the quotient is too large, or if the divisor is 0, a dividebyzero interrupt, `int 0`, is executed.

OF, SF, ZF, AF, PF, and CF are left in undefined states by `div`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


HLT Halt
--------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `hlt` | 2      |1      | `hlt` |

**Notes:**

`hlt` stops the 8088 until a hardware interrupt, a nonmaskable interrupt, or a processor reset occurs. This instruction is almost never used in normal PC programs.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

IDIV Signed divide
------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                  | Cycles         | Bytes  |                        |
|------------------|----------------|--------|------------------------|
| `idiv` *reg8*    | 101 to 112     | 2      | `idiv` cl              |
| `idiv` [*mem8*]  | 107EA to 118EA | 2 to 4 | `idiv` [ByteVar]       |
| `idiv` *reg16*   | 165 to 184     | 2      | `idiv` bx              |
| `idiv` [*mem16*] | 175EA to 194EA | 2 to 4 | `idiv` word ptr [bxsi] |

**Notes:**

`idiv` performs a 16x8 signed division of AX by a byte operand, storing the quotient in AL and the remainder in AH, or a 32x16 signed multiplication of DX:AX by a word operand, storing the quotient in AX and the remainder in DX. Note that in order to use a byte value in AL as a dividend, you must signextend it to a word in AX (`cbw` can be used for this purpose). Similarly, in order to divide a word value in AX by another word value, you must signextend it to a doubleword in DX:AX, generally with `cwd`. Also note that for 16x8 division, the quotient must be no larger than 8 bits (including the sign bit), and for 32x16 division, the quotient must be no larger than 16 bits (including the sign bit). If the quotient is too large, or if the divisor is 0, a dividebyzero interrupt, `int 0`, is executed.

OF, SF, ZF, AF, PF, and CF are left in undefined states by `idiv`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

IMUL Signed multiply
--------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                  | Cycles         | Bytes  |                      |
|------------------|----------------|--------|----------------------|
| `imul` *reg8*    | 80 to 98       | 2      | `imul` ch            |
| `imul` [*mem8*]  | 86EA to 104EA  | 2 to 4 | `imul` byte ptr [bx] |
| `imul` *reg16*   | 128 to 154     | 2      | `imul` bp            |
| `imul` [*mem16*] | 138EA to 164EA | 2 to 4 | `imul` [WordVarsi]   |

**Notes:**

`imul` performs an 8x8 signed multiplication of AL by a byte operand, storing the result in AX, or a 16x16 signed multiplication of AX by a word operand, storing the result in DX:AX. Note that AH is changed by 8x8 multiplication even though it is not an operand; the same is true of DX for 16x16 multiplication.

CF and OF are set to 1 if and only if the upper half of the result (AH for 8x8 multiplies, DX for 16x16 multiplies) is not a signextension of the lower half (that is, if the upper half of the result is *not* all 0 bits or all 1 bits), and set to 0 otherwise. SF, ZF, AF, and PF are left in undefined states.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

IN Input byte from I/O port
---------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                  | Cycles | Bytes |             |
|------------------|--------|-------|-------------|
| `in` al,dx       | 8      | 1     | `in` al,dx  |
| `in` al,*immed8* | 10     | 2     | `in` al,1   |
| `in` ax,dx       | 12     | 1     | `in` ax,dx  |
| `in` ax,*immed8* | 14     | 2     | `in` ax,92h |

**Notes:**

`in` reads data from the specified I/O port into the accumulator. Note that data *must* go to the accumulator, and that only DX or a constant may be used to address the I/O port. Note also that a constant may only be used to address I/O ports in the range 0255; DX must be used to address I/O ports in the range 25665,535.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


INC Increment operand
---------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                 | Cycles | Bytes  |                     |
|-----------------|--------|--------|---------------------|
| `inc` *reg8*    | 3      | 2      | `inc` ah            |
| `inc` [*mem8*]  | 15EA   | 2 to 4 | `inc` byte ptr [bx] |
| `inc` *reg16*   | 2      | 1      | `inc` si            |
| `inc` [*mem16*] | 23EA   | 2 to 4 | `inc` [WordVar]     |

**Notes:**

`inc` increments (adds 1 to) the operand. Incrementing an operand with
`inc` is similar to adding 1 to the operand with `add`; however,
`inc` is more compact, since no immediate operand is required, and,
unlike `add`, the Carry flag is not affected by `inc`. Note the
special, shorter 16bit register form of `inc`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


INT Software interrupt
----------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |  *  |  *  |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                | Cycles | Bytes |           |
|----------------|--------|-------|-----------|
| `int` *immed8* | 71     | 2     | `int` 10h |
| `int` 3        | 72     | 1     | `int` 3   |

**Notes:**

`int` generates a software interrupt to one of 256 segment:offset vectors stored in the first 1024 bytes of memory. The operand specifies which vector, in the range 0 to 255, is to be used; `int n` branches to the address specified by the segment:offset pointer stored at address `0000:n*4`. When an interrupt is performed, the FLAGS register is pushed on the stack, followed by the current CS and then the IP of the instruction after the `int`, so that a later `iret` can restore the pre interrupt FLAGS register and return to the instruction following the `int` instruction. The Interrupt flag is cleared by `int`, preventing hardware interrupts from being recognized until IF is set again. TF is also cleared.

There's also a special 1byte form of `int` specifically for executing interrupt 3. Debuggers use interrupt 3 to set "breakpoints" in code by replacing an instruction byte to be stopped at with the singlebyte opcode for `int 3`. Normal programs use the 2byte form of `int`, which takes an 8bit immediate numeric value.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

INTO Execute int 4 if Overflow flag set
---------------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |  *  |  *  |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|        | Cycles             | Bytes |        |
|--------|--------------------|-------|--------|
| `into` | 73 (OF=1)/4 (OF=0) | 1     | `into` |

**Notes:**

`into` executes an `int 4` if the Overflow flag is set (equal to 1),
and does nothing otherwise. This is a compact (1 bytes) way to check for
overflow after arithmetic operations and branch to a common handler if
overflow does occur. The Interrupt flag is cleared by `into`. TF is
also cleared.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

IRET Return from interrupt
--------------------------

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |  *  |  *  |  *  |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |

Table: Instruction forms

|        | Cycles | Bytes |        |
|--------|--------|-------|--------|
| `iret` | 44     | 1     | `iret` |

**Notes:**

`iret` is the proper way to exit from an interrupt service routine;
that is, from code called branched to with `int` or started by
hardware that generates hardware interrupts, such as serial ports, the
timer chip, the keyboard, and the like. `iret` pops the return address
from the top of the stack into CS:IP (IP must be on top of the stack,
followed by CS), and then pops the next word from the stack into the
FLAGS register. (This is the state in which both hardware and software
interrupts leave the stack.) *All flags are affected*.

For interrupts triggered by hardware, additional steps, such as issuing
an "end of interrupt" (EOI) command, are generally required in order to
prepare the hardware for another interrupt before `iret` is executed,
depending on the hardware involved. Consult your PC and peripheral
hardware documentation.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

J? Jump on condition
--------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |

| Instruction forms | Descriptions                   | Jump conditions |                  |
|-------------------|--------------------------------|-----------------|------------------|
| `ja` *disp8*      | Jump above                     | CF=0 and ZF=0   | `ja` OutOfRange  |
| `jae` *disp8*     | Jump above or equal            | CF=0            | `jae` XLabel     |
| `jb` *disp8*      | Jump below                     | CF=1            | `jb` TooLow      |
| `jbe` *disp8*     | Jump below or equal            | CF=1 or ZF=1    | `jbe` Exit       |
| `jc` *disp8*      | Jump Carry flag set            | CF=1            | `jc` NextTest    |
| `je` *disp8*      | Jump equal                     | ZF=1            | `je` Same        |
| `jg` *disp8*      | Jump greater                   | ZF=0 and SF=OF  | `jg` Greater     |
| `jge` *disp8*     | Jump greater than or equal     | SF=OF           | `jge` GtThanEq   |
| `jl` *disp8*      | Jump less than                 | SF<>OF          | `jl` IsLessThan  |
| `jle` *disp8*     | Jump less than or equal        | ZF=1 or SF<>OF  | `jle` LessThanEq |
| `jna` *disp8*     | Jump not above                 | CF=1 or ZF=1    | `jna` NotAbove   |
| `jnae` *disp8*    | Jump not above or equal        | CF=1            | `jnae` Skip1     |
| `jnb` *disp8*     | Jump not below                 | CF=0            | `jnb` OffTop     |
| `jnbe` *disp8*    | Jump not below or equal        | CF=0 and ZF=0   | `jnbe` TooHigh   |
| `jnc` *disp8*     | Jump Carry flag not set        | CF=0            | `jnc` TryAgain   |
| `jne` *disp8*     | Jump not equal                 | ZF=0            | `jne` Mismatch   |
| `jng` *disp8*     | Jump not greater               | ZF=1 or SF<>OF  | `jng` LoopBottom |
| `jnge` *disp8*    | Jump not greater than or equal | SF<>OF          | `jnge` Point2    |
| `jnl` *disp8*     | Jump not less than             | SF=OF           | `jnl` NotLess    |
| `jnle` *disp8*    | Jump not less than or equal    | ZF=0 and SF=OF  | `jnle` ShortLab  |
| `jno` *disp8*     | Jump Overflow flag not set     | OF=0            | `jno` NoOverflow |
| `jnp` *disp8*     | Jump Parity flag not set       | PF=0            | `jnp` EndText    |
| `jns` *disp8*     | Jump Sign flag not set         | SF=0            | `jns` NoSign     |
| `jnz` *disp8*     | Jump not zero                  | ZF=0            | `jnz` Different  |
| `jo` *disp8*      | Jump Overflow flag set         | OF=1            | `jo` Overflow    |
| `jp` *disp8*      | Jump Parity flag set           | PF=1            | `jp` ParCheck1   |
| `jpe` *disp8*     | Jump Parity Even               | PF=1            | `jpe` ParityEven |
| `jpo` *disp8*     | Jump Parity Odd                | PF=0            | `jpo` OddParity  |
| `js` *disp8*      | Jump Sign flag set             | SF=1            | `js` Negative    |
| `jz` *disp8*      | Jump zero                      | ZF=1            | `jz` Match       |

All conditional jumps take 16 `Cycles` if the condition is true and the branch is taken, or 4 `Cycles` if the condition is false and the branch is not taken. All conditional jump instructions are 2 bytes long.

**Notes:**

Each conditional jump instruction makes a short jump (a maximum of 127 bytes forward or 128 bytes back from the start of the instruction after the conditional jump) if the specified condition is true, or falls through if the condition is not true. The conditions all involve flags; the flag conditions tested by each conditional jump are given to the right of the mnemonic and its description, above.

The mnemonics incorporating "above" and "below" are for use after unsigned comparisons, whereas the mnemonics incorporating "less" and "greater" are for use after signed comparisons. "Equal" and "zero" may be used after either signed or unsigned comparisons.

Note that two or three different mnemonics often test the same condition; for example, `jc`, `jb`, and `jnae` all assemble to the same instruction, which branches only when the Carry flag is set to 1. The multiple mnemonics provide different logical ways to think of the instruction; for example, `jc` could be used to test a status returned in the Carry flag by a subroutine, while `jb` or `jnae` might be used after an unsigned comparison. Any of the three mnemonics would work, but it's easier to use a mnemonic that's logically related to the task at hand.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


JCXZ Jump if CX = 0
-------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |

Table: Instruction forms

|                | Cycles              | Bytes |                 |
|----------------|---------------------|-------|-----------------|
| `jcxz` *disp8* | 18 (CX=0)/6 (CX<>0) | 2     | `jcxz` SkipTest |

**Notes:**

Many instructions use CX as a counter. `jcxz`, which branches only if CX=0, allows you to test for the case where CX is 0, as for example to avoid executing a loop 65,536 times when the loop is entered with CX=0. The branch can only be a short branch (that is, no more than 127 bytes forward or 128 bytes back from the start of the instruction following `jcxz`), and will be taken only if CX=0 at the time the instruction is executed. If CX is any other value than 0, execution falls through to the next instruction.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

JMP Jump
--------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |

Table: Instruction forms

|                        | Cycles | Bytes  |                          |
|------------------------|--------|--------|--------------------------|
| `jmp` *disp8*          | 15     | 2      | `jmp` short SkipAdd      |
| `jmp` *disp16*         | 15     | 3      | `jmp` NearLabel          |
| `jmp` *reg16*          | 11     | 2      | `jmp` dx                 |
| `jmp` [*mem16*]        | 22EA   | 2 to 4 | `jmp` word ptr [Vecsbx]  |
| `jmp` *segment:offset* | 15     | 5      | `jmp` FarLabel           |
| `jmp` [*mem32*]        | 32EA   | 2 to 4 | `jmp` dword ptr [FarVec] |

**Notes:**

`jmp` branches to the destination specified by the single operand; that is, `jmp` sets IP (and CS, for far jumps) so that the next instruction executed is at the specified location. In addition to branching to either near or far labels, `jmp` can branch anywhere in the segment pointed to by CS by setting IP equal to an offset stored in any generalpurpose register. `jmp` can also branch to an address (either near or far) stored in memory and accessed through any *mod-reg-rm* addressing mode; this is ideal for branching to addresses stored in jump tables.

Note that short jumps can only reach labels within 127 or 128 bytes of the start of the instruction after the jump, but are 1 byte shorter than normal 16bitdisplacement jumps, which can reach anywhere in the current code segment.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

LAHF Load AH from 8080 flags
----------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |

Table: Instruction forms

|        | Cycles | Bytes |        |
|--------|--------|-------|--------|
| `lahf` | 4      | 1     | `lahf` |

**Notes:**

`lahf` copies the lower byte of the FLAGS register to AH. This action, which can be reversed with `sahf`, is intended to allow the 8088 to emulate the `push psw` instruction of the 8080; however, it can also be used to save five of the 8088's flagsthe Sign flag, the Zero flag, the Auxiliary Carry flag, the Parity flag, and the Carry flagquickly and without involving the stack. Note that the Overflow flag is *not* copied to AH.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

LDS Load DS pointer
-------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                 | Cycles | Bytes  |                     |
|-----------------|--------|--------|---------------------|
| `lds` [*mem32*] | 24EA   | 2 to 4 | `lds` bx,[DwordVar] |

**Notes:**

`lds` loads both DS and a generalpurpose register from a memory doubleword. This is useful for loading a segment:offset pointer to any location in the 8088's address space in a single instruction. Note that segment:offset pointers loaded with `les` must be stored with the offset value at memory address *n* and the segment value at memory address *n*2.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

LEA Load effective address
--------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                       | Cycles | Bytes  |                     |
|-----------------------|--------|--------|---------------------|
| `lea` *reg16*,[*mem*] | 2EA    | 2 to 4 | `lea` bx,[bpsi100h] |

**Notes:**

`lea` calculates the offset of the source operand within its segment, then loads that offset into the destination operand. The destination operand must be a 16bit register, and *cannot* be memory. The source operand must be a memory operand, but may be of any size. In other words, the value stored in the destination operand is the offset of the first byte of the source operand in memory. The source operand is not actually read.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


LES Load ES pointer
-------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                 | Cycles | Bytes  |                         |
|-----------------|--------|--------|-------------------------|
| `les` [*mem32*] | 24EA   | 2 to 4 | `les` di,dword ptr [bx] |

**Notes:**

`les` loads both ES and a generalpurpose register from a memory doubleword. This is useful for loading a segment:offset pointer to any location in the 8088's address space in a single instruction. Note that segment:offset pointers loaded with `les` must be stored with the offset value at memory address *n* and the segment value at memory address *n*2.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


LODS Load string
----------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|             | Cycles    | Bytes |             |
|-------------|-----------|-------|-------------|
| `lodsb`     | 12        | 1     | `lodsb`     |
| `rep lodsb` | 9(13\*CX) | 2     | `rep lodsb` |
| `lodsw`     | 16        | 1     | `lodsw`     |
| `rep lodsw` | 9(17\*CX) | 2     | `rep lodsw` |

**Notes:**

`lods` loads either AL (`lodsb`) or AX (`lodsw`) from the location pointed to by DS:SI, adjusting SI after the operation, as described below. DS may be overridden as the source segment, but SI must always be the source offset.

By placing an instruction repeat count in CX and preceding `lodsb` or `lodsw` with the `rep` prefix, it is possible to execute a single `lods` up to 65,535 (0FFFFh) times; however, this is not particularly useful, since the value loaded into AL or AX by each repeated `lods` will wipe out the value loaded by the previous repetition. After each `lods`, SI is adjusted (as described in the next paragraph) by either 1 (for `lodsb`) or 2 (for `lodsw`), and, if the `rep` prefix is being used, CX is decremented by 1.

"Adjusting" SI means incrementing SI if the Direction flag is cleared (0) or decrementing SI if the Direction flag is set (1).

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


LOOP Loop while CX not equal to 0
---------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                | Cycles              | Bytes |                 |
|----------------|---------------------|-------|-----------------|
| `loop` *disp8* | 17 (CX<>0)/5 (CX=0) | 2     | `loop` WaitLoop |

**Notes:**

`loop` is similar to the twoinstruction sequence `dec cx`/`jnz disp8`. When the `loop` instruction is executed, it first decrements CX, then it tests to see if CX equals 0. If CX is *not* 0 after being decremented, `loop` branches *disp8* bytes relative to the start of the instruction following `loop`; if CX is 0, execution falls through to the instruction after `loop`.

The difference between `loop` and the above twoinstruction sequence is that `loop` does not alter any flags, even when CX is decremented to 0. Be aware that if CX is initially 0, `loop` will decrement it to 65,535 (0FFFFh) and then perform the loop another 65,535 times.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


LOOPNZ Loop while CX not equal to 0 and Zero flag equal to 0
------------------------------------------------------------

`LOOPNE``` `Loop while CX not equal to 0 and last result was not equal`

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                  | Cycles                               | Bytes |                 |
|------------------|--------------------------------------|-------|-----------------|
| `loopnz` *disp8* | 19 (CX<>0 and ZF=0)/5 (CX=0 or ZF=1) | 2     | `loopnz` PollLp |

**Notes:**

`loopnz` (also known as `loopne`) is identical to `loop`, except that `loopnz` branches to the specified displacement only if CX isn't equal to 0 after CX is decremented *and* the Zero flag is cleared to 0. This is useful for handling a maximum number of repetitions of a loop that normally terminates on a Zero flag setting of 1.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


# LOOPZ Loop while CX not equal to 0 and Zero flag equal to 1

## LOOPE Loop while CX not equal to 0 and last result was equal

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                 | Cycles                               | Bytes |                 |
|-----------------|--------------------------------------|-------|-----------------|
| `loopz` *disp8* | 18 (CX<>0 and ZF=1)/6 (CX=0 or ZF=0) | 2     | `loopz` MaxWtLp |

**Notes:**

`loopz` (also known as `loope`) is identical to `loop`, except that `loopz` branches to the specified displacement only if CX isn't equal to 0 after CX is decremented *and* the Zero flag is set to 1. This is useful for handling a maximum number of repetitions of a loop that normally terminates on a Zero flag setting of 0.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


MOV Move (copy) right operand into left operand
-----------------------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                             | Cycles | Bytes  |                       |
|-----------------------------|--------|--------|-----------------------|
| `mov` *reg8*,*reg8*         | 2      | 2      | `mov` ch,al           |
| `mov` [*mem8*],*reg8*       | 9EA    | 2 to 4 | `mov` [bx10h],dh      |
| `mov` *reg8*,[*mem8*]       | 8EA    | 2 to 4 | `mov` bl,[si]         |
| `mov` *reg16*,*reg16*       | 2      | 2      | `mov` ax,dx           |
| `mov` [*mem16*],*reg16*     | 13EA   | 2 to 4 | `mov` [WordVar],cx    |
| `mov` *reg16*,[*mem16*]     | 12EA   | 2 to 4 | `mov` bx,[Tablebx]    |
| `mov` *reg8*,*immed8*       | 4      | 2      | `mov` dl,1            |
| `mov` [*mem8*],*immed8*     | 10EA   | 3 to 5 | `mov` [ByteVar],1     |
| `mov` *reg16*,*immed16*     | 4      | 3      | `mov` ax,88h          |
| `mov` [*mem16*],*immed16*   | 14EA   | 4 to 6 | `mov` [WordVar],1000h |
| `mov` al,[*mem8*] (direct)  | 10     | 3      | `mov` al,[Flag]       |
| `mov` [*mem8*],al (direct)  | 10     | 3      | `mov` [ByteVar],al    |
| `mov` ax,[*mem16*] (direct) | 14     | 3      | `mov` ax,[WordVar]    |
| `mov` [*mem16*],ax (direct) | 14     | 3      | `mov` [Count],ax      |
| `mov` *segreg*,*reg16*      | 2      | 2      | `mov` es,ax           |
| `mov` *segreg*,[*mem16*]    | 12EA   | 2 to 4 | `mov` ds,[DataPtrsbx] |
| `mov` *reg16*,*segreg*      | 2      | 2      | `mov` dx,ds           |
| `mov` [*mem16*],*segreg*    | 13EA   | 2 to 4 | `mov` [StackSeg],ss   |

**Notes:**

`mov` copies the contents of the source operand to the destination operand. The source operand is not affected, and no flags are affected. Note that, unlike other instructions that accept immediate operands, 16bit immediate operands to `mov` are never stored as a single byte that is sign extended at execution time. Note also that the special, shorter accumulatorspecific form of `mov` only applies to directaddressed operands, and that there is a special, 1byteshorter form of `mov` to load a register (but not a memory operand) with an immediate value.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


MOVS Move string
----------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|             | Cycles    | Bytes |             |
|-------------|-----------|-------|-------------|
| `movsb`     | 18        | 1     | `movsb`     |
| `rep movsb` | 9(17\*CX) | 2     | `rep movsb` |
| `movsw`     | 26        | 1     | `movsw`     |
| `rep movsw` | 9(25\*CX) | 2     | `rep movsw` |

**Notes:**

`movs` copies either the byte (`movsb`) or word (`movsw`) pointed
to by DS:SI to the location pointed to by ES:DI, adjusting both SI and
DI after the operation, as described below. The use of DS as the source
segment can be overridden, but ES must be the segment of the destination
and cannot be overridden. SI must always be the source offset, and DI
must always be the destination offset.

By placing an instruction repeat count in CX and preceding `movsb` or
`movsw` with the `rep` prefix, it is possible to execute a single
`movs` up to 65,535 (0FFFFh) times, just as if that many `movs`
instructions had been executed, but without the need for any additional
instruction fetching. Note that if CX is 0 when `rep movs` is started,
zero repetitions of `movs`not 65,536 repetitionsare performed. After
each `movs`, SI and DI are adjusted (as described in the next
paragraph) by either 1 (for `movsb`) or 2 (for `movsw`), and, if the
`rep` prefix is being used, CX is decremented by 1.

"Adjusting" SI and DI means incrementing them if the Direction flag is
cleared (0) or decrementing them if the Direction flag is set (1).

Note that the accumulator is not affected by `movs`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

MUL Unsigned multiply
---------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |

Table: Instruction forms

|                 | Cycles         | Bytes  |                       |
|-----------------|----------------|--------|-----------------------|
| `mul` *reg8*    | 70 to 77       | 2      | `mul` ah              |
| `mul` [*mem8*]  | 76EA to 83EA   | 2 to 4 | `mul` byte ptr [bxsi] |
| `mul` *reg16*   | 118 to 133     | 2      | `mul` cx              |
| `mul` [*mem16*] | 128EA to 143EA | 2 to 4 | `mul` [WordVar]       |

**Notes:**

`mul` performs an 8x8 unsigned multiplication of AL by a byte operand, storing the result in AX, or a 16x16 unsigned multiplication of AX by a word operand, storing the result in DX:AX. Note that AH is changed by 8x8 multiplication even though it is not an operand; the same is true of DX for 16x16 multiplication.

CF and OF are set to 1 if and only if the upper half of the result (AH for 8x8 multiplies, DX for 16x16 multiplies) is nonzero, and set to 0 otherwise. SF, ZF, AF, and PF are left in undefined states.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

NEG Negate (two's complement; i.e. multiply by 1)
-------------------------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                 | Cycles | Bytes  |                        |
|-----------------|--------|--------|------------------------|
| `neg` *reg8*    | 3      | 2      | `neg` cl               |
| `neg` [*mem8*]  | 16EA   | 2 to 4 | `neg` [ByteVar]        |
| `neg` *reg16*   | 3      | 2      | `neg` si               |
| `neg` [*mem16*] | 24EA   | 2 to 4 | `neg` word ptr [bxsi1] |

**Notes:**

`neg` performs the assembly language equivalent of multiplying a value by 1. Keep in mind that negation is not the same as simply inverting each bit in the operand; another instruction, `not`, does that. The process of negation is also known as generating the *two's complement* of a value; the two's complement of a value added to that value yields zero.

If the operand is 0, CF is cleared and ZF is set; otherwise CF is set and ZF is cleared. This property can be useful in multiword negation. If the operand contains the maximum negative value (80h = 128 for byte operands, 8000h = 32,768 for word operands), there is no corresponding positive value that will fit in the operand, so the operand does not change; this case can be detected because it is the only case in which the Overflow flag is set by `neg`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

NOP No operation
----------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `nop` | 3      | 1     | `nop` |


**Notes:**

This, the easiest to understand of all 8086family machine instructions, does nothing; its job is simply to take up space and/or time. The opcode for `nop` is actually the opcode for `xchg ax,ax`, which changes no registers and alters no flags, but which does take up 1 byte and require 3 `Cycles` to execute. `nop` is used for patching out machine instructions during debugging, leaving space for future procedure or interrupt calls, and padding timing loops. `nop` instructions are also inserted by MASM to fill reserved space that turns out not to be needed, such as the third byte of a forward `jmp` that turns out to be a `jmp short`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

NOT Logical not (one's complement)
----------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                 | Cycles | Bytes  |                     |
|-----------------|--------|--------|---------------------|
| `not` *reg8*    | 3      | 2      | `not` al            |
| `not` [*mem8*]  | 16EA   | 2 to 4 | `not` byte ptr [bx] |
| `not` *reg16*   | 3      | 2      | `not` dx            |
| `not` [*mem16*] | 24EA   | 2 to 4 | `not` [WordVar]     |

**Notes:**

`not` inverts each individual bit within the operand. In other words, every bit that was 1 becomes 0, and every bit that was 0 becomes 1, just as if the operand had been exclusive ored with 0FFh (for byte operands) or 0FFFFh (for word operands). `not` performs the "logical not," or "one's complement," operation. See the `neg` instruction for the negation, or "two's complement," operation.

Note that no flags are altered.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

OR Logical or
-------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                           | Cycles | Bytes  |                     |
|---------------------------|--------|--------|---------------------|
| `or`*reg8*,*reg8*         | 3      | 2      | `or`al,dl           |
| `or`[*mem8*],*reg8*       | 16EA   | 2 to 4 | `or`[ByteVar],ch    |
| `or`*reg8*,[*mem8*]       | 9EA    | 2 to 4 | `or`bh,[si]         |
| `or`*reg16*,*reg16*       | 3      | 2      | `or`bp,ax           |
| `or`[*mem16*],*reg16*     | 24EA   | 2 to 4 | `or`[bpsi],cx       |
| `or`*reg16*,[*mem16*]     | 13EA   | 2 to 4 | `or`ax,[bx]         |
| `or`*reg8*,*immed8*       | 4      | 3      | `or`cl,03h          |
| `or`[*mem8*],*immed8*     | 17EA   | 3 to 5 | `or`[ByteVar1],29h  |
| `or`*reg16*,*sextimmed*   | 4      | 3      | `or`ax,01fh         |
| `or`*reg16*,*immed16*     | 4      | 4      | `or`ax,01fffh       |
| `or`[*mem16*],*sextimmed* | 25EA   | 3 to 5 | `or`[WordVar],7fh   |
| `or`[*mem16*],*immed16*   | 25EA   | 4 to 6 | `or`[WordVar],7fffh |
| `or`al,*immed8*           | 4      | 2      | `or`al,0c0h         |
| `or`ax,*immed16*          | 4      | 3      | `or`ax,01ffh        |

**Notes:**

`or` performs the "or" logical operation between its two operands. Once the operation is complete, the result replaces the destination operand. `or` is performed on a bitby bit basis, such that bit 0 of the source is ored with bit 0 of the destination, bit 1 of the source is ored with bit 1 of the destination, and so on. The "or" operation yields a 1 if *either one* of the operands is 1, and a 0 only if both operands are 0. Note that `or` makes the Auxiliary Carry flag undefined. CF and OF are cleared to 0, and the other affected flags are set according to the operation's results.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


OUT Output byte to I/O port
---------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |

Table: Instruction forms

|                   | Cycles | Bytes |              |
|-------------------|--------|-------|--------------|
| `out` dx,al       | 8      | 1     | `out` dx,al  |
| `out` *immed8*,al | 10     | 2     | `out` 21h,al |
| `out` dx,ax       | 12     | 1     | `out` dx,ax  |
| `out` *immed8*,ax | 14     | 2     | `out` 10,ax  |

**Notes:**

`out` writes the data in the accumulator to the specified I/O port. Note that data *must* come from the accumulator, and that only DX or a constant may be used to address the I/O port. Note also that a constant may only be used to address I/O ports in the range 0255; DX must be used to address I/O ports in the range 25665,535.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

POP Pop from top of stack
-------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |

Table: Instruction forms

|                          | Cycles | Bytes  |                      |
|--------------------------|--------|--------|----------------------|
| `pop` *reg16*            | 12     | 1      | `pop` cx             |
| `pop` *mem16*            | 25EA   | 2 to 4 | `pop` word ptr [si1] |
| `pop` *segreg*  (not CS) | 12     | 1      | `pop` es             |

**Notes:**

`pop` pops the word on top of the stack into the specified operand. SP is incremented by 2 *after* the word comes off the stack. Remember that a word can be popped directly to memory, without passing through a register.

It is impossible to pop a bytesized item from the stack; it's words or nothing. There is a separate instruction, `popf`, for popping the FLAGS register.

Note that CS cannot by popped off the stack with `pop`; in order to load CS from the stack, it must be loaded simultaneously with IP, usually via `retf`.

The top of the stack is always located at SS:SP; the segment cannot be overridden, and `pop` always uses SP to address memory. However, when a memory location is popped, *mod-reg-rm* addressing is used to point to the memory location, and the default segment of DS for that operand can be overridden.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

POPF Pop top of stack into FLAGS reg
------------------------------------

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |  *  |  *  |  *  |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|        | Cycles | Bytes |        |
|--------|--------|-------|--------|
| `popf` | 12     | 1     | `popf` |


**Notes:**

`popf` pops the word on top of the stack into the FLAGS register. SP is incremented by 2 *after* the word comes off the stack.

There is a separate instruction, `pop`, for popping into register and memory operands.

The top of the stack is always located at SS:SP; the segment cannot be overridden, and `popf` always uses SP to address memory.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

PUSH Push onto top of stack
---------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                 | Cycles | Bytes  |                      |
|-----------------|--------|--------|----------------------|
| `push` *reg16*  | 15     | 1      | `push` ax            |
| `push` *mem16*  | 24EA   | 2 to 4 | `push` word ptr [bx] |
| `push` *segreg* | 14     | 1      | `push` ds            |

**Notes:**

`push` pushes the specified operand onto the top of the stack. SP is decremented by 2 *before* the word goes onto the stack. Remember that memory operands can be pushed directly onto the stack, without passing through a register.

It is impossible to push a bytesized item onto the stack; it's words or nothing. There is a separate instruction, `pushf`, for pushing the FLAGS register.

The top of the stack is always located at SS:SP; the segment cannot be overridden, and `push` always uses SP to address memory. However, when a memory location is pushed, *mod-reg-rm* addressing is used to point to the memory location, and the default segment of DS for that operand can be overridden.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

PUSHF Push FLAGS register onto top of stack
-------------------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |

Table: Instruction forms

|         | Cycles | Bytes |         |
|---------|--------|-------|---------|
| `pushf` | 14     | 1     | `pushf` |

**Notes:**

`pushf` pushes the current contents of the FLAGS register onto the top of the stack. SP is decremented *before* the word goes onto the stack.

There is a separate instruction, `push`, for pushing other register data and memory data.

The FLAGS register is not affected when you *push* the flags, but only when you pop them back with `popf`.

The top of the stack is always located at SS:SP; the segment cannot be overridden, and `pushf` always uses SP to address memory.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

RCL Rotate through carry left
-----------------------------

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |     |     |     |     |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                    | Cycles      | Bytes  |                             |
|--------------------|-------------|--------|-----------------------------|
| `rcl` *reg8*,1     | 2           | 2      | `rcl` dl,1                  |
| `rcl` [*mem8*],1   | 15EA        | 2 to 4 | `rcl` byte ptr [bxdi],1     |
| `rcl` *reg16*,1    | 2           | 2      | `rcl` dx,1                  |
| `rcl` [*mem16*],1  | 23EA        | 2 to 4 | `rcl` word ptr [di],1       |
| `rcl` *reg8*,cl    | 8(4\*CL)    | 2      | `rcl` ah,cl                 |
| `rcl` [*mem8*],cl  | 20EA(4\*CL) | 2 to 4 | `rcl` [ByteVar],cl          |
| `rcl` *reg16*,cl   | 8(4\*CL)    | 2      | `rcl` ax,cl                 |
| `rcl` [*mem16*],cl | 28EA(4\*CL) | 2 to 4 | `rcl` word ptr [bxIndex],cl |

**Notes:**

`rcl` rotates the bits within the destination operand to the left, where left is toward the most significant bit, bit 15 for word operands, bit 7 for byte operands. A rotate is a shift (see `shl` and `shr`) that wraps around; with `rcl`, the leftmost bit (bit 15 for word operands, bit 7 for byte operands) of the operand is rotated into the Carry flag, the Carry flag is rotated into the rightmost bit of the operand (bit 0), and all intermediate bits are rotated one bit to the left.

The number of bit positions rotated may either be specified as the literal 1 or by the value in CL (not CX!). It is generally faster to perform sequential rotatebyone instructions for rotations of up to about 4 bits, and faster to use rotatebyCL instructions for longer rotations. Note that while CL may contain any value up to 255, it is meaningless to rotate by any value larger than 17, *even though the rotations are actually performed wasting `Cycles` on the 8088*.

OF is modified predictably *only* by the rotatebyone forms of `rcl`; after rotatebyCL forms, OF becomes undefined.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

RCR Rotate through carry right
------------------------------

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |     |     |     |     |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                    | Cycles      | Bytes  |                         |
|--------------------|-------------|--------|-------------------------|
| `rcr` *reg8*,1     | 2           | 2      | `rcr` cl,1              |
| `rcr` [*mem8*],1   | 15EA        | 2 to 4 | `rcr` byte ptr [di],1   |
| `rcr` *reg16*,1    | 2           | 2      | `rcr` bx,1              |
| `rcr` [*mem16*],1  | 23EA        | 2 to 4 | `rcr` word ptr [bxdi],1 |
| `rcr` *reg8*,cl    | 8(4\*CL)    | 2      | `rcr` dh,cl             |
| `rcr` [*mem8*],cl  | 20EA(4\*CL) | 2 to 4 | `rcr` [ByteVar100h],cl  |
| `rcr` *reg16*,cl   | 8(4\*CL)    | 2      | `rcr` bx,cl             |
| `rcr` [*mem16*],cl | 28EA(4\*CL) | 2 to 4 | `rcr` [WordVar],cl      |

**Notes:**

`rcr` rotates the bits within the destination operand to the right, where right is toward the least significant bit, bit 0. A rotate is a shift (see `shl` and `shr`) that wraps around; with `rcr`, the rightmost bit (bit 0) of the operand is rotated into the Carry flag, the Carry flag is rotated into the leftmost bit of the operand (bit 15 for word operands, bit 7 for byte operands), and all intermediate bits are rotated one bit to the right.

The number of bit positions rotated may either be specified as the literal 1 or by the value in CL (not CX!). It is generally faster to perform sequential rotatebyone instructions for rotations of up to about 4 bits, and faster to use rotatebyCL instructions for longer rotations. Note that while CL may contain any value up to 255, it is meaningless to rotate by any value larger than 17, *even though the rotations are actually performed wasting `Cycles` on the 8088*.

OF is modified predictably *only* by the rotatebyone forms of `rcr`; after rotatebyCL forms, OF becomes undefined.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

RET Return from subroutine call
-------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                  | Cycles | Bytes |                         |
|------------------|--------|-------|-------------------------|
| `retn`           | 20     | 1     | `ret` (in near proc)    |
| `retf`           | 34     | 1     | `retf`                  |
| `retn` *immed16* | 24     | 3     | `retn` 10               |
| `retf` *immed16* | 33     | 3     | `ret` 512 (in far proc) |

**Notes:**

There are two kinds of returns, near and far, where near pops IP from the stack (returning to an address within the current code segment) and far pops both CS and IP from the stack (usually returning to an address in some other code segment). Ordinarily the `ret` form is used, with the assembler resolving it to a near or far return opcode to match the current `proc` directive's use of the `near` or `far` specifier. Alternatively, `retf` or `retn` may be used to select explicitly the type of return; however, be aware that the `retf` and `retn` forms are *not* available in MASM prior to version 5.0.

`ret` may take an operand indicating how many bytes of stack space are to be released (the amount to be added to the stack pointer) as the return is executed. This is used to discard parameters that were pushed onto the stack for the procedure's use immediately prior to the procedure call.

No two references agree on the execution times of `ret immed16` and `retf immed16`. The times shown above are from *Microsoft Macro Assembler 5.0 Reference*, which are closest to the times measured with the Zen timer. The Zen timer actually measured longer execution times still, most likely due to the effects of the prefetch queue bottleneck and DRAM refresh.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

ROL Rotate left
---------------

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |     |     |     |     |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                    | Cycles      | Bytes  |                           |
|--------------------|-------------|--------|---------------------------|
| `rol` *reg8*,1     | 2           | 2      | `rol` cl,1                |
| `rol` [*mem8*],1   | 15EA        | 2 to 4 | `rol` byte ptr [di],1     |
| `rol` *reg16*,1    | 2           | 2      | `rol` ax,1                |
| `rol` [*mem16*],1  | 23EA        | 2 to 4 | `rol` word ptr [Basebx],1 |
| `rol` *reg8*,cl    | 8(4\*CL)    | 2      | `rol` dl,cl               |
| `rol` [*mem8*],cl  | 20EA(4\*CL) | 2 to 4 | `rol` byte ptr [bx],cl    |
| `rol` *reg16*,cl   | 8(4\*CL)    | 2      | `rol` di,cl               |
| `rol` [*mem16*],cl | 28EA(4\*CL) | 2 to 4 | `rol` [WordVar],cl        |

**Notes:**

`rol` rotates the bits within the destination operand to the left, where left is toward the most significant bit, bit 15 for word operands and bit 7 for byte operands. A rotate is a shift (see `shl` and `shr`) that wraps around; with `rol`, the leftmost bit of the operand (bit 15 for word operands, bit 7 for byte operands) is rotated into the rightmost bit, and all intermediate bits are rotated one bit to the left.

The number of bit positions rotated may either be specified as the literal 1 or by the value in CL (not CX!). It is generally faster to perform sequential rotatebyone instructions for rotations of up to about 4 bits, and faster to use rotatebyCL instructions for longer rotations. Note that while CL may contain any value up to 255, it is meaningless to rotate by any value larger than 16, *even though the rotations are actually performed wasting `Cycles` on the 8088*.

The leftmost bit is copied into the Carry flag on each rotate operation. OF is modified predictably *only* by the rotatebyone forms of `rol`; after rotatebyCL forms, OF becomes undefined.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address


ROR Rotate right
----------------

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |     |     |     |     |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                    | Cycles      | Bytes  |                            |
|--------------------|-------------|--------|----------------------------|
| `ror` *reg8*,1     | 2           | 2      | `ror` dl,1                 |
| `ror` [*mem8*],1   | 15EA        | 2 to 4 | `ror` [ByteVar],1          |
| `ror` *reg16*,1    | 2           | 2      | `ror` bx,1                 |
| `ror` [*mem16*],1  | 23EA        | 2 to 4 | `ror` word ptr [bxsi],1    |
| `ror` *reg8*,cl    | 8(4\*CL)    | 2      | `ror` ah,cl                |
| `ror` [*mem8*],cl  | 20EA(4\*CL) | 2 to 4 | `ror` byte ptr [si100h],cl |
| `ror` *reg16*,cl   | 8(4\*CL)    | 2      | `ror` si,cl                |
| `ror` [*mem16*],cl | 28EA(4\*CL) | 2 to 4 | `ror` [WordVar1],cl        |

**Notes:**

`ror` rotates the bits within the destination operand to the right, where right is toward the least significant bit, bit 0. A rotate is a shift (see `shl` and `shr`) that wraps around; with `ror`, the rightmost bit (bit 0) of the operand is rotated into the leftmost bit (bit 15 for word operands, bit 7 for byte operands), and all intermediate bits are rotated one bit to the right.

The number of bit positions rotated may either be specified as the literal 1 or by the value in CL (not CX!). It is generally faster to perform sequential rotatebyone instructions for rotations of up to about 4 bits, and faster to use rotatebyCL instructions for longer rotations. Note that while CL may contain any value up to 255, it is meaningless to rotate by any value larger than 16, *even though the rotations are actually performed wasting `Cycles `on the 8088*.

Bit 0 of the operand is not only copied to the leftmost bit, but is also copied into the Carry flag by each rotation. OF is modified predictably *only* by the rotatebyone forms of `ror`; after rotatebyCL forms, OF becomes undefined.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

SAHF Store AH to 8080 flags
---------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|        | Cycles | Bytes |        |
|--------|--------|-------|--------|
| `sahf` | 4      | 1     | `sahf` |

**Notes:**

`sahf` copies AH to the lower byte of the FLAGS register. This reverses the action of `lahf`, and is intended to allow the 8088 to emulate the `pop psw` instruction of the 8080; however, it can also be used to restore five of the 8088's flagsthe Sign flag, the Zero flag, the Auxiliary Carry flag, the Parity flag, and the Carry flag quickly and without involving the stack. Note that the Overflow flag is *not* affected.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

SAR Shift arithmetic right
--------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                    | Cycles      | Bytes  |                        |
|--------------------|-------------|--------|------------------------|
| `sar` *reg8*,1     | 2           | 2      | `sar` bh,1             |
| `sar` [*mem8*],1   | 15EA        | 2 to 4 | `sar` [ByteVar],1      |
| `sar` *reg16*,1    | 2           | 2      | `sar` dx,1             |
| `sar` [*mem16*],1  | 23EA        | 2 to 4 | `sar` word ptr [bx1],1 |
| `sar` *reg8*,cl    | 8(4\*CL)    | 2      | `sar` ch,cl            |
| `sar` [*mem8*],cl  | 20EA(4\*CL) | 2 to 4 | `sar` byte ptr [bx],cl |
| `sar` *reg16*,cl   | 8(4\*CL)    | 2      | `sar` ax,cl            |
| `sar` [*mem16*],cl | 28EA(4\*CL) | 2 to 4 | `sar` [WordVar],cl     |

**Notes:**

`sar` shifts all bits within the destination operand to the right, where right is toward the least significant bit, bit 0. The number of bit positions shifted may either be specified as the literal 1 or by the value in CL (not CX!). It is generally faster to perform sequential shiftbyone instructions for shifts of up to about four bits, and faster to use shiftbyCL instructions for longer shifts. Note that while CL may contain any value up to 255, it is meaningless to shift by any value larger than 16, *even though the shifts are actually performed wasting `Cycles` on the 8088*.

The rightmost bit of the operand is shifted into the Carry flag by each shift; *the leftmost bit is left unchanged*. This preservation of the most significant bit, which is the difference between `sar` and `shr`, maintains the sign of the operand. The Auxiliary Carry flag (AF) becomes undefined after this instruction. OF is modified predictably *only* by the shiftby one forms of `sar`; after shiftbyCL forms, OF becomes undefined.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

SBB Arithmetic subtract with borrow
-----------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                             | Cycles | Bytes  |                           |
|-----------------------------|--------|--------|---------------------------|
| `sbb` *reg8*,*reg8*         | 3      | 2      | `sbb` ah,dh               |
| `sbb` [*mem8*],*reg8*       |  16EA  | 2 to 4 | `sbb` [ByteVar],al        |
| `sbb` *reg8*,[*mem8*]       | 9EA    | 2 to 4 | `sbb` al,[sibp18h]        |
| `sbb` *reg16*,*reg16*       | 3      | 2      | `sbb` bx,cx               |
| `sbb` [*mem16*],*reg16*     | 24EA   | 2 to 4 | `sbb` [WordVar2],ax       |
| `sbb` *reg16*,[*mem16*]     | 13EA   | 2 to 4 | `sbb` dx,[si]             |
| `sbb` *reg8*,*immed8*       | 4      | 3      | `sbb` cl,0                |
| `sbb` [*mem8*],*immed8*     | 17EA   | 3 to 5 | `sbb` [ByteVar],20h       |
| `sbb` *reg16*,*sextimmed*   | 4      | 3      | `sbb` dx,40h              |
| `sbb` *reg16*,*immed16*     | 4      | 4      | `sbb` dx,8000h            |
| `sbb` [*mem16*],*sextimmed* | 25EA   | 3 to 5 | `sbb` word ptr [bx],1     |
| `sbb` [*mem16*],*immed16*   | 25EA   | 4 to 6 | `sbb` word ptr [bx],1000h |
| `sbb` al,*immed8*           | 4      | 2      | `sbb` al,10               |
| `sbb` ax,*immed8*           | 4      | 3      | `sbb` ax,1                |

**Notes:**

`sbb` performs a subtraction with borrow, where the source is subtracted from the destination, and then the Carry flag is subtracted from the result. The result replaces the destination. If the result is negative, the Carry flag is set, indicating a borrow. To subtract without taking the Carry flag into account (i.e., without borrowing) use the `sbb` instruction.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

SCAS Scan string
----------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|               | Cycles     | Bytes |               |
|---------------|------------|-------|---------------|
| `scasb`       | 15         | 1     | `scasb`       |
| `repz scasb`  | 9(15\*CX)  | 2     | `repz scasb`  |
| `repnz scasb` | 9(15\*CX)  | 2     | `repnz scasb` |
| `scasw`       | 19         | 1     | `scasw`       |
| `repz scasw`  | 9(19\*CX)  | 2     | `repz scasw`  |
| `repnz scasw` | 9(19\*CX)  | 2     | `repnz scasw` |

**Notes:**

`scas` compares either AL (`scasb`) or AX (`scasw`) to the location pointed to by ES:DI, adjusting DI after the operation, as described below. ES must be the segment of the destination and cannot be overridden. Similarly, DI must always be the destination offset. The comparison is performed via a trial subtraction of the location pointed to by ES:DI from AL or AX; just as with `cmp`, this trial subtraction alters only the flags, not AL/AX or the location pointed to by ES:DI.

By placing an instruction repeat count in CX and preceding `scasb` or `scasw` with the `repz` or `repnz` prefix, it is possible to execute a single `scas` up to 65,535 (0FFFFh) times, just as if that many `scas` instructions had been executed, but without the need for any additional instruction fetching. Repeated `scas` instructions end either when CX counts down to 0 or when the state of the Zero flag specified by `repz`/`repnz` ceases to be true. The Zero flag should be used to determine whether a match/nonmatch was found after `repz scas` or `repnz scas` ends.

Note that if CX is 0 when `repz scas` or `repnz scas` is started, zero repetitions of `scas`not 65,536 repetitionsare performed. After each `scas`, DI is adjusted (as described in the next paragraph) by either 1 (for `scasb`) or 2 (for `scasw`), and, if the `repz` or `repnz` prefix is being used, CX is decremented by 1.

"Adjusting" DI means incrementing DI if the Direction flag is cleared (0) or decrementing DI if the Direction flag is set (1).

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

SHL Shift logical left
----------------------

`SAL Shift arithmetic left`

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                    | Cycles      | Bytes  |                              |
|--------------------|-------------|--------|------------------------------|
| `shl` *reg8*,1     | 2           | 2      | `shl` dl,1                   |
| `shl` [*mem8*],1   | 15EA        | 2      | to 4 `shl` byte ptr [bxsi],1 |
| `shl` *reg16*,1    | 2           | 2      | `shl` cx,1                   |
| `shl` [*mem16*],1  | 23EA        | 2 to 4 | `shl` word ptr [di],1        |
| `shl` *reg8*,cl    | 8(4\*CL)    | 2      | `shl` al,cl                  |
| `shl` [*mem8*],cl  | 20EA(4\*CL) | 2 to 4 | `shl` [ByteVar],cl           |
| `shl` *reg16*,cl   | 8(4\*CL)    | 2      | `shl` bp,cl                  |
| `shl` [*mem16*],cl | 28EA(4\*CL) | 2 to 4 | `shl` [WordVar1],cl          |

**Notes:**

`shl` (also known as `sal`; the two mnemonics refer to the same instruction) shifts the bits within the destination operand to the left, where left is toward the most significant bit, bit 15 for word operands and bit 7 for byte operands. The number of bit positions shifted may either be specified as the literal 1 or by the value in CL (not CX!). It is generally faster to perform sequential shiftbyone instructions for shifts of up to about 4 bits, and faster to use shiftbyCL instructions for longer shifts. Note that while CL may contain any value up to 255, it is meaningless to shift by any value larger than 16, *even though the shifts are actually performed wasting `Cycles` on the 8088*.

The leftmost bit of the operand is shifted into the Carry flag; the rightmost bit is cleared to 0. The Auxiliary Carry flag (AF) becomes undefined after this instruction. OF is modified predictably *only* by the shiftbyone forms of `shl`; after shiftbyCL forms, OF becomes undefined.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

SHR Shift logical right
-----------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                    | Cycles      | Bytes  |                       |
|--------------------|-------------|--------|-----------------------|
| `shr` *reg8*,1     | 2           | 2      | `shr` al,1            |
| `shr` [*mem8*],1   | 15EA        | 2 to 4 | `shr` [ByteVar],1     |
| `shr` *reg16*,1    | 2           | 2      | `shr` bx,1            |
| `shr` [*mem16*],1  | 23EA        | 2 to 4 | `shr` word ptr [si],1 |
| `shr` *reg8*,cl    | 8(4\*CL)    | 2      | `shr` dl,cl           |
| `shr` [*mem8*],cl  | 20EA(4\*CL) | 2 to 4 | `shr` [ByteVarbx],cl  |
| `shr` *reg16*,cl   | 8(4\*CL)    | 2      | `shr` si,cl           |
| `shr` [*mem16*],cl | 28EA(4\*CL) | 2 to 4 | `shr` [WordVarsi],cl  |

**Notes:**

`shr` shifts the bits within the destination operand to the right, where right is toward the least significant bit, bit 0. The number of bit positions shifted may either be specified as the literal 1 or by the value in CL (not CX!). It is generally faster to perform sequential shiftbyone instructions for shifts of up to about four bits, and faster to use shiftbyCL instructions for longer shifts. Note that while CL may contain any value up to 255, it is meaningless to shift by any value larger than 16, *even though the shifts are actually performed wasting `Cycles` on the 8088*.

The rightmost bit of the operand is shifted into the Carry flag; the leftmost bit is cleared to 0. The Auxiliary Carry flag (AF) becomes undefined after this instruction. OF is modified predictably *only* by the shiftbyone forms of `shr`; after shiftbyCL forms, OF becomes undefined.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

STC Set Carry flag
------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `stc` | 2      | 1     | `stc` |

**Notes:**

`stc` sets the Carry flag (CF) to 1. `stc` can be useful for returning a status in the Carry flag from a subroutine, or for presetting the Carry flag before `adc`, `sbb`, or a conditional jump that tests the Carry flag, such as `jc`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

STD Set Direction flag
----------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `std` | 2      | 1     | `std` |

**Notes:**

`std` sets the Direction flag (DF) to the set (1) state. This affects the pointerregister adjustments performed after each memory access by the string instructions `lods`, `stos`, `scas`, `movs`, and `cmps`. When DF=0, pointer registers (SI and/or DI) are incremented by 1 or 2; when DF=1, pointer registers are decremented by 1 or 2. DF is set to 0 by `cld`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

STI Set Interrupt flag
----------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|       | Cycles | Bytes |       |
|-------|--------|-------|-------|
| `sti` | 2      | 1     | `sti` |

**Notes:**

`sti` sets the Interrupt flag (IF) to the set (1) state, allowing maskable hardware interrupts (IRQ0 through IRQ7) to occur. (Software interrupts via `int` are not affected by the state of IF.) Both `cli` and `int` clear the Interrupt flag to 0, disabling maskable hardware interrupts.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

STOS Store string
-----------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|             | Cycles    | Bytes |             |
|-------------|-----------|-------|-------------|
| `stosb`     | 11        | 1     | `stosb`     |
| `rep stosb` | 9(10\*CX) | 2     | `rep stosb` |
| `stosw`     | 15        | 1     | `stosw`     |
| `rep stosw` | 9(14\*CX) | 2     | `rep stosw` |

**Notes:**

`stos` stores either AL (`stosb`) or AX (`stosw`) to the location pointed to by ES:DI, adjusting DI after the operation, as described below. ES must be the segment of the destination and cannot be overridden. Similarly, DI must always be the destination offset.

By placing an instruction repeat count in CX and preceding `stosb` or `stosw` with the `rep` prefix, it is possible to execute a single `stos` up to 65,535 (0FFFFh) times, just as if that many `stos` instructions had been executed, but without the need for any additional instruction fetching. Note that if CX is 0 when `rep stos` is started, zero repetitions of `stos`not 65,536 repetitionsare performed. After each `stos`, DI is adjusted (as described in the next paragraph) by either 1 (for `stosb`) or 2 (for `stosw`), and, if the `rep` prefix is being used, CX is decremented by 1.

"Adjusting" DI means incrementing DI if the Direction flag is cleared (0) or decrementing DI if the Direction flag is set (1).

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

SUB Arithmetic subtraction (no borrow)
--------------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                             | Cycles | Bytes  |                          |
|-----------------------------|--------|--------|--------------------------|
| `sub` *reg8*,*reg8*         | 3      | 2      | `sub` al,dl              |
| `sub` [*mem8*],*reg8*       | 16EA   | 2 to 4 | `sub` [ByteVar],ah       |
| `sub` *reg8*,[*mem8*]       | 9EA    | 2 to 4 | `sub` dl,[si1]           |
| `sub` *reg16*,*reg16*       | 3      | 2      | `sub` ax,dx              |
| `sub` [*mem16*],*reg16*     | 24EA   | 2 to 4 | `sub` [WordVar],ax       |
| `sub` *reg16*,[*mem16*]     | 13EA   | 2 to 4 | `sub` cx,[dibp]          |
| `sub` *reg8*,*immed8*       | 4      | 3      | `sub` dl,10h             |
| `sub` [*mem8*],*immed8*     | 17EA   | 3 to 5 | `sub` [ByteVar],01h      |
| `sub` *reg16*,*sextimmed*   | 4      | 3      | `sub` dx,1               |
| `sub` *reg16*,*immed16*     | 4      | 4      | `sub` dx,80h             |
| `sub` [*mem16*],*sextimmed* | 25EA   | 3 to 5 | `sub` word ptr [bp],10h  |
| `sub` [*mem16*],*immed16*   | 25EA   | 4 to 6 | `sub` word ptr [bp],100h |
| `sub` al,*immed8*           | 4      | 2      | `sub` al,20h             |
| `sub` ax,*immed16*          | 4      | 3      | `sub` ax,100h            |

**Notes:**

`sub` performs a subtraction without borrow, where the source is subtracted from the destination; the result replaces the destination. If the result is negative, the Carry flag is set, indicating a borrow. Multiple precision subtraction can be performed by following `sub` with `sbb` subtract with borrowwhich takes the Carry flag into account as a borrow.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

TEST Compare by anding without saving result
--------------------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                            | Cycles | Bytes  |                            |
|----------------------------|--------|--------|----------------------------|
| `test` *reg8*,*reg8*       | 3      | 2      | `test` dl,bl               |
| `test` [*mem8*],*reg8*     | 9EA    | 2 to 4 | `test` [si],al             |
| `test` *reg8*,[*mem8*]     | 9EA    | 2 to 4 | `test` dh,[bx]             |
| `test` *reg16*,*reg16*     | 3      | 2      | `test` si,cx               |
| `test` [*mem16*],*reg16*   | 13EA   | 2 to 4 | `test` [WordVar],dx        |
| `test` *reg16*,[*mem16*]   | 13EA   | 2 to 4 | `test` ax,[bx2]            |
| `test` *reg8*,*immed8*     | 5      | 3      | `test` bh,040h             |
| `test` [*mem8*],*immed8*   | 11EA   | 3 to 5 | `test` byte ptr [di],44h   |
| `test` *reg16*,*immed16*   | 5      | 4      | `test` bx,08080h           |
| `test` [*mem16*],*immed16* | 15EA   | 4 to 6 | `test` word ptr [bp],0101h |
| `test` al,*immed8*         | 4      | 2      | `test` al,0f7h             |
| `test` ax,*immed16*        | 4      | 3      | `test` ax,09001h           |

**Notes:**

`test` performs the logical operation "and" on its two operands, but does not store the result. The "and" operation is performed on a bitby bit basis, such that bit 0 of the source is anded with bit 0 of the destination, bit 1 of the source is anded with bit 1 of the destination, and so on. The "and" operation yields a 1 if *both* of the operands are 1, and a 0 if *either* operand is 0. Note that `test` makes the Auxiliary Carry flag undefined. CF and OF are cleared to 0, and the other affected flags are set according to the operation's results. Note also that the ordering of the operands doesn't matter; `test al,[bx]` and `test [bx],al` function identically.

Unlike `and`, `test` cannot store signextendable 16bit values as bytes, then signextend them to words at execution time.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

WAIT Wait for interrupt or test signal
--------------------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|        | Cycles | Bytes |        |
|--------|--------|-------|--------|
| `wait` | 3      | 1     | `wait` |

**Notes:**

`wait` stops the 8088 until either a hardware interrupt occurs or the signal on the 8088's TEST pin becomes true. `wait` is often used for synchronization with coprocessors, notably the 8087, to make sure that the coprocessor has finished its current instruction before starting another coprocessor instruction and/or to make sure that memory variables aren't accessed out of sequence by different processors. Note that when a hardware interrupt occurs during `wait`, the `iret` that ends that interrupt returns to the `wait` instruction, not the following instruction. Also note that 3 is the minimum number of `Cycles` that `wait` can take, in the case where the signal on the TEST pin is already true; the actual number of `Cycles` can be much higher, depending on the coprocessor.

Also known as `fwait`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

XCHG Exchange operands
----------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                          | Cycles | Bytes  |                     |
|--------------------------|--------|--------|---------------------|
| `xchg` *reg8*,*reg8*     | 4      | 2      | `xchg` al,ah        |
| `xchg` [*mem8*],*reg8*   | 17EA   | 2 to 4 | `xchg` [ByteVar],dl |
| `xchg` *reg8*,[*mem8*]   | 17EA   | 2 to 4 | `xchg` dh,[ByteVar] |
| `xchg` *reg16*,*reg16*   | 4      | 2      | `xchg` dx,bx        |
| `xchg` [*mem16*],*reg16* | 25EA   | 2 to 4 | `xchg` [bx],cx      |
| `xchg` *reg16*,[*mem16*] | 25EA   | 2 to 4 | `xchg` ax,[bx]      |
| `xchg` ax,*reg16*        | 3      | 1      | `xchg` ax,bx        |

**Notes:**

`xchg` exchanges the contents of its two operands. Note that the ordering of the operands doesn't matter; `xchg al,ah` and `xchg ah,al` function identically.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

XLAT Translate from table
-------------------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|     |     |     |     |     |     |     |     |     | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|        | Cycles | Bytes |        |
|--------|--------|-------|--------|
| `xlat` | 11     | 1     | `xlat` |

**Notes:**

`xlat` loads into AL the byte of memory addressed by the sum of BX and AL. `xlat` defaults to accessing the segment pointed to by DS, but this can be overridden with a segment override prefix.

Also known as `xlatb`.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

XOR Exclusive or
----------------

Table: Flags affected

|     |     |     |     |     |     |     |     |     |                     |                      |                      |
|-----|-----|-----|-----|-----|-----|-----|-----|-----|---------------------|----------------------|----------------------|
| `O` | `D` | `I` | `T` | `S` | `Z` | `A` | `P` | `C` | `OF`: Overflow flag | `DF`: Direction flag | `IF`: Interrupt flag |
| `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `F` | `TF`: Trap flag     | `SF`: Sign flag      | `ZF`: Zero flag      |
|  *  |     |     |     |  *  |  *  |  *  |  *  |  *  | `AF`: Aux carry     | `PF`: Parity flag    | `CF`: Carry flag     |


Table: Instruction forms

|                             | Cycles | Bytes  |                          |
|-----------------------------|--------|--------|--------------------------|
| `xor` *reg8*,*reg8*         | 3      | 2      | `xor` dh,dl              |
| `xor` [*mem8*],*reg8*       | 16EA   | 2 to 4 | `xor` [ByteVar],bh       |
| `xor` *reg8*,[*mem8*]       | 9EA    | 2 to 4 | `xor` al,[si]            |
| `xor` *reg16*,*reg16*       | 3      | 2      | `xor` ax,ax              |
| `xor` [*mem16*],*reg16*     | 24EA   | 2 to 4 | `xor` [WordVar1],bp      |
| `xor` *reg16*,[*mem16*]     | 13EA   | 2 to 4 | `xor` si,[di]            |
| `xor` *reg8*,*immed8*       | 4      | 3      | `xor` al,1               |
| `xor` [*mem8*],*immed8*     | 17EA   | 3 to 5 | `xor` [ByteVar],11h      |
| `xor` *reg16*,*sextimmed*   | 4      | 3      | `xor` bx,1               |
| `xor` *reg16*,*immed16*     | 4      | 4      | `xor` bx,2222h           |
| `xor` [*mem16*],*sextimmed* | 25EA   | 3 to 5 | `xor` word ptr [bx],17h  |
| `xor` [*mem16*],*immed16*   | 25EA   | 4 to 6 | `xor` word ptr [bx],100h |
| `xor` al,*immed8*           | 4      | 2      | `xor` al,33h             |
| `xor` ax,*immed16*          | 4      | 3      | `xor` ax,0cccch          |

**Notes:**

`xor` performs an "exclusive or" logical operation between its two operands. Once the operation is complete, the result replaces the destination operand. `xor` is performed on a bitby bit basis, such that bit 0 of the source is exclusive ored with bit 0 of the destination, bit 1 of the source is exclusive ored with bit 1 of the destination, and so on. The "exclusive or" operation yields a 1 if the operands are different, and a 0 if the operands are the same. Note that `xor` makes the Auxiliary Carry flag undefined. CF and OF are cleared to 0, and the other affected flags are set according to the operation's results.

`reg8` = AL AH BL BH CL CH DL DH

`reg16` = AX BX CX DX BP SP SI DI

`[mem8]` = 8bit memory data

`[mem16]` = 16bit memory data

`immed8` = 8bit immediate data

`immed16` = 16bit immediate data

`sextimmed` = 8bit signextendable value

`segreg` = CS DS SS ES

`disp8` = 8bit branch displacement

`[mem32]` = 32bit memory data

`disp16` = 16bit branch displacement

`[mem]` = memory data of any size

`segment:offset` = 32bit segment:offset address

[`APPENDIX B: ASCII Table And PC Character Set`](#TAPPB)
==========================================================

`Dec`

`Hex`

`Binary`

`Char`

`Name`

0

00

00000000

NUL

Null

1

01

00000001

STX

Start of Header

2

02

00000010

SOT

Start of Text

3

03

00000011

ETX

End of Text

4

04

00000100

EOT

End of Transmission

5

05

00000101

ENQ

Enquiry

6

06

00000110

ACK

Acknowledge

7

07

00000111

BEL

Bell

8

08

00001000

BS

BackSpace

9

09

00001001

HT

Horizontal Tabulation

10

0A

00001010

LF

Line Feed

11

0B

00001011

VT

Vertical Tabulation

12

0C

00001100

FF

Form Feed

13

0D

00001101

CR

Carriage Return

14

0E

00001110

SO

Shift Out

15

0F

00001111

SI

Shift In

16

10

00010000

DLE

Data Link Escape

17

11

00010001

DC1

Device Control 1 (XON)

18

12

00010010

DC2

Device Control 2

19

13

00010011

DC3

Device Control 3 (XOFF)

20

14

00010100

DC4

Device Control 4

21

15

00010101

NAK

Negative acknowledge

22

16

00010110

SYN

Synchronous Idle

23

17

00010111

ETB

End of Transmission Block

24

18

00011000

CAN

Cancel

25

19

00011001

EM

End of Medium

26

1A

00011010

SUB

Substitute

27

1B

00011011

ESC

Escape

28

1C

00011100

FS

File Separator

29

1D

00011101

GS

Group Separator

30

1E

00011110

RS

Record Separator

31

1F

00011111

US

Unit Separator

32

20

00100000

[Space]

Space

33

21

00100001

!

Exclamation mark

34

22

00100010

"

Quotes

35

23

00100011

\#

Hash

36

24

00100100

$

Dollar

37

25

00100101

%

Percent

38

26

00100110

&

Ampersand

39

27

00100111

'

Apostrophe

40

28

00101000

(

Open bracket

41

29

00101001

)

Close bracket

42

2A

00101010

\*

Asterisk

43

2B

00101011

+

Plus

44

2C

00101100

,

Comma

45

2D

00101101

-

Dash

46

2E

00101110

.

Full stop

47

2F

00101111

/

Slash

48

30

00110000

0

Zero

49

31

00110001

1

One

50

32

00110010

2

Two

51

33

00110011

3

Three

52

34

00110100

4

Four

53

35

00110101

5

Five

54

36

00110110

6

Six

55

37

00110111

7

Seven

56

38

00111000

8

Eight

57

39

00111001

9

Nine

58

3A

00111010

:

Colon

59

3B

00111011

;

Semi-colon

60

3C

00111100

<

Less than

61

3D

00111101

=

Equals

62

3E

00111110

\>

Greater than

63

3F

00111111

?

Question mark

64

40

01000000

@

At

65

41

01000001

A

Uppercase A

66

42

01000010

B

Uppercase B

67

43

01000011

C

Uppercase C

68

44

01000100

D

Uppercase D

69

45

01000101

E

Uppercase E

70

46

01000110

F

Uppercase F

71

47

01000111

G

Uppercase G

72

48

01001000

H

Uppercase H

73

49

01001001

I

Uppercase I

74

4A

01001010

J

Uppercase J

75

4B

01001011

K

Uppercase K

76

4C

01001100

L

Uppercase L

77

4D

01001101

M

Uppercase M

78

4E

01001110

N

Uppercase N

79

4F

01001111

O

Uppercase O

80

50

01010000

P

Uppercase P

81

51

01010001

Q

Uppercase Q

82

52

01010010

R

Uppercase R

83

53

01010011

S

Uppercase S

84

54

01010100

T

Uppercase T

85

55

01010101

U

Uppercase U

86

56

01010110

V

Uppercase V

87

57

01010111

W

Uppercase W

88

58

01011000

X

Uppercase X

89

59

01011001

Y

Uppercase Y

90

5A

01011010

Z

Uppercase Z

91

5B

01011011

[

Open square bracket

92

5C

01011100

\Backslash

93

5D

01011101

]

Close square bracket

94

5E

01011110

\^

Caret / hat

95

5F

01011111

\_

Underscore

96

60

01100000

\`

Grave accent

97

61

01100001

a

Lowercase a

98

62

01100010

b

Lowercase b

99

63

01100011

c

Lowercase c

100

64

01100100

d

Lowercase d

101

65

01100101

e

Lowercase e

102

66

01100110

f

Lowercase f

103

67

01100111

g

Lowercase g

104

68

01101000

h

Lowercase h

105

69

01101001

i

Lowercase i

106

6A

01101010

j

Lowercase j

107

6B

01101011

k

Lowercase k

108

6C

01101100

l

Lowercase l

109

6D

01101101

m

Lowercase m

110

6E

01101110

n

Lowercase n

111

6F

01101111

o

Lowercase o

112

70

01110000

p

Lowercase p

113

71

01110001

q

Lowercase q

114

72

01110010

r

Lowercase r

115

73

01110011

s

Lowercase s

116

74

01110100

t

Lowercase t

117

75

01110101

u

Lowercase u

118

76

01110110

v

Lowercase v

119

77

01110111

w

Lowercase w

120

78

01111000

x

Lowercase x

121

79

01111001

y

Lowercase y

122

7A

01111010

z

Lowercase z

123

7B

01111011

{

Open brace

124

7C

01111100

|

Pipe

125

7D

01111101

}

Close brace

126

7E

01111110

\~

Tilde

127

7F

01111111

DEL

Delete

128

80

10000000

Ç

latin capital letter c with cedilla

129

81

10000001

ü

latin small letter u with diaeresis

130

82

10000010

é

latin small letter e with acute

131

83

10000011

â

latin small letter a with circumflex

132

84

10000100

ä

latin small letter a with diaeresis

133

85

10000101

à

latin small letter a with grave

134

86

10000110

å

latin small letter a with ring above

135

87

10000111

ç

latin small letter c with cedilla

136

88

10001000

ê

latin small letter e with circumflex

137

89

10001001

ë

latin small letter e with diaeresis

138

8A

10001010

è

latin small letter e with grave

139

8B

10001011

ï

latin small letter i with diaeresis

140

8C

10001100

î

latin small letter i with circumflex

141

8D

10001101

ì

latin small letter i with grave

142

8E

10001110

Ä

latin capital letter a with diaeresis

143

8F

10001111

Å

latin capital letter a with ring above

144

90

10010000

É

latin capital letter e with acute

145

91

10010001

æ

latin small ligature ae

146

92

10010010

Æ

latin capital ligature ae

147

93

10010011

ô

latin small letter o with circumflex

148

94

10010100

ö

latin small letter o with diaeresis

149

95

10010101

ò

latin small letter o with grave

150

96

10010110

û

latin small letter u with circumflex

151

97

10010111

ù

latin small letter u with grave

152

98

10011000

ÿ

latin small letter y with diaeresis

153

99

10011001

Ö

latin capital letter o with diaeresis

154

9A

10011010

Ü

latin capital letter u with diaeresis

155

9B

10011011

¢

cent sign

156

9C

10011100

£

pound sign

157

9D

10011101

¥

yen sign

158

9E

10011110

₧

peseta sign

159

9F

10011111

ƒ

latin small letter f with hook

160

A0

10100000

á

latin small letter a with acute

161

A1

10100001

í

latin small letter i with acute

162

A2

10100010

ó

latin small letter o with acute

163

A3

10100011

ú

latin small letter u with acute

164

A4

10100100

ñ

latin small letter n with tilde

165

A5

10100101

Ñ

latin capital letter n with tilde

166

A6

10100110

ª

feminine ordinal indicator

167

A7

10100111

º

masculine ordinal indicator

168

A8

10101000

¿

inverted question mark

169

A9

10101001

⌐

reversed not sign

170

AA

10101010

¬

not sign

171

AB

10101011

½

vulgar fraction one half

172

AC

10101100

¼

vulgar fraction one quarter

173

AD

10101101

¡

inverted exclamation mark

174

AE

10101110

«

left-pointing double angle quotation mark

175

AF

10101111

»

right-pointing double angle quotation mark

176

B0

10110000

░

light shade

177

B1

10110001

▒

medium shade

178

B2

10110010

▓

dark shade

179

B3

10110011

│

box drawings light vertical

180

B4

10110100

┤

box drawings light vertical and left

181

B5

10110101

╡

box drawings vertical single and left double

182

B6

10110110

╢

box drawings vertical double and left single

183

B7

10110111

╖

box drawings down double and left single

184

B8

10111000

╕

box drawings down single and left double

185

B9

10111001

╣

box drawings double vertical and left

186

BA

10111010

║

box drawings double vertical

187

BB

10111011

╗

box drawings double down and left

188

BC

10111100

╝

box drawings double up and left

189

BD

10111101

╜

box drawings up double and left single

190

BE

10111110

╛

box drawings up single and left double

191

BF

10111111

┐

box drawings light down and left

192

C0

11000000

└

box drawings light up and right

193

C1

11000001

┴

box drawings light up and horizontal

194

C2

11000010

┬

box drawings light down and horizontal

195

C3

11000011

├

box drawings light vertical and right

196

C4

11000100

─

box drawings light horizontal

197

C5

11000101

┼

box drawings light vertical and horizontal

198

C6

11000110

╞

box drawings vertical single and right double

199

C7

11000111

╟

box drawings vertical double and right single

200

C8

11001000

╚

box drawings double up and right

201

C9

11001001

╔

box drawings double down and right

202

CA

11001010

╩

box drawings double up and horizontal

203

CB

11001011

╦

box drawings double down and horizontal

204

CC

11001100

╠

box drawings double vertical and right

205

CD

11001101

═

box drawings double horizontal

206

CE

11001110

╬

box drawings double vertical and horizontal

207

CF

11001111

╧

box drawings up single and horizontal double

208

D0

11010000

╨

box drawings up double and horizontal single

209

D1

11010001

╤

box drawings down single and horizontal double

210

D2

11010010

╥

box drawings down double and horizontal single

211

D3

11010011

╙

box drawings up double and right single

212

D4

11010100

╘

box drawings up single and right double

213

D5

11010101

╒

box drawings down single and right double

214

D6

11010110

╓

box drawings down double and right single

215

D7

11010111

╫

box drawings vertical double and horizontal single

216

D8

11011000

╪

box drawings vertical single and horizontal double

217

D9

11011001

┘

box drawings light up and left

218

DA

11011010

┌

box drawings light down and right

219

DB

11011011

█

full block

220

DC

11011100

▄

lower half block

221

DD

11011101

▌

left half block

222

DE

11011110

▐

right half block

223

DF

11011111

▀

upper half block

224

E0

11100000

α

greek small letter alpha

225

E1

11100001

ß

latin small letter sharp s

226

E2

11100010

Γ

greek capital letter gamma

227

E3

11100011

π

greek small letter pi

228

E4

11100100

Σ

greek capital letter sigma

229

E5

11100101

σ

greek small letter sigma

230

E6

11100110

µ

micro sign

231

E7

11100111

τ

greek small letter tau

232

E8

11101000

Φ

greek capital letter phi

233

E9

11101001

Θ

greek capital letter theta

234

EA

11101010

Ω

greek capital letter omega

235

EB

11101011

δ

greek small letter delta

236

EC

11101100

∞

infinity

237

ED

11101101

φ

greek small letter phi

238

EE

11101110

ε

greek small letter epsilon

239

EF

11101111

∩

intersection

240

F0

11110000

≡

identical to

241

F1

11110001

±

plus-minus sign

242

F2

11110010

≥

greater-than or equal to

243

F3

11110011

≤

less-than or equal to

244

F4

11110100

⌠

top half integral

245

F5

11110101

⌡

bottom half integral

246

F6

11110110

÷

division sign

247

F7

11110111

≈

almost equal to

248

F8

11111000

°

degree sign

249

F9

11111001

∙

bullet operator

250

FA

11111010

·

middle dot

251

FB

11111011

√

square root

252

FC

11111100

ⁿ

superscript latin small letter n

253

FD

11111101

²

superscript two

254

FE

11111110

■

black square

255

FF

11111111

no-break space

* * * * *
