;******************************************************************************
; BIOS.asm
;
; BIOS (Basic Input/Output System)
; for dastaZ80's dzOS
; by David Asta (Jan 2018)
;
; Version 1.0.0
; Created on 03 Jan 2018
; Last Modification 03 Jan 2018
;******************************************************************************
; CHANGELOG
; 	-
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; This file is part of dzOS
; Copyright (C) 2017-2018 David Asta

; dzOS is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; dzOS is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with dzOS.  If not, see <http://www.gnu.org/licenses/>.
; -----------------------------------------------------------------------------

;==============================================================================
; Includes
;==============================================================================
#include "src/initACIA.asm"
;#include "src/includes/equates.inc"	; this include is already in initACIA.asm
#include "exp/sysvars.exp"

		.ORG	BIOS_START
;==============================================================================
; General Routines
;==============================================================================
F_BIOS_CBOOT:
; Cold Boot
;		LD		HL, STACK_END			; Bottom of the dastaZ80's Stack location
; 		^ included in initACIA.asm
		call	F_BIOS_WHAT_RAMSIZE		; determines if RAM is 32KB or 64KB
		call	F_BIOS_WBOOT			; Proceed as if in Warm Boot
		jp		KRN_START				; transfer control to Kernel
		ret
;------------------------------------------------------------------------------
F_BIOS_WBOOT:			.EXPORT			F_BIOS_WBOOT
; Warm Boot
		call	F_BIOS_WIPE_RAM			; wipe (with zeros) the entire RAM, except the Stack area
		call	F_BIOS_CLRSCR			; Clear screen
		ret
;------------------------------------------------------------------------------
F_BIOS_SYSHALT:			.EXPORT			F_BIOS_SYSHALT
; Halts the system
		di								; disable interrupts
		halt							; halt the computer
;==============================================================================
; RAM Routines
;==============================================================================
;------------------------------------------------------------------------------
F_BIOS_WHAT_RAMSIZE:
; Checks if the system is running with 32KB or 64KB of RAM
		; check for 32KB
		ld		hl, 8000h				; HL = pointer to 32KB + 1
		ld		(hl), 55h				; try to write a value in pointed memory address
		ld		a, (hl)					; read it back
		cp		55h						; and compare to be sure that the value was indeed written
		jp		nz, ram_is_32kb			; if value couldn't be written, then is 32KB
ram_is_64kb:
		ld		hl, $FFFF				; 0xFFFF = 65535 bytes = 64KB
		ld		(ram_end_addr), hl	; store value in sysvars.ram_size
		ret
ram_is_32kb:
		ld		hl, $7FFF				; 0x7FFF = 32767 bytes = 32KB
		ld		(ram_end_addr), hl	; store value in sysvars.ram_size
		ret
;------------------------------------------------------------------------------
F_BIOS_WIPE_RAM:
; Sets zeros (00h) in all RAM addresses after the SysVars area
		ld		hl, SYSVARS_END + 1		; start address to wipe
		ld		de, (ram_end_addr)		; end address to wipe
		ld		a, 0					; 00h is the value that will written in all RAM addresses
wiperam_loop:
		ld		(hl), a					; put register A content in address pointed by HL
		inc		hl						; increment pointer
		push	hl						; store HL value in Stack, because SBC destroys it
		sbc		hl, de					; substract DE from HL
		jr		z, wiperam_end			; if we reach the end position, jump out
		pop		hl						; restore HL
		jr		wiperam_loop			; no at end yet, continue loop
wiperam_end:
		pop		hl						; restore HL value from Stack
		ret
;==============================================================================
; BIOS Modules
;==============================================================================
#include "src/BIOS/BIOS.cf.asm"
#include "src/BIOS/BIOS.video.asm"

;==============================================================================
; Messages
;==============================================================================
msg_bios_version:				.EXPORT			msg_bios_version
		.BYTE	CR, LF
		.BYTE	"BIOS v1.0.0", 0
;==============================================================================
; END of CODE
;==============================================================================
		.ORG	BIOS_END
				.BYTE	0
		.END