# Chapter 1: Zen?

What is the Zen of assembler? Many things: a set of programming skills that lets you write incredibly fast programs, a technique for turning ideas into code, a process of looking at problems in new ways and finding fresh solutions, and more. Perhaps a brief story would be the best way to introduce the Zen of assembler.

## 1.1 The Zen of Assembler in a Nutshell

Some time ago, I was asked to work over a critical assembler subroutine in order to make it run as fast as possible. The task of the subroutine was to construct a nibble out of four bits read from different bytes, rotating and combining the bits so that they ultimately ended up neatly aligned in bits 3-0 of a single byte. (In case you're curious, the object was to construct a 16-color pixel from bits scattered over 4 bytes.) I examined the subroutine line by line, saving a cycle here and a cycle there, until the code truly seemed to be optimized. When I was done, the key part of the code looked something like this:

```nasm
LoopTop:
  lodsb          ;get the next byte to extract a bit from
  and    al,ah   ;isolate the bit we want
  rol    al,cl   ;rotate the bit into the desired position
  or     bl,al   ;insert the bit into the final nibble
  dec    cx      ;the next bit goes 1 place to the right
  dec    dx      ;count down the number of bits
  jnz    LoopTop ;process the next bit, if any
```

Now, it's hard to write code that's much faster than seven assembler instructions, only one of which accesses memory, and most programmers would have called it a day at this point; still, something bothered me, so I spent a bit of time going over the code again. Suddenly, the answer struck me — the code was rotating each bit into place separately, so that a multi-bit rotation was being performed every time through the loop, for a total of four separate time-consuming multi-bit rotations! *While the instructions themselves were individually optimized, the overall approach did not make the best possible use of the instructions.*

I changed the code to the following:

```nasm
LoopTop:
  lodsb          ;get the next byte to extract a bit from
  and    al,ah   ;isolate the bit we want
  or     bl,al   ;insert the bit into the final nibble
  rol    bl,1    ;make room for the next bit
  dec    dx      ;count down the number of bits
  jnz    LoopTop ;process the next bit, if any
  rol    bl,cl   ;rotate all four bits into their final
                 ; positions at the same time
```

This moved the costly multi-bit rotation out of the loop, so that it was performed just once, rather than four times. While the new code may not look much different from the original, and in fact still contains exactly the same number of instructions, the performance of the entire subroutine improved by about 10% from just this one change. (Incidentally, that wasn't the end of the optimization; I eliminated the `dec` and `jnz` instructions by expanding the four iterations of the loop into in-line code — but that's a tale for another chapter.)

The point is this: to write truly superior assembler programs, you need to know what the various instructions do and which instructions execute fastest...and more. You must also learn to look at your programming problems from a variety of perspectives, so that you can put those fast instructions to work in the most effective ways. And, that, in a nutshell, is the Zen of assembler.

## 1.2 Assembler is Fundamentally Different from Other Languages

Is it really so hard as all that to write good assembler code for the IBM PC? Yes! Thanks to the decidedly quirky nature of the 8088 processor, assembly language differs fundamentally from other languages, and is undeniably harder to work with. On the other hand, the potential of assembler code is much greater than that of other languages, as well. The Zen of assembler is the way to tap that potential.

To understand why this is, consider how a program gets written. A programmer examines the requirements of an application, designs a solution at some level of abstraction, and then makes that design come alive in a code implementation. If not handled properly, the transformation that takes place between conception and implementation can reduce performance tremendously; for example, a programmer who implements a routine to search a list of 100,000 sorted items with a linear rather than binary search will end up with a disappointingly slow program.

No matter how well an implementation is derived from the corresponding design, however, high-level languages like C and Pascal inevitably introduce additional transformation inefficiencies, as shown in Figure 1.1.

![](images/fig1.1RT.png)

High-level languages provide artificial environments that lend themselves relatively well to human programming skills, in order to ease the transition from design to implementation. The price for this ease of implementation is a considerable loss of efficiency in transforming source code into machine language. This is particularly true given that the 8088, with its specialized memory-addressing instructions and segmented memory architecture, does not lend itself particularly well to compiler design.

Assembler, on the other hand, is simply a human-oriented representation of machine language. As a result, assembler provides a difficult programming environment — the bare hardware and systems software of the computer — *but properly constructed assembler programs suffer no transformation loss*, as shown in Figure 1.2.

![](images/fig1.2RT.png)

The key, of course, is the programmer, since in assembler the programmer must essentially perform the transformation from the application specification to machine language entirely on his own. (The assembler merely handles the direct translation from assembler to machine language.)

The first part of the Zen of assembler, then, is self-reliance. An assembler is nothing more than a tool to let you design machine-language programs without having to think in hexadecimal codes, so assembly-language programmers — unlike all other programmers — must take full responsibility for the quality of their code. Since assemblers provide little help at any level higher than the generation of machine language, the assembler programmer must be capable both of coding any programming construct directly and of controlling the PC at the lowest practical level — the operating system, the BIOS, the hardware where necessary. High-level languages handle most of this transparently to the programmer, but in assembler everything is fair — and necessary — game, which brings us to another aspect of the Zen of assembler.

Knowledge.

## 1.3 Knowledge

In the IBM PC world, you can never have enough knowledge, and every item you add to your store will make your programs better. Thorough familiarity with both the operating system and BIOS interfaces is important; since those interfaces are well-documented and reasonably straightforward, my advice is to get IBM's documentation and a good book or two and bring yourself up to speed. Similarly, familiarity with the hardware of the IBM PC is required. While that topic covers a lot of ground — display adapters, keyboards, serial ports, printer ports, timer and DMA channels, memory organization, and more — most of the hardware is well-documented, and articles about programming major hardware components appear frequently, so this sort of knowledge can be acquired readily enough.

The single most critical aspect of the hardware, and the one about which it is hardest to learn, is the 8088 processor. The 8088 has a complex, irregular instruction set, and, unlike most processors, the 8088 is neither straightforward nor well-documented as regards true code performance. What's more, assembler is so difficult to learn that most articles and books which present assembler code settle for code that works, rather than code that pushes the 8088 to its limits. In fact, since most articles and books are written for inexperienced assembler programmers, there is very little information of any sort available about how to generate high-quality assembler code for the 8088. As a result, knowledge about programming the 8088 effectively is by far the hardest knowledge to gather. A good portion of this book is devoted to seeking out such knowledge. Be forewarned, though: no matter how much you learn about programming the IBM PC in assembler, there's always more to discover.

## 1.4 The Flexible Mind

Is the never-ending collection of information all there is to the Zen of assembler, then? Hardly. Knowledge is simply a necessary base on which to build. Let's take a moment to examine the objectives of good assembler programming, and the remainder of the Zen of assembler will fall into place.

Basically, there are only two possible objectives to high-performance assembler programming: given the requirements of the application, keep to a minimum either the number of processor cycles the program takes to run or the number of bytes in the program, or some combination of both. We'll look at ways to achieve both objectives, but we'll more often be concerned with saving cycles than saving bytes, for the PC offers relatively more memory than it does processing horsepower. In fact, we'll find that 2-to-3 times performance improvements *over tight assembler code* are often possible if we're willing to expend additional bytes in order to save cycles. It's not always desirable to use such techniques to speed up code, due to the heavy memory requirements — but it is almost always possible.

You will notice that my short list of objectives for high-performance assembler programming does not include traditional objectives such as easy maintenance and speed of development. Those are indeed important considerations — to persons and companies that develop and distribute software. People who actually *buy* software, on the other hand, care only about how well that software performs, not how it was developed. Nowadays, developers spend so much time focusing on such admittedly important issues as code maintainability and reusability, source code control, choice of development environment, and the like that they forget rule #1: from the user's perspective, performance is fundamental. Comment your code, design it carefully, and write non-time-critical portions in a high-level language, if you wish — but when you write the portions that interact with the user and/or affect response time, performance must be your paramount objective, and assembler is the path to that goal.

Knowledge of the sort described earlier is absolutely essential to fulfilling either of the objectives of assembler programming. What that knowledge doesn't by itself do is meet the need to write code that both performs to the requirements of the application at hand and operates in the PC environment as efficiently as possible. Knowledge makes that possible, but your programming instincts make it happen. And it is that intuitive, on-the-fly integration of a program specification and a sea of facts about the PC that is the heart of the Zen of assembler.

As with Zen of any sort, mastering the Zen of assembler is more a matter of learning than of being taught. You will have to find your own path of learning, although I will start you on your way with this book. The subtle facts and examples I provide will help you gain the necessary experience, but you must continue the journey on your own. Each program you create will expand your programming horizons and increase the options available to you in meeting the next challenge. The ability of your mind to find surprising new and better ways to craft superior code from a concept — the flexible mind, if you will — is the linchpin of good assembler code, and you will develop this skill only by doing.

Never underestimate the importance of the flexible mind. Good assembler code is better than good compiled code. Many people would have you believe otherwise, but they're wrong. That doesn't mean high-level languages are useless; far from it. High-level languages are the best choice for the majority of programmers, and for the bulk of the code of most applications. When the *best* code — the fastest or smallest code possible — is needed, though, assembler is the only way to go.

Simple logic dictates that no compiler can know as much about what a piece of code needs to do or adapt as well to those needs as the person who wrote the code. Given that superior information and adaptability, an assembly-language programmer can generate better code than a compiler, all the more so given that compilers are constrained by the limitations of high-level languages and by the process of transformation from high-level to machine language. Consequently, carefully optimized assembler is not just the language of choice but the *only* choice for the 1% to 10% of all code — usually consisting of small, well-defined subroutines — that determines overall program performance, and is the only choice for code that must be as compact as possible, as well. In the run-of-the-mill, non-time-critical portions of your programs, it makes no sense to waste time and effort on writing optimized assembler code — concentrate your efforts on loops and the like instead — but in those areas where you need the finest code quality, accept no substitutes.

Note that I said that an assembler programmer *can* generate better code than a compiler, not *will* generate better code. While it is true that good assembler code is better than good compiled code, it is also true that bad assembler code is often much worse than bad compiled code; since the assembler programmer has so much control over the program, he or she has unlimited opportunity to waste cycles and bytes. The sword cuts both ways, and good assembler code requires more, not less, forethought and planning than good code written in a high-level language.

The gist of all this is simply that good assembler programming is done in the context of a solid overall framework unique to each program, and the flexible mind is the key to creating that framework and holding it together.

## 1.5 Where to Begin?

To summarize, the Zen of assembler is a combination of knowledge, perspective, and way of thought that makes possible the genesis of first-rate assembler programs. Given that, where to begin our explorations of the Zen of assembler? Development of the flexible mind is an obvious step. Still, the flexible mind is no better than the knowledge at its disposal. We have much knowledge to acquire before we can begin to discuss the flexible mind, and in truth we don't even know yet how to acquire knowledge about 8088 assembler, let alone what that knowledge might be. The first step in the journey toward the Zen of assembler, then, would seem to be learning how to learn.
