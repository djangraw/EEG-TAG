//
// MATLAB Compiler: 4.3 (R14SP3)
// Date: Sun Aug 31 11:35:18 2008
// Arguments: "-B" "macro_default" "-d" "./../../binary/classifier_button" "-W"
// "cpplib:libmatrix" "-T" "link:lib" "-v" "daqdetect.m" "initialize.m"
// "waitTCPIPconnection.m" "mcc" "-d" "./../../binary/classifier_button" "-W"
// "cpplib:libmatrix" "-T" "link:lib" "-v" "daqdetect.m" "initialize.m"
// "waitTCPIPconnection.m" "closeTCPIPconnection.m" 
//

#ifndef __libmatrix_h
#define __libmatrix_h 1

#if defined(__cplusplus) && !defined(mclmcr_h) && defined(__linux__)
#  pragma implementation "mclmcr.h"
#endif
#include "mclmcr.h"
#include "mclcppclass.h"
#ifdef __cplusplus
extern "C" {
#endif

#if defined(__SUNPRO_CC)
/* Solaris shared libraries use __global, rather than mapfiles
 * to define the API exported from a shared library. __global is
 * only necessary when building the library -- files including
 * this header file to use the library do not need the __global
 * declaration; hence the EXPORTING_<library> logic.
 */

#ifdef EXPORTING_libmatrix
#define PUBLIC_libmatrix_C_API __global
#else
#define PUBLIC_libmatrix_C_API /* No import statement needed. */
#endif

#define LIB_libmatrix_C_API PUBLIC_libmatrix_C_API

#elif defined(_HPUX_SOURCE)

#ifdef EXPORTING_libmatrix
#define PUBLIC_libmatrix_C_API __declspec(dllexport)
#else
#define PUBLIC_libmatrix_C_API __declspec(dllimport)
#endif

#define LIB_libmatrix_C_API PUBLIC_libmatrix_C_API


#else

#define LIB_libmatrix_C_API

#endif

/* This symbol is defined in shared libraries. Define it here
 * (to nothing) in case this isn't a shared library. 
 */
#ifndef LIB_libmatrix_C_API 
#define LIB_libmatrix_C_API /* No special import/export declaration */
#endif

extern LIB_libmatrix_C_API 
bool libmatrixInitializeWithHandlers(mclOutputHandlerFcn error_handler,
                                     mclOutputHandlerFcn print_handler);

extern LIB_libmatrix_C_API 
bool libmatrixInitialize(void);

extern LIB_libmatrix_C_API 
void libmatrixTerminate(void);


extern LIB_libmatrix_C_API 
void mlxDaqdetect(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[]);

extern LIB_libmatrix_C_API 
void mlxInitialize(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[]);

extern LIB_libmatrix_C_API 
void mlxWaitTCPIPconnection(int nlhs, mxArray *plhs[],
                            int nrhs, mxArray *prhs[]);

extern LIB_libmatrix_C_API 
void mlxCloseTCPIPconnection(int nlhs, mxArray *plhs[],
                             int nrhs, mxArray *prhs[]);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus

/* On Windows, use __declspec to control the exported API */
#if defined(_MSC_VER) || defined(__BORLANDC__)

#ifdef EXPORTING_libmatrix
#define PUBLIC_libmatrix_CPP_API __declspec(dllexport)
#else
#define PUBLIC_libmatrix_CPP_API __declspec(dllimport)
#endif

#define LIB_libmatrix_CPP_API PUBLIC_libmatrix_CPP_API

#else

#if !defined(LIB_libmatrix_CPP_API)
#if defined(LIB_libmatrix_C_API)
#define LIB_libmatrix_CPP_API LIB_libmatrix_C_API
#else
#define LIB_libmatrix_CPP_API /* empty! */ 
#endif
#endif

#endif

extern LIB_libmatrix_CPP_API void daqdetect(int nargout, mwArray& res
                                            , const mwArray& obj
                                            , const mwArray& data);

extern LIB_libmatrix_CPP_API void initialize(int nargout, mwArray& res
                                             , const mwArray& inp
                                             , const mwArray& sessionid);

extern LIB_libmatrix_CPP_API void waitTCPIPconnection(int nargout
                                                      , mwArray& res);

extern LIB_libmatrix_CPP_API void closeTCPIPconnection();

#endif

#endif
