// Copyright (c) 2021 luckytyphlosion
// 
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted.
// 
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
// REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
// INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
// OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
// PERFORMANCE OF THIS SOFTWARE.

	.gba
	.thumb

	INPUT_FILE equ "rr2_3a.gba"
	OUTPUT_FILE equ "rr2_3a_instant_text.gba"

	AddTextPrinterHookPatch equ 0x8002cfc
	RunTextPrinters equ 0x8002de8

	RenderFont equ 0x8002e7c
	CopyWindowToVram equ 0x8003f20
	sTextPrinters equ 0x2020034

	InstantHPBarsPatch1 equ 0x804a300
	InstantHPBarsPatch2 equ 0x804a360

	TurnStatChangeAnimOffPatch1 equ 0x9481cfc
	TurnStatChangeAnimOffPatch2 equ 0x9481ddc
	TurnStatChangeAnimOffPatch1ForcedAnimsIfStatement equ 0x9481d06

	BattleScript_Pausex20_PauseValue equ 0x81d89f2
	BattleScript_EffectStatUpAfterAtkCanceler_Pause0x20_PauseValue equ 0x81d6bb3

	atk12_waitmessage_ForcedFastMessagesPatch equ 0x9480f64
	atk12_waitmessage_EndMessageWait equ 0x9480f4c

	FREE_SPACE equ 0x8730000

	.open INPUT_FILE, OUTPUT_FILE, 0x8000000
	.org AddTextPrinterHookPatch
	b AddTextPrinterHook
AddTextPrinterHookReturn:

	.org RunTextPrinters
	ldr r0, =RunTextPrintersForInstantText|1
	bx r0
	.pool

AddTextPrinterHook:
	lsr r5, r1, 0x18
	cmp r5, 0
	beq AddTextPrinterHookReturn
	cmp r5, 0xff
	beq AddTextPrinterHookReturn
	mov r5, 1
	b AddTextPrinterHookReturn

	// partially based on https://github.com/luckytyphlosion/pokefirered/commit/5e8fee38e3438131c746b6bde327f1289750e7a5
	// but need to add `s32 toAdd_ = 32768` somewhere
	// toAdd = 32768
	.org InstantHPBarsPatch1
	mov r3, 1
	lsl r3, r3, 15
	str r3, [sp, 0x1c]

	// s32 toAdd_ = 32768
	.org InstantHPBarsPatch2
	nop
	nop
	mov r0, 1
	lsl r0, r0, 15

	.org TurnStatChangeAnimOffPatch1
	bne TurnStatChangeAnimOffPatch1ForcedAnimsIfStatement

	.org TurnStatChangeAnimOffPatch2
	.word 0x60020005 // changed from 0x60020007
	// the value itself is a bitfield of values which cause forced anims
	// game will perform (0x60020005 >> gBattlescriptCurrInstr[2]) << 0x1f
	// if the bit is set in the bitfield then branch will occur

	.org atk12_waitmessage_ForcedFastMessagesPatch
	b atk12_waitmessage_EndMessageWait

	.org BattleScript_Pausex20_PauseValue
	.byte 1

	.org BattleScript_EffectStatUpAfterAtkCanceler_Pause0x20_PauseValue
	.byte 0

	.org FREE_SPACE
// compiled from https://github.com/luckytyphlosion/pokefirered/commit/a27b8f1458d92b96ace70bd0e80d4e85b29701e9
RunTextPrintersForInstantText:
        push    {r4, r5, r6, r7, lr}
        mov     r7, r9
        mov     r6, r8
        push    {r6, r7}


        mov     r2, 0
@@L6:

        ldr     r5, =sTextPrinters
        lsl     r0, r2, 3
        add     r0, r0, r2
        lsl     r3, r0, 2
        add     r1, r3, r5
        ldrb    r0, [r1, 27]
        add     r2, r2, 1
        mov     r9, r2
        cmp     r0, 0
        beq     @@L5       

        mov     r0, 0
        mov     r8, r0
        add     r4, r1, 0
        add     r0, r5, 0
        add     r0, 16
        add     r5, r3, r0
@@L11:


        ldrb    r7, [r4, 28]

        add     r0, r4, 0
        bl      RenderFontHook
        lsl     r0, r0, 16
        lsr     r0, r0, 16
        add     r1, r0, 0

        ldrb    r6, [r4, 28]

        cmp     r0, 0
        bne     @@L12      

        ldr     r2, [r5]
        cmp     r2, 0
        beq     @@L10      

        add     r0, r4, 0
        mov     r1, 0
        mov lr, pc
		bx r2

        b       @@L10
@@L12:
        cmp     r0, 3
        bne     @@L15      

        ldr     r2, [r5]
        cmp     r2, 0
        beq     @@L16      

        add     r0, r4, 0
        mov     r1, 3
        mov lr, pc
		bx r2
@@L16:

        cmp     r7, 0
        bne     @@L5       
        cmp     r6, 0
        beq     @@L5       

        ldrb    r0, [r4, 4]
        mov     r1, 2
        bl      CopyWindowToVramHook

        b       @@L5

@@L15:
        cmp     r1, 1
        bne     @@L10      

        ldrb    r0, [r4, 4]
        mov     r1, 2
        bl      CopyWindowToVramHook

        mov     r0, 0
        strb    r0, [r4, 27]

        b       @@L5


@@L10:
        mov     r0, 1
        add     r8, r0
        ldr     r0, =1023
        cmp     r8, r0
        ble     @@L11      

@@L5:
        mov     r2, r9
        cmp     r2, 31
        ble     @@L6       

        pop     {r3, r4}
        mov     r8, r3
        mov     r9, r4
        pop     {r4, r5, r6, r7}
        pop     {r0}
        bx      r0

RenderFontHook:
	ldr r1, =RenderFont|1
	bx r1

CopyWindowToVramHook:
	ldr r2, =CopyWindowToVram|1
	bx r2

	.pool

	.close
