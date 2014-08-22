function [howmany_in howmany_out catlist] = TAG_howmanyinout(DisplayedImages,EEGresults)

% function [howmany_in howmany_out catlist] = TAG_howmanyinout(DisplayedImages,EEGresults)
%
% Created 11/13/09 by DJ.
% update 11/20: EAP
%           modified to accept runs of less than 500
%           modified to load category list from file: 
% Last updated 11/20/09 by EAP.

% SET UP
nRuns = numel(DisplayedImages); % number of times EEG was displayed
N = size(DisplayedImages{1},1); % number of images per run
%%%Get list of all categories in the TAG graph
load TAGimageOrdering; catlist = unique(TAGnames(:,1)); clear TAGFileList TAGnames;
howmany_out = zeros(nRuns,numel(catlist));

% MAIN LOOP
for iRun = 1:nRuns
    N = size(DisplayedImages{iRun},1); % number of images in this run run
    %%%
    N = min(N,500);%get number of images shown **up to** 500
    %%%
    % Get the categories of all the displayed images (RSVP input) and make
    % them numeric (corresponding to index in catlist)
    cat_in = DisplayedImages{iRun}(1:N,1); % categories of images shown as input to EEG
    catnum_in = zeros(1,numel(cat_in));
    for i=1:numel(cat_in)
        catnum_in(i) = strmatch(cat_in{i},catlist,'exact'); % what category NUMBER is each image in 'cat_in' in?
    end

    % Get the categories of the top 20 EEG results (RSVP output) and make 
    % them numeric
    catlist_out = EEGresults{iRun}(:,1);
    for i=1:numel(catlist_out)
        iCat = strmatch(catlist_out{i},catlist,'exact'); % what category NUMBER is each image in 'cat_in' in?
        howmany_out(iRun,iCat) = EEGresults{iRun}{i,2};
    end
    
    % Get totals
    for iCat = 1:numel(catlist)
        howmany_in(iRun,iCat) = sum(catnum_in==iCat);
    end
     
end


