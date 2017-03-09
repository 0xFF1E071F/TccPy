
// Everything IPC test

// revision 2:
// fixed command line interpreting '-' as a switch inside text.

// revision 3:
// convert unicode to same code page as console.

// revision 4:
// removed write console because it has no support for piping.

// revision 5:
// added ChangeWindowMessageFilterEx (if available) for admin/user support.

// compiler options
#pragma warning(disable : 4311) // type cast void * to unsigned int
#pragma warning(disable : 4312) // type cast unsigned int to void *
#pragma warning(disable : 4244) // warning C4244: 'argument' : conversion from 'LONG_PTR' to 'LONG', possible loss of data
#pragma warning(disable : 4996) // deprecation

#include <windows.h>
#include <stdio.h>

#include "everything_ipc.h"

#define COPYDATA_IPCTEST_QUERYCOMPLETEW	0

#define MSGFLT_RESET		0
#define MSGFLT_ALLOW		1
#define MSGFLT_DISALLOW		2

















#define COPYDATA_IPCTEST_QUERYCOMPLETEW	0
#define COPYDATA_IPCTEST_QUERYCOMPLETEA	1

#define farrStatus printf

int gotData=0;
int timeout=0;
int isTutorial=0;
int scoringType=0;

int _EverythingSendQueryA(HWND hwnd, char *search_string, int flags)
{
	EVERYTHING_IPC_QUERY *query;
	int len, size;
	HWND everything_hwnd;
	COPYDATASTRUCT cds;

	everything_hwnd = FindWindow(EVERYTHING_IPC_WNDCLASS, 0);
	if (everything_hwnd)
	{
		len = (int)strlen(search_string);

		size = sizeof(EVERYTHING_IPC_QUERY) - sizeof(CHAR) + len*sizeof(CHAR) + sizeof(CHAR);

		query = (EVERYTHING_IPC_QUERY *)HeapAlloc(GetProcessHeap(),0,size);
		if (query)
		{
			query->max_results = 50;
			query->offset = 0;
			query->reply_copydata_message = COPYDATA_IPCTEST_QUERYCOMPLETEA;
			query->search_flags = flags;
			query->reply_hwnd = hwnd;
			CopyMemory(query->search_string,search_string,(len+1)*sizeof(CHAR));

			cds.cbData = size;
			cds.dwData = EVERYTHING_IPC_COPYDATAQUERY;
			cds.lpData = query;

			if (SendMessage(everything_hwnd,WM_COPYDATA,(WPARAM)hwnd,(LPARAM)&cds) == TRUE)
			{
				//debugmsg("Query sent.\n");
				HeapFree(GetProcessHeap(),0,query);
				return 1;
			}
			else
			{
				farrStatus("Everything IPC service not running!");
				isTutorial=1;
			}

			HeapFree(GetProcessHeap(),0,query);
		}
		else
		{
			farrStatus("Failed to allocate %d bytes for Everything IPC query.",size);
			return 0;
		}
	}
	else
	{
		farrStatus("Everything IPC service not found. Everything must be running.");
		isTutorial=1;
	}

	return 0;
}

int EverythingSendQuery(HWND windowHandle,char *searchString)
{
	int ret, flags=0;
	MSG msg;

	timeout=30;
	gotData=0;
	if(searchString[0]=='$'&&strlen(searchString)>1)
	{
		flags|=EVERYTHING_IPC_REGEX;
		searchString++;
	}
	if(_EverythingSendQueryA(windowHandle, searchString, flags)==1)
	{
		//WaitMessage();
		while(1)
		{
			timeout--;
			if(timeout<=0)
			{
				farrStatus("Timed out while waiting for blob from Everything!");
				break;
			}

			WaitMessage();
			while(PeekMessage(&msg, NULL, 0, 0, 0))
			{
				ret = (int)GetMessage(&msg, 0, 0, 0);
				if (ret <=0) break;
				TranslateMessage(&msg);
				DispatchMessage(&msg);
			}
			if(gotData) break;
		}
		return 1;
	}

	return 0;
}

















typedef struct tagCHANGEFILTERSTRUCT {
  DWORD cbSize;
  DWORD ExtStatus;
} CHANGEFILTERSTRUCT, *PCHANGEFILTERSTRUCT;

static void write(wchar_t *text);
static void write_DWORD(DWORD value);
static int wstring_to_int(const wchar_t *s);

int sort = 0;
EVERYTHING_IPC_LIST *sort_list;
HMODULE user32_hdll = 0;

BOOL (WINAPI *pChangeWindowMessageFilterEx)(HWND hWnd,UINT message,DWORD action,PCHANGEFILTERSTRUCT pChangeFilterStruct) = 0;

int wstring_length(const wchar_t *s)
{
	const wchar_t *p;

	p = s;
	while(*p)
	{
		p++;
	}

	return (int)(p - s);
}

// query everything with search string
int sendquery(HWND hwnd,DWORD num,WCHAR *search_string,int regex,int match_case,int match_whole_word,int match_path)
{
	EVERYTHING_IPC_QUERY *query;
	int len;
	int size;
	HWND everything_hwnd;
	COPYDATASTRUCT cds;

	everything_hwnd = FindWindow(EVERYTHING_IPC_WNDCLASS,0);
	if (everything_hwnd)
	{
		len = wstring_length(search_string);

		size = sizeof(EVERYTHING_IPC_QUERY) - sizeof(WCHAR) + len*sizeof(WCHAR) + sizeof(WCHAR);

		query = (EVERYTHING_IPC_QUERY *)HeapAlloc(GetProcessHeap(),0,size);
		if (query)
		{
			query->max_results = num;
			query->offset = 0;
			query->reply_copydata_message = COPYDATA_IPCTEST_QUERYCOMPLETEW;
			query->search_flags = (regex?EVERYTHING_IPC_REGEX:0) | (match_case?EVERYTHING_IPC_MATCHCASE:0) | (match_whole_word?EVERYTHING_IPC_MATCHWHOLEWORD:0) | (match_path?EVERYTHING_IPC_MATCHPATH:0);
			query->reply_hwnd = hwnd;
			CopyMemory(query->search_string,search_string,(len+1)*sizeof(WCHAR));

			cds.cbData = size;
			cds.dwData = EVERYTHING_IPC_COPYDATAQUERY;
			cds.lpData = query;

			if (SendMessage(everything_hwnd,WM_COPYDATA,(WPARAM)hwnd,(LPARAM)&cds) == TRUE)
			{
				HeapFree(GetProcessHeap(),0,query);

				return 1;
			}
			else
			{
				write(L"Everything IPC service not running.\n");
			}

			HeapFree(GetProcessHeap(),0,query);
		}
		else
		{
			write(L"failed to allocate ");
			write_DWORD(size);
			write(L" bytes for IPC query.\n");
		}
	}
	else
	{
		// the everything window was not found.
		// we can optionally RegisterWindowMessage("EVERYTHING_IPC_CREATED") and
		// wait for Everything to post this message to all top level windows when its up and running.
		write(L"Everything IPC window not found, IPC unavailable.\n");
	}

	return 0;
}

int compare_list_items(const void *a,const void *b)
{
	int i;

	i = wcsicmp(EVERYTHING_IPC_ITEMPATH(sort_list,a),EVERYTHING_IPC_ITEMPATH(sort_list,b));

	if (!i)
	{
		return wcsicmp(EVERYTHING_IPC_ITEMFILENAME(sort_list,a),EVERYTHING_IPC_ITEMFILENAME(sort_list,b));
	}
	else
	if (i > 0)
	{
		return 1;
	}
	else
	{
		return -1;
	}
}

static void write(wchar_t *text)
{
	DWORD mode;
	int wlen;
	DWORD numwritten;
	HANDLE output_handle;

	output_handle = GetStdHandle(STD_OUTPUT_HANDLE);

	wlen = wstring_length(text);

	if (GetConsoleMode(output_handle,&mode))
	{
		WriteConsoleW(output_handle,text,wlen,&numwritten,0);
	}
	else
	{
		char *buf;
		int len;

		len = WideCharToMultiByte(GetConsoleCP(),0,text,wlen,0,0,0,0);
		if (len)
		{
			buf = HeapAlloc(GetProcessHeap(),0,len);
			if (buf)
			{
				WideCharToMultiByte(GetConsoleCP(),0,text,wlen,buf,len,0,0);

				WriteFile(output_handle,buf,len,&numwritten,0);

				HeapFree(GetProcessHeap(),0,buf);
			}
		}
	}
}

static void write_DWORD(DWORD value)
{
	wchar_t buf[256];
	wchar_t *d;

	d = buf + 256;
	*--d = 0;

	if (value)
	{
		DWORD i;

		i = value;

		while(i)
		{
			*--d = '0' + (i % 10);

			i /= 10;
		}
	}
	else
	{
		*--d = '0';
	}

	write(d);
}

void listresultsW(EVERYTHING_IPC_LIST *list)
{
	DWORD i;

	if (sort)
	{
		sort_list = list;
		qsort(list->items,list->numitems,sizeof(EVERYTHING_IPC_ITEM),compare_list_items);
	}


	for(i=0;i<list->numitems;i++)
	{
		if (list->items[i].flags & EVERYTHING_IPC_DRIVE)
		{MessageBoxA(0,"LPCSTR lpText","LPCSTR lpCaption",0);
			write(EVERYTHING_IPC_ITEMFILENAME(list,&list->items[i]));
			write(L"\r\n");
		}
		else
		{MessageBoxA(0,"LPCSTR else","LPCSTR lpCaption",0);
			printf(EVERYTHING_IPC_ITEMPATH(list,&list->items[i]));
			write(L"\\");
			printf(EVERYTHING_IPC_ITEMFILENAME(list,&list->items[i]));
			write(L"\r\n");
		}
	}

	PostQuitMessage(0);
}

// custom window proc
LRESULT __stdcall window_proc(HWND hwnd,UINT msg,WPARAM wParam,LPARAM lParam)
{
	printf("proc[%d][%d]\n",msg,WM_COPYDATA);
	switch(msg)
	{
		case WM_COPYDATA:
		{
			COPYDATASTRUCT *cds = (COPYDATASTRUCT *)lParam;
			printf("cds[%d][%d]\n",cds->dwData,COPYDATA_IPCTEST_QUERYCOMPLETEA);
			switch(cds->dwData)
			{
				case COPYDATA_IPCTEST_QUERYCOMPLETEA:
					listresultsW((EVERYTHING_IPC_LIST *)cds->lpData);
					gotData=1;
					return TRUE;
			}

			break;
		}
	}

	return DefWindowProc(hwnd,msg,wParam,lParam);
}

void help(void)
{
	write(L"-r Search the database using a basic POSIX regular expression.\n");
	write(L"-i Does a case sensitive search.\n");
	write(L"-w Does a whole word search.\n");
	write(L"-p Does a full path search.\n");
	write(L"-h --help Display this help.\n");
	write(L"-n <num> Limit the amount of results shown to <num>.\n");
	write(L"-s Sort by full path.\n");
}

// main entry
int main(int argc,char **argv)
{
	WNDCLASSEX wcex;
	HWND hwnd;
	MSG msg;
	int ret;
	int q;
	wchar_t *search;
	wchar_t *d;
	wchar_t *e;
	wchar_t *s;
	int match_whole_word = 0;
	int match_path = 0;
	int regex = 0;
	int match_case = 0;
	int wasexename = 0;
	int matchpath = 0;
	int i;
	int wargc;
	wchar_t **wargv;
	DWORD num = EVERYTHING_IPC_ALLRESULTS;

	ZeroMemory(&wcex,sizeof(wcex));
	wcex.cbSize = sizeof(wcex);

	if (!GetClassInfoEx(GetModuleHandle(0),TEXT("IPCTEST"),&wcex))
	{
		ZeroMemory(&wcex,sizeof(wcex));
		wcex.cbSize = sizeof(wcex);
		wcex.hInstance = GetModuleHandle(0);
		wcex.lpfnWndProc = window_proc;
		wcex.lpszClassName = TEXT("IPCTEST");

		if (!RegisterClassEx(&wcex))
		{
			write(L"failed to register IPCTEST window class\n");

			return 1;
		}
	}

	if (!(hwnd = CreateWindow(
		TEXT("IPCTEST"),
		TEXT(""),
		0,
		0,0,0,0,
		0,0,GetModuleHandle(0),0)))
	{
		write(L"failed to create IPCTEST window\n");

		return 1;
	}
	// windowHandle=hwnd;

	int ir=EverythingSendQuery(hwnd,"qgbcs");
	printf("[%d]",ir);



	printf("[%d]",hwnd);


	return 23;








	// allow the everything window to send a reply.
	user32_hdll = LoadLibrary(L"user32.dll");

	if (user32_hdll)
	{
		pChangeWindowMessageFilterEx = (BOOL (WINAPI *)(HWND hWnd,UINT message,DWORD action,PCHANGEFILTERSTRUCT pChangeFilterStruct))GetProcAddress(user32_hdll,"ChangeWindowMessageFilterEx");

		if (pChangeWindowMessageFilterEx)
		{
			pChangeWindowMessageFilterEx(hwnd,WM_COPYDATA,MSGFLT_ALLOW,0);
		}
	}

	wargv = CommandLineToArgvW(GetCommandLineW(),&wargc);

	search = HeapAlloc(GetProcessHeap(),0,65536);
	if (!search)
	{
		write(L"failed to allocate ");
		write_DWORD(65536);
		write(L" bytes for search buffer.\n");

		if (user32_hdll)
		{
			FreeLibrary(user32_hdll);
		}

		return 1;
	}

	d = search;

	// allow room for null terminator
	e = search + (65536 / sizeof(wchar_t)) - 1;

	wargc--;
	i = 0;
	for(;;)
	{
		if (i >= wargc) break;

		if (wcsicmp(wargv[i+1],L"-r") == 0)
		{
			regex = 1;
		}
		else
		if (wcsicmp(wargv[i+1],L"-i") == 0)
		{
			match_case = 1;
		}
		else
		if (wcsicmp(wargv[i+1],L"-w") == 0)
		{
			match_whole_word = 1;
		}
		else
		if (wcsicmp(wargv[i+1],L"-p") == 0)
		{
			match_path = 1;
		}
		else
		if (wcsicmp(wargv[i+1],L"-s") == 0)
		{
			sort = 1;
		}
		else
		if ((wcsicmp(wargv[i+1],L"-n") == 0) && (i + 1 < wargc))
		{
			i++;

			num = wstring_to_int(wargv[i+1]);
		}
		else
		if (wargv[i+1][0] == '-')
		{
			// unknwon command
			help();
			HeapFree(GetProcessHeap(),0,search);

			if (user32_hdll)
			{
				FreeLibrary(user32_hdll);
			}

			return 1;
		}
		else
		{
			// keep quotes ?
			q = 0;

			s = wargv[i+1];
			while(*s)
			{
				if ((*s == ' ') || (*s == '\t') || (*s == '\r') || (*s == '\n'))
				{
					q = 1;
					break;
				}

				s++;
			}

			if ((d != search) && (d < e)) *d++ = ' ';

			if (q)
			{
				if (d < e) *d++ = '"';
			}

			// copy append to search
			s = wargv[i+1];
			while(*s)
			{
				if (d < e) *d++ = *s;
				s++;
			}

			if (q)
			{
				if (d < e) *d++ = '"';
			}
		}

		i++;
	}

	// null terminate
	*d = 0;

	if (!sendquery(hwnd,num,search,regex,match_case,match_whole_word,match_path))
	{
		// send query reports error

		HeapFree(GetProcessHeap(),0,search);

		if (user32_hdll)
		{
			FreeLibrary(user32_hdll);
		}

		return 1;
	}

	HeapFree(GetProcessHeap(),0,search);

	// message pump
loop:

	// update windows
	if (PeekMessage(&msg,NULL,0,0,0))
	{
		ret = (int)GetMessage(&msg,0,0,0);
		if (ret <= 0) goto exit;

		// let windows handle it.
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
	else
	{
		WaitMessage();
	}

	goto loop;

exit:

	if (user32_hdll)
	{
		FreeLibrary(user32_hdll);
	}

	return 0;
}

static int wstring_to_int(const wchar_t *s)
{
	const wchar_t *p;
	int value;

	p = s;
	value = 0;

	while(*p)
	{
		if (!((*p >= '0') && (*p <= '9')))
		{
			break;
		}

		value *= 10;
		value += *p - '0';
		p++;
	}

	return value;
}
