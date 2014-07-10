; *** Hardware dependent resident part definition

; --- DMA Descriptor management ---
extern	VTxHead : word
extern	VTxFreeHead : word
extern	VTxBase : word
extern	TxBasePhys : dword

extern	VRxInProg : word
extern	VRxHead : word
extern	VRxBase : word
extern	RxBasePhys : dword

; --- System(PCI) Resource ---
;extern	IOaddr : word
extern	MEMSel : word		; selector for MEMaddr
extern	MEMaddr : dword
extern	IRQlevel : byte
extern	CacheLine : byte
extern	Latency : byte

; --- Configuration Memory Image Parameters ---
extern	cfgSLOT : byte
extern	cfgTXQUEUE : byte
extern	cfgRXQUEUE : byte
extern	cfgMAXFRAMESIZE : word

extern	cfgMXDMA : byte
extern	cfgDCFG1 : byte
extern	cfgMCFG0 : byte
extern	cfgMCFG1 : byte
extern	cfgFLTH : byte

extern	cfgTXSUPPTHR : byte
extern	cfgRXSUPPTHR : byte
extern	cfgINTHOTMR : byte
extern	cfgIHLAYER : byte

extern	cfgTQETMR : byte
extern	cfgRQETMR : byte
extern	cfgDAPOLL : byte

extern	cfgRxAcErr : byte
extern	cfgChecksumMask : byte

; --- Receive Buffer Address ---
extern	RxBufferLin : dword
extern	RxBufferPhys : dword
extern	RxBufferSize : dword
extern	SelCnt : word
extern	TxDescSel : word
extern	TxCopySel : word
extern	RxBufferSel : word


; ---Vendor Adapter Description ---
extern	AdapterDesc : byte


; --- Hardware Depended Services ---
extern	_hwTxChain : near16
extern	_hwRxRelease : near16
extern	_hwEnableRxInd : near16
extern	_hwDisableRxInd : near16
extern	_hwSetMACaddr : near16
extern	_hwOpen : near16
extern	_hwClose : near16
extern	_hwIntReq : near16
extern	_hwUpdatePktFlt : near16
extern	_hwUpdateMulticast : near16
extern	_hwUpdateStat : near16
extern	_hwClearStat : near16
extern	_hwReset : near16

extern	_hwCheckInt : near16
extern	_hwDisableInt : near16
extern	_hwEnableInt : near16
extern	_hwServiceInt : near16
extern	_hwPollLink : near16


; --- Driver Version ---
extern	DrvMajVer : abs
extern	DrvMinVer : abs

