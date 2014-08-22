%%%
%%%This function generates a set of ERP plots of some analog data given the data
%%%and the event markers indicating target and non-target (ie distracter)
%%%events.  The event markers should be given as the id number of the bins
%%%correspdoning to their occurence in the analog data.  Similarly,
%%%numbins (which indicates the amount of data following each event that
%%%is considered in the ERP) should be specified as the number of analog
%%%bins that are used.
%%%
%%%The 3 ERP plots generated show the effects during target trials, the
%%%effects during non-target trials, and the effects during target trials
%%%when the non-target trial effects have been subtracted out.
%%%
%%%h = generate_ERP_plot(analogdata,targetevents,nontargetevents,numbins);
%%%
%%%Last modified Jan 2009, EAP

function [h] = generate_ERP_plot(analogdata,targetevents,nontargetevents,numbins)

%%%
%%%Reshape the data to get a 3-D matrix that contains all of the trial
%%%information for target trials
Xt = analog2trial_matrix(analogdata,targetevents,numbins);

%%%
%%%Reshape the data to get a 3-D matrix that contains all of the trial
%%%information for non-target trials
Xn = analog2trial_matrix(analogdata,nontargetevents,numbins);

%%%Find the average analog values during each trial
mXt = mean(Xt,3); %for target events
mXn = mean(Xn,3); %for non-target events

%%%Make the ERP figures
figure;h(1,1) = imagesc(mXt);
caxis([-20 20])
ylabel('Electrode Number'); xlabel('Number Sample points'); 
title('ERP for Targets');

figure;h(1,2) = imagesc(mXn);
caxis([-20 20])
ylabel('Electrode Number'); xlabel('Number Sample points');
title('ERP for Non-Targets');

figure;h(1,3) = imagesc(mXt-mXn);
caxis([-20 20])
ylabel('Electrode Number'); xlabel('Number Sample points');
title('ERP for Targets with Non-Target Averages Removed');




