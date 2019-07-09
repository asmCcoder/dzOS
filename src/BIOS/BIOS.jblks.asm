;******************************************************************************
; BIOS_jblks.asm
;
; BIOS Jumpblocks
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
#include "exp/BIOS.exp"

		.ORG	BIOS_JBLK_START

		jp		F_BIOS_WBOOT
		jp		F_BIOS_SYSHALT
		jp		F_BIOS_CF_INIT
		jp		F_BIOS_CF_BUSY
		jp		F_BIOS_CF_READ_SEC
		jp		F_BIOS_CF_WRITE_SEC
		jp		F_BIOS_CF_DIAGNOSDRV
		jp		F_BIOS_CLRSCR
		jp		F_BIOS_CONIN
		jp		F_BIOS_CONOUT

		.ORG	BIOS_JBLK_END
				.BYTE	0
		.END