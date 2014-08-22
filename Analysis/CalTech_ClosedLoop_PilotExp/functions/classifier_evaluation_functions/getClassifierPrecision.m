%%%
%%%This function anlayzes stored training data and determines what the
%%%precision recall curve would be for that data (plot by request).  It
%%%also resturns what the necessary confidence thresholds would be if you
%%%wanted to obtain certain precision levels (.5, .55, .60, .65 .... 1.0)
%%%as well as the threshold for the maximum precision.
%%%
%%%[Precision, Recall, h_precrcall, PrecisionCutoffs] = GetPrecisionCutoffs(resultsdirectory,plotflag);
%%%
%%%resultsdirectory = directory where the _cbci_xxxxxx.xxxx folder is
%%%located (the results of the training session0.
%%%
%%%first column of PrecisionCutoffs tells what the precision levels are,
%%%2nd column tells the threshold to achieve that for the training data.
%%%
%%%Last modfied Dec 2009 EAP

function [Precision, Recall, h_precrcall, PrecisionCutoffs] = getClassifierPrecision(resultsdirectory,plotflag)

if nargin<2; plotflag=0; end;
if isempty(plotflag); plotflag=0; end;

%%%
%%%Load the classifier and the training data
load(fullfile(resultsdirectory,'classifier'));
load(fullfile(resultsdirectory,'trainDatabase'));
%%%
%%%Get the classifier output for each target and nontarget trial
[TargetOutput Expectations]    = applyClassifier(trainingDatabase.Xtargets(:,:,1:trainingDatabase.targetCounter), Cparams);
[NonTargetOutput Expectations] = applyClassifier(trainingDatabase.Xnontargets(:,:,1:trainingDatabase.nontargetCounter), Cparams);
AllScores                      = [TargetOutput;NonTargetOutput];
%%%
[Precision Recall h_precrcall] = precisionrecallcurve(AllScores, [ones(size(TargetOutput));zeros(size(NonTargetOutput))], plotflag);
%%%
%%%Scores in rank order
[Y,I] = sort(AllScores,'descend');
%%%
%%%Determine what threshold you would need to use to have precision of at
%%%least the following values: .5, .55, .6 .65 etc. up to 1.00.  Also note
%%%the minimum threshold that gives you the maximum value of the PR curve.
PrecisionThresholds = .05:.05:1;
PrecisionCutoffs    = zeros(length(PrecisionThresholds)+1,2);
%%%
%%%First, determine the threshold relating to the peak of the
%%%precision-recall curve.  Use the last value of spots so that you can get
%%%the lowest threshold that meets your criteria (thus move to the right on
%%%the PR curve and maximizing the Recall/True Pos rate).
spots                   = find(Precision == max(Precision));
PrecisionCutoffs(end,1) = max(Precision);
PrecisionCutoffs(end,2) = Y(spots(end));
%%%Now find the others
for k=1:length(PrecisionThresholds)
    PrecisionCutoffs(k,1) = PrecisionThresholds(1,k);
    spots                 = find(Precision >= PrecisionThresholds(1,k));
    if ~isempty(spots)
        PrecisionCutoffs(k,2) = Y(spots(end));
    end
    clear spots
end
PrecisionCutoffs = flipud(PrecisionCutoffs);
