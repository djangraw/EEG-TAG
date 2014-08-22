
%%%This function generates a Precision-Recall curve.
%%%
%%%It is given a vector that contains the confidence values that each of
%%%the data pointes does fall into the category in question.
%%%
%%%The other input is a vector that indicates whether or not those points
%%%are in fact known to fall into that category.
%%%
%%%Output are the actual Precision and Recall values, as well as a handle
%%%to the plot itself.
%%%
%%%[Precision Recall h_precrcall] = precisionrecallcurve(confidences,status);
%%%
%%%Last modified Jan 2009 EAP

function [Precision Recall h_precrcall] = precisionrecallcurve(confidences,status,plotflag)

if nargin < 3; plotflag=1; end;
if isempty(plotflag); plotflag=0; end;
if strcmp('plot',plotflag)==1; plotflag=1; end;

% keep ConfidenceValues TargetStatus
% confidences = ConfidenceValues; status = TargetStatus;

confidences = confidences(:);
status = status(:);

numpoints = size(confidences,1);

%%%Abbreviations:
%%%True Positive => TP
%%%True Negative => TN
%%%False Positive => FP
%%%False Negative => FN

%%%Number of actual targets present
Nactual = sum(status);%Nactual = (TP + FN)

%%%Number of actual non-targets/distracters
%Ndistract = sum(~status);%Ndistract = (FP + TN)

%%%These are the confidences and status values for each data point in
%%%ascending order of the confidence
[conf_Sorted,indx]=sort(-1*confidences,'ascend');
status = status(indx);


%%%Incrementally determine the TP, TN, FP, and FN values for each data
%%%point (by assuming that the confidence cut-off was placed at that
%%%confidence value).
TP = zeros(numpoints,1); FP = zeros(numpoints,1); 
%TN = zeros(numpoints,1); FN = zeros(numpoints,1);
%%%
TP = cumsum(status);
FP = cumsum(~status);

%%%Determine the true positive rate (ie the Recall)
Recall = TP./Nactual;
%%%Determine the precision at each point
Precision = TP./(TP + FP);

%%%Plot the raw data points
if plotflag==1
    figure; grid; 
    hold on;
    h_precrcall = plot(Recall,Precision,'-ok');
    set(h_precrcall,'markersize',6);
    set(h_precrcall,'markerfacecolor','k');
    xlabel('Recall (ie True Positive Rate)');
    ylabel('Precision');
    axis([0 1 0 1])
    axis square
    hold off;
else
    h_precrcall = [];
end


return;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Below were some attempts to arrange code for adding interpolated points
%%%to the plot.
% 
% 
% %%%Plot the general shape of the R-R plot
% %
% %%%Look between each successive pair of Precision-Recall points that were
% %%%calculated from the data and see if you want to interpolate any points.
% Add2plot = [];
% for k=2:size(Recall,1);
%     %%%See if you want to add any interpolated points between this set
%     if (TP(k)-TP(k-1)) >= 1
%         interpolatedPTs = [1:1:round(TP(k)-TP(k-1))]';    
%         %%%Find the local skew (how many negatives it takes to make a
%         %%%positive between these two known pts)
%         localskew = (FP(k)-FP(k-1))/(TP(k)-TP(k-1));
%         for deltax=1:1:size(interpolatedPTs,1)
%             %%%Now find as much interpolated data between the points as you
%             %%%want
%             newRecall    = [TP(k-1)+deltax]/Nactual;
%             newPrecision = [TP(k-1)+deltax]/[TP(k-1) + deltax + FP(k-1) + deltax*localskew];
%             Add2plot = [Add2plot; [newRecall newPrecision]];
%             clear newRecall newPrecision
%         end
%     end
% end
% %%%Between each point 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% %%%Determine the points that you want to interpolate at
% plottedpoints = 0:0.1:1;
% plottedpoints = plottedpoints([plottedpoints > min(Recall) & plottedpoints < max(Recall)])';
% Add2plot = zeros(size(plottedpoints,1),2);
% for k=1:size(plottedpoints,1);
%     %%%Make sure this isn't already a point in Recall
%     if sum(plottedpoints(k)==Recall) == 0
%         %%%Determine what the interpolation point should be.
%         before = find(Recall < plottedpoints(k));
%         after  = find(Recall > plottedpoints(k));        
%         deltax = plottedpoints(k) - Recall(before(end));
%         %%%This is from Davis and Goadrich "The Relationship between
%         %%%Precision-Recall and ROC Curves".
%         %%%These are for finding the points just before and after the
%         %%%desirered interpolation point.
%         TPa = TP(before(end));
%         FPa = FP(before(end));
%         FPb = FP(after(1));
%         TPb = TP(after(1));
%         Add2plot(k,1) = [TPa + deltax]/Nactual;
%         Add2plot(k,2) = [TPa + deltax]/[TPa + deltax + FPa + ((FPb-FPa)/(TPb-TPa))*deltax];
%         clear before after
%     end
% end
% 
% 
% 

