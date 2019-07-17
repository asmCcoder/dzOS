;******************************************************************************
; kernel.mem.asm
;
; Kernel's Memory routines
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
; Memory Routines
;==============================================================================
;------------------------------------------------------------------------------
F_KRN_SETMEMRNG:		.EXPORT		F_KRN_SETMEMRNG
; Sets a value in a memory position range
; IN <= HL = start position
;		DE = end position
;		A  = value to set
; The routine will go from HL to DE and store in each position whatever value
; is in register A.
setmemrng_loop:
		ld		(hl), a					; put register A content in address pointed by HL
		inc		hl						; HL pointed + 1
		push	hl						; store HL value in Stack, because SBC destroys it
		sbc		hl, de					; substract DE from HL
		jp		z, end_setmemrng_loop	; if we reach the end position, jump out
		pop		hl						; restore HL value from Stack
		jp		setmemrng_loop			; no at end yet, continue loop
end_setmemrng_loop:
		pop		hl						; restore HL value from Stack
		ret