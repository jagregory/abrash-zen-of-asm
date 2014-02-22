# Chapter 8: Strange Fruit of the 8080

> For of all sad words of tongue or pen
>
> The saddest are these: "It might have been!"
>
> -- John Greenleaf Whittier

With this chapter we start our exploration of the 8088's instruction set. What better place to begin than with the roots of that instruction set, which trace all the way back to the dawn of the microcomputer age?

If you're a veteran programmer, you probably remember the years Before IBM, when state-of-the-art micros were built around the 8-bit 8080 processor and its derivatives. In today's era of ever-mightier 16-and 32-bit processors, you no doubt think you've seen the last of the venerable but not particularly powerful 8080.

Not a chance.

The 8080 lingers on in the instruction set and architecture of the 8088, which was designed with an eye toward making it easy to port 8080 programs to the 8088. While it may seem strange that the design of an advanced processor would be influenced by the architecture of a less-capable processor, that practice is actually quite common and makes excellent market sense. For example, the 80286 and 80386 processors provide complete 8088 compatibility, and would certainly not have been as successful were they not 8088-compatible. In fact, one of the great virtues of the 80386 is its ability to emulate several 8088s at once, and it is well known that the designers of the 80386 went to considerable trouble to maintain that link with the past.

Less well known, perhaps, is the degree to which the designers of the 8088 were guided by the past as well. (Actually, as discussed in Chapter 3, the 8086 was designed first and the 8088 spun off from it, but we'll refer simply to the 8088 from now on, since that's our focus and since the two processors share the same instruction set.)

## The 8080 Legacy

At the time the 8088 was designed, the Intel 8080, an 8-bit processor, was an industry standard, along with the more powerful but 8080-compatible Zilog Z80 and Intel 8085 chips. The 8080 had spawned CP/M, a widely-used operating system, and with it a variety of useful programs, including word processing, spreadsheet, and database software.

New processors are *always* — without fail — more powerful than their predecessors. Nonetheless, processors that lack compatibility with any previous generation are generally not widely used for several years — if ever — because software developers don't come fully up to speed on new processors for several years, and it's a broad software base that makes a processor useful and therefore popular. In the interim, relatively few programs are available to run on that processor, and sales languish. One solution to this problem is to provide complete compatibility with an earlier standard, as the Z80 and 8085 did. Indeed, today the NEC V20 processor, which is fully 8088 compatible, has the equivalent of an 8080 built in, and can readily switch between 8088-and 8080-compatible modes.

Unfortunately, chip space was at a premium during the 1970s, and presumably Intel couldn't afford to put both 8088 and 8080 functionality into a single package. What Intel could and did do was design the 8088 so that it would be relatively easy to port 8080 programs — especially assembler programs, since most programs were written in assembler in those days — to run on the 8088, and so that those ported programs would perform reasonably well.

The designers of the 8088 provided such "source-level" compatibility by making the 8088's register set similar to the 8080's, by implementing directly analogous — although not identical — 8088 instructions for most 8080 instructions and by providing special speedy, compact forms of key 8080 instructions. As a result, the 8088's architecture bears a striking similarity to that of the 8080.

For example, the 8088's 16-bit AX, BX, CX, and DX registers can also be accessed as paired 8-bit registers, thereby making it possible for the 8088 to mimic the seven 8-bit program-accessible registers and the 8-bit FLAGS register of the 8080, as shown in Figure 8.1. In particular, the 8088's BH and BL registers can be used together as the BX register to address memory, just as the 8080's HL register pair can.

![](images/fig8.1RT.png)

The register correspondence between the 8080 and 8088 is not perfect. For one thing, neither CX nor DX can be used to address memory as the 8080's BC and DE register pairs can; however, the 8088's `xchg`{.nasm} instruction and/or index registers can readily be used to compensate for this. Similarly, the 8080 can push both the flags and the accumulator onto the stack with a single instruction, while the 8088 cannot. As we'll see later in this chapter, though, the designers of the 8088 provided two instructions — `lahf`{.nasm} and `sahf`{.nasm} — to take care of that very problem.

All in all, while the 8080 and 8088 certainly aren't brothers, they're close relatives indeed.

### More Than a Passing Resemblance

In general, the 8088's instruction set reflects the influence of the 8080 fairly strongly. While the 8088's instruction set is a considerable superset of the 8080's, there are few 8080 instructions that can't be emulated by one (or at most two) 8088 instructions, and there are several 8088 instructions that most likely would not exist were it not for the 8080 legacy. Also, although it's only speculation, it certainly seems possible that the segmented memory architecture of the 8088 is at least partially the result of needing to reconcile the 1 Mb address space of the 8088 with the 8-and 16-bit nature of the registers the 8088 inherited from the 8080. (Segmentation does allow some types of code to be more compact than it would be if the 8088 had an unsegmented address space, so let's not blame segmentation entirely on the 8080.)

The 8088 is without question a more powerful processor than the 8080, with far more flexible addressing modes and register usage, but it is nonetheless merely a 16-bit extension of the 8080 in many ways, rather than a processor designed from scratch. We can only speculate as to what the capabilities of an 8088 built without regard for the 8080 might have been — but a glance at the 68000's 16 Mb linear address space and large 32-bit register set gives us a glimpse of that future that never was.

At any rate, the 8088 *was* designed with the 8080 in mind, and the orientation of the 8088's instruction set toward porting 8080 programs seems to have served its purpose. Many 8080 programs, including WordStar and VisiCalc, were ported to the 8088, and those ported programs helped generate the critical mass of software that catapulted the 8088 to a position of dominance in the microcomputer world. How much of the early success of the 8088 was due to ported 8080 software and how much resulted from the letters "IBM" on the nameplate of the PC is arguable, but ported 8080 software certainly sold well for some time.

Today the need for 8080 source-level compatibility is long gone, but that 8080-oriented instruction set is with us still, and seems likely to survive well into the 21st century in the silicon of the 80386 and its successors. (Amazingly, every processor shown in Figure 3-5 provides full 8088 compatibility, and it's a safe bet that future generations will be compatible as well. In fact, although it hasn't happened as of this writing, it appears that some *non-Intel* manufacturers may build 8088-compatible subprocessors into their chips!)

The 8080 flavor of the 8088's instruction set is both a curse and a blessing. It's a curse because it limits the performance of average 8088 code, and a blessing because it provides great opportunity for assembler code to shine. In particular, the 8080-specific instructions occupy valuable space in the 8088 opcode set — arguably causing native 8088 code (as opposed to ported 8080 code) to be larger and slower than it would otherwise be — and that is, by-and-large, one of the less appealing aspects of the 8088. For the assembler programmer, however, the 8080-specific instructions can be an asset. Since those instructions are faster and more compact than their general-purpose counterparts, they can often be used to create significantly better code. Next, we'll examine the 8080-specific instructions in detail.

## Accumulator-Specific Instructions

The accumulator is a rather special register on the 8080. For one thing, the 8080 requires that the accumulator be the destination for most arithmetic and logical operations. For another, the accumulator is the register generally used as source and destination for memory accesses that use direct addressing. (Refer back to Chapter 7 for a discussion of addressing modes.)

Not so with the 8088. In the 8088's instruction set, the accumulator (AL for 8-bit operations, AX for 16-bit operations) is a special register for some operations, such as multiplication and division, but is by-and-large no different from any other general-purpose register. With the 8088, any of the eight general-purpose registers can be the source or destination for logical operations, addition, subtraction, and memory accesses as readily as the accumulator can.

While the 8088's instructions are far more flexible than the 8080's instructions, that flexibility has a price. The price is an extra instruction byte, the *mod-reg-rm* byte, which encodes the 8088's many addressing modes and source/destination combinations, as we learned in Chapter 7. Thanks to the *mod-reg-rm* byte, 8088 instructions are normally 1 byte longer than equivalent 8080 instructions. However, several 8080-inspired 8088 instructions, which require that the accumulator be one of the operands and accept only a few possibilities for the other operand, are the same length as their 8080 counterparts. (Not all the special instructions have exact 8080 counterparts, but that doesn't make them any less useful.) While these accumulator-specific instructions lack the flexibility of their native 8088 counterparts, they are also smaller and faster, so it's desirable to use them whenever possible.

The accumulator-specific 8088 instructions fall into two categories: instructions involving direct addressing of memory, and instructions involving immediate arithmetic and logical operands. We'll look at accumulator-specific memory accesses first.

### Accumulator-Specific Direct-Addressing Instructions

The 8088 lets you address memory operands in a great many different ways — 16 ways, to be precise, as we saw in Chapter 7. This flexibility is one of the strengths of the 8088, and is one way in which the 8088 far exceeds the 8080. There's a price for that flexibility, though, and that's the *mod-reg-rm* byte, which we encountered in Chapter 7. To briefly recap, the *mod-reg-rm* byte is a second instruction byte, immediately following the opcode byte of most instructions that access memory, which specifies which of 32 possible addressing modes are to be used to select the source and/or destination for the instruction. (8 of the addressing modes are used to select the 8 general-purpose registers as operands, and 8 addressing modes differ only in the size of the displacement field, hence the discrepancy between the 32 addressing modes and the 16 ways to address memory operands.) Together, the *mod-reg-rm* byte and the 16-bit displacement required for direct addressing mean that any instruction that uses *mod-reg-rm* direct addressing must be at least 4 bytes long, as shown in Figure 8.2.

![](images/fig8.2RT.png)

Direct addressing is used whenever you simply want to refer to a memory location by name, with no pointing or indexing. For example, a counter named `Count`{.nasm} could be incremented with direct addressing as follows:

```nasm
inc   [Count]
```

Direct addressing is intuitive and convenient, and is one of the most heavily used addressing modes of the 8088.

Since direct addressing is one of the very few addressing modes of the 8080, and since the 8088's designers needed to make sure that ported 8080 code ran reasonably well on the 8088, there are 8088 instructions that do nothing more than load and store the accumulator from and to memory via direct addressing. These instructions are only 3 bytes long, as shown in Figure 8.3; better yet, they execute in just 10 cycles, rather than the 14 (memory read) or 15 (memory write) cycles required by *mod-reg-rm* memory accesses that use direct addressing. (Those cycle counts are for byte-sized accesses; add 4 cycles to both forms of `mov`{.nasm} for word-sized accesses.)

![](images/fig8.3RT.png)

### Looks Aren't Everything

One odd aspect of the accumulator-specific direct-addressing instructions is that in assembler form they don't *look* any different from the more general form of the `mov`{.nasm} instruction; the difference between the two versions only becomes apparent in machine-language. So, for example, while:

```nasm
mov   al,[Count]
```

and:

```nasm
mov   dl,[Count]
```

look like they refer to the same instruction, the machine code assembled from the two differs greatly, as shown in Figure 8.4; the first instruction is a byte shorter and 4 cycles faster than the second.

![](images/fig8.4RT.png)

Odder still, there are actually *two* legitimate machine-language forms of the assembler code for each of the accumulator-specific direct-addressing instructions (and, indeed, for all the accumulator-specific instructions discussed in this chapter), as shown in Figure 8.5. Any 8088 assembler worth its salt automatically assembles the shorter form, of course, so the longer, general-purpose versions of the accumulator-specific instructions aren't used. Still, the mere existence of two forms of the accumulator-specific instructions points up the special-case nature of these instructions and the general irregularity of the 8088's instruction set.

### How Fast Are They?

How much difference does the use of the accumulator-specific direct-addressing instructions make? Generally, less difference than the official timings in Appendix A would indicate, but a significant difference

![](images/fig8.5RT.png)

nonetheless — and you save a byte every time you use an accumulator-specific direct-addressing instruction, as well.

Suppose you want to copy the value of one byte-sized memory variable to another byte-sized memory variable. A common way to perform this simple task is to read the value of the first variable into a register, then write the value from the register to the other variable. [Listing 8-1](#L801) shows a code fragment that performs such a byte copy 1000 times by way of the AH register. Since the accumulator is neither source nor destination in [Listing 8-1](#L801), the 4-byte *mod-reg-rm* direct-addressing form of `mov`{.nasm} is assembled for each instruction; consequently, 8 bytes of code are assembled in order to copy each byte via AH, as shown in Figure 8.6. (Remember that AH is not considered the accumulator. For 8-bit operations, AL is the accumulator, and for 16-bit operations, AX is the accumulator, but AH by itself is just another general-purpose register.)

![](images/fig8.6RT.png)

Plugged into the Zen timer test program, [Listing 8-1](#L801) yields an average time per byte copied of 10.06 us, or about 48 cycles per byte copied. That's considerably longer than the 29 cycles per byte copied you'd expect from adding up the official cycle times given in Appendix A; the difference is the result of the prefetch queue and dynamic RAM refresh cycle-eaters. We can't cover all the aspects of code performance at once, so for the moment let's just discuss the implications of the times reported by the Zen timer. Remember, no matter how much theory of code performance you've mastered, there's still only one reliable way to know how fast PC code really is — measure it!

[Listing 8-2](#L802) performs the same 1000 byte copies as [Listing 8-1](#L801), but does so by way of the 8-bit accumulator, AL. In [Listing 8-2](#L802), 6 bytes of code are assembled in order to copy each byte by way of AL, as shown in Figure 8.7. Each `mov`{.nasm} instruction in [Listing 8-2](#L802) is a byte shorter than the corresponding instruction in [Listing 8-1](#L801), thanks to the 3-byte size of the accumulator-specific direct-addressing `mov`{.nasm} instructions. The Zen timer reports that copying by way of the accumulator reduces average time per byte copied to 7.55 microseconds, which works out to about 36 cycles per byte — a 33% improvement in performance over [Listing 8-1](#L801).

Enough said.

![](images/fig8.7RT.png)

### When Should You Use Them?

The implications of accumulator-specific direct addressing are obvious: whenever you need to read or write a direct-addressed memory operand, do so via the accumulator if at all possible. You can take this a step further by running unorthodox applications of accumulator-specific direct addressing through the Zen timer to see whether they're worth using. For example, one common use of direct addressing is checking whether a flag or count is zero, with an instruction sequence like:

```nasm
cmp   [NumberOfShips],0   ;5 bytes/20 cycles
jz    NoMoreShips         ;2 bytes/16 or 4 cycles
```

In this example, `NumberOfShips`{.nasm} is accessed with *mod-reg-rm* direct addressing. We'd like to use accumulator-specific direct addressing, but because this is a `cmp`{.nasm} instruction rather than a `mov`{.nasm} instruction, it would seem that accumulator-specific direct addressing can't help us.

Even here, however, accumulator-specific direct addressing can help speed things up a bit. Since we're only interested in whether `NumberOfShips`{.nasm} is zero or not, we can load it into the accumulator and then `and`{.nasm} the accumulator with itself to set the zero flag appropriately, as in:

```nasm
mov   ax,[NumberOfShips]    ;3 bytes/14 cycles
and   ax,ax                 ;2 bytes/3 cycles
jz    NoMoreShips           ;2 bytes/16 or 4 cycles
```

While the accumulator-specific version is longer in terms of instructions, what really matters is that both code sequences are 7 bytes long, and that the cycle time for the accumulator-specific code is 3 cycles less according to the timings in Appendix A.

Of course, we only trust what we measure for ourselves, so we'll run the code in [Listings 8-3](#L803) and [8-4](#L804) through the Zen timer. The Zen timer reports that the accumulator-specific means of testing a memory location and setting the appropriate zero/non-zero status executes in 6.34 us per test, more than 6% faster than the 6.76 us time per test of the standard test-for-zero code. While 6% isn't a vast improvement, it *is* an improvement, and that boost in performance comes at no cost in code size. In addition, the accumulator-specific form leaves the variable's value available in the accumulator after the test is completed, allowing for faster code yet if you need to manipulate or test that value further. The flip side is that the accumulator-specific direct-addressing approach *requires* that the test value be loaded into the accumulator, so if you've got something stored in the accumulator that you don't want to lose, by all means use the *mod-reg-rm* `cmp`{.nasm} instruction.

Don't get hung up on using nifty tricks for their own sake. The object is simply to select the best instructions for the task at hand, and it matters not in the least whether those instructions happen to be dazzlingly clever or perfectly straightforward.

Don't expect that unorthodox uses of accumulator-specific direct addressing will always pay off, but try them out anyway; they *might* speed up your code, and even if they don't, your experiments might well lead to something else worth knowing. For instance, based on the official execution times in Appendix A it appears that:

```nasm
mov   ax,1                ;3 bytes/4 cycles
mov   [InitialValue],ax   ;3 bytes/14 cycles
```

should be faster than:

```nasm
mov   [InitialValue],1    ;6 bytes/20 cycles
```

running [Listings 8-5](#L805) and [8-6](#L806) through the Zen timer, however, we find that both versions take exactly 7.54 us per initialization. The execution time in both cases is determined by the number of memory accesses rather than by Execution Unit execution time, and both versions perform 8 memory accesses per initialization (6 instruction byte fetches and 1 word-sized memory operand access).

While that particular trick didn't work out, it does suggest another possibility. Suppose that we want to initialize the variable `InitialValue`{.nasm} to the specific value of zero; now we can modify [Listing 8-5](#L805) to:

```nasm
sub   ax,ax               ;2 bytes/3 cycles`
mov   [InitialValue],ax   ;3 bytes/14 cycles`
```

which is both 1 byte shorter and 3 cycles faster than the *mod-reg-rm* instruction:

```nasm
mov   word ptr [InitialValue],0   ;6 bytes/20 cycles
```

Code that's shorter in both bytes and cycles (remember, we're talking about official cycles, as listed in Appendix A) almost always provides superior performance, and [Listing 8-7](#L807) does indeed clock the accumulator-specific initialize-to-zero approach at 6.76 us per initialization, more than 11% faster than [Listing 8-6](#L806).

Actively pursue the possibilities in your assembler code. You never know where they might lead.

### Accumulator-Specific Immediate-Operand Instructions

The 8088 also offers special accumulator-specific versions of a number of arithmetic and logical instructions — `adc`{.nasm}, `add`{.nasm}, `and`{.nasm}, `cmp`{.nasm}, `or`{.nasm}, `sub`{.nasm}, `sbb`{.nasm}, and `xor`{.nasm} — when these instructions are used with one register operand and one immediate operand. (Remember that an immediate operand is a constant operand that is built right into an instruction.) The *mod-reg-rm* immediate-addressing versions of the above instructions, when used with a register as the destination operand, are 3 bytes long for byte comparisons and 4 bytes long for word comparisons, as shown in Figure 8.8. The accumulator-specific immediate-addressing versions, on the other hand, are 2 bytes long for byte comparisons and 3 bytes long for word comparisons, as shown in Figure 8.9. Although the official cycle counts listed in Appendix A for all immediate-addressing forms of these instructions — accumulator-specific or otherwise — are all 4 when used with a register as the destination, shorter is generally faster, thanks to the prefetch queue cycle-eater.

![](images/fig8.8RT.png)

Let's see how much faster the accumulator-specific immediate-addressing form of `cmp`{.nasm} is than the *mod-reg-rm* version. (The results will hold true for all 8 accumulator-specific immediate-addressing instructions, since they all have the same sizes and execution times.) The Zen timer reports that each accumulator-specific `cmp`{.nasm} in [Listing 8-8](#L808) takes 1.81 us, making it 50% faster than the *mod-reg-rm* version in [Listing 8-9](#L809), which clocks in at 2.71 us per comparison. It is not in the least coincidental that the ratio of the execution times, 3:2, is the same as the ratio of instruction lengths in bytes; the performance difference is entirely due to the difference in instruction lengths.

![](images/fig8.9RT.png)

There are two *caveats* regarding accumulator-specific immediate-addressing instructions. First, unlike the accumulator-specific form of the direct-addressing `mov`{.nasm} instruction, the accumulator-specific immediate-addressing instructions can't work with memory operands. For instance, `add al,[Temp]`{.nasm} assembles to a *mod-reg-rm* instruction, not to an accumulator-specific instruction.

Second, there's no advantage to using the accumulator-specific immediate-addressing instructions when they're used with word-sized immediate operands in the range -128 to +127 (inclusive), although there's no disadvantage, either. This is true because the word-sized *mod-reg-rm* equivalents of the accumulator-specific instructions can store immediate values in this range as bytes and then sign-extend them to words at execution time, while the accumulator-specific immediate-addressing instructions cannot, as shown in Figure 8.10. Consequently, both forms of these instructions are 3 bytes long when used with immediate operands in the range -128 to +127.

An important note: some 8088 references indicate that while immediate operands to arithmetic instructions can be sign-extended, immediate operands to logical instructions — `xor`{.nasm}, `and`{.nasm}, and `or`{.nasm} — cannot. Not true! Immediate operands to logical instructions *can* be sign-extended, and MASM does so automatically whenever possible.

![](images/fig8.10RT.png)

Remember, if you're not sure exactly what instructions the assembler is generating from your source code, you can always look at the instructions directly with a disassembler. Alternatively, you can look at the assembled hex bytes at the left side of the assembly listing.

### An Accumulator-Specific Example

Let's look at a real-world example of saving bytes and cycles with accumulator-specific instructions. We're going to force the adapter-select bits — bits 5 and 4 of the BIOS equipment flag variable at 0000:0410 — to the setting for an 80-column color adapter. This requires first forcing the adapter-select bits to 0, then setting bit 5 to 1 and bit 4 to 0.

The simplest approach to setting the equipment flag to 80-column color text mode is shown in [Listing 8-10](#L810); this code uses one *mod-reg-rm* `and` instruction and one *mod-reg-rm* `or`{.nasm} instruction to set the equipment flag in 18.86 us. By contrast, [Listing 8-11](#L811) uses four accumulator-specific instructions to set the equipment flag. Even though [Listing 8-11](#L811) uses two more instructions than [Listing 8-10](#L810), it is 12.5% faster, taking only 16.76 us to set the equipment flag.

![](images/fig8.11RT.png)

### Other Accumulator-Specific Instructions

There are two more instructions that have accumulator-specific versions: `test`{.nasm} and `xchg`{.nasm}. Although these instructions have no direct equivalents in the 8080 instruction set, we'll cover them now while we're on the topic of accumulator-specific instructions. (While the 8080 does offer some exchange instructions, the 8088's accumulator-specific form of `xchg`{.nasm} doesn't correspond directly to any of those 8080 instructions.)

### The Accumulator-Specific Version Of `test`

`test`{.nasm} sets the flags as if an `and`{.nasm} had taken place, but does not modify the destination. As with `and`{.nasm}, there's an accumulator-specific immediate-addressing version of `test`{.nasm} that's a byte shorter than the *mod-reg-rm* immediate version. (Unlike `and`{.nasm}, the accumulator-specific version of `test`{.nasm} is also a cycle faster than the *mod-reg-rm* version.) So, for example:

```nasm
test    al,1
```

is a byte shorter and a cycle faster than:

```nasm
test    dh,1
```

### The Ax-Specific Version of `xchg`

In its general form, `xchg`{.nasm} swaps the values of two registers, or of a register and a memory location. The *mod-reg-rm* register-register interchange form of `xchg`{.nasm} is 2 bytes long and executes in 4 cycles. There is, however, a special form of `xchg`{.nasm} specifically for interchanging AX (not AL) with any of the 8 general-purpose registers. This AX-specific form is just 1 byte long and executes in a mere 3 cycles. So, for example:

```nasm
xchg    ax,bx
```

is 1 byte and 1 cycle shorter than:

```nasm
xchg    al,bl
```

as shown in Figure 8.11. In fact:

```nasm
xchg    ax,bx
```

is 1 byte shorter (albeit 1 cycle slower) than:

```nasm
mov     ax,bx
```

so the AX-specific form of `xchg`{.nasm} can be an attractive alternative to `mov`{.nasm} when you don't require that the copied value remain in the source register after the copy.

When else might the AX-specific version of `xchg`{.nasm} be useful? Suppose that we've got a loop in which we need to add together elements from two arrays, subtract from that sum a value from a third array, and store the result in a fourth array. Suppose further that we can't use BP, perhaps because it's dedicated to maintaining a stack frame. What's more, the pointers to the arrays are passed in, so we can't just use one pointer register as an array subscript by way of displacement+base addressing. Now we've got a bit of a problem: there are only three registers other than BP capable of addressing memory, but we need pointers to four arrays. We could, of course, load two or more of the pointers from memory each time through the loop, but that would slow processing considerably. We could also store two of the pointers in other registers and copy them into, say, BX as we need them, but that would require us to use three registers to maintain two pointers, and, as it happens, we don't have a register to spare.

The solution is to keep one pointer in BX and one in AX, and swap them as needed via the AX-specific form of `xchg`{.nasm}. (As usual, the assembler automatically uses the most efficient possible form of `xchg`{.nasm}; you don't have to worry about explicitly selecting it.) [Listing 8-12](#L812) show an implementation that uses the AX-specific form of `xchg`{.nasm} to handle our four-array case without accessing memory or using BP.

[Listing 8-12](#L812) is intentionally constructed to allow us to use the AX-specific form of `xchg`{.nasm}. It's natural to choose AL, not DL, as the register used for adding and moving data, but if we had done that, then the `xchg`{.nasm} would have become `xchg dx,bx`{.nasm}, which is the 2-byte *mod-reg-rm* version. [Listing 8-13](#L813) shows this less-efficient version of [Listing 8-12](#L812). Thanks solely to the AX-specific form of `xchg`{.nasm}, [Listing 8-12](#L812) executes in 21.12 us per array element, 7% faster than the 22.63 us per array element of [Listing 8-13](#L813). (By the way, we could revamp [Listing 8-13](#L813) to run considerably faster by using the `lodsb`{.nasm} and `stosb`{.nasm} string instructions, but for the moment we're focusing on the AX-specific form of `xchg`{.nasm}. Nonetheless, there's a lesson here: be careful not to become fixated on a particular trick to the point where you miss other and possibly better approaches.)

The important point is that in 8088 assembler it often matters which registers and/or which forms of various instructions you select. Two seemingly similar code sequences, such as [Listings 8-12](#L812) and [8-13](#L813), can actually have quite different performance characteristics.

Yet another aspect of the Zen of assembler.

## Pushing and Popping the 8080 Flags

Finally, we come to the strangest part of the 8080 legacy, the `lahf`{.nasm} and `sahf`{.nasm} instructions. `lahf`{.nasm} loads AH with the lower byte of the 8088's FLAGS register, as shown in Figure 8.12. Not coincidentally, the lower byte of the FLAGS register contains the 8088 equivalents of the 8080's flags, and those flags are located in precisely the same bit positions in the lower byte of the 8088's FLAGS register as they are in the 8080's FLAGS register. `sahf`{.nasm} reverses the action of `lahf`{.nasm}, loading the 8080-compatible flags into the 8088's FLAGS register by copying AH to the lower byte of the 8088's FLAGS register, as shown in Figure 8.13.

![](images/fig8.12RT.png)

![](images/fig8.13RT.png)

Why do these odd instructions exist? Simply to allow the 8088 to emulate efficiently the 8080's `push psw`{.nasm} and `pop psw`{.nasm} instructions, which transfer both the 8080's accumulator and FLAGS register to and from the stack as a single word. The 8088 sequence:

```nasm
lahf
push  ax
```

is equivalent to the 8080 sequence:

```nasm
push  psw
```

and the 8088 sequence:

```nasm
pop   ax
sahf
```

is equivalent to the 8080 sequence:

```nasm
pop   psw
```

While it's a pretty safe bet that nobody is writing code that uses `lahf`{.nasm} and `sahf`{.nasm} to emulate 8080 instructions anymore, there are nonetheless a few interesting tricks to be played with these instructions. The key is that `lahf`{.nasm} and `sahf`{.nasm} give us a compact (1 byte) and fast (4 cycles) way to save and load the flags we're generally most interested in testing without disturbing the direction and interrupt flags. (Note that the overflow flag also is not saved or restored by these instructions.) By contrast, `pushf`{.nasm} and `popf`{.nasm}, the standard instructions for saving and restoring the flags, take 14 and 12 cycles, respectively, and affect all the flags. What's more, `lahf`{.nasm} and `sahf`{.nasm}, unlike `pushf`{.nasm} and `popf`{.nasm}, avoid the potential complications of accessing the stack.

All in all, `lahf`{.nasm} and `sahf`{.nasm} run faster and tend to cause fewer complications than `pushf`{.nasm} and `popf`{.nasm}. This means that these instructions are attractive whenever you generate a status but don't want to check it right away. This is particularly true if you can't be sure the stack pointer will point to the same place when you finally do check the status, since `pushf`{.nasm} and `popf`{.nasm} wouldn't work in such a case.

By the way, `sahf`{.nasm} is also useful for handling certain status flags of the 8087 numeric coprocessor. The 8087's flags can't be tested directly; they must be stored to memory by the 8087, then tested by the 8088. One good way to do this for testing certain 8088 statuses, such as greater-than/less-than results from comparisons, is by storing the 8087's flags to memory, loading AH from the stored flags, and executing `sahf`{.nasm} to copy the flags into the 8088's FLAGS register, where they can be used to control conditional jumps.

### `lahf` and `sahf`: An Example

Let's look at `lahf`{.nasm} and `sahf`{.nasm} in action. Suppose we have a loop in which a value stored in AL is added to each element of a byte array, with the loop ending only when the result of any addition exceeds 7Fh, causing the Sign flag to be set. Unfortunately, the array pointer must be incremented after the addition, wiping out the Sign flag that we need to test at the bottom of the loop, so we need some way to preserve the Sign flag during execution of the instruction that increments the array pointer.

[Listing 8-14](#L814) solves this problem by using `pushf`{.nasm} and `popf`{.nasm} to preserve the Sign flag. The Zen timer reports that with this approach it takes 16.45 ms to process 1000 array elements, or 16.45 us per element. Astoundingly, [Listing 8-15](#L815), which is exactly the same as [Listing 8-14](#L814) save that it uses `lahf`{.nasm} and `sahf`{.nasm} instead of `pushf`{.nasm} and `popf`{.nasm}, takes only 11.31 ms, or 11.31 us per array element — a performance improvement of 45%! (That's a 45% improvement in *the whole loop*; the performance advantage of just `lahf`{.nasm} and `sahf`{.nasm} versus `pushf`{.nasm} and `popf`{.nasm} in this loop is far greater, in the neighborhood of 200%.)

## A Brief Digression on Optimization

As is always the case, there are other solutions to the programming task at hand than those shown in [Listings 8-14](#L814) and [8-15](#L815). For example, the Sign flag could be tested immediately after the addition, as shown in [Listing 8-16](#L816). The approach of [Listing 8-16](#L816) is exactly equivalent to [Listings 8-14](#L814) and [8-15](#L815), but eliminates the need to preserve the flags. [Listing 8-16](#L816) executes in 10.78 us per array element, a slight improvement over [Listing 8-15](#L815).

Let's look at the code in [Listing 8-16](#L816) for a moment more, since it's often true that even heavily-optimized code will yield a bit more performance with a bit of effort. What's looks less-than-optimal about [Listing 8-16](#L816)? `add`{.nasm} is pretty clearly indispensible, as is `inc`{.nasm}. However, there are two jumps inside the loop; if we could manage with one jump, things should speed up a bit. With a bit of ingenuity, it is indeed possible to get by with one jump, as shown in [Listing 8-17](#L817).

The key to [Listing 8-17](#L817) is that the `inc`{.nasm} instruction that points BX to the next memory location is moved ahead of the addition, allowing us to put the conditional jump at the bottom of the loop without the necessity of preserving the flags for several instructions (as is done in [Listings 8-14](#L814) and [8-15](#L815)). [Listing 8-17](#L817) looks to be much faster than [Listing 8-16](#L816). After all, it's a full instruction shorter in the loop than [Listing 8-16](#L816), and two bytes shorter in the loop as well. Still, we only trust what we measure, so let's compare actual performance.

Incredibly, the Zen timer reports that [Listing 8-17](#L817) executes in 10.78 us per array element — *no faster than*[Listing 8-16](#L816)*!* Why isn't [Listing 8-17](#L817) faster? To be honest, I don't know. [Listing 8-17](#L817) probably wastes some prefetches at the bottom of the loop, where `add [bx],al`{.nasm}, a slow, short instruction that allows the prefetch queue to fill, is followed by a jump that flushes the queue. There may also be interaction between the memory operand accesses of the `add`{.nasm} instruction and prefetching that works to the relative benefit of [Listing 8-16](#L816). There may be synchronization with DRAM refresh taking place as well.

I could hook up the hardware I used in Chapter 5 to find the answer, but that takes considerable time and money and simply isn't worth the effort. As we've established in past chapters, we'll never understand the exact operation of 8088 code — that's why we have to use the Zen timer to monitor performance. The important points of this exercise in optimization are these: we created shorter, faster code by examining a programming problem from a new perspective, and we measured that code and found that it actually ran no faster than the new code.

Bring your knowledge and creativity to bear on improving your code. Then use the Zen timer to make sure you've really improved the code!

Interesting optimizations aside, `lahf`{.nasm} and `sahf`{.nasm} are always preferred to `pushf`{.nasm} and `popf`{.nasm} whenever you can spare AH and don't need to save the interrupt, overflow, and direction flags, all the more so when you don't *want* to save those flags or don't want to have to use the stack to store flag states. Who would ever have thought that two warmed-over 8080 instructions could be so useful?

### Onward Through the Instruction Set

Given the extent to which the 8080 influenced the decidedly unusual architecture and instruction set of the 8088, it is interesting (although admittedly pointless) to wonder what might have been had the 8080 been less successful, allowing Intel to make a clean break with the past when the 8088 was designed. Still, the 8088 is what it is — so it's on to the rest of the instruction set for us.
