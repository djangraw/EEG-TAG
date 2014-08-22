%%%
%%%This function returns a vector of the values for the requested field for
%%%an XML structure (this is the kind of XML structure that has been read
%%%into Matlab from an XML file, see convertXML2XMLstruct.m)
%%%
%%%[output] = getXMLstructfieldvalue(XMLstruct,fieldname,stringflag);
%%%
%%%fieldname => string specifying which field value you want
%%%If you want multiple field values from each entry can specify fieldname
%%%a cell array (each entry being the different field name).  Ouput will be
%%%a matrix with each column corresponding to the differen fieldnames.
%%%
%%%stringflag => optional, default is zero; set to 1 if the entry in the
%%%field is known to be a string (the default is to return all field
%%%entries as a numeric value).  If there are multiple fields in fieldname,
%%%stringflag should be a vector with one entry for fieldname.
%%%
%%%output will be a cell matrix if any of the requested fields correspond
%%%to a text stringflag of 1, otherwise output will just be a standard
%%%numeric matrix.  Output could also be a cell matrix if all of the values
%%%are numeric, but there are variable quantities of values for one or more
%%%of the requested fields.
%%%
%%%Aug 2009: added functionality so that it will load all values of
%%%sub-nodes for a specified sequence of fieldnames.  This should be specified as:
%%%fieldname={'id';'groundTruth';'status';'eegconfidence.econf'}
%%%
%%%Last modified Aug 2009 EAP

function [output] = getXMLstructfieldvalue(XMLstruct,fieldname,stringflag)

%%%since fieldnames can be of multiple lengths it needs to be a cell for
%%%multiple entries, and to have consistent code it also needs to be a cell
%%%even if they only input a single entry
if iscell(fieldname) ~= 1
    fieldnames{1,1} = fieldname;
else
    fieldnames = fieldname;
end
%%%
%%%Default flag indicating all returned values are numeric
if nargin == 2
    stringflag = zeros(length(fieldnames),1);
end
%%%
%%%How many fields are being looked at
fieldnames = fieldnames(:);
numFields = size(fieldnames,1);

%%%Make sure all the requested fields exist
for k=1:numFields
    try
        eval(['check = XMLstruct.object_info{1,1}.',fieldnames{k,1},';']);
        clear check;
    catch
        disp('No such field in XML structure');
        output = [];
        return;
    end
end
%%%
%%%How many entries there are
numEntries = size(XMLstruct.object_info,2);
%%%
output = cell(numEntries,numFields);
%%%Extract the request field for each entry in the XML structure
for k=1:numEntries
    for z=1:numFields
        %%%
        %%%This is for retrieving the result if what was given was two
        %%%fieldnames to which the results was buried, eg
        %%%XMLstruct.object_info{1,k}.fieldname1.fieldname2
        %getfield(XMLstruct.object_info{1,k},fieldnames{:})
        %%%
        %%%If the field entry is a string, just put it in the output as a string
        if stringflag(z) == 1
            output{k,z} = getfield(XMLstruct.object_info{1,k},fieldnames{z,1});
        else
            %%%If the entry is to be output as numeric value, then convert
            %%%it to numeric if it is text, and otherwise just grab the
            %%%value
            %fieldentry = getfield(XMLstruct.object_info{1,k},fieldnames{z,1});            
            eval(['fieldentry = XMLstruct.object_info{1,k}.',fieldnames{z,1},';']);
            %%%
            if iscell(fieldentry)
                check = isnumeric(fieldentry{1,1});
            else
                check = isnumeric(fieldentry);
            end
            if check%ie already a numeric value
                output{k,z} = fieldentry;
            else%convert to a numeric value
                output{k,z} = str2double(fieldentry);
            end
            %%%
            clear fieldentry
        end
    end
end
%%%
%%%If all the outputs are numeric, and there are a consistent number of
%%%entries for each field, just return a normal matrix rather than
%%%a cell matrix.
if sum(stringflag)==0
    try
        output = cell2mat(output);
    catch
        %%%If you can't make the conversion, there is probably and erratic
        %%%number of entries somewhere, so just return the cell matrix
    end
end






