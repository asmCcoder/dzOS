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
;------------------------------------------------------------------------------
F_KRN_UDIV16:
; Divides two unsigned 16-bit numbers
; Returns quotient and remainder
; IN <= HL = dividend
;		DE = divisor
; OUT => HL = quotient
;		 DE = remainder
;		 Z Flag set if remainder = 0, otherwise 0
		ld		c, l					; c = low byte of dividend
		ld		a, h					; A = high byte of dividend
		ld		hl, 0					; initialise remainder HL
		ld		b, 16					; 16 bits in dividend
		or		a						; clear Carry flag
udiv16loop:
		rl		c						; carry next bit of quotien to bit 0
		rla								; shift remaining bytes
		rl		l
		rl		h						; clear Carry since HL was 0
		push	hl						; backup HL. Current remainder
		sbc		hl, de					; remainder - divisor. Carry flag set if borrow
		ccf								; invert Carry flag
		jr		c, udiv16drop			; did subtract borrow? No (was inverted), loop again, remainder is >= dividend
		ex		(sp), hl				; yes, restore remainder
udiv16drop:		
		inc		sp						; drop remainder
		inc		sp						;	from top of Stack
		djnz	udiv16loop				; all 16 bits done? No, loop again
		ex		de, hl					; yes, DE = remainder
		rl		c						; carry to C
		ld		l, c					; L = low byte of quotient
		rla
		ld		h, a					; H = high byte of quotient
		or		a						; clear Carry flag
		; set flag Z if remainder = 0
		push	hl						; backup HL. Quotient
		ld		hl, 0
		sbc		hl, de					; HL = HL - DE
		pop		hl						; restore HL. Quotient
		ret