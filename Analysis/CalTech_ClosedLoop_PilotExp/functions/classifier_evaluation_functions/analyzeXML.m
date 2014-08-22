
%%%This function takes an XML file and determines how well the images are
%%%being classified.
%%%
%%%One input is which field contains the confidence that the entry is a
%%%target (vs a distracter).  Another input is the name of the field that
%%%telss whether that entry is actually known to be a target or not.  The
%%%main input is the name of the XML file.
%%%
%%%Would like to generate ROC and precision recall curves
%%%
%%%statusvalues specifies how the statusfieldname data will describe the
%%%data, ie it tells what the numberic flag is for a target of unknown
%%%status, true positive status, and true negative status (in that order).
%%%This is an optional input with [0 1 -1] as the default.
%%%
%%%Last modified Feb 2009 EAP

function [output] = analyzeXML(xmlfilename,confidencefieldname,statusfieldname,statusvalues)

output = 0;

if nargin == 3
    %%%Default flag values are 0 for unknown, 1 for true positive, and -1
    %%%for true negative
    statusvalues = [0 1 -1];
end

statusvalues = statusvalues(:)';

if size(statusvalues,2) == 1
    statusvalues = [0 statusvalues -1];
end
if size(statusvalues,2) == 2
    statusvalues = [0 statusvalues];
end

%%%Example call
%[output] = analyzeXML('test_sam2.xml','myeegconfidence','status');

%%%If the input was an XML file, convert it into a structure that Matlab
%%%can analyze.
%%%If the file has already been converted to a Matlab XML structure, this
%%%is unneccessary
if isstruct(xmlfilename)
    XMLstruct = xmlfilename;
    clear xmlfilename
else
    s1 = xmltree(xmlfilename); XMLstruct = convert(s1);
end

%%%Number of nodes
numEntries = size(XMLstruct.object_info,2);

%%%TargetStatus tells whether or not the image is known to be a target
TargetStatus = false(numEntries,1);
%%%Also, extact all the confidences values
ConfidenceValues = zeros(numEntries,1);
%%%Get the Computer vision confidences while we are at it
CVconfidences = zeros(numEntries,1);
for k=1:numEntries
    if str2num(getfield(XMLstruct.object_info{k},statusfieldname)) == statusvalues(1,2)
        TargetStatus(k,1) = true;
    end
    ConfidenceValues(k,1) = str2num(getfield(XMLstruct.object_info{k},confidencefieldname));
    CVconfidences(k,1) = str2num(getfield(XMLstruct.object_info{k},'confidence'));
end


%%%Plot the EEG confidences versus the CV confidences, so we can see how
%%%they stack up with each other
%%%Do a plot of EEGconfidences vs the CVconfidences
figure; hold on; grid; box off; axis square;
plot(CVconfidences(TargetStatus),ConfidenceValues(TargetStatus),'r*')
plot(CVconfidences(~TargetStatus),ConfidenceValues(~TargetStatus),'k.')
xlabel('Computer Vision Confidence')
ylabel('EEG Confidence')
title(['Comparing the Computer Vision and the EEG Rankings']);
hold off;

%%%Now do a basic set of plots: distribution of the confidences, ROC curve,
%%%Precision Recall Curve
displayclassificationresults(ConfidenceValues,TargetStatus);

%%%Actually return the Az values
[Azvalues,tp,fp]=rocarea(ConfidenceValues,TargetStatus);
%%%
output = Azvalues;

