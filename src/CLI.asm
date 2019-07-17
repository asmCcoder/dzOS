;******************************************************************************
; CLI.asm
;
; Command-Line Interface
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
#include "exp/kernel.exp"
#include "exp/sysvars.exp"

;==============================================================================
; EQUates
;==============================================================================
LINESPERPAGE			.EQU	20		; 20 lines per page (for memdump)

;==============================================================================
; General Routines
;==============================================================================
		.ORG	CLI_START
cli_welcome:
		ld		hl, msg_cli_version		; CLI start up message
		call	F_KRN_WRSTR				; Output message
		; output 1 empty line
		ld		b, 1
		call 	F_KRN_EMPTYLINES

print_avail_ram:	; <<<<	ToDo - it doesn't work >>>>
; 		ld		hl, ram_end_addr
; 		ld		de, FREERAM_START
; 		sbc		hl, de
; 		; Needs to be converted from Hexadcimal to decimal first
; 		call	F_KRN_BIN2BCD6
; 		ex		de, hl					; HL = converted 6-digit BCD
; 		ld		de, buffer_pgm			; where the numbers in ASCII will be stored
; 		call	F_KRN_BCD2ASCII
; 		; Print each of the 6 digits
; 		ld		iy, buffer_pgm
; 		ld		a, (iy + 0)
; 		call	F_BIOS_CONOUT
; 		ld		a, (iy + 1)
; 		call	F_BIOS_CONOUT
; 		ld		a, (iy + 2)
; 		call	F_BIOS_CONOUT
; 		ld		a, (iy + 3)
; 		call	F_BIOS_CONOUT
; 		ld		a, (iy + 4)
; 		call	F_BIOS_CONOUT
; 		ld		a, (iy + 5)
; 		call	F_BIOS_CONOUT

cli_promptloop:
		call	F_CLI_CLRCLIBUFFS		; Clear buffers
		ld		hl, msg_prompt			; Prompt
		call	F_KRN_WRSTR				; Output message
		ld		hl, buffer_cmd			; address where commands are buffered

		; read and parse cmd
		call	F_CLI_READCMD
		call	F_CLI_PARSECMD
		jp		cli_promptloop
;------------------------------------------------------------------------------
F_CLI_READCMD:
; Read string containing a command and parameters
; Read characters from the Console into a memory buffer until RETURN is pressed.
; Parameters (identified by colon) are detected and stored in *parameters buffer*,
; meanwhile the command is store in *command buffer*.
readcmd_loop:
		call	F_KRN_RDCHARECHO		; read a character into A, with echo
		cp		SPACE					; was a SPACE?
		jp		z, was_param1			; test for 1st parameter entered
		cp		','						; was a comma?
		jp		z, was_param2			; test for 2nd parameter entered
		; test for special keys
;		cp		KEY_BACKSPACE			; was a backspace?
;		jp		z, was_backspace		; yes, don't add to buffer
;		cp		KEY_UP					; up arrow?
;		jp		z, no_buffer			; yes, don't add to buffer
;		cp		KEY_DOWN				; down arrow?
;		jp		z, no_buffer			; yes, don't add to buffer
;		cp		KEY_LEFT				; left arrow?
;		jp		z, no_buffer			; yes, don't add to buffer
;		cp		KEY_RIGHT				; right arrow?
;		jp		z, no_buffer			; yes, don't add to buffer

		cp		CR						; ENTER?
		jp		z, end_get_cmd			; yes, command was fully entered
		ld		(hl), a					; store character in buffer
		inc		hl						; buffer pointer + 1
no_buffer:
		jp		readcmd_loop			; don't add last entered char to buffer
		ret
;was_backspace:	
loop_get_cmd:	
		jp		readcmd_loop			; read another character
; Use this code if want to separate parameters by space instead of comma
; was_param:
; 		ld		a, (buffer_parm1)
; 		cp		00h						; is buffer area empty (=00h)?
; 		jp		z, add_value1			; yes, add character to buffer area
; 		ld		a, (buffer_parm2)
; 		cp		00h						; is buffer area empty (=00h)?
; 		jp		z, add_value2			; yes, add character to buffer area
; 		jp		readcmd_loop			; read next character
was_param1:
;add_value1:
		ld		hl, buffer_parm1
		jp		readcmd_loop
was_param2:
;add_value2:
		ld		hl, buffer_parm2
		jp		readcmd_loop
end_get_cmd:
		ret
;------------------------------------------------------------------------------
F_CLI_PARSECMD:
; Parse command
; Parses entered command and calls related subroutine.
		ld		hl, buffer_cmd
		ld		a, (hl)
		cp		00h						; just an ENTER?
		jp		z, cli_promptloop		; show prompt again
		;search command "test"
		ld		de, _CMD_TEST
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_TEST			; yes, then execute the command
		;search command "memdump"
		ld		de, _CMD_MEMDUMP
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_MEMDUMP		; yes, then execute the command
		;search command "ld" (list directory)
		ld		de, _CMD_LD
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_LD			; yes, then execute the command
;		;search command "cd" (change directory)
;		ld		de, _CMD_CD
;		call	search_cmd				; was the command that we were searching?
;		jp		z, CLI_CMD_CD			; yes, then execute the command
		;search command "load file to RAM"
		ld		de, _CMD_LF
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_LF			; yes, then execute the command
;		;search command "loadihex"
;		ld		de, _CMD_LOADIHEX
;		call	search_cmd				; was the command that we were searching?
;		jp		z, CLI_CMD_LOADIHEX		; yes, then execute the command
		;search command "run"
		ld		de, _CMD_RUN
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_RUN			; yes, then execute the command
		;search command "rename file"
		ld		de, _CMD_NF
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_NF			; yes, then execute the command
		;search command "peek"
		ld		de, _CMD_PEEK
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_PEEK			; yes, then execute the command
		;search command "poke"
		ld		de, _CMD_POKE
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_POKE			; yes, then execute the command
		;search command "reset"
		ld		de, _CMD_RESET
		call	search_cmd				; was the command that we were searching?
		jp		z, F_BIOS_WBOOT			; yes, then execute the command
no_match:	; unknown command entered
		ld		hl, error_1001
		call	F_KRN_WRSTR
		jp		cli_promptloop
;------------------------------------------------------------------------------
search_cmd:
; compare buffered command with a valid command syntax
;	IN <= DE = command to check against to
;	OUT => Z flag	1 if DE=HL, which means the command matches
;			0 if one letter isn't equal = command doesn't match
		ld		hl, buffer_cmd
		dec		de
loop_search_cmd:
		cp		' '						; is it a space (start parameter)?
		ret		z						; yes, return
		inc		de						; no, continue checking
		ld		a, (de)
		cpi								; compare content of A with HL, and increment HL
		jp		z, test_end_hl			; A = (HL)
		ret nz
test_end_hl:							; check if end (0) was reached on buffered command
		ld		a, (hl)
		cp		0
		jp		z, test_end_de
		jp		loop_search_cmd
test_end_de:							; check if end (0) was reached on command to check against to
		inc		de
		ld		a, (de)
		cp		0
		ret
;------------------------------------------------------------------------------
check_param1:
; Check if buffer parameters were specified
;	OUT => Z flag =	1 command doesn't exist
;					0 command does exist
		ld		a, (buffer_parm1)		; get what's in param1
		jp		check_param				; check it
check_param2:
		ld		a, (buffer_parm2)		; get what's in param2
check_param:
		cp		0						; was a parameter specified?
		jp		z, bad_params			; no, show error and exit subroutine
		ret
bad_params:
		ld		hl, error_1002			; load bad parameters error text
		call	F_KRN_WRSTR				; print it
		ret
;------------------------------------------------------------------------------
param1val_uppercase:
; converts buffer_parm1 to uppercase
		ld		hl, buffer_parm1 - 1
		jp		p1vup_loop
param2val_uppercase:
; converts buffer_parm1 to uppercase
		ld		hl, buffer_parm2 - 1
p1vup_loop:
		inc		hl
		ld		a, (hl)
		cp		0
		jp		z, plvup_end
		call	F_KRN_TOUPPER
		ld		(hl), a
		jp		p1vup_loop
plvup_end:
		ret
;==============================================================================
; Memory Routines
;==============================================================================
;------------------------------------------------------------------------------
F_CLI_CLRCLIBUFFS:
; Clear CLI buffers
; Clears the buffers used for F_CLI_READCMD, so they are ready for a new command
		ld		a, 0
		ld		hl, buffer_cmd
		ld		de, buffer_cmd + 15		; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG

		ld		hl, buffer_parm1
		ld		de, buffer_parm1 + 15	; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG

		ld		hl, buffer_parm2
		ld		de, buffer_parm2 + 15	; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG
		ret
;==============================================================================
; Disk Routines
;==============================================================================
;------------------------------------------------------------------------------
F_CLI_F16_READDIRENTRY:
; Read all directory entries from current directory (sysvars.cur_dir_start)
; There are 512 root entries. 32 bytes per entry, therefore 16 entries per sector, 
;	therefore 32 sectors
; IN <= cur_dir_start = Sector number current dir
		ld		hl, (cur_dir_start)		; Sector number = current dir
		ld		(cur_sector), hl		; backup Sector number
load_sector:
		ld		hl, (cur_sector)
		call	F_KRN_F16_SEC2BUFFER	; load sector into RAM buffer

		ld		ix, CF_BUFFER_START		; byte pointer within the 32 bytes group
		ld		(buffer_pgm), ix		; byte pointer within the 32 bytes group
loop_readentries:
		; The first byte of the filename indicates its status:
		; 0x00	No file
		; 0xE5  Deleted file
		; 0x05	The first character of the filename is actually 0xe5.
		; 0x2E	The entry is for the dot entry (current directory)
		;		If the second byte is also 0x2e, the entry is for the double dot entry (parent directory)
		;				the cluster field contains the cluster number of this directory's parent directory.
		;		If the parent directory is the root directory, cluster number 0x0000 is specified here.
		; Any other character for first character of a real filename.
		ld		ix, (buffer_pgm)		; byte pointer within the 32 bytes group
		call	F_KRN_F16_GETENTRYDATA	; get data for this entry
		ld		a, (ix)					; load contents of pointed memory address
		cp		0						; is it no file, therefore directory is empty?
		jp		z, nextsector			; yes, load next sector
		cp		$E5						; no, is it a deleted file?
		jp		z, nextentry			; yes, skip entry
										; no, continue
		; if it's a Long File Name (LFN) entry, skip it
		ld		a, (cur_file_attribs)
		cp		0Fh						; is it Long File Name entry?
		jp		z, nextentry			; yes, skip entry
										; no, continue
		; if it was no LFN, then 0x0b holds the File attributes
		bit		3, a					; is it disk's volume label entry?
		jp		nz, nextentry			; yes, skip entry
		call	F_CLI_F16_PRNDIRENTRY	; no, print to screen
nextentry:
		ld		de, 32					; skip 32 bytes
		ld		hl, (buffer_pgm)		; byte pointer within the 32 bytes group
		add		hl, de					; HL = HL + 32
		ld		(buffer_pgm), hl		; byte pointer within the 32 bytes group
		jp		loop_readentries
nextsector:
		ld		hl, cur_sector			; current sector
		inc		(hl)					; next sector
		ld		a, 32
		cp		(hl)					; did we load all 32 bytes of the entry?
		ret		z						; yes, exit routine
		jp		load_sector				; no, load next sector
;------------------------------------------------------------------------------
F_CLI_F16_PRNDIRENTRY:
; Prints an entry for a directory entry
; Filename, extension, first cluster, size
;	IN <= buffer_pgm = first byte of the address where the entry is located
;	OUT => default output (e.g. screen, I/O)
;		ld		iy, (buffer_pgm)		; first byte of the address where the entry is located
		; 0x00 	8 bytes 	File name
		ld		hl, cur_file_name		; byte pointer within the 32 bytes group
		ld		b, 8					; counter = 8 bytes
		call	F_KRN_PRN_BYTES
		; 0x08 	3 bytes 	File extension
		ld		a, '.'					; print the dot between 
		call	F_BIOS_CONOUT			;    name and extension
		ld		hl, cur_file_extension
		ld		b, 3					; counter = 3 bytes
		call	F_KRN_PRN_BYTES

		; print 2 spaces to separate
		ld		a, SPACE
		call	F_BIOS_CONOUT
		ld		a, SPACE
		call	F_BIOS_CONOUT

		; 0x1a	2 bytes		First cluster (low word)
		ld		ix, cur_file_1stcluster
		ld		a, (ix + 1)
		call F_KRN_PRN_BYTE
		ld		a, (ix)
		call F_KRN_PRN_BYTE

		; print 5 spaces to separate
		ld		a, SPACE
		call	F_BIOS_CONOUT
		ld		a, SPACE
		call	F_BIOS_CONOUT
		ld		a, SPACE
		call	F_BIOS_CONOUT
		ld		a, SPACE
		call	F_BIOS_CONOUT
		ld		a, SPACE
		call	F_BIOS_CONOUT

		; 0x1c 	4 bytes 	File size in bytes
		; File size is 4 bytes, but in Z80 computers the max. addressable 
		; memory is 2 bytes (FFFF = 65536 = 64 KB). Therefore we will only
		; use 2 bytes as we don't expect files to be bigger than that
		ld		a, (cur_file_attribs)
		bit		4, a					; Is it a subdirectory?
		jp		nz, printdirlabel		; yes, print <DIR> instead of file size
										; no, print file size
		; file size is in Hexadecimal
		ld		iy, cur_file_size		; IY = first byte of the address where the entry is located
		ld		e, (iy)					; D = MSB
		ld		d, (iy + 1)				; E = LSB
		ex		de, hl					; H = 1st byte (LSB), L = 2nd byte (LSB)
		call	F_KRN_BIN2BCD6
		ex		de, hl					; HL = converted 6-digit BCD
		ld		de, buffer_pgm + 2		; where the numbers in ASCII will be stored
		call	F_KRN_BCD2ASCII
		; Print each of the 6 digits
		ld		iy, buffer_pgm + 2
		ld		a, (iy + 0)
		call	F_BIOS_CONOUT
		ld		a, (iy + 1)
		call	F_BIOS_CONOUT
		ld		a, (iy + 2)
		call	F_BIOS_CONOUT
		ld		a, (iy + 3)
		call	F_BIOS_CONOUT
		ld		a, (iy + 4)
		call	F_BIOS_CONOUT
		ld		a, (iy + 5)
		call	F_BIOS_CONOUT
		jp		nextfiledata
printdirlabel:
		; skip the 4 bytes of file size that were not read
		ld		hl, msg_dirlabel
		call	F_KRN_WRSTR
		ld		a, SPACE
		call	F_BIOS_CONOUT
nextfiledata:
		; print 2 spaces to separate
		ld		a, SPACE
		call	F_BIOS_CONOUT
		ld		a, SPACE
		call	F_BIOS_CONOUT
		
		; 0x18	2 bytes		Date modified
		ld		hl, (cur_file_datemod)
		call	F_KRN_F16_GETDDMMYYYY
 		; print day and  '/' separator
		ld		a, (cur_file_datemod_dd)
		ld		h, 0
		ld		l, a
		call	F_KRN_BIN2BCD6
		ex		de, hl
		ld		de, buffer_pgm + 5
		call	F_KRN_BCD2ASCII
		ld		iy, buffer_pgm + 5
		ld		a, (iy + 4)
		call	F_BIOS_CONOUT
		ld		a, (iy + 5)
		call	F_BIOS_CONOUT
		ld		a, DATESEP
 		call	F_BIOS_CONOUT
		; print month and '/' separator
		ld		a, (cur_file_datemod_mm)
		ld		h, 0
		ld		l, a
		call	F_KRN_BIN2BCD6
		ex		de, hl
		ld		de, buffer_pgm + 5
		call	F_KRN_BCD2ASCII
		ld		iy, buffer_pgm + 5
		ld		a, (iy + 4)
		call	F_BIOS_CONOUT
		ld		a, (iy + 5)
		call	F_BIOS_CONOUT
		ld		a, DATESEP
 		call	F_BIOS_CONOUT
		; print year
 		ld		a, (cur_file_datemod_yyyy)
 		ld		l, a
		ld		a, (cur_file_datemod_yyyy + 1)
 		ld		h, a
		call	F_KRN_BIN2BCD6
		ex		de, hl
		ld		de, buffer_pgm + 5
		call	F_KRN_BCD2ASCII
		ld		iy, buffer_pgm + 5
		ld		a, (iy + 2)
		call	F_BIOS_CONOUT
		ld		a, (iy + 3)
		call	F_BIOS_CONOUT
		ld		a, (iy + 4)
		call	F_BIOS_CONOUT
		ld		a, (iy + 5)
		call	F_BIOS_CONOUT
		
		; print 2 spaces to separate
		ld		a, SPACE
		call	F_BIOS_CONOUT
		ld		a, SPACE
		call	F_BIOS_CONOUT

		; 0x16	2 bytes		Time modified
		ld		hl, (cur_file_timemod)
		call	F_KRN_F16_GETHHMM
		; print hour and  ':' separator
		ld		a, (cur_file_timemod_hh)
		ld		h, 0
		ld		l, a
		call	F_KRN_BIN2BCD6
		ex		de, hl
		ld		de, buffer_pgm + 4
		call	F_KRN_BCD2ASCII
		ld		iy, buffer_pgm + 4
		ld		a, (iy + 4)
		call	F_BIOS_CONOUT
		ld		a, (iy + 5)
		call	F_BIOS_CONOUT
		ld		a, TIMESEP
 		call	F_BIOS_CONOUT
		; print minutes
		ld		a, (cur_file_timemod_mm)
		ld		h, 0
		ld		l, a
		call	F_KRN_BIN2BCD6
		ex		de, hl
		ld		de, buffer_pgm + 4
		call	F_KRN_BCD2ASCII
		ld		iy, buffer_pgm + 4
		ld		a, (iy + 4)
		call	F_BIOS_CONOUT
		ld		a, (iy + 5)
		call	F_BIOS_CONOUT

		ld		b, 1
		call 	F_KRN_EMPTYLINES
		ret
;------------------------------------------------------------------------------
F_CLI_CHK_CFDRIVE:
; CompactFlash commands are only available if a CompactFlash Drive was
; found at boot. Here we check if that was the case (i.e. sysvars.num_fats != 0)
		ld		a, (num_fats)			; load number of FATs found at boot
										; if a CF Drive is not present, it will be 0
		cp		0						; is it 0?
		ret 	nz						; no, then exit routine and command will be executed
		ld		hl, error_1003			; yes,
		call	F_KRN_WRSTR				;		print error message
		jp		cli_promptloop			; and show prompt without executing command
;==============================================================================
; CLI available Commands
;==============================================================================
;------------------------------------------------------------------------------
;	test
;------------------------------------------------------------------------------
CLI_CMD_TEST:
 		call	F_CLI_CHK_CFDRIVE		; Was CF Drive found at boot?


		call	F_KRN_F16_GETDIRENTRY4FILENAME
		ret

; ; TEST FOR F_KRN_F16_SAVEFILE
; 		; store filename in sysvars.cur_file_name
; 		ld		ix, cur_file_name
; 		ld		a, 't'
; 		ld		(ix + 0), a		; 1
; 		ld		a, 'e'
; 		ld		(ix + 1), a		; 2
; 		ld		a, 's'
; 		ld		(ix + 2), a		; 3
; 		ld		a, 't'
; 		ld		(ix + 3), a		; 4
; 		ld		a, 'f'
; 		ld		(ix + 4), a		; 5
; 		ld		a, 'i'
; 		ld		(ix + 5), a		; 6
; 		ld		a, 'l'
; 		ld		(ix + 6), a		; 7
; 		ld		a, 'e'
; 		ld		(ix + 7), a		; 8
; 		; store extension in sysvars.cur_file_extension
; 		ld		ix, cur_file_extension
; 		ld		a, 't'
; 		ld		(ix + 0), a		; 1
; 		ld		a, 's'
; 		ld		(ix + 1), a		; 2
; 		ld		a, 't'
; 		ld		(ix + 2), a		; 3

; 		ld		de, $0000					; start_address
; 		ld		hl, $1000					; end_address
; 		call	F_KRN_F16_SAVEFILE
		ret
;------------------------------------------------------------------------------
;	memdump - Shows memory contents of an specified section of memory
;------------------------------------------------------------------------------
CLI_CMD_MEMDUMP:
;	IN <= 	buffer_parm1 = Start address
; 			buffer_parm2 = End address
;	OUT => default output (e.g. screen, I/O)

	; Check if both parameters were specified
		call	check_param1
		ret		z						; param1 specified? No, exit routine
		call	check_param2			; yes, check param2
		ret		z						; param2 specified? No, exit routine
		; print header
		ld		hl, msg_memdump_hdr
		call	F_KRN_WRSTR
	; buffer_parm2 have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm2)
		ld		h, a
		ld		a, (buffer_parm2 + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		d, a
		ld		a, (buffer_parm2 + 2)
		ld		h, a
		ld		a, (buffer_parm2 + 3)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		e, a
	; DE contains the binary value for param2
		push	de						; store in the stack
	; buffer_parm1 have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1)
		ld		h, a
		ld		a, (buffer_parm1 + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		d, a
		ld		a, (buffer_parm1 + 2)
		ld		h, a
		ld		a, (buffer_parm1 + 3)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		e, a
	; DE contains the binary value for param1
		ex		de, hl					; move from DE to HL (HL=param1)
		pop		de						; restore from stack (DE=param2)
start_dump_line:
		ld		c, LINESPERPAGE			; we will print 23 lines per page
dump_line:
		push	hl
		ld		a, CR
		call	F_BIOS_CONOUT
		ld		a, LF
		call	F_BIOS_CONOUT
		call	F_KRN_PRN_WORD
		ld		a, ':'					; semicolon separates mem address from data
		call	F_BIOS_CONOUT
		ld		a, ' '					; and an extra space to separate
		call	F_BIOS_CONOUT
		ld		b, 10h					; we will output 16 bytes in each line
dump_loop:
		ld		a, (hl)
		call	F_KRN_PRN_BYTE
		ld		a, ' '
		call	F_BIOS_CONOUT
		inc		hl
		djnz	dump_loop
		; dump ASCII characters
		pop		hl
		ld		b, 10h					; we will output 16 bytes in each line
		ld		a, ' '
		call	F_BIOS_CONOUT
		call	F_BIOS_CONOUT
ascii_loop:
		ld		a, (hl)
		call	F_KRN_PRINTABLE			; is it an ASCII printable character?
		jr		c, printable
		ld		a, '.'					; if is not, print a dot
printable:
		call	F_BIOS_CONOUT
		inc		hl
		djnz	ascii_loop

		push	hl						; backup HL before doing sbc instruction
		and		a						; clear carry flag
		sbc		hl, de					; have we reached the end address?
		pop		hl						; restore HL
		jr		c, dump_next			; end address not reached. Dump next line
		ret
dump_next:
		dec		c						; 1 line was printed
		jp		z, askmoreorquit	 	; we have printed 23 lines. More?
		jp 		dump_line				; print another line
askmoreorquit:
		push	hl						; backup HL
		ld		hl, msg_moreorquit
		call	F_KRN_WRSTR
		call	F_BIOS_CONIN			; read key
		cp		SPACE					; was the SPACE key?
		jp		z, wantsmore			; user wants more
		pop		hl						; yes, user wants more. Restore HL
		ret								; no, user wants to quit
wantsmore:
		; print header
		ld		hl, msg_memdump_hdr
		call	F_KRN_WRSTR
		pop		hl						; restore HL
		jp		start_dump_line			; return to start, so we print 23 more lines
;------------------------------------------------------------------------------
;	lf - Load a file into RAM
;------------------------------------------------------------------------------
; bytes of executable code are loaded at load address read from 
; the file (bytes 03 and 04)
CLI_CMD_LF:
		call	F_CLI_CHK_CFDRIVE		; Was CF Drive found at boot?
		call	check_param1
		jp		nz, loadfile			; param1 specified? Yes, do the command
		ret								; no, exit routine
loadfile:
		call	param1val_uppercase		; convert param1 to uppercase
		ld		hl, buffer_parm1
		ld		(tmp_addr1), hl
		call	F_KRN_F16_GETDIRENTRY4FILENAME
		jp		c, ldfilenotfound		; if Carry Flag is set, file was not found
		ld		de, (cur_file_1stcluster)
		call	F_KRN_F16_LOADEXE2RAM	; load from executable's 1st cluster to RAM
		ld		hl, msg_exeloaded		; no, print load message
		call	F_KRN_WRSTR
		ex		de, hl					; HL = load address (returned by F_KRN_F16_LOADEXE2RAM)
		call	F_KRN_PRN_WORD			; print load address
		ret
ldfilenotfound:
		ld		hl, error_1004
		call	F_KRN_WRSTR
		ret
;------------------------------------------------------------------------------
;	nf - Rename file
;------------------------------------------------------------------------------
CLI_CMD_NF:
		call	F_CLI_CHK_CFDRIVE		; Was CF Drive found at boot?
		; Check if both parameters were specified
		call	check_param1
		ret		z						; param1 specified? No, exit routine
		call	check_param2			; yes, check param2
		ret		z						; param2 specified? No, exit routine
renfile:
		call	param1val_uppercase		; convert param1 to uppercase
		call	param2val_uppercase		; convert param2 to uppercase
		ld		hl, buffer_parm1		; copy entered param1's address
		ld		(tmp_addr1), hl			; 	to tmp_addr1
		ld		hl, buffer_parm2		; copy entered param2's address
		ld		(tmp_addr2), hl			; 	to tmp_addr2
		call	F_KRN_F16_RENFILE
		jp		c, nferror
		ret
nferror:
		ld		hl, error_1005
		call	F_KRN_WRSTR
		ret
;------------------------------------------------------------------------------
;	cd - Changes current directory of a disk
;------------------------------------------------------------------------------
;CLI_CMD_CD:
;		call	check_param1
;		jp		z, cdend				; param1 specified?
;		call	F_KRN_F16_CHGDIR		; yes, change current directory
;cdend:
;		ret								; no, exit routine
;------------------------------------------------------------------------------
;	ld - Prints the list of the current directory of a disk
;------------------------------------------------------------------------------
CLI_CMD_LD:
		call	F_CLI_CHK_CFDRIVE		; Was CF Drive found at boot?
		ld		hl, msg_cf_ld			; print directory list header
		call	F_KRN_WRSTR
		call	F_CLI_F16_READDIRENTRY	; print contents of current directory
		ret
;------------------------------------------------------------------------------
;	peek - Prints the value of a single memory address
;------------------------------------------------------------------------------
CLI_CMD_PEEK:
;	IN <= 	buffer_parm1 = address
;	OUT => default output (e.g. screen, I/O)
	; Check if parameter 1 was specified
		call	check_param1
		jp		nz, peek				; param1 specified? Yes, do the peek
		ret								; no, exit routine
peek:
		call	param1val_uppercase		; convert param1 to uppercase
;		ld		hl, empty_line			; print an empty line
;		call	F_KRN_WRSTR
		ld		b, 1
		call 	F_KRN_EMPTYLINES
	; buffer_parm1 has the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1)
		ld		h, a
		ld		a, (buffer_parm1 + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		d, a
		ld		a, (buffer_parm1 + 2)
		ld		h, a
		ld		a, (buffer_parm1 + 3)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		e, a
	; DE contains the binary value for param1
		ex		de, hl					; move from DE to HL (param1)
		ld		a, (hl)					; load value at address of param1
		call	F_KRN_PRN_BYTE			; Prints byte in hexadecimal notation
		ret
;------------------------------------------------------------------------------
;	poke - Changes a single memory address to a specified value
;------------------------------------------------------------------------------
CLI_CMD_POKE:
;	IN <= 	buffer_parm1 = address
; 			buffer_parm2 = value
;	OUT => print message 'OK' to default output (e.g. screen, I/O)
	; Check if both parameters were specified
		call	check_param1
		ret		z						; param1 specified? No, exit routine
		call	check_param2			; yes, check param2
		ret		z						; param2 specified? No, exit routine
		call	param1val_uppercase		; convert param1 to uppercase
		call	param2val_uppercase		; convert param2 to uppercase
		; convert param2 to uppercase and store in HL
		ld		hl, (buffer_parm2)
		ld		a, h
		call	F_KRN_TOUPPER
		ld		b, a
		ld		a, l
		call	F_KRN_TOUPPER
		ld		l, b
		ld		h, a
		call	F_KRN_ASCII2HEX			; Hex ASCII to Binary conversion
	; buffer_parm1 have the address in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1)
		ld		h, a
		ld		a, (buffer_parm1 + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		d, a
		ld		a, (buffer_parm1 + 2)
		ld		h, a
		ld		a, (buffer_parm1 + 3)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		e, a					; DE contains the binary value for param1
	; buffer_parm2 have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm2)
		ld		h, a
		ld		a, (buffer_parm2 + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX			; A contains the binary value for param2
		ex		de, hl					; move from DE to HL
		ld		(hl), a					; store value in address
	; print OK, to let the user know that the command was successful
		ld		hl, msg_ok
		call	F_KRN_WRSTR
		ret
;------------------------------------------------------------------------------
;	run - Starts running instructions from a specific memory address
;------------------------------------------------------------------------------
CLI_CMD_RUN:
;	IN <= 	buffer_parm1 = address
	; Check if parameter 1 was specified
		call	check_param1
		jp		nz, runner				; param1 specified? Yes, do the run
		ret								; no, exit routine
runner:
		call	param1val_uppercase		; convert param1 to uppercase
	; buffer_parm1 have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1)
		ld		h, a
		ld		a, (buffer_parm1 + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		d, a
		ld		a, (buffer_parm1 + 2)
		ld		h, a
		ld		a, (buffer_parm1 + 3)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		e, a
	; DE contains the binary value for param1
		ex		de, hl					; move from DE to HL (param1)
		jp		(hl)					; jump execution to address in HL
		ret
;==============================================================================
; Messages
;==============================================================================
msg_cli_version:
		.BYTE	CR, LF
		.BYTE	"CLI    v1.0.0", 0
msg_bytesfree:
		.BYTE	" Bytes free", 0
msg_prompt:
		.BYTE	CR, LF
		.BYTE	"> ", 0
msg_ok:
		.BYTE	CR, LF
		.BYTE	"OK", 0
msg_cf_ld:
		.BYTE	CR, LF
		.BYTE	"Directory contents", CR, LF
		.BYTE	"------------------------------------------------", CR, LF
		.BYTE	"File          Cluster  Size    Date        Time", CR, LF
		.BYTE	"------------------------------------------------", CR, LF, 0
msg_dirlabel:
		.BYTE	"<DIR>", 0
msg_crc_ok:
		.BYTE	" ...[CRC OK]", CR, LF, 0
msg_exeloaded:
		.BYTE	CR, LF
		.BYTE	"Executable loaded at: 0x", 0
msg_moreorquit:
		.BYTE	CR, LF
		.BYTE	"[SPACE] for more or another key for stop", 0
msg_memdump_hdr:
		.BYTE	CR, LF
		.BYTE	"      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F", CR, LF
		.BYTE	"      .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. ..", 0
;------------------------------------------------------------------------------
;             ERROR MESSAGES
;------------------------------------------------------------------------------
error_1001:
		.BYTE	CR, LF
		.BYTE	"Command unknown (use utility 'help' for list of available commands)", CR, LF, 0
error_1002:
		.BYTE	CR, LF
		.BYTE	"Bad parameter(s)", CR, LF, 0
error_1003:
		.BYTE	CR, LF
		.BYTE	"Command unavailable. CF Drive not found at boot", CR, LF, 0
error_1004:
		.BYTE	CR, LF
		.BYTE	"ERROR: File not found", 0
error_1005:
		.BYTE	CR, LF
		.BYTE	"ERROR: Original file not found or destination file already exists", 0
;==============================================================================
; AVAILABLE CLI COMMANDS
;==============================================================================
_CMD_PEEK		.BYTE	"peek", 0
_CMD_POKE		.BYTE	"poke", 0
_CMD_RESET		.BYTE	"reset", 0
_CMD_RUN		.BYTE	"run", 0
_CMD_TEST		.BYTE	"test", 0		; ToDo - remove this and all code related
_CMD_MEMDUMP	.BYTE	"memdump", 0


; CompactFlash commands
_CMD_LD			.BYTE	"ld", 0			; list directory
;_CMD_CD			.BYTE	"cd", 0		; change directory
_CMD_LF			.BYTE	"lf", 0			; load file to RAM
_CMD_NF			.BYTE	"nf", 0			; rename file
;==============================================================================
; END of CODE
;==============================================================================
        .ORG	CLI_END
		.BYTE	0
		.END