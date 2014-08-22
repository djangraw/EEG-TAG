%%%
%%%This generates a plot the overlays the distributions of the EEG scores
%%%for both the True and False Positive images
%%%
%%%plotEEGscoredistributions(TPscores,FPscores);
%%%
%%%Last modified Nov 2008 EAP

function plotEEGscoredistributions(TPscores,FPscores)

figure; hold on;

histbins = [-15:0.5:2];

Ntp = hist(TPscores,histbins);
Nfp = hist(FPscores,histbins);

xlabel('EEG Confidences');

title('Comparing Distributions of False Pos (black) and True Pos (red)');

[AX,H1,H2] = plotyy(histbins,Nfp,histbins,Ntp);
set(H1,'Marker', '.')
set(H2,'Marker', '*')
set(AX(1),'ycolor',[0 0 0])
set(H1,'color',[0 0 0])
set(AX(2),'ycolor',[1 0 0])
set(H2,'color',[1 0 0])

box off

hold off;