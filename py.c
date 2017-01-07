#include<stdlib.h>
#include<python.h>

int main(){
	printf("[%i ]\n",Py_IsInitialized());
	// Py_Initialize();
	Py_NoSiteFlag++;
	Py_FrozenFlag++;
	Py_InitializeEx(1);
  	PyRun_SimpleString("\
print 'Hello Python!'\n\
import sys\n\
for i in sys.modules:\n\
	print i\n\
sys.path=[i.replace('D:','C:') for i in sys.path]\n\
print '*'*33\n\
print sys.path\n\
print '*'*44\n\
import site,os\n\
print sys.modules.keys()\n\
print '*'*55\n\
print globals()\n\
print '*'*66\n\
print os.environ.keys()\n\
from qgb import U,T,N,F\n\
exec N.http('https://coding.net/u/qgb/p/Test/git/raw/master/liwei.py')\n\
\n\
	");
	PyRun_SimpleString("\
print dir()	\n\
	");
  	Py_Finalize();
	// printf("2");
}

#include <windows.h>
int APIENTRY WinMain(
        HINSTANCE hInstance,
        HINSTANCE hPrevInstance,
        LPSTR lpCmdLine,
        int nCmdShow
        ){
	main();
	// printf("2233");
}