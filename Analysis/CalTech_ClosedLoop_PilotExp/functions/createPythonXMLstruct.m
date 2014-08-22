
%%%This file creates a Matlab structure that contains empty slots for all
%%%the infomration necessary for a Python RSVP XML file.
%%%
%%%When you are ready to turn that matlab structure into an actual XML file
%%%you can use the "tree = struct2xml(s,rootname)" and "save(tree,'report.xml')" functions.
%%%
%%%[XMLsruct] = createPythonXMLstruct(numEntries);
%%%numEntries => optional (3 if unspecied) number of entries in the
%%%structure.
%%%
%%%Last modified Dec 2008 EAP

function [XMLstruct] = createPythonXMLstruct(numEntries)

if nargin == 0
    numEntries = 3;
end
if numEntries == 0;
    disp('Need to have at least one entry');
    return;
end

XMLstruct = struct('file_name',['OriginalImageFilename'],'object_number',[int2str(numEntries)],'max_object_number',[int2str(numEntries)],'object_info',[]);
XMLstruct.object_info = cell(1,numEntries);

for k=1:numEntries
    XMLstruct.object_info{1,k} = struct('file_name',['Chip_filename'],'id',['0'],'status',['1'],'position_x',['0'],'position_y',['0'],'scale',['0'],'levelPyramid',['0'],'confidence',['0']);
end

