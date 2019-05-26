;******************************************************************************
; kernel.math.asm
;
; Kernel's Arithmetic routines
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
; Arithmetic Routines
;==============================================================================
;------------------------------------------------------------------------------
F_KRN_MULTIPLY816_SLOW:
; Multiplies an 8-bit number by a 16-bit number
; It does a slow multiplication by adding multiplier to itself as many
; times as multiplicand (e.g. 8 * 4 = 8+8+8+8)
; IN <= A = Multiplicand
;		DE = Multiplier
; OUT => HL = product
		ld		b, a					; counter = multiplicand
		ld		hl, 0					; initialise result
mult8loop:	
		add		hl, de					; add multiplier to result
		djnz	mult8loop				; decrease multiplicand. Is multiplicand = 0? No, do it again
		ret								; Yes, exit routine
