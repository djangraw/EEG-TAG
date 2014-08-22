//
// MATLAB Compiler: 4.3 (R14SP3)
// Date: Sun Aug 31 11:35:18 2008
// Arguments: "-B" "macro_default" "-d" "./../../binary/classifier_button" "-W"
// "cpplib:libmatrix" "-T" "link:lib" "-v" "daqdetect.m" "initialize.m"
// "waitTCPIPconnection.m" "mcc" "-d" "./../../binary/classifier_button" "-W"
// "cpplib:libmatrix" "-T" "link:lib" "-v" "daqdetect.m" "initialize.m"
// "waitTCPIPconnection.m" "closeTCPIPconnection.m" 
//

#include "mclmcr.h"

#ifdef __cplusplus
extern "C" {
#endif
extern const unsigned char __MCC_libmatrix_session_key[] = {
        '8', '6', '3', '8', 'D', 'F', 'B', 'A', '6', '0', 'C', '8', '1', 'A',
        '7', 'E', 'B', '8', '3', '9', 'A', 'B', '2', '1', '8', '7', 'F', '9',
        '7', 'A', '2', '0', '1', '7', 'C', 'E', '5', '9', 'B', '2', 'B', '6',
        'D', '8', '4', '8', 'C', 'F', 'A', 'C', '4', 'F', '6', '0', 'A', '7',
        '0', 'F', 'B', '4', '2', 'E', 'B', 'F', '6', '3', '7', '7', 'E', '9',
        'C', 'B', '6', 'D', 'D', '4', 'D', 'D', 'B', '1', '9', '5', '9', 'C',
        'A', '4', 'C', '2', '5', '2', 'F', '7', '1', '9', '9', 'A', 'E', 'D',
        '9', '6', 'C', 'C', '6', '4', '4', '7', 'B', '0', '5', '9', '8', '1',
        'B', '5', 'D', '0', '9', '9', 'E', '7', 'D', 'E', 'B', '1', '9', 'B',
        '3', '7', '0', '4', '4', 'D', '1', 'A', 'C', 'A', '6', '6', 'B', '8',
        '2', '4', '6', '0', '8', 'A', 'D', 'D', '3', 'C', 'E', '0', '3', 'C',
        '9', 'F', 'C', '1', '2', '0', 'A', '1', '5', '9', '7', 'E', 'C', '6',
        '8', '5', '4', '9', '2', '7', '4', 'E', 'D', 'C', '3', '0', 'B', 'A',
        'A', '9', '6', 'D', '9', '3', 'E', '2', '5', '9', 'C', '5', '0', '4',
        '1', '5', 'A', '4', '3', 'B', '5', '6', 'E', 'A', '7', 'B', '5', 'A',
        '4', 'A', '8', 'C', 'F', '6', '0', 'B', '1', 'E', '1', '1', '7', '6',
        'A', 'F', '7', '8', 'B', '5', '5', '7', '7', '3', 'F', '8', '2', '3',
        'A', 'E', '8', 'B', '1', 'A', 'F', 'E', '0', '0', '0', '2', 'A', '4',
        '6', '1', '8', 'A', '\0'};

extern const unsigned char __MCC_libmatrix_public_key[] = {
        '3', '0', '8', '1', '9', 'D', '3', '0', '0', 'D', '0', '6', '0', '9',
        '2', 'A', '8', '6', '4', '8', '8', '6', 'F', '7', '0', 'D', '0', '1',
        '0', '1', '0', '1', '0', '5', '0', '0', '0', '3', '8', '1', '8', 'B',
        '0', '0', '3', '0', '8', '1', '8', '7', '0', '2', '8', '1', '8', '1',
        '0', '0', 'C', '4', '9', 'C', 'A', 'C', '3', '4', 'E', 'D', '1', '3',
        'A', '5', '2', '0', '6', '5', '8', 'F', '6', 'F', '8', 'E', '0', '1',
        '3', '8', 'C', '4', '3', '1', '5', 'B', '4', '3', '1', '5', '2', '7',
        '7', 'E', 'D', '3', 'F', '7', 'D', 'A', 'E', '5', '3', '0', '9', '9',
        'D', 'B', '0', '8', 'E', 'E', '5', '8', '9', 'F', '8', '0', '4', 'D',
        '4', 'B', '9', '8', '1', '3', '2', '6', 'A', '5', '2', 'C', 'C', 'E',
        '4', '3', '8', '2', 'E', '9', 'F', '2', 'B', '4', 'D', '0', '8', '5',
        'E', 'B', '9', '5', '0', 'C', '7', 'A', 'B', '1', '2', 'E', 'D', 'E',
        '2', 'D', '4', '1', '2', '9', '7', '8', '2', '0', 'E', '6', '3', '7',
        '7', 'A', '5', 'F', 'E', 'B', '5', '6', '8', '9', 'D', '4', 'E', '6',
        '0', '3', '2', 'F', '6', '0', 'C', '4', '3', '0', '7', '4', 'A', '0',
        '4', 'C', '2', '6', 'A', 'B', '7', '2', 'F', '5', '4', 'B', '5', '1',
        'B', 'B', '4', '6', '0', '5', '7', '8', '7', '8', '5', 'B', '1', '9',
        '9', '0', '1', '4', '3', '1', '4', 'A', '6', '5', 'F', '0', '9', '0',
        'B', '6', '1', 'F', 'C', '2', '0', '1', '6', '9', '4', '5', '3', 'B',
        '5', '8', 'F', 'C', '8', 'B', 'A', '4', '3', 'E', '6', '7', '7', '6',
        'E', 'B', '7', 'E', 'C', 'D', '3', '1', '7', '8', 'B', '5', '6', 'A',
        'B', '0', 'F', 'A', '0', '6', 'D', 'D', '6', '4', '9', '6', '7', 'C',
        'B', '1', '4', '9', 'E', '5', '0', '2', '0', '1', '1', '1', '\0'};

static const char * MCC_libmatrix_matlabpath_data[] = 
    { "libmatrix/", "toolbox/compiler/deploy/", "classifieralgorithms/",
      "toolbox/eeglab/functions/", "toolbox/eeglab/plugins/fmrib1.2/",
      "toolbox/fullbnt-1.0.2/kpmtools/", "$TOOLBOXMATLABDIR/general/",
      "$TOOLBOXMATLABDIR/ops/", "$TOOLBOXMATLABDIR/lang/",
      "$TOOLBOXMATLABDIR/elmat/", "$TOOLBOXMATLABDIR/elfun/",
      "$TOOLBOXMATLABDIR/specfun/", "$TOOLBOXMATLABDIR/matfun/",
      "$TOOLBOXMATLABDIR/datafun/", "$TOOLBOXMATLABDIR/polyfun/",
      "$TOOLBOXMATLABDIR/funfun/", "$TOOLBOXMATLABDIR/sparfun/",
      "$TOOLBOXMATLABDIR/scribe/", "$TOOLBOXMATLABDIR/graph2d/",
      "$TOOLBOXMATLABDIR/graph3d/", "$TOOLBOXMATLABDIR/specgraph/",
      "$TOOLBOXMATLABDIR/graphics/", "$TOOLBOXMATLABDIR/uitools/",
      "$TOOLBOXMATLABDIR/strfun/", "$TOOLBOXMATLABDIR/imagesci/",
      "$TOOLBOXMATLABDIR/iofun/", "$TOOLBOXMATLABDIR/audiovideo/",
      "$TOOLBOXMATLABDIR/timefun/", "$TOOLBOXMATLABDIR/datatypes/",
      "$TOOLBOXMATLABDIR/verctrl/", "$TOOLBOXMATLABDIR/codetools/",
      "$TOOLBOXMATLABDIR/helptools/", "$TOOLBOXMATLABDIR/winfun/",
      "$TOOLBOXMATLABDIR/demos/", "$TOOLBOXMATLABDIR/timeseries/",
      "$TOOLBOXMATLABDIR/hds/", "toolbox/local/", "toolbox/compiler/",
      "toolbox/database/database/", "toolbox/nnet/nnet/",
      "toolbox/nnet/nnutils/", "toolbox/optim/",
      "toolbox/signal/signal/", "toolbox/signal/sigtools/" };

static const char * MCC_libmatrix_classpath_data[] = 
    { "java/jar/toolbox/database.jar" };

static const char * MCC_libmatrix_libpath_data[] = 
    { "" };

static const char * MCC_libmatrix_app_opts_data[] = 
    { "" };

static const char * MCC_libmatrix_run_opts_data[] = 
    { "" };

static const char * MCC_libmatrix_warning_state_data[] = 
    { "" };


mclComponentData __MCC_libmatrix_component_data = { 

    /* Public key data */
    __MCC_libmatrix_public_key,

    /* Component name */
    "libmatrix",

    /* Component Root */
    "",

    /* Application key data */
    __MCC_libmatrix_session_key,

    /* Component's MATLAB Path */
    MCC_libmatrix_matlabpath_data,

    /* Number of directories in the MATLAB Path */
    44,

    /* Component's Java class path */
    MCC_libmatrix_classpath_data,
    /* Number of directories in the Java class path */
    1,

    /* Component's load library path (for extra shared libraries) */
    MCC_libmatrix_libpath_data,
    /* Number of directories in the load library path */
    0,

    /* MCR instance-specific runtime options */
    MCC_libmatrix_app_opts_data,
    /* Number of MCR instance-specific runtime options */
    0,

    /* MCR global runtime options */
    MCC_libmatrix_run_opts_data,
    /* Number of MCR global runtime options */
    0,
    
    /* Component preferences directory */
    "libmatrix_9A298BB1606CBFEBE29B61AFB1E6856D",

    /* MCR warning status data */
    MCC_libmatrix_warning_state_data,
    /* Number of MCR warning status modifiers */
    0,

    /* Path to component - evaluated at runtime */
    NULL

};

#ifdef __cplusplus
}
#endif


