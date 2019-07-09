;******************************************************************************
; romtrail.asm
;
; This file just fills the free ROM space, so that the binary is exactly 8192 bytes
; for dastaZ80's dzOS
; by David Asta (Jul 2019)
;
; Version 1.0.0
; Created on 09 July 2019
; Last Modification 09 July 2019
;******************************************************************************
; CHANGELOG
; 	-
;******************************************************************************
; --------------------------- LICENSE NOTICE ----------------------------------
; This file is part of dzOS
; Copyright (C) 2017-2019 David Asta

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

#include "src/includes/equates.inc"

	.ORG	FREEROM_START
				.FILL	FREEROM_SIZE, 0

	.ORG	FREEROM_END
				.BYTE	0
		.END