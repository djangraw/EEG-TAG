%%%
%%%This function is for loading an entire .dat file into a single matrix
%%%that is fit for analysis.  It loads up individual channels (based on
%%%memory availability) and does a basic set of filtering and downsampling
%%%for each channel.  This reduces the matrix size into something more
%%%manageable so it can easily be handled by Matlab.  The first row of the
%%%matrix is the analog channel describing the events, this information is
%%%duplicated in a cell matrix that contains the timetamps corresponding to
%%%the events.
%%%
%%%[outputanalogdata eventdata] = preprocess_dat_file(filename,samplingfreq,Nchannels,Nanalogchannels,analogchanneloffset);
%%%
%%%filename => of the .dat file
%%%samplingfreq    => .dat file sampling freq
%%%Nchannels       => Number of channels stored in the .dat file
%%%Nanalogchannels => numnber of those channels that are actually analog
%%%channels you wnat
%%%analogchanneloffset => Tells how many informatin channels are located in the .dat file
%%%before you get into the actual data analog channels (probably = 2)
%%%
%%%Last modified Jan 2009 EAP

function [outputanalogdata eventdata] = preprocess_dat_file(filename,samplingfreq,Nchannels,Nanalogchannels,analogchanneloffset)

%%%
%%%Create an empty filter structure
P   = preprocess_filter_struct;
%%%
%%%Populate the filter structure with the basic filtering operations
currentfreq    = samplingfreq;
hipassfilter   = 0.5;
notch_filt     = 0;%[60];%set for 60 typically
downsamplefreq = 256;
amountofdelay  = 1;
displayfilter  = 0;
FIR            = 0;
%%%Create the filtering structure
[P] = preprocess_filter_create(P,currentfreq,hipassfilter,notch_filt,downsamplefreq,amountofdelay,displayfilter,FIR);

%%%
%%%Pre-allocate memory for the downsampled and completely pre-processed
%%%analog data that will be outputted (one event channel and the rest are
%%%the analog data).
[qty_of_numbers] = getdatfilelength(filename,Nchannels);
qty_of_numbers   = floor(qty_of_numbers/P.fsr);%%%length after downsampling
outputanalogdata = zeros(Nanalogchannels+1,qty_of_numbers);

%%%
%%%Load up the event data
channelsubset = 1;
blocklength   = 50000;%this is loading about 24 sec of data (if sampling at 2048)
mode          = 0;%load the full amount of each channel
fileoffset    = 0;
[analogeventdata filetell] = load_dat_file(filename, Nchannels, mode, channelsubset, blocklength, fileoffset);
%%%
%%%Delay the analog version appropriately
Pcurrent            = P;
Pcurrent.channelsNo = 1;
Pcurrent.fsr        = 1;%don't downsample it
%if P.delay is 1: doesn't this do nothing but return the original signal?
%%%Put the downsampled analog event data into the output matrix.
[delayedanalogeventdata, Pcurrent] = preprocess_filter_apply(analogeventdata,Pcurrent);
%%%
%%%Convert the analog events to lists of timestamps=>you *must* do this
%%%before the signal is downsampled or you can lose clarity in the signal.
[eventdata]  = analogevents2timestamps(delayedanalogeventdata,samplingfreq);
%%%
%%%Now make a delayed version that is also downsampled
Pcurrent            = P;
Pcurrent.channelsNo = 1;
[outputanalogdata(1,:), Pcurrent] = preprocess_filter_apply(analogeventdata,Pcurrent);
%%%
clear delayedanalogeventdata analogeventdata%don't need the original anymore
%%%

%%%
%%%Determine how much memory is available for loading and processing the
%%%analog data.  Since you will be filtering and subsampling it, you should
%%%use no more than half of the available memory (using a quarter of a gig here). 
[qty_of_numbers]          = getdatfilelength(filename,Nchannels);
load_memory_limit         = 0.25*(1000000000);%qtr gig as matrix limiting size
currentvariables          = whos;
[recomendedmatrixentries] = recommendedMatrixsize(load_memory_limit,currentvariables);
%%%
%%%Determine how many channels can be loaded at a time (depends on the
%%%memory available), and then process and downsample the data.  
channels2process = floor(recomendedmatrixentries/qty_of_numbers);
%%%
%%%If you are going to have to do things in two chunks, you may as well
%%%make them two even-sized chunks
if channels2process > 0.5*Nanalogchannels
    channels2process = floor(0.5*Nanalogchannels);
end
    
%%%
for k = channels2process:channels2process:Nanalogchannels
    disp('.................');
    disp(['Loading and processing channel ',int2str((k-channels2process+1)),' through channel ',int2str(k)]);
    %%%
    Pcurrent = P;
    Pcurrent.channels = [1:channels2process];
    %%%Load the analog data
    [analogdata filetell] = load_dat_file(filename, Nchannels, mode, [(k-channels2process+1):k]+analogchanneloffset, blocklength, fileoffset);
    %%%Apply the filters and downsample the signals, saving the results
    %%%in the output matrix
    [outputanalogdata([(k-channels2process+1):k]+1,:), Pcurrent] = preprocess_filter_apply(double(analogdata),Pcurrent);    
    %%%clear the memory
    clear analogdata Pcurrent
    
    %%%Another option would be to load a full channel of data, but only
    %%%filter half of it, then filter the other half of it (if this saves
    %%%memory).  Or, instead of loading one full channel of data, could
    %%%load multiple channels of data but only a portion of each channel's
    %%%data.
end
%%%Do any channels that didn't make it into the main group.
if rem(Nanalogchannels,channels2process) > 0
    Pcurrent = P;
    Pcurrent.channels = [1:rem(Nanalogchannels,channels2process)];
    %%%Load the analog data
    [analogdata filetell] = load_dat_file(filename, Nchannels, mode, [(k+1):Nanalogchannels]+analogchanneloffset, blocklength, fileoffset);
    %%%Apply the filters and downsample the signals, saving the results
    %%%in the output matrix
    [outputanalogdata([(k+1):Nanalogchannels]+1,:), Pcurrent] = preprocess_filter_apply(double(analogdata),Pcurrent);    
    %%%clear the memory
    clear analogdata Pcurrent    
end    

