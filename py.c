#include<stdlib.h>
#include<python.h>

int main(){
	
	int f=open("py.c",'r');

	printf("[%i %i]\n",Py_IsInitialized(),f);
	exit(2);
	// Py_Initialize();
	Py_NoSiteFlag++;
	Py_FrozenFlag++;
	Py_InitializeEx(1);
  	PyRun_SimpleString("\
print 'Hello Python!'\n\
import sys\n\
for i in sys.modules:\n\
	print i\n\
print '*'*33\n\
print sys.path\n\
print '*'*44\n\
print globals()\n\
os.system('pwd')\n\
	");

  	Py_Finalize();
	printf("2");
}