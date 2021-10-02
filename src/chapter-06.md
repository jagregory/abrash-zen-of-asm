# Chapter 6: The 8088

## An Overview of the 8088

In a nutshell, the 8088 is a 16-bit processor with an 8-bit data bus capable of addressing 1 Mb of memory in total but no more than four 64Kb byte blocks at a time and that via a remarkably awkward segmented memory scheme. The register space is limited, but the instruction set is powerful and flexible, albeit highly irregular. The 4.77-MHz clock speed of the 8088 as implemented in the IBM PC is slow by today's standards, and both instruction execution and memory access are relatively slow as well. What the whole 8088 package as used in the PC amounts to is a fairly low-performance processor that is hard to program.

Why am I saying such unflattering things about the 8088? Because I want you to understand how hard it is to write good 8088 code. As you may have guessed, there is a saving grace to the 8088; as implemented in the PC the 8088 can support just enough performance and memory to run some splendid software—software carefully crafted to work around the 8088's weaknesses and take maximum advantage of its strengths. Those strengths and weaknesses lie hidden in the 8088's instruction set, and we will spend the rest of this book ferreting them out.

Before we begin, you must understand one thing; the 8088 is a hodgepodge of a processor. Not a *random* hodgepodge, mind you—there are good reasons why the 8088 is what it is—but a hodgepodge nonetheless. Internally, the 8088 is a 16-bit processor, thanks to its derivation from the 8086, as discussed in Chapter 3. Externally, the 8088 is an 8-bit processor, owing to its genesis in the 1970s, when the cost difference between 8- and 16-bit buses was significant. The design of the 8086, including the register set and several instructions, was heavily influenced by the 8-bit 8080 processor, as we'll see in Chapter 8. Finally, the memory architecture of the 8088 is a remnant of an era when both chip space and the number of pins per chip were severely limited and memory was extremely expensive. The 8088 is an excellent representative of the transitional state of the microcomputer industry a decade ago; striving for state-of-the-art while maintaining a link with the past, all in too little silicon. From a programmer's perspective, though, the 8088 is simply a bit of a mess.

That certainly doesn't mean the 8088 isn't worth bothering with nowadays, as attested by 10 million or so 8088-based computers. It does, however, mean that programming the 8088 properly in assembler is not simple, since code that takes maximum advantage of the unique nature of the 8088 is generally much faster than code that uses the processor in a straightforward manner. We must take the time to understand the strengths and weaknesses of the 8088 intimately, then learn how to best structure our code in light of that knowledge.

## Resources of the 8088

Over the next nine chapters, we'll look at the capabilities and resources of the 8088. We'll learn a great deal about high-performance assembler programming, and we'll also lay the groundwork for the higher level assembler programming techniques of Volume II.

We'll spend the remainder of this chapter looking at the registers and flags of the 8088. In Chapter 7 we'll cover the 8088's memory-addressing capabilities, and in Chapter 8 we'll start to cover the 8088's large and varied instruction set. The resources of the 8088 are both fascinating and essential, for in their infinite permutations and combinations—they are your set of tools for creating the best possible code for the IBM PC.

## Registers

The register set of a processor is a key to understanding the processor's personality, since registers are typically where most of the action in a processor takes place. The 8088's register set is something of a mixed bag. Since the 8088 is a 16-bit processor internally, register-only instructions (instructions without memory operands) tend to be fast and compact, so the 8088's registers are no more regular than anything else about the processor. Each register offers unique, specialized (and hard to remember) functions; together, these oddball register functions make up what my friend and editor Jeff Duntemann calls "the register hidden agenda," the not obvious but powerful register capabilities that considerably increase both the difficulty and the potential power of 8088 assembler programming.

Let me give you an example. Many years ago, a friend who had just made the transition from programming the Apple II to programming the IBM PC, had a program that crashed every so often for no apparent reason. We spent a good deal of time examining his program before we could isolate the cause of his problems. As it turned out, he was using SP as a working register for short stretches, storing values in it, performing arithmetic with it, and all-in-all using SP as if it were just another general-purpose register.

While SP can theoretically be used as a general-purpose register, in fact it is almost always dedicated to maintaining the stack. My friend's problem was that keyboard and timer interrupts, which use the stack, were occurring while he had SP loaded with values that didn't point to a valid stack, so interrupts were pushing return addresses and flags into random areas of memory. When I asked him how he could possibly have made such an obvious mistake, he explained that his approach would have worked perfectly well on the Apple II, where there are no interrupts.

There are two important points here. One is by not understanding SP's portion of the register hidden agenda—the role of SP as a stack pointer in an interrupt-driven system—my friend had wasted considerable development time. The second point is that, had he understood the register hidden agenda better, he could have extended his odd approach to generate some genuinely innovative code.

How? Well, SP really is a general purpose register when it's not being used to maintain a stack. My friend's mistake had been his assumption that the stack is inactive when no calls, returns, pushes, or pops are occurring; this assumption is incorrect because interrupts may take place at any time. Suppose, though, that he had simply disabled interrupts for those brief periods when he needed an eighth general-purpose register for speed. Why, then his use of SP would have been not only acceptable but nearly brilliant!

Alas, disabling interrupts and using SP would not have been truly brilliant, for nonmaskable interrupts, used to signal parity errors and used by some display adapters as well, can occur and use the stack even when interrupts are disabled. In general, I recommend that you not use SP as a general-purpose register, even with interrupts disabled. Although the chances of a nonmaskable interrupt occurring are slim, they are nonetheless real.

All of which simply serves to reinforce the notion that the more we know about the 8088, the better our code will be. That's why we'll cover the 8088's other resources for most of the rest of this volume. The more thorough your understanding of the 8088, the greater the potential of your assembler code.

## The 8088's Register Set

Figure 6.1 shows the 8088's register set to be a mix of general and special-purpose registers. The 8088 offers only seven truly general-purpose

![**Figure 6.1** The 8088's register set.](images/fig6.1RT.png)

registers—AX, BX, CX, DX, SI, DI, and BP—a small set that seems even smaller because four of these registers double as memory-addressing registers and because the slow speed of memory assess dictates use of registers whenever possible. Only certain registers can be used for many functions; for example, only BX, BP, SI, and DI can be used to generate memory-addressing offsets, and then only in certain combinations. Likewise, only AX, BX, CX, and DX can be accessed as either as single 16-bit registers or paired 8-bit registers.

Let's take a quick tour of the registers, looking at the unique capabilities of each.

## The General-Purpose Registers

Any of the eight general-purpose registers—AX, BX, CX, DX, SI, DI, BP, or SP—may serve as an operand to virtually any instruction that accepts operands, such as `add`{.nasm}, `push`{.nasm}, `shl`{.nasm}, or `call`{.nasm}. Put another way, any general-purpose register may be used as an operand by any instruction that uses mod-reg-rm addressing, the most commonly-used addressing mode of the 8088, which we'll discuss in the next chapter. Most of the logical, arithmetic, and data movement operations of the 8088 can use any of the general-purpose registers, and it is the general-purpose registers that are most often used as instruction operands.

Four of the eight general-purpose registers—AX, BX, CX, DX—can be accessed either as paired 8-bit registers or as single 16-bit registers. For example, the upper byte of BX can be accessed as BH for 8-bit operations, and the lower byte can be accessed as BL. The eight 8-bit general-purpose registers—AH, AL, BH, BL, CH, CL, DH, and DL—can be used as 8-bit operands with any instructions that use *mod-reg-rm* addressing, just as the eight 16-bit general-purpose registers can be used as 16-bit operands with those instructions.

### The AX register

The AX register is the 16-bit accumulator. The lower byte of AX can be accessed as the AL register, which is the 8-bit accumulator; the upper byte of AX can be accessed as the AH register, which is not an accumulator of any sort. The accumulator is always both one of the source operands and the destination for multiply and divide instructions. The accumulator must also be the source for `out`{.nasm} instructions and the destination for `in`{.nasm} instructions, and is the source or destination register for the string instructions `lods`{.nasm}, `stos`{.nasm}, and `scas`{.nasm}, as we'll see in Chapter 10. There are special instructions for sign-extending the accumulator to larger data types; `cbw`{.nasm} for converting a signed byte in AL to a signed word in AX, and `cwd`{.nasm} for converting a signed word in AX to a signed doubleword in DX:AX. Finally, there are a number of accumulator-specific instructions that are particularly efficient; we'll discuss those instructions in Chapters 8 and 9.

There are several instructions that use part or all of the AX register in odd ways. In Chapter 7 we'll discuss `xlat`{.nasm}, the only instruction that can use AL for memory addressing. In Chapter 8 we'll discuss `lahf`{.nasm} and `sahf`{.nasm}, which transfer the lower byte of the flags register to and from AH. In Chapter 8 we'll also discuss a special form of `xchg`{.nasm} that requires that AX be one operand. Finally, the decimal- and ASCII-adjust instructions—`aaa`{.nasm}, `aad`{.nasm}, `aam`{.nasm}, `aas`{.nasm}, `daa`{.nasm}, and `das`{.nasm}—alter AL or AX in specific ways to compensate for the effects of ASCII or BCD arithmetic. These instructions are so different from the other members of the 8088 instruction set that we'll defer further discussion of them until Chapter 9.

### The BX register

The BX register is the only register among the dual 8/16-bit registers that can be used for memory addressing (with the sole exception of AL in the case of `xlat`{.nasm}). The lower byte of BX is accessible as BL and the upper byte is accessible as BH; neither BH nor BL alone can be used for memory addressing.

Like the other general-purpose registers, BX (or BH or BL) may serve as an operand to any instruction that uses *mod-reg-rm* addressing. In addition, BX (but not BH or BL) can be used as a base register for memory addressing. That is, the contents of BX can be used to generate the address of a memory operand, as discussed in the next chapter, by any instruction that uses *mod-reg-rm* addressing, and by `xlat`{.nasm} as well.

### The CX register

The CX register is designed for specialized counting purposes. The lower byte of CX is accessible as CL and the upper byte as CH; CL can be used for certain specialized 8-bit counting purposes, but CH cannot. CX is used as a counter by the `loop`{.nasm}, `loopz`{.nasm}, `loopnz`{.nasm}, and `jcxz`{.nasm} instructions, which we'll look at in Chapter 14, and is also used as a counter by the string instructions when they're used with the `rep`{.nasm} prefix, as we'll see in Chapter 10, CL can be used to specify a rotation or shift count for any of the rotate or shift instructions, such as`ror`{.nasm}, `shl`{.nasm}, and `rcl`{.nasm}, as described in Chapter 9.

### The DX register

The DX register is the least specialized of the general-purpose registers; the only unique functions of DX are serving as the upper word of the destination on 16-bit by 16-bit multiplies, serving as the upper word of the source and the destination for the remainder on 32-bit by 16-bit divides, addressing I/O ports when used with `in`{.nasm} and `out`{.nasm}, and serving as the upper word of the destination for `cbw`{.nasm}. The lower byte of DX is accessible as DL, and the upper byte is accessible as DH.

### The SI register

The SI register specializes as the source memory-addressing register for the string instructions `lods`{.nasm} and `mob`{.nasm} and as the destination memory-addressing register for the string instruction `cmps`{.nasm}, as we'll see in Chapter 10.

Like the other general-purpose registers, SI may serve as an operand to any instruction that uses *mod-reg-rm* addressing. In addition, SI can be used as an index register for memory addressing by any instruction that uses *mod-reg-rm* addressing, as we'll see in the next chapter, and, of course, by the above-mentioned string instructions as well.

### The DI register

The DI register Specializes as the destination memory-addressing register for the string instructions `stos`{.nasm} and `movs`{.nasm}, and as the source memory-addressing register for the string instructions `scas`{.nasm} and `cmps`{.nasm}, as we'll see in Chapter 10.

Like the other general-purpose registers, DI may serve as an operand to any instruction that uses *mod-reg-rm* addressing. In addition, DI can be used as an index register for memory addressing by any instruction that uses *mod-reg-rm* addressing, as we'll see in the next chapter, and by the above-mentioned string instructions as well.

### The BP register

The BP register specializes as the stack frame-addressing register. Like the other general-purpose registers, BP may serve as an operand to any instruction that uses *mod-reg-rm* addressing. Like BX, BP can also be used as a base register for memory addressing by any instruction that uses *mod-reg-rm* addressing, as discussed in the next chapter. However, while BX normally addresses the data segment, BP normally addresses the stack segment. This makes BP ideal for addressing parameters and temporary variables stored in stack frames, a topic to which we'll return in the next chapter.

### The SP register

The SP register is technically a general-purpose register, but in actual practice it almost always serves as the highly specialized stack pointer, and is rarely used as a general-purpose register. SP points to the offset of the top of the stack in the stack segment, and is automatically incremented and decremented as the stack is accessed via `push`{.nasm}, `pop`{.nasm}, `call`{.nasm}, `ret`{.nasm}, `int`{.nasm}, and `iret`{.nasm} instructions.

Like the other general-purpose registers, SP may serve as an operand to any instruction that uses *mod-reg-rm* addressing. In general, SP is modified through the above-mentioned stack-oriented instructions, but SP also may be subtracted from, added to, or loaded directly in order to allocate or deallocate a temporary storage block on the stack or switch to a new stack.

One note: never push SP directly, as in

```nasm
push    sp
```

The reason is that the 80286 doesn't handle the pushing of SP in quite the same way as the 8088 does; the 80286 pushes SP before decrementing it by 2, whereas the 8088 pushes SP *after* decrementing it. As a result, code that uses `push sp`{.nasm} may not work in the same way on all computers. In normal code you'll rarely need to push SP, but if you do, you can simply pass the value through another register, as in

```nasm
mov     ax,sp
push    ax
```

The above sequence will work exactly the same way on any 8086-family processor...

## The Segment Registers

Each of the four segment registers—CS, DS, ES, and SS—points to the start of a 64-Kb block, or segment, within which certain types of memory accesses may be performed. For instance, the stack must always reside in the segment pointed to by SS. Except as noted, segment registers can only be copied to or loaded from a memory operand, the stack, or a general-purpose register. Segment registers cannot be used as operands to instructions such as `add`{.nasm}, `dec`{.nasm} or `and`{.nasm} a property that complicates considerably the handling of blocks of memory larger than 64 Kb.

Since a segment register stores a 16-bit value just as a general-purpose register does, it sometimes becomes tempting to use one of the segment registers (almost always ES or DS, although SS could conceivably be used under certain circumstances) for temporary storage. Be aware, however, that because segment registers take on more specialized meanings in the protected modes of the 80286 and 80386 processors, you should avoid using this technique in code that may at sometime need to be ported to protected mode. That doesn't mean you shouldn't use segment registers for temporary storage, as we'll see in the next chapter, just that you should be aware of the possible complications.

We'll discuss segments and segment registers at length in the next chapter; what's coming up next is just a quick glance at the segment registers and their uses.

### The CS register

The CS register points to the code segment, the 64-Kb block within which IP points to the offset of the next instruction byte to be executed. The CS:IP pair cannot ever point to the wrong place for even one instruction; if it did, an incorrect instruction byte would be fetched and executed next. Consequently, both CS and IP must be set whenever CS is changed, and the setting of both registers must be accomplished by a single instruction. Although CS can be pushed, copied to memory, or copied to a general-purpose register, it can't be loaded directly from any of those sources. The only instructions that can load CS are the far versions of `jmp`{.nasm}, `call`{.nasm} and `ret`{.nasm} as well as `int`{.nasm} and `iret`{.nasm}, what all those instructions have in common is that they load both CS and IP at the same time. Both `int`{.nasm} and the far version of `call`{.nasm} push both CS and IP on the stack so that `iret`{.nasm} or `ret`{.nasm} can return to the instruction following the `int`{.nasm} or `call`{.nasm}.

In addition, segment override prefixes can be used to select CS as the segment accessed by many memory operands that normally access DS.

### The DS register

The DS register points to the data segment, the segment within which most memory operands reside by default. (Note, however, that many memory-addressing instructions can access any of the four segments with the help of a segment override prefix.)

DS can be copied to or loaded from a memory operand, the stack, or a general-purpose register. It can also be loaded, along with any general- purpose register, from a doubleword operand with the `lds`{.nasm} instruction.

### The ES register

The ES register points to the extra segment, the segment within which certain string instruction operands must reside. In addition, segment override prefixes can be used to select ES as the segment accessed by many memory operands that normally access DS.

ES can be copied to or loaded from a memory operand, the stack, or a general-purpose register. ES can also be loaded, along with any general-purpose register, from a doubleword operand with the `les`{.nasm} instruction.

### The SS register

The SS register points to the stack segment, the segment within which SP points to the top of the stack. The instruction `push`{.nasm} stores its operand in the stack segment, and `pop`{.nasm} retrieves its operand from the stack segment. In addition, `call`{.nasm}, `ret`{.nasm}, `int`{.nasm}, and `iret`{.nasm} all access the stack Memory accesses performed with BP as a base register also default to accessing the stack segment. Finally, segment override prefixes can be used to select SS as the segment accessed by many memory operands that normally access DS.

Although SS can be loaded directly, like DS and ES, you must always remember that SS and SP operate as a pair and together must point to a valid stack whenever stack operations might occur. As discussed above, interrupts can occur at any time, so when you load SS, interrupts must be off until both SS and SP have been loaded to point to the new stack. Intel thoughtfully provided a feature designed to take care of such problems. Whenever you load a segment register via `mov`{.nasm} or `pop`{.nasm}, interrupts are automatically disabled until the following instruction has finished. For example, in the following code

```nasm
mov   ss,dx
mov   sp,ax
```

interrupts are disabled from the start of the first `mov`{.nasm} until the end of the second. After the second `mov`{.nasm}, interrupts are again enabled or disabled as they were before the first `mov`{.nasm}, depending on the state of the interrupt flag.

Unfortunately, there was a bug in early 8088 chips that caused the automatic interrupt disabling described above to malfunction. Consequently, it's safest to explicitly disable interrupts when loading SS:SP, as follows:

```nasm
cli
mov   ss,dx
mov   sp,ax
sti
```

## The Instruction Pointer

IP, the instruction pointer, is an internal 8088 register that is not directly accessible as an instruction operand. IP contains the offset in the code segment at which the next instruction to be executed resides. After one instruction is started, IP is normally advanced to point to the next instruction; however, branching instructions, such as `jmp`{.nasm} and `call`{.nasm}, load IP with the offset of the instruction being branched to. The instructions `call`{.nasm} and `int`{.nasm} automatically push IP, allowing `ret`{.nasm} or `iret`{.nasm} to continue execution at the instruction following the `call`{.nasm} or `int`{.nasm}.

As we've discussed, in one sense the instruction pointer points to the next instruction to be *fetched* from memory rather than the next instruction to be executed. This distinction arises because the bus interface unit (BID) of the 8088 can prefetch several instructions ahead of the instruction being carried out by the execution unit (EU). From the programmer's perspective, though, the instruction pointer always simply points to the next instruction byte to be executed; the 8088 handles all the complications of prefetching internally in order to present us with this consistent programming interface.

## The Flags Register

The flags register contains the nine bit-sized status flags of the 8088, as shown in Figure 6.2. Six of these flags—CF, PF, AF, ZF, SF, and OF, collectively known as the status flags—reflect the status of logical and arithmetic operations; two—IF and DF—control aspects of the 8088's operation; and one—TF—is used only by debugging software.

![**Figure 6.2** The 8088's flags.](images/fig6.2RT.png)

The flags are generally tested singly (or occasionally in pairs or even three at a time, as when testing signed operands); however, many arithmetic and logical instructions set all six status flags to indicate result statuses, and a few instructions work directly with all or half of the flags register at once. For example, `pushf`{.nasm} pushes the flags register onto the stack, and `popf`{.nasm} pops the word on top of the stack into the flags register. (We'll encounter an interesting complication with `popf`{.nasm} on the 80286 in Chapter 15.) In Chapter 8 we'll discuss `lahf`{.nasm} and `sahf`{.nasm}, which copy the lower byte of the flags register to and from the AH register. Interrupts, both software (via `int`{.nasm}) and hardware (via the INTR pin), push the flags register on the stack, followed by CS and IP; `iret`{.nasm} reverses the action of an interrupt, popping the three words on top of the stack into IP, CS, and the flags register.

One more note: bear in mind that the six status flags are not set by every instruction. On some processors the status flags always reflect the contents of the accumulator, but not so with the 8088, where only specific instructions affect specific flags. For example, `inc`{.nasm} affects all the status flags *except* the carry flag; although that can be a nuisance, it can also be used to good advantage in summing multi-word memory operands, as we'll see in Chapter 9.

Along the same line, some instructions, such as division, leave some or all of the status flags in undefined states; that is, the flags are changed, but there is no guarantee as to what values they are changed to. Because `mov`{.nasm} and most branching instructions don't affect the status flags at all, you can, if you're clever, carry the result of an operation along for several instructions, a technique we'll look at in Chapter 9.

Let's briefly examine each flag.

### The Carry flag (CF)

The carry flag (CF for short) is set to 1 by additions that result in sums too large to fit in the destination and by subtractions that result in differences less than 0, and is set to 0 by arithmetic and logical operations that produce results small enough to fit in the destination when viewed as unsigned integers. (The logical operations `and`{.nasm}, `or`{.nasm}, and `xor`{.nasm} always set CF to 0, since they always produce results that fit in the destination.) Also, when a shift or rotate instruction shifts a bit out of an operand's most significant bit (msb) or least significant bit (lsb), that bit is transferred to CF. As a special case, both the carry and overflow flags are set to 1 by multiplication, except when the result is small enough to fit in the lower half of the destination (considered as a signed number for `imul`{.nasm} and as an unsigned number for `mul`{.nasm}).

The primary purpose of CF is to support addition, subtraction, rotation, and shifting of multi-byte or multi-word operands. In these applications, CF conveys the msb or lsb of one 8- or 16-bit operation to the next operation, as for example in the 32-bit right shift

```nasm
shr   dx,1  ;shift upper 16 bits
rcr   ax,1  ;shift lower 16 bits, including the bit
            ; shifted down from the upper 16 bits
```

Note that this makes CF the only flag that can participate directly in arithmetic operations.

CF can also be tested with the `jc`{.nasm} (which can be thought of as standing for "jump carry") and the `jnc`{.nasm} ("jump no carry") conditional jump instructions. The instruction `jc`{.nasm} is also known as both `jb`{.nasm} ("jump below") and `jnae`{.nasm} ("jump not above or equal"). All three instructions assemble to the same machine code. Likewise, `jnc`{.nasm} is also known as both `jae`{.nasm} ("jump above or equal") and `jnb`{.nasm} ("jump not below"). The carry and zero flags together can be tested with `ja`{.nasm} and `jbe`{.nasm}. `ja`{.nasm} is also known as `jnbe`{.nasm} ("jump not below or equal"), and `jbe`{.nasm} is also known as `jna`{.nasm} ("jump not above"). These conditional jumps are often used to determine unsigned greater than/less than/equal relationships between operands.

Alone among the six status flags , CF can be set, reset, and toggled directly with the `clc`{.nasm} ("clear carry"), `stc`{.nasm} ("set carry"), and `cmc`{.nasm} ("complement carry") instructions. This can be useful for returning a status from a subroutine, or for modifying the action of `ade`{.nasm}, `sbb`{.nasm}, `rei`{.nasm}, or any other instruction that includes CF in its calculations.

Note that CF is *not* affected by `inc`{.nasm} or `dec`{.nasm}, although it is affected by add and sub. (We'll see one use for this trait of `inc`{.nasm} and `dec`{.nasm} in Chapter 9.) Also, be aware that since `neg`{.nasm} is logically equivalent to subtracting an operand from 0, CF is always set by `neg`{.nasm}, except when the operand is 0. (Zero minus anything other than zero always causes borrow).

### The Parity flag (PF)

The parity flag (PF for short) is set to 1 whenever the least significant byte of the result of an arithmetic or logical operation contains an even number of bits that are set to 1, and it is set to 0 whenever the least significant byte contains an odd number of bits that are 1.

PF can be tested only with the `jp`{.nasm} ("jump parity") and `jnp`{.nasm} ("jump no parity") conditional jump instructions. The instruction `jp`{.nasm} is also known as `jpe`{.nasm} ("jump parity even"), and `jnp`{.nasm} is also known as `jpo`{.nasm} ("jump parity odd"). Generally, PF is useful for generating and testing parity bits for data storage and transmission. Apart from that, I know of no good uses for PF, although such uses may well exist.

### The Auxiliary Carry flag (AF)

The auxiliary carry flag (AF for short) is set to 1 if arithmetic or logical operation results in carry out of bit 3 of the destination and is set to 0 otherwise. Alone among the six status flags, AF cannot be tested by any conditional jump instruction. In fact, the only instructions that pay any attention at all to AF are `aaa`{.nasm}, `aas`{.nasm}, `daa`{.nasm}, and `das`{.nasm}, which use AF to help sort out the results of ASCII or BCD arithmetic. Apart from ASCII and BCD arithmetic, which we'll discuss in Chapter 9, I've never found a use for AF.

### The Zero flag (ZF)

The zero flag (ZF for short) is set to 1 if an arithmetic or logical operation produces a 0 result or to 0 otherwise. ZF is generally used to test for equality of two operands or for zero results via the `jz`{.nasm} ("jump zero") and `jnz`{.nasm} ("jump not zero") conditional jumps, also known as `je`{.nasm} ("jump equal") and `jne`{.nasm} ("jump not equal"), respectively. As discussed above, ZF and CF can be tested together with a variety of conditional jumps. The zero, sign, and overflow flags together can be tested with `jg`{.nasm} ("jump greater"), also known as `jnle`{.nasm} ("jump not less or equal") and with `jle`{.nasm}, also known as `jng`{.nasm} ("jump not greater"). These conditional jumps are often used to determine signed greater than/less than/equal relationships between operands.

### The Sign flag (SF)

The sign flag (SF for short) is set to the state of the most significant bit of the result of an arithmetic or logical operation. For signed arithmetic, the most Significant bit is the sign of the operand, so an SF setting of 1 indicates a negative result.

SF is generally used to test for negative results via the `js`{.nasm} ("jump sign") and `jns`{.nasm} ("jump no sign") conditional jumps. As discussed above, the sign zero, and overflow flags together can be tested with `jg`{.nasm} and `jle`{.nasm}. The sign and overflow flags together can be tested with `jl`{.nasm} ("jump less") and `jge`{.nasm} ("jump greater or equal"). The instruction `jl`{.nasm} is also known as `jnge`{.nasm} ("jump not greater or equal") and `jge`{.nasm} is also known as `jnl`{.nasm} ("jump not less").

### The Overflow flag (OF)

The overflow flag (OF for short) is set to 1 if the carry into the most significant bit of the result of an operation and the carry out of that bit don't match. Overflow indicates that the result, interpreted as a signed result, is too large to fit in the destination and is therefore not a valid signed result of the operation. (It may still be a valid unsigned result, however; CF is used to detect too large and too small unsigned results.) In short, OF is set to 1 if the result has overflowed (grown too large for) the destination in terms of signed arithmetic. I know of no use for OF other than in signed arithmetic. The logical operations `and`{.nasm}, `or`{.nasm}, and `xor`{.nasm} always set OF to 0.

OF can be tested in any of several ways. The `jo`{.nasm} ("jump overflow") and `jno`{.nasm} ("jump no overflow") instructions branch or don't branch depending on the state of OF. As described above, the `jl`{.nasm}, `jnl`{.nasm}, `jle`{.nasm}, `jnle`{.nasm}, `jg`{.nasm}, `jng`{.nasm}, `jge`{.nasm}, and `jnge`{.nasm} instructions branch or don't branch depending on the states of OF, SF, and sometimes ZF. Finally, the `int`{.nasm} instruction executes an int 4 if and only if OF is set.

### The Interrupt flag (IF)

The interrupt flag (IF for short) enables and disables maskable hardware interrupts. When IF is 1, all hardware interrupts are recognized by the 8088. When IF is 0, maskable interrupts (that is, those interrupts signaled on the INTR pin) are not recognized until such time as IF is set to 1. (Nonmaskable interrupts—interrupts signaled on the NMI pin—are recognized by the 8088 regardless of the setting of IF, as are software interrupts, which are invoked with the `int`{.nasm} instruction.) IF is set to 1 (enabling interrupts) with `sti`{.nasm} and is set to 0 (disabling interrupts) with `cli`{.nasm}. IF is also automatically set to 0 when a hardware interrupt occurs or an `int`{.nasm} instruction is executed. In addition, as described in the discussion of the SS register above, interrupts are automatically disabled until the end of the following instruction whenever a segment register is loaded.

The PC is an interrupt-based computer, so interrupts should in general be disabled as infrequently and for as short a time as possible. System resources such as the keyboard and time-of-day clock are interrupt based and won't function properly if interrupts are off for too long. You really only need to disable interrupts in code that could malfunction if it is interrupted, such as code that services time-sensitive hardware or code that uses multiple prefix bytes per instruction. (The latter, as discussed in Chapter 10, should be avoided whenever possible.)

Leave interrupts enabled at all other times.

### The Direction flag (DF)

The direction flag (DF for short) controls the direction in which the pointer registers used by the string instructions (SI and DI) count. When DF is 1 (as set with `std`{.nasm}), string instruction pointer registers decrement after each memory access; when DF is 0 (as set with `cld`{.nasm}), string instruction pointer registers increment. We'll discuss the direction flag in detail when we cover the string instructions in Chapter 10.

### The Trap flag (TF)

The trap flag (TF for short) instructs the 8088 to execute a software interrupt 1 after the next instruction. This is specifically intended to allow debugging software to single-step through code; it has no other known use.

## There's More to Life Than Registers

The register set is just one aspect of the 8088, albeit an important aspect indeed. The other key features of the 8088 are memory addressing, which expands the 8088's working data set from the few bytes that can be stored in the registers to the million bytes that can be stored in memory, and the instruction set, which allows manipulation of registers and memory locations and provides program flow control (branching and decision making) as well. We'll look at memory addressing next, then move on to the limitless possibilities of the instruct instruction set.

