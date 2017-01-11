
; KmdManager - utility for simplify kmd un/loading and sending control codes
; Written by Four-F (four-f@mail.ru)

.386
.model flat, stdcall
option casemap:none

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                  I N C L U D E   F I L E S                                        
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

include windows.inc

include user32.inc
include kernel32.inc
include advapi32.inc
include comdlg32.inc
include shell32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib advapi32.lib
includelib comdlg32.lib
includelib shell32.lib
includelib gdi32.lib

include Macros.mac
include E:\WinAsmFull505\masm32\Macros\Strings.mac
include E:\WinAsmFull505\masm32\cocomac\cocomac.mac
include E:\WinAsmFull505\masm32\cocomac\ListView.mac
include htodw.asm
include dwtohex.asm
include memory.asm
include string.asm
include MaskedEdit.asm
include theme.asm

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                         F U N C T I O N S   P R O T O T Y P E S                                   
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

DlgProc 			proto :HWND, :UINT, :WPARAM, :LPARAM
DlgOptionsProc 		proto :HWND, :UINT, :WPARAM, :LPARAM
DlgDumpProc 		proto :HWND, :UINT, :WPARAM, :LPARAM
DlgEditProc 		proto :HWND, :UINT, :WPARAM, :LPARAM
PrintHexDump 		proto :HWND, :LPSTR,:DWORD

IDD_DIALOG				equ		1000
IDD_OPTIONS				equ		1100
IDD_DUMP				equ		1200
IDD_EDIT				equ		1300

IDB_BROWSE				equ		1001
IDB_REGISTER			equ		1002
IDB_RUN					equ		1003
IDB_IOCONTROL			equ		1004
IDB_UNREGISTER			equ		1005
IDB_STOP				equ		1006
IDB_OPTIONS				equ		1007
IDB_ABOUT				equ		1008
IDB_EXIT				equ		1009
IDB_OPTAPPLY			equ		1101
IDB_OPTCLOSE			equ		1102
IDB_EDITBUFFER			equ		1103
IDB_PUTVALUE			equ		1300
IDB_PUTSTRING			equ		1301
IDB_CLAERBUFFER			equ		1302

IDCHK_REGTORUNLINK		equ		1010
IDCHK_UNREGTOSTOPLINK	equ		1011
IDCHK_IOCONTROLLINK		equ		1012
IDCHK_INPUTBUFFER		equ		1111
IDCHK_OUTPUTBUFFER		equ		1112
IDCHK_SHOWBUFFER		equ		1113

IDL_INPUTBUFFER			equ		1150
IDL_OUTPUTBUFFER		equ		1151
IDL_VALUE				equ		1351

IDE_PATH				equ		1020
IDE_CONTROL_CODE		equ		1021
IDE_INPUTBUFFER			equ		1120
IDE_OUTPUTBUFFER		equ		1121
IDE_DUMP				equ		1220
IDE_EDITDUMP			equ		1320
IDE_EDITOFFSET			equ		1321
IDE_EDITVALUE			equ		1322
IDE_EDITSTRING			equ		1323

IDC_REPORT_LIST			equ		1030

IDR_BYTE				equ		1340
IDR_WORD				equ		1341
IDR_DWORD				equ		1342

IDI_ICON				equ		2000

IDM_CLEAR_LOG			equ		5000

TEXT_BUFFER_SIZE		equ 	300000

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                      U S E R   D E F I N E D   S T R U C T U R E S                                
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                     C O N S T A N T S                                             
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

.const
g_szFilterString		db "Kernel-Mode Drivers", 0, "*.sys", 0
						db "All Files", 0, "*.*", 0, 0

g_szOpenDriverTitle		db "Choose Driver", 0

g_szSuccess				db "Success", 0
g_szFail				db "Fail", 0
g_szCriticalError		db "Critical Error", 0
g_szOpenSCManagerError	db "Can't get Service Control Manager handle.", 0
g_szEnterFullDriverPath	db "Enter full driver path.", 0

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                              I N I T I A L I Z E D  D A T A                                       
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

.data

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                              U N I N I T I A L I Z E D  D A T A                                   
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

.data?
g_hInstance				HINSTANCE	?
;g_pfnPrevStaticProc		LPVOID		?
g_hwndEditDriverPath	HWND		?
g_hwndEditControlCode	HWND		?
g_hwndReportListView	HWND		?

g_hwndButtonRegister	HWND		?
g_hwndButtonRun			HWND		?
g_hwndButtonControl		HWND		?
g_hwndButtonStop		HWND		?
g_hwndButtonUnregister	HWND		?
g_hListViewPopupMenu	HMENU		?
g_hwndCheckRegToRun		HWND		?
g_hwndCheckUnregToStop	HWND		?
g_hwndCheckLinkAll		HWND		?

g_hwndEditDump			HWND		?
g_hwndMain				HWND		?

g_pfnListViewProcPrev	LPVOID		?
g_lpstrCmdLine			LPSTR		?

g_acErrorDescription	CHAR	256	dup(?)


g_dwDlgMinHeight		DWORD		?
g_dwDlgMaxHeight		DWORD		?

g_dwDlgWidth			DWORD		?

g_InputBufferSize		DWORD		?
g_OutputBufferSize		DWORD		?
g_LastBytesRet			DWORD		?
g_CurValueMode			DWORD		?
g_OutputBuffer			PVOID		?
g_InputBuffer			PVOID		?
g_bInputBuffer			BOOL		?
g_bOutputBuffer			BOOL		?
g_bShowBuffer			BOOL		?
g_bNotClearBuffer		BOOL		?

g_hFontOld				HFONT		?
g_hFontNew				HFONT		?

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                       C O D E                                                     
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

.code

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                        LastError                                                  
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

LastError proc; pacBuffer:LPVOID

    pushfd
    pushad
    
    invoke GetLastError
    push eax

	invoke RtlZeroMemory, offset g_acErrorDescription, sizeof g_acErrorDescription
	pop eax
    mov ecx, SUBLANG_DEFAULT
    shl ecx, 10
    add ecx, LANG_NEUTRAL               ; MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT) User default language
    
    invoke FormatMessage, FORMAT_MESSAGE_FROM_SYSTEM + FORMAT_MESSAGE_MAX_WIDTH_MASK, NULL, \
    						eax, ecx, offset g_acErrorDescription, 128, NULL

    .if eax == 0
		invoke lstrcpy, offset g_acErrorDescription, $CTA0("Error number not found.")
    .endif

    popad
    popfd
    
    ret

LastError endp

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                      ReportStatus                                                 
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

ReportStatus proc uses esi pszDriverName:LPSTR, pszOperation:LPSTR, pszStatus:LPSTR, pszLastError:LPSTR

LOCAL lvi:LV_ITEM

	mov lvi.imask, LVIF_TEXT 
	m2m lvi.pszText,pszDriverName
	and lvi.iSubItem, 0
	ListView_GetItemCount g_hwndReportListView
	mov esi, eax
	mov lvi.iItem, eax

	ListView_InsertItem g_hwndReportListView, addr lvi	

	ListView_SetItemText g_hwndReportListView, esi, 1, pszOperation
	ListView_SetItemText g_hwndReportListView, esi, 2, pszStatus
	ListView_SetItemText g_hwndReportListView, esi, 3, pszLastError

	; Make it fully visible
	ListView_EnsureVisible g_hwndReportListView, esi, FALSE

	ret

ReportStatus endp

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                     RegisterDriver                                                
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

RegisterDriver proc uses esi edi ebx pszDriverName:LPSTR, pszDriverPath:LPSTR

	xor ebx, ebx		; assume error
	mov edi, offset g_szFail

	invoke OpenSCManager, NULL, NULL, SC_MANAGER_CREATE_SERVICE
	.if eax != NULL
		mov esi, eax

		; Register driver - fill registry directory
		invoke CreateService, esi, pszDriverName, pszDriverName, \
					0, SERVICE_KERNEL_DRIVER, SERVICE_DEMAND_START, SERVICE_ERROR_IGNORE, \
					pszDriverPath, NULL, NULL, NULL, NULL, NULL

		invoke LastError

		.if eax != NULL
			invoke CloseServiceHandle, eax
			inc ebx					; success
			mov edi, offset g_szSuccess
		.endif
		invoke CloseServiceHandle, esi
	.else
		invoke MessageBox, NULL, addr g_szOpenSCManagerError, addr g_szCriticalError, MB_OK + MB_ICONSTOP
	.endif

	invoke ReportStatus, pszDriverName, $CTA0("Register"), edi, offset g_acErrorDescription

	return ebx

RegisterDriver endp

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                    UnregisterDriver                                               
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

UnregisterDriver proc uses esi edi ebx pszDriverName:LPSTR

	xor ebx, ebx		; assume error
	mov edi, offset g_szFail

	invoke OpenSCManager, NULL, NULL, SC_MANAGER_CONNECT
	.if eax != NULL
		mov esi, eax
		
		; Unregister driver - remove registry directory
		invoke OpenService, esi, pszDriverName, DELETE

		invoke LastError

		.if eax != NULL
			push eax
			invoke DeleteService, eax

			invoke LastError

			.if eax != 0
				inc ebx					; success
				mov edi, offset g_szSuccess
			.endif
			call CloseServiceHandle
		.endif

		invoke CloseServiceHandle, esi
	.else
		invoke MessageBox, NULL, addr g_szOpenSCManagerError, addr g_szCriticalError, MB_OK + MB_ICONSTOP
	.endif

	invoke ReportStatus, pszDriverName, $CTA0("Unregister"), edi, offset g_acErrorDescription

	return ebx

UnregisterDriver endp


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                       RunDriver                                                   
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

RunDriver proc uses esi edi ebx pszDriverName:LPSTR

	xor ebx, ebx		; assume error
	mov edi, offset g_szFail

	invoke OpenSCManager, NULL, NULL, SC_MANAGER_CONNECT
	.if eax != NULL
		mov esi, eax
		
		; Unregister driver - remove registry directory
		invoke OpenService, esi, pszDriverName, SERVICE_START

		invoke LastError

		.if eax != NULL
			push eax
			invoke StartService, eax, 0, NULL
			
			invoke LastError
			
			.if eax != 0
				inc ebx					; success
				mov edi, offset g_szSuccess
			.endif

			call CloseServiceHandle
			mov edi, offset g_szSuccess
		.endif
		invoke CloseServiceHandle, esi
	.else
		invoke MessageBox, NULL, addr g_szOpenSCManagerError, addr g_szCriticalError, MB_OK + MB_ICONSTOP
	.endif

	invoke ReportStatus, pszDriverName, $CTA0("Start"), edi, offset g_acErrorDescription

	return ebx

RunDriver endp

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                       StopDriver                                                  
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

StopDriver proc uses esi ebx pszDriverName:LPSTR

LOCAL sest:SERVICE_STATUS

	xor ebx, ebx		; assume error
	mov edi, offset g_szFail

	invoke OpenSCManager, NULL, NULL, SC_MANAGER_CONNECT
	.if eax != NULL
		mov esi, eax
		
		; Unregister driver - remove registry directory
		invoke OpenService, esi, pszDriverName, SERVICE_STOP

		invoke LastError

		.if eax != NULL
			push eax
			mov ecx, eax
			invoke ControlService, ecx, SERVICE_CONTROL_STOP, addr sest
			
			invoke LastError

			.if eax != 0
				inc ebx					; success
				mov edi, offset g_szSuccess
			.endif
			call CloseServiceHandle
		.endif

		invoke CloseServiceHandle, esi
	.else
		invoke MessageBox, NULL, addr g_szOpenSCManagerError, addr g_szCriticalError, MB_OK + MB_ICONSTOP
	.endif

	invoke ReportStatus, pszDriverName, $CTA0("Stop"), edi, offset g_acErrorDescription

	return ebx

StopDriver endp

PrintHexDump proc hEditWnd: HWND, lpszBuffer: LPSTR, dwBufferSize: DWORD
	local pTextBuffer: PVOID
	local dwCurr: DWORD
	local dwTextSize: DWORD
	
.data
	szFmt	db "%08X:  %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X  ", 0
.code
	pushad
	push lpszBuffer
	pop	dwCurr
	invoke SendMessage, hEditWnd, WM_SETTEXT, 0, 0
	mov ebx, dwBufferSize
	imul ebx, 1000h
	shr ebx, 4
	mov dwTextSize, ebx
	imul ebx, 80
	invoke VirtualAlloc, NULL, ebx, MEM_COMMIT + MEM_RESERVE, PAGE_READWRITE
	mov pTextBuffer, eax
	xchg edi, eax
	mov esi, dwCurr
	mov ebx, dwTextSize
	.while ebx
		mov ecx, 16
		xor eax, eax
		.while ecx
			dec ecx
			mov al, [esi][ecx]
			push eax
		.endw
		mov eax, dwCurr
		sub eax, lpszBuffer
		push eax
		push offset szFmt
		push edi
		call wsprintf
		add esp, 04Ch
		add edi, eax
		xor ecx, ecx
		.while ecx < 16
			mov al, [esi][ecx]
			.if al < ' '
				mov al, '.'
			.endif
			stosb
			inc ecx
		.endw
		mov al, 0Dh
		stosb
		mov al, 0Ah
		stosb
		add esi, 16
		add dwCurr, 16
		dec ebx
	.endw
	invoke SendMessage, hEditWnd, WM_SETTEXT, 0, pTextBuffer
	invoke VirtualFree, pTextBuffer, 0, MEM_RELEASE
	popad
	ret
PrintHexDump EndP

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                      ControlDevice                                                
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

ControlDriver proc uses esi edi ebx pszDriverName:LPSTR, dwCode:DWORD

LOCAL acBuffer[MAX_PATH]:CHAR
LOCAL dwBytesReturned:DWORD
LOCAL dwOutBytes: DWORD
LOCAL dwInBytes: DWORD

	xor ebx, ebx		; assume error
	mov edi, offset g_szFail

	invoke GetVersion
	.if al >= 5
		mov eax, $CTA0("\\\\.\\Global\\%s")
	.else
		mov eax, $CTA0("\\\\.\\%s")
	.endif
	invoke wsprintf, addr acBuffer, eax, pszDriverName

	invoke CreateFile, addr acBuffer, GENERIC_READ + GENERIC_WRITE, 0, \
				NULL, OPEN_EXISTING, 0, NULL

	invoke LastError

	.if eax != INVALID_HANDLE_VALUE
		mov esi, eax
		push esi
		xor eax, eax
		mov g_OutputBuffer, eax
		mov dwOutBytes, eax
		mov dwInBytes, eax
		.if g_bOutputBuffer
			mov eax, g_OutputBufferSize
			imul eax, 1000h
			mov dwOutBytes, eax
			invoke VirtualAlloc, NULL, dwOutBytes, MEM_COMMIT + MEM_RESERVE, PAGE_READWRITE
			mov g_OutputBuffer, eax
		.endif
		.if g_bInputBuffer == TRUE
			mov eax, g_InputBufferSize
			imul eax, 1000h
			mov dwInBytes, eax
		.elseif g_bInputBuffer == FALSE
			xor eax, eax
			mov g_InputBuffer, eax
		.endif
		pop esi
		invoke DeviceIoControl, esi, dwCode, g_InputBuffer, dwInBytes, g_OutputBuffer, dwOutBytes, addr dwBytesReturned, NULL
		push dwBytesReturned
		pop g_LastBytesRet
		invoke LastError
		.if eax != 0
			inc ebx					; success
			mov edi, offset g_szSuccess
		.endif
		invoke CloseHandle, esi
		invoke ReportStatus, pszDriverName, $CTA0("Control"), edi, offset g_acErrorDescription
		
		mov eax, g_bOutputBuffer
		.if g_bOutputBuffer
			.if g_bShowBuffer 
				invoke DialogBoxParam, g_hInstance, IDD_DUMP, g_hwndMain, addr DlgDumpProc, 0
			.endif
			invoke VirtualFree, g_OutputBuffer, 0, MEM_RELEASE
		.endif
	.else
		invoke MessageBox, NULL, $CTA0("Can't get Driver handle."), addr g_szCriticalError, MB_OK + MB_ICONSTOP
	.endif

	return ebx

ControlDriver endp

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                  GetDriverNameFromPath                                            
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

GetDriverNameFromPath proc uses esi edi ebx pDriverPath:LPSTR, pBuffer:LPVOID

	xor ebx, ebx	; assume error

	mov edi, pDriverPath
	mov esi, edi
	invoke lstrlen, edi
	add esi, eax
	sub esi, 4			; ".sys"
	invoke lstrcmpi, $CTA0(".sys"), esi
	.if eax == 0
		xor ecx, ecx
		dec esi

	    .while esi > edi
		    mov al, [esi]
	    	.break .if al == '\'
		    inc ecx
		    dec esi
		.endw

		.if esi != edi
			inc esi
			mov edi, pBuffer
			rep movsb
		    mov byte ptr [edi], 0
		    inc ebx				; success
		.else
			invoke MessageBox, NULL, $CTA0("Can't extract Driver Name.\nYou have to specify full path."), \
									NULL, MB_OK + MB_ICONSTOP
		.endif

	.else
		invoke MessageBox, NULL, $CTA0("Can't recognize Driver Name.\nThe file extension must be '.sys'."), \
									NULL, MB_OK + MB_ICONSTOP
	.endif

	return ebx

GetDriverNameFromPath endp

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                  InsertReportListColumns                                          
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

InsertReportListColumns proc hwndListView:HWND
	
LOCAL lvc:LV_COLUMN
LOCAL lvi:LV_ITEM
	
	ListView_SetExtendedListViewStyle hwndListView, LVS_EX_GRIDLINES + LVS_EX_FULLROWSELECT

	mov lvc.imask, LVCF_TEXT + LVCF_WIDTH + LVCF_FMT
	mov lvc.fmt, LVCFMT_LEFT
	mov lvc.pszText, $TA0("Driver")
	mov lvc.lx, 60
	ListView_InsertColumn hwndListView, 0, addr lvc

	mov lvc.lx, 65
	mov lvc.pszText, $TA0("Operation")
	ListView_InsertColumn hwndListView, 1, addr lvc

	mov lvc.lx, 60
	mov lvc.pszText, $TA0("Status")
	ListView_InsertColumn hwndListView, 2, addr lvc

	mov lvc.lx, 400
	mov lvc.pszText, $TA0("Last Error")
	ListView_InsertColumn hwndListView, 3, addr lvc

	ret

InsertReportListColumns endp

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                      MakeFilePathOnly                                             
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

MakeFilePathOnly proc lpPathName:LPVOID

	invoke fstrlen, lpPathName

    mov ecx, lpPathName
    lea ecx, [ecx][eax-6]

@@:
    mov al, [ecx]
    dec ecx
    cmp al, '\'
    jne @B

    mov byte ptr [ecx+2], 0

    ret

MakeFilePathOnly endp

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                                                                                   
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

ListViewProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	mov eax, uMsg
	.if eax == WM_CONTEXTMENU

		; Don't pop up menu if list is empty
		ListView_GetItemCount g_hwndReportListView
		.if eax != 0
			mov eax, lParam
			mov ecx, eax
			and eax, 0FFFFh
			shr ecx, 16
			invoke TrackPopupMenu, g_hListViewPopupMenu, TPM_LEFTALIGN, eax, ecx, NULL, hWnd, NULL
		.endif

	.elseif eax == WM_COMMAND

		mov eax, $LOWORD(wParam)
		.if eax == IDM_CLEAR_LOG	
			ListView_DeleteAllItems g_hwndReportListView
		.endif

	.endif

	invoke CallWindowProc, g_pfnListViewProcPrev, hWnd, uMsg, wParam, lParam

	ret

ListViewProc endp

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                       Dlg_OnInitDialog                                            
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Dlg_OnInitDialog proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

local rect:RECT

	; Set Dialog Icon
	invoke LoadIcon, g_hInstance, IDI_ICON
	invoke SendMessage, hDlg, WM_SETICON, ICON_BIG, eax

	push hDlg
	pop g_hwndMain
	mov g_bShowBuffer, TRUE
	mov g_InputBufferSize, 1
	mov g_OutputBufferSize, 1
	mov g_hwndEditDriverPath, $invoke(GetDlgItem, hDlg, IDE_PATH)
	invoke SetWindowText, eax, g_lpstrCmdLine
	mov g_hwndEditControlCode, $invoke(GetDlgItem, hDlg, IDE_CONTROL_CODE)
	; Thnx to James Brown for idea
	invoke MaskEditControl, g_hwndEditControlCode, $CTA0("0123456789abcdefABCDEF"), TRUE
	invoke SendMessage, g_hwndEditControlCode, EM_LIMITTEXT, 8, 0

	mov g_hwndButtonRegister,	$invoke(GetDlgItem, hDlg, IDB_REGISTER)
	mov g_hwndButtonRun,		$invoke(GetDlgItem, hDlg, IDB_RUN)
	mov g_hwndButtonControl,	$invoke(GetDlgItem, hDlg, IDB_IOCONTROL)
	mov g_hwndButtonStop,		$invoke(GetDlgItem, hDlg, IDB_STOP)
	mov g_hwndButtonUnregister, $invoke(GetDlgItem, hDlg, IDB_UNREGISTER)

	mov g_hwndCheckRegToRun,	$invoke(GetDlgItem, hDlg, IDCHK_REGTORUNLINK)
	mov g_hwndCheckUnregToStop, $invoke(GetDlgItem, hDlg, IDCHK_UNREGTOSTOPLINK)
	mov g_hwndCheckLinkAll,		$invoke(GetDlgItem, hDlg, IDCHK_IOCONTROLLINK)

	mov g_hwndReportListView, $invoke(GetDlgItem, hDlg, IDC_REPORT_LIST)
	invoke InsertReportListColumns, g_hwndReportListView

	mov g_pfnListViewProcPrev, $invoke(SetWindowLong, g_hwndReportListView, GWL_WNDPROC, offset ListViewProc)	
	; Create popup menu
	invoke CreatePopupMenu
	mov g_hListViewPopupMenu,eax
	invoke AppendMenu, g_hListViewPopupMenu, MF_STRING, IDM_CLEAR_LOG, $CTA0("Clear log")

	; for tracking size

	invoke GetWindowRect, hDlg, addr rect

	lea edx, rect
	mov eax, (RECT PTR [edx]).right
	sub eax, (RECT PTR [edx]).left

	mov g_dwDlgWidth, eax

	mov eax, (RECT PTR [edx]).bottom
	sub eax, (RECT PTR [edx]).top

	mov g_dwDlgMinHeight, eax
	add eax, 195
	mov g_dwDlgMaxHeight, eax
	
	; If we XP themed, remove WS_EX_STATICEDGE. Looks better.

	invoke AdjustGuiIfThemed, hDlg
		
	ret

Dlg_OnInitDialog endp

Options_OnInitDialog proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	LOCAL sBuf[10]: CHAR
	
	;invoke LoadIcon, g_hInstance, IDI_ICONOPTIONS
	;invoke SendMessage, hDlg, WM_SETICON, ICON_SMALL, eax
	invoke MaskEditControl, $invoke(GetDlgItem, hDlg, IDE_INPUTBUFFER), $CTA0("0123456789abcdefABCDEF"), TRUE
	invoke SendMessage, $invoke(GetDlgItem, hDlg, IDE_INPUTBUFFER), EM_LIMITTEXT, 8, 0
	invoke MaskEditControl, $invoke(GetDlgItem, hDlg, IDE_OUTPUTBUFFER), $CTA0("0123456789abcdefABCDEF"), TRUE
	invoke SendMessage, $invoke(GetDlgItem, hDlg, IDE_OUTPUTBUFFER), EM_LIMITTEXT, 8, 0
	.if g_bInputBuffer == TRUE
		invoke SendDlgItemMessage, hDlg, IDCHK_INPUTBUFFER, BM_SETCHECK, TRUE, 0
		invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDL_INPUTBUFFER), TRUE
		invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDE_INPUTBUFFER), TRUE
		invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDB_EDITBUFFER), TRUE
	.endif
	.if g_bOutputBuffer == TRUE
		invoke SendDlgItemMessage, hDlg, IDCHK_OUTPUTBUFFER, BM_SETCHECK, TRUE, 0
		invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDL_OUTPUTBUFFER), TRUE
		invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDE_OUTPUTBUFFER), TRUE
		invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDCHK_SHOWBUFFER), TRUE
	.endif
	.if g_bShowBuffer == TRUE
		invoke SendDlgItemMessage, hDlg, IDCHK_SHOWBUFFER, BM_SETCHECK, TRUE, 0
	.endif
	invoke dw2hex, g_OutputBufferSize, addr sBuf
	invoke SendDlgItemMessage, hDlg, IDE_OUTPUTBUFFER, WM_SETTEXT, 0, addr sBuf
	invoke dw2hex, g_InputBufferSize, addr sBuf
	invoke SendDlgItemMessage, hDlg, IDE_INPUTBUFFER, WM_SETTEXT, 0, addr sBuf
	invoke AdjustGuiIfThemed, hDlg
	invoke SetFocus, $invoke(GetDlgItem, hDlg, IDB_OPTAPPLY)
	ret
Options_OnInitDialog EndP

Dump_OnInitDialog proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local lf:LOGFONT
	local sCaption[46]: CHAR
	
	invoke GetDlgItem, hDlg, IDE_DUMP
	mov g_hwndEditDump, eax
	mov	g_hFontOld, $invoke(SendMessage, g_hwndEditDump, WM_GETFONT, 0, 0)
	invoke GetObject, g_hFontOld, sizeof LOGFONT, addr lf
	lea ecx, lf.lfFaceName
	invoke lstrcpy, ecx, $CTA0("Courier New")
	invoke CreateFontIndirect, addr lf		
	mov	g_hFontNew, eax
	invoke SendMessage, g_hwndEditDump, WM_SETFONT, g_hFontNew, FALSE
	invoke wsprintf, addr sCaption, $CTA0("Output buffer dump :: %08X bytes returned"), g_LastBytesRet
	;add esp, 4
	invoke SendMessage, hDlg, WM_SETTEXT, 0, addr sCaption
	
	invoke PrintHexDump, g_hwndEditDump, g_OutputBuffer, g_OutputBufferSize
	ret
Dump_OnInitDialog EndP

Edit_OnInitDialog proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local lf: LOGFONT
	local hwndEditOffset: HWND
	local hwndEditValue: HWND
	local hwndEditDump: HWND
	
	invoke GetDlgItem, hDlg, IDE_EDITDUMP
	mov hwndEditDump, eax
	mov	g_hFontOld, $invoke(SendMessage, hwndEditDump, WM_GETFONT, 0, 0)
	invoke GetObject, g_hFontOld, sizeof LOGFONT, addr lf
	lea ecx, lf.lfFaceName
	invoke lstrcpy, ecx, $CTA0("Courier New")
	invoke CreateFontIndirect, addr lf		
	mov	g_hFontNew, eax
	invoke SendMessage, hwndEditDump, WM_SETFONT, g_hFontNew, FALSE
	
	invoke AdjustGuiIfThemed, hDlg
	invoke CheckDlgButton, hDlg, IDR_BYTE, BST_CHECKED
	invoke GetDlgItem, hDlg, IDE_EDITOFFSET
	mov hwndEditOffset, eax
	invoke MaskEditControl, eax, $CTA0("0123456789abcdefABCDEF"), TRUE
	invoke SendMessage, hwndEditOffset, EM_LIMITTEXT, 8, 0
	invoke SendMessage, hwndEditOffset, WM_SETTEXT, 0, $CTA0("0")
	invoke GetDlgItem, hDlg, IDE_EDITVALUE
	mov hwndEditValue, eax
	invoke MaskEditControl, eax, $CTA0("0123456789abcdefABCDEF"), TRUE
	invoke SendMessage, hwndEditValue, EM_LIMITTEXT, 2, 0
	invoke SendMessage, hwndEditValue, WM_SETTEXT, 0, $CTA0("00")
	mov g_CurValueMode, IDR_BYTE
	invoke SendDlgItemMessage, hDlg, IDE_EDITSTRING, EM_LIMITTEXT, 256, 0
	invoke PrintHexDump, hwndEditDump, g_InputBuffer, g_InputBufferSize
	ret
Edit_OnInitDialog EndP

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                    Dlg_OnCommand                                                  
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Dlg_OnCommand proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

LOCAL ofn:OPENFILENAME
LOCAL acBufferPath[MAX_PATH]:CHAR
LOCAL acBufferName[MAX_PATH]:CHAR
LOCAL acIoCode[16]:CHAR
LOCAL dwIoCode:DWORD

	mov eax, $LOWORD(wParam)
	.if eax == IDCANCEL
		; ask only if user hit Esc key
		invoke MessageBox, hDlg, $CTA0("Sure want to exit?"), \
							$CTA0("Exit Confirmation"), MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON1
		.if eax == IDYES
			invoke EndDialog, hDlg, 0
			invoke TerminateProcess, -1, 0
		.endif

	.elseif eax == IDB_EXIT
		invoke EndDialog, hDlg, 0
		invoke TerminateProcess, -1, 0

	.elseif eax == IDB_BROWSE

		; Get driver's path to load
		invoke RtlZeroMemory, addr ofn, sizeof ofn
		mov ofn.lStructSize, sizeof ofn
		m2m ofn.hwndOwner, hDlg
		m2m ofn.hInstance, g_hInstance
 		mov ofn.lpstrFilter, offset g_szFilterString
		invoke RtlZeroMemory, addr acBufferPath, sizeof acBufferPath
 		lea eax, acBufferPath
		mov ofn.lpstrFile, eax
		mov ofn.nMaxFile, sizeof acBufferPath

		invoke GetCurrentDirectory, sizeof acBufferName, addr acBufferName
		lea eax, acBufferName
		mov ofn.lpstrInitialDir, eax
		mov ofn.lpstrTitle, offset g_szOpenDriverTitle
		mov ofn.Flags, OFN_FILEMUSTEXIST + OFN_PATHMUSTEXIST + OFN_LONGNAMES + OFN_EXPLORER
		invoke GetOpenFileName, addr ofn
		.if eax != 0
			; Show it in edit control
			invoke SetWindowText, g_hwndEditDriverPath, ofn.lpstrFile
		.endif

	.elseif eax == IDB_REGISTER

		invoke RtlZeroMemory, addr acBufferPath, sizeof acBufferPath
		invoke GetWindowText, g_hwndEditDriverPath, addr acBufferPath, sizeof acBufferPath
		
		.if eax != 0
			invoke GetDriverNameFromPath, addr acBufferPath, addr acBufferName
			.if eax == TRUE
				invoke RegisterDriver, addr acBufferName, addr acBufferPath

				invoke SendMessage, g_hwndCheckRegToRun, BM_GETCHECK, 0, 0
				.if eax == BST_CHECKED
				;invoke IsWindowEnabled, g_hwndButtonRun
				;.if eax == 0
					; linked
					invoke RunDriver, addr acBufferName				
				.endif
			.endif
		.else
			invoke MessageBox, hDlg, addr g_szEnterFullDriverPath, NULL, MB_OK + MB_ICONSTOP
		.endif

	.elseif eax == IDB_UNREGISTER

		invoke RtlZeroMemory, addr acBufferPath, sizeof acBufferPath
		invoke GetWindowText, g_hwndEditDriverPath, addr acBufferPath, sizeof acBufferPath
		
		.if eax != 0
			invoke GetDriverNameFromPath, addr acBufferPath, addr acBufferName
			.if eax == TRUE
				invoke SendMessage, g_hwndCheckUnregToStop, BM_GETCHECK, 0, 0
				.if eax == BST_CHECKED
				;invoke IsWindowEnabled, g_hwndButtonStop
				;.if eax == 0
					; linked
					invoke StopDriver, addr acBufferName				
				.endif
				invoke UnregisterDriver, addr acBufferName
			.endif
		.else
			invoke MessageBox, hDlg, addr g_szEnterFullDriverPath, NULL, MB_OK + MB_ICONSTOP
		.endif

	.elseif eax == IDB_RUN

		invoke RtlZeroMemory, addr acBufferPath, sizeof acBufferPath
		invoke GetWindowText, g_hwndEditDriverPath, addr acBufferPath, sizeof acBufferPath
		
		.if eax != 0
			invoke GetDriverNameFromPath, addr acBufferPath, addr acBufferName
			.if eax == TRUE
				invoke RunDriver, addr acBufferName
			.endif
		.else
			invoke MessageBox, hDlg, addr g_szEnterFullDriverPath, NULL, MB_OK + MB_ICONSTOP
		.endif

	.elseif eax == IDB_STOP

		invoke RtlZeroMemory, addr acBufferPath, sizeof acBufferPath
		invoke GetWindowText, g_hwndEditDriverPath, addr acBufferPath, sizeof acBufferPath
		
		.if eax != 0
			invoke GetDriverNameFromPath, addr acBufferPath, addr acBufferName
			.if eax == TRUE
				invoke StopDriver, addr acBufferName
			.endif
		.else
			invoke MessageBox, hDlg, addr g_szEnterFullDriverPath, NULL, MB_OK + MB_ICONSTOP
		.endif

	.elseif eax == IDB_IOCONTROL

		invoke RtlZeroMemory, addr acBufferPath, sizeof acBufferPath
		invoke GetWindowText, g_hwndEditDriverPath, addr acBufferPath, sizeof acBufferPath
		
		.if eax != 0
			invoke GetDriverNameFromPath, addr acBufferPath, addr acBufferName
			.if eax == TRUE
				invoke GetWindowText, g_hwndEditControlCode, addr acIoCode, sizeof acIoCode
				.if eax != 0
					invoke htodw, addr acIoCode
					mov dwIoCode, eax

					invoke SendMessage, g_hwndCheckLinkAll, BM_GETCHECK, 0, 0
					.if eax == BST_CHECKED
						; linked
						.while TRUE
							; he-he
							invoke RegisterDriver, addr acBufferName, addr acBufferPath
							.break .if eax == FALSE
							invoke RunDriver, addr acBufferName
							.break .if eax == FALSE
							invoke ControlDriver, addr acBufferName, dwIoCode
							.break .if eax == FALSE
							invoke StopDriver, addr acBufferName
							.break .if eax == FALSE
							invoke UnregisterDriver, addr acBufferName
							.break
						.endw
					.else
						invoke ControlDriver, addr acBufferName, dwIoCode
					.endif

				.else
					invoke MessageBox, hDlg, $CTA0("Enter control code first."), NULL, MB_OK + MB_ICONSTOP				
				.endif
			.endif
		.else
			invoke MessageBox, hDlg, addr g_szEnterFullDriverPath, NULL, MB_OK + MB_ICONSTOP
		.endif

	.elseif eax == IDB_ABOUT
		invoke MessageBox, hDlg, $CTA0("Kernel-Mode Driver Manager\n\tv 1.4\n\nWritten by\n\tFour-F  &  Twister\n\nfour-f@mail.ru\ntwister.kz@mail.ru"), \
								$CTA0("About"), MB_OK + MB_ICONINFORMATION
	
	.elseif eax == IDB_OPTIONS
		invoke DialogBoxParam, g_hInstance, IDD_OPTIONS, hDlg, addr DlgOptionsProc, NULL

	.elseif eax == IDCHK_REGTORUNLINK
		invoke SendDlgItemMessage, hDlg, IDCHK_REGTORUNLINK, BM_GETCHECK, 0, 0
		.if eax == BST_CHECKED
			invoke EnableWindow, g_hwndButtonRun, FALSE
			invoke SetWindowText, g_hwndButtonRegister, $CTA0("&Reg'n'Run")
		.else
			invoke EnableWindow, g_hwndButtonRun, TRUE
			invoke SetWindowText, g_hwndButtonRegister, $CTA0("Re&gister")
		.endif	

	.elseif eax == IDCHK_UNREGTOSTOPLINK
		invoke SendDlgItemMessage, hDlg, IDCHK_UNREGTOSTOPLINK, BM_GETCHECK, 0, 0
		.if eax == BST_CHECKED
			invoke EnableWindow, g_hwndButtonStop, FALSE
			invoke SetWindowText, g_hwndButtonUnregister, $CTA0("&Stop'n'Unreg")
		.else
			invoke EnableWindow, g_hwndButtonStop, TRUE
			invoke SetWindowText, g_hwndButtonUnregister, $CTA0("&Unregister")
		.endif	

	.elseif eax == IDCHK_IOCONTROLLINK
		invoke SendDlgItemMessage, hDlg, IDCHK_IOCONTROLLINK, BM_GETCHECK, 0, 0
		.if eax == BST_CHECKED
			invoke EnableWindow, g_hwndButtonRegister, FALSE
			invoke EnableWindow, g_hwndCheckRegToRun, FALSE
			invoke EnableWindow, g_hwndButtonRun, FALSE
			invoke EnableWindow, g_hwndButtonStop, FALSE
			invoke EnableWindow, g_hwndCheckUnregToStop, FALSE
			invoke EnableWindow, g_hwndButtonUnregister, FALSE
			invoke SetWindowText, g_hwndButtonControl, $CTA0("All A&ctions")

		.else
			invoke EnableWindow, g_hwndButtonRegister, TRUE
			invoke EnableWindow, g_hwndCheckRegToRun, TRUE

			invoke SendMessage, g_hwndCheckRegToRun, BM_GETCHECK, 0, 0
			.if eax == BST_UNCHECKED
				invoke EnableWindow, g_hwndButtonRun, TRUE
			.endif	

			invoke SendMessage, g_hwndCheckUnregToStop, BM_GETCHECK, 0, 0
			.if eax == BST_UNCHECKED
				invoke EnableWindow, g_hwndButtonStop, TRUE
			.endif

			invoke EnableWindow, g_hwndCheckUnregToStop, TRUE
			invoke EnableWindow, g_hwndButtonUnregister, TRUE

			invoke SetWindowText, g_hwndButtonControl, $CTA0("I/O &Control")
		.endif

	.endif

	ret

Dlg_OnCommand endp

Options_OnCommand proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local sBuf[10]: CHAR
	local dwSize: DWORD
	
	mov eax, $LOWORD(wParam)
	.if eax == IDCANCEL
		invoke EndDialog, hDlg, 0
	.elseif eax == IDB_EDITBUFFER
		mov g_bInputBuffer, TRUE
		invoke SendDlgItemMessage, hDlg, IDE_INPUTBUFFER, WM_GETTEXT, 10, addr sBuf
		invoke htodw, addr sBuf
		.if eax != g_InputBufferSize
			mov g_bNotClearBuffer, FALSE
			mov g_InputBufferSize, eax
		.endif
		.if g_bNotClearBuffer == FALSE
			mov g_bNotClearBuffer, TRUE
			mov eax, g_InputBufferSize 
			imul eax, 1000h
			mov dwSize, eax
			invoke VirtualAlloc, NULL, eax, MEM_COMMIT + MEM_RESERVE, PAGE_READWRITE
			mov g_InputBuffer, eax
			invoke RtlZeroMemory, eax, dwSize
			mov g_bNotClearBuffer, TRUE
		.endif
		invoke DialogBoxParam, g_hInstance, IDD_EDIT, hDlg, addr DlgEditProc, 0
	.elseif eax == IDCHK_INPUTBUFFER
		invoke SendDlgItemMessage, hDlg, IDCHK_INPUTBUFFER, BM_GETCHECK, 0, 0
		.if eax == BST_CHECKED
			invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDL_INPUTBUFFER), TRUE
			invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDE_INPUTBUFFER), TRUE
			invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDB_EDITBUFFER), TRUE
			invoke SetFocus, $invoke(GetDlgItem, hDlg, IDE_INPUTBUFFER)
		.else
			invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDL_INPUTBUFFER), FALSE
			invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDE_INPUTBUFFER), FALSE
			invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDB_EDITBUFFER), FALSE
		.endif
	.elseif eax == IDCHK_OUTPUTBUFFER
		invoke SendDlgItemMessage, hDlg, IDCHK_OUTPUTBUFFER, BM_GETCHECK, 0, 0
		.if eax == BST_CHECKED
			invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDL_OUTPUTBUFFER), TRUE
			invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDE_OUTPUTBUFFER), TRUE
			invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDCHK_SHOWBUFFER), TRUE
			invoke SetFocus, $invoke(GetDlgItem, hDlg, IDE_OUTPUTBUFFER)
		.else
			invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDL_OUTPUTBUFFER), FALSE
			invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDE_OUTPUTBUFFER), FALSE
			invoke EnableWindow, $invoke(GetDlgItem, hDlg, IDCHK_SHOWBUFFER), FALSE
		.endif
	.elseif eax == IDB_OPTCLOSE
		invoke EndDialog, hDlg, 0
	.elseif eax == IDB_OPTAPPLY
		invoke SendDlgItemMessage, hDlg, IDE_OUTPUTBUFFER, WM_GETTEXT, 10, addr sBuf
		invoke htodw, addr sBuf
		.if eax != g_InputBufferSize
			mov g_bNotClearBuffer, FALSE
			mov g_InputBufferSize, eax
		.endif
		mov g_bInputBuffer, FALSE
		invoke SendDlgItemMessage, hDlg, IDCHK_INPUTBUFFER, BM_GETCHECK, 0, 0
		.if eax == BST_CHECKED
			mov g_bInputBuffer, TRUE
			.if g_bNotClearBuffer == FALSE
				mov eax, g_InputBufferSize
				imul eax, 1000h
				mov dwSize, eax
				invoke VirtualAlloc, NULL, eax, MEM_COMMIT + MEM_RESERVE, PAGE_READWRITE
				mov g_InputBuffer, eax
				invoke RtlZeroMemory, eax, dwSize
				mov g_bNotClearBuffer, TRUE
			.endif
		.else
			.if g_bInputBuffer == TRUE
				invoke VirtualFree, g_InputBuffer, 0, MEM_RELEASE
				mov g_bNotClearBuffer, FALSE
			.endif
		.endif
		mov g_bOutputBuffer, FALSE
		invoke SendDlgItemMessage, hDlg, IDCHK_OUTPUTBUFFER, BM_GETCHECK, 0, 0
		.if eax == BST_CHECKED
			mov g_bOutputBuffer, TRUE
		.endif
		mov g_bShowBuffer, FALSE
		invoke SendDlgItemMessage, hDlg, IDCHK_SHOWBUFFER, BM_GETCHECK, 0, 0
		.if eax == BST_CHECKED
			mov g_bShowBuffer, TRUE
		.endif
		invoke EndDialog, hDlg, 0
	.endif
	ret
Options_OnCommand EndP

Edit_OnCommand proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local sBuf[10]: CHAR
	local sString[256]: CHAR
	local dwOffset: DWORD
	local dwLen: DWORD
	local hwndEdit: HWND
	
	mov eax, $LOWORD(wParam)
	.if eax == IDCANCEL
		invoke EndDialog, hDlg, 0
	.elseif eax == IDR_BYTE
		invoke IsDlgButtonChecked, hDlg, IDR_BYTE
		.if eax == BST_CHECKED
			invoke SendDlgItemMessage, hDlg, IDL_VALUE, WM_SETTEXT, 0, $CTA0("Value (hex, byte):")
			invoke SendDlgItemMessage, hDlg, IDE_EDITVALUE, EM_LIMITTEXT, 2, 0
			invoke SendDlgItemMessage, hDlg, IDE_EDITVALUE, WM_SETTEXT, 0, $CTA0("00")
			mov g_CurValueMode, IDR_BYTE
		.endif
	.elseif eax == IDR_WORD
		invoke IsDlgButtonChecked, hDlg, IDR_WORD
		.if eax == BST_CHECKED
			invoke SendDlgItemMessage, hDlg, IDL_VALUE, WM_SETTEXT, 0, $CTA0("Value (hex, word):")
			invoke SendDlgItemMessage, hDlg, IDE_EDITVALUE, EM_LIMITTEXT, 4, 0
			invoke SendDlgItemMessage, hDlg, IDE_EDITVALUE, WM_SETTEXT, 0, $CTA0("0000")
			mov g_CurValueMode, IDR_WORD
		.endif
	.elseif eax == IDR_DWORD
		invoke IsDlgButtonChecked, hDlg, IDR_DWORD
		.if eax == BST_CHECKED
			invoke SendDlgItemMessage, hDlg, IDL_VALUE, WM_SETTEXT, 0, $CTA0("Value (hex, dword):")
			invoke SendDlgItemMessage, hDlg, IDE_EDITVALUE, EM_LIMITTEXT, 8, 0
			invoke SendDlgItemMessage, hDlg, IDE_EDITVALUE, WM_SETTEXT, 0, $CTA0("00000000")
			mov g_CurValueMode, IDR_DWORD
		.endif
	.elseif eax == IDB_PUTVALUE
		invoke SendDlgItemMessage, hDlg, IDE_EDITOFFSET, WM_GETTEXT, 10, addr sBuf
		invoke htodw, addr sBuf
		mov dwOffset, eax
		invoke SendDlgItemMessage, hDlg, IDE_EDITVALUE, WM_GETTEXT, 10, addr sBuf
		invoke htodw, addr sBuf
		mov ebx, g_InputBuffer
		add ebx, dwOffset
		mov ecx, g_InputBufferSize
		imul ecx, 1000h
		add ecx, g_InputBuffer
		.if g_CurValueMode == IDR_BYTE
			sub ecx, 1
			cmp ebx, ecx
			jg _err
			mov byte ptr[ebx], al
			inc dwOffset
		.elseif g_CurValueMode == IDR_WORD
			sub ecx, 2
			cmp ebx, ecx
			jg _err
			mov word ptr[ebx], ax
			inc dwOffset
			inc dwOffset
		.elseif g_CurValueMode == IDR_DWORD
			sub ecx, 4
			cmp ebx, ecx
			jg _err
			mov dword ptr[ebx], eax
			add dwOffset, 4
		.endif
		invoke GetDlgItem, hDlg, IDE_EDITDUMP
		mov hwndEdit, eax
		invoke SendMessage, eax, EM_GETFIRSTVISIBLELINE, 0, 0
		invoke PrintHexDump, hwndEdit, g_InputBuffer, g_InputBufferSize
		xor ebx, ebx
		mov bx, ax
		invoke SendMessage, hwndEdit, EM_LINESCROLL, 0, ebx
		invoke dw2hex, dwOffset, addr sBuf
		invoke SendDlgItemMessage, hDlg, IDE_EDITOFFSET, WM_SETTEXT, 0, addr sBuf
	.elseif eax == IDB_PUTSTRING
		invoke SendDlgItemMessage, hDlg, IDE_EDITSTRING, WM_GETTEXTLENGTH, 0, 0
		.if eax > 0
			inc eax
			mov dwLen, eax
			invoke SendDlgItemMessage, hDlg, IDE_EDITSTRING, WM_GETTEXT, dwLen, addr sString
			invoke SendDlgItemMessage, hDlg, IDE_EDITOFFSET, WM_GETTEXT, 10, addr sBuf
			invoke htodw, addr sBuf
			mov dwOffset, eax
			mov ecx, g_InputBufferSize
			imul ecx, 1000h
			sub ecx, dwLen
			inc ecx
			cmp eax, ecx
			jg _err
			add eax, g_InputBuffer
			xchg eax, ebx
			invoke lstrcpyn, ebx, addr sString, dwLen
			invoke GetDlgItem, hDlg, IDE_EDITDUMP
			mov hwndEdit, eax
			invoke SendMessage, eax, EM_GETFIRSTVISIBLELINE, 0, 0
			invoke PrintHexDump, hwndEdit, g_InputBuffer, g_InputBufferSize
			xor ebx, ebx
			mov bx, ax
			invoke SendMessage, hwndEdit, EM_LINESCROLL, 0, ebx
			mov ebx, dwOffset
			add ebx, dwLen
			dec ebx
			invoke dw2hex, ebx, addr sBuf
			invoke SendDlgItemMessage, hDlg, IDE_EDITOFFSET, WM_SETTEXT, 0, addr sBuf
		.endif
	.elseif eax == IDB_CLAERBUFFER
		invoke MessageBox, hDlg, $CTA0("Do you realy want to clear buffer?"), $CTA0("Confirmation"),MB_DEFBUTTON2+MB_ICONQUESTION+MB_YESNO
		.if eax == IDYES
			mov eax, g_InputBufferSize
			imul eax, 1000h
			invoke RtlZeroMemory, g_InputBuffer, eax
			invoke GetDlgItem, hDlg, IDE_EDITDUMP
			invoke PrintHexDump, eax, g_InputBuffer, g_InputBufferSize
		.endif
	.endif
	ret
  _err:
  	invoke MessageBox, hDlg, $CTA0("Can't put data outside of the buffer"), $CTA0("Error"),MB_ICONERROR
  	ret
Edit_OnCommand EndP

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                       Dlg_OnSize                                                  
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Dlg_OnSize proc uses esi esi ebx hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

local rcDlg:RECT
local rcList:RECT
local sz:_SIZE
local pos:POINT

	invoke GetWindowRect, hDlg, addr rcDlg
	invoke GetWindowRect, g_hwndReportListView, addr rcList

	mov eax, rcList.bottom
	sub eax, rcList.top

	mov ecx, rcDlg.bottom
	sub ecx, rcList.bottom
	sub ecx, 6
	add eax, ecx
	mov sz.y, eax

	mov eax, rcList.right
	sub eax, rcList.left
	mov sz.x, eax

	mrm pos.x, rcList.left
	mrm pos.y, rcList.top

	invoke ScreenToClient, hDlg, addr pos

	invoke MoveWindow, g_hwndReportListView, pos.x, pos.y, sz.x, sz.y, TRUE

	ret

Dlg_OnSize endp

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                  Dlg_OnGetMinMaxInfo                                              
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Dlg_OnGetMinMaxInfo proc uses esi esi ebx hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	mov ecx, lParam
	assume ecx:ptr MINMAXINFO
	mov eax, g_dwDlgWidth
	mov [ecx].ptMinTrackSize.x, eax
	mov [ecx].ptMaxTrackSize.x, eax

	mrm [ecx].ptMinTrackSize.y, g_dwDlgMinHeight
	mrm [ecx].ptMaxTrackSize.y, g_dwDlgMaxHeight
	assume ecx:nothing

	ret

Dlg_OnGetMinMaxInfo endp

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                    Dlg_OnDropFiles                                                
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Dlg_OnDropFiles proc uses esi esi ebx hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

local acDroppedFilePath[MAX_PATH]:CHAR
local acDriverName[MAX_MODULE_NAME32]:CHAR

	invoke DragQueryFile, wParam, 0, addr acDroppedFilePath, sizeof acDroppedFilePath

	; Show it in edit control

	invoke SetWindowText, g_hwndEditDriverPath, addr acDroppedFilePath

	invoke MakeFilePathOnly, addr acDroppedFilePath
	invoke SetCurrentDirectory, addr acDroppedFilePath

	ret

Dlg_OnDropFiles endp

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                 D I A L O G      P R O C E D U R E                                
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

DlgProc proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	mov eax, uMsg

	.if eax == WM_COMMAND
		invoke Dlg_OnCommand, hDlg, uMsg, wParam, lParam

	.elseif eax == WM_INITDIALOG
		invoke Dlg_OnInitDialog, hDlg, uMsg, wParam, lParam

	.elseif eax == WM_GETMINMAXINFO
		invoke Dlg_OnGetMinMaxInfo, hDlg, uMsg, wParam, lParam

	.elseif eax == WM_SIZE
		invoke Dlg_OnSize, hDlg, uMsg, wParam, lParam

	.elseif eax == WM_DROPFILES
		invoke Dlg_OnDropFiles, hDlg, uMsg, wParam, lParam

	.elseif eax == WM_CLOSE
		invoke EndDialog, hDlg, 0
		invoke TerminateProcess, -1, 0

	.else
 
		return FALSE
      
	.endif
   
	return TRUE
    
DlgProc endp

DlgOptionsProc proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	LOCAL rct: RECT
	
	mov eax, uMsg
	.if eax == WM_CLOSE
		invoke EndDialog, hDlg, 0
	.elseif eax == WM_INITDIALOG
		invoke Options_OnInitDialog, hDlg, uMsg, wParam, lParam
	.elseif eax == WM_COMMAND
		invoke Options_OnCommand, hDlg, uMsg, wParam, lParam
	.else
		return FALSE
	.endif
	return TRUE
DlgOptionsProc EndP

DlgDumpProc proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	mov eax, uMsg
	.if eax == WM_CLOSE
		invoke EndDialog, hDlg, 0
	.elseif eax == WM_INITDIALOG
		invoke Dump_OnInitDialog, hDlg, uMsg, wParam, lParam
	.else
		return FALSE
	.endif
	return TRUE
	ret
DlgDumpProc EndP

DlgEditProc proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	mov eax, uMsg
	.if eax == WM_CLOSE
		invoke EndDialog, hDlg, 0
	.elseif eax == WM_INITDIALOG
		invoke Edit_OnInitDialog, hDlg, uMsg, wParam, lParam
	.elseif eax == WM_COMMAND
		invoke Edit_OnCommand, hDlg, uMsg, wParam, lParam
	.else
		return FALSE
	.endif
	return TRUE
	ret
DlgEditProc EndP

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                                                                                                   
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

start:

	mov g_hInstance, $invoke(GetModuleHandle, NULL)
	invoke GetCommandLine
	xchg eax, edi
	inc edi
	mov ecx, 260
	mov al, '"'
	repne scasb
	inc edi
	cmp byte ptr [edi], '"'
	jne _stop
	inc edi
	push edi
	repne scasb
	dec edi
	xor bl, bl
	mov byte ptr[edi], bl
	pop edi	
  _stop:
  	mov g_lpstrCmdLine, edi
	invoke DialogBoxParam, g_hInstance, IDD_DIALOG, NULL, addr DlgProc, 0
	invoke ExitProcess, eax

	ret

end start
