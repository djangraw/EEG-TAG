%%%
%%%This function returns the classifier scores for all trials during the
%%%training session.  It also returns a vector indicating whether each
%%%trial corresponded to a target or distracter trial.
%%%
%%%[scores status] = getTrainingScores(classifier_dir);
%%%
%%%last modified Feb 2010, EAP

function [scores status] = getTrainingScores(classifier_dir)

%%%
%%%Load the classifier and the training data
load(fullfile(classifier_dir,'classifier'));
load(fullfile(classifier_dir,'trainDatabase'));
%%%
%%%Get the classifier output for each target and nontarget trial
[TargetOutput Expectations]    = applyClassifier(trainingDatabase.Xtargets(:,:,1:trainingDatabase.targetCounter), Cparams);
[NonTargetOutput Expectations] = applyClassifier(trainingDatabase.Xnontargets(:,:,1:trainingDatabase.nontargetCounter), Cparams);
scores                         = [TargetOutput;NonTargetOutput];
%%%
%%%make a vector indicating targets/distracters 
status                                   = false(size(scores));
status(1:trainingDatabase.targetCounter) = true;
