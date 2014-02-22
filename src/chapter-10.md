# Chapter 10: String Instructions: The Magic Elixir

The 8088's instruction set is flexible, full-featured, and a lot of fun to work with. On the whole, there's just one thing that seriously ails the 8088's instruction set, and that's lousy performance. Branches are slow, memory accesses are slow, and even register-only instructions are slowed by the prefetch queue cycle-eater. Let's face it: most 8088 code just doesn't run very fast.

Don't despair, though. There's a sure cure for the 8088 performance blues: the magic elixir of the string instructions. The string instructions are like nothing else in the 8088's instruction set. They're compact — 1 byte apiece — so they're not much affected by the prefetch queue cycle-eater. A single string instruction can be repeated up to 65,535 times, avoiding both branching and instruction fetching. String instructions access memory faster than most 8088 instructions, and can advance pointers and decrement counters into the bargain. In short, string instructions can do more with fewer cycles than other 8088 instructions.

Of course, nothing is perfect in this imperfect world, and the string instructions are no exception. The major drawback to the string instructions is that there are just so darn *few* of them — five, to be exact. The only tasks that can be performed with string instructions are reading from memory, writing to memory, copying from memory to memory, comparing a byte or word to a block of memory, and comparing two blocks of memory. That may sound like a lot, but in truth it isn't. The many varieties of normal (non-string) instructions can add constants to memory, shift memory, perform logical operations with memory operands, and much more, far exceeding the limited capabilities of the five string instructions. What's more, the normal instructions can work with a variety of registers and can address memory in all sorts of ways, while string instructions are very restrictive in terms of register usage and memory addressing modes.

That doesn't mean that the string instructions are of limited value — far from it, in fact. What it does mean is that your programs must be built around the capabilities of the string instructions if they are to run as fast as possible. As you learn to bring string instructions to bear on your programming tasks, you'll find that the performance of your code improves considerably.

In other words, use string instructions whenever you possibly can, and try to think of ways to use them even when it seems you can't.

## A Quick Tour of the String Instructions

Odds are good that you're already at least somewhat conversant with the string instructions, so I'm not going to spend much time going over their basic functionality. I am going to summarize them briefly, however; I want to make sure that we're speaking the same language, and I also want you to be as knowledgeable as possible about these key instructions.

After we've discussed the individual string instructions, we'll cover a variety of important and often non-obvious facts, tips, and potential problems associated with the string instructions. Finally, in the next chapter we'll look at some powerful applications of the string instructions.

This chapter is a tour of the string instructions, not a tutorial. We'll be moving fast — while we'll hit the important points about the string instructions, we won't linger. At times I'll refer to some material that's not covered until later in this chapter or the next. Alas, that sort of forward reference is unavoidable with a topic as complex as the string instructions. Bear with me, though — by the end of the next chapter, I promise that everything will come together.

### Reading Memory: `lods`

`lodsb` ("load string byte") reads the byte addressed by DS:SI (the source operand) into AL and then either increments or decrements SI, depending on the setting of the direction flag, as shown in Figure 10.1.

![](images/fig10.1RT.png)

`lodsw` ("load string word") reads the word addressed by DS:SI into AX and then adds or subtracts 2 to or from SI, again depending on the state of the direction flag. In either case, the use of DS as the segment can be overridden, as we'll see later.

We'll discuss the direction flag in detail later on. For now, let's just refer to string instructions as "advancing" their pointers, with the understanding that advancing means either adding or subtracting 1 or 2, depending on the direction flag and the data size.

`lods` is particularly useful for reading the elements of an array or string sequentially, since SI is automatically advanced each time `lods` is executed.

`lods` is considerably more limited than, say, `mov reg8,[mem8]`. For instance, `lodsb` requires that AL be the destination and that SI point to the source operand, while the `mov` instruction allows any of the 8 general-purpose registers to be the destination and allows the use of any of the 16 addressing modes to address the source.

On the other hand, `lodsb` is shorter and a good deal faster than `mov`. `mov reg8,[mem8]` is between 2 and 4 bytes in length, while `lodsb` is exactly 1 byte long. `lodsb` also advances SI, an action which requires a second instruction (albeit a fast one), `inc si`, when `mov` is used.

Let's compare `lodsb` and `mov` in action. [Listing 10-1](#L1001), which loads AL and advances SI 1000 times with `mov` and `inc`, executes in 3.77 ms. [Listing 10-2](#L1002), which uses `lodsb` to both load and advance in a single instruction, is 33% faster at 2.83 ms. When two code sequences perform the same task and one of them is 33% faster and one-third the length, there can't be much doubt about which is better.

`lodsb` is even superior to `mov` when the time required to advance SI is ignored. Suppose, for example, that you were to load SI with a pointer into a look-up table. Would you be better off using `lods` or `mov` to perform the look-up, given that it doesn't matter in this case whether SI advances or not?

Use `lods`. [Listing 10-3](#L1003), which is [Listing 10-1](#L1001) modified to remove the `inc` instructions, executes in 3.11 ms. [Listing 10-2](#L1002), which uses `lodsb`, is one-half the length of [Listing 10-3](#L1003) and 10% faster, even though [Listing 10-3](#L1003) uses the shortest and fastest memory-accessing form of the `mov` instruction and doesn't advance SI.

Of course, if you specifically didn't *want* SI to advance, you'd be better off with `mov`, since there's no way to stop `lods` from advancing SI. (In fact, all the string instructions always advance their pointer registers, whether you want them to or not.)

I'm not going to contrast the other string instructions with their non-string equivalents in the next few sections; we'll get plenty of that later in the chapter. The rule we just established applies to the other string instructions as well, though: it's often better to use a string instruction than `mov` even when you don't need all the power of the string instruction. While it can be a nuisance to set up the registers for the string instructions, it's still usually worth using the string instructions whenever you can do so without going through too many contortions. In general, the string instructions simply make for shorter, faster code than their `mov`-based equivalents.

Never assume, though: string instructions aren't superior in *all* cases. Always time your code!

### Writing Memory: `stos`

`stosb` ("store string byte") writes the value in AL to the byte addressed by ES:DI (the destination operand) and then either increments or decrements DI, depending on the setting of the direction flag. `stosw` ("store string word") writes the value in AX to the word addressed by ES:DI and then adds or subtracts 2 to or from DI, again depending on the direction flag, as shown in Figure 10.2. The use of ES as the destination segment cannot be overridden.

![](images/fig10.2RT.png)

`stos` is the preferred way to initialize arrays, strings, and other blocks of memory, especially when used with the `rep` prefix, which we'll discuss shortly. `stos` also works well with `lods` for tasks that require performing some sort of translation while copying arrays or strings, such as conversion of a text string to uppercase. In this use, `lods` loads an array element into AL, the element is translated in AL, and `stos` stores the element to the new array. Put a loop around all that and you've got a compact, fast translation routine. We'll discuss this further in the next chapter.

### Moving Memory: movs

`movsb` ("move string byte") copies the value stored at the byte addressed by DS:SI (the source operand) to the byte addressed by ES:DI (the destination operand) and then either increments or decrements SI and DI, depending on the setting of the direction flag, as shown in Figure 10.3.

![](images/fig10.3RT.png)

`movsw` ("move string word") copies the value stored at the word addressed by DS:SI to the word addressed by ES:DI and then adds or subtracts 2 to or from SI or DI, again depending on the direction flag. The use of DS as the source segment can be overridden, but the use of ES as the destination segment cannot.

Note that the accumulator is not affected by `movs`; the data is copied directly from memory to memory, not by way of AL or AX.

`movs` is by far the 8088's best instruction for copying arrays, strings, and other blocks of data from one memory location to another.

### Scanning Memory: scas

`scasb` ("scan string byte") compares AL to the byte addressed by ES:DI (the source operand) and then either increments or decrements DI, depending on the setting of the direction flag, as shown in Figure 10.4.

![](images/fig10.4aRT.png)

![](images/fig10.4bRT.png)

`scasw` ("scan string word") compares the value in AX to the word addressed by ES:DI and then adds or subtracts 2 to or from DI, again depending on the direction flag. The use of ES as the source segment cannot be overridden.

`scas` performs its comparison exactly as `cmp` does, by performing a trial subtraction of the memory location addressed by ES:DI from the accumulator without actually changing either the accumulator or the memory location. All the arithmetic flags — Overflow, Sign, Zero, Auxiliary Carry, Parity, and Carry — are affected by `scas`. That's easy to forget when you use `repz scas` or `repnz scas`, which can only terminate according to the status of the Zero flag. (We'll cover all the repeated string instruction below.)

`scas` is the preferred instruction for searching strings and arrays for specific values, and is especially good for looking up values in tables. Many programmers get so used to using `repz scas` and `repnz scas` that they forget that non-repeated `scas` instructions are more flexible than their repeated counterparts and can often be used when the repeated versions of `scas` can't. For example, suppose that we wanted to search a word-sized array for the first element greater than 10,000. [Listing 10-4](#L1004) shows code for doing this with non-string instructions. The code in [Listing 10-4](#L1004) runs in 10.07 ms.

Note that in [Listing 10-4](#L1004) the value 10,000 is placed in a register outside the loop in order to make the `cmp` instruction inside the loop faster and 2 bytes shorter. Also note that the code is arranged so that DI can be incremented *before* each comparison inside the loop, allowing us to get by with just one jump instruction. The alternative would be:

```nasm
SearchLoop:
    cmp   ax,[di]
    jb    SearchDone
    inc   di
    inc   di
    jmp   SearchLoop
SearchDone:
```

While this works perfectly well, it has not only the 4 instructions of the loop in [Listing 10-4](#L1004) but also an additional jump instruction, and so it's bound to be slower.

[Listing 10-5](#L1005) is functionally equivalent to [Listing 10-4](#L1004), but uses `scasw` rather than `cmp` and `inc`. That slight difference allows [Listing 10-5](#L1005) to run in 8.25 ms, 22% faster than [Listing 10-4](#L1004). While `scasw` works beautifully in this application, `rep scasw` would not have worked at all, since `rep scasw` can only handle equality/non-equality comparisons, not greater-than or less-than. If we had been thinking in terms of `rep scasw`, we might well have missed the superior `scasw` implementation. The moral: although repeated string instructions are the most powerful instructions of the 8088, don't forget that non-repeated string instructions are nearly as powerful and generally more flexible.

As another example, [Listing 10-6](#L1006) shows a `lodsw`-based version of [Listing 10-4](#L1004). While this straightforward approach is faster than [Listing 10-4](#L1004) (it executes in 9.07 ms), it is clearly inferior to the `scasw`-based implementation of [Listing 10-5](#L1005). When you set out to tackle a programming problem, always think of the string instructions first... and think of *all* the string instructions. The obvious solution is not necessarily the best.

### Notes on Loading Segments for String Instructions

You may have noticed that in [Listing 10-5](#L1005) I chose to use DI to load ES with the target segment. This is a useful practice to follow when setting up pointers in ES:DI for string instructions; since you know you're going to load DI with the target offset next, you can be sure that you won't accidentally wipe out any important data in that register. It's more common to use AX to load segment registers, since AX is the most general-purpose of registers, but why use AX — which *might* contain something useful — when DI is guaranteed to be free?

Similarly, I make a practice of using SI to load DS for string instructions, loading the offset into SI immediately after setting DS.

Along the same lines, I load the segment into DI in [Listing 10-5](#L1005) with the `seg` operator. You may prefer to load the name of the segment instead (for example, `mov di,DataSeg`). That's okay too, but consider this: you can't go wrong with the `seg` operator when you're loading a segment in order to access a specific named variable. Even if you change the name of the segment containing the array in [Listing 10-5](#L1005), the code will still assemble properly. The same cannot be said for loading DI with the name of the segment. The choice is yours, but personally I prefer to make my code as immune as possible to errors induced by later changes.

It may have occurred to you that in [Listing 10-5](#L1005) it would be faster to load DI with the target segment from DS rather than with a constant. That is:

```nasm
mov   di,ds
mov   es,di
```

is shorter and faster than:

```nasm
mov   di,seg WordArray
mov   es,di
```

True enough, and you should use the first approach whenever you can. I've chosen to use the latter approach in the listings in this chapter in order to make the operation of the string instructions clear, and to illustrate the most general case. After all, in many cases the destination segment for a string instruction won't be DS.

### Comparing Memory: `cmps`

`cmpsb` ("compare string byte") compares the byte addressed by DS:SI (the destination operand) to the byte addressed by ES:DI (the source operand) and then either increments or decrements SI and DI, depending on the setting of the direction flag. `cmpsw` ("compare string word") compares the value stored at the word addressed by DS:SI to the word addressed by ES:DI and then adds or subtracts 2 to or from SI and DI, again depending on the direction flag, as shown in Figure 10.5.

![](images/fig10.5aRT.png)

![](images/fig10.5bRT.png)

The use of DS as the destination segment can be overridden, but the use of ES as the source segment cannot.

`cmps` performs its comparison as `cmp` does, by performing a trial subtraction of the memory location addressed by ES:DI from the memory location addressed by DS:SI without actually changing either location. As with `scas`, all six arithmetic flags are affected by `cmps`. The key difference between `scas` and `cmps` is that `scas` compares the accumulator to memory, while `cmps` compares two memory locations directly. The accumulator is not affected by `cmps` in any way; data is compared directly from one memory operand to the other, not by way of AL or AX. `cmps` is in a class by itself for comparing arrays, strings, and other blocks of memory data.

## Hither and Yon With the String Instructions

That does it for our quick tour of the individual string instructions. Now it's on to a variety of useful items about string instructions in general.

### Data Size, Advancing Pointers, and the Direction Flag

Each string instruction advances its associated pointer register (or registers) by one memory location each time it executes. `lods` advances SI, `stos` and `scas` advance DI, and `movs` and `cmps` advance both SI and DI. As we've seen, that's a very handy bonus of using the string instructions — not only do they access memory rapidly, they also advance pointers in that same short time. String instructions advance their pointer registers just once per execution. However, any string instruction prefixed with `rep` can execute — and consequently advance its pointer or pointers — thousands of times.

All that seems straightforward enough. There are complications, though: both the definition of "one memory location" and the direction in which the pointer or pointers advance can vary.

String instructions can operate on either byte-or word-sized data. We've already seen one way to choose data size: by putting the suffix "b" or "w" on the end of a string instruction's mnemonic. For example, `lodsb` loads a byte, and `cmpsw` compares two words. Later in the chapter we'll see another way to specify data size, along with ways to specify segment overrides for string instructions that access memory via SI.

When working with byte-sized data, string instructions advance their pointers by 1 byte per memory access, and when working with word-sized data, they advance their pointers by one word per memory access. So "one memory location" means whichever of 1 byte or 1 word is the data size of the instruction. That makes perfect sense given that the idea of using string instructions is to advance sequentially through the elements of a byte-or word-sized array.

Ah, but what exactly does "advance" mean? Do the pointer registers used by string instructions move to the next location higher in memory or to the next location lower in memory?

Both, actually. Or, rather, either one, depending on the setting of the Direction flag in the FLAGS register. If the Direction flag is set, string instructions move their pointers down in memory, subtracting either 1 or 2 — whichever is the data size — from the pointer registers. If the Direction flag is reset, string instructions move their pointers up in memory by adding either 1 or 2.

The Direction flag can be explicitly set with the `std` ("set Direction flag") instruction and reset with the `cld` ("clear Direction flag") instruction. Other instructions that load the FLAGS register, such as `popf` and `iret`, can alter the Direction flag as well. Be aware, however, that `sahf` does not affect the Direction flag, since it loads only the lower byte of the FLAGS register from AH. A glance at Figure 6-2 shows that the Direction flag resides in the upper byte of the FLAGS register.

The Direction flag doesn't seem like a big deal, but in fact it can be responsible for some particularly nasty bugs. The problem with the Direction flag is that it allows a given string instruction to produce two completely different results under what look to be the same circumstances — the same register settings, memory contents, and so on. In other words, the Direction flag makes string instructions modal, and the instruction that controls that mode at any given time — the `cld` or `std` that selected the string direction — may have occurred long ago, in a subroutine far, far away. A string instruction that runs perfectly most of the time can mysteriously crash the system every so often because a different Direction flag state was selected by seemingly unrelated code that ran thousands of cycles earlier.

What's the solution? Well, usually you'll want your string instructions to move their pointers up in memory, since that's the way arrays and strings are stored. (It's also the way people tend to think about memory, with storage running from low to high addresses.) There are good uses for counting down, such as copying overlapping source and destination blocks and searching for the last element in an array, but those are not the primary applications for string instructions. Given that, it makes sense to leave the Direction flag cleared at all times except when you explicitly need to move pointers down rather than up in memory. That way you can always count on your string instructions to move their pointers up unless you specify otherwise.

Unfortunately, that solution can only be used when you've written all the code in a program yourself, and done so in pure assembler. Since you have no control over the code generated by compilers or the code in third-party libraries, you can't rely on such code to leave the Direction flag cleared. I know of one language in which library functions do indeed leave the Direction flag set occasionally, and I've no doubt that there are others. What to do here?

The solution is obvious, though a bit painful: whenever you can't be sure of the state of the Direction flag, you absolutely *must* put it in a known state before using any of the string instructions. This causes your code to be sprinkled with `cld` and `std` instructions, and that makes your programs a bit bigger and slower. Fortunately, though, `cld` and `std` are 1-byte, 2-cycle instructions, so they have a minimal impact on size and performance. As with so much else about the 8088, it would have been nice if Intel had chosen to build direction into the opcode bytes of the string instruction, as they did with data size. Alas, Intel chose not to do so -so be sure the Direction flag is in the proper state each and every time you use a string instruction.

That doesn't mean you have to put a `cld` or `std` before *every* string instruction. Just be sure you know the state of the Direction flag when each string instruction is executed. For example, in [Listing 10 - 5](#L1005) `cld` is performed just once, outside the loop. Since nothing inside the loop changes the Direction flag, there's no need to set the flag again.

An important tip: *always* put the Direction flag in a known state in interrupt — handling code. Interrupts can occur at any time, while any code is executing -including BIOS and DOS code, over which you have no control. Consequently, the Direction flag may be in any state when an interrupt handler is invoked, even if your program always keeps the Direction flag cleared.

### The `rep` Prefix

Taken by themselves, the string instructions are superior instructions: they're shorter and faster than the average memory-accessing instruction, and advance pointer registers too. It's in conjunction with the `rep` prefix that string instructions really shine, though.

As you may recall from Chapter 7, a prefix is an instruction byte that modifies the operation of the following instruction. For example, segment override prefixes can cause many instructions to access memory in segments other than their default segments.

`rep` is a prefix that modifies the operation of the string instructions (and only the string instructions). `rep` is exactly 1 byte long, so it effectively doubles the 1-byte length of the string instruction it prefixes. Put another way, `movsb` is a 1-byte instruction, while `rep movsb` is effectively a 2-byte instruction, although it actually consists of a 1-byte prefix and a 1-byte instruction. What `rep` does to justify the expenditure of an extra byte is simple enough: it instructs the following string instruction to execute the number of times specified by CX.

Sounds familiar, doesn't it? It should — it's a lot like the "repeat CL times" capability of the shift and rotate instructions that we discussed in the last chapter. There is a difference, however. Because `rep` causes instructions to be repeated CX times, any string instruction can be repeated up to 65,535 times, rather than the paltry 255 times a shift or rotate can be repeated. Of course, there's really no reason to want to repeat a shift or rotate more than 16 times, but there's plenty of reason to want to do so with the string instructions. By repeating a single string instruction CX times, that instruction can, if necessary, access every word in an entire segment. That's one — count it, *one* — string instruction!

The above description makes it sound as if string instruction repetitions are free. They aren't. A string instruction repeated *n* times takes about *n* times longer to execute than a single non-repeated instance of that instruction, as measured in Execution Unit cycles. There's some start-up time for repeated string instructions, and some of the string instructions take a cycle more or less per execution when repeated than when run singly. Nonetheless, the execution time of repeated string instructions is generally proportional to the number of repetitions.

That's okay, though, because repeated string instructions do the next best thing to running in no time at all: *they beat the prefetch queue cycle-eater.* How? By performing multiple repetitions of an instruction with just one instruction fetch. When you repeat a string instruction, you're basically executing multiple instances of that instruction without having to fetch the extra instruction bytes. For instance, as shown in Figure 10.6, the `rep` prefix lets this:

```nasm
sub   di,di
mov   ax,0a000h
mov   es,ax
sub   ax,ax
mov   cx,10
cld
rep   stosw
```

replace this:

```nasm
sub    di,di
mov    ax,0a000h
mov    es,ax
sub    ax,ax
cld
stosw
stosw
stosw
stosw
stosw
stosw
stosw
stosw
stosw
stosw
```

![](images/fig10.6RT.png)

The `rep`-based version takes a bit more set-up, but it's worth it. Because `rep stosw` (requiring one 2-byte instruction fetch) replaces ten `stosw` instructions (requiring ten 1-byte instruction fetches), we can replace 20 instruction bytes with 15 instruction bytes. The instruction fetching benefits should be obvious.

No doubt you'll look at the last example and think that it would be easy to reduce the number of instruction bytes by using a loop, such as:

```nasm
    sub   di,di
    mov   ax,0a000h
    mov   es,ax
    sub   ax,ax
    cld
    mov   cx,10
ClearLoop:
    stosw
    loop  ClearLoop
```

True enough, that would reduce the count of instruction bytes to 16 — but it wouldn't reduce the overhead of instruction fetching in the least. In fact, it would *increase* the instruction fetch overhead, since a total of 43 bytes — including 3 bytes each of the 10 times through the loop — would have to be fetched.

There's another reason that the `rep stosw` version of the last example is by far the preferred version, and that's branching (or the lack thereof). To see why this is, lets look at another example which contrasts `rep stosw` with a non-string loop.

### rep = No Instruction Fetching + No Branching

Suppose we want to set not 10 but 1000 words of memory to zero. [Listing 10-7](#L1007) shows code which uses `mov`, `inc`, and `loop` to do this in a respectable 10.06 ms.

By contrast, [Listing 10-8](#L1008) initializes the same 1000 words to zero with one repeated `stosw` instruction — *and no branches*. The result: the 1000 words are set to zero in just 3.03 ms. [Listing 10-8](#L1008) is over *three times* as fast as [Listing 10-7](#L1007), a staggeringly large difference between two well-written assembler routines.

Now you know why it's worth going out of your way to use string instructions.

Why is there so large a difference in performance between [Listings 10-7](#L1007) and [10-8](#L1008)? It's not because of instruction execution speed. Sure, `stos` is faster than `mov`, but a repeated `stosw` takes 14 cycles to write each word, while `mov [di],ax` takes 18 cycles, hardly a three-times difference.

The real difference lies in instruction fetching and branching. When [Listing 10-7](#L1007) runs, the 8088 must fetch 6 instruction bytes and write 2 data bytes per loop, which means that each loop takes at least 32 cycles — 4 cycles per memory byte accessed times 8 bytes — no matter what.

By contrast, because the 8088 simply holds a repeated string instruction inside the chip while executing it over and over, the loop-equivalent code in [Listing 10-8](#L1008) requires no instruction fetching at all after the 2 bytes of `rep stosw` are fetched. What's more, since the 8 cycles required to write the 2 data bytes fit neatly within the 14-cycle official execution time of a repeated `stosw`, that 14-cycle official execution time should be close to the actual execution time, apart from any effects DRAM refresh may have. Indeed, dividing 3.03 ms by 1000 repetitions reveals that each `stosw` takes 14.5 cycles — 3.03 us — to execute, which works out nicely as 14 cycles plus about 4% DRAM refresh overhead.

Let's look at this from a different perspective. The 8088 must fetch 6000 instruction bytes (6 bytes per loop times 1000 loops, as shown in Figure 10.7) when the loop in [Listing 10-7](#L1007) executes.

![](images/fig10.7RT.png)

The `rep stosw` instruction in [Listing 10-8](#L1008), on the other hand, requires the fetching of exactly 2 instruction bytes *in total*, as shown in Figure 10.8 — quite a difference!

![](images/fig10.8RT.png)

Better still, the prefetch queue can fill completely whenever a string instruction is repeated a few times. Fast as string instructions are, they don't keep the bus busy all the time. Since repetitions of string instructions require no additional instruction fetching, there's plenty of time for the instruction bytes of the following instructions to be fetched while string instructions repeat. On balance, then, repeated string instructions not only require very little fetching for a great many executions, but also allow the prefetch queue to fill with the bytes of the following instructions.

There's more to the difference between [Listings 10-7](#L1007) and [10-8](#L1008) than just prefetching, however. The 8088 must not only fetch the bytes of the instructions in the loop in [Listing 10-7](#L1007) over and over, but must also perform one `loop` instruction per word written to memory, and that's costly indeed. Although `loop` is the 8088's most efficient instruction for repeating code by branching, it's slow nonetheless, as we'll see in Chapter 12. Each `loop` instruction in [Listing 10-7](#L1007) takes at least 17 cycles to execute. That means that the code in [Listing 10-7](#L1007) spends more time looping than the code in [Listing 10-8](#L1008) spends *in total* to initialize each word!

Used properly, repeated string instructions are truly the magic elixir of the PC. Alone among the 8088's instructions, they can cure the most serious performance ills of the PC, the prefetch queue cycle-eater and slow branching. The flip side is that repeated string instructions are much less flexible than normal instructions. For example, while you can do whatever you want inside a loop terminated with `loop`, all you can do during a repeated string instruction is the single action of which that instruction is capable. Even so, the performance advantages of repeated string instructions are so great that you should try to use them at every opportunity.

### `repz` and `repnz`

There are two special forms of `rep` — `repz` and `repnz` — designed specifically for use with `scas` and `cmps`. The notion behind these prefixes is that when you repeat one of the comparison string instructions, you want the repeated comparison to end either the first time a specified match does occur or the first time that match *doesn't* occur.

`repnz` ("repeat while not Zero flag") causes the following `scas` or `cmps` to repeat until either the string instruction sets the Zero flag (indicating a match) or CX counts down to zero. For instance, the following compares `ByteArray1` to `ByteArray2` until either a position at which the two arrays differ is found or 100 bytes have been checked:

```nasm
mov   si,seg ByteArray1
mov   ds,si
mov   si,offset ByteArray1
mov   di,seg ByteArray2
mov   es,di
mov   di,offset ByteArray2
mov   cx,100
cld
repnz cmpsb
```

`repnz` also goes by the name of `repne`; the two are
interchangeable.

`repz` ("repeat while Zero flag") causes the following `scas` or `cmps` to repeat until either the string instruction resets the Zero flag (indicating a non-match) or CX counts down to zero. For instance, the following scans `WordArray` until either a non-zero word is found or 1000 words have been checked:

```nasm
mov   di,seg WordArray
mov   es,di
mov   di,offset WordArray
sub   ax,ax
mov   cx,1000
cld
repz  scasw
```

`repz` is also known as `repe`.

How do you know whether a repeated `scas` or `cmps` has found its termination condition — match or non-match — or simply run out of repetitions? By way of the Zero flag, of course. If — and only if — the Zero flag is set after a `repnz scas` or `repnz cmps`, then the desired match was found. Likewise, if and only if the Zero flag is reset after a `repz scas` or `repz cmps` was the desired non-match found.

As I pointed out earlier, repeated `scas` and `cmps` instructions are not as flexible as their non-repeated counterparts. When used singly, `scas` and `cmps` set all the arithmetic flags, which can be tested with the appropriate conditional jumps. Although these instructions still set all the arithmetic flags when repeated, they can terminate only according to the state of the Zero flag.

Beware of accidentally using just plain `rep` with `scas` or `cmps`. MASM will accept a dubious construct such as `rep scasw` without complaint and dutifully generate a `rep` prefix byte. Unfortunately, the same byte that MASM generates for `rep` with `movs`, `lods`, and `stos` means `repz` when used with `scas` and `cmps`. Of course, `repz` may not have been at all what you had in mind, and because `rep scas` and `rep cmps` *look* all right and assemble without warning, this can lead to some difficult debugging. It's unfortunate that MASM doesn't at least generate a warning when it encounters `rep scas` or `rep cmps`, but it doesn't, so you'll just have to watch out for such cases yourself.

(Don't expect too much from MASM, which not only accepts a number of dubious assembler constructs — as we'll see again later in this chapter — but also has some out-and-out bugs. If something just doesn't seem to assemble properly, no matter what you do, then the problem is most likely a bug in MASM. This can often be confirmed by running the malfunctioning code through TASM, which generally has far fewer bugs than MASM — and my experience is that the bugs it does have are present for MASM compatibility!)

`repnz` is ideal for all sort of searches and look-ups, as we'll see at the end of the chapter. `repz` is less generally useful, but can serve to find the first location at which a sequence of repeated values ends. For example, suppose you wanted to find the last non-blank character in a buffer padded to the end with blanks. You could set the Direction flag, point DI to the last byte of the buffer, set CX to the length of the buffer, and load AL with a space character. A fairly elaborate set-up sequence, true — but then a single `rep scasb` would then find the last non-blank character for you. We'll look at this application in more detail in the next chapter.

### `rep` is a Prefix, Not an Instruction

I'd like to take a moment to point out that `rep`, `repz`, and `repnz` are prefixes, not instructions. When you see code like:

```nasm
cld
rep   stosw
jmp   Test
```

you may well get the impression that `rep` is an instruction and that `stosw` is some sort of operand. Not so — `rep` is a prefix, and `stosw` is an instruction. A more appropriate way to show a repeated `stosw` might be:

```nasm
      cld
rep   stosw
      jmp   Test
```

which makes it clear that `rep` is a prefix by putting it to the left of the instruction field. However, MASM considers both forms to be the same, and since it has become the convention in the PC world to put `rep` in the mnemonic column, I'll do the same in *The Zen of Assembly Language*. Bear in mind, though, that `rep` is not an instruction.

Also remember that `rep` only works with string instructions. Lines like:

```nasm
rep   mov   [di],al
```

don't do anything out of the ordinary. If you think about it, you'll realize that that's no great loss; there really isn't any reason to want to repeat a non-string instruction. Without the automatically-advanced pointers that only the string instructions offer, the action of a repeated non-string instruction would simply be repeated over and over, to no useful end. At any rate, like it or not, if you try to repeat a non-string instruction the repeat prefix is ignored.

### Of Counters and Flags

When you use CL as a count for a shift or rotate instruction, CL is left unchanged by the instruction. Not so with CX and `rep`. Repeated string instructions decrement CX once for each repetition. CX always contains zero after repeated `lods`, `stos`, and `movs` instructions finish, because those instructions simply execute until CX counts down to zero.

The situation is a bit more complex with `scas` and `cmps` instructions. These repeated instructions can terminate either when CX counts down to zero or when a match or non-match, as selected with `repz` or `repnz`, becomes true. As a result, `scas` and `cmps` instructions can leave CX with any value between 0 and *n*-1, where *n* is the value loaded into CX when the repeated instruction began. The value *n*-1 is left in CX if the termination condition for the repeated `scas` or `cmps` occurred on the first byte or word. CX counts down by 1 for each additional byte or word checked, ending up at 0 if the instruction was repeated the full number of times initially specified by CX.

Point number 1, then: CX is always altered by repeated string instructions.

By the way, while both repeated and non-repeated string instructions alter pointer registers, it's only *repeated* string instructions that alter CX. For example, after the following code is executed:

```nasm
mov   di,0b800h
mov   es,di
mov   di,1000h
mov   cx,1
sub   al,al
cld
stosb
```

DI will contain 1001h but CX will still contain 1. However, after the same code using a `rep` prefix is executed:

```nasm
mov   di,0b800h
mov   es,di
mov   di,1000h
mov   cx,1
sub   al,al
cld
rep   stosb
```

DI will contain 1001h and CX will contain 0.

As we saw earlier, repeated `scas` and `cmps` instructions count CX down to zero if they complete without encountering the terminating match or non-match condition. As a result, you may be tempted to test whether CX is zero — perhaps with the compact `jcxz` instruction — to see whether a repeated `scas` or `cmps` instruction found its match or non-match condition. *Don't do it!*

It's true that repeated `scas` and `cmps` instructions count CX down to zero if the termination condition isn't found — but this is a case of "if but *not* only if." These instructions also count CX down to zero if the termination condition is found on the last possible execution. That is, if CX was initially set to 10 and a `repz scasb` instruction is about to repeat for the tenth time, CX will be equal to 1. The next repetition will be performed, decrementing CX, regardless of whether the next byte scanned matches AL or not, so CX will surely be zero when the `repz scasb` ends, no matter what the outcome.

In short, always use the Zero flag, *not* CX, to determine whether a `scas` or `cmps` instruction found its termination condition.

There's another point to be made here. We've established that the flags set by a repeated `scas` or `cmps` instruction reflect the result of the last repetition of `scas` or `cmps`. Given that, it would seem that the flags can't very well reflect the result of decrementing CX too. (After all, there's only one set of flags, and it's already spoken for.) That is indeed the case: the changes made to CX during a repeated string instruction never affect the flags. In fact, `movs`, `lods`, and `stos`, whether repeated or not, never affect the flags at all, while `scas` and `cmps` only affect the flags according to the comparison performed.

There's a certain logic to this. The `loop` instruction, which `rep` resembles, doesn't affect any flags, even though it decrements CX and may branch on the result. You can view both `loop` and `rep` as program flow control instructions rather than counting instructions; as such, there's really no reason for them to set the flags. You set CX for a certain number of repetitions, and those repetitions occur in due course; where's the need for a status? Anyway, whether you agree with the philosophy or not, that's the way both `rep` and `loop` work.

### Of Data Size and Counters

We said earlier that CX specifies the number of times that a string instruction preceded by a `rep` prefix should be repeated. Be aware that CX literally controls the number of repeated executions of a string instruction, not the number of memory accesses. While that seems easy enough to remember, consider the case where you want to set every element of an array containing 1000 8-bit values to 1. The obvious approach to setting the array is shown in [Listing 10-9](#L1009), which sets the array in 2.17 ms.

While [Listing 10-9](#L1009) is certainly fast, it is not the ideal way to initialize this array. It would be far better to repeat `stos` half as many times, writing 2 bytes at a time with `stosw` rather than 1 byte at a time with `stosb`. Why? Well, recall that way back in Chapter 4 we found that the 8088 handles the second byte of a word-sized memory access in just 4 cycles. That's faster than any normal instruction can handle that second byte, and, as it turns out, it's faster than `rep stosb` can handle a second byte as well. While `rep stosw` can write the second byte of a word access in just 4 cycles, for a total time per word written of 14 cycles, `rep stosb` requires 10 cycles for each byte, for a total time per word of 20 cycles. The same holds true across the board: you should use string instructions with word-sized data whenever possible.

[Listing 10-10](#L1010) illustrates the use of word-sized data in initializing the same array to the same values as in Listing 109. As expected, [Listing 10-10](#L1010) is considerably faster than [Listing 10-9](#L1009), finishing in just 1.52 ms. In fact, the ratio of the execution time of [Listing 10-9](#L1009) to that of [Listing 10-10](#L1010) is 1.43, which happens to be a ratio of 10/7, or 20/14. That should ring a bell, since it's the ratio of the execution time of two `rep stosb` instructions to one `rep stosw` instruction.

All well and good, but we didn't set out to compare the performance of word-and byte-sized string instructions. The important point in [Listing 10-10](#L1010) is that since we're using `rep stosw`, CX is loaded with `ARRAY_LENGTH/2`, the array length in words, rather than `ARRAY_LENGTH`, the array length in bytes. Of course, it is `ARRAY_LENGTH`, not `ARRAY_LENGTH/2`, that's the actual length of the array as measured in byte-sized array elements. When you're thinking of a `rep stosw` instruction as clearing a byte array of length `ARRAY_LENGTH`, as we are in [Listing 10-10](#L1010), it's *very* easy to slip and load CX with `ARRAY_LENGTH` rather than `ARRAY_LENGTH/2`. The end result is unpredictable but almost surely unpleasant, as you'll wipe out the contents of the `ARRAY_LENGTH` bytes immediately following the array.

The lesson is simple: whenever you use a repeated word-sized string instruction, make sure that the count you load into CX is a count in words, not in bytes.

### Pointing Back to the Last Element

Sometimes it's a little tricky figuring out where your pointers are after a string instruction finishes. That's because each string instruction advances its pointer or pointers only *after* performing its primary function, so pointers are always one location past the last byte or word processed, as shown in Figures 10.9 and 10.10. This is definitely a convenience with `lods`, `stos`, and `movs`, since it always leaves the pointers ready for the next operation. However, it can be a nuisance with `scas` and `cmps`, because it complicates the process of calculating exactly where a match or non-match occurred.

![](images/fig10.9RT.png)

![](images/fig10.10RT.png)

Along the same lines, CX counts down one time more than you might expect when repeated `scas` and `cmps` instructions find their termination conditions. Suppose, for instance, that a `repnz scasb` instruction is started with CX equal to 100 and DI equal to 0. If the very first byte, byte 0, is a match, the `repnz scasb` instruction will terminate. However, CX will contain 99, not 100, and DI will contain 1, not 0.

We'll return to this topic in the next chapter. For now, just remember that string instructions never leave their pointers pointing at the last byte or word processed, and repeated `scas` and `cmps` instructions count down CX one more time than you'd expect.

### Handling Very Small and Very Large Blocks

The repeated string instructions have some interesting boundary conditions. One of those boundary conditions occurs when a repeated string instruction is executed with CX equal to zero.

When CX is zero, the analogy of `rep` to `loop` breaks down. A `loop`-based loop entered with CX equal to zero will execute 64 K times, as CX decrements from 0 to 0FFFFh and then all the way back down to 0. However, a repeated instruction executed with CX equal to zero won't even execute once! That actually can be a useful feature, since it saves you from having to guard against a zero repeat count, as you do with `loop`.

(Be aware that if you repeat `scas` or `cmps` with CX equal to 0, no comparisons will be performed *and no flags will be changed*. This means that when CX could possibly be set to 0, you must actively check for that case and skip the comparison if CX is indeed 0, as follows:

```nasm
    jcxz  NothingToTest
    repnz scasb
    jnz   NoMatch
    ; A match occurred.
          :
    ; No match occurred.
NoMatch:
          :
    ; There was nothing to scan, which is usually handled either
    ; as a non-match or as an error.
NothingToTest:
```

Otherwise, you might unwittingly end up acting on flags set by some earlier instruction, since either `scas` or `cmps` repeated zero times will leave those flags unchanged.)

However, as Robert Heinlein was fond of saying, there ain't no such things as a free lunch. What `rep` giveth with small (zero-length) blocks it taketh away with large (64 Kb) blocks. Since a zero count causes nothing to happen, the largest number of times a string instruction can be repeated is 0FFFFh, which is not 64 K but 64 K-1. That means that a byte-sized repeated string instruction can't *quite* cover a full segment. That can certainly be a bother, since it's certainly possible that you'll want to use repeated string instructions to initialize or copy arrays and strings of any length between 0 and 64 K bytes — inclusive. What to do?

First of all, let me point out that there's never a problem in covering large blocks with *word-sized* repeated string instructions. A mere 8000h repetitions of any word-sized string instruction will suffice to cover an entire segment. Additional repetitions are useless — which brings us to another interesting point about string instructions. String instructions can handle a maximum of 64 K bytes, and then only *within a single segment*.

You'll surely recall that string instructions advance pointer registers. Those pointer registers are SI, DI or both SI and DI. Notice that we didn't mention anything about advancing DS, ES, or any other segment register. That's because the string instructions don't affect the segment registers. The implication should be pretty obvious: like all the memory addressing instructions of the 8088, the string instructions can only access those bytes that lie within the 64 Kb ranges of their associated segment registers, as shown in Figure 10.11. (We'll discuss the relationships between the segment registers and the string instructions in detail shortly.)

![](images/fig10.11RT.png)

Granted, `movs` and `cmps` can access source bytes in one 64 Kb block and destination bytes in another 64 Kb block, but each pointer register has a maximum range of 64 K, and that's that.

While the string instructions are limited to operating within 64 Kb blocks, that doesn't mean that they stop advancing their pointers when they hit one end or the other of one of those 64 Kb blocks — quite the contrary, in fact. Upon hitting one end of a 64 Kb block, the string instructions keep right on going at the *other* end of the block. This somewhat odd phenomenon springs directly from the nature of the pointer registers used by the string instructions, as follows.

The largest value a 16-bit register can contain is 0FFFFh. Consequently, SI and DI turn over from 0FFFFh to 0 as they are incremented by a string instruction (or from 0 to 0FFFFh as they're decremented.) This effectively causes each string instruction pointer to wrap when it reaches the end of the segment it's operating within, as shown in Figure 10.12.

![](images/fig10.12aRT.png)

![](images/fig10.12bRT.png)

This means that a string instruction can't access part or all of just *any* 64 Kb block starting at a given segment:offset address, but only the 64 Kb block starting at the address *segment*:0, where *segment* is whichever of CS, DS, ES, or SS the string instruction is using. For instance:

```nasm
mov   di,0a000h
mov   es,di
mov   di,8000h
mov   cx,8000h
sub   ax,ax
cld
rep   stosw
```

won't clear the 32 K words starting at A000:8000, but rather the 32 K words starting at A000:0000. The words will be cleared in the following order: the words from A000:8000 to A000:FFFE will be cleared first, followed by the words from A000:0000 to A000:7FFE, as shown in Figure 10.13.

![](images/fig10.13RT.png)

Now you can see why it's pointless to repeat a word-sized string instruction more than 8000h times. Repetitions after 8000h simply access the same addresses as the first 8000h repetitions, as shown in Figure 10.14.

![](images/fig10.14aRT.png)

![](images/fig10.14bRT.png)

That brings us back to the original problem of handling both zero-length and 64 Kb blocks that consist of byte-sized elements. It should be clear that there's no way that a single block of code can handle both zero-length and 64 Kb blocks unless the block length is stored in something larger than a 16-bit register. Handling both the zero-length and 64 Kb cases and everything in-between takes 64 K+1 counter values, one more than the 64 K values that can be stored in 16 bits. Simply put, if CX is zero, that can mean "handle zero bytes" or "handle 64 K bytes,"but it can't mean both.

If you want to take CX equal to zero to mean "handle zero bytes," you're all set — that's exactly how repeated string instructions work, as described above. For example, the subroutine `BlockClear` in [Listing 10-11](#L1011) clears a block of memory between zero and 64 K-1 bytes in length; as called in [Listing 10-11](#L1011), `BlockClear` clears a 1000-byte block in 2.18 ms. If you want to take CX equal to zero to mean "handle 64 K bytes," however, you have to do a bit of work — but there's an opportunity for higher performance there as well.

The obvious way to handle 64 K bytes with a single repeated string instruction is to simply perform 32 K word-sized operations. Now, that's fine for blocks that are exactly 64 K bytes long, but what about blocks between 1 and 64 K-1 bytes long? Such blocks may be an odd number of bytes in length, so we can't just divide the count by two and perform a word-sized repeated string instruction.

What we can do, however, is divide the byte count by two, perform a word-sized repeated string instruction, and then make up the odd byte (if there is one) with a byte-sized non-repeated string instruction. The subroutine `BlockClear64` in [Listing 10-12](#L1012) does exactly that. [Listing 10-12](#L1012) divides the count by two with a `rcr` instruction, converting zero counts into 32 K-word counts in the process. Next, `BlockClear64` clears memory in word-sized chunks with `rep stosw`. Finally, one extra `stosb` is performed if there was a carry from the `rcr` — that is, if the array is an odd number of bytes in length — in order to clear the last byte of the array.

[Listing 10-12](#L1012), unlike [Listing 10-11](#L1011), is capable of handling blocks between 1 and 64 K bytes in length. The more interesting thing about [Listing 10-12](#L1012), however, is that it's *fast*, clocking in at 1.55 ms, about 41% faster than [Listing 10-11](#L1011). Why? Well, as we found earlier, we're always better off using word-sized rather than byte-sized string instructions. A side-effect of [Listing 10-12](#L1012) is that initialization of byte-sized data is performed almost entirely with word-sized string instructions, and that pays off handsomely.

You need not be copying full 64 Kb blocks in order to use the approach of [Listing 10-12](#L1012). It's worth converting any byte-sized string instruction that's repeated more than a few times to use a word-sized string instruction followed by a final conditional byte-sized instruction. For instance, [Listing 10-13](#L1013) is functionally identical to [Listing 10-11](#L1011), but is 5 bytes longer and executes in just 1.54 ms, thanks to the use of a word-sized `rep stos`. That's the same 41% improvement that we got in [Listing 10-12](#L1012), which isn't surprising considering that [Listings 10-12](#L1012) and [10-13](#L1013) both spend virtually all of their time performing repeated `stosw` instructions. I'm sure you'll agree that a 41% speed-up is quite a return for the expenditure of 5 bytes.

Once again: *use word-rather than byte-sized string instructions whenever you can.*

### Words of Caution

Before we take our leave of the issue of byte-versus word-sized string instructions, I'd like to give you a couple of warnings about the use of word-sized string instructions.

You must exercise additional caution when using word-sized string instructions on the 8086, 80286, and 80386 processors. The 8086 and 80286 processors access word-sized data that starts at an even address (word-aligned data) twice as fast as word-sized data that starts at an odd address. This means that code such as that in [Listing 10-13](#L1013) would run at only half speed on an 8086 or 80286 if the start of the array happened to be at an odd address. This can be solved by altering the code to detect whether arrays start at odd or even addresses and then performing byte moves as needed to ensure that the bulk of the operation — performed with a repeated word-sized instruction — is word-aligned.

The 80386 has similar constraints involving doubleword alignment. We'll discuss the issue of word and doubleword alignment in detail in Chapter 15. For now just be aware that while the word-sized string instruction rule for the 8088 is simple — use word-sized string instructions whenever possible — there are additional considerations, involving alignment, for the other members of the 8086 family.

The second warning concerns the use of word-sized string instructions to access EGA and VGA display memory in modes 0Dh, 0Eh, 0Fh, 10h, and 12h. In each these modes it's possible to copy 4 bytes of video data -1 byte from each of the four planes at once by loading the 4 bytes into four special latches in the adapter with a single read and then storing all 4 latches back to display memory with a single write, as shown in Figure 10.15.

![](images/fig10.15RT.png)

Use of the latches can greatly speed graphics code; for example, copying via the latches can improve the performance of tasks that require block copies from one part of display memory to another, such as scrolling, by a factor of four over normal byte-at-a-time copying techniques.

Unfortunately, because each latch can store only 1 byte, the latches only work properly with byte-sized string instructions. Word-sized string instructions cause the latches to be loaded twice per word-sized read from display memory: once for the lower byte of each word, then again for the upper byte, wiping out the data read from the lower byte. Consequently, only half of each word is really transferred. The end result is that half the data you'd expect to copy is missing, and the other half is copied twice.

The EGA/VGA latches are complex, and now is not the time to describe them in detail. We'll return to the latches in Volume II of *The Zen of Assembly Language*. For now, remember this: don't use word-sized string instructions to copy data from one area to another of EGA/VGA display memory via the latches.

### Segment Overrides: Sometimes You Can, Sometimes You Can't

We've said that string instructions advance only their pointers, not their segments, so they can only access memory within the 64 Kb block after a given segment. That raises the question of which segments the string instructions access by default, and when the default segment selections can be overridden.

The rules for default segments are simple. String instructions that use DI as a pointer register (`stos` and `movs` for the destination operand, and `scas` and `cmps` for the source operand) use DI as an offset in the ES segment. String instructions that use SI as a pointer register (`lods` and `movs` for the source operand, and `cmps` for the destination operand) use SI as an offset in the DS segment.

The rule for segment overrides is equally simple. Accesses via DI must go to the ES segment; that cannot be overridden. Accesses via SI default to the DS segment, but that default can be overridden. In other words, the source segment for `lods` and `movs` and the destination segment for `cmps` can be any of the four segments, but the destination segment for `stos` and `movs` and the source segment for `scas` and `cmps` must be ES.

How do we tell MASM to override the segment for those string instructions that allow segment overrides? While we're at it, how do we specify the size — word or byte — of a string instruction's data? Both answers lie in the slightly unusual way in which string instructions are coded in 8088 assembler.

String instructions are odd in that operands are optional. `stosb` with no operands means "perform a byte-sized `stos`," and `cmpsw` with no operands means "perform a word-sized `cmps`." There really isn't any need for explicit operands to string instructions, since the memory operands are fully implied by the contents of the SI, DI, and segment registers.

However, MASM is a strongly-typed assembler, meaning that MASM considers named memory operands to have inherent types — byte, word, and so on. Consequently, MASM lets you provide operands to string instructions, *even though those operands have no effect on the memory location actually accessed*! MASM uses operands to string instructions to check segment accessibility (by way of the `assume` directive, which is a bit of a kludge — but that's another story), to decide whether to assemble byte-or word-sized string instructions, and to decide whether to perform segment overrides — and that's all.

For example, the following is a valid `movs` instruction that copies `SourceWord` to `DestWord`:

```nasm
SourceWord  dw   1
DestWord    dw   ?
    :
    mov   si,seg SourceWord
    mov   ds,si
    mov   si,offset SourceWord
    mov   di,seg DestWord
    mov   es,di
    mov   di,offset DestWord
    movs  es:[DestWord],[SourceWord]
```

There's something strange here, though, and that's that the operands to `movs` have *nothing* to do with the source and destination addresses.

Why? String instructions don't contain any addresses at all; they're only 1 byte long, so there isn't even room for a *mod-reg-rm* byte. Instead, string instructions use whatever addresses are already in DS:SI and ES:DI. By providing operands to `movs` in the last example, you've simply told the assembler to *assume* that DS:SI points to `SourceWord` and ES:DI points to `DestWord`. The assembler uses that information only to decide to assemble a `movsw` rather than a `movsb`, since the operands are word-sized. If you had set up SI or DI to point to a different variable, the assembler would never have known, and the `movs` operands would only have served to confuse you when you tried to debug the program. For example:

```nasm
SourceWord  dw  1
DestWord    dw  ?
    :
    mov   di,seg SourceWord
    mov   es,di
    mov   di,offset SourceWord
    mov   si,seg DestWord
    mov   ds,si
    mov   si,offset DestWord
    movs  es:[DestWord],[SourceWord]
```

actually copies `DestWord` to `SourceWord`, despite the operands to `movs`. Seems pretty silly, doesn't it? That's MASM, though.

(Actually, that's not the worst of it. Try assembling:

```nasm
movs  byte ptr es:[bx],byte ptr [di]
```

which features not one but *two* memory addressing modes that can't be used by `movs`. MASM cheerfully assembles this line without complaint; it already knows the addressing modes used by `movs`, so it pays little attention to the modes you specify.)

In short, operands to string instructions can be misleading and don't really provide any data-type information that the simple suffixes "b"and "w" on string instructions don't. Consequently, I prefer to steer clear of string instruction operands in favor of stand-alone string instructions such as `scasb` and `lodsw`. However, there's one case where operands are quite useful, and that's when you want to force a segment override.

Recall from Chapter 7 that a prefix like `DS:` can be placed on a memory operand in order to force a segment override on that memory access. Segment overrides work in just the same way with string instructions. For instance, we can modify our ongoing example to copy `SourceWord` to `DestWord`, with both operands accessed in ES, as follows:

```nasm
SourceWord  dw  1
DestWord    dw  ?
    :
    mov   si,seg SourceWord
    mov   es,si
    mov   si,offset SourceWord
    mov   di,offset DestWord
    movs  es:[DestWord],es:[SourceWord]
```

The segment override on `SourceWord` forces the 8088 to access the source operand at ES:SI rather than the default of DS:SI.

This is a less-than-ideal approach, however. For one thing, I'm still not fond of using meaningless and potentially misleading memory operands with string instructions. For another, there are many cases where SI and/or DI are passed to a subroutine that uses a string instruction, or where SI and/or DI can be set to point to any one of a number of memory locations before a string instruction is executed. In these cases, there simply isn't any single memory variable name that can legitimately be assigned to an operand.

Fortunately, there's an easy solution: specify the memory operands to string instructions as consisting of only the pointer registers in the form `[SI]` and `[DI]`. Here's our ongoing example with the pointer-register approach:

```nasm
SourceWord  dw  1
DestWord    dw  ?
    :
    mov   si,seg SourceWord
    mov   es,si
    mov   si,offset SourceWord
    mov   di,offset DestWord
    movs  word ptr es:[di],word ptr es:[si]
```

This code is acceptable, since the operands to `movs` merely confirm what we already know, that `movs` copies the data pointed to by SI to the location pointed to by DI. Note that the operator `word ptr` is required because the `movsw` form of `movs` doesn't accept operands (yet another quirk of MASM).

Now that we have a decent solution to the problem of generating segment overrides to string instructions, let's review what we've learned. The entire point of our discussion of operands to string instructions is simply that such operands make it possible to perform segment overrides with string instructions. If you don't need to perform segment overrides, I strongly suggest that you skip the operands altogether. Here's my preferred version of the first example in this section:

```nasm
SourceWord  dw  1
DestWord    dw  ?
    :
    mov   si,seg SourceWord
    mov   ds,si
    mov   si,offset SourceWord
    mov   di,seg DestWord
    mov   es,di
    mov   di,offset DestWord
    movsw
```

A final note. You may be tempted to try something like:

```nasm
movs  byte ptr ds:[di],byte ptr [si]
```

After all, it would be awfully convenient if string instruction accesses via DI didn't always have to be in ES. Go right ahead and try it, if you wish — but it won't work. It won't even assemble. (The same goes for trying to use registers or addressing modes other than those I've shown as operands to string instructions; MASM either ignores the operands or spits them out with an error message.)

Segment overrides on string instruction accesses via DI don't assemble because the ES segment must *always* be used when string instructions access operands addressed by DI. Why? There is no particular "why": for whatever reason, that's just the way the 8088 works. The 8088 doesn't have to make sense — inside the universe of PC programming, the quirks of the 8088 become laws of nature. Understanding those laws and making the best possible use of them is what the Zen of assembler is all about.

Then, too, if you had to choose one segment to be stuck with, it would certainly be ES. CS and SS can't be changed freely, and DS is often dedicated to maintaining a near data segment, but ES is usually free to point anywhere in memory. Remember also that the segments of all SI operands to string instructions can be overridden, so string instructions can access *any* operand — source, destination, or both — via the ES segment if that becomes necessary.

### The Good and the Bad of Segment Overrides

Should you use segment overrides with string instructions? That depends on the situation. Segment override prefixes take up 1 byte and take 2 cycles to execute, so you're better off without them if that's possible. When you use a string instruction repeatedly within a loop, you should generally set up the segment registers outside the loop in such a way that the string instruction can use its default segment or segments. If, on the other hand, you're using a string instruction to perform a single memory access, a segment override prefix is preferable to all the code required to set up the default segment registers for that instruction.

For example, suppose that we're calculating the 8-bit checksum of a 1000-byte array residing in a far segment. [Listing 10-14](#L1014), which reads the 1000 elements via a `lods` with an `ES:` prefix, runs in 9.06 ms. In contrast, [Listing 10-15](#L1015), which juggles the registers so that DS points to the array's segment for the duration of the loop, runs in just 7.56 ms.

Now suppose that we're reading a single memory location — also located in a far segment — with `lods`. [Listing 10-16](#L1016), which does this by loading ES and using an `ES:` override, runs in 10.35 us per byte read. [Listing 10-17](#L1017), which first preserves DS, then loads DS and reads the memory location via DS, the default segment for `lods`, and finally pops DS, runs in a considerably more leisurely 15.06 us per byte read. In this situation it pays to use the segment override.

By the way, there's an opportunity for tremendous performance improvement in [Listing 10-16](#L1016). The trick: just leave ES set for as long as necessary. [Listing 10-18](#L1018) performs exactly the same task as [Listing 10-16](#L1016), save that ES is loaded only once, at the start of the program. The result: an execution time of just 5.87 ms per byte read, a 76% improvement over [Listing 10-16](#L1016). What that means is that you should...

### ...Leave ES and/or DS Set for as Long as Possible

*When you're accessing far data, leave ES and/or DS (whichever you're using) set for as long as possible.* This rule may seem impractical, since it prevents the use of those registers to point to any other area of memory, but properly applied it has tremendous benefits.

For example, you can leave DS set for the duration of a loop that scans a far data array, as we did in [Listing 10-15](#L1015). This is one of the areas in which you can outshine any compiler. Typically, compilers reload both the segment and offset portions of far pointers on every use, even inside a loop. [Listing 10-19](#L1019), which is the sort of code a high-level language compiler would generate for the task of [Listing 10-15](#L1015), takes 25.14 ms to execute. [Listing 10-15](#L1015) is *232%* faster than [Listing 10-19](#L1019), and the difference is entirely due to the superior ability of the assembler programmer to deal with string instructions and segments. (Actually, [Listing 10-19](#L1019) is *more* efficient than the code generated by most high-level language compilers would be, since it keeps the checksum in a byte-sized register rather than in a memory variable and uses a `loop` instruction rather than decrementing a counter stored in memory.)

As an example of leaving ES set for as long as possible, I once wrote and sold a game in which ES contained the display memory segment — 0B800h — for the entire duration of the game. My program spent so much of its time drawing that it was worth dedicating ES to a single area of memory in order to save the cycles that would otherwise have been expended on preserving and reloading ES during each call to the video driver. I'm not saying this is generally a good idea (in fact, it's not, because it sharply restricts the use of the most flexible segment register), but rather that this is the sort of unusual approach that's worth considering when you're looking to turbocharge your code.

### `rep` and Segment Prefixes Don't Mix

One case in which you should exercise extreme caution when using segment overrides is in conjunction with repeated string instructions. The reason: the 8088 has the annoying habit of remembering a maximum of one prefix byte when a string instruction is interrupted by a hardware interrupt and then continues after an `iret`. `rep` is a prefix byte, and segment overrides are prefix bytes, which means that a repeated string instruction with a segment override has two prefix bytes — and that's one too many. You're pretty much guaranteed to have erratic and unreproducible bugs in any code that uses instructions like:

```nasm
rep   movs  byte ptr es:[di],byte ptr es:[si]
```

If you have some time-critical task that absolutely requires the use of a repeated string instruction with a segment override, you must turn off interrupts before executing the instruction. With interrupts disabled, there's no chance that the repeated string instruction will be confused by an interrupt and subsequent `iret`. However, this technique should be used only as a last resort, because it involves disabling interrupts for the potentially lengthy duration of a repeated string instruction. If interrupts are kept disabled for too long, then keystrokes, mouse actions, and serial data can be lost or corrupted. The preferred solution is to reduce the two prefix bytes to just one — the `rep` prefix — by juggling the segments so that the repeated string instruction can use its default segments.

### On to String Instruction Applications

We haven't covered *everything* there is to know about the string instructions, but we have touched on the important points. Now we're ready to see the string instructions in action. To an assembler programmer, that's a pleasant sight indeed.
