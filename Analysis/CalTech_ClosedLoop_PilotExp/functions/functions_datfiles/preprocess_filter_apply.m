%%%
%%%This function is for applying a previously created filter for filtering
%%%and downsampling some analog data (filter stored in structure 'P').
%%%see preprocess_filter_struct and preprocess_filter_create.
%%%
%%%Each row in analogdata is assumed to represent a different channel of
%%%data, and are treated independantly.
%%%
%%%The filter structure P is returned so that if the data are being
%%%processed in chunks when the next chunk is done there will not be any
%%%edge effects from the previous application of the filter (the Zdec
%%%and/or Zdel are modified to contain this information).
%%%
%%%You can specify in P whether specific channels are to have the filter
%%%applied (P.channels), or are just delayed by a specific amount of
%%%delayed enforced on them (P.channelsNo, and delay).
%%%
%%%If both channel entries in P are emtpy this function can just downsample
%%%the data.
%%%
%%%[analogdata, P] = preprocess_filter(analogdata,P);
%%%
%%%Last modified Jan 2009, EAP

function [analogdata_out, P] = preprocess_filter_apply(analogdata,P)

%%%Apply the filter specified in the structure 'P'
%%%
%%%Some channels will be filtered, other channels may only be delayed
if isempty(P.channels)~=1
    [analogdata(P.channels,:),   P.Zdec] = filter(P.b,     P.a, analogdata(P.channels,:),  P.Zdec, 2); 
end
%%%
%%%This is for any channels that are just being delayed
if isempty(P.channelsNo)~=1
    [analogdata(P.channelsNo,:), P.Zdel] = filter(P.delay, 1,   analogdata(P.channelsNo,:), P.Zdel, 2);
end

%%%
%%%If requested, downsample the resulting signal (all channels are
%%%downsampled equivalently).
if P.fsr ~= 1
    %%%Downsampling (decimating) the signals
    analogdata_out = analogdata(:,round(P.fsr:P.fsr:end));
else
    %%%Do nothing to the data beyond the previous filtering.
    analogdata_out = analogdata;
end
clear analogdata

%downsample, resample, decimate