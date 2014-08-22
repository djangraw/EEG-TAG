function P = preprocessinit2(D,fs,fsref,channels,V)

% P = preprocessinit(D,fs,fsref,channels,V) Initializes parameters for
% preprocess(). All parameters are stored in the structure P. fs is the
% sampling frequency in Hz. The rest are optional parameters that can be
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
%
% (c) Lucas Parra, October 13, 2003, all rights reserved. Exclusive usage
% license to Anil Raj, UWF.

% parameters 
filter60Hz = 1; % select 60Hz notch filtering if needed
filter120Hz = 0; % select 120Hz harmonic notch filtering if needed
filterDC = 1;   % high pass filter to remove DC
FIR  = 0;       % =1 use linear phase FIR and delay events by the group delay.
                % =0 use IIR and do not dealy

% set some defaults
if nargin<3 | isempty(fsref), fsref = fs; end; 
if nargin<4 | isempty(channels), channels = 1:D; end; 
if nargin<5, V = []; end; 


% channels not in "channels" variable will be left alone
channelsNo = 1:D; channelsNo(channels) = 0; 
channelsNo = channelsNo(find(channelsNo));

% ratio of given and desired fs
fsr = fs/fsref;

% decimation filter (same as in decimate())
if fsr==1
  adec=1;bdec=1;
else
  [bdec,adec]=cheby1(4,0.05,.8/fsr);
end

% Notch (2nd order Butterworth, bandstop, F3db1=58, F3db2=62)
if filter60Hz 
  [notchnum,notchdenom]=butter(2,[58 62]/fs*2,'stop');
else
  notchnum=1;notchdenom=1;
end

% Notch (2nd order Butterworth, bandstop, F3db1=118, F3db2=122)
if filter120Hz 
  [notchnum120,notchdenom120]=butter(2,[118 122]/fs*2,'stop');
else
  notchnum120=1;notchdenom120=1;
end

% High-pass filter (2nd order Butterworth, cutoof f = 0.5 Hz, fs = 250 Hz).
if filterDC
  [hpnum,hpdenom]=butter(2,0.5/fs*2,'high');
else
  hpnum=1;hpdenom=1;
end

% instantaneous power code
% create a complex FIR filter
fc=25; % center frequency
%t=(-fs/2:fs/2)'/fs; % time course
t=linspace(-fs/2,fs/2,fs+1)'/fs;  
s = sin(2*pi*t*fc); % imaginary (odd) component
c = cos(2*pi*t*fc); % real (even) component
tw=1/fc; % time width
w = exp(-t.^2/2/tw^2); % Gaussian 
gp = w.*(c + sqrt(-1)*s); % Gabor pair
gp = gp/100; % try to obtain unity gain at center frequency 
%freqz(h,1,[],2048)


% combine all filters
a = poly([roots(adec);roots(hpdenom);roots(notchdenom);roots(notchdenom120)]);
b = conv(notchnum120,conv(notchnum,conv(hpnum,bdec)));
% gabor real
br = conv(b,real(gp)); % keep it real  
%br = real(gp);
% gabor imaginary
bi = conv(b,imag(gp));  
%bi = imag(gp);  
% note: autoregressive part is unaffected 

delay = 1; % this is how much the event channel is to be delayed
delaygp = [zeros(1,round(fs/2)) 1];
%delaygp=1;  



% make linear phase FIR filter from this IIR
if FIR
  u = zeros(2*1024,1); u(round(length(u)/2))=1;
  b=filtfilt(b,a,u);
  a=1;
  delay = [zeros(1,floor(length(b)/2)-1) 1];
end

% construct projection matrix to remove eye artefacts
if ~isempty(V), 

  % these channels are not to be included in the projections.
  V(channelsNo,:) = 0; 
  
  % this will project out eye artifacts 
  U = (eye(size(V,1))-V*pinv(V)); 

else
  U = [];
end








% collecting all the stuff that we are initializing for preprocess.m
P.fsr = fsr;
P.Zdec = []; 
P.Zdel = [];




P.channels=channels;
P.channelsNo=channelsNo;
P.delay=delay;
P.delaygp=delaygp;  

%P.delayr=delayr;
%P.delayi=delayi;

P.a=a;
P.b=b;
P.U=U;
P.br=br;  
P.bi=bi;  
P.gp=gp;  
P.Zdecr = []; 
P.Zdeci = []; 






