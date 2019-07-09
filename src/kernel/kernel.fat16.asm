;******************************************************************************
; kernel.fat16.asm
;
; Kernel's FAT16 routines
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
; FAT16 Routines
;==============================================================================
; FAT16 disk layout
;	boot sector				1 sector
;	fat 1					248 sectors
;	fat 2					248 sectors
;	root dir
;	cluster 2				512 * 4 = 2048 sectors
;	cluster 3				512 * 4 = 2048 sectors
;	...						512 * 4 = 2048 sectors
;------------------------------------------------------------------------------
F_KRN_F16_READBOOTSEC:	.EXPORT		F_KRN_F16_READBOOTSEC
; Reads the Boot Sector (at sector 0)
		; read 512 bytes (from First Sector) into RAM CF_BUFFER_START
		ld		de, 0
		ld		bc, 0
		call	F_BIOS_CF_READ_SEC		; read 1 sector (512 bytes)

		; last 2 bytes (0x257E and 0x257F) must be 55 AA (signature indicating that this is a valid boot sector)
		ld		a, (CF_BUFFER_END - 1)
		cp		55h
		jp		nz, error_bootsignature
		ld		a, (CF_BUFFER_END)
		cp		$AA
		jp		nz, error_bootsignature
		; 0x003 = OEM ID (8 bytes)
;		ld		hl, msg_oemid
;		call	F_KRN_WRSTR				; Output message
;		ld		b, 8					; counter = 8 bytes
;		ld		hl, CF_BUFFER_START + 3h ; point HL to offset 3h in the buffer
;		call	F_KRN_PRN_BYTES
		; 0x00B = BytesPerSector (2 bytes)
		ld		de, (CF_BUFFER_START + $0B)	; store it in DE for the later calculation of root_dir_sectors
		; 0x00D = SectorsPerCluster (1 byte)
		ld		hl, (CF_BUFFER_START + $0D)
		ld		(secs_per_clus), hl
		; 0x00E = ReservedSectors (2 bytes)
		ld		hl, (CF_BUFFER_START + $0E)
		ld		(reserv_secs), hl
		ld		bc, (reserv_secs)		; store it in BC for the later calculation of clus2secnum
		; 0x010 = NumberFATs (1 byte)
		ld		a, (CF_BUFFER_START + $10)
		ld		(num_fats), a
		; root_dir_sectors = (32 bytes * RootEntries) / BytesPerSector
		ld		hl, (CF_BUFFER_START + $11)	; 0x011 = RootEntries (2 bytes)
		ld		a, 32						; 32 bytes
		ex		de, hl						; DE = RootEntries
		call	F_KRN_MULTIPLY816_SLOW		; HL = RootEntries * 32 bytes
		ld		de, (CF_BUFFER_START + $0B)	; 0x00B = BytesPerSector (2 bytes)
		call	F_KRN_UDIV16				; HL = (RootEntries * 32 bytes) / BytesPerSector
		ld		(root_dir_sectors), hl
		; 0x016 = SectorsPerFAT (2 bytes)
		ld		hl, (CF_BUFFER_START + $16)
		ld		(secs_per_fat), hl
		; clus2secnum = reserv_secs + num_fats * secs_per_fat + root_dir_sectors
		ld		a, (num_fats)
		ld		de, (secs_per_fat)
		call	F_KRN_MULTIPLY816_SLOW		; HL = num_fats * secs_per_fat
		ld		bc, (reserv_secs)
		add		hl, bc						; HL = reserv_secs + num_fats * secs_per_fat
		ld		bc, (root_dir_sectors)
		add		hl, bc						; HL = reserv_secs + num_fats * secs_per_fat + root_dir_sectors
		ld		(clus2secnum), hl
		; 0x02B = Volume Label (11 bytes)
;		ld		hl, msg_vollabel
;		call	F_KRN_WRSTR				; Output message
;		ld		b, 11					; counter = 11 bytes
;		ld		hl, CF_BUFFER_START + $2B ; point HL to offset 2Bh in the buffer
;		call	F_KRN_PRN_BYTES
		; 0x036 = File System (8 bytes)
;		ld		hl, msg_filesys
;		call	F_KRN_WRSTR				; Output message
		ld		b, 8					; counter = 8 bytes
		ld		hl, CF_BUFFER_START + $36	; point HL to offset 36h in the buffer
		call	F_KRN_PRN_BYTES
		call	check_isFAT16			; check if file system is FAT16
		; calculate Root Directory start position and set it as Current Directory
		; 		root_dir_start = (secs_per_fat * num_fats) + reserv_secs
;		ld		bc, (secs_per_fat)
;		ld		de, (num_fats)
;		call	F_KRN_MULTIPLY			; HL = (SectorsPerFAT * NumberFATs)
		ld		a, (num_fats)
		dec		a
		ld  	b, a
		ld		hl, (secs_per_fat)
		ld		de, (secs_per_fat)
loopmult:
		add		hl, de
		djnz	loopmult

		ld		bc, (reserv_secs)
		add		hl, bc					; HL = (SectorsPerFAT * NumberFATs) + ReservedSectors
		ld		(root_dir_start), hl
		ld		(cur_dir_start), hl		; set roor as current directory
		ret
check_isFAT16:
		push	hl						; backup HL
		ld		hl, CF_BUFFER_START + $36	; point HL to offset 36h in the buffer
		ld		a, (hl)
		cp		'F'						; is it character F?
		jp		nz, error_notFAT16		; no, print message and halt computer
		inc 	hl						; yes, continue
		ld		a, (hl)
		cp		'A'						; is it character A?
		jp		nz, error_notFAT16		; no, print message and halt computer
		inc 	hl						; yes, continue
		ld		a, (hl)
		cp		'T'						; is it character T?
		jp		nz, error_notFAT16		; no, print message and halt computer
		inc 	hl						; yes, continue
		ld		a, (hl)
		cp		'1'						; is it character 1?
		jp		nz, error_notFAT16		; no, print message and halt computer
		inc 	hl						; yes, continue
		ld		a, (hl)
		cp		'6'						; is it character 6?
		jp		nz, error_notFAT16		; no, print message and halt computer
		pop		hl						; restore HL
		ret
error_notFAT16:
		ld		hl, error_4001
		call	F_KRN_WRSTR				; Output message
		call	F_BIOS_SYSHALT
error_bootsignature:
		ld		hl, error_4002
		call	F_KRN_WRSTR				; Output message
		call	F_BIOS_SYSHALT

;------------------------------------------------------------------------------
F_KRN_F16_SEC2BUFFER:	.EXPORT		F_KRN_F16_SEC2BUFFER
; Loads a Sector (512 bytes) and puts the bytes into RAM CF_BUFFER_START
; IN <=  HL = Sector number
; OUT => CF_BUFFER_START is filled with the read 512 bytes
		ex		de, hl					; D sector address LBA 1 (bits 8-15)
										; E sector address LBA 0 (bits 0-7)
		ld		bc, 0					; sector address LBA 3 (bits 24-27) and sector address LBA 2 (bits 16-23)
		call	F_BIOS_CF_READ_SEC		; read 1 sector (512 bytes)
		ret
;------------------------------------------------------------------------------
F_KRN_F16_CLUS2SEC:		.EXPORT		F_KRN_F16_CLUS2SEC
; Converts Cluster number to corresponding Sector number
;	ClusterSectorNumber = clus2secnum + (ClusterNum - 2) * secs_per_clus
; IN <= DE = Cluster number
; OUT => HL = Sector number
		dec		de						; DE = (ClusterNum - 1)
		dec		de						; DE = (ClusterNum - 2)
		ld		a, (secs_per_clus)		; A = secs_per_clus
		call	F_KRN_MULTIPLY816_SLOW	; HL = DE * A = (ClusterNum - 2) * secs_per_clus
		ld		de, (clus2secnum)		; DE = clus2secnum
		add		hl, de					; HL = clus2secnum + ((ClusterNum - 2) * secs_per_clus)
		ret
;------------------------------------------------------------------------------
F_KRN_F16_GETFATCLUS:	.EXPORT		F_KRN_F16_GETFATCLUS
; Get list of all the clusters of a file from FAT
; IN <= HL First cluster number
; OUT => list of clusters (2 bytes each) stored in sysvars.cur_file_clusterlist
		push	hl						; backup HL. First cluster number
		; FAT sector = sysvars.reserv_secs
		ld		hl, (reserv_secs)		; HL = sysvars.reserv_secs
		call	F_KRN_F16_SEC2BUFFER	; read FAT into RAM buffer
		pop		hl						; restore HL. First cluster number
		; get next cluster from FAT
		add		hl, hl					; the byte to read is at CF_BUFFER_START + HL * 2
		ld		de, CF_BUFFER_START
		add		hl, de
		ld		de, cur_file_clusterlist; pointer to sysvars.cur_file_clusterlist
getfatloop:
		; store bytes pair in sysvars.buffer_pgm
		ld		a, (hl)
		ld		(de), a					; store first byte
		inc		de						; pointer to next byte in sysvars.buffer_pgm
		inc		hl						; pointer to next byte in CF_BUFFER_START
		ld		a, (hl)
		ld		(de), a					; store second byte
		cp		$FF						; if A = FF, then this was last cluster
		ret		z						; yes, exit routine
		inc		de						; no, pointer to next pair of bytes in sysvars.buffer_pgm 
		inc		hl						; pointer to next pair of bytes in CF_BUFFER_START
		jp		getfatloop				; get next pair of bytes
;------------------------------------------------------------------------------
F_KRN_F16_LOADEXE2RAM:	.EXPORT		F_KRN_F16_LOADEXE2RAM
; Load an executable file into RAM, so it can be run
; IN <= DE First cluster number
; OUT => Z flag set if an error occurred
;		 DE = load address
;		 All bytes of the executable file are loaded into 
;			RAM at the address location found in the file header
; sysvars.buffer_pgm usage:
;		buffer_pgm + 0 = (2 bytes) original load address from header
;		buffer_pgm + 2 = (2 bytes) destination address in RAM
;		buffer_pgm + 4 = (1 byte) cluster counter within cur_file_clusterlist
;		buffer_pgm + 5 = (1 byte) remaining sectors to be read within a cluster
		ld		a, 0
		ld		(buffer_pgm + 4), a		; cluster counter within cur_file_clusterlist
		ld		a, (secs_per_clus)		; counter. Remaining sectors
		ld		(buffer_pgm + 5), a		; remaining sectors to be read within a cluster

		push	de						; backup DE. First cluster number
		ex		de, hl					; HL = First cluster number
		call	F_KRN_F16_GETFATCLUS	; read clusters from FAT into sysvars.cur_file_clusterlist
		pop		de						; restore first cluster number
		call	F_KRN_F16_CLUS2SEC		; convert cluster number to sector number
		ld		(cur_sector), hl		; backup HL. 1st Sector number
		call	F_KRN_F16_SEC2BUFFER	; load sector to buffer
		; Header:
		;	to keep compatibility with binaries created with SDCC, the header is:
		;		1 byte for the opcode C3 (jump)
		;		2 bytes for the load address in little-endian format
		ld		hl, (CF_BUFFER_START + 3)	; get load address
		ld		(buffer_pgm), hl		; store load address
		ld		(buffer_pgm + 2), hl	; next load address = original load address
loadsecsloop: ; >>>> ToDo - Should only load number of bytes equal to file size. Otherwise is loading rubbish at the end <<<<
		; copy bytes from buffer to RAM (starting at next load address)
		ld		de, (buffer_pgm + 2)	; restore next load address
		ld		hl, CF_BUFFER_START		; pointer to first executable byte
		ld		bc, 512					; 512 bytes (entire sector) will be copied
		ldir							; copy n bytes from HL to DE
		ld		(buffer_pgm + 2), de	; backup next load address
		; count out the just read sector 
		; and check if need to read more sector or next cluster
		ld		a, (buffer_pgm + 5)		; remaining sectors to be read within a cluster
		dec		a						; count out the just read sector 
		cp		0						; did we copy all sectors of the cluster?
		jp		z, nextcluster			; yes, load next cluster
										; no, continue
		ld		(buffer_pgm + 5), a		; store remaining sectors to be read within a cluster
		; change pointer to next sector
		ld		hl, (cur_sector)
		inc		hl						; next sector
		ld		(cur_sector), hl		; backup sector number
		; load sector to buffer
		call	F_KRN_F16_SEC2BUFFER
		jp		loadsecsloop			; copy another sector
nextcluster:
		; get next cluster from sysvars.cur_file_clusterlist
		ld		a, (buffer_pgm + 4)		; A = cluster counter within cur_file_clusterlist
		ld		d, 0					; clear D. cluster counter is only 1 byte
		ld		e, a 				; E = cluster counter within cur_file_clusterlist
		ld		hl, cur_file_clusterlist
		add		hl, de					; HL = cur_file_clusterlist + cluster counter
		ld		a, (hl)					; get 1st byte of next cluster number pair
		cp		$FF						; is next cluster number $FF?
		jp		z, alldone				; yes, then all cluster were read already
										; no, continue
		ld		e, a					; DE = next cluster number (1st byte)
		inc		hl						; point to 2nd byte of next cluster number pair
		ld		a, (hl)					; get 2nd byte of next cluster number pair
		ld		d, a					; DE = next cluster number (2nd byte)
		
		ld		hl, buffer_pgm + 4		; HL = pointer to cluster counter within cur_file_clusterlist
		inc		(hl)					; increase counter to next cluster number (1st byte)
		inc		(hl)					; increase counter to next cluster number (2nd byte)
		call	F_KRN_F16_CLUS2SEC		; convert cluster number to sector number
		ld		(cur_sector), hl		; backup HL. Sector number
		call	F_KRN_F16_SEC2BUFFER	; load sector to buffer
		ld		a, (secs_per_clus)		; restore sectors
		ld		(buffer_pgm + 5), a		;	per cluster counter
		jp		loadsecsloop			; load all sectors of the cluster
alldone:
		ld		de, (buffer_pgm)		; restore load address from header
		ret
;------------------------------------------------------------------------------
F_KRN_F16_GETENTRYDATA:	.EXPORT		F_KRN_F16_GETENTRYDATA
; Gets data referring to a directory entry and stores it in sysvars
; IN <= buffer_pgm = first byte of the address where the entry is located
; OUT => cur_file_name			Name 			8 bytes
;		 cur_file_extension		Extension		3 bytes
;		 cur_file_attribs		Attributes		1 byte
;		 cur_file_timemod		Time Modif		2 bytes
;		 cur_file_datemod		Date Modif		2 bytes
;		 cur_file_1stcluster	First Cluster	2 bytes
;		 cur_file_size			File size		4 bytes
		; 0x00 	8 bytes 	File name
		ld		hl, (buffer_pgm)
		ld		de, cur_file_name
		ld		b, 8
		call	F_KRN_STRCPY
		; 0x08 	3 bytes 	File extension
		ld		hl, (buffer_pgm)
		ld		bc, $8
		add		hl, bc
		ld		de, cur_file_extension
		ld		b, 3
		call	F_KRN_STRCPY
		; 0x0b 	1 byte 		File attributes
		;	Bit 0	0x01	Indicates that the file is read only.
		;	Bit 1	0x02	Indicates a hidden file. Such files can be displayed if it is really required.
		;	Bit 2	0x04	Indicates a system file. These are hidden as well.
		;	Bit 3	0x08	Indicates a special entry containing the disk's volume label, instead of describing a file. This kind of entry appears only in the root directory.
		;	Bit 4	0x10	The entry describes a subdirectory.
		;	Bit 5	0x20	This is the archive flag. This can be set and cleared by the programmer or user, but is always set when the file is modified. It is used by backup programs.
		;	Bit 6	Not used; must be set to 0.
		; 	Bit 7	Not used; must be set to 0.
		ld		hl, (buffer_pgm)
		ld		bc, $b
		add		hl, bc
		ld		a, (hl)
		ld		(cur_file_attribs), a

		; 0x0c 	1 bytes 	Reserved
		; 0x0d	1 byte		Created time refinement in 10ms (0-199)
		; 0x0e 	2 bytes 	Time created
		; 0x10 	2 bytes 	Date created
		; 0x12	2 bytes		Last access date
		; 0x14	2 bytes		First cluster (high word)

		; 0x16	2 bytes		Time modified
		ld		hl, (buffer_pgm)
		ld		bc, $16
		add		hl, bc
		ld		de, cur_file_timemod
		ld		b, 2
		call	F_KRN_STRCPY
		; 0x18	2 bytes		Date modified
		ld		hl, (buffer_pgm)
		ld		bc, $18
		add		hl, bc
		ld		de, cur_file_datemod
		ld		b, 2
		call	F_KRN_STRCPY
		; 0x1a	2 bytes		First cluster (low word)
		ld		hl, (buffer_pgm)
		ld		bc, $1a
		add		hl, bc
		ld		de, cur_file_1stcluster
		ld		b, 2
		call	F_KRN_STRCPY
		; 0x1c 	4 bytes 	File size in bytes
		ld		hl, (buffer_pgm)
		ld		bc, $1c
		add		hl, bc
		ld		de, cur_file_size
		ld		b, 4
		call	F_KRN_STRCPY
		ret
;------------------------------------------------------------------------------
F_KRN_F16_GETHHMM:		.EXPORT		F_KRN_F16_GETHHMM
; Gets the hour (HH) and the minutes (MM) from 2 bytes that store a time
; IN <= H = MSB of the stored time
;		L = LSB of the stored time
; OUT => sysvars.cur_file_timemod_hh = byte representing the hour in Hexadecimal (0-23)
;		 sysvars.cur_file_timemod_mm = byte representing the minutes in Hexadecimal (0-59)
; 		|---- MSB ----| |---- LSB ----|
;		7 6 5 4 3 2 1 0 7 6 5 4 3 2 1 0
;		h h h h h m m m m m m x x x x x
;	hhhhh = binary number of hours (0-23)
;	mmmmmm = binary number of minutes (0-59)
;	xxxxx = binary number of two-second periods (0-29), representing seconds 0 to 58.
		; extract hour (hhhhh) from MSB
 		ld		e, h					; we are only interested in the MSB now
		ld		d, 5					; we want to extract 5 bits
		ld		a, 3					; starting at position bit 3
		push	hl						; backup HL. Stored time
		call	F_KRN_BITEXTRACT
		ld		(cur_file_timemod_hh), a	; store hour value in sysvars
		; extract minute part (mmm) from MSB
		pop		hl						; restore HL. Stored time
		ld		e, h					; we are only interested in the MSB now
		ld		d, 3					; we want to extract 3 bits
		ld		a, 0					; starting at position bit 0
		push	hl						; backup HL. Stored time
		call	F_KRN_BITEXTRACT
		ld		(cur_file_timemod_mm), a	; store minute part value in sysvars
		ld		hl, cur_file_timemod_mm	; get rid
		sla		(hl)					;   of the
		sla		(hl)					;   unwanted
		sla		(hl)					;   bits
		; extract minute part (mmm) from LSB
		pop		hl						; restore HL. Stored time
		ld		e, l					; we are only interested in the LSB now
		ld		d, 3					; we want to extract 3 bits
		ld		a, 5					; starting at position bit 5
		call	F_KRN_BITEXTRACT
		ld		b, a					; store minute part value in B for later
		; combine both minutes parts
		ld		a, (cur_file_timemod_mm)
		or		b
		ld		(cur_file_timemod_mm), a	; store minute value in sysvars
		ret
;------------------------------------------------------------------------------
F_KRN_F16_GETDDMMYYYY:	.EXPORT		F_KRN_F16_GETDDMMYYYY
; Gets the day (DD), month (MM) and year (YYYY) from 2 bytes that store a date
; IN <= H = MSB of the stored date
;		L = LSB of the stored date
; OUT => sysvars.cur_file_timemod_dd = byte representing the day in Hexadecimal (1-31)
;		 sysvars.cur_file_timemod_mm = byte representing the month in Hexadecimal (1-12)
;		 sysvars.cur_file_timemod_yyyy = 2 bytes representing the year in Hexadecimal
; 		|---- MSB ----| |---- LSB ----|
;		7 6 5 4 3 2 1 0 7 6 5 4 3 2 1 0
;		y y y y y y y m m m m d d d d d
;	yyyyyyy = binary year offset from 1980 (0-119), representing the years 1980 to 2099
;	mmmm = binary month number (1-12)
; 	ddddd = indicates the binary day number (1-31)
; extract year (yyyyyyy) from MSB 0x19
 		ld		e, h					; we are only interested in the MSB now
 		ld		d, 7					; we want to extract 7 bits
		ld		a, 1					; starting at position bit 1
		push	hl						; backup HL. Stored date
		call	F_KRN_BITEXTRACT
		ld		h, 0
		ld		l, a
		ld		bc, 1980				; year is the number of years since 1980
		add		hl, bc
		ld		(cur_file_datemod_yyyy), hl		; store year value in sysvars
 		; extract month part (mmm) from LSB 0x18
		pop		hl						; restore HL. Stored date
 		ld		e, l					; we are only interested in the LSB now
 		ld		d, 3					; we want to extract 3 bits
 		ld		a, 5					; starting at position bit 5
		push	hl						; backup HL. Stored date
 		call	F_KRN_BITEXTRACT
 		ld		(cur_file_datemod_mm), a	; store month part in sysvars
 		; extract month part (m) from MSB 0x19
		pop		hl						; restore HL. Stored date
 		ld		e, h					; we are only interested in the MSB now
		ld		d, 1					; we want to extract last bit
		ld		a, 0					; starting at position bit 0
		push	hl						; backup HL. Stored date
		call	F_KRN_BITEXTRACT
 		cp		1						; was the bit set?
		jp		z, setit				; yes, then set the 3th bit on the extracted month part too
		ld		hl, (cur_file_datemod_mm) 
		res		3, (hl)					; no, then reset the 3th bit on the extracted month part (mmm)
		jp		extrday
setit:
		ld		hl, (cur_file_datemod_mm) 
		set		3, (hl)					; set the 3th bit on the extracted month part (mmm)
 		; extract day (ddddd) from LSB 0x18
extrday:
		pop		hl						; restore HL. Stored date
 		ld		e, l					; we are only interested in the LSB now
 		ld		d, 5					; we want to extract 5 bits
 		ld		a, 0					; starting at position bit 0
 		call	F_KRN_BITEXTRACT
 		ld		(cur_file_datemod_dd), a	; store day in sysvars
		ret
;------------------------------------------------------------------------------
F_KRN_F16_SAVEFILE:		.EXPORT		F_KRN_F16_SAVEFILE
; Saves blocks of bytes in RAM to a file
; Updates FAT entries
; Creates Directory entry in Root Directory
; IN <= sysvars.cur_file_name = name for new file
;		sysvars.cur_file_extension = extension for new file
;		DE = start_address in RAM
;		HL = end_address in RAM


; TESTS
; It should write to:
; 	04 00 
; 	48 00 
; 	4A 00 
; 	54 00 
; 	56 00 
; 	58 00 
; 	5A 00 
; 	5C 00
; 	5E 00
; 	60 00
; 	62 00
; 	64 00
; 	66 00
; 	68 00
; 	6A 00
; 	6C 00
; 	6E 00
; 	70 00
; 	72 00
; 	74 00
; 	76 00
; 	78 00
; 	7A 00
; 	7C 00
; 	7E 00
; 	80 00
; 	82 00
; 	84 00
; TESTS

		; FAT sector = sysvars.reserv_secs
		push	de						; backup DE. start_address in RAM
		push	hl						; backup HL. end_address in RAM
		ld		hl, (reserv_secs)		; HL = sysvars.reserv_secs
		call	F_KRN_F16_SEC2BUFFER	; read FAT into RAM buffer
		pop		hl						; restore HL. end_address in RAM
		pop		de						; restore DE. start_address in RAM
		push	de						; backup DE. start_address in RAM
		push	hl						; backup HL. end_address in RAM
		; get the list of clusters that will be used for storing the file
		call	F_KRN_F16_CLUSTERS4NEWFILE		; OUT => A = number of clusters needed for a new file
		call	F_KRN_F16_GETCLUSLST4NEWFILE	; OUT => list is stored in sysvars.cur_file_clusterlist
		; change "partition state" to FF F7
		ld		a, $F7
;		call	F_KRN_F16_UPD_PARTSTATE
		pop		hl						; restore HL. end_address in RAM
		pop		de						; restore DE. start_address in RAM
doanothercluster:
		ld		ix, cur_file_clusterlist
		ld		a, (ix + 0)				; number of clusters
		cp		1						; is it 1?
		jp		z, lastcluster			; yes, then it's last cluster
										; no, then save 512 bytes to disk, secs_per_clus times
		inc		ix						; pointer to first cluster
sectorsloop:
		; copy RAM bytes to CF Buffer
		ex		de, hl					; HL =  start_address in RAM
		ld		de, CF_BUFFER_START
		ld		bc, 512					; buffer is 512 bytes
		ldir							; copy to buffer (from Hl to DE)
		; Determine which is the 1st sector of the cluster
		ld		d, (ix + 1)				; D = next cluster LSB
		ld		e, (ix)					; E = next cluster MSB
		call	F_KRN_F16_CLUS2SEC		; Converts Cluster number to corresponding Sector number. OUT => HL = Sector number
		ld		a, (secs_per_clus)		; how many sectors per cluster?
		ld		(cur_sector), a			; store how many in sysvars.cur_sector
		ex		de, hl					; D sector address LBA 1 (bits 8-15)
										; E sector address LBA 0 (bits 0-7)
		ld		bc, 0					; sector address LBA 3 (bits 24-27) and sector address LBA 2 (bits 16-23)
doanothersector:
;		call	F_BIOS_CF_WRITE_SEC		; Write a Sector (512 bytes) byte by byte from CF_BUFFER_START in RAM to the CF card
		push 	de
		push	hl
		ld		hl, test_wrclus
		call	F_KRN_WRSTR
		pop		de
		pop		hl
		push 	de
		push	hl
		call	F_KRN_PRN_WORD
		pop		de
		pop		hl
		ld		a, (cur_sector)			; How many sectors left?
		dec		a						; counter number of sectors. One sector done
		cp		1						; is it last one?
		jp		z, lastsector			; yes, it is last sector
										; no, do another sector
		ld		(cur_sector), a			; store how many in sysvars.cur_sector
		inc		de						; point to next sector
		ld		bc, 0					; sector address LBA 3 (bits 24-27) and sector address LBA 2 (bits 16-23)
		jp		doanothersector
lastsector:
		inc		de						; point to next sector
		ld		bc, 0					; sector address LBA 3 (bits 24-27) and sector address LBA 2 (bits 16-23)
;		call	F_BIOS_CF_WRITE_SEC		; Write a Sector (512 bytes) byte by byte from CF_BUFFER_START in RAM to the CF card
		push 	de
		push	hl
		ld		hl, test_wrclus
		call	F_KRN_WRSTR
		pop		de
		pop		hl
		push 	de
		push	hl
		call	F_KRN_PRN_WORD
		pop		de
		pop		hl
		ld		hl, cur_file_clusterlist ; counter number of clusters
		dec		(hl)					; One cluster done
		jp		doanothercluster
lastcluster:
		; calculate number of sectors left
		;		IF number of sectors > 1
		;			loop2
		;				read 512 bytes into CF Buffer
		;				save 512 bytes to current sector
		;				decrease number of sectors
		;				IF number of sectors > 1 THE loop2 again
		;				ELSE 	calculate how many bytes
		;						save how many bytes to current sector
		; for each cluster in sysvars.cur_file_clusterlist
		; 	read 512 bytes into CF Buffer, secs_per_clus times and store them in sectors of the cluster
		jp		wrallclustdone
wrallclustdone:
		; ToDo update FAT

		; ToDo create Directory Entry

		; change "partition state" to FF FF
		ld		a, $FF
;		call	F_KRN_F16_UPD_PARTSTATE
		ret
;------------------------------------------------------------------------------
;F_KRN_F16_CHGDIR:		.EXPORT		F_KRN_F16_CHGDIR
;; Changes current directory (cur_dir_start sysvar) of a disk
;		; read 512 bytes (from cur_dir_start) into RAM CF_BUFFER_START
;;		ld		a, (cur_dir_start + 1)
;;		ld		d, a					; sector address LBA 1 (bits 8-15)
;;		ld		a, (cur_dir_start)
;;		ld		e, a					; sector address LBA 0 (bits 0-7)
;;		ld		bc, 0					; sector address LBA 3 (bits 24-27) and sector address LBA 2 (bits 16-23)
;;		call	F_BIOS_CF_READ_SEC		; read 1 sector (512 bytes)
;;		ld		de, CF_BUFFER_START		; DE pointer to the start of the buffer
;		call	F_KRN_SEC2BUFFER		; load sector into RAM buffer
;		; scan current directory for a match to the name specified. Error if not found
;		ld		b, 8					; counter = 8 bytes
;		ld		hl, buffer_parm1_val	; HL pointer to param1
;checkattr:
;		; check file attributes
;		push	de						; backup DE
;		push	hl						; backup HL
;		ex		de, hl
;		ld		de, 0Bh
;		add		hl, de					; HL now points to offset 0x00B File Attributes
;		bit		4, (hl)					; is it a directory?
;		pop		hl						; restore HL
;		pop		de						; restore DE
;		jp		z, nextentry			; no, skip this entry
;										; yes, continue
;loop_search_dir:
;		ld		a, (de)					; load 1 character of the file name
;		cp		SPACE					; spaces are not counted, as names cannot have spaces
;		jp		z, sameentry			; was a space, skip character
;		cpi								; was not a space, compare content of A with HL, and increment HL
;		jp		nz, nextentry			; A is not (HL)
;sameentry:
;		inc		de						; A = (HL). Move DE pointer to next character of the file name
;		djnz	loop_search_dir			; if B is not 0, decrement B and repeat loop
;										; if B is 0, directory was found. Get location (cluster)
;		; 0x14	2 bytes		First cluster (high word)
;		; 0x1a	2 bytes		First cluster (low word)
;		ld		bc, 19					; 0x1a is now 19 bytes ahead of current DE
;		ex		de, hl					; HL pointer to the start of the current entry
;		add		hl, bc					; HL pointer to the start of the current entry + 18
;		ld		a, (hl)					; LSB
;		ld		(cur_dir_start), a
;		ld		(2333h), a
;		inc		hl						; move pointer to 2nd byte
;		ld		a, (hl)					; MSB
;		ld		(cur_dir_start + 1), a
;		ld		(2334h), a
;		jp		getsector				; we got the cluster, now we need the sector for LBA
;nextentry:
;		ld		hl, 32					; each entry is 32 bytes
;		add		hl, de					; HL + DE = start of new entry
;		ex		de, hl					; DE pointer to the start of the new entry
;		ld		hl, buffer_parm1_val	; HL pointer to param1
;		jp		checkattr
;errorchg:
;		ld		hl, error_4003
;		call	F_KRN_WRSTR				; Output message
;getsector:
;		ld		de, (cur_dir_start)		; file start cluster
;		call	F_KRN_CLUS2SEC			; convert cluster (DE) to sector (HL)
;		ld		(cur_dir_start), hl		; update cur_dir_start with the sector
;		ret
;------------------------------------------------------------------------------
;F_KRN_F16_GETENTRYNUM:	.EXPORT		F_KRN_F16_GETENTRYNUM
;; Gets the directory entry number of a given filename
;; IN <= HL pointer to where the filename is stored in RAM
;; OUT => HL contains cluster number of the file in disk
;;		 Z flag set if filename was found
;		push	hl						; backup HL. Pointer to the start of the filename string
;		call	F_KRN_F16_SEC2BUFFER	; load sector for current directory into RAM buffer
;		pop		hl						; restore HL
;		; scan current directory for a match to the name specified. Error if not found
;		ld		b, 15					; counter. There are 512/32=16 entries per directory
;entriesloop:
;		push	hl						; backup HL. Pointer to the start of the filename string
;		push	bc						; backup B. Counter
;		call	F_KRN_F16_CHKENTRY		; check if directory entry is equal to filename
;		pop		bc						; restore B
;		jp		z, getend				; filename found? yes, finish routine
;		pop		hl						; restore HL
;		djnz	entriesloop				; no, check next entry
;		jp		getend					; checked all 16 entries. Filename not found
;entryfound:
;		pop		hl						; restore HL
;		ret
;getend:
;		; >>>> ToDo - Catastrophe!!!! missing a pop hl coming from jp z,getend <<<<
;		; HL = pointer to 1st byte of First cluster (low word) (2 bytes)
;		ret
;------------------------------------------------------------------------------
;F_KRN_F16_CHKENTRY:		.EXPORT		F_KRN_F16_CHKENTRY
;; Check if directory entry is equal to filename
;; IN <= HL pointer to where the filename is stored in RAM
;;		B = directory entry number to check
;; OUT => Z flag set if filename is same as directory entry to check
;;		 HL = pointer to 1st byte of First cluster (low word)
;		push	hl						; backup HL. Pointer to the start of the filename string
;		ld		de, 32					; E 32 bytes per entry
;		ld		a, b					; A directory entry number to check 
;		cp		0						; is it 0 (i.e. first entry)?
;		jp		z, byzero				; no need to multiply by zero
;		call	F_KRN_MULTIPLY816_SLOW	; HL = A * DE = offset of entry to check
;		jp		nobyzero		
;byzero:
;		ld		hl, 0
;nobyzero:
;		ld		de, CF_BUFFER_START		; DE pointer to the start of the buffer
;		call	F_KRN_F16_ENTRY2FILENAME
;		ret
;
;		add		hl, de					; HL 1st byte of entry to check
;		ex		de, hl					; DE 1st byte of entry to check
;		pop		hl						; restore HL. Pointer to the start of the filename string
;		ld		b, 10					; counter = 11 bytes (8 filename, 3 extension) 11-1=10 because of byte 0
;checkattr:								; check file attributes
;		push	de						; backup DE. Pointer to the start of the buffer
;		push	hl						; backup HL. Pointer to the start of the filename string
;		ex		de, hl
;		ld		de, 0Bh					; offset 0x0b (1 byte) contains the File attributes
;		add		hl, de					; HL now points to offset 0x00B File Attributes
;		bit		4, (hl)					; is it a directory?
;		pop		hl						; restore HL
;		pop		de						; restore DE
;		ret		nz						; A is not (HL), exit routine
;loop_search_dir:
;		ld		a, (de)					; load 1 character of the file name
;		cp		SPACE					; spaces are not counted, as names cannot have spaces
;		jp		z, sameentry			; was a space, skip character
;		cpi								; was not a space, compare content of A with HL, and increment HL
;		ret		nz						; A is not (HL), exit routine
;		; discard dot in the filename of the param1
;		ld		a, (hl)					; A is (HL). Check if it's a dot and then discard it
;		cp		'.'						; is it a dot?
;		jp		nz, sameentry			; no, continue
;		inc		hl						; yes, skip it
;sameentry:
;		inc		de						; A = (HL). Move DE pointer to next character of the file name
;		djnz	loop_search_dir			; if B is not 0, decrement B and repeat loop
;										; if B is 0, directory was found. Get location (cluster)
;		; 0x14	2 bytes		First cluster (high word)
;		; 0x1a	2 bytes		First cluster (low word)
;		ld		bc, 16					; 0x1a is now 16 bytes ahead of current DE
;		ex		de, hl					; HL pointer to the start of the current entry
;		add		hl, bc					; HL pointer to the start of the current entry + 16
;		ret
;------------------------------------------------------------------------------
F_KRN_F16_CLUSTERS4NEWFILE:
; Calculate number of clusters needed for a new file that will be store in disk
; IN <= DE = start_address
;		HL = end_address
; OUT => A = number of clusters needed for a new file
;
; total_bytes = end_addr - start_addr
; total_sectors = total_bytes / bytes_per_sector
; total_clusters = total_sectors / sectors_per_cluster
;
; For a 32KB RAM system:
; 		23168 free bytes RAM / 512 bytes per sector = 46 sectors
;		46 sectors / 4 sectors per cluster = 12 clusters
;
; For a 64KB RAM system:
;		55936 free bytes RAM / 512 bytes per sector = 110 sectors
;		110 sectors / 4 sectors per cluster = 5 clusters

		; total_bytes = end_addr - start_addr
		or		a						; Clear Carry Flag
		sbc		hl, de					; HL = total_bytes
		; total_sectors = total_bytes / bytes_per_sector
		ld		de, 512					; DE = bytes_per_sector
		call 	F_KRN_UDIV16			; HL = HL / DE, DE = remainder, S Flag set if DE > 0
		jp		z, nomoresectors		; remainder = 0 ?
		inc		hl						; no, add 1 extra sector
		; at this point HL = total_sectors
nomoresectors:
		; total_clusters = total_sectors / sectors_per_cluster
		ld		a, (secs_per_clus)
		ld		d, 0
		ld		e, a					; DE = sectors_per_cluster
		call 	F_KRN_UDIV16			; HL = HL / DE, DE = remainder, S Flag set if DE > 0
		jp		z, nomoreclusters		; remainder = 0 ?
		inc		hl						; no, add 1 extra cluster
nomoreclusters:		
		; at this point HL = total_clusters
		ld		a, l					; A = total_clusters
		ret
;------------------------------------------------------------------------------
F_KRN_F16_GETNEXTFREECLUSTER:
; Gets the offset position (relative to CF_BUFFER_START) of the next
; available free cluster (marked as 00 00)
; IN <= HL = last offset used. From here the count will continue
; OUT => HL = next offset position available
		ld		de, 2					; each entry is 2 bytes
		add		hl, de
		ld		de, CF_BUFFER_START		; DE = pointer to start of CF_BUFFER_START
		ex		de, hl					; HL = start of CF_BUFFER_START, DE = last offset
		add		hl, de					; HL = start of CF_BUFFER_START + last offset used
		; is this cluster available? (marked as 00 00)
nextfreecluster:
		push	hl						; backup HL. Pointer inside CF_BUFFER_START
		ld		a, (hl)					; LSB of the cluster address
		cp		$FF						; is it FF ?
		jp		z, skipcluster			; yes, then we know already that cluster is used, skip it
		ld		e, a					; LSB of the cluster address
		inc		hl						; point to MSB
		ld		d, (hl)					; MSB of the cluster address
		ld		hl, 0
		or		a						; Clear Carry Flag
		sbc		hl, de
		jp		z, freecluster			; HL - DE = 0 ?
										; yes, then return this cluster position
										; no, continue search
skipcluster:
		pop		hl						; restore HL. Pointer inside CF_BUFFER_START
		inc		hl
		inc		hl
		jp		nextfreecluster
freecluster:
		pop		hl						; restore HL. Pointer inside CF_BUFFER_START
		ld		de, CF_BUFFER_START		; DE = pointer to start of CF_BUFFER_START
		sbc		hl, de					; HL = next offset position available
		ret
;------------------------------------------------------------------------------
F_KRN_F16_GETCLUSLST4NEWFILE:
; Gets a list of clusters
; IN <= A = number of clusters needed for a new file
; OUT => list is stored in sysvars.cur_file_clusterlist
;		 1st byte = total number of clusters
;		 rest bytes = the list
		ld		(cur_file_clusterlist), a
		ld		hl, 2					; first 2 entries (0 and 1) in FAT are reserved, so we start at 2
		ld		ix, cur_file_clusterlist + 1	; IX = pointer to sysvar where list will be stored
getclusloop:
		push	af						; backup AF. number of clusters needed
		call	F_KRN_F16_GETNEXTFREECLUSTER	; HL = next offset position available
		ld		(ix), l					; store LSB next offset in sysvar.cur_file_clusterlist
		ld		(ix + 1), h				; store MSB next offset in sysvar.cur_file_clusterlist
		pop		af						; restore AF. number of clusters needed
		dec		a						; decrease number of clusters counter
		cp		0						; number of clusters counter = 0 ?
		ret		z						; yes, exit routine
		inc		bc						; no, increase counter
		inc		bc						;	by 2 bytes
		inc		ix						; move pointer within sysvar.cur_file_clusterlist
		inc		ix						;	by 2 bytes
		jp		getclusloop				; 	get another available cluster
;------------------------------------------------------------------------------
F_KRN_F16_CHK_PARTSTATE:
; Checks FAT's partition state is FF FF
; When a write operation is initiated, the FAT's partition state is changed 
; to FF F7, and only once all disk opeartions have finished, this state is set
; back to FF FF. Therefore, if at boot we found FF F7, this indicates that the
; system was stopped or reset during a write-to-disk operation
; partition state is located at the bytes 2 and 3 of the FAT.
; Checking byte 3 will be enough, as the byte 2 is always FF.
		; FAT sector = sysvars.reserv_secs
		ld		hl, (reserv_secs)		; HL = sysvars.reserv_secs
		call	F_KRN_F16_SEC2BUFFER	; read FAT into RAM buffer
		ld		a, (CF_BUFFER_START + 3); get 3rd byte
		cp		$FF						; is it FF?
		ret		z						; yes, exit routine
		ld		hl, error_4003			; no, show warning message
		call	F_KRN_WRSTR
		ret
;------------------------------------------------------------------------------
F_KRN_F16_UPD_PARTSTATE:
; Update FAT's Partition Status in disk
; IMPORTANT: requires that the FAT is already loaded into CF Buffer RAM
; IN <= A = value of 3rd byte
;		F7 = write-to-disk in process
;		FF = write-to-disk finished
		ld		(CF_BUFFER_START + 3), a	; store F7 in FAT's 3rd byte in Buffer RAM
		ld		hl, (reserv_secs)		; HL = sysvars.reserv_secs
		ex		de, hl					; D sector address LBA 1 (bits 8-15)
										; E sector address LBA 0 (bits 0-7)
		ld		bc, 0					; sector address LBA 3 (bits 24-27) and sector address LBA 2 (bits 16-23)
		call	F_BIOS_CF_WRITE_SEC		; Write FAT back to disk
		ret
;------------------------------------------------------------------------------
;F_KRN_F16_GETCLUSTER:
;; Gets the Cluster number of a directory entry
;; IN <= A = Directory entry number (there are 512/32 = 16 entries in each sector)
;; OUT => DE = Cluster number
;		ld		de, 32
;		call	F_KRN_MULTIPLY816_SLOW	; HL = DE * A = (entry number * 32 bytes per entry)
;		inc		hl						; add 1, to account for entry 0
;
;		; ToDo 
;		;	- Search entry and get First Cluster (low word)
;		;	- Update cur_dir_start with the Cluster number
;		call	F_KRN_F16_SEC2BUFFER	; load sector into RAM buffer
;		ret
;------------------------------------------------------------------------------
;F_KRN_F16_ENTRY2FILENAME:	.EXPORT	F_KRN_F16_ENTRY2FILENAME
;; Converts a directory entry in format FFFFFFFFEEE to FFFFFFFF.EEE00
;; where F is character for Filename and E is character for Extension
;; and 00 is zero terminated byte
;; IN <= DE pointer to start of directory entry to convert
;; OUT => filename is stored in sysvars.buffer_pgm
;		; copy filename
;		ex		de, hl					; HL pointer to start of directory entry to convert
;		ld		de, (buffer_pgm)		; DE pointer of converted filename (sysvars.buffer_pgm)
;		ld		b, 8					; counter = 8 bytes for filename
;		call	filenamecpy				; copy string from HL to DE
;		; insert dot between filename and extension
;		ld		a, '.'
;		ld		(hl), a
;		inc		hl
;		; copy extension
;		ld		b, 3					; counter = 3 bytes for extension
;		call	filenamecpy				; copy string from HL to DE
;		ld		(hl), 0					; insert zero terminated byte
;		ret
;filenamecpy:
;		ld		a, (de)					; 1 character from original string
;		cp		SPACE					; is it a space?
;		jp		z, nocpy				; yes, do not copy it
;		ld		(hl), a					; no, copy it to destination string
;		inc		hl						; pointer to next original character
;nocpy:		
;		inc		de						; pointer to next destination character	
;		djnz	filenamecpy				; all characters copied (i.e. B=0)? No, continue copying
;		ret								; yes, exit routine
;==============================================================================
; Messages
;==============================================================================
msg_oemid:
		.BYTE 	"OEM ID: ", 0
msg_vollabel:
		.BYTE 	"    Volume label: ", 0
msg_filesys:
		.BYTE 	"    File System: ", 0
;------------------------------------------------------------------------------
;             ERROR MESSAGES
;------------------------------------------------------------------------------
error_4001:
		.BYTE	CR, LF
		.BYTE	"ERROR: dzOS only supports FAT16. System halted!", 0
error_4002:
		.BYTE	CR, LF
		.BYTE	"ERROR: invalid Boot Sector signature. System halted!", 0
error_4003:
 		.BYTE	CR, LF
 		.BYTE	"WARNING: system was stop during a write-to-disk operation", CR, LF
		.BYTE	"         Some file(s) may be missing.", CR, LF, 0



test_wrclus:
		.BYTE	CR, LF
		.BYTE	"Writing cluster: ", 0
test_wrsec:
		.BYTE	CR, LF
		.BYTE	"Writing sector: ", 0