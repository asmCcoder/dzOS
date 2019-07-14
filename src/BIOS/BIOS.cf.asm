;******************************************************************************
; BIOS.cf.asm
;
; BIOS' CompactFlash routines
; for dastaZ80's dzOS
; by David Asta (May 2019)
;
; Version 1.0.0
; Created on 08 May 2019
; Last Modification 08 May 2019
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
; CompactFlash Routines
;==============================================================================
;------------------------------------------------------------------------------
F_BIOS_CF_INIT:			.EXPORT		F_BIOS_CF_INIT
; Initialise CF IDE card
; Sets CF card to 8-bit data transfer mode
		; Loop until status register bit 7 (busy) is 0
		call	F_BIOS_CF_CONNECTED		; was the CF Drive connected at boot?
		cp		$FF						; is it FF (i.e. not connected)?
		ret		z						; yes, exit routine
		call	F_BIOS_CF_BUSY			; wait until CF is ready
		ld		a, CF_CMD_SET_FEAT_8BIT_ON	; mask for 8-bit mode enable
		out		(CF_FEAUTURES), a		; send mask to Features register
		call	F_BIOS_CF_BUSY			; wait until CF is ready
		ld		a, CF_CMD_SET_FEATURE	; mask for set feature command
		out		(CF_CMD), a				; send mask to Command register
		call	F_BIOS_CF_BUSY			; wait until CF is ready
		ret
;------------------------------------------------------------------------------
F_BIOS_CF_BUSY:			.EXPORT			F_BIOS_CF_BUSY
; Check CF busy bit (0=ready, 1=busy)
		in		a, (CF_STATUS)			; read status register
		and		10000000b				; mask busy bit
		jp		nz, F_BIOS_CF_BUSY		; if bit is set (i.e. is busy), loop again
		ret
;------------------------------------------------------------------------------
F_BIOS_CF_READ_SEC:		.EXPORT			F_BIOS_CF_READ_SEC
; Read a Sector (512 bytes) byte by byte from CF card 
; into CF_BUFFER_START in RAM
; IN <= E = sector address LBA 0 (bits 0-7)
;		D = sector address LBA 1 (bits 8-15)
;		C = sector address LBA 2 (bits 16-23)
;		B = sector address LBA 3 (bits 24-27)

		; set LBA addresses
		call	F_BIOS_CF_SET_LBA

		call	F_BIOS_CF_BUSY			; wait until CF is ready
		ld		a, CF_CMD_READ_SECTOR	; mask for Read Sector(s) (w/retry)
		out		(CF_CMD), a				; send mask to Command register
		call	F_BIOS_CF_BUSY			; wait until CF is ready
		ld		hl, CF_BUFFER_START		; Sector data will be stored at the CF buffer in RAM
		ld		b, 0h					; 256 words (512 bytes) will be read
cf_read_sector_loop:
		; as we loop 256 times, we need to read 2 bytes each time
		; to achieve 512 bytes in total
		; read 1st byte
		call	F_BIOS_CF_BUSY			; wait until CF is ready
		in		a, (CF_DATA)			; Read byte from Data
		ld		(hl), a					; read byte is stored in RAM
		inc		hl						; increment RAM pointer
		; read 2nd byte
		call	F_BIOS_CF_BUSY			; wait until CF is ready
		in		a, (CF_DATA)			; Read byte from Data
		ld		(hl), a					; read byte is stored in RAM
		inc		hl						; increment RAM pointer
		djnz	cf_read_sector_loop		; did B went back to 0 (i.e. 256 times)? No, continue loop
		ret								; yes, exit routine
;------------------------------------------------------------------------------
F_BIOS_CF_WRITE_SEC:	.EXPORT			F_BIOS_CF_WRITE_SEC
; Write a Sector (512 bytes) byte by byte from CF_BUFFER_START in RAM
; to the CF card
; IN <= E = sector address LBA 0 (bits 0-7)
;		D = sector address LBA 1 (bits 8-15)
;		C = sector address LBA 2 (bits 16-23)
;		B = sector address LBA 3 (bits 24-27)

		; set LBA addresses
		call	F_BIOS_CF_SET_LBA

		call	F_BIOS_CF_BUSY			; wait until CF is ready
		ld		a, CF_CMD_WRITE_SECTOR	; mask for Write Verify
		out		(CF_CMD), a				; send mask to Command register
		call	F_BIOS_CF_BUSY			; wait until CF is ready
		ld		hl, CF_BUFFER_START		; Sector data is stored in the CF buffer in RAM
		ld		b, 0h					; 256 words (512 bytes) will be written
cf_write_sector_loop:
		; as we loop 256 times, we need to write 2 bytes each time
		; to achieve 512 bytes in total
		; read 1st byte
		call	F_BIOS_CF_BUSY			; wait until CF is ready
		ld		a, (hl)					; read byte stored in RAM
		out		(CF_DATA), a			; Write byte to Data
		inc		hl						; increment RAM pointer
		; read 2nd byte
		call	F_BIOS_CF_BUSY			; wait until CF is ready
		ld		a, (hl)					; read byte stored in RAM
		out		(CF_DATA), a			; Write byte to Data
		inc		hl						; increment RAM pointer
		djnz	cf_write_sector_loop	; did B went back to 0 (i.e. 256 times)? No, continue loop
		ret								; yes, exit routine
;------------------------------------------------------------------------------
F_BIOS_CF_DIAGNOSDRV:	.EXPORT			F_BIOS_CF_DIAGNOSDRV
; Performs the internal diagnostic tests implemented by the drive
; A diagnostic code is returned upon completion in the Error Register:
; OUT => A = Diagnostic code
;	0x01	No Errors
;	0x02	Formatter Device Error
;	0x03	Sector Buffer Error
;	0x04	ECC Circuitry Error
;	0x05	Microprocessor Error
;	0x8X	Slave Failed
		ld		a, CF_CMD_EXE_DRV_DIAGNOS	; mask for Execute Drive Diagnostic
		out		(CF_CMD), a				; send mask to Command register
		call	F_BIOS_CF_BUSY			; wait until CF is ready
		in		a, (CF_ERROR)			; A = Error Code
		ret
;------------------------------------------------------------------------------
F_BIOS_CF_CONNECTED:		.EXPORT			F_BIOS_CF_CONNECTED
; Check CF busy bit (0=ready, 1=busy) for a maximum of 10 times
; if maximum reached, return FF in A to indicate timeout
		ld		b, 10					; retries counter
busyloop:
		dec		b						; retries counter - 1
		in		a, (CF_STATUS)			; read status register
		and		10000000b				; mask busy bit
		jp		z, endcheck				; if bit is set (i.e. is busy), loop again
		djnz	busyloop				; keep trying if 10 retries not done
		ld		a, $FF					; return FF in A to indicate timeout
endcheck:
		ret
;------------------------------------------------------------------------------
F_BIOS_CF_SET_LBA:
; Set sector count and LBA address
; IN <= E = sector address LBA 0 (bits 0-7)
;		D = sector address LBA 1 (bits 8-15)
;		C = sector address LBA 2 (bits 16-23)
;		B = sector address LBA 3 (bits 24-27)
		call	F_BIOS_CF_BUSY			; loop until CF card is ready
		
		ld		a, 1
		out		(CF_SECTORCNT), a		; 1 sector at at a time (512 bytes)
		call	F_BIOS_CF_BUSY			; loop until CF card is ready
		
		ld		a, e					; sector address LBA 0
		out		(CF_LBA0), a			; LBA Bits 0-7
		call	F_BIOS_CF_BUSY			; loop until CF card is ready
		
		ld		a, d					; sector address LBA 1
		out		(CF_LBA1), a			; LBA Bits 8-15
		call	F_BIOS_CF_BUSY			; loop until CF card is ready
		
		ld		a, c					; sector address LBA 2
		out		(CF_LBA2), a			; LBA Bits 16-23
		call	F_BIOS_CF_BUSY			; loop until CF card is ready

		ld		a, b					; sector address LBA 3
		and		0fh						; only bits 0 to 3 are LBA 3
		or		$e0						; mask to select as drive 0 (master)
		out		(CF_LBA3), a			; LBA Bits 24-27
		ret