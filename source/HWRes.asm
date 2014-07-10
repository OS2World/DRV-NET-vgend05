; *** Resident part: Hardware dependent ***

include	NDISdef.inc
include	vt6122.inc
include	MIIdef.inc
include	misc.inc
include	DrvRes.inc

extern	DosIODelayCnt : far16

public	DrvMajVer, DrvMinVer
DrvMajVer	equ	1
DrvMinVer	equ	5

.386

_REGSTR	segment	use16 dword AT 'RGST'
	org	0
Reg	VT612x_registers <>
_REGSTR	ends

_DATA	segment	public word use16 'DATA'

; --- DMA Descriptor management ---
public	VTxHead, VTxFreeHead, VTxBase, TxBasePhys
VTxHead		dw	0
VTxFreeHead	dw	0
VTxBase		dw	0
TxBasePhys	dd	0

public	VRxHead, VRxBase, RxBasePhys, VRxInProg
VRxInProg	dw	0
VRxHead		dw	0
VRxBase		dw	0
RxBasePhys	dd	0

; --- Register Contents ---
public	regIntStatus, regIntMask	; << for debug info >>

I_RX	equ	PPRX or PRX or RACE or OVFL or LSTE or LSTPE	; ISR0,1
I_TX	equ	PPTX or PTX0		; ISR0

regIntStatus	dd	0
regIntMask	dd	0

; --- ReceiveChain Frame Descriptor ---
public	RxFrameLen, RxDesc	; << for debug info >>
RxFrameLen	dw	0
RxDesc		RxFrameDesc	<>

; --- Physical information ---
PhyInfo		_PhyInfo <>

public	MediaSpeed, MediaDuplex, MediaPause, MediaLink	; << for debug >>
MediaSpeed	db	0
MediaDuplex	db	0
MediaPause	db	0
MediaLink	db	0

; --- System(PCI) Resource ---
public	IOaddr, MEMSel, MEMaddr, IRQlevel
public	CacheLine, Latency
IOaddr		dw	?
MEMSel		dw	?
MEMaddr		dd	?
IRQlevel	db	?
CacheLine	db	?	; [0..3] <- [0,8,16,32]
Latency		db	?

PHY_WAF		db	0	; PHY Work Around flag

; --- Configuration Memory Image Parameters ---
public	cfgSLOT, cfgTXQUEUE, cfgRXQUEUE, cfgMAXFRAMESIZE
public	cfgMXDMA, cfgDCFG1, cfgMCFG0, cfgMCFG1, cfgFLTH
public	cfgTXSUPPTHR, cfgRXSUPPTHR, cfgINTHOTMR, cfgIHLAYER
public	cfgTQETMR, cfgRQETMR, cfgDAPOLL
public	cfgRxAcErr, cfgChecksumMask
cfgSLOT		db	0
cfgTXQUEUE	db	24
cfgRXQUEUE	db	32

cfgMXDMA	db	001b	; 16dwords  [0..7]
cfgDCFG1	db	09h	; latency, insert wait, MRM
cfgMCFG0	db	0	; rx arbiter, rx fifo drain threshold
cfgMCFG1	db	0	; tx arbiter
cfgFLTH		db	0000b	; transmit pause threshold

cfgTXSUPPTHR	db	6	; tx interrupt pending count
cfgRXSUPPTHR	db	6	; rx interrupt pending count
cfgINTHOTMR	db	8	; n*20us interrupt hold-off timer
cfgIHLAYER	db	0	; hold-off layer

cfgTQETMR	db	0ch	; 12us
cfgRQETMR	db	0ch	; 12us
cfgDAPOLL	db	0	; auto polling

cfgChecksumMask	db	67h	; IP/TCP/UDP checksum mask
cfgMAXFRAMESIZE	dw	1514
cfgRxAcErr	db	0

; --- Receive Buffer address ---
public	RxBufferLin, RxBufferPhys, RxBufferSize, SelCnt, RxBufferSel
public	TxDescSel, TxCopySel
RxBufferLin	dd	?
RxBufferPhys	dd	?
RxBufferSize	dd	?
SelCnt		dw	?
TxDescSel	dw	?
TxCopySel	dw	?
RxBufferSel	dw	6 dup (?)	; max is 6.

; ---Vendor Adapter Description ---
public	AdapterDesc
AdapterDesc	db	'VIA VT612x Volocity Giga Ethernet Adapter',0


_DATA	ends

_TEXT	segment	public word use16 'CODE'
	assume	ds:_DATA, gs:_REGSTR
	
; USHORT hwTxChain(TxFrameDesc *txd, USHORT rqh, USHORT pid)
_hwTxChain	proc	near
	push	bp
	mov	bp,sp
	push	fs
	lfs	bx,[bp+4]
	xor	ax,ax
	mov	cx,fs:[bx].TxFrameDesc.TxImmedLen
	mov	dx,fs:[bx].TxFrameDesc.TxDataCount
	cmp	ax,cx
	adc	ax,dx		; fragment count
	or	dx,dx
	jz	short loc_p2
loc_p1:
	add	cx,fs:[bx].TxFrameDesc.TxBufDesc1.TxDataLen
	add	bx,sizeof(TxBufDesc)
	dec	dx
	jnz	short loc_p1
loc_p2:
	cmp	ax,7			; framgment count <= 7
	ja	short loc_p4
	cmp	cx,[cfgMAXFRAMESIZE]	; frame length <= maximum length
	ja	short loc_p4

	push	offset semTx
	call	_EnterCrit
	mov	si,[VTxFreeHead]
	mov	dx,[si].vtxd.vlink
	cmp	dx,[VTxHead]		; vtxd used up?
	jnz	short loc_0
	call	_LeaveCrit
	pop	cx	; stack adjust
	mov	ax,OUT_OF_RESOURCE
loc_p3:
	pop	fs
	pop	bp
	retn
loc_p4:
	mov	ax,INVALID_PARAMETER
	jmp	short loc_p3

loc_0:
	mov	[VTxFreeHead],dx	; next vtxd update
	mov	di,[bp+8]		; reqhandle
	mov	dx,[bp+10]		; protid
	mov	bp,[bp+4]
	mov	[si].vtxd.reqhandle,di
	mov	[si].vtxd.protid,dx
	mov	[si].vtxd.len,cx
	les	bx,[si].vtxd.txd	; TD far pointer
	inc	ax
	shl	ax,12			; CMDZ
	cmp	cx,1514
	seta	al
	or	ah,high(highword TCPLS)	; normal packet
	shl	al,1			; jumbo packet
	mov	di,offset TD.TFB0
	or	al,low(highword TIC)	; normal interrupt request
	mov	cx,fs:[bp].TxFrameDesc.TxImmedLen
	mov	word ptr es:[bx].TD.TCR[2],ax
	or	cx,cx
	jz	short loc_1		; no immediate data

	mov	ax,word ptr [si].vtxd.immedphys
	mov	dx,word ptr [si].vtxd.immedphys[2]
	mov	word ptr es:[bx+di].TFB.BufAdr,ax
	mov	word ptr es:[bx+di].TFB.BufAdr[2],dx
	mov	es:[bx+di].TFB.BufLen,cx

	push	si
	push	di
	push	es
	push	ds

	push	ds
	pop	es
	lea	di,[si].vtxd.immed
	lds	si,fs:[bp].TxFrameDesc.TxImmedPtr

	mov	ax,cx
	shr	cx,2
	and	al,3
	rep	movsd
	mov	cl,al
	rep	movsb

	pop	ds
	pop	es
	pop	di
	pop	si
	add	di,sizeof(TFB)		; next fragment

loc_1:
	cmp	[si].vtxd.len,60
	jnc	near ptr loc_multi	; multiple buffers

loc_pad:		; length < 60, single buffer and padding
	lea	di,[si].vtxd.immed
	mov	dx,fs:[bp].TxFrameDesc.TxDataCount
	add	di,fs:[bp].TxFrameDesc.TxImmedLen	; next/start ptr
	push	es
	push	ds
	pop	es

	or	dx,dx
	jz	short loc_pad5
	push	si
	push	gs
loc_pad2:
	cmp	fs:[bp].TxFrameDesc.TxBufDesc1.TxPtrType,0
	mov	cx,fs:[bp].TxFrameDesc.TxBufDesc1.TxDataLen
	jnz	short loc_pad3		; virtual address
	push	cx
	push	fs:[bp].TxFrameDesc.TxBufDesc1.TxDataPtr
	push	[TxCopySel]
	call	_PhysToGDT
	pop	gs
	xor	si,si
	add	sp,4+2
	jmp	short loc_pad4
loc_pad3:
	lgs	si,fs:[bp].TxFrameDesc.TxBufDesc1.TxDataPtr
loc_pad4:
	mov	ax,cx
	shr	cx,2
	and	al,3
	rep	movsd	es:[di],gs:[si]
	mov	cl,al
	rep	movsb	es:[di],gs:[si]
	add	bp,sizeof(TxBufDesc)
	dec	dx
	jnz	short loc_pad2
	pop	gs
	pop	si

loc_pad5:
	mov	cx,60
	sub	cx,[si].vtxd.len
	mov	dx,cx
	and	cx,3
	shr	dx,2
	xor	eax,eax			; avoid prev data leak
	rep	stosb
	mov	cx,dx
	rep	stosd

	pop	es
	mov	ax,word ptr [si].vtxd.immedphys
	mov	dx,word ptr [si].vtxd.immedphys[2]
	mov	word ptr es:[bx].TD.TFB0.BufAdr,ax
	mov	word ptr es:[bx].TD.TFB0.BufAdr[2],dx
	mov	es:[bx].TD.TFB0.BufLen,60
	mov	word ptr es:[bx].TD.TCR[2],2380h
	mov	word ptr es:[bx].TD.TSR[2],803ch
	jmp	short loc_ex


loc_multi:
	mov	cx,fs:[bp].TxFrameDesc.TxDataCount
	or	cx,cx
	jz	short loc_4		; no tx data desc.
	lea	bp,[bp].TxFrameDesc.TxBufDesc1
loc_3:
	mov	ax,word ptr fs:[bp].TxBufDesc.TxDataPtr
	mov	dx,word ptr fs:[bp].TxBufDesc.TxDataPtr[2]
	cmp	fs:[bp].TxBufDesc.TxPtrType,0
	jz	short loc_2
	push	dx
	push	ax
	call	_VirtToPhys
	add	sp,2*2
loc_2:
	mov	word ptr es:[bx+di].TFB.BufAdr,ax
	mov	word ptr es:[bx+di].TFB.BufAdr[2],dx
	mov	ax,fs:[bp].TxBufDesc.TxDataLen
	mov	es:[bx+di].TFB.BufLen,ax
	add	di,sizeof(TFB)
	add	bp,sizeof(TxBufDesc)
	dec	cx
	jnz	short loc_3
loc_4:
	mov	ax,[si].vtxd.len
	or	ax,highword OWN
	mov	word ptr es:[bx].TD.TSR[2],ax
loc_ex:
;	test	byte ptr gs:[Reg.TDCSRs],ACT	; TD0 active?
;	jnz	short loc_nowake
	mov	byte ptr gs:[Reg.TDCSRs],WAK	; wake-up TD0
loc_nowake:
	call	_LeaveCrit
	pop	cx
	mov	ax,SUCCESS
	pop	fs
	pop	bp
	retn
_hwTxChain	endp


_hwRxRelease	proc	near
	push	bp
	mov	bp,sp
	push	si
	push	offset semRx
	call	_EnterCrit

	mov	ax,[bp+4]		; ReqHandle = vrxd
	mov	si,ax			; backup
	sub	ax,[VRxBase]
	jb	short loc_ex		; invalid handle
	xor	dx,dx
	mov	cx,sizeof(vrxd)
	div	cx
	or	dx,dx
	jnz	short loc_ex		; invalid handle
	mov	cl,[cfgRXQUEUE]
	cmp	ax,cx
	jnc	short loc_ex		; invalid handle

	cmp	si,[VRxInProg]
	jnz	short loc_1
	mov	[VRxInProg],dx		; clear (dx=0)

loc_1:
	mov	cx,[si].vrxd.cnt
	or	cx,cx
	jz	short loc_ex		; MAC driver own... 
	mov	[si].vrxd.cnt,dx	; clear protocol own/count
	mov	ax,cx			; backup
loc_2:
	mov	bx,[si].vrxd.rxd
	dec	cx
	mov	word ptr [bx].RD.RSR[2],highword(OWN)
	mov	si,[si].vrxd.vlink
	jnz	short loc_2

	mov	gs:[Reg.RBRDU],ax	; update rx desc. residue
;	test	gs:[Reg.RDCSRs],ACT	; rx active?
;	jnz	short loc_ex
	mov	gs:[Reg.RDCSRs],WAK	; rx wake-up
loc_ex:
	call	_LeaveCrit
	pop	cx	; stack adjust
	mov	ax,SUCCESS
	pop	si
	pop	bp
	retn
_hwRxRelease	endp


_ServiceIntTx	proc	near
	push	offset semTx
loc_0:
	call	_EnterCrit
	mov	bx,[VTxHead]
	cmp	bx,[VTxFreeHead]
	jz	short loc_ex		; vtxd queue is empty
	les	si,[bx].vtxd.txd
	mov	ax,word ptr es:[si].TD.TSR[2]
	test	ax,highword(OWN)
	jnz	short loc_ex		; incomplete

	mov	ax,[bx].vtxd.vlink
	mov	cx,[bx].vtxd.reqhandle
	mov	dx,[bx].vtxd.protid
	mov	[VTxHead],ax		; update vtxd head
	mov	ax,word ptr es:[si].TD.TSR
	call	_LeaveCrit

	test	cx,cx
	jz	short loc_0		; null request handle - no confirm
	shr	ax,15			; TERR
	mov	bx,[CommonChar.moduleID]
	mov	si,[ProtDS]
	neg	al			; [0,ff] <- TERR[0,1]

	push	dx	; ProtID
	push	bx	; MACID
	push	cx	; ReqHandle
	push	ax	; Status
	push	si	; ProtDS
	call	dword ptr [LowDisp.txconfirm]
	mov	gs,[MEMSel]	; fix gs selector

	jmp	short loc_0

loc_ex:
	call	_LeaveCrit
	pop	ax	; stack adjust
	retn
_ServiceIntTx	endp


_ServiceIntRx	proc	near
	push	bp
	push	offset semRx
loc_0:
	call	_EnterCrit
loc_1:
	mov	bx,[VRxInProg]
	mov	si,[VRxHead]
	or	bx,bx
	jnz	near ptr loc_rty	; retry suspended frame
	cmp	[si].vrxd.cnt,0
	jnz	near ptr loc_ex		; protocol own. vrxd used up!
	mov	bx,[si].vrxd.rxd
	mov	ax,word ptr [bx].RD.RSR[2]
	test	ax,highword OWN
	jnz	near ptr loc_ex		; rx queue empty
	mov	dx,word ptr [bx].RD.RSR
	xor	cx,cx			; fragment count
	xor	bp,bp			; frame length
	mov	di,offset RxDesc.RxBufDesc1
	test	dh,high(STP or EDP)
	jz	short loc_lstfrg	; single fragment
	test	dh,high EDP
;	jnz	short loc_rmv		; start fragment missing
	jnz	near ptr loc_rmv

loc_m1:
	inc	cx
	mov	ax,[bx].RD.BufLen	; fragment size
	cmp	cx,7
	ja	short loc_rmv		; too many fragment
	and	ax,not rxINT		; clear rxINT bit
	mov	dx,word ptr [si].vrxd.vbuf
	mov	bx,word ptr [si].vrxd.vbuf[2]
	mov	[di].RxBufDesc.RxDataLen,ax
	mov	word ptr [di].RxBufDesc.RxDataPtr,dx
	mov	word ptr [di].RxBufDesc.RxDataPtr[2],bx
	mov	si,[si].vrxd.vlink	; next descriptor
	add	bp,ax			; total size
	mov	bx,[si].vrxd.rxd
	add	di,sizeof RxBufDesc	; next RxBufDesc ptr
	mov	ax,word ptr [bx].RD.RSR[2]
	test	ax,highword OWN
	jnz	near ptr loc_ex		; rx dma in progress. incomplete
	mov	dx,word ptr [bx].RD.RSR
	test	dh,high(STP or EDP)
	jz	short loc_rmvb		; !? single fragment !?
	test	dh,high EDP
	jz	short loc_rmvb		; !? start fragment !?
	test	dh,high STP
	jnz	short loc_m1		; middle fragment
loc_lstfrg:
	test	dh,high RXOK
	jz	short loc_rmv		; error packet
	mov	dl,byte ptr [bx].RD.RxCR[2]
	and	ax,highword RMBC	; received size
	and	dl,[cfgChecksumMask]	; IP/TCP/UPD chechsum mask
	test	dl,low(highword IPKT)	; IP received?
	jz	short loc_noip
	test	dl,low(highword IPOK)	; IP checksum valid?
	jz	short loc_rmv
loc_noip:
	test	dl,low(highword(TPKT or UPKT))	; TCP/UDP received?
	jz	short loc_notu
	test	dl,low(highword TUPOK)	; TCP/UDP chechsum valid?
	jz	short loc_rmv
loc_notu:
	mov	dx,ax
	sub	ax,4			; remove FCS, total frame size
	jbe	short loc_rmv		; too short packet
	sub	dx,bp			; last fragment size
	jbe	short loc_rmv		; last fragment size invalid
	cmp	ax,[cfgMAXFRAMESIZE]
	ja	short loc_rmv		; too long packet
	sub	dx,4			; remove FCS, last fragment size
	mov	[RxFrameLen],ax
	ja	short loc_2		; last fragment is valid

	mov	[RxDesc.RxDataCount],cx
	add	[di-sizeof(RxBufDesc)].RxBufDesc.RxDataLen,dx	; remove CRC
	inc	cx
	jmp	short loc_3

loc_rmv:	; remove from VRxHead to [si]
	mov	si,[si].vrxd.vlink
loc_rmvb:	; remove from VRxHead to before [si]
	mov	di,[VRxHead]
	xor	ax,ax
loc_rmv1:
	mov	bx,[di].vrxd.rxd
	inc	ax
	mov	di,[di].vrxd.vlink
	mov	word ptr [bx].RD.RSR[2],highword OWN
	cmp	di,si
	jnz	short loc_rmv1
	mov	[VRxHead],di		; next vrxd ptr
	mov	gs:[Reg.RBRDU],ax	; update rx desc. residue
;	test	gs:[Reg.RDCSRs],ACT	; rx active?
;	jnz	short loc_rmv2
	mov	gs:[Reg.RDCSRs],WAK	; rx wake-up
loc_rmv2:
	jmp	near ptr loc_1		; repeat

loc_ex:
	call	_LeaveCrit
	pop	cx	; stack adjust
	pop	bp
	retn

loc_2:
	inc	cx
	cmp	cx,7
	ja	short loc_rmv		; too many fragment
	mov	[RxDesc.RxDataCount],cx
	mov	[di].RxBufDesc.RxDataLen,dx
	mov	ax,word ptr [si].vrxd.vbuf
	mov	dx,word ptr [si].vrxd.vbuf[2]
	mov	word ptr [di].RxBufDesc.RxDataPtr,ax
	mov	word ptr [di].RxBufDesc.RxDataPtr[2],dx
loc_3:
	mov	bx,[VRxHead]
	mov	ax,[si].vrxd.vlink
	mov	[bx].vrxd.cnt,cx
	mov	[VRxHead],ax
	mov	[VRxInProg],bx
loc_rty:
	call	_LeaveCrit

	call	_IndicationChkOFF
	or	ax,ax
	jz	short loc_spd		; indicate off - suspend...

	push	-1
;	mov	bx,[VRxInProg]
	mov	cx,[RxFrameLen]
	mov	ax,[ProtDS]
	mov	dx,[CommonChar.moduleID]
	mov	di,sp
	push	bx			; current vrxd = handle

	push	dx		; MACID
	push	cx		; FrameSize
	push	bx		; ReqHandle
	push	ds
	push	offset RxDesc	; RxFrameDesc
	push	ss
	push	di		; Indicate
	push	ax		; Protocol DS
	call	dword ptr [LowDisp.rxchain]
	mov	gs,[MEMSel]	; fix gs selector
lock	or	[drvflags],mask df_idcp
	cmp	ax,WAIT_FOR_RELEASE
	jz	short loc_6
	call	_hwRxRelease
loc_5:
	pop	cx	; stack adjust
	pop	ax	; indicate
	cmp	al,-1
	jnz	short loc_spd		; indication remains OFF - suspend
	call	_IndicationON
	jmp	near ptr loc_0
loc_6:
	call	_RxPutBusyQueue
	jmp	short loc_5

loc_spd:
lock	or	[drvflags],mask df_rxsp
	pop	cx	; stack adjust
	pop	bp
	retn

_RxPutBusyQueue	proc	near
	push	offset semRx
	call	_EnterCrit
	mov	[VRxInProg],0		; simply clear
	call	_LeaveCrit
	pop	bx	; stack adjust
	retn
_RxPutBusyQueue	endp

_ServiceIntRx	endp


_hwServiceInt	proc	near
	enter	4,0
loc_0:
	mov	eax,gs:[Reg.ISR]
lock	or	[regIntStatus],eax
	mov	eax,[regIntStatus]
	and	eax,[regIntMask]
	jz	short loc_5
	mov	gs:[Reg.ISR],eax

loc_1:
	mov	[bp-4],eax

	mov	al,I_TX
	test	[bp-4],al
	jz	short loc_2
	not	ax
lock	and	byte ptr [regIntStatus],al
	call	_ServiceIntTx

loc_2:
	mov	ax,I_RX
	cmp	[Indication],0		; rx enable
	jnz	short loc_3
	test	word ptr [bp-4],ax
	jz	short loc_3
	not	ax
lock	and	word ptr [regIntStatus],ax
	call	_ServiceIntRx

loc_3:
	test	[bp-4+2],low(highword MIB)	; ISR2
	jz	short loc_4
lock	and	byte ptr [regIntStatus][2],not low(highword MIB)
	call	_hwClearStat
	mov	byte ptr gs:[Reg.ISR][2],low(highword(MIB)) ; avoid twice run

loc_4:
lock	btr	[drvflags],df_rxsp
	jnc	short loc_0
loc_5:
	leave
	retn
_hwServiceInt	endp

_hwCheckInt	proc	near
	mov	eax,gs:[Reg.ISR]
lock	or	[regIntStatus],eax
	mov	eax,[regIntStatus]
	test	eax,[regIntMask]
	setnz	al
	mov	ah,0
	retn
_hwCheckInt	endp

_hwEnableInt	proc	near
	mov	eax,[regIntMask]
	mov	byte ptr gs:[Reg.ISR][2],\
		  low(highword(HFLD))	; hold-off timer reload
	mov	gs:[Reg.IMR],eax
	retn
_hwEnableInt	endp

_hwDisableInt	proc	near
	xor	eax,eax
	mov	gs:[Reg.IMR],eax	; clear IMR
;	mov	eax,gs:[Reg.IMR]
	retn
_hwDisableInt	endp

_hwIntReq	proc	near
	or	gs:[Reg.ISR_CTL],UDPINT	; user define interrupt
	retn
_hwIntReq	endp

_hwEnableRxInd	proc	near
	push	eax
lock	or	[regIntMask],I_RX
	cmp	[semInt],0
	jnz	short loc_1
	mov	eax,[regIntMask]
	mov	gs:[Reg.IMR],eax
loc_1:
	pop	eax
	retn
_hwEnableRxInd	endp

_hwDisableRxInd	proc	near
	push	eax
lock	and	[regIntMask],not I_RX
	cmp	[semInt],0
	jnz	short loc_1
	mov	eax,[regIntMask]
	mov	gs:[Reg.IMR],eax
loc_1:
	pop	eax
	retn
_hwDisableRxInd	endp


_hwPollLink	proc	near
	test	gs:[Reg.MIICR],MAUTO	; auto-polling running?
	jz	short loc_0
	retn

loc_0:
	call	_ChkLink
	or	al,al
	mov	[MediaLink],al
	jnz	short loc_1	; change into Link Active
	call	_ChkLink	; link down. check again.
	or	al,al
	mov	[MediaLink],al
	jnz	short loc_1	; short time link down
	retn

loc_1:
	call	_GetPhyMode

;	cmp	al,MediaSpeed
;	jnz	short loc_2
;	cmp	ah,MediaDuplex
;	jnz	short loc_2
;	cmp	dl,MediaPause
;	jz	short loc_3
loc_2:
	mov	MediaSpeed,al
	mov	MediaDuplex,ah
	mov	MediaPause,dl
	call	_SetMacEnv
loc_3:
	retn
_hwPollLink	endp

_hwOpen		proc	near	; call in protocol bind process?
	mov	gs:[Reg.CR0c],TXON or RXON	; explicit tx/rx stop

	mov	gs:[Reg.TXE_SR],0fh	; clear tx error
	mov	gs:[Reg.RXE_SR],0fh	; clear rx error
	mov	gs:[Reg.TDCSRc],-1	; clear tx RUN/DEAD
	mov	gs:[Reg.RDCSRc],0fh	; clear rx RUM/DEAD

	mov	gs:[Reg.CR0c],STOP	; clear stop (require before start)
	mov	gs:[Reg.CR0s],STRT	; MAC start

	call	_AutoNegotiate
	mov	[MediaSpeed],al
	mov	[MediaDuplex],ah
	mov	[MediaPause],dl

	call	_ChkLink
	mov	[MediaLink],al

	call	_SetupQueues

	call	_hwUpdateMulticast
	call	_hwUpdatePktFlt

	cmp	[MediaLink],0
	jz	short loc_1

	call	_SetMacEnv
loc_1:
	mov	gs:[Reg.CR0s],TXON or RXON	; enable tx/rx
	mov	gs:[Reg.RDCSRs],RUN or WAK	; rx run and wake-up
	mov	byte ptr gs:[Reg.TDCSRs],RUN	; tx run

	xor	edx,edx
	mov	eax,I_TX or I_RX or MIB or UDP

	mov	[regIntStatus],edx
	mov	[regIntMask],eax
	mov	gs:[Reg.ISR],-1		; clear interrupt status
	mov	gs:[Reg.CR3s],GintMsk	; set global intmask
	call	_hwEnableInt

	mov	ax,SUCCESS
	retn
_hwOpen		endp

_SetMacEnv	proc	near
	mov	ax,(XONEN or FDXTFCEN or FDXRFCEN or HDXFCEN) shl 8
	cmp	al,[MediaDuplex]	; full duplex?
	jz	short loc_2
	test	[MediaPause],1		; tx pause?
	jz	short loc_1
	or	al,XONEN or FDXTFCEN
loc_1:
	test	[MediaPause],2		; rx pause?
	jz	short loc_2
	or	al,FDXRFCEN
loc_2:
	xor	ah,al			; clear bit
	mov	gs:[Reg.CR2c],ah
	mov	gs:[Reg.CR2s],al

	test	[PHY_WAF],1
	jz	short loc_nowa

	call	_PHY_WorkAround2

loc_nowa:
	mov	gs:[Reg.MIIADR],SWMPL	; initiate priority resolution

	call	_SetSpeedStat

	mov	cx,128
	push	64
loc_3:
	test	gs:[Reg.MIIADR],SWMPL	; resolution complete?
	jz	short loc_4
	call	__IODelayCnt
	dec	cx
	jnz	short loc_3
loc_4:
	pop	ax
	mov	gs:[Reg.MIICR],MAUTO	; auto-polling enable
	retn
_SetMacEnv	endp

_SetupQueues	proc	near
	push	si
	push	di
	push	offset semTx
loc_1:
	call	_EnterCrit
	mov	ax,[VTxHead]
	cmp	ax,[VTxFreeHead]
	jz	short loc_2
	call	_LeaveCrit
	call	_ClearTx
	jmp	short loc_1
loc_2:
	xor	cx,cx
	mov	ax,[VTxBase]
	mov	cl,[cfgTXQUEUE]
	mov	bx,ax
	mov	[VTxHead],ax
	mov	[VTxFreeHead],ax
	les	di,[bx].vtxd.txd
	mov	gs:[Reg.TDCSIZE],cx
	inc	cx

	shl	cx,6-2			; sizeof(TD)=64
	xor	eax,eax
	rep	stosd

	mov	gs:[Reg.DescBaseHi],eax
	mov	gs:[Reg.TDBase1Lo],eax
	mov	gs:[Reg.TDBase2Lo],eax
	mov	gs:[Reg.TDBase3Lo],eax
	mov	gs:[Reg.TDINDX0],ax
	mov	gs:[Reg.TDINDX1],ax
	mov	gs:[Reg.TDINDX2],ax
	mov	gs:[Reg.TDINDX3],ax
	mov	gs:[Reg.DataBaseHi],ax
	mov	eax,[TxBasePhys]
	mov	gs:[Reg.TDBase0Lo],eax
	call	_LeaveCrit

	push	offset semRx
	call	_EnterCrit
	xor	ax,ax
	sub	cx,cx
	mov	bx,[VRxBase]
	mov	al,[cfgRXQUEUE]
	mov	[VRxHead],bx
	mov	[VRxInProg],cx
	dec	ax			; size = count -1
	mov	gs:[Reg.RDCSIZE],ax
	inc	ax
	mov	gs:[Reg.RBRDU],ax
loc_3:
	mov	di,[bx].vrxd.rxd
	mov	[bx].vrxd.cnt,cx		; clear own/cnt
	mov	word ptr [di].RD.RSR[2],highword OWN	; set own bit
	mov	bx,[bx].vrxd.vlink
	dec	ax
	jnz	short loc_3
	mov	gs:[Reg.RDINDX],ax
	mov	eax,[RxBasePhys]
	mov	gs:[Reg.RDBaseLo],eax
	call	_LeaveCrit

	add	sp,2*2
	pop	di
	pop	si
	retn
_SetupQueues	endp

_ClearTx	proc	near
	enter	4,0
	push	offset semTx
	call	_EnterCrit
	mov	bx,[VTxHead]
	mov	ax,[VTxFreeHead]
	call	_LeaveCrit
loc_0:
	cmp	ax,bx
	jnz	short loc_1
;	add	sp,2
	leave
	retn

loc_1:
	mov	[bp-4],ax
loc_2:
	mov	ax,[bx].vtxd.vlink
	mov	cx,[bx].vtxd.reqhandle
	mov	dx,[bx].vtxd.protid
	mov	[bp-2],ax
	mov	bx,[CommonChar.moduleID]
	mov	ax,[ProtDS]

	push	dx	; ProtID
	push	bx	; MACID
	push	cx	; ReqHandle
	push	0ffh	; Status
	push	ax	; ProtDS
	call	dword ptr [LowDisp.txconfirm]
	mov	gs,[MEMSel]	; fix gs selector

	mov	bx,[bp-2]
	cmp	bx,[bp-4]
	jnz	short loc_2

	call	_EnterCrit
	mov	[VTxHead],bx		; txd head update
	mov	ax,[VTxFreeHead]
	call	_LeaveCrit
	jmp	short loc_0
_ClearTx	endp

_SetSpeedStat	proc	near
	mov	al,[MediaSpeed]
	mov	ah,0
	dec	ax
	jz	short loc_10M
	dec	ax
	jz	short loc_100M
	dec	ax
	jz	short loc_1G
	xor	ax,ax
	sub	cx,cx
	jmp	short loc_1
loc_10M:
	mov	cx,highword 10000000
	mov	ax,lowword  10000000
	jmp	short loc_1
loc_100M:
	mov	cx,highword 100000000
	mov	ax,lowword  100000000
	jmp	short loc_1
loc_1G:
	mov	cx,highword 1000000000
	mov	ax,lowword  1000000000
loc_1:
	mov	word ptr [MacChar.linkspeed],ax
	mov	word ptr [MacChar.linkspeed][2],cx
	retn
_SetSpeedStat	endp


_ChkLink	proc	near
	push	miiBMSR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	and	ax,miiBMSR_LinkStat
	add	sp,2*2
	shr	ax,2
	retn
_ChkLink	endp


_AutoNegotiate	proc	near
	enter	2,0
	push	0
	push	miiBMCR
	push	[PhyInfo.Phyaddr]
	call	_miiWrite		; clear ANEnable bit
	add	sp,3*2

	push	33
	call	_Delay1ms
	push	miiBMCR_ANEnable or miiBMCR_RestartAN
;	push	miiBMCR_ANEnable	; remove restart bit??
	push	miiBMCR
	push	[PhyInfo.Phyaddr]
	call	_miiWrite		; restart Auto-Negotiation
	add	sp,(1+3)*2

	mov	word ptr [bp-2],12*30	; about 12sec.
loc_1:
	push	33
	call	_Delay1ms
	push	miiBMCR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,(1+2)*2
	test	ax,miiBMCR_RestartAN	; AN in progress?
	jz	short loc_2
	dec	word ptr [bp-2]
	jnz	short loc_1
	jmp	short loc_f
loc_2:
	push	33
	call	_Delay1ms
	push	miiBMSR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,(1+2)*2
	test	ax,miiBMSR_ANComp	; AN Base Page exchange complete?
	jnz	short loc_3
	dec	word ptr [bp-2]
	jnz	short loc_2
	jmp	short loc_f
loc_3:
	push	33
	call	_Delay1ms
	push	miiBMSR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,(1+2)*2
	test	ax,miiBMSR_LinkStat	; link establish?
	jnz	short loc_4
	dec	word ptr [bp-2]
	jnz	short loc_3
loc_f:
	xor	ax,ax			; AN failure.
	xor	dx,dx
	leave
	retn
loc_4:
	call	_GetPhyMode
	leave
	retn
_AutoNegotiate	endp

_GetPhyMode	proc	near
	push	miiANLPAR
	push	[PhyInfo.Phyaddr]
	call	_miiRead		; read base page
	add	sp,2*2
	mov	[PhyInfo.ANLPAR],ax

	test	[PhyInfo.BMSR],miiBMSR_ExtStat
	jz	short loc_2

	push	mii1KSTSR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	mov	[PhyInfo.GSTSR],ax
;	shl	ax,2
;	and	ax,[PhyInfo.GSCR]
	shr	ax,2
	and	ax,[PhyInfo.GTCR]
;	test	ax,mii1KSCR_1KTFD
	test	ax,mii1KTCR_1KTFD
	jz	short loc_1
	mov	al,3			; media speed - 1000Mb
	mov	ah,1			; media duplex - full
	jmp	short loc_p
loc_1:
;	test	ax,mii1KSCR_1KTHD
	test	ax,mii1KTCR_1KTHD
	jz	short loc_2
	mov	al,3			; 1000Mb
	mov	ah,0			; half duplex
	jmp	short loc_p
loc_2:
	mov	ax,[PhyInfo.ANAR]
	and	ax,[PhyInfo.ANLPAR]
	test	ax,miiAN_100FD
	jz	short loc_3
	mov	al,2			; 100Mb
	mov	ah,1			; full duplex
	jmp	short loc_p
loc_3:
	test	ax,miiAN_100HD
	jz	short loc_4
	mov	al,2			; 100Mb
	mov	ah,0			; half duplex
	jmp	short loc_p
loc_4:
	test	ax,miiAN_10FD
	jz	short loc_5
	mov	al,1			; 10Mb
	mov	ah,1			; full duplex
	jmp	short loc_p
loc_5:
	test	ax,miiAN_10HD
	jz	short loc_e
	mov	al,1			; 10Mb
	mov	ah,0			; half duplex
	jmp	short loc_p
loc_e:
	xor	ax,ax
	sub	dx,dx
	retn
loc_p:
	cmp	ah,1			; full duplex?
	mov	dh,0
	jnz	short loc_np
	mov	cx,[PhyInfo.ANLPAR]
	test	cx,miiAN_PAUSE		; symmetry
	mov	dl,3			; tx/rx pause
	jnz	short loc_ex
	test	cx,miiAN_ASYPAUSE	; asymmetry
	mov	dl,2			; rx pause
	jnz	short loc_ex
loc_np:
	mov	dl,0			; no pause
loc_ex:
	retn
_GetPhyMode	endp


_ResetPhy	proc	near
	enter	2,0
	call	_miiReset	; Reset Interface
	push	miiPHYID2
;	push	1		; phyaddr 1
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	mov	[PhyInfo.PHYIDR2],ax
	or	ax,ax		; ID2 = 0
	jz	short loc_1
	inc	ax		; ID2 = -1
	jnz	short loc_2
loc_1:
	mov	ax,HARDWARE_FAILURE
	leave
	retn
loc_2:
;	mov	[PhyInfo.Phyaddr],1
	push	miiPHYID1
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	mov	[PhyInfo.PHYIDR1],ax

	push	miiBMCR_Reset
	push	miiBMCR
	push	[PhyInfo.Phyaddr]
	call	_miiWrite	; Reset PHY
	add	sp,3*2

	push	1536		; wait for about 1.5sec.
	call	_Delay1ms
	pop	ax

	call	_miiReset	; interface reset again
	mov	word ptr [bp-2],64  ; about 2sec.
loc_3:
	push	miiBMCR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	test	ax,miiBMCR_Reset
	jz	short loc_4
	push	33
	call	_Delay1ms	; wait reset complete.
	pop	ax
	dec	word ptr [bp-2]
	jnz	short loc_3
	jmp	short loc_1	; PHY Reset Failure
loc_4:
	push	miiBMSR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	mov	[PhyInfo.BMSR],ax
	push	miiANAR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	mov	[PhyInfo.ANAR],ax
	test	[PhyInfo.BMSR],miiBMSR_ExtStat
	jz	short loc_5	; extended status exist?
	push	mii1KTCR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	mov	[PhyInfo.GTCR],ax
	push	mii1KSCR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	add	sp,2*2
	mov	[PhyInfo.GSCR],ax
	xor	cx,cx
	test	ax,mii1KSCR_1KTFD or mii1KSCR_1KXFD
	jz	short loc_41
	or	cx,mii1KTCR_1KTFD
loc_41:
	test	ax,mii1KSCR_1KTHD or mii1KSCR_1KXHD
	jz	short loc_42
	or	cx,mii1KTCR_1KTHD
loc_42:
	mov	ax,[PhyInfo.GTCR]
	and	ax,not (mii1KTCR_MSE or mii1KTCR_Port or \
		  mii1KTCR_1KTFD or mii1KTCR_1KTHD)
	or	ax,cx
	mov	[PhyInfo.GTCR],ax
	push	ax
	push	mii1KTCR
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,3*2
loc_5:
	mov	ax,[PhyInfo.BMSR]
	mov	cx,miiAN_PAUSE
	test	ax,miiBMSR_100FD
	jz	short loc_61
	or	cx,miiAN_100FD
loc_61:
	test	ax,miiBMSR_100HD
	jz	short loc_62
	or	cx,miiAN_100HD
loc_62:
	test	ax,miiBMSR_10FD
	jz	short loc_63
	or	cx,miiAN_10FD
loc_63:
	test	ax,miiBMSR_10HD
	jz	short loc_64
	or	cx,miiAN_10HD
loc_64:
	mov	ax,[PhyInfo.ANAR]
	and	ax,not (miiAN_ASYPAUSE + miiAN_T4 + \
	  miiAN_100FD + miiAN_100HD + miiAN_10FD + miiAN_10HD)
	or	ax,cx
	mov	[PhyInfo.ANAR],ax
	push	ax
	push	miiANAR
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,3*2

	call	_PHY_WorkAround

	mov	ax,SUCCESS
	leave
	retn

_ResetPhy	endp

_PHY_WorkAround	proc	near
	mov	dx,[PhyInfo.PHYIDR1]
	mov	ax,[PhyInfo.PHYIDR2]
	and	ax,-10		; clear revision
	cmp	dx,highword PHYID_MARVELL_1000
	jz	short loc_Marvell
	cmp	dx,highword PHYID_CICADA_CS8201
	jnz	short loc_ex
	cmp	ax,lowword PHYID_VT3216_32BIT
	jz	short loc_VT
	cmp	ax,lowword PHYID_VT3216_64BIT
	jz	short loc_VT
	cmp	ax,lowword PHYID_CICADA_CS8201
	jnz	short loc_ex

	push	1ch
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	or	ax,4
	push	ax
	push	1ch
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,5*2

	push	1bh
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	or	ax,4
	push	ax
	push	1bh
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,5*2
loc_VT:
	or	[PHY_WAF],1
loc_ex:
	retn

loc_Marvell:
	cmp	ax,lowword PHYID_MARVELL_1000
	jz	short loc_mar1
	cmp	ax,lowword PHYID_MARVELL_1000S
	jnz	short loc_ex
loc_mar1:
	push	10h
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	or	ax,0bh
	push	ax
	push	10h
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,5*2

	retn
_PHY_WorkAround	endp

_PHY_WorkAround2	proc	near
	mov	al,[MediaSpeed]
	cmp	al,2
	ja	short loc_ex	; 1000M
	cmp	al,1
	jc	short loc_ex	; speed detection failure

	push	miiTCSR
	push	[PhyInfo.Phyaddr]
	call	_miiRead
	mov	cl,[MediaDuplex]
	and	ax,not TCSR_ECHODIS
	shl	cx,13
	or	ax,cx
	push	ax
	push	miiTCSR
	push	[PhyInfo.Phyaddr]
	call	_miiWrite
	add	sp,5*2
loc_ex:
	retn
_PHY_WorkAround2	endp


_hwUpdateMulticast	proc	near
	enter	2+8,0
	push	di
	push	offset semFlt
	call	_EnterCrit

	bt	[MacStatus.sstRxFilter],fltprms
	sbb	ax,ax			; 0/-1
	mov	[bp-10],ax
	mov	[bp-8],ax
	mov	[bp-6],ax
	mov	[bp-4],ax	; clear/set hash table
	jnz	short loc_2	; promiscous mode

	mov	ax,[MCSTList.curnum]
	dec	ax
	jl	short loc_2	; no multicast
	mov	[bp-2],ax
loc_1:
	mov	ax,[bp-2]
	shl	ax,4		; 16bytes
	add	ax,offset MCSTList.multicastaddr1
	push	ax
	call	_CRC32
	shr	dx,10		; the 6 most significant bits
	pop	ax	; stack adjust
	mov	di,dx
	mov	cx,dx
	shr	di,4
	and	cl,0fh		; the bit index in word
	mov	ax,1
	add	di,di		; the word index (2byte)
	shl	ax,cl
	or	word ptr [bp+di-10],ax
	dec	word ptr [bp-2]
	jge	short loc_1
loc_2:
	mov	eax,dword ptr [bp-10]
	mov	ecx,dword ptr [bp-6]
	mov	gs:[Reg.MARCAM],eax
	mov	gs:[Reg.MARCAM][4],ecx

	call	_LeaveCrit
	pop	cx	; stack adjust
	pop	di
	mov	ax,SUCCESS
	leave
	retn
_hwUpdateMulticast	endp

_CRC32		proc	near
POLYNOMIAL_be   equ  04C11DB7h
POLYNOMIAL_le   equ 0EDB88320h

	push	bp
	mov	bp,sp

	push	si
	push	di
	or	ax,-1
	mov	bx,[bp+4]
	mov	ch,3
	cwd

loc_1:
	mov	bp,[bx]
	mov	cl,10h
	inc	bx
loc_2:
IF 1
		; big endian

	ror	bp,1
	mov	si,dx
	xor	si,bp
	shl	ax,1
	rcl	dx,1
	sar	si,15
	mov	di,si
	and	si,highword POLYNOMIAL_be
	and	di,lowword POLYNOMIAL_be
ELSE
		; litte endian
	mov	si,ax
	ror	bp,1
	ror	si,1
	shr	dx,1
	rcr	ax,1
	xor	si,bp
	sar	si,15
	mov	di,si
	and	si,highword POLYNOMIAL_le
	and	di,lowword POLYNOMIAL_le
ENDIF
	xor	dx,si
	xor	ax,di
	dec	cl
	jnz	short loc_2
	inc	bx
	dec	ch
	jnz	short loc_1
	push	dx
	push	ax
	pop	eax
	pop	di
	pop	si
	pop	bp
	retn
_CRC32		endp

_hwUpdatePktFlt	proc	near
	push	offset semFlt
	call	_EnterCrit

	mov	al,[cfgRxAcErr]
	mov	cx,[MacStatus.sstRxFilter]

	test	cl,mask fltdirect
	jnz	short loc_1
	mov	gs:[Reg.CR1s],DISAU	; disable unicast
	jmp	short loc_2
loc_1:
	mov	gs:[Reg.CR1c],DISAU	; enable unicast
	or	al,AM			; multicast
loc_2:
	test	cl,mask fltbroad
	jz	short loc_3
	or	al,AB			; broadcast
loc_3:
	test	cl,mask fltprms
	jz	short loc_4
	or	al,AM or AB or PROM	; promiscous
	mov	gs:[Reg.CR1c],DISAU	; enable unicast
	or	edx,-1
	mov	gs:[Reg.MARCAM],edx
	mov	gs:[Reg.MARCAM][4],edx
loc_4:
	mov	gs:[Reg.RxCR],al

	call	_LeaveCrit
	pop	cx
	mov	ax,SUCCESS
	retn
_hwUpdatePktFlt	endp

_hwSetMACaddr	proc	near
	push	offset semFlt
	call	_EnterCrit

	mov	bx,offset MacChar.mctcsa
	mov	ax,[bx]
	or	ax,[bx+2]
	or	ax,[bx+4]
	jnz	short loc_1
	mov	bx,offset MacChar.mctpsa
loc_1:
	mov	eax,[bx]
	mov	cx,[bx+4]
	mov	dword ptr gs:[Reg.PAR],eax
	mov	word ptr gs:[Reg.PAR][4],cx

	call	_LeaveCrit
	pop	cx
	mov	ax,SUCCESS
	retn
_hwSetMACaddr	endp

_hwUpdateStat	proc	near
	push	offset semStat
	call	_EnterCrit

	mov	gs:[Reg.MIBCR],MBTRINI or MIBFREEZE
	mov	bx,offset MacStatus

	call	__mibRead	; 1
	call	__mibRead	; 2
	add	[bx].mst.rxframe,eax
	call	__mibRead	; 3
	add	[bx].mst.txframe,eax
	call	__mibRead	; 4
	add	[bx].mst.rxframehw,eax
	call	__mibRead	; 5
	add	[bx].mst.rxframebuf,eax
	call	__mibRead	; 6
	add	[bx].mst.rxframehw,eax
	mov	cx,13
loc_1:
	call	__mibRead	; 7..19
	dec	cx
	jnz	short loc_1
	call	__mibRead	; 20
	add	[bx].mst.rxframecrc,eax
	mov	cx,4
loc_2:
	call	__mibRead	; 21..24
	dec	cx
	jnz	short loc_2
	call	__mibRead	; 25
	add	[bx].mst.rxframecrc,eax
	call	__mibRead	; 26
	add	[bx].mst.rxframebuf,eax
	call	__mibRead	; 27
	add	[bx].mst.rxframebuf,eax
	call	__mibRead	; 28
	add	[bx].mst.txframehw,eax
	call	__mibRead	; 29
	add	[bx].mst.rxframebuf,eax
	call	__mibRead	; 30
	add	[bx].mst.rxframehw,eax
	call	__mibRead	; 31
	call	__mibRead	; 32
	add	[bx].mst.txframeto,eax

	mov	gs:[Reg.MIBCR],0

	call	_LeaveCrit
	pop	ax	; stack adjust
	retn

__mibRead	proc	near
	mov	eax,gs:[Reg.MIBDATA]
	and	eax,MIB_data
	retn
__mibRead	endp
_hwUpdateStat	endp

_hwClearStat	proc	near
	push	offset semStat
	call	_EnterCrit

	mov	bx,offset Reg.MIBCR

	mov	byte ptr gs:[bx],MIBFREEZE	; stop
	mov	al,gs:[bx]
	mov	byte ptr gs:[bx],MIBCLR or MIBFREEZE
	mov	al,gs:[bx]
	mov	byte ptr gs:[bx],0

	call	_LeaveCrit
	pop	ax	; stack adjust
	retn
_hwClearStat	endp

_hwClose	proc	near
	mov	gs:[Reg.CR3c],GintMsk	; clear global intmask
	call	_hwDisableInt		; clear IMR

	mov	gs:[Reg.RDCSRc],RUN		; stop rx
	mov	byte ptr gs:[Reg.TDCSRc],RUN	; stop tx

	mov	gs:[Reg.CR0c],TXON or RXON	; disable tx/rx
	call	_ClearTx
	mov	gs:[Reg.CR0s],STOP		; stop MAC

	mov	ax,SUCCESS
	retn
_hwClose	endp

_hwReset	proc	near	; call in bind process
	enter	6,0

	call	_hwDisableInt
	mov	gs:[Reg.CR1s],SFRST	; reset
	mov	byte ptr [bp-2],32	; about 3sec.
	push	96			; 256ms
loc_1:
	call	_Delay1ms
	test	gs:[Reg.CR1s],SFRST	; reset complete?
	jz	short loc_2
	dec	byte ptr [bp-2]
	jnz	short loc_1
loc_er:
	mov	ax,HARDWARE_FAILURE
	leave
	retn

loc_2:
;	add	sp,2
			; read eeprom
	or	gs:[Reg.CFGC],EELOAD	; eeprom access enable
	push	0fh			; programed check
	call	_eepRead
;	add	sp,2
	cmp	al,73h
	jnz	short loc_er
	push	0			; 0..2  MAC address
	call	_eepRead
	mov	[bp-6],ax
	push	1
	call	_eepRead
	mov	[bp-4],ax
	push	2
	call	_eepRead
	mov	[bp-2],ax
	push	3			; 3 PHY address
	call	_eepRead
	and	ax,PHYAD
	mov	[PhyInfo.Phyaddr],ax	; may not be used
;	add	sp,4*2

;	push	offset semFlt
;	call	_EnterCrit
	mov	ax,[bp-6]		; set station addresses
	mov	cx,[bp-4]
	mov	dx,[bp-2]
	mov	word ptr MacChar.mctpsa,ax	; parmanent
	mov	word ptr MacChar.mctpsa[2],cx
	mov	word ptr MacChar.mctpsa[4],dx
	mov	word ptr MacChar.mctcsa,ax	; current
	mov	word ptr MacChar.mctcsa[2],cx
	mov	word ptr MacChar.mctcsa[4],dx
	mov	word ptr MacChar.mctVendorCode,ax ; vendor
	mov	byte ptr MacChar.mctVendorCode[2],cl
;	call	_LeaveCrit
;	add	sp,2

	mov	gs:[Reg.EECSR],RELOAD	; eeprom reload
	mov	byte ptr [bp-2],32	; about 3sec.
	push	96			; 256ms
loc_3:
	call	_Delay1ms
	test	gs:[Reg.EECSR],RELOAD	; reload complete?
	jz	short loc_4
	dec	byte ptr [bp-2]
	jnz	short loc_3
	jmp	short loc_er
;	mov	ax,HARDWARE_FAILURE
;	leave
;	retn

loc_4:
;	add	sp,2
	and	gs:[Reg.CFGC],not EELOAD ; explicit eeprom disable

	mov	gs:[Reg.WOLCRc],-1	; disable WOL
	mov	gs:[Reg.WOLSRc],-1	; clear WOL event state
	and	gs:[Reg.STKSHDW],\
		  not(STKDS1 or STKDS0)	; force D0 mode (^^;;
	mov	gs:[Reg.PWCFGc],PME_SR	; clear PME_STS (^^//

	mov	gs:[Reg.CR3s],DIAG	; diagnostic  CFGD writeable
	and	gs:[Reg.CFGD],not CFGDACEN ; disable 64bit dual address cycle
	mov	gs:[Reg.CR3c],DIAG

	mov	al,[cfgDCFG1]
	cmp	[CacheLine],0		; cache line size is valid?
	jnz	short loc_5
	or	al,XMRL			; disable read cache line
	and	al,not MRDPL		; disable read multiple
loc_5:
	mov	gs:[Reg.DCFG1],al

	mov	al,gs:[Reg.DCFG0]
	and	al,not DMALEN
	or	al,[cfgMXDMA]
	mov	gs:[Reg.DCFG0],al	; set DMA Burst length

	mov	al,gs:[Reg.MCFG0]
	and	al,48h			; reserve LOWTHOPT
	or	al,[cfgMCFG0]
	mov	gs:[Reg.MCFG0],al	; set RXARB, Rx FIFO Threshold

	mov	al,gs:[Reg.MCFG1]
	and	al,7fh
	or	al,[cfgMCFG1]
	mov	gs:[Reg.MCFG1],al	; set TXARB

	mov	al,byte ptr [PhyInfo.Phyaddr]
	mov	gs:[Reg.MIICFG],al	; MII auto-polling timing, set PHY adr?

	mov	al,[cfgFLTH]
	mov	gs:[Reg.CR2c],-1	; clear pause function
	mov	gs:[Reg.CR2s],al	; set pause threshold
	mov	gs:[Reg.TXPUTM],-1	; XON(0)/XOFF(ffff) scheme

	mov	al,[cfgTQETMR]
	mov	ah,[cfgRQETMR]
	mov	gs:[Reg.TQETMR],al	; what? waht interrupt? PPTX,PPRX?
	mov	gs:[Reg.RQETMR],ah	; descriptor auto-polling timing?

	mov	al,[cfgDAPOLL]
	mov	gs:[Reg.CR1s],DPOLL
	shl	al,3
	mov	gs:[Reg.CR1c],al	; clear auto-polling disable

	xor	ax,ax
	mov	gs:[Reg.CAMCR],PS0	; page1
	mov	al,[cfgTXSUPPTHR]
	mov	gs:[Reg.ISR_CTL],ax	; set TxSuppThr counter

	mov	gs:[Reg.CAMCR],PS1	; page2
	mov	al,[cfgRXSUPPTHR]
	mov	gs:[Reg.ISR_CTL],ax	; set RxSuppThr counter

	mov	gs:[Reg.CAMCR],0	; return to page0
	mov	gs:[Reg.CR3c],INTPCTL or SWPEND
	mov	al,[cfgINTHOTMR]
	mov	ah,[cfgIHLAYER]
	shl	ah,3			; hold-off layer

	cmp	[cfgTXSUPPTHR],0	; tx count invalid?
	jnz	short loc_6
	or	ah,high(TSUPP_DIS)
loc_6:
	cmp	[cfgRXSUPPTHR],0	; rx count invalid?
	jnz	short loc_7
	or	ah,high(RSUPP_DIS)
loc_7:
	xor	cx,cx
	or	al,al			; timer valid?
	jz	short loc_8
	or	ah,high(HC_RELOAD)
;	mov	cl,INTPCTL or SWPEND
	mov	cl,INTPCTL		; remove SWPEND
loc_8:
	mov	gs:[Reg.ISR_CTL],ax	; hold-off timer/layer
	mov	gs:[Reg.CR3s],cl	; enable hold-off

	cmp	[cfgMAXFRAMESIZE],1514
	seta	al
	shl	al,5			; AL bit
	or	[cfgRxAcErr],al		; accept long packet

	call	_hwClearStat
	call	_ResetPhy

	leave
	retn
_hwReset	endp


; USHORT miiRead( UCHAR phyaddr, UCHAR phyreg)
_miiRead	proc	near
	push	bp
	mov	bp,sp
	push	offset semMii
	call	_EnterCrit

	mov	gs:[Reg.MIICR],0
	mov	cx,40h
	push	8
loc_1:
	test	gs:[Reg.MIISR],MIIDL
	jnz	short loc_2
	call	__IODelayCnt
	dec	cx
	jnz	short loc_1

loc_2:
	mov	al,[bp+6]
	mov	gs:[Reg.MIIADR],al	; reg addr
	mov	gs:[Reg.MIICR],RCMD	; embedded read

	mov	cx,40h
loc_3:
	call	__IODelayCnt
	test	gs:[Reg.MIICR],RCMD
	jz	short loc_4
	dec	cx
	jnz	short loc_3
loc_4:
	mov	ax,gs:[Reg.MIIDATA]
	pop	cx	; stack adjust
	call	_LeaveCrit
	leave
	retn
_miiRead	endp

; VOID miiWrite( UCHAR phyaddr, UCHAR phyreg, USHORT value)
_miiWrite	proc	near
	push	bp
	mov	bp,sp
	push	offset semMii
	call	_EnterCrit

	mov	gs:[Reg.MIICR], 0	; clear MAUTO, MDPM
					; embedded mode  phyaddr ignored
	mov	cx,40h
	push	8
loc_1:
	test	gs:[Reg.MIISR],MIIDL	; polling cycle active?
	jnz	short loc_2
	call	__IODelayCnt
	dec	cx
	jnz	short loc_1
loc_2:
	mov	cl,[bp+6]		; register
	mov	ax,[bp+8]		; data value

	mov	gs:[Reg.MIIADR],cl
	mov	gs:[Reg.MIIDATA],ax
	mov	gs:[Reg.MIICR],WCMD

	mov	cx,40h
loc_3:
	call	__IODelayCnt
	test	gs:[Reg.MIICR],WCMD
	jz	short loc_4
	dec	cx
	jnz	short loc_3
loc_4:
	pop	cx	; stack adjust
	call	_LeaveCrit
	leave
	retn
_miiWrite	endp

; VOID miiReset( VOID )
_miiReset	proc	near
	push	offset semMii
	call	_EnterCrit
	mov	bx,offset Reg.MIICR
	push	2

	mov	gs:[bx],byte ptr 0	; clear auto-polling
	mov	cx,100h
loc_1:
	test	gs:[Reg.MIISR],MIIDL
	jnz	short loc_2
	call	__IODelayCnt
	dec	cx
	jnz	short loc_1
loc_2:
	mov	cx,32			; 32clocks
loc_3:
	mov	al,MDO or MOUT or MDPM	; high
	mov	byte ptr gs:[bx],al
	call	__IODelayCnt
	or	al,MDC
	mov	gs:[bx],al
	call	__IODelayCnt
	loop	short loc_3

	pop	cx	; stack adjust
	call	_LeaveCrit
	pop	cx	; stack adjust
loc_ex:
	retn
_miiReset	endp


; USHORT eepRead( UCHAR addr )
_eepRead	proc	near
	push	bp
	mov	bp,sp

	mov	gs:[Reg.EECSR],EMBP	; embedded mode enable
	mov	al,[bp+4]
	mov	gs:[Reg.EADDR],al	; address
	mov	gs:[Reg.EMBCMD],ERD	; read command

	mov	cx,64
	push	32
loc_1:
	call	__IODelayCnt
	test	gs:[Reg.EMBCMD],ERD	; complete clear?
	jz	short loc_2
	dec	cx
	jnz	short loc_1
loc_2:
	mov	ax,gs:[Reg.EE_RD_DATA]
	mov	gs:[Reg.EECSR],0	; embedded mode disable

;	pop	cx
	leave
	retn
_eepRead	endp


; void _IODelayCnt( USHORT count )
__IODelayCnt	proc	near
	push	bp
	mov	bp,sp
	push	cx
	mov	bp,[bp+4]
loc_1:
	mov	cx,offset DosIODelayCnt
	dec	bp
	loop	$
	jnz	short loc_1
	pop	cx
	pop	bp
	retn
__IODelayCnt	endp


_TEXT	ends
end
