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
print sys.modules\n\
print '*'*55\n\
print globals()\n\
os.system('echo %cd%')\n\
os.environ['TCL_LIBRARY']='C:/python27/tcl/tcl8.5'\n\
os.environ['TK_LIBRARY']= 'C:/python27/tcl/tk8.5' \n\
os.environ['TIX_LIBRARY']='C:/python27/tcl/tk8.4.3'\n\
from Tkinter import Tk\n\
Tk(baseName='qgb').mainloop()\n\
	");

  	Py_Finalize();
	// printf("2");
}