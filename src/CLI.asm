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

		; Show Free available RAM
;		ld		hl, FREERAM_END
;		ld		de, FREERAM_START
;		sbc		hl, de					; FREERAM_END - FREERAM_START
;;		inc		hl						; + 1 byte to account of byte 0
;		ld		(FREERAM_START), hl		; store it in RAM

; ToDo - Needs to be converted to decimal first!

cli_promptloop:
        call	F_CLI_CLRCLIBUFFS	    ; Clear buffers
		ld	    hl, msg_prompt          ; Prompt
		call	F_KRN_WRSTR             ; Output message
		ld	    hl, buffer_cmd          ; address where commands are buffered

		ld	    a, 0
		ld	    (buffer_cmd), a
		call	F_CLI_READCMD
		call	F_CLI_PARSECMD
        jp      cli_promptloop
;------------------------------------------------------------------------------
F_CLI_READCMD:
; Read string containing a command and parameters
; Read characters from the Console into a memory buffer until RETURN is pressed.
; Parameters (identified by colon) are detected and stored in *parameters buffer*,
; meanwhile the command is store in *command buffer*.
readcmd_loop:
		call	F_KRN_RDCHARECHO		; read a character, with echo
		cp		' '						; test for 1st parameter entered
		jp		z, was_param
		cp		','						; test for 2nd parameter entered
		jp		z, was_param
		; test for special keys
;		cp		key_backspace			; Backspace?
;		jp		z, was_backspace		; yes, don't add to buffer
;		cp		key_up					; up arrow?
;		jp		z, no_buffer			; yes, don't add to buffer
;		cp		key_down				; down arrow?
;		jp		z, no_buffer			; yes, don't add to buffer
;		cp		key_left				; left arrow?
;		jp		z, no_buffer			; yes, don't add to buffer
;		cp		key_right				; right arrow?
;		jp		z, no_buffer			; yes, don't add to buffer

		cp		CR						; ENTER?
		jp		z, end_get_cmd			; yes, command was fully entered
		ld		(hl), a					; store character in buffer
		inc		hl						; buffer pointer + 1
no_buffer:
		jp		readcmd_loop			; don't add last entered char to buffer
		ret
was_backspace:	
		dec		hl						; go back 1 unit on the buffer pointer
loop_get_cmd:	
		jp		readcmd_loop			; read another character
was_param:
		ld		a, (buffer_parm1_val)
		cp		00h						; is buffer area empty (=00h)?
		jp		z, add_value1			; yes, add character to buffer area
		ld		a, (buffer_parm2_val)
		cp		00h						; is buffer area empty (=00h)?
		jp		z, add_value2			; yes, add character to buffer area
		jp		readcmd_loop			; read next character
add_value1:
		ld		hl, buffer_parm1_val
		jp		readcmd_loop
add_value2:
		ld		hl, buffer_parm2_val
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
		;search command "ld" (list directory)
		ld		de, _CMD_LD
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_LD			; yes, then execute the command
;		;search command "cd" (change directory)
;		ld		de, _CMD_CD
;		call	search_cmd				; was the command that we were searching?
;		jp		z, CLI_CMD_CD			; yes, then execute the command
		;search command "help"
		ld		de, _CMD_HELP
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_HELP			; yes, then execute the command
		;search command "load file to RAM"
		ld		de, _CMD_LF
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_LF			; yes, then execute the command
		;search command "show file contents"
		ld		de, _CMD_SF
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_SF			; yes, then execute the command
;		;search command "loadihex"
;		ld		de, _CMD_LOADIHEX
;		call	search_cmd				; was the command that we were searching?
;		jp		z, CLI_CMD_LOADIHEX		; yes, then execute the command
		;search command "run"
		ld		de, _CMD_RUN
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_RUN			; yes, then execute the command
		;search command "peek"
		ld		de, _CMD_PEEK
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_PEEK			; yes, then execute the command
		;search command "poke"
		ld		de, _CMD_POKE
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_POKE			; yes, then execute the command
		;search command "memdump"
		ld		de, _CMD_MEMDUMP
		call	search_cmd				; was the command that we were searching?
		jp		z, CLI_CMD_MEMDUMP		; yes, then execute the command
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
		ld		a, (buffer_parm1_val)	; get what's in param1
		jp		check_param				; check it
check_param2:
		ld		a, (buffer_parm2_val)	; get what's in param2
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
; converts buffer_parm1_val to uppercase
		ld		hl, buffer_parm1_val - 1
		jp		p1vup_loop
param2val_uppercase:
; converts buffer_parm1_val to uppercase
		ld		hl, buffer_parm2_val - 1
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
		ld	    a, 0
		ld	    hl, buffer_cmd
		ld	    de, buffer_cmd + 0fh    ; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG

		ld	    hl, buffer_parm1
		ld	    de, buffer_parm1 + 0fh	; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG

		ld	    hl, buffer_parm1_val
		ld	    de, buffer_parm1_val + 0fh   ; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG

		ld	    hl, buffer_parm2
		ld	    de, buffer_parm2 + 0fh	; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG

		ld	    hl, buffer_parm2_val
		ld	    de, buffer_parm2_val + 0fh	; buffers are 15 bytes long
		call	F_KRN_SETMEMRNG
		ret
;==============================================================================
; Disk Routines
;==============================================================================
;------------------------------------------------------------------------------
F_CLI_F16_READDIRENTRY:
; Read a Directory Entry (32 bytes) from disk
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
		ld		b, 1
		call 	F_KRN_EMPTYLINES
		ret
;==============================================================================
; CLI available Commands
;==============================================================================
;------------------------------------------------------------------------------
;	lf - Load a file into RAM
;------------------------------------------------------------------------------
; First 16 bytes are the header and are not loaded into RAM
		;	4 bytes must be string dzOS
		;	next bytes for load address (where to load the bytes)
		; Rest of the bytes are the executable code, which is loaded at load address
CLI_CMD_LF:
		call	check_param1
		jp		nz, loadfile			; param1 specified? Yes, do the command
		ret								; no, exit routine
loadfile:
		call	param1val_uppercase
		ld		de, (buffer_parm1_val)
		; parm1 is in ascii, we need to convert the values to hex
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		e, a
	; DE contains the binary value for param1
	; >>>> ToDO - What if user entered wrong cluster? <<<<
		call	F_KRN_F16_LOADEXE2RAM
		jp		z, lfend				; did LOADEXE2RAM return an error? Yes, exit routine
		ld		hl, msg_exeloaded		; no, print load message
		call	F_KRN_WRSTR
		ex		de, hl					; HL = load address (returned by F_KRN_F16_LOADEXE2RAM)
		call	F_KRN_PRN_WORD			; print load address
lfend:
		ret
;------------------------------------------------------------------------------
;	sf - Show the contents of a file
;------------------------------------------------------------------------------
CLI_CMD_SF:
		call	check_param1
		jp		nz, showfile			; param1 specified? Yes, do the command
		ret								; no, exit routine
showfile:
		call	param1val_uppercase
		ld		de, (buffer_parm1_val)
		; parm1 is in ascii, we need to convert the values to hex
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		e, a
	; DE contains the binary value for param1
	; >>>> ToDO - What if user entered wrong cluster? <<<<

		; for current cluster
		;	convert it to sector
		;	read each sector of the cluster
		;	print the 512 bytes to the screen
		ex		de, hl					; move from DE to HL (HL = param1)
		push	hl						; backup HL. param1 (cluster number)
		call	F_KRN_F16_CLUS2SEC		; convert cluster number to sector number
		call	F_KRN_F16_SEC2BUFFER	; load sector to buffer
		; read FAT (into buffer_pgm) to know which are the clusters of the file
		pop		hl						; restore HL. param1 (cluster number)
		push	hl						; backup HL. param1 (cluster number)
		call	F_KRN_F16_GETFATCLUS	; read clusters from FAT into sysvars.buffer_pgm
		pop		hl						; restore HL. param1 (cluster number)
		ld		b, 1
		call 	F_KRN_EMPTYLINES
		ld		a, (secs_per_clus)
		push	af						; backup A. secs_per_clus
		ex		de, hl					; DE = param1 (cluster number)
getclussec:
		call	F_KRN_F16_CLUS2SEC		; get the sector number of the cluster
loadandprintsec:
		push	hl						; backup HL. sector number
		call	F_KRN_F16_SEC2BUFFER	; load sector to buffer

		; print entire sector on screen
		ld		hl, CF_BUFFER_START
		; print first 256 bytes of the sector on screen
		ld		b, 0
		call	F_KRN_PRN_BYTES
		jp		z, sfendpop				; was last character null? Yes, exit routine
		; no, print remaining 256 bytes of the sector on screen
		ld		b, 0
		call	F_KRN_PRN_BYTES

		pop		hl						; restore HL. sector number
		pop		af						; restore A. secs_per_clus
		dec		a						; 1 sector printed
		cp		0						; all sectors of the cluster printed?
		jp		z, nextclus				; yes, load next cluster
		inc		hl						; no, print next sector of the cluster
		push	af						; backup A. secs_per_clus
		jp		loadandprintsec

		; rest of clusters
		; 	for each cluster in sysvars.buffer_pgm until cluster == FFFF
		; 		convert it into sectors
		;		print each byte of sector
		; 	load sectors and print contents

nextclus:
		ld		ix, buffer_pgm			; pointer to cluster counter in sysvars.buffer_pgm
		ld		a, (ix)					; how many cluster to print
		add		a, a					; each cluster is 2 bytes, so duplicate the counter
		cp		(ix + 1)				; all cluster printed?
		jp		z, sfend				; yes, exit routine
		ld		b, 0					; no continue
		ld		c, (ix + 1)				; BC = counter of printed clusters
		inc		bc						; counter + 1
		ld		hl, buffer_pgm			; pointer to cluster counter in sysvars.buffer_pgm
		add		hl, bc					; pointer to cluster counter + counter of printed clusters
		ld		a, (hl)					; load LSB byte of cluster number
		cp		$FF						; if A = FF, then this was last cluster
		jp		z, sfend				; yes, exit routine
										; no, continue
		ld		e, (hl)					; DE = LSB first cluster in sysvars.buffer_pgm
		inc		hl
		ld		d, (hl)					; DE = MSB first cluster in sysvars.buffer_pgm
		inc		(ix + 1)				; each cluster is 2 bytes
		inc		(ix + 1)				; 	counter of printed clusters + 2
		jp		getclussec				; print entire cluster (all sectors)
sfendpop:
		pop		hl
		pop		af
sfend:
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
		ld		hl, msg_cf_ld			; print directory list header
		call	F_KRN_WRSTR
		call	F_CLI_F16_READDIRENTRY	; print contents of current directory
		ret
;------------------------------------------------------------------------------
;	help - Show list of available commands
;------------------------------------------------------------------------------
CLI_CMD_HELP:
		ld		hl, msg_help
		call	F_KRN_WRSTR
		ret
;------------------------------------------------------------------------------
;	peek - Prints the value of a single memory address
;------------------------------------------------------------------------------
CLI_CMD_PEEK:
;	IN <= 	buffer_parm1_val = address
;	OUT => default output (e.g. screen, I/O)
	; Check if parameter 1 was specified
		call	check_param1
		jp		nz, peek				; param1 specified? Yes, do the peek
		ret								; no, exit routine
peek:
		call	param1val_uppercase
;		ld		hl, empty_line			; print an empty line
;		call	F_KRN_WRSTR
		ld		b, 1
		call 	F_KRN_EMPTYLINES
	; buffer_parm1_val has the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
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
;	IN <= 	buffer_parm1_val = address
; 			buffer_parm2_val = value
;	OUT => print message 'OK' to default output (e.g. screen, I/O)
	; Check if both parameters were specified
		call	check_param1
		ret		z						; param1 specified? No, exit routine
		call	check_param2			; yes, check param2
		jp		nz, poke				; param2 specified? Yes, do the poke
		ret								; no, exit routine
poke:
		call	param1val_uppercase
		call	param2val_uppercase
		; convert param2 to uppercase and store in HL
		ld		hl, (buffer_parm2_val)
		ld		a, h
		call	F_KRN_TOUPPER
		ld		b, a
		ld		a, l
		call	F_KRN_TOUPPER
		ld		l, b
		ld		h, a
		call	F_KRN_ASCII2HEX			; Hex ASCII to Binary conversion
	; buffer_parm1_val have the address in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		e, a					; DE contains the binary value for param1
	; buffer_parm2_val have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm2_val)
		ld		h, a
		ld		a, (buffer_parm2_val + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX			; A contains the binary value for param2
		ex		de, hl					; move from DE to HL
		ld		(hl), a					; store value in address
	; print OK, to let the user know that the command was successful
		ld		hl, msg_ok
		call	F_KRN_WRSTR
		ret
;------------------------------------------------------------------------------
;	memdump - Shows memory contents of an specified section of memory
;------------------------------------------------------------------------------
CLI_CMD_MEMDUMP:
;	IN <= 	buffer_parm1_val = Start address
; 			buffer_parm2_val = End address
;	OUT => default output (e.g. screen, I/O)

	; Check if both parameters were specified
		call	check_param1
		ret		z						; param1 specified? No, exit routine
		call	check_param2			; yes, check param2
		jp		nz, memdump				; param2 specified? Yes, do the memdump
		ret								; no, exit routine
memdump:
		; print header
		ld		hl, msg_memdump_hdr
		call	F_KRN_WRSTR
	; buffer_parm2_val have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm2_val)
		ld		h, a
		ld		a, (buffer_parm2_val + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		d, a
		ld		a, (buffer_parm2_val + 2)
		ld		h, a
		ld		a, (buffer_parm2_val + 3)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		e, a
	; DE contains the binary value for param2
		push	de						; store in the stack
	; buffer_parm1_val have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
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
;	run - Starts running instructions from a specific memory address
;------------------------------------------------------------------------------
CLI_CMD_RUN:
;	IN <= 	buffer_parm1_val = address
	; Check if parameter 1 was specified
		call	check_param1
		jp		nz, runner				; param1 specified? Yes, do the run
		ret								; no, exit routine
runner:
		call	param1val_uppercase
	; buffer_parm1_val have the value in hexadecimal
	; we need to convert it to binary
		ld		a, (buffer_parm1_val)
		ld		h, a
		ld		a, (buffer_parm1_val + 1)
		ld		l, a
		call	F_KRN_ASCII2HEX
		ld		d, a
		ld		a, (buffer_parm1_val + 2)
		ld		h, a
		ld		a, (buffer_parm1_val + 3)
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
msg_moreorquit:
		.BYTE	CR, LF
		.BYTE	"[SPACE] for more or another key for stop", 0
msg_help:
		.BYTE	CR, LF
		.BYTE	" dzOS Help", CR, LF
		.BYTE	"|-------------|-----------------------------------|--------------------|", CR, LF
		.BYTE	"| Command     | Description                       | Usage              |", CR, LF
		.BYTE	"|-------------|-----------------------------------|--------------------|", CR, LF
		.BYTE	"| help        | Shows this help                   | help               |", CR, LF
;		.BYTE	"| loadihex    | Load Intel HEX file               | loadihex 2600      |", CR, LF
		.BYTE	"| memdump     | Memory Dump                       | memdump 0000,0100  |", CR, LF
		.BYTE	"| peek        | Show a Memory Address value       | peek 20cf          |", CR, LF
		.BYTE	"| poke        | Change a Memory Address value     | poke 20cf,ff       |", CR, LF
		.BYTE	"| reset       | Clears RAM and resets the system  | reset              |", CR, LF
		.BYTE	"| run         | Run from Memory Address           | run 2600           |", CR, LF
		.BYTE	"|             |                                   |                    |", CR, LF
;		.BYTE	"| cd          | Change Directory                  | cd mydocs          |", CR, LF
		.BYTE	"| ld          | List Directory contents of a Disk | ld                 |", CR, LF
		.BYTE	"| sf          | Show contents of a file           | sf 0007            |", CR, LF
		.BYTE	"| lf          | Load file (Max. 496 bytes) to RAM | lf 0007            |", CR, LF
		.BYTE	"|-------------|-----------------------------------|--------------------|", 0
msg_cf_ld:
		.BYTE	CR, LF
		.BYTE	"Directory contents", CR, LF
		.BYTE	"------------------------------------------------", CR, LF
		.BYTE	"File          Cluster  Size    Time   Date", CR, LF
		.BYTE	"------------------------------------------------", CR, LF, 0
msg_dirlabel:
		.BYTE	"<DIR>", 0
msg_crc_ok:
		.BYTE	" ...[CRC OK]", CR, LF, 0
msg_memdump_hdr:
		.BYTE	CR, LF
		.BYTE	"      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F", CR, LF
		.BYTE	"      .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. ..", 0
msg_exeloaded:
		.BYTE	CR, LF
		.BYTE	"Executable loaded at: 0x", 0
;------------------------------------------------------------------------------
;             ERROR MESSAGES
;------------------------------------------------------------------------------
error_1001:
		.BYTE	CR, LF
		.BYTE	"Command unknown (type help for list of available commands)", CR, LF, 0
error_1002:
		.BYTE	CR, LF
		.BYTE	"Bad parameter(s)", CR, LF, 0
error_1003:
		.BYTE	CR, LF
		.BYTE	"Invalid Intel HEX format", CR, LF, 0
error_1004:
		.BYTE	CR, LF
		.BYTE	"Checksum error", CR, LF, 0
error_1005:
		.BYTE	CR, LF
		.BYTE	"File not found", CR, LF, 0
;==============================================================================
; AVAILABLE CLI COMMANDS
;==============================================================================
_CMD_HELP		.BYTE	"help", 0
;_CMD_LOADIHEX	.BYTE	"loadihex", 0
_CMD_MEMDUMP	.BYTE	"memdump", 0
_CMD_PEEK		.BYTE	"peek", 0
_CMD_POKE		.BYTE	"poke", 0
_CMD_RESET		.BYTE	"reset", 0
_CMD_RUN		.BYTE	"run", 0

; CompactFlash commands
_CMD_LD			.BYTE	"ld", 0			; list directory
;_CMD_CD			.BYTE	"cd", 0		; change directory
_CMD_SF			.BYTE	"sf", 0			; show file contents
_CMD_LF			.BYTE	"lf", 0			; load file to RAM
;==============================================================================
; END of CODE
;==============================================================================
        .ORG	CLI_END
		.BYTE	0
		.END