%%%
%%%This function just takes a .dat file, loads it, and generates a plot of
%%%the ERP's and scalp plots of the forward model.  The .dat file is of the
%%%kind created by ProducerConsomuer
%%%
%%%plot_datfile(filename,samplingfreq);
%%%
%%%It just uses several subfunctions and assumes a bunch of default
%%%settigns for the .dat file
%%%
%%%Last modified Feb 2009 EAP

function plot_datfile(filename,samplingfreq)

if nargin == 1;
    samplingfreq = 2048;
end

%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%load the data
disp('loading the data, pre-processing and downsampling to 256 Hz');
Nchannels       = 73;
Nanalogchannels = 64;
analogchanneloffset = 2;
%%%
[outputanalogdata eventdata] = preprocess_dat_file(filename,samplingfreq,Nchannels,Nanalogchannels,analogchanneloffset);
samplingfreq    = 256;

%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Create a matrix data for each trial
disp('Parsing data into trials');
%%%
targetevents    = floor(eventdata{end,2} * samplingfreq);
nontargetevents = floor(eventdata{end-1,2} * samplingfreq);
%%%
target_trial_ts    = targetevents;
nontarget_trial_ts = nontargetevents;
triallength        = samplingfreq;
[X3 y] = convertanalog2trial(outputanalogdata(2:end,:),target_trial_ts,nontarget_trial_ts,triallength);

%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Plot the ERPs
disp('Plotting ERP''s');
targetevents    = floor(eventdata{end,2} * samplingfreq);
nontargetevents = floor(eventdata{end-1,2} * samplingfreq); 
numbins = samplingfreq;
h = generate_ERP_plot(outputanalogdata(2:end,:),targetevents,nontargetevents,numbins);


%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Plot the scalp plots of the analog data.
disp('Generating scalp plot''s');
%%%
conditioning_eigenvalue = 50;
[alpha beta Y] = generate_forward_model(X3,y,conditioning_eigenvalue,'plot');





