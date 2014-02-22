# Chapter 16: Onward to the Flexible Mind

And so we come to the end of our journey through knowledge. More precisely, we've come to the end of that part of *The Zen of Assembly Language* that's dedicated to knowledge, for no matter how long you or I continue to program the 8088, there will always be more to learn about this surprising processor.

If The Zen of assembler were merely a matter of instructions and cycle times, I would spend a few pages marvelling at the wonders we've seen, then congratulate you on arriving at a mastery of assembler and bid you farewell. I won't do that, though, for in truth we've merely arrived at a resting place from whence our journey will continue anew in Volume II of *The Zen of Assembly Language*. There are marvels aplenty to come, so we'll just catch our breath, take a brief look back to see how far we've come...and then it's on to the flexible mind.

The flexible mind notwithstanding, congratulations are clearly in order *right now*. You've mastered a great deal — in fact, you've absorbed just about as much knowledge about assembler as any mortal could in so short a time. You've undoubtedly learned much more than you realize just yet; only with experience will everything you've seen in this volume sink in fully.

As important as the amount you've learned is the nature of your knowledge. We haven't just thrown together a collection of unrelated facts in this volume; we've divined the fundamental nature and basic optimization rules of the PC. We've explored the architectures of the PC and the 8088, and we've seen how those underlying factors greatly influence the performance of all assembler code — and, by extension, the performance of all code that runs on the PC. We've learned which members of the instruction set are best suited to various tasks, we've come across unexpected talents in many instructions, and we've learned to view instructions in light of what they *can* do, not what they were designed to do. Best of all, we've learned to use the Zen timer to check our assumptions and to help us continue to learn and hone our skills.

What all this amounts to is a truly excellent understanding of instruction performance on the PC. That's important — critically important — but it's not the whole picture. The knowledge we've acquired is merely the foundation for the flexible mind, which enables us to transform task specifications into superior assembler code. In turn, application implementations — whole programs — are built upon the flexible mind. So, while we've built a strong foundation, we've a ways yet to go in completing our mastery of the Zen of assembler.

The flexible mind and implementation are what Volume II of *The Zen of Assembly Language* is all about. Volume II develops the concept of the flexible mind from the bottom up, starting at the level of implementing the most efficient code for a small, well-defined task, continuing on through algorithm implementation, and extending to designing custom assembler-based mini-languages tailored to various applications. We'll learn how to search and sort data quickly, how to squeeze every cycle out of a line-drawing routine, how to let data replace code (with tremendous program-size benefits), and how to do animation. The emphasis every step of the way will be on outperforming standard techniques by using our new knowledge in innovative ways to create the best possible 8088 code for each task.

Finally, we'll put everything we've learned together by designing and implementing an animation application. The PC isn't renowned as a game machine (to put it mildly!), but by the time we're through, I promise you won't be able to tell the difference between the graphics on your PC and those in an arcade. The key, of course, is the flexible mind, the ability to bring together the needs of the application and the capabilities of the PC -with often-spectacular results.

So, while we've gone a mighty long way toward mastering the Zen of assembler, we haven't arrived yet. That's all to the good, though. Until now, interesting as our explorations have been, we've basically been doing grunt work — learning cycle times and the like. What's coming up next is the *really* fun stuff — taking what we've learned and using that knowledge to create the wondrous tasks and applications that are possible only with the very best assembler code.

In short, in Volume II we'll experience the full spectrum of the Zen of assembler, from the details that we now know so well to the magnificent applications that make it all worthwhile.

## 16.1 A Taste of What You've Learned

Before we leave Volume I, I'd like to give you a taste of both what's to come and what you already know. Why do you need to see what you already know? The answer is that you've surely learned much more than you realize right now. The example we'll look at involves strong elements of the flexible mind, and what we'll find is that there's no neat dividing line between knowledge and the flexible mind...and that we have already ventured much farther across the fuzzy boundary between the two than you'd ever imagine.

We'll also see that the flexible mind involves knowledge and intuition — but no deep dark mysteries. Knowledge you have in profusion, and, as you'll see, your intuition is growing by leaps and bounds. (Try to stay one step ahead of me as we optimize the following routine. I suspect you'll be surprised at how easy it is.) I'm presenting this last example precisely because I'd like you to see how well you already understand the flexible mind.

On to our final example...

## 16.2 Zenning

In Jeff Duntemann's excellent book *Complete Turbo Pascal, Third Edition* (published by Scott, Foresman and Company), there's a small assembler subroutine that's designed to be called from a Turbo Pascal program in order to fill the screen or a system-memory screen buffer with a specified character/attribute pair in text mode. This subroutine involves only 21 instructions and works perfectly well; nonetheless, with what we know we can compact the subroutine tremendously, and speed it up a bit as well. To coin a verb, we can "Zen" this already-tight assembler code to an astonishing degree. In the process, I hope you'll get a feel for how advanced your assembler skills have become.

The code is as follows (the code is Jeff's, with many letters converted to lowercase in order to match the style of *Zen of Assembly Language*, but the comments are mine):

```nasm
OnStack   struc       ;data that's stored on the stack after PUSH BP
OldBP     dw      ?   ;caller's BP
RetAddr   dw      ?   ;return address
Filler    dw      ?   ;character to fill the buffer with
Attrib    dw      ?   ;attribute to fill the buffer with
BufSize   dw      ?   ;number of character/attribute pairs to fill
BufOfs    dw      ?   ;buffer offset
BufSeg    dw      ?   ;buffer segment
EndMrk    db      ?   ;marker for the end of the stack frame
OnStack   ends
;
ClearS    proc    near
    push  bp                        ;save caller's BP
    mov   bp,sp                     ;point to stack frame
    cmp   word ptr [bp].BufSeg,0    ;skip the fill if a null
    jne   Start                     ; pointer is passed
    cmp   word ptr [bp].BufOfs,0
    je    Bye
Start: cld                          ;make STOSW count up
    mov   ax,[bp].Attrib            ;load AX with attribute parameter
    and   ax,0ff00h                 ;prepare for merging with fill char
    mov   bx,[bp].Filler            ;load BX with fill char
    and   bx,0ffh                   ;prepare for merging with attribute
    or    ax,bx                     ;combine attribute and fill char
    mov   bx,[bp].BufOfs            ;load DI with target buffer offset
    mov   di,bx
    mov   bx,[bp].BufSeg            ;load ES with target buffer segment
    mov   es,bx
    mov   cx,[bp].BufSize           ;load CX with buffer size
    rep   stosw                     ;fill the buffer
Bye: mov  sp,bp                     ;restore original stack pointer
    pop   bp                        ; and caller's BP
    ret   EndMrk-RetAddr-2          ;return, clearing the parms from the stack
ClearS    endp
```

The first thing you'll notice about the above code is that `ClearS` uses a `rep stosw` instruction. That means that we're not going to improve performance by any great amount, no matter how clever we are. While we can eliminate some cycles, the bulk of the work in `ClearS` is done by that one repeated string instruction, and there's no way to improve on that.

Does that mean that the above code is as good as it can be? Hardly. While the speed of `ClearS` is very good, there's another side to the optimization equation: size. The whole of `ClearS` is 52 bytes long as it stands — but, as we'll see, that size is hardly graven in stone.

Where do we begin with `ClearS`? For starters, there's an instruction in there that serves no earthly purpose — `mov sp,bp`. SP is guaranteed to be equal to BP at that point anyway, so why reload it with the same value? Removing that instruction saves us 2 bytes.

Well, that was certainly easy enough! We're not going to find any more totally non-functional instructions in `ClearS`, however, so let's get on to some serious optimizing. We'll look first for cases where we know of better instructions for particular tasks than those that were chosen. For example, there's no need to load any register, whether segment or general-purpose, through BX; we can eliminate two instructions by simply loading ES and DI directly:

```nasm
ClearS    proc  near
    push  bp                      ;save caller's BP
    mov   bp,sp                   ;point to stack frame
    cmp   word ptr [bp].BufSeg,0  ;skip the fill if a null
    jne   Start                   ; pointer is passed
    cmp   word ptr [bp].BufOfs,0
    je    Bye
Start: cld                        ;make STOSW count up
    mov   ax,[bp].Attrib          ;load AX with attribute parameter
    and   ax,0ff00h               ;prepare for merging with fill char
    mov   bx,[bp].Filler          ;load BX with fill char
    and   bx,0ffh                 ;prepare for merging with attribute
    or    ax,bx                   ;combine attribute and fill char
    mov   di,[bp].BufOfs          ;load DI with target buffer offset
    mov   es,[bp].BufSeg          ;load ES with target buffer segment
    mov   cx,[bp].BufSize         ;load CX with buffer size
    rep   stosw                   ;fill the buffer
Bye:
    pop   bp                      ;restore caller's BP
    ret   EndMrk-RetAddr-2        ;return, clearing the parms from the stack
ClearS    endp
```

(The `OnStack` structure definition doesn't change in any of our examples, so I'm not going clutter up this chapter by reproducing it for each new version of `ClearS`.)

Okay, loading ES and DI directly saves another 4 bytes. We've squeezed a total of 6 bytes — about 11% — out of `ClearS`. What next?

Well, `les` would serve better than two `mov` instructions for loading ES and DI:

```nasm
ClearS    proc  near
    push  bp                        ;save caller's BP
    mov   bp,sp                     ;point to stack frame
    cmp   word ptr [bp].BufSeg,0    ;skip the fill if a null
    jne   Start                     ; pointer is passed
    cmp   word ptr [bp].BufOfs,0
    je    Bye
Start: cld                          ;make STOSW count up
    mov   ax,[bp].Attrib            ;load AX with attribute parameter
    and   ax,0ff00h                 ;prepare for merging with fill char
    mov   bx,[bp].Filler            ;load BX with fill char
    and   bx,0ffh                   ;prepare for merging with attribute
    or    ax,bx                     ;combine attribute and fill char
    les   di,dword ptr [bp].BufOfs  ;load ES:DI with target buffer segment:offset
    mov   cx,[bp].BufSize           ;load CX with buffer size
    rep   stosw                     ;fill the buffer
Bye:
    pop   bp                        ;restore caller's BP
    ret   EndMrk-RetAddr-2          ;return, clearing the parms from the stack
ClearS    endp
```

That's good for another 3 bytes. We're down to 43 bytes, and counting.

We can save 3 more bytes by clearing the low and high bytes of AX and BX, respectively, by using `sub reg8,reg8` rather than anding 16-bit values:

```nasm
ClearS    proc  near
    push  bp                        ;save caller's BP
    mov   bp,sp                     ;point to stack frame
    cmp   word ptr [bp].BufSeg,0    ;skip the fill if a null
    jne   Start                     ; pointer is passed
    cmp   word ptr [bp].BufOfs,0
    je    Bye
Start: cld                          ;make STOSW count up
    mov   ax,[bp].Attrib            ;load AX with attribute parameter
    sub   al,al                     ;prepare for merging with fill char
    mov   bx,[bp].Filler            ;load BX with fill char
    sub   bh,bh                     ;prepare for merging with attribute
    or    ax,bx                     ;combine attribute and fill char
    les   di,dword ptr [bp].BufOfs  ;load ES:DI with target buffer segment:offset
    mov   cx,[bp].BufSize           ;load CX with buffer size
    rep   stosw                     ;fill the buffer
Bye:
    pop   bp                        ;restore caller's BP
    ret   EndMrk-RetAddr-2          ;return, clearing the parms from the stack
ClearS    endp
```

Now we're down to 40 bytes — more than 20% smaller than the original code. That's pretty much it for simple instruction-substitution optimizations. Now let's look for instruction-rearrangement optimizations.

It seems strange to load a word value into AX and then throw away AL. Likewise, it seems strange to load a word value into BX and then throw away BH. However, those steps are necessary because the two modified word values are ored into a single character/attribute word value that is then used to fill the target buffer.

Let's step back and see what this code really *does*, though. All it does in the end is load 1 byte addressed relative to BP into AH and another byte addressed relative to BP into AL. Heck, we can just do that directly! Presto — we've saved another 6 bytes, and turned two word-sized memory accesses into byte-sized memory accesses as well:

```nasm
ClearS    proc  near
    push  bp                          ;save caller's BP
    mov   bp,sp                       ;point to stack frame
    cmp   word ptr [bp].BufSeg,0      ;skip the fill if a null
    jne   Start                       ; pointer is passed
    cmp   word ptr [bp].BufOfs,0
    je Bye
Start: cld ;make STOSW count up
    mov   ah,byte ptr [bp].Attrib[1]  ;load AH with attribute
    mov   al,byte ptr [bp].Filler     ;load AL with fill char
    les   di,dword ptr [bp].BufOfs    ;load ES:DI with target buffer segment:offset
    mov   cx,[bp].BufSize             ;load CX with buffer size
    rep   stosw                       ;fill the buffer
Bye:
    pop   bp                          ;restore caller's BP
    ret   EndMrk-RetAddr-2            ;return, clearing the parms from the stack
ClearS    endp
```

(We could get rid of yet another instruction by having the calling code pack both the attribute and the fill value into the same word, but that's not part of the specification for this particular routine.)

Another nifty instruction-rearrangement trick saves 6 more bytes. `ClearS` checks to see whether the far pointer is null (zero) at the start of the routine...then loads and uses that same far pointer later on. Let's get that pointer into memory and keep it there; that way we can check to see whether it's null with a single comparison, and can use it later without having to reload it from memory:

```nasm
ClearS    proc  near
    push  bp                        ;save caller's BP
    mov   bp,sp                     ;point to stack frame
    les   di,dword ptr [bp].BufOfs  ;load ES:DI with target buffer segment:offset
    mov   ax,es                     ;put segment where we can test it
    or    ax,di                     ;is it a null pointer?
    je    Bye                       ;yes, so we're done
Start: cld                          ;make STOSW count up
    mov ah,byte ptr [bp].Attrib[1]  ;load AH with attribute
    mov al,byte ptr [bp].Filler     ;load AL with fill char
    mov cx,[bp].BufSize             ;load CX with buffer size
    rep stosw                       ;fill the buffer
Bye:
    pop   bp                        ;restore caller's BP
    ret   EndMrk-RetAddr-2          ;return, clearing the parms from the stack
ClearS    endp
```

Well. Now we're down to 28 bytes, having reduced the size of this subroutine by nearly 50%. Only 13 instructions remain. Realistically, how much smaller can we make this code?

About one-third smaller yet, as it turns out — but in order to do that, we must stretch our minds and use the 8088's instructions in unusual ways. Let me ask you this: what do most of the instructions in the current version of `ClearS` do?

Answer: they either load parameters from the stack frame or set up the registers so that the parameters can be accessed. Mind you, there's nothing wrong with the stack-frame-oriented instructions used in `ClearS`; those instructions access the stack frame in a highly efficient way, exactly as the designers of the 8088 intended, and just as the code generated by a high-level language would. That means that we aren't going to be able to improve the code if we don't bend the rules a bit.

Let's think...the parameters are sitting on the stack, and most of our instruction bytes are being used to read bytes off the stack with BP-based addressing...we need a more efficient way to address the stack...*the stack*...THE STACK!

Ye gods! That's easy — we can use the *stack pointer* to address the stack. While it's true that the stack pointer can't be used for *mod-reg-rm* addressing, as BP can, it *can* be used to pop data off the stack — and `pop` is a 1-byte instruction. Instructions don't get any shorter than that.

There is one detail to be taken care of before we can put our plan into action: the return address — the address of the calling code — is on top of the stack, so the parameters we want can't be reached with `pop`. That's easily solved, however — we'll just pop the return address into an unused register, then branch through that register when we're done, as we learned to do in Chapter 14. As we pop the parameters, we'll also be removing them from the stack, thereby neatly avoiding the need to discard them when it's time to return.

With that problem dealt with, here's the Zenned version of `ClearS`:

```nasm
ClearS    proc  near
    pop   dx      ;get the return address
    pop   ax      ;put fill char into AL
    pop   bx      ;get the attribute
    mov   ah,bh   ;put attribute into AH
    pop   cx      ;get the buffer size
    pop   di      ;get the offset of the buffer origin
    pop   es      ;get the segment of the buffer origin
    mov   bx,es   ;put the segment where we can test it
    or    bx,di   ;null pointer?
    je    Bye     ;yes, so we're done
    cld           ;make STOSW count up
    rep   stosw   ;do the string store
Bye:
    jmp   dx      ;return to the calling code
ClearS    endp
```

At long last, we're down to the bare metal. This version of `ClearS` is just 19 bytes long. That's just 37% as long as the original version, *without any change whatsoever in the functionality``ClearS``makes available to the calling code*. The code is bound to run a bit faster too, given that there are far fewer instruction bytes and fewer memory accesses.

All in all, the Zenned version of `ClearS` is a vast improvement over the original. Probably not the best possible implementation — *never say never!* — but an awfully good one.

## 16.3 Knowledge and Beyond

There is a point to all this Zenning above and beyond showing off some neat tricks we've learned (and a trick or two we'll learn more about in Volume II). The real point is to illustrate the breadth of knowledge you now possess, and the tremendous power that knowledge has when guided by the flexible mind.

Consider the optimizations we made to `ClearS` above. Our initial optimizations resulted purely from knowing particular facts about the 8088, and nothing more. We knew, for example, that segment registers do not have to be loaded from memory by way of general-purpose registers but can instead be loaded directly, so we made that change.

As optimizations became harder to come by, however, we shifted from applying pure knowledge to coming up with creative solutions that involved understanding and reworking the code as a whole. We started out by compacting individual instructions and bits of code, but in the end we came up with a solution that applied our knowledge of the PC to implementing the functionality of the entire subroutine as efficiently as possible.

And that, simply put, is the flexible mind.

Think back. Did you have any trouble following the optimizations to `ClearS`? I very much doubt it; in fact, I would guess that you were ahead of me much of the way. So, you see, you already have a good feel for the flexible mind.

There will be much more of the flexible mind in Volume II of *The Zen of Assembly Language*, but it won't be an abrupt change from what we've been doing; rather, it will be a gradual raising of our focus from learning the nuts and bolts of the PC to building applications with those nuts and bolts. We've trekked through knowledge and beyond; now it's time to seek out ways to bring the magic of the Zen of assembler to the real world of applications.

I hope you'll join me for the journey.
