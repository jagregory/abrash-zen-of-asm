# Expanded Listings

## Listing 2-1

```nasm
;
; *** Listing 2-1 ***
;
; The precision Zen timer (PZTIMER.ASM)
;
; Uses the 8253 timer to time the performance of code that takes
; less than about 54 milliseconds to execute, with a resolution
; of better than 10 microseconds.
;
; By Michael Abrash 4/26/89
;
; Externally callable routines:
;
;   ZTimerOn: Starts the Zen timer, with interrupts disabled.
;
;   ZTimerOff: Stops the Zen timer, saves the timer count,
;     times the overhead code, and restores interrupts to the
;     state they were in when ZTimerOn was called.
;
;   ZTimerReport: Prints the net time that passed between starting
;     and stopping the timer.
;
; Note: If longer than about 54 ms passes between ZTimerOn and
;       ZTimerOff calls, the timer turns over and the count is
;       inaccurate. When this happens, an error message is displayed
;       instead of a count. The long-period Zen timer should be used
;       in such cases.
;
; Note: Interrupts *MUST* be left off between calls to ZTimerOn
;       and ZTimerOff for accurate timing and for detection of
;       timer overflow.
;
; Note: These routines can introduce slight inaccuracies into the
;       system clock count for each code section timed even if
;       timer 0 doesn't overflow. If timer 0 does overflow, the
;       system clock can become slow by virtually any amount of
;       time, since the system clock can't advance while the
;       precison timer is timing. Consequently, it's a good idea
;       to reboot at the end of each timing session. (The
;       battery-backed clock, if any, is not affected by the Zen
;       timer.)
;
; All registers, and all flags except the interrupt flag, are
; preserved by all routines. Interrupts are enabled and then disabled
; by ZTimerOn, and are restored by ZTimerOff to the state they were
; in when ZTimerOn was called.
;

Code    segment word public 'CODE'
        assume  cs:Code, ds:nothing
        public ZTimerOn, ZTimerOff, ZTimerReport

;
; Base address of the 8253 timer chip.
;
BASE_8253       equ     40h
;
; The address of the timer 0 count registers in the 8253.
;
TIMER_0_8253    equ     BASE_8253 + 0
;
; The address of the mode register in the 8253.
;
MODE_8253       equ     BASE_8253 + 3
;
; The address of Operation Command Word 3 in the 8259 Programmable
; Interrupt Controller (PIC) (write only, and writable only when
; bit 4 of the byte written to this address is 0 and bit 3 is 1).
;
OCW3            equ     20h
;
; The address of the Interrupt Request register in the 8259 PIC
; (read only, and readable only when bit 1 of OCW3 = 1 and bit 0
; of OCW3 = 0).
;
IRR             equ     20h
;
; Macro to emulate a POPF instruction in order to fix the bug in some
; 80286 chips which allows interrupts to occur during a POPF even when
; interrupts remain disabled.
;
MPOPF macro
    local   p1, p2
    jmp short p2
p1: iret                ;jump to pushed address & pop flags
p2: push    cs          ;construct far return address to
    call    p1          ; the next instruction
    endm

;
; Macro to delay briefly to ensure that enough time has elapsed
; between successive I/O accesses so that the device being accessed
; can respond to both accesses even on a very fast PC.
;
DELAY       macro
    jmp     $+2
    jmp     $+2
    jmp     $+2
    endm

OriginalFlags   db  ?   ;storage for upper byte of
                        ; FLAGS register when
                        ; ZTimerOn called
TimedCount      dw  ?   ;timer 0 count when the timer
                        ; is stopped
ReferenceCount  dw  ?   ;number of counts required to
                        ; execute timer overhead code
OverflowFlag    db  ?   ;used to indicate whether the
                        ; timer overflowed during the
                        ; timing interval
;
; String printed to report results.
;
OutputStr   label   byte
            db      0dh, 0ah, 'Timed count: ', 5 dup (?)
ASCIICountEnd   label   byte
            db ' microseconds', 0dh, 0ah
            db '$'
;
; String printed to report timer overflow.
;
OverflowStr label   byte
        db 0dh, 0ah
        db '***************************************************'
        db 0dh, 0ah
        db '* The timer overflowed, so the interval timed was *'
        db 0dh, 0ah
        db '* too long for the precision timer to measure.    *'
        db 0dh, 0ah
        db '* Please perform the timing test again with the   *'
        db 0dh, 0ah
        db '* long-period timer.                              *'
        db 0dh, 0ah
        db '***************************************************'
        db 0dh, 0ah
        db '$'

;***********************************
;* Routine called to start timing. *
;***********************************

ZTimerOn    proc    near

;
; Save the context of the program being timed.
;
    push    ax
    pushf
    pop     ax                      ;get flags so we can keep
                                    ; interrupts off when leaving
                                    ; this routine
    mov     cs:[OriginalFlags],ah   ;remember the state of the
                                    ; Interrupt flag
    and     ah,0fdh                 ;set pushed interrupt flag
                                    ; to 0
    push    ax
;
; Turn on interrupts, so the timer interrupt can occur if it's
; pending.
;
    sti
;
; Set timer 0 of the 8253 to mode 2 (divide-by-N), to cause
; linear counting rather than count-by-two counting. Also
; leaves the 8253 waiting for the initial timer 0 count to
; be loaded.
;
    mov     al,00110100b            ;mode 2
    out     MODE_8253,al
;
; Set the timer count to 0, so we know we won't get another
; timer interrupt right away.
; Note: this introduces an inaccuracy of up to 54 ms in the system
; clock count each time it is executed.
;
    DELAY
    sub     al,al
    out     TIMER_0_8253,al         ;lsb
    DELAY
    out     TIMER_0_8253,al         ;msb
;
; Wait before clearing interrupts to allow the interrupt generated
; when switching from mode 3 to mode 2 to be recognized. The delay
; must be at least 210 ns long to allow time for that interrupt to
; occur. Here, 10 jumps are used for the delay to ensure that the
; delay time will be more than long enough even on a very fast PC.
;
    rept    10
    jmp     $+2
    endm
;
; Disable interrupts to get an accurate count.
;
    cli
;
; Set the timer count to 0 again to start the timing interval.
;
    mov     al,00110100b            ;set up to load initial
    out     MODE_8253,al            ; timer count
    DELAY
    sub     al,al
    out     TIMER_0_8253,al         ;load count lsb
    DELAY
    out     TIMER_0_8253,al         ;load count msb
;
; Restore the context and return.
;
    MPOPF                           ;keeps interrupts off
    pop     ax
    ret

ZTimerOn    endp

;************************************************
;* Routine called to stop timing and get count. *
;************************************************

ZTimerOff proc  near

;
; Save the context of the program being timed.
;
    push    ax
    push    cx
    pushf
;
; Latch the count.
;
    mov     al,00000000b            ;latch timer 0
    out     MODE_8253,al
;
; See if the timer has overflowed by checking the 8259 for a pending
; timer interrupt.
;
    mov     al,00001010b            ;OCW3, set up to read
    out     OCW3,al                 ; Interrupt Request register
    DELAY
    in      al,IRR                  ;read Interrupt Request
                                    ; register
    and     al,1                    ;set AL to 1 if IRQ0 (the
                                    ; timer interrupt) is pending
    mov     cs:[OverflowFlag],al    ;store the timer overflow
                                    ; status
;
; Allow interrupts to happen again.
;
    sti
;
; Read out the count we latched earlier.
;
    in      al,TIMER_0_8253         ;least significant byte
    DELAY
    mov     ah,al
    in      al,TIMER_0_8253         ;most significant byte
    xchg    ah,al
    neg     ax                      ;convert from countdown
                                    ; remaining to elapsed
                                    ; count
    mov     cs:[TimedCount],ax
; Time a zero-length code fragment, to get a reference for how
; much overhead this routine has. Time it 16 times and average it,
; for accuracy, rounding the result.
;
    mov     cs:[ReferenceCount],0
    mov     cx,16
    cli                             ;interrupts off to allow a
                                    ; precise reference count
RefLoop:
    call    ReferenceZTimerOn
    call    ReferenceZTimerOff
    loop    RefLoop
    sti
    add     cs:[ReferenceCount],8   ;total + (0.5 * 16)
    mov     cl,4
    shr     cs:[ReferenceCount],cl  ;(total) / 16 + 0.5
;
; Restore originaLinterrupt state.
;
    pop     ax                      ;retrieve flags when called
    mov     ch,cs:[OriginalFlags]   ;get back the original upper
                                    ; byte of the FLAGS register
    and     ch,not 0fdh             ;only care about original
                                    ; interrupt flag...
    and     ah,0fdh                 ;...keep all other flags in
                                    ; their current condition
    or      ah,ch                   ;make flags word with original
                                    ; interrupt flag
    push    ax                      ;prepare flags to be popped
;
; Restore the context of the program being timed and return to it.
;
    MPOPF                           ;restore the flags with the
                                    ; originaLinterrupt state
    pop     cx
    pop     ax
    ret

ZTimerOff endp

;
; Called by ZTimerOff to start timer for overhead measurements.
;

ReferenceZTimerOn proc  near
;
; Save the context of the program being timed.
;
    push    ax
    pushf                       ;interrupts are already off
;
; Set timer 0 of the 8253 to mode 2 (divide-by-N), to cause
; linear counting rather than count-by-two counting.
;
    mov     al,00110100b        ;set up to load
    out     MODE_8253,al        ; initial timer count
    DELAY
;
; Set the timer count to 0.
;
    sub     al,al
    out     TIMER_0_8253,al     ;load count lsb
    DELAY
    out     TIMER_0_8253,al     ;load count msb
;
; Restore the context of the program being timed and return to it.
;
    MPOPF
    pop     ax
    ret

ReferenceZTimerOn endp

;
; Called by ZTimerOff to stop timer and add result to ReferenceCount
; for overhead measurements.
;

ReferenceZTimerOff proc     near
;
; Save the context of the program being timed.
;
    push    ax
    push    cx
    pushf
;
; Latch the count and read it.
;
    mov     al,00000000b            ;latch timer 0
    out     MODE_8253,al
    DELAY
    in      al,TIMER_0_8253         ;lsb
    DELAY
    mov     ah,al
    in      al,TIMER_0_8253         ;msb
    xchg    ah,al
    neg     ax                      ;convert from countdown
                                    ; remaining to amount
                                    ; counted down
    add     cs:[ReferenceCount],ax
;
; Restore the context of the program being timed and return to it.
;
    MPOPF
    pop     cx
    pop     ax
    ret

ReferenceZTimerOff endp

;********************************************
;* Routine called to report timing results. *
;********************************************

ZTimerReport proc   near

    pushf
    push    ax
    push    bx
    push    cx
    push    dx
    push    si
    push    ds
;
    push    cs          ;DOS functions require that DS point
    pop     ds          ; to text to be displayed on the screen
    assume  ds:Code
;
; Check for timer 0 overflow.
;
    cmp     [OverflowFlag],0
    jz      PrintGoodCount
    mov     dx,offset OverflowStr
    mov     ah,9
    int     21h
    jmp     short EndZTimerReport
;
; Convert net count to decimal ASCII in microseconds.
;
PrintGoodCount:
    mov     ax,[TimedCount]
    sub     ax,[ReferenceCount]
    mov     si,offset ASCIICountEnd -1
;
; Convert count to microseconds by multiplying by .8381.
;
    mov     dx,8381
    mul     dx
    mov     bx,10000
    div     bx          ;* .8381 = * 8381 / 10000
;
; Convert time in microseconds to 5 decimal ASCII digits.
;
    mov     bx,10
    mov     cx,5
CTSLoop:
    sub     dx,dx
    div     bx
    add     dl,'0'
    mov     [si],dl
    dec     si
    loop    CTSLoop
;
; Print the results.
;
    mov     ah,9
    mov     dx,offset OutputStr
    int     21h
;
EndZTimerReport:
    pop     ds
    pop     si
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    MPOPF
    ret

ZTimerReport    endp

Code    ends
        end
```

## Listing 2-2

```nasm
;
; *** Listing 2-2 ***
;
; Program to measure performance of code that takes less than
; 54 ms to execute. (PZTEST.ASM)
;
; Link with PZTIMER.ASM (Listing 2-1). PZTEST.BAT (Listing 2-4)
; can be used to assemble and link both files. Code to be
; measured must be in the file TESTCODE; Listing 2-3 shows
; a sample TESTCODE file.
;
; By Michael Abrash 4/26/89
;
mystack     segment     para stack 'STACK'
        db  512 dup(?)
mystack     ends
;
Code    segment     para public 'CODE'
        assume      cs:Code, ds:Code
        extrn   ZTimerOn:near, ZTimerOff:near, ZTimerReport:near
Start   proc    near
        push    cs
        pop     ds          ;set DS to point to the code segment,
                            ; so data as well as code can easily
                            ; be included in TESTCODE
;
        include TESTCODE    ;code to be measured, including
; calls to ZTimerOn and ZTimerOff
;
; Display the results.
;
        call    ZTimerReport
;
; Terminate the program.
;
        mov     ah,4ch
        int     21h
Start   endp
Code    ends
        end     Start
```

## Listing 2-3

```nasm
;
; *** Listing 2-3 ***
;
; Measures the performance of 1000 loads of AL from
; memory. (Use by renaming to TESTCODE, which is
; included by PZTEST.ASM (Listing 2-2). PZTIME.BAT
; (Listing 2-4) does this, along with all assembly
; and linking.)
;
    jmp     Skip ;jump around defined data
;
MemVar  db  ?
;
Skip:
;
; Start timing.
;
    call    ZTimerOn
;
    rept    1000
    mov     al,[MemVar]
    endm
;
; Stop timing.
;
    call    ZTimerOff
```

## Listing 2-4

```bat
echo off
rem
rem *** Listing 2-4 ***
rem
rem ***************************************************************
rem * Batch file PZTIME.BAT, which builds and runs the precision  *
rem * Zen timer program PZTEST.EXE to time the code named as the  *
rem * command-line parameter. Listing 2-1 must be named           *
rem * PZTIMER.ASM, and Listing 2-2 must be named PZTEST.ASM. To   *
rem * time the code in LST2-3, you'd type the DOS command:        *
rem *                                                             *
rem * pztime lst2-3                                               *
rem *                                                             *
rem * Note that MASM and LINK must be in the current directory or *
rem * on the current path in order for this batch file to work.   *
rem *                                                             *
rem * This batch file can be speeded up by assembling PZTIMER.ASM *
rem * once, then removing the lines:                              *
rem *                                                             *
rem * masm pztimer;                                               *
rem * if errorlevel 1 goto errorend                               *
rem *                                                             *
rem * from this file.                                             *
rem *                                                             *
rem * By Michael Abrash 4/26/89                                   *
rem ***************************************************************
rem
rem Make sure a file to test was specified.
rem
if not x%1==x goto ckexist
echo ***************************************************************
echo * Please specify a file to test.                              *
echo ***************************************************************
goto end
rem
rem Make sure the file exists.
rem
:ckexist
if exist %1 goto docopy
echo ***************************************************************
echo * The specified file, "%1," doesn't exist.
echo ***************************************************************
goto end
rem
rem copy the file to measure to TESTCODE.
rem
:docopy
copy %1 testcode
masm pztest;
if errorlevel 1 goto errorend
masm pztimer;
if errorlevel 1 goto errorend
link pztest+pztimer;
if errorlevel 1 goto errorend
pztest
goto end
:errorend
echo ***************************************************************
echo * An error occurred while building the precision Zen timer.   *
echo ***************************************************************
:end
```

## Listing 2-5

```nasm
;
; *** Listing 2-5 ***
;
; The long-period Zen timer. (LZTIMER.ASM)
; Uses the 8253 timer and the BIOS time-of-day count to time the
; performance of code that takes less than an hour to execute.
; Because interrupts are left on (in order to allow the timer
; interrupt to be recognized), this is less accurate than the
; precision Zen timer, so it is best used only to time code that takes
; more than about 54 milliseconds to execute (code that the precision
; Zen timer reports overflow on). Resolution is limited by the
; occurrence of timer interrupts.
;
; By Michael Abrash 4/26/89
;
; Externally callable routines:
;
;   ZTimerOn: Saves the BIOS time of day count and starts the
;       long-period Zen timer.
;
;   ZTimerOff: Stops the long-period Zen timer and saves the timer
;       count and the BIOS time-of-day count.
;
;   ZTimerReport: Prints the time that passed between starting and
;       stopping the timer.
;
; Note: If either more than an hour passes or midnight falls between
;       calls to ZTimerOn and ZTimerOff, an error is reported. For
;       timing code that takes more than a few minutes to execute,
;       either the DOS TIME command in a batch file before and after
;       execution of the code to time or the use of the DOS
;       time-of-day function in place of the long-period Zen timer is
;       more than adequate.
;
; Note: The PS/2 version is assembled by setting the symbol PS2 to 1.
;       PS2 must be set to 1 on PS/2 computers because the PS/2's
;       timers are not compatible with an undocumented timer-stopping
;       feature of the 8253; the alternative timing approach that
;       must be used on PS/2 computers leaves a short window
;       during which the timer 0 count and the BIOS timer count may
;       not be synchronized. You should also set the PS2 symbol to
;       1 if you're getting erratic or obviously incorrect results.
;
; Note: When PS2 is 0, the code relies on an undocumented 8253
;       feature to get more reliable readings. It is possible that
;       the 8253 (or whatever chip is emulating the 8253) may be put
;       into an undefined or incorrect state when this feature is
;       used.
;
; ***************************************************************
; * If your computer displays any hint of erratic behavior      *
; * after the long-period Zen timer is used, such as the floppy *
; * drive failing to operate properly, reboot the system, set   *
; * PS2 to 1 and leave it that way!                             *
; ***************************************************************
;
; Note: Each block of code being timed should ideally be run several
;       times, with at least two similar readings required to
;       establish a true measurement, in order to eliminate any
;       variability caused by interrupts.
;
; Note: Interrupts must not be disabled for more than 54 ms at a
;       stretch during the timing interval. Because interrupts
;       are enabled, keys, mice, and other devices that generate
;       interrupts should not be used during the timing interval.
;
; Note: Any extra code running off the timer interrupt (such as
;       some memory-resident utilities) wilLincrease the time
;       measured by the Zen timer.
;
; Note: These routines can introduce inaccuracies of up to a few
;       tenths of a second into the system clock count for each
;       code section timed. Consequently, it's a good idea to
;       reboot at the conclusion of timing sessions. (The
;       battery-backed clock, if any, is not affected by the Zen
;       timer.)
;
; All registers and all flags are preserved by all routines.
;

Code    segment word    public 'CODE'
        assume          cs:Code, ds:nothing
        public ZTimerOn, ZTimerOff, ZTimerReport

;
; Set PS2 to 0 to assemble for use on a fully 8253-compatible
; system; when PS2 is 0, the readings are more reliable if the
; computer supports the undocumented timer-stopping feature,
; but may be badly off if that feature is not supported. In
; fact, timer-stopping may interfere with your computer's
; overall operation by putting the 8253 into an undefined or
; incorrect state. Use with caution!!!
;
; Set PS2 to 1 to assemble for use on non-8253-compatible
; systems, including PS/2 computers; when PS2 is 1, readings
; may occasionally be off by 54 ms, but the code will work
; properly on all systems.
;
; A setting of 1 is safer and will work on more systems,
; while a setting of 0 produces more reliable results in systems
; which support the undocumented timer-stopping feature of the
; 8253. The choice is yours.
;
PS2             equ     1
;
; Base address of the 8253 timer chip.
;
BASE_8253       equ     40h
;
; The address of the timer 0 count registers in the 8253.
;
TIMER_0_8253    equ     BASE_8253 + 0
;
; The address of the mode register in the 8253.
;
MODE_8253       equ     BASE_8253 + 3
;
; The address of the BIOS timer count variable in the BIOS
; data segment.
;
TIMER_COUNT     equ     46ch
;
; Macro to emulate a POPF instruction in order to fix the bug in some
; 80286 chips which allows interrupts to occur during a POPF even when
; interrupts remain disabled.
;
MPOPF macro
    local   p1, p2
    jmp     short p2
p1: iret                ;jump to pushed address & pop flags
p2: push    cs          ;construct far return address to
    call    p1          ; the next instruction
    endm

;
; Macro to delay briefly to ensure that enough time has elapsed
; between successive I/O accesses so that the device being accessed
; can respond to both accesses even on a very fast PC.
;
DELAY macro
    jmp     $+2
    jmp     $+2
    jmp     $+2
    endm

StartBIOSCountLow   dw  ?   ;BIOS count low word at the
                            ; start of the timing period
StartBIOSCountHigh  dw  ?   ;BIOS count high word at the
                            ; start of the timing period
EndBIOSCountLow     dw  ?   ;BIOS count low word at the
                            ; end of the timing period
EndBIOSCountHigh    dw  ?   ;BIOS count high word at the
                            ; end of the timing period
EndTimedCount       dw  ?   ;timer 0 count at the end of
                            ; the timing period
ReferenceCount      dw  ?   ;number of counts required to
                            ; execute timer overhead code
;
; String printed to report results.
;
OutputStr   label   byte
            db      0dh, 0ah, 'Timed count: '
TimedCountStr       db  10 dup (?)
            db      ' microseconds', 0dh, 0ah
            db      '$'
;
; Temporary storage for timed count as it's divided down by powers
; of ten when converting from doubleword binary to ASCII.
;
CurrentCountLow     dw  ?
CurrentCountHigh    dw  ?
;
; Powers of ten table used to perform division by 10 when doing
; doubleword conversion from binary to ASCII.
;
PowersOfTen     label   word
    dd  1
    dd  10
    dd  100
    dd  1000
    dd  10000
    dd  100000
    dd  1000000
    dd  10000000
    dd  100000000
    dd  1000000000
PowersOfTenEnd  label   word
;
; String printed to report that the high word of the BIOS count
; changed while timing (an hour elapsed or midnight was crossed),
; and so the count is invalid and the test needs to be rerun.
;
TurnOverStr     label   byte
    db  0dh, 0ah
    db  '****************************************************'
    db  0dh, 0ah
    db  '* Either midnight passed or an hour or more passed *'
    db  0dh, 0ah
    db  '* while timing was in progress. If the former was  *'
    db  0dh, 0ah
    db  '* the case, please rerun the test; if the latter   *'
    db  0dh, 0ah
    db  '* was the case, the test code takes too long to    *'
    db  0dh, 0ah
    db  '* run to be timed by the long-period Zen timer.    *'
    db  0dh, 0ah
    db  '* Suggestions: use the DOS TIME command, the DOS   *'
    db  0dh, 0ah
    db  '* time function, or a watch.                       *'
    db  0dh, 0ah
    db  '****************************************************'
    db  0dh, 0ah
    db  '$'

;********************************************************************
;* Routine called to start timing.                                  *
;********************************************************************

ZTimerOn    proc    near

;
; Save the context of the program being timed.
;
    push    ax
    pushf
;
; Set timer 0 of the 8253 to mode 2 (divide-by-N), to cause
; linear counting rather than count-by-two counting. Also stops
; timer 0 until the timer count is loaded, except on PS/2
; computers.
;
    mov     al,00110100b        ;mode 2
    out     MODE_8253,al
;
; Set the timer count to 0, so we know we won't get another
; timer interrupt right away.
; Note: this introduces an inaccuracy of up to 54 ms in the system
; clock count each time it is executed.
;
    DELAY
    sub     al,al
    out     TIMER_0_8253,al     ;lsb
    DELAY
    out     TIMER_0_8253,al     ;msb
;
; In case interrupts are disabled, enable interrupts briefly to allow
; the interrupt generated when switching from mode 3 to mode 2 to be
; recognized. Interrupts must be enabled for at least 210 ns to allow
; time for that interrupt to occur. Here, 10 jumps are used for the
; delay to ensure that the delay time will be more than long enough
; even on a very fast PC.
;
    pushf
    sti
    rept    10
    jmp     $+2
    endm
    MPOPF
;
; Store the timing start BIOS count.
; (Since the timer count was just set to 0, the BIOS count will
; stay the same for the next 54 ms, so we don't need to disable
; interrupts in order to avoid getting a half-changed count.)
;
    push    ds
    sub     ax,ax
    mov     ds,ax
    mov     ax,ds:[TIMER_COUNT+2]
    mov     cs:[StartBIOSCountHigh],ax
    mov     ax,ds:[TIMER_COUNT]
    mov     cs:[StartBIOSCountLow],ax
    pop     ds
;
; Set the timer count to 0 again to start the timing interval.
;
    mov     al,00110100b        ;set up to load initial
    out     MODE_8253,al        ; timer count
    DELAY
    sub     al,al
    out     TIMER_0_8253,al     ;load count lsb
    DELAY
    out     TIMER_0_8253,al     ;load count msb
;
; Restore the context of the program being timed and return to it.
;
    MPOPF
    pop     ax
    ret

ZTimerOn    endp

;********************************************************************
;* Routine called to stop timing and get count.                     *
;********************************************************************

ZTimerOff   proc    near

;
; Save the context of the program being timed.
;
    pushf
    push    ax
    push    cx
;
; In case interrupts are disabled, enable interrupts briefly to allow
; any pending timer interrupt to be handled. Interrupts must be
; enabled for at least 210 ns to allow time for that interrupt to
; occur. Here, 10 jumps are used for the delay to ensure that the
; delay time will be more than long enough even on a very fast PC.
;
    sti
    rept    10
    jmp     $+2
    endm

;
; Latch the timer count.
;

if PS2

    mov     al,00000000b
    out     MODE_8253,al    ;latch timer 0 count
;
; This is where a one-instruction-long window exists on the PS/2.
; The timer count and the BIOS count can lose synchronization;
; since the timer keeps counting after it's latched, it can turn
; over right after it's latched and cause the BIOS count to turn
; over before interrupts are disabled, leaving us with the timer
; count from before the timer turned over coupled with the BIOS
; count from after the timer turned over. The result is a count
; that's 54 ms too long.
;

else

;
; Set timer 0 to mode 2 (divide-by-N), waiting for a 2-byte count
; load, which stops timer 0 until the count is loaded. (Only works
; on fully 8253-compatible chips.)
;
    mov     al,00110100b    ;mode 2
    out     MODE_8253,al
    DELAY
    mov     al,00000000b    ;latch timer 0 count
    out     MODE_8253,al

endif

    cli                     ;stop the BIOS count
;
; Read the BIOS count. (Since interrupts are disabled, the BIOS
; count won't change.)
;
    push    ds
    sub     ax,ax
    mov     ds,ax
    mov     ax,ds:[TIMER_COUNT+2]
    mov     cs:[EndBIOSCountHigh],ax
    mov     ax,ds:[TIMER_COUNT]
    mov     cs:[EndBIOSCountLow],ax
    pop     ds
;
; Read the timer count and save it.
;
    in      al,TIMER_0_8253         ;lsb
    DELAY
    mov     ah,al
    in      al,TIMER_0_8253         ;msb
    xchg    ah,al
    neg     ax                      ;convert from countdown
                                    ; remaining to elapsed
                                    ; count
    mov     cs:[EndTimedCount],ax
;
; Restart timer 0, which is still waiting for an initial count
; to be loaded.
;

ife PS2

    DELAY
    mov     al,00110100b    ;mode 2, waiting to load a
                            ; 2-byte count
    out     MODE_8253,al
    DELAY
    sub     al,al
    out     TIMER_0_8253,al ;lsb
    DELAY
    mov     al,ah
    out     TIMER_0_8253,al ;msb
    DELAY

endif

    sti                     ;let the BIOS count continue
;
; Time a zero-length code fragment, to get a reference for how
; much overhead this routine has. Time it 16 times and average it,
; for accuracy, rounding the result.
;
    mov     cs:[ReferenceCount],0
    mov     cx,16
    cli                     ;interrupts off to allow a
                            ; precise reference count
RefLoop:
    call    ReferenceZTimerOn
    call    ReferenceZTimerOff
    loop    RefLoop
    sti
    add     cs:[ReferenceCount],8   ;total + (0.5 * 16)
    mov     cl,4
    shr     cs:[ReferenceCount],cl  ;(total) / 16 + 0.5
;
; Restore the context of the program being timed and return to it.
;
    pop     cx
    pop     ax
    MPOPF
    ret

ZTimerOff   endp

;
; Called by ZTimerOff to start the timer for overhead measurements.
;

ReferenceZTimerOn   proc    near
;
; Save the context of the program being timed.
;
    push    ax
    pushf
;
; Set timer 0 of the 8253 to mode 2 (divide-by-N), to cause
; linear counting rather than count-by-two counting.
;
    mov     al,00110100b        ;mode 2
    out     MODE_8253,al
;
; Set the timer count to 0.
;
    DELAY
    sub     al,al
    out     TIMER_0_8253,al     ;lsb
    DELAY
    out     TIMER_0_8253,al     ;msb
;
; Restore the context of the program being timed and return to it.
;
    MPOPF
    pop     ax
    ret

ReferenceZTimerOn   endp

;
; Called by ZTimerOff to stop the timer and add the result to
; ReferenceCount for overhead measurements. Doesn't need to look
; at the BIOS count because timing a zero-length code fragment
; isn't going to take anywhere near 54 ms.
;

ReferenceZTimerOff  proc    near
;
; Save the context of the program being timed.
;
    pushf
    push    ax
    push    cx

;
; Match the interrupt-window delay in ZTimerOff.
;
    sti
    rept    10
    jmp     $+2
    endm

    mov     al,00000000b
    out     MODE_8253,al        ;latch timer
;
; Read the count and save it.
;
    DELAY
    in      al,TIMER_0_8253     ;lsb
    DELAY
    mov     ah,al
    in      al,TIMER_0_8253     ;msb
    xchg    ah,al
    neg     ax                  ;convert from countdown
                                ; remaining to elapsed
                                ; count
    add     cs:[ReferenceCount],ax
;
; Restore the context and return.
;
    pop     cx
    pop     ax
    MPOPF
    ret

ReferenceZTimerOff  endp

;********************************************************************
;* Routine called to report timing results.                         *
;********************************************************************

ZTimerReport    proc    near

    pushf
    push    ax
    push    bx
    push    cx
    push    dx
    push    si
    push    di
    push    ds
;
    push    cs              ;DOS functions require that DS point
    pop     ds              ; to text to be displayed on the screen
    assume  ds:Code
;
; See if midnight or more than an hour passed during timing. If so,
; notify the user.
;
    mov     ax,[StartBIOSCountHigh]
    cmp     ax,[EndBIOSCountHigh]
    jz      CalcBIOSTime                ;hour count didn't change,
                                        ; so everything's fine
    inc     ax
    cmp     ax,[EndBIOSCountHigh]
    jnz     TestTooLong                 ;midnight or two hour
                                        ; boundaries passed, so the
                                        ; results are no good
    mov     ax,[EndBIOSCountLow]
    cmp     ax,[StartBIOSCountLow]
    jb      CalcBIOSTime                ;a single hour boundary
                                        ; passed-that's OK, so long as
                                        ; the total time wasn't more
                                        ; than an hour

;
; Over an hour elapsed or midnight passed during timing, which
; renders the results invalid. Notify the user. This misses the
; case where a multiple of 24 hours has passed, but we'll rely
; on the perspicacity of the user to detect that case.
;
TestTooLong:
    mov     ah,9
    mov     dx,offset TurnOverStr
    int     21h
    jmp     short ZTimerReportDone
;
; Convert the BIOS time to microseconds.
;
CalcBIOSTime:
    mov     ax,[EndBIOSCountLow]
    sub     ax,[StartBIOSCountLow]
    mov     dx,54925                ;number of microseconds each
                                    ; BIOS count represents
    mul     dx
    mov     bx,ax                   ;set aside BIOS count in
    mov     cx,dx                   ; microseconds
;
; Convert timer count to microseconds.
;
    mov     ax,[EndTimedCount]
    mov     si,8381
    mul     si
    mov     si,10000
    div     si                      ;* .8381 = * 8381 / 10000
;
; Add timer and BIOS counts together to get an overall time in
; microseconds.
;
    add     bx,ax
    adc     cx,0
;
; Subtract the timer overhead and save the result.
;
    mov     ax,[ReferenceCount]
    mov     si,8381                 ;convert the reference count
    mul     si                      ; to microseconds
    mov     si,10000
    div     si                      ;* .8381 = * 8381 / 10000
    sub     bx,ax
    sbb     cx,0
    mov     [CurrentCountLow],bx
    mov     [CurrentCountHigh],cx
;
; Convert the result to an ASCII string by trial subtractions of
; powers of 10.
;
    mov     di,offset PowersOfTenEnd -offset PowersOfTen -4
    mov     si,offset TimedCountStr
CTSNextDigit:
    mov     bl,'0'
CTSLoop:
    mov     ax,[CurrentCountLow]
    mov     dx,[CurrentCountHigh]
    sub     ax,PowersOfTen[di]
    sbb     dx,PowersOfTen[di+2]
    jc      CTSNextPowerDown
    inc     bl
    mov     [CurrentCountLow],ax
    mov     [CurrentCountHigh],dx
    jmp     CTSLoop
CTSNextPowerDown:
    mov     [si],bl
    inc     si
    sub     di,4
    jns     CTSNextDigit
;
;
; Print the results.
;
    mov     ah,9
    mov     dx,offset OutputStr
    int     21h
;
ZTimerReportDone:
    pop     ds
    pop     di
    pop     si
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    MPOPF
    ret

ZTimerReport    endp

Code    ends
        End
```

## Listing 2-6

```nasm
;
; *** Listing 2-6 ***
;
; Program to measure performance of code that takes longer than
; 54 ms to execute. (LZTEST.ASM)
;
; Link with LZTIMER.ASM (Listing 2-5). LZTEST.BAT (Listing 2-7)
; can be used to assemble and link both files. Code to be
; measured must be in the file TESTCODE; Listing 2-8 shows
; a sample TESTCODE file.
;
; By Michael Abrash 4/26/89
;
mystack     segment     para stack 'STACK'
        db  512 dup(?)
mystack     ends
;
Code    segment     para public 'CODE'
        assume      cs:Code, ds:Code
        extrn   ZTimerOn:near, ZTimerOff:near, ZTimerReport:near
Start   proc    near
        push    cs
        pop     ds      ;point DS to the code segment,
                        ; so data as well as code can easily
                        ; be included in TESTCODE
;
; Delay for 6-7 seconds, to let the Enter keystroke that started the
; program come back up.
;
        mov     ah,2ch
        int     21h             ;get the current time
        mov     bh,dh           ;set the current time aside
DelayLoop:
        mov     ah,2ch
        push    bx              ;preserve start time
        int     21h             ;get time
        pop     bx              ;retrieve start time
        cmp     dh,bh           ;is the new seconds count less than
                                ; the start seconds count?
        jnb     CheckDelayTime  ;no
        add     dh,60           ;yes, a minute must have turned over,
                                ; so add one minute
CheckDelayTime:
        sub     dh,bh           ;get time that's passed
        cmp     dh,7            ;has it been more than 6 seconds yet?
        jb      DelayLoop       ;not yet
;
        include TESTCODE        ;code to be measured, including calls
                                ; to ZTimerOn and ZTimerOff
;
; Display the results.
;
        call    ZTimerReport
;
; Terminate the program.
;
        mov     ah,4ch
        int     21h
Start   endp
Code    ends
        end Start
```

## Listing 2-7

```bat
echo off
rem
rem *** Listing 2-7 ***
rem
rem ***************************************************************
rem * Batch file LZTIME.BAT, which builds and runs the            *
rem * long-period Zen timer program LZTEST.EXE to time the code   *
rem * named as the command-line parameter. Listing 2-5 must be    *
rem * named LZTIMER.ASM, and Listing 2-6 must be named            *
rem * LZTEST.ASM. To time the code in LST2-8, you'd type the      *
rem * DOS command:                                                *
rem *                                                             *
rem * lztime lst2-8                                               *
rem *                                                             *
rem * Note that MASM and LINK must be in the current directory or *
rem * on the current path in order for this batch file to work.   *
rem *                                                             *
rem * This batch file can be speeded up by assembling LZTIMER.ASM *
rem * once, then removing the lines:                              *
rem *                                                             *
rem * masm lztimer;                                               *
rem * if errorlevel 1 goto errorend                               *
rem *                                                             *
rem * from this file.                                             *
rem *                                                             *
rem * By Michael Abrash 4/26/89                                   *
rem ***************************************************************
rem
rem Make sure a file to test was specified.
rem
if not x%1==x goto ckexist
echo ***************************************************************
echo * Please specify a file to test.                              *
echo ***************************************************************
goto end
rem
rem Make sure the file exists.
rem
:ckexist
if exist %1 goto docopy
echo ***************************************************************
echo * The specified file, "%1," doesn't exist.
echo ***************************************************************
goto end
rem
rem copy the file to measure to TESTCODE.
:docopy
copy %1 testcode
masm lztest;
if errorlevel 1 goto errorend
masm lztimer;
if errorlevel 1 goto errorend
link lztest+lztimer;
if errorlevel 1 goto errorend
lztest
goto end
:errorend
echo ***************************************************************
echo * An error occurred while building the long-period Zen timer. *
echo ***************************************************************
:end
```

## Listing 2-8

```nasm
;
; *** Listing 2-8 ***
;
; Measures the performance of 20000 loads of AL from
; memory. (Use by renaming to TESTCODE, which is
; included by LZTEST.ASM (Listing 2-6). LZTIME.BAT
; (Listing 2-7) does this, along with all assembly
; and linking.)
;
; Note: takes about 10 minutes to assemble on a PC with
;       MASM 5.0.
;
        jmp     Skip    ;jump around defined data
;
        MemVar  db  ?
;
Skip:
;
; Start timing.
;
        call    ZTimerOn
;
        rept    20000
        mov     al,[MemVar]
        endm
;
; Stop timing.
;
        call    ZTimerOff
```

## Listing 3-1

```nasm
;
; *** Listing 3-1 ***
;
; Times speed of memory access to Enhanced Graphics
; Adapter graphics mode display memory at A000:0000.
;
        mov     ax,0010h
        int     10h         ;select hi-res EGA graphics
                            ; mode 10 hex (AH=0 selects
                            ; BIOS set mode function,
                            ; with AL=mode to select)
;
        mov     ax,0a000h
        mov     ds,ax
        mov     es,ax       ;move to & from same segment
        sub     si,si       ;move to & from same offset
        mov     di,si
        mov     cx,800h     ;move 2K words
        cld
        call    ZTimerOn
        rep     movsw       ;simply read each of the first
                            ; 2K words of the destination segment,
                            ; writing each byte immediately back
                            ; to the same address. No memory
                            ; locations are actually altered; this
                            ; is just to measure memory access
                            ; times
        call    ZTimerOff
;
        mov     ax,0003h
        int     10h         ;return to text mode
;
```

## Listing 3-2

```nasm
;
; *** Listing 3-2 ***
;
; Times speed of memory access to normal system
; memory.
;
        mov     ax,ds
        mov     es,ax       ;move to & from same segment
        sub     si,si       ;move to & from same offset
        mov     di,si
        mov     cx,800h     ;move 2K words
        cld
        call    ZTimerOn
        rep     movsw       ;simply read each of the first
                            ; 2K words of the destination segment,
                            ; writing each byte immediately back
                            ; to the same address. No memory
                            ; locations are actually altered; this
                            ; is just to measure memory access
                            ; times
        call    ZTimerOff
```

## Listing 4-1

```nasm
;
; *** Listing 4-1 ***
;
; Measures the performance of a loop which uses a
; byte-sized memory variable as the loop counter.
;
        jmp     Skip
;
Counter db      100
;
Skip:
        call    ZTimerOn
LoopTop:
        dec     [Counter]
        jnz     LoopTop
        call    ZTimerOff
```

## Listing 4-2

```nasm
;
; *** Listing 4-2 ***
;
; Measures the performance of a loop which uses a
; word-sized memory variable as the loop counter.
;
        jmp     Skip
;
Counter dw      100
;
Skip:
        call    ZTimerOn
LoopTop:
        dec     [Counter]
        jnz     LoopTop
        call    ZTimerOff
```

## Listing 4-3

```nasm
;
; *** Listing 4-3 ***
;
; Measures the performance of reading 1000 words
; from memory with 1000 word-sized accesses.
;
        sub     si,si
        mov     cx,1000
        call    ZTimerOn
        rep     lodsw
        call    ZTimerOff
```

## Listing 4-4

```nasm
;
; *** Listing 4-4 ***
;
; Measures the performance of reading 1000 words
; from memory with 2000 byte-sized accesses.
;
        sub     si,si
        mov     cx,2000
        call    ZTimerOn
        rep     lodsb
        call    ZTimerOff
```

## Listing 4-5

```nasm
;
; *** Listing 4-5 ***
;
; Measures the performance of 1000 SHR instructions
; in a row. Since SHR executes in 2 cycles but is
; 2 bytes long, the prefetch queue is always empty,
; and prefetching time determines the overall
; performance of the code.
;
        call    ZTimerOn
        rept    1000
        shr     ax,1
        endm
        call    ZTimerOff
```

## Listing 4-6

```nasm
;
; *** Listing 4-6 ***
;
; Measures the performance of 1000 MUL/SHR instruction
; pairs in a row. The lengthy execution time of MUL
; should keep the prefetch queue from ever emptying.
;
        mov     cx,1000
        sub     ax,ax
        call    ZTimerOn
        rept    1000
        mul     ax
        shr     ax,1
        endm
        call    ZTimerOff
```

## Listing 4-7

```nasm
;
; *** Listing 4-7 ***
;
; Measures the performance of repeated MOV AL,0 instructions,
; which take 4 cycles each according to Intel's official
; specifications.
;
        sub     ax,ax
        call    ZTimerOn
        rept    1000
        mov     al,0
        endm
        call    ZTimerOff
```

## Listing 4-8

```nasm
;
; *** Listing 4-8 ***
;
; Measures the performance of repeated SUB AL,ALinstructions,
; which take 3 cycles each according to Intel's official
; specifications.
;
        sub     ax,ax
        call    ZTimerOn
        rept    1000
        sub     al,al
        endm
        call    ZTimerOff
```

## Listing 4-9

```nasm
;
; *** Listing 4-9 ***
;
; Measures the performance of repeated MULinstructions,
; which allow the prefetch queue to be full at all times,
; to demonstrate a case in which DRAM refresh has no impact
; on code performance.
;
        sub     ax,ax
        call    ZTimerOn
        rept    1000
        mul     ax
        endm
        call    ZTimerOff
```

## Listing 4-10

```nasm
;
; *** Listing 4-10 ***
;
; Measures the performance of repeated SHR instructions,
; which empty the prefetch queue, to demonstrate the
; worst-case impact of DRAM refresh on code performance.
;
        call    ZTimerOn
        rept    1000
        shr     ax,1
        endm
        call    ZTimerOff
```

## Listing 4-11

```nasm
;
; *** Listing 4-11 ***
;
; Times speed of memory access to Enhanced Graphics
; Adapter graphics mode display memory at A000:0000.
;
        mov     ax,0010h
        int     10h         ;select hi-res EGA graphics
                            ; mode 10 hex (AH=0 selects
                            ; BIOS set mode function,
                            ; with AL=mode to select)
;
        mov     ax,0a000h
        mov     ds,ax
        mov     es,ax       ;move to & from same segment
        sub     si,si       ;move to & from same offset
        mov     di,si
        mov     cx,800h     ;move 2K words
        cld
        call    ZTimerOn
        rep     movsw       ;simply read each of the first
                            ; 2K words of the destination segment,
                            ; writing each byte immediately back
                            ; to the same address. No memory
                            ; locations are actually altered; this
                            ; is just to measure memory access
                            ; times
        call    ZTimerOff
;
        mov     ax,0003h
        int     10h         ;return to text mode
```

## Listing 4-12

```nasm
;
; *** Listing 4-12 ***
;
; Times speed of memory access to normal system
; memory.
;
        mov     ax,ds
        mov     es,ax       ;move to & from same segment
        sub     si,si       ;move to & from same offset
        mov     di,si
        mov     cx,800h     ;move 2K words
        cld
        call    ZTimerOn
        rep     movsw       ;simply read each of the first
                            ; 2K words of the destination segment,
                            ; writing each byte immediately back
                            ; to the same address. No memory
                            ; locations are actually altered; this
                            ; is just to measure memory access
                            ; times
        call    ZTimerOff
```

## Listing 5-1

```nasm
;
; *** Listing 5-1 ***
;
; Copies a byte via AH endlessly, for the purpose of
; illustrating the complexity of a complete understanding
; of even the simplest instruction sequence on the PC.
;
; Note: This program is an endless loop, and never exits!
;
; Compile and link as a standalone program; not intended
; for use with the Zen timer.
;
mystack     segment     para stack 'STACK'
        db  512 dup(?)
mystack     ends
;
Code    segment word public 'CODE'
        assume  cs:Code, ds:Code
Start   proc    near
        push    cs
        pop     ds
        jmp     Skip
;
i       db      1
j       db      0
;
Skip:
        rept    1000
        mov     ah,ds:[i]
        mov     ds:[j],ah
        endm
        jmp     Skip
Start   endp
Code    ends
        end     Start
```

## Listing 7-1

```nasm
;
; *** Listing 7-1 ***
;
; Calculates the 16-bit sum of all bytes in a 64Kb block.
;
; Time with LZTIME.BAT, since this takes more than
; 54 ms to run.
;
        call    ZTimerOn
        sub     bx,bx       ;we'll just sum the data segment
        sub     cx,cx       ;count 64K bytes
        mov     ax,cx       ;set initial sum to 0
        mov     dh,ah       ;set DH to 0 for summing later
SumLoop:
        mov     dl,[bx]     ;get this byte
        add     ax,dx       ;add the byte to the sum
        inc     bx          ;point to the next byte
        loop    SumLoop
        call    ZTimerOff
```

## Listing 7-2

```nasm
;
; *** Listing 7-2 ***
;
; Calculates the 16-bit sum of all bytes in a 128Kb block.
;
; Time with LZTIME.BAT, since this takes more than
; 54 ms to run.
;
        call    ZTimerOn
        sub     bx,bx       ;we'll just sum the 128Kb starting
                            ; at DS:0
        sub     cx,cx       ;count 128K bytes with SI:CX
        mov     si,2
        mov     ax,cx       ;set initial sum to 0
        mov     dh,ah       ;set DH to 0 for summing later
SumLoop:
        mov     dl,[bx]     ;get this byte
        add     ax,dx       ;add the byte to the sum
        inc     bx          ;point to the next byte
        and     bx,0fh      ;time to advance the segment?
        jnz     SumLoopEnd  ;not yet
        mov     di,ds       ;advance the segment by 1; since BX
        inc     di          ; has just gone from 15 to 0, we've
        mov     ds,di       ; advanced 1 byte in all
SumLoopEnd:
        loop    SumLoop
        dec     si
        jnz     SumLoop
        call    ZTimerOff
```

## Listing 7-3

```nasm
;
; *** Listing 7-3 ***
;
; Calculates the 16-bit sum of all bytes in a 128Kb block
; using optimized code that takes advantage of the knowledge
; that the first byte summed is at offset 0 in its segment.
;
; Time with LZTIME.BAT, since this takes more than
; 54 ms to run.
;
        call    ZTimerOn
        sub     bx,bx       ;we'll just sum the 128Kb starting
                            ; at DS:0
        mov     cx,2        ;count two 64Kb blocks
        mov     ax,bx       ;set initial sum to 0
        mov     dh,ah       ;set DH to 0 for summing later
SumLoop:
        mov     dl,[bx]     ;get this byte
        add     ax,dx       ;add the byte to the sum
        inc     bx          ;point to the next byte
        jnz     SumLoop     ;go until we wrap at the end of a
                            ; 64Kb block
        mov     si,ds
        add     si,1000h    ;advance the segment by 64K bytes
        mov     ds,si
        loop    SumLoop     ;count down 64Kb blocks
        call    ZTimerOff
```

## Listing 7-4

```nasm
;
; *** Listing 7-4 ***
;
; Adds one far array to another far array as a high-level
; language would, loading each far pointer with LES every
; time it's needed.
;
        jmp     Skip
;
ARRAY_LENGTH    equ     1000
Array1      db  ARRAY_LENGTH dup (1)
Array2      db  ARRAY_LENGTH dup (2)
;
; Adds one byte-sized array to another byte-sized array.
; C-callable.
;
; Input: parameters on stack as in AddArraysParms
;
; Output: none
;
; Registers altered: AL, BX, CX, ES
;
AddArraysParms  struc
        dw  ?               ;pushed BP
        dw  ?               ;return address
FarPtr1 dd  ?               ;pointer to array to be added to
FarPtr2 dd  ?               ;pointer to array to add to the
; other array
AddArraysLength dw      ?   ;# of bytes to add
AddArraysParms  ends
;
AddArrays   proc    near
        push    bp                          ;save caller's BP
        mov     bp,sp                       ;point to stack frame
        mov     cx,[bp+AddArraysLength]
                                            ;get the length to add
AddArraysLoop:
        les     bx,[bp+FarPtr2]             ;point to the array to add
                                            ; from
        inc     word ptr [bp+FarPtr2]
                                            ;point to the next byte
                                            ; of the array to add from
        mov     al,es:[bx]                  ;get the array element to
                                            ; add
        les     bx,[bp+FarPtr1]             ;point to the array to add
                                            ; to
        inc     word ptr [bp+FarPtr1]
                                            ;point to the next byte
                                            ; of the array to add to
        add     es:[bx],al                  ;add to the array
        loop    AddArraysLoop
        pop     bp                          ;restore caller's BP
        ret
AddArrays   endp
;
Skip:
        call    ZTimerOn
        mov     ax,ARRAY_LENGTH
        push    ax                  ;pass the length to add
        push    ds                  ;pass segment of Array2
        mov     ax,offset Array2
        push    ax                  ;pass offset of Array2
        push    ds                  ;pass segment of Array1
        mov     ax,offset Array1
        push    ax                  ;pass offset of Array1
        call    AddArrays
        add     sp,10               ;clear the parameters
        call    ZTimerOff
```

## Listing 7-5

```nasm
;
; *** Listing 7-5 ***
;
; Adds one far array to another far array as only assembler
; can, loading the two far pointers once and keeping them in
; the registers during the entire loop for speed.
;
        jmp     Skip
;
ARRAY_LENGTH    equ     1000
Array1      db  ARRAY_LENGTH dup (1)
Array2      db  ARRAY_LENGTH dup (2)
;
; Adds one byte-sized array to another byte-sized array.
; C-callable.
;
; Input: parameters on stack as in AddArraysParms
;
; Output: none
;
; Registers altered: AL, BX, CX, DX, ES
;
AddArraysParms  struc
        dw  ?               ;pushed BP
        dw  ?               ;return address
FarPtr1 dd  ?               ;pointer to array to be added to
FarPtr2 dd  ?               ;pointer to array to add to the
                            ; other array
AddArraysLength     dw  ?   ;# of bytes to add
AddArraysParms      ends
;
AddArrays   proc    near
        push    bp                      ;save caller's BP
        mov     bp,sp                   ;point to stack frame
        push    si                      ;save registers used by many
        push    di                      ; C compilers for register
                                        ; variables
        mov     cx,[bp+AddArraysLength]
                                        ;get the length to add
        les     si,[bp+FarPtr2]         ;point to the array to add
                                        ; from
        mov     dx,es                   ;set aside the segment
        les     bx,[bp+FarPtr1]         ;point to the array to add
                                        ; to
        mov     di,es                   ;set aside the segment
AddArraysLoop:
        mov     es,dx                   ;point ES:SI to the next
                                        ; byte of the array to add
                                        ; from
        mov     al,es:[si]              ;get the array element to
                                        ; add
        inc     si                      ;point to the next byte of
                                        ; the array to add from
        mov     es,di                   ;point ES:BX to the next
                                        ; byte of the array to add
                                        ; to
        add     es:[bx],al              ;add to the array
        inc     bx                      ;point to the next byte of
                                        ; the array to add to
        loop    AddArraysLoop
        pop     di                      ;restore registers used by
        pop     si                      ; many C compilers for
                                        ; register variables
        pop     bp                      ;restore caller's BP
        ret
        AddArrays   endp
;
Skip:
        call    ZTimerOn
        mov     ax,ARRAY_LENGTH
        push    ax                  ;pass the length to add
        push    ds                  ;pass segment of Array2
        mov     ax,offset Array2
        push    ax                  ;pass offset of Array2
        push    ds                  ;pass segment of Array1
        mov     ax,offset Array1
        push    ax                  ;pass offset of Array1
        call    AddArrays
        add     sp,10               ;clear the parameters
        call    ZTimerOff
```

## Listing 7-6

```nasm
;
; *** Listing 7-6 ***
;
; Adds one far array to another far array by temporarily
; switching segments in order to allow the use of the most
; efficient possible instructions within the loop.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
Array1 db ARRAY_LENGTH dup (1)
Array2 db ARRAY_LENGTH dup (2)
;
; Adds one byte-sized array to another byte-sized array.
; C-callable.
;
; Input: parameters on stack as in AddArraysParms
;
; Output: none
;
; Registers altered: AL, BX, CX, ES
;
; Direction flag cleared
;
AddArraysParms struc
dw ? ;pushed BP
dw ? ;return address
FarPtr1 dd ? ;pointer to array to be added to
FarPtr2 dd ? ;pointer to array to add to the
; other array
AddArraysLength dw ? ;# of bytes to add
AddArraysParms ends
;
AddArrays proc near
push bp ;save caller's BP
mov bp,sp ;point to stack frame
push si ;save register used by many
; C compilers for register
; variables
push ds ;save normal DS, since we're
; going to switch data
; segments for the duration
; of the loop
mov cx,[bp+AddArraysLength]
;get the length to add
les bx,[bp+FarPtr1] ;point to the array to add
; to
lds si,[bp+FarPtr2] ;point to the array to add
; from
cld ;make LODSB increment SI
AddArraysLoop:
lodsb ;get the array element to
; add
add es:[bx],al ;add to the other array
inc bx ;point to the next byte of
; the array to add to
loop AddArraysLoop
pop ds ;restore normal DS
pop si ;restore register used by
; many C compilers for
; register variables
pop bp ;restore caller's BP
ret
AddArrays endp
;
Skip:
call ZTimerOn
mov ax,ARRAY_LENGTH
push ax ;pass the length to add
push ds ;pass segment of Array2
mov ax,offset Array2
push ax ;pass offset of Array2
push ds ;pass segment of Array1
mov ax,offset Array1
push ax ;pass offset of Array1
call AddArrays
add sp,10 ;clear the parameters
call ZTimerOff
```

## Listing 7-7

```nasm
;
; *** Listing 7-7 ***
;
; Strips the high bit of every byte in a byte-sized array,
; using a segment override prefix.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
TestArray db ARRAY_LENGTH dup (0ffh)
;
; Strips the high bit of every byte in a byte-sized array.
;
; Input:
; CX = length of array
; ES:BX = pointer to start of array
;
; Output: none
;
; Registers altered: AL, BX
;
StripHighBits proc near
mov al,not 80h ;bit pattern for stripping
; high bits, loaded into a
; register outside the loop
; so we can use fast
; register-to-memory ANDing
; inside the loop
StripHighBitsLoop:
and es:[bx],al ;strip this byte's high bit
inc bx ;point to next byte
loop StripHighBitsLoop
ret
StripHighBits endp
;
Skip:
call ZTimerOn
mov bx,seg TestArray
mov es,bx
mov bx,offset TestArray ;point to array
; which will have
; high bits stripped
call StripHighBits ;strip the high bits
call ZTimerOff
```

## Listing 7-8

```nasm
;
; *** Listing 7-8 ***
;
; Strips the high bit of every byte in a byte-sized array
; without using a segment override prefix.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
TestArray db ARRAY_LENGTH dup (0ffh)
;
; Strips the high bit of every byte in a byte-sized array.
;
; Input:
; CX = length of array
; ES:BX = pointer to start of array
;
; Output: none
;
; Registers altered: AL, BX
;
StripHighBits proc near
push ds ;save normal DS
mov ax,es ;point DS to the array's
mov ds,ax ; segment
mov al,not 80h ;bit pattern for stripping
; high bits, loaded into a
; register outside the loop
; so we can use fast
; register-to-memory ANDing
; inside the loop
StripHighBitsLoop:
and [bx],al ;strip this byte's high bit
inc bx ;point to next byte
loop StripHighBitsLoop
pop ds ;restore normal DS
ret
StripHighBits endp
;
Skip:
call ZTimerOn
mov bx,seg TestArray
mov es,bx
mov bx,offset TestArray ;point to array
; which will have
; high bits stripped
call StripHighBits ;strip the high bits
call ZTimerOff
```

## Listing 7-9

```nasm
;
; *** Listing 7-9 ***
;
; Adds up the elements of a byte-sized array using
; base+index+displacement addressing inside the loop.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
TestArray db ARRAY_LENGTH dup (1)
TEST_START_OFFSET equ 200 ;we'll add elements 200-299
TEST_LENGTH equ 100 ; of TestArray
;
Skip:
call ZTimerOn
mov bx,TEST_START_OFFSET
;for base+index+displacement
sub si,si ; addressing
sub ax,ax ;initialize sum
sub dl,dl ;store 0 in DL so we can use
; it for faster register-
; register adds in the loop
mov cx,TEST_LENGTH ;# of bytes to add
SumArrayLoop:
add al,[TestArray+bx+si] ;add in the next byte
adc ah,dl ; to the 16-bit sum
inc si ;point to next byte
loop SumArrayLoop
call ZTimerOff
```

## Listing 7-10

```nasm
;
; *** Listing 7-10 ***
;
; Adds up the elements of a byte-sized array using
; base+index addressing inside the loop.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
TestArray db ARRAY_LENGTH dup (1)
TEST_START_OFFSET equ 200 ;we'll add elements 200-299
TEST_LENGTH equ 100 ; of TestArray
;
Skip:
call ZTimerOn
mov bx,offset TestArray+TEST_START_OFFSET
;build the array start
; offset right into the
; base so we can use
; base+index addressing,
sub si,si ; with no displacement
sub ax,ax ;initialize sum
sub dl,dl ;store 0 in DL so we can use
; it for faster register-
; register adds in the loop
mov cx,TEST_LENGTH ;# of bytes to add
SumArrayLoop:
add al,[bx+si] ;add in the next byte
adc ah,dl ; to the 16-bit sum
inc si ;point to next byte
loop SumArrayLoop
call ZTimerOff
```

## Listing 7-11

```nasm
;
; *** Listing 7-11 ***
;
; Adds up the elements of a byte-sized array using
; base-only addressing inside the loop.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
TestArray db ARRAY_LENGTH dup (1)
TEST_START_OFFSET equ 200 ;we'll add elements 200-299
TEST_LENGTH equ 100 ; of TestArray
;
Skip:
call ZTimerOn
mov bx,offset TestArray+TEST_START_OFFSET
;build the array start
; offset right into the
; base so we can use
; base addressing, with no
; displacement
sub ax,ax ;initialize sum
sub dl,dl ;store 0 in DL so we can use
; it for faster register-
; register adds in the loop
mov cx,TEST_LENGTH ;# of bytes to add
SumArrayLoop:
add al,[bx] ;add in the next byte
adc ah,dl ; to the 16-bit sum
inc bx ;point to next byte
loop SumArrayLoop
call ZTimerOff
```

## Listing 7-12

```nasm
;
; *** Listing 7-12 ***
;
; Adds up the elements of a byte-sized array using
; base-only addressing inside the loop, and using
; an immediate operand with ADC.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
TestArray db ARRAY_LENGTH dup (1)
TEST_START_OFFSET equ 200 ;we'll add elements 200-299
TEST_LENGTH equ 100 ; of TestArray
;
Skip:
call ZTimerOn
mov bx,offset TestArray+TEST_START_OFFSET
;build the array start
; offset right into the
; base so we can use
; base+index addressing,
; with no displacement
sub ax,ax ;initialize sum
mov cx,TEST_LENGTH ;# of bytes to add
SumArrayLoop:
add al,[bx] ;add in the next byte
adc ah,0 ; to the 16-bit sum
inc bx ;point to next byte
loop SumArrayLoop
call ZTimerOff
```

## Listing 7-13

```nasm
;
; *** Listing 7-13 ***
;
; Adds up the elements of a byte-sized array using
; base-only addressing inside the loop, and using
; a memory operand with ADC.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
TestArray db ARRAY_LENGTH dup (1)
TEST_START_OFFSET equ 200 ;we'll add elements 200-299
TEST_LENGTH equ 100 ; of TestArray
MemZero db 0 ;the constant value 0
;
Skip:
call ZTimerOn
mov bx,offset TestArray+TEST_START_OFFSET
;build the array start
; offset right into the
; base so we can use
; base+index addressing,
; with no displacement
sub ax,ax ;initialize sum
mov cx,TEST_LENGTH ;# of bytes to add
SumArrayLoop:
add al,[bx] ;add in the next byte
adc ah,[MemZero] ; to the 16-bit sum
inc bx ;point to next byte
loop SumArrayLoop
call ZTimerOff
```

## Listing 7-14

```nasm
;
; *** Listing 7-14 ***
;
; Performs bit-doubling of a byte in AL to a word in AX
; by using doubled shifts, one from each of two source
; registers. This approach avoids branching and is very
; fast according to officiaLinstruction timings, but is
; actually quite slow due to instruction prefetching.
;
; (Based on an approach used in "Optimizing for Speed,"
; by Michael Hoyt, Programmer's Journal 4.2, March, 1986.)
;
; Macro to double each bit in a byte.
;
; Input:
; AL = byte to bit-double
;
; Output:
; AX = bit-doubled word
;
; Registers altered: AX, BX
;
DOUBLE_BYTE macro
mov ah,al ;put the byte to double in two
; registers
mov bx,ax
rept 8
shr bl,1 ;get the next bit to double
rcr ax,1 ;move it into the msb...
shr bh,1 ;...then get the bit again...
rcr ax,1 ;...and replicate it
endm
endm
;
call ZTimerOn
BYTE_TO_DOUBLE=0
rept 100
mov al,BYTE_TO_DOUBLE
DOUBLE_BYTE
BYTE_TO_DOUBLE=BYTE_TO_DOUBLE+1
endm
call ZTimerOff
```

## Listing 7-15

```nasm
;
; *** Listing 7-15 ***
;
; Performs very fast bit-doubling of a byte in AL to a
; word in AX by using a look-up table.
; This approach avoids both branching and the severe
; instruction-fetching penalty of the shift-based approach.
;
; Macro to double each bit in a byte.
;
; Input:
; AL = byte to bit-double
;
; Output:
; AX = bit-doubled word
;
; Registers altered: AX, BX
;
DOUBLE_BYTE macro
mov bl,al ;move the byte to look up to BL,
sub bh,bh ; make a word out of the value,
shl bx,1 ; and double the value so we can
; use it as a pointer into the
; table of word-sized doubled byte
; values
mov ax,[DoubledByteTable+bx]
;look up the doubled byte value
endm
;
jmp Skip
DOUBLED_VALUE=0
DoubledByteTable label word
dw 00000h,00003h,0000ch,0000fh,00030h,00033h,0003ch,0003fh
dw 000c0h,000c3h,000cch,000cfh,000f0h,000f3h,000fch,000ffh
dw 00300h,00303h,0030ch,0030fh,00330h,00333h,0033ch,0033fh
dw 003c0h,003c3h,003cch,003cfh,003f0h,003f3h,003fch,003ffh
dw 00c00h,00c03h,00c0ch,00c0fh,00c30h,00c33h,00c3ch,00c3fh
dw 00cc0h,00cc3h,00ccch,00ccfh,00cf0h,00cf3h,00cfch,00cffh
dw 00f00h,00f03h,00f0ch,00f0fh,00f30h,00f33h,00f3ch,00f3fh
dw 00fc0h,00fc3h,00fcch,00fcfh,00ff0h,00ff3h,00ffch,00fffh
;
dw 03000h,03003h,0300ch,0300fh,03030h,03033h,0303ch,0303fh
dw 030c0h,030c3h,030cch,030cfh,030f0h,030f3h,030fch,030ffh
dw 03300h,03303h,0330ch,0330fh,03330h,03333h,0333ch,0333fh
dw 033c0h,033c3h,033cch,033cfh,033f0h,033f3h,033fch,033ffh
dw 03c00h,03c03h,03c0ch,03c0fh,03c30h,03c33h,03c3ch,03c3fh
dw 03cc0h,03cc3h,03ccch,03ccfh,03cf0h,03cf3h,03cfch,03cffh
dw 03f00h,03f03h,03f0ch,03f0fh,03f30h,03f33h,03f3ch,03f3fh
dw 03fc0h,03fc3h,03fcch,03fcfh,03ff0h,03ff3h,03ffch,03fffh
;
dw 0c000h,0c003h,0c00ch,0c00fh,0c030h,0c033h,0c03ch,0c03fh
dw 0c0c0h,0c0c3h,0c0cch,0c0cfh,0c0f0h,0c0f3h,0c0fch,0c0ffh
dw 0c300h,0c303h,0c30ch,0c30fh,0c330h,0c333h,0c33ch,0c33fh
dw 0c3c0h,0c3c3h,0c3cch,0c3cfh,0c3f0h,0c3f3h,0c3fch,0c3ffh
dw 0cc00h,0cc03h,0cc0ch,0cc0fh,0cc30h,0cc33h,0cc3ch,0cc3fh
dw 0ccc0h,0ccc3h,0cccch,0cccfh,0ccf0h,0ccf3h,0ccfch,0ccffh
dw 0cf00h,0cf03h,0cf0ch,0cf0fh,0cf30h,0cf33h,0cf3ch,0cf3fh
dw 0cfc0h,0cfc3h,0cfcch,0cfcfh,0cff0h,0cff3h,0cffch,0cfffh
;
dw 0f000h,0f003h,0f00ch,0f00fh,0f030h,0f033h,0f03ch,0f03fh
dw 0f0c0h,0f0c3h,0f0cch,0f0cfh,0f0f0h,0f0f3h,0f0fch,0f0ffh
dw 0f300h,0f303h,0f30ch,0f30fh,0f330h,0f333h,0f33ch,0f33fh
dw 0f3c0h,0f3c3h,0f3cch,0f3cfh,0f3f0h,0f3f3h,0f3fch,0f3ffh
dw 0fc00h,0fc03h,0fc0ch,0fc0fh,0fc30h,0fc33h,0fc3ch,0fc3fh
dw 0fcc0h,0fcc3h,0fccch,0fccfh,0fcf0h,0fcf3h,0fcfch,0fcffh
dw 0ff00h,0ff03h,0ff0ch,0ff0fh,0ff30h,0ff33h,0ff3ch,0ff3fh
dw 0ffc0h,0ffc3h,0ffcch,0ffcfh,0fff0h,0fff3h,0fffch,0ffffh
;
Skip:
call ZTimerOn
BYTE_TO_DOUBLE=0
rept 100
mov al,BYTE_TO_DOUBLE
DOUBLE_BYTE
BYTE_TO_DOUBLE=BYTE_TO_DOUBLE+1
endm
call ZTimerOff
```

## Listing 7-16

```nasm
;
; *** Listing 7-16 ***
;
; Performs fast, compact bit-doubling of a byte in AL
; to a word in AX by using two nibble look-ups rather
; than a byte look-up.
;
; Macro to double each bit in a byte.
;
; Input:
; AL = byte to bit-double
;
; Output:
; AX = bit-doubled word
;
; Registers altered: AX, BX, CL
;
DOUBLE_BYTE macro
mov bl,al ;move the byte to look up to BL
sub bh,bh ; and make a word out of the value
mov cl,4 ;make a look-up pointer out of the
shr bx,cl ; upper nibble of the byte
mov ah,[DoubledNibbleTable+bx]
;look up the doubled upper nibble
mov bl,al ;get the byte to look up again,
and bl,0fh ; and make a pointer out of the
; lower nibble this time
mov al,[DoubledNibbleTable+bx]
;look up the doubled lower nibble
endm
;
jmp Skip
DOUBLED_VALUE=0
DoubledNibbleTable label byte
db 000h, 003h, 00ch, 00fh
db 030h, 033h, 03ch, 03fh
db 0c0h, 0c3h, 0cch, 0cfh
db 0f0h, 0f3h, 0fch, 0ffh
;
Skip:
call ZTimerOn
BYTE_TO_DOUBLE=0
rept 100
mov al,BYTE_TO_DOUBLE
DOUBLE_BYTE
BYTE_TO_DOUBLE=BYTE_TO_DOUBLE+1
endm
call ZTimerOff
```

## Listing 7-17

```nasm
;
; *** Listing 7-17 ***
;
; Performs fast, compact bit-doubling of a byte in AL
; to a word in AX by using two nibble look-ups. Overall
; code length and performance are improved by
; using base indexed addressing (bx+si) rather than base
; direct addressing (bx+DoubleNibbleTable). Even though
; an additional 3-byte MOV instruction is required to load
; SI with the offset of DoubleNibbleTable, each access to
; DoubleNibbleTable is 2 bytes shorter thanks to the
; elimination of mod-reg-rm displacements.
;
; Macro to double each bit in a byte.
;
; Input:
; AL = byte to bit-double
;
; Output:
; AX = bit-doubled word
;
; Registers altered: AX, BX, CL, SI
;
DOUBLE_BYTE macro
mov bl,al ;move the byte to look up to BL
sub bh,bh ; and make a word out of the value
mov cl,4 ;make a look-up pointer out of the
shr bx,cl ; upper nibble of the byte
mov si,offset DoubledNibbleTable
mov ah,[si+bx]
;look up the doubled upper nibble
mov bl,al ;get the byte to look up again,
and bl,0fh ; and make a pointer out of the
; lower nibble this time
mov al,[si+bx]
;look up the doubled lower nibble
endm
;
jmp Skip
DOUBLED_VALUE=0
DoubledNibbleTable label byte
db 000h, 003h, 00ch, 00fh
db 030h, 033h, 03ch, 03fh
db 0c0h, 0c3h, 0cch, 0cfh
db 0f0h, 0f3h, 0fch, 0ffh
;
Skip:
call ZTimerOn
BYTE_TO_DOUBLE=0
rept 100
mov al,BYTE_TO_DOUBLE
DOUBLE_BYTE
BYTE_TO_DOUBLE=BYTE_TO_DOUBLE+1
endm
call ZTimerOff
```

## Listing 7-18

```nasm
;
; *** Listing 7-18 ***
;
; Performs fast, compact bit-doubling of a byte in AL
; to a word in AX by using two nibble look-ups. Overall
; code length and performance are improved by
; using XLAT to look up the nibbles.
;
; Macro to double each bit in a byte.
;
; Input:
; AL = byte to bit-double
;
; Output:
; AX = bit-doubled word
;
; Registers altered: AX, BX, CL
;
DOUBLE_BYTE macro
mov ah,al ;set aside the byte to look up
mov cl,4 ;make a look-up pointer out of the
shr al,cl ; upper nibble of the byte (XLAT
; uses AL as an index pointer)
mov bx,offset DoubledNibbleTable
;XLAT uses BX as a base pointer
xlat ;look up the doubled value of the
; upper nibble
xchg ah,al ;store the doubled upper nibble in AH
; and get back the value to double
and al,0fh ;make a look-up pointer out of the
; lower nibble of the byte
xlat ;look up the doubled value of the
; lower nibble of the byte
endm
;
jmp Skip
DOUBLED_VALUE=0
DoubledNibbleTable label byte
db 000h, 003h, 00ch, 00fh
db 030h, 033h, 03ch, 03fh
db 0c0h, 0c3h, 0cch, 0cfh
db 0f0h, 0f3h, 0fch, 0ffh
;
Skip:
call ZTimerOn
BYTE_TO_DOUBLE=0
rept 100
mov al,BYTE_TO_DOUBLE
DOUBLE_BYTE
BYTE_TO_DOUBLE=BYTE_TO_DOUBLE+1
endm
call ZTimerOff
```

## Listing 7-19

```nasm
;
; *** Listing 7-19 ***
;
; Measures the performance of multiplying by 80 with
; the MULinstruction
;
sub ax,ax
call ZTimerOn
rept 1000
mov ax,10 ;so we have a constant value to
; multiply by
mov dx,80 ;amount to multiply by
mul dx
endm
call ZTimerOff
```

## Listing 7-20

```nasm
;
; *** Listing 7-20 ***
;
; Measures the performance of multiplying by 80 with
; shifts and adds.
;
sub ax,ax
call ZTimerOn
rept 1000
mov ax,10 ;so we have a constant value to
; multiply by
mov cl,4
shl ax,cl ;times 16
mov cx,ax ;set aside times 16
shl ax,1 ;times 32
shl ax,1 ;times 64
add ax,cx ;times 80 (times 64 + times 16)
endm
call ZTimerOff
```

## Listing 7-21

```nasm
;
; *** Listing 7-21 ***
;
; Measures the performance of multiplying by 80 with
; a table look-up.
;
jmp Skip
;
; Table of multiples of 80, covering the range 80 times 0
; to 80 times 479.
;
Times80Table label word
TIMES_80_SUM=0
rept 480
dw TIMES_80_SUM
TIMES_80_SUM=TIMES_80_SUM+80
endm
;
Skip:
sub ax,ax
call ZTimerOn
rept 1000
mov ax,10 ;so we have a constant value to
; multiply by
mov bx,ax ;put the factor where we can use it
; for a table look-up
shl bx,1 ;times 2 for use as an index in a
; word-sized look-up table
mov ax,[Times80Table+bx]
;look up the answer
endm
call ZTimerOff
```

## Listing 8-1

```nasm
;
; *** Listing 8-1 ***
;
; Copies a byte via AH, with memory addressed with
; mod-reg-rm direct addressing.
;
jmp Skip
;
SourceValue db 1
DestValue db 0
;
Skip:
call ZTimerOn
rept 1000
mov ah,[SourceValue]
mov [DestValue],ah
endm
call ZTimerOff
```

## Listing 8-2

```nasm
;
; *** Listing 8-2 ***
;
; Copies a byte via AL, with memory addressed with
; accumulator-specific direct addressing.
;
jmp Skip
;
SourceValue db 1
DestValue db 0
;
Skip:
call ZTimerOn
rept 1000
mov al,[SourceValue]
mov [DestValue],al
endm
call ZTimerOff
```

## Listing 8-3

```nasm
;
; *** Listing 8-3 ***
;
; Tests the zero/non-zero status of a variable via
; the direct-addressing mod-reg-rm form of CMP.
;
jmp Skip
;
TestValue dw ?
;
Skip:
call ZTimerOn
rept 1000
cmp [TestValue],0
endm
call ZTimerOff
```

## Listing 8-4

```nasm
;
; *** Listing 8-4 ***
;
; Tests the zero/non-zero status of a variable via
; the accumulator-specific form of MOV followed by a
; register-register AND.
;
jmp Skip
;
TestValue dw ?
;
Skip:
call ZTimerOn
rept 1000
mov ax,[TestValue]
and ax,ax
endm
call ZTimerOff
```

## Listing 8-5

```nasm
;
; *** Listing 8-5 ***
;
; Initializes a variable to 1 by setting AX to 1, then
; using the accumulator-specific form of MOV to store
; that value to a direct-addressed operand.
;
jmp Skip
;
InitialValue dw ?
;
Skip:
call ZTimerOn
rept 1000
mov ax,1
mov [InitialValue],ax
endm
call ZTimerOff
```

## Listing 8-6

```nasm
;
; *** Listing 8-6 ***
;
; Initializes a variable to 1 via the direct-addressing
; mod-reg-rm form of MOV.
;
jmp Skip
;
InitialValue dw ?
;
Skip:
call ZTimerOn
rept 1000
mov [InitialValue],1
endm
call ZTimerOff
```

## Listing 8-7

```nasm
;
; *** Listing 8-7 ***
;
; Initializes a variable to 0 via a register-register SUB,
; followed by the accumulator-specific form of MOV to a
; direct-addressed operand.
;
jmp Skip
;
InitialValue dw ?
;
Skip:
call ZTimerOn
rept 1000
sub ax,ax
mov [InitialValue],ax
endm
call ZTimerOff
```

## Listing 8-8

```nasm
;
; *** Listing 8-8 ***
;
; The accumulator-specific immediate-addressing form of CMP.
;
call ZTimerOn
rept 1000
cmp al,1
endm
call ZTimerOff
```

## Listing 8-9

```nasm
;
; *** Listing 8-9 ***
;
; The mod-reg-rm immediate-addressing form of CMP with a
; register as the destination operand.
;
call ZTimerOn
rept 1000
cmp bl,1
endm
call ZTimerOff
```

## Listing 8-10

```nasm
;
; *** Listing 8-10 ***
;
; Sets the BIOS equipment flag to select an 80-column
; color monitor.
; Uses mod-reg-rm AND and OR instructions.
;
call ZTimerOn
rept 1000
sub ax,ax
mov es,ax ;point ES to the segment at 0
and byte ptr es:[410h],not 30h
;mask off the adapter bits
or byte ptr es:[410h],20h
;set the adapter bits to select
; 80-column color
endm
call ZTimerOff
```

## Listing 8-11

```nasm
;
; *** Listing 8-11 ***
;
; Sets the BIOS equipment flag to select an 80-column
; color monitor.
; Uses accumulator-specific MOV, AND, and OR instructions.
;
call ZTimerOn
rept 1000
sub ax,ax
mov es,ax ;point ES to the segment at 0
mov al,es:[410h] ;get the equipment flag
and al,not 30h ;mask off the adapter bits
or al,20h ;set the adapter bits to select
; 80-column color
mov es:[410h],al ;set the new equipment flag
endm
call ZTimerOff
```

## Listing 8-12

```nasm
;
; *** Listing 8-12 ***
;
; Adds together bytes from two arrays, subtracts a byte from
; another array from the sum, and stores the result in a fourth
; array, for all elements in the arrays.
; Uses the AX-specific form of XCHG.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
Array1 db ARRAY_LENGTH dup (3)
Array2 db ARRAY_LENGTH dup (2)
Array3 db ARRAY_LENGTH dup (1)
Array4 db ARRAY_LENGTH dup (?)
;
Skip:
mov ax,offset Array1 ;set up array pointers
mov bx,offset Array2
mov si,offset Array3
mov di,offset Array4
mov cx,ARRAY_LENGTH
call ZTimerOn
ProcessingLoop:
xchg ax,bx ;point BX to Array1,
; point AX to Array2
mov dl,[bx] ;get next byte from Array1
xchg ax,bx ;point BX to Array2,
; point AX to Array1
add dl,[bx] ;add Array2 element to Array1
sub dl,[si] ;subtract Array3 element
mov [di],dl ;store result in Array4
inc ax ;point to next element of each array
inc bx
inc si
inc di
loop ProcessingLoop ;do the next element
call ZTimerOff
```

## Listing 8-13

```nasm
;
; *** Listing 8-13 ***
;
; Adds together bytes from two arrays, subtracts a byte from
; another array from the sum, and stores the result in a fourth
; array, for all elements in the arrays.
; Uses the mod-reg-rm form of XCHG.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
Array1 db ARRAY_LENGTH dup (3)
Array2 db ARRAY_LENGTH dup (2)
Array3 db ARRAY_LENGTH dup (1)
Array4 db ARRAY_LENGTH dup (?)
;
Skip:
mov dx,offset Array1
mov bx,offset Array2
mov si,offset Array3
mov di,offset Array4
mov cx,ARRAY_LENGTH
call ZTimerOn
ProcessingLoop:
xchg dx,bx ;point BX to Array1,
; point DX to Array2
mov al,[bx] ;get next byte from Array1
xchg dx,bx ;point BX to Array2,
; point DX to Array1
add al,[bx] ;add Array2 element to Array1
sub al,[si] ;subtract Array3 element
mov [di],al ;store result in Array4
inc dx ;point to next element of each array
inc bx
inc si
inc di
loop ProcessingLoop ;do the next element
call ZTimerOff
```

## Listing 8-14

```nasm
;
; *** Listing 8-14 ***
;
; Adds AL to each element in an array until the result
; of an addition exceeds 7Fh.
; Uses PUSHF and POPF.
;
jmp Skip
;
Data db 999 dup (0),7fh
;
Skip:
mov bx,offset Data
mov al,2 ;we'll add 2 to each array element
call ZTimerOn
AddLoop:
add [bx],al ;add the value to this element
pushf ;save the sign flag
inc bx ;point to the next array element
popf ;get back the sign flag
jns AddLoop ;do the next element, if any
call ZTimerOff
```

## Listing 8-15

```nasm
;
; *** Listing 8-15 ***
;
; Adds AL to each element in an array until the result
; of an addition exceeds 7Fh.
; Uses LAHF and SAHF.
;
jmp Skip
;
Data db 999 dup (0),7fh
;
Skip:
mov bx,offset Data
mov al,2 ;we'll add 2 to each array element
call ZTimerOn
AddLoop:
add [bx],al ;add the value to this element
lahf ;save the sign flag
inc bx ;point to the next array element
sahf ;get back the sign flag
jns AddLoop ;do the next element, if any
call ZTimerOff
```

## Listing 8-16

```nasm
;
; *** Listing 8-16 ***
;
; Adds AL to each element in an array until the result
; of an addition exceeds 7Fh.
; Uses two jumps in the loop, with a finaLiNC to adjust
; BX for the last addition.
;
jmp Skip
;
Data db 999 dup (0),7fh
;
Skip:
mov bx,offset Data
mov al,2 ;we'll add 2 to each array element
call ZTimerOn
AddLoop:
add [bx],al ;add the value to this element
js EndAddLoop ;done if Sign flag set
inc bx ;point to the next array element
jmp AddLoop ;do the next element
EndAddLoop:
inc bx ;adjust BX for the final addition
call ZTimerOff
```

## Listing 8-17

```nasm
;
; *** Listing 8-17 ***
;
; Adds AL to each element in an array until the result
; of an addition exceeds 7Fh.
; Uses one jump in the loop, with a predecrement before
; the loop, an INC before the ADD in the loop, and a final
; INC to adjust BX for the last addition.
;
jmp Skip
;
Data db 999 dup (0),7fh
;
Skip:
mov bx,offset Data
mov al,2 ;we'll add 2 to each array element
call ZTimerOn
dec bx ;compensate for the initiaLiNC
AddLoop:
inc bx ;point to the next array element
add [bx],al ;add the value to this element
jns AddLoop ;do the next element, if any
EndAddLoop:
inc bx ;adjust BX for the final addition
call ZTimerOff
```

## Listing 9-1

```nasm
;
; *** Listing 9-1 ***
;
; An example of initializing multiple memory variables
; to the same value by placing the value in a register,
; then storing the register to each of the variables.
; This avoids the overhead that's incurred when using
; immediate operands.
;
jmp Skip
;
MemVar1 dw ?
MemVar2 dw ?
MemVar3 dw ?
;
Skip:
call ZTimerOn
rept 1000
mov ax,0ffffh ;place the initial value in
; AX
mov [MemVar1],ax ;store AX to each memory
mov [MemVar2],ax ; variable to be initialized
mov [MemVar3],ax
endm
call ZTimerOff
```

## Listing 9-2

```nasm
;
; *** Listing 9-2 ***
;
; An example of initializing multiple memory variables
; to the same value by making the value an immediate
; operand to each instruction. Immediate operands
; increase instruction size by 1 to 2 bytes, and preclude
; use of the accumulator-specific direct-addressing
; form of MOV.
;
jmp Skip
;
MemVar1 dw ?
MemVar2 dw ?
MemVar3 dw ?
;
Skip:
call ZTimerOn
rept 1000
mov [MemVar1],0ffffh ;store 0ffffh to each memory
mov [MemVar2],0ffffh ; variable as an immediate
mov [MemVar3],0ffffh ; operand
endm
call ZTimerOff
```

## Listing 9-3

```nasm
;
; *** Listing 9-3 ***
;
; An example of using AND reg,reg to test for the
; zero/non-zero status of a register. This is faster
; (and usually shorter) than CMP reg,0.
;
sub dx,dx ;set DX to 0, so we don't jump
call ZTimerOn
rept 1000
and dx,dx ;is DX 0?
jnz $+2 ;just jumps to the next line if
; Z is not set (never jumps)
endm
call ZTimerOff
```

## Listing 9-4

```nasm
;
; *** Listing 9-4 ***
;
; An example of using CMP reg,0 to test for the
; zero/non-zero status of a register.
;
sub dx,dx ;set DX to 0, so we don't jump
call ZTimerOn
rept 1000
cmp dx,0 ;is DX 0?
jnz $+2 ;just jumps to the next line if
; Z is not set (never jumps)
endm
call ZTimerOff
```

## Listing 9-5

```nasm
;
; *** Listing 9-5 ***
;
; An example of performing a switch statement with just a
; few cases, all consecutive, by using CMP to test for each
; of the cases.
;
; Macro to perform switch statement. This must be a macro
; rather than code inside the REPT block because MASM
; doesn't handle LOCAL declarations properly inside REPT
; blocks, but it does handle them properly inside macros.
;
HANDLE_SWITCH macro
local ValueWas1, ValueWas2, ValueWas3, ValueWas4
cmp cx,1
jz ValueWas1
cmp cx,2
jz ValueWas2
cmp cx,3
jz ValueWas3
cmp cx,4
jz ValueWas4
; <none of the above>
ValueWas1:
ValueWas2:
ValueWas3:
ValueWas4:
endm
;
call ZTimerOn
TEST_VALUE = 1
rept 1000
mov cx,TEST_VALUE ;set the test value
HANDLE_SWITCH ;perform the switch test
TEST_VALUE = (TEST_VALUE MOD 5)+1 ;cycle the test value from
; 1 to 4
endm
call ZTimerOff
```

## Listing 9-6

```nasm
;
; *** Listing 9-6 ***
;
; An example of performing a switch statement with just a
; few cases, all consecutive, by using DEC to test for each
; of the cases.
;
; Macro to perform switch statement. This must be a macro
; rather than code inside the REPT block because MASM
; doesn't handle LOCAL declarations properly inside REPT
; blocks, but it does handle them properly inside macros.
;
HANDLE_SWITCH macro
local ValueWas1, ValueWas2, ValueWas3, ValueWas4
dec cx
jz ValueWas1
dec cx
jz ValueWas2
dec cx
jz ValueWas3
dec cx
jz ValueWas4
; <none of the above>
ValueWas1:
ValueWas2:
ValueWas3:
ValueWas4:
endm
;
call ZTimerOn
TEST_VALUE = 1
rept 1000
mov cx,TEST_VALUE ;set the test value
HANDLE_SWITCH ;perform the switch test
TEST_VALUE = (TEST_VALUE MOD 5)+1 ;cycle the test value from
; 0 to 3
endm
call ZTimerOff
```

## Listing 9-7

```nasm
;
; *** Listing 9-7 ***
;
; Times the performance of a 16-bit register DEC.
;
mov dx,1000
call ZTimerOn
TestLoop:
dec dx ;16-bit register DEC
; (1 byte long, uses 16-bit-
; register-specific form of DEC)
jnz TestLoop
call ZTimerOff
```

## Listing 9-8

```nasm
;
; *** Listing 9-8 ***
;
; Times the performance of a 16-bit subtraction
; of an immediate value of 1.
;
mov dx,1000
call ZTimerOn
TestLoop:
sub dx,1 ;decrement DX by subtracting 1 from
; it (3 bytes long, uses sign-
; extended mod-reg-rm form of SUB)
jnz TestLoop
call ZTimerOff
```

## Listing 9-9

```nsam
;
; *** Listing 9-9 ***
;
; Times the performance of two 16-bit register DEC
; instructions.
;
mov dx,2000
call ZTimerOn
TestLoop:
dec dx ;subtract 2 from DX by decrementing
dec dx ; it twice (2 bytes long, uses
; 2 16-bit-register-specific DECs)
jnz TestLoop
call ZTimerOff
```

## Listing 9-10

```nasm
;
; *** Listing 9-10 ***
;
; Times the performance of an 8-bit register DEC.
;
mov dl,100
call ZTimerOn
TestLoop:
dec dl ;8-bit register DEC
; (2 bytes long, uses mod-reg-rm
; form of DEC)
jnz TestLoop
call ZTimerOff
```

## Listing 9-11

```nasm
;
; *** Listing 9-11 ***
;
; Illustrates the use of the efficient word-sized INC to
; increment a byte-sized register, taking advantage of the
; knowledge that AL never counts past 0FFh to wrap to 0 and
; so AH will never affected by the INC.
;
; Note: This is a sample code fragment, and is not intended
; to either be run under the Zen timer or assembled as a
; standalone program.
;
sub al,al ;count up from 0
TestLoop:
inc ax ;AL will never turn over, so AH
; will never be affected
cmp al,8 ;count up to 8
jbe TestLoop
```

## Listing 9-12

```nasm
;
; *** Listing 9-12 ***
;
; Illustrates the use of a word-sized DEC for the outer
; loop, taking advantage of the knowledge that the counter
; for the inner loop is always 0 when the outer loop is
; counted down. This code uses no registers other than
; CX, and would be used when registers are in such short
; supply that no other registers are available. Otherwise,
; word-sized DECs would be used for both loops. (Ideally,
; a LOOP would also be used instead of DEC CX/JNZ.)
;
; Note: This is a sample code fragment, and is not intended
; to either be run under the Zen timer or assembled as a
; standalone program.
;
mov cl,5 ;outer loop is performed 5 times
OuterLoop:
mov ch,10 ;inner loop is performed 10 times
; each time through the outer loop
InnerLoop:
;<<<working code goes here>>>
dec ch ;count down inner loop
jnz InnerLoop
dec cx ;CH is always 0 at this point, so
; we can use the shorter & faster
; word DEC to count down CL
jnz OuterLoop
```

## Listing 9-13

```nasm
;
; *** Listing 9-13 ***
;
; Adds together two 64-bit memory variables, taking
; advantage of the fact that neither INC nor LOOP affects
; the Carry flag.
;
; Note: This is a sample code fragment, and is not intended
; to either be run under the Zen timer or assembled as a
; standalone program.
;
jmp Skip
;
MemVar1 db 2, 0, 0, 0, 0, 0, 0, 0
MEM_VAR_LEN equ ($-MemVar1)
MemVar2 db 0feh, 0ffh, 0ffh, 0ffh, 0, 0, 0, 0
;
Skip:
mov si,offset MemVar1 ;set up memory variable
mov di,offset MemVar2 ; pointers
mov ax,[si] ;add the first words
add [di],ax ; together
mov cx,(MEM_VAR_LEN/2)-1
;we'll add together the
; remaining 3 words in
; each variable
AdditionLoop:
inc si
inc si ;point to next word
inc di ; (doesn't affect Carry
inc di ; flag)
mov ax,[si] ;add the next words
adc [di],ax ; together-C flag still set
; from last addition
loop AdditionLoop ;add the next word of each
; variable together
```

## Listing 9-14

```nasm
;
; *** Listing 9-14 ***
;
; An illustration of the use of CBW to convert an
; array of unsigned byte values between 0 and 7Fh to an
; array of unsigned words. Note that this would not work
; if Array1 contained values greater than 7Fh.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
;
Array1 label byte
ARRAY_VALUE=0
rept ARRAY_LENGTH
db ARRAY_VALUE
ARRAY_VALUE=(ARRAY_VALUE+1) and 07fh
;cycle source array byte
; values from 0-7Fh
endm
;
Array2 dw ARRAY_LENGTH dup (?)
;
Skip:
mov si,offset Array1 ;set up array pointers
mov di,offset Array2
mov ax,ds
mov es,ax ;copy to & from same segment
cld ;make string instructions
; increment pointers
mov cx,ARRAY_LENGTH
call ZTimerOn
ProcessingLoop:
lodsb ;get the next element
cbw ;make it a word
stosw ;save the word value
loop ProcessingLoop ;do the next element
call ZTimerOff
```

## Listing 9-15

```nasm
;
; *** Listing 9-15 ***
;
; An illustration of the use of SUB AH,AH to convert an
; array of unsigned byte values between 0 and 7Fh to an
; array of words. Note that this would work even if Array1
; contained values greater than 7Fh.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
;
Array1 label byte
ARRAY_VALUE=0
rept ARRAY_LENGTH
db ARRAY_VALUE
ARRAY_VALUE=(ARRAY_VALUE+1) and 07fh
;cycle source array byte
; values from 0-7Fh
endm
;
Array2 dw ARRAY_LENGTH dup (?)
;
Skip:
mov si,offset Array1 ;set up array pointers
mov di,offset Array2
mov ax,ds
mov es,ax ;copy to & from same segment
cld ;make string instructions
; increment pointers
mov cx,ARRAY_LENGTH
call ZTimerOn
ProcessingLoop:
lodsb ;get the next element
sub ah,ah ;make it a word
stosw ;save the word value
loop ProcessingLoop ;do the next element
call ZTimerOff
```

## Listing 9-16

```nasm
;
;
; *** Listing 9-16 ***
;
; An illustration of the use of SUB AH,AH outside the
; processing loop to convert an array of byte values
; between 0 and 7Fh to an array of words. AH never changes
; from one pass through the loop to the next, so there's no
; need to continually set AH to 0.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
;
Array1 label byte
ARRAY_VALUE=0
rept ARRAY_LENGTH
db ARRAY_VALUE
ARRAY_VALUE=(ARRAY_VALUE+1) and 07fh
;cycle source array byte
; values from 0-7Fh
endm
;
Array2 dw ARRAY_LENGTH dup (?)
;
Skip:
mov si,offset Array1 ;set up array pointers
mov di,offset Array2
mov ax,ds
mov es,ax ;copy to & from same segment
cld ;make string instructions
; increment pointers
mov cx,ARRAY_LENGTH
sub ah,ah ;set up to make each byte
; read into AL a word in AX
; automatically
call ZTimerOn
ProcessingLoop:
lodsb ;get the next element
stosw ;save the word value
loop ProcessingLoop ;do the next element
call ZTimerOff
```

## Listing 9-17

```nasm
;
; *** Listing 9-17 ***
;
; Supports the use of CX to store a loop count and CL
; to store a shift count by pushing and popping the loop
; count around the use of the shift count.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
Array1 db ARRAY_LENGTH dup (3)
Array2 db ARRAY_LENGTH dup (2)
;
Skip:
mov si,offset Array1 ;point to the source array
mov di,offset Array2 ;point to the dest array
mov ax,ds
mov es,ax ;copy to & from same segment
mov cx,ARRAY_LENGTH ;the loop count
mov dl,2 ;the shift count
call ZTimerOn
ProcessingLoop:
lodsb ;get the next byte
push cx ;save the loop count
mov cl,dl ;get the shift count into CL
shl al,cl ;shift the byte
pop cx ;get back the loop count
stosb ;save the modified byte
loop ProcessingLoop
call ZTimerOff
```

## Listing 9-18

```nasm
;
; *** Listing 9-18 ***
;
; Supports the use of CX to store a loop count and CL
; to store a shift count by using XCHG to swap the
; contents of CL as needed.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
Array1 db ARRAY_LENGTH dup (3)
Array2 db ARRAY_LENGTH dup (2)
;
Skip:
mov si,offset Array1 ;point to the source array
mov di,offset Array2 ;point to the dest array
mov ax,ds
mov es,ax ;copy to & from same segment
mov cx,ARRAY_LENGTH ;the loop count
mov dl,2 ;the shift count
call ZTimerOn
ProcessingLoop:
lodsb ;get the next byte
xchg cl,dl ;get the shift count into CL
; and save the low byte of
; the loop count in DL
shl al,cl ;shift the byte
xchg cl,dl ;put the shift count back
; into DL and restore the
; low byte of the loop count
; to CL
stosb ;save the modified byte
loop ProcessingLoop
call ZTimerOff
```

## Listing 9-19

```nasm
;
; *** Listing 9-19 ***
;
; Times the performance of SUB with a register as the
; destination operand and memory as the source operand.
;
jmp Skip
;
Dest db 0
;
Skip:
call ZTimerOn
rept 1000
sub al,[Dest] ;subtract [Dest] from AL
; Only 1 memory access
; is performed
endm
call ZTimerOff
```

## Listing 9-20

```nasm
;
; *** Listing 9-20 ***
;
; Times the performance of SUB with memory as the
; destination operand and a register as the source operand.
;
jmp Skip
;
Dest db 0
;
Skip:
call ZTimerOn
rept 1000
sub [Dest],al ;subtract AL from [Dest]
; Two memory accesses are
; performed
endm
call ZTimerOff
```

## Listing 9-21

```nasm
;
; *** Listing 9-21 ***
;
; Times shifts performed by shifting CL times.
;
BITS_TO_SHIFT equ 1
call ZTimerOn
rept 100
mov cl,BITS_TO_SHIFT
shl ax,cl
endm
call ZTimerOff
```

## Listing 9-22

```nasm
;
; *** Listing 9-22 ***
;
; Times shifts performed by using multiple 1-bit shift
; instructions.
;
BITS_TO_SHIFT equ 1
call ZTimerOn
rept 100
rept BITS_TO_SHIFT
shl ax,1
endm
endm
call ZTimerOff
```

## Listing 9-23

```nasm
;
; *** Listing 9-23 ***
;
; Performs bit-doubling of a byte in AL to a word in AX
; by using SAR. This is not as fast as bit-doubling with
; a look-up table, but it is faster than any other
; shift-based approach.
; (Conceived by Dan Illowsky.)
;
DOUBLE_BYTE macro
mov bl,al
rept 8
shr bl,1 ;get the next bit to double
rcr ax,1 ;move it into the msb...
sar ax,1 ;...and replicate it
endm
endm
;
call ZTimerOn
BYTE_TO_DOUBLE=0
rept 100
mov al,BYTE_TO_DOUBLE
DOUBLE_BYTE
BYTE_TO_DOUBLE=(BYTE_TO_DOUBLE+1) and 0ffH
endm
call ZTimerOff
```

## Listing 9-24

```nasm
;
; *** Listing 9-24 ***
;
; Performs binary-to-ASCII conversion of a byte value
; by using AAM.
;
jmp Skip
;
ResultString db 3 dup (?)
ResultStringEnd label byte
db 0 ;a zero to mark the string end
;
Skip:
BYTE_VALUE=0
call ZTimerOn
rept 100
std ;make STOSB decrement DI
mov ax,ds
mov es,ax ;for STOSB
mov bl,'0' ;used for converting to ASCII
mov di,offset ResultStringEnd-1
mov al,BYTE_VALUE
aam ;put least significant decimal
; digit of BYTE_VALUE in AL,
; other digits in AH
add al,bl ;make it an ASCII digit
stosb ;save least significant digit
mov al,ah
aam ;put middle decimal digit in AL
add al,bl ;make it an ASCII digit
stosb ;save middle digit
;most significant decimal
; digit is in AH
add ah,bl ;make it an ASCII digit
mov [di],ah ;save most significant digit
BYTE_VALUE=BYTE_VALUE+1
endm
call ZTimerOff
```

## Listing 9-25

```nasm
;
; *** Listing 9-25 ***
;
; Performs binary-to-ASCII conversion of a byte value
; by using DIV.
;
jmp Skip
;
ResultString db 3 dup (?)
ResultStringEnd label byte
db 0 ;a zero to mark the string end
;
Skip:
BYTE_VALUE=0
call ZTimerOn
rept 100
mov cx,(10 shl 8)+'0'
;CL='0', used for converting to ASCII
; CH=10, used for dividing by 10
mov di,offset ResultString
mov al,BYTE_VALUE
sub ah,ah ;prepare 16-bit dividend
div ch ;put least significant decimal
; digit of BYTE_VALUE in AH,
; other digits in AL
add ah,cl ;make it an ASCII digit
mov [di+2],ah ;save least significant digit
sub ah,ah ;prepare 16-bit dividend
div ch ;put middle decimal digit in AL
add ah,cl ;make it an ASCII digit
mov [di+1],ah ;save middle ASCII decimal digit
;most significant decimal
; digit is in AL
add al,cl ;make it an ASCII digit
mov [di],al ;save most significant digit
BYTE_VALUE=BYTE_VALUE+1
endm
call ZTimerOff
```

## Listing 9-26

```nasm
;
; *** Listing 9-26 ***
;
; Performs addition of the ASCII decimal value "00001"
; to an ASCII decimal count variable.
;
DECIMAL_INCREMENT macro
local DigitLoop
std ;we'll work from least-significant
; to most-significant
mov si,offset ASCIIOne+VALUE_LENGTH-1
mov di,offset Count+VALUE_LENGTH-1
mov ax,ds
mov es,ax ;ES:DI points to Count for STOSB
mov cx,VALUE_LENGTH
clc ;there's no carry into the least-
; significant digit
DigitLoop:
lodsb ;get the next increment digit
adc al,[di] ;add it to the next Count digit
aaa ;adjust to an unpacked BCD digit
lahf ;save the carry, in case we just
; turned over 9
add al,'0' ;make it an ASCII digit
stosb
sahf ;get back the carry for the next adc
loop DigitLoop
endm
;
jmp Skip
;
Count db '00000'
VALUE_LENGTH equ $-Count
ASCIIOne db '00001'
;
Skip:
call ZTimerOn
rept 100
DECIMAL_INCREMENT
endm
call ZTimerOff
```

## Listing 10-1

```nasm
;
; *** Listing 10-1 ***
;
; Loads each byte in a 1000-byte array into AL, using
; MOV and INC.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
ByteArray db ARRAY_LENGTH dup (0)
;
Skip:
call ZTimerOn
mov si,offset ByteArray
;point to the start of the array
rept ARRAY_LENGTH
mov al,[si] ;get this array byte
inc si ;point to the next byte in the array
endm
call ZTimerOff
```

## Listing 10-2

```nasm
;
; *** Listing 10-2 ***
;
; Loads each byte in a 1000-byte array into AL, using
; LODSB.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
ByteArray db ARRAY_LENGTH dup (0)
;
Skip:
call ZTimerOn
mov si,offset ByteArray
;point to the start of the array
cld ;make LODSB increment SI
rept ARRAY_LENGTH
lodsb ;get this array byte & point to the
; next byte in the array
endm
call ZTimerOff
```

## Listing 10-3

```nasm
;
; *** Listing 10-3 ***
;
; Loads a byte into AL 1000 times via MOV, with no
; INC performed.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
ByteArray db ARRAY_LENGTH dup (0)
;
Skip:
call ZTimerOn
mov si,offset ByteArray
;point to the start of the array
rept ARRAY_LENGTH
mov al,[si] ;get this array byte but don't point
; to the next byte in the array
endm
call ZTimerOff
```

## Listing 10-4

```nasm
;
; *** Listing 10-4 ***
;
; Searches a word-sized array for the first element
; greater than 10,000, using non-string instructions.
;
jmp Skip
;
WordArray dw 1000 dup (0), 10001
;
Skip:
call ZTimerOn
mov di,offset WordArray-2
;start 1 word early so the
; first preincrement points
; to the first element
mov ax,10000 ;value we'll compare with
SearchLoop:
inc di ;point to the next element
inc di
cmp ax,[di] ;compare the next element
; to 10,000
jae SearchLoop ;if not greater than 10,000,
; do the next element
call ZTimerOff
```

## Listing 10-5

```nasm
;
; *** Listing 10-5 ***
;
; Searches a word-sized array for the first element
; greater than 10,000, using SCASW.
;
jmp Skip
;
WordArray dw 1000 dup (0), 10001
;
Skip:
call ZTimerOn
mov di,seg WordArray
mov es,di ;SCASW always uses ES:SI as a
; memory pointer
mov di,offset WordArray
mov ax,10000 ;value we'll compare with
cld ;make SCASW add 2 to DI after
; each execution
SearchLoop:
scasw ;compare the next element to 10,000
jae SearchLoop ;if not greater than 10,000, do
; the next element
dec di ;point back to the matching word
dec di
call ZTimerOff
```

## Listing 10-6

```nasm
;
; *** Listing 10-6 ***
;
; Searches a word-sized array for the first element
; greater than 10,000, using LODSW & CMP.
;
jmp Skip
;
WordArray dw 1000 dup (0), 10001
;
Skip:
call ZTimerOn
mov si,offset WordArray
;array to search
mov dx,10000 ;value we'll compare with
cld ;make LODSW add 2 to SI after each
; execution
SearchLoop:
lodsw ;get the next element
cmp dx,ax ;compare the element to 10,000
jae SearchLoop ;if not greater than 10,000, do
; the next element
dec di ;point back to the matching word
dec di
call ZTimerOff
```

## Listing 10-7

```nasm
;
; *** Listing 10-7 ***
;
; Initializes a 1000-word array using a loop and
; non-string instructions.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
WordArray dw ARRAY_LENGTH dup (?)
;
Skip:
call ZTimerOn
mov di,offset WordArray
;point to array to fill
sub ax,ax ;we'll fill with the value zero
mov cx,ARRAY_LENGTH ;# of words to fill
ZeroLoop:
mov [di],ax ;zero one word
inc di ;point to the next word
inc di
loop ZeroLoop
call ZTimerOff
```

## Listing 10-8

```nasm
;
; *** Listing 10-8 ***
;
; Initializes a 1000-word array using a single
; repeated STOSW.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
WordArray dw ARRAY_LENGTH dup (?)
;
Skip:
call ZTimerOn
mov di,seg WordArray
mov es,di
mov di,offset WordArray
;point ES:DI to the array to
; fill, since STOSW must
; use that segment:offset combo
; as a memory pointer
sub ax,ax ;we'll fill with the value zero
mov cx,ARRAY_LENGTH ;# of words to fill
cld ;make STOSW add 2 to DI after each
; execution
rep stosw ;fill the array
call ZTimerOff
```

## Listing 10-9

```nasm
;
; *** Listing 10-9 ***
;
; Sets every element of a 1000-byte array to 1 by
; repeating STOSB 1000 times.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
ByteArray db ARRAY_LENGTH dup (?)
;
Skip:
call ZTimerOn
mov di,seg ByteArray
mov es,di ;point ES:DI to the array to fill
mov di,offset ByteArray
mov al,1 ;we'll fill with the value 1
mov cx,ARRAY_LENGTH ;# of bytes to fill
cld ;make STOSB increment DI after
; each execution
rep stosb ;initialize the array
call ZTimerOff
```

## Listing 10-10

```nasm
;
; *** Listing 10-10 ***
;
; Sets every element of a 1000-byte array to 1 by
; repeating STOSW 500 times.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
WordArray db ARRAY_LENGTH dup (?)
;
Skip:
call ZTimerOn
mov di,seg WordArray
mov es,di ;point ES:DI to the array to fill
mov di,offset WordArray
mov ax,(1 shl 8) + 1
;fill each byte with the value 1
mov cx,ARRAY_LENGTH/2 ;# of words to fill
cld ;make STOSW add 2 to DI on each
; execution
rep stosw ;fill a word at a time
call ZTimerOff
```

## Listing 10-11

```nasm
;
; *** Listing 10-11 ***
;
; Clears a 1000-byte block of memory via BlockClear,
; which handles blocks between 0 and 64K-1 bytes in
; length.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
ByteArray db ARRAY_LENGTH dup (?)
;
; Clears a block of memory CX bytes in length. A value
; of 0 means "clear zero bytes," so the maximum length
; that can be cleared is 64K-1 bytes and the minimum
; length is 0 bytes.
;
; Input:
; CX = number of bytes to clear
; ES:DI = start of block to clear
;
; Output:
; none
;
; Registers altered: AL, CX, DI
;
; Direction flag cleared
;
BlockClear:
sub al,al ;fill with zero
cld ;make STOSB move DI up
rep stosb ;clear the block
ret
;
Skip:
call ZTimerOn
mov di,seg ByteArray
mov es,di ;point ES:DI to the array to clear
mov di,offset ByteArray
mov cx,ARRAY_LENGTH ;# of bytes to clear
call BlockClear ;clear the array
call ZTimerOff
```

## Listing 10-12

```nasm
;
; *** Listing 10-12 ***
;
; Clears a 1000-byte block of memory via BlockClear64,
; which handles blocks between 1 and 64K bytes in
; length. BlockClear64 gains the ability to handle
; 64K blocks by using STOSW rather than STOSB to
; the greatest possible extent, getting a performance
; boost in the process.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
ByteArray db ARRAY_LENGTH dup (?)
;
; Clears a block of memory CX bytes in length. A value
; of 0 means "clear 64K bytes," so the maximum length
; that can be cleared is 64K bytes and the minimum length
; is 1 byte.
;
; Input:
; CX = number of bytes to clear
; ES:DI = start of block to clear
;
; Output:
; none
;
; Registers altered: AX, CX, DI
;
; Direction flag cleared
;
BlockClear64:
sub ax,ax ;fill with zero a word at a time
stc ;assume the count is zero-setting
; the Carry flag will give us 8000h
; after the RCR
jcxz DoClear ;the count is zero
clc ;it's not zero
DoClear:
rcr cx,1 ;divide by 2, copying the odd-byte
; status to the Carry flag and
; shifting a 1 into bit 15 if and
; only if the count is zero
cld ;make STOSW move DI up
rep stosw ;clear the block
jnc ClearDone
;the Carry status is still left over
; from the RCR. If we had an even #
; of bytes, we're done
stosb ;clear the odd byte
ClearDone:
ret
;
Skip:
call ZTimerOn
mov di,seg ByteArray
mov es,di ;point ES:DI to the array to clear
mov di,offset ByteArray
mov cx,ARRAY_LENGTH ;# of bytes to clear
call BlockClear64 ;clear the array
call ZTimerOff
```

## Listing 10-13

```nasm
;
; *** Listing 10-13 ***
;
; Clears a 1000-byte block of memory via BlockClearW,
; which handles blocks between 0 and 64K-1 bytes in
; length. BlockClearW uses STOSW rather than STOSB to
; the greatest possible extent in order to improve
; performance.
;
jmp Skip
;
ARRAY_LENGTH equ 1000
ByteArray db ARRAY_LENGTH dup (?)
;
; Clears a block of memory CX bytes in length. A value
; of 0 means "clear zero bytes," so the maximum length
; that can be cleared is 64K-1 bytes and the minimum
; length is 0 bytes.
;
; Input:
; CX = number of bytes to clear
; ES:DI = start of block to clear
;
; Output:
; none
;
; Registers altered: AX, CX, DI
;
; Direction flag cleared
;
BlockClearW:
sub ax,ax ;we'll fill with the value 0
shr cx,1 ;divide by 2, copying the odd-byte
; status to the Carry flag
cld ;make STOSW move DI up
rep stosw ;clear the block
jnc ClearDone
;the Carry status is still left over
; from the SHR. If we had an even #
; of bytes, we're done
stosb ;clear the odd byte
ClearDone:
ret
;
Skip:
call ZTimerOn
mov di,seg ByteArray
mov es,di ;point ES:DI to the array to clear
mov di,offset ByteArray
mov cx,ARRAY_LENGTH ;# of bytes to clear
call BlockClearW ;clear the array
call ZTimerOff
```

## Listing 10-14

```nasm
;
; *** Listing 10-14 ***
;
; Generates the 8-bit checksum of a 1000-byte array
; using LODS with an ES: override.
;
jmp Skip
;
FarSeg segment para
ARRAY_LENGTH equ 1000
ByteArray db ARRAY_LENGTH dup (0)
FarSeg ends
Skip:
call ZTimerOn
mov si,seg ByteArray
mov es,si ;point ES:SI to the array to
; checksum
mov si,offset ByteArray
mov cx,ARRAY_LENGTH ;# of bytes to checksum
sub ah,ah ;zero the checksum counter
cld ;make LODS move the pointer up
ChecksumLoop:
lods byte ptr es:[si]
;get the next byte to checksum
add ah,al ;add the byte into the checksum
loop ChecksumLoop
call ZTimerOff
```

## Listing 10-15

```nasm
;
; *** Listing 10-15 ***
;
; Generates the 8-bit checksum of a 1000-byte array
; using LODS without a segment override, by setting
; DS up to point to the far segment for the duration
; of the loop.
;
jmp Skip
;
FarSeg segment para
ARRAY_LENGTH equ 1000
ByteArray db ARRAY_LENGTH dup (0)
FarSeg ends
Skip:
call ZTimerOn
push ds ;preserve the normal DS setting
mov si,seg ByteArray
mov ds,si ;point DS to the far segment for
; the duration of the loop-we
; won't need the normal DS setting
; until the loop is done
mov si,offset ByteArray
mov cx,ARRAY_LENGTH
sub ah,ah ;zero the checksum counter
cld ;make LODSB move the pointer up
ChecksumLoop:
lodsb ;get the next byte to checksum
add ah,al ;add the byte into the checksum
loop ChecksumLoop
pop ds ;retrieve the normal DS setting
call ZTimerOff
```

## Listing 10-16

```nasm
;
; *** Listing 10-16 ***
;
; Reads a single byte stored in a far segment by
; using a segment override prefix.
;
jmp Skip
;
FarSeg segment para
MemVar db 0 ;this variable resides in a
; far segment
FarSeg ends
;
Skip:
call ZTimerOn
rept 100
mov si,seg MemVar
mov es,si
mov si,offset MemVar ;point ES:SI to MemVar
lods byte ptr es:[si] ;read MemVar
endm
call ZTimerOff
```

## Listing 10-17

```nasm
;
; *** Listing 10-17 ***
;
; Reads a single byte stored in a far segment by
; temporarily pointing DS to the far segment.
;
jmp Skip
;
FarSeg segment para
MemVar db 0 ;this variable resides in a
; far segment
FarSeg ends
;
Skip:
call ZTimerOn
rept 100
push ds ;preserve the normal data segment
mov si,seg MemVar
mov ds,si
mov si,offset MemVar ;point DS:SI to MemVar
lodsb ;read MemVar
pop ds ;retrieve the normal data segment
endm
call ZTimerOff
```

## Listing 10-18

```nasm
;
; *** Listing 10-18 ***
;
; Reads a single byte stored in a far segment by
; using a segment override prefix. Loads ES just
; once and then leaves ES set to point to the far
; segment at all times.
;
jmp Skip
;
FarSeg segment para
MemVar db 0 ;this variable resides in a
; far segment
FarSeg ends
;
Skip:
call ZTimerOn
mov si,seg MemVar
mov es,si ;point ES to the far segment for
; the remainder of the test
rept 100
mov si,offset MemVar ;point ES:SI to MemVar
lods byte ptr es:[si] ;read MemVar
endm
call ZTimerOff
```

## Listing 10-19

```nasm
;
; *** Listing 10-19 ***
;
; Generates the 8-bit checksum of a 1000-byte array
; by loading both segment and offset from a far
; pointer each time through the loop and without
; using string instructions, as the code generated
; by a typical high-level language compiler would.
;
jmp Skip
;
FarSeg segment para
ARRAY_LENGTH equ 1000
ByteArray db ARRAY_LENGTH dup (0)
;this array resides in a
; far segment
FarSeg ends
;
FarPtr dd ByteArray ;a far pointer to the array
;
Skip:
call ZTimerOn
mov cx,ARRAY_LENGTH ;# of bytes to checksum
sub ah,ah ;zero the checksum counter
ChecksumLoop:
les bx,[FarPtr] ;load both segment and
; offset from the far
; pointer
inc word ptr [FarPtr]
;advance the offset portion
; of the far pointer
add ah,es:[bx] ;add the next byte to the
; checksum
loop ChecksumLoop
call ZTimerOff
```

## Listing 11-1

```nasm
;
; *** Listing 11-1 ***
;
; Copies a string to another string, converting all
; characters to uppercase in the process, using a loop
; containing LODSB and STOSB.
;
jmp Skip
;
SourceString label word
db 'This space intentionally left not blank',0
DestString db 100 dup (?)
;
; Copies one zero-terminated string to another string,
; converting all characters to uppercase.
;
; Input:
; DS:SI = start of source string
; ES:DI = start of destination string
;
; Output:
; none
;
; Registers altered: AL, BX, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries. Does not handle
; overlapping strings.
;
CopyStringUpper:
mov bl,'a' ;set up for fast register-register
mov bh,'z' ; comparisons
cld
StringUpperLoop:
lodsb ;get the next character and
; point to the following character
cmp al,bl ;below 'a'?
jb IsUpper ;yes, not lowercase
cmp al,bh ;above 'z'?
ja IsUpper ;yes, not lowercase
and al,not 20h ;is lowercase-make uppercase
IsUpper:
stosb ;put the uppercase character into
; the new string and point to the
; following character
and al,al ;is this the zero that marks the
; end of the string?
jnz StringUpperLoop ;no, do the next character
ret
;
Skip:
call ZTimerOn
mov si,offset SourceString ;point DS:SI to the
; string to copy from
mov di,seg DestString
mov es,di ;point ES:DI to the
mov di,offset DestString ; string to copy to
call CopyStringUpper ;copy & convert to
; uppercase
call ZTimerOff
```

## Listing 11-2

```nasm
;
; *** Listing 11-2 ***
;
; Copies a string to another string, converting all
; characters to uppercase in the process, using a loop
; containing non-string instructions.
;
jmp Skip
;
SourceString label word
db 'This space intentionally left not blank',0
DestString db 100 dup (?)
;
; Copies one zero-terminated string to another string,
; converting all characters to uppercase.
;
; Input:
; DS:SI = start of source string
; ES:DI = start of destination string
;
; Output:
; none
;
; Registers altered: AL, BX, SI, DI
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CopyStringUpper:
mov bl,'a' ;set up for fast register-register
mov bh,'z' ; comparisons
StringUpperLoop:
mov al,[si] ;get the next character
inc si ;point to the following character
cmp al,bl ;below 'a'?
jb IsUpper ;yes, not lowercase
cmp al,bh ;above 'z'?
ja IsUpper ;yes, not lowercase
and al,not 20h ;is lowercase-make uppercase
IsUpper:
mov es:[di],al ;put the uppercase character into
; the new string
inc di ;point to the following character
and al,al ;is this the zero that marks the
; end of the string?
jnz StringUpperLoop ;no, do the next character
ret
;
Skip:
call ZTimerOn
mov si,offset SourceString ;point DS:SI to the
; string to copy from
mov di,seg DestString
mov es,di ;point ES:DI to the
mov di,offset DestString ; string to copy to
call CopyStringUpper ;copy & convert to
; uppercase
call ZTimerOff
```

## Listing 11-3

```nasm
;
; *** Listing 11-3 ***
;
; Converts all characters in a string to uppercase,
; using a loop containing LODSB and STOSB and using
; two pointers.
;
jmp Skip
;
SourceString label word
db 'This space intentionally left not blank',0
;
; Copies one zero-terminated string to another string,
; converting all characters to uppercase.
;
; Input:
; DS:SI = start of source string
; ES:DI = start of destination string
;
; Output:
; none
;
; Registers altered: AL, BX, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CopyStringUpper:
mov bl,'a' ;set up for fast register-register
mov bh,'z' ; comparisons
cld
StringUpperLoop:
lodsb ;get the next character and
; point to the following character
cmp al,bl ;below 'a'?
jb IsUpper ;yes, not lowercase
cmp al,bh ;above 'z'?
ja IsUpper ;yes, not lowercase
and al,not 20h ;is lowercase-make uppercase
IsUpper:
stosb ;put the uppercase character into
; the new string and point to the
; following character
and al,al ;is this the zero that marks the
; end of the string?
jnz StringUpperLoop ;no, do the next character
ret
;
Skip:
call ZTimerOn
mov si,offset SourceString ;point DS:SI to the
; string to convert
mov di,ds
mov es,di ;point ES:DI to the
mov di,si ; same string
call CopyStringUpper ;convert to
; uppercase in place
call ZTimerOff
```

## Listing 11-4

```nasm
;
; *** Listing 11-4 ***
;
; Converts all characters in a string to uppercase,
; using a loop containing non-string instructions
; and using only one pointer.
;
jmp Skip
;
SourceString label word
db 'This space intentionally left not blank',0
;
; Converts a string to uppercase.
;
; Input:
; DS:SI = start of string
;
; Output:
; none
;
; Registers altered: AL, BX, SI
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
StringToUpper:
mov bl,'a' ;set up for fast register-register
mov bh,'z' ; comparisons
StringToUpperLoop:
mov al,[si] ;get the next character
cmp al,bl ;below 'a'?
jb IsUpper ;yes, not lowercase
cmp al,bh ;above 'z'?
ja IsUpper ;yes, not lowercase
and al,not 20h ;is lowercase-make uppercase
IsUpper:
mov [si],al ;put the uppercase character back
inc si ; into the string and point to the
; following character
and al,al ;is this the zero that marks the
; end of the string?
jnz StringToUpperLoop ;no, do the next character
ret
;
Skip:
call ZTimerOn
mov si,offset SourceString ;point to the string
; to convert
call StringToUpper ;convert it to
; uppercase
call ZTimerOff
```

## Listing 11-5

```nasm
; *** Listing 11-5 ***
;
; Sets the high bit of every element in a byte
; array using LODSB and STOSB.
;
jmp Skip
;
;
ARRAY_LENGTH equ 1000
ByteArray db ARRAY_LENGTH dup (?)
;
Skip:
call ZTimerOn
mov si,offset ByteArray ;point to the array
mov di,ds ; as both source and
mov es,di ; destination
mov di,si
mov cx,ARRAY_LENGTH
mov ah,80h ;bit pattern to OR
cld
SetHighBitLoop:
lodsb ;get the next byte
or al,ah ;set the high bit
stosb ;save the byte
loop SetHighBitLoop
call ZTimerOff
```

## Listing 11-6

```nasm
; *** Listing 11-6 ***
;
; Sets the high bit of every element in a byte
; array by ORing directly to memory.
;
jmp Skip
;
;
ARRAY_LENGTH equ 1000
ByteArray db ARRAY_LENGTH dup (?)
;
Skip:
call ZTimerOn
mov si,offset ByteArray ;point to the array
mov cx,ARRAY_LENGTH
mov al,80h ;bit pattern to OR
SetHighBitLoop:
or [si],al ;set the high bit
inc si ;point to the next
; byte
loop SetHighBitLoop
call ZTimerOff
```

## Listing 11-7

```nasm
;
; *** Listing 11-7 ***
;
; Copies overlapping blocks of memory with MOVS.
; To the greatest possible extent, the copy is
; performed a word at a time.
;
jmp Skip
;
TEST_LENGTH1 equ 501 ;sample copy length #1
TEST_LENGTH2 equ 1499 ;sample copy length #2
TestArray db 1500 dup (0)
;
; Copies a block of memory CX bytes in length. A value
; of 0 means "copy zero bytes," since it wouldn't make
; much sense to copy one 64K block to another 64K block
; in the same segment, so the maximum length that can
; be copied is 64K-1 bytes and the minimum length
; is 0 bytes. Note that both blocks must be in DS. Note
; also that overlap handling is not guaranteed if either
; block wraps at the end of the segment.
;
; Input:
; CX = number of bytes to clear
; DS:SI = start of block to copy
; DS:DI = start of destination block
;
; Output:
; none
;
; Registers altered: CX, DX, SI, DI, ES
;
; Direction flag cleared
;
BlockCopyWithOverlap:
mov dx,ds ;source and destination are in the
mov es,dx ; same segment
cmp si,di ;which way do the blocks overlap, if
; they do overlap?
jae LowToHigh
;source is not below destination, so
; we can copy from low to high

;source is below destination, so we
; must copy from high to low
add si,cx ;point to the end of the source
dec si ; block
add di,cx ;point to the end of the destination
dec di ; block
std ;copy from high addresses to low
shr cx,1 ;divide by 2, copying the odd-byte
; status to the Carry flag
jnc CopyWordHighToLow ;no odd byte to copy
movsb ;copy the odd byte
CopyWordHighToLow:
dec si ;point one word lower in memory, not
dec di ; one byte
rep movsw ;move the rest of the block
cld
ret
;
LowToHigh:
cld ;copy from low addresses to high
shr cx,1 ;divide by 2, copying the odd-byte
; status to the Carry flag
jnc CopyWordLowToHigh ;no odd byte to copy
movsb ;copy the odd byte
CopyWordLowToHigh:
rep movsw ;move the rest of the block
ret
;
Skip:
call ZTimerOn
;
; First run the case where the destination overlaps & is
; higher in memory.
;
mov si,offset TestArray
mov di,offset TestArray+1
mov cx,TEST_LENGTH1
call BlockCopyWithOverlap
;
; Now run the case where the destination overlaps & is
; lower in memory.
;
mov si,offset TestArray+1
mov di,offset TestArray
mov cx,TEST_LENGTH2
call BlockCopyWithOverlap
call ZTimerOff
```

## Listing 11-8

```nasm
;
; *** Listing 11-8 ***
;
; Copies overlapping blocks of memory with
; non-string instructions. To the greatest possible
; extent, the copy is performed a word at a time.
;
jmp Skip
;
TEST_LENGTH1 equ 501 ;sample copy length #1
TEST_LENGTH2 equ 1499 ;sample copy length #2
TestArray db 1500 dup (0)
;
; Copies a block of memory CX bytes in length. A value
; of 0 means "copy zero bytes," since it wouldn't make
; much sense to copy one 64K block to another 64K block
; in the same segment, so the maximum length that can
; be copied is 64K-1 bytes and the minimum length
; is 0 bytes. Note that both blocks must be in DS. Note
; also that overlap handling is not guaranteed if either
; block wraps at the end of the segment.
;
; Input:
; CX = number of bytes to clear
; DS:SI = start of block to copy
; DS:DI = start of destination block
;
; Output:
; none
;
; Registers altered: AX, CX, DX, SI, DI
;
BlockCopyWithOverlap:
jcxz BlockCopyWithOverlapDone
;guard against zero block size,
; since LOOP will execute 64K times
; when started with CX=0
mov dx,2 ;amount by which to adjust the
; pointers in the word-copy loop
cmp si,di ;which way do the blocks overlap, if
; they do overlap?
jae LowToHigh
;source is not below destination, so
; we can copy from low to high

;source is below destination, so we
; must copy from high to low
add si,cx ;point to the end of the source
dec si ; block
add di,cx ;point to the end of the destination
dec di ; block
shr cx,1 ;divide by 2, copying the odd-byte
; status to the Carry flag
jnc CopyWordHighToLow ;no odd byte to copy
mov al,[si] ;copy the odd byte
mov [di],al
dec si ;advance both pointers
dec di
CopyWordHighToLow:
dec si ;point one word lower in memory, not
dec di ; one byte
HighToLowCopyLoop:
mov ax,[si] ;copy a word
mov [di],ax
sub si,dx ;advance both pointers 1 word
sub di,dx
loop HighToLowCopyLoop
ret
;
LowToHigh:
shr cx,1 ;divide by 2, copying the odd-byte
; status to the Carry flag
jnc LowToHighCopyLoop ;no odd byte to copy
mov al,[si] ;copy the odd byte
mov [di],al
inc si ;advance both pointers
inc di
LowToHighCopyLoop:
mov ax,[si] ;copy a word
mov [di],ax
add si,dx ;advance both pointers 1 word
add di,dx
loop LowToHighCopyLoop
BlockCopyWithOverlapDone:
ret
;
Skip:
call ZTimerOn
;
; First run the case where the destination overlaps & is
; higher in memory.
;
mov si,offset TestArray
mov di,offset TestArray+1
mov cx,TEST_LENGTH1
call BlockCopyWithOverlap
;
; Now run the case where the destination overlaps & is
; lower in memory.
;
mov si,offset TestArray+1
mov di,offset TestArray
mov cx,TEST_LENGTH2
call BlockCopyWithOverlap
call ZTimerOff
```

## Listing 11-9

```nasm
;
; *** Listing 11-9 ***
;
; Counts the number of times the letter 'A'
; appears in a byte-sized array, using non-string
; instructions.
;
jmp Skip
;
ByteArray label byte
db 'ARRAY CONTAINING THE LETTER ''A'' 4 TIMES'
ARRAY_LENGTH equ ($-ByteArray)
;
; Counts the number of occurrences of the specified byte
; in the specified byte-sized array.
;
; Input:
; AL = byte of which to count occurrences
; CX = array length (0 means 64K)
; DS:DI = array to count byte occurrences in
;
; Output:
; DX = number of occurrences of the specified byte
;
; Registers altered: CX, DX, DI
;
; Note: Does not handle arrays that are longer than 64K
; bytes or cross segment boundaries.
;
ByteCount:
sub dx,dx ;set occurrence counter to 0
dec di ;compensate for the initial
; upcoming INC DI
and cx,cx ;64K long?
jnz ByteCountLoop ;no
dec cx ;yes, so handle first byte
; specially, since JCXZ will
; otherwise conclude that
; we're done right away
inc di ;point to first byte
cmp [di],al ;is this byte the value
; we're looking for?
jz ByteCountCountOccurrence
;yes, so count it
ByteCountLoop:
jcxz ByteCountDone ;done if we've checked all
; the bytes in the array
dec cx ;count off the byte we're
; about to check
inc di ;point to the next byte to
; check
cmp [di],al ;see if this byte contains
; the value we're counting
jnz ByteCountLoop ;no match
ByteCountCountOccurrence:
inc dx ;count this occurrence
jmp ByteCountLoop ;check the next byte, if any
ByteCountDone:
ret
;
Skip:
call ZTimerOn
mov al,'A' ;byte of which we want a
; count of occurrences
mov di,offset ByteArray
;array we want a count for
mov cx,ARRAY_LENGTH ;# of bytes to check
call ByteCount ;get the count
call ZTimerOff
```

## Listing 11-10

```nasm
;
; *** Listing 11-10 ***
;
; Counts the number of times the letter 'A'
; appears in a byte-sized array, using REPNZ SCASB.
;
jmp Skip
;
ByteArray label byte
db 'ARRAY CONTAINING THE LETTER ''A'' 4 TIMES'
ARRAY_LENGTH equ ($-ByteArray)
;
; Counts the number of occurrences of the specified byte
; in the specified byte-sized array.
;
; Input:
; AL = byte of which to count occurrences
; CX = array length (0 means 64K)
; DS:DI = array to count byte occurrences in
;
; Output:
; DX = number of occurrences of the specified byte
;
; Registers altered: CX, DX, DI, ES
;
; Direction flag cleared
;
; Note: Does not handle arrays that are longer than 64K
; bytes or cross segment boundaries. Does not handle
; overlapping strings.
;
ByteCount:
push ds
pop es ;SCAS uses ES:DI
sub dx,dx ;set occurrence counter to 0
cld
and cx,cx ;64K long?
jnz ByteCountLoop ;no
dec cx ;yes, so handle first byte
; specially, since JCXZ will
; otherwise conclude that
; we're done right away
scasb ;is first byte a match?
jz ByteCountCountOccurrence
;yes, so count it
ByteCountLoop:
jcxz ByteCountDone ;if there's nothing left to
; search, we're done
repnz scasb ;search for the next byte
; occurrence or the end of
; the array
jnz ByteCountDone ;no match
ByteCountCountOccurrence:
inc dx ;count this occurrence
jmp ByteCountLoop ;check the next byte, if any
ByteCountDone:
ret
;
Skip:
call ZTimerOn
mov al,'A' ;byte of which we want a
; count of occurrences
mov di,offset ByteArray
;array we want a count for
mov cx,ARRAY_LENGTH ;# of bytes to check
call ByteCount ;get the count
call ZTimerOff
```

## Listing 11-11

```nasm
;
; *** Listing 11-11 ***
;
; Finds the first occurrence of the letter 'z' in
; a zero-terminated string, using LODSB.
;
jmp Skip
;
TestString label byte
db 'This is a test string that is '
db 'z'
db 'terminated with a zero byte...',0
;
; Finds the first occurrence of the specified byte in the
; specified zero-terminated string.
;
; Input:
; AL = byte to find
; DS:SI = zero-terminated string to search
;
; Output:
; SI = pointer to first occurrence of byte in string,
; or 0 if the byte wasn't found
;
; Registers altered: AX, SI
;
; Direction flag cleared
;
; Note: Do not pass a string that starts at offset 0 (SI=0),
; since a match on the first byte and failure to find
; the byte would be indistinguishable.
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
FindCharInString:
mov ah,al ;we'll need AL since that's the
; only register LODSB can use
cld
FindCharInStringLoop:
lodsb ;get the next string byte
cmp al,ah ;is this the byte we're
; looking for?
jz FindCharInStringDone
;yes, so we're done
and al,al ;is this the terminating zero?
jnz FindCharInStringLoop
;no, so check the next byte
sub si,si ;we didn't find a match, so return
; 0 in SI
ret
FindCharInStringDone:
dec si ;point back to the matching byte
ret
;
Skip:
call ZTimerOn
mov al,'z' ;byte value to find
mov si,offset TestString
;string to search
call FindCharInString ;search for the byte
call ZTimerOff
```

## Listing 11-12

```nasm
;
; *** Listing 11-12 ***
;
; Finds the first occurrence of the letter 'z' in
; a zero-terminated string, using REPNZ SCASB in a
; double-search approach, first finding the terminating
; zero to determine the string length, and then searching
; for the desired byte.
;
jmp Skip
;
TestString label byte
db 'This is a test string that is '
db 'z'
db 'terminated with a zero byte...',0
;
; Finds the first occurrence of the specified byte in the
; specified zero-terminated string.
;
; Input:
; AL = byte to find
; DS:SI = zero-terminated string to search
;
; Output:
; SI = pointer to first occurrence of byte in string,
; or 0 if the byte wasn't found
;
; Registers altered: AH, CX, SI, DI, ES
;
; Direction flag cleared
;
; Note: Do not pass a string that starts at offset 0 (SI=0),
; since a match on the first byte and failure to find
; the byte would be indistinguishable.
;
; Note: If the search value is 0, will not find the
; terminating zero in a string that is exactly 64K
; bytes long. Does not handle strings that are longer
; than 64K bytes or cross segment boundaries.
;
FindCharInString:
mov ah,al ;set aside the byte to be found
sub al,al ;we'll search for zero
push ds
pop es
mov di,si ;SCAS uses ES:DI
mov cx,0ffffh ;long enough to handle any string
; up to 64K-1 bytes in length, and
; will handle 64K case except when
; the search value is the terminating
; zero
cld
repnz scasb ;find the terminating zero
not cx ;length of string in bytes, including
; the terminating zero except in the
; case of a string that's exactly 64K
; long including the terminating zero
mov al,ah ;get back the byte to be found
mov di,si ;point to the start of the string again
repnz scasb ;search for the byte of interest
jnz FindCharInStringNotFound
;the byte isn't present in the string
dec di ;we've found the desired value. Point
; back to the matching location
mov si,di ;return the pointer in SI
ret
FindCharInStringNotFound:
sub si,si ;return a 0 pointer indicating that
; no match was found
ret
;
Skip:
call ZTimerOn
mov al,'z' ;byte value to find
mov si,offset TestString
;string to search
call FindCharInString ;search for the byte
call ZTimerOff
```

## Listing 11-13

```nasm
;
; *** Listing 11-13 ***
;
; Finds the first occurrence of the letter 'z' in
; a zero-terminated string, using non-string instructions.
;
jmp Skip
;
TestString label byte
db 'This is a test string that is '
db 'z'
db 'terminated with a zero byte...',0
;
; Finds the first occurrence of the specified byte in the
; specified zero-terminated string.
;
; Input:
; AL = byte to find
; DS:SI = zero-terminated string to search
;
; Output:
; SI = pointer to first occurrence of byte in string,
; or 0 if the byte wasn't found
;
; Registers altered: AH, SI
;
; Note: Do not pass a string that starts at offset 0 (SI=0),
; since a match on the first byte and failure to find
; the byte would be indistinguishable.
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
FindCharInString:
FindCharInStringLoop:
mov ah,[si] ;get the next string byte
cmp ah,al ;is this the byte we're
; looking for?
jz FindCharInStringDone
;yes, so we're done
inc si ;point to the following byte
and ah,ah ;is this the terminating zero?
jnz FindCharInStringLoop
;no, so check the next byte
sub si,si ;we didn't find a match, so return
; 0 in SI
FindCharInStringDone:
ret
;
Skip:
call ZTimerOn
mov al,'z' ;byte value to find
mov si,offset TestString
;string to search
call FindCharInString ;search for the byte
call ZTimerOff
```

## Listing 11-14

```nasm
; *** Listing 11-14 ***
;
; Finds the first occurrence of the letter 'z' in
; a zero-terminated string, using LODSW and checking
; 2 bytes per read.
;
jmp Skip
;
TestString label byte
db 'This is a test string that is '
db 'z'
db 'terminated with a zero byte...',0
;
; Finds the first occurrence of the specified byte in the
; specified zero-terminated string.
;
; Input:
; AL = byte to find
; DS:SI = zero-terminated string to search
;
; Output:
; SI = pointer to first occurrence of byte in string,
; or 0 if the byte wasn't found
;
; Registers altered: AX, BL, SI
;
; Direction flag cleared
;
; Note: Do not pass a string that starts at offset 0 (SI=0),
; since a match on the first byte and failure to find
; the byte would be indistinguishable.
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
FindCharInString:
mov bl,al ;we'll need AX since that's the
; only register LODSW can use
cld
FindCharInStringLoop:
lodsw ;get the next 2 string bytes
cmp al,bl ;is the first byte the byte we're
; looking for?
jz FindCharInStringDoneAdjust
;yes, so we're done after we adjust
; back to the first byte of the word
and al,al ;is the first byte the terminating
; zero?
jz FindCharInStringNoMatch ;yes, no match
cmp ah,bl ;is the second byte the byte we're
; looking for?
jz FindCharInStringDone
;yes, so we're done
and ah,ah ;is the second byte the terminating
; zero?
jnz FindCharInStringLoop
;no, so check the next 2 bytes
FindCharInStringNoMatch:
sub si,si ;we didn't find a match, so return
; 0 in SI
ret
FindCharInStringDoneAdjust:
dec si ;adjust to the first byte of the
; word we just read
FindCharInStringDone:
dec si ;point back to the matching byte
ret
;
Skip:
call ZTimerOn
mov al,'z' ;byte value to find
mov si,offset TestString
;string to search
call FindCharInString ;search for the byte
call ZTimerOff
```

## Listing 11-15

```nasm
;
; *** Listing 11-15 ***
;
; Finds the last non-blank character in a string, using
; LODSW and checking 2 bytes per read.
;
jmp Skip
;
TestString label byte
db 'This is a test string with blanks....'
db ' ',0
;
; Finds the last non-blank character in the specified
; zero-terminated string.
;
; Input:
; DS:SI = zero-terminated string to search
;
; Output:
; SI = pointer to last non-blank character in string,
; or 0 if there are no non-blank characters in
; the string
;
; Registers altered: AX, BL, DX, SI
;
; Direction flag cleared
;
; Note: Do not pass a string that starts at offset 0 (SI=0),
; since a return pointer to the first byte and failure
; to find a non-blank character would be
; indistinguishable.
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
FindLastNonBlankInString:
mov dx,1 ;so far we haven't found a non-blank
; character
mov bl,' ' ;put our search character, the space
; character, in a register for speed
cld
FindLastNonBlankInStringLoop:
lodsw ;get the next 2 string bytes
and al,al ;is the first byte the terminating
; zero?
jz FindLastNonBlankInStringDone
;yes, we're done
cmp al,bl ;is the second byte a space?
jz FindLastNonBlankInStringNextChar
;yes, so check the next character
mov dx,si ;remember where the non-blank was
dec dx ;adjust back to first byte of word
FindLastNonBlankInStringNextChar:
and ah,ah ;is the second byte the terminating
; zero?
jz FindLastNonBlankInStringDone
;yes, we're done
cmp ah,bl ;is the second byte a space?
jz FindLastNonBlankInStringLoop
;yes, so check the next 2 bytes
mov dx,si ;remember where the non-blank was
jmp FindLastNonBlankInStringLoop
;check the next 2 bytes
FindLastNonBlankInStringDone:
dec dx ;point back to the last non-blank
; character, correcting for the
; 1-byte overrun of LODSW
mov si,dx ;return pointer to last non-blank
; character in SI
ret
;
Skip:
call ZTimerOn
mov si,offset TestString ;string to search
call FindLastNonBlankInString ;search for the byte
call ZTimerOff
```

## Listing 11-16

```nasm
;
; *** Listing 11-16 ***
;
; Finds the last non-blank character in a string, using
; REPNZ SCASB to find the end of the string and then using
; REPZ SCASW from the end of the string to find the last
; non-blank character.
;
jmp Skip
;
TestString label byte
db 'This is a test string with blanks....'
db ' ',0
;
; Finds the last non-blank character in the specified
; zero-terminated string.
;
; Input:
; DS:SI = zero-terminated string to search
;
; Output:
; SI = pointer to last non-blank character in string,
; or 0 if there are no non-blank characters in
; the string
;
; Registers altered: AX, CX, SI, DI, ES
;
; Direction flag cleared
;
; Note: Do not pass a string that starts at offset 0 (SI=0),
; since a return pointer to the first byte and failure
; to find a non-blank character would be
; indistinguishable.
;
; Note: If there is no terminating zero in the first 64K-1
; bytes of the string, it is assumed without checking
; that byte #64K-1 (the 1 byte in the segment that
; wasn't checked) is the terminating zero.
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
FindLastNonBlankInString:
push ds
pop es
mov di,si ;SCAS uses ES:DI
sub al,al ;first we'll search for the
; terminating zero
mov cx,0ffffh ;we'll search the longest possible
; string
cld
repnz scasb ;find the terminating zero
dec di ;point back to the zero
cmp [di],al ;make sure this is a zero.
; (Remember, ES=DS)
jnz FindLastNonBlankInStringSearchBack
; not a zero. The string must be
; exactly 64K bytes long, so we've
; come up 1 byte short of the zero
; that we're assuming is at byte
; 64K-1. That means we're already
; pointing to the byte before the
; zero
dec di ;point to the byte before the zero
inc cx ;don't count the terminating zero
; as one of the characters we've
; searched through (and have to
; search back through)
FindLastNonBlankInStringSearchBack:
std ;we'll search backward
not cx ;length of string, not including
; the terminating zero
mov ax,2020h ;now we're looking for a space
shr cx,1 ;divide by 2 to get a word count
jnc FindLastNonBlankInStringWord
scasb ;see if the odd byte is the last
; non-blank character
jnz FindLastNonBlankInStringFound
;it is, so we're done
FindLastNonBlankInStringWord:
jcxz FindLastNonBlankInStringNoMatch
;if there's nothing left to check,
; there are no non-blank characters
dec di ;point back to the start of the
; next word, not byte
repz scasw ;find the first non-blank character
jz FindLastNonBlankInStringNoMatch
;there is no non-blank character in
; this string
inc di ;undo 1 byte of SCASW's overrun, so
; this looks like SCASB's overrun
cmp [di+2],al ;which of the 2 bytes we just
; checked was the last non-blank
; character?
jz FindLastNonBlankInStringFound
inc di ;the byte at the higher address was
; the last non-blank character, so
; adjust by 1 byte
FindLastNonBlankInStringFound:
inc di ;point to the non-blank character
; we just found, correcting for
; overrun of SCASB running from high
; addresses to low
mov si,di ;return pointer to the last
; non-blank in SI
cld
ret
FindLastNonBlankInStringNoMatch:
sub si,si ;return that we didn't find a
; non-blank character
cld
ret
;
Skip:
call ZTimerOn
mov si,offset TestString ;string to search
call FindLastNonBlankInString ;search for the
; last non-blank
; character
call ZTimerOff
```

## Listing 11-17

```nasm
;
; *** Listing 11-17 ***
;
; Demonstrates the calculation of the offset of the word
; matching a keystroke in a look-up table when SCASW is
; used, where the 2-byte overrun of SCASW must be
; compensated for. The offset in the look-up table is used
; to look up the corresponding address in a second table;
; that address is then jumped to in order to handle the
; keystroke.
;
; This is a standalone program, not to be used with PZTIME
; but rather assembled, linked, and run by itself.
;
stack segment para stack 'STACK'
db 512 dup (?)
stack ends
;
code segment para public 'CODE'
assume cs:code, ds:nothing
;
; Main loop, which simply calls VectorOnKey until one of the
; key handlers ends the program.
;
start proc near
call VectorOnKey
jmp start
start endp
;
; Gets the next 16-bit key code from the BIOS, looks it up
; in KeyLookUpTable, and jumps to the corresponding routine
; according to KeyJumpTable. When the jumped-to routine
; returns, is will return to the code that called
; VectorOnKey. Ignores the key if the key code is not in the
; look-up table.
;
; Input: none
;
; Output: none
;
; Registers altered: AX, CX, DI, ES
;
; Direction flag cleared
;
; Table of 16-bit key codes this routine handles.
;
KeyLookUpTable label word
dw 0011bh ;Esc to exit
dw 01c0dh ;Enter to beep
;*** Additional key codes go here ***
KEY_LOOK_UP_TABLE_LENGTH_IN_WORDS equ (($-KeyLookUpTable)/2)
;
; Table of addresses to jump to when corresponding key codes
; in KeyLookUpTable are found.
;
KeyJumpTable label word
dw EscHandler
dw EnterHandler
;*** Additional addresses go here ***
;
VectorOnKey proc near
WaitKeyLoop:
mov ah,1 ;BIOS key status function
int 16h ;invoke BIOS to see if
; a key is pending
jz WaitKeyLoop ;wait until key comes along
sub ah,ah ;BIOS get key function
int 16h ;invoke BIOS to get the key
push cs
pop es
mov di,offset KeyLookUpTable
;point ES:DI to the table of keys
; we handle, which is in the same
; segment as this code
mov cx,KEY_LOOK_UP_TABLE_LENGTH_IN_WORDS
;# of words to scan
cld
repnz scasw ;look up the key
jnz WaitKeyLoop ;it's not in the table, so
; ignore it
jmp cs:[KeyJumpTable+di-2-offset KeyLookUpTable]
;jump to the routine for this key
; Note that:
; DI-2-offset KeyLookUpTable
; is the offset in KeyLookUpTable of
; the key we found, with the -2
; needed to compensate for the
; 2-byte (1-word) overrun of SCASW
VectorOnKey endp
;
; Code to handle Esc (ends the program).
;
EscHandler proc near
mov ah,4ch ;DOS terminate program function
int 21h ;exit program
EscHandler endp
;
; Code to handle Enter (beeps the speaker).
;
EnterHandler proc near
mov ax,0e07h ;AH=0E is BIOS print character
; function, AL=7 is bell (beep)
; character
int 10h ;tell BIOS to beep the speaker
ret
EnterHandler endp
;
code ends
end start
```

## Listing 11-18

```nasm
;
; *** Listing 11-18 ***
;
; Demonstrates the calculation of the element number in a
; look-up table of a byte matching the ASCII value of a
; keystroke when SCASB is used, where the 1-count
; overrun of SCASB must be compensated for. The element
; number in the look-up table is used to look up the
; corresponding address in a second table; that address is
; then jumped to in order to handle the keystroke.
;
; This is a standalone program, not to be used with PZTIME
; but rather assembled, linked, and run by itself.
;
stack segment para stack 'STACK'
db 512 dup (?)
stack ends
;
code segment para public 'CODE'
assume cs:code, ds:nothing
;
; Main loop, which simply calls VectorOnASCIIKey until one
; of the key handlers ends the program.
;
start proc near
call VectorOnASCIIKey
jmp start
start endp
;
; Gets the next 16-bit key code from the BIOS, looks up just
; the 8-bit ASCII portion in ASCIIKeyLookUpTable, and jumps
; to the corresponding routine according to
; ASCIIKeyJumpTable. When the jumped-to routine returns, it
; will return directly to the code that called
; VectorOnASCIIKey. Ignores the key if the key code is not
; in the look-up table.
;
; Input: none
;
; Output: none
;
; Registers altered: AX, CX, DI, ES
;
; Direction flag cleared
;
; Table of 8-bit ASCII codes this routine handles.
;
ASCIIKeyLookUpTable label word
db 02h ;Ctrl-B to beep
db 18h ;Ctrl-X to exit
;*** Additional ASCII codes go here ***
ASCII_KEY_LOOK_UP_TABLE_LENGTH equ ($-ASCIIKeyLookUpTable)
;
; Table of addresses to jump to when corresponding key codes
; in ASCIIKeyLookUpTable are found.
;
ASCIIKeyJumpTable label word
dw Beep
dw Exit
;*** Additional addresses go here ***
;
VectorOnASCIIKey proc near
WaitASCIIKeyLoop:
mov ah,1 ;BIOS key status function
int 16h ;invoke BIOS to see if
; a key is pending
jz WaitASCIIKeyLoop ;wait until key comes along
sub ah,ah ;BIOS get key function
int 16h ;invoke BIOS to get the key
push cs
pop es
mov di,offset ASCIIKeyLookUpTable
;point ES:DI to the table of keys
; we handle, which is in the same
; segment as this code
mov cx,ASCII_KEY_LOOK_UP_TABLE_LENGTH
;# of bytes to scan
cld
repnz scasb ;look up the key
jnz WaitASCIIKeyLoop ;it's not in the table, so
; ignore it
mov di,ASCII_KEY_LOOK_UP_TABLE_LENGTH-1
sub di,cx ;calculate the # of the element we
; found in ASCIIKeyLookUpTable.
; The -1 is needed to compensate for
; the 1-count overrun of SCAS
shl di,1 ;multiply by 2 in order to perform
; the look-up in word-sized
; ASCIIKeyJumpTable
jmp cs:[ASCIIKeyJumpTable+di]
;jump to the routine for this key
VectorOnASCIIKey endp
;
; Code to handle Ctrl-X (ends the program).
;
Exit proc near
mov ah,4ch ;DOS terminate program function
int 21h ;exit program
Exit endp
;
; Code to handle Ctrl-B (beeps the speaker).
;
Beep proc near
mov ax,0e07h ;AH=0E is BIOS print character
; function, AL=7 is bell (beep)
; character
int 10h ;tell BIOS to beep the speaker
ret
Beep endp
;
code ends
end start
```

## Listing 11-19

```nasm
;
; *** Listing 11-19 ***
;
; Tests whether several characters are in the set
; {A,Z,3,!} by using REPNZ SCASB.
;
jmp Skip
;
; List of characters in the set.
;
TestSet db "AZ3!"
TEST_SET_LENGTH equ ($-TestSet)
;
; Determines whether a given character is in TestSet.
;
; Input:
; AL = character to check for inclusion in TestSet
;
; Output:
; Z if character is in TestSet, NZ otherwise
;
; Registers altered: DI, ES
;
; Direction flag cleared
;
CheckTestSetInclusion:
push ds
pop es
mov di,offset TestSet
;point ES:DI to the set in which to
; check inclusion
mov cx,TEST_SET_LENGTH
;# of characters in TestSet
cld
repnz scasb ;search the set for this character
ret ;the success status is already in
; the Zero flag
;
Skip:
call ZTimerOn
mov al,'A'
call CheckTestSetInclusion ;check 'A'
mov al,'Z'
call CheckTestSetInclusion ;check 'Z'
mov al,'3'
call CheckTestSetInclusion ;check '3'
mov al,'!'
call CheckTestSetInclusion ;check '!'
mov al,' '
call CheckTestSetInclusion ;check space, so
; we get a failed
; search
call ZTimerOff
```

## Listing 11-20

```nasm
;
; *** Listing 11-20 ***
;
; Tests whether several characters are in the set
; {A,Z,3,!} by using the compare-and-jump approach.
;
jmp Skip
;
; Determines whether a given character is in the set
; {A,Z,3,!}.
;
; Input:
; AL = character to check for inclusion in the set
;
; Output:
; Z if character is in TestSet, NZ otherwise
;
; Registers altered: none
;
CheckTestSetInclusion:
cmp al,'A' ;is it 'A'?
jz CheckTestSetInclusionDone ;yes, we're done
cmp al,'Z' ;is it 'Z'?
jz CheckTestSetInclusionDone ;yes, we're done
cmp al,'3' ;is it '3'?
jz CheckTestSetInclusionDone ;yes, we're done
cmp al,'!' ;is it '!'?
CheckTestSetInclusionDone:
ret ;the success status is already in
; the Zero flag
;
Skip:
call ZTimerOn
mov al,'A'
call CheckTestSetInclusion ;check 'A'
mov al,'Z'
call CheckTestSetInclusion ;check 'Z'
mov al,'3'
call CheckTestSetInclusion ;check '3'
mov al,'!'
call CheckTestSetInclusion ;check '!'
mov al,' '
call CheckTestSetInclusion ;check space, so
; we get a failed
; search
call ZTimerOff
```

## Listing 11-21

```nasm
;
; *** Listing 11-21 ***
;
; Compares two word-sized arrays of equal length to see
; whether they differ, and if so where, using REPZ CMPSW.
;
jmp Skip
;
WordArray1 dw 100 dup (1), 0, 99 dup (2)
ARRAY_LENGTH_IN_WORDS equ (($-WordArray1)/2)
WordArray2 dw 100 dup (1), 100 dup (2)
;
; Returns pointers to the first locations at which two
; word-sized arrays of equal length differ, or zero if
; they're identical.
;
; Input:
; CX = length of the arrays (they must be of equal
; length)
; DS:SI = the first array to compare
; ES:DI = the second array to compare
;
; Output:
; DS:SI = pointer to the first differing location in
; the first array if there is a difference,
; or SI=0 if the arrays are identical
; ES:DI = pointer to the first differing location in
; the second array if there is a difference,
; or DI=0 if the arrays are identical
;
; Registers altered: SI, DI
;
; Direction flag cleared
;
; Note: Does not handle arrays that are longer than 32K
; words or cross segment boundaries.
;
FindFirstDifference:
cld
jcxz FindFirstDifferenceSame
;if there's nothing to
; check, we'll consider the
; arrays to be the same.
; (If we let REPZ CMPSW
; execute with CX=0, we
; may get a false match
; because CMPSW repeated
; zero times doesn't alter
; the flags)
repz cmpsw ;compare the arrays
jz FindFirstDifferenceSame ;they're identical
dec si ;the arrays differ, so
dec si ; point back to first
dec di ; difference in both arrays
dec di
ret
FindFirstDifferenceSame:
sub si,si ;indicate that the strings
mov di,si ; are identical
ret
;
Skip:
call ZTimerOn
mov si,offset WordArray1 ;point to the two
mov di,ds ; arrays to be
mov es,di ; compared
mov di,offset WordArray2
mov cx,ARRAY_LENGTH_IN_WORDS
;# of words to check
call FindFirstDifference ;see if they differ
call ZTimerOff
```

## Listing 11-22

```nasm
;
;
; *** Listing 11-22 ***
;
; Compares two word-sized arrays of equal length to see
; whether they differ, and if so where, using LODSW and
; SCASW.
;
jmp Skip
;
WordArray1 dw 100 dup (1), 0, 99 dup (2)
ARRAY_LENGTH_IN_WORDS equ (($-WordArray1)/2)
WordArray2 dw 100 dup (1), 100 dup (2)
;
; Returns pointers to the first locations at which two
; word-sized arrays of equal length differ, or zero if
; they're identical.
;
; Input:
; CX = length of the arrays (they must be of equal
; length)
; DS:SI = the first array to compare
; ES:DI = the second array to compare
;
; Output:
; DS:SI = pointer to the first differing location in
; the first array if there is a difference,
; or SI=0 if the arrays are identical
; ES:DI = pointer to the first differing location in
; the second array if there is a difference,
; or DI=0 if the arrays are identical
;
; Registers altered: AX, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle arrays that are longer than 32K
; words or cross segment boundaries.
;
FindFirstDifference:
cld
jcxz FindFirstDifferenceSame
;if there's nothing to
; check, we'll consider the
; arrays to be the same.
; (If we let LOOP
; execute with CX=0, we'll
; get 64 K repetitions)
FindFirstDifferenceLoop:
lodsw
scasw ;compare the next two words
jnz FindFirstDifferenceFound
;the arrays differ
loop FindFirstDifferenceLoop
;the arrays are the
; same so far
FindFirstDifferenceSame:
sub si,si ;indicate that the strings
mov di,si ; are identical
ret
FindFirstDifferenceFound:
dec si ;the arrays differ, so
dec si ; point back to first
dec di ; difference in both arrays
dec di
ret
;
Skip:
call ZTimerOn
mov si,offset WordArray1 ;point to the two
mov di,ds ; arrays to be
mov es,di ; compared
mov di,offset WordArray2
mov cx,ARRAY_LENGTH_IN_WORDS
;# of words to check
call FindFirstDifference ;see if they differ
call ZTimerOff
```

## Listing 11-23

```nasm
;
; *** Listing 11-23 ***
;
; Compares two word-sized arrays of equal length to see
; whether they differ, and if so, where, using non-string
; instructions.
;
jmp Skip
;
WordArray1 dw 100 dup (1), 0, 99 dup (2)
ARRAY_LENGTH_IN_WORDS equ (($-WordArray1)/2)
WordArray2 dw 100 dup (1), 100 dup (2)
;
; Returns pointers to the first locations at which two
; word-sized arrays of equal length differ, or zero if
; they're identical.
;
; Input:
; CX = length of the arrays (they must be of equal
; length)
; DS:SI = the first array to compare
; ES:DI = the second array to compare
;
; Output:
; DS:SI = pointer to the first differing location in
; the first array if there is a difference,
; or SI=0 if the arrays are identical
; ES:DI = pointer to the first differing location in
; the second array if there is a difference,
; or DI=0 if the arrays are identical
;
; Registers altered: AX, SI, DI
;
; Note: Does not handle arrays that are longer than 32K
; words or cross segment boundaries.
;
FindFirstDifference:
jcxz FindFirstDifferenceSame
;if there's nothing to
; check, we'll consider the
; arrays to be the same
FindFirstDifferenceLoop:
mov ax,[si]
cmp es:[di],ax ;compare the next two words
jnz FindFirstDifferenceFound ;the arrays differ
inc si
inc si ;point to the next words to
inc di ; compare
inc di
loop FindFirstDifferenceLoop ;the arrays are the
; same so far
FindFirstDifferenceSame:
sub si,si ;indicate that the strings
mov di,si ; are identical
FindFirstDifferenceFound:
ret
;
Skip:
call ZTimerOn
mov si,offset WordArray1 ;point to the two
mov di,ds ; arrays to be
mov es,di ; compared
mov di,offset WordArray2
mov cx,ARRAY_LENGTH_IN_WORDS
;# of words to check
call FindFirstDifference ;see if they differ
call ZTimerOff
```

## Listing 11-24

```nasm
;
; *** Listing 11-24 ***
;
; Determines whether two zero-terminated strings differ, and
; if so where, using REP SCASB to find the terminating zero
; to determine one string length, and then using REPZ CMPSW
; to compare the strings.
;
jmp Skip
;
TestString1 label byte
db 'This is a test string that is '
db 'z'
db 'terminated with a zero byte...',0
TestString2 label byte
db 'This is a test string that is '
db 'a'
db 'terminated with a zero byte...',0
;
; Compares two zero-terminated strings.
;
; Input:
; DS:SI = first zero-terminated string
; ES:DI = second zero-terminated string
;
; Output:
; DS:SI = pointer to first differing location in
; first string, or 0 if the byte wasn't found
; ES:DI = pointer to first differing location in
; second string, or 0 if the byte wasn't found
;
; Registers altered: AL, CX, DX, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
; Note: If there is no terminating zero in the first 64K-1
; bytes of a string, the string is treated as if byte
; 64K is a zero without checking, since if it isn't
; the string isn't zero-terminated at all.
;
CompareStrings:
mov dx,di ;set aside the start of the second
; string
sub al,al ;we'll search for zero in the second
; string to see how long it is
mov cx,0ffffh ;long enough to handle any string
; up to 64K-1 bytes in length. Any
; longer string will be treated as
; if byte 64K is zero
cld
repnz scasb ;find the terminating zero
not cx ;length of string in bytes, including
; the terminating zero except in the
; case of a string that's exactly 64K
; long including the terminating zero
mov di,dx ;get back the start of the second
; string
shr cx,1 ;get count in words
jnc CompareStringsWord
;if there's no odd byte, go directly
; to comparing a word at a time
cmpsb ;compare the odd bytes of the
; strings
jnz CompareStringsDifferentByte
;we've already found a difference
CompareStringsWord:
;there's no need to guard against
; CX=0 here, since we know that if
; CX=0 here, the preceding CMPSB
; must have successfully compared
; the terminating zero bytes of the
; strings (which are the only bytes
; of the strings), and the Zero flag
; setting of 1 from CMPSB will be
; preserved by REPZ CMPSW if CX=0,
; resulting in the correct
; conclusion that the strings are
; identical
repz cmpsw ;compare the rest of the strings a
; word at a time for speed
jnz CompareStringsDifferent ;they're not the same
sub si,si ;return 0 pointers indicating that
mov di,si ; the strings are identical
ret
CompareStringsDifferent:
;the strings are different, so we
; have to figure which byte in the
; word just compared was the first
; difference
dec si ;point back to the second byte of
dec di ; the differing word in each string
dec si ;point back to the differing byte in
dec di ; each string
lodsb
scasb ;compare that first byte again
jz CompareStringsDone
;if the first bytes are the same,
; then it must have been the second
; bytes that differed. That's where
; we're pointing, so we're done
CompareStringsDifferentByte:
dec si ;the first bytes differed, so point
dec di ; back to them
CompareStringsDone:
ret
;
Skip:
call ZTimerOn
mov si,offset TestString1 ;point to one string
mov di,seg TestString2
mov es,di
mov di,offset TestString2 ;point to other string
call CompareStrings ;and compare the strings
call ZTimerOff
```

## Listing 11-25

```nasm
;
; *** Listing 11-25 ***
;
; Determines whether two zero-terminated strings differ, and
; if so where, using LODS/SCAS.
;
jmp Skip
;
TestString1 label byte
db 'This is a test string that is '
db 'z'
db 'terminated with a zero byte...',0
TestString2 label byte
db 'This is a test string that is '
db 'a'
db 'terminated with a zero byte...',0
;
; Compares two zero-terminated strings.
;
; Input:
; DS:SI = first zero-terminated string
; ES:DI = second zero-terminated string
;
; Output:
; DS:SI = pointer to first differing location in
; first string, or 0 if the byte wasn't found
; ES:DI = pointer to first differing location in
; second string, or 0 if the byte wasn't found
;
; Registers altered: AX, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CompareStrings:
cld
CompareStringsLoop:
lodsw ;get the next 2 bytes
and al,al ;is the first byte the terminating
; zero?
jz CompareStringsFinalByte
;yes, so there's only one byte left
; to check
scasw ;compare this word
jnz CompareStringsDifferent ;the strings differ
and ah,ah ;is the second byte the terminating
; zero?
jnz CompareStringsLoop ;no, continue comparing
;the strings are the same
CompareStringsSame:
sub si,si ;return 0 pointers indicating that
mov di,si ; the strings are identical
ret
CompareStringsFinalByte:
scasb ;does the terminating zero match in
; the 2 strings?
jz CompareStringsSame ;yes, the strings match
dec si ;point back to the differing byte
dec di ; in each string
ret
CompareStringsDifferent:
;the strings are different, so we
; have to figure which byte in the
; word just compared was the first
; difference
dec si
dec si ;point back to the first byte of the
dec di ; differing word in each string
dec di
lodsb
scasb ;compare that first byte again
jz CompareStringsDone
;if the first bytes are the same,
; then it must have been the second
; bytes that differed. That's where
; we're pointing, so we're done
dec si ;the first bytes differed, so point
dec di ; back to them
CompareStringsDone:
ret
;
Skip:
call ZTimerOn
mov si,offset TestString1 ;point to one string
mov di,seg TestString2
mov es,di
mov di,offset TestString2 ;point to other string
call CompareStrings ;and compare the strings
call ZTimerOff
```

## Listing 11-26

```nasm
;
; *** Listing 11-26 ***
;
; Determines whether two zero-terminated strings differ
; ignoring case-only differences, and if so where, using
; LODS.
;
jmp Skip
;
TestString1 label byte
db 'THIS IS A TEST STRING THAT IS '
db 'Z'
db 'TERMINATED WITH A ZERO BYTE...',0
TestString2 label byte
db 'This is a test string that is '
db 'a'
db 'terminated with a zero byte...',0
;
; Macro to convert the specified register to uppercase if
; it is lowercase.
;
TO_UPPER macro REGISTER
local NotLower
cmp REGISTER,ch ;below 'a'?
jb NotLower ;yes, not lowercase
cmp REGISTER,cl ;above 'z'?
ja NotLower ;yes, not lowercase
and REGISTER,bl ;lowercase-convert to uppercase
NotLower:
endm
;
; Compares two zero-terminated strings, ignoring differences
; that are only uppercase/lowercase differences.
;
; Input:
; DS:SI = first zero-terminated string
; ES:DI = second zero-terminated string
;
; Output:
; DS:SI = pointer to first case-insensitive differing
; location in first string, or 0 if the byte
; wasn't found
; ES:DI = pointer to first case-insensitive differing
; location in second string, or 0 if the byte
; wasn't found
;
; Registers altered: AX, BL, CX, DX, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CompareStringsNoCase:
cld
mov cx,'az' ;for fast register-register
; comparison in the loop
mov bl,not 20h ;for fast conversion to
; uppercase in the loop
CompareStringsLoop:
lodsw ;get the next 2 bytes
mov dx,es:[di] ; from each string
inc di ;point to the next word in the
inc di ; second string
TO_UPPER al ;convert the first byte from each
TO_UPPER dl ; string to uppercase
cmp al,dl ;do the first bytes match?
jnz CompareStringsDifferent1 ;the strings differ
and al,al ;is the first byte the terminating
; zero?
jz CompareStringsSame
;yes, we're done with a match
TO_UPPER ah ;convert the second byte from each
TO_UPPER dh ; string to uppercase
cmp ah,dh ;do the second bytes match?
jnz CompareStringsDifferent ;the strings differ
and ah,ah ;is the second byte the terminating
; zero?
jnz CompareStringsLoop
;no, do the next 2 bytes
CompareStringsSame:
sub si,si ;return 0 pointers indicating that
mov di,si ; the strings are identical
ret
CompareStringsDifferent1:
dec si ;point back to the second byte of
dec di ; the word we just compared
CompareStringsDifferent:
dec si ;point back to the first byte of the
dec di ; word we just compared
ret
;
Skip:
call ZTimerOn
mov si,offset TestString1 ;point to one string
mov di,seg TestString2
mov es,di
mov di,offset TestString2 ;point to other string
call CompareStringsNoCase ;and compare the
; strings without
; regard for case
call ZTimerOff
```

## Listing 11-27

```nasm
;
; *** Listing 11-27 ***
;
; Determines whether two zero-terminated strings differ
; ignoring case-only differences, and if so where, using
; LODS, with an XLAT-based table look-up to convert to
; uppercase.
;
jmp Skip
;
TestString1 label byte
db 'THIS IS A TEST STRING THAT IS '
db 'Z'
db 'TERMINATED WITH A ZERO BYTE...',0
TestString2 label byte
db 'This is a test string that is '
db 'a'
db 'terminated with a zero byte...',0
;
; Table of conversions between characters and their
; uppercase equivalents. (Could be just 128 bytes long if
; only 7-bit ASCII characters are used.)
;
ToUpperTable label word
CHAR=0
rept 256
if (CHAR lt 'a') or (CHAR gt 'z')
db CHAR ;not a lowercase character
else
db CHAR and not 20h
;convert in the range 'a'-'z' to
; uppercase
endif
CHAR=CHAR+1
endm
;
; Compares two zero-terminated strings, ignoring differences
; that are only uppercase/lowercase differences.
;
; Input:
; DS:SI = first zero-terminated string
; ES:DI = second zero-terminated string
;
; Output:
; DS:SI = pointer to first case-insensitive differing
; location in first string, or 0 if the byte
; wasn't found
; ES:DI = pointer to first case-insensitive differing
; location in second string, or 0 if the byte
; wasn't found
;
; Registers altered: AX, BX, DX, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CompareStringsNoCase:
cld
mov bx,offset ToUpperTable
CompareStringsLoop:
lodsw ;get the next 2 bytes
mov dx,es:[di] ; from each string
inc di ;point to the next word in the
inc di ; second string
xlat ;convert the first byte in the
; first string to uppercase
xchg dl,al ;set aside the first byte &
xlat ; convert the first byte in the
; second string to uppercase
cmp al,dl ;do the first bytes match?
jnz CompareStringsDifferent1 ;the strings differ
and al,al ;is this the terminating zero?
jz CompareStringsSame
;yes, we're done, with a match
mov al,ah
xlat ;convert the second byte from the
; first string to uppercase
xchg dh,al ;set aside the second byte &
xlat ; convert the second byte from the
; second string to uppercase
cmp al,dh ;do the second bytes match?
jnz CompareStringsDifferent ;the strings differ
and ah,ah ;is this the terminating zero?
jnz CompareStringsLoop
;no, do the next 2 bytes
CompareStringsSame:
sub si,si ;return 0 pointers indicating that
mov di,si ; the strings are identical
ret
CompareStringsDifferent1:
dec si ;point back to the second byte of
dec di ; the word we just compared
CompareStringsDifferent:
dec si ;point back to the first byte of the
dec di ; word we just compared
ret
;
Skip:
call ZTimerOn
mov si,offset TestString1 ;point to one string
mov di,seg TestString2
mov es,di
mov di,offset TestString2 ;point to other string
call CompareStringsNoCase ;and compare the
; strings without
; regard for case
call ZTimerOff
```

## Listing 11-28

```nasm
;
; *** Listing 11-28 ***
;
; Searches a text buffer for a sequence of bytes by checking
; for the sequence with CMPS starting at each byte of the
; buffer that potentially could start the sequence.
;
jmp Skip
;
; Text buffer that we'll search.
;
TextBuffer label byte
db 'This is a sample text buffer, suitable '
db 'for a searching text of any sort... '
db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 '
db 'End of text... '
TEXT_BUFFER_LENGTH equ ($-TextBuffer)
;
; Sequence of bytes that we'll search for.
;
SearchSequence label byte
db 'text...'
SEARCH_SEQUENCE_LENGTH equ ($-SearchSequence)
;
; Searches a buffer for the first occurrence of a specified
; sequence of bytes.
;
; Input:
; CX = length of sequence of bytes to search for
; DX = length of buffer to search in
; DS:SI = start of sequence of bytes to search for
; ES:DI = start of buffer to search
;
; Output:
; ES:DI = pointer to start of first occurrence of
; desired sequence of bytes in the buffer, or
; 0:0 if the sequence wasn't found
;
; Registers altered: AX, BX, CX, DX, SI, DI, BP
;
; Direction flag cleared
;
; Note: Does not handle search sequences or text buffers
; that are longer than 64K bytes or cross segment
; boundaries.
;
; Note: Assumes non-zero length of search sequence (CX > 0),
; and search sequence shorter than 64K (CX <= 0ffffh).
;
; Note: Assumes buffer is longer than search sequence
; (DX > CX). Zero length of buffer is taken to mean
; that the buffer is 64K bytes long.
;
FindSequence:
cld
mov bp,si ;set aside the sequence start
; offset
mov ax,di ;set aside the buffer start offset
mov bx,cx ;set aside the sequence length
sub dx,cx ;difference between buffer and
; search sequence lengths
inc dx ;# of possible sequence start bytes
; to check in the buffer
FindSequenceLoop:
mov cx,bx ;sequence length
shr cx,1 ;convert to word for faster search
jnc FindSequenceWord ;do word search if no odd
; byte
cmpsb ;compare the odd byte
jnz FindSequenceNoMatch ;odd byte doesn't match,
; so we havent' found the
; search sequence here
FindSequenceWord:
jcxz FindSequenceFound
;since we're guaranteed to
; have a non-zero length,
; the sequence must be 1
; byte long and we've
; already found that it
; matched
repz cmpsw ;check the rest of the
; sequence a word at a time
; for speed
jz FindSequenceFound ;it's a match
FindSequenceNoMatch:
mov si,bp ;point to the start of the search
; sequence again
inc ax ;advance to the next buffer start
; search location
mov di,ax ;point DI to the next buffer start
; search location
dec dx ;count down the remaining bytes to
; search in the buffer
jnz FindSequenceLoop
sub di,di ;return 0 pointer indicating that
mov es,di ; the sequence was not found
ret
FindSequenceFound:
mov di,ax ;point to the buffer location at
; which the first occurrence of the
; sequence was found
ret
;
Skip:
call ZTimerOn
mov si,offset SearchSequence
;point to search sequence
mov cx,SEARCH_SEQUENCE_LENGTH
;length of search sequence
mov di,seg TextBuffer
mov es,di
mov di,offset TextBuffer
;point to buffer to search
mov dx,TEXT_BUFFER_LENGTH
;length of buffer to search
call FindSequence ;search for the sequence
call ZTimerOff
```

## Listing 11-29

```nasm
;
; *** Listing 11-29 ***
;
; Searches a text buffer for a sequence of bytes by using
; REPNZ SCASB to identify bytes in the buffer that
; potentially could start the sequence and then checking
; only starting at those qualified bytes for a match with
; the sequence by way of REPZ CMPS.
;
jmp Skip
;
; Text buffer that we'll search.
;
TextBuffer label byte
db 'This is a sample text buffer, suitable '
db 'for a searching text of any sort... '
db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 '
db 'End of text... '
TEXT_BUFFER_LENGTH equ ($-TextBuffer)
;
; Sequence of bytes that we'll search for.
;
SearchSequence label byte
db 'text...'
SEARCH_SEQUENCE_LENGTH equ ($-SearchSequence)
;
; Searches a buffer for the first occurrence of a specified
; sequence of bytes.
;
; Input:
; CX = length of sequence of bytes to search for
; DX = length of buffer to search in
; DS:SI = start of sequence of bytes to search for
; ES:DI = start of buffer to search
;
; Output:
; ES:DI = pointer to start of first occurrence of
; desired sequence of bytes in the buffer, or
; 0:0 if the sequence wasn't found
;
; Registers altered: AL, BX, CX, DX, SI, DI, BP
;
; Direction flag cleared
;
; Note: Does not handle search sequences or text buffers
; that are longer than 64K bytes or cross segment
; boundaries.
;
; Note: Assumes non-zero length of search sequence (CX > 0),
; and search sequence shorter than 64K (CX <= 0ffffh).
;
; Note: Assumes buffer is longer than search sequence
; (DX > CX). Zero length of buffer (DX = 0) is taken
; to mean that the buffer is 64K bytes long.
;
FindSequence:
cld
lodsb ;get the first byte of the search
; sequence, which we'll leave in AL
; for faster searching
mov bp,si ;set aside the sequence start
; offset plus one
dec cx ;we don't need to compare the first
; byte of the sequence with CMPS,
; since we'll do it with SCAS
mov bx,cx ;set aside the sequence length
; minus 1
sub dx,cx ;difference between buffer and
; search sequence lengths plus 1
; (# of possible sequence start
; bytes to check in the buffer)
mov cx,dx ;put buffer search length in CX
jnz FindSequenceLoop ;start normally if the
; buffer isn't 64Kb long
dec cx ;the buffer is 64K bytes long-we
; have to check the first byte
; specially since CX = 0 means
; "do nothing" to REPNZ SCASB
scasb ;check the first byte of the buffer
jz FindSequenceCheck ;it's a match for 1 byte,
; at least-check the rest
FindSequenceLoop:
repnz scasb ;search for the first byte of the
; search sequence
jnz FindSequenceNotFound
;it's not found, so there are no
; possible matches
FindSequenceCheck:
;we've got a potential (first byte)
; match-check the rest of this
; candidate sequence
push di ;remember the address of the next
; byte to check in case it's needed
mov dx,cx ;set aside the remaining length to
; search in the buffer
mov si,bp ;point to the rest of the search
; sequence
mov cx,bx ;sequence length (minus first byte)
shr cx,1 ;convert to word for faster search
jnc FindSequenceWord ;do word search if no odd
; byte
cmpsb ;compare the odd byte
jnz FindSequenceNoMatch
;odd byte doesn't match,
; so we haven't found the
; search sequence here
FindSequenceWord:
jcxz FindSequenceFound
;since we're guaranteed to have
; a non-zero length, the
; sequence must be 1 byte long
; and we've already found that
; it matched
repz cmpsw ;check the rest of the sequence a
; word at a time for speed
jz FindSequenceFound ;it's a match
FindSequenceNoMatch:
pop di ;get back the pointer to the next
; byte to check
mov cx,dx ;get back the remaining length to
; search in the buffer
and cx,cx ;see if there's anything left to
; check
jnz FindSequenceLoop ;yes-check next byte
FindSequenceNotFound:
sub di,di ;return 0 pointer indicating that
mov es,di ; the sequence was not found
ret
FindSequenceFound:
pop di ;point to the buffer location at
dec di ; which the first occurrence of the
; sequence was found (remember that
; earlier we pushed the address of
; the byte after the potential
; sequence start)
ret
;
Skip:
call ZTimerOn
mov si,offset SearchSequence
;point to search sequence
mov cx,SEARCH_SEQUENCE_LENGTH
;length of search sequence
mov di,seg TextBuffer
mov es,di
mov di,offset TextBuffer
;point to buffer to search
mov dx,TEXT_BUFFER_LENGTH
;length of buffer to search
call FindSequence ;search for the sequence
call ZTimerOff
```

## Listing 11-30

```nasm
;
; *** Listing 11-30 ***
;
; Searches a text buffer for a sequence of bytes by checking
; for the sequence with non-string instructions starting at
; each byte of the buffer that potentially could start the
; sequence.
;
jmp Skip
;
; Text buffer that we'll search.
;
TextBuffer label byte
db 'This is a sample text buffer, suitable '
db 'for a searching text of any sort... '
db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 '
db 'End of text... '
TEXT_BUFFER_LENGTH equ ($-TextBuffer)
;
; Sequence of bytes that we'll search for.
;
SearchSequence label byte
db 'text...'
SEARCH_SEQUENCE_LENGTH equ ($-SearchSequence)
;
; Searches a buffer for the first occurrence of a specified
; sequence of bytes.
;
; Input:
; CX = length of sequence of bytes to search for
; DX = length of buffer to search in
; DS:SI = start of sequence of bytes to search for
; ES:DI = start of buffer to search
;
; Output:
; ES:DI = pointer to start of first occurrence of
; desired sequence of bytes in the buffer, or
; 0:0 if the sequence wasn't found
;
; Registers altered: AX, BX, CX, DX, SI, DI, BP
;
; Note: Does not handle search sequences or text buffers
; that are longer than 64K bytes or cross segment
; boundaries.
;
; Note: Assumes non-zero length of search sequence (CX > 0),
; and search sequence shorter than 64K (CX <= 0ffffh).
;
; Note: Assumes buffer is longer than search sequence
; (DX > CX). Zero length of buffer is taken to mean
; that the buffer is 64K bytes long.
;
FindSequence:
mov bp,si ;set aside the sequence start
; offset
mov bx,cx ;set aside the sequence length
sub dx,cx ;difference between buffer and
; search sequence lengths
inc dx ;# of possible sequence start bytes
; to check in the buffer
FindSequenceLoop:
push di ;remember the address of the current
; byte in case it's needed
mov cx,bx ;sequence length
shr cx,1 ;convert to word for faster search
jnc FindSequenceWord ;do word search if no odd
; byte
mov al,[si]
cmp es:[di],al ;compare the odd byte
jnz FindSequenceNoMatch ;odd byte doesn't match,
; so we havent' found the
; search sequence here
inc si ;odd byte matches, so point
inc di ; to the next byte in the
; buffer and sequence
FindSequenceWord:
jcxz FindSequenceFound
;since we're guaranteed to
; have a non-zero length,
; the sequence must be 1
; byte long and we've
; already found that it
; matched
FindSequenceWordCompareLoop:
mov ax,[si] ;compare the remainder of
cmp es:[di],ax ; the search sequence to
jnz FindSequenceNoMatch ; this part of the
inc si ; buffer a word at a time
inc si ; for speed
inc di
inc di
loop FindSequenceWordCompareLoop
FindSequenceFound: ;it's a match
pop di ;point to the buffer location at
; which the first occurrence of the
; sequence was found (remember that
; earlier we pushed the address of
; the potential sequence start)
ret
FindSequenceNoMatch:
pop di ;get back the pointer to the current
; byte
inc di ;point to the next buffer start
; search location
mov si,bp ;point to the start of the search
; sequence again
dec dx ;count down the remaining bytes to
; search in the buffer
jnz FindSequenceLoop
sub di,di ;return 0 pointer indicating that
mov es,di ; the sequence was not found
ret
;
Skip:
call ZTimerOn
mov si,offset SearchSequence
;point to search sequence
mov cx,SEARCH_SEQUENCE_LENGTH
;length of search sequence
mov di,seg TextBuffer
mov es,di
mov di,offset TextBuffer
;point to buffer to search
mov dx,TEXT_BUFFER_LENGTH
;length of buffer to search
call FindSequence ;search for the sequence
call ZTimerOff
```

## Listing 11-31

```nasm
;
; *** Listing 11-31 ***
;
; Compares two arrays of 16-bit signed values in order to
; find the first point at which the arrays cross, using
; non-repeated CMPSW.
;
jmp Skip
;
; The two arrays that we'll compare.
;
ARRAY_LENGTH equ 200
;
Array1 label byte
TEMP=-100
rept ARRAY_LENGTH
dw TEMP
TEMP=TEMP+1
endm
;
Array2 label byte
TEMP=100
rept ARRAY_LENGTH
dw TEMP
TEMP=TEMP-1
endm
;
; Compares two buffers to find the first point at which they
; cross. Points at which the arrays become equal are
; considered to be crossing points.
;
; Input:
; CX = length of arrays in words (they must be of
; equal length)
; DS:SI = start of first array
; ES:DI = start of second array
;
; Output:
; DS:SI = pointer to crossing point in first array,
; or SI=0 if there is no crossing point
; ES:DI = pointer to crossing point in second array,
; or DI=0 if there is no crossing point
;
; Registers altered: AX, CX, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle arrays that are longer than 64K
; bytes or cross segment boundaries.
;
FindCrossing:
cld
jcxz FindCrossingNotFound
;if there's nothing to compare, we
; certainly can't find a crossing
mov ax,[si] ;compare the first two points to
cmp ax,es:[di] ; make sure that the first array
; doesn't start out below the second
; array
pushf ;remember the original relationship
; of the arrays, so we can put the
; pointers back at the end (can't
; use LAHF because it doesn't save
; the Overflow flag)
jnl FindCrossingLoop ;the first array is above
; the second array
xchg si,di ;swap the array pointers so that
; SI points to the initially-
; greater array
FindCrossingLoop:
cmpsw ;compare the next element in each
; array
jng FindCrossingFound ;if SI doesn't point to a
; greater value, we've found
; the first crossing
loop FindCrossingLoop ;check the next element in
; each array
FindCrossingNotFound:
popf ;clear the flags we pushed earlier
sub si,si ;return 0 pointers to indicate that
mov di,si ; no crossing was found
ret
FindCrossingFound:
dec si
dec si ;point back to the crossing point
dec di ; in each array
dec di
popf ;get back the original relationship
; of the arrays
jnl FindCrossingDone
;SI pointed to the initially-
; greater array, so we're all set
xchg si,di ;SI pointed to the initially-
; less array, so swap SI and DI to
; undo our earlier swap
FindCrossingDone:
ret
;
Skip:
call ZTimerOn
mov si,offset Array1 ;point to first array
mov di,seg Array2
mov es,di
mov di,offset Array2 ;point to second array
mov cx,ARRAY_LENGTH ;length to compare
call FindCrossing ;find the first crossing, if
; any
call ZTimerOff
```

## Listing 11-32

```nasm
;
; *** Listing 11-32 ***
;
; Compares two arrays of 16-bit signed values in order to
; find the first point at which the arrays cross, using
; non-string instructions.
;
jmp Skip
;
; The two arrays that we'll compare.
;
ARRAY_LENGTH equ 200
;
Array1 label byte
TEMP=-100
rept ARRAY_LENGTH
dw TEMP
TEMP=TEMP+1
endm
;
Array2 label byte
TEMP=100
rept ARRAY_LENGTH
dw TEMP
TEMP=TEMP-1
endm
;
; Compares two buffers to find the first point at which they
; cross. Points at which the arrays become equal are
; considered to be crossing points.
;
; Input:
; CX = length of arrays in words (they must be of
; equal length)
; DS:SI = start of first array
; ES:DI = start of second array
;
; Output:
; DS:SI = pointer to crossing point in first array,
; or SI=0 if there is no crossing point
; ES:DI = pointer to crossing point in second array,
; or DI=0 if there is no crossing point
;
; Registers altered: BX, CX, DX, SI, DI
;
; Note: Does not handle arrays that are longer than 64K
; bytes or cross segment boundaries.
;
FindCrossing:
jcxz FindCrossingNotFound
;if there's nothing to compare, we
; certainly can't find a crossing
mov dx,2 ;amount we'll add to the pointer
; registers after each comparison,
; kept in a register for speed
mov bx,[si] ;compare the first two points to
cmp bx,es:[di] ; make sure that the first array
; doesn't start out below the second
; array
pushf ;remember the original relationship
; of the arrays, so we can put the
; pointers back at the end (can't
; use LAHF because it doesn't save
; the Overflow flag)
jnl FindCrossingLoop ;the first array is above
; the second array
xchg si,di ;swap the array pointers so that
; SI points to the initially-
; greater array
FindCrossingLoop:
mov bx,[si] ;compare the next element in
cmp bx,es:[di] ; each array
jng FindCrossingFound ;if SI doesn't point to a
; greater value, we've found
; the first crossing
add si,dx ;point to the next element
add di,dx ; in each array
loop FindCrossingLoop ;check the next element in
; each array
FindCrossingNotFound:
popf ;clear the flags we pushed earlier
sub si,si ;return 0 pointers to indicate that
mov di,si ; no crossing was found
ret
FindCrossingFound:
popf ;get back the original relationship
; of the arrays
jnl FindCrossingDone
;SI pointed to the initially-
; greater array, so we're all set
xchg si,di ;SI pointed to the initially-
; less array, so swap SI and DI to
; undo our earlier swap
FindCrossingDone:
ret
;
Skip:
call ZTimerOn
mov si,offset Array1 ;point to first array
mov di,seg Array2
mov es,di
mov di,offset Array2 ;point to second array
mov cx,ARRAY_LENGTH ;length to compare
call FindCrossing ;find the first crossing, if
; any
call ZTimerOff
```

## Listing 11-33

```nasm
;
; *** Listing 11-33 ***
;
; Illustrates animation based on exclusive-oring.
; Animates 10 images at once.
; Not a general animation implementation, but rather an
; example of the strengths and weaknesses of exclusive-or
; based animation.
;
; Make with LZTIME.BAT, since this program is too long to be
; handled by the precision Zen timer.
;
jmp Skip
;
DELAY equ 0 ;set to higher values to
; slow down for closer
; observation
REPETITIONS equ 500 ;# of times to move and
; redraw the images
DISPLAY_SEGMENT equ 0b800h ;display memory segment
; in 320x200 4-color
; graphics mode
SCREEN_WIDTH equ 80 ;# of bytes per scan line
BANK_OFFSET equ 2000h ;offset from the bank
; containing the even-
; numbered lines on the
; screen to the bank
; containing the odd-
; numbered lines
;
; Used to count down # of times images are moved.
;
RepCount dw REPETITIONS
;
; Complete info about one image that we're animating.
;
Image struc
XCoord dw ? ;image X location in pixels
XInc dw ? ;# of pixels to increment
; location by in the X
; direction on each move
YCoord dw ? ;image Y location in pixels
YInc dw ? ;# of pixels to increment
; location by in the Y
; direction on each move
Image ends
;
; List of images to animate.
;
Images label Image
Image <64,4,8,4>
Image <144,0,56,2>
Image <224,-4,104,0>
Image <64,4,152,-2>
Image <144,0,8,-4>
Image <224,-4,56,-2>
Image <64,4,104,0>
Image <144,0,152,2>
Image <224,-4,8,4>
Image <64,4,56,2>
ImagesEnd label Image
;
; Pixel pattern for the one image this program draws,
; a 32x32 3-color square.
;
TheImage label byte
rept 32
dw 0ffffh, 05555h, 0aaaah, 0ffffh
endm
IMAGE_HEIGHT equ 32 ;# of rows in the image
IMAGE_WIDTH equ 8 ;# of bytes across the image
;
; Exclusive-ors the image of a 3-color square at the
; specified screen location. Assumes images start on
; even-numbered scan lines and are an even number of
; scan lines high. Always draws images byte-aligned in
; display memory.
;
; Input:
; CX = X coordinate of upper left corner at which to
; draw image (will be adjusted to nearest
; less-than or equal-to multiple of 4 in order
; to byte-align)
; DX = Y coordinate of upper left corner at which to
; draw image
; ES = display memory segment
;
; Output: none
;
; Registers altered: AX, CX, DX, SI, DI, BP
;
XorImage:
push bx ;preserve the main loop's pointer
shr dx,1 ;divide the row # by 2 to compensate
; for the 2-bank nature of 320x200
; 4-color mode
mov ax,SCREEN_WIDTH
mul dx ;start offset of top row of image in
; display memory
shr cx,1 ;divide the X coordinate by 4
shr cx,1 ; because there are 4 pixels per
; byte
add ax,cx ;point to the offset at which the
; upper left byte of the image will
; go
mov di,ax
mov si,offset TheImage
;point to the start of the one image
; we always draw
mov bx,BANK_OFFSET-IMAGE_WIDTH
;offset from the end of an even line
; of the image in display memory to
; the start of the next odd line of
; the image
mov dx,IMAGE_HEIGHT/2
;# of even/odd numbered row pairs to
; draw in the image
mov bp,IMAGE_WIDTH/2
;# of words to draw per row of the
; image. Note that IMAGE_WIDTH must
; be an even number since we XOR
; the image a word at a time
XorRowLoop:
mov cx,bp ;# of words to draw per row of the
; image
XorColumnLoopEvenRows:
lodsw ;next word of the image pattern
xor es:[di],ax ;XOR the next word of the
; image into the screen
inc di ;point to the next word in display
inc di ; memory
loop XorColumnLoopEvenRows
add di,bx ;point to the start of the next
; (odd) row of the image, which is
; in the second bank of display
; memory
mov cx,bp ;# of words to draw per row of the
; image
XorColumnLoopOddRows:
lodsw ;next word of the image pattern
xor es:[di],ax ;XOR the next word of the
; image into the screen
inc di ;point to the next word in display
inc di ; memory
loop XorColumnLoopOddRows
sub di,BANK_OFFSET-SCREEN_WIDTH+IMAGE_WIDTH
;point to the start of the next
; (even) row of the image, which is
; in the first bank of display
; memory
dec dx ;count down the row pairs
jnz XorRowLoop
pop bx ;restore the main loop's pointer
ret
;
; Main animation program.
;
Skip:
;
; Set the mode to 320x200 4-color graphics mode.
;
mov ax,0004h ;AH=0 is mode select fn
;AL=4 selects mode 4,
; 320x200 4-color mode
int 10h ;invoke the BIOS video
; interrupt to set the mode
;
; Point ES to display memory for the rest of the program.
;
mov ax,DISPLAY_SEGMENT
mov es,ax
;
; We'll always want to count up.
;
cld
;
; Start timing.
;
call ZTimerOn
;
; Draw all the images initially.
;
mov bx,offset Images ;list of images
InitialDrawLoop:
mov cx,[bx+XCoord] ;X coordinate
mov dx,[bx+YCoord] ;Y coordinate
call XorImage ;draw this image
add bx,size Image ;point to next image
cmp bx,offset ImagesEnd
jb InitialDrawLoop ;draw next image, if
; there is one
;
; Erase, move, and redraw each image in turn REPETITIONS
; times.
;
MainMoveAndDrawLoop:
mov bx,offset Images ;list of images
ImageMoveLoop:
mov cx,[bx+XCoord] ;X coordinate
mov dx,[bx+YCoord] ;Y coordinate
call XorImage ;erase this image (it's
; already drawn at this
; location, so this XOR
; erases it)
mov cx,[bx+XCoord] ;X coordinate
cmp cx,4 ;at left edge?
ja CheckRightMargin ;no
neg [bx+XInc] ;yes, so bounce
CheckRightMargin:
cmp cx,284 ;at right edge?
jb MoveX ;no
neg [bx+XInc] ;yes, so bounce
MoveX:
add cx,[bx+XInc] ;move horizontally
mov [bx+XCoord],cx ;save the new location
mov dx,[bx+YCoord] ;Y coordinate
cmp dx,4 ;at top edge?
ja CheckBottomMargin ;no
neg [bx+YInc] ;yes, so bounce
CheckBottomMargin:
cmp dx,164 ;at bottom edge?
jb MoveY ;no
neg [bx+YInc] ;yes, so bounce
MoveY:
add dx,[bx+YInc] ;move horizontally
mov [bx+YCoord],dx ;save the new location
call XorImage ;draw the image at its
; new location
add bx,size Image ;point to the next image
cmp bx,offset ImagesEnd
jb ImageMoveLoop ;move next image, if there
; is one

if DELAY
mov cx,DELAY ;slow down as specified
loop $
endif
dec [RepCount] ;animate again?
jnz MainMoveAndDrawLoop ;yes
;
call ZTimerOff ;done timing
;
; Return to text mode.
;
mov ax,0003h ;AH=0 is mode select fn
;AL=3 selects mode 3,
; 80x25 text mode
int 10h ;invoke the BIOS video
; interrupt to set the mode
```

## Listing 11-34

```nasm
;
; *** Listing 11-34 ***
;
; Illustrates animation based on block moves.
; Animates 10 images at once.
; Not a general animation implementation, but rather an
; example of the strengths and weaknesses of block-move
; based animation.
;
; Make with LZTIME.BAT, since this program is too long to be
; handled by the precision Zen timer.
;
jmp Skip
;
DELAY equ 0 ;set to higher values to
; slow down for closer
; observation
REPETITIONS equ 500 ;# of times to move and
; redraw the images
DISPLAY_SEGMENT equ 0b800h ;display memory segment
; in 320x200 4-color
; graphics mode
SCREEN_WIDTH equ 80 ;# of bytes per scan line
BANK_OFFSET equ 2000h ;offset from the bank
; containing the even-
; numbered lines on the
; screen to the bank
; containing the odd-
; numbered lines
;
; Used to count down # of times images are moved.
;
RepCount dw REPETITIONS
;
; Complete info about one image that we're animating.
;
Image struc
XCoord dw ? ;image X location in pixels
XInc dw ? ;# of pixels to increment
; location by in the X
; direction on each move
YCoord dw ? ;image Y location in pixels
YInc dw ? ;# of pixels to increment
; location by in the Y
; direction on each move
Image ends
;
; List of images to animate.
;
Images label Image
Image <60,4,4,4>
Image <140,0,52,2>
Image <220,-4,100,0>
Image <60,4,148,-2>
Image <140,0,4,-4>
Image <220,-4,52,-2>
Image <60,4,100,0>
Image <140,0,148,2>
Image <220,-4,4,4>
Image <60,4,52,2>
ImagesEnd label Image
;
; Pixel pattern for the one image this program draws,
; a 32x32 3-color square. There's a 4-pixel-wide blank
; fringe around each image, which makes sure the image at
; the old location is erased by the drawing of the image at
; the new location.
;
TheImage label byte
rept 4
dw 5 dup (0) ;top blank fringe
endm
rept 32
db 00h ;left blank fringe
dw 0ffffh, 05555h, 0aaaah, 0ffffh
db 00h ;right blank fringe
endm
rept 4
dw 5 dup (0) ;bottom blank fringe
endm
IMAGE_HEIGHT equ 40 ;# of rows in the image
; (including blank fringe)
IMAGE_WIDTH equ 10 ;# of bytes across the image
; (including blank fringe)
;
; Block-move draws the image of a 3-color square at the
; specified screen location. Assumes images start on
; even-numbered scan lines and are an even number of
; scan lines high. Always draws images byte-aligned in
; display memory.
;
; Input:
; CX = X coordinate of upper left corner at which to
; draw image (will be adjusted to nearest
; less-than or equal-to multiple of 4 in order
; to byte-align)
; DX = Y coordinate of upper left corner at which to
; draw image
; ES = display memory segment
;
; Output: none
;
; Registers altered: AX, CX, DX, SI, DI, BP
;
BlockDrawImage:
push bx ;preserve the main loop's pointer
shr dx,1 ;divide the row # by 2 to compensate
; for the 2-bank nature of 320x200
; 4-color mode
mov ax,SCREEN_WIDTH
mul dx ;start offset of top row of image in
; display memory
shr cx,1 ;divide the X coordinate by 4
shr cx,1 ; because there are 4 pixels per
; byte
add ax,cx ;point to the offset at which the
; upper left byte of the image will
; go
mov di,ax
mov si,offset TheImage
;point to the start of the one image
; we always draw
mov ax,BANK_OFFSET-SCREEN_WIDTH+IMAGE_WIDTH
;offset from the end of an odd line
; of the image in display memory to
; the start of the next even line of
; the image
mov bx,BANK_OFFSET-IMAGE_WIDTH
;offset from the end of an even line
; of the image in display memory to
; the start of the next odd line of
; the image
mov dx,IMAGE_HEIGHT/2
;# of even/odd numbered row pairs to
; draw in the image
mov bp,IMAGE_WIDTH/2
;# of words to draw per row of the
; image. Note that IMAGE_WIDTH must
; be an even number since we draw
; the image a word at a time
BlockDrawRowLoop:
mov cx,bp ;# of words to draw per row of the
; image
rep movsw ;draw a whole even row with this one
; repeated instruction
add di,bx ;point to the start of the next
; (odd) row of the image, which is
; in the second bank of display
; memory
mov cx,bp ;# of words to draw per row of the
; image
rep movsw ;draw a whole odd row with this one
; repeated instruction
sub di,ax
;point to the start of the next
; (even) row of the image, which is
; in the first bank of display
; memory
dec dx ;count down the row pairs
jnz BlockDrawRowLoop
pop bx ;restore the main loop's pointer
ret
;
; Main animation program.
;
Skip:
;
; Set the mode to 320x200 4-color graphics mode.
;
mov ax,0004h ;AH=0 is mode select fn
;AL=4 selects mode 4,
; 320x200 4-color mode
int 10h ;invoke the BIOS video
; interrupt to set the mode
;
; Point ES to display memory for the rest of the program.
;
mov ax,DISPLAY_SEGMENT
mov es,ax
;
; We'll always want to count up.
;
cld
;
; Start timing.
;
call ZTimerOn
;
; There's no need to draw all the images initially with
; block-move animation.
;
; Move and redraw each image in turn REPETITIONS times.
; Redrawing automatically erases the image at the old
; location, thanks to the blank fringe.
;
MainMoveAndDrawLoop:
mov bx,offset Images ;list of images
ImageMoveLoop:
mov cx,[bx+XCoord] ;X coordinate
cmp cx,0 ;at left edge?
ja CheckRightMargin ;no
neg [bx+XInc] ;yes, so bounce
CheckRightMargin:
cmp cx,280 ;at right edge?
jb MoveX ;no
neg [bx+XInc] ;yes, so bounce
MoveX:
add cx,[bx+XInc] ;move horizontally
mov [bx+XCoord],cx ;save the new location
mov dx,[bx+YCoord] ;Y coordinate
cmp dx,0 ;at top edge?
ja CheckBottomMargin ;no
neg [bx+YInc] ;yes, so bounce
CheckBottomMargin:
cmp dx,160 ;at bottom edge?
jb MoveY ;no
neg [bx+YInc] ;yes, so bounce
MoveY:
add dx,[bx+YInc] ;move horizontally
mov [bx+YCoord],dx ;save the new location
call BlockDrawImage ;draw the image at its
; new location
add bx,size Image ;point to the next image
cmp bx,offset ImagesEnd
jb ImageMoveLoop ;move next image, if there
; is one

if DELAY
mov cx,DELAY ;slow down as specified
loop $
endif
dec [RepCount] ;animate again?
jnz MainMoveAndDrawLoop ;yes
;
call ZTimerOff ;done timing
;
; Return to text mode.
;
mov ax,0003h ;AH=0 is mode select fn
;AL=3 selects mode 3,
; 80x25 text mode
int 10h ;invoke the BIOS video
; interrupt to set the mode
```

## Listing 12-1

```nasm
;
; *** Listing 12-1 ***
;
; Measures the performance of JMP.
;
call ZTimerOn
rept 1000
jmp short $+2 ;we'll do a short jump,
; since the next instruction
; can be reached with a
; 1-byte displacement
endm
call ZTimerOff
```

## Listing 12-2

```nasm
;
; *** Listing 12-2 ***
;
; Measures the performance of IMUL when used to calculate
; the 32-bit product of two 16-bit factors each with a value
; of zero.
;
sub ax,ax ;we'll multiply zero times zero
call ZTimerOn
rept 1000
imul ax
endm
call ZTimerOff
```

## Listing 12-3

```nasm
;
; *** Listing 12-3 ***
;
; Measures the performance of JMP when the prefetch queue
; is full when it comes time for each JMP to run.
;
sub ax,ax ;we'll multiply zero times zero
call ZTimerOn
rept 1000
imul ax ;let the prefetch queue fill
jmp short $+2 ;we'll do a short jump,
; since the next instruction
; is less than 127 bytes
; away
endm
call ZTimerOff
```

## Listing 12-4

```nasm
;
; *** Listing 12-4 ***
;
; Measures the performance of JMP when 1) the prefetch queue
; is full when it comes time for each JMP to run and 2) the
; prefetch queue is allowed to fill faster than the
; instruction bytes after the JMP are requested by the EU,
; so the EU doesn't have to wait for instruction bytes.
;
call ZTimerOn
rept 1000
push ax ;let the prefetch queue fill while
; the first instruction byte after
; each branch executes
jmp short $+2 ;we'll do a short jump,
; since the next instruction
; is less than 127 bytes
; away
endm
call ZTimerOff
```

## Listing 12-5

```nasm
;
; *** Listing 12-5 ***
;
; Measures the performance of PUSH AX.
;
call ZTimerOn
rept 1000
push ax
endm
call ZTimerOff
```

## Listing 13-1

```nasm
;
; *** Listing 13-1 ***
;
; Generates the cumulative exclusive-or of all bytes in a
; 64-byte block of memory by using the LOOP instruction to
; repeat the same code 64 times.
;
jmp Skip
;
; The 64-byte block for which to generate the cumulative
; exclusive-or.
;
X=1
ByteArray label byte
rept 64
db X
X=X+1
endm
;
; Generates the cumulative exclusive-or of all bytes in a
; 64-byte memory block.
;
; Input:
; SI = pointer to start of 64-byte block for which to
; calculate cumulative exclusive-or
;
; Output:
; AH = cumulative exclusive-or of all bytes in the
; 64-byte block
;
; Registers altered: AX, CX, SI
;
CumulativeXor:
cld
sub ah,ah ;initialize our cumulative XOR to 0
mov cx,64 ;number of bytes to XOR together
XorLoop:
lodsb ;get the next byte and
xor ah,al ; XOR it into the cumulative result
loop XorLoop
ret
;
Skip:
call ZTimerOn
mov si,offset ByteArray
;point to the 64-byte block
call CumulativeXor ;get the cumulative XOR
call ZTimerOff
```

## Listing 13-2

```nasm
;
; *** Listing 13-2 ***
;
; Generates the cumulative exclusive-or of all bytes in a
; 64-byte block of memory by replicating the exclusive-or
; code 64 times and then executing all 64 instances in a
; row without branching.
;
jmp Skip
;
; The 64-byte block for which to generate the cumulative
; exclusive-or.
;
X=1
ByteArray label byte
rept 64
db X
X=X+1
endm
;
; Generates the cumulative exclusive-or of all bytes in a
; 64-byte memory block.
;
; Input:
; SI = pointer to start of 64-byte block for which to
; calculate cumulative exclusive-or
;
; Output:
; AH = cumulative exclusive-or of all bytes in the
; 64-byte block
;
; Registers altered: AX, SI
;
CumulativeXor:
sub ah,ah ;initialize our cumulative XOR to 0
rept 64
lodsb ;get the next byte and
xor ah,al ; XOR it into the cumulative result
endm
ret
;
Skip:
call ZTimerOn
cld
mov si,offset ByteArray
;point to the 64-byte block
call CumulativeXor ;get the cumulative XOR
call ZTimerOff
```

## Listing 13-3

```nasm
;
; *** Listing 13-3 ***
;
; Tests whether several characters are in the set
; {A,Z,3,!} by using the compare-and-jump approach,
; branching each time a match isn't found.
;
jmp Skip
;
; Determines whether a given character is in the set
; {A,Z,3,!}.
;
; Input:
; AL = character to check for inclusion in the set
;
; Output:
; Z if character is in TestSet, NZ otherwise
;
; Registers altered: none
;
CheckTestSetInclusion:
cmp al,'A' ;is it 'A'?
jnz CheckTestSetZ
ret ;yes, we're done
CheckTestSetZ:
cmp al,'Z' ;is it 'Z'?
jnz CheckTestSet3
ret ;yes, we're done
CheckTestSet3:
cmp al,'3' ;is it '3'?
jnz CheckTestSetEx
ret ;yes, we're done
CheckTestSetEx:
cmp al,'!' ;is it '!'?
ret ;the success status is already in
; the Zero flag
;
Skip:
call ZTimerOn
mov al,'A'
call CheckTestSetInclusion ;check 'A'
mov al,'Z'
call CheckTestSetInclusion ;check 'Z'
mov al,'3'
call CheckTestSetInclusion ;check '3'
mov al,'!'
call CheckTestSetInclusion ;check '!'
mov al,' '
call CheckTestSetInclusion ;check space, so
; we've got a failed
; search
call ZTimerOff
```

## Listing 13-4

```nasm
;
; *** Listing 13-4 ***
;
; Negates several 32-bit values with non-branching code.
;
jmp Skip
;
; Negates a 32-bit value.
;
; Input:
; DX:AX = 32-bit value to negate
;
; Output:
; DX:AX = negated 32-bit value
;
; Registers altered: AX, DX
;
Negate32Bits:
neg dx
neg ax
sbb dx,0
ret
;
Skip:
call ZTimerOn
; First, negate zero.
sub dx,dx
mov ax,dx ;0
call Negate32Bits
; Next, negate 1 through 50.
X=1
rept 50
sub dx,dx
mov ax,X
call Negate32Bits
X=X+1
endm
; Finally, negate -1 through -50.
X=-1
rept 50
mov dx,0ffffh
mov ax,X
call Negate32Bits
X=X-1
endm
call ZTimerOff
```

## Listing 13-5

```nasm
;
; *** Listing 13-5 ***
;
; Negates several 32-bit values using the branch-on-zero-AX
; approach.
;
jmp Skip
;
; Negates a 32-bit value.
;
; Input:
; DX:AX = 32-bit value to negate
;
; Output:
; DX:AX = negated 32-bit value
;
; Registers altered: AX, DX
;
;
-------------------------------------------------------------------------------------------------
; Branching-out exit for Negate32Bits when AX negates to
; zero, necessitating an increment of DX.
;
Negate32BitsIncDX:
inc dx
ret
;
Negate32Bits:
not dx
neg ax
jnc Negate32BitsIncDX
ret
;
Skip:
call ZTimerOn
; First, negate zero.
sub dx,dx
mov ax,dx ;0
call Negate32Bits
; Next, negate 1 through 50.
X=1
rept 50
sub dx,dx
mov ax,X
call Negate32Bits
X=X+1
endm
; Finally, negate -1 through -50.
X=-1
rept 50
mov dx,0ffffh
mov ax,X
call Negate32Bits
X=X-1
endm
call ZTimerOff
```

## Listing 13-6

```nasm
;
; *** Listing 13-6 ***
;
; Measures the time needed to set AL, based on the contents
; of DL, with test-and-branch code (a branch is required no
; matter what value DL contains).
;
;
; Macro to perform the test of DL and setting of AL.
; It's necessary to use a macro because the LOCAL directive
; doesn't work properly inside REPT blocks with MASM.
;
TEST_DL_AND_SET_AL macro
local DLGreaterThan10, DLCheckDone
cmp dl,10 ;is DL greater than 10?
ja DLGreaterThan10 ;yes, so set AL to 1
sub al,al ;DLis <= 10
jmp short DLCheckDone
DLGreaterThan10:
mov al,1 ;DLis greater than 10
DLCheckDone:
endm
;
mov dl,10 ;AL will always be set to 0
call ZTimerOn
rept 1000
TEST_DL_AND_SET_AL
endm
call ZTimerOff
```

## Listing 13-7

```nasm
;
; *** Listing 13-7 ***
;
; Measures the time needed to set AL, based on the contents
; of DL, with preload code (a branch is required in only one
; of the two possible cases).
;
;
------------------------------------------------------------------------------------------------------
; Macro to perform the test of DL and setting of AL.
; It's necessary to use a macro because the LOCAL directive
; doesn't work properly inside REPT blocks with MASM.
;
TEST_DL_AND_SET_AL macro
local DLCheckDone
sub al,al ;assume DL <= 10
cmp dl,10 ;is DL greater than 10?
jbe DLCheckDone ;no, so ALis already set
mov al,1 ;DLis greater than 10
DLCheckDone:
endm
;
mov dl,10 ;AL will always be set to 0
call ZTimerOn
rept 1000
TEST_DL_AND_SET_AL
endm
call ZTimerOff
```

## Listing 13-8

```nasm
;
; *** Listing 13-8 ***
;
; Counts the number of negative values in a 1000-word array,
; by comparing each element to 0 and branching accordingly.
;
jmp Skip
;
WordArray label word
X=-500
rept 1000
dw X
X=X+1
endm
WORD_ARRAY_LENGTH equ ($-WordArray)
;
; Counts the number of negative values in a word-sized
; array.
;
; Input:
; CX = length of array in words
; DS:SI = pointer to start of array
;
; Output:
; DX = count of negative values in array
;
; Registers altered: AX, CX, DX, SI
;
; Direction flag cleared
;
; Note: Does not handle arrays that are longer than 32K
; words or cross segment boundaries.
;
CountNegativeWords:
cld
sub dx,dx ;initialize the count to 0
CountNegativeWordsLoop:
lodsw ;get the next word from the array
and ax,ax ;is the word negative?
jns CountNegativeWordsLoopBottom
;not negative-do the next element
inc dx ;word is negative, so increment the
; negative-word counter
CountNegativeWordsLoopBottom:
loop CountNegativeWordsLoop
ret
;
Skip:
call ZTimerOn
mov si,offset WordArray
;point to the array to count
; the # of negative words in...
mov cx,WORD_ARRAY_LENGTH/2
;...set the # of words to check...
call CountNegativeWords
;...and count the negative words
call ZTimerOff
```

## Listing 13-9

```nasm
;
; *** Listing 13-9 ***
;
; Counts the number of negative values in a 1000-word array,
; by adding the Sign bit of each array element directly to
; the register used for counting.
;
jmp Skip
;
WordArray label word
X=-500
rept 1000
dw X
X=X+1
endm
WORD_ARRAY_LENGTH equ ($-WordArray)
;
; Counts the number of negative values in a word-sized
; array.
;
; Input:
; CX = length of array in words
; DS:SI = pointer to start of array
;
; Output:
; DX = count of negative values in array
;
; Registers altered: AX, BX, CX, DX, SI
;
; Direction flag cleared
;
; Note: Does not handle arrays that are longer than 32K
; words or cross segment boundaries.
;
CountNegativeWords:
cld
sub dx,dx ;initialize the count to 0
mov bx,dx ;store the constant 0 in BX to speed
; up ADC in the loop
CountNegativeWordsLoop:
lodsw ;get the next word from the array
shl ax,1 ;put the sign bit in the Carry flag
adc dx,bx ;add the sign bit (via the Carry
; flag) to DX, since BX is 0
CountNegativeWordsLoopBottom:
loop CountNegativeWordsLoop
ret
;
Skip:
call ZTimerOn
mov si,offset WordArray
;point to the array to count
; the # of negative words in...
mov cx,WORD_ARRAY_LENGTH/2
;...set the # of words to check...
call CountNegativeWords
;...and count the negative words
call ZTimerOff
```

## Listing 13-10

```nasm
;
; *** Listing 13-10 ***
;
; Finds the first occurrence of the letter 'z' in
; a zero-terminated string, with a less-than-ideal
; conditional jump followed by an unconditional jump at
; the end of the loop.
;
jmp Skip
;
TestString label byte
db 'This is a test string that is '
db 'z'
db 'terminated with a zero byte...',0
;
; Finds the first occurrence of the specified byte in the
; specified zero-terminated string.
;
; Input:
; AL = byte to find
; DS:SI = zero-terminated string to search
;
; Output:
; SI = pointer to first occurrence of byte in string,
; or 0 if the byte wasn't found
;
; Registers altered: AX, SI
;
; Direction flag cleared
;
; Note: Do not pass a string that starts at offset 0 (SI=0),
; since a match on the first byte and failure to find
; the byte would be indistinguishable.
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
FindCharInString:
mov ah,al ;we'll need AL since that's the
; only register LODSB can use
cld
FindCharInStringLoop:
lodsb ;get the next string byte
cmp al,ah ;is this the byte we're
; looking for?
jz FindCharInStringFound
;yes, so we're done with a match
and al,al ;is this the terminating zero?
jz FindCharInStringNotFound
;yes, so we're done with no match
jmp FindCharInStringLoop
;check the next byte
FindCharInStringFound:
dec si ;point back to the matching byte
ret
FindCharInStringNotFound:
sub si,si ;we didn't find a match, so return
; 0 in SI
ret
;
Skip:
call ZTimerOn
mov al,'z' ;byte value to find
mov si,offset TestString
;string to search
call FindCharInString ;search for the byte
call ZTimerOff
```

## Listing 13-11

```nasm
;
; *** Listing 13-11 ***
;
; Determines whether there are more non-negative or negative
; elements in an array of 8-bit signed values, using a
; standard test-and-branch approach and a single LOOP
; instruction.
;
jmp Skip
;
ARRAY_LENGTH equ 256
ByteArray label byte
X=0
rept ARRAY_LENGTH
db X
X=X+1
endm
;
; Determines whether there are more non-negative or
; negative elements in the specified array of 8-bit
; signed values.
;
; Input:
; CX = length of array
; DS:SI = array to check
;
; Output:
; DX = signed count of the number of non-negative
; elements found in the array minus the number
; of negative elements found. (Zero if there
; are the same number of each type of element.
; Otherwise, sign bit set if there are more
; negative elements than non-negative
; elements, cleared if there are more
; non-negative elements than negative
; elements)
;
; Registers altered: AL, CX, DX, SI
;
; Direction flag cleared
;
; Note: Only usefuLif the surplus of non-negative
; elements over negative elements is less than
; 32K, or if the surplus of negative elements
; over non-negative elements is less than or
; equal to 32K. Otherwise, the signed count
; returned in DX overflows.
;
; Note: Does not handle arrays that are longer than 64K
; bytes or cross segment boundaries.
;
CountNegPos:
cld
sub dx,dx ;initialize the count to zero
CountNegPosLoop:
lodsb ;get the next byte to check
and al,al ;see if it's negative or
; non-negative
js CountNeg ;it's negative
inc dx ;count off one non-negative element
jmp short CountNegPosLoopBottom
CountNeg:
dec dx ;count off one negative element
CountNegPosLoopBottom:
loop CountNegPosLoop
ret
;
Skip:
call ZTimerOn
mov si,offset ByteArray ;array to check
mov cx,ARRAY_LENGTH ;# of bytes to check
call CountNegPos ;see whether there
; are more negative
; or non-negative
; elements
call ZTimerOff
```

## Listing 13-12

```nasm
; *** Listing 13-12 ***
;
; Determines whether there are more non-negative or negative
; elements in an array of 8-bit signed values, using
; duplicated code with two LOOP instructions and two RET
; instructions.
;
jmp Skip
;
ARRAY_LENGTH equ 256
ByteArray label byte
X=0
rept ARRAY_LENGTH
db X
X=X+1
endm
;
; Determines whether there are more non-negative or
; negative elements in the specified array of 8-bit
; signed values.
;
; Input:
; CX = length of array
; DS:SI = array to check
;
; Output:
; DX = signed count of the number of non-negative
; elements found in the array minus the number
; of negative elements found. (Zero if there
; are the same number of each type of element.
; Otherwise, sign bit set if there are more
; negative elements than non-negative
; elements, cleared if there are more
; non-negative elements than negative
; elements)
;
; Registers altered: AL, CX, DX, SI
;
; Direction flag cleared
;
; Note: Only usefuLif the surplus of non-negative
; elements over negative elements is less than
; 32K, or if the surplus of negative elements
; over non-negative elements is less than or
; equal to 32K. Otherwise, the signed count
; returned in DX overflows.
;
; Note: Does not handle arrays that are longer than 64K
; bytes or cross segment boundaries.
;
CountNegPos:
cld
sub dx,dx ;initialize the count to zero
CountNegPosLoop:
lodsb ;get the next byte to check
and al,al ;see if it's negative or
; non-negative
js CountNeg ;it's negative
inc dx ;count off one non-negative element
loop CountNegPosLoop
ret
CountNeg:
dec dx ;count off one negative element
loop CountNegPosLoop
ret
;
Skip:
call ZTimerOn
mov si,offset ByteArray ;array to check
mov cx,ARRAY_LENGTH ;# of bytes to check
call CountNegPos ;see whether there
; are more negative
; or non-negative
; elements
call ZTimerOff
```

## Listing 13-13

```nasm
;
; *** Listing 13-13 ***
;
; Copies a zero-terminated string to another string,
; optionally converting characters to uppercase. The
; decision as to whether to convert to uppercase is made
; once for each character.
;
jmp Skip
;
SourceString label byte
db 'This is a sample string, consisting of '
db 'both uppercase and lowercase characters.'
db 0
DestinationString label byte
db 100 dup (?)
;
; Copies a zero-terminated string to another string,
; optionally converting characters to uppercase.
;
; Input:
; DL = 1 if conversion to uppercase during copying is
; desired, 0 otherwise
; DS:SI = source string
; ES:DI = destination string
;
; Output: none
;
; Registers altered: AL, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CopyAndConvert:
cld
CopyAndConvertLoop:
lodsb ;get the next byte
; to check
and dl,dl ;conversion to
; uppercase desired?
jz CopyAndConvertUC ;no
cmp al,'a' ;less than 'a'?
jb CopyAndConvertUC ;yes, not lowercase
cmp al,'z' ;greater than 'z'?
ja CopyAndConvertUC ;yes, not lowercase
and al,not 20h ;make it uppercase
CopyAndConvertUC:
stosb ;put the byte in the
; destination string
and al,al ;was that the
; terminating zero?
jnz CopyAndConvertLoop ;no, do next byte
ret
;
Skip:
call ZTimerOn
;
; First, copy without converting to uppercase.
;
mov di,seg DestinationString
mov es,di
mov di,offset DestinationString
;ES:DI points to the destination
mov si,offset SourceString
;DS:SI points to the source
sub dl,dl ;don't convert to uppercase
call CopyAndConvert ;copy without converting
; to uppercase
;
; Now copy and convert to uppercase.
;
mov di,offset DestinationString
;ES:DI points to the destination
mov si,offset SourceString
;DS:SI points to the source
mov dl,1 ;convert to uppercase this time
call CopyAndConvert ;copy and convert to
; uppercase
call ZTimerOff
```

## Listing 13-14

```nasm
;
; *** Listing 13-14 ***
;
; Copies a zero-terminated string to another string,
; optionally converting characters to uppercase. The
; decision as to whether to convert to uppercase is made
; once at the beginning of the subroutine; if conversion
; is not desired, the register containing the value of the
; start of the lowercase range is simply set to cause all
; tests for lowercase to fail. This avoids one test in the
; case where conversion to uppercase is desired, since the
; single test for the start of the lowercase range is able
; to perform both that test and the test for whether
; conversion is desired.
;
jmp Skip
;
SourceString label byte
db 'This is a sample string, consisting of '
db 'both uppercase and lowercase characters.'
db 0
DestinationString label byte
db 100 dup (?)
;
; Copies a zero-terminated string to another string,
; optionally converting characters to uppercase.
;
; Input:
; DL = 1 if conversion to uppercase during copying is
; desired, 0 otherwise
; DS:SI = source string
; ES:DI = destination string
;
; Output: none
;
; Registers altered: AX, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CopyAndConvert:
cld
mov ah,0ffh ;assume conversion to uppercase is
; not desired. In that case, this
; value will cause the initial
; lowercase test to fail (except
; when the character is 0FFh, but
; that's rare and will be rejected
; by the second lowercase test
and dl,dl ;is conversion to uppercase desired?
jz CopyAndConvertLoop ;no, AH is all set
mov ah,'a' ;set the proper lower limit of the
; lowercase range
CopyAndConvertLoop:
lodsb ;get the next byte
; to check
cmp al,ah ;less than 'a'?
; (If conversion
; isn't desired,
; AH is 0FFh, and
; this fails)
jb CopyAndConvertUC ;yes, not lowercase
cmp al,'z' ;greater than 'z'?
ja CopyAndConvertUC ;yes, not lowercase
and al,not 20h ;make it uppercase
CopyAndConvertUC:
stosb ;put the byte in the
; destination string
and al,al ;was that the
; terminating zero?
jnz CopyAndConvertLoop ;no, do next byte
ret
;
Skip:
call ZTimerOn
;
; First, copy without converting to uppercase.
;
mov di,seg DestinationString
mov es,di
mov di,offset DestinationString
;ES:DI points to the destination
mov si,offset SourceString
;DS:SI points to the source
sub dl,dl ;don't convert to uppercase
call CopyAndConvert ;copy without converting
; to uppercase
;
; Now copy and convert to uppercase.
;
mov di,offset DestinationString
;ES:DI points to the destination
mov si,offset SourceString
;DS:SI points to the source
mov dl,1 ;convert to uppercase this time
call CopyAndConvert ;copy and convert to
; uppercase
call ZTimerOff
```

## Listing 13-15

```nasm
;
; *** Listing 13-15 ***
;
; Copies a zero-terminated string to another string,
; optionally converting characters to uppercase. The
; decision as to whether to convert to uppercase is made
; once at the beginning of the subroutine, with separate
; code executed depending on whether conversion is desired
; or not.
;
jmp Skip
;
SourceString label byte
db 'This is a sample string, consisting of '
db 'both uppercase and lowercase characters.'
db 0
DestinationString label byte
db 100 dup (?)
;
; Copies a zero-terminated string to another string,
; optionally converting characters to uppercase.
;
; Input:
; DL = 1 if conversion to uppercase during copying is
; desired, 0 otherwise
; DS:SI = source string
; ES:DI = destination string
;
; Output: none
;
; Registers altered: AL, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CopyAndConvert:
cld
and dl,dl ;is conversion desired?
jz CopyLoop ;no, so just copy the string
;
; Copy the string, converting to uppercase.
;
CopyAndConvertLoop:
lodsb ;get the next byte
; to check
cmp al,'a' ;less than 'a'?
jb CopyAndConvertUC ;yes, not lowercase
cmp al,'z' ;greater than 'z'?
ja CopyAndConvertUC ;yes, not lowercase
and al,not 20h ;make it uppercase
CopyAndConvertUC:
stosb ;put the byte in the
; destination string
and al,al ;was that the
; terminating zero?
jnz CopyAndConvertLoop ;no, do next byte
ret
;
; Copy the string without conversion to uppercase.
;
CopyLoop:
lodsb ;get the next byte to check
stosb ;copy the byte
and al,al ;was that the terminating 0?
jnz CopyLoop ;no, do next byte
ret
;
Skip:
call ZTimerOn
;
; First, copy without converting to uppercase.
;
mov di,seg DestinationString
mov es,di
mov di,offset DestinationString
;ES:DI points to the destination
mov si,offset SourceString
;DS:SI points to the source
sub dl,dl ;don't convert to uppercase
call CopyAndConvert ;copy without converting
; to uppercase
;
; Now copy and convert to uppercase.
;
mov di,offset DestinationString
;ES:DI points to the destination
mov si,offset SourceString
;DS:SI points to the source
mov dl,1 ;convert to uppercase this time
call CopyAndConvert ;copy and convert to
; uppercase
call ZTimerOff
```

## Listing 13-16

```nasm
;
; *** Listing 13-16 ***
;
; Copies a zero-terminated string to another string,
; filtering out non-printable characters by means of a
; subroutine that performs the test.
;
jmp Skip
;
SourceString label byte
db 'This is a sample string, consisting of '
X=1
rept 31
db X
X=X+1
endm
db 7fh
db 'both printable and non-printable '
db 'characters', 0
DestinationString label byte
db 200 dup (?)
;
; Determines whether a character is printable (in the range
; 20h through 7Eh).
;
; Input:
; AL = character to check
;
; Output:
; Zero flag set to 1 if character is printable,
; set to 0 otherwise
;
; Registers altered: none
;
IsPrintable:
cmp al,20h
jb IsPrintableDone ;not printable
cmp al,7eh
ja IsPrintableDone ;not printable
cmp al,al ;set the Zero flag to 1, since the
; character is printable
IsPrintableDone:
ret
;
; Copies a zero-terminated string to another string,
; filtering out non-printable characters.
;
; Input:
; DS:SI = source string
; ES:DI = destination string
;
; Output: none
;
; Registers altered: AL, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CopyPrintable:
cld
CopyPrintableLoop:
lodsb ;get the next byte to copy
call IsPrintable ;is it printable?
jnz NotPrintable ;nope, don't copy it
stosb ;put the byte in the
; destination string
jmp CopyPrintableLoop ;the character was
; printable, so it couldn't
; possibly have been 0. No
; need to check whether it
; terminated the string
NotPrintable:
and al,al ;was that the
; terminating zero?
jnz CopyPrintableLoop ;no, do next byte
stosb ;copy the terminating zero
ret ;done
;
Skip:
call ZTimerOn
mov di,seg DestinationString
mov es,di
mov di,offset DestinationString
;ES:DI points to the destination
mov si,offset SourceString
;DS:SI points to the source
call CopyPrintable ;copy the printable
; characters
call ZTimerOff
```

## Listing 13-17

```nasm
;
; *** Listing 13-17 ***
;
; Copies a zero-terminated string to another string,
; filtering out non-printable characters by means of a
; macro that performs the test.
;
jmp Skip
;
SourceString label byte
db 'This is a sample string, consisting of '
X=1
rept 31
db X
X=X+1
endm
db 7fh
db 'both printable and non-printable '
db 'characters', 0
DestinationString label byte
db 200 dup (?)
;
; Macro that determines whether a character is printable (in
; the range 20h through 7Eh).
;
; Input:
; AL = character to check
;
; Output:
; Zero flag set to 1 if character is printable,
; set to 0 otherwise
;
; Registers altered: none
;
IS_PRINTABLE macro
local IsPrintableDone
cmp al,20h
jb IsPrintableDone ;not printable
cmp al,7eh
ja IsPrintableDone ;not printable
cmp al,al ;set the Zero flag to 1, since the
; character is printable
IsPrintableDone:
endm
;
; Copies a zero-terminated string to another string,
; filtering out non-printable characters.
;
; Input:
; DS:SI = source string
; ES:DI = destination string
;
; Output: none
;
; Registers altered: AL, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CopyPrintable:
cld
CopyPrintableLoop:
lodsb ;get the next byte to copy
IS_PRINTABLE ;is it printable?
jnz NotPrintable ;nope, don't copy it
stosb ;put the byte in the
; destination string
jmp CopyPrintableLoop ;the character was
; printable, so it couldn't
; possibly have been 0. No
; need to check whether it
; terminated the string
NotPrintable:
and al,al ;was that the
; terminating zero?
jnz CopyPrintableLoop ;no, do next byte
stosb ;copy the terminating zero
ret ;done
;
Skip:
call ZTimerOn
mov di,seg DestinationString
mov es,di
mov di,offset DestinationString
;ES:DI points to the destination
mov si,offset SourceString
;DS:SI points to the source
call CopyPrintable ;copy the printable
; characters
call ZTimerOff
```

## Listing 13-18

```nasm
;
; *** Listing 13-18 ***
;
; Copies a zero-terminated string to another string,
; filtering out non-printable characters by means of
; carefully customized code that performs the test
; directly in the loop.
;
jmp Skip
;
SourceString label byte
db 'This is a sample string, consisting of '
X=1
rept 31
db X
X=X+1
endm
db 7fh
db 'both printable and non-printable '
db 'characters', 0
DestinationString label byte
db 200 dup (?)
;
; Copies a zero-terminated string to another string,
; filtering out non-printable characters.
;
; Input:
; DS:SI = source string
; ES:DI = destination string
;
; Output: none
;
; Registers altered: AL, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CopyPrintable:
cld
CopyPrintableLoop:
lodsb ;get the next byte to copy
cmp al,20h
jb NotPrintable ;not printable
cmp al,7eh
ja CopyPrintableLoop ;not printable
stosb ;put the byte in the
; destination string
jmp CopyPrintableLoop ;the character was
; printable, so it couldn't
; possibly have been 0. No
; need to check whether it
; terminated the string
NotPrintable:
and al,al ;was that the
; terminating zero?
jnz CopyPrintableLoop ;no, do next byte
stosb ;copy the terminating zero
ret ;done
;
Skip:
call ZTimerOn
mov di,seg DestinationString
mov es,di
mov di,offset DestinationString
;ES:DI points to the destination
mov si,offset SourceString
;DS:SI points to the source
call CopyPrintable ;copy the printable
; characters
call ZTimerOff
```

## Listing 13-19

```nasm
;
; *** Listing 13-19 ***
;
; Zeros the high-bit of each byte in a 100-byte array,
; using the LOOP instruction.
;
jmp Skip
;
ARRAY_LENGTH equ 100
ByteArray label byte
db ARRAY_LENGTH dup (80h)
;
; Clears the high bit of each byte in an array of
; length ARRAY_LENGTH.
;
; Input:
; BX = pointer to the start of the array to clear
;
; Output: none
;
; Registers altered: AL, BX, CX
;
ClearHighBits:
mov cx,ARRAY_LENGTH ;# of bytes to clear
mov al,not 80h ;pattern to clear
; high bits with
ClearHighBitsLoop:
and [bx],al ;clear the high bit
; of this byte
inc bx ;point to the next
; byte
loop ClearHighBitsLoop ;repeat until we're
; out of bytes
ret
;
Skip:
call ZTimerOn
mov bx,offset ByteArray
;array in which to clear
; high bits
call ClearHighBits ;clear the high bits of the
; bytes
call ZTimerOff
```

## Listing 13-20

```nasm
;
; *** Listing 13-20 ***
;
; Zeros the high-bit of each byte in a 100-byte array,
; using in-line code.
;
jmp Skip
;
ARRAY_LENGTH equ 100
ByteArray label byte
db ARRAY_LENGTH dup (80h)
;
; Clears the high bit of each byte in an array of
; length ARRAY_LENGTH.
;
; Input:
; BX = pointer to the start of the array to clear
;
; Output: none
;
; Registers altered: AL, BX
;
ClearHighBits:
mov al,not 80h ;pattern to clear
; high bits with
rept ARRAY_LENGTH ;# of bytes to clear
and [bx],al ;clear the high bit
; of this byte
inc bx ;point to the next
; byte
endm
ret
;
Skip:
call ZTimerOn
mov bx,offset ByteArray
;array in which to clear
; high bits
call ClearHighBits ;clear the high bits of the
; bytes
call ZTimerOff
```

## Listing 13-21

```nasm
;
; *** Listing 13-21 ***
;
; Replacement code for XorImage in Listing 11-33.
; This version uses in-line code to eliminate branching
; during the drawing of each image line.
;-----------------------------
; Exclusive-ors the image of a 3-color square at the
; specified screen location. Assumes images start on
; even-numbered scan lines and are an even number of
; scan lines high. Always draws images byte-aligned in
; display memory.
;
; Input:
; CX = X coordinate of upper left corner at which to
; draw image (will be adjusted to nearest
; less-than or equal-to multiple of 4 in order
; to byte-align)
; DX = Y coordinate of upper left corner at which to
; draw image
; ES = display memory segment
;
; Output: none
;
; Registers altered: AX, CX, DX, SI, DI, BP
;
XorImage:
shr dx,1 ;divide the row # by 2 to compensate
; for the 2-bank nature of 320x200
; 4-color mode
mov ax,SCREEN_WIDTH
mul dx ;start offset of top row of image in
; display memory
shr cx,1 ;divide the X coordinate by 4
shr cx,1 ; because there are 4 pixels per
; byte
add ax,cx ;point to the offset at which the
; upper left byte of the image will
; go
mov di,ax
mov si,offset TheImage
;point to the start of the one image
; we always draw
mov dx,BANK_OFFSET-IMAGE_WIDTH
;offset from the end of an even line
; of the image in display memory to
; the start of the next odd line of
; the image
mov bp,BANK_OFFSET-SCREEN_WIDTH+IMAGE_WIDTH
;offset from the end of an odd line
; of the image in display memory to
; the start of the next even line of
; the image
mov cx,IMAGE_HEIGHT/2
;# of even/odd numbered row pairs to
; draw in the image
XorRowLoop:
rept IMAGE_WIDTH/2
lodsw ;next word of the image pattern
xor es:[di],ax ;XOR the next word of the
; image into the screen
inc di ;point to the next word in display
inc di ; memory
endm
add di,dx ;point to the start of the next
; (odd) row of the image, which is
; in the second bank of display
; memory
rept IMAGE_WIDTH/2
lodsw ;next word of the image pattern
xor es:[di],ax ;XOR the next word of the
; image into the screen
inc di ;point to the next word in display
inc di ; memory
endm
sub di,bp ;point to the start of the next
; (even) row of the image, which is
; in the first bank of display
; memory
loop XorRowLoop ;count down the row pairs
ret
```

## Listing 13-22

```nasm
;
; *** Listing 13-22 ***
;
; Replacement code for BlockDrawImage in Listing 11-34.
; This version uses in-line code to eliminate branching
; entirely during the drawing of each image (eliminates
; the branching between the drawing of each pair of lines.)
;-----------------------------
; Block-move draws the image of a 3-color square at the
; specified screen location. Assumes images start on
; even-numbered scan lines and are an even number of
; scan lines high. Always draws images byte-aligned in
; display memory.
;
; Input:
; CX = X coordinate of upper left corner at which to
; draw image (will be adjusted to nearest
; less-than or equal-to multiple of 4 in order
; to byte-align)
; DX = Y coordinate of upper left corner at which to
; draw image
; ES = display memory segment
;
; Output: none
;
; Registers altered: AX, CX, DX, SI, DI, BP
;
BlockDrawImage:
shr dx,1 ;divide the row # by 2 to compensate
; for the 2-bank nature of 320x200
; 4-color mode
mov ax,SCREEN_WIDTH
mul dx ;start offset of top row of image in
; display memory
shr cx,1 ;divide the X coordinate by 4
shr cx,1 ; because there are 4 pixels per
; byte
add ax,cx ;point to the offset at which the
; upper left byte of the image will
; go
mov di,ax
mov si,offset TheImage
;point to the start of the one image
; we always draw
mov ax,BANK_OFFSET-SCREEN_WIDTH+IMAGE_WIDTH
;offset from the end of an odd line
; of the image in display memory to
; the start of the next even line of
; the image
mov dx,BANK_OFFSET-IMAGE_WIDTH
;offset from the end of an even line
; of the image in display memory to
; the start of the next odd line of
; the image
mov bp,IMAGE_WIDTH/2
;# of words to draw per row of the
; image. Note that IMAGE_WIDTH must
; be an even number since we XOR
; the image a word at a time
rept IMAGE_HEIGHT/2
mov cx,bp ;# of words to draw per row of the
; image
rep movsw ;draw a whole even row with this one
; repeated instruction
add di,dx ;point to the start of the next
; (odd) row of the image, which is
; in the second bank of display
; memory
mov cx,bp ;# of words to draw per row of the
; image
rep movsw ;draw a whole odd row with this one
; repeated instruction
sub di,ax
;point to the start of the next
; (even) row of the image, which is
; in the first bank of display
; memory
endm
ret
```

## Listing 13-23

```nasm
;
; *** Listing 13-23 ***
;
; Zeros the high-bit of each byte in a 100-byte array,
; using branched-to in-line code.
;
jmp Skip
;
MAXIMUM_ARRAY_LENGTH equ 200
ARRAY_LENGTH equ 100
ByteArray label byte
db ARRAY_LENGTH dup (80h)
;
; Clears the high bit of each byte in an array.
;
; Input:
; BX = pointer to the start of the array to clear
; CX = number of bytes to clear (no greater than
; MAXIMUM_ARRAY_LENGTH)
;
; Output: none
;
; Registers altered: AX, BX, CX
;
ClearHighBits:
;
; Calculate the offset in the in-line code to which to jump
; in order to get the desired number of repetitions.
;
mov al,InLineBitClearEnd-SingleRepetitionStart
;# of bytes per single
; repetition of
; AND [BX],AL/INC BX
mul cl ;# of code bytes in the # of
; repetitions desired
mov cx,offset InLineBitClearEnd
sub cx,ax ;point back just enough
; instruction bytes from
; the end of the in-line
; code to perform the
; desired # of repetitions
mov al,not 80h ;pattern to clear high bits
; with
jmp cx ;finally, branch to perform
; the desired # of
; repetitions
;
; In-line code to clear the high bits of up to the maximum #
; of bytes.
;
rept MAXIMUM_ARRAY_LENGTH-1
;maximum # of bytes to clear
; less 1
and [bx],al ;clear the high bit of this
; byte
inc bx ;point to the next byte
endm
SingleRepetitionStart: ;a single repetition of the
; loop code, so we can
; calculate the length of
; a single repetition
and [bx],dl ;clear the high bit of this
; byte
inc bx ;point to the next byte
InLineBitClearEnd:
ret
;
Skip:
call ZTimerOn
mov bx,offset ByteArray
;array in which to clear
; high bits
mov cx,ARRAY_LENGTH ;# of bytes to clear
; (always less than
; MAXIMUM_ARRAY_LENGTH)
call ClearHighBits ;clear the high bits of the
; bytes
call ZTimerOff
```

## Listing 13-24

```nasm
;
; *** Listing 13-24 ***
;
; Zeros the high-bit of each byte in a 100-byte array,
; using partiaLin-line code.
;
jmp Skip
;
ARRAY_LENGTH equ 100
ByteArray label byte
db ARRAY_LENGTH dup (80h)
;
; Clears the high bit of each byte in an array.
;
; Input:
; BX = pointer to the start of the array to clear
; CX = number of bytes to clear (must be a multiple
; of 4)
;
; Output: none
;
; Registers altered: AL, BX, CX
;
ClearHighBits:
mov al,not 80h ;pattern to clear
; high bits with
shr cx,1 ;# of passes through
shr cx,1 ; partiaLin-line
; loop, which does
; 4 bytes at a pop
ClearHighBitsLoop:
rept 4 ;we'll put 4 bit-
; clears back to
; back, then loop
and [bx],al ;clear the high bit
; of this byte
inc bx ;point to the next
; byte
endm
loop ClearHighBitsLoop
ret
;
Skip:
call ZTimerOn
mov bx,offset ByteArray
;array in which to clear
; high bits
mov cx,ARRAY_LENGTH ;# of bytes to clear
; (always a multiple of 4)
call ClearHighBits ;clear the high bits of the
; bytes
call ZTimerOff
```

## Listing 13-25

```nasm
;
; *** Listing 13-25 ***
;
; Zeros the high-bit of each byte in a 100-byte array,
; using branched-to partiaLin-line code.
;
jmp Skip
;
ARRAY_LENGTH equ 100
ByteArray label byte
db ARRAY_LENGTH dup (80h)
;
; Clears the high bit of each byte in an array.
;
; Input:
; BX = pointer to the start of the array to clear
; CX = number of bytes to clear (0 means 0)
;
; Output: none
;
; Registers altered: AX, BX, CX, DX
;
ClearHighBits:
;
; Calculate the offset in the partiaLin-line code to which
; to jump in order to perform CX modulo 4 repetitions (the
; remaining repetitions will be handled by full passes
; through the loop).
;
mov ax,cx
and ax,3 ;# of repetitions modulo 4
mov dx,ax
shl ax,1
add ax,dx ;(# of reps modulo 4) * 3
; is the # of bytes from the
; the end of the partial
; in-line code to branch to
; in order to handle the
; # of repetitions that
; can't be handled in a full
; loop
mov dx,offset InLineBitClearEnd
sub dx,ax ;point back just enough
; instruction bytes from
; the end of the in-line
; code to perform the
; desired # of repetitions
shr cx,1 ;divide by 4, since we'll do
shr cx,1 ; 4 repetitions per loop
inc cx ;account for the first,
; partial pass through the
; loop
mov al,not 80h ;pattern to clear high bits
; with
jmp dx ;finally, branch to perform
; the desired # of
; repetitions
;
; PartiaLin-line code to clear the high bits of 4 bytes per
; pass through the loop.
;
ClearHighBitsLoop:
rept 4
and [bx],al ;clear the high bit of this
; byte
inc bx ;point to the next byte
endm
InLineBitClearEnd:
loop ClearHighBitsLoop
ret
;
Skip:
call ZTimerOn
mov bx,offset ByteArray
;array in which to clear
; high bits
mov cx,ARRAY_LENGTH ;# of bytes to clear
; (always less than
; MAXIMUM_ARRAY_LENGTH)
call ClearHighBits ;clear the high bits of the
; bytes
call ZTimerOff
```

## Listing 13-26

```nasm
;
; *** Listing 13-26 ***
;
; Replacement code for ClearHighBits in Listing 13-25.
; This version performs 64K rather than 0 repetitions
; when CX is 0.
;-----------------------------
; Clears the high bit of each byte in an array.
;
; Input:
; BX = pointer to the start of the array to clear
; CX = number of bytes to clear (0 means 64K)
;
; Output: none
;
; Registers altered: AX, BX, CX, DX
;
ClearHighBits:
;
; Calculate the offset in the partiaLin-line code to which
; to jump in order to perform CX modulo 4 repetitions (the
; remaining repetitions will be handled by full passes
; through the loop).
;
dec cx ;# of reps -1, since 1 to 4
; (rather than 0 to 3) repetitions
; are performed on the first,
; possibly partial pass through
; the loop

mov ax,cx
and ax,3 ;# of repetitions modulo 4
inc ax ;(# of reps modulo 4)+1 in order to
; perform 1 to 4 repetitions on the
; first, possibly partial pass
; through the loop
mov dx,ax
shl ax,1
add ax,dx ;(((# of reps -1) modulo 4)+1)*3
; is the # of bytes from the
; the end of the partial
; in-line code to branch to
; in order to handle the
; # of repetitions that
; must be handled in the
; first, possibly partial
; loop
mov dx,offset InLineBitClearEnd
sub dx,ax ;point back just enough
; instruction bytes from
; the end of the in-line
; code to perform the
; desired # of repetitions
shr cx,1 ;divide by 4, since we'll do
shr cx,1 ; 4 repetitions per loop
inc cx ;account for the first,
; possibly partial pass
; through the loop
mov al,not 80h
;pattern with which to clear
; high bits
jmp dx ;finally, branch to perform
; the desired # of repetitions
;
; PartiaLin-line code to clear the high bits of 4 bytes per
; pass through the loop.
;
ClearHighBitsLoop:
rept 4
and [bx],al ;clear the high bit of this
; byte
inc bx ;point to the next byte
endm
InLineBitClearEnd:
loop ClearHighBitsLoop
ret
```

## Listing 13-27

```nasm
;
; *** Listing 13-27 ***
;
; Determines whether two zero-terminated strings differ, and
; if so where, using LODS/SCAS and partiaLin-line code.
;
jmp Skip
;
TestString1 label byte
db 'This is a test string that is '
db 'z'
db 'terminated with a zero byte...',0
TestString2 label byte
db 'This is a test string that is '
db 'a'
db 'terminated with a zero byte...',0
;
; Compares two zero-terminated strings.
;
; Input:
; DS:SI = first zero-terminated string
; ES:DI = second zero-terminated string
;
; Output:
; DS:SI = pointer to first differing location in
; first string, or 0 if the byte wasn't found
; ES:DI = pointer to first differing location in
; second string, or 0 if the byte wasn't found
;
; Registers altered: AX, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CompareStrings:
cld
CompareStringsLoop:
;
; First 7 repetitions of partiaLin-line code.
;
rept 7
lodsw ;get the next 2 bytes
and al,al ;is the first byte the terminating
; zero?
jz CompareStringsFinalByte
;yes, so there's only one byte left
; to check
scasw ;compare this word
jnz CompareStringsDifferent ;the strings differ
and ah,ah ;is the second byte the terminating
; zero?
jz CompareStringsSame
;yes, we've got a match
endm
;
; Final repetition of partiaLin-line code.
;
lodsw ;get the next 2 bytes
and al,al ;is the first byte the terminating
; zero?
jz CompareStringsFinalByte
;yes, so there's only one byte left
; to check
scasw ;compare this word
jnz CompareStringsDifferent ;the strings differ
and ah,ah ;is the second byte the terminating
; zero?
jnz CompareStringsLoop ;no, continue comparing
;the strings are the same
CompareStringsSame:
sub si,si ;return 0 pointers indicating that
mov di,si ; the strings are identical
ret
CompareStringsFinalByte:
scasb ;does the terminating zero match in
; the 2 strings?
jz CompareStringsSame ;yes, the strings match
dec si ;point back to the differing byte
dec di ; in each string
ret
CompareStringsDifferent:
;the strings are different, so we
; have to figure which byte in the
; word just compared was the first
; difference
dec si
dec si ;point back to the first byte of the
dec di ; differing word in each string
dec di
lodsb
scasb ;compare that first byte again
jz CompareStringsDone
;if the first bytes are the same,
; then it must have been the second
; bytes that differed. That's where
; we're pointing, so we're done
dec si ;the first bytes differed, so point
dec di ; back to them
CompareStringsDone:
ret
;
Skip:
call ZTimerOn
mov si,offset TestString1 ;point to one string
mov di,seg TestString2
mov es,di
mov di,offset TestString2 ;point to other string
call CompareStrings ;and compare the strings
call ZTimerOff
```

## Listing 14-1

```nasm
;
; *** Listing 14-1 ***
;
; Copies a zero-terminated string to another string,
; filtering out non-printable characters by means of a
; subroutine that performs the test. The subroutine is
; called with a far call and returns with a far return.
;
jmp Skip
;
SourceString label byte
db 'This is a sample string, consisting of '
X=1
rept 31
db X
X=X+1
endm
db 7fh
db 'both printable and non-printable '
db 'characters', 0
DestinationString label byte
db 200 dup (?)
;
; Determines whether a character is printable (in the range
; 20h through 7Eh).
;
; Input:
; AL = character to check
;
; Output:
; Zero flag set to 1 if character is printable,
; set to 0 otherwise
;
; Registers altered: none
;
IsPrintable proc far
cmp al,20h
jb IsPrintableDone ;not printable
cmp al,7eh
ja IsPrintableDone ;not printable
cmp al,al ;set the Zero flag to 1, since the
; character is printable
IsPrintableDone:
ret
IsPrintable endp
;
; Copies a zero-terminated string to another string,
; filtering out non-printable characters.
;
; Input:
; DS:SI = source string
; ES:DI = destination string
;
; Output: none
;
; Registers altered: AL, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CopyPrintable:
cld
CopyPrintableLoop:
lodsb ;get the next byte to copy
call IsPrintable ;is it printable?
jnz NotPrintable ;nope, don't copy it
stosb ;put the byte in the
; destination string
jmp CopyPrintableLoop ;the character was
; printable, so it couldn't
; possibly have been 0. No
; need to check whether it
; terminated the string
NotPrintable:
and al,al ;was that the
; terminating zero?
jnz CopyPrintableLoop ;no, do next byte
stosb ;copy the terminating zero
ret ;done
;
Skip:
call ZTimerOn
mov di,seg DestinationString
mov es,di
mov di,offset DestinationString
;ES:DI points to the destination
mov si,offset SourceString
;DS:SI points to the source
call CopyPrintable ;copy the printable
; characters
call ZTimerOff
```

## Listing 14-2

```nasm
;
; *** Listing 14-2 ***
;
; Copies a zero-terminated string to another string,
; filtering out non-printable characters by means of a
; subroutine that performs the test. The subroutine is
; invoked with a JMP and returns with another JMP.
;
jmp Skip
;
SourceString label byte
db 'This is a sample string, consisting of '
X=1
rept 31
db X
X=X+1
endm
db 7fh
db 'both printable and non-printable '
db 'characters', 0
DestinationString label byte
db 200 dup (?)
;
; Determines whether a character is printable (in the range
; 20h through 7Eh).
;
; Input:
; AL = character to check
;
; Output:
; Zero flag set to 1 if character is printable,
; set to 0 otherwise
;
; Registers altered: none
;
IsPrintable:
cmp al,20h
jb IsPrintableDone ;not printable
cmp al,7eh
ja IsPrintableDone ;not printable
cmp al,al ;set the Zero flag to 1, since the
; character is printable
IsPrintableDone:
jmp short IsPrintableReturn
;this hardwires IsPrintable to
; return to just one place
;
; Copies a zero-terminated string to another string,
; filtering out non-printable characters.
;
; Input:
; DS:SI = source string
; ES:DI = destination string
;
; Output: none
;
; Registers altered: AL, SI, DI
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CopyPrintable:
cld
CopyPrintableLoop:
lodsb ;get the next byte to copy
jmp IsPrintable ;is it printable?
IsPrintableReturn:
jnz NotPrintable ;nope, don't copy it
stosb ;put the byte in the
; destination string
jmp CopyPrintableLoop ;the character was
; printable, so it couldn't
; possibly have been 0. No
; need to check whether it
; terminated the string
NotPrintable:
and al,al ;was that the
; terminating zero?
jnz CopyPrintableLoop ;no, do next byte
stosb ;copy the terminating zero
ret ;done
;
Skip:
call ZTimerOn
mov di,seg DestinationString
mov es,di
mov di,offset DestinationString
;ES:DI points to the destination
mov si,offset SourceString
;DS:SI points to the source
call CopyPrintable ;copy the printable
; characters
call ZTimerOff
```

## Listing 14-3

```nasm
;
; *** Listing 14-3 ***
;
; Copies a zero-terminated string to another string,
; filtering out non-printable characters by means of a
; subroutine that performs the test. The subroutine is
; invoked with a JMP and returns with a JMP through a
; register.
;
jmp Skip
;
SourceString label byte
db 'This is a sample string, consisting of '
X=1
rept 31
db X
X=X+1
endm
db 7fh
db 'both printable and non-printable '
db 'characters', 0
DestinationString label byte
db 200 dup (?)
;
; Determines whether a character is printable (in the range
; 20h through 7Eh).
;
; Input:
; AL = character to check
; BP = return address
;
; Output:
; Zero flag set to 1 if character is printable,
; set to 0 otherwise
;
; Registers altered: none
;
IsPrintable:
cmp al,20h
jb IsPrintableDone ;not printable
cmp al,7eh
ja IsPrintableDone ;not printable
cmp al,al ;set the Zero flag to 1, since the
; character is printable
IsPrintableDone:
jmp bp ;return to the address in BP
;
; Copies a zero-terminated string to another string,
; filtering out non-printable characters.
;
; Input:
; DS:SI = source string
; ES:DI = destination string
;
; Output: none
;
; Registers altered: AL, SI, DI, BP
;
; Direction flag cleared
;
; Note: Does not handle strings that are longer than 64K
; bytes or cross segment boundaries.
;
CopyPrintable:
cld
mov bp,offset IsPrintableReturn
;set the return address for
; IsPrintable. Note that
; this is done outside the
; loop for speed
CopyPrintableLoop:
lodsb ;get the next byte to copy
jmp IsPrintable ;is it printable?
IsPrintableReturn:
jnz NotPrintable ;nope, don't copy it
stosb ;put the byte in the
; destination string
jmp CopyPrintableLoop ;the character was
; printable, so it couldn't
; possibly have been 0. No
; need to check whether it
; terminated the string
NotPrintable:
and al,al ;was that the
; terminating zero?
jnz CopyPrintableLoop ;no, do next byte
stosb ;copy the terminating zero
ret ;done
;
Skip:
call ZTimerOn
mov di,seg DestinationString
mov es,di
mov di,offset DestinationString
;ES:DI points to the destination
mov si,offset SourceString
;DS:SI points to the source
call CopyPrintable ;copy the printable
; characters
call ZTimerOff
```

## Listing 14-4

```nasm
;
; *** Listing 14-4 ***
;
; Copies the standard input to the standard output,
; converting all characters to uppercase. Does so
; one character at a time.
;
jmp Skip
; Storage for the character we're processing.
Character db ?
ErrorMsg db 'An error occurred', 0dh, 0ah
ERROR_MSG_LENGTH equ $-ErrorMsg
;
Skip:
call ZTimerOn
CopyLoop:
mov ah,3fh ;DOS read fn
sub bx,bx ;handle 0 is the standard input
mov cx,1 ;we want to get 1 character
mov dx,offset Character ;the character goes here
int 21h ;get the character
jc Error ;check for an error
and ax,ax ;did we read any characters?
jz Done ;no, we've hit the end of the file
mov al,[Character] ;get the character and
cmp al,'a' ; convert it to uppercase
jb WriteCharacter ; if it's lowercase
cmp al,'z'
ja WriteCharacter
and al,not 20h ;it's uppercase-convert to
mov [Character],al ; uppercase and save
WriteCharacter:
mov ah,40h ;DOS write fn
mov bx,1 ;handle 1 is the standard output
mov cx,1 ;we want to write 1 character
mov dx,offset Character ;the character to write
int 21h ;write the character
jnc CopyLoop ;if no error, do the next character
Error:
mov ah,40h ;DOS write fn
mov bx,2 ;handle 2 is standard error
mov cx,ERROR_MSG_LENGTH ;# of chars to display
mov dx,offset ErrorMsg ;error msg to display
int 21h ;notify of error
Done:
call ZTimerOff
```

## Listing 14-5

```nasm
;
; *** Listing 14-5 ***
;
; Copies the standard input to the standard output,
; converting all characters to uppercase. Does so in
; blocks of 256 characters.
;
jmp Skip
; Storage for the characters we're processing.
CHARACTER_BLOCK_SIZE equ 256
CharacterBlock db CHARACTER_BLOCK_SIZE dup (?)
ErrorMsg db 'An error occurred', 0dh, 0ah
ERROR_MSG_LENGTH equ $-ErrorMsg
;
Skip:
call ZTimerOn
CopyLoop:
mov ah,3fh ;DOS read fn
sub bx,bx ;handle 0 is the standard input
mov cx,CHARACTER_BLOCK_SIZE
;we want to get a block
mov dx,offset CharacterBlock
;the characters go here
int 21h ;get the characters
jc Error ;check for an error
mov cx,ax ;get the count where it does us the
; most good
jcxz Done ;if we didn't read anything, we've
; hit the end of the file
mov dx,cx ;remember how many characters we read
mov bx,offset CharacterBlock
;point to the first character to
; convert
ConvertLoop:
mov al,[bx] ;get the next character and
cmp al,'a' ; convert it to uppercase
jb ConvertLoopBottom ; if it's lowercase
cmp al,'z'
ja ConvertLoopBottom
and al,not 20h ;it's uppercase-convert to
mov [bx],al ; uppercase and save
ConvertLoopBottom:
inc bx ;point to the next character
loop ConvertLoop
mov cx,dx ;get back the character count in
; this block, to serve as a count of
; bytes for DOS to write
mov ah,40h ;DOS write fn
mov bx,1 ;handle 1 is the standard output
mov dx,offset CharacterBlock
;point to the characters to write
push cx ;remember # of characters read
int 21h ;write the character
pop ax ;get back the # of characters in
; this block
jc Error ;check for an error
cmp ax,CHARACTER_BLOCK_SIZE
;was it a partial block?
jz CopyLoop ;no, so we're not done yet
jmp short Done ;it was a partial block, so that
; was the end of the file
Error:
mov ah,40h ;DOS write fn
mov bx,2 ;handle 2 is standard error
mov cx,ERROR_MSG_LENGTH ;# of chars to display
mov dx,offset ErrorMsg ;error msg to display
int 21h ;notify of error
Done:
call ZTimerOff
```

## Listing 14-6

```nasm
;
; *** Listing 14-6 ***
;
; Searches for the first appearance of a character, in any
; case, in a byte-sized array by using JZ and LOOP.
;
jmp Skip
;
ByteArray label byte
db 'Array Containing Both Upper and Lowercase'
db ' Characters And Blanks'
ARRAY_LENGTH equ ($-ByteArray)
;
; Finds the first occurrence of the specified character, in
; any case, in the specified byte-sized array.
;
; Input:
; AL = character for which to perform a
; case-insensitive search
; CX = array length (0 means 64K long)
; DS:SI = array to search
;
; Output:
; SI = pointer to first case-insensitive match, or 0
; if no match is found
;
; Registers altered: AX, CX, SI
;
; Direction flag cleared
;
; Note: Does not handle arrays that are longer than 64K
; bytes or cross segment boundaries.
;
; Note: Do not pass an array that starts at offset 0 (SI=0),
; since a match on the first byte and failure to find
; the byte would be indistinguishable.
;
CaseInsensitiveSearch:
cld
cmp al,'a'
jb CaseInsensitiveSearchBegin
cmp al,'z'
ja CaseInsensitiveSearchBegin
and al,not 20h ;make sure the search byte
; is uppercase
CaseInsensitiveSearchBegin:
mov ah,al ;put the search byte in AH
; so we can use AL to hold
; the bytes we're checking
CaseInsensitiveSearchLoop:
lodsb ;get the next byte from the
; array being searched
cmp al,'a'
jb CaseInsensitiveSearchIsUpper
cmp al,'z'
ja CaseInsensitiveSearchIsUpper
and al,not 20h ;make sure the array byte is
; uppercase
CaseInsensitiveSearchIsUpper:
cmp al,ah ;do we have a
; case-insensitive match?
jz CaseInsensitiveSearchMatchFound ;yes
loop CaseInsensitiveSearchLoop
;check the next byte, if any
sub si,si ;no match found
ret
CaseInsensitiveSearchMatchFound:
dec si ;point back to the matching
; array byte
ret
;
Skip:
call ZTimerOn
mov al,'K' ;character to search for
mov si,offset ByteArray ;array to search
mov cx,ARRAY_LENGTH ;# of bytes to search
; through
call CaseInsensitiveSearch
;perform a case-insensitive
; search for 'K'
call ZTimerOff
```

## Listing 14-7

```nasm
;
; *** Listing 14-7 ***
;
; Searches for the first appearance of a character, in any
; case, in a byte-sized array by using LOOPNZ.
;
jmp Skip
;
ByteArray label byte
db 'Array Containing Both Upper and Lowercase'
db ' Characters And Blanks'
ARRAY_LENGTH equ ($-ByteArray)
;
; Finds the first occurrence of the specified character, in
; any case, in the specified byte-sized array.
;
; Input:
; AL = character for which to perform a
; case-insensitive search
; CX = array length (0 means 64K long)
; DS:SI = array to search
;
; Output:
; SI = pointer to first case-insensitive match, or 0
; if no match is found
;
; Registers altered: AX, CX, SI
;
; Direction flag cleared
;
; Note: Does not handle arrays that are longer than 64K
; bytes or cross segment boundaries.
;
; Note: Do not pass an array that starts at offset 0 (SI=0),
; since a match on the first byte and failure to find
; the byte would be indistinguishable.
;
CaseInsensitiveSearch:
cld
cmp al,'a'
jb CaseInsensitiveSearchBegin
cmp al,'z'
ja CaseInsensitiveSearchBegin
and al,not 20h ;make sure the search byte
; is uppercase
CaseInsensitiveSearchBegin:
mov ah,al ;put the search byte in AH
; so we can use AL to hold
; the bytes we're checking
CaseInsensitiveSearchLoop:
lodsb ;get the next byte from the
; array being searched
cmp al,'a'
jb CaseInsensitiveSearchIsUpper
cmp al,'z'
ja CaseInsensitiveSearchIsUpper
and al,not 20h ;make sure the array byte is
; uppercase
CaseInsensitiveSearchIsUpper:
cmp al,ah ;do we have a
; case-insensitive match?
loopnz CaseInsensitiveSearchLoop
;fall through if we have a
; match, or if we've run out
; of bytes. Otherwise, check
; the next byte
jz CaseInsensitiveSearchMatchFound
;we did find a match
sub si,si ;no match found
ret
CaseInsensitiveSearchMatchFound:
dec si ;point back to the matching
; array byte
ret
;
Skip:
call ZTimerOn
mov al,'K' ;character to search for
mov si,offset ByteArray ;array to search
mov cx,ARRAY_LENGTH ;# of bytes to search
; through
call CaseInsensitiveSearch
;perform a case-insensitive
; search for 'K'
call ZTimerOff
```

## Listing 14-8

```nasm
;
; *** Listing 14-8 ***
;
; Searches for the first appearance of a character, in any
; case, in a byte-sized array by using JZ, DEC REG16, and
; JNZ.
;
jmp Skip
;
ByteArray label byte
db 'Array Containing Both Upper and Lowercase'
db ' Characters And Blanks'
ARRAY_LENGTH equ ($-ByteArray)
;
; Finds the first occurrence of the specified character, in
; any case, in the specified byte-sized array.
;
; Input:
; AL = character for which to perform a
; case-insensitive search
; CX = array length (0 means 64K long)
; DS:SI = array to search
;
; Output:
; SI = pointer to first case-insensitive match, or 0
; if no match is found
;
; Registers altered: AX, CX, SI
;
; Direction flag cleared
;
; Note: Does not handle arrays that are longer than 64K
; bytes or cross segment boundaries.
;
; Note: Do not pass an array that starts at offset 0 (SI=0),
; since a match on the first byte and failure to find
; the byte would be indistinguishable.
;
CaseInsensitiveSearch:
cld
cmp al,'a'
jb CaseInsensitiveSearchBegin
cmp al,'z'
ja CaseInsensitiveSearchBegin
and al,not 20h ;make sure the search byte
; is uppercase
CaseInsensitiveSearchBegin:
mov ah,al ;put the search byte in AH
; so we can use AL to hold
; the bytes we're checking
CaseInsensitiveSearchLoop:
lodsb ;get the next byte from the
; array being searched
cmp al,'a'
jb CaseInsensitiveSearchIsUpper
cmp al,'z'
ja CaseInsensitiveSearchIsUpper
and al,not 20h ;make sure the array byte is
; uppercase
CaseInsensitiveSearchIsUpper:
cmp al,ah ;do we have a
; case-insensitive match?
jz CaseInsensitiveSearchMatchFound ;yes
dec cx ;count down bytes remaining
; in array being searched
jnz CaseInsensitiveSearchLoop
;check the next byte, if any
sub si,si ;no match found
ret
CaseInsensitiveSearchMatchFound:
dec si ;point back to the matching
; array byte
ret
;
Skip:
call ZTimerOn
mov al,'K' ;character to search for
mov si,offset ByteArray ;array to search
mov cx,ARRAY_LENGTH ;# of bytes to search
; through
call CaseInsensitiveSearch
;perform a case-insensitive
; search for 'K'
call ZTimerOff
```

## Listing 14-9

```nasm
;
; *** Listing 14-9 ***
;
; Searches for the first appearance of a character, in any
; case, in a byte-sized array by using JZ, DEC REG8, and
; JNZ.
;
jmp Skip
;
ByteArray label byte
db 'Array Containing Both Upper and Lowercase'
db ' Characters And Blanks'
ARRAY_LENGTH equ ($-ByteArray)
;
; Finds the first occurrence of the specified character, in
; any case, in the specified byte-sized array.
;
; Input:
; AL = character for which to perform a
; case-insensitive search
; CL = array length (0 means 256 long)
; DS:SI = array to search
;
; Output:
; SI = pointer to first case-insensitive match, or 0
; if no match is found
;
; Registers altered: AX, CL, SI
;
; Direction flag cleared
;
; Note: Does not handle arrays that are longer than 256
; bytes or cross segment boundaries.
;
; Note: Do not pass an array that starts at offset 0 (SI=0),
; since a match on the first byte and failure to find
; the byte would be indistinguishable.
;
CaseInsensitiveSearch:
cld
cmp al,'a'
jb CaseInsensitiveSearchBegin
cmp al,'z'
ja CaseInsensitiveSearchBegin
and al,not 20h ;make sure the search byte
; is uppercase
CaseInsensitiveSearchBegin:
mov ah,al ;put the search byte in AH
; so we can use AL to hold
; the bytes we're checking
CaseInsensitiveSearchLoop:
lodsb ;get the next byte from the
; array being searched
cmp al,'a'
jb CaseInsensitiveSearchIsUpper
cmp al,'z'
ja CaseInsensitiveSearchIsUpper
and al,not 20h ;make sure the array byte is
; uppercase
CaseInsensitiveSearchIsUpper:
cmp al,ah ;do we have a
; case-insensitive match?
jz CaseInsensitiveSearchMatchFound ;yes
dec cl ;count down bytes remaining
; in array being searched
jnz CaseInsensitiveSearchLoop
;check the next byte, if any
sub si,si ;no match found
ret
CaseInsensitiveSearchMatchFound:
dec si ;point back to the matching
; array byte
ret
;
Skip:
call ZTimerOn
mov al,'K' ;character to search for
mov si,offset ByteArray ;array to search
mov cx,ARRAY_LENGTH ;# of bytes to search
; through
call CaseInsensitiveSearch
;perform a case-insensitive
; search for 'K'
call ZTimerOff
```

## Listing 14-10

```nasm
;
; *** Listing 14-10 ***
;
; Searches for the first appearance of a character, in any
; case, in a byte-sized array by using JZ, DEC MEM8, and
; JNZ.
;
jmp Skip
;
ByteArray label byte
db 'Array Containing Both Upper and Lowercase'
db ' Characters And Blanks'
ARRAY_LENGTH equ ($-ByteArray)
BCount db ? ;used to count down the # of bytes
; remaining in the array being
; searched (counter is byte-sized)
;
; Finds the first occurrence of the specified character, in
; any case, in the specified byte-sized array.
;
; Input:
; AL = character for which to perform a
; case-insensitive search
; CL = array length (0 means 256 long)
; DS:SI = array to search
;
; Output:
; SI = pointer to first case-insensitive match, or 0
; if no match is found
;
; Registers altered: AX, SI
;
; Direction flag cleared
;
; Note: Does not handle arrays that are longer than 256
; bytes or cross segment boundaries.
;
; Note: Do not pass an array that starts at offset 0 (SI=0),
; since a match on the first byte and failure to find
; the byte would be indistinguishable.
;
CaseInsensitiveSearch:
cld
mov [BCount],cl ;set the count variable
cmp al,'a'
jb CaseInsensitiveSearchBegin
cmp al,'z'
ja CaseInsensitiveSearchBegin
and al,not 20h ;make sure the search byte
; is uppercase
CaseInsensitiveSearchBegin:
mov ah,al ;put the search byte in AH
; so we can use AL to hold
; the bytes we're checking
CaseInsensitiveSearchLoop:
lodsb ;get the next byte from the
; array being searched
cmp al,'a'
jb CaseInsensitiveSearchIsUpper
cmp al,'z'
ja CaseInsensitiveSearchIsUpper
and al,not 20h ;make sure the array byte is
; uppercase
CaseInsensitiveSearchIsUpper:
cmp al,ah ;do we have a
; case-insensitive match?
jz CaseInsensitiveSearchMatchFound ;yes
dec [BCount] ;count down bytes remaining
; in array being searched
; (counter is byte-sized)
jnz CaseInsensitiveSearchLoop
;check the next byte, if any
sub si,si ;no match found
ret
CaseInsensitiveSearchMatchFound:
dec si ;point back to the matching
; array byte
ret
;
Skip:
call ZTimerOn
mov al,'K' ;character to search for
mov si,offset ByteArray ;array to search
mov cx,ARRAY_LENGTH ;# of bytes to search
; through
call CaseInsensitiveSearch
;perform a case-insensitive
; search for 'K'
call ZTimerOff
```

## Listing 14-11

```nasm
;
; *** Listing 14-11 ***
;
; Searches for the first appearance of a character, in any
; case, in a byte-sized array by using JZ, DEC MEM16, and
; JNZ.
;
jmp Skip
;
ByteArray label byte
db 'Array Containing Both Upper and Lowercase'
db ' Characters And Blanks'
ARRAY_LENGTH equ ($-ByteArray)
WCount dw ? ;used to count down the # of bytes
; remaining in the array being
; searched (counter is word-sized)
;
; Finds the first occurrence of the specified character, in
; any case, in the specified byte-sized array.
;
; Input:
; AL = character for which to perform a
; case-insensitive search
; CX = array length (0 means 64K long)
; DS:SI = array to search
;
; Output:
; SI = pointer to first case-insensitive match, or 0
; if no match is found
;
; Registers altered: AX, SI
;
; Direction flag cleared
;
; Note: Does not handle arrays that are longer than 64K
; bytes or cross segment boundaries.
;
; Note: Do not pass an array that starts at offset 0 (SI=0),
; since a match on the first byte and failure to find
; the byte would be indistinguishable.
;
CaseInsensitiveSearch:
cld
mov [WCount],cx ;set the count variable
cmp al,'a'
jb CaseInsensitiveSearchBegin
cmp al,'z'
ja CaseInsensitiveSearchBegin
and al,not 20h ;make sure the search byte
; is uppercase
CaseInsensitiveSearchBegin:
mov ah,al ;put the search byte in AH
; so we can use AL to hold
; the bytes we're checking
CaseInsensitiveSearchLoop:
lodsb ;get the next byte from the
; array being searched
cmp al,'a'
jb CaseInsensitiveSearchIsUpper
cmp al,'z'
ja CaseInsensitiveSearchIsUpper
and al,not 20h ;make sure the array byte is
; uppercase
CaseInsensitiveSearchIsUpper:
cmp al,ah ;do we have a
; case-insensitive match?
jz CaseInsensitiveSearchMatchFound ;yes
dec [WCount] ;count down bytes remaining
; in array being searched
; (counter is word-sized)
jnz CaseInsensitiveSearchLoop
;check the next byte, if any
sub si,si ;no match found
ret
CaseInsensitiveSearchMatchFound:
dec si ;point back to the matching
; array byte
ret
;
Skip:
call ZTimerOn
mov al,'K' ;character to search for
mov si,offset ByteArray ;array to search
mov cx,ARRAY_LENGTH ;# of bytes to search
; through
call CaseInsensitiveSearch
;perform a case-insensitive
; search for 'K'
call ZTimerOff
```

## Listing 14-12

```nasm
;
; *** Listing 14-12 ***
;
; Demonstrates scanning a table with REPNZ SCASW in
; order to generate an index to be used with a jump table.
;
jmp Skip
;
; Branches to the routine corresponding to the key code in
; AX. Simply returns if no match is found.
;
; Input:
; AX = 16-bit key code, as returned by the BIOS
;
; Output: none
;
; Registers altered: CX, DI, ES
;
; Direction flag cleared
;
; Table of 16-bit key codes this routine handles.
;
KeyLookUpTable label word
dw 1e41h, 3042h, 2e43h, 2044h ;A-D
dw 1245h, 2146h, 2247h, 2347h ;E-H
dw 1749h, 244ah, 254bh, 264ch ;I-L
dw 324dh, 314eh, 184fh, 1950h ;M-P
dw 1051h, 1352h, 1f53h, 1454h ;Q-T
dw 1655h, 2f56h, 1157h, 2d58h ;U-X
dw 1559h, 2c5ah ;Y-Z
KEY_LOOK_UP_TABLE_LENGTH_IN_WORDS equ (($-KeyLookUpTable)/2)
;
; Table of addresses to which to jump when the corresponding
; key codes in KeyLookUpTable are found. All the entries
; point to the same routine, since this is for illustrative
; purposes only, but they could easily be changed to point
; to any labeLin the code segment.
;
KeyJumpTable label word
dw HandleA_Z, HandleA_Z, HandleA_Z, HandleA_Z
dw HandleA_Z, HandleA_Z, HandleA_Z, HandleA_Z
dw HandleA_Z, HandleA_Z, HandleA_Z, HandleA_Z
dw HandleA_Z, HandleA_Z, HandleA_Z, HandleA_Z
dw HandleA_Z, HandleA_Z, HandleA_Z, HandleA_Z
dw HandleA_Z, HandleA_Z, HandleA_Z, HandleA_Z
dw HandleA_Z, HandleA_Z
;
VectorOnKey proc near
mov di,cs
mov es,di
mov di,offset KeyLookUpTable
;point ES:DI to the table of keys
; we handle, which is in the same
; code segment as this routine
mov cx,KEY_LOOK_UP_TABLE_LENGTH_IN_WORDS
;# of words to scan
cld
repnz scasw ;look up the key
jnz VectorOnKeyDone ;it's not in the table, so
; we're done
jmp cs:[KeyJumpTable+di-2-offset KeyLookUpTable]
;jump to the routine for this key
; Note that:
; DI-2-offset KeyLookUpTable
; is the offset in KeyLookUpTable of
; the key we found, with the -2
; needed to compensate for the
; 2-byte (1-word) overrun of SCASW
HandleA_Z:
VectorOnKeyDone:
ret
VectorOnKey endp
;
Skip:
call ZTimerOn
mov ax,1e41h
call VectorOnKey ;look up 'A'
mov ax,1749h
call VectorOnKey ;look up 'I'
mov ax,1f53h
call VectorOnKey ;look up 'S'
mov ax,2c5ah
call VectorOnKey ;look up 'Z'
mov ax,0
call VectorOnKey ;finally, look up a key
; code that's not in the
; table
call ZTimerOff
```

## Listing 14-13

```nasm
;
; *** Listing 14-13 ***
;
; Demonstrates that it's much slower to scan a table
; in a loop than to use REP SCASW; look-up tables should
; be designed so that repeated string instructions can be
; used.
;
jmp Skip
;
; Branches to the routine corresponding to the key code in
; AX. Simply returns if no match is found.
;
; Input:
; AX = 16-bit key code, as returned by the BIOS
;
; Output: none
;
; Registers altered: CX, DI, ES
;
; Direction flag cleared
;
; Table of 16-bit key codes this routine handles, each
; paired with the address to jump to if that key code is
; found.
;
KeyLookUpTable label word
dw 1e41h, HandleA_Z, 3042h, HandleA_Z ;A-B
dw 2e43h, HandleA_Z, 2044h, HandleA_Z ;C-D
dw 1245h, HandleA_Z, 2146h, HandleA_Z ;E-F
dw 2247h, HandleA_Z, 2347h, HandleA_Z ;G-H
dw 1749h, HandleA_Z, 244ah, HandleA_Z ;I-J
dw 254bh, HandleA_Z, 264ch, HandleA_Z ;K-L
dw 324dh, HandleA_Z, 314eh, HandleA_Z ;M-N
dw 184fh, HandleA_Z, 1950h, HandleA_Z ;O-P
dw 1051h, HandleA_Z, 1352h, HandleA_Z ;Q-R
dw 1f53h, HandleA_Z, 1454h, HandleA_Z ;S-T
dw 1655h, HandleA_Z, 2f56h, HandleA_Z ;U-V
dw 1157h, HandleA_Z, 2d58h, HandleA_Z ;W-X
dw 1559h, HandleA_Z, 2c5ah, HandleA_Z ;Y-Z
KEY_LOOK_UP_TABLE_LEN_IN_ENTRIES equ (($-KeyLookUpTable)/4)
;
VectorOnKey proc near
mov di,cs
mov es,di
mov di,offset KeyLookUpTable
;point ES:DI to the table of keys
; we handle, which is in the same
; code segment as this routine
mov cx,KEY_LOOK_UP_TABLE_LEN_IN_ENTRIES
;# of entries to scan
cld
VectorOnKeyLoop:
scasw
jz VectorOnKeyJump ;we've found the key code
inc di ;point to the next entry
inc di
loop VectorOnKeyLoop
ret ;the key code is not in the
; table, so we're done
VectorOnKeyJump:
jmp word ptr cs:[di]
;jump to the routine for this key
HandleA_Z:
ret
VectorOnKey endp
;
Skip:
call ZTimerOn
mov ax,1e41h
call VectorOnKey ;look up 'A'
mov ax,1749h
call VectorOnKey ;look up 'I'
mov ax,1f53h
call VectorOnKey ;look up 'S'
mov ax,2c5ah
call VectorOnKey ;look up 'Z'
mov ax,0
call VectorOnKey ;finally, look up a key
; code that's not in the
; table
call ZTimerOff
```

## Listing 14-14

```nasm
;
; *** Listing 14-14 ***
;
; Demonstrates the use of a jump table to branch into
; in-line code consisting of repeated code blocks of
; varying lengths. The approach of using a jump table to
; branch into in-line code is speedy enough that
; it's often preferable even when all the repeated code
; blocks are the same size, although the jump table does
; take extra space.
;
; Searches up to N bytes of a zero-terminated string for
; a character.
;
jmp Skip
TestString label byte
db 'This is a string containing the letter '
db 'z but not containing capital q', 0
;
; Searches a zero-terminated string for a character.
; Searches until a match is found, the terminating zero
; is found, or the specified number of characters have been
; checked.
;
; Input:
; AL = character to search for
; BX = maximum # of characters to search. Must be
; less than or equal to 80
; DS:SI = string to search
;
; Output:
; SI = pointer to character, or 0 if character not
; found
;
; Registers altered: AX, BX, SI
;
; Direction flag cleared
;
; Note: Don't pass a string starting at offset 0, since a
; match there couldn't be distinguished from a failure
; to match.
;
MAX_SEARCH_LENGTH equ 80 ;longest supported search
; length
;
; Macro to create SearchTable entries.
;
MAKE_CHECK_CHAR_LABEL macro NUMBER
dw CheckChar&NUMBER&
endm
;
; Macro to create in-line code to search 1 character.
; Gives the code block a unique label according to NUMBER.
; Each conditional branch uses the shortest possible jump
; sequence to reach NoMatch and MatchFound.
;
CHECK_CHAR macro NUMBER
local CheckMatch, Continue
CheckChar&NUMBER&:
lodsb ;get the character
and al,al ;done if terminating zero
;
; Assemble a single conditional jump if it'll reach, or
; a conditional jump around an unconditional jump if the
; 1-byte displacement of a conditional jump won't reach.
;
if ($+2-NoMatch) le 128
jz NoMatch
else
jnz CheckMatch
jmp NoMatch
endif
CheckMatch:
cmp ah,al ;done if matches search character
;
; Again, assemble shortest possible jump sequence.
;
if ($+2-MatchFound) le 128
jz MatchFound
else
jnz Continue
jmp MatchFound
endif
Continue:
endm
;
; Table of in-line code entry points for maximum search
; lengths of 0 through 80.
;
SearchTable label word
dw NoMatch ;we never match on a
; maximum length of 0
BLOCK_NUMBER=MAX_SEARCH_LENGTH-1
rept MAX_SEARCH_LENGTH
MAKE_CHECK_CHAR_LABEL %BLOCK_NUMBER
BLOCK_NUMBER=BLOCK_NUMBER-1
endm
;
SearchNBytes proc near
mov ah,al ;we'll need AL for LODSB
cmp bx,MAX_SEARCH_LENGTH
ja NoMatch ;if the maximum length's
; too long for the in-line
; code, return a no-match
; status
shl bx,1 ;*2 to look up in word-sized
; table
jmp [SearchTable+bx] ;branch into the in-line
; code to do the search
;
; No match was found.
;
NoMatch:
sub si,si ;return no-match status
ret
;
; A match was found.
;
MatchFound:
dec si ;point back to matching
; location
ret
;
; This is the in-line code that actually does the search.
; Each repetition is uniquely labelled, with the labels
; running from CheckChar0 through CheckChar79.
;
BLOCK_NUMBER=0
;
; These in-line blocks use 1-byte displacements whenever
; possible to branch backward; otherwise 2-byte
; displacements are used to branch backward, with
; conditional jumps around unconditional jumps.
;
rept MAX_SEARCH_LENGTH
CHECK_CHAR %BLOCK_NUMBER
BLOCK_NUMBER=BLOCK_NUMBER+1
endm
;
; If we make it here, we haven't found the character.
;
sub si,si ;return no-match status
ret
SearchNBytes endp
;
Skip:
call ZTimerOn
mov al,'Q'
mov bx,20 ;search up to the
mov si,offset TestString ; first 20 bytes of
call SearchNBytes ; TestString for 'Q'
mov al,'z'
mov bx,80 ;search up to the
mov si,offset TestString ; first 80 bytes of
call SearchNBytes ; TestString for 'z'
mov al,'a'
mov bx,10 ;search up to the
mov si,offset TestString ; first 10 bytes of
call SearchNBytes ; TestString for 'a'
call ZTimerOff
```

## Listing 14-15

```nasm
;
; *** Listing 14-15 ***
;
; For comparison with the in-line-code-branched-to-via-a-
; jump-table approach of Listing 14-14, this is a loop-based
; string-search routine that searches at most the specified
; number of bytes of a zero-terminated string for the
; specified character.
;
jmp Skip
TestString label byte
db 'This is a string containing the letter '
db 'z but not containing capital q', 0
;
; Searches a zero-terminated string for a character.
; Searches until a match is found, the terminating zero
; is found, or the specified number of characters have been
; checked.
;
; Input:
; AL = character to search for
; BX = maximum # of characters to search
; DS:SI = string to search
;
; Output:
; SI = pointer to character, or 0 if character not
; found
;
; Registers altered: AX, CX, SI
;
; Direction flag cleared
;
; Note: Don't pass a string starting at offset 0, since a
; match there couldn't be distinguished from a failure
; to match.
;
SearchNBytes proc near
mov ah,al ;we'll need AL for LODSB
mov cx,bx ;for LOOP
SearchNBytesLoop:
lodsb
and al,al
jz NoMatch ;terminating 0, so no match
cmp ah,al
jz MatchFound ;match, so we're done
loop SearchNBytesLoop
;
; No match was found.
;
NoMatch:
sub si,si ;return no-match status
ret
;
; A match was found.
;
MatchFound:
dec si ;point back to matching
; location
ret
SearchNBytes endp
;
Skip:
call ZTimerOn
mov al,'Q'
mov bx,20 ;search up to the
mov si,offset TestString ; first 20 bytes of
call SearchNBytes ; TestString for 'Q'
mov al,'z'
mov bx,80 ;search up to the
mov si,offset TestString ; first 80 bytes of
call SearchNBytes ; TestString for 'z'
mov al,'a'
mov bx,10 ;search up to the
mov si,offset TestString ; first 10 bytes of
call SearchNBytes ; TestString for 'a'
call ZTimerOff
```

## Listing 14-16

```nasm
;
; *** Listing 14-16 ***
;
; Demonstrates the use of a jump table to branch into
; in-line code consisting of repeated code blocks of
; varying lengths. Branches out of the in-line code with
; 1-byte displacements at both ends of the in-line code,
; for improved speed.
;
; Searches up to N bytes of a zero-terminated string for
; a character.
;
jmp Skip
TestString label byte
db 'This is a string containing the letter '
db 'z but not containing capital q', 0
;
; Searches a zero-terminated string for a character.
; Searches until a match is found, the terminating zero
; is found, or the specified number of characters has been
; checked.
;
; Input:
; AL = character to search for
; BX = maximum # of characters to search. Must be
; less than or equal to MAX_SEARCH_LENGTH
; DS:SI = string to search
;
; Output:
; SI = pointer to character, or 0 if character not
; found
;
; Registers altered: AX, BX, SI
;
; Direction flag cleared
;
; Note: Don't pass a string starting at offset 0, since a
; match there couldn't be distinguished from a failure
; to match.
;
MAX_SEARCH_LENGTH equ 80 ;longest supported search
; length
;
; Macro to create SearchTable entries.
;
MAKE_CHECK_CHAR_LABEL macro NUMBER
dw CheckChar&NUMBER&
endm
;
; Macro to create in-line code to search 1 character.
; Gives the code block a unique label according to NUMBER.
; Each conditional branch uses the shortest possible jump
; sequence to reach NoMatch and MatchFound.
;
CHECK_CHAR macro NUMBER
local CheckMatch, Continue
CheckChar&NUMBER&:
lodsb ;get the character
and al,al ;done if terminating zero
;
; Assemble a single conditional jump if it'll reach, or
; a conditional jump around an unconditional jump if the
; 1-byte displacement of a conditional jump won't reach.
;
if ($+2-NoMatch) le 128
jz NoMatch
else
jnz CheckMatch
jmp NoMatch
endif
CheckMatch:
cmp ah,al ;done if matches search character
;
; Again, assemble shortest possible jump sequence.
;
if ($+2-MatchFound) le 128
jz MatchFound
else
jnz Continue
jmp MatchFound
endif
Continue:
endm
;
; Macro to create in-line code to search 1 character.
; Gives the code block a unique label according to NUMBER.
; All branches use a 1-byte displacement to branch to
; NoMatch2 and MatchFound2.
;
CHECK_CHAR2 macro NUMBER
CheckChar&NUMBER&:
lodsb ;get the character
and al,al ;done if terminating zero
jz NoMatch2
cmp ah,al ;done if matches search character
jz MatchFound2
endm
;
; Table of in-line code entry points for maximum search
; lengths of 0 through 80.
;
SearchTable label word
dw NoMatch ;we never match on a
; maximum length of 0
BLOCK_NUMBER=MAX_SEARCH_LENGTH-1
rept MAX_SEARCH_LENGTH
MAKE_CHECK_CHAR_LABEL %BLOCK_NUMBER
BLOCK_NUMBER=BLOCK_NUMBER-1
endm
;
SearchNBytes proc near
mov ah,al ;we'll need AL for LODSB
cmp bx,MAX_SEARCH_LENGTH
ja NoMatch ;if the maximum length's
; too long for the in-line
; code, return a no-match
; status
shl bx,1 ;*2 to look up in word-sized
; table
jmp [SearchTable+bx] ;branch into the in-line
; code to do the search
;
; No match was found.
;
NoMatch:
sub si,si ;return no-match status
ret
;
; A match was found.
;
MatchFound:
dec si ;point back to matching
; location
ret
;
; This is the in-line code that actually does the search.
; Each repetition is uniquely labelled, with labels
; CheckChar0 through CheckChar79.
;
BLOCK_NUMBER=0
;
; These in-line code blocks use 1-byte displacements
; whenever possible to branch backward; otherwise 2-byte
; displacements are used to branch backwards, with
; conditional jumps around unconditional jumps.
;
rept MAX_SEARCH_LENGTH-14
CHECK_CHAR %BLOCK_NUMBER
BLOCK_NUMBER=BLOCK_NUMBER+1
endm
;
; These in-line code blocks use 1-byte displacements to
; branch forward.
;
rept 14
CHECK_CHAR2 %BLOCK_NUMBER
BLOCK_NUMBER=BLOCK_NUMBER+1
endm
;
; If we make it here, we haven't found the character.
;
NoMatch2:
sub si,si ;return no-match status
ret
;
; A match was found.
;
MatchFound2:
dec si ;point back to matching
; location
ret
SearchNBytes endp
;
Skip:
call ZTimerOn
mov al,'Q'
mov bx,20 ;search up to the
mov si,offset TestString ; first 20 bytes of
call SearchNBytes ; TestString for 'Q'
mov al,'z'
mov bx,80 ;search up to the
mov si,offset TestString ; first 80 bytes of
call SearchNBytes ; TestString for 'z'
mov al,'a'
mov bx,10 ;search up to the
mov si,offset TestString ; first 10 bytes of
call SearchNBytes ; TestString for 'a'
call ZTimerOff
```

## Listing 15-1

```nasm
;
; *** Listing 15-1 ***
;
jmp Skip
;
even ;always make sure word-sized memory
; variables are word-aLigned!
WordVar dw 0
;
Skip:
call ZTimerOn
rept 1000
mov [WordVar],1
endm
call ZTimerOff
```

## Listing 15-2

```nasm
;
; *** Listing 15-2 ***
;
; Measures the performance of accesses to word-sized
; variables that start at odd addresses (are not
; Word-aLigned).
;
Skip:
push ds
pop es
mov si,1 ;source and destination are the same
mov di,si ; and both are not word-aLigned
mov cx,1000 ;move 1000 words
cld
call ZTimerOn
rep movsw
call ZTimerOff
```

## Listing 15-3

```nasm
;
; *** Listing 15-3 ***
;
; Measures the performance of accesses to word-sized
; variables that start at even addresses (are word-aLigned).
;
Skip
push ds
pop es
mov si,si ;source and destination are the same
mov di,si ; and both are word-aLigned
mov cx,1000 ;move 1000 words
cld
call ZTimerOn
rep movsw
call ZTimerOff
```

## Listing 15-4

```nasm
;
; *** Listing 15-4 ***
;
; Measures the performance of adding an immediate value
; to a register, for comparison with Listing 15-5, which
; adds an immediate value to a memory variable.
;
call ZTimerOn
rept 1000
add dx,100h
endm
call ZTimerOff
```

## Listing 15-5

```nasm
;
; *** Listing 15-5 ***
;
; Measures the performance of adding an immediate value
; to a memory variable, for comparison with listing 15-4,
; which adds an immediate value to a register.
;
jmp Skip
;
even ;always make sure word-sized memory
; Variables are word-aLigned!
WordVar dw 0
;
Skip:
call ZTimerOn
rept 1000
add [WordVar],100h
endm
call ZTimerOff
```

## LZTEST

```nasm
; LZTEST
;
; *** Listing 2-6 ***
;
; Program to measure performance of code that takes longer than
; 54 ms to execute. (LZTEST.ASM)
;
; Link with LZTIMER.ASM (Listing 2-5). LZTEST.BAT (Listing 2-7)
; can be used to assemble and link both files. Code to be
; measured must be in the file TESTCODE; Listing 2-8 shows
; a sample TESTCODE file.
;
; By Michael Abrash 4/26/89
;
mystack segment para stack 'STACK'
db 512 dup(?)
mystack ends
;
Code segment para public 'CODE'
assume cs:Code, ds:Code
extrn ZTimerOn:near, ZTimerOff:near, ZTimerReport:near
Start proc near
push cs
pop ds ;point DS to the code segment,
; so data as well as code can easily
; be included in TESTCODE
;
; Delay for 6-7 seconds, to let the Enter keystroke that started the
; program come back up.
;
mov ah,2ch
int 21h ;get the current time
mov bh,dh ;set the current time aside
DelayLoop:
mov ah,2ch
push bx ;preserve start time
int 21h ;get time
pop bx ;retrieve start time
cmp dh,bh ;is the new seconds count less than
; the start seconds count?
jnb CheckDelayTime ;no
add dh,60 ;yes, a minute must have turned over,
; so add one minute
CheckDelayTime:
sub dh,bh ;get time that's passed
cmp dh,7 ;has it been more than 6 seconds yet?
jb DelayLoop ;not yet
;
include TESTCODE ;code to be measured, including calls
; to ZTimerOn and ZTimerOff
;
; Display the results.
;
call ZTimerReport
;
; Terminate the program.
;
mov ah,4ch
int 21h
Start endp
Code ends
end Start
```

## LZTIME.BAT

```bat
LZTIME.BAT
echo off
rem
rem *** Listing 2-7 ***
rem
rem
***************************************************************
rem * Batch file LZTIME.BAT, which builds and runs the *
rem * long-period Zen timer program LZTEST.EXE to time the code *
rem * named as the command-line parameter. Listing 2-5 must be *
rem * named LZTIMER.ASM, and Listing 2-6 must be named *
rem * LZTEST.ASM. To time the code in LST2-8, you'd type the *
rem * DOS command: *
rem * *
rem * lztime lst2-8 *
rem * *
rem * Note that MASM and LINK must be in the current directory or
*
rem * on the current path in order for this batch file to work. *
rem * *
rem * This batch file can be speeded up by assembling LZTIMER.ASM
*
rem * once, then removing the lines: *
rem * *
rem * masm lztimer; *
rem * if errorlevel 1 goto errorend *
rem * *
rem * from this file. *
rem * *
rem * By Michael Abrash 4/26/89 *
rem
***************************************************************
rem
rem Make sure a file to test was specified.
rem
if not x%1==x goto ckexist
echo
***************************************************************
echo * Please specify a file to test. *
echo
***************************************************************
goto end
rem
rem Make sure the file exists.
rem
:ckexist
if exist %1 goto docopy
echo
***************************************************************
echo * The specified file, "%1," doesn't exist.
echo
***************************************************************
goto end
rem
rem copy the file to measure to TESTCODE.
:docopy
copy %1 testcode
masm lztest;
if errorlevel 1 goto errorend
masm lztimer;
if errorlevel 1 goto errorend
link lztest+lztimer;
if errorlevel 1 goto errorend
lztest
goto end
:errorend
echo
***************************************************************
echo * An error occurred while building the long-period Zen timer.
*
echo
***************************************************************
:end
```

## LZTIME

```nasm
;
; *** Listing 2-5 ***
;
; The long-period Zen timer. (LZTIMER.ASM)
; Uses the 8253 timer and the BIOS time-of-day count to time the
; performance of code that takes less than an hour to execute.
; Because interrupts are left on (in order to allow the timer
; interrupt to be recognized), this is less accurate than the
; precision Zen timer, so it is best used only to time code that takes
; more than about 54 milliseconds to execute (code that the precision
; Zen timer reports overflow on). Resolution is limited by the
; occurrence of timer interrupts.
;
; By Michael Abrash 4/26/89
;
; Externally callable routines:
;
;   ZTimerOn: Saves the BIOS time of day count and starts the
;       long-period Zen timer.
;
;   ZTimerOff: Stops the long-period Zen timer and saves the timer
;       count and the BIOS time-of-day count.
;
;   ZTimerReport: Prints the time that passed between starting and
;       stopping the timer.
;
; Note: If either more than an hour passes or midnight falls between
;       calls to ZTimerOn and ZTimerOff, an error is reported. For
;       timing code that takes more than a few minutes to execute,
;       either the DOS TIME command in a batch file before and after
;       execution of the code to time or the use of the DOS
;       time-of-day function in place of the long-period Zen timer is
;       more than adequate.
;
; Note: The PS/2 version is assembled by setting the symbol PS2 to 1.
;       PS2 must be set to 1 on PS/2 computers because the PS/2's
;       timers are not compatible with an undocumented timer-stopping
;       feature of the 8253; the alternative timing approach that
;       must be used on PS/2 computers leaves a short window
;       during which the timer 0 count and the BIOS timer count may
;       not be synchronized. You should also set the PS2 symbol to
;       1 if you're getting erratic or obviously incorrect results.
;       When the PS/2 version is used, each block of code being timed
;       should be run several times, with at least two similar
;       readings required to establish a true measurement.
;
; Note: When PS2 is 0, the code relies on an undocumented 8253
;       feature. It is possible that the 8253 (or whatever chip
;       is emulating the 8253) may be put into an undefined or
;       incorrect state when this feature is used. If your computer
;       displays any hint of erratic behavior after the long-period
;       Zen timer is used, such as the floppy drive failing to
;       operate properly, reboot the system, set PS2 to 1 and
;       leave it that way.
;
; Note: Interrupts must not be disabled for more than 54 ms at a
;       stretch during the timing interval. Because interrupts
;       are enabled, keys, mice, and other devices that generate
;       interrupts should not be used during the timing interval.
;
; Note: Any extra code running off the timer interrupt (such as
;       some memory-resident utilities) wilLincrease the time
;       measured by the Zen timer.
;
; Note: These routines can introduce inaccuracies of up to a few
;       tenths of a second into the system clock count for each
;       code section timed. Consequently, it's a good idea to
;       reboot at the conclusion of timing sessions. (The
;       battery-backed clock, if any, is not affected by the Zen
;       timer.)
;
; All registers and all flags are preserved by all routines.
;
 
Code    segment     word public 'CODE'
        assume      cs:Code, ds:nothing
        public ZTimerOn, ZTimerOff, ZTimerReport
 
;
; Set to 0 to assemble for use on a fully 8253-compatible
; system. Set to 1 to assemble for use on non-8253-compatible
; systems, including PS/2 computers. In general, leave this
; set to 0 on non-PS/2 computers unless you get inconsistent
; or inaccurate readings.
;
PS2             equ     0
;
; Base address of the 8253 timer chip.
;
BASE_8253       equ     40h
;
; The address of the timer 0 count registers in the 8253.
;
TIMER_0_8253    equ     BASE_8253 + 0
;
; The address of the mode register in the 8253.
;
MODE_8253       equ     BASE_8253 + 3
;
; The address of the BIOS timer count variable in the BIOS
; data segment.
;
TIMER_COUNT     equ     46ch
;
; Macro to emulate a POPF instruction in order to fix the bug in some
; 80286 chips which allows interrupts to occur during a POPF even when
; interrupts remain disabled.
;
MPOPF macro
    local   p1, p2
    jmp     short p2
p1: iret                ;jump to pushed address & pop flags
p2: push    cs          ;construct far return address to
    call    p1          ; the next instruction
    endm

;
; Macro to delay briefly to ensure that enough time has elapsed
; between successive I/O accesses so that the device being accessed
; can respond to both accesses even on a very fast PC.
;
DELAY macro
    jmp     $+2
    jmp     $+2
    jmp     $+2
    endm

StartBIOSCountLow   dw  ?   ;BIOS count low word at the
                            ; start of the timing period
StartBIOSCountHigh  dw  ?   ;BIOS count high word at the
                            ; start of the timing period
EndBIOSCountLow     dw  ?   ;BIOS count low word at the
                            ; end of the timing period
EndBIOSCountHigh    dw  ?   ;BIOS count high word at the
                            ; end of the timing period
EndTimedCount       dw  ?   ;timer 0 count at the end of
                            ; the timing period
ReferenceCount      dw  ?   ;number of counts required to
                            ; execute timer overhead code
;
; String printed to report results.
;
OutputStr   label   byte
            db      0dh, 0ah, 'Timed count: '
TimedCountStr       db  10 dup (?)
            db      ' microseconds', 0dh, 0ah
            db      '$'
;
; Temporary storage for timed count as it's divided down by powers
; of ten when converting from doubleword binary to ASCII.
;
CurrentCountLow     dw  ?
CurrentCountHigh    dw  ?
;
; Powers of ten table used to perform division by 10 when doing
; doubleword conversion from binary to ASCII.
;
PowersOfTen     label   word
    dd  1
    dd  10
    dd  100
    dd  1000
    dd  10000
    dd  100000
    dd  1000000
    dd  10000000
    dd  100000000
    dd  1000000000
PowersOfTenEnd  label   word
;
; String printed to report that the high word of the BIOS count
; changed while timing (an hour elapsed or midnight was crossed),
; and so the count is invalid and the test needs to be rerun.
;
TurnOverStr     label   byte
    db  0dh, 0ah
    db  '****************************************************'
    db  0dh, 0ah
    db  '* Either midnight passed or an hour or more passed *'
    db  0dh, 0ah
    db  '* while timing was in progress. If the former was  *'
    db  0dh, 0ah
    db  '* the case, please rerun the test; if the latter   *'
    db  0dh, 0ah
    db  '* was the case, the test code takes too long to    *'
    db  0dh, 0ah
    db  '* run to be timed by the long-period Zen timer.    *'
    db  0dh, 0ah
    db  '* Suggestions: use the DOS TIME command, the DOS   *'
    db  0dh, 0ah
    db  '* time function, or a watch.                       *'
    db  0dh, 0ah
    db  '****************************************************'
    db  0dh, 0ah
    db  '$'

;********************************************************************
;* Routine called to start timing.                                  *
;********************************************************************

ZTimerOn    proc    near

;
; Save the context of the program being timed.
;
    push    ax
    pushf
;
; Set timer 0 of the 8253 to mode 2 (divide-by-N), to cause
; linear counting rather than count-by-two counting. Also stops
; timer 0 until the timer count is loaded, except on PS/2
; computers.
;
    mov     al,00110100b        ;mode 2
    out     MODE_8253,al
;
; Set the timer count to 0, so we know we won't get another
; timer interrupt right away.
; Note: this introduces an inaccuracy of up to 54 ms in the system
; clock count each time it is executed.
;
    DELAY
    sub     al,al
    out     TIMER_0_8253,al     ;lsb
    DELAY
    out     TIMER_0_8253,al     ;msb
;
; In case interrupts are disabled, enable interrupts briefly to allow
; the interrupt generated when switching from mode 3 to mode 2 to be
; recognized. Interrupts must be enabled for at least 210 ns to allow
; time for that interrupt to occur. Here, 10 jumps are used for the
; delay to ensure that the delay time will be more than long enough
; even on a very fast PC.
;
    pushf
    sti
    rept    10
    jmp     $+2
    endm
    MPOPF
;
; Store the timing start BIOS count.
; (Since the timer count was just set to 0, the BIOS count will
; stay the same for the next 54 ms, so we don't need to disable
; interrupts in order to avoid getting a half-changed count.)
;
    push    ds
    sub     ax,ax
    mov     ds,ax
    mov     ax,ds:[TIMER_COUNT+2]
    mov     cs:[StartBIOSCountHigh],ax
    mov     ax,ds:[TIMER_COUNT]
    mov     cs:[StartBIOSCountLow],ax
    pop     ds
;
; Set the timer count to 0 again to start the timing interval.
;
    mov     al,00110100b        ;set up to load initial
    out     MODE_8253,al        ; timer count
    DELAY
    sub     al,al
    out     TIMER_0_8253,al     ;load count lsb
    DELAY
    out     TIMER_0_8253,al     ;load count msb
;
; Restore the context of the program being timed and return to it.
;
    MPOPF
    pop     ax
    ret

ZTimerOn    endp

;********************************************************************
;* Routine called to stop timing and get count.                     *
;********************************************************************

ZTimerOff   proc    near

;
; Save the context of the program being timed.
;
    pushf
    push    ax
    push    cx
;
; In case interrupts are disabled, enable interrupts briefly to allow
; any pending timer interrupt to be handled. Interrupts must be
; enabled for at least 210 ns to allow time for that interrupt to
; occur. Here, 10 jumps are used for the delay to ensure that the
; delay time will be more than long enough even on a very fast PC.
;
    sti
    rept    10
    jmp     $+2
    endm

;
; Latch the timer count.
;

if PS2

    mov     al,00000000b
    out     MODE_8253,al    ;latch timer 0 count
;
; This is where a one-instruction-long window exists on the PS/2.
; The timer count and the BIOS count can lose synchronization;
; since the timer keeps counting after it's latched, it can turn
; over right after it's latched and cause the BIOS count to turn
; over before interrupts are disabled, leaving us with the timer
; count from before the timer turned over coupled with the BIOS
; count from after the timer turned over. The result is a count
; that's 54 ms too long.
;

else

;
; Set timer 0 to mode 2 (divide-by-N), waiting for a 2-byte count
; load, which stops timer 0 until the count is loaded. (Only works
; on fully 8253-compatible chips.)
;
    mov     al,00110100b    ;mode 2
    out     MODE_8253,al
    DELAY
    mov     al,00000000b    ;latch timer 0 count
    out     MODE_8253,al

endif

    cli                     ;stop the BIOS count
;
; Read the BIOS count. (Since interrupts are disabled, the BIOS
; count won't change.)
;
    push    ds
    sub     ax,ax
    mov     ds,ax
    mov     ax,ds:[TIMER_COUNT+2]
    mov     cs:[EndBIOSCountHigh],ax
    mov     ax,ds:[TIMER_COUNT]
    mov     cs:[EndBIOSCountLow],ax
    pop     ds
;
; Read the timer count and save it.
;
    in      al,TIMER_0_8253         ;lsb
    DELAY
    mov     ah,al
    in      al,TIMER_0_8253         ;msb
    xchg    ah,al
    neg     ax                      ;convert from countdown
                                    ; remaining to elapsed
                                    ; count
    mov     cs:[EndTimedCount],ax
;
; Restart timer 0, which is still waiting for an initial count
; to be loaded.
;

ife PS2

    DELAY
    mov     al,00110100b    ;mode 2, waiting to load a
                            ; 2-byte count
    out     MODE_8253,al
    DELAY
    sub     al,al
    out     TIMER_0_8253,al ;lsb
    DELAY
    mov     al,ah
    out     TIMER_0_8253,al ;msb
    DELAY

endif

    sti                     ;let the BIOS count continue
;
; Time a zero-length code fragment, to get a reference for how
; much overhead this routine has. Time it 16 times and average it,
; for accuracy, rounding the result.
;
    mov     cs:[ReferenceCount],0
    mov     cx,16
    cli                     ;interrupts off to allow a
                            ; precise reference count
RefLoop:
    call    ReferenceZTimerOn
    call    ReferenceZTimerOff
    loop    RefLoop
    sti
    add     cs:[ReferenceCount],8   ;total + (0.5 * 16)
    mov     cl,4
    shr     cs:[ReferenceCount],cl  ;(total) / 16 + 0.5
;
; Restore the context of the program being timed and return to it.
;
    pop     cx
    pop     ax
    MPOPF
    ret

ZTimerOff   endp

;
; Called by ZTimerOff to start the timer for overhead measurements.
;

ReferenceZTimerOn   proc    near
;
; Save the context of the program being timed.
;
    push    ax
    pushf
;
; Set timer 0 of the 8253 to mode 2 (divide-by-N), to cause
; linear counting rather than count-by-two counting.
;
    mov     al,00110100b        ;mode 2
    out     MODE_8253,al
;
; Set the timer count to 0.
;
    DELAY
    sub     al,al
    out     TIMER_0_8253,al     ;lsb
    DELAY
    out     TIMER_0_8253,al     ;msb
;
; Restore the context of the program being timed and return to it.
;
    MPOPF
    pop     ax
    ret

ReferenceZTimerOn   endp

;
; Called by ZTimerOff to stop the timer and add the result to
; ReferenceCount for overhead measurements. Doesn't need to look
; at the BIOS count because timing a zero-length code fragment
; isn't going to take anywhere near 54 ms.
;

ReferenceZTimerOff  proc    near
;
; Save the context of the program being timed.
;
    pushf
    push    ax
    push    cx

;
; Match the interrupt-window delay in ZTimerOff.
;
    sti
    rept    10
    jmp     $+2
    endm

    mov     al,00000000b
    out     MODE_8253,al        ;latch timer
;
; Read the count and save it.
;
    DELAY
    in      al,TIMER_0_8253     ;lsb
    DELAY
    mov     ah,al
    in      al,TIMER_0_8253     ;msb
    xchg    ah,al
    neg     ax                  ;convert from countdown
                                ; remaining to elapsed
                                ; count
    add     cs:[ReferenceCount],ax
;
; Restore the context and return.
;
    pop     cx
    pop     ax
    MPOPF
    ret

ReferenceZTimerOff  endp

;********************************************************************
;* Routine called to report timing results.                         *
;********************************************************************

ZTimerReport    proc    near

    pushf
    push    ax
    push    bx
    push    cx
    push    dx
    push    si
    push    di
    push    ds
;
    push    cs              ;DOS functions require that DS point
    pop     ds              ; to text to be displayed on the screen
    assume  ds:Code
;
; See if midnight or more than an hour passed during timing. If so,
; notify the user.
;
    mov     ax,[StartBIOSCountHigh]
    cmp     ax,[EndBIOSCountHigh]
    jz      CalcBIOSTime                ;hour count didn't change,
                                        ; so everything's fine
    inc     ax
    cmp     ax,[EndBIOSCountHigh]
    jnz     TestTooLong                 ;midnight or two hour
                                        ; boundaries passed, so the
                                        ; results are no good
    mov     ax,[EndBIOSCountLow]
    cmp     ax,[StartBIOSCountLow]
    jb      CalcBIOSTime                ;a single hour boundary
                                        ; passed-that's OK, so long as
                                        ; the total time wasn't more
                                        ; than an hour

;
; Over an hour elapsed or midnight passed during timing, which
; renders the results invalid. Notify the user. This misses the
; case where a multiple of 24 hours has passed, but we'll rely
; on the perspicacity of the user to detect that case.
;
TestTooLong:
    mov     ah,9
    mov     dx,offset TurnOverStr
    int     21h
    jmp     short ZTimerReportDone
;
; Convert the BIOS time to microseconds.
;
CalcBIOSTime:
    mov     ax,[EndBIOSCountLow]
    sub     ax,[StartBIOSCountLow]
    mov     dx,54925                ;number of microseconds each
                                    ; BIOS count represents
    mul     dx
    mov     bx,ax                   ;set aside BIOS count in
    mov     cx,dx                   ; microseconds
;
; Convert timer count to microseconds.
;
    mov     ax,[EndTimedCount]
    mov     si,8381
    mul     si
    mov     si,10000
    div     si                      ;* .8381 = * 8381 / 10000
;
; Add timer and BIOS counts together to get an overall time in
; microseconds.
;
    add     bx,ax
    adc     cx,0
;
; Subtract the timer overhead and save the result.
;
    mov     ax,[ReferenceCount]
    mov     si,8381                 ;convert the reference count
    mul     si                      ; to microseconds
    mov     si,10000
    div     si                      ;* .8381 = * 8381 / 10000
    sub     bx,ax
    sbb     cx,0
    mov     [CurrentCountLow],bx
    mov     [CurrentCountHigh],cx
;
; Convert the result to an ASCII string by trial subtractions of
; powers of 10.
;
    mov     di,offset PowersOfTenEnd -offset PowersOfTen -4
    mov     si,offset TimedCountStr
CTSNextDigit:
    mov     bl,'0'
CTSLoop:
    mov     ax,[CurrentCountLow]
    mov     dx,[CurrentCountHigh]
    sub     ax,PowersOfTen[di]
    sbb     dx,PowersOfTen[di+2]
    jc      CTSNextPowerDown
    inc     bl
    mov     [CurrentCountLow],ax
    mov     [CurrentCountHigh],dx
    jmp     CTSLoop
CTSNextPowerDown:
    mov     [si],bl
    inc     si
    sub     di,4
    jns     CTSNextDigit
;
;
; Print the results.
;
    mov     ah,9
    mov     dx,offset OutputStr
    int     21h
;
ZTimerReportDone:
    pop     ds
    pop     di
    pop     si
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    MPOPF
    ret

ZTimerReport    endp

Code    ends
        End
```

## LZTIMER

```nasm
; LZTIMER
;
; *** Listing 2-5 ***
;
; The long-period Zen timer. (LZTIMER.ASM)
; Uses the 8253 timer and the BIOS time-of-day count to time the
; performance of code that takes less than an hour to execute.
; Because interrupts are left on (in order to allow the timer
; interrupt to be recognized), this is less accurate than the
; precision Zen timer, so it is best used only to time code that
takes
; more than about 54 milliseconds to execute (code that the
precision
; Zen timer reports overflow on). Resolution is limited by the
; occurrence of timer interrupts.
;
; By Michael Abrash 4/26/89
;
; Externally callable routines:
;
; ZTimerOn: Saves the BIOS time of day count and starts the
; long-period Zen timer.
;
; ZTimerOff: Stops the long-period Zen timer and saves the timer
; count and the BIOS time-of-day count.
;
; ZTimerReport: Prints the time that passed between starting and
; stopping the timer.
;
; Note: If either more than an hour passes or midnight falls between
; calls to ZTimerOn and ZTimerOff, an error is reported. For
; timing code that takes more than a few minutes to execute,
; either the DOS TIME command in a batch file before and after
; execution of the code to time or the use of the DOS
; time-of-day function in place of the long-period Zen timer is
; more than adequate.
;
; Note: The PS/2 version is assembled by setting the symbol PS2 to
1.
; PS2 must be set to 1 on PS/2 computers because the PS/2's
; timers are not compatible with an undocumented timer-stopping
; feature of the 8253; the alternative timing approach that
; must be used on PS/2 computers leaves a short window
; during which the timer 0 count and the BIOS timer count may
; not be synchronized. You should also set the PS2 symbol to
; 1 if you're getting erratic or obviously incorrect results.
;
; Note: When PS2 is 0, the code relies on an undocumented 8253
; feature to get more reliable readings. It is possible that
; the 8253 (or whatever chip is emulating the 8253) may be put
; into an undefined or incorrect state when this feature is
; used.
;
;
***************************************************************
; * If your computer displays any hint of erratic behavior *
; * after the long-period Zen timer is used, such as the floppy *
; * drive failing to operate properly, reboot the system, set *
; * PS2 to 1 and leave it that way! *
;
***************************************************************
;
; Note: Each block of code being timed should ideally be run several
; times, with at least two similar readings required to
; establish a true measurement, in order to eliminate any
; variability caused by interrupts.
;
; Note: Interrupts must not be disabled for more than 54 ms at a
; stretch during the timing interval. Because interrupts
; are enabled, keys, mice, and other devices that generate
; interrupts should not be used during the timing interval.
;
; Note: Any extra code running off the timer interrupt (such as
; some memory-resident utilities) wilLincrease the time
; measured by the Zen timer.
;
; Note: These routines can introduce inaccuracies of up to a few
; tenths of a second into the system clock count for each
; code section timed. Consequently, it's a good idea to
; reboot at the conclusion of timing sessions. (The
; battery-backed clock, if any, is not affected by the Zen
; timer.)
;
; All registers and all flags are preserved by all routines.
;

Code segment word public 'CODE'
assume cs:Code, ds:nothing
public ZTimerOn, ZTimerOff, ZTimerReport

;
; Set PS2 to 0 to assemble for use on a fully 8253-compatible
; system; when PS2 is 0, the readings are more reliable if the
; computer supports the undocumented timer-stopping feature,
; but may be badly off if that feature is not supported. In
; fact, timer-stopping may interfere with your computer's
; overall operation by putting the 8253 into an undefined or
; incorrect state. Use with caution!!!
;
; Set PS2 to 1 to assemble for use on non-8253-compatible
; systems, including PS/2 computers; when PS2 is 1, readings
; may occasionally be off by 54 ms, but the code will work
; properly on all systems.
;
; A setting of 1 is safer and will work on more systems,
; while a setting of 0 produces more reliable results in systems
; which support the undocumented timer-stopping feature of the
; 8253. The choice is yours.
;
PS2 equ 1
;
; Base address of the 8253 timer chip.
;
BASE_8253 equ 40h
;
; The address of the timer 0 count registers in the 8253.
;
TIMER_0_8253 equ BASE_8253 + 0
;
; The address of the mode register in the 8253.
;
MODE_8253 equ BASE_8253 + 3
;
; The address of the BIOS timer count variable in the BIOS
; data segment.
;
TIMER_COUNT equ 46ch
;
; Macro to emulate a POPF instruction in order to fix the bug in
some
; 80286 chips which allows interrupts to occur during a POPF even
when
; interrupts remain disabled.
;
MPOPF macro
local p1, p2
jmp short p2
p1: iret ;jump to pushed address & pop flags
p2: push cs ;construct far return address to
call p1 ; the next instruction
endm

;
; Macro to delay briefly to ensure that enough time has elapsed
; between successive I/O accesses so that the device being accessed
; can respond to both accesses even on a very fast PC.
;
DELAY macro
jmp $+2
jmp $+2
jmp $+2
endm

StartBIOSCountLow dw ? ;BIOS count low word at the
; start of the timing period
StartBIOSCountHigh dw ? ;BIOS count high word at the
; start of the timing period
EndBIOSCountLow dw ? ;BIOS count low word at the
; end of the timing period
EndBIOSCountHigh dw ? ;BIOS count high word at the
; end of the timing period
EndTimedCount dw ? ;timer 0 count at the end of
; the timing period
ReferenceCount dw ? ;number of counts required to
; execute timer overhead code
;
; String printed to report results.
;
OutputStr label byte
db 0dh, 0ah, 'Timed count: '
TimedCountStr db 10 dup (?)
db ' microseconds', 0dh, 0ah
db '$'
;
; Temporary storage for timed count as it's divided down by powers
; of ten when converting from doubleword binary to ASCII.
;
CurrentCountLow dw ?
CurrentCountHigh dw ?
;
; Powers of ten table used to perform division by 10 when doing
; doubleword conversion from binary to ASCII.
;
PowersOfTen label word
dd 1
dd 10
dd 100
dd 1000
dd 10000
dd 100000
dd 1000000
dd 10000000
dd 100000000
dd 1000000000
PowersOfTenEnd label word
;
; String printed to report that the high word of the BIOS count
; changed while timing (an hour elapsed or midnight was crossed),
; and so the count is invalid and the test needs to be rerun.
;
TurnOverStr label byte
db 0dh, 0ah
db
'****************************************************'
db 0dh, 0ah
db '* Either midnight passed or an hour or more passed *'
db 0dh, 0ah
db '* while timing was in progress. If the former was *'
db 0dh, 0ah
db '* the case, please rerun the test; if the latter *'
db 0dh, 0ah
db '* was the case, the test code takes too long to *'
db 0dh, 0ah
db '* run to be timed by the long-period Zen timer. *'
db 0dh, 0ah
db '* Suggestions: use the DOS TIME command, the DOS *'
db 0dh, 0ah
db '* time function, or a watch. *'
db 0dh, 0ah
db
'****************************************************'
db 0dh, 0ah
db '$'

;********************************************************************
;* Routine called to start timing. *
;********************************************************************

ZTimerOn proc near

;
; Save the context of the program being timed.
;
push ax
pushf
;
; Set timer 0 of the 8253 to mode 2 (divide-by-N), to cause
; linear counting rather than count-by-two counting. Also stops
; timer 0 until the timer count is loaded, except on PS/2
; computers.
;
mov al,00110100b ;mode 2
out MODE_8253,al
;
; Set the timer count to 0, so we know we won't get another
; timer interrupt right away.
; Note: this introduces an inaccuracy of up to 54 ms in the system
; clock count each time it is executed.
;
DELAY
sub al,al
out TIMER_0_8253,al ;lsb
DELAY
out TIMER_0_8253,al ;msb
;
; In case interrupts are disabled, enable interrupts briefly to
allow
; the interrupt generated when switching from mode 3 to mode 2 to be
; recognized. Interrupts must be enabled for at least 210 ns to
allow
; time for that interrupt to occur. Here, 10 jumps are used for the
; delay to ensure that the delay time will be more than long enough
; even on a very fast PC.
;
pushf
sti
rept 10
jmp $+2
endm
MPOPF
;
; Store the timing start BIOS count.
; (Since the timer count was just set to 0, the BIOS count will
; stay the same for the next 54 ms, so we don't need to disable
; interrupts in order to avoid getting a half-changed count.)
;
push ds
sub ax,ax
mov ds,ax
mov ax,ds:[TIMER_COUNT+2]
mov cs:[StartBIOSCountHigh],ax
mov ax,ds:[TIMER_COUNT]
mov cs:[StartBIOSCountLow],ax
pop ds
;
; Set the timer count to 0 again to start the timing interval.
;
mov al,00110100b ;set up to load initial
out MODE_8253,al ; timer count
DELAY
sub al,al
out TIMER_0_8253,al ;load count lsb
DELAY
out TIMER_0_8253,al ;load count msb
;
; Restore the context of the program being timed and return to it.
;
MPOPF
pop ax
ret

ZTimerOn endp

;********************************************************************
;* Routine called to stop timing and get count. *
;********************************************************************

ZTimerOff proc near

;
; Save the context of the program being timed.
;
pushf
push ax
push cx
;
; In case interrupts are disabled, enable interrupts briefly to
allow
; any pending timer interrupt to be handled. Interrupts must be
; enabled for at least 210 ns to allow time for that interrupt to
; occur. Here, 10 jumps are used for the delay to ensure that the
; delay time will be more than long enough even on a very fast PC.
;
sti
rept 10
jmp $+2
endm

;
; Latch the timer count.
;

if PS2

mov al,00000000b
out MODE_8253,al ;latch timer 0 count
;
; This is where a one-instruction-long window exists on the PS/2.
; The timer count and the BIOS count can lose synchronization;
; since the timer keeps counting after it's latched, it can turn
; over right after it's latched and cause the BIOS count to turn
; over before interrupts are disabled, leaving us with the timer
; count from before the timer turned over coupled with the BIOS
; count from after the timer turned over. The result is a count
; that's 54 ms too long.
;

else

;
; Set timer 0 to mode 2 (divide-by-N), waiting for a 2-byte count
; load, which stops timer 0 until the count is loaded. (Only works
; on fully 8253-compatible chips.)
;
mov al,00110100b ;mode 2
out MODE_8253,al
DELAY
mov al,00000000b ;latch timer 0 count
out MODE_8253,al

endif

cli ;stop the BIOS count
;
; Read the BIOS count. (Since interrupts are disabled, the BIOS
; count won't change.)
;
push ds
sub ax,ax
mov ds,ax
mov ax,ds:[TIMER_COUNT+2]
mov cs:[EndBIOSCountHigh],ax
mov ax,ds:[TIMER_COUNT]
mov cs:[EndBIOSCountLow],ax
pop ds
;
; Read the timer count and save it.
;
in al,TIMER_0_8253 ;lsb
DELAY
mov ah,al
in al,TIMER_0_8253 ;msb
xchg ah,al
neg ax ;convert from countdown
; remaining to elapsed
; count
mov cs:[EndTimedCount],ax
;
; Restart timer 0, which is still waiting for an initial count
; to be loaded.
;

ife PS2

DELAY
mov al,00110100b ;mode 2, waiting to load a
; 2-byte count
out MODE_8253,al
DELAY
sub al,al
out TIMER_0_8253,al ;lsb
DELAY
mov al,ah
out TIMER_0_8253,al ;msb
DELAY

endif

sti ;let the BIOS count continue
;
; Time a zero-length code fragment, to get a reference for how
; much overhead this routine has. Time it 16 times and average it,
; for accuracy, rounding the result.
;
mov cs:[ReferenceCount],0
mov cx,16
cli ;interrupts off to allow a
; precise reference count
RefLoop:
call ReferenceZTimerOn
call ReferenceZTimerOff
loop RefLoop
sti
add cs:[ReferenceCount],8 ;total + (0.5 * 16)
mov cl,4
shr cs:[ReferenceCount],cl ;(total) / 16 + 0.5
;
; Restore the context of the program being timed and return to it.
;
pop cx
pop ax
MPOPF
ret

ZTimerOff endp

;
; Called by ZTimerOff to start the timer for overhead measurements.
;

ReferenceZTimerOn proc near
;
; Save the context of the program being timed.
;
push ax
pushf
;
; Set timer 0 of the 8253 to mode 2 (divide-by-N), to cause
; linear counting rather than count-by-two counting.
;
mov al,00110100b ;mode 2
out MODE_8253,al
;
; Set the timer count to 0.
;
DELAY
sub al,al
out TIMER_0_8253,al ;lsb
DELAY
out TIMER_0_8253,al ;msb
;
; Restore the context of the program being timed and return to it.
;
MPOPF
pop ax
ret

ReferenceZTimerOn endp

;
; Called by ZTimerOff to stop the timer and add the result to
; ReferenceCount for overhead measurements. Doesn't need to look
; at the BIOS count because timing a zero-length code fragment
; isn't going to take anywhere near 54 ms.
;

ReferenceZTimerOff proc near
;
; Save the context of the program being timed.
;
pushf
push ax
push cx

;
; Match the interrupt-window delay in ZTimerOff.
;
sti
rept 10
jmp $+2
endm

mov al,00000000b
out MODE_8253,al ;latch timer
;
; Read the count and save it.
;
DELAY
in al,TIMER_0_8253 ;lsb
DELAY
mov ah,al
in al,TIMER_0_8253 ;msb
xchg ah,al
neg ax ;convert from countdown
; remaining to elapsed
; count
add cs:[ReferenceCount],ax
;
; Restore the context and return.
;
pop cx
pop ax
MPOPF
ret

ReferenceZTimerOff endp

;********************************************************************
;* Routine called to report timing results. *
;********************************************************************

ZTimerReport proc near

pushf
push ax
push bx
push cx
push dx
push si
push di
push ds
;
push cs ;DOS functions require that DS point
pop ds ; to text to be displayed on the screen
assume ds:Code
;
; See if midnight or more than an hour passed during timing. If so,
; notify the user.
;
mov ax,[StartBIOSCountHigh]
cmp ax,[EndBIOSCountHigh]
jz CalcBIOSTime ;hour count didn't change,
; so everything's fine
inc ax
cmp ax,[EndBIOSCountHigh]
jnz TestTooLong ;midnight or two hour
; boundaries passed, so the
; results are no good
mov ax,[EndBIOSCountLow]
cmp ax,[StartBIOSCountLow]
jb CalcBIOSTime ;a single hour boundary
; passed-that's OK, so long as
; the total time wasn't more
; than an hour

;
; Over an hour elapsed or midnight passed during timing, which
; renders the results invalid. Notify the user. This misses the
; case where a multiple of 24 hours has passed, but we'll rely
; on the perspicacity of the user to detect that case.
;
TestTooLong:
mov ah,9
mov dx,offset TurnOverStr
int 21h
jmp short ZTimerReportDone
;
; Convert the BIOS time to microseconds.
;
CalcBIOSTime:
mov ax,[EndBIOSCountLow]
sub ax,[StartBIOSCountLow]
mov dx,54925 ;number of microseconds each
; BIOS count represents
mul dx
mov bx,ax ;set aside BIOS count in
mov cx,dx ; microseconds
;
; Convert timer count to microseconds.
;
mov ax,[EndTimedCount]
mov si,8381
mul si
mov si,10000
div si ;* .8381 = * 8381 / 10000
;
; Add timer and BIOS counts together to get an overall time in
; microseconds.
;
add bx,ax
adc cx,0
;
; Subtract the timer overhead and save the result.
;
mov ax,[ReferenceCount]
mov si,8381 ;convert the reference count
mul si ; to microseconds
mov si,10000
div si ;* .8381 = * 8381 / 10000
sub bx,ax
sbb cx,0
mov [CurrentCountLow],bx
mov [CurrentCountHigh],cx
;
; Convert the result to an ASCII string by trial subtractions of
; powers of 10.
;
mov di,offset PowersOfTenEnd -offset PowersOfTen -4
mov si,offset TimedCountStr
CTSNextDigit:
mov bl,'0'
CTSLoop:
mov ax,[CurrentCountLow]
mov dx,[CurrentCountHigh]
sub ax,PowersOfTen[di]
sbb dx,PowersOfTen[di+2]
jc CTSNextPowerDown
inc bl
mov [CurrentCountLow],ax
mov [CurrentCountHigh],dx
jmp CTSLoop
CTSNextPowerDown:
mov [si],bl
inc si
sub di,4
jns CTSNextDigit
;
;
; Print the results.
;
mov ah,9
mov dx,offset OutputStr
int 21h
;
ZTimerReportDone:
pop ds
pop di
pop si
pop dx
pop cx
pop bx
pop ax
MPOPF
ret

ZTimerReport endp

Code ends
end

## PZTEST

; PZTEST
;
; *** Listing 2-2 ***
;
; Program to measure performance of code that takes less than
; 54 ms to execute. (PZTEST.ASM)
;
; Link with PZTIMER.ASM (Listing 2-1). PZTEST.BAT (Listing 2-4)
; can be used to assemble and link both files. Code to be
; measured must be in the file TESTCODE; Listing 2-3 shows
; a sample TESTCODE file.
;
; By Michael Abrash 4/26/89
;
mystack segment para stack 'STACK'
db 512 dup(?)
mystack ends
;
Code segment para public 'CODE'
assume cs:Code, ds:Code
extrn ZTimerOn:near, ZTimerOff:near, ZTimerReport:near
Start proc near
push cs
pop ds ;set DS to point to the code segment,
; so data as well as code can easily
; be included in TESTCODE
;
include TESTCODE ;code to be measured, including
; calls to ZTimerOn and ZTimerOff
;
; Display the results.
;
call ZTimerReport
;
; Terminate the program.
;
mov ah,4ch
int 21h
Start endp
Code ends
end Start
```

## PZTIME.BAT

```bat
PZTIME.BAT
echo off
rem
rem *** Listing 2-4 ***
rem
rem
***************************************************************
rem * Batch file PZTIME.BAT, which builds and runs the precision *
rem * Zen timer program PZTEST.EXE to time the code named as the *
rem * command-line parameter. Listing 2-1 must be named *
rem * PZTIMER.ASM, and Listing 2-2 must be named PZTEST.ASM. To *
rem * time the code in LST2-3, you'd type the DOS command: *
rem * *
rem * pztime lst2-3 *
rem * *
rem * Note that MASM and LINK must be in the current directory or
*
rem * on the current path in order for this batch file to work. *
rem * *
rem * This batch file can be speeded up by assembling PZTIMER.ASM
*
rem * once, then removing the lines: *
rem * *
rem * masm pztimer; *
rem * if errorlevel 1 goto errorend *
rem * *
rem * from this file. *
rem * *
rem * By Michael Abrash 4/26/89 *
rem
***************************************************************
rem
rem Make sure a file to test was specified.
rem
if not x%1==x goto ckexist
echo
***************************************************************
echo * Please specify a file to test. *
echo
***************************************************************
goto end
rem
rem Make sure the file exists.
rem
:ckexist
if exist %1 goto docopy
echo
***************************************************************
echo * The specified file, "%1," doesn't exist.
echo
***************************************************************
goto end
rem
rem copy the file to measure to TESTCODE.
rem
:docopy
copy %1 testcode
masm pztest;
if errorlevel 1 goto errorend
masm pztimer;
if errorlevel 1 goto errorend
link pztest+pztimer;
if errorlevel 1 goto errorend
pztest
goto end
:errorend
echo
***************************************************************
echo * An error occurred while building the precision Zen timer. *
echo
***************************************************************
:end
```

## PZTIMER

```nasm
; PZTIMER
;
; *** Listing 2-1 ***
;
; The precision Zen timer (PZTIMER.ASM)
;
; Uses the 8253 timer to time the performance of code that takes
; less than about 54 milliseconds to execute, with a resolution
; of better than 10 microseconds.
;
; By Michael Abrash 4/26/89
;
; Externally callable routines:
;
; ZTimerOn: Starts the Zen timer, with interrupts disabled.
;
; ZTimerOff: Stops the Zen timer, saves the timer count,
; times the overhead code, and restores interrupts to the
; state they were in when ZTimerOn was called.
;
; ZTimerReport: Prints the net time that passed between starting
; and stopping the timer.
;
; Note: If longer than about 54 ms passes between ZTimerOn and
; ZTimerOff calls, the timer turns over and the count is
; inaccurate. When this happens, an error message is displayed
; instead of a count. The long-period Zen timer should be used
; in such cases.
;
; Note: Interrupts *MUST* be left off between calls to ZTimerOn
; and ZTimerOff for accurate timing and for detection of
; timer overflow.
;
; Note: These routines can introduce slight inaccuracies into the
; system clock count for each code section timed even if
; timer 0 doesn't overflow. If timer 0 does overflow, the
; system clock can become slow by virtually any amount of
; time, since the system clock can't advance while the
; precison timer is timing. Consequently, it's a good idea
; to reboot at the end of each timing session. (The
; battery-backed clock, if any, is not affected by the Zen
; timer.)
;
; All registers, and all flags except the interrupt flag, are
; preserved by all routines. Interrupts are enabled and then
disabled
; by ZTimerOn, and are restored by ZTimerOff to the state they were
; in when ZTimerOn was called.
;

Code segment word public 'CODE'
assume cs:Code, ds:nothing
public ZTimerOn, ZTimerOff, ZTimerReport

;
; Base address of the 8253 timer chip.
;
BASE_8253 equ 40h
;
; The address of the timer 0 count registers in the 8253.
;
TIMER_0_8253 equ BASE_8253 + 0
;
; The address of the mode register in the 8253.
;
MODE_8253 equ BASE_8253 + 3
;
; The address of Operation Command Word 3 in the 8259 Programmable
; Interrupt Controller (PIC) (write only, and writable only when
; bit 4 of the byte written to this address is 0 and bit 3 is 1).
;
OCW3 equ 20h
;
; The address of the Interrupt Request register in the 8259 PIC
; (read only, and readable only when bit 1 of OCW3 = 1 and bit 0
; of OCW3 = 0).
;
IRR equ 20h
;
; Macro to emulate a POPF instruction in order to fix the bug in
some
; 80286 chips which allows interrupts to occur during a POPF even
when
; interrupts remain disabled.
;
MPOPF macro
local p1, p2
jmp short p2
p1: iret ;jump to pushed address & pop flags
p2: push cs ;construct far return address to
call p1 ; the next instruction
endm

;
; Macro to delay briefly to ensure that enough time has elapsed
; between successive I/O accesses so that the device being accessed
; can respond to both accesses even on a very fast PC.
;
DELAY macro
jmp $+2
jmp $+2
jmp $+2
endm

OriginalFlags db ? ;storage for upper byte of
; FLAGS register when
; ZTimerOn called
TimedCount dw ? ;timer 0 count when the timer
; is stopped
ReferenceCount dw ? ;number of counts required to
; execute timer overhead code
OverflowFlag db ? ;used to indicate whether the
; timer overflowed during the
; timing interval
;
; String printed to report results.
;
OutputStr label byte
db 0dh, 0ah, 'Timed count: ', 5 dup (?)
ASCIICountEnd label byte
db ' microseconds', 0dh, 0ah
db '$'
;
; String printed to report timer overflow.
;
OverflowStr label byte
db 0dh, 0ah
db
'****************************************************'
db 0dh, 0ah
db '* The timer overflowed, so the interval timed was *'
db 0dh, 0ah
db '* too long for the precision timer to measure. *'
db 0dh, 0ah
db '* Please perform the timing test again with the *'
db 0dh, 0ah
db '* long-period timer. *'
db 0dh, 0ah
db
'****************************************************'
db 0dh, 0ah
db '$'

;********************************************************************
;* Routine called to start timing. *
;********************************************************************

ZTimerOn proc near

;
; Save the context of the program being timed.
;
push ax
pushf
pop ax ;get flags so we can keep
; interrupts off when leaving
; this routine
mov cs:[OriginalFlags],ah ;remember the state of the
; Interrupt flag
and ah,0fdh ;set pushed interrupt flag
; to 0
push ax
;
; Turn on interrupts, so the timer interrupt can occur if it's
; pending.
;
sti
;
; Set timer 0 of the 8253 to mode 2 (divide-by-N), to cause
; linear counting rather than count-by-two counting. Also
; leaves the 8253 waiting for the initial timer 0 count to
; be loaded.
;
mov al,00110100b ;mode 2
out MODE_8253,al
;
; Set the timer count to 0, so we know we won't get another
; timer interrupt right away.
; Note: this introduces an inaccuracy of up to 54 ms in the system
; clock count each time it is executed.
;
DELAY
sub al,al
out TIMER_0_8253,al ;lsb
DELAY
out TIMER_0_8253,al ;msb
;
; Wait before clearing interrupts to allow the interrupt generated
; when switching from mode 3 to mode 2 to be recognized. The delay
; must be at least 210 ns long to allow time for that interrupt to
; occur. Here, 10 jumps are used for the delay to ensure that the
; delay time will be more than long enough even on a very fast PC.
;
rept 10
jmp $+2
endm
;
; Disable interrupts to get an accurate count.
;
cli
;
; Set the timer count to 0 again to start the timing interval.
;
mov al,00110100b ;set up to load initial
out MODE_8253,al ; timer count
DELAY
sub al,al
out TIMER_0_8253,al ;load count lsb
DELAY
out TIMER_0_8253,al ;load count msb
;
; Restore the context and return.
;
MPOPF ;keeps interrupts off
pop ax
ret

ZTimerOn endp

;********************************************************************
;* Routine called to stop timing and get count. *
;********************************************************************

ZTimerOff proc near

;
; Save the context of the program being timed.
;
push ax
push cx
pushf
;
; Latch the count.
;
mov al,00000000b ;latch timer 0
out MODE_8253,al
;
; See if the timer has overflowed by checking the 8259 for a pending
; timer interrupt.
;
mov al,00001010b ;OCW3, set up to read
out OCW3,al ; Interrupt Request register
DELAY
in al,IRR ;read Interrupt Request
; register
and al,1 ;set AL to 1 if IRQ0 (the
; timer interrupt) is pending
mov cs:[OverflowFlag],al ;store the timer overflow
; status
;
; Allow interrupts to happen again.
;
sti
;
; Read out the count we latched earlier.
;
in al,TIMER_0_8253 ;least significant byte
DELAY
mov ah,al
in al,TIMER_0_8253 ;most significant byte
xchg ah,al
neg ax ;convert from countdown
; remaining to elapsed
; count
mov cs:[TimedCount],ax
; Time a zero-length code fragment, to get a reference for how
; much overhead this routine has. Time it 16 times and average it,
; for accuracy, rounding the result.
;
mov cs:[ReferenceCount],0
mov cx,16
cli ;interrupts off to allow a
; precise reference count
RefLoop:
call ReferenceZTimerOn
call ReferenceZTimerOff
loop RefLoop
sti
add cs:[ReferenceCount],8 ;total + (0.5 * 16)
mov cl,4
shr cs:[ReferenceCount],cl ;(total) / 16 + 0.5
;
; Restore originaLinterrupt state.
;
pop ax ;retrieve flags when called
mov ch,cs:[OriginalFlags] ;get back the original upper
; byte of the FLAGS register
and ch,not 0fdh ;only care about original
; interrupt flag...
and ah,0fdh ;...keep all other flags in
; their current condition
or ah,ch ;make flags word with original
; interrupt flag
push ax ;prepare flags to be popped
;
; Restore the context of the program being timed and return to it.
;
MPOPF ;restore the flags with the
; originaLinterrupt state
pop cx
pop ax
ret

ZTimerOff endp

;
; Called by ZTimerOff to start timer for overhead measurements.
;

ReferenceZTimerOn proc near
;
; Save the context of the program being timed.
;
push ax
pushf ;interrupts are already off
;
; Set timer 0 of the 8253 to mode 2 (divide-by-N), to cause
; linear counting rather than count-by-two counting.
;
mov al,00110100b ;set up to load
out MODE_8253,al ; initial timer count
DELAY
;
; Set the timer count to 0.
;
sub al,al
out TIMER_0_8253,al ;load count lsb
DELAY
out TIMER_0_8253,al ;load count msb
;
; Restore the context of the program being timed and return to it.
;
MPOPF
pop ax
ret

ReferenceZTimerOn endp

;
; Called by ZTimerOff to stop timer and add result to ReferenceCount
; for overhead measurements.
;

ReferenceZTimerOff proc near
;
; Save the context of the program being timed.
;
push ax
push cx
pushf
;
; Latch the count and read it.
;
mov al,00000000b ;latch timer 0
out MODE_8253,al
DELAY
in al,TIMER_0_8253 ;lsb
DELAY
mov ah,al
in al,TIMER_0_8253 ;msb
xchg ah,al
neg ax ;convert from countdown
; remaining to amount
; counted down
add cs:[ReferenceCount],ax
;
; Restore the context of the program being timed and return to it.
;
MPOPF
pop cx
pop ax
ret

ReferenceZTimerOff endp

;********************************************************************
;* Routine called to report timing results. *
;********************************************************************

ZTimerReport proc near

pushf
push ax
push bx
push cx
push dx
push si
push ds
;
push cs ;DOS functions require that DS point
pop ds ; to text to be displayed on the screen
assume ds:Code
;
; Check for timer 0 overflow.
;
cmp [OverflowFlag],0
jz PrintGoodCount
mov dx,offset OverflowStr
mov ah,9
int 21h
jmp short EndZTimerReport
;
; Convert net count to decimal ASCII in microseconds.
;
PrintGoodCount:
mov ax,[TimedCount]
sub ax,[ReferenceCount]
mov si,offset ASCIICountEnd -1
;
; Convert count to microseconds by multiplying by .8381.
;
mov dx,8381
mul dx
mov bx,10000
div bx ;* .8381 = * 8381 / 10000
;
; Convert time in microseconds to 5 decimal ASCII digits.
;
mov bx,10
mov cx,5
CTSLoop:
sub dx,dx
div bx
add dl,'0'
mov [si],dl
dec si
loop CTSLoop
;
; Print the results.
;
mov ah,9
mov dx,offset OutputStr
int 21h
;
EndZTimerReport:
pop ds
pop si
pop dx
pop cx
pop bx
pop ax
MPOPF
ret

ZTimerReport endp

Code ends

end
```
