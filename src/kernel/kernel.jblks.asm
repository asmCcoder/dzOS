;******************************************************************************
; kernel_jblks.asm
;
; Kernel Jumpblocks
; for dastaZ80's dzOS
; by David Asta (Apr 2019)
;
; Version 1.0.0
; Created on 25 Apr 2019
; Last Modification 25 Apr 2019
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
#include "exp/kernel.exp"

		.ORG	KRN_JBLK_START

		jp		F_KRN_WRSTR
		jp		F_KRN_RDCHARECHO
		jp		F_KRN_TOUPPER
		jp		F_KRN_PRN_BYTES
		jp		F_KRN_PRN_BYTE
		jp		F_KRN_PRN_WORD
		jp		F_KRN_PRINTABLE
		jp		F_KRN_EMPTYLINES
		jp		F_KRN_STRCMP
		jp		F_KRN_STRCPY
		jp		F_KRN_SETMEMRNG
		jp		F_KRN_ASCII2HEX
		jp		F_KRN_HEX2ASCII
		jp		F_KRN_BIN2BCD4
		jp		F_KRN_BIN2BCD6
		jp		F_KRN_BCD2ASCII
		jp		F_KRN_BITEXTRACT
		jp		F_KRN_F16_READBOOTSEC
		jp		F_KRN_F16_SEC2BUFFER
		jp		F_KRN_F16_CLUS2SEC
		jp		F_KRN_F16_GETFATCLUS
		jp		F_KRN_F16_LOADEXE2RAM
		jp		F_KRN_F16_GETHHMM
		jp		F_KRN_F16_GETDDMMYYYY

		.ORG	KRN_JBLK_END
				.BYTE	0
		.END