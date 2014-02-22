# Chapter 15: Other Processors

Now that we've spent 14 chapters learning how to write good assembler code for the 8088, it's time to acknowledge that there are other widely-used processors in the 8088's family: the 8086, the 80286, and the 80386, to name but a few. None of the other processors are as popular as the 8088 yet, but some — most notably the 80386 — are growing in popularity, and it's likely that any code you write for general distribution will end up running on those processors as well as on the 8088.

*Omigod*! Does that mean that you need to learn as much about those processors as you've learned about the 8088? Not at all. We'll see why shortly, but for now, take my word for it: the 8088 is the processor for which you should optimize.

Nonetheless, in this chapter we'll take a quick look at optimizations for other processors, primarily the 80286 and the 80386. Why? Well, many of the optimizations for those processors are similar to those for the 8088, and it's useful to know which of the rules we've learned are generally applicable to the whole family (all the major ones, as it turns out). Also, one particular optimization for other 8086-family processors — data alignment — is so easy to implement, costs so little, and has such a large payback that you might want to apply it routinely to your code even though it has no effect on 8088 performance.

Finally, I'd like to get you started in the right direction if you *are* primarily interested in optimization for the 80286 and its successors. After all, the 8088 is going to go out of style *someday* (although that's certainly not happening anytime soon), and OS/2 and its ilk are creeping up on us. You have the Zen timer, and you've learned much about how to evaluate and improve code performance; with a bit of a head start here, you should be able to develop your own expertise in 80286/80386 coding if you so desire.

## Why Optimize for the 8088?

The great lurking unanswered question is: given that the 80286 and the 80386 (and the 80486 someday) are the future of PC-compatible computing, why optimize for the 8088? Why not use all the extra instructions and features of the newer processors to supercharge your code so it will run as fast as possible on the fastest computers?

There are several reasons. Each by itself is probably ample reason to optimize for the 8088; together, they make a compelling argument for 8088-specific optimization. Briefly put, the reasons are:

  * The 8088 is the lowest common denominator of the 8086 family for both compatibility and performance.
  * The market for software that runs on the 8088 is enormous.
  * The 8088 is the 8086-family processor for which optimization pays off most handsomely.
  * The 8088 is the only 8086-family processor which comes in a single consistent system configuration — the IBM PC.
  * The major 8088 optimizations work surprisingly well on the 80286 and 80386.

As we discuss these reasons below, bear in mind that when I say "8088,"I mean "8088 as used in the IBM PC," for it's the widespread use of the PC that makes the 8088 the assembler programmer's chip of choice.

That said, let's tackle our original question again, this time in more detail: why optimize for the 8088?

For starters, the 8088 is the lowest common denominator of the 8086 family, unless you're writing applications for an operating system that doesn't even run on an 8088 -OS/2, an 80286/80386-specific version of Unix, or the like. Code written for the 8088 will run on all of the other chips in the 8086 family, while code written for the 80286 or the 80386 won't run on the 8088 if any of the special features and/or instructions of those chips are used.

It stands to reason, then, that code written for the 8088 has the broadest market and is the most generally useful code around. That status should hold well into the twenty-first century, given that every 8086-family processor Intel has ever introduced has provided full backward compatibility with the 8088. If any further proof is needed, hardware and/or software packages that allow 8088 code to be run are available for a number of computers built around non-Intel processors, including the Apple Macintosh, the Commodore Amiga, and a variety of 68XXX-based workstations.

The 8088 is the lowest common denominator of the 8086 family in terms of performance as well as code compatibility. No 8086-family chip runs slower than the 8088, and it's a safe bet that none ever will. By definition, any code that runs adequately fast on an 8088 is bound to be more than adequate on any other 8086-family processor. Unless you're willing to forgo the 8088 market altogether, then, it certainly makes sense to optimize your code for the 8088.

The 8088 is also the processor for which optimization pays off best. The slow memory access, too-small 8-bit bus, and widely varying instruction execution times of the 8088 mean that careful coding can produce stunning improvements in performance. Over the past few chapters we've seen that it's possible to double and even triple the performance of already-tight 8088 assembler code. While the 80286 and 80386 certainly offer optimization possibilities, their superior overall performance results partly from eliminating some of the worst bottlenecks of the 8088, so it's harder to save cycles by the bushel. Then, too, the major optimizations for the 8088 — keep instructions short, use the registers, use string instructions, and the like — also serve well on the 80286 and 80386, so optimization for the 8088 results in code that is reasonably well optimized across the board.

Finally, the 8088 is the only 8086-family processor that comes in one consistent system configuration — the IBM PC. There are 8088-based computers that run at higher clock speeds than the IBM PC, but, to the best of my knowledge, all 8088-based PC compatible computers have zero-wait-state memory. By contrast, the 80286 comes in two flavors: classic one-wait-state AT, and souped-up zero-wait-state AT... and additional variations will surely appear as high-speed 80286s become available. The 80386 is available in a multitude of configurations: static-column RAM, cached memory, and interleaved memory, to name a few, with each of those available in several versions.

What all that means is that while you can rely on fast code on one PC being fast code on any PC, that's not the case with 80286 and 80386 computers. 80286/80386 performance can vary considerably, depending on how your code interacts with a particular computer's memory architecture. As a result, it's only on the PC that it pays to fine-tune your assembler code down to the last few cycles.

So. I hope I've convinced you that the 8088 is the best place to focus your optimization efforts. In any case, let's tour the rest of the 8086 family.

## Which Processors Matter?

While the 8086 family is a large one, only a few members of the family — which includes the 8088, 8086, 80188, 80186, 80286, 80386SX, and 80386 — really matter.

The 80186 and 80188 never really caught on for use in PC compatibles, and don't require further discussion.

The 8086, which is a good bit faster than the 8088, was used fairly widely for a while, but has largely been superseded by the 80286 as the chip of choice for better-than-8088 performance. (The 80386 is the chip of choice for flat-out performance, but it's the 80286 that's generally used in computers that are faster but not much more expensive than 8088-based PCs.) Besides, the 8086 has exactly the same Execution Unit instruction execution times as the 8088, so much of what we've learned about the 8088 is directly applicable to the 8086. The only difference between the two processors is that the 8086 has a 16-rather than 8-bit bus, as we found back in Chapter 3. That means that the 8086 suffers less from the prefetch queue and 8-bit bus cycle-eaters than does the 8088.

That's not to say that the 8086 doesn't suffer from those cycle-eaters at all; it just suffers less than the 8088 does. Instruction fetching is certainly still a bottleneck on the 8086. For example, the 8086's Execution Unit can execute register-only instructions such as `shl`{.nasm} and `inc`{.nasm} twice as fast as the Bus Interface Unit can fetch those instructions. Of course, that is a considerable improvement over the 8088, which can execute those instructions *four* times as fast as they can be fetched.

Oddly enough, the 8-bit bus cycle-eater is also still a problem on the 8086, even though the 8086's bus is 16 bits wide. While the 8086 is indeed capable of fetching words as rapidly as bytes, that's true only for words that start at even addresses. Words that start at odd addresses are fetched with two memory accesses, since the 8086 is capable of performing word-sized accesses only to even addresses. We'll discuss this phenomenon in detail when we get to the 80286.

In summary, the 8086 is much like the 8088, save that the prefetch queue cycle-eater is less of a problem and that word-sized accesses should be made to even addresses. Both these differences mean that code running on an 8086 always runs either exactly as fast as or faster than it would run on an 8088, so the rule still is: optimize for the 8088, and the code will perform even better on an 8086.

That leaves us with the high-end chips: the 80826, the 80386SX, and the 80386. At this writing, it's unclear whether the 80386SX is going to achieve widespread popularity; it may turn out that the relatively small cost advantage the 80386SX enjoys over the 80386 isn't enough to offset its relatively large performance disadvantage. After all, the 80386SX suffers from the same debilitating problem that looms over the 8088 — a too-small bus. Internally, the 80386SX is a 32-bit processor, but externally, it's a 16-bit processor... and we know what *that* sort of mismatch can lead to!

Given its uncertain acceptance, I'm not going to discuss the 80386SX in detail. If you do find yourself programming for the 80386SX, follow the same general rules we've established for the 8088: use short instructions, use the registers as heavily as possible, and don't branch. In other words, avoid memory, since the 80386SX is by definition better at processing data internally than it is at accessing memory.

Which leaves us with just two processors, the 80286 and the 80386.

### The 80286 and the 80386

There's no question but what the 80286 and 80386 are very popular processors. The 8088 is still more widely used than either of its more powerful descendants, but the gap is narrowing, and the more powerful processors can only gain in popularity as their prices comes down and memory — which both can use in huge quantities — becomes cheaper. All in all, it's certainly worth our while to spend some time discussing 80286/80386 optimization.

We're only going to talk about real-mode operation of the 80286 and 80386, however. Real mode is the mode in which the processors basically act like 8088s (albeit with some new instructions), running good old MS-DOS. By contrast, protected mode offers a whole new memory management scheme, one which isn't supported by the 8088. Only code specifically written for protected mode can run in that mode; it's an alien and hostile environment for MS-DOS programs.

In particular, segments are different creatures in protected mode. They're selectors — indexes into a table of segment descriptors — rather than plain old registers, and can't be set arbitrarily. That means that segments can't be used for temporary storage or as part of a fast indivisible 32-bit load from memory, as in:

```nasm
les   ax,dword ptr [LongVar]
mov   dx,es
```

which loads `LongVar`{.nasm} into DX:AX faster than:

```nasm
mov   ax,word ptr [LongVar]
mov   dx,word ptr [LongVar+2]
```

Protected mode uses those altered segment registers to offer access to a great deal more memory than real mode: the 80286 supports 16 megabytes of memory, while 80386 supports 4 gigabytes (4 K megabytes) of physical memory and 64 *terabytes* (64 K gigabytes!) of virtual memory. There's a price to pay for all that memory: protected-mode code tends to run a bit more slowly than equivalent real mode code, since instructions that load segments run more slowly in protected mode than in real mode.

Also, in protected mode your programs generally run under an operating system (OS/2, Unix, or the like) that exerts much more control over the computer than does MS-DOS. Protected-mode operating systems can generally run multiple programs simultaneously, and the performance of any one program may depend far less on code quality than on how efficiently the program uses operating system services and how often and under what circumstances the operating system preempts the program. Protected mode programs are often nothing more than collections of operating system calls, and the performance of whatever code *isn't* operating-system oriented may depend primarily on how large a timeslice the operating system gives that code to run in.

In short, protected mode programming is a different kettle of fish altogether from what we've seen in *The Zen of Assembly Language*. There's certainly a Zen to protected mode... but it's not the Zen we've been learning, and now is not the time to pursue it further.

## Things Mother Never Told You, Part II

Under the programming interface, the 80286 and 80386 differ considerably from the 8088. Nonetheless, with one exception and one addition, the cycle-eaters remain much the same on computers built around the 80286 and 80386. Next, we'll review each of the familiar cycle-eaters as they apply to the 80286 and 80386, and we'll look at the new member of the gang, the data alignment cycle-eater.

The one cycle-eater that vanishes on the 80286 and 80386 is the 8-bit bus cycle-eater. The 80286 is a 16-bit processor both internally and externally, and the 80386 is a 32-bit processor both internally and externally, so the Execution Unit/Bus Interface Unit size mismatch that plagues the 8088 is eliminated. Consequently, there's no longer any need to use byte-sized memory variables in preference to word-sized variables, at least so long as word-sized variables start at even addresses, as we'll see shortly. On the other hand, access to byte-sized variables still isn't any *slower* than access to word-sized variables, so you can use whichever size suits a given task best.

You might think that the elimination of the 8-bit bus cycle-eater would mean that the prefetch queue cycle-eater would also vanish, since on the 8088 the prefetch queue cycle-eater is a side effect of the 8-bit bus. That would seem all the more likely given that both the 80286 and the 80386 have larger prefetch queues than the 8088 (6 bytes for the 80286, 16 bytes for the 80386) and can perform memory accesses, including instruction fetches, in far fewer cycles than the 8088.

However, the prefetch queue cycle-eater *doesn't* vanish on either the 80286 or the 80386, for several reasons. For one thing, branching instructions still empty the prefetch queue, so instruction fetching still slows things down after most branches; when the prefetch queue is empty, it doesn't much matter how big it is. (Even apart from emptying the prefetch queue, branches aren't particularly fast on the 80286 or the 80386, at a minimum of seven-plus cycles apiece. Avoid branching whenever possible.)

After a branch it *does* matter how fast the queue can refill, and there we come to the second reason the prefetch queue cycle-eater lives on: the 80286 and 80386 are so fast that sometimes the Execution Unit can execute instructions faster than they can be fetched, even though instruction fetching is *much* faster on the 80286 and 80836 than on the 8088.

(All other things being equal, too-slow instruction fetching is more of a problem on the 80286 than on the 80386, since the 80386 fetches 4 instruction bytes at a time versus the 2 instruction bytes fetched per memory access by the 80286. However, the 80386 also typically runs at least twice as fast as the 80286, meaning that the 80386 can easily execute instructions faster than they can be fetched unless very high-speed memory is used.)

The most significant reason that the prefetch queue cycle-eater not only survives but prospers on the 80286 and 80386, however, lies in the various memory architectures used in computers built around the 80286 and 80286. Due to the memory architectures, the 8-bit bus cycle-eater is replaced by a new form of the wait-state cycle-eater: wait states on accesses to normal system memory.

### System Wait States

The 80286 and 80386 were designed to lose relatively little performance to the prefetch queue cycle-eater... *when used with zero-wait-state memory* — memory that can complete memory accesses so rapidly that no wait states are needed. However, true zero-wait-state memory is almost never used with those processors. Why? Because memory that can keep up with an 80286 is fairly expensive, and memory that can keep up with an 80386 is *very* expensive. Instead, computer designers use alternative memory architectures that offer more performance for the dollar — but less performance overall — than zero-wait-state memory. (It *is* possible to build zero-wait-state systems for the 80286 and 80386; it's just so expensive that it's rarely done.)

The IBM AT and true compatibles use one-wait-state memory (some AT clones use zero-wait-state memory, but such clones are less common than one-wait-state AT clones). 80386 systems use a wide variety of memory systems, including high-speed caches, interleaved memory, and static-column RAM, that insert anywhere from 0 to about 5 wait states (and many more if 8-or 16-bit memory expansion cards are used); the exact number of wait states inserted at any given time depends on the interaction between the code being executed and the memory system it's running on. The performance of most 80386 memory systems can vary greatly from one memory access to another, depending on factors such as what data happens to be in the cache and which interleaved bank and/or RAM column was accessed last.

The many memory systems in use make it impossible for us to optimize for 80286/80386 computers with the precision to which we've become accustomed on the 8088. Instead, we must write code that runs reasonably well under the varying conditions found in the 80286/80386 arena.

The wait states that occur on most accesses to system memory in 80286 and 80386 computers mean that nearly every access to system memory — memory in the DOS's normal 640 Kb memory area — is slowed down. (Accesses in computers with high-speed caches may be wait-state-free if the desired data is already in the cache, but will certainly encounter wait states if the data isn't cached; this phenomenon produces highly variable instruction execution times.) While this is our first encounter with system memory wait states, we have run into a wait-state cycle-eater before: the display adapter cycle-eater, which we discussed way back in Chapter 4. System memory generally has fewer wait states per access than display memory. However, system memory is also accessed far more often than display memory, so system memory wait states hurt plenty — and the place they hurt most is instruction fetching.

Consider this. The 80286 can store an immediate value to memory, as in `mov [WordVar],0`{.nasm}, in just 3 cycles. However, that instruction is 6 bytes long. The 80286 is capable of fetching 1 word every 2 cycles; however, the one-wait-state architecture of the AT stretches that to 3 cycles. Consequently, 9 cycles are needed to fetch the 6 instruction bytes. On top of that, 3 cycles are needed to write to memory, bringing the total memory access time to 12 cycles. On balance, memory access time — especially instruction prefetching — greatly exceeds execution time, to the extent that this particular instruction can take up to four times as long to run as it does to execute in the Execution Unit.

And that, my friend, is unmistakably the prefetch queue cycle-eater. I might add that the prefetch queue cycle-eater is in rare good form in the above example: a 4-to-1 ratio of instruction fetch time to execution time is in a class with the best (or worst!) we've found on the 8088.

Let's check out the prefetch queue cycle-eater in action. [Listing 15-1](#listing-15-1) times `mov [WordVar],0`{.nasm}. The Zen timer reports that on a one-wait-state 10-MHz AT clone (the computer used for all tests in this chapter), [Listing 15-1](#listing-15-1) runs in 1.27 us per instruction. That's 12.7 cycles per instruction, just as we calculated above. (That extra seven-tenths of a cycle comes from DRAM refresh, which we'll get to shortly.)

What does this mean? It means that, practically speaking, the 80286 as used in the AT doesn't have a 16-bit bus. From a performance perspective, the 80286 in an AT has two-thirds of a 16-bit bus (a 10.7-bit bus?), since every bus access on an AT takes 50% longer than it should. An 80286 running at 10 MHz *should* be able to access memory at a maximum rate of 1 word every 200 ns; in a 10-MHz AT, however, that rate is reduced to 1 word every 300 ns by the one-wait-state memory.

In short, a close relative of our old friend the 8-bit bus cycle-eater — the system memory wait state cycle-eater — haunts us still on all but zero-wait-state 80286 and 80386 computers, and that means that the prefetch queue cycle-eater is alive and well. (The system memory wait state cycle-eater isn't really a new cycle-eater, but rather a variant of the general wait state cycle-eater, of which the display adapter cycle-eater is another variant.) While the 80286 in the AT can fetch instructions much faster than can the 8088 in the PC, it can execute those instructions faster still.

The picture is less clear in the 80386 world, since there are so many different memory architectures, but similar problems can occur in any computer built around an 80286 or 80386. The prefetch queue cycle-eater is even a factor — albeit a lesser one — on zero-wait-state machines, both because branching empties the queue and because some instructions can outrun even zero-wait-state instruction fetching. ([Listing 15-1](#listing-15-1) would take at least 8 cycles per instruction on a zero-wait-state AT — 5 cycles longer than the official execution time.)

To summarize:

  * Memory-accessing instructions don't run at their official speeds on non-zero-wait-state 80286/80386 computers.
  * The prefetch queue cycle-eater reduces performance on 80286/80386 computers, particularly when non-zero-wait-state memory is used.
  * Branches generally execute at less than their rated speeds on the 80286 and 80386, since the prefetch queue is emptied.
  * The extent to which the prefetch queue and wait states affect performance varies from one 80286/80386 computer to another, making precise optimization impossible.

What's to be learned from all this? Several things:

  * Keep your instructions short.
  * Keep it in the registers; avoid memory, since memory generally can't keep up with the processor.
  * Don't jump.

Of course, those are exactly the rules we've developed for the 8088. Isn't it convenient that the same general rules apply across the board?

### Data Alignment

Thanks to its 16-bit bus, the 80286 can access word-sized memory variables just as fast as byte-sized variables. There's a catch, however: that's only true for word-sized variables that start at even addresses. When the 80286 is asked to perform a word-sized access starting at an odd address, it actually performs two separate accesses, each of which fetches 1 byte, just as the 8088 does for all word-sized accesses.

Figure 15.1 illustrates this phenomenon.

![](images/fig15.1RT.png)

The conversion of word-sized accesses to odd addresses into double byte-sized accesses is transparent to memory-accessing instructions; all any instruction knows is that the requested word has been accessed, no matter whether 1 word-sized access or 2 byte-sized accesses were required.

The penalty for performing a word-sized access starting at an odd address is easy to calculate: two accesses take twice as long as one access. In other words, the effective capacity of the 80286's external data bus is *halved* when a word-sized access to an odd address is performed.

That, in a nutshell, is the data alignment cycle-eater, the one new cycle-eater of the 80286 and 80386. (The data alignment cycle-eater is a close relative of the 8088's 8-bit bus cycle-eater, but since it behaves differently — occurring only at odd addresses — and is avoided with a different workaround, we'll consider it to be a new cycle-eater.)

The way to deal with the data alignment cycle-eater is straightforward: *don't perform word-sized accesses to odd addresses on the 80286 if you can help it*. The easiest way to avoid the data alignment cycle-eater is to place the directive `even`{.nasm} before each of your word-sized variables. `even`{.nasm} forces the offset of the next byte assembled to be even by inserting a `nop`{.nasm} if the current offset is odd; consequently, you can ensure that any word-sized variable can be accessed efficiently by the 80286 simply by preceding it with `even`{.nasm}.

[Listing 15-2](#listing-15-2), which accesses memory a word at a time with each word starting at an odd address, runs on a 10-MHz AT clone in 1.27 us per repetition of `movsw`{.nasm}, or 0.64 us per word-sized memory access. That's 6-plus cycles per word-sized access, which breaks down to two separate memory accesses — 3 cycles to access the high byte of each word and 3 cycles to access the low byte of each word, the inevitable result of non-word-aligned word-sized memory accesses — plus a bit extra for DRAM refresh.

On the other hand, [Listing 15-3](#listing-15-3), which is exactly the same as [Listing 15-2](#listing-15-2) save that the memory accesses are word-aligned (start at even addresses), runs in 0.64 us per repetition of `movsw`{.nasm}, or 0.32 us per word-sized memory access. That's 3 cycles per word-sized access — exactly twice as fast as the non-word-aligned accesses of [Listing 15-2](#listing-15-2), just as we predicted.

The data alignment cycle-eater has intriguing implications for speeding up 80286/80386 code. The expenditure of a little care and a few bytes to make sure that word-sized variables and memory blocks are word-aligned can literally double the performance of certain code running on the 80286; even if it doesn't double performance, word alignment usually helps and never hurts.

In fact, word alignment provides such an excellent return on investment on the 80286 that it's the one 80286-specific optimization that I recommend for assembler code in general. (Actually, word alignment pays off on the 80386 too, as we'll see shortly.) True, word alignment costs a few bytes and doesn't help the code that most needs help — code running on the 8088. Still, it's hard to resist a technique that boosts 80286 performance so dramatically without losing 8088 compatibility in any way or hurting 8088 performance in the least.

### Code Alignment

Lack of word alignment can also interfere with instruction fetching on the 80286, although not to the extent that it interferes with access to word-sized memory variables. The 80286 prefetches instructions a word at a time; even if a given instruction doesn't begin at an even address, the 80286 simply fetches the first byte of that instruction at the same time that it fetches the last byte of the previous instruction, as shown in Figure 15.2, then separates the bytes internally. That means that in most cases instructions run just as fast whether they're word-aligned or not.

![](images/fig15.2RT.png)

There is, however, a non-word-alignment penalty on *branches* to odd addresses. On a branch to an odd address, the 80286 is only able to fetch 1 useful byte with the first instruction fetch following the branch, as shown in Figure 15.3.

![](images/fig15.3RT.png)

In other words, lack of word alignment of the target instruction for any branch effectively cuts the instruction-fetching power of the 80286 in half for the first instruction fetch after that branch. While that may not sound like much, you'd be surprised at what it can do to tight loops; in fact, a brief story is in order.

When I was developing the Zen timer, I used my trusty 10-MHz AT clone to verify the basic functionality of the timer by measuring the performance of simple instruction sequences. I was cruising along with no problems until I timed the following code:

```nasm
    mov   cx,1000
    call  ZTimerOn
LoopTop:
    loop  LoopTop
    call  ZTimerOff
```

Now, the above code *should* run in, say, about 12 cycles per loop at most. Instead, it took over 14 cycles per loop, an execution time that I could not explain in any way. After rolling it around in my head for a while, I took a look at the code under a debugger... and the answer leaped out at me. *The loop began at an odd address!* That meant that two instruction fetches were required each time through the loop; one to get the opcode byte of the `loop`{.nasm} instruction, which resided at the end of one word-aligned word, and another to get the displacement byte, which resided at the start of the next word-aligned word.

One simple change brought the execution time down to a reasonable 12.5 cycles per loop:

```nasm
    mov   cx,1000
    call  ZTimerOn
    even
LoopTop:
    loop  LoopTop
    call  ZTimerOff
```

While word-aligning branch destinations can improve branching performance, it's a nuisance and can increase code size a good deal, so it's not worth doing in most code. Besides, `even`{.nasm} inserts a `nop`{.nasm} instruction if necessary, and the time required to execute a `nop`{.nasm} can sometimes cancel the performance advantage of having a word-aligned branch destination. Consequently, it's best to word-align only those branch destinations that can be reached solely by branching. I recommend that you only go out of your way to word-align the start offsets of your subroutines, as in:

```nasm
    even
FindChar  proc  near
          .
          .
```

In my experience, this simple practice is the one form of code alignment that consistently provides a reasonable return for bytes and effort expended, although sometimes it also pays to word-align tight time-critical loops.

### Alignment and the 80386

So far we've only discussed alignment as it pertains to the 80286. What, you may well ask, of the 80386?

The 80386 benefits most from *doubleword* alignment. Every memory access that crosses a doubleword boundary forces the 80386 to perform two memory accesses, effectively doubling memory access time, just as happens with memory accesses that cross word boundaries on the 80286.

The rule for the 80386 is: word-sized memory accesses should be word-aligned (it's impossible for word-aligned word-sized accesses to cross doubleword boundaries), and doubleword-sized memory accesses should be doubleword-aligned. However, in real (as opposed to protected) mode, doubleword-sized memory accesses are rare, so the simple word-alignment rule we've developed for the 80286 serves for the 80386 in real mode as well.

As for code alignment... the subroutine start word-alignment rule of the 80286 serves reasonably well there too, since it avoids the worst case, where just 1 byte is fetched on entry to a subroutine. While optimum performance would dictate doubleword alignment of subroutines, that takes 3 bytes, a high price to pay for an optimization that improves performance only on the 80386.

### Alignment and the Stack

One side-effect of the data alignment cycle-eater of the 80286 and 80386 is that you should *never* allow the stack pointer to become odd. (You can make the stack pointer odd by adding an odd value to it or subtracting an odd value from it, or by loading it with an odd value.) An odd stack pointer on the 80286 or 80386 will significantly reduce the performance of `push`{.nasm}, `pop`{.nasm}, `call`{.nasm}, and `ret`{.nasm}, as well as `int`{.nasm} and `iret`{.nasm}, which are executed to invoke DOS and BIOS functions, handle keystrokes and incoming serial characters, and manage the mouse. I know of a Forth programmer who vastly improved the performance of a complex application on the AT simply by forcing the Forth interpreter to maintain an even stack pointer at all times.

An interesting corollary to this rule is that you shouldn't `inc`{.nasm} SP twice to add 2, even though that's more efficient than using `add sp,2`{.nasm}. The stack pointer is odd between the first and second `inc`{.nasm}, so any interrupt occurring between the two instructions will be serviced more slowly than it normally would. The same goes for decrementing twice; use `sub sp,2`{.nasm} instead.

*Keep the stack pointer even at all times.*

### The Dram Refresh Cycle-Eater: Still an Act of God

The DRAM refresh cycle-eater is the cycle-eater that's least changed from its 8088 form on the 80286 and 80386. In the AT, DRAM refresh uses a little over 5% of all available memory accesses, slightly less than it uses in the PC, but in the same ballpark. While the DRAM refresh penalty varies somewhat on various AT clones and 80386 computers (in fact, a few computers are built around static RAM, which requires no refresh at all), the 5% figure is a good rule of thumb.

Basically, the effect of the DRAM refresh cycle-eater is pretty much the same throughout the PC-compatible world: fairly small, so it doesn't greatly affect performance; unavoidable, so there's no point in worrying about it anyway; and a nuisance, since it results in fractional cycle counts when using the Zen timer. Just as with the PC, a given code sequence on the AT can execute at varying speeds at different times, as a result of the interaction between the code and the DRAM refresh timing.

There's nothing much new with DRAM refresh on 80286/80386 computers, then. Be aware of it, but don't concern yourself overly — DRAM refresh is still an act of God, and there's not a blessed thing you can do about it.

### The Display Adapter Cycle-Eater

And finally we come to the last of the cycle-eaters, the display adapter cycle-eater. There are two ways of looking at this cycle-eater on 80286/80386 computers: 1) it's much worse than it was on the PC, or, 2) it's just about the same as it was on the PC.

Either way, the display adapter cycle-eater is extremely bad news on 80286/80386 computers.

The two ways of looking at the display adapter cycle-eater on 80286/80386 computers are actually the same. As you'll recall from Chapter 4, display adapters offer only a limited number of accesses to display memory during any given period of time. The 8088 is capable of making use of most but not all of those slots with `rep movsw`{.nasm}, so the number of memory accesses allowed by a display adapter such as an EGA is reasonably well matched to an 8088's memory access speed. Granted, access to an EGA slows the 8088 down considerably — but, as we're about to find out, "considerably" is a relative term. What an EGA does to PC performance is nothing compared to what it does to faster computers.

Under ideal conditions, an 80286 can access memory much, much faster than an 8088. A 10-MHz 80286 is capable of accessing a word of system memory every 0.20 us with `rep movsw`{.nasm}, dwarfing the 1 byte every 1.31 us that the 8088 in a PC can manage. However, access to display memory is anything but ideal for an 80286. For one thing, most display adapters are 8-bit devices. (While a few are 16-bit devices, they're the exception.) One consequence of that is that only 1 byte can be read or written per access to display memory; word-sized accesses to 8-bit devices are automatically split into 2 separate byte-sized accesses by the AT's bus. Another consequence is that accesses are simply slower; the AT's bus always inserts 3 wait states on accesses to 8-bit devices, since it must assume that such devices were designed for PCs and may not run reliably at AT speeds.

However, the 8-bit size of most display adapters is but one of the two factors that reduce the speed with which the 80286 can access display memory. Far more cycles are eaten by the inherent memory-access limitations of display adapters — that is, the limited number of display memory accesses that display adapters make available to the 80286. Look at it this way: if `rep movsw`{.nasm} on a PC can use more than half of all available accesses to display memory, then how much faster can code running on an 80286 or 80386 possibly run when accessing display memory?

That's right — less than twice as fast.

In other words, instructions that access display memory won't run a whole lot faster on ATs and faster computers than they do on PCs. That explains one of the two viewpoints expressed at the beginning of this section: the display adapter cycle-eater is just about the same on high-end computers as it is on the PC, in the sense that it allows instructions that access display memory to run at just about the same speed on all computers.

Of course, the picture is quite a bit different when you compare the performance of instructions that access display memory to the *maximum* performance of those instructions. Instructions that access display memory receive many more wait states when running on an 80286 than they do on an 8088. Why? While the 80286 is capable of accessing memory much more often than the 8088, we've seen that the frequency of access to display memory is determined not by processor speed but by the display adapter. As a result, both processors are actually allowed just about the same maximum number of accesses to display memory in any given time. By definition, then, the 80286 must spend many more cycles waiting than does the 8088.

And that explains the second viewpoint expressed above regarding the display adapter cycle-eater vis-a-vis the 80286 and 80386. The display adapter cycle-eater, as measured in cycles lost to wait states, is indeed much worse on AT-class computers than it is on the PC, and it's worse still on more powerful computers.

How bad is the display adapter cycle-eater on an AT? Back in Chapter 3, we measured the performance of `rep movsw`{.nasm} accessing system memory in a PC and display memory on an EGA installed in a PC. Access to EGA memory proved to be more than twice as slow as access to system memory; [Listing 3-1](#listing-3-1), which accessed EGA memory, ran in 26.06 ms, while [Listing 3-2](#listing-3-2), which accessed system memory, ran in 11.24 ms.

When the same two listings are run on an EGA-equipped 10-MHz AT clone, the results are startling. [Listing 3-2](#listing-3-2) accesses system memory in just 1.31 ms, more than eight times faster than on the PC. [Listing 3-1](#listing-3-1) accesses EGA memory in 16.12 ms — considerably less than twice as fast as on the PC, and well over ten times as slow as [Listing 3-1](#listing-3-1). *The display adapter cycle-eater can slow an AT* — *or even an 80386 computer* — *to near-PC speeds when display memory is accessed.*

I know that's hard to believe, but the display adapter cycle-eater gives out just so many display memory accesses in a given time, and no more, no matter how fast the processor is. In fact, the faster the processor, the more the display adapter cycle-eater hurts the performance of instructions that access display memory. The display adapter cycle-eater is not only still present in 80286/80386 computers, it's worse than ever.

What can we do about this new, more virulent form of the display adapter cycle-eater? The workaround is the same as it was on the PC:

*Access display memory as little as you possibly can.*

## New Instructions and Features

### New Instructions and Features: The 80286

The 80286 and 80386 offer a number of new instructions. The 80286 has a relatively small number of instructions that the 8088 lacks, while the 80386 has those instructions and quite a few more, along with new addressing modes and data sizes. We'll discuss the 80286 and the 80386 separately in this regard.

The 80286 has a number of instructions designed for protected-mode operations. As I've said, we're not going to discuss protected mode in *The Zen of Assembly Language*; in any case, protected-mode instructions are generally used only by operating systems. (I should mention that the 80286's protected mode brings with it the ability to address 16 Mb of memory, a considerable improvement over the 8088's 1 Mb. In real mode, however, programs are still limited to 1 Mb of addressable memory on the 80286. In either mode, each segment is still limited to 64 Kb.)

There are also a handful of 80286-specific real-mode instructions, and they can be quite useful. `bound`{.nasm} checks array bounds. `enter`{.nasm} and `leave`{.nasm} support compact and speedy stack frame construction and removal, ideal for interfacing to high-level languages such as C and Pascal. `ins`{.nasm} and `outs`{.nasm} are new string instructions that support efficient data transfer between memory and I/O ports. Finally, `pusha`{.nasm} and `popa`{.nasm} push and pop all eight general-purpose registers.

A couple of old instructions gain new features on the 80286. For one, the 80286 version of `push`{.nasm} is capable of pushing a constant on the stack. For another, the 80286 allows all shifts and rotates to be performed for not just 1 bit or the number of bits specified by CL, but for any constant number of bits.

These new instructions are fairly powerful, if not earthshaking. Nonetheless, it would be foolish to use them unless you're intentionally writing a program that will run only on the 80286 and 80386. That's because none of the 80286-specific instructions does anything you can't do reasonably well with some combination of 8088 instructions... and if you do use even one of the 80286-specific instructions, you've thrown 8088 compatibility out the window. In other words, you'll be sacrificing the ability to run on most of the computers in the PC-compatible market in return for a relatively minor improvement in performance and program size.

If you're programming in protected mode, or if you've already decided that you don't want your programs to run on 8088-based computers, sure, use the 80286-specific instructions. Otherwise, give them a wide berth.

### New Instructions and Features: The 80386

The 80386 is somewhat more complex than the 80286 as regards new features. Once again, we won't discuss protected mode, which on the 80386 comes with the ability to address up to 4 gigabytes per segment and 64 terabytes in all. In real mode (and in virtual-86 mode, which allows the 80386 to multitask MS-DOS applications, and which is identical to real mode so far as MS-DOS programs are concerned), programs running on the 80386 are still limited to 1 Mb of addressable memory and 64 Kb per segment.

The 80386 has many new instructions, as well as new registers, addressing modes and data sizes that have trickled down from protected mode. Let's take a quick look at these new real-mode features.

Even in real mode, it's possible to access many of the 80386's new and extended registers. Most of these registers are simply 32-bit extensions of the 16-bit registers of the 8088. For example, EAX is a 32-bit register containing AX as its lower 16 bits, EBX is a 32-bit register containing BX as its lower 16 bits, and so on. There are also two new segment registers, FS and GS.

The 80386 also comes with a slew of new real-mode instructions beyond those supported by the 8088 and 80286. These instructions can scan data on a bit-by-bit basis, set the Carry flag to the value of a specified bit, sign-extend or zero-extend data as it's moved, set a register or memory variable to 1 or 0 on the basis of any of the conditions that can be tested with conditional jumps, and more. What's more, both old and new instructions support 32-bit operations on the 80386. For example, it's relatively simple to copy data in chunks of 4 bytes on an 80386, even in real mode, by using the `movsd`{.nasm} ("move string double") instruction, or to negate a 32-bit value with `neg eax`{.nasm}. (That's a whole lot less complicated than our fancy 32-bit negation code of past chapters, eh?)

Finally, it's possible in real mode to use the 80386's new addressing modes, in which *any* 32-bit general-purpose register can be used to address memory. What's more, multiplication of memory-addressing registers by 2, 4, or 8 for look-ups in word, doubleword, or quadword tables can be built right into the memory addressing mode. In protected mode, these new addressing modes allow you to address a full 4 gigabytes per segment, but in real mode you're still limited to 64 Kb, even with 32-bit registers and the new addressing modes. Having shown you these wonders, I'm going to snatch them away. All these features are available only on the 80386; code using them won't even run on the 80286, let alone the 8088. If you're going to go to the trouble of using 80386-specific features, thereby eliminating any chance of running on PCs and ATs, you might as well go all the way and write 80386 protected-mode code. That way, you'll be able to take full advantage of the new addressing modes and larger segments, rather than working with the subset of 80386 features that's available in real mode.

And 80386 protected mode programming, my friend, is quite a different journey from the one we've been taking. While the 80386 in protected mode bears some resemblance to the 8088, the resemblance isn't all that strong. The protected-mode 80386 is a wonderful processor to program, and a good topic — a *terrific* topic — for some book to cover in detail... but this is not that book.

To sum up: stick to the 8088's instruction set, registers, and addressing modes, unless you're willing to sacrifice completely the ability to run on the bulk of PC-compatible computers. 80286-specific instructions don't have a big enough payback to compensate for the inability to run on 8088-based computers, while 80386-specific instructions limit your market so sharply that you might as well go to protected mode and get the full benefits of the 80386.

## Optimization Rules: The More Things Change...

Let's see what we've learned about 80286/80386 optimization. Mostly what we've learned is that our familiar PC cycle-eaters still apply, although in somewhat different forms, and that the major optimization rules for the PC hold true on ATs and 80386-based computers. You won't go wrong on high-end MS-DOS computers if you keep your instructions short, use the registers heavily and avoid memory, don't branch, and avoid accessing display memory like the plague.

Although we haven't touched on them, repeated string instructions are still desirable on the 80286 and 80386, since they provide a great deal of functionality per instruction byte and eliminate both the prefetch queue cycle-eater and branching. However, string instructions are not quite so spectacularly superior on the 80286 and 80386 as they are on the 8088, since non-string memory-accessing instructions have been speeded up considerably on the newer processors.

There's one cycle-eater with new implications on the 80286 and 80386, and that's the data alignment cycle-eater. From the data alignment cycle-eater we get a new rule: word-align your word-sized variables, and start your subroutines at even addresses. This rule doesn't hurt 8088 performance or compatibility, improves 80286 and 80386 performance considerably, is easy to implement, and costs relatively few bytes, so it's worth applying even though it doesn't improve the performance of 8088 code.

Basically, what we've found is that the broad optimization rules for the 8088, plus the word-alignment rule, cover the 80286 and 80386 quite nicely. What *that* means is that if you optimize for the 8088 and word-align word-sized memory accesses, you'll get solid performance on all PC-compatible computers. What's more, it means that if you're writing code specifically for the 80286 and/or 80386, you already have a good feel for optimizing that code.

In short, what you've already learned in *The Zen of Assembly Language* will serve you well across the entire PC family.

### Detailed Optimization

While the major 8088 optimization rules hold true on computers built around the 80286 and 80386, many of the instruction-specific optimizations we've learned no longer hold, for the execution times of most instructions are quite different on the 80286 and 80386 than on the 8088. We have already seen one such example of the sometimes vast difference between 8088 and 80286/80386 instruction execution times: `mov [WordVar],0`{.nasm}, which has an Execution Unit execution time of 20 cycles on the 8088, has an EU execution time of just 3 cycles on the 80286 and 2 cycles on the 80386.

In fact, the performance of virtually all memory-accessing instructions has been improved enormously on the 80286 and 80386. The key to this improvement is the near elimination of effective address (EA) calculation time. Where an 8088 takes from 5 to 12 cycles to calculate an EA, an 80286 or 80386 usually takes no time whatsoever to perform the calculation. If a base+index+displacement addressing mode, such as `mov ax,[WordArray+bx+si]`{.nasm}, is used on an 80286 or 80386, 1 cycle is taken to perform the EA calculation, but that's both the worst case and the only case in which there's any EA overhead at all.

The elimination of EA calculation time means that the EU execution time of memory-addressing instructions is much closer to the EU execution time of register-only instructions. For instance, on the 8088 `add [WordVar],100h`{.nasm} is a 31-cycle instruction, while `add dx,100h`{.nasm} is a 4-cycle instruction — a ratio of nearly 8 to 1. By contrast, on the 80286 `add [WordVar],100h`{.nasm} is a 7-cycle instruction, while `add dx,100h`{.nasm} is a 3-cycle instruction — a ratio of just 2.3 to 1.

It would seem, then, that it's less necessary to use the registers on the 80286 than it was on the 8088, but that's simply not the case, for reasons we've already seen. The key is this: the 80286 can execute memory-addressing instructions so fast that there's no spare instruction prefetching time during those instructions, so the prefetch queue runs dry, especially on the AT, with its one-wait-state memory. On the AT, the 6-byte instruction `add [WordVar],100h`{.nasm} is effectively at least a 15-cycle instruction, because 3 cycles are needed to fetch each of the three instruction words and 6 more cycles are needed to read `WordVar`{.nasm} and write the result back to memory.

Granted, the register-only instruction `add dx,100h`{.nasm} also slows down — to 6 cycles — because of instruction prefetching, leaving a ratio of 2.5 to 1. Now, however, let's look at the performance of the same code on an 8088. The register-only code would run in 16 cycles (4 instruction bytes at 4 cycles per byte), while the memory-accessing code would run in 40 cycles (6 instruction bytes at 4 cycles per byte, plus 2 word-sized memory accesses at 8 cycles per word). That's a ratio of 2.5 to 1, *exactly the same as on the 80286*.

This is all theoretical. We put our trust not in theory but in actual performance, so let's run this code through the Zen timer. On a PC, [Listing 15-4](#listing-15-4), which performs register-only addition, runs in 3.62 ms, while [Listing 15-5](#listing-15-5), which performs addition to a memory variable, runs in 10.05 ms. On a 10-MHz AT clone, [Listing 15-4](#listing-15-4) runs in 0.64 ms, while [Listing 15-5](#listing-15-5) runs in 1.80 ms. Obviously, the AT is much faster... but the ratio of [Listing 15-5](#listing-15-5) to [Listing 15-4](#listing-15-4) is virtually identical on both computers, at 2.78 for the PC and 2.81 for the AT. If anything, the register-only form of `add`{.nasm} has a slightly *larger* advantage on the AT than it does on the PC in this case.

Theory confirmed.

What's going on? Simply this: instruction fetching is controlling overall execution time on *both* processors. Both the 8088 in a PC and the 80286 in an AT can execute the bytes of the instructions in [Listings 15-4](#listing-15-4) and [15-5](#listing-15-5) faster than they can be fetched. Since the instructions are exactly the same lengths on both processors, it stands to reason that the ratio of the overall execution times of the instructions should be the same on both processors as well. Instruction length controls execution time, and the instruction lengths are the same — therefore the ratios of the execution times are the same. The 80286 can both fetch and execute instruction bytes faster than the 8088 can, so code executes much faster on the 80286; nonetheless, because the 80286 can also execute those instruction bytes much faster than it can fetch them, overall performance is still largely determined by the size of the instructions.

Is this always the case? No. When the prefetch queue is full, memory-accessing instruction on the 80286 and 80386 are much faster relative to register-only instructions than they are on the 8088. Given the system wait states prevalent on 80286 and 80386 computers, however, the prefetch queue is likely to be empty quite a bit, especially when code consisting of instructions with short Execution Unit execution times is executed. Of course, that's just the sort of code we're likely to write when we're optimizing, so the performance of high-speed code is more likely to be controlled by instruction size than by EU execution time on most 80286 and 80386 computers, just as it is on the PC.

All of which is just a way of saying that faster memory access and EA calculation notwithstanding, it's just as desirable to keep instructions short and memory accesses to a minimum on the 80286 as it is on the 8088. And we know full well that the way to do that is to use the registers as heavily as possible, use string instructions, use short forms of instructions, and the like.

The more things change, the more they remain the same...

### Don't Sweat the Details

We've just seen how a major difference between the 80286 and 8088 — the virtual elimination of effective address calculation time — leaves the major optimization rules pretty much unchanged. While there are many details about 80286 and 80386 code performance that differ greatly from the 8088 (for example, the 80386's barrel shifter allows you to shift or rotate a value *any* number of bits in just 3 cycles, and `mul`{.nasm} and `div`{.nasm} are much, much faster on the newer processors), those details aren't worth worrying about unless you're abandoning the 8088 entirely. Even then, the many variations in memory architecture and performance between various 80286 and 80386 computers make it impractical to focus too closely on detailed 80286/80386 optimizations.

In short, there's little point in even considering 80286/80386 optimizations when you're writing code that will also run on the 8088. If the 8088 isn't one of the target processors for a particular piece of code, you can use Intel's publications, which list cycle times for both real and protected mode, and the Zen timer to optimize for the 80286 and/or 80386. (You will probably have to modify the Zen timer before you can run it under a protected-mode operating system; it was designed for use under MS-DOS in real mode and has only been tested in that mode. Some operating systems provide built-in high-precision timing services that could be used in place of the Zen timer.)

Always bear in mind, however, that your optimization control is not so fine on 80286/80386 computers as it is on the PC, unless you can be sure that your code will run only on a particular processor (either 80286 or 80386, but not both) with a single, well-understood memory architecture. As 80286 and 80386 machines of various designs proliferate, that condition becomes increasingly difficult to fulfill.

On balance, my final word on 80286/80386 real-mode optimization in this: *with the sole exception of word-aligning your word-sized variables and subroutines, optimize only for the 8088*. You'll get the best possible performance on the slowest computer — the PC — and excellent performance across the entire spectrum of PC-compatible computers.

When you get right down to it, isn't that everything you could ask for from a real-mode program?

## `popf` and the 80286

We've one final 80286-related item to discuss: the hardware malfunction of `popf`{.nasm} under certain circumstances on the 80286.

The problem is this: sometimes `popf`{.nasm} permits interrupts to occur when interrupts are initially off and the setting popped into the Interrupt flag from the stack keeps interrupts off. In other words, an interrupt can happen even though the Interrupt flag is never set to 1. (For further details, see "Chips in Transition," *PC Tech Journal*, April, 1986.)

Now, I don't want to blow this particular bug out of proportion. It only causes problems in code that cannot tolerate interrupts under any circumstances, and that's a rare sort of code, especially in user programs. However, some code really does need to have interrupts absolutely disabled, with no chance of an interrupt sneaking through. For example, a critical portion of a disk BIOS might need to retrieve data from the disk controller the instant it becomes available; even a few hundred microseconds of delay could result in a sector's worth of data misread. In this case, one misplaced interrupt during a `popf`{.nasm} could result in a trashed hard disk if that interrupt occurs while the disk BIOS is reading a sector of the File Allocation Table.

There is a workaround for the `popf`{.nasm} bug. While the workaround is easy to use, it's considerably slower than `popf`{.nasm}, and costs a few bytes as well, so you won't want to use it in code that can tolerate interrupts. On the other hand, in code that truly cannot be interrupted, you should view those extra cycles and bytes as cheap insurance against mysterious and erratic program crashes.

One obvious reason to discuss the `popf`{.nasm} workaround is that it's useful. Another reason is that the workaround is an excellent example of the Zen of assembler, in that there's a well-defined goal to be achieved but no obvious way to do so. The goal is to reproduce the functionality of the `popf`{.nasm} instruction without using `popf`{.nasm}, and the place to start is by asking exactly what `popf`{.nasm} does.

All `popf`{.nasm} does is pop the word on top of the stack into the FLAGS register, as shown in Figure 15.4.

![](images/fig15.4RT.png)

How can we do that without `popf`{.nasm}? Of course, the 80286's designers intended us to use `popf`{.nasm} for this purpose, and didn't intentionally provide any alternative approach, so we'll have to devise an alternative approach of our own. To do that, we'll have to search for instructions that contain some of the same functionality as `popf`{.nasm}, in the hope that one of those instructions can be used in some way to replace `popf`{.nasm}.

Well, there's only one instruction other than `popf`{.nasm} that loads the FLAGS register directly from the stack, and that's `iret`{.nasm}, which loads the FLAGS register from the stack as it branches, as shown in Figure 15.5.

![](images/fig15.5RT.png)

`iret`{.nasm} has no known bugs of the sort that plagues `popf`{.nasm}, so it's certainly a candidate to replace `popf`{.nasm} in non-interruptible applications. Unfortunately, `iret`{.nasm} loads the FLAGS register with the *third* word down on the stack, not the word on top of the stack, as is the case with `popf`{.nasm}; the far return address that `iret`{.nasm} pops into CS:IP lies between the top of the stack and the word popped into the FLAGS register.

Obviously, the segment:offset that `iret`{.nasm} expects to find on the stack above the pushed flags isn't present when the stack is set up for `popf`{.nasm}, so we'll have to adjust the stack a bit before we can substitute `iret`{.nasm} for `popf`{.nasm}. What we'll have to do is push the segment:offset of the instruction after our workaround code onto the stack right above the pushed flags. `iret`{.nasm} will then branch to that address and pop the flags, ending up at the instruction after the workaround code with the flags popped. That's just the result that would have occurred had we executed `popf`{.nasm} — with the bonus that no interrupts can accidentally occur when the Interrupt flag is 0 both before and after the pop.

How can we push the segment:offset of the next instruction? Well, think back to our discussion in the last chapter of finding the offset of the next instruction by performing a near call to that instruction. We can do something similar here, but in this case we need a far call, since `iret`{.nasm} requires both a segment and an offset. We'll also branch backward so that the address pushed on the stack will point to the instruction we want to continue with. The code works out like this:

```nasm
    jmp   short popfskip
popfiret:
    iret                    ;branches to the instruction after the
                            ; call, popping the word below the address
                            ; pushed by CALL into the FLAGS register
popfskip:
    call  far ptr popfiret
                            ;pushes the segment:offset of the next
                            ; instruction on the stack just above
                            ; the flags word, setting things up so
                            ; that IRET will branch to the next
                            ; instruction and pop the flags
; When execution reaches the instruction following this comment,
; the word that was on top of the stack when JMP SHORT POPFSKIP
; was reached has been popped into the FLAGS register, just as
; if a POPF instruction had been executed.
```

The operation of this code is illustrated in Figure 15.6.

![](images/fig15.6RT.png)

The `popf`{.nasm} workaround can best be implemented as a macro; we can also emulate a far call by pushing CS and performing a near call, thereby shrinking the workaround code by 1 byte:

```nasm
EMULATE_POPF  macro
    local popfskip, popfiret
    jmp   short popfskip
popfiret:
    iret
popfskip:
    push  cs
    call  popfiret
    endm
```

(By the way, the flags can be popped much more quickly if you're willing to alter a register in the process. For example, the following macro emulates `popf`{.nasm} with just one branch, but wipes out AX:

```nasm
EMULATE_POPF_TRASH_AX   macro
    push  cs
    mov   ax,offset $+5
    push  ax
    iret
    endm
```

It's not a perfect substitute for `popf`{.nasm}, since `popf`{.nasm} doesn't alter any registers, but it's faster and shorter than `EMULATE_POPF`{.nasm} when you can spare the register. If you're using 286-specific instructions, you can use:

```nasm
    .286
          :
EMULATE_POPF  macro
    push  cs
    push  offset $+4
    iret
    endm
```

which is shorter still, alters no registers, and branches just once. (Of course, this version of `EMULATE_POPF`{.nasm} won't work on an 8088.)

The standard version of `EMULATE_POPF`{.nasm} is 6 bytes longer than `popf`{.nasm} and much slower, as you'd expect given that it involves three branches. Anyone in their right mind would prefer `popf`{.nasm} to a larger, slower, three-branch macro — given a choice. In non-interruptible code, however, there's no choice; the safer — if slower — approach is the best. (Having people associate your programs with crashed computers is *not* a desirable situation, no matter how unfair the circumstances under which it occurs.)

Anyway, the overall inferiority of `EMULATE_POPF`{.nasm} is almost never an issue, because `EMULATE_POPF`{.nasm} is unlikely to be used either often or in situations where performance matters. `popf`{.nasm} is neither a frequently-used instruction nor an instruction that's often used in time-critical code; as we found in Chapter 8, `lahf`{.nasm}/`sahf`{.nasm} is superior to `pushf`{.nasm}/`popf`{.nasm} for most applications. Besides, all this only matters when the flags need to be popped in non-interruptible code, a situation that rarely arises.

And now you know the nature of and the workaround for the `popf`{.nasm} bug. Whether you ever need the workaround or not, it's a neatly packaged example of the tremendous flexibility of the 8088's instruction set... and of the value of the Zen of assembler.

## Coprocessors and Peripherals

Up to this point, we've concentrated on the various processors in the 8088 family. There are also a number of coprocessors in use in the PC world, and they can affect the performance of some programs every bit as much as processors can. Unfortunately, while processors are standard equipment (I should hope every computer comes with one!) not a single coprocessor is standard. Every PC-compatible computer can execute the 8088 instruction `mov al,1`{.nasm}, but the same cannot be said of the 8087 numeric coprocessor instruction `fld [MemVar]`{.nasm}, to say nothing of instructions for the coprocessors on a variety of graphics, sound, and other adapters available for the PC. Then, too, there are many PC peripherals that offer considerable functionality without being true coprocessors — VGAs and serial adapters, to name just two — but not a one of those is standard either.

Coprocessors and peripherals are just about as complex as processors, and require similarly detailed explanations of programming techniques. However, because of the lack of standards, you'll only want to learn about a given coprocessor or peripheral if it affects your work. By contrast, you had no choice but to learn about the 8088, since it affects everything you do on a PC.

If you're interested in programming a particular coprocessor or peripheral, you can always find a book, an article, or at least a data sheet that addresses that interest. You may not find the quality or quantity of reference material you'd like, especially for the more esoteric coprocessors, but there is surely enough information available to get you started; otherwise no one else would be able to program that coprocessor or peripheral either. (Remember, as an advanced assembler programmer, you're now among the programming elite. There just aren't very many people who understand as much about microcomputer programming as you do. That may be a strange thought, but roll it around in your head for a while — I suspect you'll get to like it.)

Once you've gotten started with a given coprocessor or adapter, you can put the Zen approach to work in a new context. Gain a thorough understanding of the resources and capabilities the new environment has to offer, and learn to think in terms of matching those capabilities to your applications.

### A Brief Note on the 8087

The 8087, 80287 and 80387 are the most common and important PC coprocessors. These numeric coprocessors improve the performance of floating-point arithmetic far beyond the speeds possible with an 8088 alone, performing operations such as floating-point addition, subtraction, multiplication, division, absolute value, comparison, and square root. The 80287 is similar to the 8087, but with protected mode support; the 80387 adds some new functions, including sine and cosine. (For the remainder of this section I'll use the term "8087" to cover all 8087-family numeric coprocessors.)

While the 8087 is widely used, and is frequently used by high-level language programs, it is rarely programmed directly in assembler. This is true partly because floating-point arithmetic is relatively slow, even with an 8087, so the cycle savings achievable via assembler are relatively small as a percentage of overall execution time. Also, 8087 instructions are so specialized that they generally offer less rich optimization opportunities than do 8088 instructions.

Given the specialized nature of 8087 assembler programming, and given that 8087 programming is largely a separate topic from 8088 programming (although the processors do have their common points, such as addressing modes), I'm not going to tackle the 8087 in this book. I will offer one general tip, however:

*Keep your arithmetic variables in the 8087's data registers as much as you possibly can.* (There are eight 80-bit data registers, organized as an internal stack.) "Keep it in the registers" is a rule we've become familiar with on the 8088, and it will stand us in equally good stead on the 8087.

Why? Well, the 8087 works with an internal 10-byte format, rather than the 2-, 4-, and 8-byte integer and floating-point formats we're familiar with. Whenever an 8087 instruction loads data from or stores data to a memory variable that's in a 2-, 4-, or 8-byte format, the 8087 must convert the data format accordingly... and it takes the 8087 dozens of cycles to perform those conversions. Even apart from the conversion time, it takes a number of cycles just to copy 2 to 10 bytes to or from memory.

For example, it takes the 8087 between 51 and 97 cycles (including effective address calculation time and the 4-cycle-per-word 8-bit bus penalty) just to push a floating-point value from memory onto the 8087's data register stack. By contrast, it takes just 17 to 22 cycles to push a value from an internal register onto the data register stack. Ideally, the value you need will have been left on top of the 8087 register stack as the result of the last operation, in which case no load time at all is required.

Intensive use of the 8087's data registers is one area in which assembler code can substantially outperform high-level language code. High-level languages tend to use the 8087 for only one operation — or, at most, one high-level language statement — at a time, loading the data registers from scratch for each operation. Most high-level languages load the operands for each operation into the 8087's data registers, perform the operation, and store the result back to memory... then start the whole process over again for the next operation, even if the two operations are related.

What you can do in assembler, of course, is use the 8087's data registers much as you've learned to use the 8088's general-purpose registers: load often-used values into the data registers, keep results around if you'll need them later, and keep intermediate results in the data registers rather than storing them to memory. Also, remember that you often have the option of either popping or not popping source operands from the top of the stack, and that data registers other than ST(0) can often serve as destination operands.

In short, the 8087 has both a generous set of data registers and considerable flexibility in how those registers can be used. Take full advantage of those resources when you write 8087 code.

Before we go, one final item about the 8087. The 8087 is a true coprocessor, fully capable of executing instructions in parallel with the 8088. In other words, the 8088 can continue fetching and executing instructions while the 8087 is processing one of its lengthy instructions. While that makes for excellent performance, problems can arise if a second 8087 instruction is fetched and started before the first 8087 instruction has finished. To avoid such problems, MASM automatically inserts a `wait`{.nasm} instruction before each 8087 instruction. `wait`{.nasm} simply tells the 8088 to wait until the 8087 has finished its current instruction before continuing. In short, MASM neatly and invisibly avoids one sort of potential 8087 synchronization problem.

There's a second sort of potential 8087 synchronization problem, however, and this one you must guard against, for it isn't taken care of by MASM: instructions accessing memory out of sequence. The 8088 is fully capable of executing new instructions while a lengthy 8087 instruction that precedes those 8088 instructions executes. One of those later 8088 instructions can, for example, easily read a memory location before the 8087 instruction writes to it. In other words, given an 8087 instruction that accesses a memory variable, it's possible for an 8088 instruction that follows that 8087 instruction to access that memory variable *before* the 8087 instruction does.

Clearly, serious problems can arise if instructions access memory out of sequence. To avoid such problems, you should explicitly place a `wait`{.nasm} instruction between any 8087 instruction that accesses a memory variable and any following 8088 instructions that could possibly access that same variable.

That doesn't by any stretch of the imagination mean that you should put `wait`{.nasm} after all of your 8087 instructions. On the contrary, the rule is that you should use `wait`{.nasm} only when there's the potential for out-of-sequence 8087 and 8088 memory accesses, and then only immediately before the instructions during which the conflict might arise. The rest of the time, you can boost performance by omitting `wait`{.nasm} and letting the 8088 and 8087 coprocess.

### Conclusion

Despite all the other processors, coprocessors, and peripherals in the PC family, the 8088 is still the best place to focus your optimization efforts. If your code runs well on an 8088, it will run well on every 8086-family processor well into the twenty-first century, and even on a number of computers built around other processors as well. Good performance and the largest possible market — what more could you want?

That's enough of being practical. No one programs extensively in assembler just because it's useful; also required is a certain fondness for the sorts of puzzles assembler programming presents. For that sort of programmer, there's nothing better than the weird but wonderful 8088. Admit it — strange as 8088 assembler programming is...

...isn't it *fun*?
