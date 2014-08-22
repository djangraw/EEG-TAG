%%%
%%%This creates an empty filtering structure 'P'.  This structure can then be
%%%initialized with specific filter settings by preprocess_filter, which in
%%%turn can be used by such functions as preprocess_EEG_data.  It is based
%%%on Lucas' preprocessinit.m and preprocess.m.
%%%
%%%P = preprocess_filter_struct;
%%%
% All parameters are stored in the structure P. 
% Most are optional parameters that can be
% omitted or left empty: fsref is a references sampling frequency for
% preprocessing and output. The data may have been recorded at a sampling
% frequency that is much higher than what is needed. Use this to down sample
% the data. channels is a vector that contains the channels numbers to be
% processed. This is useful if not all channels are to be processed, in
% which case one would list all the channels except the once that are to be
% omitted. V is a matrix of column vectors of size D specifying the
% directions that are to be subtracted from the data. The can be computed
% using our calibration routine eyecalibrate() with data that has been
% recorded at the beginning of the experiment.
%%%
%%%Last modified Jan 2009, EAP

function P = preprocess_filter_struct

P.fsr        = [];%desired goal frequency after downsampling
P.Zdec       = [];%for channels that get filtered, the initial/final conditions of the delays can be stored here
P.Zdel       = [];%for channels that just get delayed (no filtering), the initial/final conditions of the delays can be stored here
P.channels   = [];%id numbers of specific analog channels that should be filtered
P.channelsNo = [];%id numbers of specific analog channels that should NOT be filtered, just downsampled
P.delay      = 0;%for channels that need to be delayed, this is how many samples to delay them
P.a          = [];%filter denominator
P.b          = [];%filter numerator
P.U          = [];%used for removing eye artifact