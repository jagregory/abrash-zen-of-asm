**The Zen of Assembly Language Volume I, Knowledge**

Second Edition\

Table of Contents
=================

\

[Acknowledgements](#_ACKNOWLEDGEMENTS)

[Source Of Book Files](#SOB)

[Trademarks](#Trademarks)

[Introduction](#_Introduction:__Pushing)

[PART I: THE ZEN OF ASSEMBLER](#_Chapter_1:_)

[CHAPTER 1: ZEN?](#_Chapter_1:_)

[1.1 THE ZEN OF ASSEMBLER IN A NUTSHELL](#_THE_ZEN_OF)

[1.2 ASSEMBLER IS FUNDAMENTALLY DIFFERENT FROM OTHER
LANGUAGES](#_ASSEMBLER_IS_FUNDAMENTALLY)

[1.3 KNOWLEDGE](#_KNOWLEDGE)

[1.4 THE FLEXIBLE MIND](#_THE_FLEXIBLE_MIND)

[1.5 WHERE TO BEGIN?](#_WHERE_TO_BEGIN?)

[CHAPTER 2: ASSUME NOTHING](#_Chapter_2:_)

[2.1 THE ZEN TIMER](#_THE_ZEN_TIMER)

[2.2 THE ZEN TIMER IS A MEANS, NOT AN END](#C22)

[2.3 STARTING THE ZEN TIMER](#_STARTING_THE_ZEN)

[2.4 TIME AND THE PC](#_TIME_AND_THE)

[2.5 STOPPING THE ZEN TIMER](#_STOPPING_THE_ZEN)

[2.6 REPORTING TIMING RESULTS](#_REPORTING_TIMING_RESULTS)

[2.7 NOTES ON THE ZEN TIMER](#_NOTES_ON_THE)

[2.8 A SAMPLE USE OF THE ZEN TIMER](#_A_SAMPLE_USE)

[2.9 THE LONG-PERIOD ZEN TIMER](#_THE_LONG-PERIOD_ZEN)

[2.10 STOPPING THE CLOCK](#_STOPPING_THE_CLOCK)

[2.11 A SAMPLE USE OF THE LONG-PERIOD ZEN TIMER](#C211)

[2.12 FURTHER READING](#_FURTHER_READING)

[2.13 ARMED WITH THE ZEN TIMER, ONWARD AND UPWARD](#_ARMED_WITH_THE)

[PART II: KNOWLEDGE](#_Chapter_3:_)

[C](#_Chapter_3:_)[HAPTER](#_Chapter_3:_)[3: CONTEXT](#_Chapter_3:_)

[3.1 FROM THE BOTTOM UP](#_FROM_THE_BOTTOM)

[3.2 THE TRADITIONAL MODEL](#_THE_TRADITIONAL_MODEL)

[3.3 CYCLE-EATERS](#_CYCLE-EATERS)

[3.4 CODE IS DATA](#_CODE_IS_DATA)

[3.5 INSIDE THE 8088](#_INSIDE_THE_8088)

[3.6 STEPCHILD OF THE 8086](#_STEPCHILD_OF_THE)

[3.7 WHICH MODEL TO USE?](#_WHICH_MODEL_TO)

[C](#_Chapter_4:_)[HAPTER](#_Chapter_4:_)[4: THINGS MOTHER NEVER TOLD
YOU:](#_Chapter_4:_)

[UNDER THE PROGRAMMING INTERFACE](#_Chapter_4:_)

[4.1 CYCLE-EATERS REVISITED](#_CYCLE-EATERS_REVISITED)

[4.2 THE 8-BIT BUS CYCLE-EATER](#_THE_8-BIT_BUS)

[The Impact Of The 8-Bit Bus Cycle-Eate](#_THE_IMPACT_OF)

[What To Do About The 8-Bit Bus Cycle-Eater?](#_WHAT_TO_DO)

[4.3 THE PREFETCH QUEUE CYCLE-EATER](#_THE_PREFETCH_QUEUE)

[Official Execution Times Are Only Part Of The
Stor](#_OFFICIAL_EXECUTION_TIMES)

[There Is No Such Beast As A True Instruction Execution
Time](#_THERE_IS_NO)

[Approximating Overall Execution
Times](#_APPROXIMATING_OVERALL_EXECUTION)

[What To Do About The Prefetch Queue Cycle-Eater?](#_WHAT_TO_DO_1)

[Holding Up The 8088](#_HOLDING_UP_THE)

[4.4 DYNAMIC RAM REFRESH: THE INVISIBLE HAND](#_DYNAMIC_RAM_REFRESH:)

[How DRAM Refresh Works In The PC](#_HOW_DRAM_REFRESH)

[The Impact Of DRAM Refresh](#_THE_IMPACT_OF_1)

[What To Do About The DRAM Refresh Cycle-Eater?](#_WHAT_TO_DO_1)

[4.5 WAIT STATES](#_WAIT_STATES)

[The Display Adapter Cycle-Eater](#_THE_DISPLAY_ADAPTER)

[The Impact Of The Display Adapter Cycle-Eater](#_THE_IMPACT_OF_2)

[What To Do About The Display Adapter Cycle-Eater?](#_WHAT_TO_DO_2)

[4.6 CYCLE-EATERS: A SUMMARY](#_CYCLE-EATERS:__A)

[4.7 WHAT DOES IT ALL MEAN?](#_WHAT_DOES_IT)

[C](#_Chapter_5:_)[HAPTER](#_Chapter_5:_)[5: NIGHT OF THE
CYCLE-EATERS](#_Chapter_5:_)

[5.1 NO, WE'RE NOT IN KANSAS ANYMORE](#_NO,_WE%27RE_NOT)

[Cycle-Eaters By The Battalion](#_CYCLE-EATERS_BY_THE)

[5.2 ...THERE'S STILL NO SUCH BEAST AS A TRUE INSTRUCTION
TIME](#_...THERE%27S_STILL_NO)

[170 Cycles In The Life Of A PC](#_170_CYCLES_IN)

[The Test Set-Up](#_THE_TEST_SET-UP)

[The Results](#_THE_RESULTS)

[Code Execution Isn't All That Exciting](#_CODE_EXECUTION_ISN%27T)

[The 8088 Really Does Coprocess](#_THE_8088_REALLY)

[When Does An Instruction Execute?](#_WHEN_DOES_AN)

[5.3 THE TRUE NATURE OF INSTRUCTION EXECUTION](#_THE_TRUE_NATURE)

[Variability](#_VARIABILITY)

[You Never Know Unless You Measure (In Context!)](#_YOU_NEVER_KNOW)

[The Longer The Better](#_THE_LONGER_THE)

[Odds And Ends](#_ODDS_AND_ENDS)

[5.4 BACK TO THE PROGRAMMING INTERFACE](#_BACK_TO_THE)

[C](#CH06)[HAPTER](#CH06)[6: THE 8088](#CH06)

[6.1 AN OVERVIEW OF THE 8088](#_AN_OVERVIEW_OF)

[6.2 RESOURCES OF THE 8088](#_RESOURCES_OF_THE)

[6.3 REGISTERS](#_REGISTERS)

[6.4 THE 8088'S REGISTER SET](#_THE_8088%27S_REGISTER)

[6.5 THE GENERAL-PURPOSE REGISTERS](#_THE_GENERAL-PURPOSE_REGISTERS)

[The AX Register](#_The_AX_register)

[The BX Register](#_The_BX_register)

[The CX Register](#_The_CX_register)

[The DX Register](#_The_DX_register)

[The SI Register](#_The_SI_register)

[The DI Register](#_The_DI_register)

[The BP Register](#_The_BP_register)

[The SP Register](#_The_SP_register)

[6.6 THE SEGMENT REGISTERS](#_THE_SEGMENT_REGISTERS)

[The CS Register](#_The_CS_register)

[The DS Register](#_The_DS_register)

[The ES Register](#_The_ES_register)

[The SS Register](#_The_SS_register)

[6.7 THE INSTRUCTION POINTER](#_THE_INSTRUCTION_POINTER)

[6.8 THE FLAGS REGISTER](#_THE_FLAGS_REGISTER)

[The Carry Flag (CF)](#_The_Carry_flag)

[The Parity Flag (PF)](#_The_Parity_flag)

[The Auxiliary Carry Flag (AF)](#_The_Auxiliary_Carry)

[The Zero Flag (ZF)](#_The_Zero_flag)

[The Sign Flag (SF)](#_The_Sign_flag)

[The Overflow Flag (OF)](#_The_Overflow_flag)

[The Interrupt Flag (IF)](#_The_Interrupt_flag)

[The Direction Flag (DF)](#_The_Direction_flag)

[The Trap Flag (TF)](#_The_Trap_flag)

[6.9 THERE'S MORE TO LIFE THAN REGISTERS](#_THERE%27S_MORE_TO)

[C](#_Chapter_7:_)[HAPTER](#_Chapter_7:_)[7: MEMORY
ADDRESSING](#_Chapter_7:_)

[7.1 DEFINITIONS](#_DEFINITIONS)

[Square Brackets Mean Memory Addressing](#_SQUARE_BRACKETS_MEAN)

[7.2 THE MEMORY ARCHITECTURE OF THE 8088](#_THE_MEMORY_ARCHITECTURE)

[7.3 SEGMENTS AND OFFSETS](#_SEGMENTS_AND_OFFSETS)

[Segment:Offset Pairs Aren't Unique](#_SEGMENT:OFFSET_PAIRS_AREN%27T)

[Good News And Bad News](#_GOOD_NEWS_AND)

[More Good News](#_MORE_GOOD_NEWS)

[Notes on Optimization](#_NOTES_ON_OPTIMIZATION)

[A Final Word On Segment:Offset Addressing](#_A_FINAL_WORD)

[7.4 SEGMENT HANDLING](#_SEGMENT_HANDLING)

[What Can You Do With Segment Registers? Not Much](#_WHAT_CAN_YOU)

[Using Segment Registers For Temporary
Storage](#_USING_SEGMENT_REGISTERS)

[Setting And Copying Segment Registers](#_SETTING_AND_COPYING)

[Loading 20-bit Pointers With lds And les](#_LOADING_20-BIT_POINTERS)

[Loading Doublewords With les](#_LOADING_DOUBLEWORDS_WITH)

[Segment:Offset And Byte Ordering In Memory](#_SEGMENT:OFFSET_AND_BYTE)

[Loading SS](#_LOADING_SS)

[Extracting Segment Values With The seg
Directive](#_EXTRACTING_SEGMENT_VALUES)

[Joining Segments](#_JOINING_SEGMENTS)

[Segment Override Prefixes](#_SEGMENT_OVERRIDE_PREFIXES)

[assume And Segment Override Prefixes](#_assume_AND_SEGMENT)

[7.5 OFFSET HANDLING](#_OFFSET_HANDLING)

[Loading Offsets](#_LOADING_OFFSETS)

[7.6 *MOD-REG-RM* ADDRESSING](#_mod-reg-rm_ADDRESSING)

[What's *mod-reg-rm* Addressing Good
For?](#_WHAT%27S_mod-reg-rm_ADDRESSING)

[Displacements And Sign-Extension](#_DISPLACEMENTS_AND_SIGN-EXTENSION)

[Naming The *mod-reg-rm* Addressing Modes](#_NAMING_THE_mod-reg-rm)

[Direct Addressing](#_DIRECT_ADDRESSING)

[Miscellaneous Information About Memory
Addressing](#_MISCELLANEOUS_INFORMATION_ABOUT)

[*mod-reg-rm* Addressing: The Dark Side](#_mod-reg-rm_ADDRESSING:_)

[Why Memory Accesses Are Slow](#_WHY_MEMORY_ACCESSES)

[Some *mod-reg-rm* Memory Accesses Are Slower Than
Others](#_SOME_mod-reg-rm_MEMORY)

[Performance Implications Of Effective Address
Calculations](#_PERFORMANCE_IMPLICATIONS_OF)

[*mod-reg-rm* Addressing: Slow, But Not Quite As Slow As You
Think](#_mod-reg-rm_ADDRESSING:_)

[The Importance Of Addressing Well](#_THE_IMPORTANCE_OF)

[The 8088 Is Faster At Memory Address Calculations Than You
Are](#_THE_8088_IS)

[Calculating Effective Addresses With
lea](#_CALCULATING_EFFECTIVE_ADDRESSES)

[Offset Wrapping At The Ends Of Segments](#_OFFSET_WRAPPING_AT)

[7.7 NON-*MOD-REG-RM* MEMORY
ADDRESSING](#_NON-mod-reg-rm_MEMORY_ADDRESSING)

[Special Forms Of Common Instructions](#_SPECIAL_FORMS_OF)

[The String Instructions](#_THE_STRING_INSTRUCTIONS)

[Immediate Addressing](#_IMMEDIATE_ADDRESSING)

[Sign-Extension Of Immediate Operands](#_SIGN-EXTENSION_OF_IMMEDIATE)

[mov Doesn't Sign-Extend Immediate
Operands](#_mov_DOESN%27T_SIGN-EXTEND)

[Don't mov Immediate Operands To Memory If You Can Help
It](#_DON%27T_mov_IMMEDIATE)

[Stack Addressing](#_STACK_ADDRESSING)

[An Example Of Avoiding push And pop](#_AN_EXAMPLE_OF)

[Miscellaneous Notes About Stack
Addressing](#_MISCELLANEOUS_NOTES_ABOUT)

[Stack Frames](#_STACK_FRAMES)

[When Stack Frames Are Useful](#_WHEN_STACK_FRAMES)

[Tips On Stack Frames](#_TIPS_ON_STACK)

[Stack Frames Are Often In DS](#_STACK_FRAMES_ARE)

[Use BP As A Normal Register If You Must](#_USE_BP_AS)

[The Many Ways Of Specifying *mod-reg-rm* Addressing](#_THE_MANY_WAYS)

[xlat](#_xlat)

[Memory Is Cheap: You Could Look It Up](#_MEMORY_IS_CHEAP:)

[Five Ways To Double Bits](#_FIVE_WAYS_TO)

[Table Look-Ups To The Rescue](#_TABLE_LOOK-UPS_TO)

[There Are Many Ways To Approach Any Task](#_THERE_ARE_MANY)

[7.8 INITIALIZING MEMORY](#_INITIALIZING_MEMORY)

[7.9 A BRIEF NOTE ON I/O ADDRESSING](#_A_BRIEF_NOTE)

[Video Programming And I/O](#_VIDEO_PROGRAMMING_AND)

[Avoid Memory!](#_AVOID_MEMORY%21)

[C](#_Chapter_8:_)[HAPTER](#_Chapter_8:_)[8: STRANGE FRUIT OF THE
8080](#_Chapter_8:_)

[8.1 THE 8080 LEGACY](#_THE_8080_LEGACY)

[More Than A Passing Resemblance](#_MORE_THAN_A)

[8.2 ACCUMULATOR-SPECIFIC
INSTRUCTIONS](#_ACCUMULATOR-SPECIFIC_INSTRUCTIONS)

[Accumulator-Specific Direct-Addressing
Instructions](#_ACCUMULATOR-SPECIFIC_DIRECT-ADDRESS)

[Looks Aren't Everything](#_LOOKS_AREN%27T_EVERYTHING)

[How Fast Are They?](#_HOW_FAST_ARE)

[When Should You Use Them?](#_WHEN_SHOULD_YOU)

[Accumulator-Specific Immediate-Operand
Instructions](#_ACCUMULATOR-SPECIFIC_IMMEDIATE-OPER)

[An Accumulator-Specific Example](#_AN_ACCUMULATOR-SPECIFIC_EXAMPLE)

[Other Accumulator-Specific
Instructions](#_OTHER_ACCUMULATOR-SPECIFIC_INSTRUCT)

[The Accumulator-Specific Version Of
Test](#_THE_ACCUMULATOR-SPECIFIC_VERSION)

[The AX-Specific Version Of xchg](#_THE_AX-SPECIFIC_VERSION)

[8.3 PUSHING AND POPPING THE 8080 FLAGS](#_PUSHING_AND_POPPING)

[lahf And sahf: An Example](#_lahf_AND_sahf:)

[8.4 A BRIEF DIGRESSION ON OPTIMIZATION](#_A_BRIEF_DIGRESSION)

[Onward Through The Instruction Set](#_ONWARD_THROUGH_THE)

[C](#_Chapter_9:_)[HAPTER](#_Chapter_9:_)[9: AROUND AND ABOUT THE
INSTRUCTION SET](#_Chapter_9:_)

[9.1 SHORTCUTS FOR HANDLING ZERO AND
CONSTANTS](#_SHORTCUTS_FOR_HANDLING)

[Making Zero](#_MAKING_ZERO)

[Initializing Constants From The
Registers](#_INITIALIZING_CONSTANTS_FROM)

[Initializing Two Bytes With A Single Mov](#_INITIALIZING_TWO_BYTES)

[More Fun With Zero](#_MORE_FUN_WITH)

[9.2 inc AND dec](#_inc_AND_dec)

[Using 16-Bit inc And dec Instructions For 8-Bit
Operations](#_USING_16-BIT_inc)

[How inc And add (And dec And sub) Differ — And Why](#_HOW_inc_AND)

[9.3 CARRYING RESULTS ALONG IN A FLAG](#_CARRYING_RESULTS_ALONG)

[9.4 BYTE-TO-WORD AND WORD-TO-DOUBLEWORD
CONVERSION](#_BYTE-TO-WORD_AND_WORD-TO-DOUBLEWORD)

[9.5 xchg IS HANDY WHEN REGISTERS ARE TIGHT](#_xchg_IS_HANDY)

[9.6 DESTINATION: REGISTER](#_DESTINATION:__REGISTER)

[9.7 neg AND not](#_neg_AND_not)

[9.8 ROTATES AND SHIFTS](#C98)

[Shifting And Rotating Memory](#_SHIFTING_AND_ROTATING)

[Rotates](#_ROTATES)

[Shifts](#_SHIFTS)

[Signed Division With sar](#_SIGNED_DIVISION_WITH)

[Bit-Doubling Made Easy](#_BIT-DOUBLING_MADE_EASY)

[9.9 ASCII AND DECIMAL ADJUST](#_ASCII_AND_DECIMAL)

[daa, das, And Packed BCD Arithmetic](#_daa,_das,_AND)

[aam, aad, And Unpacked BCD Arithmetic](#_aam,_aad,_AND)

[Notes On mul And div](#_NOTES_ON_mul)

[aaa, aas, And Decimal ASCII Arithmetic](#_aaa,_aas,_AND)

[9.10 MNEMONICS THAT COVER MULTIPLE
INSTRUCTIONS](#_MNEMONICS_THAT_COVER)

[On To The String Instructions](#_ON_TO_THE)

[C](#_Chapter_10:_)[HAPTER](#_Chapter_10:_)[10: STRING INSTRUCTIONS: THE
MAGIC ELIXIR](#_Chapter_10:_)

[10.1 A QUICK TOUR OF THE STRING INSTRUCTIONS](#_A_QUICK_TOUR)

[Reading Memory: lods](#_READING_MEMORY:_)

[Writing Memory: stos](#_WRITING_MEMORY:_)

[Moving Memory: movs](#_MOVING_MEMORY:_)

[Scanning Memory: scas](#_SCANNING_MEMORY:_)

[Notes On Loading Segments For String Iinstructions](#_NOTES_ON_LOADING)

[Comparing Memory: cmps](#_COMPARING_MEMORY:_)

[10.2 HITHER AND YON WITH THE STRING INSTRUCTIONS](#_HITHER_AND_YON)

[Data Size, Advancing Pointers, And The Direction
Flag](#_DATA_SIZE,_ADVANCING)

[The rep Prefix](#_THE_rep_PREFIX)

[rep = No Iinstruction Fetching + No Branching](#_rep_=_NO)

[repz And repnz](#_repz_AND_repnz)

[rep Is A Prefix, Not An Instruction](#_rep_IS_A)

[Of Counters And Flags](#_OF_COUNTERS_AND)

[Of Data Size And Counters](#_OF_DATA_SIZE)

[Pointing Back To The Last Element](#_POINTING_BACK)

[Words Of Caution](#_WORDS_OF_CAUTION)

[Segment Overrides: Sometimes You Can, Sometimes You
Can't](#_SEGMENT_OVERRIDES:_)

[The Good And The Bad Of Segment Overrides](#_THE_GOOD_AND)

[...Leave ES And/Or DS Set For As Long As
Possible](#_...LEAVE_ES_AND/OR)

[rep And Segment Prefixes Don't Mix](#_rep_AND_SEGMENT)

[On To String Instruction Applications](#_ON_TO_STRING)

[C](#_Chapter_11:_)[HAPTER](#_Chapter_11:_)[11: STRING INSTRUCTION
APPLICATIONS](#_Chapter_11:_)

[11.1 STRING HANDLING WITH lods AND stos](#_STRING_HANDLING_WITH)

[11.2 BLOCK HANDLING WITH movs](#_BLOCK_HANDLING_WITH)

[11.3 SEARCHING WITH scas](#_SEARCHING_WITH_scas)

[scas And Zero-Terminated Strings](#_scas_AND_ZERO-TERMINATED)

[More On scas And Zero-Terminated Strings](#_MORE_ON_scas)

[Using Repeated scasw On Byte-Sized Data](#_USING_REPEATED_scasw)

[scas And Look-Up Tables](#_scas_AND_LOOK-UP)

[Consider Your Options](#_CONSIDER_YOUR_OPTIONS)

[11.4 COMPARING MEMORY TO MEMORY WITH cmps](#_COMPARING_MEMORY_TO)

[String Searching](#_STRING_SEARCHING)

[cmps Without rep](#_cmps_WITHOUT_rep)

[11.5 A NOTE ABOUT RETURNING VALUES](#_A_NOTE_ABOUT)

[11.6 PUTTING STRING INSTRUCTIONS TO WORK IN UNLIKELY
PLACES](#_PUTTING_STRING_INSTRUCTIONS)

[Animation Basics](#_ANIMATION_BASICS)

[String Instruction-Based
Animation](#_STRING_INSTRUCTION-BASED_ANIMATION)

[Notes On The Animation Implementations](#_NOTES_ON_THE_1)

[11.7 A NOTE ON HANDLING BLOCKS LARGER THAN 64 K BYTES](#_A_NOTE_ON)

[Conclusion](#_CONCLUSION)

[C](#_Chapter_12:_)[HAPTER](#_Chapter_12:_)[12: DON'T
JUMP!](#_Chapter_12:_)

[12.1 HOW SLOW IS IT?](#_HOW_SLOW_IS)

[12.2 BRANCHING AND CALCULATION OF THE TARGET
ADDRESS](#_BRANCHING_AND_CALCULATION)

[12.3 BRANCHING AND THE PREFETCH QUEUE](#_BRANCHING_AND_THE)

[The Prefetch Queue Empties When You Branch](#_THE_PREFETCH_QUEUE_1)

[Branching Instructions Do Prefetch](#_BRANCHING_INSTRUCTIONS_DO)

[12.4 BRANCHING AND THE SECOND BYTE OF THE BRANCHED-TO
INSTRUCTION](#C124)

[Don't Jump!](#_DON%27T_JUMP%21)

[Now That We Know Why Not To Branch...](#_NOW_THAT_WE)

[C](#_Chapter_13:_)[HAPTER](#_Chapter_13:_)[13:
NOT-BRANCHING](#_Chapter_13:_)

[13.1 THINK FUNCTIONALLY](#_THINK_FUNCTIONALLY)

[13.2 rep: LOOPING WITHOUT BRANCHING](#_rep:__LOOPING)

[13.3 LOOK-UP TABLES: CALCULATING WITHOUT BRANCHING](#_LOOK-UP_TABLES:_)

[13.4 TAKE THE BRANCH LESS TRAVELLED BY](#_TAKE_THE_BRANCH)

[Put The Load On The Unimportant Case](#_PUT_THE_LOAD)

[13.5 YES, VIRGINIA, THERE IS A FASTER 32-BIT
NEGATE!](#_YES,_VIRGINIA,_THERE)

[How 32-Bit Negation Works](#_HOW_32-BIT_NEGATION)

[How Fast 32-Bit Negation Works](#_HOW_FAST_32-BIT)

[13.6 ARRANGE YOUR CODE TO ELIMINATE BRANCHES](#_ARRANGE_YOUR_CODE)

[Preloading The Less Common Case](#_PRELOADING_THE_LESS)

[Use The Carry Flag To Replace Some Branches](#_USE_THE_CARRY)

[Never Use Two Jumps When One Will Do](#_NEVER_USE_TWO)

[Jump To The Land Of No Return](#_JUMP_TO_THE)

[Don't Be Afraid To Duplicate Code](#_DON%27T_BE_AFRAID)

[Inside Loops Is Where Branches Really Hurt](#_INSIDE_LOOPS_IS)

[Two Loops Can Be Better Than One](#_TWO_LOOPS_CAN)

[Make Up Your Mind Once And For All](#_MAKE_UP_YOUR)

[Don't Come Calling](#_DON%27T_COME_CALLING)

[Smaller Isn't *Always* Better](#_SMALLER_ISN%27T_ALWAYS)

[13.7 loop MAY NOT BE BAD, BUT LORD KNOWS IT'S NOT GOOD: IN-LINE
CODE](#_loop_MAY_NOT)

[Branched-To In-Line Code: Flexibility Needed And
Found](#_BRANCHED-TO_IN-LINE_CODE:)

[Partial In-Line Code](#_PARTIAL_IN-LINE_CODE)

[Partial In-Line Code: Limitations And
Workarounds](#_PARTIAL_IN-LINE_CODE:)

[Partial In-Line Code And Strings: A Good
Match](#_PARTIAL_IN-LINE_CODE_1)

[Labels And In-Line Code](#_LABELS_AND_IN-LINE)

[13.8 A NOTE ON SELF-MODIFYING CODE](#C138)

[Conclusion](#_CONCLUSION_1)

[C](#_Chapter_14:_)[HAPTER](#_Chapter_14:_)[14: IF YOU MUST
BRANCH...](#_Chapter_14:_)

[14.1 DON'T GO FAR](#_DON%27T_GO_FAR)

[How To Avoid Far Branches](#_HOW_TO_AVOID)

[Odds And Ends On Branching Far](#_ODDS_AND_ENDS_1)

[14.2 REPLACING call AND ret WITH jmp](#_REPLACING_call_AND)

[Flexibility A*d Infinitum*](#_FLEXIBILITY_AD_INFINITUM)

[Tinkering With The Stack In A Subroutine](#_TINKERING_WITH_THE)

[14.3 USE int ONLY WHEN YOU MUST](#_14.3_USE_int)

[Beware Of Letting Dos Do The Work](#_BEWARE_OF_LETTING)

[14.4 FORWARD REFERENCES CAN WASTE TIME AND
SPACE](#_FORWARD_REFERENCES_CAN)

[The Right Assembler Can Help](#_THE_RIGHT_ASSEMBLER)

[14.5 SAVING SPACE WITH BRANCHES](#_SAVING_SPACE_WITH)

[Multiple Entry Points](#_MULTIPLE_ENTRY_POINTS)

[A Brief Zen Exercise In Branching (And Not-Branching)](#_A_BRIEF_ZEN)

[14.6 DOUBLE-DUTY TESTS](#_DOUBLE-DUTY_TESTS)

[Using Loop Counters As Indexes](#_USING_LOOP_COUNTERS)

[14.7 THE LOOPING INSTRUCTIONS](#_THE_LOOPING_INSTRUCTIONS)

[loopz And loopnz](#_loopz_AND_loopnz)

[How You Loop Matters More Than You Might Think](#_HOW_YOU_LOOP)

[14.8 ONLY jcxz CAN TEST AND BRANCH IN A SINGLE BOUND](#_ONLY_jcxz_CAN)

[14.9 JUMP AND CALL TABLES](#_JUMP_AND_CALL)

[Partial Jump Tables](#_PARTIAL_JUMP_TABLES)

[Generating Jump Table Indexes](#_GENERATING_JUMP_TABLE)

[Jump Tables, Macros, And Branched-To In-Line
Code](#_JUMP_TABLES,_MACROS,)

[14.10 FORWARD REFERENCES REAR THEIR COLLECTIVE UGLY HEAD ONCE
MORE](#_FORWARD_REFERENCES_REAR)

[Still And All...Don't Jump!](#_STILL_AND_ALL...DON%27T)

[This Concludes Our Tour Of The 8088's Instruction
Set](#_THIS_CONCLUDES_OUR)

\

[C](#_Chapter_15:_)[HAPTER](#_Chapter_15:_)[15: OTHER
PROCESSORS](#_Chapter_15:_)

[15.1 WHY OPTIMIZE FOR THE 8088?](#_WHY_OPTIMIZE_FOR)

[15.2 WHICH PROCESSORS MATTER?](#_WHICH_PROCESSORS_MATTER?)

[The 80286 And The 80386](#_THE_80286_AND)

[15.3 THINGS MOTHER NEVER TOLD YOU, PART II](#_THINGS_MOTHER_NEVER)

[System Wait States](#_SYSTEM_WAIT_STATES)

[Data Alignment](#_DATA_ALIGNMENT)

[Code Alignment](#_CODE_ALIGNMENT)

[Alignment And The 80386](#_ALIGNMENT_AND_THE)

[Alignment And The Stack](#_ALIGNMENT_AND_THE_1)

[The DRAM Refresh Cycle-Eater: Still An Act Of God](#_THE_DRAM_REFRESH)

[The Display Adapter Cycle-Eater](#_THE_DISPLAY_ADAPTER_1)

[15.4 NEW INSTRUCTIONS AND FEATURES:](#_NEW_INSTRUCTIONS_AND)

[New Instructions And Features: The 80286](#_NEW_INSTRUCTIONS_AND_1)

[New Instructions And Features: The 80386](#_NEW_INSTRUCTIONS_AND_2)

[15.5 OPTIMIZATION RULES: THE MORE THINGS
CHANGE...](#_OPTIMIZATION_RULES:_)

[Detailed Optimization](#_DETAILED_OPTIMIZATION)

[Don't Sweat The Details](#_DON%27T_SWEAT_THE)

[15.6 popf AND THE 80286](#_popf_AND_THE)

[15.7 COPROCESSORS AND PERIPHERALS](#_COPROCESSORS_AND_PERIPHERALS)

[A Brief Note On The 8087](#_A_BRIEF_NOTE_1)

[Conclusion](#_CONCLUSION_2)

[C](#_Chapter_16:_)[HAPTER](#_Chapter_16:_)[16: ONWARD TO THE FLEXIBLE
MIND](#_Chapter_16:_)

[16.1 A TASTE OF WHAT YOU'VE LEARNED](#_A_TASTE_OF)

[16.2 ZENNING](#_ZENNING)

[16.3 KNOWLEDGE AND BEYOND](#_KNOWLEDGE_AND_BEYOND)

[LISTINGS INDEX](#_LISTINGS_INDEX)

[APPENDICES](#_APPENDIX_A:_8086/8088)

[APPENDIX A: AN 8088 INSTRUCTION SET REFERENCE](#_APPENDIX_A:_8086/8088)

[APPENDIX B: ASCII TABLE AND PC CHARACTER SET](#_Appendix_B:_)

[INDEX](#ZENINDX)

\

