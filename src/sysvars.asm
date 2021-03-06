;******************************************************************************
; sysvars.asm
;
; System Variables
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
;==============================================================================
; Buffers
;==============================================================================
;		.ORG	SYSVARS
		.ORG	ACIA_BUFFERS_END
buffer_cmd:			.EXPORT			buffer_cmd
				.FILL	16, 0

buffer_parm1:		.EXPORT			buffer_parm1
				.FILL	16, 0

buffer_parm1_val:	.EXPORT			buffer_parm1_val
				.FILL	16, 0

buffer_parm2:		.EXPORT			buffer_parm2
				.FILL	16, 0

buffer_parm2_val:	.EXPORT			buffer_parm2_val
				.FILL	16, 0

buffer_pgm:			.EXPORT			buffer_pgm
				.FILL	32, 0			; general buffer from programs

secs_per_clus:		.EXPORT			secs_per_clus
				.BYTE	0

secs_per_fat:		.EXPORT			secs_per_fat
				.BYTE	0, 0

num_fats:			.EXPORT			num_fats
				.BYTE 	0

reserv_secs:		.EXPORT			reserv_secs
				.BYTE 	0, 0

clus2secnum:		.EXPORT			clus2secnum
				.BYTE 	0, 0

root_dir_start:		.EXPORT			root_dir_start
				.BYTE 	0, 0

root_dir_sectors:	.EXPORT			root_dir_sectors
				.BYTE	0, 0

cur_dir_start:		.EXPORT			cur_dir_start
				.BYTE 	0, 0

file_attributes:	.EXPORT			file_attributes
				.BYTE 	0

cur_sector:		.EXPORT			cur_sector
				.BYTE 	0, 0

        .ORG	SYSVARS_END
		        .BYTE	0
        .END