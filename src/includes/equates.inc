;******************************************************************************
; equates.asm
;
; General Equates (.EQU)
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
; I/O Mapping
;==============================================================================
IODEV_CFLASH			.EQU	10h				; CompactFlash

;==============================================================================
; Screen
;==============================================================================
CR						.EQU	$0D				; Carriage Return
LF						.EQU	$0A				; Line Feed
SPACE					.EQU	$20				; Space
;CLRSCR					.EQU	$0C				; Clear screen
DATESEP					.EQU	'/'				; Date separator
TIMESEP					.EQU	':'				; Time separator

;==============================================================================
; Special Keys
;==============================================================================
KEY_BACKSPACE			.EQU	$7F				; Backspace

;==============================================================================
; ROM positions
;==============================================================================
INITACIA_START			.EQU	0000h
INITACIA_END			.EQU	INITACIA_START + 255

BIOS_START				.EQU	0100h
BIOS_END				.EQU	BIOS_START + 319
BIOS_JBLK_START			.EQU	BIOS_END + 1
BIOS_JBLK_END			.EQU	BIOS_JBLK_START + 255

KRN_START				.EQU	BIOS_JBLK_END + 1
KRN_DZOS_VERSION		.EQU	KRN_START + 2752
KRN_END					.EQU	KRN_DZOS_VERSION + 15
KRN_JBLK_START			.EQU	KRN_END + 1
KRN_JBLK_END			.EQU	KRN_JBLK_START + 255

CLI_START				.EQU	KRN_JBLK_END + 1
CLI_END					.EQU	CLI_START + 1996

FREEROM_START			.EQU	CLI_END + 1
FREEROM_END				.EQU	$1FFF
FREEROM_SIZE			.EQU	FREEROM_END - FREEROM_START

;==============================================================================
; RAM positions
;==============================================================================
STACK_START				.EQU	$2000			; Top of the dastaZ80's Stack location
STACK_END				.EQU    $207F			; Bottom of the dastaZ80's Stack location

BIOS_JBLK_COPY_START	.EQU	$2080
BIOS_JBLK_COPY_END		.EQU	$217F
KRN_JBLK_COPY_START		.EQU	$2180
KRN_JBLK_COPY_END		.EQU	$227F

SYSVARS_START			.EQU	$2280
SYSVARS_END				.EQU	$237F

CF_BUFFER_START			.EQU	$2380
CF_BUFFER_END			.EQU	$257F

FREERAM_START			.EQU	$2580
;FREERAM_END				.EQU	$7FFF
;FREERAM_TOTAL			.EQU	FREERAM_END - FREERAM_START + 1

;==============================================================================
; CompactFlash
;==============================================================================
; Command Block Registers
CF_DATA					.EQU	IODEV_CFLASH + $00	; Data (Read/Write)
CF_ERROR				.EQU	IODEV_CFLASH + $01	; Error register (Read)
CF_FEAUTURES			.EQU	IODEV_CFLASH + $01	; Features (Write)
CF_SECTORCNT			.EQU	IODEV_CFLASH + $02	; Sector Count (Read/Write)
CF_SECTORNUM			.EQU	IODEV_CFLASH + $03	; Sector Number (Read/Write)
CF_CYL_LO				.EQU	IODEV_CFLASH + $04	; Cylinder Low (Read/Write)
CF_CYL_HI				.EQU	IODEV_CFLASH + $05	; Cylinder High (Read/Write)
CF_DRIVEHEAD			.EQU	IODEV_CFLASH + $06	; Drive/Head (Read/Write)
CF_STATUS				.EQU	IODEV_CFLASH + $07	; Status (Read)
CF_CMD					.EQU	IODEV_CFLASH + $07	; Command (Write)
CF_LBA0					.EQU	IODEV_CFLASH + $03	; LBA Bits 0-7 (Read/Write)
CF_LBA1					.EQU	IODEV_CFLASH + $04	; LBA Bits 8-15 (Read/Write)
CF_LBA2					.EQU	IODEV_CFLASH + $05	; LBA Bits 16-23 (Read/Write)
CF_LBA3					.EQU	IODEV_CFLASH + $06	; LBA Bits 24-27 (Read/Write)

; Commands
CF_CMD_SET_FEATURE		.EQU 	$0ef				; Set Features
CF_CMD_SET_FEAT_8BIT_ON	.EQU	$01					; Enable 8-bit data transfers
CF_CMD_READ_SECTOR		.EQU	$20					; Read Sector(s) (w/retry)
CF_CMD_WRITE_SECTOR		.EQU	$30					; Write Sector(s) (w/retry)
;CF_CMD_WRITE_SECTOR	.EQU	$3C					; Write Verify
													; similar to the Write Sectors command, 
													; except that each sector is verified 
													; immediately after being written.
CF_CMD_EXE_DRV_DIAGNOS	.EQU	$90					; Execute Drive Diagnostic

;==============================================================================
; ACIA Buffers
;==============================================================================
SER_BUFSIZE				.EQU	$3F
SER_FULLSIZE			.EQU	$30
SER_EMPTYSIZE			.EQU	5
serBuf					.EQU	SYSVARS_START
serInPtr				.EQU	serBuf + SER_BUFSIZE
serRdPtr				.EQU	serInPtr + 2
serBufUsed				.EQU	serRdPtr + 2
ACIA_BUFFERS_END		.EQU	serBufUsed + 1

		.END
