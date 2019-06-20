;******************************************************************************
; kernel.string.asm
;
; Kernel's String routines
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
; String Routines
;==============================================================================
;------------------------------------------------------------------------------
F_KRN_WRSTR:			.EXPORT		F_KRN_WRSTR
; Console output string
; Display a string of ASCII characters terminated with CR.
; HL = pointer to first character of the string
		ld	    a, (hl)			        ; Get character of the string
		or	    a			            ; is it 00h? (i.e. end of string)
		ret	    z			            ; if yes, then return on terminator
		call	F_BIOS_CONOUT		    ; otherwise, print it
		inc	    hl			            ; pointer to next character of the string
		jr	    F_KRN_WRSTR		        ; continue (until 00h)
		ret
;------------------------------------------------------------------------------
F_KRN_RDCHARECHO:		.EXPORT		F_KRN_RDCHARECHO
; Read a character, with echo
; Read a character from Console and outputs to the Screen
; Read character is stored in register A
		call 	F_BIOS_CONIN
		call 	F_BIOS_CONOUT
; ToDo 	- Check for special characters
;	- Allow backspace
		ret
;------------------------------------------------------------------------------
F_KRN_TOUPPER:			.EXPORT		F_KRN_TOUPPER
; Convert to Uppercase
; Converts character in register A to uppercase.
; IN <= character to convert
; OUT => uppercased character
		cp		'a'						; nothing to do if is not lower case
		ret		c
		cp		'z' + 1					; > 'z'?
		ret		nc
		and		5Fh						; convert to upper case
		ret
;------------------------------------------------------------------------------
F_KRN_PRN_BYTES:		.EXPORT		F_KRN_PRN_BYTES
; Prints bytes
; Print n number of bytes as ASCII characters
;	IN <= B = number of bytes to print
;		  HL = start memory address where the bytes are
;	OUT => default output (e.g. screen, I/O)
		ld		a, (hl)					; get memory content pointed by HL into A
		cp		0						; is it null?
		jp		z, prnbytesend			; yes, exit routine
		cp		LF						; new line?
		jp		nz, nonewline			; no, contine normally
		ld		a, CR					; yes, print CR+LF
		call	F_BIOS_CONOUT
		ld		a, LF
nonewline:
		call	F_BIOS_CONOUT			; no, print character
		inc		hl						; pointer to next character
		djnz	F_KRN_PRN_BYTES			; all bytes printer? No, continue printing
prnbytesend:
		ret								; yes, exit routine
;------------------------------------------------------------------------------
F_KRN_PRN_BYTE:			.EXPORT		F_KRN_PRN_BYTE
; Print Byte
; Prints a single byte in hexadecimal notation.
;	IN <= A = the byte to be printed
;	OUT => default output (e.g. screen, I/O)
		push	bc
		; convert high nibble
		ld		b, a
		rrca							;move high nibble to low nibble
		rrca
		rrca
		rrca
		call	F_KRN_PRN_NIBBLE    	; prints high nibble
		;convert low nibble
		ld		a, b
		call	F_KRN_PRN_NIBBLE   		; prints low nibble
		pop	bc
		ret
;------------------------------------------------------------------------------
F_KRN_PRN_NIBBLE:
; Print Nibble
; Prints a single hexadecimal nibble in hexadecimal notation.
;	IN <= LSB of A
;	OUT => default output (e.g. screen, I/O)
		and		0fh						; remove hight nibble
		cp		10						; is it a digit?
		jr		c, print_nibble			; yes, print it
		add		a, 7					; no, add offset for letters
print_nibble:
		add		a, 30h					; add offset for digits (30 to 39 in hex is 0 to 9 in dec)
		call	F_BIOS_CONOUT			; print the nibble
		ret
;------------------------------------------------------------------------------
F_KRN_PRN_WORD:			.EXPORT		F_KRN_PRN_WORD
; Print Word
; Prints the 4 hexadecimal digits of a word in hexadecimal notation.
;	IN <= HL (the word to be printed)
;	OUT => default output (e.g. screen, I/O)
		ld		a, h
		call	F_KRN_PRN_BYTE
		ld		a, l
		call	F_KRN_PRN_BYTE
		ret
;------------------------------------------------------------------------------
F_KRN_PRINTABLE:		.EXPORT		F_KRN_PRINTABLE
; Checks if a character is a printable ASCII character
;	IN <= A contains character to check
;	OUT => C flag is set if character is printable.
		cp		SPACE
		jr		nc, is_printable
		ccf
		ret
is_printable:
		cp		7fh
		ret
;------------------------------------------------------------------------------
F_KRN_EMPTYLINES:		.EXPORT		F_KRN_EMPTYLINES
; Output n empty lines
;	IN <= B = number of empty lines to print out
;	OUT => default output (e.g. screen, I/O)
loop_emptylines:
		ld		a, CR
		call	F_BIOS_CONOUT
		ld		a, LF
		call	F_BIOS_CONOUT
		djnz	loop_emptylines
		ret
;------------------------------------------------------------------------------
F_KRN_STRCMP:			.EXPORT		F_KRN_STRCMP
; Compare 2 zero terminated strings
; IN <= HL pointer to start of string 1
;		DE pointer to start of string 2
; OUT => if str1 = str2, Z flag set and C flag not set
;		 if str1 != str2 and str1 longer than str2, Z flag not set and C flag not set
;		 if str1 != str2 and str1 shorter than str2, Z flag not set and C flag set
;
		; Determine which is the shorter string
		ld		a, (hl)
		ld		(buffer_pgm), a			; length of string 1
		ld		a, (de)
		ld		(buffer_pgm + 1), a		; length of string 2
		cp		(hl)					; compare length str2 to length str1
		jr		c, strcmp				; str2 shorter than str1? yes, jump
		ld		a, (hl)					; no, str1 is shorter
		; Compare string (through length of shorter)
strcmp:
		or		a						; test length of shorter string
		jr		z, cmplen				; compare lengths
		ld		b, a					; counter = length of shorter string (number of bytes to compare)
		ex		de, hl					; DE = str1, HL = str2
strcmploop:
		inc		hl						; pointer to next byte of str2
		inc		de						; pointer to next byte of str1
		ld		a, (de)					; byte from str1
		cp		(hl)					; is it same as in str2?
		ret		nz						; no, return with flags set
		djnz	strcmploop				; yes, continue comparing
cmplen:
		; compare lengths
		ld		a, (buffer_pgm)
		ld		hl, (buffer_pgm + 1)
		cp		(hl)
		ret								; exit routine, with flags set or cleared
;------------------------------------------------------------------------------
F_KRN_STRCPY:			.EXPORT		F_KRN_STRCPY
; Copy n characters from string 1 to string 2
; IN <= HL pointer to start of string 1
;		DE pointer to start of string 2
;		B number of characters to copy
		ld		a, (hl)					; 1 character from original string
		ld		(de), a					; copy it to destination string
		inc		de						; pointer to next destination character
		inc		hl						; pointer to next original character
		djnz	F_KRN_STRCPY			; all characters copied (i.e. B=0)? No, continue copying
		ret								; yes, exit routine
