%%%%
%%%This function takes a set of analog data (each row being considered to
%%%represent a different channel of data) and extracts the analog data for
%%%each channel relating to specified trial events.  The data is arranged
%%%into a 3-dimensional matrix wherein each row represents a different
%%%analog channel, each column represents that data for that channel
%%%extending back in time following a single trial event, and the 3rd dimension
%%%being the data for each channel vs time for each successive trial event.
%%%In other words, if D: number of channels; N: number of trials; T: number
%%%of bins of data following each trial, the size of the output matrix (X)
%%%is DxTxN.
%%%
%%%X = analog2trial_matrix(analogdata,events,numbins);
%%%
%%%analogdata   => each row is different channel
%%%targetevents => event occurence that correspond to analogdata, specified by bin number
%%%numbins      => how much data following each event is desired in final matrix
%%%
%%%Last modified Jan 2009, EAP

function X = analog2trial_matrix(analogdata,events,numbins)

%%%Want the events as a columen vector
events = events(:);
if size(events,2) > 1
    disp('Event timing should be given as a single vector');
    return;
end

%%%Number of analog channels and events
numchannels = size(analogdata,1);
numevents   = size(events,1);

X = zeros(numchannels,numbins,numevents);

for k=1:numevents
    X(:,:,k) = analogdata(:,[events(k,1):(events(k,1)+numbins-1)]);
end
