;******************************************************************************
; kernel.rtc.asm
;
; Kernel's Real-Time Clock routines
; for dastaZ80's dzOS
; by David Asta (Jul 2019)
;
; Version 1.0.0
; Created on 10 July 2019
; Last Modification 10 July 2019
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

;==============================================================================
; Real-Time Clock Routines
;==============================================================================
;------------------------------------------------------------------------------
F_KRN_RTC_GETTIME:		.EXPORT		F_KRN_RTC_GETTIME
; Gets the Time (hours, minutes, seconds) from the RTC module
; OUT => sysvars.cur_file_timemod_hh = Hours in Hexadecimal notation
;		 sysvars.cur_file_timemod_mm = Minutes in Hexadecimal notation
;		 sysvars.cur_file_timemod_ss = Seconds in Hexadecimal notation

		; ToDo - get hh mm ss from RTC. Right now is 11:12:13 for testing
		ld		a, $11
		ld		(cur_file_timemod_hh), a
		ld		a, $12
		ld		(cur_file_timemod_mm), a
		ld		a, $13
		ld		(cur_file_timemod_ss), a
		ret
;------------------------------------------------------------------------------
F_KRN_RTC_GETDATE:		.EXPORT		F_KRN_RTC_GETDATE
; Gets the Date (day, month, year) from the RTC module
; OUT => sysvars.cur_file_datemod_dd = Day in Hexadecimal notation
;		 sysvars.cur_file_datemod_mm = Month in Hexadecimal notation
;		 sysvars.cur_file_datemod_yyyy = Year in Hexadecimal notation

		; ToDo - get dd mm yyyy from RTC. Right now is 04/10/1974 for testing
		ld		a, $04
		ld		(cur_file_datemod_dd), a
		ld		a, $10
		ld		(cur_file_datemod_mm), a
		ld		hl, $1974
		ld		(cur_file_datemod_yyyy), hl
		ret
