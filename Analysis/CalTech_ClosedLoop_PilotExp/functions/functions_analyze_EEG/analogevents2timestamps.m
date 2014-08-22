%%%
%%%This function is for converting an analog channel that only recorded
%%%specific, discrete numberic events into lists of timestamps that
%%%correspond to the occurence of these events in the file.
%%%
%%%This function assumes that there is no noise in this analog channel, and
%%%that all the non-zero values in the analog signal represent distinct
%%%events.  Also, it is important that the analog signal will always go
%%%back to zero between two distinct events (you may lose this
%%%characterisitic after filtering or downsampling, so be aware).
%%%
%%%[event_ts] = analogevents2timestamps(analogeventchannel,samplingrate);
%%%
%%%event_ts is a cell matrix with the first column indicating what the
%%%numeric value of the event, and the second column indicatign the
%%%timestamp of when that event occured.
%%%
%%%When using the BioSemi to record 64 EEG channels, the .dat file that
%%%ProducerConsumer creates has the following attributes:
% BioSemi sample rate is often 2048Hz (set by switch on device)
% There are 73 channels
% X(1,:) is the trigger channel
% X(2,:) is a virtual channel that increases by 1 from sample to sample are reset at the end of he buffer (you can ignore this)
% X(2:66,:)  is  the actual EEG data
% X(67:73,:) the recording of the external channels (we dont use those now
% so they should have anything interesting - can be ignored.) 
% Note to see the trigger channel you might need do this
% plot(bitand(X(1,:),255);
%%%
%%%Last modifed July 2009 EAP

function [event_ts] = analogevents2timestamps(analogeventchannel,samplingrate)

%%%If you don't know the sampling rate, you can just output the event
%%%occurences by the id number of the analog data point at which they
%%%occured.
if nargin == 1
    disp('sampling rate unknown, assuming a sampling rate of one');
    samplingrate = 1;
end
%%%
%%%This converts the recorded analog channel event channel into numeric
%%%values that actually reflect the events.
analog_events = bitand(double(analogeventchannel),255);
%%%
%%%This just guarantees that you have a column vector
analog_events = analog_events(:);
%%%
%%%These are all the distinct events recorded in the analog channel
unique_events = unique(analog_events);
%%%
%%%Don't care about the value zero (it doesn't reflect an actual event).
event_ts = cell(size(unique_events,1)-1,2);
%%%
%%%These are the timepoints at which the analog event channel first changed
%%%from one value to another.
%transitions   = find(diff(analog_events) > 0);
%%%
%add a zero to account for possibility of signal being nonzero at the very
%beginning
transitions   = find(diff([0; analog_events]) > 0);

%%%
%%%Make a record of all the different events and record the timepoints
%%%where each transitioned
% for k = 2:size(unique_events,1)
%     spots = find(analog_events(transitions+1) == unique_events(k,1));
%     %%%These are the data pts where the channel transitioned to that event
%     %%%value, by dividing by the sampling rate you get the actual
%     %%%timepoints.
%     event_ts{k-1,2} = [transitions(spots)+1]./samplingrate;
%     event_ts{k-1,1} = unique_events(k,1);
%     clear spots
% end
%%%
%%%This version assumes you've added a zero at the beginning
for k = 2:size(unique_events,1)
    spots = find(analog_events(transitions) == unique_events(k,1));
    %%%These are the data pts where the channel transitioned to that event
    %%%value, by dividing by the sampling rate you get the actual
    %%%timepoints.
    event_ts{k-1,2} = [transitions(spots)]./samplingrate;
    event_ts{k-1,1} = unique_events(k,1);
    clear spots
end

