%%%
%%%This function loads up a list of event timestamps directly from a
%%%ProducerConsumer .dat file.
%%%
%%%If the file is already loaded and you just want to convert the analog
%%%signal to event timestamps, you can call the analogevents2timestamps
%%%function directly.
%%%
%%%[eventdata]  = extractDatEvents(filename, samplingfreq);
%%%
%%%last modified July 2009, EAP

function [eventdata]  = extractDatEvents(filename, samplingfreq)

%%%
%%%Create an empty filter structure
P   = preprocess_filter_struct;
%%%
%%%Populate the filter structure with the basic filtering operations
currentfreq    = samplingfreq;
hipassfilter   = 0.5;
notch_filt     = [60];
downsamplefreq = samplingfreq;
amountofdelay  = 1;
displayfilter  = 1;
FIR            = 0;
%%%Create the filtering structure
[P] = preprocess_filter_create(P,currentfreq,hipassfilter,notch_filt,downsamplefreq,amountofdelay,displayfilter,FIR);

%%%
%%%Load up the event data
channelsubset = 1;
blocklength   = 50000;%this is loading about 24 sec of data (if sampling at 2048)
mode          = 0;%load the full amount of each channel
fileoffset    = 0;
Nchannels     = 73;
disp('Loading the event channel data from the .dat file.');
[analogeventdata filetell] = load_dat_file(filename, Nchannels, mode, channelsubset, blocklength, fileoffset);
disp('Finished loading the analog event channel data.');

%%%
%%%Delay the analog version appropriately
Pcurrent            = P;
Pcurrent.channelsNo = 1;%this ensures that the channel is not filtered, just delayed
Pcurrent.fsr        = 1;%don't downsample it
[delayedanalogeventdata, Pcurrent] = preprocess_filter_apply(analogeventdata,Pcurrent);

%%%
%%%Convert the analog events to lists of timestamps=>you *must* do this
%%%before the signal is downsampled or you can lose clarity in the signal.
[eventdata]  = analogevents2timestamps(delayedanalogeventdata,samplingfreq);

%%%
clear delayedanalogeventdata analogeventdata%don't need the original anymore



