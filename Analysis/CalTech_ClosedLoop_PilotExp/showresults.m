

fieldname = 'confidence';
qty2show = 40;
imagedirectory = 'C:\Program Files\MATLAB\R2007b\work\CalTech_ClosedLoop_PilotExp\101_samesize_resized';

try
    [imagehandle] = displayrankedimages(XMLstruct_TAG,imagedirectory,qty2show,fieldname);
catch
    target_cat = input('Enter the case sensitive ID for the exp series [A,B,C... etc]=> ', 's');
    iterationNumber = input('Please enter the number of the Closed-Loop Iteration: ');
    xmlfilename = ['ClosedLoopTAG_',target_cat,'_',int2str(iterationNumber)];
    %%%
    disp('Converting XML file ');
    [imagehandle] = displayrankedimages([xmlfilename,'_end.xml'],imagedirectory,qty2show,fieldname);
end