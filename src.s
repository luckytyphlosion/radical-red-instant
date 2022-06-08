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

	HandleWriteSector_SkipSaveSector30And31Patch equ 0x9498628
	HandleWriteSector_End equ 0x949862a

	save_write_to_flash_AddInSaveSector30And31Patch equ 0x80d9838
	save_write_to_flash_End equ 0x80d9854

	_call_via_r0 equ 0x081e3ba8

	gSaveDataBuffer equ 0x02039a38
	gDamagedSaveSectors equ 0x0300538c
	gLastKnownGoodSector equ 0x03005388
	gFirstSaveSector equ 0x03005380
	gPrevSaveCounter equ 0x03005384
	gSaveCounter equ 0x03005390

	Memset equ 0x081e5ed8
	Memcpy equ 0x081e5e78
	TryWriteSector equ 0x080d99d8

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

	.org HandleWriteSector_SkipSaveSector30And31Patch
	b HandleWriteSector_End

	.org save_write_to_flash_AddInSaveSector30And31Patch
	ldr r0, =SaveSector30And31AndCheckDamagedSectors|1
	bl _call_via_r0
	b save_write_to_flash_End
	.pool

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

// The following was compiled with this code using https://godbolt.org/
/*
#include <stdint.h>

typedef uint8_t   u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t    s8;
typedef int16_t  s16;
typedef int32_t  s32;
typedef int64_t  s64;

struct SaveSection
{
    u8 data[0xFF4];
    u16 id;
    u16 checksum;
    u32 security;
    u32 counter;
}; // size is 0x1000

extern struct SaveSection gSaveDataBuffer;
void* __attribute__((long_call)) Memset(void *dst, u8 pattern, u32 size);
void* __attribute__((long_call)) Memcpy(void *dst, const void *src, u32 size);
u8 __attribute__((long_call)) TryWriteSector(u8 sector, u8 *data);

extern u16 gFirstSaveSector;
extern u32 gPrevSaveCounter;
extern u16 gLastKnownGoodSector;
extern u32 gDamagedSaveSectors;
extern u32 gSaveCounter;

#define SECTOR_DATA_SIZE 0xFF0
#define SECTOR_FOOTER_SIZE 128
#define NUM_SECTORS_PER_SAVE_SLOT 14
#define FILE_SIGNATURE 0x08012025
#define gSaveBlockParasite 0x0203B174
#define parasiteSize 0xEC4
#define SAVE_STATUS_OK 1
#define SAVE_STATUS_ERROR 0xFF

u32 SaveSector30And31AndCheckDamagedSectors(void)
{
	u32 retVal = SAVE_STATUS_OK;
	struct SaveSection* saveBuffer = &gSaveDataBuffer;
	
	//Write sector 30
	Memset(saveBuffer, 0, sizeof(struct SaveSection));
	u32 startLoc = gSaveBlockParasite + parasiteSize;
	Memcpy(saveBuffer->data, (void*)(startLoc), SECTOR_DATA_SIZE);
	TryWriteSector(30, saveBuffer->data);

	//Write sector 31
	Memset(saveBuffer, 0, sizeof(struct SaveSection));
	startLoc += SECTOR_DATA_SIZE;
	Memcpy(saveBuffer->data, (void*)(startLoc), SECTOR_DATA_SIZE);
	TryWriteSector(31, saveBuffer->data);

    if (gDamagedSaveSectors != 0) // skip the damaged sector.
    {
        retVal = SAVE_STATUS_ERROR;
        gFirstSaveSector = gLastKnownGoodSector;
        gSaveCounter = gPrevSaveCounter;
    }

    return retVal;
}
*/

SaveSector30And31AndCheckDamagedSectors:
        mov    r2, 128
        push    {r3, r4, r5, r6, r7, lr}
        ldr     r4, [@@L6]
        mov    r1, 0
        ldr     r7, [@@L6+4]
        lsl    r2, r2, 5
        mov    r0, r4
        bl      @@L8
        mov    r2, 255
        ldr     r1, [@@L6+8]
        lsl    r2, r2, 4
        ldr     r6, [@@L6+12]
        mov    r0, r4
        bl      @@L9
        mov    r1, r4
        ldr     r5, [@@L6+16]
        mov    r0, 30
        bl      @@L10
        mov    r2, 128
        mov    r1, 0
        lsl    r2, r2, 5
        mov    r0, r4
        bl      @@L8
        mov    r2, 255
        ldr     r1, [@@L6+20]
        lsl    r2, r2, 4
        mov    r0, r4
        bl      @@L9
        mov    r1, r4
        mov    r0, 31
        bl      @@L10
        ldr     r3, [@@L6+24]
        ldr     r3, [r3]
        mov    r0, 1
        cmp     r3, 0
        beq     @@L1
        ldr     r2, [@@L6+28]
        ldr     r3, [@@L6+32]
        ldrh    r2, [r2]
        strh    r2, [r3]
        ldr     r2, [@@L6+36]
        ldr     r3, [@@L6+40]
        ldr     r2, [r2]
        str     r2, [r3]
        add    r0, 254
@@L1:
        pop     {r3, r4, r5, r6, r7}
        pop     {r1}
        bx      r1
@@L6:
        .word   gSaveDataBuffer
        .word   Memset|1
        .word   33800248
        .word   Memcpy|1
        .word   TryWriteSector|1
        .word   33804328
        .word   gDamagedSaveSectors
        .word   gLastKnownGoodSector
        .word   gFirstSaveSector
        .word   gPrevSaveCounter
        .word   gSaveCounter
@@L10:
        bx      r5
@@L9:
        bx      r6
@@L8:
        bx      r7

	.pool

	.close
