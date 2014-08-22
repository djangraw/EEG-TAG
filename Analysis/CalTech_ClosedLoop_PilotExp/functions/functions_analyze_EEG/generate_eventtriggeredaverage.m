%%%
%%%This function generates a set of event-triggered averages (ETA) for a set of
%%%analog data given the timestamps of a series of events.  If requested,
%%%it will do a plot of each average.  For EEG data this means you can see
%%%event-related potential following a stimulus.
%%%
%%%[ETA] = generate_eventtriggeredaverage(analogdata,events,samplingrate,windowsize,plotflag);
%%%
%%%analogdata   => data to be averaged, if a matrix each row is assumed to be a different channel
%%%events       => timestamp of occurence (in seconds) of each
%%%windowsize   => amount of time (in seconds) to be averaged following each event
%%%samplingrate => sampling rate (in Hz) of analog data
%%%plotflag     => optional (default is no plot) if equal to 'plot', a plot
%%%is made of each event-triggered average
%%%ETA          => matrix of event-triggered average results
%%%
%%%Last modified Jan 2009, EAP

function [ETA] = generate_eventtriggeredaverage(analogdata,events,samplingrate,windowsize,plotflag)

if nargin == 4
    plotflag = 'noplot';
elseif nargin ~= 5
    disp('Insufficient number of inputs');
    ETA = [];
    return;
end

%%%
%%%Reshape the data to get a 3-D matrix that contains all of the trial
%%%information following each of the events
X = analog2trial_matrix(analogdata,events,round(samplingrate*windowsize));

%%%Find the average analog values during each trial
ETA = mean(X,3);

clear X

%%%If requested, make figures
if strcmp(plotflag,'plot')
    for k=1:size(analogdata,1)
        figure;
        h = plot(1000*[1:round(samplingrate*windowsize)]./samplingrate,ETA(k,:),'k');
        xlabel('Time (msecs)');
        ylabel('Mean Analog value');
        title(['Channel #',int2str(k)]);
    end
end
        