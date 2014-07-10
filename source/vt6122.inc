; *** VIA Velocity VT612x definitions ***

VT612x_registers	struc
PAR		db	6 dup(?) ; 00 physical address 0-5
RxCR		db	?	; 06 receive control
TCR		db	?	; 07 transmit control
CR0s		db	?	; 08 global command set
CR1s		db	?	; 09 global command 1 set
CR2s		db	?	; 0a global command 2 set
CR3s		db	?	; 0b global command 3 set
CR0c		db	?	; 0c global command clear
CR1c		db	?	; 0d global command 1 clear
CR2c		db	?	; 0e global command 2 clear
CR3c		db	?	; 0f global command 3 clear
MARCAM		dd	?,?	; 10 multicast / CAM data/mask
DescBaseHi	dd	?	; 18 descriptor base address high[63..32]
DataBaseHi	dw	?	; 1c data buffer base address high[63..48]
		dw	?
ISR_CTL		dw	?	; 20 interrupt control
TXE_SR		db	?	; 22 transmit host error status
RXE_SR		db	?	; 23 receive host error status
ISR		dd	?	; 24 interrupt status 0-3
IMR		dd	?	; 28 interrupt mask 0-3
TD_STATUS_PORT	dd	?
TDCSRs		dw	?	; 30 tx descriptor control/status set
RDCSRs		db	?	; 32 rx descriptor control/status set
		db	?
TDCSRc		dw	?	; 34 tx descriptor control/status clear
RDCSRc		db	?	; 36 rx descriptor control/status clear
		db	?
RDBaseLo	dd	?	; 38 rx descriptor base low[31..6]
RDINDX		dw	?	; 3c current rx descriptor index
TQETMR		db	?	; 3e tx qeueu empty pending timer
RQETMR		db	?	; 3f rx queue empty pending timer
TDBase0Lo	dd	?	; 40 tx0 descriptor base low[31..6]
TDBase1Lo	dd	?	; 44
TDBase2Lo	dd	?	; 48
TDBase3Lo	dd	?	; 4c
RDCSIZE		dw	?	; 50 rx descriptor size
TDCSIZE		dw	?	; 52 tx descriptor size
TDINDX0		dw	?	; 54 current tx0 descriptor index
TDINDX1		dw	?	; 56
TDINDX2		dw	?	; 58
TDINDX3		dw	?	; 5a
TXPUTM		dw	?	; 5c tx programmable pause frame timer
RBRDU		dw	?	; 5e flow control rx desc. residue count
		dd	?,?	; 60 fifo test
CAMADDR		db	?	; 68 CAM address
CAMCR		db	?	; 69 CAM command
		db	?,?	; 6a fifo test
MIICFG		db	?	; 6c MII management port control
MIISR		db	?	; 6d MII management port status
PHYSR0		db	?	; 6e PHY status 0
		db	?
MIICR		db	?	; 70 MII management control
MIIADR		db	?	; 71 MII embedded address port
MIIDATA		dw	?	; 72 MII embedded data port
SFTMR0		dw	?	; 74 software single shot timer 0
SFTMR1		dw	?	; 76 software periodic timer 1
CFGA		db	?	; 78 chip configuration A
CFGB		db	?	; 79 chip configuration B
CFGC		db	?	; 7a chip configuration C
CFGD		db	?	; 7b chip configuration D
DCFG0		db	?	; 7c DMA configuration 0
DCFG1		db	?	; 7d DMA configuration 1
MCFG0		db	?	; 7e MAC rx configuration
MCFG1		db	?	; 7f MAC tx configuration
BISTCMD		db	?
BISTSR		db	?
PMCC		db	?	; 82 Pover Management capability shadow
STKSHDW		db	?	; 83 sticky bit shadow (pm stat)
MIBCR		db	?	; 84 MIB counter control/status
EE_SWDAT	db	?	; 85 eeprom loaded data
		db	?,?
MIBDATA		dd	?	; 88 MIB counter address and data
EE_WR_DATA	dw	?	; 8c eeprom embedded write data
		db	?
BPMD_w		db	?
BPCMD		db	?
BPMD_r		db	?
CHKSUM		db	?	; 92 eeprom chechsum field shadown
EECSR		db	?	; 93 eeprom embedded control/status
EE_RD_DATA	dw	?	; 94 eeprom embedded read data
EADDR		db	?	; 96 eeprom embedded address
EMBCMD		db	?	; 97 eeprom embedded command/status
		db	?
CJMPSR		db	?
		db	?
MJMPSR		db	?
CHIPGSR		db	?	; 9c chip operation/diagnosis status
		db	?
DEBUG		db	?	; 9e chip debug control
CHIPGCR		db	?	; 9f chip operation/diagnosis control
WOLCRs		dw	?	; a0 WOL event enable set
PWCFGs		db	?	; a2 Power Management config. control set
WOLCFGs		db	?	; a3 WOL configuration set
WOLCRc		dw	?	; a4 WOL event enable clear
PWCFGc		db	?	; a6 Power Management config. control clear
WOLCFGc		db	?	; a7 WOL configuration clear
WOLSRs		dw	?	; a8 WOL event status set
		dw	?
WOLSRc		dw	?	; ac WOL event status clear
		dw	?
PTNCRC0		dw	?	; b0  16bits crc
PTNCRC1		dw	?	; b2
PTNCRC2		dw	?	; b4
PTNCRC3		dw	?	; b6
PTNCRC4		dw	?	; b8
PTNCRC5		dw	?	; ba
PTNCRC6		dw	?	; bc
PTNCRC7		dw	?	; be
PTNBMSK04_1	dd	?	; c0  128bit pattern match bit mask
PTNBMSK04_2	dd	?	; c4
PTNBMSK04_3	dd	?	; c8
PTNBMSK04_4	dd	?	; cc
PTNBMSK15_1	dd	?	; d0
PTNBMSK15_2	dd	?	; d4
PTNBMSK15_3	dd	?	; d8
PTNBMSK15_4	dd	?	; dc
PTNBMSK26_1	dd	?	; e0
PTNBMSK26_2	dd	?	; e4
PTNBMSK26_3	dd	?	; e8
PTNBMSK26_4	dd	?	; ec
PTNBMSK37_1	dd	?	; f0
PTNBMSK37_2	dd	?	; f4
PTNBMSK37_3	dd	?	; f8
PTNBMSK37_4	dd	?	; fc
VT612x_registers	ends


; --- Receive control register 06h ---
AS	equ	80h	; accept symbol error
AP	equ	40h	; accept through perfect-filtering
rxAL	equ	20h	; accept long packet
PROM	equ	10h	; promiscous mode
AB	equ	 8	; accept broadcast
AM	equ	 4	; accept mulicast (64bit hash table enable?)
AR	equ	 2	; accept runt
SEP	equ	 1	; accept CRC error

; --- transmit control register 07h ---
COLTMC1	equ	8	; collision retry control  00:normal 16times
COLTMC0	equ	4	;   01:32times  10:48times  11:forever
LB1	equ	2	; loopback control  00:normal
LB0	equ	1	;   01:internal  10:external

; --- global command register set/clear 08h/0ch ---
TXON	equ	8	; transmit process enable
RXON	equ	4	; receive process enable
STOP	equ	2	; stop NIC, clear STRT
STRT	equ	1	; start NIC

; --- global command register 1 set/clear 09h/0dh ---
SFRST	equ	80h	; software reset self-clear
TM1EN	equ	40h	; periodic software timer enable
TM0EN	equ	20h	; single-shot software timer enable
DPOLL	equ	 8	; disable tx/rx desc. auto polling
DISAU	equ	 1	; disable unicast recception

; --- global command register 2 set/clear 0ah/0eh ---
XONEN		equ	80h	; transmit zero-length pause control enable
FDXTFCEN	equ	40h	; full-duplex pause transmit enable
FDXRFCEN	equ	20h	; full-duplex pause receive enable
HDXFCEN		equ	10h	; half-duplex back-pressure enable
XHITH1		equ	 8	; tx XON(zero-length pause) threshold
XHITH0		equ	 4	;   00:24  01:32  10:48  11:64
XLTH1		equ	 2	; tx XOFF threshold
XLTH0		equ	 1	;   00:4  01:8  10:16  11:24

; --- global command register 3 set/clear 0bh/0fh ---
FORSRST		equ	40h	; force exit software stop
FPHYRST		equ	20h	; force PHYRSZ active
DIAG		equ	10h	; diagnostic enable
INTPCTL		equ	 4	; enable interrupt hold-off timer
GintMsk		equ	 2	; global interrupt mask
SWPEND		equ	 1	; software base interrupt pending control

; --- interrupt control register 20h ---
UDPINT		equ	8000h	; user defined interrupt set port
TSUPP_DIS	equ	4000h	; disable tx interrupt suppression
RSUPP_DIS	equ	2000h	; disable rx interrupt suppression
PMSK1		equ	1000h	; interrupt mask level
PMSK0		equ	 800h	;   00:layer-1  01:layer-2  10/11:all
INT_Pending	equ	 400h	; interrupt pending status
HC_RELOAD	equ	 200h	; timer reload via ISR2.HFLD write
SW_RELOAD	equ	 100h	; timer reload via toggle this bit
INTHOTMR	equ	 0ffh	; (mask) Timer/TSUPPTHR/RSUPPTHR

; --- transmit/recieve error status register 22h/23h ---
TRFDBS		equ	8	; FIFO DMA host bus error
TRDWBS		equ	4	; descriptor write-back host bus error
TRDRBS		equ	2	; descriptor fetch host bus error
TRDSTR		equ	1	; descriptor scructure error

; --- interrupt status/mask register 24h/28h ---
ISR3		equ	80000000h	; interrupt source indication
ISR2		equ	40000000h
ISR1		equ	20000000h
ISR0		equ	10000000h
TXSTL		equ	 2000000h	; tx DMA stall
RXSTL		equ	 1000000h	; rx DMA stall

HFLD		equ	  800000h	; hold-off timer reload
UDP		equ	  400000h	; user define interrupt
MIB		equ	  200000h	; MIB counter near full
SHDN		equ	  100000h	; software shudwon complete
PHY		equ	   80000h	; phy interrupt
PWE		equ	   40000h	; wake-up power event
TMR1		equ	   20000h	; periodic timer
TMR0		equ	   10000h	; single-shot timer

SRC		equ	    8000h	; port status change
LSTPE		equ	    4000h	; RD using-up warning
LSTE		equ	    2000h	; RD used up
OVFL		equ	    1000h	; rx FIFO overflow
FLON		equ	     800h	; rx pause control frame
RACE		equ	     400h	; rx FIFO packet count overflow

PTX3		equ	      80h	; TD3 complete
PTX2		equ	      40h
PTX1		equ	      20h
PTX0		equ	      10h
PTX		equ	       8	; combination of PTXn
PRX		equ	       4	; RD complete
PPTX		equ	       2	; high priority tx interrupt
PPRX		equ	       1	; high priority rx interrupt

; --- tx/rx descriptor control/status register set/clear 30h,32h/34h,36h ---
DEAD	equ	8	; error
WAK	equ	4	; wake-up
ACT	equ	2	; indicate active
RUN	equ	1	; enable queue

; --- tx/rx queue empty interrupt pending timer 3eh/3fh ---
TRQETMS1	equ	80h	; timer resolusion selection
TRQETMS0	equ	40h	;   00:1us  01:4us  10:16us  11:64us
TRQETMR		equ	3fh	; (mask) pending timer

; --- CAM address register 68h ---
CAMEN		equ	80h	; enable CAM read/write commad
A0C1		equ	40h	; address/VLAN ID select
CA		equ	3f	; (mask) CAM address

; --- CAM command register 69h ---
PS1		equ	80h	; page select  00:MAR/INTHOTMR
PS0		equ	40h	;   01:MASK/TSUPPTHR  10:DATA/RSUPPTHR
AITRPKT		equ	20h	; interrest packet segment defined
AITR16		equ	10h	; address size 0:[56..63]  1:[48..63]
CAMRD		equ	 8	; read command  self-clear
CAMWR		equ	 4	; write command  self-clear

; --- MII control status register 6ch ---
MPO1		equ	80h	; MII polling interval
MPO0		equ	40h	;   00:1024  01:512  10:128  11:64
MFDC		equ	20h	; Accelarate MDC speed x4
PHYAD		equ	1fh	; (mask) phy address

; --- MII status register 6dh ---
MIIDL		equ	80h	; not at polling cycle

; --- MII command register 70h ---
MAUTO		equ	80h	; auto polling enable
RCMD		equ	40h	; embedded read command
WCMD		equ	20h	; embedded write command
MDPM		equ	10h	; direct programming enable
MOUT		equ	 8	; MDIO output pin enable
MDO		equ	 4	; output data
MDI		equ	 2	; input data
MDC		equ	 1	; clock

; --- MII read/write address register 71h ---
SWMPL	equ	80h	; Initiate priority resolusion process self-clear

; --- chip configuration register A 78h ---
PHYLEDS1	equ	20h	; PHY LED function selection
PHYLEDS0	equ	10h	; 
PMHCTG		equ	 8	; crc culculation with tag field
ABSHDN		equ	 2	; abnormal shutdown wake-up function
PACPL		equ	 1	; Pre_ACPI wake-up function

; --- chip configuration register B 79h ---
GTCKOPT		equ	80h	; GTXCLK disable while link-down
CRSEOPT		equ	20h	; giga mode slot time option

; --- chip configuration register C 7ah ---
EELOAD		equ	80h	; enable EEPROM programming

; --- chip configuration register D 7bh ---
IODIS		equ	80h	; disable IO access mode
CFGDACEN	equ	20h	; enable 64bit dual address cycle

; --- DMA configuration register 0 7ch ---
DMALEN	equ	7	; tx/rx FIFO DMA burst length control in dword
			;   0:8 1:16 2:32 3:64 4:128 5:256 6/7:store&forward

; --- DMA configuration register 1 7dh ---
XMRL		equ	20h	; disable memory read cache line
PEER_DIS	equ	10h	; disable data parity generation and checking
MRDPL		equ	 8	; replace MRL with memory read multiple
MRWAIT		equ	 4	; read insert one wait 2-2-2-2
MWWAIT		equ	 2	; write insert one wait 2-2-2-2
LATMEN		equ	 1	; latency timer effect enable

; --- MAC receive configuration register 7eh ---
RXARB		equ	80h	; interleave to rx FIFO DMA
RFT1		equ	20h	; receive FIFO threshold
RFT0		equ	10h	;   00:128byte  01:512  10:1024  11:SF
LOWTHOPT	equ	 8	; receive FIFO low threshold 0:7 1:15qword
PQEN		equ	 4	; enable tagging function
RTGOPT		equ	 2	;   00:untag
VIDFR		equ	 1	; filter out VLAN ID mis-match

; --- MAC transmit configuration register 7fh ---
TXARB		equ	80h	; interleave to tx FIFO DMA
TXQBK1		equ	 8	; non blocking mode threshold
TXQBK0		equ	 4	; 
TXQNOBK		equ	 2	; priority transmit non-blocking mode
SNAPOPT		equ	 1	; control for tag insertion

; --- sticky bit shadow register 83h ---
STKDS1		equ	2	; power state indicator
STKDS0		equ	1	;

; --- MIB counter control and status register 84h ---
MIBSTOK		equ	80h	; MIB bist check status
MBISTGO		equ	40h	; MIB bist trigger
MIBHI		equ	10h	; counter near full 0:800000 1:c00000
MIBFREEZE	equ	 8	; freeze
MIBFLUSH	equ	 4	; force flush
MBTRINI		equ	 2	; return MIB counter index 0
MIBCLR		equ	 1	; clear

; --- MIB counter data and address output port register 88h ---
MIB_ptr		equ	0ff000000h	; (mask) index
MIB_data	equ	  0ffffffh	; (mask) data 24bit

; --- MIB counter index ---
RxAllPkts	equ	1	; all, including bad packet
RxOkPkts	equ	2	; 
TxOkPkts	equ	3
RxErrorPkts	equ	4	; fifo overrun
RxRuntOkPkt	equ	5	; runt packet
RxRuntErrPkt	equ	6	; runt and error
Rx64Pkts	equ	7	; 
Tx64Pkts	equ	8	; 
Rx65To127pkts	equ	9	; 
Tx65To127pkts	equ	10	; 
Rx128To255pkts	equ	11	; 
Tx128To255pkts	equ	12	; 
Rx256To511pkts	equ	13	; 
Tx256To511pkts	equ	14	; 
Rx512To1023pkts	equ	15	; 
Tx512To1023pkts	equ	16	; 
Rx1024To1518pkts equ	17	; 
Tx1024To1518pkts equ	18	; 
TxEtherCollisions equ	19	; collision
RxPktCRCR	equ	20	; CRC error
RxJumboPkts	equ	21	; jumbo packet
TxJumboPkts	equ	22	; 
RxMacControl	equ	23	; MAC control pause frame
TxMaxControl	equ	24	; 
RxPktFAE	equ	25	; alignment error
RxLongOkPkts	equ	26	; >1518
RxLongErrPkts	equ	27	; 
TxSQEErrors	equ	28	; SQE error
RxNobuf		equ	29	; no buffer event
RxSymbolErrors	equ	30	; 
InRangeLenErr	equ	31	; accepted in range length error
LateCollisions	equ	32	; 

; --- EEPROM embedded control and status register 93h ---
EMBP		equ	40h	; embedded program mode enable
RELOAD		equ	20h	; dynamic reload EEPROM
DPM_EEPROM	equ	10h	; direct program mode enable
ECS		equ	 8	; chip select
ESK		equ	 4	; clock
EpDI		equ	 2	; DI output
EpDO		equ	 1	; DO status

; --- EEPROM embedded command register 97h ---
EDONE		equ	80h	; embedded command done
EWDIS		equ	 8	; write protect  self-clear
EWEN		equ	 4	; write enable  self-clear
EWR		equ	 2	; write
ERD		equ	 1	; read

; --- chip debug control register 9eh ---
PMCDIAG		equ	10h	; PMCC setting test mode
FPSTIME		equ	 8	; force receiveed pause frame timer
ACPFRM		equ	 4	; accept pause frame to system buffer

; --- chip operation and dianosis control register 9fh ---
FCGMII		equ	80h	; force GMII mode
FCFDX		equ	40h	; force Full-duplex mode
FCMODE		equ	10h	; MAC into force mode
LPSOPT		equ	 8	; disable LPSEL field in priority resolusion
TM1US		equ	 4	; timer 0 resolution
TM0US		equ	 2	; timer 1 resolution
PHYINTEN	equ	 1	; enable PHY interrupt

; --- Wake on Lan Event enable/status control set/clear a0h,a8h/a4h,ach ---
LinkOff		equ	800h	; 
LinkOn		equ	400h	; 
Magic		equ	200h	; 
UniQ		equ	100h	; unicast
PTNMH7		equ	 80h
PTNMH6		equ	 40h
PTNMH5		equ	 20h
PTNMH4		equ	 10h
PTNMH3		equ	  8
PTNMH2		equ	  4
PTNMH1		equ	  2
PTNMH0		equ	  1

; --- Power Management configuration set/clear a2h/a6h ---
PME_SR		equ	8	; pme status
PME_EN		equ	4	; pme enable

; --- Wake on Lan Configuration control set/clear a3h/a7h ---
SAM		equ	20h	; accept multicast
SAB		equ	10h	; accept broadcast
PHYEVTEN	equ	 1	; using PHYINT as status change port


; +++ tx/rx descriptor definitions +++
; --- tx fragment buffer +++
TFB		struc
BufAdr		dd	?	; buffer physical address [31..0]
BufAdrHi	dw	?	; buffer physical address [47..32]
BufLen		dw	?	; buffer length
TFB		ends

; --- tx frame descriptor ---
TD		struc
TSR		dd	?	; status/frame length
TCR		dd	?	; control/fragment count
TFB0		TFB	7 dup(<>) ; fragment buffer [0..6]
TD		ends

; --- rx frame descriptor ---
RD		struc
RSR		dd	?	; status/receive length
RxCR		dd	?	; control/
BufAdr		dd	?	; buffer address
BufAddrHi	dw	?	; buffer address high
BufLen		dw	?	; buffer length
RD		ends

; --- tx status flags ---
OWN		equ	80000000h	; ownership
TxPktSize	equ	3fff0000h	; (mask)large send packet size [13..0]
TERR		equ	    8000h	; combination of ABT, OWT, OWC
FDX		equ	    4000h	; full-duplex sended
GMII		equ	    2000h	; GMII sended
LINKFL		equ	    1000h	; link down
txSHDN		equ	     400h	; shutdown
CRS		equ	     200h	; carrier sense lost
CDH		equ	     100h	; heart beat detection failure
ABT		equ	      80h	; excessive collision
OWT		equ	      40h	; jumbo packet abort
OWC		equ	      20h	; out of window collision
COLS		equ	      10h	; collision
NCR		equ	      0fh	; (mask) collision count

; --- tx conrtol flags ---
CMDZ		equ	0f0000000h	; (mask)fragment count
TCPLS		equ	  3000000h	; (mask) large send pointer 11:normal
TIC		equ	   800000h	; interrupt request
PIC		equ	   400000h	; priority interrupt request
VETAG		equ	   200000h	; enable VLAN tag
IPCK		equ	   100000h	; IP checksum calculation
UDPCK		equ	    80000h	; UDP checksum calculation
TCPCK		equ	    40000h	; TCP checksum calculation
JMBO		equ	    20000h	; jumbo packet
txCRC		equ	    10000h	; disable CRC generation

; --- rx status flags ---
;OWN		equ	80000000h
rxSHDN		equ	40000000h	; shutdown
RMBC		equ	3fff0000h	; received frame size
RXOK		equ	    8000h	; receive OK
PFT		equ	    4000h	; parfect filter match
MAR		equ	    2000h	; multicast
BAR		equ	    1000h	; broadcast
rxPHY		equ	     800h	; unicast
VTAG		equ	     400h	; VLAN tag indicator
STP		equ	     200h	; packet start  00:single 10:start
EDP		equ	     100h	; packet end  11:middle  01:end
DETAG		equ	      80h	; detag indicator
SNTAG		equ	      40h	; SNAP indicator
RXER		equ	      20h	; PCS symbol error
RLE		equ	      10h	; length error
CE		equ	       8	; checksum error
FAE		equ	       4	; alignment error
rxCRC		equ	       2	; CRC error
VIDM		equ	       1	; VID filter miss

; --- rx control flags ---
IPTn		equ	3f000000h	; parfect filter index
IPOK		equ	  400000h	; IP checksum OK
TUPOK		equ	  200000h	; TCP/UDP chechsum OK
FRAG		equ	  100000h	; fragment datagram
CKSMZO		equ	   80000h	; UDP checksum zero
IPKT		equ	   40000h	; IP received
TPKT		equ	   20000h	; TCP received
UPKT		equ	   10000h	; UDP received

; --- tx QUE command / rx INT request ---
txQUE		equ	8000h
rxINT		equ	8000h

; --- virtual transmit descriptor (for driver) ---
vtxd		struc
txd		dd	?	; far pointer to TD
reqhandle	dw	?	; request handle
protid		dw	?	; protocol id
len		dw	?	; frame total length
vlink		dw	?	; virtual link
immedphys	dd	?	; physical address of immediate data buffer
immed		db	64 dup(?) ; buffer for immediate data
vtxd		ends

; --- virtual receive descriptor (for driver) ---
vrxd		struc
vbuf		dd	?	; virtual address of buffer
rxd		dw	?	; rxd pointer
cnt		dw	?	; own / fragment count
vlink		dw	?	; virtual link
		dw	?
vrxd		ends


; --- PHY specific bug word around ?? ---
PHYID_CICADA_CS8201	equ	000FC410h
PHYID_VT3216_32BIT	equ	000FC610h
PHYID_VT3216_64BIT	equ	000FC600h
PHYID_MARVELL_1000	equ	01410C50h
PHYID_MARVELL_1000S	equ	01410C40h

miiTCSR		equ	16h	; 10BASE-T control and status
TCSR_ECHODIS	equ	2000h	; disable echo mode

