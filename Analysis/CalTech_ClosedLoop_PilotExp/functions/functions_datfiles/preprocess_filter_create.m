%%%
%%%This function is for creating a filter that is used for filtering and/or
%%%downsampling some EEG data.  You can also create a filter that only is
%%%used to delay a signal.
%%%
%%%The inputted value P is the structure that holds all the filtering data.
%%%It can be created using preprocess_struct_create.m
%%%
%%%If you don't want a filter to be applied, just provide either a zero or
%%%[] input for that input value.
%%%
%%%Simply using [P] = preprocess_filter(P, currentfreq) will create a default structure for
%%%P and populate it with a set of default filtering values.  These include
%%%a hi-pass filter at 0.5 hz, notch filters at 60 and 120 hz, and
%%%downsampling to 256Hz (assuming the currentfreq is higher, if not, no
%%%downsampling is done), and a specifc delay value of 1 data point.
%%%
%%%Simply using [P] = preprocess_filter(amountofdelay) will simply create a
%%%'filter' structure 'P' such that it simply delays an analog signal by
%%%the value in amountofdelay
%%%
%%%If any filters are to be created, the sampling frequency of the data to
%%%be filtered (currentfreq) *must* be specified, currentfreq should be
%%%specified in hz for this function.
%%%
%%%All filter corners should be given in Hz.  Any number of notch filters
%%%should be specified as a row vector (e.g. [60 120] will give filters at
%%%60 and 120 Hz).
%%%
%%%P: filter structur; currentfreq: sampling freq; hipassfilter: corner of
%%%hi pass filter; notch_filt: row vector that specifies all notch filters;
%%%downsamplefreq: if downsampling specify here so an appropriate low pass
%%%filter can be implemented; amountofdelay: specify any fixed amount of
%%%delay to be enforced to channels that are not filtered; displayfilter:
%%%if set to one, a plot of the final filter will be produced; FIR: set to
%%%one if the final filter is to be converted to a finite impulse response
%%%
%%%Need to be aware of where you place the notch filters, certain
%%%combinations can cause distortions with the high and low-pass filters,
%%%probably because of pole-zero competitions, ie you should do a plot of
%%%the filter the first time you decide on a filter combination to make
%%%sure it is OK.
%%%
%%%Another warning, the filter coefficients are double precision, applying
%%%them to single precision data can cause problems as they will get
%%%rounded to single  precision standards (may want to convert the filtered
%%%data to double before applying the filter).
%%%
%%%Last modified Jan 2009, EAP

function [P] = preprocess_filter_create(P,currentfreq,hipassfilter,notch_filt,downsamplefreq,amountofdelay,displayfilter,FIR)

%%%If only generating a filter for delaying a signal, just return the following.
if nargin == 1
    %%%If only one input, then the amountofdelay value will actually be
    %%%listed under the variable 'P'.
    amountofdelay = P;
    clear P
    %%%Now create an actual empty filter structure
    P   = preprocess_filter_struct;
    P.a = 1;
    P.b = amountofdelay;
    return;
end

%%%
%%%Populate filter structure with default values if not specified
if (nargin == 2)
    FIR             = 0;
    displayfilter   = 0;
    amountofdelay   = 1;    
    %%%By default, just hi pass filter the data, and then notch filter out
    %%%any noise.
    hipassfilter    = 0.5;
    notch_filt      = [60 120];%notch filters at 60 and 120 Hz
    %%%Downsample to 256Hz, if the current frequency is higher
    if currentfreq > 256
        downsamplefreq  = 256;
    else
        downsamplefreq  = currentfreq;
    end
elseif nargin == 6
    FIR             = 0;
    displayfilter   = 0;    
elseif nargin < 6
    disp('If not using ALL default filter settings, only FIR and displayfilter are optional inputs (default for both is no)');
    disp('All other values must be specifed, unwanted filters should be specified as 0 or []');
    return
end

%%%
%%%Fill in zeros for unspecified flags
if isempty(hipassfilter); hipassfilter = 0; end;
if isempty(currentfreq); currentfreq = 0; end;
if isempty(notch_filt); notch_filt = 0; end;
if isempty(displayfilter); displayfilter = 0; end;
if isempty(downsamplefreq); downsamplefreq = currentfreq; end;
if isempty(FIR); FIR = 0; end;
if isempty(displayfilter); displayfilter = 0; end;

if (currentfreq == 0 ) 
    disp('Need to specify sampling rate (currentfreq)');
    return;
end

%%%The notch filter(s) should be specified as a row vector;
notch_filt = notch_filt(:)';
if size(notch_filt,1) > 1
    display('Specify notch filters in a row vector');
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%Now we start making the filter(s)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%If the goal frequency (the downsamplefreq) is smaller than the current
%%%freq, you should low pass filter the data prior to the downsampling
%%%decimation takes place.  
freq_ratio = currentfreq/downsamplefreq;
if freq_ratio == 1
    %%%no downsampling
    adec=1;bdec=1;
else
    %%%Need a low-pass filter prior to that decimation
    %%%This is similar to the matlab decimate function in that it uses a
    %%%chebychev filter at 80% the freq ratio and .05 in the ripple
    [bdec,adec]=cheby1(4,0.05,.8/freq_ratio);
end

%%%
%%%High-pass filter (2nd order Butterworth).  This gets rid of any DC
%%%offset or any slow drift.
if hipassfilter ~= 0
  [hpnum,hpdenom]=butter(2,(hipassfilter/currentfreq)*2,'high');
else
  hpnum=1;hpdenom=1;
end

%%%
%%%Here the coefficients for any and all notch filters are determined
if sum(sum(notch_filt)) > 0
    notch_filt_num   = ones(size(notch_filt,2),5);
    notch_filt_denom = ones(size(notch_filt,2),5);
    for k = 1:size(notch_filt,2)
        [notch_filt_num(k,:),notch_filt_denom(k,:)]=butter(2,([notch_filt(1,k)-2 notch_filt(1,k)+2]/currentfreq)*2,'stop');
    end
else
    %%%No notch filters
    notch_filt_num   = 1;
    notch_filt_denom = 1;
end    

%%%
%%%Merge all these filters together so they can be implemented in a single
%%%operation
%%%
%%%First, get the roots of all the notch filters
All_notch_roots = [];
for k=1:size(notch_filt_num,1)
    All_notch_roots = [All_notch_roots; roots(notch_filt_denom(k,:))];
end
%%%Now merge the notch with any high- and low-pass filters
a = poly([roots(adec);roots(hpdenom);All_notch_roots]);
%%%
%%%Now convolve all the filters with each other
b = conv(hpnum,bdec);
for k=1:size(notch_filt_num,1)
    b = conv(notch_filt_num(k,:),b);
end
    
% make linear phase FIR filter from this IIR
if FIR
  u = zeros(2*1024,1); u(round(length(u)/2))=1;
  b = filtfilt(b,a,u); a=1;
  amountofdelay = [zeros(1,floor(length(b)/2)-1) 1];
end

%%%Make a figure showing the composite filter
if displayfilter == 1 % the filters we will apply
    figure;
  freqz(b,a,1024*4,currentfreq); 
  subplot(2,1,2); grpdelay(b,a,1024,currentfreq); 
  if ~FIR, axis([0 currentfreq/2 0 currentfreq/50]); end
  drawnow
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%Put all of the details of the desired filter into the structure 'P'
P.fsr   = freq_ratio;
P.delay = amountofdelay;%%%This is how much you may want to specifically delay some channels
P.a     = a;
P.b     = b;

