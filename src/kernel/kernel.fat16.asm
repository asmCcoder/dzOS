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
;	boot sector
;	fat 1
;	fat 2
;	root dir
;	cluster 2
;	cluster 3
;	...
;------------------------------------------------------------------------------
F_KRN_F16_READBOOTSEC:	.EXPORT		F_KRN_F16_READBOOTSEC
; Reads the Boot Sector (at sector 0)
		; read 512 bytes (from First Sector) into RAM CF_BUFFER_START
		ld		de, 0
		ld		bc, 0
		call	F_BIOS_CF_READ_SEC		; read 1 sector (512 bytes)

		; last 2 bytes (0x257E and 0x257F) must be 55 AA (signature indicating that this is a valid boot sector)
		ld		a, (257Eh)
		cp		55h
		jp		nz, error_bootsignature
		ld		a, (257Fh)
		cp		$AA
		jp		nz, error_bootsignature
		; 0x003 = OEM ID (8 bytes)
		ld		hl, msg_oemid
		call	F_KRN_WRSTR				; Output message
		ld		b, 8					; counter = 8 bytes
		ld		hl, CF_BUFFER_START + 3h ; point HL to offset 3h in the buffer
		call	F_KRN_PRN_BYTES
		; 0x00B = BytesPerSector (2 bytes)
		ld		de, (CF_BUFFER_START + 0Bh)	; store it in DE for the later calculation of root_dir_sectors
		; 0x00D = SectorsPerCluster (1 byte)
		ld		hl, (CF_BUFFER_START + 0Dh)
		ld		(secs_per_clus), hl
		; 0x00E = ReservedSectors (2 bytes)
		ld		hl, (CF_BUFFER_START + 0Eh)
		ld		(reserv_secs), hl
		ld		bc, (reserv_secs)		; store it in BC for the later calculation of clus2secnum
		; 0x010 = NumberFATs (1 byte)
		ld		a, (CF_BUFFER_START + 10h)
		ld		(num_fats), a
		; 0x011 = RootEntries (2 bytes)
		; root_dir_sectors = (32 bytes * RootEntries) / BytesPerSector
		ld		hl, 32																	; >>>> ToDo - this is hardcoded! We need a DIV routine <<<<
		ld		(root_dir_sectors), hl
		; 0x016 = SectorsPerFAT (2 bytes)
		ld		hl, (CF_BUFFER_START + 16h)
		ld		(secs_per_fat), hl
		; clus2secnum = reserv_secs + num_fats * secs_per_fat + root_dir_sectors
		ld		hl, 529																	; >>>> ToDo - this is hardcoded! <<<<
		ld		(clus2secnum), hl
		; 0x02B = Volume Label (11 bytes)
		ld		hl, msg_vollabel
		call	F_KRN_WRSTR				; Output message
		ld		b, 11					; counter = 11 bytes
		ld		hl, CF_BUFFER_START + 2Bh ; point HL to offset 2Bh in the buffer
		call	F_KRN_PRN_BYTES
		; 0x036 = File System (8 bytes)
		ld		hl, msg_filesys
		call	F_KRN_WRSTR				; Output message
		ld		b, 8					; counter = 8 bytes
		ld		hl, CF_BUFFER_START + 36h	; point HL to offset 36h in the buffer
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
		ld		hl, CF_BUFFER_START + 36h	; point HL to offset 36h in the buffer
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
;------------------------------------------------------------------------------
F_KRN_F16_GETFATCLUS:	.EXPORT		F_KRN_F16_GETFATCLUS
; Get list of all the clusters of a file from FAT
; IN <= HL First cluster number
; OUT => list of clusters (2 bytes each) stored in sysvars.buffer_pgm
		ld		ix, 1					; counter. How many clusters for a the file
		; each entry in the FAT is 2 bytes, therefore in each Sector
		; of 512 bytes, can be 256 allocations
		; We check if HL is greater. Right now dzOS only supports 256 Clusters
		push	hl						; backup HL. First cluster number
;		ld		de, 256					; max. number of clusters allowed
;		sbc		hl, de					; is it more than 256?
;		jp		m, getfatend			; yes, exit routine
										; no, continue
		; FAT sector = sysvars.reserv_secs
		ld		hl, (reserv_secs)		; HL = sysvars.reserv_secs
		call	F_KRN_F16_SEC2BUFFER	; read FAT into RAM buffer
		pop		hl						; restore HL. First cluster number
		; get next cluster from FAT
		add		hl, hl					; the byte to read is at CF_BUFFER_START + HL * 2
		ld		de, CF_BUFFER_START
		add		hl, de
		ld		de, buffer_pgm			; pointer to sysvars.buffer_pgm (store number of clusters)
		inc		de						; pointer to sysvars.buffer_pgm + 1 (store cluster counter)
		inc		de						; pointer to sysvars.buffer_pgm + 2 (store cluster list)
getfatloop:
		; store bytes pair in sysvars.buffer_pgm
		ld		a, (hl)
		ld		(de), a					; store first byte
		inc		de						; pointer to next byte in sysvars.buffer_pgm
		inc		hl						; pointer to next byte in CF_BUFFER_START
		ld		a, (hl)
		ld		(de), a					; store second byte
		cp		$FF						; if A = FF, then this was last cluster
		jp		z, getfatend			; yes, exit routine
		inc		de						; no, pointer to next pair of bytes in sysvars.buffer_pgm 
		inc		hl						; pointer to next pair of bytes in CF_BUFFER_START
		inc		ix						; counter. How many clusters for a the file
		jp		getfatloop				; get next pair of bytes
getfatend:
		ld		(buffer_pgm), ix		;store number of clusters
		ld		ix, buffer_pgm
		ld		(ix + 1), 1				;store cluster counter
		ret
;------------------------------------------------------------------------------
F_KRN_F16_LOADEXE2RAM:	.EXPORT		F_KRN_F16_LOADEXE2RAM
; Load an executable file into RAM, so it can be run
; IN <= DE First cluster number
; OUT => Z flag set if an error occurred
;		 DE = load address
;		 All bytes of the executable file are loaded into 
;			RAM at the address location found in the file header
; buffer_cmd usage
;		buffer_cmd = 2 bytes 1st Cluster, 1st Sector number
;		buffer_cmd + 2 = 2 bytes Load address
;		buffer_cmd + 4 =  number of bytes copied
; Header:
; 	first 4 bytes = string dzOS (64, 7A, 4F, 53)
; 	next 2 bytes are the hexadecimal values of the start address in little-endian format
;	rest of the bytes are nullified with 0x00 and not used at the moment

	; Read FAT and get list of clusters
	call	F_KRN_F16_CLUS2SEC		; convert cluster number to sector number
	ld		(buffer_cmd), hl		; backup HL. 1st Cluster, 1st Sector number
	call	F_KRN_F16_SEC2BUFFER	; load sector to buffer
	; Check header for "dzOS"
	ld		ix, CF_BUFFER_START
	ld		a, (ix)
	cp		'd'						; 1st byte = 'd'?
	jp		nz, errorheader			; no, print error and exit routine
	ld		a, (ix + 1)
	cp		'z'						; yes, 2nd byte = 'z'?
	jp		nz, errorheader			; no, print error and exit routine
	ld		a, (ix + 2)
	cp		'O'						; yes, 3rd byte = 'O'?
	jp		nz, errorheader			; no, print error and exit routine
	ld		a, (ix + 3)
	cp		'S'						; yes, 4th byte = 'S'?
	jp		nz, errorheader			; no, print error and exit routine
									; yes, continue
	
	; copy 1st sector of 1st cluster
	ld		de, (CF_BUFFER_START + 4)	; pointer to load address
	ld		(buffer_cmd + 2), de	; backup DE. Load address
	ld		hl, CF_BUFFER_START + 16	; pointer to first executable byte
	ld		bc, 496					; 512 - 16 = 496 bytes will be copied
	ld		(buffer_cmd + 4), bc	; backup BC. Number of bytes copied
	ldir							; copy n bytes from HL to DE
;	jp		allok
	; copy remaining sectors of 1st cluster
	ld		a, (secs_per_clus)		; counter. Remaining sectors
loadloop:
	dec		a						; 1st sector already loaded
	ld		hl, (buffer_cmd)		; restore sector number
	inc		hl						; next sector
	ld		(buffer_cmd), hl		; backup HL. Sector number
	call	F_KRN_F16_SEC2BUFFER	; load sector to buffer
	ld		hl, (buffer_cmd + 2)	; restore load address
	ld		bc, (buffer_cmd + 4)	; restore number of bytes copied
	add		hl, bc					; HL = load address + number of bytes last copied
	ld		bc, 512					; copy entire sector (512 bytes)
	ld		(buffer_cmd + 4), bc	; backup BC. Number of bytes copied
	ex		de, hl					; DE = load address + number of bytes last copied
	ld		hl, CF_BUFFER_START		; pointer to first executable byte
	ldir							; copy n bytes from HL to DE
	cp		0						; did we copy all sectors of the cluster?
	jp		nz, loadloop			; no, copy another sector
	jp		allok					; yes, set return parameters and exit routine

	; for each cluster
	;	print sectors

	; >>>> ToDo - This only loads 496 bytes (first sector of first cluster) <<<<

	; Get load address from header
		; For each sector
		; Copy bytes to load address location in RAM

errorheader:
	ld		hl, error_4004
	call	F_KRN_WRSTR
	cp		a						; set Z flag
	ret
allok:
	ld		de, (CF_BUFFER_START + 4)	; pointer to load address
	or		1						; reset Z flag
	ret
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
		.BYTE	"ERROR: directory not found", CR, LF, 0
error_4004:
		.BYTE	CR, LF
		.BYTE	"ERROR: incorrect header for executable", CR, LF, 0