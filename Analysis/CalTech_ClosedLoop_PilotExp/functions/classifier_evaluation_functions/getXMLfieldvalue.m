%%%
%%%This function returns a vector of the values for the requested field for
%%%an XML structure
%%%
%%%[output] = getXMLfieldvalue(XMLstruct,fieldname);
%%%
%%%fieldname => string specifying which field value you want
%%%If you want multiple field values from each entry can specify fieldname
%%%a cell array (each entry being the different field name).  Ouput will be
%%%a matrix with each column corresponding to the differen fieldnames.
%%%
%%%Last modified Feb 2009 EAP

function [output] = getXMLfieldvalue(XMLstruct,fieldname)

if isfield(XMLstruct.object_info{1,1},fieldname) == 0
    disp('No such field in XML structure');
    output = [];
    return;
end

%%%How many entries there are
numEntries = size(XMLstruct.object_info,2);

%%%How many fields are being looked at
fieldname = fieldname(:);
numFields = size(fieldname,1);

output = nan(numEntries,numFields);
%%%Extract the request field for each entry in the XML structure
for k=1:numEntries
    for z=1:numFields
        output(k,z) = str2double(getfield(XMLstruct.object_info{1,k},fieldname{z,1}));
    end
end


