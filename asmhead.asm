; haribote-os
; TAB=4

VBEMODE	EQU		0x104	; It couldn't work with 0x105 thus I use 320x200 for now

BOTPAK  EQU             0x00280000
DSKCAC  EQU             0x00100000
DSKCAC0 EQU             0x00080000

; BOOT_INFO
CYLS    EQU             0x0ff0
LEDS    EQU             0x0ff1
VMODE   EQU             0x0ff2
SCRNX   EQU             0x0ff4
SCRNY   EQU             0x0ff6
VRAM    EQU             0x0ff8

                ORG             0xc200

; Check the VBE existence
		MOV		AX, 0x9000
		MOV		ES, AX
		MOV		DI, 0
		MOV		AX, 0x4f00
		INT		0x10
		CMP		AX, 0x004f
		JNE		scrn320

; Check the VBE version
		MOV		AX, [ES:DI+4]
		CMP		AX, 0x0200
		JB		scrn320

; Get the video mode information

		MOV		CX, VBEMODE
		MOV		AX, 0x4f01
		INT		0x10
		CMP		AX, 0x004f
		JNE		scrn320

; Check the video mode information

		CMP		BYTE [ES:DI+0x19], 8
		JNE		scrn320
		CMP		BYTE [ES:DI+0x1b], 4
		JNE		scrn320
		MOV		AX, [ES:DI+0x00]
		AND		AX, 0x0080
		JZ		scrn320

; Swith the video mode

		MOV		BX, VBEMODE+0x4000
		MOV		AX, 0x4f02
		INT		0x10
		MOV		BYTE [VMODE], 8
		MOV		AX, [ES:DI+0x12]
		MOV		[SCRNX], AX
		MOV		AX, [ES:DI+0x14]
		MOV		[SCRNY], AX
		MOV		EAX, [ES:DI+0x28]
		MOV		[VRAM], EAX
		JMP		keystatus

scrn320:
		MOV		AL, 0x13
		MOV		AH, 0x00
		INT		0x10
		MOV		BYTE [VMODE], 8
		MOV		WORD [SCRNX], 320
		MOV		WORD [SCRNY], 200
		MOV		DWORD [VRAM], 0x000a0000

keystatus:
		MOV		AH, 0x02
		INT		0x16
		MOV		[LEDS], AL

; Not to be interrupted PIC
                MOV             AL, 0xff
                OUT             0x21, AL
                NOP
                OUT             0xa1, AL

                CLI

                CALL    waitkbdout
                MOV             AL, 0xd1
                OUT             0x64, AL
                CALL    waitkbdout
                MOV             AL,0xdf
                OUT             0x60, AL
                CALL    waitkbdout

; Move to protected mode

                LGDT    [GDTR0]
                MOV             EAX, CR0
                AND             EAX, 0x7fffffff
                OR              EAX, 0x00000001
                MOV             CR0, EAX
                JMP             pipelineflush
pipelineflush:
                MOV             AX, 1 * 8
                MOV             DS, AX
                MOV             ES, AX
                MOV             FS, AX
                MOV             GS, AX
                MOV             SS, AX

; Transfer bootpack

                MOV		ESI, bootpack
		MOV		EDI, BOTPAK
		MOV		ECX, 512 * 1024 / 4
		CALL	memcpy

; Boot bootpack

		MOV		EBX, BOTPAK
		MOV		ECX, [EBX+16]
		ADD		ECX, 3
		SHR		ECX, 2
		JZ		skip
		MOV		ESI, [EBX+20]
		ADD		ESI, EBX
		MOV		EDI, [EBX+12]
		CALL	memcpy
skip:
		MOV		ESP, [EBX+12]
		JMP		DWORD 2 * 8:0x0000001b

waitkbdout:
		IN              AL, 0x64
		AND             AL, 0x02
		JNZ             waitkbdout
		RET

memcpy:
		MOV		EAX, [ESI]
		ADD		ESI, 4
		MOV		[EDI], EAX
		ADD		EDI, 4
		SUB		ECX, 1
		JNZ		memcpy
		RET

		ALIGNB	16
GDT0:
		RESB	8
		DW		0xffff, 0x0000, 0x9200, 0x00cf
		DW		0xffff, 0x0000, 0x9a28, 0x0047

		DW		0
GDTR0:
		DW		8 * 3 - 1
		DD		GDT0

		ALIGNB	16
bootpack:
