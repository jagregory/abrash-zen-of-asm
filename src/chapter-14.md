# Chapter 14: If You Must Branch...

Not-branching is a terrific performance tool, but realistically you *are* going to branch — and frequently at that, for the branching instructions are both compact and most useful for making decisions. Do your best to avoid branches in your time-critical code, and when you must branch, do so intelligently. By "intelligently" I mean, among other things, avoiding far branches whenever possible, getting multiple tests out of a single instruction, using the special looping instructions, and using jump tables. We'll look at these and various other cycle-and/or byte-saving branching techniques over the course of this chapter.

This chapter differs from the last few chapters in that it offers no spectacularly better approaches, no massive savings of cycles. Instead, it's a collection of things to steer clear of and tips that save a few cycles and/or bytes. Taken together, the topics in this chapter should give you some new perspectives on writing branching code, along with a few more items for your programming toolkit.

Remember, though, that relatively fast as some of the techniques in this chapter may be, it's still faster not to branch at all!

## 14.1 Don't Go Far

Far branches are branches that load both CS and IP, by contrast with near branches, which only load IP. Whatever you do, don't use far branches — jumps, calls, and returns — any more than you absolutely must. Far calls and returns, in particular, tend to bulk up code and slow performance greatly, as the bloated size and sluggish performance of C programs written in the large code model readily attest.

Surprisingly, far jumps — direct far jumps, at least — aren't all that bad. A direct far jump — a far jump to a label, such as `jmp far ptr Target` — is big, at 5 bytes, but its EU execution time is exactly the same as that of a near jump to a label — 15 cycles. Of course, it can take extra cycles to fetch all 5 bytes, and, as with all branches, the prefetch queue is emptied; still and all, a direct jump isn't much worse than its near counterpart.

The same cannot be said for an indirect far jump — that is, a far jump to the segment:offset address contained in a memory variable, as in `jmp dword ptr [Vector]`. While such an instruction is no larger than its near counterpart — both are 1 byte long plus the usual 1 to 3 bytes of *mod-reg-rm* addressing — it *is* much slower than an indirect near jump, and that's saying a lot. Where an indirect near jump takes at least 27 cycles to execute, an indirect far jump takes at least 37 cycles...one reason why jump and call tables that branch to near routines are *much* preferred to those that branch to far routines. (We'll discuss jump and call tables at the end of this chapter.)

Far calls and returns are worse yet. Near returns must pop IP from the stack. Far returns must pop CS as well, and those two additional memory accesses must cost at least 8 cycles. In all, far returns execute in 32 cycles, 12 cycles slower than near returns. That's not in itself so bad, especially when you consider that far returns are only 1 byte long, just like near returns.

Now, however, consider that far returns must be paired with far calls. So what, you ask? Simply this: no matter how you slice it, far calls are bad news. The basic problem is that far calls perform a slew of memory accesses. All far calls must push 4 bytes (the CS:IP of the return address) onto the stack: that alone takes 16 cycles. Direct far calls are 5 bytes long, which is likely to cause the prefetch queue to eat more than a few cycles, while indirect far calls must read the 4 bytes that point to the destination from memory, at a cost of 16 more cycles. The total bill: direct far calls take 36 cycles and 5 bytes, while indirect far calls take at least 58 cycles.

58 cycles — and where there's a far call, there's a far return yet to come. Together, an indirect far call and the corresponding return take at least 90 cycles — as long as or longer than an 8-bit divide! Even a direct far call and the corresponding return together take at least 68 cycles — and very possibly more when you add in the prefetch queue effects of fetching a 5-byte instruction and emptying the prefetch queue twice.

Let's see just how bad far calls are. In the last chapter, we compared the performance of a subroutine in [Listing 13-16](#L1316) with that of a macro in [Listing 13-17](#L1317). The subroutine in [Listing 13-16](#L1316) — `IsPrintable` — is called with a near `call` and returns with a near `ret`. Given that quite a bit besides the `call` and `ret` occurs each time the subroutine is called — including several branches and two memory accesses — how much slower do you suppose overall performance would be if `IsPrintable` were entered and exited with far branches?

Quite a bit, as it turns out. [Listing 13-16](#L1316) ran in 3.48 ms. [Listing 14-1](#L1401), which is identical to [Listing 13-16](#L1316) save that `IsPrintable` is a far procedure, takes 4.32 ms to finish. In other words, the simple substitution of a near `call`/`ret` for a far `call`/`ret` results in a 24% performance increase.

I don't think I really have to interpret those results for you, but just in case...

Don't branch. If you must branch, don't branch far. If you must branch far, don't use far calls and returns unless you absolutely, positively can't help it. (Don't even consider software interrupts; as we'll see later, interrupts make far calls look fast.) Unfortunately, it's easy to fall into using far calls and returns, since that's the obvious way to implement large applications on the PC. High-level languages make it particularly easy to fall into the far-call trap, because the source code for a large code model program (that is, a program using far calls by default) is no different than that for a small code model program.

Even in assembler, far calls seem fairly harmless at first glance. The Zen timer reveals the truth, however — far calls cost dearly in the performance department. Far calls, whether direct to a label or indirect through a call table (as we'll see later), cost dearly in code size, too.

If you catch my drift: don't use far calls unless you have no choice!

### How to Avoid Far Branches

Ideally, all the code in a given program should fit in one 64 Kb segment, eliminating the need for far branching altogether. Even in bigger programs, however, it's often possible to keep most of the branches near.

For example, few programs with more than 64 Kb of code (large code model programs) are written in pure assembler; usually the bulk of the program is written in C, Pascal, or the like, with assembler used when speed is of the essence. In such programs all the assembler code will often fit in a single 64 Kb segment, and the complete control assembler gives you over segment naming makes it easy to place multiple assembler modules in the same code segment. Once that's done, all branches within the assembler code can be near, even though branches between the high-level language code and the assembler code must be far, as shown in Figure 14.1.

![](images/fig14.1RT.png)

Many compilers allow you to specify the segment names used for individual modules, if you so desire. If your compiler supports code segment naming and also supports near procedures in the large code model (as, for example, Turbo C does), you could actually make near calls not only within your assembler code, but also *into* that code from the high-level language. The key is giving selected high-level language modules and your assembler code identical code segment names, so they'll share a single code segment, then using the `near` keyword to declare the assembler subroutines as near externals in the high-level language code.

In fact, you can readily benefit from localized near branching even if you're not using assembler at all. You can use the `near` keyword to declare routines that are referenced only within one high-level language module to be near routines, allowing the compiler to generate near rather than far calls to those routines. As noted above, you can even place several modules in the same code segment and use near calls for functions referenced only within those modules that share the same segment.

In short, in the code that really matters you can often enjoy the performance advantage of small code model programming — that is, near branches — even when your program has more than 64 Kb of code and so must use the large code model overall.

Whether you're programming in assembler or a high-level language, one great benefit of using near rather than far subroutines is the reduction in the size of jump and call tables that near subroutines make possible. While the address of a near subroutine can be specified as a 1-word table entry, a full doubleword is required to specify the segment and offset of a far subroutine. It doesn't take a genius to figure out that we can cut the size of a jump or call table in half if we can convert the subroutines it branches to from far to near, as shown in Figure 14.2.

![](images/fig14.2RT.png)

When we add the space savings of near-branching jump and call tables to the performance advantages of indirect near branches that we explored earlier, we can readily see that it's worth going to a good deal of trouble to make the near-branching variety of jump and call tables whenever possible. We'll return to the topic of jump and call tables at the end of this chapter.

### Odds and Ends on Branching Far

When programming in the large code model, you'll often encounter the case where one assembler subroutine calls another assembler subroutine that resides in the same code segment. Naturally, you'd like to use a near rather than far call; unfortunately, if the called subroutine is also called from outside the module, it may well have to be a far subroutine — that is, it may return with a far return. That means that a near call can't be used, since the far return would attempt to pop CS:IP while the near call would push only IP.

All is not lost, however — you can *fake* a far call, and save a byte in the process. If you think about it, the only difference between a far call to a near label and a near call is that the far call pushes CS before it pushes IP, and we can accomplish that by pushing CS before making a near call. That is:

```nasm
push  cs
call  near ptr FarSubroutine
```

is equivalent to:

```nasm
call  far ptr FarSubroutine
```

when `FarSubroutine` is in the same segment as the calling code. Since a direct near call is 2 bytes shorter than a direct far call and `push cs` is only 1 byte long, we actually come out 1 byte ahead by pushing CS and making a near call. According to the official cycle counts, the push/near call approach is 1 cycle slower; however, the alternative approach requires that 1 more instruction byte be fetched, so the scales could easily tip the other way.

One more item on far calls, and then we'll get on to other topics. Often it's necessary to perform a far branch to an address specified by an entry in a look-up table. That's generally no problem — we point to the table entry, perform an indirect far branch, and away we go.

Sometimes, however — in certain types of reentrant interrupt handlers and dispatchers, for example — it's necessary to perform an indirect far branch without altering the registers in any way, and without modifying memory. How can we perform such a branch without building a doubleword pointer in memory, to say nothing of leaving the registers unchanged?

The answer is that we *can* build a doubleword pointer in memory — on the stack. We can perform a far branch to anywhere in memory simply by putting CS and IP onto the stack (in that order, with CS at the higher address), then performing a far return. To wit:

```nasm
;
; Branches to the entry in VectorTable that's indicated
; by the index in BX. All registers are preserved.
;
; VectorTable is in CS, so DS doesn't need to be set to
; any particular segment.
;
FarBranchByIndex  proc  near
    sub   sp,4                      ;make room for the target address
    push  bp                        ;preserve all registers we'll change
    mov   bp,sp                     ;point 1 word above the stack space
                                    ; we've reserved for the target address
    push  bx
    push  ax
    shl   bx,1                      ;convert index to doubleword look-up
    shl   bx,1
    mov   ax,cs:[VectorTable+bx]    ;get target offset
    mov   [bp+2],ax                 ;put target offset onto stack
    mov   ax,cs:[VectorTable+bx+2]  ;get target segment
    mov   [bp+4],ax                 ;put target segment onto stack
    pop   ax                        ;restore all registers we've changed
    pop   bx
    pop   bp
    ret
FarBranchByIndex  endp
```

To carry this line of thought to its logical extreme, we could even preserve the states of the flags by executing a `pushf` before allocating the stack space, and then performing an `iret` rather than a far `ret` to branch to the target.

The sort of branching shown above is an example of how flexible the 8088's instruction set can be, especially if you're willing to use instructions in unusual ways, like hand-constructing far return addresses on the stack. This example certainly isn't ideal for most tasks...but it's available if you need the particular service it delivers. In truth, the only limit on the strange jobs the 8088 can be coaxed into doing is your creativity. Speed may sometimes be a problem with the 8088, but flexibility shouldn't be.

## 14.2 Replacing `call` and `ret` With `jmp`

Enough of far branches, already. Let's continue with some interesting ways to replace `call` and `ret` with `jmp`.

Suppose that we've got a subroutine that's only called from one place in an entire program. That might be the case with a subroutine called through a call table from a central dispatch point, for example. Well, then, there's really no reason to call and return; instead, we can simply jump to the subroutine, and then jump back to the instruction after the call point, saving some cycles in the process.

For example, consider the code in [Listing 14-2](#L1402), which is yet another modification of the printable character filtering program of [Listing 13-16](#L1316). The modification in [Listing 14-2](#L1402) is that the call to `IsPrintable` has been replaced with a jump to the subroutine, and the return from `IsPrintable` has been replaced with a second jump, this time to the instruction after the jump that invoked the subroutine.

That simple change cuts overall execution time to 3.09 ms, an improvement of more than 12%. Granted, part of the improvement is due to the use of short jumps, each of which reduces prefetching by 1 byte over normal jumps; when:

```nasm
db  128 dup(?)
```

is placed between `IsPrintable` and the rest of the code, forcing the use of jumps with normal 2-byte displacements, overall execution time rises to 3.33 ms, less than 5% faster than the original version. All that means, however, is that the `jmp`-`jmp` technique as a replacement for `call`-`ret` is most desirable when short jumps can be used. That's particularly true since two normal jumps total 6 bytes in length, 2 bytes longer than a `call`-`ret` pair.

In truth, [Listing 14-2](#L1402) doesn't demonstrate a particularly good application for replacing `call`-`ret` with `jmp`-`jmp`. As shown in [Listing 14-2](#L1402), `IsPrintable` could only be called from one place in the program, the `CopyPrintable` subroutine, and we usually want more flexibility in invoking our subroutines than that. (Otherwise we might just as well make the subroutines macros and move them right into the calling code.) That's why subroutines called through call tables are much better candidates for the `jmp`-`jmp` technique, since such subroutines often really are invoked from just one place.

### Flexibility *Ad Infinitum*

If more flexibility is needed than the last example provides, are we fated always to use `call`-`ret` rather than `jmp-jmp`? Well, the theme of this chapter seems to be the infinite flexibility of the 8088's instruction set, so it should come as no surprise to you that the answer is: not at all. Usually, you *will* want to use `call`-`ret`, since it's by far the simplest solution and often the fastest as well...but there *are* alternatives, and they can be quite handy in a pinch.

Consider this. Suppose that you've got a set of subroutines that are called via a call table. Next, suppose that it's desirable that any of the subroutines be able to end at any point and return to the central dispatching point — *without cleaning up the stack*. That is, it must be possible to return from anywhere in any subroutine called through the call table, discarding whatever variables, return addresses and so on happen to be on the stack at the time.

Well, that's no great trick; we can simply jump back to the dispatch point, where the original (pre-call) stack pointer could be retrieved from a memory variable and loaded into SP. I know it's a strange thought, but it's perfectly legal to clear the stack simply by reloading SP. Now, however, suppose that the call table can be started from any of several locations. That means that a simple direct jump will no longer serve to return us to the calling code, since the calling code could be in any of several places. We certainly can't use `call` and `ret` either, since the return address could well be buried under data pushed on the stack at any given time.

The solution is simple: place the return address in a register before jumping at the central dispatch point, preserve the register throughout each subroutine, and return by branching to the offset in the register. The code would look something like this:

```nasm
    mov   [OriginalSP],sp           ;save the stack state
DispatchLoopTop:
          :                         ;point BX to desired entry
          :                         ; in VectorTable
    mov   di,offset DispatchReturn  ;put the return address in DI,
                                    ; pointing to the instruction
                                    ; after the jump
    jmp   [VectorTable+bx]          ;jump to desired subroutine
DispatchReturn:                     ;subroutines return here
    mov   sp,[OriginalSP]           ;restore the stack state
    jmp   DispatchLoopTop
          :
Subroutine1:                        ;one of the subroutines
          :                         ; called through VectorTable
          :                         ;DI is preserved throughout
          :                         ; Subroutine1
    jmp   di                        ;return to the calling code
```

Make no mistake: this approach has its flaws. For one thing, it ties up a 16-bit register for the duration of each subroutine, and registers are scarce enough as it is. (The return address could instead be stored in a memory variable, but that reduces performance and causes reentrancy problems.) For another, it wastes bytes, since the `jmp di` instruction used to return to the dispatcher is 1 byte longer than `ret`, and the `mov`-`jmp` pair used by the dispatcher is 3 bytes longer than `call`. Yet another fault is the inherently greater complexity of the code, which brings with it an increased probability of bugs.

Nonetheless, the above approach offers the flexibility we need — and then some. Think for a moment, and you'll realize that we can, if we wish, return anywhere at all with the above approach. For example, the following saves a branch by returning right to `DispatchLoopTop`:

```nasm
    mov   [OriginalSP],sp             ;save the stack state
DispatchLoopTop:
    mov   sp,[OriginalSP]             ;restore the stack state
          :                           ;point BX to desired entry
          :                           ; in VectorTable
    mov   di,offset DispatchLoopTop   ;put the return address in DI,
                                      ; pointing to the top of the loop
    jmp   [VectorTable+bx]            ;jump to desired subroutine
          :
Subroutine1:                          ;one of the subroutines
          :                           ; called through VectorTable
          :                           ;DI is preserved throughout
          :                           ; Subroutine1
    jmp   di                          ;return to the calling code
```

(You don't have to jump through a register to return to an instruction other than the one after the calling instruction; just push the desired return address onto the stack and jump to a subroutine. For example, the following:

```nasm
DispatchLoopTop:
          :                           ;point BX to desired entry
          :                           ; in VectorTable
    mov   ax,offset DispatchLoopTop   ;push the return address
    push  ax                          ; on the stack
    jmp   [VectorTable+bx]            ;jump to desired subroutine
          :
Subroutine1:                          ;one of the subroutines
          :                           ; called through VectorTable
    ret                               ;return to the calling code
```

pushes `DispatchLoopTop` before jumping, so each subroutine returns to `DispatchLoopTop` rather than to the instruction after the `jmp`.)

Surprisingly, flexibility is not the only virtue of the return-through-register approach — under the right circumstances, performance can benefit as well, since a branch through a register is only 2 bytes long and executes in just 11 cycles. [Listing 14-3](#L1403) shows [Listing 14-2](#L1402) modified to store the return address in BP. While this code is a tad longer than [Listing 14-2](#L1402), since BP must be loaded, [Listing 14-3](#L1403) executes in 3.03 ms — slightly *faster* than [Listing 14-2](#L1402). The key is that BP is loaded only once, outside the loop, in `CopyPrintable`, so the extra overhead of loading BP is spread over the many repetitions of the loop. Meanwhile, the 4-cycle performance advantage of `jmp bp` over `jmp short IsPrintableReturn` is gained every time through the loop.

What's more, the version of `IsPrintable` in [Listing 14-3](#L1403) can be called from anywhere, so long as the calling code sets BP to the return address. By contrast, `IsPrintable` is hardwired to return only to `CopyPrintable` in [Listing 14-2](#L1402).

Once again, the point is not that you should generally replace `call`-`ret` with one of the many flavors of `jmp`-`jmp`, but rather that you should understand the unusual flexibility that `jmp`-`jmp` offers. It's a bonus that `jmp`-`jmp` can sometimes improve performance; the main point is that the flexibility of this approach lets you perform an odd lot of slightly improbable but sometimes most useful tasks.

### Tinkering With the Stack in a Subroutine

Let's look at an example of the slightly-improbable that jumping through a register makes easy. Suppose that we want to be able to call a subroutine that allocates a specified number of bytes on the stack, then returns. That doesn't seem at first glance to be possible, since the allocated bytes would bury the return address beneath them, preventing the subroutine from returning until it deallocated the bytes.

Ah, but now we know about jumping through a register, so the solution's obvious. Here's the desired subroutine:

```nasm
;
; Allocates space on the stack.
;
; Input:
;     CX = # of bytes to allocate
;
; Output: none
;
; Registers altered: AX, SP
;
AllocateStackSpace  proc  near
    pop   ax                    ;retrieve the return address
    sub   sp,cx                 ;allocate the space on the stack
    jmp   ax                    ;return to the calling code
AllocateStackSpace  endp
```

If we can tinker with the stack in a subroutine with such impunity, it would seem that with the 8088's instruction set we could do just about anything one could imagine — and indeed we can. Given the in-depth understanding of the 8088 that we've acquired, there's really nothing we can't do, given enough execution time. It's just a matter of putting the pieces of the puzzle — the 8088's instructions — together, and that's what the Zen of assembler is all about.

As a simple example, consider the following. Once upon a time, Jeff Duntemann needed to obtain the IP of a particular instruction. Normally, that's no problem: the value of any label can be loaded into a general-purpose register as an immediate value. That wouldn't do in Jeff's situation, however, because his code was in-line assembler code in a Pascal program. The code was nothing more than a series of hex bytes that could be compiled directly into the program at any location at all; because the code could be placed at any location, the current IP couldn't be represented by any label or immediate value. Given that IP can't be read directly, what was Jeff to do?

The solution was remarkably simple... given a solid understanding of the 8088's instruction set and a flexible mind. The `call` instruction pushes the IP of the next instruction, so Jeff just called the very next instruction and popped the IP of that instruction from the stack as follows:

```nasm
call  $+3   ;pushes IP and branches to the next instruction
pop   ax    ;gets the IP of this instruction
```

It's not exactly what `call` was intended for, but it solved Jeff's problem — and results are what matter most in assembler programming.

## 14.3 Use `int` Only When You Must

Before we get on with more ways to branch efficiently, let's discuss `int` for a moment. `int` is an oddball among branching instructions, in that it performs a far branch to the address stored at the corresponding interrupt vector in the 1 Kb table of interrupt vectors starting at 0000:0000. `int` not only pushes a return CS:IP address, as would a far call, but pushes the FLAGS register as well.

`int` operates as it does because it's really more of a hardware instruction than a software instruction. When interrupts are enabled (via the Interrupt flag) and one of the 8088's hardware interrupts occurs, the 8088 automatically executes an `int` instruction at the end of the current instruction. Because the currently executing code can be interrupted at any time, the exact state of the registers and flags *must* be preserved; hence the pushing of the FLAGS register. The `iret` instruction provides a neat method for restoring the flags and branching back to continue the interrupted code.

From the perspective of servicing hardware that can require attention at any time, the 8088's interrupt mechanism is ideal. Interrupts are location — and code — independent; no matter what code you're executing, where that code resides, or what the setting of the registers are, an interrupt will branch to the correct interrupt handler and allow you to restore the state of the 8088 when you're done.

From a software perspective, the interrupt mechanism is considerably less ideal. Since an `int` instruction must be executed to perform a software interrupt, there's no possibility of asynchronous execution of a software interrupt, and hence no real need to save the state of the flags. What's more, `int` is astonishingly slow, making almost any sort of branch — yes, even a far call — preferable.

How slow is `int`? *Slow*. `int` itself takes 71 cycles and empties the prefetch queue, and `iret` takes an additional 44 cycles and empties the prefetch queue again. At 115 cycles and two queue flushes a pop, you won't be using `int` too often in your time-critical code!

Why would you ever want to use `int`? The obvious answer is that you *must* use `int` to invoke DOS and BIOS functions. `int` is used for these services because it's a handy way to provide entry points into routines that may move around in memory. No matter where the BIOS keyboard interface resides (and it may well move from one version of the BIOS to another, to say nothing of memory-resident programs that intercept keystrokes), it can always be accessed with `int 16h`. Basically, `int` is a useful way to access code that's external to the program that's running and consequently can't be branched to directly.

IBM left a number of interrupt vectors free for application program use, and that, along with the knowledge that `int` is a compact 2 bytes in length, might start you thinking that you could use `int` rather than `call` to branch to routines *within* a program. After all, in a large code model program `int` is 3 bytes shorter than a direct call.

It's a nice idea — but not, as a general rule, a *good* idea. For one thing, you might well find that your chosen interrupt vectors conflict with those used by a memory-resident program. There aren't very many available vectors, and interrupt conflicts can easily crash a computer. Also, `int` is just too slow to be of much use; you'd have to have a powerful need to save space and an equally powerful insensitivity to performance to even consider using `int`. Also, because there aren't many interrupt vectors, you'll probably find yourself using a register to pass function numbers. Having to load a register pretty much wipes out the space savings `int` offers, and because the interrupt handler will have to perform another branch internally in order to vector to the code for the desired function, performance will be even worse.

In short, reserve `int` for accessing DOS and BIOS services and for those applications where there simply is no substitute — applications in which location independence is paramount.

### Beware of Letting Dos Do the Work

Interrupts are so slow that it often pays to go to considerable trouble to move them out of loops. Consider character-by-character processing of a text file, as for example when converting the contents of a text file to uppercase. In such an application it's easiest to avoid the complications of buffering text by letting DOS feed you one character at a time, as shown in Figure 14.3.

![](images/fig14.3RT.png)

[Listing 14-4](#L1404) illustrates the approach of letting DOS do the work on a character-by-character basis. [Listing 14-4](#L1404) reads characters from the standard input, converts them to uppercase, and prints the results to the standard output, interacting with DOS a character at a time at both the input and output stages. [Listing 14-4](#L1404) takes 2.009 seconds to convert the contents of the file TEST.TXT, shown in Figure 14.4, to uppercase and send the result to the standard output.

(There's a slight complication in timing [Listing 14-4](#L1404). [Listing 14-4](#L1404) must be assembled and linked with LZTIME.BAT, since it takes more than 54 ms to run. However, [Listing 14-4](#L1404) expects to receive characters from the standard input when it executes. When run with the standard input *not* redirected, as occurs when LZTIME.BAT completes assembly and linking, [Listing 14-4](#L1404) waits indefinitely for input from the keyboard.

![](images/fig14.4RT.png)

Consequently, after the link is complete — when the program is waiting for keyboard input — you must press Ctrl-Break to stop the program and type:

```cmd
LZTEST <TEST.TXT
```

at the DOS prompt to time the code in [Listing 14-4](#L1404). The same is true for [Listing 14-5](#L1405).)

The problem with the approach of [Listing 14-4](#L1404) is that all the overhead of calling a DOS function — including an `int` and an `iret` — occurs twice for each character, once during input and once during output. We can easily avoid all that simply by reading a sizable block of text with a single DOS call, processing it a character at a time *in place* (thereby avoiding the overhead of interrupts and DOS calls), and printing it out as a block with a single DOS call, as shown in Figure 14.5.

![](images/fig14.5RT.png)

This process can be repeated a block at a time until the source file runs out of characters.

[Listing 14-5](#L1405), which implements the block-handling approach, runs in 818 ms — about 145% faster that [Listing 14-4](#L1404). Forget about disk access time and screen input and output time, to say nothing of the time required to loop and convert characters to uppercase — [Listing 14-4](#L1404)*spends well over half of its time just performing the overhead associated with asking DOS to retrieve characters one at a time*.

I rest my case.

## 14.4 Forward References Can Waste Time and Space

Many 8088 instructions offer special compressed forms. For example, `jmp`, which is normally 3 bytes long, can use the 2-byte `jmp short` form when the target in within the range of a 1-byte displacement, as we found in Chapter 12. The word-sized forms of the arithmetic instructions — `cmp`, `add`, `and`, and the like — have similarly shortened forms when used with immediate operands that can fit within a signed byte; such operands are stored in a byte rather than a word and are automatically sign-extended before being used.

As yet another example, any instruction that uses a *mod-reg-rm* byte and has a displacement field — `Index` in `mov al,[bx+Index]`, for example — is a byte shorter if the displacement fits within a signed byte. In fact, if `Index` is 0 in `mov al,[bx+Index]`, the displacement field can be done away with entirely, saving 2 bytes. (The potential waste of 2 bytes also applies when SI or DI is used with a displacement, but not when BP is used; the organization of the *mod-reg-rm* byte requires that BP-based addressing have at least a 1-byte displacement, so only 1 byte at most can be wasted.)

Obviously, we'd like the assembler to use the shortest possible forms of compressible instructions such as those mentioned above, and the assembler does just that *when it knows enough to do so* — which is not always the case.

Consider this. If the assembler comes to a `jmp` instruction, a great deal depends on whether the jump goes backward or forward. If it's a backward jump, the target label is already defined, and the assembler knows exactly how far away the jump destination is. If a backward destination is within the range of a 1-byte displacement, a short jump is generated; otherwise, a normal jump with a 2-byte displacement is generated. Either way, you can rest assured that the assembler has assembled the shortest possible jump.

Not so with a forward jump. In this case, the target label hasn't been reached yet, so the assembler hasn't the faintest idea of how far away it is. Either type of jump *might* be appropriate, but the assembler won't know until the target label is reached in the course of assembly. The assembler can't wait until then to decide how big to make the jump, though. The jump size *must* be set before assembly can continue past the jump instruction; otherwise, the assembler wouldn't know where to place the next instruction.

Faced with such a dilemma, the assembler takes the only possible way out: it reserves space for the larger possibility, a normal jump. Later, when the target label becomes defined, the jump is assembled as a short jump if possible, but the damage has already been done; since 3 bytes were originally reserved for the jump, 3 bytes must be used, and a `nop` is stuffed in after the short jump. That is, a jump to the very next instruction, as in:

```nasm
    jmp   NearLabel
NearLabel:
```

assembles to the following:

```nasm
    jmp   short NearLabel
    nop
NearLabel:
```

From a speed perspective, that's fine, but why waste a byte on a `nop`? The correct code is:

```nasm
    jmp   short NearLabel
NearLabel:
```

Now consider the case of forward references to structure elements. The following `mov`:

```nasm
      mov   ax,[bx+FirstEntry]
            :
EntryList   struc
FirstEntry  dw    ?
SecondEntry dw    ?
ThirdEntry  dw    ?
EntryList   struc
```

assembles with a 2-byte displacement field, while this `mov`:

```nasm
EntryList   struc
FirstEntry  dw    ?
SecondEntry dw    ?
ThirdEntry  dw    ?
EntryList   struc
            :
      mov   ax,[bx+FirstEntry]
```

assembles with no displacement field at all. Again, the assembler has no way of knowing on a forward reference how much space will be required for the displacement field, and must assume the worst. Unlike the previous `jmp` example, however, performance as well as code size suffers in this case, since the additional displacement bytes must be fetched and a more complex effective address calculation must be made.

The same is true of forward-referenced immediate operands to the arithmetic instructions, and, indeed, of forward-referenced operands to any instruction that has a compressed form. You can improve the quality of your code considerably by avoiding forward references to data of all sorts (this will also speed up assembly a bit) and by explicitly using `jmp short` whenever it will reach on forward jumps.

### The Right Assembler Can Help

Avoiding inefficient forward references can be a frustrating task, involving many assembly errors from short jumps that you thought *might* reach their destinations but which turned out not to. What's more, MASM doesn't tell you when it encounters inefficient forward references, so there's no easy way to identify opportunities to save bytes and/or cycles by using short jumps and by moving data and equates so as to avoid forward references.

In short, there's no good way to avoid inefficient code with *MASM* — but it's a different story with TASM and OPTASM. TASM can detect inefficient code as it assembles, issuing warnings to that effect if you so desire. You do then need to reedit your source code to correct the inefficient code, but once that's done you can relax in the knowledge that the assembler is generating the best possible machine language code from your source code.

OPTASM goes TASM one better. OPTASM can actually assemble the most efficient possible code automatically, with no intervention on your part required. Be warned, however, that I've heard that OPTASM is mostly but not 100% MASM-compatible. On the other hand, Borland claims TASM is 100% MASM-compatible, and I've found no reason to dispute that claim.

I wouldn't be surprised if MASM added inefficient-code handling features in a future version, because it's so obviously useful and because it's easy to do (at least to the extent of issuing inefficient code warnings). In any case, if you're interested in generating the tightest, fastest possible code, it's generally worth your while to use an assembler that can handle inefficient code in one way or another. Unlike almost everything else we've encountered in this book, saving bytes and/or cycles by eliminating inefficient code requires virtually no effort, given an assembler that helps you do the job.

If you aren't using an assembler that can help you generate efficient forward branches, use backward branches whenever possible. One reason is that MASM can select the smallest possible displacement for unconditional backward jumps. Another reason is that macros can be used to generate efficient code for backward *conditional* jumps, as we'll see later in this chapter.

## 14.5 Saving Space With Branches

When you're interested in saving space while losing as little performance as possible, you should use jumps in order to share as much code as possible between similar routines. For example, suppose you've got a routine, `SampleSub`, which performs the equivalent of a switch statement with three separate cases, depending on the value in BX. Suppose that each of the cases can succeed or fail, and that `TestSub` returns AX equal to 0 for success or 1 for failure. Suppose further that on failure the byte-sized memory variable `ErrorCode` must be set to indicate which case failed.

One possible implementation is:

```nasm
SampleSub   proc  near
      and   bx,bx
      jz    Case0
      dec   bx
      jz    Case1
; Default case.
            :                               ;code to handle the default case
      jz    SampleSubSuccess                ;if success, set AX properly
      mov   [ErrorCode],DEFAULT_CASE_ERROR
      mov   ax,1
      ret
Case0:
            :                               ;code to handle the case of BX=1
      jz    SampleSubSuccess                ;if success, set AX properly
      mov   [ErrorCode],CASE0_ERROR
      mov   ax,1
      ret
Case1:
            :                               ;code to handle the case of BX=2
      jz    SampleSubSuccess                ;if success, set AX properly
      mov   [ErrorCode],CASE1_ERROR
      mov   ax,1
      ret
SampleSubSuccess:
      sub   ax,ax                           ;return success status
      ret
SampleSub   endp
```

In this implementation, all cases jump to the common code at `Success` when they succeed, so that the code to return a success status appears just once but serves all three cases.

Although it's not quite so obvious, we can shrink the code a good bit by doing the same for the failure case, as follows:

```nasm
SampleSub   proc  near
      and   bx,bx
      jz    Case0
      dec   bx
      jz    Case1
; Default case.
            :                       ;code to handle the default case
      jz    SampleSubSuccess        ;if success, set AX properly
      mov   al,DEFAULT_CASE_ERROR
      jmp   short SampleSubFailure  ;set error code & status
Case0:
            :                       ;code to handle the case of BX=1
      jz    SampleSubSuccess        ;if success, set AX properly
      mov   al,CASE0_ERROR
      jmp   short SampleSubFailure  ;set error code & status
Case1:
            :                       ;code to handle the case of BX=2
      jz    SampleSubSuccess        ;if success, set AX properly
      mov   al,CASE1_ERROR
SampleSubFailure:
      mov   [ErrorCode],al
      mov   ax,1
      ret
SampleSubSuccess:
      sub   ax,ax                   ;return success status
      ret
SampleSub   endp
```

Although this latter version doesn't look much different from the original, it's a full 10 bytes shorter, and functionally equivalent. (If there were more cases, we'd save proportionally more bytes, too.) This substantial reduction in size results from two factors: the instruction pair `mov ax,1`/`ret` appears once rather than three times, saving 8 bytes, and three `mov al,``*immed`* instructions along with one accumulator-specific direct-addressed memory access replace three *mod-reg-rm* direct-addressed memory accesses, saving 6 bytes. Those 14 bytes saved more than offset the 4 bytes added by two `jmp short` instructions.

There are two points to be made here. First, we can save many bytes by jumping to common exit code from various places in a subroutine, provided that the common exit code performs a reasonably lengthy task that would otherwise have to be performed at the end of a number of code sequences. (If the common exit code is just a `ret`, we're better off executing a 1-byte `ret` in several places in the subroutine than we are executing a 2-byte `jmp short` just to get to the `ret`, as we saw in the last chapter.)

Second, we can save bytes by altering our code a bit to allow common exit code to do more than it normally would. This is illustrated in the above example in that each of the cases loads an error code into AL, rather than storing it to memory, so that a single accumulator-specific direct-addressed `mov` can store the error code to memory. Off the top, it would seem that the error-code setting belongs in the separate cases, since each case stores a different error value, but with a little ingenuity, a single memory-accessing instruction can do the trick.

The idea of sharing common exit code can be extended across several functions. Suppose that we've got two subroutines that end by popping DI, SI, and BP, then returning. Suppose also that in case of success these subroutines return AX set to 0, while in case of failure they return AX set to a non-zero error code.

There's absolutely no reason why the two subroutines shouldn't share a considerable amount of exit code, along the following lines:

```nasm
Subroutine1   proc  near
      push    bp
      mov     bp,sp
      push    si
      push    di
              :           ;body of subroutine, putting an error code in AX and
              :           ; branching to Exit on failure, or falling through in
              ;           ; case of success
Success:
      sub     ax,ax
Exit:
      pop     di
      pop     si
      pop     bp
      ret
Subroutine1   endp
Subroutine2   proc  near
      push    bp
      mov     bp,sp
      push    si
      push    di
              :           ;body of subroutine, putting an error code in AX and
              :           ; branching to Exit on failure, or falling through in
              ;           ; case of success
      jmp     Success
Subroutine2 endp
```

Here we've saved 3 or 4 bytes by replacing 6 bytes of exit code that would normally appear at the end of `Subroutine2` with a 2-or 3-byte jump. What's more, we could do the same for any number of subroutines that can use the same exit code; at worst, a 3-byte normal jump would be required to reach `Success` or `Exit`. Naturally, larger savings would result from sharing lengthier exit code.

The key here is realizing that in assembler there's no need for a clean separation between subroutines. If multiple subroutines end with the same instructions, they might as well share those instructions. Of course, performance will suffer a little from the extra branch all but one of the subroutines will have to make in order to reach the common code. Once again, we've acquired a new tool that has both costs and benefits; this time it's a tool that saves bytes while expending cycles. Deciding when that's a good tradeoff is your business, to be judged on a case by case basis. Sometimes this new tool is desirable, sometimes not...but either way, making that sort of decision properly is a key to good assembler code.

### Multiple Entry Points

At the other end of a subroutine, we can save bytes by providing multiple entry points. In one use, multiple entry points are an extension of the common exit code concept we just discussed, with the idea being the sharing of as much code as possible, via branches into the middle as well as the start of subroutines. If two subroutines share the whole last half of their code in common, then one can branch into the other at that point. If some tasks require only the last one-third of the code in a subroutine, then a call could be made directly to the appropriate point in the subroutine; in this case, one subroutine would be a proper subset of the other, and wouldn't exist as separate code at all.

Assembler facilitates that sort of sharing of code, because if we really want to, we can always set up the registers, flags and stack to match the requirements of a subroutine's code at any entry point. In other words, if we want to branch into the middle of a subroutine, the complete control of the PC that is possible only in assembler allows us to set up the state of the PC as needed to enter that code. (Recall our tinkering with the stack earlier in this chapter...) Whether it's worth going to the trouble of doing so is another question entirely, but never forget that assembler lets you put the PC into any state you choose at any time.

There's another meaning to multiple entry points, as well, and that's the technique of using several front-end entry points to a subroutine in order to set up commonly-used parameters. I can best explain this by way of example.

Imagine that we've got a subroutine, `SpeakerControl`, that's called with one parameter, passed in AX. A call to `SpeakerControl` with AX set to 0 turns off the PC's speaker, while a call with AX set to 1 turns on the speaker.

Now imagine that `SpeakerControl` is called from dozens — perhaps hundreds — of places in a program. Every time `SpeakerControl` is called, a 2-or 3-byte instruction must be used to set AX to the desired state. If there are 100 calls to `SpeakerControl`, approximately 250 bytes are used simply selecting the mode of operation of `SpeakerControl`.

Instead, why not simply provide two front-end entry points to `SpeakerControl`, one to turn the speaker on (`SpeakerOn`) and one to turn the speaker off (`SpeakerOff`)? The code would be as simple as this:

```nasm
; Turns the speaker on.
SpeakerOn   proc  near
      mov   ax,1
      jmp   short SpeakerControl
SpeakerOn   endp
; Turns the speaker off.
SpeakerOff  proc  near
      sub   ax,ax
SpeakerOff  endp
;
; Turns the speaker on or off.
;
; Input:
;     AX = 1 to turn the speaker on
;        = 0 to turn the speaker off
;
; Output:
;     none
;
SpeakerControl  proc  near
                :
```

Now, instead of:

```nasm
mov   ax,1
call  SpeakerControl
```

we can simply use:

```nasm
call  SpeakerOn
```

and we could likewise use `SpeakerOff` instead of calling `SpeakerControl` with AX equal to 0. At the cost of the 7 bytes taken by the two front-end functions, we would save 250 bytes worth of parameter-setting code, for a net savings of 243 bytes.

The principle of using front-end functions that set common parameter values applies to high-level language code as well. In fact, it may apply even better to high-level language code, since it takes 3 to 4 bytes to push a constant parameter onto the stack. The downside of using this technique in a high-level language is much the same as the downside of using it in assembler — it involves extra branching, so it's slower. (In high-level language code, performance will also be slowed by the time required to push any additional parameters that must be passed through the front-end functions.)

Trading off cycles for bytes...so what else is new?

### A Brief Zen Exercise in Branching (And Not-Branching)

Just for fun, we're going to take a moment to look at several ways in which branching and not-branching can be used to improve a simple bit of code. I'm not going to dwell on the mechanisms or merits of the various approaches; by this point you should have the knowledge and tools to do that yourself.

The task at hand is simple: increment a 32-bit value in DX:AX. The obvious solution is:

```nasm
add   ax,1
adc   dx,0
```

which comes in at 6 bytes and 8 Execution Unit cycles.

If we're willing to sacrifice performance, we can save 2 bytes by branching:

```nasm
    inc   ax
    jnz   IncDone
    inc   dx
IncDone:
```

However, this approach usually takes 18 cycles and empties the prefetch queue, since the case where AX turns over to 0 (and so no branch occurs) is only 1 out of 64 K possible cases. We can adjust for that at the cost of an additional byte with:

```nasm
    inc   dx
    inc   ax
    jz    IncDone
    dec   dx
IncDone:
```

which preincrements DX, then usually falls through the conditional jump and decrements DX back to its original state. This approach is 5 bytes long, but usually takes 10 cycles to execute.

Along the lines of our discussion of 32-bit negation in the last chapter, we can also use conditional branching to improve performance, as follows:

```nasm
    inc   ax
    jz    IncDX
IncDone:
          :
IncDX:
    inc   dx
    jmp   IncDone
```

This approach requires the same 6 bytes as the original approach, but takes only 3 bytes and 6 cycles along the usual execution path.

Finally, if the branch-out technique of the last case isn't feasible, we could preload two registers with the values 1 and 0, to speed and shorten the addition:

```nasm
mov   bx,1
sub   cx,cx
      :
add   ax,bx
adc   dx,cx
```

This would reduce the actual addition code to 4 bytes and 6 cycles, although it would require 9 bytes overall. Such an approach would make little sense unless BX and CX were preloaded outside a loop and the 32-bit addition occurred repeatedly inside the loop...but then it doesn't make sense expending the energy for *any* of these optimizations unless either the code is inside a time-critical loop or bytes are in extremely short supply.

Remember, you must pick and choose your spots when you optimize at a detailed instruction-by-instruction level. When you optimize for speed, identify the portions of your programs that significantly affect overall performance and/or make an appreciable difference in response time, and focus your detailed optimization efforts on fine-tuning that code, especially inside loops.

Optimizing for space rather than speed is less focused — you should save bytes wherever you can — but most assembler optimization on the PC is in fact for speed, since there's a great deal of memory available relative to the few bytes that can be saved over the course of a few assembler instructions. However, in certain applications, such as BIOS code and ROMable process-control code, size optimization is sometimes critical. In such applications, you'd want to use subroutines as much as possible (and, yes, perhaps even interrupts), and design those subroutines to share as much code as possible. You'd probably also want to use mini-interpreters, which we'll discuss in Volume II of *The Zen of Assembly Language*.

At any rate, knowing when and where optimization is worth the effort is as important as knowing how to optimize. Without the "when" and "where,"the "how" is useless; you'll spend all your time tweaking code without seeing the big picture, and you'll never accomplish anything of substance.

## 14.6 Double-Duty Tests

There are a number of ways to get multiple uses out of a single instruction that sets the flags. Sometimes the multiple use is available because multiple flags are set, and sometimes the multiple use is available because the instruction that sets the flags performs other tasks as well. Let's look at some examples.

Suppose that we have eight 1-bit flags stored in a single byte-sized memory variable, `StateFlags`, as shown in Figure 14.6.

![](images/fig14.6RT.png)

In order to check whether a high-or medium-priority event is pending, as indicated by bits 7 and 6 of `StateFlags`, we'd normally use something like:

```nasm
mov   al,[StateFlags]
test  al,80h                      ;high-priority event pending?
jnz   HandleHighPriorityEvent     ;yes
test  al,40h                      ;medium-priority event pending?
jnz   HandleMediumPriorityEvent   ;yes
```

or perhaps, if we were clever, the slightly faster sequence:

```nasm
mov   al,[StateFlags]
shl   al,1                        ;high-priority event pending?
jc    HandleHighPriorityEvent     ;yes
shl   al,1                        ;medium-priority event pending?
jc    HandleMediumPriorityEvent   ;yes
```

If we think for a moment, however, we'll realize that shifting a value to the left has a most desirable property. `shl` not only sets the Carry flag to reflect carry out of the most significant bit of the result, but also sets the Sign flag to reflect the value stored *into* the most significant bit of the result.

Do you see it now? After a register is shifted 1 bit to the left, the Carry and Sign flags are set to reflect the states of the *two* most significant bits originally stored in that register. That means that we can replace the above code with:

```nasm
mov   al,[StateFlags]
shl   al,1                        ;high-or medium-priority event pending?
jc    HandleHighPriorityEvent     ;high-priority event pending
js    HandleMediumPriorityEvent   ;medium-priority event pending
```

which is one full instruction shorter.

Stretching this idea still further, we could relocate three of our flags to bits 7, 6, and 5 of `EventFlags`, with bits 4-0 always set to 0, as shown in Figure 14.7.

![](images/fig14.7RT.png)

Then, if the first two tests failed, a zero/non-zero test would serve to determine whether the flag in bit 5 is set, and we could get *three* tests out of a single operation:

```nasm
mov   al,[EventFlags]
shl   al,1                        ;high-, medium-, or low-
                                  ; priority event pending?
jc    HandleHighPriorityEvent     ;high-priority event pending
js    HandleMediumPriorityEvent   ;medium-priority event pending
jnz   HandleLowPriorityEvent      ;low-priority event pending
```

### Using Loop Counters as Indexes

There's another way to get double-duty from tests, in this case by combining the counting function of a loop counter with the indexing function of an index used inside the loop.

Consider the following, which is a standard way to generate a checksum byte for an array:

```nasm
    mov   cx,TEST_ARRAY_LENGTH
    sub   bx,bx
    sub   al,al
ChecksumLoop:
    add   al,[TestArray+bx]
    inc   bx
    loop  ChecksumLoop
```

(Yes, I know that this could be speeded up and shrunk by loading BX with the offset of `TestArray` outside the loop, but bear with me while we look at a specific optimization.)

Now consider the following:

```nasm
    mov   bx,TEST_ARRAY_LENGTH
    sub   al,al
ChecksumLoop:
    add   al,[TestArray+bx-1]
    dec   bx
    jnz   ChecksumLoop
```

This second version generates the same checksum as the earlier code, but is 1 instruction and 2 bytes shorter, and slightly faster, as well. Rather than maintaining separate loop counter and array index values, the second version uses BX for both purposes. The key to being able to do this is the realization that it's equally valid to start processing at either end of the array. Whenever that's the case, look to process at the high end and count toward zero if you can, because it's easier to test for zero than any other value.

By the way, while it's easiest to check for counting down to zero, it's reasonably easy to check for counting *past* zero as well, so long as the initial count is 32 K or less: just test the Sign flag. For instance, the following is yet another version of the checksum code, this time ending the loop when BX counts down past zero to 0FFFFh:

```nasm
    mov   bx,TEST_ARRAY_LENGTH-1
    sub   al,al
ChecksumLoop:
    add   al,[TestArray+bx]
    dec   bx
    jns   ChecksumLoop
```

Note that BX now starts off with the index of the last element of the array rather than the length of the array, so no adjustment by 1 is needed when each element of the array is addressed. So long as TEST\_ARRAY\_LENGTH is 32 K or less, this version isn't generally better or worse than the last version; both versions are the same length and execute at the same speed. However, the Sign flag is set when either 0 *or* any value greater than 32 K is decremented, so if TEST\_ARRAY\_LENGTH exceeds 32 K the checksum loop in the last example will end prematurely — and incorrectly.

## 14.7 The Looping Instructions

And so we come to the 8088's special looping instructions: `jcxz`, `loop`, `loopz`, and `loopnz`. You undoubtedly know how `jcxz` and `loop` work by now — we've certainly used them often enough over the last few chapters. As a quick refresher, `jcxz` branches if and only if CX is zero, and `loop` decrements CX and branches *unless* the new value in CX is zero. None of the looping instructions — not even `loop`, which decrements CX — affects the 8088's flags in any way; we saw that put to good use in a loop that performed multi-word addition in Chapter 9.

(In fact, the only branching instruction of the 8088 that affects the FLAGS register are the interrupt-related instructions. `int` sets the Interrupt and Trap flags to 0, disabling interrupts and single-stepping, as does `into` when the Overflow flag is 1, while `iret` sets the entire FLAGS register to the 16-bit value popped from the stack.)

Given that we're already familiar with `jcxz` and `loop`, we'll take a look at the useful and often overlooked `loopz` and `loopnz`, and then we'll touch on a few items of interest involving `jcxz` and `loop`. Always bear in mind, however, that while the special looping instructions are more efficient than the other branching instructions, they're still branching instructions — and that means that they're still slow. When performance matters, not-branching is the way to go.

### `loopz` and `loopnz`

`loopz` and `loopnz` (also known as `loope` and `loopne`, respectively) are essentially `loop` with a little something extra added. `loopz` (which we can remember as "loop while zero," as we did with `repz`) decrements CX and then branches unless either CX is 0 *or* the Zero flag is 0. Likewise, `loopnz` ("loop while not zero") decrements CX and branches unless either CX is 0 *or* the Zero flag is 1. Depending on whether they branch or not, these instructions are anywhere from 0 to 2 cycles slower than `loop`, but all three instructions are the same size, 2 bytes.

`loopz` and `loopnz` provide an extremely compact way to repeat a loop up to a maximum number of repetitions while waiting for an event that affects the Zero flag to occur. If, when the loop ends, the Zero flag isn't in the sought-after state, then the event hasn't occurred within the maximum number of repetitions.

For example, suppose that we want to search an array for the first entry that matches a particular character. Normally, we would do that with `repnz scasb`, but in this particular case we need to perform a case-insensitive search. [Listing 14-6](#L1406) shows a standard solution to this problem, which tests for a match and branches out of the loop when a match is found, or falls through the bottom of the loop if no match exists. [Listing 14-6](#L1406) runs in 1134 us for the test case.

You can probably see where we're heading. The `jz`/`loop` pair at the bottom of the loop in [Listing 14-6](#L1406) is an obvious candidate for conversion to `loopnz`, and [Listing 14-7](#L1407) takes advantage of just that conversion. Essentially, the test for a match is moved out of the loop in [Listing 14-7](#L1407), with `loopnz` replacing `loop` in order to allow the loop to end either on a match or at the end of the array. The result: [Listing 14-7](#L1407) runs in 1036 us, more than 9% faster than [Listing 14-7](#L1407). Not a *massive* improvement..but not a bad payoff for replacing one instruction and moving another.

(Food for thought: [Listings 14-6](#L1406) and [14-7](#L1407) could be speeded up by storing uppercase and lowercase versions of the search byte in separate registers and simply comparing each byte of the array to *both* versions. The extra comparison would be a good deal faster than the code used in [Listings 14-6](#L1406) and [14-7](#L1407) to convert each byte of the array to uppercase.)

### How You Loop Matters More Than You Might Think

In the last chapter, I lambasted `loop` as a slow looping instruction. Well, it *is* slow — but if you must perform repetitive tasks by branching — that is, if you must loop — `loop` is a good deal faster than other branching instructions. To drive that point home, I'm going to measure the performance of the case-insensitive search program of [Listing 14-6](#L1406) with the looping code implemented as follows: with `loop`, with `dec reg16/jnz`, with `dec reg8/jnz`, with `dec mem8/jnz`, and with `dec mem16/jnz`. (Remember that `dec reg16` is faster than `dec reg8`, and that byte-sized memory accesses are faster than word-sized accesses.)

[Listing 14-6](#L1406) already shows the `loop`-based implementation. [Listings 14-8](#L1408) through [14-11](#L1411) show the other implementations. Here are the results:

| Looping code                               | Listing         | Time    |
|--------------------------------------------|-----------------|---------|
| loop CaseInsensitiveSearchLoop             | [14-6](#L1406)  | 1134 us |
| Dec cx/jnz CaseInsensitiveSearchLoop       | [14-8](#L1408)  | 1199 us |
| dec cl/jnz CaseInsensitiveSearchLoop       | [14-9](#L1409)  | 1252 us |
| dec [BCount]/jnz CaseInsensitiveSearchLoop | [14-10](#L1410) | 1540 us |
| dec [WCount]/jnz CaseInsensitiveSearchLoop | [14-11](#L1411) | 1652 us |

While the incremental performance differences between the various implementations are fairly modest, `loop` is the clear winner, and is the shortest of the bunch as well.

Whenever you must branch in order to loop, use the `loop` instruction if you possibly can. The superiority of `loop` holds true only in the realm of branching instructions, for not — branching is *much* faster than looping with any of the branching instructions...but when space is at a premium, `loop` is hard to beat.

## 14.8 Only `jcxz` Can Test *and* Branch in a Single Bound

`jcxz` is the only 8088 instruction that can both test a register and branch according to the outcome. Most of the applications for this unusual property of `jcxz` are well-known, most notably avoiding division by zero and guarding against zero counts in loops. You may, however, find other, less obvious, applications if you stretch your mind a little.

For example, suppose that we have an animation program that needs to be speed-synchronized. This program has a delay loop built into each pass through the main loop; however, the proper delay will vary from processor to processor and from one display adapter to another, so the delay will need to be adjusted as the program runs.

Let's say that ideally the program should perform exactly 600 passes through the main loop every 10 seconds. In order to monitor its compliance with that standard, the program counts down a word-sized counter every time it completes the main loop. In a perfect world, the counter would reach zero precisely as the 10-second mark is reached.

That's not very likely to happen, of course. The program can easily detect if it's running too fast; if the counter reaches zero before the 10-second mark is reached, the delay needs to be increased. The quicker the counter reaches zero, the greater the necessary increase in the delay.

If the program does reach the 10-second mark without the counter reaching zero, then it's running too slowly, and the delay needs to be decreased. The higher the remaining count, the greater the amount by which the delay needs to be decreased, so we need to know not only that the counter hasn't reached zero but also the exact remaining count. At the same time, we need to reset the counter to its initial value in preparation for the next 10-second timing period.

We could do that easily enough with:

```nasm
    mov   ax,[SyncCount]            ;get remaining count
    mov   [SyncCount],INITIAL_COUNT
                                  ;set count back to initial value
    and   ax,ax                   ;is the count 0?
    jz    MainLoop                ;yes, so we're dead on and no
                                  ; adjustment is needed
; The count isn't zero, so the program is running too slowly.
; Decrease the delay proportionately to the value in AX.
```

With `jcxz` and a little creativity, however, we can tighten the code considerably:

```nasm
    mov   cx,INITIAL_COUNT
    xchg  [SyncCount],cx    ;get remaining count and set count
                            ; back to initial value
    jcxz  MainLoop          ;if the count is 0, we're dead on
                            ; and no adjustment is needed
; The count isn't zero, so the program is running too slowly.
; Decrease the delay proportionately to the value in CX.
```

With these changes, we've managed to trim a 13-byte sequence by 4 bytes — 30% — even though the original sequence used the accumulator-specific direct-addressed form of `mov`. There's nothing more profound here than familiarity with the 8088's instruction set and a willingness to mix and match instructions inventively — which, when you get right down to it, is where some of the best 8088 code comes from.

Try it yourself and see!

## 14.9 Jump and Call Tables

Given that you've got an index that's associated with the execution of certain code, jump and call tables allow you to branch very quickly to the corresponding code. A jump or call table is nothing more than an array of code addresses organized to correspond to some index value; the index can then be used to look up the matching address in the table, so that a branch can be made to that address.

The only difference between call tables and jump tables is the type of branch made. Both types of tables consist of nothing but addresses, and the distinction lies solely in whether the code using the table chooses to call or jump to the looked-up addresses. Jump tables are used in switch-type situations, where one of several paths through a routine is chosen, while call tables are used for applications such as function dispatchers, where one of several subroutines is executed. For simplicity, I'll refer to both sorts of tables as jump tables from now on.

The operation of a sample jump table is shown in Figure 14. 8.

![](images/fig14.8RT.png)

An index into the table is used to look up one of the entries in the table, and an indirect branch is performed to the address contained in that entry.

The size of a jump table entry can be either 2 or 4 bytes, depending on whether near or far branches are used by the code that branches through the jump table. As we discussed earlier, the 2-byte jump table entries used with near branches are vastly preferable to the 4-byte jump table entries used with far branches, for two reasons: 2-byte-per-entry jump tables are half the size of equivalent 4-byte-per-table jump tables, and near indirect branches are much faster than far indirect branches, especially when `call` and `ret` are used.

So, what's so great about jump tables? Simply put, they're usually the fastest way to turn an index into execution of the corresponding code. In the sorts of applications jump tables are best suited to, we basically already know which routine we want to branch to, thanks to the index — it's just a matter of getting there as fast as possible and in the fewest bytes, and jump tables are winners on both counts.

For example, suppose that we have a program that monitors the serial port and needs to branch quickly to 1 of 128 subroutines, depending on which one of the 128 7-bit ASCII characters is in AL. We could do that with 127 `cmp` instructions followed by conditional jumps, something like this:

```nasm
    and   al,7fh    ;make it 7-bit ASCII
          :
    cmp   al,8
    jae   Above7
    cmp   al,4
    jae   Above3
    cmp   al,2
    jae   Above1
    and   al,al
    jnz   Is1
; The character is ASCII 0.
          :
; The character is ASCII 1.
Is1:
```

However, this approach would take a *lot* of code to handle all 128 characters — somewhere between 4 and 7 bytes for each character after the first, or between 508 and 889 bytes in all. It would be slow as well, since seven comparisons and conditional jumps would be required to identify each character. Worse yet, some of the conditional jumps would have to be implemented as reverse-polarity conditional jumps around unconditional jumps, since conditional jumps only have a range of +127 to -128 bytes — and we know how slow jumps around jumps can be.

The failing of the above approach is that it uses code to translate a value in AL into a routine's offset to be loaded into IP. Because the mapping of values to offsets covers every value from 0 through 127 and is well-defined, it can be handled far more efficiently in the form of data than in the form of endless test-and-branch code. How? By constructing a table of offsets — a jump table — with the position of each routine's offset in the table corresponding to the value used to select that routine:

```nasm
Jump7BitASCIITable  label   word
    dw    Is0, Is1, Is2, Is3, Is4, Is5, Is6, Is7
    dw    Is8, Is9, Is10, Is11, Is12, Is13, Is14, Is15
    :
    mov   bl,al
    and   bx,7fh                    ;make it 7-bit ASCII and make it a word
    shl   bx,1                      ;*2 for lookup in a table of word-sized offsets
    jmp   [Jump7BitASCIITable+bx]   ;jump to handler for value
```

The jump table approach is not only faster (by a long shot — only four instructions and one branch are involved), it's also *much* more compact. Only 267 bytes are needed, less than half as many as required by the compare-and-branch approach.

It's not much of a contest, is it?

This may remind you of our experience with look-up tables in Chapter 7, and well it might, for a jump table is just another sort of look-up table. When a task is such that it can be solved by looking up a result rather than calculating it, the look-up approach almost invariably wins. It matters not a whit whether the desired result is a bit pattern, a multiplication product, or a code address.

### Partial Jump Tables

Jump tables work well even with less neatly organized index-to-offset mappings. Suppose, for example, that the ASCII character handler of the last example only needs to branch to unique handlers for the 32 control characters, with the other 96 characters handled by a single routine. That would greatly reduce the number of comparisons required by the compare-and-branch approach, improving performance and shrinking the code to less than 150 bytes. On the other hand, our jump-table implementation wouldn't shrink at all, since one jump-table entry would still be needed for each 7-bit ASCII character, although the entries for all the non-control character entries would be the same, as follows:

```nasm
Jump7BitASCIITable  label   word
    dw    Is0, Is1, Is2, Is3, Is4, Is5, Is6, Is7
    dw    Is8, Is9, Is10, Is11, Is12, Is13, Is14, Is15
    dw    Is16, Is17, Is18, Is19, Is20, Is21, Is22, Is23
    dw    Is24, Is25, Is26, Is27, Is28, Is29, Is30, Is31
    dw    96 dup (IsNormalChar)
    :
    mov   bl,al
    and   bx,7fh                    ;make it 7-bit ASCII and make it a word
    shl   bx,1                      ;*2 for lookup in a table of word-sized offsets
    jmp   [Jump7BitASCIITable+bx]   ;jump to handler for value
```

While the duplicate entries work perfectly well, all branching to the same place, they do waste bytes.

What of jump tables in this case?

Well, the pure jump table code would indeed be somewhat larger than the compare-and-branch code, but it would still be much faster. One of the wonders of jump tables is that they never require more than one branch, and no compare-and-branch approach that performs anything more complex than a yes/no decision can make that claim.

Matters are not so cut and dried as they might seem, however. We've learned that there are always other options, and this is no exception. Just as we achieved good results with a hybrid of in-line code and looping in the last chapter, we can come up with a better solution here by mixing the two approaches. We can compare-and-branch to handle the 96 normal characters, then use a reduced jump table to handle the 32 control characters, as follows:

```nasm
JumpControlCharTable  label   word
    dw    Is0, Is1, Is2, Is3, Is4, Is5, Is6, Is7
    dw    Is8, Is9, Is10, Is11, Is12, Is13, Is14, Is15
    dw    Is16, Is17, Is18, Is19, Is20, Is21, Is22, Is23
    dw    Is24, Is25, Is26, Is27, Is28, Is29, Is30, Is31
    :
    cmp   al,20h                      ;is it a control character?
    jnb   IsNormalChar                ;no-handle as a normal character
    mov   bl,al                       ;handle control characters through look-up table
    and   bx,7fh                      ;make it 7-bit ASCII and make it a word
    shl   bx,1                        ;*2 for lookup in a table of word-sized offsets
    jmp   [JumpControlCharTable+bx]   ;jump to handler for value
```

This partial jump table approach requires the execution of a maximum of just 6 instructions and 1 branch, and is just 79 bytes long — still vastly superior to the compare-and-branch approach, and, on balance, superior to the pure jump table approach as well.

Granted, pure jump table code would be slightly faster, since it's 2 instructions shorter, but that's just our familiar trade-off of speed for size. In this case that's an easy trade-off to make, since the speed difference is negligible and the size difference is great. The greater the number of tests required before performing the branch through the jump table in a partial jump table approach, the greater the performance loss and the less the space savings relative to a pure jump table approach. As usual, the decision is yours to make on a case by case basis.

### Generating Jump Table Indexes

There are many ways to generate indexes into jump tables. Sometimes indexes are passed in as parameters by calling routines, as in a function dispatcher. Sometimes indexes are read from ports or from memory. Indexes may also be looked up in *other* tables. For example, a keyboard handler might use `repnz scasw` to find the index for the current 16-bit key code in a key-mapping table, then use that index to jump to the appropriate key-handling routine via a jump table, as shown in [Listing 14-12](#L1412), which runs in 504 us for the sample keystrokes. ([Listing 14-12](#L1412) is a modification of the key-handling jump table code we saw in [Listing 11-17](#L1117).)

Why not simply put the address of each key handler right next to the corresponding 16-bit key code in a single look-up table, so no calculation is needed in order to perform the second look-up? For one thing, the second look-up takes hardly any time at all in [Listing 14-12](#L1412), since the calculation of the jump table address is performed as a *mod-reg-rm* calculation by:

```nasm
jmp   cs:[KeyJumpTable+di-2-offset KeyLookUpTable]
```

Even if the second look-up were slow, however, the two-table approach would still be preferable. You see, contiguous data arrays are required in order to use `repnz scasw`, and, as we learned a few chapters back, it's worth structuring your code so that repeated string instructions can be used whenever possible.

Does it really make that much difference to structure the table so that `rep scasw` can be used? It surely does. [Listing 14-13](#L1413), which uses a single look-up table containing both key codes and handler addresses, takes 969 us to run — nearly twice as long as [Listing 14-12](#L1412).

Design your code to use repeated string instructions!

At any rate, jump tables operate in the same basic way no matter how indexes are generated; an index is used to look up an address to branch to. The rule as to when you should use a jump table is equally simple: whenever you find yourself branching to one of several addresses based on one of a set of consecutive values, you should almost certainly use a jump table. If the values aren't consecutive but are bunched, you might want to use the partial jump table approach, filtering out the oddball cases and branching on those that are tightly grouped. Finally, if speed is paramount, the pure jump table approach is the way to go, even if that means making a large table containing many unused or duplicate entries.

### Jump Tables, Macros and Branched-To In-Line Code

In the last chapter, we simply calculated the destination offset whenever we needed to branch into in-line code. That approach is fine when the offset calculations involve nothing more than a few shifts and adds, but it can reduce performance considerably if a `mul` instruction must be used. Then, too, the calculated-offset approach only works if every repeated code block in the target in-line code is exactly the same size. That won't be the case if, for example, some repeated code blocks use short branches while others use normal branches, as shown in Figure 14.9.

![](images/fig14.9RT.png)

In such a case, a jump table is the preferred solution. Selecting an offset and branching to it through a jump table takes only a few instructions, and is certainly faster than multiplying. Jump tables can also handle repeated in-line code blocks of varying sizes, since jump tables store offsets that can point anywhere and can be arranged in any order, rather than being limited to calculations based on a fixed block size.

Let's look at the use of a jump table to handle a case where in-line code blocks do vary in size. Suppose that we're writing a subroutine that will search the first *n* bytes of a zero-terminated string of up to 80 bytes in length for a given character. We want to use pure in-line code for speed, but that's more easily said than done. The in-line code performs conditional jumps when checking for both matches and terminating zeros; unfortunately, the entire in-line code sequence is so long that the 1-byte displacement of a conditional jump can't reach the termination labels from the in-line code blocks that are smack in the middle of the in-line code. We could solve this problem by using conditional jumps around unconditional jumps in all cases, but that seems like an awful waste given that many of the blocks *could* use conditional jumps.

What we really want to do is use conditional jumps in some in-line code blocks — whenever a 1-byte displacement will reach — and jumps around jumps in other blocks. Unfortunately, that would mean that some blocks were larger than others, and *that* would mean that there was no easy way to calculate the start offset of the desired block.

The answer (surprise!) is to use a jump table, as shown in [Listing 14-14](#L1414). The jump table simply stores the start offset of each in-line code block, regardless of how large that block may be. While the jump table is 162 bytes in size, there's no speed penalty for using it, since the process of looking up a table entry and branching accordingly requires only a few instructions. Indeed, it's often faster to use a jump table in this way than it is to calculate the target offset even when the repeated in-line code blocks *are* all the same size.

How does [Listing 14-14](#L1414) generate in-line code blocks of varying sizes? The macro `CHECK_CHAR`, which is used to generate each in-line code block, actually calculates the distance from the end of each conditional jump to the target label, and uses the `if` directive to assemble a single conditional jump if a 1-byte displacement will reach the target label, or a conditional jump around an unconditional jump if necessary. In some cases a conditional jump does reach, while in others it doesn't; as a result, the in-line code blocks vary in size.

[Listing 14-14](#L1414) illustrates the use of a clever technique that's most useful for generating jump tables that point to in-line code: macro text substitution. In order to generate a unique label for each repeated code block, the assembler variable `BLOCK_NUMBER` is initially set to zero, and then incremented each time a new code block is created. (Note that `BLOCK_NUMBER` is a variable used during assembly, not a variable used by the assembler program. Such variables are used to control assembly, and the program being assembled has no knowledge of them at run time.)

The value of `BLOCK_NUMBER` is passed to `CHECK_CHAR`, the macro that creates each instance of the repeated code, as follows:

```nasm
CHECK_CHAR   %BLOCK_NUMBER
```

The macro sees this passed parameter as the parameter `NUMBER`. Thanks to the percent-sign, the assembler actually makes the value of `BLOCK_NUMBER` into a text string when it passes it to `CHECK_CHAR`; that text string is then substituted wherever the parameter `NUMBER` appears in the macro.

What's really interesting is what comes of butting `&NUMBER&` up against the text "CheckChar" in the macro `CHECK_CHAR`, as follows:

```nasm
CheckChar&NUMBER&:
```

(The ampersands ('&') around `NUMBER` ensure that the assembler knows that parameter substitution should take place; otherwise, when `NUMBER` is butted up against other text, as it is above, the assembler has no way of knowing whether to treat `NUMBER` as a parameter or as part of a longer text string.) A text representation of the value of `NUMBER` is substituted into the above line, so if `NUMBER` is 2, the line becomes:

```nasm
CheckChar2:
```

If `NUMBER` is 10, the line becomes:

```nasm
CheckChar10:
```

Do you see what we've done? We've created a unique label for each repeated code block, since `BLOCK_NUMBER` is incremented after each code block is created. Better yet, the labels are organized in a predictable manner, with the first code block labelled with `CheckChar0`, the second labelled with `CheckChar1`, and so on.

It should be pretty clear that this is an ideal set-up for a jump table. There are a couple of tricks here, however. First, if we want to check at most one character, we must branch to not the first but the *last* repeated in-line code block, and that code block is labelled with `CheckChar79`. That means that our jump table should look something like this:

```nasm
CheckCharJumpTable  label   word
    dw    NoMatch
    dw    CheckChar79, CheckChar78, CheckChar77, CheckChar76
    dw    CheckChar75, CheckChar74, CheckChar73, CheckChar72
    :
    dw    CheckChar3, CheckChar2, CheckChar1, CheckChar0
```

with the maximum number of characters to check used as the index into the table. That way, a maximum check count of 1 will branch to the last repeated in-line code block, a maximum count of 2 will branch to the next to last block, and so on.

That brings us to the second trick: why do all the typing involved in creating the above table, when we've already seen that labels created with macros can do the work for us? The following is a *much* easier way to create the jump table:

```nasm
MAKE_CHECK_CHAR_LABEL   macro   NUMBER
        dw    CheckChar&NUMBER&
        endm
              :
SearchTable   label   word
        dw    NoMatch
BLOCK_NUMBER=MAX_SEARCH_LENGTH-1
        rept  MAX_SEARCH_LENGTH
        MAKE_CHECK_CHAR_LABEL %BLOCK_NUMBER
BLOCK_NUMBER=BLOCK_NUMBER-1
        endm
```

[Listing 14-14](#L1414) puts all of the above together, creating and using unique labels in both the in-line code and the jump table. Figure 14.10 illustrates [Listing 14-14](#L1414) in action.

![](images/fig14.10RT.png)

Study both the listing and the figure carefully, for macros, repeat blocks, jump tables, and in-line code working together are potent indeed.

Now for the kicker: all that fancy coding actually doesn't even pay off in this particular case. [Listing 14-14](#L1414) runs in 1013 us. [Listing 14-15](#L1415), which uses a standard loop approach, runs in 988 us! Not only is [Listing 14-15](#L1415) faster, but it's also hundreds of bytes shorter and much simpler than [Listing 14-14](#L1414) — and, unlike [Listing 14-14](#L1414), [Listing 14-15](#L1415) can handle strings of any length. Frankly, there's no reason to recommend [Listing 14-14](#L1414) over [Listing 14-15](#L1415), and good reason not to.

Why have I spent all this time developing *slower* code? Forget the specific example: the idea was to show you how jump tables can be used to branch into in-line code, even when the in-line code consists of code blocks of varying lengths. The particular example I chose doesn't benefit from these techniques because it was selected for illustrative rather than practical purposes. While there are good applications for jump tables that branch into in-line code — plenty of them! — they tend to be lengthy and complex, and I decided to choose an example that was short enough so that the decidedly non-obvious techniques used could be readily understood.

Why does this particular example not benefit much from the use of branched to in-line code? The answer is that too few of the branches in [Listing 14-14](#L1414) are able to use a 1-byte conditional jump. As a result, many of the branches — especially those between the middle and end of the in-line code, which tend to be executed most often — must use jumps around jumps. The end result is that *two* branches, in the form of jumps around jumps, are often performed for each byte checked in [Listing 14-14](#L1414), while only one branch — a `loop` — is performed for each byte checked in [Listing 14-15](#L1415).

In truth, the best way to speed up this code would be partial in-line code, which would allow *all* the branches to use 1-byte displacements. A double-scan approach, using a repeated string instruction to search for the terminating zero and then another string instruction to search for the desired character, might also serve well.

Just to demonstrate the flexibility of macros, jump tables, and branched-to in-line code, however, [Listing 14-16](#L1416) is a modification of [Listing 14-14](#L1414) that branches out with 1-byte displacements at *both* ends of the in-line code, using conditional jumps around unconditional jumps only in the middle of the in-line code, where 1-byte displacements can't reach past either end. As predicted, [Listing 14-16](#L1416) is, at 908 us, a good bit faster than [Listings 14-14](#L1414) and [14-15](#L1415). (Bear in mind that the relative performances of these listings could change considerably given different search parameters. *There is no such thing as absolute performance*. Know the conditions under which your code will run!)

[Listing 14-16](#L1416) isn't *blazingly* fast, but it is fast enough to remind us that branched-to in-line code is a most attractive option...and now jump tables let us use branched-to in-line code in more situations than ever, and often with improved speed, as well.

## 14.10 Forward References Rear Their Collective Ugly Head Once More

You may have noticed that `CHECK_CHAR2`, the macro in [Listing 14-16](#L1416) that assembles in-line code blocks that use conditional jumps forward to `NoMatch2` and `MatchFound2`, is a bit different from `CHECK_CHAR`, which assembles blocks that use backward jumps. `CHECK_CHAR` uses the `if` directive to determine whether a conditional jump can be used, assembling a jump around a jump if a conditional jump won't reach. `CHECK_CHAR2`, on the other hand, always assembles a conditional jump.

The reason is this: when the assembler performs arithmetic for use in `if` directives, all the values in the expression must already be known when the `if` is encountered. In particular, the offset of a forward-referenced label can't be used in `if` arithmetic. Why? When performing `if` arithmetic with a forward-referenced label, the assembler doesn't know whether the `if` is true until the forward-referenced label has been assembled. That creates a nasty paradox, since the assembler can't assemble the label, which follows the `if`, until the `if` has been evaluated and the code associated with the `if` has or hasn't been assembled. The assembler resolves this chicken-and-egg problem by reporting an error.

The upshot is that while a line like:

````nasm
if ($-BackwardReferencedLabel)
```

is fine, a line like:

```nasm
if (ForwardReferencedLabel-$)
```

is not. Alas, that means that there's no way to have a macro do automatic jump sizing for branches to forward-referenced labels — hence the lack of conditional assembly in `CHECK_CHAR2` — although there's no problem with backward-referenced labels, as evidenced by `CHECK_CHAR`. In fact, I arrived at the optimum number of repetitions of `CHECK_CHAR2` in [Listing 14-16](#L1416) by rough calculation followed by trial-and-error... and that's what you'll have to do when trying to get maximum performance out of forward branches in in-line code.

Actually, there is an alternative to trial-and-error: as I mentioned earlier, assemblers that detect and/or correct suboptimal branches can help considerably in optimizing forward in-line branches. If you're using MASM, however, backward branches, which macros (or even the assembler, for unconditional branches) can easily optimize, should be used whenever possible.

A final note: macros can easily obscure the true nature of your code, since you don't see the actual code that's assembled when you scan a listing containing macros. That problem becomes all the more acute when the `if` directive is used to produce conditionally assembled code. Whenever you're not sure exactly what code you're assembling, generate an assembler listing file that shows macro expansions, or take a look at the actual code with a debugger.

### Still and All... Don't Jump!

All of the wonderful branching tricks we've encountered in this chapter notwithstanding, you're still better off from a performance perspective when you don't branch. Granted, branching can often be beneficial from a code-size perspective, but performance is more often an issue than is size. Also, the improvements in performance that can be achieved by not-branching are relatively far greater than the improvements in size that can be achieved by judicious branching.

Think back again to [Listing 11-27](#L1127), in which we sped up a case-insensitive string comparison considerably simply by looking up the uppercase version of each character in a table instead of using a mere five instructions — and at most one branch — to convert each character to uppercase. *Only rarely can code-only calculations, especially calculations that involve branching, beat table look-ups.* What's more, we could speed the code up a good deal more by using pure or partial in-line code rather than looping every two characters. If we wanted to, we could effectively eliminate nearly every single branch in the string-comparison code — and the code would be much the faster for it.

No matter how tight your code is, if it branches it *can* be made faster. Whether it *is* made faster is purely a matter of: a) your ability to bring techniques such as table look-ups and in-line code to bear, and b) your willingness to trade the extra bytes those techniques require for the cycles they save. To that list I might add a third, slightly different condition: c) the degree to which the performance of the code matters.

Never waste your time optimizing non-critical code for speed. There's too much time-critical code in the world that *needs* improving to squander effort on initialization code, code outside loops, and the like.

### This Concludes Our Tour of the 8088's Instruction Set

And with that, we've come to the end of our long journey through the 8088's strange but powerful instruction set. We haven't covered all the variations of all the instructions — not by a long shot — but we have done the major ones, and we've gotten a good look at what the 8088 has to offer. As a sort of continuing education on the instruction set, you would do well to scan through Appendix A and/or other instruction set summaries periodically. I've been doing that for seven years now, and I still find useful new tidbits in the instruction set from time to time.

We've also come across a great many tricks, tips, and optimizations in our travels — but Lord knows we haven't seen them all! Thanks to the virtually infinite permutations of which the 8088's instruction set is capable, as well as the inherent and unpredictable variation of the execution time of any given instruction, PC code optimization is now and forever an imperfect art. Nonetheless, we've learned a great deal, and with that knowledge and the Zen timer in hand, we're well along the path to becoming expert code artists.
