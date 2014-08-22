//
// MATLAB Compiler: 4.3 (R14SP3)
// Date: Sun Aug 31 11:35:18 2008
// Arguments: "-B" "macro_default" "-d" "./../../binary/classifier_button" "-W"
// "cpplib:libmatrix" "-T" "link:lib" "-v" "daqdetect.m" "initialize.m"
// "waitTCPIPconnection.m" "mcc" "-d" "./../../binary/classifier_button" "-W"
// "cpplib:libmatrix" "-T" "link:lib" "-v" "daqdetect.m" "initialize.m"
// "waitTCPIPconnection.m" "closeTCPIPconnection.m" 
//

#include <stdio.h>
#define EXPORTING_libmatrix 1
#include "libmatrix.h"
#ifdef __cplusplus
extern "C" {
#endif

extern mclComponentData __MCC_libmatrix_component_data;

#ifdef __cplusplus
}
#endif


static HMCRINSTANCE _mcr_inst = NULL;


#if defined( _MSC_VER) || defined(__BORLANDC__) || defined(__WATCOMC__) || defined(__LCC__)
#include <windows.h>

static char path_to_dll[_MAX_PATH];

BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD dwReason, void *pv)
{
    if (dwReason == DLL_PROCESS_ATTACH)
    {
        char szDllPath[_MAX_PATH];
        char szDir[_MAX_DIR];
        if (GetModuleFileName(hInstance, szDllPath, _MAX_PATH) > 0)
        {
             _splitpath(szDllPath, path_to_dll, szDir, NULL, NULL);
            strcat(path_to_dll, szDir);
        }
	else return FALSE;
    }
    else if (dwReason == DLL_PROCESS_DETACH)
    {
    }
    return TRUE;
}
#endif
static int mclDefaultPrintHandler(const char *s)
{
    return fwrite(s, sizeof(char), strlen(s), stdout);
}

static int mclDefaultErrorHandler(const char *s)
{
    int written = 0, len = 0;
    len = strlen(s);
    written = fwrite(s, sizeof(char), len, stderr);
    if (len > 0 && s[ len-1 ] != '\n')
        written += fwrite("\n", sizeof(char), 1, stderr);
    return written;
}


/* This symbol is defined in shared libraries. Define it here
 * (to nothing) in case this isn't a shared library. 
 */
#ifndef LIB_libmatrix_C_API 
#define LIB_libmatrix_C_API /* No special import/export declaration */
#endif

LIB_libmatrix_C_API 
bool libmatrixInitializeWithHandlers(
    mclOutputHandlerFcn error_handler,
    mclOutputHandlerFcn print_handler
)
{
    if (_mcr_inst != NULL)
        return true;
    if (!mclmcrInitialize())
        return false;
    if (!mclInitializeComponentInstance(&_mcr_inst,
                                        &__MCC_libmatrix_component_data,
                                        true, NoObjectType, LibTarget,
                                        error_handler, print_handler))
        return false;
    return true;
}

LIB_libmatrix_C_API 
bool libmatrixInitialize(void)
{
    return libmatrixInitializeWithHandlers(mclDefaultErrorHandler,
                                           mclDefaultPrintHandler);
}

LIB_libmatrix_C_API 
void libmatrixTerminate(void)
{
    if (_mcr_inst != NULL)
        mclTerminateInstance(&_mcr_inst);
}


LIB_libmatrix_C_API 
void mlxDaqdetect(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[])
{
    mclFeval(_mcr_inst, "daqdetect", nlhs, plhs, nrhs, prhs);
}

LIB_libmatrix_C_API 
void mlxInitialize(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[])
{
    mclFeval(_mcr_inst, "initialize", nlhs, plhs, nrhs, prhs);
}

LIB_libmatrix_C_API 
void mlxWaitTCPIPconnection(int nlhs, mxArray *plhs[],
                            int nrhs, mxArray *prhs[])
{
    mclFeval(_mcr_inst, "waitTCPIPconnection", nlhs, plhs, nrhs, prhs);
}

LIB_libmatrix_C_API 
void mlxCloseTCPIPconnection(int nlhs, mxArray *plhs[],
                             int nrhs, mxArray *prhs[])
{
    mclFeval(_mcr_inst, "closeTCPIPconnection", nlhs, plhs, nrhs, prhs);
}

LIB_libmatrix_CPP_API 
void daqdetect(int nargout, mwArray& res
               , const mwArray& obj, const mwArray& data)
{
    mclcppMlfFeval(_mcr_inst, "daqdetect", nargout, 1, 2, &res, &obj, &data);
}

LIB_libmatrix_CPP_API 
void initialize(int nargout, mwArray& res, const mwArray& inp
                , const mwArray& sessionid)
{
    mclcppMlfFeval(_mcr_inst, "initialize", nargout,
                   1, 2, &res, &inp, &sessionid);
}

LIB_libmatrix_CPP_API 
void waitTCPIPconnection(int nargout, mwArray& res)
{
    mclcppMlfFeval(_mcr_inst, "waitTCPIPconnection", nargout, 1, 0, &res);
}

LIB_libmatrix_CPP_API 
void closeTCPIPconnection()
{
    mclcppMlfFeval(_mcr_inst, "closeTCPIPconnection", 0, 0, 0);
}
