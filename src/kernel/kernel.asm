;******************************************************************************
; kernel.asm
;
; Kernel
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
#include "src/includes/equates.inc"
#include "exp/BIOS.exp"
#include "exp/sysvars.exp"

		.ORG	KRN_START
;		; Clean sysvars (not the ACIA, because they are in use already)
;		ld		hl, 0
;		ld		a, 0
;		ld		(secs_per_clus), a
;		ld		(secs_per_fat), hl
;		ld		(num_fats), a
;		ld		(reserv_secs), hl
;		ld		(clus2secnum), hl
;		ld		(root_dir_start), hl
;		ld		(root_dir_sectors), hl
;		ld		(cur_dir_start), hl
;		ld		(file_attributes), a
krn_welcome:
		; Kernel start up messages
		ld		hl, msg_dzos			; dzOS welcome message
		call	F_KRN_WRSTR
		ld		hl, dzos_version		; dzOS version
		call	F_KRN_WRSTR
;		; output 1 empty line
;		ld		b, 1
;		call	F_KRN_EMPTYLINES

		ld		hl, msg_bios_version	; BIOS version
		call	F_KRN_WRSTR
		ld		hl, msg_krn_version		; Kernel version
		call	F_KRN_WRSTR

		; output 2 empty lines
		ld		b, 2
		call	F_KRN_EMPTYLINES

		; Initialise CF card reader
		ld		hl, krn_msg_cf_init
		call	F_KRN_WRSTR
		call	F_BIOS_CF_INIT
		cp		$FF
		jp		z, noCFdrive
;		ld		hl, krn_msg_OK
;		call	F_KRN_WRSTR
;		ld		hl, krn_msg_cf_fat16ver
;		call	F_KRN_WRSTR
		call	F_KRN_F16_READBOOTSEC	; read CF Boot Sector
		ld		hl, krn_msg_clos_sqbracket
		call	F_KRN_WRSTR

		; Check FAT's partition state is FF FF
		call	F_KRN_F16_CHK_PARTSTATE
copyjmpblks:
		; Copy BIOS Jumpblocks from ROM to RAM
		ld		hl, krn_msg_cpybiosjblks
		call	F_KRN_WRSTR
		ld		hl, BIOS_JBLK_START			; pointer to address of start of BIOS Jumpblocks in ROM
		ld		de, BIOS_JBLK_COPY_START	; pointer to address of start of BIOS Jumpblocks in RAM
		ld		bc, 256						; jumpblocks are 256 bytes max.
		ldir								; copy from ROM to RAM
		ld		hl, krn_msg_OK
		call	F_KRN_WRSTR
		; Copy Kernel Jumpblocks from ROM to RAM
		ld		hl, krn_msg_cpykrnjblks
		call	F_KRN_WRSTR
		ld		hl, KRN_JBLK_START			; pointer to address of start of Kernel Jumpblocks in ROM
		ld		de, KRN_JBLK_COPY_START		; pointer to address of start of Kernel Jumpblocks in RAM
		ld		bc, 256						; jumpblocks are 256 bytes max.
		ldir								; copy from ROM to RAM
		ld		hl, krn_msg_OK
		call	F_KRN_WRSTR

		; Show Free available RAM
		ld		hl, krn_msg_ramsize
		call	F_KRN_WRSTR

		ld		hl, ram_end_addr + 1		; load MSB
		ld		a, (hl)						; 	into A
		cp		$7F							; is it 0x7F? (i.e. 0x7FFF = 32KB)
		jp		z, ram_is_32kb
ram_is_64kb:
		ld		hl, krn_msg_ramsize_64kb
		call	F_KRN_WRSTR
		jp		ramsizeprinted
ram_is_32kb:
		ld		hl, krn_msg_ramsize_32kb
		call	F_KRN_WRSTR
ramsizeprinted:
;		; output 1 empty line
;		ld		b, 1
;		call	F_KRN_EMPTYLINES

		jp		CLI_START				; transfer control to CLI
noCFdrive:
		ld		hl, krn_msg_notfound
		call	F_KRN_WRSTR
		jp		copyjmpblks

;==============================================================================
; Kernel Modules
;==============================================================================
#include "src/kernel/kernel.string.asm"
#include "src/kernel/kernel.mem.asm"
#include "src/kernel/kernel.conv.asm"
#include "src/kernel/kernel.math.asm"
#include "src/kernel/kernel.fat16.asm"
;==============================================================================
; Messages
;==============================================================================
msg_krn_version:
		.BYTE	CR, LF
		.BYTE	"Kernel v1.0.0", 0
msg_dzos:
		.BYTE	CR, LF
		.BYTE	"#####   ######   ####    ####  ", CR, LF
		.BYTE	"##  ##     ##   ##  ##  ##     ", CR, LF
		.BYTE	"##  ##    ##    ##  ##   ####  ", CR, LF
		.BYTE	"##  ##   ##     ##  ##      ## ", CR, LF
		.BYTE	"#####   ######   ####    ####  ", 0
krn_msg_cf_init:
		.BYTE	"....Initialising CompactFlash reader [ ", 0
krn_msg_cf_fat16ver:
		.BYTE	"FAT16 implementation v1.0 - No directories supported!", CR, LF, 0
krn_msg_cpybiosjblks:
		.BYTE	CR, LF
		.BYTE	"....Copying BIOS Jumblocks to RAM ", 0
krn_msg_cpykrnjblks:
		.BYTE	"....Copying Kernel Jumblocks to RAM ", 0
krn_msg_ramsize:
		.BYTE	"....Detecting RAM size ", 0
krn_msg_ramsize_32kb:
		.BYTE	"[ 32 KB ]", CR, LF, 0
krn_msg_ramsize_64kb:
		.BYTE	"[ 64 KB ]", CR, LF, 0
krn_msg_OK:
		.BYTE	"[ OK ]", CR, LF, 0
krn_msg_clos_sqbracket:
		.BYTE	" ]", 0
krn_msg_notfound:
		.BYTE	" Not Found! ]", 0

		.ORG	KRN_DZOS_VERSION
dzos_version:			.EXPORT		dzos_version
		.BYTE	"vYYYY.MM.DD.   ", 0
;==============================================================================
; END of CODE
;==============================================================================
    	.ORG	KRN_END
		        .BYTE	0
		.END