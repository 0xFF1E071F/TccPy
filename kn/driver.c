#include <ddk/ntddk.h>

NTSTATUS
STDCALL
DriverDispatch(IN PDEVICE_OBJECT DeviceObject,
               IN PIRP Irp)
{
    return STATUS_SUCCESS;
}

VOID
STDCALL
DriverUnload(IN PDRIVER_OBJECT DriverObject)
{
    DbgPrint("DriverUnload() !\n");
    return;
}

#define DELAY_ONE_MICROSECOND   (-10)
#define DELAY_ONE_MILLISECOND   (DELAY_ONE_MICROSECOND*1000)

STDCALL int d(IN PVOID pDisplayMem){
    int i =0;
    LARGE_INTEGER LI;//单位为100ns
    LI.QuadPart = DELAY_ONE_MILLISECOND;
    LI.QuadPart *= 1;
    for (i =989999;i<999999; i+=4)

        KeDelayExecutionThread(KernelMode,0,&LI);
        *(BYTE*)((ULONG)pDisplayMem + i + 1)  = 255;  //g
    return 0;


   for ( i = 0;i<4*1440*900 +900*96*4; i+=4)
  {
      if (i>=89999 && i<99999)
    {
      *(BYTE*)((ULONG)pDisplayMem + i )  = 0;    //b
      *(BYTE*)((ULONG)pDisplayMem + i + 1)  = 255;  //g
      *(BYTE*)((ULONG)pDisplayMem + i + 2)  = 0;  //r
      *(BYTE*)((ULONG)pDisplayMem + i + 3)  = 0x00;  //reserve
    }
      continue;
  }
    return 0;
}

NTSTATUS
STDCALL
DriverEntry(IN PDRIVER_OBJECT DriverObject,
            IN PUNICODE_STRING RegistryPath)
{
    int pid=(int)PsGetCurrentProcessId();
    DbgPrint("(%i) !\n",pid);// 4

  ULONG i = 0;
  ULONG uWidth = 1440;  // 分辨率是1440*900
  ULONG uHeight = 900;
  ULONG uLen = 4*uWidth*uHeight+uHeight*96*4;// 4个byte表示一个象素



    LARGE_INTEGER PhysicalAddress;
  PhysicalAddress.LowPart = 0xE0000000; //在我电脑上，显卡内存映射的起始地址
  PhysicalAddress.HighPart = 0;

  PVOID pDisplayMem;
  pDisplayMem = MmMapIoSpace(PhysicalAddress, uLen, MmNonCached );

  for(i=0;i<2999;i+=1)
  d(pDisplayMem);
//
//   for ( i = 0;i<uLen; i+=4)
//  {
//      *(BYTE*)((ULONG)pDisplayMem + i )  = i% 0xff;    //r
//      *(BYTE*)((ULONG)pDisplayMem + i + 1)  = 0x0;  //g
//      *(BYTE*)((ULONG)pDisplayMem + i + 2)  = 0x0;  //b
//      *(BYTE*)((ULONG)pDisplayMem + i + 3)  = 0x00;  //reserve
//      continue;
//    if (i<uLen/4)
//    {
//      //填充一个象素  白
//      *(BYTE*)((ULONG)pDisplayMem + i )  = 0xFF;    //r
//      *(BYTE*)((ULONG)pDisplayMem + i + 1)  = 0xFF;  //g
//      *(BYTE*)((ULONG)pDisplayMem + i + 2)  = 0xFF;  //b
//      *(BYTE*)((ULONG)pDisplayMem + i + 3)  = 0x00;  //reserve
//    }
//
//    if (i>=uLen/4 && i<uLen/2)
//    {
//      *(BYTE*)((ULONG)pDisplayMem + i )  = 0xFF;//蓝
//      *(BYTE*)((ULONG)pDisplayMem + i + 1)  = 0x00;
//      *(BYTE*)((ULONG)pDisplayMem + i + 2)  = 0x00;
//      *(BYTE*)((ULONG)pDisplayMem + i + 3)  = 0x00;
//    }
//    if (i>=uLen/2 && i<uLen*3/4)
//    {
//      *(BYTE*)((ULONG)pDisplayMem + i )  = 0x00;
//      *(BYTE*)((ULONG)pDisplayMem + i + 1)  = 0xFF;//绿
//      *(BYTE*)((ULONG)pDisplayMem + i + 2)  = 0x00;
//      *(BYTE*)((ULONG)pDisplayMem + i + 3)  = 0x00;
//    }
//    if (i>=uLen*3/4 && i<uLen)
//    {
//      *(BYTE*)((ULONG)pDisplayMem + i )  = 0x00;
//      *(BYTE*)((ULONG)pDisplayMem + i + 1)  = 0x00;
//      *(BYTE*)((ULONG)pDisplayMem + i + 2)  = 0xFF;//红
//      *(BYTE*)((ULONG)pDisplayMem + i + 3)  = 0x00;
//    }
//  }


DbgPrint("%i]My Driver Loaded!",pDisplayMem);



    DriverObject->DriverUnload = DriverUnload;
    return STATUS_SUCCESS;
}
