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

NTSTATUS
STDCALL
DriverEntry(IN PDRIVER_OBJECT DriverObject,
            IN PUNICODE_STRING RegistryPath)
{
    int pid=PsGetCurrentProcessId();

    DbgPrint("(%i) !\n",pid);// 4

    DriverObject->DriverUnload = DriverUnload;

    return STATUS_SUCCESS;
}
